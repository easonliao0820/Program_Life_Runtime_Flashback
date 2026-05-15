extends Control

@onready var label = $Label
@onready var hint = $ContinueHint
var full_text = "在程式碼的深處，隱藏著一段失落的記憶...\n當 Runtime 再次啟動，那些被遺忘的片段將重新閃爍。\n\n「歡迎回來，開發者。」"
var typing_speed = 0.1
var is_typing = false
var tween: Tween

func _ready():
	# 初始化文字
	label.text = full_text
	label.visible_characters = 0
	hint.modulate.a = 0 # 初始不可見
	start_typing()

func start_typing():
	is_typing = true
	tween = create_tween()
	var duration = full_text.length() * typing_speed
	tween.tween_property(label, "visible_characters", full_text.length(), duration)
	tween.finished.connect(_on_typing_finished)

func _on_typing_finished():
	is_typing = false
	show_hint()

func show_hint():
	# 漸顯提示文字
	var hint_tween = create_tween()
	hint_tween.tween_property(hint, "modulate:a", 1.0, 1.0).set_trans(Tween.TRANS_SINE)

func _input(event):
	# 偵測點擊或按下空白鍵
	var is_confirm = (event is InputEventMouseButton and event.pressed) or \
					 (event is InputEventKey and event.pressed and event.keycode == KEY_SPACE)
	
	if is_confirm:
		if is_typing:
			# 跳過打字
			if tween:
				tween.kill()
			label.visible_characters = full_text.length()
			_on_typing_finished()
		elif hint.modulate.a >= 0.9: # 確保提示已浮現或快浮現完
			# 進入下一階段
			print("前言結束，進入第一章...")
			# get_tree().change_scene_to_file("res://chapters/chapter_1/scenes/section_1.tscn")
