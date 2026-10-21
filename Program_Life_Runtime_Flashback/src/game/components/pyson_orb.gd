extends Control

## 派森（畫面設定書 第三節）
## 正式美術：src/actors/npc/paisen_float_sparkle_sheet.png（一列 24 格的動圖：揮手、飄浮、身邊有光點）。
## 有這張圖就播放動圖；沒有就退回用程式畫的藍黃光球。
## 情緒（兩種外觀都一樣）：
##   說話 → 變亮；開心 → 動畫加快、輕輕彈跳；擔心 → 變暗、動畫變慢；
##   說大道理 → 緩慢；難過、晚年（fading）→ 光忽明忽暗、身邊散出光點；結局 → 越來越透明（set_fade）
## 背後一圈淡淡的藍黃光暈，呼應「程式＝光」。
## 模糊（set_blur）：第一章新生兒的視線還看不清楚，派森是一團模糊的光（劇本：@orb blur 10），
## 每一節開頭會自動恢復清楚。
## 請保留 place / set_mood / speak / set_fade / set_sprite_scale / set_blur 介面，GameStage 與回憶模式都會用到。

const SHEET := "res://src/actors/npc/paisen_float_sparkle_sheet.png"
const SHEET_FRAMES := 24
const SHEET_FPS := 12.0

## 動圖的模糊：在圖上取周圍 7×7 個點加權平均（各格之間有透明空隙，不會糊到隔壁格）
const BLUR_SHADER := """
shader_type canvas_item;
uniform float radius = 0.0;
varying vec4 tint;
void vertex() {
	tint = COLOR;
}
void fragment() {
	if (radius <= 0.01) {
		COLOR = texture(TEXTURE, UV) * tint;
	} else {
		vec2 step = TEXTURE_PIXEL_SIZE * radius / 3.0;
		vec4 sum = vec4(0.0);
		float total = 0.0;
		for (int x = -3; x <= 3; x++) {
			for (int y = -3; y <= 3; y++) {
				float w = max(1.0 - length(vec2(float(x), float(y))) / 4.5, 0.0);
				sum += texture(TEXTURE, UV + vec2(float(x), float(y)) * step) * w;
				total += w;
			}
		}
		COLOR = (sum / total) * tint;
	}
}
"""

const CORE := Color("#ffd75e")
const RIM := Color("#3d7fd6")
const EYE := Color("#14306b")

var radius: float = 46.0
var brightness: float = 0.8
var mood: String = "idle"
var fade: float = 1.0  ## 結局用：越來越透明
var _t: float = 0.0
var _speaking: bool = false
var _base_pos: Vector2
var _particles: CPUParticles2D
var _sprite: AnimatedSprite2D
var _sprite_scale: float = 0.7
var _blur: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(radius * 4, radius * 4)
	size = custom_minimum_size
	pivot_offset = size / 2.0
	_build_sprite()
	_particles = CPUParticles2D.new()
	_particles.position = size / 2.0
	_particles.amount = 24
	_particles.lifetime = 1.6
	_particles.emitting = false
	_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE_SURFACE
	_particles.emission_sphere_radius = radius * (2.2 if _sprite else 1.0)
	_particles.direction = Vector2(0, -1)
	_particles.spread = 180.0
	_particles.gravity = Vector2(0, -20)
	_particles.initial_velocity_min = 10.0
	_particles.initial_velocity_max = 40.0
	_particles.scale_amount_min = 2.0
	_particles.scale_amount_max = 4.0
	var ramp := Gradient.new()
	ramp.set_color(0, Color(CORE, 0.9))
	ramp.set_color(1, Color(RIM, 0.0))
	_particles.color_ramp = ramp
	add_child(_particles)
	_base_pos = position


## 把動圖切成 24 格做成動畫（保持像素風，不模糊）
func _build_sprite() -> void:
	if not ResourceLoader.exists(SHEET):
		return
	var sheet: Texture2D = load(SHEET)
	var fw := sheet.get_width() / SHEET_FRAMES
	var fh := sheet.get_height()
	var frames := SpriteFrames.new()
	frames.add_animation("float")
	frames.set_animation_loop("float", true)
	frames.set_animation_speed("float", SHEET_FPS)
	for i in SHEET_FRAMES:
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(i * fw, 0, fw, fh)
		frames.add_frame("float", atlas)
	if frames.has_animation("default"):
		frames.remove_animation("default")
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = frames
	_sprite.animation = "float"
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var mat := ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = BLUR_SHADER
	mat.shader = shader
	_sprite.material = mat
	_sprite.position = size / 2.0
	_sprite.scale = Vector2.ONE * _sprite_scale
	add_child(_sprite)
	_sprite.play("float")


## 動圖顯示的大小（1.0 = 原圖 391 像素高）
func set_sprite_scale(s: float) -> void:
	_sprite_scale = s
	if _sprite:
		_sprite.scale = Vector2.ONE * s


## 模糊程度（0 = 清楚；第一章用 10 左右）。模糊時也稍微透明，像一團看不清的光
func set_blur(amount: float) -> void:
	_blur = maxf(amount, 0.0)
	if _sprite:
		_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR if _blur > 0.0 else CanvasItem.TEXTURE_FILTER_NEAREST
		(_sprite.material as ShaderMaterial).set_shader_parameter("radius", _blur)


func place(pos: Vector2, sprite_scale: float = -1.0) -> void:
	position = pos - size / 2.0
	_base_pos = position
	if sprite_scale > 0.0:
		set_sprite_scale(sprite_scale)


func set_mood(new_mood: String) -> void:
	mood = new_mood
	_particles.emitting = mood in ["sad", "fading"] or fade < 0.95


func speak(on: bool) -> void:
	_speaking = on


func set_fade(value: float) -> void:
	fade = clampf(value, 0.0, 1.0)
	_particles.emitting = fade < 0.95 or mood in ["sad", "fading"]


func _process(delta: float) -> void:
	_t += delta
	var target := 0.8
	# 動圖本身就在飄浮，程式這邊的上下浮動小一點
	var bob := sin(_t * 1.6) * (3.0 if _sprite else 8.0)
	var s := 1.0
	var anim_speed := 1.0
	match mood:
		"happy":
			target = 1.1
			bob = -absf(sin(_t * 5.0)) * (10.0 if _sprite else 18.0)
			anim_speed = 1.4
		"worried":
			target = 0.45
			s = 0.92 if _sprite else 0.8
			anim_speed = 0.6
		"wise":
			anim_speed = 0.7
		"sad":
			target = 0.55
			anim_speed = 0.7
		"fading":
			target = 0.5 + 0.4 * absf(sin(_t * 3.3))  # 晚年：光忽明忽暗
			anim_speed = 0.8
	if _speaking:
		target += 0.3
	brightness = lerpf(brightness, target, delta * 4.0)
	scale = scale.lerp(Vector2(s, s), delta * 4.0)
	position = _base_pos + Vector2(0, bob)
	# 模糊時稍微透明（最多淡到 0.65）
	modulate.a = fade * (1.0 - minf(_blur / 30.0, 0.35))
	if _sprite:
		_sprite.speed_scale = anim_speed
		# 說話、開心時亮一點；擔心時暗一點
		var lum := clampf(0.55 + brightness * 0.5, 0.6, 1.25)
		_sprite.modulate = Color(lum, lum, lum, 1.0)
	queue_redraw()


func _draw() -> void:
	var c := size / 2.0
	if _sprite:
		# 動圖背後淡淡的藍黃光暈（程式＝光）
		var r := 391.0 * _sprite_scale * 0.45
		for i in range(10, 0, -1):
			var k := float(i) / 10.0
			var col := RIM.lerp(CORE, 1.0 - k)
			draw_circle(c, r * (0.4 + k * 0.8), Color(col, 0.016 * brightness))
		return
	# ---------- 沒有動圖時：程式畫的光球 ----------
	# 外圈光暈
	for i in range(6, 0, -1):
		var k := float(i) / 6.0
		draw_circle(c, radius * (1.0 + k * 0.9), Color(RIM, 0.05 * brightness * (1.0 - k * 0.5)))
	# 本體：外藍內黃
	for i in range(10):
		var k := float(i) / 9.0
		var col := RIM.lerp(CORE, k)
		col = col.lightened(0.15 * (brightness - 0.8))
		draw_circle(c, radius * (1.0 - k * 0.75), col)
	draw_circle(c + Vector2(-radius * 0.3, -radius * 0.35), radius * 0.18, Color(1, 1, 1, 0.35 * brightness))
	# 眼睛（說大道理時慢慢左右轉，像在轉身）
	var look := sin(_t * 0.6) * radius * 0.12 if mood == "wise" else 0.0
	var blink := 0.15 if fmod(_t, 4.2) < 0.12 else 1.0
	for side in [-1.0, 1.0]:
		var e := c + Vector2(side * radius * 0.28 + look, -radius * 0.05)
		draw_set_transform(e, 0.0, Vector2(1.0, blink))
		draw_circle(Vector2.ZERO, radius * 0.1, EYE)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
