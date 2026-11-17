--!nonstrict
-- Yen and sakura tokens, income multipliers, boosts and the per-day ledger.
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Franchise = require(Shared.Config.Franchise)
local Formulas = require(Shared.Logic.Formulas)
local GameConfig = require(Shared.Config.GameConfig)
local Core = require(script.Parent.Parent.Core)

local Economy = {}
Economy.ledger = nil

local INCOME = { sale = true, tip = true, offline = true }

function Economy.resetLedger()
	Economy.ledger = { sales = 0, tips = 0, supplies = 0, salaries = 0, build = 0, other = 0, customers = 0, served = 0, walkouts = 0, stars = 0, reviews = 0, bestDish = {} }
end

function Economy.boostActive(name)
	local data = Core.S.Session.ownerData()
	return data and data.boosts and (data.boosts[name] or 0) > os.time() or false
end

function Economy.multiplier()
	local data = Core.S.Session.ownerData()
	if not data then
		return 1
	end
	local passMult = 1
	local Monetization = Core.S.Monetization
	if Monetization then
		passMult = Monetization.ownerYenMultiplier()
	end
	return Formulas.incomeMultiplier({ franchiseStars = data.franchise.stars or 0, yenPerStar = Franchise.YenPerStar, passMult = passMult })
end

-- Adds yen to `player`'s profile. opts.raw skips multipliers.
function Economy.add(player, amount, reason, opts)
	local Data = Core.S.Data
	local data = Data.get(player)
	if not data or not amount or amount <= 0 then
		return 0
	end
	local value = amount
	if INCOME[reason] and not (opts and opts.raw) and player == Core.S.Session.owner then
		value = math.floor(amount * Economy.multiplier() + 0.5)
		if reason == "tip" and Economy.boostActive("golden") then
			value = math.floor(value * 1.5 + 0.5)
		end
	end
	data.yen += value
	if INCOME[reason] then
		data.stats.earned += value
	end
	if Economy.ledger and player == Core.S.Session.owner then
		if reason == "sale" then
			Economy.ledger.sales += value
		elseif reason == "tip" then
			Economy.ledger.tips += value
		end
	end
	Data.changed(player, "yen")
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

function Economy.spend(player, amount, reason)
	local Data = Core.S.Data
	local data = Data.get(player)
	if not data or amount < 0 or data.yen < amount then
		return false
	end
	data.yen -= amount
	if Economy.ledger and player == Core.S.Session.owner then
		if reason == "supplies" then
			Economy.ledger.supplies += amount
		elseif reason == "salary" then
			Economy.ledger.salaries += amount
		elseif reason == "build" then
			Economy.ledger.build += amount
		else
			Economy.ledger.other += amount
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

local function jars()
	return Core.S.Entities.ofKind("tipjar")
end

-- shows the coins of every jar (height grows with the amount, full at TipJarFull)
local function drawJars(amount)
	for _, e in ipairs(jars()) do
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

-- a tip goes into the jar when the restaurant has one; returns true if it did
function Economy.tipToJar(amount)
	local d = Core.S.Session.ownerData()
	if not d or amount <= 0 or #jars() == 0 then
		return false
	end
	d.tipJar = (d.tipJar or 0) + amount
	drawJars(d.tipJar)
	Core.S.Data.changed(Core.S.Session.owner, "tipJar")
	return true
end

-- empties the jar into the owner's wallet (click on the jar, or automatically at closing time)
function Economy.collectTips(player)
	local d = Core.S.Session.ownerData()
	local owner = Core.S.Session.owner
	if not d or not owner or (d.tipJar or 0) <= 0 then
		return false, "msg.tipjar_empty"
	end
	local amount = d.tipJar
	d.tipJar = 0
	drawJars(0)
	local got = Economy.add(owner, amount, "tip")
	local pos = nil
	local jar = jars()[1]
	if jar and jar.model and jar.model.PrimaryPart then
		pos = jar.model.PrimaryPart.Position
	end
	Core.S.Net.fx("coins", { amount = got, pos = pos })
	Core.S.Net.fx("sfx", { name = "coin", pos = pos })
	local _ = player
	return true
end

function Economy.redrawJars()
	local d = Core.S.Session.ownerData()
	drawJars(d and d.tipJar or 0)
end

function Economy.addSakura(player, n)
	local data = Core.S.Data.get(player)
	if not data or n <= 0 then
		return
	end
	data.sakura += n
	Core.S.Data.changed(player, "sakura")
end

function Economy.spendSakura(player, n)
	local data = Core.S.Data.get(player)
	if not data or data.sakura < n then
		return false
	end
	data.sakura -= n
	Core.S.Data.changed(player, "sakura")
	return true
end

function Economy.Init()
	Economy.resetLedger()
end

function Economy.Start()
	-- a jar placed (or rebuilt after a move) shows the tips it holds
	Core.S.Placement.ItemAdded:Connect(function(e)
		if e.kind == "tipjar" then
			task.defer(Economy.redrawJars)
		end
	end)
	Core.S.Session.OwnerReady:Connect(function()
		task.defer(Economy.redrawJars)
	end)
end

return Economy
