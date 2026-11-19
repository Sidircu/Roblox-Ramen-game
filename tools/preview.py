#!/usr/bin/env python3
"""Renders the procedural models to PNG without Roblox (for checking proportions and details).

It runs the real builder modules (src/shared/Models) on a small Roblox API mock
(tools/preview/mock.lua) through lupa, then draws the parts with matplotlib.

  python3 tools/preview.py item sushi_station out.png
  python3 tools/preview.py category lighting out.png
  python3 tools/preview.py dish shoyu_ramen out.png
  python3 tools/preview.py facade out.png        (street view of the restaurant)
  python3 tools/preview.py interior out.png      (roof removed, starter layout)
  python3 tools/preview.py street out.png   [--focus=xmin,xmax,zmin,zmax] frames an area
  python3 tools/preview.py plots out.png     (the street of four restaurants, two of them empty lots)
  python3 tools/preview.py people casual suit tourist elder trendy vip child:casual staff:staff_waiter casual@angry out.png
  --basic   plain starting look (no renovations / detail styles); default is the finished look
  --swap=stool_wood:stool_red   --place=id@x,z,r,s[,y];...   --surfaces=zone=floor_id/wall_id
Requires: pip install lupa matplotlib numpy
"""
import math
import os
import re
import sys

import numpy as np
import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402
from mpl_toolkits.mplot3d.art3d import Poly3DCollection  # noqa: E402
from lupa import lua54  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "src")

COMPOUND = re.compile(r"^(\s*)([A-Za-z_][A-Za-z0-9_.\[\]\"']*)\s*(\+|-|\*|/|\.\.)=\s*(.+?)\s*$")


def luau_to_lua(src):
    out = []
    for line in src.split("\n"):
        m = COMPOUND.match(line)
        if m and not line.strip().startswith("--"):
            ind, lhs, op, rhs = m.groups()
            line = f"{ind}{lhs} = {lhs} {op} ({rhs})"
        out.append(line)
    return "\n".join(out)


def read_module(path):
    base = os.path.join(SRC, *path.split("/"))
    for cand in (base + ".luau", os.path.join(base, "init.luau")):
        if os.path.exists(cand):
            return luau_to_lua(open(cand, encoding="utf-8").read())
    return None


def list_dir(path):
    d = os.path.join(SRC, *path.split("/"))
    if not os.path.isdir(d):
        return []
    return sorted(f[:-5] for f in os.listdir(d) if f.endswith(".luau") and not f.startswith("init."))


PRELUDE = r"""
math.clamp = function(x, a, b) if x < a then return a elseif x > b then return b end return x end
math.round = function(x) return math.floor(x + 0.5) end
table.clone = function(t) local o = {} for k, v in pairs(t) do o[k] = v end return o end
table.find = function(t, v) for i, x in ipairs(t) do if x == v then return i end end return nil end
table.clear = function(t) for k in pairs(t) do t[k] = nil end end
string.split = function(s, sep)
  local out = {}
  for piece in (s .. sep):gmatch("(.-)" .. sep:gsub("%p", "%%%0")) do table.insert(out, piece) end
  return out
end
task = { wait = function() end, spawn = function(f, ...) f(...) end, defer = function(f, ...) f(...) end, delay = function() end }
warn = function(...) print("WARN", ...) end
local cache = {}
local node
node = function(path)
  local name = path:match("([^/]+)$")
  return setmetatable({ __path = path }, { __index = function(t, k)
    if k == "Parent" then return node(path:match("^(.*)/[^/]+$")) end
    if k == "Name" then return name end
    if k == "GetChildren" then
      return function()
        local out = {}
        for _, n in ipairs(__list(path)) do table.insert(out, node(path .. "/" .. n)) end
        return out
      end
    end
    if k == "IsA" then return function(_, c) return c == "ModuleScript" end end
    if k == "WaitForChild" or k == "FindFirstChild" then return function(_, n) return node(path .. "/" .. n) end end
    return node(path .. "/" .. k)
  end })
end
function require(n)
  local p = rawget(n, "__path")
  if cache[p] ~= nil then return cache[p] end
  local src = __read(p)
  if not src then error("module not found: " .. p) end
  local env = setmetatable({ script = node(p) }, { __index = _G })
  local chunk, err = load(src, "@" .. p, "t", env)
  if not chunk then error(err) end
  local result = chunk()
  cache[p] = result
  return result
end
Shared = node("shared")
"""

SCENES = r"""
local Registry = require(Shared.Models.Registry)
Registry.load()
local Items = require(Shared.Config.Items)
local Recipes = require(Shared.Config.Recipes)

function scene_items(ids)
  local root = Instance.new("Model")
  local x, z, rowDepth = 0, 0, 0
  local perRow = math.max(2, math.ceil(math.sqrt(#ids)))
  for i, id in ipairs(ids) do
    local item = Items.byId[id]
    local m = Registry.build(id, __basic and { styles = {} } or nil)
    local w = item.size[1]
    Registry.place(m, x + w / 2, 0, z, 0)
    m.Parent = root
    x = x + w + 1.5
    rowDepth = math.max(rowDepth, item.size[3])
    if i % perRow == 0 then
      x = 0
      z = z + rowDepth + 2.5
      rowDepth = 0
    end
  end
  return root
end

function scene_dish(ids)
  -- grid of dishes; "ing:<id>" ingredient, "box:<id>" supplier box, "openbox:<id>" carried box, "dirty:bowl", "tool:knife", "stack:clean"
  local root = Instance.new("Model")
  local cols = math.ceil(math.sqrt(#ids))
  for i, id in ipairs(ids) do
    local kind, rest = string.match(id, "^(%a+):(.+)$")
    local m
    if kind == "ing" then m = Registry.food("ingredient", rest)
    elseif kind == "box" then m = Registry.food("box", rest, 12)
    elseif kind == "openbox" then m = Registry.food("box", rest, 8, 20, true)
    elseif kind == "stack" then m = Registry.food("stack", 4, rest)
    elseif kind then m = Registry.food(kind, rest)
    else m = Registry.food("dish", id) end
    local c, r = (i - 1) % cols, math.floor((i - 1) / cols)
    m:PivotTo(CFrame.new(c * 2.4, 0.5, r * 2.4))
    m.Parent = root
  end
  return root
end

-- Blocky R15 rig like the one Players:CreateHumanoidModelFromDescription builds
local function rig(x, z, scale)
  local m = Instance.new("Model")
  local k = scale or 1
  local function part(name, sx, sy, sz, px, py)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = Vector3.new(sx * k, sy * k, sz * k)
    p.CFrame = CFrame.new(x + px * k, py * k, z)
    p.Color = Color3.fromRGB(160, 160, 160)
    p.Parent = m
    return p
  end
  local headK = scale and scale < 1 and 1.12 or 1
  local h = part("Head", 1.2 * headK, 1.2 * headK, 1.2 * headK, 0, 5.3 + (headK - 1) * 0.6)
  part("UpperTorso", 2, 1.6, 1, 0, 3.9)
  part("LowerTorso", 2, 0.4, 1, 0, 2.9)
  for _, s in ipairs({ { "Left", -1 }, { "Right", 1 } }) do
    part(s[1] .. "UpperArm", 1, 1.2, 1, s[2] * 1.5, 4.1)
    part(s[1] .. "LowerArm", 1, 1.1, 1, s[2] * 1.5, 2.95)
    part(s[1] .. "Hand", 1, 0.3, 1, s[2] * 1.5, 2.25)
    part(s[1] .. "UpperLeg", 1, 1.2, 1, s[2] * 0.5, 2.1)
    part(s[1] .. "LowerLeg", 1, 1.2, 1, s[2] * 0.5, 0.9)
    part(s[1] .. "Foot", 1, 0.3, 1, s[2] * 0.5, 0.15)
  end
  local _ = h
  return m
end

-- specs: "casual", "child:casual", "staff:staff_waiter", optional "@mood" suffix
function scene_people(specs)
  local People = Registry.People
  local NpcLooks = require(Shared.Config.NpcLooks)
  local root = Instance.new("Model")
  for i, spec in ipairs(specs) do
    local body, mood = string.match(spec, "^([^@]+)@?(.*)$")
    local kind, rest = string.match(body, "^(%a+):(.+)$")
    local x = (i - 1) * 3.4
    local m = rig(x, 0, kind == "child" and 0.72 or 1)
    local r = Random.new(i * 7 + 3)
    if kind == "staff" then
      People.staff(m, rest, NpcLooks, r)
    elseif kind == "child" then
      People.dress(m, rest, NpcLooks, r, { child = true })
    else
      People.dress(m, body, NpcLooks, r)
    end
    if mood and mood ~= "" then People.setMood(m, mood) end
    m.Parent = root
  end
  return root
end

function scene_category(cat)
  local ids = {}
  for _, it in ipairs(Items.list) do if it.cat == cat then table.insert(ids, it.id) end end
  return scene_items(ids)
end

function scene_restaurant(withItems)
  local Expansions = require(Shared.Config.Expansions)
  local Geometry = require(Shared.Logic.Geometry)
  local Scene = require(Shared.Models.Scene)
  local StarterLayout = require(Shared.Config.StarterLayout)
  local zones = { zone_base = true }
  for z in string.gmatch(__zones or "", "[^,]+") do zones[z] = true end
  -- finished look by default (every renovation); --basic shows the plain starting restaurant
  if not __basic then
    for _, e in ipairs(Expansions.list) do
      if e.reno and e.id ~= "facade_deluxe" and e.id ~= "sign_rooftop" then zones[e.id] = true end
    end
  end
  local styles = Expansions.styles(zones)
  local geo = Geometry.compute(Expansions.list, zones, Expansions.Supplier)
  local root = Instance.new("Model")
  local shell = Instance.new("Folder")
  shell.Parent = root
  local surfaces = {}
  for zid, f, w in string.gmatch(__surfaces or "", "([%w_]+)=([%w_]+)/([%w_]+)") do surfaces[zid] = { floor = f, wall = w } end
  Scene.shell(shell, geo, { zones = zones, surfaces = surfaces, franchise = { city = "tokyo" } })
  if withItems then
    -- --swap=a:b replaces starter items, --place=id@x,z,r,s[,y];... adds more
    local swap = {}
    for a, b in string.gmatch(__swap or "", "([%w_]+):([%w_]+)") do swap[a] = b end
    local list = {}
    for _, s in ipairs(StarterLayout.items) do
      table.insert(list, { i = swap[s.i] or s.i, x = s.x, z = s.z, r = s.r, s = s.s, y = s.y, p = s.p })
    end
    for spec in string.gmatch(__place or "", "[^;]+") do
      local id, rest = string.match(spec, "([%w_]+)@(.+)")
      local v = {}
      for n in string.gmatch(rest, "[^,]+") do table.insert(v, n) end
      table.insert(list, { i = id, x = tonumber(v[1]), z = tonumber(v[2]), r = tonumber(v[3]) or 0, s = v[4] or "f", y = tonumber(v[5]) })
    end
    for _, s in ipairs(list) do
      local item = Items.byId[s.i]
      local m = Registry.build(s.i, { styles = styles })
      local y = 0
      if s.s == "c" then y = 14 - item.size[2]
      elseif s.s == "w" then y = s.y - item.size[2] / 2
      elseif s.s == "t" then y = s.y or Items.byId[StarterLayout.items[s.p].i].size[2] end
      Registry.place(m, s.x, y, s.z, s.r or 0)
      m.Parent = root
    end
  end
  return root
end

function scene_street()
  local Scene = require(Shared.Models.Scene)
  local root = Instance.new("Model")
  local street = Instance.new("Folder")
  street.Parent = root
  Scene.street(street, "tokyo")
  return root
end

-- the street of restaurants (Config/Plots): the first two plots with a basic restaurant, the
-- others as empty lots
function scene_plots()
  local Scene = require(Shared.Models.Scene)
  local PlotsCfg = require(Shared.Config.Plots)
  local Expansions = require(Shared.Config.Expansions)
  local Geometry = require(Shared.Logic.Geometry)
  local root = Instance.new("Model")
  local street = Instance.new("Folder")
  street.Parent = root
  Scene.street(street, "tokyo", PlotsCfg.OriginsX, PlotsCfg.StreetReach)
  local geo = Geometry.compute(Expansions.list, { zone_base = true }, Expansions.Supplier)
  for i, ox in ipairs(PlotsCfg.OriginsX) do
    local shell = Instance.new("Folder")
    shell.Parent = root
    if i <= 2 then
      Scene.shell(shell, geo, { zones = { zone_base = true }, surfaces = {}, franchise = { city = "tokyo" } })
    else
      Scene.emptyLot(shell)
    end
    for _, d in ipairs(shell:GetDescendants()) do
      if d:IsA("BasePart") then
        d.CFrame = d.CFrame + Vector3.new(ox, 0, 0)
      end
    end
  end
  return root
end

function collect(root, skipRoof, bounds)
  local out = {}
  for _, d in ipairs(root:GetDescendants()) do
    if d:IsA("BasePart") and not rawget(d, "__destroyed") then
      local roof = rawget(d, "__attrs")["__tag_Roof"] or rawget(d, "__attrs")["__tag_Ceiling"]
      local cf = d.CFrame
      local keep = not (skipRoof and roof)
      if keep and bounds then
        keep = cf.x >= bounds[1] and cf.x <= bounds[2] and cf.z >= bounds[3] and cf.z <= bounds[4]
      end
      if keep and d.Transparency < 0.98 then
        local mesh = d:FindFirstChildOfClass("SpecialMesh")
        local shape = "Block"
        if d.ClassName == "WedgePart" then shape = "Wedge"
        elseif mesh and mesh.MeshType and mesh.MeshType.Name == "Sphere" then shape = "Ellipsoid"
        elseif d.Shape and d.Shape.Name ~= "Block" then shape = d.Shape.Name end
        local r = cf.r
        table.insert(out, {
          shape = shape, sx = d.Size.X, sy = d.Size.Y, sz = d.Size.Z,
          x = cf.x, y = cf.y, z = cf.z,
          r1 = r[1], r2 = r[2], r3 = r[3], r4 = r[4], r5 = r[5], r6 = r[6], r7 = r[7], r8 = r[8], r9 = r[9],
          cr = d.Color.R, cg = d.Color.G, cb = d.Color.B, t = d.Transparency,
          mat = d.Material and d.Material.Name or "Plastic",
        })
      end
    end
  end
  return out
end
"""

LIGHT = np.array([0.45, 0.85, -0.35])
LIGHT = LIGHT / np.linalg.norm(LIGHT)


def unit_shapes():
    box = np.array([[x, y, z] for x in (-0.5, 0.5) for y in (-0.5, 0.5) for z in (-0.5, 0.5)])
    idx = lambda x, y, z: (x > 0) * 4 + (y > 0) * 2 + (z > 0)  # noqa: E731
    faces = [
        [idx(-1, -1, -1), idx(-1, 1, -1), idx(1, 1, -1), idx(1, -1, -1)],
        [idx(-1, -1, 1), idx(1, -1, 1), idx(1, 1, 1), idx(-1, 1, 1)],
        [idx(-1, -1, -1), idx(-1, -1, 1), idx(-1, 1, 1), idx(-1, 1, -1)],
        [idx(1, -1, -1), idx(1, 1, -1), idx(1, 1, 1), idx(1, -1, 1)],
        [idx(-1, -1, -1), idx(1, -1, -1), idx(1, -1, 1), idx(-1, -1, 1)],
        [idx(-1, 1, -1), idx(-1, 1, 1), idx(1, 1, 1), idx(1, 1, -1)],
    ]
    box_faces = [box[f] for f in faces]
    # wedge: full back face at +z, slope down to the front bottom edge
    w = {
        "bfl": [-0.5, -0.5, -0.5], "bfr": [0.5, -0.5, -0.5], "bbl": [-0.5, -0.5, 0.5], "bbr": [0.5, -0.5, 0.5],
        "tbl": [-0.5, 0.5, 0.5], "tbr": [0.5, 0.5, 0.5],
    }
    wedge_faces = [np.array([w[a] for a in f]) for f in (
        ("bfl", "bfr", "bbr", "bbl"), ("bbl", "bbr", "tbr", "tbl"), ("bfl", "bbl", "tbl"), ("bfr", "tbr", "bbr"),
        ("bfl", "tbl", "tbr", "bfr"))]
    n = 16
    ring = [(0.5 * math.cos(2 * math.pi * i / n), 0.5 * math.sin(2 * math.pi * i / n)) for i in range(n)]
    cyl = []
    for i in range(n):
        a, b = ring[i], ring[(i + 1) % n]
        cyl.append(np.array([[-0.5, a[0], a[1]], [0.5, a[0], a[1]], [0.5, b[0], b[1]], [-0.5, b[0], b[1]]]))
    cyl.append(np.array([[-0.5, p[0], p[1]] for p in ring]))
    cyl.append(np.array([[0.5, p[0], p[1]] for p in ring[::-1]]))
    sph = []
    la, lo = 7, 12
    for i in range(la):
        t1, t2 = math.pi * i / la - math.pi / 2, math.pi * (i + 1) / la - math.pi / 2
        for j in range(lo):
            p1, p2 = 2 * math.pi * j / lo, 2 * math.pi * (j + 1) / lo
            pts = [(t1, p1), (t1, p2), (t2, p2), (t2, p1)]
            sph.append(np.array([[0.5 * math.cos(t) * math.cos(p), 0.5 * math.sin(t), 0.5 * math.cos(t) * math.sin(p)] for t, p in pts]))
    return box_faces, wedge_faces, cyl, sph


BOX, WEDGE, CYL, SPH = unit_shapes()


def part_faces(p):
    R = np.array([[p["r1"], p["r2"], p["r3"]], [p["r4"], p["r5"], p["r6"]], [p["r7"], p["r8"], p["r9"]]])
    pos = np.array([p["x"], p["y"], p["z"]])
    size = np.array([p["sx"], p["sy"], p["sz"]])
    shape = p["shape"]
    if shape == "Cylinder":
        d = min(size[1], size[2])
        size = np.array([size[0], d, d])
        base = CYL
    elif shape == "Ball":
        d = min(size)
        size = np.array([d, d, d])
        base = SPH
    elif shape == "Ellipsoid":
        base = SPH
    elif shape == "Wedge":
        base = WEDGE
    else:
        base = BOX
    out = []
    for f in base:
        local = f * size
        world = local @ R.T + pos
        if len(world) == 4:
            # split big quads so painter's sorting works on large walls and floors
            e1 = np.linalg.norm(world[1] - world[0])
            e2 = np.linalg.norm(world[3] - world[0])
            n1 = int(min(16, max(1, math.ceil(e1 / 3))))
            n2 = int(min(16, max(1, math.ceil(e2 / 3))))
            if n1 > 1 or n2 > 1:
                for i in range(n1):
                    for j in range(n2):
                        def pt(a, b):
                            top = world[0] + (world[1] - world[0]) * a
                            bot = world[3] + (world[2] - world[3]) * a
                            return top + (bot - top) * b
                        out.append(np.array([pt(i / n1, j / n2), pt((i + 1) / n1, j / n2), pt((i + 1) / n1, (j + 1) / n2), pt(i / n1, (j + 1) / n2)]))
                continue
        out.append(world)
    return out


def to_plot(v):
    # Roblox (X, Y, Z) -> plot (X, -Z, Y)
    return np.stack([v[:, 0], -v[:, 2], v[:, 1]], axis=1)


def render(parts, out, elev=18, azim=60, title=None, size=(12, 8), dpi=110, night=False, zoom=1.35, background="#BFD3E6", focus=None):
    polys, colors = [], []
    for p in parts:
        base = np.array([p["cr"], p["cg"], p["cb"]])
        alpha = max(0.08, 1 - p["t"])
        neon = p["mat"] == "Neon"
        for f in part_faces(p):
            if len(f) < 3:
                continue
            n = np.cross(f[1] - f[0], f[2] - f[0])
            norm = np.linalg.norm(n)
            if norm < 1e-9 and len(f) > 3:
                n = np.cross(f[2] - f[0], f[3] - f[0])
                norm = np.linalg.norm(n)
            n = n / norm if norm > 1e-9 else np.array([0, 1, 0])
            shade = 0.45 + 0.55 * max(0.0, float(np.dot(n, LIGHT)))
            col = np.clip(base * (1.25 if neon else shade), 0, 1)
            if night and not neon:
                col = col * 0.45
            polys.append(to_plot(f))
            colors.append((*col, alpha))
    if not polys:
        print("nothing to render")
        return
    fig = plt.figure(figsize=size, dpi=dpi)
    ax = fig.add_subplot(111, projection="3d")
    coll = Poly3DCollection(polys, facecolors=colors, edgecolors=(0, 0, 0, 0.15), linewidths=0.2)
    ax.add_collection3d(coll)
    allp = np.concatenate(polys)
    mins, maxs = allp.min(axis=0), allp.max(axis=0)
    if focus:
        # focus = (xmin, xmax, zmin, zmax) in Roblox coordinates: frame that area, not huge ground parts
        x0, x1, z0, z1 = focus
        mins = np.array([max(mins[0], x0), max(mins[1], -z1), mins[2]])
        maxs = np.array([min(maxs[0], x1), min(maxs[1], -z0), maxs[2]])
    span = (maxs - mins).max() / 2
    center = (mins + maxs) / 2
    ax.set_xlim(center[0] - span, center[0] + span)
    ax.set_ylim(center[1] - span, center[1] + span)
    ax.set_zlim(center[2] - span, center[2] + span)
    ax.set_box_aspect((1, 1, 1), zoom=zoom)
    ax.set_proj_type("persp", focal_length=0.6)
    ax.view_init(elev=elev, azim=azim)
    ax.set_axis_off()
    bg = "#1E2230" if night else background
    fig.patch.set_facecolor(bg)
    ax.set_facecolor(bg)
    if title:
        ax.set_title(title)
    plt.tight_layout()
    fig.savefig(out, facecolor=fig.get_facecolor())
    plt.close(fig)
    print(f"wrote {out} ({len(polys)} faces, {len(parts)} parts)")


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        return 1
    kind = sys.argv[1]
    lua = lua54.LuaRuntime(unpack_returned_tuples=True)
    g = lua.globals()
    g.__read = read_module
    g.__list = lambda p: lua.table_from(list_dir(p))
    lua.execute(open(os.path.join(ROOT, "tools", "preview", "mock.lua"), encoding="utf-8").read())
    lua.execute(PRELUDE)
    lua.execute(SCENES)
    opts = {"elev": 18, "azim": 60}
    bounds = None
    skip_roof = False
    night = "--night" in sys.argv
    args = [a for a in sys.argv[2:] if not a.startswith("--")]
    for a in sys.argv[2:]:
        if a.startswith("--zones="):
            g.__zones = a.split("=", 1)[1]
        if a == "--basic":
            g.__basic = True
        for key in ("place", "swap", "surfaces"):
            if a.startswith("--" + key + "="):
                g["__" + key] = a.split("=", 1)[1]
        if a.startswith("--view="):
            vals = [float(v) for v in a.split("=", 1)[1].split(",")]
            opts = {"elev": vals[0], "azim": vals[1]}
            if len(vals) > 2:
                opts["zoom"] = vals[2]
    if kind == "item":
        root = lua.eval("scene_items")(lua.table_from(args[:-1]))
        out = args[-1]
    elif kind == "dish":
        root = lua.eval("scene_dish")(lua.table_from(args[:-1]))
        out = args[-1]
    elif kind == "category":
        root = lua.eval("scene_category")(args[0])
        out = args[1]
        opts = {"elev": 14, "azim": 75, "zoom": 1.6}
    elif kind == "people":
        root = lua.eval("scene_people")(lua.table_from(args[:-1]))
        out = args[-1]
        opts = {"elev": 6, "azim": 90, "zoom": 1.5} if "--view=" not in " ".join(sys.argv) else opts
    elif kind == "facade":
        root = lua.eval("scene_restaurant")(True)
        out = args[0]
        opts = {"elev": 8, "azim": 90, "zoom": 1.5} if "--view=" not in " ".join(sys.argv) else opts
        bounds = lua.table_from([-40, 40, -20, 30])
    elif kind == "interior":
        root = lua.eval("scene_restaurant")(True)
        out = args[0]
        skip_roof = True
        opts = {"elev": 55, "azim": 100, "zoom": 1.4} if "--view=" not in " ".join(sys.argv) else opts
    elif kind == "plots":
        root = lua.eval("scene_plots")()
        out = args[0]
        bounds = lua.table_from([-560, 560, -90, 110])
        opts = {"elev": 60, "azim": 90, "zoom": 1.1} if "--view=" not in " ".join(sys.argv) else opts
    elif kind == "street":
        root = lua.eval("scene_street")()
        out = args[0]
        bounds = lua.table_from([-160, 160, -130, 10])
        opts = {"elev": 12, "azim": 90, "zoom": 1.5} if "--view=" not in " ".join(sys.argv) else opts
    else:
        print(__doc__)
        return 1
    raw = lua.eval("collect")(root, skip_roof, bounds)
    for a in sys.argv[2:]:
        if a.startswith("--clip="):
            # keep only parts whose centre lies in xmin,xmax,zmin,zmax (e.g. drop the near wall)
            bounds = lua.table_from([float(v) for v in a.split("=", 1)[1].split(",")])
            raw = lua.eval("collect")(root, skip_roof, bounds)
    focus = None
    for a in sys.argv[2:]:
        if a.startswith("--focus="):
            focus = [float(v) for v in a.split("=", 1)[1].split(",")]
    if focus is None and bounds is not None:
        focus = [bounds[1], bounds[2], bounds[3], bounds[4]]
    parts = [dict(raw[i + 1]) for i in range(len(raw))]
    render(parts, out, night=night, focus=focus, **opts)
    return 0


if __name__ == "__main__":
    sys.exit(main())
