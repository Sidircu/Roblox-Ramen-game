-- A returning player: the offline earnings popup, then the daily gift calendar (day 3 of a streak).
Sim.startServer()
task.wait(1)
local S = Sim.core().S
local today = math.floor(os.time() / 86400)
local profile = S.Data.newProfile()
profile.level = 6
profile.meta.tutorial = -1
profile.meta.daily = { streak = 2, last = today - 1 }
profile.meta.lastSeen = os.time() - 3 * 3600
profile.stats.dayHistory = { 3000, 3000 }
profile.settings.lang = Sim.previewLang or "it"
Sim.store("ds", "Profiles_v1").__data["u_2001"] = { data = profile }
local p = Sim.addPlayer({ userId = 2001, name = "Kenji" })
Sim.startClient(p, Sim.previewDevice or "phone")
local C = Sim.waitFor(function()
	local core = Sim.clientRequire(p.PlayerScripts.Client.Core)
	return core.C.Data and core.C.Data.ready and core.C
end, 30)
Sim.waitFor(function()
	return C.UI.current == "Offline"
end, 6)
task.wait(0.5)
Sim.snapshot("offline")
C.UI.close("Offline")
Sim.waitFor(function()
	return C.UI.current == "Daily"
end, 6)
task.wait(1)
Sim.snapshot("daily")
