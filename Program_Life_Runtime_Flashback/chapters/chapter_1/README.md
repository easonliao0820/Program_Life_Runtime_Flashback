# 第一章：新生之聲 (Chapter 1: The Voice of New Life)

本章節為《程式人生：跑馬燈》的起點，引導玩家進入遊戲世界，並學習最基礎的 Python 程式概念——輸出與字串。

---

## 📖 劇情背景 (Story Context)

- **場景設定**：溫馨的嬰兒房。玩家剛誕生在這個世界上，被新手父母抱在懷中。
- **劇情概要**：
  你（主角）試圖大聲哭泣，卻發現自己無法發出任何聲音。這時，虛空中傳來一個神秘的聲音（AI NPC 派森的投影）。它告訴你，這個世界是由獨特的語言與規則所構成的；如果想要發出聲音、宣告自己的存在，就必須學會對應的語法。
- **首要任務**：使用 Python 的 `print()` 函式將自己的名字「輸出」給這個世界，跨出人生的第一步。

---

## 🎯 學習目標 (Learning Objectives)

在第一章中，玩家將學習以下核心程式概念：

1. **認識 `print()` 函式**：學習如何在控制台或螢幕輸出資訊。
2. **字串 (String)**：理解如何使用單引號 `'` 或雙引號 `"` 來表示文字資料。
3. **基礎語法規則**：
   - 括號必須成對出現，如 `print(...)`。
   - 只能在引號內寫入要顯示的文字。
   - 練習閱讀並理解基本的錯誤提示（例如：缺少括號、缺少引號、使用不合規範的指令等）。

---

## 🗂️ 劇情流程 (Story Flow)

```
ch1_intro_story（開場劇情，next_interaction = NONE）
    └─► story_finished 訊號 → 版面展開動畫（Tween）
            └─► ch1_teach_story（派森教學，next_interaction = WAIT_FOR_SANDBOX）
                    └─► sandbox_waiting 訊號 → 教材按鈕出現
                            └─► 玩家執行正確程式碼（Run）
                                    └─► ch1_success_story（成功結局，next_interaction = NONE）
                                            └─► 劇情結束
```

---

## 🛠️ 章節關卡設計 (Gameplay & Sandbox Mechanics)

### 1. 關卡版面配置
第一章採用 **四象限（分屏）動態佈局**，在開場對話結束後平滑展開：
- **左上（故事與視覺區）**：顯示新生嬰兒的背景圖像。
- **左下（物件與狀態區）**：顯示當前關卡的物件狀態，含教材按鈕（於 Teach 劇情結束後才顯示）。
- **右上（程式編輯區）**：玩家輸入代碼的 `CodeEdit` 區域，預設顯示引導代碼。
- **右下（執行結果與控制台）**：包含「Run」按鈕，顯示沙盒執行的輸出結果或錯誤提示。

### 2. 對話框操作
- **滑鼠左鍵點擊對話框** 或 **按空白鍵**：推進/跳過打字機動畫。
- 進入沙盒等待（`WAIT_FOR_SANDBOX`）狀態時，點擊與空白鍵失效，必須執行程式碼才能繼續。

### 3. 沙盒限制與規則
為了引導新手，`SandboxManager` 設有以下安全與語法限制：
- **僅限單行指令**：禁止使用換行符 `\n`。
- **禁止變數宣告與模組導入**：禁止使用等號 `=` 或 `import` 關鍵字。
- **精準匹配**：必須使用 `print("你的名字")` 或 `print('你的名字')` 格式。

---

## 🧩 使用的元件與系統組件 (Components & Nodes Used)

1. **`StoryBox` (劇情對話盒)**
   - 路徑：`res://src/ui/story_box/story_box.tscn`
   - 訊號：
     - `story_finished`：劇情正常結束時發出（next_interaction = NONE）。
     - `sandbox_waiting`：進入沙盒等待狀態時發出，用來通知控制器顯示教材按鈕。
   - 輸入：左鍵點擊透過 MainBox 的 `gui_input` 處理；空白鍵透過 `_unhandled_input` 處理。

2. **`SandboxManager` (沙盒管理器單例)**
   - 類型：Autoload 全域單例（`res://src/core/sandbox_manager.gd`）
   - 功能：提供 `run_code(code)` 介面，解析並驗證玩家輸入的 Python `print` 代碼。

3. **`TextbookPanel` (教材視窗)**
   - 位於獨立 CanvasLayer（`TextbookLayer`，layer = 10），確保永遠顯示在最上層。
   - 僅在 Teach 劇情播完（進入沙盒等待）後才顯示教材按鈕。
   - 點擊背景遮罩或關閉按鈕可收起。

4. **`CodeEdit` (代碼編輯器)**
   - Godot 內建 UI 控制件，預設顯示引導語法 `print("哈囉小艾")`。

5. **動畫與過渡**
   - **`AnimationPlayer`**：播放開場 `fade_in` 背景漸入動畫。
   - **`Tween`**：於 intro 劇情結束後動態調整面板的 `size_flags_stretch_ratio` 與 `modulate:a`，實現四象限展開效果。

---

## 📂 檔案目錄結構 (Folder Structure)

```text
chapter_1/
├── audio/                        # 本章節專用音效與配樂
├── data/
│   ├── ch1_intro_story.tres      # 開場劇情（next_interaction = NONE）
│   ├── ch1_teach_story.tres      # 派森教學劇情（next_interaction = WAIT_FOR_SANDBOX）
│   └── ch1_success_story.tres    # 成功結局劇情（next_interaction = NONE）
├── images/
│   ├── baby.png                  # 嬰兒房背景圖
│   └── baby.png.import
├── scenes/
│   ├── section_1.tscn            # 第一關主要場景
│   └── test_level.tscn           # 測試用場景
└── scripts/
    └── section_1_controller.gd   # 控制器：對話引導、UI 動畫、沙盒對接
```

---

## ⚠️ 待實作功能 (Missing / TODO)

以下功能已規劃但尚未實作：

### 1. 成功後解鎖聊天功能
- **觸發時機**：玩家成功執行 `print("自己的名字")` 並完成成功結局劇情後。
- **功能描述**：解鎖與派森的自由對話介面，玩家可以向派森提問或閒聊。
- **預計串接**：呼叫 AI Bridge（Gemini API），將玩家輸入送出並動態回傳派森的回應文字，透過 `StoryBox` 或獨立聊天視窗顯示。

### 2. 進入下一章節按鈕
- **觸發時機**：聊天功能解鎖後（或成功結局劇情結束後）。
- **位置**：左上角區塊（`ObjectArea`）正中央新增一個按鈕。
- **功能描述**：點擊後切換至第二章場景。

---

## 🚀 開發與測試指引 (Development & Testing)

1. **啟動關卡**：在 Godot 編輯器開啟 `res://chapters/chapter_1/scenes/section_1.tscn` 並運行。
2. **劇情流程測試**：
   - 點擊對話框或按空白鍵推進 intro 劇情。
   - 劇情結束後確認四象限版面平滑展開。
   - 派森教學（7 句）結束後，確認系統提示出現且教材按鈕顯示。
3. **驗證沙盒功能**：
   - 輸入 `print("哈囉小艾")`，點擊 **Run**。
   - 預期右下角輸出 `哈囉小艾`，並觸發成功結局劇情。
   - 輸入不合規的代碼應顯示 `❌` 錯誤提示。
