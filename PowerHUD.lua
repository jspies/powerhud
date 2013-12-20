-----------------------------------------------------------------------------------------------
-- Client Lua Script for PowerHUD
-----------------------------------------------------------------------------------------------
 
require "Window"
 
-----------------------------------------------------------------------------------------------
-- PowerHUD Module Definition
-----------------------------------------------------------------------------------------------
local PowerHUD = {} 

local GeminiPackages = _G["GeminiPackages"]
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
    Apollo.RegisterAddon(self)
end
 

-----------------------------------------------------------------------------------------------
-- PowerHUD OnLoad
-----------------------------------------------------------------------------------------------
function PowerHUD:OnLoad()

	GeminiPackages:Require("GeminiLogging-1.0", function(GeminiLogging)
		glog = GeminiLogging:GetLogger()
	end)
    -- Register handlers for events, slash commands and timer, etc.
    -- e.g. Apollo.RegisterEventHandler("KeyDown", "OnKeyDown", self)
    Apollo.RegisterSlashCommand("powerhud", "OnPowerHUDOn", self)
	Apollo.RegisterEventHandler("VarChange_FrameCount", "OnFrameUpdate", self)
	Apollo.RegisterEventHandler("UnitEnteredCombat", "OnEnterCombat", self)
    
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

function PowerHUD:OnSave(eLevel)
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character then
		return
	end
	
	local temp = {}
	local resource = {}
	resource["l"], resource["t"], resource["r"], resource["b"] = self.wndMain:GetAnchorOffsets()
	temp["wndMainOffsets"] = resource
	
	local health = {}
	health["l"], health["t"], health["r"], health["b"] = self.wndHealth:GetAnchorOffsets()
	temp["wndHealthOffsets"] = health
	
	return temp
end

function PowerHUD:OnRestore(eLevel, tData)
	if tData ~= nil and tData["wndMainOffsets"] ~= nil then
		offsets = tData["wndMainOffsets"]
		self.wndMain:SetAnchorOffsets(offsets["l"], offsets["t"], offsets["r"], offsets["b"])
	end
	
	if tData ~= nil and tData["wndHealthOffsets"] ~= nil then
		offsets = tData["wndHealthOffsets"]
		self.wndMain:SetAnchorOffsets(offsets["l"], offsets["t"], offsets["r"], offsets["b"])
	end
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
