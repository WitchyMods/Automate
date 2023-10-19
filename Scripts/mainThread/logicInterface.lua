local mod = {
    loadOrder = 1,
}

local automatedRoles = mjrequire "automatedRoles/automatedRoles"
local playerSapiens = mjrequire "mainThread/playerSapiens"

function mod:onload(logicInterface)
	local super_init = logicInterface.init
	
	logicInterface.init = function(logicInterface_, world_, localPlayer_)
		super_init(logicInterface_, world_, localPlayer_)
		automatedRoles:init(world_, playerSapiens)
	end
end

return mod