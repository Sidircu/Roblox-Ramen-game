--!nonstrict
-- End-to-end self test of the core loop, started from the dev panel. It drives the real services
-- with an invisible worker: restock, rice, cook a kappa maki, serve a customer, get paid, wash.
-- Results go to the Output window and to a toast.
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
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
		for _, g in ipairs({ "nori", "cucumber" }) do
			local _, ent = ensureBox(g)
			assert(S.Supply.takeBox(actor, ent), "could not take the box")
			local shelf = firstOf("shelf", function(e)
				return not e.item.fn.fishOnly
			end)
			local ok, msg = S.Supply.useShelf(actor, shelf, nil)
			assert(ok, "useShelf: " .. tostring(msg))
			returnLeftover()
			assert(S.Supply.shelfStock(g) > 0, g .. " not on the shelf")
		end
	end)

	check("cook rice", function()
		local rc = firstOf("ricecooker")
		if not S.Appliance.hasRice() then
			local _, ent = ensureBox("rice")
			assert(S.Supply.takeBox(actor, ent), "could not take the rice box")
			local ok, msg = S.Appliance.load(actor, rc)
			assert(ok or msg == "msg.cooking_wait", "load: " .. tostring(msg))
			returnLeftover()
			local st = d.appliances[rc.uid]
			if st and st.c > 0 then
				st.t = workspace:GetServerTimeNow() - 1 -- fast-forward
			end
			assert(waitFor(S.Appliance.hasRice, 5), "rice never got ready")
		end
	end)

	check("cook a kappa maki with clicks", function()
		for _, g in ipairs({ "nori", "cucumber" }) do
			local shelf, slot = S.Supply.findShelfWith(g)
			assert(shelf, "no " .. g .. " on the shelves")
			local ok, msg = S.Supply.useShelf(actor, shelf, slot)
			assert(ok, "take " .. g .. ": " .. tostring(msg))
		end
		local station = firstOf("station", function(e)
			return e.item.fn.station == "sushi" and not S.Cooking.stationState(e).busy and not S.Cooking.stationState(e).ready
		end)
		assert(station, "no free sushi station")
		local ok, msg = S.Cooking.use(actor, station, 4)
		assert(ok, "deposit: " .. tostring(msg))
		for _ = 1, 6 do
			if S.Cooking.stationState(station).ready then
				break
			end
			local stepOk, stepMsg = S.Cooking.use(actor, station, 4)
			assert(stepOk, "step: " .. tostring(stepMsg))
		end
		assert(S.Cooking.stationState(station).ready, "dish not ready")
		assert(S.Cooking.use(actor, station, 4), "could not take the dish")
		assert(S.Hands.get(actor).kind == "dish", "no dish in hand")
		actor.keepDish = S.Hands.get(actor).items[1]
	end)

	check("customer orders, is served and pays", function()
		assert(actor.keepDish, "no dish from the previous step")
		if S.Day.phase == "prep" then
			S.Day.open()
		end
		assert(S.Day.phase == "open", "the day is not open")
		local before = d.yen
		local known = {}
		for uid in pairs(S.Customers.active) do
			known[uid] = true
		end
		assert(S.Customers.trySpawn("cust_student"), "no customer could be spawned (seats? menu?)")
		local c = waitFor(function()
			for uid, cust in pairs(S.Customers.active) do
				if not known[uid] and cust.state == "order" then
					return cust
				end
			end
			return nil
		end, 75)
		assert(c, "the customer never sat down to order")
		c.order = "kappa_maki"
		c.npc.model:SetAttribute("Order", "kappa_maki")
		local e = S.Entities.get(c.uid)
		assert(S.Customers.use(actor, e), "could not take the order")
		assert(c.state == "waiting", "state after order: " .. tostring(c.state))
		S.Hands.set(actor, "dish", { actor.keepDish })
		local ok, msg = S.Customers.use(actor, e)
		assert(ok, "serve: " .. tostring(msg))
		assert(waitFor(function()
			return d.yen > before
		end, 40), "the customer did not pay")
		actor.customerSeat = c.seat
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
		assert(full:FindFirstChild("Detail_counter") and full:FindFirstChild("Detail_tableware"), "the renovated counter misses its details")
		assert(#full:GetDescendants() > #plain:GetDescendants(), "the renovated counter is not more detailed")
		plain:Destroy()
		full:Destroy()
		for _, e in ipairs(Expansions.list) do
			if e.reno then
				assert(e.cosmetic and not e.zones, e.id .. " must be cosmetic")
			end
		end
	end)

	check("placement rules", function()
		local ctx = S.World.ctx(d.placed)
		local ok, reason = PlacementLogic.validate(ctx, { i = "bamboo_pot", x = 12, z = 4, r = 0, f = 0, s = "f" })
		assert(ok, "valid spot refused: " .. tostring(reason))
		ok = PlacementLogic.validate(ctx, { i = "stool_wood", x = 0, z = 22, r = 0, f = 0, s = "f" })
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
