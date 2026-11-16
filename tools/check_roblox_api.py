#!/usr/bin/env python3
"""Checks Roblox API usage against an API dump (classes, enums, services, members).

Get the dump (a JSON data file) once:
  curl -sSL -o build/API-Dump.json https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/roblox/API-Dump.json
Usage: python3 tools/check_roblox_api.py [path/to/API-Dump.json]

Checks:
  * Enum.X.Y exists
  * Instance.new("Class") is a creatable class; game:GetService("X") is a service
  * members used on variables created by Instance.new / GetService / Kit.new
  * property names in Kit.new("Class", { ... }) tables
  * material names in Config/Surfaces.luau
"""
import glob
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def load(path):
    d = json.load(open(path, encoding="utf-8"))
    classes = {c["Name"]: c for c in d["Classes"]}
    enums = {e["Name"]: {i["Name"] for i in e["Items"]} for e in d["Enums"]}
    return classes, enums


def members(classes, name, cache={}):
    if name in cache:
        return cache[name]
    out = {}
    c = classes.get(name)
    while c:
        for m in c.get("Members", []):
            out.setdefault(m["Name"], m)
        sup = c.get("Superclass")
        c = classes.get(sup) if sup and sup != "<<<ROOT>>>" else None
    cache[name] = out
    return out


def table_keys(src, start):
    """Top-level keys of the table literal starting at src[start] == '{'."""
    depth = 0
    keys = []
    i = start
    n = len(src)
    while i < n:
        ch = src[i]
        if ch in "{([":
            depth += 1
        elif ch in "})]":
            depth -= 1
            if depth == 0:
                break
        elif ch == '"':
            j = src.find('"', i + 1)
            i = j if j > 0 else i
        elif depth == 1:
            m = re.match(r"([A-Za-z_][A-Za-z0-9_]*)\s*=(?!=)", src[i:])
            prev = src[:i].rstrip()[-1:] if src[:i].rstrip() else ""
            if m and prev in ("{", ","):
                keys.append(m.group(1))
                i += len(m.group(0)) - 1
        i += 1
    return keys


def main():
    dump = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, "build", "API-Dump.json")
    if not os.path.exists(dump):
        print("API dump not found: " + dump)
        return 2
    classes, enums = load(dump)
    problems, warnings = [], []
    files = glob.glob(os.path.join(ROOT, "src", "**", "*.luau"), recursive=True)
    all_methods, all_props = set(), set()
    for c in classes.values():
        for mbr in c.get("Members", []):
            if mbr["MemberType"] in ("Function", "Callback", "Event"):
                all_methods.add(mbr["Name"])
            elif mbr["MemberType"] == "Property":
                all_props.add(mbr["Name"])
    # datatype methods (CFrame, Vector3, Color3, TweenInfo...) and our own PascalCase API
    all_methods |= {"Lerp", "Inverse", "ToHSV", "ToWorldSpace", "ToObjectSpace", "PointToWorldSpace", "PointToObjectSpace",
                    "Cross", "Dot", "FuzzyEq", "Abs", "Floor", "Ceil", "Max", "Min", "NextNumber", "NextInteger", "Clone",
                    "Connect", "Once", "Wait", "Disconnect", "ConnectParallel", "GetCurrentPage", "AdvanceToNextPageAsync",
                    "ToHex", "Emit", "GetComponents", "Orthonormalize", "ToEulerAnglesXYZ", "ToEulerAnglesYXZ", "ToOrientation"}
    own_methods, own_fields = set(), set()
    for path in files:
        text = open(path, encoding="utf-8").read()
        own_methods |= set(re.findall(r"function\s+[A-Za-z_]+:([A-Za-z0-9_]+)", text))
        own_fields |= set(re.findall(r"^[A-Za-z_]+\.([A-Z][A-Za-z0-9_]*)\s*=", text, re.M))
    for path in files:
        raw = open(path, encoding="utf-8").read()
        # blank out comments (keep line numbers)
        src = re.sub(r"--\[\[.*?\]\]", lambda m: re.sub(r"[^\n]", " ", m.group(0)), raw, flags=re.S)
        src = re.sub(r"--[^\n]*", "", src)
        rel = os.path.relpath(path, ROOT)

        def line(pos):
            return src.count("\n", 0, pos) + 1

        for m in re.finditer(r"\bEnum\.([A-Za-z]+)\.([A-Za-z0-9_]+)", src):
            e, item = m.group(1), m.group(2)
            if e not in enums:
                problems.append(f"{rel}:{line(m.start())}: unknown enum Enum.{e}")
            elif item not in enums[e]:
                problems.append(f"{rel}:{line(m.start())}: Enum.{e} has no item {item}")
        var_class = {}
        for m in re.finditer(r'(?:local\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*=\s*Instance\.new\("([A-Za-z]+)"', src):
            var, cls = m.group(1), m.group(2)
            c = classes.get(cls)
            if not c:
                problems.append(f"{rel}:{line(m.start())}: unknown class {cls}")
                continue
            if "NotCreatable" in (c.get("Tags") or []):
                problems.append(f"{rel}:{line(m.start())}: {cls} is not creatable")
            var_class.setdefault(var, set()).add(cls)
        for m in re.finditer(r'Instance\.new\("([A-Za-z]+)"', src):
            if m.group(1) not in classes:
                problems.append(f"{rel}:{line(m.start())}: unknown class {m.group(1)}")
        for m in re.finditer(r'(?:local\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*=\s*game:GetService\("([A-Za-z]+)"\)(?![:.\[])', src):
            var, cls = m.group(1), m.group(2)
            c = classes.get(cls)
            if not c or "Service" not in (c.get("Tags") or []):
                problems.append(f"{rel}:{line(m.start())}: {cls} is not a service")
            else:
                var_class.setdefault(var, set()).add(cls)
        for m in re.finditer(r'game:GetService\("([A-Za-z]+)"\)', src):
            c = classes.get(m.group(1))
            if not c or "Service" not in (c.get("Tags") or []):
                problems.append(f"{rel}:{line(m.start())}: {m.group(1)} is not a service")
        for var, clsset in var_class.items():
            if len(clsset) != 1:
                continue
            # only variables assigned once in the file are reliable
            if len(re.findall(r"(?<![A-Za-z0-9_.])%s\s*=(?!=)" % re.escape(var), src)) != 1:
                continue
            cls = next(iter(clsset))
            mem = members(classes, cls)
            for m in re.finditer(r"(?<![A-Za-z0-9_.])%s([.:])([A-Za-z_][A-Za-z0-9_]*)" % re.escape(var), src):
                name = m.group(2)
                if name in mem:
                    tags = mem[name].get("Tags") or []
                    if "Deprecated" in tags:
                        warnings.append(f"{rel}:{line(m.start())}: {cls}.{name} is deprecated")
                    continue
                if m.group(1) == "." and cls in ("Folder", "Model") :
                    continue  # child access
                problems.append(f"{rel}:{line(m.start())}: {cls} has no member {name} ({var}{m.group(1)}{name})")
        for m in re.finditer(r'Kit\.new\("([A-Za-z]+)",\s*\{', src):
            cls = m.group(1)
            if cls not in classes:
                problems.append(f"{rel}:{line(m.start())}: unknown class {cls}")
                continue
            mem = members(classes, cls)
            for key in table_keys(src, m.end() - 1):
                if key == "Parent" or key.startswith("On"):
                    continue
                if key not in mem or mem[key]["MemberType"] != "Property":
                    problems.append(f"{rel}:{line(m.start())}: {cls} has no property {key}")
        for m in re.finditer(r":([A-Z][A-Za-z0-9]*)\(", src):
            if m.group(1) not in all_methods and m.group(1) not in own_methods:
                problems.append(f"{rel}:{line(m.start())}: no Roblox method named {m.group(1)}")
        for m in re.finditer(r"\b[a-z][A-Za-z0-9_]*\.([A-Z][A-Za-z0-9]*)\s*=(?!=)", src):
            name = m.group(1)
            if name not in all_props and name not in own_fields:
                warnings.append(f"{rel}:{line(m.start())}: {name} is not a Roblox property (module field?)")
    surfaces = open(os.path.join(ROOT, "src", "shared", "Config", "Surfaces.luau"), encoding="utf-8").read()
    for mat in re.findall(r'material = "([A-Za-z]+)"', surfaces):
        if mat not in enums["Material"]:
            problems.append(f"Config/Surfaces.luau: unknown material {mat}")
    for p in sorted(set(problems)):
        print(p)
    for w in sorted(set(warnings)):
        print("warning: " + w)
    print(f"roblox api check: {len(set(problems))} problem(s), {len(set(warnings))} warning(s)")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
