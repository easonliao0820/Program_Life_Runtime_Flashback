extends CanvasLayer

# 獲取各個面板與標題節點
@onready var menu_container: Control = $Control
@onready var menu_title: Label = $Control/VBoxContainer/MenuTitle
@onready var main_menu_buttons: VBoxContainer = $Control/VBoxContainer/MainMenuButtons
@onready var settings_panel: VBoxContainer = $Control/VBoxContainer/SettingsPanel
@onready var volume_slider: HSlider = $Control/VBoxContainer/SettingsPanel/VolumeSlider

const BUS_MASTER = "Master"

func _ready() -> void:
	# 遊戲開始時，完全隱藏暫停控制台
	menu_container.hide()
	
	# 初始化設定：顯示主選單、隱藏設定面板
	reset_menu_view()
	
	# 初始化音量滑條
	var bus_index = AudioServer.get_bus_index(BUS_MASTER)
	if bus_index != -1:
		volume_slider.value = db_to_linear(AudioServer.get_bus_volume_db(bus_index))
	
	# 連接音量滑條訊號
	volume_slider.value_changed.connect(_on_volume_slider_changed)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

# 切換暫停與恢復遊戲
func toggle_pause() -> void:
	var new_pause_state = !get_tree().paused
	get_tree().paused = new_pause_state
	menu_container.visible = new_pause_state
	
	# 每次打開選單時，都強迫重設回「主暫停畫面」
	if new_pause_state:
		reset_menu_view()

# 重設選單視圖（回到主暫停畫面）
func reset_menu_view() -> void:
	menu_title.text = "遊戲暫停"
	main_menu_buttons.show()
	settings_panel.hide()

# ==================== 訊號連接函式 ====================

func _on_gear_button_pressed() -> void:
	toggle_pause()

func _on_resume_button_pressed() -> void:
	toggle_pause()

# 💡 核心變動：點擊「設定選項」
func _on_settings_button_pressed() -> void:
	# 1. 修改上方大標題
	menu_title.text = "系統設定"
	# 2. 隱藏主選單按鈕群
	main_menu_buttons.hide()
	# 3. 顯示音量控制與返回按鈕面板
	settings_panel.show()

# 💡 核心變動：點擊設定面板裡的「返回選單」
func _on_back_button_pressed() -> void:
	# 恢復原狀
	reset_menu_view()

func _on_volume_slider_changed(value: float) -> void:
	var bus_index = AudioServer.get_bus_index(BUS_MASTER)
	if bus_index != -1:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))

func _on_exit_button_pressed() -> void:
	get_tree().paused = false
	get_tree().quit()
