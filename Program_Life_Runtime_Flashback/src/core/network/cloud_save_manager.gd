
extends Node

## AWS 雲端存檔管理器。
## 負責讀取、上傳目前登入玩家的遊戲存檔。

const BACKEND_URL := "https://oj3wxp63b5ttx6sfklndqcrccq0nnxwq.lambda-url.ap-southeast-2.on.aws"

var _busy := false


## 下載雲端存檔。
## 回傳資料中的 data.has_save 表示雲端是否有進度。
func download_save() -> Dictionary:
	return await _send_request(
		HTTPClient.METHOD_GET,
		{}
	)


## 將 GameState 的本機存檔上傳至 AWS。
func upload_save() -> Dictionary:
	if not PlayerSession.is_logged_in:
		return {
			"ok": false,
			"message": "玩家尚未登入"
		}

	# 先儲存本機進度。
	GameState.save_game()

	var file := FileAccess.open(
		GameState.save_path,
		FileAccess.READ
	)

	if file == null:
		return {
			"ok": false,
			"message": "無法讀取本機存檔"
		}

	var save_text := file.get_as_text()
	file.close()

	var save_data = JSON.parse_string(save_text)

	if not (save_data is Dictionary):
		return {
			"ok": false,
			"message": "本機存檔格式錯誤"
		}

	
	# 建立獨立副本，不影響本機完整存檔。
	var cloud_data: Dictionary = save_data.duplicate(true)

	# 劇情回顧只保存在本機，不上傳 AWS。
	cloud_data.erase("backlog")

	print("[CloudSave] 使用精簡雲端存檔（不含 backlog）")

	return await _send_request(
		HTTPClient.METHOD_PUT,
		{"save": cloud_data}
	)



## 統一處理 AWS GET / PUT HTTP 請求。
func _send_request(
	method: int,
	request_data: Dictionary
) -> Dictionary:
	if _busy:
		return {
			"ok": false,
			"message": "已有雲端存檔請求正在執行"
		}

	if not PlayerSession.is_logged_in:
		return {
			"ok": false,
			"message": "玩家尚未登入"
		}

	var token := AuthManager.get_backend_access_token()

	if token.is_empty():
		return {
			"ok": false,
			"message": "Access Token 不存在或已過期"
		}

	var http := HTTPRequest.new()
	http.timeout = 20.0
	http.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(http)

	var headers := PackedStringArray([
		"Content-Type: application/json",
		"Authorization: Bearer " + token
	])

	var body := ""

	if method == HTTPClient.METHOD_PUT:
		body = JSON.stringify(request_data)

	_busy = true

	var error := http.request(
		BACKEND_URL + "/players/me/save",
		headers,
		method,
		body
	)

	if error != OK:
		_busy = false
		http.queue_free()

		return {
			"ok": false,
			"message": "無法送出 AWS 請求",
			"error": error
		}

	var response: Array = await http.request_completed

	_busy = false
	http.queue_free()

	var result := int(response[0])
	var status_code := int(response[1])
	var response_body: PackedByteArray = response[3]

	if result != HTTPRequest.RESULT_SUCCESS:
		return {
			"ok": false,
			"message": "AWS 網路連線失敗",
			"result": result
		}

	var data = JSON.parse_string(
		response_body.get_string_from_utf8()
	)

	if not (data is Dictionary):
		return {
			"ok": false,
			"message": "AWS 回傳格式不正確",
			"status": status_code
		}

	if status_code != 200:
		return {
			"ok": false,
			"message": str(data.get("detail", "AWS 請求失敗")),
			"status": status_code
		}

	if not data.get("success", false):
		return {
			"ok": false,
			"message": "AWS 未確認操作成功",
			"status": status_code
		}

	return {
		"ok": true,
		"status": status_code,
		"data": data
	}
