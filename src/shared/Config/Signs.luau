--!nonstrict
-- The restaurant's sign over the door (and the giant sign on the roof, when bought): the name,
-- the look and the colours chosen by the owner in Screens/Sign. The name is filtered by Roblox
-- (TextService, server Signs) before anybody sees it; with no name the sign says らーめん ・ 寿司.
local Colors = {
	{ id = "hinoki", hex = "#E3C79A" },
	{ id = "wood", hex = "#8A5A36" },
	{ id = "ink", hex = "#2B2320" },
	{ id = "black", hex = "#151312" },
	{ id = "red", hex = "#B3262E" },
	{ id = "orange", hex = "#E07A2E" },
	{ id = "gold", hex = "#D4A23C" },
	{ id = "cream", hex = "#F4EBDD" },
	{ id = "white", hex = "#FFFFFF" },
	{ id = "sakura", hex = "#F2A7B5" },
	{ id = "matcha", hex = "#5E8F3A" },
	{ id = "indigo", hex = "#2E3A5C" },
}

-- wood: a carved board in a dark frame; lacquer: a glossy board with a gold frame; noren: three
-- cloth panels hanging from a rod; neon: glowing letters and a neon tube round a dark board;
-- lanterns: a board between two paper lanterns
local Styles = {
	{ id = "wood", icon = "🪵" },
	{ id = "lacquer", icon = "🏯" },
	{ id = "noren", icon = "🎌" },
	{ id = "neon", icon = "💡" },
	{ id = "lanterns", icon = "🏮" },
}

local colorById, styleById = {}, {}
for i, c in ipairs(Colors) do
	c.order = i
	colorById[c.id] = c
end
for i, s in ipairs(Styles) do
	s.order = i
	styleById[s.id] = s
end

return {
	Colors = Colors,
	ColorById = colorById,
	Styles = Styles,
	StyleById = styleById,
	-- letters in a name (spaces count)
	MinName = 2,
	MaxName = 24,
	-- what every restaurant starts with: the classic board with dark letters
	Default = { name = "", shown = "", style = "wood", board = "hinoki", text = "ink" },
	-- the text of a sign without a name, and the small line under a name
	DefaultText = "らーめん ・ 寿司",
	Subtitle = "らーめん ・ 寿司",
	-- the facade sign (restaurant-local, over the door) and how often a player may change it
	Facade = { x = 0, y = 11.6, z = -0.9, width = 18, height = 2.6 },
	MinSecondsBetweenChanges = 3,
}
