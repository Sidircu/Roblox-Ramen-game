--!nonstrict
-- Short unique ids for placed items, boxes, entities.
local Uid = {}

local counter = 0
local rng = Random.new()
local ALPHABET = "abcdefghijklmnopqrstuvwxyz0123456789"

function Uid.new(prefix)
	counter += 1
	local chars = {}
	for i = 1, 5 do
		local idx = rng:NextInteger(1, #ALPHABET)
		chars[i] = string.sub(ALPHABET, idx, idx)
	end
	return (prefix or "") .. string.format("%x", counter) .. table.concat(chars)
end

return Uid
