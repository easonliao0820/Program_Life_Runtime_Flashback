extends Control

@onready var video_player: VideoStreamPlayer = $VideoStreamPlayer

func _ready() -> void:
	# 確保影片一開始就播放
	if video_player and not video_player.is_playing():
		video_player.play()

func _on_video_stream_player_finished() -> void:
	# 當影片結束時重新播放實現循環
	video_player.play()
