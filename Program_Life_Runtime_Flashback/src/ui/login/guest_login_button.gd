extends Button

func _ready():
	# 連結按鈕按下訊號
	self.pressed.connect(_on_guest_login_pressed)
	# 連結滑鼠移入與移出的訊號（延用與 Google 按鈕一樣的動畫）
	self.mouse_entered.connect(_on_mouse_entered)
	self.mouse_exited.connect(_on_mouse_exited)

func _on_guest_login_pressed():
	print("訪客登入：跳過驗證流程，進入前言...")
	get_tree().change_scene_to_file("res://chapters/prologue/prologue.tscn")

func _on_mouse_entered():
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.3).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)

func _on_mouse_exited():
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
