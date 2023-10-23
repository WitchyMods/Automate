-- Hammerstone
local shadow = mjrequire "hammerstone/utils/shadow"

local logic = {}

function logic:setBridge(super, bridge_)
    super(self, bridge_)

    bridge_:registerLogicThreadNetFunction("nonFollowerApproached", function(nomadID)
        bridge_:callMainThreadFunction("nonFollowerApproached", nomadID)
    end)

    bridge_:registerLogicThreadNetFunction("soilQualityDropped", function(vertID)
        bridge_:callMainThreadFunction("soilQualityDropped", vertID)
    end)
end

return shadow:shadow(logic)