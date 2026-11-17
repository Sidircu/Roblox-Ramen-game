--!nonstrict
-- Phone: every secondary screen is an app, ordered by how often it is needed. Opens from the
-- 📱 button at the bottom-left and closes when an app is opened.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Locale = require(Shared.Locale)
local Format = require(Shared.Util.Format)
local Color = require(Shared.Util.Color)
local Kit = require(script.Parent.Parent.Kit)
local Core = require(script.Parent.Parent.Parent.Core)

local T = Kit.Theme
local t = Locale.t
local player = Players.LocalPlayer

local APPS = {
	{ id = "Menu", icon = "📜", key = "ui.menu", color = "#B3262E" },
	{ id = "Gifts", icon = "🎁", key = "ui.gifts", color = "#E0405A" },
	{ id = "Staff", icon = "👥", key = "ui.staff", color = "#2E5A8C" },
	{ id = "Upgrades", icon = "⬆️", key = "ui.upgrades", color = "#5E8F3A" },
	{ id = "Expansions", icon = "🏗️", key = "ui.expansions", color = "#8A5A36" },
	{ id = "Licenses", icon = "🎫", key = "ui.licenses", color = "#D4A23C" },
	{ id = "Goals", icon = "🎯", key = "ui.goals", color = "#F27A2E" },
	{ id = "Help", icon = "❓", key = "ui.howto", color = "#2EA3B3" },
	{ id = "Shop", icon = "🛒", key = "ui.shop", color = "#F25A9A" },
	{ id = "Codes", icon = "🎟️", key = "ui.codes", color = "#3A8F8A" },
	{ id = "Invite", icon = "👋", key = "ui.invite", color = "#7F3AB3" },
	{ id = "Settings", icon = "⚙️", key = "ui.settings", color = "#5A5A64" },
	{ id = "Dev", icon = "🛠️", key = "ui.dev", color = "#1E1E22", dev = true },
}

local Phone = {}
local frame, grid, clock

local function launch(app)
	if Core.C.Audio then
		Core.C.Audio.play("ui")
	end
	Core.C.UI.close("Phone")
	if app.id == "Help" then
		if Core.C.Tutorial and Core.C.Tutorial.restart then
			Core.C.Tutorial.restart()
		end
		return
	end
	Core.C.UI.open(app.id)
end

function Phone.create(root)
	frame = Kit.new("Frame", {
		Name = "Phone", AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 10, 1, -88), Size = UDim2.fromOffset(292, 470),
		BackgroundColor3 = Color3.fromRGB(28, 26, 30), Visible = false, Parent = root,
	}, { Kit.corner(30), Kit.stroke(Color3.fromRGB(70, 66, 72), 3) })
	-- screen
	local screen = Kit.new("Frame", { Position = UDim2.fromOffset(10, 12), Size = UDim2.new(1, -20, 1, -34), BackgroundColor3 = T.paper, Parent = frame }, { Kit.corner(22) })
	Kit.new("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(255, 240, 244), Color3.fromRGB(244, 235, 221)), Rotation = 90, Parent = screen })
	-- status bar with the time and a little notch
	clock = Kit.label("", { Parent = screen, Position = UDim2.fromOffset(16, 6), Size = UDim2.fromOffset(80, 18), TextSize = 13, FontFace = T.bold })
	Kit.label("📶 🔋", { Parent = screen, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 6), Size = UDim2.fromOffset(60, 18), TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right })
	Kit.new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 6), Size = UDim2.fromOffset(70, 14), BackgroundColor3 = Color3.fromRGB(28, 26, 30), Parent = screen }, { Kit.corner(7) })
	Kit.title("🌸 Sakura", { Parent = screen, Position = UDim2.fromOffset(16, 30), Size = UDim2.new(1, -32, 0, 28), TextSize = 22 })
	grid = Kit.new("Frame", { Position = UDim2.fromOffset(10, 66), Size = UDim2.new(1, -20, 1, -76), BackgroundTransparency = 1, Parent = screen }, { Kit.grid(80, 88, 4) })
	-- home bar
	Kit.new("Frame", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -8), Size = UDim2.fromOffset(90, 5), BackgroundColor3 = Color3.fromRGB(120, 116, 124), Parent = frame }, { Kit.corner(3) })
end

function Phone.refresh()
	if not grid then
		return
	end
	Kit.clear(grid)
	clock.Text = Format.clock(game:GetService("Lighting").ClockTime)
	local order = 0
	for _, app in ipairs(APPS) do
		local visible = not app.dev or player:GetAttribute("Dev") == true
		if visible then
			order += 1
			local cell = Kit.new("TextButton", { Text = "", BackgroundTransparency = 1, LayoutOrder = order, Parent = grid })
			local icon = Kit.new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 4), Size = UDim2.fromOffset(58, 58), BackgroundColor3 = Color.hex(app.color), Parent = cell }, { Kit.corner(16), Kit.sheen(0.75) })
			Kit.label(app.icon, { Parent = icon, Size = UDim2.new(1, -12, 1, -12), Position = UDim2.fromOffset(6, 6), TextScaled = true, TextXAlignment = Enum.TextXAlignment.Center })
			Kit.label(t(app.key), { Parent = cell, Position = UDim2.fromOffset(0, 64), Size = UDim2.new(1, 0, 0, 18), TextSize = 12, FontFace = T.bold, TextXAlignment = Enum.TextXAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd })
			cell.MouseButton1Click:Connect(function()
				launch(app)
			end)
		end
	end
end

function Phone.visible()
	return frame ~= nil and frame.Visible
end

function Phone.open()
	Phone.refresh()
	frame.Visible = true
	frame.Position = UDim2.new(0, 10, 1, 40)
	TweenService:Create(frame, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = UDim2.new(0, 10, 1, -88) }):Play()
end

function Phone.close()
	if frame then
		frame.Visible = false
	end
end

return Phone
