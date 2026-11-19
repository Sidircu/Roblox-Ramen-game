--!nonstrict
-- Robux shop: game passes and products (only the ones with an id in Config/Monetization).
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local NetDef = require(Shared.Net)
local Locale = require(Shared.Locale)
local Monetization = require(Shared.Config.Monetization)
local Kit = require(script.Parent.Parent.Kit)
local Base = require(script.Parent.Parent.Base)

local t = Locale.t
local ICON = { gp_vip = "👑", gp_double_yen = "💴", gp_big_tray = "🍱", gp_express = "🚀", gp_starter = "🎁", dp_rush_hour = "🔔", dp_golden_sign = "🌟" }

return Base.make("Premium", "ui.premium", UDim2.fromScale(0.6, 0.72), function(content)
	local scroll = Kit.scroll({ Parent = content })
	local any = false
	for i, gp in ipairs(Monetization.GamePasses) do
		if gp.assetId ~= 0 then
			any = true
			local card, right = Kit.row(ICON[gp.id] or "🎟️", t("gp." .. gp.id), t("gpdesc." .. gp.id), 76)
			card.Parent = scroll
			card.LayoutOrder = i
			Kit.button("R$", { parent = right, size = UDim2.fromOffset(120, 38), style = "green", onClick = function()
				NetDef.event("BuyWithRobux"):FireServer("gamepass", gp.id)
			end })
		end
	end
	for i, p in ipairs(Monetization.Products) do
		if p.productId ~= 0 then
			any = true
			local icon = ICON[p.id] or (string.find(p.id, "sakura") and "🌸" or "💴")
			local card, right = Kit.row(icon, t("dp." .. p.id), t("dpdesc." .. p.id), 70)
			card.Parent = scroll
			card.LayoutOrder = 100 + i
			Kit.button("R$", { parent = right, size = UDim2.fromOffset(120, 38), style = "green", onClick = function()
				NetDef.event("BuyWithRobux"):FireServer("product", p.id)
			end })
		end
	end
	if not any then
		Kit.label("🛒 " .. t("ui.shop_soon"), { Parent = scroll, Size = UDim2.new(1, 0, 0, 80), TextSize = 20, TextXAlignment = Enum.TextXAlignment.Center })
	end
end)
