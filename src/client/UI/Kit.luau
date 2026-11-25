--!nonstrict
-- Tiny declarative UI toolkit + the visual theme (washi paper, dark wood, lacquer red, gold).
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Color = require(Shared.Util.Color)
local Locale = require(Shared.Locale)

local Kit = {}

Kit.Theme = {
	paper = Color.hex("#F4EBDD"),
	paperDark = Color.hex("#E6D7BF"),
	wood = Color.hex("#5B3A24"),
	woodLight = Color.hex("#8A5A36"),
	ink = Color.hex("#2B2320"),
	muted = Color.hex("#7A6A5A"),
	red = Color.hex("#B3262E"),
	redDark = Color.hex("#7A1A1F"),
	gold = Color.hex("#D4A23C"),
	green = Color.hex("#5E8F3A"),
	blue = Color.hex("#2E5A8C"),
	white = Color.hex("#FFFFFF"),
	shadow = Color.hex("#000000"),
	locked = Color.hex("#B8AFA2"),
	title = Font.new("rbxasset://fonts/families/FredokaOne.json"),
	body = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Medium),
	bold = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold),
}
local T = Kit.Theme

-- "phone" | "tablet" | "desktop": set by Controllers/UI from the screen size (see UI.rescale)
Kit.profile = "desktop"

function Kit.T(key, params)
	return Locale.t(key, params)
end

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local function tween(o, t, goal, style, dir)
	local tw = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), goal)
	tw:Play()
	return tw
end
Kit.tween = tween

-- Press feedback for any button: a quick squash while pressed, a small grow under the mouse
function Kit.press(b)
	local s = b:FindFirstChild("Press") or Kit.new("UIScale", { Name = "Press", Parent = b })
	local hover = false
	if UserInputService.MouseEnabled then
		b.MouseEnter:Connect(function()
			hover = true
			tween(s, 0.12, { Scale = 1.04 })
		end)
		b.MouseLeave:Connect(function()
			hover = false
			tween(s, 0.12, { Scale = 1 })
		end)
	end
	b.MouseButton1Down:Connect(function()
		tween(s, 0.06, { Scale = 0.92 })
	end)
	b.MouseButton1Up:Connect(function()
		tween(s, 0.2, { Scale = hover and 1.04 or 1 }, Enum.EasingStyle.Back)
	end)
	return b
end

-- A window or card springs open
function Kit.popIn(frame, from)
	local s = frame:FindFirstChild("Pop") or Kit.new("UIScale", { Name = "Pop", Parent = frame })
	s.Scale = from or 0.86
	tween(s, 0.24, { Scale = 1 }, Enum.EasingStyle.Back)
end

-- A short bump (a value changed, something was bought)
function Kit.bump(frame, amount)
	local s = frame:FindFirstChild("Bump") or Kit.new("UIScale", { Name = "Bump", Parent = frame })
	local up = tween(s, 0.08, { Scale = amount or 1.15 })
	up.Completed:Connect(function()
		tween(s, 0.22, { Scale = 1 }, Enum.EasingStyle.Back)
	end)
end

-- Kit.new("Frame", { props }, { children })
function Kit.new(class, props, children)
	local inst = Instance.new(class)
	local parent = nil
	for k, v in pairs(props or {}) do
		if k == "Parent" then
			parent = v
		elseif type(k) == "string" and string.sub(k, 1, 2) == "On" and type(v) == "function" then
			local event = string.sub(k, 3)
			inst[event]:Connect(v)
		else
			inst[k] = v
		end
	end
	if inst:IsA("GuiObject") and props and props.BorderSizePixel == nil then
		inst.BorderSizePixel = 0
	end
	if inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox") then
		inst.AutoLocalize = false
		if not (props and props.FontFace) then
			inst.FontFace = T.body
		end
	end
	for _, child in ipairs(children or {}) do
		child.Parent = inst
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

function Kit.corner(r)
	return Kit.new("UICorner", { CornerRadius = UDim.new(0, r or 10) })
end

function Kit.stroke(color, thickness, transparency)
	return Kit.new("UIStroke", { Color = color or T.wood, Thickness = thickness or 2, Transparency = transparency or 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
end

function Kit.padding(px, py)
	py = py or px
	return Kit.new("UIPadding", { PaddingLeft = UDim.new(0, px), PaddingRight = UDim.new(0, px), PaddingTop = UDim.new(0, py), PaddingBottom = UDim.new(0, py) })
end

function Kit.list(direction, pad, halign, valign)
	return Kit.new("UIListLayout", {
		FillDirection = direction or Enum.FillDirection.Vertical,
		Padding = UDim.new(0, pad or 6),
		HorizontalAlignment = halign or Enum.HorizontalAlignment.Left,
		VerticalAlignment = valign or Enum.VerticalAlignment.Top,
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
end

function Kit.grid(cellW, cellH, pad)
	return Kit.new("UIGridLayout", { CellSize = UDim2.fromOffset(cellW, cellH), CellPadding = UDim2.fromOffset(pad or 8, pad or 8), SortOrder = Enum.SortOrder.LayoutOrder })
end

function Kit.label(text, props)
	props = props or {}
	local base = {
		BackgroundTransparency = 1,
		Text = text or "",
		TextColor3 = T.ink,
		TextSize = 18,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 22),
	}
	for k, v in pairs(props) do
		base[k] = v
	end
	return Kit.new("TextLabel", base)
end

function Kit.title(text, props)
	props = props or {}
	props.FontFace = T.title
	props.TextSize = props.TextSize or 24
	props.TextColor3 = props.TextColor3 or T.wood
	return Kit.label(text, props)
end

-- Button styles: "primary" (red), "gold", "green", "plain", "dark"
function Kit.button(text, opts)
	opts = opts or {}
	-- one colour per kind of action: buy / confirm green, close / cancel / remove red, rewards and
	-- offers gold, everything else beige; the chosen option of a row is dark wood
	local style = ({ buy = "green", close = "primary", reward = "gold", secondary = "plain", selected = "dark" })[opts.style] or opts.style or "primary"
	local bg = ({ primary = T.red, gold = T.gold, green = T.green, plain = T.paperDark, dark = T.wood, blue = T.blue })[style] or T.red
	local fg = (style == "plain" or style == "gold") and T.ink or T.white
	local b = Kit.new("TextButton", {
		Text = text,
		Size = opts.size or UDim2.fromOffset(140, 40),
		BackgroundColor3 = bg,
		TextColor3 = fg,
		TextSize = opts.textSize or 18,
		FontFace = T.bold,
		AutoButtonColor = true,
		LayoutOrder = opts.order or 0,
		Position = opts.position,
		AnchorPoint = opts.anchor,
		TextWrapped = true,
	}, {
		Kit.corner(opts.radius or 10),
		Kit.stroke(style == "plain" and T.woodLight or Color3.new(0, 0, 0), 2, style == "plain" and 0 or 0.7),
		Kit.sheen(),
	})
	if opts.disabled then
		b.BackgroundColor3 = T.locked
		b.AutoButtonColor = false
		b.TextColor3 = T.muted
	else
		Kit.press(b)
	end
	if opts.onClick then
		b.MouseButton1Click:Connect(function()
			if not opts.disabled then
				local Core = require(script.Parent.Parent.Core)
				if Core.C.Audio then
					Core.C.Audio.play("ui")
				end
				opts.onClick()
			end
		end)
	end
	if opts.parent then
		b.Parent = opts.parent
	end
	return b
end

-- Soft top-lit gradient so flat colours read like lacquer
function Kit.sheen(amount)
	local a = amount or 0.82
	return Kit.new("UIGradient", {
		Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(a, a, a)),
		Rotation = 90,
	})
end

-- Washi panel framed like a lacquer box (dark wood edge, soft paper gradient)
function Kit.panel(props, children)
	local base = { BackgroundColor3 = T.paper, Size = UDim2.fromScale(1, 1) }
	for k, v in pairs(props or {}) do
		base[k] = v
	end
	local f = Kit.new("Frame", base, children)
	Kit.corner(12).Parent = f
	Kit.stroke(T.wood, 3).Parent = f
	Kit.new("UIGradient", { Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(0.94, 0.92, 0.88)), Rotation = 90, Parent = f })
	return f
end

-- Thin inner gold line (only for frames without UIPadding, which would shift it)
function Kit.goldLine(parent, inset)
	local i = inset or 5
	return Kit.new("Frame", {
		Name = "GoldLine",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(i, i),
		Size = UDim2.new(1, -2 * i, 1, -2 * i),
		ZIndex = 0,
		Active = false,
		Parent = parent,
	}, { Kit.corner(9), Kit.stroke(T.gold, 1, 0.35) })
end

function Kit.card(props, children)
	local base = { BackgroundColor3 = Color.hex("#FBF5EA"), Size = UDim2.new(1, 0, 0, 80) }
	for k, v in pairs(props or {}) do
		base[k] = v
	end
	local f = Kit.new("Frame", base, children)
	Kit.corner(10).Parent = f
	Kit.stroke(T.paperDark, 2).Parent = f
	return f
end

-- Scrolling container with automatic canvas size
function Kit.scroll(props, layout)
	local base = {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ScrollBarThickness = 8,
		ScrollBarImageColor3 = T.woodLight,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ScrollingDirection = Enum.ScrollingDirection.Y,
	}
	for k, v in pairs(props or {}) do
		base[k] = v
	end
	local s = Kit.new("ScrollingFrame", base)
	local l = layout or Kit.list(Enum.FillDirection.Vertical, 8)
	l.Parent = s
	Kit.padding(6).Parent = s
	return s
end

function Kit.bar(value, color, props)
	local base = { BackgroundColor3 = T.paperDark, Size = UDim2.new(1, 0, 0, 10) }
	for k, v in pairs(props or {}) do
		base[k] = v
	end
	local bg = Kit.new("Frame", base, { Kit.corner(5) })
	local fill = Kit.new("Frame", { BackgroundColor3 = color or T.green, Size = UDim2.fromScale(math.clamp(value or 0, 0, 1), 1), Name = "Fill" }, { Kit.corner(5) })
	fill.Parent = bg
	return bg, fill
end

function Kit.clear(container)
	for _, c in ipairs(container:GetChildren()) do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
end

-- every window and the size it asked for (phones get almost the whole screen)
local windows = {}

local function fitWindow(frame)
	local size = windows[frame]
	if not size then
		return
	end
	if Kit.profile == "phone" then
		frame.Size = UDim2.new(1, -16, 1, -12)
		frame.Position = UDim2.fromScale(0.5, 0.5)
	else
		frame.Size = size
		frame.Position = UDim2.fromScale(0.5, 0.52)
	end
end

function Kit.fitWindows()
	for frame in pairs(windows) do
		if frame.Parent then
			fitWindow(frame)
		else
			windows[frame] = nil
		end
	end
end

-- Standard modal window. Returns { frame, content, title }
function Kit.window(parent, size, titleText, onClose)
	-- windows draw above the HUD (ZIndex order of the screen's children: HUD 1, guide 5,
	-- tutorial 7, phone 9, windows 10, messages 20)
	local frame = Kit.panel({
		Name = "Window",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.52),
		Size = size or UDim2.fromScale(0.62, 0.72),
		Visible = false,
		ZIndex = 10,
		Parent = parent,
	})
	windows[frame] = size or UDim2.fromScale(0.62, 0.72)
	fitWindow(frame)
	Kit.new("UISizeConstraint", { MaxSize = Vector2.new(1040, 760), MinSize = Vector2.new(320, 260), Parent = frame })
	Kit.goldLine(frame, 5)
	local header = Kit.new("Frame", { BackgroundColor3 = T.wood, Size = UDim2.new(1, 0, 0, 48), Parent = frame }, { Kit.corner(10), Kit.sheen(0.7) })
	-- lacquer red and gold trim under the header, and a little red seal before the title
	Kit.new("Frame", { BackgroundColor3 = T.red, BorderSizePixel = 0, Position = UDim2.new(0, 6, 0, 44), Size = UDim2.new(1, -12, 0, 4), Parent = header })
	Kit.new("Frame", { BackgroundColor3 = T.gold, BorderSizePixel = 0, Position = UDim2.new(0, 6, 0, 48), Size = UDim2.new(1, -12, 0, 2), Parent = header })
	local seal = Kit.new("Frame", { BackgroundColor3 = T.red, Size = UDim2.fromOffset(30, 30), Position = UDim2.fromOffset(12, 8), Rotation = -4, Parent = header }, { Kit.corner(6), Kit.stroke(T.gold, 1, 0.2) })
	Kit.new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Text = "和", TextScaled = true, TextColor3 = T.paper, FontFace = T.title, AutoLocalize = false, Parent = seal })
	local title = Kit.title(titleText or "", { Parent = header, Size = UDim2.new(1, -150, 1, 0), Position = UDim2.fromOffset(52, 0), TextColor3 = T.paper, TextSize = 24, TextYAlignment = Enum.TextYAlignment.Center })
	title.TextStrokeTransparency = 0.7
	Kit.button("✕", { parent = header, size = UDim2.fromOffset(44, 40), position = UDim2.new(1, -50, 0, 4), style = "close", textSize = 20, onClick = onClose })
	local content = Kit.new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 56), Size = UDim2.new(1, -24, 1, -66), Parent = frame, Name = "Content" })
	return { frame = frame, content = content, title = title, header = header }
end

-- Red notification dot with a number in the top-right corner of `parent`; returns set(n)
function Kit.badge(parent, size)
	local d = size or 22
	local dot = Kit.new("Frame", {
		Name = "Badge", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -4, 0, 4), Size = UDim2.fromOffset(d, d),
		BackgroundColor3 = T.red, Visible = false, ZIndex = 5, Parent = parent,
	}, { Kit.corner(d / 2), Kit.stroke(T.white, 2, 0) })
	local label = Kit.label("", { Parent = dot, Size = UDim2.fromScale(1, 1), TextSize = math.floor(d * 0.62), FontFace = T.bold, TextColor3 = T.white, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 6 })
	local shown = 0
	return function(n)
		n = n or 0
		dot.Visible = n > 0
		label.Text = n > 9 and "9+" or tostring(n)
		if n > shown then
			Kit.bump(dot, 1.35)
		end
		shown = n
	end
end

-- Tabs row; returns the row frame, paint(id) and badges[id] = set(n).
-- tabs = { {id, label, width} }, onSelect(id)
function Kit.tabs(parent, tabs, onSelect, current, height)
	local h = height or 40
	local row = Kit.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, h), Parent = parent }, { Kit.list(Enum.FillDirection.Horizontal, 6) })
	local buttons, badges = {}, {}
	local function paint(sel)
		for id, b in pairs(buttons) do
			b.BackgroundColor3 = id == sel and T.wood or T.paperDark
			b.TextColor3 = id == sel and T.paper or T.ink
		end
	end
	for i, t in ipairs(tabs) do
		local b = Kit.button(t.label, { size = UDim2.fromOffset(t.width or 130, h - 4), style = "plain", order = i, textSize = t.textSize or 16 })
		b.Parent = row
		buttons[t.id] = b
		badges[t.id] = Kit.badge(b, 20)
		b.MouseButton1Click:Connect(function()
			paint(t.id)
			onSelect(t.id)
		end)
	end
	paint(current or (tabs[1] and tabs[1].id))
	return row, paint, badges
end

-- Row with an emoji icon, title, subtitle and a right side area. Returns card, right
function Kit.row(icon, titleText, subtitle, height)
	local card = Kit.card({ Size = UDim2.new(1, -8, 0, height or 72) })
	-- red accent along the left edge of every list row
	Kit.new("Frame", { BackgroundColor3 = T.red, BorderSizePixel = 0, Position = UDim2.fromOffset(0, 10), Size = UDim2.new(0, 4, 1, -20), Parent = card }, { Kit.corner(2) })
	Kit.label(icon or "", { Parent = card, Size = UDim2.fromOffset(52, 52), Position = UDim2.fromOffset(10, ((height or 72) - 52) / 2), TextScaled = true, TextXAlignment = Enum.TextXAlignment.Center })
	Kit.label(titleText or "", { Parent = card, Position = UDim2.fromOffset(70, 8), Size = UDim2.new(1, -250, 0, 24), FontFace = T.bold, TextSize = 19, TextTruncate = Enum.TextTruncate.AtEnd })
	Kit.label(subtitle or "", { Parent = card, Position = UDim2.fromOffset(70, 32), Size = UDim2.new(1, -250, 0, (height or 72) - 38), TextSize = 15, TextColor3 = T.muted, TextYAlignment = Enum.TextYAlignment.Top })
	local right = Kit.new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(170, (height or 72) - 16), Parent = card }, { Kit.list(Enum.FillDirection.Vertical, 4, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center) })
	return card, right
end

return Kit
