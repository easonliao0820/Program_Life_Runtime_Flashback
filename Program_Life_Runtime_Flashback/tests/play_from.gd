extends Node

## 試玩：從某一節開始自己玩（不用登入、不會蓋掉正式存檔）。
##   開：godot --path . res://tests/play_from.tscn -- --from=ch3_1
##   例：ch2_1（嬰兒客廳）、ch3_1（整理書包）、ch3_4（學測當天）

func _ready() -> void:
	var from := "ch2_1"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--from="):
			from = a.substr(7)
	GameState.save_path = "user://plrf_trial_save.json"
	GameState.new_game("試玩者")
	GameFlow.autopilot = false
	GameFlow.autopilot_watch = false
	GameFlow.debug_jump.call_deferred(from)
