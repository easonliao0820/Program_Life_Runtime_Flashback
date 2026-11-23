extends Node

## 只看結尾的跑馬燈：godot --path . res://tests/credits_preview.tscn

func _ready() -> void:
	GameFlow.stage_preview = true
	var stage: Node = load("res://src/game/stage/game_stage.tscn").instantiate()
	add_child(stage)
	await get_tree().process_frame
	# 跟正式結局二一樣：片尾開始前跳出「成就：成為 Python」（只顯示彈窗，不寫進存檔）
	stage.popup.show_achievement("成為 Python")
	await stage.credits()
	get_tree().quit()
