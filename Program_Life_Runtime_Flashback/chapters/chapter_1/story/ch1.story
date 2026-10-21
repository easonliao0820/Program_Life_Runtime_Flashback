# 第一章　放聲大哭（含序章）　｜　Python 概念：print()
# 序章跟第一章合在一起：只有一次章節轉場。
#
# ---------- 序章：睜開眼睛 ----------
# 演出（畫面設定書 第四節）：一開始全黑，畫面上下兩條黑邊慢慢打開，像眼睛睜開；
# 畫面先模糊再對焦，看到父母的臉（逆光、看不清五官）。
# 新生兒的視線還看不清楚：整個第一章，派森都是一團模糊的光（下一節開頭自動恢復清楚）。
# 一開始先藏起來，等第一句「……：」出現時才慢慢浮現。
@orb hide
@orb blur 10
# 先閉上眼睛（畫面維持全黑），在眼皮後面換好背景，再慢慢睜開
@eyes_close
@bgm prologue
@bg delivery_room
@eyes_open
（你漸漸地睜開眼，發現自己來到一個新的世界，不安與恐懼充斥著你的心。）

# ---------- 第一章：放聲大哭 ----------
# 演出：畫面仍是模糊的（序章留下的柔焦）。哭不出來時畫面輕微晃動、聲音悶悶的；
# 玩家成功 print 之後，畫面瞬間變清晰，配上嬰兒哭聲與白光。
# 父母逆光、看不清五官：用後面的 CG（父母剪影）呈現，這裡不放立繪，以免擋住嬰兒房
@orb show
……：終於見到你了，我的朋友。
（被新生父母抱在懷裡的你想著）
心聲：不會吧，我該不會剛出生就要夭折了吧，我也太衰了。
@shake 0.6
（嬰兒的小臉上慢慢多了好幾條小河，但預想中震耳欲聾的哭聲卻沒有出現。）
心聲：為什麼哭不出來？！
……：你是這個世界上獨一無二的存在。你的世界有著獨特的語言和與眾不同的規則，想要發出聲音的話，就學我怎麼做。

```python
print("Hello, World!")
```

……：這是一句很古老的咒語。很久很久以前，每個第一次來到這個語言世界的人，說出的第一句話都是它，意思是：「哈囉，世界！」
……：輪到你了。把這句話放進引號裡，再用 print() 包起來，跟這個世界打聲招呼吧。

# 【判定】大小寫、逗號和驚嘆號不同也算通過（例如 print("hello world")）；
# 只差在引號或括號是全形時，派森會跳出全形符號的提示（ErrorExplainer）。
@level ch1_first_words
title: 第一句話
goal: 把「Hello, World!」放進引號裡，再用 print() 包起來，跟這個世界打聲招呼。
tags: print("Hello, World!")
hint: 括號和引號都要用英文半形：( ) 與 " "。全形的（ ）是 Python 看不懂的。
hint: 完整的寫法是：print("Hello, World!")
starter:
```python
print("")
```
check:
```python
assert "print" in code, "要用 print() 才能發出聲音喔。"
said = "".join(ch for ch in out.lower() if ch.isalnum())
assert said != "", "引號裡面要放進那句古老的咒語：Hello, World!"
assert said == "helloworld", "這句古老的咒語是 Hello, World! 喔，把它放進引號裡。"
```
solution:
```python
print("Hello, World!")
```
success: Hello, World! 你的第一句話傳出去了——嬰兒的哭聲響徹了整個產房。
@end

# 學會發出聲音之後，才能跟派森聊天：解鎖輸入框
@set chat_unlocked = True
@focus
@flash white
@sfx baby_cry
（當你成功說出「Hello, World!」，嬰兒的哭聲終於響徹整個產房。）
@cg birth 剛出生的第一眼：模糊的父母剪影
派森：（AI 回應：回應玩家的第一句「Hello, World!」，歡迎他來到這個世界，並自我介紹。）
【備用台詞】派森：Hello，{userName}。世界聽到你了。這就是你在這個世界的第一句話。我叫派森，從今天起，我會一直在你身邊。只有你看得見我，也只有你聽得懂我的語言。
（轉場）
