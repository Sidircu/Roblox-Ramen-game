--!nonstrict
-- Redeem a code (Config/Rewards.Codes): each code works once per player.
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local NetDef = require(Shared.Net)
local Locale = require(Shared.Locale)
local Kit = require(script.Parent.Parent.Kit)
local Base = require(script.Parent.Parent.Base)

local t = Locale.t
local T = Kit.Theme

return Base.make("Codes", "ui.codes", UDim2.fromScale(0.4, 0.42), function(content)
	Kit.label("🎟️", { Parent = content, Size = UDim2.new(1, 0, 0, 56), TextScaled = true, TextXAlignment = Enum.TextXAlignment.Center })
	Kit.label(t("ui.codes_hint"), { Parent = content, Position = UDim2.fromOffset(0, 60), Size = UDim2.new(1, 0, 0, 44), TextSize = 16, TextColor3 = T.muted, TextXAlignment = Enum.TextXAlignment.Center })
	local box = Kit.new("TextBox", {
		Parent = content, Position = UDim2.fromOffset(0, 112), Size = UDim2.new(1, 0, 0, 46), Text = "", PlaceholderText = t("ui.codes_placeholder"),
		ClearTextOnFocus = false, TextSize = 22, FontFace = T.bold, TextColor3 = T.ink, BackgroundColor3 = T.white,
	}, { Kit.corner(10), Kit.stroke(T.wood, 2) })
	local function redeem()
		if box.Text ~= "" then
			NetDef.event("RedeemCode"):FireServer(box.Text)
			box.Text = ""
		end
	end
	box.FocusLost:Connect(function(enter)
		if enter then
			redeem()
		end
	end)
	Kit.button(t("ui.redeem"), { parent = content, size = UDim2.new(1, 0, 0, 46), position = UDim2.new(0, 0, 1, -48), style = "green", onClick = redeem })
end)
