extends Node2D

@onready var code_edit: CodeEdit = $CodeEdit
@onready var output: Label = $OutputLabel
@onready var button: Button = $RunButton
@onready var story_box = $StoryBox

func _ready() -> void:
	print("GDScript READY OK")
	
	# 綁定按鈕訊號
	button.pressed.connect(_on_run_pressed)
	
	# 啟動開場劇情
	if story_box:
		var data = load("res://chapters/chapter_1/data/ch1_intro_story.tres")
		story_box.start_story(data)

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
