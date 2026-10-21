# 5.4 回憶相簿　｜　30～65 歲　｜　class 類別、物件
# 時間軸：奶奶離開、成家、爸媽離開、Cindy 退休、自己退休。
# 【設計】這一段跨越三十多年，用「相片翻頁」一張一張帶過（@photo），每張相片角落標上年齡，
# 讓玩家清楚知道時間往前走了多少。
# 場景：文昌帝君廟 → 湖邊 → 病房 → Cindy 的歡送會 → 整理舊照片的房間。相簿頁面重用前面章節的 CG 縮圖。

# ---------- 32 歲：奶奶 ----------
@photo 32 歲
@bg temple
（三十二歲。奶奶在睡夢中走了，九十二歲，走得很安詳。）
（告別式結束後，你一個人走進那間文昌帝君廟。拜墊還是那個拜墊，香爐還是那個香爐，只是旁邊再也沒有那個穿花襯衫的身影。）
派森：你一歲的時候，她就是在這裡幫你擲筊的。
（你拿起筊杯，學著奶奶的樣子，在心裡說：奶奶，謝謝你。如果你過得很好，請給我一個聖杯。）
@flash gold
（筊杯落地，一正一反。）
派森：有時候信仰跟機率只有一步之隔。但這一次，我想相信信仰。

# ---------- 成家 ----------
@if gave_gift
@photo 22～45 歲
@bg lake_dawn
（二十二歲那年夏天，你們終於在湖邊看了那場約好的日出。三十一歲，你們結婚了。四十五歲，你們在湖邊買了一棟小房子，每天早上一起看日升，傍晚一起看日落。倖芳說，這比她夢想中的還要好。）
@else
@photo 29～34 歲
@bg lake_sunset
（二十九歲，你收到倖芳的喜帖，地點在一座湖邊。你真心為她高興，在婚禮上和翊丞喝得比誰都多。三十四歲，你也遇見了一個願意陪你吃一輩子培根蛋吐司的人。）
@endif

# ---------- 四十多歲：爸媽 ----------
@photo 40 多歲
@bg hospital
（四十多歲那幾年，爸爸和媽媽先後住進了醫院。最後一次去看媽媽時，她握著你的手，聲音很輕。）
@show 媽媽 right 老年
媽媽：早餐……要記得吃喔。
@hide all
（爸媽走了以後，你把爸爸每天傳來的血壓數字，一則一則存了下來。最後一則的後面，寫著：「你媽說你要多吃點」。）

# ---------- 55 歲：Cindy 退休 ----------
@photo 55 歲
@bg office
@cg farewell_party Cindy 的歡送會
（五十五歲，Cindy 退休，部門替她辦了歡送會。她拍拍你的肩膀說：「現在換你帶新人了，對他們兇一點，但要護著他們。」）
（那時的你，已經是部門的主管，而 Claire 還是坐在你隔壁，桌上還是堆滿零食。）

# ---------- 65 歲：退休 ----------
@photo 65 歲
@bg office_dusk
（六十五歲，你也退休了。歡送會上，Claire 送你一大袋零食，翊丞特地從新竹趕來，喝得比你還醉。）
@orb mood fading
（退休後，你發現派森的光偶爾會閃一下，像快沒電的燈泡。你問他怎麼了，他只說：「沒事，我也老了嘛。」）
@orb mood idle
@photo off

@bg photo_room
（有一天，你整理舊東西，翻出一大箱照片：溜滑梯、早餐店、便利商店、捷運站、奶奶的廟、宿舍、第一份薪水、Cindy 的歡送會……）
你：派森，我怕有一天我會忘記這些事。
派森：那我們把每一段回憶，都做成一個「物件」吧。每一段回憶都有一樣的格式：發生了什麼、幾歲、當時的心情。我們先寫一張「設計圖」，再照著設計圖做出一段一段的回憶。
系統：class 就是設計圖，用它做出來的東西叫做「物件」。__init__ 會在物件被做出來時執行，用 self. 把資料存進物件裡；寫在 class 裡的函式，叫做這個物件的「方法」。

@level ch5_4_album
title: 回憶相簿
goal: 用 Memory 這張設計圖，建立一段屬於你自己的回憶，加進 album，然後印出整本相簿。
tags: class Memory | Memory("發生了什麼", 幾歲, "心情") | album.append(...) | memory.recall()
hint: 在 album 的中括號裡加一行：Memory("你的回憶", 年齡, "心情"),
hint: 也可以在 album 建立之後寫 album.append(Memory("……", 30, "……"))。
starter:
```python
class Memory:
    def __init__(self, title, age, feeling):
        self.title = title
        self.age = age
        self.feeling = feeling

    def recall(self):
        print(f"{self.age} 歲那年，{self.title}，那時候的心情是「{self.feeling}」。")

album = [
    Memory("第一次自己算早餐錢", 5, "驕傲"),
    Memory("奶奶擲出三個聖杯", 18, "感動"),
    Memory("把第一份薪水分給爸媽", 23, "幸福"),
    Memory("Cindy 第一次說「做得好」", 23, "想哭"),
]
# 在這裡加入一段你自己的回憶


for memory in album:
    memory.recall()
```
check:
```python
assert "class Memory" in code, "要保留 Memory 這張設計圖。"
assert len(album) >= 5, "album 裡要多一段你自己的回憶。"
assert all(isinstance(m, Memory) for m in album), "album 裡的每一段都要是用 Memory(...) 做出來的物件。"
assert out.count("歲那年") >= len(album), "最後用 for 迴圈讓每一段回憶都 recall() 一次。"
mine = album[-1]
set_flag("my_memory", "%s 歲那年，%s" % (mine.age, mine.title))
```
solution:
```python
class Memory:
    def __init__(self, title, age, feeling):
        self.title = title
        self.age = age
        self.feeling = feeling

    def recall(self):
        print(f"{self.age} 歲那年，{self.title}，那時候的心情是「{self.feeling}」。")

album = [
    Memory("第一次自己算早餐錢", 5, "驕傲"),
    Memory("奶奶擲出三個聖杯", 18, "感動"),
]
album.append(Memory("在湖邊看日出", 30, "平靜"))
album.append(Memory("第一次帶新人", 35, "緊張"))
album.append(Memory("整理回憶相簿", 50, "溫暖"))
for memory in album:
    memory.recall()
```
success: 「{my_memory}」——也收進相簿了。就算哪天忘了，這些物件也會替你記得。
@end

派森：這樣，就算哪天你忘了，相簿也會替你記得。
成就：回憶收藏家
