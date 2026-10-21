extends Control

## 對話框（畫面設定書 2.1，外觀沿用舊版 StoryBox：深藍半透明、金色細邊、捷運藍名字牌）
## - 旁白：不顯示名字牌，斜體淡灰字
## - 心聲：金色虛線邊框，表示腦中的聲音
## - 右上方「自動」「快進」
## - 劇情為主：進入程式關卡／探索模式時，對話框不會消失，而是縮進左上的「劇情區」（set_compact），
##   派森的提示、錯誤解說都在這裡說，劇情不中斷。
## 用法：await dialogue_box.show_line("say", "派森", "你好")  —— 玩家點擊後才會繼續

signal advanced
signal line_shown(kind: String, speaker: String, text: String)

const FULL_RECT := Rect2(160, 790, 1600, 250)

var auto_mode: bool = false
var skip_mode: bool = false
var input_enabled: bool = true

var _panel: PanelContainer
var _margin: MarginContainer
var _name_plate: PanelContainer
var _name_label: Label
var _text: RichTextLabel
var _dash: Control
var _next_mark: Label
var _toggles: HBoxContainer
var _auto_btn: Button
var _skip_btn: Button
var _typing: bool = false
var _waiting: bool = false
var _shown_chars: float = 0.0
var _hold: float = 0.0
var _rect: Rect2 = FULL_RECT
var _compact: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIKit.full_rect(self)

	_panel = PanelContainer.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_panel)
	_margin = MarginContainer.new()
	_panel.add_child(_margin)
	_text = UIKit.rich(UIKit.DIALOGUE_SIZE, UIKit.TEXT_LIGHT)
	_text.fit_content = false
	_text.scroll_active = false
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_margin.add_child(_text)
	_dash = DashedBorder.new()
	UIKit.full_rect(_dash)
	_panel.add_child(_dash)

	_name_plate = PanelContainer.new()
	_name_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_name_label = UIKit.label("", 28, Color.WHITE)
	_name_plate.add_child(_name_label)
	add_child(_name_plate)

	_next_mark = UIKit.label(UIKit.CONTINUE_HINT, 20, UIKit.GOLD)
	add_child(_next_mark)

	_toggles = HBoxContainer.new()
	_toggles.add_theme_constant_override("separation", 10)
	add_child(_toggles)
	_auto_btn = UIKit.button("自動", UIKit.NAVY, Color.WHITE, UIKit.SMALL_SIZE)
	_skip_btn = UIKit.button("快進", UIKit.NAVY, Color.WHITE, UIKit.SMALL_SIZE)
	_auto_btn.toggle_mode = true
	_skip_btn.toggle_mode = true
	_auto_btn.toggled.connect(_on_auto_toggled)
	_skip_btn.toggled.connect(_on_skip_toggled)
	_toggles.add_child(_auto_btn)
	_toggles.add_child(_skip_btn)

	_apply_layout()
	set_box_visible(false)


# ------------------------------------------------------------------
# 版面：全螢幕下方（劇情模式）／縮進劇情區（程式關卡、探索模式）
# ------------------------------------------------------------------

func set_full() -> void:
	_compact = false
	_rect = FULL_RECT
	_apply_layout()


func set_compact(rect: Rect2) -> void:
	_compact = true
	_rect = rect
	_apply_layout()


func _apply_layout() -> void:
	# 先改最小尺寸再改大小，否則會被舊的最小尺寸撐住
	_panel.custom_minimum_size = _rect.size
	_panel.position = _rect.position
	_panel.size = _rect.size
	var pad_x := 28 if _compact else 48
	_margin.add_theme_constant_override("margin_left", pad_x)
	_margin.add_theme_constant_override("margin_right", pad_x)
	_margin.add_theme_constant_override("margin_top", 32 if _compact else 44)
	_margin.add_theme_constant_override("margin_bottom", 16 if _compact else 28)
	var font_size := 26 if _compact else UIKit.DIALOGUE_SIZE
	_text.add_theme_font_size_override("normal_font_size", font_size)
	_text.add_theme_font_size_override("italics_font_size", font_size)
	_name_label.add_theme_font_size_override("font_size", 24 if _compact else 28)
	_name_plate.position = _rect.position + Vector2(24 if _compact else 40, -26 if _compact else -30)
	_next_mark.position = _rect.end - Vector2(200 if not _compact else 180, 40)
	_toggles.position = Vector2(_rect.end.x - 230, _rect.position.y - 54)
	_toggles.visible = not _compact and _panel.visible


func _on_auto_toggled(on: bool) -> void:
	auto_mode = on
	_restyle_toggles()


func _on_skip_toggled(on: bool) -> void:
	skip_mode = on
	_restyle_toggles()


func _restyle_toggles() -> void:
	_auto_btn.modulate = Color(1.3, 1.2, 0.6) if auto_mode else Color.WHITE
	_skip_btn.modulate = Color(1.3, 1.2, 0.6) if skip_mode else Color.WHITE


func set_box_visible(on: bool) -> void:
	_panel.visible = on
	_name_plate.visible = on and _name_label.text != ""
	_next_mark.visible = false
	_toggles.visible = on and not _compact


# ------------------------------------------------------------------
# 顯示文字
# ------------------------------------------------------------------

## kind：say / narrate / think / system
func show_line(kind: String, speaker: String, text: String) -> void:
	_style_for(kind, speaker)
	set_box_visible(true)
	_name_plate.visible = _name_label.text != ""
	_text.text = "[i]%s[/i]" % text if kind == "narrate" else text
	_text.visible_characters = 0
	_shown_chars = 0.0
	_typing = true
	_waiting = true
	_hold = 0.0
	_next_mark.visible = false
	line_shown.emit(kind, speaker, text)
	await advanced


## 不等待玩家、直接把文字放上去（派森在關卡中的提示、「思考中……」）
func show_status(speaker: String, text: String, kind: String = "say") -> void:
	_style_for(kind, speaker)
	set_box_visible(true)
	_name_plate.visible = _name_label.text != ""
	_text.text = text
	_text.visible_characters = -1
	_typing = false
	_waiting = false
	_next_mark.visible = false


func request_advance() -> void:
	if not _waiting:
		return
	if _typing:
		_finish_typing()
		return
	_waiting = false
	_next_mark.visible = false
	advanced.emit()


func is_waiting() -> bool:
	return _waiting


func _finish_typing() -> void:
	_typing = false
	_text.visible_characters = -1
	_next_mark.visible = true
	_hold = 0.0


func _process(delta: float) -> void:
	if not _waiting:
		return
	if _typing:
		var speed: float = GameState.settings.get("text_speed", 40.0)
		_shown_chars += delta * (speed * 20.0 if skip_mode or GameFlow.autopilot else speed)
		_text.visible_characters = int(_shown_chars)
		if _shown_chars >= _text.get_total_character_count():
			_finish_typing()
		return
	_next_mark.modulate.a = 0.5 + 0.5 * sin(Time.get_ticks_msec() / 250.0)
	if skip_mode or auto_mode or GameFlow.autopilot:
		_hold += delta
		var wait: float = 0.08 if skip_mode or GameFlow.autopilot else float(GameState.settings.get("auto_delay", 1.6))
		if _hold >= wait:
			request_advance()


func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled or not _waiting or not is_visible_in_tree():
		return
	var go := false
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		go = true
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
		go = true
	if go:
		get_viewport().set_input_as_handled()
		request_advance()


func _style_for(kind: String, speaker: String) -> void:
	var text_color := UIKit.TEXT_LIGHT
	var plate_text := speaker
	var plate_color := UIKit.MRT_BLUE
	var panel := UIKit.navy_panel(10)
	_dash.visible = false
	match kind:
		"narrate":
			plate_text = ""
			text_color = Color("#c9d1da")
		"think":
			plate_text = ""
			text_color = Color("#e9eef4")
			panel = UIKit.box(Color(0.117647, 0.164706, 0.219608, 0.78), 10)
			_dash.visible = true
		"system":
			plate_text = "系統"
			plate_color = Color("#1b3a78")
			text_color = Color("#dfe9ff")
	# 角色有代表色時，名字牌左側加一條代表色（舊版名字牌維持捷運藍）
	var plate := UIKit.name_plate(plate_color)
	if kind == "say" and ChapterRegistry.CHARACTERS.has(speaker) and speaker != "系統":
		plate.border_width_left = 10
		plate.border_color = ChapterRegistry.character_color(speaker)
		if speaker == "派森":
			plate.border_color = UIKit.PY_YELLOW
	_panel.add_theme_stylebox_override("panel", panel)
	_text.add_theme_color_override("default_color", text_color)
	# 主角視角：「你」的台詞，名字牌顯示玩家輸入的名字
	_name_label.text = GameState.display_name(plate_text)
	_name_plate.add_theme_stylebox_override("panel", plate)


class DashedBorder extends Control:
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var r := Rect2(Vector2(4, 4), size - Vector2(8, 8))
		var pts := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y), r.position]
		for i in 4:
			draw_dashed_line(pts[i], pts[i + 1], UIKit.GOLD, 3.0, 14.0)
