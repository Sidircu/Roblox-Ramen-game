--!nonstrict
-- Franchise (prestige): open a restaurant in the next city with permanent bonuses.
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Franchise = require(Shared.Config.Franchise)
local Core = require(script.Parent.Parent.Core)

local Service = {}

function Service.check(d)
	if d.level < Franchise.RequiredLevel then
		return false, "msg.need_level", { level = Franchise.RequiredLevel }
	end
	if Core.S.Progression.rating() < Franchise.RequiredRating then
		return false, "msg.need_rating", { rating = Franchise.RequiredRating }
	end
	for _, z in ipairs(Franchise.RequiredZones) do
		if not d.zones[z] then
			return false, "msg.need_zone", { name = "zone." .. z }
		end
	end
	local nextCity = nil
	for _, c in ipairs(Franchise.list) do
		if c.star == (d.franchise.stars or 0) + 1 then
			nextCity = c
		end
	end
	if not nextCity then
		return false, "msg.franchise_done"
	end
	return true, nil, nil, nextCity
end

local KEEP = { sakura = true, mastery = true, stats = true, meta = true, settings = true, passes = true, receipts = true, created = true, inventory = true, perms = true }

local function open(player)
	local Session, Net = Core.S.Session, Core.S.Net
	if player ~= Session.owner then
		return
	end
	local d = Session.ownerData()
	local ok, reason, params, city = Service.check(d)
	if not ok then
		return Net.notify(player, reason, params, "error")
	end
	-- every placed object goes to the inventory
	for _, e in ipairs(d.placed) do
		d.inventory[e.i] = (d.inventory[e.i] or 0) + 1
	end
	local fresh = Core.S.Data.newProfile()
	for k, v in pairs(fresh) do
		if not KEEP[k] then
			d[k] = v
		end
	end
	d.yen = Franchise.StartYen
	d.franchise = { stars = city.star, city = city.id, cities = {} }
	for _, c in ipairs(Franchise.list) do
		if c.star <= city.star then
			d.franchise.cities[c.id] = true
		end
	end
	-- the starter layout is already placed: remove those copies from the inventory
	for _, e in ipairs(d.placed) do
		if d.inventory[e.i] and d.inventory[e.i] > 0 then
			d.inventory[e.i] -= 1
			if d.inventory[e.i] == 0 then
				d.inventory[e.i] = nil
			end
		end
	end
	Net.fx("construction", { zone = "franchise" })
	Net.notifyAll("msg.franchise_opened", { city = "city." .. city.id }, "level")
	Core.S.Customers.sendAllHome()
	Core.S.Cooking.clearTickets()
	Session.OwnerReady:Fire(player, d)
	for _, k in ipairs(Core.S.Data.WorldKeys) do
		Core.S.Data.changed(player, k)
	end
	Core.S.Data.changed(player, "meta")
	Core.S.Meta.event(player, "franchise", 1)
end

function Service.Init()
	Core.S.Net.on("Franchise", function(player)
		open(player)
	end, 1)
end

return Service
