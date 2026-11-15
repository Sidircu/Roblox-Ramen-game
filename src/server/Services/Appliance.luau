--!nonstrict
-- Rice cookers, broth pots, sink, dishwasher, fridges and the clean/dirty dish pool.
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Ingredients = require(Shared.Config.Ingredients)
local Color = require(Shared.Util.Color)
local Core = require(script.Parent.Parent.Core)

local Appliance = {}
local sinkPile = 0
local washerQueue = {} -- [uid] = count waiting
local washing = {} -- [uid] = true while animating

local function data()
	return Core.S.Session.ownerData()
end

local function state(uid)
	local d = data()
	d.appliances[uid] = d.appliances[uid] or { g = nil, n = 0, c = 0, t = 0 }
	return d.appliances[uid]
end

local function refresh(e)
	if not e or not e.model then
		return
	end
	local st = state(e.uid)
	local m = e.model
	m:SetAttribute("G", st.g or "")
	m:SetAttribute("N", st.n)
	m:SetAttribute("C", st.c)
	m:SetAttribute("T", st.t)
	m:SetAttribute("Batch", e.item.fn.batch or 0)
	m:SetAttribute("Time", e.item.fn.time or 0)
	local steam = m:FindFirstChild("Steam")
	local emitter = steam and steam:FindFirstChildOfClass("ParticleEmitter")
	if emitter then
		emitter.Enabled = st.c > 0 or (e.kind == "pot" and st.n > 0)
	end
	local led = m:FindFirstChild("Led")
	if led then
		led.Color = st.c > 0 and Color.hex("#FF3B4A") or (st.n > 0 and Color.hex("#6DDC5A") or Color.hex("#3A3A3A"))
	end
	local broth = m:FindFirstChild("Broth")
	if broth then
		local ing = st.g and Ingredients.byId[st.g]
		broth.Transparency = (st.n + st.c > 0) and 0 or 1
		if ing then
			broth.Color = Color.hex(ing.color)
		end
		local bubbles = broth:FindFirstChildOfClass("ParticleEmitter")
		if bubbles then
			bubbles.Enabled = st.c > 0
		end
	end
	local flame = m:FindFirstChild("Flame")
	if flame then
		flame.Transparency = st.c > 0 and 0 or 0.85
	end
end
Appliance.refresh = refresh

-- Loads a rice/broth box into a cooker or pot
function Appliance.load(actor, e)
	local Hands = Core.S.Hands
	local hands = Hands.get(actor)
	local st = state(e.uid)
	if hands.kind ~= "box" then
		if st.c > 0 then
			return false, "msg.cooking_wait"
		end
		return false, e.kind == "ricecooker" and "msg.need_rice_box" or "msg.need_broth_box"
	end
	local entry = hands.items[1]
	local ing = Ingredients.byId[entry.g]
	if e.kind == "ricecooker" and ing.storage ~= "rice" then
		return false, "msg.need_rice_box"
	elseif e.kind == "pot" and ing.storage ~= "broth" then
		return false, "msg.need_broth_box"
	end
	if st.c > 0 then
		return false, "msg.cooking_wait"
	end
	if st.n > 0 and st.g ~= entry.g then
		return false, "msg.pot_other_broth"
	end
	local batch = e.item.fn.batch
	local amount = math.min(entry.n, batch - st.n)
	if amount <= 0 then
		return false, "msg.appliance_full"
	end
	st.g = entry.g
	st.c = amount
	st.t = workspace:GetServerTimeNow() + e.item.fn.time
	entry.n -= amount
	if entry.n <= 0 then
		Core.S.Supply.removeBox(entry)
		Hands.clear(actor)
	else
		Hands.refresh(actor)
	end
	refresh(e)
	Core.S.Net.fx("sfx", { name = "pour", pos = e.model.PrimaryPart.Position })
	Core.S.Data.changed(Core.S.Session.owner, "appliances")
	return true
end

local function takeFrom(kind, g)
	for _, e in ipairs(Core.S.Entities.ofKind(kind)) do
		local st = state(e.uid)
		if st.n > 0 and (g == nil or st.g == g) then
			st.n -= 1
			if st.n <= 0 and st.c <= 0 then
				st.g = (kind == "ricecooker") and "rice" or nil
			end
			refresh(e)
			return true
		end
	end
	return false
end

function Appliance.hasRice()
	for _, e in ipairs(Core.S.Entities.ofKind("ricecooker")) do
		if state(e.uid).n > 0 then
			return true
		end
	end
	return false
end

function Appliance.hasBroth(g)
	for _, e in ipairs(Core.S.Entities.ofKind("pot")) do
		local st = state(e.uid)
		if st.n > 0 and st.g == g then
			return true
		end
	end
	return false
end

-- pending portions (cooking) count as "coming soon" for customer menus
function Appliance.willHave(kind, g)
	for _, e in ipairs(Core.S.Entities.ofKind(kind)) do
		local st = state(e.uid)
		if (st.n + st.c) > 0 and (g == nil or st.g == g) then
			return true
		end
	end
	return false
end

function Appliance.takeRice()
	return takeFrom("ricecooker", nil)
end

function Appliance.takeBroth(g)
	return takeFrom("pot", g)
end

-- Appliances that need refilling (for staff)
function Appliance.needsRefill()
	local out = {}
	for _, kind in ipairs({ "ricecooker", "pot" }) do
		for _, e in ipairs(Core.S.Entities.ofKind(kind)) do
			local st = state(e.uid)
			if st.c == 0 and st.n <= math.floor((e.item.fn.batch or 8) * 0.3) then
				table.insert(out, { entity = e, g = st.n > 0 and st.g or nil })
			end
		end
	end
	return out
end

------------------------------------------------------------------ dishes

function Appliance.takeCleanDish()
	local d = data()
	if d.dishes.clean > 0 then
		d.dishes.clean -= 1
		Core.S.Data.changed(Core.S.Session.owner, "dishes")
		return true
	end
	return false
end

function Appliance.addDirtyToSink(n)
	sinkPile += n
	workspace:SetAttribute("SinkPile", sinkPile)
end

function Appliance.sinkPile()
	return sinkPile
end

local function finishWash(count)
	local d = data()
	d.dishes.clean = math.min(d.dishes.total, d.dishes.clean + count)
	d.stats.washed = (d.stats.washed or 0) + count
	Core.S.Data.changed(Core.S.Session.owner, "dishes")
	Core.S.Meta.event(Core.S.Session.owner, "wash", count)
end

-- Sink: wash the dirty dishes in hands (or from the pile); duration scales with count
function Appliance.useSink(actor, e, speed)
	local Hands = Core.S.Hands
	if washing[e.uid] then
		return false, "msg.busy"
	end
	local hands = Hands.get(actor)
	local count = 0
	if hands.kind == "dirty" then
		count = #hands.items
		Hands.clear(actor)
	elseif hands.kind == nil and sinkPile > 0 then
		count = math.min(6, sinkPile)
		sinkPile -= count
		workspace:SetAttribute("SinkPile", sinkPile)
	else
		return false, sinkPile > 0 and "msg.hands_busy" or "msg.sink_hint"
	end
	washing[e.uid] = true
	local spout = e.model:FindFirstChild("Spout")
	local emitter = spout and spout:FindFirstChildOfClass("ParticleEmitter")
	if emitter then
		emitter.Enabled = true
	end
	e.model:SetAttribute("Busy", true)
	task.wait(math.max(0.6, 0.35 * count) / (speed or 1))
	if emitter then
		emitter.Enabled = false
	end
	e.model:SetAttribute("Busy", false)
	washing[e.uid] = nil
	finishWash(count)
	return true
end

function Appliance.useDishwasher(actor, e)
	local Hands = Core.S.Hands
	local hands = Hands.get(actor)
	if hands.kind ~= "dirty" then
		return false, "msg.sink_hint"
	end
	washerQueue[e.uid] = (washerQueue[e.uid] or 0) + #hands.items
	Hands.clear(actor)
	e.model:SetAttribute("Queue", washerQueue[e.uid])
	return true
end

local function dishwasherLoop()
	while true do
		task.wait(1)
		local now = os.clock()
		for _, e in ipairs(Core.S.Entities.ofKind("dishwasher")) do
			-- pull dirty dishes from the sink pile automatically
			if sinkPile > 0 and (washerQueue[e.uid] or 0) < e.item.fn.cap then
				local take = math.min(sinkPile, e.item.fn.cap - (washerQueue[e.uid] or 0))
				sinkPile -= take
				workspace:SetAttribute("SinkPile", sinkPile)
				washerQueue[e.uid] = (washerQueue[e.uid] or 0) + take
			end
			e.nextWash = e.nextWash or (now + e.item.fn.interval)
			local q = washerQueue[e.uid] or 0
			local steam = e.model:FindFirstChild("Steam")
			local emitter = steam and steam:FindFirstChildOfClass("ParticleEmitter")
			if emitter then
				emitter.Enabled = q > 0
			end
			if q > 0 and now >= e.nextWash then
				local n = math.min(q, e.item.fn.cap)
				washerQueue[e.uid] = q - n
				finishWash(n)
				e.nextWash = now + e.item.fn.interval
			elseif q == 0 then
				e.nextWash = now + e.item.fn.interval
			end
			e.model:SetAttribute("Queue", washerQueue[e.uid] or 0)
		end
	end
end

local function cookLoop()
	while true do
		task.wait(0.5)
		local now = workspace:GetServerTimeNow()
		for _, kind in ipairs({ "ricecooker", "pot" }) do
			for _, e in ipairs(Core.S.Entities.ofKind(kind)) do
				local d = data()
				local st = d and d.appliances[e.uid]
				if st and st.c > 0 and now >= st.t then
					st.n += st.c
					st.c = 0
					refresh(e)
					Core.S.Net.fx("ready", { pos = e.model.PrimaryPart.Position })
					Core.S.Data.changed(Core.S.Session.owner, "appliances")
				end
			end
		end
	end
end

function Appliance.fridgeNear(pos)
	for _, e in ipairs(Core.S.Entities.ofKind("fridge")) do
		local p = e.model.PrimaryPart.Position
		if (p - pos).Magnitude <= e.item.fn.radius then
			return true
		end
	end
	return false
end

function Appliance.Init()
	local Placement = Core.S.Placement
	Placement.ItemAdded:Connect(function(e)
		if e.kind == "ricecooker" or e.kind == "pot" then
			local st = state(e.uid)
			if e.kind == "ricecooker" then
				st.g = st.g or "rice"
			end
			-- anything that was cooking when the game was saved is ready now
			if st.c > 0 then
				st.n += st.c
				st.c = 0
			end
			refresh(e)
		end
	end)
	Placement.addVeto(function(e)
		if e.kind == "ricecooker" or e.kind == "pot" then
			local st = state(e.uid)
			if st.c > 0 then
				return false, "msg.cooking_wait"
			end
		elseif e.kind == "sink" and washing[e.uid] then
			return false, "msg.busy"
		end
		return true
	end)
end

function Appliance.Start()
	Core.S.Session.OwnerReady:Connect(function(_, d)
		d.dishes.clean = d.dishes.total -- everything was washed overnight
		sinkPile = 0
	end)
	task.spawn(cookLoop)
	task.spawn(dishwasherLoop)
end

return Appliance
