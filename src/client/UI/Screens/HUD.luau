--!nonstrict
-- Always-visible HUD, kept small: wallet and level (top-left), day bar with an open / closed
-- switch (top-centre), rating line (top-right), order tickets (left), what you hold (bottom),
-- build / supplier / phone (bottom-left).
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local NetDef = require(Shared.Net)
local Locale = require(Shared.Locale)
local Format = require(Shared.Util.Format)
local Formulas = require(Shared.Logic.Formulas)
local Recipes = require(Shared.Config.Recipes)
local Ingredients = require(Shared.Config.Ingredients)
local Kit = require(script.Parent.Parent.Kit)
local Core = require(script.Parent.Parent.Parent.Core)

local HUD = { modal = false }
local T = Kit.Theme
local t = Locale.t
local refs = {}
local player = Players.LocalPlayer

-- Always on screen: the two most used actions and the phone (bottom-left). Everything else is an
-- app on the phone, ordered by how often it is needed (see Screens/Phone).
local BUTTONS = {
	{ id = "Build", icon = "🔨", key = "ui.build", build = true, hotkey = "B" },
	{ id = "Supplier", icon = "📦", key = "ui.supplier", build = true, hotkey = "O" },
	{ id = "Phone", icon = "📱", key = "ui.phone", hotkey = "P" },
}

local function lang()
	return Locale.get()
end

-- " [R]" after a label on keyboards (shortcuts in Controllers/FirstPerson)
local function keyHint(key)
	if game:GetService("UserInputService").KeyboardEnabled then
		return " [" .. key .. "]"
	end
	return ""
end

local function open(id)
	local UIc = Core.C.UI
	if id == "Build" then
		Core.C.Build.toggle()
		return
	end
	UIc.toggle(id)
end

-- Small rounded pill used by the compact top bar
local function pill(props)
	local f = Kit.new("Frame", props, { Kit.corner(18), Kit.stroke(T.wood, 2, 0.2), Kit.sheen(0.9) })
	f.BackgroundColor3 = props.BackgroundColor3 or T.paper
	return f
end

function HUD.create(root)
	local top = Kit.new("Frame", { Name = "HUD", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = root })
	HUD.frame = top
	-- wallet & level (top-left, compact)
	local wallet = pill({ Size = UDim2.fromOffset(236, 54), Position = UDim2.fromOffset(10, 8), Parent = top })
	refs.yen = Kit.label("¥0", { Parent = wallet, Position = UDim2.fromOffset(14, 3), Size = UDim2.fromOffset(140, 26), TextSize = 22, FontFace = T.title, TextColor3 = T.wood })
	refs.sakura = Kit.label("🌸0", { Parent = wallet, Position = UDim2.new(1, -86, 0, 5), Size = UDim2.fromOffset(74, 22), TextSize = 16, FontFace = T.bold, TextXAlignment = Enum.TextXAlignment.Right })
	refs.level = Kit.label("", { Parent = wallet, Position = UDim2.fromOffset(14, 30), Size = UDim2.fromOffset(70, 18), TextSize = 13, FontFace = T.bold, TextColor3 = T.muted })
	local bar, fill = Kit.bar(0, T.gold, { Parent = wallet, Position = UDim2.fromOffset(84, 35), Size = UDim2.new(1, -100, 0, 8) })
	refs.xpFill = fill
	local _ = bar
	-- day bar (top-centre): clock, day and a small open / closed switch
	local day = pill({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 8), Size = UDim2.fromOffset(300, 36), Parent = top })
	refs.clock = Kit.label("", { Parent = day, Position = UDim2.fromOffset(14, 0), Size = UDim2.fromOffset(76, 36), TextSize = 17, FontFace = T.title, TextColor3 = T.wood, TextYAlignment = Enum.TextYAlignment.Center })
	refs.dayInfo = Kit.label("", { Parent = day, Position = UDim2.fromOffset(92, 0), Size = UDim2.fromOffset(96, 36), TextSize = 14, TextColor3 = T.muted, TextYAlignment = Enum.TextYAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd })
	refs.dayButton = Kit.button("", {
		size = UDim2.fromOffset(104, 26), position = UDim2.new(1, -110, 0, 5), style = "green", textSize = 13, radius = 13,
		onClick = function()
			local phase = Core.C.Data.day.phase
			if phase == "prep" then
				NetDef.event("SetDayState"):FireServer("open")
			elseif phase == "open" then
				NetDef.event("SetDayState"):FireServer("close")
			elseif phase == "report" then
				Core.C.UI.open("DayReport", Core.C.Data.day.report)
			end
		end,
	})
	refs.dayButton.Parent = day
	-- rating, ambience and plates (top-right, one line)
	local info = pill({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 8), Size = UDim2.fromOffset(268, 36), Parent = top })
	refs.rating = Kit.label("", { Parent = info, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -24, 1, 0), TextSize = 14, FontFace = T.bold, TextYAlignment = Enum.TextYAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd })
	refs.ambience = refs.rating
	refs.dishes = refs.rating
	-- ❤️ likes of this restaurant (top-right, under the rating); visitors can like it once a day
	refs.like = Kit.new("TextButton", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 48), Size = UDim2.fromOffset(150, 28), BackgroundColor3 = T.paper, Text = "", Parent = top }, { Kit.corner(14), Kit.stroke(T.red, 2, 0.2) })
	refs.likeLabel = Kit.label("", { Parent = refs.like, Size = UDim2.fromScale(1, 1), TextSize = 14, FontFace = T.bold, TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center })
	refs.like.MouseButton1Click:Connect(function()
		if Core.C.Data.role() ~= "owner" then
			NetDef.event("Like"):FireServer()
		end
	end)
	-- today's objective (first daily quest not claimed yet) under the day bar
	refs.goal = Kit.new("TextButton", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 48), Size = UDim2.fromOffset(330, 28), BackgroundColor3 = T.paper, Text = "", Visible = false, Parent = top }, { Kit.corner(14), Kit.stroke(T.wood, 2, 0.2) })
	refs.goalLabel = Kit.label("", { Parent = refs.goal, Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -20, 1, 0), TextSize = 14, FontFace = T.bold, TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd })
	refs.goal.MouseButton1Click:Connect(function()
		local q = HUD.currentGoal and HUD.currentGoal()
		if q and q.progress >= q.target then
			NetDef.event("ClaimQuest"):FireServer(q.id)
		else
			Core.C.UI.toggle("Goals")
		end
	end)
	-- free gift for minutes played (Screens/Gifts): countdown, then "claim!"
	refs.gift = Kit.new("TextButton", { Position = UDim2.fromOffset(10, 68), Size = UDim2.fromOffset(150, 30), BackgroundColor3 = T.paper, Text = "", Visible = false, Parent = top }, { Kit.corner(15), Kit.stroke(T.wood, 2, 0.2), Kit.sheen(0.9) })
	refs.giftLabel = Kit.label("🎁", { Parent = refs.gift, Size = UDim2.fromScale(1, 1), TextSize = 15, FontFace = T.bold, TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center })
	refs.gift.MouseButton1Click:Connect(function()
		if Core.C.Audio then
			Core.C.Audio.play("ui")
		end
		Core.C.UI.toggle("Gifts")
	end)
	-- order tickets (left, under the wallet): click one to see how to make it
	refs.tickets = Kit.new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 104), Size = UDim2.fromOffset(196, 420), Parent = top }, { Kit.list(Enum.FillDirection.Vertical, 5) })
	-- what you are holding (bottom-centre) with a put-down button
	refs.hands = pill({ AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -14), Size = UDim2.fromOffset(360, 40), Visible = false, Parent = top })
	refs.handsLabel = Kit.label("", { Parent = refs.hands, Position = UDim2.fromOffset(14, 0), Size = UDim2.new(1, -130, 1, 0), TextSize = 15, FontFace = T.bold, TextYAlignment = Enum.TextYAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd })
	Kit.button("⬇ " .. t("ui.drop"), {
		parent = refs.hands, size = UDim2.fromOffset(110, 28), position = UDim2.new(1, -116, 0, 6), style = "plain", textSize = 13, radius = 14,
		onClick = function()
			NetDef.event("DropHands"):FireServer()
		end,
	})
	-- main actions (bottom-left): build, order supplies, phone
	local dock = Kit.new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 10, 1, -10), Size = UDim2.fromOffset(222, 70), Parent = top }, { Kit.list(Enum.FillDirection.Horizontal, 8, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Bottom) })
	refs.buttons = {}
	for i, b in ipairs(BUTTONS) do
		local btn = Kit.new("TextButton", { Size = UDim2.fromOffset(66, 66), BackgroundColor3 = T.paper, Text = "", LayoutOrder = i, Parent = dock }, { Kit.corner(16), Kit.stroke(T.wood, 2, 0.1), Kit.sheen(0.88) })
		Kit.label(b.icon, { Parent = btn, Size = UDim2.new(1, 0, 0, 34), Position = UDim2.fromOffset(0, 5), TextScaled = true, TextXAlignment = Enum.TextXAlignment.Center })
		local lbl = Kit.label("", { Parent = btn, Size = UDim2.new(1, -4, 0, 18), Position = UDim2.fromOffset(2, 43), TextSize = 12, FontFace = T.bold, TextXAlignment = Enum.TextXAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd })
		if b.hotkey and game:GetService("UserInputService").KeyboardEnabled then
			-- keyboard shortcut (see Controllers/FirstPerson)
			local key = Kit.new("Frame", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 4, 0, -4), Size = UDim2.fromOffset(20, 20), BackgroundColor3 = T.wood, Parent = btn }, { Kit.corner(6) })
			Kit.label(b.hotkey, { Parent = key, Size = UDim2.fromScale(1, 1), TextSize = 13, FontFace = T.bold, TextColor3 = T.white, TextXAlignment = Enum.TextXAlignment.Center })
		end
		btn.MouseButton1Click:Connect(function()
			if Core.C.Audio then
				Core.C.Audio.play("ui")
			end
			open(b.id)
		end)
		refs.buttons[b.id] = { button = btn, label = lbl, def = b }
	end
	player:GetAttributeChangedSignal("Hands"):Connect(HUD.refreshHands)
	player:GetAttributeChangedSignal("HandsKind"):Connect(HUD.refreshHands)
	-- G puts down what you hold (keyboard)
	game:GetService("UserInputService").InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.G and refs.hands.Visible then
			NetDef.event("DropHands"):FireServer()
		end
	end)
	task.spawn(function()
		while true do
			task.wait(1)
			HUD.refreshTickets()
			HUD.refreshInfo()
			HUD.refreshGift()
			HUD.refreshGoal()
			HUD.refreshLike()
		end
	end)
	Core.C.Data.TicketsChanged:Connect(HUD.refreshTickets)
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

function HUD.refreshLike()
	local n = workspace:GetAttribute("Likes") or 0
	if Core.C.Data.role() == "owner" then
		refs.likeLabel.Text = "❤️ " .. n
		refs.like.AutoButtonColor = false
	else
		refs.likeLabel.Text = "❤️ " .. t("ui.like") .. "  " .. n
	end
end

function HUD.refreshGoal()
	local q = HUD.currentGoal()
	if not q then
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
		local hot = keyHint("R")
		refs.giftLabel.Text = "🎁 " .. t("ui.gift_ready") .. hot
		refs.gift.BackgroundColor3 = T.gold
		if not giftToasted[idx] then
			giftToasted[idx] = true
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
	refs.hands.Visible = true
end

function HUD.day(state)
	local phase = state.phase
	refs.clock.Text = "🕒 " .. Format.clock(state.clock or 9.5)
	refs.dayInfo.Text = t("ui.day_n", { n = state.day or 1 })
	local b = refs.dayButton
	if phase == "prep" then
		b.Text = "● " .. t("ui.closed_tap")
		b.BackgroundColor3 = T.red
	elseif phase == "open" then
		b.Text = "● " .. t("ui.open_tap")
		b.BackgroundColor3 = T.green
	elseif phase == "closing" then
		b.Text = t("ui.closing")
		b.BackgroundColor3 = T.locked
	else
		b.Text = "📊 " .. t("ui.report_short")
		b.BackgroundColor3 = T.gold
	end
	b.Active = Core.C.Data.canBuild() or phase == "report"
	b.AutoButtonColor = b.Active
end

function HUD.refreshInfo()
	local rating = workspace:GetAttribute("Rating") or 3
	local tier = workspace:GetAttribute("AmbienceTier") or 0
	local text = "★ " .. Format.decimal(rating, 1, lang()) .. "   ✨ " .. t("amb.tier" .. tier)
	local d = Core.C.Data.w("dishes")
	if d then
		text ..= "   🍽️ " .. d.clean .. "/" .. d.total
		local pile = workspace:GetAttribute("SinkPile") or 0
		if pile > 0 then
			text ..= "  🧽" .. pile
		end
	end
	refs.rating.Text = text
	local day = Core.C.Data.day
	if day and day.phase == "open" then
		refs.clock.Text = "🕒 " .. Format.clock(game:GetService("Lighting").ClockTime)
	end
end

function HUD.refreshTickets()
	local holder = refs.tickets
	if not holder then
		return
	end
	Kit.clear(holder)
	local now = workspace:GetServerTimeNow()
	local guide = Core.C.UI.screens.Guide
	local selected = guide and guide.recipe
	for i, tk in ipairs(Core.C.Data.tickets or {}) do
		if i > 6 then
			break
		end
		local r = Recipes.byId[tk.recipe]
		local age = now - (tk.created or now)
		local col = age < 30 and T.paper or (age < 60 and Kit.Theme.gold or Kit.Theme.red)
		local card = Kit.new("TextButton", { Text = "", Size = UDim2.fromOffset(196, 44), BackgroundColor3 = col, LayoutOrder = i, Parent = holder }, { Kit.corner(10), Kit.stroke(selected == tk.recipe and T.red or T.wood, selected == tk.recipe and 3 or 2) })
		Kit.label((r and r.icon or "🍽️"), { Parent = card, Size = UDim2.fromOffset(32, 32), Position = UDim2.fromOffset(6, 6), TextScaled = true })
		Kit.label(t("rec." .. tk.recipe), { Parent = card, Position = UDim2.fromOffset(44, 3), Size = UDim2.new(1, -50, 0, 20), TextSize = 14, FontFace = T.bold, TextTruncate = Enum.TextTruncate.AtEnd })
		Kit.label("⏱ " .. Format.duration(age) .. (tk.claimed and "  👨‍🍳" or "") .. "   " .. t("ui.tap_for_steps"), { Parent = card, Position = UDim2.fromOffset(44, 22), Size = UDim2.new(1, -50, 0, 18), TextSize = 12, TextColor3 = T.muted, TextTruncate = Enum.TextTruncate.AtEnd })
		card.MouseButton1Click:Connect(function()
			if Core.C.UI.screens.Guide then
				Core.C.UI.screens.Guide.show(tk.recipe)
			else
				Core.C.Interaction.highlightRecipe(tk.recipe)
			end
			HUD.refreshTickets()
		end)
	end
end

function HUD.refresh()
	local Data = Core.C.Data
	if not Data.ready then
		return
	end
	refs.yen.Text = Format.yen(Data.wallet(), lang())
	refs.sakura.Text = Format.sakura(Data.m("sakura") or 0, lang())
	local level = Data.w("level") or 1
	local xp = Data.w("xp") or 0
	refs.level.Text = t("ui.level_n", { n = level }) .. "  ·  " .. Format.number(xp, lang()) .. "/" .. Format.number(Formulas.xpForLevel(level), lang()) .. " XP"
	refs.xpFill.Size = UDim2.fromScale(math.clamp(xp / Formulas.xpForLevel(level), 0, 1), 1)
	for id, b in pairs(refs.buttons) do
		b.label.Text = t(b.def.key)
		local visible = true
		if b.def.dev then
			visible = player:GetAttribute("Dev") == true
		end
		b.button.Visible = visible
		b.button.BackgroundColor3 = (b.def.build and not Data.canBuild()) and T.locked or T.paper
	end
	HUD.day(Data.day)
	HUD.refreshHands()
	HUD.refreshInfo()
end

-- While building, the dock, tickets and hands bar step aside for the catalog
function HUD.setBuilding(on)
	if not HUD.frame then
		return
	end
	for _, b in pairs(refs.buttons or {}) do
		b.button.Parent.Visible = not on
	end
	if refs.tickets then
		refs.tickets.Visible = not on
	end
	if on and refs.hands then
		refs.hands.Visible = false
	elseif refs.hands then
		HUD.refreshHands()
	end
end

function HUD.open() end
function HUD.close() end

return HUD
