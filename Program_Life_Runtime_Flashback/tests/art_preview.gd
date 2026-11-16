extends Control

## 美術預覽：不用玩到那一節，直接看新背景＋立繪在遊戲裡的樣子（用遊戲本身的背景、立繪元件）。
##   開：godot --path . res://tests/art_preview.tscn
##   ← → 換背景　　空白鍵 切換立繪　　Esc 離開
##   自動截圖：godot --path . res://tests/art_preview.tscn -- --shots=<資料夾>

const BackgroundView := preload("res://src/game/components/background_view.gd")
const PortraitLayer := preload("res://src/game/components/portrait_layer.gd")

## [背景, 左邊角色, 右邊角色]
const PAGES := [
	["photo_room", "媽媽", "爸爸"],
	["school", "倖芳", ""],
	["library", "倖芳", "翊丞"],
	["cafe", "倖芳", ""],
	["meeting_room", "Cindy", "Claire"],
	["temple_day", "奶奶", ""],
]

var _bg: Control
var _portraits: Control
var _hint: Label
var _i := 0
var _show_chars := true


func _ready() -> void:
	UIKit.full_rect(self)
	_bg = BackgroundView.new()
	add_child(_bg)
	_portraits = PortraitLayer.new()
	add_child(_portraits)
	_hint = Label.new()
	_hint.position = Vector2(36, 1030)
	_hint.add_theme_font_size_override("font_size", 24)
	_hint.add_theme_color_override("font_color", Color.WHITE)
	_hint.add_theme_color_override("font_outline_color", Color.BLACK)
	_hint.add_theme_constant_override("outline_size", 6)
	add_child(_hint)

	var shots := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shots="):
			shots = a.substr(8)
	if shots != "":
		_hint.visible = false
		for i in PAGES.size():
			_show(i, true)
			await get_tree().create_timer(0.6).timeout
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("%s/%02d_%s.png" % [shots, i, PAGES[i][0]])
		get_tree().quit()
		return
	_show(0, true)


func _show(i: int, instant: bool = false) -> void:
	_i = wrapi(i, 0, PAGES.size())
	var page: Array = PAGES[_i]
	_bg.show_bg(page[0], "", instant)
	_portraits.hide_character("all")
	if _show_chars:
		if page[1] != "":
			_portraits.show_character(page[1], "left")
		if page[2] != "":
			_portraits.show_character(page[2], "right")
	_hint.text = "%d/%d　%s　　← → 換背景　空白鍵 立繪開關　Esc 離開" % [_i + 1, PAGES.size(), page[0]]


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_right"):
		_show(_i + 1)
	elif e.is_action_pressed("ui_left"):
		_show(_i - 1)
	elif e.is_action_pressed("ui_accept"):
		_show_chars = not _show_chars
		_show(_i, true)
	elif e.is_action_pressed("ui_cancel"):
		get_tree().quit()
