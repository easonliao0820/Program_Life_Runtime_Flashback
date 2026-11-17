
extends Control

## 登入畫面協調器：啟動 OAuth → AWS 驗證 → 保存玩家身分 → 交給 GameFlow。
## GoogleAuth 處理 Google 授權，AuthManager 管憑證，這裡不直接讀寫資料庫。
@onready var google_login_button: Button = $GoogleLoginButton
@onready var google_auth: Node = $GoogleAuth
@onready var auth_verify_request: HTTPRequest = $AuthVerifyRequest
@onready var auth_me_request: HTTPRequest = $AuthMeRequest
@onready var auth_manager: Node = get_node("/root/AuthManager")

const BACKEND_URL = "https://oj3wxp63b5ttx6sfklndqcrccq0nnxwq.lambda-url.ap-southeast-2.on.aws"

var _entering_game := false
var _pending_player: Dictionary = {}

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
	auth_me_request.request_completed.connect(
		_on_auth_me_completed
	)



func _on_google_login_pressed() -> void:
	if _entering_game:
		return

	# 已登入但雲端下載失敗時，允許直接重試，
	# 不需要重新執行 Google OAuth。
	if PlayerSession.is_logged_in:
		_entering_game = true
		google_login_button.disabled = true
		_enter_game.call_deferred()
		return

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

	
	var player_data = data.get("player", {})

	if not player_data is Dictionary:
		auth_manager.clear_token()
		print("後端玩家資料格式錯誤")
		return

	var player: Dictionary = player_data

	if str(player.get("id", "")).is_empty():
		auth_manager.clear_token()
		print("後端未提供有效的玩家 ID")
		return

	
	var access_token := str(data.get("access_token", ""))
	var expires_in := int(data.get("expires_in", 0))

	var refresh_token := str(data.get("refresh_token", ""))
	var refresh_expires_in := int(data.get("refresh_expires_in", 0))

	if access_token.is_empty() or expires_in <= 0:
		auth_manager.clear_token()
		print("後端未提供有效的 Access Token")
		return

	if refresh_token.is_empty() or refresh_expires_in <= 0:
		auth_manager.clear_token()
		print("後端未提供有效的 Refresh Token")
		return


	# 暫存玩家資料，尚未建立正式登入狀態。
	_pending_player = player.duplicate()

	# 由 AuthManager 統一管理後端 JWT。
	auth_manager.set_backend_access_token(
		access_token,
		expires_in
	)
	
	auth_manager.set_backend_refresh_token(
		refresh_token,
		refresh_expires_in
	)

	var headers: PackedStringArray = (
		auth_manager.get_backend_auth_headers()
	)

	if headers.is_empty():
		auth_manager.clear_token()
		_pending_player.clear()
		print("無法取得有效的 JWT Authorization Header")
		return

	print("Google 登入成功，準備驗證後端 JWT...")

	google_login_button.disabled = true

	var error := auth_me_request.request(
		BACKEND_URL + "/auth/me",
		headers,
		HTTPClient.METHOD_GET
	)

	if error != OK:
		google_login_button.disabled = false
		auth_manager.clear_token()
		_pending_player.clear()
		print("無法送出 JWT 驗證請求")


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

	if not data is Dictionary:
		_handle_auth_me_failure("/auth/me 回傳格式錯誤")
		return

	var player_data = data.get("player", {})

	if not player_data is Dictionary:
		_handle_auth_me_failure("/auth/me 玩家資料格式錯誤")
		return

	var player: Dictionary = player_data
	var returned_player_id := str(player.get("id", ""))
	var expected_player_id := str(_pending_player.get("id", ""))

	if not data.get("success", false) \
	or returned_player_id.is_empty() \
	or returned_player_id != expected_player_id:
		_handle_auth_me_failure("/auth/me 玩家身分不一致")
		return

	# JWT 驗證成功後，才正式設定玩家登入狀態。
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

	_entering_game = true
	google_login_button.disabled = true
	_enter_game.call_deferred()

func _handle_auth_me_failure(message: String) -> void:
	_pending_player.clear()
	auth_manager.clear_token()
	PlayerSession.logout()
	google_login_button.disabled = false
	print(message)


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
	if (
		not PlayerSession.is_logged_in
		or PlayerSession.player_id != player_id
	):
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
	# 現在 GameState.save_path 已經是此玩家專屬檔案。
	var error := GameFlow.start_after_login(
		PlayerSession.player_name
	)

	if error != OK:
		_cloud_login_failed(
			"無法進入遊戲：" + error_string(error)
		)


func _cloud_login_failed(message: String) -> void:
	push_warning("[CloudSave] " + message)

	_entering_game = false
	google_login_button.disabled = false

	print("[CloudSave] 請再次按登入按鈕重試")
