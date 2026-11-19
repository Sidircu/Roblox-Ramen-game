-- A brand-new player plays the core loop through the real remotes: the first customer orders by
-- themselves within seconds, the order is cooked in one press per step, served and paid on the
-- spot, then the dirty dish is collected and washed. Times are checked against the 30-second goal.
Sim.startServer()
task.wait(1)
local S = Sim.core().S
local Recipes = Sim.shared("Config.Recipes")
local p = Sim.addPlayer({ name = "Newbie" })
local d = Sim.waitFor(function()
	return S.Data.get(p)
end, 30)
Sim.check("profile loaded", d ~= nil)
local t0 = Sim.now
task.wait(0.6)
local plot = S.Plots.ofPlayer(p)
Sim.check("the player has a restaurant", plot ~= nil)
Sim.check("the starter shelves are stocked", S.Supply.shelfStock(plot, "noodles") >= 10 and S.Supply.shelfStock(plot, "naruto") >= 10 and S.Supply.shelfStock(plot, "scallion") >= 10)

local function goTo(model)
	local pos = model:GetPivot().Position
	p.Character:PivotTo(CFrame.new(pos + Vector3.new(0, 0, -3)))
	task.wait(0.4) -- a short walk
end

-- the first customer orders by themselves
local ticket = Sim.waitFor(function()
	return S.Cooking.ticketsOf(plot)[1]
end, 60)
Sim.check("first order within 20 s", ticket and Sim.now - t0 <= 20, ticket and string.format("%.1f s", Sim.now - t0) or "no order")
if not ticket then
	return
end
local recipe = Recipes.byId[ticket.recipe]
local station
for _, e in ipairs(S.Entities.ofKind("station", plot)) do
	if e.item.fn.station == recipe.station then
		station = e
		break
	end
end
Sim.check("a station for the order", station ~= nil, recipe.station)
goTo(station.model)
Sim.check("the station shows the next order", station.model:GetAttribute("Next") == recipe.id and station.model:GetAttribute("Missing") == "", tostring(station.model:GetAttribute("Next")) .. " / missing " .. tostring(station.model:GetAttribute("Missing")))
local presses = 0
while (station.model:GetAttribute("Ready") or "") == "" and presses < 8 do
	Sim.fire(p, "Interact", station.uid, {})
	presses += 1
	task.wait(0.2)
	Sim.waitFor(function()
		return not station.model:GetAttribute("Busy")
	end, 10)
end
Sim.check("dish ready in one press per step", presses == #recipe.steps, presses .. " presses for " .. #recipe.steps .. " steps")
Sim.fire(p, "Interact", station.uid, {})
task.wait(0.3)
Sim.check("the dish is in hand", p:GetAttribute("HandsKind") == "dish")

local cust = S.Entities.get(ticket.customer)
Sim.check("the customer is still waiting", cust ~= nil)
goTo(cust.model)
local yen = d.yen
Sim.fire(p, "Interact", cust.uid, {})
task.wait(0.5)
Sim.check("paid on the spot", d.yen > yen, "yen " .. yen .. " -> " .. d.yen)
local loopTime = Sim.now - t0
Sim.check("first customer served and paid within 35 s", loopTime <= 35, string.format("%.1f s", loopTime))
Sim.say(string.format("core loop: first order %.1f s, served and paid %.1f s after joining", ticket.created - Sim.epoch - t0, loopTime))

-- after eating: collect the dirty dish and wash it
local dirty = Sim.waitFor(function()
	return S.Entities.ofKind("dirty", plot)[1]
end, 40)
Sim.check("the customer leaves a dirty dish", dirty ~= nil)
if dirty then
	goTo(dirty.model)
	Sim.fire(p, "Interact", dirty.uid, {})
	task.wait(0.3)
	local sink = S.Entities.ofKind("sink", plot)[1]
	goTo(sink.model)
	Sim.fire(p, "Interact", sink.uid, {})
	task.wait(0.3)
	Sim.check("the dish goes in the sink", (plot.folder:GetAttribute("SinkPile") or 0) >= 1)
	Sim.fire(p, "Wash", sink.uid, true)
	task.wait(4)
	Sim.fire(p, "Wash", sink.uid, false)
	Sim.check("washed while holding", (plot.folder:GetAttribute("SinkPile") or 0) == 0)
end

-- the day goes on by itself: a whole day later the day was closed and summed up
local days = d.stats.days
task.wait(15 * 60)
Sim.check("a day passed without pressing anything", d.stats.days == days + 1, "days " .. tostring(days) .. " -> " .. tostring(d.stats.days))
