-- The HUD of a brand-new player a few seconds in: the first order is on screen.
Sim.startServer()
task.wait(1)
local S = Sim.core().S
local p = Sim.addPlayer({ name = "Aiko" })
Sim.startClient(p, Sim.previewDevice or "phone")
Sim.waitFor(function()
	return S.Data.get(p)
end, 30)
task.wait(20)
Sim.snapshot("hud")
-- tap the order: the step-by-step guide opens on the left
local ticket = p.PlayerGui.RamenUI.HUD.Tickets:FindFirstChild("Ticket")
if ticket then
	Sim.click(ticket)
	task.wait(0.6)
	Sim.snapshot("guide")
end
