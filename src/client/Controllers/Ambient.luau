--!nonstrict
-- Client-only animations: swaying lanterns and noren, maneki-neko paws, koi, shishi-odoshi,
-- streamers, and the evening train on the viaduct.
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Registry = require(Shared.Models.Registry)

local Ambient = {}
local parts = {} -- [part] = { kind, base, last, phase }
local rng = Random.new()

local function track(d)
	if d:IsA("BasePart") and d:GetAttribute("Animate") then
		parts[d] = { kind = d:GetAttribute("Animate"), base = d.CFrame, last = d.CFrame, phase = rng:NextNumber() * 10 }
	end
end

local function offset(info, part, tt)
	local k, ph = info.kind, info.phase
	local h = part.Size.Y
	if k == "sway" then
		return CFrame.new(0, h / 2, 0) * CFrame.Angles(math.sin(tt * 1.3 + ph) * 0.035, 0, math.sin(tt * 1.7 + ph) * 0.05) * CFrame.new(0, -h / 2, 0)
	elseif k == "paw" then
		return CFrame.new(0, -h / 2, 0) * CFrame.Angles(math.sin(tt * 4 + ph) * 0.45, 0, 0) * CFrame.new(0, h / 2, 0)
	elseif k == "fish" or k == "koi" then
		local r = k == "koi" and 1.4 or 0.9
		local a = tt * (k == "koi" and 0.5 or 0.8) + ph
		return CFrame.new(math.sin(a) * r, math.sin(tt * 2 + ph) * 0.05, math.cos(a) * r * 0.6) * CFrame.Angles(0, a + math.pi / 2, 0)
	elseif k == "shishi" then
		local cycle = (tt + ph) % 7
		local tilt = cycle < 5.5 and (cycle / 5.5) * 0.5 or 0.5 - (cycle - 5.5) / 1.5 * 0.5
		return CFrame.Angles(0, 0, -tilt)
	elseif k == "streamer" then
		return CFrame.Angles(0, math.sin(tt * 2 + ph) * 0.25, math.sin(tt * 3.2 + ph) * 0.12)
	end
	return CFrame.new()
end

local function runTrain()
	local S = Registry.Street
	if not S then
		return
	end
	local train = S.train(4)
	train.Parent = workspace.CurrentCamera
	while true do
		local dir = rng:NextNumber() < 0.5 and 1 or -1
		local x0, x1 = -520 * dir, 520 * dir
		local t0 = os.clock()
		local duration = 22
		while os.clock() - t0 < duration do
			local k = (os.clock() - t0) / duration
			train:PivotTo(CFrame.new(x0 + (x1 - x0) * k, 22 + 0.8 + 2.5, -95) * CFrame.Angles(0, dir > 0 and math.pi or 0, 0))
			task.wait()
		end
		train:PivotTo(CFrame.new(0, -200, 0))
		task.wait(rng:NextNumber() * 40 + 35)
	end
end

function Ambient.Start()
	Registry.load()
	for _, d in ipairs(workspace:GetDescendants()) do
		track(d)
	end
	workspace.DescendantAdded:Connect(track)
	workspace.DescendantRemoving:Connect(function(d)
		parts[d] = nil
	end)
	RunService.RenderStepped:Connect(function()
		local cam = workspace.CurrentCamera
		local camPos = cam and cam.CFrame.Position or Vector3.new()
		local tt = os.clock()
		for part, info in pairs(parts) do
			if part.Parent then
				-- the server moved/rebuilt the part: take the new base
				if part.CFrame ~= info.last then
					info.base = part.CFrame
				end
				if (info.base.Position - camPos).Magnitude < 110 then
					local cf = info.base * offset(info, part, tt)
					part.CFrame = cf
					info.last = cf
				end
			else
				parts[part] = nil
			end
		end
	end)
	task.spawn(runTrain)
end

return Ambient
