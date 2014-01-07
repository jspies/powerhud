-----------------------------------------------------------------------------------------------
-- Client Lua Script for SimpleHUD
-----------------------------------------------------------------------------------------------
 
require "Window"
 
-----------------------------------------------------------------------------------------------
-- SimpleHUD Module Definition
-----------------------------------------------------------------------------------------------
local SimpleHUD = {} 

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

local karHUDTypes = {
	"Health/Shield Bar",
	"Resource Percentage",
	"Buff Debuff Aura"
}

-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function SimpleHUD:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self 

	SimpleHUDWindows = GeminiPackages:GetPackage("SimpleHUDWindows")

    -- initialize variables here
	self.config = self:Defaults()
	self.simpleHUDs = SimpleHUDWindows:new()
	
	return o
end

function SimpleHUD:Init()
    Apollo.RegisterAddon(self, true)
end
 

-----------------------------------------------------------------------------------------------
-- SimpleHUD OnLoad
-----------------------------------------------------------------------------------------------
function SimpleHUD:OnLoad()
	-- store config variables for customization and options page
	
	GeminiPackages:Require("GeminiLogging-1.0", function(GeminiLogging)
		glog = GeminiLogging:GetLogger()
	end)
	
	
    -- Register handlers for events, slash commands and timer, etc.
    Apollo.RegisterSlashCommand("simplehud", "OnSimpleHUDOn", self)
	Apollo.RegisterEventHandler("VarChange_FrameCount", "OnFrameUpdate", self)
	Apollo.RegisterEventHandler("UnitEnteredCombat", "OnEnterCombat", self)
	Apollo.RegisterTimerHandler("OutOfCombatTimer", "OnOutOfCombatTimer", self)

    -- load our forms
    self.wndResource = Apollo.LoadForm("SimpleHUD.xml", "SimpleHUDForm", nil, self)
	self:CreateOptionsWindow()
		
	--self.simpleHUDs:CreateWindow(kHealthShieldType, "health")
	
	-- GeminiPosition handles boilerplate for windows you would like to save postion and restore
	-- here we are saving the customizable HUD elements
	GeminiPackages:Require("GeminiPosition", function(GP)
		GeminiPosition = GP:new()
		GeminiPosition:MakePositionable("rresource", self.wndResource)
	end)

	
    --self.wndResource:Show(true)

end


-----------------------------------------------------------------------------------------------
-- SimpleHUD Functions
-----------------------------------------------------------------------------------------------
-- Define general functions here
function SimpleHUD:CreateOptionsWindow()
	self.wndOptions = Apollo.LoadForm("SimpleHUD.xml", "SimpleHUDOptionsForm", nil, self)
	
	self.wndOptions:Show(false)
end

-- on SlashCommand "/simplehud"
function SimpleHUD:OnSimpleHUDOn(cmd, args)
	if string.len(args) == 0 then
		self:OnOptionsShow()
	elseif string.lower(args) == "lock" then
		self:ToggleLock(nil)
	elseif string.lower(args) == "reset" then
		self:ResetPositions()
	end	
end

function SimpleHUD:OnToggleLock(wndHandler, wndControl, eMouseButton)
	self.simpleHUDs:ToggleLock()
end

function SimpleHUD:OnEnterCombat(unitPlayer, bInCombat)
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

function SimpleHUD:OnFrameUpdate()
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

function SimpleHUD:OnConfigure()
	self:OnOptionsShow()
end

-- Default settings used for config
function SimpleHUD:Defaults()
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

function SimpleHUD:OnOptionsShow()
	local bHealthOn = self.config.tHealthBar.bEnabled
	self.wndOptions:FindChild("LockCheck"):SetCheck(self.config.bLocked)
	
	self.wndOptions:Show(true)
end

function SimpleHUD:OnSave(eLevel)
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character then
		return
	end
	local temp = {}
	temp["positions"] = GeminiPosition:PositionsForSave()
	temp["gpositions"] = self.simpleHUDs:GetPositions()
	temp["config"] = self.config
	return temp
end

function SimpleHUD:OnRestore(eLevel, tData)
	GeminiPosition:RestorePositions(tData["positions"])
	self.config = tData["config"]
	if self.config == nil then -- possibly first time or data got wiped
		self.config = self:Defaults()
	end
	self.simpleHUDs:RestoreHUDs(tData["huds"])
	self.simpleHUDs:SetPositions(tData["gpositions"])
	self.simpleHUDs:ToggleLock(self.config.bLocked)
end

function SimpleHUD:OnOptionsClose( wndHandler, wndControl, eMouseButton )
	self.wndOptions:Show(false)
end

function SimpleHUD:ResetPositions()
	GeminiPosition:CenterPositions()
end

---------------------------------------------------------------------------------------------------
-- SimpleHUDOptionsForm Functions
---------------------------------------------------------------------------------------------------

function SimpleHUD:OnCreateNewHUD( wndHandler, wndControl, eMouseButton )
	-- need to add the edit form to the view
	local wndEditView = self.wndOptions:FindChild("EditView")
	wndEditForm = Apollo.LoadForm("SimpleHUD.xml", "SimpleHUDEditForm", wndEditView, self)
	wndEditForm:FindChild("TypeDropdownList"):Show(false)
	
	for key, strType in pairs(karHUDTypes) do
		local wndHeader = Apollo.LoadForm("SimpleHUD.xml", "DropdownHeader", wndEditForm:FindChild("TypeDropdownList"), self)
		wndHeader:FindChild("DropdownHeaderText"):SetText(strType)
		wndHeader:SetData(strType)
	end
	wndEditForm:FindChild("TypeDropdownList"):ArrangeChildrenVert(0, function(a,b) return a:GetData() < b:GetData() end)
end

---------------------------------------------------------------------------------------------------
-- SimpleHUDEditForm Functions
---------------------------------------------------------------------------------------------------

function SimpleHUD:OnHUDTypeDropdownToggle( wndHandler, wndControl, eMouseButton )
	-- show the dropdown list
	local wndEditView = self.wndOptions:FindChild("EditView")
	wndEditView:FindChild("TypeDropdownList"):Show(true)
end

function SimpleHUD:OnHUDSettingsSave( wndHandler, wndControl, eMouseButton )
	-- user asked to save current settings pane
	-- we need name, type, Hide OOC and any special type settings
	local wndEditView = self.wndOptions:FindChild("EditView")
	local strName = wndEditView:FindChild("HudName"):GetText()
	local strType = wndEditView:FindChild("TypeDropdownButton"):GetText()
	local bOocHide = wndEditView:FindChild("HUDOOCombatHide"):IsChecked()
	local bIsVertical = true
	
	if strType == "Health Shield" then
		bIsVertical = wndEditView:FindChild("Vertical"):IsChecked()
	end
	
	-- now, add to simpleHUDs
	self.simpleHUDs:CreateOrUpdateWindow(strName, {
		name = strName,
		type = strType,
		oocHide = bOocHide,
		isVertical = bIsVertical
	})
end

---------------------------------------------------------------------------------------------------
-- DropdownItem Functions
---------------------------------------------------------------------------------------------------

function SimpleHUD:OnDropdownItemButton( wndHandler, wndControl, eMouseButton ) -- wndHandler is the Button. GetData is the string data
	-- now we know the type the user selected. Load the appropriate settings
	local type = wndHandler:GetData()
	
	-- close the dropdown and set the text to the type
	local wndEditView = self.wndOptions:FindChild("EditView")
	wndEditView:FindChild("TypeDropdownList"):Show(false)
	wndEditView:FindChild("TypeDropdownButton"):SetText(type)
	
	-- Load the settings
	local strSettingsName = "SimpleHUD" .. "HealthShield" .. "Settings"
	local wndTypeSettings = Apollo.LoadForm("SimpleHUD.xml", strSettingsName, wndEditView:FindChild("TypeSettingsContainer"), self)
end

-----------------------------------------------------------------------------------------------
-- SimpleHUD Instance
-----------------------------------------------------------------------------------------------
local SimpleHUDInst = SimpleHUD:new()
SimpleHUDInst:Init()
