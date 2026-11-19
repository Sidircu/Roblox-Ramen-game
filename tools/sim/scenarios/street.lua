-- Four players on one street: everyone gets a restaurant of their own, a friend helps in another
-- restaurant (and gets a share), a stranger may not, an owner leaves and the lot empties, a fifth
-- player finds no free plot, and two saves with the same object id still work side by side.
-- a published server (in Studio every test player counts as a friend)
Sim.studio = false
Sim.startServer()
task.wait(1)
local S = Sim.core().S
local Recipes = Sim.shared("Config.Recipes")

local function join(id, name)
	local p = Sim.addPlayer({ userId = id, name = name })
	Sim.waitFor(function()
		return S.Data.get(p) and S.Plots.ofPlayer(p)
	end, 30)
	return p
end

-- a save that shares an object id with the first player's restaurant (see the end)
local a = join(1001, "Aiko")
local da = S.Data.get(a)
local sharedUid = da.placed[1].u
local bProfile = S.Data.newProfile()
bProfile.placed[1].u = sharedUid
Sim.store("ds", "Profiles_v1").__data["u_1002"] = { data = bProfile }

local b = join(1002, "Ben")
local c = join(1003, "Chiara")
local d4 = join(1004, "Dai")
task.wait(3)
local plots = {}
for _, p in ipairs({ a, b, c, d4 }) do
	local plot = S.Plots.ofPlayer(p)
	Sim.check(p.Name .. " has a restaurant", plot ~= nil)
	if plot then
		Sim.check(p.Name .. " has a plot of their own", plots[plot.id] == nil)
		plots[plot.id] = p
	end
end
local pa, pb, pc = S.Plots.ofPlayer(a), S.Plots.ofPlayer(b), S.Plots.ofPlayer(c)
Sim.check("restaurants stand side by side", pa.origin.X ~= pb.origin.X and math.abs(pa.origin.X - pb.origin.X) >= 200)
Sim.check("every restaurant has its stations", #S.Entities.ofKind("station", pa) >= 2 and #S.Entities.ofKind("station", pb) >= 2 and #S.Entities.ofKind("station", pc) >= 2)
Sim.check("the stations stand on their own plot", (function()
	for _, e in ipairs(S.Entities.ofKind("station")) do
		if S.Plots.at(e.model:GetPivot().Position) ~= e.plot then
			return false
		end
	end
	return true
end)())
Sim.check("the shared id was renamed", S.Data.get(b).placed[1].u ~= sharedUid)
Sim.check("both objects with the shared id exist", S.Entities.get(sharedUid) ~= nil and S.Entities.get(S.Data.get(b).placed[1].u) ~= nil)

-- a fifth player: every plot is taken
local e5 = Sim.addPlayer({ userId = 1005, name = "Eri" })
task.wait(4)
Sim.check("a fifth player gets no plot", S.Plots.ofPlayer(e5) == nil)
local told = false
for _, k in ipairs(Sim.noticesFor(e5)) do
	if k == "msg.no_plot" then
		told = true
	end
end
Sim.check("and is told why", told)

-- customers come to every restaurant
task.wait(40)
for _, plot in ipairs({ pa, pb, pc }) do
	Sim.check("orders in restaurant " .. plot.id, #S.Cooking.ticketsOf(plot) >= 1, #S.Cooking.ticketsOf(plot) .. " tickets")
end

-- Ben is Aiko's friend: he walks into her restaurant and cooks and serves her order
Sim.friends["1001:1002"] = true
local function goTo(p, model)
	p.Character:PivotTo(CFrame.new(model:GetPivot().Position + Vector3.new(0, 0, -3)))
	task.wait(0.8)
end
local ticket = S.Cooking.ticketsOf(pa)[1]
local recipe = Recipes.byId[ticket.recipe]
local station
for _, e in ipairs(S.Entities.ofKind("station", pa)) do
	if e.item.fn.station == recipe.station then
		station = e
	end
end
goTo(b, station.model)
Sim.check("Ben now works in Aiko's restaurant", S.Plots.of(b) == pa)
Sim.check("and is a helper there", S.Plots.role(b, pa) == "helper")
local presses = 0
while (station.model:GetAttribute("Ready") or "") == "" and presses < 8 do
	Sim.fire(b, "Interact", station.uid, {})
	presses += 1
	task.wait(0.2)
	Sim.waitFor(function()
		return not station.model:GetAttribute("Busy")
	end, 10)
end
Sim.check("Ben cooked Aiko's order", (station.model:GetAttribute("Ready") or "") == recipe.id, presses .. " presses")
Sim.fire(b, "Interact", station.uid, {})
task.wait(0.3)
local cust = S.Entities.get(ticket.customer)
goTo(b, cust.model)
local yenA, yenB = da.yen, S.Data.get(b).yen
Sim.fire(b, "Interact", cust.uid, {})
task.wait(0.5)
Sim.check("Aiko is paid", da.yen > yenA, yenA .. " -> " .. da.yen)
Sim.check("Ben gets a helper share", S.Data.get(b).yen > yenB, yenB .. " -> " .. S.Data.get(b).yen)

-- Chiara is not a friend: she may not use Aiko's stations
goTo(c, station.model)
Sim.check("Chiara is a visitor in Aiko's restaurant", S.Plots.role(c, pa) == "visitor")
Sim.check("Chiara keeps working in her own restaurant", S.Plots.of(c) == pc)
local before = #Sim.noticesFor(c)
Sim.fire(c, "Interact", station.uid, {})
task.wait(0.3)
local notes = Sim.noticesFor(c)
Sim.check("Chiara is refused", #notes > before and notes[#notes] == "msg.not_your_restaurant", notes[#notes])

-- Aiko leaves: her lot empties, Ben goes back to his own restaurant
Sim.removePlayer(a)
task.wait(3)
Sim.check("Aiko's plot is free again", pa.owner == nil)
Sim.check("nothing of Aiko's restaurant is left", #S.Entities.ofPlot(pa) == 0, #S.Entities.ofPlot(pa) .. " entities")
local left = 0
for _, cu in pairs(S.Customers.active) do
	if cu.plot == pa then
		left += 1
	end
end
Sim.check("her customers are gone", left == 0)
Sim.check("the lot shows the empty-lot sign", #pa.folder.Shell:GetChildren() > 0 and #pa.folder.Items:GetChildren() == 0)
Sim.waitFor(function()
	return S.Plots.of(b) == pb
end, 3)
Sim.check("Ben works in his own restaurant again", S.Plots.of(b) == pb)

-- the fifth player can now take the free plot when they come back
Sim.removePlayer(e5)
task.wait(2)
local e6 = join(1006, "Fumi")
Sim.check("a newcomer takes the free plot", S.Plots.ofPlayer(e6) == pa)
task.wait(5)
Sim.check("the new restaurant is built", #S.Entities.ofKind("station", pa) >= 2)
Sim.check("server closes cleanly", Sim.close())
