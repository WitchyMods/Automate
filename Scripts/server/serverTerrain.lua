-- Sapiens

-- Hammerstone
local shadow = mjrequire "hammerstone/utils/shadow"

local serverGOM = nil

local serverTerrain = {}

function serverTerrain:setServerGOM(super, serverGOM_, planManager_)
    super(self, serverGOM_, planManager_)
    serverGOM = serverGOM_
end

function serverTerrain:changeSoilQualityForVertex(super, vertID, qualityOffset)
    super(self, vertID, qualityOffset)

    if qualityOffset < 0 then
        serverGOM:soilQualityDropped(vertID)
    end
end

return shadow:shadow(serverTerrain)