extends Control

signal next_chapter_pressed
signal textbook_pressed

@onready var next_chapter_button: Button = $NextChapterButton
@onready var textbook_button: Button = $TextbookButton

func _ready() -> void:
	next_chapter_button.pressed.connect(func(): next_chapter_pressed.emit())
	textbook_button.pressed.connect(func(): textbook_pressed.emit())

func show_next_chapter() -> void:
	next_chapter_button.show()

func show_textbook() -> void:
	textbook_button.show()

func hide_next_chapter() -> void:
	next_chapter_button.hide()

func hide_textbook() -> void:
	textbook_button.hide()
