--!nonstrict
-- Client entry point.
if not game:IsLoaded() then
	game.Loaded:Wait()
end

local Core = require(script.Parent.Core)
local Controllers = script.Parent.Controllers

local ORDER = {
	"Data", "Audio", "UI", "Lighting", "Ambient", "WorldUI", "Camera", "Interaction", "FirstPerson", "Sink", "Build", "Tutorial", "Effects",
}

for _, name in ipairs(ORDER) do
	local m = Controllers:FindFirstChild(name)
	if m then
		local ok, c = pcall(require, m)
		if ok then
			Core.C[name] = c
		else
			warn("[Client] failed to load " .. name .. ": " .. tostring(c))
		end
	end
end

for _, name in ipairs(ORDER) do
	local c = Core.C[name]
	if c and c.Init then
		local ok, err = pcall(c.Init)
		if not ok then
			warn("[Client] " .. name .. ".Init failed: " .. tostring(err))
		end
	end
end

for _, name in ipairs(ORDER) do
	local c = Core.C[name]
	if c and c.Start then
		task.spawn(function()
			local ok, err = pcall(c.Start)
			if not ok then
				warn("[Client] " .. name .. ".Start failed: " .. tostring(err))
			end
		end)
	end
end
