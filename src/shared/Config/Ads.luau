--!nonstrict
-- One-day advertising campaigns.
local list = {
	{ id = "ad_flyers", icon = "📰", cost = 500, lv = 1, popularity = 0.20 },
	{ id = "ad_radio", icon = "📻", cost = 5000, lv = 10, popularity = 0.35 },
	{ id = "ad_tv", icon = "📺", cost = 50000, lv = 25, popularity = 0.60, tourists = true },
}
local byId = {}
for i, a in ipairs(list) do
	a.order = i
	byId[a.id] = a
end
return { list = list, byId = byId }
