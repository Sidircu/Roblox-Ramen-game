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
local ShelfGrid = require(Shared.Logic.ShelfGrid)
local Locks = require(Shared.Logic.Locks)
local Shop = require(Shared.Logic.Shop)
local TutorialCfg = require(Shared.Config.Tutorial)
local FranchiseCfg = require(Shared.Config.Franchise)
local Upgrades = require(Shared.Config.Upgrades)
local Ads = require(Shared.Config.Ads)
local StaffCfg = require(Shared.Config.Staff)

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
  local geo = Geometry.compute(Expansions.list, zones, Expansions)
  return Geometry.ctx(geo, Items.byId, placed, GameConfig), geo
end

local function allZones()
  local z = {}
  for _, e in ipairs(Expansions.list) do z[e.id] = true end
  return z
end

test("xp curve", function()
  expect(Formulas.xpForLevel(1) == 50, "level 1 needs 50 xp")
  expect(Formulas.xpForLevel(10) == 1991, "level 10 xp " .. Formulas.xpForLevel(10))
  local lvl, xp, gained = Formulas.addXp(1, 0, 250)
  expect(lvl == 3 and gained == 2, "two levels gained")
  expect(xp == 48, "remaining xp " .. xp)
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
    if w.axis == "z" and w.line == 32 and w.a < 10 and w.b > -10 then kitchenDining = true end
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
  ok = Placement.validate(ctx, { i = "stool_wood", x = 0, z = 40, r = 0, f = 0, s = "f" })
  expect(not ok, "stools are not allowed in the kitchen")
  ok = Placement.validate(ctx, { i = "bamboo_pot", x = 0, z = 1, r = 0, f = 0, s = "f" })
  expect(not ok, "the entrance must stay free")
  ok = Placement.validate(ctx, { i = "bamboo_pot", x = -9, z = 27.8, r = 0, f = 0, s = "f" })
  expect(not ok, "overlap with a stool")
  ok, reason = Placement.validate(ctx, { i = "kakejiku", x = -35.4, y = 6, z = 6, r = 0, f = 0, s = "w" })
  expect(ok, "scroll on the west wall: " .. tostring(reason))
  ok, reason = Placement.validate(ctx, { i = "chochin_red", x = 10, z = 8, r = 0, f = 0, s = "c" })
  expect(ok, "ceiling lantern: " .. tostring(reason))
  ok, reason = Placement.validate(ctx, { i = "daruma", x = -17.5, z = 30.05, r = 0, f = 0, s = "t", p = "p3" })
  expect(ok, "daruma on the counter: " .. tostring(reason))
  -- wall of counters closing the dining room off from the kitchen must be refused
  local blockers = table.clone(placed)
  local _ = blockers
  ok = Placement.validate(ctx, { i = "counter_straight", x = 17.5, z = 30.05, r = 0, f = 0, s = "f" })
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
  ok, reason = Placement.validate(ctx, { i = "sakura_tree", x = -12, z = 74, r = 0, f = 0, s = "f" })
  expect(ok, "tree in the garden: " .. tostring(reason))
  ok, reason = Placement.validate(ctx, { i = "zashiki_table", x = -84, z = 72, r = 0, f = 0, s = "f" })
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
  -- close both gaps beside the counter (x -36..-24 and 16..36) with 3-stud modules
  local function add(i, x)
    table.insert(layout, { u = "blk" .. #layout, i = i, x = x, z = 30.05, r = 0, f = 0, s = "f" })
  end
  for x = -34.5, -25.5, 3 do add("counter_straight", x) end
  for x = 17.5, 29.5, 3 do add("counter_straight", x) end
  add("counter_straight", 32.5)
  add("counter_end", 35)
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
  local ok = Placement.validate(ctx, { i = "kakejiku", x = -36.6, y = 6, z = 6, r = 0, f = 0, s = "w" })
  expect(not ok, "the outside of the building is not a valid wall")
  ok = Placement.validate(ctx, { i = "kakejiku", x = 0, y = 6, z = 0.55, r = 0, f = 0, s = "w" })
  expect(not ok, "not over the entrance")
end)

test("renovations are cosmetic and map to detail styles", function()
  local count = 0
  for _, e in ipairs(Expansions.list) do
    if e.reno then
      count = count + 1
      expect(e.cosmetic, e.id .. " must be cosmetic")
      expect(not e.zones and not e.openings and not e.stairs, e.id .. " must not change the building")
      expect(e.reno == "exterior" or e.reno == "interior" or e.reno == "furniture", e.id .. " group")
      for _, r in ipairs(e.requires) do expect(Expansions.byId[r], e.id .. " requires " .. r) end
    end
  end
  expect(count >= 13, "renovation list")
  local none = Expansions.styles({ zone_base = true })
  expect(next(none) == nil, "the starting restaurant has no detail styles")
  local some = Expansions.styles({ zone_base = true, reno_counter = true, reno_tableware = true })
  expect(some.counter and some.tableware and not some.kitchen, "owned styles only")
  local all = Expansions.allStyles()
  for _, k in ipairs({ "counter", "kitchen", "tableware", "furnish" }) do expect(all[k], "style " .. k) end
  -- geometry is identical with or without renovations
  local plain = Geometry.compute(Expansions.list, { zone_base = true }, Expansions)
  local reno = Geometry.compute(Expansions.list, { zone_base = true, reno_facade = true, reno_beams = true }, Expansions)
  expect(#plain.zones == #reno.zones and #plain.openings == #reno.openings, "renovations do not add rooms")
end)

test("shelf slots are product grids, a box fills two slots", function()
  local function dims(n)
    local c, r = ShelfGrid.dims(n)
    return c .. "x" .. r
  end
  expect(dims(10) == "5x2" and dims(15) == "5x3" and dims(6) == "3x2" and dims(4) == "2x2", "grid shapes")
  expect(dims(20) == "5x4" and dims(12) == "4x3" and dims(8) == "4x2" and dims(5) == "5x1", "more grid shapes")
  local c, r = ShelfGrid.dims(7)
  expect(c * r >= 7 and c <= 5, "uneven counts still fit")
  -- every shelf ingredient: a full grid holds exactly half a box (no rounding surprises)
  for _, ing in ipairs(Ingredients.list) do
    if ing.storage == "shelf" or ing.storage == "fish" then
      local cols, rows = ShelfGrid.forIngredient(ing.units, GameConfig.BoxShelfSlots, 1)
      expect(cols * rows * GameConfig.BoxShelfSlots == ing.units, ing.id .. " box does not split into two full grids")
    end
  end
  -- the shelf upgrade adds rows
  local c1, r1 = ShelfGrid.forIngredient(20, 2, 1)
  local c2, r2 = ShelfGrid.forIngredient(20, 2, 1.75)
  expect(c1 == c2 and r2 > r1, "upgrade adds rows")
  -- the front row fills first, starting on the left of a player facing the shelf (+x)
  local x1, z1 = ShelfGrid.cell(1, 5, 2, 5, 2)
  local x2, z2 = ShelfGrid.cell(2, 5, 2, 5, 2)
  local x6, z6 = ShelfGrid.cell(6, 5, 2, 5, 2)
  expect(x1 > x2 and z1 == z2 and z6 > z1, "fill order")
end)

test("the first day is ramen only, locks name the license to buy", function()
  local owned = { lic_base = true }
  expect(Locks.station("ramen", owned, Recipes, Licenses) == nil, "ramen is open from the start")
  local sushi = Locks.station("sushi", owned, Recipes, Licenses)
  expect(sushi and sushi.level <= 3, "the sushi station names an early license")
  local rice = Locks.rice(owned, Recipes, Licenses)
  expect(rice ~= nil, "the rice cooker is locked at the start")
  owned[sushi.id] = true
  expect(Locks.station("sushi", owned, Recipes, Licenses) == nil, "buying it unlocks the station")
  -- only the ramen ingredients can be bought at the start
  for _, ing in ipairs(Ingredients.list) do
    if ing.license == "lic_base" then
      expect(ing.id == "noodles" or ing.id == "scallion" or ing.id == "naruto" or ing.id == "broth_shoyu", ing.id .. " on sale at the start")
    end
  end
end)

test("the shop says what can be bought, what is missing and what comes first", function()
  local w = { level = 1, yen = 1200, upgrades = {}, licenses = { lic_base = true }, zones = { zone_base = true }, staff = {}, ads = {}, stats = { days = 0 } }
  local shoes = Upgrades.byId.up_shoes
  local st = Shop.upgrade(w, shoes)
  expect(st.state == "buy" and st.price == shoes.costs[1], "shoes can be bought at level 1")
  w.yen = 400
  st = Shop.upgrade(w, shoes)
  expect(st.state == "poor" and st.missing == shoes.costs[1] - 400, "too expensive says how much is missing")
  st = Shop.upgrade(w, Upgrades.byId.up_knife)
  expect(st.state == "locked" and st.need.kind == "level" and st.need.level == Upgrades.byId.up_knife.levels[1], "the knife waits for a level")
  w.upgrades.up_cart = Upgrades.byId.up_cart.max
  expect(Shop.upgrade(w, Upgrades.byId.up_cart).state == "max", "an upgrade at its last level is max")
  -- an upgrade that needs a member of staff
  w.level = 50
  w.yen = 1e9
  st = Shop.upgrade(w, Upgrades.byId.up_autorestock)
  expect(st.state == "locked" and st.need.kind == "staff", "auto-restock needs a stocker")
  -- licenses: level, the license before, the rating
  for _, lic in ipairs(Licenses.list) do
    if #lic.requires > 0 and lic.requires[1] ~= "lic_base" then
      local s2 = Shop.license(w, lic, 5)
      expect(s2.state == "locked" and s2.need.kind == "license", lic.id .. " waits for " .. lic.requires[1])
      break
    end
  end
  for _, lic in ipairs(Licenses.list) do
    if (lic.rating or 0) > 0 then
      local deps = true
      for _, r in ipairs(lic.requires) do
        w.licenses[r] = true
      end
      local s3 = Shop.license(w, lic, lic.rating - 0.5)
      expect(deps and s3.state == "locked" and s3.need.kind == "rating", lic.id .. " waits for the rating")
      expect(Shop.license(w, lic, lic.rating).state == "buy", lic.id .. " with the rating")
      break
    end
  end
  expect(Shop.license(w, Licenses.byId.lic_base, 5).state == "owned", "the first license is owned")
  -- rooms need the rooms before them
  for _, e in ipairs(Expansions.list) do
    if #e.requires > 0 and e.requires[1] ~= "zone_base" then
      local s4 = Shop.expansion(w, e)
      expect(s4.state == "locked" and s4.need.kind == "zone", e.id .. " waits for " .. e.requires[1])
      break
    end
  end
  -- staff: free places and a single manager
  local slots = Shop.staffSlots(w, StaffCfg, GameConfig.MaxStaff)
  expect(slots == StaffCfg.BaseSlots, "base staff slots " .. slots)
  local first = StaffCfg.list[1]
  expect(Shop.hire(w, first, slots).state == "buy", "a free place to hire")
  for i = 1, slots do
    table.insert(w.staff, { role = first.id, lvl = 1 })
  end
  st = Shop.hire(w, first, slots)
  expect(st.state == "locked" and st.need.kind == "slots", "a full team cannot hire")
  -- adverts run for one day
  w.ads.ad_flyers = 1
  expect(Shop.ad(w, Ads.byId.ad_flyers).state == "active", "today's advert is active")
  -- the count per tab, and the order of the cards
  local total, tabs = Shop.buyable(w, { Upgrades = Upgrades, Ads = Ads, Licenses = Licenses, Expansions = Expansions, Staff = StaffCfg, MaxStaff = GameConfig.MaxStaff }, 5)
  expect(total > 0 and total == tabs.upgrades + tabs.recipes + tabs.staff + tabs.rooms + tabs.reno, "buyable count adds up")
  local list = {
    { st = { state = "owned" }, order = 1 }, { st = { state = "locked", price = 5 }, order = 2 },
    { st = { state = "poor", price = 900 }, order = 3 }, { st = { state = "buy", price = 800 }, order = 4 }, { st = { state = "buy", price = 100 }, order = 5 },
  }
  Shop.sort(list)
  expect(list[1].order == 5 and list[2].order == 4 and list[3].order == 3 and list[4].order == 2 and list[5].order == 1, "buy first (cheapest first), then poor, locked, owned")
end)

test("the tutorial gift buys the first upgrade at once", function()
  -- the "buy" step of the tutorial needs a green price right after the first dish
  local w = { level = 1, yen = GameConfig.StartYen + TutorialCfg.ServeYen, upgrades = {}, licenses = { lic_base = true }, zones = { zone_base = true }, staff = {}, ads = {}, stats = { days = 0 } }
  local any = false
  for _, u in ipairs(Upgrades.list) do
    if Shop.upgrade(w, u).state == "buy" then
      any = true
    end
  end
  expect(any, "an upgrade is affordable with the start money and the gift")
  expect(TutorialCfg.DoneSakura > 0, "a last gift")
  for _, id in ipairs({ "restock", "dishes", "shop", "staff" }) do
    expect(TutorialCfg.Hints[id] ~= nil, "tip " .. id .. " configured")
  end
end)

test("each franchise asks for more than the one before", function()
  local prev = nil
  for i, st in ipairs(FranchiseCfg.Steps) do
    expect(FranchiseCfg.nextStep(i - 1) == st, "step " .. i)
    for _, z in ipairs(st.zones) do
      expect(Expansions.byId[z] ~= nil, "zone " .. z .. " exists")
      expect(Expansions.byId[z].lv <= st.level, z .. " is open by level " .. st.level)
    end
    if prev then
      expect(st.level > prev.level and st.rating >= prev.rating and #st.zones >= #prev.zones, "step " .. i .. " asks for more")
    end
    prev = st
  end
  expect(FranchiseCfg.nextStep(#FranchiseCfg.Steps) == nil, "no step after the last city")
  expect(#FranchiseCfg.Steps == #FranchiseCfg.list - 1, "one step for every city after Tokyo")
  -- the first helper comes early: a member of staff by level 5
  local first = math.huge
  for _, s in ipairs(StaffCfg.list) do
    first = math.min(first, s.lv)
  end
  expect(first <= 5, "first staff at level " .. first)
end)

test("retention and fair passes", function()
  local Monetization = require(Shared.Config.Monetization)
  local DailyRewards = require(Shared.Config.DailyRewards)
  -- the extra staff pass adds its slots on top of the rooms' slots, also at the cap
  local w = { level = 1, zones = { zone_base = true }, staff = {}, passes = {} }
  local base = Shop.staffSlots(w, StaffCfg, GameConfig.MaxStaff)
  w.passes.gp_extra_staff = true
  expect(Shop.staffSlots(w, StaffCfg, GameConfig.MaxStaff) == base + StaffCfg.PassSlots, "the pass adds " .. StaffCfg.PassSlots .. " slots")
  local all = { staff = {}, passes = {}, zones = {} }
  for _, e in ipairs(Expansions.list) do
    all.zones[e.id] = true
  end
  local full = Shop.staffSlots(all, StaffCfg, GameConfig.MaxStaff)
  expect(full == GameConfig.MaxStaff, "every room: the full team (" .. full .. ")")
  all.passes.gp_extra_staff = true
  expect(Shop.staffSlots(all, StaffCfg, GameConfig.MaxStaff) == GameConfig.MaxStaff + StaffCfg.PassSlots, "the pass still helps with every room")
  local gp = nil
  for _, p in ipairs(Monetization.GamePasses) do
    if p.id == "gp_extra_staff" then
      gp = p
    end
  end
  expect(gp ~= nil and gp.effect.staffSlots == StaffCfg.PassSlots, "the pass says what it gives")
  -- everybody earns while away (the safe makes it longer), and the team bonus has a cap
  local safe = Upgrades.byId.up_safe
  expect(safe.values[1] >= 1 and safe.pct[1] > 0, "offline earnings without the safe")
  for i = 2, #safe.values do
    expect(safe.values[i] > safe.values[i - 1] and safe.pct[i] > safe.pct[i - 1], "every safe level gives more")
  end
  expect(#safe.values == safe.max + 1 and #safe.pct == safe.max + 1, "a value for every safe level")
  expect(GameConfig.Coop.BonusPerHelper > 0 and GameConfig.Coop.MaxBonus >= GameConfig.Coop.BonusPerHelper, "a team bonus with a cap")
  -- the daily calendar: seven days, the last one the best
  expect(#DailyRewards.days == 7 and DailyRewards.days[7].item ~= nil, "a week of gifts with a present on day 7")
  expect(DailyRewards.PopupAfterTutorial > 0 and DailyRewards.PopupWait > 0, "the calendar opens by itself")
end)

test("wall decorations hang where the pointer is", function()
  local ctx = ctxFor({ zone_base = true }, starterPlaced())
  local walls = ctx.walls[0]
  local item = Items.byId.kakejiku
  local inside = { x = -20, z = 10 }
  -- the pointer on the inside face of the west wall
  local x, z, y = Placement.wallSpot(ctx, walls, { x = -35.6, y = 7, z = 6 }, { x = 1, y = 0, z = 0 }, inside, item.size, 1, 0)
  expect(x ~= nil, "a spot on the face")
  local ok, reason = Placement.validate(ctx, { i = "kakejiku", x = x, z = z, y = y, r = 0, f = 0, s = "w" })
  expect(ok, "hung on the face: " .. tostring(reason) .. " at " .. tostring(x) .. "," .. tostring(z) .. "," .. tostring(y))
  -- the pointer on the top of the wall (the build view looks down): the side you stand on
  x, z, y = Placement.wallSpot(ctx, walls, { x = -36.1, y = 14, z = 6.3 }, { x = 0, y = 1, z = 0 }, inside, item.size, 1, 0)
  ok, reason = Placement.validate(ctx, { i = "kakejiku", x = x, z = z, y = y, r = 0, f = 0, s = "w" })
  expect(ok, "hung from the top view: " .. tostring(reason))
  expect(math.abs(y - GameConfig.WallItemY) <= 1, "at the usual height: " .. tostring(y))
  -- standing outside, the outside of the building is not a wall for decorations
  x, z, y = Placement.wallSpot(ctx, walls, { x = -36.1, y = 14, z = 6.3 }, { x = 0, y = 1, z = 0 }, { x = -50, z = 6 }, item.size, 1, 0)
  ok = Placement.validate(ctx, { i = "kakejiku", x = x, z = z, y = y, r = 0, f = 0, s = "w" })
  expect(not ok, "not on the outside")
  -- the 5-stud grid keeps it on the wall too
  x, z, y = Placement.wallSpot(ctx, walls, { x = -35.6, y = 9, z = 13 }, { x = 1, y = 0, z = 0 }, inside, Items.byId.noren_red.size, 5, 0)
  ok, reason = Placement.validate(ctx, { i = "noren_red", x = x, z = z, y = y, r = 0, f = 0, s = "w" })
  expect(ok, "noren on the 5-stud grid: " .. tostring(reason))
  expect(Placement.wallSpot(ctx, walls, { x = 0, y = 1, z = 20 }, { x = 0, y = 1, z = 0 }, inside, item.size, 1, 0) == nil, "no wall near the middle of the room")
end)
