--!nonstrict
-- Game camera: a smooth orbit camera that rotates slowly (right mouse drag, one-finger drag on
-- the world, ← → keys), zooms with the wheel or a pinch, never ends up behind walls and hides the
-- roof when it rises above the ceiling, so the kitchen is always visible from above.
-- Also the build-mode top view and hiding roofs/ceilings while building.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")

local Core = require(script.Parent.Parent.Core)

local Camera = {}
Camera.top = false
Camera.build = false
Camera.floor = 0
local height = 48
local conn = nil
local player = Players.LocalPlayer

-- orbit state (degrees, studs)
local orbit = { yaw = 0, pitch = 38, dist = 22, targetDist = 22 }
local MIN_DIST, MAX_DIST = 8, 48
local BASE_SENS = 0.16 -- degrees per pixel at speed 1 (the Roblox default is much faster)
local roofsHiddenByOrbit = false
local rotating = false
local touches = {}

local FLOOR_HEIGHT = 15

function Camera.currentFloor()
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then
		return 0
	end
	return math.max(0, math.floor((root.Position.Y + 2) / FLOOR_HEIGHT))
end

-- hides roofs, ceilings and anything on the floors above `floor` (nil = show everything)
local function setRoofs(hidden, floor)
	for _, tagName in ipairs({ "Roof", "Ceiling" }) do
		for _, p in ipairs(CollectionService:GetTagged(tagName)) do
			if p:IsA("BasePart") then
				p.LocalTransparencyModifier = hidden and 1 or 0
			end
		end
	end
	for _, tagName in ipairs({ "Floor", "Wall" }) do
		for _, p in ipairs(CollectionService:GetTagged(tagName)) do
			if p:IsA("BasePart") then
				local f = p:GetAttribute("FloorIndex") or 0
				p.LocalTransparencyModifier = (hidden and floor and f > floor) and 1 or 0
			end
		end
	end
	local items = workspace:FindFirstChild("Restaurant") and workspace.Restaurant:FindFirstChild("Items")
	if items then
		for _, m in ipairs(items:GetChildren()) do
			local above = hidden and floor and (m:GetAttribute("FloorIndex") or 0) > floor
			for _, d in ipairs(m:GetDescendants()) do
				if d:IsA("BasePart") then
					-- parts tagged Roof (canopies, cords right under the ceiling) hide like the roof
					local roofLike = hidden and CollectionService:HasTag(d, "Roof")
					d.LocalTransparencyModifier = (above or roofLike) and 1 or 0
				end
			end
		end
	end
end

local function settings()
	local s = Core.C.Data and Core.C.Data.m and Core.C.Data.m("settings") or {}
	return s or {}
end

local function useGameCamera()
	return settings().cam ~= "roblox"
end

local function sensitivity()
	return BASE_SENS * (settings().camSpeed or 1)
end

-- Ray from the focus point to the wanted camera position, stopping before walls
local function clearDistance(focus, dir, dist)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ignore = { workspace.CurrentCamera }
	if player.Character then
		table.insert(ignore, player.Character)
	end
	local rest = workspace:FindFirstChild("Restaurant")
	if rest then
		for _, name in ipairs({ "Npcs", "Dynamic", "Items" }) do
			local f = rest:FindFirstChild(name)
			if f then
				table.insert(ignore, f)
			end
		end
	end
	for _, p in ipairs(CollectionService:GetTagged("Roof")) do
		table.insert(ignore, p)
	end
	for _, p in ipairs(CollectionService:GetTagged("Ceiling")) do
		table.insert(ignore, p)
	end
	params.FilterDescendantsInstances = ignore
	local hit = workspace:Raycast(focus, dir * dist, params)
	if hit then
		return math.max(2, (hit.Position - focus).Magnitude - 0.8)
	end
	return dist
end

local function orbitLoop(dt)
	local cam = workspace.CurrentCamera
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root or Camera.top or not useGameCamera() then
		return
	end
	if cam.CameraType ~= Enum.CameraType.Scriptable then
		cam.CameraType = Enum.CameraType.Scriptable
	end
	-- keyboard rotation, slow and steady
	local turn = 0
	if not UserInputService:GetFocusedTextBox() then
		if UserInputService:IsKeyDown(Enum.KeyCode.Left) then
			turn -= 1
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.Right) then
			turn += 1
		end
	end
	orbit.yaw += turn * 70 * dt * (settings().camSpeed or 1)
	orbit.dist += (orbit.targetDist - orbit.dist) * math.min(1, dt * 8)
	local focus = root.Position + Vector3.new(0, 2.2, 0)
	local rot = CFrame.Angles(0, math.rad(orbit.yaw), 0) * CFrame.Angles(-math.rad(orbit.pitch), 0, 0)
	local dir = -rot.LookVector
	local dist = clearDistance(focus, dir, orbit.dist)
	local pos = focus + dir * dist
	cam.CFrame = cam.CFrame:Lerp(CFrame.lookAt(pos, focus), math.min(1, dt * 14))
	cam.Focus = CFrame.new(focus)
	-- roof off when the camera is above this storey's ceiling (dollhouse view of the kitchen)
	if not Camera.build then
		local f = Camera.currentFloor()
		local above = pos.Y > f * FLOOR_HEIGHT + 13
		if above ~= roofsHiddenByOrbit then
			roofsHiddenByOrbit = above
			Camera.applyRoofs(above, f)
		end
	end
end

local function topLoop()
	local cam = workspace.CurrentCamera
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local focus = root.Position
	local pos = focus + Vector3.new(0, height, height * 0.55)
	cam.CFrame = cam.CFrame:Lerp(CFrame.lookAt(pos, focus), 0.25)
end

function Camera.applyRoofs(hidden, floor)
	setRoofs(hidden, floor)
end

function Camera.setTop(on)
	Camera.top = on
	local cam = workspace.CurrentCamera
	if on then
		cam.CameraType = Enum.CameraType.Scriptable
		if not conn then
			conn = RunService.RenderStepped:Connect(topLoop)
		end
	else
		if conn then
			conn:Disconnect()
			conn = nil
		end
		cam.CameraType = useGameCamera() and Enum.CameraType.Scriptable or Enum.CameraType.Custom
	end
end

function Camera.toggleTop()
	Camera.setTop(not Camera.top)
end

function Camera.setBuildView(on)
	Camera.build = on
	roofsHiddenByOrbit = nil
	Camera.floor = Camera.currentFloor()
	setRoofs(on, Camera.floor)
	if not on and Camera.top then
		Camera.setTop(false)
	end
end

function Camera.Start()
	RunService:BindToRenderStep("RamenCamera", Enum.RenderPriority.Camera.Value + 1, orbitLoop)
	player.CharacterAdded:Connect(function(char)
		local root = char:WaitForChild("HumanoidRootPart", 10)
		if root then
			local _, y = root.CFrame:ToEulerAnglesYXZ()
			orbit.yaw = math.deg(y)
		end
		if not useGameCamera() then
			workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
		end
	end)
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or not useGameCamera() then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton2 and not (Core.C.Build and Core.C.Build.itemId) then
			rotating = true
			UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
		elseif input.UserInputType == Enum.UserInputType.Touch then
			touches[input] = input.Position
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton2 and rotating then
			rotating = false
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		elseif input.UserInputType == Enum.UserInputType.Touch then
			touches[input] = nil
		end
	end)
	UserInputService.InputChanged:Connect(function(input, processed)
		if Camera.top and input.UserInputType == Enum.UserInputType.MouseWheel then
			height = math.clamp(height - input.Position.Z * 4, 18, 95)
			return
		end
		if not useGameCamera() then
			return
		end
		local sens = sensitivity()
		if input.UserInputType == Enum.UserInputType.MouseMovement and rotating then
			orbit.yaw -= input.Delta.X * sens
			orbit.pitch = math.clamp(orbit.pitch + input.Delta.Y * sens, 12, 78)
		elseif input.UserInputType == Enum.UserInputType.MouseWheel and not processed then
			orbit.targetDist = math.clamp(orbit.targetDist - input.Position.Z * 3, MIN_DIST, MAX_DIST)
		elseif input.UserInputType == Enum.UserInputType.Touch and touches[input] then
			local count = 0
			for _ in pairs(touches) do
				count += 1
			end
			local last = touches[input]
			local delta = input.Position - last
			touches[input] = input.Position
			if count == 1 then
				-- one finger on the world: rotate (slower than the default camera)
				orbit.yaw -= delta.X * sens * 1.4
				orbit.pitch = math.clamp(orbit.pitch + delta.Y * sens * 1.4, 12, 78)
			elseif count == 2 then
				-- pinch: zoom
				local other
				for inp, p in pairs(touches) do
					if inp ~= input then
						other = p
					end
				end
				if other then
					local before = (last - other).Magnitude
					local after = (input.Position - other).Magnitude
					orbit.targetDist = math.clamp(orbit.targetDist - (after - before) * 0.08, MIN_DIST, MAX_DIST)
				end
			end
		end
	end)
	CollectionService:GetInstanceAddedSignal("Roof"):Connect(function(p)
		if Camera.build and p:IsA("BasePart") then
			p.LocalTransparencyModifier = 1
		end
	end)
	-- follow the player up and down the stairs while building
	while true do
		task.wait(1)
		if Camera.build then
			local f = Camera.currentFloor()
			if f ~= Camera.floor then
				Camera.floor = f
			end
			setRoofs(true, Camera.floor)
		end
	end
end

return Camera
