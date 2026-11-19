--!nonstrict
-- Phone ("More"): the screens that are not needed every minute, as apps. Opens from the 📱 button
-- of the HUD and closes when an app is opened. Everything bought with yen is in the shop.
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
	{ id = "Goals", icon = "🎯", key = "ui.goals", color = "#F27A2E" },
	{ id = "Gifts", icon = "🎁", key = "ui.gifts", color = "#E0405A" },
	{ id = "Invite", icon = "👋", key = "ui.invite", color = "#7F3AB3" },
	{ id = "Premium", icon = "💎", key = "ui.premium", color = "#2E5A8C" },
	{ id = "Codes", icon = "🎟️", key = "ui.codes", color = "#3A8F8A" },
	{ id = "Help", icon = "❓", key = "ui.howto", color = "#2EA3B3" },
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
		Name = "Phone", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -92), Size = UDim2.fromOffset(300, 400),
		BackgroundColor3 = Color3.fromRGB(28, 26, 30), Visible = false, ZIndex = 9, Parent = root,
	}, { Kit.corner(30), Kit.stroke(Color3.fromRGB(70, 66, 72), 3) })
	-- screen
	local screen = Kit.new("Frame", { Position = UDim2.fromOffset(10, 12), Size = UDim2.new(1, -20, 1, -34), BackgroundColor3 = T.paper, Parent = frame }, { Kit.corner(22) })
	Kit.new("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(255, 240, 244), Color3.fromRGB(244, 235, 221)), Rotation = 90, Parent = screen })
	-- status bar with the time and a little notch
	clock = Kit.label("", { Parent = screen, Position = UDim2.fromOffset(16, 6), Size = UDim2.fromOffset(80, 18), TextSize = 13, FontFace = T.bold })
	Kit.label("📶 🔋", { Parent = screen, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 6), Size = UDim2.fromOffset(60, 18), TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right })
	Kit.new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 6), Size = UDim2.fromOffset(70, 14), BackgroundColor3 = Color3.fromRGB(28, 26, 30), Parent = screen }, { Kit.corner(7) })
	Kit.title("🌸 Sakura", { Parent = screen, Position = UDim2.fromOffset(16, 30), Size = UDim2.new(1, -32, 0, 28), TextSize = 22 })
	grid = Kit.new("Frame", { Position = UDim2.fromOffset(10, 66), Size = UDim2.new(1, -20, 1, -76), BackgroundTransparency = 1, Parent = screen }, { Kit.grid(82, 92, 4) })
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
			local name = Kit.label(t(app.key), { Parent = cell, Position = UDim2.fromOffset(0, 65), Size = UDim2.new(1, 0, 0, 20), TextScaled = true, FontFace = T.bold, TextXAlignment = Enum.TextXAlignment.Center, TextWrapped = false })
			Kit.new("UITextSizeConstraint", { MaxTextSize = 14, MinTextSize = 9, Parent = name })
			Kit.press(cell)
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
	-- slides up above the dock; on a phone screen there is no room above it, so it stands on the
	-- left half of the screen, clear of the dock
	local goal
	if Kit.profile == "phone" then
		frame.AnchorPoint = Vector2.new(0.5, 0.5)
		frame.Size = UDim2.fromOffset(300, 380)
		goal = UDim2.new(0.25, 0, 0.5, 0)
		frame.Position = UDim2.new(0.25, 0, 1.2, 0)
	else
		local x = Kit.profile == "desktop" and 0.5 or 0.55
		frame.AnchorPoint = Vector2.new(0.5, 1)
		frame.Size = UDim2.fromOffset(300, 400)
		goal = UDim2.new(x, 0, 1, -92)
		frame.Position = UDim2.new(x, 0, 1, 40)
	end
	TweenService:Create(frame, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = goal }):Play()
end

function Phone.close()
	if frame then
		frame.Visible = false
	end
end

return Phone
