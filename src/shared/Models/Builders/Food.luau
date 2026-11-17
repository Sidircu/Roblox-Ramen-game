--!nonstrict
-- Food visuals: dishes (per recipe), ingredients, supplier boxes, dirty dishes, cooking tools.
-- Everything is built from primitives with real-world proportions and colours: curved bowls
-- with a glazed band, glossy broth with fat drops, wavy noodles, chashu with a browned edge and a
-- fat ring, jammy eggs, fish with fat lines, translucent roe, crispy batter and so on.
-- Dishes: bottom at y = 0, Root 1.6 x 1 x 1.2 (callers pivot the Root 0.5 above the surface).
local Kit = require(script.Parent.Parent.Kit)
local P = require(script.Parent.Parent.Palette)
local Color = require(script.Parent.Parent.Parent.Util.Color)
local Recipes = require(script.Parent.Parent.Parent.Config.Recipes)
local Ingredients = require(script.Parent.Parent.Parent.Config.Ingredients)
local M = P.M

local function nc(extra)
	local p = { collide = false, shadow = false }
	if extra then
		for k, v in pairs(extra) do
			p[k] = v
		end
	end
	return p
end

local function c(hex)
	return Color.hex(hex)
end

-- Food palette (real colours, not game-y primaries)
local F = {
	rice = c("#F7F4EC"), riceShade = c("#E9E3D3"),
	nori = c("#1C2A1E"), noriLight = c("#2C3D2E"),
	salmon = c("#F27A4A"), salmonFat = c("#FBD3BE"),
	tuna = c("#A8162A"), tunaLight = c("#C2303F"),
	otoro = c("#F0A39A"), otoroFat = c("#FBE4DE"),
	hamachi = c("#F2D9C8"), blood = c("#C8505A"),
	shrimp = c("#F6EDE6"), shrimpRed = c("#EE5A36"),
	eel = c("#5A3418"), sauce = c("#3B2414"),
	ikura = c("#F2541B"), tobiko = c("#F48A1E"),
	wasabi = c("#8DB04A"), gari = c("#F5C6C0"), shiso = c("#3F7A2A"), baran = c("#3E8A34"),
	cucumber = c("#2F6B2A"), cucumberIn = c("#CFE6A8"), avocado = c("#B7C95A"), avocadoSkin = c("#6E9A3A"),
	crab = c("#E8544A"), daikon = c("#F4F4EE"), lemon = c("#F2D84A"),
	noodle = c("#F2D27A"), noodleThick = c("#E8C26A"), soba = c("#7E9A4E"),
	chashuEdge = c("#8A4A2A"), chashuMeat = c("#D9A089"), chashuFat = c("#F3DCCB"),
	eggWhite = c("#F6EEDF"), eggMarinated = c("#D8A86A"), yolk = c("#F09A2A"), yolkCore = c("#E57A12"),
	naruto = c("#FFFFFF"), narutoPink = c("#E8548A"),
	menma = c("#C9A25A"), scallion = c("#5FA63A"), scallionLight = c("#B5D98A"),
	corn = c("#F4CF3B"), butter = c("#F7E39A"), kikurage = c("#2E2420"),
	pork = c("#8A4A3A"), chili = c("#C0261E"), sesame = c("#EDE3C8"), blackSesame = c("#2A2420"),
	tofu = c("#F6F2E6"), wakame = c("#2E4A22"), batter = c("#E9B85A"), golden = c("#D9962E"),
	karaage = c("#B8692A"), takoyaki = c("#C08848"), okoSauce = c("#3E1F12"), mayo = c("#F6F0DC"),
	aonori = c("#5E8A2A"), bonito = c("#D9B48A"), beniShoga = c("#D8343E"), cabbage = c("#D8E8B0"),
	lamb = c("#9A5A4A"), pumpkin = c("#E8902A"), goya = c("#4E8A2E"), scrambled = c("#F3D25A"),
	matcha = c("#7A9A3A"), matchaFoam = c("#A9C25A"), tea = c("#B8C86A"),
	porcelain = c("#F7F5F0"), indigo = c("#2E5A8C"), lacquerRed = c("#B3262E"), lacquerBlack = c("#1A1414"),
}

local BROTH = {
	broth_shoyu = "#7A4A22",
	broth_shio = "#E6C980",
	broth_miso = "#C58A3E",
	broth_tonkotsu = "#F1E4C8",
}

-- Bowl look per recipe (outer, inner, band)
local BOWLS = {
	shoyu_ramen = { P.porcelain, F.porcelain, F.lacquerRed },
	shio_ramen = { P.porcelain, F.porcelain, F.indigo },
	butter_corn_ramen = { P.porcelain, F.porcelain, F.indigo },
	miso_ramen = { c("#5A2A1A"), F.lacquerRed, P.gold },
	tantanmen = { F.lacquerBlack, F.lacquerRed, F.lacquerRed },
	tonkotsu_ramen = { F.lacquerBlack, F.lacquerRed, P.gold },
	hakata_ramen = { F.lacquerBlack, F.lacquerRed, F.lacquerRed },
	mayu_ramen = { F.lacquerBlack, F.lacquerBlack, P.gold },
	okinawa_soba = { c("#E8EEF2"), F.porcelain, c("#3A6A9A") },
}

local function ingColor(id)
	local ing = Ingredients.byId[id]
	return ing and Color.hex(ing.color) or P.white
end

local function has(recipe, id)
	for _, g in ipairs(recipe.ing) do
		if g == id then
			return true
		end
	end
	return false
end

-- Deterministic pseudo random (same dish always looks the same)
local function seq(seed)
	local s = (seed or 1) % 2147483646 + 1
	return function()
		s = (s * 16807) % 2147483647
		return s / 2147483647
	end
end

local function lerp(a, b, t)
	return a:Lerp(b, t)
end

-- Ellipsoid (sphere mesh) placed with a full CFrame
local function blobAt(m, sx, sy, sz, cf, color, mat, props)
	local p = Kit.blob(m, sx, sy, sz, 0, 0, 0, color, mat, props)
	p.CFrame = cf
	return p
end

-- Cylinder of diameter d and height h whose axis is the local Y of cf
local function cylAt(m, d, h, cf, color, mat, props)
	local pr = props or nc()
	pr.shape = Enum.PartType.Cylinder
	return Kit.part(m, Vector3.new(h, d, d), cf * CFrame.Angles(0, 0, math.rad(90)), color, mat, pr)
end

---------------------------------------------------------------------------------------------------
-- Tableware
---------------------------------------------------------------------------------------------------

-- Ramen bowl (donburi): curved wall from stacked rings, foot ring, glazed band and rim. Returns the
-- liquid level y. The inner glaze shows as a ring around the broth.
local function donburi(m, d, h, outer, inner, band)
	local foot = d * 0.42
	Kit.cyl(m, foot, 0.08, 0, 0.04, 0, outer, M.smooth, nc())
	local n = 6
	for i = 1, n do
		local t = i / n
		local dd = foot + (d - foot) * math.sin(t * math.pi / 2)
		local hh = (h - 0.08) / n + 0.012
		local y0 = 0.08 + (h - 0.08) * (i - 1) / n
		Kit.cyl(m, dd, hh, 0, y0 + hh / 2, 0, outer, M.smooth, nc({ reflectance = 0.06 }))
	end
	if band then
		Kit.cyl(m, d + 0.012, 0.08, 0, h - 0.11, 0, band, M.smooth, nc({ reflectance = 0.06 }))
		-- meander notches (raimon pattern) cut into the band
		for k = 0, 15 do
			local a = k * math.pi / 8
			local r = d / 2 + 0.01
			Kit.box(m, 0.045, 0.045, 0.02, math.cos(a) * r, h - 0.11 + ((k % 2 == 0) and 0.012 or -0.012), math.sin(a) * r, outer, M.smooth, nc({ rot = CFrame.Angles(0, math.pi / 2 - a, 0) }))
		end
	end
	Kit.cyl(m, d + 0.02, 0.025, 0, h - 0.012, 0, band or outer, M.smooth, nc())
	Kit.cyl(m, d - 0.02, 0.02, 0, h, 0, inner, M.smooth, nc())
	return h + 0.012
end

-- Glossy liquid with a few fat drops
local function liquid(m, d, y, color, drops, seed)
	Kit.cyl(m, d, 0.02, 0, y, 0, color, M.smooth, nc({ reflectance = 0.14 }))
	local rnd = seq(seed or 7)
	for _ = 1, drops or 0 do
		local a, r = rnd() * math.pi * 2, rnd() * d * 0.4
		local s = 0.04 + rnd() * 0.06
		Kit.cyl(m, s, 0.01, math.cos(a) * r, y + 0.012, math.sin(a) * r, lerp(color, P.white, 0.35), M.smooth, nc({ reflectance = 0.3, transparency = 0.2 }))
	end
end

-- White ceramic plate with a coloured rim line
local function plateRound(m, d, color, rim)
	Kit.cyl(m, d * 0.6, 0.05, 0, 0.025, 0, color or F.porcelain, M.smooth, nc())
	Kit.cyl(m, d, 0.05, 0, 0.07, 0, color or F.porcelain, M.smooth, nc({ reflectance = 0.06 }))
	Kit.cyl(m, d - 0.04, 0.052, 0, 0.072, 0, rim or lerp(color or F.porcelain, P.black, 0.12), M.smooth, nc())
	Kit.cyl(m, d - 0.12, 0.055, 0, 0.073, 0, color or F.porcelain, M.smooth, nc({ reflectance = 0.06 }))
	return 0.1
end

-- Rectangular ceramic plate with raised edges
local function plateRect(m, w, d, color, rim)
	Kit.box(m, w * 0.85, 0.04, d * 0.8, 0, 0.02, 0, color, M.smooth, nc())
	Kit.box(m, w, 0.05, d, 0, 0.065, 0, color, M.smooth, nc({ reflectance = 0.06 }))
	for _, s in ipairs({ -1, 1 }) do
		Kit.box(m, w, 0.05, 0.05, 0, 0.1, s * (d / 2 - 0.025), rim or color, M.smooth, nc())
		Kit.box(m, 0.05, 0.05, d, s * (w / 2 - 0.025), 0.1, 0, rim or color, M.smooth, nc())
	end
	return 0.09
end

-- Wooden geta board for sushi
local function geta(m, w, d)
	Kit.box(m, w, 0.08, d, 0, 0.14, 0, P.hinoki, M.wood, nc())
	Kit.box(m, w - 0.02, 0.01, d - 0.02, 0, 0.185, 0, lerp(P.hinoki, P.white, 0.25), M.wood, nc())
	for _, x in ipairs({ -w / 2 + 0.18, w / 2 - 0.18 }) do
		Kit.box(m, 0.1, 0.1, d - 0.04, x, 0.05, 0, P.wood_light, M.wood, nc())
	end
	return 0.19
end

-- Chopsticks resting on a little ceramic rest (hashioki)
local function chopsticks(m, x, z, yaw, y0)
	local base = CFrame.new(x, y0 or 0, z) * CFrame.Angles(0, math.rad(yaw or 0), 0)
	Kit.part(m, Vector3.new(0.18, 0.06, 0.1), base * CFrame.new(-0.45, 0.03, 0), F.indigo, M.smooth, nc())
	for k = 0, 1 do
		Kit.part(m, Vector3.new(1.3, 0.035, 0.035), base * CFrame.new(0.15, 0.075, -0.03 + k * 0.06) * CFrame.Angles(0, 0, math.rad(-2)), lerp(P.wood_light, P.lacquer_dark, 0.15), M.wood, nc())
	end
end

-- Ceramic soup spoon (renge)
local function renge(m, x, y, z, yaw)
	local base = CFrame.new(x, y, z) * CFrame.Angles(0, math.rad(yaw or 0), 0)
	blobAt(m, 0.34, 0.1, 0.24, base, F.porcelain, M.smooth, nc({ reflectance = 0.08 }))
	blobAt(m, 0.28, 0.04, 0.19, base * CFrame.new(0, 0.035, 0), lerp(F.porcelain, F.indigo, 0.12), M.smooth, nc())
	Kit.part(m, Vector3.new(0.32, 0.04, 0.08), base * CFrame.new(0.28, 0.08, 0) * CFrame.Angles(0, 0, math.rad(25)), F.porcelain, M.smooth, nc())
end

-- Small soy sauce dish
local function soyDish(m, x, z, withChili)
	Kit.cyl(m, 0.36, 0.06, x, 0.03, z, F.porcelain, M.smooth, nc())
	Kit.cyl(m, 0.28, 0.01, x, 0.065, z, F.sauce, M.smooth, nc({ reflectance = 0.2 }))
	if withChili then
		for k = 0, 3 do
			Kit.cyl(m, 0.05, 0.012, x - 0.06 + (k % 2) * 0.1, 0.072, z - 0.05 + math.floor(k / 2) * 0.08, F.chili, M.smooth, nc({ reflectance = 0.2 }))
		end
	end
end

local function wasabiAndGari(m, x, z, y)
	Kit.blob(m, 0.16, 0.12, 0.14, x, y + 0.05, z, F.wasabi, M.sand, nc())
	for k = 0, 3 do
		Kit.blob(m, 0.2, 0.025, 0.14, x + 0.18 + (k % 2) * 0.05, y + 0.02 + k * 0.018, z + 0.02 - (k % 2) * 0.04, F.gari, M.smooth, nc({ rot = CFrame.Angles(math.rad(k * 9), math.rad(k * 35), 0), transparency = 0.1 }))
	end
end

-- Serrated green baran leaf divider
local function baran(m, x, z, y, yaw)
	local base = CFrame.new(x, y, z) * CFrame.Angles(0, math.rad(yaw or 0), 0)
	Kit.part(m, Vector3.new(0.5, 0.12, 0.02), base * CFrame.new(0, 0.06, 0), F.baran, M.smooth, nc())
	for k = 0, 3 do
		Kit.part(m, Vector3.new(0.08, 0.08, 0.021), base * CFrame.new(-0.18 + k * 0.12, 0.12, 0) * CFrame.Angles(0, 0, math.rad(45)), F.baran, M.smooth, nc())
	end
end

---------------------------------------------------------------------------------------------------
-- Sushi pieces
---------------------------------------------------------------------------------------------------

-- Hand-pressed rice with a few loose grains
local function shari(m, base, len)
	len = len or 0.5
	blobAt(m, len, 0.24, 0.3, base, F.rice, M.sand, nc())
	for k = 0, 3 do
		local p = base * CFrame.new(-len / 2 + 0.1 + k * (len - 0.2) / 3, -0.02 + (k % 2) * 0.04, (k % 2 == 0) and 0.14 or -0.14)
		blobAt(m, 0.06, 0.035, 0.035, p * CFrame.Angles(0, k, 0), F.rice, M.smooth, nc())
	end
end

-- Fish slice draped over the rice. kind: salmon | tuna | otoro | hamachi | shrimp | eel
local function neta(m, base, kind, len)
	len = len or 0.62
	local col = ({ salmon = F.salmon, tuna = F.tuna, otoro = F.otoro, hamachi = F.hamachi, shrimp = F.shrimp, eel = F.eel })[kind] or F.salmon
	-- soft rounded slice: an ellipsoid for the draped edges and a flat top
	blobAt(m, len + 0.1, 0.13, 0.36, base * CFrame.new(0, -0.02, 0), col, M.smooth, nc({ reflectance = 0.1 }))
	Kit.part(m, Vector3.new(len - 0.06, 0.07, 0.28), base, col, M.smooth, nc({ reflectance = 0.1 }))
	if kind == "salmon" or kind == "otoro" then
		local fat = kind == "salmon" and F.salmonFat or F.otoroFat
		for k = 0, 3 do
			Kit.part(m, Vector3.new(0.025, 0.083, 0.36), base * CFrame.new(-len / 2 + 0.12 + k * (len - 0.2) / 3, 0.003, 0) * CFrame.Angles(0, math.rad(28), 0), fat, M.smooth, nc())
		end
	elseif kind == "tuna" then
		for k = 0, 1 do
			Kit.part(m, Vector3.new(0.02, 0.082, 0.3), base * CFrame.new(-0.12 + k * 0.24, 0.002, 0) * CFrame.Angles(0, math.rad(25), 0), F.tunaLight, M.smooth, nc())
		end
	elseif kind == "hamachi" then
		Kit.part(m, Vector3.new(len - 0.06, 0.082, 0.05), base * CFrame.new(0, 0.002, 0.11), F.blood, M.smooth, nc())
	elseif kind == "shrimp" then
		for k = 0, 3 do
			Kit.part(m, Vector3.new(0.06, 0.084, 0.32), base * CFrame.new(-len / 2 + 0.12 + k * 0.13, 0.002, 0), F.shrimpRed, M.smooth, nc())
		end
		for _, s in ipairs({ -1, 1 }) do
			Kit.wedge(m, 0.03, 0.18, 0.14, base * CFrame.new(len / 2 + 0.12, -0.02, s * 0.06) * CFrame.Angles(0, math.rad(90), math.rad(-60)), F.shrimpRed, M.smooth, nc())
		end
	elseif kind == "eel" then
		for k = 0, 2 do
			Kit.part(m, Vector3.new(0.025, 0.083, 0.3), base * CFrame.new(-0.18 + k * 0.18, 0.003, 0), lerp(F.eel, P.black, 0.4), M.smooth, nc())
		end
		Kit.part(m, Vector3.new(len - 0.1, 0.02, 0.26), base * CFrame.new(0, 0.05, 0), F.sauce, M.smooth, nc({ reflectance = 0.3, transparency = 0.15 }))
	end
end

local function nigiri(m, x, z, y0, kind, yaw)
	local base = CFrame.new(x, y0 + 0.13, z) * CFrame.Angles(0, math.rad(yaw or 0), 0)
	shari(m, base, 0.46)
	neta(m, base * CFrame.new(0, 0.14, 0), kind, 0.48)
end

-- Thin roll (hosomaki) standing with the cut face up
local function hosomaki(m, x, z, y0, filling)
	Kit.cyl(m, 0.34, 0.3, x, y0 + 0.15, z, F.nori, M.smooth, nc({ reflectance = 0.05 }))
	Kit.cyl(m, 0.3, 0.305, x, y0 + 0.153, z, F.rice, M.sand, nc())
	if filling == "cucumber" then
		Kit.box(m, 0.11, 0.31, 0.11, x, y0 + 0.155, z, F.cucumber, M.smooth, nc())
		Kit.box(m, 0.07, 0.312, 0.07, x, y0 + 0.156, z, F.cucumberIn, M.smooth, nc())
	else
		Kit.box(m, 0.13, 0.31, 0.12, x, y0 + 0.155, z, F.tuna, M.smooth, nc({ reflectance = 0.1 }))
	end
end

-- Inside-out roll piece; style: "california" | "dragon"
local function uramaki(m, x, z, y0, style)
	Kit.cyl(m, 0.42, 0.28, x, y0 + 0.14, z, F.rice, M.sand, nc())
	Kit.cyl(m, 0.25, 0.285, x, y0 + 0.142, z, F.nori, M.smooth, nc())
	Kit.cyl(m, 0.21, 0.29, x, y0 + 0.145, z, F.rice, M.sand, nc())
	if style == "dragon" then
		Kit.box(m, 0.12, 0.292, 0.07, x - 0.02, y0 + 0.146, z, F.eel, M.smooth, nc())
		Kit.box(m, 0.06, 0.292, 0.07, x + 0.06, y0 + 0.146, z + 0.02, F.cucumber, M.smooth, nc())
	else
		Kit.box(m, 0.08, 0.292, 0.06, x - 0.04, y0 + 0.146, z, F.crab, M.smooth, nc())
		Kit.box(m, 0.07, 0.292, 0.06, x + 0.04, y0 + 0.146, z + 0.02, F.avocado, M.smooth, nc())
		Kit.box(m, 0.05, 0.292, 0.05, x + 0.02, y0 + 0.146, z - 0.05, F.cucumber, M.smooth, nc())
		-- tobiko rim and sesame on the outside
		Kit.cyl(m, 0.44, 0.2, x, y0 + 0.13, z, F.tobiko, M.sand, nc())
		for k = 0, 3 do
			local a = k * math.pi / 2 + 0.4
			Kit.box(m, 0.03, 0.02, 0.015, x + math.cos(a) * 0.2, y0 + 0.2, z + math.sin(a) * 0.2, F.sesame, M.smooth, nc())
		end
	end
end

---------------------------------------------------------------------------------------------------
-- Ramen toppings
---------------------------------------------------------------------------------------------------

local function noodleNest(m, y, r, color, thick, seed)
	local rnd = seq(seed or 3)
	Kit.blob(m, r * 1.6, 0.1, r * 1.3, -r * 0.1, y, r * 0.05, color, M.smooth, nc())
	for k = 0, 15 do
		local a = rnd() * math.pi * 2
		local cx, cz = (rnd() - 0.5) * r * 1.1, (rnd() - 0.5) * r * 0.9
		local cf = CFrame.new(cx, y + 0.04 + rnd() * 0.02, cz) * CFrame.Angles(0, a, math.rad((rnd() - 0.5) * 10))
		Kit.part(m, Vector3.new(0.3 + rnd() * 0.15, thick, thick), cf, lerp(color, P.white, rnd() * 0.15), M.smooth, nc({ shape = Enum.PartType.Cylinder, reflectance = 0.08 }))
	end
end

local function chashuSlice(m, x, y, z, d, yaw, tilt)
	local base = CFrame.new(x, y, z) * CFrame.Angles(math.rad(tilt or 8), math.rad(yaw or 0), 0)
	cylAt(m, d, 0.06, base, F.chashuEdge, M.smooth)
	cylAt(m, d - 0.05, 0.065, base * CFrame.new(0, 0.002, 0), F.chashuFat, M.smooth)
	cylAt(m, d - 0.16, 0.07, base * CFrame.new(0.02, 0.004, 0.01), F.chashuMeat, M.smooth, nc({ reflectance = 0.05 }))
	Kit.part(m, Vector3.new(d - 0.25, 0.072, 0.025), base * CFrame.new(0.02, 0.005, 0.03), F.chashuFat, M.smooth, nc())
end

-- Half marinated egg, cut side up
local function eggHalf(m, x, y, z, yaw)
	local base = CFrame.new(x, y, z) * CFrame.Angles(0, math.rad(yaw or 0), 0)
	blobAt(m, 0.36, 0.14, 0.26, base, F.eggMarinated, M.smooth, nc())
	blobAt(m, 0.32, 0.14, 0.22, base * CFrame.new(0, 0.012, 0), F.eggWhite, M.smooth, nc())
	blobAt(m, 0.18, 0.13, 0.15, base * CFrame.new(0.01, 0.022, 0), F.yolk, M.smooth, nc({ reflectance = 0.15 }))
	blobAt(m, 0.09, 0.12, 0.08, base * CFrame.new(0.01, 0.03, 0), F.yolkCore, M.smooth, nc({ reflectance = 0.2 }))
end

local function narutoSlice(m, x, y, z, yaw)
	Kit.cyl(m, 0.32, 0.05, x, y, z, F.naruto, M.smooth, nc())
	for k, col in ipairs({ F.narutoPink, F.naruto, F.narutoPink }) do
		Kit.cyl(m, 0.24 - (k - 1) * 0.07, 0.052 + k * 0.002, x + k * 0.01, y, z, col, M.smooth, nc())
	end
	for k = 0, 7 do
		local a = k * math.pi / 4 + math.rad(yaw or 0)
		Kit.box(m, 0.05, 0.05, 0.05, x + math.cos(a) * 0.16, y, z + math.sin(a) * 0.16, F.naruto, M.smooth, nc({ rot = CFrame.Angles(0, -a, 0) }))
	end
end

local function scallions(m, x, y, z, n, seed)
	local rnd = seq(seed or 11)
	for _ = 1, n do
		local px, pz = x + (rnd() - 0.5) * 0.3, z + (rnd() - 0.5) * 0.3
		local col = rnd() < 0.3 and F.scallionLight or F.scallion
		Kit.cyl(m, 0.07, 0.022, px, y + rnd() * 0.02, pz, col, M.smooth, nc({ rot = CFrame.Angles(math.rad(rnd() * 30), 0, 0) }))
	end
end

local function menma(m, x, y, z)
	for k = 0, 3 do
		Kit.box(m, 0.3, 0.04, 0.06, x, y + k * 0.015, z + k * 0.065, lerp(F.menma, P.wood, (k % 2) * 0.2), M.smooth, nc({ rot = CFrame.Angles(0, math.rad(10 - k * 6), math.rad(4)) }))
	end
end

local function noriSheet(m, x, y, z, yaw)
	local base = CFrame.new(x, y, z) * CFrame.Angles(0, math.rad(yaw or 0), 0) * CFrame.Angles(math.rad(-22), 0, 0)
	Kit.part(m, Vector3.new(0.36, 0.44, 0.02), base, F.nori, M.smooth, nc({ reflectance = 0.04 }))
	for k = 0, 2 do
		Kit.part(m, Vector3.new(0.36, 0.012, 0.022), base * CFrame.new(0, -0.13 + k * 0.13, 0), F.noriLight, M.smooth, nc())
	end
end

local function ramenToppings(m, recipe, y)
	local slots = {
		{ 0.3, 0.12 }, { -0.28, 0.18 }, { 0.05, -0.32 }, { -0.3, -0.18 }, { 0.32, -0.2 },
	}
	local i = 0
	local function nextSlot()
		i += 1
		local s = slots[(i - 1) % #slots + 1]
		return s[1], s[2]
	end
	for _, id in ipairs(recipe.ing) do
		if id == "chashu" then
			local x, z = nextSlot()
			chashuSlice(m, x, y + 0.04, z, 0.52, 20, 10)
			chashuSlice(m, x - 0.14, y + 0.08, z + 0.07, 0.5, -15, 14)
		elseif id == "egg" then
			local x, z = nextSlot()
			eggHalf(m, x, y + 0.05, z, 30)
			eggHalf(m, x + 0.08, y + 0.06, z - 0.16, -20)
		elseif id == "naruto" then
			local x, z = nextSlot()
			narutoSlice(m, x, y + 0.03, z, 0)
		elseif id == "corn" then
			local x, z = nextSlot()
			for k = 0, 11 do
				Kit.ball(m, 0.07, x + (k % 4) * 0.065 - 0.1, y + 0.035 + (k % 3) * 0.012, z + math.floor(k / 4) * 0.065 - 0.06, lerp(F.corn, P.white, (k % 3) * 0.08), M.smooth, nc({ reflectance = 0.1 }))
			end
		elseif id == "butter" then
			local x, z = nextSlot()
			Kit.blob(m, 0.24, 0.06, 0.22, x, y + 0.02, z, lerp(F.butter, P.white, 0.2), M.smooth, nc({ reflectance = 0.25, transparency = 0.2 }))
			Kit.box(m, 0.15, 0.1, 0.15, x, y + 0.07, z, F.butter, M.smooth, nc({ rot = CFrame.Angles(0, math.rad(20), math.rad(6)), reflectance = 0.1 }))
		elseif id == "kikurage" then
			local x, z = nextSlot()
			for k = 0, 3 do
				Kit.blob(m, 0.2, 0.04, 0.09, x + (k % 2) * 0.1, y + 0.03 + k * 0.008, z + math.floor(k / 2) * 0.1, F.kikurage, M.smooth, nc({ rot = CFrame.Angles(0, k * 0.9, math.rad(10)), reflectance = 0.15 }))
			end
		elseif id == "minced_pork" then
			local x, z = nextSlot()
			for k = 0, 9 do
				Kit.ball(m, 0.08 + (k % 3) * 0.02, x + (k % 4) * 0.07 - 0.1, y + 0.04, z + math.floor(k / 4) * 0.07 - 0.07, lerp(F.pork, P.black, (k % 2) * 0.2), M.sand, nc())
			end
		elseif id == "chili_oil" then
			for k = 0, 4 do
				Kit.cyl(m, 0.12 + k * 0.03, 0.012, -0.2 + k * 0.1, y + 0.012, 0.15 - k * 0.08, F.chili, M.smooth, nc({ reflectance = 0.35, transparency = 0.25 }))
			end
		elseif id == "black_garlic" then
			for k = 0, 3 do
				Kit.cyl(m, 0.18 + k * 0.04, 0.012, 0.15 - k * 0.12, y + 0.013, -0.05 + k * 0.06, P.black, M.smooth, nc({ reflectance = 0.35, transparency = 0.1 }))
			end
		elseif id == "matcha" then
			Kit.cyl(m, 0.3, 0.012, 0.1, y + 0.012, 0.1, F.matcha, M.sand, nc())
		end
	end
	if has(recipe, "scallion") or recipe.id == "tonkotsu_ramen" then
		scallions(m, -0.05, y + 0.04, 0.05, 12, #recipe.id)
	end
	if recipe.broth == "broth_shoyu" or recipe.id == "tonkotsu_ramen" or recipe.id == "hakata_ramen" then
		menma(m, 0.18, y + 0.03, 0.22)
	end
	if recipe.broth == "broth_tonkotsu" then
		for k = 0, 5 do
			Kit.box(m, 0.025, 0.012, 0.015, -0.2 + k * 0.08, y + 0.03, -0.05 + (k % 2) * 0.06, F.sesame, M.smooth, nc())
		end
	end
end

local function ramenBowl(m, recipe)
	local style = BOWLS[recipe.id] or BOWLS.shoyu_ramen
	local y = donburi(m, 1.4, 0.58, style[1], style[2], style[3])
	local broth = Color.hex(BROTH[recipe.broth] or "#C58A3E")
	liquid(m, 1.24, y, broth, recipe.broth == "broth_tonkotsu" and 3 or 7, #recipe.id)
	local thick = recipe.id == "okinawa_soba" and 0.075 or 0.055
	noodleNest(m, y + 0.01, 0.42, recipe.id == "okinawa_soba" and F.noodleThick or F.noodle, thick, #recipe.id)
	ramenToppings(m, recipe, y + 0.02)
	noriSheet(m, -0.28, y + 0.18, 0.42, 15)
	renge(m, 0.42, y + 0.06, 0.3, -40)
	chopsticks(m, 0.05, -0.92, 0)
	local steam = Kit.box(m, 0.6, 0.05, 0.6, 0, y + 0.25, 0, P.white, M.smooth, nc({ transparency = 1 }))
	Kit.particles(steam, "steam", { rate = 3 })
end

---------------------------------------------------------------------------------------------------
-- Dishes
---------------------------------------------------------------------------------------------------

local FISH_KIND = { salmon = "salmon", tuna = "tuna", otoro = "otoro", yellowtail = "hamachi", shrimp = "shrimp", eel = "eel" }

local function fishOf(recipe)
	for _, id in ipairs(recipe.ing) do
		if FISH_KIND[id] then
			return FISH_KIND[id]
		end
	end
	return "salmon"
end

local function dishNigiri(m, recipe)
	local y = geta(m, 1.5, 0.75)
	local kind = fishOf(recipe)
	nigiri(m, -0.42, 0, y, kind, 82)
	nigiri(m, -0.02, 0, y, kind, 98)
	baran(m, 0.26, -0.05, y, 90)
	wasabiAndGari(m, 0.42, 0.12, y)
end

local function dishMaki(m, recipe)
	local y = plateRect(m, 1.5, 0.85, F.porcelain, F.indigo)
	local filling = has(recipe, "cucumber") and "cucumber" or "tuna"
	for i = 0, 5 do
		hosomaki(m, -0.42 + (i % 3) * 0.38, -0.12 + math.floor(i / 3) * 0.32 + (i % 2) * 0.03, y, filling)
	end
	wasabiAndGari(m, 0.52, 0.28, y)
end

local function dishRoll(m, recipe)
	local y = plateRect(m, 1.7, 0.75, P.charcoal, P.black)
	local style = recipe.id == "dragon_roll" and "dragon" or "california"
	for i = 0, 5 do
		uramaki(m, -0.62 + i * 0.25, (i % 2) * 0.02, y, style)
	end
	if style == "dragon" then
		-- fanned avocado slices along the top and an eel-sauce zigzag
		for i = 0, 7 do
			Kit.blob(m, 0.24, 0.05, 0.4, -0.66 + i * 0.19, y + 0.31, 0, lerp(F.avocado, F.avocadoSkin, (i % 2) * 0.35), M.smooth, nc({ rot = CFrame.Angles(0, 0, math.rad(-12)), reflectance = 0.12 }))
		end
		for i = 0, 6 do
			Kit.box(m, 0.26, 0.02, 0.03, -0.6 + i * 0.2, y + 0.35, ((i % 2) * 2 - 1) * 0.08, F.sauce, M.smooth, nc({ rot = CFrame.Angles(0, math.rad(((i % 2) * 2 - 1) * 35), 0), reflectance = 0.3 }))
		end
	end
	wasabiAndGari(m, 0.62, 0.25, y)
end

local function dishTemaki(m, recipe)
	local y = plateRect(m, 1.3, 0.85, F.porcelain, P.wood_dark)
	-- cone of nori built from shrinking rings along a tilted axis
	local axis = CFrame.new(-0.1, y + 0.48, 0) * CFrame.Angles(0, 0, math.rad(-55))
	for i = 0, 5 do
		cylAt(m, 0.46 - i * 0.075, 0.12, axis * CFrame.new(0, -i * 0.1, 0), i % 2 == 0 and F.nori or F.noriLight, M.smooth)
	end
	local mouth = axis * CFrame.new(0, 0.1, 0)
	Kit.blob(m, 0.4, 0.18, 0.4, mouth.X, mouth.Y, mouth.Z, F.rice, M.sand, nc())
	for k = 0, 2 do
		local p = mouth * CFrame.new(-0.08 + k * 0.08, 0.1 + k * 0.03, 0.04 - k * 0.04)
		Kit.part(m, Vector3.new(0.08, 0.32, 0.14), p * CFrame.Angles(0, 0, math.rad(-20 + k * 15)), k == 1 and F.avocado or F.salmon, M.smooth, nc({ reflectance = 0.1 }))
	end
	local _ = recipe
	Kit.part(m, Vector3.new(0.04, 0.3, 0.04), mouth * CFrame.new(0.12, 0.15, 0.1), F.cucumber, M.smooth, nc())
	wasabiAndGari(m, 0.42, 0.25, y)
end

local function dishGunkan(m, recipe)
	local y = geta(m, 1.3, 0.75)
	for gi, x in ipairs({ -0.3, 0.3 }) do
		Kit.blob(m, 0.42, 0.18, 0.34, x, y + 0.1, 0, F.rice, M.sand, nc())
		Kit.cyl(m, 0.46, 0.26, x, y + 0.13, 0, F.nori, M.smooth, nc({ rot = CFrame.Angles(0, 0, 0) }))
		local rnd = seq(gi * 17)
		for _ = 1, 12 do
			local a, r = rnd() * math.pi * 2, rnd() * 0.15
			Kit.ball(m, 0.11, x + math.cos(a) * r, y + 0.3 + rnd() * 0.07, math.sin(a) * r, F.ikura, M.glass, nc({ transparency = 0.15, reflectance = 0.25 }))
		end
		Kit.cyl(m, 0.16, 0.02, x + 0.12, y + 0.34, 0.1, F.cucumber, M.smooth, nc({ rot = CFrame.Angles(math.rad(30), 0, 0) }))
	end
	local _ = recipe
	wasabiAndGari(m, 0.45, 0.26, y)
end

local function slices(m, x, z, y, col, fat, n, yaw)
	local base = CFrame.new(x, y, z) * CFrame.Angles(0, math.rad(yaw or 0), 0)
	for k = 0, n - 1 do
		local p = base * CFrame.new(0, 0.1, -0.14 + k * 0.12) * CFrame.Angles(math.rad(-35), 0, 0)
		Kit.part(m, Vector3.new(0.42, 0.24, 0.07), p, col, M.smooth, nc({ reflectance = 0.1 }))
		if fat then
			for f = 0, 1 do
				Kit.part(m, Vector3.new(0.02, 0.24, 0.072), p * CFrame.new(-0.08 + f * 0.16, 0, 0.001) * CFrame.Angles(0, 0, math.rad(25)), fat, M.smooth, nc())
			end
		end
	end
end

local function dishSashimi(m, recipe)
	local y = plateRound(m, 1.55, F.indigo, F.porcelain)
	-- shredded daikon mound and shiso leaves under the fish
	Kit.blob(m, 0.6, 0.22, 0.5, -0.05, y + 0.08, 0.28, F.daikon, M.fabric, nc())
	for k = 0, 5 do
		Kit.part(m, Vector3.new(0.3, 0.02, 0.02), CFrame.new(-0.05 + (k % 3) * 0.08 - 0.08, y + 0.18, 0.2 + math.floor(k / 3) * 0.12) * CFrame.Angles(0, k * 0.7, math.rad(15)), F.daikon, M.smooth, nc())
	end
	for k = 0, 1 do
		Kit.blob(m, 0.42, 0.03, 0.28, -0.35 + k * 0.6, y + 0.04, 0.05, F.shiso, M.smooth, nc({ rot = CFrame.Angles(0, math.rad(30 - k * 60), math.rad(8)) }))
	end
	slices(m, -0.42, -0.05, y, F.salmon, F.salmonFat, 3, 10)
	slices(m, 0.02, -0.15, y, F.tuna, nil, 3, 0)
	slices(m, 0.45, -0.05, y, F.hamachi, F.blood, 3, -10)
	Kit.blob(m, 0.14, 0.12, 0.12, 0.35, y + 0.06, 0.4, F.wasabi, M.sand, nc())
	Kit.cyl(m, 0.3, 0.04, 0.55, y + 0.05, 0.3, F.lemon, M.smooth, nc({ rot = CFrame.Angles(math.rad(70), 0, 0) }))
	local _ = recipe
end

local function dishPlatter(m, recipe)
	if recipe.id == "kaiseki" then
		-- black lacquer bento box with four compartments
		Kit.box(m, 1.6, 0.18, 1.15, 0, 0.09, 0, F.lacquerBlack, M.smooth, nc({ reflectance = 0.12 }))
		Kit.box(m, 1.5, 0.02, 1.05, 0, 0.17, 0, F.lacquerRed, M.smooth, nc())
		Kit.box(m, 0.04, 0.12, 1.05, 0, 0.22, 0, F.lacquerBlack, M.smooth, nc())
		Kit.box(m, 1.5, 0.12, 0.04, 0, 0.22, 0, F.lacquerBlack, M.smooth, nc())
		slices(m, -0.38, -0.25, 0.12, F.otoro, F.otoroFat, 3, 90)
		Kit.blob(m, 0.3, 0.1, 0.25, -0.38, 0.22, 0.27, F.daikon, M.fabric, nc())
		for k = 0, 8 do
			Kit.ball(m, 0.09, -0.42 + (k % 3) * 0.08, 0.3, 0.2 + math.floor(k / 3) * 0.08, F.ikura, M.glass, nc({ transparency = 0.15, reflectance = 0.25 }))
		end
		noodleNest(m, 0.22, 0.25, F.soba, 0.035, 5)
		for k, col in ipairs({ c("#F4B6C8"), F.porcelain, F.matcha }) do
			Kit.ball(m, 0.17, 0.22 + k * 0.13, 0.28, 0.28, col, M.smooth, nc())
		end
		Kit.cyl(m, 0.02, 0.6, 0.48, 0.28, 0.28, P.wood_light, M.wood, nc({ rot = CFrame.Angles(0, 0, math.rad(90)) }))
		return
	end
	local y = plateRect(m, 1.7, 1.05, F.lacquerBlack, F.lacquerRed)
	nigiri(m, -0.6, -0.2, y, "otoro", 85)
	nigiri(m, -0.25, -0.2, y, "hamachi", 95)
	nigiri(m, 0.1, -0.2, y, "shrimp", 88)
	nigiri(m, 0.45, -0.2, y, "salmon", 92)
	for i = 0, 2 do
		hosomaki(m, -0.5 + i * 0.36, 0.25, y, "tuna")
	end
	Kit.blob(m, 0.38, 0.16, 0.3, 0.55, y + 0.09, 0.25, F.rice, M.sand, nc())
	Kit.cyl(m, 0.42, 0.24, 0.55, y + 0.12, 0.25, F.nori, M.smooth, nc())
	for k = 0, 6 do
		Kit.ball(m, 0.1, 0.5 + (k % 3) * 0.06, y + 0.28, 0.2 + math.floor(k / 3) * 0.06, F.ikura, M.glass, nc({ transparency = 0.15, reflectance = 0.25 }))
	end
	baran(m, 0.18, 0.25, y, 90)
	wasabiAndGari(m, 0.62, -0.42, y)
end

local function dishTsukemen(m, recipe)
	-- thick glossy noodles folded on a plate, dipping broth in a small bowl
	local y = plateRound(m, 1.15, F.porcelain, F.indigo)
	for k = 0, 9 do
		Kit.part(m, Vector3.new(0.6, 0.07, 0.07), CFrame.new(-0.2, y + 0.05 + (k % 3) * 0.04, -0.25 + k * 0.05) * CFrame.Angles(0, math.rad(-8 + (k % 4) * 5), math.rad((k % 2) * 3)), lerp(F.noodleThick, P.white, (k % 3) * 0.06), M.smooth, nc({ shape = Enum.PartType.Cylinder, reflectance = 0.15 }))
	end
	noriSheet(m, -0.55, y + 0.15, 0.25, 30)
	Kit.cyl(m, 0.22, 0.04, -0.05, y + 0.16, -0.32, F.lemon, M.smooth, nc({ rot = CFrame.Angles(math.rad(60), 0, 0) }))
	-- dipping bowl
	local dip = Kit.model("Dip")
	dip.Parent = m
	local dy = donburi(dip, 0.6, 0.42, F.lacquerBlack, F.lacquerRed, P.gold)
	liquid(dip, 0.5, dy, c("#7A4A22"), 4, 9)
	chashuSlice(dip, 0.05, dy + 0.03, 0.02, 0.3, 10, 12)
	eggHalf(dip, -0.1, dy + 0.04, -0.08, 20)
	scallions(dip, 0.08, dy + 0.04, -0.12, 6, 4)
	for _, d in ipairs(dip:GetDescendants()) do
		if d:IsA("BasePart") then
			d.CFrame = CFrame.new(0.5, 0, 0.2) * d.CFrame
		end
	end
	local _ = recipe
end

local function dishZaruSoba(m, recipe)
	-- square lacquer tray, bamboo mat, green soba, nori strips, tsuyu cup
	Kit.box(m, 1.15, 0.1, 1.0, -0.15, 0.05, 0, F.lacquerBlack, M.smooth, nc({ reflectance = 0.1 }))
	for k = 0, 8 do
		Kit.cylH(m, 0.04, 0.95, -0.15, 0.12, -0.4 + k * 0.1, P.bamboo, M.wood, nc())
	end
	noodleNest(m, 0.18, 0.38, F.soba, 0.035, 21)
	for k = 0, 5 do
		Kit.box(m, 0.03, 0.01, 0.16, -0.25 + k * 0.05, 0.27, -0.05 + (k % 2) * 0.06, F.nori, M.smooth, nc({ rot = CFrame.Angles(0, math.rad(k * 25), 0) }))
	end
	Kit.cyl(m, 0.34, 0.3, 0.62, 0.15, -0.15, F.porcelain, M.smooth, nc())
	Kit.cyl(m, 0.36, 0.03, 0.62, 0.28, -0.15, F.indigo, M.smooth, nc())
	Kit.cyl(m, 0.28, 0.01, 0.62, 0.3, -0.15, c("#5A3418"), M.smooth, nc({ reflectance = 0.2 }))
	Kit.cyl(m, 0.3, 0.04, 0.62, 0.02, 0.32, F.porcelain, M.smooth, nc())
	scallions(m, 0.62, 0.06, 0.3, 6, 5)
	Kit.blob(m, 0.1, 0.08, 0.08, 0.7, 0.07, 0.36, F.wasabi, M.sand, nc())
	if has(recipe, "matcha") then
		Kit.cyl(m, 0.12, 0.01, 0.62, 0.31, -0.18, F.matcha, M.sand, nc())
	end
end

local function dishSoup(m, recipe)
	if recipe.id == "yudofu" then
		-- clay pot with kombu, clear dashi and tofu blocks
		local base = c("#A0785A")
		Kit.cyl(m, 0.9, 0.08, 0, 0.04, 0, lerp(base, P.black, 0.3), M.slate, nc())
		Kit.cyl(m, 1.15, 0.36, 0, 0.26, 0, base, M.slate, nc())
		Kit.cyl(m, 1.2, 0.05, 0, 0.45, 0, lerp(base, P.black, 0.45), M.slate, nc())
		for _, s in ipairs({ -1, 1 }) do
			Kit.box(m, 0.16, 0.08, 0.22, s * 0.64, 0.38, 0, base, M.slate, nc())
		end
		Kit.cyl(m, 1.04, 0.02, 0, 0.45, 0, c("#E6E2C8"), M.smooth, nc({ reflectance = 0.2, transparency = 0.15 }))
		Kit.box(m, 0.7, 0.01, 0.4, 0, 0.42, 0.1, F.wakame, M.smooth, nc())
		for k = 0, 3 do
			Kit.box(m, 0.26, 0.16, 0.26, -0.22 + (k % 2) * 0.36, 0.48, -0.15 + math.floor(k / 2) * 0.32, F.tofu, M.smooth, nc({ rot = CFrame.Angles(0, math.rad(k * 12), 0) }))
		end
		scallions(m, 0.05, 0.56, 0.02, 6, 2)
		chopsticks(m, 0, -0.75, 0)
		return
	end
	-- miso soup in a red and black lacquer owan
	Kit.cyl(m, 0.42, 0.1, 0, 0.05, 0, F.lacquerBlack, M.smooth, nc())
	for i = 1, 4 do
		local d = 0.55 + (0.95 - 0.55) * math.sin(i / 4 * math.pi / 2)
		Kit.cyl(m, d, 0.1, 0, 0.1 + (i - 0.5) * 0.09, 0, F.lacquerBlack, M.smooth, nc({ reflectance = 0.12 }))
	end
	Kit.cyl(m, 0.97, 0.03, 0, 0.47, 0, F.lacquerRed, M.smooth, nc())
	local broth = Color.hex(BROTH[recipe.broth or "broth_miso"] or "#C58A3E")
	liquid(m, 0.86, 0.48, broth, 0, 1)
	Kit.blob(m, 0.5, 0.012, 0.42, 0.05, 0.495, -0.02, lerp(broth, P.white, 0.2), M.smooth, nc({ transparency = 0.4 }))
	for k = 0, 5 do
		Kit.box(m, 0.09, 0.07, 0.09, -0.2 + (k % 3) * 0.17, 0.5, -0.12 + math.floor(k / 3) * 0.2, F.tofu, M.smooth, nc({ rot = CFrame.Angles(0, k, 0) }))
	end
	for k = 0, 2 do
		Kit.blob(m, 0.2, 0.02, 0.1, 0.18 - k * 0.15, 0.5, 0.18 - k * 0.12, F.wakame, M.smooth, nc({ rot = CFrame.Angles(0, k * 1.2, 0) }))
	end
	scallions(m, 0, 0.51, 0, 7, 3)
end

local function dishEdamame(m, recipe)
	local y = plateRound(m, 1.0, c("#E8E0D0"), c("#8A6A4A"))
	local rnd = seq(13)
	for k = 0, 9 do
		local a = rnd() * math.pi * 2
		local r = rnd() * 0.28
		local base = CFrame.new(math.cos(a) * r, y + 0.05 + (k % 3) * 0.04, math.sin(a) * r) * CFrame.Angles(math.rad((rnd() - 0.5) * 30), rnd() * 6, 0)
		local pod = lerp(c("#6FAE3E"), c("#9ACB5E"), rnd() * 0.5)
		blobAt(m, 0.4, 0.08, 0.13, base, pod, M.smooth, nc({ reflectance = 0.06 }))
		for b = -1, 1 do
			blobAt(m, 0.12, 0.1, 0.11, base * CFrame.new(b * 0.1, 0.012, 0), lerp(pod, P.white, 0.1), M.smooth, nc())
		end
	end
	for k = 0, 5 do
		Kit.box(m, 0.02, 0.02, 0.02, -0.2 + k * 0.08, y + 0.17, (k % 2) * 0.1, P.white, M.smooth, nc())
	end
	local _ = recipe
end

local function dishCup(m, recipe)
	Kit.cyl(m, 0.7, 0.04, 0, 0.02, 0, P.wood_dark, M.wood, nc())
	if recipe.id == "matcha_latte" then
		Kit.cyl(m, 0.5, 0.5, 0, 0.29, 0, F.porcelain, M.smooth, nc({ reflectance = 0.06 }))
		Kit.cylH(m, 0.24, 0.06, 0.3, 0.3, 0, F.porcelain, M.smooth, nc(), "z")
		Kit.cyl(m, 0.44, 0.01, 0, 0.54, 0, F.matchaFoam, M.smooth, nc())
		-- latte-art heart
		Kit.ball(m, 0.12, -0.04, 0.54, -0.03, F.porcelain, M.smooth, nc())
		Kit.ball(m, 0.12, 0.04, 0.54, -0.03, F.porcelain, M.smooth, nc())
		Kit.wedge(m, 0.16, 0.012, 0.12, CFrame.new(0, 0.546, 0.06) * CFrame.Angles(0, math.rad(180), 0), F.porcelain, M.smooth, nc())
	else
		-- tall stoneware yunomi with a dripping glaze
		Kit.cyl(m, 0.42, 0.6, 0, 0.34, 0, c("#7A6A52"), M.slate, nc())
		Kit.cyl(m, 0.43, 0.25, 0, 0.5, 0, c("#5E7A4A"), M.smooth, nc({ reflectance = 0.1 }))
		Kit.cyl(m, 0.36, 0.01, 0, 0.64, 0, F.tea, M.smooth, nc({ reflectance = 0.2 }))
	end
	local steam = Kit.box(m, 0.3, 0.05, 0.3, 0, 0.75, 0, P.white, M.smooth, nc({ transparency = 1 }))
	Kit.particles(steam, "steam", { rate = 2 })
end

-- Codd-neck ramune bottle: body, shoulder, pinched neck with the glass marble, blue cap, label
local function dishRamune(m, s)
	s = s or 1
	local glass = c("#8FD3EA")
	local function gl()
		return nc({ transparency = 0.35, reflectance = 0.2 })
	end
	Kit.cyl(m, 0.42 * s, 0.62 * s, 0, 0.32 * s, 0, glass, M.glass, gl())
	Kit.cyl(m, 0.36 * s, 0.1 * s, 0, 0.68 * s, 0, glass, M.glass, gl())
	Kit.cyl(m, 0.24 * s, 0.12 * s, 0, 0.78 * s, 0, glass, M.glass, gl())
	Kit.cyl(m, 0.18 * s, 0.08 * s, 0, 0.87 * s, 0, glass, M.glass, gl())
	Kit.cyl(m, 0.22 * s, 0.16 * s, 0, 0.99 * s, 0, glass, M.glass, gl())
	Kit.ball(m, 0.15 * s, 0, 0.84 * s, 0, c("#DDF2F8"), M.glass, nc({ transparency = 0.1, reflectance = 0.4 }))
	Kit.cyl(m, 0.24 * s, 0.07 * s, 0, 1.1 * s, 0, P.neon_blue, M.smooth, nc())
	Kit.cyl(m, 0.43 * s, 0.22 * s, 0, 0.32 * s, 0, P.white, M.smooth, nc({ transparency = 0.15 }))
	Kit.cyl(m, 0.432 * s, 0.05 * s, 0, 0.32 * s, 0, F.indigo, M.smooth, nc())
	Kit.cyl(m, 0.38 * s, 0.4 * s, 0, 0.26 * s, 0, c("#BFE8F4"), M.glass, nc({ transparency = 0.5 }))
end

local function gyozaPiece(m, base, crispy)
	Kit.part(m, Vector3.new(0.42, 0.06, 0.2), base * CFrame.new(0, 0.03, 0), crispy and F.golden or lerp(F.golden, F.batter, 0.5), M.sand, nc())
	blobAt(m, 0.44, 0.18, 0.22, base * CFrame.new(0, 0.11, 0), c("#F1E2C2"), M.smooth, nc({ reflectance = 0.04 }))
	for k = -1, 1 do
		Kit.part(m, Vector3.new(0.04, 0.06, 0.06), base * CFrame.new(k * 0.1, 0.19, 0) * CFrame.Angles(0, 0, math.rad(k * 15)), c("#E9D7B2"), M.smooth, nc())
	end
end

local function dishGyoza(m, recipe)
	local y = plateRect(m, 1.5, 0.8, F.porcelain, F.indigo)
	-- crispy lace wing (hane) joining the dumplings
	Kit.blob(m, 1.15, 0.02, 0.45, -0.1, y + 0.01, 0, F.golden, M.sand, nc({ transparency = 0.15 }))
	for k = 0, 5 do
		local base = CFrame.new(-0.5 + k * 0.17, y, (k % 2) * 0.02) * CFrame.Angles(0, math.rad(80), math.rad(-12))
		gyozaPiece(m, base, true)
	end
	soyDish(m, 0.55, 0.22, has(recipe, "chili_oil") or recipe.id == "yatai_gyoza")
	if has(recipe, "chili_oil") then
		for k = 0, 4 do
			Kit.cyl(m, 0.05, 0.012, -0.4 + k * 0.17, y + 0.23, 0, F.chili, M.smooth, nc({ reflectance = 0.3 }))
		end
	end
end

local function shrimpTempura(m, base)
	for k = 0, 4 do
		local s = 0.24 - k * 0.025
		blobAt(m, s, s * 0.9, s, base * CFrame.new(-0.3 + k * 0.13, 0.12 + math.sin(k * 0.8) * 0.02, 0) * CFrame.Angles(k, k * 2, 0), lerp(F.batter, F.golden, (k % 2) * 0.4), M.sand, nc())
	end
	for _, s in ipairs({ -1, 1 }) do
		Kit.wedge(m, 0.03, 0.2, 0.14, base * CFrame.new(0.38, 0.14, s * 0.05) * CFrame.Angles(0, math.rad(90), math.rad(-50)), F.shrimpRed, M.smooth, nc())
	end
end

local function cabbage(m, x, z, y)
	Kit.blob(m, 0.5, 0.16, 0.4, x, y + 0.06, z, F.cabbage, M.fabric, nc())
	for k = 0, 4 do
		Kit.part(m, Vector3.new(0.3, 0.015, 0.02), CFrame.new(x - 0.08 + k * 0.04, y + 0.14, z - 0.05 + (k % 2) * 0.08) * CFrame.Angles(0, k * 0.8, math.rad(10)), lerp(F.cabbage, P.white, 0.3), M.smooth, nc())
	end
end

local function lemonWedge(m, x, z, y)
	Kit.wedge(m, 0.08, 0.12, 0.26, CFrame.new(x, y + 0.06, z) * CFrame.Angles(0, math.rad(30), 0), F.lemon, M.smooth, nc())
	Kit.box(m, 0.02, 0.12, 0.26, x - 0.04, y + 0.06, z, c("#F7EDA0"), M.smooth, nc({ rot = CFrame.Angles(0, math.rad(30), 0) }))
end

local function dishFried(m, recipe)
	if recipe.id == "ebi_tempura" then
		-- bamboo basket with kaishi paper, three shrimp and a dipping cup
		Kit.cyl(m, 1.2, 0.1, -0.1, 0.05, 0, P.bamboo, M.wood, nc())
		Kit.cyl(m, 1.24, 0.06, -0.1, 0.12, 0, lerp(P.bamboo, P.wood, 0.3), M.wood, nc())
		Kit.box(m, 0.8, 0.01, 0.8, -0.1, 0.12, 0, P.paper, M.fabric, nc({ rot = CFrame.Angles(0, math.rad(45), 0) }))
		for k = 0, 2 do
			shrimpTempura(m, CFrame.new(-0.12, 0.12 + k * 0.05, -0.2 + k * 0.2) * CFrame.Angles(0, math.rad(15 - k * 15), 0))
		end
		Kit.cyl(m, 0.34, 0.2, 0.6, 0.1, 0.3, F.porcelain, M.smooth, nc())
		Kit.cyl(m, 0.28, 0.01, 0.6, 0.2, 0.3, c("#8A5A2E"), M.smooth, nc({ reflectance = 0.2 }))
		Kit.blob(m, 0.12, 0.06, 0.1, 0.6, 0.22, 0.3, F.daikon, M.sand, nc())
		lemonWedge(m, 0.3, -0.35, 0.12)
		return
	end
	local y = plateRound(m, 1.2, F.porcelain, c("#C8B898"))
	cabbage(m, 0.3, 0.15, y)
	if recipe.id == "kushikatsu" then
		for k = 0, 2 do
			local base = CFrame.new(-0.1, y + 0.08, -0.25 + k * 0.22) * CFrame.Angles(0, math.rad(-5 + k * 5), 0)
			Kit.part(m, Vector3.new(1.0, 0.025, 0.025), base, P.wood_light, M.wood, nc())
			for p = 0, 2 do
				Kit.part(m, Vector3.new(0.18, 0.14, 0.16), base * CFrame.new(-0.2 + p * 0.2, 0.02, 0) * CFrame.Angles(p, 0, 0.2 * p), lerp(F.batter, F.golden, 0.6), M.sand, nc())
			end
		end
		Kit.cyl(m, 0.3, 0.18, 0.45, y + 0.09, -0.3, P.charcoal, M.smooth, nc())
		Kit.cyl(m, 0.25, 0.01, 0.45, y + 0.18, -0.3, F.okoSauce, M.smooth, nc({ reflectance = 0.2 }))
		for k = 0, 3 do
			Kit.box(m, 0.02, 0.01, 0.02, -0.2 + k * 0.1, y + 0.18, -0.25 + (k % 2) * 0.2, F.sesame, M.smooth, nc())
		end
	else
		-- karaage: craggy golden nuggets
		local rnd = seq(29)
		for k = 0, 5 do
			local x, z = -0.35 + (k % 3) * 0.2, -0.2 + math.floor(k / 3) * 0.25
			for b = 0, 2 do
				local k2 = 0.8 + rnd() * 0.4
				blobAt(m, 0.17 * k2, 0.14 * k2, 0.16 * k2, CFrame.new(x + (rnd() - 0.5) * 0.08, y + 0.08 + b * 0.03, z + (rnd() - 0.5) * 0.08) * CFrame.Angles(rnd() * 3, rnd() * 3, rnd() * 3), lerp(F.karaage, F.golden, rnd() * 0.6), M.sand, nc())
			end
		end
		Kit.blob(m, 0.16, 0.08, 0.14, 0.3, y + 0.15, -0.25, F.mayo, M.smooth, nc({ reflectance = 0.1 }))
	end
	lemonWedge(m, 0.4, -0.05, y)
end

local function dishTakoyaki(m, recipe)
	-- wooden boat tray
	Kit.box(m, 1.3, 0.04, 0.72, 0, 0.02, 0, P.wood_light, M.wood, nc())
	for _, s in ipairs({ -1, 1 }) do
		Kit.box(m, 1.3, 0.12, 0.03, 0, 0.07, s * 0.36, P.wood_light, M.wood, nc())
		Kit.box(m, 0.03, 0.12, 0.72, s * 0.65, 0.07, 0, P.wood_light, M.wood, nc())
	end
	for k = 0, 5 do
		local x, z = -0.38 + (k % 3) * 0.38, -0.16 + math.floor(k / 3) * 0.32
		Kit.ball(m, 0.34, x, 0.2, z, F.takoyaki, M.sand, nc())
		Kit.blob(m, 0.3, 0.1, 0.3, x, 0.33, z, F.okoSauce, M.smooth, nc({ reflectance = 0.25 }))
		for l = 0, 1 do
			Kit.box(m, 0.3, 0.02, 0.025, x, 0.385, z - 0.05 + l * 0.1, F.mayo, M.smooth, nc({ rot = CFrame.Angles(0, math.rad(l == 0 and 25 or -25), 0) }))
		end
		Kit.box(m, 0.03, 0.02, 0.03, x - 0.06, 0.39, z + 0.04, F.aonori, M.smooth, nc())
		Kit.box(m, 0.03, 0.02, 0.03, x + 0.07, 0.39, z - 0.03, F.aonori, M.smooth, nc())
		Kit.box(m, 0.1, 0.005, 0.07, x + 0.02, 0.4, z + 0.02, F.bonito, M.smooth, nc({ rot = CFrame.Angles(math.rad(20), k, 0) }))
	end
	for k = 0, 1 do
		Kit.part(m, Vector3.new(0.02, 0.5, 0.02), CFrame.new(0.38 - k * 0.06, 0.45, -0.16) * CFrame.Angles(math.rad(25), 0, math.rad(-20 + k * 8)), P.wood_light, M.wood, nc())
	end
	local _ = recipe
end

local function dishMochi(m, recipe)
	-- hanami dango on skewers and a bowl of whisked matcha
	local y = plateRect(m, 1.1, 0.65, c("#E8E0D0"), c("#8A6A4A"))
	for s = 0, 1 do
		local z = -0.12 + s * 0.24
		Kit.part(m, Vector3.new(0.9, 0.025, 0.025), CFrame.new(-0.05, y + 0.12, z), P.wood_light, M.wood, nc())
		for k, col in ipairs({ c("#F4B6C8"), F.porcelain, F.matcha }) do
			Kit.ball(m, 0.22, -0.3 + k * 0.17, y + 0.12, z, col, M.smooth, nc({ reflectance = 0.05 }))
		end
	end
	Kit.cyl(m, 0.42, 0.24, 0.62, 0.12, 0.28, c("#3A3A32"), M.slate, nc())
	Kit.cyl(m, 0.36, 0.01, 0.62, 0.245, 0.28, F.matchaFoam, M.sand, nc())
	local _ = recipe
end

local function dishGriddle(m, recipe)
	if recipe.id == "jingisukan" then
		-- cast-iron dome grill with lamb slices and vegetables around the rim
		Kit.cyl(m, 1.4, 0.06, 0, 0.03, 0, P.wood_dark, M.wood, nc())
		Kit.cyl(m, 1.3, 0.08, 0, 0.1, 0, P.charcoal, M.metal, nc())
		Kit.blob(m, 0.95, 0.42, 0.95, 0, 0.14, 0, P.charcoal, M.metal, nc())
		for k = 0, 5 do
			local a = k * math.pi / 3
			Kit.box(m, 0.02, 0.03, 0.4, math.cos(a) * 0.25, 0.3, math.sin(a) * 0.25, P.black, M.metal, nc({ rot = CFrame.Angles(0, math.pi / 2 - a, math.rad(25)) }))
		end
		for k = 0, 3 do
			Kit.blob(m, 0.32, 0.04, 0.22, -0.12 + (k % 2) * 0.24, 0.33 + math.floor(k / 2) * 0.03, -0.1 + math.floor(k / 2) * 0.2, lerp(F.lamb, c("#5A2E22"), (k % 2) * 0.3), M.smooth, nc({ rot = CFrame.Angles(math.rad(14), k, 0), reflectance = 0.1 }))
		end
		for k = 0, 7 do
			local a = k * math.pi / 4
			local col = ({ F.pumpkin, F.cabbage, c("#F3EEDC"), F.scallion })[k % 4 + 1]
			Kit.blob(m, 0.2, 0.06, 0.12, math.cos(a) * 0.55, 0.17, math.sin(a) * 0.55, col, M.smooth, nc({ rot = CFrame.Angles(0, -a, 0) }))
		end
		return
	end
	local y = plateRound(m, 1.3, F.porcelain, F.indigo)
	if recipe.id == "goya_champuru" then
		local rnd = seq(41)
		Kit.blob(m, 0.85, 0.08, 0.7, 0, y + 0.03, 0, lerp(F.scrambled, P.white, 0.3), M.smooth, nc())
		for k = 0, 23 do
			local x, z = (rnd() - 0.5) * 0.75, (rnd() - 0.5) * 0.6
			local kind = k % 4
			if kind == 0 then
				Kit.part(m, Vector3.new(0.16, 0.05, 0.12), CFrame.new(x, y + 0.06, z) * CFrame.Angles(0, rnd() * 6, 0), F.goya, M.sand, nc())
			elseif kind == 1 then
				Kit.box(m, 0.14, 0.1, 0.14, x, y + 0.07, z, lerp(F.tofu, F.golden, 0.25), M.smooth, nc({ rot = CFrame.Angles(0, rnd() * 3, 0) }))
			elseif kind == 2 then
				Kit.blob(m, 0.18, 0.07, 0.14, x, y + 0.07, z, F.scrambled, M.smooth, nc())
			else
				Kit.blob(m, 0.2, 0.04, 0.12, x, y + 0.08, z, F.chashuMeat, M.smooth, nc({ rot = CFrame.Angles(0, rnd() * 3, 0) }))
			end
		end
		for k = 0, 4 do
			Kit.box(m, 0.09, 0.005, 0.06, -0.1 + k * 0.06, y + 0.15, (k % 2) * 0.06, F.bonito, M.smooth, nc({ rot = CFrame.Angles(math.rad(20), k, 0) }))
		end
		return
	end
	-- okonomiyaki: thick pancake, glossy sauce, mayo lattice, aonori, bonito and red ginger
	Kit.cyl(m, 1.0, 0.16, 0, y + 0.08, 0, lerp(F.takoyaki, P.black, 0.25), M.sand, nc())
	Kit.cyl(m, 0.96, 0.17, 0, y + 0.09, 0, F.takoyaki, M.sand, nc())
	Kit.cyl(m, 0.9, 0.02, 0, y + 0.18, 0, F.okoSauce, M.smooth, nc({ reflectance = 0.25 }))
	for k = -2, 2 do
		Kit.box(m, 0.85 - math.abs(k) * 0.15, 0.015, 0.025, k * 0.06, y + 0.195, k * 0.12, F.mayo, M.smooth, nc({ rot = CFrame.Angles(0, math.rad(35), 0) }))
		Kit.box(m, 0.85 - math.abs(k) * 0.15, 0.015, 0.025, -k * 0.06, y + 0.197, k * 0.12, F.mayo, M.smooth, nc({ rot = CFrame.Angles(0, math.rad(-35), 0) }))
	end
	for k = 0, 7 do
		Kit.box(m, 0.03, 0.01, 0.03, -0.3 + (k % 4) * 0.2, y + 0.2, -0.2 + math.floor(k / 4) * 0.35, F.aonori, M.smooth, nc())
	end
	for k = 0, 5 do
		Kit.box(m, 0.12, 0.005, 0.08, -0.15 + (k % 3) * 0.12, y + 0.21, -0.05 + math.floor(k / 3) * 0.1, F.bonito, M.smooth, nc({ rot = CFrame.Angles(math.rad(25), k * 1.1, 0) }))
	end
	for k = 0, 3 do
		Kit.box(m, 0.12, 0.02, 0.02, 0.25 + (k % 2) * 0.04, y + 0.21, 0.25 + k * 0.03, F.beniShoga, M.smooth, nc({ rot = CFrame.Angles(0, k * 0.6, 0) }))
	end
end

local function dish(recipeId, gold)
	local recipe = Recipes.byId[recipeId]
	local m = Kit.model("Dish")
	if gold then
		Kit.cyl(m, 1.75, 0.04, 0, 0.01, 0, P.gold, M.foil, nc())
		local shine = Kit.box(m, 0.3, 0.05, 0.3, 0, 0.6, 0, P.gold, M.smooth, nc({ transparency = 1 }))
		Kit.particles(shine, "sparkle", { rate = 2, color = "#FFE08A", glow = 0.6 })
	end
	if not recipe then
		plateRound(m, 1.2)
		Kit.finish(m, Vector3.new(1.6, 1, 1.2))
		return m
	end
	local kind = recipe.dish
	if kind == "nigiri" then
		dishNigiri(m, recipe)
	elseif kind == "maki" then
		dishMaki(m, recipe)
	elseif kind == "roll" then
		dishRoll(m, recipe)
	elseif kind == "temaki" then
		dishTemaki(m, recipe)
	elseif kind == "gunkan" then
		dishGunkan(m, recipe)
	elseif kind == "sashimi" then
		dishSashimi(m, recipe)
	elseif kind == "platter" then
		dishPlatter(m, recipe)
	elseif kind == "bowl" then
		if recipe.id == "matcha_soba" then
			dishZaruSoba(m, recipe)
		else
			ramenBowl(m, recipe)
		end
	elseif kind == "tsukemen" then
		dishTsukemen(m, recipe)
	elseif kind == "soup" then
		dishSoup(m, recipe)
	elseif kind == "edamame" then
		dishEdamame(m, recipe)
	elseif kind == "cup" then
		dishCup(m, recipe)
	elseif kind == "bottle" then
		dishRamune(m)
	elseif kind == "gyoza" then
		dishGyoza(m, recipe)
	elseif kind == "fried" then
		dishFried(m, recipe)
	elseif kind == "takoyaki" then
		dishTakoyaki(m, recipe)
	elseif kind == "mochi" then
		dishMochi(m, recipe)
	elseif kind == "okonomiyaki" then
		dishGriddle(m, recipe)
	else
		plateRound(m, 1.2)
	end
	Kit.finish(m, Vector3.new(1.6, 1, 1.2))
	m:SetAttribute("Recipe", recipeId)
	return m
end

---------------------------------------------------------------------------------------------------
-- Ingredients (what you carry from the shelves and put on the board)
---------------------------------------------------------------------------------------------------

-- Fish block (saku) or fillet with fat lines / skin
local function ingFish(m, id, col)
	if id == "shrimp" then
		-- two raw shrimp, curled, with segments and tail
		for s = 0, 1 do
			local base = CFrame.new(-0.14 + s * 0.28, 0.12, -0.06 + s * 0.12) * CFrame.Angles(0, math.rad(s * 160), 0)
			for k = 0, 5 do
				local a = k * 0.42
				blobAt(m, 0.17, 0.17 - k * 0.014, 0.19 - k * 0.014, base * CFrame.new(math.cos(a) * 0.22, 0, math.sin(a) * 0.22) * CFrame.Angles(0, -a, 0), lerp(c("#F2A08A"), c("#E86A4A"), (k % 2) * 0.4), M.smooth, nc({ reflectance = 0.1 }))
			end
			Kit.wedge(m, 0.04, 0.2, 0.18, base * CFrame.new(-0.04, 0.02, 0.27) * CFrame.Angles(0, 0, math.rad(90)), F.shrimpRed, M.smooth, nc())
		end
		return
	elseif id == "octopus" then
		-- boiled tentacle with suckers
		for k = 0, 5 do
			local a = k * 0.5
			local s = 0.2 - k * 0.022
			local p = CFrame.new(math.cos(a) * 0.22 - 0.05, s / 2, math.sin(a) * 0.22)
			Kit.ball(m, s, p.X, p.Y, p.Z, lerp(c("#B8344A"), c("#8A2A3A"), k * 0.1), M.smooth, nc({ reflectance = 0.12 }))
			Kit.ball(m, s * 0.45, p.X - 0.03, p.Y - s * 0.25, p.Z + 0.05, c("#F2D8D8"), M.smooth, nc())
		end
		return
	elseif id == "eel" then
		-- grilled kabayaki fillet with char lines and glaze
		Kit.box(m, 0.75, 0.08, 0.32, 0, 0.06, 0, F.eel, M.smooth, nc({ reflectance = 0.25 }))
		for k = 0, 3 do
			Kit.box(m, 0.03, 0.085, 0.3, -0.27 + k * 0.18, 0.063, 0, lerp(F.eel, P.black, 0.5), M.smooth, nc())
		end
		Kit.box(m, 0.75, 0.02, 0.3, 0, 0.11, 0, F.sauce, M.smooth, nc({ reflectance = 0.35, transparency = 0.2 }))
		return
	end
	-- saku block: tuna/otoro/yellowtail/salmon
	local fat = ({ salmon = F.salmonFat, otoro = F.otoroFat, tuna = F.tunaLight, yellowtail = F.blood })[id]
	-- the block sits on a sheet of butcher paper
	Kit.box(m, 0.8, 0.01, 0.42, 0, 0.005, 0, P.paper, M.smooth, nc())
	Kit.box(m, 0.75, 0.2, 0.34, 0, 0.11, 0, col, M.smooth, nc({ reflectance = 0.12 }))
	if id == "salmon" then
		Kit.box(m, 0.75, 0.05, 0.345, 0, 0.035, 0, c("#C8CED2"), M.metal, nc({ reflectance = 0.2 }))
	end
	if id == "yellowtail" then
		Kit.box(m, 0.76, 0.012, 0.06, 0, 0.215, 0.1, F.blood, M.smooth, nc())
		Kit.box(m, 0.76, 0.2, 0.012, 0, 0.11, -0.172, lerp(col, F.blood, 0.3), M.smooth, nc())
	elseif fat then
		for k = 0, 3 do
			local x = -0.27 + k * 0.18
			Kit.box(m, 0.03, 0.012, 0.36, x, 0.215, 0, fat, M.smooth, nc({ rot = CFrame.Angles(0, math.rad(25), 0) }))
			Kit.box(m, 0.03, 0.2, 0.012, x + 0.04, 0.11, -0.172, fat, M.smooth, nc({ rot = CFrame.Angles(0, 0, math.rad(15)) }))
		end
	end
end

local function ingredient(id)
	local ing = Ingredients.byId[id]
	local m = Kit.model("Ing")
	local col = ing and Color.hex(ing.color) or P.white
	local shape = ing and ing.shape or "pack"
	if shape == "fillet" then
		ingFish(m, id, col)
	elseif id == "cucumber" then
		-- two Japanese cucumbers: bumpy dark skin, pale cut ends
		for s = 0, 1 do
			local z = -0.08 + s * 0.16
			Kit.cylH(m, 0.17, 0.72, 0, 0.09, z, F.cucumber, M.sand, nc({ rot = CFrame.Angles(0, math.rad(s * 8), 0) }))
			Kit.cylH(m, 0.13, 0.725, 0, 0.09, z, F.cucumberIn, M.smooth, nc({ rot = CFrame.Angles(0, math.rad(s * 8), 0) }))
		end
	elseif id == "avocado" then
		-- pear shape with a halved one showing the stone
		Kit.blob(m, 0.32, 0.42, 0.3, -0.18, 0.21, 0, c("#3E4A22"), M.sand, nc())
		Kit.blob(m, 0.24, 0.24, 0.22, -0.18, 0.38, 0, c("#3E4A22"), M.sand, nc())
		Kit.blob(m, 0.3, 0.12, 0.38, 0.18, 0.06, 0, c("#3E4A22"), M.sand, nc())
		Kit.blob(m, 0.27, 0.1, 0.34, 0.18, 0.1, 0, F.avocado, M.smooth, nc())
		Kit.blob(m, 0.14, 0.1, 0.14, 0.18, 0.13, 0.04, c("#8A5A2A"), M.smooth, nc({ reflectance = 0.2 }))
	elseif id == "daikon" then
		Kit.cylH(m, 0.26, 0.6, 0, 0.13, 0, F.daikon, M.smooth, nc())
		Kit.cylH(m, 0.16, 0.2, -0.38, 0.13, 0, F.daikon, M.smooth, nc())
		for k = 0, 3 do
			Kit.part(m, Vector3.new(0.35, 0.04, 0.1), CFrame.new(0.42, 0.18 + k * 0.03, -0.06 + k * 0.04) * CFrame.Angles(0, math.rad(-15 + k * 10), math.rad(20)), c("#5E9A3A"), M.smooth, nc())
		end
	elseif shape == "veg" then
		Kit.cylH(m, 0.2, 0.75, 0, 0.12, 0, col, M.smooth, nc())
	elseif shape == "sack" then
		-- paper sack, folded top, printed label
		Kit.blob(m, 0.6, 0.62, 0.42, 0, 0.3, 0, P.paper_warm, M.fabric, nc())
		Kit.box(m, 0.5, 0.12, 0.3, 0, 0.6, 0, P.paper_warm, M.fabric, nc())
		Kit.box(m, 0.52, 0.04, 0.31, 0, 0.66, 0, lerp(P.paper_warm, P.wood, 0.25), M.fabric, nc())
		Kit.box(m, 0.34, 0.22, 0.02, 0, 0.32, -0.21, id == "rice" and F.lacquerRed or F.indigo, M.smooth, nc())
		Kit.box(m, 0.2, 0.1, 0.022, 0, 0.32, -0.212, P.white, M.smooth, nc())
	elseif shape == "jar" then
		if id == "ikura" then
			Kit.cyl(m, 0.5, 0.16, 0, 0.08, 0, P.white, M.plastic, nc())
			for k = 0, 9 do
				Kit.ball(m, 0.1, -0.15 + (k % 4) * 0.1, 0.18, -0.1 + math.floor(k / 4) * 0.1, F.ikura, M.glass, nc({ transparency = 0.15, reflectance = 0.25 }))
			end
		elseif id == "matcha" or id == "green_tea" then
			-- tea tin with a paper label
			Kit.cyl(m, 0.36, 0.48, 0, 0.24, 0, id == "matcha" and F.matcha or c("#2E5A3A"), M.metal, nc({ reflectance = 0.15 }))
			Kit.cyl(m, 0.38, 0.1, 0, 0.5, 0, P.metal, M.metal, nc())
			Kit.cyl(m, 0.37, 0.2, 0, 0.22, 0, P.paper, M.smooth, nc())
		elseif id == "miso_paste" then
			Kit.cyl(m, 0.5, 0.28, 0, 0.14, 0, P.white, M.plastic, nc())
			Kit.cyl(m, 0.46, 0.02, 0, 0.29, 0, col, M.sand, nc())
			Kit.cyl(m, 0.52, 0.04, 0, 0.3, 0, F.lacquerRed, M.plastic, nc({ transparency = 0.5 }))
		elseif id == "sesame" then
			Kit.cyl(m, 0.32, 0.4, 0, 0.2, 0, P.glass, M.glass, nc({ transparency = 0.4 }))
			Kit.cyl(m, 0.28, 0.3, 0, 0.16, 0, col, M.sand, nc())
			Kit.cyl(m, 0.34, 0.08, 0, 0.44, 0, F.lacquerRed, M.plastic, nc())
		else
			-- broth stock in a glass jar with a wooden lid and a label
			Kit.cyl(m, 0.42, 0.46, 0, 0.23, 0, P.glass, M.glass, nc({ transparency = 0.4, reflectance = 0.15 }))
			Kit.cyl(m, 0.38, 0.34, 0, 0.18, 0, col, M.smooth, nc({ reflectance = 0.15 }))
			Kit.cyl(m, 0.44, 0.1, 0, 0.5, 0, P.wood_dark, M.wood, nc())
			Kit.cyl(m, 0.43, 0.14, 0, 0.26, 0, P.paper, M.smooth, nc())
		end
	elseif shape == "bottle" then
		if id == "ramune" then
			dishRamune(m, 0.55)
		else
			Kit.cyl(m, 0.26, 0.5, 0, 0.25, 0, col, M.glass, nc({ transparency = 0.15, reflectance = 0.15 }))
			Kit.cyl(m, 0.2, 0.08, 0, 0.54, 0, col, M.glass, nc({ transparency = 0.15 }))
			Kit.cyl(m, 0.12, 0.18, 0, 0.66, 0, col, M.glass, nc({ transparency = 0.15 }))
			Kit.cyl(m, 0.14, 0.06, 0, 0.77, 0, F.lacquerRed, M.plastic, nc())
			Kit.cyl(m, 0.27, 0.2, 0, 0.25, 0, P.paper, M.smooth, nc())
		end
	elseif shape == "noodle" then
		-- portions of fresh wavy noodles on a tray
		Kit.box(m, 0.75, 0.04, 0.45, 0, 0.02, 0, P.white, M.plastic, nc())
		local thick = id == "tsukemen_noodles" and 0.06 or 0.04
		for p = 0, 1 do
			local px = -0.18 + p * 0.36
			Kit.blob(m, 0.32, 0.1, 0.32, px, 0.08, 0, col, M.smooth, nc())
			for k = 0, 5 do
				Kit.part(m, Vector3.new(0.28, thick, thick), CFrame.new(px + (k % 2) * 0.03 - 0.015, 0.11 + (k % 3) * 0.02, -0.1 + k * 0.04) * CFrame.Angles(0, math.rad(-20 + k * 9), math.rad((k % 2) * 6)), lerp(col, P.white, (k % 3) * 0.08), M.smooth, nc({ shape = Enum.PartType.Cylinder }))
			end
		end
	elseif shape == "egg" then
		-- carton of four brown eggs
		Kit.box(m, 0.62, 0.1, 0.36, 0, 0.05, 0, c("#C9B8A0"), M.cardboard, nc())
		for k = 0, 3 do
			Kit.blob(m, 0.2, 0.26, 0.2, -0.22 + k * 0.145, 0.2, 0, c("#C9894A"), M.smooth, nc({ reflectance = 0.04 }))
		end
	elseif shape == "sheet" then
		-- stack of nori sheets in a clear pack
		for k = 0, 4 do
			Kit.box(m, 0.6, 0.012, 0.52, 0, 0.02 + k * 0.016, 0, k % 2 == 0 and F.nori or F.noriLight, M.smooth, nc({ reflectance = 0.06 }))
		end
		Kit.box(m, 0.64, 0.1, 0.56, 0, 0.05, 0, P.glass, M.glass, nc({ transparency = 0.7 }))
		Kit.box(m, 0.2, 0.08, 0.02, 0.15, 0.06, -0.285, P.gold, M.smooth, nc())
	elseif shape == "ball" then
		for k, cc in ipairs({ c("#F4B6C8"), P.white, F.matcha, c("#F4B6C8"), P.white, F.matcha }) do
			local x, z = -0.2 + ((k - 1) % 3) * 0.2, -0.1 + math.floor((k - 1) / 3) * 0.2
			Kit.blob(m, 0.2, 0.15, 0.2, x, 0.1, z, cc, M.smooth, nc())
		end
		Kit.box(m, 0.66, 0.03, 0.46, 0, 0.015, 0, P.wood_light, M.wood, nc())
	elseif shape == "leaf" then
		-- bunch of scallions with white ends and roots, tied with a band
		for k = -2, 2 do
			Kit.part(m, Vector3.new(0.7, 0.06, 0.06), CFrame.new(0.05, 0.05, k * 0.05) * CFrame.Angles(0, math.rad(k * 3), 0), col, M.smooth, nc({ shape = Enum.PartType.Cylinder }))
			Kit.part(m, Vector3.new(0.2, 0.065, 0.065), CFrame.new(-0.32, 0.05, k * 0.05) * CFrame.Angles(0, math.rad(k * 3), 0), P.white, M.smooth, nc({ shape = Enum.PartType.Cylinder }))
		end
		Kit.box(m, 0.04, 0.16, 0.3, -0.2, 0.06, 0, F.indigo, M.plastic, nc())
		Kit.box(m, 0.06, 0.05, 0.22, -0.44, 0.05, 0, c("#D8D0B0"), M.fabric, nc())
	elseif id == "naruto" then
		Kit.cylH(m, 0.3, 0.6, 0, 0.15, 0, F.naruto, M.smooth, nc())
		for k, cc in ipairs({ F.narutoPink, F.naruto, F.narutoPink }) do
			Kit.cylH(m, 0.24 - (k - 1) * 0.07, 0.605 + k * 0.002, 0, 0.15, 0, cc, M.smooth, nc())
		end
		for k = 0, 5 do
			local a = k * math.pi / 3
			Kit.box(m, 0.6, 0.04, 0.04, 0, 0.15 + math.sin(a) * 0.15, math.cos(a) * 0.15, F.naruto, M.smooth, nc())
		end
	elseif id == "tofu" then
		Kit.box(m, 0.62, 0.12, 0.44, 0, 0.06, 0, P.white, M.plastic, nc({ transparency = 0.3 }))
		Kit.box(m, 0.52, 0.22, 0.36, 0, 0.13, 0, F.tofu, M.smooth, nc())
		Kit.box(m, 0.6, 0.02, 0.42, 0, 0.1, 0, P.water, M.glass, nc({ transparency = 0.6 }))
	elseif id == "chashu" then
		-- rolled braised pork belly tied with string
		Kit.cylH(m, 0.36, 0.62, 0, 0.18, 0, F.chashuEdge, M.smooth, nc({ reflectance = 0.15 }))
		Kit.cylH(m, 0.3, 0.625, 0, 0.18, 0, F.chashuFat, M.smooth, nc())
		Kit.cylH(m, 0.18, 0.63, 0, 0.18, 0, F.chashuMeat, M.smooth, nc())
		for k = 0, 2 do
			Kit.cylH(m, 0.37, 0.02, -0.18 + k * 0.18, 0.18, 0, P.paper, M.fabric, nc())
		end
	elseif id == "surimi" then
		for k = 0, 3 do
			Kit.cylH(m, 0.1, 0.6, 0, 0.06 + math.floor(k / 2) * 0.09, -0.06 + (k % 2) * 0.12, P.white, M.smooth, nc())
			Kit.box(m, 0.6, 0.04, 0.06, 0, 0.1 + math.floor(k / 2) * 0.09, -0.06 + (k % 2) * 0.12, F.crab, M.smooth, nc())
		end
	elseif id == "corn" then
		Kit.cylH(m, 0.26, 0.6, 0, 0.13, 0, F.corn, M.sand, nc())
		for k = 0, 4 do
			Kit.cylH(m, 0.27, 0.025, -0.24 + k * 0.12, 0.13, 0, lerp(F.corn, P.wood, 0.2), M.sand, nc())
		end
		Kit.cylH(m, 0.12, 0.12, 0.36, 0.13, 0, c("#C8B87A"), M.wood, nc())
	elseif id == "butter" then
		Kit.box(m, 0.5, 0.18, 0.28, 0, 0.09, 0, P.paper, M.smooth, nc())
		Kit.box(m, 0.36, 0.19, 0.285, 0.08, 0.09, 0, F.butter, M.smooth, nc({ reflectance = 0.1 }))
		Kit.box(m, 0.16, 0.18, 0.3, -0.18, 0.09, 0, F.indigo, M.smooth, nc())
	elseif id == "edamame" then
		Kit.box(m, 0.6, 0.06, 0.4, 0, 0.03, 0, P.white, M.plastic, nc())
		for k = 0, 5 do
			Kit.blob(m, 0.32, 0.08, 0.12, -0.15 + (k % 2) * 0.28, 0.08 + math.floor(k / 2) * 0.02, -0.12 + math.floor(k / 2) * 0.12, c("#6FAE3E"), M.smooth, nc({ rot = CFrame.Angles(0, k * 0.4, 0) }))
		end
	elseif id == "gyoza_raw" then
		Kit.box(m, 0.7, 0.04, 0.44, 0, 0.02, 0, P.white, M.plastic, nc())
		for k = 0, 5 do
			gyozaPiece(m, CFrame.new(-0.22 + (k % 3) * 0.22, 0.02, -0.1 + math.floor(k / 3) * 0.2) * CFrame.Angles(0, math.rad(10), 0), false)
		end
	elseif id == "kikurage" then
		Kit.box(m, 0.5, 0.38, 0.06, 0, 0.19, 0, P.glass, M.glass, nc({ transparency = 0.6 }))
		for k = 0, 4 do
			Kit.blob(m, 0.18, 0.12, 0.05, -0.12 + (k % 3) * 0.12, 0.12 + math.floor(k / 3) * 0.14, 0, F.kikurage, M.smooth, nc({ rot = CFrame.Angles(0, 0, k) }))
		end
		Kit.box(m, 0.5, 0.06, 0.07, 0, 0.36, 0, F.lacquerRed, M.plastic, nc())
	elseif id == "minced_pork" or id == "chicken" then
		-- butcher tray with cling film
		Kit.box(m, 0.62, 0.05, 0.42, 0, 0.025, 0, P.white, M.plastic, nc())
		if id == "minced_pork" then
			for k = 0, 11 do
				Kit.ball(m, 0.12, -0.2 + (k % 4) * 0.13, 0.08 + (k % 3) * 0.015, -0.1 + math.floor(k / 4) * 0.1, lerp(c("#C8665A"), c("#E8A898"), (k % 3) * 0.25), M.sand, nc())
			end
		else
			for k = 0, 2 do
				Kit.blob(m, 0.24, 0.1, 0.3, -0.17 + k * 0.17, 0.08, 0, lerp(c("#E8B48A"), c("#F2CBB0"), (k % 2) * 0.5), M.smooth, nc({ rot = CFrame.Angles(0, k * 0.5, 0), reflectance = 0.08 }))
			end
		end
		Kit.box(m, 0.64, 0.01, 0.44, 0, 0.15, 0, P.glass, M.glass, nc({ transparency = 0.75, reflectance = 0.3 }))
	elseif id == "mochi" then
		Kit.box(m, 0.66, 0.03, 0.46, 0, 0.015, 0, P.wood_light, M.wood, nc())
		for k = 0, 5 do
			Kit.blob(m, 0.2, 0.15, 0.2, -0.2 + (k % 3) * 0.2, 0.1, -0.1 + math.floor(k / 3) * 0.2, k % 2 == 0 and c("#F4B6C8") or P.white, M.smooth, nc())
		end
	else
		-- generic pack with a coloured label
		Kit.box(m, 0.5, 0.3, 0.35, 0, 0.15, 0, col, M.smooth, nc())
		Kit.box(m, 0.52, 0.1, 0.37, 0, 0.18, 0, P.white, M.smooth, nc())
	end
	Kit.finish(m, Vector3.new(0.8, 0.6, 0.6))
	m:SetAttribute("Ingredient", id)
	return m
end

---------------------------------------------------------------------------------------------------
-- Supplier boxes, dirty dishes, stacks and tools
---------------------------------------------------------------------------------------------------

local BOX_BAND = { fish = "#2E5A8C", fridge = "#3E8A4A", dry = "#B3262E" }

-- Paper label on a big face of a box: the ingredient icon in the middle and "left/total" in the
-- lower-right corner (TextLabel "Count", updated by SupplyService)
local function boxLabel(body, face, icon, count, cap)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Label"
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 60
	gui.LightInfluence = 1
	gui.Parent = body
	local paper = Instance.new("Frame")
	paper.AnchorPoint = Vector2.new(0.5, 0.5)
	paper.Position = UDim2.fromScale(0.5, 0.48)
	paper.Size = UDim2.fromScale(0.8, 0.72)
	paper.BackgroundColor3 = Color3.fromRGB(244, 235, 221)
	paper.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.08, 0)
	corner.Parent = paper
	local iconLabel = Instance.new("TextLabel")
	iconLabel.Name = "Icon"
	iconLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	iconLabel.Position = UDim2.fromScale(0.42, 0.5)
	iconLabel.Size = UDim2.fromScale(0.62, 0.86)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Text = icon
	iconLabel.TextScaled = true
	iconLabel.AutoLocalize = false
	iconLabel.Parent = paper
	local countLabel = Instance.new("TextLabel")
	countLabel.Name = "Count"
	countLabel.AnchorPoint = Vector2.new(1, 1)
	countLabel.Position = UDim2.new(1, -4, 1, -4)
	countLabel.Size = UDim2.fromScale(0.44, 0.34)
	countLabel.BackgroundColor3 = Color3.fromRGB(43, 35, 32)
	countLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	countLabel.Text = tostring(count) .. "/" .. tostring(cap)
	countLabel.TextScaled = true
	countLabel.FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json")
	countLabel.AutoLocalize = false
	countLabel.Parent = paper
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0.25, 0)
	round.Parent = countLabel
	return gui
end

-- Supplier cardboard box: packing tape, hand holes, coloured band by storage type, and on both big
-- faces the icon with the portions left (language independent). cap = portions of a full box.
-- Products peeking out of an open box: up to 6 in a 3x2 grid, tops just above the rim
local function boxContents(m, id, n, W, H, D)
	local shown = math.min(n, 6)
	local cols, rows = 3, 2
	local cw, cd = (W - 0.25) / cols, (D - 0.25) / rows
	for k = 1, shown do
		local p = ingredient(id)
		local ok, ext = pcall(function()
			return p:GetExtentsSize()
		end)
		if ok and ext then
			local fit = math.min(0.9 * cw / math.max(ext.X, 0.01), 0.9 * cd / math.max(ext.Z, 0.01), 0.7 / math.max(ext.Y, 0.01), 1)
			pcall(function()
				p:ScaleTo(fit)
			end)
		end
		local i, j = (k - 1) % cols, math.floor((k - 1) / cols)
		local x = -(W - 0.25) / 2 + cw * (i + 0.5)
		local z = -(D - 0.25) / 2 + cd * (j + 0.5)
		local target = CFrame.new(x, H - 0.5, z) * CFrame.Angles(0, math.rad((k * 37) % 20 - 10), 0)
		p:PivotTo(target)
		local okBox, bb, size = pcall(function()
			return p:GetBoundingBox()
		end)
		if okBox and bb then
			p:PivotTo(target + Vector3.new(0, target.Position.Y - (bb.Position.Y - size.Y / 2), 0))
		end
		for _, d in ipairs(p:GetDescendants()) do
			if d:IsA("BasePart") then
				d.CanCollide = false
				d.CanQuery = false
			end
		end
		p.Parent = m
	end
end

-- Supplier cardboard box, closed on the racks: packing tape, hand holes, coloured band by storage
-- type, and on both big faces the icon with the portions left (language independent).
-- cap = portions of a full box. open = the box you carry: flaps folded out and some of the
-- products inside visible (as in shop tycoons), as long as something is left in it.
local function box(id, count, cap, open)
	local ing = Ingredients.byId[id]
	local m = Kit.model("Box")
	local W, H, D, T = 1.8, 1.3, 1.5, 0.07
	local icon = ing and ing.icon or "📦"
	local n = count or (ing and ing.units) or 0
	local full = math.max(cap or (ing and ing.units) or n, n)
	local band = BOX_BAND[ing and ing.storage or "dry"] or BOX_BAND.dry
	local front, back
	if open and n > 0 then
		local inside = lerp(P.cardboard, P.black, 0.35)
		Kit.box(m, W - 2 * T, T, D - 2 * T, 0, T / 2 + 0.02, 0, inside, M.cardboard, nc())
		front = Kit.box(m, W, H, T, 0, H / 2, -D / 2 + T / 2, P.cardboard, M.cardboard, { name = "Body" })
		back = Kit.box(m, W, H, T, 0, H / 2, D / 2 - T / 2, P.cardboard, M.cardboard, nc())
		for _, sx in ipairs({ -1, 1 }) do
			Kit.box(m, T, H, D - 2 * T, sx * (W / 2 - T / 2), H / 2, 0, P.cardboard, M.cardboard, nc())
			Kit.box(m, 0.02, 0.14, 0.4, sx * (W / 2 + 0.005), 0.95, 0, lerp(P.cardboard, P.black, 0.55), M.smooth, nc())
		end
		-- the inner faces of the walls are a little darker
		Kit.box(m, W - 2 * T, H - 0.1, 0.01, 0, H / 2, -D / 2 + T + 0.005, inside, M.cardboard, nc())
		Kit.box(m, W - 2 * T, H - 0.1, 0.01, 0, H / 2, D / 2 - T - 0.005, inside, M.cardboard, nc())
		-- coloured band on the outside of the walls only (the inside stays cardboard)
		for _, sz in ipairs({ -1, 1 }) do
			Kit.box(m, W + 0.02, 0.18, 0.01, 0, 0.18, sz * (D / 2 + 0.005), c(band), M.smooth, nc())
		end
		for _, sx in ipairs({ -1, 1 }) do
			Kit.box(m, 0.01, 0.18, D + 0.02, sx * (W / 2 + 0.005), 0.18, 0, c(band), M.smooth, nc())
		end
		-- four flaps folded outwards
		local a = math.rad(50)
		local len = 0.62
		local fl = lerp(P.cardboard, P.white, 0.08)
		for _, sz in ipairs({ -1, 1 }) do
			local hinge = Vector3.new(0, H, sz * D / 2)
			local dir = Vector3.new(0, math.sin(a), sz * math.cos(a))
			Kit.part(m, Vector3.new(W - 0.04, 0.04, len), CFrame.new(hinge + dir * (len / 2)) * CFrame.Angles(-sz * a, 0, 0), fl, M.cardboard, nc())
		end
		for _, sx in ipairs({ -1, 1 }) do
			local hinge = Vector3.new(sx * W / 2, H, 0)
			local dir = Vector3.new(sx * math.cos(a), math.sin(a), 0)
			Kit.part(m, Vector3.new(len * 0.8, 0.04, D - 0.06), CFrame.new(hinge + dir * (len * 0.4)) * CFrame.Angles(0, 0, sx * a), fl, M.cardboard, nc())
		end
		boxContents(m, id, n, W, H, D)
	else
		local body = Kit.box(m, W, H, D, 0, H / 2, 0, P.cardboard, M.cardboard, { name = "Body" })
		Kit.box(m, W + 0.02, 0.12, 0.3, 0, H - 0.05, 0, c("#D8C49A"), M.smooth, nc({ transparency = 0.1 }))
		Kit.box(m, W - 0.2, 0.012, 0.012, 0, H + 0.01, 0, lerp(P.cardboard, P.black, 0.35), M.smooth, nc())
		Kit.box(m, W + 0.02, 0.18, D + 0.02, 0, 0.18, 0, c(band), M.smooth, nc())
		for _, sx in ipairs({ -1, 1 }) do
			Kit.box(m, 0.02, 0.14, 0.4, sx * 0.905, 0.95, 0, lerp(P.cardboard, P.black, 0.55), M.smooth, nc())
		end
		front, back = body, body
	end
	-- front faces the shelf / aisle, back faces you when you carry it
	boxLabel(front, Enum.NormalId.Front, icon, n, full)
	boxLabel(back, Enum.NormalId.Back, icon, n, full)
	Kit.finish(m, Vector3.new(W, H, D))
	m:SetAttribute("Ingredient", id)
	return m
end

local function dirty(kind)
	local m = Kit.model("Dirty")
	if kind == "bowl" then
		local y = donburi(m, 1.3, 0.55, P.porcelain, F.porcelain, F.lacquerRed)
		Kit.cyl(m, 0.9, 0.012, 0.05, y - 0.005, 0, c("#A8865A"), M.smooth, nc({ transparency = 0.25, reflectance = 0.2 }))
		for k = 0, 2 do
			Kit.part(m, Vector3.new(0.3, 0.04, 0.04), CFrame.new(-0.1 + k * 0.08, y + 0.01, -0.05 + k * 0.08) * CFrame.Angles(0, k, 0), F.noodle, M.smooth, nc({ shape = Enum.PartType.Cylinder }))
		end
		scallions(m, 0.15, y + 0.01, 0.1, 3, 9)
	else
		local y = plateRound(m, 1.2, F.porcelain, F.indigo)
		Kit.cyl(m, 0.3, 0.008, 0.2, y + 0.002, 0.1, F.sauce, M.smooth, nc({ transparency = 0.3 }))
		for k = 0, 4 do
			Kit.ball(m, 0.06, -0.2 + k * 0.1, y + 0.02, (k % 2) * 0.15 - 0.05, F.rice, M.sand, nc())
		end
		Kit.blob(m, 0.3, 0.12, 0.24, -0.25, y + 0.06, 0.2, P.white, M.fabric, nc())
	end
	chopsticks(m, 0.1, -0.6, 10, 0.05)
	Kit.finish(m, Vector3.new(1.3, 0.6, 1.3))
	return m
end

local function dishStack(count, kind)
	local m = Kit.model("Stack")
	for k = 0, math.min(count, 5) - 1 do
		local col = kind == "dirty" and c("#D8D0C0") or F.porcelain
		Kit.cyl(m, 1.1, 0.1, 0, 0.06 + k * 0.12, 0, col, M.smooth, nc({ reflectance = 0.05 }))
		Kit.cyl(m, 1.12, 0.02, 0, 0.08 + k * 0.12, 0, F.indigo, M.smooth, nc())
	end
	Kit.finish(m, Vector3.new(1.2, 0.7, 1.2))
	return m
end

local function tool(kind)
	local m = Kit.model("Tool")
	if kind == "knife" then
		-- yanagiba: long single-bevel blade, spine, collar and wooden handle
		Kit.box(m, 1.25, 0.22, 0.025, 0.42, 0, 0, P.metal, M.metal, nc({ reflectance = 0.35 }))
		Kit.box(m, 1.25, 0.04, 0.03, 0.42, 0.1, 0, P.steel, M.metal, nc({ reflectance = 0.2 }))
		Kit.wedge(m, 0.025, 0.22, 0.2, CFrame.new(1.13, 0, 0) * CFrame.Angles(0, math.rad(90), 0), P.metal, M.metal, nc({ reflectance = 0.35 }))
		Kit.box(m, 0.08, 0.16, 0.1, -0.24, 0, 0, P.black, M.smooth, nc())
		Kit.box(m, 0.55, 0.14, 0.1, -0.55, 0, 0, P.hinoki, M.wood, nc())
	elseif kind == "mat" then
		for k = -4, 4 do
			Kit.cylH(m, 0.06, 1.3, 0, 0, k * 0.1, P.bamboo, M.wood, nc())
		end
		for _, x in ipairs({ -0.4, 0, 0.4 }) do
			Kit.box(m, 0.02, 0.065, 0.9, x, 0, 0, c("#E8E0C8"), M.fabric, nc())
		end
	elseif kind == "ladle" then
		Kit.cyl(m, 0.06, 1.4, 0, 0.5, 0, P.metal, M.metal, nc({ reflectance = 0.25 }))
		Kit.blob(m, 0.4, 0.2, 0.4, 0, -0.2, 0, P.metal, M.metal, nc({ reflectance = 0.25 }))
		Kit.cyl(m, 0.08, 0.4, 0, 1.0, 0, P.wood_dark, M.wood, nc())
	elseif kind == "spatula" then
		Kit.box(m, 0.5, 0.03, 0.4, 0.3, 0, 0, P.metal, M.metal, nc({ reflectance = 0.25 }))
		Kit.box(m, 0.8, 0.08, 0.08, -0.3, 0.05, 0, P.wood_dark, M.wood, nc())
	else
		-- tebo noodle strainer: mesh basket and long handle
		Kit.cyl(m, 0.5, 0.4, 0, 0, 0, P.metal, M.metal, nc({ transparency = 0.35 }))
		Kit.cyl(m, 0.52, 0.04, 0, 0.2, 0, P.steel, M.metal, nc())
		Kit.cylH(m, 0.06, 1.0, 0.7, 0.1, 0, P.wood_dark, M.wood, nc())
	end
	Kit.finish(m, Vector3.new(1.4, 0.4, 0.6))
	return m
end

return function(Registry)
	Registry.registerFood("dish", dish)
	Registry.registerFood("ingredient", ingredient)
	Registry.registerFood("box", box)
	Registry.registerFood("dirty", dirty)
	Registry.registerFood("stack", dishStack)
	Registry.registerFood("tool", tool)
	Registry.Food.BrothColors = BROTH
end
