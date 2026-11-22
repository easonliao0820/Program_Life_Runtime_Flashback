# 結局一：天下沒有不散的宴席（錯誤較多 → 回憶遊戲由簡單到困難，陪玩家把概念慢慢複習一遍）
# 場景：夕陽下的湖邊長椅。有禮物時倖芳靠在你的肩上；沒禮物時只有你一個人，旁邊放著一杯中冰奶。
# 派森往上飄，進入回憶模式。結局一 CG：派森化成光點，融進老年的你的胸口。

@bg lake_sunset
@bgm farewell
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
goal: 用 print() 說出「別走，派森」。
intro: 還記得第一章學的 print() 嗎？
step: 把「別走，派森」放進引號
step: 再放進 print( ) 的括號裡，按執行
expect:
```text
別走，派森
```
tags: print("……")
hint: 文字要用英文半形的引號包起來，再放進 print( ) 裡。
hint: 寫法：print("別走，派森")
lesson: 派森：……還記得嗎？我們最早學的那一句。
lesson: 系統：print() 會把括號裡的東西印出來；文字要用英文半形的引號包起來。
lesson: @example
lesson: 系統：所以要說「別走，派森」，就把這句話放進引號，再放進 print( ) 的括號裡。
example:
```python
print("你好")          # 印出：你好
print("今天天氣很好")   # 印出：今天天氣很好
```
starter:
```python
print()   # ← 在括號裡說出：別走，派森
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
print("別走，派森")   # ← 在括號裡說出：別走，派森
```
success: 「別走，派森」——你的聲音，派森聽見了。
@end

@level end1_love
title: 回憶二：愛的盒子
goal: 建立 love 盒子，印出「我愛我的○○」。
intro: 變數就是貼了名字的盒子。
step: 在 love = 後面放進你愛的人，記得加引號
step: 第二行不用改，按執行
expect:
```text
（例如 love = "爸爸媽媽"：）
我愛我的爸爸媽媽
```
tags: love = "文字" | f-string
hint: 文字要加引號，例如 "爸爸媽媽"。
hint: 寫法：love = "爸爸媽媽"
lesson: 系統：變數是貼了名字的盒子：名字 = 值。放文字時要加引號。
lesson: 系統：f-string 是在引號前面加一個 f，大括號裡寫變數的名字，印出來時就會換成盒子裡的東西。
lesson: @example
lesson: 系統：這關只要在 love = 後面放進你愛的人（記得加引號），第二行不用改。
example:
```python
food = "布丁"
print(f"我喜歡{food}")   # 我喜歡布丁
```
starter:
```python
love =    # ← 在這裡放進你愛的人（文字要加引號）
print(f"我愛我的{love}")
```
check:
```python
assert "love" in globals() and isinstance(love, str) and love.strip(), "love 盒子裡要放一串文字。"
assert ("我愛我的" + love) in out, "要印出「我愛我的" + love + "」。"
```
solution:
```python
love = "爸爸媽媽"    # ← 在這裡放進你愛的人（文字要加引號）
print(f"我愛我的{love}")
```
success: 愛的盒子找回來了：{last_output}
@end

@level end1_friends
title: 回憶三：朋友清單
goal: 用 append() 把派森加回朋友清單。
intro: list 加東西用 append()。
step: 在中間空白那一行，用 append() 把 "派森" 加進 friends
step: 執行，人數會從 7 變成 8
expect:
```text
我的朋友有 8 個：['爸爸', '媽媽', '奶奶', '倖芳', '翊丞', 'Claire', 'Cindy', '派森']
```
tags: friends.append("派森") | len(friends)
hint: 要寫在 friends 建立之後、print 之前。
hint: 寫法：friends.append("派森")
lesson: 系統：list 用中括號裝很多東西。append() 會把東西加到最後面，len() 會算出有幾樣。
lesson: @example
lesson: 系統：這關要在朋友清單建立之後、print 之前，用 append() 把 "派森" 加回去。人數會從 7 變成 8。
example:
```python
fruits = ["蘋果", "香蕉"]
fruits.append("葡萄")         # 加到最後面
print(len(fruits), fruits)    # 3 ['蘋果', '香蕉', '葡萄']
```
starter:
```python
friends = ["爸爸", "媽媽", "奶奶", "倖芳", "翊丞", "Claire", "Cindy"]
# ← 在這裡把派森加回朋友清單
print(f"我的朋友有 {len(friends)} 個：{friends}")
```
check:
```python
import ast
from collections import Counter
expected_friends = ["爸爸","媽媽","奶奶","倖芳","翊丞","Claire","Cindy","派森"]
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
friends = ["爸爸", "媽媽", "奶奶", "倖芳", "翊丞", "Claire", "Cindy"]
# ← 在這裡把派森加回朋友清單
friends.append("派森")
print(f"我的朋友有 {len(friends)} 個：{friends}")
```
success: 朋友清單又是 8 個人了，派森也在裡面。
@end

@level end1_days
title: 回憶四：那 100 天
goal: 找出倒數時每一個「撐過一段」的日子（可以被 25 整除的那幾天）。
intro: 「可以被 25 整除」就是除以 25 的餘數是 0。
step: 在 if 和冒號中間，寫出「day 可以被 25 整除」的條件
step: 執行，會印出 100、75、50、25 四天
expect:
```text
倒數第 100 天，我還在。
倒數第 75 天，我還在。
倒數第 50 天，我還在。
倒數第 25 天，我還在。
```
tags: range(100, 0, -1) | day % 25 == 0
hint: % 是取餘數：day % 25 就是 day 除以 25 的餘數。
hint: 條件寫法：day % 25 == 0
lesson: 系統：range(100, 0, -1) 會從 100 開始，每次減 1，數到 1 為止。
lesson: 系統：% 是取餘數。day % 25 是 day 除以 25 剩下多少；剩 0 就代表剛好整除。
lesson: @example
lesson: 系統：if 後面、冒號前面，要寫的是「條件」。條件成立，底下那行才會執行。
example:
```python
for n in range(10, 0, -1):
    if n % 5 == 0:      # n 可以被 5 整除
        print(n)
# 印出：10、5
```
starter:
```python
for day in range(100, 0, -1):
    if :   # ← 在 if 和冒號中間寫條件：day 可以被 25 整除
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
    if day % 25 == 0:   # ← 在 if 和冒號中間寫條件：day 可以被 25 整除
        print(f"倒數第 {day} 天，我還在。")
```
success: 倒數 100、75、50、25 天——那 100 天，你一直都在。
@end

@level end1_places
title: 回憶五：人生地圖
goal: 用 .items() 一行印出一段回憶，和它發生的地方。
intro: .items() 可以一次拿出字典的鍵和值。
step: 在空白處寫 for，用 .items() 一次拿出事件 event 和地點 place
step: 在 for 裡面（往內縮）用 print 印出「事件 -> 地點」
expect:
```text
出生 -> 醫院
第一次算數 -> 早餐店
遇見倖芳 -> 捷運站
奶奶的祈禱 -> 文昌帝君廟
第一次被說做得好 -> Claire 的會議室
```
tags: for event, place in places.items() | ->（減號＋大於）
hint: 第一行：for event, place in places.items():
hint: 第二行往內縮，用 f-string 印出：大括號放 event、中間是 -> 、再一個大括號放 place。-> 是「減號」加「大於」兩個符號。
lesson: 系統：字典的 .items() 會一次拿出每一筆的「鍵」和「值」，for 後面用兩個名字接住。
lesson: @example
lesson: 系統：for 那一行最後要有冒號，底下的 print 要往內縮四格。這關請用 event 接事件、place 接地點，印成「事件 -> 地點」。
example:
```python
price = {"吐司": 35, "奶茶": 25}
for food, money in price.items():
    print(f"{food} -> {money}")
# 吐司 -> 35
# 奶茶 -> 25
```
starter:
```python
places = {"出生": "醫院", "第一次算數": "早餐店", "遇見倖芳": "捷運站", "奶奶的祈禱": "文昌帝君廟", "第一次被說做得好": "Claire 的會議室"}
# ← 在這裡寫 for 迴圈，一行印出一段「事件 -> 地點」
```
check:
```python
import ast
from collections import Counter
expected_places = {"出生":"醫院","第一次算數":"早餐店","遇見倖芳":"捷運站","奶奶的祈禱":"文昌帝君廟","第一次被說做得好":"Claire 的會議室"}
assert "places" in globals() and isinstance(places,dict) and places == expected_places, "請保留完整的人生地圖，不能刪除或改動地點。"
expected = [f"{event} -> {place}" for event,place in expected_places.items()]
assert Counter(x.strip() for x in lines if x.strip()) == Counter(expected), "請印出每筆正確事件及地點，不可漏項、重複或印錯地點；順序可以不同。"
assert any(isinstance(n,ast.For) and any(
           isinstance(call,ast.Call) and isinstance(call.func,ast.Attribute)
           and call.func.attr == "items" and isinstance(call.func.value,ast.Name)
           and call.func.value.id == "places" for call in ast.walk(n.iter))
           for n in ast.walk(ast.parse(code))), "請用 places.items() 逐筆查出事件與地點。"
```
solution:
```python
places = {"出生": "醫院", "第一次算數": "早餐店", "遇見倖芳": "捷運站", "奶奶的祈禱": "文昌帝君廟", "第一次被說做得好": "Claire 的會議室"}
# ← 在這裡寫 for 迴圈，一行印出一段「事件 -> 地點」
for event, place in places.items():
    print(f"{event} -> {place}")
```
success: 從醫院、早餐店、捷運站，一路到 Claire 的會議室，人生地圖接起來了。
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
