extends Control

@onready var back_button: Button = $Header/BackButton
@onready var reset_button: Button = $Header/ResetButton
@onready var map_content: Control = $ScrollContainer/MapContent

# 連接線節點對照表 (Key: 目標關卡 ID, Value: 對應的 Line2D 節點名稱)
# 連接線的顏色會根據「目標關卡是否解鎖」來變更
const CONNECTION_LINES = {
	"ch1_sec1": "Line_Prologue_Ch1",
	"ch2_sec1": "Line_Ch1_Ch2Sec1",
	"ch2_sec2": "Line_Ch2Sec1_Ch2Sec2",
	"ch2_sec3": "Line_Ch2Sec2_Ch2Sec3",
	"ch3_sec1": "Line_Ch2Sec3_Ch3"
}

func _ready() -> void:
	# 綁定按鈕事件
	back_button.pressed.connect(_on_back_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	
	# 隱藏全域暫停選單的齒輪（進入關卡地圖時不顯示暫停齒輪）
	if PauseMenu:
		PauseMenu.menu_container.hide()
		var gear = PauseMenu.get_node_or_null("GearButton")
		if gear:
			gear.hide()
			
	update_map()

# 更新整張地圖的關卡狀態與連接線顏色
func update_map() -> void:
	# 1. 更新所有 LevelNode 卡片狀態
	for child in map_content.get_children():
		if child.has_method("update_status"):
			child.update_status()
			
	# 2. 更新連接線顏色 (Line2D)
	for level_id in CONNECTION_LINES.keys():
		var line_name = CONNECTION_LINES[level_id]
		var line_node = map_content.get_node_or_null(line_name) as Line2D
		
		if line_node:
			if ProgressManager and ProgressManager.is_level_unlocked(level_id):
				# 已解鎖：亮白連線
				line_node.default_color = Color(1.0, 1.0, 1.0, 0.9)
			else:
				# 未解鎖：暗灰連線
				line_node.default_color = Color(0.25, 0.28, 0.32, 0.6)

func _on_back_pressed() -> void:
	print("⬅️ 返回登入畫面")
	get_tree().change_scene_to_file("res://login_screen.tscn")

func _on_reset_pressed() -> void:
	# 顯示確認視窗（簡易版）
	print("🔄 重設玩家進度...")
	if ProgressManager:
		ProgressManager.reset_progress()
		update_map()
