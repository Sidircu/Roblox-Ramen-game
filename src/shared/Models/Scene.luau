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
			table.insert(holes, s.hole or s.rect)
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
					table.insert(holes, s.hole or s.rect)
				end
			end
			local covered = false
			for _, other in ipairs(geo.zones) do
				if other.floor == zone.floor + 1 and Footprint.pointInRect((zone.rect[1] + zone.rect[3]) / 2, (zone.rect[2] + zone.rect[4]) / 2, other.rect) then
					covered = true
				end
			end
			for _, r in ipairs(subtractAll(zone.rect, holes)) do
				-- under another floor the slab stops just below that floor's boards (no z-fighting)
				local thick = covered and (GameConfig.FloorHeight - GameConfig.WallHeight - 0.2) or 1
				local c = B.slab(shell, r, fy + GameConfig.WallHeight, thick, P.wood_dark, P.M.wood, "Ceiling")
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
				for x = r[1] + 4, r[3] - 2, 8 do
					local beam = Kit.box(shell, 0.6, 0.7, r[4] - r[2], x, fy + GameConfig.WallHeight - 0.35, (r[2] + r[4]) / 2, P.wood_black, P.M.wood, { collide = false })
					B.tag(beam, "Roof")
				end
			end
			for x = r[1] + 7, r[3] - 3, 14 do
				for z = r[2] + 7, r[4] - 3, 14 do
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
			-- walls under another floor go up to it, so there is no gap between the storeys
			local above = false
			for _, z in ipairs(geo.zones) do
				if z.floor == floor + 1 and Footprint.pointInRect(seg.axis == "z" and mid or seg.line, seg.axis == "z" and seg.line or mid, z.rect, 0.5) then
					above = true
				end
			end
			B.wall(shell, seg, fy, above and GameConfig.FloorHeight or GameConfig.WallHeight, GameConfig.WallThickness, wallStyle, outsideSign, exterior)
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
				if not above then
					B.parapet(shell, seg, fy + GameConfig.WallHeight + 1)
				end
			end
		end
		for _, seg in ipairs(fw.rails) do
			B.railing(shell, seg, fy, P.wood_dark)
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
		B.stairs(shell, s, floorY(s.floor), GameConfig.FloorHeight)
	end

	-- Facade: big sign, entrance lanterns, open plate
	local signText = "らーめん ・ 寿司"
	local face = B.sign(shell, 0, 11.6, -0.9, 18, signText, deluxe)
	B.tag(face, "Roof")
	for _, x in ipairs({ -6.4, 6.4 }) do
		local l = Kit.blob(shell, 1.3, 1.8, 1.3, x, 8.2, -1.6, P.lacquer, P.M.smooth, { collide = false })
		Kit.cyl(shell, 0.8, 0.2, x, 9.2, -1.6, P.black, P.M.smooth, { collide = false })
		Kit.cyl(shell, 0.8, 0.2, x, 7.2, -1.6, P.black, P.M.smooth, { collide = false })
		Kit.light(l, "Point", P.lamp_warm, 16, 1.4)
		l:SetAttribute("Animate", "sway")
		l.CanQuery = false
	end
	local label = nil -- (the LED OPEN sign by the door says it now)
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
		for _, x in ipairs({ -36.2, 36.2 }) do
			local post = Kit.box(shell, 0.4, 13, 0.4, x, 6.5, -0.6, P.gold, P.M.foil, { collide = false })
			B.tag(post, "Roof")
		end
		local glow = Kit.box(shell, 72.4, 0.2, 0.2, 0, 13.6, -0.7, P.neon_yellow, P.M.neon, { collide = false })
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
	-- LED OPEN / CLOSED sign next to the door: using it opens or closes the restaurant
	local signAt = Expansions.OpenSign
	local openSign = B.ledSign(shell, signAt.x, signAt.y, signAt.z)
	openSign:SetAttribute("Uid", "fixed_opensign")
	openSign:SetAttribute("Kind", "opensign")
	CollectionService:AddTag(openSign, "Interactable")

	for _, d in ipairs(shell:GetDescendants()) do
		if d:IsA("BasePart") then
			d.CollisionGroup = "Shell"
		end
	end
	return { openLabel = label, openSign = openSign }
end

-- A plot nobody owns yet: a low construction fence along the street and a lantern sign
-- ("a new ramen shop opens here"), built in local coordinates like the shell
function Scene.emptyLot(shell)
	local pb = Expansions.PlotBounds
	local M = P.M
	for x = pb[1] + 4, pb[3] - 4, 6 do
		Kit.box(shell, 0.3, 3.2, 0.3, x, 1.6, -1, P.wood_dark, M.wood)
	end
	Kit.box(shell, pb[3] - pb[1] - 8, 0.3, 0.2, (pb[1] + pb[3]) / 2, 2.9, -1, P.vermilion, M.smooth, { collide = false })
	Kit.box(shell, pb[3] - pb[1] - 8, 0.3, 0.2, (pb[1] + pb[3]) / 2, 1.4, -1, P.vermilion, M.smooth, { collide = false })
	local sign = Kit.box(shell, 16, 4, 0.4, 0, 6, 2, P.paper, M.wood, { collide = false })
	Kit.text(sign, Enum.NormalId.Front, "空き地 · 近日オープン", { color = "#2B2320" })
	Kit.text(sign, Enum.NormalId.Back, "空き地", { color = "#2B2320" })
	for _, x in ipairs({ -7, 7 }) do
		Kit.box(shell, 0.4, 6, 0.4, x, 3, 2, P.wood_dark, M.wood, { collide = false })
	end
	local lamp = Kit.ball(shell, 1.2, 9, 8.6, 2, P.lacquer, M.fabric, { collide = false })
	Kit.light(lamp, "Point", P.lamp_warm, 14, 1.5)
	for _, d in ipairs(shell:GetDescendants()) do
		if d:IsA("BasePart") then
			d.CollisionGroup = "Shell"
		end
	end
end

-- A "for sale" sign standing where a room can be built, like the buy pads of a tycoon: posts, a
-- board with a little roof and a lantern. The board's text (icon, name, price or lock) is written
-- by every client in its own language (Controllers/WorldUI); using the sign buys the room
-- (Controllers/Interaction -> BuyExpansion, checked by the server).
function Scene.forSale(shell, e, plotId)
	local rect = e.zones[1].rect
	local x, z = (rect[1] + rect[3]) / 2, (rect[2] + rect[4]) / 2
	-- an outdoor area in front of the door (the terrace): the sign stands at its side, not in the way
	if e.zones[1].outdoor and rect[3] - rect[1] > 30 then
		x = rect[1] + 6
	end
	local M = P.M
	local m = Kit.model("ForSale_" .. e.id)
	local board = Kit.box(m, 7, 3.6, 0.35, x, 4.2, z, P.paper, M.wood, { collide = false })
	board.Name = "Board"
	for _, dx in ipairs({ -3.2, 3.2 }) do
		Kit.box(m, 0.35, 6, 0.35, x + dx, 3, z, P.wood_dark, M.wood, { collide = false })
	end
	Kit.box(m, 7.8, 0.3, 1.2, x, 6.25, z, P.wood_dark, M.wood, { collide = false })
	local lamp = Kit.ball(m, 0.8, x + 3.2, 6.9, z, P.lacquer, M.fabric, { collide = false })
	Kit.light(lamp, "Point", P.lamp_warm, 12, 1.2)
	local front = Kit.text(board, Enum.NormalId.Front, "🏗️", { color = "#2B2320", pps = 40 })
	front.Name = "Front"
	local back = Kit.text(board, Enum.NormalId.Back, "🏗️", { color = "#2B2320", pps = 40 })
	back.Name = "Back"
	m.PrimaryPart = board
	m:SetAttribute("Kind", "forsale")
	m:SetAttribute("Uid", "forsale_" .. e.id .. "_" .. tostring(plotId))
	m:SetAttribute("Expansion", e.id)
	m:SetAttribute("Price", e.cost)
	m:SetAttribute("Level", e.lv)
	m:SetAttribute("PlotId", plotId)
	game:GetService("CollectionService"):AddTag(m, "Interactable")
	game:GetService("CollectionService"):AddTag(m, "ForSale")
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") then
			d.CollisionGroup = "Shell"
		end
	end
	m.Parent = shell
	return m
end

-- Neighbour facade colour: the city tone mixed with plaster, tile or concrete shades
local FACADE_MIX = { "#EFE3CC", "#B5B1A8", "#C9B8A0", "#9AA3A8", "#D8CFC0", "#A0705A" }
local function facadeColor(pal, r)
	local mix = Color.hex(FACADE_MIX[r:NextInteger(1, #FACADE_MIX)])
	return Color.hex(pal.building):Lerp(mix, 0.35 + r:NextNumber() * 0.5)
end

-- lots = the X of every restaurant plot along the street; reach = how far the street runs each way
function Scene.street(street, cityId, lots, reachOverride)
	street:ClearAllChildren()
	lots = lots or { 0 }
	local city = Franchise.byId[cityId] or Franchise.byId.tokyo
	local pal = city.palette
	local S = Registry.Street
	local r = S.rng(42)
	local M = P.M
	local L = Expansions.Street
	local reach = reachOverride or L.reach
	local curb, roadFar, farFront = L.curb, L.roadFar, L.farFront
	local roadW = curb - roadFar
	local roadZ = (curb + roadFar) / 2
	local farW = roadFar - farFront
	local farZ = (roadFar + farFront) / 2
	local len = reach * 2 + 200
	-- a ranking board on the far sidewalk across the road from every restaurant's door; the lamps,
	-- trees and bicycles of the far sidewalk keep clear of it
	local boardZ = roadFar - 7
	local function nearBoard(x, d)
		for _, ox in ipairs(lots) do
			if math.abs(x - ox) < d then
				return true
			end
		end
		return false
	end
	-- ground
	Kit.box(street, len + 400, 1, 900, 0, -1.9, 80, city.snow and P.white or Color.hex("#4A5A3A"), city.snow and M.snow or M.grass)
	-- four-lane road: double centre line, dashed lane lines, solid edge lines
	Kit.box(street, len, 0.6, roadW, 0, -1.1, roadZ, Color.hex(pal.road), M.asphalt)
	for _, dz in ipairs({ -0.35, 0.35 }) do
		Kit.box(street, len, 0.05, 0.3, 0, -0.78, roadZ + dz, P.neon_yellow, M.smooth, { collide = false, shadow = false })
	end
	for _, lz in ipairs({ curb - L.lane, roadFar + L.lane }) do
		for x = -reach - 80, reach + 80, 14 do
			Kit.box(street, 6, 0.05, 0.35, x, -0.78, lz, P.road_line, M.smooth, { collide = false, shadow = false })
		end
	end
	for _, ez in ipairs({ curb - 0.7, roadFar + 0.7 }) do
		Kit.box(street, len, 0.05, 0.3, 0, -0.78, ez, P.road_line, M.smooth, { collide = false, shadow = false })
	end
	S.crosswalk(street, -26, -0.77, roadZ, roadW, 7)
	for i, mx in ipairs({ -70, 30, 96, -130, 160 }) do
		S.manhole(street, mx, -0.77, curb - L.lane * (0.5 + (i % 4)), mx == 30)
	end
	for gx = -reach, reach, 24 do
		Kit.box(street, 1.6, 0.05, 0.6, gx + 7, -0.77, curb - 0.7, P.steel_dark, M.metal, { collide = false, shadow = false })
		Kit.box(street, 1.6, 0.05, 0.6, gx + 19, -0.77, roadFar + 0.7, P.steel_dark, M.metal, { collide = false, shadow = false })
	end
	-- wide sidewalks with yellow tactile paving and kerbs
	Kit.box(street, len, 1, -curb, 0, -0.9, curb / 2, P.sidewalk, M.pavement)
	Kit.box(street, len, 0.5, 0.6, 0, -0.65, curb, P.stone_light, M.concrete)
	Kit.box(street, len, 1, farW, 0, -0.9, farZ, P.sidewalk, M.pavement)
	Kit.box(street, len, 0.5, 0.6, 0, -0.65, roadFar, P.stone_light, M.concrete)
	local tactile = Color.hex("#E2B93B")
	Kit.box(street, len, 0.06, 1, 0, -0.38, -7, tactile, M.pavement, { collide = false, shadow = false })
	Kit.box(street, len, 0.06, 1, 0, -0.38, roadFar - 4, tactile, M.pavement, { collide = false, shadow = false })
	Kit.box(street, 1, 0.06, -curb - 8, -26, -0.38, (curb - 7.5) / 2 - 0.5, tactile, M.pavement, { collide = false, shadow = false })
	Kit.box(street, 4, 0.06, 1, -26, -0.38, curb + 0.8, tactile, M.cobble, { collide = false, shadow = false })
	Kit.box(street, 4, 0.06, 1, -26, -0.38, roadFar - 0.8, tactile, M.cobble, { collide = false, shadow = false })
	S.manhole(street, -80, -0.37, -6.5, false)
	-- street furniture near the crossing: signs, post box, bus stop
	S.trafficSign(street, -31, curb + 0.6, "walk")
	S.trafficSign(street, -21, roadFar - 0.6, "walk")
	S.trafficSign(street, -92, curb + 0.6, "stop")
	S.postBox(street, -36, curb + 0.8)
	Kit.cyl(street, 0.2, 7, 64, 3.1, curb + 0.6, P.metal, M.metal)
	local bus = Kit.cylH(street, 1.6, 0.1, 64, 6.4, curb + 0.6, P.white, M.smooth, { collide = false, shadow = false }, "z")
	Kit.text(bus, Enum.NormalId.Left, "バス", { color = "#1E2A44" })
	Kit.text(bus, Enum.NormalId.Right, "バス", { color = "#1E2A44" })
	Kit.box(street, 0.9, 1.4, 0.12, 64, 4.6, curb + 0.6, P.paper, M.smooth, { collide = false, shadow = false })
	-- bus shelter with a bench
	Kit.box(street, 8, 0.3, 3, 69, 7.6, curb + 2.2, P.steel_dark, M.metal, { collide = false })
	for _, bx in ipairs({ 65.2, 72.8 }) do
		Kit.box(street, 0.3, 7.6, 0.3, bx, 3.4, curb + 3.4, P.steel_dark, M.metal)
	end
	local glassBack = Kit.box(street, 7.6, 5, 0.1, 69, 3.4, curb + 3.6, P.glass, M.glass, { collide = false })
	glassBack.Transparency = 0.6
	Kit.box(street, 5, 0.3, 1.2, 69, 1.4, curb + 2.8, P.wood_light, M.wood)
	-- bicycles parked on the far sidewalk
	for _, bx in ipairs({ -44, -42.8, -41.6, 34, 35.2, 118, 119.2, -150 }) do
		local color = ({ P.white, P.navy, P.lacquer, P.matcha, P.sakura_dark })[r:NextInteger(1, 5)]
		if not nearBoard(bx, 15) then
			S.bicycle(street, bx, farFront + 2.2, 90, color)
		end
	end
	-- every plot: its lot and loading bay, a bamboo fence and trees along the back
	local pb = Expansions.PlotBounds
	local bay = Expansions.LoadingBay
	for _, ox in ipairs(lots) do
		Kit.box(street, pb[3] - pb[1], 1, pb[4], ox + (pb[1] + pb[3]) / 2, -0.9, pb[4] / 2, P.stone_dark, M.pavement)
		Kit.box(street, 12, 0.1, 18, ox + bay.x, -0.38, bay.z, P.concrete, M.concrete, { collide = false })
		for _, x in ipairs({ bay.x - 5.7, bay.x + 5.7 }) do
			Kit.box(street, 0.25, 0.05, 18, ox + x, -0.33, bay.z, P.neon_yellow, M.smooth, { collide = false, shadow = false })
		end
		for fx = pb[1], pb[3] - 2, 3 do
			Kit.box(street, 0.3, 5, 0.3, ox + fx, 2.1, pb[4], P.bamboo, M.wood)
		end
		Kit.box(street, pb[3] - pb[1], 0.3, 0.3, ox + (pb[1] + pb[3]) / 2, 4.2, pb[4], P.bamboo, M.wood, { collide = false })
		Kit.box(street, pb[3] - pb[1], 0.3, 0.3, ox + (pb[1] + pb[3]) / 2, 1.5, pb[4], P.bamboo, M.wood, { collide = false })
		for _, tx in ipairs({ -100, -60, -20, 20, 60 }) do
			S.planterTree(street, ox + tx, pb[4] + 8, (tx % 40 == 0) and P.sakura or P.leaf, 1.6)
		end
	end
	-- big buildings: the opposite row and the neighbours on our side (between the plots and past
	-- the outer ones), in scale with the restaurants
	local K = 1.6
	local x = -reach
	while x < reach do
		local w = r:NextInteger(34, 62)
		local cx = x + w / 2
		S.building(street, x, x + w - 1, farFront, r:NextInteger(36, 48), r:NextInteger(32, 70), -1, facadeColor(pal, r), r, K, math.abs(cx) < reach - 150)
		x += w
	end
	local gaps = {}
	local sorted = table.clone(lots)
	table.sort(sorted)
	local from = -reach
	for _, ox in ipairs(sorted) do
		table.insert(gaps, { from, ox + pb[1] - 4 })
		from = ox + pb[3] + 4
	end
	table.insert(gaps, { from, reach })
	for _, gap in ipairs(gaps) do
		x = gap[1]
		while x < gap[2] - 16 do
			local w = math.min(r:NextInteger(26, 54), gap[2] - x)
			if w >= 16 then
				S.building(street, x, x + w - 1, 0, 70, r:NextInteger(28, 52), 1, facadeColor(pal, r), r, K, true)
			end
			x += math.max(w, 16)
		end
	end
	-- tall lamps on both kerbs, utility poles with wires on the far side
	for lx = -reach + 10, reach - 10, 36 do
		if math.abs(lx + 26) > 8 then
			S.lamp(street, lx, curb + 1, -1, 1.5)
			if not nearBoard(lx + 18, 15) then
				S.lamp(street, lx + 18, roadFar - 1, 1, 1.5)
			end
		end
	end
	local prev = nil
	local poleZ = farFront + 6
	for px = -reach, reach, 48 do
		S.pole(street, px, poleZ, 1.5)
		local top = Vector3.new(px, 14.5 * 1.5, poleZ)
		if prev then
			S.wire(street, prev, top, 1.8)
			S.wire(street, prev + Vector3.new(0, -1.9, 0), top + Vector3.new(0, -1.9, 0), 1.8)
		end
		prev = top
	end
	for tx = -reach + 40, reach - 40, 70 do
		S.planterTree(street, tx, curb + 3, (math.floor(tx / 70) % 2 == 0) and P.sakura or P.leaf_light, 1.5)
		if not nearBoard(tx + 35, 17) then
			S.planterTree(street, tx + 35, roadFar - 5, P.sakura, 1.5)
		end
	end
	for _, ox in ipairs(lots) do
		S.rankingBoard(street, ox, boardZ)
	end
	-- a street vending machine next to every restaurant
	for _, ox in ipairs(lots) do
		local vx = ox + pb[3] + 7
		local vm = Registry.build("vending_machine")
		Registry.place(vm, vx, -0.4, -1.4, 180)
		vm.Parent = street
		S.bins(street, vx + 2.6, -1.3)
	end
	S.viaduct(street, L.railZ, L.railY, -reach - 300, reach + 300)
	if city.snow then
		local snow = Kit.box(street, reach * 2, 1, 360, 0, 90, -20, P.white, M.smooth, { transparency = 1, collide = false, shadow = false })
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
