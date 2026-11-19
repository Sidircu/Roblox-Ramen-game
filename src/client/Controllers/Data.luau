--!nonstrict
-- Local copy of the player's profile ("me"), the data of the restaurant you work in when it is
-- not yours ("world"), session info (plot, role, plot origins), day state and tickets.
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local NetDef = require(Shared.Net)
local Signal = require(Shared.Util.Signal)
local Locale = require(Shared.Locale)
local PlotsCfg = require(Shared.Config.Plots)

local Data = {}
Data.me = nil
Data.world = nil
Data.session = { role = "visitor", plot = nil, home = nil, originX = 0, homeX = 0, plots = {} }
Data.day = { phase = "prep", clock = 9.5, day = 1 }
Data.tickets = {}
Data.Changed = Signal.new() -- (scope, key)
Data.DayChanged = Signal.new()
Data.TicketsChanged = Signal.new()
Data.SessionChanged = Signal.new()
Data.Ready = Signal.new()
Data.ready = false

function Data.w(key)
	local w = Data.world or Data.me
	return w and w[key]
end

function Data.m(key)
	return Data.me and Data.me[key]
end

function Data.role()
	return Data.session and Data.session.role or "visitor"
end

-- the plot you work in (your own restaurant, or the one you help in)
function Data.plotId()
	return Data.session and Data.session.plot or nil
end

function Data.plotFolder(id)
	local plots = workspace:FindFirstChild("Plots")
	local pid = id or Data.plotId()
	return plots and pid and plots:FindFirstChild("Plot" .. pid) or nil
end

-- an attribute of the restaurant you work in (Rating, AmbienceTier, SinkPile, Likes, Seats)
function Data.plotAttr(name)
	local f = Data.plotFolder()
	return f and f:GetAttribute(name) or nil
end

-- world position of the plot you work in / of your own restaurant (local coordinates + origin)
function Data.origin()
	return Vector3.new(Data.session and Data.session.originX or 0, 0, 0)
end

function Data.homeOrigin()
	return Vector3.new(Data.session and Data.session.homeX or 0, 0, 0)
end

-- the plot a world position belongs to
function Data.plotAt(pos)
	local half = PlotsCfg.HalfWidth
	for _, p in ipairs(Data.session and Data.session.plots or {}) do
		if math.abs(pos.X - p.x) < half then
			return p
		end
	end
	return nil
end

-- true when a model belongs to the restaurant you work in
function Data.isMine(model)
	local id = model and model:GetAttribute("PlotId")
	return id ~= nil and id == Data.plotId()
end

function Data.canBuild()
	local r = Data.role()
	return r == "owner" or r == "comanager"
end

-- yen shown in the HUD: the restaurant wallet for owner/co-manager, own wallet for helpers
function Data.wallet()
	if Data.canBuild() then
		return Data.w("yen") or 0
	end
	return Data.m("yen") or 0
end

function Data.applyLanguage()
	local lang = Data.me and Data.me.settings and Data.me.settings.lang or "auto"
	if lang == "auto" then
		lang = Locale.resolve(Players.LocalPlayer.LocaleId)
	end
	Locale.set(lang)
end

function Data.Init()
	NetDef.event("DataChanged").OnClientEvent:Connect(function(scope, key, value)
		if scope == "me" then
			Data.me = Data.me or {}
			Data.me[key] = value
			if key == "settings" then
				Data.applyLanguage()
			end
		else
			Data.world = Data.world or {}
			Data.world[key] = value
		end
		Data.Changed:Fire(scope, key)
	end)
	-- the restaurant you work in changed (nil = your own)
	NetDef.event("WorldSnapshot").OnClientEvent:Connect(function(world)
		Data.world = world
		Data.Changed:Fire("all", "all")
	end)
	NetDef.event("DayState").OnClientEvent:Connect(function(state)
		Data.day = state
		Data.DayChanged:Fire(state)
	end)
	NetDef.event("Tickets").OnClientEvent:Connect(function(list)
		Data.tickets = list
		Data.TicketsChanged:Fire(list)
	end)
	NetDef.event("Session").OnClientEvent:Connect(function(info)
		Data.session = info
		Data.SessionChanged:Fire(info)
	end)
end

function Data.Start()
	local snap
	for _ = 1, 20 do
		local ok, result = pcall(function()
			return NetDef.func("GetSnapshot"):InvokeServer()
		end)
		if ok and result then
			snap = result
			break
		end
		task.wait(1)
	end
	if snap then
		Data.me = snap.me
		Data.world = snap.world
		if snap.session then
			Data.session = snap.session
		end
	end
	Data.applyLanguage()
	Data.ready = true
	Data.Ready:Fire()
	Data.Changed:Fire("all", "all")
	-- the world snapshot may arrive before the owner finished loading: refresh once more
	task.delay(4, function()
		local ok, result = pcall(function()
			return NetDef.func("GetSnapshot"):InvokeServer()
		end)
		if ok and result then
			Data.world = result.world
			if result.session then
				Data.session = result.session
				Data.SessionChanged:Fire(result.session)
			end
			Data.Changed:Fire("all", "all")
		end
	end)
end

return Data
