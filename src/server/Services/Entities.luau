--!nonstrict
-- Registry of interactable things in the world (placed items, boxes, customers, fixed props).
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

function Entities.ofKind(kind)
	local out = {}
	for _, e in pairs(byUid) do
		if e.kind == kind then
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
