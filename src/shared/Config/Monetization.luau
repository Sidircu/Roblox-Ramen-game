--!nonstrict
-- Robux products. Put the real IDs from the Creator Dashboard here; 0 = disabled (hidden).
return {
	GamePasses = {
		{ id = "gp_vip", assetId = 0, effect = { yenMult = 1.25, items = { maneki_gold = 1, chochin_gold = 2, noren_gold = 1 } } }, -- the gold set (Config/Items)
		{ id = "gp_double_yen", assetId = 0, effect = { yenMult = 2 } },
		{ id = "gp_big_tray", assetId = 0, effect = { tray = 2 } },
		{ id = "gp_express", assetId = 0, effect = { cart = 1 } }, -- big cart: one more box at a time
		{ id = "gp_extra_staff", assetId = 0, effect = { staffSlots = 2 } }, -- two more places in the team
		{ id = "gp_starter", assetId = 0, effect = { yen = 10000, items = { stool_cushion = 6, neon_ramen = 1, maneki_neko = 1, sakura_tree = 1 } } },
	},
	Products = {
		{ id = "dp_yen_s", productId = 0, effect = { yen = 1000 } },
		{ id = "dp_yen_m", productId = 0, effect = { yen = 5000 } },
		{ id = "dp_yen_l", productId = 0, effect = { yen = 15000 } },
		{ id = "dp_yen_xl", productId = 0, effect = { yen = 50000 } },
		{ id = "dp_sakura_s", productId = 0, effect = { sakura = 20 } },
		{ id = "dp_sakura_m", productId = 0, effect = { sakura = 120 } },
		{ id = "dp_sakura_l", productId = 0, effect = { sakura = 300 } },
		{ id = "dp_rush_hour", productId = 0, effect = { boost = "rush", seconds = 1800 } },
		{ id = "dp_golden_sign", productId = 0, effect = { boost = "golden", seconds = 1800 } },
	},
	-- yen packs scale with the restaurant level: yen * (1 + level / 5)
	YenLevelScale = 0.2,
}
