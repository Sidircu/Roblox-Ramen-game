--!nonstrict
-- The street of restaurants: Config/Plots.Count plots side by side, one per player. A player who
-- joins gets the first free plot (their restaurant is built there from their save); when they leave
-- it becomes an empty lot again. Players can help in other restaurants: friends of the owner and
-- invited players (or everyone, if the owner opens the kitchen to all).
--
-- A plot: { id, origin (Vector3), cf (CFrame), owner, ownerId, folder } plus the per-restaurant
-- state that other services keep on it (tickets, ledger, geometry, seats, ...).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local PlotsCfg = require(Shared.Config.Plots)
local GameConfig = require(Shared.Config.GameConfig)
local Signal = require(Shared.Util.Signal)
local Uid = require(Shared.Util.Uid)
local Core = require(script.Parent.Parent.Core)

local Plots = {}
Plots.list = {}
Plots.byId = {}
Plots.Claimed = Signal.new() -- (plot, player, data): a restaurant opens on this plot
Plots.Released = Signal.new() -- (plot, player): the owner left, the plot is an empty lot again
Plots.WorkChanged = Signal.new() -- (player, plot): the restaurant a player works in changed

local work = {} -- [player] = plot the player is working in (their own, or one they help in)
local root

function Plots.Init()
	root = workspace:FindFirstChild("Plots") or Instance.new("Folder")
	root.Name = "Plots"
	root.Parent = workspace
	for i, x in ipairs(PlotsCfg.OriginsX) do
		local folder = Instance.new("Folder")
		folder.Name = "Plot" .. i
		folder:SetAttribute("PlotId", i)
		folder:SetAttribute("OriginX", x)
		folder:SetAttribute("OwnerId", 0)
		folder:SetAttribute("OwnerName", "")
		folder.Parent = root
		local plot = { id = i, origin = Vector3.new(x, 0, 0), cf = CFrame.new(x, 0, 0), owner = nil, ownerId = nil, folder = folder }
		Plots.list[i] = plot
		Plots.byId[i] = plot
	end
	-- back to the door of your own restaurant (the street is long)
	Core.S.Net.on("GoHome", function(player)
		Plots.sendHome(player)
	end, 1)
	Core.S.Net.on("SetPermission", function(player, userId, level)
		local plot = Plots.ofPlayer(player)
		if not plot or type(userId) ~= "number" or (level ~= "helper" and level ~= "comanager" and level ~= "none") then
			return
		end
		local d = Plots.data(plot)
		if not d then
			return
		end
		d.perms[tostring(userId)] = level ~= "none" and level or nil
		Core.S.Data.changed(player, "perms")
		Plots.refreshInfo()
	end, 4)
end

------------------------------------------------------------------ lookups

-- the owner's profile of a plot (nil for an empty lot)
function Plots.data(plot)
	if not plot or not plot.owner then
		return nil
	end
	return Core.S.Data.get(plot.owner)
end

-- the plot a player owns
function Plots.ofPlayer(player)
	for _, plot in ipairs(Plots.list) do
		if plot.owner == player then
			return plot
		end
	end
	return nil
end

-- the plot a world position belongs to (its strip of street included)
function Plots.at(pos)
	if not pos then
		return nil
	end
	for _, plot in ipairs(Plots.list) do
		if math.abs(pos.X - plot.origin.X) < PlotsCfg.HalfWidth then
			return plot
		end
	end
	return nil
end

-- the plot of a player, a staff member or an entity
function Plots.of(x)
	if x == nil then
		return nil
	end
	if typeof(x) == "Instance" and x:IsA("Player") then
		return work[x] or Plots.ofPlayer(x)
	end
	if type(x) == "table" then
		return x.plot
	end
	return nil
end

-- restaurant-local coordinates <-> world
function Plots.toWorld(plot, x, y, z)
	return Vector3.new(x + plot.origin.X, y or 0, z + plot.origin.Z)
end

function Plots.toLocal(plot, pos)
	return pos - plot.origin
end

-- moves everything built in local coordinates inside `container` onto the plot
function Plots.shift(container, plot)
	local offset = plot.origin
	if offset.Magnitude == 0 then
		return
	end
	local list = container:GetDescendants()
	if container:IsA("BasePart") then
		table.insert(list, container)
	end
	for _, d in ipairs(list) do
		if d:IsA("BasePart") then
			d.CFrame = d.CFrame + offset
		end
	end
end

------------------------------------------------------------------ roles

local function friends(a, b)
	if RunService:IsStudio() then
		return true
	end
	local ok, yes = pcall(function()
		return a:IsFriendsWith(b.UserId)
	end)
	return ok and yes
end

-- "owner" | "comanager" | "helper" | "visitor" for `player` in `plot`
function Plots.role(player, plot)
	if not player or not plot or not plot.owner then
		return "visitor"
	end
	if plot.owner == player then
		return "owner"
	end
	local d = Plots.data(plot)
	local perm = d and d.perms and d.perms[tostring(player.UserId)]
	if perm == "comanager" then
		return "comanager"
	elseif perm == "helper" then
		return "helper"
	end
	local coop = d and d.settings and d.settings.coop or PlotsCfg.DefaultCoop
	if coop == "everyone" or friends(player, plot.owner) then
		return "helper"
	end
	return "visitor"
end

function Plots.canWork(player, plot)
	local r = Plots.role(player, plot)
	return r == "owner" or r == "comanager" or r == "helper"
end

function Plots.canBuild(player, plot)
	local r = Plots.role(player, plot)
	return r == "owner" or r == "comanager"
end

-- the people working in a plot (owner and helpers standing in it)
function Plots.workers(plot)
	local out = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if work[p] == plot or plot.owner == p then
			table.insert(out, p)
		end
	end
	return out
end

-- a message for the people of one restaurant
function Plots.notify(plot, key, params, kind)
	if not plot then
		return
	end
	for _, p in ipairs(Plots.workers(plot)) do
		Core.S.Net.notify(p, key, params, kind)
	end
end

-- a remote event for the people of one restaurant
function Plots.fire(plot, name, ...)
	if not plot then
		return
	end
	for _, p in ipairs(Plots.workers(plot)) do
		Core.S.Net.fire(p, name, ...)
	end
end

------------------------------------------------------------------ info for the client

function Plots.info(player)
	local home = Plots.ofPlayer(player)
	local plot = Plots.of(player) or home
	local list = {}
	for _, p in ipairs(Plots.list) do
		table.insert(list, { id = p.id, x = p.origin.X, ownerId = p.ownerId or 0, ownerName = p.owner and p.owner.DisplayName or "" })
	end
	return {
		plot = plot and plot.id or nil,
		home = home and home.id or nil,
		originX = plot and plot.origin.X or 0,
		homeX = home and home.origin.X or 0,
		ownerId = plot and plot.ownerId or nil,
		ownerName = plot and plot.owner and plot.owner.DisplayName or nil,
		role = Plots.role(player, plot),
		studio = RunService:IsStudio(),
		plots = list,
	}
end

function Plots.refreshInfo()
	for _, p in ipairs(Players:GetPlayers()) do
		Core.S.Net.fire(p, "Session", Plots.info(p))
	end
end

------------------------------------------------------------------ claiming and releasing

local function setWork(player, plot)
	if work[player] == plot then
		return
	end
	work[player] = plot
	Plots.WorkChanged:Fire(player, plot)
	Core.S.Net.fire(player, "Session", Plots.info(player))
end

-- Ids saved in a profile (placed objects, boxes, staff) become entity ids in the server. Two
-- profiles could, very rarely, contain the same id: the newcomer's copies get new ids.
local function dedupe(data)
	local used = {}
	for _, p in ipairs(Plots.list) do
		local od = Plots.data(p)
		if od and od ~= data then
			for _, e in ipairs(od.placed) do
				used[e.u] = true
			end
			for _, b in ipairs(od.storage) do
				used[b.u] = true
			end
			for _, s in ipairs(od.staff) do
				used[s.u] = true
			end
		end
	end
	local map = {}
	for _, e in ipairs(data.placed) do
		if used[e.u] then
			map[e.u] = Uid.new("p")
		end
	end
	for _, e in ipairs(data.placed) do
		e.u = map[e.u] or e.u
		if e.p and map[e.p] then
			e.p = map[e.p]
		end
	end
	for old, new in pairs(map) do
		if data.shelves[old] then
			data.shelves[new] = data.shelves[old]
			data.shelves[old] = nil
		end
		if data.appliances[old] then
			data.appliances[new] = data.appliances[old]
			data.appliances[old] = nil
		end
	end
	for _, b in ipairs(data.storage) do
		if used[b.u] then
			b.u = Uid.new("b")
		end
	end
	for _, s in ipairs(data.staff) do
		if used[s.u] then
			s.u = Uid.new("s")
		end
	end
	return next(map) ~= nil
end
Plots.dedupe = dedupe

local function claim(player, data)
	if Plots.ofPlayer(player) then
		return
	end
	local plot = nil
	for _, p in ipairs(Plots.list) do
		if not p.owner then
			plot = p
			break
		end
	end
	if not plot then
		Core.S.Net.notify(player, "msg.no_plot", nil, "warning")
		return
	end
	dedupe(data)
	plot.owner = player
	plot.ownerId = player.UserId
	plot.folder:SetAttribute("OwnerId", player.UserId)
	plot.folder:SetAttribute("OwnerName", player.DisplayName)
	work[player] = plot
	Plots.Claimed:Fire(plot, player, data)
	Plots.refreshInfo()
	if not Core.S.Data.storeAvailable() then
		Core.S.Net.notify(player, "msg.no_saving", nil, "warning")
	end
	-- the owner's character goes to the door of their restaurant
	local char = player.Character
	if char then
		Plots.sendHome(player)
	end
end

function Plots.sendHome(player)
	local plot = Plots.ofPlayer(player)
	local char = player.Character
	if not plot or not char then
		return
	end
	local s = PlotsCfg.Spawn
	char:PivotTo(CFrame.new(Plots.toWorld(plot, s.x, s.y, s.z)) * CFrame.Angles(0, math.rad(180), 0))
end

-- rebuilds a restaurant from its owner's data (franchise, dev tools): everything on the plot is
-- cleared and built again
function Plots.rebuild(plot)
	local d = Plots.data(plot)
	if not d then
		return
	end
	Plots.Released:Fire(plot, plot.owner)
	Plots.Claimed:Fire(plot, plot.owner, d)
end

local function release(player)
	work[player] = nil
	local plot = Plots.ofPlayer(player)
	if not plot then
		Plots.refreshInfo()
		return
	end
	Plots.Released:Fire(plot, player)
	plot.owner = nil
	plot.ownerId = nil
	plot.folder:SetAttribute("OwnerId", 0)
	plot.folder:SetAttribute("OwnerName", "")
	-- helpers working there go back to their own restaurant
	for p, wp in pairs(work) do
		if wp == plot then
			work[p] = nil
		end
	end
	Plots.refreshInfo()
end

function Plots.Start()
	Core.S.Data.Loaded:Connect(function(player, data)
		claim(player, data)
	end)
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			task.defer(function()
				Plots.sendHome(player)
			end)
		end)
	end)
	for _, player in ipairs(Players:GetPlayers()) do
		local d = Core.S.Data.get(player)
		if d then
			claim(player, d)
		end
	end
	Players.PlayerRemoving:Connect(release)
	-- the restaurant a player works in: the one they stand in when they may work there,
	-- otherwise their own; and the team bonus of every restaurant (other players working in it)
	while true do
		task.wait(0.5)
		for _, player in ipairs(Players:GetPlayers()) do
			local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			local here = hrp and Plots.at(hrp.Position) or nil
			local want = Plots.ofPlayer(player)
			if here and here ~= want and here.owner and Plots.canWork(player, here) then
				want = here
			end
			if want then
				setWork(player, want)
			end
		end
		local cfg = GameConfig.Coop
		for _, plot in ipairs(Plots.list) do
			local helpers = 0
			if plot.owner then
				for p, wp in pairs(work) do
					if wp == plot and p ~= plot.owner and p.Parent then
						helpers += 1
					end
				end
			end
			local bonus = math.min(cfg.MaxBonus, helpers * cfg.BonusPerHelper)
			if plot.coopBonus ~= bonus then
				-- everybody working there hears when the bonus grows (not again and again when a
				-- helper walks in and out of the door)
				local fresh = bonus > (plot.coopTold or 0) or os.clock() - (plot.coopToldAt or -math.huge) > cfg.NotifyEvery
				if bonus > (plot.coopBonus or 0) and fresh then
					plot.coopTold = bonus
					plot.coopToldAt = os.clock()
					for p, wp in pairs(work) do
						if wp == plot and p.Parent then
							Core.S.Net.notify(p, "msg.coop_bonus", { pct = math.floor(bonus * 100 + 0.5) }, "success")
						end
					end
				end
				plot.coopBonus = bonus
				plot.folder:SetAttribute("CoopBonus", bonus)
			end
		end
	end
end

return Plots
