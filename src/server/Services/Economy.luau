--!nonstrict
-- Yen and sakura tokens, income multipliers, boosts and the per-day ledger.
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Franchise = require(Shared.Config.Franchise)
local Formulas = require(Shared.Logic.Formulas)
local GameConfig = require(Shared.Config.GameConfig)
local Core = require(script.Parent.Parent.Core)

local Economy = {}

local INCOME = { sale = true, tip = true, offline = true }

local function newLedger()
	return { sales = 0, tips = 0, supplies = 0, salaries = 0, build = 0, other = 0, customers = 0, served = 0, walkouts = 0, stars = 0, reviews = 0, bestDish = {} }
end

-- the day's accounts of a restaurant
function Economy.ledgerOf(plot)
	if not plot then
		return newLedger()
	end
	plot.ledger = plot.ledger or newLedger()
	return plot.ledger
end

function Economy.resetLedger(plot)
	if plot then
		plot.ledger = newLedger()
	end
end

function Economy.boostActive(plot, name)
	local data = Core.S.Plots.data(plot)
	return data and data.boosts and (data.boosts[name] or 0) > os.time() or false
end

-- income multiplier of a restaurant owner (franchise stars and passes)
function Economy.multiplier(player)
	local data = Core.S.Data.get(player)
	if not data then
		return 1
	end
	local passMult = 1
	local Monetization = Core.S.Monetization
	if Monetization then
		passMult = Monetization.yenMultiplier(player)
	end
	local base = Formulas.incomeMultiplier({ franchiseStars = data.franchise.stars or 0, yenPerStar = Franchise.YenPerStar, passMult = passMult })
	-- friends working in the restaurant (Plots keeps coopBonus up to date)
	local own = Core.S.Plots.ofPlayer(player)
	return base * (1 + (own and own.coopBonus or 0))
end

-- Adds yen to `player`'s profile. opts.raw skips multipliers.
function Economy.add(player, amount, reason, opts)
	local Data = Core.S.Data
	local data = Data.get(player)
	if not data or not amount or amount <= 0 then
		return 0
	end
	local value = amount
	local own = Core.S.Plots.ofPlayer(player)
	if INCOME[reason] and not (opts and opts.raw) and own then
		value = math.floor(amount * Economy.multiplier(player) + 0.5)
		if reason == "tip" and Economy.boostActive(own, "golden") then
			value = math.floor(value * 1.5 + 0.5)
		end
	end
	data.yen += value
	if INCOME[reason] then
		data.stats.earned += value
	end
	if own then
		local L = Economy.ledgerOf(own)
		if reason == "sale" then
			L.sales += value
		elseif reason == "tip" then
			L.tips += value
		end
	end
	Data.changed(player, "yen")
	if Core.S.Analytics then
		Core.S.Analytics.source(player, value, reason, data.yen)
	end
	if INCOME[reason] then
		Data.changed(player, "stats")
		Core.S.Meta.event(player, "earn", value)
		if reason == "tip" then
			Core.S.Meta.event(player, "tips", value)
		end
	end
	return value
end

function Economy.canAfford(player, amount)
	local data = Core.S.Data.get(player)
	return data ~= nil and data.yen >= amount
end

-- sku names what is bought, for the analytics (e.g. "upgrade:up_tray")
function Economy.spend(player, amount, reason, sku)
	local Data = Core.S.Data
	local data = Data.get(player)
	if not data or amount < 0 or data.yen < amount then
		return false
	end
	data.yen -= amount
	if Core.S.Analytics and amount > 0 then
		Core.S.Analytics.sink(player, amount, reason, data.yen, sku)
	end
	local own = Core.S.Plots.ofPlayer(player)
	if own then
		local L = Economy.ledgerOf(own)
		if reason == "supplies" then
			L.supplies += amount
		elseif reason == "salary" then
			L.salaries += amount
		elseif reason == "build" then
			L.build += amount
		else
			L.other += amount
		end
	end
	Data.changed(player, "yen")
	return true
end

-- Salaries may push the balance below zero only down to 0
function Economy.charge(player, amount, reason)
	local data = Core.S.Data.get(player)
	if not data then
		return 0
	end
	local paid = math.min(amount, data.yen)
	if paid > 0 then
		Economy.spend(player, paid, reason)
	end
	return paid
end

------------------------------------------------------------------ tip jar

local function jars(plot)
	return Core.S.Entities.ofKind("tipjar", plot)
end

-- shows the coins of every jar of a restaurant (height grows with the amount, full at TipJarFull)
local function drawJars(plot, amount)
	for _, e in ipairs(jars(plot)) do
		local coins = e.model and e.model:FindFirstChild("Coins")
		if coins then
			local base = coins:GetAttribute("Base") or 0.09
			local h = 0.05 + 0.9 * math.clamp(amount / (GameConfig.TipJarFull or 600), 0, 1)
			local root = e.model.PrimaryPart
			coins.Size = Vector3.new(h, coins.Size.Y, coins.Size.Z)
			if root then
				coins.CFrame = root.CFrame * CFrame.new(0, base + h / 2 - 0.025 - root.Size.Y / 2, 0) * CFrame.Angles(0, 0, math.rad(90))
			end
			e.model:SetAttribute("Tips", amount)
		end
	end
end

-- a tip goes into the restaurant's jar when it has one; returns true if it did
function Economy.tipToJar(plot, amount)
	local d = Core.S.Plots.data(plot)
	if not d or amount <= 0 or #jars(plot) == 0 then
		return false
	end
	d.tipJar = (d.tipJar or 0) + amount
	drawJars(plot, d.tipJar)
	Core.S.Data.changed(plot.owner, "tipJar")
	return true
end

-- empties a restaurant's jar into its owner's wallet (click on the jar, or at the end of the day)
function Economy.collectTips(player, plot)
	plot = plot or Core.S.Plots.of(player)
	local d = Core.S.Plots.data(plot)
	local owner = plot and plot.owner
	if not d or not owner or (d.tipJar or 0) <= 0 then
		return false, "msg.tipjar_empty"
	end
	local amount = d.tipJar
	d.tipJar = 0
	drawJars(plot, 0)
	local got = Economy.add(owner, amount, "tip")
	local pos = nil
	local jar = jars(plot)[1]
	if jar and jar.model and jar.model.PrimaryPart then
		pos = jar.model.PrimaryPart.Position
	end
	Core.S.Net.fx("coins", { amount = got, pos = pos })
	Core.S.Net.fx("sfx", { name = "coin", pos = pos })
	local _ = player
	return true
end

function Economy.redrawJars(plot)
	local d = Core.S.Plots.data(plot)
	drawJars(plot, d and d.tipJar or 0)
end

function Economy.addSakura(player, n)
	local data = Core.S.Data.get(player)
	if not data or n <= 0 then
		return
	end
	data.sakura += n
	Core.S.Data.changed(player, "sakura")
	if Core.S.Analytics then
		Core.S.Analytics.sakura(player, n, data.sakura, false)
	end
end

function Economy.spendSakura(player, n, sku)
	local data = Core.S.Data.get(player)
	if not data or data.sakura < n then
		return false
	end
	data.sakura -= n
	Core.S.Data.changed(player, "sakura")
	if Core.S.Analytics and n > 0 then
		Core.S.Analytics.sakura(player, n, data.sakura, true, sku)
	end
	return true
end

function Economy.Init() end

function Economy.Start()
	-- a jar placed (or rebuilt after a move) shows the tips it holds
	Core.S.Placement.ItemAdded:Connect(function(e)
		if e.kind == "tipjar" then
			task.defer(Economy.redrawJars, e.plot)
		end
	end)
	Core.S.Plots.Claimed:Connect(function(plot)
		plot.ledger = nil
		task.defer(Economy.redrawJars, plot)
	end)
end

return Economy
