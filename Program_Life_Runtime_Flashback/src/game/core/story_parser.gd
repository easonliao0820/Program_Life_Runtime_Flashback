class_name StoryParser
extends RefCounted

## 把 .story 劇本檔解析成事件清單，交給 StoryRunner 播放。
## 語法刻意貼近《專題劇情》的寫法，劇本可以直接從 docx 貼過來再補上 @ 指令。
## 完整語法說明見 docs/STORY_FORMAT.md。
##
##   派森：你長高了呢。                → 對話（名字牌用角色代表色）
##   （跟在高大背影後面的你……）        → 旁白（斜體灰字、不顯示名字牌）
##   心聲：為什麼哭不出來？！          → 心聲（虛線邊框）
##   系統：變數就像一個盒子……          → 系統說明
##   成就：第一次算數                  → 解鎖成就
##   派森：（AI 回應：……）             → AI 即時生成；下一行的【備用台詞】是失敗時的備案
##   【備用台詞】派森：……
##   ```python ... ```                 → 程式碼卡片（可以按「執行看看」）
##   【設計】／【選項】／# ……           → 註解，遊戲不顯示
##   @bg / @age / @if / @level ... @end → 指令（見文件）

const BLOCK_COMMANDS := ["level", "explore", "choice", "classify", "memory"]
const SPEAKER_MAX_LEN := 10

var _errors: Array = []


static func parse_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("[StoryParser] 找不到劇本檔：%s（匯出時記得在 Export → Resources 加上 *.story）" % path)
		return {"events": [], "errors": ["找不到劇本檔：" + path]}
	var text := FileAccess.get_file_as_string(path)
	var parser := StoryParser.new()
	return parser.parse(text, path)


func parse(text: String, source_name: String = "") -> Dictionary:
	_errors.clear()
	var root: Array = []
	# 事件清單的堆疊（@if 會往下推一層）
	var list_stack: Array = [root]
	# @if 節點的堆疊，處理 @elif / @else / @endif
	var if_stack: Array = []
	# 區塊（@level / @explore / ...）的堆疊
	var block_stack: Array = []

	var lines := text.replace("\r\n", "\n").split("\n")
	var i := 0
	var pending_key := ""   # 區塊裡「starter:」這類等待下一段程式碼的 key

	while i < lines.size():
		var raw: String = lines[i]
		var line := raw.strip_edges()
		var line_no := i + 1
		i += 1

		# ---------- 程式碼區塊 ----------
		if line.begins_with("```"):
			var lang := line.substr(3).strip_edges()
			var code_lines: Array = []
			while i < lines.size() and not lines[i].strip_edges().begins_with("```"):
				code_lines.append(lines[i])
				i += 1
			i += 1  # 跳過結尾的 ```
			var code := _dedent("\n".join(code_lines))
			if not block_stack.is_empty() and pending_key != "":
				block_stack.back()["data"][pending_key] = code
				pending_key = ""
			elif not block_stack.is_empty():
				_error(source_name, line_no, "區塊裡的程式碼前面要先寫 key，例如 starter:")
			else:
				list_stack.back().append({"type": "code", "code": code, "runnable": lang != "text", "line": line_no})
			continue

		if line == "" or line.begins_with("#") or line.begins_with("//"):
			continue

		# ---------- 指令 ----------
		if line.begins_with("@"):
			var cmd_text := line.substr(1)
			var sp := cmd_text.find(" ")
			var cmd := (cmd_text if sp == -1 else cmd_text.substr(0, sp)).to_lower()
			var arg := "" if sp == -1 else cmd_text.substr(sp + 1).strip_edges()

			if cmd == "end":
				if block_stack.is_empty():
					_error(source_name, line_no, "多出來的 @end")
					continue
				var block: Dictionary = block_stack.pop_back()
				pending_key = ""
				var ev := _finish_block(block)
				if not block_stack.is_empty() and block_stack.back()["kind"] == "memory" and block["kind"] == "level":
					block_stack.back()["data"]["fragments"].append(ev["level"])
				else:
					list_stack.back().append(ev)
				continue

			if cmd in BLOCK_COMMANDS:
				block_stack.append(_start_block(cmd, arg, line_no))
				pending_key = ""
				continue

			if not block_stack.is_empty():
				_error(source_name, line_no, "@%s 不能寫在 @%s 區塊裡（先用 @end 結束區塊）" % [cmd, block_stack.back()["kind"]])
				continue

			match cmd:
				"if":
					var node := {"type": "if", "branches": [{"cond": arg, "events": []}], "else": [], "line": line_no}
					list_stack.back().append(node)
					if_stack.append(node)
					list_stack.append(node["branches"][0]["events"])
				"elif":
					if if_stack.is_empty():
						_error(source_name, line_no, "@elif 前面沒有 @if")
						continue
					list_stack.pop_back()
					var branch := {"cond": arg, "events": []}
					if_stack.back()["branches"].append(branch)
					list_stack.append(branch["events"])
				"else":
					if if_stack.is_empty():
						_error(source_name, line_no, "@else 前面沒有 @if")
						continue
					list_stack.pop_back()
					list_stack.append(if_stack.back()["else"])
				"endif":
					if if_stack.is_empty():
						_error(source_name, line_no, "@endif 前面沒有 @if")
						continue
					list_stack.pop_back()
					if_stack.pop_back()
				_:
					list_stack.back().append({"type": "cmd", "cmd": cmd, "arg": arg, "line": line_no})
			continue

		# ---------- 區塊內容（key: value 或 - 項目） ----------
		if not block_stack.is_empty():
			pending_key = _block_line(block_stack.back(), line, source_name, line_no)
			continue

		# ---------- 一般劇情 ----------
		_story_line(list_stack.back(), line, line_no)

	if not block_stack.is_empty():
		_error(source_name, lines.size(), "@%s 區塊沒有用 @end 結束" % block_stack.back()["kind"])
	if not if_stack.is_empty():
		_error(source_name, lines.size(), "@if 沒有用 @endif 結束")

	for e in _errors:
		push_warning(e)
	return {"events": root, "errors": _errors.duplicate()}


# ------------------------------------------------------------------
# 一般劇情行
# ------------------------------------------------------------------

func _story_line(events: Array, line: String, line_no: int) -> void:
	# 【備用台詞】派森：…… → 補到上一個 AI 事件
	if line.begins_with("【備用台詞】"):
		var rest := line.substr("【備用台詞】".length())
		var parts := _split_speaker(rest)
		var fallback: String = parts[1] if parts[0] != "" else rest
		for j in range(events.size() - 1, -1, -1):
			if events[j]["type"] == "ai":
				events[j]["fallback"] = _strip_quotes(fallback)
				return
		events.append({"type": "say", "speaker": parts[0], "text": fallback, "line": line_no})
		return

	# 其他【……】是寫給企劃／美術看的備註
	if line.begins_with("【"):
		return

	if line.begins_with("成就：") or line.begins_with("成就:"):
		events.append({"type": "cmd", "cmd": "achievement", "arg": line.substr(3).strip_edges(), "line": line_no})
		return

	if line.begins_with("（") and line.ends_with("）"):
		var inner := line.substr(1, line.length() - 2).strip_edges()
		if inner.begins_with("轉場"):
			events.append({"type": "cmd", "cmd": "transition", "arg": inner.substr(2).lstrip(" →").strip_edges(), "line": line_no})
		else:
			events.append({"type": "narrate", "text": inner, "line": line_no})
		return

	var parts := _split_speaker(line)
	var speaker: String = parts[0]
	var text: String = parts[1]
	if speaker == "":
		events.append({"type": "narrate", "text": line, "line": line_no})
		return

	# 派森：（AI 回應：……）
	var ai_text := _strip_quotes(text)
	if ai_text.begins_with("（AI 回應：") or ai_text.begins_with("（AI回應："):
		var start := ai_text.find("：") + 1
		var prompt := ai_text.substr(start, ai_text.length() - start - (1 if ai_text.ends_with("）") else 0))
		events.append({"type": "ai", "speaker": speaker, "prompt": prompt.strip_edges(), "fallback": "", "line": line_no})
		return

	match speaker:
		"心聲":
			events.append({"type": "think", "text": text, "line": line_no})
		"旁白":
			events.append({"type": "narrate", "text": text, "line": line_no})
		"系統":
			events.append({"type": "system", "text": text, "line": line_no})
		_:
			events.append({"type": "say", "speaker": speaker, "text": text, "line": line_no})


## 「名字：台詞」→ [名字, 台詞]；不像對話就回傳 ["", 原句]。
func _split_speaker(line: String) -> Array:
	var idx := line.find("：")
	if idx == -1:
		idx = line.find(":")
		# 英文冒號只在名字是英文（Cindy: ……）時才算
		if idx != -1 and line.substr(0, idx).find(" ") != -1:
			idx = -1
	if idx <= 0 or idx > SPEAKER_MAX_LEN:
		return ["", line]
	var name := line.substr(0, idx).strip_edges()
	if name.begins_with("（") or name.find("「") != -1 or name.find("，") != -1:
		return ["", line]
	return [name, line.substr(idx + 1).strip_edges()]


func _strip_quotes(text: String) -> String:
	var t := text.strip_edges()
	if t.begins_with("「") and t.ends_with("」"):
		return t.substr(1, t.length() - 2)
	return t


# ------------------------------------------------------------------
# 區塊：@level / @explore / @choice / @classify / @memory
# ------------------------------------------------------------------

func _start_block(kind: String, arg: String, line_no: int) -> Dictionary:
	var data := {}
	match kind:
		"level":
			data = {"id": arg, "title": arg, "goal": "", "tags": [], "hints": [], "starter": "", "check": "",
				"solution": "", "stdin": [], "theme": "default", "counts": true, "success": ""}
		"explore":
			data = {"id": arg, "title": "", "goal": "", "list": "bag", "start": [], "items": [], "capacity": 0,
				"timer": 0, "hidden_count": 0, "confirm": "確認"}
		"choice":
			var parts := arg.split(" ", false, 1)
			data = {"var": parts[0] if parts.size() > 0 else "choice", "prompt": parts[1] if parts.size() > 1 else "", "options": []}
		"classify":
			var parts := arg.split(" ", false)
			data = {"var": parts[0] if parts.size() > 0 else "style", "source": parts[1] if parts.size() > 1 else "",
				"options": [], "default": "", "prompt": ""}
		"memory":
			data = {"title": arg, "fragments": [], "order": "", "cg": []}
	return {"kind": kind, "data": data, "line": line_no}


## 回傳等待程式碼的 key（例如「starter:」後面接 ```）。
func _block_line(block: Dictionary, line: String, source_name: String, line_no: int) -> String:
	var kind: String = block["kind"]
	var data: Dictionary = block["data"]

	if line.begins_with("- "):
		var item := line.substr(2).strip_edges()
		match kind:
			"choice":
				# - 培根蛋吐司 35 元 = 培根蛋吐司
				var eq := item.rfind(" = ")
				data["options"].append({"label": item.substr(0, eq) if eq != -1 else item,
					"value": item.substr(eq + 3).strip_edges() if eq != -1 else item})
			"classify":
				# - A: 感性與告白風 | 一起住, 喜歡, 你
				var colon := item.find(":")
				if colon == -1:
					colon = item.find("：")
				var key := item.substr(0, colon).strip_edges() if colon != -1 else item
				var rest := item.substr(colon + 1).strip_edges() if colon != -1 else ""
				var bar := rest.find("|")
				var desc := rest.substr(0, bar).strip_edges() if bar != -1 else rest
				var kws: Array = []
				if bar != -1:
					for kw in rest.substr(bar + 1).split(",", false):
						kws.append(kw.strip_edges())
				data["options"].append({"key": key, "desc": desc, "keywords": kws})
			"explore":
				# - 悠遊卡                            （預設產生 bag.append("悠遊卡")）
				# - 媽媽的年齡 => mom_age = 30 | 媽媽今年 30 歲
				var arrow := item.find("=>")
				var entry := {"name": item, "code": "", "note": ""}
				if arrow != -1:
					entry["name"] = item.substr(0, arrow).strip_edges()
					var rest := item.substr(arrow + 2).strip_edges()
					var bar := rest.find(" | ")
					entry["code"] = rest.substr(0, bar).strip_edges() if bar != -1 else rest
					entry["note"] = rest.substr(bar + 3).strip_edges() if bar != -1 else ""
				data["items"].append(entry)
			_:
				_error(source_name, line_no, "@%s 區塊不支援「- 項目」寫法" % kind)
		return ""

	var colon := line.find(":")
	if colon <= 0:
		_error(source_name, line_no, "@%s 區塊裡看不懂這行：%s" % [kind, line])
		return ""
	var key := line.substr(0, colon).strip_edges()
	var value := line.substr(colon + 1).strip_edges()

	if value == "":
		return key  # 下一段 ``` 程式碼放進這個 key

	match key:
		"tags", "stdin":
			var arr: Array = []
			for part in value.split("|", false):
				arr.append(part.strip_edges())
			data[key] = arr
		"start":
			var arr: Array = []
			for part in value.replace("、", ",").split(",", false):
				arr.append(part.strip_edges())
			data[key] = arr
		"hint":
			data["hints"].append(value)
		"capacity", "timer", "hidden_count":
			data[key] = int(value)
		"counts":
			data[key] = value.to_lower() in ["true", "yes", "1", "是"]
		"cg":
			if kind == "memory":
				data["cg"].append(value)
			else:
				data[key] = value
		_:
			data[key] = value
	return ""


func _finish_block(block: Dictionary) -> Dictionary:
	var kind: String = block["kind"]
	var data: Dictionary = block["data"]
	match kind:
		"level":
			return {"type": "level", "level": data, "line": block["line"]}
		"explore":
			return {"type": "explore", "explore": data, "line": block["line"]}
		"choice":
			return {"type": "choice", "choice": data, "line": block["line"]}
		"classify":
			return {"type": "classify", "classify": data, "line": block["line"]}
		"memory":
			return {"type": "memory", "memory": data, "line": block["line"]}
	return {"type": "noop"}


# ------------------------------------------------------------------

## 拿掉程式碼共同的前置縮排，讓劇本裡的程式碼可以縮排排版。
func _dedent(code: String) -> String:
	var lines := code.split("\n")
	var min_indent := 1 << 30
	for l in lines:
		if l.strip_edges() == "":
			continue
		var n := 0
		while n < l.length() and (l[n] == " " or l[n] == "\t"):
			n += 1
		min_indent = mini(min_indent, n)
	if min_indent == 1 << 30 or min_indent == 0:
		return code.strip_edges(false, true)
	var out: Array = []
	for l in lines:
		out.append(l.substr(min_indent) if l.length() >= min_indent else l.strip_edges())
	return "\n".join(out).strip_edges(false, true)


func _error(source_name: String, line_no: int, msg: String) -> void:
	_errors.append("[劇本] %s:%d %s" % [source_name.get_file(), line_no, msg])
