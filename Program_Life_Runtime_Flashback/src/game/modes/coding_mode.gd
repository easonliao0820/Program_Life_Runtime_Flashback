extends Control

## 程式關卡模式（畫面設定書 2.2，版面沿用舊版 section_1 的四象限）——劇本裡每個 @level 都會切到這裡。
## 劇情為主：左上的「劇情區」由 GameStage 保留（場景縮小＋對話框），派森的提示、錯誤解說、
## 過關台詞都透過 speak 說在對話框裡，劇情不會因為進入關卡而中斷。
##   左下：物件區——任務卡（價格、資料用「價格牌」標籤呈現）
##   右上：程式區——編輯器（深色、行號、語法上色），舊版電路板框
##   右下：輸出區——執行（綠）、提示（黃）、重置（灰）＋ print 的結果，舊版電路板框
##   上方：這一節有幾關、目前第幾關、錯誤次數（用於結局判定）

signal _continue_pressed

const CODE_FRAME := "res://chapters/chapter_1/images/code_bg.png"
const OUTPUT_FRAME := "res://chapters/chapter_1/images/codeoutput_bg.png"
const RUN_ICON := "res://src/ui/coding_panel/run.png"

## GameStage 提供：func(text: String, mood: String) —— 讓派森在劇情區的對話框裡說話
var speak: Callable

var _progress: Label
var _task_panel: PanelContainer
var _task_title: Label
var _task_goal: RichTextLabel
var _tags: HFlowContainer
var _code_panel: PanelContainer
var _editor: CodeEdit
var _out_panel: PanelContainer
var _output: RichTextLabel
var _flash: ColorRect
var _run_btn: Button
var _hint_btn: Button
var _reset_btn: Button
var _next_btn: Button
var _skip_btn: Button

var _level: Dictionary = {}
var _ctx: Dictionary = {}
var _starter: String = ""
var _errors: int = 0
var _hint_used: bool = false
var _hint_index: int = 0
var _attempt: int = 0
var _passed: bool = false
var _memory_theme: bool = false
var _last_said: String = ""


func _ready() -> void:
	UIKit.full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# ---------- 上方進度（右上，系統選單左邊） ----------
	var pill := PanelContainer.new()
	pill.add_theme_stylebox_override("panel", UIKit.navy_panel(10, 10))
	pill.position = Vector2(UIKit.SPLIT_CODE.position.x, 24)
	pill.custom_minimum_size = Vector2(560, 56)
	add_child(pill)
	_progress = UIKit.label("", 24, UIKit.GOLD)
	_progress.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pill.add_child(_progress)

	# ---------- 左下：物件區（任務卡） ----------
	_task_panel = PanelContainer.new()
	_task_panel.position = UIKit.SPLIT_OBJECT.position
	_task_panel.size = UIKit.SPLIT_OBJECT.size
	_task_panel.add_theme_stylebox_override("panel", UIKit.navy_panel(10, 18))
	add_child(_task_panel)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UIKit.box(UIKit.CREAM, 6, UIKit.GOLD, 2, 22))
	_task_panel.add_child(card)
	var card_v := VBoxContainer.new()
	card_v.add_theme_constant_override("separation", 12)
	card.add_child(card_v)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	card_v.add_child(head)
	var badge := PanelContainer.new()
	badge.add_theme_stylebox_override("panel", UIKit.name_plate(UIKit.MRT_BLUE))
	badge.add_child(UIKit.label("任務", 22, Color.WHITE))
	head.add_child(badge)
	_task_title = UIKit.label("", 30, UIKit.INK)
	_task_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(_task_title)
	_task_goal = UIKit.rich(24, UIKit.INK)
	card_v.add_child(_task_goal)
	_tags = HFlowContainer.new()
	_tags.add_theme_constant_override("h_separation", 12)
	_tags.add_theme_constant_override("v_separation", 12)
	card_v.add_child(_tags)

	# ---------- 右上：程式區 ----------
	_code_panel = PanelContainer.new()
	_code_panel.position = UIKit.SPLIT_CODE.position
	_code_panel.size = UIKit.SPLIT_CODE.size
	_code_panel.add_theme_stylebox_override("panel", UIKit.texture_box(CODE_FRAME, 28, 30))
	add_child(_code_panel)
	_editor = UIKit.code_editor()
	_code_panel.add_child(_editor)

	# ---------- 右下：輸出區 ----------
	_out_panel = PanelContainer.new()
	_out_panel.position = UIKit.SPLIT_FEEDBACK.position
	_out_panel.size = UIKit.SPLIT_FEEDBACK.size
	_out_panel.add_theme_stylebox_override("panel", UIKit.texture_box(OUTPUT_FRAME, 64, 58))
	add_child(_out_panel)
	var out_v := VBoxContainer.new()
	out_v.add_theme_constant_override("separation", 10)
	_out_panel.add_child(out_v)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)
	out_v.add_child(buttons)
	_run_btn = UIKit.button("執行", UIKit.RUN_GREEN)
	if ResourceLoader.exists(RUN_ICON):
		_run_btn.icon = load(RUN_ICON)
		_run_btn.expand_icon = true
	_hint_btn = UIKit.button("提示", UIKit.HINT_YELLOW, UIKit.INK)
	_reset_btn = UIKit.button("重置", UIKit.RESET_GRAY)
	_skip_btn = UIKit.button("略過（開發用）", Color(0.3, 0.3, 0.35), Color.WHITE, UIKit.SMALL_SIZE)
	_next_btn = UIKit.button("繼續 ▶", UIKit.MRT_BLUE)
	for b in [_run_btn, _hint_btn, _reset_btn]:
		b.custom_minimum_size = Vector2(140, 56)
		buttons.add_child(b)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(sp)
	buttons.add_child(_skip_btn)
	_next_btn.custom_minimum_size = Vector2(170, 56)
	buttons.add_child(_next_btn)
	_run_btn.pressed.connect(_on_run)
	_hint_btn.pressed.connect(_on_hint)
	_reset_btn.pressed.connect(_on_reset)
	_next_btn.pressed.connect(func(): _continue_pressed.emit())
	_skip_btn.pressed.connect(_on_skip)

	var out_bg := PanelContainer.new()
	out_bg.size_flags_vertical = Control.SIZE_EXPAND_FILL
	out_bg.add_theme_stylebox_override("panel", UIKit.box(Color(0.06, 0.05, 0.04, 0.82), 8, Color.TRANSPARENT, 0, 14))
	out_v.add_child(out_bg)
	var out_scroll := ScrollContainer.new()
	out_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	out_bg.add_child(out_scroll)
	_output = UIKit.rich(UIKit.CODE_SIZE, Color("#f3e6c8"))
	_output.add_theme_font_override("normal_font", UIKit.mono_font())
	_output.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	out_scroll.add_child(_output)
	_flash = ColorRect.new()
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.color = Color(UIKit.PY_YELLOW, 0.0)
	out_bg.add_child(_flash)

	visible = false


## ctx：{"index": 第幾關, "total": 這一節幾關, "chapter": 章節名, "theme": "memory"}
func play_level(level: Dictionary, ctx: Dictionary) -> Dictionary:
	_level = level
	_ctx = ctx
	_errors = 0
	_hint_used = false
	_hint_index = 0
	_attempt = 0
	_passed = false
	_memory_theme = ctx.get("theme", level.get("theme", "default")) == "memory"
	var editor_bg := Color(0.05, 0.09, 0.22, 0.9) if _memory_theme else Color(0.07, 0.1, 0.14, 0.88)
	_editor.add_theme_stylebox_override("normal", UIKit.box(editor_bg, 8, Color.TRANSPARENT, 0, 14))
	_update_progress()

	_task_title.text = GameState.format_text(str(level.get("title", "")))
	_task_goal.text = GameState.format_text(str(level.get("goal", "")))
	for c in _tags.get_children():
		c.queue_free()
	for tag in level.get("tags", []):
		_tags.add_child(_make_tag(GameState.format_text(str(tag))))

	_starter = fill_code(str(level.get("starter", "")))
	_editor.text = _starter
	_output.text = "[color=#a89c86]按「執行」看看結果。[/color]"
	var intro := GameState.format_text(str(level.get("intro", "")))
	if intro != "":
		_say(intro, "idle")
	_run_btn.disabled = false
	_hint_btn.disabled = false
	_reset_btn.disabled = false
	_next_btn.visible = false
	_skip_btn.visible = OS.is_debug_build()

	visible = true
	modulate.a = 0.0
	UIKit.fade(self, 1.0, 0.3)
	_editor.grab_focus()
	if GameFlow.autopilot:
		_autopilot.call_deferred()

	await _continue_pressed

	var t := UIKit.fade(self, 0.0, 0.25)
	await t.finished
	visible = false
	return {"passed": _passed, "first_try": _passed and _errors == 0 and not _hint_used,
		"errors": _errors, "hint_used": _hint_used}


## 給「跟派森聊天」用：目前的關卡題目與玩家的程式
func current_info() -> Dictionary:
	if not visible:
		return {}
	return {"title": GameState.format_text(str(_level.get("title", ""))),
		"goal": GameState.format_text(str(_level.get("goal", ""))), "code": _editor.text, "passed": _passed}


## 程式碼樣板：{userName} 換成名字、<<變數>> 換成劇本變數（例如探索模式產生的程式碼）。
## 不用 {變數} 是因為 Python 的 f-string 也用大括號。
static func fill_code(code: String) -> String:
	var out := code.replace("{userName}", GameState.user_name)
	var rx := RegEx.new()
	rx.compile("<<([A-Za-z_][A-Za-z0-9_]*)>>")
	for m in rx.search_all(code):
		var v = GameState.get_value(m.get_string(1), "")
		out = out.replace(m.get_string(0), str(v))
	return out


func _update_progress() -> void:
	var total := int(_ctx.get("total", 1))
	var index := int(_ctx.get("index", 1))
	var dots := ""
	for i in total:
		dots += "●" if i < index else "○"
	var head := str(_ctx.get("chapter", ""))
	if total > 0:
		head += "　關卡 %d/%d %s" % [index, total, dots]
	_progress.text = "%s　｜　錯誤 %d%s" % [head, _errors, "（用過提示）" if _hint_used else ""]


func _make_tag(text: String) -> Control:
	# 像便利商店的價格牌：黃底、左邊一條紅邊
	var p := PanelContainer.new()
	var sb := UIKit.box(Color("#ffe37a"), 6, Color("#d9534f"), 0, 10)
	sb.border_width_left = 8
	sb.border_color = Color("#d9534f")
	p.add_theme_stylebox_override("panel", sb)
	var l := UIKit.label(text, 24, Color("#3b2a05"))
	l.add_theme_font_override("font", UIKit.mono_font())
	p.add_child(l)
	return p


## 派森說話：交給 GameStage 顯示在劇情區的對話框（劇情不中斷）
func _say(text: String, mood: String) -> void:
	_last_said = text
	if speak.is_valid():
		speak.call(text, mood)


func _on_run() -> void:
	if _passed:
		return
	_attempt += 1
	var attempt := _attempt
	var code := _editor.text
	_run_btn.disabled = true
	_output.text = "[color=#a89c86]執行中……[/color]"
	var result: Dictionary = await PythonRunner.run(code, fill_code(str(_level.get("check", ""))), _level.get("stdin", []))
	_run_btn.disabled = false
	var stdout := _escape(str(result.get("stdout", "")))

	if not result.get("ok", false):
		_errors += 1
		_update_progress()
		var err: Dictionary = result.get("error", {})
		var plain := ErrorExplainer.explain(err, code)
		_output.text = stdout + "[color=#ff8f80]（程式在這裡停下來了）[/color]"
		if int(err.get("line", 0)) > 0:
			_editor.set_caret_line(int(err["line"]) - 1)
		_say(plain, "worried")
		# AI 開啟時，讓派森用自己的話再說一次；回來時如果玩家已經又按了執行，就不覆蓋
		var ai_line: String = await AiBridge.ask(ErrorExplainer.ai_prompt(err, code, plain), plain, 8.0)
		if attempt == _attempt and not _passed and ai_line != plain:
			_say(ai_line, "worried")
		return

	if result.get("passed", false) != true:
		_errors += 1
		_update_progress()
		_output.text = stdout if stdout != "" else "[color=#a89c86]（沒有印出任何東西）[/color]"
		var msg: String = str(result.get("message", ""))
		_say(msg if msg != "" else "程式可以跑了，但結果還不太對，再看一次任務卡吧。", "worried")
		return

	# ---------- 成功 ----------
	_passed = true
	_output.text = stdout if stdout != "" else "[color=#a89c86]（沒有印出任何東西）[/color]"
	_flash_success()
	var flags: Dictionary = result.get("flags", {})
	for k in flags:
		GameState.set_value(k, flags[k])
	GameState.set_value("last_output", str(result.get("stdout", "")).strip_edges())
	GameState.set_value("last_code", code)
	var success_text := GameState.format_text(str(_level.get("success", "")))
	_say(success_text if success_text != "" else ("第一次就成功了！" if _errors == 0 and not _hint_used else "成功了！"), "happy")
	_run_btn.disabled = true
	_hint_btn.disabled = true
	_reset_btn.disabled = true
	_skip_btn.visible = false
	_next_btn.visible = true


func _on_hint() -> void:
	var hints: Array = _level.get("hints", [])
	_hint_used = true
	_update_progress()
	if hints.is_empty():
		_say("再讀一次任務卡上的說明，一行一行對照看看。", "wise")
		return
	_say(GameState.format_text(str(hints[mini(_hint_index, hints.size() - 1)])), "wise")
	_hint_index += 1


func _on_reset() -> void:
	_editor.text = _starter
	_output.text = ""
	_say("回到一開始的樣子了。", "idle")


## 開發用：沒有 Python 時也能把流程走完（不算第一次就通過）
func _on_skip() -> void:
	_passed = true
	_hint_used = true
	var solution := str(_level.get("solution", ""))
	if solution != "":
		_editor.text = fill_code(solution)
	_continue_pressed.emit()


## 自動駕駛：用 solution 跑一次，確認每一關的參考解答真的能過關
func _autopilot() -> void:
	await get_tree().create_timer(0.1).timeout
	_editor.text = fill_code(str(_level.get("solution", "")))
	await _on_run()
	if _passed:
		print("[autopilot] ✔ ", _level.get("id", ""))
		_continue_pressed.emit()
	else:
		push_error("[autopilot] ✘ %s：%s" % [_level.get("id", ""), _last_said])
		_on_skip()


func _flash_success() -> void:
	_flash.size = _flash.get_parent().size
	var t := create_tween()
	t.tween_property(_flash, "color", Color(UIKit.PY_BLUE, 0.45), 0.12)
	t.tween_property(_flash, "color", Color(UIKit.PY_YELLOW, 0.4), 0.18)
	t.tween_property(_flash, "color", Color(UIKit.PY_YELLOW, 0.0), 0.5)


func _escape(t: String) -> String:
	return t.replace("[", "[lb]")
