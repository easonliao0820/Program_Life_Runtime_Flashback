extends Node


signal ai_response_received(text)

@onready var http = $HTTPRequest
#var http : HTTPRequest

func _ready():
	http = HTTPRequest.new()
	add_child(http)
	
	if http == null:
		push_error("找不到 HTTPRequest 節點")
		return

	http.request_completed.connect(
		_on_http_request_request_completed
	)

func translate_error(error:String, code:String):

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



func call_openai(prompt:String):

	const  API_KEY="AQ.Ab8RN6KA8tnYVwbBTJi7kw_5l23X28pAnkGJ68aIrX3Dk4lFfA"
	
	var url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent?key=" + API_KEY

	var headers = PackedStringArray([
		"Content-Type: application/json"
	])

	var body = {"contents": [{"parts": [{"text": prompt}]}]}

	http.request(
		url,
		headers,
		HTTPClient.METHOD_POST,
		JSON.stringify(body)
	)
	

func _on_http_request_request_completed(
	result,
	response_code,
	headers,
	body
):
	var json_text = body.get_string_from_utf8()
	var json = JSON.parse_string(json_text)

	print(json)
	
	if response_code != 200:
		emit_signal("ai_response_received", "AI連線失敗：" + json_text)
		return


	var text = json["candidates"][0]["content"]["parts"][0]["text"]

	emit_signal("ai_response_received", text)
	
