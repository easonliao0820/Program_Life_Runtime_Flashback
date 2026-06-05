# AiBridge.gd (請確保在專案設定 -> Autoload 中將此腳本命名為 AiBridge)
extends Node

signal ai_response_received(text)

# 移除 @onready，改成這樣：
var http: HTTPRequest 

func _ready():
	# 用程式碼主動檢查並建立，100% 安全
	if not has_node("HTTPRequest"):
		http = HTTPRequest.new()
		add_child(http)
	else:
		http = $HTTPRequest
	
	http.request_completed.connect(
		_on_http_request_request_completed
	)

func translate_error(error: String, code: String):
	var prompt = """
你是一個教學型AI（像遊戲中的NPC「語之觀測者」）。
請將以下Python錯誤轉換成：
1. 溫和語氣
2. 不直接說錯誤名稱
3. 像在提示玩家，而不是報錯
4. 保持神秘感與遊戲風格

玩家程式：
%s

錯誤：
%s
""" % [code, error]
	call_openai(prompt)

func call_openai(prompt: String):
	# 你的新版 AQ 金鑰
	var raw_key = "AQ.Ab8RN6Kae6Gj794kw_Z9UhIO2lPGPkDs5FG-8uCKIZ19ItcxnQ"
	var api_key = raw_key.strip_edges()
	
	# 【2026 終極修正】：根據新版 API 規範，全面換用最新世代的 gemini-2.5-flash
	var url = "https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent?key=" + api_key

	var headers = PackedStringArray([
		"Content-Type: application/json"
	])

	# 標準的內容傳輸結構
	var body = {
		"contents": [
			{
				"parts": [
					{"text": prompt}
				]
			}
		]
	}

	var error = http.request(
		url,
		headers,
		HTTPClient.METHOD_POST,
		JSON.stringify(body)
	)
	
	if error != OK:
		emit_signal("ai_response_received", "發送請求時發生錯誤")

func _on_http_request_request_completed(_result, response_code, _headers, body):
	var json_text = body.get_string_from_utf8()
	var json = JSON.parse_string(json_text)
	
	# 調試用
	print("API 回傳代碼: ", response_code)
	print("API 回傳內容: ", json)
	
	if response_code != 200:
		emit_signal("ai_response_received", "AI連線失敗，代碼：" + str(response_code))
		return

	# 解析 Gemini 回傳的 JSON 安全機制（防範無資料回傳）
	if json and json.has("candidates") and json["candidates"].size() > 0:
		var candidate = json["candidates"][0]
		if candidate.has("content") and candidate["content"].has("parts"):
			var text = candidate["content"]["parts"][0]["text"]
			emit_signal("ai_response_received", text)
			return
			
	emit_signal("ai_response_received", "AI 思考了很久，但沒有說話...")