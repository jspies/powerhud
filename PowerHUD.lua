-----------------------------------------------------------------------------------------------
-- Client Lua Script for PowerHUD
-----------------------------------------------------------------------------------------------
 
require "Window"
 
-----------------------------------------------------------------------------------------------
-- PowerHUD Module Definition
-----------------------------------------------------------------------------------------------
local PowerHUD = {} 

local GeminiPackages = _G["GeminiPackages"]
local GeminiPosition
local glog 
 
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
    Apollo.RegisterAddon(self, true)
	
end
 

-----------------------------------------------------------------------------------------------
-- PowerHUD OnLoad
-----------------------------------------------------------------------------------------------
function PowerHUD:OnLoad()
	-- store config variables for customization and options page
	self.config = {
		bHealthBarEnabled = true,
		bResourceBarEnabled = true,
		bHideOutOfCombat = true
	}

	GeminiPackages:Require("GeminiLogging-1.0", function(GeminiLogging)
		glog = GeminiLogging:GetLogger()
	end)
	
    -- Register handlers for events, slash commands and timer, etc.
    Apollo.RegisterSlashCommand("powerhud", "OnPowerHUDOn", self)
	Apollo.RegisterEventHandler("VarChange_FrameCount", "OnFrameUpdate", self)
	Apollo.RegisterEventHandler("UnitEnteredCombat", "OnEnterCombat", self)

	
    -- load our forms
    self.wndMain = Apollo.LoadForm("PowerHUD.xml", "PowerHUDForm", nil, self)
	self.wndHealth = Apollo.LoadForm("HealthHUD.xml", "HealthForm", nil, self)
	self.wndOptions = Apollo.LoadForm("PowerHUD.xml", "PowerHUDOptionsForm", nil, self)
	self.wndOptions:Show(false)
	
	-- GeminiPosition handles boilerplate for windows you would like to save postion and restore
	-- here we are saving the customizable HUD elements
	GeminiPackages:Require("GeminiPosition", function(GP)
		GeminiPosition = GP:new()
		GeminiPosition:MakePositionable("resource", self.wndMain)
		GeminiPosition:MakePositionable("health", self.wndHealth)
	end)

	
    self.wndMain:Show(true)
    self.wndHealth:Show(true)

	self:Lock()

end


-----------------------------------------------------------------------------------------------
-- PowerHUD Functions
-----------------------------------------------------------------------------------------------
-- Define general functions here
function PowerHUD:Lock()
	self.bIsLocked = true
	GeminiPosition:Lock(function(window)
		window:SetStyle("Picture", true)
	end)
end

function PowerHUD:Unlock()
	GeminiPosition:Unlock(function(window)
		window:SetStyle("Picture", false)
	end)
	self.wndMain:Show(true) -- show the window
	self.wndHealth:Show(true) -- show the window

	self.bIsLocked = false

end

-- on SlashCommand "/powerhud"
function PowerHUD:OnPowerHUDOn(cmd, args)
	if string.len(args) == 0 then
		--self:ShowOptionsWindow()
	elseif string.lower(args) == "lock" then
		if self.bIsLocked == true then
			self:Unlock()
		else
			self:Lock()
		end
	end
	
end


function PowerHUD:OnEnterCombat(unitPlayer, bInCombat)
	if unitPlayer ~= GameLib.GetPlayerUnit() or not self.wndMain or not self.wndMain:IsValid() then
		return
	end
	
	if bInCombat then
		self.wndHealth:Show(true)
		self.wndMain:Show(true)
	else
		self.wndHealth:Show(false)
		self.wndMain:Show(false)
	end
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
	local wndHealthBar = self.wndHealth:FindChild("HealthBar")
	wndHealthBar:SetFloor(0)
	wndHealthBar:SetMax(nHealthMax)
	wndHealthBar:SetProgress(nHealth)
	local nHealthHeight = wndHealthBar:GetHeight()

	local nHealthLeft, nHealthTop, nHealthRight, nHealthBottom = self.wndHealth:FindChild("HealthBar"):GetAnchorOffsets()
	 -- Shield Update
	local nShield = unitPlayer:GetShieldCapacity()
	local nShieldMax = unitPlayer:GetShieldCapacityMax()
	
	local nPositiveOffset = (nHealthHeight * (1 - nHealth/nHealthMax))

	local wndShieldBar = self.wndHealth:FindChild("ShieldBar")
	local nShieldHeight = wndShieldBar:GetHeight()
	local nLeft, nTop, nRight, nBottom = wndShieldBar:GetAnchorOffsets()
	wndShieldBar:SetAnchorOffsets(nLeft, nHealthTop - nShieldHeight - 1 + nPositiveOffset, nRight, nHealthTop - 1 + nPositiveOffset)
	
	self.wndHealth:FindChild("ShieldBar"):SetFloor(0)
	self.wndHealth:FindChild("ShieldBar"):SetMax(nShieldMax)
	self.wndHealth:FindChild("ShieldBar"):SetProgress(nShield)

end

function PowerHUD:OnConfigure()
	self.wndOptions:Show(true)
end

function PowerHUD:OnSave(eLevel)
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character then
		return
	end
	
	local temp = {}
	
	
	temp["positions"] = GeminiPosition:PositionsForSave()
	
	
	return temp
end

function PowerHUD:OnRestore(eLevel, tData)
	
	GeminiPosition:RestorePositions(tData["positions"])
	
end


-----------------------------------------------------------------------------------------------
-- PowerHUDForm Functions
-----------------------------------------------------------------------------------------------



---------------------------------------------------------------------------------------------------
-- PowerHUDOptionsForm Functions
---------------------------------------------------------------------------------------------------

function PowerHUD:OnOptionsClose( wndHandler, wndControl, eMouseButton )
	self.wndOptions:Show(false)
end

-----------------------------------------------------------------------------------------------
-- PowerHUD Instance
-----------------------------------------------------------------------------------------------
local PowerHUDInst = PowerHUD:new()
PowerHUDInst:Init()
