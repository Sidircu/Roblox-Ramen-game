--!nonstrict
-- Game camera (Settings → Camera): "auto" (default) picks "game" on phones and tablets and
-- "first" with a keyboard; or one of the three modes:
--   "first"  first person: mouse look, a crosshair in the middle, click / E on what you
--            look at (see Controllers/FirstPerson); Camera speed scales the mouse sensitivity
--   "game"   a smooth orbit camera that rotates slowly (right mouse drag, one-finger drag, ← →),
--            zooms with the wheel or a pinch, never ends up behind walls and hides the roof when
--            it rises above the ceiling while you are inside
--   "roblox" the standard Roblox camera
-- Also the build-mode top view and hiding roofs/ceilings while building.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")

local Core = require(script.Parent.Parent.Core)
local Footprint = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared").Logic.Footprint)

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

-- "auto" (the default): third person on phones and tablets, first person with a keyboard
function Camera.mode()
	local m = settings().cam
	if m == "game" or m == "roblox" or m == "first" then
		return m
	end
	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
		return "game"
	end
	return "first"
end

-- the orbit camera drives the view (not in first person, not while building in first person)
local function useGameCamera()
	return Camera.mode() == "game"
end

function Camera.isFirstPerson()
	return Camera.mode() == "first" and not Camera.build and not Camera.top
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

-- True when the player stands inside the restaurant (an indoor room of their storey)
local function indoors(pos, floor)
	local Build = Core.C.Build
	local geo = Build and Build.geometry and Build.geometry()
	if not geo then
		return false
	end
	for _, z in ipairs(geo.zones) do
		if z.floor == floor and not z.outdoor and Footprint.pointInRect(pos.X, pos.Z, z.rect) then
			return true
		end
	end
	return false
end

function Camera.isIndoors()
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	return root ~= nil and indoors(root.Position, Camera.currentFloor())
end

-- Applies the camera mode to the player (first person lock, zoom limits, camera type)
local applied = nil
function Camera.apply()
	local mode = Camera.mode()
	local key = mode .. (Camera.build and ":build" or "") .. (Camera.top and ":top" or "")
	if key == applied then
		return
	end
	applied = key
	local cam = workspace.CurrentCamera
	if mode == "first" and not Camera.build and not Camera.top then
		player.CameraMinZoomDistance = 0.5
		player.CameraMaxZoomDistance = 0.5
		player.CameraMode = Enum.CameraMode.LockFirstPerson
		cam.CameraType = Enum.CameraType.Custom
		cam.FieldOfView = 74
	else
		player.CameraMode = Enum.CameraMode.Classic
		player.CameraMaxZoomDistance = 60
		player.CameraMinZoomDistance = 6
		cam.FieldOfView = 70
		if not Camera.top then
			cam.CameraType = useGameCamera() and Enum.CameraType.Scriptable or Enum.CameraType.Custom
		end
	end
	if roofsHiddenByOrbit and not useGameCamera() and not Camera.build then
		roofsHiddenByOrbit = false
		setRoofs(false, nil)
	end
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
	-- roof off only when you are inside and the camera rises above this storey's ceiling
	-- (dollhouse view of the kitchen); from outside the roof and the facade always show
	if not Camera.build then
		local f = Camera.currentFloor()
		local above = pos.Y > f * FLOOR_HEIGHT + 13 and indoors(root.Position, f)
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
	Camera.apply()
end

function Camera.toggleTop()
	Camera.setTop(not Camera.top)
end

function Camera.setBuildView(on)
	Camera.build = on
	roofsHiddenByOrbit = nil
	Camera.floor = Camera.currentFloor()
	setRoofs(on, Camera.floor)
	if on and Camera.mode() == "first" then
		-- building needs the mouse and a view from above
		Camera.setTop(true)
	elseif not on and Camera.top then
		Camera.setTop(false)
	end
	Camera.apply()
end

function Camera.Start()
	RunService:BindToRenderStep("RamenCamera", Enum.RenderPriority.Camera.Value + 1, orbitLoop)
	Camera.apply()
	player.CharacterAdded:Connect(function(char)
		local root = char:WaitForChild("HumanoidRootPart", 10)
		if root then
			local _, y = root.CFrame:ToEulerAnglesYXZ()
			orbit.yaw = math.deg(y)
		end
		applied = nil
		Camera.apply()
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
	-- follow the player up and down the stairs while building; pick up camera setting changes
	while true do
		task.wait(1)
		Camera.apply()
		-- Settings → Camera speed also scales the mouse in first person and with the Roblox
		-- camera (on top of Roblox's own sensitivity); the orbit camera applies it itself
		local want = Camera.mode() == "game" and 1 or (settings().camSpeed or 1)
		if UserInputService.MouseDeltaSensitivity ~= want then
			UserInputService.MouseDeltaSensitivity = want
		end
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
