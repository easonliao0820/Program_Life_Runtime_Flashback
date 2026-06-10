extends TextureButton

@export var level_id: String = ""
@export var level_name: String = ""
@export var scene_to_load: String = ""
@export var thumbnail_texture: Texture2D

@onready var title_label: Label = $TitleLabel
@onready var thumbnail_rect: TextureRect = $MarginContainer/ThumbnailRect
@onready var locked_overlay: ColorRect = $LockedOverlay
@onready var completed_indicator: Panel = $CompletedIndicator

var is_locked: bool = true

func _ready() -> void:
	if level_name != "":
		title_label.text = level_name
	
	if thumbnail_texture:
		thumbnail_rect.texture = thumbnail_texture
		
	# 連接點擊事件與懸停動畫
	self.pressed.connect(_on_pressed)
	self.mouse_entered.connect(_on_mouse_entered)
	self.mouse_exited.connect(_on_mouse_exited)
	
	# 設定初始 pivot_offset 供縮放動畫使用
	self.pivot_offset = self.size / 2.0
	
	update_status()

# 根據 ProgressManager 更新關卡節點狀態
func update_status() -> void:
	if not ProgressManager:
		return
		
	# 檢查解鎖狀態
	is_locked = not ProgressManager.is_level_unlocked(level_id)
	self.disabled = is_locked
	locked_overlay.visible = is_locked
	
	# 檢查通關狀態
	var is_completed = ProgressManager.is_level_completed(level_id)
	completed_indicator.visible = is_completed
	
	# 根據狀態調整透明度與外觀
	if is_locked:
		self.modulate = Color(0.5, 0.5, 0.5, 0.8) # 變暗
	else:
		self.modulate = Color(1.0, 1.0, 1.0, 1.0) # 亮色
		
	# 如果是已完成，可以額外標記綠框（若有 StyleBox 的話，這裡可動態調整）

func _on_pressed() -> void:
	if is_locked:
		return
		
	if scene_to_load != "":
		print("🚀 載入關卡：", level_name, " (", scene_to_load, ")")
		get_tree().change_scene_to_file(scene_to_load)

# 懸停縮放動畫
func _on_mouse_entered() -> void:
	if not is_locked:
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2(1.08, 1.08), 0.2).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)

func _on_mouse_exited() -> void:
	if not is_locked:
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
