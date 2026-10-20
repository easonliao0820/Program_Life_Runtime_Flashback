extends Control

## 章節轉場（畫面設定書 2.5），風格跟前言畫面一致：全黑底。
## 每一章開頭：先打字顯示一句對應這一章的程式名言（ChapterRegistry.CHAPTER_QUOTES），
## 出處靠右灰字、英文原文淡入；接著顯示章節名稱與年齡。
## 同一章裡換小節不會進到這裡（GameStage 只在頂端顯示一條小字），避免太多場景切換。
## 點一下或按空白鍵：打字中 → 直接顯示全文；顯示完 → 繼續。

signal _skip

const TYPE_SPEED := 0.1  ## 每個字幾秒，跟前言畫面一樣
const FADE := 1.0         ## 淡入淡出秒數

var _bg: ColorRect
var _quote_box: VBoxContainer
var _zh: Label
var _source: Label
var _en: Label
var _title_box: VBoxContainer
var _chapter: Label
var _sub: Label
var _hint: Label
var _waiting: bool = false


func _ready() -> void:
	UIKit.full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_bg = ColorRect.new()
	_bg.color = Color.BLACK
	UIKit.full_rect(_bg)
	add_child(_bg)

	# 名言（版面比照前言畫面：置中、寬 1300、中文大字、出處靠右）
	_quote_box = VBoxContainer.new()
	_quote_box.position = Vector2(310, 330)
	_quote_box.custom_minimum_size = Vector2(1300, 0)
	_quote_box.add_theme_constant_override("separation", 18)
	add_child(_quote_box)
	_zh = UIKit.label("", 44, Color.WHITE)
	_zh.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_zh.custom_minimum_size = Vector2(1300, 0)
	_quote_box.add_child(_zh)
	_source = UIKit.label("", 26, Color(0.78, 0.78, 0.78))
	_source.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_source.custom_minimum_size = Vector2(1300, 0)
	_source.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_quote_box.add_child(_source)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 24)
	_quote_box.add_child(gap)
	_en = UIKit.label("", 30, Color(1, 1, 1, 0.85))
	_en.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_en.custom_minimum_size = Vector2(1300, 0)
	_quote_box.add_child(_en)

	# 章節名稱
	_title_box = VBoxContainer.new()
	UIKit.full_rect(_title_box)
	_title_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_title_box.add_theme_constant_override("separation", 22)
	_title_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_title_box)
	_chapter = UIKit.label("", 64, Color.WHITE)
	_chapter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_box.add_child(_chapter)
	_sub = UIKit.label("", 30, Color(0.7, 0.7, 0.7))
	_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_box.add_child(_sub)

	_hint = UIKit.label("{ 按下空白鍵繼續 }", 26, Color(0.7, 0.7, 0.7))
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.position = Vector2(0, 960)
	_hint.custom_minimum_size = Vector2(1920, 0)
	add_child(_hint)
	visible = false


## 一章的開頭：名言 → 章節名稱
func play_chapter(chapter: String, title: String, age: int, quote: Dictionary) -> void:
	visible = true
	_bg.color = Color.BLACK
	_title_box.modulate.a = 0.0
	_hint.modulate.a = 0.0
	modulate.a = 0.0
	var t := create_tween()
	t.tween_property(self, "modulate:a", 1.0, FADE)
	await t.finished
	await get_tree().create_timer(0.5).timeout

	if not quote.is_empty():
		_quote_box.visible = true
		_quote_box.modulate.a = 1.0
		_zh.text = str(quote.get("zh", ""))
		_source.text = "——" + str(quote.get("source", ""))
		_en.text = "\"%s\"" % str(quote.get("en", ""))
		_zh.visible_characters = 0
		_source.modulate.a = 0.0
		_en.modulate.a = 0.0
		# 打字（可以跳過）
		var typing := create_tween()
		typing.tween_property(_zh, "visible_characters", _zh.text.length(), _zh.text.length() * TYPE_SPEED)
		typing.tween_property(_source, "modulate:a", 1.0, 1.0)
		typing.tween_interval(0.4)
		typing.tween_property(_en, "modulate:a", 1.0, 1.5)
		typing.tween_property(_hint, "modulate:a", 1.0, 1.0)
		await _wait_tween_or_skip(typing)
		_zh.visible_characters = -1
		_source.modulate.a = 1.0
		_en.modulate.a = 1.0
		_hint.modulate.a = 1.0
		await _wait_skip(9.0)
		var out := create_tween().set_parallel(true)
		out.tween_property(_quote_box, "modulate:a", 0.0, FADE)
		out.tween_property(_hint, "modulate:a", 0.0, FADE)
		await out.finished
		await get_tree().create_timer(0.4).timeout
	_quote_box.visible = false

	_chapter.text = chapter
	_sub.text = "%s　・　%d 歲" % [title, age]
	var appear := create_tween()
	appear.tween_property(_title_box, "modulate:a", 1.0, FADE)
	await appear.finished
	await _wait_skip(3.0)
	var fade := create_tween()
	fade.tween_property(self, "modulate:a", 0.0, FADE)
	await fade.finished
	visible = false


## 劇本的（轉場）：短暫淡黑
func fade_through(color: Color = Color.BLACK, hold: float = 0.5) -> void:
	_quote_box.visible = false
	_title_box.modulate.a = 0.0
	_hint.modulate.a = 0.0
	_bg.color = color
	visible = true
	modulate.a = 0.0
	var t := create_tween()
	t.tween_property(self, "modulate:a", 1.0, 0.7)
	t.tween_interval(hold)
	t.tween_property(self, "modulate:a", 0.0, 0.7)
	await t.finished
	_bg.color = Color.BLACK
	visible = false


# ------------------------------------------------------------------

func _wait_tween_or_skip(tw: Tween) -> void:
	_waiting = true
	var done := [false]
	tw.finished.connect(func():
		done[0] = true
		_skip.emit(), CONNECT_ONE_SHOT)
	await _skip
	_waiting = false
	if not done[0] and tw.is_valid():
		tw.kill()


## 等玩家點擊；超過 seconds 秒自動繼續
func _wait_skip(seconds: float) -> void:
	_waiting = true
	var timer := get_tree().create_timer(seconds)
	timer.timeout.connect(func():
		if _waiting:
			_skip.emit())
	await _skip
	_waiting = false


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_press()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_SPACE, KEY_ENTER]:
		get_viewport().set_input_as_handled()
		_press()


func _press() -> void:
	if _waiting:
		_waiting = false
		_skip.emit()
