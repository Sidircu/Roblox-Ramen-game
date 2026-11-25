--!nonstrict
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local NetDef = require(Shared.Net)
local Locale = require(Shared.Locale)
local Format = require(Shared.Util.Format)
local Kit = require(script.Parent.Parent.Kit)
local Base = require(script.Parent.Parent.Base)
local Core = require(script.Parent.Parent.Parent.Core)

local t = Locale.t

return Base.make("Offline", "ui.offline", UDim2.fromScale(0.36, 0.4), function(content)
	local meta = Core.C.Data.m("meta") or {}
	local amount = meta.offlinePending or 0
	Kit.label("💰", { Parent = content, Size = UDim2.new(1, 0, 0, 60), TextScaled = true, TextXAlignment = Enum.TextXAlignment.Center })
	Kit.label(t("ui.offline_text", { hours = math.floor((meta.offlineHours or 0) * 10) / 10, yen = amount }), { Parent = content, Position = UDim2.fromOffset(0, 70), Size = UDim2.new(1, 0, 0, 60), TextSize = 20, TextXAlignment = Enum.TextXAlignment.Center })
	Kit.button(t("ui.claim") .. " " .. Format.yen(amount, Locale.get()), { parent = content, size = UDim2.new(1, 0, 0, 48), position = UDim2.new(0, 0, 1, -50), style = "reward", onClick = function()
		NetDef.event("ClaimOffline"):FireServer()
		Core.C.UI.close("Offline")
	end })
end)
