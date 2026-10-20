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

# 本章走向：3.1 捷運(list+分支) -> 3.2 學測100天(倖芳/夢想分支+倒數) -> 3.3 廟裡擲筊 -> 3.4 准考證檢查 -> 轉場大學
var _has_gift: bool = false
var _layout_expanded: bool = false
var _pending_ai_context: String = ""
var _is_waiting_for_chat: bool = false

# 3.3 擲筊小遊戲狀態
var _consecutive_holy: int = 0
var _divination_row: HBoxContainer = null

# 3.4 背包檢查小遊戲狀態
const REQUIRED_ITEMS = ["准考證", "身分證", "筆", "橡皮擦", "2B鉛筆"]
const CANDIDATE_ITEMS = ["准考證", "身分證", "筆", "橡皮擦", "2B鉛筆", "手機", "漫畫", "護照"]
var _my_bag: Array = []
var _bag_row: VBoxContainer = null

func _ready() -> void:
	print("GDScript READY OK - CHAPTER 3")

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

		_goto("3_1_intro")

## 用字串代表目前播放到哪一段，分支邏輯集中寫在 _on_story_finished 裡，
## 而不是像 chapter_2 那樣用線性陣列——因為這章有真正的劇情分岔。
var _step: String = ""

func _goto(step: String) -> void:
	_step = step
	var data = load("res://chapters/chapter_3/data/ch%s.tres" % step)
	if story_box:
		story_box.start_story(data)

func _on_story_finished() -> void:
	if not _layout_expanded:
		_layout_expanded = true
		await _expand_layout()

	match _step:
		"3_1_intro":
			_goto("3_1_branch_a" if _has_gift else "3_1_branch_b")
		"3_1_branch_a", "3_1_branch_b":
			_goto("3_2_intro")
		"3_2_intro":
			if _has_gift:
				_start_dream_prompt()
			else:
				_goto("3_2_for")
		"3_2_dream_response":
			_goto("3_2_pledge")
		"3_2_pledge":
			_goto("3_2_for")
		"3_2_for":
			_goto("3_3_intro")
		"3_3_intro":
			_start_divination()
		"3_3_success":
			_goto("3_4_intro")
		"3_4_intro":
			_start_backpack_check()
		"3_4_success":
			if chapter_buttons:
				chapter_buttons.show_next_chapter()
			chat_container.show()
		_:
			pass

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

## ---------------------------------------------------------------------
## 3.1 捷運：玩家在右側寫 bag = [] / bag.append(...)，
## 有沒有把「禮物」放進書包，決定接下來走哪個分支。
## ---------------------------------------------------------------------
func _on_run_pressed() -> void:
	get_viewport().gui_release_focus()
	print("RUN BUTTON PRESSED - CHAPTER 3, step ", _step)

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

	output.text = result

	if result.begins_with("❌"):
		output.text = "「語之觀測者」正在窺探程式裂縫..."
		AiBridge.translate_error(result, code)
		button.disabled = false
		return

	if _step == "3_1_intro":
		_has_gift = code.find("禮物") != -1

	output.text = result + "\n\n✨ 系統：這一段路，已經寫進你的劇本裡。"
	button.disabled = false
	if story_box:
		story_box.sandbox_resolved()

## ---------------------------------------------------------------------
## 3.2 夢想對話：借用聊天輸入框，讓玩家自由輸入夢想，AI 以倖芳的口吻回應
## （語氣感性或務實，交給 Gemini 依內容自行拿捏，而不是我們自己寫死關鍵字分類）。
## ---------------------------------------------------------------------
func _start_dream_prompt() -> void:
	_step = "3_2_dream_prompt"
	var data = load("res://chapters/chapter_3/data/ch3_2_dream_prompt.tres")
	story_box.start_story(data)
	chat_container.show()

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

	if _step == "3_2_dream_prompt":
		_pending_ai_context = "dream_response"
		_show_ai_thinking("倖芳")

		var prompt = """
你正在扮演遊戲中的角色「倖芳」，玩家的高中同學。她剛剛問了玩家的夢想是什麼，玩家的回答如下：
「%s」

請以倖芳的身分回應：
- 如果玩家的回答偏向感性／告白／想跟倖芳在一起，用嬌羞、心動又帶點調侃的語氣回應，並提議「這最後 100 天我們誰都不能放棄，要不要約好考上同一間大學？」
- 如果玩家的回答偏向實際／勵志／個人成就，用開朗、鼓勵的語氣回應，一樣自然地提議「要不要約好考上同一間大學？」
嚴格限制在 80 字內，使用繁體中文，不使用表情符號。
""" % message

		if AiBridge:
			AiBridge.call_openai(prompt)
	else:
		_is_waiting_for_chat = true
		_pending_ai_context = "free_chat"
		_show_ai_thinking("派森")

		var prompt = """
你是遊戲中的 AI 導師「派森」，目前正在引導【第三章 學測結束後】的玩家自由對話。
說話溫柔、神秘、富有哲理，絕對不得透露自己是 Gemini、AI 模型或文字機器人，嚴格限制在 60 字內，使用繁體中文，不使用表情符號。
如果玩家輸入髒話、色情、政治、現實敏感議題或完全無關的話題，溫柔地把話題拉回他這一路走來的成長。

玩家說：
%s
""" % message

		if AiBridge:
			AiBridge.call_openai(prompt)

func _show_ai_thinking(speaker: String) -> void:
	if story_box:
		var waiting_data = DialogueData.new()
		var step = DialogueStep.new()
		step.speaker = speaker
		step.line = "思考中..."
		waiting_data.dialogue_sequence.append(step)
		story_box.start_story(waiting_data)
		story_box.is_waiting_for_ai = true

func _on_ai_response(text: String) -> void:
	button.disabled = false
	chat_input.editable = true
	chat_send_button.disabled = false

	match _pending_ai_context:
		"dream_response":
			_pending_ai_context = ""
			chat_container.hide()
			_step = "3_2_dream_response"
			if story_box:
				story_box.is_waiting_for_ai = false
				var data = DialogueData.new()
				var step = DialogueStep.new()
				step.speaker = "倖芳"
				step.line = text
				data.dialogue_sequence.append(step)
				story_box.start_story(data)
		"free_chat":
			_pending_ai_context = ""
			_is_waiting_for_chat = false
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

## ---------------------------------------------------------------------
## 3.3 擲筊：動態產生按鈕，連續三次「聖杯」才算成功。
## random + while 的教學內容示範程式碼寫在 ch3_3_intro.tres 裡，
## 這裡則是把「一直重複到條件成立」實際做成可以互動的小遊戲。
## ---------------------------------------------------------------------
func _start_divination() -> void:
	_step = "3_3_divination"
	_consecutive_holy = 0

	var result_label = Label.new()
	result_label.name = "DivinationResult"
	result_label.text = "連續聖杯：0 / 3"

	var btn = Button.new()
	btn.text = "🙏 擲筊"
	btn.pressed.connect(func():
		var outcomes = ["聖杯", "笑杯", "陰杯"]
		var outcome = outcomes[randi() % outcomes.size()]
		if outcome == "聖杯":
			_consecutive_holy += 1
		else:
			_consecutive_holy = 0
		result_label.text = "這次擲出：%s　連續聖杯：%d / 3" % [outcome, _consecutive_holy]

		if _consecutive_holy >= 3:
			btn.disabled = true
			_divination_row.queue_free()
			_goto("3_3_success")
	)

	_divination_row = HBoxContainer.new()
	_divination_row.name = "DivinationRow"
	_divination_row.add_child(btn)
	_divination_row.add_child(result_label)
	object_area.add_child(_divination_row)

## ---------------------------------------------------------------------
## 3.4 准考證檢查：動態產生物品按鈕，玩家點選要放進背包的東西，
## 對照 REQUIRED_ITEMS 做巢狀比對（呼應 ch3_4_intro.tres 裡示範的雙層 for 迴圈）。
## ---------------------------------------------------------------------
func _start_backpack_check() -> void:
	_step = "3_4_backpack"
	_my_bag.clear()

	_bag_row = VBoxContainer.new()
	_bag_row.name = "BackpackCheckBox"

	var item_row = HBoxContainer.new()
	for item_name in CANDIDATE_ITEMS:
		var btn = CheckButton.new()
		btn.text = item_name
		btn.toggled.connect(func(pressed: bool):
			if pressed:
				if not _my_bag.has(item_name):
					_my_bag.append(item_name)
			else:
				_my_bag.erase(item_name)
		)
		item_row.add_child(btn)
	_bag_row.add_child(item_row)

	var confirm_btn = Button.new()
	confirm_btn.text = "檢查背包"
	confirm_btn.pressed.connect(_on_backpack_confirm)
	_bag_row.add_child(confirm_btn)

	object_area.add_child(_bag_row)

func _on_backpack_confirm() -> void:
	var count = 0
	for item_name in _my_bag:
		for req in REQUIRED_ITEMS:
			if item_name == req:
				count += 1
				break

	if count == REQUIRED_ITEMS.size():
		output.text = "（你檢查了一下背包，發現簡章要求的五個物品都帶齊了！）"
		_bag_row.queue_free()
		_goto("3_4_success")
	else:
		output.text = "（好像還缺了點什麼... 目前只帶了 %d/%d 樣正確物品。）" % [count, REQUIRED_ITEMS.size()]

func _on_next_chapter_pressed() -> void:
	# 第四章（大學）尚未存在，先顯示提示而不是硬切場景造成崩潰。
	output.text = "✨ 目前的故事，先寫到這裡。派森說：「大學的故事，等你我都準備好了再繼續。」"

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
