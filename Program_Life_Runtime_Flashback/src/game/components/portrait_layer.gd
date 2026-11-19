extends Control

## 立繪層（畫面設定書 2.1）：最多同時兩位角色，正在說話的角色亮起，其他角色稍微變暗。
## 正式立繪放在 assets/characters/<角色>.png（或 <角色>_<表情>.png）。
## 還沒有美術時，用「剪影＋代表色」佔位（畫面設定書 第六節的建議）。
## 「你」是第一人稱視角，預設不顯示立繪。

const CHAR_DIR := "res://assets/characters/"
const SheetAnim := preload("res://src/game/components/sheet_anim.gd")
## 待機動畫：一列橫排，每格跟立繪一樣 1:2（例如 128×256 一格）。有表情時檔名是 <角色>_<表情>_idle.png
##   <角色>_idle.png  → 一直循環播（呼吸、身體輕輕擺動）
##   <角色>_blink.png → 大部分時間停在第一格，每 2.5～5 秒播一輪（眨眼）
const IDLE_FPS := 6.0
const BLINK_FPS := 10.0
const SLOTS := {"left": 0.27, "right": 0.73, "center": 0.5}

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
		_face(entry["node"], slot)
		return
	# 同一個位置已經有人，先讓他離開
	for other in _shown.keys():
		if _shown[other]["slot"] == slot:
			hide_character(other)
	var node := _make_portrait(char_name, expression)
	add_child(node)
	_move(node, slot, true)
	_face(node, slot)
	node.modulate.a = 0.0
	create_tween().tween_property(node, "modulate:a", 1.0, 0.35)
	_shown[char_name] = {"node": node, "slot": slot}


## 站在右邊的角色左右翻轉，讓兩邊的人面對面（立繪都是朝同一個方向畫的）
func _face(holder: Control, slot: String) -> void:
	for c in holder.get_children():
		if c is TextureRect:
			c.flip_h = slot == "right"


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
		var target := Color(1, 1, 1, node.modulate.a) if lit else Color(0.62, 0.62, 0.68, node.modulate.a)
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
	var blink := false
	var idle := _find_idle(char_name, expression, "idle")
	if idle.is_empty():
		idle = _find_idle(char_name, expression, "blink")
		blink = true
	var tex: Texture2D = idle[0] if not idle.is_empty() else _find_texture(char_name, expression)
	if tex:
		var tr: TextureRect
		if idle.size() > 1:
			var sa := SheetAnim.new()
			if blink:
				sa.setup(idle, BLINK_FPS, 2.5, 5.0)
			else:
				sa.setup(idle, IDLE_FPS)
			tr = sa
		else:
			tr = TextureRect.new()
		UIKit.full_rect(tr)
		tr.texture = tex
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


func _find_texture(char_name: String, expression: String) -> Texture2D:
	var candidates: Array = []
	if expression != "":
		candidates.append("%s%s_%s" % [CHAR_DIR, char_name, expression])
	candidates.append(CHAR_DIR + char_name)
	for base in candidates:
		for ext in [".png", ".webp"]:
			if ResourceLoader.exists(base + ext):
				return load(base + ext)
	return null


## 有表情時只找那個表情的待機動畫（找不到就用靜態的表情圖，不會退回一般表情的動畫）
func _find_idle(char_name: String, expression: String, kind: String) -> Array[Texture2D]:
	var base := CHAR_DIR + char_name + ("_" + expression if expression != "" else "") + "_" + kind + ".png"
	if not ResourceLoader.exists(base):
		var none: Array[Texture2D] = []
		return none
	var sheet: Texture2D = load(base)
	return SheetAnim.slice(sheet, 0, sheet.get_height() / 2)


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
