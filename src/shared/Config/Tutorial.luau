--!nonstrict
-- The first two minutes (Controllers/Tutorial) and the one-time tips that come after it
-- (Controllers/Hints). Rewards are given by the server (Services/Meta) only when the player
-- really did the thing: a dish served, a dish washed.
return {
	-- after the first dish is served: yen to spend in the shop at once
	ServeYen = 1000,
	-- at the end of the tutorial
	DoneSakura = 10,
	-- every step stays on screen at least this long, even when it is already done (a customer
	-- may have ordered before the step shows)
	MinStepSeconds = 3,
	-- the welcome card (how to move and use things on your device)
	WelcomeSeconds = 7,
	-- the first card waits for the loading screen and your restaurant, at most this long
	StartWait = 30,
	-- one-time tips: id -> when it shows (see Controllers/Hints)
	Hints = {
		restock = { shelfLeft = 3 }, -- an ingredient of the menu has this many portions or fewer on the shelves
		dishes = { pile = 3 }, -- this many dirty dishes in the sink
		shop = {}, -- something in the shop can be bought
		staff = { level = 6 }, -- the first member of staff can be hired
		opensign = { dishes = 3 }, -- after this many dishes: the OPEN / CLOSED sign by the door
	},
	HintSeconds = 12, -- a tip stays this long (or until it is done)
	HintGap = 20, -- seconds between two tips
}
