--!nonstrict
-- Pure game formulas (no Roblox APIs). See docs/03-BILANCIAMENTO.md §1.
local Formulas = {}

Formulas.MaxLevel = 50
Formulas.MasteryThresholds = { 25, 100, 500, 2000, 10000 }

function Formulas.round(x)
	return math.floor(x + 0.5)
end

function Formulas.xpForLevel(level)
	return Formulas.round(100 * level ^ 1.65)
end

-- Adds xp to (level, xp) and returns newLevel, newXp, levelsGained
function Formulas.addXp(level, xp, amount)
	xp = xp + amount
	local gained = 0
	while level < Formulas.MaxLevel and xp >= Formulas.xpForLevel(level) do
		xp = xp - Formulas.xpForLevel(level)
		level = level + 1
		gained = gained + 1
	end
	if level >= Formulas.MaxLevel then
		xp = math.min(xp, Formulas.xpForLevel(level))
	end
	return level, xp, gained
end

function Formulas.levelReward(level)
	return 50 * level * level, (level % 5 == 0) and 5 or 0
end

function Formulas.masteryLevel(served)
	local lvl = 0
	for i, t in ipairs(Formulas.MasteryThresholds) do
		if (served or 0) >= t then
			lvl = i
		end
	end
	return lvl
end

-- Price paid for a dish before tips.
function Formulas.dishPrice(basePrice, served, priceMult)
	local m = Formulas.masteryLevel(served)
	return Formulas.round(basePrice * (1 + 0.05 * m) * (priceMult or 1))
end

-- Relative order probability for a menu price multiplier (0.7 .. 1.3)
function Formulas.demandFactor(priceMult)
	return math.max(0.1, 1 - 1.2 * ((priceMult or 1) - 1))
end

function Formulas.patienceFactor(priceMult)
	return math.clamp(1 - 0.5 * ((priceMult or 1) - 1), 0.75, 1.2)
end

-- opts: fresh(bool), ambienceTip, comfort (0-5), patienceLeft (0-1), customerTip, extraTip
function Formulas.tip(price, opts)
	local pct = 0.05
	if opts.fresh then
		pct = pct + (opts.freshBonus or 0.10)
	end
	pct = pct + (opts.ambienceTip or 0)
	pct = pct + 0.02 * (opts.comfort or 0)
	pct = pct + 0.10 * math.clamp(opts.patienceLeft or 0, 0, 1)
	pct = pct + (opts.extraTip or 0)
	return Formulas.round(price * pct * (opts.customerTip or 1))
end

-- Review stars (1..5). opts: patienceLeft, dirtyNearby, fresh, ambienceTier (0..4), comfort (0..5), left (walked out)
function Formulas.review(opts)
	if opts.left then
		return 1
	end
	local used = 1 - math.clamp(opts.patienceLeft or 1, 0, 1)
	local wait = 0
	if used > 0.5 then
		wait = (used - 0.5) / 0.5 * 2
	end
	local stars = 4.2 - wait
	if opts.dirtyNearby then
		stars = stars - 0.5
	end
	if opts.fresh then
		stars = stars + (opts.freshBonus or 0.3)
	end
	stars = stars + 0.125 * (opts.ambienceTier or 0)
	stars = stars + 0.06 * (opts.comfort or 0)
	return math.clamp(Formulas.round(stars * 2) / 2, 1, 5)
end

-- Weighted average of recent reviews { {s = stars, w = weight}, ... }
function Formulas.rating(recent, default)
	local sum, weight = 0, 0
	for _, r in ipairs(recent or {}) do
		sum = sum + r.s * (r.w or 1)
		weight = weight + (r.w or 1)
	end
	if weight == 0 then
		return default or 3
	end
	return sum / weight
end

-- opts: level, rating, ambience (tier popularity), sign, ads, sets, event, extra
function Formulas.popularity(opts)
	local p = 0.15 * ((opts.level or 1) / 10)
		+ 0.35 * ((opts.rating or 3) - 3)
		+ (opts.ambience or 0)
		+ (opts.sign or 0)
		+ (opts.ads or 0)
		+ (opts.sets or 0)
		+ (opts.event or 0)
		+ (opts.extra or 0)
	return math.max(0, p)
end

function Formulas.customerInterval(base, minInterval, popularity, peak, peakFactor, rush)
	local v = math.max(minInterval, base / (1 + popularity))
	if peak then
		v = v * (peakFactor or 0.6)
	end
	if rush then
		v = v * 0.5
	end
	return math.max(minInterval * 0.5, v)
end

function Formulas.staffTrainCost(hire, nextLevel)
	return Formulas.round(hire * 0.8 * 2.2 ^ (nextLevel - 2))
end

function Formulas.staffSpeed(level, perLevel, managerBonus)
	return 1 + (perLevel or 0.15) * ((level or 1) - 1) + (managerBonus or 0)
end

function Formulas.offlineEarnings(hourly, pct, hours)
	return Formulas.round(math.max(0, hourly) * pct * hours)
end

function Formulas.questTarget(base, perLevel, level)
	return math.max(1, Formulas.round(base + perLevel * level))
end

function Formulas.yenPack(baseYen, level, scale)
	return Formulas.round(baseYen * (1 + level * (scale or 0.2)))
end

-- Multiplier applied to every yen income: VIP/2x passes, franchise stars, boosts
function Formulas.incomeMultiplier(opts)
	local m = 1 + (opts.franchiseStars or 0) * (opts.yenPerStar or 0.25)
	m = m * (opts.passMult or 1)
	return m
end

return Formulas
