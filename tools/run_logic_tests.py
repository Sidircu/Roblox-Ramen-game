#!/usr/bin/env python3
"""Runs the pure Luau logic/config modules in a Lua 5.1 runtime (lupa) and executes tests/*.lua.
The modules only use Lua syntax plus a few Luau std functions, which are polyfilled here.
Usage: pip install lupa && python3 tools/run_logic_tests.py
"""
import glob
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "src")

try:
    from lupa import lua51 as lupa_mod
except ImportError:
    import lupa as lupa_mod

PRELUDE = r"""
math.clamp = function(x, a, b) if x < a then return a elseif x > b then return b end return x end
math.round = function(x) return math.floor(x + 0.5) end
math.sign = function(x) if x > 0 then return 1 elseif x < 0 then return -1 end return 0 end
table.clone = function(t) local o = {} for k, v in pairs(t) do o[k] = v end return o end
table.find = function(t, v) for i, x in ipairs(t) do if x == v then return i end end return nil end
table.clear = function(t) for k in pairs(t) do t[k] = nil end end
table.unpack = table.unpack or unpack
string.split = function(s, sep)
  local out = {}
  for piece in (s .. sep):gmatch("(.-)" .. sep:gsub("%p", "%%%0")) do table.insert(out, piece) end
  return out
end
local cache = {}
local function node(path)
  return setmetatable({ __path = path }, { __index = function(t, k)
    if k == "Parent" then return node(path:match("^(.*)/[^/]+$")) end
    return node(path .. "/" .. k)
  end })
end
function require(n)
  local p = rawget(n, "__path")
  if cache[p] ~= nil then return cache[p] end
  local src = __read(p)
  if not src then error("module not found: " .. p) end
  local chunk, err = loadstring(src, "@" .. p)
  if not chunk then error(err) end
  local env = setmetatable({ script = node(p) }, { __index = _G })
  setfenv(chunk, env)
  local result = chunk()
  cache[p] = result
  return result
end
Shared = node("shared")
local passed, failed = 0, 0
function test(name, fn)
  local ok, err = pcall(fn)
  if ok then passed = passed + 1 else failed = failed + 1; print("FAIL " .. name .. ": " .. tostring(err)) end
end
function expect(cond, msg) if not cond then error(msg or "expectation failed", 2) end end
function near(a, b, eps) return math.abs(a - b) <= (eps or 1e-6) end
function results() return passed, failed end
"""


def read_module(path):
    base = os.path.join(SRC, *path.split("/"))
    for candidate in (base + ".luau", os.path.join(base, "init.luau")):
        if os.path.exists(candidate):
            return open(candidate, encoding="utf-8").read()
    return None


def main():
    lua = lupa_mod.LuaRuntime(unpack_returned_tuples=True)
    lua.globals().__read = read_module
    lua.execute(PRELUDE)
    for spec in sorted(glob.glob(os.path.join(ROOT, "tests", "*.lua"))):
        print("running", os.path.relpath(spec, ROOT))
        lua.execute(open(spec, encoding="utf-8").read())
    passed, failed = lua.eval("results()")
    print(f"{passed} passed, {failed} failed")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
