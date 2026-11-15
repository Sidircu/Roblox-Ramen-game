--!nonstrict
-- Invite friends to the personal world and set their permissions.
local Players = game:GetService("Players")
local SocialService = game:GetService("SocialService")
local HttpService = game:GetService("HttpService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local NetDef = require(Shared.Net)
local Locale = require(Shared.Locale)
local Kit = require(script.Parent.Parent.Kit)
local Base = require(script.Parent.Parent.Base)
local Core = require(script.Parent.Parent.Parent.Core)

local t = Locale.t

return Base.make("Invite", "ui.invite", UDim2.fromScale(0.5, 0.66), function(content)
	local session = Core.C.Data.session or {}
	local me = Players.LocalPlayer
	Kit.label(t("ui.invite_text"), { Parent = content, Size = UDim2.new(1, 0, 0, 60), TextSize = 17 })
	Kit.button("📨 " .. t("ui.invite_friends"), { parent = content, size = UDim2.new(1, 0, 0, 48), position = UDim2.fromOffset(0, 64), style = "green", onClick = function()
		local ok, can = pcall(function()
			return SocialService:CanSendGameInviteAsync(me)
		end)
		if ok and can then
			local opts = Instance.new("ExperienceInviteOptions")
			opts.PromptMessage = t("ui.invite_prompt")
			opts.LaunchData = HttpService:JSONEncode({ owner = session.ownerId or me.UserId })
			pcall(function()
				SocialService:PromptGameInvite(me, opts)
			end)
		else
			Core.C.UI.toast(t("msg.invite_unavailable"), "warning")
		end
	end })
	local scroll = Kit.scroll({ Position = UDim2.fromOffset(0, 124), Size = UDim2.new(1, 0, 1, -124), Parent = content })
	local perms = (Core.C.Data.world and Core.C.Data.world.perms) or {}
	for _, p in ipairs(Players:GetPlayers()) do
		local role = p.UserId == session.ownerId and "owner" or (perms[tostring(p.UserId)] == "comanager" and "comanager" or "helper")
		local card, right = Kit.row(role == "owner" and "👑" or "🧑‍🍳", p.DisplayName, t("role." .. role), 64)
		card.Parent = scroll
		if session.role == "owner" and role ~= "owner" then
			Kit.button(role == "comanager" and t("ui.make_helper") or t("ui.make_comanager"), { parent = right, size = UDim2.fromOffset(160, 36), style = "plain", textSize = 14, onClick = function()
				NetDef.event("SetPermission"):FireServer(p.UserId, role == "comanager" and "helper" or "comanager")
			end })
		end
	end
end)
