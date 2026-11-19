-- GUI layout for the client simulation (tools/sim/client.lua): works out where Roblox would draw
-- every GuiObject (AbsolutePosition / AbsoluteSize in screen pixels) from UDim2 sizes and
-- positions, AnchorPoint, UIScale, UIPadding, UIListLayout, UIGridLayout, UISizeConstraint,
-- UIAspectRatioConstraint, AutomaticSize and ScrollingFrame canvases. The layout is computed when
-- one of those values is read and kept until any instance property changes. Sim.dumpGui() lists
-- what is on screen for tools/ui_preview.py, which draws it.
local Gui = {}
Sim.Gui = Gui
local isA = Sim.isA

local function props(o)
	return rawget(o, "__props")
end
local function kids(o)
	return rawget(o, "__children")
end
local function cls(o)
	return rawget(o, "__class")
end

local function firstOf(o, className)
	for _, c in ipairs(kids(o)) do
		if cls(c) == className then
			return c
		end
	end
	return nil
end
Gui.firstOf = firstOf

local function isText(o)
	local k = cls(o)
	return k == "TextLabel" or k == "TextButton" or k == "TextBox"
end
Gui.isText = isText

local function udim(u, base)
	if not u then
		return 0
	end
	return u.Scale * base + u.Offset
end

------------------------------------------------------------------ text
-- Width and height of a text, roughly as Roblox fonts measure it. tools/ui_preview.py replaces
-- Sim.measureText with real font metrics.
local function charWidth(cp)
	if cp == 0x200D or (cp >= 0xFE00 and cp <= 0xFE0F) or (cp >= 0x1F3FB and cp <= 0x1F3FF) then
		return 0
	elseif cp >= 0x1F000 or (cp >= 0x2600 and cp <= 0x27BF) or (cp >= 0x2B00 and cp <= 0x2BFF) then
		return 1.15
	elseif cp >= 0x2E80 then
		return 1.0
	elseif cp == 32 then
		return 0.27
	elseif cp >= 48 and cp <= 57 then
		return 0.56
	elseif cp >= 65 and cp <= 90 then
		return (cp == 73) and 0.3 or ((cp == 77 or cp == 87) and 0.86 or 0.66)
	elseif cp >= 97 and cp <= 122 then
		if cp == 105 or cp == 106 or cp == 108 then
			return 0.25
		elseif cp == 109 or cp == 119 then
			return 0.82
		elseif cp == 102 or cp == 116 or cp == 114 then
			return 0.36
		end
		return 0.53
	elseif cp == 46 or cp == 44 or cp == 58 or cp == 59 or cp == 39 or cp == 124 or cp == 33 then
		return 0.27
	end
	return 0.6
end

local function lineWidth(s, size, bold)
	local w = 0
	for _, cp in utf8.codes(s) do
		w = w + charWidth(cp)
	end
	return w * size * (bold and 1.06 or 1)
end

local function stripRich(s)
	return (s:gsub("<[^>]->", ""))
end
Gui.stripRich = stripRich

-- returns width, height of `text` at `size` px, wrapped at `maxWidth` when given (family: the
-- font's asset path, used by tools/ui_preview.py)
function Sim.measureText(text, size, bold, maxWidth, family)
	local lines = {}
	for raw in (text .. "\n"):gmatch("(.-)\n") do
		if maxWidth and maxWidth > 0 then
			local cur = ""
			for word in raw:gmatch("%S+") do
				local try = cur == "" and word or (cur .. " " .. word)
				if cur ~= "" and lineWidth(try, size, bold) > maxWidth then
					table.insert(lines, cur)
					cur = word
				else
					cur = try
				end
			end
			table.insert(lines, cur)
		else
			table.insert(lines, raw)
		end
	end
	local w = 0
	for _, l in ipairs(lines) do
		w = math.max(w, lineWidth(l, size, bold))
	end
	return w, #lines * size
end

local function fontBold(o)
	local f = props(o).FontFace
	local wt = f and f.Weight
	return wt ~= nil and (tostring(wt):find("Bold") ~= nil or tostring(wt):find("Heavy") ~= nil or tostring(wt):find("Black") ~= nil)
		or (f and type(f.Family) == "string" and f.Family:find("Fredoka") ~= nil)
end
Gui.fontBold = fontBold

local function textOf(o)
	local s = tostring(props(o).Text or "")
	if props(o).RichText then
		s = stripRich(s)
	end
	return s
end
Gui.textOf = textOf

------------------------------------------------------------------ layout
local cache = {} -- [instance] = { x, y, w, h, k, clip, order }
local contentSize = {} -- [UIListLayout / UIGridLayout] = Vector2 (px)
local canvasInfo = {} -- [ScrollingFrame] = { canvasW, canvasH, windowW, windowH } (px)
local cacheVersion = -1
local order = 0

local function automatic(o)
	local a = props(o).AutomaticSize
	if a == nil or a == Enum.AutomaticSize.None then
		return false, false
	end
	return a == Enum.AutomaticSize.X or a == Enum.AutomaticSize.XY, a == Enum.AutomaticSize.Y or a == Enum.AutomaticSize.XY
end

local function constrain(o, w, h)
	for _, c in ipairs(kids(o)) do
		local k = cls(c)
		if k == "UISizeConstraint" then
			local p = props(c)
			local mn, mx = p.MinSize or Vector2.zero, p.MaxSize or Vector2.new(math.huge, math.huge)
			w = math.max(mn.X, math.min(mx.X, w))
			h = math.max(mn.Y, math.min(mx.Y, h))
		elseif k == "UIAspectRatioConstraint" then
			local p = props(c)
			local r = p.AspectRatio or 1
			if r > 0 then
				if p.AspectType == Enum.AspectType.ScaleWithParentSize then
					if p.DominantAxis == Enum.DominantAxis.Height then
						w = h * r
					else
						h = w / r
					end
				elseif w / math.max(h, 1e-6) > r then
					w = h * r
				else
					h = w / r
				end
			end
		end
	end
	return w, h
end

local function padding(o, w, h)
	local p = firstOf(o, "UIPadding")
	if not p then
		return 0, 0, 0, 0
	end
	local pr = props(p)
	return udim(pr.PaddingLeft, w), udim(pr.PaddingTop, h), udim(pr.PaddingRight, w), udim(pr.PaddingBottom, h)
end

local function guiKids(o)
	local out = {}
	for _, c in ipairs(kids(o)) do
		if isA(cls(c), "GuiObject") then
			out[#out + 1] = c
		end
	end
	return out
end

-- children placed by a UIListLayout / UIGridLayout, in layout order (invisible ones take no room)
local function layoutItems(o, sortOrder)
	local items = {}
	for i, c in ipairs(guiKids(o)) do
		items[#items + 1] = { c = c, i = i, visible = props(c).Visible ~= false }
	end
	table.sort(items, function(a, b)
		if sortOrder == Enum.SortOrder.Name then
			local na, nb = tostring(props(a.c).Name), tostring(props(b.c).Name)
			if na ~= nb then
				return na < nb
			end
		else
			local la, lb = props(a.c).LayoutOrder or 0, props(b.c).LayoutOrder or 0
			if la ~= lb then
				return la < lb
			end
		end
		return a.i < b.i
	end)
	return items
end

local function alignOffset(alignment, free, centre, last)
	if alignment == centre then
		return free / 2
	elseif alignment == last then
		return free
	end
	return 0
end

local measureNode, placeNode, layoutChildren

local function baseSize(o, pw, ph)
	local pr = props(o)
	local s = pr.Size or UDim2.new(0, 100, 0, 100)
	local w = s.X.Scale * pw + s.X.Offset
	local h = s.Y.Scale * ph + s.Y.Offset
	if pr.SizeConstraint == Enum.SizeConstraint.RelativeXX then
		h = s.Y.Scale * pw + s.Y.Offset
	elseif pr.SizeConstraint == Enum.SizeConstraint.RelativeYY then
		w = s.X.Scale * ph + s.X.Offset
	end
	return w, h
end

local function listContent(o, list, bw, bh)
	local lp = props(list)
	local vertical = lp.FillDirection ~= Enum.FillDirection.Horizontal
	local pad = udim(lp.Padding, vertical and bh or bw)
	local total, cross, n = 0, 0, 0
	for _, it in ipairs(layoutItems(o, lp.SortOrder)) do
		if it.visible then
			local w, h = measureNode(it.c, bw, bh)
			total = total + (vertical and h or w)
			cross = math.max(cross, vertical and w or h)
			n = n + 1
		end
	end
	if n > 1 then
		total = total + pad * (n - 1)
	end
	if vertical then
		return cross, total
	end
	return total, cross
end

local function gridMetrics(o, grid, bw, bh)
	local gp = props(grid)
	local cellSize = gp.CellSize or UDim2.fromOffset(100, 100)
	local cellPad = gp.CellPadding or UDim2.fromOffset(5, 5)
	local cw, ch = udim(cellSize.X, bw), udim(cellSize.Y, bh)
	local px, py = udim(cellPad.X, bw), udim(cellPad.Y, bh)
	local horizontal = gp.FillDirection ~= Enum.FillDirection.Vertical
	local per
	if horizontal then
		per = math.max(1, math.floor((bw + px) / math.max(cw + px, 1e-6) + 1e-6))
	else
		per = math.max(1, math.floor((bh + py) / math.max(ch + py, 1e-6) + 1e-6))
	end
	if (gp.FillDirectionMaxCells or 0) > 0 then
		per = math.min(per, gp.FillDirectionMaxCells)
	end
	local n = 0
	for _, it in ipairs(layoutItems(o, gp.SortOrder)) do
		if it.visible then
			n = n + 1
		end
	end
	local lines = math.max(1, math.ceil(n / per))
	local cols = horizontal and math.min(per, math.max(n, 1)) or lines
	local rows = horizontal and lines or math.min(per, math.max(n, 1))
	if n == 0 then
		cols, rows = 0, 0
	end
	local totalW = cols * cw + math.max(0, cols - 1) * px
	local totalH = rows * ch + math.max(0, rows - 1) * py
	return { cw = cw, ch = ch, px = px, py = py, per = per, horizontal = horizontal, totalW = totalW, totalH = totalH }
end

-- what an object needs to show all of its text and children (padding included)
local function contentExtent(o, w, h, autoX)
	local pl, pt, pr, pb = padding(o, w, h)
	local bw, bh = w - pl - pr, h - pt - pb
	local cw, ch = 0, 0
	if isText(o) then
		local text = textOf(o)
		if text ~= "" then
			local size = props(o).TextSize or 14
			local wrapAt = (props(o).TextWrapped and not autoX) and bw or nil
			local f = props(o).FontFace
			cw, ch = Sim.measureText(text, size, fontBold(o), wrapAt, f and tostring(f.Family) or nil)
		end
	end
	local list, grid = firstOf(o, "UIListLayout"), firstOf(o, "UIGridLayout")
	if list then
		local lw, lh = listContent(o, list, bw, bh)
		cw, ch = math.max(cw, lw), math.max(ch, lh)
	elseif grid then
		local g = gridMetrics(o, grid, bw, bh)
		cw, ch = math.max(cw, g.totalW), math.max(ch, g.totalH)
	else
		for _, c in ipairs(guiKids(o)) do
			if props(c).Visible ~= false then
				local kw, kh = measureNode(c, bw, bh)
				local pos = props(c).Position or UDim2.new()
				local ap = props(c).AnchorPoint or Vector2.zero
				local x = pos.X.Scale * bw + pos.X.Offset - ap.X * kw
				local y = pos.Y.Scale * bh + pos.Y.Offset - ap.Y * kh
				cw = math.max(cw, x + kw)
				ch = math.max(ch, y + kh)
			end
		end
	end
	return cw + pl + pr, ch + pt + pb
end

-- size of an object inside a parent box of pw x ph (constraints and automatic size applied)
function measureNode(o, pw, ph)
	local w, h = baseSize(o, pw, ph)
	w, h = constrain(o, w, h)
	local ax, ay = automatic(o)
	if ax or ay then
		local cw, ch = contentExtent(o, w, h, ax)
		if ax then
			w = math.max(w, cw)
		end
		if ay then
			h = math.max(h, ch)
		end
		w, h = constrain(o, w, h)
	end
	return w, h
end

local function intersect(clip, x, y, w, h)
	local x1, y1, x2, y2 = x, y, x + w, y + h
	if clip then
		x1, y1 = math.max(x1, clip[1]), math.max(y1, clip[2])
		x2, y2 = math.min(x2, clip[3]), math.min(y2, clip[4])
	end
	return { x1, y1, math.max(x1, x2), math.max(y1, y2) }
end

local function record(o, x, y, w, h, k, clip)
	order = order + 1
	cache[o] = { x = x, y = y, w = w, h = h, k = k, clip = clip, order = order }
end

-- places `o` at (x, y, w, h) in its parent's units; T maps those units to screen pixels
function placeNode(o, x, y, w, h, T, clip)
	local sc = firstOf(o, "UIScale")
	local s = sc and (props(sc).Scale or 1) or 1
	local vx, vy, vw, vh = x, y, w, h
	if s ~= 1 then
		vw, vh = w * s, h * s
		vx, vy = x + (w - vw) / 2, y + (h - vh) / 2
	end
	local ax, ay = T.ox + T.k * vx, T.oy + T.k * vy
	local aw, ah = T.k * vw, T.k * vh
	record(o, ax, ay, aw, ah, T.k * s, clip)
	local CT = { ox = ax, oy = ay, k = T.k * s }
	local childClip = clip
	if props(o).ClipsDescendants or cls(o) == "ScrollingFrame" then
		childClip = intersect(clip, ax, ay, aw, ah)
	end
	local pl, pt, pr, pb = padding(o, w, h)
	if cls(o) == "ScrollingFrame" then
		local p = props(o)
		local cs = p.CanvasSize or UDim2.new(0, 0, 2, 0)
		local canvasW = math.max(w, udim(cs.X, w))
		local canvasH = math.max(h, udim(cs.Y, h))
		local auto = p.AutomaticCanvasSize
		if auto ~= nil and auto ~= Enum.AutomaticSize.None then
			local cw, ch = contentExtent(o, canvasW, canvasH, false)
			if auto == Enum.AutomaticSize.X or auto == Enum.AutomaticSize.XY then
				canvasW = math.max(udim(cs.X, w), cw, w)
			end
			if auto == Enum.AutomaticSize.Y or auto == Enum.AutomaticSize.XY then
				canvasH = math.max(udim(cs.Y, h), ch, h)
			end
		end
		canvasInfo[o] = { canvasW * CT.k, canvasH * CT.k, aw, ah }
		local cp = p.CanvasPosition or Vector2.zero
		local cpl, cpt, cpr, cpb = padding(o, canvasW, canvasH)
		layoutChildren(o, cpl - cp.X, cpt - cp.Y, canvasW - cpl - cpr, canvasH - cpt - cpb, CT, childClip)
		return
	end
	layoutChildren(o, pl, pt, w - pl - pr, h - pt - pb, CT, childClip)
end

function layoutChildren(o, bx, by, bw, bh, T, clip)
	local list, grid = firstOf(o, "UIListLayout"), firstOf(o, "UIGridLayout")
	if list then
		local lp = props(list)
		local vertical = lp.FillDirection ~= Enum.FillDirection.Horizontal
		local pad = udim(lp.Padding, vertical and bh or bw)
		local items = layoutItems(o, lp.SortOrder)
		local sizes, total, cross, n = {}, 0, 0, 0
		for i, it in ipairs(items) do
			local w, h = measureNode(it.c, bw, bh)
			sizes[i] = { w, h }
			if it.visible then
				total = total + (vertical and h or w)
				cross = math.max(cross, vertical and w or h)
				n = n + 1
			end
		end
		if n > 1 then
			total = total + pad * (n - 1)
		end
		local cursor
		if vertical then
			cursor = by + alignOffset(lp.VerticalAlignment, bh - total, Enum.VerticalAlignment.Center, Enum.VerticalAlignment.Bottom)
		else
			cursor = bx + alignOffset(lp.HorizontalAlignment, bw - total, Enum.HorizontalAlignment.Center, Enum.HorizontalAlignment.Right)
		end
		for i, it in ipairs(items) do
			local w, h = sizes[i][1], sizes[i][2]
			local x, y
			if vertical then
				x = bx + alignOffset(lp.HorizontalAlignment, bw - w, Enum.HorizontalAlignment.Center, Enum.HorizontalAlignment.Right)
				y = cursor
				if it.visible then
					cursor = cursor + h + pad
				end
			else
				y = by + alignOffset(lp.VerticalAlignment, bh - h, Enum.VerticalAlignment.Center, Enum.VerticalAlignment.Bottom)
				x = cursor
				if it.visible then
					cursor = cursor + w + pad
				end
			end
			placeNode(it.c, x, y, w, h, T, clip)
		end
		contentSize[list] = vertical and Vector2.new(cross * T.k, total * T.k) or Vector2.new(total * T.k, cross * T.k)
		return
	end
	if grid then
		local gp = props(grid)
		local g = gridMetrics(o, grid, bw, bh)
		local ox = bx + alignOffset(gp.HorizontalAlignment, bw - g.totalW, Enum.HorizontalAlignment.Center, Enum.HorizontalAlignment.Right)
		local oy = by + alignOffset(gp.VerticalAlignment, bh - g.totalH, Enum.VerticalAlignment.Center, Enum.VerticalAlignment.Bottom)
		local k = 0
		for _, it in ipairs(layoutItems(o, gp.SortOrder)) do
			local col, row
			if g.horizontal then
				col, row = k % g.per, k // g.per
			else
				row, col = k % g.per, k // g.per
			end
			local w, h = constrain(it.c, g.cw, g.ch)
			placeNode(it.c, ox + col * (g.cw + g.px), oy + row * (g.ch + g.py), w, h, T, clip)
			if it.visible then
				k = k + 1
			end
		end
		contentSize[grid] = Vector2.new(g.totalW * T.k, g.totalH * T.k)
		return
	end
	for _, c in ipairs(guiKids(o)) do
		local w, h = measureNode(c, bw, bh)
		local pos = props(c).Position or UDim2.new()
		local ap = props(c).AnchorPoint or Vector2.zero
		local x = bx + pos.X.Scale * bw + pos.X.Offset - ap.X * w
		local y = by + pos.Y.Scale * bh + pos.Y.Offset - ap.Y * h
		placeNode(c, x, y, w, h, T, clip)
	end
end

local function insetOf(sg)
	if props(sg).IgnoreGuiInset then
		return 0
	end
	return Sim.client and Sim.client.device.inset or 0
end

local function viewport()
	local cam = workspace and props(workspace).CurrentCamera
	return cam and props(cam).ViewportSize or Vector2.new(1280, 720)
end
Gui.viewport = viewport

local function layoutRoot(root)
	if cls(root) == "ScreenGui" then
		local vp = viewport()
		local inset = insetOf(root)
		local w, h = vp.X, vp.Y - inset
		local sc = firstOf(root, "UIScale")
		local s = sc and (props(sc).Scale or 1) or 1
		record(root, 0, inset, w, h, 1, nil)
		layoutChildren(root, 0, 0, w / s, h / s, { ox = 0, oy = inset, k = s }, { 0, inset, w, inset + h })
	else
		-- BillboardGui / SurfaceGui: their own canvas, not on the screen
		local p = props(root)
		local w, h = 100, 100
		if cls(root) == "SurfaceGui" then
			local cs = p.CanvasSize or Vector2.new(800, 600)
			w, h = cs.X, cs.Y
		elseif p.Size then
			w, h = math.max(p.Size.X.Offset, 1), math.max(p.Size.Y.Offset, 1)
		end
		record(root, 0, 0, w, h, 1, nil)
		layoutChildren(root, 0, 0, w, h, { ox = 0, oy = 0, k = 1 }, { 0, 0, w, h })
	end
end

local function rootOf(o)
	local n = o
	while n do
		if isA(cls(n), "LayerCollector") then
			return n
		end
		n = props(n).Parent
	end
	return nil
end

local function ensure(o)
	if Sim.writes ~= cacheVersion then
		cache, contentSize, canvasInfo = {}, {}, {}
		cacheVersion = Sim.writes
		order = 0
	end
	if cache[o] then
		return cache[o]
	end
	local root = rootOf(o)
	if not root then
		return nil
	end
	layoutRoot(root)
	return cache[o]
end
Gui.ensure = ensure

Sim.computed.AbsolutePosition = function(o)
	if not isA(cls(o), "GuiBase2d") then
		return nil
	end
	local r = ensure(o)
	return r and Vector2.new(r.x, r.y) or Vector2.zero
end
Sim.computed.AbsoluteSize = function(o)
	if not isA(cls(o), "GuiBase2d") then
		return nil
	end
	local r = ensure(o)
	return r and Vector2.new(r.w, r.h) or Vector2.zero
end
Sim.computed.AbsoluteRotation = function(o)
	if isA(cls(o), "GuiBase2d") then
		return props(o).Rotation or 0
	end
	return nil
end
Sim.computed.AbsoluteContentSize = function(o)
	local k = cls(o)
	if k ~= "UIListLayout" and k ~= "UIGridLayout" then
		return nil
	end
	local parent = props(o).Parent
	if parent then
		ensure(parent)
	end
	return contentSize[o] or Vector2.zero
end
Sim.computed.AbsoluteCanvasSize = function(o)
	if cls(o) ~= "ScrollingFrame" then
		return nil
	end
	ensure(o)
	local c = canvasInfo[o]
	return c and Vector2.new(c[1], c[2]) or Vector2.zero
end
Sim.computed.AbsoluteWindowSize = function(o)
	if cls(o) ~= "ScrollingFrame" then
		return nil
	end
	ensure(o)
	local c = canvasInfo[o]
	return c and Vector2.new(c[3], c[4]) or Vector2.zero
end
Sim.computed.TextBounds = function(o)
	if not isText(o) then
		return nil
	end
	local r = ensure(o)
	local size = props(o).TextSize or 14
	local f = props(o).FontFace
	local w, h = Sim.measureText(textOf(o), size, fontBold(o), props(o).TextWrapped and r and (r.w / math.max(r.k, 1e-6)) or nil, f and tostring(f.Family) or nil)
	local k = r and r.k or 1
	return Vector2.new(w * k, h * k)
end
Sim.computed.TextFits = function(o)
	if isText(o) then
		return true
	end
	return nil
end

------------------------------------------------------------------ what is on screen (for drawing)
local function shown(o)
	local n = o
	while n do
		local k = cls(n)
		if isA(k, "GuiObject") and props(n).Visible == false then
			return false
		end
		if isA(k, "LayerCollector") then
			return props(n).Enabled ~= false
		end
		n = props(n).Parent
	end
	return false
end

local function rgb(c)
	if not c then
		return nil
	end
	return { math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5) }
end

local function colorStops(seq)
	-- ColorSequence.new(c) / (c0, c1) / ({ keypoints })
	if not seq then
		return nil
	end
	local a = seq.args or {}
	if type(a[1]) == "table" and a[1].Time == nil and a[1].R == nil then
		local out = {}
		for _, kp in ipairs(a[1]) do
			table.insert(out, { kp.Time, rgb(kp.Value) })
		end
		return out
	end
	if a[2] then
		return { { 0, rgb(a[1]) }, { 1, rgb(a[2]) } }
	end
	return { { 0, rgb(a[1]) }, { 1, rgb(a[1]) } }
end

local function numberStops(seq)
	if not seq then
		return nil
	end
	local a = seq.args or {}
	if type(a[1]) == "table" then
		local out = {}
		for _, kp in ipairs(a[1]) do
			table.insert(out, { kp.Time, kp.Value })
		end
		return out
	end
	if a[2] then
		return { { 0, a[1] }, { 1, a[2] } }
	end
	return { { 0, a[1] or 0 }, { 1, a[1] or 0 } }
end

local function enumName(v)
	if v == nil then
		return nil
	end
	return v.Name or tostring(v)
end

local function describe(o, r)
	local p = props(o)
	local d = {
		cls = cls(o), name = tostring(p.Name), x = r.x, y = r.y, w = r.w, h = r.h, k = r.k, order = r.order,
		clip = r.clip and { r.clip[1], r.clip[2], r.clip[3], r.clip[4] } or nil,
		bg = rgb(p.BackgroundColor3), bgT = p.BackgroundTransparency or 0, rot = p.Rotation or 0, z = p.ZIndex or 1,
	}
	local corner = firstOf(o, "UICorner")
	if corner then
		local cr = props(corner).CornerRadius or UDim.new(0, 8)
		d.corner = math.min(cr.Scale * math.min(r.w, r.h) + cr.Offset * r.k, math.min(r.w, r.h) / 2)
	end
	for _, c in ipairs(kids(o)) do
		local k = cls(c)
		if k == "UIStroke" and props(c).Enabled ~= false then
			local sp = props(c)
			local mode = enumName(sp.ApplyStrokeMode) or "Contextual"
			local s = { color = rgb(sp.Color), t = sp.Transparency or 0, thick = (sp.Thickness or 1) * r.k }
			if isText(o) and mode ~= "Border" then
				d.textStroke = s
			else
				d.stroke = s
			end
		elseif k == "UIGradient" and props(c).Enabled ~= false then
			local gp = props(c)
			d.gradient = { rot = gp.Rotation or 0, colors = colorStops(gp.Color), transp = numberStops(gp.Transparency) }
		elseif k == "UITextSizeConstraint" then
			d.maxText = (props(c).MaxTextSize or 100) * r.k
			d.minText = (props(c).MinTextSize or 1) * r.k
		end
	end
	if isText(o) then
		d.text = textOf(o)
		d.textColor = rgb(p.TextColor3)
		d.textT = p.TextTransparency or 0
		d.textSize = (p.TextSize or 14) * r.k
		d.bold = fontBold(o)
		local f = p.FontFace
		d.font = f and tostring(f.Family) or ""
		d.xa = enumName(p.TextXAlignment) or "Center"
		d.ya = enumName(p.TextYAlignment) or "Center"
		d.wrapped = p.TextWrapped == true
		d.scaled = p.TextScaled == true
		d.truncate = enumName(p.TextTruncate) or "None"
		d.strokeT = p.TextStrokeTransparency or 1
		d.strokeColor = rgb(p.TextStrokeColor3)
		d.lineHeight = p.LineHeight or 1
	end
	if cls(o) == "ImageLabel" or cls(o) == "ImageButton" then
		d.image = tostring(p.Image or "")
		d.imageColor = rgb(p.ImageColor3)
		d.imageT = p.ImageTransparency or 0
	end
	if cls(o) == "ScrollingFrame" then
		d.scrollBar = (p.ScrollBarThickness or 12) * r.k
		d.scrollColor = rgb(p.ScrollBarImageColor3)
		local c = canvasInfo[o]
		if c then
			d.canvasH, d.windowH = c[2], c[4]
			d.canvasW, d.windowW = c[1], c[3]
		end
	end
	return d
end

-- everything drawn on the local player's screen, back to front
function Sim.dumpGui()
	local out = {}
	local pg = Sim.client and Sim.client.player:FindFirstChild("PlayerGui")
	if not pg then
		return out
	end
	local guis = {}
	for i, g in ipairs(kids(pg)) do
		if cls(g) == "ScreenGui" and props(g).Enabled ~= false then
			table.insert(guis, { g = g, i = i })
		end
	end
	table.sort(guis, function(a, b)
		local da, db = props(a.g).DisplayOrder or 0, props(b.g).DisplayOrder or 0
		if da ~= db then
			return da < db
		end
		return a.i < b.i
	end)
	for _, entry in ipairs(guis) do
		local g = entry.g
		ensure(g)
		local global = props(g).ZIndexBehavior == Enum.ZIndexBehavior.Global
		local list = {}
		local function walk(n, depth)
			local items = {}
			for i, c in ipairs(kids(n)) do
				if isA(cls(c), "GuiObject") then
					table.insert(items, { c = c, i = i })
				end
			end
			table.sort(items, function(a, b)
				local za, zb = props(a.c).ZIndex or 1, props(b.c).ZIndex or 1
				if za ~= zb then
					return za < zb
				end
				return a.i < b.i
			end)
			for _, it in ipairs(items) do
				local c = it.c
				if props(c).Visible ~= false then
					local r = cache[c]
					if r then
						local d = describe(c, r)
						d.seq = #list + 1
						table.insert(list, d)
					end
					walk(c, depth + 1)
				end
			end
		end
		walk(g, 0)
		if global then
			table.sort(list, function(a, b)
				if a.z ~= b.z then
					return a.z < b.z
				end
				return a.seq < b.seq
			end)
		end
		for _, d in ipairs(list) do
			d.gui = tostring(props(g).Name)
			table.insert(out, d)
		end
	end
	return out
end

Gui.shown = shown
return Gui
