--!nonstrict
-- Procedural accessories for NPC characters (hair, hats, glasses, bags, aprons).
local Kit = require(script.Parent.Parent.Kit)
local P = require(script.Parent.Parent.Palette)
local Color = require(script.Parent.Parent.Parent.Util.Color)
local M = P.M

local People = {}

local function weld(part, to)
	part.Anchored = false
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Massless = true
	local w = Instance.new("WeldConstraint")
	w.Part0 = to
	w.Part1 = part
	w.Parent = part
	part.Parent = to.Parent
	return part
end

local function at(base, cf)
	return base.CFrame * cf
end

function People.hair(character, color, style)
	local head = character:FindFirstChild("Head")
	if not head then
		return
	end
	local p = Kit.part(nil, Vector3.new(1.3, 0.45, 1.25), at(head, CFrame.new(0, 0.42, 0.05)), color, M.smooth, { collide = false })
	weld(p, head)
	if style == 2 then
		local back = Kit.part(nil, Vector3.new(1.25, 0.9, 0.3), at(head, CFrame.new(0, 0.05, 0.55)), color, M.smooth, { collide = false })
		weld(back, head)
	elseif style == 3 then
		local bun = Kit.part(nil, Vector3.new(0.55, 0.55, 0.55), at(head, CFrame.new(0, 0.75, 0.3)), color, M.smooth, { shape = Enum.PartType.Ball, collide = false })
		weld(bun, head)
	elseif style == 4 then
		local long = Kit.part(nil, Vector3.new(1.3, 1.4, 0.35), at(head, CFrame.new(0, -0.3, 0.55)), color, M.smooth, { collide = false })
		weld(long, head)
	end
end

function People.hat(character, kind, color)
	local head = character:FindFirstChild("Head")
	if not head then
		return
	end
	if kind == "cap" then
		weld(Kit.part(nil, Vector3.new(1.35, 0.4, 1.3), at(head, CFrame.new(0, 0.6, 0)), color, M.fabric, { collide = false }), head)
		weld(Kit.part(nil, Vector3.new(1.0, 0.08, 0.7), at(head, CFrame.new(0, 0.45, -0.85)), color, M.fabric, { collide = false }), head)
	elseif kind == "bucket" then
		weld(Kit.part(nil, Vector3.new(0.5, 1.6, 1.6), at(head, CFrame.new(0, 0.55, 0) * CFrame.Angles(0, 0, math.rad(90))), color, M.fabric, { shape = Enum.PartType.Cylinder, collide = false }), head)
	elseif kind == "chef" then
		weld(Kit.part(nil, Vector3.new(0.9, 1.3, 1.3), at(head, CFrame.new(0, 0.95, 0) * CFrame.Angles(0, 0, math.rad(90))), P.white, M.fabric, { shape = Enum.PartType.Cylinder, collide = false }), head)
	elseif kind == "hachimaki" then
		weld(Kit.part(nil, Vector3.new(1.32, 0.22, 1.28), at(head, CFrame.new(0, 0.3, 0)), P.white, M.fabric, { collide = false }), head)
		weld(Kit.part(nil, Vector3.new(0.5, 0.5, 0.06), at(head, CFrame.new(0, 0.32, -0.66)), P.lacquer, M.fabric, { shape = Enum.PartType.Cylinder, collide = false }), head)
	elseif kind == "sunhat" then
		weld(Kit.part(nil, Vector3.new(0.15, 2.4, 2.4), at(head, CFrame.new(0, 0.55, 0) * CFrame.Angles(0, 0, math.rad(90))), color, M.fabric, { shape = Enum.PartType.Cylinder, collide = false }), head)
		weld(Kit.part(nil, Vector3.new(0.5, 1.3, 1.3), at(head, CFrame.new(0, 0.75, 0) * CFrame.Angles(0, 0, math.rad(90))), color, M.fabric, { shape = Enum.PartType.Cylinder, collide = false }), head)
	end
end

function People.glasses(character, color)
	local head = character:FindFirstChild("Head")
	if not head then
		return
	end
	for _, x in ipairs({ -0.25, 0.25 }) do
		weld(Kit.part(nil, Vector3.new(0.35, 0.25, 0.05), at(head, CFrame.new(x, 0.1, -0.62)), color or P.black, M.glass, { collide = false, transparency = 0.3 }), head)
	end
	weld(Kit.part(nil, Vector3.new(0.9, 0.05, 0.05), at(head, CFrame.new(0, 0.18, -0.63)), color or P.black, M.smooth, { collide = false }), head)
end

function People.bag(character, kind, color)
	local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
	if not torso then
		return
	end
	if kind == "backpack" then
		weld(Kit.part(nil, Vector3.new(1.4, 1.5, 0.6), at(torso, CFrame.new(0, 0, 0.75)), color, M.fabric, { collide = false }), torso)
	elseif kind == "camera" then
		weld(Kit.part(nil, Vector3.new(0.6, 0.4, 0.35), at(torso, CFrame.new(0, -0.3, -0.7)), P.black, M.smooth, { collide = false }), torso)
		weld(Kit.part(nil, Vector3.new(0.25, 0.25, 0.3), at(torso, CFrame.new(0, -0.3, -0.95) * CFrame.Angles(math.rad(90), 0, 0)), P.steel_dark, M.glass, { shape = Enum.PartType.Cylinder, collide = false }), torso)
	elseif kind == "briefcase" then
		local hand = character:FindFirstChild("LeftHand")
		if hand then
			weld(Kit.part(nil, Vector3.new(0.3, 1.0, 1.4), at(hand, CFrame.new(0, -0.6, 0)), P.wood_dark, M.leather, { collide = false }), hand)
		end
	elseif kind == "scarf" then
		weld(Kit.part(nil, Vector3.new(1.5, 0.35, 1.1), at(torso, CFrame.new(0, 0.75, 0)), color, M.fabric, { collide = false }), torso)
	end
end

function People.apron(character, color)
	local torso = character:FindFirstChild("LowerTorso") or character:FindFirstChild("Torso")
	if not torso then
		return
	end
	weld(Kit.part(nil, Vector3.new(1.5, 1.6, 0.1), at(torso, CFrame.new(0, -0.6, -0.55)), color, M.fabric, { collide = false }), torso)
end

-- Applies a randomized look for a customer type
function People.dress(character, look, looks, r)
	local function pick(list)
		return list[r:NextInteger(1, #list)]
	end
	local hairColor = Color.hex(pick(looks.hair))
	People.hair(character, hairColor, r:NextInteger(1, 4))
	if look == "suit" then
		People.bag(character, "briefcase")
		if r:NextNumber() < 0.4 then
			People.glasses(character)
		end
	elseif look == "tourist" then
		People.hat(character, r:NextNumber() < 0.5 and "sunhat" or "bucket", Color.hex(pick(looks.shirts.tourist)))
		People.bag(character, r:NextNumber() < 0.6 and "camera" or "backpack", Color.hex(pick(looks.shirts.casual)))
	elseif look == "elder" then
		if r:NextNumber() < 0.6 then
			People.glasses(character, P.gold)
		end
		People.hat(character, "bucket", Color.hex(pick(looks.shirts.elder)))
	elseif look == "trendy" then
		People.glasses(character, P.black)
		People.bag(character, "scarf", Color.hex(pick(looks.shirts.trendy)))
	elseif look == "vip" then
		People.glasses(character, P.black)
		People.bag(character, "scarf", P.gold)
	else
		local roll = r:NextNumber()
		if roll < 0.3 then
			People.hat(character, "cap", Color.hex(pick(looks.shirts.casual)))
		elseif roll < 0.55 then
			People.bag(character, "backpack", Color.hex(pick(looks.shirts.casual)))
		end
	end
end

return function(Registry)
	Registry.People = People
end
