extends Control

## 派森（畫面設定書 第三節）
## 一顆圓潤、會飄浮的光球：中心暖黃、外圈漸層成藍色，只有兩顆深藍色小眼睛、沒有嘴巴。
## 情緒靠光表現：開心變亮彈跳、擔心變暗縮小、說大道理緩慢轉動、難過邊緣散出光點。
## 正式美術完成前都用程式畫；之後可換成 AnimatedSprite，但請保留 set_mood / speak 介面。

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


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(radius * 4, radius * 4)
	size = custom_minimum_size
	pivot_offset = size / 2.0
	_particles = CPUParticles2D.new()
	_particles.position = size / 2.0
	_particles.amount = 24
	_particles.lifetime = 1.6
	_particles.emitting = false
	_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE_SURFACE
	_particles.emission_sphere_radius = radius
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


func place(pos: Vector2) -> void:
	position = pos - size / 2.0
	_base_pos = position


func set_mood(new_mood: String) -> void:
	mood = new_mood
	_particles.emitting = mood in ["sad", "fading"]


func speak(on: bool) -> void:
	_speaking = on


func set_fade(value: float) -> void:
	fade = clampf(value, 0.0, 1.0)
	_particles.emitting = fade < 0.95 or mood in ["sad", "fading"]


func _process(delta: float) -> void:
	_t += delta
	var target := 0.8
	var bob := sin(_t * 1.6) * 8.0
	var s := 1.0
	match mood:
		"happy":
			target = 1.1
			bob = -absf(sin(_t * 5.0)) * 18.0
		"worried":
			target = 0.45
			s = 0.8
		"sad":
			target = 0.55
		"fading":
			target = 0.5 + 0.4 * absf(sin(_t * 3.3))  # 晚年：光忽明忽暗
	if _speaking:
		target += 0.3
	brightness = lerpf(brightness, target, delta * 4.0)
	scale = scale.lerp(Vector2(s, s), delta * 4.0)
	position = _base_pos + Vector2(0, bob)
	modulate.a = fade
	queue_redraw()


func _draw() -> void:
	var c := size / 2.0
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
