--!nonstrict
-- The street holds Count restaurants side by side, one per player (Game Settings → Max Players
-- should be Count). Every restaurant uses the same local layout (Config/Expansions, StarterLayout)
-- moved along X to its plot origin. A plot owns the strip of street origin ± HalfWidth.
local Count = 4
local Spacing = 240
local origins = {}
for i = 1, Count do
	origins[i] = (i - (Count + 1) / 2) * Spacing
end

return {
	Count = Count,
	Spacing = Spacing,
	OriginsX = origins,
	HalfWidth = Spacing / 2,
	-- the street runs this far each way from the middle (past the outer restaurants)
	StreetReach = origins[Count] + Spacing / 2 + 140,
	-- who may help in a restaurant: "friends" (default: Roblox friends and invited players) or
	-- "everyone"; the owner changes it in the Invite app
	DefaultCoop = "friends",
	-- spawn point in front of each restaurant (local coordinates)
	Spawn = { x = 0, y = 3, z = -8 },
}
