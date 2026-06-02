extends Node2D

@onready var code_edit: CodeEdit = $CanvasLayer/MainLayout/RightPanel/CodingArea/CodeEdit
@onready var output: Label = $CanvasLayer/MainLayout/RightPanel/FeedbackArea/OutputLabel
@onready var button: Button = $CanvasLayer/MainLayout/RightPanel/FeedbackArea/RunButton
@onready var story_box = $CanvasLayer/StoryBox

@onready var left_panel = $CanvasLayer/MainLayout/LeftPanel
@onready var right_panel = $CanvasLayer/MainLayout/RightPanel
@onready var object_area = $CanvasLayer/MainLayout/LeftPanel/ObjectArea

var chapter_buttons = null
var textbook_panel: Control = null
var textbook_close_button: Button = null
var textbook_mask: ColorRect = null
var _intro_done: bool = false
var _success_done: bool = false

func _ready() -> void:
	print("GDScript READY OK")
	AiBridge.ai_response_received.connect(_on_ai_response)
	chapter_buttons = get_node_or_null("CanvasLayer/MainLayout/LeftPanel/ObjectArea/ChapterButtons")
	textbook_panel = get_node_or_null("TextbookLayer/TextbookPanel")
	textbook_close_button = get_node_or_null("TextbookLayer/TextbookPanel/WindowContainer/MarginContainer/VBox/Header/CloseButton")
	textbook_mask = get_node_or_null("TextbookLayer/TextbookPanel/BackgroundMask")

	# 初始隱藏
	right_panel.hide()
	object_area.hide()

	# 綁定按鈕訊號
	button.pressed.connect(_on_run_pressed)

	# 綁定 ChapterButtons 訊號
	if chapter_buttons:
		chapter_buttons.next_chapter_pressed.connect(_on_next_chapter_pressed)
		chapter_buttons.textbook_pressed.connect(_on_textbook_pressed)
	if textbook_close_button:
		textbook_close_button.pressed.connect(_on_textbook_close_pressed)
	if textbook_mask:
		textbook_mask.gui_input.connect(_on_textbook_mask_gui_input)
	
	# 綁定劇情訊號
	if story_box:
		story_box.story_finished.connect(_on_story_finished)
		story_box.sandbox_waiting.connect(_on_sandbox_waiting)
		var data = load("res://chapters/chapter_1/data/ch1_intro_story.tres")
		story_box.start_story(data)

func _on_story_finished() -> void:
	if not _intro_done:
		print("1")
		_intro_done = true
	elif not _success_done:
		print("2")
		_success_done = true
		chapter_buttons.show_next_chapter()
		return
	else:
		print("3")
		return
	print("4")
	print("劇情結束，動態展開版面...")

	right_panel.show()
	object_area.show()
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

	story_box.reposition_to_top_right()
	var teach_data = load("res://chapters/chapter_1/data/ch1_teach_story.tres")
	story_box.start_story(teach_data)

# 緩衝結果
var result = "" 
var can_show_result: bool = false
var teach_story_done = false

func _on_run_pressed() -> void:
	
	
	var code = code_edit.text

	
	print("執行程式碼: ", code)
	
	# 使用 get_node 確保能抓到單例 (或是直接使用單例名稱)
	var sm = get_node_or_null("/root/SandboxManager")
	
	
	if sm:
		result = sm.run_code(code)
	else:
		result = SandboxManager.run_code(code)
	
	print("執行結果: ", result)
	
	# ❌ 不顯示
	if not can_show_result:
		output.text = "請先繼續完成劇情閱讀~"
		return

	# ✔ 可以顯示
	output.text = result
	
	
	if result.begins_with("❌"):
		output.text = result
		#AI轉譯
		AiBridge.translate_error(result,code)
	else:
		output.text = result + "\n\n✨ 系統：成功打招呼！已放聲大哭！"
		if story_box:
			story_box.sandbox_resolved()
			var success_data = load("res://chapters/chapter_1/data/ch1_success_story.tres")
			story_box.start_story(success_data)


func _on_ai_response(text):
	#顯示AI轉譯後資料
	#output.text = text
	print(text)
	
func _on_next_chapter_pressed() -> void:
	get_tree().change_scene_to_file("res://chapters/chapter_2/scenes/section_1.tscn")

func _on_sandbox_waiting() -> void:
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
