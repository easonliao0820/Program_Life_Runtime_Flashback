# 3.3 隨機保佑　｜　高中　｜　import random、while
# 場景：文昌帝君廟。主角是靈魂狀態，整個畫面降低彩度、邊緣微微發光；只有奶奶是彩色的。
# 擲筊時筊杯掉落的動畫要放慢，聖杯時發金光。

@bg desk
（不知不覺來到考前 25 天。你覺得頭暈目眩、全身發熱，怎麼樣都讀不下書，但還是想著無論如何都要把這一回考古題寫完。下一刻，你感覺全身失重，眼睛也不爭氣地閉上了。）
@transition
@bg temple
@saturation 0.2
你：我是死了嗎？
派森：應該沒有。不過，這是你第一次離我這麼近。
（你看了看四周，驚覺自己在一間廟裡。）
你：我在哪裡？
派森：這是你家附近的文昌帝君廟。你昏倒之後，爸媽急急忙忙把你送去醫院，但我發現你的意識不在那裡。
派森：正當我在想你會去哪裡時，看到平常不是在菜市場、就是在家看劇的奶奶，背著側背包出門了。我好奇地跟上來，就發現你也在這裡。
你：我奶奶呢？
派森：在那裡啊。
@show 奶奶 center
（你看見一位留著小捲髮、穿著花襯衫的長輩，跪在拜墊上虔誠地拜向文昌帝君，嘴裡默念著什麼。）
奶奶：文昌帝君請保佑我們家 {userName}，身體健康，考上他想讀的學校。拜託拜託，如果答應的話，請給個聖杯。
（當神明答應時，會連續給三個聖杯。）
系統：import random 可以借來 Python 內建的「隨機」工具箱。random.choice() 會從 list 裡隨機挑一個出來。
系統：while 迴圈會在條件成立的期間一直重複，直到條件不成立才停下。跟 for 不同，你不需要事先知道要重複幾次。
派森：真實的筊杯，兩個杯子一正一反就是聖杯，所以聖杯出現的機率大約是一半，笑杯和陰杯各約四分之一。我們可以在 list 裡放兩個 "聖杯" 來模擬。

@level ch3_3_divination
title: 奶奶的三個聖杯
goal: 用 while 迴圈一直擲筊，直到「連續」出現三個聖杯為止，最後印出奶奶一共擲了幾次。
tags: import random | random.choice(results) | while consecutive_holy < 3 | 聖杯 → +1，其他 → 歸零
hint: 在迴圈最後加上：if outcome == "聖杯": consecutive_holy += 1，else: consecutive_holy = 0。
hint: 如果 consecutive_holy 一直不變，while 就永遠停不下來喔。
starter:
```python
import random
results = ["聖杯", "聖杯", "笑杯", "陰杯"]   # 聖杯的機率約 1/2
consecutive_holy = 0   # 紀錄連續聖杯的次數
total_attempts = 0     # 紀錄總共擲了幾次

while consecutive_holy < 3:
    total_attempts += 1
    outcome = random.choice(results)
    print(f"第 {total_attempts} 次：{outcome}")
    # 是聖杯就 +1，不是就歸零

print(f"奶奶一共擲了 {total_attempts} 次，終於連續三個聖杯！")
```
check:
```python
assert "import random" in code, "要先 import random 借來隨機工具箱。"
assert "while" in code, "這關要用 while 迴圈一直擲到成功為止。"
assert consecutive_holy >= 3, "要連續三個聖杯才算數。"
assert "連續三個聖杯" in out, "最後印出奶奶一共擲了幾次。"
set_flag("divination_attempts", total_attempts)
```
solution:
```python
import random
results = ["聖杯", "聖杯", "笑杯", "陰杯"]
consecutive_holy = 0
total_attempts = 0
while consecutive_holy < 3:
    total_attempts += 1
    outcome = random.choice(results)
    print(f"第 {total_attempts} 次：{outcome}")
    if outcome == "聖杯":
        consecutive_holy += 1
    else:
        consecutive_holy = 0
print(f"奶奶一共擲了 {total_attempts} 次，終於連續三個聖杯！")
```
success: 聖杯、聖杯、聖杯！
@end

# 【設計】每次執行的結果都不一樣。平均大約要擲 14 次，才會出現連續三個聖杯。
@flash gold
@cg grandma_prayer 奶奶跪在拜墊上雙手合十的背影，香煙裊裊
（奶奶終於擲出連續三個聖杯，雙手合十，笑得眼睛都瞇成一條線。）
派森：有時候，信仰跟機率只有一步之隔。你怎麼看呢？
你：或許這只是機率造成的結果，但我相信，奶奶每次擲筊之前的祈願，一定是真的。
你：派森，帶我回去吧。我想繼續讀書了。
派森：好。
@hide all
@saturation 1
@transition
@bg hospital
@show 奶奶 right
（你在醫院的病床上醒來，奶奶握著你的手。倒數繼續。）
