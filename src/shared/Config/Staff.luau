--!nonstrict
-- Staff roles. Training levels 1..5: cost = hire * 0.8 * 2.2^(level-1), +15% speed per level.
local list = {
	{ id = "staff_waiter", icon = "🧑‍🍳", lv = 5, hire = 3500, salary = 300, tasks = { "order", "serve", "collect", "wash" }, shirt = "#2E3A5C" },
	{ id = "staff_dishwasher", icon = "🧽", lv = 4, hire = 2000, salary = 250, tasks = { "wash", "collect" }, shirt = "#4A7A8C" },
	{ id = "staff_stocker", icon = "📦", lv = 7, hire = 6000, salary = 400, tasks = { "restock", "appliance" }, shirt = "#7A5A2E" },
	{ id = "staff_sushi_chef", icon = "🍣", lv = 9, hire = 15000, salary = 900, tasks = { "cook" }, stations = { "sushi" }, shirt = "#F4F1EA" },
	{ id = "staff_ramen_chef", icon = "🍜", lv = 10, hire = 18000, salary = 1000, tasks = { "cook", "appliance" }, stations = { "ramen" }, shirt = "#F4F1EA" },
	{ id = "staff_line_cook", icon = "🍤", lv = 13, hire = 24000, salary = 1100, tasks = { "cook" }, stations = { "drink", "griddle", "fryer", "takoyaki", "dessert" }, shirt = "#B3262E" },
	{ id = "staff_manager", icon = "🎩", lv = 18, hire = 120000, salary = 3000, tasks = {}, manager = true, shirt = "#1E1E22" },
}

local byId = {}
for i, s in ipairs(list) do
	s.order = i
	byId[s.id] = s
end

local NAMES = {
	"Kenji", "Yuki", "Haruto", "Sakura", "Ren", "Aoi", "Sota", "Hina", "Daiki", "Mei",
	"Takumi", "Yui", "Riku", "Nanami", "Kaito", "Rin", "Hiro", "Emi", "Shun", "Koharu",
}

return {
	list = list,
	byId = byId,
	Names = NAMES,
	MaxTrainLevel = 5,
	-- base slots and extra slots granted by expansions
	BaseSlots = 2,
	SlotsByZone = { zone_east = 1, zone_west = 1, zone_terrace = 1, zone_kitchen_pro = 3, zone_floor2 = 3 },
}
