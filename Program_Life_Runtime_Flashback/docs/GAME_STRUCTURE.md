# 遊戲整體架構

依《專題劇情_完整版.docx》與《畫面設定書.docx》建立。劇情寫在 `.story` 劇本檔裡，畫面由程式依劇本自動切換；**寫劇情、改關卡都不需要動 Godot 場景**。

## 遊戲流程

```
login_screen（登入）
  → chapters/prologue/prologue.tscn（前言動畫，按空白鍵）
  → 名字輸入（有存檔時可選「繼續旅程」）
  → GameStage：依 ChapterRegistry 一節一節播放
       第一章（含序章）→ 2.1 → 2.2 → 2.3 → 3.1 → … → 3.5 → 4.1 → … → 4.4 → 5.1 → … → 5.4 → 第六章（最後的早晨＋結局判定）
                                                         ├→ 結局一（完成度 < 0.8）
                                                         └→ 結局二（完成度 ≥ 0.8）
  → hello python ＋ 工作人員名單 → 回到登入畫面
```

每一節的年齡照劇本的「時間軸」表，寫在 `ChapterRegistry.SECTIONS` 的 `age`。

完成度 = 第一次就通過的關卡數 ÷ 關卡總數。「第一次就通過」指沒出錯、也沒按提示。門檻寫在 `ChapterRegistry.ENDING_THRESHOLD`。

## 檔案位置

| 位置 | 內容 |
|---|---|
| `src/game/core/chapter_registry.gd` | **目錄**：章節順序、年齡、色調、成就、角色代表色、背景清單 |
| `src/game/core/game_state.gd` | 玩家名字、旗標（`gave_gift`…）、關卡成績、成就、存讀檔（Autoload） |
| `src/game/core/game_flow.gd` | 場景切換、下一節、結局判定（Autoload） |
| `src/game/core/python_runner.gd` | 真的執行玩家的 Python，並用關卡的 `check` 判斷是否過關（Autoload） |
| `src/game/core/story_parser.gd` | 解析 `.story` 劇本 |
| `src/game/core/error_explainer.gd` | 把錯誤翻成派森的白話提示 |
| `src/game/stage/` | 主舞台 `game_stage` ＋ 劇本執行器 `story_runner` |
| `src/game/modes/` | 程式關卡、探索、回憶三種模式（劇情模式就是舞台本身） |
| `src/game/components/` | 對話框、派森光球、立繪、程式碼卡片、選項、手機、年齡翻牌、成就彈窗、系統選單、名字輸入 |
| `chapters/<章>/story/*.story` | **劇本**，一節一個檔案 |
| `tests/full_playthrough_test.tscn` | 自動測試 |

## 畫面風格

- **劇情為主**：任何時候劇情都留在畫面上。
  - 進入程式關卡或探索模式時，場景和對話框會縮進左上的「劇情區」，沿用舊版 section_1 的四象限版面：
    - 左上：劇情區
    - 左下：任務卡／清單
    - 右上：程式區
    - 右下：輸出區
  - 派森的提示、錯誤解說、過關台詞都說在劇情區的對話框裡，也會記進「回顧」。
  - 回憶模式和手機畫面時，下方的對話框也一直留著。
- **沿用舊版風格**：
  - 配色：深藍半透明對話框、金色細邊、捷運藍名字牌、米色卡片。主色調同 `ThemeManager`。
  - 程式區和輸出區用舊版的像素電路板框，以 nine-patch 套用，邊框不變形。
  - 執行按鈕用 `run.png`。
- **轉場**：黑色調，風格跟前言畫面一致，並盡量減少場景切換。
  - 只有換「章」時才進全黑轉場：先打字顯示這一章的程式名言（`ChapterRegistry.CHAPTER_QUOTES`），再顯示章節名稱與年齡；按空白鍵可跳過。
  - 同一章裡換小節不切黑畫面，只在頂端顯示一條小字。
  - 小節最後的（轉場）會自動略過，避免連續淡出兩次。
  - 連續的關卡、探索之間會留在四象限，中間的幾句話直接在劇情區播，不會來回切換。
- **台灣風格**：
  - 場景名牌做成捷運站名牌。
  - 選項做成早餐店點餐單。
  - 成就是紅色「成就」印章。
  - 任務卡上的數字用便利商店價格牌。
- 共用的顏色與版面位置都在 `src/game/ui/ui_kit.gd`（`NAVY`、`GOLD`、`MRT_BLUE`、`SPLIT_*`）。

## 畫面模式對照（畫面設定書 第二節）

| 設定書 | 劇本寫法 | 實作 |
|---|---|---|
| 2.1 劇情模式 | 一般對話、旁白 | `game_stage.gd` ＋ `dialogue_box.gd` |
| 2.2 程式關卡模式 | `@level … @end` | `modes/coding_mode.gd` |
| 2.3 探索模式 | `@explore … @end` | `modes/explore_mode.gd` |
| 2.4 回憶模式 | `@memory … @end` | `modes/memory_mode.gd` |
| 2.5 名字輸入 | （自動） | `components/name_input.gd` |
| 2.5 成就彈窗 | `成就：名稱` | `components/achievement_popup.gd` |
| 2.5 章節轉場 | （換章時自動；名言在 `CHAPTER_QUOTES`，年齡在目錄設定） | `components/age_transition.gd` |
| 2.5 選項按鈕 | `@choice … @end` | `components/choice_menu.gd` |
| 2.5 手機畫面 | `@phone 名字` … `@phone off` | `components/phone_frame.gd` |
| 跟角色聊天（延續舊版聊天框） | `@set chat_unlocked = True`（第一章第一關過後解鎖；只在程式關卡、探索模式時出現，劇情模式不顯示） | `components/chat_bar.gd`：主角可以選擇跟派森或這一節出現過的角色說話，各自用角色人設（`GameStage.PERSONAS`）回答；回答顯示在泡泡裡，不會蓋掉劇情；每個角色聊過的話會存檔並帶給 AI，角色會記得 |
| 2.5 快轉演出 | `@montage …` | `game_stage.gd` 的 `montage()` |

## 劇本語法（`.story`）

可以直接從 docx 貼上，再補上 `@` 指令。

### 從 docx 直接貼上就能用的寫法

```
派森：你長高了呢，真可愛。           ← 對話，名字牌用角色代表色
（跟在高大背影後面的你覺得……）       ← 旁白，斜體灰字、不顯示名字牌
心聲：為什麼哭不出來？！              ← 心聲，虛線邊框
系統：變數就像一個盒子……              ← 系統說明
成就：第一次算數                      ← 解鎖成就（名稱要跟 ChapterRegistry.ACHIEVEMENTS 一致）
（轉場）                              ← 淡出淡入
派森：（AI 回應：回應玩家的感想……）   ← AI 即時生成
【備用台詞】派森：看得出來……           ← AI 失敗、關閉或逾時時使用
【設計】……／【選項】……／# 註解        ← 遊戲不顯示
```

台詞裡可以用 `{userName}` 和劇本變數，例如 `{food}`、`{message}`。

主角視角：寫成 `你：……` 的台詞，名字牌會顯示玩家輸入的名字。「回顧」裡的劇情與聊天紀錄都會跟著存檔。

### 程式碼卡片

用 ```` ```python ```` 包起來，會顯示在畫面上方並有「執行看看」按鈕；改成 ```` ```text ```` 就沒有按鈕。

### 演出指令

| 指令 | 說明 |
|---|---|
| `@bg 背景鍵 [色調]` | 換背景（鍵見 `ChapterRegistry.BACKGROUNDS`） |
| `@cg 名稱 說明` | 顯示 CG；圖片放在 `assets/cg/名稱.png`，沒有圖時顯示說明文字 |
| `@show 角色 [left/right/center] [表情]`、`@hide 角色/all` | 立繪 |
| `@orb mood happy/wise/worried/sad/fading`、`@orb fade 0.3`、`@orb pos x y` | 派森光球 |
| `@flash white/gold/blue`、`@shake 秒`、`@wait 秒` | 效果 |
| `@eyes_close`、`@eyes_open`、`@focus` | 序章：先閉眼（全黑）→ 換背景 → 慢慢睜眼、對焦。要先 `@eyes_close` 再 `@bg`，才不會先看到圖又變黑 |
| `@saturation 0.2` | 降低彩度（3.3 靈魂狀態），`1` 恢復 |
| `@frame on/off` | 相片邊框 |
| `@bgm 名稱`、`@sfx 名稱` | 播放 `assets/audio/名稱.ogg`（沒有檔案就略過） |
| `@code_line N` | 程式碼卡片的第 N 行亮起（解說模式，例如 3.1 車廂裡派森逐行解說）；`@code_line 0` 全部恢復 |
| `@photo 32 歲` | 「相片翻頁」：閃一下像翻到下一張相片，角落留一個年齡標籤（5.4 用）；`@photo off` 收起來 |
| `@credits` | hello python ＋ 工作人員名單 |

### 流程指令

```
@if gave_gift                ← 條件用 Godot Expression，可用 and / or / not / == / in
…
@elif dream_style == "B"
…
@else
…
@endif

@set food_price = 35         ← 設定變數
@input dream 你的夢想是什麼？  ← 玩家自由輸入（手機畫面開著時就在手機裡打字）
@jump ch6_end1               ← 跳到某一節
@ending                      ← 依完成度跳到結局一或結局二
```

### 區塊（都要用 `@end` 結束）

**選項**：

```
@choice food 想吃什麼呢？
- 培根蛋吐司　35 元 = 培根蛋吐司     ← 「顯示文字 = 存進變數的值」
@end
```

**AI 分類**（例如 3.2.1 判斷夢想風格；AI 失敗時用關鍵字判斷，都沒有對到就用最後一項）：

```
@classify dream_style dream          ← 把變數 dream 分類，結果存進 dream_style
- A: 感性與告白風 | 一起, 跟你, 喜歡
- B: 實際與勵志風 | 錢, 賺, 工作
- C: 其他
@end
```

**探索**：

```
@explore ch3_1_bag
title: 出門前找東西
list: bag                 ← 結果存進變數 bag，產生的程式碼存進 explore_code
start: 手機, 錢包, 漫畫     ← 一開始就在清單裡（可以點掉）
capacity: 5               ← 容量條
timer: 90                 ← 倒數秒數（時間到自動出發）
hidden_count: 5           ← 只提示「共有 5 樣」
- 悠遊卡                   ← 點了會產生 bag.append("悠遊卡")
- 媽媽的年齡 => mom_age = 30 | 說明     ← 自訂程式碼（2.1 回憶盒子）
@end
```

**程式關卡**：

````
@level ch2_2_breakfast        ← id 全遊戲不能重複
title: 算算早餐錢
goal: 任務卡上的說明，可以用 {food} 這類變數
tags: 培根蛋吐司 35 元 | 付 100 元      ← 價格牌標籤
hint: 第一個提示              ← 可以寫很多行，依序顯示
starter:
```python
food = <<food_price>>         ← 程式碼裡用 <<變數>> 代入（不用 {}，因為 f-string 也用大括號）
```
check:
```python
assert str(food + drink) in lines, "沒過關時派森說的話"
set_flag("gave_gift", "手作巧克力" in bag)   ← 把結果存回劇情旗標
```
solution:
```python
（參考解答：自動測試會用它確認這關真的過得了）
```
success: 過關時派森說的話
counts: false                 ← 不列入結局判定（預設 true）
@end
````

`check` 是在玩家程式碼跑完之後執行的 Python，可以使用：

- 玩家的所有變數與函式
- `out`：印出的全部文字
- `lines`：印出的文字，一行一個元素
- `code`：玩家寫的原始碼
- `set_flag(名稱, 值)`：把結果存回劇情旗標

用 `assert 條件, "提示"` 判斷，失敗時派森會說出提示。

**回憶**：

```
@memory 把回憶接起來
cg: 第一片完成後顯示的說明
@level … @end              ← 五個關卡，依序解鎖
@end
```

## 美術、音效放哪裡

都是**檔名對上就自動取代佔位圖**，不用改程式。

| 素材 | 路徑 | 備註 |
|---|---|---|
| 背景 | `assets/backgrounds/<背景鍵>.png` | 鍵見 `ChapterRegistry.BACKGROUNDS`，例如 `breakfast_shop.png`；已經在別的資料夾的舊素材可以在 `ChapterRegistry.ART` 對應（目前：產房＝`baby.png`、出生 CG＝`parentsfull.png`） |
| CG | `assets/cg/<名稱>.png` | 名稱是劇本 `@cg` 的第一個字，例如 `birth.png` |
| 立繪 | `assets/characters/<角色>.png` 或 `<角色>_<表情>.png` | 例如 `倖芳_微笑.png` |
| 音效／音樂 | `assets/audio/<名稱>.ogg` | 例如 `heartbeat.ogg`、`baby_cry.ogg` |
| 字型 | `assets/fonts/NotoSansTC-Regular.ttf`、`JetBrainsMono-Regular.ttf` | **網頁版一定要放中文字型**，不然中文會變方塊 |

## Python 執行環境

- **桌面版**：使用系統的 Python 3。可以在 `.env` 加上 `PYTHON_PATH=/路徑/python3` 指定。
- **網頁版**：自動從 CDN 載入 Pyodide（第一次大約要等 5–10 秒）。
- **都沒有**：退回舊的 `SandboxManager`，只支援單行 `print`。
- 玩家程式的限制：只能 `import random`、`math`，執行步數有上限（防無限迴圈）；`input()` 從關卡的 `stdin:` 讀取。

## 匯出注意

`.story` 不是 Godot 的資源檔，**匯出時要在 Export → Resources → Filters to export non-resource files 加上 `*.story`**，否則劇本不會被打包。

## 測試

```bash
godot --headless --path Program_Life_Runtime_Flashback res://tests/full_playthrough_test.tscn
```

測試會做三件事，全程使用另一個存檔檔案，不會蓋掉玩家存檔：

1. 解析全部劇本，列出語法錯誤。
2. 每一關的 `solution` 都要能通過 `check`。
3. 自動駕駛從第一章（含序章）玩到結局二，再從第六章玩到結局一。

**改了劇本請跑一次。**

開發時也可以打開記憶地圖（右上「設定」→「開啟記憶地圖」），按「全部解鎖（開發用）」後點任何一節直接跳過去。程式關卡在開發版本會多一顆「略過（開發用）」按鈕。

## 與舊程式的關係

- `chapters/chapter_1~3/scenes/section_1.tscn` 與各自的 controller 都**沒有刪除**，可以當參考；新流程不再經過它們。劇情內容已依 docx 完整版移到 `.story`。
- `StorySystem`、`SandboxManager`、`AiBridge`、`PauseMenu`、`ProgressManager` 等 autoload 都保留。
  - `AiBridge` 新增了 `ask()`：一定會回傳結果，失敗時回傳備用台詞。
  - `SandboxManager` 用作沒有 Python 時的備案。
- 原本的關卡地圖（`src/ui/level_select`，標題 MEMORY LOAD）保留原本的外觀，改成新架構的章節選擇：
  - 依 `ChapterRegistry` 自動排出全部小節，第六章之後分岔成兩個結局。
  - 進度看 `GameState`：走過的小節會解鎖，播完的小節打勾。
  - 點卡片就從那一節開頭開始。
  - 縮圖放在 `assets/thumbnails/<小節id>.png`。
  - 入口：系統選單「設定」、名字輸入畫面、暫停選單的「返回地圖」。

## 還沒做的事

- 正式美術、音效、字型（目前是色調漸層＋剪影佔位）。
- Google 登入與 MongoDB 雲端存檔（目前存在本機 `user://plrf_save.json`）。
- 網頁版的 Pyodide 還沒有實際匯出測試過。
