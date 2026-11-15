--!nonstrict
-- Shared registry of server services (avoids circular requires).
local Core = {
	S = {},
	Started = false,
}
return Core
