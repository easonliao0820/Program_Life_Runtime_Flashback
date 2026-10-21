# 2.3 便利商店　｜　13 歲（國一）　｜　Boolean、if / else、round()
# 時間軸：第一次自己買早餐，認識倖芳（湖的夢想從這裡埋下伏筆）。
# 場景：便利商店內，白色日光燈。關卡中結帳螢幕顯示店員的金額，讓玩家對照。

@bg convenience_store
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

@level ch2_3_breakfast
title: 關卡一：早餐時段
goal: 豆漿 25 元＋草莓吐司 60 元，早餐時段打 85 折。結帳螢幕上，店員收 72 元。算算看店員對不對。
tags: 豆漿 25 元 | 草莓吐司 60 元 | 85 折 = × 0.85 | 店員收 72 元
hint: 打 85 折就是乘上 0.85；算完記得用 round() 變成整數。
starter:
```python
soy_milk = 25
strawberry_toast = 60
clerk_total = 72
my_answer =    # 算算看：打 85 折之後是多少？
if my_answer == clerk_total:
    print(f"沒問題！總共是 {my_answer} 元。")
else:
    print("咦？好像哪裡算錯了，跟店員確認一下吧。")
```
check:
```python
assert my_answer == 72, "my_answer 還不對喔：(25 + 60) 打 85 折，再 round() 一下。"
assert "沒問題" in out, "這次店員是對的，要印出「沒問題」。"
```
solution:
```python
soy_milk = 25
strawberry_toast = 60
clerk_total = 72
my_answer = round((soy_milk + strawberry_toast) * 0.85)
if my_answer == clerk_total:
    print(f"沒問題！總共是 {my_answer} 元。")
else:
    print("咦？好像哪裡算錯了，跟店員確認一下吧。")
```
success: 85 折之後是 72 元，跟結帳螢幕上一樣。店員算對了，可以放心付錢。
@end

@level ch2_3_onigiri
title: 關卡二：第二件 6 折
goal: 御飯糰 35 元＋兩瓶奶茶各 30 元，飲料第二件 6 折。店員收 95 元。這次自己寫出 if / else 判斷。
tags: 御飯糰 35 元 | 奶茶 30 元 × 2 | 第二件 6 折 | 店員收 95 元
hint: 第二瓶奶茶是 30 × 0.6。總價 = 35 + 30 + 30 × 0.6。
hint: 照著關卡一的樣子，用 if my_answer == clerk_total: 判斷，else 底下印出提醒。
starter:
```python
onigiri = 35
milk_tea = 30
clerk_total = 95
my_answer = 
```
check:
```python
assert "if" in code and "else" in code, "要自己用 if / else 判斷店員算得對不對。"
assert round(my_answer) == 83, "金額還不對：35 + 30 + 30 × 0.6 是多少呢？"
assert out.strip() != "" and "沒問題" not in out, "店員這次算錯了，else 底下要印出提醒。"
```
solution:
```python
onigiri = 35
milk_tea = 30
clerk_total = 95
my_answer = round(onigiri + milk_tea + milk_tea * 0.6)
if my_answer == clerk_total:
    print(f"沒問題！總共是 {my_answer} 元。")
else:
    print(f"咦？應該是 {my_answer} 元才對，跟店員確認一下吧。")
```
success: 第二瓶 6 折，應該是 83 元——店員多收了 12 元，被你抓到了！
@end

（你結完帳，正要離開，排在你後面的女生卻在櫃檯前面停住了。她穿著跟你一樣的制服，書包上掛著一個湖景照片做成的吊飾。）
……：咦？三明治兩個、茶葉蛋一顆，不是有打九折嗎……怎麼好像有點貴？
（店員一臉忙碌，後面的人已經排成一條長龍。那個女生急得臉都紅了。）
派森：你剛剛練習的東西，現在派得上用場了。

@level ch2_3_noodles
title: 關卡三：幫她算算看
goal: 三明治 49 元兩個＋茶葉蛋 13 元，全部打 9 折，店員一開始收 111 元。幫她算算看店員對不對，小數點要用 round() 處理喔。
tags: 三明治 49 元 × 2 | 茶葉蛋 13 元 | 全部 9 折 | 店員收 111 元
hint: (49 × 2 + 13) × 0.9 = 99.9，round() 之後是多少？
hint: 算出來跟 111 不一樣，else 底下要印出提醒。
starter:
```python
sandwich = 49
tea_egg = 13
clerk_total = 111
my_answer = 
if my_answer == clerk_total:
    print(f"沒問題！總共是 {my_answer} 元。")
else:
    print("咦？好像哪裡算錯了，跟店員確認一下吧。")
```
check:
```python
assert my_answer == 100, "還不對喔：先算 (49 × 2 + 13) × 0.9，再用 round()。"
assert "沒問題" not in out and out.strip() != "", "店員收了 111 元，跟你算的不一樣，要印出提醒。"
```
solution:
```python
sandwich = 49
tea_egg = 13
clerk_total = 111
my_answer = round((sandwich * 2 + tea_egg) * 0.9)
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
