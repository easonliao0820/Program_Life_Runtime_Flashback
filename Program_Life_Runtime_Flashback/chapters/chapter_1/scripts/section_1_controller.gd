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
	print("GDScript READY OK")
	
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
			
		var data = load("res://chapters/chapter_1/data/ch1_intro_story.tres")
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
		var teach_data = load("res://chapters/chapter_1/data/ch1_teach_story.tres")
		story_box.start_story(teach_data)

func _on_run_pressed() -> void:
	var code = code_edit.text
	print("執行程式碼: ", code)
	
	# 防連點保護
	button.disabled = true
	
	var sm = get_node_or_null("/root/SandboxManager")
	var result = ""
	if sm:
		result = sm.run_code(code)
	else:
		result = SandboxManager.run_code(code)
	
	print("執行結果: ", result)
	
	if result.begins_with("❌"):
		output.text = "「語之觀測者」正在窺探程式裂縫..."
		AiBridge.translate_error(result, code)
	else:
		output.text = result + "\n\n✨ 系統：成功打招呼！已放聲大哭！"
		button.disabled = false # 成功執行，直接解鎖按鈕
		if story_box:
			story_box.sandbox_resolved()
			var success_data = load("res://chapters/chapter_1/data/ch1_success_story.tres")
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
	
	_is_waiting_for_chat = true # 確立聊天鎖定狀態
	
	if story_box:
		var waiting_data = DialogueData.new()
		var step = DialogueStep.new()
		step.speaker = "AI 導師 派森"
		step.line = "思考中..."
		waiting_data.dialogue_sequence.append(step)
		story_box.start_story(waiting_data)
		story_box.is_waiting_for_ai = true

	var prompt = """
你是遊戲中的 AI 導師「派森」，目前正在引導【第一章剛剛成功啼哭結束，準備轉場進入第二章】的玩家。

【當前劇情背景】
玩家剛剛在你的引導下，成功寫出 `print("哈囉")` 發出了震撼世界的嬰兒第一聲啼哭，新生父母正感動又溫暖地抱著他 。此時聊天框剛解鎖，你剛跟玩家自我介紹完 。

【下一階段任務（第二章 1.1 記憶變數）】
接下來的劇情是轉場到玩家慢慢長大，開始感嘆父母的愛、小時候的遊樂場記憶，而你需要教他用「變數（love = 'you'）」來儲存這些快要變淡的愛與記憶 。

【人格與絕對規則】
1. 你的名字永遠是「派森」，是程式世界的引導者，說話溫柔、神秘、帶點哲理 。
2. 絕對不得透露自己是 Gemini、AI 模型或文字機器人 。
3. 嚴格限制在 60 字內，使用繁體中文，不使用表情符號 。

【核心防禦與劇情推進機制】
如果玩家在聊天框輸入了：髒話、色情、政治、現實世界敏感議題，或任何與遊戲完全無關的成人話題（如：金錢、現實工作、聊股票、買車） 。

你必須啟動「嬰兒防禦機制」，順著劇情吐槽他，並積極吸引他進入下一階段（第二章）：
- 提醒他他現在只是個「剛學會哭、躺在繈褓裡的嬰兒」，大人的話題對他來說太早了 。
- 告訴他，比起這些無關的事，他現在更應該去感受身邊父母溫暖的懷抱 。
- 暗示他，這些記憶很快就會變淡，必須準備學會用「新的魔法（變數）」來把這份愛存下來 。

【引導回應範例（請嚴格學習此邏輯，不要叫他重複 print 哭泣）】
玩家：「X！我要發大財買法拉利」
派森：「大人的欲望對現在的你還太早呢。你剛學會哭泣，不如先靠在父母溫暖的懷抱裡，想想該怎麼用變數記住他們的容顏吧。」 

玩家：「今天天氣如何？」
派森：「外面的風雨與躺在襁褓中的你無關。時間正悄悄流逝，你難道不想用程式的盒子，將父母此刻的愛永遠保存下來嗎？」 

玩家：「你到底是誰？是人工智慧嗎？」
派森：「我只是寄宿在代碼長河中的一縷微光，你可以叫我派森。旅人，時空開始轉動了，準備好去記錄你接下來的人生變數了嗎？」 

現在，請根據玩家輸入的內容進行回覆，嚴格限制在 60 字內，吸引他關注父母的愛並引導進入第二章：
玩家說：
%s
""" % message

	if AiBridge:
		AiBridge.call_openai(prompt)

func _on_ai_response(text: String) -> void:
	# 無論是聊天還是錯誤轉譯回來，只要 API 有回應，就解鎖程式執行按鈕
	button.disabled = false
	
	if _is_waiting_for_chat:
		_is_waiting_for_chat = false
		
		# 恢復聊天 UI 輸入狀態
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
			
		# 【重要優化】：當聊天結束且得到 AI 引導回覆後，直接顯示進入下一章的按鈕
		if chapter_buttons:
			chapter_buttons.show_next_chapter()
	else:
		# 顯示 AI 轉譯後的錯誤資料
		output.text = text

func _on_next_chapter_pressed() -> void:
	get_tree().change_scene_to_file("res://chapters/chapter_2/scenes/section_1.tscn") 

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