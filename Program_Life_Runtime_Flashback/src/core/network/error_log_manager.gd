
extends Node

const BACKEND_URL := "https://oj3wxp63b5ttx6sfklndqcrccq0nnxwq.lambda-url.ap-southeast-2.on.aws"
const RETRY_INTERVAL_MS := 10000

var _player_id := ""
var _queue_path := ""
var _queue: Array = []

var _http: HTTPRequest
var _sending := false
var _sending_player_id := ""
var _retry_at_ms := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	_http = HTTPRequest.new()
	_http.timeout = 12.0
	_http.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_http)

	_http.request_completed.connect(_on_request_completed)


## 登入後載入該玩家尚未成功上傳的錯誤紀錄。
func activate_player(player_id: String) -> void:
	if player_id.is_empty():
		return

	if _player_id == player_id:
		_try_send.call_deferred()
		return

	if _sending:
		_http.cancel_request()
		_sending = false
		_sending_player_id = ""

	_player_id = player_id
	_queue_path = (
		"user://plrf_errors_"
		+ player_id.sha256_text().substr(0, 24)
		+ ".json"
	)

	_queue.clear()
	_retry_at_ms = 0

	if FileAccess.file_exists(_queue_path):
		var parsed = JSON.parse_string(
			FileAccess.get_file_as_string(_queue_path)
		)

		if parsed is Array:
			_queue = parsed

	_try_send.call_deferred()


## 記錄一次失敗，不等待網路回應。
func record_error(data: Dictionary) -> void:
	if not PlayerSession.is_logged_in:
		return

	activate_player(PlayerSession.player_id)

	var event: Dictionary = data.duplicate(true)

	event["event_id"] = (
		Crypto.new().generate_random_bytes(16).hex_encode()
	)

	event["occurred_at"] = (
		Time.get_datetime_string_from_system(true) + "Z"
	)

	event["section_id"] = str(
		event.get("section_id", "unknown")
	).left(120)

	event["level_id"] = str(
		event.get("level_id", "unknown")
	).left(120)

	event["error_type"] = str(
		event.get("error_type", "UnknownError")
	).left(100)

	event["error_message"] = str(
		event.get("error_message", "")
	).left(1200)

	event["source_line"] = str(
		event.get("source_line", "")
	).left(500)

	event["code"] = str(
		event.get("code", "")
	).left(4000)

	event["backend"] = str(
		event.get("backend", "")
	).left(120)

	event["line"] = maxi(0, int(event.get("line", 0)))
	event["attempt"] = maxi(1, int(event.get("attempt", 1)))

	_queue.append(event)
	_save_queue()

	print("[ErrorLog] 已記錄錯誤，等待 AWS 同步")

	_try_send.call_deferred()


func _save_queue() -> void:
	if _queue_path.is_empty():
		return

	var file := FileAccess.open(
		_queue_path,
		FileAccess.WRITE
	)

	if file == null:
		push_warning("[ErrorLog] 無法保存本機錯誤佇列")
		return

	file.store_string(JSON.stringify(_queue))
	file.close()


func _process(_delta: float) -> void:
	if _sending or _queue.is_empty():
		return

	if Time.get_ticks_msec() < _retry_at_ms:
		return

	_try_send()


func _try_send() -> void:
	if _sending or _queue.is_empty():
		return

	if not PlayerSession.is_logged_in:
		return

	if PlayerSession.player_id != _player_id:
		return

	if Time.get_ticks_msec() < _retry_at_ms:
		return

	var token := AuthManager.get_backend_access_token()

	if token.is_empty():
		return

	var headers := PackedStringArray([
		"Content-Type: application/json",
		"Authorization: Bearer " + token
	])

	var body := JSON.stringify(_queue[0])

	_sending = true
	_sending_player_id = _player_id

	var error := _http.request(
		BACKEND_URL + "/players/me/errors",
		headers,
		HTTPClient.METHOD_POST,
		body
	)

	if error != OK:
		_sending = false
		_sending_player_id = ""
		_retry_at_ms = (
			Time.get_ticks_msec() + RETRY_INTERVAL_MS
		)
		push_warning("[ErrorLog] 無法送出 AWS 請求")


func _on_request_completed(
	result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray
) -> void:
	_sending = false

	if _sending_player_id != _player_id:
		_sending_player_id = ""
		return

	_sending_player_id = ""

	var data = JSON.parse_string(
		body.get_string_from_utf8()
	)

	if (
		result == HTTPRequest.RESULT_SUCCESS
		and response_code == 201
		and data is Dictionary
		and data.get("success", false)
	):
		if not _queue.is_empty():
			_queue.pop_front()
			_save_queue()

		_retry_at_ms = 0
		print("[ErrorLog] AWS 錯誤紀錄上傳成功")

		_try_send.call_deferred()
		return

	_retry_at_ms = (
		Time.get_ticks_msec() + RETRY_INTERVAL_MS
	)

	push_warning(
		"[ErrorLog] AWS 上傳失敗，HTTP：%d，稍後重試"
		% response_code
	)


## 登出前嘗試送完待上傳事件。
## 若逾時，紀錄仍保留本機供下次登入重送。
func flush_pending(max_wait_seconds: float = 6.0) -> bool:
	if _queue.is_empty():
		return true

	var deadline := (
		Time.get_ticks_msec()
		+ int(max_wait_seconds * 1000.0)
	)

	while not _queue.is_empty():
		if Time.get_ticks_msec() >= deadline:
			return false

		_try_send()

		await get_tree().create_timer(
			0.2,
			true
		).timeout

	return true
