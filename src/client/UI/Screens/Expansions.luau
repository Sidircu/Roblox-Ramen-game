--!nonstrict
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local NetDef = require(Shared.Net)
local Locale = require(Shared.Locale)
local Format = require(Shared.Util.Format)
local Expansions = require(Shared.Config.Expansions)
local Kit = require(script.Parent.Parent.Kit)
local Base = require(script.Parent.Parent.Base)
local Icons = require(script.Parent.Parent.Icons)
local Core = require(script.Parent.Parent.Parent.Core)

local t = Locale.t

return Base.make("Expansions", "ui.expansions", UDim2.fromScale(0.66, 0.76), function(content)
	local w = Core.C.Data.world or {}
	local L = Locale.get()
	local can = Core.C.Data.canBuild()
	local scroll = Kit.scroll({ Parent = content })
	for _, e in ipairs(Expansions.list) do
		if e.id ~= "zone_base" then
			local owned = w.zones and w.zones[e.id]
			local req = t("ui.req_level", { level = e.lv })
			local reqOk = true
			for _, r in ipairs(e.requires) do
				if r ~= "zone_base" then
					req ..= "  ·  " .. t("zone." .. r)
				end
				if not (w.zones and w.zones[r]) then
					reqOk = false
				end
			end
			local card, right = Kit.row(Icons.zone[e.id] or "🏗️", t("zone." .. e.id), t("zonedesc." .. e.id) .. "\n" .. req, 86)
			card.Parent = scroll
			card.LayoutOrder = e.order
			if owned then
				Kit.label("✅ " .. t("ui.owned"), { Parent = right, Size = UDim2.fromOffset(150, 26), TextXAlignment = Enum.TextXAlignment.Right, FontFace = Kit.Theme.bold, TextColor3 = Kit.Theme.green })
			else
				Kit.button(Format.yen(e.cost, L), { parent = right, size = UDim2.fromOffset(150, 40), style = "gold", disabled = not can or not reqOk or (w.level or 1) < e.lv, onClick = function()
					NetDef.event("BuyExpansion"):FireServer(e.id)
				end })
			end
		end
	end
end)
