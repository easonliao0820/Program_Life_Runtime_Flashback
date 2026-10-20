extends Control

## 系統選單（畫面設定書 2.1）：右上角固定四顆按鈕：回顧、存檔、成就、設定。
## 回顧：這次遊玩看過的對話紀錄；存檔：記錄目前所在的小節（讀檔時從該小節開頭開始）；
## 成就：已解鎖／未解鎖列表；設定：文字速度、自動速度、AI、音量、記憶地圖（章節選擇）、回標題。

signal toast_requested(text: String)
signal panel_opened
signal panel_closed


var _overlay: Control
var _panel: PanelContainer
var _content: VBoxContainer
var _title: Label


func _ready() -> void:
	UIKit.full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

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
	_overlay.visible = false
	panel_closed.emit()


func _open(title: String) -> void:
	_title.text = title
	for c in _content.get_children():
		c.queue_free()
	_overlay.visible = true
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
	_open("設定")
	_add_slider("文字速度", 10, 120, GameState.settings["text_speed"], func(v: float): GameState.settings["text_speed"] = v)
	_add_slider("自動模式每句停留（秒）", 0.5, 4.0, GameState.settings["auto_delay"], func(v: float): GameState.settings["auto_delay"] = v)
	_add_slider("音量", 0.0, 1.0, GameState.settings["master_volume"], func(v: float):
		GameState.settings["master_volume"] = v
		AudioServer.set_bus_volume_db(0, linear_to_db(maxf(v, 0.0001))))
	var ai := CheckButton.new()
	ai.text = "使用 AI 即時回應（關閉時一律使用備用台詞）"
	ai.add_theme_font_override("font", UIKit.body_font())
	ai.add_theme_font_size_override("font_size", 24)
	ai.button_pressed = GameState.settings["ai_enabled"]
	ai.toggled.connect(func(on: bool): GameState.settings["ai_enabled"] = on)
	_content.add_child(ai)
	_content.add_child(UIKit.label("Python 執行環境：" + PythonRunner.backend_name(), 22, Color("#556877")))

	_content.add_child(HSeparator.new())
	_content.add_child(UIKit.label("章節", 28))
	var map_btn := UIKit.button("開啟記憶地圖（MEMORY LOAD）", UIKit.MRT_BLUE)
	map_btn.custom_minimum_size = Vector2(0, 64)
	map_btn.pressed.connect(func():
		close_panel()
		GameFlow.open_map(true))
	_content.add_child(map_btn)
	_content.add_child(UIKit.label("走過的小節會在地圖上解鎖，點選就能從那一節重新開始。", 20, Color("#556877")))

	_content.add_child(HSeparator.new())
	var back := UIKit.button("存檔並回到標題畫面", UIKit.RESET_GRAY)
	back.pressed.connect(func():
		close_panel()
		GameFlow.back_to_title())
	_content.add_child(back)


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
