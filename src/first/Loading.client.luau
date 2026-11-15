--!nonstrict
-- Loading screen (shown while the world is prepared or while teleporting to the personal world).
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local isItalian = string.sub(string.lower(player.LocaleId or ""), 1, 2) == "it"

local gui = Instance.new("ScreenGui")
gui.Name = "Loading"
gui.IgnoreGuiInset = true
gui.DisplayOrder = 100
gui.ResetOnSpawn = false

local bg = Instance.new("Frame")
bg.Size = UDim2.fromScale(1, 1)
bg.BackgroundColor3 = Color3.fromRGB(244, 235, 221)
bg.Parent = gui
local grad = Instance.new("UIGradient")
grad.Color = ColorSequence.new(Color3.fromRGB(247, 227, 192), Color3.fromRGB(244, 210, 200))
grad.Rotation = 90
grad.Parent = bg

local title = Instance.new("TextLabel")
title.AnchorPoint = Vector2.new(0.5, 0.5)
title.Position = UDim2.fromScale(0.5, 0.38)
title.Size = UDim2.fromScale(0.8, 0.12)
title.BackgroundTransparency = 1
title.Text = "Sakura Ramen & Sushi Tycoon"
title.TextScaled = true
title.TextColor3 = Color3.fromRGB(179, 38, 46)
title.FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json")
title.AutoLocalize = false
title.Parent = bg

local kanji = Instance.new("TextLabel")
kanji.AnchorPoint = Vector2.new(0.5, 0.5)
kanji.Position = UDim2.fromScale(0.5, 0.5)
kanji.Size = UDim2.fromScale(0.5, 0.07)
kanji.BackgroundTransparency = 1
kanji.Text = "ら ー め ん ・ 寿 司"
kanji.TextScaled = true
kanji.TextColor3 = Color3.fromRGB(43, 35, 32)
kanji.FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json")
kanji.AutoLocalize = false
kanji.Parent = bg

local flower = Instance.new("TextLabel")
flower.AnchorPoint = Vector2.new(0.5, 0.5)
flower.Position = UDim2.fromScale(0.5, 0.64)
flower.Size = UDim2.fromOffset(70, 70)
flower.BackgroundTransparency = 1
flower.Text = "🌸"
flower.TextScaled = true
flower.AutoLocalize = false
flower.Parent = bg

local status = Instance.new("TextLabel")
status.AnchorPoint = Vector2.new(0.5, 0.5)
status.Position = UDim2.fromScale(0.5, 0.76)
status.Size = UDim2.fromScale(0.8, 0.045)
status.BackgroundTransparency = 1
status.Text = isItalian and "Stiamo preparando il tuo ristorante…" or "Preparing your restaurant…"
status.TextScaled = true
status.TextColor3 = Color3.fromRGB(91, 58, 36)
status.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.SemiBold)
status.AutoLocalize = false
status.Parent = bg

gui.Parent = player:WaitForChild("PlayerGui")
pcall(function()
	ReplicatedFirst:RemoveDefaultLoadingScreen()
end)
pcall(function()
	TeleportService:SetTeleportGui(gui)
end)

local spin = RunService.RenderStepped:Connect(function(dt)
	flower.Rotation = (flower.Rotation + dt * 90) % 360
end)

if not game:IsLoaded() then
	game.Loaded:Wait()
end

local t0 = os.clock()
while os.clock() - t0 < 25 do
	local mode = workspace:GetAttribute("SessionMode")
	if mode == "lobby" then
		status.Text = isItalian and "Ti stiamo portando nel tuo mondo…" or "Taking you to your own world…"
	elseif workspace:GetAttribute("WorldReady") then
		break
	end
	task.wait(0.2)
end

if workspace:GetAttribute("SessionMode") ~= "lobby" then
	task.wait(0.5)
	local info = TweenInfo.new(0.6)
	for _, d in ipairs(bg:GetDescendants()) do
		if d:IsA("TextLabel") then
			TweenService:Create(d, info, { TextTransparency = 1 }):Play()
		end
	end
	TweenService:Create(bg, info, { BackgroundTransparency = 1 }):Play()
	task.wait(0.7)
	spin:Disconnect()
	gui:Destroy()
end
