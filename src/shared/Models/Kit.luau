--!nonstrict
-- Primitive helpers for procedural models. Coordinates are relative to the model's bottom center.
local Color = require(script.Parent.Parent.Util.Color)

local Kit = {}

local function apply(p, color, material, props)
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Color = Color.of(color or "#FFFFFF")
	p.Material = material or Enum.Material.SmoothPlastic
	p.CanTouch = false
	p.CastShadow = true
	if props then
		if props.collide ~= nil then
			p.CanCollide = props.collide
		end
		if props.query ~= nil then
			p.CanQuery = props.query
		end
		if props.transparency then
			p.Transparency = props.transparency
		end
		if props.reflectance then
			p.Reflectance = props.reflectance
		end
		if props.shadow == false then
			p.CastShadow = false
		end
		if props.name then
			p.Name = props.name
		end
	end
	return p
end

function Kit.model(name)
	local m = Instance.new("Model")
	m.Name = name or "Model"
	return m
end

-- Generic part with explicit size and local CFrame
function Kit.part(parent, size, cf, color, material, props)
	local p = Instance.new("Part")
	if props and props.shape then
		p.Shape = props.shape
	end
	p.Size = size
	p.CFrame = cf
	apply(p, color, material, props)
	if props and props.collide == nil and (size.X < 0.6 or size.Y < 0.6 or size.Z < 0.6) and size.Magnitude < 3 then
		p.CanCollide = false
	end
	p.Parent = parent
	return p
end

function Kit.box(parent, sx, sy, sz, x, y, z, color, material, props)
	local cf = CFrame.new(x, y, z)
	if props and props.rot then
		cf = cf * props.rot
	end
	return Kit.part(parent, Vector3.new(sx, sy, sz), cf, color, material, props)
end

-- Box defined by its bottom center (handy for stacking)
function Kit.slab(parent, sx, sy, sz, x, y0, z, color, material, props)
	return Kit.box(parent, sx, sy, sz, x, y0 + sy / 2, z, color, material, props)
end

-- Vertical cylinder: diameter d, height h, centered at x, y, z
function Kit.cyl(parent, d, h, x, y, z, color, material, props)
	props = props or {}
	props.shape = Enum.PartType.Cylinder
	local cf = CFrame.new(x, y, z) * CFrame.Angles(0, 0, math.rad(90))
	if props.rot then
		cf = CFrame.new(x, y, z) * props.rot * CFrame.Angles(0, 0, math.rad(90))
	end
	return Kit.part(parent, Vector3.new(h, d, d), cf, color, material, props)
end

-- Horizontal cylinder along X (length l) or along Z (axis = "z")
function Kit.cylH(parent, d, l, x, y, z, color, material, props, axis)
	props = props or {}
	props.shape = Enum.PartType.Cylinder
	local cf = CFrame.new(x, y, z)
	if axis == "z" then
		cf = cf * CFrame.Angles(0, math.rad(90), 0)
	end
	if props.rot then
		cf = cf * props.rot
	end
	return Kit.part(parent, Vector3.new(l, d, d), cf, color, material, props)
end

function Kit.ball(parent, d, x, y, z, color, material, props)
	props = props or {}
	props.shape = Enum.PartType.Ball
	return Kit.part(parent, Vector3.new(d, d, d), CFrame.new(x, y, z), color, material, props)
end

-- Ellipsoid-ish ball (non-uniform sizes are not allowed on Ball parts, so use a sphere mesh)
function Kit.blob(parent, sx, sy, sz, x, y, z, color, material, props)
	local p = Kit.box(parent, 1, 1, 1, x, y, z, color, material, props)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Scale = Vector3.new(sx, sy, sz)
	mesh.Parent = p
	p.Size = Vector3.new(math.max(sx, 0.05), math.max(sy, 0.05), math.max(sz, 0.05))
	mesh.Scale = Vector3.new(1, 1, 1)
	return p
end

function Kit.wedge(parent, sx, sy, sz, cf, color, material, props)
	local p = Instance.new("WedgePart")
	p.Size = Vector3.new(sx, sy, sz)
	p.CFrame = cf
	apply(p, color, material, props)
	p.Parent = parent
	return p
end

-- Text on a part face
function Kit.text(part, face, text, opts)
	opts = opts or {}
	local gui = Instance.new("SurfaceGui")
	gui.Face = face or Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = opts.pps or 50
	gui.LightInfluence = opts.glow and 0 or 1
	gui.Brightness = opts.glow and 2 or 1
	gui.AlwaysOnTop = false
	gui.Parent = part
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = opts.bg and 0 or 1
	if opts.bg then
		label.BackgroundColor3 = Color.of(opts.bg)
	end
	label.Text = text
	label.TextScaled = true
	label.TextColor3 = Color.of(opts.color or "#2B2320")
	label.FontFace = opts.font or Font.new("rbxasset://fonts/families/FredokaOne.json")
	label.TextWrapped = true
	label.AutoLocalize = false
	if opts.rotation then
		label.Rotation = opts.rotation
	end
	label.Parent = gui
	return gui, label
end

-- Lights carry the attribute NightLight so the client can switch them by time of day.
function Kit.light(part, kind, color, range, brightness, opts)
	opts = opts or {}
	local l
	if kind == "Surface" then
		l = Instance.new("SurfaceLight")
		l.Face = opts.face or Enum.NormalId.Bottom
		l.Angle = opts.angle or 90
	elseif kind == "Spot" then
		l = Instance.new("SpotLight")
		l.Face = opts.face or Enum.NormalId.Bottom
		l.Angle = opts.angle or 60
	else
		l = Instance.new("PointLight")
	end
	l.Color = Color.of(color or "#FFD9A0")
	l.Range = range or 10
	l.Brightness = brightness or 1
	l.Shadows = opts.shadows or false
	l:SetAttribute("NightLight", opts.night ~= false)
	l:SetAttribute("BaseBrightness", l.Brightness)
	l.Parent = part
	return l
end

local PARTICLES = {
	steam = { tex = "rbxasset://textures/particles/smoke_main.dds", color = "#FFFFFF", rate = 6, life = { 1.2, 2 }, speed = { 1, 2 }, size = { 0.4, 1.4 }, transp = { 0.6, 1 }, spread = 10, accel = Vector3.new(0, 1, 0) },
	smoke = { tex = "rbxasset://textures/particles/smoke_main.dds", color = "#D8D8D8", rate = 3, life = { 2, 4 }, speed = { 0.5, 1 }, size = { 1, 3 }, transp = { 0.7, 1 }, spread = 20, accel = Vector3.new(0, 0.5, 0) },
	sparkle = { tex = "rbxasset://textures/particles/sparkles_main.dds", color = "#FFE08A", rate = 0, life = { 0.6, 1 }, speed = { 2, 5 }, size = { 0.3, 0 }, transp = { 0, 1 }, spread = 180, accel = Vector3.new(0, -2, 0) },
	petals = { tex = "rbxasset://textures/particles/sparkles_main.dds", color = "#F7B7C9", rate = 2, life = { 4, 6 }, speed = { 0.5, 1 }, size = { 0.25, 0.2 }, transp = { 0.1, 0.4 }, spread = 60, accel = Vector3.new(0.3, -0.6, 0.2) },
	bubbles = { tex = "rbxasset://textures/particles/sparkles_main.dds", color = "#FFF4D6", rate = 5, life = { 0.4, 0.8 }, speed = { 0.5, 1 }, size = { 0.15, 0.05 }, transp = { 0.3, 1 }, spread = 30, accel = Vector3.new(0, 1, 0) },
	water = { tex = "rbxasset://textures/particles/smoke_main.dds", color = "#CFE8F5", rate = 12, life = { 0.6, 1 }, speed = { 3, 5 }, size = { 0.3, 0.8 }, transp = { 0.5, 1 }, spread = 8, accel = Vector3.new(0, -10, 0) },
	snow = { tex = "rbxasset://textures/particles/sparkles_main.dds", color = "#FFFFFF", rate = 20, life = { 6, 9 }, speed = { 1, 2 }, size = { 0.25, 0.2 }, transp = { 0, 0.3 }, spread = 40, accel = Vector3.new(0.2, -1, 0) },
}

function Kit.particles(part, preset, overrides)
	local p = PARTICLES[preset] or PARTICLES.steam
	overrides = overrides or {}
	local e = Instance.new("ParticleEmitter")
	e.Texture = p.tex
	e.Color = ColorSequence.new(Color.of(overrides.color or p.color))
	e.Rate = overrides.rate or p.rate
	e.Lifetime = NumberRange.new(p.life[1], p.life[2])
	e.Speed = NumberRange.new(p.speed[1], p.speed[2])
	e.Size = NumberSequence.new(p.size[1], p.size[2])
	e.Transparency = NumberSequence.new(p.transp[1], p.transp[2])
	e.SpreadAngle = Vector2.new(p.spread, p.spread)
	e.Acceleration = p.accel
	e.LightEmission = overrides.glow or 0
	e.LightInfluence = 1
	e.Enabled = overrides.enabled ~= false
	e.Parent = part
	return e
end

function Kit.attach(part, name, cf)
	local a = Instance.new("Attachment")
	a.Name = name
	a.CFrame = cf or CFrame.new()
	a.Parent = part
	return a
end

-- Adds the invisible Root (footprint box) and sets PrimaryPart. size = Vector3 (w, h, d)
-- Optional detail group of a placeable model. Registry.build keeps it only when the matching
-- renovation style is owned, so the same builder makes the plain and the detailed look.
function Kit.detail(model, key)
	local name = "Detail_" .. key
	local d = model:FindFirstChild(name)
	if not d then
		d = Instance.new("Model")
		d.Name = name
		d.Parent = model
	end
	return d
end

function Kit.finish(model, size)
	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = size
	root.CFrame = CFrame.new(0, size.Y / 2, 0)
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false
	root.CanQuery = false
	root.CanTouch = false
	root.CastShadow = false
	root.Parent = model
	model.PrimaryPart = root
	return root
end

-- Rows of small boxes (e.g. tiles, slats) along X
function Kit.slats(parent, count, sx, sy, sz, x0, x1, y, z, color, material, props)
	local out = {}
	if count <= 1 then
		table.insert(out, Kit.box(parent, sx, sy, sz, (x0 + x1) / 2, y, z, color, material, props))
		return out
	end
	for i = 0, count - 1 do
		local x = x0 + (x1 - x0) * i / (count - 1)
		table.insert(out, Kit.box(parent, sx, sy, sz, x, y, z, color, material, props))
	end
	return out
end

return Kit
