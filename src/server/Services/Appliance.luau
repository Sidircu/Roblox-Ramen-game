--!nonstrict
-- Rice cookers, broth pots, sink, dishwasher, fridges and the clean/dirty dish pool.
-- Sink: dirty dishes brought here pile up in the soaking basin; a player holds the click / E on
-- the sink to wash them one by one (hold sessions below), staff wash them on their own. The sink
-- model carries Washing / WashStart / WashTime / Washer so every client animates the plate and the
-- sponge (Controllers/Sink).
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Ingredients = require(Shared.Config.Ingredients)
local GameConfig = require(Shared.Config.GameConfig)
local Color = require(Shared.Util.Color)
local Registry = require(Shared.Models.Registry)
local Core = require(script.Parent.Parent.Core)

local Appliance = {}
local washerQueue = {} -- [uid] = count waiting
local sessions = {} -- [sink uid] = { actor, e, start, dur, staff }
local WASH = GameConfig.Washing

-- dirty plates waiting in the sink of each restaurant: plot.sinkPile
local function pile(plot)
	return plot and plot.sinkPile or 0
end

local function setPile(plot, n)
	plot.sinkPile = math.max(0, n)
	plot.folder:SetAttribute("SinkPile", plot.sinkPile)
end

-- saved state of a cooker / pot entity: { g, n, c, t }
local function state(e)
	local d = Core.S.Plots.data(e.plot)
	if not d then
		return { g = nil, n = 0, c = 0, t = 0 }
	end
	d.appliances[e.uid] = d.appliances[e.uid] or { g = nil, n = 0, c = 0, t = 0 }
	return d.appliances[e.uid]
end

local function refresh(e)
	if not e or not e.model then
		return
	end
	local st = state(e)
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
	local st = state(e)
	if hands.kind and hands.plot and hands.plot ~= e.plot then
		return false, "msg.other_restaurant"
	end
	if hands.kind ~= "box" then
		if st.c > 0 then
			return false, "msg.cooking_wait"
		end
		return false, e.kind == "ricecooker" and "msg.need_rice_box" or "msg.need_broth_box"
	end
	-- with a cart you may hold several boxes: use the first one that fits this appliance
	local index = nil
	for i, it in ipairs(hands.items) do
		local ig = Ingredients.byId[it.g]
		if not index and ig and ((e.kind == "ricecooker" and ig.storage == "rice") or (e.kind == "pot" and ig.storage == "broth")) then
			index = i
		end
	end
	if not index then
		return false, e.kind == "ricecooker" and "msg.need_rice_box" or "msg.need_broth_box"
	end
	local entry = hands.items[index]
	if (st.n > 0 or st.c > 0) and st.g ~= entry.g then
		return false, "msg.pot_other_broth"
	end
	local batch = e.item.fn.batch
	local amount = math.min(entry.n, batch - st.n - st.c)
	if amount <= 0 then
		return false, "msg.appliance_full"
	end
	st.g = entry.g
	if st.c > 0 then
		-- topping up while it cooks: joins the batch on the fire (same timer)
		st.c += amount
	else
		st.c = amount
		st.t = workspace:GetServerTimeNow() + e.item.fn.time
	end
	entry.n -= amount
	if entry.n <= 0 then
		Core.S.Supply.removeBox(e.plot, entry)
		Hands.removeAt(actor, index)
	else
		Hands.refresh(actor)
	end
	refresh(e)
	Core.S.Net.fx("sfx", { name = e.kind == "ricecooker" and "rice" or "pour", pos = e.model.PrimaryPart.Position })
	Core.S.Data.changed(e.plot.owner, "appliances")
	return true
end

local function takeFrom(plot, kind, g)
	for _, e in ipairs(Core.S.Entities.ofKind(kind, plot)) do
		local st = state(e)
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

function Appliance.hasRice(plot)
	for _, e in ipairs(Core.S.Entities.ofKind("ricecooker", plot)) do
		if state(e).n > 0 then
			return true
		end
	end
	return false
end

function Appliance.hasBroth(plot, g)
	for _, e in ipairs(Core.S.Entities.ofKind("pot", plot)) do
		local st = state(e)
		if st.n > 0 and st.g == g then
			return true
		end
	end
	return false
end

-- pending portions (cooking) count as "coming soon" for customer menus
function Appliance.willHave(plot, kind, g)
	for _, e in ipairs(Core.S.Entities.ofKind(kind, plot)) do
		local st = state(e)
		if (st.n + st.c) > 0 and (g == nil or st.g == g) then
			return true
		end
	end
	return false
end

function Appliance.takeRice(plot)
	return takeFrom(plot, "ricecooker", nil)
end

function Appliance.takeBroth(plot, g)
	return takeFrom(plot, "pot", g)
end

-- Appliances of a restaurant that need refilling (for staff)
function Appliance.needsRefill(plot)
	local out = {}
	for _, kind in ipairs({ "ricecooker", "pot" }) do
		for _, e in ipairs(Core.S.Entities.ofKind(kind, plot)) do
			local st = state(e)
			if st.c == 0 and st.n <= math.floor((e.item.fn.batch or 8) * 0.3) then
				table.insert(out, { entity = e, g = st.n > 0 and st.g or nil })
			end
		end
	end
	return out
end

------------------------------------------------------------------ dishes

function Appliance.takeCleanDish(plot)
	local d = Core.S.Plots.data(plot)
	if d and d.dishes.clean > 0 then
		d.dishes.clean -= 1
		Core.S.Data.changed(plot.owner, "dishes")
		return true
	end
	return false
end

function Appliance.addDirtyToSink(plot, n)
	if plot then
		setPile(plot, pile(plot) + n)
	end
end

local function sinkLocal(e, x, y, z)
	-- builder coordinates (floor at y = 0) to a world CFrame on the sink
	local h = e.item.size[2]
	return e.model.PrimaryPart.CFrame * CFrame.new(x, y - h / 2, z)
end

-- the sink that shows the pile (the first one placed)
local function mainSink(plot)
	local list = Core.S.Entities.ofKind("sink", plot)
	table.sort(list, function(a, b)
		return a.uid < b.uid
	end)
	return list[1]
end

-- dirty plates stacked in the soaking basin of the main sink
local function refreshPiles(plot)
	Registry.load()
	local main = mainSink(plot)
	for _, e in ipairs(Core.S.Entities.ofKind("sink", plot)) do
		if e.model and e.model.PrimaryPart then
			local want = (e == main) and math.min(pile(plot), WASH.MaxPile) or 0
			local stack = e.model:FindFirstChild("DirtyPile")
			if (stack and stack:GetAttribute("N") or 0) ~= want then
				if stack then
					stack:Destroy()
				end
				if want > 0 then
					stack = Instance.new("Model")
					stack.Name = "DirtyPile"
					stack:SetAttribute("N", want)
					for i = 1, want do
						local m = Registry.food("dirty", "plate")
						for _, d in ipairs(m:GetDescendants()) do
							if d:IsA("BasePart") then
								d.Anchored = true
								d.CanCollide = false
							end
						end
						-- a slightly messy stack: aiming at it aims at the sink
						local yaw = (i * 47) % 360
						m:PivotTo(sinkLocal(e, -1.1 + ((i % 3) - 1) * 0.05, 2.95 + (i - 1) * 0.13, -0.05) * CFrame.Angles(0, math.rad(yaw), 0))
						m.Parent = stack
					end
					stack.Parent = e.model
				end
			end
		end
	end
end

local function spoutEmitter(e)
	local spout = e.model and e.model:FindFirstChild("Spout")
	return spout and spout:FindFirstChildOfClass("ParticleEmitter")
end

local function setWashing(e, on, dur, actor)
	local m = e.model
	if not m then
		return
	end
	m:SetAttribute("Washing", on)
	m:SetAttribute("Busy", on)
	if on then
		m:SetAttribute("WashStart", workspace:GetServerTimeNow())
		m:SetAttribute("WashTime", dur)
		m:SetAttribute("Washer", typeof(actor) == "Instance" and actor.UserId or 0)
		Core.S.Net.fx("sfx", { name = "wash", pos = m.PrimaryPart.Position })
	else
		m:SetAttribute("Washer", 0)
	end
	local emitter = spoutEmitter(e)
	if emitter then
		emitter.Enabled = on
	end
end

function Appliance.sinkPile(plot)
	return pile(plot)
end

local function finishWash(plot, count)
	local d = Core.S.Plots.data(plot)
	if not d then
		return
	end
	d.dishes.clean = math.min(d.dishes.total, d.dishes.clean + count)
	d.stats.washed = (d.stats.washed or 0) + count
	Core.S.Data.changed(plot.owner, "dishes")
	Core.S.Meta.event(plot.owner, "wash", count)
end

-- one plate from the pile is clean: it slides to the drying rack on every client
local function washOne(e, actor)
	setPile(e.plot, pile(e.plot) - 1)
	finishWash(e.plot, 1)
	Core.S.Net.fx("washed", { uid = e.uid })
	Core.S.Net.fx("sfx", { name = "plate", pos = e.model.PrimaryPart.Position })
	if typeof(actor) == "Instance" then
		Core.S.Net.fxTo(actor, "action", { kind = "wash" })
	end
	refreshPiles(e.plot)
end

-- Sink: dirty dishes in hand go on the pile. Players then hold to wash (Appliance.hold); staff (and
-- the self test) wash the pile right away, dish by dish, with the same animation.
function Appliance.useSink(actor, e, speed)
	local Hands = Core.S.Hands
	local hands = Hands.get(actor)
	local isPlayer = typeof(actor) == "Instance"
	local plot = e.plot
	if hands.kind and hands.plot and hands.plot ~= plot then
		return false, "msg.other_restaurant"
	end
	if hands.kind == "dirty" then
		local n = #hands.items
		Hands.clear(actor)
		Appliance.addDirtyToSink(plot, n)
		refreshPiles(plot)
		Core.S.Net.fx("sfx", { name = "plate", pos = e.model.PrimaryPart.Position })
		if isPlayer then
			return true
		end
	elseif hands.kind ~= nil then
		return false, pile(plot) > 0 and "msg.hands_busy" or "msg.sink_hint"
	end
	if isPlayer then
		return false, pile(plot) > 0 and "msg.wash_hold" or "msg.sink_hint"
	end
	if sessions[e.uid] then
		return false, "msg.busy"
	end
	local dur = WASH.Time / (speed or 1)
	sessions[e.uid] = { actor = actor, e = e, staff = true }
	local count = 0
	while pile(plot) > 0 and count < WASH.StaffBatch and e.model and e.model.Parent do
		setWashing(e, true, dur, actor)
		task.wait(dur)
		washOne(e, actor)
		count += 1
	end
	sessions[e.uid] = nil
	setWashing(e, false)
	return count > 0
end

local function near(player, e)
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not hrp or not e.model or not e.model.PrimaryPart then
		return false
	end
	local p = e.model.PrimaryPart.Position
	local flat = (Vector3.new(p.X, 0, p.Z) - Vector3.new(hrp.Position.X, 0, hrp.Position.Z)).Magnitude
	return flat <= GameConfig.InteractRange + 3 and math.abs(p.Y - hrp.Position.Y) < 12
end

-- Hold to wash (remote "Wash"): on = true starts washing at this sink, false stops
function Appliance.hold(player, uid, on)
	if type(uid) ~= "string" then
		return
	end
	local e = Core.S.Entities.get(uid)
	if not e or e.kind ~= "sink" or not e.model or not e.model.PrimaryPart then
		return
	end
	local s = sessions[uid]
	if not on then
		if s and s.actor == player then
			sessions[uid] = nil
			setWashing(e, false)
		end
		return
	end
	if not Core.S.Plots.canWork(player, e.plot) then
		return
	end
	if s then
		if s.actor ~= player then
			Core.S.Net.notify(player, "msg.busy", nil, "info")
		end
		return
	end
	if not Core.S.Hands.isEmpty(player) then
		return Core.S.Net.notify(player, "msg.hands_busy", nil, "info")
	end
	if pile(e.plot) <= 0 then
		return Core.S.Net.notify(player, "msg.sink_hint", nil, "info")
	end
	if not near(player, e) then
		return Core.S.Net.notify(player, "msg.too_far", nil, "info")
	end
	sessions[uid] = { actor = player, e = e, start = os.clock(), dur = WASH.Time }
	setWashing(e, true, WASH.Time, player)
end

-- advances the players' hold sessions: one plate every WASH.Time while they keep holding
local function washLoop()
	while true do
		task.wait(0.1)
		for uid, s in pairs(sessions) do
			if not s.staff then
				local e = s.e
				local valid = e.model ~= nil and e.model.Parent ~= nil and Core.S.Entities.get(uid) ~= nil
				valid = valid and s.actor.Parent ~= nil and Core.S.Hands.isEmpty(s.actor) and near(s.actor, e)
				if not valid or pile(e.plot) <= 0 then
					sessions[uid] = nil
					setWashing(e, false)
				elseif os.clock() - s.start >= s.dur then
					washOne(e, s.actor)
					if pile(e.plot) > 0 then
						s.start = os.clock()
						setWashing(e, true, s.dur, s.actor)
					else
						sessions[uid] = nil
						setWashing(e, false)
					end
				end
			end
		end
	end
end

function Appliance.useDishwasher(actor, e)
	local Hands = Core.S.Hands
	local hands = Hands.get(actor)
	if hands.kind ~= "dirty" then
		return false, "msg.sink_hint"
	end
	if hands.plot and hands.plot ~= e.plot then
		return false, "msg.other_restaurant"
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
			local plot = e.plot
			if plot and pile(plot) > 0 and (washerQueue[e.uid] or 0) < e.item.fn.cap then
				local take = math.min(pile(plot), e.item.fn.cap - (washerQueue[e.uid] or 0))
				setPile(plot, pile(plot) - take)
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
				finishWash(plot, n)
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
				local d = Core.S.Plots.data(e.plot)
				local st = d and d.appliances[e.uid]
				if st and st.c > 0 and now >= st.t then
					st.n += st.c
					st.c = 0
					refresh(e)
					Core.S.Net.fx("ready", { pos = e.model.PrimaryPart.Position })
					Core.S.Data.changed(e.plot.owner, "appliances")
				end
			end
		end
	end
end

function Appliance.fridgeNear(plot, pos)
	for _, e in ipairs(Core.S.Entities.ofKind("fridge", plot)) do
		local p = e.model.PrimaryPart.Position
		if (p - pos).Magnitude <= e.item.fn.radius then
			return true
		end
	end
	return false
end

function Appliance.Init()
	Core.S.Net.on("Wash", Appliance.hold, 10)
	local Placement = Core.S.Placement
	Placement.ItemAdded:Connect(function(e)
		if e.kind == "ricecooker" or e.kind == "pot" then
			local st = state(e)
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
			local st = state(e)
			if st.c > 0 then
				return false, "msg.cooking_wait"
			end
		elseif e.kind == "sink" and sessions[e.uid] then
			return false, "msg.busy"
		end
		return true
	end)
end

function Appliance.Start()
	local Plots = Core.S.Plots
	Plots.Claimed:Connect(function(plot, _, d)
		d.dishes.clean = d.dishes.total -- everything was washed overnight
		setPile(plot, 0)
	end)
	Plots.Released:Connect(function(plot)
		setPile(plot, 0)
	end)
	task.spawn(cookLoop)
	task.spawn(dishwasherLoop)
	task.spawn(washLoop)
	-- keep the pile visible after the sink is moved or rebuilt
	task.spawn(function()
		while true do
			task.wait(1)
			for _, plot in ipairs(Plots.list) do
				if plot.owner then
					refreshPiles(plot)
				end
			end
		end
	end)
end

return Appliance
