local GeminiPackages = _G["GeminiPackages"]

local GeminiPosition = {}

function GeminiPosition:new()
	o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here
	self.Positionables = {}
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

GeminiPackages:NewPackage(GeminiPosition, "GeminiPosition", 3)