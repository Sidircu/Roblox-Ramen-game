--!nonstrict
-- Sounds. Every id comes from the public Roblox Creator Store library (Pro Sound Effects, APM Music
-- and Roblox UI sounds), so it plays in any experience. Each effect lists one or more takes: one is
-- picked at random and slightly re-pitched so repeated actions never sound identical.
--   ids    takes to choose from
--   volume base volume (multiplied by the player's sfx setting)
--   pitch  { min, max } PlaybackSpeed range
--   len    stop after this many seconds (with a short fade) for long recordings
--   start  start this many seconds into the recording
--   range  hearing distance in studs for positional sounds
local function a(id)
	return "rbxassetid://" .. id
end

local CHOP = {}
for _, id in ipairs({
	9113800103, 9113800168, 9113800170, 9113800257, 9113800310, 9113800372, 9113800368,
	9113800380, 9113800479, 9113800491, 9113800677, 9113800686, 9113800857, 9113801019,
	9113801156, 9113801563,
}) do
	table.insert(CHOP, a(id))
end

return {
	-- background music: a calm playlist for the day and one for the evening
	Music = {
		day = { a(1846310773), a(1838606941), a(135844487150341) }, -- Minimal Koto, Asian Lounge, Under The Cherry Blossoms
		night = { a(1837510751), a(1841374108) }, -- Kyoto In The Snow, Cherry Blossom After Frost
	},
	-- loops mixed by the client from where you are and what happens around you
	Ambience = {
		street = { id = a(9112798079), volume = 0.32 }, -- Japanese traffic (louder outside)
		restaurant = { id = a(9112862817), volume = 0.3 }, -- restaurant chatter (grows with customers)
		boil = { id = a(9120500149), volume = 0.4, range = 26 }, -- bubbling broth pot
		cooker = { id = a(9120500158), volume = 0.18, range = 18 }, -- rice cooker simmering
		train = { id = a(9112798561), volume = 0.7, range = 320 }, -- train on the viaduct
	},
	Sfx = {
		-- interface
		click = { ids = { a(15675032796) }, volume = 0.45 },
		ui = { ids = { a(15675059323) }, volume = 0.45 },
		open = { ids = { a(15675037413) }, volume = 0.4 },
		error = { ids = { a(15675075163) }, volume = 0.45 },
		gift = { ids = { a(15675055424) }, volume = 0.6, len = 1.5 },
		level = { ids = { a(15675043410) }, volume = 0.7 },
		sparkle = { ids = { a(9126073001), a(9126073318) }, volume = 0.4 },
		combo = { ids = { a(9126076030) }, volume = 0.45, pitch = { 1, 1 } },
		-- money
		coin = { ids = { a(9113728042), a(9113728049) }, volume = 0.55 }, -- cash register
		tip = { ids = { a(9113848943), a(9113849011) }, volume = 0.45 }, -- coins on a wooden counter
		-- kitchen
		chop = { ids = CHOP, volume = 0.85, pitch = { 0.94, 1.1 }, len = 0.7, range = 50 }, -- knife on a cutting board
		pour = { ids = { a(9114612188), a(9114612102) }, volume = 0.75, len = 2.6, range = 50 }, -- broth poured into a bowl
		drain = { ids = { a(9120589761) }, volume = 0.75, range = 50 }, -- noodles shaken dry in the strainer
		boilstep = { ids = { a(9120500158) }, volume = 0.5, len = 1.6, start = 2, range = 40 }, -- noodles in boiling water
		sizzle = { ids = { a(9114542867) }, volume = 0.6, len = 2.4, start = 4, range = 50 }, -- frying
		spatula = { ids = { a(9125594711), a(9119452055), a(9119448503) }, volume = 0.45, range = 40 },
		utensil = { ids = { a(9120969635), a(9120969740) }, volume = 0.5, range = 40 }, -- wooden tools, rolling mat
		batter = { ids = { a(9117142914) }, volume = 0.5, len = 1.2, start = 1, range = 40 },
		plate = { ids = { a(9117654146), a(9117654198), a(9117654476), a(9117654482) }, volume = 0.5, range = 50 },
		rice = { ids = { a(9118770347) }, volume = 0.45, len = 2, range = 40 }, -- rice poured into the cooker
		wash = { ids = { a(9125619398) }, volume = 0.45, len = 3, range = 40 },
		beep = { ids = { a(9118776841) }, volume = 0.4, range = 40 }, -- appliance ready
		bell = { ids = { a(9114058445), a(9114058446) }, volume = 0.5, len = 2.5, range = 80 }, -- dish ready / day opens
		-- storage
		box = { ids = { a(9113720101) }, volume = 0.55, range = 40 }, -- cardboard box picked up / put down
		restock = { ids = { a(9113578540), a(9113579415) }, volume = 0.5, range = 40 }, -- box slid onto a shelf
		place = { ids = { a(9120880067), a(9120880071) }, volume = 0.5, range = 40 },
		pop = { ids = { a(9120880067), a(9120880071) }, volume = 0.28, pitch = { 1.15, 1.3 }, range = 30 }, -- a product lands on its spot
		truck = { ids = { a(9114075649) }, volume = 0.3, range = 200 },
		-- customers
		ticket = { ids = { a(15675037413) }, volume = 0.45, range = 50 }, -- order written on a ticket
		chime = { ids = { a(9120749869) }, volume = 0.4, len = 3, range = 70 }, -- furin wind chime at the door
		slurp = { ids = { a(9117020558), a(9117020823), a(9117021097) }, volume = 0.45, range = 35 },
	},
	-- which effects play during each cooking step (see Audio.step)
	Steps = {
		cut = { hit = "chop", hits = 5 },
		combine = { first = "utensil", last = "plate" },
		roll = { first = "utensil", last = "utensil" },
		mold = { first = "utensil", last = "plate" },
		boil = { first = "boilstep", last = "drain" },
		pour = { first = "pour" },
		top = { first = "utensil", last = "plate" },
		batter = { first = "batter" },
		fry = { first = "sizzle" },
		flip = { first = "spatula", last = "sizzle" },
	},
	Volume = { music = 0.35, sfx = 0.8, ambience = 0.7 },
}
