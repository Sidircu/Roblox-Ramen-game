--!nonstrict
-- Food visuals: dishes (per recipe), ingredients, supplier boxes, dirty dishes, cooking tools.
local Kit = require(script.Parent.Parent.Kit)
local P = require(script.Parent.Parent.Palette)
local Color = require(script.Parent.Parent.Parent.Util.Color)
local Recipes = require(script.Parent.Parent.Parent.Config.Recipes)
local Ingredients = require(script.Parent.Parent.Parent.Config.Ingredients)
local M = P.M

local NC = { collide = false, shadow = false }
local function nc()
	return { collide = false, shadow = false }
end

local BROTH = {
	broth_shoyu = "#7A4A22",
	broth_shio = "#E9D9A8",
	broth_miso = "#C58A3E",
	broth_tonkotsu = "#F1E4C8",
}

local function ingColor(id)
	local ing = Ingredients.byId[id]
	return ing and Color.hex(ing.color) or P.white
end

local function fishSlice(m, x, y, z, color, len, yaw)
	local cf = CFrame.new(x, y, z) * CFrame.Angles(0, math.rad(yaw or 0), 0)
	Kit.part(m, Vector3.new(len or 0.55, 0.08, 0.3), cf, color, M.smooth, nc())
	for k = -1, 1, 2 do
		Kit.part(m, Vector3.new(0.03, 0.085, 0.28), cf * CFrame.new(k * 0.12, 0.005, 0), Color3.new(1, 1, 1):Lerp(color, 0.4), M.smooth, nc())
	end
end

local function nigiri(m, x, z, fish, yaw)
	Kit.blob(m, 0.5, 0.24, 0.3, x, 0.27, z, P.rice, M.sand, nc())
	fishSlice(m, x, 0.42, z, fish, 0.6, yaw)
end

local function makiPiece(m, x, z, inner, outerColor, d)
	d = d or 0.34
	Kit.cyl(m, d, 0.3, x, 0.3, z, outerColor or P.nori, M.smooth, nc())
	Kit.cyl(m, d - 0.06, 0.31, x, 0.3, z, P.rice, M.sand, nc())
	Kit.cyl(m, d * 0.38, 0.32, x, 0.3, z, inner, M.smooth, nc())
end

local function plate(m, w, d, color, mat)
	Kit.box(m, w, 0.12, d, 0, 0.06, 0, color or P.wood_light, mat or M.wood, nc())
	Kit.box(m, 0.12, 0.06, d - 0.1, -w / 2 + 0.15, -0.0, 0, color or P.wood_light, mat or M.wood, nc())
	Kit.box(m, 0.12, 0.06, d - 0.1, w / 2 - 0.15, -0.0, 0, color or P.wood_light, mat or M.wood, nc())
end

local function roundPlate(m, d, color)
	Kit.cyl(m, d, 0.08, 0, 0.06, 0, color or P.porcelain, M.smooth, nc())
	Kit.cyl(m, d - 0.25, 0.09, 0, 0.065, 0, Color3.new(1, 1, 1):Lerp(color or P.porcelain, 0.9), M.smooth, nc())
end

local function bowl(m, d, h, outer, inner)
	Kit.cyl(m, d * 0.55, 0.1, 0, 0.05, 0, outer, M.smooth, nc())
	Kit.cyl(m, d * 0.8, h * 0.5, 0, 0.1 + h * 0.25, 0, outer, M.smooth, nc())
	Kit.cyl(m, d, h * 0.5, 0, 0.1 + h * 0.7, 0, outer, M.smooth, nc())
	Kit.cyl(m, d + 0.04, 0.05, 0, 0.1 + h * 0.95, 0, inner or P.lacquer, M.smooth, nc())
	return 0.1 + h * 0.9
end

local function toppings(m, list, y, r)
	local angle = 0
	for _, id in ipairs(list) do
		angle += 1.4
		local x, z = math.cos(angle) * r, math.sin(angle) * r
		if id == "naruto" then
			Kit.cyl(m, 0.32, 0.05, x, y + 0.03, z, P.white, M.smooth, nc())
			Kit.cyl(m, 0.18, 0.055, x, y + 0.035, z, P.sakura_dark, M.smooth, nc())
		elseif id == "egg" then
			Kit.blob(m, 0.38, 0.16, 0.28, x, y + 0.06, z, P.white, M.smooth, nc())
			Kit.blob(m, 0.2, 0.17, 0.16, x, y + 0.08, z, P.koi_orange, M.smooth, nc())
		elseif id == "chashu" then
			Kit.cyl(m, 0.5, 0.07, x, y + 0.04, z, Color.hex("#C9845A"), M.smooth, nc())
			Kit.cyl(m, 0.42, 0.075, x, y + 0.045, z, Color.hex("#E8B49A"), M.smooth, nc())
		elseif id == "scallion" then
			for k = 0, 5 do
				Kit.cyl(m, 0.06, 0.04, x + (k % 3) * 0.08 - 0.08, y + 0.03, z + math.floor(k / 3) * 0.08, P.leaf_light, M.smooth, nc())
			end
		elseif id == "corn" then
			for k = 0, 5 do
				Kit.ball(m, 0.08, x + (k % 3) * 0.07 - 0.07, y + 0.04, z + math.floor(k / 3) * 0.07, P.neon_yellow, M.smooth, nc())
			end
		elseif id == "butter" then
			Kit.box(m, 0.18, 0.1, 0.18, x, y + 0.06, z, Color.hex("#F7E39A"), M.smooth, nc())
		elseif id == "kikurage" then
			Kit.box(m, 0.35, 0.03, 0.08, x, y + 0.03, z, P.ink, M.smooth, nc())
			Kit.box(m, 0.3, 0.03, 0.08, x + 0.05, y + 0.035, z + 0.1, P.ink, M.smooth, nc())
		elseif id == "minced_pork" then
			Kit.blob(m, 0.35, 0.1, 0.35, x, y + 0.04, z, Color.hex("#8A4A3A"), M.sand, nc())
		elseif id == "chili_oil" then
			Kit.cyl(m, 0.5, 0.02, x * 0.3, y + 0.012, z * 0.3, P.red, M.glass, { collide = false, shadow = false, transparency = 0.3 })
		elseif id == "black_garlic" then
			Kit.cyl(m, 0.4, 0.02, x * 0.3, y + 0.013, z * 0.3, P.black, M.glass, { collide = false, shadow = false, transparency = 0.2 })
		elseif id == "matcha" then
			Kit.cyl(m, 0.3, 0.02, x, y + 0.012, z, P.matcha, M.smooth, nc())
		elseif id == "tofu" then
			Kit.box(m, 0.15, 0.15, 0.15, x, y + 0.05, z, P.white, M.smooth, nc())
		end
	end
end

local function noodles(m, y, r, color)
	for k = 0, 6 do
		local a = k * 0.9
		Kit.part(m, Vector3.new(r * 1.4, 0.05, 0.06), CFrame.new(math.cos(a) * r * 0.2, y + 0.02, math.sin(a) * r * 0.2) * CFrame.Angles(0, a, 0), color or Color.hex("#F2D27A"), M.smooth, nc())
	end
end

local function ramenBowl(m, recipe)
	local top = bowl(m, 1.35, 0.6, P.lacquer_dark, P.lacquer)
	local broth = Kit.cyl(m, 1.22, 0.05, 0, top, 0, Color.hex(BROTH[recipe.broth] or "#C58A3E"), M.glass, { collide = false, shadow = false, transparency = 0.05 })
	local _ = broth
	noodles(m, top, 0.5)
	local tops = {}
	for _, id in ipairs(recipe.ing) do
		if id ~= "noodles" and id ~= "tsukemen_noodles" then
			table.insert(tops, id)
		end
	end
	toppings(m, tops, top, 0.32)
	Kit.box(m, 0.4, 0.45, 0.03, -0.35, top + 0.15, 0.4, P.nori, M.smooth, { collide = false, shadow = false, rot = CFrame.Angles(math.rad(-20), 0, 0) })
	-- chopsticks and spoon
	Kit.box(m, 1.5, 0.05, 0.05, 0.1, 0.07, -0.85, P.wood_light, M.wood, nc())
	Kit.box(m, 1.5, 0.05, 0.05, 0.1, 0.07, -0.95, P.wood_light, M.wood, nc())
	local steam = Kit.box(m, 0.6, 0.05, 0.6, 0, top + 0.2, 0, P.white, M.smooth, { collide = false, shadow = false, transparency = 1 })
	Kit.particles(steam, "steam", { rate = 3 })
end

local function dish(recipeId, gold)
	local recipe = Recipes.byId[recipeId]
	local m = Kit.model("Dish")
	if gold then
		Kit.cyl(m, 1.75, 0.04, 0, 0.01, 0, P.gold, M.foil, nc())
		local shine = Kit.box(m, 0.3, 0.05, 0.3, 0, 0.6, 0, P.gold, M.smooth, { collide = false, shadow = false, transparency = 1 })
		Kit.particles(shine, "sparkle", { rate = 2, color = "#FFE08A", glow = 0.6 })
	end
	if not recipe then
		roundPlate(m, 1.2)
		Kit.finish(m, Vector3.new(1.3, 0.5, 1.3))
		return m
	end
	local kind = recipe.dish
	local fish = P.koi_orange
	for _, id in ipairs(recipe.ing) do
		local ing = Ingredients.byId[id]
		if ing and ing.storage == "fish" then
			fish = ingColor(id)
			break
		end
	end
	if kind == "nigiri" then
		plate(m, 1.5, 0.8)
		nigiri(m, -0.32, 0, fish, 10)
		nigiri(m, 0.32, 0, fish, -10)
		Kit.blob(m, 0.2, 0.1, 0.15, 0.6, 0.15, 0.25, P.leaf_light, M.smooth, nc())
	elseif kind == "maki" then
		plate(m, 1.5, 0.8)
		local inner = ingColor(recipe.ing[2] or "cucumber")
		for i = 0, 5 do
			makiPiece(m, -0.45 + (i % 3) * 0.45, -0.18 + math.floor(i / 3) * 0.36, inner)
		end
	elseif kind == "roll" then
		plate(m, 1.6, 0.8, P.black, M.smooth)
		local topping = ingColor(recipe.ing[2] or "avocado")
		for i = 0, 5 do
			local x = -0.6 + i * 0.24
			makiPiece(m, x, 0, ingColor(recipe.ing[3] or "avocado"), P.rice, 0.4)
			Kit.box(m, 0.22, 0.06, 0.36, x, 0.48, 0, topping, M.smooth, nc())
		end
		if table.find(recipe.ing, "eel_sauce") then
			Kit.box(m, 1.4, 0.02, 0.06, 0, 0.53, 0, Color.hex("#3B2414"), M.smooth, nc())
		end
	elseif kind == "temaki" then
		plate(m, 1.2, 0.8)
		Kit.wedge(m, 0.4, 0.9, 0.6, CFrame.new(0, 0.6, 0) * CFrame.Angles(math.rad(-30), 0, 0), P.nori, M.smooth, nc())
		Kit.blob(m, 0.35, 0.25, 0.35, 0, 0.95, -0.2, P.rice, M.sand, nc())
		Kit.blob(m, 0.25, 0.2, 0.2, 0.08, 1.05, -0.25, fish, M.smooth, nc())
		Kit.blob(m, 0.2, 0.18, 0.18, -0.1, 1.02, -0.22, ingColor("avocado"), M.smooth, nc())
	elseif kind == "gunkan" then
		plate(m, 1.3, 0.8)
		for _, x in ipairs({ -0.3, 0.3 }) do
			Kit.cyl(m, 0.45, 0.3, x, 0.28, 0, P.nori, M.smooth, nc())
			for k = 0, 5 do
				Kit.ball(m, 0.12, x - 0.1 + (k % 3) * 0.1, 0.46, -0.06 + math.floor(k / 3) * 0.12, P.koi_orange, M.glass, nc())
			end
		end
	elseif kind == "sashimi" then
		roundPlate(m, 1.6, P.indigo)
		Kit.blob(m, 0.5, 0.2, 0.5, 0, 0.18, 0.2, P.white, M.fabric, nc())
		local colors = { ingColor("salmon"), ingColor("tuna"), ingColor("yellowtail") }
		for i, c in ipairs(colors) do
			for k = 0, 1 do
				fishSlice(m, -0.45 + (i - 1) * 0.45, 0.17 + k * 0.05, -0.2 + k * 0.1, c, 0.5, 70)
			end
		end
		Kit.box(m, 0.4, 0.02, 0.3, 0.45, 0.13, 0.35, P.leaf, M.leafy, nc())
	elseif kind == "platter" then
		plate(m, 2.0, 1.1, P.lacquer_dark, M.smooth)
		nigiri(m, -0.6, -0.25, ingColor("otoro"), 0)
		nigiri(m, -0.1, -0.25, ingColor("yellowtail"), 0)
		nigiri(m, 0.4, -0.25, ingColor("shrimp"), 0)
		for i = 0, 2 do
			makiPiece(m, -0.5 + i * 0.4, 0.25, ingColor("ikura"))
		end
		Kit.cyl(m, 0.4, 0.25, 0.7, 0.25, 0.25, P.nori, M.smooth, nc())
		Kit.ball(m, 0.25, 0.7, 0.4, 0.25, P.koi_orange, M.glass, nc())
	elseif kind == "bowl" then
		ramenBowl(m, recipe)
	elseif kind == "tsukemen" then
		roundPlate(m, 1.3, P.black)
		noodles(m, 0.15, 0.5, Color.hex("#E8C26A"))
		Kit.blob(m, 0.9, 0.25, 0.7, -0.1, 0.22, 0, Color.hex("#E8C26A"), M.smooth, nc())
		local sub = Kit.model("dip")
		sub.Parent = m
		local top = bowl(sub, 0.7, 0.45, P.charcoal, P.lacquer)
		Kit.cyl(sub, 0.62, 0.04, 0, top, 0, Color.hex(BROTH.broth_tonkotsu), M.smooth, nc())
		for _, d in ipairs(sub:GetDescendants()) do
			if d:IsA("BasePart") then
				d.CFrame = CFrame.new(0.75, 0, 0.3) * d.CFrame
			end
		end
		toppings(m, { "chashu", "egg" }, 0.25, 0.3)
	elseif kind == "soup" then
		local top = bowl(m, 0.9, 0.45, P.lacquer, P.black)
		Kit.cyl(m, 0.82, 0.04, 0, top, 0, Color.hex(recipe.broth and BROTH[recipe.broth] or "#C58A3E"), M.smooth, nc())
		toppings(m, { "tofu", "scallion", "tofu" }, top, 0.2)
	elseif kind == "edamame" then
		roundPlate(m, 1.0, P.porcelain)
		for k = 0, 7 do
			Kit.blob(m, 0.35, 0.1, 0.14, -0.25 + (k % 4) * 0.17, 0.14, -0.15 + math.floor(k / 4) * 0.25, P.leaf_light, M.smooth, { collide = false, shadow = false, rot = CFrame.Angles(0, k, 0) })
		end
	elseif kind == "cup" then
		local liquid = recipeId == "matcha_latte" and Color.hex("#B8D08A") or Color.hex("#9DB85A")
		Kit.cyl(m, 0.5, 0.55, 0, 0.3, 0, recipeId == "matcha_latte" and P.white or P.stone_dark, M.smooth, nc())
		Kit.cyl(m, 0.44, 0.03, 0, 0.56, 0, liquid, M.smooth, nc())
		local steam = Kit.box(m, 0.3, 0.05, 0.3, 0, 0.7, 0, P.white, M.smooth, { collide = false, shadow = false, transparency = 1 })
		Kit.particles(steam, "steam", { rate = 2 })
		Kit.cyl(m, 0.8, 0.05, 0, 0.03, 0, P.wood_dark, M.wood, nc())
	elseif kind == "bottle" then
		Kit.cyl(m, 0.4, 0.8, 0, 0.4, 0, Color.hex("#7FC8E8"), M.glass, { collide = false, shadow = false, transparency = 0.3 })
		Kit.cyl(m, 0.22, 0.3, 0, 0.95, 0, Color.hex("#7FC8E8"), M.glass, { collide = false, shadow = false, transparency = 0.3 })
		Kit.ball(m, 0.15, 0, 0.85, 0, P.white, M.glass, nc())
		Kit.cyl(m, 0.24, 0.06, 0, 1.12, 0, P.neon_blue, M.smooth, nc())
	elseif kind == "gyoza" then
		roundPlate(m, 1.3, P.porcelain)
		for k = 0, 4 do
			Kit.blob(m, 0.42, 0.18, 0.24, -0.4 + k * 0.2, 0.16, 0, Color.hex("#E8C27A"), M.smooth, { collide = false, shadow = false, rot = CFrame.Angles(0, math.rad(80), 0) })
		end
		if table.find(recipe.ing, "chili_oil") then
			Kit.cyl(m, 0.3, 0.05, 0.45, 0.12, 0.35, P.red, M.glass, nc())
		end
	elseif kind == "fried" then
		roundPlate(m, 1.2, P.porcelain)
		Kit.box(m, 0.8, 0.02, 0.8, 0, 0.12, 0, P.paper, M.fabric, { collide = false, shadow = false, rot = CFrame.Angles(0, math.rad(45), 0) })
		for k = 0, 2 do
			Kit.blob(m, recipeId == "ebi_tempura" and 0.6 or 0.3, 0.25, 0.25, -0.2 + k * 0.2, 0.25, -0.1 + k * 0.1, Color.hex("#E0A64A"), M.sand, nc())
		end
		Kit.cyl(m, 0.25, 0.05, 0.4, 0.15, 0.3, P.neon_yellow, M.smooth, { collide = false, shadow = false, rot = CFrame.Angles(math.rad(90), 0, 0) })
	elseif kind == "takoyaki" then
		Kit.box(m, 1.2, 0.15, 0.7, 0, 0.08, 0, P.paper_warm, M.fabric, nc())
		for k = 0, 5 do
			local x, z = -0.36 + (k % 3) * 0.36, -0.15 + math.floor(k / 3) * 0.3
			Kit.ball(m, 0.32, x, 0.3, z, Color.hex("#B5703A"), M.sand, nc())
			Kit.box(m, 0.3, 0.02, 0.05, x, 0.47, z, P.white, M.smooth, nc())
		end
	elseif kind == "mochi" then
		roundPlate(m, 1.0, P.indigo)
		for k, c in ipairs({ P.sakura, P.white, P.matcha }) do
			Kit.blob(m, 0.34, 0.26, 0.34, -0.35 + k * 0.23, 0.2, 0, c, M.smooth, nc())
		end
	elseif kind == "okonomiyaki" then
		roundPlate(m, 1.3, P.porcelain)
		Kit.cyl(m, 1.0, 0.2, 0, 0.2, 0, Color.hex("#C98A4A"), M.sand, nc())
		Kit.cyl(m, 0.9, 0.02, 0, 0.31, 0, Color.hex("#4A2A1A"), M.smooth, nc())
		for k = -1, 1 do
			Kit.box(m, 0.8, 0.02, 0.04, 0, 0.33, k * 0.2, P.white, M.smooth, nc())
		end
	else
		roundPlate(m, 1.2)
	end
	Kit.finish(m, Vector3.new(1.6, 1, 1.2))
	m:SetAttribute("Recipe", recipeId)
	return m
end

local function ingredient(id)
	local ing = Ingredients.byId[id]
	local m = Kit.model("Ing")
	local c = ing and Color.hex(ing.color) or P.white
	local shape = ing and ing.shape or "pack"
	if shape == "fillet" then
		Kit.blob(m, 0.8, 0.25, 0.4, 0, 0.13, 0, c, M.smooth, nc())
		for k = -1, 1 do
			Kit.box(m, 0.03, 0.2, 0.32, k * 0.2, 0.15, 0, Color3.new(1, 1, 1):Lerp(c, 0.5), M.smooth, nc())
		end
	elseif shape == "veg" then
		if id == "avocado" then
			Kit.blob(m, 0.35, 0.45, 0.35, 0, 0.22, 0, Color.hex("#3E5A2A"), M.smooth, nc())
		else
			Kit.cylH(m, 0.2, 0.75, 0, 0.12, 0, c, M.smooth, nc())
		end
	elseif shape == "sack" then
		Kit.blob(m, 0.6, 0.65, 0.45, 0, 0.32, 0, P.paper_warm, M.fabric, nc())
		Kit.box(m, 0.35, 0.1, 0.02, 0, 0.35, -0.22, c, M.smooth, nc())
	elseif shape == "jar" then
		Kit.cyl(m, 0.42, 0.45, 0, 0.23, 0, P.glass, M.glass, { collide = false, shadow = false, transparency = 0.4 })
		Kit.cyl(m, 0.38, 0.32, 0, 0.18, 0, c, M.smooth, nc())
		Kit.cyl(m, 0.44, 0.1, 0, 0.5, 0, P.wood_dark, M.wood, nc())
	elseif shape == "bottle" then
		Kit.cyl(m, 0.25, 0.55, 0, 0.28, 0, c, M.glass, { collide = false, shadow = false, transparency = 0.15 })
		Kit.cyl(m, 0.12, 0.2, 0, 0.65, 0, c, M.glass, nc())
		Kit.cyl(m, 0.14, 0.06, 0, 0.77, 0, P.lacquer, M.smooth, nc())
	elseif shape == "noodle" then
		Kit.box(m, 0.7, 0.2, 0.35, 0, 0.1, 0, c, M.fabric, nc())
		for k = -2, 2 do
			Kit.box(m, 0.7, 0.03, 0.03, 0, 0.21, k * 0.06, Color3.new(1, 1, 1):Lerp(c, 0.8), M.smooth, nc())
		end
		Kit.box(m, 0.1, 0.22, 0.37, 0, 0.11, 0, P.lacquer, M.fabric, nc())
	elseif shape == "egg" then
		Kit.blob(m, 0.28, 0.36, 0.28, -0.12, 0.18, 0, Color.hex("#C9894A"), M.smooth, nc())
		Kit.blob(m, 0.28, 0.36, 0.28, 0.16, 0.18, 0.05, Color.hex("#C9894A"), M.smooth, nc())
	elseif shape == "sheet" then
		for k = 0, 3 do
			Kit.box(m, 0.6, 0.03, 0.6, 0, 0.02 + k * 0.035, 0, c, M.smooth, nc())
		end
	elseif shape == "ball" then
		for k, col in ipairs({ P.sakura, P.white, P.matcha }) do
			Kit.ball(m, 0.25, -0.3 + k * 0.15, 0.13, 0, col, M.smooth, nc())
		end
	elseif shape == "leaf" then
		for k = -1, 1 do
			Kit.cyl(m, 0.08, 0.7, k * 0.08, 0.35, 0, c, M.smooth, { collide = false, shadow = false, rot = CFrame.Angles(0, 0, math.rad(k * 8)) })
		end
		Kit.box(m, 0.25, 0.08, 0.1, 0, 0.12, 0, P.white, M.smooth, nc())
	else
		Kit.box(m, 0.5, 0.35, 0.35, 0, 0.18, 0, c, M.smooth, nc())
		Kit.box(m, 0.52, 0.12, 0.37, 0, 0.2, 0, P.white, M.smooth, nc())
	end
	Kit.finish(m, Vector3.new(0.8, 0.6, 0.6))
	m:SetAttribute("Ingredient", id)
	return m
end

-- Supplier cardboard box with an icon + portions label (language independent)
local function box(id, count)
	local ing = Ingredients.byId[id]
	local m = Kit.model("Box")
	local body = Kit.box(m, 1.8, 1.3, 1.5, 0, 0.65, 0, P.cardboard, M.cardboard, { name = "Body" })
	Kit.box(m, 1.82, 0.12, 0.3, 0, 1.25, 0, Color.hex("#D8C49A"), M.smooth, nc())
	Kit.box(m, 0.3, 0.12, 1.52, 0, 1.25, 0, Color.hex("#D8C49A"), M.smooth, nc())
	local _, label = Kit.text(body, Enum.NormalId.Front, (ing and ing.icon or "📦") .. " " .. tostring(count or (ing and ing.units) or 0), { color = "#2B2320", bg = "#F4EBDD", pps = 40 })
	label.Name = "Count"
	local _, label2 = Kit.text(body, Enum.NormalId.Top, ing and ing.icon or "📦", { color = "#2B2320", pps = 30 })
	local _l = label2
	Kit.finish(m, Vector3.new(1.8, 1.3, 1.5))
	m:SetAttribute("Ingredient", id)
	return m
end

local function dirty(kind)
	local m = Kit.model("Dirty")
	if kind == "bowl" then
		bowl(m, 1.2, 0.55, P.lacquer_dark, P.lacquer)
		Kit.cyl(m, 1.0, 0.03, 0, 0.35, 0, Color.hex("#A8865A"), M.smooth, nc())
	else
		roundPlate(m, 1.2, P.porcelain)
		for k = 0, 3 do
			Kit.ball(m, 0.08, -0.2 + k * 0.13, 0.13, (k % 2) * 0.15, P.rice, M.sand, nc())
		end
	end
	Kit.box(m, 1.2, 0.04, 0.05, 0.1, 0.12, -0.55, P.wood_light, M.wood, nc())
	Kit.finish(m, Vector3.new(1.3, 0.6, 1.3))
	return m
end

local function dishStack(count, kind)
	local m = Kit.model("Stack")
	for k = 0, math.min(count, 5) - 1 do
		if kind == "dirty" then
			Kit.cyl(m, 1.1, 0.1, 0, 0.06 + k * 0.12, 0, Color.hex("#D8D0C0"), M.smooth, nc())
		else
			Kit.cyl(m, 1.1, 0.1, 0, 0.06 + k * 0.12, 0, P.porcelain, M.smooth, nc())
		end
	end
	Kit.finish(m, Vector3.new(1.2, 0.7, 1.2))
	return m
end

local function tool(kind)
	local m = Kit.model("Tool")
	if kind == "knife" then
		Kit.box(m, 1.3, 0.25, 0.03, 0.4, 0, 0, P.metal, M.metal, { collide = false, shadow = false, reflectance = 0.3 })
		Kit.box(m, 0.6, 0.14, 0.1, -0.55, 0, 0, P.wood_dark, M.wood, nc())
	elseif kind == "mat" then
		for k = -4, 4 do
			Kit.cylH(m, 0.06, 1.3, 0, 0, k * 0.1, P.bamboo, M.wood, nc())
		end
	elseif kind == "ladle" then
		Kit.cyl(m, 0.06, 1.4, 0, 0.5, 0, P.metal, M.metal, nc())
		Kit.blob(m, 0.4, 0.2, 0.4, 0, -0.2, 0, P.metal, M.metal, nc())
	elseif kind == "spatula" then
		Kit.box(m, 0.5, 0.03, 0.4, 0.3, 0, 0, P.metal, M.metal, nc())
		Kit.box(m, 0.8, 0.08, 0.08, -0.3, 0.05, 0, P.wood_dark, M.wood, nc())
	else
		Kit.cyl(m, 0.5, 0.4, 0, 0, 0, P.metal, M.metal, { collide = false, shadow = false, transparency = 0.3 })
		Kit.cylH(m, 0.06, 1.0, 0.7, 0.1, 0, P.wood_dark, M.wood, nc())
	end
	local _ = NC
	Kit.finish(m, Vector3.new(1.4, 0.4, 0.6))
	return m
end

return function(Registry)
	Registry.registerFood("dish", dish)
	Registry.registerFood("ingredient", ingredient)
	Registry.registerFood("box", box)
	Registry.registerFood("dirty", dirty)
	Registry.registerFood("stack", dishStack)
	Registry.registerFood("tool", tool)
	Registry.Food.BrothColors = BROTH
end
