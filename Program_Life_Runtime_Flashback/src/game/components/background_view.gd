extends Control

## 全螢幕背景（畫面設定書 2.1／第一節）
## - 有正式美術（assets/backgrounds/<key>.png、assets/cg/<key>.png）就顯示圖片
## - 沒有就用「人生階段色調」畫漸層佔位圖，並在角落標示場景名稱
## - 暈影（vignette）：越早的人生階段越重，像舊照片
## - 相片邊框：每一章開頭淡淡出現，暗示「這是回憶」
## - 降低彩度：3.3 靈魂出竅

const BG_DIR := "res://assets/backgrounds/"
const CG_DIR := "res://assets/cg/"
## 背景上的小動畫（PixelLab 動畫匯出的 sprite sheet），擺在哪裡見 ChapterRegistry.BG_FX
const FX_DIR := "res://assets/backgrounds/fx/"
const SheetAnim := preload("res://src/game/components/sheet_anim.gd")
## 背景圖裁切時保留哪裡：0 = 保留最上面，1 = 保留最下面。
## 不是 16:9 的圖（例如 AI 給的正方形）會填滿畫面，多的主要從上方裁，地板留著
const CROP_ANCHOR_Y := 0.65
## 同一張圖變出不同時段（傍晚、深夜、清晨、靈魂出竅…），參數見 ChapterRegistry.BG_GRADES
const GRADE_SHADER := """
shader_type canvas_item;
uniform vec4 mul : source_color = vec4(1.0);
uniform float bright = 1.0;
uniform float sat = 1.0;
uniform vec4 top_c : source_color = vec4(0.0);
uniform vec4 bottom_c : source_color = vec4(0.0);
uniform vec4 glow : source_color = vec4(0.0);
uniform vec2 glow_pos = vec2(0.5);
uniform float glow_r = 0.3;
uniform float vig = 0.0;
uniform float tame = 0.0;
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float g = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	vec3 rgb = mix(vec3(g), c.rgb, sat) * mul.rgb * bright;
	rgb *= 1.0 - tame * smoothstep(0.5, 0.95, g);
	vec4 ov = mix(top_c, bottom_c, UV.y);
	rgb = mix(rgb, ov.rgb, ov.a);
	float d = distance(UV, glow_pos);
	rgb += glow.rgb * glow.a * smoothstep(glow_r, 0.0, d) * (0.4 + g);
	rgb *= 1.0 - vig * smoothstep(0.3, 0.85, length(UV - 0.5));
	COLOR = vec4(rgb, c.a);
}
"""

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
	if _has_cg_art("cg:" + key):
		_animate_cg(layer, key)
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
	# 背景也可以是影片：assets/backgrounds/<key>.ogv（Godot 只吃 .ogv），循環播放、填滿畫面
	if not key.begins_with("cg:") and has_video(key):
		var vp := VideoStreamPlayer.new()
		UIKit.full_rect(vp)
		vp.stream = load(BG_DIR + key + ".ogv")
		vp.expand = true
		vp.loop = true
		vp.autoplay = true
		vp.volume_db = -80.0   # 背景影片不出聲，音樂另外放
		vp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		holder.add_child(vp)
		return holder
	# CG 還沒有正式的圖：沿用當下的背景，調暗、偏暖，像回憶，再寫上說明（不要整片純色）
	if key.begins_with("cg:") and not _has_cg_art(key) \
			and bg_key not in ["", "black", "white"] and not bg_key.begins_with("cg:"):
		var base := _make_layer(bg_key, tone_name)
		base.modulate = Color(0.74, 0.67, 0.6)
		if caption != "":
			base.add_child(_cg_caption(caption))
		return base
	var tex: Texture2D = null
	# 動態背景：assets/backgrounds/<key>_anim.png（一列橫排、每格 16:9），有的話優先用
	var anim: Array[Texture2D] = []
	var art_key := key   # 實際用到哪個地方的圖（變體會換成 base），小動畫照這個找
	if ChapterRegistry.ART.has(key) and ResourceLoader.exists(ChapterRegistry.ART[key]):
		tex = load(ChapterRegistry.ART[key])
	elif key.begins_with("cg:"):
		# CG 也可以是動畫：assets/cg/<名稱>_anim.png（一列橫排、每格 16:9）
		anim = _try_anim(key.substr(3), CG_DIR)
		if anim.is_empty():
			tex = _try_texture(CG_DIR + key.substr(3))
	else:
		anim = _try_anim(key)
		if anim.is_empty():
			tex = _try_texture(BG_DIR + key)
	# 沒有自己的圖，但可以從同一個地方的圖調色變出來
	var grade: Dictionary = {}
	if tex == null and anim.is_empty() and ChapterRegistry.BG_VARIANTS.has(key):
		var v: Dictionary = ChapterRegistry.BG_VARIANTS[key]
		art_key = str(v["base"])
		anim = _try_anim(art_key)
		if anim.is_empty():
			tex = _try_texture(BG_DIR + art_key)
		if tex or not anim.is_empty():
			grade = ChapterRegistry.BG_GRADES.get(v["grade"], {})
	if not anim.is_empty():
		tex = anim[0]
	if tex:
		var tr: TextureRect
		if anim.size() > 1:
			var sa := SheetAnim.new()
			sa.setup(anim, float(ChapterRegistry.BG_ANIM_FPS.get(art_key, 6.0)))
			tr = sa
		else:
			tr = TextureRect.new()
		UIKit.full_rect(tr)
		tr.texture = tex
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# 像素風：小圖放大時保持顆粒清楚，不要被線性過濾糊掉
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		if not key.begins_with("cg:"):
			# 填滿畫面但不置中裁：照 CROP_ANCHOR_Y 決定裁哪邊（畫面大小改變時重新排）
			tr.stretch_mode = TextureRect.STRETCH_SCALE
			holder.clip_contents = true
			holder.resized.connect(_fit_cover.bind(holder, tr))
			_fit_cover.call_deferred(holder, tr)
		if key.begins_with("cg:"):
			# CG 用米色底、置中不裁切（父母剪影這類方形圖）
			var paper := ColorRect.new()
			UIKit.full_rect(paper)
			paper.color = Color("#f4efe6")
			paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
			holder.add_child(paper)
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if not grade.is_empty():
			tr.material = _grade_material(grade)
		# 小動畫：背景照 BG_FX[背景鍵]，CG 照 BG_FX["cg:<名稱>"]
		_add_fx(tr, key if ChapterRegistry.BG_FX.has(key) else art_key, grade)
		if key.begins_with("cg:"):
			# CG 不走 _fit_cover，小動畫的位置在這裡跟著畫面大小排
			tr.resized.connect(_layout_fx.bind(tr))
			_layout_fx.call_deferred(tr)
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


## 等比放大到蓋滿 holder；左右置中，上下照 CROP_ANCHOR_Y 對齊
func _fit_cover(holder: Control, tr: TextureRect) -> void:
	if not is_instance_valid(tr) or tr.texture == null:
		return
	var ts := tr.texture.get_size()
	var hs := holder.size
	if ts.x <= 0 or ts.y <= 0 or hs.x <= 0 or hs.y <= 0:
		return
	var k := maxf(hs.x / ts.x, hs.y / ts.y)
	var sz := ts * k
	tr.set_anchors_preset(Control.PRESET_TOP_LEFT)
	tr.size = sz
	tr.position = Vector2((hs.x - sz.x) * 0.5, (hs.y - sz.y) * CROP_ANCHOR_Y)
	_layout_fx(tr)


## 背景上的小動畫：照 ChapterRegistry.BG_FX 的設定，從 assets/backgrounds/fx/ 找圖疊上去。
## 沒有圖的就跳過，所以可以一個一個慢慢補。
func _add_fx(tr: TextureRect, key: String, grade: Dictionary) -> void:
	for spec: Dictionary in ChapterRegistry.BG_FX.get(key, []):
		var path := FX_DIR + str(spec["sheet"]) + ".png"
		if not ResourceLoader.exists(path):
			continue
		var sheet: Texture2D = load(path)
		var frames := SheetAnim.slice(sheet, int(spec.get("frames", 0)))
		if frames.is_empty():
			continue
		var fx := SheetAnim.new()
		fx.setup(frames, float(spec.get("fps", 8.0)))
		fx.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		fx.stretch_mode = TextureRect.STRETCH_SCALE
		fx.flip_h = bool(spec.get("flip", false))
		fx.modulate.a = float(spec.get("alpha", 1.0))
		if not grade.is_empty():
			# 背景被調成夜晚／傍晚時，小動畫也跟著變暗變色（只取乘色和亮度，避免 shader 的暈影套在小圖上）
			var m: Color = grade.get("mul", Color.WHITE)
			var b: float = grade.get("bright", 1.0)
			fx.modulate = Color(m.r * b, m.g * b, m.b * b, fx.modulate.a)
		var fsz := frames[0].get_size()
		fx.set_meta("fx_pos", spec.get("pos", Vector2(0.5, 0.5)))
		fx.set_meta("fx_h", float(spec.get("h", 0.2)))
		fx.set_meta("fx_aspect", fsz.x / maxf(fsz.y, 1.0))
		tr.add_child(fx)
		if spec.has("to"):
			_move_fx.call_deferred(tr, fx, spec)


## pos = 小動畫「中心」在背景圖上的位置（0～1），h = 高度佔背景圖的比例
func _layout_fx(tr: TextureRect) -> void:
	for c in tr.get_children():
		if c.has_meta("fx_pos"):
			_place_fx(tr, c)


func _place_fx(tr: TextureRect, c: Control) -> void:
	var h: float = tr.size.y * float(c.get_meta("fx_h"))
	var sz := Vector2(h * float(c.get_meta("fx_aspect")), h)
	var p: Vector2 = c.get_meta("fx_pos")
	c.size = sz
	c.position = p * tr.size - sz / 2.0


## 會移動的小動畫（例如人慢慢往前走）：BG_FX 裡寫 to（終點）、h_to（終點高度，走遠會變小）、
## time（幾秒走完）、fade_out（走到之後淡出）。速度是等速，腳步才不會像在滑。
func _move_fx(tr: TextureRect, fx: Control, spec: Dictionary) -> void:
	if not is_instance_valid(fx):
		return
	var p0: Vector2 = spec.get("pos", Vector2(0.5, 0.5))
	var p1: Vector2 = spec["to"]
	var h0 := float(spec.get("h", 0.2))
	var h1 := float(spec.get("h_to", h0))
	var t := fx.create_tween()
	t.tween_method(_move_fx_step.bind(tr, fx, p0, p1, h0, h1), 0.0, 1.0, float(spec.get("time", 12.0)))
	if spec.get("fade_out", false):
		t.tween_property(fx, "modulate:a", 0.0, 1.5)


func _move_fx_step(k: float, tr: TextureRect, fx: Control, p0: Vector2, p1: Vector2, h0: float, h1: float) -> void:
	fx.set_meta("fx_pos", p0.lerp(p1, k))
	fx.set_meta("fx_h", lerpf(h0, h1, k))
	_place_fx(tr, fx)


## 動態背景的 sprite sheet：<key>_anim.png，一列橫排，每格都是 16:9（例如 640×360 一格）
func _try_anim(key: String, dir: String = BG_DIR) -> Array[Texture2D]:
	var path := dir + key + "_anim.png"
	if not ResourceLoader.exists(path):
		var none: Array[Texture2D] = []
		return none
	var sheet: Texture2D = load(path)
	return SheetAnim.slice(sheet, 0, roundi(sheet.get_height() * 16.0 / 9.0))


func _grade_material(g: Dictionary) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = _shader(GRADE_SHADER)
	m.set_shader_parameter("mul", g.get("mul", Color.WHITE))
	m.set_shader_parameter("bright", g.get("bright", 1.0))
	m.set_shader_parameter("sat", g.get("sat", 1.0))
	m.set_shader_parameter("top_c", g.get("top", Color(0, 0, 0, 0)))
	m.set_shader_parameter("bottom_c", g.get("bottom", Color(0, 0, 0, 0)))
	m.set_shader_parameter("glow", g.get("glow", Color(0, 0, 0, 0)))
	m.set_shader_parameter("glow_pos", g.get("glow_pos", Vector2(0.5, 0.5)))
	m.set_shader_parameter("glow_r", g.get("glow_r", 0.3))
	m.set_shader_parameter("vig", g.get("vig", 0.0))
	m.set_shader_parameter("tame", g.get("tame", 0.0))
	return m


## CG 的動態感：細小光點往上飄（不推鏡頭，畫面保持固定）。
## 結局的 CG 用派森的藍、金光點，其他用暖白色。
const CG_SPARKLE_KEYS := ["ending1", "ending2"]


func _animate_cg(holder: Control, key: String) -> void:
	holder.clip_contents = true
	var tr: TextureRect = null
	for c in holder.get_children():
		if c is TextureRect:
			tr = c
	if tr == null:
		return
	# 高解析度的圖（聊天 AI 生的）用線性過濾，慢慢放大才不會像素抖動；小的像素圖維持最近鄰
	if tr.texture and tr.texture.get_width() >= 1000:
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var dots := CPUParticles2D.new()
	dots.amount = 46 if key in CG_SPARKLE_KEYS else 28
	dots.lifetime = 5.0
	dots.preprocess = 5.0
	dots.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	dots.emission_rect_extents = Vector2(960, 540)
	dots.position = Vector2(960, 540)
	dots.direction = Vector2(0, -1)
	dots.spread = 25.0
	dots.gravity = Vector2.ZERO
	dots.initial_velocity_min = 20.0
	dots.initial_velocity_max = 45.0
	dots.scale_amount_min = 2.0
	dots.scale_amount_max = 5.0
	var ramp := Gradient.new()
	if key in CG_SPARKLE_KEYS:
		ramp.set_color(0, Color(0.55, 0.8, 1.0, 0.0))
		ramp.add_point(0.3, Color(1.0, 0.9, 0.45, 0.8))
		ramp.add_point(0.7, Color(0.55, 0.8, 1.0, 0.7))
		ramp.set_color(ramp.get_point_count() - 1, Color(1.0, 0.9, 0.45, 0.0))
	else:
		ramp.set_color(0, Color(1.0, 0.95, 0.82, 0.0))
		ramp.add_point(0.4, Color(1.0, 0.95, 0.82, 0.45))
		ramp.set_color(ramp.get_point_count() - 1, Color(1.0, 0.95, 0.82, 0.0))
	dots.color_ramp = ramp
	holder.add_child(dots)
	await get_tree().process_frame
	if not is_instance_valid(tr):
		return
	dots.position = holder.size / 2.0
	dots.emission_rect_extents = holder.size / 2.0


## 這張 CG（key = "cg:<名稱>"）有沒有正式的圖
func _has_cg_art(key: String) -> bool:
	if ChapterRegistry.ART.has(key) and ResourceLoader.exists(ChapterRegistry.ART[key]):
		return true
	return ResourceLoader.exists(CG_DIR + key.substr(3) + "_anim.png") or _try_texture(CG_DIR + key.substr(3)) != null


## 有沒有這個背景的影片版（assets/backgrounds/<key>.ogv）
func has_video(key: String) -> bool:
	return ResourceLoader.exists(BG_DIR + key + ".ogv")


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


## 閉上眼睛：上下兩條黑邊瞬間蓋住整個畫面（之後換背景，玩家也看不到）
func close_eyes() -> void:
	var h := size.y
	_eyelid_top.position = Vector2.ZERO
	_eyelid_top.size = Vector2(size.x, h / 2.0)
	_eyelid_bottom.position = Vector2(0, h / 2.0)
	_eyelid_bottom.size = Vector2(size.x, h / 2.0)
	_eyelid_top.visible = true
	_eyelid_bottom.visible = true
	set_saturation(1.0, 6.0)


func eyes_closed() -> bool:
	return _eyelid_top.visible


## 序章：上下兩條黑邊慢慢打開，像眼睛睜開；畫面先模糊再對焦
## 劇本要先 @eyes_close 再換背景，才不會先看到圖、又突然變黑再睜眼
func eyes_open(duration: float = 2.5) -> void:
	var h := size.y
	if not eyes_closed():
		close_eyes()
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
