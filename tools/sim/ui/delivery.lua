-- A delivery: the pop-up when the van parks, then the one when the boxes are down.
Sim.startServer()
task.wait(1)
local S = Sim.core().S
local p = Sim.addPlayer({ name = "Aiko" })
Sim.startClient(p, Sim.previewDevice or "phone")
local d = Sim.waitFor(function()
	return S.Data.get(p)
end, 30)
Sim.waitFor(function()
	local core = Sim.clientRequire(p.PlayerScripts.Client.Core)
	return core.C.Data and core.C.Data.ready and core.C
end, 30)
d.meta.tutorial = -1
d.yen += 2000
task.wait(3)
Sim.fire(p, "OrderSupplies", { noodles = { small = 1 }, naruto = { small = 1 } })
local function popup()
	local holder = p.PlayerGui.RamenUI:FindFirstChild("Toasts")
	for _, f in ipairs(holder and holder:GetChildren() or {}) do
		if f.Name == "Popup" then
			return f
		end
	end
	return nil
end
Sim.waitFor(popup, 20)
task.wait(0.8)
Sim.snapshot("delivery_arriving")
task.wait(3)
Sim.snapshot("delivery_done")
