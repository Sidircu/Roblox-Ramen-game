--!nonstrict
-- Emoji icons for catalog cards (no image assets needed).
local Icons = {
	cat = {
		seating = "🪑", kitchen = "🍳", storage = "📦", lighting = "🏮", plants = "🎍", art = "🖼️",
		statues = "🐱", garden = "⛩️", festival = "🎏",
	},
	item = {
		counter_straight = "🍶", counter_corner = "🍶", counter_end = "🍶", stool_wood = "🪑", stool_cushion = "🪑",
		stool_swivel = "🪑", table_2 = "🍽️", table_4 = "🍽️", chair_wood = "🪑", chair_lacquer = "🪑", chabudai = "🍵",
		zabuton = "🟥", booth = "🛋️", zashiki_table = "🎎", waiting_bench = "🪵", shelf_small = "🗄️", shelf_large = "🗄️",
		neta_case = "🐟", rice_cooker = "🍚", rice_cooker_pro = "🍚", broth_pot = "🍲", broth_pot_large = "🍲",
		sushi_station = "🍣", ramen_station = "🍜", drink_station = "🍵", griddle = "🥟", fryer = "🍤",
		takoyaki_stove = "🐙", dessert_station = "🍡", sink = "🚰", dishwasher = "🫧", fridge = "🧊",
		storage_rack = "📦", storage_rack_large = "📦", chochin_red = "🏮", chochin_white = "🏮", andon_lamp = "🕯️",
		paper_pendant = "💡", toro_stone = "🗿", neon_ramen = "🍜", neon_sushi = "🍣", lantern_string = "🏮",
		bamboo_pot = "🎍", kokedama = "🟢", bonsai_pine = "🌲", ikebana = "💐", maple_tree = "🍁", sakura_tree = "🌸",
		bonsai_ancient = "🌳", noren_red = "🎌", menu_plaques = "📜", fan_wall = "🪭", kakejiku = "📜",
		noren_indigo = "🎌", wagasa = "⛱️", wave_painting = "🌊", byobu = "🖼️", kimono_display = "👘",
		maneki_neko = "🐱", daruma = "🔴", soy_barrel = "🛢️", tanuki = "🦝", aquarium = "🐠", samurai_armor = "⚔️",
		maneki_gold = "🐈", dragon_statue = "🐉", stone_path = "🪨", moss_garden = "🌿", shishi_odoshi = "🎋",
		zen_garden = "🪨", koi_pond = "🎏", red_bridge = "🌉", torii_small = "⛩️", waterfall = "💧", torii_gold = "⛩️",
		nobori = "🚩", vending_machine = "🥤", gashapon = "🎰", koinobori = "🎏", taiko = "🥁", yatai = "🛒",
		hanami_dango = "🍡", sakura_garland = "🌸", tanabata_bamboo = "🎋", fireworks_lantern = "🎆", moon_rabbit = "🐇",
		susuki_vase = "🌾", kadomatsu = "🎍", kagami_mochi = "🍊", kyoto_lantern = "🏯", osaka_octopus_sign = "🐙",
		snow_lantern = "⛄", yatai_lanterns = "🏮", shisa_pair = "🦁",
	},
	zone = {
		zone_base = "🏠", zone_east = "🍽️", zone_storage2 = "📦", zone_west = "🍽️", zone_terrace = "🌤️", zone_garden = "🌿",
		zone_tatami = "🎎", zone_kitchen_pro = "👨‍🍳", zone_floor2 = "🏢", sign_rooftop = "🪧", facade_deluxe = "✨", zone_rooftop = "🌃",
	},
}

function Icons.forItem(item)
	return Icons.item[item.id] or Icons.cat[item.cat] or "🎁"
end

return Icons
