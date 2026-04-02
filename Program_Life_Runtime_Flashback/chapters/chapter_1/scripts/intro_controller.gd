extends Node2D

@onready var input = $CodeEdit
@onready var output = $OutputLabel
@onready var run_button= $RunButton


func _ready():
	print("ready 有跑")
	run_button.pressed.connect(_on_run_button_pressed)
	output.text = ""

func _on_run_button_pressed():
	print("按鈕被按了")  # ← 加這行
	var code = input.text
	output.text = "[執行中...]"
	output.text = "[執行結果]\n" + fake_execute(code)
	# 呼叫 Python Sandbox
	#call_sandbox(code)
	#var result = SandboxManager.run_code(code)
	#output.text = result

func fake_execute(code: String) -> String:
	var outputs = []
	for line in code.split("\n"):
		line = line.strip_edges()
		if line.begins_with("print(") and line.ends_with(")"):
			var content = line.substr(6, line.length() - 7)
			outputs.append(content)
	return "\n".join(outputs) if outputs.size() > 0 else "(沒有輸出)"
