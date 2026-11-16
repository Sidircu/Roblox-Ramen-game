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

local NC = { collide = false, shadow = false }
local function nc()
	return { collide = false, shadow = false }
end
local JP_FONT = Font.new("rbxasset://fonts/families/FredokaOne.json", Enum.FontWeight.Bold)

-- Steel (or wooden) work cabinet: recessed kick plate, framed doors with bar handles,
-- thick top with a front lip. The cook side is -Z.
local function cabinet(m, w, h, d, top, body, wood)
	local bodyColor = body or P.metal
	local mat = wood and M.wood or M.metal
	Kit.box(m, w - 0.24, 0.35, d - 0.3, 0, 0.175, 0.05, P.charcoal, M.smooth)
	Kit.box(m, w, h - 0.55, d, 0, 0.35 + (h - 0.55) / 2, 0, bodyColor, mat)
	Kit.box(m, w + 0.08, 0.2, d + 0.1, 0, h - 0.1, 0.02, top or P.metal, wood and M.wood or M.metal, { reflectance = wood and 0 or 0.12 })
	Kit.box(m, w + 0.08, 0.08, 0.1, 0, h + 0.02, -d / 2 - 0.02, top or P.metal, M.metal, nc())
	local doors = math.max(1, math.floor(w / 1.6))
	local dw = w / doors
	for i = 0, doors - 1 do
		local x = -w / 2 + dw * (i + 0.5)
		local doorH = h - 1.1
		local cy = 0.4 + doorH / 2
		Kit.box(m, dw - 0.18, doorH, 0.05, x, cy, -d / 2 - 0.025, wood and P.wood or P.steel, mat, nc())
		Kit.box(m, dw - 0.42, doorH - 0.3, 0.03, x, cy, -d / 2 - 0.06, wood and P.wood_light or P.metal, mat, nc())
		local hx = x + (i % 2 == 0 and (dw / 2 - 0.35) or -(dw / 2 - 0.35))
		Kit.box(m, 0.07, 0.9, 0.07, hx, cy + 0.3, -d / 2 - 0.13, P.steel_dark, M.metal, nc())
	end
end

-- Small wooden name plate with kanji on the cook side of a station
local function plate(m, x, y, z, text)
	local p = Kit.box(m, 1.0, 0.45, 0.06, x, y, z, P.hinoki, M.wood, nc())
	Kit.text(p, Enum.NormalId.Front, text, { color = "#2B2320", font = JP_FONT, pps = 40 })
	return p
end

local function knobs(m, n, x0, y, z)
	for i = 0, n - 1 do
		Kit.cylH(m, 0.22, 0.12, x0 + i * 0.4, y, z, P.charcoal, M.smooth, nc(), "z")
		Kit.box(m, 0.04, 0.12, 0.04, x0 + i * 0.4, y + 0.05, z - 0.07, P.neon_red, M.smooth, nc())
	end
end

-- Extraction hood with a duct to the ceiling (over hot stations)
local function hood(m, w, h, d)
	-- high and shallow so it never hides the board from the game camera
	local y = h + 5.2
	local hd = 1.5
	local hz = d / 2 - hd / 2
	Kit.box(m, w - 0.8, 0.7, hd, 0, y, hz, P.metal, M.metal, { collide = false, reflectance = 0.15 })
	Kit.wedge(m, w - 0.8, 0.5, hd, CFrame.new(0, y + 0.6, hz) * CFrame.Angles(0, math.rad(180), 0), P.metal, M.metal, nc())
	Kit.box(m, w - 0.9, 0.06, hd - 0.1, 0, y - 0.36, hz, P.steel_dark, M.metal, nc())
	Kit.box(m, 0.8, 13.9 - (y + 0.85), 0.8, 0, (y + 0.85 + 13.9) / 2, d / 2 - 0.45, P.metal, M.metal, nc())
	local light = Kit.box(m, w - 1.6, 0.05, 0.3, 0, y - 0.38, hz - 0.4, P.lamp, M.neon, nc())
	Kit.light(light, "Surface", P.lamp, 8, 0.8, { face = Enum.NormalId.Bottom, night = false })
end

-- Backsplash with a narrow shelf (back = +Z)
local function backsplash(m, w, h, d, tiles)
	Kit.box(m, w, 1.0, 0.1, 0, h + 0.5, d / 2 - 0.05, tiles and P.white or P.metal, tiles and M.tiles or M.metal, nc())
	Kit.box(m, w, 0.08, 0.35, 0, h + 1.04, d / 2 - 0.2, P.metal, M.metal, nc())
end

-- Utensil rail with hanging tools
local function utensilRail(m, w, h, d, tools)
	local y = h + 1.6
	local z = d / 2 - 0.15
	Kit.cylH(m, 0.06, w - 0.6, 0, y, z, P.metal, M.metal, nc())
	local n = #tools
	for i, t in ipairs(tools) do
		local x = -w / 2 + 0.6 + (w - 1.2) * (i - 0.5) / n
		Kit.cyl(m, 0.04, 0.9, x, y - 0.45, z, P.metal, M.metal, nc())
		if t == "ladle" then
			Kit.blob(m, 0.35, 0.18, 0.35, x, y - 0.95, z - 0.05, P.metal, M.metal, nc())
		elseif t == "strainer" then
			Kit.cyl(m, 0.42, 0.06, x, y - 0.95, z - 0.1, P.steel, M.metal, { collide = false, shadow = false, rot = CFrame.Angles(math.rad(80), 0, 0) })
		elseif t == "spatula" then
			Kit.box(m, 0.35, 0.3, 0.03, x, y - 0.95, z - 0.03, P.metal, M.metal, nc())
		elseif t == "towel" then
			Kit.box(m, 0.5, 0.8, 0.04, x, y - 0.4, z - 0.05, P.white, M.fabric, nc())
			Kit.box(m, 0.5, 0.1, 0.045, x, y - 0.55, z - 0.05, P.indigo, M.fabric, nc())
		end
	end
end

local function bowlStack(m, x, z, y0, n, color)
	for i = 0, n - 1 do
		Kit.cyl(m, 0.7, 0.14, x, y0 + 0.07 + i * 0.15, z, color, M.smooth, nc())
		Kit.cyl(m, 0.72, 0.03, x, y0 + 0.14 + i * 0.15, z, P.lacquer, M.smooth, nc())
	end
end

local function pan(m, x, z, y0, color)
	Kit.box(m, 0.42, 0.14, 0.42, x, y0 + 0.07, z, P.metal, M.metal, nc())
	Kit.box(m, 0.36, 0.05, 0.36, x, y0 + 0.13, z, color, M.smooth, nc())
end

local function shelfUnit(m, item)
	local root = Kit.finish(m, size(item))
	local w, h, d = item.size[1], item.size[2], item.size[3]
	local slots = item.fn.slots
	local cols = slots > 4 and 2 or 1
	local rows = math.ceil(slots / cols)
	-- frame: dark posts on black feet, light hinoki back boards
	Kit.box(m, w, h, 0.12, 0, h / 2, d / 2 - 0.06, P.wood_dark, M.planks)
	local dk = Kit.detail(m, "kitchen")
	Kit.box(dk, w - 0.4, h - 0.3, 0.03, 0, h / 2, d / 2 - 0.135, P.hinoki, M.planks, nc())
	for _, x in ipairs({ -w / 2 + 0.1, w / 2 - 0.1 }) do
		Kit.box(m, 0.2, h, d, x, h / 2, 0, P.wood_dark, M.wood)
		Kit.box(dk, 0.28, 0.12, d + 0.08, x, 0.06, 0, P.wood_black, M.wood, nc())
		for _, y in ipairs({ 0.55, h - 0.55 }) do
			Kit.box(dk, 0.24, 0.3, 0.03, x, y, -d / 2 - 0.015, P.charcoal, M.metal, nc())
			Kit.ball(dk, 0.07, x, y, -d / 2 - 0.04, P.brass, M.metal, nc())
		end
	end
	if cols == 2 then
		Kit.box(m, 0.14, h, d, 0, h / 2, 0, P.wood_dark, M.wood)
	end
	local rowH = (h - 0.3) / rows
	local idx = 0
	for r = 0, rows - 1 do
		local y = 0.15 + r * rowH
		Kit.box(m, w - 0.2, 0.12, d, 0, y, 0, P.wood_light, M.wood)
		Kit.box(dk, w - 0.3, 0.16, 0.05, 0, y + 0.02, -d / 2 - 0.02, P.wood_dark, M.wood, nc())
		for c = 0, cols - 1 do
			idx += 1
			if idx <= slots then
				local cw = (w - 0.3) / cols
				local x = -w / 2 + 0.15 + cw * (c + 0.5)
				local s = slot(m, idx, cw - 0.1, rowH - 0.2, d - 0.1, x, y + 0.06 + (rowH - 0.2) / 2, 0)
				s:SetAttribute("Width", cw - 0.2)
				-- paper price tag on the shelf lip
				Kit.box(dk, 0.55, 0.13, 0.02, x, y + 0.02, -d / 2 - 0.055, P.paper, M.smooth, nc())
				Kit.box(dk, 0.12, 0.13, 0.025, x - 0.2, y + 0.02, -d / 2 - 0.058, P.lacquer, M.smooth, nc())
			end
		end
	end
	-- crown with a kanji header board ("ingredients")
	Kit.box(m, w + 0.2, 0.18, d + 0.15, 0, h - 0.06, -0.02, P.wood_black, M.wood)
	Kit.box(dk, w + 0.3, 0.06, d + 0.25, 0, h + 0.06, -0.02, P.wood_dark, M.wood, nc())
	local sign = Kit.box(dk, math.min(2.2, w - 0.8), 0.6, 0.08, 0, h + 0.4, -d / 2 + 0.2, P.hinoki, M.wood, nc())
	Kit.text(sign, Enum.NormalId.Front, "食材", { color = "#2B2320", font = JP_FONT, pps = 40 })
	Kit.box(dk, math.min(2.2, w - 0.8) + 0.12, 0.08, 0.1, 0, h + 0.74, -d / 2 + 0.2, P.wood_dark, M.wood, nc())
end

local function riceCooker(m, item, pro)
	local root = Kit.finish(m, size(item))
	local w, h = item.size[1], item.size[2]
	local standH = h - 1.4
	-- wooden stand with a drawer and kanji label
	Kit.box(m, w, standH, w, 0, standH / 2, 0, P.wood_dark, M.wood)
	local dk = Kit.detail(m, "kitchen")
	Kit.box(dk, w + 0.1, 0.1, w + 0.1, 0, standH - 0.05, 0, P.wood_black, M.wood, nc())
	Kit.box(dk, w - 0.3, standH - 0.45, 0.04, 0, standH / 2 + 0.05, -w / 2 - 0.02, P.wood, M.wood, nc())
	Kit.box(dk, 0.4, 0.06, 0.06, 0, standH - 0.35, -w / 2 - 0.06, P.brass, M.metal, nc())
	local label = Kit.box(dk, 0.8, 0.34, 0.03, 0, standH / 2 - 0.1, -w / 2 - 0.05, P.paper, M.smooth, nc())
	Kit.text(label, Enum.NormalId.Front, "炊飯", { color = "#2B2320", font = JP_FONT, pps = 40 })
	-- cooker body with side handles, lid, steam vent and control panel
	local r = w - 0.35
	local body = Kit.cyl(m, r, 1.0, 0, standH + 0.5, 0, pro and P.metal or P.white, pro and M.metal or M.smooth, { name = "Body", reflectance = pro and 0.12 or 0 })
	Kit.cyl(m, r + 0.04, 0.08, 0, standH + 0.12, 0, P.charcoal, M.smooth, nc())
	Kit.cyl(dk, r + 0.04, 0.05, 0, standH + 0.98, 0, pro and P.steel or P.sakura_dark, M.smooth, nc())
	for _, sx in ipairs({ -1, 1 }) do
		Kit.box(dk, 0.12, 0.1, 0.5, sx * (r / 2 + 0.04), standH + 0.85, 0, P.charcoal, M.smooth, nc())
	end
	Kit.blob(m, r - 0.05, 0.35, r - 0.05, 0, standH + 1.05, 0, pro and P.steel or P.porcelain, M.smooth, nc())
	Kit.box(m, 0.5, 0.12, 0.1, 0, standH + 1.25, -0.25, P.charcoal, M.smooth, nc())
	Kit.cyl(m, 0.16, 0.08, 0, standH + 1.24, 0.15, P.steel_dark, M.metal, nc())
	local panel = Kit.box(m, 0.6, 0.3, 0.06, 0, standH + 0.55, -r / 2 - 0.02, P.charcoal, M.smooth, nc())
	Kit.box(m, 0.42, 0.08, 0.03, -0.05, standH + 0.6, -r / 2 - 0.06, P.neon_blue, M.neon, nc())
	local led = Kit.box(m, 0.12, 0.12, 0.04, 0.15, standH + 0.48, -r / 2 - 0.06, P.neon_red, M.neon, { collide = false, name = "Led" })
	local _ = panel
	local _2 = led
	-- rice paddle (shamoji) in its holder
	Kit.cyl(dk, 0.16, 0.4, r / 2 + 0.12, standH + 0.55, -0.2, P.white, M.smooth, nc())
	Kit.box(dk, 0.08, 0.6, 0.04, r / 2 + 0.12, standH + 0.8, -0.2, P.hinoki, M.wood, nc())
	Kit.blob(dk, 0.24, 0.3, 0.06, r / 2 + 0.12, standH + 1.15, -0.2, P.hinoki, M.wood, nc())
	local vent = Kit.box(m, 0.2, 0.1, 0.2, 0, standH + 1.3, 0.15, P.white, M.smooth, { transparency = 1, collide = false, name = "Steam" })
	Kit.particles(vent, "steam", { enabled = false })
	local _3 = body
	point(root, "Content", 0, standH + 1.1, 0)
end

local function brothPot(m, item, large)
	local root = Kit.finish(m, size(item))
	local w, h = item.size[1], item.size[2]
	local stoveH = 1.5
	cabinet(m, w, stoveH, w, P.steel_dark, P.steel)
	local dk = Kit.detail(m, "kitchen")
	plate(dk, w / 2 - 0.75, stoveH - 0.45, -w / 2 - 0.12, "出汁")
	knobs(m, 2, -w / 2 + 0.45, stoveH - 0.45, -w / 2 - 0.08)
	-- burner ring and cast iron grate
	Kit.cyl(m, w * 0.6, 0.06, 0, stoveH + 0.03, 0, P.neon_blue, M.neon, { collide = false, name = "Flame" })
	Kit.cyl(m, w * 0.35, 0.08, 0, stoveH + 0.05, 0, P.charcoal, M.metal, nc())
	for i = 0, 3 do
		Kit.box(m, w * 0.85, 0.08, 0.1, 0, stoveH + 0.1, 0, P.charcoal, M.metal, { collide = false, shadow = false, rot = CFrame.Angles(0, math.rad(i * 45), 0) })
	end
	local potH = h - stoveH - 0.2
	local d = w - 0.4
	Kit.cyl(m, d, potH, 0, stoveH + potH / 2 + 0.15, 0, P.metal, M.metal, { reflectance = 0.15, name = "Body" })
	for _, y in ipairs({ 0.35, potH - 0.45 }) do
		Kit.cyl(dk, d + 0.05, 0.06, 0, stoveH + 0.15 + y, 0, P.steel, M.metal, nc())
	end
	Kit.cyl(m, d + 0.1, 0.12, 0, stoveH + potH + 0.1, 0, P.steel, M.metal, { collide = false })
	local broth = Kit.cyl(m, d - 0.15, 0.06, 0, stoveH + potH - 0.02, 0, P.wood, M.smooth, { collide = false, name = "Broth", transparency = 1 })
	broth:SetAttribute("Fill", true)
	for _, x in ipairs({ -d / 2 - 0.15, d / 2 + 0.15 }) do
		Kit.box(m, 0.3, 0.12, 0.6, x, stoveH + potH - 0.25, 0, P.steel_dark, M.metal, { collide = false })
		Kit.box(m, 0.12, 0.3, 0.12, x - (x > 0 and 0.08 or -0.08), stoveH + potH - 0.12, 0.22, P.steel_dark, M.metal, nc())
		Kit.box(m, 0.12, 0.3, 0.12, x - (x > 0 and 0.08 or -0.08), stoveH + potH - 0.12, -0.22, P.steel_dark, M.metal, nc())
	end
	-- lid leaning against the back of the pot
	Kit.cyl(dk, d * 0.9, 0.08, 0, stoveH + potH / 2 + 0.3, d / 2 + 0.25, P.metal, M.metal, { collide = false, shadow = false, rot = CFrame.Angles(math.rad(80), 0, 0) })
	Kit.box(dk, 0.4, 0.1, 0.12, 0, stoveH + potH / 2 + 0.3, d / 2 + 0.2, P.wood_dark, M.wood, nc())
	-- long ladle (handle + bowl) resting in the pot
	Kit.cyl(m, 0.08, 2.2, d / 4, stoveH + potH + 0.45, 0, P.metal, M.metal, { collide = false, rot = CFrame.Angles(0, 0, math.rad(25)) })
	Kit.cyl(m, 0.1, 0.4, d / 4 - 0.5, stoveH + potH + 1.4, 0, P.wood_dark, M.wood, { collide = false, rot = CFrame.Angles(0, 0, math.rad(25)) })
	local vent = Kit.box(m, d - 0.4, 0.1, d - 0.4, 0, stoveH + potH + 0.2, 0, P.white, M.smooth, { transparency = 1, collide = false, name = "Steam" })
	Kit.particles(vent, "steam", { enabled = false, rate = large and 10 or 6 })
	Kit.particles(broth, "bubbles", { enabled = false })
	point(root, "Content", 0, stoveH + potH, 0)
end

-- Work station: cabinet with the board area (-x), the plate spot (+x) and a tool hovering point.
-- opts: { wood = bool, hood = bool, plate = "寿司", tools = {...}, tiles = bool, knobs = n }
local function station(m, item, deco, opts)
	opts = opts or {}
	local root = Kit.finish(m, size(item))
	local w, h, d = item.size[1], item.size[2], item.size[3]
	-- plain steel cabinet; the "chef gear" renovation (Detail_kitchen) adds the wooden sushi
	-- counter front, backsplash, utensil rail, kanji plate and the small props of each station
	local dk = Kit.detail(m, "kitchen")
	cabinet(m, w, h, d, P.metal, P.metal, false)
	if opts.wood then
		Kit.box(dk, w + 0.1, h - 0.6, 0.06, 0, 0.35 + (h - 0.55) / 2, -d / 2 - 0.16, P.wood_dark, M.wood, nc())
		for i = 0, math.floor(w / 0.45) do
			Kit.box(dk, 0.1, h - 0.8, 0.06, -w / 2 + 0.2 + i * 0.45, 0.35 + (h - 0.55) / 2, -d / 2 - 0.21, P.wood, M.wood, nc())
		end
		Kit.box(dk, w + 0.1, 0.06, d + 0.12, 0, h + 0.03, 0.02, P.hinoki, M.wood, nc())
	end
	backsplash(dk, w, h, d, opts.tiles)
	if opts.tools then
		utensilRail(dk, w, h, d, opts.tools)
	end
	if opts.hood then
		hood(m, w, h, d)
	end
	if opts.knobs then
		knobs(m, opts.knobs, -0.4 * (opts.knobs - 1) / 2, h - 0.45, -d / 2 - 0.08)
	end
	if opts.plate then
		plate(dk, w / 2 - 0.8, h - 0.75, -d / 2 - 0.12, opts.plate)
	end
	local boardX = -w / 2 + 1.4
	local plateX = w / 2 - 0.9
	deco(m, w, h, d, boardX, plateX, dk)
	point(root, "Board", boardX, h + 0.1, 0.05)
	point(root, "Plate", plateX, h + 0.05, 0.1)
	point(root, "Tool", boardX, h + 1.2, -0.1)
	point(root, "Cook", 0, 0, -d / 2 - 1.3, 0)
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
		station(m, item, function(model, w, h, d, boardX, plateX, extra)
			-- hinoki board with a yanagiba knife and a wet cloth
			Kit.box(model, 2.0, 0.18, 1.5, boardX, h + 0.09, 0.05, P.hinoki, M.wood)
			Kit.box(model, 1.9, 0.02, 1.4, boardX, h + 0.185, 0.05, P.paper_warm, M.wood, nc())
			Kit.box(extra, 1.2, 0.02, 0.12, boardX + 0.2, h + 0.2, -0.62, P.metal, M.metal, { collide = false, shadow = false, reflectance = 0.3 })
			Kit.box(extra, 0.45, 0.06, 0.1, boardX - 0.6, h + 0.2, -0.62, P.wood_black, M.wood, nc())
			-- hangiri rice tub with shamoji paddle
			local tx, tz = boardX + 1.5, 0.72
			Kit.cyl(extra, 1.1, 0.36, tx, h + 0.18, tz, P.hinoki, M.wood, nc())
			Kit.cyl(extra, 1.14, 0.06, tx, h + 0.1, tz, P.copper, M.metal, nc())
			Kit.cyl(extra, 1.14, 0.06, tx, h + 0.3, tz, P.copper, M.metal, nc())
			Kit.blob(extra, 0.9, 0.25, 0.9, tx, h + 0.36, tz, P.rice, M.sand, nc())
			Kit.box(extra, 0.18, 0.04, 0.8, tx + 0.25, h + 0.48, tz - 0.1, P.wood_light, M.wood, { collide = false, shadow = false, rot = CFrame.Angles(math.rad(-12), math.rad(25), 0) })
			-- small dishes: wasabi and pickled ginger, water bowl (tezu)
			Kit.cyl(extra, 0.4, 0.06, plateX - 0.75, h + 0.03, -0.65, P.porcelain, M.smooth, nc())
			Kit.blob(extra, 0.2, 0.12, 0.2, plateX - 0.75, h + 0.1, -0.65, P.matcha, M.smooth, nc())
			Kit.cyl(extra, 0.4, 0.06, plateX - 0.3, h + 0.03, -0.65, P.porcelain, M.smooth, nc())
			Kit.blob(extra, 0.24, 0.1, 0.24, plateX - 0.3, h + 0.09, -0.65, P.sakura, M.smooth, nc())
			Kit.cyl(extra, 0.5, 0.25, boardX - 0.95, h + 0.13, 0.65, P.indigo, M.smooth, nc())
			Kit.cyl(extra, 0.44, 0.02, boardX - 0.95, h + 0.24, 0.65, P.water, M.glass, { collide = false, shadow = false, transparency = 0.3 })
			-- geta plate for the finished dish and a stack of spare plates
			Kit.box(model, 1.4, 0.12, 0.8, plateX, h + 0.06, 0.1, P.wood_light, M.wood, nc())
			for _, sx in ipairs({ -0.55, 0.55 }) do
				Kit.box(model, 0.12, 0.08, 0.8, plateX + sx, h + 0.0, 0.1, P.wood_light, M.wood, nc())
			end
			for i = 0, 3 do
				Kit.box(extra, 0.9, 0.06, 0.5, plateX + 0.15, h + 1.1 + i * 0.07, d / 2 - 0.2, P.wood_light, M.wood, nc())
			end
			-- rolled makisu and bamboo leaves on the shelf
			Kit.cylH(extra, 0.22, 0.9, -0.9, h + 1.2, d / 2 - 0.2, P.bamboo, M.wood, nc())
			for i = 0, 2 do
				Kit.blob(extra, 0.7, 0.03, 0.22, -2 + i * 0.25, h + 1.12, d / 2 - 0.22, P.leaf, M.leafy, { collide = false, shadow = false, rot = CFrame.Angles(0, math.rad(i * 20), 0) })
			end
			Kit.cyl(extra, 0.2, 0.45, 1.2, h + 1.3, d / 2 - 0.2, P.charcoal, M.smooth, nc())
			Kit.cyl(extra, 0.22, 0.06, 1.2, h + 1.55, d / 2 - 0.2, P.lacquer, M.smooth, nc())
		end, { wood = true, plate = "寿司", tools = { "towel", "ladle" } })
	end)

	Registry.register("ramen_station", function(m, item)
		station(m, item, function(model, w, h, d, boardX, plateX, extra)
			-- noodle boiler with four tebo baskets
			local bx = boardX - 0.3
			Kit.box(model, 1.9, 0.6, 1.5, bx, h + 0.3, 0.05, P.steel_dark, M.metal)
			local water = Kit.box(model, 1.7, 0.05, 1.3, bx, h + 0.6, 0.05, P.water, M.glass, { collide = false, transparency = 0.3, name = "Water" })
			Kit.particles(water, "steam", { rate = 3 })
			for _, c in ipairs({ { -0.45, -0.3 }, { 0.45, -0.3 }, { -0.45, 0.35 }, { 0.45, 0.35 } }) do
				Kit.cyl(model, 0.5, 0.5, bx + c[1], h + 0.65, 0.05 + c[2], P.metal, M.metal, { collide = false, transparency = 0.2 })
				Kit.cylH(model, 0.06, 0.9, bx + c[1], h + 1.0, 0.05 + c[2] - 0.55, P.wood_dark, M.wood, nc(), "z")
			end
			-- bowl for the finished dish on a wooden tray
			Kit.box(model, 1.5, 0.12, 1.2, plateX - 0.1, h + 0.06, 0.1, P.wood_light, M.wood, nc())
			-- topping pans: scallion, naruto, chashu, corn, egg
			local colors = { P.leaf_light, P.sakura, P.copper, P.neon_yellow }
			for i, c in ipairs(colors) do
				pan(extra, -0.2 + (i - 1) * 0.44, -0.72, h, c)
			end
			-- tare pots and bowl stacks on the back shelf
			for i = 0, 2 do
				Kit.cyl(extra, 0.38, 0.4, -1.8 + i * 0.5, h + 1.3, d / 2 - 0.2, P.metal, M.metal, nc())
				Kit.cyl(extra, 0.32, 0.03, -1.8 + i * 0.5, h + 1.51, d / 2 - 0.2, ({ P.wood, P.cream, P.copper })[i + 1], M.smooth, nc())
			end
			bowlStack(extra, 0.6, d / 2 - 0.25, h + 1.08, 4, P.charcoal)
			bowlStack(extra, 1.4, d / 2 - 0.25, h + 1.08, 4, P.lacquer_dark)
		end, { hood = true, plate = "麺", tools = { "ladle", "ladle", "strainer", "towel" }, tiles = true, knobs = 3 })
	end)

	Registry.register("drink_station", function(m, item)
		station(m, item, function(model, w, h, d, boardX, plateX, extra)
			-- tea urn with a tap
			Kit.cyl(model, 0.9, 1.3, boardX - 0.3, h + 0.65, 0.35, P.metal, M.metal, { reflectance = 0.15 })
			Kit.cyl(model, 0.95, 0.12, boardX - 0.3, h + 1.32, 0.35, P.steel_dark, M.metal, nc())
			Kit.box(model, 0.18, 0.18, 0.35, boardX - 0.3, h + 0.35, -0.2, P.charcoal, M.smooth, nc())
			-- ramune bottles in an ice bucket
			Kit.cyl(extra, 0.8, 0.5, boardX + 0.75, h + 0.25, 0.45, P.metal, M.metal, nc())
			Kit.cyl(extra, 0.7, 0.05, boardX + 0.75, h + 0.48, 0.45, P.glass, M.glass, { collide = false, shadow = false, transparency = 0.2 })
			for i = 0, 3 do
				local a = i * math.pi / 2
				Kit.cyl(extra, 0.16, 0.5, boardX + 0.75 + math.cos(a) * 0.18, h + 0.6, 0.45 + math.sin(a) * 0.18, P.glass, M.glass, { collide = false, shadow = false, transparency = 0.25 })
			end
			-- matcha bowl and whisk, cups
			Kit.cyl(extra, 0.5, 0.22, boardX + 0.2, h + 0.11, -0.55, P.stone_dark, M.smooth, nc())
			Kit.cyl(extra, 0.42, 0.02, boardX + 0.2, h + 0.21, -0.55, P.matcha, M.smooth, nc())
			Kit.cyl(extra, 0.2, 0.3, boardX + 0.75, h + 0.15, -0.55, P.bamboo, M.wood, nc())
			for i = 0, 3 do
				Kit.cyl(extra, 0.3, 0.32, -0.2 + i * 0.36, h + 1.25, d / 2 - 0.2, P.porcelain, M.smooth, nc())
			end
			Kit.box(model, 1.2, 0.08, 0.8, plateX, h + 0.04, 0.1, P.wood_dark, M.wood, nc())
		end, { plate = "茶", tools = { "towel" } })
	end)

	Registry.register("griddle", function(m, item)
		station(m, item, function(model, w, h, d, boardX, plateX, extra)
			Kit.box(model, 2.6, 0.12, 1.6, boardX + 0.1, h + 0.06, 0.05, P.charcoal, M.metal, { reflectance = 0.05 })
			for _, e in ipairs({ { 0, 0.82, 2.6, 0.06 }, { -1.27, 0, 0.06, 1.6 }, { 1.27, 0, 0.06, 1.6 } }) do
				Kit.box(model, e[3], 0.18, e[4], boardX + 0.1 + e[1], h + 0.15, 0.05 + e[2], P.steel_dark, M.metal, nc())
			end
			local heat = Kit.box(model, 2.4, 0.02, 1.4, boardX + 0.1, h + 0.13, 0.05, P.steel_dark, M.metal, { collide = false, name = "Heat" })
			Kit.particles(heat, "smoke", { enabled = false })
			Kit.cyl(extra, 0.22, 0.6, plateX + 0.5, h + 0.3, 0.6, P.gold, M.glass, { collide = false, shadow = false, transparency = 0.2 })
			Kit.box(extra, 0.1, 0.05, 0.8, boardX + 1.5, h + 0.2, -0.5, P.metal, M.metal, nc())
			Kit.box(model, 1, 0.08, 0.7, plateX + 0.1, h + 0.04, 0.1, P.wood_light, M.wood, nc())
		end, { hood = true, plate = "餃子", tools = { "spatula", "spatula", "towel" }, tiles = true, knobs = 2 })
	end)

	Registry.register("fryer", function(m, item)
		station(m, item, function(model, w, h, d, boardX, plateX, extra)
			Kit.box(model, 1.4, 0.5, 1.4, boardX - 0.1, h + 0.25, 0.05, P.steel_dark, M.metal)
			local oil = Kit.box(model, 1.2, 0.04, 1.2, boardX - 0.1, h + 0.5, 0.05, P.gold, M.glass, { collide = false, transparency = 0.2, name = "Oil" })
			Kit.particles(oil, "bubbles", { enabled = false })
			Kit.box(model, 0.9, 0.35, 0.9, boardX - 0.1, h + 0.75, 0.05, P.metal, M.metal, { collide = false, transparency = 0.4 })
			Kit.cylH(model, 0.06, 0.8, boardX - 0.1, h + 0.95, -0.7, P.charcoal, M.smooth, nc(), "z")
			-- draining rack with paper
			Kit.box(model, 0.8, 0.08, 0.6, plateX + 0.2, h + 0.04, 0.1, P.paper, M.smooth, nc())
		end, { hood = true, plate = "天ぷら", tools = { "strainer", "towel" }, tiles = true, knobs = 2 })
	end)

	Registry.register("takoyaki_stove", function(m, item)
		station(m, item, function(model, w, h, d, boardX, plateX, extra)
			Kit.box(model, 1.6, 0.25, 1.3, boardX - 0.1, h + 0.125, 0.05, P.charcoal, M.metal)
			for i = 0, 3 do
				for j = 0, 2 do
					Kit.cyl(model, 0.28, 0.02, boardX - 0.65 + i * 0.36, h + 0.26, -0.3 + j * 0.35, P.black, M.smooth, nc())
					if (i + j) % 2 == 0 then
						Kit.ball(model, 0.26, boardX - 0.65 + i * 0.36, h + 0.3, -0.3 + j * 0.35, P.copper, M.sand, nc())
					end
				end
			end
			Kit.box(model, 0.8, 0.1, 0.6, plateX + 0.2, h + 0.05, 0.1, P.wood_light, M.wood, nc())
		end, { hood = true, plate = "たこ焼", tools = { "towel" }, tiles = true, knobs = 1 })
	end)

	Registry.register("dessert_station", function(m, item)
		station(m, item, function(model, w, h, d, boardX, plateX, extra)
			Kit.box(model, 2, 0.12, 1.3, boardX, h + 0.06, 0.05, P.porcelain, M.marble)
			for i, c in ipairs({ P.sakura, P.white, P.matcha }) do
				Kit.ball(extra, 0.35, boardX - 0.6 + i * 0.35, h + 0.3, -0.45, c, M.smooth, nc())
			end
			-- glass cloche over a tray of mochi
			Kit.cyl(extra, 0.9, 0.06, plateX - 0.2, h + 1.12, d / 2 - 0.25, P.wood_dark, M.wood, nc())
			for i = 0, 2 do
				Kit.ball(extra, 0.25, plateX - 0.45 + i * 0.25, h + 1.27, d / 2 - 0.25, ({ P.sakura, P.white, P.matcha })[i + 1], M.smooth, nc())
			end
			Kit.ball(extra, 0.85, plateX - 0.2, h + 1.32, d / 2 - 0.25, P.glass, M.glass, { collide = false, shadow = false, transparency = 0.7 })
			Kit.box(model, 1, 0.08, 0.7, plateX, h + 0.04, 0.1, P.lacquer, M.smooth, nc())
		end, { plate = "甘味", tools = { "towel" } })
	end)

	Registry.register("sink", function(m, item)
		local root = Kit.finish(m, size(item))
		local w, h, d = item.size[1], item.size[2], item.size[3]
		cabinet(m, w, h, d, P.metal, P.steel)
		local dk = Kit.detail(m, "kitchen")
		backsplash(dk, w, h, d, true)
		plate(dk, w / 2 - 0.8, h - 0.75, -d / 2 - 0.12, "洗い場")
		-- double basin (built from walls so it looks hollow), soapy water in the left one
		local bw, bd = 1.25, d - 0.75
		for i, bx in ipairs({ -1.1, 0.25 }) do
			Kit.box(m, bw, 0.08, bd, bx, h - 0.7, 0, P.steel_dark, M.metal, nc())
			for _, s in ipairs({ { 0, -bd / 2, bw, 0.08 }, { 0, bd / 2, bw, 0.08 }, { -bw / 2, 0, 0.08, bd }, { bw / 2, 0, 0.08, bd } }) do
				Kit.box(m, s[3], 0.7, s[4], bx + s[1], h - 0.35, s[2], P.metal, M.metal, { collide = false, reflectance = 0.1 })
			end
			Kit.cyl(m, 0.2, 0.02, bx, h - 0.65, 0, P.charcoal, M.metal, nc())
			if i == 1 then
				Kit.box(m, bw - 0.1, 0.05, bd - 0.1, bx, h - 0.45, 0, P.water, M.glass, { transparency = 0.35, collide = false, name = "Water" })
				for k = 0, 4 do
					Kit.ball(dk, 0.18 + (k % 2) * 0.08, bx - 0.4 + k * 0.2, h - 0.4, -0.2 + (k % 3) * 0.15, P.white, M.smooth, { collide = false, shadow = false, transparency = 0.15 })
				end
			end
		end
		-- gooseneck faucet between the basins with a pre-rinse sprayer
		local fx, fz = -0.42, bd / 2 + 0.12
		Kit.cyl(m, 0.2, 0.12, fx, h + 0.06, fz, P.metal, M.metal, nc())
		Kit.cyl(m, 0.1, 1.4, fx, h + 0.8, fz, P.metal, M.metal, { collide = false, reflectance = 0.2 })
		Kit.cylH(m, 0.1, 0.6, fx, h + 1.5, fz - 0.27, P.metal, M.metal, { collide = false, shadow = false, reflectance = 0.2 }, "z")
		local spout = Kit.cyl(m, 0.1, 0.3, fx, h + 1.36, fz - 0.55, P.metal, M.metal, { collide = false, name = "Spout" })
		Kit.particles(spout, "water", { enabled = false })
		for _, sx in ipairs({ -0.3, 0.3 }) do
			Kit.cylH(dk, 0.12, 0.25, fx + sx, h + 0.35, fz, P.metal, M.metal, nc(), "x")
			Kit.box(dk, 0.05, 0.05, 0.25, fx + sx * 1.3, h + 0.35, fz - 0.1, sx < 0 and P.neon_red or P.neon_blue, M.smooth, nc())
		end
		-- sponge, dish soap and a tenugui towel over the cabinet lip
		Kit.box(dk, 0.35, 0.14, 0.22, -1.75, h + 0.07, bd / 2, P.leaf_light, M.fabric, nc())
		Kit.box(dk, 0.35, 0.05, 0.22, -1.75, h + 0.165, bd / 2, P.neon_yellow, M.fabric, nc())
		Kit.cyl(dk, 0.24, 0.5, -1.75, h + 0.25, bd / 2 - 0.4, P.leaf, M.plastic, { collide = false, shadow = false, transparency = 0.2 })
		Kit.cyl(dk, 0.08, 0.12, -1.75, h + 0.56, bd / 2 - 0.4, P.white, M.plastic, nc())
		Kit.box(dk, 0.6, 0.9, 0.03, 0.3, h - 0.4, -d / 2 - 0.16, P.white, M.fabric, nc())
		Kit.box(dk, 0.6, 0.12, 0.035, 0.3, h - 0.6, -d / 2 - 0.165, P.indigo, M.fabric, nc())
		-- wire drying rack with clean plates
		local rx = w / 2 - 0.55
		Kit.box(dk, 0.9, 0.05, d - 0.5, rx, h + 0.05, 0, P.metal, M.metal, nc())
		for _, sx in ipairs({ -0.42, 0.42 }) do
			for k = 0, 5 do
				Kit.box(dk, 0.03, 0.4, 0.03, rx + sx, h + 0.25, -0.75 + k * 0.3, P.metal, M.metal, nc())
			end
		end
		for i = 0, 3 do
			Kit.cyl(dk, 0.7, 0.06, rx, h + 0.42, -0.45 + i * 0.3, P.porcelain, M.smooth, { collide = false, rot = CFrame.Angles(math.rad(90), 0, 0) })
			Kit.cyl(dk, 0.74, 0.03, rx, h + 0.42, -0.45 + i * 0.3, P.indigo, M.smooth, { collide = false, shadow = false, rot = CFrame.Angles(math.rad(90), 0, 0) })
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
