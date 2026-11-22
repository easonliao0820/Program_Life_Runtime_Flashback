extends PanelContainer

## 劇情中的程式碼卡片：劇本裡的 ``` 程式碼 ``` 會顯示在這裡。
## 可以按「▶ 執行看看」實際跑一次，看看印出什麼（不計分）。
## 卡片會一直留在畫面上，讓後面的對話可以解說這段程式，直到下一張卡片、關卡或換場景。

var _editor: CodeEdit
var _output: Label
var _run_btn: Button
var _code: String = ""
var _row: HBoxContainer

## 卡片的上下界（1920×1080）：上面避開右上角的按鈕列，下面不能蓋到對話框和名字牌
## （對話框在 dialogue_box.gd 的 FULL_RECT，y = 790；名字牌再往上凸出一點）。
const TOP := 100.0
const BOTTOM := 744.0
const MIN_CODE_SIZE := 18  # 再小就不好讀了，放不下改用捲動


func _ready() -> void:
	add_theme_stylebox_override("panel", UIKit.navy_panel(10, 18))
	anchor_left = 0.5
	anchor_right = 0.5
	offset_left = -560
	offset_right = 560
	offset_top = TOP
	mouse_filter = Control.MOUSE_FILTER_STOP
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	add_child(v)

	_editor = UIKit.code_editor(false, false)
	_editor.custom_minimum_size = Vector2(1080, 0)
	v.add_child(_editor)

	var row := HBoxContainer.new()
	_row = row
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
	_fit()
	visible = true
	modulate.a = 0.0
	UIKit.fade(self, 1.0, 0.25)


## 解說模式：把第 line 行（從 1 開始）亮起來，其他行恢復；line <= 0 全部恢復
func highlight_line(line: int) -> void:
	for i in _editor.get_line_count():
		_editor.set_line_background_color(i, Color(0, 0, 0, 0))
	if line >= 1 and line <= _editor.get_line_count():
		_editor.set_line_background_color(line - 1, Color(UIKit.PY_YELLOW, 0.22))
		if not _editor.scroll_fit_content_height:
			_editor.set_line_as_center_visible(line - 1)  # 卡片在捲動時，把解說的那一行捲到中間


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
	_fit()  # 輸出可能有好幾行，重新算一次，卡片才不會往下長到對話框


## 程式太長時：先把字縮小（最小 MIN_CODE_SIZE），還放不下就固定高度、讓程式在卡片裡捲動，
## 卡片永遠不超過 BOTTOM，不會被對話框蓋住。
func _fit() -> void:
	var avail := BOTTOM - TOP - 36.0  # 卡片上下內距（navy_panel 18 × 2）
	if _row.visible and (_run_btn.visible or _output.text != ""):
		avail -= 10.0 + _row.get_combined_minimum_size().y  # 執行按鈕＋輸出那一列
	var lines := maxi(_editor.get_line_count(), 1)
	var pad := 28.0  # 程式區上下內距（code_editor 14 × 2）
	var fs := UIKit.CODE_SIZE
	_editor.add_theme_font_size_override("font_size", fs)
	while fs > MIN_CODE_SIZE and _editor.get_line_height() * lines + pad > avail:
		fs -= 1
		_editor.add_theme_font_size_override("font_size", fs)
	var fits := _editor.get_line_height() * lines + pad <= avail
	_editor.scroll_fit_content_height = fits
	_editor.custom_minimum_size.y = 0.0 if fits else avail
	size = Vector2(size.x, 0.0)  # 依新的內容重新算高度（變矮時才會縮回來）
