--!nonstrict
-- Daily quest templates. target = base + perLevel * level (rounded).
-- kind matches the events sent to MetaService.event(owner, kind, amount, info).
local list = {
	{ id = "q_serve", kind = "serve", base = 15, perLevel = 1.2 },
	{ id = "q_serve_sushi", kind = "serve_sushi", base = 8, perLevel = 0.8 },
	{ id = "q_serve_ramen", kind = "serve_ramen", base = 8, perLevel = 0.8 },
	{ id = "q_tips", kind = "tips", base = 150, perLevel = 60 },
	{ id = "q_earn", kind = "earn", base = 800, perLevel = 400 },
	{ id = "q_happy", kind = "happy", base = 10, perLevel = 0.6 },
	{ id = "q_customers", kind = "customers", base = 12, perLevel = 1 },
	{ id = "q_restock", kind = "restock", base = 6, perLevel = 0.3 },
	{ id = "q_wash", kind = "wash", base = 12, perLevel = 0.6 },
	{ id = "q_five_stars", kind = "five_stars", base = 5, perLevel = 0.3 },
}
local byId = {}
for i, q in ipairs(list) do
	q.order = i
	byId[q.id] = q
end
return {
	list = list,
	byId = byId,
	PerDay = 3,
	RewardYenPerLevel = 200,
	RewardSakura = 2,
	BonusSakura = 5,
}
