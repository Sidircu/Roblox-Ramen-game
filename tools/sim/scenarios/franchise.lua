-- The first franchise: a restaurant at level 11 with the first three rooms and a 4-star rating
-- opens in Kyoto. Level, yen, licences, rooms, staff and upgrades start again; the furniture goes
-- to the inventory; the restaurant is rebuilt with the starter kitchen and works; the earnings
-- while away start again from the new city's days; the star pays more for every dish.
Sim.startServer()
task.wait(1)
local S = Sim.core().S
local FranchiseCfg = Sim.shared("Config.Franchise")
local GameConfig = Sim.shared("Config.GameConfig")
local StarterLayout = Sim.shared("Config.StarterLayout")

local profile = S.Data.newProfile()
profile.level = 11
profile.xp = 100
profile.yen = 90000
profile.meta.tutorial = -1
profile.zones.zone_east = true
profile.zones.zone_storage2 = true
profile.zones.zone_west = true
profile.licenses.lic_sushi0 = true
profile.upgrades = { up_tray = 2, up_shoes = 3, up_safe = 1 }
for _ = 1, 30 do
	table.insert(profile.reviews.recent, { s = 5, w = 1 })
end
profile.stats.dishes = 2500
profile.stats.dayHistory = { 40000, 42000 }
profile.stats.lastDayEarned = 42000
-- two tables bought in the east room
table.insert(profile.placed, { u = "p_t1", i = "table_2", x = -50, z = 12, r = 0, f = 0, t = 0 })
table.insert(profile.placed, { u = "p_t2", i = "table_2", x = -50, z = 22, r = 0, f = 0, t = 0 })
Sim.store("ds", "Profiles_v1").__data["u_3001"] = { data = profile }

local p = Sim.addPlayer({ userId = 3001, name = "Aiko" })
Sim.startClient(p, "desktop")
local d = Sim.waitFor(function()
	return S.Data.get(p) and S.Plots.ofPlayer(p) and S.Data.get(p)
end, 30)
Sim.check("profile loaded", d ~= nil)
local plot = S.Plots.ofPlayer(p)
local C = Sim.waitFor(function()
	local core = Sim.clientRequire(p.PlayerScripts.Client.Core)
	return core.C.Data and core.C.Data.ready and core.C
end, 30)
Sim.check("the client is ready", C ~= nil)
Sim.check("the first franchise is ready", S.Franchise.check(d, plot) == true)
Sim.check("the kitchen shoes make the owner faster", p:GetAttribute("WalkSpeed") > GameConfig.WalkSpeed, tostring(p:GetAttribute("WalkSpeed")))
local placedBefore = #d.placed
local tables = (d.inventory.table_2 or 0)

Sim.fire(p, "Franchise", "kyoto")
Sim.check("Kyoto opens with one star", Sim.waitFor(function()
	return d.franchise.stars == 1
end, 10) == true and d.franchise.city == "kyoto", tostring(d.franchise.city))
Sim.check("the level starts again", d.level == 1 and d.xp == 0, d.level .. "/" .. d.xp)
Sim.check("the yen start again", d.yen == FranchiseCfg.StartYen, tostring(d.yen))
Sim.check("rooms, licences, staff and upgrades start again", d.zones.zone_east == nil and d.licenses.lic_sushi0 == nil and #d.staff == 0 and next(d.upgrades) == nil)
Sim.check("the furniture goes to the inventory", (d.inventory.table_2 or 0) == tables + 2 and #d.placed == #StarterLayout.items, placedBefore .. " placed before")
Sim.check("dishes and achievements are kept", d.stats.dishes == 2500)
Sim.check("the earnings while away start again in the new city", #d.stats.dayHistory == 0 and d.stats.lastDayEarned == 0)
Sim.check("the walking speed goes back to normal with the shoes", p:GetAttribute("WalkSpeed") == GameConfig.WalkSpeed, tostring(p:GetAttribute("WalkSpeed")))
Sim.check("the rating starts again", #d.reviews.recent == 0)

-- the restaurant is rebuilt with the starter kitchen and it works
task.wait(2)
local Entities = S.Entities
Sim.check("the stations are back", #Entities.ofKind("station", plot) >= 2 and #Entities.ofKind("shelf", plot) >= 2)
Sim.check("the client shows level 1", Sim.waitFor(function()
	return C.Data.w("level") == 1
end, 5) == true)

-- the star pays 25% more for the same dish
local Economy = S.Economy
local yen = d.yen
Economy.add(p, 1000, "sale")
Sim.check("a star pays 25% more", d.yen - yen == math.floor(1000 * (1 + FranchiseCfg.YenPerStar) + 0.5), tostring(d.yen - yen))

-- the next city asks for more: no second franchise straight away
Sim.check("the next city is not ready yet", S.Franchise.check(d, plot) == false)
Sim.fire(p, "Franchise", "osaka")
task.wait(1)
Sim.check("no second franchise straight away", d.franchise.stars == 1)
Sim.check("server closes cleanly", Sim.close())
