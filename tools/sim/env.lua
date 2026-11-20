-- Server-side Roblox simulation used by tools/sim.py.
-- Loaded after tools/preview/mock.lua (Vector3, CFrame, Color3, Random, Enum, typeof) and replaces
-- its tiny instance model with a fuller one: a virtual clock with a scheduler (task.*), signals,
-- instances with properties, children, attributes, tags and events, the services the game uses,
-- data stores kept in memory (checked like the real ones) and fake players with characters.

local realClock = os.clock
local realTime = os.time

-- Luau standard library additions
math.clamp = function(x, a, b)
	if a > b then
		error("max must be greater than or equal to min", 2)
	end
	if x < a then
		return a
	elseif x > b then
		return b
	end
	return x
end
math.round = function(x)
	if x >= 0 then
		return math.floor(x + 0.5)
	end
	return math.ceil(x - 0.5)
end
-- Luau keeps math.atan2 (Lua 5.4 folded it into math.atan)
math.atan2 = math.atan2 or function(y, x)
	return math.atan(y, x)
end
math.sign = function(x)
	if x > 0 then
		return 1
	elseif x < 0 then
		return -1
	end
	return 0
end
math.noise = function(x, y, z)
	return (math.sin((x or 0) * 12.9898 + (y or 0) * 78.233 + (z or 0) * 37.719) * 0.5)
end
table.clone = function(t)
	local o = {}
	for k, v in pairs(t) do
		o[k] = v
	end
	return o
end
table.find = function(t, v, init)
	for i = init or 1, #t do
		if t[i] == v then
			return i
		end
	end
	return nil
end
table.clear = function(t)
	for k in pairs(t) do
		t[k] = nil
	end
end
table.create = function(n, v)
	local o = {}
	for i = 1, n do
		o[i] = v
	end
	return o
end
table.freeze = function(t)
	return t
end
table.isfrozen = function()
	return false
end
string.split = function(s, sep)
	sep = sep or ","
	local out = {}
	local i = 1
	while true do
		local a, b = string.find(s, sep, i, true)
		if not a then
			table.insert(out, string.sub(s, i))
			break
		end
		table.insert(out, string.sub(s, i, a - 1))
		i = b + 1
	end
	return out
end

Sim = {
	now = 0,
	frame = 1 / 30,
	epoch = 1760000000,
	errors = {},
	warnings = {},
	logs = {},
	notices = {},
	seq = 0,
	cancelled = {},
	dsLatency = 0.04,
	dsFail = {}, -- [method] = number of calls that will fail
	clientEvents = {}, -- [player] = { {name, args...} }
	analytics = {},
	friends = {}, -- ["a:b"] = true
	studio = true,
	verbose = false,
	instances = 0,
	writes = 0, -- property writes (the GUI layout cache is valid until the next one)
}

local function fail(msg)
	table.insert(Sim.errors, msg)
	print("[sim] ERROR " .. msg)
end
Sim.fail = fail

-- the same run every time (Lua 5.4 seeds math.random at random): tools/sim.py --seed=N changes it
math.randomseed(__seed or 12345)

------------------------------------------------------------------ scheduler (binary heap by time)
local heap = {}
local function less(a, b)
	if a.t ~= b.t then
		return a.t < b.t
	end
	return a.seq < b.seq
end
local function hpush(item)
	heap[#heap + 1] = item
	local i = #heap
	while i > 1 do
		local p = i // 2
		if less(heap[i], heap[p]) then
			heap[i], heap[p] = heap[p], heap[i]
			i = p
		else
			break
		end
	end
end
local function hpop()
	local top = heap[1]
	local last = heap[#heap]
	heap[#heap] = nil
	if #heap > 0 then
		heap[1] = last
		local i = 1
		while true do
			local l, r = i * 2, i * 2 + 1
			local m = i
			if l <= #heap and less(heap[l], heap[m]) then
				m = l
			end
			if r <= #heap and less(heap[r], heap[m]) then
				m = r
			end
			if m == i then
				break
			end
			heap[i], heap[m] = heap[m], heap[i]
			i = m
		end
	end
	return top
end

local resumeStarted = 0
local function hook()
	if realClock() - resumeStarted > 20 then
		error("script timeout: a thread ran for more than 20 s without yielding", 2)
	end
end

local function resume(co, ...)
	if Sim.cancelled[co] then
		return
	end
	if coroutine.status(co) ~= "suspended" then
		return
	end
	local outer = resumeStarted
	resumeStarted = realClock()
	debug.sethook(co, hook, "", 1000000)
	local ok, err = coroutine.resume(co, ...)
	resumeStarted = outer
	if not ok then
		Sim.fail("uncaught error: " .. tostring(err) .. "\n" .. debug.traceback(co))
	end
end
Sim.resume = resume

local function schedule(t, co, args, fn)
	Sim.seq = Sim.seq + 1
	hpush({ t = t, seq = Sim.seq, co = co, args = args, fn = fn })
end
Sim.schedule = schedule

local function pack(...)
	return { n = select("#", ...), ... }
end

task = {}
function task.spawn(f, ...)
	local co = type(f) == "thread" and f or coroutine.create(f)
	resume(co, ...)
	return co
end
function task.defer(f, ...)
	local co = type(f) == "thread" and f or coroutine.create(f)
	schedule(Sim.now, co, pack(...))
	return co
end
function task.delay(t, f, ...)
	local co = type(f) == "thread" and f or coroutine.create(f)
	schedule(Sim.now + math.max(t or 0, 0), co, pack(...))
	return co
end
function task.wait(t)
	local co, main = coroutine.running()
	if main then
		error("task.wait outside a thread")
	end
	local start = Sim.now
	schedule(Sim.now + math.max(t or 0, Sim.frame), co, nil)
	coroutine.yield()
	return Sim.now - start
end
function task.cancel(co)
	Sim.cancelled[co] = true
end
function task.synchronize() end
function task.desynchronize() end
wait = function(t)
	local e = task.wait(t)
	return e, Sim.now
end
delay = task.delay
spawn = function(f)
	task.defer(f)
end

-- runs every scheduled thread up to virtual time `untilT`
function Sim.step(untilT)
	while #heap > 0 and heap[1].t <= untilT do
		local item = hpop()
		if item.t > Sim.now then
			Sim.now = item.t
		end
		if item.fn then
			item.fn()
		elseif item.args then
			resume(item.co, table.unpack(item.args, 1, item.args.n))
		else
			resume(item.co)
		end
	end
	if untilT > Sim.now then
		Sim.now = untilT
	end
end

os.clock = function()
	return Sim.now
end
os.time = function(t)
	if t then
		return realTime(t)
	end
	return Sim.epoch + math.floor(Sim.now)
end
tick = function()
	return Sim.epoch + Sim.now
end
time = function()
	return Sim.now
end
elapsedTime = time

------------------------------------------------------------------ signals
local SignalMT = {}
SignalMT.__index = SignalMT
local function newSignal(name)
	return setmetatable({ name = name, conns = {}, waiting = {} }, SignalMT)
end
Sim.signal = newSignal
function SignalMT:Connect(fn)
	if type(fn) ~= "function" then
		error("Attempt to connect failed: Passed value is not a function", 2)
	end
	local c = { Connected = true, fn = fn }
	function c.Disconnect()
		c.Connected = false
	end
	table.insert(self.conns, c)
	return c
end
SignalMT.connect = SignalMT.Connect
function SignalMT:ConnectParallel(fn)
	return self:Connect(fn)
end
function SignalMT:Once(fn)
	local c
	c = self:Connect(function(...)
		c.Disconnect()
		fn(...)
	end)
	return c
end
function SignalMT:Wait()
	local co, main = coroutine.running()
	if main then
		error("Wait outside a thread")
	end
	table.insert(self.waiting, co)
	return coroutine.yield()
end
function SignalMT:Fire(...)
	local live = {}
	for _, c in ipairs(self.conns) do
		if c.Connected then
			table.insert(live, c)
		end
	end
	self.conns = live
	local list = table.move(live, 1, #live, 1, {})
	for _, c in ipairs(list) do
		if c.Connected then
			task.spawn(c.fn, ...)
		end
	end
	if #self.waiting > 0 then
		local waiting = self.waiting
		self.waiting = {}
		local args = pack(...)
		for _, co in ipairs(waiting) do
			schedule(Sim.now, co, args)
		end
	end
end
function SignalMT:DisconnectAll()
	for _, c in ipairs(self.conns) do
		c.Connected = false
	end
	self.conns = {}
end

------------------------------------------------------------------ datatypes the preview mock lacks
local V2MT = {}
V2MT.__type = "Vector2"
V2MT.__index = function(t, k)
	if k == "Magnitude" then
		return math.sqrt(t.X * t.X + t.Y * t.Y)
	elseif k == "Unit" then
		local m = math.sqrt(t.X * t.X + t.Y * t.Y)
		return m == 0 and t or Vector2.new(t.X / m, t.Y / m)
	end
	return V2MT[k]
end
V2MT.__add = function(a, b)
	return Vector2.new(a.X + b.X, a.Y + b.Y)
end
V2MT.__sub = function(a, b)
	return Vector2.new(a.X - b.X, a.Y - b.Y)
end
V2MT.__mul = function(a, b)
	if type(a) == "number" then
		return Vector2.new(a * b.X, a * b.Y)
	elseif type(b) == "number" then
		return Vector2.new(a.X * b, a.Y * b)
	end
	return Vector2.new(a.X * b.X, a.Y * b.Y)
end
V2MT.__div = function(a, b)
	return Vector2.new(a.X / b, a.Y / b)
end
V2MT.__eq = function(a, b)
	return a.X == b.X and a.Y == b.Y
end
function V2MT.Lerp(a, b, t)
	return a + (b - a) * t
end
function V2MT.Dot(a, b)
	return a.X * b.X + a.Y * b.Y
end
Vector2 = {
	new = function(x, y)
		return setmetatable({ X = x or 0, Y = y or 0 }, V2MT)
	end,
}
Vector2.zero = Vector2.new(0, 0)
Vector2.one = Vector2.new(1, 1)

local function opaque(kind, fields)
	return setmetatable(fields or {}, { __type = kind, __index = function()
		return nil
	end })
end
UDim = {
	new = function(s, o)
		return opaque("UDim", { Scale = s or 0, Offset = o or 0 })
	end,
}
UDim2 = {
	new = function(xs, xo, ys, yo)
		return opaque("UDim2", { X = UDim.new(xs, xo), Y = UDim.new(ys, yo) })
	end,
	fromScale = function(x, y)
		return UDim2.new(x, 0, y, 0)
	end,
	fromOffset = function(x, y)
		return UDim2.new(0, x, 0, y)
	end,
}
TweenInfo = {
	new = function(time, style, dir, repeatCount, reverses, delayTime)
		return opaque("TweenInfo", { Time = time or 1, EasingStyle = style, EasingDirection = dir, RepeatCount = repeatCount or 0, Reverses = reverses or false, DelayTime = delayTime or 0 })
	end,
}
NumberRange = {
	new = function(a, b)
		return opaque("NumberRange", { Min = a, Max = b or a })
	end,
}
NumberSequence = {
	new = function(...)
		return opaque("NumberSequence", { args = { ... } })
	end,
}
NumberSequenceKeypoint = {
	new = function(t, v, e)
		return opaque("NumberSequenceKeypoint", { Time = t, Value = v, Envelope = e or 0 })
	end,
}
ColorSequence = {
	new = function(...)
		return opaque("ColorSequence", { args = { ... } })
	end,
}
ColorSequenceKeypoint = {
	new = function(t, c)
		return opaque("ColorSequenceKeypoint", { Time = t, Value = c })
	end,
}
PhysicalProperties = {
	new = function(...)
		return opaque("PhysicalProperties", { args = { ... } })
	end,
}
Font = {
	new = function(family, weight, style)
		return opaque("Font", { Family = family, Weight = weight, Style = style })
	end,
	fromEnum = function(e)
		return opaque("Font", { Family = tostring(e) })
	end,
}
BrickColor = {
	new = function(name)
		return opaque("BrickColor", { Name = tostring(name), Color = Color3.new(0.6, 0.6, 0.6) })
	end,
}
RaycastParams = {
	new = function()
		local p = opaque("RaycastParams", { FilterType = Enum.RaycastFilterType.Exclude, FilterDescendantsInstances = {}, IgnoreWater = false, CollisionGroup = "Default" })
		return p
	end,
}
OverlapParams = RaycastParams
Ray = {
	new = function(o, d)
		return opaque("Ray", { Origin = o, Direction = d })
	end,
}
Rect = {
	new = function(a, b, c, d)
		return opaque("Rect", { args = { a, b, c, d } })
	end,
}
DateTime = {
	now = function()
		local s = Sim.epoch + Sim.now
		return opaque("DateTime", { UnixTimestamp = math.floor(s), UnixTimestampMillis = math.floor(s * 1000) })
	end,
	fromUnixTimestamp = function(s)
		return opaque("DateTime", { UnixTimestamp = s, UnixTimestampMillis = s * 1000 })
	end,
}

-- CFrame helpers the services may use and the preview mock does not define
do
	local CF = getmetatable(CFrame.new())
	local base = CF.__index
	CF.__index = function(t, k)
		if k == "Rotation" then
			return setmetatable({ x = 0, y = 0, z = 0, r = t.r }, CF)
		elseif k == "XVector" then
			return Vector3.new(t.r[1], t.r[4], t.r[7])
		elseif k == "YVector" then
			return Vector3.new(t.r[2], t.r[5], t.r[8])
		elseif k == "ZVector" then
			return Vector3.new(t.r[3], t.r[6], t.r[9])
		end
		return base(t, k)
	end
	function CF.ToObjectSpace(a, b)
		return a:Inverse() * b
	end
	function CF.PointToObjectSpace(a, v)
		return a:Inverse() * v
	end
	function CF.VectorToWorldSpace(a, v)
		return Vector3.new(a.r[1] * v.X + a.r[2] * v.Y + a.r[3] * v.Z, a.r[4] * v.X + a.r[5] * v.Y + a.r[6] * v.Z, a.r[7] * v.X + a.r[8] * v.Y + a.r[9] * v.Z)
	end
	function CF.VectorToObjectSpace(a, v)
		return a:Inverse():VectorToWorldSpace(v)
	end
	function CF.GetComponents(a)
		local r = a.r
		return a.x, a.y, a.z, r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9]
	end
	CF.components = CF.GetComponents
	function CF.ToEulerAnglesXYZ(a)
		local r = a.r
		local y = math.asin(math.max(-1, math.min(1, r[3])))
		local x = math.atan(-r[6], r[9])
		local z = math.atan(-r[2], r[1])
		return x, y, z
	end
	function CF.ToOrientation(a)
		local r = a.r
		local x = math.asin(math.max(-1, math.min(1, -r[6])))
		local y = math.atan(r[3], r[9])
		local z = math.atan(r[4], r[5])
		return x, y, z
	end
	CF.__eq = function(a, b)
		if a.x ~= b.x or a.y ~= b.y or a.z ~= b.z then
			return false
		end
		for i = 1, 9 do
			if a.r[i] ~= b.r[i] then
				return false
			end
		end
		return true
	end
	CF.ToEulerAnglesYXZ = CF.ToOrientation
	CFrame.fromOrientation = function(x, y, z)
		return CFrame.Angles(0, y, 0) * CFrame.Angles(x, 0, 0) * CFrame.Angles(0, 0, z)
	end
	CFrame.fromEulerAnglesYXZ = CFrame.fromOrientation
	CFrame.fromAxisAngle = function(axis, a)
		if math.abs(axis.Y) > 0.9 then
			return CFrame.Angles(0, a * (axis.Y > 0 and 1 or -1), 0)
		elseif math.abs(axis.X) > 0.9 then
			return CFrame.Angles(a * (axis.X > 0 and 1 or -1), 0, 0)
		end
		return CFrame.Angles(0, 0, a * (axis.Z > 0 and 1 or -1))
	end
	local V3 = getmetatable(Vector3.new())
	local vbase = V3.__index
	V3.__index = function(t, k)
		return vbase(t, k)
	end
	function V3.FuzzyEq(a, b, eps)
		return (a - b).Magnitude <= (eps or 1e-5)
	end
	function V3.Max(a, b)
		return Vector3.new(math.max(a.X, b.X), math.max(a.Y, b.Y), math.max(a.Z, b.Z))
	end
	function V3.Min(a, b)
		return Vector3.new(math.min(a.X, b.X), math.min(a.Y, b.Y), math.min(a.Z, b.Z))
	end
	function V3.Abs(a)
		return Vector3.new(math.abs(a.X), math.abs(a.Y), math.abs(a.Z))
	end
	Vector3.xAxis = Vector3.new(1, 0, 0)
	Vector3.yAxis = Vector3.new(0, 1, 0)
	Vector3.zAxis = Vector3.new(0, 0, 1)
	local C3 = getmetatable(Color3.new())
	function C3.ToHex(c)
		return string.format("%02X%02X%02X", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
	end
	Color3.fromHex = function(h)
		h = h:gsub("#", "")
		return Color3.fromRGB(tonumber(h:sub(1, 2), 16), tonumber(h:sub(3, 4), 16), tonumber(h:sub(5, 6), 16))
	end
end

-- Enum items know their type and can be listed
do
	local items = {}
	Enum = setmetatable({}, { __index = function(_, enumName)
		local e = setmetatable({}, { __index = function(t, item)
			if item == "GetEnumItems" then
				return function()
					return items[enumName] or {}
				end
			end
			local v = setmetatable({ Name = item, EnumType = enumName, Value = 0 }, { __type = "EnumItem", __tostring = function()
				return "Enum." .. enumName .. "." .. item
			end })
			items[enumName] = items[enumName] or {}
			table.insert(items[enumName], v)
			rawset(t, item, v)
			return v
		end })
		rawset(Enum, enumName, e)
		return e
	end })
end

local baseTypeof = typeof
function typeof(v)
	if type(v) == "table" and rawget(v, "__inst") then
		return "Instance"
	end
	if type(v) == "table" and getmetatable(v) == SignalMT then
		return "RBXScriptSignal"
	end
	return baseTypeof(v)
end

------------------------------------------------------------------ instances
local PARENT = {
	Part = "BasePart", MeshPart = "BasePart", WedgePart = "BasePart", CornerWedgePart = "BasePart", TrussPart = "BasePart",
	Seat = "BasePart", VehicleSeat = "BasePart", SpawnLocation = "BasePart", UnionOperation = "BasePart", Terrain = "BasePart",
	BasePart = "PVInstance", Model = "PVInstance", Workspace = "Model", PVInstance = "Instance", Actor = "Model",
	PointLight = "Light", SpotLight = "Light", SurfaceLight = "Light", Light = "Instance",
	Frame = "GuiObject", TextLabel = "GuiObject", ImageLabel = "GuiObject", ScrollingFrame = "GuiObject", TextBox = "GuiObject",
	ViewportFrame = "GuiObject", CanvasGroup = "GuiObject", TextButton = "GuiButton", ImageButton = "GuiButton", GuiButton = "GuiObject",
	GuiObject = "GuiBase2d", GuiBase2d = "Instance", ScreenGui = "LayerCollector", BillboardGui = "LayerCollector",
	SurfaceGui = "LayerCollector", LayerCollector = "GuiBase2d",
	Weld = "JointInstance", Motor6D = "JointInstance", Snap = "JointInstance", ManualWeld = "JointInstance", JointInstance = "Instance",
	Script = "BaseScript", LocalScript = "BaseScript", BaseScript = "LuaSourceContainer", ModuleScript = "LuaSourceContainer",
	RemoteEvent = "BaseRemoteEvent", UnreliableRemoteEvent = "BaseRemoteEvent", Bone = "Attachment",
	IntValue = "ValueBase", NumberValue = "ValueBase", StringValue = "ValueBase", BoolValue = "ValueBase", ObjectValue = "ValueBase",
	Vector3Value = "ValueBase", CFrameValue = "ValueBase", Color3Value = "ValueBase",
	Shirt = "Clothing", Pants = "Clothing", Accessory = "Accoutrement", Hat = "Accoutrement",
	SpecialMesh = "DataModelMesh", BlockMesh = "DataModelMesh",
	Decal = "FaceInstance", Texture = "Decal",
	WeldConstraint = "Instance", RopeConstraint = "Constraint", AlignPosition = "Constraint", AlignOrientation = "Constraint",
	BloomEffect = "PostEffect", ColorCorrectionEffect = "PostEffect", SunRaysEffect = "PostEffect", BlurEffect = "PostEffect",
}
local function isA(cls, target)
	if target == "Instance" then
		return true
	end
	local c = cls
	while c do
		if c == target then
			return true
		end
		c = PARENT[c]
	end
	return false
end

local DEFAULTS = {
	BasePart = function()
		return {
			Size = Vector3.new(4, 1, 2), CFrame = CFrame.new(), Anchored = false, CanCollide = true, CanQuery = true, CanTouch = true,
			CastShadow = true, Transparency = 0, Reflectance = 0, Material = Enum.Material.Plastic, Color = Color3.new(0.64, 0.64, 0.64),
			Massless = false, Locked = false, CollisionGroup = "Default", AssemblyLinearVelocity = Vector3.new(), AssemblyAngularVelocity = Vector3.new(),
			Shape = Enum.PartType.Block, LocalTransparencyModifier = 0, RootPriority = 0,
		}
	end,
	Seat = function()
		return { Disabled = false }
	end,
	Model = function()
		return { LevelOfDetail = Enum.ModelLevelOfDetail.Automatic }
	end,
	Humanoid = function()
		return {
			WalkSpeed = 16, JumpPower = 50, JumpHeight = 7.2, Health = 100, MaxHealth = 100, HipHeight = 2, AutoRotate = true, Sit = false,
			PlatformStand = false, DisplayName = "", RigType = Enum.HumanoidRigType.R15, MoveDirection = Vector3.new(), FloorMaterial = Enum.Material.Plastic,
			UseJumpPower = false, BreakJointsOnDeath = true, RequiresNeck = true, EvaluateStateMachine = true,
		}
	end,
	Player = function()
		return { AccountAge = 120, MembershipType = Enum.MembershipType.None, FollowUserId = 0, Neutral = true, CameraMaxZoomDistance = 128, CameraMinZoomDistance = 0.5 }
	end,
	Sound = function()
		return { Volume = 0.5, Playing = false, Looped = false, PlaybackSpeed = 1, TimePosition = 0, TimeLength = 1, IsLoaded = true, IsPlaying = false, RollOffMaxDistance = 10000, RollOffMinDistance = 10 }
	end,
	Light = function()
		return { Brightness = 1, Range = 8, Enabled = true, Color = Color3.new(1, 1, 1), Shadows = false }
	end,
	Attachment = function()
		return { CFrame = CFrame.new(), Visible = false }
	end,
	ProximityPrompt = function()
		return {
			ActionText = "Interact", ObjectText = "", HoldDuration = 0, MaxActivationDistance = 10, Enabled = true, KeyboardKeyCode = Enum.KeyCode.E,
			GamepadKeyCode = Enum.KeyCode.ButtonX, RequiresLineOfSight = true, Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton,
			Style = Enum.ProximityPromptStyle.Default, UIOffset = Vector2.new(), ClickablePrompt = true,
		}
	end,
	LayerCollector = function()
		return { Enabled = true }
	end,
	GuiObject = function()
		return { Visible = true, BackgroundTransparency = 0, Size = UDim2.new(0, 100, 0, 100), Position = UDim2.new(0, 0, 0, 0), Text = "" }
	end,
	ParticleEmitter = function()
		return { Enabled = true, Rate = 20 }
	end,
	Beam = function()
		return { Enabled = true }
	end,
	Lighting = function()
		return { ClockTime = 14, Brightness = 2, GeographicLatitude = 41.7, Ambient = Color3.new(0, 0, 0), OutdoorAmbient = Color3.new(0.5, 0.5, 0.5), FogEnd = 100000, ExposureCompensation = 0, EnvironmentDiffuseScale = 1, EnvironmentSpecularScale = 1, GlobalShadows = true }
	end,
	Workspace = function()
		return { Gravity = 196.2, StreamingEnabled = false }
	end,
	IntValue = function()
		return { Value = 0 }
	end,
	NumberValue = function()
		return { Value = 0 }
	end,
	StringValue = function()
		return { Value = "" }
	end,
	BoolValue = function()
		return { Value = false }
	end,
	Path = function()
		return { Status = Enum.PathStatus.NoPath }
	end,
	AnimationTrack = function()
		return { Length = 1, Looped = false, IsPlaying = false, Speed = 1, Priority = Enum.AnimationPriority.Core, TimePosition = 0, WeightCurrent = 1 }
	end,
	Animation = function()
		return { AnimationId = "" }
	end,
	Tween = function()
		return { PlaybackState = Enum.PlaybackState.Begin }
	end,
}

local function defaultsFor(cls)
	local out = {}
	local chain = {}
	local c = cls
	while c do
		table.insert(chain, 1, c)
		c = PARENT[c]
	end
	for _, k in ipairs(chain) do
		local f = DEFAULTS[k]
		if f then
			for name, v in pairs(f()) do
				out[name] = v
			end
		end
	end
	return out
end

local EVENTS = {}
for _, n in ipairs({
	"Changed", "ChildAdded", "ChildRemoved", "DescendantAdded", "DescendantRemoving", "AncestryChanged", "Destroying", "AttributeChanged",
	"Touched", "TouchEnded", "MoveToFinished", "Died", "Running", "Seated", "StateChanged", "Jumping", "HealthChanged",
	"Triggered", "TriggerEnded", "PromptButtonHoldBegan", "PromptButtonHoldEnded", "PromptShown", "PromptHidden",
	"OnServerEvent", "OnClientEvent", "Event", "Completed", "Stopped", "Ended", "DidLoop", "Played", "Paused", "Resumed", "Loaded",
	"PlayerAdded", "PlayerRemoving", "CharacterAdded", "CharacterRemoving", "CharacterAppearanceLoaded", "Chatted", "Idled",
	"Heartbeat", "Stepped", "RenderStepped", "PreSimulation", "PostSimulation", "PreRender", "PreAnimation",
	"Blocked", "Unblocked", "ReachedTarget", "MouseClick", "MouseButton1Click", "MouseButton1Down", "MouseButton1Up", "Activated",
	"FocusLost", "InputBegan", "InputEnded", "InputChanged", "PromptGamePassPurchaseFinished", "PromptProductPurchaseFinished",
	"PromptPurchaseFinished", "LightingChanged", "KeyframeReached", "OnInvoke", "TeleportInitFailed", "Close",
}) do
	EVENTS[n] = true
end

local Inst = {}
local methods = {}
local classMethods = {}

local function props(o)
	return rawget(o, "__props")
end
local function kids(o)
	return rawget(o, "__children")
end
local function className(o)
	return rawget(o, "__class")
end

local function eventOf(o, name)
	local sigs = rawget(o, "__signals")
	local s = sigs[name]
	if not s then
		s = newSignal(name)
		sigs[name] = s
	end
	return s
end

local function propSignal(o, name)
	local sigs = rawget(o, "__propSignals")
	local s = sigs[name]
	if not s then
		s = newSignal("prop:" .. name)
		sigs[name] = s
	end
	return s
end

local function attrSignal(o, name)
	local sigs = rawget(o, "__attrSignals")
	local s = sigs[name]
	if not s then
		s = newSignal("attr:" .. name)
		sigs[name] = s
	end
	return s
end

local function fireIf(o, kind, name, ...)
	local sigs = rawget(o, kind)
	local s = sigs[name]
	if s then
		s:Fire(...)
	end
end

local function ancestors(o)
	local out = {}
	local p = props(o).Parent
	while p do
		table.insert(out, p)
		p = props(p).Parent
	end
	return out
end

local tagIndex = {} -- [tag] = { [inst] = true }
local tagAdded, tagRemoved = {}, {}

local function inGame(o)
	local p = o
	while p do
		if p == game then
			return true
		end
		p = props(p).Parent
	end
	return false
end
Sim.inGame = inGame

local function setParent(o, newParent)
	local pr = props(o)
	local old = pr.Parent
	if rawget(o, "__destroyed") then
		error("The Parent property of " .. tostring(pr.Name) .. " is locked, current parent: NULL, new parent " .. tostring(newParent and props(newParent).Name), 3)
	end
	if old == newParent then
		return
	end
	if newParent ~= nil and (type(newParent) ~= "table" or not rawget(newParent, "__inst")) then
		error("Parent must be an Instance", 3)
	end
	if newParent == o then
		error("Attempt to set " .. tostring(pr.Name) .. " as its own parent", 3)
	end
	if old then
		local list = kids(old)
		for i, c in ipairs(list) do
			if c == o then
				table.remove(list, i)
				break
			end
		end
		fireIf(old, "__signals", "ChildRemoved", o)
		for _, a in ipairs({ old, table.unpack(ancestors(old)) }) do
			fireIf(a, "__signals", "DescendantRemoving", o)
		end
	end
	pr.Parent = newParent
	if newParent then
		table.insert(kids(newParent), o)
		fireIf(newParent, "__signals", "ChildAdded", o)
		local list = { newParent }
		for _, a in ipairs(ancestors(newParent)) do
			table.insert(list, a)
		end
		for _, a in ipairs(list) do
			if rawget(a, "__signals").DescendantAdded then
				a.DescendantAdded:Fire(o)
				for _, d in ipairs(o:GetDescendants()) do
					a.DescendantAdded:Fire(d)
				end
			end
		end
	end
	fireIf(o, "__signals", "AncestryChanged", o, newParent)
	fireIf(o, "__propSignals", "Parent")
end

local function newInstance(cls, parent)
	Sim.instances = Sim.instances + 1
	local o = setmetatable({
		__inst = true, __class = cls, __props = defaultsFor(cls), __children = {}, __attrs = {}, __tags = {},
		__signals = {}, __propSignals = {}, __attrSignals = {}, __id = Sim.instances,
	}, Inst)
	props(o).Name = cls
	if parent then
		o.Parent = parent
	end
	return o
end

-- generic methods
function methods.IsA(self, cls)
	return isA(className(self), cls)
end
function methods.GetChildren(self)
	return table.move(kids(self), 1, #kids(self), 1, {})
end
function methods.GetDescendants(self)
	local out = {}
	local function walk(n)
		for _, c in ipairs(kids(n)) do
			table.insert(out, c)
			walk(c)
		end
	end
	walk(self)
	return out
end
function methods.FindFirstChild(self, name, recursive)
	for _, c in ipairs(kids(self)) do
		if props(c).Name == name then
			return c
		end
	end
	if recursive then
		for _, c in ipairs(kids(self)) do
			local f = methods.FindFirstChild(c, name, true)
			if f then
				return f
			end
		end
	end
	return nil
end
function methods.FindFirstDescendant(self, name)
	return methods.FindFirstChild(self, name, true)
end
function methods.FindFirstChildOfClass(self, cls)
	for _, c in ipairs(kids(self)) do
		if className(c) == cls then
			return c
		end
	end
	return nil
end
function methods.FindFirstChildWhichIsA(self, cls, recursive)
	for _, c in ipairs(kids(self)) do
		if isA(className(c), cls) then
			return c
		end
	end
	if recursive then
		for _, c in ipairs(kids(self)) do
			local f = methods.FindFirstChildWhichIsA(c, cls, true)
			if f then
				return f
			end
		end
	end
	return nil
end
function methods.FindFirstAncestor(self, name)
	for _, a in ipairs(ancestors(self)) do
		if props(a).Name == name then
			return a
		end
	end
	return nil
end
function methods.FindFirstAncestorOfClass(self, cls)
	for _, a in ipairs(ancestors(self)) do
		if className(a) == cls then
			return a
		end
	end
	return nil
end
function methods.FindFirstAncestorWhichIsA(self, cls)
	for _, a in ipairs(ancestors(self)) do
		if isA(className(a), cls) then
			return a
		end
	end
	return nil
end
function methods.WaitForChild(self, name, timeout)
	local c = methods.FindFirstChild(self, name)
	if c then
		return c
	end
	local t0 = Sim.now
	local limit = timeout or 30
	while Sim.now - t0 < limit do
		task.wait(0.05)
		c = methods.FindFirstChild(self, name)
		if c then
			return c
		end
	end
	if not timeout then
		table.insert(Sim.warnings, "Infinite yield possible on " .. tostring(props(self).Name) .. ":WaitForChild(\"" .. name .. "\")")
	end
	return nil
end
function methods.IsDescendantOf(self, other)
	for _, a in ipairs(ancestors(self)) do
		if a == other then
			return true
		end
	end
	return false
end
function methods.IsAncestorOf(self, other)
	return other ~= nil and methods.IsDescendantOf(other, self)
end
function methods.GetFullName(self)
	local parts = { props(self).Name }
	for _, a in ipairs(ancestors(self)) do
		if a == game then
			break
		end
		table.insert(parts, 1, props(a).Name)
	end
	return table.concat(parts, ".")
end
function methods.Destroy(self)
	if rawget(self, "__destroyed") then
		return
	end
	fireIf(self, "__signals", "Destroying")
	for _, c in ipairs(methods.GetChildren(self)) do
		methods.Destroy(c)
	end
	if props(self).Parent then
		setParent(self, nil)
	end
	rawset(self, "__destroyed", true)
	for tag in pairs(rawget(self, "__tags")) do
		if tagIndex[tag] then
			tagIndex[tag][self] = nil
		end
		if tagRemoved[tag] then
			tagRemoved[tag]:Fire(self)
		end
	end
	for _, s in pairs(rawget(self, "__signals")) do
		s:DisconnectAll()
	end
end
function methods.Remove(self)
	setParent(self, nil)
end
function methods.ClearAllChildren(self)
	for _, c in ipairs(methods.GetChildren(self)) do
		methods.Destroy(c)
	end
end
local ATTR_TYPES = {
	["nil"] = true, boolean = true, number = true, string = true, Vector3 = true, Vector2 = true, Color3 = true, CFrame = true, UDim = true,
	UDim2 = true, NumberRange = true, NumberSequence = true, ColorSequence = true, BrickColor = true, Rect = true, Font = true, EnumItem = true,
}
function methods.SetAttribute(self, k, v)
	if type(k) ~= "string" then
		error("SetAttribute: attribute name must be a string", 2)
	end
	local t = typeof(v)
	if not ATTR_TYPES[t] then
		error("SetAttribute: " .. t .. " is not a supported attribute type (" .. k .. ")", 2)
	end
	if t == "number" and v ~= v then
		error("SetAttribute: NaN for " .. k, 2)
	end
	local attrs = rawget(self, "__attrs")
	if attrs[k] == v then
		return
	end
	attrs[k] = v
	fireIf(self, "__signals", "AttributeChanged", k)
	fireIf(self, "__attrSignals", k)
end
function methods.GetAttribute(self, k)
	return rawget(self, "__attrs")[k]
end
function methods.GetAttributes(self)
	local o = {}
	for k, v in pairs(rawget(self, "__attrs")) do
		o[k] = v
	end
	return o
end
function methods.GetAttributeChangedSignal(self, k)
	return attrSignal(self, k)
end
function methods.GetPropertyChangedSignal(self, k)
	return propSignal(self, k)
end
function methods.AddTag(self, tag)
	if rawget(self, "__tags")[tag] then
		return
	end
	rawget(self, "__tags")[tag] = true
	tagIndex[tag] = tagIndex[tag] or {}
	tagIndex[tag][self] = true
	if tagAdded[tag] then
		tagAdded[tag]:Fire(self)
	end
end
function methods.RemoveTag(self, tag)
	if not rawget(self, "__tags")[tag] then
		return
	end
	rawget(self, "__tags")[tag] = nil
	if tagIndex[tag] then
		tagIndex[tag][self] = nil
	end
	if tagRemoved[tag] then
		tagRemoved[tag]:Fire(self)
	end
end
function methods.HasTag(self, tag)
	return rawget(self, "__tags")[tag] == true
end
function methods.GetTags(self)
	local o = {}
	for t in pairs(rawget(self, "__tags")) do
		table.insert(o, t)
	end
	return o
end
function methods.GetDebugId(self)
	return tostring(rawget(self, "__id"))
end
function methods.GetActor()
	return nil
end

local function cloneTree(o, map)
	if props(o).Archivable == false then
		return nil
	end
	local c = newInstance(className(o))
	map[o] = c
	for k, v in pairs(props(o)) do
		if k ~= "Parent" then
			props(c)[k] = v
		end
	end
	for k, v in pairs(rawget(o, "__attrs")) do
		rawget(c, "__attrs")[k] = v
	end
	for t in pairs(rawget(o, "__tags")) do
		methods.AddTag(c, t)
	end
	for _, ch in ipairs(kids(o)) do
		local cc = cloneTree(ch, map)
		if cc then
			props(cc).Parent = c
			table.insert(kids(c), cc)
		end
	end
	return c
end
function methods.Clone(self)
	local map = {}
	local c = cloneTree(self, map)
	if not c then
		return nil
	end
	for _, nc in pairs(map) do
		for k, v in pairs(props(nc)) do
			if k ~= "Parent" and type(v) == "table" and rawget(v, "__inst") and map[v] then
				props(nc)[k] = map[v]
			end
		end
	end
	return c
end

-- PVInstance
local function partsOf(o)
	local out = {}
	if isA(className(o), "BasePart") then
		table.insert(out, o)
	end
	for _, d in ipairs(methods.GetDescendants(o)) do
		if isA(className(d), "BasePart") then
			table.insert(out, d)
		end
	end
	return out
end
local function bounds(list)
	local mn, mx
	for _, p in ipairs(list) do
		local cf, s = props(p).CFrame, props(p).Size
		local r = cf.r
		local hx = math.abs(r[1]) * s.X / 2 + math.abs(r[2]) * s.Y / 2 + math.abs(r[3]) * s.Z / 2
		local hy = math.abs(r[4]) * s.X / 2 + math.abs(r[5]) * s.Y / 2 + math.abs(r[6]) * s.Z / 2
		local hz = math.abs(r[7]) * s.X / 2 + math.abs(r[8]) * s.Y / 2 + math.abs(r[9]) * s.Z / 2
		local a = Vector3.new(cf.x - hx, cf.y - hy, cf.z - hz)
		local b = Vector3.new(cf.x + hx, cf.y + hy, cf.z + hz)
		mn = mn and mn:Min(a) or a
		mx = mx and mx:Max(b) or b
	end
	return mn, mx
end
function methods.GetPivot(self)
	if isA(className(self), "BasePart") then
		return props(self).CFrame
	end
	local pp = props(self).PrimaryPart
	if pp and not rawget(pp, "__destroyed") then
		return props(pp).CFrame
	end
	if props(self).WorldPivot then
		return props(self).WorldPivot
	end
	local mn, mx = bounds(partsOf(self))
	if not mn then
		return CFrame.new()
	end
	return CFrame.new((mn + mx) / 2)
end
function methods.PivotTo(self, target)
	if isA(className(self), "BasePart") then
		self.CFrame = target
		return
	end
	local delta = target * methods.GetPivot(self):Inverse()
	for _, p in ipairs(partsOf(self)) do
		props(p).CFrame = delta * props(p).CFrame
	end
	if props(self).WorldPivot and not props(self).PrimaryPart then
		props(self).WorldPivot = target
	end
end
function methods.GetBoundingBox(self)
	local mn, mx = bounds(partsOf(self))
	if not mn then
		return methods.GetPivot(self), Vector3.new()
	end
	return CFrame.new((mn + mx) / 2), mx - mn
end
function methods.GetExtentsSize(self)
	local _, s = methods.GetBoundingBox(self)
	return s
end
function methods.GetScale(self)
	return props(self).__scale or 1
end
function methods.ScaleTo(self, s)
	local cur = props(self).__scale or 1
	local k = s / cur
	local pivot = methods.GetPivot(self)
	local inv = pivot:Inverse()
	for _, p in ipairs(partsOf(self)) do
		local rel = inv * props(p).CFrame
		props(p).Size = props(p).Size * k
		props(p).CFrame = pivot * (CFrame.new(rel.x * k, rel.y * k, rel.z * k) * (rel - rel.Position))
	end
	props(self).__scale = s
end
function methods.MoveTo(self, pos)
	if className(self) == "Humanoid" then
		return classMethods.Humanoid.MoveTo(self, pos)
	end
	methods.PivotTo(self, CFrame.new(pos))
end
function methods.SetPrimaryPartCFrame(self, cf)
	methods.PivotTo(self, cf)
end
function methods.GetPrimaryPartCFrame(self)
	return methods.GetPivot(self)
end
function methods.TranslateBy(self, v)
	methods.PivotTo(self, methods.GetPivot(self) + v)
end
function methods.BreakJoints() end
function methods.MakeJoints() end

Inst.__type = "Instance"
Inst.__tostring = function(t)
	return tostring(props(t).Name)
end
Inst.__index = function(t, k)
	local cls = className(t)
	local c = cls
	while c do
		local cm = classMethods[c]
		if cm and cm[k] then
			return cm[k]
		end
		c = PARENT[c]
	end
	if methods[k] then
		return methods[k]
	end
	if EVENTS[k] then
		return eventOf(t, k)
	end
	if k == "ClassName" then
		return cls
	end
	local pr = props(t)
	local v = pr[k]
	if v ~= nil then
		return v
	end
	if k == "Position" and pr.CFrame then
		return pr.CFrame.Position
	elseif k == "Orientation" and pr.CFrame then
		local x, y, z = pr.CFrame:ToOrientation()
		return Vector3.new(math.deg(x), math.deg(y), math.deg(z))
	elseif (k == "WorldCFrame" or k == "WorldPosition") and isA(cls, "Attachment") then
		local parent = pr.Parent
		local cf = (parent and props(parent).CFrame or CFrame.new()) * (pr.CFrame or CFrame.new())
		return k == "WorldCFrame" and cf or cf.Position
	elseif k == "WorldPivot" and isA(cls, "PVInstance") then
		return methods.GetPivot(t)
	elseif k == "RootPart" and cls == "Humanoid" then
		local m = pr.Parent
		return m and methods.FindFirstChild(m, "HumanoidRootPart") or nil
	elseif k == "Archivable" then
		return true
	elseif k == "Terrain" and cls == "Workspace" then
		return methods.FindFirstChild(t, "Terrain")
	end
	local computed = Sim.computed[k]
	if computed then
		local cv = computed(t)
		if cv ~= nil then
			return cv
		end
	end
	local child = methods.FindFirstChild(t, k)
	if child then
		return child
	end
	return nil
end
Inst.__newindex = function(t, k, v)
	local pr = props(t)
	Sim.writes = Sim.writes + 1
	if k == "Parent" then
		setParent(t, v)
		return
	end
	if k == "ClassName" then
		error("ClassName is read-only", 2)
	end
	if k == "Position" and isA(className(t), "BasePart") then
		local cf = pr.CFrame or CFrame.new()
		pr.CFrame = CFrame.new(v) * cf.Rotation
		fireIf(t, "__propSignals", "CFrame")
		fireIf(t, "__propSignals", "Position")
		return
	end
	if k == "Position" and isA(className(t), "Attachment") then
		local cf = pr.CFrame or CFrame.new()
		pr.CFrame = CFrame.new(v) * cf.Rotation
		return
	end
	if k == "Orientation" and isA(className(t), "BasePart") then
		local cf = pr.CFrame or CFrame.new()
		pr.CFrame = CFrame.new(cf.Position) * CFrame.fromOrientation(math.rad(v.X), math.rad(v.Y), math.rad(v.Z))
		return
	end
	if k == "WorldPosition" and isA(className(t), "Attachment") then
		local parent = pr.Parent
		local base = parent and props(parent).CFrame or CFrame.new()
		pr.CFrame = base:Inverse() * CFrame.new(v)
		return
	end
	if k == "PrimaryPart" and v ~= nil and not methods.IsDescendantOf(v, t) then
		table.insert(Sim.warnings, "PrimaryPart of " .. tostring(pr.Name) .. " set to a part that is not its descendant")
	end
	local old = pr[k]
	pr[k] = v
	if old ~= v then
		fireIf(t, "__propSignals", k)
		-- value objects (IntValue, NumberValue...) fire Changed with the new value, and only for Value
		if isA(className(t), "ValueBase") then
			if k == "Value" then
				fireIf(t, "__signals", "Changed", v)
			end
		else
			fireIf(t, "__signals", "Changed", k)
		end
	end
end

Instance = {
	new = function(cls, parent)
		if type(cls) ~= "string" then
			error("Instance.new expects a class name", 2)
		end
		local o = newInstance(cls)
		local init = classMethods[cls] and classMethods[cls].__init
		if init then
			init(o)
		end
		if parent then
			o.Parent = parent
		end
		return o
	end,
	fromExisting = function(o)
		return methods.Clone(o)
	end,
}
Sim.newInstance = newInstance
Sim.PARENT = PARENT
Sim.tagIndex = tagIndex
Sim.DEFAULTS = DEFAULTS
Sim.EVENTS = EVENTS
Sim.isA = isA
Sim.computed = {} -- [property] = function(instance) for values computed on read (GUI layout)
Sim.classMethods = classMethods
Sim.methods = methods
