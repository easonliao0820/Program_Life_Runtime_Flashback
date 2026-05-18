extends Node2D

@onready var code_edit: CodeEdit = $CanvasLayer/MainLayout/RightPanel/CodingArea/CodeEdit
@onready var output: Label = $CanvasLayer/MainLayout/RightPanel/FeedbackArea/OutputLabel
@onready var button: Button = $CanvasLayer/MainLayout/RightPanel/FeedbackArea/RunButton
@onready var story_box = $CanvasLayer/StoryBox

@onready var left_panel = $CanvasLayer/MainLayout/LeftPanel
@onready var right_panel = $CanvasLayer/MainLayout/RightPanel
@onready var object_area = $CanvasLayer/MainLayout/LeftPanel/ObjectArea

func _ready() -> void:
	print("GDScript READY OK")
	
	# 初始隱藏
	right_panel.hide()
	object_area.hide()
	
	# 綁定按鈕訊號
	button.pressed.connect(_on_run_pressed)
	
	# 綁定劇情結束訊號
	if story_box:
		story_box.story_finished.connect(_on_story_finished)
		var data = load("res://chapters/chapter_1/data/ch1_intro_story.tres")
		story_box.start_story(data)

func _on_story_finished() -> void:
	# 劇情結束，執行版面展開動畫
	print("劇情結束，動態展開版面...")
	
	# 1. 準備初始狀態
	right_panel.show()
	object_area.show()
	
	# 先將比例設為極小，模擬從全螢幕開始
	right_panel.size_flags_stretch_ratio = 0.01
	object_area.size_flags_stretch_ratio = 0.01
	
	right_panel.modulate.a = 0
	object_area.modulate.a = 0
	
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	
	# 2. 執行比例動畫 (讓左側故事區平滑縮小，右側與下方展開)
	tween.tween_property(right_panel, "size_flags_stretch_ratio", 3.0, 1.5)
	tween.tween_property(object_area, "size_flags_stretch_ratio", 1.0, 1.5)
	
	# 3. 執行淡入動畫
	tween.tween_property(right_panel, "modulate:a", 1.0, 1.0)
	tween.tween_property(object_area, "modulate:a", 1.0, 1.0)

func _on_run_pressed() -> void:
	var code = code_edit.text
	print("執行程式碼: ", code)
	
	# 使用 get_node 確保能抓到單例 (或是直接使用單例名稱)
	var sm = get_node_or_null("/root/SandboxManager")
	var result = ""
	if sm:
		result = sm.run_code(code)
	else:
		result = SandboxManager.run_code(code)
	
	print("執行結果: ", result)
	
	if result.begins_with("❌"):
		output.text = result
	else:
		output.text = result + "\n\n✨ 系統：已記錄你的名字"
