
extends Control

## 登入畫面協調器：啟動 OAuth → AWS 驗證 → 保存玩家身分 → 交給 GameFlow。
## GoogleAuth 處理 Google 授權，AuthManager 管憑證，這裡不直接讀寫資料庫。
@onready var google_login_button: Button = $GoogleLoginButton
@onready var google_auth: Node = $GoogleAuth
@onready var auth_verify_request: HTTPRequest = $AuthVerifyRequest
@onready var auth_manager: Node = get_node("/root/AuthManager")

const BACKEND_URL = "https://oj3wxp63b5ttx6sfklndqcrccq0nnxwq.lambda-url.ap-southeast-2.on.aws"

var _entering_game := false

func _ready() -> void:
	# UI、Google 授權與後端驗證各用自己的 signal，避免把取 Token 當登入完成。
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
	# GoogleAuth 會接著交換 Token；此回呼只顯示狀態，不重複送請求。


func _on_login_failed(message: String) -> void:
	auth_manager.clear_token()
	print("登入失敗：" + message) 
	

func _on_token_received(data: Dictionary) -> void:
	# 只把 ID Token 送後端驗證，不將 access_token 或完整 Token 寫入日誌。
	var google_id_token := str(data.get("id_token", ""))

	if google_id_token.is_empty():
		print("未取得 Google ID Token")
		return

	# 先暫存以跨場景保留；若後續驗證失敗，下方各錯誤分支都會清除。
	auth_manager.set_google_token(data)
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
		auth_manager.clear_token()
		print("無法送出身分驗證請求")


func _on_auth_verify_completed(
	result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray
) -> void:
	# 已在切換場景時略過重複完成事件，避免同時進入兩個畫面。
	if _entering_game:
		return

	# result 是傳輸結果；response_code 才是 HTTP 狀態，兩者都要檢查。
	if result != HTTPRequest.RESULT_SUCCESS:
		auth_manager.clear_token()
		print("無法連接 AWS FastAPI 後端")
		return

	if response_code == 403:
		auth_manager.clear_token()
		print("AWS 拒絕存取：請檢查 Lambda Function URL 權限")
		return

	if response_code == 401:
		auth_manager.clear_token()
		print("Google ID Token 無效或已過期")
		return

	if response_code != 200:
		auth_manager.clear_token()
		print("後端驗證失敗，HTTP 狀態碼：", response_code)
		return

	var data = JSON.parse_string(body.get_string_from_utf8())

	if not data is Dictionary:
		auth_manager.clear_token()
		print("後端回傳格式錯誤")
		return

	if not data.get("success", false):
		auth_manager.clear_token()
		print("後端未確認登入成功")
		return

	var player: Dictionary = data.get("player", {})

	if str(player.get("id", "")).is_empty():
		auth_manager.clear_token()
		print("後端未提供有效的玩家 ID")
		return

	# 只有後端確認成功並提供有效玩家 ID 後，才更新已登入狀態。
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
	# 統一由 GameFlow 決定：有本機進度直接繼續，否則開章節選擇。
	# 未來 DynamoDB 的載入接點在 GameFlow，不必改 OAuth 驗證流程。
	var error := GameFlow.start_after_login(PlayerSession.player_name)
	if error != OK:
		_entering_game = false
		google_login_button.disabled = false
		push_error("無法進入遊戲：" + error_string(error))
