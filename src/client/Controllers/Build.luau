--!nonstrict
-- Build mode: ghost preview on a 1/5/10 stud grid, rotation, local validation (same rules as the
-- server), placing, moving, storing and selling objects.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local GuiService = game:GetService("GuiService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local NetDef = require(Shared.Net)
local Locale = require(Shared.Locale)
local GameConfig = require(Shared.Config.GameConfig)
local Items = require(Shared.Config.Items)
local Expansions = require(Shared.Config.Expansions)
local Grid = require(Shared.Logic.Grid)
local Geometry = require(Shared.Logic.Geometry)
local PlacementLogic = require(Shared.Logic.Placement)
local Registry = require(Shared.Models.Registry)
local Color = require(Shared.Util.Color)
local Signal = require(Shared.Util.Signal)
local Core = require(script.Parent.Parent.Core)

local Build = {}
Build.active = false
Build.mode = nil -- "new" | "inventory" | "move"
Build.itemId = nil
Build.moveUid = nil
Build.rot = 0
Build.grid = 1
Build.selected = nil
Build.valid = false
Build.reason = nil
Build.Changed = Signal.new()

local player = Players.LocalPlayer
local ghost, highlight, hoverHighlight
local geo, geoKey = nil, nil
local lastReq, lastValidate = nil, 0
local gridParts = {}
local touchPos = nil
local worldTouch = nil
local lastResolved = nil

local function itemsFolder()
	local r = workspace:FindFirstChild("Restaurant")
	return r and r:FindFirstChild("Items")
end

local function geometry()
	local zones = Core.C.Data.w("zones") or { zone_base = true }
	local key = ""
	for id in pairs(zones) do
		key ..= id .. ";"
	end
	if key ~= geoKey then
		geo = Geometry.compute(Expansions.list, zones, Expansions)
		geoKey = key
	end
	return geo
end

function Build.geometry()
	return geometry()
end

local function ctx()
	local placed = Core.C.Data.w("placed") or {}
	return Geometry.ctx(geometry(), Items.byId, placed, GameConfig)
end

local function floorY(f)
	return (f or 0) * GameConfig.FloorHeight
end

local function worldY(entry, item)
	if entry.s == "f" then
		return floorY(entry.f)
	elseif entry.s == "c" then
		return floorY(entry.f) + GameConfig.WallHeight - item.size[2]
	elseif entry.s == "w" then
		return (entry.y or floorY(entry.f) + 6) - item.size[2] / 2
	end
	return entry.y or floorY(entry.f)
end

------------------------------------------------------------------ ghost & grid

local function clearGhost()
	if ghost then
		ghost:Destroy()
		ghost = nil
	end
	for _, p in ipairs(gridParts) do
		p.Transparency = 1
	end
end

local function makeGhost(itemId)
	clearGhost()
	Registry.load()
	local world = Core.C.Data.world or {}
	ghost = Registry.build(itemId, { styles = Expansions.styles(world.zones) })
	for _, d in ipairs(ghost:GetDescendants()) do
		if d:IsA("BasePart") then
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
			d.CastShadow = false
			if d.Transparency < 1 then
				d.Transparency = math.max(d.Transparency, 0.35)
			end
		elseif d:IsA("Light") or d:IsA("ParticleEmitter") then
			d.Enabled = false
		end
	end
	ghost.Parent = workspace.CurrentCamera
	highlight.Adornee = ghost
	highlight.Enabled = true
end

local function gridLine(i)
	local p = gridParts[i]
	if not p then
		p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Material = Enum.Material.Neon
		p.Color = Color.hex("#FFF4D6")
		p.Transparency = 1
		p.Parent = workspace.CurrentCamera
		gridParts[i] = p
	end
	return p
end

local function drawGrid(cx, cz, y, g)
	local radius = math.clamp(g * 6, 8, 40)
	local x0 = Grid.snapValue(cx - radius, g)
	local z0 = Grid.snapValue(cz - radius, g)
	local n = math.floor(radius * 2 / g)
	local i = 0
	for k = 0, n do
		i += 1
		local p = gridLine(i)
		p.Size = Vector3.new(0.06, 0.03, radius * 2)
		p.CFrame = CFrame.new(x0 + k * g, y + 0.04, cz)
		p.Transparency = 0.55
		i += 1
		local q = gridLine(i)
		q.Size = Vector3.new(radius * 2, 0.03, 0.06)
		q.CFrame = CFrame.new(cx, y + 0.04, z0 + k * g)
		q.Transparency = 0.55
	end
	for k = i + 1, #gridParts do
		gridParts[k].Transparency = 1
	end
end

------------------------------------------------------------------ raycasting

local function cursor()
	if touchPos then
		return touchPos
	end
	return UserInputService:GetMouseLocation()
end

local function cursorRay()
	local cam = workspace.CurrentCamera
	local pos = cursor()
	return cam:ViewportPointToRay(pos.X, pos.Y)
end

-- Where the pointer meets the horizontal plane at height y (nil when looking away from it)
local function planeHit(y)
	local ray = cursorRay()
	if math.abs(ray.Direction.Y) < 1e-4 then
		return nil
	end
	local d = (y - ray.Origin.Y) / ray.Direction.Y
	if d <= 0 or d > 600 then
		return nil
	end
	return ray.Origin + ray.Direction * d
end

local function cast(includeParts)
	local cam = workspace.CurrentCamera
	local pos = cursor()
	local ray = cam:ViewportPointToRay(pos.X, pos.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = includeParts
	return workspace:Raycast(ray.Origin, ray.Direction * 400, params)
end

local function ownerModel(inst)
	local folder = itemsFolder()
	while inst and inst.Parent and inst.Parent ~= folder do
		inst = inst.Parent
	end
	if inst and inst.Parent == folder then
		return inst
	end
	return nil
end

local function onFloor(tagName)
	local floor = Core.C.Camera.floor or 0
	local out = {}
	for _, p in ipairs(CollectionService:GetTagged(tagName)) do
		local f = p:GetAttribute("FloorIndex") or 0
		if f == floor then
			table.insert(out, p)
		end
	end
	return out
end

local function buildRequest()
	local item = Items.byId[Build.itemId]
	if not item then
		return nil
	end
	local code = PlacementLogic.PlaceCode[item.place]
	local w, h, d = item.size[1], item.size[2], item.size[3]
	local g = Build.grid
	if code == "c" then
		-- ceiling objects hang in the air: aim at their own height, so they sit under the pointer
		local f = Core.C.Camera.floor or 0
		local p = planeHit(floorY(f) + GameConfig.WallHeight - h / 2)
		if not p then
			return nil
		end
		local x, z = Grid.snapFloor(p.X, p.Z, w, d, Build.rot, g)
		return { i = item.id, x = x, z = z, r = Build.rot, f = f, s = code }
	elseif code == "f" then
		local hit = cast(onFloor("Floor"))
		local f, px, pz
		if hit then
			f = hit.Instance:GetAttribute("FloorIndex") or 0
			px, pz = hit.Position.X, hit.Position.Z
		else
			-- pointer over a wall or the sky: use the floor plane of the current storey
			f = Core.C.Camera.floor or 0
			local p = planeHit(floorY(f))
			if not p then
				return nil
			end
			px, pz = p.X, p.Z
		end
		if f < 0 then
			return nil
		end
		local x, z = Grid.snapFloor(px, pz, w, d, Build.rot, g)
		return { i = item.id, x = x, z = z, r = Build.rot, f = f, s = code }
	elseif code == "w" then
		local hit = cast(onFloor("Wall"))
		if not hit or hit.Instance:GetAttribute("Rail") then
			return nil
		end
		local f = hit.Instance:GetAttribute("FloorIndex") or 0
		local n = hit.Normal
		local alongX = math.abs(n.Z) > math.abs(n.X)
		local along = alongX and hit.Position.X or hit.Position.Z
		local a, y = Grid.snapWall(along, hit.Position.Y, w, h, g, floorY(f))
		local off = 0.4 + d / 2 + 0.05
		local x = alongX and a or hit.Position.X + n.X * off
		local z = alongX and hit.Position.Z + n.Z * off or a
		return { i = item.id, x = x, z = z, y = y, r = 0, f = f, s = code }
	elseif code == "t" then
		local folder = itemsFolder()
		if not folder then
			return nil
		end
		local hit = cast({ folder })
		local model = hit and ownerModel(hit.Instance)
		if not model then
			return nil
		end
		local kind = model:GetAttribute("Kind")
		if kind ~= "counter" and kind ~= "table" and kind ~= "booth" then
			return nil
		end
		local uid = model:GetAttribute("Uid")
		local parent = nil
		for _, e in ipairs(Core.C.Data.w("placed") or {}) do
			if e.u == uid then
				parent = e
			end
		end
		if not parent then
			return nil
		end
		local x, z = Grid.snapFloor(hit.Position.X, hit.Position.Z, w, d, Build.rot, math.min(g, 0.5))
		return { i = item.id, x = x, z = z, r = Build.rot, f = parent.f or 0, s = "t", p = uid }
	end
	return nil
end

local function sameReq(a, b)
	if not a or not b then
		return false
	end
	return a.x == b.x and a.z == b.z and a.r == b.r and a.f == b.f and a.y == b.y and a.p == b.p and a.i == b.i
end

local function step()
	if not Build.active then
		return
	end
	if not ghost then
		-- selection hover
		local folder = itemsFolder()
		if folder and not touchPos then
			local hit = cast({ folder })
			local model = hit and ownerModel(hit.Instance)
			hoverHighlight.Adornee = model
			hoverHighlight.Enabled = model ~= nil
		end
		return
	end
	local req = buildRequest()
	if not req then
		Build.valid = false
		Build.reason = "msg.place_point"
		ghost.Parent = nil
		Build.Changed:Fire()
		return
	end
	ghost.Parent = workspace.CurrentCamera
	if Build.mode == "move" then
		req.u = Build.moveUid
	end
	local item = Items.byId[req.i]
	if not sameReq(req, lastReq) or os.clock() - lastValidate > 1 then
		lastReq = req
		lastValidate = os.clock()
		local ok, reason, resolved = PlacementLogic.validate(ctx(), req)
		Build.valid = ok
		Build.reason = reason
		lastResolved = resolved
		Build.Changed:Fire()
	end
	local r = lastResolved or req
	local pos = { x = r.x, z = r.z, r = r.r or req.r, y = r.y, f = r.f or req.f, s = req.s }
	Registry.place(ghost, pos.x, worldY(pos, item), pos.z, pos.r)
	highlight.FillColor = Build.valid and Color.hex("#6DDC5A") or Color.hex("#FF3B4A")
	highlight.OutlineColor = highlight.FillColor
	drawGrid(req.x, req.z, floorY(req.f), Build.grid)
end

------------------------------------------------------------------ actions

function Build.place()
	if not ghost or not Build.valid or not lastResolved then
		if Build.reason then
			Core.C.UI.toast(Locale.t(Build.reason), "error")
		end
		return
	end
	local req = lastReq
	if Build.mode == "move" then
		NetDef.event("MoveItem"):FireServer(Build.moveUid, req)
		Build.cancel()
	else
		NetDef.event("PlaceItem"):FireServer(req, Build.mode == "inventory")
		if Build.mode == "inventory" then
			local inv = Core.C.Data.w("inventory") or {}
			if (inv[Build.itemId] or 0) <= 1 then
				Build.cancel()
			end
		end
	end
	lastReq = nil
	if Core.C.Audio then
		Core.C.Audio.play("place")
	end
end

function Build.startPlace(itemId, fromInventory)
	if not Build.active then
		Build.enter()
	end
	Build.mode = fromInventory and "inventory" or "new"
	Build.itemId = itemId
	Build.moveUid = nil
	Build.selected = nil
	lastReq, lastResolved = nil, nil
	makeGhost(itemId)
	Build.Changed:Fire()
end

function Build.startMove(uid)
	for _, e in ipairs(Core.C.Data.w("placed") or {}) do
		if e.u == uid then
			Build.mode = "move"
			Build.itemId = e.i
			Build.moveUid = uid
			Build.rot = e.r or 0
			lastReq, lastResolved = nil, nil
			makeGhost(e.i)
			Build.Changed:Fire()
			return
		end
	end
end

function Build.cancel()
	Build.mode = nil
	Build.itemId = nil
	Build.moveUid = nil
	clearGhost()
	highlight.Enabled = false
	Build.Changed:Fire()
end

function Build.rotate()
	local s = Core.C.Data.m("settings")
	local stepDeg = s and s.rot or 90
	if Build.selected and not ghost then
		-- rotate a selected object in place
		for _, e in ipairs(Core.C.Data.w("placed") or {}) do
			if e.u == Build.selected then
				local req = { i = e.i, x = e.x, z = e.z, y = e.y, f = e.f, s = e.s, p = e.p, r = Grid.nextRotation(e.r or 0, stepDeg) }
				NetDef.event("MoveItem"):FireServer(e.u, req)
			end
		end
		return
	end
	Build.rot = Grid.nextRotation(Build.rot, stepDeg)
	lastReq = nil
end

function Build.cycleGrid()
	local sizes = GameConfig.GridSizes
	local idx = table.find(sizes, Build.grid) or 1
	Build.grid = sizes[idx % #sizes + 1]
	NetDef.event("SetSetting"):FireServer("grid", Build.grid)
	lastReq = nil
	Build.Changed:Fire()
end

function Build.setGrid(g)
	Build.grid = g
	NetDef.event("SetSetting"):FireServer("grid", g)
	lastReq = nil
	Build.Changed:Fire()
end

function Build.select(uid)
	Build.selected = uid
	Build.Changed:Fire()
end

function Build.removeSelected(mode)
	if Build.selected then
		NetDef.event("RemoveItem"):FireServer(Build.selected, mode)
		Build.selected = nil
		hoverHighlight.Enabled = false
		Build.Changed:Fire()
	end
end

function Build.enter()
	if not Core.C.Data.canBuild() then
		Core.C.UI.toast(Locale.t("msg.no_permission"), "error")
		return
	end
	Build.active = true
	local s = Core.C.Data.m("settings")
	Build.grid = s and s.grid or 1
	Core.C.Camera.setBuildView(true)
	Core.C.UI.open("Build")
	Build.Changed:Fire()
end

function Build.exit()
	Build.cancel()
	Build.active = false
	Build.selected = nil
	hoverHighlight.Enabled = false
	Core.C.Camera.setBuildView(false)
	Core.C.UI.close("Build")
	Build.Changed:Fire()
end

function Build.toggle()
	if Build.active then
		Build.exit()
	else
		Build.enter()
	end
end

local function clickedGui(pos)
	local objs = player.PlayerGui:GetGuiObjectsAtPosition(pos.X, pos.Y - GuiService:GetGuiInset().Y)
	for _, o in ipairs(objs) do
		if o.Visible and o.BackgroundTransparency < 1 then
			return true
		end
	end
	return false
end

function Build.Init()
	highlight = Instance.new("Highlight")
	highlight.FillTransparency = 0.55
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Enabled = false
	highlight.Parent = player:WaitForChild("PlayerGui")
	hoverHighlight = Instance.new("Highlight")
	hoverHighlight.FillTransparency = 0.8
	hoverHighlight.FillColor = Color.hex("#FFD23B")
	hoverHighlight.OutlineColor = Color.hex("#FFD23B")
	hoverHighlight.Enabled = false
	hoverHighlight.Parent = player.PlayerGui
end

function Build.Start()
	RunService.RenderStepped:Connect(function()
		local ok, err = pcall(step)
		if not ok then
			warn("[Build] " .. tostring(err))
		end
	end)
	UserInputService.InputBegan:Connect(function(input, processed)
		if not Build.active then
			return
		end
		if input.UserInputType == Enum.UserInputType.Touch then
			if processed then
				-- joystick, buttons and panels never move the object being placed
				return
			end
			worldTouch = input
			touchPos = Vector2.new(input.Position.X, input.Position.Y + GuiService:GetGuiInset().Y)
		end
		if processed then
			return
		end
		local kc = input.KeyCode
		if kc == Enum.KeyCode.R then
			Build.rotate()
		elseif kc == Enum.KeyCode.G then
			Build.cycleGrid()
		elseif kc == Enum.KeyCode.Q then
			if ghost then
				Build.cancel()
			else
				Build.exit()
			end
		elseif kc == Enum.KeyCode.X or kc == Enum.KeyCode.Delete then
			Build.removeSelected("sell")
		elseif kc == Enum.KeyCode.F then
			Build.removeSelected("store")
		elseif kc == Enum.KeyCode.M and Build.selected then
			Build.startMove(Build.selected)
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
			if clickedGui(UserInputService:GetMouseLocation()) then
				return
			end
			if ghost then
				Build.place()
			else
				local folder = itemsFolder()
				local hit = folder and cast({ folder })
				local model = hit and ownerModel(hit.Instance)
				Build.select(model and model:GetAttribute("Uid") or nil)
			end
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 and ghost then
			Build.cancel()
		elseif input.UserInputType == Enum.UserInputType.Touch and not ghost then
			local folder = itemsFolder()
			local hit = folder and cast({ folder })
			local model = hit and ownerModel(hit.Instance)
			Build.select(model and model:GetAttribute("Uid") or nil)
			hoverHighlight.Adornee = model
			hoverHighlight.Enabled = model ~= nil
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			touchPos = nil
		elseif input.UserInputType == Enum.UserInputType.Touch and Build.active and input == worldTouch then
			touchPos = Vector2.new(input.Position.X, input.Position.Y + GuiService:GetGuiInset().Y)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input == worldTouch then
			worldTouch = nil
		end
	end)
	Core.C.Data.Changed:Connect(function(_, key)
		if key == "placed" or key == "zones" or key == "all" then
			lastReq = nil
		end
	end)
end

return Build
