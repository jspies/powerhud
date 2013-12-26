local GeminiPackages = _G["GeminiPackages"]

local GeminiPosition = {}
local glog 

function GeminiPosition:new(o)
	o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here
	self.Positionables = {}
	self.bIsLocked = true
	
	GeminiPackages:Require("GeminiLogging-1.0", function(GeminiLogging)
		glog = GeminiLogging:GetLogger()
	end)
    return o
end

function GeminiPosition:MakePositionable(key, tWindow)
	if self.Positionables == nil then
		self.Positionables = {}
	end
	
	local form = Apollo.LoadForm("GeminiPositionable.xml", "GeminiPositionableUnlockForm", tWindow, self)
	form:SetAnchorPoints(0,0,1,1)
	form:SetAnchorOffsets(0,0,0,0)

	self.Positionables[key] = tWindow
end

function GeminiPosition:PositionsForSave()
	local positions = {}
	for key, value in pairs(self.Positionables) do
		local position = {}
		position["l"], position["t"], position["r"], position["b"] = value:GetAnchorOffsets()
		positions[key] = position
	end
	return positions
end

function GeminiPosition:RestorePositions(positions)
	if positions == nil then
		return
	end
	
	for key, position in pairs(positions) do
		self.Positionables[key]:SetAnchorOffsets(position["l"], position["t"], position["r"], position["b"])
	end
end

-- Sets all positionables to the center of the screen.
-- Useful when the user wants to reset or when the addon is first used
function GeminiPosition:CenterPositions()
	local tSize = Apollo.GetDisplaySize()
	local nHCenter = tSize.nWidth / 2 -- horiz center of the screen
	local nVCenter = tSize.nHeight / 2 -- vertical center of the screen

	self:ForEachPositionable(function(positionable)
		positionable:SetAnchorOffsets(
			nHCenter - positionable:GetWidth() / 2,
			nVCenter - positionable:GetHeight() / 2,
			nHCenter + positionable:GetWidth() / 2,
			nVCenter + positionable:GetHeight() / 2
		)
	end)
end

-- Toggles the Lock State and the UI
-- bForce is used to force a lock or unlock. Leave nil to toggle based on inner state
function GeminiPosition:ToggleLock(bForce, callback)
	if not (bForce == nil) then
		self.bIsLocked = not bForce -- set to not bForce because we are about to toggle it
	end
	
	if self.bIsLocked then
		self:Unlock(callback)
	else
		self:Lock(callback)
	end
end

-- Locks all Positionable Windows and removes "editing" UI elements
function GeminiPosition:Lock(callback)
	self.bIsLocked = not self.bIsLocked
	self:ForEachPositionable(function(positionable)
		positionable:SetStyle("Moveable", false)
		local form = positionable:FindChild("GeminiPositionableUnlockForm")
		if form then
			form:Show(false)
		end
		callback(positionable, self.bIsLocked)
	end)
end

function GeminiPosition:Unlock(callback)
	self.bIsLocked = not self.bIsLocked
	self:ForEachPositionable(function(positionable)
		positionable:SetStyle("Moveable", true)
		local form = positionable:FindChild("GeminiPositionableUnlockForm")
		if form then
			form:Show(true)
		end
		callback(positionable, self.bIsLocked)
	end)
end

-- iterates each positionable and runs the specified function
function GeminiPosition:ForEachPositionable(callMethod)
	local count = 0
	for key, positionable in pairs(self.Positionables) do
		count = count + 1
		glog:info(key)
		callMethod(positionable)
	end
	glog:info("the count is " .. tostring(count))
end

GeminiPackages:NewPackage(GeminiPosition, "GeminiPosition", 1)