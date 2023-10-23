--- AutomatedRoles
--- Author: Witchy

local skill = mjrequire "common/skill"
local sapienConstants = mjrequire "common/sapienConstants"
local sapienTrait = mjrequire "common/sapienTrait"

local playerSapiens = nil
local world = nil

local databaseKey = "witchy_automatedRoles_SkillSettings"

local automatedRoles = {
}

local tempRoles = {}
local allFollowers = nil 
local followersCount = 0

local skillSettings = nil

local function hasSkill(tempInfo, skillTypeIndex)
	for i = 1, #tempInfo.allRoles do 
		if tempInfo.allRoles[i] == skillTypeIndex then
			return true
		end
	end
end

local function isSkillRemoved(tempInfo, skillTypeIndex)
	for i = 1, #tempInfo.removed do
		if tempInfo.removed[i] == skillTypeIndex then
			return true
		end
	end
end

local function getNewAssignedSapiensCount(skillTypeIndex)
	local count = 0 
	
	for uniqueID, tempInfo in pairs(tempRoles) do
		if hasSkill(tempInfo, skillTypeIndex) then
			count = count + 1
		end
	end
	
	return count
end

local function getAssignedRolesCount(sapien)
	return #tempRoles[sapien.uniqueID].allRoles
end
	
local function sortInfos(a, b, skillTypeIndex)
	local function getHeuristic(info)
		local sapien = info.sapien
		local heuristic = 0
		
		if skill:priorityLevel(sapien, skillTypeIndex) == 1 then
			heuristic = heuristic + 100000
		end

		local assignedCount = getAssignedRolesCount(sapien)
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
		heuristic = heuristic + 200 + traitInfluence * 20.0

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

local function getOrderedAlreadyAssignedList(skillTypeIndex)
	local orderedSapiens = {}
	
	for uniqueID,followerInfo in pairs(allFollowers) do
		if skill:priorityLevel(followerInfo, skillTypeIndex) == 1 then 
			local limitedAbility = nil
			if skill.types[skillTypeIndex].noCapacityWithLimitedGeneralAbility then
				limitedAbility = tempRoles[followerInfo.uniqueID].limitedAbility
			end
			table.insert(orderedSapiens, {
				sapien = followerInfo,
				limitedAbility = limitedAbility,
			})
		end
	end
	
	table.sort(orderedSapiens, function (a,b) return sortInfos(a, b, skillTypeIndex) end)
	
	return orderedSapiens
end

local function getOrderedCandidatesList(skillTypeIndex, skillSetting)
	local orderedSapiens = {}
	
	for uniqueID, followerInfo in pairs(allFollowers) do
		if not hasSkill(tempRoles[uniqueID], skillTypeIndex) then
			local limitedAbility = nil
			if skill.types[skillTypeIndex].noCapacityWithLimitedGeneralAbility then
				limitedAbility = tempRoles[followerInfo.uniqueID].limitedAbility
			end
			
			local nbSkills = #tempRoles[uniqueID].allRoles
						
			if not limitedAbility and skillSetting.allowedStages[followerInfo.sharedState.lifeStageIndex] and nbSkills < skill.maxRoles then
				table.insert(orderedSapiens, {
					sapien = followerInfo,
					limitedAbility = limitedAbility,
				})
			end
		end
	end
	
	table.sort(orderedSapiens, function (a,b) return sortInfos(a, b, skillTypeIndex) end)
	
	return orderedSapiens
end

local function getAbsMinValue(skillSetting)
	if skillSetting.automationType == "abs" then
		return skillSetting.minValue
	else
		return math.floor(skillSetting.minValue / 100.0 * followersCount)
	end
end

local function getAbsMaxValue(skillSetting)
	if skillSetting.automationType == "abs" then
		return skillSetting.maxValue
	else
		return math.ceil(skillSetting.maxValue / 100.0 * followersCount)
	end
end

local function fillTempRoles()
	local orderedLists = {}	
	local automatedSettings = {}
	
	-- init the lists
	followersCount = 0
	for uniqueID, follower in pairs(allFollowers) do
		tempRoles[uniqueID] = {
			limitedAbility = sapienConstants:getHasLimitedGeneralAbility(follower.sharedState),
			allRoles = {},
			added = {},
			removed = {}
		}
		followersCount = followersCount + 1
	end
	
	local hasAutomation = false 
		
	-- build a list of roles that won't change (not automated)
	-- build an ordered list of sapiens per skill
	for skillTypeIndex, skillSetting in pairs(skillSettings) do 
		if skillSetting.automationEnabled then 
			hasAutomation = true
			automatedSettings[skillTypeIndex] = skillSetting
			orderedLists[skillTypeIndex] = getOrderedAlreadyAssignedList(skillTypeIndex)
		else
			for uniqueID, follower in pairs(allFollowers) do
				if skill:priorityLevel(follower, skillTypeIndex) == 1 then
					table.insert(tempRoles[uniqueID].allRoles, skillTypeIndex)
				end
			end
		end
	end
	
	if not hasAutomation then 
		return 
	end 
			
	-- remove roles from some sapiens if : 
	--  *the count exceeds the max value
	--  *if the sapien has limited capacity
	--  *if the life stage is not allowed
	for skillTypeIndex, skillSetting in pairs(automatedSettings) do 				
		local orderedList = orderedLists[skillTypeIndex]	
		local index = #orderedList 
		
		--mj:log("Removing invalid roles")
		while index >= 1 do 
			if orderedList[index].limitedAbility or not skillSetting.allowedStages[orderedList[index].sapien.sharedState.lifeStageIndex] then
				mj:log(skillSetting.key .. " removed from " .. orderedList[index].sapien.sharedState.name)
				local uniqueID = orderedList[index].sapien.uniqueID
				table.insert(tempRoles[uniqueID].removed, skillTypeIndex)
				table.remove(orderedList, index)
			end
			
			index = index - 1
		end
		
		
		local maxValue = getAbsMaxValue(skillSetting)
					
		--mj:log("Removing extra sapiens from role")
		while #orderedList > maxValue do
			mj:log(skillSetting.key .. " removed from " .. orderedList[#orderedList].sapien.sharedState.name)
			local uniqueID = orderedList[#orderedList].sapien.uniqueID
			table.insert(tempRoles[uniqueID].removed, skillTypeIndex)
			table.remove(orderedList)
		end
	end
	


	-- add sapiens to roles to satisfy the minimum
	-- we iterate through all skills so to distribute traits instead of filling one skill before moving on and not leave good traits for other skills
	-- skills that have a lot of sapiens missing to satisfy the minimum are prioritized over others
	local function fillMissingRoles(orderedSettings)

		table.sort(orderedSettings, function(a,b) return a.nbMissing > b.nbMissing end)

		while orderedSettings[1].nbMissing >= 1 do		
			
			for i = 1, #orderedSettings do 
				local skillTypeIndex = orderedSettings[i].skillTypeIndex
				local nbMissing = orderedSettings[i].nbMissing
				local nextNbMissing = nil
				
				if (i+1) <= #orderedSettings then
					nextNbMissing = orderedSettings[i+1].nbMissing
				end
				
				--mj:log(string.format("Filling roles for %s. nbMissing = %d", orderedSettings[i].setting.key, nbMissing))
				
				if nbMissing >= 1 then 
					local candidates = getOrderedCandidatesList(skillTypeIndex, orderedSettings[i].setting)
					--mj:log(string.format("Found %d candidates", #candidates))
					
					if #candidates == 0 then
						nbMissing = 0
					else
					
						for c = 1, #candidates do 
							table.insert(tempRoles[candidates[c].sapien.uniqueID].allRoles, skillTypeIndex)
							
							if skill:priorityLevel(candidates[c].sapien, skillTypeIndex) ~= 1 then
								mj:log(orderedSettings[i].setting.key .. " added to " .. candidates[c].sapien.sharedState.name)
								table.insert(tempRoles[candidates[c].sapien.uniqueID].added, skillTypeIndex)
							end
							
							nbMissing = nbMissing - 1
							
							if nbMissing == 0 or (nextNbMissing and nbMissing < nextNbMissing) then
								break
							end
						end
					end
					
					orderedSettings[i].nbMissing = nbMissing
				end
			end
			
			table.sort(orderedSettings, function(a,b) return a.nbMissing > b.nbMissing end)
		end
	end
	
	local minOrderedSettings = {}
	for sti, skillSetting in pairs(automatedSettings) do 
		table.insert(minOrderedSettings, { 
			skillTypeIndex = sti, 
			setting = skillSetting, 
			nbMissing = getAbsMinValue(skillSetting) - getNewAssignedSapiensCount(sti)
			})
	end
	
	--mj:log("Satisfying minimums")
	fillMissingRoles(minOrderedSettings)
		
	--- we redo the same step as before to distribute all remaining roles up to the max value 
	
	local maxOrderedSettings = {}
	for sti, skillSetting in pairs(automatedSettings) do 
		table.insert(maxOrderedSettings, { 
			skillTypeIndex = sti, 
			setting = skillSetting, 
			nbMissing = getAbsMaxValue(skillSetting) - getNewAssignedSapiensCount(sti)
			})
	end
	
	--mj:log("Satisfying maximum")
	fillMissingRoles(maxOrderedSettings)
	
	--- finally, we remove all skills that aren't assigned anymore
	--mj:log("Removing switched roles")
	for uniqueID, tempInfo in pairs(tempRoles) do
		for skillTypeIndex, skillSetting in pairs(automatedSettings) do 
			if not hasSkill(tempInfo, skillTypeIndex) and not isSkillRemoved(tempInfo, skillTypeIndex) and skill:priorityLevel(allFollowers[uniqueID], skillTypeIndex) == 1 then 
				mj:log(skill.types[skillTypeIndex].key .. " removed from " .. allFollowers[uniqueID].sharedState.name)
				table.insert(tempInfo.removed, skillTypeIndex)
			end
		end
	end
	
	--mj:log("Roles analysis finished")
end

local function processTempRoles()
	for uniqueID, tempInfo in pairs(tempRoles) do 
		for i = 1, #tempInfo.removed do
			playerSapiens:setSkillPriority(uniqueID, tempInfo.removed[i], 0)
		end
		
		for i = 1, #tempInfo.added do 
			playerSapiens:setSkillPriority(uniqueID, tempInfo.added[i], 1)
		end
	end
end

local function loadSkillSettings()
	local clientWorldSettingsDatabase = world:getClientWorldSettingsDatabase()
	
	skillSettings = clientWorldSettingsDatabase:dataForKey(databaseKey)
	
	return skillSettings
end
		
function automatedRoles:reassignAll()
	--mj:log("automatedRoles:reassignAll - start")
	
	loadSkillSettings()
	allFollowers = playerSapiens:getFollowerInfos()
	tempRoles = {}
	
	fillTempRoles()
	processTempRoles()	
		
	--mj:log("automatedRoles:reassignAll - end")
end

function automatedRoles:getSkillSettings()
	return skillSettings
end

function automatedRoles:init(world_, playerSapiens_)
	mj:log("AutomatedRoles - init")
	
    world = world_
	playerSapiens = playerSapiens_
		
	skillSettings = loadSkillSettings()
		
	if not skillSettings then
		mj:log("Skill Settings are initializing for the first time")
		skillSettings = {}
		
		for i, skillType in ipairs(skill.validTypes) do
			if not skillSettings[skillType.index] then
				skillSettings[skillType.index] = {
					key = skillType.key,
					index = skillType.index,
					automationEnabled = false,
					automationType = "abs", --- abs for absolute or prc for percentage
					allowedStages = {},
					minValue = 0,
					maxValue = 100
				}
			end
		end
		
		automatedRoles:saveSkillSettings(skillSettings)
	end
	
	mj:log("AutomatedRoles - init finished")
end

function automatedRoles:saveSkillSettings(skillSettings_)
	skillSettings = skillSettings_
	
	local clientWorldSettingsDatabase = world:getClientWorldSettingsDatabase()
	clientWorldSettingsDatabase:setDataForKey(skillSettings, databaseKey)
	
	mj:log("SKILL SETTINGS SAVED")
	--mj:log(skillSettings)
end

return automatedRoles