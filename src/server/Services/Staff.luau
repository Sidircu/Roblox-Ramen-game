--!nonstrict
-- Staff: hiring, training, salaries and the AI that automates each restaurant (every actor
-- works for one plot: a.plot).
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local StaffCfg = require(Shared.Config.Staff)
local Formulas = require(Shared.Logic.Formulas)
local Uid = require(Shared.Util.Uid)
local Core = require(script.Parent.Parent.Core)

local Staff = {}
local actors = {} -- [uid] = actor

-- where idle staff wait (restaurant-local coordinates)
local HOME = { Vector3.new(10, 0.5, 21), Vector3.new(-14, 0.5, 21), Vector3.new(4, 0.5, 23), Vector3.new(-2, 0.5, 21) }

local function homeOf(a)
	local h = HOME[(a.index % #HOME) + 1]
	return Core.S.Plots.toWorld(a.plot, h.X, h.Y, h.Z)
end

local function managerBonus(plot)
	for _, a in pairs(actors) do
		if a.plot == plot and a.role == "staff_manager" then
			return GameConfig.ManagerSpeedBonus
		end
	end
	return 0
end

local function speed(a)
	return Formulas.staffSpeed(a.lvl, GameConfig.StaffSpeedPerLevel, managerBonus(a.plot))
end

local function walk(a, pos)
	if not a.alive then
		return false
	end
	a.npc.humanoid.WalkSpeed = GameConfig.StaffWalkSpeed * speed(a)
	return Core.S.Npc.walkTo(a.npc, pos, { staff = true })
end

local function idleAt(a)
	local home = homeOf(a)
	if a.npc.root and (a.npc.root.Position - home).Magnitude > 4 then
		walk(a, home)
	end
	task.wait(1)
end

local function dropHands(a)
	local Hands = Core.S.Hands
	local h = Hands.get(a)
	if h.kind == "box" then
		for _, b in ipairs(h.items) do
			Core.S.Supply.returnBox(a.plot, b)
		end
	elseif h.kind == "dish" or h.kind == "dirty" then
		Core.S.Appliance.addDirtyToSink(a.plot, #h.items)
	end
	Hands.clear(a)
end

local Tasks

local function customerEntity(c)
	return Core.S.Entities.get(c.uid)
end

------------------------------------------------------------------ jobs

local function doOrder(a)
	local c = Tasks.findOrder(a.plot)
	if not c or not Tasks.claim(c, a) then
		return false
	end
	walk(a, Tasks.nearCustomer(c))
	local e = customerEntity(c)
	if e and c.state == "order" then
		Core.S.Customers.use(a, e)
	end
	Tasks.release(c, a)
	return true
end

local function deliverDish(a, recipeId)
	-- find a waiting customer for the dish in hand
	for _, c in ipairs(Core.S.Customers.list(a.plot, "waiting")) do
		if c.order == recipeId and Tasks.claim(c, a) then
			walk(a, Tasks.nearCustomer(c))
			local e = customerEntity(c)
			local ok = false
			if e and c.state == "waiting" then
				ok = Core.S.Customers.use(a, e)
			end
			Tasks.release(c, a)
			if ok then
				return true
			end
		end
	end
	return false
end

local function doServe(a)
	local station, c = Tasks.findServe(a.plot)
	if not station then
		return false
	end
	local st = Core.S.Cooking.stationState(station)
	if not Tasks.claim(st, a) then
		return false
	end
	Tasks.claim(c, a)
	walk(a, Tasks.frontOf(station))
	local ok = Core.S.Cooking.use(a, station, speed(a))
	Tasks.release(st, a)
	Tasks.release(c, a)
	if not ok then
		return true
	end
	local h = Core.S.Hands.get(a)
	local recipe = h.items[1] and h.items[1].recipe
	if recipe and not deliverDish(a, recipe) then
		dropHands(a)
	end
	return true
end

local function nearestOf(plot, kind, pos)
	local best, bestD = nil, math.huge
	for _, e in ipairs(Core.S.Entities.ofKind(kind, plot)) do
		local p = Core.S.Entities.position(e)
		local dd = (p - pos).Magnitude
		if dd < bestD then
			best, bestD = e, dd
		end
	end
	return best
end

local function washHeld(a)
	local Appliance = Core.S.Appliance
	local pos = a.npc.root and a.npc.root.Position or Vector3.new()
	local washer = nearestOf(a.plot, "dishwasher", pos)
	if washer then
		walk(a, Tasks.frontOf(washer))
		Appliance.useDishwasher(a, washer)
		return
	end
	local hasDishwasherStaff = false
	for _, other in pairs(actors) do
		if other.plot == a.plot and other.role == "staff_dishwasher" and other ~= a then
			hasDishwasherStaff = true
		end
	end
	local sink = nearestOf(a.plot, "sink", pos)
	if not sink then
		return dropHands(a)
	end
	walk(a, Tasks.frontOf(sink))
	if hasDishwasherStaff and a.role ~= "staff_dishwasher" then
		local n = Core.S.Hands.count(a)
		Core.S.Hands.clear(a)
		Appliance.addDirtyToSink(a.plot, n)
	else
		Appliance.useSink(a, sink, speed(a))
	end
end

local function doCollect(a)
	local e = Tasks.findDirty(a.plot)
	if not e or not Tasks.claim(e, a) then
		return false
	end
	walk(a, Core.S.Entities.position(e))
	if Core.S.Entities.get(e.uid) then
		Core.S.Customers.collectDirty(a, e)
	end
	Tasks.release(e, a)
	-- grab more while there is room, then wash
	local Hands = Core.S.Hands
	while Hands.count(a) < Hands.capacity(a, "dirty") do
		local nxt = Tasks.findDirty(a.plot)
		if not nxt or not Tasks.claim(nxt, a) then
			break
		end
		walk(a, Core.S.Entities.position(nxt))
		if Core.S.Entities.get(nxt.uid) then
			Core.S.Customers.collectDirty(a, nxt)
		end
		Tasks.release(nxt, a)
	end
	if Hands.get(a).kind == "dirty" then
		washHeld(a)
	end
	return true
end

local function doWash(a)
	local Appliance = Core.S.Appliance
	if Appliance.sinkPile(a.plot) <= 0 or #Core.S.Entities.ofKind("dishwasher", a.plot) > 0 then
		return false
	end
	local sink = nearestOf(a.plot, "sink", a.npc.root.Position)
	if not sink or not Tasks.claim(sink, a) then
		return false
	end
	walk(a, Tasks.frontOf(sink))
	Appliance.useSink(a, sink, speed(a))
	Tasks.release(sink, a)
	return true
end

local function carryBoxTo(a, box, targetEntity, useFn)
	local Supply = Core.S.Supply
	if not Tasks.claim(box, a) then
		return false
	end
	local _, boxEntity = Supply.findBox(a.plot, box.g)
	local boxModel = boxEntity and boxEntity.model
	if boxModel then
		walk(a, boxModel:GetPivot().Position)
	end
	local ent = Core.S.Entities.get(box.u)
	if not ent or box.h then
		Tasks.release(box, a)
		return false
	end
	Supply.takeBox(a, ent)
	Tasks.release(box, a)
	walk(a, Tasks.frontOf(targetEntity))
	useFn()
	-- leftover portions go back to the storage room
	local h = Core.S.Hands.get(a)
	if h.kind == "box" then
		dropHands(a)
	end
	return true
end

local function doRestock(a)
	local box, g = Tasks.findRestock(a.plot)
	if not box then
		return false
	end
	local Ingredients = require(Shared.Config.Ingredients)
	local ing = Ingredients.byId[g]
	-- target shelf: neta case for fish when available
	local target = nil
	for _, e in ipairs(Core.S.Entities.ofKind("shelf", a.plot)) do
		if ing.storage == "fish" and e.item.fn.fishOnly then
			target = e
			break
		end
	end
	if not target then
		for _, e in ipairs(Core.S.Entities.ofKind("shelf", a.plot)) do
			if not e.item.fn.fishOnly then
				target = e
				break
			end
		end
	end
	if not target then
		return false
	end
	return carryBoxTo(a, box, target, function()
		-- one slot per click: keep going while the box has products and the shelf has room
		for _ = 1, 4 do
			local h = Core.S.Hands.get(a)
			if h.kind ~= "box" or not Core.S.Supply.useShelf(a, target, nil) then
				break
			end
		end
	end)
end

local function doRefill(a, kinds)
	local e, box = Tasks.findRefill(a.plot, kinds)
	if not e or not Tasks.claim(e, a) then
		return false
	end
	local ok = carryBoxTo(a, box, e, function()
		Core.S.Appliance.load(a, e)
	end)
	Tasks.release(e, a)
	return ok
end

local function doCook(a)
	local t, recipe, station = Tasks.findCook(a.plot, a.cfg.stations or {})
	if not t then
		return false
	end
	local st = Core.S.Cooking.stationState(station)
	if not Tasks.claim(st, a) then
		return false
	end
	t.claimed = a
	-- at the station: the first press fetches the ingredients from the shelves, then one press
	-- per step until the dish is on its plate
	walk(a, Tasks.frontOf(station))
	local ok = Core.S.Cooking.use(a, station, speed(a))
	local guard = 0
	while ok and not st.ready and guard < 8 do
		guard += 1
		ok = Core.S.Cooking.use(a, station, speed(a))
	end
	Tasks.release(st, a)
	local readyNow = st.ready
	if not readyNow then
		t.claimed = nil
		return ok
	end
	-- serve it ourselves when there are no waiters
	local hasWaiter = false
	for _, other in pairs(actors) do
		if other.plot == a.plot and other.role == "staff_waiter" then
			hasWaiter = true
		end
	end
	if not hasWaiter then
		Core.S.Cooking.use(a, station, speed(a))
		local h = Core.S.Hands.get(a)
		if h.kind == "dish" then
			if not deliverDish(a, h.items[1].recipe) then
				dropHands(a)
			end
		end
	end
	return true
end

local JOBS = {
	order = doOrder,
	serve = doServe,
	collect = doCollect,
	wash = doWash,
	restock = doRestock,
	cook = doCook,
}

local function think(a)
	local priorities = {
		staff_waiter = { "serve", "order", "collect", "wash" },
		staff_dishwasher = { "wash", "collect" },
		staff_stocker = { "appliance", "restock" },
		staff_sushi_chef = { "cook", "appliance_rice" },
		staff_ramen_chef = { "cook", "appliance_pot" },
		staff_line_cook = { "cook" },
		staff_manager = {},
	}
	for _, job in ipairs(priorities[a.role] or {}) do
		local done = false
		if job == "appliance" then
			done = doRefill(a, { "ricecooker", "pot" })
		elseif job == "appliance_rice" then
			done = doRefill(a, { "ricecooker" })
		elseif job == "appliance_pot" then
			done = doRefill(a, { "pot" })
		elseif JOBS[job] then
			done = JOBS[job](a)
		end
		if done then
			return true
		end
	end
	return false
end

------------------------------------------------------------------ actors

local function spawnActor(plot, record, index)
	local cfg = StaffCfg.byId[record.role]
	if not cfg then
		return
	end
	-- the uniform (chef jacket, happi coat, rubber apron...) comes from People.staff by role
	local npc = Core.S.Npc.create({ look = "casual", shirt = cfg.shirt, staff = record.role, speed = GameConfig.StaffWalkSpeed })
	if not npc then
		return
	end
	npc.isStaff = true
	local a = { uid = record.u, role = record.role, cfg = cfg, lvl = record.lvl or 1, name = record.name, npc = npc, model = npc.model, alive = true, index = index, record = record, plot = plot }
	actors[record.u] = a
	npc.model:SetAttribute("StaffName", record.name)
	npc.model:SetAttribute("StaffRole", record.role)
	npc.model:SetAttribute("StaffLevel", a.lvl)
	npc.model:SetAttribute("PlotId", plot.id)
	Core.S.Npc.spawn(npc, CFrame.new(homeOf(a) + Vector3.new(0, 3, 0)))
	task.spawn(function()
		while a.alive do
			-- the restaurant is always open: staff always work
			local ok, did = pcall(function()
				return think(a)
			end)
			if not ok then
				warn("[Staff] " .. tostring(did))
				pcall(dropHands, a)
				task.wait(2)
			elseif not did then
				idleAt(a)
			else
				task.wait(0.2)
			end
		end
	end)
	return a
end

local function despawnActor(uid)
	local a = actors[uid]
	if not a then
		return
	end
	a.alive = false
	pcall(dropHands, a)
	Core.S.Hands.forget(a)
	Core.S.Npc.destroy(a.npc)
	actors[uid] = nil
end

local function despawnPlot(plot)
	for uid, a in pairs(actors) do
		if a.plot == plot then
			despawnActor(uid)
		end
	end
end

function Staff.spawnAll(plot, d)
	despawnPlot(plot)
	for i, rec in ipairs(d.staff) do
		spawnActor(plot, rec, i)
	end
end

-- the restaurant a player manages right now (hiring, training, firing)
local function managed(player)
	local Plots = Core.S.Plots
	local plot = Plots.of(player)
	if plot and Plots.canBuild(player, plot) then
		return plot, Plots.data(plot)
	end
	return nil
end

local function hire(player, role)
	local Net, Economy = Core.S.Net, Core.S.Economy
	local plot, d = managed(player)
	if not plot then
		return Net.notify(player, "msg.no_permission", nil, "error")
	end
	local cfg = StaffCfg.byId[role]
	if not d or not cfg then
		return
	end
	if d.level < cfg.lv then
		return Net.notify(player, "msg.need_level", { level = cfg.lv }, "error")
	end
	if #d.staff >= Core.S.Progression.staffSlots(d) then
		return Net.notify(player, "msg.staff_full", nil, "error")
	end
	if cfg.manager then
		for _, s in ipairs(d.staff) do
			if s.role == role then
				return Net.notify(player, "msg.staff_one_manager", nil, "error")
			end
		end
	end
	if not Economy.spend(plot.owner, cfg.hire, "build", "staff:" .. cfg.id) then
		return Net.notify(player, "msg.not_enough", nil, "error")
	end
	local rec = { u = Uid.new("s"), role = role, lvl = 1, name = StaffCfg.Names[math.random(1, #StaffCfg.Names)] }
	table.insert(d.staff, rec)
	spawnActor(plot, rec, #d.staff)
	Core.S.Data.changed(plot.owner, "staff")
	Core.S.Plots.notify(plot, "msg.staff_hired", { name = rec.name, role = "staff." .. role }, "success")
	Core.S.Meta.event(plot.owner, "staff", 1)
end

local function train(player, uid)
	local Net, Economy = Core.S.Net, Core.S.Economy
	local plot, d = managed(player)
	if not plot then
		return
	end
	for _, rec in ipairs(d.staff) do
		if rec.u == uid then
			if rec.lvl >= StaffCfg.MaxTrainLevel then
				return Net.notify(player, "msg.max_level", nil, "error")
			end
			local cfg = StaffCfg.byId[rec.role]
			local cost = Formulas.staffTrainCost(cfg.hire, rec.lvl + 1)
			if not Economy.spend(plot.owner, cost, "build", "train") then
				return Net.notify(player, "msg.not_enough", nil, "error")
			end
			rec.lvl += 1
			local a = actors[uid]
			if a then
				a.lvl = rec.lvl
				a.model:SetAttribute("StaffLevel", rec.lvl)
			end
			Core.S.Data.changed(plot.owner, "staff")
			return Net.notify(player, "msg.staff_trained", { name = rec.name, level = rec.lvl }, "success")
		end
	end
end

local function fire(player, uid)
	local plot, d = managed(player)
	if not plot then
		return
	end
	for i, rec in ipairs(d.staff) do
		if rec.u == uid then
			table.remove(d.staff, i)
			despawnActor(uid)
			Core.S.Data.changed(plot.owner, "staff")
			return
		end
	end
end

function Staff.Init()
	Tasks = Core.S.Tasks
	local Net = Core.S.Net
	Net.on("HireStaff", function(player, role)
		if type(role) == "string" then
			hire(player, role)
		end
	end, 2)
	Net.on("TrainStaff", function(player, uid)
		if type(uid) == "string" then
			train(player, uid)
		end
	end, 3)
	Net.on("FireStaff", function(player, uid)
		if type(uid) == "string" then
			fire(player, uid)
		end
	end, 3)
end

function Staff.Start()
	local Plots = Core.S.Plots
	Plots.Claimed:Connect(function(plot, _, d)
		task.delay(2, function()
			if plot.owner and Plots.data(plot) == d then
				Staff.spawnAll(plot, d)
			end
		end)
	end)
	Plots.Released:Connect(despawnPlot)
end

return Staff
