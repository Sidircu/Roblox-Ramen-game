-- The franchise tab of the goals: what the next city asks for, ticked off one by one.
Sim.startServer()
task.wait(1)
local S = Sim.core().S
local p = Sim.addPlayer({ name = "Aiko" })
Sim.startClient(p, Sim.previewDevice or "phone")
local d = Sim.waitFor(function()
	return S.Data.get(p)
end, 30)
d.meta.tutorial = -1
d.level = 9
d.zones.zone_east = true
S.Data.changed(p, "level")
S.Data.changed(p, "zones")
S.Data.changed(p, "meta")
task.wait(4)
local C = Sim.clientRequire(p.PlayerScripts.Client.Core).C
C.UI.open("Goals")
task.wait(0.5)
Sim.click(Sim.findText("Franchise", { button = true }))
task.wait(0.6)
Sim.snapshot("franchise")
