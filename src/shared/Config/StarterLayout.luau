--!nonstrict
-- Objects placed in a brand-new restaurant (all can be moved later). The start is plain on
-- purpose: decorations and renovations (Config/Expansions) are bought over time.
-- s: "f" floor, "w" wall (y = height of the object's center), "c" ceiling, "t" on top of item index p
return {
	items = {
		-- long counter facing the dining room: twelve 3-stud modules (one seat and one place setting
		-- each, so customers never overlap) between two ends, 40 studs, low (3) and deep (3.8)
		{ i = "counter_end", x = -23, z = 30.05, r = 0, s = "f" },
		{ i = "counter_straight", x = -20.5, z = 30.05, r = 0, s = "f" },
		{ i = "counter_straight", x = -17.5, z = 30.05, r = 0, s = "f" },
		{ i = "counter_straight", x = -14.5, z = 30.05, r = 0, s = "f" },
		{ i = "counter_straight", x = -11.5, z = 30.05, r = 0, s = "f" },
		{ i = "counter_straight", x = -8.5, z = 30.05, r = 0, s = "f" },
		{ i = "counter_straight", x = -5.5, z = 30.05, r = 0, s = "f" },
		{ i = "counter_straight", x = -2.5, z = 30.05, r = 0, s = "f" },
		{ i = "counter_straight", x = 0.5, z = 30.05, r = 0, s = "f" },
		{ i = "counter_straight", x = 3.5, z = 30.05, r = 0, s = "f" },
		{ i = "counter_straight", x = 6.5, z = 30.05, r = 0, s = "f" },
		{ i = "counter_straight", x = 9.5, z = 30.05, r = 0, s = "f" },
		{ i = "counter_straight", x = 12.5, z = 30.05, r = 0, s = "f" },
		{ i = "counter_end", x = 15, z = 30.05, r = 0, s = "f" },
		-- tip jar on the far end of the counter (index 14 = that end)
		{ i = "tip_jar", x = 15, z = 30.05, r = 0, s = "t", p = 14 },
		{ i = "stool_wood", x = -20.5, z = 27.3, r = 0, s = "f" },
		{ i = "stool_wood", x = -17.5, z = 27.3, r = 0, s = "f" },
		{ i = "stool_wood", x = -14.5, z = 27.3, r = 0, s = "f" },
		{ i = "stool_wood", x = -11.5, z = 27.3, r = 0, s = "f" },
		{ i = "stool_wood", x = -8.5, z = 27.3, r = 0, s = "f" },
		{ i = "stool_wood", x = -5.5, z = 27.3, r = 0, s = "f" },
		{ i = "stool_wood", x = -2.5, z = 27.3, r = 0, s = "f" },
		{ i = "stool_wood", x = 0.5, z = 27.3, r = 0, s = "f" },
		{ i = "stool_wood", x = 3.5, z = 27.3, r = 0, s = "f" },
		{ i = "stool_wood", x = 6.5, z = 27.3, r = 0, s = "f" },
		{ i = "stool_wood", x = 9.5, z = 27.3, r = 0, s = "f" },
		{ i = "stool_wood", x = 12.5, z = 27.3, r = 0, s = "f" },
		-- stations right behind the counter, the cook works facing it
		{ i = "sushi_station", x = -11, z = 33.3, r = 180, s = "f" },
		{ i = "ramen_station", x = -3, z = 33.3, r = 180, s = "f" },
		-- everything against the back wall, 9 studs behind the stations: the two shelves right behind
		-- the stations (the trip you make for every order), then the fitted kitchen unit (rice
		-- cooker, gas range, worktop, sink, worktop) towards the storage door
		{ i = "shelf_small", x = -10.2, z = 44.55, r = 0, s = "f" },
		{ i = "shelf_small", x = -4.4, z = 44.55, r = 0, s = "f" },
		{ i = "rice_cooker", x = -0.1, z = 44.3, r = 0, s = "f" },
		{ i = "broth_pot", x = 3.2, z = 44.3, r = 0, s = "f" },
		{ i = "kitchen_counter", x = 6.5, z = 44.3, r = 0, s = "f" },
		{ i = "sink", x = 9.8, z = 44.3, r = 0, s = "f" },
		{ i = "kitchen_counter", x = 13.1, z = 44.3, r = 0, s = "f" },
		{ i = "storage_rack", x = 48, z = 54.6, r = 0, s = "f" },
		-- a single paper lantern: every other decoration is bought (see docs/01-GAME-DESIGN.md)
		{ i = "chochin_white", x = -6, z = 20, r = 0, s = "c" },
	},
	-- the storage room starts empty: the tutorial has you order the ramen ingredients; the pot
	-- starts full of this broth and the rice cooker full of rice
	boxes = {},
	broth = "broth_shoyu",

}
