-- Sapiens
local server = mjrequire "server/server"

-- Hammerstone
local shadow = mjrequire "hammerstone/utils/shadow"

local serverWorld = nil

local serverGOM = {}

function serverGOM:setServerWorld(super, serverWorld_, serverTribe_)
    super(self, serverWorld_, serverTribe_)

    serverWorld = serverWorld_
end

function serverGOM:nonFollowerApproached(tribeID, nomadID)
    local clientID = serverWorld:clientIDForTribeID(tribeID)
    if not clientID or clientID == mj.serverClientID then
        return
    end

    server:callClientFunction(
            "nonFollowerApproached",
            clientID,
            nomadID
        )
end

function serverGOM:soilQualityDropped(vertID)
    server:callClientFunctionForAllClients("soilQualityDropped", vertID)
end

return shadow:shadow(serverGOM)