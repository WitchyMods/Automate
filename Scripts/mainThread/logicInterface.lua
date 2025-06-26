
local shadow = mjrequire "hammerstone/utils/shadow"

local automate = mjrequire "automate/automate"

local logicInterface = {}

function logicInterface:init(super, world, localPlayer)
	super(self, world, localPlayer)
	automate:init(world, self)
end

function logicInterface:setBridge(super, bridge_)
	super(self, bridge_)

	local bridge = bridge_

	bridge:registerMainThreadFunction("nonFollowerApproached", function(nomadID)
        automate:nonFollowerApproached(nomadID)
    end)

	bridge:registerMainThreadFunction("soilQualityDropped", function(vertID)
        automate:soilQualityDropped(vertID)
    end)
end

return shadow:shadow(logicInterface)