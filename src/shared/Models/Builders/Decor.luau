--!nonstrict
-- Decorations: lighting, plants, art, statues, garden, festival, seasonal and city items.
-- Parts with the attribute "Animate" are animated by the client (AmbientController).
local Kit = require(script.Parent.Parent.Kit)
local P = require(script.Parent.Parent.Palette)
local M = P.M

local function size(item)
	return Vector3.new(item.size[1], item.size[2], item.size[3])
end

local JP_FONT = Font.new("rbxasset://fonts/families/FredokaOne.json", Enum.FontWeight.Bold)

-- Paper lantern hanging from the top of its box
local function chochin(m, item, bodyColor, text, textColor, scale)
	Kit.finish(m, size(item))
	local h = item.size[2]
	scale = scale or 1
	local bodyH, bodyD = 1.5 * scale, 1.15 * scale
	local cy = h - 0.6 - bodyH / 2
	Kit.cyl(m, 0.05, 0.6, 0, h - 0.3, 0, P.black, M.fabric, { collide = false })
	Kit.cyl(m, 0.7 * scale, 0.18, 0, cy + bodyH / 2 + 0.05, 0, P.black, M.smooth, { collide = false })
	Kit.cyl(m, 0.7 * scale, 0.18, 0, cy - bodyH / 2 - 0.05, 0, P.black, M.smooth, { collide = false })
	local body = Kit.blob(m, bodyD, bodyH, bodyD, 0, cy, 0, bodyColor, M.fabric, { collide = false })
	body.Material = M.smooth
	for i = -2, 2 do
		local yy = cy + i * bodyH * 0.18
		local ring = 1 - (i * 0.18) ^ 2 * 1.2
		Kit.cyl(m, bodyD * ring + 0.02, 0.03, 0, yy, 0, Color3.new(0, 0, 0):Lerp(bodyColor, 0.6), M.smooth, { collide = false, shadow = false })
	end
	if text then
		local panel = Kit.box(m, bodyD * 0.55, bodyH * 0.8, 0.02, 0, cy, -bodyD / 2 - 0.01, P.white, M.smooth, { transparency = 1, collide = false, shadow = false })
		Kit.text(panel, Enum.NormalId.Front, text, { color = textColor or "#141414", font = JP_FONT, pps = 40 })
	end
	Kit.light(body, "Point", P.lamp_warm, 12 * scale, 1.2)
	body:SetAttribute("Animate", "sway")
	return body
end

local function plantPot(m, d, h, color)
	Kit.cyl(m, d, h, 0, h / 2, 0, color or P.charcoal, M.smooth)
	Kit.cyl(m, d + 0.1, 0.1, 0, h - 0.05, 0, color or P.charcoal, M.smooth, { collide = false })
	Kit.cyl(m, d - 0.15, 0.05, 0, h - 0.04, 0, P.wood_dark, M.sand, { collide = false })
end

local function foliage(m, list, color, material)
	for _, b in ipairs(list) do
		Kit.blob(m, b[4], b[5] or b[4] * 0.6, b[6] or b[4], b[1], b[2], b[3], color, material or M.leafy, { collide = false })
	end
end

local function tree(m, item, leafColor, petals)
	Kit.finish(m, size(item))
	local w, h = item.size[1], item.size[2]
	Kit.cyl(m, 0.9, h * 0.5, 0, h * 0.25, 0, P.wood_dark, M.wood)
	Kit.cyl(m, 0.5, h * 0.35, -0.8, h * 0.55, 0.2, P.wood_dark, M.wood, { rot = CFrame.Angles(0, 0, math.rad(30)) })
	Kit.cyl(m, 0.5, h * 0.35, 0.9, h * 0.55, -0.3, P.wood_dark, M.wood, { rot = CFrame.Angles(0, 0, math.rad(-35)) })
	local blobs = {
		{ 0, h * 0.78, 0, w * 0.55 }, { -w * 0.28, h * 0.68, 0.4, w * 0.42 }, { w * 0.3, h * 0.7, -0.3, w * 0.45 },
		{ 0.3, h * 0.88, -0.6, w * 0.4 }, { -0.4, h * 0.62, -w * 0.25, w * 0.35 }, { 0.5, h * 0.6, w * 0.25, w * 0.35 },
	}
	foliage(m, blobs, leafColor, M.leafy)
	if petals then
		local emitter = Kit.box(m, w * 0.6, 0.2, w * 0.6, 0, h * 0.7, 0, P.white, M.smooth, { transparency = 1, collide = false, shadow = false })
		Kit.particles(emitter, "petals")
	end
	Kit.cyl(m, 2, 0.15, 0, 0.075, 0, P.wood_dark, M.ground or M.sand, { collide = false })
end

local function stoneLantern(m, item, stoneColor, roofColor, glowColor)
	Kit.finish(m, size(item))
	local h = item.size[2]
	local s = h / 4.5
	Kit.cyl(m, 1.6 * s, 0.4 * s, 0, 0.2 * s, 0, stoneColor, M.granite)
	Kit.cyl(m, 0.6 * s, 1.6 * s, 0, 1.2 * s, 0, stoneColor, M.granite)
	Kit.box(m, 1.4 * s, 0.25 * s, 1.4 * s, 0, 2.1 * s, 0, stoneColor, M.granite)
	local light = Kit.box(m, 0.9 * s, 0.9 * s, 0.9 * s, 0, 2.7 * s, 0, glowColor or P.paper_warm, M.neon, { collide = false })
	Kit.box(m, 1.05 * s, 0.95 * s, 0.3 * s, 0, 2.7 * s, 0, stoneColor, M.granite)
	Kit.box(m, 0.3 * s, 0.95 * s, 1.05 * s, 0, 2.7 * s, 0, stoneColor, M.granite)
	Kit.light(light, "Point", P.lamp_warm, 10, 1)
	-- roof: four wedges forming a shallow pyramid
	local ry = 3.35 * s
	for i = 0, 3 do
		local rot = CFrame.Angles(0, math.rad(90 * i), 0)
		Kit.wedge(m, 1.9 * s, 0.5 * s, 0.95 * s, CFrame.new(0, ry, 0) * rot * CFrame.new(0, 0, -0.475 * s), roofColor or stoneColor, M.granite)
	end
	Kit.ball(m, 0.4 * s, 0, ry + 0.45 * s, 0, roofColor or stoneColor, M.granite)
end

local function neon(m, item, text, color)
	Kit.finish(m, size(item))
	local w, h, d = item.size[1], item.size[2], item.size[3]
	local board = Kit.box(m, w, h, 0.15, 0, h / 2, d / 2 - 0.075, P.charcoal, M.smooth)
	local face = Kit.box(m, w - 0.2, h - 0.2, 0.05, 0, h / 2, d / 2 - 0.18, P.charcoal, M.smooth, { collide = false })
	Kit.text(face, Enum.NormalId.Front, text, { color = color, glow = true, font = JP_FONT, pps = 40 })
	Kit.light(face, "Surface", color, 10, 1.5, { face = Enum.NormalId.Front, angle = 120 })
	for _, x in ipairs({ -w / 2 + 0.05, w / 2 - 0.05 }) do
		Kit.box(m, 0.06, h - 0.1, 0.06, x, h / 2, d / 2 - 0.2, color, M.neon, { collide = false })
	end
	local _ = board
end

local function noren(m, item, color, text, textColor)
	Kit.finish(m, size(item))
	local w, h, d = item.size[1], item.size[2], item.size[3]
	Kit.cylH(m, 0.15, w + 0.3, 0, h - 0.1, d / 2 - 0.1, P.wood_dark, M.wood, { collide = false })
	local panels = 3
	local pw = w / panels
	for i = 0, panels - 1 do
		local x = -w / 2 + pw * (i + 0.5)
		local cloth = Kit.box(m, pw - 0.08, h - 0.25, 0.05, x, (h - 0.25) / 2 + 0.05, d / 2 - 0.12, color, M.fabric, { collide = false })
		cloth:SetAttribute("Animate", "sway")
	end
	if text then
		local panel = Kit.box(m, w - 0.2, h * 0.5, 0.02, 0, h * 0.55, d / 2 - 0.16, P.white, M.smooth, { transparency = 1, collide = false, shadow = false })
		Kit.text(panel, Enum.NormalId.Front, text, { color = textColor or "#FFFFFF", font = JP_FONT, pps = 40 })
	end
end

local function frame(m, w, h, d, color)
	for _, s in ipairs({ { 0, h - 0.1, w, 0.2 }, { 0, 0.1, w, 0.2 } }) do
		Kit.box(m, s[3], s[4], d, s[1], s[2], 0, color, M.wood, { collide = false })
	end
	for _, x in ipairs({ -w / 2 + 0.1, w / 2 - 0.1 }) do
		Kit.box(m, 0.2, h, d, x, h / 2, 0, color, M.wood, { collide = false })
	end
end

local function torii(m, item, color, capColor)
	Kit.finish(m, size(item))
	local w, h = item.size[1], item.size[2]
	for _, x in ipairs({ -w / 2 + 0.9, w / 2 - 0.9 }) do
		Kit.cyl(m, 0.7, h - 0.8, x, (h - 0.8) / 2, 0, color, M.smooth)
		Kit.cyl(m, 0.85, 0.5, x, 0.25, 0, capColor, M.smooth)
	end
	Kit.box(m, w - 0.8, 0.4, 0.5, 0, h - 2.2, 0, color, M.smooth)
	Kit.box(m, w + 0.4, 0.45, 0.8, 0, h - 0.7, 0, color, M.smooth)
	Kit.box(m, w + 0.8, 0.3, 0.9, 0, h - 0.3, 0, capColor, M.smooth)
	for _, sgn in ipairs({ -1, 1 }) do
		Kit.wedge(m, 0.9, 0.35, 0.6, CFrame.new(sgn * (w / 2 + 0.55), h - 0.25, 0) * CFrame.Angles(0, math.rad(sgn * 90), 0), capColor, M.smooth)
	end
	Kit.box(m, 0.4, 1.2, 0.3, 0, h - 1.45, 0, color, M.smooth)
end

local function shisa(m, x, color, mouthOpen)
	Kit.box(m, 1.6, 0.5, 1.4, x, 0.25, 0, P.stone, M.granite)
	Kit.blob(m, 1.2, 1.2, 1.1, x, 1.05, 0.1, color, M.granite)
	Kit.ball(m, 0.9, x, 1.9, -0.15, color, M.granite)
	Kit.blob(m, 1.2, 0.5, 0.4, x, 2.2, 0.1, P.wood, M.granite, { collide = false })
	for _, ex in ipairs({ -0.22, 0.22 }) do
		Kit.ball(m, 0.18, x + ex, 2.0, -0.55, P.white, M.smooth, { collide = false })
		Kit.ball(m, 0.08, x + ex, 2.0, -0.63, P.black, M.smooth, { collide = false })
	end
	Kit.box(m, 0.5, mouthOpen and 0.25 or 0.08, 0.1, x, 1.7, -0.6, P.lacquer_dark, M.smooth, { collide = false })
end

return function(Registry)
	-- Lighting --------------------------------------------------------------------------------
	Registry.register("chochin_red", function(m, item)
		chochin(m, item, P.lacquer, "ラーメン", "#141414")
	end)
	Registry.register("chochin_white", function(m, item)
		chochin(m, item, P.paper, "寿司", "#B3262E")
	end)
	Registry.register("fireworks_lantern", function(m, item)
		chochin(m, item, P.neon_blue, "花火", "#FFFFFF")
	end)
	Registry.register("andon_lamp", function(m, item)
		Kit.finish(m, size(item))
		local h = item.size[2]
		for _, c in ipairs({ { -1, -1 }, { 1, -1 }, { 1, 1 }, { -1, 1 } }) do
			Kit.box(m, 0.12, h, 0.12, c[1] * 0.6, h / 2, c[2] * 0.6, P.wood_black, M.wood)
		end
		local paper = Kit.box(m, 1.1, h - 0.9, 1.1, 0, (h - 0.9) / 2 + 0.6, 0, P.paper_warm, M.neon, { collide = false })
		paper.Transparency = 0.1
		for i = 0, 3 do
			Kit.box(m, 1.25, 0.08, 1.25, 0, 0.6 + i * (h - 0.9) / 3, 0, P.wood_black, M.wood, { collide = false })
		end
		Kit.light(paper, "Point", P.lamp_warm, 12, 1)
	end)
	Registry.register("paper_pendant", function(m, item)
		Kit.finish(m, size(item))
		local h = item.size[2]
		Kit.cyl(m, 0.05, 0.8, 0, h - 0.4, 0, P.black, M.fabric, { collide = false })
		local globe = Kit.ball(m, 1.7, 0, h - 1.65, 0, P.paper, M.neon, { collide = false })
		globe.Transparency = 0.05
		for i = -1, 1 do
			Kit.cyl(m, 1.7 - math.abs(i) * 0.5, 0.03, 0, h - 1.65 + i * 0.5, 0, P.paper_warm, M.smooth, { collide = false })
		end
		Kit.light(globe, "Point", P.lamp_warm, 14, 1.1)
		globe:SetAttribute("Animate", "sway")
	end)
	Registry.register("toro_stone", function(m, item)
		stoneLantern(m, item, P.stone, P.stone_dark)
	end)
	Registry.register("kyoto_lantern", function(m, item)
		stoneLantern(m, item, P.stone_light, P.moss, P.lamp)
	end)
	Registry.register("snow_lantern", function(m, item)
		stoneLantern(m, item, P.stone, P.white, P.paper_warm)
	end)
	Registry.register("neon_ramen", function(m, item)
		neon(m, item, "ラーメン", P.neon_red)
	end)
	Registry.register("neon_sushi", function(m, item)
		neon(m, item, "寿司", P.neon_blue)
	end)
	local function lanternString(m, item, colors, scale)
		Kit.finish(m, size(item))
		local w, h = item.size[1], item.size[2]
		Kit.cylH(m, 0.05, w, 0, h - 0.1, 0, P.black, M.fabric, { collide = false })
		local n = 5
		for i = 0, n - 1 do
			local x = -w / 2 + 0.6 + (w - 1.2) * i / (n - 1)
			local sag = 0.4 * math.sin(math.pi * i / (n - 1))
			local c = colors[i % #colors + 1]
			local b = Kit.blob(m, 0.7 * scale, 1 * scale, 0.7 * scale, x, h - 0.75 * scale - sag, 0, c, M.smooth, { collide = false })
			Kit.cyl(m, 0.45 * scale, 0.1, x, h - 0.2 * scale - sag, 0, P.black, M.smooth, { collide = false })
			b:SetAttribute("Animate", "sway")
			if i % 2 == 0 then
				Kit.light(b, "Point", P.lamp_warm, 9, 0.8)
			end
		end
	end
	Registry.register("lantern_string", function(m, item)
		lanternString(m, item, { P.lacquer, P.paper }, 1)
	end)
	Registry.register("yatai_lanterns", function(m, item)
		lanternString(m, item, { P.lacquer, P.lacquer, P.gold }, 1.4)
	end)

	-- Plants ------------------------------------------------------------------------------------
	Registry.register("bamboo_pot", function(m, item)
		Kit.finish(m, size(item))
		local h = item.size[2]
		plantPot(m, 1.4, 1.1, P.charcoal)
		for i, c in ipairs({ { -0.3, -0.2 }, { 0.25, -0.25 }, { 0, 0.3 }, { 0.35, 0.2 }, { -0.35, 0.25 } }) do
			local sh = h - 1.2 - (i % 3) * 0.4
			Kit.cyl(m, 0.16, sh, c[1], 1.1 + sh / 2, c[2], P.bamboo_green, M.wood)
			for k = 1, 3 do
				Kit.cyl(m, 0.19, 0.06, c[1], 1.1 + sh * k / 4, c[2], P.leaf_dark, M.wood, { collide = false })
			end
			Kit.box(m, 0.6, 0.04, 0.18, c[1] + 0.3, 1.1 + sh - 0.1, c[2], P.leaf, M.leafy, { collide = false, rot = CFrame.Angles(0, math.rad(i * 70), math.rad(-25)) })
			Kit.box(m, 0.6, 0.04, 0.18, c[1] - 0.3, 1.1 + sh - 0.4, c[2], P.leaf_light, M.leafy, { collide = false, rot = CFrame.Angles(0, math.rad(i * 40), math.rad(25)) })
		end
	end)
	Registry.register("kokedama", function(m, item)
		Kit.finish(m, size(item))
		local h = item.size[2]
		Kit.cyl(m, 0.04, 1.2, 0, h - 0.6, 0, P.wood, M.fabric, { collide = false })
		local ball = Kit.ball(m, 0.9, 0, h - 1.6, 0, P.moss, M.leafy, { collide = false })
		ball:SetAttribute("Animate", "sway")
		foliage(m, { { 0, h - 1.05, 0, 0.6, 0.4 }, { 0.25, h - 1.0, 0.1, 0.4, 0.3 } }, P.leaf_light)
	end)
	local function bonsai(m, item, scale, pot)
		Kit.finish(m, size(item))
		local s = scale
		Kit.box(m, 1.6 * s, 0.35 * s, 1.0 * s, 0, 0.175 * s, 0, pot or P.indigo, M.smooth)
		Kit.box(m, 1.5 * s, 0.05, 0.9 * s, 0, 0.36 * s, 0, P.moss, M.leafy, { collide = false })
		Kit.cyl(m, 0.22 * s, 0.7 * s, -0.1 * s, 0.7 * s, 0, P.wood_dark, M.wood, { rot = CFrame.Angles(0, 0, math.rad(-20)) })
		Kit.cyl(m, 0.16 * s, 0.6 * s, 0.2 * s, 1.05 * s, 0, P.wood_dark, M.wood, { rot = CFrame.Angles(0, 0, math.rad(45)) })
		foliage(m, {
			{ -0.35 * s, 1.15 * s, 0, 0.8 * s, 0.3 * s }, { 0.45 * s, 1.3 * s, 0.05 * s, 0.7 * s, 0.25 * s },
			{ 0.05 * s, 1.45 * s, -0.05 * s, 0.6 * s, 0.25 * s },
		}, P.leaf_dark)
	end
	Registry.register("bonsai_pine", function(m, item)
		bonsai(m, item, 1)
	end)
	Registry.register("bonsai_ancient", function(m, item)
		Kit.finish(m, size(item))
		Kit.box(m, 2.6, 1.2, 2.2, 0, 0.6, 0, P.wood_black, M.wood)
		local sub = Kit.model("b")
		sub.Parent = m
		local fake = { size = { 2.6, 2.6, 2.2 } }
		bonsai(sub, fake, 1.6, P.lacquer_dark)
		sub.PrimaryPart:Destroy()
		for _, d in ipairs(sub:GetDescendants()) do
			if d:IsA("BasePart") then
				d.CFrame = CFrame.new(0, 1.2, 0) * d.CFrame
			end
		end
	end)
	Registry.register("ikebana", function(m, item)
		Kit.finish(m, size(item))
		Kit.cyl(m, 0.6, 0.7, 0, 0.35, 0, P.ink, M.smooth)
		Kit.cyl(m, 0.05, 1.1, -0.1, 1.2, 0, P.leaf, M.wood, { collide = false, rot = CFrame.Angles(0, 0, math.rad(15)) })
		Kit.cyl(m, 0.05, 0.9, 0.15, 1.1, 0.05, P.leaf, M.wood, { collide = false, rot = CFrame.Angles(0, 0, math.rad(-20)) })
		Kit.ball(m, 0.3, -0.25, 1.7, 0, P.sakura, M.smooth, { collide = false })
		Kit.ball(m, 0.25, 0.32, 1.5, 0.05, P.lacquer, M.smooth, { collide = false })
		Kit.ball(m, 0.2, 0, 1.35, -0.15, P.white, M.smooth, { collide = false })
	end)
	Registry.register("maple_tree", function(m, item)
		tree(m, item, P.maple, false)
	end)
	Registry.register("sakura_tree", function(m, item)
		tree(m, item, P.sakura, true)
	end)

	-- Art & walls --------------------------------------------------------------------------------
	Registry.register("noren_red", function(m, item)
		noren(m, item, P.lacquer, "ラーメン", "#FFFFFF")
	end)
	Registry.register("noren_indigo", function(m, item)
		noren(m, item, P.indigo, "寿司", "#FFFFFF")
	end)
	Registry.register("menu_plaques", function(m, item)
		Kit.finish(m, size(item))
		local w, h, d = item.size[1], item.size[2], item.size[3]
		Kit.box(m, w, 0.15, d, 0, h - 0.1, 0, P.wood_dark, M.wood, { collide = false })
		local words = { "醤油", "塩", "味噌", "鮭", "鮪", "茶" }
		for i, word in ipairs(words) do
			local x = -w / 2 + w / #words * (i - 0.5)
			local tag = Kit.box(m, w / #words - 0.1, h - 0.35, 0.08, x, (h - 0.35) / 2, d / 2 - 0.1, P.hinoki, M.wood, { collide = false })
			Kit.text(tag, Enum.NormalId.Front, word, { color = "#2B2320", font = JP_FONT, pps = 40 })
		end
	end)
	Registry.register("fan_wall", function(m, item)
		Kit.finish(m, size(item))
		local w, h, d = item.size[1], item.size[2], item.size[3]
		local cx, cy = 0, 0.2
		for i = 0, 8 do
			local a = math.rad(-80 + i * 20)
			local len = h - 0.3
			local cf = CFrame.new(cx, cy, d / 2 - 0.1) * CFrame.Angles(0, 0, a) * CFrame.new(0, len / 2, 0)
			Kit.part(m, Vector3.new(w / 6, len, 0.04), cf, (i % 2 == 0) and P.lacquer or P.gold, M.fabric, { collide = false })
		end
		Kit.ball(m, 0.25, cx, cy, d / 2 - 0.05, P.wood_black, M.smooth, { collide = false })
	end)
	Registry.register("kakejiku", function(m, item)
		Kit.finish(m, size(item))
		local w, h, d = item.size[1], item.size[2], item.size[3]
		local paper = Kit.box(m, w - 0.2, h - 0.7, 0.04, 0, h / 2, d / 2 - 0.1, P.paper, M.fabric, { collide = false })
		Kit.box(m, w, h - 0.4, 0.03, 0, h / 2, d / 2 - 0.07, P.indigo, M.fabric, { collide = false })
		Kit.text(paper, Enum.NormalId.Front, "和", { color = "#141414", font = JP_FONT, pps = 30 })
		Kit.cylH(m, 0.12, w + 0.2, 0, h - 0.15, d / 2 - 0.1, P.wood_dark, M.wood, { collide = false })
		Kit.cylH(m, 0.16, w + 0.4, 0, 0.15, d / 2 - 0.1, P.wood_black, M.wood, { collide = false })
	end)
	Registry.register("wagasa", function(m, item)
		Kit.finish(m, size(item))
		local w, h = item.size[1], item.size[2]
		Kit.cyl(m, 0.8, 0.3, 0, 0.15, 0, P.wood_black, M.wood)
		Kit.cyl(m, 0.12, h - 0.4, 0, (h - 0.4) / 2 + 0.3, 0, P.wood_dark, M.wood)
		local canopy = Kit.cyl(m, w, 0.12, 0, h - 0.5, 0, P.lacquer, M.fabric, { collide = false })
		local _ = canopy
		Kit.cyl(m, w * 0.6, 0.2, 0, h - 0.35, 0, P.lacquer, M.fabric, { collide = false })
		Kit.ball(m, 0.3, 0, h - 0.15, 0, P.wood_black, M.smooth, { collide = false })
		for i = 0, 7 do
			local a = math.rad(i * 45)
			local cf = CFrame.new(0, h - 0.55, 0) * CFrame.Angles(0, a, 0) * CFrame.new(w / 4, -0.02, 0)
			Kit.part(m, Vector3.new(w / 2, 0.03, 0.06), cf, P.gold, M.wood, { collide = false })
		end
	end)
	Registry.register("wave_painting", function(m, item)
		Kit.finish(m, size(item))
		local w, h, d = item.size[1], item.size[2], item.size[3]
		local z = d / 2 - 0.08
		Kit.box(m, w - 0.3, h - 0.3, 0.04, 0, h / 2, z, P.paper_warm, M.fabric, { collide = false })
		local bands = { P.navy, P.indigo, P.water_dark, P.water }
		for i, c in ipairs(bands) do
			local bh = (h - 0.6) * 0.5 / #bands
			Kit.box(m, w - 0.5, bh, 0.03, 0, 0.3 + bh * (i - 0.5), z - 0.02, c, M.fabric, { collide = false })
		end
		for i = 0, 5 do
			Kit.blob(m, 0.6, 0.35, 0.02, -w / 2 + 0.6 + i * (w - 1.2) / 5, 0.3 + (h - 0.6) * 0.5 + 0.05 * (i % 2), z - 0.04, P.white, M.smooth, { collide = false })
		end
		Kit.ball(m, 0.6, w / 2 - 0.9, h - 0.8, z - 0.03, P.lacquer, M.smooth, { collide = false })
		frame(m, w, h, 0.2, P.wood_black)
	end)
	Registry.register("byobu", function(m, item)
		Kit.finish(m, size(item))
		local w, h = item.size[1], item.size[2]
		local n = 6
		local pw = w / n
		for i = 0, n - 1 do
			local x = -w / 2 + pw * (i + 0.5)
			local z = (i % 2 == 0) and -0.15 or 0.15
			local yaw = (i % 2 == 0) and 12 or -12
			local cf = CFrame.new(x, h / 2, z) * CFrame.Angles(0, math.rad(yaw), 0)
			Kit.part(m, Vector3.new(pw - 0.04, h, 0.1), cf, P.gold, M.foil)
			Kit.part(m, Vector3.new(pw + 0.02, 0.15, 0.14), cf * CFrame.new(0, h / 2 - 0.07, 0), P.wood_black, M.wood, { collide = false })
			Kit.part(m, Vector3.new(pw + 0.02, 0.15, 0.14), cf * CFrame.new(0, -h / 2 + 0.07, 0), P.wood_black, M.wood, { collide = false })
			Kit.blob(m, pw * 0.8, 0.6, 0.05, x, h * 0.62 + (i % 3) * 0.2, z - 0.08, P.leaf_dark, M.smooth, { collide = false })
		end
	end)
	Registry.register("kimono_display", function(m, item)
		Kit.finish(m, size(item))
		local w, h = item.size[1], item.size[2]
		Kit.box(m, w * 0.6, 0.3, 0.8, 0, 0.15, 0, P.wood_black, M.wood)
		Kit.box(m, 0.15, h - 0.4, 0.15, 0, h / 2, 0.2, P.wood_black, M.wood)
		Kit.cylH(m, 0.12, w, 0, h - 0.6, 0.1, P.wood_black, M.wood, { collide = false })
		Kit.box(m, 1.6, h - 1.8, 0.25, 0, (h - 1.8) / 2 + 0.6, 0, P.lacquer, M.fabric)
		Kit.box(m, w - 0.2, 1.4, 0.2, 0, h - 1.4, 0, P.lacquer, M.fabric, { collide = false })
		Kit.box(m, 1.65, 0.5, 0.3, 0, h - 2.6, 0, P.gold, M.fabric, { collide = false })
		for i = 0, 4 do
			Kit.ball(m, 0.35, -0.6 + i * 0.3, 1.2 + (i % 2) * 0.9, -0.14, P.sakura, M.fabric, { collide = false })
		end
	end)

	-- Statues & objects ------------------------------------------------------------------------
	local function maneki(m, item, body, accent)
		Kit.finish(m, size(item))
		local s = item.size[2] / 1.3
		Kit.blob(m, 0.75 * s, 0.7 * s, 0.6 * s, 0, 0.35 * s, 0, body, M.smooth)
		Kit.ball(m, 0.62 * s, 0, 0.95 * s, -0.02 * s, body, M.smooth, { collide = false })
		for _, x in ipairs({ -0.2, 0.2 }) do
			Kit.wedge(m, 0.05, 0.22 * s, 0.18 * s, CFrame.new(x * s, 1.27 * s, 0) * CFrame.Angles(0, math.rad(90), 0), body, M.smooth, { collide = false })
			Kit.ball(m, 0.08 * s, x * 0.6 * s, 1.0 * s, -0.3 * s, P.black, M.smooth, { collide = false })
		end
		Kit.cyl(m, 0.55 * s, 0.06 * s, 0, 0.68 * s, 0, P.lacquer, M.smooth, { collide = false })
		Kit.ball(m, 0.12 * s, 0, 0.64 * s, -0.27 * s, accent, M.metal, { collide = false })
		Kit.cyl(m, 0.3 * s, 0.05, 0.15 * s, 0.35 * s, -0.31 * s, accent, M.metal, { collide = false, rot = CFrame.Angles(math.rad(90), 0, 0) })
		local paw = Kit.blob(m, 0.18 * s, 0.4 * s, 0.18 * s, -0.33 * s, 1.0 * s, -0.12 * s, body, M.smooth, { collide = false, name = "Paw" })
		paw:SetAttribute("Animate", "paw")
	end
	Registry.register("maneki_neko", function(m, item)
		maneki(m, item, P.white, P.gold)
	end)
	Registry.register("maneki_gold", function(m, item)
		maneki(m, item, P.gold, P.lacquer)
		for _, d in ipairs(m:GetDescendants()) do
			if d:IsA("BasePart") and d.Color == P.gold then
				d.Material = M.foil
			end
		end
	end)
	Registry.register("daruma", function(m, item)
		Kit.finish(m, size(item))
		Kit.blob(m, 1, 1.1, 0.95, 0, 0.55, 0, P.lacquer, M.smooth)
		Kit.blob(m, 0.6, 0.5, 0.1, 0, 0.62, -0.42, P.porcelain, M.smooth, { collide = false })
		Kit.ball(m, 0.14, -0.13, 0.68, -0.47, P.black, M.smooth, { collide = false })
		Kit.ball(m, 0.14, 0.13, 0.68, -0.47, P.white, M.smooth, { collide = false })
		Kit.box(m, 0.4, 0.15, 0.02, 0, 0.3, -0.47, P.gold, M.smooth, { collide = false })
	end)
	Registry.register("soy_barrel", function(m, item)
		Kit.finish(m, size(item))
		local w, h = item.size[1], item.size[2]
		local body = Kit.cyl(m, w - 0.1, h - 0.2, 0, (h - 0.2) / 2, 0, P.wood, M.wood)
		Kit.cyl(m, w - 0.2, 0.2, 0, h - 0.1, 0, P.paper_warm, M.fabric, { collide = false })
		for _, y in ipairs({ 0.4, h / 2, h - 0.5 }) do
			Kit.cyl(m, w + 0.02, 0.12, 0, y, 0, P.bamboo, M.fabric, { collide = false })
		end
		local label = Kit.box(m, 0.9, 1.1, 0.02, 0, h / 2, -w / 2 + 0.02, P.white, M.smooth, { collide = false })
		Kit.text(label, Enum.NormalId.Front, "醤油", { color = "#141414", font = JP_FONT, bg = "#F4EBDD" })
		local _ = body
	end)
	Registry.register("tanuki", function(m, item)
		Kit.finish(m, size(item))
		Kit.blob(m, 1.5, 1.6, 1.3, 0, 0.8, 0, P.wood, M.smooth)
		Kit.blob(m, 1.0, 1.0, 0.4, 0, 0.75, -0.5, P.sand, M.smooth, { collide = false })
		Kit.ball(m, 1.1, 0, 1.95, 0, P.wood, M.smooth)
		Kit.cyl(m, 1.4, 0.12, 0, 2.5, 0, P.bamboo, M.fabric, { collide = false })
		Kit.ball(m, 0.6, 0, 2.6, 0, P.bamboo, M.fabric, { collide = false })
		Kit.blob(m, 0.7, 0.3, 0.2, 0, 1.95, -0.5, P.sand, M.smooth, { collide = false })
		for _, x in ipairs({ -0.2, 0.2 }) do
			Kit.ball(m, 0.15, x, 2.05, -0.5, P.black, M.smooth, { collide = false })
		end
		Kit.cyl(m, 0.4, 0.7, 0.7, 0.9, -0.2, P.porcelain, M.smooth, { collide = false })
	end)
	Registry.register("aquarium", function(m, item)
		Kit.finish(m, size(item))
		local w, h, d = item.size[1], item.size[2], item.size[3]
		Kit.box(m, w, 2, d, 0, 1, 0, P.wood_black, M.wood)
		Kit.box(m, w, h - 2.2, d, 0, 2 + (h - 2.2) / 2, 0, P.glass, M.glass, { transparency = 0.7 })
		Kit.box(m, w - 0.2, h - 2.6, d - 0.2, 0, 2 + (h - 2.6) / 2 + 0.1, 0, P.water, M.glass, { transparency = 0.55, collide = false })
		Kit.box(m, w - 0.2, 0.3, d - 0.2, 0, 2.15, 0, P.sand, M.pebble, { collide = false })
		Kit.box(m, w, 0.2, d, 0, h - 0.1, 0, P.wood_black, M.wood)
		for i = 0, 4 do
			local fish = Kit.blob(m, 0.4, 0.22, 0.12, -1.5 + i * 0.7, 2.8 + (i % 3) * 0.5, -0.2 + (i % 2) * 0.4, (i % 2 == 0) and P.koi_orange or P.neon_yellow, M.smooth, { collide = false })
			fish:SetAttribute("Animate", "fish")
		end
		for i = 0, 3 do
			Kit.cyl(m, 0.1, 1.2, -1.8 + i * 1.2, 2.9, 0.3, P.leaf, M.leafy, { collide = false })
		end
		local lamp = Kit.box(m, w - 0.4, 0.05, 0.4, 0, h - 0.25, 0, P.white, M.neon, { collide = false })
		Kit.light(lamp, "Surface", P.neon_blue, 8, 1, { face = Enum.NormalId.Bottom })
	end)
	Registry.register("samurai_armor", function(m, item)
		Kit.finish(m, size(item))
		local h = item.size[2]
		Kit.box(m, 2.2, 0.5, 1.8, 0, 0.25, 0, P.wood_black, M.wood)
		Kit.box(m, 0.3, 2, 0.3, 0, 1.4, 0.2, P.wood_black, M.wood)
		for i = 0, 3 do
			Kit.box(m, 1.6 - i * 0.05, 0.3, 1.0, 0, 2.2 + i * 0.32, 0, (i % 2 == 0) and P.lacquer or P.black, M.smooth)
		end
		for _, x in ipairs({ -1, 1 }) do
			for i = 0, 2 do
				Kit.box(m, 0.7, 0.25, 0.9, x * 1.05, 3.5 - i * 0.28, 0, (i % 2 == 0) and P.black or P.lacquer, M.smooth, { rot = CFrame.Angles(0, 0, math.rad(x * -15)) })
			end
		end
		for i = 0, 2 do
			Kit.box(m, 1.8, 0.3, 1.1, 0, 1.7 - i * 0.3, 0, (i % 2 == 0) and P.black or P.lacquer, M.smooth, { collide = false })
		end
		Kit.ball(m, 1, 0, h - 1.4, 0, P.black, M.smooth)
		Kit.box(m, 1.6, 0.15, 1.4, 0, h - 1.6, 0, P.black, M.smooth, { collide = false })
		Kit.box(m, 0.7, 0.4, 0.15, 0, h - 1.5, -0.5, P.lacquer_dark, M.smooth, { collide = false })
		for _, x in ipairs({ -1, 1 }) do
			Kit.wedge(m, 0.1, 1, 0.3, CFrame.new(x * 0.35, h - 0.55, -0.35) * CFrame.Angles(0, math.rad(90), math.rad(x * 15)), P.gold, M.foil, { collide = false })
		end
	end)
	Registry.register("dragon_statue", function(m, item)
		Kit.finish(m, size(item))
		local w, h = item.size[1], item.size[2]
		Kit.cyl(m, w - 0.5, 0.8, 0, 0.4, 0, P.stone_dark, M.granite)
		for i = 0, 16 do
			local t = i / 16
			local a = t * math.pi * 3
			local r = 1.6 * (1 - t * 0.5)
			Kit.ball(m, 0.9 - t * 0.35, math.cos(a) * r, 1.1 + t * (h - 2.4), math.sin(a) * r, (i % 2 == 0) and P.matcha or P.leaf_dark, M.smooth, { collide = false })
			if i % 3 == 0 then
				Kit.wedge(m, 0.08, 0.4, 0.3, CFrame.new(math.cos(a) * r, 1.5 + t * (h - 2.4), math.sin(a) * r) * CFrame.Angles(0, -a, 0), P.gold, M.foil, { collide = false })
			end
		end
		local hy = h - 1
		Kit.blob(m, 1.1, 0.8, 1.4, 0, hy, -0.4, P.matcha, M.smooth, { collide = false })
		Kit.blob(m, 0.8, 0.4, 0.6, 0, hy - 0.2, -1.1, P.leaf_dark, M.smooth, { collide = false })
		for _, x in ipairs({ -0.3, 0.3 }) do
			Kit.ball(m, 0.18, x, hy + 0.15, -0.95, P.neon_yellow, M.neon, { collide = false })
			Kit.cyl(m, 0.1, 0.9, x, hy + 0.7, 0, P.gold, M.foil, { collide = false, rot = CFrame.Angles(math.rad(-30), 0, math.rad(x * 30)) })
		end
	end)
	Registry.register("shisa_pair", function(m, item)
		Kit.finish(m, size(item))
		shisa(m, -1.6, P.copper, true)
		shisa(m, 1.6, P.copper, false)
	end)

	-- Garden & water ----------------------------------------------------------------------------
	Registry.register("stone_path", function(m, item)
		Kit.finish(m, size(item))
		Kit.cyl(m, 1.4, 0.18, -0.2, 0.09, -0.15, P.stone, M.slate, { collide = true })
		Kit.cyl(m, 0.8, 0.16, 0.55, 0.08, 0.55, P.stone_light, M.slate)
	end)
	Registry.register("moss_garden", function(m, item)
		Kit.finish(m, size(item))
		local w = item.size[1]
		Kit.box(m, w, 0.3, w, 0, 0.15, 0, P.wood_dark, M.ground or M.sand)
		foliage(m, { { -0.8, 0.4, -0.6, 1.6, 0.5 }, { 0.7, 0.4, 0.5, 1.8, 0.6 }, { 0.6, 0.35, -1, 1, 0.4 } }, P.moss)
		Kit.blob(m, 0.9, 0.7, 0.8, -0.6, 0.55, 0.9, P.stone_dark, M.rock)
		Kit.blob(m, 0.6, 0.5, 0.6, 1.2, 0.5, -0.2, P.stone, M.rock)
	end)
	Registry.register("shishi_odoshi", function(m, item)
		Kit.finish(m, size(item))
		Kit.cyl(m, 1.4, 0.8, 0.8, 0.4, 0, P.stone, M.granite)
		Kit.cyl(m, 1.1, 0.05, 0.8, 0.78, 0, P.water, M.glass, { collide = false, transparency = 0.2 })
		Kit.cyl(m, 0.18, 2.2, -1.3, 1.1, 0, P.bamboo_green, M.wood)
		Kit.cylH(m, 0.14, 1.2, -0.8, 2.1, 0, P.bamboo_green, M.wood, { collide = false })
		for _, z in ipairs({ -0.35, 0.35 }) do
			Kit.box(m, 0.12, 1.4, 0.12, 0.2, 0.7, z, P.bamboo, M.wood)
		end
		local arm = Kit.cylH(m, 0.28, 1.8, 0.4, 1.5, 0, P.bamboo_green, M.wood, { collide = false, name = "Arm" })
		arm:SetAttribute("Animate", "shishi")
		local drip = Kit.box(m, 0.1, 0.1, 0.1, -0.2, 2.0, 0, P.white, M.smooth, { transparency = 1, collide = false })
		Kit.particles(drip, "water", { rate = 4 })
	end)
	Registry.register("zen_garden", function(m, item)
		Kit.finish(m, size(item))
		local w = item.size[1]
		for _, s in ipairs({ { 0, -w / 2 + 0.15, w, 0.3 }, { 0, w / 2 - 0.15, w, 0.3 }, { -w / 2 + 0.15, 0, 0.3, w }, { w / 2 - 0.15, 0, 0.3, w } }) do
			Kit.box(m, s[3], 0.6, s[4], s[1], 0.3, s[2], P.wood_dark, M.wood)
		end
		Kit.box(m, w - 0.6, 0.4, w - 0.6, 0, 0.2, 0, P.sand, M.sand)
		for i = 0, 6 do
			Kit.box(m, w - 0.8, 0.02, 0.08, 0, 0.41, -w / 2 + 0.8 + i * (w - 1.6) / 6, P.stone_light, M.sand, { collide = false })
		end
		Kit.blob(m, 1.2, 0.8, 1, -1, 0.6, -0.8, P.stone_dark, M.rock)
		Kit.blob(m, 0.8, 0.6, 0.7, 1.2, 0.55, 0.9, P.stone, M.rock)
		Kit.blob(m, 0.5, 0.4, 0.5, 0.6, 0.5, -1.4, P.stone, M.rock)
	end)
	Registry.register("koi_pond", function(m, item)
		Kit.finish(m, size(item))
		local w, h, d = item.size[1], item.size[2], item.size[3]
		for i = 0, 13 do
			local a = i / 14 * math.pi * 2
			Kit.blob(m, 1.3, 0.8, 1, math.cos(a) * (w / 2 - 0.6), 0.4, math.sin(a) * (d / 2 - 0.6), (i % 2 == 0) and P.stone or P.stone_dark, M.rock)
		end
		Kit.box(m, w - 1.4, 0.1, d - 1.4, 0, 0.1, 0, P.stone_dark, M.pebble, { collide = false })
		Kit.box(m, w - 1.2, 0.1, d - 1.2, 0, 0.55, 0, P.water, M.glass, { collide = false, transparency = 0.35 })
		for i = 0, 3 do
			local koi = Kit.blob(m, 0.7, 0.18, 0.28, -1.5 + i, 0.45, -0.6 + (i % 2) * 1.1, (i % 2 == 0) and P.koi_orange or P.white, M.smooth, { collide = false })
			koi:SetAttribute("Animate", "koi")
		end
		for i = 0, 2 do
			Kit.cyl(m, 0.8, 0.03, 1.2 - i * 0.9, 0.62, 1 - i * 0.6, P.leaf, M.leafy, { collide = false })
		end
	end)
	Registry.register("red_bridge", function(m, item)
		Kit.finish(m, size(item))
		local w, h, d = item.size[1], item.size[2], item.size[3]
		local n = 8
		for i = 0, n - 1 do
			local t = (i + 0.5) / n
			local y = math.sin(t * math.pi) * (h - 1.2)
			local z = -d / 2 + d * t
			Kit.box(m, w, 0.25, d / n + 0.05, 0, y + 0.12, z, P.wood_light, M.planks)
			for _, x in ipairs({ -w / 2 + 0.1, w / 2 - 0.1 }) do
				Kit.box(m, 0.15, 1, 0.15, x, y + 0.6, z, P.lacquer, M.smooth, { collide = false })
			end
		end
		for _, x in ipairs({ -w / 2 + 0.1, w / 2 - 0.1 }) do
			for i = 0, n - 2 do
				local t1, t2 = (i + 0.5) / n, (i + 1.5) / n
				local y1 = math.sin(t1 * math.pi) * (h - 1.2) + 1.1
				local y2 = math.sin(t2 * math.pi) * (h - 1.2) + 1.1
				local z1, z2 = -d / 2 + d * t1, -d / 2 + d * t2
				local mid = Vector3.new(x, (y1 + y2) / 2, (z1 + z2) / 2)
				local len = math.sqrt((z2 - z1) ^ 2 + (y2 - y1) ^ 2)
				Kit.part(m, Vector3.new(0.18, 0.15, len), CFrame.lookAt(mid, Vector3.new(x, y2, z2)), P.lacquer, M.smooth, { collide = false })
			end
		end
	end)
	Registry.register("torii_small", function(m, item)
		torii(m, item, P.vermilion, P.black)
	end)
	Registry.register("torii_gold", function(m, item)
		torii(m, item, P.gold, P.black)
		for _, d in ipairs(m:GetDescendants()) do
			if d:IsA("BasePart") and d.Color == P.gold then
				d.Material = M.foil
			end
		end
	end)
	Registry.register("waterfall", function(m, item)
		Kit.finish(m, size(item))
		local w, h, d = item.size[1], item.size[2], item.size[3]
		for i, b in ipairs({ { -1.8, 1.5, 0.8, 2.6, 3, 2 }, { 1.8, 1.8, 0.6, 2.4, 3.6, 2.2 }, { 0, h - 1.6, 1, 3.6, 3, 2 }, { -1.5, 4, 1, 2, 3, 1.8 }, { 1.6, 4.4, 1, 2, 3, 1.8 } }) do
			Kit.blob(m, b[4], b[5], b[6], b[1], b[2], b[3], (i % 2 == 0) and P.stone_dark or P.stone, M.rock)
		end
		local fall = Kit.box(m, 1.4, h - 2, 0.2, 0, (h - 2) / 2 + 1, 0, P.water, M.glass, { collide = false, transparency = 0.3 })
		Kit.particles(fall, "water", { rate = 25 })
		Kit.box(m, w - 0.6, 0.6, 2, 0, 0.3, -d / 2 + 1, P.water, M.glass, { collide = false, transparency = 0.35 })
		local mist = Kit.box(m, 1.6, 0.2, 1, 0, 0.8, -0.6, P.white, M.smooth, { transparency = 1, collide = false })
		Kit.particles(mist, "smoke", { rate = 5 })
	end)

	-- Festival -------------------------------------------------------------------------------------
	Registry.register("nobori", function(m, item)
		Kit.finish(m, size(item))
		local h = item.size[2]
		Kit.cyl(m, 0.8, 0.3, 0, 0.15, 0, P.charcoal, M.concrete)
		Kit.cyl(m, 0.12, h - 0.3, -0.5, h / 2, 0, P.metal, M.metal)
		Kit.cylH(m, 0.08, 1.1, 0.05, h - 0.4, 0, P.metal, M.metal, { collide = false })
		local banner = Kit.box(m, 1.0, h - 2, 0.04, 0.05, h - 0.4 - (h - 2) / 2, 0, P.lacquer, M.fabric, { collide = false })
		banner:SetAttribute("Animate", "sway")
		Kit.text(banner, Enum.NormalId.Front, "ラ\nー\nメ\nン", { color = "#FFFFFF", font = JP_FONT, pps = 30 })
		Kit.text(banner, Enum.NormalId.Back, "ラ\nー\nメ\nン", { color = "#FFFFFF", font = JP_FONT, pps = 30 })
	end)
	Registry.register("vending_machine", function(m, item)
		Kit.finish(m, size(item))
		local w, h, d = item.size[1], item.size[2], item.size[3]
		Kit.box(m, w, h, d, 0, h / 2, 0, P.lacquer, M.smooth)
		local glass = Kit.box(m, w - 0.5, h * 0.5, 0.05, -0.1, h * 0.65, -d / 2 - 0.02, P.white, M.neon, { collide = false })
		glass.Transparency = 0.3
		for r = 0, 2 do
			for c = 0, 4 do
				Kit.cyl(m, 0.3, 0.6, -w / 2 + 0.5 + c * 0.42, h * 0.45 + r * 0.95, -d / 2 + 0.15, ({ P.neon_blue, P.neon_yellow, P.matcha, P.white, P.koi_orange })[c + 1], M.smooth, { collide = false })
			end
		end
		Kit.box(m, w - 0.8, 0.5, 0.2, -0.1, 0.6, -d / 2 - 0.05, P.black, M.smooth, { collide = false })
		Kit.light(glass, "Surface", P.white, 8, 1, { face = Enum.NormalId.Front })
	end)
	Registry.register("gashapon", function(m, item)
		Kit.finish(m, size(item))
		local h = item.size[2]
		Kit.box(m, 1.6, h * 0.45, 1.4, 0, h * 0.225, 0, P.neon_pink, M.smooth)
		Kit.box(m, 0.4, 0.4, 0.1, 0, h * 0.3, -0.72, P.white, M.smooth, { collide = false })
		Kit.ball(m, 1.6, 0, h * 0.45 + 0.75, 0, P.glass, M.glass, { transparency = 0.6 })
		for i = 0, 9 do
			Kit.ball(m, 0.4, -0.4 + (i % 4) * 0.27, h * 0.45 + 0.3 + math.floor(i / 4) * 0.35, -0.2 + (i % 3) * 0.2, ({ P.neon_red, P.neon_blue, P.neon_yellow, P.matcha })[i % 4 + 1], M.smooth, { collide = false })
		end
		Kit.box(m, 1.7, 0.2, 1.5, 0, h - 0.1, 0, P.neon_pink, M.smooth)
	end)
	Registry.register("koinobori", function(m, item)
		Kit.finish(m, size(item))
		local h = item.size[2]
		Kit.cyl(m, 0.25, h, 0, h / 2, 0, P.wood_light, M.wood)
		Kit.ball(m, 0.4, 0, h, 0, P.gold, M.metal)
		for i, c in ipairs({ P.black, P.lacquer, P.navy }) do
			local fish = Kit.blob(m, 2.6 - i * 0.3, 0.7, 0.5, 1.5, h - 1 - i * 1.2, 0, c, M.fabric, { collide = false })
			fish:SetAttribute("Animate", "streamer")
			Kit.ball(m, 0.25, 0.5, h - 0.9 - i * 1.2, -0.2, P.white, M.smooth, { collide = false })
		end
	end)
	Registry.register("taiko", function(m, item)
		Kit.finish(m, size(item))
		local w, h = item.size[1], item.size[2]
		for _, x in ipairs({ -1, 1 }) do
			Kit.box(m, 0.25, h - 0.5, 0.25, x, (h - 0.5) / 2, 0.5, P.wood_black, M.wood)
			Kit.box(m, 0.25, h - 0.5, 0.25, x, (h - 0.5) / 2, -0.5, P.wood_black, M.wood)
		end
		Kit.cylH(m, 2.3, 1.6, 0, h - 1.3, 0, P.lacquer_dark, M.wood, nil, "z")
		Kit.cylH(m, 2.1, 1.7, 0, h - 1.3, 0, P.paper, M.leather, { collide = false }, "z")
		Kit.cylH(m, 2.35, 0.1, 0, h - 1.3, -0.75, P.gold, M.metal, { collide = false }, "z")
		Kit.cylH(m, 2.35, 0.1, 0, h - 1.3, 0.75, P.gold, M.metal, { collide = false }, "z")
		Kit.cyl(m, 0.12, 1.2, 0.8, h - 0.4, -0.9, P.wood_light, M.wood, { collide = false, rot = CFrame.Angles(0, 0, math.rad(40)) })
		Kit.cyl(m, 0.12, 1.2, -0.8, h - 0.4, -0.9, P.wood_light, M.wood, { collide = false, rot = CFrame.Angles(0, 0, math.rad(-40)) })
	end)
	Registry.register("yatai", function(m, item)
		Kit.finish(m, size(item))
		local w, h, d = item.size[1], item.size[2], item.size[3]
		Kit.box(m, w - 1, 2.6, d - 1.4, 0, 1.6, 0.2, P.wood, M.planks)
		Kit.box(m, w - 0.6, 0.2, d - 0.8, 0, 3, 0, P.wood_light, M.wood)
		for _, x in ipairs({ -w / 2 + 0.8, w / 2 - 0.8 }) do
			Kit.cylH(m, 1.4, 0.3, x, 0.7, -d / 2 + 0.9, P.wood_dark, M.wood, nil, "z")
			Kit.box(m, 0.2, h - 3, 0.2, x, 3 + (h - 3) / 2, -d / 2 + 0.6, P.wood_dark, M.wood)
			Kit.box(m, 0.2, h - 3, 0.2, x, 3 + (h - 3) / 2, d / 2 - 0.6, P.wood_dark, M.wood)
		end
		Kit.box(m, w, 0.3, d, 0, h - 0.15, 0, P.wood_black, M.wood)
		local cloth = Kit.box(m, w - 0.4, 1.2, 0.05, 0, h - 0.9, -d / 2 + 0.5, P.lacquer, M.fabric, { collide = false })
		cloth:SetAttribute("Animate", "sway")
		Kit.text(cloth, Enum.NormalId.Front, "おでん・ラーメン", { color = "#FFFFFF", font = JP_FONT, pps = 30 })
		for _, x in ipairs({ -w / 2 + 0.5, w / 2 - 0.5 }) do
			local l = Kit.blob(m, 0.6, 0.9, 0.6, x, h - 1.3, -d / 2 + 0.35, P.lacquer, M.smooth, { collide = false })
			Kit.light(l, "Point", P.lamp_warm, 10, 1)
			l:SetAttribute("Animate", "sway")
		end
		Kit.cyl(m, 1, 0.8, -0.8, 3.5, 0.2, P.metal, M.metal, { collide = false })
	end)

	-- Seasonal ---------------------------------------------------------------------------------------
	Registry.register("hanami_dango", function(m, item)
		Kit.finish(m, size(item))
		local w, h, d = item.size[1], item.size[2], item.size[3]
		Kit.box(m, w, 2.4, d, 0, 1.2, 0, P.wood_light, M.wood)
		local cloth = Kit.box(m, w + 0.1, 0.6, d + 0.1, 0, 2.2, 0, P.sakura, M.fabric, { collide = false })
		local _ = cloth
		for i = 0, 4 do
			local x = -1 + i * 0.5
			Kit.cyl(m, 0.05, 1.2, x, 3, -0.4, P.wood_light, M.wood, { collide = false })
			for k, c in ipairs({ P.sakura, P.white, P.matcha }) do
				Kit.ball(m, 0.3, x, 2.75 + k * 0.28, -0.4, c, M.smooth, { collide = false })
			end
		end
		Kit.cylH(m, 0.1, w, 0, h - 0.4, 0.8, P.wood_dark, M.wood, { collide = false })
		local sign = Kit.box(m, 1.6, 0.8, 0.05, 0, h - 0.9, 0.8, P.paper, M.smooth, { collide = false })
		Kit.text(sign, Enum.NormalId.Front, "団子", { color = "#B3262E", font = JP_FONT })
	end)
	Registry.register("sakura_garland", function(m, item)
		Kit.finish(m, size(item))
		local w, h, d = item.size[1], item.size[2], item.size[3]
		for i = 0, 11 do
			local x = -w / 2 + 0.3 + i * (w - 0.6) / 11
			local y = h - 0.3 - 0.4 * math.sin(math.pi * i / 11)
			Kit.ball(m, 0.4, x, y, d / 2 - 0.2, (i % 2 == 0) and P.sakura or P.white, M.fabric, { collide = false })
		end
	end)
	Registry.register("tanabata_bamboo", function(m, item)
		Kit.finish(m, size(item))
		local h = item.size[2]
		Kit.cyl(m, 1.2, 0.8, 0, 0.4, 0, P.wood_dark, M.wood)
		Kit.cyl(m, 0.25, h - 0.5, 0, h / 2, 0, P.bamboo_green, M.wood)
		for i = 0, 9 do
			local y = 2.5 + i * 0.5
			local a = math.rad(i * 70)
			Kit.part(m, Vector3.new(0.25, 0.7, 0.03), CFrame.new(math.cos(a) * 0.6, y, math.sin(a) * 0.6) * CFrame.Angles(0, a, 0), ({ P.neon_yellow, P.neon_pink, P.neon_blue, P.matcha, P.lacquer })[i % 5 + 1], M.fabric, { collide = false })
			Kit.box(m, 1.2, 0.04, 0.2, math.cos(a) * 0.5, y + 0.3, math.sin(a) * 0.5, P.leaf, M.leafy, { collide = false, rot = CFrame.Angles(0, a, math.rad(-20)) })
		end
	end)
	Registry.register("moon_rabbit", function(m, item)
		Kit.finish(m, size(item))
		Kit.blob(m, 1.1, 0.9, 1, 0, 0.45, 0.1, P.white, M.smooth)
		Kit.ball(m, 0.7, 0, 1.05, -0.2, P.white, M.smooth, { collide = false })
		for _, x in ipairs({ -0.15, 0.15 }) do
			Kit.blob(m, 0.15, 0.7, 0.1, x, 1.6, -0.15, P.white, M.smooth, { collide = false })
			Kit.ball(m, 0.08, x, 1.1, -0.53, P.lacquer, M.smooth, { collide = false })
		end
		for i = 0, 2 do
			Kit.ball(m, 0.25, 0.45 + i * 0.05, 0.12 + i * 0.2, -0.4, P.paper, M.smooth, { collide = false })
		end
	end)
	Registry.register("susuki_vase", function(m, item)
		Kit.finish(m, size(item))
		Kit.cyl(m, 0.6, 0.8, 0, 0.4, 0, P.stone_dark, M.smooth)
		for i = 0, 4 do
			local a = math.rad(-30 + i * 15)
			Kit.part(m, Vector3.new(0.05, 1.4, 0.05), CFrame.new(0, 0.8, 0) * CFrame.Angles(0, 0, a) * CFrame.new(0, 0.7, 0), P.bamboo, M.wood, { collide = false })
			Kit.blob(m, 0.12, 0.4, 0.12, math.sin(-a) * 1.3, 0.8 + math.cos(a) * 1.3, 0, P.sand, M.fabric, { collide = false })
		end
	end)
	Registry.register("kadomatsu", function(m, item)
		Kit.finish(m, size(item))
		local h = item.size[2]
		Kit.cyl(m, 1.6, 1.2, 0, 0.6, 0, P.bamboo, M.fabric)
		for i, hh in ipairs({ h - 0.2, h - 0.9, h - 1.4 }) do
			local a = math.rad(i * 120)
			local x, z = math.cos(a) * 0.3, math.sin(a) * 0.3
			Kit.cyl(m, 0.3, hh - 1, x, 1 + (hh - 1) / 2, z, P.bamboo_green, M.wood)
			Kit.wedge(m, 0.3, 0.5, 0.3, CFrame.new(x, hh + 0.2, z) * CFrame.Angles(0, a, 0), P.bamboo_green, M.wood, { collide = false })
		end
		foliage(m, { { 0, 1.4, 0.6, 1.2, 0.5 }, { -0.5, 1.5, -0.3, 0.9, 0.5 } }, P.leaf_dark)
	end)
	Registry.register("kagami_mochi", function(m, item)
		Kit.finish(m, size(item))
		Kit.box(m, 0.9, 0.3, 0.9, 0, 0.15, 0, P.wood_light, M.wood)
		Kit.blob(m, 0.85, 0.4, 0.85, 0, 0.5, 0, P.white, M.smooth)
		Kit.blob(m, 0.65, 0.32, 0.65, 0, 0.82, 0, P.white, M.smooth, { collide = false })
		Kit.ball(m, 0.35, 0, 1.12, 0, P.koi_orange, M.smooth, { collide = false })
	end)
	Registry.register("osaka_octopus_sign", function(m, item)
		Kit.finish(m, size(item))
		local w, h, d = item.size[1], item.size[2], item.size[3]
		local z = d / 2 - 0.3
		Kit.box(m, w, h * 0.35, 0.2, 0, h * 0.18, d / 2 - 0.1, P.neon_yellow, M.smooth)
		local label = Kit.box(m, w - 0.4, h * 0.3, 0.05, 0, h * 0.18, d / 2 - 0.22, P.neon_yellow, M.smooth, { collide = false })
		Kit.text(label, Enum.NormalId.Front, "たこ焼き", { color = "#B3262E", font = JP_FONT })
		Kit.blob(m, 2.4, 2, 0.6, 0, h * 0.6, z, P.neon_red, M.smooth, { collide = false })
		for _, x in ipairs({ -0.4, 0.4 }) do
			Kit.ball(m, 0.5, x, h * 0.65, z - 0.3, P.white, M.smooth, { collide = false })
			Kit.ball(m, 0.22, x, h * 0.65, z - 0.5, P.black, M.smooth, { collide = false })
		end
		for i = 0, 5 do
			local a = math.rad(-75 + i * 30)
			local tentacle = Kit.part(m, Vector3.new(0.35, 1.5, 0.3), CFrame.new(0, h * 0.42, z) * CFrame.Angles(0, 0, a) * CFrame.new(0, -0.9, 0), P.neon_red, M.smooth, { collide = false })
			tentacle:SetAttribute("Animate", "sway")
		end
	end)
end
