--!nonstrict
-- Builds the street and the restaurant shell from the unlocked zones; exposes the geometry
-- (zones, walls, stairs, openings) used by placement, seating and NPC services.
local CollectionService = game:GetService("CollectionService")
local PhysicsService = game:GetService("PhysicsService")
local Lighting = game:GetService("Lighting")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local Expansions = require(Shared.Config.Expansions)
local Surfaces = require(Shared.Config.Surfaces)
local Franchise = require(Shared.Config.Franchise)
local Items = require(Shared.Config.Items)
local Geometry = require(Shared.Logic.Geometry)
local Footprint = require(Shared.Logic.Footprint)
local Registry = require(Shared.Models.Registry)
local Kit = require(Shared.Models.Kit)
local P = require(Shared.Models.Palette)
local Color = require(Shared.Util.Color)
local Signal = require(Shared.Util.Signal)
local Core = require(script.Parent.Parent.Core)

local World = {}
World.Rebuilt = Signal.new()
World.zones = {}
World.openings = {}
World.stairs = {}
World.walls = {}
World.expansions = {}
World.city = "tokyo"

local root, shell, street, itemsFolder, dynamicFolder, npcFolder
local streetBuilt = false

local function folder(name, parent)
	local f = parent:FindFirstChild(name)
	if not f then
		f = Instance.new("Folder")
		f.Name = name
		f.Parent = parent
	end
	return f
end

function World.floorY(f)
	return (f or 0) * GameConfig.FloorHeight
end

function World.folders()
	return { root = root, shell = shell, items = itemsFolder, dynamic = dynamicFolder, npcs = npcFolder, street = street }
end

-- Recomputes the unlocked geometry from the owner's data
function World.recompute(data)
	local geo = Geometry.compute(Expansions.list, data.zones, Expansions.Supplier)
	World.zones, World.openings, World.stairs, World.expansions = geo.zones, geo.openings, geo.stairs, geo.expansions
	World.walls = geo.walls
	World.fixed = geo.fixed
end

function World.zoneAt(x, z, f)
	for _, zone in ipairs(World.zones) do
		if zone.floor == (f or 0) and Footprint.pointInRect(x, z, zone.rect) then
			return zone
		end
	end
	return nil
end

function World.hasExpansion(id)
	for _, e in ipairs(World.expansions) do
		if e.id == id then
			return true
		end
	end
	return false
end

-- Door clearances that must stay free of objects
function World.fixedRects()
	return World.fixed or {}
end

-- Placement validation context (see Shared.Logic.Placement)
function World.ctx(placed)
	return Geometry.ctx({ zones = World.zones, walls = World.walls, stairs = World.stairs, fixed = World.fixed }, Items.byId, placed, GameConfig)
end

local function style(id, kind)
	local s = Surfaces.byId[id]
	if not s or s.kind ~= kind then
		s = Surfaces.byId[kind == "floor" and Surfaces.DefaultFloor or Surfaces.DefaultWall]
	end
	return { color = Color.hex(s.color), material = P.material(s.material), lattice = s.lattice, stripes = s.stripes }
end

function World.surfaceOf(data, zone, kind)
	local s = data.surfaces[zone.id]
	local id = s and s[kind]
	if not id then
		id = kind == "floor" and (zone.floorStyle or Surfaces.DefaultFloor) or (zone.wallStyle or Surfaces.DefaultWall)
	end
	return id
end

local function holesFor(floor)
	local holes = {}
	for _, s in ipairs(World.stairs) do
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

local function indoorAt(x, z, floor)
	local zone = World.zoneAt(x, z, floor)
	return zone and not zone.outdoor and zone or nil
end

local function buildShell(data)
	shell:ClearAllChildren()
	local B = Registry.Building
	local floors = {}
	for _, z in ipairs(World.zones) do
		floors[z.floor] = true
	end
	local topFloor = 0
	for f in pairs(floors) do
		topFloor = math.max(topFloor, f)
	end
	local deluxe = data.zones.facade_deluxe
	local exterior = { color = deluxe and P.charcoal or P.cream, material = deluxe and P.M.wood or P.M.plaster }

	for _, zone in ipairs(World.zones) do
		local fy = World.floorY(zone.floor)
		local attrs = { Zone = zone.id, FloorIndex = zone.floor, Area = zone.area }
		local floorStyle
		if zone.outdoor then
			if zone.area == "garden" then
				floorStyle = { color = P.moss, material = P.M.leafy }
			else
				floorStyle = { color = P.wood, material = P.M.planks }
			end
		else
			floorStyle = style(World.surfaceOf(data, zone, "floor"), "floor")
		end
		for _, r in ipairs(subtractAll(zone.rect, holesFor(zone.floor))) do
			B.floorSkin(shell, r, fy, floorStyle, attrs)
			if zone.floor == 0 then
				B.slab(shell, r, zone.outdoor and -0.7 or -1.2, zone.outdoor and 0.5 or 1.0, P.stone_dark, P.M.concrete, "Foundation")
			end
		end
		if not zone.outdoor then
			-- ceiling / roof slab with holes where stairs go up
			local holes = {}
			for _, s in ipairs(World.stairs) do
				if s.floor == zone.floor then
					table.insert(holes, s.rect)
				end
			end
			for _, r in ipairs(subtractAll(zone.rect, holes)) do
				local c = B.slab(shell, r, fy + GameConfig.WallHeight, 1, P.wood_dark, P.M.wood, "Ceiling")
				B.tag(c, "Ceiling", { FloorIndex = zone.floor })
				B.tag(c, "Roof")
			end
			-- exposed beams and soft ceiling lights
			local r = zone.rect
			for x = r[1] + 3, r[3] - 2, 6 do
				local beam = Kit.box(shell, 0.6, 0.7, r[4] - r[2], x, fy + GameConfig.WallHeight - 0.35, (r[2] + r[4]) / 2, P.wood_black, P.M.wood, { collide = false })
				B.tag(beam, "Roof")
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
		local fy = World.floorY(floor)
		local fw = World.walls[floor] or { walls = {}, rails = {} }
		for _, seg in ipairs(fw.walls) do
			local mid = (seg.a + seg.b) / 2
			local sideA, sideB
			if seg.axis == "z" then
				sideA, sideB = indoorAt(mid, seg.line - 0.6, floor), indoorAt(mid, seg.line + 0.6, floor)
			else
				sideA, sideB = indoorAt(seg.line - 0.6, mid, floor), indoorAt(seg.line + 0.6, mid, floor)
			end
			local zone = sideA or sideB
			local wallStyle = style(zone and World.surfaceOf(data, zone, "wall") or Surfaces.DefaultWall, "wall")
			local outsideSign = nil
			if not sideA then
				outsideSign = -1
			elseif not sideB then
				outsideSign = 1
			end
			B.wall(shell, seg, fy, GameConfig.WallHeight, 0.8, wallStyle, outsideSign, exterior)
			if outsideSign then
				if seg.axis == "z" and outsideSign == -1 then
					B.eave(shell, seg, fy + GameConfig.WallHeight - 1.2, -1, 3)
					-- lattice windows facing the street (not over doors)
					local len = seg.b - seg.a
					local n = math.floor(len / 9)
					for i = 0, n - 1 do
						local along = seg.a + len / n * (i + 0.5)
						if math.abs(along) > 6 then
							B.window(shell, along, fy + 5.2, seg, -1, 4, 3.4)
						end
					end
				end
				local above = false
				for _, z in ipairs(World.zones) do
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
	for _, o in ipairs(World.openings) do
		local fy = World.floorY(o.floor)
		B.doorFrame(shell, o, fy, o.kind == "loading" and 10 or 9)
		if o.kind == "entrance" then
			B.entranceNoren(shell, o, fy)
		end
	end
	for _, s in ipairs(World.stairs) do
		B.stairs(shell, s.rect, World.floorY(s.floor), GameConfig.FloorHeight)
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
	World.openLabel = label
	if data.zones.sign_rooftop then
		local topY = World.floorY(topFloor) + GameConfig.WallHeight + 2
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
end

local function buildStreet(cityId)
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
	-- sidewalks
	Kit.box(street, 900, 1, 14, 0, -0.9, -7, P.sidewalk, M.pavement)
	Kit.box(street, 900, 0.5, 0.5, 0, -0.65, -14, P.stone_light, M.concrete)
	Kit.box(street, 900, 1, 6, 0, -0.9, -33, P.sidewalk, M.pavement)
	Kit.box(street, 900, 0.5, 0.5, 0, -0.65, -30, P.stone_light, M.concrete)
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
		S.building(street, x, x + w - 0.5, -36, 18, r:NextInteger(16, 34), -1, Color.hex(pal.building):Lerp(P.cream, r:NextNumber() * 0.5), r)
		x += w
	end
	-- neighbours on our side
	x = -180
	while x < pb[1] - 2 do
		local w = math.min(r:NextInteger(10, 16), pb[1] - 2 - x)
		if w >= 6 then
			S.building(street, x, x + w - 0.5, 0, 30, r:NextInteger(16, 30), 1, Color.hex(pal.building):Lerp(P.cream, r:NextNumber() * 0.5), r)
		end
		x += math.max(w, 6)
	end
	x = pb[3] + 2
	while x < 180 do
		local w = r:NextInteger(10, 16)
		S.building(street, x, x + w - 0.5, 0, 30, r:NextInteger(16, 30), 1, Color.hex(pal.building):Lerp(P.cream, r:NextNumber() * 0.5), r)
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
	Lighting:SetAttribute("City", cityId)
	Lighting:SetAttribute("Sky", pal.sky)
	streetBuilt = true
end

function World.rebuild(data)
	World.recompute(data)
	if not streetBuilt or World.city ~= (data.franchise.city or "tokyo") then
		World.city = data.franchise.city or "tokyo"
		buildStreet(World.city)
	end
	buildShell(data)
	workspace:SetAttribute("WorldReady", true)
	World.Rebuilt:Fire()
end

function World.setOpenSign(open)
	if World.openLabel then
		World.openLabel.Text = open and "営業中" or "準備中"
	end
end

function World.Init()
	Registry.load()
	root = folder("Restaurant", workspace)
	shell = folder("Shell", root)
	street = folder("Street", workspace)
	itemsFolder = folder("Items", root)
	dynamicFolder = folder("Dynamic", root)
	npcFolder = folder("NPCs", workspace)
	pcall(function()
		PhysicsService:RegisterCollisionGroup("Shell")
		PhysicsService:RegisterCollisionGroup("NPC")
		PhysicsService:RegisterCollisionGroup("Player")
		PhysicsService:CollisionGroupSetCollidable("NPC", "NPC", false)
		PhysicsService:CollisionGroupSetCollidable("NPC", "Player", false)
		PhysicsService:CollisionGroupSetCollidable("Player", "Player", false)
	end)
	-- default world until the owner's data arrives
	local Data = Core.S.Data
	World.recompute(Data.newProfile())
end

function World.Start()
	local Session = Core.S.Session
	Session.OwnerReady:Connect(function(_, data)
		World.rebuild(data)
	end)
	local players = game:GetService("Players")
	local function setGroup(character)
		for _, d in ipairs(character:GetDescendants()) do
			if d:IsA("BasePart") then
				d.CollisionGroup = "Player"
			end
		end
		character.DescendantAdded:Connect(function(d)
			if d:IsA("BasePart") then
				d.CollisionGroup = "Player"
			end
		end)
	end
	local function onPlayer(p)
		p.CharacterAdded:Connect(function(character)
			setGroup(character)
			-- spawn in front of the restaurant
			task.defer(function()
				local hrp = character:WaitForChild("HumanoidRootPart", 5)
				if hrp then
					character:PivotTo(CFrame.new(0, 3, -6) * CFrame.Angles(0, math.rad(180), 0))
				end
			end)
		end)
		if p.Character then
			setGroup(p.Character)
		end
	end
	players.PlayerAdded:Connect(onPlayer)
	for _, p in ipairs(players:GetPlayers()) do
		onPlayer(p)
	end
	if not streetBuilt then
		buildStreet("tokyo")
	end
end

return World
