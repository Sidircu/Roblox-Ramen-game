--!nonstrict
-- Seasonal events (UTC dates). While active: themed items in the catalog and a popularity bonus.
local list = {
	{ id = "hanami", from = { 3, 20 }, to = { 4, 30 }, popularity = 0.15, color = "#F7B7C9" },
	{ id = "tanabata", from = { 7, 1 }, to = { 8, 20 }, popularity = 0.15, color = "#7FB7E8" },
	{ id = "tsukimi", from = { 9, 10 }, to = { 10, 31 }, popularity = 0.15, color = "#F2D27A" },
	{ id = "shogatsu", from = { 12, 20 }, to = { 1, 15 }, popularity = 0.20, color = "#D9363E" },
}
local byId = {}
for i, e in ipairs(list) do
	e.order = i
	byId[e.id] = e
end

local function inRange(month, day, from, to)
	local v = month * 100 + day
	local a = from[1] * 100 + from[2]
	local b = to[1] * 100 + to[2]
	if a <= b then
		return v >= a and v <= b
	end
	return v >= a or v <= b -- wraps over new year
end

-- Returns the active event (or nil) for a unix time.
local function active(now)
	local d = os.date("!*t", now)
	for _, e in ipairs(list) do
		if inRange(d.month, d.day, e.from, e.to) then
			return e
		end
	end
	return nil
end

return { list = list, byId = byId, active = active }
