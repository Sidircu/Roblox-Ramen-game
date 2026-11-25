--!nonstrict
-- Friends and helpers: invite friends to this street (they get a restaurant of their own and can
-- help in yours), choose who may help in your restaurant (friends or everyone), give players a
-- role in your restaurant (helper / co-manager / none) and go back to your own door.
local Players = game:GetService("Players")
local SocialService = game:GetService("SocialService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local NetDef = require(Shared.Net)
local Locale = require(Shared.Locale)
local Kit = require(script.Parent.Parent.Kit)
local Base = require(script.Parent.Parent.Base)
local Core = require(script.Parent.Parent.Parent.Core)

local t = Locale.t

return Base.make("Invite", "ui.invite", UDim2.fromScale(0.5, 0.7), function(content)
	local Data = Core.C.Data
	local me = Players.LocalPlayer
	local scroll = Kit.scroll({ Parent = content })
	Kit.label(t("ui.invite_text"), { Parent = scroll, Size = UDim2.new(1, -8, 0, 48), TextSize = 16, LayoutOrder = 1 })
	Kit.button("📨 " .. t("ui.invite_friends"), { parent = scroll, size = UDim2.new(1, -8, 0, 46), style = "green", order = 2, onClick = function()
		local ok, can = pcall(function()
			return SocialService:CanSendGameInviteAsync(me)
		end)
		if ok and can then
			local opts = Instance.new("ExperienceInviteOptions")
			opts.PromptMessage = t("ui.invite_prompt")
			pcall(function()
				SocialService:PromptGameInvite(me, opts)
			end)
		else
			Core.C.UI.toast(t("msg.invite_unavailable"), "warning")
		end
	end })
	Kit.button("🏠 " .. t("ui.go_home"), { parent = scroll, size = UDim2.new(1, -8, 0, 40), style = "plain", order = 3, onClick = function()
		NetDef.event("GoHome"):FireServer()
		Core.C.UI.close("Invite")
	end })
	-- who may help in my restaurant
	local settings = Data.m("settings") or {}
	local coop = settings.coop or "friends"
	local row = Kit.card({ Size = UDim2.new(1, -8, 0, 56), LayoutOrder = 4, Parent = scroll })
	Kit.label("🤝 " .. t("ui.coop_who"), { Parent = row, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(0.45, 0, 1, 0), FontFace = Kit.Theme.bold, TextYAlignment = Enum.TextYAlignment.Center })
	local holder = Kit.new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromScale(0.45, 0), Size = UDim2.new(0.55, -10, 1, 0), Parent = row }, { Kit.list(Enum.FillDirection.Horizontal, 6, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center) })
	for i, o in ipairs({ { value = "friends", label = t("ui.coop_friends") }, { value = "everyone", label = t("ui.coop_everyone") } }) do
		Kit.button(o.label, { parent = holder, size = UDim2.fromOffset(110, 36), style = coop == o.value and "selected" or "secondary", order = i, textSize = 14, onClick = function()
			NetDef.event("SetSetting"):FireServer("coop", o.value)
		end })
	end
	-- the players on this street and their role in my restaurant
	local perms = Data.m("perms") or {}
	Kit.title(t("ui.street_players"), { Parent = scroll, Size = UDim2.new(1, -8, 0, 30), LayoutOrder = 5, TextSize = 20 })
	local order = 10
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= me then
			order += 1
			local perm = perms[tostring(p.UserId)]
			local role = perm == "comanager" and "comanager" or (perm == "helper" and "helper" or "default")
			local card, right = Kit.row(role == "comanager" and "🛠️" or "🧑‍🍳", p.DisplayName, t("perm." .. role), 64)
			card.LayoutOrder = order
			card.Parent = scroll
			local actions = Kit.new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(170, 36), Parent = right }, { Kit.list(Enum.FillDirection.Horizontal, 4, Enum.HorizontalAlignment.Right) })
			Kit.button(role == "comanager" and t("ui.make_helper") or t("ui.make_comanager"), { parent = actions, size = UDim2.fromOffset(120, 34), style = "plain", textSize = 13, order = 1, onClick = function()
				NetDef.event("SetPermission"):FireServer(p.UserId, role == "comanager" and "helper" or "comanager")
			end })
			if perm then
				Kit.button("✕", { parent = actions, size = UDim2.fromOffset(40, 34), style = "close", order = 2, onClick = function()
					NetDef.event("SetPermission"):FireServer(p.UserId, "none")
				end })
			end
		end
	end
end)
