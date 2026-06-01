extends PanelContainer

@onready var input_line: LineEdit = $HBoxContainer/AIInputLineEdit
@onready var send_button: Button = $HBoxContainer/SendButton

# 這個訊號可以傳給主場景或 AI NPC 系統
signal player_sent_message(message: String)

func _ready() -> void:
	send_button.pressed.connect(_on_send_pressed)
	input_line.text_submitted.connect(_on_text_submitted)

	input_line.placeholder_text = "輸入想問派森的問題..."
	send_button.text = "送出"

func _on_send_pressed() -> void:
	_send_message()

func _on_text_submitted(new_text: String) -> void:
	_send_message()

func _send_message() -> void:
	var message := input_line.text.strip_edges()

	if message == "":
		return

	player_sent_message.emit(message)
	input_line.clear()
