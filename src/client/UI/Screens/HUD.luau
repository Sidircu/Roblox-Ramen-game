--!nonstrict
-- Always-visible HUD, as little as possible:
--   top-left    wallet: yen, sakura, level badge and XP bar; under it the free gift timer
--   top-centre  clock and day (tap: last day's summary), today's objective under it
--   top-right   the restaurant you stand in (rating and likes; someone else's: like / go home),
--               a dishes chip when there is washing to do, then the orders (oldest first)
--   bottom      what you hold, and four big buttons: shop, build, supplier, more (the phone)
-- On phones the buttons sit in the middle of the bottom edge, clear of the thumbstick (bottom-
-- left) and of the jump button (bottom-right); fewer orders are listed.
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local NetDef = require(Shared.Net)
local Locale = require(Shared.Locale)
local Format = require(Shared.Util.Format)
local Formulas = require(Shared.Logic.Formulas)
local ShopLogic = require(Shared.Logic.Shop)
local Recipes = require(Shared.Config.Recipes)
local Ingredients = require(Shared.Config.Ingredients)
local Upgrades = require(Shared.Config.Upgrades)
local Licenses = require(Shared.Config.Licenses)
local Expansions = require(Shared.Config.Expansions)
local StaffCfg = require(Shared.Config.Staff)
local Ads = require(Shared.Config.Ads)
local GameConfig = require(Shared.Config.GameConfig)
local Kit = require(script.Parent.Parent.Kit)
local Core = require(script.Parent.Parent.Parent.Core)

local HUD = { modal = false }
local T = Kit.Theme
local t = Locale.t
local refs = {}
local player = Players.LocalPlayer
local SHOP_CFG = { Upgrades = Upgrades, Ads = Ads, Licenses = Licenses, Expansions = Expansions, Staff = StaffCfg, MaxStaff = GameConfig.MaxStaff }

-- the four big buttons (keyboard shortcuts in Controllers/FirstPerson)
local BUTTONS = {
	{ id = "Shop", icon = "🛒", key = "ui.shop", build = true, hotkey = "U" },
	{ id = "Build", icon = "🔨", key = "ui.build", build = true, hotkey = "B" },
	{ id = "Supplier", icon = "📦", key = "ui.supplier", build = true, hotkey = "O" },
	{ id = "Phone", icon = "📱", key = "ui.more", hotkey = "P" },
}

-- sizes per kind of screen (units, see Controllers/UI)
-- (dockX: centre of the dock as a fraction of the width; on touch screens it sits right of the
-- middle, past the thumbstick area, which covers the left 40% of the screen)
local LAYOUT = {
	phone = { dockW = 82, dockH = 62, dockX = 0.57, tickets = 3, ticketW = 214, ticketH = 58 },
	tablet = { dockW = 86, dockH = 70, dockX = 0.56, tickets = 4, ticketW = 236, ticketH = 62 },
	desktop = { dockW = 86, dockH = 70, dockX = 0.5, tickets = 5, ticketW = 236, ticketH = 62 },
}

local function L()
	return LAYOUT[Kit.profile] or LAYOUT.desktop
end

local function lang()
	return Locale.get()
end

local function keyboard()
	return UserInputService.KeyboardEnabled
end

local function open(id)
	if id == "Build" then
		Core.C.Build.toggle()
		return
	end
	Core.C.UI.toggle(id)
end

-- small rounded pill (a frame, or a button when onClick is given)
local function pill(props, onClick)
	local f = Kit.new(onClick and "TextButton" or "Frame", props, { Kit.corner(18), Kit.stroke(T.wood, 2, 0.2), Kit.sheen(0.92) })
	f.BackgroundColor3 = props.BackgroundColor3 or T.paper
	if onClick then
		f.Text = ""
		f.AutoButtonColor = true
		Kit.press(f)
		f.MouseButton1Click:Connect(function()
			if Core.C.Audio then
				Core.C.Audio.play("ui")
			end
			onClick()
		end)
	end
	return f
end

local function pillLabel(parent, size, props)
	local base = { Parent = parent, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -24, 1, 0), TextSize = size or 16, FontFace = T.bold, TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd, TextWrapped = false }
	for k, v in pairs(props or {}) do
		base[k] = v
	end
	return Kit.label("", base)
end

function HUD.create(root)
	local top = Kit.new("Frame", { Name = "HUD", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = root })
	HUD.frame = top

	-- wallet: yen and sakura on top, level badge and XP bar under them
	local wallet = pill({ Name = "Wallet", Size = UDim2.fromOffset(258, 66), Position = UDim2.fromOffset(10, 8), Parent = top })
	refs.wallet = wallet
	refs.yen = Kit.label("¥0", { Parent = wallet, Position = UDim2.fromOffset(14, 4), Size = UDim2.new(1, -110, 0, 32), TextSize = 27, FontFace = T.title, TextColor3 = T.wood, TextWrapped = false, TextYAlignment = Enum.TextYAlignment.Center })
	refs.sakura = Kit.label("🌸0", { Parent = wallet, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 8), Size = UDim2.fromOffset(92, 24), TextSize = 17, FontFace = T.bold, TextXAlignment = Enum.TextXAlignment.Right, TextWrapped = false })
	local badge = Kit.new("Frame", { Name = "Level", Position = UDim2.fromOffset(10, 36), Size = UDim2.fromOffset(26, 26), BackgroundColor3 = T.gold, Parent = wallet }, { Kit.corner(13), Kit.stroke(T.wood, 2, 0.1) })
	refs.levelBadge = badge
	refs.level = Kit.label("1", { Parent = badge, Size = UDim2.fromScale(1, 1), TextSize = 15, FontFace = T.bold, TextColor3 = T.ink, TextXAlignment = Enum.TextXAlignment.Center, TextWrapped = false })
	local bar, fill = Kit.bar(0, T.gold, { Parent = wallet, Position = UDim2.fromOffset(42, 42), Size = UDim2.new(1, -56, 0, 14) })
	refs.xpFill = fill
	refs.xpText = Kit.label("", { Parent = bar, Size = UDim2.fromScale(1, 1), TextSize = 11, FontFace = T.bold, TextColor3 = T.wood, TextXAlignment = Enum.TextXAlignment.Center, TextWrapped = false, ZIndex = 2 })

	-- free gift for minutes played (Screens/Gifts): countdown, then "claim!"
	refs.gift = pill({ Name = "Gift", Position = UDim2.fromOffset(10, 82), Size = UDim2.fromOffset(150, 34), Visible = false, Parent = top }, function()
		Core.C.UI.toggle("Gifts")
	end)
	refs.giftLabel = pillLabel(refs.gift, 16)

	-- clock and day (tap: the summary of the last day)
	refs.day = pill({ Name = "Clock", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 8), Size = UDim2.fromOffset(214, 36), Parent = top }, function()
		local report = Core.C.Data.day and Core.C.Data.day.report
		if report then
			Core.C.UI.open("DayReport", report)
		end
	end)
	refs.clock = pillLabel(refs.day, 17)

	-- today's objective (first daily quest not claimed yet): tap to claim it or see all of them
	refs.goal = pill({ Name = "Goal", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 50), Size = UDim2.fromOffset(360, 32), Visible = false, Parent = top }, function()
		local q = HUD.currentGoal and HUD.currentGoal()
		if q and q.progress >= q.target then
			NetDef.event("ClaimQuest"):FireServer(q.id)
		else
			Core.C.UI.toggle("Goals")
		end
	end)
	refs.goalLabel = pillLabel(refs.goal, 15)

	-- the restaurant you stand in (top-right)
	refs.place = pill({ Name = "Place", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 8), Size = UDim2.fromOffset(176, 36), Parent = top })
	refs.placeLabel = pillLabel(refs.place, 16)
	refs.visit = Kit.new("Frame", { Name = "Visit", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 50), Size = UDim2.fromOffset(300, 38), Visible = false, Parent = top }, { Kit.list(Enum.FillDirection.Horizontal, 6, Enum.HorizontalAlignment.Right) })
	refs.like = Kit.button("❤️ " .. t("ui.like"), { parent = refs.visit, size = UDim2.fromOffset(140, 36), style = "primary", textSize = 15, order = 1, onClick = function()
		NetDef.event("Like"):FireServer()
	end })
	refs.home = Kit.button("🏠 " .. t("ui.home"), { parent = refs.visit, size = UDim2.fromOffset(120, 36), style = "plain", textSize = 15, order = 2, onClick = function()
		NetDef.event("GoHome"):FireServer()
	end })
	-- dishes: shown when some are dirty
	refs.dishes = pill({ Name = "Dishes", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 50), Size = UDim2.fromOffset(150, 32), Visible = false, Parent = top })
	refs.dishesLabel = pillLabel(refs.dishes, 15)

	-- the orders, oldest first (tap one for the step-by-step guide)
	refs.tickets = Kit.new("Frame", { Name = "Tickets", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 52), Size = UDim2.fromOffset(236, 420), Parent = top }, { Kit.list(Enum.FillDirection.Vertical, 6, Enum.HorizontalAlignment.Right) })

	-- what you are holding, with a put-down button
	refs.hands = pill({ Name = "Hands", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -88), Size = UDim2.fromOffset(380, 40), Visible = false, Parent = top })
	refs.handsLabel = Kit.label("", { Parent = refs.hands, Position = UDim2.fromOffset(14, 0), Size = UDim2.new(1, -140, 1, 0), TextSize = 16, FontFace = T.bold, TextYAlignment = Enum.TextYAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd, TextWrapped = false })
	refs.drop = Kit.button("⬇ " .. t("ui.drop") .. (keyboard() and " [G]" or ""), {
		parent = refs.hands, size = UDim2.fromOffset(118, 32), position = UDim2.new(1, -122, 0, 4), style = "plain", textSize = 14, radius = 16,
		onClick = function()
			NetDef.event("DropHands"):FireServer()
		end,
	})

	-- the four big buttons
	refs.dock = Kit.new("Frame", { Name = "Dock", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -8), Size = UDim2.fromOffset(310, 74), Parent = top }, { Kit.list(Enum.FillDirection.Horizontal, 8, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Bottom) })
	refs.buttons = {}
	for i, b in ipairs(BUTTONS) do
		local btn = Kit.new("TextButton", { Name = b.id, Size = UDim2.fromOffset(70, 70), BackgroundColor3 = T.paper, Text = "", LayoutOrder = i, AutoButtonColor = true, Parent = refs.dock }, { Kit.corner(18), Kit.stroke(T.wood, 2.5, 0.05), Kit.sheen(0.88) })
		local icon = Kit.label(b.icon, { Parent = btn, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 5), Size = UDim2.new(1, -16, 0.52, 0), TextScaled = true, TextXAlignment = Enum.TextXAlignment.Center })
		local lbl = Kit.label("", { Parent = btn, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -4), Size = UDim2.new(1, -6, 0, 17), TextSize = 13, FontFace = T.bold, TextXAlignment = Enum.TextXAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd, TextWrapped = false })
		if b.hotkey and keyboard() then
			local key = Kit.new("Frame", { AnchorPoint = Vector2.new(0, 0), Position = UDim2.fromOffset(-5, -5), Size = UDim2.fromOffset(20, 20), BackgroundColor3 = T.wood, Parent = btn }, { Kit.corner(6) })
			Kit.label(b.hotkey, { Parent = key, Size = UDim2.fromScale(1, 1), TextSize = 13, FontFace = T.bold, TextColor3 = T.white, TextXAlignment = Enum.TextXAlignment.Center })
		end
		Kit.press(btn)
		btn.MouseButton1Click:Connect(function()
			if Core.C.Audio then
				Core.C.Audio.play("ui")
			end
			open(b.id)
		end)
		refs.buttons[b.id] = { button = btn, label = lbl, icon = icon, def = b, badge = Kit.badge(btn, 24) }
	end

	player:GetAttributeChangedSignal("Hands"):Connect(HUD.refreshHands)
	player:GetAttributeChangedSignal("HandsKind"):Connect(HUD.refreshHands)
	-- G puts down what you hold (keyboard)
	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.G and refs.hands.Visible then
			NetDef.event("DropHands"):FireServer()
		end
	end)
	HUD.layout()
	Core.C.UI.ProfileChanged:Connect(function()
		HUD.layout()
		HUD.refreshTickets()
	end)
	task.spawn(function()
		while true do
			task.wait(1)
			HUD.refreshTickets()
			HUD.refreshInfo()
			HUD.day()
			HUD.refreshGift()
			HUD.refreshGoal()
		end
	end)
	Core.C.Data.TicketsChanged:Connect(HUD.refreshTickets)
end

-- positions and sizes for the kind of screen
function HUD.layout()
	local l = L()
	refs.dock.Position = UDim2.new(l.dockX, 0, 1, -8)
	refs.dock.Size = UDim2.fromOffset(4 * l.dockW + 3 * 8, l.dockH + 4)
	for _, b in pairs(refs.buttons) do
		b.button.Size = UDim2.fromOffset(l.dockW, l.dockH)
	end
	refs.hands.Position = UDim2.new(l.dockX, 0, 1, -(l.dockH + 20))
	refs.xpText.Visible = Kit.profile ~= "phone"
	refs.tickets.Size = UDim2.fromOffset(l.ticketW, (l.ticketH + 6) * (l.tickets + 1))
end

-- where flying coins land (screen pixels, without the top bar inset)
function HUD.walletPoint()
	local l = refs.yen
	if not l then
		return nil
	end
	return l.AbsolutePosition + Vector2.new(30, l.AbsoluteSize.Y / 2)
end

-- the wallet pops a little when a coin lands
local bumping = false
function HUD.bumpWallet()
	local l = refs.yen
	if not l or bumping then
		return
	end
	bumping = true
	Kit.bump(l, 1.18)
	task.delay(0.3, function()
		bumping = false
	end)
end

-- the yen counter runs up to the new amount instead of jumping
local shownYen = nil
local yenTween = nil
local function showYen(amount)
	local Lg = Locale.get()
	if not shownYen or amount < shownYen or amount - shownYen > 1e7 then
		shownYen = amount
		refs.yen.Text = Format.yen(amount, Lg)
		return
	end
	if amount == shownYen then
		return
	end
	local value = Instance.new("NumberValue")
	value.Value = shownYen
	value.Changed:Connect(function(v)
		refs.yen.Text = Format.yen(math.floor(v + 0.5), Lg)
	end)
	if yenTween then
		yenTween:Cancel()
	end
	yenTween = game:GetService("TweenService"):Create(value, TweenInfo.new(0.6, Enum.EasingStyle.Quad), { Value = amount })
	yenTween:Play()
	shownYen = amount
end

-- first daily quest that is not claimed yet
function HUD.currentGoal()
	local meta = Core.C.Data.m("meta") or {}
	for _, q in ipairs(meta.quests or {}) do
		if not q.claimed then
			return q
		end
	end
	return nil
end

function HUD.refreshGoal()
	local q = HUD.currentGoal()
	-- the tutorial uses the top of the screen while it runs (Controllers/Tutorial)
	local tut = Core.C.Tutorial
	if not q or (tut and tut.active and tut.active()) then
		refs.goal.Visible = false
		return
	end
	refs.goal.Visible = true
	local text = t("quest." .. q.id, { n = q.target })
	if q.progress >= q.target then
		refs.goalLabel.Text = "🎯 " .. text .. "  ·  ✅ " .. t("ui.objective_claim")
		refs.goal.BackgroundColor3 = T.gold
	else
		refs.goalLabel.Text = "🎯 " .. text .. "  ·  " .. math.floor(q.progress) .. "/" .. q.target
		refs.goal.BackgroundColor3 = T.paper
	end
end

local giftToasted = {}
function HUD.refreshGift()
	local screen = Core.C.UI and Core.C.UI.screens.Gifts
	local idx, left = nil, nil
	if screen and screen.nextGift then
		idx, left = screen.nextGift()
	end
	if not idx then
		refs.gift.Visible = false
		return
	end
	refs.gift.Visible = true
	if left <= 0 then
		refs.giftLabel.Text = "🎁 " .. t("ui.gift_ready") .. (keyboard() and " [R]" or "")
		refs.gift.BackgroundColor3 = T.gold
		if not giftToasted[idx] then
			giftToasted[idx] = true
			Kit.bump(refs.gift, 1.2)
			Core.C.UI.toast("🎁 " .. t("msg.gift_ready"), "success")
			if Core.C.Audio then
				Core.C.Audio.play("gift")
			end
		end
	else
		refs.giftLabel.Text = "🎁 " .. Format.duration(left)
		refs.gift.BackgroundColor3 = T.paper
	end
end

function HUD.refreshHands()
	local kind = player:GetAttribute("HandsKind") or ""
	local raw = player:GetAttribute("Hands") or "[]"
	local ok, list = pcall(HttpService.JSONDecode, HttpService, raw)
	if not ok or kind == "" or #list == 0 then
		refs.hands.Visible = false
		return
	end
	local parts = {}
	for _, id in ipairs(list) do
		if kind == "dish" then
			table.insert(parts, (Recipes.byId[id] and Recipes.byId[id].icon or "🍽️") .. " " .. t("rec." .. id))
		elseif kind == "dirty" then
			table.insert(parts, "🧽")
		else
			local ing = Ingredients.byId[id]
			table.insert(parts, (ing and ing.icon or "📦") .. (kind == "box" and (" " .. t("ui.box_of", { name = "ing." .. id })) or ""))
		end
	end
	refs.handsLabel.Text = t("ui.holding") .. " " .. table.concat(parts, "  ")
	refs.hands.Visible = not (Core.C.Build and Core.C.Build.active)
end

local lastDay = nil
function HUD.day(state)
	lastDay = state or lastDay or {}
	state = lastDay
	-- closed with the sign by the door: said next to the clock
	local closed = Core.C.Data.plotAttr("Open") == false
	refs.clock.Text = (state.night and "🌙 " or "🕒 ") .. Format.clock(state.clock or 10) .. "  ·  " .. t("ui.day_n", { n = state.day or 1 }) .. (closed and ("  ·  🔴 " .. t("ui.closed")) or "")
	refs.day.Size = UDim2.fromOffset(closed and 320 or 214, 36)
end

-- the restaurant the player stands in: own (rating and likes) or someone else's (like, go home)
local function placeHere()
	local rootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	return rootPart and Core.C.Data.plotAt(rootPart.Position) or nil
end

function HUD.refreshInfo()
	local Data = Core.C.Data
	local here = placeHere()
	local folder = here and Data.plotFolder(here.id)
	local likes = folder and folder:GetAttribute("Likes") or 0
	local rating = (folder and folder:GetAttribute("Rating")) or Data.plotAttr("Rating") or 3
	local visiting = here ~= nil and here.ownerId ~= 0 and here.ownerId ~= player.UserId
	local text = "★ " .. Format.decimal(rating, 1, lang()) .. "   ❤️ " .. likes
	if visiting then
		text = "🏮 " .. (here.ownerName or "") .. "  ·  ★ " .. Format.decimal(rating, 1, lang())
	end
	-- friends working together: the restaurant earns more (Plots, GameConfig.Coop)
	local coop = folder and folder:GetAttribute("CoopBonus") or 0
	if coop > 0 then
		text ..= "   🤝 +" .. math.floor(coop * 100 + 0.5) .. "%"
	end
	refs.placeLabel.Text = text
	refs.place.Size = UDim2.fromOffset((visiting and 260 or 176) + (coop > 0 and 84 or 0), 36)
	refs.visit.Visible = visiting
	refs.like.Text = "❤️ " .. t("ui.like") .. "  " .. likes
	-- dishes: only when there is washing to do (or few clean ones are left)
	local d = Data.w("dishes")
	local pile = Data.plotAttr("SinkPile") or 0
	local showDishes = not visiting and d ~= nil and (pile > 0 or d.clean < d.total)
	refs.dishes.Visible = showDishes
	if showDishes then
		refs.dishesLabel.Text = "🍽️ " .. d.clean .. "/" .. d.total .. (pile > 0 and ("   🧽 " .. pile) or "")
		refs.dishes.BackgroundColor3 = (d.clean <= math.max(2, d.total * 0.2)) and T.gold or T.paper
	end
	local below = 50
	if visiting then
		below = 94
	elseif showDishes then
		below = 90
	end
	refs.tickets.Position = UDim2.new(1, -10, 0, below)
	local day = Data.day
	if day then
		local Lighting = game:GetService("Lighting")
		refs.clock.Text = (day.night and "🌙 " or "🕒 ") .. Format.clock(Lighting.ClockTime) .. "  ·  " .. t("ui.day_n", { n = day.day or 1 })
	end
end

-- patience (0..1) of the customer who ordered, read from their model
local function patienceOf(customerUid)
	for _, m in ipairs(CollectionService:GetTagged("Interactable")) do
		if m:GetAttribute("Uid") == customerUid then
			return m:GetAttribute("Patience") or 1
		end
	end
	return nil
end

-- Order tickets (right): big dish icon and name, what goes into it, and the customer's patience
-- as a coloured bar. The oldest order is the one to cook now (gold edge). Tap one for the guide.
function HUD.refreshTickets()
	local holder = refs.tickets
	if not holder then
		return
	end
	Kit.clear(holder)
	local l = L()
	local guide = Core.C.UI.screens.Guide
	local selected = guide and guide.recipe
	local tickets = Core.C.Data.tickets or {}
	for i, tk in ipairs(tickets) do
		if i > l.tickets then
			local more = pill({ Size = UDim2.fromOffset(84, 28), LayoutOrder = i, Parent = holder })
			pillLabel(more, 15).Text = "+" .. (#tickets - l.tickets)
			break
		end
		local r = Recipes.byId[tk.recipe]
		local p = patienceOf(tk.customer) or 1
		local barColor = p > 0.5 and T.green or (p > 0.25 and T.gold or T.red)
		local edge = selected == tk.recipe and T.red or (i == 1 and T.gold or (p <= 0.25 and T.red or T.wood))
		local card = Kit.new("TextButton", { Name = "Ticket", Text = "", Size = UDim2.fromOffset(l.ticketW, l.ticketH), BackgroundColor3 = Color3.fromRGB(255, 251, 242), LayoutOrder = i, AutoButtonColor = true, Parent = holder }, {
			Kit.corner(12), Kit.stroke(edge, (i == 1 or selected == tk.recipe) and 3 or 2),
		})
		Kit.label((r and r.icon or "🍽️"), { Parent = card, Size = UDim2.fromOffset(l.ticketH - 18, l.ticketH - 18), Position = UDim2.fromOffset(8, 5), TextScaled = true })
		Kit.label(t("rec." .. tk.recipe), { Parent = card, Position = UDim2.fromOffset(l.ticketH - 4, 4), Size = UDim2.new(1, -(l.ticketH + 22), 0, 22), TextSize = 17, FontFace = T.bold, TextTruncate = Enum.TextTruncate.AtEnd, TextWrapped = false })
		Kit.label("#" .. i, { Parent = card, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 5), Size = UDim2.fromOffset(26, 18), TextSize = 13, FontFace = T.bold, TextColor3 = T.muted, TextXAlignment = Enum.TextXAlignment.Right, TextWrapped = false })
		-- what goes into it: ingredients, plus broth / rice
		local need = {}
		for _, g in ipairs(r and r.ing or {}) do
			local ing = Ingredients.byId[g]
			table.insert(need, ing and ing.icon or "?")
		end
		if r and r.broth then
			table.insert(need, "🥣")
		end
		if r and r.rice then
			table.insert(need, "🍚")
		end
		Kit.label(table.concat(need, " ") .. (tk.claimed and "   👨‍🍳" or ""), { Parent = card, Position = UDim2.fromOffset(l.ticketH - 4, 26), Size = UDim2.new(1, -(l.ticketH + 2), 0, 18), TextSize = 15, TextTruncate = Enum.TextTruncate.AtEnd, TextWrapped = false })
		local bar = Kit.new("Frame", { Position = UDim2.new(0, 10, 1, -11), Size = UDim2.new(1, -20, 0, 6), BackgroundColor3 = Color3.fromRGB(216, 200, 174), Parent = card }, { Kit.corner(3) })
		Kit.new("Frame", { Size = UDim2.fromScale(math.clamp(p, 0, 1), 1), BackgroundColor3 = barColor, Parent = bar }, { Kit.corner(3) })
		Kit.press(card)
		card.MouseButton1Click:Connect(function()
			if Core.C.UI.screens.Guide then
				Core.C.UI.screens.Guide.show(tk.recipe)
			else
				Core.C.Interaction.highlightRecipe(tk.recipe)
			end
			HUD.refreshTickets()
		end)
	end
	holder.Visible = not (Core.C.Build and Core.C.Build.active)
end

-- how many things the restaurant can buy right now (the shop button's badge)
local lastBuyable = 0
local function refreshShopBadge()
	local Data = Core.C.Data
	local b = refs.buttons.Shop
	if not b then
		return
	end
	if not Data.canBuild() or not (Data.world or Data.me) then
		b.badge(0)
		return
	end
	local rating = Data.plotAttr("Rating") or 3
	local w = Data.restaurant()
	local total = ShopLogic.buyable(w, SHOP_CFG, rating)
	if total > lastBuyable then
		Kit.bump(b.button, 1.12)
	end
	lastBuyable = total
	b.badge(total)
end

function HUD.refresh()
	local Data = Core.C.Data
	if not Data.ready then
		return
	end
	showYen(Data.wallet())
	refs.sakura.Text = Format.sakura(Data.m("sakura") or 0, lang())
	local level = Data.w("level") or 1
	local xp = Data.w("xp") or 0
	local need = Formulas.xpForLevel(level)
	refs.level.Text = tostring(level)
	refs.xpText.Text = Format.number(xp, lang()) .. " / " .. Format.number(need, lang()) .. " XP"
	refs.xpFill.Size = UDim2.fromScale(math.clamp(xp / need, 0, 1), 1)
	for _, b in pairs(refs.buttons) do
		b.label.Text = t(b.def.key)
		b.button.BackgroundColor3 = (b.def.build and not Data.canBuild()) and T.locked or T.paper
	end
	refreshShopBadge()
	-- texts made before the language was known
	refs.home.Text = "🏠 " .. t("ui.home")
	refs.drop.Text = "⬇ " .. t("ui.drop") .. (keyboard() and " [G]" or "")
	HUD.day(Data.day)
	HUD.refreshHands()
	HUD.refreshInfo()
end

-- While building, the dock, the orders and the hands bar step aside for the catalog
function HUD.setBuilding(on)
	if not HUD.frame then
		return
	end
	refs.dock.Visible = not on
	refs.tickets.Visible = not on
	if on then
		refs.hands.Visible = false
	else
		HUD.refreshHands()
	end
end

function HUD.open() end
function HUD.close() end

return HUD
