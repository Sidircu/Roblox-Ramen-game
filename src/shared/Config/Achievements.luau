--!nonstrict
-- Achievements are generated from tiered templates. Name key: "ach.<stat>" with {n}.
local templates = {
	{ stat = "dishes", tiers = { 10, 100, 1000, 10000, 100000 }, sakura = { 5, 10, 20, 35, 50 } },
	{ stat = "customers", tiers = { 10, 250, 2500, 25000 }, sakura = { 5, 10, 25, 50 } },
	{ stat = "earned", tiers = { 10000, 250000, 5000000, 100000000 }, sakura = { 5, 15, 30, 50 } },
	{ stat = "decor", tiers = { 5, 25, 75, 150 }, sakura = { 5, 10, 20, 40 } },
	{ stat = "staff", tiers = { 1, 4, 8, 12 }, sakura = { 5, 10, 20, 30 } },
	{ stat = "gold_mastery", tiers = { 1, 5, 15, 30 }, sakura = { 10, 20, 35, 50 } },
	{ stat = "level", tiers = { 5, 10, 20, 30, 40, 50 }, sakura = { 5, 10, 15, 20, 30, 50 } },
	{ stat = "licenses", tiers = { 3, 8, 17 }, sakura = { 5, 15, 40 } },
	{ stat = "zones", tiers = { 2, 5, 9 }, sakura = { 5, 15, 40 } },
	{ stat = "five_stars", tiers = { 10, 100, 1000, 10000 }, sakura = { 5, 10, 25, 50 } },
	{ stat = "franchise", tiers = { 1, 2, 3, 4, 5 }, sakura = { 20, 30, 40, 50, 100 } },
	{ stat = "days", tiers = { 1, 10, 50, 200 }, sakura = { 3, 10, 25, 50 } },
	{ stat = "washed", tiers = { 50, 1000, 20000 }, sakura = { 5, 15, 40 } },
}

local list = {}
local byId = {}
for _, t in ipairs(templates) do
	for i, n in ipairs(t.tiers) do
		local a = { id = "ach_" .. t.stat .. "_" .. i, stat = t.stat, target = n, sakura = t.sakura[i], tier = i }
		table.insert(list, a)
		byId[a.id] = a
	end
end

return { list = list, byId = byId }
