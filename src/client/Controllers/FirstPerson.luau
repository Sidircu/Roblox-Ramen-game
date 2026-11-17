--!nonstrict
-- First person (Settings → Camera, the default):
--   * a crosshair in the middle of the screen; under it, what clicking / E does on the object you
--     look at (gold when close enough)
--   * what you hold is shown in front of the camera, with a light walking sway
--   * the mouse is freed while a menu is open, while building or while Alt is held
--   * keyboard shortcuts for the bottom buttons: B build, O supplier, P phone (all camera modes)
--   * on touch screens a big ✋ button uses what is under the crosshair (tapping things works too)
--   * running: hold Shift, or the 🏃 button on touch screens (every camera mode)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Locale = require(Shared.Locale)
local RewardsCfg = require(Shared.Config.Rewards)
local Kit = require(script.Parent.Parent.UI.Kit)
local Core = require(script.Parent.Parent.Core)

local FirstPerson = {}
local player = Players.LocalPlayer
local t = Locale.t
local T = Kit.Theme

local gui, dot, hintPill, hintText, modal, keysLabel, useButton, runButton
local altHeld = false
local shiftHeld = false
local runToggle = false
local views = {} -- [held model on the character] = { clone, rel }
local bob = 0

local function active()
	local Camera = Core.C.Camera
	return Camera ~= nil and Camera.isFirstPerson ~= nil and Camera.isFirstPerson()
end

-- true while the mouse must move freely (menus, building, Alt)
function FirstPerson.cursorFree()
	if altHeld then
		return true
	end
	local UI = Core.C.UI
	if UI and UI.current then
		return true
	end
	if Core.C.Build and Core.C.Build.active then
		return true
	end
	return false
end

local function clearViews()
	for m, v in pairs(views) do
		v.clone:Destroy()
		views[m] = nil
	end
end

-- copies of the held items (the character itself is hidden in first person)
local function syncViews(char, hrp)
	for m, v in pairs(views) do
		if m.Parent ~= char then
			v.clone:Destroy()
			views[m] = nil
		end
	end
	for _, m in ipairs(char:GetChildren()) do
		if m:IsA("Model") and m:GetAttribute("Held") and not views[m] then
			local ok, clone = pcall(function()
				return m:Clone()
			end)
			if ok and clone then
				for _, d in ipairs(clone:GetDescendants()) do
					if d:IsA("JointInstance") or d:IsA("WeldConstraint") then
						d:Destroy()
					elseif d:IsA("BasePart") then
						d.Anchored = true
						d.CanCollide = false
						d.CanQuery = false
						d.CanTouch = false
						d.CastShadow = false
						d.LocalTransparencyModifier = 0
					end
				end
				clone.Parent = workspace.CurrentCamera
				views[m] = { clone = clone, rel = hrp.CFrame:ToObjectSpace(m:GetPivot()) }
			end
		end
	end
end

local function updateViews(dt)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp or not active() then
		clearViews()
		return
	end
	syncViews(char, hrp)
	local cam = workspace.CurrentCamera
	local speed = Vector3.new(hrp.AssemblyLinearVelocity.X, 0, hrp.AssemblyLinearVelocity.Z).Magnitude
	local moving = speed > 1
	bob += dt * (moving and 9 or 1.6)
	local amp = moving and 0.05 or 0.015
	local base = cam.CFrame * CFrame.new(0.5 + math.cos(bob * 0.5) * amp, -1.5 + math.abs(math.sin(bob)) * amp, -0.6)
	for _, v in pairs(views) do
		v.clone:PivotTo(base * v.rel)
	end
end

local function updateCrosshair()
	local fp = active()
	local free = FirstPerson.cursorFree()
	modal.Visible = fp and free
	local show = fp and not free
	dot.Visible = show
	local touch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	keysLabel.Visible = fp and not touch and not free
	local target = show and Core.C.Interaction and Core.C.Interaction.target and Core.C.Interaction.target()
	if target and target.text then
		hintPill.Visible = true
		hintText.Text = target.near and ((touch and "✋ " or "🖱️ ") .. target.text) or ("🚶 " .. t("hint.get_closer"))
		dot.Size = UDim2.fromOffset(target.near and 14 or 10, target.near and 14 or 10)
		dot.BackgroundColor3 = target.near and T.gold or Color3.fromRGB(220, 214, 205)
	else
		hintPill.Visible = false
		dot.Size = UDim2.fromOffset(6, 6)
		dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	end
	useButton.Visible = show and touch and target ~= nil and target.near == true
end

local function shortcut(key)
	local UI = Core.C.UI
	if key == Enum.KeyCode.B then
		if Core.C.Build then
			Core.C.Build.toggle()
		end
	elseif key == Enum.KeyCode.O then
		if Core.C.Build and Core.C.Build.active then
			return
		end
		UI.toggle("Supplier")
	elseif key == Enum.KeyCode.P then
		if Core.C.Build and Core.C.Build.active then
			return
		end
		UI.toggle("Phone")
	elseif key == Enum.KeyCode.R then
		if Core.C.Build and Core.C.Build.active then
			return
		end
		UI.toggle("Gifts")
	end
end

-- walking speed from the server (shoes upgrade included) times the run multiplier
local function updateRun()
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	local base = player:GetAttribute("WalkSpeed")
	if not hum or not base then
		return
	end
	local running = shiftHeld or runToggle
	local want = running and base * (RewardsCfg.RunMultiplier or 1.4) or base
	if math.abs(hum.WalkSpeed - want) > 0.01 then
		hum.WalkSpeed = want
	end
	local touch = UserInputService.TouchEnabled
	runButton.Visible = touch and not (Core.C.Build and Core.C.Build.active)
	runButton.BackgroundColor3 = runToggle and T.green or T.paper
end

function FirstPerson.Init()
	gui = Kit.new("ScreenGui", { Name = "FirstPerson", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = -1, Parent = player:WaitForChild("PlayerGui") })
	dot = Kit.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(6, 6),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255), Visible = false, Parent = gui,
	}, { Kit.corner(8), Kit.stroke(Color3.fromRGB(30, 26, 24), 1.5, 0.2) })
	hintPill = Kit.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.5, 18), Size = UDim2.fromOffset(0, 32),
		AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = Color3.fromRGB(43, 35, 32), BackgroundTransparency = 0.15, Visible = false, Parent = gui,
	}, { Kit.corner(12), Kit.padding(12, 4) })
	hintText = Kit.label("", {
		Parent = hintPill, Size = UDim2.fromOffset(0, 24), AutomaticSize = Enum.AutomaticSize.X, TextSize = 17, FontFace = T.bold, TextWrapped = false,
		TextColor3 = Color3.fromRGB(244, 235, 221), TextYAlignment = Enum.TextYAlignment.Center,
	})
	keysLabel = Kit.label("", {
		Parent = gui, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -12, 1, -10), Size = UDim2.fromOffset(330, 60),
		TextSize = 13, FontFace = T.bold, TextColor3 = Color3.fromRGB(255, 255, 255), TextStrokeTransparency = 0.4, TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Right, TextYAlignment = Enum.TextYAlignment.Bottom, Visible = false,
	})
	-- a visible Modal button is what frees the mouse in first person
	modal = Kit.new("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.fromOffset(0, 0), Modal = true, Visible = false, Parent = gui })
	useButton = Kit.new("TextButton", {
		AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -24, 1, -190), Size = UDim2.fromOffset(86, 86), Text = "✋",
		TextScaled = true, BackgroundColor3 = T.gold, Visible = false, Parent = gui,
	}, { Kit.corner(43), Kit.stroke(T.wood, 3, 0) })
	useButton.Activated:Connect(function()
		if Core.C.Interaction and Core.C.Interaction.act then
			Core.C.Interaction.act()
		end
	end)
	runButton = Kit.new("TextButton", {
		AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -120, 1, -110), Size = UDim2.fromOffset(64, 64), Text = "🏃",
		TextScaled = true, BackgroundColor3 = T.paper, Visible = false, Parent = gui,
	}, { Kit.corner(32), Kit.stroke(T.wood, 3, 0) })
	runButton.Activated:Connect(function()
		runToggle = not runToggle
	end)
	local function refreshKeys()
		keysLabel.Text = t("ui.fp_keys")
	end
	refreshKeys()
	Locale.Changed:Connect(refreshKeys)
end

function FirstPerson.Start()
	RunService.RenderStepped:Connect(function(dt)
		updateCrosshair()
		updateViews(dt)
		updateRun()
	end)
	UserInputService.InputBegan:Connect(function(input, processed)
		if input.KeyCode == Enum.KeyCode.LeftAlt or input.KeyCode == Enum.KeyCode.RightAlt then
			altHeld = true
			return
		end
		if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
			shiftHeld = true
			return
		end
		if processed or UserInputService:GetFocusedTextBox() then
			return
		end
		shortcut(input.KeyCode)
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.LeftAlt or input.KeyCode == Enum.KeyCode.RightAlt then
			altHeld = false
		elseif input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
			shiftHeld = false
		end
	end)
	player.CharacterRemoving:Connect(clearViews)
end

return FirstPerson
