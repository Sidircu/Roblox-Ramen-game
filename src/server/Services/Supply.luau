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
local ShelfGrid = require(Shared.Logic.ShelfGrid)
local Registry = require(Shared.Models.Registry)
local Uid = require(Shared.Util.Uid)
local Core = require(script.Parent.Parent.Core)

local Supply = {}
local boxModels = {} -- [boxUid] = entity
local slotVisuals = {} -- [shelfUid .. "#" .. slot] = { holder, g, cols, rows, cells = { [k] = { kind, inst } } }
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

-- Product grid of one slot for ingredient g (Logic/ShelfGrid): half a supplier box laid out like
-- a chessboard, plus rows from the shelf upgrade. A box therefore fills at most two slots.
function Supply.slotGrid(g)
	local ing = Ingredients.byId[g]
	if not ing then
		return 1, 1
	end
	local d = data()
	local mult = d and Upgrades.value(d.upgrades, "up_shelf") or 1
	return ShelfGrid.forIngredient(ing.units, GameConfig.BoxShelfSlots, mult)
end

function Supply.slotCap(entity, g)
	if not Ingredients.byId[g] then
		return 0
	end
	local cols, rows = Supply.slotGrid(g)
	return cols * rows
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
	local dz = Expansions.DropZone
	table.insert(blocked, Footprint.rectToFp({ dz.x0, dz.z0, dz.x1, dz.z1 }))
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

-- spots on the ground where the truck leaves the boxes (Expansions.DropZone)
local function dropSpots()
	local zone = Expansions.DropZone
	local out = {}
	for layer = 0, zone.layers - 1 do
		for x = zone.x0 + 1, zone.x1 - 0.9, 2.05 do
			for z = zone.z0 + 0.8, zone.z1 - 0.75, 1.75 do
				table.insert(out, { x = x, z = z, l = layer })
			end
		end
	end
	return out
end

local function freeDropSpot(d)
	for _, sp in ipairs(dropSpots()) do
		local taken = false
		for _, b in ipairs(d.storage) do
			if b.px and (b.pf or 0) == 0 and (b.pl or 0) == sp.l and math.abs(b.px - sp.x) < 0.6 and math.abs(b.pz - sp.z) < 0.6 then
				taken = true
				break
			end
		end
		if not taken then
			return sp
		end
	end
	return nil
end

-- boxes the restaurant can hold: rack slots in the storage room plus the drop zone outside
function Supply.capacity()
	return #rackSlots() + #dropSpots()
end

local function boxModel(entry)
	local m = Registry.food("box", entry.g, entry.n, Supply.boxCap(entry))
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
	-- boxes on the floor at the same spot stack up (a box taken from the bottom lets the others drop)
	local stacks, level = {}, {}
	for _, entry in ipairs(d.storage) do
		if not entry.h and entry.px then
			local key = math.floor(entry.px * 2 + 0.5) .. ":" .. math.floor(entry.pz * 2 + 0.5) .. ":" .. (entry.pf or 0)
			stacks[key] = stacks[key] or {}
			table.insert(stacks[key], entry)
		end
	end
	for _, list in pairs(stacks) do
		table.sort(list, function(a, b)
			return (a.pl or 0) < (b.pl or 0)
		end)
		for i, entry in ipairs(list) do
			level[entry] = i - 1
		end
	end
	for _, entry in ipairs(d.storage) do
		if not entry.h then
			local cf
			if entry.px then
				-- box on the floor (left by the truck or put down by a player): it stays exactly there
				local y = Core.S.World.floorY(entry.pf or 0) + 0.65 + (level[entry] or 0) * 1.32
				cf = CFrame.new(entry.px, y, entry.pz) * CFrame.Angles(0, math.rad(entry.pr or 0), 0)
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

-- portions in a full box of this entry (big boxes hold several boxes)
function Supply.boxCap(entry)
	local ing = Ingredients.byId[entry.g]
	return math.max(entry.c or (ing and ing.units) or entry.n, entry.n)
end

local function updateBoxLabel(entry)
	local e = boxModels[entry.u]
	if e and e.model then
		local text = entry.n .. "/" .. Supply.boxCap(entry)
		for _, d in ipairs(e.model:GetDescendants()) do
			if d.Name == "Count" and d:IsA("TextLabel") then
				d.Text = text
			end
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
	local hands = Hands.get(actor)
	if hands.kind ~= nil and (hands.kind ~= "box" or #hands.items >= Hands.capacity(actor, "box")) then
		return false, "msg.hands_full"
	end
	local entry = e.box
	local pos = Core.S.Entities.position(e)
	local ok, reason = Hands.add(actor, "box", entry)
	if not ok then
		return false, reason
	end
	entry.h = true
	entry.px, entry.pz, entry.pf, entry.pr, entry.pl = nil, nil, nil, nil, nil
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
	entry.pl = 9 -- on top of anything already there
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

-- how big a product is drawn in a cell (fits the cell, never bigger than ShelfItemScale)
local extents = {}
local function productFit(g, cw, cd, ch)
	local ext = extents[g]
	if not ext then
		local m = Registry.food("ingredient", g)
		ext = m:GetExtentsSize()
		m:Destroy()
		extents[g] = ext
	end
	local maxScale = GameConfig.ShelfItemScale or 1.3
	local straight = math.min(0.86 * cw / ext.X, 0.86 * cd / ext.Z, 0.8 * ch / ext.Y)
	local turned = math.min(0.86 * cw / ext.Z, 0.86 * cd / ext.X, 0.8 * ch / ext.Y)
	if turned > straight then
		return math.min(turned, maxScale), true
	end
	return math.min(straight, maxScale), false
end

-- world CFrame of the floor of cell k of a slot part, and the cell size
local function cellFloor(part, k, cols, rows)
	local x, z, cw, cd = ShelfGrid.cell(k, cols, rows, part.Size.X - 0.1, part.Size.Z - 0.1)
	return part.CFrame * CFrame.new(x, -part.Size.Y / 2 + 0.02, z), cw, cd
end

-- one product standing on a floor CFrame (bottom resting on it); clients use the same rule
local function standProduct(g, floorCf, scale, turned)
	local m = Registry.food("ingredient", g)
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") then
			d.CanQuery = false
			d.CanCollide = false
		end
	end
	pcall(function()
		m:ScaleTo(scale)
	end)
	local target = floorCf * (turned and CFrame.Angles(0, math.rad(90), 0) or CFrame.new())
	m:PivotTo(target)
	local box, size = m:GetBoundingBox()
	m:PivotTo(target + Vector3.new(0, target.Position.Y - (box.Position.Y - size.Y / 2), 0))
	return m
end

Supply.standProduct = standProduct

-- a faint square marking a free spot of the grid
local function spot(floorCf, cw, cd)
	local p = Instance.new("Part")
	p.Name = "Spot"
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.SmoothPlastic
	p.Color = Color3.fromRGB(255, 244, 214)
	p.Transparency = 0.5
	p.Size = Vector3.new(cw * 0.8, 0.02, cd * 0.8)
	p.CFrame = floorCf * CFrame.new(0, 0.01, 0)
	return p
end

-- what fly animations need to land exactly where the product will stand
function Supply.cellTarget(e, slot, k, g)
	local part = e.model and e.model:FindFirstChild("Slot" .. slot)
	if not part then
		return nil
	end
	local cols, rows = Supply.slotGrid(g)
	local floorCf, cw, cd = cellFloor(part, k, cols, rows)
	local scale, turned = productFit(g, cw, cd, part.Size.Y)
	return { g = g, cf = floorCf, s = scale, rot = turned }
end

local function refreshSlot(e, slot)
	local st = shelfState(e.uid)
	local part = e.model:FindFirstChild("Slot" .. slot)
	local key = e.uid .. "#" .. slot
	local cur = slotVisuals[key]
	local s = st[tostring(slot)]
	local g = (s and s.n > 0) and s.g or nil
	if part then
		part:SetAttribute("G", g or "")
		part:SetAttribute("N", g and s.n or 0)
		part:SetAttribute("Cap", g and Supply.slotCap(e, g) or 0)
	end
	if not g or not part then
		if cur then
			cur.holder:Destroy()
			slotVisuals[key] = nil
		end
		return
	end
	local cols, rows = Supply.slotGrid(g)
	if not cur or cur.g ~= g or cur.cols ~= cols or cur.rows ~= rows or not cur.holder.Parent then
		if cur then
			cur.holder:Destroy()
		end
		local holder = Instance.new("Model")
		holder.Name = "SlotItems"
		holder.Parent = e.model
		cur = { holder = holder, g = g, cols = cols, rows = rows, cells = {} }
		slotVisuals[key] = cur
	end
	local _, cw0, cd0 = cellFloor(part, 1, cols, rows)
	local scale, turned = productFit(g, cw0, cd0, part.Size.Y)
	for k = 1, cols * rows do
		local want = k <= s.n and "item" or "spot"
		local have = cur.cells[k]
		if not have or have.kind ~= want then
			if have then
				have.inst:Destroy()
			end
			local floorCf, cw, cd = cellFloor(part, k, cols, rows)
			local inst = want == "item" and standProduct(g, floorCf, scale, turned) or spot(floorCf, cw, cd)
			inst.Parent = cur.holder
			cur.cells[k] = { kind = want, inst = inst }
		end
	end
end

-- Draws the products of a shelf (or of one slot) as a grid with free spots marked
function Supply.refreshShelf(e, onlySlot)
	if not e or not e.model then
		return
	end
	if onlySlot then
		refreshSlot(e, onlySlot)
		return
	end
	for slot = 1, e.item.fn.slots do
		refreshSlot(e, slot)
	end
end

-- where an actor holds things (start / end of the fly animations)
local function handPos(actor)
	if typeof(actor) == "Instance" then
		local hrp = actor.Character and actor.Character:FindFirstChild("HumanoidRootPart")
		return hrp and (hrp.CFrame * CFrame.new(0, 0.6, -1.6)).Position
	end
	local root = actor.npc and actor.npc.root
	return root and (root.CFrame * CFrame.new(0, 0.6, -1.6)).Position
end
Supply.handPos = handPos

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
		-- with a cart you may hold several boxes: use one that fits this shelf, preferring the
		-- ingredient of the clicked slot
		local clicked = slot and st[tostring(slot)]
		local index, firstError = nil, nil
		for i, it in ipairs(hands.items) do
			local ing = Ingredients.byId[it.g]
			local err = nil
			if ing.storage == "rice" or ing.storage == "broth" then
				err = "msg.use_appliance"
			elseif e.item.fn.fishOnly and ing.storage ~= "fish" then
				err = "msg.fish_only"
			end
			if err then
				firstError = firstError or err
			elseif clicked and clicked.g == it.g and (not index or hands.items[index].g ~= it.g) then
				index = i
			elseif not index then
				index = i
			end
		end
		if not index then
			return false, firstError
		end
		local entry = hands.items[index]
		local cap = Supply.slotCap(e, entry.g)
		local placed = 0
		local target
		if slot and slot >= 1 and slot <= e.item.fn.slots then
			-- the slot you clicked, and only that one
			local s = st[tostring(slot)]
			if s and s.n > 0 and s.g ~= entry.g then
				return false, "msg.slot_other", { name = "ing." .. s.g }
			end
			if s and s.n >= cap then
				return false, "msg.slot_full"
			end
			target = slot
		else
			-- clicked the shelf itself: the slot that already holds this product, else an empty one
			target = chooseSlot(e, entry.g, nil)
			if not target then
				return false, "msg.shelf_full"
			end
		end
		-- one slot per click: what does not fit stays in the box for the slot you click next
		local flights, touched = {}, {}
		do
			local s = st[tostring(target)]
			if not s or s.n == 0 then
				s = { g = entry.g, n = 0 }
				st[tostring(target)] = s
			end
			local amount = math.max(0, math.min(entry.n, cap - s.n))
			for k = s.n + 1, s.n + amount do
				local tgt = Supply.cellTarget(e, target, k, entry.g)
				if tgt then
					table.insert(flights, tgt)
				end
			end
			s.n += amount
			entry.n -= amount
			placed += amount
			table.insert(touched, target)
		end
		local left = entry.n
		if entry.n <= 0 then
			Supply.removeBox(entry)
			Hands.removeAt(actor, index)
		else
			Hands.refresh(actor)
			updateBoxLabel(entry)
		end
		if typeof(actor) == "Instance" then
			Core.S.Net.notify(actor, left > 0 and "msg.restocked_left" or "msg.restocked", { n = placed, name = "ing." .. entry.g, left = left }, "success")
		end
		-- the products fly out of the box one by one (Supermarket Together style) and are drawn on
		-- the shelf when the last one lands
		local step = GameConfig.StockFlyStep or 0.06
		Core.S.Net.fx("stock", { from = handPos(actor), items = flights, step = step })
		task.delay(#flights * step + 0.3, function()
			if e.model then
				for _, slotIndex in ipairs(touched) do
					refreshSlot(e, slotIndex)
				end
			end
		end)
		for _, slotIndex in ipairs(touched) do
			local part = e.model:FindFirstChild("Slot" .. slotIndex)
			local s = st[tostring(slotIndex)]
			if part and s then
				part:SetAttribute("G", s.g)
				part:SetAttribute("N", s.n)
			end
		end
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
		-- the last product of the slot flies into your hands
		local from = Supply.cellTarget(e, slot, s.n, s.g)
		if from then
			Core.S.Net.fx("take", { item = from, to = handPos(actor) })
		end
		s.n -= 1
		if s.n <= 0 then
			st[tostring(slot)] = nil
		end
		Supply.refreshShelf(e, slot)
		Core.S.Data.changed(Core.S.Session.owner, "shelves")
		return true
	end
	return false, "msg.hands_busy"
end

------------------------------------------------------------------ orders & delivery

-- orders leave right away: only the truck's short drive is left
local function deliveryTime()
	return 0
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
				local units = ing.units * GameConfig.BigBoxMultiplier
				table.insert(boxes, { u = Uid.new("b"), g = g, n = units, c = units })
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
	Net.fxTo(player, "action", { kind = "order" })
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
	-- backs into the bay: the cargo door faces the storage room
	local bayCf = CFrame.new(bay.x, 2.1, bay.z) * CFrame.Angles(0, math.rad(-90), 0)
	local value = Instance.new("CFrameValue")
	value.Value = startCf
	value.Changed:Connect(function(cf)
		if truck.Parent then
			truck:PivotTo(cf)
		end
	end)
	truck:PivotTo(startCf)
	local t1 = TweenService:Create(value, TweenInfo.new(GameConfig.TruckDrive or 4.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Value = roadCf })
	t1:Play()
	t1.Completed:Wait()
	local t2 = TweenService:Create(value, TweenInfo.new(1.3, Enum.EasingStyle.Sine), { Value = bayCf })
	t2:Play()
	t2.Completed:Wait()
	Core.S.Net.fx("sfx", { name = "truck", pos = bayCf.Position })
	task.delay(0.8, function()
		Core.S.Net.fx("sfx", { name = "bell", pos = bayCf.Position })
	end)
	task.wait(0.4)
	onArrive()
	task.wait(1)
	local t3 = TweenService:Create(value, TweenInfo.new(1.6, Enum.EasingStyle.Sine), { Value = CFrame.new(bay.x - 4, 2.1, lane) })
	t3:Play()
	t3.Completed:Wait()
	local t4 = TweenService:Create(value, TweenInfo.new(7, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Value = CFrame.new(-Expansions.Street.reach, 2.1, lane) })
	t4:Play()
	t4.Completed:Wait()
	truck:Destroy()
	value:Destroy()
end

------------------------------------------------------------------ rescue kit

-- ingredients of recipe r that are nowhere (shelves, boxes, hands, pot, rice cooker)
local function missingFor(d, r)
	local need = table.clone(r.ing)
	if r.broth then
		table.insert(need, r.broth)
	end
	if r.rice then
		table.insert(need, "rice")
	end
	local missing = {}
	for _, g in ipairs(need) do
		local have = Supply.shelfStock(g) > 0
		if not have then
			for _, b in ipairs(d.storage) do
				if b.g == g and b.n > 0 then
					have = true
					break
				end
			end
		end
		if not have and g == r.broth then
			have = Core.S.Appliance.hasBroth(g) or Core.S.Appliance.willHave("pot", g)
		elseif not have and g == "rice" then
			have = Core.S.Appliance.hasRice() or Core.S.Appliance.willHave("ricecooker")
		end
		if not have then
			table.insert(missing, g)
		end
	end
	return missing
end

-- Safety net: no dish of the menu can be made and there is not enough money to buy what is
-- missing (spent it all on decorations, for example): the supplier sends a free kit for the
-- cheapest dish, at most once every GameConfig.RescueCooldown seconds
local function rescueCheck()
	local d = data()
	local owner = Core.S.Session.owner
	if not d or not owner or truckBusy or #pending > 0 then
		return
	end
	if os.time() - (d.meta.rescueAt or 0) < (GameConfig.RescueCooldown or 600) then
		return
	end
	local cheapest, cheapestCost = nil, math.huge
	for id, m in pairs(d.menu or {}) do
		local r = Recipes.byId[id]
		if r and m.on then
			local missing = missingFor(d, r)
			if #missing == 0 then
				return -- something can still be cooked
			end
			local cost = 0
			for _, g in ipairs(missing) do
				cost += Ingredients.byId[g] and Ingredients.byId[g].price or 0
			end
			if cost < cheapestCost then
				cheapest, cheapestCost = missing, cost
			end
		end
	end
	if not cheapest or d.yen >= cheapestCost then
		return
	end
	local boxes = {}
	for _, g in ipairs(cheapest) do
		table.insert(boxes, { u = Uid.new("b"), g = g, n = Ingredients.byId[g].units })
	end
	d.meta.rescueAt = os.time()
	table.insert(pending, { t = os.clock(), boxes = boxes })
	Core.S.Net.notify(owner, "msg.rescue_kit", nil, "success")
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
						-- the driver puts the boxes down on the ground one by one
						for _, b in ipairs(batch) do
							local sp = freeDropSpot(d)
							if sp then
								b.px, b.pz, b.pf, b.pr, b.pl = sp.x, sp.z, 0, 0, sp.l
							end
							table.insert(d.storage, b)
							Supply.layout()
							Core.S.Net.fx("sfx", { name = "box", pos = Vector3.new(b.px or Expansions.LoadingBay.x, 1, b.pz or Expansions.LoadingBay.z) })
							task.wait(0.2)
						end
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
	task.spawn(function()
		while true do
			task.wait(15)
			pcall(rescueCheck)
		end
	end)
	task.spawn(autoRestock)
	local _ = updateBoxLabel
end

Supply.updateBoxLabel = updateBoxLabel
return Supply
