--!nonstrict
-- Builds the street (once, with a lot for every plot) and the shell of each restaurant from the
-- zones its owner unlocked; exposes each plot's geometry (zones, walls, stairs, openings) to
-- placement, seating and NPC services. Geometry is in restaurant-local coordinates; the shell is
-- built there and then moved onto the plot.
local PhysicsService = game:GetService("PhysicsService")
local Lighting = game:GetService("Lighting")
local CollectionService = game:GetService("CollectionService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local Expansions = require(Shared.Config.Expansions)
local Items = require(Shared.Config.Items)
local PlotsCfg = require(Shared.Config.Plots)
local Geometry = require(Shared.Logic.Geometry)
local Footprint = require(Shared.Logic.Footprint)
local Registry = require(Shared.Models.Registry)
local Scene = require(Shared.Models.Scene)
local Signal = require(Shared.Util.Signal)
local Core = require(script.Parent.Parent.Core)

local World = {}
World.Rebuilt = Signal.new() -- (plot)
World.city = "tokyo"

local street, npcFolder
local streetBuilt = false
local emptyGeo = nil

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

-- Floor index for a world height (players and NPCs standing on that floor)
function World.floorOf(y)
	return math.max(0, math.floor((y + 2) / GameConfig.FloorHeight))
end

-- the folders of a plot (and the shared ones)
function World.folders(plot)
	local f = plot and plot.folder
	return {
		root = f,
		shell = f and folder("Shell", f),
		items = f and folder("Items", f),
		dynamic = f and folder("Dynamic", f),
		npcs = npcFolder,
		street = street,
	}
end

-- geometry of a plot: { zones, openings, stairs, walls, expansions, fixed }
function World.geo(plot)
	return (plot and plot.geo) or emptyGeo
end

-- Recomputes the unlocked geometry of a plot from its owner's data
function World.recompute(plot, data)
	plot.geo = Geometry.compute(Expansions.list, data.zones, Expansions)
end

-- zone at restaurant-local x, z on floor f
function World.zoneAt(plot, x, z, f)
	for _, zone in ipairs(World.geo(plot).zones) do
		if zone.floor == (f or 0) and Footprint.pointInRect(x, z, zone.rect) then
			return zone
		end
	end
	return nil
end

-- zone at a world position (the plot is found from the position)
function World.zoneAtWorld(pos, f)
	local plot = Core.S.Plots.at(pos)
	if not plot then
		return nil
	end
	local p = Core.S.Plots.toLocal(plot, pos)
	return World.zoneAt(plot, p.X, p.Z, f), plot
end

function World.hasExpansion(plot, id)
	for _, e in ipairs(World.geo(plot).expansions or {}) do
		if e.id == id then
			return true
		end
	end
	return false
end

-- Door clearances that must stay free of objects
function World.fixedRects(plot)
	return World.geo(plot).fixed or {}
end

-- Placement validation context (see Shared.Logic.Placement), in local coordinates
function World.ctx(plot, placed)
	local g = World.geo(plot)
	return Geometry.ctx({ zones = g.zones, walls = g.walls, stairs = g.stairs, fixed = g.fixed }, Items.byId, placed, GameConfig)
end

function World.surfaceOf(data, zone, kind)
	return Scene.surfaceOf(data, zone, kind)
end

-- Decorative parts nothing collides with need no ray tests: the camera, clicks and build mode go
-- through them, and there are thousands fewer parts to test. Tagged parts (floors, walls,
-- ceilings, roofs) and things you use (tablet, menu board, for-sale signs) keep theirs.
local function quiet(container)
	for _, d in ipairs(container:GetDescendants()) do
		if d:IsA("BasePart") and not d.CanCollide and d.CanQuery and #CollectionService:GetTags(d) == 0 then
			local used = false
			local n = d.Parent
			while n and n ~= container do
				if CollectionService:HasTag(n, "Interactable") then
					used = true
					break
				end
				n = n.Parent
			end
			if not used then
				d.CanQuery = false
				d.CanTouch = false
			end
		end
	end
end
World.quiet = quiet

local function buildStreet(cityId)
	local lots = {}
	for _, plot in ipairs(Core.S.Plots.list) do
		table.insert(lots, plot.origin.X)
	end
	local result = Scene.street(street, cityId, lots, PlotsCfg.StreetReach)
	quiet(street)
	Lighting:SetAttribute("City", cityId)
	Lighting:SetAttribute("Sky", result.sky)
	streetBuilt = true
end

-- the shell of an empty lot: a fence and a sign while nobody owns it
local function buildEmptyLot(plot)
	local shell = World.folders(plot).shell
	shell:ClearAllChildren()
	Scene.emptyLot(shell)
	quiet(shell)
	Core.S.Plots.shift(shell, plot)
end

-- (re)builds the restaurant of a plot from its owner's data
function World.rebuild(plot, data)
	World.recompute(plot, data)
	local f = World.folders(plot)
	local result = Scene.shell(f.shell, World.geo(plot), data)
	plot.openLabel = result.openLabel
	plot.openSign = result.openSign
	-- a "for sale" sign on every ground-floor room that can be built next (its rooms before it
	-- are owned); the sign goes when the room is bought (the shell is built again)
	for _, e in ipairs(Expansions.list) do
		local z1 = e.zones and e.zones[1]
		if not e.reno and e.id ~= "zone_base" and z1 and (z1.floor or 0) == 0 and not data.zones[e.id] then
			local ready = true
			for _, req in ipairs(e.requires or {}) do
				if not data.zones[req] then
					ready = false
				end
			end
			if ready then
				Scene.forSale(f.shell, e, plot.id)
			end
		end
	end
	-- the supplier tablet and menu board are per restaurant
	for _, d in ipairs(f.shell:GetDescendants()) do
		local uid = d:GetAttribute("Uid")
		if uid == "fixed_supplier" or uid == "fixed_menu" or uid == "fixed_opensign" then
			d:SetAttribute("Uid", uid .. "_" .. plot.id)
			d:SetAttribute("PlotId", plot.id)
		end
	end
	quiet(f.shell)
	Core.S.Plots.shift(f.shell, plot)
	World.paintOpenSign(plot)
	plot.folder:SetAttribute("City", data.franchise and data.franchise.city or "tokyo")
	plot.folder:SetAttribute("Ready", true)
	World.Rebuilt:Fire(plot)
end

-- the LED sign by the door and the small wooden plate say whether the restaurant is open
-- (plot.closed, Plots.setOpen); clients read the plot's "Open" attribute
function World.paintOpenSign(plot)
	local open = not plot.closed
	plot.folder:SetAttribute("Open", open)
	if plot.openLabel then
		plot.openLabel.Text = open and "営業中" or "準備中"
	end
	local board = plot.openSign and plot.openSign.PrimaryPart
	if board then
		for _, side in ipairs({ "Front", "Back" }) do
			local gui = board:FindFirstChild(side)
			local label = gui and gui:FindFirstChild("Label")
			if label then
				label.Text = open and "OPEN" or "CLOSED"
				label.TextColor3 = open and Color3.fromRGB(92, 255, 122) or Color3.fromRGB(255, 59, 74)
			end
		end
		local glow = board:FindFirstChild("Glow")
		if glow then
			glow.Color = open and Color3.fromRGB(92, 255, 122) or Color3.fromRGB(255, 59, 74)
		end
	end
end

-- the owner left: back to an empty lot
function World.clear(plot)
	plot.geo = nil
	plot.openLabel = nil
	plot.openSign = nil
	plot.closed = false
	local f = World.folders(plot)
	f.items:ClearAllChildren()
	f.dynamic:ClearAllChildren()
	plot.folder:SetAttribute("Ready", false)
	buildEmptyLot(plot)
	World.Rebuilt:Fire(plot)
end

function World.Init()
	Registry.load()
	street = folder("Street", workspace)
	npcFolder = folder("NPCs", workspace)
	pcall(function()
		PhysicsService:RegisterCollisionGroup("Shell")
		PhysicsService:RegisterCollisionGroup("NPC")
		PhysicsService:RegisterCollisionGroup("Player")
		PhysicsService:CollisionGroupSetCollidable("NPC", "NPC", false)
		PhysicsService:CollisionGroupSetCollidable("NPC", "Player", false)
		PhysicsService:CollisionGroupSetCollidable("Player", "Player", false)
	end)
	-- geometry of a brand-new restaurant (used before an owner's data arrives)
	emptyGeo = Geometry.compute(Expansions.list, { zone_base = true }, Expansions)
end

function World.Start()
	local Plots = Core.S.Plots
	if not streetBuilt then
		buildStreet(World.city)
	end
	for _, plot in ipairs(Plots.list) do
		if not plot.owner then
			buildEmptyLot(plot)
		end
	end
	workspace:SetAttribute("WorldReady", true)
	Plots.Claimed:Connect(function(plot, _, data)
		World.rebuild(plot, data)
	end)
	Plots.Released:Connect(function(plot)
		World.clear(plot)
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
		p.CharacterAdded:Connect(setGroup)
		if p.Character then
			setGroup(p.Character)
		end
	end
	players.PlayerAdded:Connect(onPlayer)
	for _, p in ipairs(players:GetPlayers()) do
		onPlayer(p)
	end
end

return World
