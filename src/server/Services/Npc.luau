--!nonstrict
-- NPC characters (customers and staff): creation, pooling, animations, walking with pathfinding,
-- sitting and simple emotes.
local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local NpcLooks = require(Shared.Config.NpcLooks)
local Registry = require(Shared.Models.Registry)
local Color = require(Shared.Util.Color)
local Core = require(script.Parent.Parent.Core)

local Npc = {}

local ANIMS = {
	idle = "rbxassetid://507766666",
	walk = "rbxassetid://507777826",
	sit = "rbxassetid://2506281703",
	hold = "rbxassetid://507768375",
	wave = "rbxassetid://507770239",
	cheer = "rbxassetid://507770677",
}

local pool = {}
local rng = Random.new()
local active = 0

function Npc.count()
	return active
end

local function loadAnims(model)
	local hum = model:FindFirstChildOfClass("Humanoid")
	local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
	local tracks = {}
	for name, id in pairs(ANIMS) do
		local a = Instance.new("Animation")
		a.AnimationId = id
		local ok, track = pcall(function()
			return animator:LoadAnimation(a)
		end)
		if ok and track then
			if name == "walk" or name == "idle" or name == "sit" or name == "hold" then
				track.Looped = true
			end
			if name == "sit" then
				track.Priority = Enum.AnimationPriority.Action
			elseif name == "hold" then
				track.Priority = Enum.AnimationPriority.Action
			elseif name == "wave" or name == "cheer" then
				track.Priority = Enum.AnimationPriority.Action2
			else
				track.Priority = Enum.AnimationPriority.Core
			end
			tracks[name] = track
		end
	end
	return tracks
end

local function setupAnimator(npc)
	local hum = npc.humanoid
	npc.tracks = loadAnims(npc.model)
	local current = nil
	local function play(name)
		if current == name then
			return
		end
		if current and npc.tracks[current] then
			npc.tracks[current]:Stop(0.2)
		end
		current = name
		if npc.tracks[name] then
			npc.tracks[name]:Play(0.2)
		end
	end
	hum.Running:Connect(function(speed)
		if npc.sitting then
			return
		end
		if speed > 0.5 then
			play("walk")
		else
			play("idle")
		end
	end)
	npc.play = play
	play("idle")
end

local function describe(look, shirtColor)
	local desc = Instance.new("HumanoidDescription")
	local skin = Color.hex(NpcLooks.skin[rng:NextInteger(1, #NpcLooks.skin)])
	local shirts = NpcLooks.shirts[look] or NpcLooks.shirts.casual
	local shirt = shirtColor and Color.hex(shirtColor) or Color.hex(shirts[rng:NextInteger(1, #shirts)])
	local pants = Color.hex(NpcLooks.pants[rng:NextInteger(1, #NpcLooks.pants)])
	desc.HeadColor = skin
	desc.LeftArmColor = shirt
	desc.RightArmColor = shirt
	desc.TorsoColor = shirt
	desc.LeftLegColor = pants
	desc.RightLegColor = pants
	if #NpcLooks.catalogHats > 0 and rng:NextNumber() < 0.4 then
		desc.HatAccessory = tostring(NpcLooks.catalogHats[rng:NextInteger(1, #NpcLooks.catalogHats)])
	end
	return desc
end

-- Creates a new NPC. opts: { look = "casual", shirt = "#hex", staff = role }
function Npc.create(opts)
	opts = opts or {}
	local model
	local desc = describe(opts.look or "casual", opts.shirt)
	local ok, err = pcall(function()
		model = Players:CreateHumanoidModelFromDescriptionAsync(desc, Enum.HumanoidRigType.R15)
	end)
	if not ok or not model then
		-- older engine versions only have the non-Async name
		ok, err = pcall(function()
			model = Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
		end)
	end
	if not ok or not model then
		warn("[Npc] could not create rig: " .. tostring(err))
		return nil
	end
	model.Name = opts.staff and "Staff" or "Customer"
	local hum = model:FindFirstChildOfClass("Humanoid")
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	hum.BreakJointsOnDeath = false
	hum.WalkSpeed = opts.speed or GameConfig.Customers.WalkSpeed
	for _, st in ipairs({ Enum.HumanoidStateType.Climbing, Enum.HumanoidStateType.Swimming, Enum.HumanoidStateType.FallingDown, Enum.HumanoidStateType.Ragdoll, Enum.HumanoidStateType.Dead, Enum.HumanoidStateType.Flying }) do
		pcall(function()
			hum:SetStateEnabled(st, false)
		end)
	end
	for _, s in ipairs(model:GetChildren()) do
		if s:IsA("Script") or s:IsA("LocalScript") then
			s:Destroy()
		end
	end
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.CollisionGroup = "NPC"
			d.CanTouch = false
		end
	end
	local People = Registry.People
	if opts.staff then
		People.hair(model, Color.hex(NpcLooks.hair[rng:NextInteger(1, #NpcLooks.hair)]), rng:NextInteger(1, 3))
		People.hat(model, opts.hat or "hachimaki")
		People.apron(model, Color.hex(opts.apron or "#2E3A5C"))
	else
		People.dress(model, opts.look or "casual", NpcLooks, rng)
	end
	local npc = { model = model, humanoid = hum, root = model:FindFirstChild("HumanoidRootPart"), sitting = false }
	return npc
end

function Npc.spawn(npc, cf)
	npc.model:PivotTo(cf)
	npc.model.Parent = Core.S.World.folders().npcs
	if npc.root then
		pcall(function()
			npc.root:SetNetworkOwner(nil)
		end)
	end
	if not npc.play then
		setupAnimator(npc)
	end
	active += 1
end

function Npc.acquireCustomer(look)
	-- reuse a pooled body when available (looks are re-randomized only for new ones)
	for i, npc in ipairs(pool) do
		if npc.look == look then
			table.remove(pool, i)
			return npc
		end
	end
	local npc = Npc.create({ look = look })
	if npc then
		npc.look = look
	end
	return npc
end

function Npc.release(npc)
	if not npc or not npc.model then
		return
	end
	Npc.stand(npc)
	npc.model.Parent = nil
	npc.model:SetAttribute("Uid", nil)
	active = math.max(0, active - 1)
	if #pool < 16 and not npc.isStaff then
		table.insert(pool, npc)
	else
		npc.model:Destroy()
	end
end

function Npc.destroy(npc)
	if npc and npc.model then
		active = math.max(0, active - 1)
		npc.model:Destroy()
	end
end

local customerPath = { AgentRadius = 1.1, AgentHeight = 5, AgentCanJump = false, WaypointSpacing = 4, Costs = { StaffOnly = math.huge } }
local staffPath = { AgentRadius = 1.1, AgentHeight = 5, AgentCanJump = false, WaypointSpacing = 4 }

local function moveTo(npc, pos, timeout)
	local hum = npc.humanoid
	hum:MoveTo(pos)
	local done = false
	local reached = false
	local conn
	conn = hum.MoveToFinished:Connect(function(r)
		done = true
		reached = r
	end)
	local t0 = os.clock()
	while not done and os.clock() - t0 < (timeout or 6) do
		task.wait(0.1)
		if not npc.model.Parent then
			break
		end
	end
	conn:Disconnect()
	return reached
end

-- Walks to a position. Returns true when arrived (teleports if stuck for too long).
function Npc.walkTo(npc, target, opts)
	opts = opts or {}
	if not npc.model.Parent or not npc.root then
		return false
	end
	Npc.stand(npc)
	local params = opts.staff and staffPath or customerPath
	local path = PathfindingService:CreatePath(params)
	local ok = pcall(function()
		path:ComputeAsync(npc.root.Position, target)
	end)
	if ok and path.Status == Enum.PathStatus.Success then
		local waypoints = path:GetWaypoints()
		for i = 2, #waypoints do
			if not npc.model.Parent or npc.cancel then
				return false
			end
			local wp = waypoints[i]
			if not moveTo(npc, wp.Position, 4) then
				-- blocked: try straight towards the target
				break
			end
		end
	end
	if npc.model.Parent and (npc.root.Position - target).Magnitude > 3 then
		moveTo(npc, target, 4)
	end
	if npc.model.Parent and (npc.root.Position - target).Magnitude > 4 then
		-- stuck (blocked path): small teleport so the game never soft-locks
		npc.model:PivotTo(CFrame.new(target + Vector3.new(0, 3, 0)))
	end
	return npc.model.Parent ~= nil
end

function Npc.face(npc, pos)
	if npc.root then
		local p = npc.root.Position
		local look = Vector3.new(pos.X, p.Y, pos.Z)
		if (look - p).Magnitude > 0.1 then
			npc.root.CFrame = CFrame.lookAt(p, look)
		end
	end
end

-- Sits at a seat CFrame (position = seat top, look = facing)
function Npc.sit(npc, sitCf)
	if not npc.root then
		return
	end
	npc.sitting = true
	npc.root.Anchored = true
	npc.model:PivotTo(sitCf * CFrame.new(0, GameConfig.Customers.SeatHeightOffset, 0))
	if npc.play then
		npc.play("sit")
	end
end

function Npc.stand(npc)
	if npc.sitting and npc.root then
		npc.sitting = false
		npc.root.Anchored = false
		npc.model:PivotTo(npc.root.CFrame * CFrame.new(0, 0.5, 1.8))
		if npc.play then
			npc.play("idle")
		end
	end
end

function Npc.emote(npc, name)
	local t = npc.tracks and npc.tracks[name]
	if t then
		t:Play(0.1)
	end
end

function Npc.Start()
	-- prewarm a few customer bodies
	task.spawn(function()
		for _ = 1, 4 do
			local npc = Npc.create({ look = "casual" })
			if npc then
				npc.look = "casual"
				table.insert(pool, npc)
			end
			task.wait(0.2)
		end
	end)
end

return Npc
