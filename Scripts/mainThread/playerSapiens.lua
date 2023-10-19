local mod = {
    loadOrder = 2,
}

local automatedRoles = mjrequire "automatedRoles/automatedRoles"

function mod:onload(playerSapiens)
	local super_skillPriorityListChanged = playerSapiens.skillPriorityListChanged
	
	playerSapiens.skillPriorityListChanged = function(playerSapiens_)
		super_skillPriorityListChanged(playerSapiens_)
		automatedRoles:reassignAll()
	end
	
	local super_followersAdded = playerSapiens.followersAdded
	playerSapiens.followersAdded = function(playerSapiens_, addedInfos)
		super_followersAdded(playerSapiens_, addedInfos)
		automatedRoles:reassignAll()
	end
	
	local super_followersRemoved = playerSapiens.followersRemoved
	playerSapiens.followersRemoved = function(playerSapiens_, removedIDs)
		super_followersRemoved(playerSapiens_, removedIDs)
		automatedRoles:reassignAll()
	end
end

return mod