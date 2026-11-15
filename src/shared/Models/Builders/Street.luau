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
			local win = Kit.box(parent, 2.4, 2.6, 0.1, x, y, face - facing * 0.06, lit and P.lamp or P.steel_dark, lit and M.neon or M.glass, { collide = false, shadow = false })
			if lit then
				win.Transparency = 0.25
			end
			Kit.box(parent, 2.8, 0.25, 0.4, x, y - 1.45, face - facing * 0.2, P.wood_dark, M.wood, { collide = false })
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
