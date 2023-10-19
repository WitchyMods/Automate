local mjm = mjrequire "common/mjm"
local vec3 = mjm.vec3
local vec2 = mjm.vec2
local vec4 = mjm.vec4

local skill = mjrequire "common/skill"
local model = mjrequire "common/model"
local material = mjrequire "common/material"
local locale = mjrequire "common/locale"
local sapienConstants = mjrequire "common/sapienConstants"

local playerSapiens = mjrequire "mainThread/playerSapiens"

local uiAnimation = mjrequire "mainThread/ui/uiAnimation"
local uiCommon = mjrequire "mainThread/ui/uiCommon/uiCommon"
local uiScrollView = mjrequire "mainThread/ui/uiCommon/uiScrollView"
local uiStandardButton = mjrequire "mainThread/ui/uiCommon/uiStandardButton"
local sapienTrait = mjrequire "common/sapienTrait"
local uiToolTip = mjrequire "mainThread/ui/uiCommon/uiToolTip"
local tutorialUI = mjrequire "mainThread/ui/tutorialUI"

local automatedRoles = mjrequire "automatedRoles/automatedRoles"

local taskAssignUI = {}
local mainView = nil
local insetViewInfos = {}

local skillTypeIndex = nil
local roleUI = nil
local gameUI = nil
local manageUI = nil
local hubUI = nil
local taskTreeUI = nil
local automatedRolesUI = nil

local titleView = nil
local titleIcon = nil
local titleTextView = nil

local iconHalfSize = 14
local iconPadding = 6

local normalView = nil
local automatedView = nil

function taskAssignUI:init(roleUI_, gameUI_, world_, manageUI_, hubUI_, automatedRolesUI_, taskTreeUI_, contentView)
    roleUI = roleUI_
    gameUI = gameUI_
    manageUI = manageUI_
    hubUI = hubUI_
	taskTreeUI = taskTreeUI_
	automatedRolesUI = automatedRolesUI_

    mainView = View.new(contentView)
    mainView.size = vec2(contentView.size.x - 20, contentView.size.y - 20)
    mainView.relativePosition = ViewPosition(MJPositionCenter, MJPositionTop)
    mainView.baseOffset = vec3(0,-10, 0)
    mainView.hidden = true    

    titleView = View.new(mainView)
    titleView.relativePosition = ViewPosition(MJPositionCenter, MJPositionTop)
    titleView.baseOffset = vec3(0,-5, 0)
    titleView.size = vec2(200, 32.0)
    
    titleIcon = ModelView.new(titleView)
    titleIcon.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
    titleIcon.scale3D = vec3(iconHalfSize,iconHalfSize,iconHalfSize)
    titleIcon.size = vec2(iconHalfSize,iconHalfSize) * 2.0
    titleIcon:setModel(model:modelIndexForName("icon_tribe2"))

    titleTextView = ModelTextView.new(titleView)
    titleTextView.font = Font(uiCommon.titleFontName, 36)
    titleTextView.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionCenter)
    titleTextView.relativeView = titleIcon
    titleTextView.baseOffset = vec3(iconPadding, 0, 0)

    
    local backButton = uiStandardButton:create(mainView, vec2(50,50), uiStandardButton.types.markerLike)
    backButton.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionTop)
    backButton.baseOffset = vec3(0, 0, 0)
    uiStandardButton:setIconModel(backButton, "icon_back")
    uiStandardButton:setClickFunction(backButton, function()
        manageUI_:show(manageUI_.modeTypes.task)
    end)
		
	local automateButton = uiStandardButton:create(mainView, vec2(50,50), uiStandardButton.types.markerLike)
    automateButton.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
    automateButton.baseOffset = vec3(0, 0, 0)
    uiStandardButton:setIconModel(automateButton, "icon_logistics")
    uiStandardButton:setClickFunction(automateButton, function()
        taskTreeUI:hide()
		taskAssignUI:hide()
		automatedRolesUI:show(skillTypeIndex)
    end)
	
	normalView = View.new(mainView)
	normalView.size = mainView.size
	normalView.relativePosition = mainView.relativePosition
	normalView.baseOffset = mainView.baseOffset
	normalView.hidden = true 
	
	automatedView = View.new(mainView)
	automatedView.size = mainView.size
	automatedView.relativePosition = mainView.relativePosition
	automatedView.baseOffset = mainView.baseOffset
	automatedView.hidden = true 

	local automatedViewText = TextView.new(automatedView)
	automatedViewText.relativePosition = ViewPosition(MJPositionCenter, MJPositionCenter)
	automatedViewText.font = Font(uiCommon.fontName, 22)
	automatedViewText.color = mj.textColor
	automatedViewText.text = "This role is automated"

    local insetViewSize = vec2((normalView.size.x - 20) / 2, normalView.size.y - 60)
    local scrollViewSize = vec2(insetViewSize.x - 10, insetViewSize.y - 10)

    for i=1,2 do

        local insetView = ModelView.new(normalView)
        insetView:setModel(model:modelIndexForName("ui_inset_lg_2x3"))
        local scaleToUsePaneX = insetViewSize.x * 0.5 / (2.0/3.0)
        local scaleToUsePaneY = insetViewSize.y * 0.5
        insetView.scale3D = vec3(scaleToUsePaneX,scaleToUsePaneY,scaleToUsePaneX)
        insetView.size = insetViewSize
        insetView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionBottom)
        insetView.baseOffset = vec3((i - 1) * (insetViewSize.x + 20),0,0)


        local scrollView = uiScrollView:create(insetView, scrollViewSize, MJPositionInnerLeft)
        scrollView.baseOffset = vec3(0,0,2)
        
        insetViewInfos[i] = {
            insetView = insetView,
            scrollView = scrollView,
            sapienViewinfos = {}
        }
    end

    local headerIconHalfSize = 8
    local iconTitlePadding = 4

    local headerViews = {}

    local function addTitle(viewInfoIndex, titleText, textColor,  iconName, iconMaterial)
    
        local headerView = View.new(normalView)
        headerView.relativePosition = ViewPosition(MJPositionCenter, MJPositionAbove)
        headerView.relativeView = insetViewInfos[viewInfoIndex].insetView
        headerView.baseOffset = vec3(0,3,0)
    
        local iconView = ModelView.new(headerView)
        iconView:setModel(model:modelIndexForName(iconName), {
            default = iconMaterial
        })
        iconView.scale3D = vec3(headerIconHalfSize,headerIconHalfSize,headerIconHalfSize)
        iconView.size = vec2(headerIconHalfSize) * 2.0
        iconView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
    
        local thisTitleTextView = TextView.new(headerView)
        thisTitleTextView.font = Font(uiCommon.fontName, 18)
        thisTitleTextView.color = textColor
        thisTitleTextView.text = titleText
        thisTitleTextView.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionCenter)
        thisTitleTextView.relativeView = iconView
        thisTitleTextView.baseOffset = vec3(iconTitlePadding,-1,0)
    
        headerView.size = vec2(headerIconHalfSize * 2.0 + iconTitlePadding + thisTitleTextView.size.x, 20.0)

        headerViews[viewInfoIndex] = headerView
    end
    

    addTitle(1, locale:get("ui_roles_allowed"), vec4(0.5,1.0,0.5,1.0), "icon_tick", material.types.ui_green.index)
    addTitle(2, locale:get("ui_roles_disallowed"), vec4(1.0,0.5,0.5,1.0), "icon_cancel_thic", material.types.ui_red.index)

    local moveAllButtonSize = 24.0
    local moveAllButtonA = uiStandardButton:create(normalView, vec2(moveAllButtonSize,moveAllButtonSize), uiStandardButton.types.slim_1x1)
    moveAllButtonA.relativePosition = ViewPosition(MJPositionOuterLeft, MJPositionCenter)
    moveAllButtonA.relativeView = headerViews[2]
    uiStandardButton:setIconModel(moveAllButtonA, "icon_doubleArrowLeft", {
        default = material.types.ui_green.index
    })
    moveAllButtonA.baseOffset = vec3(-10, -1, 0)
    uiStandardButton:setClickFunction(moveAllButtonA, function()
        playerSapiens:moveAllBetweenSkillPriorities(skillTypeIndex, 0, 1)
        taskAssignUI:show(skillTypeIndex)
    end)
    
    uiToolTip:add(moveAllButtonA.userData.backgroundView, ViewPosition(MJPositionCenter, MJPositionBelow), locale:get("ui_action_allowAll"), nil, vec3(0,-8,10), nil, moveAllButtonA, normalView)

    
    local moveAllButtonB = uiStandardButton:create(normalView, vec2(moveAllButtonSize,moveAllButtonSize), uiStandardButton.types.slim_1x1)
    moveAllButtonB.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionCenter)
    moveAllButtonB.relativeView = headerViews[1]
    uiStandardButton:setIconModel(moveAllButtonB, "icon_doubleArrowRight", {
        default = material.types.ui_red.index
    })
    moveAllButtonB.baseOffset = vec3(10, -1, 0)
    uiStandardButton:setClickFunction(moveAllButtonB, function()
        playerSapiens:moveAllBetweenSkillPriorities(skillTypeIndex, 1, 0)
        taskAssignUI:show(skillTypeIndex)
    end)

    uiToolTip:add(moveAllButtonB.userData.backgroundView, ViewPosition(MJPositionCenter, MJPositionBelow), locale:get("ui_action_disallowAll"), nil, vec3(0,-8,10), nil, moveAllButtonB, normalView)

end


function taskAssignUI:show(skillTypeIndex_, prevSelectedPriority, prevSelectedScrollIndex)
    skillTypeIndex = skillTypeIndex_

	local skillSetting = automatedRoles:getSkillSettings()[skillTypeIndex]
	
	if skillSetting.automationEnabled then
		normalView.hidden = true 
		automatedView.hidden =  false 
	else
		normalView.hidden = false 
		automatedView.hidden = true
	
		for i=1,2 do
			uiScrollView:removeAllRows(insetViewInfos[i].scrollView)
			insetViewInfos[i].sapienViewinfos = {}
		end

		local function sortInfos(a,b)
			local function getHeuristic(info)
				local sapien = info.sapien
				local heuristic = 0

				local assignedCount = skill:getAssignedRolesCount(sapien)
				if assignedCount >= skill.maxRoles then
					heuristic = heuristic - 10000
				end
				
				if info.limitedAbility then
					heuristic = heuristic - 5000
				end
				
				if skill:learnStarted(sapien, skillTypeIndex) then
					heuristic = heuristic + 100
					if skill:hasSkill(sapien, skillTypeIndex) then
						heuristic = heuristic + 100
					else
						heuristic = heuristic + 100 * skill:fractionLearned(sapien, skillTypeIndex)
					end
				end
				
				local traitInfluence = sapienTrait:getSkillInfluence(sapien.sharedState.traits, skillTypeIndex)
				heuristic = heuristic + traitInfluence * 20.0

				heuristic = heuristic - assignedCount
				

				return heuristic
			end

			local heuristicA = getHeuristic(a)
			local heuristicB = getHeuristic(b)

			if heuristicA == heuristicB then
				return a.sapien.sharedState.name < b.sapien.sharedState.name
			end
			
			return heuristicA > heuristicB
		end

		local allFollowers = playerSapiens:getFollowerInfos()

		local orderedSapiens = {}
		for uniqueID,followerInfo in pairs(allFollowers) do
			
			local limitedAbility = nil
			if skill.types[skillTypeIndex].noCapacityWithLimitedGeneralAbility then
				if sapienConstants:getHasLimitedGeneralAbility(followerInfo.sharedState) then
					limitedAbility = true
				end
			end
			table.insert(orderedSapiens, {
				sapien = followerInfo,
				limitedAbility = limitedAbility,
			})
		end


		table.sort(orderedSapiens, sortInfos)
		
		local sapienViewHeight = 30.0
		local sapienIconSize = sapienViewHeight - 4.0
		local buttonSize = sapienViewHeight - 2.0

		local iconModelNamesByPriority = {
			[1] = "icon_tick", 
			[0] = "icon_cancel_thic",
		}
		local iconMaterialsByPriority = {
			[1] = material.types.ui_green.index,
			[0] = material.types.ui_red.index
		}

		local function insertRow(sapienInfo, addPriorityIndex)
			local sapien = sapienInfo.sapien
			local limitedAbility = sapienInfo.limitedAbility

			local scrollView = insetViewInfos[addPriorityIndex].scrollView

			local sapienView = ColorView.new(scrollView)
			local backgroundColor = vec4(0.0,0.0,0.0,0.05)
			if #insetViewInfos[addPriorityIndex].sapienViewinfos % 2 == 1 then
				backgroundColor = vec4(0.5,0.5,0.5,0.05)
			end

			local insertIndex = #insetViewInfos[addPriorityIndex].sapienViewinfos + 1

			

			sapienView.color = backgroundColor
			sapienView.size = vec2(scrollView.size.x - 20, sapienViewHeight)
			sapienView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
			
			uiScrollView:insertRow(scrollView, sapienView, nil)
			local sapienViewinfo = {
				sapienView = sapienView
			}

			insetViewInfos[addPriorityIndex].sapienViewinfos[insertIndex] = sapienViewinfo


			local function otherPriorityFromThisPriority()
				if addPriorityIndex == 1 then
					return 0
				end
				return 1
			end

			local otherPriority = otherPriorityFromThisPriority()


			local moveButton = uiStandardButton:create(sapienView, vec2(buttonSize,buttonSize), uiStandardButton.types.slim_1x1)
			moveButton.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionCenter)
			moveButton.hidden = true
			moveButton.baseOffset = vec3(0,0,1)
			uiStandardButton:setIconModel(moveButton, iconModelNamesByPriority[otherPriority], {
				default = iconMaterialsByPriority[otherPriority]
			})
			uiStandardButton:setClickFunction(moveButton, function()
				playerSapiens:setSkillPriority(sapien.uniqueID, skillTypeIndex, otherPriority)
				if otherPriority == 1 then
					tutorialUI:roleAssignmentWasIssued()
				end
				taskAssignUI:show(skillTypeIndex, addPriorityIndex, insertIndex)
			end)

			local moveText = nil
			if addPriorityIndex == 1 then
				moveText = locale:get("ui_action_disallow")
			else
				moveText = locale:get("ui_action_allow")
			end
			uiToolTip:add(moveButton.userData.backgroundView, ViewPosition(MJPositionCenter, MJPositionBelow), moveText, nil, vec3(0,-8,10), nil, moveButton, mainView)

			
			local configureButton = uiStandardButton:create(sapienView, vec2(buttonSize,buttonSize), uiStandardButton.types.slim_1x1)
			configureButton.relativePosition = ViewPosition(MJPositionOuterLeft, MJPositionCenter)
			configureButton.relativeView = moveButton
			configureButton.hidden = true
			uiStandardButton:setIconModel(configureButton, "icon_configure")
			uiStandardButton:setClickFunction(configureButton, function()
				gameUI:showTasksMenuForSapienFromTribeTaskAssignUI(sapien, function()
					manageUI:show(manageUI.modeTypes.task)
					roleUI:selectTask(skillTypeIndex)
				end)
			end)
			uiToolTip:add(configureButton.userData.backgroundView, ViewPosition(MJPositionCenter, MJPositionBelow), locale:get("ui_action_manageRoles"), nil, vec3(0,-8,10), nil, configureButton, mainView)

			local zoomButton = uiStandardButton:create(sapienView, vec2(buttonSize,buttonSize), uiStandardButton.types.slim_1x1)
			zoomButton.relativePosition = ViewPosition(MJPositionOuterLeft, MJPositionCenter)
			zoomButton.relativeView = configureButton
			zoomButton.hidden = true
			uiStandardButton:setIconModel(zoomButton, "icon_inspect")
			uiStandardButton:setClickFunction(zoomButton, function()
				manageUI:hide()
				gameUI:followObject(sapien, false, false, true, true)
				hubUI:setLookAtInfo(sapien, false, false)
				hubUI:showInspectUI(sapien, nil, false)
			end)
			uiToolTip:add(zoomButton.userData.backgroundView, ViewPosition(MJPositionCenter, MJPositionBelow), locale:get("ui_action_zoom"), nil, vec3(0,-8,10), nil, zoomButton, mainView)
			
			local objectImageView = GameObjectView.new(sapienView, vec2(sapienIconSize, sapienIconSize))
			objectImageView.size = vec2(sapienIconSize, sapienIconSize)
			objectImageView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
			objectImageView.baseOffset = vec3(16,0,1)
			
			local animationInstance = uiAnimation:getUIAnimationInstance(sapienConstants:getAnimationGroupIndex(sapien.sharedState))
			uiCommon:setGameObjectViewObject(objectImageView, sapien, animationInstance)

			local hasSkill = false
			if skill:learnStarted(sapien, skillTypeIndex) then
				local skillAchievementIcon = ModelView.new(sapienView)
				skillAchievementIcon.masksEvents = false
				skillAchievementIcon.relativePosition = ViewPosition(MJPositionCenter, MJPositionCenter)
				skillAchievementIcon.relativeView = objectImageView
				skillAchievementIcon.baseOffset = vec3(-18,6,0)
				
				if skill:hasSkill(sapien, skillTypeIndex) then
					hasSkill = true
					local skillAchievementIconHalfSize = 7
					skillAchievementIcon.scale3D = vec3(skillAchievementIconHalfSize,skillAchievementIconHalfSize,skillAchievementIconHalfSize)
					skillAchievementIcon.size = vec2(skillAchievementIconHalfSize,skillAchievementIconHalfSize) * 2.0

					skillAchievementIcon:setModel(model:modelIndexForName("icon_achievement"), {
						default = material.types.ui_selected.index,
					})
				else
					local skillAchievementIconHalfSize = 5
					skillAchievementIcon.scale3D = vec3(skillAchievementIconHalfSize,skillAchievementIconHalfSize,skillAchievementIconHalfSize)
					skillAchievementIcon.size = vec2(skillAchievementIconHalfSize,skillAchievementIconHalfSize) * 2.0

					skillAchievementIcon:setModel(model:modelIndexForName("icon_circle_filled"), {
						default = material.types.ui_disabled.index
					})
					
					local skillAchievementProgressIcon = ModelView.new(sapienView)
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

			local traitInfluenceInfo = sapienTrait:getSkillInfluenceWithTraitsList(sapien.sharedState.traits, skillTypeIndex)
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
				local traitInfluenceTextView = TextView.new(sapienView)
				traitInfluenceTextView.relativePosition = ViewPosition(MJPositionCenter, MJPositionCenter)
				traitInfluenceTextView.relativeView = objectImageView
				traitInfluenceTextView.baseOffset = vec3(-18,-8,0)
				traitInfluenceTextView.font = Font(uiCommon.fontName, 14)
				traitInfluenceTextView.color = color
				traitInfluenceTextView.text = traitText
			end


			local nameTextView = TextView.new(sapienView)
			nameTextView.relativePosition = ViewPosition(MJPositionOuterRight, MJPositionCenter)
			nameTextView.relativeView = objectImageView
			nameTextView.masksEvents = false
			nameTextView.baseOffset = vec3(4,0,1)
			nameTextView.font = Font(uiCommon.fontName, 14)

			local function getLimitedAbilityReasonInfo()
				local reason = {}
				if limitedAbility then
					local sharedState = sapien.sharedState
					if sharedState.pregnant then
						reason.pregnant = true
					elseif sharedState.hasBaby then
						reason.hasBaby = true
					elseif sharedState.lifeStageIndex == sapienConstants.lifeStages.child.index then
						reason.child = true
					elseif sharedState.lifeStageIndex == sapienConstants.lifeStages.elder.index then
						reason.elder = true
					end
				else
					reason.maxAssigned = true
				end
				return reason
			end

			local limitedAbilityReasonInfo = nil

			if limitedAbility or (addPriorityIndex == 2 and skill:getAssignedRolesCount(sapien) >= skill.maxRoles) then

				limitedAbilityReasonInfo = getLimitedAbilityReasonInfo()

				nameTextView.color = material:getUIColor(material.types.warning.index)
				
				local limitedAbilityText = locale:get("ui_cantDoTasksShort", limitedAbilityReasonInfo)

				nameTextView.text = sapien.sharedState.name .. " (" .. limitedAbilityText .. ")" 
			else
				nameTextView.color = vec4(1.0,1.0,1.0,1.0)
				nameTextView.text = sapien.sharedState.name
			end

			
			if limitedAbilityReasonInfo or #traitInfluenceInfo.positiveTraits > 0 or #traitInfluenceInfo.negativeTraits > 0 or hasSkill then
				local tipView = View.new(sapienView)
				tipView.masksEvents = true
				tipView.size = objectImageView.size + vec2(200.0,0)
				tipView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
				tipView.relativeView = objectImageView
				tipView.baseOffset = vec3(-10,0,0)
				uiToolTip:add(tipView, ViewPosition(MJPositionInnerLeft, MJPositionBelow), "", nil, vec3(20,-8,10), nil, tipView, mainView)

				if hasSkill then
					local traitText = locale:get("misc_skilled")
					if #traitInfluenceInfo.positiveTraits > 0 or #traitInfluenceInfo.negativeTraits > 0 then
						traitText = traitText .. ", "
					end
					uiToolTip:addColoredTitleText(tipView, traitText, mj.highlightColor)
				end

				for i, traitInfo in ipairs(traitInfluenceInfo.positiveTraits) do
					local traitType = sapienTrait.types[traitInfo.traitTypeIndex]
					local traitText = nil
					if traitInfo.opposite then
						traitText = traitType.opposite
					else
						traitText = traitType.name
					end
					if i < #traitInfluenceInfo.positiveTraits or #traitInfluenceInfo.negativeTraits > 0 then
						traitText = traitText .. ", "
					end
					uiToolTip:addColoredTitleText(tipView, traitText, vec4(0.4,0.8,0.4,1.0))
				end
				for i, traitInfo in ipairs(traitInfluenceInfo.negativeTraits) do
					local traitType = sapienTrait.types[traitInfo.traitTypeIndex]
					local traitText = nil
					if traitInfo.opposite then
						traitText = traitType.opposite
					else
						traitText = traitType.name
					end
					if i < #traitInfluenceInfo.negativeTraits then
						traitText = traitText .. ", "
					end
					uiToolTip:addColoredTitleText(tipView, traitText, vec4(0.8,0.4,0.4,1.0))
				end

				if limitedAbilityReasonInfo then
					local warningString = nil
					if limitedAbility and skill.types[skillTypeIndex].partialCapacityWithLimitedGeneralAbility then
						warningString = locale:get("ui_partiallyCantDoTasks", limitedAbilityReasonInfo)
					else
						warningString = locale:get("ui_cantDoTasks", limitedAbilityReasonInfo)
					end

					uiToolTip:addColoredTitleText(tipView, " (" .. warningString .. ")" , material:getUIColor(material.types.warning.index))
				end
			end

			sapienView.hoverStart = function ()
				if not sapienViewinfo.hover then
					sapienViewinfo.hover = true
					sapienView.color = vec4(mj.highlightColor.x,mj.highlightColor.y,mj.highlightColor.z,0.08)
					moveButton.hidden = false
					configureButton.hidden = false
					zoomButton.hidden = false
				end
			end
		
			sapienView.hoverEnd = function ()
				if sapienViewinfo.hover then
				   sapienViewinfo.hover = false
				   sapienView.color = backgroundColor
				   moveButton.hidden = true
				   configureButton.hidden = true
				   zoomButton.hidden = true
				end
			end

			if prevSelectedPriority and prevSelectedPriority == addPriorityIndex then
				if prevSelectedScrollIndex == insertIndex then
					sapienView.hoverStart()
				end
			end

			local iconXOffset = 300.0
			local skillIconHalfSize = 10

			local iconInfos = {}

			for i,otherSkillType in ipairs(skill.validTypes) do
				local otherPriorityLevel = skill:priorityLevel(sapien, otherSkillType.index)
				if otherPriorityLevel == 1 then
					local iconBackgroundView = View.new(sapienView)
					iconBackgroundView.masksEvents = true
					iconBackgroundView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
					iconBackgroundView.baseOffset = vec3(iconXOffset, 0, 2)
					iconBackgroundView.size = vec2(skillIconHalfSize,skillIconHalfSize) * 2.0

					local icon = ModelView.new(iconBackgroundView)
					icon.masksEvents = false
					icon.scale3D = vec3(skillIconHalfSize,skillIconHalfSize,skillIconHalfSize)
					icon.size = iconBackgroundView.size
					
					if otherSkillType.index == skillTypeIndex then
						if limitedAbility then
							icon:setModel(model:modelIndexForName(skill.types[otherSkillType.index].icon), {
								default = material.types.warning.index
							})
						else
							icon:setModel(model:modelIndexForName(skill.types[otherSkillType.index].icon), {
								default = material.types.ui_green.index
							})
						end
					else
						icon:setModel(model:modelIndexForName(skill.types[otherSkillType.index].icon))
					end
					iconXOffset = iconXOffset + icon.size.x + 2
					table.insert(iconInfos, {
						skillTypeIndex = otherSkillType.index,
						icon = icon
					})
					
					uiToolTip:add(iconBackgroundView, ViewPosition(MJPositionCenter, MJPositionBelow), otherSkillType.name, nil, vec3(0,-8,10), nil, iconBackgroundView, mainView)
				end
			end

			if addPriorityIndex == 2 then
				if #iconInfos >= skill.maxRoles then
					uiStandardButton:setDisabled(moveButton, true)
					for i, iconInfo in ipairs(iconInfos) do
						iconInfo.icon:setModel(model:modelIndexForName(skill.types[iconInfo.skillTypeIndex].icon), {
							default = material.types.warning.index
						})
					end
					
					uiStandardButton:setIconModel(moveButton, iconModelNamesByPriority[otherPriority], {
						default = material.types.ui_disabled.index
					})
				end
			end
		end

		for i,sapienInfo in ipairs(orderedSapiens) do
			local priority = skill:priorityLevel(sapienInfo.sapien, skillTypeIndex)
			local addIndex = 2
			if priority == 1 then
				addIndex = 1
			end
			insertRow(sapienInfo, addIndex)
		end
	end

    local function changeTitle(text, iconModelName)
        titleTextView:setText(text, material.types.standardText.index)
        titleIcon:setModel(model:modelIndexForName(iconModelName))
        titleView.size = vec2(titleTextView.size.x + iconHalfSize + iconHalfSize + iconPadding, titleView.size.y)
    end

    changeTitle(skill.types[skillTypeIndex].name, skill.types[skillTypeIndex].icon)

    mainView.hidden = false
end

function taskAssignUI:hide()
    mainView.hidden = true
end

return taskAssignUI