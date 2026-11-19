--!nonstrict
-- General tuning constants. Balance tables live in the sibling Config modules.
return {
	PlaceName = "Sakura Ramen & Sushi Tycoon",

	-- Interaction
	InteractRange = 11, -- studs between character and object
	IngredientHandCapacity = 6,

	-- Building
	FloorHeight = 15, -- floor-to-floor distance
	WallHeight = 14,
	CellSize = 2, -- wall generation grid
	PathCell = 1, -- walkability grid for placement validation
	PathClearance = 0.9, -- obstacles are inflated by this (corridors >= 2 studs)
	GridSizes = { 1, 5, 10 },
	RotationSteps = { 90, 45, 15 },
	SellRefund = 0.75,
	FullRefundSeconds = 30,

	-- Time of day: the restaurant is always open and the clock never stops. A game hour lasts
	-- SecondsPerHour real seconds (NightSecondsPerHour between NightFrom and NightTo, so the quiet
	-- night passes quickly); a full day is about 14 minutes. Every day at DayStartHour the day's
	-- accounts are closed (salaries, stats, daily quests, a short summary).
	Day = {
		StartClock = 10,
		DayStartHour = 6,
		SecondsPerHour = 45,
		NightSecondsPerHour = 15,
		NightFrom = 23,
		NightTo = 6,
		NightFactor = 1.6, -- customers come this much less often at night
		Peaks = { { 12, 14 }, { 19, 21 } },
		PeakFactor = 0.6,
		EarlyPeakFactor = 0.85, -- peaks are lighter for the first EarlyDays days
		EarlyDays = 2,
	},

	-- Customers
	Customers = {
		-- easy mode: every customer type waits this many times its base patience, and the timer
		-- starts again from full when you take the order (full time to cook it)
		PatienceMult = 1.8,
		MaxNpcs = 60, -- customers and staff of the whole street
		MaxPerRestaurant = 14, -- customers of one restaurant at the same time
		BaseInterval = 18,
		MinInterval = 2.5,
		MenuReadTime = { 1.5, 3 },
		FirstCustomerDelay = 2, -- the first customer walks in this soon after the restaurant opens
		StreetSpawn = { 70, 95 }, -- customers appear this far along the street (studs from the door)
		EatTime = { sushi = 12, ramen = 18, side = 8, drink = 6, dessert = 8 },
		ExtraOrderChance = 0.4,
		SecondOrderChance = 0.15,
		QueuePerBench = 3,
		BaseQueue = 2,
		StuckTeleportSeconds = 8,
		SeatHeightOffset = 1.05,
		WalkSpeed = 11,
		DefaultRating = 3.0,
		RecentReviews = 50,
	},

	-- Cooking step durations (seconds) and which upgrade speeds them up
	Steps = {
		combine = { time = 0.9, tool = "up_knife" },
		cut = { time = 1.0, tool = "up_knife" },
		roll = { time = 1.1, tool = "up_mat" },
		mold = { time = 1.0, tool = "up_mat" },
		boil = { time = 1.8, tool = "up_strainer" },
		pour = { time = 0.9, tool = "up_strainer" },
		top = { time = 0.9, tool = "up_strainer" },
		batter = { time = 0.8, tool = "up_strainer" },
		fry = { time = 1.4, tool = "up_strainer" },
		flip = { time = 1.1, tool = "up_strainer" },
	},

	-- Supply
	DeliveryOverflowBoxes = 30,
	TruckDrive = 4.5, -- seconds the delivery truck drives in (about 6 s from order to boxes)
	-- optional noodle timing: stop the needle inside the green part of the bar while the noodles
	-- boil (From..To of the step) for a perfect bowl and a bigger tip
	NoodleTiming = { From = 0.5, To = 0.8, TipBonus = 0.2 },
	DishInset = 0.85, -- studs from the edge of a counter / table to where a customer's dish goes
	TipJarFull = 600, -- yen that fill the tip jar to the top (only the look: it never overflows)
	RescueCooldown = 600, -- free kit when broke and out of ingredients, at most every 10 minutes
	BigBoxMultiplier = 3,
	-- A box fills at most this many shelf slots: a base slot holds 1/BoxShelfSlots of a box
	-- (bigger shelves and the shelf upgrade make slots roomier); big boxes fill this many per use
	BoxShelfSlots = 2,
	ShelfItemScale = 1.3, -- largest size of the products shown in the shelf grids
	StockFlyStep = 0.06, -- seconds between two products flying from the box to the shelf

	-- Sink: hold to wash one plate every Time seconds; at most MaxPile dirty plates are drawn in the
	-- soaking basin; staff wash up to StaffBatch plates per trip
	Washing = { Time = 1.6, MaxPile = 12, StaffBatch = 8 },

	-- Dishes (plates and bowls)
	StartDishes = 20,
	DishSetSize = 6,
	DishSetPrice = 300,

	-- Freshness bonus (neta case fish or professional fridge nearby)
	FreshTipBonus = 0.10,
	FreshReviewBonus = 0.3,

	-- Economy
	StartYen = 500,
	HelperRewardShare = 0.2,

	-- Player
	WalkSpeed = 16,

	-- Saving
	AutosaveSeconds = 120,
	SessionLockSeconds = 600, -- a lock older than this belongs to a crashed server
	LockWaitSeconds = 40, -- a joining server waits this long for the old one to release a profile

	DataStoreName = "Profiles_v1",

	-- Staff
	StaffWalkSpeed = 13,
	StaffSpeedPerLevel = 0.15,
	ManagerSpeedBonus = 0.10,
	MaxStaff = 12,
	AutoRestockCheck = 30,
}
