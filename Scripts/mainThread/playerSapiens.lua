
local shadow = mjrequire "hammerstone/utils/shadow"
local automatedRoles = mjrequire "automate/automatedRoles"

local playerSapiens = {}

function playerSapiens:skillPriorityListChanged(super)
	super(self)
	automatedRoles:reassignAll()
end

function playerSapiens:followersAdded(super, addedInfos)
	super(self, addedInfos)
	automatedRoles:reassignAll()
end

function playerSapiens:followersRemoved(super, removedIDs)
	super(self, removedIDs)
	automatedRoles:reassignAll()
end

return shadow:shadow(playerSapiens)