--!nonstrict
-- Build-mode camera (top view) and hiding roofs/ceilings while building.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")

local Camera = {}
Camera.top = false
Camera.build = false
Camera.floor = 0
local height = 48
local conn = nil
local player = Players.LocalPlayer

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
					d.LocalTransparencyModifier = above and 1 or 0
				end
			end
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
		cam.CameraType = Enum.CameraType.Custom
	end
end

function Camera.toggleTop()
	Camera.setTop(not Camera.top)
end

function Camera.setBuildView(on)
	Camera.build = on
	Camera.floor = Camera.currentFloor()
	setRoofs(on, Camera.floor)
	if not on and Camera.top then
		Camera.setTop(false)
	end
end

function Camera.Start()
	UserInputService.InputChanged:Connect(function(input)
		if Camera.top and input.UserInputType == Enum.UserInputType.MouseWheel then
			height = math.clamp(height - input.Position.Z * 4, 18, 95)
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
