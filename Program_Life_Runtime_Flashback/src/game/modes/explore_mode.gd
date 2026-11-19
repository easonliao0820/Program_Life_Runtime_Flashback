extends Control

## 探索模式（側向）：2.1 找回憶盒子、3.1 整理書包、3.4 學測當天行前檢查。
## - 側面看的房間（橫向捲動）：← → 走路、↑ ↓ 上下樓梯／爬上爬下家具、E 互動
## - 每一關的家具、樓梯、物品位置寫在 src/game/core/explore_layouts.gd
## - 挑戰：3.1 書包越重走越慢＋貓會絆人＋倒數；2.1 推板凳搆高處；3.4 房間很暗、東西藏在抽屜裡
## - 走到門口按 E 出發（2.1 全部找到就自動結束）
## - 左下面板即時顯示 Python 的 list，拿東西時自動長出一行 bag.append(...)
## 美術：assets/explore/ 底下有圖就用圖，沒有就畫色塊（檔名見 docs/EXPLORE_ART.md）
## 結果：GameState 的 <list 名稱> 變數存放最後的清單，explore_code 存放整段產生的程式碼。

signal _done

## GameStage 提供：func(text: String, mood: String) —— 讓派森在劇情區的對話框裡說話
var speak: Callable

const Layouts := preload("res://src/game/core/explore_layouts.gd")
const SheetAnim := preload("res://src/game/components/sheet_anim.gd")
const ART_DIR := "res://assets/explore/"

## 角色數值（單位：背景圖像素）。speed 每秒走幾像素、h 身高、w 寬、climb 能爬上多高、reach 手能伸到頭上多高
const PLAYERS := {
	"teen": {"speed": 115.0, "h": 64.0, "w": 26.0, "climb": 48.0, "reach": 24.0, "idle": "player_teen_idle", "walk": "player_teen_walk"},
	"baby": {"speed": 70.0, "h": 36.0, "w": 34.0, "climb": 60.0, "reach": 40.0, "idle": "player_baby_idle", "walk": "player_baby_crawl"},
}
const REACH_X := 40.0          ## 左右離物品多近才能按 E
const WEIGHT_STEP := 0.06      ## 書包每多一樣東西，速度少幾成
const WEIGHT_MIN := 0.55       ## 最慢不會低於原本的幾成
const CAT_STUN := 1.0          ## 被貓絆到停幾秒
const LIGHT_RADIUS := 120.0    ## 很暗的房間裡，角色身邊看得到的範圍

var _def: Dictionary = {}
var _lay: Dictionary = {}
var _room: Control
var _room_title: Label
var _view: Control
var _list_view: RichTextLabel
var _code_view: RichTextLabel
var _capacity_bar: ProgressBar
var _capacity_label: Label
var _timer_label: Label
var _note: Label
var _prompt: PanelContainer
var _prompt_label: Label

var _items: Array = []         ## 目前清單內容
var _code_lines: Array = []    ## 依互動順序產生的程式碼
var _found: Dictionary = {}    ## 已打開的回憶盒子（自訂程式碼模式用）
var _entries: Dictionary = {}  ## 物品名稱 -> entry（劇本裡的設定）
var _spots: Dictionary = {}    ## 互動點：key -> {kind, pos, label, visible, opened, bump}
var _nearest: String = ""
var _time_left: float = 0.0
var _soft_said: bool = false
var _timer_started: bool = false  ## 第一次按鍵才開始倒數
var _running: bool = false
var _finishing: bool = false

## 角色狀態
var _pl: Dictionary = {}       ## PLAYERS 裡的數值
var _p: Vector2 = Vector2.ZERO ## 腳底的位置
var _sup: int = 0              ## 站在哪個 support 上（等於 supports.size() 表示站在板凳上）
var _stair: int = -1           ## 在哪一座樓梯上（-1 = 不在樓梯上）
var _st: float = 0.0           ## 樓梯上的進度：0 = 下面、1 = 上面
var _falling: bool = false
var _fall_y: float = 0.0
var _fall_sup: int = 0
var _busy: bool = false        ## 正在爬上家具的動畫
var _face: int = 1
var _moving: bool = false
var _stun: float = 0.0
var _anim_t: float = 0.0
var _cam_x: float = 0.0

var _stool: Dictionary = {}
var _cat: Dictionary = {}
var _cat_cool: float = 0.0

## 圖（沒有就是空的，改畫色塊）
var _bg_tex: Texture2D
var _idle_frames: Array[Texture2D] = []
var _walk_frames: Array[Texture2D] = []
var _cat_frames: Array[Texture2D] = []
var _stool_tex: Texture2D
var _pscale: float = 1.0
var _icons: Dictionary = {}
var _dark_tex: GradientTexture2D


func _ready() -> void:
	UIKit.full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# 右邊：側面看的房間
	_room = Panel.new()
	_room.position = UIKit.SPLIT_CODE.position
	_room.size = Vector2(UIKit.SPLIT_CODE.size.x, UIKit.SPLIT_FEEDBACK.end.y - UIKit.SPLIT_CODE.position.y)
	_room.add_theme_stylebox_override("panel", UIKit.split_frame("code"))
	add_child(_room)
	_room_title = UIKit.label("", 30, UIKit.GOLD)
	_room_title.position = Vector2(36, 22)
	_room.add_child(_room_title)
	_view = Control.new()
	_view.position = Vector2(30, 72)
	_view.size = _room.size - Vector2(60, 72 + 62)
	_view.clip_contents = true
	_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_view.draw.connect(_draw_view)
	_room.add_child(_view)
	var help := UIKit.label("", 22, Color(1, 1, 1, 0.7))
	help.name = "Help"
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help.position = Vector2(0, _room.size.y - 54)
	help.custom_minimum_size = Vector2(_room.size.x, 0)
	_room.add_child(help)

	# 「E」互動提示
	_prompt = PanelContainer.new()
	_prompt.add_theme_stylebox_override("panel", UIKit.navy_panel(8, 8))
	_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prompt_label = UIKit.label("", 22, Color.WHITE)
	_prompt.add_child(_prompt_label)
	_prompt.visible = false
	_view.add_child(_prompt)

	# 左下：Python 清單面板（拿東西時即時長出程式碼）
	var side := PanelContainer.new()
	side.position = UIKit.SPLIT_OBJECT.position
	side.size = UIKit.SPLIT_OBJECT.size
	side.add_theme_stylebox_override("panel", UIKit.split_frame("output", Vector4(44, 40, 40, 30)))
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
	_capacity_bar.custom_minimum_size = Vector2(300, 28)
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

	_dark_tex = GradientTexture2D.new()
	_dark_tex.fill = GradientTexture2D.FILL_RADIAL
	_dark_tex.fill_from = Vector2(0.5, 0.5)
	_dark_tex.fill_to = Vector2(1.0, 0.5)
	_dark_tex.width = 256
	_dark_tex.height = 256
	var g := Gradient.new()
	g.set_color(0, Color(0.02, 0.03, 0.08, 0.0))
	g.add_point(0.55, Color(0.02, 0.03, 0.08, 0.15))
	g.set_color(g.get_point_count() - 1, Color(0.02, 0.03, 0.08, 0.88))
	_dark_tex.gradient = g
	visible = false


func play(def: Dictionary) -> Dictionary:
	_def = def
	_items = (def.get("start", []) as Array).duplicate()
	_code_lines = []
	_found = {}
	_room_title.text = GameState.format_text(str(def.get("title", "")))
	_note.text = ""
	_soft_said = false
	_finishing = false
	_say(GameState.format_text(str(def.get("goal", ""))))

	# 劇本裡的物品（一開始就在清單裡的東西也算，拿得出來）
	_entries.clear()
	var names: Array = []
	for start_item in def.get("start", []):
		_entries[start_item] = {"name": start_item, "code": "", "note": ""}
		names.append(start_item)
	for e in def.get("items", []):
		_entries[e["name"]] = e
		names.append(e["name"])
	_lay = Layouts.get_layout(str(def.get("id", "")), names)
	_load_art()
	_build_spots(names)
	var help: Label = _room.get_node("Help")
	help.text = "← → 移動　．　↑ ↓ 上下樓梯、爬上爬下　．　E 互動" + \
		("　．　走到門口按 E 出發" if _lay.has("exit") else "")

	_time_left = float(_lay.get("timer", def.get("timer", 0)))
	_timer_label.visible = _time_left > 0
	_timer_started = false
	_timer_label.text = "%s：%d 秒（按任意鍵開始）" % [str(_lay.get("timer_label", "捷運進站倒數")), ceili(_time_left)]
	_timer_label.modulate = Color.WHITE
	var cap := int(def.get("capacity", 0))
	_capacity_bar.get_parent().visible = cap > 0 or _lay.get("weight", false)
	_capacity_bar.visible = cap > 0
	_capacity_bar.max_value = maxi(cap, 1)

	# 角色、板凳、貓
	_pl = (PLAYERS.get(str(_lay.get("player", "teen")), PLAYERS["teen"]) as Dictionary).duplicate()
	# 角色放大倍率：配合背景的家具比例，身高、手長、能爬多高一起放大
	_pscale = float(_lay.get("player_scale", 1.0))
	for k in ["h", "w", "climb", "reach"]:
		_pl[k] = float(_pl[k]) * _pscale
	_p = _lay["start"]
	_sup = _support_at(_p.x, _p.y)
	_stair = -1
	_falling = false
	_busy = false
	_stun = 0.0
	_face = 1
	_stool = (_lay["stool"] as Dictionary).duplicate() if _lay.has("stool") else {}
	_cat = (_lay["cat"] as Dictionary).duplicate() if _lay.has("cat") else {}
	if not _cat.is_empty():
		_cat["x"] = float(_cat["x1"])
		_cat["dir"] = -1
	_cam_x = _target_cam()
	_refresh()

	visible = true
	_running = true
	modulate.a = 0.0
	UIKit.fade(self, 1.0, 0.3)
	if GameFlow.autopilot:
		_done.emit.call_deferred()
	await _done
	_running = false
	_prompt.visible = false
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


# ------------------------------------------------------------------
# 場景
# ------------------------------------------------------------------

func _load_art() -> void:
	_bg_tex = _tex(str(_lay.get("bg", "")))
	var who: Dictionary = PLAYERS.get(str(_lay.get("player", "teen")), PLAYERS["teen"])
	_idle_frames = SheetAnim.slice(_tex(who["idle"]))
	_walk_frames = SheetAnim.slice(_tex(who["walk"]))
	_cat_frames = SheetAnim.slice(_tex(str(_lay.get("cat", {}).get("tex", ""))))
	_stool_tex = _tex(str(_lay.get("stool", {}).get("tex", "")))
	_icons.clear()


func _tex(file: String) -> Texture2D:
	if file == "":
		return null
	var path := ART_DIR + file + ".png"
	return load(path) if ResourceLoader.exists(path) else null


func _icon(file: String) -> Texture2D:
	if not _icons.has(file):
		_icons[file] = _tex("items/" + file)
	return _icons[file]


func _build_spots(names: Array) -> void:
	_spots.clear()
	_nearest = ""
	var lay_items: Dictionary = _lay.get("items", {})
	var spare_x := 80.0
	for n in names:
		var where = lay_items.get(n, null)
		if where is Vector2:
			_spots[n] = {"kind": "item", "pos": where, "label": n, "visible": true}
		elif where is Dictionary:
			_spots[n] = {"kind": "item", "pos": Vector2.ZERO, "label": n, "visible": false, "in": where["in"]}
		else:
			# 配置裡沒寫到的東西：排在起點那層地板上
			_spots[n] = {"kind": "item", "pos": Vector2(spare_x, float(_lay["start"].y) - 10), "label": n, "visible": true}
			spare_x += 60
	for c in _lay.get("containers", []):
		_spots["#c:" + str(c["id"])] = {"kind": "container", "id": c["id"], "pos": c["pos"], "label": c["label"],
			"visible": true, "opened": false}
	if _lay.has("exit"):
		_spots["#exit"] = {"kind": "exit", "pos": _lay["exit"]["pos"], "label": _lay["exit"]["label"], "visible": true}


## 翻開容器：裡面的東西排在容器的位置左右
func _open_container(spot: Dictionary) -> void:
	spot["opened"] = true
	var inside: Array = []
	for key in _spots:
		if _spots[key].get("in", "") == spot["id"]:
			inside.append(key)
	if inside.is_empty():
		_say("（%s……什麼都沒有。）" % spot["label"])
		return
	for i in inside.size():
		var s: Dictionary = _spots[inside[i]]
		s["pos"] = spot["pos"] + Vector2((i - (inside.size() - 1) / 2.0) * 30.0, 0)
		s["visible"] = true
		s["bump"] = 1.0
	_say("（%s裡有：%s）" % [spot["label"], "、".join(inside)])


# ------------------------------------------------------------------
# 清單與程式碼
# ------------------------------------------------------------------

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
		var hidden_n := int(_def.get("hidden_count", 0))
		if hidden_n > 0:
			_list_view.text += "\n[color=#8b98a5]（簡章上一共有 %d 樣東西要帶）[/color]" % hidden_n
	_code_view.text = "[color=#8b98a5]# 你的每個動作，都會變成一行程式[/color]\n" + _escape(_full_code())
	_scroll_code_to_end.call_deferred()

	var speed_text := ""
	if _lay.get("weight", false):
		speed_text = "　走路速度 %d%%" % roundi(_weight_factor() * 100)
	if cap > 0:
		_capacity_bar.value = mini(_items.size(), cap)
		_capacity_label.text = "  %d / %d%s" % [_items.size(), cap, speed_text]
		var col := UIKit.RUN_GREEN
		_note.text = ""
		if _items.size() > cap:
			col = Color("#d9534f")
			_note.text = "東西太多了，跑不快！"
		elif _items.size() == cap:
			col = Color("#f0932b")
		_capacity_bar.add_theme_stylebox_override("fill", UIKit.box(col, 8))
		_capacity_bar.add_theme_stylebox_override("background", UIKit.box(Color(1, 1, 1, 0.15), 8))
	elif speed_text != "":
		_capacity_label.text = speed_text.strip_edges()

	# 2.1：全部打開就自動結束
	if _lay.get("auto_finish", false) and _uses_custom_code() and not _finishing \
			and _found.size() >= (_def.get("items", []) as Array).size():
		_finishing = true
		_finish_later()


func _finish_later() -> void:
	await get_tree().create_timer(1.5).timeout
	if _running:
		_done.emit()


func _full_code() -> String:
	var lines: Array = []
	if not _uses_custom_code():
		var quoted: Array = []
		for it in _def.get("start", []):
			quoted.append("\"%s\"" % it)
		lines.append("%s = [%s]" % [str(_def.get("list", "bag")), ", ".join(quoted)])
	lines.append_array(_code_lines)
	return "\n".join(lines)


func _weight_factor() -> float:
	if not _lay.get("weight", false):
		return 1.0
	return clampf(1.0 - WEIGHT_STEP * _items.size(), WEIGHT_MIN, 1.0)


# ------------------------------------------------------------------
# 每一格
# ------------------------------------------------------------------

func _process(delta: float) -> void:
	if not _running:
		return
	_anim_t += delta
	_cat_cool = maxf(_cat_cool - delta, 0.0)
	_move_cat(delta)
	_move_player(delta)
	_check_cat()
	_update_nearest()
	for key in _spots:
		var s: Dictionary = _spots[key]
		s["bump"] = maxf(float(s.get("bump", 0.0)) - delta * 4.0, 0.0)
	_cam_x = lerpf(_cam_x, _target_cam(), minf(1.0, delta * 6.0))
	_view.queue_redraw()
	_place_prompt()

	if _time_left <= 0.0 or not _timer_started:
		return
	_time_left -= delta
	_timer_label.text = "%s：%d 秒" % [str(_lay.get("timer_label", "捷運進站倒數")), ceili(maxf(_time_left, 0.0))]
	_timer_label.modulate = Color(1, 0.5, 0.5) if _time_left < 10 else Color.WHITE
	if _time_left <= 0.0:
		if _lay.has("timer_soft"):
			# 寬鬆的倒數：時間到只是被催，不會強制結束
			_timer_label.text = "時間到了，快出門！"
			_timer_label.modulate = Color(1, 0.5, 0.5)
			_say(str(_lay["timer_soft"]))
		else:
			_say("捷運進站了！")
			_done.emit()


## 在輸入框打字時，不要讓角色跟著動、也不要觸發 E
func _typing() -> bool:
	return get_viewport().gui_get_focus_owner() is LineEdit or get_viewport().gui_get_focus_owner() is TextEdit


func _key(a: Key, b: Key) -> bool:
	return Input.is_key_pressed(a) or Input.is_key_pressed(b)


func _move_player(delta: float) -> void:
	_moving = false
	if _busy or _typing():
		return
	if _stun > 0.0:
		_stun -= delta
		return
	if _falling:
		_p.y = move_toward(_p.y, _fall_y, 420.0 * delta)
		if is_equal_approx(_p.y, _fall_y):
			_falling = false
			_sup = _fall_sup
		return

	var dir := 0
	if _key(KEY_LEFT, KEY_A):
		dir -= 1
	if _key(KEY_RIGHT, KEY_D):
		dir += 1
	var speed: float = _pl["speed"] * _weight_factor()

	if _stair >= 0:
		_walk_stairs(dir, speed, delta)
		return
	if dir == 0:
		return
	_face = dir
	_moving = true
	var sups := _supports()
	var s: Dictionary = sups[_sup]
	var nx := _p.x + dir * speed * delta
	var half: float = _pl["w"] / 2.0

	# 推板凳：在板凳那層地板上、往板凳的方向走
	if not _stool.is_empty() and _sup != _stool_index() and is_equal_approx(_p.y, float(_stool["floor"])):
		var reach: float = half + float(_stool["w"]) / 2.0
		var sx: float = _stool["x"]
		if (dir > 0 and _p.x < sx and nx > sx - reach) or (dir < 0 and _p.x > sx and nx < sx + reach):
			nx = _p.x + dir * speed * 0.5 * delta  # 推東西走比較慢
			var floor_s: Dictionary = sups[_support_at(_p.x, _p.y)]
			var new_sx := clampf(nx + dir * reach, float(floor_s["x0"]) + _stool["w"] / 2.0,
				float(floor_s["x1"]) - _stool["w"] / 2.0)
			_stool["x"] = new_sx
			nx = new_sx - dir * reach

	if s.get("wall", false):
		nx = clampf(nx, float(s["x0"]) + half, float(s["x1"]) - half)
		_p.x = nx
		return
	_p.x = nx
	if nx < float(s["x0"]) or nx > float(s["x1"]):
		_drop()


func _walk_stairs(dir: int, speed: float, delta: float) -> void:
	var st: Dictionary = _lay["stairs"][_stair]
	var top: Vector2 = st["top"]
	var bottom: Vector2 = st["bottom"]
	var v := 0.0
	if _key(KEY_UP, KEY_W):
		v += 1.0
	if _key(KEY_DOWN, KEY_S):
		v -= 1.0
	if dir != 0:
		v += signf(top.x - bottom.x) * dir
		_face = dir
	v = clampf(v, -1.0, 1.0)
	if v == 0.0:
		return
	_moving = true
	if absf(top.x - bottom.x) > 1.0:
		_face = int(signf(top.x - bottom.x) * signf(v))
	_st = clampf(_st + v * speed * 0.8 * delta / top.distance_to(bottom), 0.0, 1.0)
	_p = bottom.lerp(top, _st)
	if _st >= 1.0 and v > 0.0:
		_stair = -1
		_sup = _support_at(top.x, top.y)
	elif _st <= 0.0 and v < 0.0:
		_stair = -1
		_sup = _support_at(bottom.x, bottom.y)


## ↑：上樓梯，或爬上旁邊比較高的家具／板凳
func _go_up() -> void:
	if _stair >= 0 or _busy or _falling:
		return
	for i in (_lay.get("stairs", []) as Array).size():
		var b: Vector2 = _lay["stairs"][i]["bottom"]
		if absf(_p.y - b.y) < 2.0 and absf(_p.x - b.x) < 30.0:
			_stair = i
			_st = 0.0
			_p = b
			return
	var sups := _supports()
	var best := -1
	for i in sups.size():
		var s: Dictionary = sups[i]
		var dy := _p.y - float(s["y"])
		if dy > 2.0 and dy <= float(_pl["climb"]) and _p.x >= float(s["x0"]) - 4.0 and _p.x <= float(s["x1"]) + 4.0:
			if best == -1 or float(s["y"]) > float(sups[best]["y"]):
				best = i
	if best == -1:
		return
	_busy = true
	_sup = best
	var s2: Dictionary = sups[best]
	var target := Vector2(clampf(_p.x, float(s2["x0"]) + 4.0, float(s2["x1"]) - 4.0), float(s2["y"]))
	var t := create_tween()
	t.tween_property(self, "_p", target, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.finished.connect(func(): _busy = false)


## ↓：下樓梯，或從家具上下來
func _go_down() -> void:
	if _stair >= 0 or _busy or _falling:
		return
	for i in (_lay.get("stairs", []) as Array).size():
		var t: Vector2 = _lay["stairs"][i]["top"]
		if absf(_p.y - t.y) < 2.0 and absf(_p.x - t.x) < 30.0:
			_stair = i
			_st = 1.0
			_p = t
			return
	if not _supports()[_sup].get("wall", false):
		_drop()


func _drop() -> void:
	var below := _support_below(_p.x, _p.y)
	if below == -1:
		return
	_falling = true
	_fall_sup = below
	_fall_y = float(_supports()[below]["y"])


## 所有可以站的地方（最後一個是板凳）
func _supports() -> Array:
	var out: Array = (_lay.get("supports", []) as Array).duplicate()
	if not _stool.is_empty():
		out.append({"x0": _stool["x"] - _stool["w"] / 2.0, "x1": _stool["x"] + _stool["w"] / 2.0,
			"y": float(_stool["floor"]) - float(_stool["h"])})
	return out


func _stool_index() -> int:
	return (_lay.get("supports", []) as Array).size()


func _support_at(x: float, y: float) -> int:
	var sups := _supports()
	for i in sups.size():
		var s: Dictionary = sups[i]
		if absf(float(s["y"]) - y) < 2.0 and x >= float(s["x0"]) - 2.0 and x <= float(s["x1"]) + 2.0:
			return i
	return _support_below(x, y - 1.0)


func _support_below(x: float, y: float) -> int:
	var sups := _supports()
	var best := -1
	for i in sups.size():
		var s: Dictionary = sups[i]
		if float(s["y"]) > y + 1.0 and x >= float(s["x0"]) - 2.0 and x <= float(s["x1"]) + 2.0:
			if best == -1 or float(s["y"]) < float(sups[best]["y"]):
				best = i
	return best


func _move_cat(delta: float) -> void:
	if _cat.is_empty():
		return
	_cat["x"] = float(_cat["x"]) + float(_cat["dir"]) * float(_cat["speed"]) * delta
	if _cat["x"] <= float(_cat["x0"]):
		_cat["dir"] = 1
	elif _cat["x"] >= float(_cat["x1"]):
		_cat["dir"] = -1


func _check_cat() -> void:
	if _cat.is_empty() or _cat_cool > 0.0 or _stair >= 0 or _falling:
		return
	if absf(_p.y - float(_cat["y"])) > 2.0:
		return
	var dx := _p.x - float(_cat["x"])
	if absf(dx) < float(_pl["w"]) / 2.0 + 14.0:
		_stun = CAT_STUN
		_cat_cool = 2.5
		var floor_s: Dictionary = _supports()[_sup]
		_p.x = clampf(_p.x + signf(dx if dx != 0.0 else -_face) * 24.0, float(floor_s["x0"]) + 13.0, float(floor_s["x1"]) - 13.0)
		_say("（喵——！被貓絆了一下。）")


# ------------------------------------------------------------------
# 互動
# ------------------------------------------------------------------

## 找出伸手搆得到、而且最近的互動點
func _update_nearest() -> void:
	var best := ""
	var best_d := INF
	if _stair < 0 and not _falling and not _busy:
		var top: float = _p.y - float(_pl["h"]) - float(_pl["reach"])
		for key in _spots:
			var s: Dictionary = _spots[key]
			if not s["visible"]:
				continue
			if s["kind"] == "container" and s["opened"]:
				continue
			var pos: Vector2 = s["pos"]
			var dx := absf(pos.x - _p.x)
			if dx > REACH_X or pos.y < top or pos.y > _p.y + 12.0:
				continue
			if dx < best_d:
				best_d = dx
				best = key
	_nearest = best


func _place_prompt() -> void:
	var text := ""
	var at := Vector2.ZERO
	if _nearest != "":
		text = "E　%s" % _action_text(_nearest)
		at = _spots[_nearest]["pos"]
	else:
		text = _move_hint()
		at = _p - Vector2(0, float(_pl["h"]) + 6.0)
	if text == "":
		_prompt.visible = false
		return
	_prompt_label.text = "  %s  " % text
	_prompt.visible = true
	_prompt.reset_size()
	var sp := _to(at)
	_prompt.position = Vector2(clampf(sp.x - _prompt.size.x / 2.0, 4.0, _view.size.x - _prompt.size.x - 4.0),
		maxf(sp.y - 22.0 * _s() - _prompt.size.y, 4.0))


## 沒有東西可以拿的時候：站在樓梯口、家具旁邊，提示可以按 ↑ / ↓
func _move_hint() -> String:
	if _stair >= 0 or _busy or _falling:
		return ""
	for st in _lay.get("stairs", []):
		if absf(_p.y - st["bottom"].y) < 2.0 and absf(_p.x - st["bottom"].x) < 30.0:
			return "↑　上樓"
		if absf(_p.y - st["top"].y) < 2.0 and absf(_p.x - st["top"].x) < 30.0:
			return "↓　下樓"
	var sups := _supports()
	for i in sups.size():
		var sp: Dictionary = sups[i]
		var dy := _p.y - float(sp["y"])
		if dy > 2.0 and dy <= float(_pl["climb"]) and _p.x >= float(sp["x0"]) - 4.0 and _p.x <= float(sp["x1"]) + 4.0:
			return "↑　爬上去"
	return ""


## 按 E 會做什麼（顯示在提示上）
func _action_text(key: String) -> String:
	var s: Dictionary = _spots[key]
	match s["kind"]:
		"container":
			return "翻翻看：%s" % s["label"]
		"exit":
			return s["label"]
	var entry: Dictionary = _entries.get(key, {})
	if str(entry.get("code", "")) != "":
		return "已經打開了" if _found.has(key) else "打開：%s" % key
	var where := "書包" if str(_def.get("list", "bag")) in ["bag", "my_bag"] else "清單"
	return ("從%s拿出來：%s" % [where, key]) if _items.has(key) else ("放進%s：%s" % [where, key])


func _interact() -> void:
	if _nearest == "":
		return
	var s: Dictionary = _spots[_nearest]
	s["bump"] = 1.0
	match s["kind"]:
		"container":
			_open_container(s)
		"exit":
			_on_confirm()
		_:
			if _entries.has(_nearest):
				_on_item(_entries[_nearest])


## 第一次按鍵（移動、互動都算）才開始倒數
func _input(event: InputEvent) -> void:
	if visible and _running and not _timer_started and event is InputEventKey and event.pressed and not _typing():
		_timer_started = true


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not _running or _typing():
		return
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_E:
			_interact()
		KEY_UP, KEY_W:
			_go_up()
		KEY_DOWN, KEY_S:
			_go_down()
		_:
			return
	get_viewport().set_input_as_handled()


func _on_confirm() -> void:
	var cap := int(_def.get("capacity", 0))
	if cap > 0 and _items.size() > cap:
		_say("（東西太多了，跑不快，會趕不上捷運！先拿掉一樣吧。）")
		return
	if _uses_custom_code() and _found.size() < (_def.get("items", []) as Array).size():
		_say("（還有回憶盒子沒打開喔。）")
		return
	# 只檢查 3.4 學測當天的探索，不影響其他探索關卡
	if str(_def.get("id", "")) == "ch3_4_bag":
		var required_items := [
			"准考證", "身分證", "2B鉛筆", "橡皮擦", "手錶"
		]
		var missing: Array[String] = []

		for item in required_items:
			if not _items.has(item):
				missing.append(item)

		if not missing.is_empty():
			_say("還沒帶齊考場所需的五樣物品，請再檢查一下。")
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


# ------------------------------------------------------------------
# 畫面（背景圖像素 → 螢幕）
# ------------------------------------------------------------------

func _s() -> float:
	return _view.size.y / float(_lay.get("size", Vector2(640, 360)).y)


func _target_cam() -> float:
	var w: float = _lay.get("size", Vector2(640, 360)).x
	var vis := _view.size.x / _s()
	if w <= vis:
		return 0.0
	return clampf(_p.x - vis / 2.0, 0.0, w - vis)


func _to(p: Vector2) -> Vector2:
	var s := _s()
	var w: float = _lay.get("size", Vector2(640, 360)).x
	var ox := maxf(0.0, (_view.size.x - w * s) / 2.0)
	return Vector2((p.x - _cam_x) * s + ox, p.y * s)


func _rect(r: Rect2) -> Rect2:
	return Rect2(_to(r.position), r.size * _s())


func _draw_view() -> void:
	if _lay.is_empty():
		return
	var v := _view
	var s := _s()
	var scene: Vector2 = _lay.get("size", Vector2(640, 360))
	var font := UIKit.body_font()
	if _bg_tex:
		v.draw_texture_rect(_bg_tex, _rect(Rect2(Vector2.ZERO, scene)), false)
	else:
		_draw_placeholder_room(v, scene, font)

	# 板凳／椅子
	if not _stool.is_empty():
		var r := Rect2(_stool["x"] - _stool["w"] / 2.0, float(_stool["floor"]) - float(_stool["h"]), _stool["w"], _stool["h"])
		if _stool_tex:
			v.draw_texture_rect(_stool_tex, _rect(r), false)
		else:
			v.draw_rect(_rect(r), Color("#c08a4e"))
			v.draw_rect(_rect(Rect2(r.position, Vector2(r.size.x, 6))), Color("#8c5a2b"))
			_text(v, font, str(_stool.get("label", "")), _to(Vector2(_stool["x"], float(_stool["floor"]) - float(_stool["h"]) / 2.0)), 16, Color.WHITE)

	# 互動點
	for key in _spots:
		_draw_spot(v, font, key, _spots[key], s)

	# 貓
	if not _cat.is_empty():
		var cp := _to(Vector2(_cat["x"], _cat["y"]))
		if not _cat_frames.is_empty():
			var fr: Texture2D = _cat_frames[int(_anim_t * 8.0) % _cat_frames.size()]
			_draw_frame(v, fr, cp, int(_cat["dir"]), s)
		else:
			v.draw_circle(cp + Vector2(0, -9 * s), 10 * s, Color("#e39b4b"))
			v.draw_circle(cp + Vector2(_cat["dir"] * 11 * s, -16 * s), 7 * s, Color("#e39b4b"))
			_text(v, font, "貓", cp + Vector2(0, -36 * s), 16, Color("#7a4a1a"))

	_draw_player(v, s)

	# 很暗的房間：只有角色附近看得到
	if _lay.get("dark", false):
		var c := _to(_p - Vector2(0, float(_pl["h"]) / 2.0))
		var r := float(_lay.get("light", LIGHT_RADIUS)) * s * 2.0
		var lr := Rect2(c - Vector2(r, r) / 2.0, Vector2(r, r))
		var dark := Color(0.02, 0.03, 0.08, 0.88)
		v.draw_texture_rect(_dark_tex, lr, false)
		v.draw_rect(Rect2(0, 0, v.size.x, maxf(lr.position.y, 0)), dark)
		v.draw_rect(Rect2(0, lr.end.y, v.size.x, v.size.y), dark)
		v.draw_rect(Rect2(0, lr.position.y, maxf(lr.position.x, 0), r), dark)
		v.draw_rect(Rect2(lr.end.x, lr.position.y, v.size.x, r), dark)


func _draw_placeholder_room(v: Control, scene: Vector2, font: Font) -> void:
	v.draw_rect(_rect(Rect2(Vector2.ZERO, scene)), Color("#3a3f4b"))
	for room in _lay.get("rooms", []):
		v.draw_rect(_rect(room["rect"]), room["color"])
		if room.has("label"):
			var r: Rect2 = room["rect"]
			_text(v, font, room["label"], _to(r.position + Vector2(r.size.x / 2.0, 14)), 18, Color(UIKit.INK, 0.45))
	for slab in _lay.get("slabs", []):
		v.draw_rect(_rect(slab), Color("#7a5c3e"))
	for d in _lay.get("deco", []):
		var r: Rect2 = d["rect"]
		v.draw_rect(_rect(r), d["color"])
		_text(v, font, d["label"], _to(r.get_center()), 16, Color(UIKit.INK, 0.7))
	# 家具（可以爬上去的地方）
	for sp in _lay.get("supports", []):
		if sp.get("wall", false):
			v.draw_rect(_rect(Rect2(sp["x0"], sp["y"], sp["x1"] - sp["x0"], 8)), Color("#7a5c3e"))
			continue
		var below := _support_below((sp["x0"] + sp["x1"]) / 2.0, sp["y"])
		var bottom: float = float(_supports()[below]["y"]) if below != -1 else scene.y
		var r := Rect2(sp["x0"], sp["y"], sp["x1"] - sp["x0"], bottom - sp["y"])
		v.draw_rect(_rect(r), Color("#b98b5e"))
		v.draw_rect(_rect(Rect2(r.position, Vector2(r.size.x, 5))), Color("#7a5232"))
		_text(v, font, sp.get("label", ""), _to(r.get_center()), 16, Color.WHITE)
	# 樓梯
	for st in _lay.get("stairs", []):
		var top: Vector2 = st["top"]
		var bottom: Vector2 = st["bottom"]
		var n := 9
		var pts := PackedVector2Array()
		for i in n + 1:
			var a := bottom.lerp(top, float(i) / n)
			var b := bottom.lerp(top, float(i + 1) / n) if i < n else a
			pts.append(_to(a))
			pts.append(_to(Vector2(b.x, a.y)))
		v.draw_polyline(pts, Color("#7a5c3e"), 6.0)
		_text(v, font, "樓梯", _to(bottom.lerp(top, 0.5)) + Vector2(30, 0), 16, Color(UIKit.INK, 0.6))
	if _lay.has("exit") and _lay["exit"].has("rect"):
		v.draw_rect(_rect(_lay["exit"]["rect"]), Color("#6b4a2e"))


func _draw_spot(v: Control, font: Font, key: String, sp: Dictionary, s: float) -> void:
	if not sp["visible"]:
		return
	var c := _to(sp["pos"])
	var focused := key == _nearest
	var pulse := 0.5 + 0.5 * sin(_anim_t * (6.0 if focused else 3.0))
	var grow := 1.0 + float(sp.get("bump", 0.0)) * 0.3
	var r := 13.0 * s * grow
	match sp["kind"]:
		"container":
			if sp["opened"]:
				_text(v, font, "已翻過", c + Vector2(0, 16 * s), 15, Color(1, 1, 1, 0.5))
				return
			if focused:
				v.draw_circle(c, r + 6 + pulse * 6, Color(UIKit.PY_YELLOW, 0.3))
			v.draw_arc(c, r + pulse * 3, 0, TAU, 40, Color(UIKit.PY_YELLOW, 0.7), 3)
			_text(v, font, "?", c, 22, Color(UIKit.PY_YELLOW, 0.9))
			if focused:
				_text(v, font, sp["label"], c + Vector2(0, r + 16), 17, Color.WHITE, true)
			return
		"exit":
			if focused:
				v.draw_circle(c, r + 10 + pulse * 6, Color(UIKit.RUN_GREEN, 0.35))
			v.draw_arc(c, r + 4 + pulse * 3, 0, TAU, 40, UIKit.RUN_GREEN, 4)
			_text(v, font, "出發", c, 18, Color.WHITE, true)
			return
	var taken := _items.has(key) or _found.has(key)
	var entry_custom := str(_entries.get(key, {}).get("code", "")) != ""
	var done := _found.has(key) if entry_custom else false
	if focused:
		v.draw_circle(c, r + 8 + pulse * 6, Color(UIKit.PY_YELLOW, 0.3))
	if not done and not taken:
		v.draw_circle(c, r + 4 + pulse * 3, Color(UIKit.PY_BLUE, 0.2))
		v.draw_arc(c, r + 3 + pulse * 3, 0, TAU, 40, Color(UIKit.PY_YELLOW, 0.9), 3)
	var icon := _icon(str(_lay.get("item_icon", key)))
	var alpha := 0.35 if (taken or done) else 1.0
	if icon:
		var sz := Vector2(24, 24) * s
		v.draw_texture_rect(icon, Rect2(c - sz / 2.0, sz), false, Color(1, 1, 1, alpha))
	else:
		v.draw_circle(c, r * 0.8, Color(1, 1, 1, 0.95 * alpha))
		_text(v, font, key.substr(0, 1), c, 20, Color(UIKit.INK, alpha))
	if taken or done:
		v.draw_polyline(PackedVector2Array([c + Vector2(-10, 0), c + Vector2(-2, 9), c + Vector2(13, -10)]), UIKit.RUN_GREEN, 5)
	_text(v, font, key, c - Vector2(0, r + 12), 16, Color(UIKit.INK, 0.45 if taken else 0.95), focused)


func _draw_player(v: Control, s: float) -> void:
	var feet := _to(_p)
	var frames := _walk_frames if _moving and not _walk_frames.is_empty() else _idle_frames
	if not frames.is_empty():
		var fps := 10.0 if _moving else 4.0
		_draw_frame(v, frames[int(_anim_t * fps) % frames.size()], feet, _face, s * _pscale)
	else:
		# 先用色塊代替：主角代表色的小人，白點是面向
		var h: float = _pl["h"] * s
		var w: float = _pl["w"] * s
		var bob := sin(_anim_t * 14.0) * 2.0 if _moving else 0.0
		v.draw_rect(Rect2(feet + Vector2(-w / 2.0, -h * 0.05), Vector2(w, h * 0.08)), Color(0, 0, 0, 0.2))
		var col := ChapterRegistry.character_color("你")
		v.draw_rect(Rect2(feet + Vector2(-w / 2.0, -h * 0.68 + bob), Vector2(w, h * 0.68)), col)
		var head := feet + Vector2(0, -h * 0.82 + bob)
		v.draw_circle(head, h * 0.17, col.lightened(0.25))
		v.draw_circle(head + Vector2(_face * h * 0.09, 0), h * 0.05, Color.WHITE)
	if _stun > 0.0:
		_text(v, UIKit.body_font(), "!?", feet + Vector2(0, -float(_pl["h"]) * s - 18), 24, Color("#d9534f"), true)


## 畫一格 sprite：腳底對齊、面向左邊時左右翻轉（sprite 預設面向右）
func _draw_frame(v: Control, fr: Texture2D, feet: Vector2, face: int, s: float) -> void:
	var sz := Vector2(fr.get_width(), fr.get_height()) * s
	v.draw_set_transform(feet, 0.0, Vector2(-1.0 if face < 0 else 1.0, 1.0))
	v.draw_texture_rect(fr, Rect2(Vector2(-sz.x / 2.0, -sz.y), sz), false)
	v.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _text(v: Control, font: Font, t: String, center: Vector2, fsize: int, col: Color, outline: bool = false) -> void:
	if t == "":
		return
	var tw := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize)
	var pos := center + Vector2(-tw.x / 2.0, fsize * 0.35)
	if outline:
		v.draw_string_outline(font, pos, t, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, 5, Color(0, 0, 0, 0.75))
	v.draw_string(font, pos, t, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, col)
