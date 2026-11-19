-- Client simulation: runs the real client scripts (src/first, src/client) for one player inside
-- the server simulation, as if on a phone, a tablet or a computer.
--   * code loaded by the client has its own module cache (shared modules load again, as on a real
--     client) and RunService:IsClient() is true for it;
--   * remotes are bridged both ways (FireClient reaches OnClientEvent, FireServer reaches
--     OnServerEvent, InvokeServer calls OnServerInvoke);
--   * the camera, input, GUI and sound services behave like the chosen device, and GuiObjects get
--     their AbsolutePosition / AbsoluteSize from tools/sim/gui.lua;
--   * scenarios can click buttons, press keys, trigger prompts and take snapshots of the screen
--     (drawn by tools/ui_preview.py).
-- Loaded by tools/sim.py after boot.lua and gui.lua.
local cm = Sim.classMethods
local methods = Sim.methods
local newInstance = Sim.newInstance
local PARENT, DEFAULTS, EVENTS = Sim.PARENT, Sim.DEFAULTS, Sim.EVENTS

local function props(o)
	return rawget(o, "__props")
end
local function kids(o)
	return rawget(o, "__children")
end

Sim.devices = {
	-- viewport in points, top bar inset, input
	phone = { name = "phone", viewport = Vector2.new(844, 390), inset = 58, touch = true, keyboard = false, mouse = false },
	phone_small = { name = "phone_small", viewport = Vector2.new(667, 375), inset = 58, touch = true, keyboard = false, mouse = false },
	tablet = { name = "tablet", viewport = Vector2.new(1180, 820), inset = 58, touch = true, keyboard = false, mouse = false },
	laptop = { name = "laptop", viewport = Vector2.new(1366, 768), inset = 58, touch = false, keyboard = true, mouse = true },
	desktop = { name = "desktop", viewport = Vector2.new(1920, 1080), inset = 58, touch = false, keyboard = true, mouse = true },
}

------------------------------------------------------------------ classes the client uses
for k, v in pairs({
	UIListLayout = "UIGridStyleLayout", UIGridLayout = "UIGridStyleLayout", UIPageLayout = "UIGridStyleLayout", UITableLayout = "UIGridStyleLayout",
	UIGridStyleLayout = "UILayout", UILayout = "UIComponent", UIPadding = "UIComponent", UICorner = "UIComponent", UIStroke = "UIComponent",
	UIScale = "UIComponent", UIGradient = "UIComponent", UIFlexItem = "UIComponent", UISizeConstraint = "UIConstraint",
	UIAspectRatioConstraint = "UIConstraint", UITextSizeConstraint = "UIConstraint", UIConstraint = "UIComponent", UIComponent = "UIBase",
	UIBase = "Instance", PlayerGui = "BasePlayerGui", BasePlayerGui = "Instance", PlayerScripts = "Instance", Backpack = "Instance",
	Camera = "Instance", Highlight = "Instance", SelectionBox = "PVAdornment", PVAdornment = "GuiBase3d", GuiBase3d = "GuiBase",
	GuiBase = "Instance", BoxHandleAdornment = "PVAdornment", Atmosphere = "Instance", Sky = "Instance", Clouds = "Instance",
	DepthOfFieldEffect = "PostEffect", PostEffect = "Instance",
}) do
	if PARENT[k] == nil then
		PARENT[k] = v
	end
end

local function textDefaults()
	return {
		FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"), TextSize = 14, TextColor3 = Color3.new(0, 0, 0), TextTransparency = 0,
		TextStrokeColor3 = Color3.new(0, 0, 0), TextStrokeTransparency = 1, TextScaled = false, TextWrapped = false, RichText = false,
		TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center, TextTruncate = Enum.TextTruncate.None,
		LineHeight = 1, MaxVisibleGraphemes = -1, AutoLocalize = true, Text = "",
	}
end
local baseGui = DEFAULTS.GuiObject
DEFAULTS.GuiObject = function()
	local d = baseGui and baseGui() or {}
	for k, v in pairs({
		Visible = true, Active = false, AnchorPoint = Vector2.new(0, 0), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0,
		BorderColor3 = Color3.fromRGB(27, 42, 53), BorderSizePixel = 1, ClipsDescendants = false, LayoutOrder = 0, Rotation = 0, ZIndex = 1,
		AutomaticSize = Enum.AutomaticSize.None, Selectable = false, Interactable = true, SizeConstraint = Enum.SizeConstraint.RelativeXY,
		Size = UDim2.new(0, 100, 0, 100), Position = UDim2.new(0, 0, 0, 0),
	}) do
		if d[k] == nil then
			d[k] = v
		end
	end
	-- only text objects have Text (a Frame's child called "Text" must stay reachable as frame.Text)
	d.Text = nil
	return d
end
DEFAULTS.TextLabel = textDefaults
DEFAULTS.TextBox = function()
	local d = textDefaults()
	d.PlaceholderText = ""
	d.ClearTextOnFocus = true
	d.MultiLine = false
	return d
end
DEFAULTS.GuiButton = function()
	return { AutoButtonColor = true, Modal = false, Selected = false, Selectable = true }
end
DEFAULTS.TextButton = textDefaults
DEFAULTS.ImageLabel = function()
	return { Image = "", ImageColor3 = Color3.new(1, 1, 1), ImageTransparency = 0, ScaleType = Enum.ScaleType.Stretch, ImageRectOffset = Vector2.zero, ImageRectSize = Vector2.zero }
end
DEFAULTS.ImageButton = DEFAULTS.ImageLabel
DEFAULTS.ScrollingFrame = function()
	return {
		CanvasSize = UDim2.new(0, 0, 2, 0), CanvasPosition = Vector2.zero, ScrollBarThickness = 12, ScrollingDirection = Enum.ScrollingDirection.XY,
		AutomaticCanvasSize = Enum.AutomaticSize.None, ScrollingEnabled = true, ScrollBarImageColor3 = Color3.new(1, 1, 1), ScrollBarImageTransparency = 0,
		ElasticBehavior = Enum.ElasticBehavior.WhenScrollable, VerticalScrollBarInset = Enum.ScrollBarInset.None, HorizontalScrollBarInset = Enum.ScrollBarInset.None,
	}
end
DEFAULTS.LayerCollector = function()
	return { Enabled = true, ResetOnSpawn = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }
end
DEFAULTS.ScreenGui = function()
	return { DisplayOrder = 0, IgnoreGuiInset = false, ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets, ClipToDeviceSafeArea = true }
end
DEFAULTS.BillboardGui = function()
	return {
		Size = UDim2.new(0, 0, 0, 0), StudsOffset = Vector3.new(0, 0, 0), StudsOffsetWorldSpace = Vector3.new(0, 0, 0), ExtentsOffset = Vector3.new(0, 0, 0),
		ExtentsOffsetWorldSpace = Vector3.new(0, 0, 0), AlwaysOnTop = false, MaxDistance = math.huge, LightInfluence = 1, Brightness = 1, SizeOffset = Vector2.zero,
		ClipsDescendants = false, Active = false,
	}
end
DEFAULTS.SurfaceGui = function()
	return { Face = Enum.NormalId.Front, CanvasSize = Vector2.new(800, 600), SizingMode = Enum.SurfaceGuiSizingMode.FixedSize, PixelsPerStud = 50, AlwaysOnTop = false, LightInfluence = 1, Brightness = 1, ZOffset = 0 }
end
DEFAULTS.UIListLayout = function()
	return { FillDirection = Enum.FillDirection.Vertical, HorizontalAlignment = Enum.HorizontalAlignment.Left, VerticalAlignment = Enum.VerticalAlignment.Top, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 0), Wraps = false }
end
DEFAULTS.UIGridLayout = function()
	return {
		CellSize = UDim2.new(0, 100, 0, 100), CellPadding = UDim2.new(0, 5, 0, 5), FillDirection = Enum.FillDirection.Horizontal, FillDirectionMaxCells = 0,
		StartCorner = Enum.StartCorner.TopLeft, HorizontalAlignment = Enum.HorizontalAlignment.Left, VerticalAlignment = Enum.VerticalAlignment.Top, SortOrder = Enum.SortOrder.LayoutOrder,
	}
end
DEFAULTS.UIPadding = function()
	return { PaddingLeft = UDim.new(0, 0), PaddingRight = UDim.new(0, 0), PaddingTop = UDim.new(0, 0), PaddingBottom = UDim.new(0, 0) }
end
DEFAULTS.UICorner = function()
	return { CornerRadius = UDim.new(0, 8) }
end
DEFAULTS.UIStroke = function()
	return { Color = Color3.new(0, 0, 0), Thickness = 1, Transparency = 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual, LineJoinMode = Enum.LineJoinMode.Round, Enabled = true }
end
DEFAULTS.UIScale = function()
	return { Scale = 1 }
end
DEFAULTS.UIGradient = function()
	return { Color = ColorSequence.new(Color3.new(1, 1, 1)), Transparency = NumberSequence.new(0), Rotation = 0, Offset = Vector2.zero, Enabled = true }
end
DEFAULTS.UISizeConstraint = function()
	return { MinSize = Vector2.new(0, 0), MaxSize = Vector2.new(math.huge, math.huge) }
end
DEFAULTS.UIAspectRatioConstraint = function()
	return { AspectRatio = 1, AspectType = Enum.AspectType.FitWithinMaxSize, DominantAxis = Enum.DominantAxis.Width }
end
DEFAULTS.UITextSizeConstraint = function()
	return { MinTextSize = 1, MaxTextSize = 100 }
end
DEFAULTS.Highlight = function()
	return { FillColor = Color3.new(1, 0, 0), OutlineColor = Color3.new(1, 1, 1), FillTransparency = 0.5, OutlineTransparency = 0, DepthMode = Enum.HighlightDepthMode.AlwaysOnTop, Enabled = true }
end
DEFAULTS.SelectionBox = function()
	return { Color3 = Color3.new(0.05, 0.4, 0.75), LineThickness = 0.15, SurfaceColor3 = Color3.new(0.05, 0.4, 0.75), SurfaceTransparency = 1, Visible = true, Transparency = 0 }
end
DEFAULTS.Camera = function()
	return { CFrame = CFrame.new(0, 10, 20), FieldOfView = 70, ViewportSize = Vector2.new(1280, 720), CameraType = Enum.CameraType.Custom, Focus = CFrame.new(), NearPlaneZ = -0.1, HeadLocked = true, DiagonalFieldOfView = 80, MaxAxisFieldOfView = 90 }
end
DEFAULTS.Atmosphere = function()
	return { Density = 0.3, Offset = 0, Color = Color3.new(0.78, 0.78, 0.78), Decay = Color3.new(0.42, 0.44, 0.48), Glare = 0, Haze = 0 }
end

for _, n in ipairs({
	"MouseEnter", "MouseLeave", "MouseMoved", "MouseWheelForward", "MouseWheelBackward", "MouseButton2Click", "MouseButton2Down", "MouseButton2Up",
	"TouchTap", "TouchStarted", "TouchMoved", "TouchEnded", "TouchLongPress", "TouchPan", "TouchPinch", "TouchSwipe", "TouchTapInWorld",
	"LastInputTypeChanged", "WindowFocused", "WindowFocusReleased", "GamepadConnected", "GamepadDisconnected", "SelectionGained", "SelectionLost",
	"Focused", "ReturnPressedFromOnScreenKeyboard", "MenuOpened", "MenuClosed", "PromptTriggered", "PromptTriggerEnded", "PromptShown", "PromptHidden",
	"InputBegan", "InputEnded", "InputChanged", "DeviceRotationChanged", "JumpRequest", "TextChanged", "TeleportInitFailed", "OnTeleport",
	"MessageReceived", "SendingMessage", "PreRender", "RenderStepped", "Move", "Button1Down", "Button1Up", "Button2Down", "Button2Up", "WheelForward", "WheelBackward",
}) do
	EVENTS[n] = true
end

------------------------------------------------------------------ who is running: client or server
local function fromClient()
	for level = 2, 80 do
		local info = debug.getinfo(level, "S")
		if not info then
			return false
		end
		local src = info.source or ""
		if src:sub(1, 8) == "@client:" then
			return true
		elseif src:sub(1, 5) == "@src/" or src:sub(1, 11) == "@scenarios/" then
			return false
		end
	end
	return false
end
Sim.fromClient = fromClient
function cm.RunService.IsServer()
	return not fromClient()
end
function cm.RunService.IsClient()
	return fromClient()
end
local renderBound = {}
function cm.RunService.BindToRenderStep(_, name, priority, fn)
	renderBound[name] = { priority = priority or 0, fn = fn }
end
function cm.RunService.UnbindFromRenderStep(_, name)
	renderBound[name] = nil
end

------------------------------------------------------------------ client modules
local cache, loading = {}, {}
local function relPath(full)
	return full:match("(src/.*)$") or full
end
local clientRequire
local function envFor(inst)
	return setmetatable({ script = inst, require = clientRequire }, { __index = _G })
end
function clientRequire(m)
	if type(m) ~= "table" or not rawget(m, "__inst") then
		error("require expects a ModuleScript, got " .. typeof(m), 2)
	end
	if cache[m] ~= nil then
		return cache[m]
	end
	local src = props(m).__src
	if not src or m.ClassName ~= "ModuleScript" then
		error("Attempted to require a non-ModuleScript " .. m:GetFullName(), 2)
	end
	if loading[m] then
		error("Requested module was required recursively: " .. m:GetFullName(), 2)
	end
	loading[m] = true
	local chunk, err = load(__read(src), "@client:" .. relPath(src), "t", envFor(m))
	if not chunk then
		loading[m] = nil
		error(err, 0)
	end
	local ok, result = pcall(chunk)
	loading[m] = nil
	if not ok then
		error("Requested module experienced an error while loading: " .. tostring(result), 0)
	end
	if result == nil then
		error("Module code did not return exactly one value: " .. m:GetFullName(), 0)
	end
	cache[m] = result
	return result
end
Sim.clientRequire = clientRequire

local function runLocal(inst)
	local src = props(inst).__src
	local chunk, err = load(__read(src), "@client:" .. relPath(src), "t", envFor(inst))
	if not chunk then
		Sim.fail("client syntax: " .. tostring(err))
		return
	end
	Sim.resume(coroutine.create(chunk))
end

------------------------------------------------------------------ remotes, both ways
local function copyArgs(...)
	local out = { n = select("#", ...) }
	local function copy(v, depth)
		if type(v) == "function" then
			return nil
		end
		if type(v) == "table" and not rawget(v, "__inst") and not getmetatable(v) then
			if depth > 20 then
				return nil
			end
			local o = {}
			for k, x in pairs(v) do
				o[k] = copy(x, depth + 1)
			end
			return o
		end
		return v
	end
	for i = 1, out.n do
		out[i] = copy((select(i, ...)), 0)
	end
	return out
end

local function toClient(remote, player, args)
	local c = Sim.client
	if not c or c.player ~= player then
		return
	end
	c.received = c.received + 1
	task.defer(function()
		if c.player.Parent then
			remote.OnClientEvent:Fire(table.unpack(args, 1, args.n))
		end
	end)
end
local baseFireClient = cm.RemoteEvent.FireClient
cm.RemoteEvent.FireClient = function(self, player, ...)
	baseFireClient(self, player, ...)
	toClient(self, player, copyArgs(...))
end
local baseFireAll = cm.RemoteEvent.FireAllClients
cm.RemoteEvent.FireAllClients = function(self, ...)
	baseFireAll(self, ...)
	if Sim.client then
		toClient(self, Sim.client.player, copyArgs(...))
	end
end
cm.RemoteEvent.FireServer = function(self, ...)
	local c = Sim.client
	if not c then
		error("FireServer can only be called from the client", 2)
	end
	local args = copyArgs(...)
	c.sent = c.sent + 1
	table.insert(c.fired, { name = props(self).Name, args = args, t = Sim.now })
	task.defer(function()
		if c.player.Parent then
			self.OnServerEvent:Fire(c.player, table.unpack(args, 1, args.n))
		end
	end)
end
cm.RemoteFunction.InvokeServer = function(self, ...)
	local c = Sim.client
	if not c then
		error("InvokeServer can only be called from the client", 2)
	end
	local f = props(self).OnServerInvoke
	if not f then
		error("no OnServerInvoke for " .. tostring(props(self).Name), 2)
	end
	local args = copyArgs(...)
	table.insert(c.fired, { name = props(self).Name, args = args, t = Sim.now })
	task.wait(0.04)
	local res = table.pack(f(c.player, table.unpack(args, 1, args.n)))
	local back = copyArgs(table.unpack(res, 1, res.n))
	return table.unpack(back, 1, back.n)
end
cm.RemoteFunction.InvokeClient = function(self, player, ...)
	local f = props(self).OnClientInvoke
	if not f or not Sim.client or Sim.client.player ~= player then
		error("InvokeClient: no client", 2)
	end
	return f(...)
end

------------------------------------------------------------------ camera
cm.Camera = {}
local function camBasis(cam)
	local p = props(cam)
	local vp = p.ViewportSize or Vector2.new(1280, 720)
	local tanHalf = math.tan(math.rad((p.FieldOfView or 70) / 2))
	return p.CFrame or CFrame.new(), vp, tanHalf, vp.X / math.max(vp.Y, 1)
end
function cm.Camera.WorldToViewportPoint(self, pos)
	local cf, vp, tanHalf, aspect = camBasis(self)
	local rel = cf:PointToObjectSpace(pos)
	local depth = -rel.Z
	if depth <= 1e-4 then
		return Vector3.new(0, 0, depth), false
	end
	local nx = rel.X / (depth * tanHalf * aspect)
	local ny = rel.Y / (depth * tanHalf)
	local x, y = (nx + 1) / 2 * vp.X, (1 - ny) / 2 * vp.Y
	return Vector3.new(x, y, depth), x >= 0 and x <= vp.X and y >= 0 and y <= vp.Y
end
function cm.Camera.WorldToScreenPoint(self, pos)
	local v, on = cm.Camera.WorldToViewportPoint(self, pos)
	local inset = Sim.client and Sim.client.device.inset or 0
	return Vector3.new(v.X, v.Y - inset, v.Z), on
end
function cm.Camera.ViewportPointToRay(self, x, y, depth)
	local cf, vp, tanHalf, aspect = camBasis(self)
	local dx = (2 * x / vp.X - 1) * tanHalf * aspect
	local dy = (1 - 2 * y / vp.Y) * tanHalf
	local dir = cf:VectorToWorldSpace(Vector3.new(dx, dy, -1)).Unit
	return Ray.new(cf.Position + dir * (depth or 0), dir)
end
function cm.Camera.ScreenPointToRay(self, x, y, depth)
	local inset = Sim.client and Sim.client.device.inset or 0
	return cm.Camera.ViewportPointToRay(self, x, y + inset, depth)
end
function cm.Camera.GetPartsObscuringTarget()
	return {}
end
function cm.Camera.ZoomToExtents() end
function cm.Camera.Interpolate() end

------------------------------------------------------------------ input, GUI and sound services
cm.UserInputService = cm.UserInputService or {}
local keysDown = {}
function cm.UserInputService.GetMouseLocation()
	local c = Sim.client
	if c and c.mouse then
		return c.mouse
	end
	local vp = Sim.Gui.viewport()
	return Vector2.new(vp.X / 2, vp.Y / 2)
end
function cm.UserInputService.GetMouseDelta()
	return Vector2.zero
end
function cm.UserInputService.IsKeyDown(_, key)
	return keysDown[key] == true
end
function cm.UserInputService.IsMouseButtonPressed()
	return false
end
function cm.UserInputService.GetFocusedTextBox()
	return nil
end
function cm.UserInputService.GetLastInputType()
	local c = Sim.client
	return (c and c.device.touch) and Enum.UserInputType.Touch or Enum.UserInputType.MouseMovement
end
function cm.UserInputService.GetKeysPressed()
	return {}
end
function cm.UserInputService.GetConnectedGamepads()
	return {}
end
function cm.UserInputService.GetGamepadConnected()
	return false
end
function cm.UserInputService.GetNavigationGamepads()
	return {}
end
function cm.UserInputService.GetStringForKeyCode(_, k)
	return k and k.Name or ""
end
function cm.UserInputService.GetImageForKeyCode()
	return ""
end

cm.GuiService = cm.GuiService or {}
function cm.GuiService.GetGuiInset()
	local c = Sim.client
	return Vector2.new(0, c and c.device.inset or 0), Vector2.new(0, 0)
end
function cm.GuiService.IsTenFootInterface()
	return false
end
function cm.GuiService.GetEmotesMenuOpen()
	return false
end
function cm.GuiService.SetEmotesMenuOpen() end
function cm.GuiService.GetInspectMenuEnabled()
	return false
end
function cm.GuiService.SetInspectMenuEnabled() end
function cm.GuiService.CloseInspectMenu() end

cm.StarterGui = cm.StarterGui or {}
function cm.StarterGui.SetCoreGuiEnabled() end
function cm.StarterGui.GetCoreGuiEnabled()
	return true
end
function cm.StarterGui.SetCore() end
function cm.StarterGui.GetCore()
	return nil
end

cm.SoundService = cm.SoundService or {}
function cm.SoundService.PlayLocalSound() end
function cm.SoundService.SetListener() end

cm.TextService = cm.TextService or {}
function cm.TextService.GetTextSize(_, text, size, _, frame)
	local w, h = Sim.measureText(tostring(text), size or 14, false, frame and frame.X < 1e6 and frame.X or nil)
	return Vector2.new(w, h)
end

cm.ReplicatedFirst = cm.ReplicatedFirst or {}
function cm.ReplicatedFirst.RemoveDefaultLoadingScreen() end
cm.TeleportService = cm.TeleportService or {}
function cm.TeleportService.SetTeleportGui() end
function cm.TeleportService.GetLocalPlayerTeleportData()
	return nil
end
function cm.TeleportService.GetTeleportSetting()
	return nil
end
function cm.TeleportService.SetTeleportSetting() end
cm.ContextActionService = cm.ContextActionService or {}
function cm.ContextActionService.BindAction() end
function cm.ContextActionService.BindActionAtPriority() end
function cm.ContextActionService.UnbindAction() end
function cm.ContextActionService.SetTitle() end
function cm.ContextActionService.SetImage() end
function cm.ContextActionService.SetPosition() end
function cm.ContextActionService.GetButton()
	return nil
end
cm.HapticService = cm.HapticService or {}
function cm.HapticService.IsVibrationSupported()
	return false
end
function cm.HapticService.SetMotor() end

cm.Player.GetMouse = function(self)
	local c = Sim.client
	if not c then
		error("GetMouse can only be called from the client", 2)
	end
	if not c.mouseObject then
		local m = newInstance("Mouse")
		props(m).Hit = CFrame.new()
		props(m).Icon = ""
		props(m).X, props(m).Y = 0, 0
		c.mouseObject = m
	end
	return c.mouseObject
end

------------------------------------------------------------------ starting a client
local function render()
	local c = Sim.client
	if not c or not c.player.Parent then
		return
	end
	local rs = game:GetService("RunService")
	local dt = Sim.clientFrame
	local list = {}
	for name, b in pairs(renderBound) do
		table.insert(list, { name = name, priority = b.priority, fn = b.fn })
	end
	table.sort(list, function(a, b)
		return a.priority < b.priority
	end)
	for _, b in ipairs(list) do
		local ok, err = pcall(b.fn, dt)
		if not ok then
			Sim.fail("render step " .. b.name .. ": " .. tostring(err))
		end
	end
	rs.PreRender:Fire(dt)
	rs.RenderStepped:Fire(dt)
	Sim.schedule(Sim.now + dt, nil, nil, render)
end
Sim.clientFrame = 1 / 20

-- Boots the client of `player` on `device` (a name from Sim.devices or a table like them)
function Sim.startClient(player, device)
	local dev = type(device) == "table" and device or Sim.devices[device or "desktop"]
	if not dev then
		error("unknown device " .. tostring(device), 2)
	end
	Sim.client = { player = player, device = dev, sent = 0, received = 0, fired = {}, mouse = nil }
	local players = game:GetService("Players")
	props(players).LocalPlayer = player
	for _, n in ipairs({ "PlayerGui", "PlayerScripts", "Backpack" }) do
		if not player:FindFirstChild(n) then
			local f = newInstance(n)
			f.Name = n
			f.Parent = player
		end
	end
	local cam = workspace:FindFirstChildOfClass("Camera") or newInstance("Camera")
	cam.Name = "Camera"
	props(cam).ViewportSize = dev.viewport
	cam.Parent = workspace
	props(workspace).CurrentCamera = cam
	local uis = game:GetService("UserInputService")
	for k, v in pairs({
		TouchEnabled = dev.touch, KeyboardEnabled = dev.keyboard, MouseEnabled = dev.mouse, GamepadEnabled = false, VREnabled = false,
		AccelerometerEnabled = dev.touch, GyroscopeEnabled = dev.touch, MouseBehavior = Enum.MouseBehavior.Default, MouseIconEnabled = true,
		MouseDeltaSensitivity = 1, OnScreenKeyboardVisible = false, ModalEnabled = false,
	}) do
		props(uis)[k] = v
	end
	local gs = game:GetService("GuiService")
	props(gs).MenuIsOpen = false
	props(gs).AutoSelectGuiEnabled = true
	props(gs).TouchControlsEnabled = true
	-- StarterPlayerScripts is copied into PlayerScripts, then the local scripts run
	local starter = game:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts")
	local client = starter and starter:FindFirstChild("Client")
	if not client then
		error("no client scripts mounted (StarterPlayer.StarterPlayerScripts.Client)", 2)
	end
	local copy = client:Clone()
	copy.Parent = player.PlayerScripts
	local first = game:GetService("ReplicatedFirst")
	for _, s in ipairs(first:GetChildren()) do
		if s.ClassName == "LocalScript" then
			runLocal(s)
		end
	end
	runLocal(copy:FindFirstChild("Main"))
	Sim.schedule(Sim.now + Sim.clientFrame, nil, nil, render)
	return Sim.client
end

------------------------------------------------------------------ driving the client
local function guiOf(player)
	return (player or (Sim.client and Sim.client.player)):FindFirstChild("PlayerGui")
end

-- the first GuiObject on screen whose text contains `pattern` (plain text) and that is shown
function Sim.findText(pattern, opts)
	local pg = guiOf()
	if not pg then
		return nil
	end
	for _, d in ipairs(pg:GetDescendants()) do
		if Sim.Gui.isText(d) and Sim.Gui.shown(d) then
			local text = Sim.Gui.textOf(d)
			if text:find(pattern, 1, true) and (not opts or not opts.button or d:IsA("GuiButton")) then
				return d
			end
		end
	end
	return nil
end

-- the button a text is on (itself, or the closest GuiButton ancestor)
local function buttonOf(o)
	local n = o
	while n and not n:IsA("LayerCollector") do
		if n:IsA("GuiButton") then
			return n
		end
		n = n.Parent
	end
	return nil
end

-- clicks a button (or the button a text is on); returns the button clicked
function Sim.click(target)
	local b = type(target) == "string" and Sim.findText(target) or target
	b = b and buttonOf(b)
	if not b then
		Sim.fail("click: no button " .. tostring(type(target) == "string" and target or (target and target.Name)))
		return nil
	end
	b.MouseButton1Down:Fire(0, 0)
	b.MouseButton1Up:Fire(0, 0)
	b.MouseButton1Click:Fire()
	b.Activated:Fire({ UserInputType = Enum.UserInputType.MouseButton1 }, 1)
	task.wait(0.1)
	return b
end

local function inputObject(kind, key)
	return {
		KeyCode = key or Enum.KeyCode.Unknown, UserInputType = kind, UserInputState = Enum.UserInputState.Begin,
		Position = Vector3.new(0, 0, 0), Delta = Vector3.new(0, 0, 0),
	}
end

-- presses and releases a key
function Sim.press(key, hold)
	local uis = game:GetService("UserInputService")
	keysDown[key] = true
	uis.InputBegan:Fire(inputObject(Enum.UserInputType.Keyboard, key), false)
	task.wait(hold or 0.1)
	keysDown[key] = nil
	uis.InputEnded:Fire(inputObject(Enum.UserInputType.Keyboard, key), false)
	task.wait(0.05)
end

-- triggers the ProximityPrompt shown on a model (as pressing E or tapping it)
function Sim.trigger(model)
	for _, d in ipairs(model:GetDescendants()) do
		if d.ClassName == "ProximityPrompt" and d.Enabled then
			d.Triggered:Fire(Sim.client.player)
			d.TriggerEnded:Fire(Sim.client.player)
			task.wait(0.1)
			return true
		end
	end
	return false
end

-- remotes the client fired, newest last
function Sim.clientFired(name)
	local out = {}
	for _, f in ipairs(Sim.client and Sim.client.fired or {}) do
		if not name or f.name == name then
			table.insert(out, f)
		end
	end
	return out
end

-- a picture of the screen for tools/ui_preview.py (ignored when nothing draws them)
function Sim.snapshot(name)
	if __snapshot then
		__snapshot(name, Sim.client and Sim.client.device.name or "", Sim.dumpGui(), Sim.Gui.viewport(), Sim.client and Sim.client.device.inset or 0)
	end
end
