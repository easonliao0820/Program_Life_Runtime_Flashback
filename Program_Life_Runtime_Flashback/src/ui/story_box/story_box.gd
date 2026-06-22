extends CanvasLayer

signal story_finished
signal sandbox_waiting

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

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		_advance_dialogue()

func _advance_dialogue() -> void:
	if not main_box.visible or is_waiting_for_sandbox or is_waiting_for_ai:
		return
	if is_typing:
		type_timer.stop()
		content_label.visible_characters = content_label.get_total_character_count()
		is_typing = false
	else:
		current_line_index += 1
		show_next_line()

## 【預留互動阻斷區】處理對話播放完畢後的遊戲狀態判斷
func check_next_phase() -> void:
	# 💡 情境 A：強制玩家點擊右側 Sandbox 撰寫區回覆才能前進
	if current_dialogue and current_dialogue.next_interaction == DialogueData.InteractionType.WAIT_FOR_SANDBOX:
		is_waiting_for_sandbox = true
		main_box.custom_minimum_size.y = 70
		name_box.show()
		name_label.text = "系統提示"
		content_label.text = current_dialogue.sandbox_wait_message
		sandbox_waiting.emit()
		return

	# 💡 情境 B：未來需要交給 AI NPC (Gemini) 接手進行即時動態回覆
	if current_dialogue and current_dialogue.next_interaction == DialogueData.InteractionType.WAIT_FOR_AI:
		is_waiting_for_ai = true
		name_box.show()
		name_label.text = "AI 導師"
		content_label.text = current_dialogue.ai_wait_message
		# TODO: 這裡未來放「呼叫 ai_bridge.gd 把資訊打包送給 Gemini，並等待 Gemini 回傳文字後重新 start_story()」的代碼
		return

	# 如果沒有任何需要互動或阻斷的條件，就單純結束這段劇情並關閉視窗
	end_story()

## 將對話框移至左上角（四象限版面展開後使用）
## width_ratio: MainBox 佔螢幕寬度的比例（0.0 ~ 1.0）
## box_height:  MainBox 的高度（px）
func reposition_to_top_right(width_ratio: float = 0.6, box_height: float = 25.0) -> void:
	main_box.custom_minimum_size = Vector2(0, box_height)

	main_box.anchor_left   = 0.0
	main_box.anchor_top    = 0.0
	main_box.anchor_right  = width_ratio
	main_box.anchor_bottom = 0.0
	main_box.offset_left   = 180.0
	main_box.offset_top    = 10.0
	main_box.offset_right  = -20.0
	main_box.offset_bottom = 65.0 + box_height

	# NameBox 浮在 MainBox 下方左側，緊接在 MainBox 底部
	name_box.anchor_left   = 0.0
	name_box.anchor_top    = 0.0
	name_box.anchor_right  = 0.0
	name_box.anchor_bottom = 0.0
	name_box.offset_left   = main_box.offset_left
	name_box.offset_top    = main_box.offset_bottom + 5.0
	name_box.offset_right  = main_box.offset_left + 150.0
	name_box.offset_bottom = main_box.offset_bottom + 50.0

## 關閉劇情對話框
func end_story() -> void:
	main_box.hide()
	name_box.hide()
	is_waiting_for_sandbox = false
	is_waiting_for_ai = false
	story_finished.emit()

## 解除沙盒等待狀態並關閉對話框
func sandbox_resolved() -> void:
	if is_waiting_for_sandbox:
		end_story()
		
func can_run_sandbox() -> bool:
	return is_waiting_for_sandbox
	
func show_ai_message(speaker:String, message:String):

	main_box.show()
	name_box.show()

	name_label.text = speaker

	content_label.text = message
	content_label.visible_characters = 0

	is_typing = true
	type_timer.start()
	
func ai_finished(text:String):

	is_waiting_for_ai = false

	name_label.text = "派森"
	content_label.text = text
