# 2.3 便利商店　｜　國中　｜　Boolean、if / else、round()
# 場景：便利商店內，白色日光燈。關卡中結帳螢幕顯示店員的金額，讓玩家對照。

@bg convenience_store
派森：時間過得真快，不知不覺你也上國中了。
你：很快嗎？我怎麼覺得時間過得很慢。感覺整天都在等待：早上等爸媽送我到學校，上課時等下課跟朋友聊天，放學後等補習班，聽課時邊想著下課要買什麼點心，也在等會考那天到來。
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
success: 被你抓到了！店員多收了 12 元。
@end

@level ch2_3_noodles
title: 關卡三：全部打 9 折
goal: 泡麵 49 元兩碗＋茶葉蛋 13 元，全部打 9 折。店員收 100 元。小數點要用 round() 處理喔。
tags: 泡麵 49 元 × 2 | 茶葉蛋 13 元 | 9 折 | 店員收 100 元
hint: (49 × 2 + 13) × 0.9 = 99.9，round() 之後是多少？
starter:
```python
noodles = 49
tea_egg = 13
clerk_total = 100
my_answer = 
if my_answer == clerk_total:
    print(f"沒問題！總共是 {my_answer} 元。")
else:
    print("咦？好像哪裡算錯了，跟店員確認一下吧。")
```
check:
```python
assert my_answer == 100, "還不對喔：先算 (49 × 2 + 13) × 0.9，再用 round()。"
assert "沒問題" in out, "這次店員是對的。"
```
solution:
```python
noodles = 49
tea_egg = 13
clerk_total = 100
my_answer = round((noodles * 2 + tea_egg) * 0.9)
if my_answer == clerk_total:
    print(f"沒問題！總共是 {my_answer} 元。")
else:
    print("咦？好像哪裡算錯了，跟店員確認一下吧。")
```
@end

（便利商店的對帳遊戲結束了。）
成就：精打細算
（轉場）
