--!nonstrict
-- Catalog of placeable objects.
-- place: "floor" | "wall" | "ceiling" | "top" (on counters/tables)
-- areas: zone area types where the object can be placed
-- size: { width (X), height (Y), depth (Z) } in studs, local front faces -Z
-- fn: functional behaviour (seat, counter, table, booth, shelf, ricecooker, pot, station, sink,
--     dishwasher, rack, bench, fridge); decorations have no fn.
-- Optional: license, set, event (seasonal, paid with sakura), franchise (city exclusive), sakura (token price)
local SEAT = { "dining", "outdoor", "tatami" }
local DECOR = { "dining", "kitchen", "storage", "outdoor", "garden", "tatami" }
local INDOOR = { "dining", "kitchen", "storage", "tatami" }
local OUT = { "outdoor", "garden" }
local KITCHEN = { "kitchen" }

local list = {
	-- Seating, tables and counter -------------------------------------------------------------
	{ id = "counter_straight", cat = "seating", price = 750, lv = 1, place = "floor", areas = SEAT, size = { 3, 3, 3.8 }, amb = 0, fn = { type = "counter" } },
	{ id = "counter_corner", cat = "seating", price = 1200, lv = 1, place = "floor", areas = SEAT, size = { 3.8, 3, 3.8 }, amb = 0, fn = { type = "counter" } },
	{ id = "counter_end", cat = "seating", price = 800, lv = 1, place = "floor", areas = SEAT, size = { 2, 3, 3.8 }, amb = 0, fn = { type = "counter" } },
	{ id = "stool_wood", cat = "seating", price = 80, lv = 1, place = "floor", areas = SEAT, size = { 1.6, 2.4, 1.6 }, amb = 0, fn = { type = "seat", comfort = 1, height = 2.4, symmetric = true } },
	{ id = "stool_cushion", cat = "seating", price = 300, lv = 4, place = "floor", areas = SEAT, size = { 1.6, 2.4, 1.6 }, amb = 1, fn = { type = "seat", comfort = 2, height = 2.4, symmetric = true } },
	{ id = "stool_swivel", cat = "seating", price = 900, lv = 12, place = "floor", areas = SEAT, size = { 1.8, 2.4, 1.8 }, amb = 2, fn = { type = "seat", comfort = 3, height = 2.4, symmetric = true } },
	{ id = "table_2", cat = "seating", price = 600, lv = 3, place = "floor", areas = SEAT, size = { 3, 2.6, 3 }, amb = 1, fn = { type = "table" } },
	{ id = "table_4", cat = "seating", price = 1400, lv = 6, place = "floor", areas = SEAT, size = { 5, 2.6, 3 }, amb = 2, fn = { type = "table" } },
	{ id = "chair_wood", cat = "seating", price = 150, lv = 3, place = "floor", areas = SEAT, size = { 1.6, 3.5, 1.6 }, amb = 0, fn = { type = "seat", comfort = 1, height = 1.8 } },
	{ id = "chair_lacquer", cat = "seating", price = 700, lv = 14, place = "floor", areas = SEAT, size = { 1.6, 3.5, 1.6 }, amb = 2, fn = { type = "seat", comfort = 3, height = 1.8 } },
	{ id = "chabudai", cat = "seating", price = 1800, lv = 10, place = "floor", areas = SEAT, size = { 4, 1.2, 4 }, amb = 3, fn = { type = "table" } },
	{ id = "zabuton", cat = "seating", price = 200, lv = 10, place = "floor", areas = SEAT, size = { 1.8, 0.4, 1.8 }, amb = 1, fn = { type = "seat", comfort = 2, height = 0.4, symmetric = true } },
	{ id = "stool_red", cat = "seating", price = 220, lv = 2, place = "floor", areas = SEAT, size = { 1.6, 2.4, 1.6 }, amb = 1, set = "ramenya", fn = { type = "seat", comfort = 2, height = 2.4, symmetric = true } },
	{ id = "bench_table", cat = "seating", price = 2400, lv = 7, place = "floor", areas = SEAT, size = { 5, 2.7, 5 }, amb = 3, fn = { type = "booth", comfort = 2, seats = 4 } },
	{ id = "booth", cat = "seating", price = 5000, lv = 15, place = "floor", areas = SEAT, size = { 6, 4, 5 }, amb = 6, fn = { type = "booth", comfort = 4, seats = 4 } },
	{ id = "zashiki_table", cat = "seating", price = 30000, lv = 18, place = "floor", areas = { "tatami" }, size = { 6, 1.3, 6 }, amb = 12, fn = { type = "booth", comfort = 5, seats = 4, vip = true } },
	{ id = "waiting_bench", cat = "seating", price = 500, lv = 2, place = "floor", areas = { "dining", "outdoor" }, size = { 5, 2, 1.5 }, amb = 1, fn = { type = "bench", queue = 3 } },

	-- Kitchen ------------------------------------------------------------------------------------
	{ id = "shelf_small", cat = "kitchen", price = 400, lv = 1, place = "floor", areas = KITCHEN, size = { 5.6, 7.4, 2 }, amb = 0, fn = { type = "shelf", slots = 4 } },
	{ id = "shelf_large", cat = "kitchen", price = 1500, lv = 7, place = "floor", areas = KITCHEN, size = { 7.8, 8.4, 2 }, amb = 0, fn = { type = "shelf", slots = 6 } },
	-- bigger and nicer shelves (more slots, each still half a box): tall wooden one with a little
	-- noren, a bamboo market shelf with lanterns, a black lacquer pantry with gold trim and lights
	{ id = "shelf_tall", cat = "kitchen", price = 4000, lv = 10, place = "floor", areas = KITCHEN, size = { 7.8, 10, 2 }, amb = 2, fn = { type = "shelf", slots = 8, cols = 2, style = "tall" } },
	{ id = "shelf_market", cat = "kitchen", price = 9000, lv = 15, place = "floor", areas = KITCHEN, size = { 9.6, 8.8, 2.2 }, amb = 4, fn = { type = "shelf", slots = 9, cols = 3, style = "bamboo" } },
	{ id = "shelf_deluxe", cat = "kitchen", price = 25000, lv = 22, place = "floor", areas = KITCHEN, size = { 11, 10, 2.4 }, amb = 8, fn = { type = "shelf", slots = 12, cols = 3, style = "lacquer" } },
	{ id = "neta_case", cat = "kitchen", price = 3000, lv = 5, place = "floor", areas = KITCHEN, size = { 5, 3.2, 2.2 }, amb = 3, fn = { type = "shelf", slots = 4, fishOnly = true, fresh = true } },
	{ id = "rice_cooker", cat = "kitchen", price = 600, lv = 1, place = "floor", areas = KITCHEN, size = { 2.6, 4.9, 2.5 }, amb = 0, fn = { type = "ricecooker", batch = 10, time = 20 } },
	{ id = "rice_cooker_pro", cat = "kitchen", price = 5000, lv = 11, place = "floor", areas = KITCHEN, size = { 3, 5.1, 2.5 }, amb = 0, fn = { type = "ricecooker", batch = 25, time = 15 } },
	{ id = "broth_pot", cat = "kitchen", price = 900, lv = 1, place = "floor", areas = KITCHEN, size = { 4, 4.6, 2.5 }, amb = 0, fn = { type = "pot", batch = 16, time = 30 } },
	{ id = "broth_pot_large", cat = "kitchen", price = 7500, lv = 13, place = "floor", areas = KITCHEN, size = { 4.6, 4.8, 2.5 }, amb = 0, fn = { type = "pot", batch = 32, time = 25 } },
	{ id = "sushi_station", cat = "kitchen", price = 800, lv = 1, place = "floor", areas = KITCHEN, size = { 5, 3.5, 2.5 }, amb = 0, fn = { type = "station", station = "sushi" } },
	{ id = "ramen_station", cat = "kitchen", price = 1500, lv = 1, place = "floor", areas = KITCHEN, size = { 5, 3.5, 2.5 }, amb = 0, fn = { type = "station", station = "ramen" } },
	{ id = "drink_station", cat = "kitchen", price = 2000, lv = 5, place = "floor", areas = KITCHEN, size = { 4, 3.5, 2.5 }, amb = 0, license = "lic_sides", fn = { type = "station", station = "drink" } },
	{ id = "griddle", cat = "kitchen", price = 6000, lv = 12, place = "floor", areas = KITCHEN, size = { 4, 3.5, 2.5 }, amb = 0, license = "lic_griddle", fn = { type = "station", station = "griddle" } },
	{ id = "fryer", cat = "kitchen", price = 8000, lv = 18, place = "floor", areas = KITCHEN, size = { 3, 3.5, 2.5 }, amb = 0, license = "lic_fryer", fn = { type = "station", station = "fryer" } },
	{ id = "takoyaki_stove", cat = "kitchen", price = 9000, lv = 24, place = "floor", areas = KITCHEN, size = { 3, 3.5, 2.5 }, amb = 0, license = "lic_street", fn = { type = "station", station = "takoyaki" } },
	{ id = "dessert_station", cat = "kitchen", price = 10000, lv = 28, place = "floor", areas = KITCHEN, size = { 4, 3.5, 2.5 }, amb = 0, license = "lic_dessert", fn = { type = "station", station = "dessert" } },
	{ id = "kitchen_counter", cat = "kitchen", price = 250, lv = 1, place = "floor", areas = KITCHEN, size = { 2.6, 3.5, 2.5 }, amb = 0, fn = { type = "worktop" } },
	{ id = "sink", cat = "kitchen", price = 500, lv = 1, place = "floor", areas = KITCHEN, size = { 4, 3.5, 2.5 }, amb = 0, fn = { type = "sink" } },
	{ id = "dishwasher", cat = "kitchen", price = 12000, lv = 13, place = "floor", areas = KITCHEN, size = { 3, 3.5, 2.5 }, amb = 0, fn = { type = "dishwasher", cap = 6, interval = 20 } },
	{ id = "fridge", cat = "kitchen", price = 15000, lv = 16, place = "floor", areas = KITCHEN, size = { 3, 7, 2.5 }, amb = 0, fn = { type = "fridge", radius = 14 } },

	-- Storage ------------------------------------------------------------------------------------
	{ id = "storage_rack", cat = "storage", price = 700, lv = 1, place = "floor", areas = { "storage" }, size = { 6, 4.4, 2 }, amb = 0, fn = { type = "rack", cols = 3, rows = 2 } },
	{ id = "storage_rack_large", cat = "storage", price = 3000, lv = 9, place = "floor", areas = { "storage" }, size = { 6, 8.2, 2 }, amb = 0, fn = { type = "rack", cols = 3, rows = 4 } },

	-- Lighting -----------------------------------------------------------------------------------
	{ id = "chochin_red", cat = "lighting", price = 150, lv = 1, place = "ceiling", areas = INDOOR, size = { 1.4, 2.4, 1.4 }, amb = 2, set = "neon" },
	{ id = "chochin_white", cat = "lighting", price = 150, lv = 1, place = "ceiling", areas = INDOOR, size = { 1.4, 2.4, 1.4 }, amb = 2 },
	{ id = "andon_lamp", cat = "lighting", price = 600, lv = 3, place = "floor", areas = DECOR, size = { 1.4, 3, 1.4 }, amb = 5 },
	{ id = "paper_pendant", cat = "lighting", price = 900, lv = 5, place = "ceiling", areas = INDOOR, size = { 1.8, 2.6, 1.8 }, amb = 6 },
	{ id = "toro_stone", cat = "lighting", price = 1200, lv = 6, place = "floor", areas = DECOR, size = { 1.8, 4.5, 1.8 }, amb = 8 },
	{ id = "pendant_lamp", cat = "lighting", price = 350, lv = 2, place = "ceiling", areas = INDOOR, size = { 1.2, 3.2, 1.2 }, amb = 3 },
	{ id = "chochin_orange", cat = "lighting", price = 200, lv = 2, place = "ceiling", areas = INDOOR, size = { 1.4, 2.4, 1.4 }, amb = 2 },
	-- the gold set: two lanterns, a noren and the golden maneki-neko come free with the VIP pass,
	-- everybody else can buy them with yen at higher levels
	{ id = "chochin_gold", cat = "lighting", price = 6000, lv = 10, place = "ceiling", areas = INDOOR, size = { 1.4, 2.4, 1.4 }, amb = 6, gamepass = "gp_vip" },
	{ id = "ramenya_canopy", cat = "lighting", price = 4500, lv = 9, place = "ceiling", areas = INDOOR, size = { 8, 4.2, 2.6 }, amb = 18, set = "ramenya" },
	{ id = "neon_ramen", cat = "lighting", price = 3500, lv = 8, place = "wall", areas = INDOOR, size = { 6, 2, 0.4 }, amb = 15, set = "neon" },
	{ id = "neon_sushi", cat = "lighting", price = 3500, lv = 10, place = "wall", areas = INDOOR, size = { 4, 2.2, 0.4 }, amb = 15, set = "neon" },
	{ id = "lantern_string", cat = "lighting", price = 2000, lv = 12, place = "ceiling", areas = INDOOR, size = { 8, 1.8, 0.6 }, amb = 10, set = "matsuri" },

	-- Plants -------------------------------------------------------------------------------------
	{ id = "bamboo_pot", cat = "plants", price = 300, lv = 1, place = "floor", areas = DECOR, size = { 1.6, 5, 1.6 }, amb = 3 },
	{ id = "kokedama", cat = "plants", price = 250, lv = 2, place = "ceiling", areas = INDOOR, size = { 1.2, 2.6, 1.2 }, amb = 2 },
	{ id = "bonsai_pine", cat = "plants", price = 900, lv = 4, place = "top", areas = DECOR, size = { 1.8, 1.6, 1.2 }, amb = 7, set = "zen" },
	{ id = "ikebana", cat = "plants", price = 700, lv = 7, place = "top", areas = DECOR, size = { 1.2, 1.8, 1.2 }, amb = 5 },
	{ id = "maple_tree", cat = "plants", price = 6000, lv = 15, place = "floor", areas = OUT, size = { 6, 11, 6 }, amb = 25 },
	{ id = "sakura_tree", cat = "plants", price = 12000, lv = 20, place = "floor", areas = OUT, size = { 7, 12, 7 }, amb = 40, set = "sakura" },
	{ id = "bonsai_ancient", cat = "plants", price = 45000, lv = 32, place = "floor", areas = DECOR, size = { 3, 4, 3 }, amb = 60 },

	-- Art & walls --------------------------------------------------------------------------------
	{ id = "noren_red", cat = "art", price = 250, lv = 1, place = "wall", areas = INDOOR, size = { 4, 3, 0.3 }, amb = 3 },
	{ id = "menu_plaques", cat = "art", price = 300, lv = 1, place = "wall", areas = INDOOR, size = { 4, 2.5, 0.3 }, amb = 3 },
	{ id = "menu_posters", cat = "art", price = 450, lv = 3, place = "wall", areas = INDOOR, size = { 6, 2.2, 0.2 }, amb = 4, set = "ramenya" },
	{ id = "noren_banner", cat = "art", price = 700, lv = 4, place = "ceiling", areas = INDOOR, size = { 8, 1.8, 0.3 }, amb = 5, set = "ramenya" },
	{ id = "ramen_poster", cat = "art", price = 600, lv = 5, place = "wall", areas = INDOOR, size = { 2.4, 3.2, 0.2 }, amb = 5 },
	{ id = "ramen_sign_vertical", cat = "art", price = 900, lv = 6, place = "wall", areas = INDOOR, size = { 1.6, 5, 0.9 }, amb = 6 },
	{ id = "soup_sign", cat = "art", price = 1600, lv = 8, place = "wall", areas = INDOOR, size = { 6, 2.6, 0.9 }, amb = 9 },
	{ id = "fan_wall", cat = "art", price = 350, lv = 2, place = "wall", areas = INDOOR, size = { 3, 1.8, 0.3 }, amb = 3 },
	{ id = "kakejiku", cat = "art", price = 700, lv = 3, place = "wall", areas = INDOOR, size = { 1.8, 4.5, 0.3 }, amb = 5, set = "samurai" },
	{ id = "noren_indigo", cat = "art", price = 400, lv = 5, place = "wall", areas = INDOOR, size = { 4, 3, 0.3 }, amb = 4 },
	{ id = "noren_gold", cat = "art", price = 9000, lv = 12, place = "wall", areas = INDOOR, size = { 4, 3, 0.3 }, amb = 8, gamepass = "gp_vip" },
	{ id = "wagasa", cat = "art", price = 650, lv = 6, place = "floor", areas = DECOR, size = { 3.5, 4.5, 3.5 }, amb = 5, set = "sakura" },
	{ id = "wave_painting", cat = "art", price = 1500, lv = 9, place = "wall", areas = INDOOR, size = { 5, 3, 0.3 }, amb = 9, set = "samurai" },
	{ id = "byobu", cat = "art", price = 1800, lv = 10, place = "floor", areas = DECOR, size = { 6, 4.5, 0.6 }, amb = 10, set = "samurai" },
	{ id = "kimono_display", cat = "art", price = 4000, lv = 18, place = "floor", areas = DECOR, size = { 4, 6, 1 }, amb = 18 },

	-- Statues & objects --------------------------------------------------------------------------
	{ id = "water_pitcher", cat = "tabletop", price = 120, lv = 1, place = "top", areas = DECOR, size = { 1.0, 1.3, 1.1 }, amb = 1, set = "ramenya" },
	{ id = "tip_jar", cat = "tabletop", price = 150, lv = 1, place = "top", areas = DECOR, size = { 0.9, 1.3, 0.9 }, amb = 1, fn = { type = "tipjar" } },
	{ id = "condiment_caddy", cat = "tabletop", price = 180, lv = 1, place = "top", areas = DECOR, size = { 1.6, 1.1, 0.7 }, amb = 2 },
	{ id = "counter_posters", cat = "tabletop", price = 650, lv = 4, place = "top", areas = DECOR, size = { 3.8, 1.4, 0.5 }, amb = 5 },
	{ id = "maneki_neko", cat = "statues", price = 500, lv = 2, place = "top", areas = DECOR, size = { 0.9, 1.3, 0.8 }, amb = 6, tipBonus = 0.01, tipMax = 3 },
	{ id = "daruma", cat = "statues", price = 350, lv = 3, place = "top", areas = DECOR, size = { 1, 1.1, 1 }, amb = 3, set = "samurai" },
	{ id = "soy_barrel", cat = "statues", price = 450, lv = 4, place = "floor", areas = DECOR, size = { 2.2, 2.6, 2.2 }, amb = 4 },
	{ id = "tanuki", cat = "statues", price = 1100, lv = 8, place = "floor", areas = DECOR, size = { 1.8, 3, 1.6 }, amb = 7 },
	{ id = "aquarium", cat = "statues", price = 9000, lv = 16, place = "floor", areas = INDOOR, size = { 5, 5, 2 }, amb = 30 },
	{ id = "samurai_armor", cat = "statues", price = 25000, lv = 28, place = "floor", areas = DECOR, size = { 2.4, 6, 2 }, amb = 50, set = "samurai" },
	{ id = "maneki_gold", cat = "statues", price = 250000, lv = 30, place = "top", areas = DECOR, size = { 1.2, 1.7, 1 }, amb = 30, tipBonus = 0.03, tipMax = 1, gamepass = "gp_vip" },
	{ id = "dragon_statue", cat = "statues", price = 150000, lv = 40, place = "floor", areas = DECOR, size = { 5, 6, 4 }, amb = 120 },

	-- Garden & water -----------------------------------------------------------------------------
	{ id = "stone_path", cat = "garden", price = 120, lv = 5, place = "floor", areas = DECOR, size = { 2, 0.2, 2 }, amb = 1, set = "zen", walkable = true },
	{ id = "moss_garden", cat = "garden", price = 2500, lv = 11, place = "floor", areas = DECOR, size = { 4, 0.8, 4 }, amb = 12, set = "zen" },
	{ id = "shishi_odoshi", cat = "garden", price = 4000, lv = 14, place = "floor", areas = DECOR, size = { 3.5, 2.6, 2 }, amb = 20, set = "zen" },
	{ id = "zen_garden", cat = "garden", price = 8000, lv = 17, place = "floor", areas = DECOR, size = { 6, 0.8, 6 }, amb = 30, set = "zen" },
	{ id = "koi_pond", cat = "garden", price = 15000, lv = 20, place = "floor", areas = OUT, size = { 8, 1, 6 }, amb = 45, set = "sakura" },
	{ id = "red_bridge", cat = "garden", price = 18000, lv = 24, place = "floor", areas = OUT, size = { 3, 2.4, 8 }, amb = 40, set = "sakura", walkable = true },
	{ id = "torii_small", cat = "garden", price = 20000, lv = 25, place = "floor", areas = OUT, size = { 6, 7, 1.2 }, amb = 50, set = "sakura", walkable = true },
	{ id = "waterfall", cat = "garden", price = 60000, lv = 36, place = "floor", areas = OUT, size = { 6, 8, 4 }, amb = 80 },
	{ id = "torii_gold", cat = "garden", price = 500000, lv = 45, place = "floor", areas = OUT, size = { 8, 9, 1.5 }, amb = 200, walkable = true },

	-- Festival -----------------------------------------------------------------------------------
	{ id = "nobori", cat = "festival", price = 450, lv = 4, place = "floor", areas = DECOR, size = { 1.4, 7, 0.6 }, amb = 4, set = "matsuri" },
	{ id = "vending_machine", cat = "festival", price = 2200, lv = 9, place = "floor", areas = DECOR, size = { 3, 6.5, 2.2 }, amb = 8, set = "neon" },
	{ id = "gashapon", cat = "festival", price = 2800, lv = 11, place = "floor", areas = DECOR, size = { 1.8, 4.5, 1.6 }, amb = 10, set = "neon" },
	{ id = "koinobori", cat = "festival", price = 1600, lv = 12, place = "floor", areas = OUT, size = { 2, 10, 2 }, amb = 8, set = "matsuri" },
	{ id = "taiko", cat = "festival", price = 3000, lv = 13, place = "floor", areas = DECOR, size = { 3, 3.5, 2.4 }, amb = 15, set = "matsuri" },
	{ id = "yatai", cat = "festival", price = 10000, lv = 19, place = "floor", areas = { "dining", "outdoor", "garden" }, size = { 6, 7, 4 }, amb = 35, set = "matsuri" },

	-- Seasonal event items (paid with sakura tokens while the event is active) -------------------
	{ id = "hanami_dango", cat = "festival", price = 0, sakura = 40, lv = 1, place = "floor", areas = DECOR, size = { 3, 5, 2.5 }, amb = 25, event = "hanami" },
	{ id = "sakura_garland", cat = "festival", price = 0, sakura = 25, lv = 1, place = "wall", areas = INDOOR, size = { 6, 1.2, 0.4 }, amb = 15, event = "hanami" },
	{ id = "tanabata_bamboo", cat = "festival", price = 0, sakura = 40, lv = 1, place = "floor", areas = DECOR, size = { 2, 8, 2 }, amb = 25, event = "tanabata" },
	{ id = "fireworks_lantern", cat = "festival", price = 0, sakura = 25, lv = 1, place = "ceiling", areas = INDOOR, size = { 1.4, 2.4, 1.4 }, amb = 15, event = "tanabata" },
	{ id = "moon_rabbit", cat = "festival", price = 0, sakura = 35, lv = 1, place = "floor", areas = DECOR, size = { 1.6, 2, 1.4 }, amb = 22, event = "tsukimi" },
	{ id = "susuki_vase", cat = "festival", price = 0, sakura = 20, lv = 1, place = "top", areas = DECOR, size = { 1, 2.2, 1 }, amb = 12, event = "tsukimi" },
	{ id = "kadomatsu", cat = "festival", price = 0, sakura = 40, lv = 1, place = "floor", areas = DECOR, size = { 2, 5, 2 }, amb = 25, event = "shogatsu" },
	{ id = "kagami_mochi", cat = "festival", price = 0, sakura = 20, lv = 1, place = "top", areas = DECOR, size = { 1, 1.4, 1 }, amb = 12, event = "shogatsu" },

	-- Franchise city exclusives (unlocked by opening a restaurant in that city) ------------------
	{ id = "kyoto_lantern", cat = "lighting", price = 30000, lv = 1, place = "floor", areas = DECOR, size = { 2.4, 6, 2.4 }, amb = 60, franchise = "kyoto" },
	{ id = "osaka_octopus_sign", cat = "art", price = 40000, lv = 1, place = "wall", areas = INDOOR, size = { 6, 4, 0.8 }, amb = 70, franchise = "osaka" },
	{ id = "snow_lantern", cat = "lighting", price = 50000, lv = 1, place = "floor", areas = DECOR, size = { 2.4, 4, 2.4 }, amb = 80, franchise = "sapporo" },
	{ id = "yatai_lanterns", cat = "lighting", price = 60000, lv = 1, place = "ceiling", areas = INDOOR, size = { 8, 2.4, 0.8 }, amb = 90, franchise = "fukuoka" },
	{ id = "shisa_pair", cat = "statues", price = 80000, lv = 1, place = "floor", areas = DECOR, size = { 5, 2.6, 1.6 }, amb = 110, franchise = "okinawa" },
}

local byId = {}
for i, it in ipairs(list) do
	it.order = i
	byId[it.id] = it
end

return {
	list = list,
	byId = byId,
	Categories = { "seating", "tabletop", "kitchen", "storage", "lighting", "plants", "art", "statues", "garden", "festival" },
}
