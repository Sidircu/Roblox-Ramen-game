--!nonstrict
-- Server entry point: loads every service, then calls Init() and Start() in order.
local Core = require(script.Parent.Core)
local Services = script.Parent.Services

local ORDER = {
	"Net", "Data", "Analytics", "Plots", "Economy", "Progression", "World", "Entities", "Placement", "Hands",
	"Supply", "Appliance", "Seating", "Cooking", "Npc", "Customers", "Tasks", "Staff", "Day",
	"Meta", "Rewards", "Franchise", "Monetization", "Leaderboard", "Interaction", "Signs", "SelfTest", "Dev",
}

for _, name in ipairs(ORDER) do
	local module = Services:FindFirstChild(name)
	if module then
		local ok, svc = pcall(require, module)
		if ok then
			Core.S[name] = svc
		else
			warn("[Server] failed to load service " .. name .. ": " .. tostring(svc))
		end
	else
		warn("[Server] missing service " .. name)
	end
end

for _, name in ipairs(ORDER) do
	local svc = Core.S[name]
	if svc and svc.Init then
		local ok, err = pcall(svc.Init)
		if not ok then
			warn("[Server] " .. name .. ".Init failed: " .. tostring(err))
		end
	end
end

for _, name in ipairs(ORDER) do
	local svc = Core.S[name]
	if svc and svc.Start then
		task.spawn(function()
			local ok, err = pcall(svc.Start)
			if not ok then
				warn("[Server] " .. name .. ".Start failed: " .. tostring(err))
			end
		end)
	end
end

Core.Started = true
