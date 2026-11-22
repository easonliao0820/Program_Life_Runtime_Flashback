extends Node

## GameFlow（Autoload）：決定「現在該去哪個畫面、播哪一節」。
##
## 整體流程：
##   login_screen（登入） → prologue.tscn（前言動畫） → name_input（輸入名字／繼續遊戲）
##   → game_stage（依 ChapterRegistry 一節一節播放 .story 劇本）
##   → 第六章結局判定 → 結局一／結局二 → 工作人員名單 → 回到登入畫面
## Google 登入驗證成功則走 start_after_login：有存檔繼續，無存檔開章節選擇。

const TITLE_SCENE := "res://login_screen.tscn"
const NAME_INPUT_SCENE := "res://src/game/components/name_input.tscn"
const STAGE_SCENE := "res://src/game/stage/game_stage.tscn"
const MAP_SCENE := "res://src/ui/level_select/level_select.tscn"

## 自動駕駛（tests/full_playthrough_test 用）：自動點對話、選第一個選項、用參考解答過關。
var autopilot: bool = false
## 觀看模式（tests/watch_playthrough 用）：一樣自動玩，但對話用正常速度播，讓人看得清楚。
var autopilot_watch: bool = false
## 預覽工具用：打開 game_stage 但不自動播劇情（tests/credits_preview）
var stage_preview: bool = false
signal autopilot_finished

## 開發用：從章節選擇跳進某一節時，帶著預設的旗標，避免缺少前面章節的變數。
const DEBUG_DEFAULT_FLAGS := {"gave_gift": true}


## 背景音樂放在常駐節點上，換場景（前言 → 輸入名字 → 第一章）也不會中斷。
const AUDIO_DIR := "res://assets/audio/"
const BGM_VOLUME := -12.0  # 背景音樂音量（dB），越小越安靜
## 每首原檔大小聲不一樣，這裡補成差不多大聲（dB，正數＝放大）
const BGM_GAIN := {
	"prologue": -4.0, "school": -1.0, "tension": 4.0, "campus": 0.0, "romance": -3.0,
	"office": -2.0, "nostalgia": 2.0, "farewell": 0.0, "hope": 10.0,
	"childhood": 3.0, "warm": -4.0,
}
const BGM_FADE_IN := 1.2
var _bgm: AudioStreamPlayer
var _bgm_name := ""
var _bgm_fade: Tween


func _ready() -> void:
	if _is_mobile_device():
		_show_desktop_only.call_deferred()
	_bgm = AudioStreamPlayer.new()
	_bgm.volume_db = BGM_VOLUME
	# 播完從頭再播，直到 stop_bgm()
	_bgm.finished.connect(func(): if _bgm_name != "": _bgm.play())
	add_child(_bgm)
	if ResourceLoader.exists(TYPE_SOUND):
		var st: AudioStream = load(TYPE_SOUND)
		for i in 4:
			var p := AudioStreamPlayer.new()
			p.stream = st
			p.volume_db = TYPE_VOLUME
			add_child(p)
			_type_players.append(p)


## 打字聲：對話框、黑幕文字每跳出一個字呼叫一次。
## 有節流（太快時跳過幾個字）、音高稍微隨機，聽起來不會像機關槍。
const TYPE_SOUND := "res://assets/audio/type_blip.wav"
const TYPE_VOLUME := -16.0
const TYPE_GAP_MS := 55
var _type_players: Array[AudioStreamPlayer] = []
var _type_last := 0
var _type_i := 0


func type_tick(ch: String = "x") -> void:
	if _type_players.is_empty() or (autopilot and not autopilot_watch):
		return
	if ch.strip_edges() == "" or "，。、！？：；…—「」『』（）,.!?:;()\"'".contains(ch):
		return
	var now := Time.get_ticks_msec()
	if now - _type_last < TYPE_GAP_MS:
		return
	_type_last = now
	var p := _type_players[_type_i]
	_type_i = (_type_i + 1) % _type_players.size()
	p.pitch_scale = randf_range(0.85, 1.15)
	p.play()


## 手機、平板不能玩（要用鍵盤寫程式）：網頁版看瀏覽器，原生版看作業系統。
## 測試用：加上命令列參數 -- --pretend-mobile 可以假裝是手機。
func _is_mobile_device() -> bool:
	if "--pretend-mobile" in OS.get_cmdline_user_args():
		return true
	if OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios"):
		return true
	if OS.has_feature("web"):
		# iPad 的 Safari 會假裝自己是 Mac，要再看能不能多點觸控
		var r = JavaScriptBridge.eval("""(function(){var u=navigator.userAgent||'';
			return /Android|iPhone|iPad|iPod|Mobile|Silk|Kindle|Opera Mini|IEMobile/i.test(u)
				|| (navigator.platform==='MacIntel' && navigator.maxTouchPoints>1);})()""", true)
		return r == true
	return false


func _show_desktop_only() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 128
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	var bg := ColorRect.new()
	bg.color = Color("#161F2B")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(bg)
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 28)
	bg.add_child(v)
	var title := UIKit.label("請用電腦遊玩", 72, UIKit.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var body := UIKit.label("《派森與我的一生》需要用鍵盤寫程式，\n請用桌上型電腦或筆電開啟。", 36, Color("#e6edf3"))
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(body)
	get_tree().root.add_child(layer)
	get_tree().paused = true


func _bgm_target(audio_name: String) -> float:
	return BGM_VOLUME + float(BGM_GAIN.get(audio_name, 0.0))


## 播背景音樂：同一首已經在播就不重來（前言開始的音樂接到第一章）；
## 換別首時先淡出再淡入；檔案還沒放進來就把目前的音樂淡出，不要讓上一首的氣氛延續下去。
func play_bgm(audio_name: String) -> void:
	if audio_name == "" or audio_name == "off":
		stop_bgm()
		return
	if audio_name == _bgm_name and _bgm.playing:
		return
	var path := ""
	for ext in [".ogg", ".mp3", ".wav"]:
		if ResourceLoader.exists(AUDIO_DIR + audio_name + ext):
			path = AUDIO_DIR + audio_name + ext
			break
	if path == "":
		print("[GameFlow] 音樂尚未放入：", AUDIO_DIR + audio_name)
		stop_bgm()
		return
	var was_playing := _bgm.playing and _bgm_name != ""
	_bgm_name = audio_name
	if _bgm_fade:
		_bgm_fade.kill()
	_bgm_fade = create_tween()
	if was_playing:
		_bgm_fade.tween_property(_bgm, "volume_db", -40.0, 0.8)
	_bgm_fade.tween_callback(func():
		_bgm.stream = load(path)
		_bgm.volume_db = -40.0
		_bgm.play())
	_bgm_fade.tween_property(_bgm, "volume_db", _bgm_target(audio_name), BGM_FADE_IN)


## 背景音樂淡出
func stop_bgm(fade: float = 1.5) -> void:
	if _bgm_name == "":
		return
	_bgm_name = ""
	if _bgm_fade:
		_bgm_fade.kill()
	_bgm_fade = create_tween()
	_bgm_fade.tween_property(_bgm, "volume_db", -40.0, fade)
	_bgm_fade.tween_callback(_bgm.stop)


## 前言動畫播完呼叫：有存檔就讓玩家選「繼續」，沒有就輸入名字。
func start_game() -> void:
	get_tree().change_scene_to_file(NAME_INPUT_SCENE)


## Google 驗證成功後的入口；未來可在此替換成雲端存檔查詢與載入。
## 現階段使用本機存檔，從記錄的小節開頭繼續；無進度則開章節選擇。
func start_after_login(player_name: String) -> Error:
	# 地圖不是從遊戲內開啟，返回時應回標題，避免沿用上一輪的返回旗標。
	map_return_to_game = false
	# 先確認有存檔，再載入；目前是共用本機檔，尚未依帳號隔離或查 DynamoDB。
	if GameState.has_save() and GameState.load_game():
		if ChapterRegistry.index_of(GameState.section_id) >= 0:
			# 從該小節開頭繼續，不會還原到逐句對話或程式執行的中途。
			return get_tree().change_scene_to_file(STAGE_SCENE)
		# 舊存檔的小節已不存在時保留其他進度，讓玩家從地圖選擇。
		GameState.section_id = ChapterRegistry.first_section_id()
		GameState.mark_reached(GameState.section_id)
	else:
		# 首次登入先建立第一章初始狀態，讓章節地圖有可選的起始小節。
		# 沒有提供 Google 姓名時用「你」，避免建立空名字而被判定無存檔。
		var name := player_name.strip_edges()
		GameState.new_game(name if name != "" else "你")
	# 回傳場景切換錯誤，登入畫面才能在失敗時恢復按鈕。
	return get_tree().change_scene_to_file(MAP_SCENE)


func new_game(player_name: String) -> void:
	GameState.new_game(player_name)
	_open_stage()


func continue_game() -> void:
	if not GameState.load_game():
		get_tree().change_scene_to_file(NAME_INPUT_SCENE)
		return
	_open_stage()


## 開發／測試用：直接跳到某一節。
func debug_jump(section_id: String) -> void:
	if GameState.user_name == "":
		GameState.new_game("測試員")
	for k in DEBUG_DEFAULT_FLAGS:
		if not GameState.flags.has(k):
			GameState.flags[k] = DEBUG_DEFAULT_FLAGS[k]
	goto_section(section_id)


func goto_section(section_id: String) -> void:
	if ChapterRegistry.index_of(section_id) < 0:
		push_error("[GameFlow] 找不到章節：%s" % section_id)
		return
	GameState.section_id = section_id
	GameState.mark_reached(section_id)
	GameState.save_game()
	var stage := _current_stage()
	if stage:
		stage.play_section(section_id)
	else:
		_open_stage()


## 一節播完後由 GameStage 呼叫。
func section_finished(section_id: String) -> void:
	GameState.mark_completed(section_id)
	var next_id := ChapterRegistry.next_section_id(section_id)
	if next_id == "":
		finish_game()
	else:
		goto_section(next_id)


## 第六章：依「第一次就通過」的比例決定結局。
func decide_ending() -> String:
	return "ch6_end2" if GameState.completion() >= ChapterRegistry.ENDING_THRESHOLD else "ch6_end1"


func finish_game() -> void:
	if autopilot:
		autopilot_finished.emit()
		return
	# 破關後保留成就與名字，下一輪從第一章（含序章）開始
	GameState.section_id = ChapterRegistry.first_section_id()
	GameState.save_game()
	stop_bgm()
	get_tree().change_scene_to_file(TITLE_SCENE)


## 記憶地圖的「返回」：從遊戲裡打開的就回到遊戲，否則回到登入畫面
var map_return_to_game: bool = false


## 記憶地圖（MEMORY LOAD，src/ui/level_select）：原本的關卡地圖，改成顯示新架構的全部小節
func open_map(from_game: bool = false) -> void:
	map_return_to_game = from_game
	if GameState.user_name == "" and GameState.has_save():
		GameState.load_game()
	GameState.save_game()
	get_tree().change_scene_to_file(MAP_SCENE)


## 從記憶地圖點選某一節：從那一節開頭開始播
func play_from_map(section_id: String) -> void:
	if GameState.user_name == "":
		if not GameState.load_game():
			GameState.new_game("你")
	GameState.section_id = section_id
	GameState.mark_reached(section_id)
	GameState.save_game()
	_open_stage()


func back_to_title() -> void:
	GameState.save_game()
	stop_bgm()
	get_tree().change_scene_to_file(TITLE_SCENE)


func _open_stage() -> void:
	get_tree().change_scene_to_file(STAGE_SCENE)


func _current_stage() -> Node:
	var scene := get_tree().current_scene
	if scene and scene.has_method("play_section"):
		return scene
	return null
