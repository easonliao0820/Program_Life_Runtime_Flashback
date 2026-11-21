# 還缺的音樂和音效

來源：Pixabay（pixabay.com，不用標註出處）。下載後改成「檔名」那欄的名字（.mp3 / .ogg / .wav 都可以），放進 `assets/audio/`。

- ✅ = 劇本裡已經有 `@bgm` / `@sfx` 指令，檔案放進去就會響
- 其他的放好檔案後，再到對應劇本加上指令
- 背景音樂挑 1～3 分鐘、可以重複播放的；音效挑 1～3 秒、開頭沒有空白的
- 試聽：`Godot --path . res://tests/bgm_preview.tscn`（音量和遊戲裡一樣）
- 每首大小聲不同，在 `src/game/core/game_flow.gd` 的 `BGM_GAIN` 補成差不多大聲；總音量是 `BGM_VOLUME`
- 優先順序：先找 `childhood`、`school`、`campus`、`office`、`farewell`，每章就都有音樂

## 背景音樂（Pixabay → 音樂）

- [x] `prologue`：前言黑畫面 → 第一章產房（第一章結尾淡出）
- [x] `childhood`：`childhood music box`、`cute ukulele`
  - 第二章童年：2.1 廟（temple_day）、客廳，2.2 媽媽牽手去早餐店，2.3 便利商店
- [x] `school`：`lofi study`、`calm piano lofi`
  - 第三章高中：3.1 房間收書包、3.2 學測倒數蒙太奇、3.4 學測當天清晨
- [x] `tension`：`suspense ambient`、`tense piano`
  - 3.3 奶奶在廟裡拜拜（grandma_prayer）、醫院醒來；5.2 Claire 在會議室質問
- [x] `campus`：`upbeat acoustic`、`happy indie`
  - 第四章大學：4.1 宿舍與教室、4.2 熱炒店慶功宴、4.4 畢業典禮
- [x] `romance`：`romantic piano soft`
  - 3.1 捷運上送禮物（mrt_gift）、4.3 湖邊看日出的約定（lake_promise）、5.4 成家（湖邊日出、夕陽）
- [x] `office`：`corporate background`、`office ambient`
  - 第五章出社會：5.1 辦公室、5.2 加班的黃昏辦公室、5.3 壓力
- [x] `warm` ✅：`warm piano`、`heartwarming`
  - 5.2 報表過關、Cindy 比讚；5.1 回家送媽媽早餐（mom_breakfast）
- [x] `nostalgia`：`nostalgic piano`、`memories emotional`
  - 5.4 回憶相簿（photo_room）、第六章最後的早晨（breakfast_shop）
- [x] `farewell`：`sad emotional piano`、`farewell strings`
  - 結局一：湖邊夕陽、派森化成光點（ending1），接工作人員名單
- [x] `hope`：`hopeful cinematic`、`inspiring piano`
  - 結局二：湖邊清晨 → 醫院、擁抱派森（ending2），接工作人員名單

## 音效（Pixabay → 音效）

### 第一章
- [ ] `baby_cry` ✅：`newborn baby cry`（print 成功、閃白光時第一聲哭）
- [x] `heartbeat` ✅：輸入名字畫面，音量 -14 dB，循環播放
- [ ] `muffled`：`underwater muffled`（哭不出來、畫面晃動時聲音悶悶的）

### 第二、三章
- [ ] `temple_bell`：`temple bell`、`singing bowl`（2.1 廟裡許願、3.3 奶奶拜拜閃金光時）
- [ ] `shop_door`：`convenience store door chime`（2.3 走進便利商店）
- [x] `door_warning` ✅：3.1 捷運月台，車門關上（剪成 4 秒）
- [ ] `train`：`subway train interior`（3.1 捷運車廂環境聲）
- [ ] `page_flip`：`page turn`、`pencil writing`（3.2 學測倒數讀書蒙太奇）
- [ ] `alarm_clock`：`alarm clock ring`（3.4 學測當天清晨）
- [ ] `hospital`：`hospital monitor beep`（3.3 醫院醒來、5.4 爸媽住院、結局二醫院）

### 第四、五章
- [ ] `cheers`：`glasses clink cheers`、`restaurant crowd`（4.2 熱炒店慶功宴）
- [ ] `message`：`phone notification`（4.3 一則訊息）
- [ ] `applause`：`applause crowd`（4.4 畢業典禮、5.4 Claire 的歡送會）
- [x] `clock_tick` ✅：5.2 會議開始前，Claire 把你叫進會議室（剪成 8 秒、放大音量）
- [x] `typing` ✅：5.1 報到第一天、5.2 被退件回座位改報表

### 第六章與通用（要改程式才會響）
- [ ] `sparkle`：`magic sparkle`、`shimmer`（派森出現、結局化成光點、`@flash gold`）
- [ ] `success`：`success chime`、`level up`（程式題過關）
- [ ] `error`：`error soft`、`wrong buzz`（程式執行出錯，音量要小）
- [ ] `achievement`：`achievement unlock`（跳出成就）
