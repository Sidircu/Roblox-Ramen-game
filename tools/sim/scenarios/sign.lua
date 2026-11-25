-- The restaurant's sign over the door: the owner writes a name, picks a style and two colours in
-- the editor (Screens/Sign) and saves; the sign is built again with the name checked by Roblox's
-- filter, and clients only ever get the filtered name. Names too short or too long, made-up
-- styles, a helper and a filter that cannot answer (on a live server) are refused; the sign stays
-- after leaving and coming back, and the giant sign on the roof shows the name too.
Sim.startServer()
task.wait(1)
local S = Sim.core().S
local Signs = Sim.shared("Config.Signs")

local function join(id, name)
	local p = Sim.addPlayer({ userId = id, name = name })
	Sim.waitFor(function()
		return S.Data.get(p) and S.Plots.ofPlayer(p)
	end, 30)
	return p
end
local a = join(6001, "Aiko")
local b = join(6002, "Ben")
local d = S.Data.get(a)
local plot = S.Plots.ofPlayer(a)
Sim.startClient(a, "desktop")
local C = Sim.waitFor(function()
	local core = Sim.clientRequire(a.PlayerScripts.Client.Core)
	return core.C.Data and core.C.Data.ready and core.C
end, 30)
Sim.check("the client is ready", C ~= nil)
task.wait(1)

local function sign()
	return plot.shopSign
end
local function letters()
	local s = sign()
	local gui = s and s.PrimaryPart and s.PrimaryPart:FindFirstChild("Letters")
	return gui and gui:FindFirstChild("Name"), gui and gui:FindFirstChild("Subtitle")
end
local name = letters()
Sim.check("every restaurant starts with the classic sign", name ~= nil and name.Text == Signs.DefaultText and d.sign.style == "wood", name and name.Text)
Sim.check("the sign can be used", sign() and sign():GetAttribute("Kind") == "shopsign" and sign():GetAttribute("PlotId") == plot.id)

-- the editor: a name, the neon style, an indigo board and pink letters, then save
C.UI.open("Sign")
task.wait(0.5)
local box = Sim.waitFor(function()
	return C.UI.screens.Sign.win.frame:FindFirstChild("NameBox", true)
end, 3)
Sim.check("the editor opens with a name box", box ~= nil)
box.Text = "Sakura Ramen"
task.wait(0.3)
local preview = C.UI.screens.Sign.win.frame:FindFirstChild("PreviewName", true)
Sim.check("the preview shows the name as you type", preview and preview.Text == "Sakura Ramen", preview and preview.Text)
Sim.click(Sim.findText("💡 " .. Sim.clientRequire(game:GetService("ReplicatedStorage").Shared.Locale).t("sign.style_neon")))
task.wait(0.4)
local function colorButton(which, id)
	local found = {}
	for _, d2 in ipairs(C.UI.screens.Sign.win.frame:GetDescendants()) do
		if d2.Name == "Color_" .. id then
			table.insert(found, d2)
		end
	end
	return found[which]
end
Sim.click(colorButton(1, "indigo"))
task.wait(0.4)
Sim.click(colorButton(2, "sakura"))
task.wait(0.4)
Sim.click(C.UI.screens.Sign.win.frame:FindFirstChild("Save", true))
Sim.check("saved: name, style and colours", Sim.waitFor(function()
	return d.sign.name == "Sakura Ramen"
end, 4) == true and d.sign.shown == "Sakura Ramen" and d.sign.style == "neon" and d.sign.board == "indigo" and d.sign.text == "sakura", d.sign.name .. " " .. d.sign.style .. " " .. d.sign.board .. " " .. d.sign.text)
local name2, sub = letters()
Sim.check("the sign over the door shows the name", name2 and name2.Text == "Sakura Ramen" and sub ~= nil, name2 and name2.Text)
local neon = 0
for _, part in ipairs(sign():GetDescendants()) do
	if part:IsA("BasePart") and part.Material == Enum.Material.Neon then
		neon += 1
	end
end
Sim.check("in the neon style", neon >= 4, neon .. " neon tubes")
Sim.check("in the right place over the door", math.abs(sign().PrimaryPart.Position.X - plot.origin.X) < 0.01 and math.abs(sign().PrimaryPart.Position.Y - Signs.Facade.y) < 0.5)

-- Roblox's filter: a word that is not allowed becomes ####
task.wait(3.2)
Sim.fire(a, "SetSign", { name = "badword Ramen", style = "wood", board = "hinoki", text = "ink" })
task.wait(0.5)
Sim.check("the filter hides words that are not allowed", d.sign.name == "badword Ramen" and d.sign.shown == "####### Ramen" and letters().Text == "####### Ramen", d.sign.shown)
-- what was typed stays on the server: clients (the owner's, the helpers') get only the filtered name
local mine, world, snap = C.Data.w("sign"), S.Data.worldOf(plot).sign, S.Data.snapshot(a).me.sign
Sim.check("clients only get the filtered name", mine and mine.name == nil and mine.shown == "####### Ramen" and world.name == nil and world.shown == "####### Ramen" and snap.name == nil, mine and tostring(mine.name))

-- refused: too short, too long, made up, too soon, by a visitor, when the filter cannot answer
local before = d.sign.shown
task.wait(3.2)
Sim.fire(a, "SetSign", { name = "A", style = "wood", board = "hinoki", text = "ink" })
task.wait(0.3)
Sim.fire(a, "SetSign", { name = string.rep("x", Signs.MaxName + 1), style = "wood", board = "hinoki", text = "ink" })
task.wait(0.3)
Sim.fire(a, "SetSign", { name = "Good name", style = "pink", board = "hinoki", text = "ink" })
task.wait(0.3)
Sim.check("too short, too long or a made-up style: nothing changes", d.sign.shown == before)
-- Ben walks into Aiko's restaurant: a helper there (in Studio everybody counts as a friend), who
-- cooks and serves but may not change her sign (nor, from there, his own)
b.Character:PivotTo(CFrame.new(plot.origin + Vector3.new(0, 3, 10)))
task.wait(1)
Sim.check("Ben now helps in Aiko's restaurant", S.Plots.of(b) == plot and S.Plots.role(b, plot) == "helper", S.Plots.role(b, plot))
Sim.fire(b, "SetSign", { name = "Ben was here", style = "wood", board = "red", text = "white" })
task.wait(0.3)
Sim.check("a helper cannot change it", d.sign.shown == before and S.Data.get(b).sign.name == "")
b.Character:PivotTo(CFrame.new(S.Plots.ofPlayer(b).origin + Vector3.new(0, 3, 10)))
-- on a live server a name the filter cannot check is not shown
Sim.studio = false
Sim.filterDown = true
Sim.fire(a, "SetSign", { name = "Neko-ya", style = "wood", board = "red", text = "white" })
task.wait(0.3)
Sim.filterDown = false
Sim.studio = true
Sim.check("a name the filter cannot check is not shown", d.sign.shown == before and d.sign.name ~= "Neko-ya")
-- (that try counts as a change too, so the filter is not asked again and again); in Studio, where
-- the filter may not answer, the name is shown as typed so the sign can be tried
task.wait(3.2)
Sim.filterDown = true
Sim.fire(a, "SetSign", { name = "Studio test", style = "wood", board = "red", text = "white" })
task.wait(0.3)
Sim.filterDown = false
Sim.check("in Studio the name shows without the filter", d.sign.shown == "Studio test", d.sign.shown)
task.wait(3.2)
Sim.fire(a, "SetSign", { name = "Neko-ya", style = "lanterns", board = "red", text = "white" })
task.wait(0.3)
Sim.fire(a, "SetSign", { name = "Neko-ya 2", style = "lanterns", board = "red", text = "white" })
task.wait(0.3)
Sim.check("one change every few seconds", d.sign.name == "Neko-ya", d.sign.name)
local lights = 0
for _, l in ipairs(sign():GetDescendants()) do
	if l:IsA("PointLight") then
		lights += 1
	end
end
Sim.check("the lanterns style has two lanterns with a light", lights == 2, lights .. " lights")

-- the noren style: three cloth panels under a rod with round ends (the panels stay flat boxes:
-- the round ends must not pass their shape on through the options table they share, Models/Kit)
task.wait(3.2)
Sim.fire(a, "SetSign", { name = "Neko-ya", style = "noren", board = "indigo", text = "white" })
task.wait(0.3)
local panels = 0
for _, part in ipairs(sign():GetDescendants()) do
	if part:IsA("Part") and part.Material == Enum.Material.Fabric and part.Shape == Enum.PartType.Block and part.Transparency < 1 and part.Size.X > 3 and part.Size.Y > 2 then
		panels += 1
	end
end
Sim.check("the noren style hangs three cloth panels", d.sign.style == "noren" and panels == 3, panels .. " panels")
local Kit = require(game:GetService("ReplicatedStorage").Shared.Models.Kit)
local shared = { collide = false }
Kit.ball(nil, 1, 0, 0, 0, "#FFFFFF", nil, shared)
Kit.cyl(nil, 1, 1, 0, 0, 0, "#FFFFFF", nil, shared)
Kit.cylH(nil, 1, 1, 0, 0, 0, "#FFFFFF", nil, shared)
Sim.check("round parts leave the options they were given alone", shared.shape == nil)

-- the giant sign on the roof shows the name too
d.zones.sign_rooftop = true
S.World.rebuild(plot, d)
task.wait(0.5)
local giant = plot.folder:FindFirstChild("GiantName", true)
Sim.check("the giant sign on the roof shows the name", giant ~= nil and giant.Text == "Neko-ya", giant and giant.Text)
Sim.check("and the sign over the door is still the restaurant's", letters().Text == "Neko-ya")

-- leaving and coming back: the same sign
S.Data.save(a, true)
Sim.removePlayer(a)
task.wait(2)
local a2 = join(6001, "Aiko")
local d2 = S.Data.get(a2)
local plot2 = S.Plots.ofPlayer(a2)
task.wait(1)
local back = plot2.shopSign and plot2.shopSign.PrimaryPart:FindFirstChild("Letters")
Sim.check("the sign is still there after coming back", d2.sign.name == "Neko-ya" and back and back.Name and back:FindFirstChild("Name").Text == "Neko-ya", d2.sign.name)
Sim.check("server closes cleanly", Sim.close())
