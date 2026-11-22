
extends Node

## AWS 雲端存檔管理器。
## 負責讀取、上傳目前登入玩家的遊戲存檔。

const BACKEND_URL := "https://oj3wxp63b5ttx6sfklndqcrccq0nnxwq.lambda-url.ap-southeast-2.on.aws"

var _busy := false
var _auto_save_pending := false
var _auto_save_running := false


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
		
	var request_player_id := PlayerSession.player_id
	var wait_started := Time.get_ticks_msec()

	# 其他存檔請求還沒結束時，依序等待。
	while _busy:
		if Time.get_ticks_msec() - wait_started >= 25000:
			return {
				"ok": false,
				"message": "等待雲端存檔逾時"
			}

		await get_tree().create_timer(0.2, true).timeout

		if (
			not PlayerSession.is_logged_in
			or PlayerSession.player_id != request_player_id
		):
			return {
				"ok": false,
				"message": "登入狀態已變更"
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


## 收到小節完成事件，要求自動同步。
func request_auto_save() -> void:
	if not PlayerSession.is_logged_in:
		return

	_auto_save_pending = true

	if not _auto_save_running:
		_process_auto_save.call_deferred()


## 依序上傳，短時間內多次更新以最新進度為準。
func _process_auto_save() -> void:
	if _auto_save_running:
		return

	_auto_save_running = true
	var player_id := PlayerSession.player_id

	while (
		_auto_save_pending
		and PlayerSession.is_logged_in
		and PlayerSession.player_id == player_id
	):
		_auto_save_pending = false

		print("[CloudSave] 小節完成，正在同步 AWS...")

		var result: Dictionary = await upload_save()

		if (
			not PlayerSession.is_logged_in
			or PlayerSession.player_id != player_id
		):
			break

		if result.get("ok", false):
			print("[CloudSave] 小節雲端存檔成功")
		else:
			push_warning(
				"[CloudSave] 自動同步失敗：" +
				str(result.get("message", "未知錯誤"))
			)

			# 失敗後等待三秒再試一次。
			await get_tree().create_timer(
				3.0, true
			).timeout

			if (
				not PlayerSession.is_logged_in
				or PlayerSession.player_id != player_id
			):
				break

			result = await upload_save()

			if result.get("ok", false):
				print("[CloudSave] 自動存檔重試成功")
			else:
				push_warning(
					"[CloudSave] 重試仍失敗，進度保留在本機"
				)

	_auto_save_running = false

	# 如果執行期間切換帳號，新帳號有待同步資料就再啟動。
	if _auto_save_pending and PlayerSession.is_logged_in:
		_process_auto_save.call_deferred()
