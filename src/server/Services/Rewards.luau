--!nonstrict
-- Roblox-style rewards: free gifts for the minutes played in this session, redeemable codes and
-- the leaderstats shown in the player list (yen and level).
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local RewardsCfg = require(Shared.Config.Rewards)
local Ingredients = require(Shared.Config.Ingredients)
local Uid = require(Shared.Util.Uid)
local Core = require(script.Parent.Parent.Core)

local Rewards = {}
local claimed = {} -- [player] = { [index] = true }

local function publishClaimed(player)
	local list = {}
	for i in pairs(claimed[player] or {}) do
		table.insert(list, tostring(i))
	end
	table.sort(list)
	player:SetAttribute("GiftsClaimed", table.concat(list, ","))
end

-- Gives a reward table { yen, sakura, boxes } to a player; returns false without data
local function grant(player, reward)
	local d = Core.S.Data.get(player)
	if not d then
		return false
	end
	if reward.yen then
		local yen = math.floor(reward.yen * (1 + (d.level or 1) * (RewardsCfg.GiftYenPerLevel or 0)) + 0.5)
		Core.S.Economy.add(player, yen, "gift")
	end
	if reward.sakura then
		Core.S.Economy.addSakura(player, reward.sakura)
	end
	if reward.boxes then
		if player == Core.S.Session.owner then
			for g, n in pairs(reward.boxes) do
				local ing = Ingredients.byId[g]
				if ing then
					for _ = 1, n do
						table.insert(d.storage, { u = Uid.new("b"), g = g, n = ing.units })
					end
				end
			end
			Core.S.Supply.layout()
			Core.S.Data.changed(player, "storage")
		else
			Core.S.Economy.add(player, RewardsCfg.GiftBoxYen or 400, "gift")
		end
	end
	return true
end

local function claimGift(player, index)
	if type(index) ~= "number" or index % 1 ~= 0 then
		return
	end
	local gift = RewardsCfg.Gifts[index]
	if not gift then
		return
	end
	claimed[player] = claimed[player] or {}
	if claimed[player][index] then
		return
	end
	local joinedAt = player:GetAttribute("JoinedAt") or workspace:GetServerTimeNow()
	if workspace:GetServerTimeNow() - joinedAt < gift.min * 60 - 1 then
		return Core.S.Net.notify(player, "msg.gift_wait", nil, "info")
	end
	if grant(player, gift) then
		claimed[player][index] = true
		publishClaimed(player)
		Core.S.Net.fxTo(player, "sfx", { name = "gift" })
		Core.S.Net.fxTo(player, "sparkle", {})
		Core.S.Net.notify(player, "msg.gift_claimed", nil, "success")
	end
end

local function redeemCode(player, code)
	if type(code) ~= "string" or #code > 40 then
		return
	end
	code = string.upper((string.gsub(code, "%s", "")))
	local reward = RewardsCfg.Codes[code]
	if not reward then
		return Core.S.Net.notify(player, "msg.code_invalid", nil, "error")
	end
	local d = Core.S.Data.get(player)
	if not d then
		return
	end
	d.meta.codes = d.meta.codes or {}
	if d.meta.codes[code] then
		return Core.S.Net.notify(player, "msg.code_used", nil, "error")
	end
	if grant(player, reward) then
		d.meta.codes[code] = true
		Core.S.Data.changed(player, "meta")
		Core.S.Net.fxTo(player, "sfx", { name = "gift" })
		Core.S.Net.notify(player, "msg.code_ok", { code = code }, "success")
	end
end

local function leaderstats(player)
	local folder = Instance.new("Folder")
	folder.Name = "leaderstats"
	local yen = Instance.new("IntValue")
	yen.Name = "¥"
	yen.Parent = folder
	local level = Instance.new("IntValue")
	level.Name = "⭐"
	level.Parent = folder
	folder.Parent = player
end

local function onPlayer(player)
	player:SetAttribute("JoinedAt", workspace:GetServerTimeNow())
	claimed[player] = {}
	publishClaimed(player)
	leaderstats(player)
end

-- ❤️ a visitor likes the restaurant they are in: once a day per restaurant, counts for the
-- owner's likes (shown on the restaurant and on the leaderboard)
local function like(player)
	local owner = Core.S.Session.owner
	if not owner or owner == player then
		return
	end
	local od, pd = Core.S.Data.get(owner), Core.S.Data.get(player)
	if not od or not pd then
		return
	end
	pd.meta.liked = pd.meta.liked or {}
	local key = tostring(owner.UserId)
	local today = math.floor(os.time() / 86400)
	if pd.meta.liked[key] == today then
		return Core.S.Net.notify(player, "msg.like_done", nil, "info")
	end
	pd.meta.liked[key] = today
	od.stats.likes = (od.stats.likes or 0) + 1
	workspace:SetAttribute("Likes", od.stats.likes)
	Core.S.Data.changed(owner, "stats")
	Core.S.Data.changed(player, "meta")
	Core.S.Net.notify(owner, "msg.liked", { name = player.DisplayName }, "success")
	Core.S.Net.notify(player, "msg.like_sent", nil, "success")
	Core.S.Net.fx("sparkle", {})
end

function Rewards.Init()
	local Net = Core.S.Net
	Net.on("ClaimGift", claimGift, 4)
	Net.on("RedeemCode", redeemCode, 2)
	Net.on("Like", like, 2)
end

function Rewards.Start()
	for _, p in ipairs(Players:GetPlayers()) do
		onPlayer(p)
	end
	Players.PlayerAdded:Connect(onPlayer)
	Core.S.Session.OwnerReady:Connect(function(_, d)
		workspace:SetAttribute("Likes", d and d.stats.likes or 0)
	end)
	Players.PlayerRemoving:Connect(function(p)
		claimed[p] = nil
	end)
	-- keep the player list numbers current
	while true do
		task.wait(2)
		for _, p in ipairs(Players:GetPlayers()) do
			local d = Core.S.Data.get(p)
			local ls = p:FindFirstChild("leaderstats")
			if d and ls then
				ls["¥"].Value = math.floor(d.yen or 0)
				ls["⭐"].Value = d.level or 1
			end
		end
	end
end

return Rewards
