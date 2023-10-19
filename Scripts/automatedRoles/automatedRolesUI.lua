local mjm = mjrequire "common/mjm"
local vec3 = mjm.vec3
local vec2 = mjm.vec2
local vec4 = mjm.vec4

local model = mjrequire "common/model"
local material = mjrequire "common/material"
local locale = mjrequire "common/locale"

local skill = mjrequire "common/skill"
local sapienConstants = mjrequire "common/sapienConstants"

local uiCommon = mjrequire "mainThread/ui/uiCommon/uiCommon"
local uiStandardButton = mjrequire "mainThread/ui/uiCommon/uiStandardButton"
local uiScrollView = mjrequire "mainThread/ui/uiCommon/uiScrollView"
local uiSelectionLayout = mjrequire "mainThread/ui/uiCommon/uiSelectionLayout"
local uiSlider = mjrequire "mainThread/ui/uiCommon/uiSlider"

local playerSapiens = mjrequire "mainThread/playerSapiens"

local automatedRoles = mjrequire "automatedRoles/automatedRoles"

local automatedRolesUI = {}

local roleUI = nil 
local mainView = nil
local skillTypeIndex = nil

local titleView = nil
local titleIcon = nil
local titleTextView = nil

local iconHalfSize = 14
local iconPadding = 6

local automateToggle = nil 
local containerView = nil 
local stagesScrollView = nil
local stagesScrollViewRows = {}
local absToggle = nil 
local prcToggle = nil 
local minValueSlider = nil
local maxValueSlider = nil 
local minValueText = nil 
local maxValueText = nil 

local saveButton = nil 
local skillSetting = nil 

local stagesScrollViewHasFocus = false

local followersCount = 0

local function updateMinSliderText()
	if skillSetting.automationType == "abs" then
		minSliderText.text = string.format("%d/%d", skillSetting.minValue, followersCount)
	else
		minSliderText.text = string.format("%d", skillSetting.minValue) .. "%"
	end
end 

local function updateMaxSliderText()
	if skillSetting.automationType == "abs" then
		maxSliderText.text = string.format("%d/%d", skillSetting.maxValue, followersCount)
	else
		maxSliderText.text = string.format("%d", skillSetting.maxValue) .. "%"
	end
end

local function automateToggleChanged(toggleValue)
	containerView.hidden = not toggleValue
	skillSetting.automationEnabled = toggleValue
end

local function absToggleChanged(toggleValue)
	uiStandardButton:setToggleState(prcToggle, not toggleValue)
	
	if toggleValue then
		skillSetting.automationType = "abs"
	else
		skillSetting.automationType = "prc"
	end
	
	updateMinSliderText()
	updateMaxSliderText()
end

local function prcToggleChanged(toggleValue)
	uiStandardButton:setToggleState(absToggle, not toggleValue)
	
	if not toggleValue then
		skillSetting.automationType = "abs"
	else
		skillSetting.automationType = "prc"
	end
	
	updateMinSliderText()
	updateMaxSliderText()
end

local function minSliderChanged(value)
	skillSetting.minValue = value
	
	if skillSetting.minValue > skillSetting.maxValue then
		skillSetting.maxValue = value
		uiSlider:setValue(maxSlider, value)
		updateMaxSliderText()
	end
	
	updateMinSliderText()
end

local function maxSliderChanged(value)
	skillSetting.maxValue = value 
	
	if skillSetting.maxValue < skillSetting.minValue then 
		skillSetting.minValue = value
		uiSlider:setValue(minSlider, value)
		updateMinSliderText()
	end
	
	updateMaxSliderText()
end

local function saveButtonClicked()
	local skillSettings = automatedRoles:getSkillSettings()
	skillSettings[skillTypeIndex] = skillSetting
	automatedRoles:saveSkillSettings(skillSettings)
	
	automatedRoles:reassignAll()
	
	roleUI:selectTask(skillTypeIndex)
end 

function automatedRolesUI:init(roleUI_, contentView)

	roleUI = roleUI_
	
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
    titleIcon:setModel(model:modelIndexForName("icon_logistics"))

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
        roleUI:selectTask(skillTypeIndex)
    end)
	
	local function createToggle(parentView, offsetX, text, changedFunction)
		local backgroundView = View.new(parentView)
		backgroundView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
		backgroundView.baseOffset = vec3(offsetX, 0, 0)
		backgroundView.masksEvents = true
		
		local toggleButton = uiStandardButton:create(backgroundView, vec2(26,26), uiStandardButton.types.toggle)
		toggleButton.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
		toggleButton.baseOffset = vec3(0, 4, 0)
		
		local toggleText = TextView.new(backgroundView)
		toggleText.font = Font(uiCommon.fontName, 18)
		toggleText.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
		toggleText.baseOffset = vec3(30, 0, 0)
		toggleText.text = text
		toggleText.color = mj.textColor
		
		if changedFunction then
            uiStandardButton:setClickFunction(toggleButton, function()
                changedFunction(uiStandardButton:getToggleState(toggleButton))
            end)
        end
		
		backgroundView.size = vec2(toggleButton.size.x + toggleText.size.x, toggleButton.size.y)
				
		return toggleButton		
	end 
	
	local settingsMarginY = 100
	
	local settingsView = View.new(mainView)
	settingsView.size = vec2(500, mainView.size.y - settingsMarginY)
	settingsView.relativePosition = ViewPosition(MJPositionCenter, MJPositionTop)
	settingsView.baseOffset = vec3(0, -settingsMarginY, 0)
	
	automateToggle = createToggle(settingsView, 0, "Allow automation", automateToggleChanged)
	
	local containerMarginY = 50
	
	containerView = View.new(settingsView)
	containerView.size = vec2(settingsView.size.x, settingsView.size.y - containerMarginY)
	containerView.relativePosition = ViewPosition(MJPositionCenter, MJPositionTop)
	containerView.baseOffset = vec3(0, -containerMarginY, 0)
	containerView.hidden = true
	
	local offsetY = 0
	local offsetYBetweenElements = 35
	local labelsWidth = 200
	
	--- STAGES
	local stagesViewInsetSize = vec2(200, 100)
	local stagesViewScrollSize = vec2(stagesViewInsetSize.x - 10, stagesViewInsetSize.y - 10)
	local stagesViewInsetSizeX = stagesViewInsetSize.x * 0.5
	local stagesViewInsetSizeY = stagesViewInsetSize.y * 0.5 / 0.75
	
	local stagesView = View.new(containerView)
	stagesView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
	stagesView.baseOffset = vec3(0, offsetY, 0)
	stagesView.size = vec2(containerView.size.x, stagesViewInsetSize.y)
	
	local stagesText = TextView.new(stagesView)
	stagesText.font = Font(uiCommon.fontName, 18)
	stagesText.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
	stagesText.text = "Allowed stages"
	stagesText.color = mj.textColor
	
	local stagesViewInset = ModelView.new(stagesView)
	stagesViewInset:setModel(model:modelIndexForName("ui_inset_sm_4x3"))
	stagesViewInset.scale3D = vec3(stagesViewInsetSizeX, stagesViewInsetSizeY, stagesViewInsetSizeX)
	stagesViewInset.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
	stagesViewInset.size = stagesViewInsetSize
	stagesViewInset.baseOffset = vec3(labelsWidth, 0, 0)
	
	stagesScrollView = uiScrollView:create(stagesViewInset, stagesViewScrollSize, MJPositionInnerLeft)
	stagesScrollView.baseOffset = vec3(0, 0, 2)
	
	uiSelectionLayout:createForView(stagesScrollView)
	
	offsetY = offsetY - stagesView.size.y - offsetYBetweenElements	
	
	--- AUTOMATION TYPE
	local typeChoiceView = View.new(containerView)
	typeChoiceView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
	typeChoiceView.baseOffset = vec3(0, offsetY, 0)
	typeChoiceView.size = vec2(containerView.size.x, offsetYBetweenElements)
	
	local typeChoiceText = TextView.new(typeChoiceView)
	typeChoiceText.font = Font(uiCommon.fontName, 18)
	typeChoiceText.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
	typeChoiceText.baseOffset = vec3(0, 0, 0)
	typeChoiceText.text = "Automation Type"
	typeChoiceText.color = mj.textColor
	
	absToggle = createToggle(typeChoiceView, labelsWidth, "Absolute", absToggleChanged)
	prcToggle = createToggle(typeChoiceView, labelsWidth + 100, "Percentage", prcToggleChanged)
	
	offsetY = offsetY - offsetYBetweenElements	
	
	--- MIN/MAX
	local sliderWidth = 200
		
	local minLabel = TextView.new(containerView)
	minLabel.font = Font(uiCommon.fontName, 18)
	minLabel.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
	minLabel.baseOffset = vec3(0, offsetY, 0)
	minLabel.text = "Min"
	minLabel.color = mj.textColor
	
	local minOptions = {
		continuous = true,
		releasedFunction = minSliderChanged
	}
	
	minSlider = uiSlider:create(containerView, vec2(sliderWidth, 20), 0, 100, 0, minOptions, minSliderChanged)
	minSlider.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
	minSlider.baseOffset = vec3(labelsWidth, offsetY, 0)
	
	minSliderText = TextView.new(containerView)
	minSliderText.font = Font(uiCommon.fontName, 18)
	minSliderText.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
	minSliderText.baseOffset = vec3(labelsWidth + sliderWidth + 20, offsetY, 0)
	minSliderText.color = mj.textColor
	minSliderText.text = "0/0"
	
	offsetY = offsetY - offsetYBetweenElements	
	
	local maxLabel = TextView.new(containerView)
	maxLabel.font = Font(uiCommon.fontName, 18)
	maxLabel.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
	maxLabel.baseOffset = vec3(0, offsetY, 0)
	maxLabel.text = "Max"
	maxLabel.color = mj.textColor
	
	local maxOptions = {
		continuous = true,
		releasedFunction = maxSliderChanged
	}
	
	maxSlider = uiSlider:create(containerView, vec2(sliderWidth, 20), 0, 100, 0, maxOptions, maxSliderChanged)
	maxSlider.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
	maxSlider.baseOffset = vec3(labelsWidth, offsetY, 0)
	
	maxSliderText = TextView.new(containerView)
	maxSliderText.font = Font(uiCommon.fontName, 18)
	maxSliderText.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
	maxSliderText.baseOffset = vec3(labelsWidth + sliderWidth + 20, offsetY, 0)
	maxSliderText.color = mj.textColor
	maxSliderText.text = "0/0"	
	
	offsetY = offsetY - offsetYBetweenElements	
	
	--- SAVE BUTTON
	local buttonSize = vec2(180, 40)
	
	saveButton = uiStandardButton:create(settingsView, buttonSize)
	saveButton.relativePosition = ViewPosition(MJPositionCenter, MJPositionTop)
	saveButton.baseOffset = vec3(0, offsetY - 100, 0)
	
	uiStandardButton:setText(saveButton, "Save")
	uiStandardButton:setClickFunction(saveButton, saveButtonClicked)
	
end

function automatedRolesUI:show(skillTypeIndex_)
	skillTypeIndex = skillTypeIndex_
	
	followersCount = 0 
	for uniqueId, follower in pairs(playerSapiens:getFollowerInfos()) do 
		followersCount = followersCount + 1
	end
	
	local function changeTitle(text, iconModelName)
        titleTextView:setText("Automate " .. text, material.types.standardText.index)
        titleIcon:setModel(model:modelIndexForName(iconModelName))
        titleView.size = vec2(titleTextView.size.x + iconHalfSize + iconHalfSize + iconPadding, titleView.size.y)
    end

    changeTitle(skill.types[skillTypeIndex].name, skill.types[skillTypeIndex].icon)
	
	skillSetting = automatedRoles:getSkillSettings()[skillTypeIndex]
		
	uiStandardButton:setToggleState(automateToggle, skillSetting.automationEnabled)
	containerView.hidden = not skillSetting.automationEnabled
	
	if skillSetting.automationType == "abs" then
		uiStandardButton:setToggleState(absToggle, true)
		uiStandardButton:setToggleState(prcToggle, false)
	elseif skillSetting.automationType == "prc" then
		uiStandardButton:setToggleState(absToggle, false)
		uiStandardButton:setToggleState(prcToggle, true)
	end 
	
	uiSlider:setValue(minSlider, skillSetting.minValue)
	uiSlider:setValue(maxSlider, skillSetting.maxValue)
	
	uiScrollView:removeAllRows(stagesScrollView)
    uiSelectionLayout:removeAllViews(stagesScrollView)
	
	local counter = 1
	local backgroundColors = {vec4(0.5,0.5,0.5,0.05), vec4(0.0,0.0,0.0,0.05)}
	
	stagesScrollViewRows = {}
	
	for i, stage in ipairs(sapienConstants.lifeStages) do 
		rowInfo = {
			index = stage.index, 
			text = stage.name, 
			enabled = true, 
			checked = false
			}
		
		if skill.types[skillTypeIndex].noCapacityWithLimitedGeneralAbility and sapienConstants:getHasLimitedGeneralAbility({lifeStageIndex = stage.index}) then 
			rowInfo.enabled = false
		end
		
		if skillSetting.allowedStages[stage.index] then 
			rowInfo.checked = true 
		end
		
		table.insert(stagesScrollViewRows, rowInfo)
	end
	
	for i, row in ipairs(stagesScrollViewRows) do 
		local rowBackgroundView = ColorView.new(stagesScrollView)
		local defaultColor = backgroundColors[counter % 2 + 1]
		
		rowBackgroundView.color = defaultColor
		rowBackgroundView.size = vec2(stagesScrollView.size.x - 22, 30)
		rowBackgroundView.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
		
		row.backgroundView = rowBackgroundView
		
		local toggleButton = uiStandardButton:create(rowBackgroundView, vec2(26,26), uiStandardButton.types.toggle)
        toggleButton.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
        toggleButton.baseOffset = vec3(4, 0, 0)
		uiStandardButton:setToggleState(toggleButton, row.enabled and row.checked)
		
		local toggleText = TextView.new(rowBackgroundView)
		toggleText.font = Font(uiCommon.fontName, 18)
		toggleText.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionCenter)
		toggleText.baseOffset = vec3(30, 0, 0)
		toggleText.text = row.text
		toggleText.color = mj.textColor
		
		if not row.enabled then
			uiStandardButton:setDisabled(toggleButton, not enabled)
			toggleText.color = vec4(1.0,1.0,1.0,0.5)
		end
		
		uiStandardButton:setClickFunction(toggleButton, function()
			skillSetting.allowedStages[row.index] = uiStandardButton:getToggleState(toggleButton)
		end)
		
		row.toggleButton = toggleButton
		row.toggleText = toggleText
		
		uiScrollView:insertRow(stagesScrollView, rowBackgroundView, nil)
		uiSelectionLayout:addView(stagesScrollView, rowBackgroundView)
		
		counter = counter + 1
	end
	
	updateMinSliderText()
	updateMaxSliderText()
		
	mainView.hidden = false
end

function automatedRolesUI:hide()
	uiSelectionLayout:removeActiveSelectionLayoutView(stagesScrollView)
	mainView.hidden = true
end

return automatedRolesUI