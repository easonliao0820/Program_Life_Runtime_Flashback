extends Node

## 錄影用：第一次進程式關卡時，派森帶玩家認識畫面（任務卡／程式區／執行／輸出／提示、重置）。
## 劇情用觀看模式快轉到第一章第一關，進關卡後恢復正常速度，導覽每一步停幾秒自動往下，
## 最後把程式寫完按執行。
##   錄：godot --path . --write-movie out.avi --fixed-fps 30 res://tests/record_tutorial.tscn
## 不會動到玩家存檔。

const STAGE_SCENE := preload("res://src/game/stage/game_stage.tscn")
const FROM := "ch1"
const FAST := 8.0
const STEP_SEC := [4.0, 3.0, 4.0, 4.0, 4.0, 2.5]   ## 導覽每一步停留秒數

var _stage: Node
var _started := false


func _ready() -> void:
	GameState.save_path = "user://plrf_rec_tut_save_%d.json" % OS.get_process_id()
	GameState.new_game("觀看者")
	GameState.settings["ai_enabled"] = false
	GameState.settings["auto_delay"] = 1.6
	for k in GameFlow.DEBUG_DEFAULT_FLAGS:
		GameState.flags[k] = GameFlow.DEBUG_DEFAULT_FLAGS[k]
	GameState.section_id = FROM
	GameFlow.autopilot = true
	GameFlow.autopilot_watch = true
	Engine.time_scale = FAST

	_stage = STAGE_SCENE.instantiate()
	add_child(_stage)
	_stage.coding_mode.visibility_changed.connect(_on_coding_visible)


func play_section(section_id: String) -> void:
	_stage.play_section(section_id)


## 進關卡後每格至少 1/30 秒（真實時間），錄影才會跟遊戲時間對得上
var _throttle := false
var _last_usec := 0
func _process(_delta: float) -> void:
	if _throttle:
		var spent := Time.get_ticks_usec() - _last_usec
		if spent < 33333:
			OS.delay_usec(33333 - spent)
	_last_usec = Time.get_ticks_usec()


## 進第一個程式關卡：關掉自動駕駛，導覽就會照一般玩家第一次進來那樣出現
func _on_coding_visible() -> void:
	if _started or not _stage.coding_mode.visible:
		return
	_started = true
	GameFlow.autopilot = false
	GameFlow.autopilot_watch = false
	Engine.time_scale = 1.0
	_throttle = true
	print("REC_START_FRAME=", Engine.get_frames_drawn())
	_demo.call_deferred()


func _demo() -> void:
	var cm = _stage.coding_mode
	while not cm._tutorial_active:
		await get_tree().process_frame
	for sec in STEP_SEC:
		await _wait(sec)
		if not cm._tutorial_active:
			break
		cm._tutorial_next.emit()
	await _wait(0.8)

	# 輪到玩家：把程式寫完、按執行
	await cm._type_out(cm.fill_code(str(cm._level.get("solution", ""))))
	await cm._on_run()
	await _wait(3.5)
	print("REC_END_FRAME=", Engine.get_frames_drawn())
	_quit()


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


func _quit() -> void:
	Engine.time_scale = 1.0
	GameState.delete_save()
	get_tree().quit()
