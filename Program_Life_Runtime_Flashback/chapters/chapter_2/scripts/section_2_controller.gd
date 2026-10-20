extends Node2D

@onready var code_edit: CodeEdit = $CanvasLayer/MainLayout/RightPanel/CodingArea/CodeEdit
@onready var output: Label = $CanvasLayer/MainLayout/RightPanel/FeedbackArea/OutputLabel
@onready var button: Button = $CanvasLayer/MainLayout/RightPanel/FeedbackArea/RunButton
@onready var story_box = $CanvasLayer/StoryBox

@onready var left_panel = $CanvasLayer/MainLayout/LeftPanel
@onready var right_panel = $CanvasLayer/MainLayout/RightPanel
@onready var object_area = $CanvasLayer/MainLayout/LeftPanel/ObjectArea

@onready var chat_input: LineEdit = $CanvasLayer/MainLayout/LeftPanel/ObjectArea/HBoxContainer/LineEdit
@onready var chat_send_button: Button = $CanvasLayer/MainLayout/LeftPanel/ObjectArea/HBoxContainer/Button
@onready var chat_container: HBoxContainer = $CanvasLayer/MainLayout/LeftPanel/ObjectArea/HBoxContainer

var chapter_buttons = null
var textbook_panel: Control = null
var textbook_close_button: Button = null
var textbook_mask: ColorRect = null

# 本章的完整流程：2.1 記憶變數 -> 2.2 早餐店 -> 2.3 便利商店。
# 依序播放，播完一段就自動接下一段；WAIT_FOR_SANDBOX 的段落會在玩家 Run 成功後
# 透過 story_box.sandbox_resolved() -> story_finished 訊號自然接回這條流程。
var _phases := [
	"res://chapters/chapter_2/data/ch2_1_greet.tres",
	"res://chapters/chapter_2/data/ch2_1_memory.tres",
	"res://chapters/chapter_2/data/ch2_1_success.tres",
	"res://chapters/chapter_2/data/ch2_1_hunt.tres",
	"res://chapters/chapter_2/data/ch2_2_intro.tres",
	"res://chapters/chapter_2/data/ch2_2_teach.tres",
	"res://chapters/chapter_2/data/ch2_2_success.tres",
	"res://chapters/chapter_2/data/ch2_3_intro.tres",
	"res://chapters/chapter_2/data/ch2_3_game.tres",
	"res://chapters/chapter_2/data/ch2_3_success.tres",
]
# 這幾個 phase 播完後，不直接接下一段 tres，而是先插入動態內容（AI 回覆／選擇按鈕）。
var _after_hooks := {
	0: "_after_greet",
	4: "_after_shop_intro",
	9: "_after_mart_success",
}
var _phase_index: int = -1
var _last_sandbox_result: String = ""
var _pending_ai_context: String = ""
var _chosen_breakfast: String = ""
var _is_waiting_for_chat: bool = false
# 標記目前顯示的是動態組出來的對話（AI 回覆），而不是章節流程裡的正式一段，
# 避免它播完時被誤判成某個 phase 播完，重複觸發該 phase 的 after-hook。
var _showing_dynamic: bool = false

func _ready() -> void:
	print("GDScript READY OK - CHAPTER 2")

	if AiBridge:
		if not AiBridge.ai_response_received.is_connected(_on_ai_response):
			AiBridge.ai_response_received.connect(_on_ai_response)

	chapter_buttons = get_node_or_null("CanvasLayer/MainLayout/LeftPanel/ObjectArea/ChapterButtons")
	textbook_panel = get_node_or_null("TextbookLayer/TextbookPanel")
	textbook_close_button = get_node_or_null("TextbookLayer/TextbookPanel/WindowContainer/MarginContainer/VBox/Header/CloseButton")
	textbook_mask = get_node_or_null("TextbookLayer/TextbookPanel/BackgroundMask")

	right_panel.hide()
	object_area.hide()
	chat_container.hide()

	button.pressed.connect(_on_run_pressed)
	chat_send_button.pressed.connect(_on_chat_send_pressed)
	chat_input.text_submitted.connect(_on_chat_text_submitted)

	if chapter_buttons:
		if not chapter_buttons.next_chapter_pressed.is_connected(_on_next_chapter_pressed):
			chapter_buttons.next_chapter_pressed.connect(_on_next_chapter_pressed)
		if not chapter_buttons.textbook_pressed.is_connected(_on_textbook_pressed):
			chapter_buttons.textbook_pressed.connect(_on_textbook_pressed)

	if textbook_close_button:
		textbook_close_button.pressed.connect(_on_textbook_close_pressed)
	if textbook_mask:
		textbook_mask.gui_input.connect(_on_textbook_mask_gui_input)

	if story_box:
		if not story_box.story_finished.is_connected(_on_story_finished):
			story_box.story_finished.connect(_on_story_finished)
		if not story_box.sandbox_waiting.is_connected(_on_sandbox_waiting):
			story_box.sandbox_waiting.connect(_on_sandbox_waiting)

		_phase_index = 0
		story_box.start_story(load(_phases[_phase_index]))

## 第一段劇情播完後才展開四象限版面；之後每段都只是換 story_box 的內容，版面維持展開。
var _layout_expanded: bool = false

func _on_story_finished() -> void:
	if not _layout_expanded:
		_layout_expanded = true
		await _expand_layout()

	if _showing_dynamic:
		_showing_dynamic = false
		_advance_phase()
		return

	var hook = _after_hooks.get(_phase_index, "")
	if hook != "":
		call(hook)
	else:
		_advance_phase()

func _expand_layout() -> void:
	right_panel.show()
	object_area.show()
	if chapter_buttons:
		chapter_buttons.hide_textbook()
	right_panel.size_flags_stretch_ratio = 0.01
	object_area.size_flags_stretch_ratio = 0.01
	right_panel.modulate.a = 0
	object_area.modulate.a = 0

	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(right_panel, "size_flags_stretch_ratio", 3.0, 1.5)
	tween.tween_property(object_area, "size_flags_stretch_ratio", 1.0, 1.5)
	tween.tween_property(right_panel, "modulate:a", 1.0, 1.0)
	tween.tween_property(object_area, "modulate:a", 1.0, 1.0)

	await tween.finished
	if story_box:
		story_box.reposition_to_top_right()

func _advance_phase() -> void:
	_phase_index += 1
	if _phase_index >= _phases.size():
		return
	if story_box:
		story_box.start_story(load(_phases[_phase_index]))

## ---------------------------------------------------------------------
## 動態插入內容的 hook：2.1 開場感想後，讓 AI 針對玩家輸入即時回應。
## ---------------------------------------------------------------------
func _after_greet() -> void:
	_pending_ai_context = "greet_reaction"
	_show_ai_thinking()

	var prompt = """
你是遊戲中的 AI 導師「派森」。玩家剛剛用 print() 說出了他此刻的感想：「%s」

請針對這句感想給出溫柔、神秘、富有哲理的回應，並自然地帶到「爸媽在這段時間給予的愛」這個話題，
引導玩家開始回憶起小時候的溫馨片段。嚴格限制在 60 字內，使用繁體中文，不使用表情符號，
絕對不得透露自己是 Gemini、AI 模型或文字機器人。
""" % _last_sandbox_result

	if AiBridge:
		AiBridge.call_openai(prompt)

## 2.2 早餐店開場後，讓玩家從幾樣早餐裡選一個（動態產生按鈕，不需要場景先放節點）。
func _after_shop_intro() -> void:
	var choices = [
		{"label": "培根蛋吐司＋中冰奶　$60", "value": "培根蛋吐司", "price": 60},
		{"label": "蔬菜蛋餅＋豆漿　$45", "value": "蔬菜蛋餅", "price": 45},
		{"label": "總匯三明治＋紅茶　$70", "value": "總匯三明治", "price": 70},
	]
	var row = HBoxContainer.new()
	row.name = "BreakfastChoiceRow"
	for c in choices:
		var btn = Button.new()
		btn.text = c["label"]
		btn.pressed.connect(func():
			_chosen_breakfast = "%s（$%d）" % [c["value"], c["price"]]
			output.text = "你點了：" + _chosen_breakfast
			row.queue_free()
			_advance_phase()
		)
		row.add_child(btn)
	object_area.add_child(row)

## 2.3 收尾後解鎖聊天、顯示下一章按鈕（章節到此結束）。
func _after_mart_success() -> void:
	if chapter_buttons:
		chapter_buttons.show_next_chapter()
	chat_container.show()

func _show_ai_thinking() -> void:
	if story_box:
		var waiting_data = DialogueData.new()
		var step = DialogueStep.new()
		step.speaker = "派森"
		step.line = "思考中..."
		waiting_data.dialogue_sequence.append(step)
		story_box.start_story(waiting_data)
		story_box.is_waiting_for_ai = true

func _on_run_pressed() -> void:
	get_viewport().gui_release_focus()
	print("RUN BUTTON PRESSED - CHAPTER 2, phase ", _phase_index)

	if not story_box.is_waiting_for_sandbox:
		output.text = "請先完成劇情閱讀~"
		return

	var code = code_edit.text
	print("執行程式碼: ", code)

	button.disabled = true

	var sm = get_node_or_null("/root/SandboxManager")
	var result = ""
	if sm:
		result = sm.run_code(code)
	else:
		result = SandboxManager.run_code(code)

	print("執行結果: ", result)
	output.text = result

	if result.begins_with("❌"):
		print("進行AI轉譯")
		output.text = "「語之觀測者」正在窺探程式裂縫..."
		AiBridge.translate_error(result, code)
		button.disabled = false
		return

	_last_sandbox_result = result
	output.text = result + "\n\n✨ 系統：記憶已成功寫入變數！"
	button.disabled = false
	if story_box:
		story_box.sandbox_resolved()

func _on_chat_send_pressed() -> void:
	_send_chat_message(chat_input.text)

func _on_chat_text_submitted(new_text: String) -> void:
	_send_chat_message(new_text)

func _send_chat_message(message: String) -> void:
	if message.strip_edges() == "":
		return

	chat_input.text = ""
	chat_input.editable = false
	chat_send_button.disabled = true

	_is_waiting_for_chat = true
	_pending_ai_context = "free_chat"
	_show_ai_thinking()

	var prompt = """
你是遊戲中的 AI 導師「派森」，目前正在引導【第二章 便利商店關卡結束後】的玩家自由對話。

【人格與絕對規則】
1. 你的名字永遠是「派森」，說話溫柔、神秘、富有哲理。
2. 絕對不得透露自己是 Gemini、AI 模型或文字機器人。
3. 嚴格限制在 60 字內，使用繁體中文，不使用表情符號。

如果玩家輸入髒話、色情、政治、現實敏感議題或完全無關的話題，溫柔地把話題拉回他剛經歷的成長回憶。

玩家說：
%s
""" % message

	if AiBridge:
		AiBridge.call_openai(prompt)

func _on_ai_response(text: String) -> void:
	print("AI 回應抵達，context=", _pending_ai_context, " text=", text)
	button.disabled = false

	match _pending_ai_context:
		"greet_reaction":
			_pending_ai_context = ""
			_showing_dynamic = true
			if story_box:
				story_box.is_waiting_for_ai = false
				var data = DialogueData.new()
				var step = DialogueStep.new()
				step.speaker = "派森"
				step.line = text
				data.dialogue_sequence.append(step)
				story_box.start_story(data)
		"free_chat":
			_pending_ai_context = ""
			_is_waiting_for_chat = false
			_showing_dynamic = true
			chat_input.editable = true
			chat_send_button.disabled = false
			if story_box:
				story_box.is_waiting_for_ai = false
				var data = DialogueData.new()
				var step = DialogueStep.new()
				step.speaker = "AI 導師 派森"
				step.line = text
				data.dialogue_sequence.append(step)
				story_box.start_story(data)
		_:
			output.text = text

func _on_next_chapter_pressed() -> void:
	get_tree().change_scene_to_file("res://chapters/chapter_3/scenes/section_1.tscn")

func _on_sandbox_waiting() -> void:
	if not _layout_expanded:
		_layout_expanded = true
		await _expand_layout()
	if chapter_buttons:
		chapter_buttons.show_textbook()

func _on_textbook_pressed() -> void:
	if textbook_panel:
		textbook_panel.show()

func _on_textbook_close_pressed() -> void:
	if textbook_panel:
		textbook_panel.hide()

func _on_textbook_mask_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_textbook_close_pressed()
