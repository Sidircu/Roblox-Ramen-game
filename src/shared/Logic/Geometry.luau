--!nonstrict
-- Unlocked restaurant geometry (zones, openings, stairs, walls, door clearances) computed from
-- the owner's `zones` map. Shared by the server world builder and the client build preview.
local Walls = require(script.Parent.Walls)

local Geometry = {}

-- Normalised stairs: every staircase gets rects (lower floor footprint), hole (opening in the
-- floor above), entry / exit points and their clearance rects. Old single-rect stairs rise
-- towards +Z.
function Geometry.stairs(s)
	if s.hole then
		return s
	end
	local r = s.rect
	local cx = (r[1] + r[3]) / 2
	return {
		floor = s.floor,
		rect = r,
		rects = { r },
		hole = r,
		flights = { { rect = r, dir = "+z", from = 0, to = 1 } },
		entry = { x = cx, z = r[2] - 0.5 },
		exit = { x = cx, z = r[4] + 1 },
		exitSide = "z+",
		entryRect = { r[1], r[2] - 2.5, r[3], r[2] },
		exitRect = { r[1], r[4], r[3], r[4] + 2.5 },
	}
end

-- expansions: Config.Expansions.list ; unlocked: { [expansionId] = true }
-- points: the Config.Expansions module (Supplier, MenuBoard, FacadeBand) or just the supplier
function Geometry.compute(expansions, unlocked, points)
	local zones, openings, stairs, exps = {}, {}, {}, {}
	for _, e in ipairs(expansions) do
		if unlocked[e.id] then
			table.insert(exps, e)
			for _, z in ipairs(e.zones or {}) do
				table.insert(zones, z)
			end
			for _, o in ipairs(e.openings or {}) do
				table.insert(openings, o)
			end
			for _, s in ipairs(e.stairs or {}) do
				table.insert(stairs, Geometry.stairs(s))
			end
		end
	end
	local fixed = {}
	for _, o in ipairs(openings) do
		if o.axis == "z" then
			table.insert(fixed, { floor = o.floor, rect = { o.from, o.at - 2.5, o.to, o.at + 2.5 } })
		else
			table.insert(fixed, { floor = o.floor, rect = { o.at - 2.5, o.from, o.at + 2.5, o.to } })
		end
	end
	for _, s in ipairs(stairs) do
		table.insert(fixed, { floor = s.floor, rect = s.entryRect })
		table.insert(fixed, { floor = s.floor + 1, rect = s.exitRect })
	end
	points = points or {}
	local supplier = points.Supplier or (points.x and points) or nil
	-- machiya facade details (lattice, bamboo fence, pines) in front of the street wall
	table.insert(fixed, { floor = 0, rect = points.FacadeBand or { -60, -1.6, 50, 0 } })
	local mb = points.MenuBoard
	if mb then
		table.insert(fixed, { floor = 0, rect = { mb.x - 1.6, mb.z - 1, mb.x + 1.6, mb.z + 1 } })
	end
	if supplier then
		table.insert(fixed, { floor = 0, rect = { supplier.x - 1.2, supplier.z - 1.5, supplier.x + 0.3, supplier.z + 1.5 } })
	end
	return {
		zones = zones,
		openings = openings,
		stairs = stairs,
		expansions = exps,
		walls = Walls.compute(zones, openings, stairs),
		fixed = fixed,
	}
end

function Geometry.ctx(geo, items, placed, cfg)
	return {
		items = items,
		zones = geo.zones,
		walls = geo.walls,
		stairs = geo.stairs,
		placed = placed,
		fixed = geo.fixed,
		entrance = { x = 0, z = 0.75 },
		floorHeight = cfg.FloorHeight,
		wallHeight = cfg.WallHeight,
		wallThickness = cfg.WallThickness or 0.8,
		wallItemY = cfg.WallItemY or 6,
	}
end

return Geometry
