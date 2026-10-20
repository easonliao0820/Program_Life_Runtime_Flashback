# 5.4 回憶相簿　｜　中年　｜　class 類別、物件
# 場景：Cindy 的歡送會（小 CG），以及整理舊照片的房間。相簿頁面重用前面章節的 CG 縮圖。

@bg lake_dawn
（日子一年一年過去。）
@if gave_gift
（你們終於在湖邊看了那場約好的日出。後來，你們在湖邊買了一棟小房子，每天早上一起看日升，傍晚一起看日落。倖芳說，這比她夢想中的還要好。）
@else
（你收到倖芳的喜帖，地點在一座湖邊。你真心為她高興，在婚禮上和翊丞喝得比誰都多。後來，你也遇見了一個願意陪你吃一輩子培根蛋吐司的人。）
@endif
@bg office
@cg farewell_party Cindy 的歡送會
（Cindy 退休那年，部門替她辦了歡送會。她拍拍你的肩膀說：「現在換你帶新人了，對他們兇一點，但要護著他們。」）
（那時的你，已經是部門的主管，而 Claire 還是坐在你隔壁，桌上還是堆滿零食。）
@bg photo_room
（有一天，你整理舊東西，翻出一大箱照片：溜滑梯、早餐店、捷運站、奶奶的廟、宿舍、第一份薪水、Cindy 的歡送會……）
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
    Memory("Cindy 第一次說「做得好」", 24, "想哭"),
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
@end

派森：這樣，就算哪天你忘了，相簿也會替你記得。
成就：回憶收藏家
