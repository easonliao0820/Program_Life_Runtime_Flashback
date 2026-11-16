extends TextureRect

## 播放 PixelLab 匯出的 sprite sheet（一列橫排、每格一樣大）。
## 用在：動態背景（<背景>_anim.png）、背景上的小動畫（fx/<名稱>.png）、角色待機動畫（<角色>_idle.png）。
## 每一格切成獨立的貼圖（不是 AtlasTexture），所以調色 shader 的 UV 一樣是 0～1，跟靜態圖相同。

var frames: Array[Texture2D] = []
var fps: float = 8.0
## 播完一輪後停在第一格多久（秒，隨機範圍）。角色眨眼用：大部分時間睜眼，偶爾眨一下。
var hold_min: float = 0.0
var hold_max: float = 0.0

var _i: int = 0
var _t: float = 0.0
var _hold: float = 0.0


## 把 sheet 切成 count 格；count <= 0 時用 frame_w 算格數（frame_w <= 0 時用正方形格子）
static func slice(sheet: Texture2D, count: int = 0, frame_w: int = 0) -> Array[Texture2D]:
	var out: Array[Texture2D] = []
	if sheet == null:
		return out
	var img := sheet.get_image()
	if img == null:
		return out
	if img.is_compressed():
		img.decompress()
	var w := img.get_width()
	var h := img.get_height()
	if count <= 0:
		var fw := frame_w if frame_w > 0 else h
		count = maxi(1, roundi(float(w) / float(fw)))
	var cw := w / count
	for i in count:
		out.append(ImageTexture.create_from_image(img.get_region(Rect2i(i * cw, 0, cw, h))))
	return out


func setup(p_frames: Array[Texture2D], p_fps: float = 8.0, p_hold_min: float = 0.0, p_hold_max: float = 0.0) -> void:
	frames = p_frames
	fps = p_fps
	hold_min = p_hold_min
	hold_max = p_hold_max
	_i = 0
	_t = 0.0
	_hold = randf_range(hold_min, hold_max)
	texture = frames[0] if not frames.is_empty() else null
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(frames.size() > 1)


func _process(delta: float) -> void:
	if _i == 0 and _hold > 0.0:
		_hold -= delta
		return
	_t += delta
	var step := 1.0 / maxf(fps, 0.1)
	while _t >= step:
		_t -= step
		_i = (_i + 1) % frames.size()
		if _i == 0:
			_hold = randf_range(hold_min, hold_max)
	texture = frames[_i]
