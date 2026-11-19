--!nonstrict
-- The shop: everything the restaurant buys with yen, in five tabs of big cards (upgrades and
-- adverts, recipes, staff, rooms, renovations). Every card says what it is and what it does, and
-- has one clear button:
--   green with the price      tap to buy
--   price in red              not enough yen yet (the card says how much is missing)
--   grey with a lock          something comes first (a level, a recipe, a room...)
--   a tick / MAX              already yours
-- Things to buy now come first, cheapest first. The tabs count what can be bought right now, like
-- the shop button in the HUD (Logic/Shop). Purchases go to the server, which checks everything
-- again (Services/Progression, Services/Staff).
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local NetDef = require(Shared.Net)
local Locale = require(Shared.Locale)
local Format = require(Shared.Util.Format)
local Color = require(Shared.Util.Color)
local ShopLogic = require(Shared.Logic.Shop)
local Formulas = require(Shared.Logic.Formulas)
local Upgrades = require(Shared.Config.Upgrades)
local Ads = require(Shared.Config.Ads)
local Licenses = require(Shared.Config.Licenses)
local Recipes = require(Shared.Config.Recipes)
local Expansions = require(Shared.Config.Expansions)
local StaffCfg = require(Shared.Config.Staff)
local GameConfig = require(Shared.Config.GameConfig)
local Kit = require(script.Parent.Parent.Kit)
local Base = require(script.Parent.Parent.Base)
local Icons = require(script.Parent.Parent.Icons)
local Core = require(script.Parent.Parent.Parent.Core)

local t = Locale.t
local T = Kit.Theme
local CFG = { Upgrades = Upgrades, Ads = Ads, Licenses = Licenses, Expansions = Expansions, Staff = StaffCfg, MaxStaff = GameConfig.MaxStaff }

local TABS = {
	{ id = "upgrades", icon = "⬆️", key = "ui.upgrades" },
	{ id = "recipes", icon = "🍜", key = "ui.tab_recipes" },
	{ id = "staff", icon = "👥", key = "ui.staff" },
	{ id = "rooms", icon = "🏗️", key = "ui.tab_rooms" },
	{ id = "reno", icon = "🪚", key = "ui.tab_renos" },
}
local BRANCH_ICON = { base = "🏠", sushi = "🍣", ramen = "🍜", extra = "🥟", master = "🎌" }
local BRANCH_TINT = { base = "#E9D9BE", sushi = "#F6D2C8", ramen = "#F4DDB0", extra = "#E3E8C4", master = "#F1D58E" }
local RENO_GROUPS = {
	{ id = "exterior", key = "ui.reno_exterior" },
	{ id = "interior", key = "ui.reno_interior" },
	{ id = "furniture", key = "ui.reno_furniture" },
}

local tab = "upgrades"
local lastBought = nil -- { key, progress } of the card whose purchase was just sent (it springs when it lands)

local function cardSize()
	if Kit.profile == "phone" then
		return 172, 226
	end
	return 192, 240
end

-- what an upgrade does now and at the next level
local function effectText(u, value, lvl)
	local L = Locale.get()
	if value == nil then
		return ""
	end
	if u.effect == "step" or u.effect == "walk" or u.effect == "shelf" then
		return math.floor(value * 100 + 0.5) .. "%"
	elseif u.effect == "cart" then
		return value .. " 📦"
	elseif u.effect == "delivery" then
		return value .. "s"
	elseif u.effect == "discount" then
		return "-" .. math.floor(value * 100 + 0.5) .. "%"
	elseif u.effect == "popularity" then
		return "+" .. Format.decimal(value, 2, L)
	elseif u.effect == "offline" then
		return value .. "h · " .. math.floor((u.pct[lvl + 1] or 0) * 100) .. "%"
	elseif u.effect == "autorestock" then
		return value > 0 and "✓" or "—"
	end
	return tostring(value)
end

local function needText(need)
	if not need then
		return ""
	end
	if need.kind == "level" then
		return t("ui.req_level", { level = need.level })
	elseif need.kind == "license" then
		return t("lic." .. need.id)
	elseif need.kind == "zone" then
		return t("zone." .. need.id)
	elseif need.kind == "staff" then
		return t("staff." .. need.id)
	elseif need.kind == "rating" then
		return "★ " .. need.rating
	elseif need.kind == "slots" then
		return t("ui.need_slots")
	elseif need.kind == "manager" then
		return t("ui.need_manager")
	end
	return ""
end

local function wiggle(frame)
	local s = frame
	Kit.tween(s, 0.05, { Rotation = 3 })
	task.delay(0.05, function()
		Kit.tween(s, 0.08, { Rotation = -3 })
		task.delay(0.08, function()
			Kit.tween(s, 0.08, { Rotation = 0 })
		end)
	end)
end

-- A card: o = { key, progress, icon, tint, title, sub, corner (level pips...), st, onBuy }
local function card(parent, order, o)
	local cw, ch = cardSize()
	local st = o.st
	if o.progress == nil then
		o.progress = st.state
	end
	local done = st.state == "owned" or st.state == "max" or st.state == "active"
	local locked = st.state == "locked"
	local c = Kit.card({ Name = "Card", Size = UDim2.fromOffset(cw, ch), LayoutOrder = order, Parent = parent, BackgroundColor3 = done and Color.hex("#F3EEE4") or Color.hex("#FFFBF3") })
	local stroke = c:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Color = st.state == "buy" and T.green or (done and T.paperDark or T.woodLight)
		stroke.Thickness = st.state == "buy" and 3 or 2
	end
	-- big icon on a round tile
	local tile = Kit.new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 8), Size = UDim2.fromOffset(64, 64), BackgroundColor3 = Color.hex(o.tint or "#EBDDC4"), Parent = c }, { Kit.corner(32) })
	Kit.label(o.icon or "🎁", { Parent = tile, Position = UDim2.fromOffset(10, 10), Size = UDim2.new(1, -20, 1, -20), TextScaled = true, TextXAlignment = Enum.TextXAlignment.Center, TextTransparency = locked and 0.45 or 0 })
	if locked then
		Kit.label("🔒", { Parent = tile, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, 6, 1, 4), Size = UDim2.fromOffset(28, 28), TextScaled = true })
	end
	if o.corner and o.corner ~= "" then
		local tag = Kit.new("Frame", { Position = UDim2.fromOffset(8, 8), Size = UDim2.fromOffset(0, 22), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = T.wood, Parent = c }, { Kit.corner(11), Kit.padding(8, 0) })
		Kit.label(o.corner, { Parent = tag, Size = UDim2.fromOffset(0, 22), AutomaticSize = Enum.AutomaticSize.X, TextSize = 13, FontFace = T.bold, TextColor3 = T.white, TextWrapped = false })
	end
	Kit.label(o.title or "", { Parent = c, Position = UDim2.fromOffset(6, 76), Size = UDim2.new(1, -12, 0, 22), TextSize = 16, FontFace = T.bold, TextXAlignment = Enum.TextXAlignment.Center, TextWrapped = false, TextTruncate = Enum.TextTruncate.AtEnd })
	Kit.label(o.sub or "", { Parent = c, Position = UDim2.fromOffset(8, 100), Size = UDim2.new(1, -16, 0, ch - 100 - 74), TextSize = 14, TextColor3 = T.muted, TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Top, TextTruncate = Enum.TextTruncate.AtEnd })
	-- one clear action at the bottom
	local L = Locale.get()
	local note = Kit.label("", { Parent = c, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -54), Size = UDim2.new(1, -12, 0, 18), TextSize = 14, FontFace = T.bold, TextXAlignment = Enum.TextXAlignment.Center, TextWrapped = false, TextTruncate = Enum.TextTruncate.AtEnd })
	local canBuy = Core.C.Data.canBuild()
	local text, style = "", "green"
	if st.state == "owned" then
		text, style = "✅ " .. t("ui.owned"), "plain"
	elseif st.state == "max" then
		text, style = "✅ MAX", "plain"
	elseif st.state == "active" then
		text, style = "📣 " .. t("ui.active"), "plain"
	elseif locked then
		text, style = "🔒 " .. needText(st.need), "dark"
	elseif st.state == "poor" then
		text, style = Format.yen(st.price, L), "plain"
		note.Text = t("ui.missing", { yen = Format.yen(st.missing, L) })
		note.TextColor3 = T.red
	else
		text, style = Format.yen(st.price, L), canBuy and "green" or "plain"
	end
	local btn = Kit.button(text, {
		parent = c, size = UDim2.new(1, -16, 0, 44), position = UDim2.new(0, 8, 1, -50), style = style, textSize = 17, radius = 12,
		onClick = function()
			if done then
				return
			end
			if not canBuy then
				Core.C.UI.toast(t("ui.only_owner"), "warning")
				wiggle(c)
				return
			end
			if locked then
				Core.C.UI.toast("🔒 " .. needText(st.need), "warning")
				wiggle(c)
				if Core.C.Audio then
					Core.C.Audio.play("error")
				end
				return
			end
			if st.state == "poor" then
				Core.C.UI.toast(t("ui.missing", { yen = Format.yen(st.missing, L) }), "warning")
				wiggle(c)
				if Core.C.Audio then
					Core.C.Audio.play("error")
				end
				return
			end
			lastBought = { key = o.key, progress = o.progress }
			Kit.bump(c, 1.06)
			if Core.C.Audio then
				Core.C.Audio.play("coin")
			end
			o.onBuy()
		end,
	})
	btn.Name = "Buy"
	if st.state == "poor" then
		btn.TextColor3 = T.red
	elseif done then
		btn.TextColor3 = T.green
		btn.AutoButtonColor = false
	end
	if lastBought and lastBought.key == o.key and lastBought.progress ~= o.progress then
		-- the purchase landed: the card springs once
		lastBought = nil
		Kit.popIn(c, 0.8)
		if Core.C.Audio then
			Core.C.Audio.play("sparkle")
		end
	end
	return c
end

-- a titled block of cards (a section of a tab)
local function section(scroll, order, title)
	local cw, ch = cardSize()
	if title then
		Kit.title(title, { Parent = scroll, Size = UDim2.new(1, -8, 0, 30), TextSize = 20, LayoutOrder = order })
	end
	local layout = Kit.grid(cw, ch, 10)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	local grid = Kit.new("Frame", { Name = "Cards", BackgroundTransparency = 1, Size = UDim2.new(1, -8, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = order + 1, Parent = scroll }, { layout })
	return grid
end

local function fill(grid, entries)
	ShopLogic.sort(entries)
	for i, e in ipairs(entries) do
		card(grid, i, e)
	end
end

local function pips(level, max)
	if max > 6 then
		return level .. "/" .. max
	end
	return string.rep("●", level) .. string.rep("○", max - level)
end

------------------------------------------------------------------ the tabs
local BUILD = {}

function BUILD.upgrades(scroll, w)
	local entries = {}
	for _, u in ipairs(Upgrades.list) do
		local st = ShopLogic.upgrade(w, u)
		local lvl = st.level
		local now = effectText(u, u.values[lvl + 1], lvl)
		local sub = t("upgdesc." .. u.effect) .. "\n" .. now
		if lvl < u.max then
			sub ..= " → " .. effectText(u, u.values[lvl + 2], lvl + 1)
		end
		table.insert(entries, {
			key = "u:" .. u.id, progress = lvl, icon = u.icon, tint = "#F4E3C2", title = t("upg." .. u.id), sub = sub, corner = pips(lvl, u.max), st = st, order = u.order,
			onBuy = function()
				NetDef.event("BuyUpgrade"):FireServer(u.id)
			end,
		})
	end
	fill(section(scroll, 10, nil), entries)
	local ads = {}
	for _, ad in ipairs(Ads.list) do
		table.insert(ads, {
			key = "a:" .. ad.id, progress = "", icon = ad.icon, tint = "#DDE6F2", title = t("ad." .. ad.id), sub = t("ui.ad_desc", { pop = ad.popularity }), st = ShopLogic.ad(w, ad), order = ad.order,
			onBuy = function()
				NetDef.event("BuyAd"):FireServer(ad.id)
			end,
		})
	end
	fill(section(scroll, 20, "📣 " .. t("ui.ads")), ads)
end

function BUILD.recipes(scroll, w, rating)
	local entries = {}
	for _, lic in ipairs(Licenses.list) do
		local dishes = {}
		for _, rid in ipairs(lic.recipes) do
			local r = Recipes.byId[rid]
			table.insert(dishes, (r and r.icon or "") .. " " .. t("rec." .. rid))
		end
		table.insert(entries, {
			key = "l:" .. lic.id, icon = BRANCH_ICON[lic.branch] or "🎫", tint = BRANCH_TINT[lic.branch], title = t("lic." .. lic.id), sub = table.concat(dishes, "\n"),
			st = ShopLogic.license(w, lic, rating), order = lic.order,
			onBuy = function()
				NetDef.event("BuyLicense"):FireServer(lic.id)
			end,
		})
	end
	fill(section(scroll, 10, nil), entries)
end

function BUILD.staff(scroll, w)
	local L = Locale.get()
	local staff = w.staff or {}
	local slots = ShopLogic.staffSlots(w, StaffCfg, GameConfig.MaxStaff)
	local can = Core.C.Data.canBuild()
	-- the team: train or let go
	if #staff > 0 then
		local cw, ch = cardSize()
		local grid = section(scroll, 10, t("ui.staff_team", { n = #staff, max = slots }))
		for i, s in ipairs(staff) do
			local cfg = StaffCfg.byId[s.role]
			local c = Kit.card({ Name = "Card", Size = UDim2.fromOffset(cw, ch), LayoutOrder = i, Parent = grid, BackgroundColor3 = Color.hex("#FFFBF3") })
			local tile = Kit.new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 10), Size = UDim2.fromOffset(72, 72), BackgroundColor3 = Color.hex("#DCE7F0"), Parent = c }, { Kit.corner(36) })
			Kit.label(cfg and cfg.icon or "🧑", { Parent = tile, Position = UDim2.fromOffset(10, 10), Size = UDim2.new(1, -20, 1, -20), TextScaled = true, TextXAlignment = Enum.TextXAlignment.Center })
			Kit.label(s.name, { Parent = c, Position = UDim2.fromOffset(8, 88), Size = UDim2.new(1, -16, 0, 22), TextSize = 17, FontFace = T.bold, TextXAlignment = Enum.TextXAlignment.Center, TextWrapped = false, TextTruncate = Enum.TextTruncate.AtEnd })
			Kit.label(t("staff." .. s.role) .. "\n" .. pips(s.lvl, StaffCfg.MaxTrainLevel) .. "  ·  " .. t("ui.salary", { yen = cfg and cfg.salary or 0 }), { Parent = c, Position = UDim2.fromOffset(8, 112), Size = UDim2.new(1, -16, 0, 50), TextSize = 14, TextColor3 = T.muted, TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Top })
			local row = Kit.new("Frame", { BackgroundTransparency = 1, Position = UDim2.new(0, 8, 1, -50), Size = UDim2.new(1, -16, 0, 44), Parent = c }, { Kit.list(Enum.FillDirection.Horizontal, 6, Enum.HorizontalAlignment.Center) })
			if cfg and s.lvl < StaffCfg.MaxTrainLevel then
				local price = Formulas.staffTrainCost(cfg.hire, s.lvl + 1)
				local rich = (w.yen or 0) >= price
				local b = Kit.button("⬆️ " .. Format.yen(price, L), { parent = row, size = UDim2.new(1, -50, 1, 0), style = (can and rich) and "gold" or "plain", textSize = 15, order = 1, onClick = function()
					if not can then
						return Core.C.UI.toast(t("ui.only_owner"), "warning")
					end
					if not rich then
						return Core.C.UI.toast(t("ui.missing", { yen = Format.yen(price - (w.yen or 0), L) }), "warning")
					end
					Kit.bump(c, 1.06)
					NetDef.event("TrainStaff"):FireServer(s.u)
				end })
				if not rich then
					b.TextColor3 = T.red
				end
			end
			Kit.button("✕", { parent = row, size = UDim2.fromOffset(44, 44), style = "plain", order = 2, onClick = function()
				if can then
					NetDef.event("FireStaff"):FireServer(s.u)
				end
			end })
		end
	end
	local entries = {}
	for _, cfg in ipairs(StaffCfg.list) do
		table.insert(entries, {
			key = "s:" .. cfg.id, progress = #staff, icon = cfg.icon, tint = "#DCE7F0", title = t("staff." .. cfg.id), sub = t("staffdesc." .. cfg.id) .. "\n" .. t("ui.salary", { yen = cfg.salary }),
			st = ShopLogic.hire(w, cfg, slots), order = cfg.order,
			onBuy = function()
				NetDef.event("HireStaff"):FireServer(cfg.id)
			end,
		})
	end
	fill(section(scroll, 30, "🤝 " .. t("ui.hire") .. "  (" .. #staff .. "/" .. slots .. ")"), entries)
end

local function expansionEntry(w, e)
	local sub = t("zonedesc." .. e.id)
	if e.ambience then
		sub ..= "\n" .. t("ui.reno_amb", { n = e.ambience })
	end
	return {
		key = "e:" .. e.id, icon = Icons.zone[e.id] or "🏗️", tint = e.reno and "#E6E1F2" or "#E2EBD6", title = t("zone." .. e.id), sub = sub,
		st = ShopLogic.expansion(w, e), order = e.order,
		onBuy = function()
			NetDef.event("BuyExpansion"):FireServer(e.id)
		end,
	}
end

function BUILD.rooms(scroll, w)
	local entries = {}
	for _, e in ipairs(Expansions.list) do
		if e.id ~= "zone_base" and not e.reno then
			table.insert(entries, expansionEntry(w, e))
		end
	end
	fill(section(scroll, 10, nil), entries)
end

function BUILD.reno(scroll, w)
	Kit.label(t("ui.reno_hint"), { Parent = scroll, Size = UDim2.new(1, -8, 0, 40), TextSize = 15, TextColor3 = T.muted, LayoutOrder = 1 })
	for gi, g in ipairs(RENO_GROUPS) do
		local entries, done, total = {}, 0, 0
		for _, e in ipairs(Expansions.list) do
			if e.reno == g.id then
				table.insert(entries, expansionEntry(w, e))
				total += 1
				if w.zones and w.zones[e.id] then
					done += 1
				end
			end
		end
		fill(section(scroll, gi * 10, t(g.key) .. "  " .. done .. "/" .. total), entries)
	end
end

------------------------------------------------------------------ the screen
local screen
screen = Base.make("Shop", "ui.shop", UDim2.fromScale(0.8, 0.84), function(content, s)
	if s.arg and BUILD[s.arg] then
		tab = s.arg
		s.arg = nil
	end
	local Data = Core.C.Data
	local w = Data.restaurant()
	local rating = Data.plotAttr("Rating") or 3
	local phone = Kit.profile == "phone"
	local tabs = {}
	for _, tb in ipairs(TABS) do
		table.insert(tabs, { id = tb.id, label = tb.icon .. " " .. t(tb.key), width = phone and 180 or (Kit.profile == "tablet" and 170 or 190), textSize = phone and 15 or 16 })
	end
	local _, _, badges = Kit.tabs(content, tabs, function(id)
		tab = id
		screen.refresh()
	end, tab, 44)
	local _, counts = ShopLogic.buyable(w, CFG, rating)
	if Data.canBuild() then
		for id, set in pairs(badges) do
			set(counts[id] or 0)
		end
	end
	-- the money to spend, in the title bar (on phones the window covers the wallet)
	local header = s.win.header
	local money = header:FindFirstChild("Money")
	if not money then
		money = Kit.new("Frame", { Name = "Money", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -60, 0.5, -1), Size = UDim2.fromOffset(0, 34), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = T.paper, Parent = header }, { Kit.corner(17), Kit.padding(14, 0), Kit.stroke(T.gold, 2, 0.1) })
		Kit.label("", { Name = "Amount", Parent = money, Size = UDim2.fromOffset(0, 34), AutomaticSize = Enum.AutomaticSize.X, TextSize = 20, FontFace = T.title, TextColor3 = T.wood, TextWrapped = false })
	end
	money:FindFirstChild("Amount").Text = Format.yen(Data.wallet(), Locale.get())
	local top = 50
	if not Data.canBuild() then
		Kit.label("🔒 " .. t("ui.only_owner"), { Parent = content, Position = UDim2.fromOffset(0, 48), Size = UDim2.new(1, 0, 0, 24), TextSize = 15, FontFace = T.bold, TextColor3 = T.red })
		top = 74
	end
	local scroll = Kit.scroll({ Name = "Cards_" .. tab, Position = UDim2.fromOffset(0, top), Size = UDim2.new(1, 0, 1, -top), Parent = content })
	BUILD[tab](scroll, w, rating)
end)

return screen
