--!nonstrict
-- One-time tips after the tutorial, the first time something happens:
--   restock  an ingredient of the menu is running out on the shelves -> the supplier button
--   dishes   dirty dishes pile up in the sink -> the sink (done when it is empty)
--   shop     something in the shop can be bought -> the shop button
--   staff    the first member of staff can be hired -> the shop button
-- A tip is a small card above the buttons with an arrow (Pointer); it goes away after a few
-- seconds or when the thing is done, and never comes back (meta.hints, saved by the server).
-- Only one tip at a time, never during the tutorial or while a window is open.
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local NetDef = require(Shared.Net)
local Locale = require(Shared.Locale)
local TutorialCfg = require(Shared.Config.Tutorial)
local Recipes = require(Shared.Config.Recipes)
local StaffCfg = require(Shared.Config.Staff)
local Kit = require(script.Parent.Parent.UI.Kit)
local Pointer = require(script.Parent.Parent.UI.Pointer)
local Core = require(script.Parent.Parent.Core)

local Hints = {}
local player = Players.LocalPlayer
local t = Locale.t
local T = Kit.Theme
local CFG = TutorialCfg.Hints

local card, cardText, pointer
local current = nil -- { id, since }
local lastShown = -math.huge

local function dockButton(id)
	local hud = Core.C.UI.root():FindFirstChild("HUD")
	local dock = hud and hud:FindFirstChild("Dock")
	return dock and dock:FindFirstChild(id) or nil
end

local function mine(kind)
	for _, m in ipairs(CollectionService:GetTagged("Interactable")) do
		if m:GetAttribute("Kind") == kind and m:IsDescendantOf(workspace) and Core.C.Data.isMine(m) then
			return m
		end
	end
	return nil
end

-- portions on the shelves of every ingredient the dishes on the menu use
local function lowestOnMenu()
	local w = Core.C.Data.restaurant()
	local stock = {}
	for _, slots in pairs(w.shelves or {}) do
		for _, s in pairs(slots) do
			if s.g then
				stock[s.g] = (stock[s.g] or 0) + (s.n or 0)
			end
		end
	end
	local low = math.huge
	for id, m in pairs(w.menu or {}) do
		local r = Recipes.byId[id]
		if r and m.on and w.licenses and w.licenses[r.license] then
			for _, g in ipairs(r.ing) do
				low = math.min(low, stock[g] or 0)
			end
		end
	end
	return low
end

local function shopBadge()
	local b = dockButton("Shop")
	local badge = b and b:FindFirstChild("Badge")
	return badge ~= nil and badge.Visible
end

-- each tip: when it shows, where it points, when it is done
local TIPS = {
	{ id = "restock", key = "hint.first_restock", when = function()
		return lowestOnMenu() <= CFG.restock.shelfLeft
	end, gui = function()
		return dockButton("Supplier")
	end, done = function()
		return Core.C.UI.current == "Supplier"
	end },
	{ id = "dishes", key = "hint.first_dishes", when = function()
		return (Core.C.Data.plotAttr("SinkPile") or 0) >= CFG.dishes.pile
	end, world = function()
		return mine("sink")
	end, done = function()
		return (Core.C.Data.plotAttr("SinkPile") or 0) == 0
	end },
	{ id = "shop", key = "hint.first_shop", when = shopBadge, gui = function()
		return dockButton("Shop")
	end, done = function()
		return Core.C.UI.current == "Shop"
	end },
	{ id = "staff", key = "hint.first_staff", when = function()
		local w = Core.C.Data.restaurant()
		local cheapest = math.huge
		for _, s in ipairs(StaffCfg.list) do
			cheapest = math.min(cheapest, s.lv)
		end
		return (w.level or 1) >= math.max(CFG.staff.level, cheapest) and #(w.staff or {}) == 0
	end, gui = function()
		return dockButton("Shop")
	end, done = function()
		return Core.C.UI.current == "Shop"
	end },
}

local function seen(id)
	local meta = Core.C.Data.m("meta")
	return meta and meta.hints and meta.hints[id] == true
end

local function close()
	if current then
		NetDef.event("HintSeen"):FireServer(current.id)
		local meta = Core.C.Data.m("meta")
		if meta then
			meta.hints = meta.hints or {}
			meta.hints[current.id] = true
		end
	end
	current = nil
	card.Visible = false
	pointer:hide()
	lastShown = os.clock()
end

local function aim(tip)
	local g = tip.gui and tip.gui()
	local w = tip.world and tip.world()
	if g then
		pointer:gui(g)
	elseif w then
		pointer:world(w)
	else
		pointer:hide()
	end
end

local function open(tip)
	current = { id = tip.id, tip = tip, since = os.clock() }
	cardText.Text = "💡 " .. t(tip.key)
	card.Position = UDim2.new(Kit.profile == "desktop" and 0.5 or 0.57, 0, 1, -140)
	aim(tip)
	card.Visible = true
	Kit.popIn(card, 0.85)
	if Core.C.Audio then
		Core.C.Audio.play("pop")
	end
end

function Hints.Init()
	local root = Core.C.UI.root()
	-- above the dock, in the middle
	card = Kit.panel({ Name = "Hint", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -140), Size = UDim2.fromOffset(420, 0), AutomaticSize = Enum.AutomaticSize.Y, Visible = false, ZIndex = 6, Parent = root })
	local stroke = card:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Color = T.gold
		stroke.Thickness = 3
	end
	Kit.padding(14, 10).Parent = card
	cardText = Kit.label("", { Parent = card, Size = UDim2.new(1, -40, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextSize = 17, FontFace = T.bold })
	Kit.button("✕", { parent = card, size = UDim2.fromOffset(32, 32), position = UDim2.new(1, -30, 0, -4), style = "plain", textSize = 14, radius = 16, onClick = close })
	pointer = Pointer.new("#7FE0FF")
end

function Hints.Start()
	local Data = Core.C.Data
	if not Data.ready then
		Data.Ready:Wait()
	end
	while true do
		task.wait(0.5)
		local tut = Core.C.Tutorial
		local busy = (tut and tut.active and tut.active()) or Data.role() ~= "owner"
		if current then
			local tip = current.tip
			aim(tip)
			if tip.done() or os.clock() - current.since > TutorialCfg.HintSeconds then
				close()
			end
		elseif not busy and Core.C.UI.current == nil and os.clock() - lastShown > TutorialCfg.HintGap then
			for _, tip in ipairs(TIPS) do
				if not seen(tip.id) and tip.when() then
					open(tip)
					break
				end
			end
		end
	end
end

return Hints
