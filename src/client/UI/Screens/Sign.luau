--!nonstrict
-- The restaurant's sign over the door: name, style and colours (Config/Signs) with a live preview.
-- Saving sends SetSign; the server checks the name with Roblox's text filter and builds the sign
-- again. The owner and co-managers can change it; it opens by using the sign or from the phone.
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local NetDef = require(Shared.Net)
local Locale = require(Shared.Locale)
local Signs = require(Shared.Config.Signs)
local Color = require(Shared.Util.Color)
local Kit = require(script.Parent.Parent.Kit)
local Base = require(script.Parent.Parent.Base)
local Core = require(script.Parent.Parent.Parent.Core)

local t = Locale.t
local T = Kit.Theme

-- the letters of each style, as on the real sign (Models/Builders/Building)
local FONTS = {
	wood = Font.fromEnum(Enum.Font.Merriweather),
	lacquer = Font.fromEnum(Enum.Font.Fondamento),
	noren = Font.fromEnum(Enum.Font.PermanentMarker),
	neon = Font.fromEnum(Enum.Font.FredokaOne),
	lanterns = Font.fromEnum(Enum.Font.LuckiestGuy),
}
-- ideas for a name ({name} = the player's name)
local IDEAS = { "{name}-ya", "Ramen {name}", "Sakura {name}", "{name} Sushi", "Ichiban {name}", "Kawaii {name}", "{name}'s Ramen", "Neko {name}" }

local draft = nil -- what the player is choosing; saved only with Save

local function current()
	-- (clients only get the filtered name: what everybody sees on the sign)
	local s = Core.C.Data.w("sign") or {}
	return { name = s.shown or "", style = s.style or Signs.Default.style, board = s.board or Signs.Default.board, text = s.text or Signs.Default.text }
end

local function hex(id)
	return Color.hex((Signs.ColorById[id] or Signs.ColorById.ink).hex)
end

-- at most MaxName letters
local function clip(s)
	if utf8.len(s) and utf8.len(s) > Signs.MaxName then
		return s:sub(1, utf8.offset(s, Signs.MaxName + 1) - 1)
	end
	return s
end

local screen
local preview = {}

-- the preview looks like the sign: board colour, frame of the style, letters in its font
local function paintPreview()
	if not preview.board or not draft then
		return
	end
	local style, board, text = draft.style, hex(draft.board), hex(draft.text)
	local named = draft.name ~= ""
	preview.board.BackgroundColor3 = style == "neon" and board:Lerp(Color3.new(0, 0, 0), 0.55) or board
	local frameColor = ({ wood = T.wood, lacquer = T.gold, neon = text, lanterns = Color.hex("#2B1D14") })[style]
	preview.frame.Enabled = frameColor ~= nil
	preview.frame.Color = frameColor or T.wood
	preview.frame.Thickness = style == "lacquer" and 5 or (style == "neon" and 3 or 6)
	for _, slit in ipairs(preview.slits) do
		slit.Visible = style == "noren"
	end
	for _, l in ipairs(preview.lanterns) do
		l.Visible = style == "lanterns"
	end
	preview.name.Text = named and draft.name or Signs.DefaultText
	preview.name.FontFace = named and (FONTS[style] or T.title) or T.title
	preview.name.TextColor3 = text
	preview.name.Size = named and UDim2.fromScale(0.84, 0.66) or UDim2.fromScale(0.84, 0.84)
	preview.glow.Enabled = style == "neon"
	preview.glow.Color = text
	preview.sub.Visible = named
	preview.sub.TextColor3 = text
	preview.count.Text = utf8.len(draft.name) .. " / " .. Signs.MaxName
end

local function swatches(parent, order, title, selected, onPick)
	-- as tall as its rows of colours (one row on a wide screen, two on a narrow one)
	local card = Kit.card({ Size = UDim2.new(1, -8, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = order, Parent = parent })
	Kit.new("UIPadding", { PaddingBottom = UDim.new(0, 12), Parent = card })
	Kit.label(title, { Parent = card, Position = UDim2.fromOffset(12, 4), Size = UDim2.new(1, -24, 0, 26), FontFace = T.bold, TextSize = 17 })
	local grid = Kit.new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 34), Size = UDim2.new(1, -24, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = card }, { Kit.grid(40, 40, 8) })
	for _, c in ipairs(Signs.Colors) do
		local on = c.id == selected
		local b = Kit.new("TextButton", { Name = "Color_" .. c.id, Text = on and "✓" or "", TextSize = 20, FontFace = T.title, TextColor3 = (c.id == "white" or c.id == "cream" or c.id == "hinoki" or c.id == "sakura" or c.id == "gold") and T.ink or T.white, BackgroundColor3 = Color.hex(c.hex), LayoutOrder = c.order, AutoButtonColor = true, Parent = grid }, { Kit.corner(20), Kit.stroke(on and T.gold or T.woodLight, on and 4 or 2) })
		Kit.press(b)
		b.MouseButton1Click:Connect(function()
			onPick(c.id)
		end)
	end
end

screen = Base.make("Sign", "ui.sign", UDim2.fromScale(0.62, 0.86), function(content)
	draft = draft or current()
	local can = Core.C.Data.canBuild()
	local scroll = Kit.scroll({ Name = "SignScroll", Position = UDim2.fromOffset(0, 0), Size = UDim2.new(1, 0, 1, -58), Parent = content })

	-- the live preview (lower on a phone, so the choices below it show without scrolling far)
	local phone = Kit.profile == "phone"
	local stage = Kit.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -8, 0, phone and 74 or 112), LayoutOrder = 1, Parent = scroll })
	preview.board = Kit.new("Frame", { Name = "Preview", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0.8, 0, 0, phone and 62 or 92), Parent = stage }, { Kit.corner(6) })
	preview.frame = Kit.stroke(T.wood, 6)
	preview.frame.Parent = preview.board
	preview.slits = {}
	for _, k in ipairs({ 1 / 3, 2 / 3 }) do
		table.insert(preview.slits, Kit.new("Frame", { BackgroundColor3 = T.paper, BorderSizePixel = 0, Position = UDim2.new(k, -2, 0.12, 0), Size = UDim2.new(0, 4, 0.88, 0), Parent = preview.board }))
	end
	preview.lanterns = {}
	for _, side in ipairs({ 0, 1 }) do
		table.insert(preview.lanterns, Kit.label("🏮", { Parent = stage, AnchorPoint = Vector2.new(side, 0.5), Position = UDim2.fromScale(side == 0 and 0.02 or 0.98, 0.5), Size = phone and UDim2.fromOffset(30, 40) or UDim2.fromOffset(40, 52), TextScaled = true }))
	end
	preview.name = Kit.label("", { Name = "PreviewName", Parent = preview.board, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.06), Size = UDim2.fromScale(0.84, 0.66), TextScaled = true, TextXAlignment = Enum.TextXAlignment.Center, AutoLocalize = false })
	-- a soft glow round the letters (neon)
	preview.glow = Kit.new("UIStroke", { Color = T.white, Thickness = 2.5, Transparency = 0.55, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual, Parent = preview.name })
	preview.sub = Kit.label(Signs.Subtitle, { Parent = preview.board, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 0.96), Size = UDim2.fromScale(0.4, 0.22), TextScaled = true, FontFace = T.title, TextXAlignment = Enum.TextXAlignment.Center, AutoLocalize = false })

	-- the name
	local nameCard = Kit.card({ Size = UDim2.new(1, -8, 0, 96), LayoutOrder = 2, Parent = scroll })
	Kit.label("✏️ " .. t("ui.sign_name"), { Parent = nameCard, Position = UDim2.fromOffset(12, 4), Size = UDim2.new(1, -150, 0, 26), FontFace = T.bold, TextSize = 17 })
	preview.count = Kit.label("", { Parent = nameCard, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 4), Size = UDim2.fromOffset(120, 26), TextSize = 15, TextColor3 = T.muted, TextXAlignment = Enum.TextXAlignment.Right })
	local box = Kit.new("TextBox", {
		Name = "NameBox", Parent = nameCard, Position = UDim2.fromOffset(12, 36), Size = UDim2.new(1, -150, 0, 48), Text = draft.name, PlaceholderText = t("ui.sign_placeholder"),
		ClearTextOnFocus = false, TextSize = 22, FontFace = T.bold, TextColor3 = T.ink, BackgroundColor3 = T.white, TextXAlignment = Enum.TextXAlignment.Left, TextEditable = can,
	}, { Kit.corner(10), Kit.stroke(T.wood, 2), Kit.padding(10, 0) })
	box:GetPropertyChangedSignal("Text"):Connect(function()
		local clipped = clip(box.Text)
		if clipped ~= box.Text then
			box.Text = clipped
			return
		end
		draft.name = box.Text
		paintPreview()
	end)
	Kit.button("🎲 " .. t("ui.sign_idea"), { parent = nameCard, size = UDim2.fromOffset(122, 48), position = UDim2.new(1, -134, 0, 36), style = "secondary", textSize = 16, onClick = function()
		local who = Players.LocalPlayer.DisplayName
		local idea = IDEAS[math.random(1, #IDEAS)]:gsub("{name}", who)
		box.Text = clip(idea)
	end })

	-- the style
	local styleCard = Kit.card({ Size = UDim2.new(1, -8, 0, 104), LayoutOrder = 3, Parent = scroll })
	Kit.label("🎨 " .. t("ui.sign_style"), { Parent = styleCard, Position = UDim2.fromOffset(12, 4), Size = UDim2.new(1, -24, 0, 26), FontFace = T.bold, TextSize = 17 })
	local row = Kit.new("ScrollingFrame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 36), Size = UDim2.new(1, -24, 0, 60), ScrollingDirection = Enum.ScrollingDirection.X, AutomaticCanvasSize = Enum.AutomaticSize.X, CanvasSize = UDim2.new(), ScrollBarThickness = 4, Parent = styleCard }, { Kit.list(Enum.FillDirection.Horizontal, 8) })
	for _, st in ipairs(Signs.Styles) do
		Kit.button(st.icon .. " " .. t("sign.style_" .. st.id), { parent = row, size = UDim2.fromOffset(136, 48), style = draft.style == st.id and "selected" or "secondary", order = st.order, textSize = 16, onClick = function()
			draft.style = st.id
			screen.refresh()
		end })
	end

	-- the colours
	swatches(scroll, 4, "🟫 " .. t("ui.sign_board"), draft.board, function(id)
		draft.board = id
		screen.refresh()
	end)
	swatches(scroll, 5, "🔤 " .. t("ui.sign_letters"), draft.text, function(id)
		draft.text = id
		screen.refresh()
	end)
	Kit.label(t("ui.sign_filter_note"), { Parent = scroll, Size = UDim2.new(1, -8, 0, 40), LayoutOrder = 6, TextSize = 14, TextColor3 = T.muted, TextWrapped = true })

	-- the classic look, and save
	local footer = Kit.new("Frame", { BackgroundTransparency = 1, Position = UDim2.new(0, 0, 1, -52), Size = UDim2.new(1, 0, 0, 50), Parent = content }, { Kit.list(Enum.FillDirection.Horizontal, 10, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center) })
	if not can then
		Kit.label("🔒 " .. t("ui.sign_owner_only"), { Parent = footer, Size = UDim2.new(1, 0, 1, 0), TextSize = 16, TextColor3 = T.muted, TextXAlignment = Enum.TextXAlignment.Right })
	else
		Kit.button("↺ " .. t("ui.sign_classic"), { parent = footer, size = UDim2.fromOffset(170, 46), style = "secondary", order = 1, textSize = 16, onClick = function()
			draft = { name = "", style = Signs.Default.style, board = Signs.Default.board, text = Signs.Default.text }
			screen.refresh()
		end })
		local save = Kit.button("💾 " .. t("ui.sign_save"), { parent = footer, size = UDim2.fromOffset(190, 46), style = "buy", order = 2, textSize = 18, onClick = function()
			NetDef.event("SetSign"):FireServer({ name = draft.name, style = draft.style, board = draft.board, text = draft.text })
			Core.C.UI.close("Sign")
		end })
		save.Name = "Save"
	end
	paintPreview()
end)

-- a fresh start from the sign as it is every time the editor opens
local baseOpen = screen.open
function screen.open(arg)
	draft = nil
	baseOpen(arg)
end

return screen
