--!nonstrict
-- Receives clicks/taps from players, checks distance and permissions, dispatches to services.
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local Core = require(script.Parent.Parent.Core)

local Interaction = {}

local busy = {} -- [player] = true while an action runs (steps/washing yield)

local function targetPosition(e, slot)
	if slot and e.model then
		local part = e.model:FindFirstChild("Slot" .. slot)
		if part then
			return part.Position
		end
	end
	local pos = Core.S.Entities.position(e)
	return pos
end

local function sizeMargin(e)
	if e.item then
		return math.max(e.item.size[1], e.item.size[3]) / 2
	end
	return 1.5
end

-- Dispatch shared by players (and reused by tutorial / dev tools)
function Interaction.perform(actor, e, extra)
	local S = Core.S
	local kind = e.kind
	if kind == "box" then
		return S.Supply.takeBox(actor, e)
	elseif kind == "rack" then
		local hands = S.Hands.get(actor)
		if hands.kind == "box" then
			local entry = hands.items[1]
			S.Hands.clear(actor)
			S.Supply.returnBox(entry)
			return true
		end
		return false, "msg.rack_hint"
	elseif kind == "shelf" then
		local slot = type(extra) == "table" and tonumber(extra.slot) or nil
		return S.Supply.useShelf(actor, e, slot)
	elseif kind == "ricecooker" or kind == "pot" then
		return S.Appliance.load(actor, e)
	elseif kind == "sink" then
		return S.Appliance.useSink(actor, e, 1)
	elseif kind == "dishwasher" then
		return S.Appliance.useDishwasher(actor, e)
	elseif kind == "station" then
		return S.Cooking.use(actor, e, 1)
	elseif kind == "customer" then
		return S.Customers.use(actor, e)
	elseif kind == "dirty" then
		return S.Customers.collectDirty(actor, e)
	end
	return false, nil
end

local ACTION_FOR_KIND = {
	box = "take_box", shelf = "shelf", ricecooker = "rice", pot = "broth", sink = "wash",
	dishwasher = "wash", station = "station", customer = "customer", dirty = "collect", rack = "rack",
}

function Interaction.Init()
	Core.S.Net.on("Interact", function(player, uid, extra)
		local S = Core.S
		if type(uid) ~= "string" or #uid > 40 then
			return
		end
		if not S.Session.canWork(player) or not S.Session.owner then
			return
		end
		if busy[player] then
			return
		end
		local e = S.Entities.get(uid)
		if not e then
			return
		end
		local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if not hrp then
			return
		end
		local slot = type(extra) == "table" and tonumber(extra.slot) or nil
		local pos = targetPosition(e, slot)
		if not pos then
			return
		end
		local dist = (Vector3.new(pos.X, 0, pos.Z) - Vector3.new(hrp.Position.X, 0, hrp.Position.Z)).Magnitude
		if dist > GameConfig.InteractRange + sizeMargin(e) or math.abs(pos.Y - hrp.Position.Y) > 12 then
			return S.Net.notify(player, "msg.too_far", nil, "info")
		end
		busy[player] = true
		local ok, result, reason, params = pcall(Interaction.perform, player, e, extra)
		busy[player] = nil
		if not ok then
			warn("[Interaction] " .. tostring(result))
			return
		end
		if result then
			S.Net.fxTo(player, "action", { kind = ACTION_FOR_KIND[e.kind] or e.kind, hands = S.Hands.get(player).kind })
		elseif reason then
			S.Net.notify(player, reason, params, "info")
		end
	end, 12)
	game:GetService("Players").PlayerRemoving:Connect(function(p)
		busy[p] = nil
	end)
end

return Interaction
