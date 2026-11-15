--!nonstrict
-- Global leaderboards (dishes served, yen earned) with a small cache.
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local Core = require(script.Parent.Parent.Core)

local Leaderboard = {}
local stores = {}
local cache = { t = 0, data = nil }
local names = {}

local BOARDS = { dishes = "LB_Dishes_v1", earned = "LB_Earned_v1" }

local function nameOf(userId)
	if names[userId] then
		return names[userId]
	end
	local ok, n = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	names[userId] = ok and n or ("#" .. userId)
	return names[userId]
end

local function submit(player)
	local d = Core.S.Data.get(player)
	if not d then
		return
	end
	for stat, store in pairs(stores) do
		local value = math.floor(d.stats[stat] or 0)
		pcall(function()
			store:SetAsync(tostring(player.UserId), value)
		end)
	end
end

local function fetch()
	if cache.data and os.clock() - cache.t < 120 then
		return cache.data
	end
	local out = {}
	for stat, store in pairs(stores) do
		out[stat] = {}
		local ok, pages = pcall(function()
			return store:GetSortedAsync(false, 10)
		end)
		if ok and pages then
			for rank, entry in ipairs(pages:GetCurrentPage()) do
				table.insert(out[stat], { rank = rank, name = nameOf(tonumber(entry.key)), value = entry.value })
			end
		end
	end
	cache = { t = os.clock(), data = out }
	return out
end

function Leaderboard.Init()
	for stat, name in pairs(BOARDS) do
		local ok, s = pcall(function()
			return DataStoreService:GetOrderedDataStore(name)
		end)
		if ok then
			stores[stat] = s
		end
	end
	Core.S.Net.invoke("GetLeaderboard", function()
		return fetch()
	end)
end

function Leaderboard.Start()
	Players.PlayerRemoving:Connect(submit)
	task.spawn(function()
		while true do
			task.wait(300)
			for _, p in ipairs(Players:GetPlayers()) do
				submit(p)
			end
		end
	end)
end

return Leaderboard
