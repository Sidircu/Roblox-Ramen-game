--!nonstrict
-- Placement validation shared by the client preview and the server (pure).
--
-- ctx = {
--   items = Items.byId, zones = { unlocked zone configs }, walls = Walls.compute(...),
--   stairs = { {floor, rect} }, placed = { placed entries }, fixed = { {floor, rect} },
--   entrance = {x, z}, floorHeight = 15, wallHeight = 14, wallThickness = 0.8,
--   extraTargets = { pathgrid targets },
-- }
-- req = { i = itemId, x, y, z, r, f, s, p, u (when moving an existing object) }
local Footprint = require(script.Parent.Footprint)
local Walls = require(script.Parent.Walls)
local Pathgrid = require(script.Parent.Pathgrid)

local Placement = {}

local PLACE_CODE = { floor = "f", wall = "w", ceiling = "c", top = "t" }
Placement.PlaceCode = PLACE_CODE

local SURFACE_FN = { counter = true, table = true, booth = true, worktop = true }

local function contains(list, v)
	for _, x in ipairs(list) do
		if x == v then
			return true
		end
	end
	return false
end

function Placement.floorY(ctx, f)
	return (f or 0) * ctx.floorHeight
end

function Placement.footprint(ctx, entry)
	local item = ctx.items[entry.i]
	return Footprint.new(entry.x, entry.z, item.size[1], item.size[3], entry.r or 0)
end

-- World-space axis aligned box {x0,y0,z0,x1,y1,z1} of a placed entry (rotations multiple of 90 for walls)
function Placement.box(ctx, entry)
	local item = ctx.items[entry.i]
	local fp = Placement.footprint(ctx, entry)
	local x0, z0, x1, z1 = Footprint.bounds(fp)
	local y0
	if entry.s == "f" then
		y0 = Placement.floorY(ctx, entry.f)
	elseif entry.s == "c" then
		y0 = Placement.floorY(ctx, entry.f) + ctx.wallHeight - item.size[2]
	else
		y0 = (entry.y or 0) - item.size[2] / 2
	end
	return { x0, y0, z0, x1, y0 + item.size[2], z1 }
end

local function boxesOverlap(a, b, eps)
	eps = eps or 0.05
	return a[1] < b[4] - eps and b[1] < a[4] - eps and a[2] < b[5] - eps and b[2] < a[5] - eps and a[3] < b[6] - eps and b[3] < a[6] - eps
end

local function zoneRects(ctx, floor, areas, indoorOnly)
	local out = {}
	for _, z in ipairs(ctx.zones) do
		if z.floor == floor and contains(areas, z.area) and not (indoorOnly and z.outdoor) then
			table.insert(out, z.rect)
		end
	end
	return out
end

-- Pathgrid targets for the current layout (seats, kitchen, storage, stairs, terrace gap)
function Placement.pathTargets(ctx, placed)
	local targets = {}
	for _, e in ipairs(placed) do
		local item = ctx.items[e.i]
		if item and item.fn and e.s == "f" then
			if item.fn.type == "seat" then
				table.insert(targets, { floor = e.f or 0, x = e.x, z = e.z, radius = math.max(item.size[1], item.size[3]) / 2 + 1.5, label = "msg.place_blocks_seat" })
			elseif item.fn.type == "booth" then
				table.insert(targets, { floor = e.f or 0, x = e.x, z = e.z, radius = math.max(item.size[1], item.size[3]) / 2 + 1.5, label = "msg.place_blocks_seat" })
			elseif item.fn.type == "shelf" or item.fn.type == "station" or item.fn.type == "rack" then
				table.insert(targets, { floor = e.f or 0, x = e.x, z = e.z, radius = math.max(item.size[1], item.size[3]) / 2 + 1.5, label = "msg.place_blocks_work" })
			end
		end
	end
	for _, z in ipairs(ctx.zones) do
		if z.area == "kitchen" or z.area == "storage" then
			table.insert(targets, { floor = z.floor, rect = z.rect, label = "msg.place_blocks_path" })
		end
	end
	for _, s in ipairs(ctx.stairs or {}) do
		local r = s.rect
		local entry = s.entry or { x = (r[1] + r[3]) / 2, z = r[2] - 0.5 }
		table.insert(targets, { floor = s.floor, x = entry.x, z = entry.z, radius = 1.6, label = "msg.place_blocks_stairs" })
	end
	for _, t in ipairs(ctx.extraTargets or {}) do
		table.insert(targets, t)
	end
	return targets
end

function Placement.pathOk(ctx, placed)
	local obstacles = {}
	for _, e in ipairs(placed) do
		local item = ctx.items[e.i]
		if item and e.s == "f" and not item.walkable then
			table.insert(obstacles, { fp = Placement.footprint(ctx, e), floor = e.f or 0 })
		end
	end
	return Pathgrid.check(ctx, obstacles, Placement.pathTargets(ctx, placed))
end

-- Returns ok, reasonKey, resolved (req with y filled in)
function Placement.validate(ctx, req, skipPath)
	local item = ctx.items[req.i]
	if not item then
		return false, "msg.invalid"
	end
	local code = PLACE_CODE[item.place]
	if req.s ~= code then
		return false, "msg.invalid"
	end
	local f = req.f or 0
	local floorY = Placement.floorY(ctx, f)
	local w, h, d = item.size[1], item.size[2], item.size[3]
	local fp = Footprint.new(req.x, req.z, w, d, req.r or 0)
	local resolved = { i = req.i, x = req.x, z = req.z, r = req.r or 0, f = f, s = code, p = req.p, u = req.u }
	local floorWalls = ctx.walls[f] or { walls = {}, rails = {} }

	local others = {}
	for _, e in ipairs(ctx.placed) do
		if e.u ~= req.u then
			table.insert(others, e)
		end
	end

	if code == "f" then
		resolved.y = floorY
		if not Footprint.insideRects(fp, zoneRects(ctx, f, item.areas, false)) then
			return false, "msg.place_area"
		end
		for _, list in ipairs({ floorWalls.walls, floorWalls.rails }) do
			for _, seg in ipairs(list) do
				if Footprint.overlaps(fp, Footprint.wallFp(seg, ctx.wallThickness), 0.02) then
					return false, "msg.place_wall"
				end
			end
		end
		for _, s in ipairs(ctx.stairs or {}) do
			local blocked = false
			if s.floor == f then
				for _, r in ipairs(s.rects or { s.rect }) do
					if Footprint.overlaps(fp, Footprint.rectToFp(r), 0.02) then
						blocked = true
					end
				end
			elseif s.floor == f - 1 and Footprint.overlaps(fp, Footprint.rectToFp(s.hole or s.rect), 0.02) then
				blocked = true
			end
			if blocked then
				return false, "msg.place_stairs"
			end
		end
		for _, fx in ipairs(ctx.fixed or {}) do
			if fx.floor == f and Footprint.overlaps(fp, Footprint.rectToFp(fx.rect), 0.02) then
				return false, "msg.place_door"
			end
		end
		for _, e in ipairs(others) do
			if e.s == "f" and (e.f or 0) == f then
				if Footprint.overlaps(fp, Placement.footprint(ctx, e)) then
					return false, "msg.place_overlap"
				end
			elseif e.s == "w" and (e.f or 0) == f then
				local box = { 0, floorY, 0, 0, floorY + h, 0 }
				local x0, z0, x1, z1 = Footprint.bounds(fp)
				box[1], box[3], box[4], box[6] = x0, z0, x1, z1
				if boxesOverlap(box, Placement.box(ctx, e)) then
					return false, "msg.place_overlap"
				end
			end
		end
		if not skipPath and not item.walkable then
			local layout = table.clone(others)
			table.insert(layout, resolved)
			local ok, reason = Placement.pathOk(ctx, layout)
			if not ok then
				return false, reason or "msg.place_blocks_path"
			end
		end
		return true, nil, resolved
	elseif code == "w" then
		local half = ctx.wallThickness / 2 + d / 2
		local best, bestErr = nil, math.huge
		for _, seg in ipairs(floorWalls.walls) do
			local dist
			if seg.axis == "z" then
				dist = math.abs(req.z - seg.line)
			else
				dist = math.abs(req.x - seg.line)
			end
			local along = Walls.along(seg, req.x, req.z)
			if math.abs(dist - half) < 0.2 and along - w / 2 >= seg.a - 0.01 and along + w / 2 <= seg.b + 0.01 then
				if math.abs(dist - half) < bestErr then
					best, bestErr = seg, math.abs(dist - half)
				end
			end
		end
		if not best then
			return false, "msg.place_wall_only"
		end
		-- facing away from the wall
		local rot
		if best.axis == "z" then
			rot = (req.z < best.line) and 0 or 180
			resolved.z = best.line + ((req.z < best.line) and -half or half)
		else
			rot = (req.x < best.line) and 90 or 270
			resolved.x = best.line + ((req.x < best.line) and -half or half)
		end
		resolved.r = rot
		local y = req.y or (floorY + 6)
		if y - h / 2 < floorY + 0.3 or y + h / 2 > floorY + ctx.wallHeight - 0.3 then
			return false, "msg.place_height"
		end
		resolved.y = y
		local insideArea = false
		for _, z in ipairs(ctx.zones) do
			if z.floor == f and not z.outdoor and contains(item.areas, z.area) and Footprint.pointInRect(resolved.x, resolved.z, z.rect) then
				insideArea = true
			end
		end
		if not insideArea then
			return false, "msg.place_area"
		end
		local myBox = Placement.box(ctx, resolved)
		for _, e in ipairs(others) do
			if (e.f or 0) == f and (e.s == "w" or e.s == "f") then
				if boxesOverlap(myBox, Placement.box(ctx, e)) then
					return false, "msg.place_overlap"
				end
			end
		end
		return true, nil, resolved
	elseif code == "c" then
		resolved.y = floorY + ctx.wallHeight - h / 2
		if not Footprint.insideRects(fp, zoneRects(ctx, f, item.areas, true)) then
			return false, "msg.place_area"
		end
		for _, s in ipairs(ctx.stairs or {}) do
			if s.floor == f and Footprint.overlaps(fp, Footprint.rectToFp(s.rect), 0.02) then
				return false, "msg.place_stairs"
			end
		end
		for _, e in ipairs(others) do
			if e.s == "c" and (e.f or 0) == f and Footprint.overlaps(fp, Placement.footprint(ctx, e)) then
				return false, "msg.place_overlap"
			end
		end
		return true, nil, resolved
	elseif code == "t" then
		local parent = nil
		for _, e in ipairs(others) do
			if e.u == req.p then
				parent = e
			end
		end
		if not parent then
			return false, "msg.place_top_only"
		end
		local pItem = ctx.items[parent.i]
		if not (pItem and pItem.fn and SURFACE_FN[pItem.fn.type]) then
			return false, "msg.place_top_only"
		end
		resolved.f = parent.f or 0
		resolved.y = Placement.floorY(ctx, resolved.f) + pItem.size[2]
		local pfp = Placement.footprint(ctx, parent)
		for _, c in ipairs(Footprint.corners(fp)) do
			if not Footprint.pointIn(pfp, c.x, c.z, -0.05) then
				return false, "msg.place_top_only"
			end
		end
		for _, e in ipairs(others) do
			if e.s == "t" and e.p == req.p and Footprint.overlaps(fp, Placement.footprint(ctx, e)) then
				return false, "msg.place_overlap"
			end
		end
		return true, nil, resolved
	end
	return false, "msg.invalid"
end

return Placement
