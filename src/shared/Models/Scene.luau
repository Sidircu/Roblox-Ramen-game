--!nonstrict
-- Builds the restaurant shell (floors, walls, roof, facade, stairs) and the street scenery.
-- Shared so the server world builder and the preview renderer use the same code.
local CollectionService = game:GetService("CollectionService")

local Config = script.Parent.Parent.Config
local GameConfig = require(Config.GameConfig)
local Expansions = require(Config.Expansions)
local Surfaces = require(Config.Surfaces)
local Franchise = require(Config.Franchise)
local Footprint = require(script.Parent.Parent.Logic.Footprint)
local Registry = require(script.Parent.Registry)
local Kit = require(script.Parent.Kit)
local P = require(script.Parent.Palette)
local Color = require(script.Parent.Parent.Util.Color)

local Scene = {}

local function floorY(f)
	return (f or 0) * GameConfig.FloorHeight
end
Scene.floorY = floorY

local function zoneAt(geo, x, z, f)
	for _, zone in ipairs(geo.zones) do
		if zone.floor == (f or 0) and Footprint.pointInRect(x, z, zone.rect) then
			return zone
		end
	end
	return nil
end
Scene.zoneAt = zoneAt

local function style(id, kind)
	local s = Surfaces.byId[id]
	if not s or s.kind ~= kind then
		s = Surfaces.byId[kind == "floor" and Surfaces.DefaultFloor or Surfaces.DefaultWall]
	end
	return { color = Color.hex(s.color), material = P.material(s.material), lattice = s.lattice, stripes = s.stripes }
end

function Scene.surfaceOf(data, zone, kind)
	local s = data.surfaces[zone.id]
	local id = s and s[kind]
	if not id then
		id = kind == "floor" and (zone.floorStyle or Surfaces.DefaultFloor) or (zone.wallStyle or Surfaces.DefaultWall)
	end
	return id
end

local function holesFor(geo, floor)
	local holes = {}
	for _, s in ipairs(geo.stairs) do
		if s.floor == floor - 1 then
			table.insert(holes, s.rect)
		end
	end
	return holes
end

local function subtractAll(rect, holes)
	local rects = { rect }
	for _, h in ipairs(holes) do
		local next = {}
		for _, r in ipairs(rects) do
			for _, piece in ipairs(Footprint.subtractRect(r, h)) do
				table.insert(next, piece)
			end
		end
		rects = next
	end
	return rects
end

local function indoorAt(geo, x, z, floor)
	local zone = zoneAt(geo, x, z, floor)
	return zone and not zone.outdoor and zone or nil
end

function Scene.shell(shell, geo, data)
	shell:ClearAllChildren()
	local B = Registry.Building
	local floors = {}
	for _, z in ipairs(geo.zones) do
		floors[z.floor] = true
	end
	local topFloor = 0
	for f in pairs(floors) do
		topFloor = math.max(topFloor, f)
	end
	local deluxe = data.zones.facade_deluxe
	-- renovations bought so far (the starting restaurant is plain)
	local owned = data.zones
	local trim = { wainscot = owned.reno_wainscot, beams = owned.reno_beams, tiles = owned.reno_kitchen_tiles, storage = owned.reno_storage }
	local exterior = { color = deluxe and P.charcoal or P.cream, material = deluxe and P.M.wood or P.M.plaster }

	for _, zone in ipairs(geo.zones) do
		local fy = floorY(zone.floor)
		local attrs = { Zone = zone.id, FloorIndex = zone.floor, Area = zone.area }
		local floorStyle
		if zone.outdoor then
			if zone.area == "garden" then
				floorStyle = { color = P.moss, material = P.M.leafy }
			else
				floorStyle = { color = P.wood, material = P.M.planks }
			end
		else
			floorStyle = style(Scene.surfaceOf(data, zone, "floor"), "floor")
		end
		for _, r in ipairs(subtractAll(zone.rect, holesFor(geo, zone.floor))) do
			B.floorSkin(shell, r, fy, floorStyle, attrs)
			if zone.floor == 0 then
				B.slab(shell, r, zone.outdoor and -0.7 or -1.2, zone.outdoor and 0.5 or 1.0, P.stone_dark, P.M.concrete, "Foundation")
			end
		end
		if not zone.outdoor then
			-- ceiling / roof slab with holes where stairs go up
			local holes = {}
			for _, s in ipairs(geo.stairs) do
				if s.floor == zone.floor then
					table.insert(holes, s.rect)
				end
			end
			local covered = false
			for _, other in ipairs(geo.zones) do
				if other.floor == zone.floor + 1 and Footprint.pointInRect((zone.rect[1] + zone.rect[3]) / 2, (zone.rect[2] + zone.rect[4]) / 2, other.rect) then
					covered = true
				end
			end
			for _, r in ipairs(subtractAll(zone.rect, holes)) do
				local c = B.slab(shell, r, fy + GameConfig.WallHeight, 1, P.wood_dark, P.M.wood, "Ceiling")
				B.tag(c, "Ceiling", { FloorIndex = zone.floor })
				B.tag(c, "Roof")
				if not covered then
					-- flat roof finish with gravel and a few rooftop details
					local cover = B.slab(shell, r, fy + GameConfig.WallHeight + 1, 0.15, P.stone_dark, P.M.pebble, "RoofCover")
					B.tag(cover, "Roof")
				end
			end
			if not covered then
				local rr = zone.rect
				local cx, cz = (rr[1] + rr[3]) / 2, (rr[2] + rr[4]) / 2
				local top = fy + GameConfig.WallHeight + 1.15
				local unit = Kit.box(shell, 2.6, 1.6, 1.4, cx + 4, top + 0.8, cz + 3, P.white, P.M.metal, { collide = false })
				B.tag(unit, "Roof")
				local fan = Kit.cylH(shell, 1.1, 0.08, cx + 4, top + 0.8, cz + 2.27, P.steel_dark, P.M.metal, { collide = false, shadow = false }, "z")
				B.tag(fan, "Roof")
				local tank = Kit.cyl(shell, 2.2, 2.4, cx - 6, top + 1.6, cz + 5, P.metal, P.M.metal, { collide = false })
				B.tag(tank, "Roof")
				for _, dx in ipairs({ -0.7, 0.7 }) do
					local leg = Kit.box(shell, 0.2, 0.6, 0.2, cx - 6 + dx, top + 0.3, cz + 5, P.steel_dark, P.M.metal, { collide = false, shadow = false })
					B.tag(leg, "Roof")
				end
			end
			-- exposed beams (renovation) and soft ceiling lights
			local r = zone.rect
			if trim.beams then
				for x = r[1] + 3, r[3] - 2, 6 do
					local beam = Kit.box(shell, 0.6, 0.7, r[4] - r[2], x, fy + GameConfig.WallHeight - 0.35, (r[2] + r[4]) / 2, P.wood_black, P.M.wood, { collide = false })
					B.tag(beam, "Roof")
				end
			end
			for x = r[1] + 5, r[3] - 3, 10 do
				for z = r[2] + 5, r[4] - 3, 10 do
					local fixture = Kit.box(shell, 1.2, 0.2, 1.2, x, fy + GameConfig.WallHeight - 0.8, z, P.paper_warm, P.M.neon, { collide = false, shadow = false })
					fixture.CanQuery = false
					Kit.light(fixture, "Point", P.lamp, 22, 0.55, { night = false })
					B.tag(fixture, "Roof")
				end
			end
			if zone.area == "kitchen" or zone.area == "storage" then
				local vol = Kit.box(shell, r[3] - r[1], 6, r[4] - r[2], (r[1] + r[3]) / 2, fy + 3, (r[2] + r[4]) / 2, P.white, P.M.smooth, { collide = false, transparency = 1, shadow = false })
				vol.CanQuery = false
				vol.Name = "StaffOnly"
				local mod = Instance.new("PathfindingModifier")
				mod.Label = "StaffOnly"
				mod.Parent = vol
			end
		end
	end

	for floor in pairs(floors) do
		local fy = floorY(floor)
		local fw = geo.walls[floor] or { walls = {}, rails = {} }
		for _, seg in ipairs(fw.walls) do
			local mid = (seg.a + seg.b) / 2
			local sideA, sideB
			if seg.axis == "z" then
				sideA, sideB = indoorAt(geo, mid, seg.line - 0.6, floor), indoorAt(geo, mid, seg.line + 0.6, floor)
			else
				sideA, sideB = indoorAt(geo, seg.line - 0.6, mid, floor), indoorAt(geo, seg.line + 0.6, mid, floor)
			end
			local zone = sideA or sideB
			local wallStyle = style(zone and Scene.surfaceOf(data, zone, "wall") or Surfaces.DefaultWall, "wall")
			local outsideSign = nil
			if not sideA then
				outsideSign = -1
			elseif not sideB then
				outsideSign = 1
			end
			B.wall(shell, seg, fy, GameConfig.WallHeight, 0.8, wallStyle, outsideSign, exterior)
			-- interior finishes on each indoor side
			if sideA then
				B.wallTrim(shell, seg, fy, -1, sideA.area, GameConfig.WallHeight, trim)
			end
			if sideB then
				B.wallTrim(shell, seg, fy, 1, sideB.area, GameConfig.WallHeight, trim)
			end
			if outsideSign then
				if seg.axis == "z" and outsideSign == -1 then
					B.eave(shell, seg, fy + GameConfig.WallHeight - 1.2, -1, 3, owned.reno_eaves)
					if zone and zone.area ~= "storage" and (owned.reno_facade or owned.reno_bamboo) then
						local avoid = {}
						for _, o in ipairs(geo.openings) do
							if o.axis == "z" and o.at == seg.line and o.floor == floor then
								table.insert(avoid, { o.from - 4.4, o.to + 4.4 })
							end
						end
						B.facadeDetail(shell, seg, fy, -1, avoid, { koshi = owned.reno_facade, bamboo = owned.reno_bamboo })
					end
					-- lattice windows facing the street (not over doors)
					local len = seg.b - seg.a
					local n = math.floor(len / 9)
					for i = 0, n - 1 do
						local along = seg.a + len / n * (i + 0.5)
						if math.abs(along) > 6 then
							B.window(shell, along, fy + 6.6, seg, -1, 4, 3.4, owned.reno_windows)
						end
					end
				end
				local above = false
				for _, z in ipairs(geo.zones) do
					if z.floor == floor + 1 and Footprint.pointInRect(seg.axis == "z" and mid or seg.line, seg.axis == "z" and seg.line or mid, z.rect, 0.5) then
						above = true
					end
				end
				if not above then
					B.parapet(shell, seg, fy + GameConfig.WallHeight + 1)
				end
			end
		end
		for _, seg in ipairs(fw.rails) do
			B.railing(shell, seg, fy, floor == 0 and P.wood_dark or P.lacquer)
		end
	end
	for _, o in ipairs(geo.openings) do
		local fy = floorY(o.floor)
		B.doorFrame(shell, o, fy, o.kind == "loading" and 10 or 9)
		if o.kind == "entrance" then
			B.entranceNoren(shell, o, fy)
			if owned.reno_entrance then
				B.entranceDetail(shell, o, fy)
			end
		elseif o.kind == "loading" then
			B.shutter(shell, o, fy, 10, owned.reno_storage)
		end
	end
	for _, s in ipairs(geo.stairs) do
		B.stairs(shell, s.rect, floorY(s.floor), GameConfig.FloorHeight)
	end

	-- Facade: big sign, entrance lanterns, open plate
	local signText = "らーめん ・ 寿司"
	local face = B.sign(shell, 0, 11.6, -0.9, 14, signText, deluxe)
	B.tag(face, "Roof")
	for _, x in ipairs({ -4.4, 4.4 }) do
		local l = Kit.blob(shell, 1.3, 1.8, 1.3, x, 8.2, -1.6, P.lacquer, P.M.smooth, { collide = false })
		Kit.cyl(shell, 0.8, 0.2, x, 9.2, -1.6, P.black, P.M.smooth, { collide = false })
		Kit.cyl(shell, 0.8, 0.2, x, 7.2, -1.6, P.black, P.M.smooth, { collide = false })
		Kit.light(l, "Point", P.lamp_warm, 16, 1.4)
		l:SetAttribute("Animate", "sway")
		l.CanQuery = false
	end
	local label = B.openSign(shell, 4.6, 5.2, -0.55)
	if data.zones.sign_rooftop then
		local topY = floorY(topFloor) + GameConfig.WallHeight + 2
		local board = Kit.box(shell, 20, 5, 0.6, 0, topY + 3.5, 2, P.black, P.M.smooth, { collide = false })
		Kit.text(board, Enum.NormalId.Front, "ラーメン 寿司", { color = "#FF3B4A", glow = true })
		Kit.light(board, "Surface", P.neon_red, 30, 3, { face = Enum.NormalId.Front })
		for _, x in ipairs({ -8, 8 }) do
			Kit.box(shell, 0.4, 3.5, 0.4, x, topY + 1, 2.4, P.steel_dark, P.M.metal, { collide = false })
		end
		B.tag(board, "Roof")
	end
	if deluxe then
		for _, x in ipairs({ -18.2, 18.2 }) do
			local post = Kit.box(shell, 0.4, 13, 0.4, x, 6.5, -0.6, P.gold, P.M.foil, { collide = false })
			B.tag(post, "Roof")
		end
		local glow = Kit.box(shell, 36.4, 0.2, 0.2, 0, 13.6, -0.7, P.neon_yellow, P.M.neon, { collide = false })
		B.tag(glow, "Roof")
	end
	-- Fixed interactables: supplier tablet and menu board
	local S = Registry.Street
	local tabletCfg = Expansions.Supplier
	local tablet = S.supplierTablet(shell, tabletCfg.x, tabletCfg.y, tabletCfg.z, 0)
	tablet:SetAttribute("Uid", "fixed_supplier")
	tablet:SetAttribute("Kind", "supplier")
	CollectionService:AddTag(tablet, "Interactable")
	local mb = Expansions.MenuBoard
	local board = S.menuBoard(shell, mb.x, mb.z)
	board:SetAttribute("Uid", "fixed_menu")
	board:SetAttribute("Kind", "menuboard")
	CollectionService:AddTag(board, "Interactable")

	for _, d in ipairs(shell:GetDescendants()) do
		if d:IsA("BasePart") then
			d.CollisionGroup = "Shell"
		end
	end
	return { openLabel = label }
end

-- Neighbour facade colour: the city tone mixed with plaster, tile or concrete shades
local FACADE_MIX = { "#EFE3CC", "#B5B1A8", "#C9B8A0", "#9AA3A8", "#D8CFC0", "#A0705A" }
local function facadeColor(pal, r)
	local mix = Color.hex(FACADE_MIX[r:NextInteger(1, #FACADE_MIX)])
	return Color.hex(pal.building):Lerp(mix, 0.35 + r:NextNumber() * 0.5)
end

function Scene.street(street, cityId)
	street:ClearAllChildren()
	local city = Franchise.byId[cityId] or Franchise.byId.tokyo
	local pal = city.palette
	local S = Registry.Street
	local r = S.rng(42)
	local M = P.M
	-- ground
	Kit.box(street, 900, 1, 600, 0, -1.9, 40, city.snow and P.white or Color.hex("#4A5A3A"), city.snow and M.snow or M.grass)
	-- road
	Kit.box(street, 900, 0.6, 16, 0, -1.1, -22, Color.hex(pal.road), M.asphalt)
	for x = -440, 440, 12 do
		Kit.box(street, 5, 0.05, 0.4, x, -0.78, -22, P.road_line, M.smooth, { collide = false, shadow = false })
	end
	-- solid edge lines, crossing, manholes (one steaming) and drain grates
	for _, ez in ipairs({ -15, -29 }) do
		Kit.box(street, 900, 0.05, 0.3, 0, -0.78, ez, P.road_line, M.smooth, { collide = false, shadow = false })
	end
	S.crosswalk(street, -26, -0.77, -22, 16)
	for i, mx in ipairs({ -70, 30, 96, -130 }) do
		S.manhole(street, mx, -0.77, i % 2 == 0 and -19 or -25, mx == 30)
	end
	for gx = -170, 170, 20 do
		Kit.box(street, 1.6, 0.05, 0.6, gx + 7, -0.77, -14.7, P.steel_dark, M.metal, { collide = false, shadow = false })
	end
	-- sidewalks with yellow tactile paving
	Kit.box(street, 900, 1, 14, 0, -0.9, -7, P.sidewalk, M.pavement)
	Kit.box(street, 900, 0.5, 0.5, 0, -0.65, -14, P.stone_light, M.concrete)
	Kit.box(street, 900, 1, 6, 0, -0.9, -33, P.sidewalk, M.pavement)
	Kit.box(street, 900, 0.5, 0.5, 0, -0.65, -30, P.stone_light, M.concrete)
	local tactile = Color.hex("#E2B93B")
	Kit.box(street, 900, 0.06, 1, 0, -0.38, -5.5, tactile, M.pavement, { collide = false, shadow = false })
	Kit.box(street, 900, 0.06, 1, 0, -0.38, -32.2, tactile, M.pavement, { collide = false, shadow = false })
	Kit.box(street, 1, 0.06, 7.2, -26, -0.38, -9.6, tactile, M.pavement, { collide = false, shadow = false })
	Kit.box(street, 3, 0.06, 1, -26, -0.38, -13.2, tactile, M.cobble, { collide = false, shadow = false })
	Kit.box(street, 3, 0.06, 1, -26, -0.38, -30.8, tactile, M.cobble, { collide = false, shadow = false })
	S.manhole(street, -80, -0.37, -6.5, false)
	-- street furniture near the crossing: signs, post box, bus stop
	S.trafficSign(street, -29.5, -13.4, "walk")
	S.trafficSign(street, -22.5, -30.6, "walk")
	S.trafficSign(street, -92, -13.4, "stop")
	S.postBox(street, -36, -13.2)
	Kit.cyl(street, 0.2, 7, 64, 3.1, -13.4, P.metal, M.metal)
	local bus = Kit.cylH(street, 1.6, 0.1, 64, 6.4, -13.4, P.white, M.smooth, { collide = false, shadow = false }, "z")
	Kit.text(bus, Enum.NormalId.Left, "バス", { color = "#1E2A44" })
	Kit.text(bus, Enum.NormalId.Right, "バス", { color = "#1E2A44" })
	Kit.box(street, 0.9, 1.4, 0.12, 64, 4.6, -13.4, P.paper, M.smooth, { collide = false, shadow = false })
	Kit.box(street, 4, 0.2, 1.2, 68, 1.3, -13.2, P.wood_light, M.wood)
	for _, bx in ipairs({ 66.4, 69.6 }) do
		Kit.box(street, 0.2, 1.2, 1, bx, 0.6, -13.2, P.steel_dark, M.metal)
	end
	-- bicycles parked on the far sidewalk
	for _, bx in ipairs({ -44, -42.8, -41.6, 34, 35.2, 118, 119.2, -150 }) do
		S.bicycle(street, bx, -34, 90, ({ P.white, P.navy, P.lacquer, P.matcha, P.sakura_dark })[r:NextInteger(1, 5)])
	end
	-- plot lot and loading bay
	local pb = Expansions.PlotBounds
	Kit.box(street, pb[3] - pb[1], 1, 52 - 0, (pb[1] + pb[3]) / 2, -0.9, 26, P.stone_dark, M.pavement)
	Kit.box(street, 12, 0.1, 12, 24, -0.38, 6, P.concrete, M.concrete, { collide = false })
	for _, x in ipairs({ 18.3, 29.7 }) do
		Kit.box(street, 0.25, 0.05, 12, x, -0.33, 6, P.neon_yellow, M.smooth, { collide = false, shadow = false })
	end
	-- opposite row
	local x = -180
	while x < 180 do
		local w = r:NextInteger(10, 18)
		S.building(street, x, x + w - 0.5, -36, 18, r:NextInteger(16, 34), -1, facadeColor(pal, r), r)
		x += w
	end
	-- neighbours on our side
	x = -180
	while x < pb[1] - 2 do
		local w = math.min(r:NextInteger(10, 16), pb[1] - 2 - x)
		if w >= 6 then
			S.building(street, x, x + w - 0.5, 0, 30, r:NextInteger(16, 30), 1, facadeColor(pal, r), r)
		end
		x += math.max(w, 6)
	end
	x = pb[3] + 2
	while x < 180 do
		local w = r:NextInteger(10, 16)
		S.building(street, x, x + w - 0.5, 0, 30, r:NextInteger(16, 30), 1, facadeColor(pal, r), r)
		x += w
	end
	-- back fence and trees
	for fx = pb[1], pb[3] - 2, 2 do
		Kit.box(street, 0.3, 5, 0.3, fx, 2.1, 52, P.bamboo, M.wood)
	end
	Kit.box(street, pb[3] - pb[1], 0.3, 0.3, (pb[1] + pb[3]) / 2, 4.2, 52, P.bamboo, M.wood, { collide = false })
	Kit.box(street, pb[3] - pb[1], 0.3, 0.3, (pb[1] + pb[3]) / 2, 1.5, 52, P.bamboo, M.wood, { collide = false })
	for _, tx in ipairs({ -50, -30, -5, 20, 40 }) do
		S.planterTree(street, tx, 58, (tx % 20 == 0) and P.sakura or P.leaf)
	end
	-- sidewalk lamps, poles, trees
	for lx = -170, 170, 30 do
		if math.abs(lx) > 8 then
			S.lamp(street, lx, -13, -1)
		end
	end
	local prev = nil
	for px = -180, 180, 40 do
		S.pole(street, px, -34.5)
		local top = Vector3.new(px, 14.5, -34.5)
		if prev then
			S.wire(street, prev, top, 1.2)
			S.wire(street, prev + Vector3.new(0, -1.3, 0), top + Vector3.new(0, -1.3, 0), 1.2)
		end
		prev = top
	end
	for _, tx in ipairs({ -150, -110, -80, 70, 100, 140 }) do
		S.planterTree(street, tx, -10, (tx % 20 == 0) and P.sakura or P.leaf_light)
	end
	for _, tx in ipairs({ -130, -60, 10, 80, 150 }) do
		S.planterTree(street, tx, -33, P.sakura)
	end
	-- a few street vending machines
	for _, vx in ipairs({ -60, 52, -100 }) do
		local vm = Registry.build("vending_machine")
		Registry.place(vm, vx, -0.4, -1.4, 180)
		vm.Parent = street
		S.bins(street, vx + (vx < 0 and -2.6 or 2.6), -1.3)
	end
	S.viaduct(street, -95, 22, -450, 450)
	if city.snow then
		local snow = Kit.box(street, 300, 1, 200, 0, 60, 0, P.white, M.smooth, { transparency = 1, collide = false, shadow = false })
		snow.CanQuery = false
		Kit.particles(snow, "snow", { rate = 60 })
	end
	for _, d in ipairs(street:GetDescendants()) do
		if d:IsA("BasePart") then
			d.CollisionGroup = "Shell"
			d.CanTouch = false
		end
	end
	return { sky = pal.sky }
end


return Scene
