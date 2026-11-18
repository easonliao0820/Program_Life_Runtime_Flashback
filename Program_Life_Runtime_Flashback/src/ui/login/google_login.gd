extends Control

## 登入畫面協調器：Google OAuth → AWS Google 身分驗證 → 遊戲 JWT → /auth/me → 雲端讀檔。
## 支援朋友新增的 Desktop OAuth Lambda 換碼，以及原本的 Google Token 直接回傳流程。
@onready var google_login_button: Button = $GoogleLoginButton
@onready var google_auth: Node = $GoogleAuth
@onready var auth_verify_request: HTTPRequest = $AuthVerifyRequest
@onready var auth_me_request: HTTPRequest = $AuthMeRequest
@onready var auth_manager: Node = get_node("/root/AuthManager")

const BACKEND_URL = "https://oj3wxp63b5ttx6sfklndqcrccq0nnxwq.lambda-url.ap-southeast-2.on.aws"

var _entering_game := false
var _login_busy := false
var _pending_player: Dictionary = {}


func _ready() -> void:
	# 朋友新版 GoogleAuth 新增的 AWS Desktop 換碼成功事件。
	# 有這個 signal 才連接，避免使用舊版 GoogleAuth 時發生錯誤。
	if google_auth.has_signal("backend_login_verified"):
		google_auth.backend_login_verified.connect(_on_backend_login_verified)

	google_login_button.pressed.connect(_on_google_login_pressed)
	google_auth.login_status_changed.connect(_on_login_status_changed)
	google_auth.authorization_received.connect(_on_authorization_received)
	google_auth.login_failed.connect(_on_login_failed)
	google_auth.token_received.connect(_on_token_received)
	auth_verify_request.request_completed.connect(_on_auth_verify_completed)
	auth_me_request.request_completed.connect(_on_auth_me_completed)


func _on_google_login_pressed() -> void:
	if _login_busy or _entering_game:
		return

	# 已登入但雲端下載失敗時可直接重試，不重新走 Google OAuth。
	if PlayerSession.is_logged_in:
		_entering_game = true
		google_login_button.disabled = true
		_enter_game.call_deferred()
		return

	_login_busy = true
	google_login_button.disabled = true
	google_auth.start_google_login()


func _on_login_status_changed(message: String) -> void:
	print(message)


func _on_authorization_received(_code: String) -> void:
	# 不把 Authorization Code 印到 Output。
	print("Google 授權成功，準備交換 Token")


func _on_login_failed(message: String) -> void:
	_pending_player.clear()
	auth_manager.clear_token()
	PlayerSession.logout()
	_login_busy = false
	_entering_game = false
	google_login_button.disabled = false
	print("登入失敗：" + message)


## 朋友 Desktop Lambda 已成功驗證 Google Token。
## 注意：仍必須走我們的 /auth/google 取得遊戲 JWT，不能只設定 PlayerSession。
func _on_backend_login_verified(data: Dictionary) -> void:
	if _entering_game or not _login_busy:
		return

	var player = data.get("player", {})
	var expires = data.get("expires_in", 0)

	if (
		data.get("success", false) != true
		or not (player is Dictionary)
		or str(player.get("id", "")).is_empty()
		or str(data.get("id_token", "")).is_empty()
		or not (expires is int or expires is float)
		or float(expires) <= 0.0
	):
		_on_login_failed("AWS Google 登入回覆不完整")
		return

	# 沿用已測試的後端 JWT 驗證流程。
	_on_token_received(data)


## GoogleAuth 直接從 Google 取得 Token，或朋友的 Lambda 換碼回傳 Token。
func _on_token_received(data: Dictionary) -> void:
	if _entering_game:
		return

	var google_id_token := str(data.get("id_token", ""))
	if google_id_token.is_empty():
		_on_login_failed("未取得 Google ID Token")
		return

	# 暫存 Google ID Token；真正的遊戲登入依賴 AWS JWT。
	auth_manager.set_google_token(data)
	print("正在驗證 Google 身分...")

	var headers := PackedStringArray([
		"Content-Type: application/json"
	])
	var body := JSON.stringify({"id_token": google_id_token})

	var error := auth_verify_request.request(
		BACKEND_URL + "/auth/google",
		headers,
		HTTPClient.METHOD_POST,
		body
	)

	if error != OK:
		_on_login_failed("無法送出身分驗證請求")


func _on_auth_verify_completed(
	result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray
) -> void:
	if _entering_game:
		return

	if result != HTTPRequest.RESULT_SUCCESS:
		_on_login_failed("無法連接 AWS FastAPI 後端")
		return
	if response_code == 403:
		_on_login_failed("AWS 拒絕存取：請檢查 Lambda Function URL 權限")
		return
	if response_code == 401:
		_on_login_failed("Google ID Token 無效或已過期")
		return
	if response_code != 200:
		_on_login_failed("後端驗證失敗，HTTP 狀態碼：%d" % response_code)
		return

	var data = JSON.parse_string(body.get_string_from_utf8())
	if not (data is Dictionary):
		_on_login_failed("後端回傳格式錯誤")
		return
	if not data.get("success", false):
		_on_login_failed("後端未確認登入成功")
		return

	var player_data = data.get("player", {})
	if not (player_data is Dictionary):
		_on_login_failed("後端玩家資料格式錯誤")
		return

	var player: Dictionary = player_data
	if str(player.get("id", "")).is_empty():
		_on_login_failed("後端未提供有效的玩家 ID")
		return

	var access_token := str(data.get("access_token", ""))
	var expires_in := int(data.get("expires_in", 0))
	var refresh_token := str(data.get("refresh_token", ""))
	var refresh_expires_in := int(data.get("refresh_expires_in", 0))

	if access_token.is_empty() or expires_in <= 0:
		_on_login_failed("後端未提供有效的 Access Token")
		return
	if refresh_token.is_empty() or refresh_expires_in <= 0:
		_on_login_failed("後端未提供有效的 Refresh Token")
		return

	# 暫存玩家資料，尚未建立正式登入狀態。
	_pending_player = player.duplicate()

	# 由 AuthManager 統一管理後端 JWT。
	auth_manager.set_backend_access_token(access_token, expires_in)
	auth_manager.set_backend_refresh_token(refresh_token, refresh_expires_in)

	var headers: PackedStringArray = auth_manager.get_backend_auth_headers()
	if headers.is_empty():
		_on_login_failed("無法取得有效的 JWT Authorization Header")
		return

	print("Google 登入成功，準備驗證後端 JWT...")
	var error := auth_me_request.request(
		BACKEND_URL + "/auth/me",
		headers,
		HTTPClient.METHOD_GET
	)

	if error != OK:
		_on_login_failed("無法送出 JWT 驗證請求")


func _on_auth_me_completed(
	result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray
) -> void:
	if _entering_game:
		return

	print("AuthMeRequest 傳輸結果：", result)
	print("AuthMeRequest HTTP 狀態碼：", response_code)

	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		_handle_auth_me_failure("JWT 驗證失敗")
		return

	var data = JSON.parse_string(body.get_string_from_utf8())
	if not (data is Dictionary):
		_handle_auth_me_failure("/auth/me 回傳格式錯誤")
		return

	var player_data = data.get("player", {})
	if not (player_data is Dictionary):
		_handle_auth_me_failure("/auth/me 玩家資料格式錯誤")
		return

	var player: Dictionary = player_data
	var returned_player_id := str(player.get("id", ""))
	var expected_player_id := str(_pending_player.get("id", ""))

	if (
		data.get("success", false) != true
		or returned_player_id.is_empty()
		or returned_player_id != expected_player_id
	):
		_handle_auth_me_failure("/auth/me 玩家身分不一致")
		return

	# JWT 驗證成功後才正式設定玩家登入狀態。
	PlayerSession.set_verified_player(
		returned_player_id,
		str(player.get("name", "")),
		str(player.get("email", "")),
		str(player.get("avatar_url", ""))
	)
	ErrorLogManager.activate_player(returned_player_id)
	_pending_player.clear()

	print("JWT 驗證成功，玩家 ID 一致")
	print("登入成功！歡迎 " + PlayerSession.player_name)

	_login_busy = false
	_entering_game = true
	google_login_button.disabled = true
	_enter_game.call_deferred()


func _handle_auth_me_failure(message: String) -> void:
	_on_login_failed(message)


## 原有精簡雲端讀檔流程：不要用朋友的純 GameFlow 版本覆蓋。
func _enter_game() -> void:
	if not PlayerSession.is_logged_in:
		_cloud_login_failed("玩家尚未登入")
		return

	var player_id := PlayerSession.player_id

	# 一、切換到此 Google 帳號的本機存檔。
	if not GameState.select_player_save(player_id):
		_cloud_login_failed("無法設定玩家專屬存檔")
		return

	# 二、下載 AWS 雲端進度。
	print("[CloudSave] 正在查詢 AWS 雲端存檔...")
	var response: Dictionary = await CloudSaveManager.download_save()

	if not is_inside_tree():
		return

	# 避免網路等待期間玩家已被登出或切換身分。
	if not PlayerSession.is_logged_in or PlayerSession.player_id != player_id:
		_cloud_login_failed("登入狀態已變更")
		return

	if not response.get("ok", false):
		_cloud_login_failed(
			"雲端查詢失敗：" + str(response.get("message", "未知錯誤"))
		)
		return

	var cloud_data: Dictionary = response.get("data", {})

	# 三、有雲端存檔時，先備份並更新本機資料。
	if cloud_data.get("has_save", false):
		print("[CloudSave] 找到雲端進度")

		var save_data = cloud_data.get("save")
		if not (save_data is Dictionary):
			_cloud_login_failed("雲端存檔格式錯誤")
			return

		if not GameState.import_cloud_save(save_data):
			_cloud_login_failed("無法匯入雲端存檔")
			return

		print("[CloudSave] 雲端進度下載成功")
	else:
		print("[CloudSave] 雲端尚無存檔")

		if GameState.has_save():
			print("[CloudSave] 使用此帳號原有的本機進度")
		else:
			print("[CloudSave] 首次遊玩，準備建立新進度")

	# 四、沿用原本 GameFlow 的遊戲入口。
	var error := GameFlow.start_after_login(PlayerSession.player_name)
	if error != OK:
		_cloud_login_failed("無法進入遊戲：" + error_string(error))


func _cloud_login_failed(message: String) -> void:
	push_warning("[CloudSave] " + message)
	_entering_game = false
	_login_busy = false
	google_login_button.disabled = false
	print("[CloudSave] 請再次按登入按鈕重試")
