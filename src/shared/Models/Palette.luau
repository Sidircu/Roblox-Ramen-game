--!nonstrict
-- Theme colors and materials used by every procedural model.
local Color = require(script.Parent.Parent.Util.Color)

local hex = {
	wood_light = "#C89F6E", wood = "#9A6B43", wood_dark = "#5B3A24", wood_black = "#2B1D14",
	hinoki = "#E3C79A", bamboo = "#B8A15A", bamboo_green = "#7A9A3A",
	lacquer = "#B3262E", lacquer_dark = "#7A1A1F", vermilion = "#D9442E",
	paper = "#F4EBDD", paper_warm = "#F7E3C0", ink = "#2B2320", charcoal = "#1E1E22",
	gold = "#D4A23C", brass = "#B8913A", matcha = "#7A9A4A", indigo = "#2E3A5C", navy = "#1E2A44",
	stone = "#8C8C88", stone_dark = "#5E5E5A", stone_light = "#B5B1A8", moss = "#5E7A3A",
	metal = "#A8ACB0", steel = "#6E7478", steel_dark = "#3E4246", copper = "#B87333",
	white = "#F7F5F0", porcelain = "#F2EFE8", rice = "#F7F4EC", nori = "#1E2B1E",
	leaf = "#4F7A3A", leaf_dark = "#2F5A2A", leaf_light = "#7FA34A", maple = "#C8361E",
	sakura = "#F7B7C9", sakura_dark = "#E88AA8", water = "#4F98B8", water_dark = "#2E6A88",
	sand = "#E3D6B8", tile = "#3A3D44", road = "#2A2A2E", road_line = "#E8E4D8", concrete = "#9A9A96",
	sidewalk = "#B5B0A6", brick = "#7A4A3A", glass = "#A8D0E0", cardboard = "#B98B57",
	neon_red = "#FF3B4A", neon_blue = "#3BC8FF", neon_pink = "#FF5AC8", neon_yellow = "#FFD23B",
	lamp = "#FFD9A0", lamp_warm = "#FFB866", koi_orange = "#F27A2E", black = "#141414",
	cream = "#EFE3CC", red = "#C0261E",
}

local Palette = {}
for name, value in pairs(hex) do
	Palette[name] = Color.hex(value)
end

Palette.M = {
	wood = Enum.Material.Wood,
	planks = Enum.Material.WoodPlanks,
	fabric = Enum.Material.Fabric,
	smooth = Enum.Material.SmoothPlastic,
	plastic = Enum.Material.Plastic,
	metal = Enum.Material.Metal,
	slate = Enum.Material.Slate,
	concrete = Enum.Material.Concrete,
	brick = Enum.Material.Brick,
	neon = Enum.Material.Neon,
	glass = Enum.Material.Glass,
	marble = Enum.Material.Marble,
	granite = Enum.Material.Granite,
	pebble = Enum.Material.Pebble,
	sand = Enum.Material.Sand,
	grass = Enum.Material.Grass,
	leafy = Enum.Material.LeafyGrass,
	cobble = Enum.Material.Cobblestone,
	foil = Enum.Material.Foil,
	plaster = Enum.Material.Plaster,
	cardboard = Enum.Material.Cardboard,
	tiles = Enum.Material.CeramicTiles,
	roof = Enum.Material.ClayRoofTiles,
	asphalt = Enum.Material.Asphalt,
	pavement = Enum.Material.Pavement,
	rock = Enum.Material.Rock,
	snow = Enum.Material.Snow,
	leather = Enum.Material.Leather,
	carpet = Enum.Material.Carpet,
}

function Palette.material(name)
	local ok, m = pcall(function()
		return Enum.Material[name]
	end)
	if ok and m then
		return m
	end
	return Enum.Material.SmoothPlastic
end

Palette.hex = Color.hex

return Palette
