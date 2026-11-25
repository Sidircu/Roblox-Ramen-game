--!nonstrict
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local NetDef = require(Shared.Net)
local Locale = require(Shared.Locale)
local GameConfig = require(Shared.Config.GameConfig)
local Kit = require(script.Parent.Parent.Kit)
local Base = require(script.Parent.Parent.Base)
local Core = require(script.Parent.Parent.Parent.Core)

local t = Locale.t

local function set(key, value)
	NetDef.event("SetSetting"):FireServer(key, value)
end

return Base.make("Settings", "ui.settings", UDim2.fromScale(0.5, 0.72), function(content)
	local s = Core.C.Data.m("settings") or {}
	local scroll = Kit.scroll({ Parent = content })
	local function choice(order, label, options, current, key)
		local row = Kit.card({ Size = UDim2.new(1, -8, 0, 60), LayoutOrder = order, Parent = scroll })
		Kit.label(label, { Parent = row, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(0.4, 0, 1, 0), FontFace = Kit.Theme.bold })
		local holder = Kit.new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromScale(0.4, 0), Size = UDim2.new(0.6, -10, 1, 0), Parent = row }, { Kit.list(Enum.FillDirection.Horizontal, 6, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center) })
		for i, o in ipairs(options) do
			Kit.button(o.label, { parent = holder, size = UDim2.fromOffset(o.width or 86, 38), style = (current == o.value) and "selected" or "secondary", order = i, textSize = 15, onClick = function()
				set(key, o.value)
			end })
		end
	end
	choice(1, "🌐 " .. t("ui.language"), { { label = t("ui.auto"), value = "auto" }, { label = "English", value = "en" }, { label = "Italiano", value = "it" } }, s.lang or "auto", "lang")
	local grids = {}
	for _, g in ipairs(GameConfig.GridSizes) do
		table.insert(grids, { label = g .. " stud", value = g })
	end
	choice(4, "📐 " .. t("ui.grid_size"), grids, s.grid or 1, "grid")
	local rots = {}
	for _, r in ipairs(GameConfig.RotationSteps) do
		table.insert(rots, { label = r .. "°", value = r })
	end
	choice(5, "🔄 " .. t("ui.rotation_step"), rots, s.rot or 90, "rot")
	local vols = { { label = "0%", value = 0 }, { label = "25%", value = 0.25 }, { label = "50%", value = 0.5 }, { label = "100%", value = 1 } }
	choice(6, "🎵 " .. t("ui.music"), vols, s.music or 0.5, "music")
	choice(7, "🔊 " .. t("ui.sfx"), vols, s.sfx or 0.8, "sfx")
	choice(3, "🎥 " .. t("ui.camera"), { { label = t("ui.auto"), value = "auto", width = 70 }, { label = t("ui.cam_first"), value = "first", width = 110 }, { label = t("ui.cam_game"), value = "game", width = 110 }, { label = "Roblox", value = "roblox", width = 76 } }, s.cam or "auto", "cam")
	local S = GameConfig.Sensitivity
	choice(2, "🖱️ " .. t("ui.cam_speed"), { { label = t("ui.sens_high"), value = S.High }, { label = t("ui.sens_medium"), value = S.Medium }, { label = t("ui.sens_low"), value = S.Low } }, s.camSpeed or S.Medium, "camSpeed")
	choice(8, "🖥️ " .. t("ui.low_graphics"), { { label = t("ui.on"), value = true }, { label = t("ui.off"), value = false } }, s.lowGfx == true, "lowGfx")
	-- the other restaurants of the street: everything, or only the building from outside (lighter)
	choice(9, "🏘️ " .. t("ui.others_detail"), { { label = t("ui.others_show"), value = "show", width = 124 }, { label = t("ui.others_hide"), value = "hide", width = 124 } }, s.others or "show", "others")
	Kit.button("🎓 " .. t("ui.restart_tutorial"), { parent = scroll, size = UDim2.new(1, -8, 0, 44), style = "plain", order = 10, onClick = function()
		NetDef.event("TutorialStep"):FireServer(0)
		Core.C.UI.close("Settings")
		if Core.C.Tutorial then
			Core.C.Tutorial.restart()
		end
	end })
end)
