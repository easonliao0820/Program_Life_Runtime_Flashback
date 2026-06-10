extends Node2D

@onready var code_edit: CodeEdit = $CanvasLayer/MainLayout/RightPanel/CodingArea/CodeEdit
@onready var output: Label = $CanvasLayer/MainLayout/RightPanel/FeedbackArea/OutputLabel
@onready var button: Button = $CanvasLayer/MainLayout/RightPanel/FeedbackArea/RunButton
@onready var story_box = $CanvasLayer/StoryBox

@onready var left_panel = $CanvasLayer/MainLayout/LeftPanel
@onready var right_panel = $CanvasLayer/MainLayout/RightPanel
@onready var object_area = $CanvasLayer/MainLayout/LeftPanel/ObjectArea

# 聊天對話 UI 節點
@onready var chat_input: LineEdit = $CanvasLayer/MainLayout/LeftPanel/ObjectArea/HBoxContainer/LineEdit
@onready var chat_send_button: Button = $CanvasLayer/MainLayout/LeftPanel/ObjectArea/HBoxContainer/Button
@onready var chat_container: HBoxContainer = $CanvasLayer/MainLayout/LeftPanel/ObjectArea/HBoxContainer

var chapter_buttons = null
var textbook_panel: Control = null
var textbook_close_button: Button = null
var textbook_mask: ColorRect = null
var _intro_done: bool = false
var _success_done: bool = false
var _is_waiting_for_chat: bool = false # 專門用來標記是否在「聊天狀態」

func _ready() -> void:
	print("GDScript READY OK - CHAPTER 2")
	
	# 核心：綁定 AI 回傳訊號
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
			
		# 【修改點 1】：載入第二章初始劇情
		var data = load("res://chapters/chapter_2/data/ch2_intro_story.tres")
		story_box.start_story(data)

func _on_story_finished() -> void:
	if not _intro_done:
		_intro_done = true
	elif not _success_done:
		_success_done = true
		if chapter_buttons:
			chapter_buttons.show_next_chapter()
		chat_container.show()
		return
	else:
		return

	print("劇情結束，動態展開版面...")
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
		# 【修改點 2】：載入第二章教學劇情
		var teach_data = load("res://chapters/chapter_2/data/ch2_teach_story.tres")
		story_box.start_story(teach_data)

func _on_run_pressed() -> void:
	get_viewport().gui_release_focus() 
	print("RUN BUTTON PRESSED - CHAPTER 2")
	
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
	else:
		output.text = result + "\n\n✨ 系統：記憶已成功寫入變數！這份愛已被永遠保存。"
		button.disabled = false 
		if story_box:
			story_box.sandbox_resolved()
			# 【修改點 3】：載入第二章成功解題後的通關劇情
			var success_data = load("res://chapters/chapter_2/data/ch2_success_story.tres")
			story_box.start_story(success_data)

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
	
	if story_box:
		var waiting_data = DialogueData.new()
		var step = DialogueStep.new()
		step.speaker = "AI 導師 派森"
		step.line = "思考中..."
		waiting_data.dialogue_sequence.append(step)
		story_box.start_story(waiting_data)
		story_box.is_waiting_for_ai = true

	# 【修改點 4】：完全替換成第二章「記憶變數」與引導至「第三章大學生活」的專用 Prompt
	var prompt = """
你是遊戲中的 AI 導師「派森」，目前正在引導【第二章 1.1 記憶變數 成功執行後】的玩家。

【當前劇情背景】
玩家剛剛在你的引導下，想起了小時候跟爸媽玩溜滑梯、看卡通，以及爸媽在廟宇許願希望他健康長大的溫馨回憶。他深刻體會到雖然現實中賺錢很難，但父母的愛無價。此時聊天框解鎖。

【下一階段任務（第三章 大學/歐趴/單身狗）】
接下來的劇情是轉場到玩家進入大學生活，開始面對課業、all pass、單身狗與青澀戀情的話題。你需要吸引他繼續前進，踏入精彩的大學生活。

【人格與絕對規則】
1. 你的名字永遠是「派森」，說話溫柔、神秘、富有哲理。
2. 絕對不得透露自己是 Gemini、AI 模型或文字機器人。
3. 嚴格限制在 60 字內，使用繁體中文，不使用表情符號。

【核心防禦與劇情推進機制】
如果玩家在聊天框輸入了：髒話、色情、政治、現實敏感議題，或聊買車、炒股等完全無關的話題。
你必須啟動「回憶防禦機制」，順著劇情拉回正軌，並吸引他進入下一階段：
- 提醒他，比起那些浮躁的事，剛體驗完童年回憶的他，更應該珍惜父母那份無私的愛。
- 告訴他，記憶的變數（love = "you"）已經好好存下了，但人生不會停下，前方還有更精彩的大學青春等著他去編織。

【引導回應範例】
玩家：「今天天氣如何？」
派森：「外面的風雨總會過去，就如童年的紙飛機。既然已經用變數記住了父母的愛，不如打點行囊，準備去迎接喧鬧的大學時光吧。」

玩家：「我要發大財買法拉利」
派森：「世間名利皆是過眼雲煙，唯有父母那份純粹的愛被你的變數永遠保存。旅人，青春的鐘聲響了，不想去體驗一下大學的自由與迷茫嗎？」

現在，請根據玩家輸入的內容進行回覆，限制在 60 字內，圍繞童年溫馨或引導去大學生活：
玩家說：
%s
""" % message

	if AiBridge:
		AiBridge.call_openai(prompt)

func _on_ai_response(text: String) -> void:
	button.disabled = false
	
	if _is_waiting_for_chat:
		_is_waiting_for_chat = false
		
		chat_input.editable = true
		chat_send_button.disabled = false
		
		if story_box:
			story_box.is_waiting_for_ai = false
			
			var chat_response_data = DialogueData.new()
			var step = DialogueStep.new()
			step.speaker = "AI 導師 派森"
			step.line = text
			chat_response_data.dialogue_sequence.append(step)
			
			story_box.start_story(chat_response_data)
			
		if chapter_buttons:
			chapter_buttons.show_next_chapter()
	else:
		output.text = text

func _on_next_chapter_pressed() -> void:
	# 【修改點 5】：第二章結束後，點擊跳轉按鈕切換至第三章場景
	get_tree().change_scene_to_file("res://chapters/chapter_3/scenes/section_1.tscn") 

func _on_sandbox_waiting() -> void:
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
