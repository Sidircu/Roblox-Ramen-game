--!nonstrict
-- Hover highlight + action label on nearby interactables; click / tap / E sends Interact.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local CollectionService = game:GetService("CollectionService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local NetDef = require(Shared.Net)
local Locale = require(Shared.Locale)
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
local current = nil -- { model, uid, kind, slot }
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
			return t("hint.restock")
		end
		local part = slot and model:FindFirstChild("Slot" .. slot)
		local g = part and part:GetAttribute("G") or ""
		if g ~= "" then
			return t("hint.take_ing", { name = "ing." .. g, n = part:GetAttribute("N") or 0 })
		end
		return t("hint.shelf_empty")
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
		end
		local recipe = model:GetAttribute("Recipe") or ""
		local steps = model:GetAttribute("Steps") or ""
		if recipe ~= "" then
			local list = string.split(steps, ",")
			local idx = (model:GetAttribute("Step") or 0) + 1
			return t("hint.do_step", { step = "step." .. (list[idx] or "combine"), dish = "rec." .. recipe, i = idx, n = #list })
		end
		local need = model:GetAttribute("Need") or ""
		if need ~= "" then
			local icons = {}
			for _, g in ipairs(string.split(need, ",")) do
				local ing = Ingredients.byId[g]
				table.insert(icons, ing and ing.icon or g)
			end
			return t("hint.board_need", { list = table.concat(icons, " ") })
		end
		if (model:GetAttribute("Board") or "") ~= "" then
			return t("hint.board_incomplete")
		end
		return t("hint.station")
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
		local pile = workspace:GetAttribute("SinkPile") or 0
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

local function setCurrent(model, slot)
	if not model then
		current = nil
		highlight.Adornee = nil
		highlight.Enabled = false
		label.Enabled = false
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
	-- in first person the action is written under the crosshair (Controllers/FirstPerson)
	local fp = Core.C.Camera and Core.C.Camera.isFirstPerson and Core.C.Camera.isFirstPerson()
	label.Adornee = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
	label.Enabled = not fp
	labelText.Text = near and text or ("🚶 " .. t("hint.get_closer"))
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
	if current.kind ~= "sink" or handsKind() ~= nil or (workspace:GetAttribute("SinkPile") or 0) <= 0 then
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

local function act(tap)
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
	elseif current.kind == "menuboard" then
		Core.C.UI.open("Menu")
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
		if aimingCenter() then
			-- first person: whatever is under the crosshair (mouse, touch and gamepad alike)
			local cam = workspace.CurrentCamera
			update(cam.ViewportSize / 2)
		elseif UserInputService.MouseEnabled then
			update(UserInputService:GetMouseLocation())
		elseif current then
			setCurrent(current.model, current.slot)
		end
	end)
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or (Core.C.Build and Core.C.Build.active) then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			act()
		elseif input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.ButtonX then
			act()
		end
	end)
	-- releasing the click / E stops washing
	UserInputService.InputEnded:Connect(function(input)
		local released = input.UserInputType == Enum.UserInputType.MouseButton1 or input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.ButtonX
		if released and Core.C.Sink then
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
