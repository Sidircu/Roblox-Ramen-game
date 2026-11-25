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

local DAY = { ambient = Color.hex("#8E8476"), outdoor = Color.hex("#9E9486"), top = Color.hex("#FFF1DC"), bright = 2.4, atm = Color.hex("#C9D9E8"), decay = Color.hex("#8FA8C0"), tint = Color.hex("#FFF2E2") }
local SUNSET = { ambient = Color.hex("#8A6A5A"), outdoor = Color.hex("#A0786A"), top = Color.hex("#FFB070"), bright = 1.6, atm = Color.hex("#F0B08A"), decay = Color.hex("#A06A6A"), tint = Color.hex("#FFE2C8") }
-- night: blue sky outside, but a warm, cosy grade so lanterns and pendants glow amber
local NIGHT = { ambient = Color.hex("#4A4050"), outdoor = Color.hex("#2E3450"), top = Color.hex("#6A78B0"), bright = 0.5, atm = Color.hex("#2A3050"), decay = Color.hex("#1A1E38"), tint = Color.hex("#FFE9D4") }

local function blend(a, b, k)
	return {
		ambient = a.ambient:Lerp(b.ambient, k), outdoor = a.outdoor:Lerp(b.outdoor, k), top = a.top:Lerp(b.top, k),
		bright = a.bright + (b.bright - a.bright) * k, atm = a.atm:Lerp(b.atm, k), decay = a.decay:Lerp(b.decay, k), tint = a.tint:Lerp(b.tint, k),
	}
end

-- a long golden hour (15:30 to 20:30, the lanterns light up when it starts) and a rosy dawn;
-- the second value is how much of the night it is (lights on from 0.2)
local function look(clock)
	if clock >= 7.5 and clock < 15.5 then
		return DAY, 0
	elseif clock >= 15.5 and clock < 17 then
		return blend(DAY, SUNSET, (clock - 15.5) / 1.5), 0.2
	elseif clock >= 17 and clock < 19 then
		return SUNSET, 0.4
	elseif clock >= 19 and clock < 20.5 then
		return blend(SUNSET, NIGHT, (clock - 19) / 1.5), 0.6
	elseif clock >= 5 and clock < 6 then
		return blend(NIGHT, SUNSET, clock - 5), 0.6
	elseif clock >= 6 and clock < 7.5 then
		return blend(SUNSET, DAY, (clock - 6) / 1.5), 0.2
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
					-- (off inside the other restaurants hidden by Settings → Other restaurants)
					local nb = Core.C.Neighbours
					light.Enabled = on and not (low and light:IsA("SpotLight")) and not (nb and nb.hides(light))
				end
			end
		end
	end)
end

return LightingC
