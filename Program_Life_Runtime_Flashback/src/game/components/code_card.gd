extends PanelContainer

## 劇情中的程式碼卡片：劇本裡的 ``` 程式碼 ``` 會顯示在這裡。
## 可以按「▶ 執行看看」實際跑一次，看看印出什麼（不計分）。
## 卡片會一直留在畫面上，讓後面的對話可以解說這段程式，直到下一張卡片、關卡或換場景。

var _editor: CodeEdit
var _output: Label
var _run_btn: Button
var _code: String = ""


func _ready() -> void:
	add_theme_stylebox_override("panel", UIKit.navy_panel(10, 18))
	anchor_left = 0.5
	anchor_right = 0.5
	offset_left = -560
	offset_right = 560
	offset_top = 150
	mouse_filter = Control.MOUSE_FILTER_STOP
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	add_child(v)

	_editor = UIKit.code_editor(false, false)
	_editor.custom_minimum_size = Vector2(1080, 0)
	v.add_child(_editor)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	v.add_child(row)
	_run_btn = UIKit.button("▶ 執行看看", UIKit.RUN_GREEN, Color.WHITE, UIKit.SMALL_SIZE)
	_run_btn.pressed.connect(_on_run)
	row.add_child(_run_btn)
	_output = UIKit.label("", 22, Color("#e6edf3"))
	_output.add_theme_font_override("font", UIKit.mono_font())
	_output.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_output.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(_output)
	visible = false


func show_code(code: String, runnable: bool) -> void:
	_code = code
	_editor.text = code
	_output.text = ""
	_run_btn.visible = runnable
	_run_btn.disabled = false
	visible = true
	modulate.a = 0.0
	UIKit.fade(self, 1.0, 0.25)


## 解說模式：把第 line 行（從 1 開始）亮起來，其他行恢復；line <= 0 全部恢復
func highlight_line(line: int) -> void:
	for i in _editor.get_line_count():
		_editor.set_line_background_color(i, Color(0, 0, 0, 0))
	if line >= 1 and line <= _editor.get_line_count():
		_editor.set_line_background_color(line - 1, Color(UIKit.PY_YELLOW, 0.22))


func hide_card() -> void:
	if visible:
		visible = false


func _on_run() -> void:
	_run_btn.disabled = true
	_output.text = "執行中……"
	var result: Dictionary = await PythonRunner.run(_code, "", ["120"])
	_run_btn.disabled = false
	if result.get("ok", false):
		var out: String = str(result.get("stdout", "")).strip_edges(false, true)
		_output.text = out if out != "" else "（沒有印出任何東西）"
		_output.add_theme_color_override("font_color", Color("#e6edf3"))
	else:
		_output.text = ErrorExplainer.explain(result.get("error", {}), _code)
		_output.add_theme_color_override("font_color", Color("#ffb4a8"))
