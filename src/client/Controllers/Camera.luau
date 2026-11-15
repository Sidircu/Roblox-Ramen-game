--!nonstrict
-- Build-mode camera (top view) and hiding roofs/ceilings while building.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")

local Camera = {}
Camera.top = false
Camera.build = false
local height = 48
local conn = nil
local player = Players.LocalPlayer

local function setRoofs(hidden)
	for _, tagName in ipairs({ "Roof", "Ceiling" }) do
		for _, p in ipairs(CollectionService:GetTagged(tagName)) do
			if p:IsA("BasePart") then
				p.LocalTransparencyModifier = hidden and 1 or 0
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
	setRoofs(on)
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
end

return Camera
