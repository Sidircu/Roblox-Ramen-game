--!nonstrict
-- The first two minutes, one short step at a time: a customer orders by themselves, the ramen
-- station makes it in three presses (noodles, broth, toppings), you serve it and get paid; a gift
-- of yen opens the shop and you buy your first upgrade; then you clear and wash the bowl, and a
-- last gift of sakura closes the tutorial. A banner at the top says what to do (with dots for the
-- steps and a skip button), a glowing beam and a bouncing arrow show where (on things in the world
-- and on buttons of the interface). Steps that ask for an action move on by themselves. It runs
-- once for the owner of a new restaurant (meta.tutorial: step, -1 when finished or skipped) and
-- can be started again from More -> How to play; the gifts are given by the server, once, and
-- only after a dish was really served / washed (Services/Meta, Config/Tutorial).
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local NetDef = require(Shared.Net)
local Locale = require(Shared.Locale)
local Format = require(Shared.Util.Format)
local TutorialCfg = require(Shared.Config.Tutorial)
local DailyRewards = require(Shared.Config.DailyRewards)
local Kit = require(script.Parent.Parent.UI.Kit)
local Pointer = require(script.Parent.Parent.UI.Pointer)
local Core = require(script.Parent.Parent.Core)

local Tutorial = {}
local player = Players.LocalPlayer
local t = Locale.t
local T = Kit.Theme

------------------------------------------------------------------ what the steps look at
-- the station that has the order: cooking it, ready with it, or about to start it
local function orderStation()
	local best = nil
	for _, m in ipairs(CollectionService:GetTagged("Interactable")) do
		if m:GetAttribute("Kind") == "station" and m:IsDescendantOf(workspace) and Core.C.Data.isMine(m) then
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

-- presses done on the order's station (99 = ready)
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

local function holdingDish()
	return player:GetAttribute("HandsKind") == "dish"
end

local function anyTicket()
	return #(Core.C.Data.tickets or {}) > 0
end

local function stat(name)
	local s = Core.C.Data.w("stats")
	return s and s[name] or 0
end

-- everything bought so far (upgrade levels, recipes, rooms, staff)
local function purchases()
	local w = Core.C.Data.restaurant()
	local n = #(w.staff or {})
	for _, lvl in pairs(w.upgrades or {}) do
		n += lvl
	end
	for _ in pairs(w.licenses or {}) do
		n += 1
	end
	for _ in pairs(w.zones or {}) do
		n += 1
	end
	return n
end

-- the nearest thing of a kind in your restaurant (customers: only the ones waiting for food)
local function nearestOf(kind)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local best, bestD = nil, math.huge
	for _, m in ipairs(CollectionService:GetTagged("Interactable")) do
		if m:GetAttribute("Kind") == kind and m:IsDescendantOf(workspace) and Core.C.Data.isMine(m) then
			local ok = true
			if kind == "customer" then
				ok = m:GetAttribute("State") == "order" or m:GetAttribute("State") == "waiting"
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

-- buttons of the interface the steps point at
local function dockButton(id)
	local hud = Core.C.UI.root():FindFirstChild("HUD")
	local dock = hud and hud:FindFirstChild("Dock")
	return dock and dock:FindFirstChild(id) or nil
end

local function greenCard()
	local shop = Core.C.UI.screens.Shop
	if not (shop and shop.win and shop.win.frame.Visible) then
		return nil
	end
	for _, d in ipairs(shop.win.content:GetDescendants()) do
		if d.Name == "Buy" and d:IsA("TextButton") and d.BackgroundColor3 == T.green then
			return d
		end
	end
	return nil
end

------------------------------------------------------------------ the steps
-- key: text; icon: emoji on the banner; world: what the beam points at; gui: the button the hand
-- points at; check(state): true when done (state = stats when the step started); action: done
-- when the server reports this action; timer: seconds on screen; reward: gift asked to the server
-- when the step starts; progress: text added to the banner; skippable: shows the ▶ button
local STEPS = {
	{ id = "welcome", icon = "🏮", key = "tut.welcome", timer = 4 },
	{ id = "order", icon = "🧑", key = "tut.order", world = function()
		return nearestOf("customer")
	end, check = anyTicket },
	{ id = "cook", icon = "🍜", key = "tut.cook", world = orderStation, check = function()
		local _, ready = stationStep()
		return ready or holdingDish()
	end, progress = function()
		local step = stationStep()
		return math.min(step, 3) .. "/3"
	end },
	{ id = "take", icon = "🥢", key = "tut.take_dish", world = orderStation, check = holdingDish },
	{ id = "serve", icon = "💴", key = "tut.serve", world = function()
		return nearestOf("customer")
	end, check = function(st)
		return stat("dishes") > (st.dishes or 0)
	end },
	{ id = "reward", icon = "🎁", key = "tut.reward", reward = "serve", gui = function()
		return dockButton("Shop")
	end, check = function()
		return Core.C.UI.current == "Shop"
	end },
	{ id = "buy", icon = "🛒", key = "tut.buy", gui = function()
		return greenCard() or (Core.C.UI.current ~= "Shop" and dockButton("Shop") or nil)
	end, check = function(st)
		return purchases() > (st.purchases or 0)
	end, skippable = true },
	{ id = "collect", icon = "🥣", key = "tut.collect", world = function()
		return nearestOf("dirty")
	end, action = "collect", check = function()
		return player:GetAttribute("HandsKind") == "dirty"
	end },
	{ id = "wash", icon = "🧽", key = "tut.wash", world = function()
		return nearestOf("sink")
	end, action = "wash", check = function(st)
		return stat("washed") > (st.washed or 0)
	end },
	{ id = "done", icon = "🎉", key = "tut.done", reward = "done", timer = 6 },
}
Tutorial.STEPS = STEPS

local panel, iconLabel, text, dots, skipButton, nextButton
local pointer
local index = 0
local stepState = {}
local stepStarted = 0

local function save()
	NetDef.event("TutorialStep"):FireServer(index)
end

-- id of the step on screen (nil when the tutorial is not running)
function Tutorial.currentId()
	local st = STEPS[index]
	return (st and panel and panel.Visible) and st.id or nil
end

function Tutorial.currentKey()
	local st = STEPS[index]
	return st and st.key or nil
end

-- true while a step is on screen (the HUD hides today's objective, the tips wait)
function Tutorial.active()
	return panel ~= nil and panel.Visible
end

local function stepText(st)
	local params = { yen = Format.yen(TutorialCfg.ServeYen, Locale.get()), n = TutorialCfg.DoneSakura }
	local s = t(st.key, params)
	if st.progress then
		s ..= "  (" .. st.progress() .. ")"
	end
	return s
end

local function paintDots()
	local parts = {}
	for i = 1, #STEPS do
		table.insert(parts, i < index and "●" or (i == index and "◉" or "○"))
	end
	dots.Text = table.concat(parts, " ")
end

local function hide()
	if panel then
		panel.Visible = false
	end
	if pointer then
		pointer:hide()
	end
end

local function show()
	local st = STEPS[index]
	if not st then
		hide()
		return
	end
	panel.Visible = true
	panel.Size = UDim2.fromOffset(Kit.profile == "phone" and 390 or 460, 76)
	iconLabel.Text = st.icon
	text.Text = stepText(st)
	nextButton.Visible = st.skippable == true or st.timer ~= nil
	paintDots()
	stepStarted = os.clock()
	stepState = { dishes = stat("dishes"), washed = stat("washed"), purchases = purchases() }
	if st.reward then
		NetDef.event("TutorialReward"):FireServer(st.reward)
	end
	Kit.popIn(panel, 0.9)
	if Core.C.Audio then
		Core.C.Audio.play("pop")
	end
end

-- the daily gift calendar (Screens/Daily) opens by itself once per session, when today's gift is
-- still there, the tutorial is not on screen and no other window is open
local dailyOffered = false
local function offerDaily(delay)
	if dailyOffered then
		return
	end
	dailyOffered = true
	task.spawn(function()
		task.wait(delay or 0)
		local UI = Core.C.UI
		local waited = 0
		while waited < DailyRewards.PopupWait do
			local screen = UI.screens.Daily
			if not screen or not screen.ready() then
				return
			end
			if UI.current == nil and index == -1 then
				UI.open("Daily")
				return
			end
			task.wait(0.5)
			waited = waited + 0.5
		end
	end)
end

local function finish(skipped)
	index = -1
	save()
	hide()
	if skipped then
		Core.C.UI.toast(t("tut.skipped"), "info")
	end
	offerDaily(DailyRewards.PopupAfterTutorial)
end

local function advance()
	index += 1
	if index > #STEPS then
		finish(false)
		return
	end
	save()
	show()
end

function Tutorial.onAction(kind)
	local st = STEPS[index]
	if st and st.action and st.action == kind then
		advance()
	end
end

function Tutorial.restart()
	index = 1
	save()
	show()
end

function Tutorial.Init()
	local gui = Core.C.UI.root()
	-- banner at the top in the middle, where today's objective is shown after the tutorial
	panel = Kit.panel({ Name = "Tutorial", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 50), Size = UDim2.fromOffset(460, 76), Visible = false, ZIndex = 7, Parent = gui })
	local stroke = panel:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Color = T.gold
		stroke.Thickness = 4
	end
	local tile = Kit.new("Frame", { Position = UDim2.fromOffset(10, 10), Size = UDim2.fromOffset(56, 56), BackgroundColor3 = Color3.fromRGB(255, 236, 196), Parent = panel }, { Kit.corner(28) })
	iconLabel = Kit.label("", { Parent = tile, Position = UDim2.fromOffset(8, 8), Size = UDim2.new(1, -16, 1, -16), TextScaled = true, TextXAlignment = Enum.TextXAlignment.Center })
	text = Kit.label("", { Parent = panel, Position = UDim2.fromOffset(76, 6), Size = UDim2.new(1, -164, 0, 44), TextSize = 17, FontFace = T.bold, TextYAlignment = Enum.TextYAlignment.Center })
	dots = Kit.label("", { Parent = panel, Position = UDim2.fromOffset(76, 50), Size = UDim2.new(1, -164, 0, 18), TextSize = 12, TextColor3 = T.gold, FontFace = T.bold, TextWrapped = false })
	local buttons = Kit.new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(76, 66), Parent = panel }, { Kit.list(Enum.FillDirection.Vertical, 4, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center) })
	nextButton = Kit.button("▶", { parent = buttons, size = UDim2.fromOffset(76, 30), style = "gold", textSize = 15, order = 1, onClick = function()
		local st = STEPS[index]
		if st and (st.timer or st.skippable) then
			advance()
		end
	end })
	skipButton = Kit.button(t("ui.skip"), { parent = buttons, size = UDim2.fromOffset(76, 30), style = "plain", textSize = 14, order = 2, onClick = function()
		finish(true)
	end })
	skipButton.Name = "Skip"
	-- in first person the mouse is captured: Enter also moves on from a timed card
	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and panel.Visible and (input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.KeypadEnter) then
			local st = STEPS[index]
			if st and (st.timer or st.skippable) then
				advance()
			end
		end
	end)
	Locale.Changed:Connect(function()
		skipButton.Text = t("ui.skip")
		local st = STEPS[index]
		if st and panel.Visible then
			text.Text = stepText(st)
		end
	end)
	pointer = Pointer.new("#FFD23B")
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
	skipButton.Text = t("ui.skip")
	if index > 0 and index <= #STEPS and Data.role() == "owner" then
		show()
	else
		index = -1
	end
	-- offline earnings popup, then today's gift (after the offline one is closed)
	if meta and (meta.offlinePending or 0) > 0 then
		Core.C.UI.open("Offline")
	end
	if index == -1 then
		offerDaily(1)
	end
	while true do
		task.wait(0.25)
		local st = STEPS[index]
		if st and panel.Visible then
			-- the order guide has its own arrow
			local guide = Core.C.UI.screens.Guide
			local busy = guide and guide.visible and guide.visible()
			local w = (not busy and st.world) and st.world() or nil
			local g = st.gui and st.gui() or nil
			if g then
				pointer:gui(g)
			elseif w then
				pointer:world(w)
			else
				pointer:hide()
			end
			if st.progress then
				text.Text = stepText(st)
			end
			if st.check and st.check(stepState) then
				advance()
			elseif st.timer and os.clock() - stepStarted > st.timer then
				advance()
			end
		end
	end
end

return Tutorial
