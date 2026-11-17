"""Desktop 換碼：憑證只留在後端，不記錄請求或上游原始錯誤。"""
import json
import math
import os
import re
import time
from functools import lru_cache
from threading import BoundedSemaphore
from urllib.parse import urlsplit

import boto3
import requests
from botocore.config import Config
from fastapi import HTTPException
from google.auth.exceptions import TransportError
from google.auth.transport.requests import Request as GoogleRequest

TOKEN_URL = 'https://oauth2.googleapis.com/token'
SECRET_PARAMETER = '/godot-backend/GOOGLE_OAUTH_CLIENT_SECRET'
MAX_RESPONSE_BYTES = 65536
_exchange_slots = BoundedSemaphore(2)  # 僅程序內在途保護，不影響 AI 或代表全域限流。


def validate_exchange(code: str, verifier: str, redirect_uri: str) -> None:
    if not re.fullmatch(r'[\x21-\x7e]{1,4096}', code):
        raise HTTPException(422, 'invalid_auth_request')
    if not re.fullmatch(r'[A-Za-z0-9._~-]{43,128}', verifier):
        raise HTTPException(422, 'invalid_auth_request')
    try:
        uri = urlsplit(redirect_uri)
        port = uri.port
        # 僅接受 Godot 現有的 canonical loopback 格式，不接受任意 URL／Client。
        valid = (
            uri.scheme == 'http' and uri.hostname == '127.0.0.1'
            and port is not None and 1 <= port <= 65535
            and redirect_uri == f'http://127.0.0.1:{port}/'
        )
    except ValueError:
        valid = False
    if not valid:
        raise HTTPException(422, 'invalid_auth_request')


@lru_cache(maxsize=1)
def _load_client_secret(_cache_window) -> str:
    # 僅在登入端點使用時才讀 SSM；缺 Secret 不會阻止 AI／health 啟動。
    ssm = boto3.client('ssm', region_name=os.getenv('AWS_REGION', 'ap-southeast-2'), config=Config(
        connect_timeout=1, read_timeout=1, retries={'total_max_attempts': 1},
    ))
    value = ssm.get_parameter(Name=SECRET_PARAMETER, WithDecryption=True)['Parameter']['Value']
    if not isinstance(value, str) or not value.strip():
        raise ValueError('empty OAuth configuration')
    return value


def get_client_secret() -> str:
    # 最多約五分鐘的暖程序快取，Secret 輪替不必依賴程序永久重啟。
    return _load_client_secret(int(time.monotonic() // 300))


def exchange_google_code(code, verifier, redirect_uri, client_id, verify_token):
    validate_exchange(code, verifier, redirect_uri)
    if not _exchange_slots.acquire(blocking=False):
        raise HTTPException(503, 'oauth_service_busy')
    try:
        return _exchange_once(code, verifier, redirect_uri, client_id, verify_token)
    finally:
        _exchange_slots.release()


def _exchange_once(code, verifier, redirect_uri, client_id, verify_token):
    deadline = time.monotonic() + 10.0

    def remaining(limit):
        value = deadline - time.monotonic()
        if value <= 0:
            raise HTTPException(504, 'oauth_exchange_timeout')
        return min(limit, value)

    try:
        secret = get_client_secret()
    except Exception:
        raise HTTPException(503, 'oauth_configuration_unavailable') from None

    try:
        # 固定 endpoint／client；不讀取使用者指定的金鑰路徑、不跟隨 redirect。
        # Session 預設不重試 POST。code 已可能被消耗時，任何失敗都要求重新授權。
        with requests.Session() as session:
            with session.post(
                TOKEN_URL,
                data={
                    'code': code, 'code_verifier': verifier,
                    'redirect_uri': redirect_uri, 'client_id': client_id,
                    'client_secret': secret, 'grant_type': 'authorization_code',
                },
                timeout=(remaining(2), remaining(5)), allow_redirects=False, stream=True,
            ) as response:
                raw = bytearray()
                for chunk in response.iter_content(chunk_size=4096):
                    remaining(10)
                    raw.extend(chunk)
                    if len(raw) > MAX_RESPONSE_BYTES:
                        raise HTTPException(502, 'oauth_provider_unavailable')
                try:
                    data = json.loads(raw)
                except (ValueError, UnicodeError):
                    raise HTTPException(502, 'oauth_provider_unavailable') from None
                if not isinstance(data, dict):
                    raise HTTPException(502, 'oauth_provider_unavailable')
                if response.status_code != 200:
                    error = data.get('error')
                    if error in ('invalid_grant', 'access_denied'):
                        raise HTTPException(401, 'authorization_invalid')
                    if error in ('invalid_client', 'unauthorized_client', 'invalid_request'):
                        raise HTTPException(503, 'oauth_configuration_unavailable')
                    raise HTTPException(502, 'oauth_provider_unavailable')
                token = data.get('id_token')
                if not isinstance(token, str) or not token:
                    raise HTTPException(401, 'authorization_invalid')

            google_request = GoogleRequest(session=session)

            def bounded_transport(*args, **kwargs):
                kwargs['timeout'] = remaining(3)
                return google_request(*args, **kwargs)

            # 與既有 /auth/google 共用簽章、issuer、audience 與 exp 驗證。
            info = verify_token(token, transport=bounded_transport)
            remaining(10)
            sub, exp = info.get('sub'), info.get('exp')
            if (
                not isinstance(sub, str) or not sub.strip()
                or not isinstance(exp, (int, float)) or isinstance(exp, bool)
                or not math.isfinite(exp)
                or info.get('azp', client_id) != client_id
            ):
                raise HTTPException(401, 'authorization_invalid')
            expires_in = int(exp - time.time())
            if expires_in <= 0:
                raise HTTPException(401, 'authorization_invalid')
            return {
                'success': True, 'id_token': token, 'expires_in': expires_in,
                'player': {
                    'id': sub, 'name': str(info.get('name', '')),
                    'email': str(info.get('email', '')),
                    'avatar_url': str(info.get('picture', '')),
                },
            }
    except HTTPException:
        raise
    except (requests.Timeout, TransportError):
        raise HTTPException(504, 'oauth_exchange_timeout') from None
    except Exception:
        raise HTTPException(502, 'oauth_provider_unavailable') from None
