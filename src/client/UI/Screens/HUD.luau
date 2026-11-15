--!nonstrict
-- Always-visible HUD: wallet, level, clock/day controls, rating, tickets, hands and menu bar.
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

local BUTTONS = {
	{ id = "Build", icon = "🔨", key = "ui.build", build = true },
	{ id = "Supplier", icon = "📦", key = "ui.supplier", build = true },
	{ id = "Menu", icon = "📜", key = "ui.menu" },
	{ id = "Licenses", icon = "🎫", key = "ui.licenses" },
	{ id = "Upgrades", icon = "⬆️", key = "ui.upgrades" },
	{ id = "Staff", icon = "👥", key = "ui.staff" },
	{ id = "Expansions", icon = "🏗️", key = "ui.expansions" },
	{ id = "Goals", icon = "🎯", key = "ui.goals" },
	{ id = "Shop", icon = "🛒", key = "ui.shop" },
	{ id = "Invite", icon = "👋", key = "ui.invite" },
	{ id = "Settings", icon = "⚙️", key = "ui.settings" },
	{ id = "Dev", icon = "🛠️", key = "ui.dev", dev = true },
}

local function lang()
	return Locale.get()
end

local function open(id)
	local UIc = Core.C.UI
	if id == "Build" then
		Core.C.Build.toggle()
		return
	end
	UIc.toggle(id)
end

function HUD.create(root)
	local top = Kit.new("Frame", { Name = "HUD", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = root })
	HUD.frame = top
	-- wallet & level (top-left)
	local wallet = Kit.panel({ Size = UDim2.fromOffset(250, 92), Position = UDim2.fromOffset(12, 10), Parent = top })
	Kit.padding(10, 8).Parent = wallet
	refs.yen = Kit.label("¥0", { Parent = wallet, Size = UDim2.new(1, 0, 0, 28), TextSize = 26, FontFace = T.title, TextColor3 = T.wood })
	refs.sakura = Kit.label("🌸0", { Parent = wallet, Position = UDim2.fromOffset(150, 2), Size = UDim2.fromOffset(80, 24), TextSize = 18, FontFace = T.bold, TextXAlignment = Enum.TextXAlignment.Right })
	refs.level = Kit.label("", { Parent = wallet, Position = UDim2.fromOffset(0, 32), Size = UDim2.new(1, 0, 0, 20), TextSize = 16, FontFace = T.bold })
	local bar, fill = Kit.bar(0, T.gold, { Parent = wallet, Position = UDim2.fromOffset(0, 56), Size = UDim2.new(1, 0, 0, 12) })
	refs.xpFill = fill
	local _ = bar
	-- day / clock (top-center)
	local day = Kit.panel({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 10), Size = UDim2.fromOffset(330, 70), Parent = top })
	refs.clock = Kit.label("", { Parent = day, Position = UDim2.fromOffset(12, 6), Size = UDim2.fromOffset(160, 26), TextSize = 22, FontFace = T.title, TextColor3 = T.wood })
	refs.dayInfo = Kit.label("", { Parent = day, Position = UDim2.fromOffset(12, 36), Size = UDim2.fromOffset(170, 24), TextSize = 16 })
	refs.dayButton = Kit.button("", {
		size = UDim2.fromOffset(140, 50), position = UDim2.new(1, -150, 0, 10), style = "green", textSize = 16,
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
	-- rating & ambience (top-right)
	local info = Kit.panel({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 10), Size = UDim2.fromOffset(230, 70), Parent = top })
	refs.rating = Kit.label("", { Parent = info, Position = UDim2.fromOffset(12, 6), Size = UDim2.new(1, -24, 0, 24), TextSize = 20, FontFace = T.bold })
	refs.ambience = Kit.label("", { Parent = info, Position = UDim2.fromOffset(12, 36), Size = UDim2.new(1, -24, 0, 22), TextSize = 15, TextColor3 = T.muted })
	-- tickets (right)
	refs.tickets = Kit.new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 90), Size = UDim2.fromOffset(200, 460), Parent = top }, { Kit.list(Enum.FillDirection.Vertical, 6, Enum.HorizontalAlignment.Right) })
	-- hands (bottom-center, above the bar)
	refs.hands = Kit.panel({ AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -96), Size = UDim2.fromOffset(380, 46), Visible = false, Parent = top })
	refs.handsLabel = Kit.label("", { Parent = refs.hands, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -120, 1, 0), TextSize = 17, FontFace = T.bold, TextYAlignment = Enum.TextYAlignment.Center })
	Kit.button("🗑️ " .. t("ui.drop"), {
		parent = refs.hands, size = UDim2.fromOffset(100, 34), position = UDim2.new(1, -106, 0, 6), style = "plain", textSize = 15,
		onClick = function()
			NetDef.event("DropHands"):FireServer()
		end,
	})
	-- dishes + hint (bottom-left)
	refs.dishes = Kit.label("", { Parent = top, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 14, 1, -96), Size = UDim2.fromOffset(240, 24), TextSize = 17, FontFace = T.bold, TextStrokeTransparency = 0.6, TextColor3 = T.white })
	-- bottom bar
	local barFrame = Kit.panel({ AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -10), Size = UDim2.new(0.96, 0, 0, 78), BackgroundColor3 = T.wood, Parent = top })
	local scroll = Kit.new("ScrollingFrame", {
		BackgroundTransparency = 1, Size = UDim2.new(1, -12, 1, -8), Position = UDim2.fromOffset(6, 4), ScrollingDirection = Enum.ScrollingDirection.X,
		ScrollBarThickness = 4, AutomaticCanvasSize = Enum.AutomaticSize.X, CanvasSize = UDim2.new(0, 0, 0, 0), Parent = barFrame,
	}, { Kit.list(Enum.FillDirection.Horizontal, 6, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center) })
	refs.buttons = {}
	for i, b in ipairs(BUTTONS) do
		local btn = Kit.new("TextButton", { Size = UDim2.fromOffset(78, 66), BackgroundColor3 = T.paper, Text = "", LayoutOrder = i, Parent = scroll }, { Kit.corner(10) })
		Kit.label(b.icon, { Parent = btn, Size = UDim2.new(1, 0, 0, 34), Position = UDim2.fromOffset(0, 4), TextScaled = true, TextXAlignment = Enum.TextXAlignment.Center })
		local lbl = Kit.label("", { Parent = btn, Size = UDim2.new(1, -4, 0, 22), Position = UDim2.fromOffset(2, 40), TextSize = 13, FontFace = T.bold, TextXAlignment = Enum.TextXAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd })
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
	task.spawn(function()
		while true do
			task.wait(1)
			HUD.refreshTickets()
			HUD.refreshInfo()
		end
	end)
	Core.C.Data.TicketsChanged:Connect(HUD.refreshTickets)
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
	refs.dayInfo.Text = t("ui.day_n", { n = state.day or 1 }) .. " · " .. t("day." .. phase)
	local b = refs.dayButton
	if phase == "prep" then
		b.Text = t("ui.open_restaurant")
		b.BackgroundColor3 = T.green
	elseif phase == "open" then
		b.Text = t("ui.close_early")
		b.BackgroundColor3 = T.red
	elseif phase == "closing" then
		b.Text = t("ui.closing")
		b.BackgroundColor3 = T.locked
	else
		b.Text = t("ui.see_report")
		b.BackgroundColor3 = T.gold
	end
	b.Visible = Core.C.Data.canBuild() or phase == "report"
end

function HUD.refreshInfo()
	local rating = workspace:GetAttribute("Rating") or 3
	local stars = string.rep("★", math.floor(rating + 0.5)) .. string.rep("☆", 5 - math.floor(rating + 0.5))
	refs.rating.Text = stars .. "  " .. Format.decimal(rating, 1, lang())
	local tier = workspace:GetAttribute("AmbienceTier") or 0
	refs.ambience.Text = t("ui.ambience") .. ": " .. t("amb.tier" .. tier) .. " (" .. (workspace:GetAttribute("Ambience") or 0) .. ")"
	local d = Core.C.Data.w("dishes")
	if d then
		refs.dishes.Text = "🍽️ " .. t("ui.dishes_clean", { clean = d.clean, total = d.total }) .. "   🧽 " .. (workspace:GetAttribute("SinkPile") or 0)
	end
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
	for i, tk in ipairs(Core.C.Data.tickets or {}) do
		local r = Recipes.byId[tk.recipe]
		local age = now - (tk.created or now)
		local col = age < 30 and T.paper or (age < 60 and Kit.Theme.gold or Kit.Theme.red)
		local card = Kit.new("TextButton", { Text = "", Size = UDim2.fromOffset(200, 52), BackgroundColor3 = col, LayoutOrder = i, Parent = holder }, { Kit.corner(8), Kit.stroke(T.wood, 2) })
		Kit.label((r and r.icon or "🍽️"), { Parent = card, Size = UDim2.fromOffset(40, 40), Position = UDim2.fromOffset(6, 6), TextScaled = true })
		Kit.label(t("rec." .. tk.recipe), { Parent = card, Position = UDim2.fromOffset(50, 4), Size = UDim2.new(1, -56, 0, 24), TextSize = 16, FontFace = T.bold, TextTruncate = Enum.TextTruncate.AtEnd })
		Kit.label("⏱ " .. Format.duration(age) .. (tk.claimed and "  👨‍🍳" or ""), { Parent = card, Position = UDim2.fromOffset(50, 26), Size = UDim2.new(1, -56, 0, 20), TextSize = 14, TextColor3 = T.muted })
		card.MouseButton1Click:Connect(function()
			Core.C.Interaction.highlightRecipe(tk.recipe)
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

function HUD.open() end
function HUD.close() end

return HUD
