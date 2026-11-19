--!nonstrict
-- Game passes and developer products (IDs in Shared.Config.Monetization; 0 = disabled).
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config.Monetization)
local Formulas = require(Shared.Logic.Formulas)
local Core = require(script.Parent.Parent.Core)

local Monetization = {}
local owned = {} -- [player] = { [passId] = true }
local passByAsset, productById = {}, {}

for _, gp in ipairs(Config.GamePasses) do
	if gp.assetId ~= 0 then
		passByAsset[gp.assetId] = gp
	end
end
for _, p in ipairs(Config.Products) do
	if p.productId ~= 0 then
		productById[p.productId] = p
	end
end

local function passCfg(id)
	for _, gp in ipairs(Config.GamePasses) do
		if gp.id == id then
			return gp
		end
	end
	return nil
end

function Monetization.has(player, id)
	return owned[player] ~= nil and owned[player][id] == true
end

-- yen multiplier of a player's passes (applies to the income of their own restaurant)
function Monetization.yenMultiplier(player)
	local m = 1
	for _, gp in ipairs(Config.GamePasses) do
		if gp.effect.yenMult and Monetization.has(player, gp.id) then
			m *= gp.effect.yenMult
		end
	end
	return m
end

-- one-time rewards of a pass (starter pack items, VIP statue)
local function grantPass(player, gp)
	owned[player] = owned[player] or {}
	owned[player][gp.id] = true
	if gp.id == "gp_vip" then
		player:SetAttribute("VIP", true)
	end
	local d = Core.S.Data.waitFor(player, 30)
	if not d or d.passes[gp.id] then
		return
	end
	d.passes[gp.id] = true
	local e = gp.effect
	if e.yen then
		Core.S.Economy.add(player, e.yen, "product", { raw = true })
	end
	if e.item then
		d.inventory[e.item] = (d.inventory[e.item] or 0) + 1
	end
	if e.items then
		for id, n in pairs(e.items) do
			d.inventory[id] = (d.inventory[id] or 0) + n
		end
	end
	Core.S.Data.changed(player, "inventory")
	Core.S.Data.changed(player, "passes")
end

local function applyProduct(player, d, p)
	local e = p.effect
	if e.yen then
		local amount = Formulas.yenPack(e.yen, d.level, Config.YenLevelScale)
		Core.S.Economy.add(player, amount, "product", { raw = true })
	end
	if e.sakura then
		Core.S.Economy.addSakura(player, e.sakura)
	end
	if e.boost then
		local now = os.time()
		d.boosts[e.boost] = math.max(now, d.boosts[e.boost] or 0) + e.seconds
		Core.S.Data.changed(player, "boosts")
	end
end

local function processReceipt(info)
	local player = Players:GetPlayerByUserId(info.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local Data = Core.S.Data
	local d = Data.waitFor(player, 20)
	local p = productById[info.ProductId]
	if not d or not p then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	for _, r in ipairs(d.receipts) do
		if r == info.PurchaseId then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
	end
	applyProduct(player, d, p)
	table.insert(d.receipts, info.PurchaseId)
	while #d.receipts > 50 do
		table.remove(d.receipts, 1)
	end
	if Data.storeAvailable() and not Data.saveNow(player) then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	Core.S.Net.notify(player, "msg.purchase_thanks", nil, "success")
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

local function checkPasses(player)
	owned[player] = owned[player] or {}
	for _, gp in ipairs(Config.GamePasses) do
		if gp.assetId ~= 0 then
			local ok, has = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gp.assetId)
			end)
			if ok and has then
				task.spawn(grantPass, player, gp)
			end
		end
	end
end

function Monetization.Init()
	MarketplaceService.ProcessReceipt = processReceipt
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, assetId, purchased)
		local gp = passByAsset[assetId]
		if purchased and gp then
			grantPass(player, gp)
			Core.S.Net.notify(player, "msg.purchase_thanks", nil, "success")
		end
	end)
	Core.S.Net.on("BuyWithRobux", function(player, kind, id)
		if kind == "gamepass" then
			local gp = passCfg(id)
			if gp and gp.assetId ~= 0 then
				MarketplaceService:PromptGamePassPurchase(player, gp.assetId)
			end
		elseif kind == "product" then
			for _, p in ipairs(Config.Products) do
				if p.id == id and p.productId ~= 0 then
					MarketplaceService:PromptProductPurchase(player, p.productId)
				end
			end
		end
	end, 2)
end

function Monetization.Start()
	Players.PlayerAdded:Connect(checkPasses)
	for _, p in ipairs(Players:GetPlayers()) do
		task.spawn(checkPasses, p)
	end
	Players.PlayerRemoving:Connect(function(p)
		owned[p] = nil
	end)
end

return Monetization
