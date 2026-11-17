--!nonstrict
-- Objects placed in a brand-new restaurant (all can be moved later). The start is plain on
-- purpose: decorations and renovations (Config/Expansions) are bought over time.
-- s: "f" floor, "w" wall (y = height of the object's center), "c" ceiling, "t" on top of item index p
return {
	items = {
		-- long counter facing the dining room (28 studs), twelve stools in front of it
		{ i = "counter_end", x = -21, z = 30.4, r = 0, s = "f" },
		{ i = "counter_straight", x = -18, z = 30.4, r = 0, s = "f" },
		{ i = "counter_straight", x = -14, z = 30.4, r = 0, s = "f" },
		{ i = "counter_straight", x = -10, z = 30.4, r = 0, s = "f" },
		{ i = "counter_straight", x = -6, z = 30.4, r = 0, s = "f" },
		{ i = "counter_straight", x = -2, z = 30.4, r = 0, s = "f" },
		{ i = "counter_straight", x = 2, z = 30.4, r = 0, s = "f" },
		{ i = "counter_end", x = 5, z = 30.4, r = 0, s = "f" },
		-- tip jar at the end of the counter: tips wait in it until you click it (index 8 = that end)
		{ i = "tip_jar", x = 5, z = 30.4, r = 0, s = "t", p = 8 },
		{ i = "stool_wood", x = -19, z = 27.8, r = 0, s = "f" },
		{ i = "stool_wood", x = -17, z = 27.8, r = 0, s = "f" },
		{ i = "stool_wood", x = -15, z = 27.8, r = 0, s = "f" },
		{ i = "stool_wood", x = -13, z = 27.8, r = 0, s = "f" },
		{ i = "stool_wood", x = -11, z = 27.8, r = 0, s = "f" },
		{ i = "stool_wood", x = -9, z = 27.8, r = 0, s = "f" },
		{ i = "stool_wood", x = -7, z = 27.8, r = 0, s = "f" },
		{ i = "stool_wood", x = -5, z = 27.8, r = 0, s = "f" },
		{ i = "stool_wood", x = -3, z = 27.8, r = 0, s = "f" },
		{ i = "stool_wood", x = -1, z = 27.8, r = 0, s = "f" },
		{ i = "stool_wood", x = 1, z = 27.8, r = 0, s = "f" },
		{ i = "stool_wood", x = 3, z = 27.8, r = 0, s = "f" },
		-- stations right behind the counter, the cook works facing it
		{ i = "sushi_station", x = -11, z = 33.3, r = 180, s = "f" },
		{ i = "ramen_station", x = -3, z = 33.3, r = 180, s = "f" },
		-- back line across a wide aisle: one fitted kitchen unit (same height, depth and tiles) with
		-- the rice cooker, the gas range with the stock pot, a worktop, the sink and another worktop,
		-- then two shelves on the side of the storage door (short walk with the boxes)
		{ i = "shelf_small", x = 7.4, z = 42.2, r = 0, s = "f" },
		{ i = "shelf_small", x = 13.9, z = 42.2, r = 0, s = "f" },
		{ i = "rice_cooker", x = -10.7, z = 42.45, r = 0, s = "f" },
		{ i = "broth_pot", x = -7.4, z = 42.45, r = 0, s = "f" },
		{ i = "kitchen_counter", x = -4.1, z = 42.45, r = 0, s = "f" },
		{ i = "sink", x = -0.8, z = 42.45, r = 0, s = "f" },
		{ i = "kitchen_counter", x = 2.5, z = 42.45, r = 0, s = "f" },
		{ i = "storage_rack", x = 48, z = 54.6, r = 0, s = "f" },
		-- a single paper lantern: every other decoration is bought (see docs/01-GAME-DESIGN.md)
		{ i = "chochin_white", x = -6, z = 20, r = 0, s = "c" },
	},
	-- the storage room starts empty: the tutorial has you order the ramen ingredients; the pot
	-- starts full of this broth and the rice cooker full of rice
	boxes = {},
	broth = "broth_shoyu",

}
