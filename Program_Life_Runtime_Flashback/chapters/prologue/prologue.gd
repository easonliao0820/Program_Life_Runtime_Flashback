extends Control

@onready var chinese_body = $NarrativeContainer/ChineseAct/Body
@onready var chinese_source = $NarrativeContainer/ChineseAct/Source
@onready var english_act = $NarrativeContainer/EnglishAct
@onready var hint = $ContinueHint
@onready var start_hint = $StartHint

var typing_speed = 0.1
var is_animating = false
var current_step = 0 # 0: Chinese Body, 1: Chinese Source, 2: English Fade, 3: Finished
var main_tween: Tween
var blink_tween: Tween
var fade_tween: Tween
var waiting_for_start = true

func _ready():
	chinese_body.visible_characters = 0
	chinese_source.visible_characters = 0
	english_act.modulate.a = 0
	hint.modulate.a = 0
	start_hint.modulate.a = 0
	_start_blink()

func _start_blink():
	fade_tween = create_tween()
	fade_tween.tween_property(start_hint, "modulate:a", 1.0, 1.5).set_trans(Tween.TRANS_SINE)
	fade_tween.finished.connect(_start_loop_blink)

func _start_loop_blink():
	if not waiting_for_start:
		return
	blink_tween = create_tween().set_loops()
	blink_tween.tween_property(start_hint, "modulate:a", 0.15, 1.2).set_trans(Tween.TRANS_SINE)
	blink_tween.tween_property(start_hint, "modulate:a", 1.0, 1.2).set_trans(Tween.TRANS_SINE)

func start_sequence():
	is_animating = true
	current_step = 0
	animate_chinese_body()

func animate_chinese_body():
	current_step = 0
	main_tween = create_tween()
	var duration = chinese_body.text.length() * typing_speed
	main_tween.tween_property(chinese_body, "visible_characters", chinese_body.text.length(), duration)
	main_tween.finished.connect(animate_chinese_source)

func animate_chinese_source():
	current_step = 1
	main_tween = create_tween()
	var duration = chinese_source.text.length() * typing_speed
	main_tween.tween_property(chinese_source, "visible_characters", chinese_source.text.length(), duration)
	main_tween.finished.connect(animate_english_fade)

func animate_english_fade():
	current_step = 2
	main_tween = create_tween()
	main_tween.tween_property(english_act, "modulate:a", 1.0, 1.5).set_trans(Tween.TRANS_SINE)
	main_tween.finished.connect(finish_sequence)

func finish_sequence():
	current_step = 3
	is_animating = false
	show_hint()

func show_hint():
	var hint_tween = create_tween()
	hint_tween.tween_property(hint, "modulate:a", 1.0, 1.0).set_trans(Tween.TRANS_SINE)

func _input(event):
	var is_confirm = (event is InputEventKey and event.pressed and event.keycode == KEY_SPACE)

	if not is_confirm:
		return

	if waiting_for_start:
		waiting_for_start = false
		if fade_tween:
			fade_tween.kill()
		if blink_tween:
			blink_tween.kill()
		start_hint.hide()
		start_sequence()
	elif is_animating:
		skip_animation()
	elif hint.modulate.a >= 0.9:
		print("前言結束，進入第一章...")
		get_tree().change_scene_to_file("res://chapters/chapter_1/scenes/section_1.tscn")

func skip_animation():
	if main_tween:
		main_tween.kill()

	chinese_body.visible_characters = -1
	chinese_source.visible_characters = -1
	english_act.modulate.a = 1.0

	finish_sequence()
