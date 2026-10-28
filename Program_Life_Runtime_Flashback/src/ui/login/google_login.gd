
extends Control

@onready var google_login_button: Button = $GoogleLoginButton
@onready var google_auth: Node = $GoogleAuth
@onready var auth_verify_request: HTTPRequest = $AuthVerifyRequest

const BACKEND_URL = "https://oj3wxp63b5ttx6sfklndqcrccq0nnxwq.lambda-url.ap-southeast-2.on.aws"
const PROLOGUE_SCENE := "res://chapters/prologue/prologue.tscn"

var _entering_game := false

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
	if _entering_game:
		return

	if result != HTTPRequest.RESULT_SUCCESS:
		print("無法連接 AWS FastAPI 後端")
		return

	if response_code == 403:
		print("AWS 拒絕存取：請檢查 Lambda Function URL 權限")
		return

	if response_code == 401:
		print("Google ID Token 無效或已過期")
		return

	if response_code != 200:
		print("後端驗證失敗，HTTP 狀態碼：", response_code)
		return

	var data = JSON.parse_string(body.get_string_from_utf8())

	if not data is Dictionary:
		print("後端回傳格式錯誤")
		return

	if not data.get("success", false):
		print("後端未確認登入成功")
		return

	var player: Dictionary = data.get("player", {})

	if str(player.get("id", "")).is_empty():
		print("後端未提供有效的玩家 ID")
		return

	PlayerSession.set_verified_player(
		str(player.get("id", "")),
		str(player.get("name", "")),
		str(player.get("email", "")),
		str(player.get("avatar_url", ""))
	)

	print("登入成功！歡迎 " + PlayerSession.player_name)
	_entering_game = true
	google_login_button.disabled = true
	# 等 HTTP 回呼結束後再切換，避免在信號處理期間移除登入場景。
	_enter_game.call_deferred()


func _enter_game() -> void:
	var error := get_tree().change_scene_to_file(PROLOGUE_SCENE)
	if error != OK:
		_entering_game = false
		google_login_button.disabled = false
		push_error("無法進入遊戲前言：" + error_string(error))
