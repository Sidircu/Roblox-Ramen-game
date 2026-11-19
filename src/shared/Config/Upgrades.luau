--!nonstrict
-- Upgrades: costs[n] buys level n, levels[n] is the required restaurant level,
-- values[n + 1] is the effect at level n (values[1] = level 0).
local function geometric(base, factor, count)
	local out = {}
	for i = 1, count do
		out[i] = math.floor(base * factor ^ (i - 1) + 0.5)
	end
	return out
end

local list = {
	{ id = "up_tray", icon = "🍱", max = 4, costs = { 900, 6000, 30000, 120000 }, levels = { 2, 8, 18, 30 }, values = { 1, 2, 3, 4, 5 }, effect = "tray" },
	{ id = "up_shoes", icon = "👟", max = 5, costs = geometric(600, 3, 5), levels = { 1, 4, 8, 14, 22 }, values = { 1, 1.08, 1.16, 1.24, 1.32, 1.40 }, effect = "walk" },
	{ id = "up_knife", icon = "🔪", max = 4, costs = { 1200, 12000, 80000, 350000 }, levels = { 2, 8, 16, 28 }, values = { 1, 0.9, 0.81, 0.73, 0.66 }, effect = "step" },
	{ id = "up_mat", icon = "🎋", max = 3, costs = { 1800, 18000, 120000 }, levels = { 3, 10, 20 }, values = { 1, 0.88, 0.77, 0.68 }, effect = "step" },
	{ id = "up_strainer", icon = "🥢", max = 3, costs = { 1800, 18000, 120000 }, levels = { 3, 10, 20 }, values = { 1, 0.88, 0.77, 0.68 }, effect = "step" },
	{ id = "up_shelf", icon = "🗄️", max = 3, costs = { 5000, 30000, 200000 }, levels = { 4, 12, 24 }, values = { 1, 1.25, 1.5, 1.75 }, effect = "shelf" },
	-- deliveries are immediate (the truck takes a few seconds): this upgrade is a box cart instead
	{ id = "up_cart", icon = "🛒", max = 2, costs = { 1500, 12000 }, levels = { 3, 10 }, values = { 1, 2, 3 }, effect = "cart" },
	{ id = "up_supplier", icon = "📦", max = 2, costs = { 20000, 200000 }, levels = { 10, 25 }, values = { 0, 0.10, 0.20 }, effect = "discount" },
	{ id = "up_sign", icon = "🏮", max = 5, costs = geometric(1200, 4, 5), levels = { 2, 6, 12, 20, 30 }, values = { 0, 0.08, 0.16, 0.24, 0.32, 0.40 }, effect = "popularity" },
	-- customers order by themselves: the order bar holds one ticket per seat at least
	{ id = "up_ticket", icon = "🧾", max = 2, costs = { 6000, 60000 }, levels = { 5, 15 }, values = { 12, 16, 20 }, effect = "tickets" },
	{ id = "up_jukebox", icon = "🎶", max = 3, costs = { 5000, 50000, 300000 }, levels = { 4, 14, 26 }, values = { 0, 15, 40, 90 }, effect = "ambience" },
	{ id = "up_safe", icon = "💰", max = 5, costs = geometric(10000, 4, 5), levels = { 6, 12, 18, 26, 34 }, values = { 1, 2, 4, 8, 12, 24 }, pct = { 0.05, 0.10, 0.15, 0.20, 0.25, 0.30 }, effect = "offline" },
	{ id = "up_autorestock", icon = "🔁", max = 1, costs = { 120000 }, levels = { 20 }, values = { 0, 1 }, effect = "autorestock", needsStaff = "staff_stocker" },
}

local byId = {}
for i, u in ipairs(list) do
	u.order = i
	byId[u.id] = u
end

local function value(upgrades, id)
	local u = byId[id]
	local lvl = (upgrades and upgrades[id]) or 0
	return u.values[lvl + 1] or u.values[#u.values]
end

return {
	list = list,
	byId = byId,
	value = value,
}
