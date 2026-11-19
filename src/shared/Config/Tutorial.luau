--!nonstrict
-- The first two minutes (Controllers/Tutorial) and the one-time tips that come after it
-- (Controllers/Hints). Rewards are given by the server (Services/Meta) only when the player
-- really did the thing: a dish served, a dish washed.
return {
	-- after the first dish is served: yen to spend in the shop at once
	ServeYen = 1000,
	-- at the end of the tutorial
	DoneSakura = 10,
	-- one-time tips: id -> when it shows (see Controllers/Hints)
	Hints = {
		restock = { shelfLeft = 3 }, -- an ingredient of the menu has this many portions or fewer on the shelves
		dishes = { pile = 3 }, -- this many dirty dishes in the sink
		shop = {}, -- something in the shop can be bought
		staff = { level = 6 }, -- the first member of staff can be hired
	},
	HintSeconds = 12, -- a tip stays this long (or until it is done)
	HintGap = 20, -- seconds between two tips
}
