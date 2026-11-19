--!nonstrict
-- Guided first day: step panel, arrow beam to the target and a floating marker.
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local NetDef = require(Shared.Net)
local Locale = require(Shared.Locale)
local Color = require(Shared.Util.Color)
local Kit = require(script.Parent.Parent.UI.Kit)
local Core = require(script.Parent.Parent.Core)

local Tutorial = {}
local player = Players.LocalPlayer
local t = Locale.t
local T = Kit.Theme

-- The first minutes, one short step at a time: a customer orders by themselves, the ramen station
-- makes it in three presses (noodles, broth, toppings), you serve it and get paid, then you clear
-- and wash the dish. target = what the arrow points at (a kind, or a function returning kind and a
-- filter); done = an action sent by the server after an interaction, or a check, or a timer.

-- the station that has the order: cooking it, ready with it, or about to start it
local function orderStation()
	local best = nil
	for _, m in ipairs(CollectionService:GetTagged("Interactable")) do
		if m:GetAttribute("Kind") == "station" and m:IsDescendantOf(workspace) then
			if (m:GetAttribute("Ready") or "") ~= "" or (m:GetAttribute("Recipe") or "") ~= "" then
				return m
			end
			if (m:GetAttribute("Next") or "") ~= "" then
				best = best or m
			end
		end
	end
	return best
end

local function stationStep()
	local m = orderStation()
	if not m then
		return 0, false
	end
	if (m:GetAttribute("Ready") or "") ~= "" then
		return 99, true
	end
	if (m:GetAttribute("Recipe") or "") == "" then
		return 0, false
	end
	return m:GetAttribute("Step") or 0, false
end

local function anyTicket()
	return #(Core.C.Data.tickets or {}) > 0
end

local STEPS = {
	{ key = "tut.welcome", timer = 6 },
	{ key = "tut.order", target = "customer", check = anyTicket },
	{ key = "tut.noodles", target = "orderStation", check = function()
		local step, ready = stationStep()
		return step >= 1 or ready
	end },
	{ key = "tut.broth", target = "orderStation", check = function()
		local step, ready = stationStep()
		return step >= 2 or ready
	end },
	{ key = "tut.toppings", target = "orderStation", check = function()
		local _, ready = stationStep()
		return ready or player:GetAttribute("HandsKind") == "dish"
	end },
	{ key = "tut.take_dish", target = "orderStation", check = function()
		return player:GetAttribute("HandsKind") == "dish"
	end },
	{ key = "tut.serve", target = "customer", check = function()
		local s = Core.C.Data.w("stats")
		return s and (s.dishes or 0) > (Tutorial.dishesAtStart or 0)
	end },
	{ key = "tut.collect", target = "dirty", action = "collect" },
	{ key = "tut.wash", target = "sink", action = "wash" },
	{ key = "tut.done", timer = 8 },
}

local panel, text, stepLabel, beam, a0, a1, marker
local index = 0
local stepStarted = 0

local function save()
	NetDef.event("TutorialStep"):FireServer(index)
end

local function findTarget(target)
	local kind, filter = target, nil
	if target == "orderStation" then
		return orderStation()
	end
	if type(target) == "function" then
		kind, filter = target()
	end
	if not kind then
		return nil
	end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local best, bestD = nil, math.huge
	for _, m in ipairs(CollectionService:GetTagged("Interactable")) do
		if m:GetAttribute("Kind") == kind and m:IsDescendantOf(workspace) then
			local ok = true
			if filter and kind == "box" then
				ok = filter[m:GetAttribute("Ingredient") or ""] == true
			end
			if kind == "customer" then
				ok = m:GetAttribute("State") == "order" or m:GetAttribute("State") == "waiting"
			end
			if kind == "station" then
				-- the ramen station while the first day is ramen only
				ok = m.Name ~= "sushi_station"
			end
			if ok then
				local d = root and (m:GetPivot().Position - root.Position).Magnitude or 0
				if d < bestD then
					best, bestD = m, d
				end
			end
		end
	end
	return best
end

-- key of the step on screen (the supplier highlights its menu button during "tut.buy")
function Tutorial.currentKey()
	local st = STEPS[index]
	return st and st.key or nil
end

local function show()
	local st = STEPS[index]
	if not st then
		panel.Visible = false
		beam.Enabled = false
		marker.Enabled = false
		return
	end
	panel.Visible = true
	stepLabel.Text = t("tut.step", { i = index, n = #STEPS })
	text.Text = t(st.key)
	stepStarted = os.clock()
end

local function advance()
	index += 1
	if index > #STEPS then
		index = -1
		save()
		panel.Visible = false
		beam.Enabled = false
		marker.Enabled = false
		return
	end
	if STEPS[index].key == "tut.serve" or STEPS[index].key == "tut.order" then
		local s = Core.C.Data.w("stats")
		Tutorial.dishesAtStart = s and s.dishes or 0
	end
	save()
	show()
end

function Tutorial.onAction(kind, hands)
	local st = STEPS[index]
	if not st or not st.action then
		return
	end
	if st.action ~= kind then
		return
	end
	if st.hands == "ing" and hands ~= "ing" then
		return
	end
	advance()
end

function Tutorial.restart()
	index = 1
	show()
end

function Tutorial.Init()
	local gui = Core.C.UI.root()
	-- big card on the right (the left side holds the orders and their guide)
	panel = Kit.panel({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 84), Size = UDim2.fromOffset(340, 168), Visible = false, Parent = gui })
	local stroke = panel:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Color = T.gold
		stroke.Thickness = 4
	end
	Kit.padding(12, 10).Parent = panel
	stepLabel = Kit.label("", { Parent = panel, Size = UDim2.new(1, 0, 0, 20), TextSize = 14, TextColor3 = T.muted, FontFace = T.bold })
	text = Kit.label("", { Parent = panel, Position = UDim2.fromOffset(0, 22), Size = UDim2.new(1, 0, 1, -62), TextSize = 17, TextYAlignment = Enum.TextYAlignment.Top })
	Kit.button(t("ui.skip"), { parent = panel, size = UDim2.fromOffset(90, 30), position = UDim2.new(1, -90, 1, -32), style = "plain", textSize = 14, onClick = function()
		index = -1
		save()
		panel.Visible = false
		beam.Enabled = false
		marker.Enabled = false
	end })
	Kit.button(t("ui.next"), { parent = panel, size = UDim2.fromOffset(90, 30), position = UDim2.new(1, -186, 1, -32), style = "gold", textSize = 14, onClick = function()
		-- steps that ask for an action move on by themselves when it is done
		local st = STEPS[index]
		if st and st.timer then
			advance()
		end
	end })
	-- in first person the mouse is captured: Enter also goes to the next card
	game:GetService("UserInputService").InputBegan:Connect(function(input, processed)
		if not processed and panel.Visible and (input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.KeypadEnter) then
			local st = STEPS[index]
			if st and st.timer then
				advance()
			end
		end
	end)
	a0 = Instance.new("Attachment")
	a1 = Instance.new("Attachment")
	beam = Instance.new("Beam")
	beam.Attachment0 = a0
	beam.Attachment1 = a1
	beam.Width0 = 0.6
	beam.Width1 = 0.6
	beam.FaceCamera = true
	beam.Color = ColorSequence.new(Color.hex("#FFD23B"))
	beam.LightEmission = 1
	beam.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	beam.TextureMode = Enum.TextureMode.Wrap
	beam.TextureSpeed = 2
	beam.Enabled = false
	marker = Instance.new("BillboardGui")
	marker.Size = UDim2.fromOffset(60, 60)
	marker.StudsOffsetWorldSpace = Vector3.new(0, 5, 0)
	marker.AlwaysOnTop = true
	marker.Enabled = false
	marker.Parent = player.PlayerGui
	local arrow = Instance.new("TextLabel")
	arrow.Size = UDim2.fromScale(1, 1)
	arrow.BackgroundTransparency = 1
	arrow.Text = "⬇️"
	arrow.TextScaled = true
	arrow.AutoLocalize = false
	arrow.Parent = marker
end

function Tutorial.Start()
	local Data = Core.C.Data
	if not Data.ready then
		Data.Ready:Wait()
	end
	local meta = Data.m("meta")
	index = meta and meta.tutorial or 0
	if index == 0 then
		index = 1
	end
	if index > 0 and Data.role() == "owner" then
		show()
	else
		index = -1
	end
	local holder = Instance.new("Part")
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanQuery = false
	holder.Transparency = 1
	holder.Size = Vector3.new(0.2, 0.2, 0.2)
	holder.Parent = workspace.CurrentCamera
	a1.Parent = holder
	-- offline earnings popup
	if meta and (meta.offlinePending or 0) > 0 then
		Core.C.UI.open("Offline")
	end
	while true do
		task.wait(0.25)
		local st = STEPS[index]
		if st then
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if root and a0.Parent ~= root then
				a0.Parent = root
			end
			local guide = Core.C.UI.screens.Guide
			local target = st.target and findTarget(st.target)
			if guide and guide.visible() then
				target = nil
			end
			if target then
				holder.Position = target:GetPivot().Position + Vector3.new(0, 2, 0)
				marker.Adornee = holder
				beam.Parent = holder
				beam.Enabled = true
				marker.Enabled = true
			else
				beam.Enabled = false
				marker.Enabled = false
			end
			if st.check and st.check() then
				advance()
			elseif st.timer and os.clock() - stepStarted > st.timer then
				advance()
			end
		end
	end
end

return Tutorial
