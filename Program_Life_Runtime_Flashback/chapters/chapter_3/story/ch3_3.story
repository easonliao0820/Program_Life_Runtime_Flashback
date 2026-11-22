# 3.3 隨機保佑　｜　18 歲（高三）　｜　import random、while
# 場景：文昌帝君廟。主角是靈魂狀態，整個畫面降低彩度、邊緣微微發光；只有奶奶是彩色的。
# 擲筊時筊杯掉落的動畫要放慢，聖杯時發金光。

@bg desk
@bgm school
（不知不覺來到考前 25 天。你覺得頭暈目眩、全身發熱，怎麼樣都讀不下書，但還是想著無論如何都要把這一回考古題寫完。下一刻，你感覺全身失重，眼睛也不爭氣地閉上了。）
@transition
@bg temple
@bgm tension
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

系統：「連續」的寫法：成功就加 1，失敗就歸零，等到數字夠了，while 就停下來。

```python
import random
coin = ["正面", "反面"]
streak = 0
while streak < 2:                     # 還沒連續兩次就繼續丟
    if random.choice(coin) == "正面":
        streak += 1                   # 連續次數加 1
    else:
        streak = 0                    # 斷掉了，從 0 重新數
print("連續兩次正面！")
```

系統：streak += 1 是「加 1 再放回去」；streak = 0 是「歸零」。每丟一次，while 都會重新檢查 streak < 2 還成不成立。
系統：這關的程式跟上面丟硬幣的例子一模一樣，只是換成擲筊。程式幾乎都寫好了，你只要把兩個 pass 換掉：聖杯時加 1，其他結果歸零。
派森：pass 的意思是「這裡先什麼都不做」。如果不換掉，consecutive_holy 永遠是 0，奶奶就會一直擲下去喔。
@level ch3_3_divination
title: 奶奶的三個聖杯
goal: 讓奶奶一直擲筊，直到「連續」三個聖杯為止。程式幾乎都寫好了，只要把兩個 pass 換掉。
step: 在 if outcome == "聖杯": 底下，把 pass 換成 consecutive_holy += 1
step: 在 else: 底下，把 pass 換成 consecutive_holy = 0
step: 按執行，看看奶奶一共擲了幾次
expect:
```text
（擲筊是隨機的，每次都不一樣，例如：）
第 1 次：聖杯
第 2 次：笑杯
第 3 次：聖杯
第 4 次：聖杯
第 5 次：聖杯
奶奶一共擲了 5 次，終於連續三個聖杯！
```
tags: while consecutive_holy < 3 | 聖杯 → += 1 | 其他 → = 0
hint: 在 if outcome == "聖杯": 底下寫 consecutive_holy += 1。
hint: 在 else: 底下寫 consecutive_holy = 0，因為必須是「連續」三次，斷掉就要重新數。
hint: 只要改那兩個 pass，其他程式都不用動。
starter:
```python
import random

results = ["聖杯", "聖杯", "笑杯", "陰杯"]   # 聖杯的機率約 1/2
consecutive_holy = 0   # 連續幾個聖杯
total_attempts = 0     # 總共擲了幾次

while consecutive_holy < 3:
    outcome = random.choice(results)
    total_attempts += 1
    print(f"第 {total_attempts} 次：{outcome}")

    if outcome == "聖杯":
        pass  # ← 把 pass 換掉：聖杯時，連續次數加 1
    else:
        pass  # ← 把 pass 換掉：其他結果，連續次數歸零

    if total_attempts >= 200:   # 安全裝置：擲太多次就先停下來（不用改）
        break

print(f"奶奶一共擲了 {total_attempts} 次，終於連續三個聖杯！")
```
check:
```python
import ast
import builtins
import contextlib
import io
import re
import sys
import types
import random as validation_random

assert "results" in globals() and results == ["聖杯", "聖杯", "笑杯", "陰杯"], \
    "請保留兩個聖杯、一個笑杯與一個陰杯的清單。"

tree = ast.parse(code)
while_lines = {node.lineno for node in ast.walk(tree) if isinstance(node, ast.While)}
assert while_lines, "請保留 while 迴圈，讓奶奶一直擲到連續三個聖杯。"

# 先檢查玩家這一次實際擲出來的結果
assert "total_attempts" in globals() and type(total_attempts) is int and total_attempts >= 3, \
    "total_attempts 要記錄總共擲了幾次。"
actual = out.splitlines()
assert actual and actual[-1] == f"奶奶一共擲了 {total_attempts} 次，終於連續三個聖杯！", \
    "最後一行的總結要保留原本的寫法。"
assert len(actual) == total_attempts + 1, "每擲一次印一行，最後再印總結。"

streak = 0
for i, line in enumerate(actual[:-1], 1):
    match = re.fullmatch(r"第 (\d+) 次：(聖杯|笑杯|陰杯)", line)
    assert match and int(match.group(1)) == i, "擲筊的編號或結果格式不對，請保留原本的 print。"
    streak = streak + 1 if match.group(2) == "聖杯" else 0
    if i < total_attempts:
        assert streak < 3, "已經擲出連續三個聖杯，程式卻沒有停下來。聖杯時要寫 consecutive_holy += 1，while 才知道該停了。"
assert streak == 3, \
    "還沒有連續三個聖杯就停了。聖杯時 consecutive_holy += 1，其他結果要 consecutive_holy = 0。"

# 再用固定的擲筊結果重跑一次，確認「斷掉會歸零」
sequences = [
    ["聖杯", "聖杯", "聖杯"],
    ["聖杯", "聖杯", "笑杯", "聖杯", "聖杯", "聖杯"],
    ["聖杯", "陰杯", "聖杯", "聖杯", "聖杯"],
    ["笑杯", "陰杯", "聖杯", "聖杯", "聖杯"],
]
compiled_source = compile(tree, "<random-source-validation>", "exec")

for sequence in sequences:
    draws = []
    def controlled_choice(options):
        assert list(options) == ["聖杯", "聖杯", "笑杯", "陰杯"], "random.choice 要使用原本的筊杯清單。"
        assert len(draws) < len(sequence), \
            "連續三個聖杯之後應該停下來。遇到笑杯或陰杯時，記得把 consecutive_holy 歸零。"
        result = sequence[len(draws)]
        draws.append(result)
        return result

    controlled_random = types.ModuleType("random")
    controlled_random.__dict__.update(vars(validation_random))
    controlled_random.choice = controlled_choice
    original_import = builtins.__import__
    def controlled_import(name, globals=None, locals=None, fromlist=(), level=0):
        if name == "random":
            return controlled_random
        return original_import(name, globals, locals, fromlist, level)

    source_builtins = dict(vars(builtins))
    source_builtins["__import__"] = controlled_import
    scope = {"__builtins__": source_builtins, "__name__": "__main__"}
    captured = io.StringIO()
    steps = [0]
    def guard(frame, event, arg):
        if event == "line" and frame.f_code.co_filename == "<random-source-validation>":
            steps[0] += 1
            assert steps[0] <= 30000, "執行太久了，請檢查 while 能不能停下來。"
        return guard

    previous_trace = sys.gettrace()
    try:
        with contextlib.redirect_stdout(captured):
            sys.settrace(guard)
            exec(compiled_source, scope)
    finally:
        sys.settrace(previous_trace)

    assert draws == sequence, \
        "遇到笑杯或陰杯時，consecutive_holy 要歸零（= 0），這樣才是「連續」三個聖杯。"
    expected_lines = [f"第 {n} 次：{v}" for n, v in enumerate(sequence, 1)]
    expected_lines.append(f"奶奶一共擲了 {len(sequence)} 次，終於連續三個聖杯！")
    assert captured.getvalue().splitlines() == expected_lines, \
        "輸出要跟著實際擲出的結果改變，請保留原本的 print。"

set_flag("divination_attempts", total_attempts)
```
solution:
```python
import random

results = ["聖杯", "聖杯", "笑杯", "陰杯"]   # 聖杯的機率約 1/2
consecutive_holy = 0   # 連續幾個聖杯
total_attempts = 0     # 總共擲了幾次

while consecutive_holy < 3:
    outcome = random.choice(results)
    total_attempts += 1
    print(f"第 {total_attempts} 次：{outcome}")

    if outcome == "聖杯":
        consecutive_holy += 1  # ← 把 pass 換掉：聖杯時，連續次數加 1
    else:
        consecutive_holy = 0  # ← 把 pass 換掉：其他結果，連續次數歸零

    if total_attempts >= 200:   # 安全裝置：擲太多次就先停下來（不用改）
        break

print(f"奶奶一共擲了 {total_attempts} 次，終於連續三個聖杯！")
```
success: 聖杯、聖杯、聖杯！奶奶一共擲了 {divination_attempts} 次，while 一直等到連續三個聖杯才停下來。
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
