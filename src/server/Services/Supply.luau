--!nonstrict
-- Supplier orders, the delivery truck, boxes in the storage room and shelf slots.
local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local Ingredients = require(Shared.Config.Ingredients)
local Recipes = require(Shared.Config.Recipes)
local Upgrades = require(Shared.Config.Upgrades)
local Items = require(Shared.Config.Items)
local Expansions = require(Shared.Config.Expansions)
local Footprint = require(Shared.Logic.Footprint)
local Registry = require(Shared.Models.Registry)
local Uid = require(Shared.Util.Uid)
local Core = require(script.Parent.Parent.Core)

local Supply = {}
local boxModels = {} -- [boxUid] = entity
local slotVisuals = {} -- [shelfUid .. "#" .. slot] = Model
local pending = {} -- deliveries { t, boxes }
local truckBusy = false

local function data()
	return Core.S.Session.ownerData()
end

local function ingUnlocked(d, ing)
	if d.licenses[ing.license] then
		return true
	end
	-- regional dishes may use ingredients from licenses not owned yet
	for _, r in ipairs(Recipes.list) do
		if r.city and r.city == d.franchise.city and table.find(r.ing, ing.id) then
			return true
		end
	end
	return false
end

-- Units of ingredient g one slot of this shelf holds: a fraction of a supplier box, so that a
-- box never fills more than GameConfig.BoxShelfSlots slots
function Supply.slotCap(entity, g)
	local ing = Ingredients.byId[g]
	if not ing then
		return 0
	end
	local d = data()
	local mult = d and Upgrades.value(d.upgrades, "up_shelf") or 1
	return math.max(1, math.ceil(ing.units * (entity.item.fn.size or 1) * mult / GameConfig.BoxShelfSlots - 1e-6))
end

------------------------------------------------------------------ storage layout

local chooseSlot, shelfState

local function rackSlots()
	local slots = {}
	local racks = Core.S.Entities.ofKind("rack")
	table.sort(racks, function(a, b)
		return a.uid < b.uid
	end)
	for _, r in ipairs(racks) do
		local root = r.model.PrimaryPart
		local i = 1
		while root and root:FindFirstChild("Box" .. i) do
			table.insert(slots, root["Box" .. i].WorldCFrame * CFrame.new(0, 0.65, 0))
			i += 1
		end
	end
	return slots
end

local function overflowSlots()
	local d = data()
	local slots = {}
	local World = Core.S.World
	local blocked = {}
	for _, e in ipairs(d.placed) do
		if e.s == "f" then
			local item = Items.byId[e.i]
			table.insert(blocked, Footprint.inflate(Footprint.new(e.x, e.z, item.size[1], item.size[3], e.r), 0.6))
		end
	end
	for _, fx in ipairs(World.fixedRects()) do
		table.insert(blocked, Footprint.rectToFp(fx.rect))
	end
	for _, z in ipairs(World.zones) do
		if z.area == "storage" then
			local r = z.rect
			for x = r[1] + 1.6, r[3] - 1.6, 2.2 do
				for zz = r[2] + 1.6, r[4] - 1.6, 1.9 do
					local fp = Footprint.new(x, zz, 1.8, 1.5, 0)
					local free = true
					for _, b in ipairs(blocked) do
						if Footprint.overlaps(fp, b) then
							free = false
							break
						end
					end
					if free then
						for level = 0, 1 do
							table.insert(slots, CFrame.new(x, 0.65 + level * 1.32, zz))
						end
					end
				end
			end
		end
	end
	return slots
end

function Supply.capacity()
	return #rackSlots() + math.min(#overflowSlots(), GameConfig.DeliveryOverflowBoxes)
end

local function boxModel(entry)
	local m = Registry.food("box", entry.g, entry.n)
	return m
end

function Supply.layout()
	local d = data()
	if not d then
		return
	end
	local slots = rackSlots()
	for _, s in ipairs(overflowSlots()) do
		table.insert(slots, s)
	end
	local idx = 0
	local keep = {}
	for _, entry in ipairs(d.storage) do
		if not entry.h then
			local cf
			if entry.px then
				-- box put down on the floor by a player: it stays exactly there
				cf = CFrame.new(entry.px, Core.S.World.floorY(entry.pf or 0) + 0.65, entry.pz) * CFrame.Angles(0, math.rad(entry.pr or 0), 0)
			else
				idx += 1
				cf = slots[idx] or CFrame.new(Expansions.LoadingBay.x, 0.65 + idx * 0.05, Expansions.LoadingBay.z)
			end
			local e = boxModels[entry.u]
			if not e then
				local m = boxModel(entry)
				m.Parent = Core.S.World.folders().dynamic
				e = Core.S.Entities.register(entry.u, "box", m, { box = entry })
				boxModels[entry.u] = e
			end
			e.model:PivotTo(cf)
			keep[entry.u] = true
		end
	end
	for uid, e in pairs(boxModels) do
		if not keep[uid] then
			Core.S.Entities.unregister(uid)
			if e.model then
				e.model:Destroy()
			end
			boxModels[uid] = nil
		end
	end
end

local function updateBoxLabel(entry)
	local e = boxModels[entry.u]
	if e and e.model then
		local label = e.model:FindFirstChild("Count", true)
		local ing = Ingredients.byId[entry.g]
		if label then
			label.Text = (ing and ing.icon or "📦") .. " " .. entry.n
		end
	end
end

function Supply.returnBox(entry)
	local d = data()
	if not d then
		return
	end
	entry.h = nil
	if entry.n <= 0 then
		for i, b in ipairs(d.storage) do
			if b.u == entry.u then
				table.remove(d.storage, i)
				break
			end
		end
	end
	Supply.layout()
	Core.S.Data.changed(Core.S.Session.owner, "storage")
end

function Supply.removeBox(entry)
	local d = data()
	for i, b in ipairs(d.storage) do
		if b.u == entry.u then
			table.remove(d.storage, i)
			break
		end
	end
	Supply.layout()
	Core.S.Data.changed(Core.S.Session.owner, "storage")
end

function Supply.takeBox(actor, e)
	local Hands = Core.S.Hands
	if not Hands.isEmpty(actor) then
		return false, "msg.hands_full"
	end
	local entry = e.box
	local pos = Core.S.Entities.position(e)
	entry.h = true
	entry.px, entry.pz, entry.pf, entry.pr = nil, nil, nil, nil
	Hands.set(actor, "box", { entry })
	Supply.layout()
	if pos then
		Core.S.Net.fx("sfx", { name = "box", pos = pos })
	end
	return true
end

-- Puts a held box down: on a free rack slot when a rack is close, otherwise on the floor in front
-- of the actor. Returns "rack" or "floor".
function Supply.dropBox(entry, pos, look, floor)
	entry.h = nil
	Core.S.Net.fx("sfx", { name = "box", pos = pos })
	if entry.n <= 0 then
		Supply.returnBox(entry)
		return "gone"
	end
	local d = data()
	local nearRack = false
	for _, r in ipairs(Core.S.Entities.ofKind("rack")) do
		if r.model and r.model.PrimaryPart and (r.model.PrimaryPart.Position - pos).Magnitude < 9 then
			nearRack = true
		end
	end
	local onRacks = 0
	for _, b in ipairs(d.storage) do
		if not b.h and not b.px and b ~= entry then
			onRacks += 1
		end
	end
	if nearRack and onRacks < #rackSlots() then
		entry.px, entry.pz, entry.pf, entry.pr = nil, nil, nil, nil
		Supply.layout()
		Core.S.Data.changed(Core.S.Session.owner, "storage")
		return "rack"
	end
	local target = pos + look * 3
	local World = Core.S.World
	if not World.zoneAt(target.X, target.Z, floor or 0) then
		target = pos
	end
	entry.px, entry.pz, entry.pf = math.floor(target.X * 10) / 10, math.floor(target.Z * 10) / 10, floor or 0
	entry.pr = math.floor(math.deg(math.atan2(-look.X, -look.Z)))
	Supply.layout()
	Core.S.Data.changed(Core.S.Session.owner, "storage")
	return "floor"
end

-- Puts one ingredient back on the nearest shelf that can take it. Returns the shelf or nil.
function Supply.returnIngredient(g, pos)
	local ing = Ingredients.byId[g]
	if not ing then
		return nil
	end
	local best, bestSlot, bestD = nil, nil, math.huge
	for _, e in ipairs(Core.S.Entities.ofKind("shelf")) do
		if not (e.item.fn.fishOnly and ing.storage ~= "fish") and e.model and e.model.PrimaryPart then
			local slot = chooseSlot(e, g, nil)
			if slot then
				local dist = (e.model.PrimaryPart.Position - pos).Magnitude
				-- prefer a slot that already holds this ingredient
				local st = shelfState(e.uid)[tostring(slot)]
				if st and st.g == g then
					dist -= 1000
				end
				if dist < bestD then
					best, bestSlot, bestD = e, slot, dist
				end
			end
		end
	end
	if not best then
		return nil
	end
	local st = shelfState(best.uid)
	local s = st[tostring(bestSlot)]
	if not s or s.n == 0 then
		s = { g = g, n = 0 }
		st[tostring(bestSlot)] = s
	end
	s.n += 1
	Supply.refreshShelf(best)
	Core.S.Data.changed(Core.S.Session.owner, "shelves")
	return best
end

function Supply.findBox(g)
	local d = data()
	for _, entry in ipairs(d.storage) do
		if entry.g == g and not entry.h and entry.n > 0 then
			return entry, boxModels[entry.u]
		end
	end
	return nil
end

function Supply.boxCount(g)
	local d = data()
	local n, portions = 0, 0
	for _, entry in ipairs(d.storage) do
		if entry.g == g then
			n += 1
			portions += entry.n
		end
	end
	return n, portions
end

------------------------------------------------------------------ shelves

function shelfState(uid)
	local d = data()
	d.shelves[uid] = d.shelves[uid] or {}
	return d.shelves[uid]
end

function Supply.refreshShelf(e)
	if not e or not e.model then
		return
	end
	local st = shelfState(e.uid)
	for slot = 1, e.item.fn.slots do
		local part = e.model:FindFirstChild("Slot" .. slot)
		local key = e.uid .. "#" .. slot
		if slotVisuals[key] then
			slotVisuals[key]:Destroy()
			slotVisuals[key] = nil
		end
		local s = st[tostring(slot)]
		local cap = s and Supply.slotCap(e, s.g) or 0
		if part then
			part:SetAttribute("G", s and s.g or "")
			part:SetAttribute("N", s and s.n or 0)
			part:SetAttribute("Cap", cap)
		end
		if s and s.n > 0 and part then
			local holder = Instance.new("Model")
			holder.Name = "SlotItems"
			local width = part:GetAttribute("Width") or 3
			local shown = math.min(6, math.max(1, math.ceil(s.n / math.max(1, cap) * 6)))
			for k = 1, shown do
				local m = Registry.food("ingredient", s.g)
				-- the shelves are big: show the products a little bigger too
				pcall(function()
					m:ScaleTo(GameConfig.ShelfItemScale or 1)
				end)
				local x = -width / 2 + width * (k - 0.5) / shown
				m:PivotTo(part.CFrame * CFrame.new(x, -part.Size.Y / 2 + 0.32 * (GameConfig.ShelfItemScale or 1), 0))
				for _, dsc in ipairs(m:GetDescendants()) do
					if dsc:IsA("BasePart") then
						dsc.CanQuery = false
					end
				end
				m.Parent = holder
			end
			holder.Parent = e.model
			slotVisuals[key] = holder
		end
	end
end

function Supply.shelfStock(g)
	local total = 0
	for _, e in ipairs(Core.S.Entities.ofKind("shelf")) do
		for _, s in pairs(shelfState(e.uid)) do
			if s.g == g then
				total += s.n
			end
		end
	end
	return total
end

-- Nearest shelf slot holding ingredient g (for staff)
function Supply.findShelfWith(g, pos)
	local best, bestSlot, bestD = nil, nil, math.huge
	for _, e in ipairs(Core.S.Entities.ofKind("shelf")) do
		for slot, s in pairs(shelfState(e.uid)) do
			if s.g == g and s.n > 0 then
				local p = e.model.PrimaryPart.Position
				local dist = pos and (p - pos).Magnitude or 0
				if dist < bestD then
					best, bestSlot, bestD = e, tonumber(slot), dist
				end
			end
		end
	end
	return best, bestSlot
end

function chooseSlot(e, g, requested)
	local st = shelfState(e.uid)
	local cap = Supply.slotCap(e, g)
	local slots = e.item.fn.slots
	if requested and requested >= 1 and requested <= slots then
		local s = st[tostring(requested)]
		if not s or s.n == 0 or (s.g == g and s.n < cap) then
			return requested
		end
	end
	for slot = 1, slots do
		local s = st[tostring(slot)]
		if s and s.g == g and s.n > 0 and s.n < cap then
			return slot
		end
	end
	for slot = 1, slots do
		local s = st[tostring(slot)]
		if not s or s.n == 0 then
			return slot
		end
	end
	return nil
end

-- Shelf interaction for players and staff
function Supply.useShelf(actor, e, slot)
	local Hands = Core.S.Hands
	local hands = Hands.get(actor)
	local st = shelfState(e.uid)
	if hands.kind == "box" then
		local entry = hands.items[1]
		local ing = Ingredients.byId[entry.g]
		if ing.storage == "rice" or ing.storage == "broth" then
			return false, "msg.use_appliance"
		end
		if e.item.fn.fishOnly and ing.storage ~= "fish" then
			return false, "msg.fish_only"
		end
		local cap = Supply.slotCap(e, entry.g)
		local placed, filled = 0, 0
		local target = chooseSlot(e, entry.g, slot)
		if not target then
			return false, "msg.shelf_full"
		end
		-- fill the clicked slot first, then the next free one: at most BoxShelfSlots slots per box
		while target and entry.n > 0 and filled < GameConfig.BoxShelfSlots do
			local s = st[tostring(target)]
			if not s or s.n == 0 then
				s = { g = entry.g, n = 0 }
				st[tostring(target)] = s
			end
			local amount = math.max(0, math.min(entry.n, cap - s.n))
			s.n += amount
			entry.n -= amount
			placed += amount
			filled += 1
			target = entry.n > 0 and chooseSlot(e, entry.g, nil) or nil
		end
		local left = entry.n
		if entry.n <= 0 then
			Supply.removeBox(entry)
			Hands.clear(actor)
		else
			Hands.refresh(actor)
			updateBoxLabel(entry)
		end
		if typeof(actor) == "Instance" then
			Core.S.Net.notify(actor, left > 0 and "msg.restocked_left" or "msg.restocked", { n = placed, name = "ing." .. entry.g, left = left }, "success")
		end
		Supply.refreshShelf(e)
		Core.S.Data.changed(Core.S.Session.owner, "shelves")
		Core.S.Meta.event(Core.S.Session.owner, "restock", 1)
		Core.S.Net.fx("sfx", { name = "restock", pos = e.model.PrimaryPart.Position })
		return true
	elseif hands.kind == nil or hands.kind == "ing" then
		local s = slot and st[tostring(slot)]
		if not s or s.n <= 0 then
			-- clicked an empty slot: take from any slot of this shelf
			for k = 1, e.item.fn.slots do
				if st[tostring(k)] and st[tostring(k)].n > 0 then
					slot, s = k, st[tostring(k)]
					break
				end
			end
		end
		if not s or s.n <= 0 then
			return false, "msg.shelf_empty"
		end
		local ok, reason = Hands.add(actor, "ing", { g = s.g, fresh = e.item.fn.fresh == true })
		if not ok then
			return false, reason
		end
		s.n -= 1
		if s.n <= 0 then
			st[tostring(slot)] = nil
		end
		Supply.refreshShelf(e)
		Core.S.Data.changed(Core.S.Session.owner, "shelves")
		return true
	end
	return false, "msg.hands_busy"
end

------------------------------------------------------------------ orders & delivery

local function deliveryTime()
	local d = data()
	if Core.S.Monetization.ownerHas("gp_express") then
		return 1
	end
	return Upgrades.value(d.upgrades, "up_delivery")
end

function Supply.order(player, cart)
	local Session, Net = Core.S.Session, Core.S.Net
	if not Session.canBuild(player) then
		return Net.notify(player, "msg.no_permission", nil, "error")
	end
	local d = data()
	if type(cart) ~= "table" then
		return
	end
	local discount = Upgrades.value(d.upgrades, "up_supplier")
	local total, boxes = 0, {}
	for g, q in pairs(cart) do
		local ing = Ingredients.byId[g]
		if ing and type(q) == "table" and ingUnlocked(d, ing) then
			local small = math.clamp(math.floor(tonumber(q.small) or 0), 0, 30)
			local big = (discount > 0) and math.clamp(math.floor(tonumber(q.big) or 0), 0, 30) or 0
			total += small * ing.price
			total += math.floor(big * ing.price * GameConfig.BigBoxMultiplier * (1 - discount) + 0.5)
			for _ = 1, small do
				table.insert(boxes, { u = Uid.new("b"), g = g, n = ing.units })
			end
			for _ = 1, big do
				table.insert(boxes, { u = Uid.new("b"), g = g, n = ing.units * GameConfig.BigBoxMultiplier })
			end
		end
	end
	if #boxes == 0 then
		return
	end
	local queued = 0
	for _, p in ipairs(pending) do
		queued += #p.boxes
	end
	if #d.storage + queued + #boxes > Supply.capacity() then
		return Net.notify(player, "msg.storage_full", { n = Supply.capacity() }, "error")
	end
	if not Core.S.Economy.spend(Session.owner, total, "supplies") then
		return Net.notify(player, "msg.not_enough", nil, "error")
	end
	table.insert(pending, { t = os.clock() + deliveryTime(), boxes = boxes })
	Net.notifyAll("msg.order_placed", { n = #boxes, seconds = math.floor(deliveryTime()) }, "success")
	return true
end

local function animateTruck(onArrive)
	local folders = Core.S.World.folders()
	local truck = Registry.Street.truck()
	truck.Parent = folders.dynamic
	local bay = Expansions.LoadingBay
	local lane = Expansions.Street.truckLane
	local startCf = CFrame.new(Expansions.Street.reach, 2.1, lane) * CFrame.Angles(0, 0, 0)
	local roadCf = CFrame.new(bay.x + 2, 2.1, lane)
	local bayCf = CFrame.new(bay.x, 2.1, bay.z) * CFrame.Angles(0, math.rad(90), 0)
	local value = Instance.new("CFrameValue")
	value.Value = startCf
	value.Changed:Connect(function(cf)
		if truck.Parent then
			truck:PivotTo(cf)
		end
	end)
	truck:PivotTo(startCf)
	local t1 = TweenService:Create(value, TweenInfo.new(7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Value = roadCf })
	t1:Play()
	t1.Completed:Wait()
	local t2 = TweenService:Create(value, TweenInfo.new(1.6, Enum.EasingStyle.Sine), { Value = bayCf })
	t2:Play()
	t2.Completed:Wait()
	Core.S.Net.fx("sfx", { name = "truck", pos = bayCf.Position })
	task.delay(0.8, function()
		Core.S.Net.fx("sfx", { name = "bell", pos = bayCf.Position })
	end)
	task.wait(1)
	onArrive()
	task.wait(1.5)
	local t3 = TweenService:Create(value, TweenInfo.new(1.6, Enum.EasingStyle.Sine), { Value = CFrame.new(bay.x - 4, 2.1, lane) })
	t3:Play()
	t3.Completed:Wait()
	local t4 = TweenService:Create(value, TweenInfo.new(7, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Value = CFrame.new(-Expansions.Street.reach, 2.1, lane) })
	t4:Play()
	t4.Completed:Wait()
	truck:Destroy()
	value:Destroy()
end

local function deliveryLoop()
	while true do
		task.wait(0.5)
		if not truckBusy and #pending > 0 and pending[1].t <= os.clock() then
			local batch = {}
			while #pending > 0 and pending[1].t <= os.clock() + 2 do
				local p = table.remove(pending, 1)
				for _, b in ipairs(p.boxes) do
					table.insert(batch, b)
				end
			end
			truckBusy = true
			task.spawn(function()
				local ok, err = pcall(animateTruck, function()
					local d = data()
					if d then
						for _, b in ipairs(batch) do
							table.insert(d.storage, b)
						end
						Supply.layout()
						Core.S.Data.changed(Core.S.Session.owner, "storage")
						Core.S.Net.notifyAll("msg.delivery_arrived", { n = #batch }, "success")
					end
				end)
				if not ok then
					warn("[Supply] truck: " .. tostring(err))
					local d = data()
					if d then
						for _, b in ipairs(batch) do
							table.insert(d.storage, b)
						end
						Supply.layout()
					end
				end
				truckBusy = false
			end)
		end
	end
end

-- Auto restock (upgrade + stocker): keeps at least one box of each menu ingredient
local function autoRestock()
	while true do
		task.wait(GameConfig.AutoRestockCheck)
		local d = data()
		if d and (d.upgrades.up_autorestock or 0) > 0 then
			local hasStocker = false
			for _, s in ipairs(d.staff) do
				if s.role == "staff_stocker" then
					hasStocker = true
				end
			end
			if hasStocker then
				local needed = {}
				for _, r in ipairs(Core.S.Progression.menuRecipes(d)) do
					for _, g in ipairs(r.ing) do
						needed[g] = true
					end
					if r.rice then
						needed.rice = true
					end
					if r.broth then
						needed[r.broth] = true
					end
				end
				local cart = {}
				for g in pairs(needed) do
					local ing = Ingredients.byId[g]
					local boxes = Supply.boxCount(g)
					if ing and boxes == 0 and Supply.shelfStock(g) < ing.units then
						cart[g] = { small = 2 }
					end
				end
				if next(cart) then
					Supply.order(Core.S.Session.owner, cart)
				end
			end
		end
	end
end

function Supply.Init()
	local Net = Core.S.Net
	Net.on("OrderSupplies", function(player, cart)
		Supply.order(player, cart)
	end, 2)
	Net.on("BuyDishes", function(player, count)
		local Session = Core.S.Session
		if not Session.canBuild(player) then
			return
		end
		local d = data()
		local n = math.clamp(math.floor(tonumber(count) or 1), 1, 10)
		local cost = n * GameConfig.DishSetPrice
		if Core.S.Economy.spend(Session.owner, cost, "supplies") then
			d.dishes.total += n * GameConfig.DishSetSize
			d.dishes.clean += n * GameConfig.DishSetSize
			Core.S.Data.changed(Session.owner, "dishes")
			Net.notify(player, "msg.dishes_bought", { n = n * GameConfig.DishSetSize }, "success")
		else
			Net.notify(player, "msg.not_enough", nil, "error")
		end
	end, 3)
	local Placement = Core.S.Placement
	Placement.ItemAdded:Connect(function(e)
		if e.kind == "shelf" then
			Supply.refreshShelf(e)
		elseif e.kind == "rack" then
			task.defer(Supply.layout)
		end
	end)
	Placement.ItemMoved:Connect(function(e)
		if e.kind == "shelf" then
			Supply.refreshShelf(e)
		elseif e.kind == "rack" then
			task.defer(Supply.layout)
		end
	end)
	Placement.ItemRemoved:Connect(function(e)
		if e.kind == "rack" then
			task.defer(Supply.layout)
		end
	end)
	Placement.addVeto(function(e)
		if e.kind == "shelf" then
			for _, s in pairs(shelfState(e.uid)) do
				if s.n > 0 then
					return false, "msg.empty_first"
				end
			end
		end
		return true
	end)
	Placement.LayoutChanged:Connect(function()
		task.defer(Supply.layout)
	end)
end

function Supply.Start()
	Core.S.Session.OwnerReady:Connect(function(_, d)
		for _, b in ipairs(d.storage) do
			b.h = nil
		end
		task.delay(0.5, Supply.layout)
	end)
	task.spawn(deliveryLoop)
	task.spawn(autoRestock)
	local _ = updateBoxLabel
end

Supply.updateBoxLabel = updateBoxLabel
return Supply
