--!nonstrict
-- Arrows that show where to go next, used by the tutorial and the one-time tips:
--   pointer:world(model)  a glowing beam from the player to the thing, with a bouncing ⬇️ above it
--   pointer:gui(button)   a bouncing 👇 and a pulsing ring on a button of the interface
--   pointer:hide()
-- Pointer.new(hexColour) makes one; each user keeps its own.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Color = require(Shared.Util.Color)
local Kit = require(script.Parent.Kit)
local Core = require(script.Parent.Parent.Core)

local Pointer = {}
Pointer.__index = Pointer
local player = Players.LocalPlayer

-- the button and all its parents are visible
local function shown(g)
	local n = g
	while n and not n:IsA("LayerCollector") do
		if n:IsA("GuiObject") and not n.Visible then
			return false
		end
		n = n.Parent
	end
	return n ~= nil and n.Enabled
end

function Pointer.new(hex)
	local self = setmetatable({ t0 = os.clock() }, Pointer)
	local color = Color.hex(hex or "#FFD23B")
	-- in the world: a beam from the player and a marker above the thing
	self.a0 = Instance.new("Attachment")
	self.a1 = Instance.new("Attachment")
	local holder = Instance.new("Part")
	holder.Name = "PointerTarget"
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanQuery = false
	holder.CanTouch = false
	holder.Transparency = 1
	holder.Size = Vector3.new(0.2, 0.2, 0.2)
	self.holder = holder
	self.a1.Parent = holder
	local beam = Instance.new("Beam")
	beam.Attachment0 = self.a0
	beam.Attachment1 = self.a1
	beam.Width0 = 0.6
	beam.Width1 = 0.6
	beam.FaceCamera = true
	beam.Color = ColorSequence.new(color)
	beam.LightEmission = 1
	beam.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	beam.TextureMode = Enum.TextureMode.Wrap
	beam.TextureSpeed = 2
	beam.Enabled = false
	beam.Parent = holder
	self.beam = beam
	local marker = Instance.new("BillboardGui")
	marker.Size = UDim2.fromOffset(64, 64)
	marker.StudsOffsetWorldSpace = Vector3.new(0, 4, 0)
	marker.AlwaysOnTop = true
	marker.Enabled = false
	marker.Adornee = holder
	marker.Parent = player:WaitForChild("PlayerGui")
	local arrow = Instance.new("TextLabel")
	arrow.Size = UDim2.fromScale(1, 1)
	arrow.BackgroundTransparency = 1
	arrow.Text = "⬇️"
	arrow.TextScaled = true
	arrow.AutoLocalize = false
	arrow.Parent = marker
	self.marker = marker
	-- on the screen: a ring and a hand on a button (drawn above windows)
	local root = Core.C.UI.root()
	self.ring = Kit.new("Frame", { Name = "PointerRing", BackgroundTransparency = 1, ZIndex = 30, Visible = false, Parent = root }, { Kit.corner(18), Kit.stroke(color, 4, 0) })
	self.hand = Kit.label("👇", { Name = "PointerHand", Size = UDim2.fromOffset(46, 46), TextScaled = true, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 31, Visible = false, Parent = root })
	RunService.RenderStepped:Connect(function()
		self:step()
	end)
	return self
end

function Pointer:world(model)
	self.target = model
	self.guiTarget = nil
end

function Pointer:gui(button)
	self.guiTarget = button
	self.target = nil
end

function Pointer:hide()
	self.target = nil
	self.guiTarget = nil
end

function Pointer:step()
	local bob = math.sin((os.clock() - self.t0) * 5)
	local target = self.target
	if target and target.Parent and target:IsDescendantOf(workspace) then
		local rootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if rootPart and self.a0.Parent ~= rootPart then
			self.a0.Parent = rootPart
		end
		if self.holder.Parent ~= workspace.CurrentCamera then
			self.holder.Parent = workspace.CurrentCamera
		end
		self.holder.Position = target:GetPivot().Position + Vector3.new(0, 2, 0)
		self.marker.StudsOffsetWorldSpace = Vector3.new(0, 4 + bob * 0.6, 0)
		self.beam.Enabled = rootPart ~= nil
		self.marker.Enabled = true
	else
		self.beam.Enabled = false
		self.marker.Enabled = false
	end
	local g = self.guiTarget
	local UI = Core.C.UI
	if g and g.Parent and shown(g) and UI.gui then
		local scale = math.max(UI.scale or 1, 0.01)
		local pos = (g.AbsolutePosition - UI.gui.AbsolutePosition) / scale
		local size = g.AbsoluteSize / scale
		self.ring.Position = UDim2.fromOffset(pos.X - 6, pos.Y - 6)
		self.ring.Size = UDim2.fromOffset(size.X + 12, size.Y + 12)
		local stroke = self.ring:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Transparency = 0.15 + 0.35 * (bob + 1) / 2
		end
		-- the hand points down from above, or up from below for buttons near the top
		local below = pos.Y < 60
		self.hand.Text = below and "👆" or "👇"
		local y = below and (pos.Y + size.Y + 6 + bob * 6) or (pos.Y - 52 + bob * 6)
		self.hand.Position = UDim2.fromOffset(pos.X + size.X / 2 - 23, y)
		self.ring.Visible = true
		self.hand.Visible = true
	else
		self.ring.Visible = false
		self.hand.Visible = false
	end
end

return Pointer
