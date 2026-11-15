--!nonstrict
-- Stations: ingredients go on the board, each click runs the next step (cut, combine, roll,
-- boil, pour, top, fry...), then the dish waits on the plate. Also the order tickets.
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local Recipes = require(Shared.Config.Recipes)
local Ingredients = require(Shared.Config.Ingredients)
local Upgrades = require(Shared.Config.Upgrades)
local Formulas = require(Shared.Logic.Formulas)
local Registry = require(Shared.Models.Registry)
local Uid = require(Shared.Util.Uid)
local Core = require(script.Parent.Parent.Core)

local Cooking = {}
Cooking.tickets = {}

local TOOL_FOR_STEP = {
	cut = "knife", combine = "knife", roll = "mat", mold = "mat", boil = "strainer", pour = "ladle",
	top = "ladle", batter = "ladle", fry = "strainer", flip = "spatula",
}

local function data()
	return Core.S.Session.ownerData()
end

local function station(e)
	if not e.station then
		e.station = { board = {}, step = 0, busy = false, ready = nil, boardModels = {}, dish = nil }
	end
	return e.station
end

local function stationType(e)
	return e.item.fn.station
end

local function unlockedRecipes(e)
	local d = data()
	local out = {}
	for _, r in ipairs(Recipes.byStation[stationType(e)] or {}) do
		if Core.S.Progression.isRecipeUnlocked(d, r) then
			table.insert(out, r)
		end
	end
	return out
end

local function boardKey(board)
	local ids = {}
	for _, b in ipairs(board) do
		table.insert(ids, b.g)
	end
	table.sort(ids)
	return table.concat(ids, "+")
end

-- true if `ids` (multiset) is contained in some unlocked recipe of this station
local function fits(e, ids)
	for _, r in ipairs(unlockedRecipes(e)) do
		local need = {}
		for _, g in ipairs(r.ing) do
			need[g] = (need[g] or 0) + 1
		end
		local ok = true
		for _, g in ipairs(ids) do
			if not need[g] or need[g] == 0 then
				ok = false
				break
			end
			need[g] -= 1
		end
		if ok then
			return true
		end
	end
	return false
end

function Cooking.match(e)
	local key = boardKey(station(e).board)
	for _, r in ipairs(unlockedRecipes(e)) do
		if r.key == key then
			return r
		end
	end
	return nil
end

local function attachment(e, name)
	local root = e.model and e.model.PrimaryPart
	return root and root:FindFirstChild(name)
end

local function publish(e)
	local st = station(e)
	local m = e.model
	if not m then
		return
	end
	local ids = {}
	for _, b in ipairs(st.board) do
		table.insert(ids, b.g)
	end
	local recipe = Cooking.match(e)
	m:SetAttribute("Board", table.concat(ids, ","))
	m:SetAttribute("Recipe", recipe and recipe.id or "")
	m:SetAttribute("Step", st.step)
	m:SetAttribute("Steps", recipe and table.concat(recipe.steps, ",") or "")
	m:SetAttribute("Busy", st.busy)
	m:SetAttribute("Ready", st.ready and st.ready.recipe or "")
end

local function clearBoardModels(st)
	for _, mdl in ipairs(st.boardModels) do
		mdl:Destroy()
	end
	st.boardModels = {}
end

local function layoutBoard(e)
	local st = station(e)
	clearBoardModels(st)
	local att = attachment(e, "Board")
	if not att then
		return
	end
	local n = #st.board
	for i, b in ipairs(st.board) do
		local mdl = Registry.food("ingredient", b.g)
		local x = (i - (n + 1) / 2) * 0.55
		mdl:PivotTo(att.WorldCFrame * CFrame.new(x, 0.3, 0) * CFrame.Angles(0, math.rad(90), 0))
		mdl:ScaleTo(0.8)
		for _, d in ipairs(mdl:GetDescendants()) do
			if d:IsA("BasePart") then
				d.CanQuery = false
			end
		end
		mdl.Parent = e.model
		table.insert(st.boardModels, mdl)
	end
end

local function stepDuration(e, stepName, recipe, speed)
	local d = data()
	local cfg = GameConfig.Steps[stepName] or { time = 1, tool = "up_knife" }
	local t = cfg.time * Upgrades.value(d.upgrades, cfg.tool)
	local mastery = Formulas.masteryLevel(d.mastery[recipe.id] or 0)
	t = t * (1 - 0.05 * mastery)
	return math.max(0.25, t / (speed or 1))
end

local function animateStep(e, stepName, duration)
	local st = station(e)
	local toolAtt = attachment(e, "Tool")
	local boardAtt = attachment(e, "Board")
	if not toolAtt or not boardAtt then
		task.wait(duration)
		return
	end
	local tool = Registry.food("tool", TOOL_FOR_STEP[stepName] or "knife")
	for _, d in ipairs(tool:GetDescendants()) do
		if d:IsA("BasePart") then
			d.CanQuery = false
		end
	end
	tool.Parent = e.model
	local top = toolAtt.WorldCFrame
	local low = boardAtt.WorldCFrame * CFrame.new(0, 0.45, 0)
	local steps = math.max(8, math.floor(duration / 0.04))
	local pos = boardAtt.WorldPosition
	if stepName == "cut" then
		Core.S.Net.fx("sfx", { name = "cut", pos = pos })
	elseif stepName == "boil" or stepName == "fry" then
		Core.S.Net.fx("sfx", { name = "sizzle", pos = pos })
	elseif stepName == "pour" then
		Core.S.Net.fx("sfx", { name = "pour", pos = pos })
	end
	local startScales = {}
	for i, mdl in ipairs(st.boardModels) do
		startScales[i] = mdl:GetPivot()
	end
	for k = 1, steps do
		local t = k / steps
		if stepName == "cut" then
			local chop = math.abs(math.sin(t * math.pi * 3))
			tool:PivotTo(low:Lerp(top, chop * 0.6) * CFrame.new(0.2 * math.sin(t * math.pi * 6), 0, 0))
		elseif stepName == "roll" or stepName == "mold" then
			tool:PivotTo(low * CFrame.Angles(t * math.pi * 2, 0, 0))
		elseif stepName == "combine" then
			tool:PivotTo(top:Lerp(low, math.sin(t * math.pi) * 0.8))
			for i, mdl in ipairs(st.boardModels) do
				local from = startScales[i]
				mdl:PivotTo(from:Lerp(boardAtt.WorldCFrame * CFrame.new(0, 0.3, 0), t))
			end
		else
			tool:PivotTo(top:Lerp(low, math.abs(math.sin(t * math.pi * 2)) * 0.8) * CFrame.Angles(0, 0, math.sin(t * math.pi * 4) * 0.3))
		end
		task.wait(duration / steps)
	end
	tool:Destroy()
end

local function showDish(e, recipeId)
	local st = station(e)
	if st.dish then
		st.dish:Destroy()
	end
	local att = attachment(e, "Plate")
	if not att then
		return
	end
	local d = data()
	local gold = Formulas.masteryLevel(d.mastery[recipeId] or 0) >= #Formulas.MasteryThresholds
	local mdl = Registry.food("dish", recipeId, gold)
	mdl:PivotTo(att.WorldCFrame * CFrame.new(0, 0.5, 0))
	for _, d in ipairs(mdl:GetDescendants()) do
		if d:IsA("BasePart") then
			d.CanQuery = false
		end
	end
	mdl.Parent = e.model
	st.dish = mdl
end

local function isFresh(e, st)
	for _, b in ipairs(st.board) do
		if b.fresh then
			return true
		end
	end
	return Core.S.Appliance.fridgeNear(e.model.PrimaryPart.Position)
end

-- Runs the next step. Returns ok, messageKey, params
function Cooking.step(e, speed)
	local st = station(e)
	local recipe = Cooking.match(e)
	if not recipe then
		return false, "msg.no_recipe_fits"
	end
	local Appliance = Core.S.Appliance
	if st.step == 0 then
		if recipe.rice and not Appliance.hasRice() then
			return false, "msg.need_rice"
		end
		if recipe.broth and not Appliance.hasBroth(recipe.broth) then
			return false, "msg.need_broth", { name = "ing." .. recipe.broth }
		end
		if data().dishes.clean <= 0 then
			return false, "msg.no_dishes"
		end
		if recipe.rice then
			Appliance.takeRice()
		end
		if recipe.broth then
			Appliance.takeBroth(recipe.broth)
		end
		Appliance.takeCleanDish()
		st.recipe = recipe.id
	end
	st.busy = true
	publish(e)
	local stepName = recipe.steps[st.step + 1]
	animateStep(e, stepName, stepDuration(e, stepName, recipe, speed))
	st.step += 1
	st.busy = false
	if st.step >= #recipe.steps then
		local fresh = isFresh(e, st)
		st.board = {}
		clearBoardModels(st)
		st.step = 0
		st.recipe = nil
		st.ready = { recipe = recipe.id, fresh = fresh }
		showDish(e, recipe.id)
		Core.S.Net.fx("dishReady", { pos = e.model.PrimaryPart.Position + Vector3.new(0, 4, 0), recipe = recipe.id })
	end
	publish(e)
	return true
end

-- Click on a station (players and staff)
function Cooking.use(actor, e, speed)
	local Hands = Core.S.Hands
	local st = station(e)
	local hands = Hands.get(actor)
	if st.busy then
		return false, "msg.busy"
	end
	if hands.kind == "ing" then
		local deposited = 0
		local remaining = {}
		local ids = {}
		for _, b in ipairs(st.board) do
			table.insert(ids, b.g)
		end
		for _, item in ipairs(hands.items) do
			local test = table.clone(ids)
			table.insert(test, item.g)
			if fits(e, test) then
				ids = test
				table.insert(st.board, item)
				deposited += 1
			else
				table.insert(remaining, item)
			end
		end
		if deposited == 0 then
			return false, (#st.board == 0) and "msg.no_recipe_fits" or "msg.not_for_this"
		end
		Hands.set(actor, "ing", remaining)
		layoutBoard(e)
		publish(e)
		return true
	elseif hands.kind == "dish" or hands.kind == nil then
		if st.ready then
			local ok, reason = Hands.add(actor, "dish", { recipe = st.ready.recipe, fresh = st.ready.fresh })
			if not ok then
				return false, reason
			end
			st.ready = nil
			if st.dish then
				st.dish:Destroy()
				st.dish = nil
			end
			publish(e)
			return true
		end
		if hands.kind == "dish" then
			return false, "msg.hands_busy"
		end
		if #st.board > 0 then
			if Cooking.match(e) then
				return Cooking.step(e, speed)
			end
			-- not a recipe (yet): put the ingredients back in hand
			if st.step == 0 then
				Hands.set(actor, "ing", st.board)
				st.board = {}
				layoutBoard(e)
				publish(e)
				return false, "msg.board_returned"
			end
		end
		return false, "msg.station_hint", { station = "station." .. stationType(e) }
	end
	return false, "msg.hands_busy"
end

------------------------------------------------------------------ tickets

function Cooking.maxTickets()
	return Upgrades.value(data().upgrades, "up_ticket")
end

local function broadcast()
	local list = {}
	for _, t in ipairs(Cooking.tickets) do
		table.insert(list, { id = t.id, recipe = t.recipe, created = t.created, customer = t.customer, claimed = t.claimed ~= nil })
	end
	Core.S.Net.fireAll("Tickets", list)
end

function Cooking.addTicket(customerUid, recipeId)
	if #Cooking.tickets >= Cooking.maxTickets() then
		return nil
	end
	local t = { id = Uid.new("t"), recipe = recipeId, customer = customerUid, created = workspace:GetServerTimeNow() }
	table.insert(Cooking.tickets, t)
	broadcast()
	return t
end

function Cooking.removeTicket(id)
	for i, t in ipairs(Cooking.tickets) do
		if t.id == id then
			table.remove(Cooking.tickets, i)
			broadcast()
			return t
		end
	end
	return nil
end

function Cooking.ticketFor(customerUid)
	for _, t in ipairs(Cooking.tickets) do
		if t.customer == customerUid then
			return t
		end
	end
	return nil
end

function Cooking.clearTickets()
	Cooking.tickets = {}
	broadcast()
end

-- Dishes ready on stations (for waiters)
function Cooking.readyDishes()
	local out = {}
	for _, e in ipairs(Core.S.Entities.ofKind("station")) do
		local st = station(e)
		if st.ready then
			table.insert(out, { entity = e, recipe = st.ready.recipe })
		end
	end
	return out
end

function Cooking.stationState(e)
	return station(e)
end

function Cooking.isRecipeInProgress(recipeId)
	local n = 0
	for _, e in ipairs(Core.S.Entities.ofKind("station")) do
		local st = station(e)
		if st.recipe == recipeId or (st.ready and st.ready.recipe == recipeId) then
			n += 1
		end
	end
	return n
end

function Cooking.Init()
	local Placement = Core.S.Placement
	Placement.ItemAdded:Connect(function(e)
		if e.kind == "station" then
			publish(e)
		end
	end)
	Placement.ItemMoved:Connect(function(e)
		if e.kind == "station" then
			layoutBoard(e)
			if station(e).ready then
				showDish(e, station(e).ready.recipe)
			end
		end
	end)
	Placement.addVeto(function(e)
		if e.kind == "station" then
			local st = station(e)
			if st.busy or #st.board > 0 or st.ready then
				return false, "msg.empty_first"
			end
		end
		return true
	end)
	local _ = Ingredients
end

return Cooking
