--!nonstrict
-- Customers of every restaurant (c.plot): arrive along the street, take a seat, order by
-- themselves, wait (patience), pay when served, eat, review, leave.
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local Customers = require(Shared.Config.Customers)
local Recipes = require(Shared.Config.Recipes)
local Expansions = require(Shared.Config.Expansions)
local StaffCfg = require(Shared.Config.Staff)
local Formulas = require(Shared.Logic.Formulas)
local TableUtil = require(Shared.Util.TableUtil)
local Registry = require(Shared.Models.Registry)
local Uid = require(Shared.Util.Uid)
local Core = require(script.Parent.Parent.Core)

local Service = {}
Service.active = {} -- [uid] = customer (c.plot = its restaurant)
local rng = Random.new()

local CFG = GameConfig.Customers
local RewardsCfg = require(Shared.Config.Rewards)
local MAIN = { sushi = true, ramen = true }

local function pdata(plot)
	return Core.S.Plots.data(plot)
end

------------------------------------------------------------------ menu availability

function Service.availableMenu(plot)
	if plot.menuCache and os.clock() - (plot.menuCacheTime or 0) < 2 then
		return plot.menuCache
	end
	local d = pdata(plot)
	local out = {}
	if not d then
		return out
	end
	local Supply, Appliance = Core.S.Supply, Core.S.Appliance
	local stations = {}
	for _, e in ipairs(Core.S.Entities.ofKind("station", plot)) do
		stations[e.item.fn.station] = true
	end
	for _, r in ipairs(Core.S.Progression.menuRecipes(d)) do
		local ok = stations[r.station] == true
		if ok then
			for _, g in ipairs(r.ing) do
				if Supply.shelfStock(plot, g) <= 0 and Supply.boxCount(plot, g) <= 0 then
					ok = false
					break
				end
			end
		end
		if ok and r.rice and not (Appliance.willHave(plot, "ricecooker") or Supply.boxCount(plot, "rice") > 0) then
			ok = false
		end
		if ok and r.broth and not (Appliance.willHave(plot, "pot", r.broth) or Supply.boxCount(plot, r.broth) > 0) then
			ok = false
		end
		if ok then
			table.insert(out, r)
		end
	end
	plot.menuCache, plot.menuCacheTime = out, os.clock()
	return out
end

local function chooseOrder(c, mainOnly)
	local d = pdata(c.plot)
	if not d then
		return nil
	end
	local menu = Service.availableMenu(c.plot)
	local list = {}
	for _, r in ipairs(menu) do
		local isMain = MAIN[r.cat] == true
		if (mainOnly and isMain) or (not mainOnly and not isMain) then
			table.insert(list, r)
		end
	end
	if #list == 0 then
		if mainOnly then
			list = menu
		else
			return nil
		end
	end
	local prefer = {}
	for _, p in ipairs(c.cfg.prefer) do
		prefer[p] = true
	end
	local pick = TableUtil.weightedPick(list, function(r)
		local m = d.menu[r.id]
		local w = Formulas.demandFactor(m and m.price or 1)
		if prefer[r.cat] then
			w *= 2
		end
		if prefer.cheap and r.price <= 60 then
			w *= 2
		end
		if prefer.expensive and r.price >= 150 then
			w *= 2.5
		end
		if prefer.mastery and Formulas.masteryLevel(d.mastery[r.id] or 0) >= 2 then
			w *= 3
		end
		return w
	end, rng)
	return pick
end

------------------------------------------------------------------ helpers

local placeOrder

local function setState(c, state)
	c.state = state
	if c.npc and c.npc.model then
		c.npc.model:SetAttribute("State", state)
	end
end

local function setOrder(c, recipe)
	c.order = recipe and recipe.id or nil
	if c.npc and c.npc.model then
		c.npc.model:SetAttribute("Order", c.order or "")
	end
	if recipe and c.plot then
		Core.S.Analytics.step(c.plot.owner, "first_order")
	end
end

-- puts the customer's order on the order bar; false when the bar is full
placeOrder = function(c)
	if c.state ~= "order" or not c.order then
		return false
	end
	local t = Core.S.Cooking.addTicket(c.plot, c.uid, c.order)
	if not t then
		return false
	end
	c.ticket = t
	-- a fresh, full timer for cooking it
	c.patience = c.patienceMax
	setState(c, "waiting")
	if c.npc and c.npc.root then
		Core.S.Net.fx("sfx", { name = "ticket", pos = c.npc.root.Position })
	end
	return true
end

local function patienceTick(c, dt)
	c.patience = math.max(0, c.patience - dt)
	c.minPatience = math.min(c.minPatience, c.patience / c.patienceMax)
	if c.npc and c.npc.model then
		c.npc.model:SetAttribute("Patience", c.patience / c.patienceMax)
	end
end

local function floorPos(seat)
	local p = seat.sit.Position
	local floorY = Core.S.World.floorY(seat.floor)
	local back = -seat.sit.LookVector * 1.4
	return Vector3.new(p.X + back.X, floorY + 0.5, p.Z + back.Z)
end

local function dirtyNear(plot, pos)
	for _, e in ipairs(Core.S.Entities.ofKind("dirty", plot)) do
		local p = Core.S.Entities.position(e)
		if p and (p - pos).Magnitude < 6 then
			return true
		end
	end
	return false
end

-- along the sidewalk, on one side of the restaurant's door
local function streetPoint(plot, side)
	local a, b = CFG.StreetSpawn[1], CFG.StreetSpawn[2]
	return Vector3.new(plot.origin.X + side * (a + rng:NextNumber() * (b - a)), 0, Expansions.StreetWalkZ)
end

local function entrance(plot)
	return Core.S.Plots.toWorld(plot, Expansions.Entrance.x + rng:NextNumber() * 2 - 1, 0, Expansions.Entrance.z - 1)
end

local function dishKind(recipeId)
	local r = Recipes.byId[recipeId]
	if r and (r.dish == "bowl" or r.dish == "soup" or r.dish == "tsukemen") then
		return "bowl"
	end
	return "plate"
end

------------------------------------------------------------------ lifecycle

local function release(c)
	c.gone = true
	Service.active[c.uid] = nil
	Core.S.Entities.unregister(c.uid)
	if c.ticket then
		Core.S.Cooking.removeTicket(c.plot, c.ticket.id)
		c.ticket = nil
	end
	if c.seat then
		c.seat.occupant = nil
		c.seat.reserved = nil
	end
	if c.dishModel then
		c.dishModel:Destroy()
		c.dishModel = nil
	end
	if c.bench then
		Core.S.Seating.freeBench(c.bench)
		c.bench = nil
	end
	if c.npc then
		c.npc.model:SetAttribute("State", nil)
		c.npc.model:SetAttribute("Order", nil)
		Core.S.Npc.release(c.npc)
		c.npc = nil
	end
end

local function leaveRestaurant(c)
	local Npc = Core.S.Npc
	setState(c, "leaving")
	setOrder(c, nil)
	if c.npc then
		Npc.stand(c.npc)
		Npc.walkTo(c.npc, entrance(c.plot))
		Npc.walkTo(c.npc, streetPoint(c.plot, c.side))
	end
	release(c)
end

local function review(c, walkedOut)
	local Progression, Economy = Core.S.Progression, Core.S.Economy
	local plot = c.plot
	if not pdata(plot) then
		return
	end
	local amb = Core.S.Placement.ambienceOf(plot)
	local pos = c.seat and c.seat.dish or Vector3.new()
	local stars = Formulas.review({
		left = walkedOut,
		patienceLeft = c.minPatience,
		dirtyNearby = dirtyNear(plot, pos),
		fresh = c.fresh,
		freshBonus = GameConfig.FreshReviewBonus,
		ambienceTier = amb.tier,
		comfort = c.seat and c.seat.comfort or 0,
	})
	Progression.addReview(plot, stars, c.cfg.reviewWeight or 1)
	local L = Economy.ledgerOf(plot)
	L.reviews += 1
	L.stars += stars
	if walkedOut then
		L.walkouts += 1
	else
		L.customers += 1
	end
	local owner = plot.owner
	Core.S.Net.fx("review", { stars = stars, pos = (c.npc and c.npc.root and c.npc.root.Position or pos) + Vector3.new(0, 3, 0), type = c.cfg.id })
	if not walkedOut then
		Core.S.Meta.event(owner, "customers", 1)
		if stars >= 4 then
			Core.S.Meta.event(owner, "happy", 1)
		end
		local d = pdata(plot)
		if not d then
			return
		end
		d.stats.customers += 1
		if stars >= 5 and c.cfg.reviewWeight then
			Economy.addSakura(owner, 3)
			Core.S.Plots.notify(plot, "msg.critic_happy", nil, "success")
		end
		if stars >= 5 and c.cfg.influencer then
			d.boosts.influencer = (d.stats.days or 0) + 2
			Core.S.Plots.notify(plot, "msg.influencer_happy", nil, "success")
		end
	else
		Core.S.Plots.notify(plot, "msg.customer_left", nil, "warning")
	end
end

local function pay(c, recipe)
	local plot = c.plot
	local d = pdata(plot)
	if not d then
		return
	end
	local Economy = Core.S.Economy
	local owner = plot.owner
	local amb = Core.S.Placement.ambienceOf(plot)
	local price = Core.S.Progression.priceOf(d, recipe)
	local tip = Formulas.tip(price, {
		fresh = c.fresh,
		freshBonus = GameConfig.FreshTipBonus,
		ambienceTip = amb.tip,
		comfort = c.seat and c.seat.comfort or 0,
		patienceLeft = c.patience / c.patienceMax,
		customerTip = c.cfg.tip,
		extraTip = (c.comboBonus or 0) + (c.perfect and GameConfig.NoodleTiming.TipBonus or 0),
	})
	local got = Economy.add(owner, price, "sale")
	-- with a tip jar on the counter the tip waits there until you collect it
	local gotTip = 0
	local inJar = Economy.tipToJar(plot, tip)
	if not inJar then
		gotTip = Economy.add(owner, tip, "tip")
	end
	local helper = c.servedBy
	if helper and typeof(helper) == "Instance" and helper ~= owner and helper.Parent then
		local share = math.floor((price + tip) * GameConfig.HelperRewardShare + 0.5)
		Economy.add(helper, share, "helper")
		Core.S.Progression.addXp(helper, math.floor(recipe.xp * 0.5))
	end
	Core.S.Analytics.step(owner, "first_serve")
	if (d.stats.customers or 0) >= 10 then
		Core.S.Analytics.step(owner, "served_10")
	end
	Core.S.Net.fx("money", { amount = got + gotTip, tip = gotTip, pos = (c.npc and c.npc.root and c.npc.root.Position or c.seat.dish) + Vector3.new(0, 3, 0) })
	Core.S.Net.fx("sfx", { name = "coin", pos = c.seat.dish })
	if gotTip > 0 then
		task.delay(0.35, function()
			Core.S.Net.fx("sfx", { name = "tip", pos = c.seat and c.seat.dish or Vector3.new() })
		end)
	end
end

local function eat(c, recipe)
	setState(c, "eating")
	local eatTime = CFG.EatTime[recipe.cat] or 10
	local total = eatTime * (0.85 + rng:NextNumber() * 0.3)
	if (recipe.cat == "ramen" or recipe.cat == "drink") and c.seat then
		-- noodles and soup are eaten with a proper slurp
		local where = c.seat.dish
		for _, at in ipairs({ 0.15, 0.45, 0.75 }) do
			task.delay(total * at, function()
				if c.state == "eating" then
					Core.S.Net.fx("sfx", { name = "slurp", pos = where })
				end
			end)
		end
	end
	task.wait(total)
	if c.dishModel then
		c.dishModel:Destroy()
		c.dishModel = nil
	end
	c.dishKind = dishKind(recipe.id)
	c.eaten += 1
end

local function leaveDirty(c)
	if not c.seat or c.eaten == 0 or not pdata(c.plot) then
		return
	end
	local m = Registry.food("dirty", c.dishKind or "plate")
	m:PivotTo(CFrame.new(c.seat.dish + Vector3.new(0, 0.3, 0)))
	m.Parent = Core.S.World.folders(c.plot).dynamic
	local uid = Uid.new("d")
	Core.S.Entities.register(uid, "dirty", m, { seat = c.seat, plot = c.plot })
	c.seat.dirty = uid
end

-- Main AI for one customer
local function run(c)
	local Npc = Core.S.Npc
	local Seating = Core.S.Seating
	local plot = c.plot
	-- walk in: the wind chime over the door rings
	Npc.walkTo(c.npc, entrance(plot))
	Core.S.Net.fx("sfx", { name = "chime", pos = entrance(plot) + Vector3.new(0, 7, 0) })
	-- wait in queue until a seat is free
	if not c.seat then
		setState(c, "queue")
		c.bench = Seating.benchSpot(plot, c.uid)
		if c.bench then
			Npc.walkTo(c.npc, c.bench.sit.Position)
			Npc.sit(c.npc, c.bench.sit)
		end
		local waited = 0
		while not c.seat and waited < 60 do
			task.wait(1)
			waited += 1
			if c.groupLeader == c and c.groupSeatsReady then
				break
			end
			if c.assignedSeat then
				c.seat = c.assignedSeat
			end
		end
		if c.bench then
			Npc.stand(c.npc)
			Seating.freeBench(c.bench)
			c.bench = nil
		end
		if not c.seat then
			return leaveRestaurant(c)
		end
	end
	setState(c, "walking")
	c.seat.occupant = c.uid
	Npc.walkTo(c.npc, floorPos(c.seat))
	Npc.sit(c.npc, c.seat.sit)
	setState(c, "reading")
	task.wait(rng:NextNumber() * (CFG.MenuReadTime[2] - CFG.MenuReadTime[1]) + CFG.MenuReadTime[1])
	local ordersLeft = c.cfg.ordersEach or 1
	local first = true
	while ordersLeft > 0 do
		local recipe = chooseOrder(c, first)
		if not recipe then
			break
		end
		setOrder(c, recipe)
		c.patience = c.patienceMax * (first and 1 or 0.85)
		setState(c, "order")
		-- the customer orders by themselves: the ticket goes on the order bar right away (when the
		-- bar is full they keep asking until there is room)
		placeOrder(c)
		while c.state == "order" or c.state == "waiting" do
			task.wait(0.5)
			if c.state == "order" then
				placeOrder(c)
			end
			patienceTick(c, 0.5)
			if c.patience <= 0 then
				review(c, true)
				if c.npc and c.npc.play then
					Npc.emote(c.npc, "wave")
				end
				return leaveRestaurant(c)
			end
		end
		if c.state ~= "served" then
			return leaveRestaurant(c)
		end
		eat(c, recipe)
		ordersLeft -= 1
		first = false
		if ordersLeft == 0 and c.eaten == 1 and rng:NextNumber() < CFG.ExtraOrderChance then
			ordersLeft = 1
		end
	end
	review(c, false)
	if c.npc then
		Npc.emote(c.npc, "cheer")
	end
	task.wait(0.8)
	leaveDirty(c)
	if c.seat then
		c.seat.occupant = nil
		c.seat.reserved = nil
	end
	leaveRestaurant(c)
end

local function spawnCustomer(plot, cfg, side, seat, group)
	-- in a family the third and fourth members are children
	local child = cfg.id == "cust_family" and group ~= nil and #group.members >= 2
	local npc = Core.S.Npc.acquireCustomer(cfg.look, child)
	if not npc then
		return nil
	end
	local uid = Uid.new("c")
	local amb = Core.S.Placement.ambienceOf(plot)
	local patience = cfg.patience
	local clock = Core.S.Day.clock or 12
	if cfg.lunchPatience and clock >= 12 and clock < 14 then
		patience = cfg.lunchPatience
	end
	patience = patience * (1 + amb.patience) * (CFG.PatienceMult or 1)
	local c = {
		uid = uid, cfg = cfg, npc = npc, seat = seat, side = side, state = "arriving", group = group,
		patienceMax = patience, patience = patience, minPatience = 1, eaten = 0, fresh = false, plot = plot,
	}
	Service.active[uid] = c
	Core.S.Entities.register(uid, "customer", npc.model, { customer = c, plot = plot })
	npc.model:SetAttribute("Type", cfg.id)
	npc.model:SetAttribute("Patience", 1)
	local start = streetPoint(plot, side)
	Core.S.Npc.spawn(npc, CFrame.new(start + Vector3.new(0, 3, 0)) * CFrame.Angles(0, math.rad(side > 0 and 90 or -90), 0))
	task.spawn(function()
		local ok, err = pcall(run, c)
		-- a customer removed while walking (the owner left) just stops
		if not ok and not c.gone then
			warn("[Customers] " .. tostring(err))
			release(c)
		end
	end)
	return c
end

local function pickType(plot, d)
	local list = {}
	local hasTables = false
	local hasVip = false
	for _, s in ipairs(Core.S.Seating.list(plot)) do
		if s.group and not s.vip then
			hasTables = true
		end
		if s.vip then
			hasVip = true
		end
	end
	for _, cfg in ipairs(Customers.list) do
		if d.level >= cfg.lv and (not cfg.needsTable or hasTables) and (not cfg.vip or hasVip) and (cfg.group[1] == 1 or hasTables or cfg.vip) then
			table.insert(list, cfg)
		end
	end
	local tourists = false
	for id, day in pairs(d.ads or {}) do
		if id == "ad_tv" and day == (d.stats.days or 0) + 1 then
			tourists = true
		end
	end
	return TableUtil.weightedPick(list, function(cfg)
		if tourists and cfg.id == "cust_tourist" then
			return cfg.weight * 2
		end
		return cfg.weight
	end, rng)
end

-- customers of a restaurant (alive)
local function countOf(plot)
	local n = 0
	for _, c in pairs(Service.active) do
		if c.plot == plot then
			n += 1
		end
	end
	return n
end

function Service.trySpawn(plot, forcedType)
	local d = pdata(plot)
	if not d then
		return false
	end
	if Core.S.Npc.count() >= CFG.MaxNpcs or countOf(plot) >= CFG.MaxPerRestaurant then
		return false
	end
	if #Service.availableMenu(plot) == 0 then
		if not plot.warnedMenu then
			plot.warnedMenu = true
			Core.S.Plots.notify(plot, "msg.no_menu", nil, "warning")
		end
		return false
	end
	plot.warnedMenu = false
	local cfg = forcedType and Customers.byId[forcedType] or pickType(plot, d)
	if not cfg then
		return false
	end
	local size = rng:NextInteger(cfg.group[1], cfg.group[2])
	local needsTable = cfg.needsTable or size > 1
	local seats = Core.S.Seating.find(plot, size, needsTable, cfg.vip == true)
	local side = rng:NextNumber() < 0.5 and -1 or 1
	if not seats then
		-- queue (only if there is room)
		plot.queue = plot.queue or {}
		local waiting = 0
		for _, g in ipairs(plot.queue) do
			waiting += #g.members
		end
		if waiting + size > CFG.BaseQueue + Core.S.Seating.queueCapacity(plot) then
			return false
		end
		local group = { members = {}, size = size, needsTable = needsTable, vip = cfg.vip == true }
		for _ = 1, size do
			local c = spawnCustomer(plot, cfg, side, nil, group)
			if c then
				table.insert(group.members, c)
			end
		end
		table.insert(plot.queue, group)
		return true
	end
	Core.S.Seating.reserve(seats, "pending")
	local group = { members = {} }
	for i = 1, size do
		local c = spawnCustomer(plot, cfg, side, seats[i], group)
		if c then
			seats[i].reserved = c.uid
			table.insert(group.members, c)
		else
			Core.S.Seating.release(seats[i])
		end
		task.wait(0.4)
	end
	if cfg.celebrity then
		Core.S.Plots.notify(plot, "msg.celebrity", nil, "success")
		task.spawn(function()
			for _ = 1, 4 do
				task.wait(2)
				Service.trySpawn(plot, "cust_student")
			end
		end)
	end
	return true
end

local function serveQueue(plot)
	local queue = plot.queue or {}
	for i = #queue, 1, -1 do
		local g = queue[i]
		local alive = {}
		for _, c in ipairs(g.members) do
			if Service.active[c.uid] and c.state == "queue" then
				table.insert(alive, c)
			end
		end
		if #alive == 0 then
			table.remove(queue, i)
		else
			local seats = Core.S.Seating.find(plot, #alive, g.needsTable and #alive > 1, g.vip)
			if seats then
				for k, c in ipairs(alive) do
					seats[k].reserved = c.uid
					c.assignedSeat = seats[k]
				end
				table.remove(queue, i)
			end
		end
	end
end

------------------------------------------------------------------ interaction

function Service.use(actor, e)
	local c = e.customer
	if not c then
		return false
	end
	local Hands = Core.S.Hands
	if c.state == "order" then
		if not placeOrder(c) then
			return false, "msg.tickets_full"
		end
		return true
	elseif c.state == "waiting" then
		local hands = Hands.get(actor)
		if hands.kind == "dish" and hands.plot and hands.plot ~= c.plot then
			return false, "msg.other_restaurant"
		end
		if hands.kind == "dish" then
			for i, dish in ipairs(hands.items) do
				if dish.recipe == c.order then
					Hands.removeAt(actor, i)
					Service.serve(c, dish, actor)
					return true
				end
			end
			return false, "msg.wrong_dish", { dish = "rec." .. c.order }
		end
		return false, "msg.customer_waits", { dish = "rec." .. c.order }
	elseif c.state == "reading" or c.state == "walking" then
		return false, "msg.customer_reading"
	end
	return false, "msg.customer_happy"
end

-- Serving combo: dishes served close together raise the tip (Config/Rewards.Combo), per restaurant
local function bumpCombo(c)
	local cfg = RewardsCfg.Combo
	c.plot.combo = c.plot.combo or { n = 0, last = -1e9 }
	local combo = c.plot.combo
	local now = os.clock()
	if now - combo.last <= cfg.Window then
		combo.n += 1
	else
		combo.n = 1
	end
	combo.last = now
	c.comboBonus = math.min(combo.n - 1, cfg.Max) * cfg.Step
	if combo.n >= 2 and c.seat then
		Core.S.Net.fx("combo", { n = combo.n, bonus = c.comboBonus, pos = c.seat.dish + Vector3.new(0, 4, 0) })
	end
end

function Service.serve(c, dish, actor)
	local recipe = Recipes.byId[dish.recipe]
	bumpCombo(c)
	if c.ticket then
		Core.S.Cooking.removeTicket(c.plot, c.ticket.id)
		c.ticket = nil
	end
	c.fresh = dish.fresh == true
	c.perfect = dish.perfect == true
	c.servedBy = actor
	local plot = c.plot
	local d = pdata(plot)
	if not d then
		return
	end
	local served = d.mastery[dish.recipe] or 0
	local m = Registry.food("dish", dish.recipe, Formulas.masteryLevel(served) >= #Formulas.MasteryThresholds)
	m:PivotTo(CFrame.new(c.seat.dish + Vector3.new(0, 0.5, 0)) * CFrame.Angles(0, math.rad(rng:NextInteger(0, 359)), 0))
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") then
			d.CanQuery = false
		end
	end
	m.Parent = Core.S.World.folders(plot).dynamic
	c.dishModel = m
	Core.S.Net.fx("sfx", { name = "plate", pos = c.seat.dish })
	setState(c, "served")
	local owner = plot.owner
	local L = Core.S.Economy.ledgerOf(plot)
	d.stats.dishes += 1
	L.served += 1
	L.bestDish[recipe.id] = (L.bestDish[recipe.id] or 0) + 1
	Core.S.Progression.addMastery(plot, recipe.id)
	Core.S.Progression.addXp(owner, recipe.xp)
	Core.S.Meta.event(owner, "serve", 1, { recipe = recipe.id })
	if recipe.cat == "sushi" then
		Core.S.Meta.event(owner, "serve_sushi", 1)
	elseif recipe.cat == "ramen" then
		Core.S.Meta.event(owner, "serve_ramen", 1)
	end
	Core.S.Data.changed(owner, "stats")
	-- paid on the spot: price and tip fly to the wallet the moment the dish lands
	pay(c, recipe)
	if c.npc and c.npc.root then
		Core.S.Net.fx("served", { pos = c.npc.root.Position + Vector3.new(0, 3.5, 0) })
	end
end

function Service.collectDirty(actor, e)
	local Hands = Core.S.Hands
	local ok, reason = Hands.add(actor, "dirty", { dish = "plate" }, e.plot)
	if not ok then
		return false, reason
	end
	if e.seat then
		e.seat.dirty = nil
	end
	Core.S.Entities.unregister(e.uid)
	if e.model then
		if e.model.PrimaryPart then
			Core.S.Net.fx("sfx", { name = "plate", pos = e.model.PrimaryPart.Position })
		end
		e.model:Destroy()
	end
	return true
end

-- customers of a restaurant in a state (for waiters)
function Service.list(plot, state)
	local out = {}
	for _, c in pairs(Service.active) do
		if c.plot == plot and c.state == state then
			table.insert(out, c)
		end
	end
	return out
end

function Service.sendAllHome(plot)
	for _, c in pairs(Service.active) do
		if c.plot == plot then
			c.state = "leaving"
		end
	end
end

-- the owner left: the customers of that restaurant vanish right away
local function removeAll(plot)
	for _, c in pairs(Service.active) do
		if c.plot == plot then
			c.state = "leaving"
			pcall(release, c)
		end
	end
	plot.queue = {}
end

------------------------------------------------------------------ loop

-- one restaurant's arrivals: an interval from its popularity, the rush hours and the night
local function tick(plot, dt)
	serveQueue(plot)
	local Day = Core.S.Day
	plot.spawnTimer = (plot.spawnTimer or 0) + dt
	if plot.firstAt and os.clock() >= plot.firstAt then
		plot.firstAt = nil
		plot.spawnTimer = math.huge
	end
	local d = pdata(plot)
	local pop = Core.S.Progression.popularity(plot)
	local days = (d and d.stats.days) or 0
	local peakFactor = days < (GameConfig.Day.EarlyDays or 0) and GameConfig.Day.EarlyPeakFactor or GameConfig.Day.PeakFactor
	local interval = Formulas.customerInterval(CFG.BaseInterval, CFG.MinInterval, pop, Day.isPeak(), peakFactor, Core.S.Economy.boostActive(plot, "rush"))
	if Core.S.Seating.freeCount(plot) == 0 then
		interval = interval * 1.5
	end
	-- a busy kitchen: with many orders still waiting, fewer people walk in, so the restaurant does
	-- not fill with customers nobody can cook for (every cook on the staff takes more)
	local cooks = 0
	for _, s in ipairs(d and d.staff or {}) do
		local cfg = StaffCfg.byId[s.role]
		if cfg and table.find(cfg.tasks, "cook") then
			cooks += 1
		end
	end
	if #Core.S.Cooking.ticketsOf(plot) >= CFG.BusyTickets + CFG.BusyTicketsPerCook * cooks then
		interval = interval * CFG.BusyFactor
	end
	if Day.isNight() then
		interval = interval * GameConfig.Day.NightFactor
	end
	-- closed with the sign by the door: nobody new comes in (the ones inside are served)
	if plot.spawnTimer >= interval and not plot.closed then
		plot.spawnTimer = 0
		local ok, err = pcall(Service.trySpawn, plot)
		if not ok then
			warn("[Customers] spawn failed: " .. tostring(err))
		end
	end
end

local function spawnLoop()
	while true do
		local dt = task.wait(0.5)
		for _, plot in ipairs(Core.S.Plots.list) do
			if plot.owner and pdata(plot) then
				tick(plot, dt)
			end
		end
	end
end

function Service.Start()
	local Plots = Core.S.Plots
	Plots.Claimed:Connect(function(plot)
		plot.queue = {}
		plot.spawnTimer = 0
		plot.firstAt = os.clock() + (CFG.FirstCustomerDelay or 2)
	end)
	Plots.Released:Connect(removeAll)
	task.spawn(spawnLoop)
end

return Service
