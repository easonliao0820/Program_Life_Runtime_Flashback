# 2.3 便利商店　｜　13 歲（國一）　｜　Boolean、if / else、round()
# 時間軸：第一次自己買早餐，認識倖芳（湖的夢想從這裡埋下伏筆）。
# 場景：便利商店內，白色日光燈。關卡中結帳螢幕顯示店員的金額，讓玩家對照。

@bg convenience_store
@bgm childhood
（十三歲，國一開學的第二個禮拜。）
派森：時間過得真快，不知不覺你也上國中了。
你：很快嗎？我怎麼覺得時間過得很慢。感覺整天都在等待：早上等爸媽送我到學校，上課時等下課跟朋友聊天，放學後等補習班，聽課時邊想著下課要買什麼點心，也在等著快點長大。
派森：人生總是在等待、也在期待，在不自由中期待著自由。話說，今天爸媽怎麼沒有送你上學、幫你買早餐？
你：媽媽說我長大了，有些事情可以自己來，所以給我零用錢，讓我自己去便利商店買東西吃。而且學校離家裡也不遠。
派森：她很放心你喔。
你：可能是家長會的時候，發現其他同學的家長已經開始給零用錢了吧，所以才放手讓我試試看。
派森：那你可以學學怎麼用程式快速跟店員對帳，還有怎麼判斷「對」和「錯」。
系統：在 Python 裡，「對」是 True，「錯」是 False，這種只有兩種答案的值叫做 Boolean（布林值）。== 用來比較兩邊是否相等，比較的結果就是 True 或 False。
系統：if 可以讓程式「做判斷」：如果條件是 True，就做 if 底下的事；否則就做 else 底下的事。底下的程式要往內縮排（四個空白）。
派森：關於小數點後的進位，這個小工具或許對你有幫助。
系統：round() 可以把小數變成最接近的整數，例如 round(72.25) 會得到 72。
派森：不過要小心，round() 遇到剛好 .5 的時候，會選擇最接近的「偶數」，所以 round(2.5) 是 2，round(3.5) 是 4。這跟數學課教的四捨五入不太一樣。
（每一關會有一段情境，你要寫程式算出金額，並判斷店員算得對不對。）

```python
soy_milk = 25
strawberry_toast = 60
clerk_total = 72
my_answer = round((soy_milk + strawberry_toast) * 0.85)
print(my_answer == clerk_total)   # True
if my_answer == clerk_total:
    print(f"沒問題！總共是 {my_answer} 元。")
else:
    print("咦？好像哪裡算錯了，跟店員確認一下吧。")
```

派森：先別急著對帳。我們先暖身一下，只練「比較」這一件事。
@level ch2_3_compare
title: 暖身：對還是錯？
goal: 用 == 比較兩邊一不一樣，讓程式印出 True（對）或 False（錯）。
step: 第一行已經寫好了：25 + 60 跟 85 一樣嗎？
step: 照第一行的樣子，在第二行的括號裡寫：25 + 60 跟 80 一樣嗎？
step: 按執行，看看兩行各印出什麼
expect:
```text
True
False
```
tags: == 比較兩邊 | 一樣 → True | 不一樣 → False
hint: 第二行跟第一行幾乎一樣，只是把 85 換成 80：print(25 + 60 == 80)
hint: 記得是兩個等號 ==。一個等號 = 是「放進盒子」，不能拿來比較。
starter:
```python
print(25 + 60 == 85)   # 25 + 60 跟 85 一樣嗎？
print()   # ← 在括號裡寫：25 + 60 跟 80 一樣嗎？
```
check:
```python
import ast
compares = [n for n in ast.walk(ast.parse(code)) if isinstance(n, ast.Compare) and any(isinstance(op, ast.Eq) for op in n.ops)]
assert len(compares) >= 2, "第二行也要用兩個等號 == 來比較喔。"
assert any(isinstance(c, ast.Constant) and c.value == 80 for n in compares for c in [n.left] + n.comparators), \
    "第二行要比較的是 25 + 60 跟 80。"
assert lines == ["True", "False"], "第一行應該印出 True、第二行印出 False。第二行寫的是 print(25 + 60 == 80) 嗎？"
```
solution:
```python
print(25 + 60 == 85)   # 25 + 60 跟 85 一樣嗎？
print(25 + 60 == 80)   # ← 在括號裡寫：25 + 60 跟 80 一樣嗎？
```
success: 85 對、80 錯。== 就像一台判斷機，只會回答 True 或 False。接下來把它放進 if，讓程式自己決定要說什麼。
counts: false
@end

系統：if 後面放的就是剛剛那種比較。比較結果是 True，就執行 if 底下的那行；是 False，就改做 else 底下的那行。
系統：下一關的 if 和 else 都已經寫好了，你只要在 my_answer = 後面寫出打折後的算式。

@level ch2_3_breakfast
title: 關卡一：早餐時段
goal: 算出打 85 折後要付多少，讓程式判斷店員收 72 元對不對。
step: 在 my_answer = 後面寫算式：先把豆漿和吐司加起來，再乘上 0.85
step: 加法要用括號包起來，最外面再用 round( ) 變成整數
step: 下面的 if / else 不用改，按執行
expect:
```text
沒問題！總共是 72 元。
```
tags: 豆漿 25 元 | 草莓吐司 60 元 | 85 折 = × 0.85 | 店員收 72 元
hint: 打 85 折就是乘上 0.85；算完記得用 round() 變成整數。
starter:
```python
soy_milk = 25
strawberry_toast = 60
clerk_total = 72
my_answer =    # ← 在這裡算：打 85 折之後是多少？（記得用 round）
if my_answer == clerk_total:
    print(f"沒問題！總共是 {my_answer} 元。")
else:
    print("咦？好像哪裡算錯了，跟店員確認一下吧。")
```
check:
```python
assert "my_answer" in globals(), "請把計算結果存入 my_answer。"

assert type(my_answer) is int and my_answer == 72, \
    "請使用 round() 計算：(25 + 60) × 0.85，結果應為整數72。"

assert "soy_milk" in globals() and soy_milk == 25, \
    "豆漿價格應保留為25元。"

assert "strawberry_toast" in globals() and strawberry_toast == 60, \
    "草莓吐司價格應保留為60元。"

assert "clerk_total" in globals() and clerk_total == 72, \
    "店員收費應保留為72元。"

actual_lines = [line.strip() for line in lines if line.strip()]

assert actual_lines == ["沒問題！總共是 72 元。"], \
    "這次店員算對了，請保留原本的輸出格式：沒問題！總共是 72 元。"
```
solution:
```python
soy_milk = 25
strawberry_toast = 60
clerk_total = 72
my_answer = round((soy_milk + strawberry_toast) * 0.85)    # ← 在這裡算：打 85 折之後是多少？（記得用 round）
if my_answer == clerk_total:
    print(f"沒問題！總共是 {my_answer} 元。")
else:
    print("咦？好像哪裡算錯了，跟店員確認一下吧。")
```
success: 85 折之後是 72 元，跟結帳螢幕上一樣。店員算對了，可以放心付錢。
@end

派森：這次換「第二件打折」。重點是：只有第二瓶要乘上折數，第一瓶還是原價。
系統：6 折就是乘上 0.6，8 折就是乘上 0.8。打折只會作用在你乘上去的那一項。

```python
bread = 40
juice = 20
total = bread + juice + juice * 0.5   # 第二瓶果汁半價
print(round(total))                    # 70
```

系統：電腦會先算乘法：juice * 0.5 是 10，再加上麵包 40 和第一瓶果汁 20，總共 70。
系統：一個等號 = 是「把東西放進盒子」；兩個等號 == 才是「比較兩邊一不一樣」，結果是 True 或 False。千萬別搞混。
派森：所以這關要做兩件事：先把 my_answer 算出來，再把 if 後面的 False 換成「my_answer 和店員收的錢一樣嗎」的比較。

@level ch2_3_onigiri
title: 關卡二：第二件 6 折
goal: 算出「第二瓶 6 折」的金額，讓程式判斷店員收 95 元對不對。
step: 把 my_answer 的 0 換成算式：飯糰＋第一瓶奶茶＋第二瓶奶茶 × 0.6，最外面用 round( )
step: 把 if 後面的 False 換成比較：my_answer 跟 clerk_total 一樣嗎？（用 ==）
step: 下面的 print 不用改，按執行
expect:
```text
店員算錯了，請再確認金額。
應付金額： 83
```
tags: 第一瓶原價 | 第二瓶 × 0.6 | == 比較是否相等
hint: 總價是「御飯糰＋第一瓶奶茶＋第二瓶奶茶」，只有第二瓶乘上0.6。
hint: my_answer = round(onigiri + milk_tea + milk_tea * 0.6)，判斷條件使用 my_answer == clerk_total。
starter:
```python
onigiri = 35
milk_tea = 30
clerk_total = 95

# ① 把 0 換成正確的計算式
my_answer = 0          # ← 把 0 換成計算式

# ② 把 False 換成兩個金額是否相等的比較式
if False:              # ← 把 False 換成比較式
    print("店員算對了！")
else:
    print("店員算錯了，請再確認金額。")

print("應付金額：", my_answer)
```
check:
```python
import ast
import contextlib
import io
import re
import sys

assert globals().get("onigiri") == 35, \
    "請保留御飯糰價格 35 元。"

assert globals().get("milk_tea") == 30, \
    "請保留奶茶價格 30 元。"

assert globals().get("clerk_total") == 95, \
    "請保留店員收費 95 元。"

assert type(globals().get("my_answer")) in (int, float) and my_answer == 83, \
    "第二瓶才打 6 折：35＋30＋30×0.6＝83 元。"

# 忽略空白、換行及常見標點差異。
def normalize(text):
    return re.sub(r"[\s，,。.!！?？:：、；;]", "", text)

tree = ast.parse(code)

branches = [
    node for node in tree.body
    if isinstance(node, ast.If) and node.orelse
]

assert len(branches) == 1, \
    "請保留一組 if / else，並完成比較條件。"

# 單獨測試玩家填寫的 if / else。
branch_code = compile(
    ast.Module(body=[branches[0]], type_ignores=[]),
    "<branch-test>",
    "exec"
)

for charged in (83, 95, 80):
    scope = dict(globals())
    scope["clerk_total"] = charged
    capture = io.StringIO()
    steps = [0]

    def guard(frame, event, arg):
        if event == "line":
            steps[0] += 1
            assert steps[0] < 3000, \
                "這題只需要 if / else，不需要重複執行迴圈。"
        return guard

    previous = sys.gettrace()
    try:
        sys.settrace(guard)
        with contextlib.redirect_stdout(capture):
            exec(branch_code, scope)
    finally:
        sys.settrace(previous)

    expected = (
        "店員算對了！"
        if charged == 83
        else "店員算錯了，請再確認金額。"
    )

    assert normalize(capture.getvalue()) == normalize(expected), \
        "金額已算對！請比較 my_answer 和 clerk_total 是否相等，並保留兩個分支的提示文字。"

# 檢查實際輸出，接受 83 或 83.0。
expected_output = "店員算錯了，請再確認金額。應付金額：83"

assert normalize(out) in (
    normalize(expected_output),
    normalize(expected_output + ".0")
), \
    "請保留預先提供的輸出文字及最後的應付金額；空白、換行與標點不影響判定。"
```
solution:
```python
onigiri = 35
milk_tea = 30
clerk_total = 95

# ① 把 0 換成正確的計算式
my_answer = round(onigiri + milk_tea + milk_tea * 0.6)          # ← 把 0 換成計算式

# ② 把 False 換成兩個金額是否相等的比較式
if my_answer == clerk_total:              # ← 把 False 換成比較式
    print("店員算對了！")
else:
    print("店員算錯了，請再確認金額。")

print("應付金額：", my_answer)
```
success: 第二瓶6折，應付83元！你用程式發現店員多收了12元。
@end

（你結完帳，正要離開，排在你後面的女生卻在櫃檯前面停住了。她穿著跟你一樣的制服，書包上掛著一個湖景照片做成的吊飾。）
……：咦？三明治兩個、茶葉蛋一顆，不是有打九折嗎……怎麼好像有點貴？
（店員一臉忙碌，後面的人已經排成一條長龍。那個女生急得臉都紅了。）
派森：你剛剛練習的東西，現在派得上用場了。

系統：「全部打 9 折」跟上一題不一樣：要先把全部加起來，再一起乘上 0.9。這時候一定要用括號，因為電腦會「先乘除、後加減」。

```python
cookie = 20
milk = 30
wrong = cookie * 2 + milk * 0.9      # 沒括號：只有牛奶打到折
right = (cookie * 2 + milk) * 0.9    # 有括號：先加總，再整筆打折
print(round(wrong), round(right))    # 67 63
```

系統：沒加括號時，0.9 只乘到最後一項；加了括號，括號裡會先算完，再一起打折。
系統：round() 會四捨五入成整數，例如 99.9 會變成 100。算好 my_answer 之後，下面的 if 會自動幫你跟店員收的錢比對。

@level ch2_3_noodles
title: 關卡三：幫她算算看
goal: 幫她算出全部打 9 折後的金額，看看店員收 111 元對不對。
step: 在 my_answer = 後面寫算式：三明治 × 2 加上茶葉蛋，再整筆乘上 0.9
step: 要先加總再打折，所以加法要用括號包起來，最外面用 round( )
step: 下面的 if / else 不用改，按執行
expect:
```text
咦？好像哪裡算錯了，跟店員確認一下吧。
```
tags: 三明治 49 元 × 2 | 茶葉蛋 13 元 | 全部 9 折 | 店員收 111 元
hint: (49 × 2 + 13) × 0.9 = 99.9，round() 之後是多少？
hint: 算出來跟 111 不一樣，else 底下要印出提醒。
starter:
```python
sandwich = 49
tea_egg = 13
clerk_total = 111
my_answer =    # ← 在這裡算：全部加起來再打 9 折（記得括號和 round）
if my_answer == clerk_total:
    print(f"沒問題！總共是 {my_answer} 元。")
else:
    print("咦？好像哪裡算錯了，跟店員確認一下吧。")
```
check:
```python
import ast

assert "sandwich" in globals() and sandwich == 49, \
    "每個三明治的價格應保留為49元。"

assert "tea_egg" in globals() and tea_egg == 13, \
    "茶葉蛋價格應保留為13元。"

assert "clerk_total" in globals() and clerk_total == 111, \
    "店員收費應保留為111元。"

assert "my_answer" in globals(), \
    "請把計算結果存入 my_answer。"

assert type(my_answer) is int and my_answer == 100, \
    "先算(49×2＋13)×0.9＝99.9，再用 round() 得到整數100。"

tree = ast.parse(code)

has_round = any(
    isinstance(node, ast.Call)
    and isinstance(node.func, ast.Name)
    and node.func.id == "round"
    for node in ast.walk(tree)
)
assert has_round, "請實際呼叫 round() 處理小數，註解裡寫 round() 不算。"

has_if_else = any(
    isinstance(node, ast.If)
    and node.body
    and node.orelse
    for node in ast.walk(tree)
)
assert has_if_else, "請保留 if / else 判斷。"

actual_lines = [line.strip() for line in lines if line.strip()]
expected = "咦？好像哪裡算錯了，跟店員確認一下吧。"

assert actual_lines == [expected], \
    "應付100元，店員收111元。請保留原本 else 裡的提醒文字，不要另外印出其他內容。"
```
solution:
```python
sandwich = 49
tea_egg = 13
clerk_total = 111
my_answer = round((sandwich * 2 + tea_egg) * 0.9)    # ← 在這裡算：全部加起來再打 9 折（記得括號和 round）
if my_answer == clerk_total:
    print(f"沒問題！總共是 {my_answer} 元。")
else:
    print("咦？好像哪裡算錯了，跟店員確認一下吧。")
```
success: 99.9 元 round 之後是 100 元，店員忘了打九折、多收了 11 元。你幫她把錢要回來了！
@end

（你把手機上的計算結果拿給店員看。店員連忙道歉，重新結帳，退了 11 元給她。）
@show 倖芳 right
……：謝謝你！你算得好快喔。
……：我叫倖芳，上禮拜剛轉來，就在你隔壁班。我常常看到你在這裡買早餐。
你：我叫 {userName}。妳的吊飾好漂亮，那是哪裡？
倖芳：是我外婆家附近的湖。我以後想住在那樣的地方，每天看日升日落。（她不好意思地笑了笑）明天見！
@hide all
（她跑向學校，書包上的湖在晨光裡晃呀晃。）
派森：你看，程式不只能幫你算錢，還能幫你認識新朋友。

（便利商店的對帳遊戲結束了。）
成就：精打細算

# ---------- 過場：國中三年（13～15 歲） ----------
（從那天起，你們常常在便利商店遇到，後來乾脆約好一起買早餐、一起走去學校。）
（國二的段考前，倖芳教你英文，你教她數學；國三的會考倒數，你們在圖書館坐同一張桌子，各自戴著耳機。）
（放榜那天，你們同時在榜單上找到彼此的名字：考上了同一所高中。）
@show 倖芳 right
倖芳：太好了！高中也請多指教喔，數學小老師。
派森：（小聲）你的耳朵怎麼紅了？
（轉場）
