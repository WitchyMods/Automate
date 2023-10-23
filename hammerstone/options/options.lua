local options = {
	configKey = "witchyAutomate",
	listener = function(optionKey, newValue) mj:log("WITCHY!! option changed: ", optionKey, " newValue=", newValue) end,
	options = {
		autoRecruit = {
			order = 1,
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
				}
			}
		},
		autoFertilize = {
			order = 2,
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