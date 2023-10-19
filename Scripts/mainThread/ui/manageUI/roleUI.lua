local mod = {
    loadOrder = 2,
}

local playerSapiens = mjrequire "mainThread/playerSapiens"

local taskTreeUI = mjrequire "automatedRoles/taskTreeUI"
local taskAssignUI = mjrequire "automatedRoles/taskAssignUI"
local automatedRolesUI = mjrequire "automatedRoles/automatedRolesUI"

local automatedRoles = mjrequire "automatedRoles/automatedRoles"

local world = nil


function mod:onload(roleUI)	
	roleUI.init = function(roleUI_, gameUI, world_, manageUI_, hubUI, contentView)
		world = world_
		
		automatedRoles:init(world, playerSapiens)

		automatedRolesUI:init(roleUI_, contentView)
		taskTreeUI:init(roleUI_, gameUI, world_, manageUI_, contentView)
		taskAssignUI:init(roleUI_, gameUI, world_, manageUI_, hubUI, automatedRolesUI, taskTreeUI, contentView)
	end
	
	roleUI.update = function(roleUI_)
		automatedRolesUI:hide()
		taskAssignUI:hide()
		taskTreeUI:show()
	end
	
	roleUI.selectTask = function(roleUI_, skillTypeIndex)
		automatedRolesUI:hide()
		taskTreeUI:hide()
		taskAssignUI:show(skillTypeIndex)
	end
	
	roleUI.show = function(roleUI_)
		world:setHasUsedTasksUI()
	end
end

return mod