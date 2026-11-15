--!nonstrict
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local NetDef = require(Shared.Net)
local Locale = require(Shared.Locale)
local Format = require(Shared.Util.Format)
local Licenses = require(Shared.Config.Licenses)
local Recipes = require(Shared.Config.Recipes)
local Kit = require(script.Parent.Parent.Kit)
local Base = require(script.Parent.Parent.Base)
local Core = require(script.Parent.Parent.Parent.Core)

local t = Locale.t
local BRANCH_ICON = { base = "🏠", sushi = "🍣", ramen = "🍜", extra = "🥟", master = "🎌" }

return Base.make("Licenses", "ui.licenses", UDim2.fromScale(0.66, 0.76), function(content)
	local w = Core.C.Data.world or {}
	local L = Locale.get()
	local scroll = Kit.scroll({ Parent = content })
	for _, lic in ipairs(Licenses.list) do
		local owned = w.licenses and w.licenses[lic.id]
		local icons = {}
		for _, rid in ipairs(lic.recipes) do
			local r = Recipes.byId[rid]
			table.insert(icons, (r and r.icon or "") .. " " .. t("rec." .. rid))
		end
		local req = t("ui.req_level", { level = lic.level })
		if lic.rating > 0 then
			req ..= "  ·  ★" .. lic.rating
		end
		for _, rq in ipairs(lic.requires) do
			if rq ~= "lic_base" then
				req ..= "  ·  " .. t("lic." .. rq)
			end
		end
		local card, right = Kit.row(BRANCH_ICON[lic.branch] or "🎫", t("lic." .. lic.id), table.concat(icons, ", ") .. "\n" .. req, 86)
		card.Parent = scroll
		card.LayoutOrder = lic.order
		if owned then
			Kit.label("✅ " .. t("ui.owned"), { Parent = right, Size = UDim2.fromOffset(160, 26), TextXAlignment = Enum.TextXAlignment.Right, FontFace = Kit.Theme.bold, TextColor3 = Kit.Theme.green })
		else
			local can = (w.level or 1) >= lic.level and Core.C.Data.canBuild()
			for _, rq in ipairs(lic.requires) do
				if not (w.licenses and w.licenses[rq]) then
					can = false
				end
			end
			Kit.button(Format.yen(lic.cost, L), { parent = right, size = UDim2.fromOffset(150, 40), style = "gold", disabled = not can, onClick = function()
				NetDef.event("BuyLicense"):FireServer(lic.id)
			end })
		end
	end
end)
