-- The second floor and the roof terrace. Buying them builds corner stairs: two flights of even,
-- low steps up to a landing on a chest of drawers, handrails and invisible guards on both sides,
-- and an opening in the floor above with railings on every side but the one you step off. A
-- table where the stairs go returns to the inventory; furniture can go upstairs; the player's
-- client builds it all without errors.
Sim.startServer()
task.wait(1)
local S = Sim.core().S
local GameConfig = Sim.shared("Config.GameConfig")
local Expansions = Sim.shared("Config.Expansions")
local CS = game:GetService("CollectionService")
local H = GameConfig.FloorHeight

local profile = S.Data.newProfile()
profile.level = 40
profile.yen = 5000000
profile.meta.tutorial = -1
profile.zones.zone_east = true
-- a table right where the stairs will go
table.insert(profile.placed, { u = "p_t1", i = "table_2", x = -30, z = 8, r = 0, f = 0, t = 0 })
Sim.store("ds", "Profiles_v1").__data["u_4001"] = { data = profile }

local p = Sim.addPlayer({ userId = 4001, name = "Ren" })
Sim.startClient(p, "desktop")
local d = Sim.waitFor(function()
	return S.Data.get(p) and S.Plots.ofPlayer(p) and S.Data.get(p)
end, 30)
Sim.check("profile loaded", d ~= nil)
local plot = S.Plots.ofPlayer(p)
local O = plot.origin
local C = Sim.waitFor(function()
	local core = Sim.clientRequire(p.PlayerScripts.Client.Core)
	return core.C.Data and core.C.Data.ready and core.C
end, 30)
Sim.check("the client is ready", C ~= nil)
Sim.check("the table is in the restaurant", #d.placed > 0 and (d.inventory.table_2 or 0) == 0)

-- parts of this restaurant's shell with a tag (positions relative to the plot)
local function tagged(name, filter)
	local out = {}
	for _, part in ipairs(CS:GetTagged(name)) do
		if part:IsDescendantOf(workspace) and part:IsA("BasePart") then
			local pos = part.Position - O
			if math.abs(pos.X) < 120 and pos.Z > -30 and pos.Z < 110 and (not filter or filter(part, pos)) then
				table.insert(out, { part = part, pos = pos })
			end
		end
	end
	return out
end
local function steps(y0)
	local tops = {}
	for _, s in ipairs(tagged("Floor", function(part, pos)
		local top = pos.Y + part.Size.Y / 2
		return part.Name == "Step" and top > y0 + 0.01 and top <= y0 + H + 0.05
	end)) do
		table.insert(tops, s.pos.Y + s.part.Size.Y / 2)
	end
	table.sort(tops)
	return tops
end
local function evenSteps(tops, y0)
	if #tops < 8 then
		return false, #tops .. " steps"
	end
	local prev = y0
	for _, t in ipairs(tops) do
		local rise = t - prev
		if rise < 0.4 or rise > 0.65 then
			return false, string.format("a step of %.2f at %.2f", rise, t)
		end
		prev = t
	end
	if math.abs(prev - (y0 + H)) > 0.05 then
		return false, string.format("the last step ends at %.2f", prev)
	end
	return true, #tops .. " steps"
end

Sim.fire(p, "BuyExpansion", "zone_floor2")
Sim.check("the second floor is bought", Sim.waitFor(function()
	return d.zones.zone_floor2 == true
end, 5) == true)
task.wait(2)
local ok, why = evenSteps(steps(0), 0)
Sim.check("the stairs climb a whole floor in even, low steps", ok, why)
local landing = tagged("Floor", function(part, pos)
	return part:GetAttribute("Stairs") == true and part.Name ~= "Step" and math.abs(pos.Y + part.Size.Y / 2 - H / 2) < 0.05 and part.Size.X >= 7.5 and part.Size.Z >= 7.5
end)
Sim.check("a landing halfway up", #landing == 1, #landing .. " landings")
local guards = {}
for _, part in ipairs(plot.folder:GetDescendants()) do
	if part:IsA("BasePart") and part.Transparency >= 1 and part.CanCollide and not part.CanQuery then
		local pos = part.Position - O
		if pos.X > -35 and pos.X < -12 and pos.Z > 2 and pos.Z < 24 and pos.Y > 1 and pos.Y < H + 3 then
			table.insert(guards, part)
		end
	end
end
-- two sides of two flights and the landing's two outer sides
Sim.check("invisible guards along both sides of the stairs", #guards >= 6, #guards .. " guards")
local st = Expansions.byId.zone_floor2.stairs[1]
local hole = st.hole
local covering = tagged("Floor", function(part, pos)
	if part:GetAttribute("FloorIndex") ~= 1 then
		return false
	end
	local hx, hz = part.Size.X / 2, part.Size.Z / 2
	return pos.X - hx < hole[3] - 0.5 and pos.X + hx > hole[1] + 0.5 and pos.Z - hz < hole[4] - 0.5 and pos.Z + hz > hole[2] + 0.5
end)
Sim.check("the floor above is open over the stairs", #covering == 0, #covering .. " floor parts")
local function railAt(axis, line, a, b)
	for _, r in ipairs(tagged("Wall", function(part)
		return part:GetAttribute("Rail") == true and part:GetAttribute("FloorIndex") == 1
	end)) do
		local pos, size = r.pos, r.part.Size
		if axis == "z" and math.abs(pos.Z - line) < 0.6 and pos.X - size.X / 2 <= a + 0.6 and pos.X + size.X / 2 >= b - 0.6 then
			return true
		elseif axis == "x" and math.abs(pos.X - line) < 0.6 and pos.Z - size.Z / 2 <= a + 0.6 and pos.Z + size.Z / 2 >= b - 0.6 then
			return true
		end
	end
	return false
end
Sim.check("railings round the opening upstairs", railAt("z", hole[2], hole[1], hole[3]) and railAt("z", hole[4], hole[1], hole[3]) and railAt("x", hole[1], hole[2], hole[4]))
Sim.check("no railing where you step off", not railAt("x", hole[3], hole[2], hole[4]))
Sim.check("the table under the stairs went to the inventory", (d.inventory.table_2 or 0) == 1, tostring(d.inventory.table_2))

-- furniture upstairs: a table on the second floor
local placedBefore = #d.placed
Sim.fire(p, "PlaceItem", { i = "table_2", x = 10, z = 20, r = 0, f = 1, s = "f" }, true)
Sim.check("a table goes upstairs", Sim.waitFor(function()
	return #d.placed == placedBefore + 1
end, 3) == true and (d.inventory.table_2 or 0) == 0, tostring(#d.placed - placedBefore))

-- the roof terrace: the same stairs, mirrored on the east side of the second floor
Sim.fire(p, "BuyExpansion", "zone_rooftop")
Sim.check("the roof terrace is bought", Sim.waitFor(function()
	return d.zones.zone_rooftop == true
end, 5) == true)
task.wait(2)
ok, why = evenSteps(steps(H), H)
Sim.check("the stairs to the roof climb in even, low steps", ok, why)
ok, why = evenSteps(steps(0), 0)
Sim.check("the stairs below are still there", ok, why)
task.wait(1)
Sim.check("server closes cleanly", Sim.close())
