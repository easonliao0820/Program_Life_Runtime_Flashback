extends Node

## PythonRunner（Autoload）：真的執行玩家寫的 Python，並用關卡的 check 程式判斷有沒有過關。
##
## 後端依平台自動選擇：
##   - 桌面版：呼叫系統的 python3（可在 .env 用 PYTHON_PATH=... 指定路徑）
##   - 網頁版：透過 JavaScriptBridge 載入 Pyodide（瀏覽器裡的 Python）
##   - 都沒有：退回舊的 SandboxManager，只支援單行 print()
##
## 共用 HARNESS 保留完整 Python 教學功能，限制輸出與請求大小。
## 桌面獨立程序；Web 每次建立獨立 Worker。兩者皆可取消並在 10 秒後終止。
## 這是執行保護，不是 OS 權限／記憶體隔離；不可當作不可信程式的安全邊界。
##
## 回傳格式：
##   {"ok": bool, "stdout": String, "error": {type, message, line, text} 或 null,
##    "passed": bool, "message": String（check 沒過時的提示）, "flags": Dictionary, "backend": String}

enum Backend { UNKNOWN, DESKTOP, WEB, FALLBACK }

const PYODIDE_URL := "https://cdn.jsdelivr.net/pyodide/v0.26.4/full/"
## 一次執行最多幾秒（不含 Web 初始化）
const RUN_TIMEOUT_SEC := 10.0

const MAX_REQUEST_BYTES := 131072
const MAX_RESULT_BYTES := 1048576
var _busy := false
var _cancelled := false
var _pid := -1
var _web_job := -1
var _files: Array[String] = []
var backend: Backend = Backend.UNKNOWN
var python_cmd: String = ""

const HARNESS := r'''
import sys, io, json, builtins, traceback, contextlib

MAX_OUTPUT = 16384
class OutputLimitError(Exception):
    pass

class LimitedOutput(io.StringIO):
    def __init__(self):
        super().__init__()
        self.used = 0
        self.exceeded = False
    def write(self, value):
        remaining = max(0, MAX_OUTPUT - self.used)
        self.used += len(value)
        super().write(value[:remaining])
        if self.used > MAX_OUTPUT:
            self.exceeded = True
            raise OutputLimitError("輸出超過 16384 字元，請減少 print 或檢查迴圈。")
        return len(value)



def _error_info(e):
    info = {"type": type(e).__name__, "message": str(e)[:1200], "line": 0, "text": ""}
    if isinstance(e, SyntaxError):
        info["message"] = e.msg or str(e)
        info["line"] = e.lineno or 0
        info["text"] = (e.text or "").rstrip()
        return info
    for fr in traceback.extract_tb(e.__traceback__):
        if fr.filename == "<player>":
            info["line"] = fr.lineno or 0
            info["text"] = (fr.line or "").rstrip()
    return info


def run_request(req):
    code = req.get("code", "")
    check = req.get("check", "")
    stdin_lines = [str(x) for x in req.get("stdin", [])]
    out = LimitedOutput()
    result = {"ok": True, "stdout": "", "error": None, "passed": None, "message": "", "flags": {}}

    # input() 讀關卡準備好的輸入，並把輸入的內容也印出來（像真的在終端機打字）
    def _input(prompt=""):
        out.write(str(prompt))
        if not stdin_lines:
            raise EOFError("沒有更多輸入了")
        value = stdin_lines.pop(0)
        out.write(value + "\n")
        return value

    # 完整的內建函式（沒有白名單），只換掉 input
    player_builtins = dict(vars(builtins))
    player_builtins["input"] = _input
    env = {"__builtins__": player_builtins, "__name__": "__main__"}

    try:
        compiled = compile(code, "<player>", "exec")
    except SyntaxError as e:
        result["ok"] = False
        result["error"] = _error_info(e)
        return result

    with contextlib.redirect_stdout(out), contextlib.redirect_stderr(out):
        try:
            exec(compiled, env)
        except SystemExit:
            pass  # 玩家呼叫 exit()／sys.exit()：當成正常結束
        except BaseException as e:
            result["ok"] = False
            result["error"] = _error_info(e)
    if out.exceeded:
        result["ok"] = False
        result["error"] = _error_info(OutputLimitError("輸出超過上限，請減少 print 或檢查迴圈。"))
    result["stdout"] = out.getvalue()

    if not result["ok"]:
        return result
    if not check.strip():
        result["passed"] = True
        return result

    flags = {}
    cenv = dict(env)
    cenv["__builtins__"] = builtins
    cenv["out"] = result["stdout"]
    cenv["lines"] = [l for l in result["stdout"].splitlines()]
    cenv["code"] = code
    cenv["set_flag"] = lambda k, v: flags.__setitem__(k, v)
    # check 執行時（包括它呼叫玩家的函式）印出的東西都丟掉，不能混進回傳結果
    check_out = LimitedOutput()
    with contextlib.redirect_stdout(check_out), contextlib.redirect_stderr(check_out):
        try:
            exec(compile(check, "<check>", "exec"), cenv)
            result["passed"] = True
        except AssertionError as e:
            result["passed"] = False
            result["message"] = str(e)[:1200] or "結果還不太對，再看一次任務卡吧。"
        except BaseException as e:
            result["passed"] = False
            result["message"] = "（檢查時發生問題：%s: %s）" % (type(e).__name__, str(e)[:1200])
    if check_out.exceeded:
        result["passed"] = False
        result["message"] = "檢查答案時輸出過多，請檢查函式與迴圈。"
    result["flags"] = flags
    return result


def run_request_json(text):
    return json.dumps(run_request(json.loads(text)), ensure_ascii=True, default=str)


if __name__ == "__main__" and len(sys.argv) >= 3:
    # 用法：python harness.py 請求.json 結果.json
    with open(sys.argv[1], encoding="utf-8") as f:
        answer = run_request_json(f.read())
    with open(sys.argv[2], "w", encoding="utf-8") as f:
        f.write(answer)
'''

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if OS.has_feature("web"):
		backend = Backend.WEB
		JavaScriptBridge.eval(FileAccess.get_file_as_string("res://src/game/core/python_worker.js"), true)


func cancel() -> void:
	if not _busy:
		return
	_cancelled = true
	if _pid > 0:
		OS.kill(_pid)
	if OS.has_feature("web") and _web_job > 0:
		var bridge = JavaScriptBridge.get_interface("PLPython")
		if bridge != null:
			bridge.cancel(_web_job)


func _exit_tree() -> void:
	cancel()


func backend_name() -> String:
	_ensure_backend()
	match backend:
		Backend.DESKTOP:
			return "Python（%s）" % python_cmd
		Backend.WEB:
			return "Pyodide"
		Backend.FALLBACK:
			return "簡易模式（只支援 print）"
	return "未知"


func is_full_python() -> bool:
	_ensure_backend()
	return backend == Backend.DESKTOP or backend == Backend.WEB


## 執行玩家程式碼。check 是關卡的檢查程式（可以用 out、lines、code 與玩家的變數，失敗就 assert）。
func run(code: String, check: String = "", stdin: Array = []) -> Dictionary:
	if _busy:
		return _failure("BusyError", "已有程式執行中，請先停止或等待完成。")
	_ensure_backend()
	var req := {"code": code, "check": check, "stdin": stdin}
	if JSON.stringify(req).to_utf8_buffer().size() > MAX_REQUEST_BYTES:
		return _failure("InputLimitError", "程式或輸入資料過大，請縮短後再執行。")
	_busy = true
	_cancelled = false
	var result: Dictionary
	match backend:
		Backend.DESKTOP:
			result = await _run_desktop(req)
		Backend.WEB:
			result = await _run_web(req)
		_:
			result = _run_fallback(req)
	_pid = -1
	_web_job = -1
	for path in _files:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	_files.clear()
	_busy = false
	result["backend"] = backend_name()
	return result


# ------------------------------------------------------------------
# 桌面：系統 Python
# ------------------------------------------------------------------

func _ensure_backend() -> void:
	if backend != Backend.UNKNOWN:
		return
	python_cmd = _find_python()
	if python_cmd != "":
		backend = Backend.DESKTOP
		print("[PythonRunner] 使用 ", python_cmd)
	else:
		backend = Backend.FALLBACK
		push_warning("[PythonRunner] 找不到 Python 3，改用簡易模式（只支援單行 print）。請安裝 Python 3 或在 .env 設定 PYTHON_PATH。")


func _find_python() -> String:
	var candidates: Array = []
	var env_path := _read_env_value("PYTHON_PATH")
	if env_path != "":
		candidates.append(env_path)
	if OS.get_name() == "Windows":
		candidates.append_array(["py", "python", "python3"])
	else:
		candidates.append_array(["python3", "python", "/opt/homebrew/bin/python3", "/usr/local/bin/python3",
			"/usr/bin/python3", "/Library/Frameworks/Python.framework/Versions/Current/bin/python3"])
	for c in candidates:
		var out: Array = []
		var args: Array = ["-3", "-c", "import sys;print(sys.version_info[0])"] if c == "py" else ["-c", "import sys;print(sys.version_info[0])"]
		var code := OS.execute(c, PackedStringArray(args), out, true)
		if code == 0 and out.size() > 0 and str(out[0]).strip_edges() == "3":
			return c
	return ""


func _read_env_value(key: String) -> String:
	if not FileAccess.file_exists("res://.env"):
		return ""
	for line in FileAccess.get_file_as_string("res://.env").split("\n"):
		var t := line.strip_edges()
		if t.begins_with(key + "="):
			return t.substr(key.length() + 1).strip_edges().trim_prefix("\"").trim_suffix("\"")
	return ""


func _run_desktop(req: Dictionary) -> Dictionary:
	# 每次獨立檔名，避免多個遊戲程序或上一輪結果互相覆蓋。
	var key := Crypto.new().generate_random_bytes(12).hex_encode()
	var harness_path := "user://plrf_%s.py" % key
	var request_path := "user://plrf_%s_request.json" % key
	var result_path := "user://plrf_%s_result.json" % key
	_files.assign([harness_path, request_path, result_path])
	var harness_file := FileAccess.open(harness_path, FileAccess.WRITE)
	if harness_file == null:
		return _internal_error("無法建立執行檔")
	harness_file.store_string(HARNESS)
	harness_file.close()
	var f := FileAccess.open(request_path, FileAccess.WRITE)
	if f == null:
		return _internal_error("無法寫入暫存檔")
	f.store_string(JSON.stringify(req))
	f.close()
	var result_abs := ProjectSettings.globalize_path(result_path)
	if FileAccess.file_exists(result_path):
		DirAccess.remove_absolute(result_abs)

	# 獨立的 Python 程序：遊戲不會被卡住，超過時間就結束它
	var args: Array = ["-I", ProjectSettings.globalize_path(harness_path), ProjectSettings.globalize_path(request_path), result_abs]
	if python_cmd == "py":
		args.push_front("-3")
	var pid := OS.create_process(python_cmd, PackedStringArray(args))
	if pid <= 0:
		return _internal_error("無法啟動 Python（%s）" % python_cmd)
	_pid = pid
	var started := Time.get_ticks_msec()
	while OS.is_process_running(pid):
		await get_tree().process_frame
		if _cancelled:
			return _failure("CancelledError", "已停止執行。")
		if RUN_TIMEOUT_SEC > 0.0 and Time.get_ticks_msec() - started > RUN_TIMEOUT_SEC * 1000.0:
			OS.kill(pid)
			return {"ok": false, "stdout": "", "passed": false, "message": "", "flags": {},
				"error": {"type": "TimeoutError", "message": "超過 %d 秒還沒跑完" % int(RUN_TIMEOUT_SEC), "line": 0, "text": ""}}

	if not FileAccess.file_exists(result_path):
		return _internal_error("Python 沒有傳回結果")
	var result_file := FileAccess.open(result_path, FileAccess.READ)
	if result_file == null or result_file.get_length() > MAX_RESULT_BYTES:
		return _failure("OutputLimitError", "執行結果過大或無法讀取。")
	return _parse_output(result_file.get_as_text())


# ------------------------------------------------------------------
# 網頁：Pyodide
# ------------------------------------------------------------------

func _run_web(req: Dictionary) -> Dictionary:
	var bridge = JavaScriptBridge.get_interface("PLPython")
	if bridge == null:
		return _failure("EnvironmentError", "Python Worker 未載入，請重新整理頁面。")
	_web_job = int(bridge.start(PYODIDE_URL, HARNESS, JSON.stringify(req), int(RUN_TIMEOUT_SEC * 1000), 40000))
	if _web_job < 0:
		return _failure("BusyError", "已有程式執行中。")
	while true:
		var output := str(bridge.take(_web_job))
		if not output.is_empty():
			return _parse_output(output)
		await get_tree().process_frame
	return _internal_error("未收到執行結果")


# ------------------------------------------------------------------
# 簡易模式：沒有 Python 時，沿用舊的 SandboxManager（只認得單行 print）
# ------------------------------------------------------------------

func _run_fallback(req: Dictionary) -> Dictionary:
	var code: String = req["code"]
	var result := {"ok": true, "stdout": "", "error": null, "passed": true, "message": "", "flags": {}}
	var printed: Array = []
	var sandbox := get_node_or_null("/root/SandboxManager")
	for line in code.split("\n"):
		var t := line.strip_edges()
		if t == "" or t.begins_with("#"):
			continue
		var r: String = sandbox.run_code(t) if sandbox else "❌ 沒有可用的 Python"
		if r.begins_with("❌"):
			result["ok"] = false
			result["passed"] = false
			result["error"] = {"type": "SimpleModeError", "message": r.trim_prefix("❌ "), "line": 0, "text": t}
			return result
		printed.append(r)
	result["stdout"] = "\n".join(printed) + ("\n" if printed.size() > 0 else "")
	if str(req.get("check", "")).strip_edges() != "":
		# 沒有 Python 只能預覽，不能將未驗證的答案當成通關。
		result["passed"] = false
		result["message"] = "目前為簡易模式，只能預覽輸出，無法驗證答案。請恢復 Python 執行環境後再試。"
	return result


func _parse_output(output: String) -> Dictionary:
	var lines := output.strip_edges().split("\n")
	for i in range(lines.size() - 1, -1, -1):
		var l := lines[i].strip_edges()
		if l.begins_with("{"):
			var data = JSON.parse_string(l)
			if data is Dictionary and data.get("ok") is bool and data.get("stdout") is String and data.get("flags") is Dictionary:
				if data.get("passed") != null and not data.get("passed") is bool:
					return _internal_error("Python 判題結果格式不正確")
				if data["ok"] == false and not data.get("error") is Dictionary:
					return _internal_error("Python 錯誤資料格式不正確")
				return data
	return _internal_error("Python 回應格式不正確")


func _internal_error(detail: String) -> Dictionary:
	push_warning("[PythonRunner] 執行環境出錯：" + detail)
	return {"ok": false, "stdout": "", "passed": false, "message": "", "flags": {},
		"error": {"type": "InternalError", "message": detail, "line": 0, "text": ""}}


func _failure(kind: String, message: String) -> Dictionary:
	return {"ok": false, "stdout": "", "passed": false, "message": "", "flags": {},
		"error": {"type": kind, "message": message, "line": 0, "text": ""}}
