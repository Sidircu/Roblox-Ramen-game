--!nonstrict
-- Sound effects (2D or positional) and background music.
local SoundService = game:GetService("SoundService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local AudioCfg = require(Shared.Config.Audio)
local Core = require(script.Parent.Parent.Core)

local Audio = {}
local cache = {}
local music

local function volume(kind)
	local s = Core.C.Data and Core.C.Data.m("settings")
	if kind == "music" then
		return (s and s.music or 0.5) * AudioCfg.Volume.music
	end
	return (s and s.sfx or 0.8) * AudioCfg.Volume.sfx
end

function Audio.play(name, pos)
	local id = AudioCfg.Sfx[name]
	if not id or id == "" then
		return
	end
	local vol = volume("sfx")
	if vol <= 0 then
		return
	end
	if pos then
		local p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.Transparency = 1
		p.Size = Vector3.new(0.2, 0.2, 0.2)
		p.Position = pos
		p.Parent = workspace.CurrentCamera
		local s = Instance.new("Sound")
		s.SoundId = id
		s.Volume = vol
		s.RollOffMaxDistance = 80
		s.Parent = p
		s:Play()
		task.delay(4, function()
			p:Destroy()
		end)
		return
	end
	local s = cache[name]
	if not s then
		s = Instance.new("Sound")
		s.SoundId = id
		s.Parent = SoundService
		cache[name] = s
	end
	s.Volume = vol
	s.TimePosition = 0
	s:Play()
end

function Audio.Start()
	music = Instance.new("Sound")
	music.Looped = true
	music.Parent = SoundService
	local currentId = nil
	while true do
		local night = game:GetService("Lighting").ClockTime >= 18.5 or game:GetService("Lighting").ClockTime < 6
		local id = night and AudioCfg.Music.night or AudioCfg.Music.day
		if id ~= "" and id ~= currentId then
			currentId = id
			music.SoundId = id
			music:Play()
		end
		music.Volume = volume("music")
		task.wait(2)
	end
end

return Audio
