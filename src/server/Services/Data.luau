--!nonstrict
-- Player profiles: loading, session locking, autosave, migrations and replication to clients.
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local StarterLayout = require(Shared.Config.StarterLayout)
local Surfaces = require(Shared.Config.Surfaces)
local Recipes = require(Shared.Config.Recipes)
local Ingredients = require(Shared.Config.Ingredients)
local ShelfGrid = require(Shared.Logic.ShelfGrid)
local TableUtil = require(Shared.Util.TableUtil)
local Uid = require(Shared.Util.Uid)
local Signal = require(Shared.Util.Signal)
local Locale = require(Shared.Locale)
local Core = require(script.Parent.Parent.Core)

local Data = {}
Data.Loaded = Signal.new() -- (player, data)
Data.Changed = Signal.new() -- (player, key)

local VERSION = 12
local profiles = {} -- [player] = { data, loaded, saving, released }
local releasing = {} -- [userId] = true while the final save of a player who left is running
local activeSaves = 0
local store = nil
local storeOk = false

-- Keys of the owner's profile that describe the restaurant (sent to every player in the world)
Data.WorldKeys = {
	"level", "xp", "licenses", "menu", "mastery", "upgrades", "zones", "surfaces", "placed",
	"staff", "reviews", "dishes", "franchise", "boosts", "ads", "perms", "stats", "storage",
	"shelves", "appliances", "inventory", "yen", "sakura", "settings",
}
local WORLD_KEY_SET = {}
for _, k in ipairs(Data.WorldKeys) do
	WORLD_KEY_SET[k] = true
end

function Data.newProfile()
	local d = {
		v = VERSION,
		yen = GameConfig.StartYen,
		sakura = 0,
		xp = 0,
		level = 1,
		reviews = { recent = {}, total = 0, sum = 0 },
		stats = { dishes = 0, customers = 0, earned = 0, days = 0, five_stars = 0, washed = 0, decor = 0, gold_mastery = 0, lastDayEarned = 0, dayHistory = {} },
		licenses = { lic_base = true },
		menu = {},
		mastery = {},
		upgrades = {},
		zones = { zone_base = true },
		surfaces = {},
		placed = {},
		inventory = {},
		storage = {},
		shelves = {},
		appliances = {},
		dishes = { clean = GameConfig.StartDishes, total = GameConfig.StartDishes },
		staff = {},
		tipJar = 0,
		ads = {},
		boosts = {},
		meta = { quests = {}, questDay = 0, achievements = {}, daily = { streak = 0, last = 0 }, lastSeen = 0, tutorial = 0, tutorialGifts = {}, hints = {}, offlinePending = 0, codes = {}, onboarding = true, funnel = {} },
		franchise = { stars = 0, city = "tokyo" },
		perms = {},
		settings = { lang = "auto", grid = 1, rot = 90, music = 0.5, sfx = 0.8, lowGfx = false, cam = "auto", camSpeed = GameConfig.Sensitivity.Medium, coop = "friends", others = "show" },
		passes = {},
		receipts = {},
		created = os.time(),
	}
	for _, r in ipairs(Recipes.list) do
		if r.license == "lic_base" then
			d.menu[r.id] = { on = true, price = 1 }
		end
	end
	local uids = {}
	for idx, s in ipairs(StarterLayout.items) do
		local e = { u = Uid.new("p"), i = s.i, x = s.x, z = s.z, r = s.r or 0, f = 0, s = s.s, t = 0 }
		if s.y then
			e.y = s.y
		end
		uids[idx] = e.u
		table.insert(d.placed, e)
	end
	local ItemsCfg = require(Shared.Config.Items)
	-- the first time the broth is already in the pot and the rice in the cooker
	for idx, s in ipairs(StarterLayout.items) do
		local fn = ItemsCfg.byId[s.i].fn
		if fn and fn.type == "pot" then
			d.appliances[uids[idx]] = { g = StarterLayout.broth or "broth_shoyu", n = fn.batch, c = 0, t = 0 }
		elseif fn and fn.type == "ricecooker" then
			d.appliances[uids[idx]] = { g = "rice", n = fn.batch, c = 0, t = 0 }
		end
	end
	for idx, s in ipairs(StarterLayout.items) do
		if s.p then
			d.placed[idx].p = uids[s.p]
			local parent = StarterLayout.items[s.p]
			d.placed[idx].y = ItemsCfg.byId[parent.i].size[2]
		end
	end
	-- the shelves start stocked (StarterLayout.stock): every listed slot full
	local shelfIndex = 0
	for idx, s in ipairs(StarterLayout.items) do
		local fn = ItemsCfg.byId[s.i].fn
		if fn and fn.type == "shelf" then
			shelfIndex += 1
			local list = StarterLayout.stock and StarterLayout.stock[shelfIndex]
			if list then
				local slots = {}
				for k, g in ipairs(list) do
					local ing = Ingredients.byId[g]
					if ing and k <= fn.slots then
						local cols, rows = ShelfGrid.forIngredient(ing.units, GameConfig.BoxShelfSlots, 1)
						slots[tostring(k)] = { g = g, n = cols * rows }
					end
				end
				d.shelves[uids[idx]] = slots
			end
		end
	end
	for _, b in ipairs(StarterLayout.boxes) do
		local ing = Ingredients.byId[b.g]
		for _ = 1, b.n do
			table.insert(d.storage, { u = Uid.new("b"), g = b.g, n = ing.units })
		end
	end
	d.surfaces.base_dining = { floor = Surfaces.DefaultFloor, wall = Surfaces.DefaultWall }
	return d
end

-- Puts every bought object in the inventory, rebuilds the starter layout and moves shelf stock
-- back into boxes (used when the starter layout changes size)
local function rebuildLayout(d)
	do
		d.inventory = d.inventory or {}
		d.storage = d.storage or {}
		local starter = {}
		for _, s in ipairs(StarterLayout.items) do
			starter[s.i] = (starter[s.i] or 0) + 1
		end
		for _, e in ipairs(d.placed or {}) do
			if (starter[e.i] or 0) > 0 then
				starter[e.i] -= 1
			else
				d.inventory[e.i] = (d.inventory[e.i] or 0) + 1
			end
		end
		for _, slots in pairs(d.shelves or {}) do
			for _, slot in pairs(slots) do
				if slot.g and (slot.n or 0) > 0 then
					table.insert(d.storage, { u = Uid.new("b"), g = slot.g, n = slot.n })
				end
			end
		end
		for _, b in ipairs(d.storage) do
			b.px, b.pz, b.pf, b.pr, b.h = nil, nil, nil, nil, nil
		end
		local fresh = Data.newProfile()
		d.placed = fresh.placed
		d.shelves = {}
		d.appliances = fresh.appliances
	end
end

local function migrate(d)
	d.v = d.v or 1
	if d.v < 2 then
		-- v2: the restaurant is twice as big
		rebuildLayout(d)
		d.v = 2
	end
	if d.v < 3 then
		-- v3: longer counter with twelve stools, bigger shelves, first-person camera by default
		rebuildLayout(d)
		d.settings = d.settings or {}
		if d.settings.cam == nil or d.settings.cam == "game" then
			d.settings.cam = "first"
		end
		d.v = 3
	end
	if d.v < 4 then
		-- v4: fitted kitchen unit (rice cooker, gas range, worktops, sink) and grid shelves
		rebuildLayout(d)
		d.v = 4
	end
	if d.v < 5 then
		-- v5: basic sushi moved from the starter license to lic_sushi0: players who already had it
		-- keep it
		d.licenses = d.licenses or {}
		if d.licenses.lic_base then
			d.licenses.lic_sushi0 = true
		end
		d.v = 5
	end
	if d.v < 6 then
		-- v6: shelves next to the storage door, tip jar on the counter, salmon sashimi license
		-- (whoever had basic sushi gets it too), broth and rice ready in the new kitchen
		rebuildLayout(d)
		if d.licenses and d.licenses.lic_sushi0 then
			d.licenses.lic_sashimi = true
		end
		d.v = 6
	end
	if d.v < 7 then
		-- v7: lower, deeper counter in 3-stud modules with a place setting each, stools 3 apart
		rebuildLayout(d)
		d.v = 7
	end
	if d.v < 8 then
		-- v8: shallower kitchen (14 studs) with everything on the back wall
		rebuildLayout(d)
		d.v = 8
	end
	if d.v < 9 then
		-- v9: the onboarding funnel only counts players who start after this version
		d.meta = d.meta or {}
		d.meta.onboarding = false
		d.v = 9
	end
	if d.v < 10 then
		-- v10: the restaurant is always open; the camera picks itself (third person on phones and
		-- tablets, first person with a keyboard)
		d.settings = d.settings or {}
		if d.settings.cam == nil or d.settings.cam == "first" then
			d.settings.cam = "auto"
		end
		d.settings.autoDay = nil
		-- the tutorial changed: whoever was halfway through starts the new, shorter one
		d.meta = d.meta or {}
		if (d.meta.tutorial or 0) > 0 then
			d.meta.tutorial = 1
		end
		d.v = 10
	end
	if d.v < 11 then
		-- v11: a new, two-minute tutorial with gifts; whoever was halfway through starts it again
		d.meta = d.meta or {}
		if (d.meta.tutorial or 0) > 0 then
			d.meta.tutorial = 1
		end
		d.v = 11
	end
	if d.v < 12 then
		-- v12: the look sensitivity is faster (Settings → Sensitivity: high, medium, low); the old
		-- slow / medium / fast choices move to low / medium / high
		d.settings = d.settings or {}
		local old = d.settings.camSpeed
		local S = GameConfig.Sensitivity
		if old ~= nil then
			d.settings.camSpeed = (old < 0.8 and S.Low) or (old < 1.3 and S.Medium) or S.High
		end
		d.v = 12
	end
	TableUtil.reconcile(d, Data.newProfile())
	d.v = VERSION
	return d
end

local function key(userId)
	return "u_" .. tostring(userId)
end

local function retry(fn, attempts)
	local lastErr
	for i = 1, attempts or 4 do
		local ok, a, b = pcall(fn)
		if ok then
			return true, a, b
		end
		lastErr = a
		task.wait(1.5 * i)
	end
	return false, lastErr
end

function Data.get(player)
	local p = profiles[player]
	return p and p.loaded and p.data or nil
end

function Data.isLoaded(player)
	local p = profiles[player]
	return p ~= nil and p.loaded == true
end

function Data.waitFor(player, timeout)
	local t0 = os.clock()
	while player.Parent and not Data.isLoaded(player) do
		if timeout and os.clock() - t0 > timeout then
			return nil
		end
		task.wait(0.1)
	end
	return Data.get(player)
end

local function payload(value)
	return TableUtil.deepCopy(value)
end

-- Notify clients that `k` changed in `player`'s profile: the player gets it as "me"; the helpers
-- working in their restaurant get the restaurant keys as "world".
function Data.changed(player, k)
	local d = Data.get(player)
	if not d then
		return
	end
	local Net = Core.S.Net
	Net.fire(player, "DataChanged", "me", k, payload(d[k]))
	local Plots = Core.S.Plots
	local plot = WORLD_KEY_SET[k] and Plots and Plots.ofPlayer(player)
	if plot then
		for _, other in ipairs(Plots.workers(plot)) do
			if other ~= player then
				Net.fire(other, "DataChanged", "world", k, payload(d[k]))
			end
		end
	end
	Data.Changed:Fire(player, k)
end

-- the restaurant keys of a plot's owner (what helpers see as "world")
function Data.worldOf(plot)
	local od = plot and plot.owner and Data.get(plot.owner)
	if not od then
		return nil
	end
	local world = {}
	for _, k in ipairs(Data.WorldKeys) do
		world[k] = TableUtil.deepCopy(od[k])
	end
	return world
end

function Data.snapshot(player)
	local d = Data.get(player)
	if not d then
		return nil
	end
	local me = TableUtil.deepCopy(d)
	me.receipts = nil
	local Plots = Core.S.Plots
	local plot = Plots and Plots.of(player)
	-- in your own restaurant "world" is your own data (the client uses "me")
	local world = (plot and plot.owner ~= player) and Data.worldOf(plot) or nil
	return { me = me, world = world, session = Plots and Plots.info(player) or nil }
end

-- Takes the session lock of a profile. Returns ok (the call worked), the saved data (nil for a new
-- player), and locked = true when another server still holds the profile (it is finishing the
-- player's last save there). force takes the lock anyway: a player can only be in one server, so a
-- lock that is not released in time belongs to a server that will never save this profile again.
local function acquire(userId, force)
	local locked = false
	local ok, result = pcall(function()
		return store:UpdateAsync(key(userId), function(old)
			locked = false
			old = old or {}
			local lock = old.lock
			if not force and lock and lock.job ~= game.JobId and os.time() - (lock.time or 0) < GameConfig.SessionLockSeconds then
				locked = true
				return nil
			end
			old.lock = { job = game.JobId, time = os.time() }
			return old
		end)
	end)
	if not ok then
		return false, nil, false, result
	end
	if locked then
		return true, nil, true
	end
	return true, result and result.data, false
end

local function releaseLock(userId)
	pcall(function()
		store:UpdateAsync(key(userId), function(old)
			if not old or not old.lock or old.lock.job ~= game.JobId then
				return nil
			end
			old.lock = nil
			return old
		end)
	end)
end

local function kick(player, msgKey)
	if player.Parent then
		player:Kick(Locale.tFor(player.LocaleId, msgKey))
	end
end

local function load(player)
	-- the same player may still be saving here from a moment ago (left and came back): wait for it
	local t0 = os.clock()
	while releasing[player.UserId] and os.clock() - t0 < 30 do
		task.wait(0.2)
	end
	local p = { data = nil, loaded = false }
	profiles[player] = p
	local data = nil
	if storeOk then
		local acquired, attempt, errors, told = false, 0, 0, false
		local started = os.clock()
		while player.Parent do
			attempt += 1
			local force = os.clock() - started >= GameConfig.LockWaitSeconds
			local ok, d, locked, err = acquire(player.UserId, force)
			if ok and not locked then
				data = d
				acquired = true
				break
			elseif ok then
				-- another server still holds the profile: it releases it as soon as its save is done
				if not told then
					told = true
					Core.S.Net.notify(player, "msg.loading_wait", nil, "info")
				end
				task.wait(5)
			else
				errors += 1
				warn("[Data] load attempt " .. errors .. " failed for " .. player.Name .. ": " .. tostring(err))
				if errors >= 5 then
					break
				end
				task.wait(2 * errors)
			end
		end
		if not acquired then
			-- never play on an empty profile: the real one could be overwritten later
			profiles[player] = nil
			kick(player, "msg.load_failed")
			return
		end
		if not player.Parent then
			profiles[player] = nil
			releaseLock(player.UserId)
			return
		end
	end
	if not player.Parent then
		profiles[player] = nil
		return
	end
	if type(data) == "table" then
		data = migrate(data)
	else
		data = Data.newProfile()
	end
	p.data = data
	p.loaded = true
	Data.Loaded:Fire(player, data)
end

-- Saves a profile. One save at a time per player: a save asked while another is running waits for
-- it and then saves again, so the last changes (and the lock release on leaving) are never skipped.
function Data.save(player, release)
	local p = profiles[player]
	if not p or not p.loaded or p.noSave or not storeOk then
		return false
	end
	local t0 = os.clock()
	while p.saving and os.clock() - t0 < 60 do
		task.wait(0.1)
	end
	if p.released then
		return true
	end
	p.saving = true
	activeSaves += 1
	p.data.meta.lastSeen = os.time()
	local snapshot = TableUtil.deepCopy(p.data)
	local lost = false
	local ok, err = retry(function()
		return store:UpdateAsync(key(player.UserId), function(old)
			lost = false
			old = old or {}
			if old.lock and old.lock.job ~= game.JobId then
				lost = true -- another server took the profile over: never write over its data
				return nil
			end
			old.data = snapshot
			old.lock = (not release) and { job = game.JobId, time = os.time() } or nil
			return old
		end)
	end, 3)
	activeSaves -= 1
	p.saving = false
	if not ok then
		warn("[Data] save failed for " .. player.Name .. ": " .. tostring(err))
	elseif lost then
		warn("[Data] save skipped for " .. player.Name .. ": the profile is open on another server")
	elseif release then
		p.released = true
	end
	return ok and not lost
end

function Data.storeAvailable()
	return storeOk
end

-- Saves immediately (used after Robux purchases).
function Data.saveNow(player)
	return Data.save(player, false)
end

function Data.reset(player)
	local p = profiles[player]
	if p and p.loaded then
		p.data = Data.newProfile()
		Data.Loaded:Fire(player, p.data)
	end
end

-- Final save of a player who leaves (or of everyone when the server closes)
local function releaseProfile(player)
	local p = profiles[player]
	if not p then
		return
	end
	releasing[player.UserId] = true
	Data.save(player, true)
	releasing[player.UserId] = nil
	if profiles[player] == p then
		profiles[player] = nil
	end
end

function Data.Init()
	local ok, s = pcall(function()
		return DataStoreService:GetDataStore(GameConfig.DataStoreName)
	end)
	if ok and s then
		store = s
		-- in Studio without API access every call errors: probe once
		local probeOk = pcall(function()
			s:GetAsync("probe")
		end)
		storeOk = probeOk
		if not probeOk then
			warn("[Data] DataStore not available (enable Studio Access to API Services to save in Studio). Playing without saving.")
		end
	end
	Core.S.Net.invoke("GetSnapshot", function(player)
		Data.waitFor(player, 30)
		return Data.snapshot(player)
	end, 1)
end

function Data.Start()
	-- a player who starts working in another restaurant gets its data
	Core.S.Plots.WorkChanged:Connect(function(player, plot)
		local world = (plot and plot.owner ~= player) and Data.worldOf(plot) or nil
		Core.S.Net.fire(player, "WorldSnapshot", world)
	end)
	Players.PlayerAdded:Connect(function(player)
		load(player)
	end)
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(load, player)
	end
	Players.PlayerRemoving:Connect(releaseProfile)
	game:BindToClose(function()
		-- release every profile still open, then wait for every save in flight (including the
		-- ones started by players leaving at the same moment)
		for player in pairs(profiles) do
			task.spawn(releaseProfile, player)
		end
		local t0 = os.clock()
		while os.clock() - t0 < 25 do
			local busy = activeSaves > 0 or next(releasing) ~= nil
			for _, p in pairs(profiles) do
				if p.loaded and not p.released and not p.noSave and storeOk then
					busy = true
				end
			end
			if not busy then
				break
			end
			task.wait(0.2)
		end
	end)
	task.spawn(function()
		while true do
			task.wait(GameConfig.AutosaveSeconds)
			for player, p in pairs(profiles) do
				if p.loaded and not p.saving and not p.released then
					task.spawn(Data.save, player, false)
				end
			end
		end
	end)
end

local _ = { RunService, HttpService }
return Data
