--!nonstrict
-- Build panel: catalog by category, inventory, floor/wall styles, grid & rotation tools,
-- selection actions (move / rotate / store / sell).
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local NetDef = require(Shared.Net)
local Locale = require(Shared.Locale)
local Format = require(Shared.Util.Format)
local Items = require(Shared.Config.Items)
local Surfaces = require(Shared.Config.Surfaces)
local Events = require(Shared.Config.Events)
local GameConfig = require(Shared.Config.GameConfig)
local Footprint = require(Shared.Logic.Footprint)
local Kit = require(script.Parent.Parent.Kit)
local Icons = require(script.Parent.Parent.Icons)
local Thumbs = require(script.Parent.Parent.Thumbs)
local Core = require(script.Parent.Parent.Parent.Core)

local Screen = { modal = false }
local T = Kit.Theme
local t = Locale.t
local refs = {}
local category = "seating"

local function visibleItem(w, item)
	if item.event then
		local ev = Events.active(workspace:GetServerTimeNow())
		return ev and ev.id == item.event
	end
	if item.franchise then
		return w.franchise and w.franchise.cities and w.franchise.cities[item.franchise]
	end
	return true
end

local function itemLocked(w, item)
	if (w.level or 1) < (item.lv or 1) then
		return true, t("ui.req_level", { level = item.lv })
	end
	if item.license and not (w.licenses and w.licenses[item.license]) then
		return true, "🔒 " .. t("lic." .. item.license)
	end
	return false
end

local function zoneHere()
	local char = Players.LocalPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return nil
	end
	local geo = Core.C.Build.geometry()
	local f = math.floor((hrp.Position.Y + 2) / GameConfig.FloorHeight)
	for _, z in ipairs(geo.zones) do
		if z.floor == f and not z.outdoor and Footprint.pointInRect(hrp.Position.X, hrp.Position.Z, z.rect) then
			return z
		end
	end
	return nil
end

-- Compact layout: a short catalog drawer at the bottom while browsing; while an object is being
-- placed or is selected the drawer hides and a small action bar takes its place.
function Screen.create(root)
	local frame = Kit.panel({ Name = "BuildPanel", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -8), Size = UDim2.new(0.94, 0, 0, 178), Visible = false, Parent = root })
	refs.frame = frame
	refs.tabs = Kit.new("ScrollingFrame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(8, 6), Size = UDim2.new(1, -16, 0, 36), ScrollingDirection = Enum.ScrollingDirection.X, AutomaticCanvasSize = Enum.AutomaticSize.X, CanvasSize = UDim2.new(), ScrollBarThickness = 3, Parent = frame }, { Kit.list(Enum.FillDirection.Horizontal, 4) })
	refs.items = Kit.new("ScrollingFrame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(8, 46), Size = UDim2.new(1, -16, 1, -52), ScrollingDirection = Enum.ScrollingDirection.X, AutomaticCanvasSize = Enum.AutomaticSize.X, CanvasSize = UDim2.new(), ScrollBarThickness = 5, Parent = frame }, { Kit.list(Enum.FillDirection.Horizontal, 6) })
	-- floating toolbar (right): grid, top view, exit
	local tools = Kit.new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -10, 1, -196), Size = UDim2.fromOffset(150, 132), Visible = false, Parent = root }, { Kit.list(Enum.FillDirection.Vertical, 6, Enum.HorizontalAlignment.Right) })
	refs.tools = tools
	refs.gridButton = Kit.button("", { parent = tools, size = UDim2.fromOffset(150, 38), style = "plain", order = 1, textSize = 14, radius = 19, onClick = function()
		Core.C.Build.cycleGrid()
	end })
	refs.topView = Kit.button("", { parent = tools, size = UDim2.fromOffset(150, 38), style = "plain", order = 2, textSize = 14, radius = 19, onClick = function()
		Core.C.Camera.toggleTop()
		Screen.refreshTools()
	end })
	refs.exit = Kit.button("", { parent = tools, size = UDim2.fromOffset(150, 38), style = "close", order = 3, textSize = 14, radius = 19, onClick = function()
		Core.C.Build.exit()
	end })
	-- action bar (bottom-centre) used while placing or with a selected object
	local bar = Kit.panel({ AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -12), Size = UDim2.fromOffset(560, 92), Visible = false, Parent = root })
	refs.bar = bar
	refs.status = Kit.label("", { Parent = bar, Position = UDim2.fromOffset(14, 6), Size = UDim2.new(1, -28, 0, 22), TextSize = 16, FontFace = T.bold, TextTruncate = Enum.TextTruncate.AtEnd })
	refs.howto = Kit.label("", { Parent = bar, Position = UDim2.fromOffset(14, 28), Size = UDim2.new(1, -28, 0, 18), TextSize = 13, TextColor3 = T.muted, TextTruncate = Enum.TextTruncate.AtEnd })
	refs.actions = Kit.new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 50), Size = UDim2.new(1, -20, 0, 36), Parent = bar }, { Kit.list(Enum.FillDirection.Horizontal, 6, Enum.HorizontalAlignment.Center) })
	Core.C.Build.Changed:Connect(function()
		if refs.frame.Visible or refs.bar.Visible then
			Screen.refreshTools()
		end
	end)
end

local function itemCard(item, order, opts)
	local w = Core.C.Data.restaurant()
	local L = Locale.get()
	local locked, why = itemLocked(w, item)
	if opts.inventory then
		locked = false
	end
	local card = Kit.new("TextButton", { Text = "", Size = UDim2.fromOffset(104, 118), BackgroundColor3 = locked and T.paperDark or Color3.fromRGB(251, 245, 234), LayoutOrder = order, Parent = refs.items }, { Kit.corner(10), Kit.stroke(T.woodLight, 2) })
	-- the real object in 3D (the emoji shows until it is ready, or with low graphics)
	local icon = Kit.label(Icons.forItem(item), { Parent = card, Size = UDim2.new(1, 0, 0, 36), Position = UDim2.fromOffset(0, 4), TextScaled = true, TextXAlignment = Enum.TextXAlignment.Center })
	Thumbs.later(card, "item", item.id, { Size = UDim2.new(1, -8, 0, 42), Position = UDim2.fromOffset(4, 1), transparency = locked and 0.45 or 0 }, icon)
	Kit.label(t("item." .. item.id), { Parent = card, Position = UDim2.fromOffset(4, 43), Size = UDim2.new(1, -8, 0, 30), TextSize = 12, FontFace = T.bold, TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true })
	local price
	if opts.inventory then
		price = "×" .. opts.count
	elseif item.sakura then
		price = "🌸" .. item.sakura
	else
		price = Format.yen(item.price, L)
	end
	Kit.label(price, { Parent = card, Position = UDim2.fromOffset(4, 74), Size = UDim2.new(1, -8, 0, 18), TextSize = 14, FontFace = T.title, TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = T.wood })
	local info = locked and why or ((item.amb or 0) > 0 and ("✨ " .. item.amb) or (item.fn and item.fn.comfort and ("🪑 " .. item.fn.comfort) or ""))
	Kit.label(info or "", { Parent = card, Position = UDim2.fromOffset(4, 94), Size = UDim2.new(1, -8, 0, 18), TextSize = 11, TextColor3 = T.muted, TextXAlignment = Enum.TextXAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd })
	card.MouseButton1Click:Connect(function()
		if locked then
			Core.C.UI.toast(why or "", "error")
			return
		end
		Core.C.Build.startPlace(item.id, opts.inventory == true)
	end)
	return card
end

local function renderItems()
	Kit.clear(refs.items)
	local w = Core.C.Data.restaurant()
	local L = Locale.get()
	if category == "inventory" then
		local inv = w.inventory or {}
		local order = 0
		for _, item in ipairs(Items.list) do
			local n = inv[item.id] or 0
			if n > 0 then
				order += 1
				itemCard(item, order, { inventory = true, count = n })
			end
		end
		if order == 0 then
			Kit.label(t("ui.inventory_empty"), { Parent = refs.items, Size = UDim2.fromOffset(400, 60), TextSize = 17 })
		end
	elseif category == "surfaces" then
		local zone = zoneHere()
		if not zone then
			Kit.label(t("ui.stand_in_zone"), { Parent = refs.items, Size = UDim2.fromOffset(420, 60), TextSize = 17 })
			return
		end
		Kit.label("📍 " .. t("ui.room", { name = "zone." .. zone.id }), { Parent = refs.items, Size = UDim2.fromOffset(120, 118), TextSize = 14, FontFace = T.bold, LayoutOrder = 0, TextWrapped = true })
		local current = (w.surfaces and w.surfaces[zone.id]) or {}
		for _, s in ipairs(Surfaces.list) do
			local active = current[s.kind] == s.id or (not current[s.kind] and (s.id == (s.kind == "floor" and (zone.floorStyle or Surfaces.DefaultFloor) or (zone.wallStyle or Surfaces.DefaultWall))))
			local locked = (w.level or 1) < s.lv
			local card = Kit.new("TextButton", { Text = "", Size = UDim2.fromOffset(104, 118), BackgroundColor3 = T.paper, LayoutOrder = s.order, Parent = refs.items }, { Kit.corner(10), Kit.stroke(active and T.gold or T.woodLight, active and 4 or 2) })
			local swatch = Kit.new("Frame", { BackgroundColor3 = require(Shared.Util.Color).hex(s.color), Size = UDim2.new(1, -16, 0, 34), Position = UDim2.fromOffset(8, 6), Parent = card }, { Kit.corner(8) })
			local _ = swatch
			Kit.label((s.kind == "floor" and "⬜ " or "🧱 ") .. t("surf." .. s.id), { Parent = card, Position = UDim2.fromOffset(4, 42), Size = UDim2.new(1, -8, 0, 30), TextSize = 12, FontFace = T.bold, TextXAlignment = Enum.TextXAlignment.Center, TextWrapped = true })
			Kit.label(s.price > 0 and Format.yen(s.price, L) or t("ui.free"), { Parent = card, Position = UDim2.fromOffset(4, 74), Size = UDim2.new(1, -8, 0, 18), TextSize = 14, FontFace = T.title, TextXAlignment = Enum.TextXAlignment.Center })
			Kit.label(locked and t("ui.req_level", { level = s.lv }) or ("✨ " .. math.floor(s.amb)), { Parent = card, Position = UDim2.fromOffset(4, 94), Size = UDim2.new(1, -8, 0, 18), TextSize = 11, TextColor3 = T.muted, TextXAlignment = Enum.TextXAlignment.Center })
			card.MouseButton1Click:Connect(function()
				if not locked then
					NetDef.event("PaintSurface"):FireServer(zone.id, s.kind, s.id)
				end
			end)
		end
	else
		local order = 0
		for _, item in ipairs(Items.list) do
			if item.cat == category and visibleItem(w, item) then
				order += 1
				itemCard(item, item.order, {})
			end
		end
	end
end

local function renderTabs()
	Kit.clear(refs.tabs)
	local tabs = {}
	for _, c in ipairs(Items.Categories) do
		table.insert(tabs, { id = c, label = (Icons.cat[c] or "") .. " " .. t("cat." .. c) })
	end
	table.insert(tabs, { id = "surfaces", label = "🎨 " .. t("ui.surfaces") })
	table.insert(tabs, { id = "inventory", label = "🎒 " .. t("ui.inventory") })
	for i, tb in ipairs(tabs) do
		local b = Kit.button(tb.label, { parent = refs.tabs, size = UDim2.fromOffset(118, 32), style = tb.id == category and "selected" or "secondary", order = i, textSize = 13, radius = 16, onClick = function()
			category = tb.id
			Screen.refresh()
		end })
		local _ = b
	end
end

local function selectedEntry()
	local Build = Core.C.Build
	for _, e in ipairs(Core.C.Data.w("placed") or {}) do
		if e.u == Build.selected then
			return e
		end
	end
	return nil
end

function Screen.refreshTools()
	local Build = Core.C.Build
	local L = Locale.get()
	local touch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	refs.gridButton.Text = "▦ " .. t("ui.grid") .. " " .. tostring(Build.grid)
	refs.topView.Text = Core.C.Camera.top and ("🎥 " .. t("ui.normal_view")) or ("🗺️ " .. t("ui.top_view"))
	refs.exit.Text = "✕ " .. t("ui.exit_build")
	local placing = Build.itemId ~= nil
	local entry = (not placing) and Build.selected and selectedEntry() or nil
	-- the catalog hides while something is being placed or is selected
	local active = refs.frame.Visible or refs.bar.Visible
	refs.frame.Visible = active and not placing and entry == nil
	refs.bar.Visible = active and (placing or entry ~= nil)
	refs.tools.Visible = active
	-- the catalog covers the bottom of the screen: no thumbstick over it (walking is back while
	-- an object is being placed)
	Core.C.UI.blockTouch("catalog", refs.frame.Visible)
	Kit.clear(refs.actions)
	if placing then
		local status = Build.valid and ("✅ " .. t("ui.can_place")) or ("❌ " .. t(Build.reason or "msg.place_invalid"))
		refs.status.Text = t("item." .. Build.itemId) .. "   " .. status
		refs.status.TextColor3 = Build.valid and T.green or T.red
		refs.howto.Text = touch and t("ui.place_howto_touch") or t("ui.place_howto_pc")
		Kit.button("🔄 " .. t("ui.rotate"), { parent = refs.actions, size = UDim2.fromOffset(130, 34), style = "secondary", order = 1, textSize = 14, radius = 17, onClick = function()
			Build.rotate()
		end })
		Kit.button("✔ " .. t("ui.place"), { parent = refs.actions, size = UDim2.fromOffset(150, 34), style = Build.valid and "green" or "plain", order = 2, textSize = 15, radius = 17, onClick = function()
			Build.place()
		end })
		Kit.button("✕ " .. t("ui.cancel"), { parent = refs.actions, size = UDim2.fromOffset(130, 34), style = "close", order = 3, textSize = 14, radius = 17, onClick = function()
			Build.cancel()
		end })
	elseif entry then
		local item = Items.byId[entry.i]
		refs.status.Text = t("item." .. entry.i)
		refs.status.TextColor3 = T.ink
		refs.howto.Text = t("ui.selected_howto")
		Kit.button("✋ " .. t("ui.move"), { parent = refs.actions, size = UDim2.fromOffset(110, 34), style = "secondary", order = 1, textSize = 14, radius = 17, onClick = function()
			Build.startMove(Build.selected)
		end })
		Kit.button("🔄 " .. t("ui.rotate"), { parent = refs.actions, size = UDim2.fromOffset(100, 34), style = "secondary", order = 2, textSize = 14, radius = 17, onClick = function()
			Build.rotate()
		end })
		Kit.button("🎒 " .. t("ui.store"), { parent = refs.actions, size = UDim2.fromOffset(110, 34), style = "plain", order = 3, textSize = 14, radius = 17, onClick = function()
			Build.removeSelected("store")
		end })
		local refund = item and math.floor((entry.paid or item.price) * GameConfig.SellRefund) or 0
		Kit.button("💴 " .. Format.yen(refund, L), { parent = refs.actions, size = UDim2.fromOffset(110, 34), style = "close", order = 4, textSize = 14, radius = 17, onClick = function()
			Build.removeSelected("sell")
		end })
		Kit.button("✕", { parent = refs.actions, size = UDim2.fromOffset(44, 34), style = "close", order = 5, textSize = 14, radius = 17, onClick = function()
			Build.select(nil)
		end })
	end
end

function Screen.refresh()
	if not refs.frame or not (refs.frame.Visible or refs.bar.Visible) then
		return
	end
	renderTabs()
	renderItems()
	Screen.refreshTools()
end

function Screen.visible()
	return refs.frame and (refs.frame.Visible or refs.bar.Visible)
end

function Screen.open()
	refs.frame.Visible = true
	refs.tools.Visible = true
	Screen.refresh()
	local hud = Core.C.UI.screens.HUD
	if hud and hud.setBuilding then
		hud.setBuilding(true)
	end
end

function Screen.close()
	refs.frame.Visible = false
	refs.bar.Visible = false
	refs.tools.Visible = false
	Core.C.UI.blockTouch("catalog", false)
	local hud = Core.C.UI.screens.HUD
	if hud and hud.setBuilding then
		hud.setBuilding(false)
	end
end

return Screen
