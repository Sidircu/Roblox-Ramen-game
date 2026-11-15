--!nonstrict
-- Ambience score, tiers and decoration set bonuses (pure).
local Ambience = {}

Ambience.Tiers = {
	{ min = 0, patience = 0, tip = 0, popularity = 0 },
	{ min = 30, patience = 0.10, tip = 0.05, popularity = 0.10 },
	{ min = 100, patience = 0.20, tip = 0.10, popularity = 0.25 },
	{ min = 250, patience = 0.30, tip = 0.18, popularity = 0.45 },
	{ min = 600, patience = 0.40, tip = 0.25, popularity = 0.70 },
}

function Ambience.tier(points)
	local idx = 1
	for i, t in ipairs(Ambience.Tiers) do
		if points >= t.min then
			idx = i
		end
	end
	return idx - 1, Ambience.Tiers[idx]
end

-- placed: list of placed entries; items: Items.byId; surfaces: Surfaces.byId;
-- zoneSurfaces: { [zoneId] = {floor = id, wall = id} }; extra: flat bonus points
-- sets: Sets.list
function Ambience.compute(placed, items, surfaces, zoneSurfaces, extra, sets)
	local counts = {}
	for _, e in ipairs(placed) do
		counts[e.i] = (counts[e.i] or 0) + 1
	end
	local points = extra or 0
	local maneki = 0
	for id, n in pairs(counts) do
		local item = items[id]
		if item then
			local amb = item.amb or 0
			for k = 1, n do
				points = points + amb * 0.8 ^ (k - 1)
			end
			if item.tipBonus then
				maneki = maneki + item.tipBonus * math.min(n, item.tipMax or n)
			end
		end
	end
	for _, s in pairs(zoneSurfaces or {}) do
		for _, sid in pairs(s) do
			local surf = surfaces[sid]
			if surf then
				points = points + surf.amb
			end
		end
	end
	local setTip, setPop, complete = 0, 0, {}
	for _, set in ipairs(sets or {}) do
		local all = true
		for _, id in ipairs(set.items) do
			if not counts[id] then
				all = false
				break
			end
		end
		if all then
			complete[set.id] = true
			setTip = setTip + (set.bonus.tip or 0)
			setPop = setPop + (set.bonus.popularity or 0)
		end
	end
	local tierIndex, tier = Ambience.tier(points)
	return {
		points = math.floor(points),
		tier = tierIndex,
		patience = tier.patience,
		tip = tier.tip + setTip + maneki,
		popularity = tier.popularity + setPop,
		sets = complete,
	}
end

return Ambience
