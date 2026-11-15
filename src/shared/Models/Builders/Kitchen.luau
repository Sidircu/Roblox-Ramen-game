--!nonstrict
-- Kitchen equipment: shelves, neta case, rice cookers, broth pots, stations, sink, dishwasher, fridge.
-- Functional points (on Root): SlotN parts (shelves), Board/Plate/Tool attachments (stations).
local Kit = require(script.Parent.Parent.Kit)
local P = require(script.Parent.Parent.Palette)
local M = P.M

local function size(item)
	return Vector3.new(item.size[1], item.size[2], item.size[3])
end

local function point(root, name, x, y, z, yaw)
	local h = root.Size.Y
	return Kit.attach(root, name, CFrame.new(x, y - h / 2, z) * CFrame.Angles(0, math.rad(yaw or 0), 0))
end

-- Invisible clickable slot volume
local function slot(m, index, sx, sy, sz, x, y, z)
	local p = Kit.box(m, sx, sy, sz, x, y, z, P.white, M.smooth, { transparency = 1, collide = false, shadow = false, name = "Slot" .. index })
	p.CanQuery = true
	p:SetAttribute("Slot", index)
	return p
end

local function cabinet(m, w, h, d, top, body)
	Kit.box(m, w, h - 0.2, d, 0, (h - 0.2) / 2, 0, body or P.steel, M.metal)
	Kit.box(m, w + 0.05, 0.2, d + 0.05, 0, h - 0.1, 0, top or P.metal, M.metal, { reflectance = 0.1 })
	-- doors and handles on the cook side (-Z)
	local doors = math.max(1, math.floor(w / 1.6))
	for i = 0, doors - 1 do
		local x = -w / 2 + w / doors * (i + 0.5)
		Kit.box(m, w / doors - 0.15, h - 0.8, 0.05, x, (h - 0.2) / 2, -d / 2 - 0.02, P.steel_dark, M.metal, { collide = false })
		Kit.box(m, 0.5, 0.08, 0.08, x, h - 0.65, -d / 2 - 0.08, P.metal, M.metal, { collide = false })
	end
end

local function shelfUnit(m, item)
	local root = Kit.finish(m, size(item))
	local w, h, d = item.size[1], item.size[2], item.size[3]
	local slots = item.fn.slots
	local cols = slots > 4 and 2 or 1
	local rows = math.ceil(slots / cols)
	-- frame
	Kit.box(m, w, h, 0.12, 0, h / 2, d / 2 - 0.06, P.wood_dark, M.planks)
	for _, x in ipairs({ -w / 2 + 0.1, w / 2 - 0.1 }) do
		Kit.box(m, 0.2, h, d, x, h / 2, 0, P.wood_dark, M.wood)
	end
	if cols == 2 then
		Kit.box(m, 0.14, h, d, 0, h / 2, 0, P.wood_dark, M.wood)
	end
	local rowH = (h - 0.3) / rows
	local idx = 0
	for r = 0, rows - 1 do
		local y = 0.15 + r * rowH
		Kit.box(m, w - 0.2, 0.12, d, 0, y, 0, P.wood_light, M.wood)
		-- little price/label strip
		Kit.box(m, w - 0.3, 0.14, 0.04, 0, y + 0.02, -d / 2 - 0.01, P.paper, M.smooth, { collide = false })
		for c = 0, cols - 1 do
			idx += 1
			if idx <= slots then
				local cw = (w - 0.3) / cols
				local x = -w / 2 + 0.15 + cw * (c + 0.5)
				local s = slot(m, idx, cw - 0.1, rowH - 0.2, d - 0.1, x, y + 0.06 + (rowH - 0.2) / 2, 0)
				s:SetAttribute("Width", cw - 0.2)
			end
		end
	end
	Kit.box(m, w, 0.15, d, 0, h - 0.075, 0, P.wood_dark, M.wood)
end

local function riceCooker(m, item, pro)
	local root = Kit.finish(m, size(item))
	local w, h = item.size[1], item.size[2]
	local standH = h - 1.4
	Kit.box(m, w, standH, w, 0, standH / 2, 0, P.wood_dark, M.wood)
	local body = Kit.cyl(m, w - 0.35, 1.0, 0, standH + 0.5, 0, pro and P.metal or P.white, pro and M.metal or M.smooth, { name = "Body" })
	Kit.cyl(m, w - 0.3, 0.08, 0, standH + 0.12, 0, P.charcoal, M.smooth, { collide = false })
	Kit.blob(m, w - 0.4, 0.35, w - 0.4, 0, standH + 1.05, 0, pro and P.steel or P.porcelain, M.smooth, { collide = false })
	Kit.box(m, 0.5, 0.12, 0.1, 0, standH + 1.25, 0, P.charcoal, M.smooth, { collide = false })
	local panel = Kit.box(m, 0.6, 0.3, 0.06, 0, standH + 0.55, -(w - 0.35) / 2 - 0.02, P.charcoal, M.smooth, { collide = false })
	local led = Kit.box(m, 0.12, 0.12, 0.04, 0.15, standH + 0.55, -(w - 0.35) / 2 - 0.06, P.neon_red, M.neon, { collide = false, name = "Led" })
	local _ = panel
	local _2 = led
	local vent = Kit.box(m, 0.2, 0.1, 0.2, 0, standH + 1.3, 0, P.white, M.smooth, { transparency = 1, collide = false, name = "Steam" })
	Kit.particles(vent, "steam", { enabled = false })
	local _3 = body
	point(root, "Content", 0, standH + 1.1, 0)
end

local function brothPot(m, item, large)
	local root = Kit.finish(m, size(item))
	local w, h = item.size[1], item.size[2]
	local stoveH = 1.5
	cabinet(m, w, stoveH, w, P.steel_dark, P.steel)
	Kit.cyl(m, w * 0.6, 0.06, 0, stoveH + 0.03, 0, P.neon_blue, M.neon, { collide = false, name = "Flame" })
	local potH = h - stoveH - 0.2
	local d = w - 0.4
	Kit.cyl(m, d, potH, 0, stoveH + potH / 2 + 0.05, 0, P.metal, M.metal, { reflectance = 0.15, name = "Body" })
	Kit.cyl(m, d + 0.1, 0.12, 0, stoveH + potH, 0, P.steel, M.metal, { collide = false })
	local broth = Kit.cyl(m, d - 0.15, 0.06, 0, stoveH + potH - 0.12, 0, P.wood, M.smooth, { collide = false, name = "Broth", transparency = 1 })
	broth:SetAttribute("Fill", true)
	for _, x in ipairs({ -d / 2 - 0.15, d / 2 + 0.15 }) do
		Kit.box(m, 0.3, 0.12, 0.6, x, stoveH + potH - 0.35, 0, P.steel_dark, M.metal, { collide = false })
	end
	-- ladle resting in the pot
	Kit.cyl(m, 0.08, 2, d / 4, stoveH + potH + 0.3, 0, P.metal, M.metal, { collide = false, rot = CFrame.Angles(0, 0, math.rad(25)) })
	local vent = Kit.box(m, d - 0.4, 0.1, d - 0.4, 0, stoveH + potH + 0.1, 0, P.white, M.smooth, { transparency = 1, collide = false, name = "Steam" })
	Kit.particles(vent, "steam", { enabled = false, rate = large and 10 or 6 })
	Kit.particles(broth, "bubbles", { enabled = false })
	point(root, "Content", 0, stoveH + potH, 0)
end

-- Work station: counter with a board area (-x), a plate spot (+x), a tool hovering point.
local function station(m, item, deco)
	local root = Kit.finish(m, size(item))
	local w, h, d = item.size[1], item.size[2], item.size[3]
	cabinet(m, w, h, d, P.metal, P.steel)
	local boardX = -w / 2 + 1.4
	local plateX = w / 2 - 0.9
	deco(m, w, h, d, boardX, plateX)
	point(root, "Board", boardX, h + 0.1, 0.05)
	point(root, "Plate", plateX, h + 0.05, 0.1)
	point(root, "Tool", boardX, h + 1.2, -0.1)
	point(root, "Cook", 0, 0, -d / 2 - 1.3, 0)
	local label = Kit.box(m, 0.1, 0.1, 0.1, 0, h + 2.2, 0, P.white, M.smooth, { transparency = 1, collide = false, shadow = false, name = "LabelAnchor" })
	local _ = label
end

return function(Registry)
	Registry.register("shelf_small", shelfUnit)
	Registry.register("shelf_large", shelfUnit)

	Registry.register("neta_case", function(m, item)
		local root = Kit.finish(m, size(item))
		local w, h, d = item.size[1], item.size[2], item.size[3]
		local baseH = 2.1
		Kit.box(m, w, baseH, d, 0, baseH / 2, 0, P.wood_dark, M.wood)
		Kit.box(m, w + 0.05, 0.12, d + 0.05, 0, baseH + 0.06, 0, P.hinoki, M.wood)
		local caseH = h - baseH - 0.12
		Kit.box(m, w - 0.1, 0.06, d - 0.5, 0, baseH + 0.15, 0.1, P.white, M.smooth, { collide = false })
		Kit.box(m, w, caseH, 0.08, 0, baseH + 0.12 + caseH / 2, d / 2 - 0.25, P.glass, M.glass, { transparency = 0.6 })
		Kit.wedge(m, w, caseH, 1.2, CFrame.new(0, baseH + 0.12 + caseH / 2, -d / 2 + 0.85) * CFrame.Angles(0, math.rad(180), 0), P.glass, M.glass, { transparency = 0.65, collide = false })
		Kit.box(m, w, 0.08, 1.7, 0, baseH + 0.12 + caseH, 0.4, P.steel, M.metal, { collide = false })
		local lightBar = Kit.box(m, w - 0.3, 0.05, 0.2, 0, baseH + 0.08 + caseH, 0.4, P.white, M.neon, { collide = false })
		Kit.light(lightBar, "Surface", P.white, 6, 1.2, { face = Enum.NormalId.Bottom, night = false })
		for i = 1, 4 do
			local x = -w / 2 + w / 4 * (i - 0.5)
			slot(m, i, w / 4 - 0.1, caseH - 0.1, d - 0.4, x, baseH + 0.12 + caseH / 2, 0.1):SetAttribute("Width", w / 4 - 0.3)
		end
		-- ice bed
		Kit.box(m, w - 0.2, 0.1, d - 0.6, 0, baseH + 0.2, 0.1, P.glass, M.glass, { collide = false, transparency = 0.2 })
	end)

	Registry.register("rice_cooker", function(m, item)
		riceCooker(m, item, false)
	end)
	Registry.register("rice_cooker_pro", function(m, item)
		riceCooker(m, item, true)
	end)
	Registry.register("broth_pot", function(m, item)
		brothPot(m, item, false)
	end)
	Registry.register("broth_pot_large", function(m, item)
		brothPot(m, item, true)
	end)

	Registry.register("sushi_station", function(m, item)
		station(m, item, function(model, w, h, d, boardX, plateX)
			Kit.box(model, 2.4, 0.18, 1.5, boardX, h + 0.09, 0.05, P.hinoki, M.wood)
			Kit.box(model, 2.3, 0.02, 1.4, boardX, h + 0.185, 0.05, P.paper_warm, M.wood, { collide = false })
			Kit.box(model, 1.4, 0.2, 0.8, plateX, h + 0.1, 0.1, P.wood_light, M.wood, { collide = false })
			Kit.cyl(model, 0.6, 0.35, plateX - 0.2, h + 0.18, -0.6, P.porcelain, M.smooth, { collide = false })
			Kit.box(model, 0.08, 0.04, 1.2, boardX + 1.4, h + 0.04, -0.6, P.metal, M.metal, { collide = false })
			Kit.box(model, 0.8, 0.5, 0.5, w / 2 - 0.5, h + 0.25, -0.75, P.wood_dark, M.wood, { collide = false })
		end)
	end)

	Registry.register("ramen_station", function(m, item)
		station(m, item, function(model, w, h, d, boardX, plateX)
			-- noodle boiler with tebo baskets
			local bx = boardX - 0.3
			Kit.box(model, 1.9, 0.6, 1.5, bx, h + 0.3, 0.05, P.steel_dark, M.metal)
			local water = Kit.box(model, 1.7, 0.05, 1.3, bx, h + 0.6, 0.05, P.water, M.glass, { collide = false, transparency = 0.3, name = "Water" })
			Kit.particles(water, "steam", { rate = 2 })
			for _, c in ipairs({ { -0.45, -0.3 }, { 0.45, -0.3 }, { -0.45, 0.35 }, { 0.45, 0.35 } }) do
				Kit.cyl(model, 0.5, 0.5, bx + c[1], h + 0.65, 0.05 + c[2], P.metal, M.metal, { collide = false, transparency = 0.2 })
				Kit.cylH(model, 0.06, 0.9, bx + c[1], h + 1.0, 0.05 + c[2] - 0.55, P.wood_dark, M.wood, { collide = false }, "z")
			end
			Kit.box(model, 1.5, 0.12, 1.2, plateX - 0.1, h + 0.06, 0.1, P.wood_light, M.wood, { collide = false })
			-- topping tray
			for i = 0, 3 do
				Kit.box(model, 0.35, 0.15, 0.5, plateX - 0.6 + i * 0.4, h + 0.08, -0.75, P.metal, M.metal, { collide = false })
			end
		end)
	end)

	Registry.register("drink_station", function(m, item)
		station(m, item, function(model, w, h, d, boardX, plateX)
			Kit.cyl(model, 0.9, 1.3, boardX - 0.3, h + 0.65, 0.3, P.metal, M.metal, { reflectance = 0.15 })
			Kit.box(model, 0.2, 0.2, 0.3, boardX - 0.3, h + 0.4, -0.25, P.charcoal, M.smooth, { collide = false })
			for i = 0, 3 do
				Kit.cyl(model, 0.32, 0.4, boardX + 0.6 + (i % 2) * 0.4, h + 0.2, -0.3 + math.floor(i / 2) * 0.45, P.porcelain, M.smooth, { collide = false })
			end
			Kit.box(model, 1.2, 0.08, 0.8, plateX, h + 0.04, 0.1, P.wood_dark, M.wood, { collide = false })
		end)
	end)

	Registry.register("griddle", function(m, item)
		station(m, item, function(model, w, h, d, boardX, plateX)
			Kit.box(model, 2.6, 0.12, 1.6, boardX + 0.1, h + 0.06, 0.05, P.charcoal, M.metal, { reflectance = 0.05 })
			local heat = Kit.box(model, 2.4, 0.02, 1.4, boardX + 0.1, h + 0.13, 0.05, P.steel_dark, M.metal, { collide = false, name = "Heat" })
			Kit.particles(heat, "smoke", { enabled = false })
			Kit.box(model, 0.1, 0.05, 0.8, boardX + 1.5, h + 0.2, -0.5, P.metal, M.metal, { collide = false })
			Kit.box(model, 1, 0.08, 0.7, plateX + 0.1, h + 0.04, 0.1, P.wood_light, M.wood, { collide = false })
		end)
	end)

	Registry.register("fryer", function(m, item)
		station(m, item, function(model, w, h, d, boardX, plateX)
			Kit.box(model, 1.4, 0.5, 1.4, boardX - 0.1, h + 0.25, 0.05, P.steel_dark, M.metal)
			local oil = Kit.box(model, 1.2, 0.04, 1.2, boardX - 0.1, h + 0.5, 0.05, P.gold, M.glass, { collide = false, transparency = 0.2, name = "Oil" })
			Kit.particles(oil, "bubbles", { enabled = false })
			Kit.box(model, 0.9, 0.35, 0.9, boardX - 0.1, h + 0.75, 0.05, P.metal, M.metal, { collide = false, transparency = 0.4 })
			Kit.box(model, 0.8, 0.08, 0.6, plateX + 0.2, h + 0.04, 0.1, P.paper, M.smooth, { collide = false })
		end)
	end)

	Registry.register("takoyaki_stove", function(m, item)
		station(m, item, function(model, w, h, d, boardX, plateX)
			Kit.box(model, 1.6, 0.25, 1.3, boardX - 0.1, h + 0.125, 0.05, P.charcoal, M.metal)
			for i = 0, 3 do
				for j = 0, 2 do
					Kit.cyl(model, 0.28, 0.02, boardX - 0.65 + i * 0.36, h + 0.26, -0.3 + j * 0.35, P.black, M.smooth, { collide = false })
				end
			end
			Kit.box(model, 0.8, 0.1, 0.6, plateX + 0.2, h + 0.05, 0.1, P.wood_light, M.wood, { collide = false })
		end)
	end)

	Registry.register("dessert_station", function(m, item)
		station(m, item, function(model, w, h, d, boardX, plateX)
			Kit.box(model, 2, 0.12, 1.3, boardX, h + 0.06, 0.05, P.porcelain, M.marble)
			for i, c in ipairs({ P.sakura, P.white, P.matcha }) do
				Kit.ball(model, 0.35, boardX - 0.6 + i * 0.35, h + 0.3, -0.45, c, M.smooth, { collide = false })
			end
			Kit.box(model, 1, 0.08, 0.7, plateX, h + 0.04, 0.1, P.lacquer, M.smooth, { collide = false })
		end)
	end)

	Registry.register("sink", function(m, item)
		local root = Kit.finish(m, size(item))
		local w, h, d = item.size[1], item.size[2], item.size[3]
		cabinet(m, w, h, d, P.metal, P.steel)
		-- basin (built from walls so it looks hollow)
		local bw, bd = w - 1.4, d - 0.6
		Kit.box(m, bw, 0.08, bd, -0.4, h - 0.7, 0, P.steel_dark, M.metal, { collide = false })
		for _, s in ipairs({ { 0, -bd / 2, bw, 0.08 }, { 0, bd / 2, bw, 0.08 }, { -bw / 2, 0, 0.08, bd }, { bw / 2, 0, 0.08, bd } }) do
			Kit.box(m, s[3], 0.7, s[4], -0.4 + s[1], h - 0.35, s[2], P.metal, M.metal, { collide = false })
		end
		local water = Kit.box(m, bw - 0.1, 0.05, bd - 0.1, -0.4, h - 0.45, 0, P.water, M.glass, { transparency = 0.35, collide = false, name = "Water" })
		local _ = water
		-- faucet
		Kit.cyl(m, 0.12, 1.2, -0.4, h + 0.55, bd / 2 - 0.1, P.metal, M.metal, { collide = false })
		local spout = Kit.cylH(m, 0.1, 0.7, -0.4, h + 1.1, bd / 2 - 0.4, P.metal, M.metal, { collide = false, name = "Spout" }, "z")
		Kit.particles(spout, "water", { enabled = false })
		-- drying rack with plates
		for i = 0, 3 do
			Kit.cyl(m, 0.7, 0.06, w / 2 - 0.55, h + 0.4, -0.45 + i * 0.3, P.porcelain, M.smooth, { collide = false, rot = CFrame.Angles(math.rad(90), 0, 0) })
		end
		point(root, "Basin", -0.4, h, 0)
		point(root, "Dirty", w / 2 - 0.55, h + 0.1, 0.45)
	end)

	Registry.register("dishwasher", function(m, item)
		local root = Kit.finish(m, size(item))
		local w, h, d = item.size[1], item.size[2], item.size[3]
		Kit.box(m, w, h, d, 0, h / 2, 0, P.metal, M.metal, { reflectance = 0.1 })
		Kit.box(m, w - 0.3, h - 1, 0.06, 0, h / 2 - 0.2, -d / 2 - 0.02, P.steel, M.metal, { collide = false })
		Kit.box(m, w - 0.8, 0.8, 0.04, 0, h / 2 + 0.2, -d / 2 - 0.05, P.glass, M.glass, { collide = false, transparency = 0.3 })
		Kit.box(m, w - 0.6, 0.12, 0.12, 0, h - 0.55, -d / 2 - 0.1, P.steel_dark, M.metal, { collide = false })
		Kit.box(m, 0.18, 0.18, 0.05, w / 2 - 0.35, h - 0.25, -d / 2 - 0.03, P.neon_blue, M.neon, { collide = false, name = "Led" })
		local steam = Kit.box(m, 0.4, 0.1, 0.4, 0, h + 0.05, 0, P.white, M.smooth, { transparency = 1, collide = false, name = "Steam" })
		Kit.particles(steam, "steam", { enabled = false })
		point(root, "Content", 0, h, 0)
	end)

	Registry.register("fridge", function(m, item)
		local root = Kit.finish(m, size(item))
		local w, h, d = item.size[1], item.size[2], item.size[3]
		Kit.box(m, w, h, d, 0, h / 2, 0, P.metal, M.metal, { reflectance = 0.15 })
		for _, x in ipairs({ -w / 4, w / 4 }) do
			Kit.box(m, w / 2 - 0.08, h - 0.6, 0.06, x, h / 2, -d / 2 - 0.03, P.steel, M.metal, { collide = false, reflectance = 0.2 })
			Kit.box(m, 0.08, 1.6, 0.12, x + (x < 0 and w / 4 - 0.2 or -w / 4 + 0.2), h / 2 + 0.5, -d / 2 - 0.1, P.steel_dark, M.metal, { collide = false })
		end
		local display = Kit.box(m, 0.8, 0.3, 0.04, 0, h - 0.25, -d / 2 - 0.04, P.charcoal, M.smooth, { collide = false })
		Kit.text(display, Enum.NormalId.Front, "2°C", { color = "#3BC8FF", glow = true })
		local _ = root
	end)
end
