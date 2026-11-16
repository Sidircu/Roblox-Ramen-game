--!nonstrict
-- Detailed NPC looks built on the R15 rig: per-part clothing colours, layered clothes (sleeves,
-- collars, jackets, ties, skirts, shoes), voluminous hair styles, accessories and a procedural
-- face (eyes with highlights, brows, mouth, blush) whose expression follows the customer's mood.
-- Everything is welded to the rig parts, so it follows the animations. Sizes are taken from the
-- real parts, so different body scales (children, tall adults) still fit.
local Kit = require(script.Parent.Parent.Kit)
local P = require(script.Parent.Parent.Palette)
local Color = require(script.Parent.Parent.Parent.Util.Color)
local M = P.M

local People = {}

local function c(hex)
	return Color.hex(hex)
end

local function nc(extra)
	local p = { collide = false, shadow = false }
	if extra then
		for k, v in pairs(extra) do
			p[k] = v
		end
	end
	return p
end

local function weld(part, to, parent)
	part.Anchored = false
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Massless = true
	local w = Instance.new("WeldConstraint")
	w.Part0 = to
	w.Part1 = part
	w.Parent = part
	part.Parent = parent or to.Parent
	return part
end

-- Box welded to `base`, offset in base space
local function add(base, size, offset, color, mat, props, parent)
	local p = Kit.part(nil, size, base.CFrame * offset, color, mat or M.fabric, props or nc())
	return weld(p, base, parent)
end

-- Ellipsoid welded to `base`
local function blob(base, size, offset, color, mat, props, parent)
	local p = Kit.blob(nil, size.X, size.Y, size.Z, 0, 0, 0, color, mat or M.smooth, props or nc())
	p.CFrame = base.CFrame * offset
	return weld(p, base, parent)
end

local function cyl(base, d, h, offset, color, mat, props, parent)
	local pr = nc(props)
	pr.shape = Enum.PartType.Cylinder
	local p = Kit.part(nil, Vector3.new(h, d, d), base.CFrame * offset * CFrame.Angles(0, 0, math.rad(90)), color, mat or M.fabric, pr)
	return weld(p, base, parent)
end

local function ball(base, d, offset, color, mat, props, parent)
	local pr = nc(props)
	pr.shape = Enum.PartType.Ball
	local p = Kit.part(nil, Vector3.new(d, d, d), base.CFrame * offset, color, mat or M.smooth, pr)
	return weld(p, base, parent)
end

local function body(character)
	local function g(n)
		return character:FindFirstChild(n)
	end
	return {
		head = g("Head"), ut = g("UpperTorso") or g("Torso"), lt = g("LowerTorso") or g("Torso"),
		lua = g("LeftUpperArm"), lla = g("LeftLowerArm"), lh = g("LeftHand"),
		rua = g("RightUpperArm"), rla = g("RightLowerArm"), rh = g("RightHand"),
		lul = g("LeftUpperLeg"), lll = g("LeftLowerLeg"), lf = g("LeftFoot"),
		rul = g("RightUpperLeg"), rll = g("RightLowerLeg"), rf = g("RightFoot"),
	}
end

-- Visual size of the head (classic heads are a 2x1x1 part with a scaled Head mesh)
local function headSize(head)
	local mesh = head:FindFirstChildOfClass("SpecialMesh")
	if mesh and mesh.MeshType == Enum.MeshType.Head then
		return mesh.Scale
	end
	return head.Size
end

local function setColor(part, color)
	if part then
		part.Color = color
	end
end

-- Base colours of the body parts: skin, top, sleeves, legs, shoes
local function paint(b, skin, top, sleeves, legs, shoes)
	-- the rig's BodyColors would put the description colours back, the parts are coloured here
	local model = b.head and b.head.Parent
	local bc = model and model:FindFirstChildOfClass("BodyColors")
	if bc then
		bc:Destroy()
	end
	setColor(b.head, skin)
	setColor(b.lh, skin)
	setColor(b.rh, skin)
	setColor(b.ut, top)
	setColor(b.lt, legs)
	for _, k in ipairs({ "lua", "lla", "rua", "rla" }) do
		setColor(b[k], sleeves)
	end
	for _, k in ipairs({ "lul", "lll", "rul", "rll" }) do
		setColor(b[k], legs)
	end
	setColor(b.lf, shoes)
	setColor(b.rf, shoes)
end

---------------------------------------------------------------------------------------------------
-- Face
---------------------------------------------------------------------------------------------------

-- Depth of the front of the head at horizontal offset x. Heads range from rounded cylinders
-- (classic mesh) to rounded boxes, so follow half of the cylinder curve: features sit on the
-- surface of both shapes.
local function front(hs, x)
	local r = math.min(hs.X, hs.Z) / 2
	local curve = r - math.sqrt(math.max(r * r - x * x, 0.01))
	return -r + curve * 0.5 - 0.014
end

-- Procedural face. Mood variants are kept in the Face folder and shown with People.setMood.
function People.face(character, r, opts)
	opts = opts or {}
	local head = character:FindFirstChild("Head")
	if not head then
		return
	end
	for _, d in ipairs(head:GetChildren()) do
		if d:IsA("Decal") then
			d:Destroy()
		end
	end
	local folder = Instance.new("Folder")
	folder.Name = "Face"
	folder.Parent = character
	local hs = headSize(head)
	local k = hs.X / 1.25
	local eyeY = hs.Y * 0.04
	local eyeX = hs.X * 0.17
	local eyeColor = opts.eyes or c("#2B2320")
	local big = r:NextNumber() < 0.5
	for _, s in ipairs({ -1, 1 }) do
		local x = s * eyeX
		local z = front(hs, x)
		blob(head, Vector3.new(0.13 * k, (big and 0.2 or 0.15) * k, 0.06), CFrame.new(x, eyeY, z), eyeColor, M.smooth, nc({ reflectance = 0.1 }), folder)
		ball(head, 0.05 * k, CFrame.new(x + 0.025 * k, eyeY + 0.04 * k, z - 0.025), P.white, M.neon, nc(), folder)
		-- brows: normal and angry variants
		local by = eyeY + 0.17 * k
		local bz = front(hs, x) + 0.005
		local n = add(head, Vector3.new(0.17 * k, 0.035 * k, 0.03), CFrame.new(x, by, bz) * CFrame.Angles(0, 0, math.rad(s * 6)), opts.brows or c("#2E2018"), M.smooth, nc(), folder)
		n:SetAttribute("Mood", "brow_calm")
		local a = add(head, Vector3.new(0.17 * k, 0.04 * k, 0.03), CFrame.new(x, by - 0.02 * k, bz) * CFrame.Angles(0, 0, math.rad(-s * 22)), opts.brows or c("#2E2018"), M.smooth, nc({ transparency = 1 }), folder)
		a:SetAttribute("Mood", "brow_angry")
		-- blush
		blob(head, Vector3.new(0.16 * k, 0.07 * k, 0.03), CFrame.new(s * hs.X * 0.27, eyeY - 0.12 * k, front(hs, s * hs.X * 0.27) + 0.01), c("#F2A0A0"), M.smooth, nc({ transparency = 0.45 }), folder)
	end
	-- mouths: smile (calm), open smile (happy), flat line (worried), frown (angry)
	local mz = front(hs, 0)
	local my = eyeY - 0.22 * k
	local function arc(mood, curve, visible)
		for i = -1, 1 do
			local p = add(head, Vector3.new(0.09 * k, 0.03 * k, 0.03), CFrame.new(i * 0.075 * k, my + math.abs(i) * curve * k, mz) * CFrame.Angles(0, 0, math.rad(-i * curve * 300)), c("#5A2A2A"), M.smooth, nc({ transparency = visible and 0 or 1 }), folder)
			p:SetAttribute("Mood", mood)
		end
	end
	arc("calm", 0.025, true)
	arc("angry", -0.03, false)
	local flat = add(head, Vector3.new(0.18 * k, 0.03 * k, 0.03), CFrame.new(0, my, mz), c("#5A2A2A"), M.smooth, nc({ transparency = 1 }), folder)
	flat:SetAttribute("Mood", "worried")
	local open = blob(head, Vector3.new(0.2 * k, 0.12 * k, 0.04), CFrame.new(0, my, mz), c("#6A2228"), M.smooth, nc({ transparency = 1 }), folder)
	open:SetAttribute("Mood", "happy")
	local tongue = blob(head, Vector3.new(0.1 * k, 0.05 * k, 0.04), CFrame.new(0, my - 0.03 * k, mz - 0.005), c("#E8707A"), M.smooth, nc({ transparency = 1 }), folder)
	tongue:SetAttribute("Mood", "happy")
	-- nose hint
	blob(head, Vector3.new(0.06 * k, 0.05 * k, 0.04), CFrame.new(0, eyeY - 0.09 * k, mz - 0.01), opts.skin and opts.skin:Lerp(c("#C88A6A"), 0.35) or c("#E8B996"), M.smooth, nc(), folder)
	character:SetAttribute("Mood", "calm")
end

-- mood: "calm" | "happy" | "worried" | "angry". Mouth parts carry the mood name, brows carry
-- "brow_calm" / "brow_angry".
function People.setMood(character, mood)
	local folder = character:FindFirstChild("Face")
	if not folder or character:GetAttribute("Mood") == mood then
		return
	end
	character:SetAttribute("Mood", mood)
	local brow = mood == "angry" and "brow_angry" or "brow_calm"
	for _, p in ipairs(folder:GetChildren()) do
		local m = p:GetAttribute("Mood")
		if m then
			p.Transparency = (m == mood or m == brow) and 0 or 1
		end
	end
end

---------------------------------------------------------------------------------------------------
-- Hair and hats
---------------------------------------------------------------------------------------------------

-- style: short | bob | long | ponytail | bun | spiky | bald | twin
function People.hair(character, color, style)
	local head = character:FindFirstChild("Head")
	if not head then
		return
	end
	local hs = headSize(head)
	local W, H, D = hs.X, hs.Y, hs.Z
	local sheen = nc({ reflectance = 0.08 })
	if style ~= "bald" then
		-- cap of hair over the top and back of the head
		blob(head, Vector3.new(W * 1.1, H * 0.66, D * 1.12), CFrame.new(0, H * 0.22, D * 0.05), color, M.smooth, sheen)
		blob(head, Vector3.new(W * 1.06, H * 0.8, D * 0.62), CFrame.new(0, -H * 0.02, D * 0.27), color, M.smooth, sheen)
		-- fringe across the forehead
		local n = style == "spiky" and 3 or 4
		for i = 1, n do
			local t = (i - 0.5) / n - 0.5
			local x = t * W * 0.8
			blob(head, Vector3.new(W * 0.32, H * 0.24, D * 0.16), CFrame.new(x, H * 0.27, front(hs, x) + D * 0.08) * CFrame.Angles(math.rad(-15), 0, math.rad(t * 40)), color, M.smooth, sheen)
		end
	else
		-- balding: hair around the sides and back only
		blob(head, Vector3.new(W * 1.06, H * 0.42, D * 0.6), CFrame.new(0, -H * 0.02, D * 0.27), color, M.smooth, sheen)
		for _, s in ipairs({ -1, 1 }) do
			blob(head, Vector3.new(W * 0.18, H * 0.38, D * 0.6), CFrame.new(s * W * 0.5, -H * 0.02, D * 0.05), color, M.smooth, sheen)
		end
	end
	if style == "bob" or style == "long" or style == "twin" then
		for _, s in ipairs({ -1, 1 }) do
			blob(head, Vector3.new(W * 0.24, H * (style == "long" and 1.15 or 0.75), D * 0.7), CFrame.new(s * W * 0.5, -H * (style == "long" and 0.3 or 0.12), D * 0.05), color, M.smooth, sheen)
		end
	end
	if style == "long" then
		add(head, Vector3.new(W * 1.0, H * 1.2, D * 0.25), CFrame.new(0, -H * 0.55, D * 0.52), color, M.smooth, sheen)
	elseif style == "ponytail" then
		ball(head, W * 0.28, CFrame.new(0, H * 0.1, D * 0.6), c("#B3262E"), M.fabric)
		blob(head, Vector3.new(W * 0.34, H * 0.9, D * 0.32), CFrame.new(0, -H * 0.35, D * 0.7) * CFrame.Angles(math.rad(12), 0, 0), color, M.smooth, sheen)
	elseif style == "bun" then
		ball(head, W * 0.5, CFrame.new(0, H * 0.55, D * 0.28), color, M.smooth, sheen)
		add(head, Vector3.new(0.04, 0.04, W * 0.7), CFrame.new(W * 0.08, H * 0.62, D * 0.28) * CFrame.Angles(0, math.rad(60), 0), P.lacquer, M.smooth)
	elseif style == "spiky" then
		for i = -2, 2 do
			local sp = Kit.wedge(nil, W * 0.18, H * 0.4, D * 0.3, head.CFrame * CFrame.new(i * W * 0.17, H * 0.6, D * 0.05) * CFrame.Angles(math.rad(-10), 0, math.rad(i * 12)), color, M.smooth, nc())
			weld(sp, head)
		end
	elseif style == "twin" then
		for _, s in ipairs({ -1, 1 }) do
			ball(head, W * 0.2, CFrame.new(s * W * 0.55, H * 0.15, D * 0.25), c("#F25A9A"), M.fabric)
			blob(head, Vector3.new(W * 0.3, H * 0.75, D * 0.3), CFrame.new(s * W * 0.68, -H * 0.2, D * 0.3), color, M.smooth, sheen)
		end
	end
end

-- kind: cap | bucket | chef | hachimaki | bandana | sunhat | flatcap | fedora | school
function People.hat(character, kind, color)
	local head = character:FindFirstChild("Head")
	if not head then
		return
	end
	local hs = headSize(head)
	local W, H, D = hs.X, hs.Y, hs.Z
	if kind == "cap" then
		blob(head, Vector3.new(W * 1.14, H * 0.62, D * 1.16), CFrame.new(0, H * 0.28, D * 0.02), color, M.fabric)
		add(head, Vector3.new(W * 0.85, 0.06, D * 0.55), CFrame.new(0, H * 0.24, -D * 0.68) * CFrame.Angles(math.rad(-8), 0, 0), color, M.fabric)
		ball(head, 0.12, CFrame.new(0, H * 0.6, 0), color:Lerp(P.black, 0.3), M.fabric)
		add(head, Vector3.new(W * 0.3, H * 0.18, 0.02), CFrame.new(0, H * 0.4, front(hs, 0) - 0.02), P.white, M.fabric)
	elseif kind == "bucket" or kind == "school" then
		local col = kind == "school" and c("#F4CF3B") or color
		cyl(head, W * 1.2, H * 0.42, CFrame.new(0, H * 0.42, 0), col, M.fabric)
		cyl(head, W * 1.7, 0.06, CFrame.new(0, H * 0.24, 0) * CFrame.Angles(math.rad(-6), 0, 0), col, M.fabric)
		cyl(head, W * 1.22, H * 0.08, CFrame.new(0, H * 0.32, 0), col:Lerp(P.black, 0.35), M.fabric)
	elseif kind == "chef" then
		cyl(head, W * 1.12, H * 0.25, CFrame.new(0, H * 0.45, 0), P.white, M.fabric)
		for i = 0, 5 do
			local a = i * math.pi / 3
			blob(head, Vector3.new(W * 0.45, H * 0.8, W * 0.45), CFrame.new(math.cos(a) * W * 0.28, H * 0.95, math.sin(a) * W * 0.28), P.white, M.fabric)
		end
		blob(head, Vector3.new(W * 0.9, H * 0.4, W * 0.9), CFrame.new(0, H * 1.28, 0), P.white, M.fabric)
	elseif kind == "hachimaki" or kind == "bandana" then
		local col = kind == "bandana" and (color or P.indigo) or P.white
		cyl(head, W * 1.1, H * 0.2, CFrame.new(0, H * 0.3, 0), col, M.fabric)
		if kind == "hachimaki" then
			cyl(head, H * 0.17, 0.02, CFrame.new(0, H * 0.3, -D * 0.56) * CFrame.Angles(math.rad(90), 0, 0), P.lacquer, M.fabric)
		end
		-- knot and tails at the back
		ball(head, H * 0.2, CFrame.new(0, H * 0.3, D * 0.58), col, M.fabric)
		for _, s in ipairs({ -1, 1 }) do
			add(head, Vector3.new(0.12, H * 0.4, 0.04), CFrame.new(s * 0.08, H * 0.12, D * 0.62) * CFrame.Angles(0, 0, math.rad(s * 18)), col, M.fabric)
		end
		if kind == "bandana" then
			blob(head, Vector3.new(W * 1.1, H * 0.55, D * 1.12), CFrame.new(0, H * 0.32, D * 0.04), col, M.fabric)
			for k = 0, 5 do
				ball(head, 0.06, CFrame.new(-W * 0.3 + (k % 3) * W * 0.3, H * 0.5 + math.floor(k / 3) * 0.12, -D * 0.3 + math.floor(k / 3) * D * 0.2), P.white, M.fabric)
			end
		end
	elseif kind == "sunhat" then
		cyl(head, W * 2.0, 0.06, CFrame.new(0, H * 0.3, 0), color, M.fabric)
		cyl(head, W * 1.15, H * 0.4, CFrame.new(0, H * 0.48, 0), color, M.fabric)
		cyl(head, W * 1.17, H * 0.1, CFrame.new(0, H * 0.33, 0), P.lacquer, M.fabric)
	elseif kind == "flatcap" then
		blob(head, Vector3.new(W * 1.2, H * 0.4, D * 1.25), CFrame.new(0, H * 0.4, -D * 0.05), color, M.fabric)
		add(head, Vector3.new(W * 0.8, 0.06, D * 0.35), CFrame.new(0, H * 0.32, -D * 0.62), color, M.fabric)
	elseif kind == "fedora" then
		cyl(head, W * 1.75, 0.06, CFrame.new(0, H * 0.32, 0), color, M.fabric)
		cyl(head, W * 1.12, H * 0.5, CFrame.new(0, H * 0.58, 0), color, M.fabric)
		cyl(head, W * 1.14, H * 0.1, CFrame.new(0, H * 0.4, 0), P.gold, M.fabric)
	end
end

function People.glasses(character, color, sun)
	local head = character:FindFirstChild("Head")
	if not head then
		return
	end
	local hs = headSize(head)
	local k = hs.X / 1.25
	local y = hs.Y * 0.04
	for _, s in ipairs({ -1, 1 }) do
		local x = s * hs.X * 0.17
		local z = front(hs, x) - 0.035
		add(head, Vector3.new(0.3 * k, (sun and 0.2 or 0.24) * k, 0.03), CFrame.new(x, y, z), sun and P.black or c("#BFE0F0"), M.glass, nc({ transparency = sun and 0.05 or 0.6, reflectance = 0.3 }))
		add(head, Vector3.new(0.32 * k, 0.03, 0.035), CFrame.new(x, y + 0.13 * k, z), color or P.black, M.metal)
		add(head, Vector3.new(0.03, 0.03, hs.Z * 0.6), CFrame.new(s * hs.X * 0.5, y + 0.1 * k, -hs.Z * 0.15), color or P.black, M.metal)
	end
	add(head, Vector3.new(0.1 * k, 0.03, 0.03), CFrame.new(0, y + 0.08 * k, front(hs, 0) - 0.04), color or P.black, M.metal)
end

---------------------------------------------------------------------------------------------------
-- Clothes
---------------------------------------------------------------------------------------------------

-- Short sleeves over the upper arms (arms keep the skin colour)
local function sleeves(b, color, long)
	for _, k in ipairs({ "lua", "rua" }) do
		local a = b[k]
		if a then
			local s = a.Size
			add(a, Vector3.new(s.X * 1.1, s.Y * (long and 1.02 or 0.6), s.Z * 1.1), CFrame.new(0, s.Y * (long and 0 or 0.22), 0), color, M.fabric)
		end
	end
end

local function cuffs(b, color)
	for _, k in ipairs({ "lla", "rla" }) do
		local a = b[k]
		if a then
			local s = a.Size
			add(a, Vector3.new(s.X * 1.08, s.Y * 0.14, s.Z * 1.08), CFrame.new(0, -s.Y * 0.43, 0), color, M.fabric)
		end
	end
end

local function hems(b, color)
	for _, k in ipairs({ "lll", "rll" }) do
		local l = b[k]
		if l then
			local s = l.Size
			add(l, Vector3.new(s.X * 1.08, s.Y * 0.12, s.Z * 1.08), CFrame.new(0, -s.Y * 0.44, 0), color, M.fabric)
		end
	end
end

local function belt(b, color, buckle)
	local t = b.lt
	if not t then
		return
	end
	local s = t.Size
	add(t, Vector3.new(s.X * 1.03, s.Y * 0.45, s.Z * 1.05), CFrame.new(0, s.Y * 0.25, 0), color or c("#2A2018"), M.leather)
	add(t, Vector3.new(0.22, s.Y * 0.4, 0.04), CFrame.new(0, s.Y * 0.25, -s.Z * 0.54), buckle or P.metal, M.metal, nc({ reflectance = 0.3 }))
end

-- shoes: "sneaker" | "dress" | "sandal" | "boot" | "geta"
local function shoes(b, kind, color)
	for _, k in ipairs({ "lf", "rf" }) do
		local f = b[k]
		if f then
			local s = f.Size
			if kind == "geta" then
				add(f, Vector3.new(s.X * 0.95, 0.08, s.Z * 1.15), CFrame.new(0, -s.Y * 0.5 - 0.1, -0.05), P.hinoki, M.wood)
				for _, z in ipairs({ -s.Z * 0.3, s.Z * 0.3 }) do
					add(f, Vector3.new(s.X * 0.9, 0.12, 0.08), CFrame.new(0, -s.Y * 0.5 - 0.2, z), P.hinoki, M.wood)
				end
				add(f, Vector3.new(s.X * 0.7, 0.05, 0.05), CFrame.new(0, 0, -s.Z * 0.2), P.lacquer, M.fabric)
			else
				local sole = kind == "sneaker" and P.white or (kind == "sandal" and P.wood or P.black)
				local up = color or (kind == "dress" and c("#1A1414") or P.white)
				add(f, Vector3.new(s.X * 1.08, s.Y * 1.05, s.Z * 1.18), CFrame.new(0, 0.02, -s.Z * 0.06), up, kind == "dress" and M.leather or M.fabric, nc({ reflectance = kind == "dress" and 0.2 or 0 }))
				add(f, Vector3.new(s.X * 1.12, 0.08, s.Z * 1.22), CFrame.new(0, -s.Y * 0.5, -s.Z * 0.06), sole, M.smooth)
				if kind == "sneaker" then
					add(f, Vector3.new(s.X * 0.6, 0.03, s.Z * 0.35), CFrame.new(0, s.Y * 0.55, -s.Z * 0.2), P.white, M.fabric)
				elseif kind == "boot" then
					local l = k == "lf" and b.lll or b.rll
					if l then
						add(l, Vector3.new(l.Size.X * 1.1, l.Size.Y * 0.4, l.Size.Z * 1.1), CFrame.new(0, -l.Size.Y * 0.3, 0), up, M.leather)
					end
				end
			end
		end
	end
end

-- Collar ring at the neck
local function collar(b, color, white)
	local t = b.ut
	if not t then
		return
	end
	local s = t.Size
	add(t, Vector3.new(s.X * 0.42, 0.14, s.Z * 0.85), CFrame.new(0, s.Y * 0.5, 0), color, M.fabric)
	if white then
		for _, side in ipairs({ -1, 1 }) do
			add(t, Vector3.new(0.3, 0.22, 0.04), CFrame.new(side * 0.17, s.Y * 0.42, -s.Z * 0.51) * CFrame.Angles(0, 0, math.rad(side * 30)), P.white, M.fabric)
		end
	end
end

-- Logo / print on the chest
local function chestPrint(b, color, shape)
	local t = b.ut
	if not t then
		return
	end
	local s = t.Size
	if shape == "circle" then
		cyl(t, s.X * 0.32, 0.02, CFrame.new(0, s.Y * 0.1, -s.Z * 0.51) * CFrame.Angles(math.rad(90), 0, 0), color, M.fabric)
	elseif shape == "stripe" then
		add(t, Vector3.new(s.X * 1.01, s.Y * 0.16, s.Z * 1.01), CFrame.new(0, s.Y * 0.05, 0), color, M.fabric)
	else
		add(t, Vector3.new(s.X * 0.4, s.Y * 0.28, 0.02), CFrame.new(0, s.Y * 0.08, -s.Z * 0.51), color, M.fabric)
	end
end

local function hoodie(b, color)
	local t = b.ut
	local s = t.Size
	-- hood behind the neck, drawstrings, front pocket, ribbed cuffs
	blob(t, Vector3.new(s.X * 0.75, s.Y * 0.4, s.Z * 0.6), CFrame.new(0, s.Y * 0.45, s.Z * 0.32), color, M.fabric)
	for _, side in ipairs({ -1, 1 }) do
		add(t, Vector3.new(0.04, s.Y * 0.35, 0.04), CFrame.new(side * 0.15, s.Y * 0.22, -s.Z * 0.52), P.white, M.fabric)
	end
	add(t, Vector3.new(s.X * 0.6, s.Y * 0.3, 0.05), CFrame.new(0, -s.Y * 0.3, -s.Z * 0.52), color:Lerp(P.black, 0.12), M.fabric)
	cuffs(b, color:Lerp(P.black, 0.2))
end

-- Suit jacket: lapels, tie, white shirt strip, buttons and pocket square
local function suit(b, jacket, tie, square)
	local t = b.ut
	local s = t.Size
	add(t, Vector3.new(s.X * 0.26, s.Y * 0.95, 0.02), CFrame.new(0, s.Y * 0.02, -s.Z * 0.505), P.white, M.fabric)
	add(t, Vector3.new(0.16, s.Y * 0.62, 0.03), CFrame.new(0, s.Y * 0.08, -s.Z * 0.52), tie, M.fabric)
	add(t, Vector3.new(0.18, 0.14, 0.04), CFrame.new(0, s.Y * 0.42, -s.Z * 0.53), tie:Lerp(P.black, 0.2), M.fabric)
	for _, side in ipairs({ -1, 1 }) do
		add(t, Vector3.new(0.26, s.Y * 0.62, 0.04), CFrame.new(side * s.X * 0.17, s.Y * 0.2, -s.Z * 0.53) * CFrame.Angles(0, 0, math.rad(-side * 14)), jacket:Lerp(P.black, 0.15), M.fabric)
	end
	for k = 0, 1 do
		ball(t, 0.09, CFrame.new(s.X * 0.08, -s.Y * 0.18 - k * 0.22, -s.Z * 0.53), c("#2A2420"), M.smooth)
	end
	if square then
		add(t, Vector3.new(0.2, 0.08, 0.03), CFrame.new(-s.X * 0.3, s.Y * 0.22, -s.Z * 0.52), square, M.fabric)
	end
	cuffs(b, P.white)
end

-- Kimono-style wrap (happi / kappogi): crossed collar band, obi or belt
local function wrapCollar(b, band)
	local t = b.ut
	local s = t.Size
	for _, side in ipairs({ -1, 1 }) do
		add(t, Vector3.new(0.18, s.Y * 1.05, 0.04), CFrame.new(side * 0.12, s.Y * 0.02, -s.Z * 0.52) * CFrame.Angles(0, 0, math.rad(side * 22)), band, M.fabric)
	end
end

-- long = down to the shins; bib = also covers the chest (rubber / work aprons)
local function apron(b, color, long, tie, bib)
	local lt, ut = b.lt, b.ut
	if not lt then
		return
	end
	local s = lt.Size
	local len = long and 2.4 or 1.3
	add(lt, Vector3.new(s.X * 0.95, len, 0.06), CFrame.new(0, -len / 2 + s.Y * 0.4, -s.Z * 0.56), color, M.fabric)
	add(lt, Vector3.new(s.X * 1.04, 0.12, s.Z * 1.06), CFrame.new(0, s.Y * 0.4, 0), tie or color:Lerp(P.black, 0.2), M.fabric)
	if bib and ut then
		add(ut, Vector3.new(ut.Size.X * 0.55, ut.Size.Y * 0.7, 0.06), CFrame.new(0, -ut.Size.Y * 0.1, -ut.Size.Z * 0.54), color, M.fabric)
		for _, side in ipairs({ -1, 1 }) do
			add(ut, Vector3.new(0.08, ut.Size.Y * 0.5, 0.05), CFrame.new(side * ut.Size.X * 0.25, ut.Size.Y * 0.32, -ut.Size.Z * 0.5) * CFrame.Angles(0, 0, math.rad(-side * 15)), color, M.fabric)
		end
	end
end

local function skirt(b, color)
	local lt = b.lt
	if not lt then
		return
	end
	local s = lt.Size
	blob(lt, Vector3.new(s.X * 1.25, 1.1, s.Z * 1.35), CFrame.new(0, -0.45, 0), color, M.fabric)
	add(lt, Vector3.new(s.X * 1.08, 0.12, s.Z * 1.08), CFrame.new(0, s.Y * 0.3, 0), color:Lerp(P.black, 0.25), M.fabric)
end

local function shorts(b, color)
	for _, k in ipairs({ "lul", "rul" }) do
		local l = b[k]
		if l then
			local s = l.Size
			add(l, Vector3.new(s.X * 1.08, s.Y * 0.7, s.Z * 1.08), CFrame.new(0, s.Y * 0.16, 0), color, M.fabric)
		end
	end
end

-- Backpack with straps; randoseru = Japanese school bag
local function backpack(b, color, randoseru)
	local t = b.ut
	local s = t.Size
	local depth = randoseru and 0.55 or 0.5
	add(t, Vector3.new(s.X * (randoseru and 0.7 or 0.65), s.Y * (randoseru and 0.85 or 0.9), depth), CFrame.new(0, -s.Y * 0.02, s.Z * 0.5 + depth / 2), color, randoseru and M.leather or M.fabric, nc({ reflectance = randoseru and 0.15 or 0 }))
	if randoseru then
		add(t, Vector3.new(s.X * 0.72, s.Y * 0.5, 0.06), CFrame.new(0, s.Y * 0.18, s.Z * 0.5 + depth + 0.02), color:Lerp(P.black, 0.2), M.leather)
		ball(t, 0.12, CFrame.new(0, -s.Y * 0.05, s.Z * 0.5 + depth + 0.05), P.gold, M.metal)
	else
		add(t, Vector3.new(s.X * 0.45, s.Y * 0.3, 0.12), CFrame.new(0, -s.Y * 0.2, s.Z * 0.5 + depth + 0.05), color:Lerp(P.black, 0.15), M.fabric)
	end
	for _, side in ipairs({ -1, 1 }) do
		add(t, Vector3.new(0.14, s.Y * 0.95, 0.05), CFrame.new(side * s.X * 0.22, 0, -s.Z * 0.52), color:Lerp(P.black, 0.3), M.fabric)
		add(t, Vector3.new(0.14, 0.06, s.Z * 1.05), CFrame.new(side * s.X * 0.22, s.Y * 0.48, 0), color:Lerp(P.black, 0.3), M.fabric)
	end
end

local function holdInRight(b, size, color, mat, offset, props)
	local h = b.rh
	if not h then
		return nil
	end
	return add(h, size, CFrame.new(0, -h.Size.Y * 0.5 - size.Y * 0.35, 0) * (offset or CFrame.new()), color, mat, props)
end

local function watch(b, gold)
	local a = b.lla
	if a then
		add(a, Vector3.new(a.Size.X * 1.08, 0.12, a.Size.Z * 1.08), CFrame.new(0, -a.Size.Y * 0.36, 0), gold and P.gold or P.black, M.metal, nc({ reflectance = 0.3 }))
		add(a, Vector3.new(0.2, 0.14, 0.04), CFrame.new(0, -a.Size.Y * 0.36, -a.Size.Z * 0.55), gold and P.gold or P.steel, M.metal, nc({ reflectance = 0.4 }))
	end
end

---------------------------------------------------------------------------------------------------
-- Looks
---------------------------------------------------------------------------------------------------

local HAIR_STYLES = { "short", "bob", "long", "ponytail", "bun", "spiky" }

-- Applies a randomized look for a customer type. opts.child = smaller kid outfit
function People.dress(character, look, looks, r, opts)
	opts = opts or {}
	local b = body(character)
	if not (b.head and b.ut) then
		return
	end
	local function pick(list)
		return list[r:NextInteger(1, #list)]
	end
	local skin = c(pick(looks.skin))
	local hair = c(pick(looks.hair))
	local shirts = looks.shirts[look] or looks.shirts.casual
	local top = c(pick(shirts))
	local pants = c(pick(looks.pants))
	local style = pick(HAIR_STYLES)
	local skirtOn = (style == "long" or style == "bob" or style == "ponytail" or style == "bun") and r:NextNumber() < 0.45

	if opts.child then
		local kidTop = c(pick(looks.shirts.casual))
		paint(b, skin, kidTop, skin, skin, P.white)
		sleeves(b, kidTop)
		collar(b, kidTop:Lerp(P.white, 0.4))
		chestPrint(b, P.white, r:NextNumber() < 0.5 and "circle" or "stripe")
		if r:NextNumber() < 0.5 then
			skirt(b, c(pick(looks.pants)))
			style = r:NextNumber() < 0.5 and "twin" or "bob"
		else
			shorts(b, c(pick(looks.pants)))
			style = "short"
		end
		shoes(b, "sneaker", c(pick(looks.shirts.casual)))
		People.hair(character, hair, style)
		People.face(character, r, { skin = skin, brows = hair })
		if r:NextNumber() < 0.6 then
			backpack(b, r:NextNumber() < 0.5 and c("#B3262E") or c("#1A1A1A"), true)
		end
		if r:NextNumber() < 0.4 then
			People.hat(character, "school")
		end
		return
	end

	if look == "suit" then
		local jacket = top
		paint(b, skin, jacket, jacket, jacket:Lerp(P.black, 0.1), c("#1A1414"))
		suit(b, jacket, c(pick({ "#B3262E", "#2E5A8C", "#D4A23C", "#3E6A3A" })), r:NextNumber() < 0.3 and P.white or nil)
		belt(b, c("#1A1414"))
		shoes(b, "dress")
		style = r:NextNumber() < 0.75 and "short" or (r:NextNumber() < 0.5 and "bald" or "bob")
		People.hair(character, hair, style)
		People.face(character, r, { skin = skin, brows = hair })
		if r:NextNumber() < 0.4 then
			People.glasses(character, P.black)
		end
		holdInRight(b, Vector3.new(0.25, 1.0, 1.4), c("#3A2418"), M.leather, CFrame.new(0, -0.2, 0))
		watch(b, false)
	elseif look == "tourist" then
		-- aloha shirt with flowers, shorts, sneakers, camera and sun hat
		paint(b, skin, top, skin, skin, P.white)
		sleeves(b, top)
		collar(b, top:Lerp(P.white, 0.3))
		local t = b.ut
		for k = 0, 7 do
			local side = k < 4 and -1 or 1
			ball(t, 0.22, CFrame.new(-t.Size.X * 0.35 + (k % 4) * t.Size.X * 0.24, t.Size.Y * (0.3 - (k % 3) * 0.28), side * t.Size.Z * 0.5), k % 2 == 0 and P.white or c("#F25A9A"), M.fabric)
		end
		shorts(b, c(pick({ "#C8B898", "#6A8AB0", "#5A6A3A" })))
		shoes(b, r:NextNumber() < 0.5 and "sneaker" or "sandal", c("#3A6EB3"))
		People.hair(character, hair, style)
		People.face(character, r, { skin = skin, brows = hair })
		People.hat(character, r:NextNumber() < 0.5 and "sunhat" or "bucket", c(pick(looks.shirts.tourist)))
		-- camera hanging on a strap
		add(t, Vector3.new(0.08, t.Size.Y * 1.1, 0.04), CFrame.new(0, t.Size.Y * 0.1, -t.Size.Z * 0.52) * CFrame.Angles(0, 0, math.rad(35)), P.black, M.fabric)
		add(t, Vector3.new(0.55, 0.38, 0.3), CFrame.new(t.Size.X * 0.2, -t.Size.Y * 0.25, -t.Size.Z * 0.66), P.black, M.smooth)
		cyl(t, 0.24, 0.22, CFrame.new(t.Size.X * 0.2, -t.Size.Y * 0.25, -t.Size.Z * 0.88) * CFrame.Angles(math.rad(90), 0, 0), P.steel_dark, M.glass, nc({ reflectance = 0.3 }))
		if r:NextNumber() < 0.5 then
			People.glasses(character, P.black, true)
		end
	elseif look == "elder" then
		-- cardigan with buttons over a shirt, flat cap, cane
		paint(b, skin, top, top, pants, c("#5A3A24"))
		local t = b.ut
		add(t, Vector3.new(t.Size.X * 0.3, t.Size.Y * 0.98, 0.02), CFrame.new(0, 0, -t.Size.Z * 0.505), c("#E8E0D0"), M.fabric)
		for k = 0, 4 do
			ball(t, 0.08, CFrame.new(-t.Size.X * 0.17, t.Size.Y * 0.35 - k * t.Size.Y * 0.18, -t.Size.Z * 0.53), c("#5A3A24"), M.smooth)
		end
		collar(b, c("#E8E0D0"), true)
		cuffs(b, top:Lerp(P.black, 0.2))
		belt(b, c("#3A2A1A"))
		shoes(b, "dress", c("#5A3A24"))
		People.hair(character, c(pick({ "#B8B0A8", "#D8D2CA", "#8A847C" })), r:NextNumber() < 0.5 and "bald" or "short")
		People.face(character, r, { skin = skin, brows = c("#B8B0A8") })
		People.glasses(character, P.gold)
		if r:NextNumber() < 0.6 then
			People.hat(character, "flatcap", c(pick(looks.shirts.elder)))
		end
		local cane = holdInRight(b, Vector3.new(0.1, 2.6, 0.1), P.wood_dark, M.wood, CFrame.new(0, -0.7, -0.1))
		if cane and b.rh then
			add(b.rh, Vector3.new(0.4, 0.1, 0.1), CFrame.new(0.1, 0, -0.1), P.wood_dark, M.wood)
		end
	elseif look == "trendy" then
		-- open jacket over a tee, sunglasses, phone, earrings, chunky sneakers, crossbody bag
		local jacket = c(pick({ "#1E1E22", "#F4F1EA", "#7F3AB3", "#2EA3B3" }))
		paint(b, skin, top, jacket, pants, P.white)
		local t = b.ut
		for _, side in ipairs({ -1, 1 }) do
			add(t, Vector3.new(t.Size.X * 0.32, t.Size.Y * 1.02, t.Size.Z * 1.08), CFrame.new(side * t.Size.X * 0.36, 0, 0), jacket, M.fabric)
		end
		chestPrint(b, c("#FFD23B"), "square")
		cuffs(b, jacket:Lerp(P.black, 0.25))
		if skirtOn then
			skirt(b, pants)
			setColor(b.lll, skin)
			setColor(b.rll, skin)
		end
		shoes(b, "sneaker", c(pick({ "#F25A9A", "#F4F1EA", "#3BC8FF" })))
		People.hair(character, c(pick({ "#F25A9A", "#3BC8FF", "#E8D8B0", "#1A1412", "#B3262E" })), style)
		People.face(character, r, { skin = skin, brows = hair })
		People.glasses(character, P.black, true)
		if b.head then
			local hs = headSize(b.head)
			for _, s in ipairs({ -1, 1 }) do
				ball(b.head, 0.1, CFrame.new(s * hs.X * 0.52, -hs.Y * 0.18, 0), P.gold, M.metal, nc({ reflectance = 0.4 }))
			end
		end
		local phone = holdInRight(b, Vector3.new(0.3, 0.55, 0.06), P.black, M.smooth, CFrame.new(0, 0.1, -0.2))
		if phone then
			add(b.rh, Vector3.new(0.26, 0.48, 0.02), CFrame.new(0, -b.rh.Size.Y * 0.5 - 0.09, -0.24), c("#7FC8E8"), M.neon)
		end
		add(t, Vector3.new(0.08, t.Size.Y * 1.1, 0.04), CFrame.new(0, 0, -t.Size.Z * 0.52) * CFrame.Angles(0, 0, math.rad(-38)), P.black, M.leather)
		add(t, Vector3.new(0.6, 0.45, 0.2), CFrame.new(t.Size.X * 0.42, -t.Size.Y * 0.45, -t.Size.Z * 0.2), c(pick({ "#F25A9A", "#1E1E22", "#D4A23C" })), M.leather)
	elseif look == "vip" then
		-- long black coat with gold buttons, gold scarf and watch, sunglasses, fedora
		local coat = top
		paint(b, skin, coat, coat, coat:Lerp(P.black, 0.3), c("#141414"))
		suit(b, coat, P.gold, P.gold)
		local lt = b.lt
		if lt then
			add(lt, Vector3.new(lt.Size.X * 1.05, 1.6, lt.Size.Z * 1.1), CFrame.new(0, -0.7, 0), coat, M.fabric)
		end
		local t = b.ut
		add(t, Vector3.new(t.Size.X * 0.5, 0.25, t.Size.Z * 1.1), CFrame.new(0, t.Size.Y * 0.45, 0), P.gold, M.fabric)
		add(t, Vector3.new(0.25, t.Size.Y * 0.6, 0.05), CFrame.new(t.Size.X * 0.12, t.Size.Y * 0.15, -t.Size.Z * 0.56), P.gold, M.fabric)
		shoes(b, "dress")
		People.hair(character, hair, r:NextNumber() < 0.5 and "short" or "long")
		People.face(character, r, { skin = skin, brows = hair })
		People.glasses(character, P.gold, true)
		watch(b, true)
		if r:NextNumber() < 0.5 then
			People.hat(character, "fedora", c("#1A1414"))
		end
	else
		-- casual: T-shirt or hoodie, jeans or skirt, sneakers, cap or backpack
		if r:NextNumber() < 0.45 then
			paint(b, skin, top, top, pants, P.white)
			hoodie(b, top)
		else
			paint(b, skin, top, skin, pants, P.white)
			sleeves(b, top)
			collar(b, top:Lerp(P.black, 0.2))
			chestPrint(b, top:Lerp(P.white, 0.6), r:NextNumber() < 0.5 and "circle" or "square")
		end
		if skirtOn then
			skirt(b, pants)
			setColor(b.lul, skin)
			setColor(b.rul, skin)
			setColor(b.lll, P.white)
			setColor(b.rll, P.white)
		else
			belt(b)
			hems(b, pants:Lerp(P.black, 0.25))
		end
		shoes(b, "sneaker", c(pick({ "#F4F1EA", "#D9363E", "#1E1E22", "#3A6EB3" })))
		People.hair(character, hair, style)
		People.face(character, r, { skin = skin, brows = hair })
		local roll = r:NextNumber()
		if roll < 0.3 then
			People.hat(character, "cap", c(pick(looks.shirts.casual)))
		elseif roll < 0.6 then
			backpack(b, c(pick(looks.shirts.casual)))
		end
		if r:NextNumber() < 0.25 then
			People.glasses(character, c("#3A2A20"))
		end
	end
end

-- Staff uniforms by role
function People.staff(character, role, looks, r)
	local b = body(character)
	if not (b.head and b.ut) then
		return
	end
	local function pick(list)
		return list[r:NextInteger(1, #list)]
	end
	local skin = c(pick(looks.skin))
	local hair = c(pick(looks.hair))
	local style = pick({ "short", "short", "ponytail", "bun", "spiky" })
	local t = b.ut
	if role == "staff_sushi_chef" or role == "staff_ramen_chef" or role == "staff_line_cook" then
		-- white kappogi jacket, long dark apron, tenugui at the waist, chef hat or hachimaki
		paint(b, skin, P.white, P.white, c("#1E1E22"), P.black)
		wrapCollar(b, c("#E8E0D0"))
		for k = 0, 2 do
			ball(t, 0.08, CFrame.new(t.Size.X * 0.2, t.Size.Y * 0.2 - k * 0.3, -t.Size.Z * 0.53), c("#D8D0C0"), M.smooth)
		end
		apron(b, role == "staff_sushi_chef" and c("#1E2A44") or c("#3A2A20"), true, P.white, false)
		if b.lt then
			add(b.lt, Vector3.new(0.3, 0.7, 0.05), CFrame.new(b.lt.Size.X * 0.35, -0.4, -b.lt.Size.Z * 0.62), P.white, M.fabric)
			add(b.lt, Vector3.new(0.3, 0.08, 0.051), CFrame.new(b.lt.Size.X * 0.35, -0.6, -b.lt.Size.Z * 0.625), P.indigo, M.fabric)
		end
		shoes(b, role == "staff_sushi_chef" and "geta" or "boot", P.black)
		People.hair(character, hair, style == "spiky" and "short" or style)
		People.face(character, r, { skin = skin, brows = hair })
		People.hat(character, role == "staff_sushi_chef" and "hachimaki" or "chef")
	elseif role == "staff_waiter" then
		-- indigo happi coat with white collar band, short maekake apron, bandana, order pad
		local happi = c("#1E2A44")
		paint(b, skin, happi, happi, c("#1A1A1A"), P.black)
		wrapCollar(b, P.white)
		cuffs(b, P.white)
		local back = add(t, Vector3.new(t.Size.X * 0.5, t.Size.Y * 0.5, 0.02), CFrame.new(0, 0, t.Size.Z * 0.51), happi, M.fabric)
		Kit.text(back, Enum.NormalId.Back, "麺", { color = "#FFFFFF" })
		apron(b, c("#2E3A5C"), false, P.white)
		shoes(b, "sneaker", P.black)
		People.hair(character, hair, style)
		People.face(character, r, { skin = skin, brows = hair })
		People.hat(character, "bandana", c("#B3262E"))
		holdInRight(b, Vector3.new(0.5, 0.65, 0.06), P.paper, M.smooth, CFrame.new(0, 0.1, -0.15))
	elseif role == "staff_dishwasher" then
		-- t-shirt, long rubber apron, yellow gloves, rubber boots
		local tee = c(pick({ "#F4F1EA", "#6A8AB0", "#C8B898" }))
		paint(b, skin, tee, skin, c("#2A2A30"), P.white)
		sleeves(b, tee)
		apron(b, c("#3E8A4A"), true, c("#2A5A30"), true)
		for _, k in ipairs({ "lla", "rla" }) do
			local a = b[k]
			if a then
				add(a, Vector3.new(a.Size.X * 1.1, a.Size.Y * 0.7, a.Size.Z * 1.1), CFrame.new(0, -a.Size.Y * 0.15, 0), c("#F4CF3B"), M.smooth, nc({ reflectance = 0.1 }))
			end
		end
		setColor(b.lh, c("#F4CF3B"))
		setColor(b.rh, c("#F4CF3B"))
		shoes(b, "boot", P.white)
		People.hair(character, hair, style)
		People.face(character, r, { skin = skin, brows = hair })
		People.hat(character, "bandana", c("#2E5A8C"))
	elseif role == "staff_stocker" then
		-- work jacket with reflective stripe, cap, cotton gloves, work boots
		local jacket = c("#4A5A3A")
		paint(b, skin, jacket, jacket, c("#3A3A44"), c("#5A3A24"))
		chestPrint(b, c("#D8E048"), "stripe")
		collar(b, jacket:Lerp(P.black, 0.2))
		setColor(b.lh, P.white)
		setColor(b.rh, P.white)
		belt(b)
		shoes(b, "boot", c("#5A3A24"))
		People.hair(character, hair, "short")
		People.face(character, r, { skin = skin, brows = hair })
		People.hat(character, "cap", c("#D9363E"))
	else
		-- manager: dark suit, gold tie, name badge, clipboard
		local jacket = c("#1E1E28")
		paint(b, skin, jacket, jacket, jacket, c("#141414"))
		suit(b, jacket, P.gold, P.white)
		add(t, Vector3.new(0.4, 0.18, 0.03), CFrame.new(t.Size.X * 0.27, t.Size.Y * 0.2, -t.Size.Z * 0.53), P.gold, M.metal, nc({ reflectance = 0.3 }))
		belt(b, c("#141414"), P.gold)
		shoes(b, "dress")
		People.hair(character, hair, "short")
		People.face(character, r, { skin = skin, brows = hair })
		People.glasses(character, P.black)
		holdInRight(b, Vector3.new(0.7, 0.9, 0.06), P.wood_light, M.wood, CFrame.new(0, 0.1, -0.2))
		watch(b, true)
	end
end

-- Kept for older callers
function People.apron(character, color)
	apron(body(character), color, false)
end

function People.bag(character, kind, color)
	local b = body(character)
	if kind == "backpack" and b.ut then
		backpack(b, color or P.indigo)
	end
end

return function(Registry)
	Registry.People = People
end
