-- Services, class behaviour, data stores and fake players for the server simulation
-- (loaded after tools/sim/env.lua).
local cm = Sim.classMethods
local methods = Sim.methods
local newInstance = Sim.newInstance

local function props(o)
	return rawget(o, "__props")
end

local function copyArgs(...)
	-- remote arguments are serialized: tables are copied, functions dropped
	local out = { n = select("#", ...) }
	local function copy(v, depth)
		if type(v) == "function" then
			return nil
		end
		if type(v) == "table" and not rawget(v, "__inst") and not getmetatable(v) then
			if depth > 20 then
				return nil
			end
			local o = {}
			for k, x in pairs(v) do
				o[k] = copy(x, depth + 1)
			end
			return o
		end
		return v
	end
	for i = 1, out.n do
		out[i] = copy((select(i, ...)), 0)
	end
	return out
end

------------------------------------------------------------------ class behaviour
cm.Humanoid = {}
function cm.Humanoid.MoveTo(self, pos)
	local model = props(self).Parent
	local root = model and methods.FindFirstChild(model, "HumanoidRootPart")
	props(self).__moveId = (props(self).__moveId or 0) + 1
	local id = props(self).__moveId
	if not root then
		return
	end
	local from = props(root).CFrame.Position
	local flat = Vector3.new(pos.X, from.Y, pos.Z)
	local dist = (flat - from).Magnitude
	local speed = math.max(props(self).WalkSpeed or 16, 0.1)
	local t = dist / speed
	local reached = t <= 8
	if not reached then
		t = 8
	end
	task.delay(t, function()
		if props(self).__moveId ~= id or rawget(self, "__destroyed") then
			return
		end
		local target = reached and flat or from + (flat - from).Unit * speed * 8
		local cur = props(root).CFrame
		model:PivotTo(CFrame.new(target) * cur.Rotation)
		self.MoveToFinished:Fire(reached)
	end)
end
function cm.Humanoid.Move() end
function cm.Humanoid.LoadAnimation(self, anim)
	local track = Instance.new("AnimationTrack")
	props(track).Animation = anim
	return track
end
function cm.Humanoid.SetStateEnabled(self, state, on)
	props(self).__states = props(self).__states or {}
	props(self).__states[state] = on
end
function cm.Humanoid.GetStateEnabled(self, state)
	local s = props(self).__states
	return not s or s[state] ~= false
end
function cm.Humanoid.ChangeState(self, state)
	props(self).__state = state
	self.StateChanged:Fire(Enum.HumanoidStateType.Running, state)
end
function cm.Humanoid.GetState(self)
	return props(self).__state or Enum.HumanoidStateType.Running
end
function cm.Humanoid.TakeDamage(self, n)
	self.Health = math.max(0, (props(self).Health or 100) - n)
end
function cm.Humanoid.ApplyDescription() end
function cm.Humanoid.ApplyDescriptionAsync() end
function cm.Humanoid.GetAppliedDescription()
	return Instance.new("HumanoidDescription")
end
function cm.Humanoid.AddAccessory(self, acc)
	acc.Parent = props(self).Parent
end
function cm.Humanoid.GetAccessories(self)
	local out = {}
	local m = props(self).Parent
	if m then
		for _, c in ipairs(m:GetChildren()) do
			if c.ClassName == "Accessory" then
				table.insert(out, c)
			end
		end
	end
	return out
end
function cm.Humanoid.RemoveAccessories(self)
	for _, a in ipairs(cm.Humanoid.GetAccessories(self)) do
		a:Destroy()
	end
end
function cm.Humanoid.BuildRigFromAttachments() end
function cm.Humanoid.UnequipTools() end
function cm.Humanoid.EquipTool() end
function cm.Humanoid.GetPlayingAnimationTracks()
	return {}
end
cm.Animator = { LoadAnimation = cm.Humanoid.LoadAnimation, GetPlayingAnimationTracks = cm.Humanoid.GetPlayingAnimationTracks }
cm.AnimationController = { LoadAnimation = cm.Humanoid.LoadAnimation }
cm.AnimationTrack = {}
function cm.AnimationTrack.Play(self)
	self.IsPlaying = true
end
function cm.AnimationTrack.Stop(self)
	self.IsPlaying = false
	self.Stopped:Fire()
end
function cm.AnimationTrack.AdjustSpeed(self, s)
	self.Speed = s
end
function cm.AnimationTrack.AdjustWeight() end
function cm.AnimationTrack.GetMarkerReachedSignal(self, name)
	return self.KeyframeReached
end
cm.Seat = {}
function cm.Seat.Sit(self, hum)
	self.Occupant = hum
	hum.SeatPart = self
	hum.Sit = true
end
cm.Sound = {}
function cm.Sound.Play(self)
	self.Playing = true
	self.IsPlaying = true
end
function cm.Sound.Stop(self)
	self.Playing = false
	self.IsPlaying = false
end
cm.Sound.Pause = cm.Sound.Stop
cm.Sound.Resume = cm.Sound.Play
cm.ParticleEmitter = { Emit = function() end, Clear = function() end }
cm.BindableEvent = {}
function cm.BindableEvent.Fire(self, ...)
	self.Event:Fire(...)
end
cm.BindableFunction = {}
function cm.BindableFunction.Invoke(self, ...)
	local f = props(self).OnInvoke
	if not f then
		error("BindableFunction has no OnInvoke", 2)
	end
	return f(...)
end
cm.RemoteEvent = {}
local function record(player, name, args)
	Sim.clientEvents[player] = Sim.clientEvents[player] or {}
	table.insert(Sim.clientEvents[player], { name = name, args = args, t = Sim.now })
	if name == "Notify" then
		table.insert(Sim.notices, { player = player, key = args[1], params = args[2], kind = args[3], t = Sim.now })
		if Sim.verbose then
			print(string.format("[sim %7.1f] notify %s: %s (%s)", Sim.now, tostring(player.Name), tostring(args[1]), tostring(args[3])))
		end
	end
end
function cm.RemoteEvent.FireClient(self, player, ...)
	if type(player) ~= "table" or player.ClassName ~= "Player" then
		error("FireClient: player argument must be a Player", 2)
	end
	record(player, props(self).Name, copyArgs(...))
end
function cm.RemoteEvent.FireAllClients(self, ...)
	local args = copyArgs(...)
	for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
		record(p, props(self).Name, args)
	end
end
cm.UnreliableRemoteEvent = cm.RemoteEvent
cm.RemoteFunction = {}
function cm.RemoteFunction.InvokeClient()
	error("InvokeClient is not simulated")
end
cm.TeleportOptions = {}
function cm.TeleportOptions.SetTeleportData(self, d)
	props(self).__data = d
end
function cm.TeleportOptions.GetTeleportData(self)
	return props(self).__data
end
cm.Path = {}
function cm.Path.ComputeAsync(self, a, b)
	task.wait(0.01)
	props(self).__a, props(self).__b = a, b
	self.Status = Enum.PathStatus.Success
end
function cm.Path.GetWaypoints(self)
	local a, b = props(self).__a, props(self).__b
	if not a then
		return {}
	end
	local function wp(p)
		return setmetatable({ Position = p, Action = Enum.PathWaypointAction.Walk, Label = "" }, { __type = "PathWaypoint" })
	end
	return { wp(a), wp((a + b) / 2), wp(b) }
end
function cm.Path.CheckOcclusionAsync()
	return -1
end
cm.Tween = {}
function cm.Tween.Play(self)
	local info = props(self).__info
	local goals = props(self).__goals
	local target = props(self).__target
	local id = (props(self).__run or 0) + 1
	props(self).__run = id
	self.PlaybackState = Enum.PlaybackState.Playing
	local infinite = info and info.RepeatCount and info.RepeatCount < 0
	task.delay(infinite and 0 or ((info and info.Time or 1) + (info and info.DelayTime or 0)), function()
		if props(self).__run ~= id or rawget(target, "__destroyed") then
			return
		end
		for k, v in pairs(goals or {}) do
			target[k] = v
		end
		if not infinite then
			self.PlaybackState = Enum.PlaybackState.Completed
			self.Completed:Fire(Enum.PlaybackState.Completed)
		end
	end)
end
function cm.Tween.Cancel(self)
	props(self).__run = (props(self).__run or 0) + 1
	self.PlaybackState = Enum.PlaybackState.Cancelled
end
cm.Tween.Pause = cm.Tween.Cancel

cm.Player = {}
function cm.Player.Kick(self, msg)
	Sim.kicked = Sim.kicked or {}
	table.insert(Sim.kicked, { player = self, msg = msg })
	print("[sim] kicked " .. tostring(self.Name) .. ": " .. tostring(msg))
	Sim.removePlayer(self)
end
function cm.Player.GetJoinData(self)
	return props(self).__joinData or {}
end
function cm.Player.IsFriendsWith(self, other)
	return Sim.friends[self.UserId .. ":" .. tostring(other)] == true or Sim.friends[tostring(other) .. ":" .. self.UserId] == true
end
function cm.Player.GetRankInGroup()
	return 0
end
function cm.Player.IsInGroup()
	return false
end
function cm.Player.GetFriendsOnline()
	return {}
end
function cm.Player.DistanceFromCharacter(self, p)
	local c = props(self).Character
	local root = c and methods.FindFirstChild(c, "HumanoidRootPart")
	return root and (root.Position - p).Magnitude or 0
end
function cm.Player.LoadCharacter(self)
	local old = props(self).Character
	if old then
		self.CharacterRemoving:Fire(old)
		old:Destroy()
	end
	local char = Sim.rig(self.Name)
	local spawnCf = Sim.spawnCFrame or CFrame.new(0, 3, -30)
	char:PivotTo(spawnCf)
	self.Character = char
	char.Parent = workspace
	self.CharacterAdded:Fire(char)
	return char
end
function cm.Player.RequestStreamAroundAsync() end
function cm.Player.SetAttribute(self, k, v)
	return methods.SetAttribute(self, k, v)
end

-- a simple R15-like rig
function Sim.rig(name)
	local m = newInstance("Model")
	m.Name = name or "Rig"
	local function part(n, size, offset)
		local p = newInstance("Part")
		p.Name = n
		p.Size = size
		p.CFrame = CFrame.new(offset)
		p.Parent = m
		return p
	end
	local root = part("HumanoidRootPart", Vector3.new(2, 2, 1), Vector3.new(0, 0, 0))
	root.Transparency = 1
	local head = part("Head", Vector3.new(1.2, 1.2, 1.2), Vector3.new(0, 1.6, 0))
	local att = newInstance("Attachment")
	att.Name = "FaceFrontAttachment"
	att.Parent = head
	local hat = newInstance("Attachment")
	hat.Name = "HatAttachment"
	hat.Parent = head
	local hair = newInstance("Attachment")
	hair.Name = "HairAttachment"
	hair.Parent = head
	local face = newInstance("Decal")
	face.Name = "face"
	face.Parent = head
	local ut = part("UpperTorso", Vector3.new(2, 1.6, 1), Vector3.new(0, 0.4, 0))
	for _, n in ipairs({ "BodyFrontAttachment", "BodyBackAttachment", "NeckAttachment", "WaistRigAttachment", "LeftCollarAttachment", "RightCollarAttachment" }) do
		local a = newInstance("Attachment")
		a.Name = n
		a.Parent = ut
	end
	local lt = part("LowerTorso", Vector3.new(2, 0.4, 1), Vector3.new(0, -0.6, 0))
	local wa = newInstance("Attachment")
	wa.Name = "WaistFrontAttachment"
	wa.Parent = lt
	for _, side in ipairs({ "Left", "Right" }) do
		local x = side == "Left" and -1.5 or 1.5
		part(side .. "UpperArm", Vector3.new(1, 1.2, 1), Vector3.new(x, 0.5, 0))
		part(side .. "LowerArm", Vector3.new(1, 1.1, 1), Vector3.new(x, -0.4, 0))
		local hand = part(side .. "Hand", Vector3.new(1, 0.4, 1), Vector3.new(x, -1.1, 0))
		local g = newInstance("Attachment")
		g.Name = side .. "GripAttachment"
		g.Parent = hand
		local lx = side == "Left" and -0.5 or 0.5
		part(side .. "UpperLeg", Vector3.new(1, 1.2, 1), Vector3.new(lx, -1.4, 0))
		part(side .. "LowerLeg", Vector3.new(1, 1.2, 1), Vector3.new(lx, -2.4, 0))
		part(side .. "Foot", Vector3.new(1, 0.4, 1), Vector3.new(lx, -3.1, 0))
	end
	local hum = newInstance("Humanoid")
	hum.Parent = m
	local animator = newInstance("Animator")
	animator.Parent = hum
	m.PrimaryPart = root
	return m
end

------------------------------------------------------------------ JSON
local function encode(v, out, seen)
	local t = type(v)
	if v == nil then
		table.insert(out, "null")
	elseif t == "boolean" then
		table.insert(out, tostring(v))
	elseif t == "number" then
		if v ~= v or v == math.huge or v == -math.huge then
			table.insert(out, "null")
		elseif math.type(v) == "integer" or (v == math.floor(v) and math.abs(v) < 1e15) then
			table.insert(out, string.format("%d", v))
		else
			table.insert(out, string.format("%.14g", v))
		end
	elseif t == "string" then
		table.insert(out, '"' .. v:gsub('[%c"\\]', function(c)
			local map = { ['"'] = '\\"', ["\\"] = "\\\\", ["\n"] = "\\n", ["\r"] = "\\r", ["\t"] = "\\t" }
			return map[c] or string.format("\\u%04x", c:byte())
		end) .. '"')
	elseif t == "table" then
		if seen[v] then
			error("JSONEncode: cyclic table")
		end
		seen[v] = true
		local n = #v
		local isArray = n > 0 or next(v) == nil
		if isArray then
			for k in pairs(v) do
				if type(k) ~= "number" then
					isArray = false
					break
				end
			end
		end
		if isArray then
			table.insert(out, "[")
			for i = 1, n do
				if i > 1 then
					table.insert(out, ",")
				end
				encode(v[i], out, seen)
			end
			table.insert(out, "]")
		else
			table.insert(out, "{")
			local first = true
			for k, x in pairs(v) do
				if type(x) ~= "function" then
					if not first then
						table.insert(out, ",")
					end
					first = false
					encode(tostring(k), out, seen)
					table.insert(out, ":")
					encode(x, out, seen)
				end
			end
			table.insert(out, "}")
		end
		seen[v] = nil
	else
		error("JSONEncode: cannot encode " .. typeof(v))
	end
end
local function decode(s)
	local i = 1
	local function ws()
		i = s:find("[^ \t\r\n]", i) or #s + 1
	end
	local value
	local function str()
		i = i + 1
		local out = {}
		while true do
			local c = s:sub(i, i)
			if c == '"' then
				i = i + 1
				break
			elseif c == "\\" then
				local e = s:sub(i + 1, i + 1)
				local map = { n = "\n", r = "\r", t = "\t", b = "\b", f = "\f", ['"'] = '"', ["\\"] = "\\", ["/"] = "/" }
				if e == "u" then
					table.insert(out, utf8.char(tonumber(s:sub(i + 2, i + 5), 16)))
					i = i + 6
				else
					table.insert(out, map[e] or e)
					i = i + 2
				end
			elseif c == "" then
				error("JSONDecode: unterminated string")
			else
				table.insert(out, c)
				i = i + 1
			end
		end
		return table.concat(out)
	end
	function value()
		ws()
		local c = s:sub(i, i)
		if c == "{" then
			i = i + 1
			local o = {}
			ws()
			if s:sub(i, i) == "}" then
				i = i + 1
				return o
			end
			while true do
				ws()
				local k = str()
				ws()
				i = i + 1 -- :
				o[k] = value()
				ws()
				local d = s:sub(i, i)
				i = i + 1
				if d == "}" then
					return o
				end
			end
		elseif c == "[" then
			i = i + 1
			local o = {}
			ws()
			if s:sub(i, i) == "]" then
				i = i + 1
				return o
			end
			while true do
				table.insert(o, value())
				ws()
				local d = s:sub(i, i)
				i = i + 1
				if d == "]" then
					return o
				end
			end
		elseif c == '"' then
			return str()
		elseif s:sub(i, i + 3) == "true" then
			i = i + 4
			return true
		elseif s:sub(i, i + 4) == "false" then
			i = i + 5
			return false
		elseif s:sub(i, i + 3) == "null" then
			i = i + 4
			return nil
		else
			local num = s:match("^-?%d+%.?%d*[eE]?[-+]?%d*", i)
			if not num or num == "" then
				error("JSONDecode: unexpected '" .. c .. "' at " .. i)
			end
			i = i + #num
			return tonumber(num)
		end
	end
	return value()
end
Sim.json = { encode = function(v)
	local out = {}
	encode(v, out, {})
	return table.concat(out)
end, decode = decode }

------------------------------------------------------------------ data stores (in memory, checked)
-- Values must survive the trip to Roblox's JSON storage: only strings, numbers, booleans and tables
-- that are either arrays (1..n with no holes) or dictionaries with string keys.
local function checkStorable(v, path, depth)
	local t = type(v)
	if t == "number" then
		if v ~= v or v == math.huge or v == -math.huge then
			error("cannot store NaN/inf at " .. path)
		end
	elseif t == "string" or t == "boolean" or t == "nil" then
		return
	elseif t == "table" then
		if rawget(v, "__inst") or getmetatable(v) then
			error("cannot store " .. typeof(v) .. " at " .. path)
		end
		if depth > 60 then
			error("table too deep at " .. path)
		end
		local nums, strs, maxn = 0, 0, 0
		for k, x in pairs(v) do
			if type(k) == "number" then
				nums = nums + 1
				if k ~= math.floor(k) or k < 1 then
					error("non-integer or non-positive array index " .. tostring(k) .. " at " .. path)
				end
				maxn = math.max(maxn, k)
			elseif type(k) == "string" then
				strs = strs + 1
			else
				error("key of type " .. type(k) .. " at " .. path)
			end
			checkStorable(x, path .. "." .. tostring(k), depth + 1)
		end
		if nums > 0 and strs > 0 then
			error("mixed table (number and string keys) at " .. path)
		end
		if nums > 0 and maxn ~= nums then
			error("array with holes at " .. path .. " (" .. nums .. " items, highest index " .. maxn .. ")")
		end
	else
		error("cannot store " .. t .. " at " .. path)
	end
end
Sim.checkStorable = checkStorable

local function deep(v)
	if type(v) ~= "table" then
		return v
	end
	local o = {}
	for k, x in pairs(v) do
		o[k] = deep(x)
	end
	return o
end
Sim.deep = deep

local stores = {}
Sim.stores = stores
local function dsCall(method)
	task.wait(Sim.dsLatency)
	local n = Sim.dsFail[method] or Sim.dsFail.any
	if n and n > 0 then
		if Sim.dsFail[method] then
			Sim.dsFail[method] = n - 1
		else
			Sim.dsFail.any = n - 1
		end
		error("502: API Services rejected request (simulated failure of " .. method .. ")", 3)
	end
end
local function makeStore(kind, name)
	local key = kind .. ":" .. name
	if stores[key] then
		return stores[key]
	end
	local s = { __data = {}, __name = name, __kind = kind, writes = 0 }
	function s:GetAsync(k)
		dsCall("GetAsync")
		return deep(self.__data[k])
	end
	function s:SetAsync(k, v)
		dsCall("SetAsync")
		checkStorable(v, name .. "/" .. tostring(k), 0)
		self.__data[k] = deep(v)
		self.writes = self.writes + 1
	end
	function s:UpdateAsync(k, fn)
		dsCall("UpdateAsync")
		local old = deep(self.__data[k])
		local new = fn(old, nil)
		if new == nil then
			return nil
		end
		checkStorable(new, name .. "/" .. tostring(k), 0)
		self.__data[k] = deep(new)
		self.writes = self.writes + 1
		return deep(new), nil
	end
	function s:RemoveAsync(k)
		dsCall("RemoveAsync")
		local old = self.__data[k]
		self.__data[k] = nil
		return old
	end
	function s:IncrementAsync(k, d)
		dsCall("IncrementAsync")
		self.__data[k] = (self.__data[k] or 0) + (d or 1)
		return self.__data[k]
	end
	function s:GetSortedAsync(ascending, pageSize)
		dsCall("GetSortedAsync")
		local list = {}
		for k, v in pairs(self.__data) do
			table.insert(list, { key = k, value = v })
		end
		table.sort(list, function(a, b)
			if ascending then
				return a.value < b.value
			end
			return a.value > b.value
		end)
		local page = {}
		for i = 1, math.min(pageSize or 50, #list) do
			page[i] = list[i]
		end
		return { IsFinished = true, GetCurrentPage = function()
			return page
		end, AdvanceToNextPageAsync = function() end }
	end
	-- memory store sorted map flavour
	function s:GetRangeAsync(_, count)
		dsCall("GetRangeAsync")
		local list = {}
		for k, v in pairs(self.__data) do
			table.insert(list, { key = k, value = v })
		end
		return list
	end
	stores[key] = s
	return s
end
Sim.store = makeStore

------------------------------------------------------------------ services
local services = {}
local SERVICE_CLASS = { Workspace = "Workspace" }

cm.DataModel = {}
function cm.DataModel.GetService(self, name)
	local s = services[name]
	if s then
		return s
	end
	s = newInstance(SERVICE_CLASS[name] or name)
	props(s).Name = name
	services[name] = s
	s.Parent = self
	local init = cm[name] and cm[name].__service
	if init then
		init(s)
	end
	return s
end
cm.DataModel.FindService = cm.DataModel.GetService
function cm.DataModel.IsLoaded()
	return true
end
function cm.DataModel.BindToClose(self, fn)
	Sim.closeHandlers = Sim.closeHandlers or {}
	table.insert(Sim.closeHandlers, fn)
end

cm.Players = {}
function cm.Players.GetPlayers(self)
	local out = {}
	for _, c in ipairs(self:GetChildren()) do
		if c.ClassName == "Player" then
			table.insert(out, c)
		end
	end
	return out
end
function cm.Players.GetPlayerByUserId(self, id)
	for _, p in ipairs(cm.Players.GetPlayers(self)) do
		if p.UserId == id then
			return p
		end
	end
	return nil
end
function cm.Players.GetPlayerFromCharacter(self, char)
	for _, p in ipairs(cm.Players.GetPlayers(self)) do
		if p.Character == char then
			return p
		end
	end
	return nil
end
function cm.Players.CreateHumanoidModelFromDescription(self, desc)
	task.wait(0.01)
	return Sim.rig("NPC")
end
cm.Players.CreateHumanoidModelFromDescriptionAsync = cm.Players.CreateHumanoidModelFromDescription
function cm.Players.GetNameFromUserIdAsync(self, id)
	return "User" .. tostring(id)
end
function cm.Players.GetUserThumbnailAsync()
	return "rbxthumb://", true
end
function cm.Players.GetHumanoidDescriptionFromUserId()
	return Instance.new("HumanoidDescription")
end

cm.RunService = {}
function cm.RunService.IsServer()
	return true
end
function cm.RunService.IsClient()
	return false
end
function cm.RunService.IsStudio()
	return Sim.studio
end
function cm.RunService.IsRunning()
	return true
end
function cm.RunService.BindToRenderStep() end
function cm.RunService.UnbindFromRenderStep() end

local tagAddedSignals, tagRemovedSignals = {}, {}
cm.CollectionService = {}
function cm.CollectionService.AddTag(_, inst, tag)
	methods.AddTag(inst, tag)
end
function cm.CollectionService.RemoveTag(_, inst, tag)
	methods.RemoveTag(inst, tag)
end
function cm.CollectionService.HasTag(_, inst, tag)
	return methods.HasTag(inst, tag)
end
function cm.CollectionService.GetTags(_, inst)
	return methods.GetTags(inst)
end
function cm.CollectionService.GetTagged(_, tag)
	local out = {}
	for inst in pairs(Sim.tagIndex[tag] or {}) do
		if not rawget(inst, "__destroyed") and Sim.inGame(inst) then
			table.insert(out, inst)
		end
	end
	table.sort(out, function(a, b)
		return rawget(a, "__id") < rawget(b, "__id")
	end)
	return out
end
function cm.CollectionService.GetInstanceAddedSignal(_, tag)
	tagAddedSignals[tag] = tagAddedSignals[tag] or Sim.signal("tag+" .. tag)
	return tagAddedSignals[tag]
end
function cm.CollectionService.GetInstanceRemovedSignal(_, tag)
	tagRemovedSignals[tag] = tagRemovedSignals[tag] or Sim.signal("tag-" .. tag)
	return tagRemovedSignals[tag]
end

cm.DataStoreService = {}
function cm.DataStoreService.GetDataStore(_, name, scope)
	return makeStore("ds", name .. (scope and ("/" .. scope) or ""))
end
function cm.DataStoreService.GetOrderedDataStore(_, name, scope)
	return makeStore("ods", name .. (scope and ("/" .. scope) or ""))
end
function cm.DataStoreService.GetGlobalDataStore()
	return makeStore("ds", "global")
end
function cm.DataStoreService.GetRequestBudgetForRequestType()
	return 100
end
cm.MemoryStoreService = {}
function cm.MemoryStoreService.GetSortedMap(_, name)
	local s = makeStore("ms", name)
	local set = s.SetAsync
	function s:SetAsync(k, v)
		set(self, k, v)
		return true
	end
	return s
end
function cm.MemoryStoreService.GetQueue(_, name)
	return makeStore("mq", name)
end

cm.HttpService = {}
function cm.HttpService.JSONEncode(_, v)
	return Sim.json.encode(v)
end
function cm.HttpService.JSONDecode(_, s)
	if type(s) ~= "string" then
		error("JSONDecode expects a string", 2)
	end
	return Sim.json.decode(s)
end
local guid = 0
function cm.HttpService.GenerateGUID(_, wrap)
	guid = guid + 1
	local g = string.format("%08X-0000-4000-8000-%012X", guid, guid)
	return wrap == false and g or ("{" .. g .. "}")
end
function cm.HttpService.UrlEncode(_, s)
	return s
end

cm.TweenService = {}
function cm.TweenService.Create(_, inst, info, goals)
	if type(inst) ~= "table" or not rawget(inst, "__inst") then
		error("TweenService:Create expects an Instance", 2)
	end
	local tw = Instance.new("Tween")
	props(tw).__info = info
	props(tw).__goals = goals
	props(tw).__target = inst
	return tw
end
function cm.TweenService.GetValue(_, a)
	return a
end

cm.PathfindingService = {}
function cm.PathfindingService.CreatePath()
	return Instance.new("Path")
end

cm.PhysicsService = {}
function cm.PhysicsService.RegisterCollisionGroup() end
function cm.PhysicsService.CollisionGroupSetCollidable() end
function cm.PhysicsService.CollisionGroupsAreCollidable()
	return true
end
function cm.PhysicsService.GetRegisteredCollisionGroups()
	return {}
end
function cm.PhysicsService.IsCollisionGroupRegistered()
	return true
end

cm.TeleportService = {}
local reserved = 0
function cm.TeleportService.ReserveServer()
	reserved = reserved + 1
	return "ACCESS_" .. reserved, "PS_" .. reserved
end
cm.TeleportService.ReserveServerAsync = cm.TeleportService.ReserveServer
function cm.TeleportService.TeleportAsync(_, placeId, list)
	Sim.teleports = Sim.teleports or {}
	table.insert(Sim.teleports, { placeId = placeId, players = list })
end
function cm.TeleportService.SetTeleportGui() end

cm.MarketplaceService = {}
function cm.MarketplaceService.UserOwnsGamePassAsync(_, userId, id)
	return Sim.passes ~= nil and Sim.passes[userId .. ":" .. id] == true
end
function cm.MarketplaceService.PromptGamePassPurchase() end
function cm.MarketplaceService.PromptProductPurchase() end
function cm.MarketplaceService.GetProductInfo(_, id)
	return { Name = "Product " .. tostring(id), PriceInRobux = 10 }
end

cm.Debris = {}
function cm.Debris.AddItem(_, inst, t)
	task.delay(t or 10, function()
		if not rawget(inst, "__destroyed") then
			inst:Destroy()
		end
	end)
end

cm.AnalyticsService = {}
local function logAnalytics(kind, ...)
	table.insert(Sim.analytics, { kind = kind, args = { ... }, t = Sim.now })
end
function cm.AnalyticsService.LogOnboardingFunnelStepEvent(_, player, step, name, fields)
	if type(player) ~= "table" or player.ClassName ~= "Player" then
		error("LogOnboardingFunnelStepEvent: player must be a Player", 2)
	end
	if type(step) ~= "number" or step < 1 or step % 1 ~= 0 then
		error("LogOnboardingFunnelStepEvent: step must be an integer >= 1", 2)
	end
	logAnalytics("onboarding", player, step, name, fields)
end
function cm.AnalyticsService.LogFunnelStepEvent(_, player, funnel, session, step, name, fields)
	logAnalytics("funnel", player, funnel, session, step, name, fields)
end
function cm.AnalyticsService.LogEconomyEvent(_, player, flow, currency, amount, ending, txType, sku, fields)
	if type(player) ~= "table" or player.ClassName ~= "Player" then
		error("LogEconomyEvent: player must be a Player", 2)
	end
	if typeof(flow) ~= "EnumItem" or flow.EnumType ~= "AnalyticsEconomyFlowType" then
		error("LogEconomyEvent: flowType must be an AnalyticsEconomyFlowType", 2)
	end
	if type(amount) ~= "number" or amount <= 0 or type(ending) ~= "number" or type(txType) ~= "string" then
		error("LogEconomyEvent: bad amount, balance or transaction type", 2)
	end
	logAnalytics("economy", player, flow.Name, currency, amount, ending, txType, sku, fields)
end
function cm.AnalyticsService.LogProgressionEvent(_, player, path, status, level, name, fields)
	logAnalytics("progression", player, path, status, level, name, fields)
end
function cm.AnalyticsService.LogCustomEvent(_, player, name, value, fields)
	if type(name) ~= "string" then
		error("LogCustomEvent: name must be a string", 2)
	end
	logAnalytics("custom", player, name, value, fields)
end

cm.Lighting = {}
function cm.Lighting.GetMinutesAfterMidnight(self)
	return (self.ClockTime or 14) * 60
end
function cm.Lighting.SetMinutesAfterMidnight(self, m)
	self.ClockTime = (m / 60) % 24
end

cm.Workspace = {}
function cm.Workspace.GetServerTimeNow()
	return Sim.epoch + Sim.now
end
function cm.Workspace.Raycast()
	return nil
end
function cm.Workspace.GetPartBoundsInBox()
	return {}
end
function cm.Workspace.GetPartBoundsInRadius()
	return {}
end
function cm.Workspace.GetPartsInPart()
	return {}
end
function cm.Workspace.FindPartOnRay()
	return nil
end

cm.SocialService = {}
function cm.SocialService.CanSendGameInviteAsync()
	return true
end
function cm.SocialService.PromptGameInvite() end
cm.TextChatService = {}
cm.BadgeService = {}
function cm.BadgeService.UserHasBadgeAsync()
	return false
end
function cm.BadgeService.AwardBadge()
	return true
end
cm.PolicyService = {}
function cm.PolicyService.GetPolicyInfoForPlayerAsync()
	return { AreAdsAllowed = true, ArePaidRandomItemsRestricted = false, AllowedExternalLinkReferences = {} }
end
cm.LocalizationService = {}
function cm.LocalizationService.GetCountryRegionForPlayerAsync()
	return "IT"
end
cm.GroupService = {}
cm.ServerStorage = {}
cm.ServerScriptService = {}
cm.ReplicatedStorage = {}
cm.ReplicatedFirst = {}
cm.StarterPlayer = {}
cm.StarterGui = {}
cm.SoundService = {}
cm.ProximityPromptService = {}
cm.ContentProvider = {}
function cm.ContentProvider.PreloadAsync() end

------------------------------------------------------------------ the data model
game = newInstance("DataModel")
props(game).Name = "Game"
props(game).JobId = "sim-job-1"
props(game).PlaceId = 4242
props(game).GameId = 4243
props(game).PlaceVersion = 1
props(game).PrivateServerId = ""
props(game).PrivateServerOwnerId = 0
props(game).CreatorId = 1
props(game).CreatorType = Enum.CreatorType.User
workspace = game:GetService("Workspace")
Workspace = workspace
local terrain = newInstance("Terrain")
terrain.Name = "Terrain"
terrain.Anchored = true
terrain.Parent = workspace
game:GetService("Players")
game:GetService("Lighting")
local rs = game:GetService("RunService")

-- the heartbeat drives RunService signals every frame
local function beat()
	rs.Stepped:Fire(Sim.now, Sim.frame)
	rs.Heartbeat:Fire(Sim.frame)
	rs.PostSimulation:Fire(Sim.frame)
	Sim.schedule(Sim.now + Sim.frame, nil, nil, beat)
end
Sim.schedule(0, nil, nil, beat)

------------------------------------------------------------------ fake players and remotes
local nextUser = 100
function Sim.addPlayer(opts)
	opts = opts or {}
	nextUser = nextUser + 1
	local p = newInstance("Player")
	props(p).UserId = opts.userId or nextUser
	props(p).Name = opts.name or ("Player" .. props(p).UserId)
	props(p).DisplayName = opts.displayName or props(p).Name
	props(p).LocaleId = opts.locale or "it-it"
	props(p).__joinData = opts.joinData
	props(p).FollowUserId = opts.follow or 0
	p.Parent = game:GetService("Players")
	game:GetService("Players").PlayerAdded:Fire(p)
	task.delay(0.3, function()
		if p.Parent then
			p:LoadCharacter()
		end
	end)
	return p
end

function Sim.removePlayer(p)
	if not p.Parent then
		return
	end
	local players = game:GetService("Players")
	players.PlayerRemoving:Fire(p)
	local char = p.Character
	if char then
		p.CharacterRemoving:Fire(char)
		char:Destroy()
	end
	task.defer(function()
		if p.Parent then
			p.Parent = nil
		end
	end)
end

local function remote(name)
	local folder = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
	local r = folder and folder:FindFirstChild(name)
	if not r then
		error("no remote " .. name, 3)
	end
	return r
end
function Sim.fire(player, name, ...)
	remote(name).OnServerEvent:Fire(player, table.unpack(copyArgs(...), 1, select("#", ...)))
end
function Sim.invoke(player, name, ...)
	local r = remote(name)
	local f = props(r).OnServerInvoke
	if not f then
		error("no OnServerInvoke for " .. name, 2)
	end
	return f(player, table.unpack(copyArgs(...), 1, select("#", ...)))
end

function Sim.close()
	local players = game:GetService("Players")
	local pending = 0
	for _, fn in ipairs(Sim.closeHandlers or {}) do
		pending = pending + 1
		task.spawn(function()
			fn()
			pending = pending - 1
		end)
	end
	for _, p in ipairs(players:GetPlayers()) do
		Sim.removePlayer(p)
	end
	local t0 = Sim.now
	while pending > 0 and Sim.now - t0 < 30 do
		task.wait(0.1)
	end
	return pending == 0
end

-- notifications sent to a player (keys), newest last
function Sim.noticesFor(player)
	local out = {}
	for _, n in ipairs(Sim.notices) do
		if n.player == player then
			table.insert(out, n.key)
		end
	end
	return out
end

function Sim.eventsFor(player, name)
	local out = {}
	for _, e in ipairs(Sim.clientEvents[player] or {}) do
		if e.name == name then
			table.insert(out, e.args)
		end
	end
	return out
end
