extends Node

# 專案主色調定義 (基於使用者需求)
const COLOR_PRIMARY = Color("#2D529E")    # 穩重的捷運藍 (標題或重點按鈕)
const COLOR_ACCENT = Color("#F8D08D")     # 明亮的黃色 (提示、反饋或亮點)
const COLOR_BACKGROUND = Color("#D9D0C1") # 舒適的淺米色 (頁面底色)
const COLOR_TEXT = Color("#1E2A38")       # 極深藍色 (文字主色)

# 輔助色調
const COLOR_SECONDARY_1 = Color("#928679") # 灰褐色
const COLOR_SECONDARY_2 = Color("#556877") # 藍灰色

func _ready():
	print("ThemeManager: 已載入專案主色調。")
