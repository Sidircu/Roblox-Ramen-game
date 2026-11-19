#!/usr/bin/env python3
"""Runs the real server code without Roblox Studio and plays scripted scenarios against it.

The server scripts (src/server) and shared modules (src/shared) run in Lua 5.4 (lupa) on top of a
simulated Roblox: a virtual clock with task.wait/spawn/delay, instances with properties, children,
attributes, tags and events, the services the game uses, in-memory data stores that reject values
Roblox could not save, and fake players with characters (tools/sim/env.lua, tools/sim/services.lua).

A scenario (tools/sim/scenarios/<name>.lua) adds players, fires remotes, advances time and checks
the results; any error raised by the game (uncaught errors, failed Init/Start, warnings with
"failed"/"error") or a failed check makes the run fail. A scenario can also start the real client
of one player on a simulated phone, tablet or computer (Sim.startClient, tools/sim/client.lua):
the client scripts run too, remotes go both ways and the GUI is laid out like on that screen.

  python3 tools/sim.py                  # every scenario (except the slow ones)
  python3 tools/sim.py core saves       # only these
  python3 tools/sim.py --verbose core   # also print notifications and game prints
  python3 tools/sim.py progression --hours=4   # a slow one (first line "-- (slow)"): a bot plays for hours
  python3 tools/sim.py --seed=7 core           # another random sequence (runs are the same for a seed)
Requires: pip install lupa
"""
import os
import re
import sys
import time

from lupa import lua54

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "src")
SIM = os.path.join(ROOT, "tools", "sim")
sys.path.insert(0, os.path.join(ROOT, "tools"))

COMPOUND = re.compile(r"^(\s*)([A-Za-z_][A-Za-z0-9_.\[\]\"':]*)\s*(\+|-|\*|/|\.\.)=\s*(.+?)\s*$")


def luau_to_lua(src):
    out = []
    for line in src.split("\n"):
        m = COMPOUND.match(line)
        if m and not line.strip().startswith("--"):
            ind, lhs, op, rhs = m.groups()
            line = f"{ind}{lhs} = {lhs} {op} ({rhs})"
        out.append(line)
    return "\n".join(out)


def project_entries():
    """(instance path, kind, source file) for every script under src/server and src/shared."""
    out = []
    mounts = [
        ("shared", "ReplicatedStorage/Shared"),
        ("server", "ServerScriptService/Server"),
        ("client", "StarterPlayer/StarterPlayerScripts/Client"),
        ("first", "ReplicatedFirst"),
    ]
    for folder, mount in mounts:
        base = os.path.join(SRC, folder)
        for dirpath, dirnames, filenames in os.walk(base):
            dirnames.sort()
            rel = os.path.relpath(dirpath, base)
            parts = [] if rel == "." else rel.split(os.sep)
            for f in sorted(filenames):
                if not f.endswith(".luau"):
                    continue
                full = os.path.join(dirpath, f)
                name = f[: -len(".luau")]
                kind = "ModuleScript"
                if name.endswith(".server"):
                    name, kind = name[: -len(".server")], "Script"
                elif name.endswith(".client"):
                    name, kind = name[: -len(".client")], "LocalScript"
                if name == "init":
                    inst = "/".join([mount] + parts)
                else:
                    inst = "/".join([mount] + parts + [name])
                out.append((inst, kind, full))
    return out


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    verbose = "--verbose" in sys.argv
    scenario_dir = os.path.join(SIM, "scenarios")
    available = sorted(f[:-4] for f in os.listdir(scenario_dir) if f.endswith(".lua"))

    def slow(name):
        with open(os.path.join(scenario_dir, name + ".lua"), encoding="utf-8") as fh:
            return fh.readline().startswith("-- (slow)")

    chosen = args or [n for n in available if not slow(n)]
    for name in chosen:
        if name not in available:
            print(f"unknown scenario {name} (available: {', '.join(available)})")
            return 2
    failed = 0
    hours = next((float(a.split("=", 1)[1]) for a in sys.argv[1:] if a.startswith("--hours=")), None)
    seed = next((int(a.split("=", 1)[1]) for a in sys.argv[1:] if a.startswith("--seed=")), None)
    for name in chosen:
        ok = run(name, verbose, hours, seed)
        failed += 0 if ok else 1
    print(f"\n{len(chosen) - failed} scenario(s) passed, {failed} failed")
    return 1 if failed else 0


def make_runtime(verbose=False, setup=None, seed=None):
    """A Lua state with the simulated Roblox and the project mounted (tools/sim/*.lua).
    setup(lua) runs before the boot script (e.g. to give Lua better text metrics); seed picks the
    random sequence (the same seed plays the same run)."""
    lua = lua54.LuaRuntime(unpack_returned_tuples=True)
    lua.globals()["__seed"] = seed
    sources = {}

    def read(path):
        if path not in sources:
            with open(path, encoding="utf-8") as fh:
                sources[path] = luau_to_lua(fh.read())
        return sources[path]

    lua.globals()["__read"] = read
    for f in (os.path.join(ROOT, "tools", "preview", "mock.lua"), os.path.join(SIM, "env.lua"), os.path.join(SIM, "services.lua")):
        with open(f, encoding="utf-8") as fh:
            lua.execute(fh.read())
    lua.globals().Sim.verbose = verbose
    entries = lua.table_from([lua.table_from([a, b, c]) for a, b, c in project_entries()])
    lua.globals()["__entries"] = entries
    for f in ("boot.lua", "gui.lua", "client.lua"):
        with open(os.path.join(SIM, f), encoding="utf-8") as fh:
            lua.execute(fh.read())
    if setup:
        setup(lua)
    return lua


def run_scenario(lua, path, label, max_time=6 * 3600):
    with open(path, encoding="utf-8") as fh:
        scenario = luau_to_lua(fh.read())
    return lua.globals().Sim.runScenario(scenario, "@scenarios/" + label + ".lua", max_time)


def run(name, verbose, hours=None, seed=None):
    t0 = time.time()
    lua = make_runtime(verbose, seed=seed)
    if hours:
        lua.globals().Sim.progressionHours = hours
    print(f"=== scenario {name}")
    result = run_scenario(lua, os.path.join(SIM, "scenarios", name + ".lua"), name, 30 * 3600)
    errors = list(lua.globals().Sim.errors.values())
    passed = result and not errors
    for e in errors:
        print("  ERROR", e)
    status = "PASS" if passed else "FAIL"
    print(f"=== {status} {name} ({lua.globals().Sim.now:.0f} s simulated, {time.time() - t0:.1f} s real, {lua.globals().Sim.checks} checks)")
    return passed


if __name__ == "__main__":
    sys.exit(main())
