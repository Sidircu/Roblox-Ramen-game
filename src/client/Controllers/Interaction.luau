--!nonstrict
-- What you can use: in first person the object under the crosshair, in third person the one under
-- the mouse or else the nearest one in front of you. It gets an outline and a ProximityPrompt
-- with what pressing does (E, ButtonX or a tap on the prompt; a click or a tap on the object works
-- too). Using sends Interact; the server checks distance, permissions and everything else.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local CollectionService = game:GetService("CollectionService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local NetDef = require(Shared.Net)
local Locale = require(Shared.Locale)
local Format = require(Shared.Util.Format)
local GameConfig = require(Shared.Config.GameConfig)
local Recipes = require(Shared.Config.Recipes)
local Ingredients = require(Shared.Config.Ingredients)
local Items = require(Shared.Config.Items)
local Licenses = require(Shared.Config.Licenses)
local Locks = require(Shared.Logic.Locks)
local Color = require(Shared.Util.Color)
local Core = require(script.Parent.Parent.Core)

local Interaction = {}
local player = Players.LocalPlayer
local t = Locale.t

local highlight, label, labelText
local useGui, useButton, useKey, useText -- our own look for the prompt (see showPrompt)
local handlers = setmetatable({}, { __mode = "k" }) -- [prompt] = { begin, ended }
local current = nil -- { model, uid, kind, slot }
local prompts = setmetatable({}, { __mode = "k" }) -- [model] = ProximityPrompt (local to this client)
local shownPrompt = nil
local act
local lastCheck = 0
local recipeMarks = {}

local function hrp()
	local c = player.Character
	return c and c:FindFirstChild("HumanoidRootPart")
end

local function findTarget(inst)
	local slot = nil
	while inst and inst ~= workspace do
		if inst:GetAttribute("Slot") then
			slot = inst:GetAttribute("Slot")
		end
		if inst:IsA("Model") and inst:GetAttribute("Uid") and CollectionService:HasTag(inst, "Interactable") then
			return inst, slot
		end
		inst = inst.Parent
	end
	return nil
end

local function castAt(screenPos)
	local cam = workspace.CurrentCamera
	local ray = cam:ViewportPointToRay(screenPos.X, screenPos.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ignore = { cam }
	if player.Character then
		table.insert(ignore, player.Character)
	end
	local street = workspace:FindFirstChild("Street")
	if street then
		table.insert(ignore, street)
	end
	params.FilterDescendantsInstances = ignore
	return workspace:Raycast(ray.Origin, ray.Direction * 200, params)
end

local function handsKind()
	local k = player:GetAttribute("HandsKind")
	return (k and k ~= "") and k or nil
end

local function stepName(name)
	return t("step." .. name)
end

-- 🔒 license still needed by a station or the rice cooker (nil when it can be used)
function Interaction.lockOf(model, kind)
	local owned = Core.C.Data and Core.C.Data.w("licenses") or {}
	if kind == "station" then
		local item = Items.byId[model.Name]
		local st = item and item.fn and item.fn.station
		return st and Locks.station(st, owned, Recipes, Licenses) or nil
	elseif kind == "ricecooker" then
		return Locks.rice(owned, Recipes, Licenses)
	end
	return nil
end

-- Text shown above the hovered object
local function actionText(model, kind, slot)
	-- only the restaurant you work in (your own, or one you help in)
	if not Core.C.Data.isMine(model) then
		return nil
	end
	local hands = handsKind()
	local lock = Interaction.lockOf(model, kind)
	if lock then
		return "🔒 " .. t("hint.locked", { name = "lic." .. lock.id, level = lock.level })
	end
	if kind == "box" then
		local g = model:GetAttribute("Ingredient")
		return hands and t("hint.hands_full") or t("hint.take_box", { name = "ing." .. (g or "rice") })
	elseif kind == "shelf" then
		if hands == "box" then
			-- what happens on this very slot (each click fills only the slot you point at)
			local part = slot and model:FindFirstChild("Slot" .. slot)
			if part then
				local g = part:GetAttribute("G") or ""
				local n, cap = part:GetAttribute("N") or 0, part:GetAttribute("Cap") or 0
				if g == "" then
					return t("hint.slot_put")
				end
				local raw = player:GetAttribute("Hands") or "[]"
				local okList, held = pcall(function()
					return game:GetService("HttpService"):JSONDecode(raw)
				end)
				if okList and type(held) == "table" and not table.find(held, g) then
					return t("hint.slot_other", { name = "ing." .. g })
				end
				if n >= cap then
					return t("hint.slot_full")
				end
				return t("hint.slot_add", { name = "ing." .. g, free = cap - n })
			end
			return t("hint.restock")
		end
		-- empty hands: nothing to do here, the stations take the ingredients by themselves
		return nil
	elseif kind == "ricecooker" or kind == "pot" then
		if hands == "box" then
			return t("hint.pour")
		end
		local n, c = model:GetAttribute("N") or 0, model:GetAttribute("C") or 0
		if c > 0 then
			return t("hint.cooking")
		end
		return kind == "ricecooker" and t("hint.rice_status", { n = n }) or t("hint.broth_status", { n = n })
	elseif kind == "station" then
		local ready = model:GetAttribute("Ready") or ""
		if ready ~= "" then
			return t("hint.take_dish", { dish = "rec." .. ready })
		end
		if hands == "ing" then
			return t("hint.put_ingredients")
		elseif hands then
			return t("hint.hands_full")
		end
		local recipe = model:GetAttribute("Recipe") or ""
		if recipe ~= "" then
			if model:GetAttribute("Busy") then
				return t("hint.cooking_now", { dish = "rec." .. recipe })
			end
			local list = string.split(model:GetAttribute("Steps") or "", ",")
			local idx = (model:GetAttribute("Step") or 0) + 1
			return t("act." .. (list[idx] or "combine"), { dish = "rec." .. recipe, i = idx, n = #list })
		end
		-- an empty board: the next press starts the oldest order for this station
		local nextId = model:GetAttribute("Next") or ""
		if nextId ~= "" then
			local missing = model:GetAttribute("Missing") or ""
			if missing ~= "" then
				local icons = {}
				for _, g in ipairs(string.split(missing, ",")) do
					local ing = Ingredients.byId[g]
					table.insert(icons, g == "dishes" and "🍽️" or (ing and ing.icon or g))
				end
				return t("hint.missing_for", { dish = "rec." .. nextId, list = table.concat(icons, " ") })
			end
			local r = Recipes.byId[nextId]
			return t("act." .. (r and r.steps[1] or "combine"), { dish = "rec." .. nextId, i = 1, n = r and #r.steps or 1 })
		end
		return t("hint.no_orders")
	elseif kind == "customer" then
		local state = model:GetAttribute("State")
		local order = model:GetAttribute("Order") or ""
		if state == "order" then
			return t("hint.take_order")
		elseif state == "waiting" then
			return hands == "dish" and t("hint.serve", { dish = "rec." .. order }) or t("hint.waiting_for", { dish = "rec." .. order })
		end
		return t("hint.customer")
	elseif kind == "dirty" then
		return t("hint.collect")
	elseif kind == "sink" then
		if hands == "dirty" then
			return t("hint.sink_drop")
		end
		if model:GetAttribute("Washing") and model:GetAttribute("Washer") == player.UserId then
			return t("hint.washing")
		end
		local pile = Core.C.Data.plotAttr("SinkPile") or 0
		return pile > 0 and t("hint.wash_hold", { n = pile }) or t("hint.sink")
	elseif kind == "dishwasher" then
		return hands == "dirty" and t("hint.load_dishwasher") or t("hint.dishwasher", { n = model:GetAttribute("Queue") or 0 })
	elseif kind == "rack" then
		return hands == "box" and t("hint.put_back") or t("hint.rack")
	elseif kind == "tipjar" then
		local tips = model:GetAttribute("Tips") or 0
		return tips > 0 and t("hint.tipjar", { yen = tips }) or t("hint.tipjar_empty")
	elseif kind == "supplier" then
		return t("hint.supplier")
	elseif kind == "menuboard" then
		return t("hint.menuboard")
	elseif kind == "shopsign" then
		-- the restaurant's sign over the door: its owner (or a co-manager) can change it
		if Core.C.Data.canBuild() and Core.C.Data.isMine(model) then
			return "🏮 " .. t("hint.sign_edit")
		end
		return nil
	elseif kind == "opensign" then
		-- the LED sign by the door: what pressing does now (Plots.setOpen, plot attribute "Open")
		local folder = Core.C.Data.plotFolder(model:GetAttribute("PlotId"))
		local open = not folder or folder:GetAttribute("Open") ~= false
		return open and ("🔴 " .. t("hint.close_shop")) or ("🟢 " .. t("hint.open_shop"))
	elseif kind == "forsale" then
		local id = model:GetAttribute("Expansion") or ""
		local need = model:GetAttribute("Level") or 1
		if (Core.C.Data.w("level") or 1) < need then
			return "🔒 " .. t("zone." .. id) .. " · " .. t("ui.req_level", { level = need })
		end
		return t("hint.buy_room", { name = "zone." .. id, yen = Format.yen(model:GetAttribute("Price") or 0, Locale.get()) })
	end
	return nil
end

local function inRange(model)
	local root = hrp()
	if not root then
		return false
	end
	local pos = model:GetPivot().Position
	local size = model:GetExtentsSize()
	local margin = math.max(size.X, size.Z) / 2
	local flat = (Vector3.new(pos.X, 0, pos.Z) - Vector3.new(root.Position.X, 0, root.Position.Z)).Magnitude
	return flat <= GameConfig.InteractRange + margin - 0.5 and math.abs(pos.Y - root.Position.Y) < 12
end

-- one ProximityPrompt per object, created here on the client and shown only on the target
local function promptFor(model)
	local p = prompts[model]
	if p and p.Parent then
		return p
	end
	local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
	if not part then
		return nil
	end
	p = Instance.new("ProximityPrompt")
	p.Name = "UsePrompt"
	p.RequiresLineOfSight = false
	p.Exclusivity = Enum.ProximityPromptExclusivity.OneGlobally
	p.KeyboardKeyCode = Enum.KeyCode.E
	p.GamepadKeyCode = Enum.KeyCode.ButtonX
	p.HoldDuration = 0
	p.MaxActivationDistance = 40
	p.Enabled = false
	-- Roblox's prompt bubble cannot be made bigger: ours is drawn instead (useGui), the prompt
	-- still takes E and ButtonX
	p.Style = Enum.ProximityPromptStyle.Custom
	local pressedAt = 0
	local function begin()
		pressedAt = os.clock()
		if current and current.model == model then
			-- on a touch screen a tap on the prompt is a tap (it toggles washing)
			act(UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled)
		end
	end
	-- releasing the button stops washing at the sink; a quick tap on a touch screen leaves the
	-- tap running (washing goes on by itself until the sink is empty or you tap again)
	local function ended()
		local touch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
		if Core.C.Sink and not (touch and os.clock() - pressedAt < 0.35) then
			Core.C.Sink.endHold()
		end
	end
	p.Triggered:Connect(begin)
	p.TriggerEnded:Connect(ended)
	handlers[p] = { begin = begin, ended = ended }
	p.Parent = part
	prompts[model] = p
	return p
end

-- the button over the object: big and tappable on touch screens, with the key to press (E, or X
-- on a gamepad) on a computer
local function paintUseButton(p, text)
	if not useGui then
		return
	end
	if not p then
		useGui.Enabled = false
		useGui.Adornee = nil
		return
	end
	local mode = Core.C.UI and Core.C.UI.inputMode and Core.C.UI.inputMode() or "pc"
	local touch = mode == "touch"
	useGui.Size = touch and UDim2.fromOffset(230, 72) or UDim2.fromOffset(220, 50)
	useKey.Visible = not touch
	useKey.Text = mode == "pad" and "X" or "E"
	useText.Position = touch and UDim2.fromOffset(12, 0) or UDim2.fromOffset(48, 0)
	useText.Size = touch and UDim2.new(1, -24, 1, 0) or UDim2.new(1, -58, 1, 0)
	useText.Text = text
	useGui.Adornee = p.Parent
	useGui.Enabled = true
end

local function showPrompt(model, text, near)
	local p = (model and text and near) and promptFor(model) or nil
	if shownPrompt and shownPrompt ~= p and shownPrompt.Parent then
		shownPrompt.Enabled = false
	end
	shownPrompt = p
	if p then
		if p.ActionText ~= text then
			p.ActionText = text
		end
		p.Enabled = true
	end
	paintUseButton(p, text)
end

local function setCurrent(model, slot)
	if not model then
		current = nil
		highlight.Adornee = nil
		highlight.Enabled = false
		label.Enabled = false
		showPrompt(nil)
		return
	end
	local kind = model:GetAttribute("Kind")
	local text = actionText(model, kind, slot)
	if not text then
		setCurrent(nil)
		return
	end
	local near = inRange(model)
	current = { model = model, uid = model:GetAttribute("Uid"), kind = kind, slot = slot, near = near, text = text }
	highlight.Adornee = model
	highlight.Enabled = true
	highlight.OutlineColor = near and Color.hex("#FFD23B") or Color.hex("#B8AFA2")
	-- close enough: the prompt says what pressing does; too far: a small "get closer" label
	-- (in first person it is written under the crosshair, see Controllers/FirstPerson)
	showPrompt(model, text, near)
	local fp = Core.C.Camera and Core.C.Camera.isFirstPerson and Core.C.Camera.isFirstPerson()
	label.Adornee = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
	label.Enabled = not fp and not near
	labelText.Text = "🚶 " .. t("hint.get_closer")
end

-- third person without a mouse target: the nearest usable object in front of you
local function proximityTarget()
	local root = hrp()
	if not root then
		return nil
	end
	local look = root.CFrame.LookVector
	local flatLook = Vector3.new(look.X, 0, look.Z)
	flatLook = flatLook.Magnitude > 0 and flatLook.Unit or Vector3.new(0, 0, -1)
	local best, bestScore = nil, math.huge
	for _, model in ipairs(CollectionService:GetTagged("Interactable")) do
		local pp = model.PrimaryPart
		if pp and model:IsDescendantOf(workspace) then
			local off = pp.Position - root.Position
			local flat = Vector3.new(off.X, 0, off.Z)
			local dist = flat.Magnitude
			local size = pp.Size
			if dist <= GameConfig.InteractRange + math.max(size.X, size.Z) / 2 and math.abs(off.Y) < 10 then
				local facing = dist > 0.5 and flat.Unit:Dot(flatLook) or 1
				local score = dist - facing * 5
				if score < bestScore and actionText(model, model:GetAttribute("Kind"), nil) then
					best, bestScore = model, score
				end
			end
		end
	end
	return best
end

-- What the player points at: { text, near, kind } or nil
function Interaction.target()
	if not current then
		return nil
	end
	return { text = current.text, near = current.near, kind = current.kind }
end

local function update(screenPos)
	if Core.C.Build and Core.C.Build.active then
		setCurrent(nil)
		return
	end
	local hit = castAt(screenPos)
	if not hit then
		setCurrent(nil)
		return
	end
	local model, slot = findTarget(hit.Instance)
	setCurrent(model, slot)
end

-- washing is held: true when this click starts (or a tap toggles) washing at the sink
local function washHold(tap)
	if current.kind ~= "sink" or handsKind() ~= nil or (Core.C.Data.plotAttr("SinkPile") or 0) <= 0 then
		return false
	end
	local Sink = Core.C.Sink
	if not Sink then
		return false
	end
	if tap then
		Sink.toggle(current.uid)
	else
		Sink.beginHold(current.uid)
	end
	return true
end

act = function(tap)
	-- while the noodles boil, the click stops the timing needle
	local Timing = Core.C.Timing
	if Timing and Timing.active() then
		Timing.hit()
		return
	end
	if not current then
		return
	end
	if not current.near then
		Core.C.UI.toast(t("msg.too_far"), "info")
		return
	end
	if washHold(tap) then
		return
	end
	if current.kind == "supplier" then
		Core.C.UI.open("Supplier")
		return
	elseif current.kind == "forsale" then
		-- one press buys the room (the server checks level, rooms before it and the price)
		if not Core.C.Data.canBuild() then
			Core.C.UI.toast(t("ui.only_owner"), "warning")
			return
		end
		local price = current.model:GetAttribute("Price") or 0
		if Core.C.Data.wallet() < price then
			Core.C.UI.toast(t("ui.missing", { yen = Format.yen(price - Core.C.Data.wallet(), Locale.get()) }), "warning")
			return
		end
		NetDef.event("BuyExpansion"):FireServer(current.model:GetAttribute("Expansion"))
		return
	elseif current.kind == "menuboard" then
		Core.C.UI.open("Menu")
		return
	elseif current.kind == "shopsign" then
		Core.C.UI.open("Sign")
		return
	elseif current.kind == "opensign" then
		-- opens or closes the restaurant (the server checks who you are and that you are near)
		if not Core.C.Data.canBuild() then
			Core.C.UI.toast(t("ui.only_owner"), "warning")
			return
		end
		NetDef.event("ToggleOpen"):FireServer()
		return
	end
	NetDef.event("Interact"):FireServer(current.uid, { slot = current.slot })
end

-- Briefly marks the shelves/station needed for a recipe (clicked ticket)
function Interaction.highlightRecipe(recipeId)
	for _, m in ipairs(recipeMarks) do
		m:Destroy()
	end
	recipeMarks = {}
	local r = Recipes.byId[recipeId]
	if not r then
		return
	end
	local need = {}
	for _, g in ipairs(r.ing) do
		need[g] = true
	end
	for _, model in ipairs(CollectionService:GetTagged("Interactable")) do
		local kind = model:GetAttribute("Kind")
		if kind == "shelf" then
			for _, part in ipairs(model:GetChildren()) do
				if part:IsA("BasePart") and part:GetAttribute("Slot") and need[part:GetAttribute("G") or ""] then
					local box = Instance.new("SelectionBox")
					box.Adornee = part
					box.Color3 = Color.hex("#FFD23B")
					box.LineThickness = 0.08
					box.Parent = player.PlayerGui
					table.insert(recipeMarks, box)
				end
			end
		elseif kind == "station" and model.PrimaryPart then
			local stationId = string.gsub(model.Name, "_station", "")
			if stationId == r.station or (model.Name == "griddle" and r.station == "griddle") or (model.Name == "fryer" and r.station == "fryer") or (model.Name == "takoyaki_stove" and r.station == "takoyaki") then
				local box = Instance.new("SelectionBox")
				box.Adornee = model.PrimaryPart
				box.Color3 = Color.hex("#6DDC5A")
				box.LineThickness = 0.1
				box.Parent = player.PlayerGui
				table.insert(recipeMarks, box)
			end
		end
	end
	local missing = {}
	for g in pairs(need) do
		local found = false
		for _, m in ipairs(recipeMarks) do
			if m.Adornee and m.Adornee:GetAttribute("G") == g then
				found = true
			end
		end
		if not found then
			table.insert(missing, (Ingredients.byId[g] and Ingredients.byId[g].icon or "") .. " " .. t("ing." .. g))
		end
	end
	local msg = t("hint.recipe_needs", { dish = "rec." .. recipeId })
	if #missing > 0 then
		msg ..= "  " .. t("hint.missing") .. ": " .. table.concat(missing, ", ")
	end
	Core.C.UI.toast(msg, #missing > 0 and "warning" or "info")
	task.delay(8, function()
		for _, m in ipairs(recipeMarks) do
			m:Destroy()
		end
		recipeMarks = {}
	end)
end

function Interaction.Init()
	highlight = Instance.new("Highlight")
	highlight.FillTransparency = 1
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Enabled = false
	highlight.Parent = player:WaitForChild("PlayerGui")
	label = Instance.new("BillboardGui")
	label.Size = UDim2.fromOffset(260, 46)
	label.StudsOffsetWorldSpace = Vector3.new(0, 3.2, 0)
	label.AlwaysOnTop = true
	label.LightInfluence = 0
	label.Enabled = false
	label.Parent = player.PlayerGui
	local bg = Instance.new("Frame")
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = Color.hex("#2B2320")
	bg.BackgroundTransparency = 0.15
	bg.Parent = label
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = bg
	labelText = Instance.new("TextLabel")
	labelText.Size = UDim2.new(1, -12, 1, -6)
	labelText.Position = UDim2.fromOffset(6, 3)
	labelText.BackgroundTransparency = 1
	labelText.TextColor3 = Color.hex("#F4EBDD")
	labelText.TextScaled = true
	labelText.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold)
	labelText.AutoLocalize = false
	labelText.Parent = bg
	-- the use button over the object (instead of Roblox's prompt bubble)
	useGui = Instance.new("BillboardGui")
	useGui.Name = "UseButton"
	useGui.Size = UDim2.fromOffset(220, 50)
	useGui.ExtentsOffsetWorldSpace = Vector3.new(0, 1, 0)
	useGui.AlwaysOnTop = true
	useGui.LightInfluence = 0
	useGui.MaxDistance = 60
	useGui.Active = true
	useGui.ResetOnSpawn = false
	useGui.Enabled = false
	useGui.Parent = player.PlayerGui
	useButton = Instance.new("TextButton")
	useButton.Name = "Use"
	useButton.Text = ""
	useButton.AutoButtonColor = true
	useButton.Size = UDim2.fromScale(1, 1)
	useButton.BackgroundColor3 = Color.hex("#3A2618")
	useButton.BackgroundTransparency = 0.08
	useButton.Parent = useGui
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0, 14)
	round.Parent = useButton
	local rim = Instance.new("UIStroke")
	rim.Color = Color.hex("#D4A23C")
	rim.Thickness = 2
	rim.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	rim.Parent = useButton
	useKey = Instance.new("TextLabel")
	useKey.Name = "Key"
	useKey.Size = UDim2.fromOffset(32, 32)
	useKey.AnchorPoint = Vector2.new(0, 0.5)
	useKey.Position = UDim2.new(0, 9, 0.5, 0)
	useKey.BackgroundColor3 = Color.hex("#F4EBDD")
	useKey.TextColor3 = Color.hex("#2B2320")
	useKey.TextSize = 20
	useKey.FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json")
	useKey.AutoLocalize = false
	useKey.Parent = useButton
	local keyRound = Instance.new("UICorner")
	keyRound.CornerRadius = UDim.new(0, 8)
	keyRound.Parent = useKey
	useText = Instance.new("TextLabel")
	useText.Name = "Action"
	useText.BackgroundTransparency = 1
	useText.TextColor3 = Color.hex("#FFF6E8")
	useText.TextScaled = true
	useText.TextXAlignment = Enum.TextXAlignment.Left
	useText.FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json")
	useText.AutoLocalize = false
	useText.Parent = useButton
	local fit = Instance.new("UITextSizeConstraint")
	fit.MaxTextSize = 22
	fit.MinTextSize = 12
	fit.Parent = useText
	-- pressing the button is the same as pressing E (holding it holds, for the sink)
	useButton.MouseButton1Down:Connect(function()
		local h = shownPrompt and handlers[shownPrompt]
		if h then
			h.begin()
		end
	end)
	useButton.MouseButton1Up:Connect(function()
		local h = shownPrompt and handlers[shownPrompt]
		if h then
			h.ended()
		end
	end)
end

Interaction.act = act

local function aimingCenter()
	local Camera = Core.C.Camera
	local fp = Core.C.FirstPerson
	return Camera and Camera.isFirstPerson and Camera.isFirstPerson() and not (fp and fp.cursorFree and fp.cursorFree())
end

function Interaction.Start()
	RunService.RenderStepped:Connect(function()
		if os.clock() - lastCheck < 0.05 then
			return
		end
		lastCheck = os.clock()
		if Core.C.Build and Core.C.Build.active then
			setCurrent(nil)
		elseif aimingCenter() then
			-- first person: whatever is under the crosshair (mouse, touch and gamepad alike)
			local cam = workspace.CurrentCamera
			update(cam.ViewportSize / 2)
		else
			-- third person: the object under the mouse, else the nearest one in front of you
			local hovered = nil
			if UserInputService.MouseEnabled then
				local hit = castAt(UserInputService:GetMouseLocation())
				hovered = hit and findTarget(hit.Instance) or nil
			end
			if hovered then
				update(UserInputService:GetMouseLocation())
			else
				setCurrent(proximityTarget(), nil)
			end
		end
	end)
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or (Core.C.Build and Core.C.Build.active) then
			return
		end
		-- E and ButtonX go through the prompt; a click works on the object you point at
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			act()
		end
	end)
	-- releasing the click stops washing (the prompt handles E)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 and Core.C.Sink then
			Core.C.Sink.endHold()
		end
	end)
	UserInputService.TouchTap:Connect(function(positions, processed)
		if processed or (Core.C.Build and Core.C.Build.active) then
			return
		end
		local p = positions[1]
		if p then
			local viewport = Vector2.new(p.X, p.Y + GuiService:GetGuiInset().Y)
			update(viewport)
			act(true)
		end
	end)
end

return Interaction
