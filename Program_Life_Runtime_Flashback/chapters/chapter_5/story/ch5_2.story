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
t, a = summarize([88, 102])
assert a == 95.0, "中區的月平均應該是 (88 + 102) ÷ 2。不要把 3 寫死，讓 len() 去數有幾個月。"
assert summarize([1, 2, 3, 4])[1] == 2.5, "summarize() 要能處理任何月數的資料。"
assert "中區：總業績 190 萬，月平均 95.0 萬" in out, "報表上中區的數字還不對。"
assert best_region == "南區" and best_total == 415, "本季冠軍還沒找對：比較每一區的總業績，留下最高的那一區。"
assert "南區" in out.splitlines()[-1], "最後一行要印出本季冠軍。"
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
