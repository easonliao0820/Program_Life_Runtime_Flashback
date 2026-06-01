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
