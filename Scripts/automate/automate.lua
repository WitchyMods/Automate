-- Sapiens
local plan = mjrequire "common/plan"
local playerSapiens = mjrequire "mainThread/playerSapiens"

-- Hammerstone
local modOptionsManager = mjrequire "hammerstone/options/modOptionsManager"

-- Automate
local automatedRoles = mjrequire "automate/automatedRoles"

local logicInterface = nil

local automate = {}

function automate:init(world, logicInterface_)
    logicInterface = logicInterface_

    automatedRoles:init(world, playerSapiens)
end

function automate:nonFollowerApproached(nomadID)
    local autoRecruitEnabled = modOptionsManager:getModOptionsValue("witchyAutomate", "enableAutoRecruit")
    local limit = modOptionsManager:getModOptionsValue("witchyAutomate", "autoRecruitLimit")

    if autoRecruitEnabled then
        if limit >= playerSapiens:getPopulationCountIncludingBabies() then
            local addInfo = {
                planTypeIndex = plan.types.recruit.index,
                objectOrVertIDs = {nomadID}
            }
            logicInterface:callServerFunction("addPlans", addInfo)
        end        
    end
end

function automate:soilQualityDropped(vertID)
    local autoFertilizeEnabled = modOptionsManager:getModOptionsValue("witchyAutomate", "enableAutoFertilize")
    local prioritize = modOptionsManager:getModOptionsValue("witchyAutomate", "prioritizeAutoFertilize")

    if autoFertilizeEnabled then
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