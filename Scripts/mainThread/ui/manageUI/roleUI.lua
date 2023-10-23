local shadow = mjrequire "hammerstone/utils/shadow"
local automatedRolesUI = mjrequire "automate/automatedRolesUI"


local roleUI = {}

function roleUI:init(super, gameUI, world_, manageUI_, hubUI, contentView)
	automatedRolesUI:init(self, contentView)

	super(self, gameUI, world_, manageUI_, hubUI, contentView)
end

function roleUI:update(super)
	super(self)
	automatedRolesUI:hide()
end

function roleUI:selectTask(super, skillTypeIndex)
	automatedRolesUI:hide()
	super(self, skillTypeIndex)
end

return shadow:shadow(roleUI)