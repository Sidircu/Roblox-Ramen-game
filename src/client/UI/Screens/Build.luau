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

function Screen.create(root)
	local frame = Kit.panel({ Name = "BuildPanel", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -96), Size = UDim2.new(0.96, 0, 0, 250), Visible = false, Parent = root })
	refs.frame = frame
	refs.tabs = Kit.new("ScrollingFrame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(8, 6), Size = UDim2.new(1, -330, 0, 44), ScrollingDirection = Enum.ScrollingDirection.X, AutomaticCanvasSize = Enum.AutomaticSize.X, CanvasSize = UDim2.new(), ScrollBarThickness = 3, Parent = frame }, { Kit.list(Enum.FillDirection.Horizontal, 4) })
	refs.items = Kit.new("ScrollingFrame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(8, 54), Size = UDim2.new(1, -330, 1, -60), ScrollingDirection = Enum.ScrollingDirection.X, AutomaticCanvasSize = Enum.AutomaticSize.X, CanvasSize = UDim2.new(), ScrollBarThickness = 6, Parent = frame }, { Kit.list(Enum.FillDirection.Horizontal, 8) })
	local tools = Kit.new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 6), Size = UDim2.fromOffset(310, 238), Parent = frame })
	refs.tools = tools
	refs.status = Kit.label("", { Parent = tools, Size = UDim2.new(1, 0, 0, 40), TextSize = 15, FontFace = T.bold, TextYAlignment = Enum.TextYAlignment.Top })
	local gridRow = Kit.new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 42), Size = UDim2.new(1, 0, 0, 36), Parent = tools }, { Kit.list(Enum.FillDirection.Horizontal, 4) })
	refs.gridLabel = Kit.label("", { Parent = gridRow, Size = UDim2.fromOffset(70, 34), TextSize = 15, FontFace = T.bold, LayoutOrder = 0 })
	refs.gridButtons = {}
	for i, g in ipairs(GameConfig.GridSizes) do
		refs.gridButtons[g] = Kit.button(tostring(g), { parent = gridRow, size = UDim2.fromOffset(48, 34), style = "plain", order = i, onClick = function()
			Core.C.Build.setGrid(g)
		end })
	end
	Kit.button("🔄", { parent = gridRow, size = UDim2.fromOffset(48, 34), style = "dark", order = 5, onClick = function()
		Core.C.Build.rotate()
	end })
	local actRow = Kit.new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 82), Size = UDim2.new(1, 0, 0, 80), Parent = tools }, { Kit.grid(150, 36, 6) })
	refs.actions = actRow
	local bottom = Kit.new("Frame", { BackgroundTransparency = 1, Position = UDim2.new(0, 0, 1, -40), Size = UDim2.new(1, 0, 0, 38), Parent = tools }, { Kit.list(Enum.FillDirection.Horizontal, 6) })
	refs.topView = Kit.button("", { parent = bottom, size = UDim2.fromOffset(150, 36), style = "plain", order = 1, textSize = 15, onClick = function()
		Core.C.Camera.toggleTop()
		Screen.refresh()
	end })
	refs.exit = Kit.button("", { parent = bottom, size = UDim2.fromOffset(150, 36), style = "primary", order = 2, onClick = function()
		Core.C.Build.exit()
	end })
	refs.confirm = Kit.button("✓", { parent = root, size = UDim2.fromOffset(120, 60), position = UDim2.new(1, -140, 1, -420), style = "green", textSize = 30, onClick = function()
		Core.C.Build.place()
	end })
	refs.confirm.Visible = false
	Core.C.Build.Changed:Connect(function()
		if refs.frame.Visible then
			Screen.refreshTools()
		end
	end)
end

local function itemCard(item, order, opts)
	local w = Core.C.Data.world or {}
	local L = Locale.get()
	local locked, why = itemLocked(w, item)
	if opts.inventory then
		locked = false
	end
	local card = Kit.new("TextButton", { Text = "", Size = UDim2.fromOffset(132, 178), BackgroundColor3 = locked and T.paperDark or Color3.fromRGB(251, 245, 234), LayoutOrder = order, Parent = refs.items }, { Kit.corner(10), Kit.stroke(T.woodLight, 2) })
	Kit.label(Icons.forItem(item), { Parent = card, Size = UDim2.new(1, 0, 0, 56), Position = UDim2.fromOffset(0, 6), TextScaled = true, TextXAlignment = Enum.TextXAlignment.Center })
	Kit.label(t("item." .. item.id), { Parent = card, Position = UDim2.fromOffset(6, 64), Size = UDim2.new(1, -12, 0, 40), TextSize = 15, FontFace = T.bold, TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Top })
	local price
	if opts.inventory then
		price = "×" .. opts.count
	elseif item.sakura then
		price = "🌸" .. item.sakura
	else
		price = Format.yen(item.price, L)
	end
	Kit.label(price, { Parent = card, Position = UDim2.fromOffset(6, 106), Size = UDim2.new(1, -12, 0, 22), TextSize = 16, FontFace = T.title, TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = T.wood })
	local info = locked and why or ((item.amb or 0) > 0 and ("✨ " .. item.amb) or (item.fn and item.fn.comfort and ("🪑 " .. item.fn.comfort) or ""))
	Kit.label(info or "", { Parent = card, Position = UDim2.fromOffset(6, 130), Size = UDim2.new(1, -12, 0, 40), TextSize = 13, TextColor3 = T.muted, TextXAlignment = Enum.TextXAlignment.Center })
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
	local w = Core.C.Data.world or {}
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
		local current = (w.surfaces and w.surfaces[zone.id]) or {}
		for _, s in ipairs(Surfaces.list) do
			local active = current[s.kind] == s.id or (not current[s.kind] and (s.id == (s.kind == "floor" and (zone.floorStyle or Surfaces.DefaultFloor) or (zone.wallStyle or Surfaces.DefaultWall))))
			local locked = (w.level or 1) < s.lv
			local card = Kit.new("TextButton", { Text = "", Size = UDim2.fromOffset(132, 178), BackgroundColor3 = T.paper, LayoutOrder = s.order, Parent = refs.items }, { Kit.corner(10), Kit.stroke(active and T.gold or T.woodLight, active and 4 or 2) })
			local swatch = Kit.new("Frame", { BackgroundColor3 = require(Shared.Util.Color).hex(s.color), Size = UDim2.new(1, -20, 0, 56), Position = UDim2.fromOffset(10, 10), Parent = card }, { Kit.corner(8) })
			local _ = swatch
			Kit.label((s.kind == "floor" and "⬜ " or "🧱 ") .. t("surf." .. s.id), { Parent = card, Position = UDim2.fromOffset(6, 70), Size = UDim2.new(1, -12, 0, 40), TextSize = 14, FontFace = T.bold, TextXAlignment = Enum.TextXAlignment.Center })
			Kit.label(s.price > 0 and Format.yen(s.price, L) or t("ui.free"), { Parent = card, Position = UDim2.fromOffset(6, 112), Size = UDim2.new(1, -12, 0, 22), TextSize = 16, FontFace = T.title, TextXAlignment = Enum.TextXAlignment.Center })
			Kit.label(locked and t("ui.req_level", { level = s.lv }) or ("✨ " .. math.floor(s.amb)), { Parent = card, Position = UDim2.fromOffset(6, 136), Size = UDim2.new(1, -12, 0, 30), TextSize = 13, TextColor3 = T.muted, TextXAlignment = Enum.TextXAlignment.Center })
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
		local b = Kit.button(tb.label, { parent = refs.tabs, size = UDim2.fromOffset(128, 38), style = tb.id == category and "primary" or "plain", order = i, textSize = 14, onClick = function()
			category = tb.id
			Screen.refresh()
		end })
		local _ = b
	end
end

function Screen.refreshTools()
	local Build = Core.C.Build
	local L = Locale.get()
	refs.gridLabel.Text = t("ui.grid")
	for g, b in pairs(refs.gridButtons) do
		b.BackgroundColor3 = (Build.grid == g) and T.red or T.paperDark
		b.TextColor3 = (Build.grid == g) and T.white or T.ink
	end
	refs.topView.Text = Core.C.Camera.top and ("🎥 " .. t("ui.normal_view")) or ("🗺️ " .. t("ui.top_view"))
	refs.exit.Text = "✕ " .. t("ui.exit_build")
	if Build.itemId then
		local status = Build.valid and ("✅ " .. t("ui.can_place")) or ("❌ " .. t(Build.reason or "msg.place_invalid"))
		refs.status.Text = t("item." .. Build.itemId) .. "\n" .. status
		refs.status.TextColor3 = Build.valid and T.green or T.red
	elseif Build.selected then
		local entry = nil
		for _, e in ipairs(Core.C.Data.w("placed") or {}) do
			if e.u == Build.selected then
				entry = e
			end
		end
		refs.status.Text = entry and t("item." .. entry.i) or ""
		refs.status.TextColor3 = T.ink
	else
		refs.status.Text = t("ui.build_hint")
		refs.status.TextColor3 = T.muted
	end
	Kit.clear(refs.actions)
	if Build.selected and not Build.itemId then
		local entry = nil
		for _, e in ipairs(Core.C.Data.w("placed") or {}) do
			if e.u == Build.selected then
				entry = e
			end
		end
		local item = entry and Items.byId[entry.i]
		Kit.button("✋ " .. t("ui.move"), { parent = refs.actions, style = "dark", order = 1, textSize = 15, onClick = function()
			Build.startMove(Build.selected)
		end })
		Kit.button("🔄 " .. t("ui.rotate"), { parent = refs.actions, style = "dark", order = 2, textSize = 15, onClick = function()
			Build.rotate()
		end })
		Kit.button("🎒 " .. t("ui.store"), { parent = refs.actions, style = "plain", order = 3, textSize = 15, onClick = function()
			Build.removeSelected("store")
		end })
		local refund = item and math.floor((entry.paid or item.price) * GameConfig.SellRefund) or 0
		Kit.button("💴 " .. t("ui.sell") .. " " .. Format.yen(refund, L), { parent = refs.actions, style = "primary", order = 4, textSize = 14, onClick = function()
			Build.removeSelected("sell")
		end })
	elseif Build.itemId then
		Kit.button("✕ " .. t("ui.cancel"), { parent = refs.actions, style = "plain", order = 1, textSize = 15, onClick = function()
			Build.cancel()
		end })
	end
	refs.confirm.Visible = Build.itemId ~= nil and UserInputService.TouchEnabled
end

function Screen.refresh()
	if not refs.frame or not refs.frame.Visible then
		return
	end
	renderTabs()
	renderItems()
	Screen.refreshTools()
end

function Screen.visible()
	return refs.frame and refs.frame.Visible
end

function Screen.open()
	refs.frame.Visible = true
	Screen.refresh()
end

function Screen.close()
	refs.frame.Visible = false
	refs.confirm.Visible = false
end

return Screen
