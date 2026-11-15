--!nonstrict
local Color = {}

local cache = {}

-- "#RRGGBB" -> Color3 (cached)
function Color.hex(hex)
	local c = cache[hex]
	if c then
		return c
	end
	local h = hex:gsub("#", "")
	local r = tonumber(h:sub(1, 2), 16) or 255
	local g = tonumber(h:sub(3, 4), 16) or 255
	local b = tonumber(h:sub(5, 6), 16) or 255
	c = Color3.fromRGB(r, g, b)
	cache[hex] = c
	return c
end

function Color.of(value)
	if typeof(value) == "Color3" then
		return value
	elseif type(value) == "string" then
		return Color.hex(value)
	end
	return Color3.new(1, 1, 1)
end

function Color.darken(c, amount)
	local h, s, v = c:ToHSV()
	return Color3.fromHSV(h, s, math.clamp(v * (1 - amount), 0, 1))
end

function Color.lighten(c, amount)
	return c:Lerp(Color3.new(1, 1, 1), amount)
end

return Color
