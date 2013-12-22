local GeminiPosition = {}

function GeminiPosition:MakePositionable(tWindow)
	if self.Positionables == nil then
		self.Positionables = {}
	end
	
	self.Positionables[#self.Positionables] = tWindow
	
end

function GeminiPositionMeta:SavePositions()
end

function GeminiPositionMeta:GetPositions()
end