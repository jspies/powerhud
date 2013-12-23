local GeminiPackages = _G["GeminiPackages"]

local PowerHUDWindow

-- this class enables the user to create their own custom HUDs
-- contains a window and its own config
function PowerHUDWindow:new()
	o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here
	self.config

    return o
end

function PowerHUDWindow:CreateWindow(sType)
	-- types supportes: progress_bar, percentage, health
	self.window = Apollo.LoadForm("HealthHUD.xml", "HealthForm", nil, self)
end
