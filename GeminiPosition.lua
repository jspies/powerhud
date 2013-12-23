local GeminiPackages = _G["GeminiPackages"]

local GeminiPosition = {}

function GeminiPosition:new()
	o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here
	self.Positionables = {}
	self.bIsLocked = true
    return o
end

function GeminiPosition:MakePositionable(key, tWindow)
	if self.Positionables == nil then
		self.Positionables = {}
	end
	
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

-- Toggles the Lock State and the UI
function GeminiPosition:ToggleLock(callback)
	if self.bIsLocked == true then
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
		callback(positionable, self.bIsLocked)
	end)
end

function GeminiPosition:Unlock(callback)
	self.bIsLocked = not self.bIsLocked
	self:ForEachPositionable(function(positionable)
		positionable:SetStyle("Moveable", true)
		callback(positionable)
	end)
end

-- iterates each positionable and runs the specified function
function GeminiPosition:ForEachPositionable(callMethod)
	for key, positionable in pairs(self.Positionables) do
		callMethod(positionable)
	end
end

GeminiPackages:NewPackage(GeminiPosition, "GeminiPosition", 1)