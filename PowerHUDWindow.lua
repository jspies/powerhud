local GeminiPackages = _G["GeminiPackages"]

------------------------------------------------------------------
-- SimpleHUD Window
------------------------------------------------------------------

----- constants
local kProgressType = 1
local kHealthShieldType = 2
local kBuffType = 3
local kPercentageType = 4

local SimpleHUDWindow = {}

-- this class enables the user to create their own custom HUDs
-- contains a window and its own config
function SimpleHUDWindow:new()
	o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here
	self.config = {}
	self.type = kProgressType

    return o
end

function SimpleHUDWindow:CreateWindow(nType)
	-- types supportes: progress_bar, percentage, health
	if nType == kHealthShieldType then
		self.type = kHealthShieldType
		self.window = Apollo.LoadForm("HealthHUD.xml", "HealthForm", nil, self)
	end
end

function SimpleHUD:OnEnterCombat()
	
end

function SimpleHUDWindow:OnFrame()
	if self.type == kHealthShieldType then
		self:OnHealthShieldFrame()
	end
end

function SimpleHUDWindow:OnHealthShieldFrame()
	local unitPlayer = GameLib.GetPlayerUnit()
	local nHealth = unitPlayer:GetHealth()
	local nHealthMax = unitPlayer:GetMaxHealth()
	local wndHealthBar = self.window:FindChild("HealthBar")
	wndHealthBar:SetFloor(0)
	wndHealthBar:SetMax(nHealthMax)
	wndHealthBar:SetProgress(nHealth)
	local nHealthHeight = wndHealthBar:GetHeight()

	local nHealthLeft, nHealthTop, nHealthRight, nHealthBottom = wndHealthBar:FindChild("HealthBar"):GetAnchorOffsets()
	 -- Shield Update
	local nShield = unitPlayer:GetShieldCapacity()
	local nShieldMax = unitPlayer:GetShieldCapacityMax()
	
	local nPositiveOffset = (nHealthHeight * (1 - nHealth/nHealthMax))

	local wndShieldBar = self.window:FindChild("ShieldBar")
	local nShieldHeight = wndShieldBar:GetHeight()
	local nLeft, nTop, nRight, nBottom = wndShieldBar:GetAnchorOffsets()
	wndShieldBar:SetAnchorOffsets(nLeft, nHealthTop - nShieldHeight - 1 + nPositiveOffset, nRight, nHealthTop - 1 + nPositiveOffset)
	
	wndShieldBar:SetFloor(0)
	wndShieldBar:SetMax(nShieldMax)
	wndShieldBar:SetProgress(nShield)
end

--------------------------------------------------------------------
-- SimpleHUDWindows -- A collection object for the windows
--------------------------------------------------------------------
local SimpleHUDWindows = {}
function SimpleHUDWindows:new()
	o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here
	self.aWindows = {}

    return o
end

function SimpleHUDWindows:OnFrame()
	self:ForEach(function(window)
		window:OnFrame()
	end)
end

function SimpleHUDWindows:ForEach(callMethod)
	for key, wndWindow in pairs(self.aWindows) do
		callMethod(wndWindow)
	end
end