class_name UIKit
extends RefCounted

## 共用樣式工具（畫面設定書 第一節／第六節）：
## - 對話文字不小於 28px、程式碼不小於 22px
## - 中文用思源黑體／Noto Sans TC，程式碼用等寬字體
## 把字型檔放到 assets/fonts/ 就會自動使用；沒放就用系統字型。

const DIALOGUE_SIZE := 30
const CODE_SIZE := 24
const UI_SIZE := 24
const SMALL_SIZE := 20

# 舊版風格（ThemeManager）：捷運藍、亮黃、米色、深藍對話框
const NAVY := Color(0.117647, 0.164706, 0.219608, 0.9)
const GOLD := Color("#F8D08D")
const MRT_BLUE := Color("#2D529E")
const BEIGE := Color("#D9D0C1")
const CREAM := Color("#fffaf0")
const TEXT_LIGHT := Color("#f2f5f8")
const STAMP_RED := Color("#c0392b")

const PY_BLUE := Color("#3d7fd6")

## 全遊戲統一的「繼續」：空白鍵，等待時都顯示這句提示
const CONTINUE_HINT := "▼ 按空白鍵繼續"


static func is_continue_key(event: InputEvent) -> bool:
	return event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]
const PY_YELLOW := Color("#ffd75e")
const INK := Color("#1e2a38")
const PAPER := Color(1, 1, 1, 0.86)
const RUN_GREEN := Color("#3aa564")
const HINT_YELLOW := Color("#f0b429")
const RESET_GRAY := Color("#8a939c")

const BODY_FONT_FILES := ["res://assets/fonts/NotoSansTC-Regular.ttf", "res://assets/fonts/NotoSansTC-Regular.otf",
	"res://assets/fonts/SourceHanSansTC-Regular.otf"]
const MONO_FONT_FILES := ["res://assets/fonts/JetBrainsMono-Regular.ttf", "res://assets/fonts/Consolas.ttf"]

static var _body: Font
static var _mono: Font
static var _italic: Font


static func body_font() -> Font:
	if _body == null:
		_body = _load_first(BODY_FONT_FILES)
		if _body == null:
			var sf := SystemFont.new()
			sf.font_names = PackedStringArray(["Noto Sans TC", "PingFang TC", "Microsoft JhengHei", "Heiti TC", "sans-serif"])
			_body = sf
	return _body


static func mono_font() -> Font:
	if _mono == null:
		var f := _load_first(MONO_FONT_FILES)
		if f == null:
			var sf := SystemFont.new()
			sf.font_names = PackedStringArray(["JetBrains Mono", "Consolas", "Menlo", "Monaco", "monospace"])
			f = sf
		# 程式碼裡的中文字串交給中文字型
		f.fallbacks = [body_font()]
		_mono = f
	return _mono


## 旁白用的斜體（用 FontVariation 斜切，任何字型都能用）
static func italic_font() -> Font:
	if _italic == null:
		var fv := FontVariation.new()
		fv.base_font = body_font()
		fv.variation_transform = Transform2D(Vector2(1, 0), Vector2(0.2, 1), Vector2.ZERO)
		_italic = fv
	return _italic


static func _load_first(paths: Array) -> Font:
	for p in paths:
		if ResourceLoader.exists(p):
			return load(p)
	return null


static func box(bg: Color, radius: int = 16, border: Color = Color.TRANSPARENT, border_w: int = 0, pad: int = 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	if border_w > 0:
		sb.border_color = border
		sb.set_border_width_all(border_w)
	if pad > 0:
		sb.set_content_margin_all(pad)
	return sb


## 舊版對話框樣式：深藍半透明、金色細邊、圓角、淡陰影
static func navy_panel(radius: int = 10, pad: int = 0) -> StyleBoxFlat:
	var sb := box(NAVY, radius, GOLD, 2, pad)
	sb.shadow_color = Color(0, 0, 0, 0.3)
	sb.shadow_size = 5
	sb.shadow_offset = Vector2(2, 2)
	return sb


## 舊版名字牌：捷運藍底、金色邊
static func name_plate(color: Color = MRT_BLUE) -> StyleBoxFlat:
	var sb := box(Color(color, 0.95), 8, GOLD, 2)
	sb.content_margin_left = 22
	sb.content_margin_right = 22
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	return sb


## 舊版的像素電路板框圖做成 nine-patch：四個角與邊框不變形，只拉伸中間
static func texture_box(texture_path: String, margin: int, content_pad: int = -1) -> StyleBox:
	if not ResourceLoader.exists(texture_path):
		return navy_panel(10, maxi(content_pad, 16))
	var sb := StyleBoxTexture.new()
	sb.texture = load(texture_path)
	sb.texture_margin_left = margin
	sb.texture_margin_right = margin
	sb.texture_margin_top = margin
	sb.texture_margin_bottom = margin
	var pad := content_pad if content_pad >= 0 else margin
	sb.content_margin_left = pad
	sb.content_margin_right = pad
	sb.content_margin_top = pad
	sb.content_margin_bottom = pad
	return sb


## 劇情為主的四象限版面（沿用舊版 section_1 的配置）
## 左上：劇情區（場景＋對話框，劇情不中斷）｜右上：程式區
## 左下：物件區（任務卡／清單）　　　　　　｜右下：輸出區
const SPLIT_STORY := Rect2(20, 20, 780, 580)
const SPLIT_OBJECT := Rect2(20, 620, 780, 440)
const SPLIT_CODE := Rect2(820, 96, 1080, 580)
const SPLIT_FEEDBACK := Rect2(820, 696, 1080, 364)
## 劇情區裡的對話框（下面留一條給「跟派森聊天」的輸入框）
const SPLIT_DIALOGUE := Rect2(36, 356, 748, 172)


static func label(text: String, size: int = UI_SIZE, color: Color = INK) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", body_font())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


static func rich(size: int = DIALOGUE_SIZE, color: Color = INK) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.add_theme_font_override("normal_font", body_font())
	r.add_theme_font_override("italics_font", italic_font())
	r.add_theme_font_override("mono_font", mono_font())
	r.add_theme_font_size_override("normal_font_size", size)
	r.add_theme_font_size_override("italics_font_size", size)
	r.add_theme_font_size_override("mono_font_size", CODE_SIZE)
	r.add_theme_color_override("default_color", color)
	return r


static func button(text: String, bg: Color, fg: Color = Color.WHITE, size: int = UI_SIZE) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_override("font", body_font())
	b.add_theme_font_size_override("font_size", size)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(state, fg)
	b.add_theme_color_override("font_disabled_color", Color(fg, 0.5))
	b.add_theme_stylebox_override("normal", box(bg, 10, Color(GOLD, 0.55), 2, 12))
	b.add_theme_stylebox_override("hover", box(bg.lightened(0.15), 10, GOLD, 3, 12))
	b.add_theme_stylebox_override("pressed", box(bg.darkened(0.15), 10, GOLD, 2, 12))
	b.add_theme_stylebox_override("disabled", box(Color(bg, 0.45), 10, Color.TRANSPARENT, 0, 12))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return b


static func full_rect(c: Control) -> Control:
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.offset_left = 0
	c.offset_top = 0
	c.offset_right = 0
	c.offset_bottom = 0
	return c


## Python 語法上色（畫面設定書 2.2：關鍵字粉紅、字串綠、數字黃、函式藍）
static func python_highlighter() -> CodeHighlighter:
	var h := CodeHighlighter.new()
	h.number_color = Color("#f5d76e")
	h.symbol_color = Color("#c7d0db")
	h.function_color = Color("#6cb6ff")
	h.member_variable_color = Color("#e6edf3")
	var kw := Color("#ff7ab8")
	for k in ["False", "None", "True", "and", "as", "break", "class", "continue", "def", "elif", "else", "except",
			"finally", "for", "from", "if", "import", "in", "is", "not", "or", "pass", "return", "try", "while", "with"]:
		h.add_keyword_color(k, kw)
	for b in ["print", "len", "range", "int", "float", "str", "round", "sum", "type", "input", "list", "dict"]:
		h.add_keyword_color(b, Color("#6cb6ff"))
	h.add_color_region("\"", "\"", Color("#7ee787"), true)
	h.add_color_region("'", "'", Color("#7ee787"), true)
	h.add_color_region("#", "", Color("#8b98a5"), true)
	return h


## 深色程式編輯器（memory = true 時改成回憶模式的深藍色主題）
static func code_editor(memory: bool = false, editable: bool = true) -> CodeEdit:
	var ce := CodeEdit.new()
	ce.syntax_highlighter = python_highlighter()
	ce.gutters_draw_line_numbers = true
	ce.indent_use_spaces = true
	ce.indent_size = 4
	ce.indent_automatic = true
	ce.auto_brace_completion_enabled = true
	ce.editable = editable
	ce.scroll_fit_content_height = not editable
	ce.add_theme_font_override("font", mono_font())
	ce.add_theme_font_size_override("font_size", CODE_SIZE)
	var bg := Color("#14213f") if memory else Color("#1b1f27")
	ce.add_theme_stylebox_override("normal", box(bg, 12, Color.TRANSPARENT, 0, 14))
	ce.add_theme_stylebox_override("read_only", box(bg, 12, Color.TRANSPARENT, 0, 14))
	ce.add_theme_stylebox_override("focus", box(Color.TRANSPARENT, 12, PY_BLUE, 2))
	ce.add_theme_color_override("font_color", Color("#e6edf3"))
	ce.add_theme_color_override("font_readonly_color", Color("#e6edf3"))
	ce.add_theme_color_override("line_number_color", Color("#5c6773"))
	ce.add_theme_color_override("caret_color", PY_YELLOW)
	ce.add_theme_color_override("current_line_color", Color(1, 1, 1, 0.04))
	ce.add_theme_color_override("selection_color", Color(PY_BLUE, 0.4))
	return ce


static func fade(node: CanvasItem, to: float, dur: float = 0.3) -> Tween:
	var t := node.create_tween()
	t.tween_property(node, "modulate:a", to, dur)
	return t
