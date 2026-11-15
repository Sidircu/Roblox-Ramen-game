--!nonstrict
-- Decoration sets: placing every item of a set grants its bonus.
local list = {
	{ id = "matsuri", items = { "lantern_string", "nobori", "taiko", "yatai", "koinobori" }, bonus = { tip = 0.05 } },
	{ id = "zen", items = { "moss_garden", "zen_garden", "shishi_odoshi", "stone_path", "bonsai_pine" }, bonus = { popularity = 0.10 } },
	{ id = "samurai", items = { "samurai_armor", "kakejiku", "byobu", "daruma", "wave_painting" }, bonus = { tip = 0.05 } },
	{ id = "neon", items = { "neon_ramen", "neon_sushi", "vending_machine", "gashapon", "chochin_red" }, bonus = { popularity = 0.10 } },
	{ id = "sakura", items = { "sakura_tree", "koi_pond", "red_bridge", "torii_small", "wagasa" }, bonus = { tip = 0.05, popularity = 0.05 } },
}
local byId = {}
for i, s in ipairs(list) do
	s.order = i
	byId[s.id] = s
end
return { list = list, byId = byId }
