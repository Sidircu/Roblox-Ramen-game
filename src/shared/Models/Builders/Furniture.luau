--!nonstrict
-- Seating, counters, tables, benches and storage racks.
local Kit = require(script.Parent.Parent.Kit)
local P = require(script.Parent.Parent.Palette)
local M = P.M

local function size(item)
	return Vector3.new(item.size[1], item.size[2], item.size[3])
end

-- Attachment on Root at local bottom-relative position (x, y, z) facing `look` (+Z/-Z/...)
local function point(root, name, x, y, z, yaw)
	local h = root.Size.Y
	return Kit.attach(root, name, CFrame.new(x, y - h / 2, z) * CFrame.Angles(0, math.rad(yaw or 0), 0))
end

local function stool(m, item, seatColor, seatMat, legColor, swivel)
	local root = Kit.finish(m, size(item))
	local h = item.size[2]
	if swivel then
		Kit.cyl(m, 1.5, 0.12, 0, 0.06, 0, P.steel_dark, M.metal)
		Kit.cyl(m, 0.28, h - 0.5, 0, (h - 0.5) / 2 + 0.1, 0, P.metal, M.metal, { reflectance = 0.2 })
		Kit.cyl(m, 1.2, 0.08, 0, 0.9, 0, P.metal, M.metal, { collide = false })
		Kit.cyl(m, 1.6, 0.35, 0, h - 0.2, 0, seatColor, seatMat)
		Kit.cyl(m, 1.66, 0.06, 0, h - 0.38, 0, P.gold, M.metal, { collide = false })
	else
		for _, c in ipairs({ { -0.5, -0.5 }, { 0.5, -0.5 }, { 0.5, 0.5 }, { -0.5, 0.5 } }) do
			Kit.box(m, 0.18, h - 0.3, 0.18, c[1], (h - 0.3) / 2, c[2], legColor, M.wood, { rot = CFrame.Angles(c[2] * 0.08, 0, -c[1] * 0.08) })
		end
		for _, r in ipairs({ { 0, -0.48, 1, 0.1 }, { 0, 0.48, 1, 0.1 }, { -0.48, 0, 0.1, 1 }, { 0.48, 0, 0.1, 1 } }) do
			Kit.box(m, r[3], 0.1, r[4], r[1], 0.8, r[2], legColor, M.wood, { collide = false })
		end
		Kit.cyl(m, 1.55, 0.28, 0, h - 0.16, 0, P.wood_light, M.wood)
		if seatMat == M.fabric then
			Kit.cyl(m, 1.45, 0.2, 0, h + 0.02, 0, seatColor, M.fabric, { collide = false })
		end
	end
	point(root, "SitPoint", 0, h, 0, 0)
end

local function counter(m, item, kind)
	local root = Kit.finish(m, size(item))
	local w, h, d = item.size[1], item.size[2], item.size[3]
	-- cabinet (customer side faces -Z)
	Kit.box(m, w, h - 0.25, d - 0.6, 0, (h - 0.25) / 2, 0.3, P.wood_dark, M.wood)
	-- vertical slats on the customer side
	local n = math.max(2, math.floor(w / 0.5))
	for i = 0, n - 1 do
		local x = -w / 2 + 0.25 + (w - 0.5) * i / math.max(1, n - 1)
		Kit.box(m, 0.12, h - 0.75, 0.08, x, (h - 0.25) / 2 + 0.1, -d / 2 + 0.58, P.wood, M.wood, { collide = false })
	end
	-- kick plate and foot rail
	Kit.box(m, w, 0.35, 0.1, 0, 0.175, -d / 2 + 0.62, P.black, M.smooth, { collide = false })
	Kit.cylH(m, 0.12, w, 0, 0.7, -d / 2 + 0.25, P.brass, M.metal, { collide = false, reflectance = 0.15 })
	-- hinoki counter top with front overhang
	Kit.box(m, w, 0.22, d, 0, h - 0.11, 0, P.hinoki, M.wood)
	-- raised chef ledge (tsukedai) on the kitchen side
	Kit.box(m, w, 0.35, 0.5, 0, h + 0.15, d / 2 - 0.25, P.wood_light, M.wood, { collide = false })
	if kind == "corner" then
		Kit.box(m, 0.5, 0.35, d - 0.5, w / 2 - 0.25, h + 0.15, -0.25, P.wood_light, M.wood, { collide = false })
	elseif kind == "end" then
		Kit.box(m, 0.15, h - 0.4, d - 0.4, w / 2 - 0.075, (h - 0.4) / 2 + 0.1, 0, P.wood_black, M.wood, { collide = false })
	end
	root:SetAttribute("TopY", h)
end

local function tableTop(m, item, topColor, legColor, low)
	local root = Kit.finish(m, size(item))
	local w, h, d = item.size[1], item.size[2], item.size[3]
	Kit.box(m, w, 0.2, d, 0, h - 0.1, 0, topColor, M.wood)
	Kit.box(m, w - 0.1, 0.06, d - 0.1, 0, h + 0.005, 0, Color3.new(1, 1, 1):Lerp(topColor, 0.85), M.wood, { collide = false })
	if low then
		for _, c in ipairs({ { -1, -1 }, { 1, -1 }, { 1, 1 }, { -1, 1 } }) do
			Kit.box(m, 0.35, h - 0.2, 0.35, c[1] * (w / 2 - 0.4), (h - 0.2) / 2, c[2] * (d / 2 - 0.4), legColor, M.wood)
		end
		Kit.box(m, w - 0.6, 0.12, d - 0.6, 0, h - 0.26, 0, legColor, M.wood, { collide = false })
	else
		Kit.box(m, 0.4, h - 0.5, 0.4, 0, (h - 0.5) / 2 + 0.2, 0, legColor, M.wood)
		Kit.box(m, math.min(w, 2.2), 0.2, 0.4, 0, 0.1, 0, legColor, M.wood)
		Kit.box(m, 0.4, 0.2, math.min(d, 2.2), 0, 0.1, 0, legColor, M.wood)
		Kit.box(m, w - 0.6, 0.15, 0.3, 0, h - 0.28, 0, legColor, M.wood, { collide = false })
	end
	-- small soy sauce bottle and chopstick box
	Kit.cyl(m, 0.22, 0.4, w / 2 - 0.4, h + 0.2, d / 2 - 0.35, P.white, M.smooth, { collide = false })
	Kit.cyl(m, 0.24, 0.08, w / 2 - 0.4, h + 0.44, d / 2 - 0.35, P.lacquer, M.smooth, { collide = false })
	Kit.box(m, 0.6, 0.25, 0.25, w / 2 - 0.95, h + 0.125, d / 2 - 0.35, P.wood_black, M.wood, { collide = false })
	root:SetAttribute("TopY", h)
end

local function chair(m, item, color, mat)
	local root = Kit.finish(m, size(item))
	local seatH = item.fn.height
	for _, c in ipairs({ { -0.6, -0.6 }, { 0.6, -0.6 }, { 0.6, 0.6 }, { -0.6, 0.6 } }) do
		Kit.box(m, 0.18, seatH - 0.12, 0.18, c[1], (seatH - 0.12) / 2, c[2], color, mat)
	end
	Kit.box(m, 1.5, 0.15, 1.5, 0, seatH - 0.06, 0, color, mat)
	Kit.box(m, 1.4, 0.08, 1.4, 0, seatH + 0.02, 0, P.paper_warm, M.fabric, { collide = false })
	-- backrest on +Z (the sitter faces -Z)
	Kit.box(m, 0.16, 1.6, 0.16, -0.6, seatH + 0.8, 0.66, color, mat)
	Kit.box(m, 0.16, 1.6, 0.16, 0.6, seatH + 0.8, 0.66, color, mat)
	Kit.box(m, 1.36, 0.3, 0.1, 0, seatH + 1.45, 0.66, color, mat)
	Kit.box(m, 1.2, 0.12, 0.08, 0, seatH + 0.9, 0.66, color, mat)
	point(root, "SitPoint", 0, seatH, 0, 0)
end

local function cushion(m, root, x, z, color, h)
	Kit.box(m, 1.7, h, 1.7, x, h / 2, z, color, M.fabric)
	Kit.box(m, 1.5, 0.04, 1.5, x, h + 0.01, z, Color3.new(1, 1, 1):Lerp(color, 0.7), M.fabric, { collide = false })
	for _, c in ipairs({ { -1, -1 }, { 1, -1 }, { 1, 1 }, { -1, 1 } }) do
		Kit.ball(m, 0.16, x + c[1] * 0.85, h / 2, z + c[2] * 0.85, P.gold, M.fabric, { collide = false })
	end
end

return function(Registry)
	Registry.register("stool_wood", function(m, item)
		stool(m, item, P.wood_light, M.wood, P.wood)
	end)
	Registry.register("stool_cushion", function(m, item)
		stool(m, item, P.lacquer, M.fabric, P.wood_dark)
	end)
	Registry.register("stool_swivel", function(m, item)
		stool(m, item, P.lacquer, M.leather, P.steel, true)
	end)
	Registry.register("counter_straight", function(m, item)
		counter(m, item, "straight")
	end)
	Registry.register("counter_corner", function(m, item)
		counter(m, item, "corner")
	end)
	Registry.register("counter_end", function(m, item)
		counter(m, item, "end")
	end)
	Registry.register("table_2", function(m, item)
		tableTop(m, item, P.wood_light, P.wood_dark)
	end)
	Registry.register("table_4", function(m, item)
		tableTop(m, item, P.wood_light, P.wood_dark)
	end)
	Registry.register("chabudai", function(m, item)
		tableTop(m, item, P.wood_dark, P.wood_black, true)
	end)
	Registry.register("chair_wood", function(m, item)
		chair(m, item, P.wood, M.wood)
	end)
	Registry.register("chair_lacquer", function(m, item)
		chair(m, item, P.lacquer, M.smooth)
	end)
	Registry.register("zabuton", function(m, item)
		local root = Kit.finish(m, size(item))
		cushion(m, root, 0, 0, P.indigo, 0.35)
		point(root, "SitPoint", 0, 0.4, 0, 0)
	end)
	Registry.register("booth", function(m, item)
		local root = Kit.finish(m, size(item))
		local w, h = item.size[1], item.size[2]
		-- two benches facing each other along Z
		for side = -1, 1, 2 do
			local z = side * 1.85
			Kit.box(m, w, 1.6, 1.3, 0, 0.8, z, P.wood_dark, M.wood)
			Kit.box(m, w - 0.2, 0.3, 1.2, 0, 1.75, z, P.lacquer_dark, M.leather)
			Kit.box(m, w, h - 1.6, 0.3, 0, 1.6 + (h - 1.6) / 2, z + side * 0.5, P.wood_dark, M.wood)
			Kit.box(m, w - 0.3, h - 2.2, 0.15, 0, 1.9 + (h - 2.2) / 2, z + side * 0.33, P.lacquer_dark, M.leather, { collide = false })
		end
		Kit.box(m, w - 1.2, 0.2, 2, 0, 2.6, 0, P.wood_light, M.wood)
		Kit.box(m, 0.4, 2.4, 0.4, 0, 1.3, 0, P.wood_black, M.wood)
		local i = 0
		for side = -1, 1, 2 do
			for _, x in ipairs({ -1.2, 1.2 }) do
				i += 1
				point(root, "Seat" .. i, x, 1.9, side * 1.85, side < 0 and 180 or 0)
				point(root, "Dish" .. i, x, 2.7, side * 0.55, 0)
			end
		end
		root:SetAttribute("TopY", 2.7)
	end)
	Registry.register("zashiki_table", function(m, item)
		local root = Kit.finish(m, size(item))
		Kit.box(m, 4, 0.2, 2.4, 0, 1.2, 0, P.wood_black, M.wood)
		Kit.box(m, 3.9, 0.04, 2.3, 0, 1.31, 0, P.lacquer_dark, M.smooth, { collide = false })
		for _, c in ipairs({ { -1, -1 }, { 1, -1 }, { 1, 1 }, { -1, 1 } }) do
			Kit.box(m, 0.3, 1.1, 0.3, c[1] * 1.7, 0.55, c[2] * 0.95, P.wood_black, M.wood)
		end
		local i = 0
		for side = -1, 1, 2 do
			for _, x in ipairs({ -1.1, 1.1 }) do
				i += 1
				cushion(m, root, x, side * 2.2, P.lacquer, 0.3)
				point(root, "Seat" .. i, x, 0.35, side * 2.2, side < 0 and 180 or 0)
				point(root, "Dish" .. i, x, 1.32, side * 0.6, 0)
			end
		end
		root:SetAttribute("TopY", 1.32)
	end)
	Registry.register("waiting_bench", function(m, item)
		local root = Kit.finish(m, size(item))
		local w = item.size[1]
		Kit.box(m, w, 0.2, 1.2, 0, 1.5, 0, P.wood_light, M.wood)
		for _, x in ipairs({ -w / 2 + 0.4, w / 2 - 0.4 }) do
			Kit.box(m, 0.25, 1.4, 1, x, 0.7, 0, P.wood_dark, M.wood)
		end
		Kit.box(m, w, 0.5, 0.15, 0, 2.2 - 0.25, 0.6, P.wood_light, M.wood, { collide = false })
		for i, x in ipairs({ -1.6, 0, 1.6 }) do
			point(root, "Queue" .. i, x, 1.6, 0, 0)
		end
	end)
	-- storage racks: box slots BoxN on Root
	local function rack(m, item)
		local root = Kit.finish(m, size(item))
		local w, h, d = item.size[1], item.size[2], item.size[3]
		local rows, cols = item.fn.rows, item.fn.cols
		for _, x in ipairs({ -w / 2 + 0.1, w / 2 - 0.1 }) do
			for _, z in ipairs({ -d / 2 + 0.1, d / 2 - 0.1 }) do
				Kit.box(m, 0.15, h, 0.15, x, h / 2, z, P.steel_dark, M.metal)
			end
		end
		local slot = 0
		for r = 0, rows - 1 do
			local y = 0.15 + r * 2.0
			Kit.box(m, w - 0.1, 0.12, d - 0.1, 0, y, 0, P.wood, M.planks)
			for c = 0, cols - 1 do
				slot += 1
				local x = -w / 2 + w / cols * (c + 0.5)
				point(root, "Box" .. slot, x, y + 0.06, 0, 0)
			end
		end
		Kit.box(m, w - 0.1, 0.12, d - 0.1, 0, h - 0.06, 0, P.steel_dark, M.metal, { collide = false })
	end
	Registry.register("storage_rack", rack)
	Registry.register("storage_rack_large", rack)
end
