-- A brand-new player on a phone plays through the real client: the first order shows up as a
-- ticket, the station's prompt cooks it one press per step, the customer's prompt serves it, then
-- the shop opens from the dock and a card buys an upgrade. Any error in the client scripts fails
-- the run.
Sim.startServer()
task.wait(1)
local S = Sim.core().S
local Recipes = Sim.shared("Config.Recipes")
local p = Sim.addPlayer({ name = "Mobile" })
Sim.startClient(p, "phone")
local d = Sim.waitFor(function()
	return S.Data.get(p)
end, 30)
Sim.check("profile loaded", d ~= nil)
local C = Sim.waitFor(function()
	local core = Sim.clientRequire(p.PlayerScripts.Client.Core)
	return core.C.Data and core.C.Data.ready and core.C
end, 30)
Sim.check("the client is ready", C ~= nil)
local Locale = Sim.clientRequire(game:GetService("ReplicatedStorage").Shared.Locale)
local plot = S.Plots.ofPlayer(p)
Sim.check("the phone layout is used", C.UI.profile == "phone", C.UI.profile)
Sim.check("readable on a phone", C.UI.scale >= 0.68, string.format("scale %.2f", C.UI.scale))

-- the first order reaches the screen
local ticket = Sim.waitFor(function()
	return S.Cooking.ticketsOf(plot)[1]
end, 60)
Sim.check("a customer orders", ticket ~= nil)
if not ticket then
	return
end
local recipe = Recipes.byId[ticket.recipe]
local dishName = Locale.t("rec." .. recipe.id)
Sim.check("the order is on screen", Sim.waitFor(function()
	return Sim.findText(dishName)
end, 5) ~= nil, dishName)

-- walk up to a thing and use its prompt (E / tap)
local function use(model)
	local pos = model:GetPivot().Position
	local from = pos + Vector3.new(0, 0, -3)
	p.Character:PivotTo(CFrame.lookAt(from, Vector3.new(pos.X, from.Y, pos.Z)))
	task.wait(0.6)
	return Sim.trigger(model)
end

local station
for _, e in ipairs(S.Entities.ofKind("station", plot)) do
	if e.item.fn.station == recipe.station then
		station = e
	end
end
local presses = 0
while (station.model:GetAttribute("Ready") or "") == "" and presses < 8 do
	Sim.check("the station shows its prompt", use(station.model), "press " .. (presses + 1))
	presses += 1
	Sim.waitFor(function()
		return not station.model:GetAttribute("Busy")
	end, 10)
end
Sim.check("cooked with the station's prompt", (station.model:GetAttribute("Ready") or "") == recipe.id, presses .. " presses")
use(station.model)
Sim.waitFor(function()
	return p:GetAttribute("HandsKind") == "dish"
end, 3)
Sim.check("the dish is in hand", p:GetAttribute("HandsKind") == "dish")
Sim.check("the HUD says what you hold", Sim.findText(dishName) ~= nil)
local cust = S.Entities.get(ticket.customer)
local yen = d.yen
use(cust.model)
Sim.waitFor(function()
	return d.yen > yen
end, 3)
Sim.check("served with the customer's prompt and paid", d.yen > yen, yen .. " -> " .. d.yen)

-- the shop: open it from the dock, buy the first card that can be bought
d.yen = 50000
d.level = 6
S.Data.changed(p, "yen")
S.Data.changed(p, "level")
task.wait(0.5)
local badge = p.PlayerGui.RamenUI.HUD.Dock.Shop:FindFirstChild("Badge")
Sim.check("the shop button counts what can be bought", badge ~= nil and badge.Visible)
local shopButton = p.PlayerGui.RamenUI.HUD.Dock:FindFirstChild("Shop")
Sim.check("the dock has a shop button", shopButton ~= nil)
Sim.click(shopButton)
task.wait(0.4)
Sim.check("the shop opens", C.UI.current == "Shop", tostring(C.UI.current))
local before = {}
for k, v in pairs(d.upgrades) do
	before[k] = v
end
local buy
for _, b in ipairs(p.PlayerGui.RamenUI:GetDescendants()) do
	-- green price buttons have white text (too expensive: red text, locked: a lock instead of a price)
	local c = b:IsA("TextButton") and b.TextColor3
	if b.Name == "Buy" and Sim.Gui.shown(b) and b.Text:find("¥", 1, true) and c and c.R > 0.99 and c.G > 0.99 and c.B > 0.99 then
		buy = buy or b
	end
end
Sim.check("a card can be bought", buy ~= nil)
if buy then
	Sim.click(buy)
	task.wait(0.6)
	local bought = false
	for k, v in pairs(d.upgrades) do
		if (before[k] or 0) < v then
			bought = true
		end
	end
	Sim.check("the card bought an upgrade", bought)
end
C.UI.close("Shop")
Sim.check("server closes cleanly", Sim.close())
