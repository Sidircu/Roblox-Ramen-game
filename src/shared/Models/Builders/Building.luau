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

-- Tiled eave (hisashi) projecting from a street facing wall (axis "z" segment).
-- outsideSign -1 means the street is at -Z. Tiles rows, round tile channels, rafter tails, end caps.
-- Street eave. tiled = renovation "tiled eaves" (kawara channels, ridge, rafters, onigawara);
-- otherwise a plain sheet-metal canopy.
function B.eave(parent, seg, y, outsideSign, depth, tiled)
	depth = depth or 3
	local len = seg.b - seg.a + 2
	local cx = (seg.a + seg.b) / 2
	local z = seg.line + outsideSign * (depth / 2 + 0.5)
	local yaw = outsideSign < 0 and 0 or 180
	local rise = tiled and 1.6 or 0.8
	local roof = Kit.wedge(parent, len, rise, depth, CFrame.new(cx, y + rise / 2, z) * CFrame.Angles(0, math.rad(yaw), 0), tiled and P.tile or P.steel, tiled and M.roof or M.metal, { collide = false })
	tag(roof, "Roof")
	if not tiled then
		local edge = Kit.box(parent, len, 0.2, 0.12, cx, y - 0.05, seg.line + outsideSign * (depth + 0.45), P.steel_dark, M.metal, { collide = false })
		tag(edge, "Roof")
		return
	end
	-- round tile channels running down the slope
	local slope = math.sqrt(depth * depth + rise * rise)
	local n = math.floor(len / 0.7)
	for i = 0, n do
		local x = seg.a - 1 + len * i / n
		local top = Vector3.new(x, y + rise + 0.08, seg.line + outsideSign * 0.5)
		local bottom = Vector3.new(x, y + 0.08, seg.line + outsideSign * (depth + 0.5))
		local mid = (top + bottom) / 2
		local cf = CFrame.lookAt(mid, bottom) * CFrame.Angles(0, math.rad(90), 0)
		local ch = Kit.part(parent, Vector3.new(slope, 0.22, 0.22), cf, P.charcoal, M.roof, { collide = false, shadow = false, shape = Enum.PartType.Cylinder })
		ch.CanQuery = false
		tag(ch, "Roof")
		-- round end tile (tomoe) facing the street
		local cap = Kit.cylH(parent, 0.34, 0.12, x, y + 0.1, seg.line + outsideSign * (depth + 0.56), P.charcoal, M.roof, { collide = false, shadow = false }, "z")
		cap.CanQuery = false
		tag(cap, "Roof")
	end
	-- ridge, fascia board and rafter tails
	local ridge = Kit.box(parent, len, 0.55, 0.7, cx, y + rise + 0.2, seg.line + outsideSign * 0.65, P.charcoal, M.roof, { collide = false })
	tag(ridge, "Roof")
	local ridgeTop = Kit.cylH(parent, 0.4, len, cx, y + rise + 0.5, seg.line + outsideSign * 0.65, P.tile, M.roof, { collide = false, shadow = false })
	tag(ridgeTop, "Roof")
	local fascia = Kit.box(parent, len, 0.32, 0.18, cx, y - 0.05, seg.line + outsideSign * (depth + 0.42), P.wood_dark, M.wood, { collide = false })
	tag(fascia, "Roof")
	for i = 0, math.floor(len / 1.1) do
		local x = seg.a - 1 + 0.55 + i * 1.1
		if x < seg.b + 1 then
			local tail = Kit.box(parent, 0.22, 0.22, depth - 0.3, x, y - 0.3, seg.line + outsideSign * (depth / 2 + 0.35), P.wood_dark, M.wood, { collide = false, shadow = false })
			tail.CanQuery = false
			tag(tail, "Roof")
		end
	end
	for _, sx in ipairs({ seg.a - 1.05, seg.b + 1.05 }) do
		local cap = Kit.box(parent, 0.5, 0.9, 0.6, sx, y + 0.5, seg.line + outsideSign * (depth + 0.2), P.charcoal, M.roof, { collide = false })
		tag(cap, "Roof")
		local oni = Kit.box(parent, 0.55, 0.9, 0.7, sx, y + rise + 0.45, seg.line + outsideSign * 0.65, P.charcoal, M.roof, { collide = false })
		tag(oni, "Roof")
	end
end

-- Coordinates on the face of a wall segment: along the wall, height, distance from the wall
-- line towards `side` (+1 / -1). Returns the created part.
local function faceBox(parent, seg, side, sa, sy, so, along, y, out, color, mat, props)
	if seg.axis == "z" then
		return Kit.box(parent, sa, sy, so, along, y, seg.line + side * out, color, mat, props)
	end
	return Kit.box(parent, so, sy, sa, seg.line + side * out, y, along, color, mat, props)
end
B.faceBox = faceBox

local function inAvoid(along, avoid)
	for _, r in ipairs(avoid or {}) do
		if along > r[1] and along < r[2] then
			return true
		end
	end
	return false
end

-- Interior finishes on one side of a wall: koshi-ita wainscot, hashira posts and nageshi beam
-- in dining rooms; white tiles in kitchens; plain concrete wainscot in storage rooms.
-- reno = { wainscot, beams, tiles, storage } (owned renovations); the plain room only gets
-- a skirting board.
function B.wallTrim(parent, seg, y0, side, area, height, reno)
	reno = reno or {}
	local len = seg.b - seg.a
	local mid = (seg.a + seg.b) / 2
	local NC = { collide = false, shadow = false }
	local parts = {}
	local function add(p)
		p.CanQuery = true
		tag(p, "Wall", { FloorIndex = seg.floor })
		table.insert(parts, p)
		return p
	end
	local skirting = area == "kitchen" and P.steel or (area == "storage" and P.stone_dark or P.wood_dark)
	add(faceBox(parent, seg, side, len, 0.35, 0.06, mid, y0 + 0.175, 0.43, skirting, area == "kitchen" and M.metal or M.wood, NC))
	if area == "kitchen" then
		if reno.tiles then
			add(faceBox(parent, seg, side, len, 6.4, 0.06, mid, y0 + 0.6 + 3.2, 0.44, P.white, M.tiles, NC))
			add(faceBox(parent, seg, side, len, 0.12, 0.12, mid, y0 + 7.05, 0.47, P.metal, M.metal, NC))
		end
	elseif area == "storage" then
		if reno.storage then
			add(faceBox(parent, seg, side, len, 3, 0.06, mid, y0 + 1.5, 0.44, P.concrete, M.concrete, NC))
			add(faceBox(parent, seg, side, len, 0.15, 0.1, mid, y0 + 3.05, 0.46, P.neon_yellow, M.smooth, NC))
		end
	else
		if reno.wainscot then
			local panel = area == "tatami" and P.hinoki or P.wood_dark
			add(faceBox(parent, seg, side, len, 2.7, 0.08, mid, y0 + 1.35, 0.45, panel, M.planks, NC))
			add(faceBox(parent, seg, side, len, 0.18, 0.16, mid, y0 + 2.75, 0.49, P.wood_light, M.wood, NC))
		end
		if reno.beams then
			add(faceBox(parent, seg, side, len, 0.4, 0.2, mid, y0 + 10.2, 0.5, P.wood_dark, M.wood, NC))
			local posts = math.max(1, math.floor(len / 6))
			for i = 0, posts do
				local along = seg.a + len * i / posts
				along = math.clamp(along, seg.a + 0.25, seg.b - 0.25)
				add(faceBox(parent, seg, side, 0.45, height - 0.2, 0.14, along, y0 + (height - 0.2) / 2, 0.48, P.wood_dark, M.wood, NC))
			end
		end
	end
	return parts
end

-- Kyoto machiya street front: koshi lattice band, timber frame and inu-yarai bamboo fence.
-- avoid = list of {from, to} ranges along the wall to keep clear (doors).
-- opts = { koshi = bool (timber bands and lattice), bamboo = bool (inu-yarai fence) }
function B.facadeDetail(parent, seg, y0, side, avoid, opts)
	opts = opts or { koshi = true, bamboo = true }
	local len = seg.b - seg.a
	local mid = (seg.a + seg.b) / 2
	local NC = { collide = false, shadow = false }
	local function add(p)
		p.CanQuery = false
		tag(p, "Roof")
		return p
	end
	if opts.koshi then
		-- timber frame bands
		add(faceBox(parent, seg, side, len, 0.35, 0.16, mid, y0 + 4.5, 0.68, P.wood_dark, M.wood, NC))
		add(faceBox(parent, seg, side, len, 0.3, 0.16, mid, y0 + 9.6, 0.68, P.wood_dark, M.wood, NC))
		-- koshi lattice (lower band)
		add(faceBox(parent, seg, side, len, 0.18, 0.2, mid, y0 + 1.5, 0.72, P.wood_dark, M.wood, NC))
		add(faceBox(parent, seg, side, len, 0.18, 0.2, mid, y0 + 4.15, 0.72, P.wood_dark, M.wood, NC))
		local step = 0.42
		for i = 0, math.floor(len / step) do
			local along = seg.a + 0.2 + i * step
			if along < seg.b - 0.2 and not inAvoid(along, avoid) then
				add(faceBox(parent, seg, side, 0.13, 2.6, 0.12, along, y0 + 2.85, 0.76, P.wood, M.wood, NC))
			end
	end
	end
	if not opts.bamboo then
		return
	end
	-- inu-yarai: curved bamboo fence leaning against the base of the wall
	for i = 0, math.floor(len / 0.55) do
		local along = seg.a + 0.3 + i * 0.55
		if along < seg.b - 0.3 and not inAvoid(along, avoid) then
			local a = (seg.axis == "z") and Vector3.new(along, y0 + 0.02, seg.line + side * 1.45) or Vector3.new(seg.line + side * 1.45, y0 + 0.02, along)
			local b = (seg.axis == "z") and Vector3.new(along, y0 + 1.25, seg.line + side * 0.8) or Vector3.new(seg.line + side * 0.8, y0 + 1.25, along)
			local midp = (a + b) / 2
			local rod = Kit.part(parent, Vector3.new((b - a).Magnitude, 0.14, 0.14), CFrame.lookAt(midp, b) * CFrame.Angles(0, math.rad(90), 0), P.bamboo, M.wood, { collide = false, shadow = false, shape = Enum.PartType.Cylinder })
			add(rod)
		end
	end
	for _, h in ipairs({ 0.45, 0.95 }) do
		local out = 1.45 - (h / 1.25) * 0.65
		add(faceBox(parent, seg, side, len, 0.08, 0.08, mid, y0 + h, out + 0.04, P.bamboo_green, M.wood, NC))
	end
end

-- Details around the main entrance: parked sliding lattice doors, stone step, salt cones, pines
function B.entranceDetail(parent, o, y0)
	local NC = { collide = false, shadow = false }
	local z = o.at - 0.75
	for _, sgn in ipairs({ -1, 1 }) do
		local edge = sgn < 0 and o.from or o.to
		local cx = edge + sgn * 1.45
		-- sliding koshi-do door pushed aside
		Kit.box(parent, 2.8, 8.4, 0.12, cx, y0 + 4.3, z, P.wood_dark, M.wood, NC)
		Kit.box(parent, 2.4, 3.6, 0.04, cx, y0 + 6.3, z - 0.08, P.paper_warm, M.fabric, NC)
		for k = 0, 5 do
			Kit.box(parent, 0.1, 7.8, 0.08, cx - 1.1 + k * 0.44, y0 + 4.3, z - 0.11, P.wood, M.wood, NC)
		end
		Kit.box(parent, 2.8, 0.12, 0.1, cx, y0 + 4.3, z - 0.12, P.wood, M.wood, NC)
		-- morishio: salt cone on a small dish
		local sx = edge - sgn * 0.45
		Kit.cyl(parent, 0.6, 0.06, sx, y0 + 0.03, o.at - 1.0, P.porcelain, M.smooth, NC)
		for k = 0, 3 do
			Kit.cyl(parent, 0.42 - k * 0.1, 0.12, sx, y0 + 0.12 + k * 0.11, o.at - 1.0, P.white, M.sand, NC)
		end
		-- potted pine
		local px = edge + sgn * 3.6
		Kit.cyl(parent, 1.1, 0.9, px, y0 - 0.4 + 0.45, o.at - 1.25, P.indigo, M.smooth, NC)
		Kit.cyl(parent, 0.18, 1.3, px, y0 + 1.1, o.at - 1.25, P.wood_dark, M.wood, NC)
		Kit.blob(parent, 1.4, 0.5, 1.1, px - 0.2, y0 + 1.75, o.at - 1.25, P.leaf_dark, M.leafy, NC)
		Kit.blob(parent, 1.0, 0.4, 0.9, px + 0.25, y0 + 2.15, o.at - 1.25, P.leaf_dark, M.leafy, NC)
	end
	-- stone step
	Kit.box(parent, o.to - o.from - 0.6, 0.3, 1.2, (o.from + o.to) / 2, -0.25, o.at - 1.0, P.stone, M.granite, { collide = true })
end

-- Loading door: rolled-up shutter, hazard stripe and a small sign
-- marked = renovation "tidy storage" (hazard stripes and the loading sign)
function B.shutter(parent, o, y0, height, marked)
	local NC = { collide = false, shadow = false }
	local len = o.to - o.from
	local cx = (o.from + o.to) / 2
	local z = o.at - 0.5
	Kit.box(parent, len + 0.4, 1.1, 0.9, cx, y0 + height + 0.1, z - 0.2, P.steel, M.metal, NC)
	for k = 0, 3 do
		Kit.box(parent, len, 0.22, 0.06, cx, y0 + height - 0.4 - k * 0.3, z, P.metal, M.metal, NC)
	end
	if not marked then
		return
	end
	for k = 0, math.floor(len / 0.6) do
		local stripe = Kit.box(parent, 0.3, 0.02, 0.6, o.from + 0.3 + k * 0.6, y0 - 0.33, o.at - 1.2, k % 2 == 0 and P.neon_yellow or P.black, M.smooth, NC)
		stripe.CanQuery = false
	end
	local plate = Kit.box(parent, 2.2, 0.7, 0.06, o.to + 1.6, y0 + 7, z, P.white, M.smooth, NC)
	Kit.text(plate, Enum.NormalId.Front, "搬入口", { color = "#2B2320", font = JP_FONT })
end

function B.parapet(parent, seg, y0)
	local len = seg.b - seg.a
	local cx = seg.axis == "z" and (seg.a + seg.b) / 2 or seg.line
	local cz = seg.axis == "z" and seg.line or (seg.a + seg.b) / 2
	local p = Kit.box(parent, seg.axis == "z" and len + 0.8 or 0.7, 0.8, seg.axis == "z" and 0.7 or len + 0.8, cx, y0 + 0.4, cz, P.cream, M.plaster, { collide = true })
	tag(p, "Roof")
	local cap = Kit.box(parent, seg.axis == "z" and len + 1 or 1, 0.22, seg.axis == "z" and 1 or len + 1, cx, y0 + 0.9, cz, P.tile, M.roof, { collide = false, shadow = false })
	tag(cap, "Roof")
	return p
end

-- Paper-lit lattice window on an exterior wall
-- fancy = renovation "lattice windows" (kumiko grid, sill and flower box); else a plain frame
function B.window(parent, along, y, seg, outsideSign, w, h, fancy)
	local off = outsideSign * 0.65
	local x = seg.axis == "z" and along or seg.line + off
	local z = seg.axis == "z" and seg.line + off or along
	local sx, sz = seg.axis == "z" and w or 0.1, seg.axis == "z" and 0.1 or w
	local glow = Kit.box(parent, sx, h, sz, x, y, z, P.paper_warm, M.neon, { collide = false })
	glow.Transparency = 0.15
	tag(glow, "Roof")
	local cols, rows = math.max(2, math.floor(w / 0.8)), math.max(2, math.floor(h / 0.8))
	if not fancy then
		cols, rows = 2, 1
	end
	for i = 0, cols do
		local a = along - w / 2 + w * i / cols
		local bx = seg.axis == "z" and a or x + outsideSign * 0.06
		local bz = seg.axis == "z" and z + outsideSign * 0.06 or a
		local bar = Kit.box(parent, seg.axis == "z" and 0.1 or 0.08, h, seg.axis == "z" and 0.08 or 0.1, bx, y, bz, P.wood_dark, M.wood, { collide = false, shadow = false })
		tag(bar, "Roof")
	end
	if fancy then
		-- sill with a flower box
		local sillA = seg.axis == "z" and w + 0.6 or 0.5
		local sillB = seg.axis == "z" and 0.5 or w + 0.6
		local sill = Kit.box(parent, sillA, 0.18, sillB, x + (seg.axis == "x" and outsideSign * 0.2 or 0), y - h / 2 - 0.12, z + (seg.axis == "z" and outsideSign * 0.2 or 0), P.wood_dark, M.wood, { collide = false, shadow = false })
		tag(sill, "Roof")
		for k = 0, math.floor(w / 0.6) do
			local fa = along - w / 2 + 0.3 + k * 0.6
			local fx = seg.axis == "z" and fa or x + outsideSign * 0.3
			local fz = seg.axis == "z" and z + outsideSign * 0.3 or fa
			local leaf = Kit.blob(parent, 0.55, 0.4, 0.55, fx, y - h / 2 + 0.12, fz, k % 3 == 1 and P.sakura_dark or P.leaf, M.leafy, { collide = false, shadow = false })
			tag(leaf, "Roof")
	end
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
