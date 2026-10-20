# 2.1 記憶變數　｜　嬰兒　｜　變數、int / float / str、f-string
# 場景：家裡客廳，午後陽光。探索模式中，回憶盒子是發光的小木盒。

@bg living_room
派森：你來到這裡也有一段時間了吧？還習慣嗎？

@level ch2_1_feeling
title: 說說你的感想
goal: 用 print("") 說出你現在的感想。
tags: print("……")
hint: 把感想寫在引號裡面，例如 print("這裡好溫暖")。
starter:
```python
print("")
```
check:
```python
assert out.strip() != "", "在引號裡寫下你的感想吧。"
```
solution:
```python
print("這裡好溫暖")
```
@end

派森：（AI 回應：回應玩家的感想「{last_output}」，並提到爸媽這段時間給予的愛。）
【備用台詞】派森：看得出來，你被照顧得很好。半夜哭的時候，你爸媽總是搶著起床，對吧？
你：小時候的記憶總是美好的。我還記得在遊樂場跟爸媽玩溜滑梯、跟他們在電視前面看卡通；還有一起去廟裡的時候，兩個明明想賺大錢的人，許願時卻只為我許下「身體健康、開心長大」。
你：錢明明那麼難賺，他們還是願意為我買下喜歡的玩具。他們明明為我做了這麼多，為什麼我第一個想起的，卻都是他們兇我、生氣時的樣子呢？
派森：這跟人的天性有關。幾百萬年前，人遇到可怕的東西很可能就會死，比如老虎、蛇、蜜蜂。如果不把這些恐懼牢牢記住，下一個遭殃的可能就是自己。
派森：所以人遇到害怕的事情，有的僵住、有的咆哮、有的逃跑，但永遠不會忘記。
你：可是我真的好想把爸媽現在的愛存下來。以後會遇到的事情越來越多，記憶只會越來越淡。派森，求你教我怎麼記下他們的樣子吧。
派森：那你很適合把愛存在「變數」裡面呢。
系統：變數就像一個盒子，你可以替盒子取名字，再把想存放的東西放進去。之後只要叫盒子的名字，就能拿出裡面的東西。
派森：例如 love = "爸爸媽媽"，代表我做了一個叫 love 的盒子，裡面放進了 "爸爸媽媽" 這串文字。

```python
love = "爸爸媽媽"
print("我愛我的" + love)
print(f"我愛我的{love}")
```

派森：第二行是用 + 把兩串文字接起來；第三行在引號前面加上 f，就能把盒子直接放進 { } 裡，這叫做 f-string。兩種寫法印出來都一樣。

@level ch2_1_love
title: 愛的盒子
goal: 建立 love 變數，放進一串文字，再用 print 印出「我愛我的○○」。
tags: love = "……" | print(f"我愛我的{love}")
hint: 第一行寫 love = "爸爸媽媽"，引號裡也可以換成你想放進去的人。
hint: 第二行的 f 要放在引號前面，盒子的名字放進 { } 裡。
starter:
```python
love = 
print(f"我愛我的{love}")
```
check:
```python
assert "love" in globals(), "要先建立一個叫 love 的盒子。"
assert isinstance(love, str) and love.strip() != "", "love 盒子裡要放進一串用引號包起來的文字。"
assert ("我愛我的" + love) in out, "要印出「我愛我的" + love + "」喔。"
```
solution:
```python
love = "爸爸媽媽"
print(f"我愛我的{love}")
```
success: 這份愛，現在被好好地存起來了。
@end

（你在家裡四處走動，發現了好多發著微光的小木盒——那是你的「回憶盒子」。）
@explore ch2_1_boxes
title: 家裡的回憶盒子
goal: 點開每一個發光的回憶盒子，把回憶放進正確的變數。
require_all: true
confirm: 都找到了！
- 媽媽的年齡 => mom_age = 30 | 媽媽今年 30 歲。沒有小數點的數字是 int（整數）。
- 你出生多久了 => my_age = 1.5 | 你出生一年半了。有小數點的數字是 float（浮點數）。
- 你的名字 => my_name = "{userName}" | 用引號包起來的文字是 str（字串）。
- 溜滑梯 => slide = "和爸媽玩溜滑梯" | 遊樂場的午後，爸爸在下面張開雙手接住你。
- 看卡通 => cartoon = "在電視前面看卡通" | 一家三口擠在沙發上。
- 廟裡許願 => wish = "身體健康、開心長大" | 他們只為你許了這個願。
@end

派森：盒子裡裝的東西有不同的「種類」。沒有小數點的數字是 int，有小數點的是 float，用引號包起來的文字是 str。用 type() 就能看出盒子裡裝的是哪一種。

@level ch2_1_types
title: 盒子裡裝的是什麼？
goal: 剛剛打開的回憶盒子都變成了程式。用 type() 印出 mom_age、my_age、my_name 各是哪一種資料。
tags: int 整數 | float 浮點數 | str 字串
hint: 每一行寫 print(type(盒子的名字))。
starter:
```python
<<explore_code>>

print(type(mom_age))
print(type(my_age))
```
check:
```python
for t in ["int", "float", "str"]:
    assert "<class '%s'>" % t in out, "三個盒子的種類都要印出來，還少了 %s。" % t
```
solution:
```python
mom_age = 30
my_age = 1.5
my_name = "小艾"
print(type(mom_age))
print(type(my_age))
print(type(my_name))
```
@end

成就：第一個變數
