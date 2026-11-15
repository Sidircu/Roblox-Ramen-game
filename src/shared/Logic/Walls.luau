--!nonstrict
-- Computes wall and railing segments from the unlocked zones (pure).
-- Segment: { axis = "z" (runs along X at z = line) | "x" (runs along Z at x = line), line, a, b, floor, kind }
-- Wall segments separate indoor cells from outside or from another room.
-- Railings surround outdoor zones (and stair holes on upper floors).
local Walls = {}

local CELL = 1

local function key(x, z)
	return x .. "," .. z
end

local function floorCells(zones, floor)
	local cells = {}
	for _, z in ipairs(zones) do
		if z.floor == floor then
			local r = z.rect
			for x = r[1], r[3] - CELL, CELL do
				for zz = r[2], r[4] - CELL, CELL do
					cells[key(x, zz)] = { room = z.outdoor and "_outdoor" or (z.room or "main"), outdoor = z.outdoor, zone = z.id }
				end
			end
		end
	end
	return cells
end

local function merge(edges, floor, kind)
	-- edges: list of {axis, line, a, b}; merge contiguous ones on the same line
	local groups = {}
	for _, e in ipairs(edges) do
		local k = e.axis .. ":" .. e.line
		groups[k] = groups[k] or { axis = e.axis, line = e.line, list = {} }
		table.insert(groups[k].list, e)
	end
	local out = {}
	for _, g in pairs(groups) do
		table.sort(g.list, function(p, q)
			return p.a < q.a
		end)
		local cur = nil
		for _, e in ipairs(g.list) do
			if cur and math.abs(cur.b - e.a) < 1e-6 then
				cur.b = e.b
			else
				if cur then
					table.insert(out, cur)
				end
				cur = { axis = g.axis, line = g.line, a = e.a, b = e.b, floor = floor, kind = kind }
			end
		end
		if cur then
			table.insert(out, cur)
		end
	end
	table.sort(out, function(p, q)
		if p.axis ~= q.axis then
			return p.axis < q.axis
		end
		if p.line ~= q.line then
			return p.line < q.line
		end
		return p.a < q.a
	end)
	return out
end

-- Removes the intervals of `cuts` ({axis, at, from, to}) from the segments.
local function cut(segments, cuts)
	local result = segments
	for _, c in ipairs(cuts) do
		local next = {}
		for _, s in ipairs(result) do
			if s.axis == c.axis and math.abs(s.line - c.at) < 1e-6 and c.to > s.a and c.from < s.b then
				if c.from > s.a then
					table.insert(next, { axis = s.axis, line = s.line, a = s.a, b = c.from, floor = s.floor, kind = s.kind })
				end
				if c.to < s.b then
					table.insert(next, { axis = s.axis, line = s.line, a = c.to, b = s.b, floor = s.floor, kind = s.kind })
				end
			else
				table.insert(next, s)
			end
		end
		result = next
	end
	return result
end

-- zones: unlocked zone configs; openings: list; stairs: list {floor, rect}
function Walls.compute(zones, openings, stairs)
	local floors = {}
	for _, z in ipairs(zones) do
		floors[z.floor] = true
	end
	local result = {}
	for floor in pairs(floors) do
		local cells = floorCells(zones, floor)
		local below = floor > 0 and floorCells(zones, floor - 1) or nil
		local wallEdges, railEdges = {}, {}
		for k, c in pairs(cells) do
			local sx, sz = k:match("^(-?[%d%.]+),(-?[%d%.]+)$")
			local x, z = tonumber(sx), tonumber(sz)
			local neighbours = {
				{ dx = -CELL, dz = 0, axis = "x", line = x, a = z, b = z + CELL },
				{ dx = CELL, dz = 0, axis = "x", line = x + CELL, a = z, b = z + CELL },
				{ dx = 0, dz = -CELL, axis = "z", line = z, a = x, b = x + CELL },
				{ dx = 0, dz = CELL, axis = "z", line = z + CELL, a = x, b = x + CELL },
			}
			for _, nb in ipairs(neighbours) do
				local other = cells[key(x + nb.dx, z + nb.dz)]
				local edge = { axis = nb.axis, line = nb.line, a = nb.a, b = nb.b }
				if not c.outdoor then
					if not other then
						table.insert(wallEdges, edge)
					elseif other.room ~= c.room and not other.outdoor and c.room < other.room then
						table.insert(wallEdges, edge)
					elseif other.outdoor then
						table.insert(wallEdges, edge)
					end
				else
					if not other then
						-- outdoor edge that faces nothing: railing, unless the building below continues (rooftop parapet still needed)
						table.insert(railEdges, edge)
					end
				end
			end
		end
		local floorOpenings = {}
		for _, o in ipairs(openings) do
			if o.floor == floor then
				table.insert(floorOpenings, o)
			end
		end
		local walls = cut(merge(wallEdges, floor, "wall"), floorOpenings)
		local gaps = {}
		for _, z in ipairs(zones) do
			if z.floor == floor and z.gaps then
				for _, g in ipairs(z.gaps) do
					table.insert(gaps, g)
				end
			end
		end
		local rails = cut(merge(railEdges, floor, "rail"), gaps)
		-- railing around stair holes on this floor (stairs that start on floor - 1)
		for _, s in ipairs(stairs) do
			if s.floor == floor - 1 then
				local r = s.rect
				table.insert(rails, { axis = "x", line = r[1], a = r[2], b = r[4], floor = floor, kind = "rail" })
				table.insert(rails, { axis = "x", line = r[3], a = r[2], b = r[4], floor = floor, kind = "rail" })
				table.insert(rails, { axis = "z", line = r[2], a = r[1], b = r[3], floor = floor, kind = "rail" })
			end
		end
		local _ = below
		result[floor] = { walls = walls, rails = rails }
	end
	return result
end

-- Distance from point to segment (on the XZ plane)
function Walls.distance(seg, x, z)
	if seg.axis == "z" then
		local cx = math.clamp(x, seg.a, seg.b)
		return math.sqrt((x - cx) ^ 2 + (z - seg.line) ^ 2)
	end
	local cz = math.clamp(z, seg.a, seg.b)
	return math.sqrt((x - seg.line) ^ 2 + (z - cz) ^ 2)
end

-- Position along the segment for a point
function Walls.along(seg, x, z)
	if seg.axis == "z" then
		return x
	end
	return z
end

return Walls
