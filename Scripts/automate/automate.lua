-- Sapiens
local plan = mjrequire "common/plan"
local planHelper = mjrequire "common/planHelper"
local skill = mjrequire "common/skill"
local playerSapiens = mjrequire "mainThread/playerSapiens"

-- Hammerstone
local modOptionsManager = mjrequire "hammerstone/options/modOptionsManager"

-- Automate
local automatedRoles = mjrequire "automate/automatedRoles"

local logicInterface = nil
local world = nil

local automate = {}

function automate:init(world_, logicInterface_)
    logicInterface = logicInterface_
    world = world_

    automatedRoles:init(world, playerSapiens)
end

function automate:overrideAutomatedRolesOptionChanged(newValue)
	mj:log("WITCHY! newValue = ", newValue)
	
	if newValue then
		world:setAutoRoleAssignmentEnabled(false)
		automatedRoles:reassignAll()
	end
end

function automate:nonFollowerApproached(nomadID)
    local autoRecruitEnabled = modOptionsManager:getModOptionsValue("witchyAutomate", "enableAutoRecruit")
    local limit = modOptionsManager:getModOptionsValue("witchyAutomate", "autoRecruitLimit")
    local prioritize = modOptionsManager:getModOptionsValue("witchyAutomate", "prioritizeAutoRecruit")

    if autoRecruitEnabled then
        if limit >= playerSapiens:getPopulationCountIncludingBabies() then
            local addInfo = {
                planTypeIndex = plan.types.recruit.index,
                objectOrVertIDs = {nomadID}
            }
            logicInterface:callServerFunction("addPlans", addInfo)

            if prioritize then
                logicInterface:callServerFunction("prioritizePlans", addInfo)
            end
        end        
    end
end

function automate:soilQualityDropped(vertID)
    local autoFertilizeEnabled = modOptionsManager:getModOptionsValue("witchyAutomate", "enableAutoFertilize")
    local prioritize = modOptionsManager:getModOptionsValue("witchyAutomate", "prioritizeAutoFertilize")

    if autoFertilizeEnabled and planHelper.completedSkillsByTribeID[world.tribeID] and planHelper.completedSkillsByTribeID[world.tribeID][skill.types.mulching.index] then
        local addInfo = {
            planTypeIndex = plan.types.fertilize.index,
            objectOrVertIDs = {vertID}
        }
        logicInterface:callServerFunction("addPlans", addInfo)

        if prioritize then
            logicInterface:callServerFunction("prioritizePlans", addInfo)
        end
    end
end

return automate