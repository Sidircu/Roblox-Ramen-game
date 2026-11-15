--!nonstrict
local Format = {}

local function group(n, sep)
	local s = tostring(math.floor(math.abs(n) + 0.5))
	local out = s:reverse():gsub("(%d%d%d)", "%1" .. sep):reverse()
	if out:sub(1, 1) == sep then
		out = out:sub(2)
	end
	return out
end

-- Formats an integer with thousands separators for the given language.
function Format.number(n, lang)
	n = tonumber(n) or 0
	local sign = n < 0 and "-" or ""
	local sep = lang == "it" and "." or ","
	local abs = math.abs(n)
	if abs >= 1e9 then
		local v = string.format("%.2f", abs / 1e9)
		if lang == "it" then
			v = v:gsub("%.", ",")
		end
		return sign .. v .. (lang == "it" and " Mld" or "B")
	elseif abs >= 1e7 then
		local v = string.format("%.1f", abs / 1e6)
		if lang == "it" then
			v = v:gsub("%.", ",")
		end
		return sign .. v .. (lang == "it" and " Mln" or "M")
	end
	return sign .. group(abs, sep)
end

function Format.yen(n, lang)
	return "¥" .. Format.number(n, lang)
end

function Format.sakura(n, lang)
	return "🌸" .. Format.number(n, lang)
end

function Format.decimal(n, digits, lang)
	local s = string.format("%." .. (digits or 1) .. "f", n)
	if lang == "it" then
		s = s:gsub("%.", ",")
	end
	return s
end

function Format.clock(hours)
	local h = math.floor(hours) % 24
	local m = math.floor((hours - math.floor(hours)) * 60)
	return string.format("%02d:%02d", h, m)
end

function Format.duration(seconds)
	seconds = math.max(0, math.floor(seconds))
	local h = math.floor(seconds / 3600)
	local m = math.floor((seconds % 3600) / 60)
	local s = seconds % 60
	if h > 0 then
		return string.format("%dh %02dm", h, m)
	elseif m > 0 then
		return string.format("%dm %02ds", m, s)
	end
	return string.format("%ds", s)
end

return Format
