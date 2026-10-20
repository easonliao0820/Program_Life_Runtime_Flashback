# 5.3 爸媽的血壓　｜　出社會　｜　input()、int()、try / except
# 場景：爸媽家（比第二章更舊一點，牆上多了你的照片）；手機畫面顯示爸爸每天傳來的數字。

@bg office
（又過了幾年，你發現爸媽真的老了。爸爸的白頭髮越來越多，醫生要他每天量血壓，記錄下來回診時帶給醫生看。）
（爸爸回診那天，你硬著頭皮去跟 Cindy 請假，手上還有一份報表沒做完。）
@show Cindy right
Cindy：家人的事優先，報表我先幫你看。去吧。
@hide Cindy
@show Claire left
Claire：你桌上那盒鳳梨酥我先幫你收著，不會偷吃，大概。
@hide all

@bg parents_home
@show 爸爸 right 老年
爸爸：手機打字好麻煩，你幫我做一個可以記血壓的東西好不好？
你：好啊，交給我。
系統：input() 可以讓使用者打字輸入，但輸入的東西一律是字串。要拿來比大小，得先用 int() 轉成整數。

```python
text = input("請輸入今天的收縮壓：")
value = int(text)
print(f"已記錄：{value}")
```

@hide all
@phone 爸爸
（第二天，爸爸打電話來。）
爸爸：你那個東西壞掉了啦！我一打字它就跳出一大堆英文。
（你一看，爸爸輸入的是「一百二」。）
@phone off
派森：int() 看不懂國字，程式就當機了。這時候可以用 try 和 except：先「試試看」，如果出錯，就改做另一件事，而不是整個當掉。

@level ch5_3_pressure
title: 爸爸的血壓紀錄
goal: 修改 record_pressure()，讓爸爸輸入國字時不會當機，並給出貼心的提示；輸入數字時照常記錄。
tags: try: | except ValueError: | 140 以上偏高
hint: 把 value = int(text) 放進 try: 底下；except ValueError: 底下印出提示，然後 return None。
hint: try 和 except 要對齊，底下的程式各自往內縮。
starter:
```python
def record_pressure(text):
    value = int(text)
    if value >= 140:
        print(f"記錄 {value}，有點偏高，記得跟醫生說。")
    else:
        print(f"記錄 {value}，很好，今天也很健康！")
    return value

record_pressure("一百二")
record_pressure("128")
```
check:
```python
assert "try" in code and "except" in code, "用 try / except 接住 int() 看不懂的時候。"
assert record_pressure("一百二") is None, "爸爸打國字的時候，記錄不到數字，要 return None。"
assert record_pressure("128") == 128, "打數字的時候，還是要正常記錄並回傳數字。"
assert record_pressure("150") == 150
assert "記錄 128" in out, "128 要被正常記錄下來。"
```
solution:
```python
def record_pressure(text):
    try:
        value = int(text)
    except ValueError:
        print("要輸入阿拉伯數字喔，像是 120。")
        return None
    if value >= 140:
        print(f"記錄 {value}，有點偏高，記得跟醫生說。")
    else:
        print(f"記錄 {value}，很好，今天也很健康！")
    return value

record_pressure("一百二")
record_pressure("128")
```
success: 爸爸打國字也不會當機了。
@end

@phone 爸爸
（從那天起，每天早上你都會收到爸爸傳來的數字。）
爸爸：128
爸爸：131 今天天氣很好
爸爸：125 你媽說你要多吃點
@phone off
派森：還記得你剛出生時，拜託我教你把爸媽的愛存起來嗎？
你：記得啊，love = "爸爸媽媽"。
派森：現在換你把愛存進他們的生活裡了。
