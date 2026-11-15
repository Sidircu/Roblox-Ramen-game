--!nonstrict
-- Franchise cities (prestige). Each star: +25% yen, +10% XP permanently.
local list = {
	{ id = "tokyo", star = 0, palette = { road = "#2A2A2E", building = "#6B5A4E", accent = "#B3262E", sky = "#9EC3E6" } },
	{ id = "kyoto", star = 1, palette = { road = "#4A4038", building = "#7A5A3A", accent = "#C8462E", sky = "#E6C9A0" } },
	{ id = "osaka", star = 2, palette = { road = "#26262C", building = "#4A4A5A", accent = "#E8B83A", sky = "#8FB0E0" } },
	{ id = "sapporo", star = 3, palette = { road = "#E8ECF0", building = "#5A6A7A", accent = "#3A6EB3", sky = "#C9D9E8" }, snow = true },
	{ id = "fukuoka", star = 4, palette = { road = "#2E2A2A", building = "#6A4A4A", accent = "#D9363E", sky = "#F0B07A" } },
	{ id = "okinawa", star = 5, palette = { road = "#B8A88A", building = "#E8DCC8", accent = "#2EA3B3", sky = "#7FD0F0" } },
}
local byId = {}
for i, c in ipairs(list) do
	c.order = i
	byId[c.id] = c
end
return {
	list = list,
	byId = byId,
	RequiredLevel = 40,
	RequiredRating = 4.5,
	RequiredZones = { "zone_east", "zone_west", "zone_storage2", "zone_terrace", "zone_garden", "zone_tatami", "zone_kitchen_pro", "zone_floor2" },
	YenPerStar = 0.25,
	XpPerStar = 0.10,
	StartYen = 2000,
	RegionalLevel = 5,
}
