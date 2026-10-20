extends Control

## 全螢幕背景（畫面設定書 2.1／第一節）
## - 有正式美術（assets/backgrounds/<key>.png、assets/cg/<key>.png）就顯示圖片
## - 沒有就用「人生階段色調」畫漸層佔位圖，並在角落標示場景名稱
## - 暈影（vignette）：越早的人生階段越重，像舊照片
## - 相片邊框：每一章開頭淡淡出現，暗示「這是回憶」
## - 降低彩度：3.3 靈魂出竅

const BG_DIR := "res://assets/backgrounds/"
const CG_DIR := "res://assets/cg/"

const VIGNETTE_SHADER := """
shader_type canvas_item;
uniform float strength = 0.4;
uniform vec4 tint : source_color = vec4(0.22, 0.13, 0.05, 1.0);
void fragment() {
	vec2 uv = UV - 0.5;
	float d = length(uv * vec2(1.0, 0.85));
	COLOR = vec4(tint.rgb, smoothstep(0.32, 0.8, d) * strength);
}
"""

const SATURATION_SHADER := """
shader_type canvas_item;
uniform float saturation = 1.0;
uniform float blur = 0.0;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
void fragment() {
	vec4 c = vec4(0.0);
	if (blur > 0.0) {
		vec2 px = SCREEN_PIXEL_SIZE * blur;
		for (int x = -2; x <= 2; x++) {
			for (int y = -2; y <= 2; y++) {
				c += texture(screen_tex, SCREEN_UV + vec2(float(x), float(y)) * px);
			}
		}
		c /= 25.0;
	} else {
		c = texture(screen_tex, SCREEN_UV);
	}
	float g = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	COLOR = vec4(mix(vec3(g), c.rgb, saturation), 1.0);
}
"""

var _current: Control
var _place_sign: PanelContainer
var _place_label: Label
var _vignette: ColorRect
var _post: ColorRect
var _frame: Panel
var _eyelid_top: ColorRect
var _eyelid_bottom: ColorRect
var bg_key: String = ""
var tone_id: String = "birth"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIKit.full_rect(self)

	_current = _make_layer("black", "black")
	add_child(_current)

	_post = ColorRect.new()
	UIKit.full_rect(_post)
	_post.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pm := ShaderMaterial.new()
	pm.shader = _shader(SATURATION_SHADER)
	_post.material = pm
	_post.visible = false
	add_child(_post)

	_vignette = ColorRect.new()
	UIKit.full_rect(_vignette)
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vm := ShaderMaterial.new()
	vm.shader = _shader(VIGNETTE_SHADER)
	_vignette.material = vm
	add_child(_vignette)

	_frame = Panel.new()
	UIKit.full_rect(_frame)
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fs := StyleBoxFlat.new()
	fs.draw_center = false
	fs.border_color = Color("#f7efe1")
	fs.set_border_width_all(26)
	fs.shadow_color = Color(0, 0, 0, 0.18)
	fs.shadow_size = 18
	_frame.add_theme_stylebox_override("panel", fs)
	_frame.modulate.a = 0.0
	add_child(_frame)

	# 場景名牌：捷運站名牌風格（捷運藍底、白字、左邊一條亮黃色路線色）
	_place_sign = PanelContainer.new()
	var sign := UIKit.box(Color(UIKit.MRT_BLUE, 0.92), 8, UIKit.GOLD, 0, 0)
	sign.border_width_left = 10
	sign.border_color = UIKit.GOLD
	sign.content_margin_left = 18
	sign.content_margin_right = 20
	sign.content_margin_top = 6
	sign.content_margin_bottom = 6
	_place_sign.add_theme_stylebox_override("panel", sign)
	_place_sign.position = Vector2(36, 30)
	_place_sign.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_label = UIKit.label("", 24, Color.WHITE)
	_place_sign.add_child(_place_label)
	_place_sign.visible = false
	add_child(_place_sign)

	_eyelid_top = ColorRect.new()
	_eyelid_bottom = ColorRect.new()
	for lid in [_eyelid_top, _eyelid_bottom]:
		lid.color = Color.BLACK
		lid.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lid.visible = false
		add_child(lid)


func _shader(code: String) -> Shader:
	var s := Shader.new()
	s.code = code
	return s


## 換背景（淡入淡出）。key 可以是 BACKGROUNDS 的鍵，也可以是 cg:<名稱>。
func show_bg(key: String, tone_override: String = "", instant: bool = false) -> void:
	var info: Dictionary = ChapterRegistry.BACKGROUNDS.get(key, {"name": key, "tone": tone_id})
	bg_key = key
	tone_id = tone_override if tone_override != "" else str(info.get("tone", tone_id))
	var layer := _make_layer(key, tone_id)
	add_child(layer)
	move_child(layer, _current.get_index() + 1)
	_place_label.text = str(info.get("name", ""))
	_place_sign.visible = _place_label.text != ""
	_place_sign.reset_size()
	_apply_vignette()
	var old := _current
	_current = layer
	if instant:
		old.queue_free()
		return
	layer.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(layer, "modulate:a", 1.0, 1.2)
	await t.finished
	old.queue_free()


## 顯示 CG（劇本：@cg 名稱 說明）。沒有圖時用色調佔位，並把說明寫在畫面中央。
func show_cg(key: String, caption: String) -> void:
	var layer := _make_layer("cg:" + key, tone_id, caption)
	add_child(layer)
	move_child(layer, _current.get_index() + 1)
	layer.modulate.a = 0.0
	var old := _current
	_current = layer
	var t := create_tween()
	t.tween_property(layer, "modulate:a", 1.0, 1.6)
	await t.finished
	old.queue_free()


func set_tone(id: String) -> void:
	tone_id = id
	_apply_vignette()


func _apply_vignette() -> void:
	var tone := ChapterRegistry.tone(tone_id)
	var warm: float = tone.get("warm", 0.5)
	var mat := _vignette.material as ShaderMaterial
	mat.set_shader_parameter("strength", 0.15 + warm * 0.45)
	mat.set_shader_parameter("tint", Color("#3a2410") if warm > 0.3 else Color("#05070f"))


func _make_layer(key: String, tone_name: String, caption: String = "") -> Control:
	var holder := Control.new()
	UIKit.full_rect(holder)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tex: Texture2D = null
	if ChapterRegistry.ART.has(key) and ResourceLoader.exists(ChapterRegistry.ART[key]):
		tex = load(ChapterRegistry.ART[key])
	elif key.begins_with("cg:"):
		tex = _try_texture(CG_DIR + key.substr(3))
	else:
		tex = _try_texture(BG_DIR + key)
	if tex:
		var tr := TextureRect.new()
		UIKit.full_rect(tr)
		tr.texture = tex
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if key.begins_with("cg:"):
			# CG 用米色底、置中不裁切（父母剪影這類方形圖）
			var paper := ColorRect.new()
			UIKit.full_rect(paper)
			paper.color = Color("#f4efe6")
			paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
			holder.add_child(paper)
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		holder.add_child(tr)
		if caption != "":
			holder.add_child(_cg_caption(caption))
		return holder

	# 佔位：人生階段色調的漸層
	var tone := ChapterRegistry.tone(tone_name)
	var grad := Gradient.new()
	grad.set_color(0, tone["top"])
	grad.set_color(1, tone["bottom"])
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill_from = Vector2(0.5, 0)
	gt.fill_to = Vector2(0.5, 1)
	gt.width = 64
	gt.height = 64
	var tr2 := TextureRect.new()
	UIKit.full_rect(tr2)
	tr2.texture = gt
	tr2.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr2.stretch_mode = TextureRect.STRETCH_SCALE
	tr2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(tr2)

	if caption != "":
		holder.add_child(_cg_caption(caption))
	return holder


## CG 說明：像相片背面的手寫註記，放在畫面上方（下方留給對話框）
func _cg_caption(caption: String) -> Control:
	var tag := PanelContainer.new()
	tag.add_theme_stylebox_override("panel", UIKit.navy_panel(8, 14))
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tag.anchor_left = 0.5
	tag.anchor_right = 0.5
	tag.offset_left = -520
	tag.offset_right = 520
	tag.offset_top = 110
	var lbl := UIKit.label("回憶｜" + caption, 28, UIKit.GOLD)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tag.add_child(lbl)
	return tag


func _try_texture(base: String) -> Texture2D:
	for ext in [".png", ".jpg", ".webp"]:
		if ResourceLoader.exists(base + ext):
			return load(base + ext)
	return null


func _is_light(tone_name: String) -> bool:
	var c: Color = ChapterRegistry.tone(tone_name)["top"]
	return c.get_luminance() > 0.6


# ------------------------------------------------------------------
# 演出效果
# ------------------------------------------------------------------

## 劇情為主：進入程式關卡／探索模式時，整個場景縮進左上的「劇情區」，結束後再放大回全螢幕
func set_view_rect(rect: Rect2, dur: float = 0.6) -> void:
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	var t := create_tween().set_parallel(true).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "position", rect.position, dur)
	t.tween_property(self, "size", rect.size, dur)
	await t.finished


func show_frame(on: bool, dur: float = 1.0) -> void:
	var t := create_tween()
	t.tween_property(_frame, "modulate:a", 0.85 if on else 0.0, dur)


## 3.3 靈魂狀態：降低彩度、邊緣微微發光
func set_saturation(value: float, blur: float = 0.0) -> void:
	_post.visible = value < 0.999 or blur > 0.0
	var mat := _post.material as ShaderMaterial
	mat.set_shader_parameter("saturation", value)
	mat.set_shader_parameter("blur", blur)


## 序章：上下兩條黑邊慢慢打開，像眼睛睜開；畫面先模糊再對焦
func eyes_open(duration: float = 5.0) -> void:
	var h := size.y
	_eyelid_top.position = Vector2.ZERO
	_eyelid_top.size = Vector2(size.x, h / 2.0)
	_eyelid_bottom.position = Vector2(0, h / 2.0)
	_eyelid_bottom.size = Vector2(size.x, h / 2.0)
	_eyelid_top.visible = true
	_eyelid_bottom.visible = true
	set_saturation(1.0, 6.0)
	var t := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(_eyelid_top, "position:y", -h / 2.0, duration)
	t.tween_property(_eyelid_bottom, "position:y", h, duration)
	t.tween_method(func(v: float): set_saturation(1.0, v), 6.0, 2.0, duration)
	await t.finished
	_eyelid_top.visible = false
	_eyelid_bottom.visible = false


## 對焦：把模糊收掉（序章哭出來的瞬間）
func focus(duration: float = 0.8) -> void:
	var t := create_tween()
	t.tween_method(func(v: float): set_saturation(1.0, v), 2.0, 0.0, duration)
	await t.finished
	set_saturation(1.0, 0.0)
