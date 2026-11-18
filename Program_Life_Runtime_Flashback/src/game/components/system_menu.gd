extends Control

## 系統選單（畫面設定書 2.1）：右上角固定四顆按鈕：回顧、存檔、成就、設定。
## 回顧：這次遊玩看過的對話紀錄；存檔：記錄目前所在的小節（讀檔時從該小節開頭開始）；
## 成就：已解鎖／未解鎖列表；設定：文字速度、自動速度、AI、音量、記憶地圖（章節選擇）、回標題。
## 「設定」合併了原本左上角齒輪（PauseMenu）的功能：打開時遊戲暫停、繼續遊戲、主音量、
## 返回關卡地圖（記憶地圖）、中離遊戲；按 ESC 也會打開／關閉這個面板。

signal toast_requested(text: String)
signal panel_opened
signal panel_closed


var _overlay: Control
var _panel: PanelContainer
var _content: VBoxContainer
var _title: Label


const GEAR_ICON := "res://assets/images/gear.png"
const BACKEND_URL := "https://oj3wxp63b5ttx6sfklndqcrccq0nnxwq.lambda-url.ap-southeast-2.on.aws"

var _logout_busy := false


func _ready() -> void:
	UIKit.full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# 面板打開時遊戲會暫停，選單本身要能繼續運作
	process_mode = Node.PROCESS_MODE_ALWAYS

	var row := HBoxContainer.new()
	row.anchor_left = 1.0
	row.anchor_right = 1.0
	row.offset_left = -560
	row.offset_right = -30
	row.offset_top = 24
	row.offset_bottom = 80
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override("separation", 10)
	add_child(row)
	for spec in [["回顧", _open_backlog], ["存檔", _save], ["成就", _open_achievements], ["設定", _open_settings]]:
		var b := UIKit.button(spec[0], UIKit.NAVY, Color.WHITE, UIKit.SMALL_SIZE)
		b.custom_minimum_size = Vector2(110, 52)
		b.pressed.connect(spec[1])
		# 「設定」就是原本的齒輪：沿用齒輪圖示
		if spec[0] == "設定" and ResourceLoader.exists(GEAR_ICON):
			b.icon = load(GEAR_ICON)
			b.expand_icon = true
			b.custom_minimum_size = Vector2(130, 52)
		row.add_child(b)

	_overlay = Control.new()
	UIKit.full_rect(_overlay)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	UIKit.full_rect(dim)
	dim.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed:
			close_panel())
	_overlay.add_child(dim)
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", UIKit.box(Color("#f4efe6"), 10, UIKit.GOLD, 3, 32))
	_panel.position = Vector2(360, 110)
	_panel.size = Vector2(1200, 860)
	_overlay.add_child(_panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	_panel.add_child(v)
	var head := HBoxContainer.new()
	v.add_child(head)
	_title = UIKit.label("", 36)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(_title)
	var close_btn := UIKit.button("關閉", UIKit.RESET_GRAY, Color.WHITE, UIKit.SMALL_SIZE)
	close_btn.pressed.connect(close_panel)
	head.add_child(close_btn)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(1130, 740)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 12)
	scroll.add_child(_content)
	_overlay.visible = false
	add_child(_overlay)


## 回顧的內容存在 GameState（會跟著存檔），重新打開遊戲也看得到
func add_backlog(speaker: String, text: String) -> void:
	GameState.add_backlog(speaker, text)


func is_panel_open() -> bool:
	return _overlay.visible


func close_panel() -> void:
	if _logout_busy:
		return

	_overlay.visible = false
	get_tree().paused = false
	panel_closed.emit()


## ESC：打開／關閉設定（取代原本齒輪的暫停選單）
func toggle_settings() -> void:
	if _overlay.visible:
		close_panel()
	else:
		_open_settings()


## 打開任何面板時遊戲暫停（打字、自動模式、動畫都停住），關閉後繼續
func _open(title: String) -> void:
	_title.text = title
	for c in _content.get_children():
		c.queue_free()
	_overlay.visible = true
	get_tree().paused = true
	panel_opened.emit()


func _open_backlog() -> void:
	_open("回顧")
	for entry in GameState.backlog:
		var l := UIKit.rich(26)
		var who: String = GameState.display_name(entry["speaker"])
		var col := ChapterRegistry.character_color(who).to_html(false)
		l.text = ("[color=#%s][b]%s[/b][/color]　%s" % [col, who, entry["text"]]) if who != "" else "[i][color=#6b7280]%s[/color][/i]" % entry["text"]
		_content.add_child(l)
	await get_tree().process_frame
	var scroll := _content.get_parent() as ScrollContainer
	scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)


func _save() -> void:
	GameState.save_game()
	var sec := ChapterRegistry.get_section(GameState.section_id)
	toast_requested.emit("已存檔：%s" % sec.get("title", ""))


func _open_achievements() -> void:
	_open("成就（%d / %d）" % [GameState.achievements.size(), ChapterRegistry.ACHIEVEMENTS.size()])
	for a in ChapterRegistry.ACHIEVEMENTS:
		var got := GameState.has_achievement(a["id"])
		var row := PanelContainer.new()
		row.add_theme_stylebox_override("panel", UIKit.box(Color("#fbf3dc") if got else Color("#e3e0da"), 8, UIKit.STAMP_RED if got else Color.TRANSPARENT, 2 if got else 0, 16))
		var l := UIKit.label(("【%s】　%s" % [a["id"], a["desc"]]) if got else "？？？　—　尚未解鎖", 26,
			UIKit.INK if got else Color("#8a939c"))
		row.add_child(l)
		_content.add_child(row)
	var stat := UIKit.label("目前「第一次就通過」的關卡：%d / %d" % [GameState.first_try_passed(), GameState.total_levels()], 22, Color("#556877"))
	_content.add_child(stat)


func _open_settings() -> void:
	_open("設定（遊戲暫停中）")
	var resume := UIKit.button("繼續遊戲", UIKit.RUN_GREEN)
	resume.custom_minimum_size = Vector2(0, 64)
	resume.pressed.connect(close_panel)
	_content.add_child(resume)
	_content.add_child(HSeparator.new())
	_add_slider("文字速度", 10, 120, GameState.settings["text_speed"], func(v: float): GameState.settings["text_speed"] = v)
	_add_slider("自動模式每句停留（秒）", 0.5, 4.0, GameState.settings["auto_delay"], func(v: float): GameState.settings["auto_delay"] = v)
	_add_slider("主音量", 0.0, 1.0, GameState.settings["master_volume"], func(v: float):
		GameState.settings["master_volume"] = v
		GameState.apply_volume())
	var ai := CheckButton.new()
	ai.text = "使用 AI 即時回應（關閉時一律使用備用台詞）"
	ai.add_theme_font_override("font", UIKit.body_font())
	ai.add_theme_font_size_override("font_size", 24)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		ai.add_theme_color_override(state, UIKit.INK)
	ai.button_pressed = GameState.settings["ai_enabled"]
	ai.toggled.connect(func(on: bool): GameState.settings["ai_enabled"] = on)
	_content.add_child(ai)
	_content.add_child(UIKit.label("Python 執行環境：" + PythonRunner.backend_name(), 22, Color("#556877")))

	_content.add_child(HSeparator.new())
	_content.add_child(UIKit.label("章節", 28))
	var map_btn := UIKit.button("返回關卡地圖（記憶地圖 MEMORY LOAD）", UIKit.MRT_BLUE)
	map_btn.custom_minimum_size = Vector2(0, 64)
	map_btn.pressed.connect(func():
		close_panel()
		GameFlow.open_map(true))
	_content.add_child(map_btn)
	_content.add_child(UIKit.label("走過的小節會在地圖上解鎖，點選就能從那一節重新開始。", 20, Color("#556877")))

	
	_content.add_child(HSeparator.new())

	# B：存檔、撤銷 AWS Session、返回標題畫面。
	var back := UIKit.button(
		"存檔並回到標題畫面",
		UIKit.RESET_GRAY
	)
	back.pressed.connect(func():
		_logout_and_leave(false)
	)
	_content.add_child(back)

	# C：存檔、撤銷 AWS Session、關閉遊戲。
	# 網頁版不提供關閉程式按鈕。
	if not OS.has_feature("web"):
		var quit := UIKit.button(
			"中離遊戲（存檔後關閉）",
			Color("#7a2a2a")
		)
		quit.pressed.connect(func():
			_logout_and_leave(true)
		)
		_content.add_child(quit)



func _add_slider(label_text: String, min_v: float, max_v: float, value: float, on_change: Callable) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	var l := UIKit.label(label_text, 24)
	l.custom_minimum_size = Vector2(360, 0)
	row.add_child(l)
	var s := HSlider.new()
	s.min_value = min_v
	s.max_value = max_v
	s.step = (max_v - min_v) / 100.0
	s.value = value
	s.custom_minimum_size = Vector2(600, 40)
	s.value_changed.connect(on_change)
	row.add_child(s)
	_content.add_child(row)


## 正式登出流程。
## quit_game = false：返回標題。
## quit_game = true：關閉遊戲。
func _logout_and_leave(quit_game: bool) -> void:
	if _logout_busy:
		return

	_logout_busy = true

	# 登出期間避免操作其他選單按鈕。
	for child in _content.get_children():
		if child is BaseButton:
			child.disabled = true

	
	print("[Logout] 開始存檔...")
	GameState.save_game()
	print("[Logout] 本機存檔完成")
	
	if PlayerSession.is_logged_in:
		var errors_synced: bool = await ErrorLogManager.flush_pending(
			6.0
		)

		if not errors_synced:
			push_warning(
				"[ErrorLog] 尚有錯誤紀錄未同步，"
				+ "已保留本機供下次登入重送"
			)


	# 有登入時，必須先完成雲端存檔，才能撤銷 Session。
	if PlayerSession.is_logged_in:
		print("[CloudSave] 正在上傳遊戲進度...")

		var upload_result: Dictionary = await CloudSaveManager.upload_save()

		if upload_result.get("ok", false):
			print("[CloudSave] AWS 雲端存檔成功")
		else:
			var message := str(
				upload_result.get("message", "未知錯誤")
			)

			push_warning(
				"[CloudSave] 雲端存檔失敗：" + message
			)

			# 不直接登出，避免下次登入時雲端舊進度
			# 蓋掉這次尚未同步的進度。
			_logout_busy = false

			for child in _content.get_children():
				if child is BaseButton:
					child.disabled = false

			toast_requested.emit("雲端存檔失敗，請重試")
			return
	else:
		print("[CloudSave] 未登入，僅保留本機存檔")

	var refresh_token := AuthManager.get_backend_refresh_token()

	var revoked := false

	if not refresh_token.is_empty():
		print("[Logout] 正在撤銷 AWS Session...")
		revoked = await _send_backend_logout(refresh_token)

		# 防止 Access Token 自動更新剛好與登出同時發生。
		# 如果 Refresh Token 已輪替，使用最新 Token 再試一次。
		if not revoked:
			var latest_token := AuthManager.get_backend_refresh_token()

			if (
				not latest_token.is_empty()
				and latest_token != refresh_token
			):
				print("[Logout] 偵測到 Token 輪替，重新嘗試登出...")
				revoked = await _send_backend_logout(latest_token)
	else:
		print("[Logout] 沒有可用的 Refresh Token")

	if revoked:
		print("[Logout] AWS Session 撤銷成功")
	else:
		push_warning(
			"[Logout] AWS Session 未確認撤銷，"
			+ "仍會清除本機登入狀態"
		)

	# 清除 Godot 中的登入資料與 Token。
	PlayerSession.logout()
	print("[Logout] 本機登入狀態已清除")

	# 恢復遊戲樹，讓場景可以正常切換。
	get_tree().paused = false
	_logout_busy = false

	if quit_game:
		print("[Logout] 正在關閉遊戲")
		get_tree().quit()
	else:
		print("[Logout] 正在返回標題畫面")
		GameFlow.back_to_title()


## 呼叫 AWS /auth/logout。
## 只有 HTTP 200 且 success=true 才視為成功。
func _send_backend_logout(refresh_token: String) -> bool:
	var http := HTTPRequest.new()
	http.process_mode = Node.PROCESS_MODE_ALWAYS
	http.timeout = 15.0
	add_child(http)

	var headers := PackedStringArray([
		"Content-Type: application/json"
	])

	var body := JSON.stringify({
		"refresh_token": refresh_token
	})

	var error := http.request(
		BACKEND_URL + "/auth/logout",
		headers,
		HTTPClient.METHOD_POST,
		body
	)

	if error != OK:
		print("[Logout] 無法發送登出請求：", error)
		http.queue_free()
		return false

	var response: Array = await http.request_completed
	http.queue_free()

	var result := int(response[0])
	var status_code := int(response[1])
	var response_body: PackedByteArray = response[3]

	if result != HTTPRequest.RESULT_SUCCESS:
		print("[Logout] AWS 連線失敗，結果：", result)
		return false

	print("[Logout] AWS HTTP 狀態碼：", status_code)

	if status_code != 200:
		return false

	var data = JSON.parse_string(
		response_body.get_string_from_utf8()
	)

	return (
		data is Dictionary
		and data.get("success", false) == true
	)
