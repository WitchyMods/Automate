local patch = {
	debugCopyAfter = true,
    operations = {
		[1] = { type = "insertAfter", after = "local uiToolTip = mjrequire \"mainThread/ui/uiCommon/uiToolTip\"", string = "\r\nlocal modOptionsManager = mjrequire \"hammerstone/options/modOptionsManager\"\r\n"}, 
        [2] = { type = "insertAfter", after = "uiStandardButton:setToggleState(autoRoleAssignmentToggleButton, world:getAutoRoleAssignmentEnabled())\r\n", string = "        uiStandardButton:setDisabled(autoRoleAssignmentToggleButton, modOptionsManager:getModOptionsValue(\"witchyAutomate\", \"overrideAutoRole\"))\r\n" }, 
    }
}

return patch