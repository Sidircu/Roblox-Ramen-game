--!nonstrict
-- Minimal signal implementation (connect / once / fire / wait).
local Signal = {}
Signal.__index = Signal

function Signal.new()
	return setmetatable({ _handlers = {} }, Signal)
end

function Signal:Connect(fn)
	local handler = { fn = fn, connected = true }
	table.insert(self._handlers, handler)
	local signal = self
	return {
		Disconnect = function()
			handler.connected = false
			local idx = table.find(signal._handlers, handler)
			if idx then
				table.remove(signal._handlers, idx)
			end
		end,
	}
end

function Signal:Once(fn)
	local conn
	conn = self:Connect(function(...)
		conn.Disconnect()
		fn(...)
	end)
	return conn
end

function Signal:Fire(...)
	for _, handler in ipairs(table.clone(self._handlers)) do
		if handler.connected then
			task.spawn(handler.fn, ...)
		end
	end
end

function Signal:Wait()
	local thread = coroutine.running()
	self:Once(function(...)
		task.spawn(thread, ...)
	end)
	return coroutine.yield()
end

function Signal:DisconnectAll()
	table.clear(self._handlers)
end

return Signal
