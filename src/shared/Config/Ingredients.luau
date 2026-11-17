--!nonstrict
-- Ingredients sold by the supplier in boxes.
-- storage: "shelf" (shelves), "fish" (shelves or neta case, freshness bonus in the case),
--          "rice" (poured into a rice cooker), "broth" (poured into a broth pot)
-- shape: visual used on shelves/boards: fillet, veg, pack, sack, jar, bottle, noodle, egg, sheet, ball, leaf
local list = {
	{ id = "rice", units = 20, price = 60, storage = "rice", license = "lic_base", icon = "🍚", color = "#F4F1EA", shape = "sack" },
	{ id = "nori", units = 30, price = 45, storage = "shelf", license = "lic_base", icon = "🟩", color = "#1E2B1E", shape = "sheet" },
	{ id = "cucumber", units = 16, price = 32, storage = "shelf", license = "lic_base", icon = "🥒", color = "#4E8A3A", shape = "veg" },
	{ id = "salmon", units = 12, price = 120, storage = "fish", license = "lic_base", icon = "🐟", color = "#F28C5A", shape = "fillet" },
	{ id = "noodles", units = 20, price = 80, storage = "shelf", license = "lic_base", icon = "🍜", color = "#F2D27A", shape = "noodle" },
	{ id = "broth_shoyu", units = 16, price = 96, storage = "broth", license = "lic_base", icon = "🥣", color = "#7A4A22", shape = "jar" },
	{ id = "scallion", units = 30, price = 45, storage = "shelf", license = "lic_base", icon = "🌱", color = "#6DB33F", shape = "leaf" },
	{ id = "naruto", units = 20, price = 60, storage = "shelf", license = "lic_base", icon = "🍥", color = "#F7F3F3", shape = "pack" },
	{ id = "tuna", units = 12, price = 168, storage = "fish", license = "lic_sushi1", icon = "🐟", color = "#B8293A", shape = "fillet" },
	{ id = "egg", units = 12, price = 72, storage = "shelf", license = "lic_ramen1", icon = "🥚", color = "#F3C24A", shape = "egg" },
	{ id = "broth_shio", units = 16, price = 96, storage = "broth", license = "lic_ramen1", icon = "🥣", color = "#E9D9A8", shape = "jar" },
	{ id = "edamame", units = 20, price = 60, storage = "shelf", license = "lic_sides", icon = "🫛", color = "#7DBA4A", shape = "pack" },
	{ id = "green_tea", units = 30, price = 60, storage = "shelf", license = "lic_sides", icon = "🍵", color = "#8DB55A", shape = "jar" },
	{ id = "miso_paste", units = 16, price = 96, storage = "shelf", license = "lic_sides", icon = "🟫", color = "#B5803A", shape = "jar" },
	{ id = "tofu", units = 20, price = 50, storage = "shelf", license = "lic_sides", icon = "⬜", color = "#F6F2E6", shape = "pack" },
	{ id = "avocado", units = 12, price = 72, storage = "shelf", license = "lic_sushi2", icon = "🥑", color = "#7FA33A", shape = "veg" },
	{ id = "surimi", units = 16, price = 80, storage = "shelf", license = "lic_sushi2", icon = "🦀", color = "#E8544A", shape = "pack" },
	{ id = "sesame", units = 40, price = 40, storage = "shelf", license = "lic_sushi2", icon = "⚪", color = "#E9DCC0", shape = "jar" },
	{ id = "shrimp", units = 12, price = 144, storage = "fish", license = "lic_sushi2", icon = "🦐", color = "#F48A6A", shape = "fillet" },
	{ id = "broth_miso", units = 16, price = 128, storage = "broth", license = "lic_ramen2", icon = "🥣", color = "#C58A3E", shape = "jar" },
	{ id = "corn", units = 20, price = 40, storage = "shelf", license = "lic_ramen2", icon = "🌽", color = "#F4CF3B", shape = "pack" },
	{ id = "butter", units = 20, price = 60, storage = "shelf", license = "lic_ramen2", icon = "🧈", color = "#F7E39A", shape = "pack" },
	{ id = "gyoza_raw", units = 24, price = 120, storage = "shelf", license = "lic_griddle", icon = "🥟", color = "#F1E6CC", shape = "pack" },
	{ id = "eel", units = 10, price = 220, storage = "fish", license = "lic_sushi3", icon = "🐍", color = "#6B4325", shape = "fillet" },
	{ id = "eel_sauce", units = 30, price = 60, storage = "shelf", license = "lic_sushi3", icon = "🫙", color = "#3B2414", shape = "bottle" },
	{ id = "broth_tonkotsu", units = 16, price = 192, storage = "broth", license = "lic_ramen3", icon = "🥣", color = "#F1E4C8", shape = "jar" },
	{ id = "chashu", units = 12, price = 144, storage = "shelf", license = "lic_ramen3", icon = "🥓", color = "#C9845A", shape = "pack" },
	{ id = "kikurage", units = 20, price = 80, storage = "shelf", license = "lic_ramen3", icon = "🍄", color = "#2E2420", shape = "pack" },
	{ id = "minced_pork", units = 12, price = 120, storage = "shelf", license = "lic_ramen3", icon = "🥩", color = "#B5544A", shape = "pack" },
	{ id = "chili_oil", units = 16, price = 96, storage = "shelf", license = "lic_ramen3", icon = "🌶️", color = "#C0261E", shape = "bottle" },
	{ id = "batter", units = 20, price = 40, storage = "shelf", license = "lic_fryer", icon = "🥣", color = "#F3E6B5", shape = "sack" },
	{ id = "chicken", units = 12, price = 120, storage = "shelf", license = "lic_fryer", icon = "🍗", color = "#E8B48A", shape = "pack" },
	{ id = "yellowtail", units = 10, price = 200, storage = "fish", license = "lic_sushi4", icon = "🐟", color = "#F2D3C2", shape = "fillet" },
	{ id = "ikura", units = 10, price = 260, storage = "fish", license = "lic_sushi4", icon = "🔴", color = "#F2541B", shape = "jar" },
	{ id = "daikon", units = 20, price = 40, storage = "shelf", license = "lic_sushi4", icon = "🥕", color = "#F7F6F0", shape = "veg" },
	{ id = "octopus", units = 12, price = 180, storage = "fish", license = "lic_street", icon = "🐙", color = "#C2455A", shape = "fillet" },
	{ id = "tsukemen_noodles", units = 20, price = 110, storage = "shelf", license = "lic_ramen4", icon = "🍜", color = "#E8C26A", shape = "noodle" },
	{ id = "mochi", units = 12, price = 96, storage = "shelf", license = "lic_dessert", icon = "🍡", color = "#F7D9E3", shape = "ball" },
	{ id = "matcha", units = 20, price = 100, storage = "shelf", license = "lic_dessert", icon = "🍵", color = "#6E9A3A", shape = "jar" },
	{ id = "ramune", units = 12, price = 72, storage = "shelf", license = "lic_dessert", icon = "🥤", color = "#7FC8E8", shape = "bottle" },
	{ id = "otoro", units = 8, price = 480, storage = "fish", license = "lic_sushi_master", icon = "🐟", color = "#F0A8A0", shape = "fillet" },
	{ id = "black_garlic", units = 16, price = 160, storage = "shelf", license = "lic_ramen_master", icon = "🧄", color = "#1A1412", shape = "bottle" },
}

local byId = {}
for i, ing in ipairs(list) do
	ing.order = i
	byId[ing.id] = ing
end

return {
	list = list,
	byId = byId,
}
