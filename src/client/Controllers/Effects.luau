--!nonstrict
-- Visual feedback for server events: money popups, review stars, level up confetti,
-- dish ready sparkles, construction dust, sounds.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local NetDef = require(Shared.Net)
local Locale = require(Shared.Locale)
local Format = require(Shared.Util.Format)
local Color = require(Shared.Util.Color)
local Kit = require(Shared.Models.Kit)
local Core = require(script.Parent.Parent.Core)

local Effects = {}
local player = Players.LocalPlayer

local function popup(pos, text, color, rise)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.Transparency = 1
	p.Size = Vector3.new(0.2, 0.2, 0.2)
	p.Position = pos
	p.Parent = workspace.CurrentCamera
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(200, 50)
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.Adornee = p
	gui.Parent = player.PlayerGui
	local l = Instance.new("TextLabel")
	l.Size = UDim2.fromScale(1, 1)
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextScaled = true
	l.TextColor3 = color or Color.hex("#FFD23B")
	l.TextStrokeTransparency = 0.3
	l.FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json")
	l.AutoLocalize = false
	l.Parent = gui
	TweenService:Create(p, TweenInfo.new(1.6, Enum.EasingStyle.Quad), { Position = pos + Vector3.new(0, rise or 3, 0) }):Play()
	TweenService:Create(l, TweenInfo.new(1.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	task.delay(1.7, function()
		gui:Destroy()
		p:Destroy()
	end)
end

local function burst(pos, preset, count, color)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.Transparency = 1
	p.Size = Vector3.new(1, 1, 1)
	p.Position = pos
	p.Parent = workspace.CurrentCamera
	local e = Kit.particles(p, preset, { rate = 0, color = color, glow = 0.6 })
	e:Emit(count or 20)
	task.delay(3, function()
		p:Destroy()
	end)
end

local function confetti()
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	for _, c in ipairs({ "#FF3B4A", "#FFD23B", "#3BC8FF", "#6DDC5A", "#F7B7C9" }) do
		burst(root.Position + Vector3.new(0, 4, 0), "sparkle", 18, c)
	end
end

function Effects.Init()
	NetDef.event("Fx").OnClientEvent:Connect(function(kind, data)
		data = data or {}
		local Audio = Core.C.Audio
		if kind == "money" and data.pos then
			popup(data.pos, "+" .. Format.yen(data.amount or 0, Locale.get()), Color.hex("#FFD23B"))
		elseif kind == "review" and data.pos then
			local stars = data.stars or 3
			popup(data.pos + Vector3.new(0, 1.2, 0), string.rep("★", math.floor(stars)) .. (stars % 1 >= 0.5 and "½" or ""), stars >= 4 and Color.hex("#FFD23B") or Color.hex("#FF8A5A"), 2)
		elseif kind == "levelup" then
			if data.userId == player.UserId or true then
				confetti()
			end
			if Audio then
				Audio.play("level")
			end
		elseif kind == "dishReady" and data.pos then
			burst(data.pos, "sparkle", 14)
			if Audio then
				Audio.play("bell", data.pos)
			end
		elseif kind == "ready" and data.pos then
			popup(data.pos + Vector3.new(0, 3, 0), "✅", Color.hex("#6DDC5A"), 1.5)
		elseif kind == "sparkle" then
			confetti()
		elseif kind == "construction" then
			local char = player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			if root then
				burst(root.Position + Vector3.new(0, 6, 8), "smoke", 30, "#D8C8B0")
			end
			Core.C.UI.toast("🏗️ " .. Locale.t("msg.construction"), "info")
		elseif kind == "sfx" and Audio then
			Audio.play(data.name, data.pos)
		elseif kind == "action" then
			if Core.C.Tutorial then
				Core.C.Tutorial.onAction(data.kind, data.hands)
			end
		end
	end)
end

return Effects
