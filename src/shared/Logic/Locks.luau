--!nonstrict
-- What a station or the rice cooker still needs before it can be used (for the 🔒 hints): the
-- cheapest-level license that unlocks one of its recipes, or nil when an owned license already does.
local Locks = {}

local function firstLicense(recipes, licenses, owned, match)
	local best = nil
	for _, r in ipairs(recipes.list) do
		if match(r) and not r.city then
			if owned[r.license] then
				return nil
			end
			local lic = licenses.byId[r.license]
			if lic and (not best or lic.level < best.level) then
				best = lic
			end
		end
	end
	return best
end

-- stationType = Items fn.station ("sushi", "ramen"...); owned = { [licenseId] = true }
function Locks.station(stationType, owned, recipes, licenses)
	return firstLicense(recipes, licenses, owned or {}, function(r)
		return r.station == stationType
	end)
end

function Locks.rice(owned, recipes, licenses)
	return firstLicense(recipes, licenses, owned or {}, function(r)
		return r.rice == true
	end)
end

return Locks
