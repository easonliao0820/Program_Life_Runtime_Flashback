extends Resource
class_name DialogueData

# 定義未來劇情播完後，需要強制觸發的互動類型
enum InteractionType {
	NONE,               # 無，單純播完就關閉對話框
	WAIT_FOR_SANDBOX,   # 阻斷點：播完後強制玩家必須在右側沙盒寫程式
	WAIT_FOR_AI         # 阻斷點：播完後交由 Gemini AI 進行動態對話回應
}
## 核心劇本清單
@export var dialogue_sequence: Array[DialogueStep] = []

## 設定此段劇情結束後，觸發沙盒或 AI 的回覆互動
@export var next_interaction: InteractionType = InteractionType.NONE

## 沙盒等待時顯示的提示訊息（next_interaction = WAIT_FOR_SANDBOX 時使用）
@export_multiline var sandbox_wait_message: String = ""

## AI 等待時顯示的提示訊息（next_interaction = WAIT_FOR_AI 時使用）
@export_multiline var ai_wait_message: String = ""
