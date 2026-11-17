
extends Node

## 保存「後端已驗證」的玩家顯示資訊，不保存 Token 或 AWS 憑證。
## player_name 是 Google 姓名，與 GameState.user_name（遊戲角色名）分開。
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
	# id 是後端產生的玩家 UUID，Google sub 僅用於帳號綁定。
	player_id = id
	player_name = name
	player_email = email
	player_avatar_url = avatar_url
	is_logged_in = true

	login_changed.emit(true)

func _ready() -> void:
	var auth_manager = get_node("/root/AuthManager")

	auth_manager.backend_session_expired.connect(
		_on_backend_session_expired
	)


func _on_backend_session_expired() -> void:
	print("[PlayerSession] 後端登入狀態已失效")
	logout()

func logout() -> void:
	# 同時清除憑證與畫面狀態；這裡沒有刪除存檔或呼叫雲端刪除 API。
	get_node("/root/AuthManager").clear_token()
	player_id = ""
	player_name = ""
	player_email = ""
	player_avatar_url = ""
	is_logged_in = false

	login_changed.emit(false)
