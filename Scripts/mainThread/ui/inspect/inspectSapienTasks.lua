local mod = {}

local mjm = mjrequire "common/mjm"
local vec3 = mjm.vec3
local vec2 = mjm.vec2
local vec4 = mjm.vec4

local skill = mjrequire "common/skill"
local research = mjrequire "common/research"
local model = mjrequire "common/model"
local material = mjrequire "common/material"
local sapienConstants = mjrequire "common/sapienConstants"
local locale = mjrequire "common/locale"
local sapienTrait = mjrequire "common/sapienTrait"

local playerSapiens = mjrequire "mainThread/playerSapiens"
local tutorialUI = mjrequire "mainThread/ui/tutorialUI"

local uiCommon = mjrequire "mainThread/ui/uiCommon/uiCommon"
local uiStandardButton = mjrequire "mainThread/ui/uiCommon/uiStandardButton"

local roleUICommon = mjrequire "mainThread/ui/roleUICommon"
local uiHorizontalScrollView = mjrequire "mainThread/ui/uiCommon/uiHorizontalScrollView"
local uiToolTip = mjrequire "mainThread/ui/uiCommon/uiToolTip"

local automatedRoles = mjrequire "automatedRoles/automatedRoles"

local world = nil
local inspectUI = nil

local mainView = nil
local insetView = nil
local scrollView = nil

local backFunction = nil

local countTextView = nil

local function setBackFunction(backFunction_)
    backFunction = backFunction_
end

local function init(inspectUI_, inspectFollowerUI_, world_, containerView)
    inspectUI = inspectUI_
    world = world_
	
	automatedRoles:init(world)

    mainView = View.new(containerView)
    mainView.size = vec2(containerView.size.x - 20, containerView.size.y - 40 - 30)
    mainView.relativePosition = ViewPosition(MJPositionCenter, MJPositionTop)
    mainView.baseOffset = vec3(0,-20 - 40, 0)

    local insetViewSize = mainView.size

    insetView = ModelView.new(mainView)
    insetView:setModel(model:modelIndexForName("ui_inset_lg_4x3"))
    local scaleToUsePaneX = insetViewSize.x * 0.5
    local scaleToUsePaneY = insetViewSize.y * 0.5 / 0.75
    insetView.scale3D = vec3(scaleToUsePaneX,scaleToUsePaneY,scaleToUsePaneX)
    insetView.size = insetViewSize
    
    local scrollViewSize = vec2(insetViewSize.x - 14, insetViewSize.y - 14)
    scrollView = uiHorizontalScrollView:create(insetView, scrollViewSize)

    local connectionsBackgroundView = View.new(scrollView)
    connectionsBackgroundView.size = scrollView.size
    roleUICommon:constructBackgroundConnections(connectionsBackgroundView)
    uiHorizontalScrollView:addBackgroundView(scrollView, connectionsBackgroundView)

    
    local backButton = uiStandardButton:create(mainView, vec2(50,50), uiStandardButton.types.markerLike)
    backButton.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
    backButton.baseOffset = vec3(0, 56, 0)
    uiStandardButton:setIconModel(backButton, "icon_back")
    uiStandardButton:setClickFunction(backButton, function()
        if backFunction then
            backFunction()
        end
    end)

    
    countTextView = ModelTextView.new(mainView)
    countTextView.font = Font(uiCommon.titleFontName, 36)
    countTextView.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionCenter)
    countTextView.relativeView = inspectUI.modalPanelTitleTextView

end


local taskBackgroundSize = roleUICommon.plinthSize

local viewInfosBySkillTypeIndex = {}
local columnViews = {}

local function show(sapien)
    local sharedState = sapien.sharedState
    local sapienName = sharedState.name

    local assignedCount = skill:getAssignedRolesCount(sapien)
    local canAssignTasks = assignedCount < skill.maxRoles
    

    inspectUI:setModalPanelTitleAndObject(sapienName .. " - " .. locale:get("sapien_ui_roles"), sapien)

    local function updateTaskCountText()
        local text = string.format(" (%d/%d)", assignedCount, skill.maxRoles)
        if canAssignTasks then
            countTextView:setText(text, material.types.standardText.index)
        else
            countTextView:setText(text, material.types.warning.index)
        end
    end

    updateTaskCountText()
    

    local function getBackgroundMateral(complete, priorityLevel, limitedAbility, automationEnabled)
        if complete then
			if automationEnabled then
				return material.types.ui_background_blue.index
			end
            if priorityLevel == 1 then
                if limitedAbility then
                    return material.types.ui_background_warning_disabled.index
                end
                return material.types.ui_background_green.index
            end
        end
        return material.types.ui_background.index
    end

    local function getBackgroundDisabledMateral(complete, priorityLevel, limitedAbility)
        if complete then
            if priorityLevel == 1 then
                return material.types.ui_disabled_green.index
            end
        end
        return material.types.ui_disabled.index
    end

    local function updateButton(viewInfo, disabled, complete, priorityLevel, automationEnabled)
        uiStandardButton:setDisabled(viewInfo.backgroundView, disabled or automationEnabled)
        local materialTable = nil
        if disabled then
            materialTable = {
                default = material.types.ui_background_inset.index,
            }
        else
            materialTable = {
                default = getBackgroundMateral(complete, priorityLevel, viewInfo.limitedAbility, automationEnabled),
            }
        end
        uiStandardButton:reloadBackgroundModelView(viewInfo.backgroundView, materialTable)
        
        if disabled then
            viewInfo.backgroundView.baseOffset = vec3(roleUICommon.plinthInitialXOffset, viewInfo.yOffset, -1)
        else
            viewInfo.backgroundView.baseOffset = vec3(roleUICommon.plinthInitialXOffset, viewInfo.yOffset, 4)
        end
        
        if not disabled then 
            if viewInfo.limitedAbility then
                viewInfo.titleTextView.color = material:getUIColor(material.types.warning.index)
            else
                viewInfo.titleTextView.color = mj.textColor
            end
        else
            viewInfo.titleTextView.color = vec4(1.0,1.0,1.0,0.3)
        end
        
        if not disabled then
            if viewInfo.limitedAbility then
                viewInfo.icon:setModel(model:modelIndexForName(skill.types[viewInfo.skillTypeIndex].icon), {
                    default = material.types.warning.index
                })
            else
                viewInfo.icon:setModel(model:modelIndexForName(skill.types[viewInfo.skillTypeIndex].icon))
            end
        else
            if not viewInfo.visible then
                viewInfo.icon:setModel(model:modelIndexForName("icon_lock"), {
                    default = material.types.ui_disabled.index
                })
            else
                viewInfo.icon:setModel(model:modelIndexForName(skill.types[viewInfo.skillTypeIndex].icon), {
                    default = material.types.ui_disabled.index
                })
            end
        end

        
        if viewInfo.allowCountTextView then
            if viewInfo.allowCount == 0 or disabled then
                viewInfo.allowCountTextView.color = vec4(0.4,0.4,0.4,0.6)
            elseif viewInfo.limitedAbility then
                viewInfo.allowCountTextView.color = material:getUIColor(material.types.warning.index)
            else
                viewInfo.allowCountTextView.color = mj.textColor
            end
            
            local materialIndex = material.types.ui_standard.index
            if viewInfo.allowCount == 0 or disabled then
                materialIndex = material.types.ui_disabled.index
            elseif viewInfo.limitedAbility then
                materialIndex = material.types.warning.index
            end
            viewInfo.allowIcon:setModel(model:modelIndexForName("icon_tick"), {
                default = materialIndex
            })
        end

        if viewInfo.toolTipAdded then
            uiToolTip:updateText(viewInfo.backgroundView.userData.backgroundView, skill.types[viewInfo.skillTypeIndex].description, nil, disabled)

            if viewInfo.skilledText then
                uiToolTip:addColoredDescriptionText(viewInfo.backgroundView.userData.backgroundView, viewInfo.skilledText, mj.highlightColor)
            end
            
            if viewInfo.positiveTraitsText then
                uiToolTip:addColoredDescriptionText(viewInfo.backgroundView.userData.backgroundView, viewInfo.positiveTraitsText, vec4(0.4,0.8,0.4,1.0))
            end
            
            if viewInfo.negativeTraitsText then
                uiToolTip:addColoredDescriptionText(viewInfo.backgroundView.userData.backgroundView, viewInfo.negativeTraitsText, vec4(0.8,0.4,0.4,1.0))
            end

            if viewInfo.limitedAbility then
                uiToolTip:addColoredDescriptionText(viewInfo.backgroundView.userData.backgroundView, viewInfo.limitedAbilityText, material:getUIColor(material.types.warning.index))
            end

        end
    end

    local function updateDisabledStateForAllSkillsForChangedPriority()
        local sapienInfo = playerSapiens:getInfo(sapien.uniqueID)
        if sapienInfo then
            local newAssignedCount = skill:getAssignedRolesCount(sapienInfo)
            if newAssignedCount ~= assignedCount then
                assignedCount = newAssignedCount
                local newCanAssignTasks = assignedCount < skill.maxRoles
                if newCanAssignTasks ~= canAssignTasks then
                    canAssignTasks = newCanAssignTasks
                    
                    for skillTypeIndex, viewInfo in pairs(viewInfosBySkillTypeIndex) do
                        local backgroundView = viewInfo.backgroundView
                        local complete = true
                        local researchType = research.researchTypesBySkillType[skillTypeIndex]
                        if researchType then
                            local discoveryStatus = world:discoveryInfoForResearchTypeIndex(researchType.index)
                            complete = discoveryStatus and discoveryStatus.complete
                        end

                        local priorityLevel = skill:priorityLevel(sapienInfo, skillTypeIndex)
                        local newDisabled = false
                        local oldDisabled = backgroundView.userData.disabled
						local automationEnabled = automatedRoles:getSkillSettings()[skillTypeIndex].automationEnabled
						
                        if complete then
							if automationEnabled then
								newDisabled = true
							elseif canAssignTasks or priorityLevel == 1 then
                                newDisabled = false
                            else
                                newDisabled = true
                            end
                        else
                            newDisabled = true
                        end				

                        if newDisabled ~= oldDisabled then
                            updateButton(viewInfo, newDisabled, complete, priorityLevel, automationEnabled)
                        end
                    end
                end
                updateTaskCountText()
            end
        end
    end

    for i,skillColumn in ipairs(roleUICommon.skillUIColumns) do

        local columnView = columnViews[i]
        if not columnView then
            columnView = View.new(scrollView)
            columnView.size = vec2(taskBackgroundSize.x + roleUICommon.plinthPadding.x, scrollView.size.y)
            uiHorizontalScrollView:insertColumn(scrollView, columnView)
            columnViews[i] = columnView
        end

        local yOffset = roleUICommon.plinthInitialYOffset
        if i % 2 == 0 then
            yOffset = yOffset - (taskBackgroundSize.y) / 2 - roleUICommon.plinthPadding.y / 2
        end
        for j,skillUIInfo in ipairs(skillColumn) do
            local skillTypeIndex = skillUIInfo.skillTypeIndex
            if skillTypeIndex then
                if viewInfosBySkillTypeIndex[skillTypeIndex] then
                    columnView:removeSubview(viewInfosBySkillTypeIndex[skillTypeIndex].backgroundView)
                end

                local automationEnabled = automatedRoles:getSkillSettings()[skillTypeIndex].automationEnabled
                local complete = true
                local researchType = research.researchTypesBySkillType[skillTypeIndex]
                if researchType then
                    local discoveryStatus = world:discoveryInfoForResearchTypeIndex(researchType.index)
                    complete = discoveryStatus and discoveryStatus.complete
                end
                    
                local priorityLevel = skill:priorityLevel(sapien, skillTypeIndex)
                local limitedAbility = nil
                local limitedAbilityIsPartial = false
                
                if skill.types[skillTypeIndex].noCapacityWithLimitedGeneralAbility or skill.types[skillTypeIndex].partialCapacityWithLimitedGeneralAbility then
                    if sapienConstants:getHasLimitedGeneralAbility(sharedState) then
                        limitedAbility = true
                        if not skill.types[skillTypeIndex].noCapacityWithLimitedGeneralAbility then
                            limitedAbilityIsPartial = true
                        end
                    end
                end

                local visible = complete
                if not visible then
                    local requiredSkillTypes = skillUIInfo.requiredSkillTypes
                    local allComplete = true
                    local anyComplete = false
                    if requiredSkillTypes then
                        for k,requiredSkillTypeIndex in ipairs(requiredSkillTypes) do
                            
                            local thisComplete = true
                            local thisResearchType = research.researchTypesBySkillType[requiredSkillTypeIndex]
                            if thisResearchType then
                                local discoveryStatus = world:discoveryInfoForResearchTypeIndex(thisResearchType.index)
                                thisComplete = discoveryStatus and discoveryStatus.complete
                            end

                            if (not thisComplete) then
                                allComplete = false
                            else
                                anyComplete = true
                            end
                        end
                    end
                    if allComplete then
                        visible = true
                    elseif skillUIInfo.onlyRequiresSingleSkillUnlocked and anyComplete then
                        visible = true
                    end
                end
                
                local backgroundView = uiStandardButton:create(columnView, taskBackgroundSize, uiStandardButton.types.slim_4x1, {
                    default = getBackgroundMateral(complete, priorityLevel, limitedAbility, automationEnabled),
                })

                local viewInfo = {
                    skillTypeIndex = skillTypeIndex,
                    backgroundView = backgroundView,
                    yOffset = yOffset,
                    visible = visible,
                    limitedAbility = limitedAbility,
                }
                viewInfosBySkillTypeIndex[skillTypeIndex] = viewInfo
                backgroundView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)

                local priorityIcon = nil

                local function createPriroityIconIfNeeded()
                    if not priorityIcon then
                        priorityIcon = ModelView.new(backgroundView)
                        priorityIcon.masksEvents = false
                        priorityIcon.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionTop)
                        priorityIcon.baseOffset = vec3(-4, -4, 1)
                        local priorityIconHalfSize = 7
                        priorityIcon.scale3D = vec3(priorityIconHalfSize,priorityIconHalfSize,priorityIconHalfSize)
                        priorityIcon.size = vec2(priorityIconHalfSize,priorityIconHalfSize) * 2.0
                    end
                end

                local function setPriorityIconModel()
                    if priorityLevel == 1 then
                        createPriroityIconIfNeeded()
                        priorityIcon.hidden = false
                        priorityIcon:setModel(model:modelIndexForName("icon_tick"), {
                            default = material.types.ui_green.index
                        })
                    elseif priorityIcon then
                        priorityIcon.hidden = true
                    end
                end

                local skillAchievementBackgroundIcon = nil

                local allowIcon = nil
                local allowCountTextView = nil

                local function updateForChangedPriority()
                    local materialTable = {
                        default = getBackgroundMateral(complete, priorityLevel, limitedAbility, automationEnabled),
                    }
                    uiStandardButton:reloadBackgroundModelView(backgroundView, materialTable)
                    setPriorityIconModel()
                    if skillAchievementBackgroundIcon then
                        skillAchievementBackgroundIcon:setModel(model:modelIndexForName("icon_circle_filled"), {
                            default = getBackgroundDisabledMateral(complete, priorityLevel, limitedAbility),
                        })
                    end
                    updateDisabledStateForAllSkillsForChangedPriority()

                    if allowIcon then
                        local allowCount = playerSapiens:getCountForSkillTypeAndPriority(skillTypeIndex, 1)
                        viewInfo.allowCount = allowCount
                        
                        local materialIndex = material.types.ui_standard.index
                        if allowCount == 0 then
                            materialIndex = material.types.ui_disabled.index
                        elseif limitedAbility then
                            materialIndex = material.types.warning.index
                        end
                        allowIcon:setModel(model:modelIndexForName("icon_tick"), {
                            default = materialIndex
                        })

                        if allowCount == 0 then
                            allowCountTextView.color = vec4(0.4,0.4,0.4,0.6)
                        elseif viewInfo.limitedAbility then
                            allowCountTextView.color = material:getUIColor(material.types.warning.index)
                        else
                            allowCountTextView.color = mj.textColor
                        end

                        allowCountTextView.text = mj:tostring(allowCount)

                    end
                end

                local clickFunction = function()
                    local newPriority = 1
                    if priorityLevel ~= 1 then
                        newPriority = 1
                    else
                        newPriority = 0
                    end
                    playerSapiens:setSkillPriority(sapien.uniqueID, skillTypeIndex, newPriority)
                    if newPriority == 1 then
                        tutorialUI:roleAssignmentWasIssued()
                    end
                    priorityLevel = newPriority
                    updateForChangedPriority()
                end

                
                uiStandardButton:setClickFunction(backgroundView, clickFunction)

                local traitInfluenceInfo = sapienTrait:getSkillInfluenceWithTraitsList(sapien.sharedState.traits, skillTypeIndex)

                if complete then
                    
                    if canAssignTasks or priorityLevel == 1 then
                        uiStandardButton:setDisabled(backgroundView, false)
                        uiStandardButton:setClickFunction(backgroundView, clickFunction)
                    else
                        uiStandardButton:setDisabled(backgroundView, true)
                    end
                    viewInfo.toolTipAdded = true
                    uiToolTip:add(backgroundView.userData.backgroundView, ViewPosition(MJPositionCenter, MJPositionBelow), skill.types[skillTypeIndex].description, nil, vec3(0,-8,10), nil, backgroundView, scrollView)

                    
                    if skill:hasSkill(sapien, skillTypeIndex) then
                        local traitText = locale:get("misc_skilled")
                        if #traitInfluenceInfo.positiveTraits > 0 or #traitInfluenceInfo.negativeTraits > 0 or limitedAbility then
                            traitText = traitText .. ", "
                        end
                        viewInfo.skilledText = traitText
                        uiToolTip:addColoredDescriptionText(backgroundView.userData.backgroundView, traitText, mj.highlightColor)
                    end
        
                    for k, traitInfo in ipairs(traitInfluenceInfo.positiveTraits) do
                        local traitType = sapienTrait.types[traitInfo.traitTypeIndex]
                        local traitText = nil
                        if traitInfo.opposite then
                            traitText = traitType.opposite
                        else
                            traitText = traitType.name
                        end
                        if k < #traitInfluenceInfo.positiveTraits or #traitInfluenceInfo.negativeTraits > 0 or limitedAbility then
                            traitText = traitText .. ", "
                        end
                        viewInfo.positiveTraitsText = traitText
                        uiToolTip:addColoredDescriptionText(backgroundView.userData.backgroundView, traitText, vec4(0.4,0.8,0.4,1.0))
                    end
                    for k, traitInfo in ipairs(traitInfluenceInfo.negativeTraits) do
                        local traitType = sapienTrait.types[traitInfo.traitTypeIndex]
                        local traitText = nil
                        if traitInfo.opposite then
                            traitText = traitType.opposite
                        else
                            traitText = traitType.name
                        end
                        if k < #traitInfluenceInfo.negativeTraits or limitedAbility then
                            traitText = traitText .. ", "
                        end
                        viewInfo.negativeTraitsText = traitText
                        uiToolTip:addColoredDescriptionText(backgroundView.userData.backgroundView, traitText, vec4(0.8,0.4,0.4,1.0))
                    end

                    if limitedAbility then
                        local limitedAbilityText = skill:getLimitedAbilityReason(sharedState, limitedAbilityIsPartial)
                        viewInfo.limitedAbilityText = limitedAbilityText
                        uiToolTip:addColoredDescriptionText(backgroundView.userData.backgroundView, limitedAbilityText, material:getUIColor(material.types.warning.index))
                    end

                else
                    uiStandardButton:setDisabled(backgroundView, true)
                end

                local icon = nil
                if visible then
                    icon = ModelView.new(backgroundView)
                    icon.masksEvents = false
                    if complete then
                        if limitedAbility then
                            icon:setModel(model:modelIndexForName(skill.types[skillTypeIndex].icon), {
                                default = material.types.warning.index
                            })
                        else
                            icon:setModel(model:modelIndexForName(skill.types[skillTypeIndex].icon))
                        end
                    else
                        icon:setModel(model:modelIndexForName(skill.types[skillTypeIndex].icon), {
                            default = material.types.ui_disabled.index
                        })
                    end
                    icon.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
                    icon.baseOffset = vec3(4, 0, 1)
                    local iconHalfSize = 14
                    icon.scale3D = vec3(iconHalfSize,iconHalfSize,iconHalfSize)
                    icon.size = vec2(iconHalfSize,iconHalfSize) * 2.0
                else
                    icon = ModelView.new(backgroundView)
                    icon.masksEvents = false
                    icon:setModel(model:modelIndexForName("icon_lock"), {
                        default = material.types.ui_disabled.index
                    })
                    icon.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
                    icon.baseOffset = vec3(4, 0, 1)
                    local iconHalfSize = 14
                    icon.scale3D = vec3(iconHalfSize,iconHalfSize,iconHalfSize)
                    icon.size = vec2(iconHalfSize,iconHalfSize) * 2.0
                end

                viewInfo.icon = icon


                if complete then
                    setPriorityIconModel()

                    local allowCount = playerSapiens:getCountForSkillTypeAndPriority(skillTypeIndex, 1)
                    
                    local iconHalfSize = 6
                    
                    allowIcon = ModelView.new(backgroundView)
                    viewInfo.allowIcon = allowIcon
                    allowIcon.masksEvents = false
                    local materialIndex = material.types.ui_standard.index
                    if allowCount == 0 then
                        materialIndex = material.types.ui_disabled.index
                    elseif limitedAbility then
                        materialIndex = material.types.warning.index
                    end
                    allowIcon:setModel(model:modelIndexForName("icon_tick"), {
                        default = materialIndex
                    })
                    allowIcon.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionBottom)
                    allowIcon.baseOffset = vec3(38, 4, 1)
                    allowIcon.scale3D = vec3(iconHalfSize,iconHalfSize,iconHalfSize)
                    allowIcon.size = vec2(iconHalfSize,iconHalfSize) * 2.0

                    allowCountTextView = TextView.new(backgroundView)
                    viewInfo.allowCountTextView = allowCountTextView
                    viewInfo.allowCount = allowCount
                    allowCountTextView.masksEvents = false
                    allowCountTextView.font = Font(uiCommon.fontName, 14)
                    allowCountTextView.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionCenter)
                    allowCountTextView.relativeView = allowIcon
                    allowCountTextView.baseOffset = vec3(1,-1, 0)
                    if allowCount == 0 then
                        allowCountTextView.color = vec4(0.4,0.4,0.4,0.6)
                    elseif limitedAbility then
                        allowCountTextView.color = material:getUIColor(material.types.warning.index)
                    else
                        allowCountTextView.color = mj.textColor
                    end
                    allowCountTextView.text = mj:tostring(allowCount)
                end

                local skillAchievementIcon = nil
                local skillAchievementIconHalfSize = 7

                if skill:learnStarted(sapien, skillTypeIndex) then
                    skillAchievementIcon = ModelView.new(backgroundView)
                    skillAchievementIcon.masksEvents = false
                    skillAchievementIcon.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionBottom)
                    skillAchievementIcon.baseOffset = vec3(-6, 4, 1)
                    skillAchievementIcon.scale3D = vec3(skillAchievementIconHalfSize,skillAchievementIconHalfSize,skillAchievementIconHalfSize)
                    skillAchievementIcon.size = vec2(skillAchievementIconHalfSize,skillAchievementIconHalfSize) * 2.0
                    
                    if skill:hasSkill(sapien, skillTypeIndex) then
                        skillAchievementBackgroundIcon = nil
                        skillAchievementIcon:setModel(model:modelIndexForName("icon_achievement"), {
                            default = material.types.ui_selected.index
                        })
                    else
                        skillAchievementBackgroundIcon = skillAchievementIcon
                        skillAchievementIcon:setModel(model:modelIndexForName("icon_circle_filled"), {
                            default = material.types.ui_disabled.index
                        })

                        
                        local skillAchievementProgressIcon = ModelView.new(backgroundView)
                        skillAchievementProgressIcon.masksEvents = false
                        skillAchievementProgressIcon.relativeView = skillAchievementIcon
                        skillAchievementProgressIcon.baseOffset = vec3(0, 0, 2)
                        skillAchievementProgressIcon.scale3D = vec3(skillAchievementIconHalfSize,skillAchievementIconHalfSize,skillAchievementIconHalfSize)
                        skillAchievementProgressIcon.size = vec2(skillAchievementIconHalfSize,skillAchievementIconHalfSize) * 2.0

                        skillAchievementProgressIcon:setModel(model:modelIndexForName("icon_circle_thic"), {
                            default = material.types.ui_selected.index
                        })
                        skillAchievementProgressIcon:setRadialMaskFraction(skill:fractionLearned(sapien, skillTypeIndex))

                    end
                end 
                
                    
                if traitInfluenceInfo.influence ~= 0 then
                    local traitText = nil
                    local color = nil
                    if traitInfluenceInfo.influence > 0 then
                        if traitInfluenceInfo.influence > 1.1 then
                            traitText = "++"
                            color = vec4(0.4,0.8,0.4,1.0)
                        else
                            traitText = "+"
                            color = vec4(0.4,0.8,0.4,1.0)
                        end
                    else
                        if traitInfluenceInfo.influence < -1.1 then
                            traitText = "--"
                            color = vec4(0.8,0.4,0.4,1.0)
                        else
                            traitText = "-"
                            color = vec4(0.8,0.4,0.4,1.0)
                        end
                    end
                    local traitInfluenceTextView = TextView.new(backgroundView)
                    traitInfluenceTextView.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionBottom)

                    if skillAchievementIcon then
                        traitInfluenceTextView.baseOffset = vec3(-8 - skillAchievementIconHalfSize * 2 - 2, -6, 1)
                    else
                        traitInfluenceTextView.baseOffset = vec3(-8, -6, 1)
                    end
                    traitInfluenceTextView.font = Font(uiCommon.fontName, 22)
                    traitInfluenceTextView.color = color
                    traitInfluenceTextView.text = traitText
                end

                local titleTextView = TextView.new(backgroundView)
                viewInfo.titleTextView = titleTextView
                titleTextView.masksEvents = false
                titleTextView.font = Font(uiCommon.fontName, 14)
                titleTextView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
                titleTextView.baseOffset = vec3(36,-6, 0)
                if visible then
                    titleTextView.text = skill.types[skillTypeIndex].name
                else
                    titleTextView.text = "???"
                end
                if complete then 
                    if viewInfo.limitedAbility then
                        viewInfo.titleTextView.color = material:getUIColor(material.types.warning.index)
                    else
                        viewInfo.titleTextView.color = mj.textColor
                    end
                else
                    titleTextView.color = vec4(1.0,1.0,1.0,0.3)
                end
                
                updateButton(viewInfo, (not complete) or ((not canAssignTasks) and priorityLevel ~= 1), complete, priorityLevel, automationEnabled)
            end

            yOffset = yOffset - taskBackgroundSize.y - roleUICommon.plinthPadding.y
        end
    end

end

function mod:onload(inspectSapienTasks)

	inspectSapienTasks.setBackFunction = function(inspectSapienTasks_, backFunction_)
		setBackFunction(backFunction_)
	end
	
	inspectSapienTasks.init = function(inspectSapienTasks_, inspectUI_, inspectFollowerUI_, world_, containerView)
		init(inspectUI_, inspectFollowerUI_, world_, containerView)
	end
	
	inspectSapienTasks.show = function(inspectSapienTasks_, sapien)
		show(sapien)
	end
end

return mod