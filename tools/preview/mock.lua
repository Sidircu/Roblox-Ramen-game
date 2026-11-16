-- Minimal Roblox API mock used by tools/preview.py to run the procedural model builders
-- outside Roblox and collect the parts they create. Only what the builders use is modelled.

------------------------------------------------------------------ Vector3
local V3 = {}
V3.__index = function(t, k)
	if k == "Magnitude" then
		return math.sqrt(t.X * t.X + t.Y * t.Y + t.Z * t.Z)
	elseif k == "Unit" then
		local m = math.sqrt(t.X * t.X + t.Y * t.Y + t.Z * t.Z)
		if m == 0 then
			return t
		end
		return Vector3.new(t.X / m, t.Y / m, t.Z / m)
	end
	return V3[k]
end
V3.__add = function(a, b) return Vector3.new(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end
V3.__sub = function(a, b) return Vector3.new(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end
V3.__unm = function(a) return Vector3.new(-a.X, -a.Y, -a.Z) end
V3.__mul = function(a, b)
	if type(a) == "number" then return Vector3.new(a * b.X, a * b.Y, a * b.Z) end
	if type(b) == "number" then return Vector3.new(a.X * b, a.Y * b, a.Z * b) end
	return Vector3.new(a.X * b.X, a.Y * b.Y, a.Z * b.Z)
end
V3.__div = function(a, b)
	if type(b) == "number" then return Vector3.new(a.X / b, a.Y / b, a.Z / b) end
	return Vector3.new(a.X / b.X, a.Y / b.Y, a.Z / b.Z)
end
V3.__eq = function(a, b) return a.X == b.X and a.Y == b.Y and a.Z == b.Z end
V3.__type = "Vector3"
function V3.Lerp(a, b, t) return a + (b - a) * t end
function V3.Dot(a, b) return a.X * b.X + a.Y * b.Y + a.Z * b.Z end
function V3.Cross(a, b) return Vector3.new(a.Y * b.Z - a.Z * b.Y, a.Z * b.X - a.X * b.Z, a.X * b.Y - a.Y * b.X) end
Vector3 = {
	new = function(x, y, z) return setmetatable({ X = x or 0, Y = y or 0, Z = z or 0 }, V3) end,
}
Vector3.zero = Vector3.new(0, 0, 0)
Vector3.one = Vector3.new(1, 1, 1)

------------------------------------------------------------------ CFrame (position + 3x3 rotation, row major)
local CF = {}
local function mkcf(x, y, z, r)
	return setmetatable({ x = x, y = y, z = z, r = r }, CF)
end
local I3 = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }
local function matmul(a, b)
	local o = {}
	for i = 0, 2 do
		for j = 0, 2 do
			o[i * 3 + j + 1] = a[i * 3 + 1] * b[j + 1] + a[i * 3 + 2] * b[3 + j + 1] + a[i * 3 + 3] * b[6 + j + 1]
		end
	end
	return o
end
local function rotx(a) local c, s = math.cos(a), math.sin(a) return { 1, 0, 0, 0, c, -s, 0, s, c } end
local function roty(a) local c, s = math.cos(a), math.sin(a) return { c, 0, s, 0, 1, 0, -s, 0, c } end
local function rotz(a) local c, s = math.cos(a), math.sin(a) return { c, -s, 0, s, c, 0, 0, 0, 1 } end
CF.__type = "CFrame"
CF.__index = function(t, k)
	local r = t.r
	if k == "Position" or k == "p" then return Vector3.new(t.x, t.y, t.z)
	elseif k == "X" then return t.x
	elseif k == "Y" then return t.y
	elseif k == "Z" then return t.z
	elseif k == "LookVector" then return Vector3.new(-r[3], -r[6], -r[9])
	elseif k == "RightVector" then return Vector3.new(r[1], r[4], r[7])
	elseif k == "UpVector" then return Vector3.new(r[2], r[5], r[8])
	end
	return CF[k]
end
CF.__mul = function(a, b)
	if getmetatable(b) == CF then
		local r = matmul(a.r, b.r)
		local x = a.r[1] * b.x + a.r[2] * b.y + a.r[3] * b.z + a.x
		local y = a.r[4] * b.x + a.r[5] * b.y + a.r[6] * b.z + a.y
		local z = a.r[7] * b.x + a.r[8] * b.y + a.r[9] * b.z + a.z
		return mkcf(x, y, z, r)
	end
	local v = b
	return Vector3.new(
		a.r[1] * v.X + a.r[2] * v.Y + a.r[3] * v.Z + a.x,
		a.r[4] * v.X + a.r[5] * v.Y + a.r[6] * v.Z + a.y,
		a.r[7] * v.X + a.r[8] * v.Y + a.r[9] * v.Z + a.z
	)
end
CF.__add = function(a, v) return mkcf(a.x + v.X, a.y + v.Y, a.z + v.Z, a.r) end
CF.__sub = function(a, v) return mkcf(a.x - v.X, a.y - v.Y, a.z - v.Z, a.r) end
function CF.Inverse(a)
	local r = a.r
	local t = { r[1], r[4], r[7], r[2], r[5], r[8], r[3], r[6], r[9] }
	local x = -(t[1] * a.x + t[2] * a.y + t[3] * a.z)
	local y = -(t[4] * a.x + t[5] * a.y + t[6] * a.z)
	local z = -(t[7] * a.x + t[8] * a.y + t[9] * a.z)
	return mkcf(x, y, z, t)
end
function CF.Lerp(a, b, t)
	local r = {}
	for i = 1, 9 do r[i] = a.r[i] + (b.r[i] - a.r[i]) * t end
	return mkcf(a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t, a.z + (b.z - a.z) * t, r)
end
function CF.ToWorldSpace(a, b) return a * b end
function CF.PointToWorldSpace(a, v) return a * v end
CFrame = {
	new = function(x, y, z, ...)
		if type(x) == "table" then return mkcf(x.X, x.Y, x.Z, I3) end
		return mkcf(x or 0, y or 0, z or 0, I3)
	end,
	Angles = function(ax, ay, az)
		return mkcf(0, 0, 0, matmul(matmul(rotx(ax or 0), roty(ay or 0)), rotz(az or 0)))
	end,
	lookAt = function(pos, target)
		local f = (target - pos).Unit
		local up = Vector3.new(0, 1, 0)
		if math.abs(f:Dot(up)) > 0.999 then up = Vector3.new(0, 0, 1) end
		local right = f:Cross(up).Unit
		local u = right:Cross(f).Unit
		return mkcf(pos.X, pos.Y, pos.Z, { right.X, u.X, -f.X, right.Y, u.Y, -f.Y, right.Z, u.Z, -f.Z })
	end,
}
CFrame.fromEulerAnglesXYZ = CFrame.Angles
CFrame.identity = CFrame.new()

------------------------------------------------------------------ Color3
local C3 = {}
C3.__index = C3
C3.__type = "Color3"
C3.__eq = function(a, b) return math.abs(a.R - b.R) < 1e-6 and math.abs(a.G - b.G) < 1e-6 and math.abs(a.B - b.B) < 1e-6 end
function C3.Lerp(a, b, t) return Color3.new(a.R + (b.R - a.R) * t, a.G + (b.G - a.G) * t, a.B + (b.B - a.B) * t) end
function C3.ToHSV(c)
	local r, g, b = c.R, c.G, c.B
	local mx, mn = math.max(r, g, b), math.min(r, g, b)
	local h, s, v = 0, 0, mx
	local d = mx - mn
	if mx > 0 then s = d / mx end
	if d > 0 then
		if mx == r then h = ((g - b) / d) % 6 elseif mx == g then h = (b - r) / d + 2 else h = (r - g) / d + 4 end
		h = h / 6
	end
	return h, s, v
end
Color3 = {
	new = function(r, g, b) return setmetatable({ R = r or 0, G = g or 0, B = b or 0 }, C3) end,
	fromRGB = function(r, g, b) return setmetatable({ R = (r or 0) / 255, G = (g or 0) / 255, B = (b or 0) / 255 }, C3) end,
	fromHSV = function(h, s, v)
		local i = math.floor(h * 6)
		local f = h * 6 - i
		local p, q, t = v * (1 - s), v * (1 - f * s), v * (1 - (1 - f) * s)
		local m = i % 6
		local r, g, b
		if m == 0 then r, g, b = v, t, p elseif m == 1 then r, g, b = q, v, p elseif m == 2 then r, g, b = p, v, t
		elseif m == 3 then r, g, b = p, q, v elseif m == 4 then r, g, b = t, p, v else r, g, b = v, p, q end
		return setmetatable({ R = r, G = g, B = b }, C3)
	end,
}

------------------------------------------------------------------ misc datatypes
local function dummy(name)
	return { new = function(...) return { __kind = name, args = { ... } } end }
end
NumberSequence = dummy("NumberSequence")
NumberSequenceKeypoint = dummy("NumberSequenceKeypoint")
ColorSequence = dummy("ColorSequence")
NumberRange = dummy("NumberRange")
Vector2 = { new = function(x, y) return { X = x or 0, Y = y or 0 } end }
UDim = dummy("UDim")
UDim2 = { new = function(...) return {} end, fromScale = function() return {} end, fromOffset = function() return {} end }
Font = { new = function(...) return { __kind = "Font" } end }
Random = {
	new = function(seed)
		local state = (seed or os.time()) % 2147483647
		if state <= 0 then state = state + 2147483646 end
		local obj = {}
		local function nextv()
			state = (state * 16807) % 2147483647
			return state / 2147483647
		end
		function obj:NextNumber(a, b)
			local v = nextv()
			if a then return a + (b - a) * v end
			return v
		end
		function obj:NextInteger(a, b) return a + math.floor(nextv() * (b - a + 1)) end
		return obj
	end,
}

Enum = setmetatable({}, { __index = function(_, enumName)
	local e = setmetatable({}, { __index = function(t, item)
		local v = { Name = item, EnumType = enumName }
		rawset(t, item, v)
		return v
	end })
	rawset(Enum, enumName, e)
	return e
end })

function typeof(v)
	local mt = getmetatable(v)
	if type(mt) == "table" and mt.__type then return mt.__type end
	if type(v) == "table" and v.__instance then return "Instance" end
	return type(v)
end

------------------------------------------------------------------ Instances
local BASEPARTS = { Part = true, WedgePart = true, CornerWedgePart = true, TrussPart = true, Seat = true, MeshPart = true }
local LIGHTS = { PointLight = true, SpotLight = true, SurfaceLight = true }
local GUIS = { TextLabel = true, Frame = true, TextButton = true, ImageLabel = true }
ALL_PARTS = {}

local Inst = {}
local function children(o) return rawget(o, "__children") end

local methods = {}
function methods.IsA(self, cls)
	local c = rawget(self, "ClassName")
	if c == cls or cls == "Instance" then return true end
	if cls == "BasePart" then return BASEPARTS[c] == true end
	if cls == "Light" then return LIGHTS[c] == true end
	if cls == "GuiObject" then return GUIS[c] == true end
	if cls == "PVInstance" then return BASEPARTS[c] == true or c == "Model" end
	return false
end
function methods.GetChildren(self) local o = {} for i, c in ipairs(children(self)) do o[i] = c end return o end
function methods.GetDescendants(self)
	local out = {}
	local function walk(n) for _, c in ipairs(children(n)) do table.insert(out, c) walk(c) end end
	walk(self)
	return out
end
function methods.FindFirstChild(self, name, recursive)
	for _, c in ipairs(children(self)) do if c.Name == name then return c end end
	if recursive then
		for _, c in ipairs(children(self)) do local f = c:FindFirstChild(name, true) if f then return f end end
	end
	return nil
end
function methods.FindFirstChildOfClass(self, cls)
	for _, c in ipairs(children(self)) do if rawget(c, "ClassName") == cls then return c end end
	return nil
end
function methods.FindFirstChildWhichIsA(self, cls)
	for _, c in ipairs(children(self)) do if c:IsA(cls) then return c end end
	return nil
end
function methods.WaitForChild(self, name) return self:FindFirstChild(name) end
function methods.SetAttribute(self, k, v) rawget(self, "__attrs")[k] = v end
function methods.GetAttribute(self, k) return rawget(self, "__attrs")[k] end
function methods.Destroy(self)
	local p = rawget(self, "__props").Parent
	if p then
		local list = children(p)
		for i, c in ipairs(list) do if c == self then table.remove(list, i) break end end
	end
	rawget(self, "__props").Parent = nil
	rawset(self, "__destroyed", true)
	for _, c in ipairs(self:GetDescendants()) do rawset(c, "__destroyed", true) end
end
function methods.ClearAllChildren(self) for _, c in ipairs(self:GetChildren()) do c:Destroy() end end
function methods.GetPivot(self)
	if self:IsA("BasePart") then return self.CFrame end
	local pp = self.PrimaryPart
	if pp then return pp.CFrame end
	return CFrame.new()
end
function methods.PivotTo(self, target)
	if self:IsA("BasePart") then self.CFrame = target return end
	local delta = target * self:GetPivot():Inverse()
	for _, d in ipairs(self:GetDescendants()) do
		if d:IsA("BasePart") then d.CFrame = delta * d.CFrame end
	end
end
function methods.GetScale() return 1 end
function methods.ScaleTo(self, s)
	local pivot = self:GetPivot()
	local inv = pivot:Inverse()
	for _, d in ipairs(self:GetDescendants()) do
		if d:IsA("BasePart") then
			local rel = inv * d.CFrame
			d.Size = d.Size * s
			d.CFrame = pivot * (CFrame.new(rel.x * s, rel.y * s, rel.z * s) * (rel - rel.Position))
		end
	end
end
function methods.GetExtentsSize() return Vector3.new(1, 1, 1) end
function methods.Emit() end
function methods.Play() end
function methods.Clone(self) return self end

Inst.__index = function(t, k)
	if methods[k] then return methods[k] end
	local props = rawget(t, "__props")
	local v = props[k]
	if v ~= nil then return v end
	if k == "Position" and props.CFrame then return props.CFrame.Position end
	if k == "WorldCFrame" or k == "WorldPosition" then
		local parent = props.Parent
		local cf = (parent and parent.CFrame or CFrame.new()) * (props.CFrame or CFrame.new())
		return k == "WorldCFrame" and cf or cf.Position
	end
	local child = t:FindFirstChild(k)
	if child then return child end
	return nil
end
Inst.__newindex = function(t, k, v)
	local props = rawget(t, "__props")
	if k == "Parent" then
		local old = props.Parent
		if old then
			local list = children(old)
			for i, c in ipairs(list) do if c == t then table.remove(list, i) break end end
		end
		props.Parent = v
		if v then table.insert(children(v), t) end
		return
	end
	if k == "Position" then
		local cf = props.CFrame or CFrame.new()
		props.CFrame = setmetatable({ x = v.X, y = v.Y, z = v.Z, r = cf.r }, getmetatable(cf))
		return
	end
	props[k] = v
end

Instance = {
	new = function(className, parent)
		local o = setmetatable({ __instance = true, ClassName = className, __children = {}, __attrs = {}, __props = { Name = className } }, Inst)
		if BASEPARTS[className] then
			local p = rawget(o, "__props")
			p.Size = Vector3.new(4, 1, 2)
			p.CFrame = CFrame.new()
			p.Color = Color3.new(0.64, 0.64, 0.64)
			p.Transparency = 0
			p.Material = Enum.Material.Plastic
			p.Shape = Enum.PartType.Block
			table.insert(ALL_PARTS, o)
		end
		if parent then o.Parent = parent end
		return o
	end,
}

local services = {}
game = {
	GetService = function(_, name)
		if not services[name] then
			services[name] = Instance.new(name)
			local svc = services[name]
			rawset(svc, "AddTag", function(_, inst, tag) rawget(inst, "__attrs")["__tag_" .. tag] = true end)
			rawset(svc, "HasTag", function() return false end)
			rawset(svc, "GetTagged", function() return {} end)
		end
		return services[name]
	end,
}
workspace = Instance.new("Workspace")
