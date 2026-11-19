--!nonstrict
-- Builds the street (once, with a lot for every plot) and the shell of each restaurant from the
-- zones its owner unlocked; exposes each plot's geometry (zones, walls, stairs, openings) to
-- placement, seating and NPC services. Geometry is in restaurant-local coordinates; the shell is
-- built there and then moved onto the plot.
local PhysicsService = game:GetService("PhysicsService")
local Lighting = game:GetService("Lighting")

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

local function buildStreet(cityId)
	local lots = {}
	for _, plot in ipairs(Core.S.Plots.list) do
		table.insert(lots, plot.origin.X)
	end
	local result = Scene.street(street, cityId, lots, PlotsCfg.StreetReach)
	Lighting:SetAttribute("City", cityId)
	Lighting:SetAttribute("Sky", result.sky)
	streetBuilt = true
end

-- the shell of an empty lot: a fence and a sign while nobody owns it
local function buildEmptyLot(plot)
	local shell = World.folders(plot).shell
	shell:ClearAllChildren()
	Scene.emptyLot(shell)
	Core.S.Plots.shift(shell, plot)
end

-- (re)builds the restaurant of a plot from its owner's data
function World.rebuild(plot, data)
	World.recompute(plot, data)
	local f = World.folders(plot)
	local result = Scene.shell(f.shell, World.geo(plot), data)
	plot.openLabel = result.openLabel
	if plot.openLabel then
		plot.openLabel.Text = "営業中"
	end
	-- the supplier tablet and menu board are per restaurant
	for _, d in ipairs(f.shell:GetDescendants()) do
		local uid = d:GetAttribute("Uid")
		if uid == "fixed_supplier" or uid == "fixed_menu" then
			d:SetAttribute("Uid", uid .. "_" .. plot.id)
			d:SetAttribute("PlotId", plot.id)
		end
	end
	Core.S.Plots.shift(f.shell, plot)
	plot.folder:SetAttribute("City", data.franchise and data.franchise.city or "tokyo")
	plot.folder:SetAttribute("Ready", true)
	World.Rebuilt:Fire(plot)
end

-- the owner left: back to an empty lot
function World.clear(plot)
	plot.geo = nil
	plot.openLabel = nil
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
