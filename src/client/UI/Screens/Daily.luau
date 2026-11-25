--!nonstrict
-- Daily login gift: a calendar of seven days that opens when you join and today's gift is still
-- there (not during the tutorial). Past days are ticked, today's card is gold with one big button,
-- the coming days show what waits for you tomorrow and after. Claimed by the server
-- (Services/Meta claimDaily: the streak goes back to day 1 if you skip a day). Also in Goals → Daily.
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local NetDef = require(Shared.Net)
local Locale = require(Shared.Locale)
local Format = require(Shared.Util.Format)
local Color = require(Shared.Util.Color)
local DailyRewards = require(Shared.Config.DailyRewards)
local Kit = require(script.Parent.Parent.Kit)
local Base = require(script.Parent.Parent.Base)
local Core = require(script.Parent.Parent.Parent.Core)

local t = Locale.t
local T = Kit.Theme

local function today()
	return math.floor(workspace:GetServerTimeNow() / 86400)
end

-- the day of the streak that today's gift belongs to, and whether it was already claimed
local function state()
	local me = Core.C.Data.me or {}
	local daily = me.meta and me.meta.daily or { streak = 0, last = 0 }
	local day = today()
	if daily.last == day then
		return daily.streak, true
	end
	if daily.last == day - 1 then
		return daily.streak % #DailyRewards.days + 1, false
	end
	return 1, false
end

local screen
screen = Base.make("Daily", "ui.daily_gift", UDim2.fromScale(0.68, 0.5), function(content)
	local me = Core.C.Data.me or {}
	local L = Locale.get()
	local current, claimed = state()
	Kit.label(claimed and ("✅ " .. t("ui.daily_tomorrow")) or t("ui.daily_hint"), { Parent = content, Size = UDim2.new(1, 0, 0, 30), TextSize = 18, FontFace = T.bold, TextXAlignment = Enum.TextXAlignment.Center })
	local row = Kit.new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 36), Size = UDim2.new(1, 0, 1, -100) }, {
		Kit.list(Enum.FillDirection.Horizontal, 6, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center),
	})
	row.Parent = content
	-- seven cards share the width (6 px between them), so the calendar fits phones and tablets
	local n = #DailyRewards.days
	for i, r in ipairs(DailyRewards.days) do
		local past = i < current or (i == current and claimed)
		local now = i == current and not claimed
		local c = Kit.card({ Size = UDim2.new(1 / n, -6, 0, now and 168 or 150), LayoutOrder = i, Parent = row, BackgroundColor3 = now and Color.hex("#FFF2CC") or (past and Color.hex("#EFE9DD") or Color.hex("#FFFBF3")) })
		local stroke = c:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Color = now and T.gold or (past and T.paperDark or T.woodLight)
			stroke.Thickness = now and 4 or 2
		end
		Kit.label(t("ui.day_n", { n = i }), { Parent = c, Position = UDim2.fromOffset(0, 6), Size = UDim2.new(1, 0, 0, 22), TextXAlignment = Enum.TextXAlignment.Center, FontFace = T.bold, TextSize = 16, TextWrapped = false })
		local icon = r.item and "🎁" or (r.yen and "💴" or "🌸")
		Kit.label(past and "✅" or icon, { Parent = c, Position = UDim2.new(0, 14, 0, 30), Size = UDim2.new(1, -28, 0, now and 64 or 52), TextScaled = true, TextXAlignment = Enum.TextXAlignment.Center })
		local reward = r.yen and Format.yen(math.floor(r.yen * (1 + (me.level or 1) / 10)), L) or ("🌸 " .. r.sakura)
		Kit.label(reward .. (r.item and "\n+ 🎎" or ""), { Parent = c, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 4, 1, -8), Size = UDim2.new(1, -8, 0, 40), TextSize = 15, FontFace = T.bold, TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = past and T.muted or T.ink })
		if now then
			Kit.popIn(c, 0.9)
		end
	end
	local b = Kit.button(claimed and t("ui.daily_tomorrow") or ("🎁 " .. t("ui.claim")), {
		parent = content, size = UDim2.new(0, 280, 0, 52), position = UDim2.new(0.5, -140, 1, -56), style = claimed and "secondary" or "reward", textSize = 20, disabled = claimed,
		onClick = function()
			NetDef.event("ClaimDaily"):FireServer()
			if Core.C.Audio then
				Core.C.Audio.play("gift")
			end
			task.delay(1.2, function()
				if screen.visible() then
					Core.C.UI.close("Daily")
				end
			end)
		end,
	})
	b.Name = "Claim"
end)

-- true when today's gift is still there
function screen.ready()
	local _, claimed = state()
	return not claimed
end

return screen
