--!nonstrict
-- What every actor (player or staff NPC) is carrying, with visuals welded in front of the body.
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local Upgrades = require(Shared.Config.Upgrades)
local Registry = require(Shared.Models.Registry)
local Core = require(script.Parent.Parent.Core)

local Hands = {}
local state = {} -- [actorKey] = { kind, items = {}, visuals = {} }

local HOLD_ANIM = "rbxassetid://507768375"

local function key(actor)
	return actor
end

function Hands.get(actor)
	local s = state[key(actor)]
	if not s then
		s = { kind = nil, items = {}, visuals = {} }
		state[key(actor)] = s
	end
	return s
end

function Hands.isEmpty(actor)
	return #Hands.get(actor).items == 0
end

function Hands.count(actor)
	return #Hands.get(actor).items
end

local function character(actor)
	if typeof(actor) == "Instance" and actor:IsA("Player") then
		return actor.Character
	elseif type(actor) == "table" then
		return actor.model
	end
	return nil
end

-- Capacity for a kind of item
function Hands.capacity(actor, kind)
	if kind == "box" then
		return 1
	elseif kind == "ing" then
		return GameConfig.IngredientHandCapacity
	end
	local Session = Core.S.Session
	local od = Session.ownerData()
	local tray = od and Upgrades.value(od.upgrades, "up_tray") or 1
	if typeof(actor) == "Instance" and actor:IsA("Player") then
		local Monetization = Core.S.Monetization
		if Monetization and Monetization.ownerHas("gp_big_tray") then
			tray += 2
		end
	elseif type(actor) == "table" then
		tray = math.max(2, tray)
	end
	return tray
end

local function holdAnim(actor, on)
	local char = character(actor)
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local animator = hum and (hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum))
	if not animator then
		return
	end
	local s = Hands.get(actor)
	if on and not s.track then
		local anim = Instance.new("Animation")
		anim.AnimationId = HOLD_ANIM
		local ok, track = pcall(function()
			return animator:LoadAnimation(anim)
		end)
		if ok and track then
			track.Priority = Enum.AnimationPriority.Action
			track.Looped = true
			track:Play(0.2)
			s.track = track
		end
	elseif not on and s.track then
		s.track:Stop(0.2)
		s.track = nil
	end
end

local function buildVisual(kind, item)
	if kind == "box" then
		return Registry.food("box", item.g, item.n, Core.S.Supply.boxCap(item))
	elseif kind == "ing" then
		return Registry.food("ingredient", item.g)
	elseif kind == "dish" then
		return Registry.food("dish", item.recipe)
	elseif kind == "dirty" then
		return Registry.food("dirty", item.dish)
	end
	return nil
end

local function refreshVisual(actor)
	local s = Hands.get(actor)
	for _, v in ipairs(s.visuals) do
		v:Destroy()
	end
	s.visuals = {}
	local char = character(actor)
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end
	local y = 0.1
	for i, item in ipairs(s.items) do
		local m = buildVisual(s.kind, item)
		if m then
			local h = m.PrimaryPart and m.PrimaryPart.Size.Y or 0.5
			local offset
			if s.kind == "ing" then
				offset = CFrame.new(((i - 1) % 3 - 1) * 0.55, 0.2 + math.floor((i - 1) / 3) * 0.5, -1.5)
			else
				offset = CFrame.new(0, y + h / 2, -1.5)
				y += h * 0.85
			end
			m:PivotTo(hrp.CFrame * offset)
			for _, d in ipairs(m:GetDescendants()) do
				if d:IsA("BasePart") then
					d.Anchored = false
					d.CanCollide = false
					d.CanQuery = false
					d.CanTouch = false
					d.Massless = true
					local w = Instance.new("WeldConstraint")
					w.Part0 = hrp
					w.Part1 = d
					w.Parent = d
				end
			end
			-- the client shows held items in front of the camera in first person
			m:SetAttribute("Held", true)
			m.Parent = char
			table.insert(s.visuals, m)
		end
	end
	holdAnim(actor, #s.items > 0)
end

local function publish(actor)
	if typeof(actor) == "Instance" and actor:IsA("Player") then
		local s = Hands.get(actor)
		local list = {}
		for _, it in ipairs(s.items) do
			table.insert(list, it.g or it.recipe or it.dish or "?")
		end
		actor:SetAttribute("HandsKind", s.kind or "")
		actor:SetAttribute("Hands", HttpService:JSONEncode(list))
	end
end

function Hands.set(actor, kind, items)
	local s = Hands.get(actor)
	s.kind = (#items > 0) and kind or nil
	s.items = items
	refreshVisual(actor)
	publish(actor)
end

-- Adds an item; returns false when the hands hold something else or are full.
function Hands.add(actor, kind, item)
	local s = Hands.get(actor)
	if s.kind and s.kind ~= kind then
		return false, "msg.hands_busy"
	end
	if #s.items >= Hands.capacity(actor, kind) then
		return false, "msg.hands_full"
	end
	local items = table.clone(s.items)
	table.insert(items, item)
	Hands.set(actor, kind, items)
	return true
end

function Hands.clear(actor)
	Hands.set(actor, nil, {})
end

function Hands.removeAt(actor, index)
	local s = Hands.get(actor)
	local items = table.clone(s.items)
	local it = table.remove(items, index)
	Hands.set(actor, s.kind, items)
	return it
end

function Hands.refresh(actor)
	refreshVisual(actor)
	publish(actor)
end

function Hands.forget(actor)
	local s = state[key(actor)]
	if s then
		for _, v in ipairs(s.visuals) do
			v:Destroy()
		end
	end
	state[key(actor)] = nil
end

function Hands.Start()
	Players.PlayerRemoving:Connect(function(player)
		-- boxes in hand go back to storage
		local s = state[player]
		if s and s.kind == "box" then
			local Supply = Core.S.Supply
			for _, b in ipairs(s.items) do
				Supply.returnBox(b)
			end
		end
		Hands.forget(player)
	end)
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			task.wait(0.5)
			-- respawn: drop everything (boxes return to storage)
			local s = state[player]
			if s and s.kind == "box" then
				for _, b in ipairs(s.items) do
					Core.S.Supply.returnBox(b)
				end
			end
			Hands.forget(player)
			publish(player)
		end)
	end)
	-- Putting things down always says where they went: boxes stay on the floor in front of you
	-- (or go on the rack when you are next to it), ingredients go back on a shelf, plates go to
	-- the sink.
	Core.S.Net.on("DropHands", function(player)
		local s = Hands.get(player)
		local Net = Core.S.Net
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local pos = root and root.Position or Vector3.new()
		local look = root and root.CFrame.LookVector or Vector3.new(0, 0, -1)
		local floor = Core.S.World.floorOf(pos.Y)
		if s.kind == "box" then
			local where = "floor"
			for _, b in ipairs(s.items) do
				where = Core.S.Supply.dropBox(b, pos, Vector3.new(look.X, 0, look.Z).Unit, floor)
			end
			Hands.clear(player)
			Net.notify(player, where == "rack" and "msg.box_on_rack" or "msg.box_on_floor", nil, "info")
			return
		elseif s.kind == "ing" then
			local back, lost = 0, 0
			for _, it in ipairs(s.items) do
				if Core.S.Supply.returnIngredient(it.g, pos) then
					back += 1
				else
					lost += 1
				end
			end
			Hands.clear(player)
			if lost > 0 then
				Net.notify(player, "msg.ing_discarded", { n = lost }, "error")
			else
				Net.notify(player, "msg.ing_returned", { n = back }, "info")
			end
			return
		elseif s.kind == "dish" or s.kind == "dirty" then
			-- plates are never lost: they go to the sink as dirty dishes
			Core.S.Appliance.addDirtyToSink(#s.items)
			Hands.clear(player)
			Net.notify(player, "msg.dish_to_sink", nil, "info")
			return
		end
		Hands.clear(player)
		Net.notify(player, "msg.hands_dropped")
	end, 3)
end

return Hands
