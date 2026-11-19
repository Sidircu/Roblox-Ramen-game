-- The server starts, a player joins, the in-game self test plays the whole loop, customers come
-- and go for a few minutes, then the player leaves and the profile is saved.
Sim.startServer()
task.wait(1)
local S = Sim.core().S
Sim.check("services loaded", S.Data and S.Customers and S.Cooking and S.Supply and S.Staff, "a service failed to load")

local p = Sim.addPlayer({ name = "Aiko" })
local d = Sim.waitFor(function()
	return S.Data.get(p)
end, 30)
Sim.check("profile loaded", d ~= nil)
task.wait(3)
local plot = S.Plots.ofPlayer(p)
Sim.check("player owns a restaurant", plot ~= nil)
Sim.check("starter objects placed", #S.Entities.ofKind("station", plot) >= 2, #S.Entities.ofKind("station", plot) .. " stations")

local passed, total = S.SelfTest.run(p)
Sim.check("in-game self test", passed == total, tostring(passed) .. "/" .. tostring(total))

-- a few minutes of service with customers coming and going
task.wait(180)
Sim.check("customers came", (d.stats.customers or 0) >= 1, "customers " .. tostring(d.stats.customers))

-- analytics: the onboarding steps of this new player and the economy events
local steps, economy = {}, 0
for _, a in ipairs(Sim.analytics) do
	if a.kind == "onboarding" and a.args[1] == p then
		steps[a.args[3]] = a.args[2]
	elseif a.kind == "economy" then
		economy += 1
	end
end
for _, name in ipairs({ "joined", "first_order", "first_cook", "first_serve" }) do
	Sim.check("onboarding step " .. name, steps[name] ~= nil)
end

Sim.removePlayer(p)
task.wait(3)
local saved = Sim.store("ds", "Profiles_v1").__data["u_" .. p.UserId]
Sim.check("profile saved on leave", saved and saved.data and saved.data.v ~= nil)
Sim.check("lock released on leave", saved and saved.lock == nil)
Sim.check("server closes cleanly", Sim.close())
