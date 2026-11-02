import os
from pathlib import Path

from dotenv import load_dotenv
from fastapi import FastAPI, Header, HTTPException
from google.auth.transport import requests as google_requests
from google.oauth2 import id_token
from pydantic import BaseModel, Field

from ai_access_policy import authorize_ai
from ai_service import generate

# 本機開發才從專案根目錄補讀設定；既有環境變數不會被覆蓋。
# Lambda 的 Google Client ID 由部署環境提供，不能省略 audience 驗證。
PROJECT_ROOT = Path(__file__).resolve().parent.parent
load_dotenv(PROJECT_ROOT / '.env')
GOOGLE_CLIENT_ID = os.getenv('GOOGLE_OAUTH_CLIENT_ID')

if not GOOGLE_CLIENT_ID:
	raise RuntimeError('缺少 GOOGLE_OAUTH_CLIENT_ID 環境變數')

app = FastAPI(title='Program Life Backend')

class GoogleLoginRequest(BaseModel):
	# 前端取得的 Google 身分憑證；接收後仍需驗證，不可直接當玩家 ID。
	id_token: str

class AIRequest(BaseModel):
	# 限制的是完整 prompt（包含角色設定與玩家程式），不是只有玩家輸入。
	prompt: str = Field(min_length=1, max_length=4000)

# 登入與未來私人資料 API 共用的驗證接點；不受匿名 AI 政策影響。
def verify_google_token(token: str) -> dict:
	try:
		return id_token.verify_oauth2_token(
			token, google_requests.Request(), GOOGLE_CLIENT_ID
		)
	except (ValueError, KeyError) as exc:
		raise HTTPException(status_code=401, detail='Google ID Token 驗證失敗') from exc

@app.get('/health')
def health():
	# 只確認 HTTP 應用能回應，不代表 SSM、Gemini 或資料庫已連線成功。
	return {'status': 'ok'}

@app.post('/auth/google')
def google_login(payload: GoogleLoginRequest):
	info = verify_google_token(payload.id_token)
	# sub 是 Google 帳號的穩定識別，可供未來 DynamoDB 使用。
	# 此處只回傳已驗證資料，尚未建立資料庫記錄或簽發自家 session。
	return {
		'success': True,
		'player': {
			'id': info['sub'],
			'name': info.get('name', ''),
			'email': info.get('email', ''),
			'avatar_url': info.get('picture', ''),
		},
	}

@app.post('/ai/generate')
def ai_generate(payload: AIRequest, authorization: str | None = Header(default=None)):
	# 預設匿名可用；未來是否要求登入只由獨立 AI policy 決定。
	authorize_ai(authorization, verify_google_token)
	# min_length 無法排除全空白，因此在呼叫 Gemini 前再檢查一次。
	if not payload.prompt.strip():
		raise HTTPException(status_code=422, detail='Prompt 不可為空白')
	# Godot 只收到文字；金鑰取得與上游錯誤由 ai_service 處理。
	return {'text': generate(payload.prompt)}
