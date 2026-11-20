-- The tutorial banner at a few steps: welcome (how to move on this device), cooking, the gift with
-- the hand on the shop button, and a
-- one-time tip after the tutorial.
Sim.startServer()
task.wait(1)
local S = Sim.core().S
local p = Sim.addPlayer({ name = "Aiko" })
Sim.startClient(p, Sim.previewDevice or "phone")
local d = Sim.waitFor(function()
	return S.Data.get(p)
end, 30)
local C = Sim.waitFor(function()
	local core = Sim.clientRequire(p.PlayerScripts.Client.Core)
	return core.C.Data and core.C.Data.ready and core.C
end, 30)
local plot = S.Plots.ofPlayer(p)
-- walk up and use the prompt; with a mouse the client aims with a ray, which the simulator does
-- not trace, so the remote is sent directly then
local function use(model)
	local pos = model:GetPivot().Position
	local from = pos + Vector3.new(0, 0, -3)
	p.Character:PivotTo(CFrame.lookAt(from, Vector3.new(pos.X, from.Y, pos.Z)))
	task.wait(0.6)
	if not Sim.trigger(model) then
		Sim.fire(p, "Interact", model:GetAttribute("Uid"), {})
		task.wait(0.3)
	end
end
Sim.waitFor(function()
	return C.Tutorial.currentId() == "welcome"
end, 30)
task.wait(1)
Sim.snapshot("tutorial_welcome")
Sim.waitFor(function()
	return C.Tutorial.currentId() == "cook"
end, 60)
local station
for _, e in ipairs(S.Entities.ofKind("station", plot)) do
	if e.item.fn.station == "ramen" then
		station = e
	end
end
use(station.model)
task.wait(1)
Sim.snapshot("tutorial_cook")
for _ = 1, 6 do
	if C.Tutorial.currentId() ~= "cook" then
		break
	end
	use(station.model)
	task.wait(1)
end
use(station.model)
task.wait(0.5)
local ticket = S.Cooking.ticketsOf(plot)[1]
use(S.Entities.get(ticket and ticket.customer or "").model)
Sim.waitFor(function()
	return C.Tutorial.currentId() == "reward"
end, 10)
task.wait(1)
Sim.snapshot("tutorial_gift")
-- a tip, after the tutorial
Sim.click(p.PlayerGui.RamenUI.Tutorial:FindFirstChild("Skip", true))
d.level = 4
d.yen = 6000
S.Data.changed(p, "level")
S.Data.changed(p, "yen")
Sim.waitFor(function()
	local h = p.PlayerGui.RamenUI:FindFirstChild("Hint")
	return h and h.Visible
end, 40)
task.wait(0.5)
Sim.snapshot("tip")
