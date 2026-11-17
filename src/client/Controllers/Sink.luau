--!nonstrict
-- Washing the dishes at the sink. While a sink has Washing = true (set by ApplianceService) every
-- client shows a dirty plate under the running tap with a sponge scrubbing it in circles while the
-- dirt fades away; each clean plate slides to the left, towards the drying rack, fading out.
-- The player who washes also sees a thin progress bar under the middle of the screen.
-- Holding: Interaction calls Sink.beginHold on click / E down (or the ✋ button) and Sink.endHold
-- on release; a tap on a touch screen toggles instead.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local NetDef = require(Shared.Net)
local Registry = require(Shared.Models.Registry)
local Kit = require(Shared.Models.Kit)
local UIKit = require(script.Parent.Parent.UI.Kit)
local Core = require(script.Parent.Parent.Core)

local Sink = {}
local player = Players.LocalPlayer
local scenes = {} -- [sink model] = { plate, dirt = { parts }, sponge }
local holding = nil -- sink uid we are holding on
local PLATE_LIFT = CFrame.new(0, 0.35, 0) -- a one-plate stack has its pivot 0.35 above its bottom
local barGui, barFill

-- where the plate is scrubbed: in the empty basin under the tap, tilted towards you
local function plateCf(m)
	local root = m.PrimaryPart
	local h = root.Size.Y
	return root.CFrame * CFrame.new(0.25, (h - 0.3) - h / 2, -0.12) * CFrame.Angles(math.rad(-22), 0, 0)
end

local function noQuery(model)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
		end
	end
end

local function makeScene(m)
	local folder = Instance.new("Model")
	folder.Name = "WashScene"
	-- a clean plate with dirt on top (sauce smears and rice) that fades while scrubbing
	local plate = Registry.food("stack", 1, "clean")
	noQuery(plate)
	plate.Parent = folder
	local dirtModel = Kit.model("Dirt")
	local dirt = {}
	for i, spot in ipairs({ { 0.18, 0.1, 0.32 }, { -0.2, -0.12, 0.26 }, { 0.05, -0.25, 0.18 } }) do
		local p = Kit.cyl(dirtModel, spot[3], 0.012, spot[1], 0.125, spot[2], i == 2 and "#C08A3E" or "#6B3E1E", Enum.Material.SmoothPlastic, { collide = false, shadow = false })
		table.insert(dirt, p)
	end
	for k = 0, 5 do
		local p = Kit.ball(dirtModel, 0.06, -0.25 + k * 0.1, 0.14, (k % 2) * 0.16 - 0.05, "#F4F1EA", Enum.Material.Sand, { collide = false, shadow = false })
		table.insert(dirt, p)
	end
	noQuery(dirtModel)
	dirtModel.WorldPivot = CFrame.new() -- built around the bottom of the plate
	dirtModel.Parent = folder
	-- the sponge: yellow foam with a green scrubbing side, and a few soap bubbles
	local spongeModel = Kit.model("Sponge")
	local foam = Kit.box(spongeModel, 0.42, 0.16, 0.28, 0, 0.08, 0, "#F2D04A", Enum.Material.Fabric, { collide = false })
	Kit.box(spongeModel, 0.42, 0.05, 0.28, 0, -0.025, 0, "#4E8A3A", Enum.Material.Fabric, { collide = false })
	Kit.particles(foam, "bubbles", { rate = 14 })
	noQuery(spongeModel)
	spongeModel.WorldPivot = CFrame.new()
	spongeModel.Parent = folder
	folder.Parent = workspace.CurrentCamera
	return { folder = folder, plate = plate, dirtModel = dirtModel, dirt = dirt, sponge = spongeModel }
end

local function progressOf(m)
	local start = m:GetAttribute("WashStart") or workspace:GetServerTimeNow()
	local dur = math.max(0.1, m:GetAttribute("WashTime") or 1)
	return math.clamp((workspace:GetServerTimeNow() - start) / dur, 0, 1)
end

local function update()
	local now = os.clock()
	local mine = nil
	for _, m in ipairs(CollectionService:GetTagged("Interactable")) do
		if m:GetAttribute("Kind") == "sink" then
			local sc = scenes[m]
			if m:GetAttribute("Washing") and m.PrimaryPart then
				if not sc then
					sc = makeScene(m)
					scenes[m] = sc
				end
				local t = progressOf(m)
				local base = plateCf(m)
				local spin = CFrame.Angles(0, now * 0.9, 0)
				sc.plate:PivotTo(base * spin * PLATE_LIFT)
				sc.dirtModel:PivotTo(base * spin)
				for _, p in ipairs(sc.dirt) do
					p.Transparency = math.min(1, t * 1.15)
				end
				-- the sponge scrubs in small circles over the plate
				local a = now * 9
				local r = 0.22 + 0.06 * math.sin(now * 3)
				sc.sponge:PivotTo(base * CFrame.new(math.cos(a) * r, 0.17, math.sin(a) * r) * CFrame.Angles(0, -a, math.sin(a * 2) * 0.12))
				if m:GetAttribute("Washer") == player.UserId then
					mine = t
				end
			elseif sc then
				sc.folder:Destroy()
				scenes[m] = nil
			end
		end
	end
	for m, sc in pairs(scenes) do
		if not m.Parent then
			sc.folder:Destroy()
			scenes[m] = nil
		end
	end
	barGui.Enabled = mine ~= nil
	if mine then
		barFill.Size = UDim2.fromScale(mine, 1)
	end
end

-- a clean plate slides to the left (towards the drying rack) and fades out
function Sink.washed(uid)
	local m = nil
	for _, inst in ipairs(CollectionService:GetTagged("Interactable")) do
		if inst:GetAttribute("Uid") == uid then
			m = inst
		end
	end
	if not m or not m.PrimaryPart then
		return
	end
	local start = plateCf(m)
	local plate = Registry.food("stack", 1, "clean")
	noQuery(plate)
	start = start * PLATE_LIFT
	plate:PivotTo(start)
	plate.Parent = workspace.CurrentCamera
	local parts = {}
	for _, d in ipairs(plate:GetDescendants()) do
		if d:IsA("BasePart") then
			table.insert(parts, { part = d, base = d.Transparency })
		end
	end
	-- the sink's +X is the left of a player facing it
	local goal = start * CFrame.new(1.3, 0.3, 0) * CFrame.Angles(math.rad(22), 0, 0)
	task.spawn(function()
		local t0 = os.clock()
		local dur = 0.7
		while os.clock() - t0 < dur do
			local k = (os.clock() - t0) / dur
			local ease = 1 - (1 - k) * (1 - k)
			plate:PivotTo(start:Lerp(goal, ease))
			for _, p in ipairs(parts) do
				p.part.Transparency = p.base + (1 - p.base) * k
			end
			RunService.RenderStepped:Wait()
		end
		plate:Destroy()
	end)
end

function Sink.beginHold(uid)
	if holding == uid then
		return
	end
	if holding then
		Sink.endHold()
	end
	holding = uid
	NetDef.event("Wash"):FireServer(uid, true)
end

function Sink.endHold()
	if holding then
		NetDef.event("Wash"):FireServer(holding, false)
		holding = nil
	end
end

function Sink.toggle(uid)
	if holding == uid then
		Sink.endHold()
	else
		Sink.beginHold(uid)
	end
end

function Sink.isHolding()
	return holding ~= nil
end

function Sink.Init()
	barGui = UIKit.new("ScreenGui", { Name = "WashBar", ResetOnSpawn = false, IgnoreGuiInset = true, Enabled = false, Parent = player:WaitForChild("PlayerGui") })
	local track = UIKit.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.5, 58), Size = UDim2.fromOffset(200, 7),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.45, Parent = barGui,
	}, { UIKit.corner(4) })
	barFill = UIKit.new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = UIKit.Theme.gold, Parent = track }, { UIKit.corner(4) })
end

function Sink.Start()
	RunService.RenderStepped:Connect(update)
end

return Sink
