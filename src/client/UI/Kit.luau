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

function Kit.T(key, params)
	return Locale.t(key, params)
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
	local style = opts.style or "primary"
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
	})
	if opts.disabled then
		b.BackgroundColor3 = T.locked
		b.AutoButtonColor = false
		b.TextColor3 = T.muted
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

function Kit.panel(props, children)
	local base = { BackgroundColor3 = T.paper, Size = UDim2.fromScale(1, 1) }
	for k, v in pairs(props or {}) do
		base[k] = v
	end
	local f = Kit.new("Frame", base, children)
	Kit.corner(12).Parent = f
	Kit.stroke(T.wood, 3).Parent = f
	return f
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

-- Standard modal window. Returns { frame, content, title }
function Kit.window(parent, size, titleText, onClose)
	local frame = Kit.panel({
		Name = "Window",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.52),
		Size = size or UDim2.fromScale(0.62, 0.72),
		Visible = false,
		Parent = parent,
	})
	Kit.new("UISizeConstraint", { MaxSize = Vector2.new(980, 720), MinSize = Vector2.new(320, 260), Parent = frame })
	local header = Kit.new("Frame", { BackgroundColor3 = T.wood, Size = UDim2.new(1, 0, 0, 48), Parent = frame }, { Kit.corner(10) })
	local title = Kit.title(titleText or "", { Parent = header, Size = UDim2.new(1, -110, 1, 0), Position = UDim2.fromOffset(16, 0), TextColor3 = T.paper, TextSize = 24, TextYAlignment = Enum.TextYAlignment.Center })
	Kit.button("✕", { parent = header, size = UDim2.fromOffset(38, 38), position = UDim2.new(1, -44, 0, 5), style = "primary", onClick = onClose })
	local content = Kit.new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 56), Size = UDim2.new(1, -24, 1, -66), Parent = frame, Name = "Content" })
	return { frame = frame, content = content, title = title }
end

-- Tabs row; returns the row frame. tabs = { {id, label} }, onSelect(id)
function Kit.tabs(parent, tabs, onSelect, current)
	local row = Kit.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40), Parent = parent }, { Kit.list(Enum.FillDirection.Horizontal, 6) })
	local buttons = {}
	local function paint(sel)
		for id, b in pairs(buttons) do
			b.BackgroundColor3 = id == sel and T.red or T.paperDark
			b.TextColor3 = id == sel and T.white or T.ink
		end
	end
	for i, t in ipairs(tabs) do
		local b = Kit.button(t.label, { size = UDim2.fromOffset(t.width or 130, 36), style = "plain", order = i, textSize = 16 })
		b.Parent = row
		buttons[t.id] = b
		b.MouseButton1Click:Connect(function()
			paint(t.id)
			onSelect(t.id)
		end)
	end
	paint(current or (tabs[1] and tabs[1].id))
	return row, paint
end

-- Row with an emoji icon, title, subtitle and a right side area. Returns card, right
function Kit.row(icon, titleText, subtitle, height)
	local card = Kit.card({ Size = UDim2.new(1, -8, 0, height or 72) })
	Kit.label(icon or "", { Parent = card, Size = UDim2.fromOffset(52, 52), Position = UDim2.fromOffset(10, ((height or 72) - 52) / 2), TextScaled = true, TextXAlignment = Enum.TextXAlignment.Center })
	Kit.label(titleText or "", { Parent = card, Position = UDim2.fromOffset(70, 8), Size = UDim2.new(1, -250, 0, 24), FontFace = T.bold, TextSize = 19, TextTruncate = Enum.TextTruncate.AtEnd })
	Kit.label(subtitle or "", { Parent = card, Position = UDim2.fromOffset(70, 32), Size = UDim2.new(1, -250, 0, (height or 72) - 38), TextSize = 15, TextColor3 = T.muted, TextYAlignment = Enum.TextYAlignment.Top })
	local right = Kit.new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(170, (height or 72) - 16), Parent = card }, { Kit.list(Enum.FillDirection.Vertical, 4, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center) })
	return card, right
end

return Kit
