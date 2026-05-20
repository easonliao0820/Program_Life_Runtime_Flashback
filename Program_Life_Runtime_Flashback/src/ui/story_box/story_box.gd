extends CanvasLayer

signal story_finished

# 透過節點路徑抓取 UI 元件 (請確保名稱與你左側場景樹一致)
@onready var main_box: PanelContainer = $Control/MainBox
@onready var name_box: PanelContainer = $Control/NameBox
@onready var name_label: Label = $Control/NameBox/MarginContainer/NameLabel
@onready var content_label: RichTextLabel = $Control/MainBox/MarginContainer/ContentLabel
@onready var type_timer: Timer = $TypeTimer

# 儲存目前的劇本與播放進度索引
var current_dialogue: DialogueData
var current_line_index: int = 0
var is_typing: bool = false

# 狀態旗標：用來標記當前劇情是否暫停，正在等待「右側寫程式」或「AI 運算」
var is_waiting_for_sandbox: bool = false
var is_waiting_for_ai: bool = false

func _ready() -> void:
	# 1. 遊戲一開始，預設完全隱藏劇情介面（大、小長方形）
	main_box.hide()
	name_box.hide()

## 【外部呼叫核心】啟動劇情播放
## 使用範例：StorySystem.start_story(preload("res://chapters/chapter_1/data/ch1_intro_story.tres"))
func start_story(data: DialogueData) -> void:
	if data == null or data.dialogue_sequence.is_empty():
		return
	
	current_dialogue = data
	current_line_index = 0
	
	# 顯示大小長方形容器
	main_box.show()
	name_box.show()
	
	# 解除所有阻斷狀態
	is_waiting_for_sandbox = false
	is_waiting_for_ai = false
	
	# 開始播放第一句對話
	show_next_line()

## 顯示下一行文本 (支援動態切換名字)
func show_next_line() -> void:
	# 檢查是否已經播完這個劇本檔案的所有文字
	if current_line_index >= current_dialogue.dialogue_sequence.size():
		check_next_phase() # 進入後續分支（沙盒或 AI 判斷）
		return
		
	# 獲取當前這一格的對話 Dictionary 資料
	var current_step = current_dialogue.dialogue_sequence[current_line_index]
	
	# 【動態換名與隱藏】若沒有說話者，則隱藏姓名框以免留下空白框
	if current_step.speaker.is_empty():
		name_box.hide()
	else:
		name_box.show()
		name_label.text = current_step.speaker
	
	content_label.text = current_step.line
	
	# 啟動打字機動畫
	content_label.visible_characters = 0
	is_typing = true
	type_timer.start()

## 打字機計時器：每 0.03 秒多亮出一個字
func _on_type_timer_timeout() -> void:
	content_label.visible_characters += 1
	if content_label.visible_characters >= content_label.get_total_character_count():
		type_timer.stop()
		is_typing = false

func _input(event: InputEvent) -> void:
	# 偵測滑鼠點擊左鍵
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# 如果劇情框根本沒顯示，或者正卡在「等待沙盒寫程式/等待AI回覆」的阻斷點，點擊就完全失效
		if not main_box.visible or is_waiting_for_sandbox or is_waiting_for_ai:
			return
			
		if is_typing:
			# 打字途中點擊：立刻停止計時器，直接顯示整段話（跳過動畫）
			type_timer.stop()
			content_label.visible_characters = content_label.get_total_character_count()
			is_typing = false
		else:
			# 播完文字點擊：進到下一句劇情
			current_line_index += 1
			show_next_line()

## 【預留互動阻斷區】處理對話播放完畢後的遊戲狀態判斷
func check_next_phase() -> void:
	# 💡 情境 A：未來當劇情結束，需要強制玩家點擊右側 Sandbox 撰寫區回覆才能前進
	# 你可以在未來根據關卡進度或 `current_dialogue` 裡的變數來修改這個 bool
	var need_code_interaction: bool = false 
	
	if need_code_interaction:
		is_waiting_for_sandbox = true
		name_box.show()
		name_label.text = "系統提示"
		content_label.text = "[color=yellow]請在右側 Typing area 撰寫正確程式以回覆對話...[/color]"
		# TODO: 這裡未來放「將右側撰寫區從 Disable 狀態解鎖，並註冊監聽 Sandbox 執行成功訊號」的代碼
		return
		
	# 💡 情境 B：未來需要交給 AI NPC (Gemini) 接手進行即時動態回覆
	var need_ai_reply: bool = false
	
	if need_ai_reply:
		is_waiting_for_ai = true
		name_box.show()
		name_label.text = "AI 導師"
		content_label.text = "...正在讀取當前遊戲與錯誤資訊，Gemini 思考中..."
		# TODO: 這裡未來放「呼叫 ai_bridge.gd 把資訊打包送給 Gemini，並等待 Gemini 回傳文字後重新 start_story()」的代碼
		return

	# 如果沒有任何需要互動或阻斷的條件，就單純結束這段劇情並關閉視窗
	end_story()

## 關閉劇情對話框
func end_story() -> void:
	main_box.hide()
	name_box.hide()
	is_waiting_for_sandbox = false
	is_waiting_for_ai = false
	story_finished.emit()
