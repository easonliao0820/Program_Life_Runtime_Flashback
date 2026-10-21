extends Node

## GameState（Autoload）：整趟人生的「記憶」。
## - user_name：遊戲開始時輸入的名字，劇本裡的 {userName} 都會被替換。
## - flags：影響劇情的旗標，例如 gave_gift（3.1 書包裡有沒有手作巧克力）。
## - vars：劇本執行中暫存的值，例如 last_output（上一關印出的內容）、breakfast（點的早餐）。
## - levels：每個關卡的成績，用來算「第一次就通過」的比例，決定結局。

signal achievement_unlocked(achievement_id: String)
signal value_changed(key: String, value: Variant)

## 測試時會改成別的檔案，避免蓋掉玩家存檔
var save_path: String = "user://plrf_save.json"
const SAVE_VERSION := 2
## 舊版預設的閱讀速度：存檔裡還是這個值，代表玩家沒調過，改用新的（較慢的）預設
const OLD_DEFAULT_SPEED := {"text_speed": 40.0, "auto_delay": 1.6}

var user_name: String = ""
var section_id: String = ""
var age: int = 0
var flags: Dictionary = {}
var vars: Dictionary = {}
## level_id -> {"passed": bool, "first_try": bool, "errors": int, "hint_used": bool, "counts": bool}
var levels: Dictionary = {}
var achievements: Array = []
## 記憶地圖（MEMORY LOAD）用：走過的小節會解鎖、播完的小節會打勾
var reached_sections: Array = []
var completed_sections: Array = []
## 對話紀錄（會存檔）：
## - backlog：「回顧」裡的劇情台詞與聊天，[{speaker, text}]
## - chat_history：主角跟每個角色聊過的話，{角色: [{"q": 問, "a": 答}]}，問問題時會帶給 AI，讓角色記得
const BACKLOG_LIMIT := 200
const CHAT_MEMORY_LIMIT := 20
var backlog: Array = []
var chat_history: Dictionary = {}
var settings: Dictionary = {
	"text_speed": 25.0,      # 每秒幾個字（節奏放慢：原本 40）
	"auto_delay": 2.6,       # 自動模式下，一句播完後停幾秒（原本 1.6）
	"ai_enabled": true,      # 關掉時一律使用【備用台詞】
	"master_volume": 0.8,
}


func _ready() -> void:
	_load_settings_only()
	apply_volume()


## 主音量（設定面板與原本齒輪選單共用）
func apply_volume() -> void:
	var bus := AudioServer.get_bus_index("Master")
	if bus != -1:
		AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(float(settings.get("master_volume", 0.8)), 0.0001)))


# ------------------------------------------------------------------
# 新遊戲 / 存讀檔
# ------------------------------------------------------------------

func new_game(player_name: String) -> void:
	user_name = player_name.strip_edges()
	section_id = ChapterRegistry.first_section_id()
	age = 0
	flags = {"gave_gift": false}
	vars = {}
	levels = {}
	achievements = []
	reached_sections = [section_id]
	completed_sections = []
	backlog = []
	chat_history = {}
	save_game()


## 記憶地圖的「重設」：清掉進度（保留名字、成就與設定），從序章重新開始
func reset_progress() -> void:
	section_id = ChapterRegistry.first_section_id()
	age = 0
	flags = {"gave_gift": false}
	vars = {}
	levels = {}
	reached_sections = [section_id]
	completed_sections = []
	save_game()


func add_backlog(speaker: String, text: String) -> void:
	backlog.append({"speaker": speaker, "text": text})
	if backlog.size() > BACKLOG_LIMIT:
		backlog = backlog.slice(backlog.size() - BACKLOG_LIMIT)


func remember_chat(character: String, question: String, answer: String) -> void:
	var list: Array = chat_history.get(character, [])
	list.append({"q": question, "a": answer})
	if list.size() > CHAT_MEMORY_LIMIT:
		list = list.slice(list.size() - CHAT_MEMORY_LIMIT)
	chat_history[character] = list
	save_game()


## 主角在畫面上顯示的名字（第一人稱視角：名字牌顯示玩家輸入的名字）
func display_name(speaker: String) -> String:
	return (user_name if user_name != "" else "你") if speaker == "你" else speaker


func mark_reached(id: String) -> void:
	if not reached_sections.has(id):
		reached_sections.append(id)


func mark_completed(id: String) -> void:
	if not completed_sections.has(id):
		completed_sections.append(id)


func is_section_unlocked(id: String) -> bool:
	return reached_sections.has(id)


func is_section_completed(id: String) -> bool:
	return completed_sections.has(id)


func has_save() -> bool:
	if not FileAccess.file_exists(save_path):
		return false
	var data = _read_save()
	return data is Dictionary and str(data.get("user_name", "")) != ""


func save_game() -> void:
	var data := {
		"version": SAVE_VERSION,
		"user_name": user_name,
		"section_id": section_id,
		"age": age,
		"flags": flags,
		"vars": _saveable_vars(),
		"levels": levels,
		"achievements": achievements,
		"reached_sections": reached_sections,
		"completed_sections": completed_sections,
		"backlog": backlog,
		"chat_history": chat_history,
		"settings": settings,
	}
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()


func load_game() -> bool:
	var data = _read_save()
	if not (data is Dictionary):
		return false
	user_name = str(data.get("user_name", ""))
	section_id = str(data.get("section_id", ChapterRegistry.first_section_id()))
	age = int(data.get("age", 0))
	flags = data.get("flags", {})
	vars = data.get("vars", {})
	levels = data.get("levels", {})
	achievements = data.get("achievements", [])
	reached_sections = data.get("reached_sections", [section_id])
	completed_sections = data.get("completed_sections", [])
	# 舊存檔裡已經不存在的小節（例如併進第一章的序章）換成現在的 id
	section_id = ChapterRegistry.RENAMED.get(section_id, section_id)
	reached_sections = _renamed(reached_sections)
	completed_sections = _renamed(completed_sections)
	backlog = data.get("backlog", [])
	chat_history = data.get("chat_history", {})
	_merge_settings(data.get("settings", {}))
	return true


func _renamed(ids: Array) -> Array:
	var out: Array = []
	for id in ids:
		var new_id: String = ChapterRegistry.RENAMED.get(id, id)
		if not out.has(new_id):
			out.append(new_id)
	return out


func delete_save() -> void:
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))


func _read_save() -> Variant:
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		return null
	var text := file.get_as_text()
	file.close()
	return JSON.parse_string(text)


func _load_settings_only() -> void:
	var data = _read_save()
	if data is Dictionary:
		_merge_settings(data.get("settings", {}))


func _merge_settings(saved: Dictionary) -> void:
	for k in saved:
		if OLD_DEFAULT_SPEED.has(k) and is_equal_approx(float(saved[k]), OLD_DEFAULT_SPEED[k]):
			continue
		settings[k] = saved[k]


## vars 裡可能放了不能存成 JSON 的東西，只存基本型別。
func _saveable_vars() -> Dictionary:
	var out := {}
	for k in vars.keys():
		var v = vars[k]
		if v is String or v is int or v is float or v is bool or v is Array or v is Dictionary:
			out[k] = v
	return out


# ------------------------------------------------------------------
# 變數 / 旗標
# ------------------------------------------------------------------

func get_value(key: String, default: Variant = null) -> Variant:
	if key == "userName" or key == "user_name":
		return user_name
	if key == "completion":
		return completion()
	if flags.has(key):
		return flags[key]
	return vars.get(key, default)


## 布林值或 gave_gift 這類「會影響劇情」的值放 flags，其他放 vars。
func set_value(key: String, value: Variant) -> void:
	if value is bool or flags.has(key):
		flags[key] = value
	else:
		vars[key] = value
	value_changed.emit(key, value)


## 把 {userName}、{breakfast} 這類佔位字換成實際的值。
func format_text(text: String) -> String:
	if text.find("{") == -1:
		return text
	var out := text.replace("{userName}", user_name if user_name != "" else "你")
	for source in [flags, vars]:
		for k in source.keys():
			var token := "{%s}" % k
			if out.find(token) != -1:
				var v = source[k]
				out = out.replace(token, _display(v))
	return out


func _display(v: Variant) -> String:
	if v is float and is_equal_approx(v, roundf(v)):
		return str(int(roundf(v)))
	if v is bool:
		return "True" if v else "False"
	if v is Array:
		var parts: Array = []
		for x in v:
			parts.append("\"%s\"" % x if x is String else str(x))
		return "[" + ", ".join(parts) + "]"
	return str(v)


## 劇本裡的 @if / @set 用 Godot 的 Expression 計算，例如：
##   @if gave_gift
##   @if completion >= 0.8
##   @set gave_gift = "手作巧克力" in bag
func evaluate(expr_text: String) -> Variant:
	var names: Array = ["completion", "userName"]
	var values: Array = [completion(), user_name]
	for source in [vars, flags]:
		for k in source.keys():
			if k is String and k.is_valid_identifier() and not names.has(k):
				names.append(k)
				values.append(source[k])
	var expr := Expression.new()
	var err := expr.parse(_to_godot_expr(expr_text), PackedStringArray(names))
	if err != OK:
		push_warning("[GameState] 無法解析條件「%s」：%s" % [expr_text, expr.get_error_text()])
		return null
	var result = expr.execute(values, null, false)
	if expr.has_execute_failed():
		# 變數還不存在時（例如沒經過 3.1 直接跳章），當成 false
		return null
	return result


func check(expr_text: String) -> bool:
	var v = evaluate(expr_text)
	return v == true or (v is int and v != 0) or (v is float and v != 0.0) or (v is String and v != "")


## 讓劇本可以寫 Python 風格的 True / False / and / or / not。
func _to_godot_expr(text: String) -> String:
	var t := " " + text + " "
	t = t.replace(" True ", " true ").replace(" False ", " false ").replace(" None ", " null ")
	t = t.replace("(True)", "(true)").replace("(False)", "(false)")
	return t.strip_edges()


# ------------------------------------------------------------------
# 關卡成績與結局判定
# ------------------------------------------------------------------

## counts = false 的關卡（例如結局的回憶遊戲）不列入結局判定。
func record_level(level_id: String, first_try: bool, errors: int, hint_used: bool, counts: bool = true) -> void:
	var prev: Dictionary = levels.get(level_id, {})
	# 重玩同一關時，保留第一次的「第一次就通過」紀錄
	levels[level_id] = {
		"passed": true,
		"first_try": prev.get("first_try", first_try) if prev.get("passed", false) else first_try,
		"errors": errors,
		"hint_used": hint_used,
		"counts": counts,
	}


func first_try_passed() -> int:
	var n := 0
	for id in levels:
		var r: Dictionary = levels[id]
		if r.get("counts", true) and r.get("first_try", false):
			n += 1
	return n


func total_levels() -> int:
	var n := 0
	for id in levels:
		if levels[id].get("counts", true):
			n += 1
	return n


func completion() -> float:
	var total := total_levels()
	return float(first_try_passed()) / float(total) if total > 0 else 0.0


func total_errors() -> int:
	var n := 0
	for id in levels:
		n += int(levels[id].get("errors", 0))
	return n


# ------------------------------------------------------------------
# 成就
# ------------------------------------------------------------------

func unlock_achievement(achievement_id: String) -> void:
	if achievements.has(achievement_id):
		return
	achievements.append(achievement_id)
	achievement_unlocked.emit(achievement_id)
	save_game()


func has_achievement(achievement_id: String) -> bool:
	return achievements.has(achievement_id)
