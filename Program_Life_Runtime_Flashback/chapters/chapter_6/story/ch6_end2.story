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
assert isinstance(habit, Memory), "habit 要用 Memory(...) 做出來。"
assert "歲那年" in out, "記得讓 habit.recall()。"
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
r = say_love("派森")
assert isinstance(r, str) and "派森" in r and "我愛你" in r, "say_love(\"派森\") 要回傳「派森，謝謝你，我愛你。」"
assert out.count("我愛你") >= 5, "對每一個人都說一次。"
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
assert consecutive_holy >= 3, "要連續三個聖杯。"
assert "奶奶，謝謝你" in out
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
assert my_answer == 72 and "沒問題" in out, "(25 + 60) 打 85 折，再 round()。"
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
