extends Node

## PythonRunner（Autoload）：真的執行玩家寫的 Python，並用關卡的 check 程式判斷有沒有過關。
##
## 後端依平台自動選擇：
##   - 桌面版：呼叫系統的 python3（可在 .env 用 PYTHON_PATH=... 指定路徑）
##   - 網頁版：透過 JavaScriptBridge 載入 Pyodide（瀏覽器裡的 Python）
##   - 都沒有：退回舊的 SandboxManager，只支援單行 print()
##
## 兩種後端共用同一段 HARNESS：限制可 import 的模組、限制執行步數（防無限迴圈）、
## 把 input() 換成關卡預先準備的輸入，再執行關卡的 check（assert 寫法）。
##
## 回傳格式：
##   {"ok": bool, "stdout": String, "error": {type, message, line, text} 或 null,
##    "passed": bool, "message": String（check 沒過時的提示）, "flags": Dictionary, "backend": String}

enum Backend { UNKNOWN, DESKTOP, WEB, FALLBACK }

const PYODIDE_URL := "https://cdn.jsdelivr.net/pyodide/v0.26.4/full/"
const HARNESS_PATH := "user://plrf_harness.py"
const REQUEST_PATH := "user://plrf_request.json"

var backend: Backend = Backend.UNKNOWN
var python_cmd: String = ""

const HARNESS := r'''
import sys, io, json, builtins, traceback

MAX_STEPS = 300000
MAX_OUTPUT = 20000
ALLOWED_MODULES = {"random", "math"}
SAFE_NAMES = [
    "abs", "all", "any", "bool", "dict", "enumerate", "filter", "float", "int", "isinstance", "len",
    "list", "map", "max", "min", "range", "reversed", "round", "set", "sorted", "str", "sum", "tuple",
    "type", "zip", "chr", "ord", "divmod", "pow", "object", "super", "property", "staticmethod",
    "classmethod", "hasattr", "getattr", "setattr", "repr", "format", "iter", "next", "__build_class__",
    "Exception", "ValueError", "TypeError", "KeyError", "IndexError", "ZeroDivisionError", "NameError",
    "AttributeError", "RuntimeError", "StopIteration", "AssertionError", "EOFError", "ImportError",
    "True", "False", "None",
]


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

    def _print(*args, sep=" ", end="\n", file=None, flush=False):
        out.write(sep.join(str(a) for a in args) + end)
        if out.tell() > MAX_OUTPUT:
            raise RuntimeError("印出來的東西太多了")

    def _input(prompt=""):
        out.write(str(prompt))
        if not stdin_lines:
            raise EOFError("沒有更多輸入了")
        value = stdin_lines.pop(0)
        out.write(value + "\n")
        return value

    def _import(name, globals=None, locals=None, fromlist=(), level=0):
        if name.split(".")[0] not in ALLOWED_MODULES:
            raise ImportError("這裡只能 import random 或 math，不能 import " + name)
        return builtins.__import__(name, globals, locals, fromlist, level)

    safe = {n: getattr(builtins, n) for n in SAFE_NAMES if hasattr(builtins, n)}
    safe["print"] = _print
    safe["input"] = _input
    safe["__import__"] = _import
    env = {"__builtins__": safe, "__name__": "__main__"}

    steps = [0]

    def tracer(frame, event, arg):
        if frame.f_code.co_filename != "<player>":
            return None
        if event == "line":
            steps[0] += 1
            if steps[0] > MAX_STEPS:
                raise TimeoutError("程式跑太久了，可能是無限迴圈")
        return tracer

    try:
        compiled = compile(code, "<player>", "exec")
    except SyntaxError as e:
        result["ok"] = False
        result["error"] = _error_info(e)
        return result

    old_trace = sys.gettrace()
    sys.settrace(tracer)
    try:
        exec(compiled, env)
    except BaseException as e:
        result["ok"] = False
        result["error"] = _error_info(e)
    finally:
        sys.settrace(old_trace)
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
    cenv["print"] = lambda *a, **k: None  # check 裡的 print 不能印到 stdout（會破壞回傳的 JSON）
    sys.settrace(tracer)
    try:
        exec(compile(check, "<check>", "exec"), cenv)
        result["passed"] = True
    except AssertionError as e:
        result["passed"] = False
        result["message"] = str(e) or "結果還不太對，再看一次任務卡吧。"
    except BaseException as e:
        result["passed"] = False
        result["message"] = "（檢查時發生問題：%s: %s）" % (type(e).__name__, e)
    finally:
        sys.settrace(old_trace)
    result["flags"] = flags
    return result


def run_request_json(text):
    return json.dumps(run_request(json.loads(text)), ensure_ascii=True, default=str)


if __name__ == "__main__":
    with open(sys.argv[1], encoding="utf-8") as f:
        sys.stdout.write(run_request_json(f.read()))
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

	var thread := Thread.new()
	thread.start(_exec_python.bind(ProjectSettings.globalize_path(HARNESS_PATH), ProjectSettings.globalize_path(REQUEST_PATH)))
	while thread.is_alive():
		await get_tree().process_frame
	var output: String = thread.wait_to_finish()
	return _parse_output(output)


func _exec_python(harness: String, request: String) -> String:
	var out: Array = []
	var args: Array = [harness, request]
	if python_cmd == "py":
		args.push_front("-3")
	OS.execute(python_cmd, PackedStringArray(args), out, true)
	return str(out[0]) if out.size() > 0 else ""


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
