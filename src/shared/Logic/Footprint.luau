--!nonstrict
-- 2D oriented rectangles on the XZ plane (pure). A footprint is {x, z, w, d, r} (r in degrees).
local Footprint = {}

function Footprint.new(x, z, w, d, r)
	return { x = x, z = z, w = w, d = d, r = r or 0 }
end

function Footprint.axes(fp)
	local a = math.rad(fp.r)
	-- local X axis and local Z axis expressed in world XZ (rotation around Y)
	local c, s = math.cos(a), math.sin(a)
	return { x = c, z = -s }, { x = s, z = c }
end

function Footprint.corners(fp)
	local ax, az = Footprint.axes(fp)
	local hw, hd = fp.w / 2, fp.d / 2
	local out = {}
	for _, sgn in ipairs({ { -1, -1 }, { 1, -1 }, { 1, 1 }, { -1, 1 } }) do
		table.insert(out, {
			x = fp.x + ax.x * hw * sgn[1] + az.x * hd * sgn[2],
			z = fp.z + ax.z * hw * sgn[1] + az.z * hd * sgn[2],
		})
	end
	return out
end

function Footprint.bounds(fp)
	local minX, minZ, maxX, maxZ = math.huge, math.huge, -math.huge, -math.huge
	for _, c in ipairs(Footprint.corners(fp)) do
		minX = math.min(minX, c.x)
		minZ = math.min(minZ, c.z)
		maxX = math.max(maxX, c.x)
		maxZ = math.max(maxZ, c.z)
	end
	return minX, minZ, maxX, maxZ
end

local function project(corners, axis)
	local mn, mx = math.huge, -math.huge
	for _, c in ipairs(corners) do
		local p = c.x * axis.x + c.z * axis.z
		mn = math.min(mn, p)
		mx = math.max(mx, p)
	end
	return mn, mx
end

-- True when the rectangles overlap by more than `eps` (touching is allowed).
function Footprint.overlaps(a, b, eps)
	eps = eps or 0.05
	local ca, cb = Footprint.corners(a), Footprint.corners(b)
	local a1, a2 = Footprint.axes(a)
	local b1, b2 = Footprint.axes(b)
	for _, axis in ipairs({ a1, a2, b1, b2 }) do
		local amin, amax = project(ca, axis)
		local bmin, bmax = project(cb, axis)
		if amax - eps <= bmin or bmax - eps <= amin then
			return false
		end
	end
	return true
end

function Footprint.inflate(fp, by)
	return { x = fp.x, z = fp.z, w = fp.w + by * 2, d = fp.d + by * 2, r = fp.r }
end

function Footprint.rectToFp(rect)
	local x0, z0, x1, z1 = rect[1], rect[2], rect[3], rect[4]
	return { x = (x0 + x1) / 2, z = (z0 + z1) / 2, w = x1 - x0, d = z1 - z0, r = 0 }
end

function Footprint.pointInRect(x, z, rect, tol)
	tol = tol or 0
	return x >= rect[1] - tol and x <= rect[3] + tol and z >= rect[2] - tol and z <= rect[4] + tol
end

function Footprint.pointIn(fp, x, z, tol)
	tol = tol or 0
	local ax, az = Footprint.axes(fp)
	local dx, dz = x - fp.x, z - fp.z
	local lx = dx * ax.x + dz * ax.z
	local lz = dx * az.x + dz * az.z
	return math.abs(lx) <= fp.w / 2 + tol and math.abs(lz) <= fp.d / 2 + tol
end

-- Sample points (corners, edge midpoints, center) all inside the union of rects.
function Footprint.insideRects(fp, rects, tol)
	tol = tol or 0.01
	local pts = Footprint.corners(fp)
	local n = #pts
	for i = 1, n do
		local a, b = pts[i], pts[i % n + 1]
		table.insert(pts, { x = (a.x + b.x) / 2, z = (a.z + b.z) / 2 })
	end
	table.insert(pts, { x = fp.x, z = fp.z })
	for _, p in ipairs(pts) do
		local inside = false
		for _, r in ipairs(rects) do
			if Footprint.pointInRect(p.x, p.z, r, tol) then
				inside = true
				break
			end
		end
		if not inside then
			return false
		end
	end
	return true
end

-- Footprint of a wall segment {axis, line, a, b} with given thickness.
function Footprint.wallFp(seg, thickness)
	if seg.axis == "z" then
		return { x = (seg.a + seg.b) / 2, z = seg.line, w = seg.b - seg.a, d = thickness, r = 0 }
	end
	return { x = seg.line, z = (seg.a + seg.b) / 2, w = thickness, d = seg.b - seg.a, r = 0 }
end

-- Subtracts rect `hole` from rect `r`; returns up to 4 rects.
function Footprint.subtractRect(r, hole)
	local x0, z0, x1, z1 = r[1], r[2], r[3], r[4]
	local hx0, hz0 = math.max(x0, hole[1]), math.max(z0, hole[2])
	local hx1, hz1 = math.min(x1, hole[3]), math.min(z1, hole[4])
	if hx0 >= hx1 or hz0 >= hz1 then
		return { r }
	end
	local out = {}
	if hz0 > z0 then
		table.insert(out, { x0, z0, x1, hz0 })
	end
	if hz1 < z1 then
		table.insert(out, { x0, hz1, x1, z1 })
	end
	if hx0 > x0 then
		table.insert(out, { x0, hz0, hx0, hz1 })
	end
	if hx1 < x1 then
		table.insert(out, { hx1, hz0, x1, hz1 })
	end
	return out
end

return Footprint
