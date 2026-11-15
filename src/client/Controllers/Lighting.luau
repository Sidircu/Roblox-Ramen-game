--!nonstrict
-- Time-of-day look (sky colors, atmosphere, bloom, color grading) and night lights.
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Color = require(Shared.Util.Color)
local Core = require(script.Parent.Parent.Core)

local LightingC = {}
local atmosphere, bloom, grading, rays
local lights = {}

local DAY = { ambient = Color.hex("#8C8478"), outdoor = Color.hex("#9C9488"), top = Color.hex("#FFF3E0"), bright = 2.4, atm = Color.hex("#C9D9E8"), decay = Color.hex("#8FA8C0"), tint = Color.hex("#FFF6EC") }
local SUNSET = { ambient = Color.hex("#8A6A5A"), outdoor = Color.hex("#A0786A"), top = Color.hex("#FFB070"), bright = 1.6, atm = Color.hex("#F0B08A"), decay = Color.hex("#A06A6A"), tint = Color.hex("#FFE2C8") }
local NIGHT = { ambient = Color.hex("#3A3A58"), outdoor = Color.hex("#2E3450"), top = Color.hex("#6A78B0"), bright = 0.5, atm = Color.hex("#2A3050"), decay = Color.hex("#1A1E38"), tint = Color.hex("#D8DCFF") }

local function blend(a, b, k)
	return {
		ambient = a.ambient:Lerp(b.ambient, k), outdoor = a.outdoor:Lerp(b.outdoor, k), top = a.top:Lerp(b.top, k),
		bright = a.bright + (b.bright - a.bright) * k, atm = a.atm:Lerp(b.atm, k), decay = a.decay:Lerp(b.decay, k), tint = a.tint:Lerp(b.tint, k),
	}
end

local function look(clock)
	if clock >= 7 and clock < 16.5 then
		return DAY, 0
	elseif clock >= 16.5 and clock < 18.5 then
		return blend(DAY, SUNSET, (clock - 16.5) / 2), 0.2
	elseif clock >= 18.5 and clock < 20 then
		return blend(SUNSET, NIGHT, (clock - 18.5) / 1.5), 0.6
	elseif clock >= 5 and clock < 7 then
		return blend(NIGHT, DAY, (clock - 5) / 2), 0.4
	end
	return NIGHT, 1
end

local function track(d)
	if d:IsA("Light") and d:GetAttribute("NightLight") ~= nil then
		table.insert(lights, d)
	end
end

function LightingC.Init()
	atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
	atmosphere.Density = 0.32
	atmosphere.Offset = 0.2
	atmosphere.Glare = 0.2
	atmosphere.Haze = 1.2
	atmosphere.Parent = Lighting
	bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.55
	bloom.Size = 26
	bloom.Threshold = 1.4
	bloom.Parent = Lighting
	grading = Instance.new("ColorCorrectionEffect")
	grading.Saturation = 0.12
	grading.Contrast = 0.08
	grading.Parent = Lighting
	rays = Instance.new("SunRaysEffect")
	rays.Intensity = 0.05
	rays.Spread = 0.6
	rays.Parent = Lighting
	Lighting.EnvironmentDiffuseScale = 1
	Lighting.EnvironmentSpecularScale = 1
	for _, d in ipairs(workspace:GetDescendants()) do
		track(d)
	end
	workspace.DescendantAdded:Connect(track)
end

function LightingC.Start()
	local lastLights = 0
	RunService.Heartbeat:Connect(function()
		local clock = Lighting.ClockTime
		local l, night = look(clock)
		Lighting.Ambient = l.ambient
		Lighting.OutdoorAmbient = l.outdoor
		Lighting.ColorShift_Top = l.top
		Lighting.Brightness = l.bright
		atmosphere.Color = l.atm
		atmosphere.Decay = l.decay
		grading.TintColor = l.tint
		local s = Core.C.Data and Core.C.Data.m("settings")
		local low = s and s.lowGfx
		bloom.Enabled = not low
		rays.Enabled = not low
		Lighting.GlobalShadows = not low
		if os.clock() - lastLights > 1 then
			lastLights = os.clock()
			local on = night >= 0.2
			for i = #lights, 1, -1 do
				local light = lights[i]
				if not light.Parent then
					table.remove(lights, i)
				elseif light:GetAttribute("NightLight") then
					light.Enabled = on and not (low and light:IsA("SpotLight"))
				end
			end
		end
	end)
end

return LightingC
