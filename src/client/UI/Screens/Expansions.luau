--!nonstrict
-- Expansions screen: new rooms and floors ("zones" tab) and renovations that turn the plain
-- starting restaurant into the detailed one ("reno" tab, grouped by exterior/interior/furniture).
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
local tab = "zones"
local GROUPS = {
	{ id = "exterior", key = "ui.reno_exterior" },
	{ id = "interior", key = "ui.reno_interior" },
	{ id = "furniture", key = "ui.reno_furniture" },
}

local function row(scroll, e, w, can, L, order)
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
	if e.ambience then
		req ..= "  ·  " .. t("ui.reno_amb", { n = e.ambience })
	end
	local card, right = Kit.row(Icons.zone[e.id] or "🏗️", t("zone." .. e.id), t("zonedesc." .. e.id) .. "\n" .. req, 86)
	card.Parent = scroll
	card.LayoutOrder = order
	if owned then
		Kit.label("✅ " .. t("ui.owned"), { Parent = right, Size = UDim2.fromOffset(150, 26), TextXAlignment = Enum.TextXAlignment.Right, FontFace = Kit.Theme.bold, TextColor3 = Kit.Theme.green })
	else
		Kit.button(Format.yen(e.cost, L), { parent = right, size = UDim2.fromOffset(150, 40), style = "gold", disabled = not can or not reqOk or (w.level or 1) < e.lv, onClick = function()
			NetDef.event("BuyExpansion"):FireServer(e.id)
		end })
	end
end

local screen
screen = Base.make("Expansions", "ui.expansions", UDim2.fromScale(0.66, 0.76), function(content)
	local w = Core.C.Data.world or {}
	local L = Locale.get()
	local can = Core.C.Data.canBuild()
	local done, total = 0, 0
	for _, e in ipairs(Expansions.list) do
		if e.reno then
			total += 1
			if w.zones and w.zones[e.id] then
				done += 1
			end
		end
	end
	Kit.tabs(content, {
		{ id = "zones", label = t("ui.tab_zones"), width = 150 },
		{ id = "reno", label = t("ui.tab_reno") .. " " .. done .. "/" .. total, width = 210 },
	}, function(id)
		tab = id
		screen.refresh()
	end, tab)
	local scroll = Kit.scroll({ Position = UDim2.fromOffset(0, 46), Size = UDim2.new(1, 0, 1, -46), Parent = content })
	if tab == "zones" then
		for _, e in ipairs(Expansions.list) do
			if e.id ~= "zone_base" and not e.reno then
				row(scroll, e, w, can, L, e.order)
			end
		end
		return
	end
	-- renovations: a short hint, then one block per group
	Kit.label(t("ui.reno_hint"), { Parent = scroll, Size = UDim2.new(1, -8, 0, 40), TextWrapped = true, TextSize = 15, TextColor3 = Kit.Theme.muted, LayoutOrder = 0 })
	for gi, g in ipairs(GROUPS) do
		local base = gi * 1000
		Kit.title(t(g.key), { Parent = scroll, Size = UDim2.new(1, -8, 0, 30), TextSize = 20, LayoutOrder = base })
		for _, e in ipairs(Expansions.list) do
			if e.reno == g.id then
				row(scroll, e, w, can, L, base + e.order)
			end
		end
	end
end)

return screen
