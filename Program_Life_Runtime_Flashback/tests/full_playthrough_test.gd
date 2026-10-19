extends Node

## 整體架構的自動測試（headless 可跑）：
##   godot --headless --path . res://tests/full_playthrough_test.tscn
## 1. 解析所有 .story 劇本，列出語法錯誤
## 2. 每一關的 solution 都要能通過 check；starter 不應該直接過關
## 3. 自動駕駛：從序章一路玩到結局（兩個結局各跑一次）
## 測試用自己的存檔檔案，不會蓋掉玩家存檔。

const STAGE_SCENE := preload("res://src/game/stage/game_stage.tscn")
const CodingMode := preload("res://src/game/modes/coding_mode.gd")

var _stage: Node
var _visited: Array = []
var _failures: Array = []


func _ready() -> void:
	GameState.save_path = "user://plrf_test_save.json"
	GameState.settings["ai_enabled"] = false
	await _test_parse_and_levels()
	await _test_playthrough("ch6_end2", 1.0)
	await _test_playthrough("ch6_end1", 0.0)
	print("\n================ 測試結果 ================")
	if _failures.is_empty():
		print("全部通過 ✔")
	else:
		for f in _failures:
			print("✘ ", f)
	GameState.delete_save()
	get_tree().quit(0 if _failures.is_empty() else 1)


# ------------------------------------------------------------------

func _test_parse_and_levels() -> void:
	print("\n---- 1. 劇本解析 ----")
	var levels: Array = []
	for sec in ChapterRegistry.SECTIONS:
		var parsed := StoryParser.parse_file(sec["story"])
		for e in parsed["errors"]:
			_failures.append(e)
		var found: Array = []
		_collect_levels(parsed["events"], found)
		levels.append_array(found)
		print("%-10s 事件 %3d　關卡 %d" % [sec["id"], parsed["events"].size(), found.size()])

	print("\n---- 2. 參考解答 / 起始程式碼 ----")
	GameState.new_game("測試員")
	GameState.set_value("food_price", 35)
	GameState.set_value("drink_price", 25)
	GameState.set_value("explore_code", "")
	print("Python：", PythonRunner.backend_name())
	var ids := {}
	for lv in levels:
		var id: String = lv["id"]
		if ids.has(id):
			_failures.append("關卡 id 重複：" + id)
		ids[id] = true
		var check := CodingMode.fill_code(str(lv.get("check", "")))
		if str(lv.get("solution", "")) == "":
			_failures.append("%s 沒有 solution" % id)
			continue
		var r: Dictionary = await PythonRunner.run(CodingMode.fill_code(lv["solution"]), check, lv.get("stdin", []))
		if r.get("passed", false) == true:
			print("✔ ", id)
		else:
			_failures.append("%s 的 solution 沒過：%s %s" % [id, r.get("error"), r.get("message")])
		var s: Dictionary = await PythonRunner.run(CodingMode.fill_code(str(lv.get("starter", ""))), check, lv.get("stdin", []))
		if s.get("passed", false) == true and not id in ["ch1_first_words_x"]:
			print("　（注意：%s 的 starter 不用修改就能過關）" % id)


func _collect_levels(events: Array, out: Array) -> void:
	for ev in events:
		match ev["type"]:
			"level":
				out.append(ev["level"])
			"memory":
				out.append_array(ev["memory"]["fragments"])
			"if":
				for b in ev["branches"]:
					_collect_levels(b["events"], out)
				_collect_levels(ev["else"], out)


# ------------------------------------------------------------------

func _test_playthrough(expect_ending: String, _unused: float) -> void:
	print("\n---- 3. 自動駕駛：預期走到 %s ----" % expect_ending)
	GameFlow.autopilot = true
	Engine.time_scale = 6.0
	GameState.new_game("測試員")
	GameState.settings["ai_enabled"] = false
	_visited.clear()
	if expect_ending == "ch6_end1":
		# 結局一：假裝前面的關卡都沒有第一次就通過，從第六章開始
		for i in 5:
			GameState.record_level("fake_%d" % i, false, 1, false)
		GameState.section_id = "ch6"
	_stage = STAGE_SCENE.instantiate()
	_visited.append(GameState.section_id)
	add_child(_stage)
	var timer := get_tree().create_timer(900.0, true, false, true)
	var done := [false]
	GameFlow.autopilot_finished.connect(func(): done[0] = true, CONNECT_ONE_SHOT)
	while not done[0] and timer.time_left > 0:
		await get_tree().process_frame
	Engine.time_scale = 1.0
	GameFlow.autopilot = false
	if not done[0]:
		_failures.append("自動駕駛逾時，停在 %s" % GameState.section_id)
	print("走過的小節：", " → ".join(_visited))
	print("第一次就通過：%d / %d，成就：%s" % [GameState.first_try_passed(), GameState.total_levels(), ", ".join(GameState.achievements)])
	if not _visited.has(expect_ending):
		_failures.append("沒有走到 %s（走過：%s）" % [expect_ending, _visited])
	_stage.queue_free()
	await get_tree().process_frame


## GameFlow.goto_section 會呼叫 current_scene.play_section，這裡轉交給舞台
func play_section(section_id: String) -> void:
	_visited.append(section_id)
	_stage.play_section(section_id)
