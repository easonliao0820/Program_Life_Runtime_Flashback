extends Node

## 觀看模式：從頭自動播到結局，對話用正常速度，選項、程式關卡、輸入框自動處理。
## 不會動到玩家存檔。
##   開：godot --path . res://tests/watch_playthrough.tscn
##   按鍵：+ / - 調速度（0.5～8 倍）　Esc 離開
##   選項（加在 -- 後面）：
##     --from=ch3_2      從某一節開始
##     --speed=2         一開始的速度
##     --shots=<資料夾>  每換一次背景／CG 自動截一張圖
##     --every=3         搭配 --shots，另外每 3 秒（遊戲時間）截一張

const STAGE_SCENE := preload("res://src/game/stage/game_stage.tscn")

var _stage: Node
var _speed := 1.0
var _shots := ""
var _shot_n := 0
var _last_bg := ""
var _hud: Label
var _every := 0.0
var _every_t := 0.0


func _ready() -> void:
	var from := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--from="):
			from = a.substr(7)
		elif a.begins_with("--speed="):
			_speed = float(a.substr(8))
		elif a.begins_with("--shots="):
			_shots = a.substr(8)
		elif a.begins_with("--every="):
			_every = float(a.substr(8))

	GameState.save_path = "user://plrf_watch_save_%d.json" % OS.get_process_id()
	GameState.new_game("觀看者")
	GameState.settings["ai_enabled"] = false
	GameState.settings["auto_delay"] = 1.6
	if from != "":
		for k in GameFlow.DEBUG_DEFAULT_FLAGS:
			GameState.flags[k] = GameFlow.DEBUG_DEFAULT_FLAGS[k]
		GameState.section_id = from
	GameFlow.autopilot = true
	GameFlow.autopilot_watch = true
	GameFlow.autopilot_finished.connect(_on_finished, CONNECT_ONE_SHOT)
	Engine.time_scale = _speed

	_stage = STAGE_SCENE.instantiate()
	add_child(_stage)

	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	_hud = Label.new()
	_hud.position = Vector2(1500, 8)
	_hud.add_theme_font_size_override("font_size", 20)
	_hud.add_theme_color_override("font_color", Color.WHITE)
	_hud.add_theme_color_override("font_outline_color", Color.BLACK)
	_hud.add_theme_constant_override("outline_size", 5)
	layer.add_child(_hud)


## GameFlow.goto_section 會呼叫 current_scene.play_section，這裡轉交給舞台
func play_section(section_id: String) -> void:
	print("▶ ", section_id)
	_stage.play_section(section_id)


func _process(delta: float) -> void:
	if _shots != "" and _every > 0.0:
		_every_t += delta
		if _every_t >= _every:
			_every_t = 0.0
			_snap.call_deferred("t")
	_hud.text = "觀看模式 %s 倍速｜%s｜+/- 調速度　Esc 離開" % [str(_speed), GameState.section_id]
	if _shots == "" or not _stage.get("bg"):
		return
	var key: String = _stage.bg.bg_key
	if key != _last_bg:
		_last_bg = key
		_snap.call_deferred(key)


func _snap(key: String) -> void:
	await get_tree().create_timer(1.6).timeout   # 等淡入完成（計時會跟著倍速）
	await RenderingServer.frame_post_draw
	_shot_n += 1
	var path := "%s/%03d_%s_%s.png" % [_shots, _shot_n, GameState.section_id, key.replace(":", "_")]
	get_viewport().get_texture().get_image().save_png(path)


func _unhandled_input(e: InputEvent) -> void:
	if not (e is InputEventKey and e.pressed and not e.echo):
		return
	match e.keycode:
		KEY_EQUAL, KEY_KP_ADD, KEY_PLUS:
			_speed = minf(_speed * 2.0, 8.0)
		KEY_MINUS, KEY_KP_SUBTRACT:
			_speed = maxf(_speed / 2.0, 0.5)
		KEY_ESCAPE:
			_quit()
			return
		_:
			return
	Engine.time_scale = _speed


func _on_finished() -> void:
	print("■ 播完了")
	await get_tree().create_timer(3.0).timeout
	_quit()


func _quit() -> void:
	Engine.time_scale = 1.0
	GameFlow.autopilot = false
	GameFlow.autopilot_watch = false
	GameState.delete_save()
	get_tree().quit()
