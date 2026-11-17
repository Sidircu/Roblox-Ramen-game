--!nonstrict
-- Day cycle: prep -> open (11:00-23:00, 1 game hour = 1 minute) -> closing -> report -> prep.
local Lighting = game:GetService("Lighting")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local Staff = require(Shared.Config.Staff)
local Core = require(script.Parent.Parent.Core)

local Day = {}
Day.phase = "prep"
Day.clock = GameConfig.Day.PrepClock
Day.report = nil
local phaseStarted = os.clock()
local DAY = GameConfig.Day

local function data()
	return Core.S.Session.ownerData()
end

function Day.isPeak()
	for _, p in ipairs(DAY.Peaks) do
		if Day.clock >= p[1] and Day.clock < p[2] then
			return true
		end
	end
	return false
end

local function payload()
	local d = data()
	return {
		phase = Day.phase,
		clock = Day.clock,
		day = d and (d.stats.days or 0) + 1 or 1,
		report = Day.phase == "report" and Day.report or nil,
	}
end

function Day.broadcast()
	Core.S.Net.fireAll("DayState", payload())
	workspace:SetAttribute("DayPhase", Day.phase)
end

local function setPhase(p)
	Day.phase = p
	phaseStarted = os.clock()
	Day.broadcast()
end

function Day.open()
	if Day.phase ~= "prep" then
		return
	end
	Core.S.Economy.resetLedger()
	Day.clock = DAY.OpenHour
	Lighting.ClockTime = Day.clock
	Core.S.World.setOpenSign(true)
	setPhase("open")
	Core.S.Net.notifyAll("msg.day_open", nil, "success")
	Core.S.Net.fx("sfx", { name = "bell" })
	Core.S.Meta.event(Core.S.Session.owner, "open", 1)
end

local function finish()
	local d = data()
	if not d then
		return
	end
	local owner = Core.S.Session.owner
	-- tips left in the jar go to the wallet before the day's report
	pcall(Core.S.Economy.collectTips, owner)
	local L = Core.S.Economy.ledger
	-- salaries
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
	Day.report = {
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
	setPhase("report")
	task.spawn(Core.S.Data.save, owner, false)
end

function Day.next()
	if Day.phase ~= "report" then
		return
	end
	Day.clock = DAY.PrepClock
	Lighting.ClockTime = Day.clock
	Core.S.Cooking.clearTickets()
	setPhase("prep")
end

function Day.closeEarly()
	if Day.phase == "open" then
		Day.clock = DAY.CloseHour
	end
end

local function hasManager()
	local d = data()
	if not d then
		return false
	end
	for _, s in ipairs(d.staff) do
		if s.role == "staff_manager" then
			return true
		end
	end
	return false
end

function Day.Init()
	Core.S.Net.on("SetDayState", function(player, action)
		local Session = Core.S.Session
		if not Session.canBuild(player) and action ~= "next" then
			return Core.S.Net.notify(player, "msg.no_permission", nil, "error")
		end
		if action == "open" then
			Day.open()
		elseif action == "close" then
			Day.closeEarly()
		elseif action == "next" then
			Day.next()
		end
	end, 2)
	Lighting.ClockTime = Day.clock
	Lighting.GeographicLatitude = 35
end

function Day.Start()
	game:GetService("Players").PlayerAdded:Connect(function(p)
		task.wait(2)
		Core.S.Net.fire(p, "DayState", payload())
	end)
	Core.S.Session.OwnerReady:Connect(function()
		Day.broadcast()
	end)
	local last = os.clock()
	local lastBroadcast = 0
	while true do
		task.wait(0.25)
		local now = os.clock()
		local dt = now - last
		last = now
		local d = data()
		if Day.phase == "open" then
			Day.clock += dt / DAY.SecondsPerHour
			if Day.clock >= DAY.CloseHour then
				Day.clock = DAY.CloseHour
				Core.S.World.setOpenSign(false)
				setPhase("closing")
				Core.S.Net.notifyAll("msg.day_closing", nil, "info")
			end
			Lighting.ClockTime = Day.clock
		elseif Day.phase == "closing" then
			local anyone = next(Core.S.Customers.active) ~= nil
			if not anyone or os.clock() - phaseStarted > 90 then
				Core.S.Customers.sendAllHome()
				finish()
			end
			Day.clock = math.min(Day.clock + dt / DAY.SecondsPerHour, 24)
			Lighting.ClockTime = Day.clock
		elseif Day.phase == "report" then
			if d and d.settings.autoDay and hasManager() and os.clock() - phaseStarted > DAY.ReportAutoClose then
				Day.next()
			end
		elseif Day.phase == "prep" then
			if d and d.settings.autoDay and hasManager() and os.clock() - phaseStarted > DAY.ManagerAutoOpenDelay then
				Day.open()
			end
		end
		if now - lastBroadcast > 5 then
			lastBroadcast = now
			Day.broadcast()
		end
	end
end

return Day
