--!nonstrict
-- Works out which seats are usable (stool in front of a counter, chair next to a table,
-- booths), where the dish goes, and keeps reservations / dirty dishes per seat.
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Items = require(Shared.Config.Items)
local GameConfig = require(Shared.Config.GameConfig)
local Footprint = require(Shared.Logic.Footprint)
local Core = require(script.Parent.Parent.Core)

local Seating = {}
Seating.seats = {} -- list of seat records
local byId = {}
local benches = {}

local SURFACES = { counter = true, table = true }
local PAIR_DISTANCE = 1.6 -- max gap between seat edge and surface edge

local function topY(entry)
	local item = Items.byId[entry.i]
	return Core.S.World.floorY(entry.f) + item.size[2]
end

-- closest point of an oriented footprint to (x, z)
local function closestPoint(fp, x, z)
	local ax, az = Footprint.axes(fp)
	local dx, dz = x - fp.x, z - fp.z
	local lx = math.clamp(dx * ax.x + dz * ax.z, -fp.w / 2 + 0.6, fp.w / 2 - 0.6)
	local lz = math.clamp(dx * az.x + dz * az.z, -fp.d / 2 + 0.6, fp.d / 2 - 0.6)
	return fp.x + ax.x * lx + az.x * lz, fp.z + ax.z * lx + az.z * lz
end

local function gap(fpA, fpB)
	if Footprint.overlaps(fpA, fpB, 0) then
		return 0
	end
	local best = math.huge
	for _, c in ipairs(Footprint.corners(fpA)) do
		local px, pz = closestPoint(Footprint.inflate(fpB, 0.6), c.x, c.z)
		best = math.min(best, math.sqrt((px - c.x) ^ 2 + (pz - c.z) ^ 2))
	end
	local cx, cz = closestPoint(Footprint.inflate(fpB, 0.6), fpA.x, fpA.z)
	best = math.min(best, math.sqrt((cx - fpA.x) ^ 2 + (cz - fpA.z) ^ 2) - math.max(fpA.w, fpA.d) / 2)
	return math.max(0, best)
end

function Seating.refresh()
	local d = Core.S.Session.ownerData()
	if not d then
		return
	end
	local old = byId
	local seats, newById = {}, {}
	benches = {}
	local surfaces = {}
	for _, e in ipairs(d.placed) do
		local item = Items.byId[e.i]
		if item and item.fn and SURFACES[item.fn.type] and e.s == "f" then
			table.insert(surfaces, { entry = e, item = item, fp = Footprint.new(e.x, e.z, item.size[1], item.size[3], e.r) })
		end
	end
	local function add(rec)
		-- keep the same record object so customers holding a reference stay in sync
		local prev = old[rec.id]
		if prev then
			for k, v in pairs(rec) do
				prev[k] = v
			end
			rec = prev
		end
		table.insert(seats, rec)
		newById[rec.id] = rec
	end
	for _, e in ipairs(d.placed) do
		local item = Items.byId[e.i]
		local ent = Core.S.Entities.get(e.u)
		if item and item.fn and ent and ent.model and e.s == "f" then
			local zone = Core.S.World.zoneAt(e.x, e.z, e.f)
			local area = zone and zone.area or "dining"
			if item.fn.type == "seat" then
				local fp = Footprint.new(e.x, e.z, item.size[1], item.size[3], e.r)
				local best, bestGap = nil, PAIR_DISTANCE
				for _, s in ipairs(surfaces) do
					if (s.entry.f or 0) == (e.f or 0) then
						local g = gap(fp, s.fp)
						if g <= bestGap then
							best, bestGap = s, g
						end
					end
				end
				if best then
					local px, pz = closestPoint(best.fp, e.x, e.z)
					-- move the dish spot from the edge onto the top, towards the middle of the surface
					local cx, cz = best.entry.x, best.entry.z
					local dx, dz = cx - px, cz - pz
					local len = math.sqrt(dx * dx + dz * dz)
					local inset = math.min(GameConfig.DishInset or 0.8, len)
					if len > 0.001 then
						px, pz = px + dx / len * inset, pz + dz / len * inset
					end
					local dish = Vector3.new(px, topY(best.entry) + 0.05, pz)
					local sitY = Core.S.World.floorY(e.f) + item.fn.height
					local seatPos = Vector3.new(e.x, sitY, e.z)
					local look = Vector3.new(px, sitY, pz)
					local sitCf
					if item.fn.symmetric then
						sitCf = CFrame.lookAt(seatPos, look)
					else
						sitCf = CFrame.new(seatPos) * CFrame.Angles(0, math.rad(e.r), 0)
					end
					add({
						id = e.u, itemUid = e.u, surface = best.entry.u, group = best.item.fn.type == "table" and best.entry.u or nil,
						sit = sitCf, dish = dish, floor = e.f or 0, area = area, comfort = item.fn.comfort or 0,
						vip = area == "tatami", counter = best.item.fn.type == "counter",
					})
				end
			elseif item.fn.type == "booth" then
				local root = ent.model.PrimaryPart
				for k = 1, item.fn.seats do
					local seatAtt = root:FindFirstChild("Seat" .. k)
					local dishAtt = root:FindFirstChild("Dish" .. k)
					if seatAtt and dishAtt then
						add({
							id = e.u .. "#" .. k, itemUid = e.u, surface = e.u, group = e.u,
							sit = seatAtt.WorldCFrame, dish = dishAtt.WorldPosition, floor = e.f or 0, area = area,
							comfort = item.fn.comfort or 0, vip = item.fn.vip == true or area == "tatami", counter = false,
						})
					end
				end
			elseif item.fn.type == "bench" then
				local root = ent.model.PrimaryPart
				for k = 1, item.fn.queue do
					local att = root:FindFirstChild("Queue" .. k)
					if att then
						table.insert(benches, { id = e.u .. "#q" .. k, sit = att.WorldCFrame, taken = nil })
					end
				end
			end
		end
	end
	Seating.seats = seats
	byId = newById
	workspace:SetAttribute("Seats", #seats)
end

function Seating.get(id)
	return byId[id]
end

local function free(s)
	return not s.occupant and not s.reserved and not s.dirty
end

function Seating.freeCount()
	local n = 0
	for _, s in ipairs(Seating.seats) do
		if free(s) then
			n += 1
		end
	end
	return n
end

-- Finds seats for a group. needsTable: only table/booth groups. vip: tatami seats only.
function Seating.find(size, needsTable, vip)
	local candidates = {}
	for _, s in ipairs(Seating.seats) do
		if free(s) and ((vip and s.vip) or (not vip and not s.vip)) then
			table.insert(candidates, s)
		end
	end
	if size == 1 and not needsTable then
		-- singles prefer the counter
		table.sort(candidates, function(a, b)
			if a.counter ~= b.counter then
				return a.counter
			end
			return a.id < b.id
		end)
		return candidates[1] and { candidates[1] } or nil
	end
	local groups = {}
	for _, s in ipairs(candidates) do
		if s.group then
			groups[s.group] = groups[s.group] or {}
			table.insert(groups[s.group], s)
		end
	end
	for _, list in pairs(groups) do
		if #list >= size then
			local out = {}
			for i = 1, size do
				out[i] = list[i]
			end
			return out
		end
	end
	return nil
end

function Seating.reserve(list, who)
	for _, s in ipairs(list) do
		s.reserved = who
	end
end

function Seating.release(s)
	if s then
		s.reserved = nil
		s.occupant = nil
	end
end

function Seating.benchSpot(who)
	for _, b in ipairs(benches) do
		if not b.taken then
			b.taken = who
			return b
		end
	end
	return nil
end

function Seating.freeBench(b)
	if b then
		b.taken = nil
	end
end

function Seating.queueCapacity()
	return #benches
end

-- Veto: occupied seats and surfaces with diners cannot be moved
local function busy(uid)
	for _, s in ipairs(Seating.seats) do
		if (s.itemUid == uid or s.surface == uid) and (s.occupant or s.reserved or s.dirty) then
			return true
		end
	end
	return false
end

function Seating.Init()
	local Placement = Core.S.Placement
	Placement.LayoutChanged:Connect(function()
		task.defer(Seating.refresh)
	end)
	Placement.addVeto(function(e)
		if busy(e.uid) then
			return false, "msg.seat_busy"
		end
		return true
	end)
end

return Seating
