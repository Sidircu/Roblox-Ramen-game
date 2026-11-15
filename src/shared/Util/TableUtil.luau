--!nonstrict
local TableUtil = {}

function TableUtil.deepCopy(value)
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for k, v in pairs(value) do
		copy[TableUtil.deepCopy(k)] = TableUtil.deepCopy(v)
	end
	return copy
end

-- Fills missing keys of `target` from `defaults` (recursively for tables).
function TableUtil.reconcile(target, defaults)
	for k, v in pairs(defaults) do
		if target[k] == nil then
			target[k] = TableUtil.deepCopy(v)
		elseif type(v) == "table" and type(target[k]) == "table" and next(v) ~= nil and #v == 0 then
			TableUtil.reconcile(target[k], v)
		end
	end
	return target
end

function TableUtil.count(t)
	local n = 0
	for _ in pairs(t) do
		n += 1
	end
	return n
end

function TableUtil.keys(t)
	local out = {}
	for k in pairs(t) do
		table.insert(out, k)
	end
	return out
end

function TableUtil.map(list, fn)
	local out = {}
	for i, v in ipairs(list) do
		out[i] = fn(v, i)
	end
	return out
end

function TableUtil.filter(list, fn)
	local out = {}
	for _, v in ipairs(list) do
		if fn(v) then
			table.insert(out, v)
		end
	end
	return out
end

function TableUtil.indexBy(list, key)
	local out = {}
	for _, v in ipairs(list) do
		out[v[key]] = v
	end
	return out
end

function TableUtil.shuffle(list, rng)
	rng = rng or Random.new()
	for i = #list, 2, -1 do
		local j = rng:NextInteger(1, i)
		list[i], list[j] = list[j], list[i]
	end
	return list
end

function TableUtil.weightedPick(list, weightFn, rng)
	rng = rng or Random.new()
	local total = 0
	for _, v in ipairs(list) do
		total += math.max(0, weightFn(v))
	end
	if total <= 0 then
		return nil
	end
	local roll = rng:NextNumber() * total
	for _, v in ipairs(list) do
		roll -= math.max(0, weightFn(v))
		if roll <= 0 then
			return v
		end
	end
	return list[#list]
end

return TableUtil
