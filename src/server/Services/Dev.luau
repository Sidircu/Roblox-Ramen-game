--!nonstrict
-- Developer tools: available in Studio or to the experience creator.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Licenses = require(Shared.Config.Licenses)
local Expansions = require(Shared.Config.Expansions)
local Ingredients = require(Shared.Config.Ingredients)
local Formulas = require(Shared.Logic.Formulas)
local Uid = require(Shared.Util.Uid)
local Core = require(script.Parent.Parent.Core)

local Dev = {}

local function allowed(player)
	if RunService:IsStudio() then
		return true
	end
	return game.CreatorType == Enum.CreatorType.User and player.UserId == game.CreatorId
end

local function run(player, cmd, arg)
	local S = Core.S
	local plot = S.Plots.ofPlayer(player)
	local d = S.Plots.data(plot)
	if not d then
		return
	end
	local owner = player
	if cmd == "yen" then
		S.Economy.add(owner, tonumber(arg) or 10000, "dev", { raw = true })
	elseif cmd == "sakura" then
		S.Economy.addSakura(owner, tonumber(arg) or 50)
	elseif cmd == "level" then
		local target = math.clamp(math.floor(tonumber(arg) or (d.level + 1)), 1, Formulas.MaxLevel)
		d.level = target
		d.xp = 0
		S.Data.changed(owner, "level")
		S.Data.changed(owner, "xp")
	elseif cmd == "licenses" then
		for _, l in ipairs(Licenses.list) do
			d.licenses[l.id] = true
			for _, r in ipairs(l.recipes) do
				d.menu[r] = d.menu[r] or { on = true, price = 1 }
			end
		end
		S.Data.changed(owner, "licenses")
		S.Data.changed(owner, "menu")
	elseif cmd == "zones" then
		for _, e in ipairs(Expansions.list) do
			d.zones[e.id] = true
		end
		S.Plots.rebuild(plot)
	elseif cmd == "renos" or cmd == "plain" then
		-- all renovations on (detailed look) or off (plain starting look)
		for _, e in ipairs(Expansions.list) do
			if e.reno then
				d.zones[e.id] = cmd == "renos" or nil
			end
		end
		S.Data.changed(owner, "zones")
		S.Plots.rebuild(plot)
	elseif cmd == "spawn" then
		task.spawn(S.Customers.trySpawn, plot, type(arg) == "string" and arg or nil)
	elseif cmd == "time" then
		S.Day.finish()
	elseif cmd == "stock" then
		for _, ing in ipairs(Ingredients.list) do
			if d.licenses[ing.license] then
				for _ = 1, 2 do
					table.insert(d.storage, { u = Uid.new("b"), g = ing.id, n = ing.units })
				end
			end
		end
		S.Supply.layout(plot)
	elseif cmd == "rating" then
		for _ = 1, 20 do
			S.Progression.addReview(plot, 5, 1)
		end
	elseif cmd == "selftest" then
		task.spawn(S.SelfTest.run, player)
		return
	elseif cmd == "reset" and RunService:IsStudio() then
		S.Data.reset(owner)
		S.Plots.rebuild(plot)
		for _, k in ipairs(S.Data.WorldKeys) do
			S.Data.changed(owner, k)
		end
		S.Data.changed(owner, "meta")
	end
	S.Net.notify(player, "msg.dev_done", { cmd = cmd }, "info")
end

function Dev.Init()
	Core.S.Net.on("Dev", function(player, cmd, arg)
		if allowed(player) and type(cmd) == "string" then
			run(player, cmd, arg)
		end
	end, 5)
end

function Dev.Start()
	local function mark(p)
		if allowed(p) then
			p:SetAttribute("Dev", true)
		end
	end
	Players.PlayerAdded:Connect(mark)
	for _, p in ipairs(Players:GetPlayers()) do
		mark(p)
	end
end

return Dev
