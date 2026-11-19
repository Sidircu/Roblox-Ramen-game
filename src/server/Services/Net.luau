--!nonstrict
-- Server networking helpers: rate-limited handlers and broadcast helpers.
local Players = game:GetService("Players")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local NetDef = require(Shared.Net)
local RateLimit = require(Shared.Util.RateLimit)
local Core = require(script.Parent.Parent.Core)

local Net = {}
local limiters = {}

function Net.Init()
	NetDef.event("Interact") -- creates the folder with all remotes
	-- forget the rate limit buckets of players who left
	Players.PlayerRemoving:Connect(function(player)
		for _, limiter in pairs(limiters) do
			limiter:clear(player)
		end
	end)
end

-- handler(player, ...) ; rate = calls per second allowed (burst = 2x)
function Net.on(name, handler, rate)
	local limiter = RateLimit.new(rate or 8, (rate or 8) * 2)
	limiters[name] = limiter
	NetDef.event(name).OnServerEvent:Connect(function(player, ...)
		if not limiter:check(player) then
			return
		end
		local ok, err = pcall(handler, player, ...)
		if not ok then
			warn("[Net] " .. name .. " handler error: " .. tostring(err))
		end
	end)
end

-- rate = calls per second allowed for each player (burst = 3x); extra calls get nil
function Net.invoke(name, handler, rate)
	local limiter = RateLimit.new(rate or 1, (rate or 1) * 3)
	limiters[name] = limiter
	NetDef.func(name).OnServerInvoke = function(player, ...)
		if not limiter:check(player) then
			return nil
		end
		local ok, result = pcall(handler, player, ...)
		if not ok then
			warn("[Net] " .. name .. " invoke error: " .. tostring(result))
			return nil
		end
		return result
	end
end

function Net.fire(player, name, ...)
	if player and player.Parent then
		NetDef.event(name):FireClient(player, ...)
	end
end

function Net.fireAll(name, ...)
	NetDef.event(name):FireAllClients(...)
end

function Net.notify(player, key, params, kind)
	Net.fire(player, "Notify", key, params, kind or "info")
end

function Net.notifyAll(key, params, kind)
	Net.fireAll("Notify", key, params, kind or "info")
end

function Net.fx(kind, data)
	Net.fireAll("Fx", kind, data)
end

function Net.fxTo(player, kind, data)
	Net.fire(player, "Fx", kind, data)
end

-- Argument validation helpers
function Net.str(v, maxLen)
	return type(v) == "string" and #v <= (maxLen or 64)
end

function Net.num(v, min, max)
	return type(v) == "number" and v == v and (min == nil or v >= min) and (max == nil or v <= max)
end

function Net.players()
	return Players:GetPlayers()
end

local _ = Core
return Net
