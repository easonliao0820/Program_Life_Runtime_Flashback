"""AI-only policy. Save/player APIs must authenticate independently."""
import os
from fastapi import HTTPException


def enabled(name: str) -> bool:
    return os.getenv(name, 'false').strip().lower() in {'true', '1', 'yes'}


def authorize_ai(authorization, verify_token):
    # Reserved switches: fail explicitly rather than pretend enforcement exists.
    if enabled('AI_RATE_LIMIT_ENABLED') or enabled('AI_DAILY_QUOTA_ENABLED'):
        raise HTTPException(503, 'AI 限流與每日配額機制尚未實作，請停用預留設定')
    if not enabled('AI_REQUIRE_LOGIN'):
        return None
    scheme, _, token = (authorization or '').partition(' ')
    if scheme.lower() != 'bearer' or not token.strip():
        raise HTTPException(401, '請先登入 Google')
    return verify_token(token.strip())
