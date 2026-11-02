# 程式人生：跑馬燈

> 如果人生是一段程式碼，你會如何編寫你的回憶？

《程式人生：跑馬燈》（Program Life: Runtime Flashback）是一款結合 Python 教學與台灣生活情境的敘事遊戲。玩家透過早餐店、便利商店、校園及職場等人生片段學習程式，並由導師「派森」提供錯誤解釋與引導提示。

本文件依目前工作目錄的實作整理；本機程式與設定不代表已部署到 AWS 或完成 Web 驗收。

## 目前功能與開發狀態

- **遊戲主線**：Godot 4.6、Compatibility 模式，以 `GameStage` 播放各章 `.story` 劇本；第一至第三章的舊場景仍保留。
- **Google 登入**：桌面 OAuth 取得 Google ID Token，由 AWS FastAPI 後端驗證身分。
- **登入後跳轉**：有有效本機存檔時，直接進入記錄的小節開頭；無存檔時建立初始進度並進章節選擇。訪客仍走前言流程。
- **AI 提示**：Godot 經 AWS `/ai/generate` 取得 Gemini 回覆，訪客與已登入玩家皆可使用，預設沒有每日配額或玩家冷卻時間。
- **存檔**：目前使用本機 JSON，尚未依 Google 帳號隔離，也未串接 DynamoDB。
- **Web**：已有 Pyodide 執行路徑；瀏覽器登入、CORS、程式中斷與完整 Web demo 仍需整合及實測。

## 專案目錄

外層是 Git repository，內層同名資料夾才是 Godot 專案。

```text
Program_Life_Runtime_Flashback/
├─ README.md
└─ Program_Life_Runtime_Flashback/
   ├─ project.godot
   ├─ login_screen.tscn
   ├─ backend/                 # FastAPI、AI 政策、Gemini 服務與 Lambda 入口
   ├─ template.yaml            # 既有 AWS SAM 部署設定
   ├─ chapters/                # 各章場景、劇本與對話資料
   ├─ src/
   │  ├─ core/                 # AiBridge、簡易沙盒與 AuthManager
   │  ├─ game/                 # GameFlow、GameState、PythonRunner 與新主線畫面
   │  └─ ui/                   # Google 登入、舊程式面板與章節地圖
   ├─ tests/                   # 原有劇本／關卡測試
   └─ docs/
      └─ GAME_STRUCTURE.md
```

劇本語法、畫面模式與素材位置請參閱 [遊戲架構說明](Program_Life_Runtime_Flashback/docs/GAME_STRUCTURE.md)。舊文件若與目前程式不同，以原始碼為準。

## 開啟遊戲

1. 安裝 Godot 4.6.x，匯入 [project.godot](Program_Life_Runtime_Flashback/project.godot)。
2. 確認渲染模式為 **Compatibility**。
3. 桌面程式關卡需安裝 Python 3。`PythonRunner` 會嘗試尋找 `py`、`python` 或 `python3`；也可在內層專案 `.env` 設定 `PYTHON_PATH`。
4. 執行專案，從登入頁選擇 Google 登入或訪客登入。

目前新主線透過 `PythonRunner` 呼叫系統 Python／Pyodide，不以 py4godot 作為執行入口。專案仍可能留有舊擴充設定；若出現 py4godot DLL 或 `StorySystem` Autoload UID 載入錯誤，需檢查既有擴充與 Autoload 路徑。

## Google 登入與存檔

```text
GoogleAuth 取得 Token → AWS /auth/google 驗證
  → PlayerSession 保存玩家資訊、AuthManager 保存 ID Token
  → GameFlow.start_after_login()
     ├─ 有有效本機進度：直接繼續記錄小節
     └─ 無進度／小節無法對應：章節選擇
```

- [google_auth.gd](Program_Life_Runtime_Flashback/src/ui/login/google_auth.gd)：Google 授權、PKCE、本機 TCP 回呼與 Token 交換。目前為桌面流程，仍會讀取 `.env` 的 `GOOGLE_OAUTH_CLIENT_SECRET`。
- [google_login.gd](Program_Life_Runtime_Flashback/src/ui/login/google_login.gd)：呼叫 AWS 驗證，成功後交給 GameFlow 切換畫面。
- [auth_manager.gd](Program_Life_Runtime_Flashback/src/core/network/auth_manager.gd)：記憶體中的 ID Token 與本機到期管理；尚無自動刷新。
- [player_session.gd](Program_Life_Runtime_Flashback/src/ui/login/player_session.gd)：驗證後的 Google `sub`、姓名、email、頭像與登入狀態。

新主線存檔位於 `user://plrf_save.json`；舊 `ProgressManager` 另使用 `user://save_data.json`。`user://` 是 Godot 玩家資料目錄，不是專案根目錄；可用編輯器的「開啟使用者資料資料夾」查看。

目前不同 Google 帳號與訪客可能共用同一份本機進度。未來 DynamoDB 應由後端驗證 Token 後，使用 Google `sub` 辨識資料擁有者；不能只相信前端傳來的玩家 ID。`/save`、雲端同步及玩家資料庫目前尚未實作。

## AI 與 AWS 後端

```text
程式錯誤／聊天／劇情 → AiBridge → Lambda /ai/generate
  → AI Access Policy → ai_service → SSM 讀取金鑰 → Gemini
  ← 回覆文字；失敗時由 Godot 使用備用台詞
```

- [AiBridge](Program_Life_Runtime_Flashback/src/core/ai_bridge.gd) 保留 `translate_error()`、`call_openai()`、`ask()` 與 `ai_response_received`。`call_openai` 為歷史介面名稱，實際走 AWS／Gemini。
- Godot 不讀取 Gemini `API_KEY`，也不需要取得 Google Token 才能使用 AI。
- [main.py](Program_Life_Runtime_Flashback/backend/main.py) 提供 `GET /health`、`POST /auth/google`、`POST /ai/generate`。
- [ai_service.py](Program_Life_Runtime_Flashback/backend/ai_service.py) 在 Lambda 從既有 SSM Parameter Store `/godot-backend/API_KEY` 取得解密金鑰，不回傳給 Godot。
- [ai_access_policy.py](Program_Life_Runtime_Flashback/backend/ai_access_policy.py) 將 AI 政策與登入／私人資料驗證分開。

AI 請求為 `{"prompt":"完整提示詞"}`，成功回覆為 `{"text":"回覆文字"}`。完整 prompt 上限 4000 字元、生成上限 512 Token、回傳文字上限 4000 字元，並有逾時及在途請求保護；沒有自動重試。

政策環境變數目前預設皆為 `false`：

- `AI_REQUIRE_LOGIN`：只有設為 `true` 才要求後端驗證 Bearer Google ID Token；目前 Godot 不傳 Token，啟用前須另調整客戶端。
- `AI_RATE_LIMIT_ENABLED`、`AI_DAILY_QUOTA_ENABLED`：僅預留，尚未實作。設為 `true` 會回 503，不代表已有限流或配額。

匿名 AI 不代表私人資料公開：`/auth/google` 始終驗證 Token，未來存檔／玩家 API 也必須獨立驗證。公開 AI API 可被外部直接呼叫並產生成本；目前的程序內併發保護不是全域限流或預算上限。

## 本機啟動後端

以下從內層 Godot 專案目錄執行。建議使用 Python 3.12，與 Lambda runtime 一致：

```powershell
py -3.12 -m venv .venv-backend
.\.venv-backend\Scripts\python.exe -m pip install -r backend/requirements.txt
.\.venv-backend\Scripts\python.exe -m uvicorn main:app --app-dir backend --reload
```

若已有 `.venv-backend`，可跳過建立虛擬環境。後端啟動必須提供 `GOOGLE_OAUTH_CLIENT_ID`；本機可透過環境變數或內層 `.env` 設定，且須與前端 Google Client ID 對應。

後端非 Lambda 本機模式可使用 `API_KEY` 環境變數；未提供時會嘗試讀取 SSM。Lambda 一律使用 SSM。`GEMINI_MODEL` 可覆寫模型，預設值與可用性請依實際帳號確認。

遊戲目前指向既有 AWS URL，啟動本機後端不會自動切換。若需本機串接，同步修改 `google_login.gd` 的 `BACKEND_URL` 與 `ai_bridge.gd` 的 `api_url`（後者包含 `/ai/generate`）。

不要提交 `.env`、完整 Token、Client Secret、Gemini Key 或 AWS 長期憑證；Web 發佈時也不要將 `.env`、後端與 `.aws-sam` 打包成玩家可下載資產。

## 程式執行與目前限制

程式執行仍在玩家電腦／瀏覽器，**不是在 Lambda 執行玩家程式**。

- 新主線使用 [PythonRunner](Program_Life_Runtime_Flashback/src/game/core/python_runner.gd)：桌面系統 Python、Web Pyodide；找不到執行環境時退回簡易模式。
- 舊章節仍使用 [SandboxManager](Program_Life_Runtime_Flashback/src/core/sandbox_manager.gd)：只解析單行 `print("字串")`，不支援變數、list 或多行 Python。
- 獨立 [CodingPanel](Program_Life_Runtime_Flashback/src/ui/coding_panel/coding_panel.gd) 仍同步呼叫本機 Python，AI 錯誤分析尚為 TODO，不適合直接用於 Web。
- 最新 PythonRunner 已取消 builtins／import 白名單，沒有記憶體、步數與輸出量上限；桌面只有 10 秒程序逾時，不能視為完整安全隔離。
- Web Python 同步執行，尚無 Worker／執行中斷機制；無限迴圈可能卡住頁面。簡易模式也無法真正執行關卡 `check`，可能誤判通關。

新主線錯誤先由 `ErrorExplainer` 產生離線白話，再由 AI 潤飾；程式能跑但 check 不通過時，目前主要顯示關卡訊息。

## 關卡測試

從外層 repository 目錄執行：

```powershell
godot --headless --path Program_Life_Runtime_Flashback res://tests/full_playthrough_test.tscn
```

若 Godot 未加入 PATH，請使用執行檔完整路徑。此測試解析劇本、檢查參考解答並跑自動流程，會關閉 AI 並使用獨立測試存檔。

`tests/ch2_greet_flow_test.tscn` 是舊場景流程測試，可能呼叫真實 AI，執行前先確認環境。先前臨時新增的 AI 測試腳本已移除。

## AWS 手動部署

正式後端來源在 `backend/`，不要直接修改 `.aws-sam/build/`。從內層 Godot 專案目錄手動執行：

```powershell
sam validate --template-file template.yaml
sam build --use-container --template-file template.yaml
sam deploy --guided --confirm-changeset
```

使用既有 stack、region（目前為 `ap-southeast-2`）與 Google Client ID。確認 change set 後再部署；若出現非預期的新資源或權限變更，先取消檢查。需要先準備 AWS CLI／SAM、有效部署權限及容器建置環境。

目前 template 引用既有 execution role，沒有宣告 DynamoDB；新增資料庫應另行規劃。Web 上線前也需驗收 OAuth 與 CORS，不能以桌面測試結果代替。

## 協作方式

1. 更新團隊分支後，在自己的分支修改並測試。
2. 提交時包含新增腳本、Godot `.uid` 與必要設定；不要提交機密、虛擬環境或不必要的建置產物。
3. 推送後透過 Pull Request／團隊約定流程合併。
4. 修改 API、存檔格式或場景入口時，同步通知 AI、登入與資料庫負責人，並更新文件。
