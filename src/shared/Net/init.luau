--!nonstrict
-- Remote definitions shared by server and client.
-- The server creates the instances; the client waits for them.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Net = {}

Net.Events = {
	-- client -> server
	"Interact", -- (uid, extra)
	"DropHands",
	"OrderSupplies", -- (cart {[ingredientId] = {small = n, big = n}})
	"BuyDishes",
	"PlaceItem", -- (request)
	"MoveItem", -- (uid, request)
	"RemoveItem", -- (uid, mode "sell"|"store")
	"PaintSurface", -- (zoneId, kind "floor"|"wall", styleId)
	"BuyLicense",
	"BuyUpgrade",
	"BuyExpansion",
	"BuyAd",
	"HireStaff",
	"TrainStaff",
	"FireStaff",
	"SetMenu", -- (recipeId, on, priceMult)
	"SetDayState", -- ("open" | "close" | "next")
	"ClaimQuest",
	"ClaimAchievement",
	"ClaimDaily",
	"ClaimOffline",
	"Wash", -- (sinkUid, holding) hold to wash dishes at the sink
	"ClaimGift", -- (index) free gift for minutes played
	"RedeemCode", -- (code)
	"SetSetting", -- (key, value)
	"SetPermission", -- (userId, level)
	"Franchise", -- (cityId)
	"BuyWithRobux", -- (kind "gamepass"|"product", id)
	"TutorialStep", -- (step)
	"Dev", -- (command, arg)
	-- server -> client
	"DataChanged", -- (scope "me"|"world", key, value)
	"Notify", -- (key, params, kind)
	"Tickets", -- (list)
	"Fx", -- (kind, data)
	"DayState", -- (state table)
	"Session", -- (info)
}

Net.Functions = {
	"GetSnapshot",
	"GetLeaderboard",
}

local folder

local function getFolder()
	if folder then
		return folder
	end
	if RunService:IsServer() then
		folder = ReplicatedStorage:FindFirstChild("Remotes")
		if not folder then
			folder = Instance.new("Folder")
			folder.Name = "Remotes"
			for _, name in ipairs(Net.Events) do
				local ev = Instance.new("RemoteEvent")
				ev.Name = name
				ev.Parent = folder
			end
			for _, name in ipairs(Net.Functions) do
				local fn = Instance.new("RemoteFunction")
				fn.Name = name
				fn.Parent = folder
			end
			folder.Parent = ReplicatedStorage
		end
	else
		folder = ReplicatedStorage:WaitForChild("Remotes")
	end
	return folder
end

function Net.event(name)
	local f = getFolder()
	if RunService:IsServer() then
		return f[name]
	end
	return f:WaitForChild(name)
end

function Net.func(name)
	return Net.event(name)
end

return Net
