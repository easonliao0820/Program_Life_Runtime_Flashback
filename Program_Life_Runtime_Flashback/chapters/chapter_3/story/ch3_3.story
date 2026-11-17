# 3.3 隨機保佑　｜　18 歲（高三）　｜　import random、while
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

系統：這裡的函式外框已經準備好了。draw() 代表擲一次筊，你只需要完成兩個 pass：聖杯時加1，其他結果歸零。
@level ch3_3_divination
title: 奶奶的三個聖杯
goal: 完成 divine(draw) 函式，用 while 迴圈一直擲筊，直到連續三個聖杯。每次呼叫 draw() 取得結果；聖杯加1，其他歸零。逐次印出結果，最後回傳總次數。請保留既有輸出格式及函式外的總結。
tags: draw() 取得擲筊結果 | while | 聖杯 → +1，其他 → 歸零 | return 回傳次數
hint: 在 if outcome == "聖杯": 底下寫 consecutive_holy += 1。
hint: 在 else: 底下寫 consecutive_holy = 0，因為必須是「連續」三次。
hint: draw() 在遊玩時提供隨機結果，測試時提供固定結果。請不要在函式裡另外呼叫 random.choice()。
starter:
```python
import random

results = ["聖杯", "聖杯", "笑杯", "陰杯"]# 聖杯的機率約 1/2

def divine(draw):
    consecutive_holy = 0 # 紀錄連續聖杯的次數
    total_attempts = 0 # 紀錄總共擲了幾次

    while consecutive_holy < 3:
        outcome = draw()
        total_attempts += 1
        print(f"第 {total_attempts} 次：{outcome}")

        if outcome == "聖杯":
            pass  # 聖杯：連續次數加1
        else:
            pass  # 其他：連續次數歸零

    return total_attempts

total_attempts = divine(lambda: random.choice(results))
print(f"奶奶一共擲了 {total_attempts} 次，終於連續三個聖杯！")
```
check:
```python
import ast
import contextlib
import io
import re
import sys

assert "divine" in globals() and callable(divine), \
    "請保留 divine(draw) 函式。"

tree = ast.parse(code)
functions = [
    node for node in ast.walk(tree)
    if isinstance(node, ast.FunctionDef) and node.name == "divine"
]
assert functions and any(
    isinstance(node, ast.While)
    for node in ast.walk(functions[0])
), "請在 divine 裡使用 while 迴圈。"

# 確認題目的機率清單；實際來源改用下方完整重跑驗證，不限制lambda寫法。
assert "results" in globals() and results == ["聖杯", "聖杯", "笑杯", "陰杯"], \
    "請保留兩個聖杯、一個笑杯與一個陰杯的隨機清單。"

# 固定序列：確認失敗歸零，且成功後立即停止
cases = [
    (["聖杯", "聖杯", "聖杯"], 3),
    (["聖杯", "笑杯", "聖杯", "聖杯", "聖杯"], 5),
    (["聖杯", "聖杯", "陰杯", "聖杯", "聖杯", "聖杯"], 6),
    (["聖杯", "聖杯", "笑杯", "聖杯", "聖杯", "聖杯"], 6),
    (["笑杯", "陰杯", "聖杯", "聖杯", "聖杯"], 5),
    (["聖杯", "聖杯", "聖杯", "聖杯"], 3),
]

for sequence, expected in cases:
    calls = [0]
    steps = [0]

    def fake_draw():
        assert calls[0] < expected, \
            "已連續三個聖杯，應立即停止。"
        value = sequence[calls[0]]
        calls[0] += 1
        return value

    # 避免函式測試因錯誤迴圈一直執行
    def guard(frame, event, arg):
        if event == "line":
            steps[0] += 1
            assert steps[0] <= 10000, \
                "測試執行過久，請檢查 while 是否能結束。"
        return guard

    previous_trace = sys.gettrace()
    captured = io.StringIO()

    try:
        with contextlib.redirect_stdout(captured):
            sys.settrace(guard)
            answer = divine(fake_draw)
    finally:
        sys.settrace(previous_trace)

    assert type(answer) is int and answer == expected, \
        "次數錯誤：遇到笑杯或陰杯，連續次數必須歸零。"

    assert calls[0] == expected, \
        "每次擲筊都必須呼叫 draw()。"

    expected_output = [
        f"第 {i} 次：{value}"
        for i, value in enumerate(sequence[:expected], 1)
    ]
    assert captured.getvalue().splitlines() == expected_output, \
        "請逐次印出正確的擲筊編號與結果。"

# 核對玩家實際那次隨機遊玩的輸出
assert "total_attempts" in globals(), \
    "請保存實際擲筊總次數。"
assert type(total_attempts) is int and total_attempts >= 3, \
    "total_attempts 必須是至少3次的整數。"

actual = out.splitlines()
assert len(actual) == total_attempts + 1, \
    "每次擲筊印一行，最後再印總結。"

streak = 0

for i, line in enumerate(actual[:-1], 1):
    match = re.fullmatch(r"第 (\d+) 次：(聖杯|笑杯|陰杯)", line)
    assert match and int(match.group(1)) == i, \
        "擲筊編號或結果格式不正確。"

    streak = streak + 1 if match.group(2) == "聖杯" else 0

    if i < total_attempts:
        assert streak < 3, \
            "連續三個聖杯後應停止，不能繼續擲。"

assert streak == 3, "最後必須是連續三個聖杯。"

assert actual[-1] == (
    f"奶奶一共擲了 {total_attempts} 次，終於連續三個聖杯！"
), "總結次數必須與實際紀錄一致。"



# 重跑玩家完整程式，驗證正式入口實際使用random.choice的結果。
# 只替換這次驗證環境的random模組，不修改遊戲或Python全域模組。
import builtins
import types
import random as validation_random

source_sequences = [
    ["聖杯", "聖杯", "聖杯"],
    ["聖杯", "聖杯", "笑杯", "聖杯", "聖杯", "聖杯"],
    ["聖杯", "陰杯", "聖杯", "聖杯", "聖杯"],
    ["笑杯", "陰杯", "聖杯", "聖杯", "聖杯"],
]
compiled_source = compile(tree, "<random-source-validation>", "exec")
while_lines = {node.lineno for node in ast.walk(functions[0]) if isinstance(node, ast.While)}

for source_sequence in source_sequences:
    source_draws = []
    def controlled_choice(options):
        assert list(options) == ["聖杯", "聖杯", "笑杯", "陰杯"], "random.choice必須使用原本的筊杯清單。"
        assert len(source_draws) < len(source_sequence), "連續三次聖杯後應立即停止，不能再呼叫random.choice。"
        result = source_sequence[len(source_draws)]
        source_draws.append(result)
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
    source_scope = {"__builtins__": source_builtins, "__name__": "__main__"}
    source_output = io.StringIO()
    source_steps = [0]
    source_executed = set()
    def source_guard(frame, event, arg):
        if event == "line" and frame.f_code.co_filename == "<random-source-validation>":
            source_steps[0] += 1
            assert source_steps[0] <= 30000, "隨機來源驗證執行過久，請檢查迴圈是否能停止。"
            source_executed.add(frame.f_lineno)
        return source_guard

    previous_trace = sys.gettrace()
    try:
        with contextlib.redirect_stdout(source_output):
            sys.settrace(source_guard)
            exec(compiled_source, source_scope)
    finally:
        sys.settrace(previous_trace)

    assert source_draws == source_sequence, "正式擲筊必須真的使用random.choice取得每次結果，不能固定回傳聖杯或把隨機呼叫放在不執行的位置。"
    assert bool(while_lines & source_executed), "正式擲筊時，divine裡的while必須真的執行。"
    expected_attempts = len(source_sequence)
    assert type(source_scope.get("total_attempts")) is int and source_scope["total_attempts"] == expected_attempts, "實際總次數必須隨擲筊結果改變，不能固定是3。"
    expected_source_lines = [f"第 {index} 次：{value}" for index, value in enumerate(source_sequence, 1)]
    expected_source_lines.append(f"奶奶一共擲了 {expected_attempts} 次，終於連續三個聖杯！")
    assert source_output.getvalue().splitlines() == expected_source_lines, "輸出必須反映實際隨機來源的每次結果與總次數。"

set_flag("divination_attempts", total_attempts)
```
solution:
```python
import random

results = ["聖杯", "聖杯", "笑杯", "陰杯"]

def divine(draw):
    consecutive_holy = 0
    total_attempts = 0

    while consecutive_holy < 3:
        outcome = draw()
        total_attempts += 1
        print(f"第 {total_attempts} 次：{outcome}")

        if outcome == "聖杯":
            consecutive_holy += 1
        else:
            consecutive_holy = 0

    return total_attempts

total_attempts = divine(lambda: random.choice(results))
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
