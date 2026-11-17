--!nonstrict
-- Roblox-style rewards: free gifts for the minutes played in a session, redeemable codes, the
-- serving combo and running. See docs/03-BILANCIAMENTO.md §11.
return {
	-- free gifts unlocked by minutes played in this session (they start again when you rejoin)
	-- yen grow with the level: yen * (1 + level * GiftYenPerLevel); boxes go to the storage room
	Gifts = {
		{ min = 2, yen = 250 },
		{ min = 5, sakura = 2 },
		{ min = 9, boxes = { salmon = 1, noodles = 1 } },
		{ min = 14, yen = 900 },
		{ min = 20, sakura = 5 },
		{ min = 28, yen = 2200 },
		{ min = 38, boxes = { broth_shoyu = 2, rice = 1 } },
		{ min = 50, sakura = 10 },
		{ min = 65, yen = 6000 },
	},
	GiftYenPerLevel = 0.12,
	-- yen given instead of boxes to a helper (boxes belong to the owner's storage room)
	GiftBoxYen = 400,
	-- codes (case does not matter), each works once per player
	Codes = {
		RAMEN = { yen = 500 },
		SAKURA = { sakura = 5 },
		ITADAKIMASU = { yen = 1500 },
		OISHII = { sakura = 10 },
		NEWSHOP = { yen = 3000 },
	},
	-- serving combo: each dish served within Window seconds of the previous one raises the tip
	-- of that customer by Step, up to Max steps
	Combo = { Window = 30, Step = 0.05, Max = 10 },
	-- running: hold Shift (the 🏃 button on phones and tablets)
	RunMultiplier = 1.45,
}
