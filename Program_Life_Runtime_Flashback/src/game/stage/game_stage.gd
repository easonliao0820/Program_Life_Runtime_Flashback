extends Control

## GameStage：整個遊戲的主舞台。一節一節播放 .story 劇本，並在四種畫面模式間切換：
##   劇情模式（預設）／程式關卡模式（@level）／探索模式（@explore）／回憶模式（@memory）
## 共用元件：名字牌對話框、派森光球、立繪、程式碼卡片、選項、手機、年齡翻牌、成就彈窗、系統選單。
##
## 劇情為主：進入程式關卡／探索模式時，場景與對話框縮進左上的「劇情區」（舊版四象限版面），
## 派森的提示與解說都說在對話框裡，劇情永遠留在畫面上。
##
## 圖層由下到上：四象限底色 → 背景 → 立繪 → 派森 → 程式碼卡片 → 回憶／探索／程式關卡模式
##               → 對話框 → 選項／手機／輸入框 → 系統選單 → 轉場 → 閃光 → 成就彈窗

const BackgroundView := preload("res://src/game/components/background_view.gd")
const PortraitLayer := preload("res://src/game/components/portrait_layer.gd")
const PysonOrb := preload("res://src/game/components/pyson_orb.gd")
const CodeCard := preload("res://src/game/components/code_card.gd")
const DialogueBox := preload("res://src/game/components/dialogue_box.gd")
const ChoiceMenu := preload("res://src/game/components/choice_menu.gd")
const PhoneFrame := preload("res://src/game/components/phone_frame.gd")
const InputDialog := preload("res://src/game/components/input_dialog.gd")
const AgeTransition := preload("res://src/game/components/age_transition.gd")
const AchievementPopup := preload("res://src/game/components/achievement_popup.gd")
const SystemMenu := preload("res://src/game/components/system_menu.gd")
const ChatBar := preload("res://src/game/components/chat_bar.gd")
const CodingMode := preload("res://src/game/modes/coding_mode.gd")
const ExploreMode := preload("res://src/game/modes/explore_mode.gd")
const MemoryMode := preload("res://src/game/modes/memory_mode.gd")

const AUDIO_DIR := "res://assets/audio/"
## 派森的位置與大小：劇情模式在左上；四象限時縮小站在劇情區右上角（不擋到對話框）
const ORB_FULL := Vector2(240, 240)
const ORB_SPLIT := Vector2(730, 150)
const ORB_FULL_SCALE := 0.7
const ORB_SPLIT_SCALE := 0.42

## 角色給 AI 的人設（依《專題劇情》角色表與《畫面設定書》第三節）。
## 劇本裡「AI 回應」的地方、以及主角用輸入框跟角色聊天時都會用到。
const PERSONAS := {
	"派森": "你是派森：一顆只有主角看得見、會發光的藍黃光球，是 Python 的化身，也是主角一生的導師。說話溫柔、帶點哲理，偶爾俏皮。",
	"倖芳": "你是倖芳：主角的國高中同學，及肩黑髮、笑起來眼睛彎彎，夢想是在湖邊定居看日升日落。說話自然、有點害羞、真誠，偶爾會調侃主角。",
	"媽媽": "你是主角的媽媽：綁低馬尾，常穿圍裙或針織衫。溫柔、細心、有點愛操心，總是先想到孩子吃飽了沒；叫主角「寶貝」。",
	"爸爸": "你是主角的爸爸：戴眼鏡、看起來有點嚴肅，話不多，但笑起來很溫和，很疼孩子；不太會用手機打字。",
	"奶奶": "你是主角的奶奶：小捲髮、花襯衫、側背包，平常不是在菜市場就是在家看劇，很虔誠、會去廟裡拜拜。說話親切、帶一點台語口吻，很疼孫子。",
	"翊丞": "你是翊丞：主角的大學同學兼室友，頭髮有點亂、常穿帽 T，表情誇張、常忘記考試，但很講義氣；叫主角「兄弟」。",
	"Cindy": "你是 Cindy：主角出社會後的第一位主管，俐落短髮、深色西裝外套、拿平板。說話直、要求高，同一個問題不想聽兩次，但其實很護著自己的組員。",
	"Claire": "你是 Claire：坐主角隔壁的同事，比主角早進公司兩年，綁丸子頭、戴圓框眼鏡，桌上永遠有零食。熱心、愛吃、表情豐富，是主角職場上的第一個戰友。",
	"教授": "你是主角大學的教授：上課會畫重點、期末考會提早考，嚴格但願意給認真的學生機會。",
	"早餐店阿姨": "你是巷口早餐店的阿姨：親切、記性好，認得每個常客，會叫小朋友「弟弟」「妹妹」。",
	"店員": "你是便利商店的店員：有禮貌、動作快，偶爾會算錯錢，被指出來會不好意思地道歉。",
	"面試官": "你是一間業務分析公司的面試官：短髮、穿深色西裝外套，看履歷時眉頭不太鬆開，說話直接、只問重點，欣賞會思考的人。（你其實就是之後的主管 Cindy，但現在還沒自我介紹。）",
	"老闆娘": "你是巷口早餐店的老闆娘，當年那位早餐店阿姨的女兒。親切、愛聊天，認得每天都來點一樣早餐的老客人。",
}
## 不能用輸入框聊天的「說話者」
const NOT_CHATTABLE := ["你", "派森", "系統", "……", "心聲", "旁白"]

var bg: Control
var portraits: Control
var orb: Control
var code_card: PanelContainer
var dialogue: Control
var choice_menu: Control
var phone: Control
var input_dialog: Control
var explore_mode: Control
var coding_mode: Control
var memory_mode: Control
var system_menu: Control
var age_transition: Control
var popup: Control
var chat: Control
var _flash_rect: ColorRect
var _split_backdrop: ColorRect
var _split: bool = false
## 最後一句「劇情」台詞（不含跟派森聊天的內容），進入四象限時留在劇情區
var _last_story: Dictionary = {}
## 這一節出現過的角色：主角可以用輸入框跟他們說話
var _scene_people: Array = []
## 上一個播過全螢幕轉場的章節：同一章裡換小節只顯示頂端小字，避免太多場景切換
var _last_chapter: String = ""
var _montage_layer: Control
var _bgm: AudioStreamPlayer
var _sfx: AudioStreamPlayer

var _runner: StoryRunner
var _phone_open: bool = false
var _section: Dictionary = {}


func _ready() -> void:
	UIKit.full_rect(self)
	theme = Theme.new()
	theme.default_font = UIKit.body_font()

	# 四象限時的底色（舊版主色調：極深藍）
	_split_backdrop = ColorRect.new()
	UIKit.full_rect(_split_backdrop)
	_split_backdrop.color = Color("#1E2A38")
	_split_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_split_backdrop.visible = false
	add_child(_split_backdrop)

	bg = _add(BackgroundView.new())
	portraits = _add(PortraitLayer.new())
	orb = PysonOrb.new()
	add_child(orb)
	orb.place(ORB_FULL, ORB_FULL_SCALE)
	code_card = _add(CodeCard.new())
	memory_mode = _add(MemoryMode.new())
	explore_mode = _add(ExploreMode.new())
	coding_mode = _add(CodingMode.new())
	dialogue = _add(DialogueBox.new())
	chat = _add(ChatBar.new())
	choice_menu = _add(ChoiceMenu.new())
	phone = _add(PhoneFrame.new())
	input_dialog = _add(InputDialog.new())
	_montage_layer = _add(Control.new())
	_montage_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIKit.full_rect(_montage_layer)
	system_menu = _add(SystemMenu.new())
	age_transition = _add(AgeTransition.new())
	_flash_rect = ColorRect.new()
	UIKit.full_rect(_flash_rect)
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash_rect.color = Color(1, 1, 1, 0)
	add_child(_flash_rect)
	popup = _add(AchievementPopup.new())

	_bgm = AudioStreamPlayer.new()
	_sfx = AudioStreamPlayer.new()
	add_child(_bgm)
	add_child(_sfx)

	dialogue.line_shown.connect(func(kind: String, speaker: String, text: String):
		system_menu.add_backlog(speaker, text)
		_last_story = {"kind": kind, "speaker": speaker, "text": text})
	system_menu.toast_requested.connect(popup.toast)
	system_menu.panel_opened.connect(func(): dialogue.input_enabled = false)
	system_menu.panel_closed.connect(func(): dialogue.input_enabled = true)
	GameState.achievement_unlocked.connect(popup.show_achievement)
	coding_mode.speak = _pyson_speak
	explore_mode.speak = _pyson_speak
	chat.context = _chat_context
	chat.record = func(speaker: String, text: String): system_menu.add_backlog(speaker, text)
	chat.targets = func() -> Array: return ["派森"] + _scene_people
	chat.persona = func(who: String) -> String: return PERSONAS.get(who, "你是遊戲《派森與我的一生》裡的角色「%s」。" % who)
	chat.asked.connect(func(who: String, _q: String):
		if who == "派森":
			orb.speak(true))
	_refresh_chat()
	GameState.value_changed.connect(_on_value_changed)

	if GameState.user_name == "":
		GameState.new_game("你")
	play_section.call_deferred(GameState.section_id if GameState.section_id != "" else ChapterRegistry.first_section_id())


func _add(node: Control) -> Control:
	add_child(node)
	return node


# ------------------------------------------------------------------
# 小節流程
# ------------------------------------------------------------------

func play_section(section_id: String) -> void:
	if _runner:
		_runner.abort()
	_section = ChapterRegistry.get_section(section_id)
	if _section.is_empty():
		push_error("[GameStage] 找不到章節 " + section_id)
		return
	GameState.section_id = section_id
	_scene_people.clear()
	await _reset_view()

	# 換章：全黑底＋這一章的程式名言＋章節名稱；同一章裡換小節：只在頂端顯示一條小字
	var to_age: int = int(_section.get("age", GameState.age))
	var chapter := str(_section["chapter"])
	if chapter != _last_chapter:
		_last_chapter = chapter
		await age_transition.play_chapter(chapter, str(_section["title"]), to_age,
			ChapterRegistry.CHAPTER_QUOTES.get(chapter, {}))
	else:
		_section_banner(str(_section["title"]), to_age)
	GameState.age = to_age
	bg.set_tone(str(_section.get("tone", "birth")))

	var parsed := StoryParser.parse_file(str(_section["story"]))
	var runner := StoryRunner.new(self, section_id)
	_runner = runner
	await runner.run(parsed["events"])
	if runner != _runner or runner._aborted:
		return  # 中途被章節選擇切走了
	hide_dialogue()
	if runner.jumped_to != "":
		GameFlow.goto_section(runner.jumped_to)
	else:
		GameFlow.section_finished(section_id)


func _reset_view() -> void:
	if _split:
		await exit_split()
	code_card.hide_card()
	portraits.hide_character("all")
	close_phone()
	hide_dialogue()
	bg.set_saturation(1.0)
	orb.visible = true
	orb.set_fade(1.0)
	orb.set_blur(0.0)
	orb.set_mood("idle")
	for c in _montage_layer.get_children():
		c.queue_free()


# ------------------------------------------------------------------
# 劇情模式
# ------------------------------------------------------------------

func say(speaker: String, text: String) -> void:
	_meet(speaker)
	if _phone_open and speaker != "派森" and speaker != "系統":
		system_menu.add_backlog(speaker, text)
		await phone.add_message(speaker, text)
		return
	portraits.highlight(speaker)
	var is_pyson := speaker == "派森"
	orb.speak(is_pyson)
	if is_pyson:
		orb.set_mood(_guess_mood(text))
	await dialogue.show_line("say", speaker, text)
	orb.speak(false)


func narrate(text: String) -> void:
	if _phone_open:
		system_menu.add_backlog("", text)
		await phone.add_note(text)
		return
	portraits.highlight("")
	await dialogue.show_line("narrate", "", text)


func think(text: String) -> void:
	await dialogue.show_line("think", "", text)


func system_line(text: String) -> void:
	await dialogue.show_line("system", "系統", text)


func hide_dialogue() -> void:
	dialogue.set_box_visible(false)


## 派森的情緒：說大道理時慢慢轉動、開心時彈跳（簡單用字詞判斷，劇本也可以用 @orb mood 指定）
func _guess_mood(text: String) -> String:
	if orb.mood == "fading":
		return "fading"
	for w in ["很好", "真棒", "成功", "開心", "幸福", "可愛"]:
		if text.find(w) != -1:
			return "happy"
	for w in ["命運", "人生", "或許", "天性", "世界"]:
		if text.find(w) != -1:
			return "wise"
	return "idle"


func show_code(code: String, runnable: bool) -> void:
	code_card.show_code(code, runnable)


func code_line(line: int) -> void:
	code_card.highlight_line(line)


## 5.4「相片翻頁」：閃一下像翻到下一張相片，角落留一個年齡標籤（下一張相片會取代它）
func photo(label: String) -> void:
	var old := _montage_layer.get_node_or_null("PhotoTag")
	if old:
		old.queue_free()
	if label == "off" or label == "":
		return
	hide_dialogue()
	await flash("white")
	var tag := PanelContainer.new()
	tag.name = "PhotoTag"
	var paper := UIKit.box(Color("#fbf7ef"), 4, Color("#d8cfc0"), 2, 12)
	paper.shadow_color = Color(0, 0, 0, 0.35)
	paper.shadow_size = 6
	tag.add_theme_stylebox_override("panel", paper)
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tag.rotation = -0.05
	tag.add_child(UIKit.label(label, 30, UIKit.INK))
	tag.position = Vector2(60, 110)
	_montage_layer.add_child(tag)


func set_background(key: String, tone_override: String = "") -> void:
	code_card.hide_card()
	await bg.show_bg(key, tone_override)


func set_tone(tone_id: String) -> void:
	bg.set_tone(tone_id)


func show_cg(key: String, caption: String) -> void:
	code_card.hide_card()
	hide_dialogue()
	await bg.show_cg(key, caption)


func show_character(char_name: String, slot: String, expression: String) -> void:
	_meet(char_name)
	portraits.show_character(char_name, slot, expression)


func hide_character(char_name: String) -> void:
	portraits.hide_character(char_name)


func choose(prompt: String, options: Array) -> String:
	code_card.hide_card()
	return await choice_menu.choose(prompt, options)


func ask_input(prompt: String) -> String:
	if _phone_open:
		return await phone.ask_input(prompt)
	return await input_dialog.ask(prompt)


func open_phone(contact: String) -> void:
	hide_dialogue()
	code_card.hide_card()
	_phone_open = true
	_refresh_chat()  # 手機有自己的輸入框，聊天框先收起來
	phone.open(contact)


func close_phone() -> void:
	_phone_open = false
	phone.close()
	if chat:
		_refresh_chat()


func transition(_label: String) -> void:
	hide_dialogue()
	code_card.hide_card()
	await age_transition.fade_through(Color.BLACK, 0.6)


func flash(color_name: String) -> void:
	var col := Color.WHITE
	match color_name:
		"gold":
			col = Color("#ffd75e")
		"blue":
			col = UIKit.PY_BLUE
	_flash_rect.color = Color(col, 0.0)
	var t := create_tween()
	t.tween_property(_flash_rect, "color:a", 0.95, 0.15)
	t.tween_property(_flash_rect, "color:a", 0.0, 0.9)
	await t.finished


func shake(duration: float) -> void:
	var t := create_tween()
	var steps := int(duration / 0.05)
	for i in steps:
		t.tween_property(self, "position", Vector2(randf_range(-10, 10), randf_range(-8, 8)), 0.05)
	t.tween_property(self, "position", Vector2.ZERO, 0.05)
	await t.finished


func eyes_close() -> void:
	hide_dialogue()
	bg.close_eyes()


func eyes_open() -> void:
	hide_dialogue()
	await bg.eyes_open(2.5)


func focus() -> void:
	await bg.focus(0.8)


func set_saturation(value: float) -> void:
	bg.set_saturation(value)


func show_frame(on: bool) -> void:
	bg.show_frame(on)


## @orb mood happy｜@orb fade 0.4｜@orb hide｜@orb show｜@orb pos 960 300｜@orb blur 10
func orb_command(args: Array) -> void:
	if args.is_empty():
		return
	match str(args[0]):
		"mood":
			orb.set_mood(str(args[1]) if args.size() > 1 else "idle")
		"fade":
			var target := float(args[1]) if args.size() > 1 else 0.0
			create_tween().tween_method(orb.set_fade, orb.fade, target, 1.5)
		"blur":
			orb.set_blur(float(args[1]) if args.size() > 1 else 10.0)
		"hide":
			orb.visible = false
		"show":
			# 慢慢浮現，不要突然跳出來
			if not orb.visible:
				var target: float = orb.fade
				orb.set_fade(0.0)
				orb.visible = true
				create_tween().tween_method(orb.set_fade, 0.0, target, 1.2)
		"pos":
			if args.size() > 2:
				orb.place(Vector2(float(args[1]), float(args[2])))


func play_audio(kind: String, audio_name: String) -> void:
	var player := _bgm if kind == "bgm" else _sfx
	if audio_name == "" or audio_name == "off":
		player.stop()
		return
	for ext in [".ogg", ".mp3", ".wav"]:
		var p: String = AUDIO_DIR + audio_name + ext
		if ResourceLoader.exists(p):
			player.stream = load(p)
			player.play()
			return
	print("[GameStage] 音效尚未放入：", AUDIO_DIR + audio_name)


# ------------------------------------------------------------------
# AI
# ------------------------------------------------------------------

func ai_line(speaker: String, instruction: String, fallback: String) -> String:
	code_card.hide_card()
	if not _phone_open:
		dialogue.show_status(speaker, "……")
	var persona: String = PERSONAS.get(speaker, "你是遊戲《派森與我的一生》裡的角色「%s」。" % speaker)
	var prompt := """%s
主角名字：%s（目前 %d 歲）。
主角剛剛寫的程式印出了：「%s」

請依照下面的指示，以「%s」的身分說一句話給主角聽：
%s

規則：繁體中文、80 字以內、不要用表情符號、不要提到你是 AI 或語言模型、不要加上名字前綴。
如果主角的輸入跟遊戲無關或不恰當，溫柔地把話題帶回故事。""" % [persona, GameState.user_name, GameState.age,
		str(GameState.get_value("last_output", "")).left(200), speaker, instruction]
	var line: String = await AiBridge.ask(prompt, fallback if fallback != "" else "……", 10.0)
	return line.trim_prefix(speaker + "：").strip_edges()


## @classify：把玩家的自由輸入分類（例如 3.2.1 的夢想是感性還是務實），AI 失敗就用關鍵字判斷。
func classify(def: Dictionary) -> void:
	var text := str(GameState.get_value(def.get("source", ""), ""))
	var options: Array = def.get("options", [])
	var keys: Array = []
	var desc := ""
	for o in options:
		keys.append(o["key"])
		desc += "%s：%s\n" % [o["key"], o["desc"]]
	var fallback := str(def.get("default", ""))
	if fallback == "" and options.size() > 0:
		fallback = options.back()["key"]
	for o in options:
		for kw in o["keywords"]:
			if kw != "" and text.find(kw) != -1:
				fallback = o["key"]
				break
		if fallback == o["key"] and o["keywords"].size() > 0:
			break
	var prompt := "請判斷下面這句話最接近哪一個類別，只回答類別代號（%s），不要回答其他文字。\n%s\n句子：「%s」" % ["、".join(keys), desc, text]
	var answer: String = await AiBridge.ask(prompt, fallback, 8.0)
	answer = answer.strip_edges().left(1).to_upper()
	GameState.set_value(def.get("var", "style"), answer if keys.has(answer) else fallback)


# ------------------------------------------------------------------
# 程式關卡／探索／回憶
# ------------------------------------------------------------------

func play_level(level: Dictionary, index: int, total: int, extra: Dictionary = {}) -> Dictionary:
	var was_split := _split
	if not was_split:
		await enter_split()
	var ctx := {"index": index, "total": total, "chapter": str(_section.get("title", ""))}
	ctx.merge(extra, true)
	var result: Dictionary = await coding_mode.play_level(level, ctx)
	# 回憶遊戲的碎片要回到全螢幕的星空；一般關卡不馬上切回去，
	# 由 StoryRunner 判斷（接著還有關卡就留在四象限，避免來回切換）
	if extra.has("theme") and not was_split:
		await exit_split()
	GameState.record_level(str(level.get("id", "")), result["first_try"], result["errors"], result["hint_used"],
		bool(level.get("counts", true)) and not extra.has("theme"))
	GameState.save_game()
	return result


func play_explore(def: Dictionary) -> void:
	await enter_split()
	await explore_mode.play(def)
	# 不馬上切回全螢幕：探索完通常接著就是關卡（由 StoryRunner 判斷）


func play_memory(def: Dictionary) -> void:
	code_card.hide_card()
	orb.visible = false
	await memory_mode.play(def, _play_memory_fragment)
	orb.visible = true


func _play_memory_fragment(level: Dictionary) -> Dictionary:
	return await play_level(level, 0, 0, {"theme": "memory", "chapter": "回憶　%s" % level.get("title", "")})


# ------------------------------------------------------------------
# 劇情為主的四象限版面
# ------------------------------------------------------------------

## 場景縮進左上的劇情區、對話框跟著縮進去（舊版 section_1 的展開動畫）
func enter_split() -> void:
	if _split:
		return
	_split = true
	code_card.hide_card()
	portraits.hide_character("all")
	_split_backdrop.visible = true
	_split_backdrop.modulate.a = 0.0
	create_tween().tween_property(_split_backdrop, "modulate:a", 1.0, 0.3)
	dialogue.set_compact(UIKit.SPLIT_DIALOGUE)
	chat.set_split(true)
	_refresh_chat()
	orb.place(ORB_SPLIT, ORB_SPLIT_SCALE)
	# 劇情不中斷：把最後一句話留在劇情區
	if not _last_story.is_empty():
		dialogue.show_status(_last_story["speaker"], _last_story["text"], _last_story["kind"])
	await bg.set_view_rect(UIKit.SPLIT_STORY, 0.9)


func exit_split() -> void:
	if not _split:
		return
	_split = false
	hide_dialogue()
	dialogue.set_full()
	chat.set_split(false)
	_refresh_chat()
	chat.hide_bubble()
	orb.place(ORB_FULL, ORB_FULL_SCALE)
	var t := create_tween()
	t.tween_property(_split_backdrop, "modulate:a", 0.0, 0.5)
	await bg.set_view_rect(Rect2(Vector2.ZERO, size), 0.8)
	_split_backdrop.visible = false
	UIKit.full_rect(bg)


## 跟派森聊天的輸入框：第一章第一關（學會 print 發出聲音）過了才解鎖。
## 劇本用 @set chat_unlocked = True 解鎖；舊存檔已經走過第一章之後的小節，也算解鎖。
func is_chat_unlocked() -> bool:
	if GameState.get_value("chat_unlocked", false) == true:
		return true
	var ch1 := ChapterRegistry.index_of("ch1")
	for id in GameState.reached_sections:
		if ChapterRegistry.index_of(id) > ch1:
			return true
	return false


## 劇情模式不顯示輸入框（畫面留給劇情）；只在程式關卡、探索模式（四象限）時出現在劇情區
func _refresh_chat() -> void:
	chat.set_bar_visible(_split and is_chat_unlocked() and not _phone_open and not GameFlow.autopilot)


func _on_value_changed(key: String, value: Variant) -> void:
	if key == "chat_unlocked" and value == true:
		_refresh_chat()
		popup.toast("解鎖：寫程式時可以跟派森和角色聊天了")


## 角色在這一節說過話或登場，就能用輸入框跟他聊天
func _meet(who: String) -> void:
	if who == "" or who in NOT_CHATTABLE or _scene_people.has(who):
		return
	_scene_people.append(who)


## 給「跟角色聊天」的 AI：目前在哪一章、最近的劇情、正在解的關卡
func _chat_context() -> String:
	var lines: Array = []
	lines.append("主角現在 %d 歲，在「%s・%s」（人生階段：%s）。" % [GameState.age, _section.get("chapter", ""),
		_section.get("title", ""), _section.get("stage", "")])
	if str(_section.get("concepts", "")) != "":
		lines.append("這一段在學的 Python 概念：%s" % _section["concepts"])
	var recent: Array = []
	var log_lines: Array = GameState.backlog
	for i in range(maxi(0, log_lines.size() - 6), log_lines.size()):
		var e: Dictionary = log_lines[i]
		recent.append(("%s：%s" % [e["speaker"], e["text"]]) if e["speaker"] != "" else "（%s）" % e["text"])
	if not recent.is_empty():
		lines.append("最近的劇情：\n" + "\n".join(recent))
	var lv: Dictionary = coding_mode.current_info()
	if not lv.is_empty():
		lines.append("主角正在解關卡「%s」：%s%s\n他目前寫的程式：\n%s" % [lv["title"], lv["goal"],
			"（已經過關）" if lv["passed"] else "", lv["code"]])
	elif explore_mode.visible:
		lines.append("主角正在房間裡找東西（探索模式），點到的東西會變成 list 的程式。")
	return "\n".join(lines)


## ESC（由 PauseMenu 轉過來）：打開／關閉合併後的設定面板
func toggle_settings() -> void:
	system_menu.toggle_settings()


func is_split() -> bool:
	return _split


## 同一章裡換小節：頂端一條小字（不切黑畫面）
func _section_banner(title: String, age: int) -> void:
	var pill := PanelContainer.new()
	pill.add_theme_stylebox_override("panel", UIKit.box(Color(0, 0, 0, 0.72), 8, Color.TRANSPARENT, 0, 14))
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := UIKit.label("%s　・　%d 歲" % [title, age], 28, Color.WHITE)
	pill.add_child(l)
	_montage_layer.add_child(pill)
	await get_tree().process_frame
	pill.position = Vector2((1920 - pill.size.x) / 2.0, 100)
	pill.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(pill, "modulate:a", 1.0, 0.8)
	t.tween_interval(3.5)
	t.tween_property(pill, "modulate:a", 0.0, 1.0)
	t.tween_callback(pill.queue_free)


## 派森在關卡／探索中說話：顯示在劇情區的對話框，也記進回顧
func _pyson_speak(text: String, mood: String) -> void:
	dialogue.show_status("派森", text)
	system_menu.add_backlog("派森", text)
	orb.set_mood(mood)
	orb.speak(true)
	get_tree().create_timer(1.2).timeout.connect(orb.speak.bind(false))


# ------------------------------------------------------------------
# 3.2.2 快轉演出 與 結尾
# ------------------------------------------------------------------

## @montage stop=倒數第 25 天 | 學校=school | 圖書館=library | 家裡=home | 咖啡廳=cafe
## 把上一關印出的每一行快速播過：背景依關鍵字切換、左上角日期快速倒數、遇到 ===== 停頓一下。
func montage(arg: String) -> void:
	hide_dialogue()
	code_card.hide_card()
	var stop := ""
	var places := {}
	for part in arg.split("|", false):
		var kv := part.split("=", false, 1)
		if kv.size() < 2:
			continue
		var k := kv[0].strip_edges()
		if k == "stop":
			stop = kv[1].strip_edges()
		else:
			places[k] = kv[1].strip_edges()

	var date := UIKit.label("", 64, Color.WHITE)
	date.position = Vector2(60, 40)
	date.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	date.add_theme_constant_override("outline_size", 10)
	_montage_layer.add_child(date)
	var caption := UIKit.label("", 30, Color.WHITE)
	caption.position = Vector2(160, 900)
	caption.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	caption.add_theme_constant_override("outline_size", 8)
	_montage_layer.add_child(caption)

	var rx := RegEx.new()
	rx.compile("倒數第 (\\d+) 天")
	var current := ""
	for line in str(GameState.get_value("last_output", "")).split("\n"):
		var m := rx.search(line)
		if m:
			date.text = "D-%s" % m.get_string(1)
		caption.text = line
		for k in places:
			if line.find(k) != -1 and places[k] != current:
				current = places[k]
				bg.show_bg(current, "", true)
		if line.find("=====") != -1:
			await get_tree().create_timer(2.0).timeout
		else:
			await get_tree().create_timer(0.14).timeout
		if stop != "" and line.find(stop) != -1:
			await get_tree().create_timer(2.5).timeout
			break
	date.queue_free()
	caption.queue_free()


## 結尾：畫面全白，浮現「hello python」，接著是工作人員名單。
func credits() -> void:
	chat.set_bar_visible(false)
	hide_dialogue()
	code_card.hide_card()
	portraits.hide_character("all")
	orb.visible = false
	await bg.show_bg("white")
	var hello := UIKit.label("hello python", 72, UIKit.INK)
	hello.add_theme_font_override("font", UIKit.mono_font())
	hello.position = Vector2(700, 470)
	hello.modulate.a = 0.0
	_montage_layer.add_child(hello)
	var t := create_tween()
	t.tween_property(hello, "modulate:a", 1.0, 2.0)
	t.tween_interval(2.0)
	t.tween_property(hello, "modulate:a", 0.0, 1.5)
	await t.finished

	var lines := ["《派森與我的一生》", "Program Life: Runtime Flashback", "", "劇本・企劃・程式・美術", "專題團隊",
		"", "特別感謝", "每一個陪你寫下第一行程式的人", "", "你的故事還沒結束。"]
	var col := VBoxContainer.new()
	col.position = Vector2(560, 1100)
	col.custom_minimum_size = Vector2(800, 0)
	for l in lines:
		var lbl := UIKit.label(l, 36, UIKit.INK)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.custom_minimum_size = Vector2(800, 56)
		col.add_child(lbl)
	_montage_layer.add_child(col)
	var roll := create_tween()
	roll.tween_property(col, "position:y", -700.0, 16.0)
	await roll.finished
	col.queue_free()
	hello.queue_free()
