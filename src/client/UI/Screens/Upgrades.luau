--!nonstrict
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local NetDef = require(Shared.Net)
local Locale = require(Shared.Locale)
local Format = require(Shared.Util.Format)
local Upgrades = require(Shared.Config.Upgrades)
local Ads = require(Shared.Config.Ads)
local Kit = require(script.Parent.Parent.Kit)
local Base = require(script.Parent.Parent.Base)
local Core = require(script.Parent.Parent.Parent.Core)

local t = Locale.t

local function effectText(u, value, lvl)
	local L = Locale.get()
	if u.effect == "step" or u.effect == "walk" or u.effect == "shelf" then
		return math.floor(value * 100 + 0.5) .. "%"
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

return Base.make("Upgrades", "ui.upgrades", UDim2.fromScale(0.66, 0.76), function(content)
	local w = Core.C.Data.world or {}
	local L = Locale.get()
	local scroll = Kit.scroll({ Parent = content })
	local can = Core.C.Data.canBuild()
	for _, u in ipairs(Upgrades.list) do
		local lvl = (w.upgrades and w.upgrades[u.id]) or 0
		local now = effectText(u, u.values[lvl + 1], lvl)
		local sub = t("upgdesc." .. u.effect) .. "\n" .. t("ui.level_of", { level = lvl, max = u.max }) .. "  ·  " .. now
		if lvl < u.max then
			sub ..= " → " .. effectText(u, u.values[lvl + 2], lvl + 1)
		end
		local card, right = Kit.row(u.icon, t("upg." .. u.id), sub, 86)
		card.Parent = scroll
		card.LayoutOrder = u.order
		if lvl >= u.max then
			Kit.label("✅ MAX", { Parent = right, Size = UDim2.fromOffset(150, 26), TextXAlignment = Enum.TextXAlignment.Right, FontFace = Kit.Theme.bold, TextColor3 = Kit.Theme.green })
		else
			local need = u.levels[lvl + 1]
			Kit.label(t("ui.req_level", { level = need }), { Parent = right, Size = UDim2.fromOffset(150, 18), TextSize = 14, TextXAlignment = Enum.TextXAlignment.Right })
			Kit.button(Format.yen(u.costs[lvl + 1], L), { parent = right, size = UDim2.fromOffset(150, 36), style = "gold", disabled = not can or (w.level or 1) < need, onClick = function()
				NetDef.event("BuyUpgrade"):FireServer(u.id)
			end })
		end
	end
	Kit.title(t("ui.ads"), { Parent = scroll, Size = UDim2.new(1, 0, 0, 34), LayoutOrder = 100 })
	local day = (w.stats and w.stats.days or 0) + 1
	for _, ad in ipairs(Ads.list) do
		local active = w.ads and w.ads[ad.id] == day
		local card, right = Kit.row(ad.icon, t("ad." .. ad.id), t("ui.ad_desc", { pop = ad.popularity }) .. "\n" .. t("ui.req_level", { level = ad.lv }), 76)
		card.Parent = scroll
		card.LayoutOrder = 100 + ad.order
		if active then
			Kit.label("📣 " .. t("ui.active"), { Parent = right, Size = UDim2.fromOffset(150, 26), TextXAlignment = Enum.TextXAlignment.Right, FontFace = Kit.Theme.bold })
		else
			Kit.button(Format.yen(ad.cost, L), { parent = right, size = UDim2.fromOffset(150, 36), style = "gold", disabled = not can or (w.level or 1) < ad.lv, onClick = function()
				NetDef.event("BuyAd"):FireServer(ad.id)
			end })
		end
	end
end)
