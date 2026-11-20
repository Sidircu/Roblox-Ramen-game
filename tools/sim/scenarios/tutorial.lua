-- A brand-new player on a phone plays the whole tutorial through the real client, doing only what
-- the banner says: the order comes, three presses cook it, the bowl is served, the gift opens the
-- shop and a green card buys an upgrade, the dirty bowl is collected and washed, and the last gift
-- closes the tutorial for good. Checks the gifts, the analytics step and the two-minute goal; then
-- a one-time tip shows up after the tutorial and is not shown again.
Sim.startServer()
task.wait(1)
local S = Sim.core().S
local TutorialCfg = Sim.shared("Config.Tutorial")
local p = Sim.addPlayer({ name = "Newbie" })
Sim.startClient(p, "phone")
local t0 = Sim.now
local d = Sim.waitFor(function()
	return S.Data.get(p)
end, 30)
local C = Sim.waitFor(function()
	local core = Sim.clientRequire(p.PlayerScripts.Client.Core)
	return core.C.Data and core.C.Data.ready and core.C
end, 30)
Sim.check("the client is ready", C ~= nil)
local Tut = C.Tutorial
local plot = S.Plots.ofPlayer(p)
local function step()
	return Tut.currentId()
end
local function waitStep(id, timeout)
	return Sim.waitFor(function()
		return step() == id
	end, timeout or 30) ~= nil
end
local function use(model, hold)
	local pos = model:GetPivot().Position
	local from = pos + Vector3.new(0, 0, -3)
	p.Character:PivotTo(CFrame.lookAt(from, Vector3.new(pos.X, from.Y, pos.Z)))
	task.wait(0.6)
	return Sim.trigger(model, hold)
end
local banner = p.PlayerGui.RamenUI:FindFirstChild("Tutorial")
-- the first card waits for the loading screen, then stays long enough to be read
Sim.check("no tip before the tutorial", not (p.PlayerGui.RamenUI:FindFirstChild("Hint") and p.PlayerGui.RamenUI.Hint.Visible))
Sim.check("the tutorial starts after the loading screen", waitStep("welcome", 30) and banner ~= nil and banner.Visible and p.PlayerGui:FindFirstChild("Loading") == nil, tostring(step()))
local Locale = Sim.clientRequire(game:GetService("ReplicatedStorage").Shared.Locale)
local function bannerSays(key)
	local want = Locale.t(key)
	for _, d in ipairs(banner:GetDescendants()) do
		if d:IsA("TextLabel") and string.find(d.Text, want, 1, true) then
			return true
		end
	end
	return false
end
Sim.check("the welcome card speaks of the phone (the stick on the left)", bannerSays("tut.welcome_touch"))
local shownAt = Sim.now

-- 1-2: welcome, then the first order; every card stays a few seconds, even when already done
Sim.check("welcome moves on by itself", waitStep("order", 12))
Sim.check("the welcome card stayed to be read", Sim.now - shownAt >= TutorialCfg.WelcomeSeconds - 0.5, string.format("%.1f s", Sim.now - shownAt))
local orderAt = Sim.now
Sim.check("the order step ends when the customer orders", waitStep("cook", 60), tostring(step()))
Sim.check("the order card stayed on screen", Sim.now - orderAt >= TutorialCfg.MinStepSeconds - 0.3, string.format("%.1f s", Sim.now - orderAt))
Sim.check("the cook card speaks of the phone (tap the button)", bannerSays("tut.cook_touch"))
local ticket = S.Cooking.ticketsOf(plot)[1]
local station
for _, e in ipairs(S.Entities.ofKind("station", plot)) do
	if e.item.fn.station == "ramen" then
		station = e
	end
end
-- 3-4: three presses, then pick it up
local presses = 0
while step() == "cook" and presses < 6 do
	use(station.model)
	presses += 1
	Sim.waitFor(function()
		return not station.model:GetAttribute("Busy")
	end, 10)
	task.wait(0.3)
end
Sim.check("three presses cook the ramen", step() == "take" and presses == 3, presses .. " presses, step " .. tostring(step()))
use(station.model)
Sim.check("the bowl is picked up", waitStep("serve", 5), tostring(step()))
-- 5: serve, then the gift and the shop
local yen = d.yen
local cust = S.Entities.get(ticket.customer)
use(cust.model)
Sim.check("serving moves on to the gift", waitStep("reward", 5), tostring(step()))
Sim.waitFor(function()
	return d.meta.tutorialGifts.serve
end, 3)
Sim.check("the gift of yen arrives", d.meta.tutorialGifts.serve == true and d.yen >= yen + TutorialCfg.ServeYen, yen .. " -> " .. d.yen)
task.wait(0.5)
local hand = p.PlayerGui.RamenUI:FindFirstChild("PointerHand")
Sim.check("a hand points at the shop button", hand ~= nil and hand.Visible)
Sim.click(p.PlayerGui.RamenUI.HUD.Dock.Shop)
Sim.check("opening the shop moves on", waitStep("buy", 5), tostring(step()))
task.wait(0.6)
local green
for _, b in ipairs(p.PlayerGui.RamenUI:GetDescendants()) do
	local c = b:IsA("TextButton") and b.TextColor3
	if b.Name == "Buy" and Sim.Gui.shown(b) and b.Text:find("¥", 1, true) and c and c.R > 0.99 and c.G > 0.99 and c.B > 0.99 then
		green = green or b
	end
end
Sim.check("there is a green price to tap", green ~= nil)
Sim.click(green)
Sim.check("buying moves on", waitStep("collect", 5), tostring(step()))
C.UI.close("Shop")
-- 6-7: the dirty bowl, the sink
local dirty = Sim.waitFor(function()
	return S.Entities.ofKind("dirty", plot)[1]
end, 40)
Sim.check("the customer leaves a dirty bowl", dirty ~= nil)
use(dirty.model)
Sim.check("collecting moves on", waitStep("wash", 5), tostring(step()))
local sink = S.Entities.ofKind("sink", plot)[1]
use(sink.model)
Sim.waitFor(function()
	return (plot.folder:GetAttribute("SinkPile") or 0) >= 1
end, 3)
use(sink.model) -- a tap on the phone starts the tap running
Sim.check("washing moves on", waitStep("done", 15), tostring(step()) .. ", washed " .. tostring(d.stats.washed))
Sim.waitFor(function()
	return d.meta.tutorialGifts.done
end, 3)
Sim.check("the last gift arrives", d.meta.tutorialGifts.done == true and (d.sakura or 0) >= TutorialCfg.DoneSakura, "sakura " .. tostring(d.sakura))
local logged = false
for _, a in ipairs(Sim.analytics) do
	if a.kind == "onboarding" and a.args[1] == p and a.args[3] == "tutorial_done" then
		logged = true
	end
end
Sim.check("analytics: onboarding step tutorial_done", logged)
Sim.waitFor(function()
	return step() == nil
end, 10)
local took = Sim.now - t0
Sim.check("the tutorial ends", step() == nil and d.meta.tutorial == -1, tostring(d.meta.tutorial))
Sim.check("the whole tutorial takes about two minutes", took <= 130, string.format("%.0f s", took))
Sim.say(string.format("tutorial done in %.0f s (%d presses)", took, presses))

-- the gifts cannot be asked for again
local before = d.yen
Sim.fire(p, "TutorialReward", "serve")
task.wait(0.3)
Sim.check("no second gift", d.yen == before)

-- a one-time tip after the tutorial: something new in the shop
d.yen += 20000
d.level = math.max(d.level, 4)
S.Data.changed(p, "yen")
S.Data.changed(p, "level")
local card = p.PlayerGui.RamenUI:FindFirstChild("Hint")
Sim.check("a tip shows up", Sim.waitFor(function()
	return card and card.Visible
end, 40) ~= nil)
Sim.click(p.PlayerGui.RamenUI.HUD.Dock.Shop)
task.wait(1)
Sim.check("the tip is gone and remembered", not card.Visible and next(d.meta.hints) ~= nil)
Sim.check("server closes cleanly", Sim.close())
