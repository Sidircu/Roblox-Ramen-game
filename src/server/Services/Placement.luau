--!nonstrict
-- Placed objects of every restaurant: spawning models from the owner's data (restaurant-local
-- coordinates moved onto the plot), building remotes, inventory, painting, ambience. Functional
-- services subscribe to ItemAdded / ItemRemoved / ItemMoved (the entity knows its plot).
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local Items = require(Shared.Config.Items)
local Surfaces = require(Shared.Config.Surfaces)
local Sets = require(Shared.Config.Sets)
local Upgrades = require(Shared.Config.Upgrades)
local Events = require(Shared.Config.Events)
local Expansions = require(Shared.Config.Expansions)
local PlacementLogic = require(Shared.Logic.Placement)
local Ambience = require(Shared.Logic.Ambience)
local Footprint = require(Shared.Logic.Footprint)
local Registry = require(Shared.Models.Registry)
local Signal = require(Shared.Util.Signal)
local Uid = require(Shared.Util.Uid)
local Core = require(script.Parent.Parent.Core)

local Placement = {}
Placement.ItemAdded = Signal.new() -- (entity)
Placement.ItemRemoved = Signal.new() -- (entity)
Placement.ItemMoved = Signal.new() -- (entity)
Placement.LayoutChanged = Signal.new() -- (plot)
local NO_AMBIENCE = { points = 0, tier = 0, patience = 0, tip = 0, popularity = 0, sets = {} }

-- ambience of a restaurant: { points, tier, patience, tip, popularity, sets }
function Placement.ambienceOf(plot)
	return (plot and plot.ambience) or NO_AMBIENCE
end

local vetoes = {} -- functions(entity) -> ok, reason

local FN_KIND = {
	seat = "seat", counter = "counter", table = "table", booth = "booth", shelf = "shelf",
	ricecooker = "ricecooker", pot = "pot", station = "station", sink = "sink", dishwasher = "dishwasher",
	rack = "rack", bench = "bench", fridge = "fridge", tipjar = "tipjar",
}

function Placement.kindOf(itemId)
	local item = Items.byId[itemId]
	if item and item.fn then
		return FN_KIND[item.fn.type] or "decor"
	end
	return "decor"
end

function Placement.addVeto(fn)
	table.insert(vetoes, fn)
end

-- the restaurant a player builds in: the one they stand in when they may build there
local function buildPlot(player)
	local Plots = Core.S.Plots
	local plot = Plots.of(player)
	if plot and Plots.canBuild(player, plot) then
		return plot
	end
	return nil
end

local function findEntry(data, uid)
	for i, e in ipairs(data.placed) do
		if e.u == uid then
			return e, i
		end
	end
	return nil
end

local function worldY(entry)
	local item = Items.byId[entry.i]
	local World = Core.S.World
	if entry.s == "f" then
		return World.floorY(entry.f)
	elseif entry.s == "c" then
		return World.floorY(entry.f) + GameConfig.WallHeight - item.size[2]
	elseif entry.s == "w" then
		return (entry.y or World.floorY(entry.f) + 6) - item.size[2] / 2
	elseif entry.s == "t" then
		return entry.y or World.floorY(entry.f)
	end
	return 0
end

local function spawn(plot, entry)
	local data = Core.S.Plots.data(plot)
	local model = Registry.build(entry.i, { styles = Expansions.styles(data and data.zones) })
	Registry.place(model, entry.x + plot.origin.X, worldY(entry), entry.z + plot.origin.Z, entry.r)
	model:SetAttribute("FloorIndex", entry.f or 0)
	model.Parent = Core.S.World.folders(plot).items
	local item = Items.byId[entry.i]
	local e = Core.S.Entities.register(entry.u, Placement.kindOf(entry.i), model, { entry = entry, item = item, isItem = true, plot = plot })
	Placement.ItemAdded:Fire(e)
	return e
end

local function despawn(uid)
	local e = Core.S.Entities.unregister(uid)
	if e then
		Placement.ItemRemoved:Fire(e)
		if e.model then
			e.model:Destroy()
		end
	end
end

function Placement.recomputeAmbience(plot)
	local data = Core.S.Plots.data(plot)
	if not data then
		return
	end
	local extra = Upgrades.value(data.upgrades, "up_jukebox")
	for _, e in ipairs(Expansions.list) do
		if data.zones[e.id] and e.ambience then
			extra += e.ambience
		end
	end
	plot.ambience = Ambience.compute(data.placed, Items.byId, Surfaces.byId, data.surfaces, extra, Sets.list)
	plot.folder:SetAttribute("Ambience", plot.ambience.points)
	plot.folder:SetAttribute("AmbienceTier", plot.ambience.tier)
	local decor = 0
	for _, e in ipairs(data.placed) do
		if Placement.kindOf(e.i) == "decor" then
			decor += 1
		end
	end
	data.stats.decor = math.max(data.stats.decor or 0, decor)
end

local function changed(plot)
	Placement.recomputeAmbience(plot)
	Core.S.Data.changed(plot.owner, "placed")
	Core.S.Data.changed(plot.owner, "inventory")
	Placement.LayoutChanged:Fire(plot)
end

-- removes every placed object of a restaurant (its owner left)
function Placement.despawnAll(plot)
	for _, e in ipairs(Core.S.Entities.ofPlot(plot)) do
		if e.isItem then
			despawn(e.uid)
		end
	end
end

function Placement.spawnAll(plot, data)
	Placement.despawnAll(plot)
	-- floor items first so tops find their parents
	table.sort(data.placed, function(a, b)
		local order = { f = 1, w = 2, c = 3, t = 4 }
		return (order[a.s] or 5) < (order[b.s] or 5)
	end)
	for _, entry in ipairs(data.placed) do
		if Items.byId[entry.i] then
			local ok, err = pcall(spawn, plot, entry)
			if not ok then
				warn("[Placement] could not spawn " .. tostring(entry.i) .. ": " .. tostring(err))
			end
		end
	end
	Placement.recomputeAmbience(plot)
	Placement.LayoutChanged:Fire(plot)
end

-- Removes objects that are no longer valid (e.g. after stairs appear) into the inventory
function Placement.revalidate(plot, data)
	local ctx = Core.S.World.ctx(plot, data.placed)
	local removed = 0
	for i = #data.placed, 1, -1 do
		local e = data.placed[i]
		local others = table.clone(data.placed)
		table.remove(others, i)
		ctx.placed = others
		local ok = PlacementLogic.validate(ctx, e, true)
		if not ok then
			table.remove(data.placed, i)
			data.inventory[e.i] = (data.inventory[e.i] or 0) + 1
			removed += 1
		end
	end
	return removed
end

local function canAfford(player, data, item, fromInventory)
	if fromInventory then
		return (data.inventory[item.id] or 0) > 0
	end
	if item.sakura then
		return (data.sakura or 0) >= item.sakura
	end
	return (data.yen or 0) >= item.price
end

local function itemUnlocked(data, item)
	if data.level < (item.lv or 1) then
		return false, "msg.need_level"
	end
	if item.license and not data.licenses[item.license] then
		return false, "msg.need_license"
	end
	if item.event then
		local active = Events.active(os.time())
		if not active or active.id ~= item.event then
			return false, "msg.event_over"
		end
	end
	if item.franchise and not (data.franchise.cities and data.franchise.cities[item.franchise]) then
		return false, "msg.need_franchise"
	end
	return true
end

local function parseReq(req)
	if type(req) ~= "table" then
		return nil
	end
	local Net = Core.S.Net
	if not (Net.str(req.i, 40) and Net.num(req.x, -500, 500) and Net.num(req.z, -500, 500) and Net.num(req.r or 0, -720, 720)) then
		return nil
	end
	local out = {
		i = req.i,
		x = math.floor(req.x * 100 + 0.5) / 100,
		z = math.floor(req.z * 100 + 0.5) / 100,
		r = math.floor((req.r or 0) % 360 + 0.5),
		f = (Net.num(req.f, 0, 3) and math.floor(req.f)) or 0,
		s = req.s,
		y = Net.num(req.y, -10, 100) and req.y or nil,
		p = Net.str(req.p, 40) and req.p or nil,
	}
	return out
end

local function checkVetoes(uid)
	local e = Core.S.Entities.get(uid)
	if not e then
		return true
	end
	for _, fn in ipairs(vetoes) do
		local ok, reason = fn(e)
		if not ok then
			return false, reason
		end
	end
	return true
end

function Placement.place(player, rawReq, fromInventory)
	local Net, Economy = Core.S.Net, Core.S.Economy
	local plot = buildPlot(player)
	if not plot then
		return Net.notify(player, "msg.no_permission", nil, "error")
	end
	local owner = plot.owner
	local data = Core.S.Plots.data(plot)
	local req = parseReq(rawReq)
	if not data or not req then
		return
	end
	local item = Items.byId[req.i]
	if not item then
		return
	end
	if not fromInventory then
		local ok, reason = itemUnlocked(data, item)
		if not ok then
			return Net.notify(player, reason, { level = item.lv }, "error")
		end
	end
	if item.gamepass and not fromInventory and Core.S.Monetization.has(owner, item.gamepass) then
		fromInventory = (data.inventory[item.id] or 0) > 0
	end
	if not canAfford(player, data, item, fromInventory) then
		return Net.notify(player, "msg.not_enough", nil, "error")
	end
	local ctx = Core.S.World.ctx(plot, data.placed)
	local ok, reason, resolved = PlacementLogic.validate(ctx, req)
	if not ok then
		return Net.notify(player, reason or "msg.place_invalid", nil, "error")
	end
	if fromInventory then
		data.inventory[item.id] -= 1
		if data.inventory[item.id] <= 0 then
			data.inventory[item.id] = nil
		end
	elseif item.sakura then
		if not Economy.spendSakura(owner, item.sakura, "item:" .. item.id) then
			return
		end
	else
		if not Economy.spend(owner, item.price, "build", "item:" .. item.id) then
			return Net.notify(player, "msg.not_enough", nil, "error")
		end
	end
	local entry = { u = Uid.new("p"), i = item.id, x = resolved.x, z = resolved.z, r = resolved.r, f = resolved.f, s = resolved.s, t = os.time() }
	if resolved.s == "w" or resolved.s == "t" then
		entry.y = resolved.y
	end
	if resolved.p then
		entry.p = resolved.p
	end
	entry.paid = (not fromInventory) and (item.sakura and 0 or item.price) or 0
	table.insert(data.placed, entry)
	spawn(plot, entry)
	changed(plot)
	Net.fxTo(player, "sfx", { name = "place" })
	Core.S.Meta.event(owner, "place", 1, { item = item.id })
end

local function children(data, uid)
	local out = {}
	for _, e in ipairs(data.placed) do
		if e.p == uid then
			table.insert(out, e)
		end
	end
	return out
end

function Placement.move(player, uid, rawReq)
	local Net = Core.S.Net
	local plot = buildPlot(player)
	if not plot or type(uid) ~= "string" then
		return
	end
	local data = Core.S.Plots.data(plot)
	local entry = data and findEntry(data, uid)
	local req = parseReq(rawReq)
	if not entry or not req or req.i ~= entry.i then
		return
	end
	local okVeto, vetoReason = checkVetoes(uid)
	if not okVeto then
		return Net.notify(player, vetoReason, nil, "error")
	end
	req.u = uid
	local ctx = Core.S.World.ctx(plot, data.placed)
	local ok, reason, resolved = PlacementLogic.validate(ctx, req)
	if not ok then
		return Net.notify(player, reason or "msg.place_invalid", nil, "error")
	end
	local dx, dz = resolved.x - entry.x, resolved.z - entry.z
	local dr = resolved.r - entry.r
	local oldX, oldZ = entry.x, entry.z
	entry.x, entry.z, entry.r, entry.f, entry.s = resolved.x, resolved.z, resolved.r, resolved.f, resolved.s
	entry.y = (resolved.s == "w" or resolved.s == "t") and resolved.y or nil
	entry.p = resolved.p
	-- children on top follow (rotated around the parent's center)
	for _, child in ipairs(children(data, uid)) do
		local lx, lz = child.x - oldX, child.z - oldZ
		local a = math.rad(-dr)
		local rx = lx * math.cos(a) - lz * math.sin(a)
		local rz = lx * math.sin(a) + lz * math.cos(a)
		child.x, child.z = resolved.x + rx, resolved.z + rz
		child.r = (child.r + dr) % 360
		child.f = entry.f
		local item = Items.byId[entry.i]
		child.y = Core.S.World.floorY(entry.f) + item.size[2]
	end
	local _ = { dx, dz }
	for _, e in ipairs({ entry, table.unpack(children(data, uid)) }) do
		local ent = Core.S.Entities.get(e.u)
		if ent and ent.model then
			ent.model:SetAttribute("FloorIndex", e.f or 0)
			Registry.place(ent.model, e.x + plot.origin.X, worldY(e), e.z + plot.origin.Z, e.r)
			Placement.ItemMoved:Fire(ent)
		end
	end
	changed(plot)
	Net.fxTo(player, "sfx", { name = "place" })
end

function Placement.remove(player, uid, mode)
	local Net, Economy = Core.S.Net, Core.S.Economy
	local plot = buildPlot(player)
	if not plot or type(uid) ~= "string" then
		return
	end
	local data = Core.S.Plots.data(plot)
	local entry, index = nil, nil
	if data then
		entry, index = findEntry(data, uid)
	end
	if not entry then
		return
	end
	local okVeto, vetoReason = checkVetoes(uid)
	if not okVeto then
		return Net.notify(player, vetoReason, nil, "error")
	end
	for _, child in ipairs(children(data, uid)) do
		local _, ci = findEntry(data, child.u)
		table.remove(data.placed, ci)
		data.inventory[child.i] = (data.inventory[child.i] or 0) + 1
		despawn(child.u)
	end
	index = select(2, findEntry(data, uid))
	table.remove(data.placed, index)
	despawn(uid)
	local item = Items.byId[entry.i]
	if mode == "sell" and not item.sakura then
		local paid = entry.paid or item.price
		local refund = (os.time() - (entry.t or 0) <= GameConfig.FullRefundSeconds) and paid or math.floor(paid * GameConfig.SellRefund)
		if refund > 0 then
			Economy.add(plot.owner, refund, "refund", { raw = true })
		end
	else
		data.inventory[entry.i] = (data.inventory[entry.i] or 0) + 1
	end
	changed(plot)
end

function Placement.paint(player, zoneId, kind, styleId)
	local Net, Economy = Core.S.Net, Core.S.Economy
	local plot = buildPlot(player)
	if not plot then
		return
	end
	local data = Core.S.Plots.data(plot)
	local style = Surfaces.byId[styleId]
	if not data or not style or style.kind ~= kind then
		return
	end
	local zone = nil
	for _, z in ipairs(Core.S.World.geo(plot).zones) do
		if z.id == zoneId and not z.outdoor then
			zone = z
		end
	end
	if not zone then
		return
	end
	if data.level < style.lv then
		return Net.notify(player, "msg.need_level", { level = style.lv }, "error")
	end
	data.surfaces[zoneId] = data.surfaces[zoneId] or {}
	if data.surfaces[zoneId][kind] == styleId then
		return
	end
	if style.price > 0 and not Economy.spend(plot.owner, style.price, "build", "surface:" .. tostring(styleId)) then
		return Net.notify(player, "msg.not_enough", nil, "error")
	end
	data.surfaces[zoneId][kind] = styleId
	Core.S.World.rebuild(plot, data)
	Core.S.Data.changed(plot.owner, "surfaces")
	Placement.recomputeAmbience(plot)
	Net.fxTo(player, "sfx", { name = "place" })
end

-- Items of a restaurant whose footprint is close to a local point (used by seating / freshness)
function Placement.near(plot, x, z, f, radius, filterFn)
	local out = {}
	local data = Core.S.Plots.data(plot)
	if not data then
		return out
	end
	for _, e in ipairs(data.placed) do
		if (e.f or 0) == f and (not filterFn or filterFn(e)) then
			local item = Items.byId[e.i]
			if item then
				local fp = Footprint.new(e.x, e.z, item.size[1], item.size[3], e.r)
				local x0, z0, x1, z1 = Footprint.bounds(fp)
				local dx = math.max(x0 - x, 0, x - x1)
				local dz = math.max(z0 - z, 0, z - z1)
				if math.sqrt(dx * dx + dz * dz) <= radius then
					table.insert(out, e)
				end
			end
		end
	end
	return out
end

function Placement.Init()
	local Net = Core.S.Net
	Net.on("PlaceItem", function(player, req, fromInventory)
		Placement.place(player, req, fromInventory == true)
	end, 6)
	Net.on("MoveItem", function(player, uid, req)
		Placement.move(player, uid, req)
	end, 6)
	Net.on("RemoveItem", function(player, uid, mode)
		Placement.remove(player, uid, mode == "sell" and "sell" or "store")
	end, 6)
	Net.on("PaintSurface", function(player, zoneId, kind, styleId)
		if type(zoneId) == "string" and (kind == "floor" or kind == "wall") and type(styleId) == "string" then
			Placement.paint(player, zoneId, kind, styleId)
		end
	end, 3)
end

function Placement.Start()
	Core.S.Plots.Claimed:Connect(function(plot, _, data)
		task.defer(function()
			Placement.spawnAll(plot, data)
		end)
	end)
	Core.S.Plots.Released:Connect(function(plot)
		Placement.despawnAll(plot)
		plot.ambience = nil
	end)
end

return Placement
