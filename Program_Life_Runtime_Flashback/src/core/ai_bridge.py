
def call_ai( prompt: str) -> str:
	return "👁 語之觀測者：\n" + prompt

def ai_translate_error( error: str, code: str) -> str:
	prompt = f"""
你是一個教學型AI（像遊戲中的NPC「語之觀測者」）。

請將以下Python錯誤轉換成：
1. 溫和語氣
2. 不直接說錯誤名稱
3. 像在提示玩家，而不是報錯
4. 保持神秘感與遊戲風格

玩家程式：
{code}

錯誤：
{error}

請輸出一段提示訊息：
"""

	return call_ai(prompt)
