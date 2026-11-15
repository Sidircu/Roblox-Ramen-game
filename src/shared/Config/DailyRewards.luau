--!nonstrict
-- 7-day login streak. yen scales with level: yen * (1 + level / 10)
return {
	days = {
		{ yen = 500 },
		{ yen = 1000 },
		{ sakura = 3 },
		{ yen = 2500 },
		{ sakura = 5 },
		{ yen = 5000 },
		{ sakura = 15, item = "noren_indigo" },
	},
}
