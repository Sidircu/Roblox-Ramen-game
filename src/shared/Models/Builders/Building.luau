--!nonstrict
-- Building shell pieces used by the server WorldService (floors, walls, roof, stairs, facade).
-- All coordinates are world coordinates (the plot origin is the world origin).
local CollectionService = game:GetService("CollectionService")

local Kit = require(script.Parent.Parent.Kit)
local P = require(script.Parent.Parent.Palette)
local Color = require(script.Parent.Parent.Parent.Util.Color)
local M = P.M

local JP_FONT = Font.new("rbxasset://fonts/families/FredokaOne.json", Enum.FontWeight.Bold)
local B = {}

local function tag(part, name, attrs)
	CollectionService:AddTag(part, name)
	if attrs then
		for k, v in pairs(attrs) do
			part:SetAttribute(k, v)
		end
	end
	return part
end

function B.floorSkin(parent, rect, y, style, attrs)
	local w, d = rect[3] - rect[1], rect[4] - rect[2]
	local p = Kit.box(parent, w, 0.2, d, (rect[1] + rect[3]) / 2, y - 0.1, (rect[2] + rect[4]) / 2, style.color, style.material, { collide = true })
	p.Name = "Floor"
	tag(p, "Floor", attrs)
	return p
end

function B.slab(parent, rect, y0, thickness, color, material, name)
	local w, d = rect[3] - rect[1], rect[4] - rect[2]
	local p = Kit.box(parent, w, thickness, d, (rect[1] + rect[3]) / 2, y0 + thickness / 2, (rect[2] + rect[4]) / 2, color, material, { collide = true })
	p.Name = name or "Slab"
	return p
end

-- Wall segment. style = {color, material, lattice, stripes}; outsideSign = -1/1 side of the
-- exterior (nil when both sides are interior).
function B.wall(parent, seg, y0, height, thickness, style, outsideSign, exteriorStyle)
	local len = seg.b - seg.a
	local cx, cz, sx, sz
	if seg.axis == "z" then
		cx, cz = (seg.a + seg.b) / 2, seg.line
		sx, sz = len + thickness, thickness
	else
		cx, cz = seg.line, (seg.a + seg.b) / 2
		sx, sz = thickness, len + thickness
	end
	local wall = Kit.box(parent, sx, height, sz, cx, y0 + height / 2, cz, style.color, style.material, { collide = true })
	wall.Name = "Wall"
	tag(wall, "Wall", { FloorIndex = seg.floor })
	-- baseboard on both faces
	local base = Kit.box(parent, sx + 0.06, 0.6, sz + 0.06, cx, y0 + 0.3, cz, P.wood_dark, M.wood, { collide = false })
	tag(base, "Wall", { FloorIndex = seg.floor })
	-- interior decoration
	if style.lattice or style.stripes then
		local step = style.lattice and 2 or 0.8
		local n = math.floor(len / step)
		for i = 1, n - 1 do
			local along = seg.a + i * step
			for side = -1, 1, 2 do
				if side ~= outsideSign then
					local off = side * (thickness / 2 + 0.03)
					local x, z = (seg.axis == "z") and along or seg.line + off, (seg.axis == "z") and seg.line + off or along
					local bar = Kit.box(parent, seg.axis == "z" and 0.12 or 0.06, height - 1, seg.axis == "z" and 0.06 or 0.12, x, y0 + 0.6 + (height - 1) / 2, z, style.lattice and P.wood_dark or Color.hex("#8A7A3A"), M.wood, { collide = false, shadow = false })
					tag(bar, "Wall", { FloorIndex = seg.floor })
				end
			end
		end
	end
	if outsideSign then
		local ext = exteriorStyle or { color = P.cream, material = M.plaster }
		local off = outsideSign * (thickness / 2 + 0.1)
		local ex, ez = cx, cz
		local esx, esz = sx, sz
		if seg.axis == "z" then
			ez = cz + off
			esz = 0.2
		else
			ex = cx + off
			esx = 0.2
		end
		local skin = Kit.box(parent, esx, height, esz, ex, y0 + height / 2, ez, ext.color, ext.material, { collide = false })
		tag(skin, "Roof")
		local stone = Kit.box(parent, esx + (seg.axis == "x" and 0.1 or 0), 1.4, esz + (seg.axis == "z" and 0.1 or 0), ex, y0 + 0.7, ez, P.stone_dark, M.slate, { collide = false })
		tag(stone, "Roof")
		local beam = Kit.box(parent, esx + (seg.axis == "x" and 0.2 or 0), 0.7, esz + (seg.axis == "z" and 0.2 or 0), ex, y0 + height - 0.35, ez, P.wood_dark, M.wood, { collide = false })
		tag(beam, "Roof")
		local posts = math.floor(len / 6)
		for i = 0, posts do
			local along = seg.a + (len) * (posts == 0 and 0.5 or i / posts)
			local px = seg.axis == "z" and along or ex + outsideSign * 0.08
			local pz = seg.axis == "z" and ez + outsideSign * 0.08 or along
			local post = Kit.box(parent, seg.axis == "z" and 0.5 or 0.25, height, seg.axis == "z" and 0.25 or 0.5, px, y0 + height / 2, pz, P.wood_dark, M.wood, { collide = false })
			tag(post, "Roof")
		end
	end
	return wall
end

function B.doorFrame(parent, o, y0, height)
	local h = height or 9
	local function post(along)
		local x = o.axis == "z" and along or o.at
		local z = o.axis == "z" and o.at or along
		Kit.box(parent, 0.6, h, 0.6, x, y0 + h / 2, z, P.wood_dark, M.wood, { collide = true })
	end
	post(o.from + 0.3)
	post(o.to - 0.3)
	local len = o.to - o.from
	local cx = o.axis == "z" and (o.from + o.to) / 2 or o.at
	local cz = o.axis == "z" and o.at or (o.from + o.to) / 2
	Kit.box(parent, o.axis == "z" and len or 0.9, 0.6, o.axis == "z" and 0.9 or len, cx, y0 + h + 0.3, cz, P.wood_dark, M.wood, { collide = true })
	-- fill above the door up to the wall top
	Kit.box(parent, o.axis == "z" and len or 0.8, 14 - h - 0.6, o.axis == "z" and 0.8 or len, cx, y0 + h + 0.6 + (14 - h - 0.6) / 2, cz, P.cream, M.plaster, { collide = true })
end

-- Fixed noren curtain hanging in the entrance (customers walk through it)
function B.entranceNoren(parent, o, y0)
	local len = o.to - o.from
	local cx = (o.from + o.to) / 2
	local z = o.at - 0.6
	Kit.cylH(parent, 0.18, len, cx, y0 + 8.7, z, P.wood_dark, M.wood, { collide = false })
	local panels = 4
	for i = 0, panels - 1 do
		local x = o.from + len / panels * (i + 0.5)
		local cloth = Kit.box(parent, len / panels - 0.12, 3.2, 0.06, x, y0 + 7, z, P.indigo, M.fabric, { collide = false })
		cloth.CanQuery = false
		cloth:SetAttribute("Animate", "sway")
	end
	local label = Kit.box(parent, len - 0.3, 2.2, 0.02, cx, y0 + 7.2, z - 0.05, P.white, M.smooth, { transparency = 1, collide = false, shadow = false })
	label.CanQuery = false
	Kit.text(label, Enum.NormalId.Front, "ら ー め ん", { color = "#FFFFFF", font = JP_FONT, pps = 30 })
end

function B.railing(parent, seg, y0, color)
	local len = seg.b - seg.a
	local h = 3
	local cx = seg.axis == "z" and (seg.a + seg.b) / 2 or seg.line
	local cz = seg.axis == "z" and seg.line or (seg.a + seg.b) / 2
	local rail = Kit.box(parent, seg.axis == "z" and len or 0.3, 0.25, seg.axis == "z" and 0.3 or len, cx, y0 + h, cz, color or P.wood_dark, M.wood, { collide = true })
	tag(rail, "Wall", { FloorIndex = seg.floor, Rail = true })
	Kit.box(parent, seg.axis == "z" and len or 0.15, 0.15, seg.axis == "z" and 0.15 or len, cx, y0 + h / 2, cz, color or P.wood_dark, M.wood, { collide = false })
	-- invisible blocker so nobody falls off
	local block = Kit.box(parent, seg.axis == "z" and len or 0.4, h + 1, seg.axis == "z" and 0.4 or len, cx, y0 + (h + 1) / 2, cz, P.white, M.smooth, { collide = true, transparency = 1, shadow = false })
	block.CanQuery = false
	local n = math.max(1, math.floor(len / 2))
	for i = 0, n do
		local along = seg.a + len * i / n
		local x = seg.axis == "z" and along or seg.line
		local z = seg.axis == "z" and seg.line or along
		Kit.box(parent, 0.3, h, 0.3, x, y0 + h / 2, z, color or P.wood_dark, M.wood, { collide = false })
	end
end

-- Stairs rising toward +Z inside rect, from y0 to y0 + rise
function B.stairs(parent, rect, y0, rise)
	local w = rect[3] - rect[1]
	local len = rect[4] - rect[2]
	local steps = math.floor(rise)
	local depth = len / steps
	local cx = (rect[1] + rect[3]) / 2
	for k = 0, steps - 1 do
		local stepTop = y0 + (k + 1) * rise / steps
		local z = rect[2] + (k + 0.5) * depth
		local s = Kit.box(parent, w, stepTop - y0, depth, cx, y0 + (stepTop - y0) / 2, z, P.wood, M.planks, { collide = true })
		s.Name = "Step"
		tag(s, "Floor", { FloorIndex = -1, Stairs = true })
		Kit.box(parent, w, 0.1, 0.15, cx, stepTop + 0.02, z - depth / 2 + 0.08, P.wood_dark, M.wood, { collide = false, shadow = false })
	end
	for _, x in ipairs({ rect[1] + 0.15, rect[3] - 0.15 }) do
		local a = Vector3.new(x, y0 + 3.5, rect[2])
		local b = Vector3.new(x, y0 + rise + 3.5, rect[4])
		local mid = (a + b) / 2
		Kit.part(parent, Vector3.new(0.2, 0.2, (b - a).Magnitude), CFrame.lookAt(mid, b), P.lacquer, M.smooth, { collide = false })
	end
end

-- Tiled eave projecting from a street facing wall (axis "z" segment), outsideSign -1 means street at -Z
function B.eave(parent, seg, y, outsideSign, depth)
	depth = depth or 3
	local len = seg.b - seg.a + 2
	local cx = (seg.a + seg.b) / 2
	local z = seg.line + outsideSign * (depth / 2 + 0.5)
	local yaw = outsideSign < 0 and 0 or 180
	local roof = Kit.wedge(parent, len, 1.6, depth, CFrame.new(cx, y + 0.8, z) * CFrame.Angles(0, math.rad(yaw), 0), P.tile, M.roof, { collide = false })
	tag(roof, "Roof")
	local ridge = Kit.box(parent, len, 0.5, 0.6, cx, y + 1.7, seg.line + outsideSign * 0.6, P.charcoal, M.roof, { collide = false })
	tag(ridge, "Roof")
	local edge = Kit.box(parent, len, 0.25, 0.4, cx, y + 0.1, seg.line + outsideSign * (depth + 0.4), P.charcoal, M.smooth, { collide = false })
	tag(edge, "Roof")
	for _, sx in ipairs({ seg.a - 1, seg.b + 1 }) do
		local cap = Kit.box(parent, 0.5, 0.6, 0.5, sx, y + 0.3, seg.line + outsideSign * (depth + 0.3), P.charcoal, M.roof, { collide = false })
		tag(cap, "Roof")
	end
end

function B.parapet(parent, seg, y0)
	local len = seg.b - seg.a
	local cx = seg.axis == "z" and (seg.a + seg.b) / 2 or seg.line
	local cz = seg.axis == "z" and seg.line or (seg.a + seg.b) / 2
	local p = Kit.box(parent, seg.axis == "z" and len + 0.8 or 0.8, 1.2, seg.axis == "z" and 0.8 or len + 0.8, cx, y0 + 0.6, cz, P.charcoal, M.roof, { collide = true })
	tag(p, "Roof")
	return p
end

-- Paper-lit lattice window on an exterior wall
function B.window(parent, along, y, seg, outsideSign, w, h)
	local off = outsideSign * 0.65
	local x = seg.axis == "z" and along or seg.line + off
	local z = seg.axis == "z" and seg.line + off or along
	local sx, sz = seg.axis == "z" and w or 0.1, seg.axis == "z" and 0.1 or w
	local glow = Kit.box(parent, sx, h, sz, x, y, z, P.paper_warm, M.neon, { collide = false })
	glow.Transparency = 0.15
	tag(glow, "Roof")
	local cols, rows = math.max(2, math.floor(w / 0.8)), math.max(2, math.floor(h / 0.8))
	for i = 0, cols do
		local a = along - w / 2 + w * i / cols
		local bx = seg.axis == "z" and a or x + outsideSign * 0.06
		local bz = seg.axis == "z" and z + outsideSign * 0.06 or a
		local bar = Kit.box(parent, seg.axis == "z" and 0.1 or 0.08, h, seg.axis == "z" and 0.08 or 0.1, bx, y, bz, P.wood_dark, M.wood, { collide = false, shadow = false })
		tag(bar, "Roof")
	end
	for j = 0, rows do
		local yy = y - h / 2 + h * j / rows
		local bar = Kit.box(parent, sx + (seg.axis == "x" and 0.04 or 0), 0.1, sz + (seg.axis == "z" and 0.04 or 0), x + (seg.axis == "x" and outsideSign * 0.06 or 0), yy, z + (seg.axis == "z" and outsideSign * 0.06 or 0), P.wood_dark, M.wood, { collide = false, shadow = false })
		tag(bar, "Roof")
	end
end

-- Big shop sign above the entrance
function B.sign(parent, x, y, z, w, text, deluxe)
	local board = Kit.box(parent, w, 2.6, 0.4, x, y, z, deluxe and P.black or P.wood_dark, M.wood, { collide = false })
	tag(board, "Roof")
	local face = Kit.box(parent, w - 0.4, 2.1, 0.05, x, y, z - 0.23, deluxe and P.black or P.hinoki, M.wood, { collide = false })
	tag(face, "Roof")
	Kit.text(face, Enum.NormalId.Front, text, { color = deluxe and "#FFD23B" or "#2B2320", font = JP_FONT, glow = deluxe, pps = 30 })
	if deluxe then
		for _, dy in ipairs({ -1.25, 1.25 }) do
			local tube = Kit.box(parent, w, 0.1, 0.1, x, y + dy, z - 0.25, P.neon_yellow, M.neon, { collide = false })
			tag(tube, "Roof")
		end
		Kit.light(face, "Surface", P.neon_yellow, 12, 2, { face = Enum.NormalId.Front })
	end
	return face
end

-- "Open / preparing" plate next to the door; returns the TextLabel
function B.openSign(parent, x, y, z)
	local plate = Kit.box(parent, 1.6, 0.8, 0.1, x, y, z, P.wood_light, M.wood, { collide = false })
	Kit.cyl(parent, 0.04, 0.8, x, y + 0.6, z, P.black, M.fabric, { collide = false })
	local _, label = Kit.text(plate, Enum.NormalId.Front, "準備中", { color = "#2B2320", font = JP_FONT })
	return label, plate
end

function B.tag(part, name, attrs)
	return tag(part, name, attrs)
end

return function(Registry)
	Registry.Building = B
end
