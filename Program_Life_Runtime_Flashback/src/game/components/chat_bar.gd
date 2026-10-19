extends Control

## 跟角色聊天的輸入框（延續舊版第一～三章的聊天框）：第一章第一關過了之後解鎖。
## 只在程式關卡、探索模式時出現在左上的劇情區；劇情模式不顯示（由 GameStage._refresh_chat 控制）。
## 主角視角：可以選擇跟「派森」或這一節出現過的角色（媽媽、倖芳、翊丞……）說話，
## 每個角色用自己的個性與口吻回答。
## - 回答顯示在畫面上方的泡泡裡（名字牌用角色代表色），不會蓋掉正在讀的劇情台詞
## - 對話會記住：每個角色聊過的話存進存檔（GameState.chat_history），下次問的時候帶給 AI，角色會記得；
##   問答也記進「回顧」
## - 在程式關卡中，派森看得到題目與玩家的程式（只給提示、不給答案）
## - AI 關閉或沒有金鑰時，泡泡會說明原因，不會卡住
## GameStage 提供：context（目前情境）、targets（可以說話的對象）、persona（角色人設）、record（記進回顧）。

signal asked(target: String, question: String)

const FULL_BAR := Rect2(360, 726, 1140, 52)
const SPLIT_BAR := Rect2(36, 540, 748, 52)
const FULL_BUBBLE := Rect2(340, 150, 760, 0)
const SPLIT_BUBBLE := Rect2(40, 150, 640, 0)
## 帶給 AI 的「之前聊過的話」最多幾筆
const MEMORY_IN_PROMPT := 6

var context: Callable   ## func() -> String
var targets: Callable   ## func() -> Array
var persona: Callable   ## func(name: String) -> String
var record: Callable    ## func(speaker: String, text: String)

var target: String = "派森"

var _bar: PanelContainer
var _target_btn: Button
var _input: LineEdit
var _send: Button
var _bubble: PanelContainer
var _bubble_name: Label
var _bubble_text: RichTextLabel
var _busy: bool = false
var _hide_timer: SceneTreeTimer
var _split: bool = false


func _ready() -> void:
	UIKit.full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_bar = PanelContainer.new()
	_bar.add_theme_stylebox_override("panel", UIKit.navy_panel(10, 6))
	add_child(_bar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_bar.add_child(row)
	# 對象：點一下換下一個可以說話的人
	_target_btn = UIKit.button("", UIKit.MRT_BLUE, Color.WHITE, 20)
	_target_btn.custom_minimum_size = Vector2(150, 40)
	_target_btn.tooltip_text = "點一下換說話的對象"
	_target_btn.pressed.connect(_next_target)
	row.add_child(_target_btn)
	_input = LineEdit.new()
	_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_input.max_length = 120
	_input.add_theme_font_override("font", UIKit.body_font())
	_input.add_theme_font_size_override("font_size", 22)
	_input.add_theme_color_override("font_color", UIKit.TEXT_LIGHT)
	_input.add_theme_color_override("font_placeholder_color", Color(1, 1, 1, 0.35))
	_input.add_theme_color_override("caret_color", UIKit.GOLD)
	_input.add_theme_stylebox_override("normal", UIKit.box(Color(0, 0, 0, 0.25), 6, Color.TRANSPARENT, 0, 8))
	_input.add_theme_stylebox_override("focus", UIKit.box(Color(0, 0, 0, 0.35), 6, UIKit.GOLD, 2, 8))
	_input.text_submitted.connect(func(_t: String): _on_send())
	_input.focus_entered.connect(_sync_targets)
	row.add_child(_input)
	_send = UIKit.button("送出", UIKit.MRT_BLUE, Color.WHITE, 20)
	_send.custom_minimum_size = Vector2(90, 40)
	_send.pressed.connect(_on_send)
	row.add_child(_send)

	_bubble = PanelContainer.new()
	_bubble.mouse_filter = Control.MOUSE_FILTER_STOP
	_bubble.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed:
			_hide_bubble())
	add_child(_bubble)
	var bv := VBoxContainer.new()
	bv.add_theme_constant_override("separation", 6)
	_bubble.add_child(bv)
	_bubble_name = UIKit.label("", 22, UIKit.GOLD)
	bv.add_child(_bubble_name)
	_bubble_text = UIKit.rich(24, UIKit.TEXT_LIGHT)
	bv.add_child(_bubble_text)
	var hint := UIKit.label("（點一下泡泡收起來）", 16, Color(1, 1, 1, 0.4))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	bv.add_child(hint)
	_bubble.visible = false

	_update_target_label()
	set_split(false)


func set_split(on: bool) -> void:
	_split = on
	var r := SPLIT_BAR if on else FULL_BAR
	# 先改最小尺寸再改大小，否則會被舊的最小尺寸撐住
	_bar.custom_minimum_size = r.size
	_bar.position = r.position
	_bar.size = r.size
	var b := SPLIT_BUBBLE if on else FULL_BUBBLE
	_bubble.custom_minimum_size = Vector2(b.size.x, 0)
	_bubble_text.custom_minimum_size = Vector2(b.size.x - 36, 0)
	_bubble.position = b.position
	_bubble.size = Vector2(b.size.x, 0)


func set_bar_visible(on: bool) -> void:
	_bar.visible = on
	if not on:
		_input.release_focus()
	else:
		_sync_targets()


# ------------------------------------------------------------------
# 說話的對象
# ------------------------------------------------------------------

func _available() -> Array:
	var list: Array = targets.call() if targets.is_valid() else ["派森"]
	if not list.has("派森"):
		list.push_front("派森")
	return list


## 換節或角色離場後，原本的對象不在了就回到派森
func _sync_targets() -> void:
	if not _available().has(target):
		target = "派森"
	_update_target_label()


func _next_target() -> void:
	var list := _available()
	var i := list.find(target)
	target = list[(i + 1) % list.size()]
	_update_target_label()
	_input.grab_focus()


func _update_target_label() -> void:
	_target_btn.text = "對：%s ▸" % target
	_input.placeholder_text = "想跟%s說什麼？（Enter 送出）" % target
	var plate := UIKit.box(UIKit.MRT_BLUE, 8, ChapterRegistry.character_color(target), 3, 8)
	if target == "派森":
		plate.border_color = UIKit.PY_YELLOW
	_target_btn.add_theme_stylebox_override("normal", plate)


# ------------------------------------------------------------------
# 送出與回答
# ------------------------------------------------------------------

func _on_send() -> void:
	var q := _input.text.strip_edges()
	if q == "" or _busy:
		return
	var who := target
	_input.text = ""
	_input.release_focus()
	_busy = true
	_send.disabled = true
	if record.is_valid():
		record.call("你", "（對%s）%s" % [who, q] if who != "派森" else q)
	asked.emit(who, q)
	_show_bubble(who, "[color=#8b98a5]……[/color]", false)

	var ctx: String = context.call() if context.is_valid() else ""
	var answer: String = await AiBridge.ask(_prompt(who, q, ctx), _fallback_reason(who), 12.0)
	answer = answer.trim_prefix(who + "：").trim_prefix(who + ":").strip_edges()
	_busy = false
	_send.disabled = false
	_show_bubble(who, answer, true)
	if record.is_valid():
		record.call(who, answer)
	# 記住這段對話（AI 沒回應時的系統說明不記）
	if not (answer.begins_with("（") and answer.ends_with("）")):
		GameState.remember_chat(who, q, answer)


## AI 沒辦法回答時，讓玩家知道為什麼（不是角色不理你）
func _fallback_reason(who: String) -> String:
	if not GameState.settings.get("ai_enabled", true):
		return "（%s好像沒聽見。即時回應目前是關閉的，可以在「設定」裡打開「使用 AI 即時回應」。）" % who
	if AiBridge.api_key == "" or AiBridge.api_url == "":
		return "（%s好像沒聽見。專案的 .env 還沒有設定 API_KEY，所以角色現在沒辦法即時回答。）" % who
	return "（%s好像沒聽清楚，訊號有點不穩。等一下再說一次吧。）" % who


func _prompt(who: String, question: String, ctx: String) -> String:
	var me := GameState.user_name if GameState.user_name != "" else "主角"
	var who_desc: String = persona.call(who) if persona.is_valid() else "你是遊戲裡的角色「%s」。" % who
	var memory := ""
	var past: Array = GameState.chat_history.get(who, [])
	if not past.is_empty():
		var lines: Array = []
		for i in range(maxi(0, past.size() - MEMORY_IN_PROMPT), past.size()):
			lines.append("%s：%s\n%s：%s" % [me, past[i]["q"], who, past[i]["a"]])
		memory = "\n【你們之前聊過的話（請記得，必要時接著聊）】\n" + "\n".join(lines) + "\n"
	var rules := """1. 繁體中文、80 字以內、不要用表情符號、不要加名字前綴，完全用「%s」的口吻與身分說話。
2. 只聊遊戲裡的故事、主角的人生、Python 與程式；被問到現實新聞、政治、色情、暴力或與遊戲無關的事，用角色的方式自然地把話題帶回來。
3. 不要說自己是 AI、Gemini 或語言模型。
4. 配合主角現在的年紀與這一段的劇情，不要提到還沒發生的事。""" % who
	if who == "派森":
		rules += "\n5. 如果主角正在解關卡，只給方向和提示，不要直接寫出完整答案的程式碼。"
	else:
		rules += "\n5. 你不知道派森的存在（只有主角看得見派森），也不太懂程式，除非你的角色本來就會。"
	return """%s
主角的名字是「%s」。

【目前情境】
%s
%s
【規則】
%s

主角對你說：%s""" % [who_desc, me, ctx, memory, rules, question]


func _show_bubble(who: String, text: String, auto_hide: bool) -> void:
	_bubble_name.text = who
	var sb := UIKit.navy_panel(14, 18)
	sb.border_color = UIKit.PY_YELLOW if who == "派森" else ChapterRegistry.character_color(who)
	sb.set_border_width_all(3)
	_bubble.add_theme_stylebox_override("panel", sb)
	_bubble_text.text = text
	_bubble.visible = true
	_bubble.modulate.a = 0.0
	# 文字換行後才知道高度：等一格再縮回剛好的大小
	await get_tree().process_frame
	_bubble.reset_size()
	UIKit.fade(_bubble, 1.0, 0.2)
	if auto_hide:
		var t := get_tree().create_timer(14.0)
		_hide_timer = t
		t.timeout.connect(func():
			if _hide_timer == t:
				_hide_bubble())


func hide_bubble() -> void:
	_hide_bubble()


func _hide_bubble() -> void:
	_hide_timer = null
	_bubble.visible = false
