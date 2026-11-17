
extends Node

## 開發階段專用：測試 AWS Refresh Token Rotation。
## 不輸出 Token、不寫入本機檔案。

const BACKEND_URL = "https://oj3wxp63b5ttx6sfklndqcrccq0nnxwq.lambda-url.ap-southeast-2.on.aws"

var _request: HTTPRequest

var _test_step := 0
var _old_refresh_token := ""
var _new_refresh_token := ""
var _test_running := false


func _ready() -> void:
	_request = HTTPRequest.new()
	add_child(_request)

	_request.request_completed.connect(
		_on_refresh_completed
	)


func run_test() -> void:
	if _test_running:
		print("[RefreshTest] 測試已在執行中")
		return

	_old_refresh_token = AuthManager.get_backend_refresh_token()

	if _old_refresh_token.is_empty():
		print("[RefreshTest] 找不到有效的 Refresh Token")
		return

	_test_running = true
	_test_step = 1

	print("[RefreshTest] 第一階段：使用原本的 Refresh Token")
	_send_refresh_request(_old_refresh_token)


func _send_refresh_request(token: String) -> void:
	var headers := PackedStringArray([
		"Content-Type: application/json"
	])

	var body := JSON.stringify({
		"refresh_token": token
	})

	var error := _request.request(
		BACKEND_URL + "/auth/refresh",
		headers,
		HTTPClient.METHOD_POST,
		body
	)

	if error != OK:
		print("[RefreshTest] 無法送出請求，錯誤碼：", error)
		_finish_test()


func _on_refresh_completed(
	result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray
) -> void:
	print(
		"[RefreshTest] 階段 ",
		_test_step,
		"：HTTP ",
		response_code
	)

	if result != HTTPRequest.RESULT_SUCCESS:
		print("[RefreshTest] 網路傳輸失敗：", result)
		_finish_test()
		return

	if _test_step == 2:
		if response_code == 401:
			print("[RefreshTest] 舊 Token 重複使用已被拒絕")
			_test_step = 3
			_send_refresh_request(_new_refresh_token)
		else:
			print("[RefreshTest] 安全測試失敗：舊 Token 未回傳 401")
			_finish_test()
		return

	if response_code != 200:
		print("[RefreshTest] 更新失敗，HTTP：", response_code)
		_finish_test()
		return

	var data = JSON.parse_string(body.get_string_from_utf8())

	if not data is Dictionary:
		print("[RefreshTest] 後端回傳格式錯誤")
		_finish_test()
		return

	var access_token := str(data.get("access_token", ""))
	var refresh_token := str(data.get("refresh_token", ""))
	var expires_in := int(data.get("expires_in", 0))
	var refresh_expires_in := int(data.get("refresh_expires_in", 0))

	if access_token.is_empty() \
	or refresh_token.is_empty() \
	or expires_in <= 0 \
	or refresh_expires_in <= 0:
		print("[RefreshTest] 後端回傳的 Token 資料不完整")
		_finish_test()
		return

	# 每次成功輪替後，立即更新 AuthManager，
	# 避免測試中斷時仍保留已失效的舊 Token。
	AuthManager.set_backend_access_token(
		access_token,
		expires_in
	)

	AuthManager.set_backend_refresh_token(
		refresh_token,
		refresh_expires_in
	)

	if _test_step == 1:
		_new_refresh_token = refresh_token

		print("[RefreshTest] 第一階段成功：Token 已輪替")

		_test_step = 2
		print("[RefreshTest] 第二階段：重複使用舊 Token")
		_send_refresh_request(_old_refresh_token)

	elif _test_step == 3:
		print("[RefreshTest] 第三階段成功：新 Token 可以繼續輪替")
		print("[RefreshTest] 三階段測試全部通過")
		_finish_test()


func _finish_test() -> void:
	_test_running = false
	_test_step = 0
	_old_refresh_token = ""
	_new_refresh_token = ""
