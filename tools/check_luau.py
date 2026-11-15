#!/usr/bin/env python3
"""Static checks for the Luau sources of this project (no external dependencies).

Checks:
  * tokenizer errors (unterminated strings/comments)
  * block balance (function/if/do/while/for/repeat ... end/until)
  * bracket balance
  * use of undeclared identifiers / accidental global assignments
  * require() paths that do not resolve inside the Rojo tree
  * locale: en/it key parity, placeholder parity, keys used in code exist,
    every config id has its display-name key

The project style avoids Luau type annotations so these checks stay reliable.
Usage: python3 tools/check_luau.py [--strict]
"""
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "src")

KEYWORDS = {
    "and", "break", "do", "else", "elseif", "end", "false", "for", "function",
    "if", "in", "local", "nil", "not", "or", "repeat", "return", "then", "true",
    "until", "while", "continue",
}

GLOBALS = {
    # Lua / Luau
    "assert", "error", "getmetatable", "ipairs", "next", "pairs", "pcall", "print",
    "rawequal", "rawget", "rawlen", "rawset", "require", "select", "setmetatable",
    "tonumber", "tostring", "type", "typeof", "unpack", "xpcall", "_G", "_VERSION",
    "math", "string", "table", "coroutine", "os", "debug", "utf8", "bit32", "buffer",
    "gcinfo", "newproxy", "self",
    # Roblox
    "game", "workspace", "script", "task", "tick", "time", "wait", "delay", "spawn",
    "warn", "shared", "settings", "UserSettings", "elapsedTime", "plugin",
    "Instance", "Vector3", "Vector2", "CFrame", "Color3", "UDim", "UDim2", "Enum",
    "Ray", "RaycastParams", "OverlapParams", "TweenInfo", "NumberSequence",
    "NumberSequenceKeypoint", "ColorSequence", "ColorSequenceKeypoint", "NumberRange",
    "Rect", "BrickColor", "PhysicalProperties", "Region3", "Font", "Random",
    "DateTime", "Axes", "Faces", "PathWaypoint", "SharedTable", "Content",
    "Vector3int16", "Vector2int16", "Region3int16", "CatalogSearchParams",
    "DockWidgetPluginGuiInfo", "RotationCurveKey", "FloatCurveKey", "Path2DControlPoint",
}

OPS3 = ["...", "..=", "//="]
OPS2 = ["==", "~=", "<=", ">=", "..", "//", "->", "::", "+=", "-=", "*=", "/=", "%=", "^="]


class Tok:
    __slots__ = ("kind", "val", "line")

    def __init__(self, kind, val, line):
        self.kind, self.val, self.line = kind, val, line

    def __repr__(self):
        return f"{self.kind}:{self.val}@{self.line}"


def long_bracket(src, i):
    """If src[i:] starts a long bracket [==[ return (level, start_of_content) else None."""
    if src[i] != "[":
        return None
    j = i + 1
    level = 0
    while j < len(src) and src[j] == "=":
        level += 1
        j += 1
    if j < len(src) and src[j] == "[":
        return level, j + 1
    return None


def tokenize(src, errors, line_offset=0):
    toks = []
    i = 0
    n = len(src)
    line = 1 + line_offset
    while i < n:
        c = src[i]
        if c == "\n":
            line += 1
            i += 1
            continue
        if c in " \t\r":
            i += 1
            continue
        if src.startswith("--", i):
            lb = long_bracket(src, i + 2) if i + 2 < n else None
            if lb:
                level, start = lb
                close = "]" + "=" * level + "]"
                end = src.find(close, start)
                if end < 0:
                    errors.append((line, "unterminated long comment"))
                    return toks
                line += src.count("\n", i, end)
                i = end + len(close)
            else:
                end = src.find("\n", i)
                i = n if end < 0 else end
            continue
        if c in "\"'":
            j = i + 1
            while j < n and src[j] != c:
                if src[j] == "\\":
                    j += 2
                    continue
                if src[j] == "\n":
                    errors.append((line, "unterminated string"))
                    break
                j += 1
            toks.append(Tok("str", src[i + 1:j], line))
            i = j + 1
            continue
        if c == "`":
            j = i + 1
            parts = []
            while j < n and src[j] != "`":
                if src[j] == "\\":
                    j += 2
                    continue
                if src[j] == "{":
                    depth = 1
                    k = j + 1
                    while k < n and depth:
                        if src[k] == "{":
                            depth += 1
                        elif src[k] == "}":
                            depth -= 1
                        k += 1
                    inner = src[j + 1:k - 1]
                    parts.append((inner, line + src.count("\n", i, j)))
                    j = k
                    continue
                j += 1
            if j >= n:
                errors.append((line, "unterminated interpolated string"))
            toks.append(Tok("str", src[i + 1:j], line))
            for inner, ln in parts:
                toks.append(Tok("op", "(", ln))
                toks.extend(tokenize(inner, errors, ln - 1))
                toks.append(Tok("op", ")", ln))
            line += src.count("\n", i, j)
            i = j + 1
            continue
        if c == "[":
            lb = long_bracket(src, i)
            if lb:
                level, start = lb
                close = "]" + "=" * level + "]"
                end = src.find(close, start)
                if end < 0:
                    errors.append((line, "unterminated long string"))
                    return toks
                toks.append(Tok("str", src[start:end], line))
                line += src.count("\n", i, end)
                i = end + len(close)
                continue
        if c.isdigit() or (c == "." and i + 1 < n and src[i + 1].isdigit()):
            m = re.match(r"0[xX][0-9a-fA-F_]+|0[bB][01_]+|(\d[\d_]*)?(\.[\d_]*)?([eE][+-]?\d+)?", src[i:])
            val = m.group(0) or c
            toks.append(Tok("num", val, line))
            i += len(val)
            continue
        if c.isalpha() or c == "_":
            m = re.match(r"[A-Za-z_][A-Za-z0-9_]*", src[i:])
            w = m.group(0)
            toks.append(Tok("kw" if w in KEYWORDS else "id", w, line))
            i += len(w)
            continue
        for op in OPS3 + OPS2:
            if src.startswith(op, i):
                toks.append(Tok("op", op, line))
                i += len(op)
                break
        else:
            toks.append(Tok("op", c, line))
            i += 1
    return toks


def check_blocks(toks, errors):
    stack = []
    pending_do = 0
    brackets = []
    pairs = {")": "(", "]": "[", "}": "{"}
    for t in toks:
        if t.kind == "kw":
            v = t.val
            if v in ("function", "if", "repeat"):
                stack.append((v, t.line))
            elif v in ("while", "for"):
                stack.append((v, t.line))
                pending_do += 1
            elif v == "do":
                if pending_do > 0:
                    pending_do -= 1
                else:
                    stack.append(("do", t.line))
            elif v == "end":
                if not stack:
                    errors.append((t.line, "unexpected 'end'"))
                else:
                    kind, ln = stack.pop()
                    if kind == "repeat":
                        errors.append((t.line, f"'end' closes 'repeat' from line {ln}"))
            elif v == "until":
                if not stack or stack[-1][0] != "repeat":
                    errors.append((t.line, "'until' without 'repeat'"))
                else:
                    stack.pop()
        elif t.kind == "op":
            if t.val in "([{":
                brackets.append((t.val, t.line))
            elif t.val in ")]}":
                if not brackets or brackets[-1][0] != pairs[t.val]:
                    errors.append((t.line, f"unbalanced '{t.val}'"))
                    if brackets:
                        brackets.pop()
                else:
                    brackets.pop()
    for kind, ln in stack:
        errors.append((ln, f"'{kind}' never closed"))
    for b, ln in brackets:
        errors.append((ln, f"'{b}' never closed"))


def check_scopes(toks, errors, warnings):
    scopes = [set()]
    # block stack mirrors scopes: each entry = number of scopes pushed for that block
    blocks = []
    pending_loop = []  # loops waiting for their 'do'
    brace = []  # stack of booleans: inside table constructor
    i = 0
    n = len(toks)

    def declared(name):
        return any(name in s for s in scopes) or name in GLOBALS

    def push_scope(names=()):
        scopes.append(set(names))

    def prev(k=1):
        return toks[i - k] if i - k >= 0 else None

    def nxt(k=1):
        return toks[i + k] if i + k < n else None

    def parse_params(j):
        """toks[j] should be '('. Returns (names, index after ')')."""
        names = []
        if j >= n or toks[j].val != "(":
            return names, j
        j += 1
        while j < n and toks[j].val != ")":
            if toks[j].kind == "id":
                names.append(toks[j].val)
            j += 1
        return names, j + 1

    while i < n:
        t = toks[i]
        if t.kind == "kw":
            v = t.val
            if v == "local":
                nt = nxt()
                if nt and nt.kind == "kw" and nt.val == "function":
                    name_tok = nxt(2)
                    if name_tok and name_tok.kind == "id":
                        scopes[-1].add(name_tok.val)
                    params, j = parse_params(i + 3)
                    push_scope(params)
                    blocks.append(("function", 1))
                    i = j
                    continue
                j = i + 1
                names = []
                while j < n and toks[j].kind == "id":
                    names.append(toks[j].val)
                    j += 1
                    if j < n and toks[j].val == ",":
                        j += 1
                        continue
                    break
                # declare after the initializer would be more exact; declaring now
                # is good enough for this codebase (no `local x = x` patterns).
                for nm in names:
                    scopes[-1].add(nm)
                i = j
                continue
            if v == "function":
                p = prev()
                j = i + 1
                is_method = False
                if j < n and toks[j].kind == "id":
                    first = toks[j].val
                    if not declared(first):
                        errors.append((toks[j].line, f"function assigns undeclared global '{first}'"))
                    j += 1
                    while j < n and toks[j].val in (".", ":"):
                        if toks[j].val == ":":
                            is_method = True
                        j += 2
                params, j = parse_params(j)
                if is_method:
                    params.append("self")
                push_scope(params)
                blocks.append(("function", 1))
                i = j
                continue
            if v in ("for",):
                j = i + 1
                names = []
                while j < n and toks[j].kind == "id":
                    names.append(toks[j].val)
                    j += 1
                    if j < n and toks[j].val == ",":
                        j += 1
                        continue
                    break
                # loop variables are not visible in the iterator expression; keep it simple
                pending_loop.append(names)
                i = j
                continue
            if v == "while":
                pending_loop.append([])
                i += 1
                continue
            if v == "do":
                if pending_loop:
                    push_scope(pending_loop.pop())
                else:
                    push_scope()
                blocks.append(("do", 1))
                i += 1
                continue
            if v in ("then",):
                push_scope()
                blocks.append(("then", 1))
                i += 1
                continue
            if v in ("elseif", "else"):
                # close the previous branch scope
                if blocks and blocks[-1][0] == "then":
                    blocks.pop()
                    scopes.pop()
                if v == "else":
                    push_scope()
                    blocks.append(("then", 1))
                i += 1
                continue
            if v == "repeat":
                push_scope()
                blocks.append(("repeat", 1))
                i += 1
                continue
            if v in ("end", "until"):
                if blocks:
                    _, cnt = blocks.pop()
                    for _ in range(cnt):
                        if len(scopes) > 1:
                            scopes.pop()
                i += 1
                continue
            i += 1
            continue
        if t.kind == "op":
            if t.val == "{":
                brace.append(True)
            elif t.val == "}":
                if brace:
                    brace.pop()
            elif t.val in ("(", "["):
                brace.append(False)
            elif t.val in (")", "]"):
                if brace:
                    brace.pop()
            i += 1
            continue
        if t.kind == "id":
            p = prev()
            if p is not None and p.kind == "op" and p.val in (".", ":"):
                i += 1
                continue
            nt = nxt()
            if brace and brace[-1] and nt is not None and nt.val == "=" and p is not None and p.val in ("{", ",", ";"):
                i += 1
                continue
            if not declared(t.val):
                stmt_start = p is None or p.kind == "kw" and p.val in ("do", "then", "else", "end", "repeat") or (
                    p.kind in ("id", "str", "num") or p.val in (")", "]", "}")
                )
                if nt is not None and nt.val == "=" and stmt_start:
                    errors.append((t.line, f"assignment to undeclared global '{t.val}'"))
                else:
                    errors.append((t.line, f"undeclared identifier '{t.val}'"))
            i += 1
            continue
        i += 1


# ---------------------------------------------------------------- rojo tree

def rojo_name(fname):
    for suffix, cls in ((".server.luau", "Script"), (".client.luau", "LocalScript"), (".luau", "ModuleScript")):
        if fname.endswith(suffix):
            return fname[: -len(suffix)], cls
    return None, None


def build_tree():
    """Returns dict: instance path tuple -> file path (or None for folders)."""
    proj = json.load(open(os.path.join(ROOT, "default.project.json")))
    nodes = {}

    def add_path(inst_path, fs_path):
        if os.path.isfile(fs_path):
            nodes[inst_path] = fs_path
            return
        init = None
        for nm in ("init.luau", "init.server.luau", "init.client.luau"):
            if os.path.exists(os.path.join(fs_path, nm)):
                init = os.path.join(fs_path, nm)
        nodes[inst_path] = init
        for entry in sorted(os.listdir(fs_path)):
            full = os.path.join(fs_path, entry)
            if entry.startswith("init.") and entry.endswith(".luau"):
                continue
            if os.path.isdir(full):
                add_path(inst_path + (entry,), full)
            else:
                name, cls = rojo_name(entry)
                if name:
                    nodes[inst_path + (name,)] = full

    def walk(node, inst_path):
        if "$path" in node:
            add_path(inst_path, os.path.join(ROOT, node["$path"]))
        else:
            nodes.setdefault(inst_path, None)
        for k, v in node.items():
            if not k.startswith("$") and isinstance(v, dict):
                walk(v, inst_path + (k,))

    walk(proj["tree"], ())
    return nodes


def check_requires(nodes, errors_by_file):
    by_file = {v: k for k, v in nodes.items() if v}
    shared_root = ("ReplicatedStorage", "Shared")
    pat = re.compile(r"require\(\s*([A-Za-z_][A-Za-z0-9_.]*)\s*\)")
    for fpath, inst in by_file.items():
        src = open(fpath, encoding="utf-8").read()
        for m in pat.finditer(src):
            expr = m.group(1).split(".")
            line = src.count("\n", 0, m.start()) + 1
            if expr[0] == "script":
                cur = inst
                rest = expr[1:]
            elif expr[0] == "Shared":
                cur = shared_root
                rest = expr[1:]
            else:
                continue  # dynamic require (e.g. module variable) — not checked
            ok = True
            for part in rest:
                if part == "Parent":
                    cur = cur[:-1]
                else:
                    cur = cur + (part,)
                    if cur not in nodes:
                        ok = False
                        break
            if ok and nodes.get(cur) is None:
                ok = False
            if not ok:
                errors_by_file.setdefault(fpath, []).append((line, f"require path not found: {m.group(1)}"))


# ---------------------------------------------------------------- locale

LOC_RE = re.compile(r'\["([^"]+)"\]\s*=\s*"((?:[^"\\]|\\.)*)"')
PARAM_RE = re.compile(r"\{([a-zA-Z_]+)\}")
CONFIG_PREFIX = {
    "Items": "item", "Ingredients": "ing", "Recipes": "rec", "Licenses": "lic",
    "Upgrades": "upg", "Ads": "ad", "Staff": "staff", "Expansions": "zone",
    "Customers": "cust", "Surfaces": "surf", "Franchise": "city", "Events": "event",
    "Sets": "set", "Quests": "quest",
}
KEY_USE_RE = re.compile(r'(?:\bT|Locale\.t|notify|notifyAll|toast|hint|say)\(\s*(?:[A-Za-z_.]+\s*,\s*)?"([a-z][a-z0-9_]*\.[a-z0-9_.]+)"')
KEY_LITERAL_RE = re.compile(r'"((?:ui|msg|hint|tut|step|cat|area|place|stat|day|rev|perm|set|gp|dp|ach|daily|quest|dev|lb|fx|shop|build|menu|lic|upg|staff|zone|cust|city|event|ing|rec|item|surf|ad|role|kind|tab|time|unit|load|world|err)\.[a-z0-9_.]+)"')


def load_locale(path):
    src = open(path, encoding="utf-8").read()
    return dict(LOC_RE.findall(src))


def check_locale(problems):
    loc_dir = os.path.join(SRC, "shared", "Locale")
    en = load_locale(os.path.join(loc_dir, "en.luau"))
    it = load_locale(os.path.join(loc_dir, "it.luau"))
    for k in sorted(set(en) - set(it)):
        problems.append(f"locale: key missing in it: {k}")
    for k in sorted(set(it) - set(en)):
        problems.append(f"locale: key missing in en: {k}")
    for k in sorted(set(en) & set(it)):
        if set(PARAM_RE.findall(en[k])) != set(PARAM_RE.findall(it[k])):
            problems.append(f"locale: placeholder mismatch for {k}")
    cfg_dir = os.path.join(SRC, "shared", "Config")
    for mod, prefix in CONFIG_PREFIX.items():
        p = os.path.join(cfg_dir, mod + ".luau")
        if not os.path.exists(p):
            continue
        src = open(p, encoding="utf-8").read()
        for cid in re.findall(r'\bid\s*=\s*"([a-z0-9_]+)"', src):
            if f"{prefix}.{cid}" not in en:
                problems.append(f"locale: missing name key {prefix}.{cid} (Config/{mod})")
    for dirpath, _, files in os.walk(SRC):
        for f in files:
            if not f.endswith(".luau") or dirpath == loc_dir:
                continue
            fp = os.path.join(dirpath, f)
            src = open(fp, encoding="utf-8").read()
            used = set(KEY_USE_RE.findall(src)) | set(KEY_LITERAL_RE.findall(src))
            for k in sorted(used):
                if k not in en and not k.endswith("."):
                    problems.append(f"locale: key used but not defined: {k} ({os.path.relpath(fp, ROOT)})")
    return en, it


def main():
    total = 0
    nodes = build_tree()
    errors_by_file = {}
    for dirpath, _, files in os.walk(SRC):
        for f in sorted(files):
            if not f.endswith(".luau"):
                continue
            fp = os.path.join(dirpath, f)
            src = open(fp, encoding="utf-8").read()
            errs = []
            if not src.startswith("--!"):
                errs.append((1, "missing --!strict/--!nonstrict header"))
            toks = tokenize(src, errs)
            check_blocks(toks, errs)
            check_scopes(toks, errs, [])
            if errs:
                errors_by_file.setdefault(fp, []).extend(errs)
    check_requires(nodes, errors_by_file)
    for fp in sorted(errors_by_file):
        for line, msg in sorted(set(errors_by_file[fp])):
            print(f"{os.path.relpath(fp, ROOT)}:{line}: {msg}")
            total += 1
    problems = []
    if os.path.exists(os.path.join(SRC, "shared", "Locale", "en.luau")):
        en, it = check_locale(problems)
        for p in problems:
            print(p)
        total += len(problems)
        print(f"locale keys: en={len(en)} it={len(it)}")
    nfiles = sum(1 for v in nodes.values() if v)
    print(f"checked {nfiles} files, {total} problem(s)")
    return 1 if total else 0


if __name__ == "__main__":
    sys.exit(main())
