# 第三章：高中 (Chapter 3)

內容依照官方大綱《專題劇情.docx》整理而成，共四個小節：3.1 捷運（List）、3.2 學測 100 天（for 迴圈 + 倖芳劇情分支）、3.3 隨機保佑（random / while）、3.4 准考證檢查（巢狀 for 迴圈），最後轉場進入大學。

## 🗂️ 劇情流程

```
3.1 捷運
  ch3_1_intro（WAIT_FOR_SANDBOX：建立 bag 並 append 想帶的東西）
      ├─► 有帶「禮物」 → ch3_1_branch_a（捷運上遇見倖芳、送禮）
      └─► 沒帶「禮物」 → ch3_1_branch_b（沒遇到倖芳，命運殘酷的結局）

3.2 學測 100 天
  ch3_2_intro
      ├─►（若 3.1 有送禮）ch3_2_dream_prompt → 借用聊天框讓玩家輸入夢想
      │       → AI 以倖芳口吻回應（語氣由 Gemini 依內容自行拿捏）→ ch3_2_pledge（約定考同間大學）
      └─►（若沒送禮）直接跳過對話
      └─► ch3_2_for（for 迴圈倒數 100 天讀書蒙太奇，系統敘事播放）

3.3 隨機保佑
  ch3_3_intro（廟裡擲筊教學）
      └─► 🙏 擲筊小遊戲（動態按鈕，連續 3 次聖杯才過關）
              └─► ch3_3_success

3.4 准考證檢查
  ch3_4_intro
      └─► 背包檢查小遊戲（動態勾選物品，對照 5 樣必帶物品）
              ├─► 全對 → ch3_4_success → 轉場進大學（教授期末考開場）→ 解鎖聊天 + 下一章按鈕
              └─► 沒對齊 → 提示還缺什麼，可重選
```

## 📂 資料檔案

```text
chapter_3/data/
├── ch3_1_intro.tres
├── ch3_1_branch_a.tres      # 有送禮物
├── ch3_1_branch_b.tres      # 沒送禮物
├── ch3_2_intro.tres
├── ch3_2_dream_prompt.tres  # 只有送禮分支會用到
├── ch3_2_pledge.tres
├── ch3_2_for.tres
├── ch3_3_intro.tres
├── ch3_3_success.tres
├── ch3_4_intro.tres
└── ch3_4_success.tres
```

`scripts/section_3_controller.gd` 用一個字串狀態機 `_step` 依序（含分支）播放以上檔案，並用程式動態產生擲筊按鈕、背包勾選按鈕，不需要場景預先放這些節點。

## ⚠️ 待工程確認 (TODO)

1. **場景已建立，右側三區共用第一章背景圖**：跟第二章一樣，`scenes/section_1.tscn` 已經比照 `chapter_1` 的節點結構手動重建並掛上 `section_3_controller.gd`，路徑核對過，headless 模式下驗證可以正常載入。ObjectArea／CodingArea／FeedbackArea 沿用 `chapter_1/images` 的 `actionBg.png`／`code_bg.png`／`codeoutput_bg.png`；左上角 StoryArea 保持留白。之後如果要有第三章專屬美術，再另外換圖即可。
2. **`SandboxManager` 需要支援 List**：3.1 需要 `bag = []`、`bag.append("...")`、`bag.remove("...")`，這是目前 `sandbox_manager.gd` 完全沒有的能力，跟第二章列出的擴充需求一樣，建議一併規劃（見 `chapter_2/README.md` 裡「SandboxManager 長期架構」的建議）。
3. **一個我修正過的小地方**：原文件裡「請在地圖上尋找你要帶上的五個物品」但 `required` 清單只列了 4 項（准考證/身分證/筆/橡皮擦），跟後面「count == 5」對不上。我補了「2B鉛筆」湊成 5 項，讓判斷邏輯一致——如果實際希望是別的物品組合，請再調整 `ch3_4_intro.tres` 和 `section_3_controller.gd` 裡的 `REQUIRED_ITEMS`/`CANDIDATE_ITEMS`。
4. **第四章（大學）尚未存在**：`_on_next_chapter_pressed()` 目前只顯示過場文字，沒有切場景，避免崩潰；docx 裡大學的內容目前只寫到「教授：今天期末考」這句開場，後面還沒有大綱。
