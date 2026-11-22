extends Node

## 全部 AI 請求只送 AWS；Godot 不讀取 Gemini Key，也不強制 Google 登入。
## 舊場景用 signal，新主線用 await ask()；兩種介面共用同一個 HTTP 合約。
signal ai_response_received(text)

const MAX_PROMPT_CHARS := 4000
const MAX_IN_FLIGHT := 2
var api_url: String = "https://oj3wxp63b5ttx6sfklndqcrccq0nnxwq.lambda-url.ap-southeast-2.on.aws/ai/generate"
var game_reply_url: String = "https://oj3wxp63b5ttx6sfklndqcrccq0nnxwq.lambda-url.ap-southeast-2.on.aws/ai/game-reply"
var _active_prompts: Dictionary = {}
var _legacy_busy := false


func translate_error(error: String, code: String) -> void:
	var message := (
		"我執行 Python 程式時遇到了錯誤，"
		+ "請依照你的教學風格引導我找出問題，"
		+ "先提示，不要直接給完整答案。\n\n"
		+ "【程式碼】\n"
		+ code
		+ "\n\n【錯誤訊息】\n"
		+ error
	)

	# 舊介面仍透過 signal 回傳結果。
	if _legacy_busy:
		return

	_legacy_busy = true

	var answer := await ask_character(
		message.left(1000),
		"payson",
		"派森暫時沒能接收到訊號，請稍後再試。",
		"",
		"",
		12.0
	)

	_legacy_busy = false
	ai_response_received.emit(answer)


func call_openai(prompt: String):
	# 名稱為舊介面保留，實際走 AWS/Gemini；全域 signal 沒有 request ID。
	# 因此只接受一個舊式在途請求；忙碌時略過，不另外發回覆。
	if _legacy_busy:
		return
	_legacy_busy = true
	var answer := await ask(prompt, "派森暫時沒能接收到訊號，請稍後再試。", 12.0)
	_legacy_busy = false
	ai_response_received.emit(answer)


func ask(prompt: String, fallback: String, timeout_sec: float = 10.0) -> String:
	# AI 停用、請求失敗或無法生成時，都回備用台詞，讓劇情可以繼續。
	var game_state = get_node_or_null("/root/GameState")
	if game_state and not game_state.settings.get("ai_enabled", true):
		return fallback
	if api_url.is_empty() or prompt.strip_edges().is_empty() or prompt.length() > MAX_PROMPT_CHARS:
		return fallback
	# 同 prompt 只阻止「在途重複」，不是快取、每日配額或玩家次數限制。
	var key := prompt.sha256_text()
	if _active_prompts.has(key) or _active_prompts.size() >= MAX_IN_FLIGHT:
		return fallback
	_active_prompts[key] = true
	# 每次 ask 使用獨立 HTTPRequest，避免多個 await 等待同一條回覆 signal。
	var req := HTTPRequest.new()
	req.timeout = clampf(timeout_sec, 0.1, 12.0)
	req.body_size_limit = 65536
	add_child(req)
	# 只送 prompt，不附 Google Token；私人存檔 API 的驗證應另外實作。
	var err := req.request(api_url, PackedStringArray(["Content-Type: application/json"]),
    	HTTPClient.METHOD_POST, JSON.stringify({"prompt": prompt}))
	if err != OK:
		print("AI 請求無法啟動，錯誤碼：", err)
		_active_prompts.erase(key)
		req.queue_free()
		return fallback
	# 完成後釋放在途記錄與節點；不自動重試，避免重複成本與無限重送。
	var res: Array = await req.request_completed
	_active_prompts.erase(key)
	req.queue_free()
	if res[0] != HTTPRequest.RESULT_SUCCESS or res[1] != 200:
		print("AI HTTP 請求失敗")
		print("Godot 請求結果：", res[0])
		print("HTTP 狀態碼：", res[1])
		print("後端錯誤內容：", (res[3] as PackedByteArray).get_string_from_utf8())
		return fallback
	# 後端合約是 {"text": "..."}，不再解析 Gemini 原始 candidates 格式。
	var data = JSON.parse_string((res[3] as PackedByteArray).get_string_from_utf8())
	if data is Dictionary and data.get("text") is String:
		var answer: String = data["text"].strip_edges()
		if not answer.is_empty():
			return answer.left(4000)
	print("AI 回應格式錯誤或 text 為空")
	return fallback


func ask_character(
	player_message: String,
	character_id: String,
	fallback: String,
	knowledge_id: String = "",
	story_id: String = "",
	timeout_sec: float = 10.0
) -> String:
	# 依照角色 ID，向 AWS 請求符合角色設定的回答。
	var game_state = get_node_or_null("/root/GameState")

	if game_state and not game_state.settings.get("ai_enabled", true):
		return fallback

	if game_reply_url.is_empty():
		return fallback

	if player_message.strip_edges().is_empty():
		return fallback

	# 與後端 GameAIRequest 的限制保持一致。
	if player_message.length() > 1000:
		return fallback

	if character_id.strip_edges().is_empty() or character_id.length() > 100:
		return fallback

	var payload := {
		"player_message": player_message,
		"character_id": character_id,
		"knowledge_id": knowledge_id if not knowledge_id.is_empty() else null,
		"story_id": story_id if not story_id.is_empty() else null
	}

	# 使用完整請求內容作為在途辨識依據，
	# 避免不同角色問相同問題時被視為同一個請求。
	var request_key := JSON.stringify(payload).sha256_text()

	if _active_prompts.has(request_key):
		return fallback

	if _active_prompts.size() >= MAX_IN_FLIGHT:
		return fallback

	_active_prompts[request_key] = true

	var req := HTTPRequest.new()
	req.timeout = clampf(timeout_sec, 0.1, 12.0)
	req.body_size_limit = 65536
	add_child(req)

	var headers := PackedStringArray([
		"Content-Type: application/json"
	])

	var err := req.request(
		game_reply_url,
		headers,
		HTTPClient.METHOD_POST,
		JSON.stringify(payload)
	)

	if err != OK:
		print("角色 AI 請求無法啟動，錯誤碼：", err)
		_active_prompts.erase(request_key)
		req.queue_free()
		return fallback

	var res: Array = await req.request_completed

	_active_prompts.erase(request_key)
	req.queue_free()

	if res[0] != HTTPRequest.RESULT_SUCCESS or res[1] != 200:
		print("角色 AI HTTP 請求失敗")
		print("Godot 請求結果：", res[0])
		print("HTTP 狀態碼：", res[1])
		return fallback

	var response_text: String = (
		res[3] as PackedByteArray
	).get_string_from_utf8()

	var data = JSON.parse_string(response_text)

	if data is Dictionary and data.get("text") is String:
		var answer: String = data["text"].strip_edges()

		if not answer.is_empty():
			return answer.left(4000)

	print("角色 AI 回應格式錯誤或 text 為空")
	return fallback
