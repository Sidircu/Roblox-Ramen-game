--!nonstrict
-- Building shell pieces used by the server WorldService (floors, walls, roof, stairs, facade).
-- All coordinates are world coordinates (the plot origin is the world origin).
local CollectionService = game:GetService("CollectionService")

local Kit = require(script.Parent.Parent.Kit)
local P = require(script.Parent.Parent.Palette)
local Color = require(script.Parent.Parent.Parent.Util.Color)
local M = P.M

local Signs = require(script.Parent.Parent.Parent.Config.Signs)

local JP_FONT = Font.new("rbxasset://fonts/families/FredokaOne.json", Enum.FontWeight.Bold)
-- the letters of each style of shop sign (Config/Signs)
local SIGN_FONTS = {
	wood = Font.fromEnum(Enum.Font.Merriweather),
	lacquer = Font.fromEnum(Enum.Font.Fondamento),
	noren = Font.fromEnum(Enum.Font.PermanentMarker),
	neon = Font.fromEnum(Enum.Font.FredokaOne),
	lanterns = Font.fromEnum(Enum.Font.LuckiestGuy),
}
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

-- The noren print (the word ramen and a white bowl crest) drawn on the cloth itself. The whole
-- design is laid out across the curtain and every panel shows its own slice of it, so the print
-- sways with the fabric and is cut by the slits between panels like a real noren.
-- offset = studs from the design's left edge (as seen on this face) to the panel's left edge.
local function norenPrint(cloth, face, width, height, offset)
	local pps = 60
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Print"
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = pps
	gui.LightInfluence = 1
	gui.Parent = cloth
	local design = Instance.new("Frame")
	design.BackgroundTransparency = 1
	design.Position = UDim2.fromOffset(-offset * pps, 0)
	design.Size = UDim2.fromOffset(width * pps, height * pps)
	design.Parent = gui
	local white = Color.of(P.white)
	-- x, y: centre in studs from the design's top-left corner
	local function shape(parent, x, y, w, h, color, round, rot)
		local blot = Instance.new("Frame")
		blot.AnchorPoint = Vector2.new(0.5, 0.5)
		blot.Position = UDim2.fromOffset(x * pps, y * pps)
		blot.Size = UDim2.fromOffset(w * pps, h * pps)
		blot.BackgroundColor3 = color
		blot.BorderSizePixel = 0
		blot.Rotation = rot or 0
		if round then
			local c = Instance.new("UICorner")
			c.CornerRadius = UDim.new(round, 0)
			c.Parent = blot
		end
		blot.Parent = parent
		return blot
	end
	local word = Instance.new("TextLabel")
	word.AnchorPoint = Vector2.new(0.5, 0.5)
	word.Position = UDim2.fromOffset(width / 2 * pps, 0.66 * pps)
	word.Size = UDim2.fromOffset((width - 0.4) * pps, 1.05 * pps)
	word.BackgroundTransparency = 1
	word.Text = "ら ー め ん"
	word.TextScaled = true
	word.TextColor3 = white
	word.FontFace = JP_FONT
	word.AutoLocalize = false
	word.Parent = design
	-- bowl: the lower half of an ellipse, a rim line and a small foot
	local cx = width / 2
	local clip = Instance.new("Frame")
	clip.AnchorPoint = Vector2.new(0.5, 0)
	clip.Position = UDim2.fromOffset(cx * pps, 2.2 * pps)
	clip.Size = UDim2.fromOffset(1.8 * pps, 0.66 * pps)
	clip.BackgroundTransparency = 1
	clip.ClipsDescendants = true
	clip.Parent = design
	shape(clip, 0.9, 0, 1.8, 1.32, white, 0.5)
	shape(design, cx, 2.2, 1.95, 0.09, white, 0.5)
	shape(design, cx, 2.9, 0.62, 0.1, white, 0.3)
	-- noodles lifted out of the bowl and two chopsticks
	for k = -1, 1 do
		shape(design, cx + k * 0.2, 1.86, 0.07, 0.6, white, 0.5)
	end
	for k = 0, 1 do
		shape(design, cx + 0.42 + k * 0.15, 1.72, 0.06, 1.0, white, 0.5, 28)
	end
	return gui
end

-- Fixed noren curtain hanging in the entrance (customers walk through it)
function B.entranceNoren(parent, o, y0)
	local len = o.to - o.from
	local cx = (o.from + o.to) / 2
	local z = o.at - 0.6
	Kit.cylH(parent, 0.18, len, cx, y0 + 8.7, z, P.wood_dark, M.wood, { collide = false })
	local panels = 4
	local h = 3.2
	local pw = len / panels - 0.12
	for i = 0, panels - 1 do
		local x = o.from + len / panels * (i + 0.5)
		local cloth = Kit.box(parent, pw, h, 0.06, x, y0 + 7, z, P.indigo, M.fabric, { collide = false })
		cloth.CanQuery = false
		cloth:SetAttribute("Animate", "sway")
		-- the front (street side, -Z) shows world +X on its left; the back shows world -X on its left
		norenPrint(cloth, Enum.NormalId.Front, len, h, o.to - (x + pw / 2))
		norenPrint(cloth, Enum.NormalId.Back, len, h, (x - pw / 2) - o.from)
	end
end

function B.railing(parent, seg, y0, color)
	-- balustrade like the stairs': square posts with caps every few studs, a handrail on top and
	-- slim balusters (no board across the middle)
	local len = seg.b - seg.a
	local h = 3.2
	local cx = seg.axis == "z" and (seg.a + seg.b) / 2 or seg.line
	local cz = seg.axis == "z" and seg.line or (seg.a + seg.b) / 2
	local dark = color or P.wood_dark
	local rail = Kit.box(parent, seg.axis == "z" and len or 0.34, 0.24, seg.axis == "z" and 0.34 or len, cx, y0 + h, cz, dark, M.wood, { collide = true })
	tag(rail, "Wall", { FloorIndex = seg.floor, Rail = true })
	-- invisible blocker so nobody falls off
	local block = Kit.box(parent, seg.axis == "z" and len or 0.4, h + 1, seg.axis == "z" and 0.4 or len, cx, y0 + (h + 1) / 2, cz, P.white, M.smooth, { collide = true, transparency = 1, shadow = false })
	block.CanQuery = false
	local function at(along)
		return seg.axis == "z" and along or seg.line, seg.axis == "z" and seg.line or along
	end
	local posts = math.max(1, math.floor(len / 4 + 0.5))
	for i = 0, posts do
		local x, z = at(seg.a + len * i / posts)
		Kit.box(parent, 0.45, h + 0.3, 0.45, x, y0 + (h + 0.3) / 2, z, dark, M.wood, { collide = false })
		Kit.box(parent, 0.62, 0.18, 0.62, x, y0 + h + 0.39, z, dark, M.wood, { collide = false, shadow = false })
	end
	local n = math.max(2, math.floor(len / 1.4))
	for i = 1, n - 1 do
		local x, z = at(seg.a + len * i / n)
		Kit.box(parent, 0.14, h - 0.1, 0.14, x, y0 + (h - 0.1) / 2, z, P.wood_light, M.wood, { collide = false, shadow = false })
	end
end

-- Paper lantern (chochin) hanging from the ceiling at height `top`: a cord, dark caps, a glowing
-- paper body with two ribs and a warm light inside. Returns its parts (none can be clicked).
function B.pendantLantern(parent, x, top, z)
	local NQ = { collide = false, shadow = false }
	local parts = {}
	local function add(p)
		p.CanQuery = false
		table.insert(parts, p)
		return p
	end
	local bodyY = top - 2.9
	add(Kit.box(parent, 0.08, top - (bodyY + 0.75), 0.08, x, (top + bodyY + 0.75) / 2, z, P.black, M.smooth, NQ))
	add(Kit.cyl(parent, 0.7, 0.2, x, bodyY + 0.68, z, P.wood_black, M.wood, NQ))
	local body = add(Kit.blob(parent, 1.35, 1.35, 1.35, x, bodyY, z, P.paper_warm, M.neon, NQ))
	body.Transparency = 0.05
	add(Kit.cyl(parent, 0.7, 0.18, x, bodyY - 0.66, z, P.wood_black, M.wood, NQ))
	for _, dy in ipairs({ -0.3, 0.3 }) do
		add(Kit.cyl(parent, 1.33, 0.05, x, bodyY + dy, z, P.lacquer, M.smooth, NQ))
	end
	Kit.light(body, "Point", P.lamp_warm, 22, 0.7, { night = false })
	return parts
end

-- Staircase in the hako-kaidan style (the Japanese chest of drawers under the stairs):
-- * flights of light treads with a dark nosing and closed risers between closed stringers;
-- * a flight that starts on the floor has solid sides down to the floor (drawers in the side that
--   faces the room, s.drawerSide), a flight that starts higher has a sloped board underneath;
-- * the landing sits on a chest with drawers; newel posts with caps, handrails and balusters on
--   both sides of every flight and on the landing's outer sides, with invisible guards so nobody
--   falls off. s = normalised stairs (Logic/Geometry.stairs)
function B.stairs(parent, s, y0, rise)
	if s[1] then
		s = { flights = { { rect = s, dir = "+z", from = 0, to = 1 } }, rects = { s } }
	end
	local NC = { collide = false, shadow = false }
	local dark, mid, light, treadColor = P.wood_dark, P.wood, P.wood_light, P.hinoki
	local STEP, RAIL_H, SIDE = 0.58, 3.2, 0.35

	-- point on a flight: t = distance from the start edge, u = offset across the flight
	local function at(f, t, u)
		local r = f.rect
		if f.dir == "+z" then
			return (r[1] + r[3]) / 2 + u, r[2] + t
		elseif f.dir == "+x" then
			return r[1] + t, (r[2] + r[4]) / 2 + u
		end
		return r[3] - t, (r[2] + r[4]) / 2 + u
	end
	local function dims(f)
		local r = f.rect
		if f.dir == "+z" then
			return r[4] - r[2], r[3] - r[1]
		end
		return r[3] - r[1], r[4] - r[2]
	end
	-- a part's +Z turned towards the way the flight rises
	local function facing(f)
		if f.dir == "+x" then
			return CFrame.Angles(0, math.rad(90), 0)
		elseif f.dir == "-x" then
			return CFrame.Angles(0, math.rad(-90), 0)
		end
		return CFrame.new()
	end
	local function boxAlong(f, t, u, len, width, y, h, color, mat, props)
		local x, z = at(f, t, u)
		local sx, sz = width, len
		if f.dir ~= "+z" then
			sx, sz = len, width
		end
		return Kit.box(parent, sx, h, sz, x, y, z, color, mat, props)
	end
	local function beam(a, b, size, color, props, mat)
		local mid3 = (a + b) / 2
		return Kit.part(parent, Vector3.new(size.X, size.Y, (b - a).Magnitude), CFrame.lookAt(mid3, b), color, mat or M.wood, props)
	end
	local function newel(x, z, yBase)
		local h = RAIL_H + 0.5
		Kit.box(parent, 0.5, h, 0.5, x, yBase + h / 2, z, dark, M.wood, { collide = true })
		Kit.box(parent, 0.72, 0.2, 0.72, x, yBase + h + 0.1, z, dark, M.wood, NC)
		Kit.ball(parent, 0.34, x, yBase + h + 0.36, z, light, M.wood, NC)
	end
	-- handrail on balusters from (x0, z0) at height h0 to (x1, z1) at h1, with a guard
	local function balustrade(x0, z0, h0, x1, z1, h1)
		beam(Vector3.new(x0, h0 + RAIL_H, z0), Vector3.new(x1, h1 + RAIL_H, z1), Vector3.new(0.34, 0.24, 0), dark, NC)
		local len = (Vector3.new(x1, 0, z1) - Vector3.new(x0, 0, z0)).Magnitude
		local n = math.max(2, math.floor(len / 0.9))
		for i = 1, n - 1 do
			local t = i / n
			local x, z = x0 + (x1 - x0) * t, z0 + (z1 - z0) * t
			local h = h0 + (h1 - h0) * t
			Kit.box(parent, 0.15, RAIL_H - 0.1, 0.15, x, h + (RAIL_H - 0.1) / 2, z, light, M.wood, NC)
		end
		local guard = beam(Vector3.new(x0, h0 + 2, z0), Vector3.new(x1, h1 + 2, z1), Vector3.new(0.3, 4, 0), P.white, { collide = true, transparency = 1, shadow = false }, M.smooth)
		guard.CanQuery = false
	end
	-- a drawer front with a small dark handle on a vertical face (normal along +X or +Z)
	local function drawer(x, y, z, w, h, alongX, out)
		local sx, sz = alongX and w or 0.06, alongX and 0.06 or w
		local ox, oz = alongX and 0 or out * 0.03, alongX and out * 0.03 or 0
		Kit.box(parent, sx, h, sz, x + ox, y, z + oz, light, M.wood, NC)
		Kit.box(parent, alongX and 0.6 or 0.08, 0.12, alongX and 0.08 or 0.6, x + ox * 2.4, y + h * 0.18, z + oz * 2.4, dark, M.metal, NC)
	end

	for fi, f in ipairs(s.flights or {}) do
		local along, width = dims(f)
		local h0, h1 = y0 + f.from * rise, y0 + f.to * rise
		local n = math.max(4, math.floor((h1 - h0) / STEP + 0.5))
		local depth = along / n
		local riser = (h1 - h0) / n
		local inner = width - 2 * SIDE
		for k = 0, n - 1 do
			local top = h0 + (k + 1) * riser
			local tread = boxAlong(f, (k + 0.5) * depth + 0.04, 0, depth + 0.1, inner, top - 0.11, 0.22, treadColor, M.wood, { collide = true })
			tread.Name = "Step"
			tag(tread, "Floor", { FloorIndex = -1, Stairs = true })
			local rs = boxAlong(f, k * depth + 0.06, 0, 0.1, inner, top - riser / 2 - 0.11, riser, mid, M.wood, { collide = true })
			tag(rs, "Floor", { FloorIndex = -1, Stairs = true })
			boxAlong(f, k * depth + 0.01, 0, 0.08, inner, top - 0.02, 0.07, dark, M.wood, NC)
		end
		local floorStart = math.abs(h0 - y0) < 0.01
		for _, side in ipairs({ -1, 1 }) do
			local u = side * (width / 2 - SIDE / 2)
			-- closed stringer following the steps
			local ax, az = at(f, 0, u)
			local bx, bz = at(f, along, u)
			beam(Vector3.new(ax, h0 + riser * 0.6, az), Vector3.new(bx, h1 + riser * 0.1, bz), Vector3.new(SIDE, 1.3, 0), dark, NC)
			if floorStart then
				-- solid side down to the floor
				local hh = h1 - y0 - 0.25
				local cx, cz = at(f, along / 2, u)
				Kit.wedge(parent, SIDE - 0.05, hh, along, CFrame.new(cx, y0 + hh / 2, cz) * facing(f), mid, M.wood, { collide = true, shadow = false })
				-- drawers in the side facing the room
				if s.drawerSide == side then
					local out = side
					local alongX = f.dir == "+z" and false or true
					for row, band in ipairs({ { 0.35, 1.45 }, { 1.85, 2.95 } }) do
						local count = row == 1 and 4 or 3
						local t0 = row == 1 and 0.3 or 0.52
						for i = 0, count - 1 do
							local ta = along * (t0 + (0.98 - t0) * i / count)
							local tb = along * (t0 + (0.98 - t0) * (i + 1) / count)
							local slopeAt = y0 + (ta / along) * hh
							if band[2] + 0.35 < slopeAt then
								local dx, dz = at(f, (ta + tb) / 2, u + out * (SIDE / 2))
								drawer(dx, y0 + (band[1] + band[2]) / 2, dz, tb - ta - 0.18, band[2] - band[1], alongX, out)
							end
						end
					end
				end
			end
			-- handrail with balusters on both sides (newel posts at the foot of each flight)
			local rx0, rz0 = at(f, 0.25, u)
			local rx1, rz1 = at(f, along, u)
			balustrade(rx0, rz0, h0 + riser * 0.5, rx1, rz1, h1)
			newel(rx0, rz0, h0)
		end
		if not floorStart then
			-- sloped board under a flight that starts high up
			local ax, az = at(f, 0, 0)
			local bx, bz = at(f, along, 0)
			beam(Vector3.new(ax, h0 - 0.3, az), Vector3.new(bx, h1 - riser - 0.3, bz), Vector3.new(width - 0.1, 0.3, 0), mid, NC)
			-- posts at the top of the last flight, where it meets the floor above
			for _, side in ipairs({ -1, 1 }) do
				local tx, tz = at(f, along, side * (width / 2 - SIDE / 2))
				newel(tx, tz, h1)
			end
		end
	end
	-- landing on a chest of drawers, posts at its corners and rails on its outer sides
	if s.landing then
		local r = s.landing
		local hy = y0 + rise * 0.5
		local lw, ld = r[3] - r[1], r[4] - r[2]
		local cx, cz = (r[1] + r[3]) / 2, (r[2] + r[4]) / 2
		local land = Kit.box(parent, lw, 0.4, ld, cx, hy - 0.2, cz, treadColor, M.wood, { collide = true })
		tag(land, "Floor", { FloorIndex = -1, Stairs = true })
		Kit.box(parent, lw + 0.12, 0.28, ld + 0.12, cx, hy - 0.5, cz, dark, M.wood, NC)
		if s.landingBase then
			local bh = hy - 0.64 - y0
			Kit.box(parent, lw - 0.3, bh, ld - 0.3, cx, y0 + bh / 2, cz, mid, M.wood, { collide = true })
			for _, c in ipairs({ { r[1] + 0.2, r[2] + 0.2 }, { r[3] - 0.2, r[2] + 0.2 }, { r[1] + 0.2, r[4] - 0.2 }, { r[3] - 0.2, r[4] - 0.2 } }) do
				Kit.box(parent, 0.4, bh, 0.4, c[1], y0 + bh / 2, c[2], dark, M.wood, NC)
			end
			-- drawers (2 x 2) on the three faces that show (the first flight covers the fourth)
			local faces = {
				{ x = r[1] + 0.12, z = cz, alongX = false, out = -1, len = ld },
				{ x = r[3] - 0.12, z = cz, alongX = false, out = 1, len = ld },
				{ x = cx, z = r[4] - 0.12, alongX = true, out = 1, len = lw },
			}
			for _, fc in ipairs(faces) do
				for col = 0, 1 do
					for row = 0, 1 do
						local off = (col - 0.5) * (fc.len / 2)
						local y = y0 + 0.5 + bh * (0.25 + row * 0.42)
						local dx = fc.alongX and fc.x + off or fc.x
						local dz = fc.alongX and fc.z or fc.z + off
						drawer(dx, y, dz, fc.len / 2 - 0.6, bh * 0.34, fc.alongX, fc.out)
					end
				end
			end
		else
			for _, c in ipairs(s.landingPosts or { { r[3] - 0.3, r[4] - 0.3 } }) do
				Kit.box(parent, 0.5, hy - y0, 0.5, c[1], y0 + (hy - y0) / 2, c[2], dark, M.wood, { collide = true })
			end
		end
		for _, seg in ipairs(s.landingRails or {}) do
			balustrade(seg[1], seg[2], hy, seg[3], seg[4], hy)
			newel(seg[1], seg[2], hy)
			newel(seg[3], seg[4], hy)
		end
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

-- The restaurant's own sign over the door: the owner's name (filtered, `sign.shown`), style and
-- colours from Config/Signs (sign = Data.sign; nil = the classic board). Returns the Model
-- "ShopSign"; its PrimaryPart carries the letters on its front (-Z, towards the street).
function B.shopSign(parent, sign, deluxe)
	sign = sign or Signs.Default
	local cfg = Signs.Facade
	local x, y, z, w, h = cfg.x, cfg.y, cfg.z, cfg.width, cfg.height
	local style = Signs.StyleById[sign.style or ""] and sign.style or Signs.Default.style
	local boardC = Color.hex((Signs.ColorById[sign.board or ""] or Signs.ColorById[Signs.Default.board]).hex)
	local textC = Color.hex((Signs.ColorById[sign.text or ""] or Signs.ColorById[Signs.Default.text]).hex)
	local name = (sign.shown and sign.shown ~= "") and sign.shown or nil
	local NC = { collide = false, shadow = false }
	local m = Kit.model("ShopSign")
	local face
	if style == "lacquer" then
		-- a glossy board with a gold frame
		face = Kit.box(m, w, h, 0.4, x, y, z, boardC, M.smooth, { collide = false, reflectance = 0.12 })
		for _, dy in ipairs({ -h / 2, h / 2 }) do
			Kit.box(m, w + 0.3, 0.16, 0.48, x, y + dy, z, P.gold, M.foil, NC)
		end
		for _, sx in ipairs({ -1, 1 }) do
			Kit.box(m, 0.16, h + 0.16, 0.48, x + sx * w / 2, y, z, P.gold, M.foil, NC)
		end
	elseif style == "noren" then
		-- three cloth panels with slits between them, hanging from a rod with round ends
		Kit.cylH(m, 0.22, w + 0.8, x, y + h / 2 + 0.12, z - 0.12, P.wood_dark, M.wood, NC)
		for _, sx in ipairs({ -1, 1 }) do
			Kit.ball(m, 0.36, x + sx * (w / 2 + 0.45), y + h / 2 + 0.12, z - 0.12, P.wood_black, M.wood, NC)
		end
		local pw = (w - 0.3) / 3
		for i = 0, 2 do
			Kit.box(m, pw - 0.14, h, 0.06, x - w / 2 + 0.15 + pw * (i + 0.5), y, z - 0.12, boardC, M.fabric, NC)
		end
		-- the letters run across the three panels
		face = Kit.box(m, w - 0.2, h - 0.3, 0.02, x, y - 0.05, z - 0.17, boardC, M.fabric, NC)
		face.Transparency = 1
	elseif style == "neon" then
		-- glowing letters and a neon tube round a dark board in the board's colour
		face = Kit.box(m, w, h, 0.3, x, y, z, boardC:Lerp(Color3.new(0, 0, 0), 0.55), M.smooth, { collide = false })
		for _, dy in ipairs({ -(h / 2 - 0.12), h / 2 - 0.12 }) do
			Kit.box(m, w - 0.2, 0.1, 0.1, x, y + dy, z - 0.17, textC, M.neon, NC)
		end
		for _, sx in ipairs({ -1, 1 }) do
			Kit.box(m, 0.1, h - 0.24, 0.1, x + sx * (w / 2 - 0.12), y, z - 0.17, textC, M.neon, NC)
		end
		Kit.light(face, "Surface", textC, 12, 1.6, { face = Enum.NormalId.Front })
	else
		-- wood (and lanterns): a board in a dark wooden frame
		Kit.box(m, w, h, 0.4, x, y, z, style == "lanterns" and P.wood_black or P.wood_dark, M.wood, { collide = false })
		face = Kit.box(m, w - 0.4, h - 0.5, 0.05, x, y, z - 0.23, boardC, M.wood, NC)
		if style == "lanterns" then
			-- a paper lantern hanging on each side
			for _, sx in ipairs({ -1, 1 }) do
				local lx = x + sx * (w / 2 + 1.1)
				Kit.box(m, 0.06, 0.5, 0.06, lx, y + 1.15, z - 0.4, P.black, M.smooth, NC)
				Kit.cyl(m, 0.62, 0.16, lx, y + 0.84, z - 0.4, P.wood_black, M.wood, NC)
				local body = Kit.blob(m, 1.2, 1.5, 1.2, lx, y, z - 0.4, P.lacquer, M.smooth, NC)
				Kit.cyl(m, 0.62, 0.16, lx, y - 0.84, z - 0.4, P.wood_black, M.wood, NC)
				Kit.light(body, "Point", P.lamp_warm, 12, 1.2)
			end
		end
	end
	-- the letters: the name (with a small らーめん ・ 寿司 under it) or the classic text
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Letters"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = style == "neon" and 0 or 1
	gui.Brightness = style == "neon" and 2.2 or 1
	gui.Parent = face
	local title = Instance.new("TextLabel")
	title.Name = "Name"
	title.BackgroundTransparency = 1
	title.Position = UDim2.fromScale(0.03, name and 0.02 or 0.08)
	title.Size = UDim2.fromScale(0.94, name and 0.68 or 0.84)
	title.Text = name or Signs.DefaultText
	title.TextScaled = true
	title.TextColor3 = textC
	title.FontFace = name and SIGN_FONTS[style] or JP_FONT
	title.AutoLocalize = false
	title.Parent = gui
	if name then
		local sub = Instance.new("TextLabel")
		sub.Name = "Subtitle"
		sub.BackgroundTransparency = 1
		sub.Position = UDim2.fromScale(0.25, 0.72)
		sub.Size = UDim2.fromScale(0.5, 0.24)
		sub.Text = Signs.Subtitle
		sub.TextScaled = true
		sub.TextColor3 = textC
		sub.TextTransparency = 0.15
		sub.FontFace = JP_FONT
		sub.AutoLocalize = false
		sub.Parent = gui
	end
	-- the deluxe facade adds golden tubes over and under the sign (neon glows already)
	if deluxe and style ~= "neon" then
		for _, dy in ipairs({ -(h / 2 + 0.1), h / 2 + 0.1 }) do
			Kit.box(m, w, 0.1, 0.1, x, y + dy, z - 0.25, P.neon_yellow, M.neon, NC)
		end
		Kit.light(face, "Surface", P.neon_yellow, 12, 1.5, { face = Enum.NormalId.Front })
	end
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") then
			tag(d, "Roof")
		end
	end
	m.PrimaryPart = face
	m.Parent = parent
	return m
end

-- "Open / preparing" plate next to the door; returns the TextLabel
function B.openSign(parent, x, y, z)
	local plate = Kit.box(parent, 1.6, 0.8, 0.1, x, y, z, P.wood_light, M.wood, { collide = false })
	Kit.cyl(parent, 0.04, 0.8, x, y + 0.6, z, P.black, M.fabric, { collide = false })
	local _, label = Kit.text(plate, Enum.NormalId.Front, "準備中", { color = "#2B2320", font = JP_FONT })
	return label, plate
end

-- LED sign on a post on the sidewalk, next to the door: a dark board with OPEN / CLOSED in light
-- letters on both sides (World.paintOpenSign writes them), a thin metal frame, a post and a foot;
-- the board is the model's PrimaryPart (y = height of the board's middle)
function B.ledSign(parent, x, y, z)
	local m = Kit.model("OpenSign")
	local NC = { collide = false, shadow = false }
	Kit.box(m, 1, 0.16, 0.7, x, 0.08, z, P.steel_dark, M.metal)
	Kit.box(m, 0.22, y - 0.6, 0.22, x, (y - 0.6) / 2, z, P.steel_dark, M.metal)
	local board = Kit.box(m, 2.8, 1.25, 0.22, x, y, z, P.charcoal, M.smooth, { collide = false, name = "Board" })
	for _, dy in ipairs({ -0.66, 0.66 }) do
		Kit.box(m, 2.96, 0.1, 0.28, x, y + dy, z, P.steel_dark, M.metal, NC)
	end
	for _, dx in ipairs({ -1.46, 1.46 }) do
		Kit.box(m, 0.1, 1.42, 0.28, x + dx, y, z, P.steel_dark, M.metal, NC)
	end
	for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
		local gui, label = Kit.text(board, face, "OPEN", { color = P.neon_green, glow = true, pps = 60 })
		gui.Name = face == Enum.NormalId.Front and "Front" or "Back"
		label.Name = "Label"
		label.FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json", Enum.FontWeight.Bold)
	end
	local glow = Kit.light(board, "Point", P.neon_green, 8, 1, { night = false })
	glow.Name = "Glow"
	m.PrimaryPart = board
	m.Parent = parent
	return m
end

function B.tag(part, name, attrs)
	return tag(part, name, attrs)
end

return function(Registry)
	Registry.Building = B
end
