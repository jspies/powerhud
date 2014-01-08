local GeminiPackages = _G["GeminiPackages"]

------------------------------------------------------------------
-- SimpleHUD Window
------------------------------------------------------------------

----- constants
local kProgressType = 1
local kHealthShieldType = "healthshield"
local kBuffType = 3
local kPercentageType = 4
local glog
local SimpleHUDWindow = {}

-- this class enables the user to create their own custom HUDs
-- contains a window and its own config
function SimpleHUDWindow:new(o, tOptions)
	o = o or {}
	setmetatable(o, self)
	self.__index = self 

    -- initialize variables here
	self.config = {}
	self.config.bHideOoc = true
	self.config.bFadeAsOne = false
	self.type = tOptions.type
	self.name = tOptions.name

    return o
end

-- takes a GeminiPosition instance
function SimpleHUDWindow:CreateWindow(GP)

	if self.type == kHealthShieldType then
		self.window = Apollo.LoadForm("HealthHUD.xml", "HealthForm", nil, self)
	end
	
	GP:MakePositionable(self.name, self.window)
	self.window:Show(true)
	
	Apollo.RegisterTimerHandler("SimpleHUDOutOfCombatTimer", "OnOutOfCombatTimer", self)
end

------------------------------------------------------------------------------------
-- OnEnterCombat Callbacks
------------------------------------------------------------------------------------

function SimpleHUDWindow:DelayCombatCallback()
	Apollo.CreateTimer("SimpleHUDOutOfCombatTimer", 1, false)
end

function SimpleHUDWindow:OnOutOfCombatTimer()
	if self:CombatFadeRequirement() then
		if not self.config.bFadeAsOne then
			self.window:Show(false)
		end
	else
		self:DelayCombatCallback()
	end
end

function SimpleHUDWindow:CombatFadeRequirement()
	local unitPlayer = GameLib.GetPlayerUnit()
	local nShield = unitPlayer:GetShieldCapacity() / unitPlayer:GetShieldCapacityMax()
	local nHealth = unitPlayer:GetHealth() / unitPlayer:GetMaxHealth()
	return nShield >= 1 and nHealth >= 1	
end

------------------------------------------------------------------------------------
-- OnFrame callbacks
------------------------------------------------------------------------------------
function SimpleHUDWindow:OnFrame()
	if self.type == kHealthShieldType then
		self:OnHealthShieldFrame()
	end
end

-- this is a special type of window. can't be a progress bar since we want progress and shield in one
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

function SimpleHUDWindows:new(o)
	GeminiPackages:Require("GeminiLogging-1.0", function(GeminiLogging)
		glog = GeminiLogging:GetLogger()
	end)
	
	o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here
	self.tWindows = {}
	self.GeminiPosition = nil
	
	GeminiPackages:Require("GeminiPosition", function(GP)
		self.GeminiPosition = GP:new()
	end)

    return o
end

function SimpleHUDWindows:RestoreHUDs(tHuds)
	if tHuds == nil then
		return
	end
	
	for key, hudInfo in pairs(tHuds) do
		self:CreateWindow(hudInfo["type"], key)
	end
end

function SimpleHUDWindows:GetSaveableHUDs()
	local tHUDs = {}
	self:ForEach(function(hud)
		tHUDs[hud.name] = {
			type = hud.type
		}
	end)
	return tHUDs
end

function SimpleHUDWindows:CreateOrUpdateWindow(strName, tOptions)
	if self.tWindows[strName] == nil then -- create new one
		self.tWindows[strName] = SimpleHUDWindow:new(nil, tOptions)
		self.tWindows[strName]:CreateWindow(self.GeminiPosition)
	else -- update existing
	end
end

function SimpleHUDWindows:OnEnterCombat(bInCombat)
	self:ForEach(function(window)
		if bInCombat then
			window.window:Show(true)
		else
			if window.config.bHideOoc then
				window:DelayCombatCallback()
			end
		end
	end)
end

function SimpleHUDWindows:GetPositions()
	return self.GeminiPosition:PositionsForSave()
end

function SimpleHUDWindows:SetPositions(tPositions)
	self.GeminiPosition:RestorePositions(tPositions)
end

function SimpleHUDWindows:OnFrame()
	self:ForEach(function(window)
		window:OnFrame()
	end)
end

function SimpleHUDWindows:ToggleLock(bForce)
	self.GeminiPosition:ToggleLock(bForce, function(window, bIsLocked)
		--glog:info(window)
	end)
end

function SimpleHUDWindows:ForEach(callMethod)
	for key, wndWindow in pairs(self.tWindows) do
		callMethod(wndWindow)
	end
end

GeminiPackages:NewPackage(SimpleHUDWindows, "SimpleHUDWindows", 1)