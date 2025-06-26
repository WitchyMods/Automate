local options = {
	configKey = "witchyAutomate",
	listener = function(messages) 
				for i,message in ipairs(messages) do
					if message.optionKey == "overrideAutoRole" then
						mjrequire("automate/automate"):overrideAutomatedRolesOptionChanged(message.value)
					end
			    end
			end,
	options = {
		automateRoles = {
			order = 1,
			type = "group",
			options = {
				overrideAutoRole = {
					order = 1,
					type = "boolean",
					default_value = false
				}
			}
		},
		autoRecruit = {
			order = 2,
			type = "group", 
			options = {
				enableAutoRecruit = {
					order = 1,
					type = "boolean", 
					default_value = true
				}, 
				autoRecruitLimit = {
					order = 2, 
					type = "number",
					min = 0, 
					max = 200,
					default_value = 200,
					enable_on = "enableAutoRecruit"
				}, 
				prioritizeAutoRecruit = {
					order = 3,
					type = "boolean", 
					default_value = true
				}
			}
		},
		autoFertilize = {
			order = 3,
			type = "group",
			options = {
				enableAutoFertilize = {
					order = 1,
					type = "boolean", 
					default_value = true,
				}, 
				prioritizeAutoFertilize = {
					order = 2,
					type = "boolean",
					label = "Prioritize", 
					default_value = false,
					enable_on = "enableAutoFertilize"
				}
			}
		}
	}
}

return options