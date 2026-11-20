-- (slow) A bot plays a new restaurant for a few hours at about human speed (a walk of ~1.2 s between
-- two places) through the real remotes: it cooks and serves every order, washes, restocks the
-- shelves, refills the broth pot and the rice cooker, and buys the cheapest thing it can afford
-- (upgrades, recipes for the stations it has, rooms, renovations, staff). It prints when every
-- level and every purchase came, the gaps between purchases, the first hire and when the
-- franchise opens up, and checks the pacing goals (Phase 6): something to buy every few minutes
-- at the start, a first member of staff within ~20 minutes, the franchise within ~4 hours.
--   python3 tools/sim.py progression            (Sim.progressionHours to change the length)
local HOURS = Sim.progressionHours or 3
local WALK = 1.2
Sim.startServer()
task.wait(1)
local S = Sim.core().S
local Recipes = Sim.shared("Config.Recipes")
local Ingredients = Sim.shared("Config.Ingredients")
local Upgrades = Sim.shared("Config.Upgrades")
local Ads = Sim.shared("Config.Ads")
local Licenses = Sim.shared("Config.Licenses")
local Expansions = Sim.shared("Config.Expansions")
local StaffCfg = Sim.shared("Config.Staff")
local GameConfig = Sim.shared("Config.GameConfig")
local FranchiseCfg = Sim.shared("Config.Franchise")
local Shop = Sim.shared("Logic.Shop")
local p = Sim.addPlayer({ name = "Bot" })
local d = Sim.waitFor(function()
	return S.Data.get(p)
end, 30)
local plot = Sim.waitFor(function()
	return S.Plots.ofPlayer(p)
end, 30)
d.meta.tutorial = -1
local t0 = Sim.now
local function mins()
	return (Sim.now - t0) / 60
end

local function goTo(model)
	local pos = model:GetPivot().Position
	local from = pos + Vector3.new(0, 0, -3)
	p.Character:PivotTo(CFrame.lookAt(from, Vector3.new(pos.X, from.Y, pos.Z)))
	task.wait(WALK)
end
local function interact(e, extra)
	Sim.fire(p, "Interact", e.uid, extra or {})
	task.wait(0.25)
end
local function hands()
	return S.Hands.get(p)
end
local function free()
	return #hands().items == 0
end

-- the station types the restaurant has
local function stationTypes()
	local out = {}
	for _, e in ipairs(S.Entities.ofKind("station", plot)) do
		out[e.item.fn.station] = true
	end
	return out
end

------------------------------------------------------------------ jobs
local function serveDish()
	local h = hands()
	if h.kind ~= "dish" then
		return false
	end
	local item = h.items[1]
	local want = type(item) == "table" and item.recipe or item
	for _, c in pairs(S.Customers.active) do
		if c.plot == plot and c.order == want and (c.state == "waiting" or c.state == "order") and c.npc and c.npc.model then
			local e = S.Entities.get(c.uid)
			if e then
				goTo(e.model)
				interact(e)
				return true
			end
		end
	end
	-- nobody wants it any more: put it down
	Sim.fire(p, "DropHands")
	task.wait(0.3)
	return true
end

local function takeReady()
	if not free() then
		return false
	end
	for _, e in ipairs(S.Entities.ofKind("station", plot)) do
		if (e.model:GetAttribute("Ready") or "") ~= "" then
			goTo(e.model)
			interact(e)
			return true
		end
	end
	return false
end

local function cook()
	if not free() then
		return false
	end
	local types = stationTypes()
	for _, tk in ipairs(S.Cooking.ticketsOf(plot)) do
		local r = Recipes.byId[tk.recipe]
		if r and types[r.station] and not tk.claimed then
			for _, e in ipairs(S.Entities.ofKind("station", plot)) do
				if e.item.fn.station == r.station and (e.model:GetAttribute("Ready") or "") == "" and (e.model:GetAttribute("Missing") or "") == "" then
					goTo(e.model)
					for _ = 1, 8 do
						interact(e)
						Sim.waitFor(function()
							return not e.model:GetAttribute("Busy")
						end, 10)
						if (e.model:GetAttribute("Ready") or "") ~= "" then
							break
						end
						if (e.model:GetAttribute("Missing") or "") ~= "" then
							return false
						end
					end
					interact(e) -- take the dish
					return true
				end
			end
		end
	end
	return false
end

local function clearDirty()
	if not free() then
		return false
	end
	local dirty = S.Entities.ofKind("dirty", plot)[1]
	if not dirty then
		return false
	end
	goTo(dirty.model)
	interact(dirty)
	local sink = S.Entities.ofKind("sink", plot)[1]
	if sink and hands().kind == "dirty" then
		goTo(sink.model)
		interact(sink)
	end
	return true
end

local function wash()
	local sink = S.Entities.ofKind("sink", plot)[1]
	if not sink or not free() or (plot.folder:GetAttribute("SinkPile") or 0) < 3 then
		return false
	end
	goTo(sink.model)
	Sim.fire(p, "Wash", sink.uid, true)
	Sim.waitFor(function()
		return (plot.folder:GetAttribute("SinkPile") or 0) == 0
	end, 40)
	Sim.fire(p, "Wash", sink.uid, false)
	return true
end

-- what the menu needs: ingredients on the shelves, broth in the pot, rice in the cooker
local lastOrder = -math.huge
local function needs()
	local types = stationTypes()
	local shelf, broth, rice = {}, {}, false
	for id, m in pairs(d.menu) do
		local r = Recipes.byId[id]
		if r and m.on and S.Progression.isRecipeUnlocked(d, r) and types[r.station] then
			for _, g in ipairs(r.ing) do
				shelf[g] = true
			end
			if r.broth then
				broth[r.broth] = true
			end
			if r.rice then
				rice = true
			end
		end
	end
	return shelf, broth, rice
end

local tried = {} -- [ingredient] = when the bot last carried a box of it (once every 30 s)
local function restock()
	if not free() then
		return false
	end
	local shelf, broth, rice = needs()
	local low = {}
	local function want(g)
		if Sim.now - (tried[g] or -math.huge) > 30 then
			table.insert(low, g)
		end
	end
	for g in pairs(shelf) do
		if S.Supply.shelfStock(plot, g) < 5 then
			want(g)
		end
	end
	for g in pairs(broth) do
		if not S.Appliance.willHave(plot, "pot", g) then
			want(g)
		end
	end
	if rice and not S.Appliance.willHave(plot, "ricecooker") then
		want("rice")
	end
	if #low == 0 then
		return false
	end
	for _, g in ipairs(low) do
		local _, box = S.Supply.findBox(plot, g)
		if box and box.model then
			tried[g] = Sim.now
			goTo(box.model)
			interact(box)
			local target
			if Ingredients.byId[g].kind == "broth" or broth[g] then
				target = S.Entities.ofKind("pot", plot)[1]
			elseif g == "rice" then
				target = S.Entities.ofKind("ricecooker", plot)[1]
			else
				target = S.Supply.findShelfWith(plot, g) or S.Entities.ofKind("shelf", plot)[1]
			end
			if target then
				goTo(target.model)
				interact(target)
			end
			-- full: like a player, try the other shelves
			if not free() and hands().kind == "box" and target and target.kind == "shelf" then
				for _, sh in ipairs(S.Entities.ofKind("shelf", plot)) do
					if sh ~= target and not free() then
						goTo(sh.model)
						interact(sh)
					end
				end
			end
			if not free() then
				local rack = S.Entities.ofKind("rack", plot)[1]
				if rack then
					goTo(rack.model)
					interact(rack)
				end
				if not free() then
					Sim.fire(p, "DropHands")
					task.wait(0.3)
				end
			end
			return true
		end
	end
	-- nothing in storage: order a box of each (at most every 20 s)
	if Sim.now - lastOrder > 20 then
		lastOrder = Sim.now
		local cart = {}
		for _, g in ipairs(low) do
			cart[g] = { small = 1, big = 0 }
		end
		local supplier = S.Entities.get("fixed_supplier_" .. plot.id)
		if supplier then
			goTo(supplier.model)
		end
		Sim.fire(p, "OrderSupplies", cart)
		task.wait(0.5)
	end
	return false
end

------------------------------------------------------------------ buying
local CFG = { Upgrades = Upgrades, Ads = Ads, Licenses = Licenses, Expansions = Expansions, Staff = StaffCfg, MaxStaff = GameConfig.MaxStaff }
local bought = {}
local function log(kind, id, price)
	table.insert(bought, { t = mins(), kind = kind, id = id, price = price, level = d.level })
end

local function options()
	local out = {}
	local rating = S.Progression.rating(plot)
	local types = stationTypes()
	for _, u in ipairs(Upgrades.list) do
		local st = Shop.upgrade(d, u)
		if st.state == "buy" or st.state == "poor" then
			table.insert(out, { kind = "upgrade", id = u.id, price = st.price, remote = "BuyUpgrade" })
		end
	end
	for _, lic in ipairs(Licenses.list) do
		local st = Shop.license(d, lic, rating)
		local usable = true
		for _, rid in ipairs(lic.recipes) do
			local r = Recipes.byId[rid]
			if r and not types[r.station] then
				usable = false
			end
		end
		if usable and (st.state == "buy" or st.state == "poor") then
			table.insert(out, { kind = "license", id = lic.id, price = st.price, remote = "BuyLicense" })
		end
	end
	for _, e in ipairs(Expansions.list) do
		if e.id ~= "zone_base" then
			local st = Shop.expansion(d, e)
			if st.state == "buy" or st.state == "poor" then
				table.insert(out, { kind = e.reno and "reno" or "room", id = e.id, price = st.price, remote = "BuyExpansion" })
			end
		end
	end
	local slots = Shop.staffSlots(d, StaffCfg, GameConfig.MaxStaff)
	for _, s in ipairs(StaffCfg.list) do
		local st = Shop.hire(d, s, slots)
		if st.state == "buy" or st.state == "poor" then
			table.insert(out, { kind = "staff", id = s.id, price = st.price, remote = "HireStaff" })
		end
	end
	table.sort(out, function(a, b)
		return a.price < b.price
	end)
	return out
end

-- like a player who saves up for the first helper and for new rooms once they show up
local function buy()
	local list = options()
	local o = list[1]
	local goal = nil
	local hired = {}
	for _, s in ipairs(d.staff) do
		hired[s.role] = true
	end
	for _, x in ipairs(list) do
		if (x.kind == "staff" and not hired[x.id]) or x.kind == "room" then
			goal = goal or x
		end
	end
	-- one of each role is enough for this restaurant
	for i = #list, 1, -1 do
		if list[i].kind == "staff" and hired[list[i].id] then
			table.remove(list, i)
		end
	end
	o = list[1]
	if goal and goal.price <= d.yen * 3 then
		o = goal
	end
	if not o or d.yen - o.price < 300 then
		return false
	end
	local before = d.yen
	Sim.fire(p, o.remote, o.id)
	task.wait(2)
	if d.yen < before then
		log(o.kind, o.id, o.price)
		return true
	end
	return false
end

------------------------------------------------------------------ furnishing
-- like a player, the bot fills new dining rooms with seats: a table for two with its chairs
-- (from level 3), then tables with built-in benches for four (from level 7)
local Items = Sim.shared("Config.Items")
local PlacementLogic = Sim.shared("Logic.Placement")
local function valid(req)
	local ok = PlacementLogic.validate(S.World.ctx(plot, d.placed), req)
	return ok
end
local function placeAt(req)
	local n = #d.placed
	Sim.fire(p, "PlaceItem", req)
	task.wait(0.4)
	return #d.placed > n
end
local function furnish()
	local level, yen = d.level, d.yen
	local unit, cost, chairs
	if level >= Items.byId.bench_table.lv then
		unit, cost = "bench_table", Items.byId.bench_table.price
	elseif level >= Items.byId.table_2.lv and level >= Items.byId.chair_wood.lv then
		unit, cost, chairs = "table_2", Items.byId.table_2.price + 2 * Items.byId.chair_wood.price, true
	end
	if not unit or yen - cost < 300 then
		return false
	end
	-- dining rooms other than the starting one, with fewer than 12 seats placed by the bot
	for _, z in ipairs(S.World.geo(plot).zones) do
		if z.area == "dining" and z.floor == 0 and z.id ~= "base_dining" then
			local count = 0
			for _, e in ipairs(d.placed) do
				local item = Items.byId[e.i]
				if item and item.fn and (item.fn.type == "booth" or item.fn.type == "table") and S.World.zoneAt(plot, e.x, e.z, 0) == z then
					count += 1
				end
			end
			if count < 4 then
				local r = z.rect
				for x = r[1] + 4, r[3] - 4, 3 do
					for zz = r[2] + 4, r[4] - 4, 3 do
						local req = { i = unit, x = x, z = zz, r = 0, f = 0, s = "f" }
						local ok = valid(req)
						if ok and chairs then
							ok = valid({ i = "chair_wood", x = x - 2.5, z = zz, r = 90, f = 0, s = "f" }) and valid({ i = "chair_wood", x = x + 2.5, z = zz, r = 270, f = 0, s = "f" })
						end
						if ok then
							local placed = placeAt(req)
							if placed and chairs then
								placeAt({ i = "chair_wood", x = x - 2.5, z = zz, r = 90, f = 0, s = "f" })
								placeAt({ i = "chair_wood", x = x + 2.5, z = zz, r = 270, f = 0, s = "f" })
							end
							if placed then
								log("seats", unit, cost)
								return true
							end
						end
					end
				end
			end
		end
	end
	return false
end

------------------------------------------------------------------ play
local levels = {}
local lastLevel = d.level
local firstStaff, franchiseAt, franchiseNoRating = nil, nil, nil
local step1 = FranchiseCfg.nextStep(0)
local function levelAndRooms()
	if d.level < step1.level then
		return false
	end
	for _, z in ipairs(step1.zones) do
		if not d.zones[z] then
			return false
		end
	end
	return true
end
local lastBuyCheck = 0
local lastClaim = 0
-- how long the shop had nothing the bot could buy (what a player sees as the shop badge at 0)
local dryFor, dryMax60, lastDry = 0, 0, Sim.now
-- quests, timed gifts and achievements are claimed like a player taps them in the HUD
local function claim()
	for _, q in ipairs(d.meta.quests or {}) do
		if not q.claimed and q.progress >= q.target then
			Sim.fire(p, "ClaimQuest", q.id)
		end
	end
	for i = 1, 9 do
		Sim.fire(p, "ClaimGift", i)
	end
	for id in pairs(d.meta.achievements or {}) do
		Sim.fire(p, "ClaimAchievement", id)
	end
	task.wait(0.3)
end
local endAt = Sim.now + HOURS * 3600
local spent = {}
local function timed(name, fn)
	local a = Sim.now
	local r = fn()
	if r then
		spent[name] = (spent[name] or 0) + (Sim.now - a)
	end
	return r
end
while Sim.now < endAt do
	local did = timed("serve", serveDish) or timed("take", takeReady) or timed("cook", cook) or timed("dirty", clearDirty) or timed("wash", wash) or timed("restock", restock)
	if Sim.now - lastClaim > 30 then
		lastClaim = Sim.now
		claim()
	end
	if Sim.now - lastBuyCheck > 10 and free() then
		lastBuyCheck = Sim.now
		while buy() do
		end
		furnish()
	end
	if not did then
		task.wait(0.5)
	end
	if d.level ~= lastLevel then
		lastLevel = d.level
		table.insert(levels, { level = d.level, t = mins() })
	end
	if Sim.now - lastDry >= 10 then
		local total = Shop.buyable(d, CFG, S.Progression.rating(plot))
		if total == 0 then
			dryFor += Sim.now - lastDry
		else
			if dryFor >= 180 then
				Sim.say(string.format("  nothing to buy from %.0fm to %.0fm (¥%d, L%d)", mins() - dryFor / 60, mins(), math.floor(d.yen), d.level))
			end
			dryFor = 0
		end
		if mins() <= 60 then
			dryMax60 = math.max(dryMax60, dryFor / 60)
		end
		lastDry = Sim.now
	end
	if not firstStaff and #d.staff > 0 then
		firstStaff = mins()
	end
	if not franchiseAt and S.Franchise.check(d, plot) then
		franchiseAt = mins()
	end
	if not franchiseNoRating and levelAndRooms() then
		franchiseNoRating = mins()
	end
end

------------------------------------------------------------------ report
Sim.say(string.format("=== %.1f h of play: level %d, ¥%d, %d dishes, %d purchases, rating %.2f, %d staff", HOURS, d.level, math.floor(d.yen), d.stats.dishes, #bought, S.Progression.rating(plot), #d.staff))
local line = {}
for _, l in ipairs(levels) do
	table.insert(line, string.format("L%d %.0fm", l.level, l.t))
end
Sim.say("levels: " .. table.concat(line, " · "))
-- the economy: what the restaurant earned (sales and tips) for every point of XP, and the days
local Formulas = Sim.shared("Logic.Formulas")
local totalXp = d.xp
for l = 1, d.level - 1 do
	totalXp += Formulas.xpForLevel(l)
end
local days = {}
for _, v in ipairs(d.stats.dayHistory or {}) do
	table.insert(days, tostring(math.floor(v)))
end
Sim.say(string.format("earned ¥%d (sales and tips) for %d XP: ¥%.1f per XP; last days ¥%s", math.floor(d.stats.earned), totalXp, d.stats.earned / math.max(totalXp, 1), table.concat(days, ", ¥")))
local sp = {}
for k, v in pairs(spent) do
	table.insert(sp, string.format("%s %.0fs", k, v))
end
table.sort(sp)
Sim.say("time spent: " .. table.concat(sp, ", "))
local left = 0
for _, k in ipairs(Sim.noticesFor(p)) do
	if k == "msg.customer_left" then
		left += 1
	end
end
local hist = {}
for _, r in ipairs(d.reviews.recent or {}) do
	hist[r.s] = (hist[r.s] or 0) + 1
end
local hl = {}
for st = 1, 5, 0.5 do
	if hist[st] then
		table.insert(hl, st .. "★×" .. hist[st])
	end
end
Sim.say(string.format("customers served %d, left %d; last reviews %s", math.floor(d.stats.customers or 0), left, table.concat(hl, " ")))
local gaps, last, maxGap60 = {}, 0, 0
for _, b in ipairs(bought) do
	local gap = b.t - last
	if b.t <= 60 then
		maxGap60 = math.max(maxGap60, gap)
	end
	last = b.t
	table.insert(gaps, string.format("%.0fm %s %s ¥%d (L%d)", b.t, b.kind, b.id, math.floor(b.price), b.level))
end
for _, g in ipairs(gaps) do
	Sim.say("  bought " .. g)
end
Sim.say(string.format("first staff at %s min · franchise level and rooms at %s min (with the rating: %s min) · longest wait between two purchases in the first hour %.1f min",
	firstStaff and string.format("%.0f", firstStaff) or "-", franchiseNoRating and string.format("%.0f", franchiseNoRating) or "-", franchiseAt and string.format("%.0f", franchiseAt) or "-", maxGap60))
Sim.say(string.format("longest time with nothing in the shop the bot could afford, first hour: %.1f min", dryMax60))
-- (shop items only: decorations in the build catalog fill the gaps for a player)
Sim.check("something to buy every few minutes in the first hour", dryMax60 <= 8, string.format("%.1f min", dryMax60))
Sim.check("first member of staff within ~20 minutes", firstStaff ~= nil and firstStaff <= 25, tostring(firstStaff))
if HOURS >= 4 then
	-- the bot does not decorate, so its rating stays lower than a player's: the level and the rooms
	Sim.check("the franchise level and rooms within ~4 hours", franchiseNoRating ~= nil and franchiseNoRating <= 4 * 60, tostring(franchiseNoRating))
end
