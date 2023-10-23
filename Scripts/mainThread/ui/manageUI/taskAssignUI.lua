local mjm = mjrequire "common/mjm"
local vec2 = mjm.vec2
local vec3 = mjm.vec3

local uiCommon = mjrequire "mainThread/ui/uiCommon/uiCommon"
local uiStandardButton = mjrequire "mainThread/ui/uiCommon/uiStandardButton"

local shadow = mjrequire "hammerstone/utils/shadow"
local uiController = mjrequire "hammerstone/ui/uiController"

local automatedRolesUI = mjrequire "automate/automatedRolesUI"
local automatedRoles = mjrequire "automate/automatedRoles"
local taskTreeUI = mjrequire "mainThread/ui/manageUI/taskTreeUI"

local taskAssignUI = {}

local mainView = nil
local automatedView = nil
local skillTypeIndex = nil

function taskAssignUI:init(super, roleUI_, gameUI_, world_, manageUI_, hubUI_, contentView)

    super(self, roleUI_, gameUI_, world_, manageUI_, hubUI_, contentView)

    mainView = uiController:searchSubViews(contentView, "mainView", "View", "mainThread/ui/manageUI/taskAssignUI")[1]

    automatedView = View.new(contentView)
    automatedView.size = vec2(contentView.size.x - 20, contentView.size.y - 20)
    automatedView.relativePosition = ViewPosition(MJPositionCenter, MJPositionTop)
    automatedView.baseOffset = vec3(0,-10, 0)
    automatedView.hidden = true 

    local backButton = uiStandardButton:create(automatedView, vec2(50,50), uiStandardButton.types.markerLike)
    backButton.relativePosition = ViewPosition(MJPositionInnerRight, MJPositionTop)
    backButton.baseOffset = vec3(0, 0, 0)
    uiStandardButton:setIconModel(backButton, "icon_back")
    uiStandardButton:setClickFunction(backButton, function()
        manageUI_:show(manageUI_.modeTypes.task)
    end)

    local automatedViewText = TextView.new(automatedView)
	automatedViewText.relativePosition = ViewPosition(MJPositionCenter, MJPositionCenter)
	automatedViewText.font = Font(uiCommon.fontName, 22)
	automatedViewText.color = mj.textColor
	automatedViewText.text = "This role is automated"

    local function addAutomateButton(parentView)
        local automateButton = uiStandardButton:create(parentView, vec2(50,50), uiStandardButton.types.markerLike)
        automateButton.relativePosition = ViewPosition(MJPositionInnerLeft, MJPositionTop)
        automateButton.baseOffset = vec3(0, 0, 0)
        uiStandardButton:setIconModel(automateButton, "icon_logistics")
        uiStandardButton:setClickFunction(automateButton, function()
            self:hide()
            taskTreeUI:hide()
            automatedRolesUI:show(skillTypeIndex)
        end)
    end

    addAutomateButton(mainView)
    addAutomateButton(automatedView)
end

function taskAssignUI:show(super, skillTypeIndex_, prevSelectedPriority, prevSelectedScrollIndex)
    skillTypeIndex = skillTypeIndex_
    super(self, skillTypeIndex_, prevSelectedPriority, prevSelectedScrollIndex)

    local skillSetting = automatedRoles:getSkillSettings()[skillTypeIndex]
	
    mainView.hidden = skillSetting.automationEnabled
    automatedView.hidden = not skillSetting.automationEnabled
end

function taskAssignUI:hide(super)
    super(self)
    automatedView.hidden = true
end

return shadow:shadow(taskAssignUI)