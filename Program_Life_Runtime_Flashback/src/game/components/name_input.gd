extends Control

## 名字輸入畫面（畫面設定書 2.5）：遊戲一開始，在畫面中央輸入名字（{userName}），
## 設定書原本是全白畫面，太刺眼；改成跟前言、登入畫面一致的深色調（深藍黑底＋暖黃心跳光暈）。
## 背景有微弱的心跳聲（assets/audio/heartbeat.ogg，沒有檔案時只播放脈動動畫）。
## 有存檔時多一個「繼續旅程」按鈕。

var _input: LineEdit
var _pulse: Control
var _t: float = 0.0


func _ready() -> void:
	UIKit.full_rect(self)
	var bg := ColorRect.new()
	bg.color = Color("#0d1424")
	UIKit.full_rect(bg)
	add_child(bg)

	_pulse = Pulse.new()
	UIKit.full_rect(_pulse)
	add_child(_pulse)

	var center := CenterContainer.new()
	UIKit.full_rect(center)
	add_child(center)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 28)
	v.custom_minimum_size = Vector2(720, 0)
	center.add_child(v)

	var q := UIKit.label("你叫什麼名字？", 40, UIKit.GOLD)
	q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(q)
	_input = LineEdit.new()
	_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_input.max_length = 12
	_input.placeholder_text = "輸入名字"
	_input.custom_minimum_size = Vector2(720, 84)
	_input.add_theme_font_override("font", UIKit.body_font())
	_input.add_theme_font_size_override("font_size", 40)
	_input.add_theme_color_override("font_color", UIKit.TEXT_LIGHT)
	_input.add_theme_color_override("font_placeholder_color", Color(1, 1, 1, 0.3))
	_input.add_theme_color_override("caret_color", UIKit.GOLD)
	_input.add_theme_stylebox_override("normal", UIKit.box(Color(0, 0, 0, 0), 0, Color.TRANSPARENT, 0, 10))
	_input.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_input.text_submitted.connect(func(_t2: String): _start_new())
	v.add_child(_input)
	var underline := ColorRect.new()
	underline.color = Color(UIKit.GOLD, 0.7)
	underline.custom_minimum_size = Vector2(720, 3)
	v.add_child(underline)

	var start := UIKit.button("開始", UIKit.MRT_BLUE)
	start.custom_minimum_size = Vector2(0, 70)
	start.pressed.connect(_start_new)
	v.add_child(start)

	if GameState.has_save():
		var data_ok := GameState.load_game()
		if data_ok:
			var sec := ChapterRegistry.get_section(GameState.section_id)
			var cont := UIKit.button("繼續旅程：%s（%s）" % [GameState.user_name, sec.get("title", "")], UIKit.NAVY, UIKit.TEXT_LIGHT)
			cont.custom_minimum_size = Vector2(0, 70)
			cont.pressed.connect(GameFlow.continue_game)
			v.add_child(cont)
			var map_btn := UIKit.button("記憶地圖（MEMORY LOAD）", UIKit.NAVY, UIKit.GOLD)
			map_btn.custom_minimum_size = Vector2(0, 70)
			map_btn.pressed.connect(GameFlow.open_map)
			v.add_child(map_btn)
			_input.placeholder_text = "輸入新名字，重新開始"

	_input.grab_focus.call_deferred()
	var hb := "res://assets/audio/heartbeat.ogg"
	if ResourceLoader.exists(hb):
		var p := AudioStreamPlayer.new()
		p.stream = load(hb)
		p.volume_db = -14
		add_child(p)
		p.play()


func _start_new() -> void:
	var n := _input.text.strip_edges()
	if n == "":
		_input.placeholder_text = "要先告訴我你的名字喔"
		return
	GameFlow.new_game(n)


## 心跳：畫面中央暖黃色的淡淡光暈，一下一下地跳
class Pulse extends Control:
	var _t: float = 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var beat := fmod(_t, 1.1)
		var k := exp(-beat * 6.0) + 0.6 * exp(-absf(beat - 0.25) * 12.0)
		var c := size / 2.0
		# 圈數多、每圈很淡，疊起來才是平滑的光暈，不會看到一圈一圈的分層
		for i in range(24, 0, -1):
			draw_circle(c, 120.0 + i * 22.0 + k * 24.0, Color(0.97, 0.82, 0.55, 0.006 * k + 0.003))
