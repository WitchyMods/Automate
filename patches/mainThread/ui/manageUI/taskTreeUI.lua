local patch = {
	debugCopyAfter = true,
    operations = {
		[1] = { type = "insertAfter", after = "local uiToolTip = mjrequire \"mainThread/ui/uiCommon/uiToolTip\"\r\n", string = 
[[
local modOptionsManager = mjrequire "hammerstone/options/modOptionsManager"
local automatedRoles = mjrequire "automate/automatedRoles"
]] },
		[2] = { type = "insertAfter", after = "uiStandardButton:setToggleState(autoRoleAssignmentToggleButton, world:getAutoRoleAssignmentEnabled())\r\n", string = 
[[            local overrideAutoRoles = modOptionsManager:getModOptionsValue("witchyAutomate", "overrideAutoRole")
              uiStandardButton:setDisabled(autoRoleAssignmentToggleButton, overrideAutoRoles)
]]
		},  
        [3] = { type = "insertAfter", after = {"function taskTreeUI:show()", "if not complete then", "else"}, string = 
        [[if overrideAutoRoles and automatedRoles:getSkillSettings()[skillTypeIndex].automationEnabled then
            backgroundMaterialTable = {
                default = material.types.ui_background_blue.index
            }
        else]]}
    }
}

return patch