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
local TableUtil = require(Shared.Util.TableUtil)
local Uid = require(Shared.Util.Uid)
local Signal = require(Shared.Util.Signal)
local Core = require(script.Parent.Parent.Core)

local Data = {}
Data.Loaded = Signal.new() -- (player, data)
Data.Changed = Signal.new() -- (player, key)

local VERSION = 1
local profiles = {} -- [player] = { data, key, loaded, saving }
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
		ads = {},
		boosts = {},
		meta = { quests = {}, questDay = 0, achievements = {}, daily = { streak = 0, last = 0 }, lastSeen = 0, tutorial = 0, offlinePending = 0 },
		franchise = { stars = 0, city = "tokyo" },
		perms = {},
		settings = { lang = "auto", grid = 1, rot = 90, music = 0.5, sfx = 0.8, lowGfx = false, autoDay = false },
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
	for idx, s in ipairs(StarterLayout.items) do
		if s.p then
			d.placed[idx].p = uids[s.p]
			local parent = StarterLayout.items[s.p]
			d.placed[idx].y = ItemsCfg.byId[parent.i].size[2]
		end
	end
	for _, b in ipairs(StarterLayout.boxes) do
		local ing = require(Shared.Config.Ingredients).byId[b.g]
		for _ = 1, b.n do
			table.insert(d.storage, { u = Uid.new("b"), g = b.g, n = ing.units })
		end
	end
	d.surfaces.base_dining = { floor = Surfaces.DefaultFloor, wall = Surfaces.DefaultWall }
	return d
end

local function migrate(d)
	d.v = d.v or 1
	-- future migrations: if d.v < 2 then ... d.v = 2 end
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

-- Notify clients that `k` changed in `player`'s profile.
function Data.changed(player, k)
	local d = Data.get(player)
	if not d then
		return
	end
	local Net = Core.S.Net
	Net.fire(player, "DataChanged", "me", k, payload(d[k]))
	local Session = Core.S.Session
	if WORLD_KEY_SET[k] and Session and Session.owner == player then
		for _, other in ipairs(Players:GetPlayers()) do
			Net.fire(other, "DataChanged", "world", k, payload(d[k]))
		end
	end
	Data.Changed:Fire(player, k)
end

function Data.snapshot(player)
	local d = Data.get(player)
	if not d then
		return nil
	end
	local me = TableUtil.deepCopy(d)
	me.receipts = nil
	local Session = Core.S.Session
	local world = nil
	if Session and Session.owner then
		local od = Data.get(Session.owner)
		if od then
			world = {}
			for _, k in ipairs(Data.WorldKeys) do
				world[k] = TableUtil.deepCopy(od[k])
			end
		end
	end
	return { me = me, world = world, session = Session and Session.info(player) or nil }
end

local function load(player)
	local p = { data = nil, loaded = false }
	profiles[player] = p
	local data = nil
	if storeOk then
		local ok, result = retry(function()
			return store:UpdateAsync(key(player.UserId), function(old)
				old = old or { data = nil, lock = nil }
				if old.lock and old.lock.job ~= game.JobId and os.time() - (old.lock.time or 0) < GameConfig.SessionLockSeconds then
					return nil -- locked by another server: do not write, retry later
				end
				old.lock = { job = game.JobId, time = os.time() }
				return old
			end)
		end, 3)
		if ok and result then
			data = result.data
		elseif ok and not result then
			-- still locked: wait for the lock to expire (another server is saving)
			for _ = 1, 6 do
				task.wait(5)
				local ok2, r2 = pcall(function()
					return store:UpdateAsync(key(player.UserId), function(old)
						old = old or {}
						if old.lock and old.lock.job ~= game.JobId and os.time() - (old.lock.time or 0) < 30 then
							return nil
						end
						old.lock = { job = game.JobId, time = os.time() }
						return old
					end)
				end)
				if ok2 and r2 then
					data = r2.data
					break
				end
			end
		else
			warn("[Data] load failed for " .. player.Name .. ": " .. tostring(result))
			p.noSave = true -- do not overwrite a profile we could not read
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

function Data.save(player, release)
	local p = profiles[player]
	if not p or not p.loaded or p.noSave or not storeOk then
		return false
	end
	if p.saving then
		return false
	end
	p.saving = true
	p.data.meta.lastSeen = os.time()
	local snapshot = TableUtil.deepCopy(p.data)
	local ok, err = retry(function()
		return store:UpdateAsync(key(player.UserId), function(old)
			old = old or {}
			if old.lock and old.lock.job ~= game.JobId and os.time() - (old.lock.time or 0) < GameConfig.SessionLockSeconds then
				return nil -- another server owns the profile
			end
			old.data = snapshot
			old.lock = (not release) and { job = game.JobId, time = os.time() } or nil
			return old
		end)
	end, 3)
	p.saving = false
	if not ok then
		warn("[Data] save failed for " .. player.Name .. ": " .. tostring(err))
	end
	return ok
end

function Data.storeAvailable()
	return storeOk
end

-- Saves immediately (used after Robux purchases).
function Data.saveNow(player)
	local p = profiles[player]
	if p then
		p.saving = false
	end
	return Data.save(player, false)
end

function Data.reset(player)
	local p = profiles[player]
	if p and p.loaded then
		p.data = Data.newProfile()
		Data.Loaded:Fire(player, p.data)
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
	end)
end

function Data.Start()
	Players.PlayerAdded:Connect(function(player)
		load(player)
	end)
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(load, player)
	end
	Players.PlayerRemoving:Connect(function(player)
		Data.save(player, true)
		profiles[player] = nil
	end)
	game:BindToClose(function()
		local pending = 0
		for player in pairs(profiles) do
			pending += 1
			task.spawn(function()
				Data.save(player, true)
				pending -= 1
			end)
		end
		local t0 = os.clock()
		while pending > 0 and os.clock() - t0 < 25 do
			task.wait(0.2)
		end
	end)
	task.spawn(function()
		while true do
			task.wait(GameConfig.AutosaveSeconds)
			for player in pairs(profiles) do
				task.spawn(Data.save, player, false)
			end
		end
	end)
end

local _ = { RunService, HttpService }
return Data
