--!nonstrict
-- Menu board: enable dishes, set prices (-30%..+30%), recipe book with mastery.
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local NetDef = require(Shared.Net)
local Locale = require(Shared.Locale)
local Format = require(Shared.Util.Format)
local Recipes = require(Shared.Config.Recipes)
local Licenses = require(Shared.Config.Licenses)
local Franchise = require(Shared.Config.Franchise)
local Formulas = require(Shared.Logic.Formulas)
local Kit = require(script.Parent.Parent.Kit)
local Base = require(script.Parent.Parent.Base)
local Core = require(script.Parent.Parent.Parent.Core)

local t = Locale.t
local T = Kit.Theme
local tab = "menu"

local function isUnlocked(w, r)
	if r.city then
		return w.franchise and w.franchise.city == r.city and (w.level or 1) >= Franchise.RegionalLevel
	end
	return w.licenses and w.licenses[r.license] == true
end

local function licenseOf(recipeId)
	for _, l in ipairs(Licenses.list) do
		if table.find(l.recipes, recipeId) then
			return l
		end
	end
	return nil
end

local screen
screen = Base.make("Menu", "ui.menu", UDim2.fromScale(0.66, 0.76), function(content)
	local w = Core.C.Data.restaurant()
	local L = Locale.get()
	Kit.tabs(content, { { id = "menu", label = t("ui.tab_menu") }, { id = "book", label = t("ui.tab_book") } }, function(id)
		tab = id
		screen.refresh()
	end, tab)
	local scroll = Kit.scroll({ Position = UDim2.fromOffset(0, 46), Size = UDim2.new(1, 0, 1, -46), Parent = content })
	local canEdit = Core.C.Data.canBuild()
	for _, r in ipairs(Recipes.list) do
		local unlocked = isUnlocked(w, r)
		local served = (w.mastery and w.mastery[r.id]) or 0
		local mastery = Formulas.masteryLevel(served)
		if tab == "menu" and unlocked then
			local m = (w.menu and w.menu[r.id]) or { on = true, price = 1 }
			local price = Formulas.dishPrice(r.price, served, m.price)
			local stars = string.rep("★", mastery) .. string.rep("☆", 5 - mastery)
			local card, right = Kit.row(r.icon, t("rec." .. r.id), Format.yen(price, L) .. "  ·  " .. t("station." .. r.station) .. "  ·  " .. stars, 74)
			card.Parent = scroll
			card.LayoutOrder = r.order
			local controls = Kit.new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(170, 30), Parent = right }, { Kit.list(Enum.FillDirection.Horizontal, 4, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center) })
			Kit.button("−", { parent = controls, size = UDim2.fromOffset(30, 28), style = "plain", order = 1, disabled = not canEdit, onClick = function()
				NetDef.event("SetMenu"):FireServer(r.id, nil, m.price - 0.1)
			end })
			Kit.label(math.floor(m.price * 100 + 0.5) .. "%", { Parent = controls, Size = UDim2.fromOffset(52, 28), TextXAlignment = Enum.TextXAlignment.Center, FontFace = T.bold, LayoutOrder = 2 })
			Kit.button("+", { parent = controls, size = UDim2.fromOffset(30, 28), style = "plain", order = 3, disabled = not canEdit, onClick = function()
				NetDef.event("SetMenu"):FireServer(r.id, nil, m.price + 0.1)
			end })
			Kit.button(m.on and t("ui.on") or t("ui.off"), { parent = controls, size = UDim2.fromOffset(52, 28), style = m.on and "green" or "plain", order = 4, disabled = not canEdit, onClick = function()
				NetDef.event("SetMenu"):FireServer(r.id, not m.on, nil)
			end })
		elseif tab == "book" then
			local sub
			if unlocked then
				local nextT = Formulas.MasteryThresholds[mastery + 1]
				sub = t("ui.mastery", { level = mastery }) .. "  ·  " .. served .. (nextT and ("/" .. nextT) or "") .. "  ·  " .. t("ui.ingredients") .. ": "
				local names = {}
				for _, g in ipairs(r.ing) do
					table.insert(names, t("ing." .. g))
				end
				sub ..= table.concat(names, ", ")
			elseif r.city then
				sub = "🔒 " .. t("ui.regional", { city = "city." .. r.city })
			else
				local l = licenseOf(r.id)
				sub = "🔒 " .. (l and t("lic." .. l.id) or "")
			end
			local card = Kit.row(unlocked and r.icon or "🔒", t("rec." .. r.id), sub, 74)
			card.Parent = scroll
			card.LayoutOrder = r.order
			if mastery >= 5 then
				card.BackgroundColor3 = Kit.Theme.gold
			end
		end
	end
end)

return screen
