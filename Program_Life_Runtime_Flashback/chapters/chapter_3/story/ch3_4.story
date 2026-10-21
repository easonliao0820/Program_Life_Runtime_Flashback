# 3.4 學測當天　｜　18 歲（高三）　｜　雙層 for 迴圈、break、not in
# 場景：清晨的主角房間（探索模式），窗外天剛亮。

@bg my_room_dawn
（學測當天早上，你做著最後的行前檢查。）
派森：簡章規定的五樣東西，一樣都不能少。請你用程式幫自己做最後的檢查吧。

# 【關卡】required 清單不會直接顯示，只會提示「共有 5 樣」。
@explore ch3_4_bag
title: 學測當天・行前檢查
goal: 把要帶進考場的東西放進 my_bag。簡章上一共有 5 樣。
list: my_bag
hidden_count: 5
confirm: 檢查完畢
- 准考證
- 身分證
- 2B鉛筆
- 橡皮擦
- 手錶
- 水壺
- 手機
- 漫畫
@end

系統：for 迴圈裡面還可以再放一個 for 迴圈，叫做「雙層迴圈」。break 可以提早結束最內層的迴圈。

@level ch3_4_check
title: 簡章上的五樣東西
goal: 用雙層 for 迴圈檢查：外層拿出簡章上的每一樣，內層翻書包裡的每一樣，找到就 count += 1，然後 break。五樣都要帶齊！
tags: 外層：for req in required | 內層：for item in my_bag | 找到 → count += 1、break
hint: 把 pass 換成兩行：count += 1 和 break。
hint: 如果 count 不到 5，代表書包裡少了東西：用 my_bag.append("……") 補上。
starter:
```python
required = ["准考證", "身分證", "2B鉛筆", "橡皮擦", "手錶"]
<<explore_code>>
count = 0   # 用來計算帶對的物品數量

for req in required:          # 外層：拿出簡章上的每一樣
    for item in my_bag:       # 內層：翻書包裡的每一樣
        if item == req:       # 找到了
            pass              # 把這行換成 count += 1 和 break

if count == len(required):
    print("（你檢查了一下背包，簡章要求的五樣物品都帶齊了！）")
else:
    print(f"（好像還缺了點什麼……目前只帶了 {count}/{len(required)} 樣。）")
```
check:
```python
assert "break" in code, "找到之後用 break 停止翻書包，避免重複計算。"
assert count == len(required), "好像還缺了點什麼……目前只帶了 %d/5 樣。把缺的東西 append 進 my_bag 吧。" % count
```
solution:
```python
required = ["准考證", "身分證", "2B鉛筆", "橡皮擦", "手錶"]
my_bag = ["身分證", "2B鉛筆", "水壺", "准考證", "橡皮擦", "手錶"]
count = 0
for req in required:
    for item in my_bag:
        if item == req:
            count += 1
            break
if count == len(required):
    print("（你檢查了一下背包，簡章要求的五樣物品都帶齊了！）")
else:
    print(f"（好像還缺了點什麼……目前只帶了 {count}/{len(required)} 樣。）")
```
success: 准考證、身分證、2B鉛筆、橡皮擦、手錶，五樣都帶齊了。考場見！
@end

派森：外層用簡章、內層用書包，這樣就算你不小心放了兩支一樣的筆，也不會被算兩次。其實 Python 還有更簡單的寫法：

```python
required = ["准考證", "身分證", "2B鉛筆", "橡皮擦", "手錶"]
my_bag = ["身分證", "2B鉛筆", "水壺", "准考證", "橡皮擦"]
for req in required:
    if req not in my_bag:
        print(f"還缺：{req}")
```

你：出發！
（媽媽在門口塞給你一份培根蛋吐司，爸爸開車送你到考場。下車前，爸爸只說了一句：「盡力就好。」奶奶傳來一張照片：文昌帝君廟的香爐，配上三個愛心。）
成就：考場戰士
