extends Control

## 名字輸入畫面（畫面設定書 2.5）：遊戲一開始，在畫面中央輸入名字（{userName}），
## 設定書原本是全白畫面，太刺眼；改成「胎中」：背景是 assets/images/worm.jpeg（像素風的子宮內部），
## 圖片會隨著心跳輕輕「呼吸」，接著才是第一章的睜眼。
## 背景有微弱的心跳聲（assets/audio/heartbeat.ogg，沒有檔案時只播放脈動動畫）。
## 有存檔時多一個「繼續旅程」按鈕。

## 胎中的背景圖與配色（配合 worm.jpeg 的橘紅色調）
const WOMB_IMAGE := "res://assets/images/worm.jpeg"
## 背景圖模糊程度（0 = 不模糊；數字越大越糊）
const WOMB_BLUR := 16.0
## 暗角暈影（Vignette）：四周往深酒紅色暗下去，視線集中在中間的光
const VIGNETTE_STRENGTH := 0.85   # 0 = 沒有暗角；1 = 邊緣幾乎全暗
const VIGNETTE_COLOR := Color("#2a0907")

const VIGNETTE_SHADER := """
shader_type canvas_item;
uniform float strength = 0.85;
uniform vec4 tint : source_color = vec4(0.16, 0.035, 0.03, 1.0);
void fragment() {
	// 依畫面長寬比修正，讓暗角是橢圓而不是被拉扁
	vec2 uv = (UV - 0.5) * vec2(1.0, 0.8);
	float d = length(uv);
	float v = smoothstep(0.22, 0.72, d) * strength;
	COLOR = vec4(tint.rgb, v);
}
"""

## 模糊背景圖：在圖上取周圍 7×7 個點加權平均；brightness 讓心跳時微微變亮
const BLUR_SHADER := """
shader_type canvas_item;
uniform float radius = 6.0;
uniform float brightness = 1.0;
void fragment() {
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
	vec4 c = sum / total;
	COLOR = vec4(c.rgb * brightness, c.a);
}
"""
const WOMB_DARK := Color("#2a0d06")      # 沒有圖時的底色：很深的紅褐
const WOMB_GLOW := Color("#ffb066")      # 心跳光暈：暖橘
const WOMB_TEXT := Color("#fff1e0")      # 文字：奶油白
const WOMB_ROSE := Color("#f2a65a")      # 底線、游標、按鈕邊框：琥珀
const WOMB_BTN := Color("#9c3412")       # 主要按鈕：暗橘紅
const WOMB_BTN_DIM := Color("#4a1709")   # 次要按鈕：深鏽紅

var _input: LineEdit
var _pulse: Control
var _womb: TextureRect
var _t: float = 0.0


func _ready() -> void:
	UIKit.full_rect(self)
	var bg := ColorRect.new()
	bg.color = WOMB_DARK
	UIKit.full_rect(bg)
	add_child(bg)

	# 胎中的背景圖：模糊處理（像在肚子裡看出去朦朦朧朧的），隨心跳輕輕縮放
	if ResourceLoader.exists(WOMB_IMAGE):
		_womb = TextureRect.new()
		UIKit.full_rect(_womb)
		_womb.texture = load(WOMB_IMAGE)
		_womb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_womb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		_womb.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		var mat := ShaderMaterial.new()
		var shader := Shader.new()
		shader.code = BLUR_SHADER
		mat.shader = shader
		mat.set_shader_parameter("radius", WOMB_BLUR)
		_womb.material = mat
		_womb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_womb)

	# 暗角暈影：蓋在背景圖上、輸入框下面
	var vignette := ColorRect.new()
	UIKit.full_rect(vignette)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vmat := ShaderMaterial.new()
	var vshader := Shader.new()
	vshader.code = VIGNETTE_SHADER
	vmat.shader = vshader
	vmat.set_shader_parameter("strength", VIGNETTE_STRENGTH)
	vmat.set_shader_parameter("tint", VIGNETTE_COLOR)
	vignette.material = vmat
	add_child(vignette)

	_pulse = Pulse.new()
	UIKit.full_rect(_pulse)
	add_child(_pulse)

	var center := CenterContainer.new()
	UIKit.full_rect(center)
	add_child(center)
	# 輸入區後面一塊半透明的深紅底，讓文字在圖上也看得清楚
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIKit.box(Color(0.36, 0.11, 0.1, 0.66), 18, Color(WOMB_ROSE, 0.45), 2, 40))
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 28)
	v.custom_minimum_size = Vector2(720, 0)
	panel.add_child(v)

	var q := UIKit.label("你叫什麼名字？", 40, WOMB_TEXT)
	q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(q)
	_input = LineEdit.new()
	_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_input.max_length = 12
	_input.placeholder_text = "輸入名字"
	_input.custom_minimum_size = Vector2(720, 84)
	_input.add_theme_font_override("font", UIKit.body_font())
	_input.add_theme_font_size_override("font_size", 40)
	_input.add_theme_color_override("font_color", WOMB_TEXT)
	_input.add_theme_color_override("font_placeholder_color", Color(WOMB_TEXT, 0.35))
	_input.add_theme_color_override("caret_color", WOMB_ROSE)
	_input.add_theme_stylebox_override("normal", UIKit.box(Color(0, 0, 0, 0), 0, Color.TRANSPARENT, 0, 10))
	_input.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_input.text_submitted.connect(func(_t2: String): _start_new())
	v.add_child(_input)
	var underline := ColorRect.new()
	underline.color = Color(WOMB_ROSE, 0.75)
	underline.custom_minimum_size = Vector2(720, 3)
	v.add_child(underline)

	var start := _womb_button("開始", WOMB_BTN)
	start.custom_minimum_size = Vector2(0, 70)
	start.pressed.connect(_start_new)
	v.add_child(start)

	if GameState.has_save():
		var data_ok := GameState.load_game()
		if data_ok:
			var sec := ChapterRegistry.get_section(GameState.section_id)
			var cont := _womb_button("繼續旅程：%s（%s）" % [GameState.user_name, sec.get("title", "")], WOMB_BTN_DIM)
			cont.custom_minimum_size = Vector2(0, 70)
			cont.pressed.connect(GameFlow.continue_game)
			v.add_child(cont)
			var map_btn := _womb_button("記憶地圖（MEMORY LOAD）", WOMB_BTN_DIM)
			map_btn.custom_minimum_size = Vector2(0, 70)
			map_btn.pressed.connect(GameFlow.open_map)
			v.add_child(map_btn)
			_input.placeholder_text = "輸入新名字，重新開始"

	_input.grab_focus.call_deferred()
	var hb := "res://assets/audio/heartbeat.ogg"
	if ResourceLoader.exists(hb):
		var p := AudioStreamPlayer.new()
		p.stream = load(hb)
		p.volume_db = -14
		add_child(p)
		p.play()


## 心跳：「咚、咚」兩下一組，背景圖跟著輕輕放大、變亮，像在呼吸
func _process(delta: float) -> void:
	_t += delta
	if _womb == null:
		return
	var k := _beat(_t)
	_womb.pivot_offset = _womb.size / 2.0
	_womb.scale = Vector2.ONE * (1.0 + 0.012 * k)
	(_womb.material as ShaderMaterial).set_shader_parameter("brightness", 1.0 + 0.08 * k)


static func _beat(t: float) -> float:
	var beat := fmod(t, 1.1)
	return clampf(exp(-beat * 6.0) + 0.6 * exp(-absf(beat - 0.25) * 12.0), 0.0, 1.0)


func _womb_button(text: String, bg: Color) -> Button:
	var b := UIKit.button(text, bg, WOMB_TEXT)
	b.add_theme_stylebox_override("normal", UIKit.box(bg, 12, Color(WOMB_ROSE, 0.5), 2, 12))
	b.add_theme_stylebox_override("hover", UIKit.box(bg.lightened(0.12), 12, WOMB_ROSE, 3, 12))
	b.add_theme_stylebox_override("pressed", UIKit.box(bg.darkened(0.15), 12, WOMB_ROSE, 2, 12))
	return b


func _start_new() -> void:
	var n := _input.text.strip_edges()
	if n == "":
		_input.placeholder_text = "要先告訴我你的名字喔"
		return
	GameFlow.new_game(n)


## 心跳光暈：畫面中央淡淡的暖橘色光，隨著「咚、咚」兩下一組的心跳脈動
class Pulse extends Control:
	var _t: float = 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var beat := fmod(_t, 1.1)
		var k := exp(-beat * 6.0) + 0.6 * exp(-absf(beat - 0.25) * 12.0)
		var c := size / 2.0
		# 圈數多、每圈很淡，疊起來才是平滑的光暈，不會看到一圈一圈的分層（疊在背景圖上，很淡）
		for i in range(24, 0, -1):
			draw_circle(c, 80.0 + i * 26.0 + k * 30.0, Color(WOMB_GLOW, 0.006 * k))
