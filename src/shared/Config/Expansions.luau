--!nonstrict
-- Restaurant zones. Rects are { x0, z0, x1, z1 } relative to the plot origin (street side is -Z).
-- area: dining | kitchen | storage | outdoor | garden | tatami
-- room: walls are generated between different rooms and around the building.
-- openings: doors in walls ({ floor, axis = "z" (wall along X at z = at) | "x" (wall along Z at x = at), from, to }).
-- stairs: corner (L-shaped) staircases. flights = { {rect, dir, from, to} } rising in `dir`
-- ("+z", "+x", "-x") from height `from` to `to` (0..1 of the floor height); landing = flat rect;
-- rects = everything the stairs occupy on the lower floor; hole = opening in the floor above
-- (railings on every side but `exitSide`); entry/exit = where you step on / off.
-- The restaurant is laid out at real scale for the avatars: the base is 72 x 56 studs.
local function cornerStairs(floor, side)
	-- side = -1: along the west wall, turning towards +X; side = 1: mirrored on the east wall
	local s = side
	local x0, x1 = s < 0 and -35 or 29, s < 0 and -29 or 35
	local bx0, bx1 = s < 0 and -29 or 17, s < 0 and -17 or 29
	return {
		floor = floor,
		flights = {
			{ rect = { x0, 4, x1, 14 }, dir = "+z", from = 0, to = 0.5 },
			{ rect = { bx0, 14, bx1, 20 }, dir = s < 0 and "+x" or "-x", from = 0.5, to = 1 },
		},
		landing = { x0, 14, x1, 20 },
		rects = { { x0, 4, x1, 14 }, { x0, 14, x1, 20 }, { bx0, 14, bx1, 20 } },
		hole = { math.min(x0, bx0), 14, math.max(x1, bx1), 20 },
		rect = { math.min(x0, bx0), 4, math.max(x1, bx1), 20 },
		entry = { x = (x0 + x1) / 2, z = 2.5 },
		exit = { x = s < 0 and -15.5 or 15.5, z = 17 },
		exitSide = s < 0 and "x+" or "x-",
		-- handrails: flight 1 on the room side, flight 2 on both sides, landing along the back
		railSides = { { s < 0 and 1 or -1 }, { -1, 1 } },
		landingPosts = { { s < 0 and x1 - 0.3 or x0 + 0.3, 19.7 } },
		landingRails = { { x0 + 0.2, 19.8, x1 - 0.2, 19.8 } },
		-- kept clear so the stairs can be reached (lower floor) and left (upper floor)
		entryRect = { x0, 1.5, x1, 4 },
		exitRect = s < 0 and { -17, 14, -14.5, 20 } or { 14.5, 14, 17, 20 },
	}
end

local list = {
	{
		id = "zone_base", lv = 1, cost = 0, requires = {},
		zones = {
			{ id = "base_dining", rect = { -36, 0, 36, 32 }, floor = 0, area = "dining", room = "main" },
			{ id = "base_kitchen", rect = { -36, 32, 36, 56 }, floor = 0, area = "kitchen", room = "main" },
			{ id = "base_storage", rect = { 36, 24, 60, 56 }, floor = 0, area = "storage", room = "storage" },
		},
		openings = {
			{ floor = 0, axis = "z", at = 0, from = -4, to = 4, kind = "entrance" },
			{ floor = 0, axis = "x", at = 36, from = 40, to = 47, kind = "door" },
			{ floor = 0, axis = "z", at = 24, from = 45, to = 55, kind = "loading" },
		},
	},
	{ id = "zone_east", lv = 3, cost = 5000, requires = { "zone_base" }, zones = { { id = "east_dining", rect = { -68, 0, -36, 32 }, floor = 0, area = "dining", room = "main" } } },
	{ id = "zone_storage2", lv = 5, cost = 8000, requires = { "zone_base" }, zones = { { id = "storage2", rect = { 60, 24, 84, 56 }, floor = 0, area = "storage", room = "storage" } } },
	{ id = "zone_west", lv = 8, cost = 25000, requires = { "zone_east" }, zones = { { id = "west_dining", rect = { -100, 0, -68, 56 }, floor = 0, area = "dining", room = "main" } } },
	{ id = "zone_terrace", lv = 12, cost = 60000, requires = { "zone_base" }, zones = { { id = "terrace", rect = { -36, -10, 36, 0 }, floor = 0, area = "outdoor", outdoor = true, gaps = { { axis = "z", at = -10, from = -4, to = 4 } } } } },
	{
		id = "zone_garden", lv = 15, cost = 100000, requires = { "zone_base" },
		zones = { { id = "garden", rect = { -36, 56, 12, 92 }, floor = 0, area = "garden", outdoor = true } },
		openings = { { floor = 0, axis = "z", at = 56, from = -17, to = -10, kind = "door" } },
	},
	{
		id = "zone_tatami", lv = 18, cost = 180000, requires = { "zone_west" },
		zones = { { id = "tatami", rect = { -100, 56, -68, 88 }, floor = 0, area = "tatami", room = "tatami", floorStyle = "floor_tatami", wallStyle = "wall_shoji" } },
		openings = { { floor = 0, axis = "z", at = 56, from = -88, to = -81, kind = "door" } },
	},
	{ id = "zone_kitchen_pro", lv = 20, cost = 250000, requires = { "zone_east" }, zones = { { id = "kitchen_pro", rect = { -68, 32, -36, 56 }, floor = 0, area = "kitchen", room = "main" } } },
	{
		id = "zone_floor2", lv = 25, cost = 600000, requires = { "zone_base" },
		zones = { { id = "floor2", rect = { -36, 0, 36, 56 }, floor = 1, area = "dining", room = "f2" } },
		stairs = { cornerStairs(0, -1) },
	},
	{ id = "sign_rooftop", lv = 28, cost = 500000, requires = { "zone_base" }, popularity = 0.3, cosmetic = true, reno = "exterior" },
	{ id = "facade_deluxe", lv = 30, cost = 1000000, requires = { "zone_base" }, ambience = 60, cosmetic = true, reno = "exterior" },
	{
		id = "zone_rooftop", lv = 35, cost = 2000000, requires = { "zone_floor2" },
		zones = { { id = "rooftop", rect = { -36, 0, 36, 56 }, floor = 2, area = "outdoor", outdoor = true } },
		stairs = { cornerStairs(1, 1) },
	},
	-- Renovations: the starting restaurant is plain; these add the detailed look piece by piece.
	-- reno = tab group; the shell builder reads the owned ids, `style` keeps the matching
	-- Detail_<style> group inside placeable models (see Registry.build).
	{ id = "reno_storage", lv = 2, cost = 1500, requires = { "zone_base" }, cosmetic = true, reno = "interior", ambience = 2 },
	{ id = "reno_wainscot", lv = 3, cost = 3500, requires = { "zone_base" }, cosmetic = true, reno = "interior", ambience = 5 },
	{ id = "reno_kitchen_tiles", lv = 4, cost = 4000, requires = { "zone_base" }, cosmetic = true, reno = "interior", ambience = 3 },
	{ id = "reno_facade", lv = 4, cost = 6000, requires = { "zone_base" }, cosmetic = true, reno = "exterior", ambience = 6, popularity = 0.03 },
	{ id = "reno_entrance", lv = 5, cost = 8000, requires = { "zone_base" }, cosmetic = true, reno = "exterior", ambience = 8, popularity = 0.04 },
	{ id = "reno_counter", lv = 6, cost = 10000, requires = { "zone_base" }, cosmetic = true, reno = "furniture", style = "counter", ambience = 10 },
	{ id = "reno_eaves", lv = 7, cost = 14000, requires = { "zone_base" }, cosmetic = true, reno = "exterior", ambience = 10, popularity = 0.04 },
	{ id = "reno_kitchen_gear", lv = 8, cost = 16000, requires = { "zone_base" }, cosmetic = true, reno = "furniture", style = "kitchen", ambience = 6 },
	{ id = "reno_windows", lv = 9, cost = 18000, requires = { "zone_base" }, cosmetic = true, reno = "exterior", ambience = 10 },
	{ id = "reno_beams", lv = 10, cost = 22000, requires = { "reno_wainscot" }, cosmetic = true, reno = "interior", ambience = 14 },
	{ id = "reno_tableware", lv = 11, cost = 28000, requires = { "zone_base" }, cosmetic = true, reno = "furniture", style = "tableware", ambience = 16 },
	{ id = "reno_bamboo", lv = 13, cost = 40000, requires = { "reno_facade" }, cosmetic = true, reno = "exterior", ambience = 18 },
	{ id = "reno_furnish", lv = 15, cost = 60000, requires = { "zone_base" }, cosmetic = true, reno = "furniture", style = "furnish", ambience = 24 },
}

local byId = {}
for i, e in ipairs(list) do
	e.order = i
	byId[e.id] = e
end

-- Set of detail styles owned with these zones/renovations ({ counter = true, ... })
local function styles(zones)
	local out = {}
	for _, e in ipairs(list) do
		if e.style and zones and zones[e.id] then
			out[e.style] = true
		end
	end
	return out
end

-- Every style (used by previews and thumbnails that show the finished look)
local function allStyles()
	local out = {}
	for _, e in ipairs(list) do
		if e.style then
			out[e.style] = true
		end
	end
	return out
end

return {
	list = list,
	byId = byId,
	styles = styles,
	allStyles = allStyles,
	-- Fixed points of the plot (relative to origin)
	Entrance = { x = 0, z = -1.5 },
	StreetWalkZ = -11.5,
	StreetEnds = { -150, 150 },
	LoadingBay = { x = 50, z = 12 },
	Supplier = { x = 35.7, y = 5, z = 35 },
	MenuBoard = { x = -12, z = -2.6 },
	PlotBounds = { -110, -14, 96, 100 },
	-- strip in front of the street wall kept free for the facade details
	FacadeBand = { -110, -1.6, 96, 0 },
}
