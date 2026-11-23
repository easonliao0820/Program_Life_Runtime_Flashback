extends Node

## 錄影用：示範「寫程式時，用左邊的輸入框跟派森／角色聊天」。
## 劇情用觀看模式快轉到 3.2 的第一個程式關卡，進關卡後改成真實速度，
## 自動在輸入框打字問問題、等 AI 回答，最後把程式寫完按執行。
##   錄：godot --path . --write-movie out.avi --fixed-fps 30 res://tests/record_ai_chat.tscn
## 終端機會印出 REC_START_FRAME=n，剪片時從那一格開始即可。
## 不會動到玩家存檔。

const STAGE_SCENE := preload("res://src/game/stage/game_stage.tscn")
const FROM := "ch3_2"
const FAST := 8.0
const FRAME_USEC := 33333   ## 進關卡後每格至少 1/30 秒（真實時間），讓錄影跟現實同速、AI 不會逾時

## [對象, 問題, 回答後停留秒數]
const SCRIPT := [
	["派森", "派森，for 迴圈到底是什麼？", 9.0],
	["派森", "這關我卡住了，可以給我一點提示嗎？", 9.0],
	["倖芳", "倖芳，最後 100 天你會緊張嗎？", 9.0],
]

var _stage: Node
var _throttle := false
var _last_usec := 0
var _started := false


func _ready() -> void:
	GameState.save_path = "user://plrf_rec_ai_save_%d.json" % OS.get_process_id()
	GameState.new_game("觀看者")
	GameState.settings["ai_enabled"] = true
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


func _process(_delta: float) -> void:
	if _throttle:
		var spent := Time.get_ticks_usec() - _last_usec
		if spent < FRAME_USEC:
			OS.delay_usec(FRAME_USEC - spent)
	_last_usec = Time.get_ticks_usec()


## 進第一個程式關卡的那一刻：關掉自動駕駛（這關不自動解）、恢復正常速度
func _on_coding_visible() -> void:
	if _started or not _stage.coding_mode.visible:
		return
	_started = true
	GameFlow.autopilot = false
	GameFlow.autopilot_watch = false
	GameState.set_value("seen_coding_tutorial", true)
	GameState.set_value("chat_unlocked", true)
	Engine.time_scale = 1.0
	_throttle = true
	print("REC_START_FRAME=", Engine.get_frames_drawn())
	_demo.call_deferred()


func _demo() -> void:
	var chat = _stage.chat
	if not _stage._scene_people.has("倖芳"):
		_stage._scene_people.append("倖芳")
	_stage._refresh_chat()
	await _wait(3.0)

	for item in SCRIPT:
		var who: String = item[0]
		await _switch_to(chat, who)
		await _type(chat._input, item[1])
		await _wait(0.5)
		chat._on_send()
		chat._input.text = item[1]   # 錄影用：送出後問題留在輸入框，讓觀眾看得到問了什麼
		await _wait(0.3)
		while chat._busy:
			await get_tree().process_frame
		print("[%s] %s → %s" % [who, item[1], chat._bubble_text.text])
		await _wait(item[2])
		chat.hide_bubble()
		await _wait(0.8)

	# 收尾：把程式寫完、按執行
	chat._input.text = ""
	var cm = _stage.coding_mode
	await cm._type_out(cm.fill_code(str(cm._level.get("solution", ""))))
	await cm._on_run()
	await _wait(5.0)
	print("REC_END_FRAME=", Engine.get_frames_drawn())
	_quit()


func _switch_to(chat, who: String) -> void:
	var guard := 0
	while chat.target != who and guard < 10:
		chat._next_target()
		guard += 1
		await _wait(0.6)


func _type(input: LineEdit, text: String) -> void:
	input.grab_focus()
	input.text = ""
	for ch in text:
		input.text += ch
		input.caret_column = input.text.length()
		await _wait(0.11)


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


func _quit() -> void:
	_throttle = false
	Engine.time_scale = 1.0
	GameState.delete_save()
	get_tree().quit()
