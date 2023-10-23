local patch = {
    operations = {
        [1] = { type = "insertBefore", before = "local taskTreeUI = {}", string = "local automatedRoles = mjrequire \"automate/automatedRoles\"\r\n" }, 
        [2] = { type = "insertAfter", after = {"function taskTreeUI:show()", "local backgroundMaterialTable = nil"}, string = "				local skillSetting = automatedRoles:getSkillSettings()[skillTypeIndex]" }, 
        [3] = { type = "insertAfter", after = {"function taskTreeUI:show()", "if not complete then", "else"}, string = [[if skillSetting.automationEnabled then
            backgroundMaterialTable = {
                default = material.types.ui_background_blue.index
            }
        else]]}
    }
}

return patch