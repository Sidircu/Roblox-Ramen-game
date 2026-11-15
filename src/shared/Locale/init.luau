--!nonstrict
-- Localization: Locale.t("key", { param = value }). Languages: en (base), it.
local Signal = require(script.Parent.Util.Signal)
local Format = require(script.Parent.Util.Format)

local Locale = {}

local tables = {
	en = require(script.en),
	it = require(script.it),
}

local current = "en"
Locale.Changed = Signal.new()
Locale.Languages = { "en", "it" }

function Locale.resolve(localeId)
	if type(localeId) == "string" and string.sub(string.lower(localeId), 1, 2) == "it" then
		return "it"
	end
	return "en"
end

function Locale.set(lang)
	if not tables[lang] then
		lang = "en"
	end
	if lang ~= current then
		current = lang
		Locale.Changed:Fire(lang)
	end
end

function Locale.get()
	return current
end

function Locale.has(key)
	return tables.en[key] ~= nil
end

function Locale.t(key, params)
	local s = tables[current][key] or tables.en[key]
	if not s then
		return key
	end
	if params then
		s = string.gsub(s, "{([%w_]+)}", function(name)
			local v = params[name]
			if v == nil then
				return "{" .. name .. "}"
			end
			if type(v) == "number" then
				if math.floor(v) == v then
					return Format.number(v, current)
				end
				return Format.decimal(v, 1, current)
			end
			if type(v) == "string" and Locale.has(v) then
				return Locale.t(v)
			end
			return tostring(v)
		end)
	end
	return s
end

-- Display name helpers for config ids
function Locale.name(prefix, id)
	return Locale.t(prefix .. "." .. id)
end

return Locale
