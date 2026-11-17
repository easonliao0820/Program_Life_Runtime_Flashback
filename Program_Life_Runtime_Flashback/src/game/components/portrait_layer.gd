extends Control

## 立繪層（畫面設定書 2.1）：最多同時兩位角色，正在說話的角色亮起，其他角色稍微變暗。
## 正式立繪放在 assets/characters/<角色>.png（或 <角色>_<表情>.png）。
## 動圖立繪：<角色>_動圖.png（或 <角色>_<表情>_動圖.png），有的話優先使用。
##   一張圖裡排好每一格，從左到右、從上到下播放（例如 3×3 共 9 格）。
##   每格的大小 = 同一個角色靜止圖的大小（例如 媽媽.png 是 128×256，就用 128×256 去切）；
##   沒有靜止圖時用 DEFAULT_FRAME_SIZE。
## 還沒有美術時，用「剪影＋代表色」佔位（畫面設定書 第六節的建議）。
## 「你」是第一人稱視角，預設不顯示立繪。

const CHAR_DIR := "res://assets/characters/"
const SLOTS := {"left": 0.27, "right": 0.73, "center": 0.5}
const ANIM_SUFFIX := "_動圖"
const DEFAULT_FRAME_SIZE := Vector2i(128, 256)
const ANIM_FPS := 6.0  ## 動圖立繪每秒幾格

## 角色名 -> {node, slot}
var _shown: Dictionary = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIKit.full_rect(self)


func show_character(char_name: String, slot: String = "", expression: String = "") -> void:
	if slot == "":
		slot = "right" if _slot_taken("left", char_name) else "left"
	if _shown.has(char_name):
		var entry: Dictionary = _shown[char_name]
		entry["slot"] = slot
		_move(entry["node"], slot)
		_set_texture(entry["node"], char_name, expression)
		return
	# 同一個位置已經有人，先讓他離開
	for other in _shown.keys():
		if _shown[other]["slot"] == slot:
			hide_character(other)
	var node := _make_portrait(char_name, expression)
	add_child(node)
	_move(node, slot, true)
	node.modulate.a = 0.0
	create_tween().tween_property(node, "modulate:a", 1.0, 0.35)
	_shown[char_name] = {"node": node, "slot": slot}


func hide_character(char_name: String) -> void:
	if char_name == "all":
		for k in _shown.keys():
			hide_character(k)
		return
	if not _shown.has(char_name):
		return
	var node: Control = _shown[char_name]["node"]
	_shown.erase(char_name)
	var t := create_tween()
	t.tween_property(node, "modulate:a", 0.0, 0.3)
	t.tween_callback(node.queue_free)


## 說話的角色亮起，其他人變暗；speaker 不在畫面上（旁白、派森）時大家都維持正常亮度。
func highlight(speaker: String) -> void:
	for k in _shown.keys():
		var node: Control = _shown[k]["node"]
		var lit: bool = speaker == "" or not _shown.has(speaker) or k == speaker
		# 透明度一律是 1（還在 _shown 裡的都是要看得見的；離場的人已經先移出 _shown）。
		# 不能用「當下的透明度」：角色剛出場、淡入還沒跑完就開口說話時，會把淡入蓋掉，角色永遠停在透明。
		var target := Color(1, 1, 1, 1) if lit else Color(0.62, 0.62, 0.68, 1)
		create_tween().tween_property(node, "modulate", target, 0.2)


func has_character(char_name: String) -> bool:
	return _shown.has(char_name)


func _slot_taken(slot: String, except_name: String) -> bool:
	for k in _shown.keys():
		if k != except_name and _shown[k]["slot"] == slot:
			return true
	return false


func _move(node: Control, slot: String, instant: bool = false) -> void:
	var x: float = SLOTS.get(slot, 0.5) * 1920.0 - node.size.x / 2.0
	var y: float = 1080.0 - node.size.y - 60.0
	if instant:
		node.position = Vector2(x, y)
	else:
		create_tween().tween_property(node, "position", Vector2(x, y), 0.3)


func _make_portrait(char_name: String, expression: String) -> Control:
	var holder := Control.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.size = Vector2(440, 760)
	holder.set_meta("char_name", char_name)
	_set_texture(holder, char_name, expression)
	return holder


func _set_texture(holder: Control, char_name: String, expression: String) -> void:
	for c in holder.get_children():
		c.queue_free()
	var frames := _find_frames(char_name, expression)
	if not frames.is_empty():
		var tr := AnimPortrait.new()
		tr.frames = frames
		tr.fps = ANIM_FPS
		UIKit.full_rect(tr)
		tr.texture = frames[0]
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST  # 像素立繪放大不糊
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(tr)
	else:
		var sil := Silhouette.new()
		sil.color = ChapterRegistry.character_color(char_name)
		sil.label = char_name + ("（%s）" % expression if expression != "" else "")
		UIKit.full_rect(sil)
		holder.add_child(sil)


## 找立繪，回傳每一格（靜止圖就只有 1 格）。
## 順序：表情動圖 → 表情靜止圖 → 一般動圖 → 一般靜止圖
func _find_frames(char_name: String, expression: String) -> Array[Texture2D]:
	var bases: Array = []
	if expression != "":
		bases.append("%s%s_%s" % [CHAR_DIR, char_name, expression])
	bases.append(CHAR_DIR + char_name)
	for base in bases:
		var still := _load_first(base)
		var anim := _load_first(base + ANIM_SUFFIX)
		if anim:
			var size := Vector2i(still.get_size()) if still else DEFAULT_FRAME_SIZE
			return _slice(anim, size)
		if still:
			return [still] as Array[Texture2D]
	return [] as Array[Texture2D]


func _load_first(base: String) -> Texture2D:
	for ext in [".png", ".webp"]:
		if ResourceLoader.exists(base + ext):
			return load(base + ext)
	return null


## 把動圖照格子大小切開（從左到右、從上到下）
func _slice(sheet: Texture2D, cell: Vector2i) -> Array[Texture2D]:
	var out: Array[Texture2D] = []
	var cols := maxi(sheet.get_width() / cell.x, 1)
	var rows := maxi(sheet.get_height() / cell.y, 1)
	for r in rows:
		for c in cols:
			var atlas := AtlasTexture.new()
			atlas.atlas = sheet
			atlas.region = Rect2(c * cell.x, r * cell.y, cell.x, cell.y)
			out.append(atlas)
	return out


## 立繪圖片：只有 1 格就是靜止圖，多格就循環播放
class AnimPortrait extends TextureRect:
	var frames: Array[Texture2D] = []
	var fps: float = 6.0
	var _t: float = 0.0
	var _i: int = 0

	func _process(delta: float) -> void:
		if frames.size() <= 1:
			set_process(false)
			return
		_t += delta
		var step := 1.0 / fps
		if _t >= step:
			_t -= step
			_i = (_i + 1) % frames.size()
			texture = frames[_i]


## 佔位剪影：頭＋肩膀，半透明代表色
class Silhouette extends Control:
	var color: Color = Color.GRAY
	var label: String = ""

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var w := size.x
		var h := size.y
		# 佔位剪影：代表色壓暗＋半透明，不要搶過場景美術
		var c := Color(color.darkened(0.35), 0.7)
		draw_circle(Vector2(w / 2.0, h * 0.24), w * 0.17, c)
		var body := PackedVector2Array([
			Vector2(w * 0.12, h), Vector2(w * 0.18, h * 0.55), Vector2(w * 0.36, h * 0.42),
			Vector2(w * 0.64, h * 0.42), Vector2(w * 0.82, h * 0.55), Vector2(w * 0.88, h)])
		draw_colored_polygon(body, c)
		var font := UIKit.body_font()
		var tw := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 28).x
		draw_string(font, Vector2((w - tw) / 2.0, h * 0.5), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color(1, 1, 1, 0.85))
