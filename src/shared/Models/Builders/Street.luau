--!nonstrict
-- Street scenery: road, sidewalks, neighbour buildings, lamps, poles, trees, viaduct, truck, train.
local Kit = require(script.Parent.Parent.Kit)
local P = require(script.Parent.Parent.Palette)
local Color = require(script.Parent.Parent.Parent.Util.Color)
local M = P.M

local JP_FONT = Font.new("rbxasset://fonts/families/FredokaOne.json", Enum.FontWeight.Bold)
local S = {}

local SIGNS = { "居酒屋", "本屋", "薬局", "喫茶", "花屋", "銭湯", "焼鳥", "古着", "時計", "果物", "団子", "書道" }

local function rng(seed)
	return Random.new(seed or 7)
end

local function NC()
	return { collide = false, shadow = false }
end

-- Outdoor AC unit with a round fan grille, mounted on the wall
local function acUnit(parent, x, y, face, facing)
	local z = face - facing * 0.4
	Kit.box(parent, 1.6, 1.1, 0.7, x, y, z, P.stone_light, M.smooth, NC())
	Kit.cylH(parent, 0.8, 0.04, x - 0.25, y, z - facing * 0.36, P.steel_dark, M.metal, NC(), "z")
	Kit.cylH(parent, 0.2, 0.05, x - 0.25, y, z - facing * 0.38, P.metal, M.metal, NC(), "z")
	Kit.box(parent, 1.4, 0.08, 0.6, x, y - 0.6, z + facing * 0.05, P.steel_dark, M.metal, NC())
	Kit.cyl(parent, 0.12, 1.2, x + 0.6, y + 0.9, face - facing * 0.15, P.white, M.smooth, NC())
end

-- Apartment balcony: slab, frosted panel railing and (sometimes) laundry on a pole
local function balcony(parent, x, y, face, facing, r)
	local z = face - facing * 0.7
	Kit.box(parent, 3.6, 0.2, 1.4, x, y - 1.55, z, P.stone_light, M.concrete, NC())
	local panel = Kit.box(parent, 3.6, 1.2, 0.08, x, y - 0.85, face - facing * 1.38, P.metal, M.glass, NC())
	panel.Transparency = 0.35
	Kit.box(parent, 3.7, 0.1, 0.14, x, y - 0.22, face - facing * 1.38, P.steel_dark, M.metal, NC())
	if r:NextNumber() < 0.6 then
		Kit.cylH(parent, 0.08, 3.2, x, y + 0.9, face - facing * 0.9, P.metal, M.metal, NC())
		local colors = { P.white, P.sakura, P.navy, P.leaf_light, P.neon_yellow, P.indigo }
		for k = 0, r:NextInteger(1, 3) do
			local c = colors[r:NextInteger(1, #colors)]
			local cw = 0.6 + r:NextNumber() * 0.5
			Kit.box(parent, cw, 0.8 + r:NextNumber() * 0.4, 0.05, x - 1.2 + k * 0.85, y + 0.45, face - facing * 0.9, c, M.fabric, NC())
		end
	end
end

-- Chalkboard A-frame sign on the sidewalk
local function aframe(parent, x, z, facing)
	Kit.box(parent, 1.1, 1.6, 0.08, x, 0.4, z - facing * 0.25, P.wood_dark, M.wood, { collide = false, shadow = false, rot = CFrame.Angles(math.rad(12), 0, 0) })
	Kit.box(parent, 0.9, 1.2, 0.04, x, 0.45, z - facing * 0.32, P.charcoal, M.slate, { collide = false, shadow = false, rot = CFrame.Angles(math.rad(12), 0, 0) })
	Kit.box(parent, 1.1, 1.6, 0.08, x, 0.4, z + facing * 0.25, P.wood_dark, M.wood, { collide = false, shadow = false, rot = CFrame.Angles(math.rad(-12), 0, 0) })
end

-- Part placed in the local frame of `base`
local function lp(parent, base, sx, sy, sz, lx, ly, lz, rot, color, mat, props)
	local cf = base * CFrame.new(lx, ly, lz)
	if rot then
		cf = cf * rot
	end
	return Kit.part(parent, Vector3.new(sx, sy, sz), cf, color, mat, props)
end

-- Japanese city bicycle (mamachari) with a front basket; yaw in degrees, ground at -0.4
function S.bicycle(parent, x, z, yaw, color)
	local base = CFrame.new(x, -0.4, z) * CFrame.Angles(0, math.rad(yaw or 0), 0)
	local wheel = CFrame.Angles(0, math.rad(90), 0)
	for _, wx in ipairs({ -1.1, 1.1 }) do
		lp(parent, base, 0.12, 1.7, 1.7, wx, 0.85, 0, wheel, P.charcoal, M.smooth, { collide = false, shadow = false, shape = Enum.PartType.Cylinder })
		lp(parent, base, 0.13, 1.3, 1.3, wx, 0.85, 0, wheel, P.metal, M.metal, { collide = false, shadow = false, shape = Enum.PartType.Cylinder })
	end
	lp(parent, base, 1.4, 0.12, 0.12, -0.35, 1.25, 0, CFrame.Angles(0, 0, math.rad(-35)), color, M.metal, NC())
	lp(parent, base, 1.3, 0.12, 0.12, 0.3, 1.1, 0, CFrame.Angles(0, 0, math.rad(20)), color, M.metal, NC())
	lp(parent, base, 0.12, 1.2, 0.12, -0.45, 1.4, 0, CFrame.Angles(0, 0, math.rad(-15)), color, M.metal, NC())
	lp(parent, base, 0.7, 0.18, 0.35, -0.6, 2.05, 0, nil, P.charcoal, M.leather, NC())
	lp(parent, base, 0.12, 1.1, 0.12, 0.95, 1.5, 0, CFrame.Angles(0, 0, math.rad(15)), color, M.metal, NC())
	lp(parent, base, 0.1, 0.1, 1.2, 0.85, 2.05, 0, nil, P.metal, M.metal, NC())
	lp(parent, base, 0.7, 0.5, 0.8, 1.4, 1.75, 0, nil, P.metal, M.metal, { collide = false, shadow = false, transparency = 0.3 })
	lp(parent, base, 0.9, 0.06, 0.6, -1.1, 1.75, 0, nil, P.metal, M.metal, NC())
	lp(parent, base, 0.6, 0.6, 0.06, -0.9, 0.5, 0.2, nil, color, M.metal, NC())
end

-- Round-topped red post box
function S.postBox(parent, x, z)
	Kit.box(parent, 0.5, 1.6, 0.5, x, 0.4, z, P.charcoal, M.metal)
	Kit.box(parent, 1.4, 2.0, 1.1, x, 2.2, z, P.red, M.metal)
	Kit.cylH(parent, 1.1, 1.4, x, 3.2, z, P.red, M.metal, NC(), "z")
	Kit.box(parent, 1.0, 0.12, 0.06, x, 2.8, z - 0.56, P.charcoal, M.metal, NC())
	local plate = Kit.box(parent, 0.6, 0.5, 0.04, x, 2.1, z - 0.57, P.white, M.smooth, NC())
	Kit.text(plate, Enum.NormalId.Front, "〒", { color = "#C0261E", font = JP_FONT })
end

-- Pair of recycling bins next to a vending machine
function S.bins(parent, x, z)
	for k, c in ipairs({ P.indigo, P.matcha }) do
		local bx = x + (k - 1.5) * 1.1
		Kit.box(parent, 1, 1.8, 1, bx, 0.5, z, c, M.plastic, NC())
		Kit.box(parent, 1.05, 0.15, 1.05, bx, 1.45, z, P.white, M.plastic, NC())
		Kit.cyl(parent, 0.4, 0.05, bx, 1.53, z, P.charcoal, M.smooth, NC())
	end
end

-- Round traffic sign on a pole (kind = "walk" blue, "stop" red triangle)
function S.trafficSign(parent, x, z, kind)
	Kit.cyl(parent, 0.18, 7, x, 3.1, z, P.metal, M.metal)
	if kind == "stop" then
		local tri = Kit.wedge(parent, 0.08, 1.6, 0.9, CFrame.new(x, 6.2, z - 0.45) * CFrame.Angles(0, math.rad(90), 0), P.red, M.smooth, NC())
		local _ = tri
		Kit.wedge(parent, 0.08, 1.6, 0.9, CFrame.new(x, 6.2, z + 0.45) * CFrame.Angles(0, math.rad(-90), 0), P.red, M.smooth, NC())
		local plate = Kit.box(parent, 1.4, 0.5, 0.06, x, 5.1, z, P.white, M.smooth, NC())
		Kit.text(plate, Enum.NormalId.Back, "止まれ", { color = "#C0261E", font = JP_FONT })
	else
		Kit.box(parent, 1.4, 1.4, 0.08, x, 6, z, P.navy, M.smooth, NC())
		Kit.wedge(parent, 0.04, 0.9, 0.5, CFrame.new(x - 0.25, 6, z - 0.06) * CFrame.Angles(0, math.rad(90), 0), P.white, M.smooth, NC())
		Kit.wedge(parent, 0.04, 0.9, 0.5, CFrame.new(x + 0.25, 6, z - 0.06) * CFrame.Angles(0, math.rad(-90), 0), P.white, M.smooth, NC())
	end
end

-- Manhole cover, optionally steaming
function S.manhole(parent, x, y, z, steam)
	local m = Kit.cyl(parent, 2, 0.06, x, y, z, P.stone_dark, M.metal, NC())
	Kit.cyl(parent, 1.6, 0.07, x, y, z, P.steel_dark, M.metal, NC())
	Kit.cyl(parent, 0.7, 0.08, x, y, z, P.stone_dark, M.metal, NC())
	if steam then
		Kit.particles(m, "steam", { rate = 3 })
	end
end

-- Zebra crossing across the road (road along X, centered on z), with stop lines
function S.crosswalk(parent, x, y, z, roadWidth)
	local n = math.floor(roadWidth / 1.6)
	for i = 0, n - 1 do
		Kit.box(parent, 4, 0.04, 0.8, x, y, z - roadWidth / 2 + 0.8 + i * 1.6, P.road_line, M.smooth, NC())
	end
	Kit.box(parent, 0.4, 0.04, roadWidth / 2 - 0.4, x - 4, y, z + roadWidth / 4, P.road_line, M.smooth, NC())
	Kit.box(parent, 0.4, 0.04, roadWidth / 2 - 0.4, x + 4, y, z - roadWidth / 4, P.road_line, M.smooth, NC())
	local word = Kit.box(parent, 3.2, 0.04, 1.6, x - 6.5, y, z + roadWidth / 4, P.road, M.asphalt, NC())
	word.Transparency = 1
	Kit.text(word, Enum.NormalId.Top, "止まれ", { color = "#E8E4D8", font = JP_FONT, rotation = 90 })
end

-- Facade block with windows and an optional shop front
function S.building(parent, x0, x1, zFront, depth, height, facing, color, r)
	local w = x1 - x0
	local cx = (x0 + x1) / 2
	local cz = zFront + facing * depth / 2
	local body = Kit.box(parent, w, height, depth, cx, -0.4 + height / 2, cz, color, M.plaster, { collide = true })
	body.CastShadow = true
	local face = zFront - facing * 0.05
	-- shop front at street level
	local awning = ({ P.lacquer, P.indigo, P.matcha, P.wood_dark, P.navy })[r:NextInteger(1, 5)]
	Kit.box(parent, w - 1, 4.2, 0.2, cx, 2.1 - 0.4, face, P.wood_dark, M.wood, { collide = false })
	local glass = Kit.box(parent, w - 2, 3.4, 0.1, cx, 2.0 - 0.4, face - facing * 0.12, P.paper_warm, M.neon, { collide = false })
	glass.Transparency = 0.3
	-- sash mullions, a short noren over the door and something on the sidewalk
	local panes = math.max(2, math.floor((w - 2) / 2.2))
	for i = 1, panes - 1 do
		Kit.box(parent, 0.12, 3.4, 0.14, x0 + 1 + (w - 2) * i / panes, 1.6, face - facing * 0.16, P.wood_dark, M.wood, NC())
	end
	Kit.box(parent, w - 2, 0.12, 0.14, cx, 2.4, face - facing * 0.16, P.wood_dark, M.wood, NC())
	for k = -1, 1 do
		Kit.box(parent, 0.95, 1.3, 0.05, cx + k * 1.0, 2.75, face - facing * 0.3, awning, M.fabric, NC())
	end
	Kit.cylH(parent, 0.1, 3.4, cx, 3.45, face - facing * 0.3, P.wood_dark, M.wood, NC())
	local extra = r:NextNumber()
	if extra < 0.3 then
		aframe(parent, cx + w / 2 - 1.6, face - facing * 1.6, facing)
	elseif extra < 0.55 then
		Kit.cyl(parent, 1.2, 1.1, cx - w / 2 + 1.4, 0.15, face - facing * 0.9, P.stone_dark, M.concrete, NC())
		Kit.ball(parent, 1.6, cx - w / 2 + 1.4, 1.3, face - facing * 0.9, P.leaf, M.leafy, NC())
	elseif extra < 0.75 then
		S.bicycle(parent, cx - w / 2 + 2.2, face - facing * 1.3, facing < 0 and 0 or 180, ({ P.white, P.navy, P.lacquer, P.matcha })[r:NextInteger(1, 4)])
	end
	Kit.wedge(parent, w - 0.5, 0.8, 1.6, CFrame.new(cx, 4.8 - 0.4, face - facing * 0.8) * CFrame.Angles(0, math.rad(facing < 0 and 180 or 0), 0), awning, M.fabric, { collide = false })
	local shopSign = Kit.box(parent, math.min(w - 2, 6), 1.1, 0.15, cx, 5.8 - 0.4, face - facing * 0.15, P.paper, M.smooth, { collide = false })
	Kit.text(shopSign, facing < 0 and Enum.NormalId.Back or Enum.NormalId.Front, SIGNS[r:NextInteger(1, #SIGNS)], { color = "#2B2320", font = JP_FONT })
	-- upper floor windows (lit at night)
	local floors = math.floor((height - 7) / 5)
	for f = 0, floors - 1 do
		local y = 9 + f * 5 - 0.4
		local n = math.max(1, math.floor(w / 5))
		for i = 0, n - 1 do
			local x = x0 + w / n * (i + 0.5)
			local lit = r:NextNumber() < 0.55
			Kit.box(parent, 2.7, 2.9, 0.08, x, y, face - facing * 0.03, P.charcoal, M.metal, NC())
			local win = Kit.box(parent, 2.4, 2.6, 0.1, x, y, face - facing * 0.06, lit and P.lamp or P.steel_dark, lit and M.neon or M.glass, { collide = false, shadow = false })
			if lit then
				win.Transparency = 0.25
			end
			Kit.box(parent, 0.08, 2.6, 0.12, x, y, face - facing * 0.1, P.charcoal, M.metal, NC())
			Kit.box(parent, 2.8, 0.25, 0.4, x, y - 1.45, face - facing * 0.2, P.wood_dark, M.wood, { collide = false })
			local roll = r:NextNumber()
			if roll < 0.3 then
				balcony(parent, x, y, face, facing, r)
			elseif roll < 0.5 then
				acUnit(parent, x + 2, y - 0.9, face, facing)
			elseif roll < 0.62 then
				-- flower pots on the sill
				for k = -1, 1 do
					Kit.box(parent, 0.4, 0.35, 0.3, x + k * 0.7, y - 1.15, face - facing * 0.25, P.vermilion, M.smooth, NC())
					Kit.ball(parent, 0.5, x + k * 0.7, y - 0.85, face - facing * 0.25, k == 0 and P.sakura or P.leaf, M.leafy, NC())
				end
			end
		end
	end
	-- drain pipe and roof furniture
	Kit.cyl(parent, 0.3, height - 0.5, x1 - 0.35, height / 2 - 0.4, face - facing * 0.2, P.stone_dark, M.metal, NC())
	local roofY = height - 0.4 + 0.6
	local roof = r:NextNumber()
	if roof < 0.35 then
		-- water tank on legs
		local tx, tz = cx - w / 4, cz
		for _, c in ipairs({ { -0.8, -0.8 }, { 0.8, -0.8 }, { 0.8, 0.8 }, { -0.8, 0.8 } }) do
			Kit.box(parent, 0.2, 1.4, 0.2, tx + c[1], roofY + 0.7, tz + c[2], P.steel_dark, M.metal, NC())
		end
		Kit.cyl(parent, 2.4, 2.4, tx, roofY + 2.6, tz, P.stone_light, M.concrete, NC())
		Kit.cyl(parent, 2.5, 0.2, tx, roofY + 3.9, tz, P.steel, M.metal, NC())
	elseif roof < 0.6 then
		-- antenna and a couple of AC units
		Kit.cyl(parent, 0.12, 4, cx + w / 4, roofY + 2, cz, P.metal, M.metal, NC())
		for k = 0, 2 do
			Kit.cylH(parent, 0.08, 1.6 - k * 0.4, cx + w / 4, roofY + 2.5 + k * 0.6, cz, P.metal, M.metal, NC())
		end
		for k = 0, 1 do
			Kit.box(parent, 1.6, 1.1, 0.7, cx - w / 4 + k * 1.9, roofY + 0.55, cz, P.stone_light, M.smooth, NC())
		end
	elseif roof < 0.75 then
		-- rooftop billboard
		local bb = Kit.box(parent, math.min(w - 1, 9), 3, 0.3, cx, roofY + 2.6, zFront + facing * 3, P.white, M.smooth, NC())
		Kit.text(bb, facing < 0 and Enum.NormalId.Back or Enum.NormalId.Front, ({ "ラーメン", "寿司", "カメラ", "牛乳", "ビール", "茶" })[r:NextInteger(1, 6)], { color = ({ "#C0261E", "#1E2A44", "#2F5A2A" })[r:NextInteger(1, 3)], font = JP_FONT })
		for _, bx in ipairs({ -2, 2 }) do
			Kit.box(parent, 0.25, 1.4, 0.25, cx + bx, roofY + 0.7, zFront + facing * 3, P.steel_dark, M.metal, NC())
		end
	end
	-- vertical sign
	if r:NextNumber() < 0.6 then
		local vs = Kit.box(parent, 1.2, 5, 0.3, x0 + 1, height * 0.6, face - facing * 0.9, P.charcoal, M.smooth, { collide = false })
		local word = SIGNS[r:NextInteger(1, #SIGNS)]
		local vertical = ""
		for _, c in utf8.codes(word) do
			vertical ..= utf8.char(c) .. "\n"
		end
		Kit.text(vs, facing < 0 and Enum.NormalId.Back or Enum.NormalId.Front, vertical, { color = ({ "#FF3B4A", "#3BC8FF", "#FFD23B", "#FF5AC8" })[r:NextInteger(1, 4)], glow = true, font = JP_FONT })
	end
	-- roof edge
	Kit.box(parent, w + 0.4, 0.6, depth + 0.4, cx, height - 0.4 + 0.3, cz, P.charcoal, M.roof, { collide = false })
	return body
end

function S.lamp(parent, x, z, facing)
	Kit.cyl(parent, 0.35, 9, x, -0.4 + 4.5, z, P.charcoal, M.metal)
	Kit.cylH(parent, 0.2, 2, x, 8.4, z + facing * 1, P.charcoal, M.metal, { collide = false }, "z")
	local head = Kit.box(parent, 0.9, 0.4, 1.2, x, 8.2, z + facing * 1.8, P.lamp, M.neon, { collide = false })
	Kit.light(head, "Spot", P.lamp_warm, 26, 2, { face = Enum.NormalId.Bottom, angle = 100 })
end

function S.pole(parent, x, z)
	Kit.cyl(parent, 0.6, 16, x, -0.4 + 8, z, P.stone_light, M.concrete)
	-- yellow and black guard sleeve, step bolts and an address plate
	for k = 0, 3 do
		Kit.cyl(parent, 0.66, 0.45, x, 0.05 + k * 0.45, z, k % 2 == 0 and P.neon_yellow or P.black, M.smooth, NC())
	end
	for k = 0, 4 do
		Kit.cylH(parent, 0.08, 0.9, x, 6 + k * 1.2, z, P.steel_dark, M.metal, NC(), k % 2 == 0 and "z" or nil)
	end
	Kit.box(parent, 0.5, 1.6, 0.66, x, 4, z, P.navy, M.smooth, NC())
	Kit.cylH(parent, 0.25, 3, x, 14.5, z, P.wood_dark, M.wood, { collide = false })
	Kit.cylH(parent, 0.25, 2.4, x, 13.2, z, P.wood_dark, M.wood, { collide = false })
	Kit.cyl(parent, 0.8, 1.2, x + 0.6, 12, z + 0.5, P.metal, M.metal, { collide = false })
end

function S.wire(parent, a, b, sag)
	local n = 6
	for i = 0, n - 1 do
		local t1, t2 = i / n, (i + 1) / n
		local p1 = a:Lerp(b, t1) - Vector3.new(0, sag * math.sin(math.pi * t1), 0)
		local p2 = a:Lerp(b, t2) - Vector3.new(0, sag * math.sin(math.pi * t2), 0)
		Kit.part(parent, Vector3.new(0.06, 0.06, (p2 - p1).Magnitude), CFrame.lookAt((p1 + p2) / 2, p2), P.black, M.smooth, { collide = false, shadow = false })
	end
end

function S.planterTree(parent, x, z, color)
	Kit.box(parent, 3, 0.8, 3, x, 0, z, P.stone, M.concrete)
	Kit.box(parent, 2.6, 0.1, 2.6, x, 0.4, z, P.wood_dark, M.sand, { collide = false })
	Kit.cyl(parent, 0.6, 6, x, 3.4, z, P.wood_dark, M.wood)
	for _, b in ipairs({ { 0, 7.5, 0, 5 }, { -1.4, 6.6, 0.6, 3.4 }, { 1.4, 6.8, -0.5, 3.6 }, { 0.4, 8.6, 0.4, 3 } }) do
		Kit.blob(parent, b[4], b[4] * 0.7, b[4], x + b[1], b[2], z + b[3], color, M.leafy, { collide = false })
	end
end

function S.viaduct(parent, z, y, x0, x1)
	Kit.box(parent, x1 - x0, 1.6, 8, (x0 + x1) / 2, y, z, P.concrete, M.concrete)
	Kit.box(parent, x1 - x0, 1.2, 0.4, (x0 + x1) / 2, y + 1.4, z - 3.8, P.stone_light, M.concrete, { collide = false })
	Kit.box(parent, x1 - x0, 1.2, 0.4, (x0 + x1) / 2, y + 1.4, z + 3.8, P.stone_light, M.concrete, { collide = false })
	for x = x0 + 10, x1 - 10, 30 do
		Kit.box(parent, 3, y, 4, x, y / 2 - 0.4, z, P.concrete, M.concrete)
	end
	for _, dz in ipairs({ -1.5, 1.5 }) do
		Kit.box(parent, x1 - x0, 0.2, 0.25, (x0 + x1) / 2, y + 0.9, z + dz, P.steel, M.metal, { collide = false })
	end
end

-- Train (built at the origin, moved by the client)
function S.train(cars)
	local m = Kit.model("Train")
	for i = 0, (cars or 4) - 1 do
		local x = i * 13.2
		Kit.box(m, 13, 4, 4, x, 2.3, 0, P.white, M.smooth)
		Kit.box(m, 13, 0.6, 4.05, x, 1.0, 0, P.matcha, M.smooth)
		for k = 0, 4 do
			local win = Kit.box(m, 1.6, 1.2, 4.1, x - 5 + k * 2.5, 3, 0, P.lamp, M.neon, { collide = false, shadow = false })
			win.Transparency = 0.2
		end
		Kit.box(m, 12.6, 0.3, 3.6, x, 4.4, 0, P.stone_light, M.metal)
	end
	Kit.box(m, 0.3, 1, 1, -6.6, 3, 1.2, P.lamp, M.neon, { collide = false })
	Kit.box(m, 0.3, 1, 1, -6.6, 3, -1.2, P.lamp, M.neon, { collide = false })
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") then
			d.CanCollide = false
			d.CanQuery = false
		end
	end
	Kit.finish(m, Vector3.new(cars * 13.2, 5, 4))
	return m
end

-- Delivery kei truck (front faces -X)
function S.truck()
	local m = Kit.model("Truck")
	Kit.box(m, 3.2, 3.4, 4.2, -3.2, 2.3, 0, P.white, M.smooth)
	Kit.box(m, 0.1, 1.4, 3.6, -4.82, 3, 0, P.glass, M.glass, { transparency = 0.3 })
	Kit.box(m, 6.6, 0.5, 4.2, 1.6, 1.0, 0, P.steel_dark, M.metal)
	local cargo = Kit.box(m, 6.2, 3.6, 4.2, 1.8, 3.05, 0, P.paper, M.smooth, { name = "Cargo" })
	Kit.text(cargo, Enum.NormalId.Back, "🐟 魚市場 🍚", { color = "#2E3A5C" })
	Kit.text(cargo, Enum.NormalId.Front, "🐟 魚市場 🍚", { color = "#2E3A5C" })
	for _, x in ipairs({ -3.2, 3 }) do
		for _, z in ipairs({ -2, 2 }) do
			Kit.cylH(m, 1.5, 0.6, x, 0.75, z, P.charcoal, M.rubber or M.smooth, nil, "z")
		end
	end
	local light = Kit.box(m, 0.15, 0.4, 0.8, -4.85, 1.6, 1.4, P.lamp, M.neon, { collide = false })
	Kit.light(light, "Spot", P.lamp, 20, 1.5, { face = Enum.NormalId.Left, angle = 60 })
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") then
			d.CanCollide = false
		end
	end
	Kit.finish(m, Vector3.new(10, 5, 4.2))
	return m
end

function S.menuBoard(parent, x, z)
	local m = Kit.model("MenuBoard")
	Kit.box(m, 0.15, 4.2, 0.15, -1, 2.1, 0.6, P.wood_dark, M.wood)
	Kit.box(m, 0.15, 4.2, 0.15, 1, 2.1, 0.6, P.wood_dark, M.wood)
	local board = Kit.box(m, 2.4, 3.2, 0.2, 0, 2.4, 0, P.charcoal, M.slate, { name = "Board" })
	Kit.box(m, 2.6, 0.2, 0.3, 0, 4.1, 0, P.wood_dark, M.wood, { collide = false })
	Kit.text(board, Enum.NormalId.Front, "お品書き\n🍣 🍜 🍵", { color = "#F4EBDD", pps = 40 })
	Kit.finish(m, Vector3.new(2.6, 4.3, 1.4))
	m:PivotTo(CFrame.new(x, -0.4 + 2.15, z))
	m.Parent = parent
	return m
end

function S.supplierTablet(parent, x, y, z, yaw)
	local m = Kit.model("SupplierTablet")
	local frame = Kit.box(m, 0.15, 1.6, 2.4, 0, 0, 0, P.charcoal, M.smooth, { name = "Body" })
	local screen = Kit.box(m, 0.05, 1.3, 2.1, -0.09, 0, 0, P.white, M.neon, { collide = false })
	Kit.text(screen, Enum.NormalId.Left, "📦 発注", { color = "#2E3A5C", glow = true })
	local _ = frame
	Kit.finish(m, Vector3.new(0.3, 1.6, 2.4))
	m:PivotTo(CFrame.new(x, y, z) * CFrame.Angles(0, math.rad(yaw or 0), 0))
	m.Parent = parent
	return m
end

function S.rng(seed)
	return rng(seed)
end

return function(Registry)
	Registry.Street = S
	local _ = Color
end
