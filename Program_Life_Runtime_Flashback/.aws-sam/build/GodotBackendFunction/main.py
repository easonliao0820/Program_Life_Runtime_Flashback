import os
import uuid
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any, Literal

from botocore.exceptions import BotoCoreError, ClientError
from dotenv import load_dotenv
from fastapi import FastAPI, Header, HTTPException, Request, Response
from fastapi.exception_handlers import request_validation_exception_handler
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from google.auth.transport import requests as google_requests
from google.oauth2 import id_token
from pydantic import BaseModel, ConfigDict, Field

from ai_access_policy import authorize_ai
from ai_service import generate, generate_game_reply
from auth_service import (
	ACCESS_TOKEN_MINUTES,
	REFRESH_TOKEN_DAYS,
	create_access_token,
	create_refresh_token,
	hash_refresh_token,
	verify_access_token,
	verify_refresh_token,
)
from error_repository import save_player_error
from oauth_service import exchange_google_code
from player_repository import get_or_create_google_player, get_player_by_id
from save_repository import load_player_game, save_player_game
from session_repository import (
	create_session,
	get_session,
	rotate_refresh_token,
	revoke_session,
)
from game_data_repository import (
	get_character,
	get_knowledge,
	get_story,
)

# 本機開發才從專案根目錄補讀設定；既有環境變數不會被覆蓋。
# Lambda 的 Google Client ID 由部署環境提供，不能省略 audience 驗證。
PROJECT_ROOT = Path(__file__).resolve().parent.parent
load_dotenv(PROJECT_ROOT / ".env")
GOOGLE_CLIENT_ID = os.getenv("GOOGLE_OAUTH_CLIENT_ID")
GOOGLE_WEB_CLIENT_ID = os.getenv("GOOGLE_OAUTH_WEB_CLIENT_ID", "").strip()
GOOGLE_ALLOWED_AUDIENCES = [v for v in (GOOGLE_CLIENT_ID, GOOGLE_WEB_CLIENT_ID) if v]

if not GOOGLE_CLIENT_ID:
	raise RuntimeError("缺少 GOOGLE_OAUTH_CLIENT_ID 環境變數")

app = FastAPI(title="Program Life Backend")


class GoogleLoginRequest(BaseModel):
	# 前端取得的 Google 身分憑證；接收後仍需驗證。
	id_token: str


class RefreshTokenRequest(BaseModel):
	refresh_token: str = Field(min_length=1)


class GameSaveRequest(BaseModel):
	save: dict[str, Any]


class AIRequest(BaseModel):
    prompt: str = Field(
        min_length=1,
        max_length=1000
    )


class GameAIRequest(BaseModel):
	player_message: str = Field(
		min_length=1,
		max_length=1000
	)
	character_id: str = Field(
		min_length=1,
		max_length=100
	)
	knowledge_id: str | None = None
	story_id: str | None = None



class PlayerErrorRequest(BaseModel):
	event_id: str = Field(min_length=32, max_length=32)
	occurred_at: str = Field(min_length=20, max_length=35)

	section_id: str = Field(min_length=1, max_length=120)
	level_id: str = Field(min_length=1, max_length=120)

	attempt: int = Field(ge=1)
	error_kind: Literal["python_exception", "check_failed"]

	error_type: str = Field(min_length=1, max_length=100)
	error_message: str = Field(default="", max_length=1200)

	line: int = Field(default=0, ge=0)
	source_line: str = Field(default="", max_length=500)
	code: str = Field(default="", max_length=4000)
	backend: str = Field(default="", max_length=120)


class DesktopExchangeRequest(BaseModel):
	# Desktop PKCE 授權碼由 Lambda 交換，Client Secret 不經過 Godot。
	model_config = ConfigDict(extra="forbid")
	code: str = Field(min_length=1, max_length=4096)
	code_verifier: str = Field(min_length=43, max_length=128)
	redirect_uri: str = Field(min_length=1, max_length=128)


@app.exception_handler(RequestValidationError)
async def safe_validation_error(request: Request, exc: RequestValidationError):
	# 不把原始 OAuth code / verifier 反射給客戶端。
	if request.url.path in {"/auth/google/desktop/exchange", "/auth/google", "/auth/refresh", "/auth/logout"}:
		return JSONResponse(
			status_code=422,
			content={"detail": "invalid_auth_request"},
			headers={"Cache-Control": "no-store"},
		)
	return await request_validation_exception_handler(request, exc)


# 與 Desktop OAuth 交換端點共用 Google ID Token 驗證。
def verify_google_token(token: str, transport=None, *, desktop_only=False) -> dict:
	try:
		return id_token.verify_oauth2_token(
			token,
			transport if transport is not None else google_requests.Request(),
			GOOGLE_CLIENT_ID if desktop_only else GOOGLE_ALLOWED_AUDIENCES,
		)
	except (ValueError, KeyError) as exc:
		raise HTTPException(
			status_code=401,
			detail="Google ID Token 驗證失敗",
		) from exc


def verify_desktop_google_token(token: str, transport=None) -> dict:
	return verify_google_token(token, transport, desktop_only=True)


@app.get("/health")
def health():
	# 只確認 HTTP 應用能回應，不代表其他服務已連線成功。
	return {"status": "ok"}


@app.post("/auth/google/desktop/exchange")
def desktop_exchange(payload: DesktopExchangeRequest, response: Response):
	# 新增朋友的 Desktop OAuth 功能，不取代既有 JWT 流程。
	response.headers["Cache-Control"] = "no-store"
	try:
		return exchange_google_code(
			payload.code,
			payload.code_verifier,
			payload.redirect_uri,
			GOOGLE_CLIENT_ID,
			verify_desktop_google_token,
		)
	except HTTPException as exc:
		return JSONResponse(
			status_code=exc.status_code,
			content={"detail": exc.detail},
			headers={"Cache-Control": "no-store"},
		)


@app.post("/auth/google")
def google_login(payload: GoogleLoginRequest):
	# 先驗證 Google 身分，不能直接相信前端傳入的資料。
	info = verify_google_token(payload.id_token)

	try:
		# 查詢或建立 DynamoDB 玩家資料。
		player = get_or_create_google_player(info)
	except (ClientError, BotoCoreError) as exc:
		print(f"DynamoDB 玩家資料處理失敗：{type(exc).__name__}")

		if isinstance(exc, ClientError):
			print("AWS Error Code:", exc.response.get("Error", {}).get("Code"))
			print("Cancellation Reasons:", [
				reason.get("Code")
				for reason in exc.response.get("CancellationReasons", [])
			])

		raise HTTPException(
			status_code=503,
			detail="玩家資料服務暫時無法使用，請稍後再試",
		) from exc

	except ValueError as exc:
		raise HTTPException(
			status_code=401,
			detail="Google 身分資料不完整",
		) from exc

	try:
		# 為這次登入建立獨立的工作階段。
		session_id = str(uuid.uuid4())
		access_token = create_access_token(player["id"])
		refresh_token = create_refresh_token(player["id"], session_id)

		# DynamoDB 只保存 Refresh Token 的雜湊。
		refresh_token_hash = hash_refresh_token(refresh_token)
		expires_at = int(
			(
				datetime.now(timezone.utc)
				+ timedelta(days=REFRESH_TOKEN_DAYS)
			).timestamp()
		)

		# 必須先成功建立工作階段，才能回傳 Refresh Token。
		create_session(
			player_id=player["id"],
			session_id=session_id,
			refresh_token_hash=refresh_token_hash,
			expires_at=expires_at,
		)

	except (ClientError, BotoCoreError, RuntimeError, KeyError, ValueError) as exc:
		print(f"登入憑證或工作階段建立失敗：{type(exc).__name__}")
		raise HTTPException(
			status_code=503,
			detail="登入憑證服務暫時無法使用，請稍後再試",
		) from exc

	return {
		"success": True,
		"player": player,
		"access_token": access_token,
		"refresh_token": refresh_token,
		"token_type": "Bearer",
		"expires_in": ACCESS_TOKEN_MINUTES * 60,
		"refresh_expires_in": REFRESH_TOKEN_DAYS * 24 * 60 * 60,
	}


@app.get("/auth/me")
def get_current_player(authorization: str | None = Header(default=None)):
	"""使用後端 JWT 驗證登入狀態並取得玩家資料。"""
	if not authorization:
		raise HTTPException(status_code=401, detail="缺少登入憑證")

	scheme, separator, token = authorization.partition(" ")
	if not separator or scheme.lower() != "bearer" or not token.strip():
		raise HTTPException(status_code=401, detail="Authorization 格式錯誤")

	try:
		player_id = verify_access_token(token.strip())
	except ValueError as exc:
		raise HTTPException(
			status_code=401, detail="登入憑證無效或已過期"
		) from exc
	except (ClientError, BotoCoreError, RuntimeError) as exc:
		print(f"JWT 驗證服務失敗：{type(exc).__name__}")
		raise HTTPException(
			status_code=503, detail="登入驗證服務暫時無法使用"
		) from exc

	try:
		player = get_player_by_id(player_id)
	except (ClientError, BotoCoreError) as exc:
		print(f"DynamoDB 玩家查詢失敗：{type(exc).__name__}")
		raise HTTPException(
			status_code=503, detail="玩家資料服務暫時無法使用"
		) from exc

	if player is None:
		raise HTTPException(
			status_code=401, detail="玩家不存在或登入狀態無效"
		)

	return {"success": True, "player": player}


@app.post("/auth/refresh")
def refresh_login(payload: RefreshTokenRequest):
	"""驗證並輪替 Refresh Token，發放新的登入憑證。"""
	try:
		player_id, session_id = verify_refresh_token(payload.refresh_token)
	except ValueError as exc:
		raise HTTPException(
			status_code=401, detail="Refresh Token 無效或已過期"
		) from exc
	except (ClientError, BotoCoreError, RuntimeError) as exc:
		print(f"Refresh Token 驗證服務失敗：{type(exc).__name__}")
		raise HTTPException(
			status_code=503, detail="登入驗證服務暫時無法使用"
		) from exc

	try:
		session = get_session(player_id, session_id)
	except (ClientError, BotoCoreError) as exc:
		print(f"工作階段查詢失敗：{type(exc).__name__}")
		raise HTTPException(
			status_code=503, detail="工作階段服務暫時無法使用"
		) from exc

	if session is None:
		raise HTTPException(status_code=401, detail="登入工作階段不存在")

	try:
		player = get_player_by_id(player_id)
	except (ClientError, BotoCoreError) as exc:
		print(f"玩家資料查詢失敗：{type(exc).__name__}")
		raise HTTPException(
			status_code=503, detail="玩家資料服務暫時無法使用"
		) from exc

	if player is None:
		raise HTTPException(status_code=401, detail="玩家不存在")

	try:
		new_access_token = create_access_token(player_id)
		new_refresh_token = create_refresh_token(player_id, session_id)
		old_hash = hash_refresh_token(payload.refresh_token)
		new_hash = hash_refresh_token(new_refresh_token)
		new_expires_at = int(
			(
				datetime.now(timezone.utc)
				+ timedelta(days=REFRESH_TOKEN_DAYS)
			).timestamp()
		)
		rotated = rotate_refresh_token(
			player_id=player_id,
			session_id=session_id,
			old_token_hash=old_hash,
			new_token_hash=new_hash,
			new_expires_at=new_expires_at,
		)

	except (ClientError, BotoCoreError, RuntimeError) as exc:
		print(f"Refresh Token 輪替失敗：{type(exc).__name__}")
		raise HTTPException(
			status_code=503, detail="登入憑證服務暫時無法使用"
		) from exc

	if not rotated:
		raise HTTPException(
			status_code=401, detail="Refresh Token 已失效或已被使用"
		)

	return {
		"success": True,
		"access_token": new_access_token,
		"refresh_token": new_refresh_token,
		"token_type": "Bearer",
		"expires_in": ACCESS_TOKEN_MINUTES * 60,
		"refresh_expires_in": REFRESH_TOKEN_DAYS * 24 * 60 * 60,
	}


@app.post("/auth/logout")
def logout(payload: RefreshTokenRequest):
	"""撤銷目前 Refresh Token 對應的登入工作階段。"""
	try:
		player_id, session_id = verify_refresh_token(payload.refresh_token)
	except ValueError as exc:
		raise HTTPException(
			status_code=401, detail="Refresh Token 無效或已過期"
		) from exc
	except (ClientError, BotoCoreError, RuntimeError) as exc:
		print(f"登出 Token 驗證失敗：{type(exc).__name__}")
		raise HTTPException(
			status_code=503, detail="登入驗證服務暫時無法使用"
		) from exc

	try:
		token_hash = hash_refresh_token(payload.refresh_token)
	except (RuntimeError, ValueError) as exc:
		print(f"登出 Token Hash 計算失敗：{type(exc).__name__}")
		raise HTTPException(
			status_code=503, detail="登入憑證服務暫時無法使用"
		) from exc

	try:
		revoked = revoke_session(
			player_id=player_id,
			session_id=session_id,
			refresh_token_hash=token_hash,
		)
	except (ClientError, BotoCoreError) as exc:
		print(f"DynamoDB Session 撤銷失敗：{type(exc).__name__}")
		raise HTTPException(
			status_code=503, detail="Session 撤銷服務暫時無法使用"
		) from exc

	if not revoked:
		raise HTTPException(
			status_code=401,
			detail="Session 已失效或 Refresh Token 已被使用",
		)

	return {"success": True, "message": "登出成功"}


@app.get("/players/me/save")
def get_my_game_save(authorization: str | None = Header(default=None)):
	"""讀取目前登入玩家的雲端進度。"""
	auth_result = get_current_player(authorization)
	player_id = auth_result["player"]["id"]

	try:
		record = load_player_game(player_id)
	except (ClientError, BotoCoreError, KeyError, ValueError) as exc:
		print(f"雲端存檔讀取失敗：{type(exc).__name__}")
		raise HTTPException(
			status_code=503, detail="雲端存檔暫時無法讀取"
		) from exc

	if record is None:
		return {"success": True, "has_save": False, "save": None}

	return {
		"success": True,
		"has_save": True,
		"save": record["save"],
		"updated_at": record["updated_at"],
	}


@app.put("/players/me/save")
def put_my_game_save(
	payload: GameSaveRequest,
	authorization: str | None = Header(default=None),
):
	"""儲存目前登入玩家的遊戲進度。"""
	auth_result = get_current_player(authorization)
	player_id = auth_result["player"]["id"]
	save_data = payload.save

	if (
		save_data.get("version") != 2
		or not isinstance(save_data.get("user_name"), str)
		or not save_data["user_name"].strip()
		or not isinstance(save_data.get("section_id"), str)
		or not save_data["section_id"].strip()
	):
		raise HTTPException(status_code=422, detail="遊戲存檔格式不正確")

	try:
		updated_at = save_player_game(player_id, save_data)
	except ValueError as exc:
		raise HTTPException(
			status_code=413, detail="遊戲存檔過大或內容無效"
		) from exc
	except (ClientError, BotoCoreError) as exc:
		print(f"雲端存檔寫入失敗：{type(exc).__name__}")
		raise HTTPException(
			status_code=503, detail="雲端存檔暫時無法寫入"
		) from exc

	return {
		"success": True,
		"message": "雲端存檔成功",
		"updated_at": updated_at,
	}


@app.post("/players/me/errors", status_code=201)
def record_player_error(
	payload: PlayerErrorRequest,
	authorization: str | None = Header(default=None),
):
	"""記錄目前登入玩家的程式執行錯誤。"""
	auth_result = get_current_player(authorization)
	player_id = auth_result["player"]["id"]

	try:
		inserted = save_player_error(player_id, payload.dict())
	except ValueError as exc:
		raise HTTPException(status_code=422, detail="錯誤紀錄格式不正確") from exc
	except (ClientError, BotoCoreError) as exc:
		print(f"錯誤紀錄儲存失敗：{type(exc).__name__}")
		raise HTTPException(
			status_code=503, detail="錯誤紀錄服務暫時無法使用"
		) from exc

	return {"success": True, "duplicate": not inserted}


@app.post("/ai/generate")
def ai_generate(
	payload: AIRequest,
	authorization: str | None = Header(default=None),
):
	# 預設匿名可用；登入政策仍由獨立 AI policy 決定。
	authorize_ai(authorization, verify_google_token)

	if not payload.prompt.strip():
		raise HTTPException(status_code=422, detail="Prompt 不可為空白")

	return {"text": generate(payload.prompt)}


@app.get("/characters/{character_id}")
def read_character(character_id: str):
	try:
		character = get_character(character_id)
	except (ClientError, BotoCoreError) as exc:
		print(f"角色資料讀取失敗：{type(exc).__name__}")
		raise HTTPException(
			status_code=503,
			detail="角色資料服務暫時無法使用"
		) from exc

	if character is None:
		raise HTTPException(
			status_code=404,
			detail="找不到角色資料"
		)

	return {
		"success": True,
		"character": character
	}

@app.get("/knowledge/{knowledge_id}")
def read_knowledge(knowledge_id: str):
	try:
		knowledge = get_knowledge(knowledge_id)
	except (ClientError, BotoCoreError) as exc:
		print(f"教學知識讀取失敗：{type(exc).__name__}")
		raise HTTPException(
			status_code=503,
			detail="教學知識服務暫時無法使用"
		) from exc

	if knowledge is None:
		raise HTTPException(
			status_code=404,
			detail="找不到教學知識"
		)

	return {
		"success": True,
		"knowledge": knowledge
	}


@app.get("/stories/{story_id}")
def read_story(story_id: str):
	try:
		story = get_story(story_id)
	except (ClientError, BotoCoreError) as exc:
		print(f"劇情資料讀取失敗：{type(exc).__name__}")
		raise HTTPException(
			status_code=503,
			detail="劇情資料服務暫時無法使用"
		) from exc

	if story is None:
		raise HTTPException(
			status_code=404,
			detail="找不到劇情資料"
		)

	return {
		"success": True,
		"story": story
	}


@app.post("/ai/game-reply")
def ai_game_reply(
	payload: GameAIRequest,
	authorization: str | None = Header(default=None),
):
	# 沿用原本的 AI 存取政策
	authorize_ai(authorization, verify_google_token)

	if not payload.player_message.strip():
		raise HTTPException(
			status_code=422,
			detail="玩家問題不可為空白"
		)

	try:
		text = generate_game_reply(
			player_message=payload.player_message,
			character_id=payload.character_id,
			knowledge_id=payload.knowledge_id,
			story_id=payload.story_id,
		)

	except (ClientError, BotoCoreError) as exc:
		print(f"遊戲 AI 資料讀取失敗：{type(exc).__name__}")
		raise HTTPException(
			status_code=503,
			detail="遊戲資料暫時無法讀取"
		) from exc

	return {"text": text}
