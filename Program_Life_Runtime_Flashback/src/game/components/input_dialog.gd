extends Control

## 自由輸入框（劇本：@input 變數名 提示文字）——不在手機畫面時使用。

signal _submitted(text: String)

var _prompt: Label
var _input: LineEdit


func _ready() -> void:
	UIKit.full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.35)
	UIKit.full_rect(dim)
	add_child(dim)
	var center := CenterContainer.new()
	UIKit.full_rect(center)
	add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIKit.navy_panel(10, 36))
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 20)
	v.custom_minimum_size = Vector2(900, 0)
	panel.add_child(v)
	_prompt = UIKit.label("", 30, UIKit.TEXT_LIGHT)
	_prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_prompt)
	_input = LineEdit.new()
	_input.add_theme_font_override("font", UIKit.body_font())
	_input.add_theme_font_size_override("font_size", 28)
	_input.custom_minimum_size = Vector2(0, 64)
	_input.text_submitted.connect(func(_t: String): _submit())
	v.add_child(_input)
	var ok := UIKit.button("確定", UIKit.MRT_BLUE)
	ok.pressed.connect(_submit)
	v.add_child(ok)
	visible = false


func ask(prompt: String, placeholder: String = "") -> String:
	_prompt.text = prompt
	_input.text = ""
	_input.placeholder_text = placeholder
	visible = true
	_input.grab_focus()
	if GameFlow.autopilot:
		_input.text = "自動測試"
		_submit.call_deferred()
	var text: String = await _submitted
	visible = false
	return text


func _submit() -> void:
	var t := _input.text.strip_edges()
	if t != "":
		_submitted.emit(t)
