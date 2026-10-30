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
signal autopilot_finished

## 開發用：從章節選擇跳進某一節時，帶著預設的旗標，避免缺少前面章節的變數。
const DEBUG_DEFAULT_FLAGS := {"gave_gift": true}


## 訪客前言動畫播完呼叫：有存檔就讓玩家選「繼續」，沒有就輸入名字。
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
	get_tree().change_scene_to_file(TITLE_SCENE)


func _open_stage() -> void:
	get_tree().change_scene_to_file(STAGE_SCENE)


func _current_stage() -> Node:
	var scene := get_tree().current_scene
	if scene and scene.has_method("play_section"):
		return scene
	return null
