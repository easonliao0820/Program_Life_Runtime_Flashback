# 5.1 第一份薪水　｜　22 歲　｜　def 函式、參數、return
# 場景：公司辦公室（開放式座位），Claire 的桌上堆滿零食。存摺特寫。之後回到家裡的餐桌。

@bg office
（報到第一天。你穿著新買的襯衫，站在業務分析部的門口，緊張得手心冒汗。）
（會議室的門打開，一位穿著深色西裝外套、手裡拿著平板的女人走了出來。）
@show Cindy right
（是面試你的那個人。）
Cindy：又見面了，{userName}。我是 Cindy，你的主管。我們這裡步調很快，有問題就問，但同一個問題，不要讓我聽到第二次。
你：好、好的！
@hide Cindy
（她點了點頭，踩著高跟鞋走回會議室，留下你愣在原地。）
……：別被嚇到啦，她只是講話比較直。
@show Claire left
（隔壁座位探出一顆頭，桌上堆滿了零食。）
Claire：我是 Claire，比你早來兩年，就坐你隔壁。有什麼不懂的先問我，問到我也不會為止。來，歡迎禮。
（她遞給你一包餅乾。）
你：謝謝……我以為第一天會更可怕。
派森：看來你遇到了一個好同事。
（一個月後，第一次領薪水的那天，你盯著存摺上的數字看了很久。）
你：派森，為什麼我拿到的錢，跟面試時說的不一樣？
Claire：（湊過來看）喔，這是扣了勞保跟健保啦，每個新人第一個月都會問。
派森：她說得對，要扣掉勞保和健保的自付額。每個月都要算一次，不如我們把它寫成一個「函式」吧。
系統：函式就像一台機器，用 def 建立。你把材料（參數）放進去，它會照著裡面的步驟處理，再用 return 把結果交還給你。寫好一次，之後隨時都能重複使用。

```python
def calc_take_home(salary):
    insurance = round(salary * 0.04)   # 勞健保自付額（遊戲中簡化為約 4%）
    return salary - insurance

pay = calc_take_home(32000)
print(f"實際拿到：{pay} 元")
```

Claire：第一份薪水耶，記得請我喝飲料喔。
派森：那第一份薪水，你想怎麼用？
你：我想先存一些，自己留一些，然後……分一些給爸媽。

@level ch5_1_budget
title: 第一份薪水
goal: 修改 split_budget() 裡的比例，決定第一份薪水要怎麼分：給爸媽、存起來、自己用。三份加起來要剛好等於實際拿到的錢。
tags: 月薪 32000 元 | 勞健保約 4% | def split_budget(money) | return family, saving, me
hint: 只要改 0.3 這兩個數字就好，例如給爸媽 0.2、存起來 0.4。
hint: me 用 money 減掉另外兩份，這樣三份加起來一定剛好。
starter:
```python
def calc_take_home(salary):
    insurance = round(salary * 0.04)
    return salary - insurance

def split_budget(money):
    family = round(money * 0.3)    # 給爸媽
    saving = round(money * 0.3)    # 存起來
    me = money - family - saving   # 留給自己
    return family, saving, me

pay = calc_take_home(32000)
family, saving, me = split_budget(pay)
print(f"實際拿到：{pay} 元")
print(f"給爸媽 {family} 元，存起來 {saving} 元，自己用 {me} 元")
```
check:
```python
assert "def split_budget" in code and "return" in code, "要用 def 寫出 split_budget()，最後用 return 把結果交回來。"
f, s, m = split_budget(30720)
assert f + s + m == 30720, "三份加起來要剛好等於拿到的錢。"
assert f >= 0 and s >= 0 and m >= 0, "每一份都不能是負的喔。"
assert f > 0, "記得分一些給爸媽。"
set_flag("family_share", family)
```
solution:
```python
def calc_take_home(salary):
    insurance = round(salary * 0.04)
    return salary - insurance

def split_budget(money):
    family = round(money * 0.3)
    saving = round(money * 0.3)
    me = money - family - saving
    return family, saving, me

pay = calc_take_home(32000)
family, saving, me = split_budget(pay)
print(f"給爸媽 {family} 元，存起來 {saving} 元，自己用 {me} 元")
```
success: 給爸媽 {family_share} 元。函式寫好一次，以後每個月發薪水都能直接用。
@end

@hide all
@bg parents_home
@show 媽媽 left
（週末，你回家吃飯。你把 {family_share} 元的紅包塞給媽媽，她推了好幾次才收下，轉身走進房間時，你看到她偷偷擦了一下眼睛。）
@hide all
@bg breakfast_shop
（隔天早上，你早起去了那家早餐店。阿姨老了許多，但一眼就認出你。）
你：阿姨，一份培根蛋吐司、一杯中冰奶，外帶。
@bg parents_home
@show 媽媽 left
（你把早餐放在餐桌上，媽媽愣了一下。）
你：媽，以前都是你買給我吃，以後換我買給你。
@cg mom_breakfast 媽媽收到早餐時的表情
成就：第一份薪水
