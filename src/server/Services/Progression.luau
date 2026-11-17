--!nonstrict
-- Restaurant level, licenses, upgrades, ads, expansions, menu, mastery, rating and popularity.
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local Licenses = require(Shared.Config.Licenses)
local Recipes = require(Shared.Config.Recipes)
local Upgrades = require(Shared.Config.Upgrades)
local Ads = require(Shared.Config.Ads)
local Expansions = require(Shared.Config.Expansions)
local Franchise = require(Shared.Config.Franchise)
local Events = require(Shared.Config.Events)
local Staff = require(Shared.Config.Staff)
local Formulas = require(Shared.Logic.Formulas)
local Core = require(script.Parent.Parent.Core)

local Progression = {}

local function owner()
	return Core.S.Session.owner
end

local function data()
	return Core.S.Session.ownerData()
end

function Progression.rating()
	local d = data()
	if not d then
		return GameConfig.Customers.DefaultRating
	end
	return Formulas.rating(d.reviews.recent, GameConfig.Customers.DefaultRating)
end

function Progression.addReview(stars, weight)
	local d = data()
	if not d then
		return
	end
	table.insert(d.reviews.recent, { s = stars, w = weight or 1 })
	while #d.reviews.recent > GameConfig.Customers.RecentReviews do
		table.remove(d.reviews.recent, 1)
	end
	d.reviews.total += 1
	d.reviews.sum += stars
	if stars >= 5 then
		d.stats.five_stars = (d.stats.five_stars or 0) + 1
		Core.S.Meta.event(owner(), "five_stars", 1)
	end
	workspace:SetAttribute("Rating", Progression.rating())
	Core.S.Data.changed(owner(), "reviews")
end

function Progression.addXp(player, amount)
	local d = Core.S.Data.get(player)
	if not d or amount <= 0 then
		return
	end
	local mult = 1 + (d.franchise.stars or 0) * Franchise.XpPerStar
	local newLevel, newXp, gained = Formulas.addXp(d.level, d.xp, math.floor(amount * mult + 0.5))
	local oldLevel = d.level
	d.level, d.xp = newLevel, newXp
	Core.S.Data.changed(player, "xp")
	if gained > 0 then
		for lvl = oldLevel + 1, newLevel do
			local yen, sakura = Formulas.levelReward(lvl)
			Core.S.Economy.add(player, yen, "level")
			if sakura > 0 then
				Core.S.Economy.addSakura(player, sakura)
			end
		end
		Core.S.Data.changed(player, "level")
		Core.S.Net.notifyAll("msg.level_up", { level = newLevel }, "level")
		Core.S.Net.fx("levelup", { level = newLevel, userId = player.UserId })
		Core.S.Meta.event(player, "level", newLevel)
	end
end

function Progression.isRecipeUnlocked(d, recipe)
	if recipe.city then
		return d.franchise.city == recipe.city and d.level >= Franchise.RegionalLevel
	end
	return recipe.license ~= nil and d.licenses[recipe.license] == true
end

-- Recipes the restaurant can currently sell (unlocked + enabled in the menu)
function Progression.menuRecipes(d)
	local out = {}
	for _, r in ipairs(Recipes.list) do
		if Progression.isRecipeUnlocked(d, r) then
			local m = d.menu[r.id]
			if not m then
				m = { on = true, price = 1 }
				d.menu[r.id] = m
			end
			if m.on then
				table.insert(out, r)
			end
		end
	end
	return out
end

function Progression.priceOf(d, recipe)
	local m = d.menu[recipe.id]
	return Formulas.dishPrice(recipe.price, d.mastery[recipe.id] or 0, m and m.price or 1)
end

function Progression.addMastery(recipeId)
	local d = data()
	if not d then
		return
	end
	local before = Formulas.masteryLevel(d.mastery[recipeId] or 0)
	d.mastery[recipeId] = (d.mastery[recipeId] or 0) + 1
	local after = Formulas.masteryLevel(d.mastery[recipeId])
	if after > before then
		Core.S.Net.notifyAll("msg.mastery_up", { dish = "rec." .. recipeId, level = after }, "level")
		if after == #Formulas.MasteryThresholds then
			d.stats.gold_mastery = (d.stats.gold_mastery or 0) + 1
		end
		Core.S.Data.changed(owner(), "mastery")
	end
end

function Progression.popularity()
	local d = data()
	if not d then
		return 0
	end
	local ads = 0
	for id, day in pairs(d.ads or {}) do
		local ad = Ads.byId[id]
		if ad and day == (d.stats.days or 0) + 1 then
			ads += ad.popularity
		end
	end
	local extra = 0
	for _, e in ipairs(Expansions.list) do
		if d.zones[e.id] and e.popularity then
			extra += e.popularity
		end
	end
	if d.boosts.influencer and d.boosts.influencer == (d.stats.days or 0) + 1 then
		extra += 0.25
	end
	local ev = Events.active(os.time())
	local amb = Core.S.Placement.ambience
	return Formulas.popularity({
		level = d.level,
		rating = Progression.rating(),
		ambience = amb.popularity,
		sign = Upgrades.value(d.upgrades, "up_sign"),
		ads = ads,
		event = ev and ev.popularity or 0,
		extra = extra,
	})
end

function Progression.staffSlots(d)
	local slots = Staff.BaseSlots
	for zone, n in pairs(Staff.SlotsByZone) do
		if d.zones[zone] then
			slots += n
		end
	end
	return math.min(slots, GameConfig.MaxStaff)
end

local function payer(player)
	local Session = Core.S.Session
	if not Session.canBuild(player) then
		Core.S.Net.notify(player, "msg.no_permission", nil, "error")
		return nil
	end
	return Session.owner, Session.ownerData()
end

local function buyLicense(player, id)
	local o, d = payer(player)
	local lic = Licenses.byId[id]
	if not o or not d or not lic or d.licenses[id] then
		return
	end
	local Net = Core.S.Net
	if d.level < lic.level then
		return Net.notify(player, "msg.need_level", { level = lic.level }, "error")
	end
	for _, req in ipairs(lic.requires) do
		if not d.licenses[req] then
			return Net.notify(player, "msg.need_license", nil, "error")
		end
	end
	if lic.rating > 0 and Progression.rating() < lic.rating then
		return Net.notify(player, "msg.need_rating", { rating = lic.rating }, "error")
	end
	if not Core.S.Economy.spend(o, lic.cost, "build") then
		return Net.notify(player, "msg.not_enough", nil, "error")
	end
	d.licenses[id] = true
	for _, rid in ipairs(lic.recipes) do
		d.menu[rid] = d.menu[rid] or { on = true, price = 1 }
	end
	Core.S.Data.changed(o, "licenses")
	Core.S.Data.changed(o, "menu")
	Net.notifyAll("msg.license_bought", { name = "lic." .. id }, "success")
	Net.fx("sparkle", { userId = player.UserId })
	Core.S.Meta.event(o, "licenses", 1)
end

local function buyUpgrade(player, id)
	local o, d = payer(player)
	local up = Upgrades.byId[id]
	if not o or not d or not up then
		return
	end
	local Net = Core.S.Net
	local lvl = d.upgrades[id] or 0
	if lvl >= up.max then
		return Net.notify(player, "msg.max_level", nil, "error")
	end
	local nextLvl = lvl + 1
	if d.level < up.levels[nextLvl] then
		return Net.notify(player, "msg.need_level", { level = up.levels[nextLvl] }, "error")
	end
	if up.needsStaff then
		local has = false
		for _, s in ipairs(d.staff) do
			if s.role == up.needsStaff then
				has = true
			end
		end
		if not has then
			return Net.notify(player, "msg.need_staff", { role = "staff." .. up.needsStaff }, "error")
		end
	end
	if not Core.S.Economy.spend(o, up.costs[nextLvl], "build") then
		return Net.notify(player, "msg.not_enough", nil, "error")
	end
	d.upgrades[id] = nextLvl
	Core.S.Data.changed(o, "upgrades")
	Net.notifyAll("msg.upgrade_bought", { name = "upg." .. id, level = nextLvl }, "success")
	if id == "up_jukebox" then
		Core.S.Placement.recomputeAmbience()
	elseif id == "up_shoes" then
		Progression.applyWalkSpeed()
	end
end

local function buyAd(player, id)
	local o, d = payer(player)
	local ad = Ads.byId[id]
	if not o or not d or not ad then
		return
	end
	local Net = Core.S.Net
	if d.level < ad.lv then
		return Net.notify(player, "msg.need_level", { level = ad.lv }, "error")
	end
	local day = (d.stats.days or 0) + 1
	if d.ads[id] == day then
		return Net.notify(player, "msg.ad_active", nil, "error")
	end
	if not Core.S.Economy.spend(o, ad.cost, "other") then
		return Net.notify(player, "msg.not_enough", nil, "error")
	end
	d.ads[id] = day
	Core.S.Data.changed(o, "ads")
	Net.notifyAll("msg.ad_bought", { name = "ad." .. id }, "success")
end

local function buyExpansion(player, id)
	local o, d = payer(player)
	local exp = Expansions.byId[id]
	if not o or not d or not exp or d.zones[id] then
		return
	end
	local Net = Core.S.Net
	if d.level < exp.lv then
		return Net.notify(player, "msg.need_level", { level = exp.lv }, "error")
	end
	for _, req in ipairs(exp.requires) do
		if not d.zones[req] then
			return Net.notify(player, "msg.need_zone", { name = "zone." .. req }, "error")
		end
	end
	if not Core.S.Economy.spend(o, exp.cost, "build") then
		return Net.notify(player, "msg.not_enough", nil, "error")
	end
	d.zones[id] = true
	for _, z in ipairs(exp.zones or {}) do
		if z.floorStyle or z.wallStyle then
			d.surfaces[z.id] = d.surfaces[z.id] or { floor = z.floorStyle, wall = z.wallStyle }
		end
	end
	Net.fx("construction", { zone = id })
	task.wait(1.5)
	local World, Placement = Core.S.World, Core.S.Placement
	World.rebuild(d)
	local moved = Placement.revalidate(d)
	Placement.spawnAll(d)
	Core.S.Data.changed(o, "zones")
	Core.S.Data.changed(o, "placed")
	Core.S.Data.changed(o, "inventory")
	Net.notifyAll(exp.reno and "msg.reno_bought" or "msg.expansion_bought", { name = "zone." .. id }, "success")
	if moved > 0 then
		Net.notify(o, "msg.items_to_inventory", { n = moved })
	end
	Core.S.Meta.event(o, exp.reno and "renos" or "zones", 1)
end

local function setMenu(player, recipeId, on, priceMult)
	local o, d = payer(player)
	local r = Recipes.byId[recipeId]
	if not o or not d or not r or not Progression.isRecipeUnlocked(d, r) then
		return
	end
	local m = d.menu[recipeId] or { on = true, price = 1 }
	if type(on) == "boolean" then
		m.on = on
	end
	if type(priceMult) == "number" then
		m.price = math.clamp(math.floor(priceMult * 10 + 0.5) / 10, 0.7, 1.3)
	end
	d.menu[recipeId] = m
	Core.S.Data.changed(o, "menu")
end

function Progression.applyWalkSpeed()
	local d = data()
	if not d then
		return
	end
	local speed = GameConfig.WalkSpeed * Upgrades.value(d.upgrades, "up_shoes")
	for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
		-- the client multiplies this while running (Controllers/FirstPerson)
		p:SetAttribute("WalkSpeed", speed)
		local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.WalkSpeed = speed
		end
	end
end

function Progression.Init()
	local Net = Core.S.Net
	Net.on("BuyLicense", buyLicense, 3)
	Net.on("BuyUpgrade", buyUpgrade, 3)
	Net.on("BuyAd", buyAd, 3)
	Net.on("BuyExpansion", buyExpansion, 2)
	Net.on("SetMenu", setMenu, 8)
end

function Progression.Start()
	Core.S.Session.OwnerReady:Connect(function()
		workspace:SetAttribute("Rating", Progression.rating())
		Progression.applyWalkSpeed()
	end)
	game:GetService("Players").PlayerAdded:Connect(function(p)
		p.CharacterAdded:Connect(function()
			task.wait(0.2)
			Progression.applyWalkSpeed()
		end)
	end)
end

return Progression
