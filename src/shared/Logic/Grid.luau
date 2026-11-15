--!nonstrict
-- Grid snapping helpers (pure).
local Grid = {}

function Grid.normRot(deg)
	deg = deg % 360
	if deg < 0 then
		deg = deg + 360
	end
	return deg
end

-- Axis-aligned extents of a w x d rectangle rotated by deg around Y.
function Grid.aabb(w, d, deg)
	local r = math.rad(deg)
	local c, s = math.abs(math.cos(r)), math.abs(math.sin(r))
	return w * c + d * s, w * s + d * c
end

function Grid.snapValue(v, g)
	return math.floor(v / g + 0.5) * g
end

-- Snaps the footprint's minimum corner to the grid (relative to origin 0,0) and returns the center.
function Grid.snapFloor(x, z, w, d, deg, g)
	local ew, ed = Grid.aabb(w, d, deg)
	local minX = Grid.snapValue(x - ew / 2, g)
	local minZ = Grid.snapValue(z - ed / 2, g)
	return minX + ew / 2, minZ + ed / 2
end

-- Snaps a position along a wall (1D) and a height.
function Grid.snapWall(along, y, w, h, g, floorY)
	local a = Grid.snapValue(along - w / 2, g) + w / 2
	local yy = Grid.snapValue(y - h / 2 - floorY, math.min(g, 5)) + h / 2 + floorY
	return a, yy
end

function Grid.nextRotation(deg, step)
	return Grid.normRot(deg + step)
end

return Grid
