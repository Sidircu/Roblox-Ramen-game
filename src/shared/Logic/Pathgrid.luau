--!nonstrict
-- Walkability check used when placing objects: every seat must stay reachable from the
-- entrance, the kitchen and the storage must stay reachable, stairs must stay usable.
-- Works on a 0.5-stud grid per floor (pure).
local Footprint = require(script.Parent.Footprint)
local Walls = require(script.Parent.Walls)

local Pathgrid = {}

local CELL = 0.5
local WALL_CLEAR = 0.4 + 0.6 -- half wall thickness + body radius

-- ctx: { zones = {...}, walls = Walls.compute(...) result, stairs = {...}, entrance = {x, z} }
-- obstacles: list of { fp = footprint, floor = n }
-- targets: list of { floor, x, z, radius, label }
function Pathgrid.check(ctx, obstacles, targets, clearance)
	clearance = clearance or 0.8
	local byFloor = {}
	for _, z in ipairs(ctx.zones) do
		byFloor[z.floor] = byFloor[z.floor] or { rects = {} }
		table.insert(byFloor[z.floor].rects, z.rect)
	end
	local grids = {}
	local function grid(floor)
		if grids[floor] then
			return grids[floor]
		end
		local f = byFloor[floor]
		if not f then
			return nil
		end
		local minX, minZ, maxX, maxZ = math.huge, math.huge, -math.huge, -math.huge
		for _, r in ipairs(f.rects) do
			minX, minZ = math.min(minX, r[1]), math.min(minZ, r[2])
			maxX, maxZ = math.max(maxX, r[3]), math.max(maxZ, r[4])
		end
		local nx = math.floor((maxX - minX) / CELL + 0.5)
		local nz = math.floor((maxZ - minZ) / CELL + 0.5)
		local g = { minX = minX, minZ = minZ, nx = nx, nz = nz, free = {} }
		local floorWalls = ctx.walls[floor] or { walls = {}, rails = {} }
		local free = g.free
		-- visit every cell whose center lies inside the box [x0,x1] x [z0,z1]
		local function each(x0, z0, x1, z1, fn)
			local i0 = math.max(0, math.ceil((x0 - minX) / CELL - 0.5))
			local i1 = math.min(nx - 1, math.floor((x1 - minX) / CELL - 0.5))
			local j0 = math.max(0, math.ceil((z0 - minZ) / CELL - 0.5))
			local j1 = math.min(nz - 1, math.floor((z1 - minZ) / CELL - 0.5))
			for i = i0, i1 do
				for j = j0, j1 do
					fn(i, j, minX + (i + 0.5) * CELL, minZ + (j + 0.5) * CELL)
				end
			end
		end
		for _, r in ipairs(f.rects) do
			each(r[1], r[2], r[3], r[4], function(i, j)
				free[i * nz + j] = true
			end)
		end
		local function clearBox(x0, z0, x1, z1)
			each(x0, z0, x1, z1, function(i, j)
				free[i * nz + j] = nil
			end)
		end
		for _, s in ipairs(ctx.stairs or {}) do
			local h = s.hole or s.rect
			if s.floor == floor - 1 then
				clearBox(h[1], h[2], h[3], h[4])
			elseif s.floor == floor then
				-- the stairs themselves are not floor you can walk across
				for _, r in ipairs(s.rects or { s.rect }) do
					clearBox(r[1], r[2], r[3], r[4])
				end
			end
		end
		for _, list in ipairs({ floorWalls.walls, floorWalls.rails }) do
			for _, seg in ipairs(list) do
				if seg.axis == "z" then
					clearBox(seg.a - WALL_CLEAR, seg.line - WALL_CLEAR, seg.b + WALL_CLEAR, seg.line + WALL_CLEAR)
				else
					clearBox(seg.line - WALL_CLEAR, seg.a - WALL_CLEAR, seg.line + WALL_CLEAR, seg.b + WALL_CLEAR)
				end
			end
		end
		for _, o in ipairs(obstacles) do
			if o.floor == floor then
				local fp = Footprint.inflate(o.fp, clearance)
				local bx0, bz0, bx1, bz1 = Footprint.bounds(fp)
				each(bx0, bz0, bx1, bz1, function(i, j, x, z)
					if Footprint.pointIn(fp, x, z) then
						free[i * nz + j] = nil
					end
				end)
			end
		end
		grids[floor] = g
		return g
	end

	local function cellOf(g, x, z)
		return math.floor((x - g.minX) / CELL), math.floor((z - g.minZ) / CELL)
	end

	local reached = {}
	local function flood(floor, sx, sz)
		local g = grid(floor)
		if not g then
			return
		end
		reached[floor] = reached[floor] or {}
		local seen = reached[floor]
		-- start from the nearest free cell within 2 studs of the start point
		local si, sj = cellOf(g, sx, sz)
		local start = nil
		for radius = 0, 4 do
			for di = -radius, radius do
				for dj = -radius, radius do
					local i, j = si + di, sj + dj
					if not start and i >= 0 and j >= 0 and i < g.nx and j < g.nz and g.free[i * g.nz + j] then
						start = { i, j }
					end
				end
			end
			if start then
				break
			end
		end
		if not start then
			return
		end
		local queue = { start }
		local head = 1
		seen[start[1] * g.nz + start[2]] = true
		while head <= #queue do
			local c = queue[head]
			head = head + 1
			local i, j = c[1], c[2]
			for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
				local ni, nj = i + d[1], j + d[2]
				if ni >= 0 and nj >= 0 and ni < g.nx and nj < g.nz then
					local id = ni * g.nz + nj
					if g.free[id] and not seen[id] then
						seen[id] = true
						table.insert(queue, { ni, nj })
					end
				end
			end
		end
	end

	local function isReached(floor, x, z, radius)
		local g = grid(floor)
		if not g or not reached[floor] then
			return false
		end
		local ci, cj = cellOf(g, x, z)
		local cells = math.ceil(radius / CELL)
		for di = -cells, cells do
			for dj = -cells, cells do
				local i, j = ci + di, cj + dj
				if i >= 0 and j >= 0 and i < g.nx and j < g.nz and reached[floor][i * g.nz + j] then
					local px = g.minX + (i + 0.5) * CELL
					local pz = g.minZ + (j + 0.5) * CELL
					if (px - x) ^ 2 + (pz - z) ^ 2 <= radius * radius then
						return true
					end
				end
			end
		end
		return false
	end

	-- Floor 0 from the entrance, upper floors from the top of their stairs
	flood(0, ctx.entrance.x, ctx.entrance.z)
	local stairs = ctx.stairs or {}
	table.sort(stairs, function(a, b)
		return a.floor < b.floor
	end)
	for _, s in ipairs(stairs) do
		local r = s.rect
		local cx = (r[1] + r[3]) / 2
		local entry = s.entry or { x = cx, z = r[2] - 0.5 }
		local exit = s.exit or { x = cx, z = r[4] + 1 }
		if isReached(s.floor, entry.x, entry.z, 1.6) then
			flood(s.floor + 1, exit.x, exit.z)
		end
	end
	local function isReachedRect(floor, rect)
		local g = grid(floor)
		if not g or not reached[floor] then
			return false
		end
		for id in pairs(reached[floor]) do
			local i = math.floor(id / g.nz)
			local j = id - i * g.nz
			local px = g.minX + (i + 0.5) * CELL
			local pz = g.minZ + (j + 0.5) * CELL
			if Footprint.pointInRect(px, pz, rect) then
				return true
			end
		end
		return false
	end
	for _, t in ipairs(targets) do
		local ok
		if t.rect then
			ok = isReachedRect(t.floor, t.rect)
		else
			ok = isReached(t.floor, t.x, t.z, t.radius or 2)
		end
		if not ok then
			return false, t.label
		end
	end
	return true
end

return Pathgrid
