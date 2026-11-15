--!nonstrict
-- Floor and wall styles, applied per zone.
local list = {
	{ id = "floor_wood_light", kind = "floor", price = 0, lv = 1, color = "#C8A27A", material = "WoodPlanks" },
	{ id = "floor_wood_dark", kind = "floor", price = 2000, lv = 3, color = "#5E3E28", material = "WoodPlanks" },
	{ id = "floor_tatami", kind = "floor", price = 5000, lv = 6, color = "#C9C083", material = "Fabric" },
	{ id = "floor_slate", kind = "floor", price = 8000, lv = 10, color = "#4A4D52", material = "Slate" },
	{ id = "floor_pebble", kind = "floor", price = 12000, lv = 14, color = "#9A948A", material = "Cobblestone" },
	{ id = "floor_marble", kind = "floor", price = 40000, lv = 26, color = "#1E1E22", material = "Marble" },
	{ id = "floor_hinoki", kind = "floor", price = 80000, lv = 34, color = "#E3C79A", material = "Wood" },
	{ id = "wall_plaster", kind = "wall", price = 0, lv = 1, color = "#EFE3CC", material = "Plaster" },
	{ id = "wall_wood", kind = "wall", price = 2500, lv = 3, color = "#8A5A36", material = "WoodPlanks" },
	{ id = "wall_shoji", kind = "wall", price = 6000, lv = 7, color = "#F6F0E0", material = "SmoothPlastic", lattice = true },
	{ id = "wall_brick", kind = "wall", price = 9000, lv = 12, color = "#5A3A30", material = "Brick" },
	{ id = "wall_bamboo", kind = "wall", price = 15000, lv = 16, color = "#B8A15A", material = "Wood", stripes = true },
	{ id = "wall_yakisugi", kind = "wall", price = 30000, lv = 22, color = "#262220", material = "Wood" },
	{ id = "wall_gold", kind = "wall", price = 120000, lv = 38, color = "#B8862E", material = "Foil" },
}

local byId = {}
for i, s in ipairs(list) do
	s.order = i
	s.amb = math.min(40, s.price / 1000)
	byId[s.id] = s
end

return {
	list = list,
	byId = byId,
	DefaultFloor = "floor_wood_light",
	DefaultWall = "wall_plaster",
	OutdoorFloor = "deck",
}
