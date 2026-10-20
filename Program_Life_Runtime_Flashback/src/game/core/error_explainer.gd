class_name ErrorExplainer
extends RefCounted

## 畫面設定書 2.2：「出錯時，派森會用白話解釋錯誤訊息，不直接丟英文錯誤給玩家。」
## 這裡先用規則產生一句白話解釋（離線也能用、不會卡住），
## AI 開啟時再交給 AiBridge 用派森的口吻潤飾，AI 失敗就用這句當備用台詞。

const FULLWIDTH := ["（", "）", "“", "”", "「", "」", "，", "：", "＝", "＋", "；"]


static func explain(error: Dictionary, code: String) -> String:
	var etype: String = str(error.get("type", ""))
	var msg: String = str(error.get("message", ""))
	var line: int = int(error.get("line", 0))
	var where := "第 %d 行" % line if line > 0 else "程式裡"
	var line_text := _line_of(code, line)

	# 最常見的新手錯誤：全形符號
	for ch in FULLWIDTH:
		if line_text.find(ch) != -1 or (line == 0 and code.find(ch) != -1):
			if etype == "SyntaxError" or etype == "NameError" or etype == "SimpleModeError":
				return "%s有全形的「%s」。Python 只看得懂英文半形的符號，括號是 ( )、引號是 \" \"。" % [where, ch]

	match etype:
		"SyntaxError":
			if msg.find("never closed") != -1 or msg.find("was not closed") != -1 or msg.find("EOF") != -1:
				return "%s好像有括號或引號沒有成對。每一個「(」都要有一個「)」，引號也要前後各一個。" % where
			if msg.find("unterminated string") != -1 or msg.find("EOL") != -1:
				return "%s的文字少了結尾的引號，Python 不知道這句話在哪裡結束。" % where
			if msg.find("expected ':'") != -1:
				return "%s的 if、for、while、def 這類句子，最後面要加上冒號「:」。" % where
			if msg.find("invalid syntax") != -1 and line_text.find("=") != -1 and line_text.find("==") == -1 and (line_text.begins_with("if") or line_text.begins_with("while") or line_text.begins_with("elif")):
				return "%s在比較兩個東西時要用「==」，一個「=」是把東西放進盒子。" % where
			return "%s的寫法 Python 看不懂，檢查一下括號、引號、冒號有沒有少或多。" % where
		"IndentationError", "TabError":
			if msg.find("expected an indented block") != -1:
				return "%s的上一行是 if、for 或 def，底下的程式要往內縮排四個空白。" % where
			if msg.find("unexpected indent") != -1:
				return "%s不需要縮排，把前面的空白拿掉試試看。" % where
			return "%s的縮排對不齊，同一層的程式要從同一個位置開始。" % where
		"NameError":
			var name := _quoted(msg)
			if name != "" and not name.is_valid_identifier():
				return "派森不認識「%s」。如果這是要說的話，記得用引號包起來，像 \"%s\"。" % [name, name]
			return "派森不認識「%s」這個名字。是不是拼錯了，或還沒先建立這個盒子（變數）？" % name
		"TypeError":
			if msg.find("can only concatenate str") != -1 or msg.find("unsupported operand type") != -1 and msg.find("str") != -1:
				return "%s把文字和數字直接用 + 接在一起了。可以改用 f-string，或用 str() 先把數字變成文字。" % where
			if msg.find("not callable") != -1:
				return "%s把不是函式的東西當成函式呼叫了，檢查一下括號前面的名字。" % where
			if msg.find("argument") != -1:
				return "%s呼叫函式時，放進去的材料（參數）數量不對。" % where
			return "%s的資料種類不對，例如把文字拿去做數學運算。" % where
		"ValueError":
			if msg.find("invalid literal for int()") != -1:
				return "%s的 int() 看不懂這段文字，它只認得阿拉伯數字，像 \"120\"。" % where
			if msg.find("not in list") != -1:
				return "%s想從 list 拿出一個本來就不在裡面的東西。" % where
			return "%s的值不太對：%s" % [where, msg]
		"IndexError":
			return "%s的索引超出範圍了。list 的編號是從 0 開始算的，最後一個是 len() - 1。" % where
		"KeyError":
			return "字典裡沒有「%s」這個鍵，檢查一下名字有沒有打錯。" % msg.trim_prefix("'").trim_suffix("'")
		"AttributeError":
			var attr := _quoted(msg.get_slice("attribute", 1)) if msg.find("attribute") != -1 else ""
			return "%s用了一個不存在的方法%s，檢查一下拼字。" % [where, "「%s」" % attr if attr != "" else ""]
		"ZeroDivisionError":
			return "%s除以 0 了。什麼數字都不能除以 0 喔。" % where
		"TimeoutError":
			return "程式一直跑停不下來，可能是迴圈的條件永遠成立。檢查 while 的條件會不會改變。"
		"ImportError", "ModuleNotFoundError":
			return "這裡只能 import random 或 math 兩個工具箱。"
		"EOFError":
			return "程式在等你輸入，但已經沒有準備好的輸入了。"
		"RuntimeError":
			return msg
		"SimpleModeError":
			return "%s。（目前是簡易模式，只能寫單行 print；安裝 Python 3 後可以使用完整功能。）" % msg
		"InternalError":
			return "Python 執行環境出了點問題，不是你的錯。再按一次執行試試看。"
	return "%s出了一點問題（%s）。" % [where, etype]


## 給 AI 的提示詞：請派森用自己的口吻改寫規則版的解釋。
static func ai_prompt(error: Dictionary, code: String, plain: String) -> String:
	return """你是遊戲《派森與我的一生》裡的派森：一顆只有主角看得見、會發光的藍黃光球，是 Python 的化身。
主角的程式出錯了，請用溫柔、白話、像朋友的口吻提示他錯在哪裡。
規則：繁體中文、60 字以內、不要用表情符號、不要直接寫出英文錯誤名稱、不要直接給出完整答案。

玩家的程式：
%s

錯誤：%s: %s（第 %d 行）
參考解釋：%s""" % [code, error.get("type", ""), error.get("message", ""), int(error.get("line", 0)), plain]


static func _line_of(code: String, line: int) -> String:
	var lines := code.split("\n")
	if line >= 1 and line <= lines.size():
		return lines[line - 1]
	return ""


static func _quoted(msg: String) -> String:
	var a := msg.find("'")
	var b := msg.find("'", a + 1)
	if a != -1 and b > a:
		return msg.substr(a + 1, b - a - 1)
	return ""
