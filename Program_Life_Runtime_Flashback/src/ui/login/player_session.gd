
extends Node

signal login_changed(is_logged_in: bool)

var is_logged_in := false
var player_id := ""
var player_name := ""
var player_email := ""
var player_avatar_url := ""

func set_verified_player(
	id: String,
	name: String,
	email: String,
	avatar_url: String
) -> void:
	player_id = id
	player_name = name
	player_email = email
	player_avatar_url = avatar_url
	is_logged_in = true

	login_changed.emit(true)


func logout() -> void:
	player_id = ""
	player_name = ""
	player_email = ""
	player_avatar_url = ""
	is_logged_in = false

	login_changed.emit(false)
