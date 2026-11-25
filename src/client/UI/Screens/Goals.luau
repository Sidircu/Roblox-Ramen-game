--!nonstrict
-- Daily quests, achievements, login calendar, leaderboards and franchise.
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local NetDef = require(Shared.Net)
local Locale = require(Shared.Locale)
local Format = require(Shared.Util.Format)
local Quests = require(Shared.Config.Quests)
local Achievements = require(Shared.Config.Achievements)
local DailyRewards = require(Shared.Config.DailyRewards)
local Franchise = require(Shared.Config.Franchise)
local Kit = require(script.Parent.Parent.Kit)
local Base = require(script.Parent.Parent.Base)
local Core = require(script.Parent.Parent.Parent.Core)

local t = Locale.t
local T = Kit.Theme
local tab = "quests"
local board = nil
local boardTime = 0

local function statValue(me, stat)
	if stat == "staff" then
		return #(me.staff or {})
	elseif stat == "level" then
		return me.level or 1
	elseif stat == "licenses" then
		local n = 0
		for _ in pairs(me.licenses or {}) do
			n += 1
		end
		return n
	elseif stat == "zones" then
		local n = 0
		for id in pairs(me.zones or {}) do
			if string.sub(id, 1, 5) == "zone_" then
				n += 1
			end
		end
		return n
	elseif stat == "franchise" then
		return me.franchise and me.franchise.stars or 0
	end
	return me.stats and me.stats[stat] or 0
end

local screen
screen = Base.make("Goals", "ui.goals", UDim2.fromScale(0.68, 0.78), function(content)
	local me = Core.C.Data.me or {}
	local L = Locale.get()
	Kit.tabs(content, {
		{ id = "quests", label = t("ui.tab_quests"), width = 120 },
		{ id = "achievements", label = t("ui.tab_achievements"), width = 120 },
		{ id = "daily", label = t("ui.tab_daily"), width = 120 },
		{ id = "leaderboard", label = t("ui.tab_leaderboard"), width = 120 },
		{ id = "franchise", label = t("ui.tab_franchise"), width = 120 },
	}, function(id)
		tab = id
		screen.refresh()
	end, tab)
	local scroll = Kit.scroll({ Position = UDim2.fromOffset(0, 46), Size = UDim2.new(1, 0, 1, -46), Parent = content })
	if tab == "quests" then
		for i, q in ipairs(me.meta and me.meta.quests or {}) do
			local cfg = Quests.byId[q.id]
			local card, right = Kit.row("🎯", t("quest." .. q.id, { n = q.target }), q.progress .. " / " .. q.target, 76)
			card.Parent = scroll
			card.LayoutOrder = i
			local _, fill = Kit.bar(q.progress / q.target, T.green, { Parent = card, Position = UDim2.new(0, 70, 1, -16), Size = UDim2.new(1, -260, 0, 8) })
			local _ = fill
			if q.claimed then
				Kit.label("✅", { Parent = right, Size = UDim2.fromOffset(40, 30), TextScaled = true })
			else
				Kit.button(t("ui.claim"), { parent = right, size = UDim2.fromOffset(120, 36), style = "gold", disabled = q.progress < q.target, onClick = function()
					NetDef.event("ClaimQuest"):FireServer(q.id)
				end })
			end
			local _2 = cfg
		end
		Kit.label(t("ui.quests_reward", { yen = Quests.RewardYenPerLevel * (me.level or 1), sakura = Quests.RewardSakura, bonus = Quests.BonusSakura }), { Parent = scroll, Size = UDim2.new(1, 0, 0, 44), TextSize = 15, TextColor3 = T.muted, LayoutOrder = 10 })
	elseif tab == "achievements" then
		for _, a in ipairs(Achievements.list) do
			local state = me.meta and me.meta.achievements and me.meta.achievements[a.id]
			local value = statValue(me, a.stat)
			local card, right = Kit.row(state and "🏆" or "🔒", t("ach." .. a.stat, { n = a.target }), Format.number(math.min(value, a.target), L) .. " / " .. Format.number(a.target, L) .. "  ·  🌸" .. a.sakura, 64)
			card.Parent = scroll
			if state == "done" then
				Kit.button(t("ui.claim"), { parent = right, size = UDim2.fromOffset(120, 34), style = "gold", onClick = function()
					NetDef.event("ClaimAchievement"):FireServer(a.id)
				end })
			elseif state == "claimed" then
				Kit.label("✅", { Parent = right, Size = UDim2.fromOffset(34, 30), TextScaled = true })
			end
		end
	elseif tab == "daily" then
		local daily = me.meta and me.meta.daily or { streak = 0, last = 0 }
		local today = math.floor(workspace:GetServerTimeNow() / 86400)
		local claimedToday = daily.last == today
		local nextDay = claimedToday and daily.streak or ((daily.last == today - 1) and (daily.streak % 7 + 1) or 1)
		local row = Kit.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 130) }, { Kit.list(Enum.FillDirection.Horizontal, 6, Enum.HorizontalAlignment.Center) })
		row.Parent = scroll
		for i, r in ipairs(DailyRewards.days) do
			local c = Kit.card({ Size = UDim2.fromOffset(92, 120), LayoutOrder = i, Parent = row })
			if i == nextDay then
				c:FindFirstChildOfClass("UIStroke").Color = T.gold
				c:FindFirstChildOfClass("UIStroke").Thickness = 3
			end
			Kit.label(t("ui.day_n", { n = i }), { Parent = c, Size = UDim2.new(1, 0, 0, 22), TextXAlignment = Enum.TextXAlignment.Center, FontFace = T.bold, TextSize = 15 })
			local reward = r.yen and Format.yen(math.floor(r.yen * (1 + (me.level or 1) / 10)), L) or ("🌸" .. r.sakura)
			Kit.label(r.yen and "💴" or "🌸", { Parent = c, Position = UDim2.fromOffset(0, 24), Size = UDim2.new(1, 0, 0, 44), TextScaled = true, TextXAlignment = Enum.TextXAlignment.Center })
			Kit.label(reward .. (r.item and " +🎁" or ""), { Parent = c, Position = UDim2.fromOffset(2, 74), Size = UDim2.new(1, -4, 0, 40), TextSize = 14, TextXAlignment = Enum.TextXAlignment.Center })
		end
		Kit.button(claimedToday and t("ui.daily_tomorrow") or t("ui.claim"), { parent = scroll, size = UDim2.new(1, -8, 0, 46), style = "reward", disabled = claimedToday, onClick = function()
			NetDef.event("ClaimDaily"):FireServer()
		end })
	elseif tab == "leaderboard" then
		if not board or os.clock() - boardTime > 60 then
			boardTime = os.clock()
			task.spawn(function()
				local ok, result = pcall(function()
					return NetDef.func("GetLeaderboard"):InvokeServer()
				end)
				if ok and result then
					board = result
					if screen.visible() and tab == "leaderboard" then
						screen.refresh()
					end
				end
			end)
		end
		for _, stat in ipairs({ "likes", "dishes", "earned" }) do
			Kit.title(t("lb." .. stat), { Parent = scroll, Size = UDim2.new(1, 0, 0, 30) })
			for _, entry in ipairs(board and board[stat] or {}) do
				local row = Kit.card({ Size = UDim2.new(1, -8, 0, 34), Parent = scroll })
				Kit.label("#" .. entry.rank .. "  " .. entry.name, { Parent = row, Position = UDim2.fromOffset(10, 0), Size = UDim2.new(0.6, 0, 1, 0), FontFace = T.bold })
				Kit.label(stat == "earned" and Format.yen(entry.value, L) or Format.number(entry.value, L), { Parent = row, Position = UDim2.fromScale(0.6, 0), Size = UDim2.new(0.38, 0, 1, 0), TextXAlignment = Enum.TextXAlignment.Right })
			end
		end
	elseif tab == "franchise" then
		local w = Core.C.Data.restaurant()
		local stars = w.franchise and w.franchise.stars or 0
		local nextCity = nil
		for _, c in ipairs(Franchise.list) do
			if c.star == stars + 1 then
				nextCity = c
			end
		end
		Kit.label(t("ui.franchise_info", { stars = stars, yen = math.floor(stars * Franchise.YenPerStar * 100), xp = math.floor(stars * Franchise.XpPerStar * 100) }), { Parent = scroll, Size = UDim2.new(1, 0, 0, 50), TextSize = 17, LayoutOrder = 1 })
		-- first what the next city asks for, ticked off one by one, and the button
		local step = Franchise.nextStep(stars)
		if nextCity and step then
			local rating = Core.C.Data.plotAttr("Rating") or 3
			local level = w.level or 1
			local all = true
			local order = 10
			local function need(ok, text)
				all = all and ok
				order += 1
				Kit.label((ok and "✅ " or "🔒 ") .. text, { Parent = scroll, Size = UDim2.new(1, -8, 0, 26), TextSize = 16, FontFace = ok and T.body or T.bold, TextColor3 = ok and T.muted or T.ink, LayoutOrder = order })
			end
			Kit.title(t("ui.franchise_next", { city = "city." .. nextCity.id }), { Parent = scroll, Size = UDim2.new(1, -8, 0, 30), TextSize = 20, LayoutOrder = 10 })
			need(level >= step.level, t("ui.req_level", { level = step.level }) .. "  (" .. level .. ")")
			need(rating >= step.rating, "★ " .. Format.decimal(step.rating, 1, L) .. "  (" .. Format.decimal(rating, 1, L) .. ")")
			for _, z in ipairs(step.zones) do
				need(w.zones and w.zones[z] == true, t("zone." .. z))
			end
			local b = Kit.button("🗾 " .. t("ui.franchise_open", { city = "city." .. nextCity.id }), { parent = scroll, size = UDim2.new(1, -8, 0, 50), style = all and "buy" or "secondary", disabled = Core.C.Data.role() ~= "owner" or not all, onClick = function()
				NetDef.event("Franchise"):FireServer(nextCity.id)
			end })
			b.LayoutOrder = 50
		end
		-- then the cities
		for i, c in ipairs(Franchise.list) do
			local mark = (w.franchise and w.franchise.city == c.id) and "📍" or ((c.star <= stars) and "✅" or "🔒")
			local card = Kit.row(mark, t("city." .. c.id), t("citydesc." .. c.id), 60)
			card.LayoutOrder = 100 + i
			card.Parent = scroll
		end
	end
end)

return screen
