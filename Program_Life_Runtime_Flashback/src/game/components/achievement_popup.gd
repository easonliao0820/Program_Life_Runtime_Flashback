extends Control

## 成就彈窗（畫面設定書 2.5）：畫面上方滑下的金色橫條，左邊一個獎章圖示，
## 例如「成就：第一次算數」，停留約 3 秒。也拿來顯示「已存檔」這類短提示。
## 台灣風格：獎章做成紅色圓印章（像蓋在獎狀上的「成就」印），橫條是米色紙＋金邊。

var _queue: Array = []
var _busy: bool = false


func _ready() -> void:
	UIKit.full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func show_achievement(achievement_id: String) -> void:
	_queue.append({"title": "成就：" + achievement_id, "gold": true})
	_pump()


func toast(text: String) -> void:
	_queue.append({"title": text, "gold": false})
	_pump()


func _pump() -> void:
	if _busy or _queue.is_empty():
		return
	_busy = true
	var item: Dictionary = _queue.pop_front()
	var bar := PanelContainer.new()
	var gold: bool = item["gold"]
	bar.add_theme_stylebox_override("panel", UIKit.box(Color("#fbf3dc") if gold else UIKit.NAVY, 10,
		UIKit.GOLD, 3 if gold else 2, 16))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	bar.add_child(row)
	if gold:
		var medal := Medal.new()
		medal.custom_minimum_size = Vector2(64, 64)
		row.add_child(medal)
	var l := UIKit.label(item["title"], 30, UIKit.INK if gold else Color.WHITE)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(l)
	add_child(bar)
	await get_tree().process_frame
	bar.position = Vector2((1920 - bar.size.x) / 2.0, -bar.size.y - 10)
	var t := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(bar, "position:y", 30.0, 0.45)
	t.tween_interval(4.0 if gold else 2.0)
	t.tween_property(bar, "position:y", -bar.size.y - 10, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await t.finished
	bar.queue_free()
	_busy = false
	_pump()


## 紅色圓印章，中間寫「成就」
class Medal extends Control:
	func _draw() -> void:
		var c := size / 2.0
		var r := size.x / 2.0
		draw_circle(c, r, UIKit.STAMP_RED)
		draw_circle(c, r - 4, Color("#fbf3dc"))
		draw_circle(c, r - 7, UIKit.STAMP_RED)
		var font := UIKit.body_font()
		for i in 2:
			var ch := "成就"[i]
			var w := font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
			draw_string(font, Vector2(c.x - w / 2.0, c.y - 4 + i * 24), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("#fbf3dc"))
