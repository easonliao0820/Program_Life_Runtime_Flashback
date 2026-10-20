extends Node

func _ready() -> void:
	var target = $Chapter2Section1
	await get_tree().create_timer(1.0).timeout

	print(">>> TEST: 開始模擬玩家點擊對話框讀完開場劇情")
	var tries = 0
	while not target.story_box.is_waiting_for_sandbox and tries < 40:
		target.story_box._advance_dialogue()
		await get_tree().create_timer(0.1).timeout
		tries += 1
	print(">>> TEST: is_waiting_for_sandbox = ", target.story_box.is_waiting_for_sandbox, " (經過 ", tries, " 次點擊)")

	print(">>> TEST: setting code_edit.text and pressing Run")
	target.code_edit.text = "print(\"我覺得這裡很新奇\")"
	target.button.emit_signal("pressed")

	# 等 AI 回應（真的打 Gemini API，給足夠時間）
	await get_tree().create_timer(15.0).timeout
	print(">>> TEST: final output.text = ", target.output.text)
	print(">>> TEST: story_box waiting_for_ai = ", target.story_box.is_waiting_for_ai)
	print(">>> TEST: phase_index = ", target._phase_index)
	print(">>> TEST: current_dialogue speaker/line = ",
		target.story_box.current_dialogue.dialogue_sequence[0].speaker, " / ",
		target.story_box.current_dialogue.dialogue_sequence[0].line)
	print(">>> TEST: main_box visible = ", target.story_box.main_box.visible)
	print(">>> TEST DONE")
	get_tree().quit()
