extends Control

## 探索模式試玩：不用從頭玩，直接進某一關的探索。
##   開：godot --path . res://tests/explore_preview.tscn -- --level=ch3_1
##   --level= ch2_1 / ch3_1 / ch3_4（預設 ch3_1）
##   玩完會自動關掉，左上會印出最後的清單。
##   自動截圖（開發用）：加 --shots=<資料夾>，會自己走一段路並截圖

const ExploreMode := preload("res://src/game/modes/explore_mode.gd")

const LEVELS := {
	"ch2_1": ["res://chapters/chapter_2/story/ch2_1.story", "ch2_1_boxes"],
	"ch3_1": ["res://chapters/chapter_3/story/ch3_1.story", "ch3_1_bag"],
	"ch3_4": ["res://chapters/chapter_3/story/ch3_4.story", "ch3_4_bag"],
}

var _mode: Control
var _say: Label
var _shots := ""


func _ready() -> void:
	UIKit.full_rect(self)
	var bg := ColorRect.new()
	bg.color = Color("#1b2230")
	UIKit.full_rect(bg)
	add_child(bg)
	var level := "ch3_1"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--level="):
			level = a.substr(8)
		elif a.begins_with("--shots="):
			_shots = a.substr(8)
	GameState.new_game("試玩")
	GameFlow.autopilot = false

	_say = UIKit.label("", 26, Color.WHITE)
	_say.position = UIKit.SPLIT_STORY.position + Vector2(20, 20)
	_say.custom_minimum_size = Vector2(UIKit.SPLIT_STORY.size.x - 40, 0)
	_say.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_say)
	_mode = ExploreMode.new()
	_mode.speak = func(text: String, _mood: String): _say.text = "派森：" + text
	add_child(_mode)

	var def := _find_def(LEVELS[level][0], LEVELS[level][1])
	if _shots != "":
		_bot.call_deferred(level)
	var result: Dictionary = await _mode.play(def)
	print("[explore_preview] 結果：", result["items"])
	print(result["code"])
	get_tree().quit()


func _find_def(path: String, id: String) -> Dictionary:
	var parsed: Dictionary = StoryParser.parse_file(path)
	var stack: Array = [parsed["events"]]
	while not stack.is_empty():
		for ev in stack.pop_back():
			if ev is Dictionary:
				if ev.get("type", "") == "explore" and ev["explore"].get("id", "") == id:
					return ev["explore"]
				for k in ev:
					if ev[k] is Array:
						stack.append(ev[k])
	push_error("找不到探索關卡 " + id)
	return {}


# ---------------- 自動走一段路並截圖（開發用）----------------

func _key(code: Key, down: bool) -> void:
	var e := InputEventKey.new()
	e.keycode = code
	e.physical_keycode = code
	e.pressed = down
	Input.parse_input_event(e)


func _hold(code: Key, sec: float) -> void:
	_key(code, true)
	await get_tree().create_timer(sec).timeout
	_key(code, false)
	await get_tree().process_frame


func _tap(code: Key) -> void:
	await _hold(code, 0.05)
	await get_tree().create_timer(0.2).timeout


func _shot(n: String) -> void:
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(_shots)
	get_viewport().get_texture().get_image().save_png(_shots.path_join(n + ".png"))


func _bot(level: String) -> void:
	await get_tree().create_timer(0.6).timeout
	await _shot("0_start")
	match level:
		"ch3_1":
			await _hold(KEY_RIGHT, 0.6)      # 書架
			await _tap(KEY_E)                # 數學課本
			await _shot("1_bookshelf")
			await _hold(KEY_RIGHT, 1.45)     # 樓梯口
			await _tap(KEY_DOWN)             # 下樓梯
			await _hold(KEY_DOWN, 1.0)
			await _shot("2_on_stairs")
			await _hold(KEY_DOWN, 3.0)
			await _hold(KEY_RIGHT, 1.0)
			await _shot("3_livingroom")
			await _hold(KEY_RIGHT, 3.5)
			await _shot("4_door")
		"ch2_1":
			await _hold(KEY_RIGHT, 0.3)
			await _shot("1_push")
			await _tap(KEY_UP)
			await _shot("2_climb")
		"ch3_4":
			await _hold(KEY_RIGHT, 0.4)
			await _tap(KEY_E)
			await _shot("1_open")
			await _hold(KEY_RIGHT, 1.5)
			await _shot("2_dark")
	get_tree().quit()
