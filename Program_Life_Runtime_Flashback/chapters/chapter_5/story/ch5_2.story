# 5.2 Cindy 的報表　｜　23 歲　｜　函式＋字典＋迴圈、sum()、不把數字寫死
# 場景：辦公室傍晚（夕陽從百葉窗照進來）、會議室。被退件時畫面色調變冷、時鐘滴答聲；
# 改好後，會議室大螢幕投影出報表。Cindy 說「做得好」時，畫面短暫停格，背景音樂換成溫暖的版本。

@bg office_dusk
（進公司半年後，你已經慢慢習慣了這裡的節奏。某個星期五下午五點，大家正準備下班，Cindy 走到你們座位旁。）
@show Cindy right
Cindy：Claire、{userName}，星期一早上九點的會議，我要三個區的季度業績報表：每一區的總業績、月平均，還有本季冠軍是哪一區。
@hide Cindy
@show Claire left
Claire：（小聲）完了，上次我用 Excel 一格一格算，算了三個小時……
你：我來試試看用程式算吧。
派森：這種「每一區都要做一樣的事」的工作，最適合寫成函式，再搭配字典和迴圈。
系統：sum() 可以把 list 裡的數字全部加起來，len() 可以算出有幾個月。把重複的步驟寫成函式，每一區只要呼叫一次就好。
（你很快寫好了第一版，月平均直接除以 3，因為一季有三個月。）

```python
sales = {
    "北區": [120, 98, 143],
    "中區": [88, 102],        # 中區這一季第二個月才成立
    "南區": [130, 125, 160],
}

def summarize(months):
    total = sum(months)
    average = round(total / 3, 1)   # 第一版：直接除以 3
    return total, average

for region, months in sales.items():
    total, average = summarize(months)
    print(f"{region}：總業績 {total} 萬，月平均 {average} 萬")
```

@hide all
@bg meeting_room
@tone work
@sfx clock_tick
（星期一早上，會議開始前十分鐘，Cindy 把你叫進會議室。）
@show Cindy right
Cindy：中區的月平均為什麼只有 63.3 萬？他們兩個月都有接近一百萬的業績。
你：……
Cindy：中區是這一季第二個月才成立的，只有兩個月的資料。你把「3」寫死在程式裡了。
Cindy：面試的時候，你跟我說「數字寫死的話，資料一變，程式就錯了」。還記得嗎？
（你的臉一下子紅到耳根。）
Cindy：還有十分鐘，改好再拿進來。
@hide all
@bg office
@show Claire left
（你回到座位，手指一直發抖。Claire 默默把椅子滑了過來。）
Claire：沒事的，每個人第一年都會被 Cindy 退件，我第一次被退了四次。來，我幫你對數字，你改程式。
派森：不要把會變的數字寫死。有幾個月，就讓程式自己用 len() 去數。

@level ch5_2_report
title: Cindy 的報表（還有十分鐘）
goal: 找出第一版程式的錯誤，修正 summarize()；再加上找出「本季冠軍」的程式，印出冠軍和它的總業績。
tags: 北區 120・98・143 | 中區 88・102 | 南區 130・125・160 | 不要把 3 寫死
hint: 月平均應該除以 len(months)，而不是 3。
hint: 用 best_region、best_total 兩個盒子記住目前最高的一區：if total > best_total 就更新。
starter:
```python
sales = {
    "北區": [120, 98, 143],
    "中區": [88, 102],        # 中區這一季第二個月才成立
    "南區": [130, 125, 160],
}

def summarize(months):
    total = sum(months)
    average = round(total / 3, 1)   # 第一版：直接除以 3
    return total, average

best_region = ""
best_total = 0
for region, months in sales.items():
    total, average = summarize(months)
    print(f"{region}：總業績 {total} 萬，月平均 {average} 萬")
    # 找出本季冠軍

print(f"本季冠軍：{best_region}，總業績 {best_total} 萬")
```
check:
```python
import ast
import contextlib
import io
import sys

def _call_checked(fn, *args):
    capture = io.StringIO()
    ticks = [0]
    def guard(frame, event, arg):
        if event == "line":
            ticks[0] += 1
            assert ticks[0] <= 30000, "驗證執行過久，請檢查迴圈是否能停止。"
        return guard
    previous = sys.gettrace()
    try:
        with contextlib.redirect_stdout(capture):
            sys.settrace(guard)
            value = fn(*args)
    finally:
        sys.settrace(previous)
    return value, capture.getvalue()

import copy
import builtins
import types

def _rerun(replacements=None, sequence=None):
    replacements = replacements or {}
    parsed = ast.parse(code)
    scope = {"__builtins__": dict(vars(builtins)), "__name__": "__main__"}
    for key, value in replacements.items():
        scope["_validation_" + key] = copy.deepcopy(value)
        found = False
        for statement in parsed.body:
            if isinstance(statement, ast.Assign) and any(
                isinstance(target, ast.Name) and target.id == key
                for target in statement.targets
            ):
                statement.value = ast.Name(id="_validation_" + key, ctx=ast.Load())
                found = True
                break
        assert found, "請保留題目原本的 " + key + " 初始化資料。"
    draws = []
    if sequence is not None:
        def draw(options):
            assert list(options) == ["聖杯", "聖杯", "笑杯", "陰杯"], "請保留原本的筊杯機率清單。"
            assert len(draws) < len(sequence), "連續三個聖杯後應停止，不能再擲。"
            value = sequence[len(draws)]
            draws.append(value)
            return value
        real_import = builtins.__import__
        def test_import(name, globals=None, locals=None, fromlist=(), level=0):
            if name == "random":
                return types.SimpleNamespace(choice=draw)
            return real_import(name, globals, locals, fromlist, level)
        scope["__builtins__"]["__import__"] = test_import
    compiled = compile(ast.fix_missing_locations(parsed), "<validation>", "exec")
    _, captured = _call_checked(lambda: exec(compiled, scope))
    return scope, captured, draws

expected_sales = {"北區":[120,98,143],"中區":[88,102],"南區":[130,125,160]}
assert "sales" in globals() and sales == expected_sales, "請保留題目三區原始業績。"
assert "summarize" in globals() and callable(summarize), "請保留 summarize(months)。"
for months in [[88,102],[1,2,3,4],[9],[10,20,30],[0,0],[2,3,8]]:
    answer, _ = _call_checked(summarize, months.copy())
    assert isinstance(answer, (tuple,list)) and tuple(answer) == (sum(months), round(sum(months)/len(months),1)), "summarize 必須正確回傳總和與平均，不能寫死月數或答案。"
import re
from decimal import Decimal
from collections import Counter

def validate_report(text, data):
    actual = [line.strip() for line in text.splitlines() if line.strip()]
    assert len(actual) == len(data) + 1, "請印出每區報表，最後一行印出冠軍。"
    number = r"[+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?"
    row_pattern = r"(.+?)\s*[:：]\s*總業績\s*(" + number + r")\s*萬[，,]\s*月平均\s*(" + number + r")\s*萬"
    records = []
    for line in actual[:-1]:
        match = re.fullmatch(row_pattern, line)
        assert match, "請保留每區的名稱、總業績與月平均標示。"
        records.append((match.group(1).strip(), Decimal(match.group(2)), Decimal(match.group(3))))
    expected = [(region, Decimal(str(sum(values))), Decimal(str(round(sum(values)/len(values),1)))) for region, values in data.items()]
    assert Counter(records) == Counter(expected), "各區總和及平均必須正確，不能漏區或重複；95與95.0都可以。"
    champion = re.fullmatch(r"本季冠軍\s*[:：]\s*(.+?)[，,]\s*總業績\s*(" + number + r")\s*萬", actual[-1])
    assert champion, "最後一行請印出本季冠軍與總業績。"
    winner = max(data, key=lambda region: sum(data[region]))
    assert champion.group(1).strip() == winner and Decimal(champion.group(2)) == Decimal(str(sum(data[winner]))), "冠軍名稱或總業績不正確。"
    return winner

winner = validate_report(out, expected_sales)
assert best_region == winner and best_total == sum(expected_sales[winner]), "冠軍變數不正確。"
for data in [{"北區":[500,10],"中區":[10,20],"南區":[1]}, {"北區":[1],"中區":[700,200,1,3],"南區":[9,10]}]:
    scope, captured, _ = _rerun({"sales":data})
    winner = validate_report(captured, data)
    assert scope.get("best_region") == winner and scope.get("best_total") == sum(data[winner]), "請真正比較各區業績找出冠軍，不能寫死南區。"
```
solution:
```python
sales = {"北區": [120, 98, 143], "中區": [88, 102], "南區": [130, 125, 160]}

def summarize(months):
    total = sum(months)
    average = round(total / len(months), 1)
    return total, average

best_region = ""
best_total = 0
for region, months in sales.items():
    total, average = summarize(months)
    print(f"{region}：總業績 {total} 萬，月平均 {average} 萬")
    if total > best_total:
        best_total = total
        best_region = region
print(f"本季冠軍：{best_region}，總業績 {best_total} 萬")
```
success: 中區月平均 95.0 萬，本季冠軍是南區 415 萬。不再把 3 寫死，十分鐘內趕上了！
@end

@hide all
@bg meeting_room
（會議上，Cindy 把報表投影在大螢幕上，簡單報告完，全場沒有人提出問題。）
@bg office
@show Cindy right
（散會後，Cindy 經過你的座位，停了一下。）
@bgm warm
@flash white
Cindy：報表做得好。下次把這支程式整理成說明文件，教給整個部門。
Cindy：還有，被退件不丟臉，同樣的錯犯第二次才丟臉。你今天改得很快。
@hide Cindy
@cg claire_thumbs_up Claire 在桌子底下對你比了一個讚
@show Claire left
（她走遠之後，Claire 在桌子底下對你比了一個讚。）
Claire：Cindy 一年說不到三次「做得好」，今天中午你請客。
派森：你看，被退件的那十分鐘，學到的比順利的一整個月還多。
成就：第一次被說「做得好」
