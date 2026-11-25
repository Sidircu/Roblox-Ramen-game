--!nonstrict
-- 3D pictures for catalog and shop cards: the real model of an object or a dish shown in a
-- ViewportFrame, seen from the front, a little from above. Each model is built once and copied for
-- every card; with low graphics (Settings) or when a model cannot be built, the card keeps its
-- emoji instead.
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Registry = require(Shared.Models.Registry)
local Core = require(script.Parent.Parent.Core)

local Thumbs = {}
local cache = {}

-- what a picture does not need: lights, particles, sounds, labels and click targets
local STRIP = { "Light", "ParticleEmitter", "Sound", "BillboardGui", "SurfaceGui", "ProximityPrompt", "ClickDetector", "Beam", "Trail" }

local function strip(m)
	for _, d in ipairs(m:GetDescendants()) do
		for _, class in ipairs(STRIP) do
			if d:IsA(class) then
				d:Destroy()
				break
			end
		end
	end
end

-- the model of `kind` ("item" or "dish") and `id`, built once; false when it cannot be built
local function source(kind, id)
	local key = kind .. ":" .. id
	if cache[key] == nil then
		local ok, m = pcall(function()
			if kind == "item" then
				return Registry.build(id, { styles = {} })
			end
			return Registry.food("dish", id)
		end)
		if ok and m then
			strip(m)
			cache[key] = m
		else
			cache[key] = false
		end
	end
	return cache[key]
end

function Thumbs.enabled()
	local s = Core.C.Data and Core.C.Data.m("settings")
	return not (s and s.lowGfx)
end

-- Adds a ViewportFrame with the model to `parent` (props: Size, Position, AnchorPoint, ZIndex).
-- Returns the frame, or nil: then the caller shows its emoji.
function Thumbs.add(parent, kind, id, props)
	if not Thumbs.enabled() then
		return nil
	end
	local src = source(kind, id)
	if not src then
		return nil
	end
	local vf = Instance.new("ViewportFrame")
	vf.Name = "Thumb"
	vf.BackgroundTransparency = 1
	vf.Size = props.Size or UDim2.fromScale(1, 1)
	vf.Position = props.Position or UDim2.new()
	vf.AnchorPoint = props.AnchorPoint or Vector2.new()
	vf.ZIndex = props.ZIndex or 1
	vf.ImageTransparency = props.transparency or 0
	vf.Ambient = Color3.fromRGB(176, 164, 150)
	vf.LightColor = Color3.fromRGB(255, 242, 224)
	vf.LightDirection = Vector3.new(-0.5, -1, -0.7)
	local m = src:Clone()
	m.Parent = vf
	local cam = Instance.new("Camera")
	cam.FieldOfView = 30
	cam.Parent = vf
	vf.CurrentCamera = cam
	-- frame the whole model: its bounding sphere fills the height of the picture
	local box, size = m:GetBoundingBox()
	local radius = math.max(size.Magnitude / 2, 0.3)
	local dist = radius / math.sin(math.rad(cam.FieldOfView / 2)) * (props.zoom or 1)
	local dir = Vector3.new(-0.42, -0.4, 0.81).Unit -- from the front (-Z), right and above
	cam.CFrame = CFrame.lookAt(box.Position - dir * dist, box.Position)
	vf.Parent = parent
	return vf
end

-- Same as add, a few per frame so a long catalog opens at once: the emoji label `fallback` shows
-- until the picture is ready, then hides. Cards that were closed meanwhile are skipped.
local queue = {}
local running = false
function Thumbs.later(parent, kind, id, props, fallback)
	if not Thumbs.enabled() then
		return
	end
	table.insert(queue, { parent = parent, kind = kind, id = id, props = props, fallback = fallback })
	if running then
		return
	end
	running = true
	task.spawn(function()
		local built = 0
		while #queue > 0 do
			local job = table.remove(queue, 1)
			if job.parent.Parent then
				local vf = Thumbs.add(job.parent, job.kind, job.id, job.props)
				if vf and job.fallback then
					job.fallback.Visible = false
				end
				built += 1
				if built % 4 == 0 then
					task.wait()
				end
			end
		end
		running = false
	end)
end

return Thumbs
