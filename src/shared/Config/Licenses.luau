--!nonstrict
-- License tree. Buying a license unlocks its recipes and station items.
local list = {
	-- you start with shoyu ramen only; a very easy second dish (salmon sashimi: one cut) comes
	-- cheap at level 2, then basic sushi with rice
	{ id = "lic_base", branch = "base", level = 1, cost = 0, rating = 0, requires = {}, recipes = { "shoyu_ramen" } },
	{ id = "lic_sashimi", branch = "sushi", level = 2, cost = 300, rating = 0, requires = { "lic_base" }, recipes = { "sake_sashimi" } },
	{ id = "lic_sushi0", branch = "sushi", level = 3, cost = 800, rating = 0, requires = { "lic_sashimi" }, recipes = { "kappa_maki", "sake_nigiri" } },
	{ id = "lic_sushi1", branch = "sushi", level = 4, cost = 1800, rating = 0, requires = { "lic_sushi0" }, recipes = { "tekka_maki", "maguro_nigiri" } },
	{ id = "lic_ramen1", branch = "ramen", level = 4, cost = 2200, rating = 0, requires = { "lic_base" }, recipes = { "shio_ramen" } },
	{ id = "lic_sides", branch = "extra", level = 5, cost = 4000, rating = 0, requires = { "lic_base" }, recipes = { "edamame", "green_tea", "miso_soup" } },
	{ id = "lic_sushi2", branch = "sushi", level = 8, cost = 12000, rating = 0, requires = { "lic_sushi1" }, recipes = { "california_roll", "ebi_nigiri" } },
	{ id = "lic_ramen2", branch = "ramen", level = 9, cost = 15000, rating = 0, requires = { "lic_ramen1" }, recipes = { "miso_ramen" } },
	{ id = "lic_griddle", branch = "extra", level = 12, cost = 30000, rating = 0, requires = { "lic_sides" }, recipes = { "gyoza" } },
	{ id = "lic_sushi3", branch = "sushi", level = 14, cost = 45000, rating = 3.5, requires = { "lic_sushi2" }, recipes = { "temaki_salmon", "dragon_roll" } },
	{ id = "lic_ramen3", branch = "ramen", level = 16, cost = 60000, rating = 3.5, requires = { "lic_ramen2" }, recipes = { "tonkotsu_ramen", "tantanmen" } },
	{ id = "lic_fryer", branch = "extra", level = 18, cost = 80000, rating = 0, requires = { "lic_griddle" }, recipes = { "ebi_tempura", "karaage" } },
	{ id = "lic_sushi4", branch = "sushi", level = 22, cost = 110000, rating = 4.0, requires = { "lic_sushi3" }, recipes = { "sashimi_moriawase", "ikura_gunkan" } },
	{ id = "lic_street", branch = "extra", level = 24, cost = 120000, rating = 0, requires = { "lic_fryer" }, recipes = { "takoyaki" } },
	{ id = "lic_ramen4", branch = "ramen", level = 25, cost = 140000, rating = 4.0, requires = { "lic_ramen3" }, recipes = { "tsukemen" } },
	{ id = "lic_dessert", branch = "extra", level = 28, cost = 160000, rating = 0, requires = { "lic_sides" }, recipes = { "mochi", "matcha_latte", "ramune" } },
	{ id = "lic_sushi_master", branch = "sushi", level = 35, cost = 240000, rating = 4.5, requires = { "lic_sushi4" }, recipes = { "otoro_nigiri", "omakase" } },
	{ id = "lic_ramen_master", branch = "ramen", level = 38, cost = 280000, rating = 4.5, requires = { "lic_ramen4" }, recipes = { "mayu_ramen" } },
	{ id = "lic_grandmaster", branch = "master", level = 45, cost = 400000, rating = 4.7, requires = { "lic_sushi_master", "lic_ramen_master" }, recipes = { "kaiseki" } },
}

local byId = {}
for i, l in ipairs(list) do
	l.order = i
	byId[l.id] = l
end

return {
	list = list,
	byId = byId,
	Branches = { "base", "sushi", "ramen", "extra", "master" },
}
