-- Mounts the project scripts as instances (like Rojo), defines require, captures print/warn and
-- gives scenarios their helpers. Run by tools/sim.py after env.lua and services.lua.
local rawPrint = print
local function props(o)
	return rawget(o, "__props")
end

Sim.checks = 0
Sim.allowed = {} -- warn patterns a scenario expects (e.g. a simulated data store failure)

function Sim.fail(msg)
	table.insert(Sim.errors, msg)
	rawPrint(string.format("[%8.1f] ERROR %s", Sim.now, msg))
end

local function joinArgs(...)
	local parts = {}
	for i = 1, select("#", ...) do
		parts[#parts + 1] = tostring((select(i, ...)))
	end
	return table.concat(parts, " ")
end

function print(...)
	local s = joinArgs(...)
	table.insert(Sim.logs, s)
	if Sim.verbose then
		rawPrint(string.format("[%8.1f] %s", Sim.now, s))
	end
end

function warn(...)
	local s = joinArgs(...)
	table.insert(Sim.logs, "WARN " .. s)
	for _, pat in ipairs(Sim.allowed) do
		if s:find(pat, 1, true) then
			if Sim.verbose then
				rawPrint(string.format("[%8.1f] WARN (expected) %s", Sim.now, s))
			end
			return
		end
	end
	rawPrint(string.format("[%8.1f] WARN %s", Sim.now, s))
	local low = s:lower()
	if low:find("fail") or low:find("error") or low:find("attempt to") or low:find("missing service") then
		Sim.fail("warning: " .. s)
	end
end

function Sim.allow(pattern)
	table.insert(Sim.allowed, pattern)
end

------------------------------------------------------------------ project tree
local function child(parent, name, cls)
	local c = parent:FindFirstChild(name)
	if not c then
		c = Instance.new(cls or "Folder")
		c.Name = name
		c.Parent = parent
	end
	return c
end

local function nodeAt(path)
	local parts = {}
	for p in path:gmatch("[^/]+") do
		table.insert(parts, p)
	end
	local node = game:GetService(parts[1])
	for i = 2, #parts do
		node = child(node, parts[i])
	end
	return node
end

local function relPath(full)
	return full:match("(src/.*)$") or full
end

for _, e in ipairs(__entries) do
	local instPath, kind, file = e[1], e[2], e[3]
	local node = nodeAt(instPath)
	rawset(node, "__class", kind)
	props(node).__src = file
end
child(game:GetService("ReplicatedStorage"), "AssetOverrides")

------------------------------------------------------------------ require
local cache, loading = {}, {}
function require(m)
	if type(m) ~= "table" or not rawget(m, "__inst") then
		error("require expects a ModuleScript, got " .. typeof(m), 2)
	end
	if cache[m] ~= nil then
		return cache[m]
	end
	local src = props(m).__src
	if not src or m.ClassName ~= "ModuleScript" then
		error("Attempted to require a non-ModuleScript " .. m:GetFullName(), 2)
	end
	if loading[m] then
		error("Requested module was required recursively: " .. m:GetFullName(), 2)
	end
	loading[m] = true
	local env = setmetatable({ script = m }, { __index = _G })
	local chunk, err = load(__read(src), "@" .. relPath(src), "t", env)
	if not chunk then
		loading[m] = nil
		error(err, 0)
	end
	local ok, result = pcall(chunk)
	loading[m] = nil
	if not ok then
		error("Requested module experienced an error while loading: " .. tostring(result), 0)
	end
	if result == nil then
		error("Module code did not return exactly one value: " .. m:GetFullName(), 0)
	end
	cache[m] = result
	return result
end

local function runScript(inst)
	local env = setmetatable({ script = inst }, { __index = _G })
	local chunk, err = load(__read(props(inst).__src), "@" .. relPath(props(inst).__src), "t", env)
	if not chunk then
		Sim.fail("syntax: " .. tostring(err))
		return
	end
	Sim.resume(coroutine.create(chunk))
end

function Sim.startServer()
	local server = game:GetService("ServerScriptService"):FindFirstChild("Server")
	runScript(server:FindFirstChild("Main"))
end

function Sim.core()
	return require(game:GetService("ServerScriptService").Server.Core)
end

function Sim.shared(path)
	local node = game:GetService("ReplicatedStorage").Shared
	for p in path:gmatch("[^/.]+") do
		node = node:FindFirstChild(p)
	end
	return require(node)
end

------------------------------------------------------------------ scenario helpers
function Sim.check(name, cond, detail)
	Sim.checks = Sim.checks + 1
	if not cond then
		Sim.fail("check failed: " .. name .. (detail and (" (" .. tostring(detail) .. ")") or ""))
		return false
	end
	if Sim.verbose then
		rawPrint(string.format("[%8.1f] ok   %s", Sim.now, name))
	end
	return true
end

function Sim.waitFor(fn, timeout)
	local t0 = Sim.now
	while Sim.now - t0 < (timeout or 30) do
		local v = fn()
		if v then
			return v
		end
		task.wait(0.25)
	end
	return nil
end

function Sim.say(...)
	rawPrint(string.format("[%8.1f] %s", Sim.now, joinArgs(...)))
end

function Sim.runScenario(src, chunkname, maxTime)
	local env = setmetatable({}, { __index = _G })
	local chunk, err = load(src, chunkname, "t", env)
	if not chunk then
		Sim.fail("scenario syntax: " .. tostring(err))
		return false
	end
	local done, result = false, false
	Sim.resume(coroutine.create(function()
		local ok, e = pcall(chunk)
		if not ok then
			Sim.fail("scenario stopped: " .. tostring(e))
		end
		result = ok
		done = true
	end))
	while not done and Sim.now < maxTime do
		Sim.step(Sim.now + 1)
	end
	if not done then
		Sim.fail("scenario did not finish in " .. maxTime .. " simulated seconds")
	end
	return done and result
end
