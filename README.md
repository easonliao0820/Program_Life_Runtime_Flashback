# 程式人生：跑馬燈

> 如果人生是一段程式碼，你會如何編寫你的回憶？

《程式人生：跑馬燈》（Program Life: Runtime Flashback）是一款結合 Python 教學與台灣生活情境的敘事遊戲。玩家在人生不同階段完成程式任務，並由導師「派森」提供錯誤解釋與引導提示。

本文件依 2026-11-19 的原始碼整理。程式已實作、雲端已部署與完整驗收是不同狀態，請以實際測試紀錄確認。

## 目前進度

- **遊戲主線**：Godot 4.6、Compatibility 模式；第一至第六章共 20 份 `.story` 劇本，包含兩種結局。第一至第三章舊場景仍保留。
- **Desktop 登入**：Google OAuth + PKCE + State + Loopback，透過 Lambda 交換 Token；已由開發者確認 Windows 登入成功。
- **Web 登入**：GIS 官方按鈕與 JavaScriptBridge 已接回既有玩家流程；完整 localhost／Amplify 登入仍需驗收。
- **玩家與資料**：已有遊戲 JWT、Token 自動更新、Session 撤銷、DynamoDB 玩家資料、雲端存檔與錯誤紀錄。
- **AI 提示**：訪客與登入玩家皆可使用 AWS Gemini，預設無每日配額及玩家冷卻時間。
- **Web 發布**：已由開發者確認成功匯出並部署 [Amplify 展示網站](https://main.dopnyv7gaqxh9.amplifyapp.com)。網站發布成功不代表所有功能都已驗收。
- **待完善**：Web Python 中斷、執行資源限制、新舊場景整合、跨裝置存檔衝突處理及完整流程測試。

## 專案目錄

外層是 Git repository，內層同名資料夾才是 Godot 專案。

```text
Program_Life_Runtime_Flashback/
├─ README.md
└─ Program_Life_Runtime_Flashback/
   ├─ project.godot
   ├─ export_presets.cfg
   ├─ login_screen.tscn
   ├─ backend/              # FastAPI、OAuth、JWT、DynamoDB 與 Gemini
   ├─ template.yaml         # SAM：既有角色、資料表名稱與 Function URL CORS
   ├─ chapters/             # 章節、題目與劇本
   ├─ src/
   │  ├─ core/network/      # AuthManager、CloudSaveManager、ErrorLogManager
   │  ├─ core/              # AiBridge、舊執行器
   │  ├─ game/              # 主線、關卡、PythonRunner、進度與 UI
   │  └─ ui/login/          # Desktop OAuth、Web GIS 與玩家狀態
   ├─ tests/                # 劇本／關卡流程測試
   └─ docs/                 # 架構與素材文件
```

劇本語法與遊戲結構參閱 [GAME_STRUCTURE.md](Program_Life_Runtime_Flashback/docs/GAME_STRUCTURE.md)。文件與原始碼不同時，先核對目前實作。

## 開啟遊戲

1. 使用 Godot 4.6.x 匯入 [project.godot](Program_Life_Runtime_Flashback/project.godot)，保持 Compatibility 模式。
2. 桌面程式關卡需安裝 Python 3。PythonRunner 嘗試尋找 `py`、`python`、`python3`，也支援在內層 `.env` 設定 `PYTHON_PATH`。
3. 執行專案，選擇 Google 或訪客登入。

新主線透過系統 Python／Pyodide 執行。若遇到既有 py4godot DLL 或 StorySystem Autoload UID 載入錯誤，需檢查擴充及路徑設定，不能將其視為登入驗收成功。

## Google 登入與遊戲入口

```text
Desktop：OAuth + PKCE → /auth/google/desktop/exchange → Google ID Token
Web：GIS 官方按鈕 → JavaScriptBridge → Google ID Token
  → /auth/google → 玩家 UUID + 遊戲 Access／Refresh Token
  → /auth/me 驗證 → PlayerSession
  → 玩家專屬本機存檔 → 雲端查詢／匯入 → GameFlow
```

- [google_auth.gd](Program_Life_Runtime_Flashback/src/ui/login/google_auth.gd) 以 `OS.has_feature("web")` 分流。Desktop 使用 `oauth/google/client_id`、`exchange_mode="lambda"` 與交換服務網址；Godot 不讀取 Client Secret。
- [google_web.js](Program_Life_Runtime_Flashback/src/ui/login/google_web.js) 載入 GIS 官方按鈕，支援取消、逾時、重開與回呼清理；Web Client ID 由 `oauth/google/web_client_id` 讀取。
- [google_login.gd](Program_Life_Runtime_Flashback/src/ui/login/google_login.gd) 協調 Google 驗證、遊戲 JWT、玩家身分及雲端進度。
- [auth_manager.gd](Program_Life_Runtime_Flashback/src/core/network/auth_manager.gd) 分別管理 Google ID Token 與遊戲 JWT，包含自動刷新；後端提供 Refresh Token 輪替及登出撤銷 Session。
- [player_session.gd](Program_Life_Runtime_Flashback/src/ui/login/player_session.gd) 保存後端玩家 UUID、姓名、email、頭像與登入狀態。Google sub 用於帳號綁定，不再直接當遊戲玩家 UUID。

Google 驗證接受明確設定的 Desktop 與 Web audiences；Desktop 授權碼交換仍固定使用 Desktop Client。登入成功且進度有效時從記錄小節開頭繼續，無進度則建立初始狀態並進入章節選擇。雲端查詢失敗會留在登入畫面重試；訪客仍走原有前言流程。

## 存檔與錯誤紀錄

[GameState](Program_Life_Runtime_Flashback/src/game/core/game_state.gd) 預設使用 `user://plrf_save.json`，登入後切換為依玩家 UUID 雜湊命名的 `plrf_save_<雜湊>.json`。舊 ProgressManager 另使用 `user://save_data.json`。`user://` 是玩家資料目錄，可從 Godot 編輯器開啟使用者資料資料夾查看。

[CloudSaveManager](Program_Life_Runtime_Flashback/src/core/network/cloud_save_manager.gd) 以遊戲 JWT 呼叫 `/players/me/save`。登入時下載雲端進度；匯入前驗證格式並備份本機資料。上傳採精簡格式，不包含劇情回顧 backlog；存檔序列化大小上限為 280 KiB。目前尚無完整的跨裝置版本衝突解決。

DynamoDB 存取由後端負責，Godot 不持有 AWS 長期憑證：

- `Players`：玩家 PROFILE、Google IDENTITY 綁定、SESSION 與主要進度 `SAVE#MAIN`。表名可由 `PLAYERS_TABLE` 設定。
- `PlayerErrors`：程式例外 `python_exception` 與判題失敗 `check_failed`。表名可由 `PLAYER_ERRORS_TABLE` 設定。

[ErrorLogManager](Program_Life_Runtime_Flashback/src/core/network/error_log_manager.gd) 記錄已登入玩家的關卡、程式碼、錯誤訊息、行號及嘗試次數。失敗先保存本機佇列再重送，後端以條件寫入避免相同紀錄重複；訪客不透過此模組上傳。管理員分析介面尚未實作。

## AI 與 Python 執行

```text
PythonRunner 執行 → ErrorExplainer 離線解釋
  → AiBridge → /ai/generate → AI Access Policy → Gemini
  ← 提示文字；失敗則使用備用說明
```

[AiBridge](Program_Life_Runtime_Flashback/src/core/ai_bridge.gd) 保留 `translate_error()`、`call_openai()`、`ask()` 與 `ai_response_received`；call_openai 是歷史名稱，實際走 AWS／Gemini。聊天與劇情也共用 AI 介面。

Lambda 從 Parameter Store `/godot-backend/API_KEY` 取得 Gemini Key，不回傳 Godot。AI 請求為 `{"prompt":"..."}`，回應為 `{"text":"..."}`；完整 prompt 上限 4000 字元、生成上限 512 Token、回覆文字上限 4000 字元，有逾時與在途請求保護，不自動重試。

AI 政策預設皆為 false：

- `AI_REQUIRE_LOGIN`：開啟才驗證 Bearer Google ID Token；目前前端 AI 不傳 Token，啟用前需另外調整，不能直接用遊戲 JWT 替代。
- `AI_RATE_LIMIT_ENABLED`、`AI_DAILY_QUOTA_ENABLED`：預留功能，啟用會回 503，並非已完成限流或配額。

匿名 AI 不影響私人 API 的 JWT 驗證。公開 AI 仍可能被外部呼叫產生成本，程序內併發保護不是全域預算上限。

玩家 Python 在本機／瀏覽器執行，不在 Lambda 執行。目前限制：

- PythonRunner 使用桌面 Python 或 Web Pyodide，桌面約 10 秒逾時。
- 允許完整 builtins／import，缺少記憶體與輸出量限制，不能稱為完整安全隔離。
- Web 同步執行，尚無 Worker／可靠中斷，無限迴圈可能卡住頁面。
- 缺少 Python 時的簡易模式無法真正執行 check，可能誤判通關。
- 舊 SandboxManager 主要支援單行 print；舊 CodingPanel 同步呼叫本機 Python，AI 分析仍有 TODO。

## Web 設定與驗收

使用既有 Web 匯出預設，包含 `.story` 與 `.js`，目前 thread_support 為 false。重新發布時上傳整份匯出目錄，不能只換 HTML。發布前檢查產物，避免包含 `.env`、後端、虛擬環境或建置資料。

Google Web OAuth Client 的 Authorized JavaScript origins 應對應：

- `http://localhost:8060`
- `https://main.dopnyv7gaqxh9.amplifyapp.com`

Lambda 的 `GOOGLE_OAUTH_WEB_CLIENT_ID` 須與 Godot 公開 Web Client ID 一致。SAM 已宣告兩個來源的 Function URL CORS：GET／POST／PUT、content-type／authorization、AllowCredentials false。模板內容不代表雲端已套用；避免在 FastAPI 重複添加 CORS 標頭。

需分別驗收 localhost 與 Amplify 的登入、名稱顯示、進遊戲、登出重登、無效 Token 拒絕、雲端存檔及匿名 AI。若 GIS popup 被阻擋，檢查瀏覽器、CSP 與 COOP 設定；不能用桌面登入結果代替 Web 驗收。

## 後端 API

[backend/main.py](Program_Life_Runtime_Flashback/backend/main.py) 提供：

- `GET /health`：應用存活檢查，不代表 SSM／Gemini／DynamoDB 正常。
- `POST /auth/google/desktop/exchange`：Desktop 授權碼交換與驗證。
- `POST /auth/google`：驗證 Google 身分，取得遊戲 JWT 與玩家資料。
- `GET /auth/me`：驗證遊戲 JWT，取得玩家資料。
- `POST /auth/refresh`、`POST /auth/logout`：更新憑證及撤銷 Session。
- `GET /players/me/save`、`PUT /players/me/save`：雲端存讀檔。
- `POST /players/me/errors`：上傳錯誤紀錄。
- `POST /ai/generate`：依 AI 政策產生提示。

## 本機啟動後端

從內層專案目錄執行，使用 Python 3.12 對齊 Lambda：

```powershell
py -3.12 -m venv .venv-backend
.\.venv-backend\Scripts\python.exe -m pip install -r backend/requirements.txt
.\.venv-backend\Scripts\python.exe -m uvicorn main:app --app-dir backend --reload
```

提供 `GOOGLE_OAUTH_CLIENT_ID`、需要時的 `GOOGLE_OAUTH_WEB_CLIENT_ID`、`GEMINI_MODEL`、`PLAYERS_TABLE`、`PLAYER_ERRORS_TABLE`。本機可由內層 `.env` 補讀環境設定；遊戲 OAuth 本身不依賴 `.env` Secret。

登入、JWT 與資料 API 仍需有效 AWS 憑證及既有 SSM／DynamoDB 權限，本機啟動不會自動建立資料庫。既有 SSM 參數包含 `/godot-backend/API_KEY`、`/godot-backend/GOOGLE_OAUTH_CLIENT_SECRET`、`/godot-backend/JWT_SECRET`。不要在程式、日誌或 Git 放入秘密值。

非 Lambda 本機 AI 可使用 API_KEY 環境變數，否則嘗試 SSM；Lambda 一律讀 SSM。遊戲各網路模組目前指向既有 AWS URL，啟動本機後端不會自動切換；若改測本機，需一致調整登入、AuthManager、CloudSaveManager、ErrorLogManager、AiBridge 與 Desktop 交換網址，Web 另需處理測試伺服器 CORS。

## AWS 手動部署

正式來源在 `backend/`，不要直接修改 `.aws-sam/build/`。以下在內層專案目錄執行：

```powershell
sam validate --template-file template.yaml --region ap-southeast-2
Docker info
sam build --use-container --template-file template.yaml --region ap-southeast-2
```

Windows 先啟動 Docker Desktop 的 Linux containers，確認 Server 可連線。建置失敗時不要部署舊產物。

部署前確認既有 stack 名稱、部署 S3 bucket、AWS profile 及目前所有環境變數。SAM 需提供五個參數：GoogleOAuthClientId、GoogleOAuthWebClientId、GeminiModel、PlayersTableName、PlayerErrorsTableName；不能只填 Desktop ID。使用團隊既有部署設定並保留變更確認，例如：

```powershell
sam deploy --template-file .aws-sam/build/template.yaml --confirm-changeset --region ap-southeast-2 --profile godot-project
```

此範例需先有正確的 samconfig.toml 或另行提供完整參數；沒有設定檔時不要直接照貼。若採 `--guided`，使用既有 stack，不接受預設名稱建立第二個後端。自動管理部署 bucket 需要 CloudFormation 權限；既有 bucket 可用 `--s3-bucket` 配合 `--no-resolve-s3` 指定。IAM role creation 的確認提示不會自動授予部署者權限。

模板引用既有 execution role 及資料表，沒有宣告建立 DynamoDB。確認變更集不含非預期資源或權限變動後才部署；更新 Lambda 不會自動更新 Amplify 遊戲檔案。

## 測試與協作

從外層 repository 執行既有主線測試：

```powershell
godot --headless --path Program_Life_Runtime_Flashback res://tests/full_playthrough_test.tscn
```

若 Godot 未加入 PATH，改用執行檔完整路徑。此測試停用 AI 並使用獨立測試存檔；舊 `ch2_greet_flow_test` 可能呼叫真實 AI。後端另有 Auth、Refresh、Logout 與 Session 測試，測試檔案存在不等於目前版本已通過。

提交前記錄版本、環境、測試步驟與結果。優先驗收 Desktop／Web 登入、帳號存檔隔離、錯誤重送、匿名 AI、各章及兩種結局。測試截圖與日誌不得包含完整 Token。

協作時在自己的分支修改，提交必要 `.uid`、劇本與設定；不要提交機密或新增不必要的建置產物。API、存檔格式與場景入口改動需通知 AI、登入及資料庫負責人，並同步文件。
