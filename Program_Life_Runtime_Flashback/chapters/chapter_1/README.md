# 第一章：新生之聲 (Chapter 1: The Voice of New Life)

本章節為《程式人生：跑馬燈》的起點，引導玩家進入遊戲世界，並學習最基礎的 Python 程式概念——輸出與字串。

---

## 📖 劇情背景 (Story Context)

- **場景設定**：溫馨的嬰兒房。玩家剛誕生在這個世界上，被新手父母抱在懷中。
- **劇情概要**：
  你（主角小艾）試圖大聲哭泣，卻發現自己無法發出任何聲音。這時，虛空中傳來一個神秘的聲音（AI 導師派森的投影）。它告訴你，這個世界是由獨特的語言與規則所構成的；如果想要發出聲音、宣告自己的存在，就必須學會對應的語法。
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

## 🛠️ 章節關卡設計 (Gameplay & Sandbox Mechanics)

### 1. 關卡版面配置
第一章採用了 **四象限（分屏）動態佈局**，在開場對話結束後平滑展開：
- **左上（故事與視覺區）**：顯示新生嬰兒的背景圖像與劇情文字。
- **左下（物件與狀態區）**：顯示當前關卡的物件狀態（目前為待解鎖）。
- **右上（程式編輯區）**：玩家輸入代碼的 `CodeEdit` 區域，預設顯示引導代碼。
- **右下（執行結果與控制台）**：包含「Run」按鈕，顯示沙盒執行的輸出結果或錯誤提示。

### 2. 沙盒限制與規則
為了引導新手，本關的 Python 沙盒執行器（`SandboxManager`）設有以下安全與語法限制：
- **僅限單行指令**：禁止使用換行符 `\n`。
- **禁止變數宣告與模組導入**：禁止使用等號 `=` 或 `import` 關鍵字。
- **精準匹配**：必須使用 `print("你的名字")` 或 `print('你的名字')` 格式。

---

## 🧩 使用的元件與系統組件 (Components & Nodes Used)

本章節的場景與程式串接了以下關鍵元件：

1. **`StoryBox` (劇情對話盒)**：
   - 檔案路徑：`res://src/ui/story_box/story_box.tscn`
   - 功能：加載對話資源 (`DialogueData`)，以打字機效果播放開場劇情，並在播放完畢時發送 `story_finished` 訊號。
2. **`SandboxManager` (沙盒管理器單例)**：
   - 類型：Autoload 全域單例 (`res://src/core/sandbox_manager.gd`)
   - 功能：提供 `run_code(code)` 介面，解析玩家輸入的 Python `print` 代碼，過濾不安全或不符規則的輸入，並返回結果字串。
3. **`CodeEdit` (代碼編輯器)**：
   - 類型：Godot 內建 UI 控制件
   - 功能：提供多行程式編輯區，預設顯示引導語法 `print("哈囉{userName}")`。
4. **控制台與排版元件 (UI Elements)**：
   - **`HBoxContainer` / `VBoxContainer`**：用於分割故事區、物件區、程式編輯區與執行結果區，構建四象限佈局。
   - **`TextureRect` (背景圖顯示)**：顯示主角嬰兒時期的插畫 `baby.png`。
   - **`Label` (輸出控制台)**：顯示沙盒的回傳結果或編譯報錯。
   - **`Button` (執行按鈕)**：點擊後抓取 `CodeEdit` 的文字傳給 `SandboxManager` 運行。
5. **動畫與過渡元件 (Animations & Transitions)**：
   - **`AnimationPlayer`**：負責播放開場的 `fade_in` 背景漸入動畫。
   - **`Tween` (程式插值動畫)**：在 `section_1_controller.gd` 中，於劇情結束時動態調整右側面板的 `size_flags_stretch_ratio` 從 `0.01` 到 `3.0`，並配合 `modulate:a` (不透明度) 的漸變，實現平滑展開的視覺效果。

---

## 📂 檔案目錄結構 (Folder Structure)

本章相關的實作檔案均位於 `chapters/chapter_1/` 目錄下：

```text
chapter_1/
├── audio/                   # 本章節專用音效與配樂
├── data/
│   └── ch1_intro_story.tres # 開場劇情的對話資源 (DialogueData)
├── images/
│   ├── baby.png             # 嬰兒房與主角背景圖
│   └── baby.png.import
├── scenes/
│   ├── section_1.tscn       # 第一關主要場景（包含 UI 佈局與動畫）
│   └── test_level.tscn      # 測試與開發用場景
├── scripts/
│   ├── section_1_controller.gd  # GDScript 控制器，負責對話引導、UI 動畫及沙盒對接
│   └── section_1_controller.py  # Python 版本控制器（備用與架構參考）
└── sprites/                 # 其他小型的 2D 精靈或圖示
```

---

## 🚀 開發與測試指引 (Development & Testing)

1. **啟動關卡**：
   - 在 Godot 編輯器中開啟 `res://chapters/chapter_1/scenes/section_1.tscn` 並運行。
2. **劇情流程**：
   - 點擊對話框推進劇情，結束時 `section_1_controller.gd` 將會自動觸發展開動畫，將右側的編輯器與下方反饋區淡入並拉伸顯示。
3. **驗證沙盒功能**：
   - 在程式編輯區輸入 `print("小艾")`，點擊 **Run**。
   - 預期右下角控制台應正確輸出 `小艾`，並附帶 `✨ 系統：已記錄你的名字` 的提示。
   - 輸入不合規的代碼（例如多行或無引號），應顯示相應的紅叉叉 `❌` 錯誤提示。
