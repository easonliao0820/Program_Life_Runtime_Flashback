extends Node

## PythonRunner（Autoload）：真的執行玩家寫的 Python，並用關卡的 check 程式判斷有沒有過關。
##
## 後端依平台自動選擇：
##   - 桌面版：呼叫系統的 python3（可在 .env 用 PYTHON_PATH=... 指定路徑）
##   - 網頁版：透過 JavaScriptBridge 載入 Pyodide（瀏覽器裡的 Python）
##   - 都沒有：退回舊的 SandboxManager，只支援單行 print()
##
## 兩種後端共用同一段 HARNESS：玩家的程式用完整的 Python 執行（沒有沙盒限制：
## 任何模組都能 import、所有內建函式都能用、不限步數與輸出量），
## 只把 input() 換成關卡預先準備的輸入，再執行關卡的 check（assert 寫法）。
## 防止整個遊戲卡住：桌面版每次執行是獨立的 Python 程序，超過 RUN_TIMEOUT_SEC 秒就結束它
## （這不限制程式能做什麼，只是避免無限迴圈讓遊戲當掉；設成 0 就不限時間）。
##
## 回傳格式：
##   {"ok": bool, "stdout": String, "error": {type, message, line, text} 或 null,
##    "passed": bool, "message": String（check 沒過時的提示）, "flags": Dictionary, "backend": String}

enum Backend { UNKNOWN, DESKTOP, WEB, FALLBACK }

const PYODIDE_URL := "https://cdn.jsdelivr.net/pyodide/v0.26.4/full/"
const HARNESS_PATH := "user://plrf_harness.py"
const REQUEST_PATH := "user://plrf_request.json"
const RESULT_PATH := "user://plrf_result.json"
## 一次執行最多幾秒（桌面版）；0 = 不限時間
const RUN_TIMEOUT_SEC := 10.0

var backend: Backend = Backend.UNKNOWN
var python_cmd: String = ""

const HARNESS := r'''
import sys, io, json, builtins, traceback, contextlib


def _error_info(e):
    info = {"type": type(e).__name__, "message": str(e), "line": 0, "text": ""}
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
    out = io.StringIO()
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

    with contextlib.redirect_stdout(out):
        try:
            exec(compiled, env)
        except SystemExit:
            pass  # 玩家呼叫 exit()／sys.exit()：當成正常結束
        except BaseException as e:
            result["ok"] = False
            result["error"] = _error_info(e)
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
    with contextlib.redirect_stdout(io.StringIO()):
        try:
            exec(compile(check, "<check>", "exec"), cenv)
            result["passed"] = True
        except AssertionError as e:
            result["passed"] = False
            result["message"] = str(e) or "結果還不太對，再看一次任務卡吧。"
        except BaseException as e:
            result["passed"] = False
            result["message"] = "（檢查時發生問題：%s: %s）" % (type(e).__name__, e)
    result["flags"] = flags
    return result


def run_request_json(text):
    return json.dumps(run_request(json.loads(text)), ensure_ascii=True, default=str)


if __name__ == "__main__":
    # 用法：python harness.py 請求.json 結果.json
    with open(sys.argv[1], encoding="utf-8") as f:
        answer = run_request_json(f.read())
    with open(sys.argv[2], "w", encoding="utf-8") as f:
        f.write(answer)
'''

const WEB_BOOT := '''
(function () {
	if (window.plrf) { return; }
	window.plrf = { ready: false, failed: false };
	var base = %s;
	var harness = %s;
	var s = document.createElement("script");
	s.src = base + "pyodide.js";
	s.onload = async function () {
		try {
			var py = await loadPyodide({ indexURL: base });
			py.runPython(harness);
			var fn = py.globals.get("run_request_json");
			window.plrf.run = function (req) { return fn(req); };
			window.plrf.ready = true;
		} catch (e) {
			console.error("[PythonRunner] Pyodide 載入失敗", e);
			window.plrf.failed = true;
		}
	};
	s.onerror = function () { window.plrf.failed = true; };
	document.head.appendChild(s);
})();
'''


func _ready() -> void:
	if OS.has_feature("web"):
		backend = Backend.WEB
		JavaScriptBridge.eval(WEB_BOOT % [JSON.stringify(PYODIDE_URL), JSON.stringify(HARNESS)], true)


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
	_ensure_backend()
	var req := {"code": code, "check": check, "stdin": stdin}
	var result: Dictionary
	match backend:
		Backend.DESKTOP:
			result = await _run_desktop(req)
		Backend.WEB:
			result = await _run_web(req)
		_:
			result = _run_fallback(req)
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
		var f := FileAccess.open(HARNESS_PATH, FileAccess.WRITE)
		if f:
			f.store_string(HARNESS)
			f.close()
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
	var f := FileAccess.open(REQUEST_PATH, FileAccess.WRITE)
	if f == null:
		return _internal_error("無法寫入暫存檔")
	f.store_string(JSON.stringify(req))
	f.close()
	var result_abs := ProjectSettings.globalize_path(RESULT_PATH)
	if FileAccess.file_exists(RESULT_PATH):
		DirAccess.remove_absolute(result_abs)

	# 獨立的 Python 程序：遊戲不會被卡住，超過時間就結束它
	var args: Array = [ProjectSettings.globalize_path(HARNESS_PATH), ProjectSettings.globalize_path(REQUEST_PATH), result_abs]
	if python_cmd == "py":
		args.push_front("-3")
	var pid := OS.create_process(python_cmd, PackedStringArray(args))
	if pid <= 0:
		return _internal_error("無法啟動 Python（%s）" % python_cmd)
	var started := Time.get_ticks_msec()
	while OS.is_process_running(pid):
		await get_tree().process_frame
		if RUN_TIMEOUT_SEC > 0.0 and Time.get_ticks_msec() - started > RUN_TIMEOUT_SEC * 1000.0:
			OS.kill(pid)
			return {"ok": false, "stdout": "", "passed": false, "message": "", "flags": {},
				"error": {"type": "TimeoutError", "message": "超過 %d 秒還沒跑完" % int(RUN_TIMEOUT_SEC), "line": 0, "text": ""}}

	if not FileAccess.file_exists(RESULT_PATH):
		return _internal_error("Python 沒有傳回結果")
	return _parse_output(FileAccess.get_file_as_string(RESULT_PATH))


# ------------------------------------------------------------------
# 網頁：Pyodide
# ------------------------------------------------------------------

func _run_web(req: Dictionary) -> Dictionary:
	var waited := 0.0
	while not bool(JavaScriptBridge.eval("!!(window.plrf && window.plrf.ready)", true)):
		if bool(JavaScriptBridge.eval("!!(window.plrf && window.plrf.failed)", true)) or waited > 40.0:
			backend = Backend.FALLBACK
			push_warning("[PythonRunner] Pyodide 無法載入，改用簡易模式。")
			return _run_fallback(req)
		await get_tree().create_timer(0.25).timeout
		waited += 0.25
	var output = JavaScriptBridge.eval("window.plrf.run(%s)" % JSON.stringify(JSON.stringify(req)), true)
	return _parse_output(str(output))


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
		# 沒有 Python 沒辦法跑 check，只要有印出東西就先放行
		result["passed"] = printed.size() > 0
		result["message"] = "" if result["passed"] else "簡易模式：至少要用 print() 印出一行。"
	return result


func _parse_output(output: String) -> Dictionary:
	var lines := output.strip_edges().split("\n")
	for i in range(lines.size() - 1, -1, -1):
		var l := lines[i].strip_edges()
		if l.begins_with("{"):
			var data = JSON.parse_string(l)
			if data is Dictionary:
				return data
	return _internal_error(output.strip_edges().right(400))


func _internal_error(detail: String) -> Dictionary:
	push_warning("[PythonRunner] 執行環境出錯：" + detail)
	return {"ok": false, "stdout": "", "passed": false, "message": "", "flags": {},
		"error": {"type": "InternalError", "message": detail, "line": 0, "text": ""}}
