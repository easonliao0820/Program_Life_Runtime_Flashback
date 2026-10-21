# 4.1 期末考　｜　20 歲（大二）　｜　dict 字典、.items()、更新字典
# 場景：大學宿舍（早晨、凌亂）、大學教室。成績單用字典的樣子呈現，修改物理分數時數字有跳動動畫。

@bg dorm
（一年半後，大二上學期的期末考週。你夢到了學測那天的考場，夢裡的鐘聲越來越大聲……）
（你感覺到一陣搖晃。）
@show 翊丞 right
翊丞：欸兄弟，起床了！這堂課教授會點名啊！
（是你的室友翊丞在叫你起床。原來剛剛的鐘聲是他的鬧鐘。）
你：啊，鬧鐘怎麼沒響！
派森：誰叫你昨天打遊戲打到半夜，一上床就直接睡死了。
（上了大學，你離開爸媽，開始體驗自己的生活。打工、買自己想買的東西，或許有點孤單，也有點不知所措，但你相信一切都會好起來。）
@if gave_gift
（放榜之後，你和倖芳的訊息越來越少。到現在，已經三個月沒聯絡了。）
@else
（高中畢業後，你和倖芳就沒什麼聯絡了，只偶爾在社群上看到她在臺北的近況。）
@endif

@bg classroom
@show 翊丞 right
教授：今天期末考，相信大家都有好好背我上課畫的重點。
翊丞：完了，我忘記這個教授提早考試了。
（這次考試是一趟漫長的旅程。有人生活規律、記得今天要考試，有人忘了考試正在求神拜佛。今天的你有讀，但讀得不多，或許能得到一個中庸的結局。）
翊丞：（嘆氣）我先來看一下明年能不能隨班重修。
你：沒事啦，去找老師說說看，菜菜撈撈，或許他會撈你過啊。
（刺激的考試週過了一個禮拜，來到學期最後一週。）

@bg dorm
@show 翊丞 right
翊丞：欸欸，你幫我看一下我是不是 All pass 啦，拜託了。這樣我才知道要不要回家攔截成績單。
你：行吧，你欠我一頓飯。
系統：字典 dict 用大括號 { } 建立，裡面是一組一組的「鍵：值」。就像查字典一樣，用科目名稱（鍵）就能查到分數（值），例如 scores["物理"]。
系統：.items() 可以一次拿出每一組鍵和值；用 scores["物理"] = 60 則可以修改字典裡的值。

```python
scores = {
    "微積分": 60,
    "計算機概論": 62,
    "物理": 58,
    "體育": 90,
    "英文": 65,
    "通識邏輯": 70,
}
failed = []
for subject, score in scores.items():
    if score < 60:
        failed.append(subject)
if len(failed) == 0:
    print("翊丞：All pass！明年可以繼續一起打遊戲！")
elif len(failed) >= 3:
    print("翊丞：救命啊，我要被退學了！")
else:
    print(f"翊丞：還好，只要重修 {failed} 就好……")
```

（第一次執行，螢幕跳出：翊丞：還好，只要重修 ['物理'] 就好……）
翊丞：差兩分！我、我現在就去找教授！
@hide 翊丞
（半小時後，翊丞衝回宿舍，氣喘吁吁。）
@show 翊丞 right
翊丞：教授說我期中報告寫得很認真，物理給我 60 了！快，再跑一次！

@level ch4_1_scores
title: 成績單守護者
goal: 教授把翊丞的物理改成 60 分了。修改字典裡物理的分數，再執行一次，確認翊丞 All pass。
tags: scores["物理"] = 60 | for subject, score in scores.items()
hint: 在字典建立之後、for 迴圈之前，加上一行 scores["物理"] = 60。
starter:
```python
scores = {
    "微積分": 60,
    "計算機概論": 62,
    "物理": 58,
    "體育": 90,
    "英文": 65,
    "通識邏輯": 70,
}
# 教授改分數了！在這裡修改物理的分數


failed = []
for subject, score in scores.items():
    if score < 60:
        failed.append(subject)
if len(failed) == 0:
    print("翊丞：All pass！明年可以繼續一起打遊戲！")
elif len(failed) >= 3:
    print("翊丞：救命啊，我要被退學了！")
else:
    print(f"翊丞：還好，只要重修 {failed} 就好……")
```
check:
```python
assert scores["物理"] == 60, "物理現在是 %s 分，教授說要改成 60 分。" % scores["物理"]
assert "All pass" in out, "還沒有 All pass 喔，看看 failed 裡還有什麼。"
assert 'scores["物理"]' in code or "scores['物理']" in code, "試著用 scores[\"物理\"] = 60 修改字典，而不是直接改上面的數字。"
```
solution:
```python
scores = {"微積分": 60, "計算機概論": 62, "物理": 58, "體育": 90, "英文": 65, "通識邏輯": 70}
scores["物理"] = 60
failed = []
for subject, score in scores.items():
    if score < 60:
        failed.append(subject)
if len(failed) == 0:
    print("翊丞：All pass！明年可以繼續一起打遊戲！")
elif len(failed) >= 3:
    print("翊丞：救命啊，我要被退學了！")
else:
    print(f"翊丞：還好，只要重修 {failed} 就好……")
```
success: 物理改成 60 分，failed 清單空了——All pass！翊丞抱著你又叫又跳。
@end

你：All pass 了，你可以安心過年了。
成就：成績單守護者
