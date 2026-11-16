--!nonstrict
-- Personal worlds: public servers act as an entrance that teleports every player to their
-- own reserved server; friends can join through invites. In Studio the server is a world directly.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local DataStoreService = game:GetService("DataStoreService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local HttpService = game:GetService("HttpService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Signal = require(Shared.Util.Signal)
local Core = require(script.Parent.Parent.Core)

local Session = {}
Session.mode = "world"
Session.owner = nil
Session.ownerId = nil
Session.OwnerReady = Signal.new() -- (player, data)
Session.RolesChanged = Signal.new()

local codesStore, ownersStore, liveMap
local isReservedServer = game.PrivateServerId ~= "" and game.PrivateServerOwnerId == 0

local function safe(fn, ...)
	local ok, a, b = pcall(fn, ...)
	if ok then
		return a, b
	end
	warn("[Session] " .. tostring(a))
	return nil
end

function Session.role(player)
	if not player then
		return "none"
	end
	if player == Session.owner then
		return "owner"
	end
	local od = Session.ownerData()
	local perm = od and od.perms and od.perms[tostring(player.UserId)]
	if perm == "comanager" then
		return "comanager"
	end
	return "helper"
end

function Session.canBuild(player)
	local r = Session.role(player)
	return r == "owner" or r == "comanager"
end

function Session.canWork(player)
	return Session.role(player) ~= "none"
end

function Session.ownerData()
	if not Session.owner then
		return nil
	end
	return Core.S.Data.get(Session.owner)
end

function Session.info(player)
	return {
		mode = Session.mode,
		ownerId = Session.ownerId,
		ownerName = Session.owner and Session.owner.DisplayName or nil,
		role = Session.role(player),
		studio = RunService:IsStudio(),
	}
end

local function broadcastInfo()
	for _, p in ipairs(Players:GetPlayers()) do
		Core.S.Net.fire(p, "Session", Session.info(p))
	end
end

local function worldCode(userId)
	if not codesStore then
		return nil
	end
	local entry = safe(function()
		return codesStore:GetAsync(tostring(userId))
	end)
	if entry and entry.code then
		return entry.code, entry.ps
	end
	-- ReserveServerAsync is the newer name; ReserveServer is the older fallback
	local code, psId = safe(function()
		return TeleportService:ReserveServerAsync(game.PlaceId)
	end)
	if not code then
		code, psId = safe(function()
			return TeleportService:ReserveServer(game.PlaceId)
		end)
	end
	if not code then
		return nil
	end
	safe(function()
		codesStore:SetAsync(tostring(userId), { code = code, ps = psId })
	end)
	if psId then
		safe(function()
			ownersStore:SetAsync(psId, userId)
		end)
	end
	return code, psId
end

local function teleport(player, code, data, psId)
	for attempt = 1, 3 do
		local opts = Instance.new("TeleportOptions")
		-- the access code is the long-standing way; ReservedServerId is the newer property
		local set = pcall(function()
			if attempt == 2 and psId then
				opts.ReservedServerId = psId
			else
				opts.ReservedServerAccessCode = code
			end
		end)
		if not set then
			pcall(function()
				opts.ReservedServerId = psId
			end)
		end
		opts:SetTeleportData(data or {})
		local ok, err = pcall(function()
			TeleportService:TeleportAsync(game.PlaceId, { player }, opts)
		end)
		if ok then
			return true
		end
		warn("[Session] teleport failed (" .. attempt .. "): " .. tostring(err))
		task.wait(2 * attempt)
	end
	return false
end

function Session.sendToOwnWorld(player)
	local code, psId = worldCode(player.UserId)
	if code and teleport(player, code, { owner = player.UserId }, psId) then
		return true
	end
	return false
end

local function becomeOwner(player)
	Session.owner = player
	Session.ownerId = player.UserId
	task.spawn(function()
		local data = Core.S.Data.waitFor(player, 60)
		if data and Session.owner == player then
			Session.OwnerReady:Fire(player, data)
			broadcastInfo()
			if not Core.S.Data.storeAvailable() then
				Core.S.Net.notify(player, "msg.no_saving", nil, "warning")
			end
		end
	end)
end

local function allowedGuest(player)
	if RunService:IsStudio() then
		return true
	end
	local od = Session.ownerData()
	if od and od.perms and od.perms[tostring(player.UserId)] then
		return true
	end
	local ok, friends = pcall(function()
		return player:IsFriendsWith(Session.ownerId)
	end)
	return ok and friends
end

local function onWorldPlayer(player)
	if not Session.owner then
		if Session.ownerId == nil or player.UserId == Session.ownerId then
			becomeOwner(player)
			return
		end
	end
	if player == Session.owner then
		return
	end
	if Session.owner == nil and Session.ownerId ~= nil and player.UserId == Session.ownerId then
		becomeOwner(player)
		return
	end
	if not Session.owner or not allowedGuest(player) then
		Core.S.Net.notify(player, "msg.world_private")
		task.wait(2)
		if not Session.sendToOwnWorld(player) and not Session.owner then
			becomeOwner(player)
		end
		return
	end
	Core.S.Net.notify(Session.owner, "msg.helper_joined", { name = player.DisplayName })
	broadcastInfo()
end

local function onLobbyPlayer(player)
	local joinData = player:GetJoinData()
	local launch = joinData and joinData.LaunchData
	if type(launch) == "string" and launch ~= "" and liveMap then
		local ok, decoded = pcall(HttpService.JSONDecode, HttpService, launch)
		local ownerId = ok and type(decoded) == "table" and tonumber(decoded.owner) or nil
		if ownerId and ownerId ~= player.UserId then
			local live = safe(function()
				return liveMap:GetAsync(tostring(ownerId))
			end)
			local friends = false
			pcall(function()
				friends = player:IsFriendsWith(ownerId)
			end)
			if live and live.code and friends then
				if teleport(player, live.code, { owner = ownerId, guest = true }, live.ps) then
					return
				end
			else
				Core.S.Net.notify(player, "msg.friend_offline")
			end
		end
	end
	if not Session.sendToOwnWorld(player) then
		-- fallback: play right here as a world
		if not Session.owner then
			Session.mode = "world"
			becomeOwner(player)
			Core.S.Net.notify(player, "msg.teleport_failed")
		end
	end
end

function Session.Init()
	pcall(function()
		codesStore = DataStoreService:GetDataStore("WorldCodes_v1")
		ownersStore = DataStoreService:GetDataStore("WorldOwners_v1")
		liveMap = MemoryStoreService:GetSortedMap("LiveWorlds_v1")
	end)
	if RunService:IsStudio() then
		Session.mode = "world"
	elseif isReservedServer then
		Session.mode = "world"
		local ownerId = safe(function()
			return ownersStore:GetAsync(game.PrivateServerId)
		end)
		Session.ownerId = ownerId
	else
		Session.mode = "lobby"
	end
	workspace:SetAttribute("SessionMode", Session.mode)
	Core.S.Net.on("SetPermission", function(player, userId, level)
		if player ~= Session.owner then
			return
		end
		if type(userId) ~= "number" or (level ~= "helper" and level ~= "comanager") then
			return
		end
		local od = Session.ownerData()
		if not od then
			return
		end
		od.perms[tostring(userId)] = level
		Core.S.Data.changed(player, "perms")
		Session.RolesChanged:Fire()
		broadcastInfo()
	end, 4)
end

function Session.Start()
	Players.PlayerAdded:Connect(function(player)
		player.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam
		if Session.mode == "lobby" then
			onLobbyPlayer(player)
		else
			onWorldPlayer(player)
		end
	end)
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			player.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam
			if Session.mode == "lobby" then
				onLobbyPlayer(player)
			else
				onWorldPlayer(player)
			end
		end)
	end
	Players.PlayerRemoving:Connect(function(player)
		if player == Session.owner then
			Session.owner = nil
			if liveMap then
				safe(function()
					liveMap:RemoveAsync(tostring(player.UserId))
				end)
			end
			if RunService:IsStudio() then
				local nextOwner = nil
				for _, p in ipairs(Players:GetPlayers()) do
					if p ~= player then
						nextOwner = p
						break
					end
				end
				if nextOwner then
					Session.ownerId = nextOwner.UserId
					becomeOwner(nextOwner)
				end
				return
			end
			for _, p in ipairs(Players:GetPlayers()) do
				if p ~= player then
					Core.S.Net.notify(p, "msg.owner_left")
					task.delay(3, function()
						if p.Parent then
							Session.sendToOwnWorld(p)
						end
					end)
				end
			end
		else
			task.defer(broadcastInfo)
		end
	end)
	-- heartbeat so friends can find this world
	task.spawn(function()
		while true do
			if Session.mode == "world" and Session.owner and liveMap and isReservedServer then
				local code, psId = worldCode(Session.owner.UserId)
				if code then
					safe(function()
						liveMap:SetAsync(tostring(Session.owner.UserId), { code = code, ps = psId, t = os.time() }, 180)
					end)
				end
			end
			task.wait(60)
		end
	end)
end

return Session
