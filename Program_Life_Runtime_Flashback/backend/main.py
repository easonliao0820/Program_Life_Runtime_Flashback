
import os
from pathlib import Path

from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from google.auth.transport import requests
from google.oauth2 import id_token

# 讀取專案根目錄的 .env
PROJECT_ROOT = Path(__file__).resolve().parent.parent
load_dotenv(PROJECT_ROOT / ".env")

GOOGLE_CLIENT_ID = os.getenv("GOOGLE_OAUTH_CLIENT_ID")

if not GOOGLE_CLIENT_ID:
	raise RuntimeError(
        "缺少 GOOGLE_OAUTH_CLIENT_ID 環境變數"
	)

# 建立 FastAPI 應用程式
app = FastAPI(title="Program Life Backend")


# Google 登入請求格式
class GoogleLoginRequest(BaseModel):
	id_token: str


# 測試後端是否正常運作
@app.get("/health")
def health():
	return {"status": "ok"}


# 驗證 Google 登入身分
@app.post("/auth/google")
def google_login(payload: GoogleLoginRequest):
	try:
		info = id_token.verify_oauth2_token(
			payload.id_token,
			requests.Request(),
			GOOGLE_CLIENT_ID
		)

		return {
			"success": True,
			"player": {
				"id": info["sub"],
				"name": info.get("name", ""),
				"email": info.get("email", ""),
				"avatar_url": info.get("picture", "")
			}
		}

	except (ValueError, KeyError):
		raise HTTPException(
			status_code=401,
			detail="Google ID Token 驗證失敗"
		)
