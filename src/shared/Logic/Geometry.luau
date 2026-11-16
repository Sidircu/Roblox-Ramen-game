--!nonstrict
-- Unlocked restaurant geometry (zones, openings, stairs, walls, door clearances) computed from
-- the owner's `zones` map. Shared by the server world builder and the client build preview.
local Walls = require(script.Parent.Walls)

local Geometry = {}

-- expansions: Config.Expansions.list ; unlocked: { [expansionId] = true }
function Geometry.compute(expansions, unlocked, supplier)
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
				table.insert(stairs, s)
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
		local r = s.rect
		table.insert(fixed, { floor = s.floor, rect = { r[1], r[2] - 2.5, r[3], r[2] } })
		table.insert(fixed, { floor = s.floor + 1, rect = { r[1], r[4], r[3], r[4] + 2.5 } })
	end
	-- machiya facade details (lattice, bamboo fence, pines, menu board) in front of the street wall
	table.insert(fixed, { floor = 0, rect = { -60, -1.6, 50, 0 } })
	table.insert(fixed, { floor = 0, rect = { -10.2, -3.6, -7, -1.6 } })
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
		wallThickness = 0.8,
	}
end

return Geometry
