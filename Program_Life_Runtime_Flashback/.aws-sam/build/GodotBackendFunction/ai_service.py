"""Bounded Gemini transport; no retry and no credentials in responses/logs."""
import json
import os
from functools import lru_cache
from threading import BoundedSemaphore
from urllib import error as urlerror
from urllib import request as urlrequest

import boto3
from botocore.config import Config
from fastapi import HTTPException

_slots = BoundedSemaphore(1)  # Per process only; not a global/user rate limit.
MAX_RESPONSE_BYTES = 65536
MAX_TEXT_CHARS = 4000


@lru_cache(maxsize=1)
def get_api_key():
    # Lambda always uses SSM, even if API_KEY was accidentally set there.
    if not os.getenv('AWS_LAMBDA_FUNCTION_NAME') and os.getenv('API_KEY'):
        return os.environ['API_KEY']
    ssm = boto3.client(
        'ssm', region_name=os.getenv('AWS_REGION', 'ap-southeast-2'),
        config=Config(connect_timeout=2, read_timeout=2, retries={'total_max_attempts': 1}),
    )
    return ssm.get_parameter(
        Name='/godot-backend/API_KEY', WithDecryption=True,
    )['Parameter']['Value']


def generate(prompt: str) -> str:
    if not _slots.acquire(blocking=False):
        raise HTTPException(503, 'AI 正在處理其他請求，請稍後再試')
    try:
        model = os.getenv('GEMINI_MODEL', 'gemini-2.0-flash')
        body = json.dumps({
            'contents': [{'parts': [{'text': prompt}]}],
            'generationConfig': {'maxOutputTokens': 512},
        }).encode('utf-8')
        req = urlrequest.Request(
            f'https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent',
            data=body, method='POST',
            headers={'Content-Type': 'application/json', 'x-goog-api-key': get_api_key()},
        )
        with urlrequest.urlopen(req, timeout=8) as response:
            raw = response.read(MAX_RESPONSE_BYTES + 1)
        if len(raw) > MAX_RESPONSE_BYTES:
            raise HTTPException(502, 'AI 回覆過長')
        result = json.loads(raw)
        candidates = result.get('candidates', [])
        parts = candidates[0].get('content', {}).get('parts', []) if candidates else []
        text = ''.join(p.get('text', '') for p in parts if not p.get('thought')).strip()
        if not text:
            raise HTTPException(502, 'AI 沒有產生文字')
        return text[:MAX_TEXT_CHARS]
    except urlerror.HTTPError as exc:
        raise HTTPException(429 if exc.code == 429 else 502, 'AI 服務暫時無法使用') from exc
    except (urlerror.URLError, TimeoutError) as exc:
        raise HTTPException(503, 'AI 服務連線失敗或逾時') from exc
    except HTTPException:
        raise
    except Exception as exc:
        # Do not log exceptions containing upstream request details.
        raise HTTPException(502, 'AI 服務暫時無法處理請求') from exc
    finally:
        _slots.release()
