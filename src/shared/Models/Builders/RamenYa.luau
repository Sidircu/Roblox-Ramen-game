--!nonstrict
-- "Ramen-ya" decoration pack, modelled on real ramen counters: industrial pendant lamps, a red
-- banner with white lettering, rows of menu posters, a retro ramen poster, a vertical sign, a
-- framed soup signboard, a wooden canopy over the counter, water pitchers, condiment caddies,
-- red vinyl stools and a wooden table with benches.
-- Conventions: front faces -Z; wall items have their back at +Z; ceiling items hang from y = h.
local CollectionService = game:GetService("CollectionService")

local Kit = require(script.Parent.Parent.Kit)
local P = require(script.Parent.Parent.Palette)
local Color = require(script.Parent.Parent.Parent.Util.Color)
local M = P.M

local JP_FONT = Font.new("rbxasset://fonts/families/FredokaOne.json", Enum.FontWeight.Bold)

local function size(item)
	return Vector3.new(item.size[1], item.size[2], item.size[3])
end

local function nc()
	return { collide = false, shadow = false }
end

local function point(root, name, x, y, z, yaw)
	local h = root.Size.Y
	return Kit.attach(root, name, CFrame.new(x, y - h / 2, z) * CFrame.Angles(0, math.rad(yaw or 0), 0))
end

-- Invisible panel carrying a text label. faces: nil = front (-Z), "back" = +Z, "both"
local function label(m, w, h, x, y, z, text, color, faces)
	local p = Kit.box(m, w, h, 0.02, x, y, z, P.white, M.smooth, { transparency = 1, collide = false, shadow = false })
	p.CanQuery = false
	if faces ~= "back" then
		Kit.text(p, Enum.NormalId.Front, text, { color = color, font = JP_FONT, pps = 40 })
	end
	if faces == "back" or faces == "both" then
		Kit.text(p, Enum.NormalId.Back, text, { color = color, font = JP_FONT, pps = 40 })
	end
	return p
end

-- Parts high under the ceiling hide in build view like the roof (see Camera.setRoofs)
local function high(p)
	CollectionService:AddTag(p, "Roof")
	return p
end

-- Industrial pendant: cord, black metal shade with a brass rim and a glowing glass globe
local function pendant(m, x, top, z, drop)
	high(Kit.cyl(m, 0.05, drop, x, top - drop / 2, z, P.black, M.fabric, nc()))
	local y = top - drop
	Kit.cyl(m, 0.18, 0.2, x, y - 0.05, z, P.charcoal, M.metal, nc())
	Kit.cyl(m, 0.72, 0.55, x, y - 0.4, z, P.charcoal, M.metal, { collide = false, shadow = false, reflectance = 0.1 })
	Kit.cyl(m, 0.76, 0.06, x, y - 0.68, z, P.brass, M.metal, nc())
	local bulb = Kit.ball(m, 0.62, x, y - 0.95, z, P.lamp, M.neon, { collide = false, shadow = false })
	bulb.Transparency = 0.1
	Kit.light(bulb, "Point", P.lamp_warm, 14, 1.2)
	return bulb
end

-- Hanging banner made of split cloth panels with lettering readable from both sides
local function banner(m, w, top, bottom, z, text, color)
	local n = math.max(2, math.floor(w / 1))
	local pw = w / n
	for i = 0, n - 1 do
		local x = -w / 2 + pw * (i + 0.5)
		local cloth = Kit.box(m, pw - 0.06, top - bottom, 0.04, x, (top + bottom) / 2, z, color, M.fabric, nc())
		cloth:SetAttribute("Animate", "sway")
		Kit.box(m, pw - 0.06, 0.1, 0.05, x, bottom + 0.12, z, P.lacquer_dark, M.fabric, nc())
	end
	Kit.box(m, w, 0.06, 0.05, 0, top - 0.12, z, P.white, M.fabric, nc())
	label(m, w - 0.4, (top - bottom) * 0.62, 0, (top + bottom) / 2 + 0.02, z - 0.04, text, "#FFFFFF", "both")
end

-- Bowl drawn flat (ellipses facing -Z): navy bowl, broth, noodles, egg, naruto and nori
local function bowlArt(m, x, y, z, s, broth)
	Kit.blob(m, 1.6 * s, 1.0 * s, 0.04, x, y, z, P.navy, M.smooth, nc())
	Kit.blob(m, 1.5 * s, 0.42 * s, 0.04, x, y + 0.27 * s, z - 0.02, broth or Color.hex("#D9A55A"), M.smooth, nc())
	for k = -2, 2 do
		Kit.box(m, 0.05 * s, 0.22 * s, 0.03, x + k * 0.12 * s, y + 0.3 * s, z - 0.04, P.neon_yellow, M.smooth, nc())
	end
	Kit.blob(m, 0.32 * s, 0.24 * s, 0.03, x - 0.4 * s, y + 0.3 * s, z - 0.05, P.white, M.smooth, nc())
	Kit.blob(m, 0.16 * s, 0.12 * s, 0.03, x - 0.4 * s, y + 0.3 * s, z - 0.06, P.koi_orange, M.smooth, nc())
	Kit.blob(m, 0.24 * s, 0.18 * s, 0.03, x + 0.42 * s, y + 0.3 * s, z - 0.05, P.white, M.smooth, nc())
	Kit.blob(m, 0.1 * s, 0.08 * s, 0.03, x + 0.42 * s, y + 0.3 * s, z - 0.06, P.sakura_dark, M.smooth, nc())
	Kit.box(m, 0.3 * s, 0.4 * s, 0.03, x + 0.62 * s, y + 0.5 * s, z - 0.03, P.nori, M.smooth, nc())
	-- chopsticks lifting noodles
	for k = 0, 1 do
		local cf = CFrame.new(x + (0.2 + k * 0.1) * s, y + 0.75 * s, z - 0.07) * CFrame.Angles(0, 0, math.rad(-28 - k * 6))
		Kit.part(m, Vector3.new(0.05 * s, 0.9 * s, 0.03), cf, P.wood_light, M.wood, nc())
	end
end

-- Row of colourful menu posters on a plane facing -Z (front face at z)
local POSTERS = {
	{ bg = "#FFD23B", text = "醤油", price = "¥780", broth = "#8A5A2E" },
	{ bg = "#F27A2E", text = "味噌", price = "¥850", broth = "#C88A3A" },
	{ bg = "#F7F5F0", text = "豚骨", price = "¥900", broth = "#EDE0C8" },
	{ bg = "#C0261E", text = "餃子", price = "¥450", broth = "#E3B070" },
	{ bg = "#FFD23B", text = "塩", price = "¥750", broth = "#EBD49A" },
	{ bg = "#F7F5F0", text = "炒飯", price = "¥600", broth = "#E8C25A" },
}

local function posterRow(m, x0, x1, y0, y1, z, count)
	local n = count or 5
	local pw = (x1 - x0) / n
	local ph = y1 - y0
	for i = 0, n - 1 do
		local info = POSTERS[i % #POSTERS + 1]
		local x = x0 + pw * (i + 0.5)
		local cy = (y0 + y1) / 2
		local bg = Color.hex(info.bg)
		Kit.box(m, pw - 0.08, ph, 0.03, x, cy, z + 0.015, bg, M.smooth, nc())
		-- photo of the dish
		Kit.box(m, pw - 0.3, ph * 0.42, 0.02, x, cy - ph * 0.02, z - 0.005, P.charcoal, M.smooth, nc())
		bowlArt(m, x, cy - ph * 0.06, z - 0.02, math.min(pw - 0.3, ph * 0.42) * 0.42, Color.hex(info.broth))
		local dark = info.bg == "#C0261E" or info.bg == "#F27A2E"
		label(m, pw - 0.2, ph * 0.26, x, y1 - ph * 0.16, z - 0.02, info.text, dark and "#FFFFFF" or "#C0261E")
		local tag = Kit.box(m, (pw - 0.08) * 0.62, ph * 0.16, 0.02, x, y0 + ph * 0.12, z - 0.01, dark and P.white or P.lacquer, M.smooth, nc())
		Kit.text(tag, Enum.NormalId.Front, info.price, { color = dark and "#C0261E" or "#FFFFFF", font = JP_FONT, pps = 40 })
		-- bits of tape on the top corners
		for _, sx in ipairs({ -1, 1 }) do
			Kit.box(m, 0.22, 0.08, 0.01, x + sx * (pw / 2 - 0.12), y1 - 0.04, z - 0.01, P.paper_warm, M.smooth, { collide = false, shadow = false, rot = CFrame.Angles(0, 0, math.rad(sx * 35)), transparency = 0.2 })
		end
	end
end

-- Small stainless water pitcher with a lid and a handle; bottom center at (x, y0, z)
local function pitcher(m, x, y0, z, s)
	s = s or 1
	Kit.cyl(m, 0.58 * s, 0.95 * s, x, y0 + 0.5 * s, z, P.metal, M.metal, { collide = false, reflectance = 0.25 })
	Kit.cyl(m, 0.62 * s, 0.06 * s, x, y0 + 0.04 * s, z, P.steel, M.metal, nc())
	Kit.cyl(m, 0.6 * s, 0.1 * s, x, y0 + 1.02 * s, z, P.steel, M.metal, nc())
	Kit.ball(m, 0.14 * s, x, y0 + 1.12 * s, z, P.charcoal, M.smooth, nc())
	Kit.wedge(m, 0.16 * s, 0.22 * s, 0.24 * s, CFrame.new(x, y0 + 0.92 * s, z - 0.36 * s), P.metal, M.metal, nc())
	for _, hy in ipairs({ 0.85, 0.3 }) do
		Kit.box(m, 0.08 * s, 0.07 * s, 0.26 * s, x, y0 + hy * s, z + 0.4 * s, P.metal, M.metal, nc())
	end
	Kit.box(m, 0.08 * s, 0.62 * s, 0.07 * s, x, y0 + 0.575 * s, z + 0.5 * s, P.metal, M.metal, nc())
end

return function(Registry)
	-- Lighting ------------------------------------------------------------------------------------
	Registry.register("pendant_lamp", function(m, item)
		Kit.finish(m, size(item))
		local h = item.size[2]
		pendant(m, 0, h, 0, h - 1.7)
		high(Kit.cyl(m, 0.4, 0.08, 0, h - 0.04, 0, P.charcoal, M.metal, nc()))
	end)

	Registry.register("chochin_orange", function(m, item)
		Kit.finish(m, size(item))
		local h = item.size[2]
		local bodyH, bodyD = 1.5, 1.15
		local cy = h - 0.6 - bodyH / 2
		high(Kit.cyl(m, 0.05, 0.6, 0, h - 0.3, 0, P.black, M.fabric, nc()))
		Kit.cyl(m, 0.7, 0.18, 0, cy + bodyH / 2 + 0.05, 0, P.black, M.smooth, nc())
		Kit.cyl(m, 0.7, 0.18, 0, cy - bodyH / 2 - 0.05, 0, P.black, M.smooth, nc())
		local body = Kit.blob(m, bodyD, bodyH, bodyD, 0, cy, 0, P.koi_orange, M.smooth, nc())
		for i = -2, 2 do
			local ring = 1 - (i * 0.18) ^ 2 * 1.2
			Kit.cyl(m, bodyD * ring + 0.02, 0.03, 0, cy + i * bodyH * 0.18, 0, P.vermilion, M.smooth, nc())
		end
		label(m, bodyD * 0.55, bodyH * 0.8, 0, cy, -bodyD / 2 - 0.01, "ラーメン", "#141414")
		label(m, bodyD * 0.55, bodyH * 0.8, 0, cy, bodyD / 2 + 0.01, "らーめん", "#141414", "back")
		Kit.light(body, "Point", P.lamp_warm, 12, 1.2)
		body:SetAttribute("Animate", "sway")
	end)

	-- Wooden canopy over the counter: hanging rods, frame, ribbed metal roof, red banner and
	-- three pendant lamps (the centrepiece of the ramen-ya look)
	Registry.register("ramenya_canopy", function(m, item)
		Kit.finish(m, size(item))
		local w, h, d = item.size[1], item.size[2], item.size[3]
		local frameY = h - 2.0
		for _, c in ipairs({ { -1, -1 }, { 1, -1 }, { 1, 1 }, { -1, 1 } }) do
			high(Kit.box(m, 0.1, 2.0, 0.1, c[1] * (w / 2 - 0.3), h - 1.0, c[2] * (d / 2 - 0.3), P.black, M.metal, nc()))
		end
		-- ribbed roof sheet sloping towards the customers
		local roof = Kit.box(m, w, 0.08, d, 0, frameY + 0.32, 0, P.steel, M.metal, { collide = false, rot = CFrame.Angles(math.rad(-6), 0, 0) })
		high(roof)
		for x = -w / 2 + 0.25, w / 2 - 0.2, 0.5 do
			high(Kit.box(m, 0.1, 0.08, d, x, frameY + 0.38, 0, P.metal, M.metal, { collide = false, shadow = false, rot = CFrame.Angles(math.rad(-6), 0, 0) }))
		end
		-- timber frame
		for _, z in ipairs({ -d / 2 + 0.15, d / 2 - 0.15 }) do
			high(Kit.box(m, w, 0.4, 0.3, 0, frameY, z, P.wood_dark, M.wood, nc()))
		end
		for _, x in ipairs({ -w / 2 + 0.15, 0, w / 2 - 0.15 }) do
			high(Kit.box(m, 0.25, 0.3, d - 0.3, x, frameY + 0.05, 0, P.wood_dark, M.wood, nc()))
		end
		Kit.box(m, w + 0.1, 0.12, 0.08, 0, frameY - 0.25, -d / 2 + 0.02, P.wood_black, M.wood, nc())
		-- red banner along the customer side and three pendant lamps
		banner(m, w - 0.2, frameY - 0.3, frameY - 1.3, -d / 2 + 0.1, "ラーメン ・ 餃子 ・ 炒飯", P.lacquer)
		for _, x in ipairs({ -w / 3, 0, w / 3 }) do
			pendant(m, x, frameY - 0.2, 0.35, 0.7)
		end
	end)

	-- Art & walls ---------------------------------------------------------------------------------
	Registry.register("noren_banner", function(m, item)
		Kit.finish(m, size(item))
		local w, h = item.size[1], item.size[2]
		high(Kit.cylH(m, 0.12, w + 0.2, 0, h - 0.12, 0, P.wood_dark, M.wood, nc()))
		for _, x in ipairs({ -w / 2 + 0.4, w / 2 - 0.4 }) do
			high(Kit.box(m, 0.06, 0.12, 0.06, x, h - 0.03, 0, P.black, M.metal, nc()))
		end
		banner(m, w, h - 0.18, 0.05, 0, "ラーメン ・ 餃子 ・ 炒飯", P.lacquer)
		-- round shop crest in the middle
		Kit.cylH(m, 0.9, 0.06, 0, h * 0.5, -0.06, P.white, M.fabric, nc(), "z")
		label(m, 0.7, 0.7, 0, h * 0.5, -0.1, "麺", "#B3262E")
	end)

	Registry.register("menu_posters", function(m, item)
		Kit.finish(m, size(item))
		local w, h, d = item.size[1], item.size[2], item.size[3]
		posterRow(m, -w / 2 + 0.1, w / 2 - 0.1, 0.1, h - 0.1, d / 2 - 0.06, 5)
	end)

	Registry.register("ramen_poster", function(m, item)
		Kit.finish(m, size(item))
		local w, h, d = item.size[1], item.size[2], item.size[3]
		local z = d / 2 - 0.04
		Kit.box(m, w, h, 0.05, 0, h / 2, z, P.cream, M.smooth, nc())
		Kit.box(m, w - 0.3, h - 0.3, 0.03, 0, h / 2, z - 0.04, P.lacquer, M.smooth, nc())
		label(m, w - 0.5, 0.7, 0, h - 0.6, z - 0.07, "ラーメン", "#FFF3E0")
		bowlArt(m, 0, h * 0.42, z - 0.07, 0.85)
		-- steam
		for k = -1, 1 do
			for j = 0, 2 do
				Kit.box(m, 0.05, 0.22, 0.02, k * 0.3 + (j % 2) * 0.06, h * 0.42 + 0.75 + j * 0.2, z - 0.07, P.white, M.smooth, { collide = false, shadow = false, rot = CFrame.Angles(0, 0, math.rad((j % 2 == 0) and 20 or -20)), transparency = 0.2 })
			end
		end
		Kit.cylH(m, 0.7, 0.03, w / 2 - 0.55, 0.6, z - 0.07, P.white, M.smooth, nc(), "z")
		label(m, 0.5, 0.5, w / 2 - 0.55, 0.6, z - 0.1, "開店", "#C0261E")
		label(m, w - 1.4, 0.35, -0.35, 0.55, z - 0.07, "since 1987", "#FFF3E0")
	end)

	Registry.register("ramen_sign_vertical", function(m, item)
		Kit.finish(m, size(item))
		local w, h, d = item.size[1], item.size[2], item.size[3]
		local z = d / 2 - 0.08
		Kit.box(m, w, h - 0.5, 0.15, 0, (h - 0.5) / 2, z, P.lacquer, M.smooth, nc())
		for _, x in ipairs({ -w / 2 + 0.12, w / 2 - 0.12 }) do
			Kit.box(m, 0.06, h - 0.8, 0.02, x, (h - 0.5) / 2, z - 0.085, P.cream, M.smooth, nc())
		end
		label(m, w - 0.4, h - 1.2, 0, (h - 0.5) / 2, z - 0.09, "ラ\nー\nメ\nン", "#FFFFFF")
		-- little tiled cap and a lamp arm lighting the sign
		Kit.wedge(m, w + 0.3, 0.35, 0.4, CFrame.new(0, h - 0.33, z - 0.05), P.tile, M.roof, nc())
		Kit.box(m, 0.08, 0.08, 0.6, 0, h - 0.1, z - 0.35, P.black, M.metal, nc())
		local head = Kit.box(m, 0.4, 0.2, 0.25, 0, h - 0.18, z - 0.65, P.charcoal, M.metal, nc())
		Kit.light(head, "Spot", P.lamp_warm, 8, 1.4, { face = Enum.NormalId.Bottom, angle = 70 })
	end)

	Registry.register("soup_sign", function(m, item)
		Kit.finish(m, size(item))
		local w, h, d = item.size[1], item.size[2], item.size[3]
		local z = d / 2 - 0.1
		Kit.box(m, w, h, 0.2, 0, h / 2, z, P.wood_dark, M.wood, nc())
		Kit.box(m, w - 0.4, h - 0.4, 0.04, 0, h / 2, z - 0.12, P.paper_warm, M.smooth, nc())
		label(m, w * 0.55, h * 0.55, w * 0.12, h * 0.48, z - 0.15, "秘伝スープ", "#C0261E")
		label(m, w * 0.22, h * 0.7, -w / 2 + w * 0.15, h / 2, z - 0.15, "当店\n自慢", "#2B2320")
		Kit.cylH(m, 0.8, 0.03, w / 2 - 0.65, h - 0.6, z - 0.15, P.lacquer, M.smooth, nc(), "z")
		label(m, 0.6, 0.6, w / 2 - 0.65, h - 0.6, z - 0.18, "極", "#FFFFFF")
		label(m, w * 0.5, h * 0.18, w * 0.12, 0.45, z - 0.15, "豚骨 ・ 鶏ガラ ・ 魚介", "#2B2320")
		-- two small spotlights above
		for _, x in ipairs({ -w / 4, w / 4 }) do
			Kit.box(m, 0.08, 0.08, 0.5, x, h - 0.05, z - 0.3, P.black, M.metal, nc())
			local head = Kit.cyl(m, 0.3, 0.3, x, h - 0.1, z - 0.55, P.charcoal, M.metal, nc())
			Kit.light(head, "Spot", P.lamp_warm, 8, 1.2, { face = Enum.NormalId.Bottom, angle = 80 })
		end
	end)

	-- On the table (top items) ------------------------------------------------------------------------
	Registry.register("water_pitcher", function(m, item)
		Kit.finish(m, size(item))
		pitcher(m, 0, 0, 0, 1)
		-- two stacked glasses beside it
		for k = 0, 1 do
			Kit.cyl(m, 0.26, 0.3, 0.3, 0.15 + k * 0.08, -0.25, P.glass, M.glass, { collide = false, shadow = false, transparency = 0.35 })
		end
	end)

	Registry.register("condiment_caddy", function(m, item)
		Kit.finish(m, size(item))
		Kit.box(m, 1.5, 0.08, 0.6, 0, 0.04, 0, P.steel, M.metal, { reflectance = 0.1 })
		-- chopstick holder with a bundle of waribashi
		Kit.cyl(m, 0.36, 0.6, -0.5, 0.38, 0, P.koi_orange, M.smooth, nc())
		for k = 0, 5 do
			local a = k * math.pi / 3
			Kit.box(m, 0.04, 0.9, 0.04, -0.5 + math.cos(a) * 0.08, 0.6, math.sin(a) * 0.08, P.hinoki, M.wood, { collide = false, shadow = false, rot = CFrame.Angles(math.sin(a) * 0.06, 0, -math.cos(a) * 0.06) })
		end
		-- jars with red lids: garlic, chili oil
		for i, c in ipairs({ P.cream, P.vermilion }) do
			local x = -0.1 + (i - 1) * 0.32
			Kit.cyl(m, 0.28, 0.32, x, 0.24, 0.08, P.glass, M.glass, { collide = false, shadow = false, transparency = 0.3 })
			Kit.cyl(m, 0.24, 0.2, x, 0.19, 0.08, c, M.sand, nc())
			Kit.cyl(m, 0.3, 0.08, x, 0.44, 0.08, P.red, M.smooth, nc())
		end
		-- pepper can and tissue box
		Kit.cyl(m, 0.22, 0.45, 0.58, 0.31, 0.12, P.navy, M.metal, nc())
		Kit.cyl(m, 0.23, 0.05, 0.58, 0.55, 0.12, P.metal, M.metal, nc())
		Kit.box(m, 0.36, 0.28, 0.26, 0.5, 0.22, -0.16, P.white, M.smooth, nc())
		Kit.box(m, 0.14, 0.1, 0.12, 0.5, 0.4, -0.16, P.white, M.fabric, nc())
	end)

	Registry.register("counter_posters", function(m, item)
		Kit.finish(m, size(item))
		local w, h, d = item.size[1], item.size[2], item.size[3]
		-- stainless pass shelf: front panel with menu posters, top shelf with pitchers
		Kit.box(m, w, h - 0.1, 0.06, 0, (h - 0.1) / 2, -d / 2 + 0.03, P.steel_dark, M.metal)
		Kit.box(m, w, 0.08, d, 0, h - 0.04, 0, P.metal, M.metal, { reflectance = 0.2 })
		for _, x in ipairs({ -w / 2 + 0.05, w / 2 - 0.05 }) do
			Kit.box(m, 0.08, h - 0.1, d - 0.06, x, (h - 0.1) / 2, 0.03, P.steel, M.metal, nc())
		end
		posterRow(m, -w / 2 + 0.1, w / 2 - 0.1, 0.12, h - 0.18, -d / 2 - 0.01, 5)
		pitcher(m, -w / 2 + 0.6, h, 0, 0.7)
		pitcher(m, w / 2 - 0.6, h, 0, 0.7)
	end)

	-- Seating -------------------------------------------------------------------------------------
	Registry.register("stool_red", function(m, item)
		local root = Kit.finish(m, size(item))
		local h = item.size[2]
		Kit.cyl(m, 1.3, 0.1, 0, 0.05, 0, P.black, M.metal)
		Kit.cyl(m, 0.24, h - 0.5, 0, (h - 0.5) / 2 + 0.05, 0, P.black, M.metal, { reflectance = 0.1 })
		Kit.cyl(m, 1.0, 0.06, 0, 0.95, 0, P.black, M.metal, nc())
		Kit.cyl(m, 1.1, 0.1, 0, h - 0.5, 0, P.charcoal, M.metal, nc())
		Kit.cyl(m, 1.55, 0.4, 0, h - 0.22, 0, P.lacquer, M.smooth, { reflectance = 0.08 })
		Kit.blob(m, 1.5, 0.22, 1.5, 0, h - 0.02, 0, P.lacquer, M.smooth, { collide = false, reflectance = 0.08 })
		Kit.cyl(m, 1.58, 0.05, 0, h - 0.4, 0, P.lacquer_dark, M.smooth, nc())
		point(root, "SitPoint", 0, h, 0, 0)
	end)

	-- Wooden table with two benches (works like a booth: four seats with their own dish spots)
	Registry.register("bench_table", function(m, item)
		local root = Kit.finish(m, size(item))
		local w = item.size[1]
		-- trestle table
		Kit.box(m, w - 0.6, 0.2, 2, 0, 2.6, 0, P.wood, M.wood)
		Kit.box(m, w - 0.5, 0.06, 2.1, 0, 2.48, 0, P.wood_dark, M.wood, nc())
		for _, x in ipairs({ -w / 2 + 0.9, w / 2 - 0.9 }) do
			Kit.box(m, 0.3, 2.4, 0.3, x, 1.3, 0, P.wood_dark, M.wood)
			Kit.box(m, 0.3, 0.2, 1.6, x, 0.1, 0, P.wood_dark, M.wood)
			Kit.box(m, 0.25, 0.2, 1.6, x, 2.38, 0, P.wood_dark, M.wood, nc())
		end
		Kit.box(m, w - 1.8, 0.2, 0.2, 0, 0.9, 0, P.wood_dark, M.wood, nc())
		-- benches
		local df = Kit.detail(m, "furnish")
		for side = -1, 1, 2 do
			local z = side * 1.85
			Kit.box(m, w - 0.4, 0.2, 1.0, 0, 1.8, z, P.wood, M.wood)
			for _, x in ipairs({ -w / 2 + 0.6, w / 2 - 0.6 }) do
				Kit.box(m, 0.25, 1.7, 0.8, x, 0.85, z, P.wood_dark, M.wood)
			end
			Kit.box(m, w - 1.4, 0.15, 0.15, 0, 0.6, z, P.wood_dark, M.wood, nc())
			for _, x in ipairs({ -1.2, 1.2 }) do
				Kit.box(df, 1.3, 0.12, 0.85, x, 1.96, z, side < 0 and P.indigo or P.lacquer, M.fabric, nc())
			end
		end
		local dt = Kit.detail(m, "tableware")
		pitcher(dt, -0.4, 2.7, 0, 0.6)
		Kit.box(dt, 0.8, 0.06, 0.4, 0.4, 2.73, 0, P.steel, M.metal, nc())
		Kit.cyl(dt, 0.24, 0.45, 0.2, 2.95, 0, P.koi_orange, M.smooth, nc())
		Kit.cyl(dt, 0.2, 0.3, 0.55, 2.9, 0, P.red, M.smooth, nc())
		local i = 0
		for side = -1, 1, 2 do
			for _, x in ipairs({ -1.2, 1.2 }) do
				i += 1
				point(root, "Seat" .. i, x, 1.9, side * 1.85, side < 0 and 180 or 0)
				point(root, "Dish" .. i, x, 2.7, side * 0.55, 0)
			end
		end
		root:SetAttribute("TopY", 2.7)
	end)
end
