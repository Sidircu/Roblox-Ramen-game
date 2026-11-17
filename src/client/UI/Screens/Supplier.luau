--!nonstrict
-- Supplier tablet: order boxes of ingredients and dish sets.
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local NetDef = require(Shared.Net)
local Locale = require(Shared.Locale)
local Format = require(Shared.Util.Format)
local Ingredients = require(Shared.Config.Ingredients)
local Recipes = require(Shared.Config.Recipes)
local Upgrades = require(Shared.Config.Upgrades)
local GameConfig = require(Shared.Config.GameConfig)
local Kit = require(script.Parent.Parent.Kit)
local Base = require(script.Parent.Parent.Base)
local Core = require(script.Parent.Parent.Parent.Core)

local t = Locale.t
local T = Kit.Theme
local cart = {}

local function unlocked(w, ing)
	if w.licenses and w.licenses[ing.license] then
		return true
	end
	for _, r in ipairs(Recipes.list) do
		if r.city and w.franchise and r.city == w.franchise.city and table.find(r.ing, ing.id) then
			return true
		end
	end
	return false
end

local function stock(w, g)
	local shelf, boxes = 0, 0
	for _, slots in pairs(w.shelves or {}) do
		for _, s in pairs(slots) do
			if s.g == g then
				shelf += s.n
			end
		end
	end
	for _, b in ipairs(w.storage or {}) do
		if b.g == g then
			boxes += 1
		end
	end
	return shelf, boxes
end

-- one box of every ingredient the dishes on the menu need and that is running low
local function cartForMenu(w)
	for id, m in pairs(w.menu or {}) do
		local r = Recipes.byId[id]
		if r and m.on then
			local need = table.clone(r.ing)
			if r.broth then
				table.insert(need, r.broth)
			end
			if r.rice then
				table.insert(need, "rice")
			end
			for _, g in ipairs(need) do
				local ing = Ingredients.byId[g]
				if ing and unlocked(w, ing) then
					local shelf, boxes = stock(w, g)
					if shelf + boxes * ing.units < ing.units / 2 then
						local q = cart[g] or { small = 0, big = 0 }
						q.small = math.max(q.small, 1)
						cart[g] = q
					end
				end
			end
		end
	end
end

local screen
screen = Base.make("Supplier", "ui.supplier", UDim2.fromScale(0.72, 0.78), function(content)
	local w = Core.C.Data.world or {}
	local discount = Upgrades.value(w.upgrades, "up_supplier")
	local L = Locale.get()
	local header = Kit.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30), Parent = content })
	Kit.label(t("ui.supplier_info", { seconds = Upgrades.value(w.upgrades, "up_delivery"), boxes = #(w.storage or {}) }), { Parent = header, Size = UDim2.new(1, 0, 1, 0), TextSize = 16, TextColor3 = T.muted })
	local scroll = Kit.scroll({ Position = UDim2.fromOffset(0, 34), Size = UDim2.new(1, 0, 1, -100), Parent = content }, Kit.grid(200, discount > 0 and 170 or 140, 8))
	local total = 0
	for _, ing in ipairs(Ingredients.list) do
		if unlocked(w, ing) then
			local q = cart[ing.id] or { small = 0, big = 0 }
			total += q.small * ing.price + math.floor(q.big * ing.price * GameConfig.BigBoxMultiplier * (1 - discount) + 0.5)
			local card = Kit.card({ Size = UDim2.fromOffset(200, 140), LayoutOrder = ing.order, Parent = scroll })
			Kit.label(ing.icon, { Parent = card, Size = UDim2.fromOffset(36, 36), Position = UDim2.fromOffset(8, 6), TextScaled = true })
			Kit.label(t("ing." .. ing.id), { Parent = card, Position = UDim2.fromOffset(50, 6), Size = UDim2.new(1, -56, 0, 22), TextSize = 17, FontFace = T.bold, TextTruncate = Enum.TextTruncate.AtEnd })
			local shelf, boxes = stock(w, ing.id)
			Kit.label("🗄️ " .. shelf .. "   📦 " .. boxes, { Parent = card, Position = UDim2.fromOffset(50, 28), Size = UDim2.new(1, -56, 0, 18), TextSize = 14, TextColor3 = T.muted })
			local function qtyRow(y, kind, label, price)
				Kit.label(label .. "  " .. Format.yen(price, L), { Parent = card, Position = UDim2.fromOffset(8, y), Size = UDim2.new(1, -16, 0, 18), TextSize = 14 })
				local row = Kit.new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(8, y + 20), Size = UDim2.new(1, -16, 0, 30), Parent = card }, { Kit.list(Enum.FillDirection.Horizontal, 6, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center) })
				Kit.button("−", { parent = row, size = UDim2.fromOffset(36, 28), style = "plain", order = 1, onClick = function()
					q[kind] = math.max(0, q[kind] - 1)
					cart[ing.id] = q
					screen.refresh()
				end })
				Kit.label(tostring(q[kind]), { Parent = row, Size = UDim2.fromOffset(34, 28), TextXAlignment = Enum.TextXAlignment.Center, FontFace = T.bold, LayoutOrder = 2 })
				Kit.button("+", { parent = row, size = UDim2.fromOffset(36, 28), style = "green", order = 3, onClick = function()
					q[kind] = math.min(30, q[kind] + 1)
					cart[ing.id] = q
					screen.refresh()
				end })
			end
			qtyRow(52, "small", t("ui.box_units", { n = ing.units }), ing.price)
			if discount > 0 then
				card.Size = UDim2.fromOffset(200, 170)
				qtyRow(104, "big", t("ui.big_box_units", { n = ing.units * GameConfig.BigBoxMultiplier }), math.floor(ing.price * GameConfig.BigBoxMultiplier * (1 - discount) + 0.5))
			end
		end
	end
	local footer = Kit.new("Frame", { BackgroundTransparency = 1, Position = UDim2.new(0, 0, 1, -58), Size = UDim2.new(1, 0, 0, 56), Parent = content })
	Kit.label(t("ui.total") .. ": " .. Format.yen(total, L), { Parent = footer, Size = UDim2.new(0.3, 0, 1, 0), TextSize = 22, FontFace = T.title })
	-- the easy way: everything the menu needs (the tutorial points at this button)
	local tut = Core.C.Tutorial
	local guided = tut and tut.currentKey and tut.currentKey() == "tut.buy"
	local menuBtn = Kit.button((guided and "👉 " or "") .. "🍜 " .. t("ui.cart_menu"), {
		parent = footer, size = UDim2.fromOffset(190, 46), position = UDim2.new(1, -600, 0, 5), style = guided and "gold" or "plain", textSize = 15,
		onClick = function()
			cartForMenu(w)
			screen.refresh()
		end,
	})
	if guided then
		Kit.stroke(T.red, 3).Parent = menuBtn
	end
	Kit.button("🍽️ " .. t("ui.buy_dishes", { n = GameConfig.DishSetSize, price = GameConfig.DishSetPrice }), {
		parent = footer, size = UDim2.fromOffset(220, 46), position = UDim2.new(1, -400, 0, 5), style = "gold", textSize = 15,
		onClick = function()
			NetDef.event("BuyDishes"):FireServer(1)
		end,
	})
	Kit.button("🚚 " .. t("ui.order"), {
		parent = footer, size = UDim2.fromOffset(170, 46), position = UDim2.new(1, -170, 0, 5), style = "green", disabled = total == 0,
		onClick = function()
			NetDef.event("OrderSupplies"):FireServer(cart)
			cart = {}
			screen.refresh()
		end,
	})
end)

return screen
