extends Control

signal textbook_pressed

@onready var textbook_button: TextureButton = $TextbookButton

func _ready() -> void:
	textbook_button.pressed.connect(func(): textbook_pressed.emit())
	textbook_button.mouse_entered.connect(_on_textbook_hover_in)
	textbook_button.mouse_exited.connect(_on_textbook_hover_out)

func _on_textbook_hover_in() -> void:
	textbook_button.pivot_offset = textbook_button.size / 2
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(textbook_button, "scale", Vector2(1.05, 1.05), 0.15)
	tween.tween_property(textbook_button, "modulate", Color(1.3, 1.3, 1.3, 1.0), 0.15)

func _on_textbook_hover_out() -> void:
	textbook_button.pivot_offset = textbook_button.size / 2
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(textbook_button, "scale", Vector2(1.0, 1.0), 0.12)
	tween.tween_property(textbook_button, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.12)

func show_textbook() -> void:
	textbook_button.show()

func hide_textbook() -> void:
	textbook_button.hide()
