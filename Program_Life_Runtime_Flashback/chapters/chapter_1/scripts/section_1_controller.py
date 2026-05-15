from py4godot.classes import gdclass
from py4godot.classes.Node import Node

@gdclass
class section_1_controller(Node):

	def _ready(self):
		print("READY OK")

		self.code_edit = self.get_node("CodeEdit")
		self.output = self.get_node("OutputLabel")
		self.button = self.get_node("RunButton")

		print("button:", self.button)

		# ✅ 正確 connect（重點）
		self.button.pressed.connect(self._on_run_pressed)

	def _on_run_pressed(self):
		code = self.code_edit.text
		self.output.text = self.run_code(code, "玩家")

	def run_code(self, code: str, user_name: str) -> str:
		output = ""

		# 🔥 1. 基本清理
		code = code.strip()

		# 🔥 2. 規則限制（第一關核心）
		if "import" in code or "=" in code or "\n" in code:
			return "❌ 第一關只能使用 print(\"你的名字\")"

		# 🔥 3. 必須是 print 開頭
		if not code.startswith("print("):
			return "❌ 只能使用 print()"

		# 🔥 4. 必須是字串內容
		if not (code.startswith('print("') or code.startswith("print('")):
			return "❌ 只能輸入名字（字串）"

		if not code.endswith(")") :
			return "❌ 語法錯誤"

		# 🔥 5. 執行安全 sandbox
		def fake_print(*args):
			nonlocal output
			output += " ".join(str(a) for a in args) + "\n"

		safe_globals = {
			"print": fake_print,
			"__builtins__": {}
		}

		try:
			exec(code, safe_globals, {})
		except Exception as e:
			return f"Error: {e}"

		# 🔥 6. 加劇情回應（你原本設計）
		return f"{output.strip()}\n\n✨ 系統：已記錄你的名字"
