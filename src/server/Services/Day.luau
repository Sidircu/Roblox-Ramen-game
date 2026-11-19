--!nonstrict
-- Time of day, the same for the whole street. The restaurants are always open: the clock turns
-- continuously for the light (day, sunset, lantern-lit evening, a quick night) and the lunch and
-- dinner rush. Every day at Day.DayStartHour each restaurant closes its accounts: salaries, stats,
-- daily quests and a short summary for its owner (never a screen that stops the game).
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local Staff = require(Shared.Config.Staff)
local Core = require(script.Parent.Parent.Core)

local Day = {}
local DAY = GameConfig.Day
Day.phase = "open" -- kept for older checks: the restaurant never closes
Day.clock = DAY.StartClock
local hours = DAY.StartClock -- game hours since the server started (never wraps)

function Day.isPeak()
	for _, p in ipairs(DAY.Peaks) do
		if Day.clock >= p[1] and Day.clock < p[2] then
			return true
		end
	end
	return false
end

function Day.isNight()
	return Day.clock >= DAY.NightFrom or Day.clock < DAY.NightTo
end

-- what a player sees: the clock, their own day number and the last summary of their restaurant
local function payload(player)
	local d = Core.S.Data.get(player)
	local plot = Core.S.Plots.ofPlayer(player)
	return {
		phase = Day.phase,
		clock = Day.clock,
		day = d and (d.stats.days or 0) + 1 or 1,
		night = Day.isNight(),
		report = plot and plot.report or nil,
	}
end

function Day.broadcast()
	for _, p in ipairs(Players:GetPlayers()) do
		Core.S.Net.fire(p, "DayState", payload(p))
	end
	workspace:SetAttribute("DayPhase", Day.phase)
end

-- closes the day's accounts of one restaurant
local function finishPlot(plot)
	local d = Core.S.Plots.data(plot)
	local owner = plot.owner
	if not d or not owner then
		return
	end
	-- tips left in the jar go to the wallet before the summary
	pcall(Core.S.Economy.collectTips, owner, plot)
	local L = Core.S.Economy.ledgerOf(plot)
	local salaries = 0
	for _, s in ipairs(d.staff) do
		local cfg = Staff.byId[s.role]
		if cfg then
			salaries += cfg.salary
		end
	end
	local paid = Core.S.Economy.charge(owner, salaries, "salary")
	local best, bestN = nil, 0
	for id, n in pairs(L.bestDish) do
		if n > bestN then
			best, bestN = id, n
		end
	end
	local income = L.sales + L.tips
	local costs = L.supplies + paid + L.build + L.other
	plot.report = {
		day = (d.stats.days or 0) + 1,
		sales = L.sales, tips = L.tips, supplies = L.supplies, salaries = paid, build = L.build, other = L.other,
		profit = income - costs, customers = L.customers, served = L.served, walkouts = L.walkouts,
		rating = L.reviews > 0 and (L.stars / L.reviews) or 0, best = best, bestCount = bestN,
	}
	d.stats.days = (d.stats.days or 0) + 1
	d.stats.lastDayEarned = income
	table.insert(d.stats.dayHistory, income)
	while #d.stats.dayHistory > 10 do
		table.remove(d.stats.dayHistory, 1)
	end
	Core.S.Data.changed(owner, "stats")
	Core.S.Meta.event(owner, "days", 1)
	Core.S.Meta.dayEnded(owner)
	Core.S.Economy.resetLedger(plot)
	Core.S.Net.notify(owner, "msg.day_summary", { day = plot.report.day, yen = income, served = L.served }, "success")
	task.spawn(Core.S.Data.save, owner, false)
end

-- a new day for the whole street
local function finish()
	for _, plot in ipairs(Core.S.Plots.list) do
		local ok, err = pcall(finishPlot, plot)
		if not ok then
			warn("[Day] closing the day failed: " .. tostring(err))
		end
	end
	Day.broadcast()
end

Day.finish = finish
Day.finishPlot = finishPlot

-- compatibility: the restaurant does not open or close any more
function Day.open() end
function Day.closeEarly() end
function Day.next() end

function Day.Init()
	Lighting.ClockTime = Day.clock
	Lighting.GeographicLatitude = 35
end

function Day.Start()
	Players.PlayerAdded:Connect(function(p)
		task.wait(2)
		Core.S.Net.fire(p, "DayState", payload(p))
	end)
	Core.S.Plots.Claimed:Connect(function(plot)
		plot.report = nil
		Day.broadcast()
	end)
	local last = os.clock()
	local lastBroadcast = 0
	local dayIndex = math.floor((hours - DAY.DayStartHour) / 24)
	while true do
		task.wait(0.25)
		local now = os.clock()
		local dt = now - last
		last = now
		local perHour = Day.isNight() and DAY.NightSecondsPerHour or DAY.SecondsPerHour
		hours += dt / perHour
		Day.clock = hours % 24
		Lighting.ClockTime = Day.clock
		local idx = math.floor((hours - DAY.DayStartHour) / 24)
		if idx > dayIndex then
			dayIndex = idx
			finish()
		end
		if now - lastBroadcast > 5 then
			lastBroadcast = now
			Day.broadcast()
		end
	end
end

return Day
