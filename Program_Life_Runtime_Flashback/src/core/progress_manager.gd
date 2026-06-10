extends Node

# 存檔路徑
const SAVE_PATH = "user://save_data.json"

# 關卡解鎖關係字典：[完成這關] -> [解鎖下關]
const UNLOCK_RELATION = {
	"prologue": "ch1_sec1",
	"ch1_sec1": "ch2_sec1",
	"ch2_sec1": "ch2_sec2",
	"ch2_sec2": "ch2_sec3",
	"ch2_sec3": "ch3_sec1"
}

# 玩家進度資料
var unlocked_levels: Array = ["prologue", "ch1_sec1"]  # 初始解鎖前言與第一章
var completed_levels: Array = []                      # 已通關關卡
# 用來記錄玩家是否是從「關卡地圖」進入關卡的
var coming_from_map: bool = false

func _ready() -> void:
	load_progress()

# 檢查關卡是否已解鎖
func is_level_unlocked(level_id: String) -> bool:
	return unlocked_levels.has(level_id)

# 檢查關卡是否已完成
func is_level_completed(level_id: String) -> bool:
	return completed_levels.has(level_id)

# 標記關卡為完成，並解鎖下一關
func complete_level(level_id: String) -> void:
	if not completed_levels.has(level_id):
		completed_levels.append(level_id)
	
	# 檢查是否有對應解鎖的下一關
	if UNLOCK_RELATION.has(level_id):
		var next_level = UNLOCK_RELATION[level_id]
		if not unlocked_levels.has(next_level):
			unlocked_levels.append(next_level)
			print("🎉 解鎖新關卡：", next_level)
			
	save_progress()

# 儲存進度到本地
func save_progress() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var data = {
			"unlocked_levels": unlocked_levels,
			"completed_levels": completed_levels
		}
		var json_string = JSON.stringify(data)
		file.store_string(json_string)
		file.close()
		print("💾 存檔成功！路徑：", ProjectSettings.globalize_path(SAVE_PATH))

# 讀取本地進度
func load_progress() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		print("ℹ️ 無現有存檔，載入初始預設值。")
		return
		
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var parsed_data = JSON.parse_string(json_string)
		if parsed_data is Dictionary:
			if parsed_data.has("unlocked_levels"):
				unlocked_levels = parsed_data["unlocked_levels"]
			if parsed_data.has("completed_levels"):
				completed_levels = parsed_data["completed_levels"]
			print("💾 讀取存檔成功！已解鎖關卡：", unlocked_levels)
		else:
			print("❌ 存檔格式錯誤，無法讀取。")

# 重設存檔（供地圖 Reset 按鈕呼叫）
func reset_progress() -> void:
	unlocked_levels = ["prologue", "ch1_sec1"]
	completed_levels = []
	save_progress()
	print("🔄 已重設所有關卡進度。")
