--!nonstrict
-- Free gifts for the minutes played in this session (Config/Rewards.Gifts). Timers tick every
-- second without rebuilding the list.
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local NetDef = require(Shared.Net)
local Locale = require(Shared.Locale)
local Format = require(Shared.Util.Format)
local Rewards = require(Shared.Config.Rewards)
local Ingredients = require(Shared.Config.Ingredients)
local Kit = require(script.Parent.Parent.Kit)
local Base = require(script.Parent.Parent.Base)
local Core = require(script.Parent.Parent.Parent.Core)

local t = Locale.t
local T = Kit.Theme
local player = Players.LocalPlayer

local function claimedSet()
	local set = {}
	for _, s in ipairs(string.split(player:GetAttribute("GiftsClaimed") or "", ",")) do
		if s ~= "" then
			set[tonumber(s)] = true
		end
	end
	return set
end

local function elapsed()
	local joined = player:GetAttribute("JoinedAt")
	if not joined then
		return 0
	end
	return workspace:GetServerTimeNow() - joined
end

local function rewardText(g)
	local me = Core.C.Data.me or {}
	if g.yen then
		return Format.yen(math.floor(g.yen * (1 + (me.level or 1) * Rewards.GiftYenPerLevel) + 0.5), Locale.get())
	elseif g.sakura then
		return "🌸 " .. g.sakura
	elseif g.boxes then
		local parts = {}
		for id, n in pairs(g.boxes) do
			local ing = Ingredients.byId[id]
			table.insert(parts, n .. "× " .. (ing and ing.icon or "📦"))
		end
		table.sort(parts)
		return "📦 " .. table.concat(parts, " ")
	end
	return ""
end

-- index of the next gift not yet claimed and seconds until it is ready (0 = ready now)
local function nextGift()
	local set = claimedSet()
	local e = elapsed()
	for i, g in ipairs(Rewards.Gifts) do
		if not set[i] then
			return i, math.max(0, g.min * 60 - e)
		end
	end
	return nil, nil
end

local screen = Base.make("Gifts", "ui.gifts", UDim2.fromScale(0.5, 0.66), function(content, s)
	s.rows = {}
	Kit.label(t("ui.gifts_hint"), { Parent = content, Size = UDim2.new(1, 0, 0, 24), TextSize = 15, TextColor3 = T.muted })
	local grid = Kit.new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 30), Size = UDim2.new(1, 0, 1, -30), Parent = content }, { Kit.grid(132, 132, 8) })
	local set = claimedSet()
	for i, g in ipairs(Rewards.Gifts) do
		local card = Kit.card({ LayoutOrder = i, Parent = grid })
		Kit.label("🎁", { Parent = card, Position = UDim2.fromOffset(0, 6), Size = UDim2.new(1, 0, 0, 36), TextScaled = true, TextXAlignment = Enum.TextXAlignment.Center })
		Kit.label(rewardText(g), { Parent = card, Position = UDim2.fromOffset(4, 44), Size = UDim2.new(1, -8, 0, 22), TextSize = 15, FontFace = T.bold, TextXAlignment = Enum.TextXAlignment.Center })
		local btn = Kit.button("", { parent = card, size = UDim2.new(1, -16, 0, 34), position = UDim2.new(0, 8, 1, -42), style = "plain", textSize = 15, onClick = function()
			NetDef.event("ClaimGift"):FireServer(i)
		end })
		s.rows[i] = { button = btn, gift = g, claimed = set[i] }
	end
	s.tick()
end)

-- updates the countdowns and buttons in place
function screen.tick()
	if not screen.rows then
		return
	end
	local e = elapsed()
	for _, row in pairs(screen.rows) do
		local left = row.gift.min * 60 - e
		if row.claimed then
			row.button.Text = "✅ " .. t("ui.claimed")
			row.button.BackgroundColor3 = T.paperDark
		elseif left <= 0 then
			row.button.Text = t("ui.claim")
			row.button.BackgroundColor3 = T.gold
			row.button.TextColor3 = T.ink
		else
			row.button.Text = "⏳ " .. Format.duration(left)
			row.button.BackgroundColor3 = T.paperDark
		end
	end
end

screen.nextGift = nextGift

task.spawn(function()
	while true do
		task.wait(1)
		if screen.visible() then
			screen.tick()
		end
	end
end)

player:GetAttributeChangedSignal("GiftsClaimed"):Connect(function()
	if screen.visible() then
		screen.refresh()
	end
end)

return screen
