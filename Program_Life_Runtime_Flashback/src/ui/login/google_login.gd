
extends Control

@onready var google_login_button: Button = $GoogleLoginButton
@onready var google_auth: Node = $GoogleAuth
@onready var auth_verify_request: HTTPRequest = $AuthVerifyRequest

const BACKEND_URL = "http://127.0.0.1:8000"

func _ready() -> void:
	google_login_button.pressed.connect(
		_on_google_login_pressed
	)

	google_auth.login_status_changed.connect(
		_on_login_status_changed
	)

	google_auth.authorization_received.connect(
		_on_authorization_received
	)

	google_auth.login_failed.connect(
		_on_login_failed
	)
	
	google_auth.token_received.connect(
		_on_token_received
	)
	
	auth_verify_request.request_completed.connect(
		_on_auth_verify_completed
	)


func _on_google_login_pressed() -> void:
	google_auth.start_google_login()


func _on_login_status_changed(message: String) -> void:
	print(message)


func _on_authorization_received(code: String) -> void:
	print("Google 授權成功，準備交換 Token")

	# 不要把 Authorization Code 印到 Output。
	# 下一步會在這裡進行 Token 交換。


func _on_login_failed(message: String) -> void:
	print("登入失敗：" + message) 
	

func _on_token_received(data: Dictionary) -> void:
	var google_id_token := str(data.get("id_token", ""))

	if google_id_token.is_empty():
		print("未取得 Google ID Token")
		return

	print("正在驗證 Google 身分...")

	var headers := PackedStringArray([
        "Content-Type: application/json"
	])

	var body := JSON.stringify({
		"id_token": google_id_token
	})

	var error := auth_verify_request.request(
		BACKEND_URL + "/auth/google",
		headers,
		HTTPClient.METHOD_POST,
		body
	)

	if error != OK:
		print("無法送出身分驗證請求")

func _on_auth_verify_completed(
	result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray
) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		print("無法連接 FastAPI 後端")
		return

	var data = JSON.parse_string(body.get_string_from_utf8())

	if not data is Dictionary:
		print("後端回傳格式錯誤")
		return

	if response_code != 200:
		print("Google 身分驗證失敗")
		print("HTTP 狀態碼：", response_code)
		return

	var player: Dictionary = data.get("player", {})

	if player.is_empty():
		print("找不到玩家資料") 
		return

	PlayerSession.set_verified_player(
		str(player.get("id", "")),
		str(player.get("name", "")),
		str(player.get("email", "")),
		str(player.get("avatar_url", ""))
	)
	print("登入成功！歡迎 "+ PlayerSession.player_name)
