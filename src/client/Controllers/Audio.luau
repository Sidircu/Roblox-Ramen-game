--!nonstrict
-- Sound: one-shot effects (2D or positional, random take and pitch), the sound patterns of the
-- cooking steps (knife chops in rhythm, broth pouring, noodles drained...), ambience loops mixed
-- from where you are (street outside, chatter that grows with the customers, bubbling pots, the
-- train) and a day / evening music playlist.
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")
local CollectionService = game:GetService("CollectionService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local AudioCfg = require(Shared.Config.Audio)
local Core = require(script.Parent.Parent.Core)

local Audio = {}
local rng = Random.new()
local loops = {} -- [name] = Sound for 2D ambience
local attached = {} -- [Model] = Sound for bubbling pots and cookers
local music, musicList, musicIndex = nil, nil, 0

local function settings()
	return Core.C.Data and Core.C.Data.m and Core.C.Data.m("settings") or {}
end

local function volume(kind)
	local s = settings() or {}
	if kind == "music" then
		return (s.music or 0.5) * AudioCfg.Volume.music
	elseif kind == "ambience" then
		return (s.sfx or 0.8) * AudioCfg.Volume.ambience
	end
	return (s.sfx or 0.8) * AudioCfg.Volume.sfx
end

local function pick(list)
	return list[rng:NextInteger(1, #list)]
end

local function fadeOut(s, after, time)
	task.delay(after, function()
		if s.Parent then
			TweenService:Create(s, TweenInfo.new(time or 0.25), { Volume = 0 }):Play()
			task.wait((time or 0.25) + 0.05)
			s:Stop()
		end
	end)
end

-- Plays effect `name`; pos (Vector3) makes it positional. opts: volume (multiplier), len, pitch
function Audio.play(name, pos, opts)
	local cfg = AudioCfg.Sfx[name]
	if not cfg or not cfg.ids or #cfg.ids == 0 then
		return
	end
	local vol = volume("sfx") * (cfg.volume or 1) * (opts and opts.volume or 1)
	if vol <= 0 then
		return
	end
	local s = Instance.new("Sound")
	s.SoundId = pick(cfg.ids)
	s.Volume = vol
	local p = cfg.pitch or { 0.96, 1.05 }
	s.PlaybackSpeed = (opts and opts.pitch) or (p[1] + (p[2] - p[1]) * rng:NextNumber())
	if cfg.start then
		s.TimePosition = cfg.start
	end
	local len = (opts and opts.len) or cfg.len
	if pos then
		local att = Instance.new("Attachment")
		att.WorldPosition = pos
		att.Parent = workspace.Terrain
		s.RollOffMode = Enum.RollOffMode.InverseTapered
		s.RollOffMinDistance = 6
		s.RollOffMaxDistance = cfg.range or 60
		s.Parent = att
		s.Ended:Connect(function()
			att:Destroy()
		end)
		task.delay(math.max(len or 0, 8), function()
			if att.Parent then
				att:Destroy()
			end
		end)
	else
		s.Parent = SoundService
		s.Ended:Connect(function()
			s:Destroy()
		end)
		task.delay(math.max(len or 0, 8), function()
			if s.Parent then
				s:Destroy()
			end
		end)
	end
	s:Play()
	if len then
		fadeOut(s, len, 0.25)
	end
	return s
end

-- Sound pattern of one cooking step lasting `dur` seconds at `pos`
function Audio.step(name, dur, pos)
	local cfg = AudioCfg.Steps[name]
	if not cfg then
		return
	end
	dur = math.max(0.3, dur or 1)
	if cfg.hit then
		-- knife: quick chops in rhythm with the animation
		local n = cfg.hits or 4
		for k = 0, n - 1 do
			task.delay(dur * (k + 0.5) / n, function()
				Audio.play(cfg.hit, pos)
			end)
		end
		return
	end
	if cfg.first then
		Audio.play(cfg.first, pos, { len = math.max(0.6, dur + 0.2) })
	end
	if cfg.last then
		task.delay(math.max(0.2, dur - 0.35), function()
			Audio.play(cfg.last, pos)
		end)
	end
end

------------------------------------------------------------------ ambience

local function loop2d(name)
	local cfg = AudioCfg.Ambience[name]
	if not cfg or not cfg.id or cfg.id == "" then
		return nil
	end
	if not loops[name] then
		local s = Instance.new("Sound")
		s.Name = "Ambience_" .. name
		s.SoundId = cfg.id
		s.Looped = true
		s.Volume = 0
		s.Parent = SoundService
		s:Play()
		loops[name] = s
	end
	return loops[name], cfg
end

local function setLoop(name, target)
	local s, cfg = loop2d(name)
	if not s then
		return
	end
	local v = target * (cfg.volume or 1) * volume("ambience")
	TweenService:Create(s, TweenInfo.new(1.2), { Volume = v }):Play()
end

local function customersInside()
	local n = 0
	for _, m in ipairs(CollectionService:GetTagged("Interactable")) do
		if m:GetAttribute("Kind") == "customer" then
			local st = m:GetAttribute("State")
			if st == "order" or st == "waiting" or st == "eating" or st == "reading" then
				n += 1
			end
		end
	end
	return n
end

-- bubbling loops on pots with broth and on cookers that are cooking
local function updateAttached()
	local seen = {}
	local base = volume("ambience")
	for _, m in ipairs(CollectionService:GetTagged("Interactable")) do
		local kind = m:GetAttribute("Kind")
		if (kind == "pot" or kind == "ricecooker") and m.PrimaryPart then
			local cooking = (m:GetAttribute("C") or 0) > 0
			local has = (m:GetAttribute("N") or 0) > 0
			local on = cooking or (kind == "pot" and has)
			if on then
				seen[m] = true
				local s = attached[m]
				local cfg = AudioCfg.Ambience[kind == "pot" and "boil" or "cooker"]
				if not s and cfg then
					s = Instance.new("Sound")
					s.SoundId = cfg.id
					s.Looped = true
					s.RollOffMode = Enum.RollOffMode.InverseTapered
					s.RollOffMinDistance = 4
					s.RollOffMaxDistance = cfg.range or 24
					s.TimePosition = rng:NextNumber() * 8
					s.Volume = 0
					s.Parent = m.PrimaryPart
					s:Play()
					attached[m] = s
				end
				if s and cfg then
					s.Volume = base * (cfg.volume or 0.3) * (cooking and 1.25 or 0.8)
				end
			end
		end
	end
	for m, s in pairs(attached) do
		if not seen[m] or not m.Parent then
			s:Destroy()
			attached[m] = nil
		end
	end
end

local function ambienceLoop()
	while true do
		local Camera = Core.C.Camera
		local inside = Camera and Camera.isIndoors and Camera.isIndoors() or false
		local day = Core.C.Data and Core.C.Data.day or {}
		setLoop("street", inside and 0.35 or 1)
		local crowd = math.clamp(customersInside() / 8, 0, 1)
		if day.phase ~= "open" then
			crowd = 0
		end
		setLoop("restaurant", crowd * (inside and 1 or 0.35))
		updateAttached()
		task.wait(0.6)
	end
end

-- the train on the viaduct carries its own sound
function Audio.attachTrain(part)
	local cfg = AudioCfg.Ambience.train
	if not cfg or not part then
		return nil
	end
	local s = Instance.new("Sound")
	s.SoundId = cfg.id
	s.Looped = true
	s.RollOffMode = Enum.RollOffMode.InverseTapered
	s.RollOffMinDistance = 30
	s.RollOffMaxDistance = cfg.range or 300
	s.Volume = 0
	s.Parent = part
	return s
end

function Audio.trainVolume()
	local cfg = AudioCfg.Ambience.train
	return volume("ambience") * (cfg and cfg.volume or 0.6)
end

------------------------------------------------------------------ music

local function nextTrack()
	local night = game:GetService("Lighting").ClockTime >= 18.5 or game:GetService("Lighting").ClockTime < 6
	local list = night and AudioCfg.Music.night or AudioCfg.Music.day
	if list ~= musicList then
		musicList = list
		musicIndex = rng:NextInteger(0, math.max(0, #list - 1))
	end
	if #list == 0 then
		return nil
	end
	musicIndex = musicIndex % #list + 1
	return list[musicIndex]
end

local function playNext()
	local id = nextTrack()
	if not id then
		return
	end
	music.SoundId = id
	music.TimePosition = 0
	music:Play()
end

local function preload()
	local list = {}
	for _, cfg in pairs(AudioCfg.Sfx) do
		for _, id in ipairs(cfg.ids or {}) do
			local s = Instance.new("Sound")
			s.SoundId = id
			table.insert(list, s)
		end
	end
	pcall(function()
		ContentProvider:PreloadAsync(list)
	end)
	for _, s in ipairs(list) do
		s:Destroy()
	end
end

function Audio.Start()
	task.spawn(preload)
	task.spawn(ambienceLoop)
	music = Instance.new("Sound")
	music.Name = "Music"
	music.Looped = false
	music.Parent = SoundService
	music.Ended:Connect(function()
		task.wait(2)
		playNext()
	end)
	playNext()
	local wasNight = nil
	while true do
		local clock = game:GetService("Lighting").ClockTime
		local night = clock >= 18.5 or clock < 6
		if wasNight ~= nil and night ~= wasNight then
			-- evening falls (or morning comes): fade into the other playlist
			TweenService:Create(music, TweenInfo.new(2), { Volume = 0 }):Play()
			task.wait(2.1)
			playNext()
		end
		wasNight = night
		music.Volume = volume("music")
		task.wait(2)
	end
end


return Audio
