
import hashlib
import os
import uuid
from datetime import datetime, timedelta, timezone
from functools import lru_cache

import boto3
import jwt
from botocore.exceptions import BotoCoreError, ClientError


AWS_REGION = os.getenv("AWS_REGION", "ap-southeast-2")
JWT_SECRET_PARAMETER = "/godot-backend/JWT_SECRET"

JWT_ALGORITHM = "HS256"
JWT_ISSUER = "program-life-backend"
JWT_AUDIENCE = "program-life-game"

ACCESS_TOKEN_MINUTES = 15
REFRESH_TOKEN_DAYS = 7


@lru_cache(maxsize=1)
def _get_jwt_secret() -> str:
    """從 AWS SSM SecureString 取得 JWT 簽章密鑰。"""
    ssm = boto3.client("ssm", region_name=AWS_REGION)

    response = ssm.get_parameter(
        Name=JWT_SECRET_PARAMETER,
        WithDecryption=True,
    )

    secret = response["Parameter"]["Value"]

    if len(secret) < 32:
        raise RuntimeError("JWT Secret 長度不足，至少需要 32 個字元")

    return secret


def create_access_token(player_id: str) -> str:
    """為已完成身分驗證的玩家簽發 Access Token。"""
    if not player_id:
        raise ValueError("player_id 不可為空")

    now = datetime.now(timezone.utc)

    payload = {
        "sub": player_id,
        "iss": JWT_ISSUER,
        "aud": JWT_AUDIENCE,
        "type": "access",
        "iat": now,
        "nbf": now,
        "exp": now + timedelta(minutes=ACCESS_TOKEN_MINUTES),
    }

    return jwt.encode(
        payload,
        _get_jwt_secret(),
        algorithm=JWT_ALGORITHM,
    )


def verify_access_token(token: str) -> str:
    """驗證 Access Token，成功後回傳玩家 ID。"""
    if not token:
        raise ValueError("缺少 Access Token")

    try:
        payload = jwt.decode(
            token,
            _get_jwt_secret(),
            algorithms=[JWT_ALGORITHM],
            issuer=JWT_ISSUER,
            audience=JWT_AUDIENCE,
            options={
                "require": [
                    "sub",
                    "iss",
                    "aud",
                    "type",
                    "iat",
                    "nbf",
                    "exp",
                ]
            },
        )
    except jwt.InvalidTokenError as exc:
        raise ValueError("Access Token 無效或已過期") from exc

    if payload.get("type") != "access":
        raise ValueError("Token 類型錯誤")

    player_id = payload.get("sub")

    if not isinstance(player_id, str) or not player_id:
        raise ValueError("Token 缺少有效的玩家 ID")

    return player_id


def create_refresh_token(player_id: str, session_id: str) -> str:
    """為玩家工作階段簽發有效期 7 天的 Refresh Token。"""
    if not player_id or not session_id:
        raise ValueError("player_id 與 session_id 不可為空")

    now = datetime.now(timezone.utc)

    payload = {
        "sub": player_id,
        "sid": session_id,
        "jti": str(uuid.uuid4()),
        "iss": JWT_ISSUER,
        "aud": JWT_AUDIENCE,
        "type": "refresh",
        "iat": now,
        "nbf": now,
        "exp": now + timedelta(days=REFRESH_TOKEN_DAYS),
    }

    return jwt.encode(
        payload,
        _get_jwt_secret(),
        algorithm=JWT_ALGORITHM,
    )


def verify_refresh_token(token: str) -> tuple[str, str]:
    """驗證 Refresh Token，回傳 (player_id, session_id)。"""
    if not token:
        raise ValueError("缺少 Refresh Token")

    try:
        payload = jwt.decode(
            token,
            _get_jwt_secret(),
            algorithms=[JWT_ALGORITHM],
            issuer=JWT_ISSUER,
            audience=JWT_AUDIENCE,
            options={
                "require": [
                    "sub",
                    "sid",
                    "jti",
                    "iss",
                    "aud",
                    "type",
                    "iat",
                    "nbf",
                    "exp",
                ]
            },
        )
    except jwt.InvalidTokenError as exc:
        raise ValueError("Refresh Token 無效或已過期") from exc

    if payload.get("type") != "refresh":
        raise ValueError("Token 類型錯誤")

    player_id = payload.get("sub")
    session_id = payload.get("sid")
    token_id = payload.get("jti")

    if not all(
        isinstance(value, str) and value
        for value in (player_id, session_id, token_id)
    ):
        raise ValueError("Refresh Token 缺少有效的識別資訊")

    return player_id, session_id


def hash_refresh_token(token: str) -> str:
    """計算 Refresh Token 的 SHA-256 雜湊，不儲存原始 Token。"""
    if not token:
        raise ValueError("缺少 Refresh Token")

    return hashlib.sha256(token.encode("utf-8")).hexdigest()
