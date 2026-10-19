# 2.2 跑腿計算　｜　幼兒　｜　四則運算
# 場景：家附近的早餐店，早晨。鏡頭從低角度看媽媽的背影，表現小孩的視角。

@bg living_room
派森：你長高了呢，真可愛。
你：你在捉弄我嗎？也是啦，從嬰兒變成幼兒總會有個成長期嘛。
派森：（AI 回應：回應玩家，並提到每個人或多或少都有被爸媽帶著認識世界的經歷。）
【備用台詞】派森：我是說真的。每個人小時候都是被爸媽牽著手，一點一點認識這個世界的，現在輪到你了。
@show 媽媽 left
媽媽：寶貝你長大了，就快要去上學了呢，所以媽媽今天要讓你練習去買早餐。
你：好～
系統：媽媽牽著你的手，帶著你出門。
@hide all
@cg holding_hands 媽媽牽著你的手，走在巷子裡的背影
（跟在高大背影後面的你覺得，慢慢長大其實也不錯。跟著爸媽，或許可以看見比家裡更大的世界。）

@bg breakfast_shop
@show 媽媽 left
（來到家附近的早餐店）
媽媽：去跟早餐店阿姨點你喜歡吃的吧。

@choice food 想吃什麼呢？
- 培根蛋吐司　35 元 = 培根蛋吐司
- 火腿起司蛋餅　40 元 = 火腿起司蛋餅
- 鐵板麵　50 元 = 鐵板麵
@end
@choice drink 要喝什麼？
- 中冰奶　25 元 = 中冰奶
- 紅茶　20 元 = 紅茶
- 豆漿　20 元 = 豆漿
@end
@if food == "培根蛋吐司"
@set food_price = 35
@elif food == "火腿起司蛋餅"
@set food_price = 40
@else
@set food_price = 50
@endif
@if drink == "中冰奶"
@set drink_price = 25
@else
@set drink_price = 20
@endif

媽媽：原來你喜歡吃{food}啊。來，媽媽先示範怎麼算。
媽媽：媽媽的培根蛋吐司加中冰奶，可以這樣算：

```python
bacon_egg_toast = 35
iced_milk = 25
print(bacon_egg_toast + iced_milk)         # 60
print(100 - (bacon_egg_toast + iced_milk)) # 付 100 元，要找 40 元
```

媽媽：換你試試看吧，寶貝。
系統：Python 的加減乘除是 +、-、*、/。先算括號裡面，再算外面，跟數學課一樣。
派森：在日常生活中，對會寫程式的人來說，只要寫得出算式，就能得到答案。

@level ch2_2_breakfast
title: 算算早餐錢
goal: 你點了{food}和{drink}。用程式算出總共多少錢，以及付 100 元要找多少。
tags: {food}　{food_price} 元 | {drink}　{drink_price} 元 | 付 100 元
hint: 先把兩個價格放進盒子，再用 + 加起來。
hint: 找零就是 100 - (food + drink)，記得括號。
starter:
```python
food = <<food_price>>
drink = <<drink_price>>
print()   # 總共多少錢？
print()   # 付 100 元要找多少？
```
check:
```python
total = <<food_price>> + <<drink_price>>
nums = [l.strip() for l in lines]
assert str(total) in nums, "總共多少錢還沒算對喔：把兩個價格加起來印出來。"
assert str(100 - total) in nums, "還要印出付 100 元要找多少錢。"
```
solution:
```python
food = 35
drink = 25
print(food + drink)
print(100 - (food + drink))
```
success: 一塊錢都沒算錯！
@end

媽媽：真棒啊寶貝！以後買東西都要自己先算過一遍喔，這樣別人算錯的時候，才不會多付錢。
@hide all
@cg breakfast 你捧著早餐吃得很開心
（你接過阿姨遞來的早餐，一口一口吃著，為自己的成長感到開心，臉上露出幸福的表情。）
@show 媽媽 left
媽媽：你喜歡吃這個嗎？以後媽媽都幫你買這個，好不好？
（吃得津津有味的你，聽到以後都能吃到像今天一樣的美味，開心地點了點頭。）
派森：真是幸福。希望未來的某一天，你還會想起今天。
成就：第一次算數
（轉場 → 進入學校時光）
