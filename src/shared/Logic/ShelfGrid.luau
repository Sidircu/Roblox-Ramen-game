--!nonstrict
-- Product grid of a shelf slot. A slot holds half a supplier box (GameConfig.BoxShelfSlots = 2) laid
-- out like a chessboard (2x3, 2x5, 3x5...), so a glance tells how many products fit and how many
-- are missing. The shelf upgrade adds rows towards the back.
local ShelfGrid = {}

-- columns (across) and rows (front to back) for n products: the most square layout with at most
-- 5 columns; numbers that do not split evenly leave a few cells of the last row unused
function ShelfGrid.dims(n)
	n = math.max(1, math.floor(n))
	local bestC, bestR = nil, nil
	for r = 1, n do
		if n % r == 0 then
			local c = math.floor(n / r)
			if c >= r and c <= 5 then
				if not bestC or (c - r) < (bestC - bestR) then
					bestC, bestR = c, r
				end
			end
		end
	end
	if not bestC then
		bestC = math.min(5, n)
		bestR = math.ceil(n / bestC)
	end
	return bestC, bestR
end

-- grid of one slot for an ingredient whose box holds `units`, split over `slotsPerBox` slots;
-- mult = shelf upgrade multiplier (extra rows, rounded)
function ShelfGrid.forIngredient(units, slotsPerBox, mult)
	local per = math.max(1, math.ceil(units / math.max(1, slotsPerBox)))
	local cols, rows = ShelfGrid.dims(per)
	local upgraded = math.max(rows, math.floor(rows * (mult or 1) + 0.5))
	return cols, upgraded
end

-- local (x, z) of the centre of cell k (1-based) on a slot `width` wide and `depth` deep, plus
-- the cell size. The front row (-z) fills first, from the left of a player facing the shelf (+x).
function ShelfGrid.cell(k, cols, rows, width, depth)
	local i = (k - 1) % cols
	local j = math.floor((k - 1) / cols)
	local cw, cd = width / cols, depth / rows
	local x = width / 2 - cw * (i + 0.5)
	local z = -depth / 2 + cd * (j + 0.5)
	return x, z, cw, cd
end

return ShelfGrid
