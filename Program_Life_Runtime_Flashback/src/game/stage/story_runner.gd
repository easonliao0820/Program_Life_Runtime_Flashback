class_name StoryRunner
extends RefCounted

## 依序執行 StoryParser 產生的事件。所有「畫面」相關的事都交給 stage（GameStage）處理，
## 這裡只負責流程：對話、條件分支、關卡、AI、跳章……
## 新增劇本指令：在 _run_cmd 的 match 加一個分支即可（未知指令會略過並印出警告）。

var stage: Node
var section_id: String = ""
var level_index: int = 0
var level_total: int = 0
var jumped_to: String = ""   ## @jump / @ending 設定後，這一節就停止播放
var _aborted: bool = false


func _init(owner_stage: Node, id: String) -> void:
	stage = owner_stage
	section_id = id


func abort() -> void:
	_aborted = true


static func count_levels(events: Array) -> int:
	var n := 0
	for ev in events:
		match ev["type"]:
			"level":
				n += 1
			"if":
				# 分支只會走其中一條，取最多關的那條
				var best := count_levels(ev["else"])
				for b in ev["branches"]:
					best = maxi(best, count_levels(b["events"]))
				n += best
	return n


func run(events: Array) -> void:
	level_total = count_levels(events)
	# 小節最後的（轉場）不用播：接下來本來就會換小節／換章，避免連續淡出兩次
	var list := events.duplicate()
	while not list.is_empty() and list.back()["type"] == "cmd" and list.back()["cmd"] == "transition":
		list.pop_back()
	await _run_list(list)


func _stopped() -> bool:
	return _aborted or jumped_to != "" or not is_instance_valid(stage)


func _run_list(events: Array) -> void:
	for i in events.size():
		if _stopped():
			return
		var ev: Dictionary = events[i]
		# 關卡／探索結束後還在四象限：如果接下來幾句話之後馬上又是關卡，就留在四象限
		# （對話顯示在左上劇情區）；否則才放大回全螢幕，避免來回切換
		if stage.is_split() and not _is_split_event(ev) and not (_is_light_event(ev) and _split_soon(events, i)):
			await stage.exit_split()
		await _run_event(ev)


## 會用到四象限的事件
func _is_split_event(ev: Dictionary) -> bool:
	return ev["type"] in ["level", "explore"]


## 可以直接在劇情區對話框播的事件（不需要全螢幕）
func _is_light_event(ev: Dictionary) -> bool:
	if ev["type"] in ["say", "narrate", "think", "system", "ai"]:
		return true
	return ev["type"] == "cmd" and ev["cmd"] in ["achievement", "set", "wait", "sfx", "orb"]


## 從第 i 個事件開始，最多往後看 4 個「輕事件」，看會不會接著遇到關卡／探索
func _split_soon(events: Array, i: int) -> bool:
	var light := 0
	for j in range(i, events.size()):
		var ev: Dictionary = events[j]
		if _is_split_event(ev):
			return true
		if not _is_light_event(ev):
			return false
		light += 1
		if light > 4:
			return false
	return false


func _run_event(ev: Dictionary) -> void:
	match ev["type"]:
		"say":
			await stage.say(ev["speaker"], GameState.format_text(ev["text"]))
		"narrate":
			await stage.narrate(GameState.format_text(ev["text"]))
		"think":
			await stage.think(GameState.format_text(ev["text"]))
		"system":
			await stage.system_line(GameState.format_text(ev["text"]))
		"code":
			# 程式碼只換 {userName}，不能用 format_text（f-string 的 {變數} 會被誤換）
			stage.show_code(str(ev["code"]).replace("{userName}", GameState.user_name), ev.get("runnable", true))
		"ai":
			var line: String = await stage.ai_line(ev["speaker"], GameState.format_text(ev["prompt"]), GameState.format_text(ev.get("fallback", "")))
			await stage.say(ev["speaker"], line)
		"if":
			for b in ev["branches"]:
				if GameState.check(b["cond"]):
					await _run_list(b["events"])
					return
			await _run_list(ev["else"])
		"level":
			level_index += 1
			await stage.play_level(ev["level"], level_index, maxi(level_total, level_index))
		"explore":
			await stage.play_explore(ev["explore"])
		"choice":
			var c: Dictionary = ev["choice"]
			var value: String = await stage.choose(GameState.format_text(c["prompt"]), c["options"])
			GameState.set_value(c["var"], value)
		"classify":
			await stage.classify(ev["classify"])
		"memory":
			await stage.play_memory(ev["memory"])
		"cmd":
			await _run_cmd(ev["cmd"], ev["arg"], ev.get("line", 0))


func _run_cmd(cmd: String, arg: String, line: int) -> void:
	var args := arg.split(" ", false)
	match cmd:
		"bg":
			await stage.set_background(args[0] if args.size() > 0 else "black", args[1] if args.size() > 1 else "")
		"tone":
			stage.set_tone(arg)
		"cg":
			var parts := arg.split(" ", false, 1)
			await stage.show_cg(parts[0], parts[1] if parts.size() > 1 else "")
		"show":
			stage.show_character(args[0], args[1] if args.size() > 1 else "", args[2] if args.size() > 2 else "")
		"hide":
			stage.hide_character(args[0] if args.size() > 0 else "all")
		"age":
			GameState.age = int(arg)
		"achievement":
			GameState.unlock_achievement(arg)
		"set":
			var eq := arg.find("=")
			if eq == -1:
				push_warning("[劇本] 第 %d 行 @set 要寫成 @set 名稱 = 值" % line)
				return
			var key := arg.substr(0, eq).strip_edges()
			GameState.set_value(key, GameState.evaluate(arg.substr(eq + 1).strip_edges()))
		"input":
			var parts := arg.split(" ", false, 1)
			var text: String = await stage.ask_input(GameState.format_text(parts[1] if parts.size() > 1 else ""))
			GameState.set_value(parts[0], text)
		"phone":
			if arg == "off" or arg == "":
				stage.close_phone()
			else:
				stage.open_phone(arg)
		"transition":
			await stage.transition(arg)
		"wait":
			await stage.get_tree().create_timer(float(arg) if arg != "" else 1.0).timeout
		"flash":
			await stage.flash(arg if arg != "" else "white")
		"shake":
			await stage.shake(float(arg) if arg != "" else 0.6)
		"code_line":
			stage.code_line(int(arg))
		"photo":
			await stage.photo(arg)
		"eyes_close":
			stage.eyes_close()
		"eyes_open":
			await stage.eyes_open()
		"focus":
			await stage.focus()
		"saturation":
			stage.set_saturation(float(arg) if arg != "" else 1.0)
		"frame":
			stage.show_frame(arg != "off")
		"orb":
			stage.orb_command(args)
		"montage":
			await stage.montage(arg)
		"jump":
			jumped_to = arg
		"ending":
			jumped_to = GameFlow.decide_ending()
		"credits":
			await stage.credits()
		"hide_box":
			stage.hide_dialogue()
		"sfx", "bgm":
			stage.play_audio(cmd, arg)
		_:
			push_warning("[劇本] 第 %d 行：不認得的指令 @%s（已略過）" % [line, cmd])
