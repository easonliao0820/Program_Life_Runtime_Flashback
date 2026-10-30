import os
from pathlib import Path

from dotenv import load_dotenv
from fastapi import FastAPI, Header, HTTPException
from google.auth.transport import requests as google_requests
from google.oauth2 import id_token
from pydantic import BaseModel, Field

from ai_access_policy import authorize_ai
from ai_service import generate

PROJECT_ROOT = Path(__file__).resolve().parent.parent
load_dotenv(PROJECT_ROOT / '.env')
GOOGLE_CLIENT_ID = os.getenv('GOOGLE_OAUTH_CLIENT_ID')

if not GOOGLE_CLIENT_ID:
    raise RuntimeError('缺少 GOOGLE_OAUTH_CLIENT_ID 環境變數')

app = FastAPI(title='Program Life Backend')

class GoogleLoginRequest(BaseModel):
    id_token: str

class AIRequest(BaseModel):
    prompt: str = Field(min_length=1, max_length=4000)

def verify_google_token(token: str) -> dict:
    try:
        return id_token.verify_oauth2_token(
            token, google_requests.Request(), GOOGLE_CLIENT_ID
        )
    except (ValueError, KeyError) as exc:
        raise HTTPException(status_code=401, detail='Google ID Token 驗證失敗') from exc

@app.get('/health')
def health():
    return {'status': 'ok'}

@app.post('/auth/google')
def google_login(payload: GoogleLoginRequest):
    info = verify_google_token(payload.id_token)
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
    authorize_ai(authorization, verify_google_token)
    if not payload.prompt.strip():
        raise HTTPException(status_code=422, detail='Prompt 不可為空白')
    return {'text': generate(payload.prompt)}
