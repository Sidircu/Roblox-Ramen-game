--!nonstrict
-- Helper to build standard modal screens: Base.make(name, titleKey, size, render)
-- render(content, screen) rebuilds the content each refresh.
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Locale = require(Shared.Locale)
local Kit = require(script.Parent.Kit)

local Base = {}

function Base.make(name, titleKey, size, render)
	local s = { name = name }
	function s.create(root)
		s.win = Kit.window(root, size, Locale.t(titleKey), function()
			local Core = require(script.Parent.Parent.Core)
			Core.C.UI.close(name)
		end)
	end
	function s.visible()
		return s.win ~= nil and s.win.frame.Visible
	end
	-- The content is built again on every change; data changes come in bursts (a customer pays,
	-- a quest moves...), so a refresh waits a moment after the previous one, and the lists keep
	-- their scroll position.
	local last, pending = -1, false
	function s.refresh()
		if not s.win then
			return
		end
		local now = os.clock()
		if now - last < 0.2 then
			if not pending then
				pending = true
				task.delay(0.2, function()
					pending = false
					if s.win.frame.Visible then
						s.refresh()
					end
				end)
			end
			return
		end
		last = now
		s.win.title.Text = Locale.t(titleKey)
		local scrolls = {}
		for _, d in ipairs(s.win.content:GetDescendants()) do
			if d:IsA("ScrollingFrame") then
				scrolls[d.Name] = d.CanvasPosition
			end
		end
		Kit.clear(s.win.content)
		local ok, err = pcall(render, s.win.content, s)
		if not ok then
			warn("[UI] " .. name .. ": " .. tostring(err))
		end
		for _, d in ipairs(s.win.content:GetDescendants()) do
			if d:IsA("ScrollingFrame") and scrolls[d.Name] then
				d.CanvasPosition = scrolls[d.Name]
			end
		end
	end
	function s.open(arg)
		s.arg = arg
		local was = s.win.frame.Visible
		s.win.frame.Visible = true
		last = -1
		s.refresh()
		if not was then
			Kit.popIn(s.win.frame)
		end
	end
	function s.close()
		if s.win then
			s.win.frame.Visible = false
		end
	end
	return s
end

return Base
