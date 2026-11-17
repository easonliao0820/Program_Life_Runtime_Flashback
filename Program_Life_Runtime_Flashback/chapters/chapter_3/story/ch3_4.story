# 3.4 學測當天　｜　18 歲（高三）　｜　雙層 for 迴圈、break、not in
# 場景：清晨的主角房間（探索模式），窗外天剛亮。

@bg my_room_dawn
（學測當天早上，你做著最後的行前檢查。）
派森：簡章規定的五樣東西，一樣都不能少。請你用程式幫自己做最後的檢查吧。

# 【關卡】required 清單不會直接顯示，只會提示「共有 5 樣」。
@explore ch3_4_bag
title: 學測當天・行前檢查
goal: 把要帶進考場的東西放進 my_bag。簡章上一共有 5 樣。
list: my_bag
hidden_count: 5
confirm: 檢查完畢
- 准考證
- 身分證
- 2B鉛筆
- 橡皮擦
- 手錶
- 水壺
- 手機
- 漫畫
@end

系統：for 迴圈裡面還可以再放一個 for 迴圈，叫做「雙層迴圈」。break 可以提早結束最內層的迴圈。

@level ch3_4_check
title: 簡章上的五樣東西
goal: 用雙層 for 迴圈檢查：外層拿出簡章上的每一樣，內層翻書包裡的每一樣，找到就 count += 1，然後 break。五樣都要帶齊！
tags: 外層：for req in required | 內層：for item in my_bag | 找到 → count += 1、break
hint: 把 pass 換成兩行：count += 1 和 break。
hint: 如果 count 不到 5，代表書包裡少了東西：用 my_bag.append("……") 補上。
starter:
```python
required = ["准考證", "身分證", "2B鉛筆", "橡皮擦", "手錶"]
<<explore_code>>
count = 0   # 用來計算帶對的物品數量

for req in required:          # 外層：拿出簡章上的每一樣
    for item in my_bag:       # 內層：翻書包裡的每一樣
        if item == req:       # 找到了
            pass              # 把這行換成 count += 1 和 break

if count == len(required):
    print("（你檢查了一下背包，簡章要求的五樣物品都帶齊了！）")
else:
    print(f"（好像還缺了點什麼……目前只帶了 {count}/{len(required)} 樣。）")
```
check:
```python
import ast
import builtins
import contextlib
import copy
import io
import sys

expected_required = ["准考證", "身分證", "2B鉛筆", "橡皮擦", "手錶"]

assert "required" in globals() and isinstance(required, list), \
    "請保留簡章上的 required 清單。"
assert required == expected_required, \
    "不能修改簡章：准考證、身分證、2B鉛筆、橡皮擦、手錶都要檢查。"

assert "my_bag" in globals() and isinstance(my_bag, list), \
    "請建立 my_bag 書包清單。"
missing = [item for item in expected_required if item not in my_bag]
assert not missing, "書包還缺：" + "、".join(missing)

assert "count" in globals() and type(count) is int and count == 5, \
    "請正確計算帶齊的五樣必需品。"

tree = ast.parse(code)

# break 必須結束翻書包的內層迴圈；其他迴圈的 break 不算
class InnerBreakFinder(ast.NodeVisitor):
    def __init__(self):
        self.found = False
        self.lines = set()

    def visit_Break(self, node):
        self.found = True
        self.lines.add(node.lineno)

    def visit_For(self, node):
        pass

    def visit_While(self, node):
        pass

    def visit_AsyncFor(self, node):
        pass

    def visit_FunctionDef(self, node):
        pass

    def visit_AsyncFunctionDef(self, node):
        pass

    def visit_ClassDef(self, node):
        pass

has_required_loops = False
loop_candidates = []
for outer in ast.walk(tree):
    if not (isinstance(outer, ast.For)
            and isinstance(outer.iter, ast.Name)
            and outer.iter.id == "required"):
        continue
    # 起始程式指定外層 required、內層 my_bag
    for inner in outer.body:
        if not (isinstance(inner, ast.For)
                and isinstance(inner.iter, ast.Name)
                and inner.iter.id == "my_bag"):
            continue
        finder = InnerBreakFinder()
        for statement in inner.body:
            finder.visit(statement)
        if finder.found:
            has_required_loops = True
            loop_candidates.append((outer.lineno, inner.lineno, finder.lines))

assert has_required_loops, \
    "請用外層 for 遍歷 required、內層 for 遍歷 my_bag，並在內層找到物品後 break。"

actual_lines = [line.strip() for line in lines if line.strip()]
assert actual_lines == ["（你檢查了一下背包，簡章要求的五樣物品都帶齊了！）"], \
    "請保留起始程式的結果輸出，確認五樣必需品都帶齊。"


# 將測試背包注入「count 初始化之前」，保留玩家完整的計數程式、函式與輸出。
# 不改玩家初始程式，也不把玩家的 count 初始化換成正確答案。
def count_assignment(statement):
    if isinstance(statement, ast.Assign):
        return any(isinstance(target, ast.Name) and target.id == "count" for target in statement.targets)
    return isinstance(statement, ast.AnnAssign) and isinstance(statement.target, ast.Name) and statement.target.id == "count"

count_start = next((i for i, statement in enumerate(tree.body) if count_assignment(statement)), None)
assert count_start is not None, "請保留起始程式的 count 初始化，再用雙層迴圈累加。"

cases = [
    (expected_required.copy(), 5),
    (expected_required[:-1], 4),
    ([], 0),
    (expected_required[:-1] + ["准考證"], 4),
    (["手錶", "橡皮擦", "2B鉛筆", "身分證", "准考證"], 5),
    (["水壺", "漫畫"], 0),
    (expected_required + ["准考證", "手錶", "水壺"], 5),
]

for test_bag, expected_count in cases:
    probe = copy.deepcopy(tree)
    assignments = ast.parse("required = " + repr(expected_required) + "\nmy_bag = " + repr(test_bag)).body
    probe.body[count_start:count_start] = assignments
    # 新增的資料注入行不列入玩家執行追蹤。
    for statement in assignments:
        for node in ast.walk(statement):
            if hasattr(node, "lineno"):
                node.lineno = 0
                node.end_lineno = 0
    compiled = compile(ast.fix_missing_locations(probe), "<bag-validation>", "exec")
    scope = {"__builtins__": dict(vars(builtins)), "__name__": "__main__"}
    executed = set()
    steps = [0]
    def guard(frame, event, arg):
        if frame.f_code.co_filename == "<bag-validation>" and event == "line":
            steps[0] += 1
            assert steps[0] <= 30000, "背包驗證執行過久，請檢查迴圈。"
            executed.add(frame.f_lineno)
        return guard
    previous_trace = sys.gettrace()
    captured = io.StringIO()
    try:
        with contextlib.redirect_stdout(captured):
            sys.settrace(guard)
            exec(compiled, scope)
    finally:
        sys.settrace(previous_trace)
    assert scope.get("required") == expected_required and scope.get("my_bag") == test_bag, "計數時不可改動簡章或測試背包來湊答案。"
    answer = scope.get("count")
    assert type(answer) is int and answer == expected_count, "請實際比對物品：缺物品要少算，重複物品不能重複計數，不能直接設定 count=5。"
    assert any(outer_line in executed and inner_line in executed
               and (expected_count == 0 or bool(break_lines & executed))
               for outer_line, inner_line, break_lines in loop_candidates), "雙層 for 與找到物品時的 break 必須真的執行，不能放在不會執行的程式裡。"
```
solution:
```python
required = ["准考證", "身分證", "2B鉛筆", "橡皮擦", "手錶"]
my_bag = ["身分證", "2B鉛筆", "水壺", "准考證", "橡皮擦", "手錶"]
count = 0
for req in required:
    for item in my_bag:
        if item == req:
            count += 1
            break
if count == len(required):
    print("（你檢查了一下背包，簡章要求的五樣物品都帶齊了！）")
else:
    print(f"（好像還缺了點什麼……目前只帶了 {count}/{len(required)} 樣。）")
```
success: 准考證、身分證、2B鉛筆、橡皮擦、手錶，五樣都帶齊了。考場見！
@end

派森：外層用簡章、內層用書包，這樣就算你不小心放了兩支一樣的筆，也不會被算兩次。其實 Python 還有更簡單的寫法：

```python
required = ["准考證", "身分證", "2B鉛筆", "橡皮擦", "手錶"]
my_bag = ["身分證", "2B鉛筆", "水壺", "准考證", "橡皮擦"]
for req in required:
    if req not in my_bag:
        print(f"還缺：{req}")
```

你：出發！
（媽媽在門口塞給你一份培根蛋吐司，爸爸開車送你到考場。下車前，爸爸只說了一句：「盡力就好。」奶奶傳來一張照片：文昌帝君廟的香爐，配上三個愛心。）
成就：考場戰士
