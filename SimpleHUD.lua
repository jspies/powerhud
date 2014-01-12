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
local kEngineerClassId = 2
local kHealthShieldType = 2

local karHUDTypes = {}
karHUDTypes["healthshield"] = "Health/Shield Bar"
karHUDTypes["percentage"] = "Resource Percentage"
karHUDTypes["buff"] = "Buff Debuff Aura"


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

	self:CreateOptionsWindow()
	GeminiPackages:Require("GeminiList", function(GeminiList)
		self.GLItemList = GeminiList:new()
		self.GLItemList:Init({
			window = self.wndOptions:FindChild("HudsList"),
			onSelect = function(strName)
				self:LoadExistingEditForm(strName)
			end,
			xmlFile = "SimpleHUD.xml",
			itemTemplate = "HudListItem"
		})
	end)
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
	if unitPlayer ~= GameLib.GetPlayerUnit() then
		return
	end
	
	self.bInCombat = bInCombat
	
	self.simpleHUDs:OnEnterCombat(bInCombat)
end

function SimpleHUD:OnFrameUpdate()
	if self.tHudsToRestore ~= nil then
		self:RestoreHUDs()
	end
	self.simpleHUDs:OnFrame()	
	
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
	self.wndOptions:FindChild("LockCheck"):SetCheck(self.config.bLocked)
	
	self.wndOptions:Show(true)
end

function SimpleHUD:OnSave(eLevel)
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character then
		return
	end
	local temp = {}
	temp["huds"] = self.simpleHUDs:SerializeHuds()
	temp["config"] = self.config
	return temp
end

function SimpleHUD:OnRestore(eLevel, tData)
	self.config = tData["config"]
	if self.config == nil then -- possibly first time or data got wiped
		self.config = self:Defaults()
	end
	
	self.tHudsToRestore = tData["huds"] -- we store it to load later since not all of the xml files have been loaded
end

function SimpleHUD:RestoreHUDs()
	self.simpleHUDs:RestoreHUDs(self.tHudsToRestore)
	self.simpleHUDs:ToggleLock(self.config.bLocked)
	-- need to add to options list as well
	for index, hud in pairs(self.tHudsToRestore) do
		self.GLItemList:AddItem(function(window)
			window:SetText(hud.name)
		end)
	end
	self.tHudsToRestore = nil
end

function SimpleHUD:InitHUDList()
	self.wndHudList = self.wndOptions:FindChild('HudsView')
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
	local existingForm = wndEditView:FindChild("SimpleHUDEditForm")
	if existingForm ~= nil then
		existingForm:Destroy()
	end

	wndEditForm = Apollo.LoadForm("SimpleHUD.xml", "SimpleHUDEditForm", wndEditView, self)
	wndEditForm:FindChild("TypeDropdownList"):Show(false)
	
	for key, strType in pairs(karHUDTypes) do
		local wndItem = Apollo.LoadForm("SimpleHUD.xml", "DropdownItem", wndEditForm:FindChild("TypeDropdownList"), self)
		wndItem:FindChild("DropdownItemButton"):SetText(strType)
		wndItem:FindChild("DropdownItemButton"):SetData(key)
		wndItem:SetData(strType)
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
	local strType = wndEditView:FindChild("TypeDropdownButton"):GetData()
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
	self.GLItemList:AddItem(function(window)
		window:SetText(strName)
	end)
	wndEditView:FindChild("SimpleHUDEditForm"):Destroy()
end

function SimpleHUD:LoadExistingEditForm(strName)
	self:OnCreateNewHUD(nil, nil, nil)
	-- now need to populate all the fields
	local hud = self.simpleHUDs:GetHudByName(strName)
	local wndEditView = self.wndOptions:FindChild("EditView")
	wndEditView:FindChild("HudName"):SetText(hud.name)
	wndEditView:FindChild("TypeDropdownButton"):SetText(karHUDTypes[hud.type])
	wndEditView:FindChild("TypeDropdownButton"):SetData(hud.type)

	glog:info(hud)

end

---------------------------------------------------------------------------------------------------
-- DropdownItem Functions
---------------------------------------------------------------------------------------------------

function SimpleHUD:OnDropdownItemButton( wndHandler, wndControl, eMouseButton ) -- wndHandler is the Button.
	-- now we know the type the user selected. Load the appropriate settings
	local type = wndHandler:GetText()

	-- close the dropdown and set the text to the type
	local wndEditView = self.wndOptions:FindChild("EditView")
	wndEditView:FindChild("TypeDropdownList"):Show(false)
	wndEditView:FindChild("TypeDropdownButton"):SetText(type)
	wndEditView:FindChild("TypeDropdownButton"):SetData(wndHandler:GetData())
	
	-- Load the settings
	local strSettingsName = "SimpleHUD" .. "HealthShield" .. "Settings"
	local wndTypeSettings = Apollo.LoadForm("SimpleHUD.xml", strSettingsName, wndEditView:FindChild("TypeSettingsContainer"), self)
end

-----------------------------------------------------------------------------------------------
-- SimpleHUD Instance
-----------------------------------------------------------------------------------------------
local SimpleHUDInst = SimpleHUD:new()
SimpleHUDInst:Init()
