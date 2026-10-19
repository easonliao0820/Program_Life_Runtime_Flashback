extends Control

## 回憶模式（畫面設定書 2.4）：第六章兩個結局的回憶遊戲。
## - 深藍星空，五片不規則形狀的回憶碎片漂浮在空中
## - 未解鎖：黑白、模糊；可挑戰：發光；完成：恢復色彩，並顯示當年的 CG 縮圖
## - 派森在畫面中央，隨著進度越來越透明，邊緣不斷散出光點
## - 金色進度條，完成一片前進 20%
## - 下方的劇情對話框一直留著（劇情為主），派森的話會繼續出現
## - 點選碎片後進入程式關卡模式，編輯器改成深藍色主題

signal _picked(index: int)

var _sky: Control
var _orb: Control
var _bar: ProgressBar
var _title: Label
var _fragments: Array = []
var _done_flags: Array = []


func _ready() -> void:
	UIKit.full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_sky = StarSky.new()
	UIKit.full_rect(_sky)
	add_child(_sky)
	_orb = preload("res://src/game/components/pyson_orb.gd").new()
	add_child(_orb)
	_orb.place(Vector2(960, 420))
	_orb.set_mood("fading")
	_title = UIKit.label("", 34, Color("#ffe9a8"))
	_title.position = Vector2(60, 40)
	add_child(_title)
	_bar = ProgressBar.new()
	_bar.position = Vector2(560, 700)  # 下方留給劇情對話框
	_bar.size = Vector2(800, 26)
	_bar.max_value = 100
	_bar.show_percentage = false
	_bar.add_theme_stylebox_override("fill", UIKit.box(Color("#f5c242"), 13))
	_bar.add_theme_stylebox_override("background", UIKit.box(Color(1, 1, 1, 0.12), 13))
	add_child(_bar)
	visible = false


## play_fragment：Callable(level: Dictionary) -> Dictionary，由 GameStage 提供（會開程式關卡模式）
func play(def: Dictionary, play_fragment: Callable) -> void:
	var levels: Array = def.get("fragments", [])
	var cgs: Array = def.get("cg", [])
	_title.text = GameState.format_text(str(def.get("title", "回憶")))
	for f in _fragments:
		f.queue_free()
	_fragments.clear()
	_done_flags.clear()
	var spots := [Vector2(330, 250), Vector2(1590, 250), Vector2(380, 560), Vector2(1540, 560), Vector2(960, 160)]
	for i in levels.size():
		var frag := Fragment.new()
		frag.title = str(levels[i].get("title", "回憶 %d" % (i + 1)))
		frag.cg_caption = str(cgs[i]) if i < cgs.size() else ""
		frag.seed_value = i * 7919 + 13
		frag.position = spots[i % spots.size()] - Vector2(150, 110)
		frag.picked.connect(func(): _picked.emit(i))
		add_child(frag)
		_fragments.append(frag)
		_done_flags.append(false)
	_update()

	visible = true
	modulate.a = 0.0
	UIKit.fade(self, 1.0, 0.6)

	while _done_flags.has(false):
		if GameFlow.autopilot:
			_picked.emit.call_deferred(_done_flags.find(false))
		var idx: int = await _picked
		if _done_flags[idx] or idx != _done_flags.find(false):
			continue  # 只能挑戰目前發光的那一片
		visible = false
		await play_fragment.call(levels[idx])
		visible = true
		_done_flags[idx] = true
		_update()
		await get_tree().create_timer(0.8).timeout

	await get_tree().create_timer(1.2).timeout
	var t := UIKit.fade(self, 0.0, 0.8)
	await t.finished
	visible = false


func _update() -> void:
	var next := _done_flags.find(false)
	var done := 0
	for i in _fragments.size():
		var f: Fragment = _fragments[i]
		f.state = "done" if _done_flags[i] else ("open" if i == next else "locked")
		f.queue_redraw()
		if _done_flags[i]:
			done += 1
	var ratio := float(done) / maxf(1.0, _fragments.size())
	create_tween().tween_property(_bar, "value", ratio * 100.0, 0.6)
	_orb.set_fade(1.0 - ratio * 0.75)


class Fragment extends Control:
	signal picked
	var title: String = ""
	var cg_caption: String = ""
	var state: String = "locked"
	var seed_value: int = 1
	var _t: float = 0.0
	var _poly: PackedVector2Array

	func _ready() -> void:
		size = Vector2(300, 220)
		mouse_filter = Control.MOUSE_FILTER_STOP
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var c := size / 2.0
		for k in 7:
			var a := TAU * k / 7.0 + rng.randf_range(-0.25, 0.25)
			_poly.append(c + Vector2(cos(a) * rng.randf_range(110, 145), sin(a) * rng.randf_range(75, 100)))

	func _process(delta: float) -> void:
		_t += delta
		position.y += sin(_t * 0.9 + seed_value) * 0.15
		queue_redraw()

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			picked.emit()

	func _draw() -> void:
		var fill := Color(0.35, 0.37, 0.42, 0.55)
		var edge := Color(0.6, 0.6, 0.65, 0.4)
		if state == "open":
			var p := 0.5 + 0.5 * sin(_t * 3.0)
			draw_colored_polygon(_grow(14 + p * 8), Color(UIKit.PY_YELLOW, 0.18 + p * 0.12))
			fill = Color(0.25, 0.4, 0.75, 0.8)
			edge = UIKit.PY_YELLOW
		elif state == "done":
			fill = Color("#f6c66b").lerp(Color("#e89bb3"), 0.3)
			edge = Color.WHITE
		draw_colored_polygon(_poly, fill)
		var closed := _poly.duplicate()
		closed.append(_poly[0])
		draw_polyline(closed, edge, 3.0)
		var font := UIKit.body_font()
		var label := title if state != "locked" else "？？？"
		if state == "done" and cg_caption != "":
			label = cg_caption
		var tw := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
		draw_string(font, Vector2((size.x - tw) / 2.0, size.y / 2.0 + 8), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 24,
			Color(1, 1, 1, 0.95) if state != "done" else UIKit.INK)

	func _grow(d: float) -> PackedVector2Array:
		var c := size / 2.0
		var out := PackedVector2Array()
		for p in _poly:
			out.append(p + (p - c).normalized() * d)
		return out


class StarSky extends Control:
	var _stars: Array = []
	var _t: float = 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		var rng := RandomNumberGenerator.new()
		rng.seed = 2026
		for i in 180:
			_stars.append([Vector2(rng.randf() * 1920, rng.randf() * 1080), rng.randf_range(1, 3), rng.randf() * TAU])

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color("#070d24"))
		for s in _stars:
			var a: float = 0.4 + 0.6 * absf(sin(_t * 0.8 + s[2]))
			draw_circle(s[0], s[1], Color(1, 0.97, 0.85, a))
