-- The shop of a restaurant a little way in: enough yen for some upgrades, not for others.
Sim.startServer()
task.wait(1)
local S = Sim.core().S
local p = Sim.addPlayer({ name = "Aiko" })
Sim.startClient(p, Sim.previewDevice or "phone")
local d = Sim.waitFor(function()
	return S.Data.get(p)
end, 30)
task.wait(3)
d.yen = 4200
d.level = 4
S.Data.changed(p, "yen")
S.Data.changed(p, "level")
task.wait(1)
local C = Sim.clientRequire(p.PlayerScripts.Client.Core).C
C.UI.open("Shop", "upgrades")
task.wait(1)
Sim.snapshot("shop_upgrades")
Sim.click(Sim.findText("Ricette", { button = true }) or Sim.findText("Recipes", { button = true }))
task.wait(0.5)
Sim.snapshot("shop_recipes")
Sim.click(Sim.findText("Personale", { button = true }) or Sim.findText("Staff", { button = true }))
task.wait(0.5)
Sim.snapshot("shop_staff")
C.UI.close("Shop")
C.UI.open("Phone")
task.wait(0.5)
Sim.snapshot("phone_apps")
