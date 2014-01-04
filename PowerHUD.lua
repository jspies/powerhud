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
local SimpleHUDWindows
local glog 
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999
local kEngineerClassId = 2
local kHealthShieldType = 2

-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function PowerHUD:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self 

	SimpleHUDWindows = GeminiPackages:GetPackage("SimpleHUDWindows")

    -- initialize variables here
	self.config = self:Defaults()
	self.simpleHUDs = SimpleHUDWindows:new()
	
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
	
	GeminiPackages:Require("GeminiLogging-1.0", function(GeminiLogging)
		glog = GeminiLogging:GetLogger()
	end)
	
	
    -- Register handlers for events, slash commands and timer, etc.
    Apollo.RegisterSlashCommand("powerhud", "OnPowerHUDOn", self)
	Apollo.RegisterEventHandler("VarChange_FrameCount", "OnFrameUpdate", self)
	Apollo.RegisterEventHandler("UnitEnteredCombat", "OnEnterCombat", self)
	Apollo.RegisterTimerHandler("OutOfCombatTimer", "OnOutOfCombatTimer", self)

    -- load our forms
    self.wndResource = Apollo.LoadForm("PowerHUD.xml", "PowerHUDForm", nil, self)
	self.wndOptions = Apollo.LoadForm("PowerHUD.xml", "PowerHUDOptionsForm", nil, self)
	
	self.wndOptions:Show(false)
	
	self.simpleHUDs:CreateWindow(kHealthShieldType, "health")
	
	-- GeminiPosition handles boilerplate for windows you would like to save postion and restore
	-- here we are saving the customizable HUD elements
	GeminiPackages:Require("GeminiPosition", function(GP)
		GeminiPosition = GP:new()
		GeminiPosition:MakePositionable("rresource", self.wndResource)
	end)

	
    self.wndResource:Show(true)

end


-----------------------------------------------------------------------------------------------
-- PowerHUD Functions
-----------------------------------------------------------------------------------------------
-- Define general functions here

-- on SlashCommand "/powerhud"
function PowerHUD:OnPowerHUDOn(cmd, args)
	if string.len(args) == 0 then
		self:OnOptionsShow()
	elseif string.lower(args) == "lock" then
		self:ToggleLock(nil)
	elseif string.lower(args) == "reset" then
		self:ResetPositions()
	end	
end

function PowerHUD:OnToggleLock(wndHandler, wndControl, eMouseButton)
	self.simpleHUDs:ToggleLock()
end

function PowerHUD:OnEnterCombat(unitPlayer, bInCombat)
	if unitPlayer ~= GameLib.GetPlayerUnit() or not self.wndResource or not self.wndResource:IsValid() then
		return
	end
	
	self.bInCombat = bInCombat
	
	if bInCombat then
		self.wndResource:Show(true)
	else
		self.wndResource:Show(false)		
	end
	
	self.simpleHUDs:OnEnterCombat(bInCombat)
end

function PowerHUD:OnFrameUpdate()
	if not self.wndResource:IsValid() then
		return
	end
	
	self.simpleHUDs:OnFrame()
	
	local unitPlayer = GameLib.GetPlayerUnit()
	
	-- Resource Update
	local nResourceCurrent, nResourceMax
	-- Engineer Resource = Volatility enum EResources 1
	if unitPlayer:GetClassId() == kEngineerClassId then
		nResourceCurrent = unitPlayer:GetResource(1)
		nResourceMax = unitPlayer:GetMaxResource(1)
	else
		nResourceCurrent = unitPlayer:GetMana()
		nResourceMax = unitPlayer:GetMaxMana()
	end
	
	self.wndResource:FindChild("ResourceAmount"):SetText(tostring(math.floor((nResourceCurrent / nResourceMax * 100) + 0.5)) .. "%")
	
end

-----------------------------------------------------------------
-- Options Methods
-----------------------------------------------------------------

function PowerHUD:OnConfigure()
	self:OnOptionsShow()
end

-- Default settings used for config
function PowerHUD:Defaults()
	return {
		bLocked = true,
		tHealthBar = {
			bEnabled = true,
			bHideOoc = true
		},
		tResourceBar = {
			bEnabled = true,
			bHideOoc = true
		}
	}
end

function PowerHUD:OnOptionsShow()
	local bHealthOn = self.config.tHealthBar.bEnabled
	self.wndOptions:FindChild("HealthEnabledButton"):SetCheck(bHealthOn)
	self.wndOptions:FindChild("HealthSettings"):Enable(bHealthOn)
	self.wndOptions:FindChild("HealthOOCombatHide"):SetCheck(self.config.tHealthBar.bHideOoc)
	self.wndOptions:FindChild("LockCheck"):SetCheck(self.config.bLocked)
	
	self.wndOptions:Show(true)
end

function PowerHUD:OnSave(eLevel)
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character then
		return
	end
	local temp = {}
	temp["positions"] = GeminiPosition:PositionsForSave()
	temp["gpositions"] = self.simpleHUDs:GetPositions()
	temp["config"] = self.config
	return temp
end

function PowerHUD:OnRestore(eLevel, tData)
	GeminiPosition:RestorePositions(tData["positions"])
	self.config = tData["config"]
	if self.config == nil then -- possibly first time or data got wiped
		self.config = self:Defaults()
	end
	self.simpleHUDs:SetPositions(tData["gpositions"])
	self.simpleHUDs:ToggleLock(self.config.bLocked)
end

function PowerHUD:OnOptionsClose( wndHandler, wndControl, eMouseButton )
	self.wndOptions:Show(false)
end

function PowerHUD:ResetPositions()
	GeminiPosition:CenterPositions()
end


-----------------------------------------------------------------------------------------------
-- HealthSettings Functions
-----------------------------------------------------------------------------------------------

function PowerHUD:OnHealthOOCombatHideCheck( wndHandler, wndControl, eMouseButton )
	self.config.tHealthBar.bHideOoc = wndControl:IsChecked()
end


-----------------------------------------------------------------------------------------------
-- PowerHUD Instance
-----------------------------------------------------------------------------------------------
local PowerHUDInst = PowerHUD:new()
PowerHUDInst:Init()
