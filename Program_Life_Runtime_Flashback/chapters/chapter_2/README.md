# 第二章：幼兒到國中 (Chapter 2)

內容依照官方大綱《專題劇情.docx》整理而成，共三個小節：2.1 記憶變數、2.2 早餐店（跑腿計算）、2.3 便利商店。

## 🗂️ 劇情流程

```
2.1 記憶變數
  ch2_1_greet（WAIT_FOR_SANDBOX：print 感想）
      └─► sandbox 成功 → AI 動態回應（提到爸媽的愛）
              └─► ch2_1_memory（回憶溜滑梯/卡通/廟裡 + WAIT_FOR_SANDBOX：建立 love 變數並 print）
                      └─► ch2_1_success
                              └─► ch2_1_hunt（變數尋寶引導，小遊戲待實作，見下方 TODO）

2.2 早餐店
  ch2_2_intro（媽媽帶你去早餐店）
      └─► 選早餐（動態按鈕，程式即時產生，不需場景先放節點）
              └─► ch2_2_teach（WAIT_FOR_SANDBOX：算早餐總價）
                      └─► ch2_2_success（🏆 成就：第一次算數）

2.3 便利商店
  ch2_3_intro（國中，教 Boolean / if / round()）
      └─► ch2_3_game（WAIT_FOR_SANDBOX：if/else 判斷找零，見下方 TODO）
              └─► ch2_3_success → 解鎖聊天 + 顯示下一章按鈕
```

## 📂 資料檔案

```text
chapter_2/data/
├── ch2_1_greet.tres
├── ch2_1_memory.tres
├── ch2_1_success.tres
├── ch2_1_hunt.tres
├── ch2_2_intro.tres
├── ch2_2_teach.tres
├── ch2_2_success.tres
├── ch2_3_intro.tres
├── ch2_3_game.tres
└── ch2_3_success.tres
```

`scripts/section_2_controller.gd` 依序播放以上檔案，並在特定段落插入動態內容（AI 回應、早餐選擇按鈕）。

## ⚠️ 待工程確認 (TODO)

1. **場景已建立，右側三區共用第一章背景圖**：`scenes/section_1.tscn` 節點結構比照 `chapter_1/scenes/section_1.tscn` 手動重建（四象限版面、StoryBox、ChapterButtons、TextbookPanel 都在），路徑跟 `section_2_controller.gd` 逐一核對過，headless 模式下已驗證可以正常載入、跑完開場對話＋沙盒＋AI 回應整條流程。ObjectArea／CodingArea／FeedbackArea 直接沿用 `chapter_1/images` 的 `actionBg.png`／`code_bg.png`／`codeoutput_bg.png`；左上角 StoryArea 依指示保持留白（純色，沒有插圖）。之後如果要有第二章專屬美術，再另外換圖即可。
2. **`SandboxManager` 需要擴充**（目前只認得單行 `print("...")`，見 `src/core/sandbox_manager.gd:13`）：
   - 2.1：需要支援變數賦值 `love = "..."`，以及字串相加／插值 `print("我愛我的" + love)`。
   - 2.2：需要支援數字變數與加法運算 `print(item1 + item2)`。
   - 2.3：需要支援 `round()`、布林比較與**多行** `if / else`——這已經超出「單行指令」的限制，建議參考下方的引擎建議。
3. **2.1 變數尋寶小遊戲**：目前只有引導對話（`ch2_1_hunt.tres`），實際「在場景裡找到物件、輸入對應型別變數」的互動尚未實作，需要地圖上的可互動物件（可以接續 `src/objects/interactable.gd.txt` 這個已經存在但未啟用的系統）。

## 💡 一個較大的建議：SandboxManager 的長期架構

隨著後面章節（第三章的 List、for、random、while、巢狀迴圈）陸續加入，靠字串比對／正則去擴充 `SandboxManager` 會越來越難維護，而且每章都要重新想一套規則。專案本身已經在用 **py4godot**（見專案根目錄 README「Setup」）串接 Python，這代表工程上其實有能力讓玩家的程式碼**真的用 Python 執行**，而不是用字串規則模擬。長期建議評估把 `SandboxManager` 從「規則比對」換成「用 py4godot 實際執行（在白名單/沙盒限制下）」，這樣才跟得上後面章節越來越複雜的教學內容。這個決定影響範圍大，建議提早跟工程端討論。
