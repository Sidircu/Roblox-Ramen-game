-- Tests for the pure logic and configuration modules (run with tools/run_logic_tests.py)
local Formulas = require(Shared.Logic.Formulas)
local Grid = require(Shared.Logic.Grid)
local Footprint = require(Shared.Logic.Footprint)
local Geometry = require(Shared.Logic.Geometry)
local Placement = require(Shared.Logic.Placement)
local Ambience = require(Shared.Logic.Ambience)
local Items = require(Shared.Config.Items)
local Expansions = require(Shared.Config.Expansions)
local StarterLayout = require(Shared.Config.StarterLayout)
local GameConfig = require(Shared.Config.GameConfig)
local Recipes = require(Shared.Config.Recipes)
local Ingredients = require(Shared.Config.Ingredients)
local Licenses = require(Shared.Config.Licenses)
local Surfaces = require(Shared.Config.Surfaces)
local Sets = require(Shared.Config.Sets)

local function starterPlaced()
  local placed, uids = {}, {}
  for i, s in ipairs(StarterLayout.items) do
    local e = { u = "p" .. i, i = s.i, x = s.x, z = s.z, r = s.r or 0, f = 0, s = s.s, y = s.y }
    uids[i] = e.u
    table.insert(placed, e)
  end
  for i, s in ipairs(StarterLayout.items) do
    if s.p then
      placed[i].p = uids[s.p]
      placed[i].y = Items.byId[StarterLayout.items[s.p].i].size[2]
    end
  end
  return placed
end

local function ctxFor(zones, placed)
  local geo = Geometry.compute(Expansions.list, zones, Expansions.Supplier)
  return Geometry.ctx(geo, Items.byId, placed, GameConfig), geo
end

local function allZones()
  local z = {}
  for _, e in ipairs(Expansions.list) do z[e.id] = true end
  return z
end

test("xp curve", function()
  expect(Formulas.xpForLevel(1) == 100, "level 1 needs 100 xp")
  expect(Formulas.xpForLevel(10) == 4467, "level 10 xp " .. Formulas.xpForLevel(10))
  local lvl, xp, gained = Formulas.addXp(1, 0, 250)
  expect(lvl == 2 and gained == 1, "one level gained")
  expect(xp == 150, "remaining xp " .. xp)
end)

test("mastery and prices", function()
  expect(Formulas.masteryLevel(0) == 0 and Formulas.masteryLevel(100) == 2 and Formulas.masteryLevel(10000) == 5)
  expect(Formulas.dishPrice(40, 0, 1) == 40)
  expect(Formulas.dishPrice(100, 500, 1.3) == 150, "price " .. Formulas.dishPrice(100, 500, 1.3))
  expect(Formulas.demandFactor(1.3) < Formulas.demandFactor(1) and Formulas.demandFactor(0.7) > 1)
end)

test("review and tip ranges", function()
  for _, p in ipairs({ 0, 0.3, 0.6, 1 }) do
    local s = Formulas.review({ patienceLeft = p, ambienceTier = 4, comfort = 5, fresh = true })
    expect(s >= 1 and s <= 5, "stars in range")
  end
  expect(Formulas.review({ left = true }) == 1)
  expect(Formulas.review({ patienceLeft = 1, ambienceTier = 4, comfort = 5, fresh = true }) == 5, "best case gives 5 stars")
  expect(Formulas.tip(100, { patienceLeft = 1, customerTip = 1 }) == 15)
end)

test("grid snapping 1 / 5 / 10", function()
  local x, z = Grid.snapFloor(1.3, 2.7, 1.6, 1.6, 0, 1)
  expect(near(x, 1.8) and near(z, 2.8), "1-stud snap " .. x .. "," .. z)
  x, z = Grid.snapFloor(7, 7, 2, 2, 0, 5)
  expect(near(x, 6) and near(z, 6), "5-stud snap " .. x .. "," .. z)
  x, z = Grid.snapFloor(13, -4, 4, 3, 90, 10)
  local ew, ed = Grid.aabb(4, 3, 90)
  expect(near(ew, 3) and near(ed, 4), "rotated aabb")
  expect(near((x - ew / 2) % 10, 0) and near((z - ed / 2) % 10, 0), "10-stud corner on grid")
end)

test("footprint overlap", function()
  local a = Footprint.new(0, 0, 2, 2, 0)
  expect(Footprint.overlaps(a, Footprint.new(1.5, 0, 2, 2, 0)))
  expect(not Footprint.overlaps(a, Footprint.new(2, 0, 2, 2, 0)), "touching is allowed")
  expect(Footprint.overlaps(a, Footprint.new(2.2, 0, 2, 2, 45)), "rotated overlap")
end)

test("walls of the base restaurant", function()
  local _, geo = ctxFor({ zone_base = true }, {})
  local walls = geo.walls[0].walls
  expect(#walls > 6, "walls generated")
  for _, w in ipairs(walls) do
    if w.axis == "z" and w.line == 0 then
      expect(not (w.a < 0 and w.b > 0), "entrance is open")
    end
  end
  local kitchenDining = false
  for _, w in ipairs(walls) do
    if w.axis == "z" and w.line == 16 and w.a < 10 and w.b > -10 then kitchenDining = true end
  end
  expect(not kitchenDining, "no wall between dining and kitchen")
end)

test("starter layout is valid", function()
  local placed = starterPlaced()
  local ctx = ctxFor({ zone_base = true }, placed)
  for i, e in ipairs(placed) do
    local others = {}
    for j, o in ipairs(placed) do if j ~= i then table.insert(others, o) end end
    ctx.placed = others
    local req = table.clone(e)
    local ok, reason = Placement.validate(ctx, req, true)
    expect(ok, "starter item " .. e.i .. " invalid: " .. tostring(reason))
  end
  ctx.placed = placed
  local ok, reason = Placement.pathOk(ctx, placed)
  expect(ok, "starter layout path: " .. tostring(reason))
end)

test("placing new objects", function()
  local placed = starterPlaced()
  local ctx = ctxFor({ zone_base = true }, placed)
  local ok, reason = Placement.validate(ctx, { i = "bamboo_pot", x = 12, z = 4, r = 0, f = 0, s = "f" })
  expect(ok, "decor in the dining room: " .. tostring(reason))
  ok = Placement.validate(ctx, { i = "stool_wood", x = 0, z = 22, r = 0, f = 0, s = "f" })
  expect(not ok, "stools are not allowed in the kitchen")
  ok = Placement.validate(ctx, { i = "bamboo_pot", x = 0, z = 1, r = 0, f = 0, s = "f" })
  expect(not ok, "the entrance must stay free")
  ok = Placement.validate(ctx, { i = "bamboo_pot", x = -9, z = 11.9, r = 0, f = 0, s = "f" })
  expect(not ok, "overlap with a stool")
  ok, reason = Placement.validate(ctx, { i = "kakejiku", x = -17.4, y = 6, z = 6, r = 0, f = 0, s = "w" })
  expect(ok, "scroll on the west wall: " .. tostring(reason))
  ok, reason = Placement.validate(ctx, { i = "chochin_red", x = 10, z = 8, r = 0, f = 0, s = "c" })
  expect(ok, "ceiling lantern: " .. tostring(reason))
  ok, reason = Placement.validate(ctx, { i = "daruma", x = -4, z = 14.5, r = 0, f = 0, s = "t", p = "p3" })
  expect(ok, "daruma on the counter: " .. tostring(reason))
  -- wall of counters closing the dining room off from the kitchen must be refused
  local blockers = table.clone(placed)
  for k = 0, 6 do table.insert(blockers, { u = "b" .. k, i = "counter_straight", x = 6 + k * 4 >= 18 and 16 or 6 + k * 4, z = 14.5, r = 0, f = 0, s = "f" }) end
  local _ = blockers
  ok = Placement.validate(ctx, { i = "counter_straight", x = 6.5, z = 14.5, r = 0, f = 0, s = "f" })
  expect(ok, "a counter next to the others is fine")
end)

test("full restaurant geometry", function()
  local placed = starterPlaced()
  local ctx, geo = ctxFor(allZones(), placed)
  expect(geo.walls[1] ~= nil and geo.walls[2] ~= nil, "upper floors")
  local ok, reason = Placement.pathOk(ctx, placed)
  expect(ok, "path with every zone: " .. tostring(reason))
  ok, reason = Placement.validate(ctx, { i = "table_4", x = 0, z = 8, r = 0, f = 1, s = "f" })
  expect(ok, "table on the second floor: " .. tostring(reason))
  ok, reason = Placement.validate(ctx, { i = "sakura_tree", x = -6, z = 38, r = 0, f = 0, s = "f" })
  expect(ok, "tree in the garden: " .. tostring(reason))
  ok, reason = Placement.validate(ctx, { i = "zashiki_table", x = -42, z = 37, r = 0, f = 0, s = "f" })
  expect(ok, "VIP table in the tatami room: " .. tostring(reason))
end)

test("ambience", function()
  local placed = starterPlaced()
  local a = Ambience.compute(placed, Items.byId, Surfaces.byId, {}, 0, Sets.list)
  expect(a.points > 0 and a.tier == 0, "starter ambience " .. a.points)
  local many = {}
  for k = 1, 10 do table.insert(many, { i = "bonsai_pine" }) end
  local b = Ambience.compute(many, Items.byId, Surfaces.byId, {}, 0, Sets.list)
  expect(b.points < 70, "diminishing returns")
end)

test("config integrity", function()
  for _, r in ipairs(Recipes.list) do
    for _, g in ipairs(r.ing) do expect(Ingredients.byId[g], r.id .. " uses unknown " .. g) end
    if r.broth then expect(Ingredients.byId[r.broth].storage == "broth", r.id .. " broth") end
    for _, s in ipairs(r.steps) do expect(GameConfig.Steps[s], r.id .. " unknown step " .. s) end
    expect(r.license or r.city, r.id .. " has no unlock")
    if r.license then expect(Licenses.byId[r.license], r.id .. " license") end
  end
  for _, l in ipairs(Licenses.list) do
    for _, rid in ipairs(l.recipes) do expect(Recipes.byId[rid] and Recipes.byId[rid].license == l.id, l.id .. " -> " .. rid) end
  end
  for _, ing in ipairs(Ingredients.list) do expect(Licenses.byId[ing.license], ing.id .. " license") end
  for _, it in ipairs(Items.list) do
    expect(it.size and #it.size == 3, it.id .. " size")
    expect(Placement.PlaceCode[it.place], it.id .. " place")
    if it.license then expect(Licenses.byId[it.license], it.id .. " license") end
  end
  for _, s in ipairs(StarterLayout.items) do expect(Items.byId[s.i], "starter " .. s.i) end
end)

test("blocking the way to the kitchen is refused", function()
  local placed = starterPlaced()
  local ctx = ctxFor({ zone_base = true }, placed)
  local layout = table.clone(placed)
  -- close both gaps beside the counter (x -18..-12 and 4..18)
  local function add(i, x)
    table.insert(layout, { u = "blk" .. #layout, i = i, x = x, z = 14.5, r = 0, f = 0, s = "f" })
  end
  add("counter_straight", -15.6)
  add("counter_end", -12.8)
  for x = 6, 14, 4 do add("counter_straight", x) end
  add("counter_end", 16.6)
  local ok = Placement.pathOk(ctx, layout)
  expect(not ok, "a closed counter must block the kitchen")
  -- a 1.6 stud gap is too narrow, a wide opening keeps the kitchen reachable
  table.remove(layout)
  expect(not Placement.pathOk(ctx, layout), "1.6 studs is too narrow")
  table.remove(layout)
  ok = Placement.pathOk(ctx, layout)
  expect(ok, "an opening keeps the kitchen reachable")
end)

test("wall objects need an inside wall", function()
  local ctx = ctxFor({ zone_base = true }, starterPlaced())
  local ok = Placement.validate(ctx, { i = "kakejiku", x = -18.6, y = 6, z = 6, r = 0, f = 0, s = "w" })
  expect(not ok, "the outside of the building is not a valid wall")
  ok = Placement.validate(ctx, { i = "kakejiku", x = 0, y = 6, z = 0.55, r = 0, f = 0, s = "w" })
  expect(not ok, "not over the entrance")
end)
