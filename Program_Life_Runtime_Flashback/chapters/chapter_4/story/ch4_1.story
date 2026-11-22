# 4.1 期末考　｜　20 歲（大二）　｜　dict 字典、.items()、更新字典
# 場景：大學宿舍（早晨、凌亂）、大學教室。成績單用字典的樣子呈現，修改物理分數時數字有跳動動畫。

@bg dorm
@bgm campus
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
    "微積分": 60, "計算機概論": 62, "物理": 58,
    "體育": 90, "英文": 65, "通識邏輯": 70,
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

派森：改之前，先把字典怎麼用弄清楚。
系統：字典 dict 用大括號 { } 裝「鍵: 值」。鍵像標籤，值是標籤對應的東西；用 字典["鍵"] 就能拿到值。

```python
bag = {"筆": 3, "書": 1}
print(bag["筆"])      # 用鍵找值：3
bag["書"] = 2         # 鍵已經存在 → 改掉原本的值
bag["尺"] = 1         # 鍵還不存在 → 新增一筆
print(bag)            # {'筆': 3, '書': 2, '尺': 1}
```

系統：.items() 會把每一筆的「鍵和值」一起拿出來，配合 for 就能一筆一筆檢查：

```python
for name, num in bag.items():
    print(name, num)
# 筆 3
# 書 2
# 尺 1
```

系統：.items() 常常跟 if 一起用：一筆一筆檢查，符合條件的就用 append 放進另一個 list。例如找出數量 2 個以上的文具：

```python
bag = {"筆": 3, "書": 2, "尺": 1}
many = []
for name, num in bag.items():   # 一次拿出一筆：name 是鍵、num 是值
    if num >= 2:                # 符合條件……
        many.append(name)       # ……就把「鍵」放進 many
print(many)                     # ['筆', '書']
```

翊丞：對了，「程式設計」的成績剛剛也公布了，75 分！你幫我一起加進去。
派森：這次要你自己動手三個地方：① 把物理改成 60 ② 把程式設計 75 分加進字典 ③ 自己寫迴圈，把不及格的科目找出來。
派森：改分數跟加科目的寫法一模一樣，都是 字典["鍵"] = 值——鍵已經有就是更新，還沒有就是新增。迴圈的寫法，照上面找文具的例子改就對了。

@level ch4_1_scores
title: 成績單守護者
goal: 更新物理分數、加上程式設計的成績，再自己寫迴圈找出不及格的科目，看看翊丞能不能 All pass。
intro: 三個地方都要自己寫：更新、新增、用 for 和 .items() 檢查。
step: 在註解底下用 scores["物理"] = 60 把物理改成 60
step: 用一樣的寫法，把「程式設計」75 分加進字典
step: 寫 for subject, score in scores.items():，分數小於 60 就 failed.append(subject)
expect:
```text
翊丞：這學期一共修了 7 科
翊丞：All pass！明年可以繼續一起打遊戲！
```
tags: ① scores["物理"] = 60 | ② scores["程式設計"] = 75 | ③ for … in scores.items()
hint: ① 在字典底下加一行 scores["物理"] = 60。
hint: ② 新增跟更新寫法一樣：scores["程式設計"] = 75。加完後「一共修了」會變成 7 科。
hint: ③ 第一行寫 for subject, score in scores.items():，下一行縮排寫 if score < 60:，再下一行再縮排寫 failed.append(subject)。
starter:
```python
scores = {
    "微積分": 60, "計算機概論": 62, "物理": 58,
    "體育": 90, "英文": 65, "通識邏輯": 70,
}
# ① 教授改分數了：在這裡把物理改成 60

# ② 程式設計的成績公布了（75 分）：在這裡加進字典

failed = []
# ③ 用 for 和 .items() 一科一科檢查，分數小於 60 的科目放進 failed


# ↓ 下面的程式不用改
print(f"翊丞：這學期一共修了 {len(scores)} 科")
if len(failed) == 0:
    print("翊丞：All pass！明年可以繼續一起打遊戲！")
elif len(failed) >= 3:
    print("翊丞：救命啊，我要被退學了！")
else:
    print(f"翊丞：還好，只要重修 {failed} 就好……")
```
check:
```python
import ast
base = {"微積分": 60, "計算機概論": 62, "體育": 90, "英文": 65, "通識邏輯": 70}
assert "scores" in globals() and isinstance(scores, dict), "請保留 scores 這個字典。"
assert scores.get("物理") == 60, "① 物理還是 %s 分，用 scores[\"物理\"] = 60 把它改掉。" % scores.get("物理")
assert "程式設計" in scores, "② 字典裡還沒有「程式設計」，用 scores[\"程式設計\"] = 75 加進去。"
assert scores["程式設計"] == 75, "② 程式設計是 75 分喔。"
assert all(scores.get(k) == v for k, v in base.items()) and len(scores) == 7, "其他科目的分數不用動，也不要多加別的科目。"
loops = [n for n in ast.walk(ast.parse(code)) if isinstance(n, ast.For) and "scores.items()" in ast.unparse(n.iter)]
assert loops, "③ 還沒看到 for … in scores.items(): 的迴圈。"
trial = {"scores": {"甲": 59, "乙": 60, "丙": 30}, "failed": []}
exec(ast.unparse(loops[0]), trial)
assert trial["failed"] == ["甲", "丙"], "③ 迴圈要把分數小於 60 的科目 append 進 failed（剛好 60 分算及格）。"
assert failed == [], "③ 這次所有科目都及格了，failed 應該是空的。"
assert out.strip().splitlines() == ["翊丞：這學期一共修了 7 科", "翊丞：All pass！明年可以繼續一起打遊戲！"], "下面印出結果的程式不用改喔。"
```
solution:
```python
scores = {
    "微積分": 60, "計算機概論": 62, "物理": 58,
    "體育": 90, "英文": 65, "通識邏輯": 70,
}
# ① 教授改分數了：在這裡把物理改成 60
scores["物理"] = 60
# ② 程式設計的成績公布了（75 分）：在這裡加進字典
scores["程式設計"] = 75
failed = []
# ③ 用 for 和 .items() 一科一科檢查，分數小於 60 的科目放進 failed
for subject, score in scores.items():
    if score < 60:
        failed.append(subject)

# ↓ 下面的程式不用改
print(f"翊丞：這學期一共修了 {len(scores)} 科")
if len(failed) == 0:
    print("翊丞：All pass！明年可以繼續一起打遊戲！")
elif len(failed) >= 3:
    print("翊丞：救命啊，我要被退學了！")
else:
    print(f"翊丞：還好，只要重修 {failed} 就好……")
```
success: 物理 60、程式設計 75，七科全部及格，failed 清單是空的——All pass！翊丞抱著你又叫又跳。
@end

你：All pass 了，你可以安心過年了。
成就：成績單守護者
