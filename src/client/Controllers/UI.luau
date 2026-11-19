--!nonstrict
-- Screen manager, toasts and shared UI helpers.
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local NetDef = require(Shared.Net)
local Locale = require(Shared.Locale)
local Signal = require(Shared.Util.Signal)
local Kit = require(script.Parent.Parent.UI.Kit)
local Core = require(script.Parent.Parent.Core)

local UI = {}
UI.screens = {}
UI.current = nil
UI.profile = "desktop" -- "phone" | "tablet" | "desktop"
UI.scale = 1
UI.ProfileChanged = Signal.new() -- (profile)
local T = Kit.Theme
local toastHolder

-- Screens are designed in "units": the UIScale turns them into points. Each kind of screen has a
-- design size (what fits at scale 1) and limits, so text stays readable on a phone (never below
-- 0.68: 16-unit text is still 11 points) and does not get huge on a big monitor.
local DESIGN = {
	phone = { w = 960, h = 400, min = 0.68, max = 1.0 },
	tablet = { w = 1180, h = 760, min = 0.8, max = 1.15 },
	desktop = { w = 1400, h = 800, min = 0.72, max = 1.3 },
}

function UI.root()
	return UI.gui
end

function UI.isTouch()
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

-- the area the HUD can use (under the Roblox top bar) and the kind of screen it is
local function measure()
	local size = UI.gui and UI.gui.AbsoluteSize or Vector2.zero
	if size.X < 10 or size.Y < 10 then
		local cam = workspace.CurrentCamera
		size = cam and cam.ViewportSize or Vector2.new(1280, 720)
	end
	local short = math.min(size.X, size.Y)
	local profile = short < 520 and "phone" or (UI.isTouch() and "tablet" or "desktop")
	local d = DESIGN[profile]
	return profile, math.clamp(math.min(size.X / d.w, size.Y / d.h), d.min, d.max)
end

function UI.rescale()
	if not UI.uiScale then
		return
	end
	local profile, scale = measure()
	UI.uiScale.Scale = scale
	UI.scale = scale
	local changed = profile ~= UI.profile
	UI.profile = profile
	Kit.profile = profile
	Kit.fitWindows()
	if changed then
		UI.ProfileChanged:Fire(profile)
	end
end

-- Roblox's thumbstick and jump button sit above our screens on touch devices: while a window or
-- the build catalog is open they are hidden, so a tap always reaches the window (reasons are
-- counted: the controls come back when the last one goes)
local touchBlocks = {}
function UI.blockTouch(reason, on)
	touchBlocks[reason] = on and true or nil
	local GuiService = game:GetService("GuiService")
	pcall(function()
		GuiService.TouchControlsEnabled = next(touchBlocks) == nil
	end)
end

function UI.register(name, screen)
	UI.screens[name] = screen
	if screen.create then
		local ok, err = pcall(screen.create, UI.gui)
		if not ok then
			warn("[UI] create " .. name .. " failed: " .. tostring(err))
		end
	end
end

function UI.open(name, arg)
	local s = UI.screens[name]
	if not s then
		return
	end
	if s.modal ~= false and UI.current and UI.current ~= name then
		UI.close(UI.current)
	end
	if s.modal ~= false then
		UI.current = name
		UI.blockTouch("window", true)
		if Core.C.Audio then
			Core.C.Audio.play("open")
		end
	end
	local ok, err = pcall(s.open, arg)
	if not ok then
		warn("[UI] open " .. name .. ": " .. tostring(err))
	end
end

function UI.close(name)
	name = name or UI.current
	local s = name and UI.screens[name]
	if s and s.close then
		pcall(s.close)
	end
	if UI.current == name then
		UI.current = nil
		UI.blockTouch("window", false)
	end
end

function UI.toggle(name, arg)
	if UI.current == name then
		UI.close(name)
	else
		UI.open(name, arg)
	end
end

function UI.refreshAll()
	for name, s in pairs(UI.screens) do
		if s.refresh and (s.visible == nil or s.visible()) then
			local ok, err = pcall(s.refresh)
			if not ok then
				warn("[UI] refresh " .. name .. ": " .. tostring(err))
			end
		end
	end
end

local KIND_COLOR = { info = T.wood, success = T.green, error = T.red, warning = T.gold, level = T.gold }

function UI.toast(text, kind)
	if not toastHolder then
		return
	end
	-- under the tutorial banner while it is on screen
	local tut = Core.C.Tutorial
	toastHolder.Position = UDim2.new(0.5, 0, 0, (tut and tut.active and tut.active()) and 134 or 92)
	local f = Kit.panel({ Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = T.paper, Parent = toastHolder })
	f:FindFirstChildOfClass("UIStroke").Color = KIND_COLOR[kind] or T.wood
	Kit.padding(12, 8).Parent = f
	Kit.label(text, { Parent = f, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextSize = 18, FontFace = T.bold, TextColor3 = kind == "error" and T.red or T.ink })
	Kit.popIn(f, 0.7)
	task.delay(kind == "level" and 5 or 3.2, function()
		if f.Parent then
			TweenService:Create(f, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
			for _, d in ipairs(f:GetDescendants()) do
				if d:IsA("TextLabel") then
					TweenService:Create(d, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
				elseif d:IsA("UIStroke") then
					TweenService:Create(d, TweenInfo.new(0.3), { Transparency = 1 }):Play()
				end
			end
			task.wait(0.35)
			f:Destroy()
		end
	end)
	local items = {}
	for _, c in ipairs(toastHolder:GetChildren()) do
		if c:IsA("Frame") then
			table.insert(items, c)
		end
	end
	if #items > 5 then
		items[1]:Destroy()
	end
end

function UI.Init()
	local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
	UI.gui = Kit.new("ScreenGui", { Name = "RamenUI", ResetOnSpawn = false, IgnoreGuiInset = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = pg })
	UI.uiScale = Kit.new("UIScale", { Parent = UI.gui })
	UI.rescale()
	UI.gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(UI.rescale)
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(UI.rescale)
	end
	-- messages appear under the objective, in the middle of the screen
	toastHolder = Kit.new("Frame", { Name = "Toasts", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 92), Size = UDim2.fromOffset(460, 300), ZIndex = 20, Parent = UI.gui }, { Kit.list(Enum.FillDirection.Vertical, 6, Enum.HorizontalAlignment.Center) })
	local screens = script.Parent.Parent.UI.Screens
	for _, m in ipairs(screens:GetChildren()) do
		if m:IsA("ModuleScript") then
			local ok, s = pcall(require, m)
			if ok then
				Core.Screens[m.Name] = s
			else
				warn("[UI] screen " .. m.Name .. ": " .. tostring(s))
			end
		end
	end
	for name, s in pairs(Core.Screens) do
		UI.register(name, s)
	end
	NetDef.event("Notify").OnClientEvent:Connect(function(key, params, kind)
		UI.toast(Locale.t(key, params), kind)
		if kind == "error" and Core.C.Audio then
			Core.C.Audio.play("error")
		end
	end)
	Locale.Changed:Connect(UI.refreshAll)
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.ButtonB then
			if UI.current then
				UI.close(UI.current)
			end
		end
	end)
end

local function vipChat()
	local TextChatService = game:GetService("TextChatService")
	pcall(function()
		TextChatService.OnIncomingMessage = function(message)
			local props = Instance.new("TextChatMessageProperties")
			local source = message.TextSource
			local p = source and Players:GetPlayerByUserId(source.UserId)
			if p and p:GetAttribute("VIP") then
				props.PrefixText = "<font color=\"#D4A23C\">[VIP]</font> " .. message.PrefixText
			end
			return props
		end
	end)
end

function UI.Start()
	vipChat()
	local Data = Core.C.Data
	Data.Changed:Connect(function()
		UI.refreshAll()
	end)
	Data.SessionChanged:Connect(UI.refreshAll)
	Data.DayChanged:Connect(function(state)
		local hud = UI.screens.HUD
		if hud and hud.day then
			hud.day(state)
		end
	end)
	UI.refreshAll()
end

return UI
