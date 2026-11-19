--!nonstrict
-- 7-day login streak. yen scales with level: yen * (1 + level / 10)
return {
	-- the calendar opens by itself when you join with today's gift still there, or this many
	-- seconds after the tutorial ends (only while no other window is open)
	PopupAfterTutorial = 20,
	-- how long it waits for the other windows to close before giving up for this session
	PopupWait = 120,
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
