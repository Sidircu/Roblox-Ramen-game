--!nonstrict
-- Daily quests, achievements, login streak, offline earnings and tutorial progress.
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Quests = require(Shared.Config.Quests)
local Achievements = require(Shared.Config.Achievements)
local DailyRewards = require(Shared.Config.DailyRewards)
local Upgrades = require(Shared.Config.Upgrades)
local Expansions = require(Shared.Config.Expansions)
local Formulas = require(Shared.Logic.Formulas)
local TableUtil = require(Shared.Util.TableUtil)
local Core = require(script.Parent.Parent.Core)

local Meta = {}

local function dayIndex()
	return math.floor(os.time() / 86400)
end

local function ensureQuests(player, d)
	local today = dayIndex()
	if d.meta.questDay == today and #d.meta.quests > 0 then
		return
	end
	local rng = Random.new(today * 7919 + player.UserId % 1000)
	local pool = table.clone(Quests.list)
	TableUtil.shuffle(pool, rng)
	d.meta.quests = {}
	for i = 1, Quests.PerDay do
		local q = pool[i]
		table.insert(d.meta.quests, { id = q.id, target = Formulas.questTarget(q.base, q.perLevel, d.level), progress = 0, claimed = false })
	end
	d.meta.questDay = today
	d.meta.questBonus = false
end

local function statValue(d, stat)
	if stat == "staff" then
		return #d.staff
	elseif stat == "level" then
		return d.level
	elseif stat == "licenses" then
		return TableUtil.count(d.licenses)
	elseif stat == "zones" then
		local n = 0
		for id in pairs(d.zones) do
			if string.sub(id, 1, 5) == "zone_" then
				n += 1
			end
		end
		return n
	elseif stat == "renos" then
		local n = 0
		for id in pairs(d.zones) do
			local e = Expansions.byId[id]
			if e and e.reno then
				n += 1
			end
		end
		return n
	elseif stat == "franchise" then
		return d.franchise.stars or 0
	end
	return d.stats[stat] or 0
end

local function checkAchievements(player, d)
	local changed = false
	for _, a in ipairs(Achievements.list) do
		if not d.meta.achievements[a.id] and statValue(d, a.stat) >= a.target then
			d.meta.achievements[a.id] = "done"
			changed = true
			Core.S.Net.notify(player, "msg.achievement", { name = "ach." .. a.stat, n = a.target }, "level")
		end
	end
	return changed
end

-- Generic progress hook. kind matches Quests[].kind and stats.
function Meta.event(player, kind, amount, info)
	if not player then
		return
	end
	local d = Core.S.Data.get(player)
	if not d then
		return
	end
	ensureQuests(player, d)
	local questChanged = false
	for _, q in ipairs(d.meta.quests) do
		local cfg = Quests.byId[q.id]
		if cfg and cfg.kind == kind and q.progress < q.target then
			q.progress = math.min(q.target, q.progress + (amount or 1))
			questChanged = true
			if q.progress >= q.target then
				Core.S.Net.notify(player, "msg.quest_done", { name = "quest." .. q.id, n = q.target }, "success")
			end
		end
	end
	local achChanged = checkAchievements(player, d)
	if questChanged or achChanged then
		Core.S.Data.changed(player, "meta")
	end
	local _ = info
end

function Meta.dayEnded(player)
	Meta.event(player, "day_end", 1)
end

local function claimQuest(player, id)
	local d = Core.S.Data.get(player)
	if not d then
		return
	end
	ensureQuests(player, d)
	for _, q in ipairs(d.meta.quests) do
		if q.id == id and q.progress >= q.target and not q.claimed then
			q.claimed = true
			Core.S.Economy.add(player, Quests.RewardYenPerLevel * d.level, "quest")
			Core.S.Economy.addSakura(player, Quests.RewardSakura)
			local all = true
			for _, other in ipairs(d.meta.quests) do
				if not other.claimed then
					all = false
				end
			end
			if all and not d.meta.questBonus then
				d.meta.questBonus = true
				Core.S.Economy.addSakura(player, Quests.BonusSakura)
				Core.S.Net.notify(player, "msg.quest_bonus", { n = Quests.BonusSakura }, "success")
			end
			Core.S.Data.changed(player, "meta")
			return
		end
	end
end

local function claimAchievement(player, id)
	local d = Core.S.Data.get(player)
	local a = Achievements.byId[id]
	if not d or not a or d.meta.achievements[id] ~= "done" then
		return
	end
	d.meta.achievements[id] = "claimed"
	Core.S.Economy.addSakura(player, a.sakura)
	Core.S.Data.changed(player, "meta")
end

local function claimDaily(player)
	local d = Core.S.Data.get(player)
	if not d then
		return
	end
	local today = dayIndex()
	local daily = d.meta.daily
	if daily.last == today then
		return Core.S.Net.notify(player, "msg.daily_done", nil, "info")
	end
	if daily.last == today - 1 then
		daily.streak = daily.streak % #DailyRewards.days + 1
	else
		daily.streak = 1
	end
	daily.last = today
	local reward = DailyRewards.days[daily.streak]
	if reward.yen then
		Core.S.Economy.add(player, math.floor(reward.yen * (1 + d.level / 10)), "daily")
	end
	if reward.sakura then
		Core.S.Economy.addSakura(player, reward.sakura)
	end
	if reward.item then
		d.inventory[reward.item] = (d.inventory[reward.item] or 0) + 1
		Core.S.Data.changed(player, "inventory")
	end
	Core.S.Data.changed(player, "meta")
	Core.S.Net.notify(player, "msg.daily_claimed", { day = daily.streak }, "success")
end

local function computeOffline(player, d)
	local lvl = d.upgrades.up_safe or 0
	if lvl <= 0 or (d.meta.lastSeen or 0) <= 0 then
		return
	end
	local up = Upgrades.byId.up_safe
	local maxHours = up.values[lvl + 1]
	local pct = up.pct[lvl + 1]
	local hours = math.min(maxHours, (os.time() - d.meta.lastSeen) / 3600)
	if hours < 0.05 then
		return
	end
	local history = d.stats.dayHistory or {}
	if #history == 0 then
		return
	end
	local sum = 0
	for _, v in ipairs(history) do
		sum += v
	end
	local perDay = sum / #history
	local hourly = perDay * 5 -- a service day lasts 12 real minutes
	local amount = Formulas.offlineEarnings(hourly, pct, hours)
	if amount > 0 then
		d.meta.offlinePending = (d.meta.offlinePending or 0) + amount
		d.meta.offlineHours = hours
		Core.S.Data.changed(player, "meta")
	end
end

local function claimOffline(player)
	local d = Core.S.Data.get(player)
	if not d or (d.meta.offlinePending or 0) <= 0 then
		return
	end
	local amount = d.meta.offlinePending
	d.meta.offlinePending = 0
	Core.S.Economy.add(player, amount, "offline")
	Core.S.Data.changed(player, "meta")
end

function Meta.Init()
	local Net = Core.S.Net
	Net.on("ClaimQuest", function(player, id)
		if type(id) == "string" then
			claimQuest(player, id)
		end
	end, 4)
	Net.on("ClaimAchievement", function(player, id)
		if type(id) == "string" then
			claimAchievement(player, id)
		end
	end, 6)
	Net.on("ClaimDaily", claimDaily, 2)
	Net.on("ClaimOffline", claimOffline, 2)
	local SETTINGS = {
		lang = function(v)
			return v == "auto" or v == "en" or v == "it"
		end,
		grid = function(v)
			return v == 1 or v == 5 or v == 10
		end,
		rot = function(v)
			return v == 90 or v == 45 or v == 15
		end,
		music = function(v)
			return type(v) == "number" and v >= 0 and v <= 1
		end,
		sfx = function(v)
			return type(v) == "number" and v >= 0 and v <= 1
		end,
		lowGfx = function(v)
			return type(v) == "boolean"
		end,
		autoDay = function(v)
			return type(v) == "boolean"
		end,
	}
	Net.on("SetSetting", function(player, key, value)
		local d = Core.S.Data.get(player)
		local check = SETTINGS[key]
		if d and check and check(value) then
			d.settings[key] = value
			Core.S.Data.changed(player, "settings")
		end
	end, 6)
	Net.on("TutorialStep", function(player, step)
		local d = Core.S.Data.get(player)
		if d and type(step) == "number" then
			d.meta.tutorial = math.floor(step)
			Core.S.Data.changed(player, "meta")
		end
	end, 4)
end

function Meta.Start()
	Core.S.Data.Loaded:Connect(function(player, d)
		ensureQuests(player, d)
		computeOffline(player, d)
		checkAchievements(player, d)
		d.meta.lastSeen = os.time()
		Core.S.Data.changed(player, "meta")
	end)
end

return Meta
