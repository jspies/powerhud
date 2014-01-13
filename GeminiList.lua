local GeminiPackages = _G["GeminiPackages"]

local GeminiList = {}
local glog

function GeminiList:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self 

  -- initialize variables here
  GeminiPackages:Require("GeminiLogging-1.0", function(GeminiLogging)
    glog = GeminiLogging:GetLogger()
  end)

	return o
end

function GeminiList:Init(tOptions)
	self.wndItemList = tOptions.window
	self.strXmlFile = tOptions.xmlFile
	self.strItemTemplate = tOptions.itemTemplate
	self.OnSelectCallback = tOptions.onSelect
	self.children = {}
end

function GeminiList:AddItem(fCreateWindow)
	local itemWindow = Apollo.LoadForm(self.strXmlFile, self.strItemTemplate, self.wndItemList, self)
	fCreateWindow(itemWindow)
	self.children[#self.children] = itemWindow

	self.wndItemList:ArrangeChildrenVert()
end

function GeminiList:Update(window, fUpdateWindow)
	fUpdateWindow(window)
	self.wndItemList:ArrangeChildrenVert()
end

function GeminiList:OnItemSelect(wndHandler, wndControl)
 	if wndHandler ~= wndControl then
        return
    end
	local iId = wndControl:GetData()
	self.OnSelectCallback(iId)
end

GeminiPackages:NewPackage(GeminiList, "GeminiList", 1)