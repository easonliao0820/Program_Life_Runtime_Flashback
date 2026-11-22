# 2.2 跑腿計算　｜　5 歲　｜　四則運算
# 時間軸：上小學前，跟媽媽去買早餐。
# 場景：家附近的早餐店，早晨。鏡頭從低角度看媽媽的背影，表現小孩的視角。

@bg living_room
@bgm childhood
（五歲那年夏天，再過幾個月你就要上小學了。）
派森：你長高了呢，真可愛。
你：你在捉弄我嗎？也是啦，從嬰兒變成幼兒總會有個成長期嘛。
派森：（AI 回應：回應玩家，並提到每個人或多或少都有被爸媽帶著認識世界的經歷。）
【備用台詞】派森：我是說真的。每個人小時候都是被爸媽牽著手，一點一點認識這個世界的，現在輪到你了。
@show 媽媽 left
媽媽：寶貝你長大了，就快要去上學了呢，所以媽媽今天要讓你練習去買早餐。
你：好～
系統：媽媽牽著你的手，帶著你出門。
@hide all
@cg holding_hands 媽媽牽著你的手，走在巷子裡的背影
（跟在高大背影後面的你覺得，慢慢長大其實也不錯。跟著爸媽，或許可以看見比家裡更大的世界。）

@bg breakfast_shop
@show 媽媽 left
（來到家附近的早餐店）
媽媽：去跟早餐店阿姨點你喜歡吃的吧。
@show 老闆娘 right

@choice food 想吃什麼呢？
- 培根蛋吐司　35 元 = 培根蛋吐司
- 火腿起司蛋餅　40 元 = 火腿起司蛋餅
- 鐵板麵　50 元 = 鐵板麵
@end
@choice drink 要喝什麼？
- 中冰奶　25 元 = 中冰奶
- 紅茶　20 元 = 紅茶
- 豆漿　20 元 = 豆漿
@end
@if food == "培根蛋吐司"
@set food_price = 35
@elif food == "火腿起司蛋餅"
@set food_price = 40
@else
@set food_price = 50
@endif
@if drink == "中冰奶"
@set drink_price = 25
@else
@set drink_price = 20
@endif

媽媽：原來你喜歡吃{food}啊。來，媽媽先示範怎麼算。
媽媽：媽媽的培根蛋吐司加中冰奶，可以這樣算：

```python
bacon_egg_toast = 35
iced_milk = 25
print(bacon_egg_toast + iced_milk)         # 60
print(100 - (bacon_egg_toast + iced_milk)) # 付 100 元，要找 40 元
```

媽媽：換你試試看吧，寶貝。
系統：Python 的加減乘除是 +、-、*、/。先算括號裡面，再算外面，跟數學課一樣。
派森：在日常生活中，對會寫程式的人來說，只要寫得出算式，就能得到答案。

系統：也可以先把算好的結果放進盒子，再印出來，程式比較好讀：

```python
toast = 35
milk = 25
total = toast + milk      # 先把總價放進盒子
change = 100 - total      # 再算找零
print(total)              # 60
print(change)             # 40
print(toast * 2)          # 買兩份：70
```

系統：+ 加、- 減、* 乘、/ 除。盒子裡的數字可以直接拿來算，算出來的結果也能再放進新的盒子。

@level ch2_2_breakfast
title: 算算早餐錢
goal: 算出早餐總共多少錢，以及付 100 元要找多少。
step: 在第一個 print() 的括號裡寫總價的算式：food 加 drink
step: 在第二個 print() 的括號裡寫找零的算式：100 減掉總價（記得加括號）
step: 只印數字，不要加文字，按執行
expect:
```text
（例如 35 元＋25 元：）
60
40
```
tags: {food}　{food_price} 元 | {drink}　{drink_price} 元 | 付 100 元
hint: 先把兩個價格放進盒子，再用 + 加起來。
hint: 找零就是 100 - (food + drink)，記得括號。
starter:
```python
food = <<food_price>>
drink = <<drink_price>>
print()   # ← 在括號裡寫算式：總共多少錢？
print()   # ← 在括號裡寫算式：付 100 元要找多少？
```
check:
```python
import ast
import copy
import contextlib
import io
import sys

expected_food = <<food_price>>
expected_drink = <<drink_price>>
expected_total = expected_food + expected_drink
expected_change = 100 - expected_total

# 先確認玩家沒有修改實際選餐的價格。
assert "food" in globals() and type(food) is int and food == expected_food, \
    "請保留你點的食物價格。"

assert "drink" in globals() and type(drink) is int and drink == expected_drink, \
    "請保留你點的飲料價格。"

# 確認本次答案的輸出正確。
actual_lines = [line.strip() for line in out.splitlines() if line.strip()]

assert len(actual_lines) == 2, \
    "請輸出兩行：第一行總價，第二行找零，只印整數，不加文字。"

assert actual_lines[0] == str(expected_total), \
    "第一行總價不正確，請把食物與飲料價格加起來。"

assert actual_lines[1] == str(expected_change), \
    "第二行找零不正確，請用100減掉總價。"

# 找到起始程式裡 food、drink 的第一次價格設定。
tree = ast.parse(code)
price_positions = {}

for index, statement in enumerate(tree.body):
    target = None

    if isinstance(statement, ast.Assign) and len(statement.targets) == 1:
        target = statement.targets[0]
    elif isinstance(statement, ast.AnnAssign):
        target = statement.target

    if isinstance(target, ast.Name):
        if target.id in ("food", "drink") and target.id not in price_positions:
            price_positions[target.id] = index

assert set(price_positions) == {"food", "drink"}, \
    "請保留起始程式中 food = 價格、drink = 價格這兩行，再於下方計算。"

def test_prices(food_value, drink_value):
    # 只替換測試用程式中的起始價格，不修改玩家的原始答案。
    test_tree = copy.deepcopy(tree)

    for name, value in (("food", food_value), ("drink", drink_value)):
        statement = test_tree.body[price_positions[name]]
        statement.value = ast.Constant(value=value)

    ast.fix_missing_locations(test_tree)
    compiled = compile(test_tree, "<breakfast-test>", "exec")

    # 每組測試使用新的變數環境。
    scope = {"__name__": "__main__"}
    captured = io.StringIO()
    steps = [0]

    def guard(frame, event, arg):
        if event == "line" and frame.f_code.co_filename == "<breakfast-test>":
            steps[0] += 1
            if steps[0] > 10000:
                raise RuntimeError("測試執行過久")
        return guard

    previous_trace = sys.gettrace()

    try:
        sys.settrace(guard)
        with contextlib.redirect_stdout(captured):
            exec(compiled, scope)
    except Exception:
        raise AssertionError(
            "你的原本金額正確，但換一組價格後程式無法完成。"
            "請使用 food 和 drink 計算總價，再用100減掉總價。"
        ) from None
    finally:
        sys.settrace(previous_trace)

    return [
        line.strip()
        for line in captured.getvalue().splitlines()
        if line.strip()
    ]

# 固定寫 print(60)、print(40)，無法通過不同價格的測試。
for test_food, test_drink in ((40, 20), (35, 20), (50, 25)):
    total = test_food + test_drink
    expected_lines = [str(total), str(100 - total)]

    assert test_prices(test_food, test_drink) == expected_lines, \
        "你算出的金額正確！但換一組價格後，程式沒有算出正確結果。" \
        "請不要直接印出固定答案；改用 food 和 drink 計算總價，再用100減掉總價。"
```
solution:
```python
food = <<food_price>>
drink = <<drink_price>>
print(food + drink)   # ← 在括號裡寫算式：總共多少錢？
print(100 - (food + drink))   # ← 在括號裡寫算式：付 100 元要找多少？
```
success: {food} {food_price} 元＋{drink} {drink_price} 元，算得剛剛好，找回來的零錢一塊都沒少！
@end

媽媽：真棒啊寶貝！以後買東西都要自己先算過一遍喔，這樣別人算錯的時候，才不會多付錢。
@hide all
@cg breakfast 你捧著早餐吃得很開心
（你接過阿姨遞來的早餐，一口一口吃著，為自己的成長感到開心，臉上露出幸福的表情。）
@show 媽媽 left
媽媽：你喜歡吃這個嗎？以後媽媽都幫你買這個，好不好？
（吃得津津有味的你，聽到以後都能吃到像今天一樣的美味，開心地點了點頭。）
派森：真是幸福。希望未來的某一天，你還會想起今天。
成就：第一次算數

# ---------- 過場：小學六年（6～12 歲） ----------
@bg living_room
（媽媽說到做到。小學六年，每天早上的餐桌上，都有一份培根蛋吐司和一杯中冰奶。）
（一年級，你在聯絡簿上寫錯了自己的名字；三年級，你在數學考卷上第一次拿到一百分，媽媽把考卷貼在冰箱上；六年級畢業典禮，爸爸在台下拍了兩百張照片，卻沒有一張是對焦的。）
派森：你發現了嗎？你現在算早餐錢，已經不用我提醒了。
（轉場 → 進入國中）
