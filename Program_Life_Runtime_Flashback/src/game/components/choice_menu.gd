extends Control

## 選項按鈕（畫面設定書 2.5）：直式排列，滑鼠移上去時發亮。
## 台灣風格：做成早餐店的「點餐單」——米白紙、紅色表頭、每一項前面一個勾選格。
## 選單放在畫面上半部，下方的劇情對話框維持可見。
## 用法：var value = await choice_menu.choose("想吃什麼？", [{"label": ..., "value": ...}])

signal chosen(value: String)

var _sheet: PanelContainer
var _header: Label
var _list: VBoxContainer


func _ready() -> void:
	UIKit.full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.18)
	UIKit.full_rect(dim)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	_sheet = PanelContainer.new()
	var paper := UIKit.box(Color("#fbf7ef"), 6, Color("#d8cfc0"), 2, 0)
	paper.shadow_color = Color(0, 0, 0, 0.35)
	paper.shadow_size = 10
	paper.shadow_offset = Vector2(4, 6)
	_sheet.add_theme_stylebox_override("panel", paper)
	_sheet.position = Vector2(610, 110)
	_sheet.custom_minimum_size = Vector2(700, 0)
	add_child(_sheet)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	_sheet.add_child(v)
	var head := PanelContainer.new()
	head.add_theme_stylebox_override("panel", UIKit.box(UIKit.STAMP_RED, 0, Color.TRANSPARENT, 0, 14))
	v.add_child(head)
	_header = UIKit.label("", 32, Color.WHITE)
	_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_child(_header)
	var pad := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		pad.add_theme_constant_override("margin_" + side, 22)
	v.add_child(pad)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 8)
	pad.add_child(_list)
	visible = false


func choose(prompt: String, options: Array) -> String:
	for c in _list.get_children():
		c.queue_free()
	_header.text = prompt if prompt != "" else "點餐單"
	for opt in options:
		var b := UIKit.button("☐　" + GameState.format_text(str(opt["label"])), Color.TRANSPARENT, UIKit.INK, 30)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(656, 70)
		var line := UIKit.box(Color.TRANSPARENT, 0, Color("#d8cfc0"), 0, 12)
		line.border_width_bottom = 2
		line.border_color = Color("#e3d9c8")
		b.add_theme_stylebox_override("normal", line)
		b.add_theme_stylebox_override("hover", UIKit.box(Color("#ffe9a8"), 6, UIKit.GOLD, 2, 12))
		b.add_theme_stylebox_override("pressed", UIKit.box(Color("#ffd97a"), 6, UIKit.GOLD, 2, 12))
		var label_text := b.text
		b.mouse_entered.connect(func(): b.text = label_text.replace("☐", "☑"))
		b.mouse_exited.connect(func(): b.text = label_text)
		var value := str(opt["value"])
		b.pressed.connect(func(): chosen.emit(value))
		_list.add_child(b)
	visible = true
	modulate.a = 0.0
	UIKit.fade(self, 1.0, 0.2)
	if GameFlow.autopilot and options.size() > 0:
		chosen.emit.call_deferred(str(options[0]["value"]))
	var result: String = await chosen
	visible = false
	return result
