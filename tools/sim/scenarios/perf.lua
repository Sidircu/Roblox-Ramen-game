-- Budgets for a full street (four restaurants open, customers coming): parts, lights, parts the
-- client's rays have to test, per area. A bigger number than the budget fails the run, so a new
-- model or decoration that costs too much shows up at once (docs/02 §14).
Sim.startServer()
task.wait(1)
local S = Sim.core().S
for i = 1, 4 do
	Sim.addPlayer({ userId = 4000 + i, name = "P" .. i })
end
Sim.waitFor(function()
	local n = 0
	for _, plot in ipairs(S.Plots.list) do
		if plot.owner and plot.folder:GetAttribute("Ready") then
			n += 1
		end
	end
	return n == 4
end, 60)
task.wait(45)

local function count(root)
	local c = { parts = 0, lights = 0, query = 0, shadows = 0 }
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("BasePart") then
			c.parts += 1
			if d.CastShadow then
				c.shadows += 1
			end
			if not d.CanCollide and d.CanQuery then
				c.query += 1
			end
		elseif d:IsA("Light") then
			c.lights += 1
		end
	end
	return c
end

local BUDGET = {
	street = { parts = 8500, lights = 80, query = 50 },
	restaurant = { parts = 2600, lights = 40, query = 1200 }, -- shell + placed objects of a new restaurant
	npcs = { parts = 1500 },
	total = { parts = 20000, lights = 260 },
}
local street = count(workspace.Street)
Sim.say(string.format("street: %d parts, %d lights, %d decorative parts tested by rays, %d casting shadows", street.parts, street.lights, street.query, street.shadows))
Sim.check("street parts within budget", street.parts <= BUDGET.street.parts, street.parts)
Sim.check("street lights within budget", street.lights <= BUDGET.street.lights, street.lights)
Sim.check("street decorations are not tested by rays", street.query <= BUDGET.street.query, street.query)
for _, plot in ipairs(S.Plots.list) do
	local shell, items = count(plot.folder.Shell), count(plot.folder.Items)
	local parts, lights, query = shell.parts + items.parts, shell.lights + items.lights, shell.query + items.query
	Sim.say(string.format("restaurant %d: %d parts (shell %d, objects %d), %d lights, %d tested by rays", plot.id, parts, shell.parts, items.parts, lights, query))
	Sim.check("restaurant " .. plot.id .. " parts within budget", parts <= BUDGET.restaurant.parts, parts)
	Sim.check("restaurant " .. plot.id .. " lights within budget", lights <= BUDGET.restaurant.lights, lights)
	Sim.check("restaurant " .. plot.id .. " rays within budget", query <= BUDGET.restaurant.query, query)
end
local npcs = count(workspace.NPCs)
Sim.say(string.format("customers and staff: %d parts", npcs.parts))
Sim.check("characters within budget", npcs.parts <= BUDGET.npcs.parts, npcs.parts)
local all = count(workspace)
Sim.say(string.format("whole street: %d parts, %d lights", all.parts, all.lights))
Sim.check("whole street within budget", all.parts <= BUDGET.total.parts and all.lights <= BUDGET.total.lights, all.parts .. " parts, " .. all.lights .. " lights")
