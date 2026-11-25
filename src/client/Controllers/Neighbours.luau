--!nonstrict
-- Settings → Other restaurants. "Show all": the whole street as it is. "Only the outside": the
-- restaurants you are not in keep their building (walls, roof, facade, the lanterns in the
-- ceiling) but their objects, boxes and the people inside are hidden on this screen only, so a
-- phone has much less to draw. The restaurant you stand in, and the next one as you walk up to
-- it, are always complete. Nothing changes for the other players or on the server: parts get
-- LocalTransparencyModifier 1, their lamps and painted signs are switched off here and come back
-- as they were.
local Players = game:GetService("Players")
local Core = require(script.Parent.Parent.Core)

local Neighbours = {}
local player = Players.LocalPlayer

-- a restaurant is complete when you are this close to the middle of its plot (along the street;
-- plots are 240 studs apart, so the next one appears as you walk past the halfway point)
Neighbours.Near = 150
local DETAIL = { "Items", "Dynamic" }

local hiddenPlots = {} -- [plot folder] = { connections }
local prior = setmetatable({}, { __mode = "k" }) -- [light / gui / emitter] = Enabled before hiding
local hiddenNpcs = setmetatable({}, { __mode = "k" }) -- [npc model] = true

local function setting()
	local s = Core.C.Data and Core.C.Data.m("settings")
	return (s and s.others) or "show"
end

local function hereX()
	local c = player.Character
	local root = c and c:FindFirstChild("HumanoidRootPart")
	if root then
		return root.Position.X
	end
	local cam = workspace.CurrentCamera
	return cam and cam.Focus.Position.X or 0
end

-- hides (or shows again) one instance of a restaurant's inside
local function apply(d, hide)
	if d:IsA("BasePart") or d:IsA("Decal") or d:IsA("Texture") then
		d.LocalTransparencyModifier = hide and 1 or 0
	elseif d:IsA("Light") then
		-- night lights are switched by Controllers/Lighting, which asks Neighbours.hides
		if d:GetAttribute("NightLight") ~= true then
			if hide then
				if prior[d] == nil then
					prior[d] = d.Enabled
				end
				d.Enabled = false
			elseif prior[d] ~= nil then
				d.Enabled = prior[d]
				prior[d] = nil
			end
		end
	elseif d:IsA("SurfaceGui") then
		-- (floating labels and smoke are left alone: they fade with distance anyway, and the
		-- server switches some of them while the restaurant is hidden)
		if hide then
			if prior[d] == nil then
				prior[d] = d.Enabled
			end
			d.Enabled = false
		elseif prior[d] ~= nil then
			d.Enabled = prior[d]
			prior[d] = nil
		end
	end
end

local function setPlot(folder, hide)
	if (hiddenPlots[folder] ~= nil) == hide then
		return
	end
	if hide then
		local conns = {}
		for _, name in ipairs(DETAIL) do
			local f = folder:FindFirstChild(name)
			if f then
				for _, d in ipairs(f:GetDescendants()) do
					apply(d, true)
				end
				-- what arrives while hidden (a new object, a box, a dish) is hidden too
				table.insert(conns, f.DescendantAdded:Connect(function(d)
					apply(d, true)
				end))
			end
		end
		hiddenPlots[folder] = conns
	else
		for _, c in ipairs(hiddenPlots[folder]) do
			c:Disconnect()
		end
		hiddenPlots[folder] = nil
		for _, name in ipairs(DETAIL) do
			local f = folder:FindFirstChild(name)
			if f then
				for _, d in ipairs(f:GetDescendants()) do
					apply(d, false)
				end
			end
		end
	end
end

local function setNpc(model, hide)
	if (hiddenNpcs[model] == true) == hide then
		return
	end
	hiddenNpcs[model] = hide or nil
	for _, d in ipairs(model:GetDescendants()) do
		apply(d, hide)
	end
end

-- true when `inst` belongs to the hidden inside of another restaurant (Controllers/Lighting)
function Neighbours.hides(inst)
	for folder in pairs(hiddenPlots) do
		if inst:IsDescendantOf(folder) then
			return true
		end
	end
	return false
end

-- true when the inside of plot folder `folder` is drawn
function Neighbours.shown(folder)
	return hiddenPlots[folder] == nil
end

function Neighbours.step()
	local plots = workspace:FindFirstChild("Plots")
	if not plots then
		return
	end
	local only = setting() == "hide"
	local x = hereX()
	local hiddenX = {}
	for _, folder in ipairs(plots:GetChildren()) do
		local ox = folder:GetAttribute("OriginX") or 0
		local hide = only and math.abs(x - ox) >= Neighbours.Near
		setPlot(folder, hide)
		if hide then
			table.insert(hiddenX, ox)
		end
	end
	-- the people inside a hidden restaurant (those walking on the street stay)
	local npcs = workspace:FindFirstChild("NPCs")
	if npcs then
		for _, m in ipairs(npcs:GetChildren()) do
			local hide = false
			if #hiddenX > 0 and m:IsA("Model") then
				local pos = m:GetPivot().Position
				if pos.Z > 0.5 then
					for _, ox in ipairs(hiddenX) do
						if math.abs(pos.X - ox) < 120 then
							hide = true
						end
					end
				end
			end
			setNpc(m, hide)
		end
	end
end

function Neighbours.Start()
	task.spawn(function()
		while true do
			pcall(Neighbours.step)
			task.wait(1)
		end
	end)
end

return Neighbours
