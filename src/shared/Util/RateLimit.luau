--!nonstrict
-- Token bucket rate limiter keyed by any value (player, player..remote, ...).
local RateLimit = {}
RateLimit.__index = RateLimit

function RateLimit.new(perSecond, burst)
	return setmetatable({ rate = perSecond, burst = burst or perSecond, buckets = {} }, RateLimit)
end

function RateLimit:check(key)
	local now = os.clock()
	local b = self.buckets[key]
	if not b then
		b = { tokens = self.burst, t = now }
		self.buckets[key] = b
	end
	b.tokens = math.min(self.burst, b.tokens + (now - b.t) * self.rate)
	b.t = now
	if b.tokens >= 1 then
		b.tokens -= 1
		return true
	end
	return false
end

function RateLimit:clear(key)
	self.buckets[key] = nil
end

return RateLimit
