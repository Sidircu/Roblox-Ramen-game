--!nonstrict
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local NetDef = require(Shared.Net)
local Kit = require(script.Parent.Parent.Kit)
local Base = require(script.Parent.Parent.Base)

local CMDS = {
	{ "💴 +10.000", "yen", 10000 }, { "💴 +1M", "yen", 1000000 }, { "🌸 +50", "sakura", 50 }, { "⬆️ +1 level", "level", nil },
	{ "Level 25", "level", 25 }, { "Level 45", "level", 45 }, { "🎫 All licenses", "licenses" }, { "🏗️ All zones", "zones" },
	{ "📦 Stock boxes", "stock" }, { "🧍 Spawn customer", "spawn" }, { "🕚 Close day", "time" }, { "⭐ 5-star reviews", "rating" },
	{ "♻️ Reset (Studio)", "reset" },
}

return Base.make("Dev", "ui.dev", UDim2.fromScale(0.5, 0.6), function(content)
	local grid = Kit.scroll({ Parent = content }, Kit.grid(200, 44, 8))
	for i, c in ipairs(CMDS) do
		Kit.button(c[1], { parent = grid, size = UDim2.fromOffset(200, 44), style = c[2] == "reset" and "primary" or "dark", order = i, textSize = 15, onClick = function()
			NetDef.event("Dev"):FireServer(c[2], c[3])
		end })
	end
end)
