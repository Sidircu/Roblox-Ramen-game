-- Saving under stress: a profile still locked by another server, leaving during an autosave, a
-- server shutdown racing the last save, a data store outage while loading.
local store = Sim.store("ds", "Profiles_v1")
local function stored(p)
	return store.__data["u_" .. p.UserId]
end

-- 1) another server still holds the lock (it is finishing the player's last save)
store.__data["u_501"] = { data = { v = 8, yen = 12345, level = 7, xp = 0 }, lock = { job = "other-server", time = os.time() } }
local refreshing = true
task.spawn(function()
	-- the other server keeps the lock fresh for 20 s, then releases it
	while refreshing do
		task.wait(5)
		local e = store.__data["u_501"]
		if e and e.lock and e.lock.job == "other-server" then
			e.lock.time = os.time()
		end
	end
	local e = store.__data["u_501"]
	if e then
		e.lock = nil
	end
end)
task.delay(20, function()
	refreshing = false
end)

Sim.startServer()
task.wait(1)
local S = Sim.core().S
local a = Sim.addPlayer({ userId = 501, name = "Locked" })
task.wait(10)
Sim.check("waits while another server holds the profile", S.Data.get(a) == nil or S.Data.get(a).yen == 12345, "loaded a fresh profile while locked")
local da = Sim.waitFor(function()
	return S.Data.get(a)
end, 90)
Sim.check("then loads the real profile", da and da.yen == 12345 and da.level == 7, da and ("yen " .. tostring(da.yen)) or "never loaded")

-- 2) leaving while an autosave is running: the last change must still be saved and the lock released
local b = Sim.addPlayer({ userId = 502, name = "Leaver" })
local db = Sim.waitFor(function()
	return S.Data.get(b)
end, 30)
Sim.dsLatency = 1
db.yen = 777
task.spawn(S.Data.save, b, false) -- an autosave starts (snapshot with 777)
task.wait(0.2)
db.yen = 888 -- changed after the snapshot
Sim.removePlayer(b)
task.wait(8)
Sim.dsLatency = 0.04
local sb = stored(b)
Sim.check("last change saved after leaving during an autosave", sb and sb.data and sb.data.yen == 888, sb and sb.data and ("saved yen " .. tostring(sb.data.yen)) or "nothing saved")
Sim.check("lock released after leaving during an autosave", sb and sb.lock == nil, "lock still held")

-- 3) the server shuts down while the leave save is still in flight (alone on the server, so no
-- other save keeps the shutdown waiting by chance)
Sim.removePlayer(a)
task.wait(3)
local c = Sim.addPlayer({ userId = 503, name = "Closer" })
local dc = Sim.waitFor(function()
	return S.Data.get(c)
end, 30)
dc.yen = 4242
Sim.dsLatency = 1.5
Sim.removePlayer(c) -- the leave save starts (slow data store)
task.wait(0.1)
local closed = Sim.close() -- BindToClose must wait for it
local sc = stored(c)
Sim.check("server close waits for the leave save", closed and sc and sc.data and sc.data.yen == 4242, sc and sc.data and ("saved yen " .. tostring(sc.data.yen)) or "not saved before shutdown")
Sim.dsLatency = 0.04

-- 4) the data store is down while loading: no fresh profile is ever saved over the real one
store.__data["u_504"] = { data = { v = 8, yen = 999, level = 3, xp = 0 } }
Sim.allow("[Data]")
Sim.dsFail.UpdateAsync = 1000
local d4 = Sim.addPlayer({ userId = 504, name = "Outage" })
task.wait(60)
Sim.dsFail.UpdateAsync = 0
local p4 = S.Data.get(d4)
Sim.check("no fresh profile during an outage", p4 == nil or p4.yen == 999, p4 and ("yen " .. tostring(p4.yen)))
local s4 = store.__data["u_504"]
Sim.check("the stored profile is untouched after an outage", s4 and s4.data and s4.data.yen == 999)
