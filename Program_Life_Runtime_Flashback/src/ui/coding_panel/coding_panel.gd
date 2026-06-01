extends CanvasLayer

@onready var sandbox_container: Control = $SandboxContainer
@onready var code_edit: CodeEdit = $SandboxContainer/CodeEdit
@onready var output_label: Label = $SandboxContainer/OutputLabel
@onready var run_button: Button = $SandboxContainer/RunButton

const TEMP_PY_PATH = "user://sandbox_player_code.py"

# 全域暫存：記錄當前是哪一個關卡物件開啟了沙盒，以及它的過關關鍵字
var current_target_object: Node = null
var current_success_keyword: String = ""

func _ready() -> void:
	# 遊戲啟動時，預設完全隱藏右手邊的程式沙盒區
	sandbox_container.hide()
	output_label.text = "等待執行程式碼..."
	
	# 綁定執行按鈕
	if not run_button.pressed.is_connected(_on_run_button_pressed):
		run_button.pressed.connect(_on_run_button_pressed)

## ==================== 🌐 全域呼叫接口 ====================
## 外部章節物件呼叫此函式即可在右手邊彈出沙盒
## 使用範例：CodingPanel.open_sandbox(self, "door.open()", "print('hello')")
func open_sandbox(target_node: Node, success_keyword: String, default_code: String = "") -> void:
	current_target_object = target_node
	current_success_keyword = success_keyword
	
	# 注入這一關預設給玩家的基礎程式碼草稿/模板
	code_edit.text = default_code
	output_label.text = "請輸入 Python 程式碼並點擊執行..."
	
	# 顯示右手邊沙盒介面
	sandbox_container.show()
	print("【沙盒系統】已由外部物件成功喚醒，目標關鍵字為：", success_keyword)

## 關閉沙盒介面
func close_sandbox() -> void:
	sandbox_container.hide()
	current_target_object = null
	current_success_keyword = ""

## ==================== ⚙️ 核心編譯運作邏輯 ====================

func _on_run_button_pressed() -> void:
	var player_input_code = code_edit.text
	if player_input_code.strip_edges() == "":
		output_label.text = "[系統提示] 撰寫區不可為空！"
		return
		
	output_label.text = "正在編譯並執行 Python 中..."
	
	# A. 安全性過濾
	if not check_code_safety(player_input_code):
		return
		
	# B. 生成實體檔案
	generate_py_file(player_input_code)
	
	# C. 進程執行與攔截
	execute_py_file()

func check_code_safety(code: String) -> bool:
	var forbidden_keywords = ["import os", "import sys", "import pathlib", "shutil", "eval("]
	for keyword in forbidden_keywords:
		if keyword in code:
			output_label.text = "【安全性攔截】偵測到禁用指令：%s" % keyword
			if StorySystem:
				StorySystem.start_story(generate_ai_warning_tres(keyword))
			return false
	return true

func generate_py_file(code: String) -> void:
	var file = FileAccess.open(TEMP_PY_PATH, FileAccess.WRITE)
	if file:
		file.store_string(code)
		file.close()

func execute_py_file() -> void:
	var global_py_file_path = ProjectSettings.globalize_path(TEMP_PY_PATH)
	var output_capture = []
	
	# 呼叫系統 Python 執行
	var exit_code = OS.execute("python", [global_py_file_path], output_capture, true)
	var final_result = output_capture[0] if output_capture.size() > 0 else ""
	
	if exit_code == 0:
		# 🟢 狀況 1：Python 語法執行成功
		output_label.text = final_result
		
		# 核心串接：自動比對玩家印出的結果是否包含本關卡要求的過關目標
		if current_success_keyword != "" and current_success_keyword in final_result:
			output_label.text += "\n\n🎉【編譯成功】機關已解開！"
			
			# 如果外部物件有寫過關函式（例如：_on_sandbox_success），直接跨檔案觸發它！
			if current_target_object and current_target_object.has_method("_on_sandbox_success"):
				current_target_object._on_sandbox_success()
				
			# 通關後，自動於 2 秒後關閉寫程式面板 (可選)
			await get_tree().create_timer(2.0).timeout
			close_sandbox()
	else:
		# 🔴 狀況 2：Python 語法執行報錯
		output_label.text = "【執行階段錯誤】\n" + final_result
		
		# 自動將【錯誤紅字】與【程式碼】丟給預留的 AI NPC 系統解析
		trigger_ai_npc_error_analysis(final_result, code_edit.text)

func trigger_ai_npc_error_analysis(error_msg: String, full_code: String) -> void:
	print("【AI NPC 預備接管】傳送 Traceback 紅字給 Gemini...")
	# TODO: 未來串接此處 ➡️ ai_bridge.gd 發送給 Gemini API

func generate_ai_warning_tres(keyword: String) -> DialogueData:
	var dummy_data = DialogueData.new()
	dummy_data.dialogue_sequence = [
		{"speaker": "AI 導師", "line": "不准在沙盒內呼叫危險的 [color=red]%s[/color] 指令！" % keyword},
		{"speaker": "AI 導師", "line": "請專注在解開眼前的防火牆。"}
	]
	return dummy_data
