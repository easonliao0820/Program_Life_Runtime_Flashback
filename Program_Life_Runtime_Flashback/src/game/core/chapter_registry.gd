class_name ChapterRegistry
extends RefCounted

## 全遊戲的「目錄」：依《專題劇情_完整版》與《畫面設定書》整理。
## 年齡照劇本的「時間軸」表：章節轉場、小節頂端的小字都顯示這裡的年齡。
## GameFlow 照 SECTIONS 的順序一節一節往下播；每一節對應一個 .story 劇本檔。
## 要新增／調整章節，只要改這張表跟對應的 .story 檔即可。

const SECTIONS: Array = [
	{"id": "ch1", "chapter": "第一章　放聲大哭", "title": "第一句話", "stage": "出生", "age": 0,
		"concepts": "print()", "tone": "birth", "story": "res://chapters/chapter_1/story/ch1.story"},

	{"id": "ch2_1", "chapter": "第二章　童年", "title": "2.1 記憶變數", "stage": "嬰兒", "age": 1,
		"concepts": "變數、int / float / str、f-string", "tone": "childhood", "story": "res://chapters/chapter_2/story/ch2_1.story"},
	{"id": "ch2_2", "chapter": "第二章　童年", "title": "2.2 跑腿計算", "stage": "幼兒", "age": 5,
		"concepts": "四則運算", "tone": "childhood", "story": "res://chapters/chapter_2/story/ch2_2.story"},
	{"id": "ch2_3", "chapter": "第二章　童年", "title": "2.3 便利商店", "stage": "國中", "age": 13,
		"concepts": "Boolean、if / else、round()", "tone": "mart", "story": "res://chapters/chapter_2/story/ch2_3.story"},

	{"id": "ch3_1", "chapter": "第三章　高中", "title": "3.1 捷運", "stage": "高二", "age": 17,
		"concepts": "list、append() / remove()、len()、in", "tone": "highschool", "story": "res://chapters/chapter_3/story/ch3_1.story"},
	{"id": "ch3_2", "chapter": "第三章　高中", "title": "3.2 學測 100 天", "stage": "高三", "age": 18,
		"concepts": "索引、for、range()、% 取餘數", "tone": "highschool", "story": "res://chapters/chapter_3/story/ch3_2.story"},
	{"id": "ch3_3", "chapter": "第三章　高中", "title": "3.3 隨機保佑", "stage": "高三", "age": 18,
		"concepts": "import random、while", "tone": "temple", "story": "res://chapters/chapter_3/story/ch3_3.story"},
	{"id": "ch3_4", "chapter": "第三章　高中", "title": "3.4 學測當天", "stage": "高三", "age": 18,
		"concepts": "雙層 for 迴圈、break、not in", "tone": "highschool", "story": "res://chapters/chapter_3/story/ch3_4.story"},
	{"id": "ch3_5", "chapter": "第三章　高中", "title": "3.5 放榜與離家", "stage": "高中畢業的暑假", "age": 18,
		"concepts": "", "tone": "highschool", "story": "res://chapters/chapter_3/story/ch3_5.story"},

	{"id": "ch4_1", "chapter": "第四章　大學", "title": "4.1 期末考", "stage": "大二", "age": 20,
		"concepts": "dict 字典、.items()、更新字典", "tone": "university", "story": "res://chapters/chapter_4/story/ch4_1.story"},
	{"id": "ch4_2", "chapter": "第四章　大學", "title": "4.2 慶功宴", "stage": "大二", "age": 20,
		"concepts": "", "tone": "university", "story": "res://chapters/chapter_4/story/ch4_2.story"},
	{"id": "ch4_3", "chapter": "第四章　大學", "title": "4.3 一則訊息", "stage": "大二", "age": 20,
		"concepts": "字串方法 strip() / replace() / len()", "tone": "university_night", "story": "res://chapters/chapter_4/story/ch4_3.story"},
	{"id": "ch4_4", "chapter": "第四章　大學", "title": "4.4 畢業", "stage": "大學畢業", "age": 22,
		"concepts": "", "tone": "university", "story": "res://chapters/chapter_4/story/ch4_4.story"},

	{"id": "ch5_1", "chapter": "第五章　出社會", "title": "5.1 第一份薪水", "stage": "出社會", "age": 22,
		"concepts": "def 函式、參數、return", "tone": "work", "story": "res://chapters/chapter_5/story/ch5_1.story"},
	{"id": "ch5_2", "chapter": "第五章　出社會", "title": "5.2 Cindy 的報表", "stage": "出社會", "age": 23,
		"concepts": "函式＋字典＋迴圈、sum()、不把數字寫死", "tone": "work", "story": "res://chapters/chapter_5/story/ch5_2.story"},
	{"id": "ch5_3", "chapter": "第五章　出社會", "title": "5.3 爸媽的血壓", "stage": "出社會", "age": 30,
		"concepts": "input()、int()、try / except", "tone": "work_home", "story": "res://chapters/chapter_5/story/ch5_3.story"},
	{"id": "ch5_4", "chapter": "第五章　出社會", "title": "5.4 回憶相簿", "stage": "三十歲到退休", "age": 30,
		"concepts": "class 類別、物件", "tone": "work_home", "story": "res://chapters/chapter_5/story/ch5_4.story"},

	{"id": "ch6", "chapter": "第六章　告別", "title": "最後的早晨", "stage": "晚年", "age": 80,
		"concepts": "綜合複習", "tone": "farewell", "story": "res://chapters/chapter_6/story/ch6.story"},
	{"id": "ch6_end1", "chapter": "第六章　告別", "title": "結局一：天下沒有不散的宴席", "stage": "晚年", "age": 80,
		"concepts": "綜合複習（由簡單到困難）", "tone": "farewell", "story": "res://chapters/chapter_6/story/ch6_end1.story", "ending": true},
	{"id": "ch6_end2", "chapter": "第六章　告別", "title": "結局二：你的故事還沒結束", "stage": "晚年", "age": 80,
		"concepts": "綜合複習（由困難到簡單）", "tone": "farewell_dawn", "story": "res://chapters/chapter_6/story/ch6_end2.story", "ending": true},
]

## 每一章開頭的程式名言（黑底轉場時顯示，對應這一章的主題）。
## zh 是中文翻譯，en 是原文，source 是出處。
const CHAPTER_QUOTES: Dictionary = {
	"第一章　放聲大哭": {
		"zh": "學一門新程式語言唯一的方法，就是用它來寫程式。",
		"en": "The only way to learn a new programming language is by writing programs in it.",
		"source": "Brian Kernighan & Dennis Ritchie《The C Programming Language》"},
	"第二章　童年": {
		"zh": "電腦科學裡只有兩件難事：快取失效，和替東西取名字。",
		"en": "There are only two hard things in Computer Science: cache invalidation and naming things.",
		"source": "Phil Karlton"},
	"第三章　高中": {
		"zh": "現在開始，總比永遠不開始好。",
		"en": "Now is better than never.",
		"source": "Tim Peters《The Zen of Python》"},
	"第四章　大學": {
		"zh": "錯誤永遠不該被悄悄放過。",
		"en": "Errors should never pass silently.",
		"source": "Tim Peters《The Zen of Python》"},
	"第五章　出社會": {
		"zh": "任何笨蛋都寫得出電腦看得懂的程式；好的程式設計師，寫的是人看得懂的程式。",
		"en": "Any fool can write code that a computer can understand. Good programmers write code that humans can understand.",
		"source": "Martin Fowler《Refactoring》"},
	"第六章　告別": {
		"zh": "程式是寫給人讀的，只是順便讓機器執行。",
		"en": "Programs must be written for people to read, and only incidentally for machines to execute.",
		"source": "Harold Abelson & Gerald Jay Sussman《Structure and Interpretation of Computer Programs》"},
}

## 結局判定門檻：first_try_passed / total_levels >= 這個值 → 結局二
const ENDING_THRESHOLD := 0.8

## 成就（劇本裡寫「成就：名稱」就會解鎖對應項目）
const ACHIEVEMENTS: Array = [
	{"id": "第一個變數", "desc": "把爸媽的愛存進了變數。"},
	{"id": "第一次算數", "desc": "自己算出了早餐錢。"},
	{"id": "精打細算", "desc": "在便利商店抓到店員算錯。"},
	{"id": "考場戰士", "desc": "簡章上的五樣東西一樣都沒少。"},
	{"id": "成績單守護者", "desc": "陪翊丞 All pass。"},
	{"id": "第一份薪水", "desc": "用函式分配了人生第一份薪水。"},
	{"id": "第一次被說「做得好」", "desc": "Cindy 一年說不到三次的那句話。"},
	{"id": "回憶收藏家", "desc": "用 class 把回憶做成了物件。"},
	{"id": "了解 Python", "desc": "結局一：派森融進了你的身體裡。"},
	{"id": "成為 Python", "desc": "結局二：你化成光，融進了 Python。"},
]

## 角色代表色（畫面設定書 第三節）：名字牌、立繪佔位剪影都用這個顏色。
const CHARACTERS: Dictionary = {
	"你": {"color": Color("#6f8296")},        # 藍灰
	"派森": {"color": Color("#3d7fd6")},      # 藍＋黃的光（名字牌用藍，光球另外畫）
	"倖芳": {"color": Color("#e89bb3")},      # 櫻花粉
	"媽媽": {"color": Color("#e8955a")},      # 暖橘
	"爸爸": {"color": Color("#3f7354")},      # 深綠
	"奶奶": {"color": Color("#a3456e")},      # 紫紅
	"翊丞": {"color": Color("#e6a92e")},      # 橘黃
	"Cindy": {"color": Color("#8a2a3c")},     # 酒紅
	"Claire": {"color": Color("#6cc4a8")},    # 薄荷綠
	"教授": {"color": Color("#8a8a8a")},
	"店員": {"color": Color("#8a8a8a")},
	"面試官": {"color": Color("#8a2a3c")},    # 其實是 Cindy（酒紅）
	"老闆娘": {"color": Color("#c9925e")},
	"早餐店阿姨": {"color": Color("#8a8a8a")},
	"系統": {"color": Color("#2d529e")},
	"……": {"color": Color("#9aa3ad")},
}

## 人生階段色調（畫面設定書 第一節）：背景佔位圖、暈影都依這裡上色。
## top / bottom 是漸層的上下兩色，warm 越高越像舊照片（柔焦、暈影越重）。
const TONES: Dictionary = {
	"birth":            {"top": Color("#fbf6ee"), "bottom": Color("#f6dfe4"), "accent": Color("#f6e3a6"), "warm": 1.0},
	"childhood":        {"top": Color("#ffe3a3"), "bottom": Color("#f5a96b"), "accent": Color("#9ccc72"), "warm": 0.85},
	"mart":             {"top": Color("#f7faf8"), "bottom": Color("#cfe8d6"), "accent": Color("#3aa564"), "warm": 0.6},
	"highschool":       {"top": Color("#bfe8e4"), "bottom": Color("#9cc9ef"), "accent": Color("#f4b6c8"), "warm": 0.45},
	"temple":           {"top": Color("#8d8079"), "bottom": Color("#5d4a43"), "accent": Color("#c8a24a"), "warm": 0.5},
	"university":       {"top": Color("#6a6aa8"), "bottom": Color("#2f3466"), "accent": Color("#f2c46d"), "warm": 0.3},
	"university_night": {"top": Color("#2c2f5c"), "bottom": Color("#13152f"), "accent": Color("#f2c46d"), "warm": 0.25},
	"work":             {"top": Color("#a9b8c6"), "bottom": Color("#6c7d8f"), "accent": Color("#e9b27a"), "warm": 0.15},
	"work_home":        {"top": Color("#b5bfc8"), "bottom": Color("#d8a77c"), "accent": Color("#f0c38e"), "warm": 0.35},
	"farewell":         {"top": Color("#f6c66b"), "bottom": Color("#4d8fa8"), "accent": Color("#ffe3a0"), "warm": 0.9},
	"farewell_dawn":    {"top": Color("#f9d9b8"), "bottom": Color("#6fa6c0"), "accent": Color("#ffe3a0"), "warm": 0.8},
	"memory":           {"top": Color("#0e1a3d"), "bottom": Color("#04081c"), "accent": Color("#ffd75e"), "warm": 0.0},
	"white":            {"top": Color("#ffffff"), "bottom": Color("#f3f3f3"), "accent": Color("#ffd75e"), "warm": 0.0},
	"black":            {"top": Color("#000000"), "bottom": Color("#000000"), "accent": Color("#ffd75e"), "warm": 0.0},
}

## 背景（畫面設定書 第五節素材清單）。正式美術放到 assets/backgrounds/<key>.png 就會自動取代佔位圖。
const BACKGROUNDS: Dictionary = {
	"delivery_room": {"name": "醫院產房", "tone": "birth"},
	"temple_day": {"name": "文昌帝君廟・白天", "tone": "childhood"},
	"graduation": {"name": "大學畢業典禮", "tone": "university"},
	"interview": {"name": "面試會議室", "tone": "work"},
	"living_room": {"name": "家裡客廳・午後", "tone": "childhood"},
	"breakfast_shop": {"name": "巷口早餐店・早晨", "tone": "childhood"},
	"alley": {"name": "家附近的巷子", "tone": "childhood"},
	"convenience_store": {"name": "便利商店", "tone": "mart"},
	"my_room": {"name": "主角房間", "tone": "highschool"},
	"my_room_dawn": {"name": "主角房間・清晨", "tone": "highschool"},
	"mrt_platform": {"name": "捷運月台", "tone": "highschool"},
	"mrt_car": {"name": "捷運車廂", "tone": "highschool"},
	"desk": {"name": "書桌・檯燈", "tone": "highschool"},
	"school": {"name": "學校", "tone": "highschool"},
	"library": {"name": "圖書館", "tone": "highschool"},
	"home": {"name": "家裡", "tone": "highschool"},
	"cafe": {"name": "咖啡廳", "tone": "highschool"},
	"temple": {"name": "文昌帝君廟", "tone": "temple"},
	"hospital": {"name": "病房", "tone": "birth"},
	"dorm": {"name": "大學宿舍・早晨", "tone": "university"},
	"dorm_night": {"name": "大學宿舍・夜晚", "tone": "university_night"},
	"classroom": {"name": "大學教室", "tone": "university"},
	"stir_fry": {"name": "熱炒店", "tone": "university"},
	"office": {"name": "公司辦公室", "tone": "work"},
	"office_dusk": {"name": "辦公室・傍晚", "tone": "work"},
	"meeting_room": {"name": "會議室", "tone": "work"},
	"parents_home": {"name": "爸媽家", "tone": "work_home"},
	"photo_room": {"name": "整理舊照片的房間", "tone": "work_home"},
	"lake_sunset": {"name": "湖邊・夕陽", "tone": "farewell"},
	"lake_dawn": {"name": "湖邊・清晨", "tone": "farewell_dawn"},
	"star_sky": {"name": "星空回憶空間", "tone": "memory"},
	"white": {"name": "", "tone": "white"},
	"black": {"name": "", "tone": "black"},
}


## 專案裡已經有的美術（舊版素材），檔名不在 assets/backgrounds、assets/cg 的先在這裡對應。
## 之後有正式圖，直接放到 assets/backgrounds/<鍵>.png 或 assets/cg/<名稱>.png 即可（會優先使用）。
const ART: Dictionary = {
	"delivery_room": "res://chapters/chapter_1/images/baby.png",
	"cg:birth": "res://assets/images/parentsfull.png",
}


## 改名或合併過的小節：舊存檔裡的 id 對應到現在的 id（序章已併進第一章）
const RENAMED: Dictionary = {"prologue": "ch1"}


static func index_of(section_id: String) -> int:
	for i in SECTIONS.size():
		if SECTIONS[i]["id"] == section_id:
			return i
	return -1


static func get_section(section_id: String) -> Dictionary:
	var i := index_of(section_id)
	return SECTIONS[i] if i >= 0 else {}


static func first_section_id() -> String:
	return SECTIONS[0]["id"]


## 下一節；結局章節（ending = true）之後沒有下一節，回傳空字串。
static func next_section_id(section_id: String) -> String:
	var i := index_of(section_id)
	if i < 0 or SECTIONS[i].get("ending", false):
		return ""
	if i + 1 >= SECTIONS.size():
		return ""
	var next: Dictionary = SECTIONS[i + 1]
	# 結局章節只能由 @jump 進入，不會自然往下播到
	if next.get("ending", false):
		return ""
	return next["id"]


static func character_color(speaker: String) -> Color:
	if CHARACTERS.has(speaker):
		return CHARACTERS[speaker]["color"]
	return Color("#7a8591")


static func tone(tone_id: String) -> Dictionary:
	return TONES.get(tone_id, TONES["birth"])
