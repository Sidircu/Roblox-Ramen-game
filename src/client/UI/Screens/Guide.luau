--!nonstrict
-- Order guide: tapping an order ticket (right) shows what to do, in a few short lines with live
-- ticks, highlights the shelf slots and the station to use and draws a glowing arrow from you to
-- the next thing to click. The card stands on the left, under the wallet; on phones the second
-- line of each step is left out.
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Locale = require(Shared.Locale)
local Recipes = require(Shared.Config.Recipes)
local Ingredients = require(Shared.Config.Ingredients)
local Items = require(Shared.Config.Items)
local Color = require(Shared.Util.Color)
local Kit = require(script.Parent.Parent.Kit)
local Core = require(script.Parent.Parent.Parent.Core)

local Guide = { modal = false, recipe = nil, ticket = nil }
local T = Kit.Theme
local t = Locale.t
local player = Players.LocalPlayer

local frame, title, list
local marks = {}
local beam, a0, a1, holder, marker
local lastBuild = 0

local STATION_ICON = { sushi = "🍣", ramen = "🍜", drink = "🍵", griddle = "🥟", fryer = "🍤", takoyaki = "🐙", dessert = "🍡" }

local function hands()
	local kind = player:GetAttribute("HandsKind") or ""
	local ok, list = pcall(HttpService.JSONDecode, HttpService, player:GetAttribute("Hands") or "[]")
	return kind, ok and list or {}
end

local function interactables(kind)
	local out = {}
	for _, m in ipairs(CollectionService:GetTagged("Interactable")) do
		if m:GetAttribute("Kind") == kind and m:IsDescendantOf(workspace) and Core.C.Data.isMine(m) then
			table.insert(out, m)
		end
	end
	return out
end

local function stationType(m)
	local item = Items.byId[m.Name]
	return item and item.fn and item.fn.station
end

local function distance(m)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then
		return 0
	end
	return (m:GetPivot().Position - root.Position).Magnitude
end

local function nearest(models, filter)
	local best, bestD = nil, math.huge
	for _, m in ipairs(models) do
		if not filter or filter(m) then
			local d = distance(m)
			if d < bestD then
				best, bestD = m, d
			end
		end
	end
	return best
end

local function clearMarks()
	for _, m in ipairs(marks) do
		m:Destroy()
	end
	marks = {}
end

local function mark(adornee, color)
	local box = Instance.new("SelectionBox")
	box.Adornee = adornee
	box.Color3 = color
	box.LineThickness = 0.09
	box.SurfaceColor3 = color
	box.SurfaceTransparency = 0.8
	box.Parent = player.PlayerGui
	table.insert(marks, box)
end

local function pointAt(target)
	if target then
		holder.Position = target:GetPivot().Position + Vector3.new(0, 2.5, 0)
		marker.Adornee = holder
		beam.Enabled = true
		marker.Enabled = true
	else
		beam.Enabled = false
		marker.Enabled = false
	end
end

-- One line of the guide: state = "done" | "now" | "todo"
local function line(order, state, text, sub)
	if Kit.profile == "phone" and state ~= "now" then
		sub = nil
	end
	local icon = state == "done" and "✅" or (state == "now" and "👉" or "▫️")
	local row = Kit.new("Frame", { BackgroundColor3 = state == "now" and Color.hex("#FFF4D6") or T.paper, BackgroundTransparency = state == "now" and 0 or 1, Size = UDim2.new(1, 0, 0, sub and 46 or 28), LayoutOrder = order, Parent = list }, { Kit.corner(8) })
	Kit.label(icon, { Parent = row, Position = UDim2.fromOffset(4, 3), Size = UDim2.fromOffset(22, 22), TextScaled = true })
	Kit.label(text, { Parent = row, Position = UDim2.fromOffset(30, 3), Size = UDim2.new(1, -34, 0, 22), TextSize = 15, FontFace = state == "now" and T.bold or T.body, TextColor3 = state == "done" and T.muted or T.ink, TextTruncate = Enum.TextTruncate.AtEnd, TextWrapped = false })
	if sub then
		Kit.label(sub, { Parent = row, Position = UDim2.fromOffset(30, 24), Size = UDim2.new(1, -34, 0, 18), TextSize = 13, TextColor3 = T.muted, TextTruncate = Enum.TextTruncate.AtEnd, TextWrapped = false })
	end
end

-- Builds the steps for the current recipe from what is happening in the world
local function update()
	local r = Recipes.byId[Guide.recipe or ""]
	if not r or not frame.Visible then
		return
	end
	Kit.clear(list)
	clearMarks()
	local kind, held = hands()
	local stations = interactables("station")
	local myStations = {}
	for _, m in ipairs(stations) do
		if stationType(m) == r.station then
			table.insert(myStations, m)
		end
	end
	local readyStation = nearest(myStations, function(m)
		return m:GetAttribute("Ready") == r.id
	end)
	local workStation = nearest(myStations, function(m)
		return m:GetAttribute("Recipe") == r.id and (m:GetAttribute("Ready") or "") == ""
	end)
	local holdingDish = kind == "dish" and table.find(held, r.id) ~= nil
	local target = nil
	local order = 0
	local function add(state, text, sub)
		order += 1
		line(order, state, text, sub)
	end

	-- 1. rice / broth ready in the appliances
	local baseOk = true
	if r.rice then
		local cooker = nearest(interactables("ricecooker"), function(m)
			return (m:GetAttribute("N") or 0) > 0
		end)
		baseOk = cooker ~= nil
		add(baseOk and "done" or "now", "🍚 " .. t("guide.rice"), not baseOk and t("guide.rice_how") or nil)
		if not baseOk then
			target = nearest(interactables("ricecooker"))
		end
	end
	if r.broth then
		local pot = nearest(interactables("pot"), function(m)
			return m:GetAttribute("G") == r.broth and (m:GetAttribute("N") or 0) > 0
		end)
		local ok = pot ~= nil
		add(ok and "done" or (baseOk and "now" or "todo"), "🥣 " .. t("guide.broth", { name = "ing." .. r.broth }), not ok and t("guide.broth_how") or nil)
		if not ok and not target then
			target = nearest(interactables("pot"))
		end
		baseOk = baseOk and ok
	end

	-- 2. ingredients on the shelves (the station takes them by itself)
	local need = {}
	for _, g in ipairs(r.ing) do
		need[g] = (need[g] or 0) + 1
	end
	local stock = {}
	for _, shelf in ipairs(interactables("shelf")) do
		for _, part in ipairs(shelf:GetChildren()) do
			local g = part:IsA("BasePart") and part:GetAttribute("Slot") and part:GetAttribute("G") or ""
			if g ~= "" then
				stock[g] = (stock[g] or 0) + (part:GetAttribute("N") or 0)
			end
		end
	end
	local workStation0 = workStation or readyStation
	local onBoard = workStation0 ~= nil or holdingDish
	local chips, missing = {}, nil
	for _, g in ipairs(r.ing) do
		local ing = Ingredients.byId[g]
		local got = onBoard or (stock[g] or 0) >= need[g]
		table.insert(chips, (got and "✓" or "✗") .. (ing and ing.icon or "") .. " " .. t("ing." .. g))
		if not got and not missing then
			missing = g
		end
	end
	add(missing == nil and "done" or "now", "🧺 " .. t("guide.on_shelves"), table.concat(chips, "   "))
	if missing and not target then
		-- a box of what is missing, else the supplier
		target = nearest(interactables("box"), function(m)
			return m:GetAttribute("Ingredient") == missing
		end)
		add("now", "📦 " .. t("guide.no_stock", { name = "ing." .. missing }), t("guide.no_stock_how"))
	end

	-- 3. the station: one press per step (the first press brings the ingredients)
	local stName = (STATION_ICON[r.station] or "🔪") .. " " .. t("station." .. r.station)
	local steps = {}
	for _, s in ipairs(r.steps) do
		table.insert(steps, t("step." .. s))
	end
	local stepDone = workStation and (workStation:GetAttribute("Step") or 0) or 0
	if readyStation or holdingDish then
		add("done", t("guide.press_steps", { station = stName, n = #r.steps }), table.concat(steps, " → "))
	elseif workStation then
		add("now", t("guide.press_steps", { station = stName, n = #r.steps }) .. "  (" .. stepDone .. "/" .. #r.steps .. ")", table.concat(steps, " → "))
		target = target or workStation
		mark(workStation.PrimaryPart or workStation, Color.hex("#6DDC5A"))
	else
		local free = nearest(myStations, function(m)
			return (m:GetAttribute("Board") or "") == "" and (m:GetAttribute("Ready") or "") == ""
		end) or nearest(myStations)
		local state = (missing == nil and not target) and "now" or "todo"
		add(state, t("guide.press_steps", { station = stName, n = #r.steps }), #myStations == 0 and t("guide.no_station") or table.concat(steps, " → "))
		if free then
			mark(free.PrimaryPart or free, Color.hex("#6DDC5A"))
			if state == "now" then
				target = free
			end
		end
	end

	-- 4. take the dish and serve the customer
	if holdingDish then
		add("done", t("guide.pick"))
		local customer = nearest(interactables("customer"), function(m)
			return m:GetAttribute("Order") == r.id and (m:GetAttribute("State") == "waiting" or m:GetAttribute("State") == "order")
		end)
		add("now", t("guide.serve"))
		target = customer
	elseif readyStation then
		add("now", t("guide.pick"))
		add("todo", t("guide.serve"))
		target = readyStation
	else
		add("todo", t("guide.pick"))
		add("todo", t("guide.serve"))
	end
	pointAt(target)
	local h = 50
	for _, c in ipairs(list:GetChildren()) do
		if c:IsA("Frame") then
			h += c.Size.Y.Offset + 3
		end
	end
	frame.Size = UDim2.fromOffset(Kit.profile == "phone" and 290 or 320, h + 8)
end

function Guide.create(root)
	frame = Kit.panel({ Name = "Guide", Position = UDim2.fromOffset(10, 124), Size = UDim2.fromOffset(320, 300), Visible = false, ZIndex = 5, Parent = root })
	title = Kit.title("", { Parent = frame, Position = UDim2.fromOffset(12, 6), Size = UDim2.new(1, -54, 0, 30), TextSize = 18, TextTruncate = Enum.TextTruncate.AtEnd })
	Kit.button("✕", { parent = frame, size = UDim2.fromOffset(32, 32), position = UDim2.new(1, -40, 0, 6), style = "close", textSize = 14, radius = 16, onClick = function()
		Guide.hide()
	end })
	list = Kit.new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 42), Size = UDim2.new(1, -20, 1, -48), Parent = frame }, { Kit.list(Enum.FillDirection.Vertical, 3) })
	-- glowing arrow from the player to the next thing to click
	a0 = Instance.new("Attachment")
	a1 = Instance.new("Attachment")
	beam = Instance.new("Beam")
	beam.Attachment0 = a0
	beam.Attachment1 = a1
	beam.Width0 = 0.5
	beam.Width1 = 0.5
	beam.FaceCamera = true
	beam.Color = ColorSequence.new(Color.hex("#6DDC5A"))
	beam.LightEmission = 1
	beam.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	beam.TextureMode = Enum.TextureMode.Wrap
	beam.TextureSpeed = 2
	beam.Enabled = false
	holder = Instance.new("Part")
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanQuery = false
	holder.CanTouch = false
	holder.Transparency = 1
	holder.Size = Vector3.new(0.2, 0.2, 0.2)
	a1.Parent = holder
	beam.Parent = holder
	marker = Instance.new("BillboardGui")
	marker.Size = UDim2.fromOffset(56, 56)
	marker.StudsOffsetWorldSpace = Vector3.new(0, 3, 0)
	marker.AlwaysOnTop = true
	marker.Enabled = false
	marker.Parent = player:WaitForChild("PlayerGui")
	local arrow = Instance.new("TextLabel")
	arrow.Size = UDim2.fromScale(1, 1)
	arrow.BackgroundTransparency = 1
	arrow.Text = "⬇️"
	arrow.TextScaled = true
	arrow.AutoLocalize = false
	arrow.Parent = marker
	RunService.Heartbeat:Connect(function()
		if not frame.Visible then
			return
		end
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root and a0.Parent ~= root then
			a0.Parent = root
		end
		if holder.Parent ~= workspace.CurrentCamera then
			holder.Parent = workspace.CurrentCamera
		end
		if os.clock() - lastBuild > 0.3 then
			lastBuild = os.clock()
			local ok, err = pcall(update)
			if not ok then
				warn("[Guide] " .. tostring(err))
			end
		end
		-- the order is gone (served or the customer left)
		local still = false
		for _, tk in ipairs(Core.C.Data.tickets or {}) do
			if tk.recipe == Guide.recipe then
				still = true
			end
		end
		local kind, held = hands()
		if not still and not (kind == "dish" and table.find(held, Guide.recipe)) then
			Guide.hide()
		end
	end)
end

-- Shows the guide for a recipe; tapping the same order again hides it
function Guide.show(recipeId)
	if Guide.recipe == recipeId and frame.Visible then
		Guide.hide()
		return
	end
	Guide.recipe = recipeId
	local r = Recipes.byId[recipeId]
	title.Text = (r and r.icon or "🍽️") .. " " .. t("rec." .. recipeId)
	frame.Visible = true
	lastBuild = 0
	update()
end

function Guide.hide()
	Guide.recipe = nil
	frame.Visible = false
	clearMarks()
	beam.Enabled = false
	marker.Enabled = false
	local hud = Core.C.UI.screens.HUD
	if hud and hud.refreshTickets then
		hud.refreshTickets()
	end
end

function Guide.visible()
	return frame ~= nil and frame.Visible
end

function Guide.refresh()
	if frame and frame.Visible then
		update()
	end
end

function Guide.open(recipeId)
	if recipeId then
		Guide.show(recipeId)
	end
end

function Guide.close()
	Guide.hide()
end

return Guide
