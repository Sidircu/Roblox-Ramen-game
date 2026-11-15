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
	function s.refresh()
		if not s.win then
			return
		end
		s.win.title.Text = Locale.t(titleKey)
		Kit.clear(s.win.content)
		local ok, err = pcall(render, s.win.content, s)
		if not ok then
			warn("[UI] " .. name .. ": " .. tostring(err))
		end
	end
	function s.open(arg)
		s.arg = arg
		s.win.frame.Visible = true
		s.refresh()
	end
	function s.close()
		if s.win then
			s.win.frame.Visible = false
		end
	end
	return s
end

return Base
