extends Control

## 手機畫面（畫面設定書 2.5）：3.2.1 與倖芳傳訊息、4.3 一則訊息、5.3 爸爸的血壓紀錄。
## 直式手機框置中，裡面是聊天泡泡；玩家輸入的文字會變成自己的泡泡（靠右）。
## 劇本寫法：@phone 倖芳 …（之間的對話都會變成泡泡）… @phone off

signal _clicked
signal _submitted(text: String)

const ME := "你"

var contact: String = ""
var _frame: PanelContainer
var _title: Label
var _scroll: ScrollContainer
var _list: VBoxContainer
var _input_row: HBoxContainer
var _input: LineEdit
var _counter: Label
var _send: Button
var _max_len: int = 0
var _waiting_click: bool = false
var _hint: Label


func _ready() -> void:
	UIKit.full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_frame = PanelContainer.new()
	_frame.add_theme_stylebox_override("panel", UIKit.box(Color("#111418"), 54, Color("#3a3f47"), 6, 22))
	_frame.anchor_left = 0.5
	_frame.anchor_right = 0.5
	_frame.offset_left = -270
	_frame.offset_right = 270
	_frame.offset_top = 60
	_frame.offset_bottom = 1020
	_frame.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_frame)

	var screen := PanelContainer.new()
	screen.add_theme_stylebox_override("panel", UIKit.box(Color("#eef1f5"), 36, Color.TRANSPARENT, 0, 0))
	_frame.add_child(screen)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	screen.add_child(v)

	var header := PanelContainer.new()
	header.add_theme_stylebox_override("panel", UIKit.box(Color("#ffffff"), 36, Color.TRANSPARENT, 0, 18))
	v.add_child(header)
	_title = UIKit.label("", 26, UIKit.INK)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_child(_title)

	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(_scroll)
	var pad := MarginContainer.new()
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "right", "top", "bottom"]:
		pad.add_theme_constant_override("margin_" + side, 16)
	_scroll.add_child(pad)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 12)
	pad.add_child(_list)

	_input_row = HBoxContainer.new()
	_input_row.add_theme_constant_override("separation", 8)
	var input_pad := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		input_pad.add_theme_constant_override("margin_" + side, 12)
	input_pad.add_child(_input_row)
	v.add_child(input_pad)
	_input = LineEdit.new()
	_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_input.add_theme_font_override("font", UIKit.body_font())
	_input.add_theme_font_size_override("font_size", 24)
	_input.text_changed.connect(_on_text_changed)
	_input.text_submitted.connect(func(_t: String): _on_send())
	_input_row.add_child(_input)
	_counter = UIKit.label("", 18, Color("#8a939c"))
	_input_row.add_child(_counter)
	_send = UIKit.button("送出", UIKit.PY_BLUE, Color.WHITE, 22)
	_send.pressed.connect(_on_send)
	_input_row.add_child(_send)
	input_pad.visible = false

	_hint = UIKit.label(UIKit.CONTINUE_HINT, 20, Color("#8a939c"))
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.visible = false
	v.add_child(_hint)
	visible = false


func open(contact_name: String) -> void:
	contact = contact_name
	_title.text = contact_name
	for c in _list.get_children():
		c.queue_free()
	visible = true
	_frame.position.y += 80
	_frame.modulate.a = 0.0
	var t := create_tween().set_parallel(true)
	t.tween_property(_frame, "position:y", _frame.position.y - 80, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(_frame, "modulate:a", 1.0, 0.25)


func close() -> void:
	visible = false


## 加一個泡泡並等玩家點擊
func add_message(speaker: String, text: String) -> void:
	_add_bubble(speaker, text)
	await _wait_click()


## 旁白在手機裡顯示成置中的小灰字
func add_note(text: String) -> void:
	var l := UIKit.label(text, 20, Color("#7a838c"))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(440, 0)
	_list.add_child(l)
	_scroll_to_end()
	await _wait_click()


## 讓玩家在手機裡打字；max_len > 0 時顯示字數
func ask_input(placeholder: String, max_len: int = 0) -> String:
	_max_len = max_len
	_input.placeholder_text = placeholder
	_input.text = ""
	_on_text_changed("")
	_input_row.get_parent().visible = true
	_input.grab_focus()
	if GameFlow.autopilot:
		_input.text = "我想跟你一起住在湖邊"
		_on_send.call_deferred()
	var text: String = await _submitted
	_input_row.get_parent().visible = false
	_add_bubble(ME, text)
	return text


func _on_text_changed(t: String) -> void:
	_counter.text = "%d/%d" % [t.length(), _max_len] if _max_len > 0 else ""
	_counter.add_theme_color_override("font_color", Color("#d9534f") if _max_len > 0 and t.length() > _max_len else Color("#8a939c"))


func _on_send() -> void:
	var t := _input.text.strip_edges()
	if t == "":
		return
	_submitted.emit(t)


func _add_bubble(speaker: String, text: String) -> void:
	var me := speaker == ME
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END if me else BoxContainer.ALIGNMENT_BEGIN
	var bubble := PanelContainer.new()
	var bg := Color("#9fd18b") if me else Color("#ffffff")
	bubble.add_theme_stylebox_override("panel", UIKit.box(bg, 20, Color.TRANSPARENT, 0, 14))
	var l := UIKit.label(text, 24, UIKit.INK)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(minf(340, 26.0 * text.length() + 10), 0)
	bubble.add_child(l)
	row.add_child(bubble)
	_list.add_child(row)
	_scroll_to_end()


func _scroll_to_end() -> void:
	await get_tree().process_frame
	_scroll.scroll_vertical = int(_scroll.get_v_scroll_bar().max_value)


func _wait_click() -> void:
	if GameFlow.autopilot:
		await get_tree().create_timer(0.05).timeout
		return
	_waiting_click = true
	_hint.visible = true
	await _clicked
	_hint.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not _waiting_click or not visible:
		return
	var go: bool = (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) \
		or (event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_SPACE, KEY_ENTER])
	if go:
		get_viewport().set_input_as_handled()
		_waiting_click = false
		_clicked.emit()

