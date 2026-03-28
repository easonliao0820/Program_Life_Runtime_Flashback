extends Button

# 貼上你在 Google Cloud Console 拿到的用戶端 ID
#619377384055-3leeasc4abkrjh614ce2nnrq5kiao1g1.apps.googleusercontent.com
const CLIENT_ID = "619377384055-3leeasc4abkrjh614ce2nnrq5kiao1g1.apps.googleusercontent.com"
const REDIRECT_URI = "http://localhost:8000"

func _ready():
	# 當按鈕被按下時，執行 _on_pressed 函式
	self.pressed.connect(_on_google_login_button_pressed)

func _on_google_login_button_pressed():
	var auth_url = "https://accounts.google.com/o/oauth2/v2/auth"
	var scope = "https://www.googleapis.com/auth/userinfo.email profile"
	var response_type = "token"

	# 組合請求網址
	var url = "%s?client_id=%s&redirect_uri=%s&response_type=%s&scope=%s" % [
		auth_url,
		CLIENT_ID.uri_encode(),
		REDIRECT_URI.uri_encode(),
		response_type,
		scope.uri_encode()
	]
	
	# 如果是在 Web 環境，這行會呼叫瀏覽器開啟新分頁
	OS.shell_open(url)
	print("正在導向 Google 登入...")
