--!nonstrict
-- Objects placed in a brand-new restaurant (all can be moved later).
-- s: "f" floor, "w" wall (y = height of the object's center), "c" ceiling, "t" on top of item index p
return {
	items = {
		{ i = "counter_end", x = -11, z = 14.5, r = 0, s = "f" },
		{ i = "counter_straight", x = -8, z = 14.5, r = 0, s = "f" },
		{ i = "counter_straight", x = -4, z = 14.5, r = 0, s = "f" },
		{ i = "counter_straight", x = 0, z = 14.5, r = 0, s = "f" },
		{ i = "counter_end", x = 3, z = 14.5, r = 0, s = "f" },
		{ i = "stool_wood", x = -9, z = 11.9, r = 0, s = "f" },
		{ i = "stool_wood", x = -7, z = 11.9, r = 0, s = "f" },
		{ i = "stool_wood", x = -5, z = 11.9, r = 0, s = "f" },
		{ i = "stool_wood", x = -3, z = 11.9, r = 0, s = "f" },
		{ i = "stool_wood", x = -1, z = 11.9, r = 0, s = "f" },
		{ i = "stool_wood", x = 1, z = 11.9, r = 0, s = "f" },
		{ i = "sushi_station", x = -6, z = 17.6, r = 180, s = "f" },
		{ i = "ramen_station", x = 0, z = 17.6, r = 180, s = "f" },
		{ i = "shelf_small", x = -12, z = 27.25, r = 0, s = "f" },
		{ i = "shelf_small", x = -7, z = 27.25, r = 0, s = "f" },
		{ i = "rice_cooker", x = -16, z = 26.9, r = 0, s = "f" },
		{ i = "broth_pot", x = -2, z = 26.4, r = 0, s = "f" },
		{ i = "sink", x = 6, z = 26.65, r = 0, s = "f" },
		{ i = "storage_rack", x = 24, z = 27, r = 0, s = "f" },
		{ i = "chochin_red", x = -6, z = 6, r = 0, s = "c" },
		{ i = "chochin_red", x = 6, z = 6, r = 0, s = "c" },
		{ i = "chochin_white", x = 0, z = 9, r = 0, s = "c" },
		{ i = "bamboo_pot", x = 16.5, z = 1.5, r = 0, s = "f" },
		{ i = "bamboo_pot", x = -11.5, z = 1.5, r = 0, s = "f" },
		{ i = "menu_plaques", x = 17.45, y = 6.5, z = 6, r = 90, s = "w" },
		{ i = "maneki_neko", x = -11, z = 14.5, r = 0, s = "t", p = 1 },
	},
	boxes = {
		{ g = "rice", n = 2 }, { g = "nori", n = 2 }, { g = "cucumber", n = 2 }, { g = "salmon", n = 2 },
		{ g = "noodles", n = 2 }, { g = "broth_shoyu", n = 2 }, { g = "scallion", n = 2 }, { g = "naruto", n = 2 },
	},
}
