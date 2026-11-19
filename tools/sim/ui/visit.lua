-- Two friends on the street: Ben walks into Aiko's restaurant (HUD while visiting) and Aiko's
-- restaurant has a few orders waiting.
Sim.startServer()
task.wait(1)
local S = Sim.core().S
local a = Sim.addPlayer({ userId = 2001, name = "Aiko" })
local b = Sim.addPlayer({ userId = 2002, name = "Ben" })
Sim.startClient(b, Sim.previewDevice or "phone")
Sim.waitFor(function()
	return S.Data.get(a) and S.Data.get(b) and S.Plots.ofPlayer(a) and S.Plots.ofPlayer(b)
end, 30)
task.wait(30)
local pa = S.Plots.ofPlayer(a)
b.Character:PivotTo(CFrame.new(pa.origin + Vector3.new(0, 3, 6)))
task.wait(3)
Sim.snapshot("visiting")
