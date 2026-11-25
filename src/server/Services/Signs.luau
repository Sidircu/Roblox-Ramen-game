--!nonstrict
-- The restaurant's sign over the door (Config/Signs). The owner, or a co-manager, sets its name,
-- style and colours with SetSign (Screens/Sign). The name goes through Roblox's text filter as
-- text that every player sees (TextService) before it is shown, and again whenever the restaurant
-- is loaded, because the filter changes over time. A new name that cannot be checked is not shown.
local TextService = game:GetService("TextService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Signs = require(Shared.Config.Signs)
local Core = require(script.Parent.Parent.Core)

local Service = {}
local lastChange = {} -- [player] = os.clock() of the last change

-- one line of text: no control characters, single spaces, nothing at the ends; returns the text
-- and its length in letters, or nil when it is not text
function Service.clean(name)
	if type(name) ~= "string" then
		return nil
	end
	local n = utf8.len(name)
	if not n or n > 200 then
		return nil
	end
	name = name:gsub("%c", " ")
	name = name:gsub("%s+", " ")
	name = name:gsub("^ ", "")
	name = name:gsub(" $", "")
	return name, utf8.len(name)
end

-- Roblox's filter for text shown to everybody; nil when it cannot be checked right now
function Service.filter(text, userId)
	if text == "" then
		return ""
	end
	local ok, result = pcall(function()
		local filtered = TextService:FilterStringAsync(text, userId, Enum.TextFilterContext.PublicChat)
		return filtered:GetNonChatStringForBroadcastAsync()
	end)
	if ok and type(result) == "string" then
		return result
	end
	-- in Studio (test players, often an unpublished place) the filter may not answer: the name is
	-- shown as typed there so the sign can be tried; a live server never shows an unchecked name
	if RunService:IsStudio() then
		return text
	end
	return nil
end

-- req = { name, style, board, text } for the restaurant the player manages
function Service.set(player, req)
	local Plots, Net = Core.S.Plots, Core.S.Net
	local plot = Plots.of(player)
	if not plot or not Plots.canBuild(player, plot) then
		return Net.notify(player, "msg.no_permission", nil, "error")
	end
	local d = Plots.data(plot)
	if not d or type(req) ~= "table" then
		return
	end
	local style = Signs.StyleById[req.style] and req.style or nil
	local board = Signs.ColorById[req.board] and req.board or nil
	local text = Signs.ColorById[req.text] and req.text or nil
	local name, n = Service.clean(req.name)
	if not style or not board or not text or not name then
		return
	end
	if n > 0 and (n < Signs.MinName or n > Signs.MaxName) then
		return Net.notify(player, "msg.sign_length", { min = Signs.MinName, max = Signs.MaxName }, "error")
	end
	if os.clock() - (lastChange[player] or -math.huge) < Signs.MinSecondsBetweenChanges then
		return Net.notify(player, "msg.sign_wait", nil, "error")
	end
	lastChange[player] = os.clock()
	local shown = d.sign and d.sign.name == name and d.sign.shown or nil
	if not shown then
		shown = Service.filter(name, player.UserId)
		if not shown then
			return Net.notify(player, "msg.sign_filter_failed", nil, "error")
		end
	end
	d.sign = { name = name, shown = shown, style = style, board = board, text = text }
	Core.S.Data.changed(plot.owner, "sign")
	Core.S.World.paintSign(plot)
	Core.S.Plots.notify(plot, "msg.sign_saved", nil, "success")
end

-- the name is checked again when a restaurant opens (its owner joined)
local function refilter(plot, owner, d)
	local sign = d and d.sign
	if not sign or (sign.name or "") == "" then
		return
	end
	local shown = Service.filter(sign.name, owner.UserId)
	if shown and shown ~= sign.shown and plot.owner == owner then
		sign.shown = shown
		Core.S.Data.changed(owner, "sign")
		Core.S.World.paintSign(plot)
	end
end

function Service.Init()
	Core.S.Net.on("SetSign", function(player, req)
		Service.set(player, req)
	end, 2)
end

function Service.Start()
	Core.S.Plots.Claimed:Connect(function(plot, owner, d)
		task.spawn(refilter, plot, owner, d or Core.S.Plots.data(plot))
	end)
	Players.PlayerRemoving:Connect(function(player)
		lastChange[player] = nil
	end)
end

return Service
