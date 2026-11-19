--!nonstrict
-- End-to-end self test of the core loop, started from the dev panel. It drives the real services
-- with an invisible worker: restock, broth, cook a shoyu ramen, serve a customer, get paid, wash.
-- Results go to the Output window and to a toast.
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local Ingredients = require(Shared.Config.Ingredients)
local Expansions = require(Shared.Config.Expansions)
local Registry = require(Shared.Models.Registry)
local PlacementLogic = require(Shared.Logic.Placement)
local Uid = require(Shared.Util.Uid)
local Core = require(script.Parent.Parent.Core)

local SelfTest = {}
local running = false

local function waitFor(fn, timeout)
	local t0 = os.clock()
	while os.clock() - t0 < timeout do
		local v = fn()
		if v then
			return v
		end
		task.wait(0.25)
	end
	return nil
end

function SelfTest.run(player)
	if running then
		return
	end
	running = true
	local S = Core.S
	local d = S.Session.ownerData()
	local actor = { uid = "selftest", alive = true, model = nil }
	local results = {}

	local function check(name, fn)
		local ok, err = pcall(fn)
		table.insert(results, { name = name, ok = ok, err = err })
		if ok then
			print("[SelfTest] PASS " .. name)
		else
			warn("[SelfTest] FAIL " .. name .. ": " .. tostring(err))
		end
		S.Hands.clear(actor)
		return ok
	end

	local function ensureBox(g)
		local entry = S.Supply.findBox(g)
		if not entry then
			table.insert(d.storage, { u = Uid.new("b"), g = g, n = Ingredients.byId[g].units })
			S.Supply.layout()
		end
		local e, ent = S.Supply.findBox(g)
		assert(e and ent, "no box entity for " .. g)
		return e, ent
	end

	local function returnLeftover()
		local h = S.Hands.get(actor)
		if h.kind == "box" then
			for _, b in ipairs(h.items) do
				S.Supply.returnBox(b)
			end
		end
		S.Hands.clear(actor)
	end

	local function firstOf(kind, filter)
		for _, e in ipairs(S.Entities.ofKind(kind)) do
			if not filter or filter(e) then
				return e
			end
		end
		return nil
	end

	check("world and starter objects", function()
		assert(#S.World.zones > 0, "no zones")
		assert(firstOf("shelf"), "no shelf")
		assert(firstOf("station", function(e)
			return e.item.fn.station == "sushi"
		end), "no sushi station")
		assert(firstOf("ricecooker"), "no rice cooker")
		assert(firstOf("sink"), "no sink")
		assert(firstOf("rack"), "no storage rack")
	end)

	check("seats around the counter", function()
		S.Seating.refresh()
		assert(#S.Seating.seats >= 6, "only " .. #S.Seating.seats .. " seats")
	end)

	check("restock a shelf", function()
		-- three noodles are used, then a box of noodles fills the free spots of that slot only
		local _, ent = ensureBox("noodles")
		for _ = 1, 3 do
			assert(S.Supply.takeIngredient("noodles"), "no noodles on the shelves")
		end
		local shelf = S.Supply.findShelfWith("noodles")
		assert(shelf, "no shelf with noodles")
		local before = S.Supply.shelfStock("noodles")
		assert(S.Supply.takeBox(actor, ent), "could not take the box")
		local ok, msg = S.Supply.useShelf(actor, shelf, nil)
		assert(ok, "useShelf: " .. tostring(msg))
		returnLeftover()
		local after = S.Supply.shelfStock("noodles")
		assert(after == before + 3, "the slot got " .. (after - before) .. " noodles instead of 3")
	end)

	check("pour the shoyu broth", function()
		local pot = firstOf("pot")
		assert(pot, "no broth pot")
		if not S.Appliance.hasBroth("broth_shoyu") then
			local _, ent = ensureBox("broth_shoyu")
			assert(S.Supply.takeBox(actor, ent), "could not take the broth box")
			local ok, msg = S.Appliance.load(actor, pot)
			assert(ok or msg == "msg.cooking_wait", "load: " .. tostring(msg))
			returnLeftover()
			local st = d.appliances[pot.uid]
			if st and st.c > 0 then
				st.t = workspace:GetServerTimeNow() - 1 -- fast-forward
			end
			assert(waitFor(function()
				return S.Appliance.hasBroth("broth_shoyu")
			end, 5), "the broth never got ready")
		end
	end)

	check("a customer comes in and orders by themselves", function()
		local known = {}
		for uid in pairs(S.Customers.active) do
			known[uid] = true
		end
		assert(S.Customers.trySpawn("cust_student"), "no customer could be spawned (seats? menu?)")
		local c = waitFor(function()
			for uid, cust in pairs(S.Customers.active) do
				if not known[uid] and cust.state == "waiting" and cust.ticket then
					return cust
				end
			end
			return nil
		end, 75)
		assert(c, "the customer never ordered")
		actor.customer = c
	end)

	check("the station cooks the order, one press per step", function()
		local c = actor.customer
		assert(c, "no customer from the previous step")
		local Recipes = require(Shared.Config.Recipes)
		local recipe = Recipes.byId[c.order]
		local stationEntity = firstOf("station", function(e)
			local st = S.Cooking.stationState(e)
			if e.item.fn.station ~= recipe.station or st.busy or st.ready or #st.board > 0 then
				return false
			end
			local _, r = S.Cooking.nextOrder(e)
			return r ~= nil and r.id == recipe.id
		end)
		assert(stationEntity, "no free " .. recipe.station .. " station for " .. recipe.id)
		local presses = 0
		while not S.Cooking.stationState(stationEntity).ready and presses < 8 do
			local ok, msg = S.Cooking.use(actor, stationEntity, 4)
			assert(ok, "press " .. (presses + 1) .. ": " .. tostring(msg))
			presses += 1
		end
		assert(S.Cooking.stationState(stationEntity).ready, "dish not ready after " .. presses .. " presses")
		assert(presses == #recipe.steps, recipe.id .. " took " .. presses .. " presses, expected " .. #recipe.steps)
		assert(S.Cooking.use(actor, stationEntity, 4), "could not take the dish")
		assert(S.Hands.get(actor).kind == "dish", "no dish in hand")
		actor.keepDish = S.Hands.get(actor).items[1]
	end)

	check("the customer is served and pays", function()
		local c = actor.customer
		assert(c and actor.keepDish, "no customer or no dish from the previous steps")
		S.Hands.set(actor, "dish", { actor.keepDish })
		local before = d.yen
		local e = S.Entities.get(c.uid)
		local ok, msg = S.Customers.use(actor, e)
		assert(ok, "serve: " .. tostring(msg))
		assert(waitFor(function()
			return d.yen > before
		end, 40), "the customer did not pay")
	end)

	check("collect the dirty dish and wash it", function()
		local dirty = waitFor(function()
			return firstOf("dirty")
		end, 30)
		assert(dirty, "no dirty dish appeared")
		local ok, msg = S.Customers.collectDirty(actor, dirty)
		assert(ok, "collect: " .. tostring(msg))
		local sink = firstOf("sink")
		local okWash, washMsg = S.Appliance.useSink(actor, sink, 4)
		assert(okWash, "wash: " .. tostring(washMsg))
	end)

	check("plain and renovated models", function()
		local plain = Registry.build("counter_straight", { styles = {} })
		local full = Registry.build("counter_straight", { styles = Expansions.allStyles() })
		assert(not plain:FindFirstChild("Detail_counter"), "the plain counter has renovation details")
		assert(full:FindFirstChild("Detail_counter"), "the renovated counter misses its details")
		assert(#full:GetDescendants() > #plain:GetDescendants(), "the renovated counter is not more detailed")
		-- the condiment tray of the tableware renovation sits on the corner modules
		local corner = Registry.build("counter_corner", { styles = Expansions.allStyles() })
		assert(corner:FindFirstChild("Detail_tableware"), "the renovated corner misses its condiments")
		plain:Destroy()
		full:Destroy()
		corner:Destroy()
		for _, e in ipairs(Expansions.list) do
			if e.reno then
				assert(e.cosmetic and not e.zones, e.id .. " must be cosmetic")
			end
		end
	end)

	check("every dish and ingredient model builds", function()
		local Recipes = require(Shared.Config.Recipes)
		local bad = {}
		for _, r in ipairs(Recipes.list) do
			local ok, m = pcall(Registry.food, "dish", r.id)
			if not ok or not m or not m.PrimaryPart or #m:GetChildren() < 4 then
				table.insert(bad, r.id)
			end
			if ok and m then
				m:Destroy()
			end
		end
		for _, ing in ipairs(Ingredients.list) do
			local ok, m = pcall(Registry.food, "ingredient", ing.id)
			if not ok or not m or not m.PrimaryPart then
				table.insert(bad, ing.id)
			end
			if ok and m then
				m:Destroy()
			end
		end
		assert(#bad == 0, "broken food models: " .. table.concat(bad, ", "))
	end)

	check("detailed customers and staff", function()
		local Npc = S.Npc
		local made = {
			Npc.create({ look = "tourist" }),
			Npc.create({ look = "casual", child = true }),
			Npc.create({ look = "casual", staff = "staff_sushi_chef" }),
		}
		for i, npc in ipairs(made) do
			assert(npc and npc.model, "npc " .. i .. " was not created")
			local parts = 0
			for _, d in ipairs(npc.model:GetDescendants()) do
				if d:IsA("BasePart") then
					parts += 1
				end
			end
			assert(parts > 35, "npc " .. i .. " has only " .. parts .. " parts")
			assert(npc.model:FindFirstChild("Face"), "npc " .. i .. " has no face")
		end
		Registry.People.setMood(made[1].model, "angry")
		assert(made[1].model:GetAttribute("Mood") == "angry", "mood did not change")
		for _, npc in ipairs(made) do
			npc.model:Destroy()
		end
	end)

	check("placement rules", function()
		local ctx = S.World.ctx(d.placed)
		local ok, reason = PlacementLogic.validate(ctx, { i = "bamboo_pot", x = 12, z = 4, r = 0, f = 0, s = "f" })
		assert(ok, "valid spot refused: " .. tostring(reason))
		ok = PlacementLogic.validate(ctx, { i = "stool_wood", x = 0, z = 47, r = 0, f = 0, s = "f" })
		assert(not ok, "stool in the kitchen accepted")
	end)

	S.Hands.forget(actor)
	local passed, failed = 0, {}
	for _, r in ipairs(results) do
		if r.ok then
			passed += 1
		else
			table.insert(failed, r.name)
		end
	end
	print(string.format("[SelfTest] %d/%d passed", passed, #results))
	S.Net.notify(player, "msg.selftest_result", { passed = passed, total = #results, failed = #failed > 0 and table.concat(failed, ", ") or "—" }, #failed == 0 and "success" or "error")
	running = false
	return passed, #results
end

return SelfTest
