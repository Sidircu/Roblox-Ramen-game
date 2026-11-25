-- Settings → Other restaurants: with "Only the outside" the objects, lights and people inside the
-- other restaurants of the street are hidden on your screen (the buildings stay); the restaurant
-- you walk into is complete again; "Show all" brings everything back. Nothing changes on the server.
Sim.startServer()
task.wait(1)
local S = Sim.core().S
local function join(id, name)
	local p = Sim.addPlayer({ userId = id, name = name })
	Sim.waitFor(function()
		return S.Data.get(p) and S.Plots.ofPlayer(p)
	end, 30)
	return p
end
local a = join(5001, "Aiko")
local b = join(5002, "Ben")
Sim.startClient(a, "desktop")
local C = Sim.waitFor(function()
	local core = Sim.clientRequire(a.PlayerScripts.Client.Core)
	return core.C.Data and core.C.Data.ready and core.C
end, 30)
Sim.check("the client is ready", C ~= nil)
local pa, pb = S.Plots.ofPlayer(a), S.Plots.ofPlayer(b)
task.wait(2)

-- the parts and lights inside a restaurant
local function inside(plot)
	local parts, lights = {}, {}
	local items = plot.folder:FindFirstChild("Items")
	for _, d in ipairs(items and items:GetDescendants() or {}) do
		if d:IsA("BasePart") then
			table.insert(parts, d)
		elseif d:IsA("Light") and d:GetAttribute("NightLight") ~= true then
			table.insert(lights, d)
		end
	end
	return parts, lights
end
local function hiddenShare(plot)
	local parts = inside(plot)
	local n = 0
	for _, p in ipairs(parts) do
		if p.LocalTransparencyModifier >= 1 then
			n += 1
		end
	end
	return #parts > 0 and n / #parts or -1
end
local bParts, bLights = inside(pb)
local lightsOn = 0
for _, l in ipairs(bLights) do
	if l.Enabled then
		lightsOn += 1
	end
end
Sim.check("by default every restaurant is complete", hiddenShare(pa) == 0 and hiddenShare(pb) == 0 and #bParts > 100, #bParts .. " parts")

Sim.fire(a, "SetSetting", "others", "hide")
task.wait(2)
Sim.check("the setting is saved", S.Data.get(a).settings.others == "hide")
Sim.check("the other restaurant's inside is hidden on my screen", hiddenShare(pb) == 1, string.format("%.2f", hiddenShare(pb)))
Sim.check("mine is complete", hiddenShare(pa) == 0, string.format("%.2f", hiddenShare(pa)))
local stillOn = 0
for _, l in ipairs(bLights) do
	if l.Enabled then
		stillOn += 1
	end
end
Sim.check("its lights are off on my screen", stillOn == 0, stillOn .. " of " .. lightsOn .. " on")
Sim.check("its building stays", pb.folder:FindFirstChild("Shell") ~= nil and pb.folder.Shell:FindFirstChildWhichIsA("BasePart", true).LocalTransparencyModifier == 0)

-- walking into the other restaurant: it is complete, mine is hidden now
a.Character:PivotTo(CFrame.new(pb.origin + Vector3.new(0, 3, 10)))
task.wait(2)
Sim.check("the restaurant I walk into is complete", hiddenShare(pb) == 0, string.format("%.2f", hiddenShare(pb)))
Sim.check("the one I left is hidden", hiddenShare(pa) == 1, string.format("%.2f", hiddenShare(pa)))

-- back to show all: everything as it was, lights included
Sim.fire(a, "SetSetting", "others", "show")
task.wait(2)
local backOn = 0
for _, l in ipairs(bLights) do
	if l.Enabled then
		backOn += 1
	end
end
Sim.check("show all brings everything back", hiddenShare(pa) == 0 and hiddenShare(pb) == 0 and backOn == lightsOn, backOn .. "/" .. lightsOn .. " lights")
Sim.fire(a, "SetSetting", "others", "nonsense")
task.wait(0.5)
Sim.check("a made-up value is refused", S.Data.get(a).settings.others == "show")
Sim.check("server closes cleanly", Sim.close())
