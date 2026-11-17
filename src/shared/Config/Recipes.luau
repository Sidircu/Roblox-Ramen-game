--!nonstrict
-- Recipes. `ing` are the ingredients the cook brings to the station by hand;
-- `rice` = takes one cooked rice portion from a rice cooker; `broth` = takes one portion
-- of that broth from a pot. Every station must have unique ingredient sets.
-- steps: combine, cut, roll, mold, boil, pour, top, batter, fry, flip (one click each)
-- cat: eating category (sushi, ramen, side, drink, dessert)
-- dish: visual model used by Models/Builders/Food
local list = {
	-- Base
	{ id = "kappa_maki", station = "sushi", ing = { "nori", "cucumber" }, rice = true, steps = { "combine", "roll", "cut" }, price = 25, xp = 8, cat = "sushi", license = "lic_sushi0", icon = "🍣", dish = "maki" },
	{ id = "sake_nigiri", station = "sushi", ing = { "salmon" }, rice = true, steps = { "cut", "combine" }, price = 40, xp = 10, cat = "sushi", license = "lic_sushi0", icon = "🍣", dish = "nigiri" },
	{ id = "sake_sashimi", station = "sushi", ing = { "salmon", "salmon" }, steps = { "cut" }, price = 45, xp = 9, cat = "sushi", license = "lic_sashimi", icon = "🍣", dish = "sashimi" },
	{ id = "shoyu_ramen", station = "ramen", ing = { "noodles", "scallion", "naruto" }, broth = "broth_shoyu", steps = { "boil", "pour", "top" }, price = 55, xp = 14, cat = "ramen", license = "lic_base", icon = "🍜", dish = "bowl" },
	-- Sushi I
	{ id = "tekka_maki", station = "sushi", ing = { "nori", "tuna" }, rice = true, steps = { "combine", "roll", "cut" }, price = 45, xp = 12, cat = "sushi", license = "lic_sushi1", icon = "🍣", dish = "maki" },
	{ id = "maguro_nigiri", station = "sushi", ing = { "tuna" }, rice = true, steps = { "cut", "combine" }, price = 50, xp = 13, cat = "sushi", license = "lic_sushi1", icon = "🍣", dish = "nigiri" },
	-- Ramen I
	{ id = "shio_ramen", station = "ramen", ing = { "noodles", "scallion", "egg" }, broth = "broth_shio", steps = { "boil", "pour", "top" }, price = 62, xp = 16, cat = "ramen", license = "lic_ramen1", icon = "🍜", dish = "bowl" },
	-- Sides & tea
	{ id = "edamame", station = "drink", ing = { "edamame" }, steps = { "pour" }, price = 20, xp = 5, cat = "side", license = "lic_sides", icon = "🫛", dish = "edamame" },
	{ id = "green_tea", station = "drink", ing = { "green_tea" }, steps = { "pour" }, price = 12, xp = 3, cat = "drink", license = "lic_sides", icon = "🍵", dish = "cup" },
	{ id = "miso_soup", station = "ramen", ing = { "miso_paste", "tofu", "scallion" }, steps = { "combine", "pour" }, price = 18, xp = 5, cat = "side", license = "lic_sides", icon = "🥣", dish = "soup" },
	-- Sushi II
	{ id = "california_roll", station = "sushi", ing = { "nori", "surimi", "avocado", "cucumber", "sesame" }, rice = true, steps = { "combine", "roll", "cut" }, price = 85, xp = 22, cat = "sushi", license = "lic_sushi2", icon = "🍣", dish = "roll" },
	{ id = "ebi_nigiri", station = "sushi", ing = { "shrimp" }, rice = true, steps = { "cut", "combine" }, price = 60, xp = 16, cat = "sushi", license = "lic_sushi2", icon = "🍤", dish = "nigiri" },
	-- Ramen II
	{ id = "miso_ramen", station = "ramen", ing = { "noodles", "corn", "butter", "scallion" }, broth = "broth_miso", steps = { "boil", "pour", "top" }, price = 90, xp = 24, cat = "ramen", license = "lic_ramen2", icon = "🍜", dish = "bowl" },
	-- Griddle
	{ id = "gyoza", station = "griddle", ing = { "gyoza_raw" }, steps = { "flip", "flip" }, price = 45, xp = 12, cat = "side", license = "lic_griddle", icon = "🥟", dish = "gyoza" },
	-- Sushi III
	{ id = "temaki_salmon", station = "sushi", ing = { "nori", "salmon", "avocado" }, rice = true, steps = { "combine", "roll" }, price = 95, xp = 26, cat = "sushi", license = "lic_sushi3", icon = "🍣", dish = "temaki" },
	{ id = "dragon_roll", station = "sushi", ing = { "nori", "eel", "avocado", "eel_sauce" }, rice = true, steps = { "combine", "roll", "cut", "top" }, price = 150, xp = 38, cat = "sushi", license = "lic_sushi3", icon = "🐉", dish = "roll" },
	-- Ramen III
	{ id = "tonkotsu_ramen", station = "ramen", ing = { "noodles", "chashu", "egg", "kikurage" }, broth = "broth_tonkotsu", steps = { "boil", "pour", "top" }, price = 140, xp = 36, cat = "ramen", license = "lic_ramen3", icon = "🍜", dish = "bowl" },
	{ id = "tantanmen", station = "ramen", ing = { "noodles", "minced_pork", "chili_oil", "scallion" }, broth = "broth_tonkotsu", steps = { "boil", "pour", "top" }, price = 150, xp = 38, cat = "ramen", license = "lic_ramen3", icon = "🌶️", dish = "bowl" },
	-- Fryer
	{ id = "ebi_tempura", station = "fryer", ing = { "shrimp", "batter" }, steps = { "batter", "fry" }, price = 90, xp = 24, cat = "side", license = "lic_fryer", icon = "🍤", dish = "fried" },
	{ id = "karaage", station = "fryer", ing = { "chicken", "batter" }, steps = { "batter", "fry" }, price = 80, xp = 22, cat = "side", license = "lic_fryer", icon = "🍗", dish = "fried" },
	-- Sushi IV
	{ id = "sashimi_moriawase", station = "sushi", ing = { "salmon", "tuna", "yellowtail", "daikon" }, steps = { "cut", "cut", "combine" }, price = 260, xp = 60, cat = "sushi", license = "lic_sushi4", icon = "🍱", dish = "sashimi" },
	{ id = "ikura_gunkan", station = "sushi", ing = { "nori", "ikura" }, rice = true, steps = { "combine", "roll" }, price = 180, xp = 44, cat = "sushi", license = "lic_sushi4", icon = "🍣", dish = "gunkan" },
	-- Street food
	{ id = "takoyaki", station = "takoyaki", ing = { "octopus", "batter", "scallion" }, steps = { "pour", "flip" }, price = 110, xp = 28, cat = "side", license = "lic_street", icon = "🐙", dish = "takoyaki" },
	-- Ramen IV
	{ id = "tsukemen", station = "ramen", ing = { "tsukemen_noodles", "chashu", "egg" }, broth = "broth_tonkotsu", steps = { "boil", "pour", "top" }, price = 200, xp = 50, cat = "ramen", license = "lic_ramen4", icon = "🍜", dish = "tsukemen" },
	-- Desserts & matcha
	{ id = "mochi", station = "dessert", ing = { "mochi", "matcha" }, steps = { "combine", "mold" }, price = 70, xp = 18, cat = "dessert", license = "lic_dessert", icon = "🍡", dish = "mochi" },
	{ id = "matcha_latte", station = "drink", ing = { "matcha" }, steps = { "pour" }, price = 60, xp = 14, cat = "drink", license = "lic_dessert", icon = "🍵", dish = "cup" },
	{ id = "ramune", station = "drink", ing = { "ramune" }, steps = { "pour" }, price = 35, xp = 6, cat = "drink", license = "lic_dessert", icon = "🥤", dish = "bottle" },
	-- Masters
	{ id = "otoro_nigiri", station = "sushi", ing = { "otoro" }, rice = true, steps = { "cut", "combine" }, price = 300, xp = 75, cat = "sushi", license = "lic_sushi_master", icon = "🍣", dish = "nigiri" },
	{ id = "omakase", station = "sushi", ing = { "otoro", "yellowtail", "ikura", "shrimp", "nori" }, rice = true, steps = { "cut", "cut", "combine", "roll" }, price = 900, xp = 200, cat = "sushi", license = "lic_sushi_master", icon = "🍱", dish = "platter" },
	{ id = "mayu_ramen", station = "ramen", ing = { "noodles", "black_garlic", "chashu", "egg", "kikurage" }, broth = "broth_tonkotsu", steps = { "boil", "pour", "top" }, price = 320, xp = 80, cat = "ramen", license = "lic_ramen_master", icon = "🍜", dish = "bowl" },
	{ id = "kaiseki", station = "sushi", ing = { "otoro", "ikura", "noodles", "matcha", "mochi" }, rice = true, broth = "broth_tonkotsu", steps = { "cut", "combine", "boil", "pour", "top" }, price = 2000, xp = 450, cat = "sushi", license = "lic_grandmaster", icon = "🎌", dish = "platter" },
	-- Regional dishes (Franchise cities, unlocked at level 5 in that city)
	{ id = "yudofu", station = "ramen", ing = { "tofu", "scallion" }, broth = "broth_shio", steps = { "combine", "pour" }, price = 120, xp = 30, cat = "side", city = "kyoto", icon = "🍲", dish = "soup" },
	{ id = "matcha_soba", station = "ramen", ing = { "tsukemen_noodles", "matcha", "scallion" }, broth = "broth_shoyu", steps = { "boil", "pour", "top" }, price = 220, xp = 55, cat = "ramen", city = "kyoto", icon = "🍵", dish = "bowl" },
	{ id = "okonomiyaki", station = "griddle", ing = { "batter", "minced_pork", "scallion" }, steps = { "pour", "flip", "flip" }, price = 180, xp = 45, cat = "side", city = "osaka", icon = "🥞", dish = "okonomiyaki" },
	{ id = "kushikatsu", station = "fryer", ing = { "chicken", "batter", "sesame" }, steps = { "batter", "fry" }, price = 140, xp = 35, cat = "side", city = "osaka", icon = "🍢", dish = "fried" },
	{ id = "butter_corn_ramen", station = "ramen", ing = { "noodles", "butter", "corn", "chashu" }, broth = "broth_miso", steps = { "boil", "pour", "top" }, price = 260, xp = 65, cat = "ramen", city = "sapporo", icon = "🌽", dish = "bowl" },
	{ id = "jingisukan", station = "griddle", ing = { "minced_pork", "scallion", "corn" }, steps = { "flip", "flip" }, price = 200, xp = 50, cat = "side", city = "sapporo", icon = "🥩", dish = "okonomiyaki" },
	{ id = "hakata_ramen", station = "ramen", ing = { "noodles", "scallion", "kikurage" }, broth = "broth_tonkotsu", steps = { "boil", "pour", "top" }, price = 240, xp = 60, cat = "ramen", city = "fukuoka", icon = "🍜", dish = "bowl" },
	{ id = "yatai_gyoza", station = "griddle", ing = { "gyoza_raw", "chili_oil" }, steps = { "flip", "flip" }, price = 150, xp = 38, cat = "side", city = "fukuoka", icon = "🥟", dish = "gyoza" },
	{ id = "okinawa_soba", station = "ramen", ing = { "noodles", "chashu", "scallion" }, broth = "broth_shio", steps = { "boil", "pour", "top" }, price = 250, xp = 62, cat = "ramen", city = "okinawa", icon = "🍜", dish = "bowl" },
	{ id = "goya_champuru", station = "griddle", ing = { "tofu", "egg", "minced_pork" }, steps = { "combine", "flip" }, price = 210, xp = 52, cat = "side", city = "okinawa", icon = "🥗", dish = "okonomiyaki" },
}

local byId = {}
local byStation = {}
for i, r in ipairs(list) do
	r.order = i
	byId[r.id] = r
	byStation[r.station] = byStation[r.station] or {}
	table.insert(byStation[r.station], r)
	-- sorted ingredient key for exact matching on the board
	local sorted = table.clone(r.ing)
	table.sort(sorted)
	r.key = table.concat(sorted, "+")
end

return {
	list = list,
	byId = byId,
	byStation = byStation,
	Stations = { "sushi", "ramen", "drink", "griddle", "fryer", "takoyaki", "dessert" },
}
