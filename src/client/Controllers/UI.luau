--!nonstrict
-- Screen manager, toasts and shared UI helpers.
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local NetDef = require(Shared.Net)
local Locale = require(Shared.Locale)
local Kit = require(script.Parent.Parent.UI.Kit)
local Core = require(script.Parent.Parent.Core)

local UI = {}
UI.screens = {}
UI.current = nil
local T = Kit.Theme
local toastHolder

function UI.root()
	return UI.gui
end

function UI.isTouch()
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
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
	local f = Kit.panel({ Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = T.paper, Parent = toastHolder })
	f:FindFirstChildOfClass("UIStroke").Color = KIND_COLOR[kind] or T.wood
	Kit.padding(10, 6).Parent = f
	Kit.label(text, { Parent = f, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextSize = 18, FontFace = T.bold, TextColor3 = kind == "error" and T.red or T.ink })
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
	local scale = Kit.new("UIScale", { Parent = UI.gui })
	local function rescale()
		local cam = workspace.CurrentCamera
		local v = cam and cam.ViewportSize or Vector2.new(1280, 720)
		scale.Scale = math.clamp(math.min(v.X / 1280, v.Y / 760) * 1.05, 0.55, 1.25)
	end
	rescale()
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
	end
	toastHolder = Kit.new("Frame", { Name = "Toasts", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 52), Size = UDim2.fromOffset(460, 300), Parent = UI.gui }, { Kit.list(Enum.FillDirection.Vertical, 6, Enum.HorizontalAlignment.Center) })
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
		if state.phase == "report" and state.report then
			UI.open("DayReport", state.report)
		end
	end)
	UI.refreshAll()
end

return UI
