--!nonstrict
-- Model registry: id -> builder. Models in ReplicatedStorage.AssetOverrides with the same name
-- replace the procedural version (they are scaled to fit the configured size).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = require(script.Parent.Kit)
local Items = require(script.Parent.Parent.Config.Items)

local Registry = {}
local builders = {}
local foodBuilders = {}
Registry.Food = {}

function Registry.register(id, fn)
	builders[id] = fn
end

function Registry.has(id)
	return builders[id] ~= nil
end

local function override(id)
	local folder = ReplicatedStorage:FindFirstChild("AssetOverrides")
	local m = folder and folder:FindFirstChild(id)
	if m and m:IsA("Model") then
		return m:Clone()
	end
	return nil
end

local function fitOverride(model, size)
	local cf, bbox = model:GetBoundingBox()
	local scale = math.min(size.X / math.max(bbox.X, 0.01), size.Y / math.max(bbox.Y, 0.01), size.Z / math.max(bbox.Z, 0.01))
	if scale > 0 and math.abs(scale - 1) > 0.02 then
		model:ScaleTo(model:GetScale() * scale)
		cf, bbox = model:GetBoundingBox()
	end
	-- move so the bottom center sits at the origin
	local offset = CFrame.new(0, bbox.Y / 2, 0) * cf:Inverse()
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CFrame = offset * d.CFrame
		end
	end
	local old = model:FindFirstChild("Root")
	if old then
		old:Destroy()
	end
	Kit.finish(model, size)
	return model
end

-- Builds the model of a placeable item; returns a Model whose Root is the footprint box,
-- bottom center at the origin, front facing -Z. opts.styles: owned renovation styles.
function Registry.build(id, opts)
	local item = Items.byId[id]
	local size = item and Vector3.new(item.size[1], item.size[2], item.size[3]) or Vector3.new(2, 2, 2)
	local m = override(id)
	if m then
		m.Name = id
		return fitOverride(m, size)
	end
	m = Kit.model(id)
	local fn = builders[id]
	if fn then
		local ok, err = pcall(fn, m, item, opts or {})
		if not ok then
			warn("[Models] builder failed for " .. id .. ": " .. tostring(err))
			m:ClearAllChildren()
			Kit.box(m, size.X, size.Y, size.Z, 0, size.Y / 2, 0, "#C89F6E", Enum.Material.Wood)
		end
	else
		Kit.box(m, size.X, size.Y, size.Z, 0, size.Y / 2, 0, "#C89F6E", Enum.Material.Wood)
	end
	if not m:FindFirstChild("Root") then
		Kit.finish(m, size)
	end
	-- opts.styles = set of owned renovation styles; without it every detail is kept
	local styles = opts and opts.styles
	if styles then
		for _, child in ipairs(m:GetChildren()) do
			local key = string.match(child.Name, "^Detail_(.+)$")
			if key and not styles[key] then
				child:Destroy()
			end
		end
	end
	return m
end

-- Food: Registry.dish(recipeId, opts), Registry.ingredient(id), Registry.box(id, count)
function Registry.registerFood(name, fn)
	foodBuilders[name] = fn
end

function Registry.food(name, ...)
	local fn = foodBuilders[name]
	if fn then
		return fn(...)
	end
	local m = Kit.model(name)
	Kit.box(m, 0.8, 0.4, 0.8, 0, 0.2, 0, "#F7F5F0")
	Kit.finish(m, Vector3.new(0.8, 0.4, 0.8))
	return m
end

-- Loads every builder module once.
local loaded = false
function Registry.load()
	if loaded then
		return
	end
	loaded = true
	for _, mod in ipairs(script.Parent.Builders:GetChildren()) do
		if mod:IsA("ModuleScript") then
			local ok, fn = pcall(require, mod)
			if ok and type(fn) == "function" then
				fn(Registry)
			else
				warn("[Models] could not load " .. mod.Name .. ": " .. tostring(fn))
			end
		end
	end
end

-- Moves a model so its Root sits at (x, y floor level, z) with rotation r (degrees)
function Registry.place(model, x, y, z, r)
	local root = model.PrimaryPart
	local h = root and root.Size.Y or 0
	model:PivotTo(CFrame.new(x, y + h / 2, z) * CFrame.Angles(0, math.rad(r or 0), 0))
end

return Registry
