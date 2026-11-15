--!nonstrict
-- Task board helpers for staff: finds work, claims targets so two workers never do the same job.
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Recipes = require(Shared.Config.Recipes)
local Ingredients = require(Shared.Config.Ingredients)
local Core = require(script.Parent.Parent.Core)

local Tasks = {}

-- Point in front of an entity (local -Z side) at floor level
function Tasks.frontOf(e, dist)
	local root = e.model and e.model.PrimaryPart
	if not root then
		return Core.S.Entities.position(e)
	end
	local cook = root:FindFirstChild("Cook")
	if cook then
		return cook.WorldPosition + Vector3.new(0, 0.5, 0)
	end
	local cf = root.CFrame * CFrame.new(0, -root.Size.Y / 2 + 0.5, -(root.Size.Z / 2 + (dist or 1.6)))
	return cf.Position
end

function Tasks.nearCustomer(c)
	if not c.seat then
		return c.npc and c.npc.root and c.npc.root.Position or Vector3.new()
	end
	local sit = c.seat.sit
	local p = sit.Position - sit.LookVector * 2.2
	return Vector3.new(p.X, Core.S.World.floorY(c.seat.floor) + 0.5, p.Z)
end

-- claims live outside the objects (box entries are saved to the DataStore)
local claims = setmetatable({}, { __mode = "k" })

local function claimed(obj)
	local a = claims[obj]
	return a ~= nil and a.alive ~= false
end

function Tasks.claim(obj, actor)
	if claimed(obj) then
		return claims[obj] == actor
	end
	claims[obj] = actor
	return true
end

function Tasks.release(obj, actor)
	if obj and claims[obj] == actor then
		claims[obj] = nil
	end
end

function Tasks.claimedBy(obj)
	return claims[obj]
end

-- Waiter: a ready dish that matches a waiting customer
function Tasks.findServe()
	local Customers = Core.S.Customers
	for _, rd in ipairs(Core.S.Cooking.readyDishes()) do
		local st = Core.S.Cooking.stationState(rd.entity)
		if not claimed(st) then
			for _, c in ipairs(Customers.list("waiting")) do
				if c.order == rd.recipe and not claimed(c) then
					return rd.entity, c
				end
			end
		end
	end
	return nil
end

function Tasks.findOrder()
	for _, c in ipairs(Core.S.Customers.list("order")) do
		if not claimed(c) then
			return c
		end
	end
	return nil
end

function Tasks.findDirty()
	for _, e in ipairs(Core.S.Entities.ofKind("dirty")) do
		if not claimed(e) then
			return e
		end
	end
	return nil
end

-- Chef: a ticket for one of the chef's stations whose ingredients are on the shelves
function Tasks.findCook(stations)
	local Supply, Appliance = Core.S.Supply, Core.S.Appliance
	for _, t in ipairs(Core.S.Cooking.tickets) do
		local r = Recipes.byId[t.recipe]
		if r and not t.claimed and table.find(stations, r.station) then
			local ok = true
			local need = {}
			for _, g in ipairs(r.ing) do
				need[g] = (need[g] or 0) + 1
			end
			for g, n in pairs(need) do
				if Supply.shelfStock(g) < n then
					ok = false
				end
			end
			if ok and r.rice and not Appliance.hasRice() then
				ok = false
			end
			if ok and r.broth and not Appliance.hasBroth(r.broth) then
				ok = false
			end
			if ok then
				-- a free station of the right type
				for _, e in ipairs(Core.S.Entities.ofKind("station")) do
					if e.item.fn.station == r.station then
						local st = Core.S.Cooking.stationState(e)
						if not st.busy and #st.board == 0 and not st.ready and not claimed(st) then
							return t, r, e
						end
					end
				end
			end
		end
	end
	return nil
end

-- Stocker: ingredient running low on shelves with a box available
function Tasks.findRestock()
	local d = Core.S.Session.ownerData()
	local Supply = Core.S.Supply
	local wanted = {}
	for _, r in ipairs(Core.S.Progression.menuRecipes(d)) do
		for _, g in ipairs(r.ing) do
			wanted[g] = true
		end
	end
	for g in pairs(wanted) do
		local ing = Ingredients.byId[g]
		if ing and (ing.storage == "shelf" or ing.storage == "fish") and Supply.shelfStock(g) < 6 then
			local box = Supply.findBox(g)
			if box and not claimed(box) then
				return box, g
			end
		end
	end
	return nil
end

-- Stocker / ramen chef: a rice cooker or pot that needs refilling (and a box to do it)
function Tasks.findRefill(kinds)
	local d = Core.S.Session.ownerData()
	local Supply = Core.S.Supply
	local broths = {}
	for _, r in ipairs(Core.S.Progression.menuRecipes(d)) do
		if r.broth then
			broths[r.broth] = (broths[r.broth] or 0) + 1
		end
	end
	for _, need in ipairs(Core.S.Appliance.needsRefill()) do
		local e = need.entity
		if table.find(kinds, e.kind) and not claimed(e) then
			if e.kind == "ricecooker" then
				local box = Supply.findBox("rice")
				if box and not claimed(box) then
					return e, box
				end
			else
				local g = need.g
				if not g then
					-- empty pot: pick the broth most used by the menu that no other pot is making
					local best, bestN = nil, 0
					for b, n in pairs(broths) do
						if n > bestN and not Core.S.Appliance.willHave("pot", b) then
							best, bestN = b, n
						end
					end
					g = best
				end
				local box = g and Supply.findBox(g)
				if box and not claimed(box) then
					return e, box
				end
			end
		end
	end
	return nil
end

return Tasks
