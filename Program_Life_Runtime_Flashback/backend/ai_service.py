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

# 只限制單一 Python 程序的同時生成數，不是玩家冷卻或跨 Lambda 全域限流。
_slots = BoundedSemaphore(1)  # Per process only; not a global/user rate limit.
MAX_RESPONSE_BYTES = 65536
MAX_TEXT_CHARS = 4000


@lru_cache(maxsize=1)
def get_api_key():
    # 暖啟動期間快取金鑰，避免每次 AI 請求都讀 SSM；輪替後需更新快取／程序。
    # Lambda 一律讀 SSM，即使誤設 API_KEY 也不採用；本機開發才允許環境金鑰。
    if not os.getenv('AWS_LAMBDA_FUNCTION_NAME') and os.getenv('API_KEY'):
        return os.environ['API_KEY']
    ssm = boto3.client(
        'ssm', region_name=os.getenv('AWS_REGION', 'ap-southeast-2'),
        config=Config(connect_timeout=2, read_timeout=2, retries={'total_max_attempts': 1}),
    )
    # WithDecryption 讓後端取得解密值；IAM／KMS 權限由既有 execution role 管理。
    # 金鑰只用在服務端呼叫，不能放進 HTTP 回應或日誌。
    return ssm.get_parameter(
        Name='/godot-backend/API_KEY', WithDecryption=True,
    )['Parameter']['Value']


def generate(prompt: str) -> str:
    # 忙碌時直接回應，不排無限佇列，也不在此自動重試。
    if not _slots.acquire(blocking=False):
        raise HTTPException(503, 'AI 正在處理其他請求，請稍後再試')
    try:
        model = os.getenv('GEMINI_MODEL', 'gemini-2.0-flash')
        # 輸入長度由路由限制；此處再限制生成 Token 數，降低失控輸出成本。
        body = json.dumps({
            'contents': [{'parts': [{'text': prompt}]}],
            'generationConfig': {'maxOutputTokens': 512},
        }).encode('utf-8')
        req = urlrequest.Request(
            f'https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent',
            data=body, method='POST',
            headers={'Content-Type': 'application/json', 'x-goog-api-key': get_api_key()},
        )
        # 8 秒是 socket 逾時，不是整個流程的嚴格總時限；Lambda 仍有總逾時。
        with urlrequest.urlopen(req, timeout=8) as response:
            # 多讀一個位元組來判定超限，不將任意大的上游回應全部讀入記憶體。
            raw = response.read(MAX_RESPONSE_BYTES + 1)
        if len(raw) > MAX_RESPONSE_BYTES:
            raise HTTPException(502, 'AI 回覆過長')
        result = json.loads(raw)
        candidates = result.get('candidates', [])
        parts = candidates[0].get('content', {}).get('parts', []) if candidates else []
        # 只取第一個候選的可顯示文字，略過標記為 thought 的內容。
        text = ''.join(p.get('text', '') for p in parts if not p.get('thought')).strip()
        if not text:
            raise HTTPException(502, 'AI 沒有產生文字')
        return text[:MAX_TEXT_CHARS]
    except urlerror.HTTPError as exc:
        # 不回傳上游原始 body；保留 429 讓客戶端辨識供應端額度問題。
        raise HTTPException(429 if exc.code == 429 else 502, 'AI 服務暫時無法使用') from exc
    except (urlerror.URLError, TimeoutError) as exc:
        raise HTTPException(503, 'AI 服務連線失敗或逾時') from exc
    except HTTPException:
        raise
    except Exception as exc:
        # 例外可能含請求資訊，因此只回傳固定訊息，不記錄原始例外或憑證。
        raise HTTPException(502, 'AI 服務暫時無法處理請求') from exc
    finally:
        # 成功或失敗都必須釋放，否則此程序後續請求會一直被判定忙碌。
        _slots.release()
