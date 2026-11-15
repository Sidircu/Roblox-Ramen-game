--!nonstrict
-- Restaurant zones. Rects are { x0, z0, x1, z1 } relative to the plot origin (street side is -Z).
-- area: dining | kitchen | storage | outdoor | garden | tatami
-- room: walls are generated between different rooms and around the building.
-- openings: doors in walls ({ floor, axis = "z" (wall along X at z = at) | "x" (wall along Z at x = at), from, to }).
-- stairs: { floor (bottom floor), rect } rising towards +Z; the floor above gets a hole.
local list = {
	{
		id = "zone_base", lv = 1, cost = 0, requires = {},
		zones = {
			{ id = "base_dining", rect = { -18, 0, 18, 16 }, floor = 0, area = "dining", room = "main" },
			{ id = "base_kitchen", rect = { -18, 16, 18, 28 }, floor = 0, area = "kitchen", room = "main" },
			{ id = "base_storage", rect = { 18, 12, 30, 28 }, floor = 0, area = "storage", room = "storage" },
		},
		openings = {
			{ floor = 0, axis = "z", at = 0, from = -3, to = 3, kind = "entrance" },
			{ floor = 0, axis = "x", at = 18, from = 20, to = 24, kind = "door" },
			{ floor = 0, axis = "z", at = 12, from = 21, to = 27, kind = "loading" },
		},
	},
	{ id = "zone_east", lv = 3, cost = 5000, requires = { "zone_base" }, zones = { { id = "east_dining", rect = { -34, 0, -18, 16 }, floor = 0, area = "dining", room = "main" } } },
	{ id = "zone_storage2", lv = 5, cost = 8000, requires = { "zone_base" }, zones = { { id = "storage2", rect = { 30, 12, 42, 28 }, floor = 0, area = "storage", room = "storage" } } },
	{ id = "zone_west", lv = 8, cost = 25000, requires = { "zone_east" }, zones = { { id = "west_dining", rect = { -50, 0, -34, 28 }, floor = 0, area = "dining", room = "main" } } },
	{ id = "zone_terrace", lv = 12, cost = 60000, requires = { "zone_base" }, zones = { { id = "terrace", rect = { -18, -9, 18, 0 }, floor = 0, area = "outdoor", outdoor = true, gaps = { { axis = "z", at = -9, from = -3, to = 3 } } } } },
	{
		id = "zone_garden", lv = 15, cost = 100000, requires = { "zone_base" },
		zones = { { id = "garden", rect = { -18, 28, 6, 46 }, floor = 0, area = "garden", outdoor = true } },
		openings = { { floor = 0, axis = "z", at = 28, from = -8, to = -4, kind = "door" } },
	},
	{
		id = "zone_tatami", lv = 18, cost = 180000, requires = { "zone_west" },
		zones = { { id = "tatami", rect = { -50, 28, -34, 44 }, floor = 0, area = "tatami", room = "tatami", floorStyle = "floor_tatami", wallStyle = "wall_shoji" } },
		openings = { { floor = 0, axis = "z", at = 28, from = -44, to = -40, kind = "door" } },
	},
	{ id = "zone_kitchen_pro", lv = 20, cost = 250000, requires = { "zone_east" }, zones = { { id = "kitchen_pro", rect = { -34, 16, -18, 28 }, floor = 0, area = "kitchen", room = "main" } } },
	{
		id = "zone_floor2", lv = 25, cost = 600000, requires = { "zone_base" },
		zones = { { id = "floor2", rect = { -18, 0, 18, 28 }, floor = 1, area = "dining", room = "f2" } },
		stairs = { { floor = 0, rect = { -17.5, 1, -13.5, 15 } } },
	},
	{ id = "sign_rooftop", lv = 28, cost = 500000, requires = { "zone_base" }, popularity = 0.3, cosmetic = true },
	{ id = "facade_deluxe", lv = 30, cost = 1000000, requires = { "zone_base" }, ambience = 60, cosmetic = true },
	{
		id = "zone_rooftop", lv = 35, cost = 2000000, requires = { "zone_floor2" },
		zones = { { id = "rooftop", rect = { -18, 0, 18, 28 }, floor = 2, area = "outdoor", outdoor = true } },
		stairs = { { floor = 1, rect = { 13.5, 1, 17.5, 15 } } },
	},
}

local byId = {}
for i, e in ipairs(list) do
	e.order = i
	byId[e.id] = e
end

return {
	list = list,
	byId = byId,
	-- Fixed points of the plot (relative to origin)
	Entrance = { x = 0, z = -1.5 },
	StreetWalkZ = -11.5,
	StreetEnds = { -110, 110 },
	LoadingBay = { x = 24, z = 5 },
	Supplier = { x = 17.7, y = 5, z = 17.5 },
	MenuBoard = { x = -6.5, z = -1.8 },
	PlotBounds = { -60, -14, 52, 52 },
}
