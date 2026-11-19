--!nonstrict
-- Localized billboards over customers (order + patience), stations (board / next step),
-- rice cookers & pots, shelf slots, dirty dishes and staff name tags.
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Locale = require(Shared.Locale)
local Recipes = require(Shared.Config.Recipes)
local Ingredients = require(Shared.Config.Ingredients)
local Color = require(Shared.Util.Color)
local NetDef = require(Shared.Net)
local GameConfig = require(Shared.Config.GameConfig)
local Core = require(script.Parent.Parent.Core)

local WorldUI = {}
local player = Players.LocalPlayer
local t = Locale.t
local boards = {} -- [Instance] = { gui, title, sub, bar, fill }

local RANGE = 45
local TYPE_ICON = { cust_critic = "🧐", cust_influencer = "📱", cust_vip = "💎", cust_celebrity = "⭐" }

local function make(adornee, height, width)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(width or 210, 66)
	gui.StudsOffsetWorldSpace = Vector3.new(0, height or 3, 0)
	gui.AlwaysOnTop = false
	gui.LightInfluence = 0
	gui.MaxDistance = RANGE
	gui.Adornee = adornee
	local bg = Instance.new("Frame")
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = Color.hex("#F4EBDD")
	bg.BackgroundTransparency = 0.05
	bg.Parent = gui
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 12)
	c.Parent = bg
	local s = Instance.new("UIStroke")
	s.Color = Color.hex("#5B3A24")
	s.Thickness = 2
	s.Parent = bg
	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, -8, 0.55, 0)
	title.Position = UDim2.fromOffset(4, 2)
	title.TextScaled = true
	title.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold)
	title.TextColor3 = Color.hex("#2B2320")
	title.AutoLocalize = false
	title.Parent = bg
	local sub = Instance.new("TextLabel")
	sub.BackgroundTransparency = 1
	sub.Size = UDim2.new(1, -8, 0.32, 0)
	sub.Position = UDim2.new(0, 4, 0.56, 0)
	sub.TextScaled = true
	sub.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Medium)
	sub.TextColor3 = Color.hex("#7A6A5A")
	sub.AutoLocalize = false
	sub.Parent = bg
	local bar = Instance.new("Frame")
	bar.BackgroundColor3 = Color.hex("#D8C8AE")
	bar.Size = UDim2.new(1, -16, 0, 9)
	bar.Position = UDim2.new(0, 8, 1, -13)
	bar.Visible = false
	bar.Parent = bg
	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(0, 4)
	barCorner.Parent = bar
	local fill = Instance.new("Frame")
	fill.BackgroundColor3 = Color.hex("#5E8F3A")
	fill.Size = UDim2.fromScale(1, 1)
	fill.Parent = bar
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 4)
	fillCorner.Parent = fill
	gui.Parent = player.PlayerGui
	return { gui = gui, bg = bg, title = title, sub = sub, bar = bar, fill = fill }
end

-- Customer bubble: sized in studs (2.7 wide, narrower than the 3 studs between two stools, so
-- neighbours never overlap), always on top, a big icon (❗, the dish, 😋), the dish name, and a
-- thick patience bar that turns yellow and red
local function makeCustomer(adornee)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromScale(2.7, 1.5)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 2.3, 0)
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.MaxDistance = 40
	gui.Adornee = adornee
	local bg = Instance.new("Frame")
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = Color.hex("#FFFBF2")
	bg.Parent = gui
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0.22, 0)
	c.Parent = bg
	local s = Instance.new("UIStroke")
	s.Color = Color.hex("#5B3A24")
	s.Thickness = 2.5
	s.Parent = bg
	local icon = Instance.new("TextLabel")
	icon.BackgroundTransparency = 1
	icon.Position = UDim2.fromScale(0.03, 0.06)
	icon.Size = UDim2.fromScale(0.34, 0.66)
	icon.TextScaled = true
	icon.AutoLocalize = false
	icon.Parent = bg
	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Position = UDim2.fromScale(0.38, 0.06)
	title.Size = UDim2.fromScale(0.6, 0.38)
	title.TextScaled = true
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Heavy)
	title.TextColor3 = Color.hex("#2B2320")
	title.AutoLocalize = false
	title.Parent = bg
	local sub = Instance.new("TextLabel")
	sub.BackgroundTransparency = 1
	sub.Position = UDim2.fromScale(0.38, 0.44)
	sub.Size = UDim2.fromScale(0.6, 0.28)
	sub.TextScaled = true
	sub.TextXAlignment = Enum.TextXAlignment.Left
	sub.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold)
	sub.TextColor3 = Color.hex("#7A5A3A")
	sub.AutoLocalize = false
	sub.Parent = bg
	local bar = Instance.new("Frame")
	bar.BackgroundColor3 = Color.hex("#D8C8AE")
	bar.Position = UDim2.fromScale(0.06, 0.78)
	bar.Size = UDim2.fromScale(0.88, 0.14)
	bar.Visible = false
	bar.Parent = bg
	local bc = Instance.new("UICorner")
	bc.CornerRadius = UDim.new(0.5, 0)
	bc.Parent = bar
	local fill = Instance.new("Frame")
	fill.BackgroundColor3 = Color.hex("#5E8F3A")
	fill.Size = UDim2.fromScale(1, 1)
	fill.Parent = bar
	local fc = Instance.new("UICorner")
	fc.CornerRadius = UDim.new(0.5, 0)
	fc.Parent = fill
	gui.Parent = player.PlayerGui
	return { gui = gui, bg = bg, icon = icon, title = title, sub = sub, bar = bar, fill = fill, customer = true }
end

local function icons(list)
	local out = {}
	for _, g in ipairs(list) do
		local ing = Ingredients.byId[g]
		table.insert(out, ing and ing.icon or "?")
	end
	return table.concat(out, " ")
end

local function setBar(b, value, show)
	b.bar.Visible = show
	if show then
		b.fill.Size = UDim2.fromScale(math.clamp(value, 0, 1), 1)
		b.fill.BackgroundColor3 = value > 0.5 and Color.hex("#5E8F3A") or (value > 0.25 and Color.hex("#D4A23C") or Color.hex("#B3262E"))
	end
end

local function updateEntity(model, b)
	local kind = model:GetAttribute("Kind")
	local now = workspace:GetServerTimeNow()
	b.gui.Enabled = true
	if kind == "customer" then
		local state = model:GetAttribute("State") or ""
		local order = model:GetAttribute("Order") or ""
		local typeIcon = TYPE_ICON[model:GetAttribute("Type") or ""] or ""
		local r = Recipes.byId[order]
		local icon = b.icon
		if state == "order" then
			icon.Text = "❗"
			b.title.Text = typeIcon .. t("ui.wants_order")
			b.sub.Text = t("hint.take_order")
		elseif state == "waiting" then
			icon.Text = r and r.icon or "🍽️"
			b.title.Text = typeIcon .. t("rec." .. order)
			b.sub.Text = t("ui.waiting")
		elseif state == "eating" or state == "served" then
			icon.Text = "😋"
			b.title.Text = t("ui.eating")
			b.sub.Text = ""
		elseif state == "queue" then
			icon.Text = "⏳"
			b.title.Text = t("ui.queue")
			b.sub.Text = ""
		else
			b.gui.Enabled = false
		end
		setBar(b, model:GetAttribute("Patience") or 1, state == "order" or state == "waiting")
		-- a gentle pulse while the order waits to be taken
		b.bg.BackgroundColor3 = state == "order" and Color.hex(math.floor(now * 2) % 2 == 0 and "#FFF1C2" or "#FFFBF2") or Color.hex("#FFFBF2")
	elseif (kind == "station" or kind == "ricecooker") and Core.C.Interaction and Core.C.Interaction.lockOf(model, kind) then
		-- not usable yet: name the license that unlocks it
		local lock = Core.C.Interaction.lockOf(model, kind)
		b.title.Text = "🔒 " .. t("lic." .. lock.id)
		b.sub.Text = t("ui.locked_level", { level = lock.level })
		b.bar.Visible = false
	elseif kind == "station" then
		local ready = model:GetAttribute("Ready") or ""
		local board = model:GetAttribute("Board") or ""
		local recipe = model:GetAttribute("Recipe") or ""
		if ready ~= "" then
			b.title.Text = "✅ " .. t("rec." .. ready)
			b.sub.Text = t("ui.ready_to_serve")
		elseif recipe ~= "" then
			local steps = string.split(model:GetAttribute("Steps") or "", ",")
			local idx = (model:GetAttribute("Step") or 0) + 1
			b.title.Text = (Recipes.byId[recipe] and Recipes.byId[recipe].icon or "") .. " " .. t("rec." .. recipe)
			b.sub.Text = (model:GetAttribute("Busy") and "⏳ " or "👆 ") .. t("step." .. (steps[idx] or "combine")) .. " (" .. idx .. "/" .. #steps .. ")"
		elseif board ~= "" then
			b.title.Text = icons(string.split(board, ","))
			b.sub.Text = t("ui.board_incomplete")
		else
			b.gui.Enabled = false
		end
		b.bar.Visible = false
	elseif kind == "ricecooker" or kind == "pot" then
		local n, c, batch = model:GetAttribute("N") or 0, model:GetAttribute("C") or 0, model:GetAttribute("Batch") or 0
		local g = model:GetAttribute("G") or ""
		local icon = kind == "ricecooker" and "🍚" or "🥣"
		local name = g ~= "" and t("ing." .. g) or t(kind == "ricecooker" and "ui.rice_cooker" or "ui.pot")
		b.title.Text = icon .. " " .. name
		if c > 0 then
			local remaining = math.max(0, (model:GetAttribute("T") or now) - now)
			local total = model:GetAttribute("Time") or 1
			b.sub.Text = "⏳ " .. math.ceil(remaining) .. "s  (+" .. c .. ")"
			setBar(b, 1 - remaining / total, true)
			b.fill.BackgroundColor3 = Color.hex("#2E5A8C")
		else
			b.sub.Text = n .. " / " .. batch .. (n == 0 and ("  ·  " .. t("ui.empty")) or "")
			setBar(b, n / math.max(1, batch), true)
		end
	elseif kind == "tipjar" then
		local tips = model:GetAttribute("Tips") or 0
		b.gui.Enabled = tips > 0
		b.title.Text = "🫙 ¥" .. tips
		b.sub.Text = t("ui.tipjar_collect")
		b.bar.Visible = false
	elseif kind == "dirty" then
		b.title.Text = "🧽"
		b.sub.Text = t("hint.collect")
		b.bar.Visible = false
	elseif kind == "dishwasher" then
		local q = model:GetAttribute("Queue") or 0
		b.gui.Enabled = q > 0
		b.title.Text = "🫧 " .. q
		b.sub.Text = t("ui.washing")
	else
		b.gui.Enabled = false
	end
end

local staffTags = {}

local function updateStaff(char, origin)
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local b = staffTags[char]
	if not b then
		b = make(char:FindFirstChild("Head") or root, 1.8, 150)
		b.gui.Size = UDim2.fromOffset(150, 40)
		staffTags[char] = b
	end
	local near = (root.Position - origin).Magnitude < RANGE
	b.gui.Enabled = near
	if near then
		b.title.Text = char:GetAttribute("StaffName") or ""
		b.sub.Text = t("staff." .. (char:GetAttribute("StaffRole") or "staff_waiter")) .. " · Lv" .. (char:GetAttribute("StaffLevel") or 1)
	end
end

-- the "for sale" signs of rooms (Models/Scene.forSale): icon, name and price in your language,
-- or the level it needs
local function paintSigns()
	local Format = require(Shared.Util.Format)
	local level = Core.C.Data.w("level") or 1
	local yen = Core.C.Data.wallet()
	for _, m in ipairs(CollectionService:GetTagged("ForSale")) do
		local board = m.PrimaryPart
		local id = m:GetAttribute("Expansion") or ""
		local price = m:GetAttribute("Price") or 0
		local need = m:GetAttribute("Level") or 1
		local text
		if level < need then
			text = "🔒\n" .. t("zone." .. id) .. "\n" .. t("ui.req_level", { level = need })
		else
			text = "🏗️ " .. t("zone." .. id) .. "\n" .. Format.yen(price, Locale.get()) .. (yen >= price and "  ✅" or "")
		end
		for _, side in ipairs({ "Front", "Back" }) do
			local gui = board and board:FindFirstChild(side)
			local label = gui and gui:FindFirstChildOfClass("TextLabel")
			if label and label.Text ~= text then
				label.Text = text
			end
		end
	end
end

-- Ranking boards in the street (Models/Builders/Street rankingBoard): the top ten of every
-- leaderboard (Services/Leaderboard) in your language, your row in gold when you are in it and
-- your own number at the bottom
local RANK_ICON = { dishes = "🍜 ", earned = "💴 ", likes = "" }
local MEDAL = { "🥇", "🥈", "🥉" }
local rankData = nil
local BOLD = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold)
local MEDIUM = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Medium)

local function rankLabel(parent, name, size, font, align)
	local l = Instance.new("TextLabel")
	l.Name = name
	l.BackgroundTransparency = 1
	l.Size = size
	l.FontFace = font
	l.TextSize = 22
	l.TextColor3 = Color.hex("#2B2320")
	l.TextXAlignment = align or Enum.TextXAlignment.Left
	l.TextTruncate = Enum.TextTruncate.AtEnd
	l.AutoLocalize = false
	l.Text = ""
	l.Parent = parent
	return l
end

local function rankRow(parent, name, order, height)
	local row = Instance.new("Frame")
	row.Name = name
	row.LayoutOrder = order
	row.Size = UDim2.new(1, -12, 0, height)
	row.BackgroundColor3 = Color.hex("#F2D27A")
	row.BackgroundTransparency = 1
	row.BorderSizePixel = 0
	row.Parent = parent
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 6)
	c.Parent = row
	rankLabel(row, "Who", UDim2.new(0.64, -6, 1, 0), MEDIUM).Position = UDim2.fromOffset(6, 0)
	rankLabel(row, "Value", UDim2.new(0.36, -6, 1, 0), BOLD, Enum.TextXAlignment.Right).Position = UDim2.fromScale(0.64, 0)
	return row
end

local function rankingGui(panel)
	local gui = panel:FindFirstChild("Ranking")
	if gui then
		return gui
	end
	gui = Instance.new("SurfaceGui")
	gui.Name = "Ranking"
	gui.Face = Enum.NormalId.Back
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0
	gui.MaxDistance = 160
	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.Padding = UDim.new(0, 2)
	list.Parent = gui
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 8)
	pad.Parent = gui
	local title = rankLabel(gui, "Title", UDim2.new(1, -16, 0, 50), BOLD, Enum.TextXAlignment.Center)
	title.TextScaled = true
	title.TextWrapped = true
	title.TextColor3 = Color.hex("#7A1A1F")
	title.LayoutOrder = 0
	for i = 1, GameConfig.Leaderboard.Rows do
		rankRow(gui, "Row" .. i, i, 28)
	end
	rankRow(gui, "You", 99, 38).BackgroundTransparency = 0.4
	gui.Parent = panel
	return gui
end

local function paintRankings()
	local Format = require(Shared.Util.Format)
	local L = Locale.get()
	local stats = Core.C.Data.m("stats") or {}
	for _, board in ipairs(CollectionService:GetTagged("RankingBoard")) do
		for _, panel in ipairs(board:GetChildren()) do
			local stat = panel:IsA("BasePart") and panel.Name:match("^Panel_(%w+)$")
			if stat then
				local gui = rankingGui(panel)
				local function value(n)
					return stat == "earned" and Format.yen(n, L) or Format.number(n, L)
				end
				gui.Title.Text = (RANK_ICON[stat] or "") .. t("lb." .. stat)
				local entries = rankData and rankData[stat] or {}
				for i = 1, GameConfig.Leaderboard.Rows do
					local row = gui:FindFirstChild("Row" .. i)
					local e = entries[i]
					if row then
						local me = e and e.name == player.Name
						row.Who.Text = e and ((MEDAL[i] or (i .. ".")) .. " " .. e.name) or ((MEDAL[i] or (i .. ".")) .. " —")
						row.Value.Text = e and value(e.value) or ""
						row.BackgroundTransparency = me and 0 or 1
						row.Who.FontFace = me and BOLD or MEDIUM
					end
				end
				gui.You.Who.Text = t("ui.lb_you")
				gui.You.Value.Text = value(math.floor(stats[stat] or 0))
			end
		end
	end
end

local function refreshRankings()
	local ok, result = pcall(function()
		return NetDef.func("GetLeaderboard"):InvokeServer()
	end)
	if ok and type(result) == "table" then
		rankData = result
	end
	pcall(paintRankings)
end

function WorldUI.Start()
	local lastSigns = 0
	local lastRanks = -math.huge
	local lastPaint = 0
	Locale.Changed:Connect(function()
		pcall(paintRankings)
	end)
	while true do
		task.wait(0.2)
		if os.clock() - lastSigns > 1 then
			lastSigns = os.clock()
			pcall(paintSigns)
		end
		-- new numbers every CacheSeconds; painted again every few seconds for boards that stream in
		if os.clock() - lastRanks > GameConfig.Leaderboard.CacheSeconds then
			lastRanks = os.clock()
			lastPaint = os.clock()
			task.spawn(refreshRankings)
		elseif os.clock() - lastPaint > 5 then
			lastPaint = os.clock()
			pcall(paintRankings)
		end
		local cam = workspace.CurrentCamera
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local origin = root and root.Position or (cam and cam.CFrame.Position) or Vector3.new()
		local alive = {}
		for _, model in ipairs(CollectionService:GetTagged("Interactable")) do
			if model:IsDescendantOf(workspace) then
				local kind = model:GetAttribute("Kind")
				local pos = model:GetPivot().Position
				local near = (pos - origin).Magnitude < RANGE
				-- shelves need no label: their products stand in a grid with the free spots marked;
				-- customers show their bubble everywhere, the other boards only in the restaurant you
				-- work in
				local mine = kind == "customer" or Core.C.Data.isMine(model)
				if near and mine and (kind == "customer" or kind == "station" or kind == "ricecooker" or kind == "pot" or kind == "dirty" or kind == "dishwasher" or kind == "tipjar") then
					local b = boards[model]
					if not b then
						local adornee = model:FindFirstChild("Head") or model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
						b = kind == "customer" and makeCustomer(adornee) or make(adornee, kind == "station" and 3 or 2.5)
						boards[model] = b
					end
					alive[model] = true
					local ok = pcall(updateEntity, model, b)
					if not ok then
						b.gui.Enabled = false
					end
				end
			end
		end
		for model, b in pairs(boards) do
			if not alive[model] then
				b.gui:Destroy()
				boards[model] = nil
			end
		end
		local npcs = workspace:FindFirstChild("NPCs")
		if npcs then
			for _, m in ipairs(npcs:GetChildren()) do
				if m:GetAttribute("StaffName") then
					updateStaff(m, origin)
				end
			end
		end
		for m, b in pairs(staffTags) do
			if not m:IsDescendantOf(workspace) then
				b.gui:Destroy()
				staffTags[m] = nil
			end
		end
	end
end

return WorldUI
