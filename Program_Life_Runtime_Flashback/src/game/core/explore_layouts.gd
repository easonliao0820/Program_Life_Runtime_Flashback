extends RefCounted

## 側向探索模式的場景配置（鍵 = 劇本 @explore 後面的 id）。
## 座標都是「背景圖上的像素」：背景高 360，寬看場景（640 一個畫面、1280 兩個畫面寬）。
## 圖還沒生的時候，遊戲會照這裡的 rooms / supports / deco 畫色塊頂著；背景圖放進
## assets/explore/<bg>.png 之後色塊就不畫了，所以下面的數字要跟背景圖上的家具對齊。
##
## supports：可以站的地方（y = 站的那條線）。wall = true 是地板（走到邊緣會被擋住），
##           否則是家具（走出邊緣會掉下去；在下面按 ↑ 可以爬上去，高度差要小於角色的 climb）。
## stairs：樓梯，top / bottom 是兩端站的位置；站在端點按 ↑ / ↓ 上下樓。
## items：物品中心的位置；{"in": 容器 id} 表示藏在容器裡，要先翻開才看得到。
## containers：可以翻的地方（抽屜、床底下…）。
## stool：可以推的板凳／椅子（推過去再按 ↑ 站上去，搆得到高的地方）。
## cat：會走來走去的貓，碰到會絆一下。
## weight：書包越重走越慢。dark：房間很暗，只有角色附近看得到。

const LAYOUTS := {
	# ---------------- 2.1 回憶盒子（1 歲，客廳，不計時）----------------
	# 背景 assets/explore/explore_living_room.png（640×303，換算成高 360 → 寬 760）
	# 高櫃子、電視櫃上的盒子要推小板凳過去才搆得到；沙發椅背上的要先爬上沙發
	"ch2_1_boxes": {
		"bg": "explore_living_room",
		"size": Vector2(760, 360),
		"player": "baby",
		"start": Vector2(300, 340),
		"rooms": [
			{"rect": Rect2(0, 0, 760, 340), "color": Color("#f1e3c8"), "label": "客廳"},
		],
		"supports": [
			{"x0": 0, "x1": 760, "y": 340, "wall": true},
			{"x0": 322, "x1": 540, "y": 278, "label": "沙發"},
		],
		"stool": {"x": 470, "floor": 340, "w": 44, "h": 37, "tex": "stool", "label": "小板凳"},
		"items": {
			"媽媽的年齡": Vector2(220, 330),
			"你出生多久了": Vector2(430, 224),
			"你的名字": Vector2(560, 330),
			"溜滑梯": Vector2(360, 268),
			"看卡通": Vector2(585, 236),
			"廟裡許願": Vector2(80, 230),
		},
		"item_icon": "回憶盒子",
		"auto_finish": true,
	},

	# ---------------- 3.1 整理書包（17 歲，透天厝兩層樓，倒數）----------------
	# 背景 assets/explore/explore_house.png（240×110，座標換算成高 360 → 寬 785）
	"ch3_1_bag": {
		"bg": "explore_house",
		"size": Vector2(785, 360),
		"player": "teen",
		"player_scale": 1.6,
		"start": Vector2(177, 164),
		"weight": true,
		"rooms": [
			{"rect": Rect2(0, 0, 789, 164), "color": Color("#e7dcc9"), "label": "2F"},
			{"rect": Rect2(0, 182, 789, 149), "color": Color("#efe4cf"), "label": "1F"},
		],
		"slabs": [Rect2(0, 164, 789, 18)],
		"supports": [
			{"x0": 7, "x1": 776, "y": 164, "wall": true},
			{"x0": 7, "x1": 776, "y": 331, "wall": true},
		],
		"stairs": [
			{"top": Vector2(363, 164), "bottom": Vector2(494, 331)},
		],
		"cat": {"y": 331, "x0": 268, "x1": 612, "speed": 55.0, "tex": "cat_walk"},
		"items": {
			"漫畫": Vector2(39, 121),
			"手機": Vector2(85, 121),
			"錢包": Vector2(170, 108),
			"數學課本": Vector2(236, 88),
			"數學作業": Vector2(334, 288),
			"悠遊卡": Vector2(655, 272),
			"手作巧克力": Vector2(26, 259),
		},
		"exit": {"pos": Vector2(727, 291), "label": "大門（出發）"},
	},

	# ---------------- 3.4 學測當天（18 歲，清晨的房間，很暗）----------------
	# 背景 assets/explore/explore_bedroom_dawn.png（640×360）
	# 角色照房門比例放大（約房門的 7 成高），每個地方伸手都搆得到；難的是很暗、要一個一個翻、還有倒數
	"ch3_4_bag": {
		"bg": "explore_bedroom_dawn",
		"size": Vector2(640, 360),
		"player": "teen",
		"player_scale": 3.0,
		"start": Vector2(70, 340),
		"dark": true,
		"light": 190.0,
		"timer": 90,
		"timer_label": "出門倒數",
		"timer_soft": "（媽媽在樓下喊：「再不出門就要遲到了！」）",
		"rooms": [
			{"rect": Rect2(0, 0, 640, 340), "color": Color("#c9cfe0"), "label": "我的房間（清晨）"},
		],
		"supports": [
			{"x0": 0, "x1": 640, "y": 340, "wall": true},
		],
		"containers": [
			{"id": "pillow", "label": "枕頭底下", "pos": Vector2(95, 256)},
			{"id": "under_bed", "label": "床底下", "pos": Vector2(110, 330)},
			{"id": "nightstand", "label": "床頭櫃抽屜", "pos": Vector2(200, 285)},
			{"id": "desk", "label": "書桌抽屜", "pos": Vector2(355, 280)},
			{"id": "desk_top", "label": "書桌上", "pos": Vector2(290, 232)},
			{"id": "shelf", "label": "置物架上", "pos": Vector2(420, 170)},
			{"id": "coat", "label": "外套口袋", "pos": Vector2(622, 200)},
		],
		"items": {
			"橡皮擦": {"in": "under_bed"},
			"手機": {"in": "nightstand"},
			"手錶": {"in": "nightstand"},
			"准考證": {"in": "desk"},
			"2B鉛筆": {"in": "desk"},
			"漫畫": {"in": "desk_top"},
			"水壺": {"in": "desk_top"},
			"身分證": {"in": "shelf"},
		},
		"exit": {"pos": Vector2(548, 300), "label": "房門（出發）", "rect": Rect2(495, 90, 105, 240)},
	},
}


## 找不到配置時：一個畫面寬的房間，物品沿著地板排開，右邊是門
static func get_layout(id: String, item_names: Array) -> Dictionary:
	if LAYOUTS.has(id):
		return LAYOUTS[id]
	var items := {}
	for i in item_names.size():
		items[item_names[i]] = Vector2(70 + i * (480.0 / maxi(item_names.size(), 1)), 320)
	return {
		"bg": "", "size": Vector2(640, 360), "player": "teen", "start": Vector2(40, 340),
		"rooms": [{"rect": Rect2(0, 20, 640, 320), "color": Color("#e9dcc6")}],
		"supports": [{"x0": 0, "x1": 640, "y": 340, "wall": true}],
		"items": items,
		"exit": {"pos": Vector2(610, 300), "label": "出發", "rect": Rect2(585, 250, 50, 90)},
	}
