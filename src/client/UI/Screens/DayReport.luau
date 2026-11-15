--!nonstrict
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local NetDef = require(Shared.Net)
local Locale = require(Shared.Locale)
local Format = require(Shared.Util.Format)
local Kit = require(script.Parent.Parent.Kit)
local Base = require(script.Parent.Parent.Base)
local Core = require(script.Parent.Parent.Parent.Core)

local t = Locale.t
local T = Kit.Theme

local screen
screen = Base.make("DayReport", "ui.report", UDim2.fromScale(0.42, 0.74), function(content)
	local r = screen.arg or (Core.C.Data.day and Core.C.Data.day.report)
	if not r then
		return
	end
	local L = Locale.get()
	local list = Kit.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, -60), Parent = content }, { Kit.list(Enum.FillDirection.Vertical, 4) })
	Kit.title(t("ui.day_n", { n = r.day }), { Parent = list, Size = UDim2.new(1, 0, 0, 34), LayoutOrder = 0 })
	local rows = {
		{ "💴", "ui.r_sales", Format.yen(r.sales, L), T.green },
		{ "💝", "ui.r_tips", Format.yen(r.tips, L), T.green },
		{ "📦", "ui.r_supplies", "-" .. Format.yen(r.supplies, L), T.red },
		{ "👥", "ui.r_salaries", "-" .. Format.yen(r.salaries, L), T.red },
		{ "🔨", "ui.r_build", "-" .. Format.yen(r.build + r.other, L), T.red },
		{ "📈", "ui.r_profit", Format.yen(r.profit, L), r.profit >= 0 and T.green or T.red },
		{ "🙂", "ui.r_customers", tostring(r.customers), T.ink },
		{ "🍜", "ui.r_served", tostring(r.served), T.ink },
		{ "😠", "ui.r_walkouts", tostring(r.walkouts), T.ink },
		{ "⭐", "ui.r_rating", Format.decimal(r.rating, 1, L), T.ink },
	}
	if r.best then
		table.insert(rows, { "🏆", "ui.r_best", t("rec." .. r.best) .. " ×" .. r.bestCount, T.ink })
	end
	for i, row in ipairs(rows) do
		local f = Kit.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 28), LayoutOrder = i, Parent = list })
		Kit.label(row[1] .. "  " .. t(row[2]), { Parent = f, Size = UDim2.new(0.6, 0, 1, 0), TextSize = 18 })
		Kit.label(row[3], { Parent = f, Position = UDim2.fromScale(0.6, 0), Size = UDim2.new(0.4, 0, 1, 0), TextSize = 18, FontFace = T.bold, TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = row[4] })
	end
	Kit.button("🌅 " .. t("ui.next_day"), { parent = content, size = UDim2.new(1, 0, 0, 50), position = UDim2.new(0, 0, 1, -52), style = "green", onClick = function()
		NetDef.event("SetDayState"):FireServer("next")
		Core.C.UI.close("DayReport")
	end })
end)

return screen
