--!nonstrict
-- Noodle timing (optional skill): while the noodles boil, a bar with a green part and a moving
-- needle appears under the middle of the screen. Click / E (or ✋) when the needle is in the
-- green: "Perfect!" and that bowl gets a bigger tip. Missing it costs nothing.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local NetDef = require(Shared.Net)
local Locale = require(Shared.Locale)
local UIKit = require(script.Parent.Parent.UI.Kit)
local Core = require(script.Parent.Parent.Core)

local Timing = {}
local player = Players.LocalPlayer
local t = Locale.t
local T = UIKit.Theme

local gui, bar, zone, needle, label
local session = nil -- { uid, start, dur, a, b, hit }

local function hide(after)
	task.delay(after or 0, function()
		if not session or session.hit then
			gui.Enabled = false
			session = nil
		end
	end)
end

function Timing.active()
	return session ~= nil and not session.hit
end

-- the player pressed: send where the needle is
function Timing.hit()
	if not Timing.active() then
		return
	end
	local k = math.clamp((os.clock() - session.start) / session.dur, 0, 1)
	session.hit = true
	NetDef.event("TimingHit"):FireServer(session.uid, k)
end

function Timing.start(data)
	session = { uid = data.uid, start = os.clock(), dur = math.max(0.3, data.dur or 1.5), a = data.a or 0.5, b = data.b or 0.8 }
	zone.Position = UDim2.fromScale(session.a, 0)
	zone.Size = UDim2.fromScale(session.b - session.a, 1)
	label.Text = "🍜 " .. t("ui.timing_hint")
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	gui.Enabled = true
end

function Timing.result(data)
	local Audio = Core.C.Audio
	if data.ok then
		label.Text = "✨ " .. t("ui.timing_perfect")
		label.TextColor3 = T.gold
		if Audio then
			Audio.play("combo", nil, { pitch = 1.3 })
		end
	else
		label.Text = t("ui.timing_miss")
		label.TextColor3 = Color3.fromRGB(230, 230, 230)
	end
	task.delay(0.9, function()
		gui.Enabled = false
		session = nil
	end)
end

function Timing.Init()
	gui = UIKit.new("ScreenGui", { Name = "Timing", ResetOnSpawn = false, IgnoreGuiInset = true, Enabled = false, Parent = player:WaitForChild("PlayerGui") })
	bar = UIKit.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.5, 70), Size = UDim2.fromOffset(280, 16),
		BackgroundColor3 = Color3.fromRGB(43, 35, 32), BackgroundTransparency = 0.2, Parent = gui,
	}, { UIKit.corner(8), UIKit.stroke(Color3.fromRGB(255, 255, 255), 2, 0.3) })
	zone = UIKit.new("Frame", { BackgroundColor3 = T.green, BorderSizePixel = 0, Parent = bar }, { UIKit.corner(6) })
	needle = UIKit.new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.new(0, 5, 1, 10), BackgroundColor3 = Color3.fromRGB(255, 255, 255), Parent = bar }, { UIKit.corner(3) })
	label = UIKit.label("", {
		Parent = gui, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.5, 92), Size = UDim2.fromOffset(320, 24),
		TextSize = 17, FontFace = T.bold, TextXAlignment = Enum.TextXAlignment.Center, TextStrokeTransparency = 0.4, TextColor3 = Color3.fromRGB(255, 255, 255),
	})
end

function Timing.Start()
	RunService.RenderStepped:Connect(function()
		if session and not session.hit then
			local k = (os.clock() - session.start) / session.dur
			needle.Position = UDim2.fromScale(math.clamp(k, 0, 1), 0.5)
			if k > 1.05 then
				label.Text = t("ui.timing_miss")
				session.hit = true
				hide(0.6)
			end
		end
	end)
end

return Timing
