-- The other everyday screens: supplier, menu, goals, gifts, settings, the sign editor, and build
-- mode.
Sim.startServer()
task.wait(1)
local S = Sim.core().S
local p = Sim.addPlayer({ name = "Aiko" })
Sim.startClient(p, Sim.previewDevice or "phone")
local d = Sim.waitFor(function()
	return S.Data.get(p)
end, 30)
task.wait(4)
local C = Sim.clientRequire(p.PlayerScripts.Client.Core).C
for _, name in ipairs({ "Supplier", "Menu", "Goals", "Gifts", "Settings", "Invite" }) do
	C.UI.open(name)
	task.wait(0.5)
	Sim.snapshot("screen_" .. name:lower())
	C.UI.close(name)
end
-- the sign editor with a name typed in, the neon style and pink letters on indigo
d.sign = { name = "", shown = "", style = "neon", board = "indigo", text = "sakura" }
S.Data.changed(p, "sign")
task.wait(0.5)
C.UI.open("Sign")
task.wait(0.5)
local box = C.UI.screens.Sign.win.frame:FindFirstChild("NameBox", true)
if box then
	box.Text = "Sakura Ramen"
end
task.wait(0.3)
Sim.snapshot("screen_sign")
C.UI.close("Sign")
C.Build.toggle()
task.wait(1)
Sim.snapshot("build_mode")
C.Build.toggle()
