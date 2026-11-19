--!nonstrict
-- Task board helpers for staff: finds work in their restaurant (every finder takes the plot),
-- claims targets so two workers never do the same job.
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
function Tasks.findServe(plot)
	local Customers = Core.S.Customers
	for _, rd in ipairs(Core.S.Cooking.readyDishes(plot)) do
		local st = Core.S.Cooking.stationState(rd.entity)
		if not claimed(st) then
			for _, c in ipairs(Customers.list(plot, "waiting")) do
				if c.order == rd.recipe and not claimed(c) then
					return rd.entity, c
				end
			end
		end
	end
	return nil
end

function Tasks.findOrder(plot)
	for _, c in ipairs(Core.S.Customers.list(plot, "order")) do
		if not claimed(c) then
			return c
		end
	end
	return nil
end

function Tasks.findDirty(plot)
	for _, e in ipairs(Core.S.Entities.ofKind("dirty", plot)) do
		if not claimed(e) then
			return e
		end
	end
	return nil
end

-- Chef: a free station of the chef's kinds with an order to start and everything it needs
-- (the station fetches the ingredients from the shelves by itself)
function Tasks.findCook(plot, stations)
	local Cooking = Core.S.Cooking
	for _, e in ipairs(Core.S.Entities.ofKind("station", plot)) do
		if table.find(stations, e.item.fn.station) then
			local st = Cooking.stationState(e)
			if not st.busy and #st.board == 0 and not st.ready and not claimed(st) then
				local t, r = Cooking.nextOrder(e)
				if t and #Cooking.missing(plot, r) == 0 then
					return t, r, e
				end
			end
		end
	end
	return nil
end

-- Stocker: ingredient running low on shelves with a box available
function Tasks.findRestock(plot)
	local d = Core.S.Plots.data(plot)
	if not d then
		return nil
	end
	local Supply = Core.S.Supply
	local wanted = {}
	for _, r in ipairs(Core.S.Progression.menuRecipes(d)) do
		for _, g in ipairs(r.ing) do
			wanted[g] = true
		end
	end
	for g in pairs(wanted) do
		local ing = Ingredients.byId[g]
		if ing and (ing.storage == "shelf" or ing.storage == "fish") and Supply.shelfStock(plot, g) < 6 then
			local box = Supply.findBox(plot, g)
			if box and not claimed(box) then
				return box, g
			end
		end
	end
	return nil
end

-- Stocker / ramen chef: a rice cooker or pot that needs refilling (and a box to do it)
function Tasks.findRefill(plot, kinds)
	local d = Core.S.Plots.data(plot)
	if not d then
		return nil
	end
	local Supply = Core.S.Supply
	local broths = {}
	for _, r in ipairs(Core.S.Progression.menuRecipes(d)) do
		if r.broth then
			broths[r.broth] = (broths[r.broth] or 0) + 1
		end
	end
	for _, need in ipairs(Core.S.Appliance.needsRefill(plot)) do
		local e = need.entity
		if table.find(kinds, e.kind) and not claimed(e) then
			if e.kind == "ricecooker" then
				local box = Supply.findBox(plot, "rice")
				if box and not claimed(box) then
					return e, box
				end
			else
				local g = need.g
				if not g then
					-- empty pot: pick the broth most used by the menu that no other pot is making
					local best, bestN = nil, 0
					for b, n in pairs(broths) do
						if n > bestN and not Core.S.Appliance.willHave(plot, "pot", b) then
							best, bestN = b, n
						end
					end
					g = best
				end
				local box = g and Supply.findBox(plot, g)
				if box and not claimed(box) then
					return e, box
				end
			end
		end
	end
	return nil
end

return Tasks
