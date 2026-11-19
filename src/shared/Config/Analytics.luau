--!nonstrict
-- Roblox Analytics setup (Creator Dashboard → Analytics).
-- Funnel: the onboarding steps of a new player, in order; each one is logged once per player.
-- SourceFlush: seconds between two reports of the yen earned with sales and tips (summed up).
local Funnel = {
	"joined", -- the profile was created
	"first_order", -- the first customer ordered
	"first_cook", -- the first dish came out of a station
	"first_serve", -- the first customer was served
	"tutorial_done", -- the tutorial was finished (not skipped)
	"first_purchase", -- the first thing bought with yen
	"served_10", -- ten customers served
	"level_3",
	"level_5",
}
local FunnelIndex = {}
for i, name in ipairs(Funnel) do
	FunnelIndex[name] = i
end

return {
	Funnel = Funnel,
	FunnelIndex = FunnelIndex,
	SourceFlush = 120,
	-- what kind of transaction each yen source and sink is (Enum.AnalyticsEconomyTransactionType)
	SourceType = {
		sale = "Gameplay", tip = "Gameplay", helper = "Gameplay", level = "Gameplay", quest = "Gameplay",
		gift = "TimedReward", daily = "TimedReward", offline = "TimedReward", tutorial = "Onboarding",
		product = "IAP", refund = "Shop", code = "TimedReward",
	},
	SinkType = { build = "Shop", supplies = "Gameplay", salary = "Gameplay", other = "Shop" },
}
