--!nonstrict
-- Shelf tags (as in shop games): a small paper tag on the front edge of every shelf slot with the
-- icon and the name of the product it holds, written in your language. Empty slots get a blank
-- tag. Tags are local parts, rebuilt only when a slot changes product.
local CollectionService = game:GetService("CollectionService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Locale = require(Shared.Locale)
local Ingredients = require(Shared.Config.Ingredients)

local ShelfTags = {}
local tags = {} -- [slot part] = { part, icon, name, g }
local folder
local RANGE = 70

local function makeTag()
	local p = Instance.new("Part")
	p.Name = "ShelfTag"
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.SmoothPlastic
	p.Color = Color3.fromRGB(250, 246, 236)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 90
	gui.LightInfluence = 1
	gui.Parent = p
	-- red band on the left like a price tag, icon, then the name
	local band = Instance.new("Frame")
	band.Size = UDim2.new(0, 10, 1, 0)
	band.BackgroundColor3 = Color3.fromRGB(179, 38, 46)
	band.BorderSizePixel = 0
	band.Parent = gui
	local icon = Instance.new("TextLabel")
	icon.Position = UDim2.new(0, 14, 0, 2)
	icon.Size = UDim2.new(0.28, -14, 1, -4)
	icon.BackgroundTransparency = 1
	icon.TextScaled = true
	icon.AutoLocalize = false
	icon.Parent = gui
	local name = Instance.new("TextLabel")
	name.Position = UDim2.new(0.28, 2, 0, 2)
	name.Size = UDim2.new(0.72, -6, 1, -4)
	name.BackgroundTransparency = 1
	name.TextScaled = true
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.TextColor3 = Color3.fromRGB(43, 35, 32)
	name.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold)
	name.AutoLocalize = false
	name.Parent = gui
	return { part = p, icon = icon, name = name, g = nil }
end

local function place(tag, slot)
	-- on the front edge of the shelf board, just under the slot
	local w = math.clamp(slot.Size.X * 0.42, 1.0, 1.7)
	tag.part.Size = Vector3.new(w, 0.34, 0.04)
	tag.part.CFrame = slot.CFrame * CFrame.new(0, -slot.Size.Y / 2 - 0.03, -slot.Size.Z / 2 - 0.1)
end

local function setText(tag, g)
	tag.g = g
	local ing = Ingredients.byId[g or ""]
	if ing then
		tag.icon.Text = ing.icon
		tag.name.Text = Locale.t("ing." .. g)
	else
		tag.icon.Text = ""
		tag.name.Text = "—"
	end
end

local function update()
	local cam = workspace.CurrentCamera
	local origin = cam and cam.CFrame.Position or Vector3.new()
	local seen = {}
	for _, m in ipairs(CollectionService:GetTagged("Interactable")) do
		if m:GetAttribute("Kind") == "shelf" and m:IsDescendantOf(workspace) and m.PrimaryPart then
			if (m.PrimaryPart.Position - origin).Magnitude < RANGE then
				for _, slot in ipairs(m:GetChildren()) do
					if slot:IsA("BasePart") and slot:GetAttribute("Slot") then
						seen[slot] = true
						local tag = tags[slot]
						if not tag then
							tag = makeTag()
							tags[slot] = tag
							tag.part.Parent = folder
						end
						place(tag, slot)
						local g = slot:GetAttribute("G") or ""
						if tag.g ~= g then
							setText(tag, g)
						end
					end
				end
			end
		end
	end
	for slot, tag in pairs(tags) do
		if not seen[slot] then
			tag.part:Destroy()
			tags[slot] = nil
		end
	end
end

function ShelfTags.Init()
	folder = Instance.new("Folder")
	folder.Name = "ShelfTags"
	folder.Parent = workspace.CurrentCamera
	Locale.Changed:Connect(function()
		for _, tag in pairs(tags) do
			setText(tag, tag.g)
		end
	end)
end

function ShelfTags.Start()
	while true do
		update()
		task.wait(0.4)
	end
end


return ShelfTags
