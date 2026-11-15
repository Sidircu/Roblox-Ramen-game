--!nonstrict
-- Customer types. prefer: recipe categories or tags with doubled order probability.
local list = {
	{ id = "cust_student", lv = 1, weight = 30, group = { 1, 1 }, patience = 70, tip = 0.7, prefer = { "ramen", "cheap" }, look = "casual" },
	{ id = "cust_salaryman", lv = 1, weight = 30, group = { 1, 1 }, patience = 50, lunchPatience = 35, tip = 1.0, prefer = { "ramen" }, look = "suit" },
	{ id = "cust_tourist", lv = 3, weight = 15, group = { 1, 2 }, patience = 100, tip = 1.4, prefer = { "sushi" }, look = "tourist" },
	{ id = "cust_couple", lv = 3, weight = 12, group = { 2, 2 }, patience = 80, tip = 1.1, prefer = { "sushi", "dessert" }, look = "casual", needsTable = true },
	{ id = "cust_elder", lv = 5, weight = 8, group = { 1, 1 }, patience = 130, tip = 1.0, prefer = { "drink", "side", "sushi" }, look = "elder" },
	{ id = "cust_family", lv = 6, weight = 10, group = { 3, 4 }, patience = 90, tip = 1.0, prefer = {}, look = "casual", needsTable = true },
	{ id = "cust_influencer", lv = 10, weight = 2, group = { 1, 1 }, patience = 45, tip = 1.5, prefer = { "expensive" }, look = "trendy", influencer = true },
	{ id = "cust_critic", lv = 12, weight = 1.5, group = { 1, 1 }, patience = 80, tip = 1.6, prefer = { "mastery" }, look = "suit", reviewWeight = 5 },
	{ id = "cust_vip", lv = 18, weight = 3, group = { 2, 4 }, patience = 150, tip = 2.5, prefer = { "expensive" }, look = "vip", vip = true, ordersEach = 3 },
	{ id = "cust_celebrity", lv = 30, weight = 0.3, group = { 1, 1 }, patience = 90, tip = 5.0, prefer = { "expensive" }, look = "vip", celebrity = true },
}
local byId = {}
for i, c in ipairs(list) do
	c.order = i
	byId[c.id] = c
end
return { list = list, byId = byId }
