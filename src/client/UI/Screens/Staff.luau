--!nonstrict
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local NetDef = require(Shared.Net)
local Locale = require(Shared.Locale)
local Format = require(Shared.Util.Format)
local StaffCfg = require(Shared.Config.Staff)
local GameConfig = require(Shared.Config.GameConfig)
local Formulas = require(Shared.Logic.Formulas)
local Kit = require(script.Parent.Parent.Kit)
local Base = require(script.Parent.Parent.Base)
local Core = require(script.Parent.Parent.Parent.Core)

local t = Locale.t

local function slots(w)
	local n = StaffCfg.BaseSlots
	for zone, extra in pairs(StaffCfg.SlotsByZone) do
		if w.zones and w.zones[zone] then
			n += extra
		end
	end
	return math.min(n, GameConfig.MaxStaff)
end

return Base.make("Staff", "ui.staff", UDim2.fromScale(0.66, 0.78), function(content)
	local w = Core.C.Data.world or {}
	local L = Locale.get()
	local can = Core.C.Data.canBuild()
	local staff = w.staff or {}
	local scroll = Kit.scroll({ Parent = content })
	Kit.title(t("ui.staff_team", { n = #staff, max = slots(w) }), { Parent = scroll, Size = UDim2.new(1, 0, 0, 32), LayoutOrder = 0 })
	local hasManager = false
	for i, s in ipairs(staff) do
		local cfg = StaffCfg.byId[s.role]
		if cfg and cfg.manager then
			hasManager = true
		end
		local card, right = Kit.row(cfg and cfg.icon or "🧑", s.name .. " · " .. t("staff." .. s.role), t("ui.level_of", { level = s.lvl, max = StaffCfg.MaxTrainLevel }) .. "  ·  " .. t("ui.salary", { yen = cfg and cfg.salary or 0 }), 76)
		card.Parent = scroll
		card.LayoutOrder = i
		local row = Kit.new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(170, 36), Parent = right }, { Kit.list(Enum.FillDirection.Horizontal, 4, Enum.HorizontalAlignment.Right) })
		if s.lvl < StaffCfg.MaxTrainLevel then
			Kit.button("⬆️ " .. Format.yen(Formulas.staffTrainCost(cfg.hire, s.lvl + 1), L), { parent = row, size = UDim2.fromOffset(120, 34), style = "gold", textSize = 14, order = 1, disabled = not can, onClick = function()
				NetDef.event("TrainStaff"):FireServer(s.u)
			end })
		end
		Kit.button("✕", { parent = row, size = UDim2.fromOffset(40, 34), style = "plain", order = 2, disabled = not can, onClick = function()
			NetDef.event("FireStaff"):FireServer(s.u)
		end })
	end
	if hasManager and can then
		local auto = Core.C.Data.m("settings") and Core.C.Data.m("settings").autoDay
		Kit.button((auto and "✅ " or "⬜ ") .. t("ui.auto_day"), { parent = scroll, size = UDim2.fromOffset(260, 40), style = "plain", order = 50, onClick = function()
			NetDef.event("SetSetting"):FireServer("autoDay", not auto)
		end })
	end
	Kit.title(t("ui.hire"), { Parent = scroll, Size = UDim2.new(1, 0, 0, 32), LayoutOrder = 60 })
	for _, cfg in ipairs(StaffCfg.list) do
		local card, right = Kit.row(cfg.icon, t("staff." .. cfg.id), t("staffdesc." .. cfg.id) .. "\n" .. t("ui.req_level", { level = cfg.lv }) .. "  ·  " .. t("ui.salary", { yen = cfg.salary }), 86)
		card.Parent = scroll
		card.LayoutOrder = 60 + cfg.order
		Kit.button(Format.yen(cfg.hire, L), { parent = right, size = UDim2.fromOffset(150, 38), style = "green", disabled = not can or (w.level or 1) < cfg.lv or #staff >= slots(w), onClick = function()
			NetDef.event("HireStaff"):FireServer(cfg.id)
		end })
	end
end)
