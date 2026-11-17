# 結局一：天下沒有不散的宴席（錯誤較多 → 回憶遊戲由簡單到困難，陪玩家把概念慢慢複習一遍）
# 場景：夕陽下的湖邊長椅。有禮物時倖芳靠在你的肩上；沒禮物時只有你一個人，旁邊放著一杯中冰奶。
# 派森往上飄，進入回憶模式。結局一 CG：派森化成光點，融進老年的你的胸口。

@bg lake_sunset
@orb mood fading
（那天傍晚。）
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
import ast
import re
assert re.fullmatch(r"別走[，,、\s]*派森[！!。．.]*", out.strip()), "請對派森說完整的「別走，派森」，不要加否定或其他語句。"
assert any(isinstance(n,ast.Call) and isinstance(n.func,ast.Name) and n.func.id == "print" for n in ast.walk(ast.parse(code))), "請使用 print() 說出這句話。"
```
solution:
```python
print("別走，派森")
```
success: 「別走，派森」——你的聲音，派森聽見了。
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
success: 愛的盒子找回來了：{last_output}
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
import ast
from collections import Counter
expected_friends = ["爸爸","媽媽","奶奶","倖芳","翊丞","Cindy","Claire","派森"]
assert "friends" in globals() and isinstance(friends,list) and all(isinstance(name,str) for name in friends) and Counter(friends) == Counter(expected_friends), "請保留原本七位朋友並加入派森，不能重複或漏人；順序可以不同。"
tree = ast.parse(code)
assert any(isinstance(n,ast.Call) and isinstance(n.func,ast.Attribute)
           and isinstance(n.func.value,ast.Name) and n.func.value.id == "friends"
           and n.func.attr == "append" and len(n.args)==1

           for n in ast.walk(tree)), "請使用 friends 的 append 方法加入派森，註解不算。"
match = out.strip().partition("：")
assert match[0] == "我的朋友有 8 個" and match[1], "請印出實際人數及完整名單。"
try:
    actual_friends = ast.literal_eval(match[2])
except (ValueError,SyntaxError):
    raise AssertionError("請沿用原本輸出格式，印出完整朋友清單。")
assert isinstance(actual_friends, list) and actual_friends == friends, "輸出的朋友名單必須與實際清單一致。"
```
solution:
```python
friends = ["爸爸", "媽媽", "奶奶", "倖芳", "翊丞", "Cindy", "Claire"]
friends.append("派森")
print(f"我的朋友有 {len(friends)} 個：{friends}")
```
success: 朋友清單又是 8 個人了，派森也在裡面。
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
import ast
expected = [f"倒數第 {day} 天，我還在。" for day in [100,75,50,25]]
assert [x.strip() for x in lines if x.strip()] == expected, "請依序只印出第100、75、50、25天，不可重複、漏掉或改成其他日期。"
tree = ast.parse(code)
assert any(isinstance(n,ast.For) and any(isinstance(child,ast.If) for child in ast.walk(n)) for n in ast.walk(tree)), "請在 for 迴圈中使用 if 判斷。"
```
solution:
```python
for day in range(100, 0, -1):
    if day % 25 == 0:
        print(f"倒數第 {day} 天，我還在。")
```
success: 倒數 100、75、50、25 天——那 100 天，你一直都在。
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
import ast
from collections import Counter
expected_places = {"出生":"醫院","第一次算數":"早餐店","遇見倖芳":"捷運站","奶奶的祈禱":"文昌帝君廟","第一次被說做得好":"Cindy 的會議室"}
assert "places" in globals() and isinstance(places,dict) and places == expected_places, "請保留完整的人生地圖，不能刪除或改動地點。"
expected = [f"{event} → {place}" for event,place in expected_places.items()]
assert Counter(x.strip() for x in lines if x.strip()) == Counter(expected), "請印出每筆正確事件及地點，不可漏項、重複或印錯地點；順序可以不同。"
assert any(isinstance(n,ast.For) and any(
           isinstance(call,ast.Call) and isinstance(call.func,ast.Attribute)
           and call.func.attr == "items" and isinstance(call.func.value,ast.Name)
           and call.func.value.id == "places" for call in ast.walk(n.iter))
           for n in ast.walk(ast.parse(code))), "請用 places.items() 逐筆查出事件與地點。"
```
solution:
```python
places = {"出生": "醫院", "第一次算數": "早餐店", "遇見倖芳": "捷運站", "奶奶的祈禱": "文昌帝君廟", "第一次被說做得好": "Cindy 的會議室"}
for event, place in places.items():
    print(f"{event} → {place}")
```
success: 從醫院、早餐店、捷運站，一路到 Cindy 的會議室，人生地圖接起來了。
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
