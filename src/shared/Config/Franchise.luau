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
-- What the next city asks for (index = the star it gives): the first franchise comes after a
-- few hours of play (level 12, the first three rooms), every next one asks for more.
local Steps = {
	{ level = 12, rating = 4.0, zones = { "zone_east", "zone_storage2", "zone_west" } },
	{ level = 16, rating = 4.1, zones = { "zone_east", "zone_storage2", "zone_west", "zone_terrace", "zone_garden" } },
	{ level = 20, rating = 4.2, zones = { "zone_east", "zone_storage2", "zone_west", "zone_terrace", "zone_garden", "zone_tatami", "zone_kitchen_pro" } },
	{ level = 25, rating = 4.3, zones = { "zone_east", "zone_storage2", "zone_west", "zone_terrace", "zone_garden", "zone_tatami", "zone_kitchen_pro", "zone_floor2" } },
	{ level = 30, rating = 4.4, zones = { "zone_east", "zone_storage2", "zone_west", "zone_terrace", "zone_garden", "zone_tatami", "zone_kitchen_pro", "zone_floor2" } },
}

return {
	list = list,
	byId = byId,
	Steps = Steps,
	-- the requirements of the next franchise for a restaurant with `stars` stars (nil: all done)
	nextStep = function(stars)
		return Steps[(stars or 0) + 1]
	end,
	YenPerStar = 0.25,
	XpPerStar = 0.10,
	StartYen = 2000,
	RegionalLevel = 5,
}
