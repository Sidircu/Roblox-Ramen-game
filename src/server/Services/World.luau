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
local Scene = require(Shared.Models.Scene)
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

function World.surfaceOf(data, zone, kind)
	return Scene.surfaceOf(data, zone, kind)
end

local function geo()
	return { zones = World.zones, openings = World.openings, stairs = World.stairs, walls = World.walls, fixed = World.fixed }
end

local function buildShell(data)
	local result = Scene.shell(shell, geo(), data)
	World.openLabel = result.openLabel
end

local function buildStreet(cityId)
	local result = Scene.street(street, cityId)
	Lighting:SetAttribute("City", cityId)
	Lighting:SetAttribute("Sky", result.sky)
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
