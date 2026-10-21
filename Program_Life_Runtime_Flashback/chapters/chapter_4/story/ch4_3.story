# 4.3 一則訊息　｜　20 歲（大二）　｜　字串方法 strip() / replace() / len()
# 場景：宿舍夜晚，只有手機螢幕的光照在臉上。打字、刪字用手機畫面元件呈現。

@bg dorm_night
（回到宿舍，你盯著手機螢幕，打了又刪、刪了又打，已經過了一個小時。）
派森：要不要讓我幫你整理一下？你的草稿前後都是多餘的空白，還有一堆刪節號。
系統：字串也有許多好用的方法：strip() 可以去掉前後的空白，replace("舊", "新") 可以把文字替換掉，len() 可以算出字串有幾個字。

```python
draft = "   倖芳……好久不見……那年的約定……對不起。   "
message = draft.strip()               # 去掉前後空白
message = message.replace("……", "，")  # 把刪節號換成逗號
print(message)
print(f"一共 {len(message)} 個字")
if len(message) > 50:
    print("派森：太長了，她會以為你在寫作文。")
else:
    print("派森：很好，簡單、真誠，送出吧。")
```

@level ch4_3_message
title: 一則訊息
goal: 修改 draft，寫出一則你想傳給倖芳的訊息。整理之後要在 50 個字以內，前後不能有多餘的空白。
tags: draft.strip() | .replace("……", "，") | len(message) <= 50
hint: 把 draft 引號裡的文字換成你自己想說的話。
hint: 下面的 strip() 和 replace() 會幫你整理；只要印出的字數在 50 以內就可以送出。
starter:
```python
draft = "   倖芳……好久不見……   "
message = draft.strip()
message = message.replace("……", "，")
print(message)
print(f"一共 {len(message)} 個字")
if len(message) > 50:
    print("派森：太長了，她會以為你在寫作文。")
else:
    print("派森：很好，簡單、真誠，送出吧。")
```
check:
```python
assert "message" in globals() and isinstance(message, str), "要把整理好的訊息存在 message 裡。"
assert message.strip() != "", "訊息不能是空的。"
assert message == message.strip(), "訊息前後還有空白，用 strip() 去掉吧。"
assert len(message) <= 50, "太長了（%d 個字），她會以為你在寫作文。" % len(message)
set_flag("message", message)
```
solution:
```python
draft = "   倖芳……好久不見……那年的約定……對不起。   "
message = draft.strip()
message = message.replace("……", "，")
print(message)
```
success: 「{message}」——前後的空白和刪節號都整理好了，簡單又真誠。送出吧。
@end

@phone 倖芳
你：{message}
@if gave_gift
（訊息送出不到一分鐘，畫面上出現「已讀」，接著是「對方正在輸入……」，持續了很久很久。）
倖芳：（AI 回應：倖芳一直在等主角的訊息。先針對主角傳來的「{message}」回應一句，語氣是又氣又開心，開頭可以叫他笨蛋。）
【備用台詞】倖芳：笨蛋，我等這則訊息好久了。
倖芳：約定又沒有說期限。不能讀同一間大學，那就換一個約定吧？
倖芳：畢業以後，找一個有湖的地方，我們一起去看日出。這次不准再失約了。
你：好。這次一定。
@phone off
派森：你看，有時候失約不是結束，只是換了一種方式繼續。
@cg lake_promise 兩人在湖邊看日出的約定
@else
（隔天早上，你才收到回覆。）
倖芳：（AI 回應：倖芳很驚訝也很開心收到主角的「{message}」，好久不見。先針對訊息內容回應一句。）
【備用台詞】倖芳：好久不見！看到你的訊息我好驚訝，也好開心。
倖芳：其實你不用說對不起啦，那時候我們都還好小。我現在系上常常去山裡的湖做調查，離我的湖邊夢想好像又近了一點。
倖芳：下次你回臺北，我們約在那個捷運站吧，換我請你喝飲料。
@phone off
@bg mrt_platform
@cg mrt_wave 捷運站人群中，倖芳回頭揮手
（寒假，你們在捷運站見了面，聊了很多高中的糗事。分開時，你終於說出了那句一直沒說的「謝謝你」。看著她揮手走進人群，你覺得心裡有個地方，終於放下了。）
派森：有些人出現在你的生命裡，不是為了留下來，而是為了讓你學會一些事情。
@endif
