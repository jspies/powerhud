-----------------------------------------------------------------------------------------------
-- Client Lua Script for PowerHUD
-----------------------------------------------------------------------------------------------
 
require "Window"
 
-----------------------------------------------------------------------------------------------
-- PowerHUD Module Definition
-----------------------------------------------------------------------------------------------
local PowerHUD = {} 
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999
 
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function PowerHUD:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here

    return o
end

function PowerHUD:Init()
    Apollo.RegisterAddon(self)
end
 

-----------------------------------------------------------------------------------------------
-- PowerHUD OnLoad
-----------------------------------------------------------------------------------------------
function PowerHUD:OnLoad()
    -- Register handlers for events, slash commands and timer, etc.
    -- e.g. Apollo.RegisterEventHandler("KeyDown", "OnKeyDown", self)
    Apollo.RegisterSlashCommand("powerhud", "OnPowerHUDOn", self)
	Apollo.RegisterEventHandler("VarChange_FrameCount", "OnFrameUpdate", self)
    
    -- load our forms
    self.wndMain = Apollo.LoadForm("PowerHUD.xml", "PowerHUDForm", nil, self)
	self.wndHealth = Apollo.LoadForm("PowerHUD.xml", "HealthForm", nil, self)
	
    self.wndMain:Show(true)
    self.wndHealth:Show(true)

end


-----------------------------------------------------------------------------------------------
-- PowerHUD Functions
-----------------------------------------------------------------------------------------------
-- Define general functions here

-- on SlashCommand "/powerhud"
function PowerHUD:OnPowerHUDOn()
	self.wndMain:Show(true) -- show the window
end

function PowerHUD:OnFrameUpdate()
	if not self.wndMain:IsValid() then
		return
	end
	
	local unitPlayer = GameLib.GetPlayerUnit()
	
	-- Resource Update
	local nResourceCurrent = unitPlayer:GetResource(1)
	local nResourceMax = unitPlayer:GetMaxResource(1)
	
	self.wndMain:FindChild("ResourceAmount"):SetText(tostring(nResourceCurrent / nResourceMax * 100) .. "%")
	
	-- Health Update
	local nHealth = unitPlayer:GetHealth()
	local nHealthMax = unitPlayer:GetMaxHealth()
	self.wndHealth:FindChild("HealthBar"):SetFloor(0)
	self.wndHealth:FindChild("HealthBar"):SetMax(nHealthMax)
	self.wndHealth:FindChild("HealthBar"):SetProgress(nHealth)

	
	 -- Shield Update
	local nShield = unitPlayer:GetShieldCapacity()
	local nShieldMax = unitPlayer:GetShieldCapacityMax()
	
	-- y = health bar height - (healthbarheight * (1 - health/healthmax))
	-- shield top = healthtop + y - shield height
	-- shield bottom = health top + y
	
	self.wndHealth:FindChild("ShieldBar"):SetFloor(0)
	self.wndHealth:FindChild("ShieldBar"):SetMax(nShieldMax)
	self.wndHealth:FindChild("ShieldBar"):SetProgress(nShield)

end


-----------------------------------------------------------------------------------------------
-- PowerHUDForm Functions
-----------------------------------------------------------------------------------------------
-- when the OK button is clicked
function PowerHUD:OnOK()
	self.wndMain:Show(false) -- hide the window
end

-- when the Cancel button is clicked
function PowerHUD:OnCancel()
	self.wndMain:Show(false) -- hide the window
end


-----------------------------------------------------------------------------------------------
-- PowerHUD Instance
-----------------------------------------------------------------------------------------------
local PowerHUDInst = PowerHUD:new()
PowerHUDInst:Init()
