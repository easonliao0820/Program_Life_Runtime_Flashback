extends Node

## 只看結尾的跑馬燈：godot --path . res://tests/credits_preview.tscn

func _ready() -> void:
	GameFlow.stage_preview = true
	var stage: Node = load("res://src/game/stage/game_stage.tscn").instantiate()
	add_child(stage)
	await get_tree().process_frame
	await stage.credits()
	get_tree().quit()
