--!nonstrict
-- First person (Settings → Camera, the default):
--   * a crosshair in the middle of the screen (the mouse arrow is hidden meanwhile); under it, what
--     clicking / E does on the object you look at (gold when close enough)
--   * what you hold is shown in front of the camera, with a light walking sway
--   * the mouse is freed while a menu is open, while building, while Alt is held or after Q
--     (Q again to look around); the first time a toast explains it
--   * keyboard shortcuts for the bottom buttons: B build, O supplier, P phone (all camera modes)
--   * the target's ProximityPrompt says what pressing does (tap it on touch screens)
--   * running: hold Shift, or the 🏃 button on touch screens (every camera mode)
--   * right mouse button puts down the box(es) you carry (in third person it turns the camera)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Locale = require(Shared.Locale)
local NetDef = require(Shared.Net)
local RewardsCfg = require(Shared.Config.Rewards)
local Kit = require(script.Parent.Parent.UI.Kit)
local Core = require(script.Parent.Parent.Core)

local FirstPerson = {}
local player = Players.LocalPlayer
local t = Locale.t
local T = Kit.Theme

local gui, dot, hintPill, hintText, modal, keysLabel, useButton, runButton
local altHeld = false
local cursorToggle = false
local toldAboutCursor = false
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
	if altHeld or cursorToggle then
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

-- highest point of the held items above the base point in front of the camera (2.05 below the
-- eyes): anything higher would cover the crosshair, so a taller stack is shown lower
local HELD_TOP = 1.7

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
					elseif d:IsA("SurfaceGui") or d:IsA("BillboardGui") then
						d.Enabled = true
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
				-- boxes sit low (they are big); dishes and ingredients a little higher to stay in view
				local lift = m.Name == "Box" and 0 or 0.5
				-- how far the top of the copy is above its pivot
				local okSize, box, size = pcall(function()
					return clone:GetBoundingBox()
				end)
				local above = 0.5
				if okSize and box and size then
					above = clone:GetPivot():PointToObjectSpace(box.Position).Y + size.Y / 2
				end
				views[m] = { clone = clone, rel = CFrame.new(0, lift, 0) * hrp.CFrame:ToObjectSpace(m:GetPivot()), above = above }
			end
		end
	end
end

-- Roblox hides the character's parts in first person but not the labels drawn on them: the label
-- of the real box would float in the air, so it is switched off for you (only your copy shows it)
local function setHeldLabels(char, on)
	for _, m in ipairs(char:GetChildren()) do
		if m:IsA("Model") and m:GetAttribute("Held") then
			for _, d in ipairs(m:GetDescendants()) do
				if (d:IsA("SurfaceGui") or d:IsA("BillboardGui")) and d.Enabled ~= on then
					d.Enabled = on
				end
			end
		end
	end
end

local function updateViews(dt)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp or not active() then
		clearViews()
		if char then
			setHeldLabels(char, true)
		end
		return
	end
	syncViews(char, hrp)
	setHeldLabels(char, false)
	local cam = workspace.CurrentCamera
	local speed = Vector3.new(hrp.AssemblyLinearVelocity.X, 0, hrp.AssemblyLinearVelocity.Z).Magnitude
	local moving = speed > 1
	bob += dt * (moving and 9 or 1.6)
	local amp = moving and 0.05 or 0.015
	local base = cam.CFrame * CFrame.new(0.45 + math.cos(bob * 0.5) * amp, -2.05 + math.abs(math.sin(bob)) * amp, -0.9)
	-- a tall stack (several dishes or boxes) goes down so its top stays under the crosshair
	local top = -math.huge
	for _, v in pairs(views) do
		top = math.max(top, v.rel.Position.Y + v.above)
	end
	if top > HELD_TOP then
		base = base * CFrame.new(0, HELD_TOP - top, 0)
	end
	for _, v in pairs(views) do
		v.clone:PivotTo(base * v.rel)
	end
end

local function updateCrosshair()
	local fp = active()
	if fp and not toldAboutCursor and UserInputService.KeyboardEnabled then
		toldAboutCursor = true
		task.delay(2, function()
			-- (the tutorial's welcome card says it already)
			local tut = Core.C.Tutorial
			if Core.C.UI and not (tut and tut.active and tut.active()) then
				Core.C.UI.toast("🖱️ " .. t("msg.fp_cursor"), "info")
			end
		end)
	end
	local free = FirstPerson.cursorFree()
	modal.Visible = fp and free
	local show = fp and not free
	dot.Visible = show
	-- the dot replaces the mouse arrow; the arrow comes back whenever the mouse is free
	if UserInputService.MouseIconEnabled == show then
		UserInputService.MouseIconEnabled = not show
	end
	local touch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	keysLabel.Visible = fp and not touch and not free
	local target = show and Core.C.Interaction and Core.C.Interaction.target and Core.C.Interaction.target()
	if target and target.text then
		-- close enough: the object's prompt says what E / a click / a tap does; too far: "get closer"
		hintPill.Visible = not target.near
		hintText.Text = "🚶 " .. t("hint.get_closer")
		dot.Size = UDim2.fromOffset(target.near and 14 or 10, target.near and 14 or 10)
		dot.BackgroundColor3 = target.near and T.gold or Color3.fromRGB(220, 214, 205)
	else
		hintPill.Visible = false
		dot.Size = UDim2.fromOffset(6, 6)
		dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	end
	-- the prompt is tappable: no extra use button on touch screens
	useButton.Visible = false
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
	elseif key == Enum.KeyCode.U then
		if Core.C.Build and Core.C.Build.active then
			return
		end
		UI.toggle("Shop")
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
	elseif key == Enum.KeyCode.Q then
		-- (Q cancels in build mode)
		if Core.C.Build and Core.C.Build.active then
			return
		end
		cursorToggle = not cursorToggle
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
	local controls = game:GetService("GuiService").TouchControlsEnabled ~= false
	runButton.Visible = touch and controls and not (Core.C.Build and Core.C.Build.active)
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
	-- pressed = use (and start washing at a sink), released = stop washing
	useButton.MouseButton1Down:Connect(function()
		if Core.C.Interaction and Core.C.Interaction.act then
			Core.C.Interaction.act()
		end
	end)
	useButton.MouseButton1Up:Connect(function()
		if Core.C.Sink then
			Core.C.Sink.endHold()
		end
	end)
	-- run toggle: just left of Roblox's jump button (70 points at (1, -95, 1, -90) on small
	-- screens, 120 points at (1, -170, 1, -210) on bigger ones), clear of the orders above it
	runButton = Kit.new("TextButton", {
		AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -107, 1, -27), Size = UDim2.fromOffset(56, 56), Text = "🏃",
		TextScaled = true, BackgroundColor3 = T.paper, Visible = false, Parent = gui,
	}, { Kit.corner(28), Kit.stroke(T.wood, 3, 0), Kit.padding(8) })
	local function placeRun()
		local cam = workspace.CurrentCamera
		local v = cam and cam.ViewportSize or Vector2.new(844, 390)
		if math.min(v.X, v.Y) <= 500 then
			runButton.Size = UDim2.fromOffset(56, 56)
			runButton.Position = UDim2.new(1, -107, 1, -27)
		else
			runButton.Size = UDim2.fromOffset(76, 76)
			runButton.Position = UDim2.new(1, -186, 1, -96)
		end
	end
	placeRun()
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(placeRun)
	end
	runButton.Activated:Connect(function()
		runToggle = not runToggle
	end)
	local function refreshKeys()
		keysLabel.Text = t("ui.fp_keys")
	end
	refreshKeys()
	Locale.Changed:Connect(refreshKeys)
end

-- true while the player types (a text box or the chat bar has the keyboard)
local function typing()
	if UserInputService:GetFocusedTextBox() then
		return true
	end
	local ok, focused = pcall(function()
		return game:GetService("TextChatService").ChatInputBarConfiguration.IsFocused
	end)
	return ok and focused == true
end

-- O (supplier) is also Roblox's "zoom out" key and Roblox's camera keeps it: depending on the
-- version the press reaches scripts marked as used, through an action bound above the camera, or
-- only as the release. Whichever comes first toggles the supplier, once per press: the press if it
-- arrives, otherwise the release; never while typing or building. The same press can arrive twice
-- (the action and UserInputService): it is the same InputObject, or the same moment
local oDown, oLast, oActAt, oEndAt = false, nil, -math.huge, -math.huge
local function supplierKey(began, input)
	local now = os.clock()
	if input ~= nil and input == oLast and (began or not oDown) then
		return
	end
	local act = false
	if began then
		if not (oDown and now - oActAt < 0.05) then
			oDown = true
			act = true
		end
	elseif oDown then
		oDown = false
		oEndAt = now
	elseif now - oEndAt >= 0.05 then
		oEndAt = now
		act = true
	end
	oLast = input or oLast
	if act then
		oActAt = now
		if not typing() and not (Core.C.Build and Core.C.Build.active) then
			shortcut(Enum.KeyCode.O)
		end
	end
end

function FirstPerson.Start()
	RunService.RenderStepped:Connect(function(dt)
		updateCrosshair()
		updateViews(dt)
		updateRun()
	end)
	ContextActionService:BindActionAtPriority("RamenSupplierKey", function(_, state, input)
		if state == Enum.UserInputState.Begin then
			supplierKey(true, input)
		elseif state == Enum.UserInputState.End then
			supplierKey(false, input)
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.ContextActionPriority.High.Value + 1000, Enum.KeyCode.O)
	UserInputService.InputBegan:Connect(function(input, processed)
		-- (O: even when Roblox's camera marked it as used)
		if input.KeyCode == Enum.KeyCode.O then
			supplierKey(true, input)
			return
		end
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
		-- right click puts the box down (only boxes: a dish dropped by mistake would be lost)
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			if active() and player:GetAttribute("HandsKind") == "box" then
				NetDef.event("DropHands"):FireServer()
			end
			return
		end
		shortcut(input.KeyCode)
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.O then
			supplierKey(false, input)
			return
		end
		if input.KeyCode == Enum.KeyCode.LeftAlt or input.KeyCode == Enum.KeyCode.RightAlt then
			altHeld = false
		elseif input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
			shiftHeld = false
		end
	end)
	player.CharacterRemoving:Connect(clearViews)
end

return FirstPerson
