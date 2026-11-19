--!nonstrict
-- Roblox Analytics: where new players stop in their first minutes (onboarding funnel), what they
-- earn and spend (economy) and how they level up (progression). Every call is protected: analytics
-- can never break the game. Sales and tips are summed and reported every few minutes.
local AnalyticsService = game:GetService("AnalyticsService")
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config.Analytics)
local Core = require(script.Parent.Parent.Core)

local Analytics = {}
local pending = {} -- [player] = { [reason] = yen } sales and tips not reported yet

local function isPlayer(p)
	return typeof(p) == "Instance" and p:IsA("Player") and p.Parent ~= nil
end

-- logs an onboarding step once per new player (players from before this update are not counted)
function Analytics.step(player, name)
	if not isPlayer(player) then
		return
	end
	local d = Core.S.Data.get(player)
	local idx = Config.FunnelIndex[name]
	if not d or not idx or not d.meta.onboarding then
		return
	end
	d.meta.funnel = d.meta.funnel or {}
	if d.meta.funnel[name] then
		return
	end
	d.meta.funnel[name] = true
	pcall(function()
		AnalyticsService:LogOnboardingFunnelStepEvent(player, idx, name)
	end)
end

local function logEconomy(player, flow, currency, amount, balance, txType, sku)
	if not isPlayer(player) or amount <= 0 then
		return
	end
	pcall(function()
		AnalyticsService:LogEconomyEvent(player, flow, currency, amount, balance, txType, sku or "")
	end)
end

-- yen earned (reason = Economy reason); sales and tips are summed up
function Analytics.source(player, amount, reason, balance)
	if reason == "sale" or reason == "tip" or reason == "helper" then
		pending[player] = pending[player] or {}
		pending[player][reason] = (pending[player][reason] or 0) + amount
		return
	end
	local tx = Config.SourceType[reason]
	if tx then
		logEconomy(player, Enum.AnalyticsEconomyFlowType.Source, "Yen", amount, balance, tx, reason)
	end
end

-- yen spent; sku names what was bought (e.g. "upgrade:up_tray")
function Analytics.sink(player, amount, reason, balance, sku)
	logEconomy(player, Enum.AnalyticsEconomyFlowType.Sink, "Yen", amount, balance, Config.SinkType[reason] or "Shop", sku or reason)
	if reason == "build" then
		Analytics.step(player, "first_purchase")
	end
end

function Analytics.sakura(player, amount, balance, spent, sku)
	local flow = spent and Enum.AnalyticsEconomyFlowType.Sink or Enum.AnalyticsEconomyFlowType.Source
	logEconomy(player, flow, "Sakura", amount, balance, spent and "Shop" or "Gameplay", sku)
end

function Analytics.levelUp(player, level)
	if not isPlayer(player) then
		return
	end
	pcall(function()
		AnalyticsService:LogProgressionCompleteEvent(player, "Level", level - 1)
	end)
	if level >= 3 then
		Analytics.step(player, "level_3")
	end
	if level >= 5 then
		Analytics.step(player, "level_5")
	end
end

local function flush(player)
	local p = pending[player]
	pending[player] = nil
	if not p then
		return
	end
	local d = Core.S.Data.get(player)
	local balance = d and d.yen or 0
	for reason, amount in pairs(p) do
		logEconomy(player, Enum.AnalyticsEconomyFlowType.Source, "Yen", amount, balance, Config.SourceType[reason] or "Gameplay", reason)
	end
end

function Analytics.Start()
	Core.S.Data.Loaded:Connect(function(player)
		Analytics.step(player, "joined")
	end)
	Players.PlayerRemoving:Connect(function(player)
		flush(player)
	end)
	while true do
		task.wait(Config.SourceFlush)
		for player in pairs(pending) do
			flush(player)
		end
	end
end

return Analytics
