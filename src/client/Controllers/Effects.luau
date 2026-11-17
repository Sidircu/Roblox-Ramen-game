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
local Registry = require(Shared.Models.Registry)
local Core = require(script.Parent.Parent.Core)
local RunService = game:GetService("RunService")

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

------------------------------------------------------------------ flying products

-- a product model like the ones SupplyService puts on shelves (same size and resting rule)
local function product(item)
	Registry.load()
	local m = Registry.food("ingredient", item.g)
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanQuery = false
			d.CastShadow = false
		end
	end
	pcall(function()
		m:ScaleTo(item.s or 1)
	end)
	local target = item.cf * (item.rot and CFrame.Angles(0, math.rad(90), 0) or CFrame.new())
	m:PivotTo(target)
	local box, size = m:GetBoundingBox()
	local landing = target + Vector3.new(0, target.Position.Y - (box.Position.Y - size.Y / 2), 0)
	return m, landing
end

-- moves a model along a small arc, then calls done
local function arc(m, fromCf, toCf, dur, height, done)
	task.spawn(function()
		local t0 = os.clock()
		while m.Parent do
			local k = math.min(1, (os.clock() - t0) / dur)
			local e = k * k * (3 - 2 * k)
			m:PivotTo(fromCf:Lerp(toCf, e) + Vector3.new(0, math.sin(k * math.pi) * height, 0))
			if k >= 1 then
				break
			end
			RunService.RenderStepped:Wait()
		end
		if done then
			done()
		end
	end)
end

-- products leave the box one after the other and land on their spot (shelf grid, board...)
local function stock(data)
	local items = data.items or {}
	local step = data.step or 0.06
	local total = #items * step + 0.3
	for i, item in ipairs(items) do
		task.delay((i - 1) * step, function()
			local m, landing = product(item)
			local from = data.from and (CFrame.new(data.from) * landing.Rotation) or (landing + Vector3.new(0, 2, 0))
			m:PivotTo(from)
			m.Parent = workspace.CurrentCamera
			arc(m, from, landing, 0.28, 1, function()
				local Audio = Core.C.Audio
				if Audio then
					Audio.play("pop", landing.Position, { pitch = 1 + math.min(i, 20) * 0.015 })
				end
				-- stay until the real product appears in the same place
				task.delay(math.max(0.1, total - ((i - 1) * step + 0.28)) + 0.35, function()
					m:Destroy()
				end)
			end)
		end)
	end
end

-- a product taken from a shelf flies into your hands
local function take(data)
	if not data.item or not data.to then
		return
	end
	local m, landing = product(data.item)
	m:PivotTo(landing)
	m.Parent = workspace.CurrentCamera
	arc(m, landing, CFrame.new(data.to) * landing.Rotation, 0.25, 0.6, function()
		m:Destroy()
	end)
end

-- Big "COMBO x3" banner in the middle of the screen
local comboLabel = nil
local function comboBanner(n, bonus)
	local root = Core.C.UI and Core.C.UI.root()
	if not root then
		return
	end
	if comboLabel then
		comboLabel:Destroy()
	end
	local l = Instance.new("TextLabel")
	l.AnchorPoint = Vector2.new(0.5, 0.5)
	l.Position = UDim2.fromScale(0.5, 0.3)
	l.Size = UDim2.fromOffset(420, 70)
	l.BackgroundTransparency = 1
	l.Text = Locale.t("ui.combo", { n = n, pct = math.floor((bonus or 0) * 100 + 0.5) })
	l.TextScaled = true
	l.TextColor3 = Color.hex(n >= 6 and "#FF5A3B" or "#FFD23B")
	l.TextStrokeTransparency = 0
	l.TextStrokeColor3 = Color.hex("#5B3A24")
	l.FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json")
	l.AutoLocalize = false
	l.Rotation = -4
	l.Parent = root
	comboLabel = l
	local scale = Instance.new("UIScale")
	scale.Scale = 0.4
	scale.Parent = l
	TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	task.delay(1.3, function()
		if l.Parent then
			TweenService:Create(l, TweenInfo.new(0.4), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
			task.wait(0.45)
			l:Destroy()
		end
	end)
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
				task.delay(0.4, function()
					Audio.play("sparkle")
				end)
			end
		elseif kind == "dishReady" and data.pos then
			burst(data.pos, "sparkle", 14)
			if Audio then
				Audio.play("bell", data.pos)
			end
		elseif kind == "ready" and data.pos then
			popup(data.pos + Vector3.new(0, 3, 0), "✅", Color.hex("#6DDC5A"), 1.5)
			if Audio then
				Audio.play("beep", data.pos)
			end
		elseif kind == "stock" then
			stock(data)
		elseif kind == "take" then
			take(data)
		elseif kind == "washed" and data.uid then
			if Core.C.Sink then
				Core.C.Sink.washed(data.uid)
			end
		elseif kind == "step" and Audio then
			Audio.step(data.name, data.dur, data.pos)
		elseif kind == "combo" then
			comboBanner(data.n or 2, data.bonus)
			if data.pos then
				burst(data.pos, "sparkle", 10, "#FFD23B")
			end
			if Audio then
				Audio.play("combo", nil, { pitch = 1 + math.min(data.n or 2, 10) * 0.05 })
			end
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
