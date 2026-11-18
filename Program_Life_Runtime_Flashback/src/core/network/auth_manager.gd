
extends Node

## 集中管理登入憑證。
## Token 僅保存在記憶體，不寫入本機檔案。
## Access Token 用於受保護 API。
## Refresh Token 用於自動更新 Access Token。
## AiBridge 預設匿名，不依賴登入狀態。

signal backend_token_refreshed
signal backend_token_refresh_failed
signal backend_session_expired

const BACKEND_URL := "https://oj3wxp63b5ttx6sfklndqcrccq0nnxwq.lambda-url.ap-southeast-2.on.aws"

# Access Token 剩餘 60 秒時開始更新。
const REFRESH_BEFORE_SECONDS := 60.0

# 更新失敗後等待 30 秒再重試。
const REFRESH_RETRY_SECONDS := 30.0

# 每秒檢查一次。
const CHECK_INTERVAL_SECONDS := 1.0

# 保留原本提前 30 秒視為過期的設計。
const TOKEN_EXPIRY_BUFFER_SECONDS := 30.0

var _google_id_token := ""
var _google_expires_at: float = 0.0

var _backend_access_token := ""
var _backend_expires_at: float = 0.0

var _backend_refresh_token := ""
var _backend_refresh_expires_at: float = 0.0

var _refresh_request: HTTPRequest
var _refresh_in_progress := false
var _next_refresh_attempt_at: float = 0.0
var _check_elapsed := 0.0

# 用於防止登出後，舊請求回寫 Token。
var _auth_generation := 0
var _request_generation := -1


func _ready() -> void:
	_refresh_request = HTTPRequest.new()
	_refresh_request.timeout = 15.0
	add_child(_refresh_request)

	_refresh_request.request_completed.connect(
		_on_refresh_request_completed
	)


func _process(delta: float) -> void:
	_check_elapsed += delta

	if _check_elapsed < CHECK_INTERVAL_SECONDS:
		return

	_check_elapsed = 0.0

	if _refresh_in_progress:
		return

	if _backend_access_token.is_empty():
		return

	if get_backend_refresh_token().is_empty():
		return

	var now := Time.get_unix_time_from_system()

	if now < _next_refresh_attempt_at:
		return

	# _backend_expires_at 已提前扣除 30 秒，
	# 所以距離此時間剩餘 30 秒時，
	# 等同於實際 Token 剩餘約 60 秒。
	if now >= _backend_expires_at - (
		REFRESH_BEFORE_SECONDS - TOKEN_EXPIRY_BUFFER_SECONDS
	):
		_start_refresh()


func set_google_token(token_data: Dictionary) -> void:
	_google_id_token = str(token_data.get("id_token", ""))

	_google_expires_at = (
		Time.get_unix_time_from_system()
		+ maxf(0.0, float(token_data.get("expires_in", 0)))
	)


func get_google_id_token() -> String:
	if Time.get_unix_time_from_system() >= _google_expires_at:
		_google_id_token = ""
		_google_expires_at = 0.0
		return ""

	return _google_id_token


func set_backend_access_token(
	token: String,
	expires_in: int
) -> void:
	_backend_access_token = token

	_backend_expires_at = (
		Time.get_unix_time_from_system()
		+ maxi(0, expires_in - int(TOKEN_EXPIRY_BUFFER_SECONDS))
	)


func get_backend_access_token() -> String:
	if Time.get_unix_time_from_system() >= _backend_expires_at:
		clear_backend_access_token()
		return ""

	return _backend_access_token


func get_backend_auth_headers() -> PackedStringArray:
	var token := get_backend_access_token()

	if token.is_empty():
		return PackedStringArray()

	return PackedStringArray([
		"Authorization: Bearer " + token
	])


func clear_backend_access_token() -> void:
	_backend_access_token = ""
	_backend_expires_at = 0.0


func set_backend_refresh_token(
	token: String,
	expires_in: int
) -> void:
	_backend_refresh_token = token

	_backend_refresh_expires_at = (
		Time.get_unix_time_from_system()
		+ maxi(0, expires_in - int(TOKEN_EXPIRY_BUFFER_SECONDS))
	)


func get_backend_refresh_token() -> String:
	if Time.get_unix_time_from_system() >= _backend_refresh_expires_at:
		clear_backend_refresh_token()
		return ""

	return _backend_refresh_token


func clear_backend_refresh_token() -> void:
	_backend_refresh_token = ""
	_backend_refresh_expires_at = 0.0


func _start_refresh() -> void:
	if _refresh_in_progress:
		return

	var refresh_token := get_backend_refresh_token()

	if refresh_token.is_empty():
		return

	_refresh_in_progress = true
	_request_generation = _auth_generation

	var headers := PackedStringArray([
		"Content-Type: application/json"
	])

	var body := JSON.stringify({
		"refresh_token": refresh_token
	})

	print("[AuthManager] 正在自動更新 Access Token...")

	var error := _refresh_request.request(
		BACKEND_URL + "/auth/refresh",
		headers,
		HTTPClient.METHOD_POST,
		body
	)

	if error != OK:
		_refresh_in_progress = false
		_next_refresh_attempt_at = (
			Time.get_unix_time_from_system()
			+ REFRESH_RETRY_SECONDS
		)

		print("[AuthManager] 無法送出更新請求：", error)
		backend_token_refresh_failed.emit()


func _on_refresh_request_completed(
	result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray
) -> void:
	_refresh_in_progress = false

	# 登出或切換登入身分後，忽略舊請求。
	if _request_generation != _auth_generation:
		return

	if result != HTTPRequest.RESULT_SUCCESS:
		_schedule_refresh_retry()
		print("[AuthManager] Token 更新連線失敗")
		backend_token_refresh_failed.emit()
		return

	
	if response_code == 401:
		print("[AuthManager] Refresh Token 已失效，需要重新登入")

		# 清除失效的後端憑證，停止自動更新。
		clear_backend_tokens()

		# 通知 PlayerSession：後端登入狀態已失效。
		backend_session_expired.emit()

		backend_token_refresh_failed.emit()
		return

	if response_code != 200:
		_schedule_refresh_retry()
		print("[AuthManager] Token 更新失敗，HTTP：", response_code)
		backend_token_refresh_failed.emit()
		return


	var data = JSON.parse_string(body.get_string_from_utf8())

	if not data is Dictionary:
		_schedule_refresh_retry()
		print("[AuthManager] Token 更新回應格式錯誤")
		backend_token_refresh_failed.emit()
		return

	var access_token := str(data.get("access_token", ""))
	var refresh_token := str(data.get("refresh_token", ""))
	var expires_in := int(data.get("expires_in", 0))
	var refresh_expires_in := int(data.get("refresh_expires_in", 0))

	if access_token.is_empty() \
	or refresh_token.is_empty() \
	or expires_in <= 0 \
	or refresh_expires_in <= 0:
		_schedule_refresh_retry()
		print("[AuthManager] Token 更新資料不完整")
		backend_token_refresh_failed.emit()
		return

	set_backend_access_token(access_token, expires_in)
	set_backend_refresh_token(refresh_token, refresh_expires_in)

	_next_refresh_attempt_at = 0.0

	print("[AuthManager] Access Token 自動更新成功")
	backend_token_refreshed.emit()


func _schedule_refresh_retry() -> void:
	_next_refresh_attempt_at = (
		Time.get_unix_time_from_system()
		+ REFRESH_RETRY_SECONDS
	)


func clear_backend_tokens() -> void:
	# 使正在進行的 Refresh 請求失效。
	_auth_generation += 1

	if _refresh_request != null:
		_refresh_request.cancel_request()

	_refresh_in_progress = false
	_next_refresh_attempt_at = 0.0

	clear_backend_access_token()
	clear_backend_refresh_token()


func clear_token() -> void:
	_google_id_token = ""
	_google_expires_at = 0.0

	clear_backend_tokens()
