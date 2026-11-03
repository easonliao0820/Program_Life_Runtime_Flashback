# 結局二：你的故事還沒結束（完成度高 → 回憶遊戲由困難到簡單，最後一題回到人生的第一行程式）
# 場景：清晨的湖邊，有禮物時倖芳推著你的輪椅；沒禮物時是病房床頭的回憶相簿。
# 回憶修復完成後，你變成半透明的靈魂，與派森面對面。
# 結局二 CG：你第一次擁抱派森，整個人化成光點，被派森的光吸收。

@if gave_gift
@bg lake_dawn
@else
@bg hospital
@endif
@orb mood fading
（那天之後，你的記憶開始一點一點流失。又過了幾年，你漸漸忘記了你的朋友、你的愛人、你的故事。身邊的家人一次又一次提起從前的回憶，一次又一次訴說他們對你的愛，但你已經什麼都想不起來了。）
@if gave_gift
@show 倖芳 left 老年
倖芳：你看，日出喔。
（倖芳每天早上還是會推著你的輪椅到湖邊。）
@else
（你的家人把那本「回憶相簿」印了出來，放在你的床頭。）
@endif
派森：我的朋友，你真的都忘記了嗎？我們一起經歷了那麼多事，也一起寫出了那麼多程式。或許，未來都因為我們而改變了。
（突然，派森感覺到你的生命氣息正在減弱。你的腦袋裡飄出許多這一生的記憶碎片。）
派森：只要把這些記憶補回來，你就會想起來了，對吧，我的朋友。
@hide all

@memory 把記憶補回來（由困難到簡單）
cg: 每天早上的培根蛋吐司
cg: 說給每個人聽的愛
cg: 奶奶的三個聖杯
cg: 國中的那天早上
cg: Hello, python!

@level end2_habit
title: 回憶一：找回你的習慣
goal: 用 Memory 設計圖，重新做出你一輩子的習慣，並讓它 recall()。
starter:
```python
class Memory:
    def __init__(self, title, age, feeling):
        self.title = title
        self.age = age
        self.feeling = feeling

    def recall(self):
        print(f"{self.age} 歲那年，{self.title}，那時候的心情是「{self.feeling}」。")

habit = 
habit.recall()
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

assert "Memory" in globals() and isinstance(Memory, type), "請保留 Memory 類別。"
def _memory_text(memory):
    assert isinstance(memory, Memory), "每段回憶必須是 Memory 物件。"
    assert isinstance(getattr(memory,"title",None), str) and memory.title.strip(), "回憶標題不能空白。"
    assert type(getattr(memory,"age",None)) in (int, float) and memory.age >= 0, "回憶年齡請填非負數字。"
    assert isinstance(getattr(memory,"feeling",None), str) and memory.feeling.strip(), "請填入回憶的心情。"
    assert callable(getattr(memory,"recall",None)), "Memory 必須有可呼叫的 recall()。"
    expected = f"{memory.age} 歲那年，{memory.title}，那時候的心情是「{memory.feeling}」。"
    _, captured = _call_checked(memory.recall)
    assert captured.strip() == expected, "recall() 印出的內容必須與物件欄位一致。"
    return expected
# 也測試新物件，避免 recall() 寫死某一段回憶。
probe = Memory("測試一段新的回憶", 42, "安心")
_memory_text(probe)
assert "habit" in globals(), "請用 Memory 建立 habit。"
expected = _memory_text(habit)
assert out.strip() == expected, "請印出 habit 的完整回憶，不是只印「歲那年」。"
assert any(isinstance(n,ast.Call) and isinstance(n.func,ast.Attribute)
           and isinstance(n.func.value,ast.Name) and n.func.value.id == "habit"
           and n.func.attr == "recall" for n in ast.walk(ast.parse(code))), "請呼叫 habit.recall()。"
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

habit = Memory("每天早上買一份培根蛋吐司", 5, "幸福")
habit.recall()
```
success: 每天早上一份培根蛋吐司——你一輩子的習慣，回來了。
@end

@level end2_love
title: 回憶二：愛的函式
goal: 寫一個函式 say_love(name)，不管輸入誰的名字，都會回傳「○○，謝謝你，我愛你。」，再對每個人說一次。
starter:
```python
def say_love(name):
    return 

for person in ["爸爸", "媽媽", "奶奶", "倖芳", "翊丞"]:
    print(say_love(person))
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

assert "say_love" in globals() and callable(say_love), "請保留 say_love(name) 函式。"
for name in ["派森","媽媽","測試朋友","Claire"]:
    answer, captured = _call_checked(say_love,name)
    assert answer == f"{name}，謝謝你，我愛你。", "函式必須依傳入姓名回傳完整感謝句，不能寫死派森。"
    assert captured == "", "say_love 請回傳字串，交由外面的 print 印出。"
people = ["爸爸","媽媽","奶奶","倖芳","翊丞"]
assert [x.strip() for x in lines if x.strip()] == [f"{name}，謝謝你，我愛你。" for name in people], "請依原本清單對五個不同的人各說一次，不能重複同一句湊數。"
```
solution:
```python
def say_love(name):
    return f"{name}，謝謝你，我愛你。"

for person in ["爸爸", "媽媽", "奶奶", "倖芳", "翊丞"]:
    print(say_love(person))
```
success: 爸爸、媽媽、奶奶、倖芳、翊丞……每個人都聽到你說「我愛你」了。
@end

@level end2_divination
title: 回憶三：奶奶的筊杯
goal: 重現奶奶為你擲出的三個聖杯：用 while 一直擲，直到連續三個聖杯。
starter:
```python
import random
results = ["聖杯", "聖杯", "笑杯", "陰杯"]
consecutive_holy = 0
while consecutive_holy < 3:
    if random.choice(results) == "聖杯":
        
    else:
        
print("三個聖杯。奶奶，謝謝你。")
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

assert "consecutive_holy" in globals() and type(consecutive_holy) is int and consecutive_holy == 3, "必須連續三個聖杯才停止。"
assert out.strip() == "三個聖杯。奶奶，謝謝你。", "請保留原本完整的感謝句。"
tree = ast.parse(code)
assert any(isinstance(n,ast.While) for n in ast.walk(tree)), "請使用 while 迴圈。"
for sequence in [["聖杯"]*3,["聖杯","聖杯","笑杯","聖杯","聖杯","聖杯"],["聖杯","陰杯","聖杯","聖杯","聖杯"],["笑杯","陰杯","聖杯","聖杯","聖杯"]]:
    scope,captured,draws = _rerun(sequence=sequence)
    assert draws == sequence, "遇到非聖杯要歸零，直到連續三個聖杯才停止；不可直接設定計數器。"
    assert scope.get("consecutive_holy") == 3, "結束時應恰好連續三個聖杯。"
    assert captured.strip() == "三個聖杯。奶奶，謝謝你。", "完成後請印出原本完整的感謝句。"
```
solution:
```python
import random
results = ["聖杯", "聖杯", "笑杯", "陰杯"]
consecutive_holy = 0
while consecutive_holy < 3:
    if random.choice(results) == "聖杯":
        consecutive_holy += 1
    else:
        consecutive_holy = 0
print("三個聖杯。奶奶，謝謝你。")
```
success: 三個聖杯。奶奶，謝謝你。
@end

@level end2_check
title: 回憶四：對帳
goal: 想起國中那天早上，你第一次自己判斷「對」與「錯」：豆漿 25 元＋草莓吐司 60 元，打 85 折，店員收 72 元。
starter:
```python
my_answer = 
if my_answer == 72:
    print("沒問題，總共 72 元。")
```
check:
```python
assert "my_answer" in globals() and type(my_answer) is int and my_answer == 72, "請算(25+60)打85折，round()後應為整數72。"
assert out.strip() == "沒問題，總共 72 元。", "店員算對了，請依原本格式印出「沒問題，總共 72 元。」，不要加否定句。"
```
solution:
```python
my_answer = round((25 + 60) * 0.85)
if my_answer == 72:
    print("沒問題，總共 72 元。")
```
success: 72 元，沒問題。國中那天早上，你第一次自己判斷了對與錯。
@end

@level end2_hello
title: 回憶五：第一句話
goal: 回到一切的起點。編輯器裡已經寫好了你人生的第一行程式。這一次，把 World 改成 python，跟陪了你一輩子的朋友打聲招呼。
intro: 還記得嗎？你來到這個世界時，第一句話是跟「世界」打招呼。
tags: print("Hello, World!") | World → python
hint: 只要把引號裡的 World 換成 python 就好。
starter:
```python
print("Hello, World!")
```
check:
```python
said = "".join(ch for ch in out.lower() if ch.isalnum())
assert said == "hellopython", "把 World 換成 python，跟派森打聲招呼吧。"
```
solution:
```python
print("Hello, python!")
```
success: Hello, python. ——我一直都在。
@end
@end

（結束了，派森成功把回憶接了起來。靈魂狀態的你漂浮在空中，與派森對視。）
@saturation 0.6
你：hello python。
派森：你終究還是要離我而去嗎？
你：人的壽命，不過是近乎無限的時間裡的一個點而已。請不要為我難過。
派森：你在這段時間和我一起完成的事，是別人比不上的。
你：是嗎？能在最後聽到這句話，我真的很開心。
@cg ending2 你第一次擁抱派森，整個人化成光點，被派森的光吸收
（眼睛不自覺地流下充滿感情的淚水。你第一次擁抱了這個陪你走過一生的朋友，然後化成點點光芒，融進了 Python 裡。）
@flash gold
派森：我會帶著你，繼續向未來的「希望」們訴說你的故事。或許在未來的某一天，我又能見到你。
系統：在你完美的表現下，你留下來的程式，或許會成為下一個人對未來的啟發。繼續往前吧，你的故事還沒結束，未來見。
系統：又或許在不同的未來，你會有不同的結局。
@saturation 1
成就：成為 Python
@credits
