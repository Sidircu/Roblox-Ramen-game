--!nonstrict
-- Registry of interactable things in the world (placed items, boxes, customers, fixed props).
-- Every entity belongs to a restaurant: e.plot (also published as the PlotId attribute).
local CollectionService = game:GetService("CollectionService")

local Entities = {}
local byUid = {}

function Entities.register(uid, kind, model, data)
	local e = { uid = uid, kind = kind, model = model }
	if data then
		for k, v in pairs(data) do
			e[k] = v
		end
	end
	byUid[uid] = e
	if model then
		model:SetAttribute("Uid", uid)
		model:SetAttribute("Kind", kind)
		model:SetAttribute("PlotId", e.plot and e.plot.id or 0)
		CollectionService:AddTag(model, "Interactable")
	end
	return e
end

function Entities.unregister(uid)
	local e = byUid[uid]
	byUid[uid] = nil
	return e
end

function Entities.get(uid)
	return byUid[uid]
end

-- every entity of a kind; with a plot, only the ones of that restaurant
function Entities.ofKind(kind, plot)
	local out = {}
	for _, e in pairs(byUid) do
		if e.kind == kind and (plot == nil or e.plot == plot) then
			table.insert(out, e)
		end
	end
	return out
end

-- every entity of a restaurant
function Entities.ofPlot(plot)
	local out = {}
	for _, e in pairs(byUid) do
		if e.plot == plot then
			table.insert(out, e)
		end
	end
	return out
end

function Entities.all()
	return byUid
end

function Entities.position(e)
	if e.model and e.model.PrimaryPart then
		return e.model.PrimaryPart.Position
	elseif e.model then
		return e.model:GetPivot().Position
	end
	return nil
end

return Entities
