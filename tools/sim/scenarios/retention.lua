-- A returning player on a phone: away for three hours and back on the third day of a streak. The
-- offline earnings popup comes first (everybody gets the first hour at 5%), then the daily gift
-- calendar opens by itself; claiming it moves the streak on and pays day 3 once. The ranking
-- boards across the road show the best players in the player's language, and the Extra staff pass
-- adds two places to the team.
Sim.startServer()
task.wait(1)
local S = Sim.core().S
local GameConfig = Sim.shared("Config.GameConfig")
local DailyRewards = Sim.shared("Config.DailyRewards")
local Upgrades = Sim.shared("Config.Upgrades")
local StaffCfg = Sim.shared("Config.Staff")
local Plots = Sim.shared("Config.Plots")
local today = math.floor(os.time() / 86400)

-- the leaderboards already know some players
local lbDishes = Sim.store("ods", "LB_Dishes_v1")
lbDishes.__data["501"] = 9000
lbDishes.__data["502"] = 12000
lbDishes.__data["503"] = 700
Sim.store("ods", "LB_Earned_v1").__data["501"] = 2500000

-- a saved restaurant: tutorial done, day 2 of the streak claimed yesterday, last seen 3 hours ago
local profile = S.Data.newProfile()
profile.level = 6
profile.yen = 50000
profile.meta.tutorial = -1
profile.meta.daily = { streak = 2, last = today - 1 }
profile.meta.lastSeen = os.time() - 3 * 3600
profile.stats.dayHistory = { 3000, 3000 }
profile.stats.dishes = 1234
profile.settings.lang = "it"
-- saved before version 12, with the old "medium" camera speed
profile.v = 11
profile.settings.camSpeed = 1
Sim.store("ds", "Profiles_v1").__data["u_2001"] = { data = profile }

local p = Sim.addPlayer({ userId = 2001, name = "Kenji" })
Sim.startClient(p, "phone")
local d = Sim.waitFor(function()
	return S.Data.get(p)
end, 30)
Sim.check("profile loaded", d ~= nil)
local C = Sim.waitFor(function()
	local core = Sim.clientRequire(p.PlayerScripts.Client.Core)
	return core.C.Data and core.C.Data.ready and core.C
end, 30)
Sim.check("the client is ready", C ~= nil)
local Locale = Sim.clientRequire(game:GetService("ReplicatedStorage").Shared.Locale)
local Format = Sim.clientRequire(game:GetService("ReplicatedStorage").Shared.Util.Format)
local t = Locale.t

-- earnings while away: no safe, so one hour at the first level's rate
local D = GameConfig.Day
local night = (24 - D.NightFrom) + D.NightTo
local daySeconds = (24 - night) * D.SecondsPerHour + night * D.NightSecondsPerHour
local safe = Upgrades.byId.up_safe
local expected = math.floor(3000 * 3600 / daySeconds * safe.pct[1] * safe.values[1] + 0.5)
local pending = d.meta.offlinePending or 0
Sim.check("earnings while away without the safe (first hour at 5%)", math.abs(pending - expected) <= 1, pending .. " vs " .. expected)
Sim.check("the offline popup comes first", Sim.waitFor(function()
	return C.UI.current == "Offline"
end, 6) == true, tostring(C.UI.current))

local function buttonIn(screen, pattern)
	local win = C.UI.screens[screen] and C.UI.screens[screen].win
	if not win then
		return nil
	end
	for _, b in ipairs(win.frame:GetDescendants()) do
		if b:IsA("TextButton") and b.Text:find(pattern, 1, true) then
			return b
		end
	end
	return nil
end
local yen = d.yen
local claimOffline = buttonIn("Offline", Format.yen(pending, Locale.get()))
Sim.check("the offline popup shows the amount on its button", claimOffline ~= nil)
if claimOffline then
	Sim.click(claimOffline)
end
Sim.waitFor(function()
	return d.yen > yen
end, 5)
Sim.check("the offline earnings are paid", d.yen >= yen + pending and (d.meta.offlinePending or 0) == 0, yen .. " -> " .. d.yen)

-- the daily gift calendar opens by itself once the offline popup is closed
Sim.check("the daily calendar opens after it", Sim.waitFor(function()
	return C.UI.current == "Daily"
end, 6) == true, tostring(C.UI.current))
Sim.check("the calendar shows its days in Italian", Sim.findText(t("ui.day_n", { n = 3 })) ~= nil and Sim.findText(t("ui.daily_hint")) ~= nil)
Sim.snapshot("daily_calendar")
local sakura = d.sakura
local claim = C.UI.screens.Daily.win.frame:FindFirstChild("Claim", true)
Sim.check("today's gift has a big button", claim ~= nil and claim.Text:find(t("ui.claim"), 1, true) ~= nil, claim and claim.Text)
if claim then
	Sim.click(claim)
end
Sim.waitFor(function()
	return d.meta.daily.last == today
end, 5)
Sim.check("claiming moves the streak to day 3", d.meta.daily.last == today and d.meta.daily.streak == 3, d.meta.daily.streak .. "")
Sim.check("day 3 pays its sakura", d.sakura == sakura + DailyRewards.days[3].sakura, sakura .. " -> " .. d.sakura)
Sim.check("the calendar closes by itself", Sim.waitFor(function()
	return C.UI.current == nil
end, 4) == true, tostring(C.UI.current))
Sim.fire(p, "ClaimDaily")
task.wait(0.5)
Sim.check("today's gift is paid once", d.sakura == sakura + DailyRewards.days[3].sakura and d.meta.daily.streak == 3)
-- the Dev panel brings tomorrow's gift for testing in Studio
Sim.fire(p, "Dev", "nextday")
task.wait(0.5)
Sim.check("Dev: next day's gift is ready", d.meta.daily.last == today - 1 and C.UI.screens.Daily.ready())
Sim.fire(p, "ClaimDaily")
task.wait(0.5)
Sim.check("and it is day 4", d.meta.daily.streak == 4 and d.meta.daily.last == today, d.meta.daily.streak .. "")

-- the ranking boards: one across the road from every restaurant, written in the player's language
local CS = game:GetService("CollectionService")
local boards = CS:GetTagged("RankingBoard")
Sim.check("a ranking board across from every restaurant", #boards == Plots.Count, #boards .. " boards")
local mineBoard = nil
local home = S.Plots.ofPlayer(p)
for _, b in ipairs(boards) do
	local pos = b:GetPivot().Position
	if home and math.abs(pos.X - home.origin.X) < 1 then
		mineBoard = b
	end
end
Sim.check("the board stands across the road from the door", mineBoard ~= nil and mineBoard:GetPivot().Position.Z < 0)
local panel = mineBoard and mineBoard:FindFirstChild("Panel_dishes")
local gui = Sim.waitFor(function()
	local g = panel and panel:FindFirstChild("Ranking")
	return g and g:FindFirstChild("Row1") and g.Row1.Who.Text:find("User502", 1, true) and g
end, 8)
Sim.check("the dishes board shows the best player first", gui ~= nil, panel and panel:FindFirstChild("Ranking") and panel.Ranking.Row1.Who.Text)
if gui then
	Sim.check("the board's title is in Italian", gui.Title.Text:find(t("lb.dishes"), 1, true) ~= nil, gui.Title.Text)
	Sim.check("the board shows your own number", gui.You.Value.Text == Format.number(d.stats.dishes, Locale.get()), gui.You.Value.Text)
	Sim.check("an empty place says so", gui.Row4.Who.Text:find("—", 1, true) ~= nil, gui.Row4.Who.Text)
end
local earned = mineBoard and mineBoard:FindFirstChild("Panel_earned")
Sim.check("the yen board writes yen", earned and earned:FindFirstChild("Ranking") and earned.Ranking.Row1.Value.Text == Format.yen(2500000, Locale.get()), earned and earned:FindFirstChild("Ranking") and earned.Ranking.Row1.Value.Text)

-- Settings → Sensitivity: the old medium became the new, faster medium; only the three choices
local Sens = GameConfig.Sensitivity
Sim.check("old saves get the new medium sensitivity", d.settings.camSpeed == Sens.Medium, tostring(d.settings.camSpeed))
Sim.fire(p, "SetSetting", "camSpeed", Sens.High)
task.wait(0.3)
Sim.check("high sensitivity is saved", d.settings.camSpeed == Sens.High, tostring(d.settings.camSpeed))
Sim.fire(p, "SetSetting", "camSpeed", 9)
task.wait(0.3)
Sim.check("a made-up sensitivity is refused", d.settings.camSpeed == Sens.High, tostring(d.settings.camSpeed))
-- the setting reaches Roblox's own camera: right after it turns the view, the turn is scaled
-- (a 2 degree turn becomes 3.2 with medium, 4.8 with high; a jump such as a teleport is left alone)
do
	local Cam = C.Camera
	local cam = workspace.CurrentCamera
	local function yawOf()
		local l = cam.CFrame.LookVector
		return math.deg(math.atan2(-l.X, -l.Z))
	end
	local function robloxTurn(deg)
		local l = cam.CFrame.LookVector
		local yaw = math.atan2(-l.X, -l.Z) + math.rad(deg)
		local pos = cam.Focus.Position
		cam.CFrame = CFrame.lookAt(pos - Vector3.new(-math.sin(yaw), 0, -math.cos(yaw)) * 0.5, pos)
	end
	cam.Focus = CFrame.new(0, 5, 0)
	cam.CFrame = CFrame.lookAt(Vector3.new(0, 5, 0.5), Vector3.new(0, 5, 0))
	Cam.scaleTurn(cam, Sens.Medium)
	local before = yawOf()
	robloxTurn(2)
	Cam.scaleTurn(cam, Sens.Medium)
	Sim.check("medium sensitivity: 1.6 times Roblox's turn", math.abs((yawOf() - before) - 2 * Sens.Medium) < 0.05, string.format("%.2f", yawOf() - before))
	before = yawOf()
	robloxTurn(2)
	Cam.scaleTurn(cam, Sens.High)
	Sim.check("high sensitivity: 2.4 times", math.abs((yawOf() - before) - 2 * Sens.High) < 0.05, string.format("%.2f", yawOf() - before))
	before = yawOf()
	robloxTurn(90)
	Cam.scaleTurn(cam, Sens.High)
	Sim.check("a jump of the camera is not scaled", math.abs((yawOf() - before) - 90) < 0.05, string.format("%.2f", yawOf() - before))
end
C.UI.open("Settings")
task.wait(0.5)
Sim.check("the settings offer high, medium and low", Sim.findText(t("ui.sens_high")) ~= nil and Sim.findText(t("ui.sens_medium")) ~= nil and Sim.findText(t("ui.sens_low")) ~= nil)
Sim.snapshot("settings_sensitivity")
C.UI.close("Settings")

-- the Extra staff pass: two more places in the team
local base = S.Progression.staffSlots(d)
for i = 1, base do
	Sim.fire(p, "HireStaff", i == 1 and "staff_dishwasher" or "staff_waiter")
	task.wait(0.3)
end
Sim.check("the team is full without the pass", #d.staff == base, #d.staff .. "/" .. base)
Sim.fire(p, "HireStaff", "staff_waiter")
task.wait(0.3)
Sim.check("no place for one more", #d.staff == base)
d.passes.gp_extra_staff = true
S.Data.changed(p, "passes")
Sim.check("the pass adds two places", S.Progression.staffSlots(d) == base + StaffCfg.PassSlots)
Sim.fire(p, "HireStaff", "staff_waiter")
task.wait(0.3)
Sim.check("with the pass one more helper joins", #d.staff == base + 1, #d.staff .. "")
Sim.check("server closes cleanly", Sim.close())
