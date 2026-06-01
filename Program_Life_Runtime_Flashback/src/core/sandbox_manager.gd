extends Node

## 沙盒管理器：負責處理與解析玩家輸入的程式碼

# 執行程式碼並回傳結果 (目前實作第一關的 print 邏輯)
func run_code(code: String) -> String:
	var result_output = ""
	
	# 1. 基本清理
	code = code.strip_edges()
	
	# 2. 規則限制 (基礎安全性與語法檢查)
	if "import" in code or "=" in code or "\n" in code:
		return "❌ 語法限制：目前只能使用單行 print 指令"
	
	# 3. 指令檢查
	if not code.begins_with("print("):
		return "❌ 只能使用 print() 函式"
	
	# 4. 字串符號檢查
	if code.find("\"") == -1 and code.find("'") == -1:
		return "❌ print() 內必須輸入字串內容"
	
	if not code.ends_with(")"):
		return "❌ 語法錯誤：缺少右括號"
		
	# 5. 擷取 print 內容
	return _handle_print(code)
	

# 內部處理 print 內容解析
func _handle_print(code: String) -> String:
	var start = code.find("(") + 1
	var end = code.rfind(")")
	print(start)
	print(end )
	if start > 0 and end > start:
		var content = code.substr(start, end - start).strip_edges()
		# 移除最外層的引號 (支援單雙引號)
		if (content.begins_with("\"") and content.ends_with("\"")) or \
		   (content.begins_with("'") and content.ends_with("'")):
			content = content.substr(1, content.length() - 2)
		else:
			return "❌ 字串未正確閉合"
			
		if content == "":
			return "❌ 請在 print() 中輸入內容"
		
		return content
		
		
	return "❌ 語法解析失敗"
