from mangum import Mangum
from main import app

# 將 Lambda Function URL 事件轉成 FastAPI 可處理的 ASGI 請求。
# template.yaml 的 Handler 必須對應此檔案與變數：lambda_handler.handler。
handler = Mangum(app)