extends Node

## 登入憑證集中管理：Token 只放記憶體，供未來雲端存檔／玩家 API 使用。
## 收到 Token 不代表身分已驗證；每個私人資料 API 都必須交由後端驗證。
## AiBridge 預設匿名，不依賴這個管理器，也不因沒有 Token 而停用。
var _google_id_token := ""
var _expires_at: float = 0.0


func set_google_token(token_data: Dictionary) -> void:
	# expires_in 是 Google 回應的有效秒數；這裡只計算本機預估到期時間。
	# 未實作自動刷新；真正的 Token 有效性仍由後端檢查。
	_google_id_token = str(token_data.get("id_token", ""))
	_expires_at = Time.get_unix_time_from_system() + maxf(0.0, float(token_data.get("expires_in", 0)))


func get_google_id_token() -> String:
	# 過期就回空字串；雲端存檔呼叫端應要求重新登入，而非傳送過期憑證。
	if Time.get_unix_time_from_system() >= _expires_at:
		clear_token()
	return _google_id_token


func clear_token() -> void:
	# 登出或登入驗證失敗時清除；不會刪除本機遊戲進度。
	_google_id_token = ""
	_expires_at = 0.0
