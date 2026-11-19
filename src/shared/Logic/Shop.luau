--!nonstrict
-- What the shop shows for each thing on sale, from the restaurant data `w`:
--   state "buy"    affordable now
--         "poor"   unlocked, but not enough yen (missing = how much is missing)
--         "locked" something comes first (need = { kind = "level" | "license" | "zone" | "staff" |
--                  "rating" | "slots" | "manager", ... })
--         "owned"  bought (licenses, rooms, renovations) / "max" (upgrades at their last level) /
--         "active" (today's advert)
-- The server checks the same rules when a purchase arrives (Services/Progression and
-- Services/Staff). Pure: the caller passes the data and the configuration tables, so this module
-- runs in the logic tests too.
local Shop = {}

local function finish(w, state, price, need, extra)
	local r = { state = state, price = price, need = need }
	if state == "buy" and (w.yen or 0) < (price or 0) then
		r.state = "poor"
	end
	if r.state == "poor" then
		r.missing = (price or 0) - (w.yen or 0)
	end
	for k, v in pairs(extra or {}) do
		r[k] = v
	end
	return r
end

local function level(w)
	return w.level or 1
end

-- staff slots of a restaurant (base slots + slots that come with rooms, + the game pass)
function Shop.staffSlots(w, staffCfg, maxStaff)
	local n = staffCfg.BaseSlots
	for zone, extra in pairs(staffCfg.SlotsByZone) do
		if w.zones and w.zones[zone] then
			n = n + extra
		end
	end
	n = math.min(n, maxStaff or n)
	if w.passes and w.passes.gp_extra_staff then
		n = n + (staffCfg.PassSlots or 0)
	end
	return n
end

function Shop.upgrade(w, u)
	local lvl = (w.upgrades and w.upgrades[u.id]) or 0
	local extra = { level = lvl, max = u.max }
	if lvl >= u.max then
		return finish(w, "max", nil, nil, extra)
	end
	local price = u.costs[lvl + 1]
	local need = u.levels[lvl + 1]
	if level(w) < need then
		return finish(w, "locked", price, { kind = "level", level = need }, extra)
	end
	if u.needsStaff then
		local has = false
		for _, s in ipairs(w.staff or {}) do
			if s.role == u.needsStaff then
				has = true
			end
		end
		if not has then
			return finish(w, "locked", price, { kind = "staff", id = u.needsStaff }, extra)
		end
	end
	return finish(w, "buy", price, nil, extra)
end

function Shop.ad(w, ad)
	local day = ((w.stats and w.stats.days) or 0) + 1
	if w.ads and w.ads[ad.id] == day then
		return finish(w, "active", nil, nil)
	end
	if level(w) < ad.lv then
		return finish(w, "locked", ad.cost, { kind = "level", level = ad.lv })
	end
	return finish(w, "buy", ad.cost, nil)
end

-- rating: the restaurant's current star rating (the server keeps it, the client reads it from
-- the plot's "Rating" attribute)
function Shop.license(w, lic, rating)
	if w.licenses and w.licenses[lic.id] then
		return finish(w, "owned", nil, nil)
	end
	if level(w) < lic.level then
		return finish(w, "locked", lic.cost, { kind = "level", level = lic.level })
	end
	for _, req in ipairs(lic.requires or {}) do
		if not (w.licenses and w.licenses[req]) then
			return finish(w, "locked", lic.cost, { kind = "license", id = req })
		end
	end
	if (lic.rating or 0) > 0 and (rating or 0) < lic.rating then
		return finish(w, "locked", lic.cost, { kind = "rating", rating = lic.rating })
	end
	return finish(w, "buy", lic.cost, nil)
end

-- rooms, floors and renovations
function Shop.expansion(w, e)
	if w.zones and w.zones[e.id] then
		return finish(w, "owned", nil, nil)
	end
	if level(w) < e.lv then
		return finish(w, "locked", e.cost, { kind = "level", level = e.lv })
	end
	for _, req in ipairs(e.requires or {}) do
		if not (w.zones and w.zones[req]) then
			return finish(w, "locked", e.cost, { kind = "zone", id = req })
		end
	end
	return finish(w, "buy", e.cost, nil)
end

function Shop.hire(w, cfg, slots)
	if level(w) < cfg.lv then
		return finish(w, "locked", cfg.hire, { kind = "level", level = cfg.lv })
	end
	if cfg.manager then
		for _, s in ipairs(w.staff or {}) do
			if s.role == cfg.id then
				return finish(w, "locked", cfg.hire, { kind = "manager" })
			end
		end
	end
	if #(w.staff or {}) >= slots then
		return finish(w, "locked", cfg.hire, { kind = "slots" })
	end
	return finish(w, "buy", cfg.hire, nil)
end

-- cfg = { Upgrades, Ads, Licenses, Expansions, Staff, MaxStaff }; returns the number of things
-- the restaurant can buy right now, per shop tab and in total
function Shop.buyable(w, cfg, rating)
	local tabs = { upgrades = 0, recipes = 0, staff = 0, rooms = 0, reno = 0 }
	for _, u in ipairs(cfg.Upgrades.list) do
		if Shop.upgrade(w, u).state == "buy" then
			tabs.upgrades = tabs.upgrades + 1
		end
	end
	-- today's advert counts too (it comes back every day)
	for _, ad in ipairs(cfg.Ads and cfg.Ads.list or {}) do
		if Shop.ad(w, ad).state == "buy" then
			tabs.upgrades = tabs.upgrades + 1
		end
	end
	for _, lic in ipairs(cfg.Licenses.list) do
		if Shop.license(w, lic, rating).state == "buy" then
			tabs.recipes = tabs.recipes + 1
		end
	end
	local slots = Shop.staffSlots(w, cfg.Staff, cfg.MaxStaff)
	for _, s in ipairs(cfg.Staff.list) do
		if Shop.hire(w, s, slots).state == "buy" then
			tabs.staff = tabs.staff + 1
		end
	end
	for _, e in ipairs(cfg.Expansions.list) do
		if e.id ~= "zone_base" and Shop.expansion(w, e).state == "buy" then
			if e.reno then
				tabs.reno = tabs.reno + 1
			else
				tabs.rooms = tabs.rooms + 1
			end
		end
	end
	local total = tabs.upgrades + tabs.recipes + tabs.staff + tabs.rooms + tabs.reno
	return total, tabs
end

-- the order cards are shown in: things to buy first (cheapest first), then the ones that need
-- more yen, then locked ones, then what is already owned
local RANK = { buy = 1, poor = 2, active = 3, locked = 4, owned = 5, max = 5 }
function Shop.sort(entries)
	table.sort(entries, function(a, b)
		local ra, rb = RANK[a.st.state] or 9, RANK[b.st.state] or 9
		if ra ~= rb then
			return ra < rb
		end
		local pa, pb = a.st.price or 0, b.st.price or 0
		if pa ~= pb and ra <= 4 then
			return pa < pb
		end
		return (a.order or 0) < (b.order or 0)
	end)
	return entries
end

return Shop
