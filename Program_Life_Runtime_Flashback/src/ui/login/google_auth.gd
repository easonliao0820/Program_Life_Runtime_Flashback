
extends Node

## Google OAuth 桌面流程：瀏覽器授權 → 本機 TCP 回呼 → 授權碼交換 Token。
## 這裡只取得憑證，真正的玩家身分由 google_login.gd 送 AWS 驗證。
## Web 版不能直接使用本機 TCP 監聽，需另接瀏覽器登入流程。
signal login_status_changed(message: String)
signal authorization_received(code: String)
signal login_failed(message: String)
signal token_received(token_data: Dictionary)
signal backend_login_verified(data: Dictionary)

@onready var token_request: HTTPRequest = $TokenRequest

const TOKEN_URL = "https://oauth2.googleapis.com/token"
const CLIENT_ID_SETTING := "oauth/google/client_id"
const EXCHANGE_MODE_SETTING := "oauth/google/exchange_mode"
const EXCHANGE_URL_SETTING := "oauth/google/desktop_exchange_url"

var server := TCPServer.new()
var peer: StreamPeerTCP

var redirect_uri := ""
var oauth_state := ""
var code_verifier := ""
var waiting_for_callback := false
var client_id := ""
var exchanging_token := false
var exchange_mode := "direct"
var exchange_url := ""
var _callback_request := ""
var _authorization_started := 0
var _peer_started := 0

func _ready() -> void:
	set_process(false)
	token_request.timeout = 20.0
	token_request.body_size_limit = 65536
	
	token_request.request_completed.connect(
		_on_token_request_completed
	)
	

func start_google_login() -> void:
	if waiting_for_callback or exchanging_token:
		return

	# Client ID 是公開設定；本次交易固定使用同一個值，不讀取 .env。
	client_id = str(ProjectSettings.get_setting(CLIENT_ID_SETTING, "")).strip_edges()
	if client_id.is_empty():
		login_failed.emit("請在專案設定 oauth/google/client_id 填入 Desktop Client ID")
		return
	exchange_mode = str(ProjectSettings.get_setting(EXCHANGE_MODE_SETTING, "direct"))
	exchange_url = str(ProjectSettings.get_setting(EXCHANGE_URL_SETTING, ""))
	#print("OAuth Exchange Mode: ", exchange_mode)
	#print("OAuth Exchange URL: ", exchange_url)
	
	if not exchange_mode in ["direct", "lambda"]:
		login_failed.emit("Google 登入交換模式設定錯誤")
		return
	if exchange_mode == "lambda" and not exchange_url.begins_with("https://"):
		login_failed.emit("請設定 HTTPS 的 Desktop 交換服務網址")
		return

	var error := server.listen(0, "127.0.0.1")

	if error != OK:
		login_failed.emit("無法啟動本機回呼服務")
		return

	var port := server.get_local_port()
	redirect_uri = "http://127.0.0.1:%d/" % port

	# state 用來比對回呼是否屬於本次登入；PKCE 將授權碼綁定本次 verifier。
	oauth_state = generate_random_token(32)
	code_verifier = generate_random_token(48)

	var challenge := sha256_base64url(code_verifier)

	var params := {
		"client_id": client_id,
		"redirect_uri": redirect_uri,
		"response_type": "code",
		"scope": "openid email profile",
		"state": oauth_state,
		"code_challenge": challenge,
		"code_challenge_method": "S256"
	}

	var parts: PackedStringArray = []

	for key in params:
		parts.append(
			str(key).uri_encode()
			+ "="
			+ str(params[key]).uri_encode()
		)

	var auth_url := (
        "https://accounts.google.com/o/oauth2/v2/auth?"
		+ "&".join(parts)
	)

	waiting_for_callback = true
	_authorization_started = Time.get_ticks_msec()
	set_process(true)

	login_status_changed.emit("正在等待 Google 登入...")

	var open_error := OS.shell_open(auth_url)
	if open_error != OK:
		stop_callback_server()
		login_failed.emit("無法開啟瀏覽器")


func _process(_delta: float) -> void:
	if not waiting_for_callback:
		return
	if Time.get_ticks_msec() - _authorization_started > 180000:
		stop_callback_server()
		code_verifier = ""
		oauth_state = ""
		login_failed.emit("Google 授權等待逾時，請重新登入")
		return

	if peer == null and server.is_connection_available():
		peer = server.take_connection()
		_peer_started = Time.get_ticks_msec()
		_callback_request = ""

	if peer == null:
		return

	peer.poll()
	if Time.get_ticks_msec() - _peer_started > 3000:
		peer = null
		_callback_request = ""
		return

	if peer.get_available_bytes() <= 0:
		return

	if peer.get_available_bytes() + _callback_request.length() > 8192:
		_reject_callback_request()
		return
	_callback_request += peer.get_utf8_string(peer.get_available_bytes())
	# TCP 可能分多批到達，必須收完整 headers 後才解析。
	if not _callback_request.contains("\r\n\r\n"):
		return
	var request := _callback_request

	var first_line := request.split("\r\n")[0]
	var request_parts := first_line.split(" ")

	if request_parts.size() < 2:
		_reject_callback_request()
		return

	var path := request_parts[1]
	if request_parts[0] != "GET" or path.get_slice("?", 0) != "/":
		_reject_callback_request()
		return
	var query := path.get_slice("?", 1)

	var values := parse_query(query)

	if oauth_state.is_empty() or values.get("state", "") != oauth_state:
		# 不處理無效 state，也不讓 favicon／外來請求取消真正等待中的登入。
		_reject_callback_request()
		return

	if values.has("error"):
		send_browser_response("Google 登入已取消")
		stop_callback_server()
		# 不把回呼網址中的任意文字直接轉印到 Console。
		login_failed.emit("Google 授權已取消或遭拒絕")
		code_verifier = ""
		oauth_state = ""
		return

	var code := str(values.get("code", ""))

	if code.is_empty():
		send_browser_response("未收到授權碼")
		stop_callback_server()
		login_failed.emit("未收到 Authorization Code")
		code_verifier = ""
		oauth_state = ""
		return

	send_browser_response("Google 授權完成，可以返回遊戲")
	stop_callback_server()

	authorization_received.emit(code)
	exchange_authorization_code(code)

func parse_query(query: String) -> Dictionary:
	var result := {}

	for item in query.split("&"):
		if item.is_empty():
			continue

		var key := item.get_slice("=", 0).uri_decode()
		if result.has(key):
			return {}  # 拒絕重複欄位，避免不同解析方式選到不同 state/code。
		var value := item.substr(item.find("=") + 1).uri_decode()
		result[key] = value

	return result


func generate_random_token(byte_count: int) -> String:
	var crypto := Crypto.new()
	var random_bytes := crypto.generate_random_bytes(byte_count)

	return Marshalls.raw_to_base64(random_bytes) \
		.replace("+", "-") \
		.replace("/", "_") \
		.replace("=", "")


func sha256_base64url(value: String) -> String:
	var digest := value.sha256_buffer()

	return Marshalls.raw_to_base64(digest) \
		.replace("+", "-") \
		.replace("/", "_") \
		.replace("=", "")


func send_browser_response(message: String) -> void:
	if peer == null:
		return

	var html := (
        "<html><meta charset='utf-8'>"
		+ "<body><h2>"
		+ message
		+ "</h2></body></html>"
	)

	var body := html.to_utf8_buffer()

	var response := (
        "HTTP/1.1 200 OK\r\n"
		+ "Content-Type: text/html; charset=utf-8\r\n"
		+ "Content-Length: %d\r\n"
		+ "Connection: close\r\n\r\n"
	) % body.size()

	peer.put_data(response.to_utf8_buffer())
	peer.put_data(body)


func stop_callback_server() -> void:
	waiting_for_callback = false
	set_process(false)
	server.stop()
	peer = null
	_callback_request = ""


func _reject_callback_request() -> void:
	send_browser_response("這不是本次登入的有效回呼")
	peer = null
	_callback_request = ""


func _exit_tree() -> void:
	# 離開登入場景就停止監聽，避免本機回呼服務殘留。
	stop_callback_server()
	if is_instance_valid(token_request):
		token_request.cancel_request()
	code_verifier = ""
	oauth_state = ""
	

func _token_parameters(code: String) -> Dictionary:
	# Secretless Desktop PKCE：保留原 code、verifier 與同次授權的 redirect URI。
	# Google 若要求其他憑證，明確回報，不自動加入替代參數或略過驗證。
	return {
		"code": code,
		"client_id": client_id,
		"redirect_uri": redirect_uri,
		"grant_type": "authorization_code",
		"code_verifier": code_verifier
	}


func exchange_authorization_code(code: String) -> void:
	if exchanging_token:
		return
	if client_id.is_empty() or code.is_empty() or code_verifier.is_empty() or redirect_uri.is_empty():
		login_failed.emit("Google 授權資料不完整，請重新登入")
		return
	exchanging_token = true
	login_status_changed.emit("正在交換 Google Token（Desktop PKCE）...")
	var params := _token_parameters(code)
	if exchange_mode == "lambda":
		# 只傳同次交易資料；Client ID、Secret 與 Google endpoint 由後端固定。
		var payload := {"code": code, "code_verifier": code_verifier, "redirect_uri": redirect_uri}
		var request_error := token_request.request(exchange_url,
			PackedStringArray(["Content-Type: application/json"]), HTTPClient.METHOD_POST,
			JSON.stringify(payload))
		if request_error != OK:
			exchanging_token = false
			code_verifier = ""
			oauth_state = ""
			login_failed.emit("無法送出登入交換請求，請重新授權")
		return

	# 轉換成表單格式
	var parts: PackedStringArray = []

	for key in params:
		parts.append(
			str(key).uri_encode()
			+ "="
			+ str(params[key]).uri_encode()
		)

	var body := "&".join(parts)

	var headers := PackedStringArray([
        "Content-Type: application/x-www-form-urlencoded"
	])

	# 傳送請求給 Google
	var error := token_request.request(
		TOKEN_URL,
		headers,
		HTTPClient.METHOD_POST,
		body
	)

	print("Token Request Error Code: ", error)

	if error != OK:
		exchanging_token = false
		code_verifier = ""
		login_failed.emit(
			"Token 請求無法送出：" + str(error)
		)
		return

	print("Token 請求已送出，等待 Google 回應...")



func _on_token_request_completed(
	result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray
) -> void:
	exchanging_token = false
	code_verifier = ""
	oauth_state = ""

	if result != HTTPRequest.RESULT_SUCCESS:
		login_failed.emit("Token 網路請求失敗")
		return

	var json := JSON.new()
	var parse_error := json.parse(
		body.get_string_from_utf8()
	)

	if parse_error != OK:
		login_failed.emit("無法解析 Google 回應")
		return

	var data = json.data

	if not data is Dictionary:
		login_failed.emit("Google 回應格式錯誤")
		return

	if response_code != 200:
		print("Google Token HTTP Status: ", response_code)
		if exchange_mode == "lambda":
			var messages := {
				401: "授權已失效，請重新登入（不要重用授權碼）",
				404: "AWS 尚未提供 Desktop 交換端點，請先由管理者部署",
				422: "登入請求格式不符，請重新授權或檢查桌面設定",
				503: "登入服務設定暫不可用，請管理者檢查 SSM／Client 設定",
				504: "登入交換逾時，請重新授權；不會自動重送授權碼",
			}
			login_failed.emit(messages.get(response_code, "AWS 登入交換失敗，請重新授權"))
			return
		# 只顯示已知錯誤代號與固定訊息，避免上游錯誤文字意外夾帶憑證。
		var error_type := str(data.get("error", ""))
		if not error_type in ["invalid_request", "invalid_client", "invalid_grant", "unauthorized_client", "access_denied"]:
			error_type = "unknown_error"
		var message := "Token 交換失敗（HTTP %d，%s），請重新授權或檢查 Desktop Client 設定" % [response_code, error_type]
		if str(data.get("error_description", "")).strip_edges() == "client_secret is missing.":
			message = "Google Token 交換失敗（HTTP %d，%s）：client_secret is missing.；本次未附 Secret，已停止登入，未略過任何驗證" % [response_code, error_type]
		login_failed.emit(message)
		return

	if not data.has("id_token"):
		login_failed.emit("Google 未回傳 ID Token")
		return
	
	var google_id_token := str(data.get("id_token", ""))

	if google_id_token.is_empty():
		login_failed.emit("Google ID Token 為空")
		return
	if exchange_mode == "lambda":
		# 只有固定 HTTPS 後端驗證成功的回覆才走這個 signal；不額外換碼／重試。
		if data.get("success", false) != true or not data.get("player") is Dictionary:
			login_failed.emit("AWS 未提供已驗證玩家資訊")
			return
		backend_login_verified.emit(data)
		return

	print("Google ID Token 已取得：", true)
	
	# 僅表示成功取得 Token，尚未驗證使用者身分
	login_status_changed.emit("已取得 Token，等待身分驗證")

	token_received.emit(data)
