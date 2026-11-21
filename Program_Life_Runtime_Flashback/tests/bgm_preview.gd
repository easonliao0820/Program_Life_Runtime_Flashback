extends Control

## 音樂／音效試聽：點按鈕就播，音量和遊戲裡一樣（走 GameFlow.play_bgm，含每首的音量補償）。
## 執行：Godot --path . res://tests/bgm_preview.tscn

const BGM := [
	["prologue", "前言黑畫面 → 第一章產房"],
	["childhood", "第二章 童年"],
	["school", "第三章 高中（3.1、3.2、3.4、3.5）"],
	["tension", "3.3 廟裡擲筊、5.2 會議室被質問"],
	["romance", "3.1 捷運送禮物、4.3 湖邊約定、5.4 成家"],
	["campus", "3.5 搬進宿舍、第四章 大學"],
	["office", "4.4 面試、第五章 辦公室"],
	["warm", "5.1、5.3 爸媽家，5.2 報表過關"],
	["nostalgia", "5.4 回憶相簿、第六章 最後的早晨"],
	["farewell", "結局一"],
	["hope", "結局二"],
]
const SFX := ["heartbeat", "baby_cry", "door_warning", "clock_tick", "typing"]

var _now: Label
var _sfx: AudioStreamPlayer


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color("#161F2B")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var v := VBoxContainer.new()
	v.position = Vector2(80, 50)
	v.add_theme_constant_override("separation", 10)
	add_child(v)
	_now = Label.new()
	_now.add_theme_font_size_override("font_size", 34)
	_now.text = "點一首來聽"
	v.add_child(_now)
	for item in BGM:
		var exists := _exists(item[0])
		var b := Button.new()
		b.text = "%s　%s%s" % [item[0], item[1], "" if exists else "　（還沒放）"]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(1100, 56)
		b.add_theme_font_size_override("font_size", 26)
		b.disabled = not exists
		b.pressed.connect(func():
			GameFlow.play_bgm(item[0])
			_now.text = "▶ " + item[0] + "　" + item[1])
		v.add_child(b)
	var stop := Button.new()
	stop.text = "■ 停止（淡出）"
	stop.custom_minimum_size = Vector2(1100, 56)
	stop.add_theme_font_size_override("font_size", 26)
	stop.pressed.connect(func():
		GameFlow.stop_bgm()
		_now.text = "已停止")
	v.add_child(stop)

	_sfx = AudioStreamPlayer.new()
	add_child(_sfx)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	v.add_child(h)
	for n in SFX:
		var b := Button.new()
		b.text = "音效 " + n
		b.add_theme_font_size_override("font_size", 22)
		b.custom_minimum_size = Vector2(0, 50)
		b.disabled = not _exists(n)
		b.pressed.connect(func():
			_sfx.stream = load(_path(n))
			_sfx.play())
		h.add_child(b)


func _path(n: String) -> String:
	for ext in [".ogg", ".mp3", ".wav"]:
		if ResourceLoader.exists(GameFlow.AUDIO_DIR + n + ext):
			return GameFlow.AUDIO_DIR + n + ext
	return ""


func _exists(n: String) -> bool:
	return _path(n) != ""
