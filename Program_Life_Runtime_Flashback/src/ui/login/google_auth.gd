
extends Node

signal login_status_changed(message: String)
signal authorization_received(code: String)
signal login_failed(message: String)
signal token_received(token_data: Dictionary)

@onready var token_request: HTTPRequest = $TokenRequest

const TOKEN_URL = "https://oauth2.googleapis.com/token"
const CLIENT_ID = "201834248641-sdq2fk3tburk3hgvhbf41ffrsuhstfbp.apps.googleusercontent.com"

var server := TCPServer.new()
var peer: StreamPeerTCP

var redirect_uri := ""
var oauth_state := ""
var code_verifier := ""
var waiting_for_callback := false

func _ready() -> void:
	set_process(false)
	
	token_request.request_completed.connect(
		_on_token_request_completed
	)
	

func read_env_value(key: String) -> String:
	var path := "res://.env"

	if not FileAccess.file_exists(path):
		push_error("找不到 .env 檔案")
		return ""

	var file := FileAccess.open(path, FileAccess.READ)

	if file == null:
		push_error("無法開啟 .env 檔案")
		return ""

	while not file.eof_reached():
		var line := file.get_line().strip_edges()

		if line.is_empty() or line.begins_with("#"):
			continue

		var separator := line.find("=")

		if separator == -1:
			continue

		var env_key := line.substr(
			0, separator
		).strip_edges()

		var env_value := line.substr(
			separator + 1
		).strip_edges()

		if env_key == key:
			file.close()

			if env_value.length() >= 2:
				if (
					env_value.begins_with("\"")
					and env_value.ends_with("\"")
				) or (
					env_value.begins_with("'")
					and env_value.ends_with("'")
				):
					env_value = env_value.substr(
						1, env_value.length() - 2
					)

			return env_value

	file.close()
	return ""

func start_google_login() -> void:
	if waiting_for_callback:
		return

	var error := server.listen(0, "127.0.0.1")

	if error != OK:
		login_failed.emit("無法啟動本機回呼服務")
		return

	var port := server.get_local_port()
	redirect_uri = "http://127.0.0.1:%d/" % port

	oauth_state = generate_random_token(32)
	code_verifier = generate_random_token(48)

	var challenge := sha256_base64url(code_verifier)

	var params := {
		"client_id": CLIENT_ID,
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
	set_process(true)

	login_status_changed.emit("正在等待 Google 登入...")

	var open_error := OS.shell_open(auth_url)
	if open_error != OK:
		stop_callback_server()
		login_failed.emit("無法開啟瀏覽器")


func _process(_delta: float) -> void:
	if not waiting_for_callback:
		return

	if peer == null and server.is_connection_available():
		peer = server.take_connection()

	if peer == null:
		return

	peer.poll()

	if peer.get_available_bytes() <= 0:
		return

	var request := peer.get_utf8_string(
		peer.get_available_bytes()
	)

	var first_line := request.split("\r\n")[0]
	var request_parts := first_line.split(" ")

	if request_parts.size() < 2:
		return

	var path := request_parts[1]
	var query := path.get_slice("?", 1)

	var values := parse_query(query)

	if values.get("state", "") != oauth_state:
		send_browser_response("登入驗證失敗")
		stop_callback_server()
		login_failed.emit("OAuth state 驗證失敗")
		return

	if values.has("error"):
		send_browser_response("Google 登入已取消")
		stop_callback_server()
		login_failed.emit(str(values["error"]))
		return

	var code := str(values.get("code", ""))

	if code.is_empty():
		send_browser_response("未收到授權碼")
		stop_callback_server()
		login_failed.emit("未收到 Authorization Code")
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
		var value := item.get_slice("=", 1).uri_decode()
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


func _exit_tree() -> void:
	stop_callback_server()
	

func exchange_authorization_code(code: String) -> void:
	login_status_changed.emit("正在交換 Google Token...")

	# 從 .env 讀取 Client Secret
	var client_secret := read_env_value(
        "GOOGLE_OAUTH_CLIENT_SECRET"
	)

	print(
		"Google Secret loaded: ",
		not client_secret.is_empty()
	)

	# 只有 Secret 為空時才停止
	if client_secret.is_empty():
		login_failed.emit(
            "尚未設定 GOOGLE_OAUTH_CLIENT_SECRET"
		)
		return

	# 建立 Token 交換參數
	var params := {
		"code": code,
		"client_id": CLIENT_ID,
		"client_secret": client_secret,
		"redirect_uri": redirect_uri,
		"grant_type": "authorization_code",
		"code_verifier": code_verifier
	}

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
		var error_type := str(
			data.get("error", "unknown_error")
		)

		var error_description := str(
			data.get("error_description", "沒有詳細說明")
		)

		print("Google Token HTTP Status: ", response_code)
		print("Google Token Error: ", error_type)
		print("Google Token Description: ", error_description)

		login_failed.emit(
	        "Token 交換失敗："
			+ error_type
			+ " - "
			+ error_description
		)
		return

	if not data.has("id_token"):
		login_failed.emit("Google 未回傳 ID Token")
		return

	# 僅表示成功取得 Token，尚未驗證使用者身分
	login_status_changed.emit("已取得 Token，等待身分驗證")

	token_received.emit(data)
