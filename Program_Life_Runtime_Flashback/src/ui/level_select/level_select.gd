extends Control

## 記憶地圖（MEMORY LOAD）：原本的關卡地圖，外觀不變（卡片＋折線、左右捲動），
## 改成依 ChapterRegistry 自動排出全部小節，進度看 GameState：
##   - 走過的小節解鎖、播完的小節顯示 ✓ COMPLETED
##   - 點卡片從那一節開頭開始（GameFlow.play_from_map）
##   - 第六章之後分岔成結局一、結局二
## 縮圖：assets/thumbnails/<小節id>.png；沒有就用該節的人生階段色調。

@onready var back_button: Button = $Header/BackButton
@onready var reset_button: Button = $Header/ResetButton
@onready var title_label: Label = $Header/TitleLabel
@onready var scroll: ScrollContainer = $ScrollContainer
@onready var map_content: Control = $ScrollContainer/MapContent

const LEVEL_NODE := preload("res://src/ui/level_select/level_node.tscn")
const THUMB_DIR := "res://assets/thumbnails/"
## 已經有的舊素材當縮圖
const THUMB_ART := {"ch1": "res://chapters/chapter_1/images/baby.png"}

const NODE_SIZE := Vector2(240, 170)
const STEP_X := 300.0
const START_X := 120.0
## 折線的高低起伏（卡片中心的 y），沿用原本地圖的節奏
const WAVE_Y := [560.0, 420.0, 600.0, 360.0, 540.0, 440.0]
const ENDING_Y := {"ch6_end1": 330.0, "ch6_end2": 650.0}

const LINE_UNLOCKED := Color(1.0, 1.0, 1.0, 0.9)
const LINE_LOCKED := Color(0.25, 0.28, 0.32, 0.6)

var _nodes: Dictionary = {}   ## section_id -> LevelNode
var _unlock_all: bool = false


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	scroll.gui_input.connect(_on_scroll_input)

	if PauseMenu:
		PauseMenu.menu_container.hide()

	if OS.is_debug_build():
		var unlock := Button.new()
		unlock.text = "全部解鎖（開發用）"
		unlock.toggle_mode = true
		unlock.add_theme_font_size_override("font_size", 20)
		unlock.toggled.connect(func(on: bool):
			_unlock_all = on
			update_map())
		$Header.add_child(unlock)
		$Header.move_child(unlock, reset_button.get_index())

	_build_map()
	update_map()
	_scroll_to_current.call_deferred()


# ------------------------------------------------------------------
# 依 ChapterRegistry 排出卡片與連線
# ------------------------------------------------------------------

func _build_map() -> void:
	for c in map_content.get_children():
		c.queue_free()
	_nodes.clear()

	var centers := {}
	var col := 0
	var last_chapter := ""
	for sec in ChapterRegistry.SECTIONS:
		var id: String = sec["id"]
		var center: Vector2
		if ENDING_Y.has(id):
			# 兩個結局放在同一欄，從第六章分岔出去
			center = Vector2(START_X + NODE_SIZE.x / 2.0 + col * STEP_X, ENDING_Y[id])
		else:
			center = Vector2(START_X + NODE_SIZE.x / 2.0 + col * STEP_X, WAVE_Y[col % WAVE_Y.size()])
			col += 1
		centers[id] = center

		# 每一章開頭標上章節名稱
		var chapter: String = sec["chapter"]
		if chapter != last_chapter and not ENDING_Y.has(id):
			last_chapter = chapter
			var tag := Label.new()
			tag.text = chapter
			tag.add_theme_font_size_override("font_size", 26)
			tag.add_theme_color_override("font_color", Color("#F8D08D"))
			tag.position = Vector2(center.x - NODE_SIZE.x / 2.0, 150)
			map_content.add_child(tag)
			var mark := ColorRect.new()
			mark.color = Color(0.972549, 0.815686, 0.552941, 0.35)
			mark.position = Vector2(center.x - NODE_SIZE.x / 2.0, 192)
			mark.size = Vector2(4, 70)
			map_content.add_child(mark)

	# 結局欄：放在最後一欄
	var ending_x := START_X + NODE_SIZE.x / 2.0 + col * STEP_X
	for id in ENDING_Y:
		centers[id] = Vector2(ending_x, ENDING_Y[id])

	# 先畫線（在卡片下面）
	var order: Array = []
	for sec in ChapterRegistry.SECTIONS:
		order.append(sec["id"])
	for i in range(order.size() - 1):
		var a: String = order[i]
		var b: String = order[i + 1]
		if ENDING_Y.has(a) or ENDING_Y.has(b):
			continue
		_add_line(centers[a], centers[b], b)
	# 第六章 → 兩個結局分岔
	for id in ENDING_Y:
		_add_line(centers["ch6"], centers[id], id)

	# 再放卡片
	for sec in ChapterRegistry.SECTIONS:
		var id: String = sec["id"]
		var node = LEVEL_NODE.instantiate()
		node.level_id = id
		node.section_id = id
		# 卡片寬度有限：「結局一：天下沒有不散的宴席」只顯示「結局一」
		node.level_name = str(sec["title"]).get_slice("：", 0)
		node.thumbnail_texture = _thumbnail(sec)
		node.custom_minimum_size = NODE_SIZE
		node.size = NODE_SIZE
		node.pivot_offset = NODE_SIZE / 2.0
		node.position = centers[id] - NODE_SIZE / 2.0
		map_content.add_child(node)
		_enlarge_texts(node)
		_nodes[id] = node

	map_content.custom_minimum_size = Vector2(ending_x + NODE_SIZE.x / 2.0 + START_X, 860)


func _add_line(from: Vector2, to: Vector2, target_id: String) -> void:
	var line := Line2D.new()
	line.points = PackedVector2Array([from, to])
	line.width = 4.0
	line.set_meta("target", target_id)
	map_content.add_child(line)


## 1920×1080 下，原本卡片上的字太小，放大一點
func _enlarge_texts(node: Control) -> void:
	var title: Label = node.get_node_or_null("TitleLabel")
	if title:
		title.add_theme_font_size_override("font_size", 20)
		title.offset_top = -34
	var lock: Label = node.get_node_or_null("LockedOverlay/LockLabel")
	if lock:
		lock.add_theme_font_size_override("font_size", 20)
		lock.offset_left = -60
		lock.offset_right = 60
	var done: Control = node.get_node_or_null("CompletedIndicator")
	if done:
		done.offset_left = -110
		done.offset_bottom = 34
		var l: Label = done.get_node_or_null("Label")
		if l:
			l.add_theme_font_size_override("font_size", 15)


func _thumbnail(sec: Dictionary) -> Texture2D:
	var id: String = sec["id"]
	for ext in [".png", ".jpg", ".webp"]:
		if ResourceLoader.exists(THUMB_DIR + id + ext):
			return load(THUMB_DIR + id + ext)
	if THUMB_ART.has(id) and ResourceLoader.exists(THUMB_ART[id]):
		return load(THUMB_ART[id])
	# 沒有縮圖：用這一節的人生階段色調
	var tone := ChapterRegistry.tone(str(sec.get("tone", "birth")))
	var grad := Gradient.new()
	grad.set_color(0, tone["top"])
	grad.set_color(1, tone["bottom"])
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill_from = Vector2(0.5, 0)
	gt.fill_to = Vector2(0.5, 1)
	gt.width = 32
	gt.height = 32
	return gt


# ------------------------------------------------------------------
# 狀態
# ------------------------------------------------------------------

## 更新整張地圖的卡片狀態與連接線顏色
func update_map() -> void:
	for id in _nodes:
		var node = _nodes[id]
		node.force_unlocked = _unlock_all
		node.update_status()
	for c in map_content.get_children():
		if c is Line2D:
			var target: String = c.get_meta("target", "")
			var unlocked := _unlock_all or GameState.is_section_unlocked(target)
			c.default_color = LINE_UNLOCKED if unlocked else LINE_LOCKED
	_mark_current()


## 目前所在的小節：卡片上方一個金色的「▼ 目前」
func _mark_current() -> void:
	var old := map_content.get_node_or_null("CurrentMark")
	if old:
		old.queue_free()
	var node = _nodes.get(GameState.section_id)
	if node == null:
		return
	var mark := Label.new()
	mark.name = "CurrentMark"
	mark.text = "▼ 目前"
	mark.add_theme_font_size_override("font_size", 22)
	mark.add_theme_color_override("font_color", Color("#F8D08D"))
	mark.position = node.position + Vector2(NODE_SIZE.x / 2.0 - 34, -40)
	map_content.add_child(mark)


func _scroll_to_current() -> void:
	await get_tree().process_frame
	var node = _nodes.get(GameState.section_id)
	if node:
		scroll.scroll_horizontal = int(maxf(0.0, node.position.x - 600.0))


## 滑鼠滾輪也能左右捲動
func _on_scroll_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			scroll.scroll_horizontal += 120
			scroll.accept_event()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			scroll.scroll_horizontal -= 120
			scroll.accept_event()


func _on_back_pressed() -> void:
	if GameFlow.map_return_to_game and GameState.user_name != "":
		GameFlow.continue_game()
	else:
		get_tree().change_scene_to_file("res://login_screen.tscn")


func _on_reset_pressed() -> void:
	print("🔄 重設玩家進度...")
	GameState.reset_progress()
	update_map()
	_scroll_to_current()
