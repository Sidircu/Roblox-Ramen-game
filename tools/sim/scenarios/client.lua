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

-- walk up to a thing and tap the big button over it (our look for its prompt), like a phone player
local tapped = 0
local function use(model)
	local pos = model:GetPivot().Position
	local from = pos + Vector3.new(0, 0, -3)
	p.Character:PivotTo(CFrame.lookAt(from, Vector3.new(pos.X, from.Y, pos.Z)))
	task.wait(0.6)
	local gui = p.PlayerGui:FindFirstChild("UseButton")
	if gui and gui.Enabled and gui.Adornee and gui.Adornee:IsDescendantOf(model) then
		tapped += 1
		Sim.click(gui.Use)
		return true
	end
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
local useGui = p.PlayerGui:FindFirstChild("UseButton")
Sim.check("a big button over the station, tapped on the phone (no key on it)", tapped >= 1 and useGui ~= nil and useGui.Size.Y.Offset >= 64 and useGui.Use.Key.Visible == false, tapped .. " taps")
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

-- the "for sale" sign of the east dining room: one press builds it
local CS = game:GetService("CollectionService")
local function signFor(id)
	for _, m in ipairs(CS:GetTagged("ForSale")) do
		if m:GetAttribute("Expansion") == id and m:GetAttribute("PlotId") == plot.id then
			return m
		end
	end
	return nil
end
local sign = signFor("zone_east")
Sim.check("a for-sale sign stands where the east room goes", sign ~= nil)
if sign then
	task.wait(1.2)
	local label = sign.PrimaryPart:FindFirstChild("Front"):FindFirstChildOfClass("TextLabel")
	Sim.check("the sign shows the room and its price", label and label.Text:find("¥", 1, true) ~= nil, label and label.Text)
	use(sign)
	Sim.waitFor(function()
		return d.zones.zone_east == true
	end, 6)
	Sim.check("using the sign builds the room", d.zones.zone_east == true)
	task.wait(3) -- the builders take a moment, then the restaurant is built again
	Sim.check("the sign is gone and the next room has one", signFor("zone_east") == nil and signFor("zone_west") ~= nil)
end
-- the LED OPEN / CLOSED sign by the door: using it closes the restaurant (no new customers), the
-- sign and the clock say so, using it again opens it
local openSign = nil
for _, m in ipairs(CS:GetTagged("Interactable")) do
	if m:GetAttribute("Kind") == "opensign" and m:GetAttribute("PlotId") == plot.id then
		openSign = m
	end
end
Sim.check("an OPEN sign stands by the door", openSign ~= nil and openSign.PrimaryPart.Front.Label.Text == "OPEN")
if openSign then
	use(openSign)
	Sim.waitFor(function()
		return plot.closed == true
	end, 5)
	Sim.check("using the sign closes the restaurant", plot.closed == true and plot.folder:GetAttribute("Open") == false)
	Sim.check("the sign says CLOSED", openSign.PrimaryPart.Front.Label.Text == "CLOSED")
	task.wait(1.5)
	Sim.check("the clock says closed", Sim.findText(Locale.t("ui.closed")) ~= nil)
	local before = {}
	for _, e in ipairs(S.Entities.ofKind("customer", plot)) do
		before[e.model] = true
	end
	task.wait(30)
	local newcomers = 0
	for _, e in ipairs(S.Entities.ofKind("customer", plot)) do
		if not before[e.model] then
			newcomers += 1
		end
	end
	Sim.check("nobody new comes in while closed", newcomers == 0, newcomers .. " new customers")
	use(openSign)
	Sim.waitFor(function()
		return plot.closed == false
	end, 5)
	Sim.check("using it again opens the restaurant", plot.closed == false and openSign.PrimaryPart.Front.Label.Text == "OPEN")
	local stranger = Sim.addPlayer({ name = "Stranger" })
	Sim.waitFor(function()
		return S.Data.get(stranger) and stranger.Character and S.Plots.ofPlayer(stranger)
	end, 30)
	task.wait(1)
	stranger.Character:PivotTo(openSign.PrimaryPart.CFrame * CFrame.new(0, -3, -3))
	task.wait(1) -- (now a helper in this restaurant: helpers cook and serve, they do not close it)
	Sim.check("the other player now works here", S.Plots.of(stranger) == plot)
	Sim.fire(stranger, "ToggleOpen")
	task.wait(0.5)
	Sim.check("only the owner may close it", plot.closed == false)
end

-- a delivery: the van parks a little before the loading bay, a pop-up with a sound says it is
-- here, the boxes land on the ground just outside the storage door and a second pop-up says so
local Expansions = Sim.shared("Config.Expansions")
local boxesBefore = #d.storage
local function popupSays(key, params)
	local holder = p.PlayerGui.RamenUI:FindFirstChild("Toasts")
	local want = Locale.t(key, params)
	for _, f in ipairs(holder and holder:GetChildren() or {}) do
		local title = f.Name == "Popup" and f:FindFirstChild("Title")
		if title and title.Text == want then
			return true
		end
	end
	return false
end
d.yen += 2000
Sim.fire(p, "OrderSupplies", { noodles = { small = 1 } })
Sim.check("a pop-up says the van is here", Sim.waitFor(function()
	return popupSays("ui.delivery_here")
end, 20) ~= nil)
Sim.check("a pop-up says the boxes are down", Sim.waitFor(function()
	return popupSays("ui.delivery_done_one")
end, 10) ~= nil)
local dz = Expansions.DropZone
local landed = nil
for i = boxesBefore + 1, #d.storage do
	local b = d.storage[i]
	if b.g == "noodles" and b.px then
		landed = b
	end
end
Sim.check("the box is on the ground just outside the storage door", landed ~= nil and landed.px >= dz.x0 and landed.px <= dz.x1 and landed.pz >= dz.z0 and landed.pz <= dz.z1 and landed.pz < 24,
	landed and string.format("%.1f, %.1f", landed.px, landed.pz) or "no box")
Sim.snapshot("delivery_popup")

-- keyboard shortcuts: O opens the supplier although Roblox's camera zooms with it
if C.UI.current then
	C.UI.close(C.UI.current)
end
Sim.press(Enum.KeyCode.O)
Sim.check("O opens the supplier", C.UI.current == "Supplier", tostring(C.UI.current))
Sim.press(Enum.KeyCode.O)
Sim.check("O again closes it", C.UI.current == nil, tostring(C.UI.current))
-- when Roblox's camera keeps the press of O entirely, the release opens and closes it
Sim.cameraKeepsIOPress = true
Sim.press(Enum.KeyCode.O)
Sim.check("O opens the supplier on release when the camera keeps the press", C.UI.current == "Supplier", tostring(C.UI.current))
Sim.press(Enum.KeyCode.O)
Sim.check("and closes it the same way", C.UI.current == nil, tostring(C.UI.current))
Sim.cameraKeepsIOPress = false
-- a long press opens it once
Sim.press(Enum.KeyCode.O, 1.2)
Sim.check("holding O opens it once", C.UI.current == "Supplier", tostring(C.UI.current))
C.UI.close("Supplier")
Sim.press(Enum.KeyCode.U)
Sim.check("U opens the shop", C.UI.current == "Shop", tostring(C.UI.current))
C.UI.close("Shop")

-- three dishes on the tray in first person: the stack goes down so the crosshair stays clear
Sim.fire(p, "SetSetting", "cam", "first")
task.wait(1.5)
Sim.check("first person can be chosen on a phone", C.Camera.isFirstPerson())
if C.Camera.isFirstPerson() then
	S.Hands.set(p, "dish", { { recipe = "shoyu_ramen" }, { recipe = "shoyu_ramen" }, { recipe = "shoyu_ramen" } }, plot)
	task.wait(0.5)
	local cam = workspace.CurrentCamera
	local top, n = -math.huge, 0
	for _, m in ipairs(cam:GetChildren()) do
		if m:IsA("Model") and m.Name == "Dish" then
			n += 1
			-- the highest corner of every part, measured along the camera's up direction
			for _, part in ipairs(m:GetDescendants()) do
				if part:IsA("BasePart") then
					local c = cam.CFrame:ToObjectSpace(part.CFrame)
					local half = math.abs(c.XVector.Y) * part.Size.X / 2 + math.abs(c.YVector.Y) * part.Size.Y / 2 + math.abs(c.ZVector.Y) * part.Size.Z / 2
					top = math.max(top, c.Position.Y + half)
				end
			end
		end
	end
	Sim.check("three dishes in view under the crosshair", n == 3 and top < -0.3, n .. " copies, top " .. string.format("%.2f", top))
	S.Hands.clear(p)
end
Sim.check("server closes cleanly", Sim.close())
