extends Control

## 探索模式（畫面設定書 2.3）：2.1 找回憶盒子、3.1 整理書包、3.4 學測當天行前檢查。
## - 俯視的房間，直接點擊物品；可互動物品用藍黃光圈標示，放進 list 的物品變淡並打勾
## - 右側面板即時顯示 Python 的 list，點物品時自動長出一行 bag.append(...)
## - 容量條：接近上限變橘色，超過變紅並提示「跑不快」
## - 倒數計時（3.1 捷運進站）
## 結果：GameState 的 <list 名稱> 變數存放最後的清單，explore_code 存放整段產生的程式碼。
## 版面跟程式關卡一樣是四象限：左上劇情區（GameStage 保留）、右邊房間、左下 Python 清單面板。

signal _done

## GameStage 提供：func(text: String, mood: String) —— 讓派森在劇情區的對話框裡說話
var speak: Callable

var _def: Dictionary = {}
var _room: Control
var _room_title: Label
var _list_view: RichTextLabel
var _code_view: RichTextLabel
var _capacity_bar: ProgressBar
var _capacity_label: Label
var _timer_label: Label
var _note: Label
var _confirm: Button

var _items: Array = []         ## 目前清單內容
var _code_lines: Array = []    ## 依點擊順序產生的程式碼
var _found: Dictionary = {}    ## 已點過的物品（自訂程式碼模式用）
var _buttons: Dictionary = {}
var _time_left: float = 0.0
var _running: bool = false


func _ready() -> void:
	UIKit.full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# 右邊：俯視的房間（木地板色、舊版金邊）
	_room = Panel.new()
	_room.position = UIKit.SPLIT_CODE.position
	_room.size = Vector2(UIKit.SPLIT_CODE.size.x, UIKit.SPLIT_FEEDBACK.end.y - UIKit.SPLIT_CODE.position.y)
	_room.add_theme_stylebox_override("panel", UIKit.box(Color("#e9dcc6"), 10, UIKit.GOLD, 3))
	add_child(_room)
	_room_title = UIKit.label("", 30, UIKit.INK)
	_room_title.position = Vector2(30, 20)
	_room.add_child(_room_title)

	# 左下：Python 清單面板（點物品時即時長出程式碼）
	var side := PanelContainer.new()
	side.position = UIKit.SPLIT_OBJECT.position
	side.size = UIKit.SPLIT_OBJECT.size
	side.add_theme_stylebox_override("panel", UIKit.navy_panel(10, 18))
	add_child(side)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	side.add_child(v)
	_list_view = UIKit.rich(22, UIKit.GOLD)
	_list_view.add_theme_font_override("normal_font", UIKit.mono_font())
	v.add_child(_list_view)
	var cap_row := HBoxContainer.new()
	v.add_child(cap_row)
	_capacity_bar = ProgressBar.new()
	_capacity_bar.custom_minimum_size = Vector2(440, 28)
	_capacity_bar.show_percentage = false
	cap_row.add_child(_capacity_bar)
	_capacity_label = UIKit.label("", 22, Color.WHITE)
	cap_row.add_child(_capacity_label)
	_timer_label = UIKit.label("", 26, UIKit.GOLD)
	v.add_child(_timer_label)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	_code_view = UIKit.rich(22, Color("#e6edf3"))
	_code_view.add_theme_font_override("normal_font", UIKit.mono_font())
	_code_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_code_view)
	_note = UIKit.label("", 22, Color("#ffd2c8"))
	_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_note)
	_confirm = UIKit.button("確認", UIKit.RUN_GREEN)
	_confirm.custom_minimum_size = Vector2(0, 52)
	_confirm.pressed.connect(_on_confirm)
	v.add_child(_confirm)
	visible = false


func play(def: Dictionary) -> Dictionary:
	_def = def
	_items = (def.get("start", []) as Array).duplicate()
	_code_lines = []
	_found = {}
	_room_title.text = GameState.format_text(str(def.get("title", "")))
	_confirm.text = "%s（空白鍵）" % str(def.get("confirm", "確認"))
	_note.text = ""
	_say(GameState.format_text(str(def.get("goal", ""))))
	_time_left = float(def.get("timer", 0))
	_timer_label.visible = _time_left > 0
	var cap := int(def.get("capacity", 0))
	_capacity_bar.get_parent().visible = cap > 0
	_capacity_bar.max_value = maxi(cap, 1)

	for c in _room.get_children():
		if c != _room_title:
			c.queue_free()
	_buttons.clear()
	# 一開始就在清單裡的東西（例如書包裡的漫畫）也放在房間裡，點了可以拿出來
	var entries: Array = []
	for start_item in def.get("start", []):
		entries.append({"name": start_item, "code": "", "note": ""})
	entries.append_array(def.get("items", []))
	for i in entries.size():
		var entry: Dictionary = entries[i]
		var b := ItemSpot.new()
		b.item_name = entry["name"]
		b.position = _spot_position(i, entries.size())
		b.pressed_item.connect(_on_item.bind(entry))
		_room.add_child(b)
		_buttons[entry["name"]] = b
	_refresh()

	visible = true
	_running = true
	modulate.a = 0.0
	UIKit.fade(self, 1.0, 0.3)
	if GameFlow.autopilot:
		_done.emit.call_deferred()
	await _done
	_running = false
	var t := UIKit.fade(self, 0.0, 0.25)
	await t.finished
	visible = false

	var list_name := str(def.get("list", ""))
	if list_name != "" and not _uses_custom_code():
		GameState.set_value(list_name, _items.duplicate())
	GameState.set_value("explore_code", _full_code())
	return {"items": _items.duplicate(), "code": _full_code()}


func _uses_custom_code() -> bool:
	for e in _def.get("items", []):
		if str(e.get("code", "")) != "":
			return true
	return false


## 物品位置：在房間裡大致平均分散（固定亂數，每次進來位置一樣）
func _spot_position(i: int, n: int) -> Vector2:
	var cols := 3 if n > 4 else 2
	var rows := ceili(float(n) / cols)
	var cell := Vector2((_room.size.x - 100.0) / cols, (_room.size.y - 180.0) / maxi(rows, 1))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(_def.get("id", "")) + str(i))
	var base := Vector2(50, 110) + Vector2(i % cols, i / cols) * cell
	return base + Vector2(rng.randf_range(0, cell.x - 260), rng.randf_range(0, cell.y - 150)).max(Vector2.ZERO)


func _on_item(entry: Dictionary) -> void:
	if not _running:
		return
	var item_name: String = entry["name"]
	var custom := str(entry.get("code", ""))
	var list_name := str(_def.get("list", "bag"))
	if custom != "":
		# 2.1 回憶盒子：每個盒子對應一行程式碼，打開就寫進去
		if _found.has(item_name):
			return
		_found[item_name] = true
		_code_lines.append(GameState.format_text(custom))
		if str(entry.get("note", "")) != "":
			_say("【%s】%s" % [item_name, GameState.format_text(entry["note"])])
	elif _items.has(item_name):
		_items.erase(item_name)
		_code_lines.append('%s.remove("%s")' % [list_name, item_name])
	else:
		_items.append(item_name)
		_code_lines.append('%s.append("%s")' % [list_name, item_name])
	_refresh()


func _refresh() -> void:
	var list_name := str(_def.get("list", "bag"))
	var cap := int(_def.get("capacity", 0))
	if _uses_custom_code():
		_list_view.text = "找到的回憶盒子：%d / %d" % [_found.size(), (_def.get("items", []) as Array).size()]
	else:
		var quoted: Array = []
		for it in _items:
			quoted.append("\"%s\"" % it)
		_list_view.text = "%s = [%s]" % [list_name, ", ".join(quoted)]
		var hidden := int(_def.get("hidden_count", 0))
		if hidden > 0:
			_list_view.text += "\n[color=#8b98a5]（簡章上一共有 %d 樣東西要帶）[/color]" % hidden
	_code_view.text = "[color=#8b98a5]# 你的每個動作，都會變成一行程式[/color]\n" + _escape(_full_code())
	_scroll_code_to_end.call_deferred()

	for key in _buttons:
		var b: ItemSpot = _buttons[key]
		b.taken = _items.has(key) or _found.has(key)
		b.queue_redraw()

	if cap > 0:
		_capacity_bar.value = mini(_items.size(), cap)
		_capacity_label.text = "  %d / %d" % [_items.size(), cap]
		var col := UIKit.RUN_GREEN
		if _items.size() > cap:
			col = Color("#d9534f")
			_note.text = "東西太多了，跑不快！"
		elif _items.size() == cap:
			col = Color("#f0932b")
		var fill := UIKit.box(col, 8)
		_capacity_bar.add_theme_stylebox_override("fill", fill)
		_capacity_bar.add_theme_stylebox_override("background", UIKit.box(Color(1, 1, 1, 0.15), 8))
	if _def.get("require_all", "") != "" and _uses_custom_code():
		_confirm.disabled = _found.size() < (_def.get("items", []) as Array).size()


func _full_code() -> String:
	var lines: Array = []
	if not _uses_custom_code():
		var quoted: Array = []
		for it in _def.get("start", []):
			quoted.append("\"%s\"" % it)
		lines.append("%s = [%s]" % [str(_def.get("list", "bag")), ", ".join(quoted)])
	lines.append_array(_code_lines)
	return "\n".join(lines)


func _process(delta: float) -> void:
	if not _running or _time_left <= 0.0:
		return
	_time_left -= delta
	_timer_label.text = "捷運進站倒數：%d 秒" % ceili(maxf(_time_left, 0.0))
	_timer_label.modulate = Color(1, 0.5, 0.5) if _time_left < 10 else Color.WHITE
	if _time_left <= 0.0:
		_say("捷運進站了！")
		_done.emit()


## 探索完按空白鍵（或 Enter）＝按確認
func _unhandled_input(event: InputEvent) -> void:
	if visible and _running and not _confirm.disabled and UIKit.is_continue_key(event):
		get_viewport().set_input_as_handled()
		_on_confirm()


func _on_confirm() -> void:
	var cap := int(_def.get("capacity", 0))
	if cap > 0 and _items.size() > cap:
		_say("（東西太多了，跑不快，會趕不上捷運！先拿掉一樣吧。）")
		return
	_done.emit()


func _scroll_code_to_end() -> void:
	await get_tree().process_frame
	var scroll := _code_view.get_parent() as ScrollContainer
	scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)


## 派森說話：顯示在劇情區的對話框
func _say(text: String) -> void:
	if text == "":
		return
	if speak.is_valid():
		speak.call(text, "idle")
	else:
		_note.text = text


func _escape(t: String) -> String:
	return t.replace("[", "[lb]")


## 房間裡可以點的物品：藍黃光圈，放進清單後變淡並打勾
class ItemSpot extends Control:
	signal pressed_item
	var item_name: String = ""
	var taken: bool = false
	var _t: float = 0.0

	func _ready() -> void:
		size = Vector2(250, 130)
		mouse_filter = Control.MOUSE_FILTER_STOP
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			pressed_item.emit()

	func _draw() -> void:
		var c := Vector2(size.x / 2.0, 50)
		var pulse := 0.5 + 0.5 * sin(_t * 3.0)
		if not taken:
			draw_circle(c, 48 + pulse * 6, Color(UIKit.PY_BLUE, 0.18))
			draw_arc(c, 44 + pulse * 4, 0, TAU, 48, Color(UIKit.PY_YELLOW, 0.9), 4)
			draw_arc(c, 38, 0, TAU, 48, Color(UIKit.PY_BLUE, 0.9), 3)
		draw_circle(c, 32, Color(1, 1, 1, 0.35 if taken else 0.95))
		if taken:
			draw_polyline(PackedVector2Array([c + Vector2(-14, 0), c + Vector2(-3, 12), c + Vector2(18, -14)]), UIKit.RUN_GREEN, 6)
		var font := UIKit.body_font()
		var tw := font.get_string_size(item_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x
		draw_string(font, Vector2((size.x - tw) / 2.0, 122), item_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 26,
			Color(UIKit.INK, 0.4 if taken else 1.0))
