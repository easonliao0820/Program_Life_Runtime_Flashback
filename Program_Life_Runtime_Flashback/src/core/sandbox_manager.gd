extends Node

#func run_code(code: String) -> String:
	## 這裡先做最簡單 demo
	#if code.begins_with("print"):
		#return _handle_print(code)
	#return "Error: only print is allowed"

#func _handle_print(code: String) -> String:
	## 找 print(...) 的內容
	#var start = code.find("(") + 1
	#var end = code.rfind(")")
	#
	#if start == -1 or end == -1:
		#return "Syntax Error"
	#
	#var content = code.substr(start, end - start)
	#content = content.strip_edges()       # 去掉前後空白
	#content = content.strip_edges("\"")   # 去掉前後雙引號
	#
	#
	#return content
