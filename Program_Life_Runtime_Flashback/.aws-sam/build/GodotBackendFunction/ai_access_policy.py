"""AI-only policy. Save/player APIs must authenticate independently."""
import os
from fastapi import HTTPException


def enabled(name: str) -> bool:
    # 未設定一律 false；每次請求讀取，讓 policy 與 API 路由保持分離。
    return os.getenv(name, 'false').strip().lower() in {'true', '1', 'yes'}


def authorize_ai(authorization, verify_token):
    # 預留開關不是完整限流／配額功能；誤開時明確拒絕，避免宣稱已有保護。
    if enabled('AI_RATE_LIMIT_ENABLED') or enabled('AI_DAILY_QUOTA_ENABLED'):
        raise HTTPException(503, 'AI 限流與每日配額機制尚未實作，請停用預留設定')
    if not enabled('AI_REQUIRE_LOGIN'):
        # 匿名模式不解析或驗證 Token，登入狀態不影響 AI 使用。
        return None
    # 只有要求登入時才接受 Bearer Token，並交由既有驗證函式確認身分。
    # 未來 /save、玩家資料 API 必須獨立要求驗證，不可套用匿名分支。
    scheme, _, token = (authorization or '').partition(' ')
    if scheme.lower() != 'bearer' or not token.strip():
        raise HTTPException(401, '請先登入 Google')
    return verify_token(token.strip())
