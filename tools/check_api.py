#!/usr/bin/env python3
"""Checks cross-module calls through the service registries:
Core.S.<Service>.<member> (server) and Core.C.<Controller>.<member> (client) must be defined
in the target module (function X.member / X.member = ...)."""
import os, re, sys, glob
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

def defined(path):
    src = open(path, encoding="utf-8").read()
    m = re.search(r"^return\s+([A-Za-z_]+)\s*$", src, re.M)
    name = m.group(1) if m else None
    out = set()
    if name:
        out |= set(re.findall(r"function\s+%s[.:]([A-Za-z_]+)" % name, src))
        out |= set(re.findall(r"^%s\.([A-Za-z_]+)\s*=" % name, src, re.M))
        # table constructor fields: local X = { a = ..., }
        m2 = re.search(r"local\s+%s\s*=\s*\{(.*?)\n\}" % name, src, re.S)
        if m2:
            out |= set(re.findall(r"^\s*([A-Za-z_]+)\s*=", m2.group(1), re.M))
    return out

def main():
    server = {os.path.basename(p)[:-5]: defined(p) for p in glob.glob(os.path.join(ROOT, "src/server/Services/*.luau"))}
    client = {os.path.basename(p)[:-5]: defined(p) for p in glob.glob(os.path.join(ROOT, "src/client/Controllers/*.luau"))}
    problems = 0
    for path in glob.glob(os.path.join(ROOT, "src/**/*.luau"), recursive=True):
        src = open(path, encoding="utf-8").read()
        rel = os.path.relpath(path, ROOT)
        for reg, table in (("S", server), ("C", client)):
            for m in re.finditer(r"(?:Core\.%s|\bS)\.([A-Z][A-Za-z]+)\.([A-Za-z_]+)" % reg if reg == "S" else r"Core\.C\.([A-Z][A-Za-z]+)\.([A-Za-z_]+)", src):
                mod, member = m.group(1), m.group(2)
                if reg == "S" and "src/server" not in path:
                    continue
                if mod not in table:
                    print(f"{rel}: unknown module {reg}.{mod}")
                    problems += 1
                elif member not in table[mod]:
                    line = src.count("\n", 0, m.start()) + 1
                    print(f"{rel}:{line}: {reg}.{mod}.{member} is not defined")
                    problems += 1
    print(f"api check: {problems} problem(s)")
    return 1 if problems else 0

if __name__ == "__main__":
    sys.exit(main())
