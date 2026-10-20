# 結局一：天下沒有不散的宴席（錯誤較多 → 回憶遊戲由簡單到困難，陪玩家把概念慢慢複習一遍）
# 場景：夕陽下的湖邊長椅。有禮物時倖芳靠在你的肩上；沒禮物時只有你一個人，旁邊放著一杯中冰奶。
# 派森往上飄，進入回憶模式。結局一 CG：派森化成光點，融進老年的你的胸口。

@bg lake_sunset
@orb mood fading
（坐在湖邊長椅上的老人，聽著湖畔與樹林帶來的協奏曲。或許他在思考些什麼，又或許在回憶些什麼。這一生犯過許多錯，但生死有命，人終有悲歡離合。）
@if gave_gift
@show 倖芳 left 老年
（倖芳靠在你的肩上睡著了，手裡還握著你們第一次看日出時拍的照片。）
@else
（這是倖芳很久以前跟你說過的那種湖。你一直記得。長椅上，放著一杯中冰奶。）
@endif
派森：我的朋友，這一生我跟你經歷了太多，有轟轟烈烈的感情，也有失敗後的重挫。不管如何，我們的時候到了。天下沒有不散的宴席。
（你抬頭，平靜地望著這個陪了你一輩子的朋友，眼淚漸漸流了下來，不想分別的情緒充滿了整個腦袋。）
你：別走……
@hide all
@orb pos 960 260
（派森漸漸往上飄，破碎的回憶畫面一片片浮在空中。你突然有個念頭：如果把回憶補完整，是不是就能留下他了？）

@memory 把回憶接起來（由簡單到困難）
cg: 剛出生的第一眼
cg: 愛的盒子
cg: 朋友們
cg: 那 100 天
cg: 人生地圖

@level end1_voice
title: 回憶一：第一聲
goal: 讓派森聽見你的聲音：用 print() 說出「別走，派森」。
starter:
```python
print()
```
check:
```python
assert "別走" in out, "對派森說：別走，派森。"
```
solution:
```python
print("別走，派森")
```
@end

@level end1_love
title: 回憶二：愛的盒子
goal: 找回剛出生時存下的那個變數：建立 love，再用 f-string 印出「我愛我的○○」。
starter:
```python
love = 
print(f"我愛我的{love}")
```
check:
```python
assert "love" in globals() and isinstance(love, str) and love.strip(), "love 盒子裡要放一串文字。"
assert ("我愛我的" + love) in out, "要印出「我愛我的" + love + "」。"
```
solution:
```python
love = "爸爸媽媽"
print(f"我愛我的{love}")
```
@end

@level end1_friends
title: 回憶三：朋友清單
goal: 朋友清單裡少了一個人。用 append() 把派森找回來，再印出朋友的人數和名單。
starter:
```python
friends = ["爸爸", "媽媽", "奶奶", "倖芳", "翊丞", "Cindy", "Claire"]

print(f"我的朋友有 {len(friends)} 個：{friends}")
```
check:
```python
assert "派森" in friends, "派森還不在朋友清單裡。"
assert "append" in code, "用 append() 把派森加進去。"
assert "8 個" in out, "印出來的朋友人數要包含派森。"
```
solution:
```python
friends = ["爸爸", "媽媽", "奶奶", "倖芳", "翊丞", "Cindy", "Claire"]
friends.append("派森")
print(f"我的朋友有 {len(friends)} 個：{friends}")
```
@end

@level end1_days
title: 回憶四：那 100 天
goal: 用迴圈和 if，找出倒數時每一個「撐過一段」的日子（可以被 25 整除的那幾天）。
starter:
```python
for day in range(100, 0, -1):
    if :
        print(f"倒數第 {day} 天，我還在。")
```
check:
```python
got = [l for l in lines if "我還在" in l]
assert len(got) == 4, "應該要剛好印出 4 天（100、75、50、25）。"
```
solution:
```python
for day in range(100, 0, -1):
    if day % 25 == 0:
        print(f"倒數第 {day} 天，我還在。")
```
@end

@level end1_places
title: 回憶五：人生地圖
goal: 用字典的 .items() 查出每段回憶發生在哪裡，一行印一段：「事件 → 地點」。
starter:
```python
places = {"出生": "醫院", "第一次算數": "早餐店", "遇見倖芳": "捷運站", "奶奶的祈禱": "文昌帝君廟", "第一次被說做得好": "Cindy 的會議室"}

```
check:
```python
got = [l for l in lines if "→" in l]
assert len(got) == len(places), "每一段回憶都要印出來。"
assert "出生 → 醫院" in out, "格式是「事件 → 地點」。"
```
solution:
```python
places = {"出生": "醫院", "第一次算數": "早餐店", "遇見倖芳": "捷運站", "奶奶的祈禱": "文昌帝君廟", "第一次被說做得好": "Cindy 的會議室"}
for event, place in places.items():
    print(f"{event} → {place}")
```
@end
@end

（結束了，你成功把回憶接了起來。）
你：別走，我最好的朋友。或許沒有人見證，也沒有人見過你的模樣，但在我的記憶裡，你是存在的。我希望你可以一直跟我在一起。
派森：我一直都跟你在一起。就算再也看不見我，我也會一直跟你在一起。
@orb fade 0
@cg ending1 派森化成光點，融進老年的你的胸口
（派森漸漸化成點點亮光，融進你的身體裡。）
系統：相處了一輩子，Python 早已融入你的腦海。
系統：或許在不同的未來，你會有不同的結局。
成就：了解 Python
@credits
