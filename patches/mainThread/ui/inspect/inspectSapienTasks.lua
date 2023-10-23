local patch = {
    operations = {
        [1] = { type = "insertAfter", after = "local function getBackgroundMateral(complete, priorityLevel, limitedAbility", string = ", automationEnabled" }, 
        [2] = { type = "insertAfter", after = {"local function getBackgroundMateral", "if complete then", "\r\n"}, string = "				if automationEnabled then return material.types.ui_background_blue.index end" }, 
        [3] = { type = "insertAfter", after = "local function updateButton(viewInfo, disabled, complete, priorityLevel", string = ", automationEnabled" }, 
        [4] = { type = "insertAfter", after = {"local function updateButton(viewInfo, disabled, complete, priorityLevel", "uiStandardButton:setDisabled(viewInfo.backgroundView, disabled"}, string = " or automationEnabled" }, 
        [5] = { type = "insertAfter", after = {"local function updateButton", "default = getBackgroundMateral(complete, priorityLevel, viewInfo.limitedAbility"}, string = " or automationEnabled" }, 
        [6] = { type = "insertAfter", after = {"local function updateDisabledStateForAllSkillsForChangedPriority()", "local oldDisabled = backgroundView.userData.disabled", "\r\n" }, string = "						local automationEnabled = automatedRoles:getSkillSettings()[skillTypeIndex].automationEnabled\r\n" },
        [7] = { type = "insertBefore", before = {"local function updateDisabledStateForAllSkillsForChangedPriority()", "if complete then", "if canAssignTasks"}, string = "if automationEnabled then\r\n								newDisabled = true\r\n							else" }, 
        [8] = { type = "insertAfter", after = {"local function updateDisabledStateForAllSkillsForChangedPriority()", "updateButton(viewInfo, newDisabled, complete, priorityLevel"}, string = ", automationEnabled" }, 
        [9] = { type = "insertAfter", after = {"for i,skillColumn in ipairs(roleUICommon.skillUIColumns) do", "local complete = true", "\r\n"}, string = "                local automationEnabled = automatedRoles:getSkillSettings()[skillTypeIndex].automationEnabled" }, 
        [10] = { type = "insertAfter", after = {"local backgroundView = uiStandardButton:create", "getBackgroundMateral(complete, priorityLevel, limitedAbility"}, string = ", automationEnabled" }, 
        [11] = { type = "insertAfter", after = {"local function updateForChangedPriority()", "getBackgroundMateral(complete, priorityLevel, limitedAbility"}, string = ", automationEnabled" }, 
        [12] = { type = "insertAfter", after = "updateButton(viewInfo, (not complete) or ((not canAssignTasks) and priorityLevel ~= 1), complete, priorityLevel", string = ", automationEnabled" },
        [13] = { type = "insertBefore", before = "local inspectSapienTasks =", string = "local automatedRoles = mjrequire \"automate/automatedRoles\"\r\n" },
    }
}

return patch