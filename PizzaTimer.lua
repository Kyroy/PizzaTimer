-----------------------------------------------------------------------------------------------
-- Client Lua Script for PizzaTimer
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
require "Sound"
 
-----------------------------------------------------------------------------------------------
-- PizzaTimer Module Definition
-----------------------------------------------------------------------------------------------
local PizzaTimer = {} 
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999
 
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function PizzaTimer:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 
	o.time = 0
	o.run = false
	o.settings = {
		defaultTime = 10*60.0,
		posX = 10,
		posY = 10,
		sizeX = 230,
		sizeY = 110
	}

    -- initialize variables here

    return o
end

function PizzaTimer:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		-- "UnitOrPackageName",
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 

-----------------------------------------------------------------------------------------------
-- PizzaTimer OnLoad
-----------------------------------------------------------------------------------------------
function PizzaTimer:OnLoad()
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("PizzaTimer.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

-----------------------------------------------------------------------------------------------
-- PizzaTimer OnDocLoaded
-----------------------------------------------------------------------------------------------
function PizzaTimer:OnDocLoaded()

	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	    self.wndMain = Apollo.LoadForm(self.xmlDoc, "PizzaTimerForm", nil, self)
		if self.wndMain == nil then
			Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
			return
		end
		self.wndOption = Apollo.LoadForm(self.xmlDoc, "PizzaTimerForm", nil, self)
		if self.wndOption == nil then
			Apollo.AddAddonErrorText(self, "Could not load the option window for some reason.")
			return
		end

		
	    self.wndMain:Show(false, true)
		self.wndOption:Show(false, true)

		-- if the xmlDoc is no longer needed, you should set it to nil
		-- self.xmlDoc = nil
		
		-- Register handlers for events, slash commands and timer, etc.
		-- e.g. Apollo.RegisterEventHandler("KeyDown", "OnKeyDown", self)
		Apollo.RegisterSlashCommand("pizza", "OnPizzaTimerOn", self)

		self.timer = ApolloTimer.Create(0.500, true, "OnTimer", self)

		-- Do additional Addon initialization here
		if self.restoreData then
			self.settings.defaultTime = self.restoreData.defaultTime
			self.time = self.settings.defaultTime
			self.wndMain:FindChild("TimeBox"):SetText(self.settings.defaultTime/60)	
			self:updateTime()
			
			self.settings.posX = self.restoreData.posX
			self.settings.posY = self.restoreData.posY
			self.settings.sizeX= self.restoreData.sizeX
			self.settings.sizeY= self.restoreData.sizeY
			self.wndMain:SetAnchorOffsets(self.settings.posX, self.settings.posY, self.settings.posX+self.restoreData.sizeX, self.settings.posY+self.restoreData.sizeY)
		end
	end
end

-----------------------------------------------------------------------------------------------
-- PizzaTimer Functions
-----------------------------------------------------------------------------------------------
-- Define general functions here

-- on SlashCommand "/pizza"
function PizzaTimer:OnPizzaTimerOn()
	self.wndMain:Invoke() -- show the window
end

-- on timer
function PizzaTimer:OnTimer()
	if self.run then
		self.time = self.time - 0.5
		if self.time <= 0 then
			Sound.Play(Sound.PlayUIWindowAuctionHouseOpen)
			self.run = false
			self.time = self.settings.defaultTime
		end
		self:updateTime()
	end
end

function PizzaTimer:updateTime()
	if self.time%1 == 0 then
		local t = {}
		t[0] = math.floor(self.time/3600)
		t[1] = math.floor(self.time/60) - t[0]*60
		t[2] = math.floor(self.time) - t[1]*60 - t[0]*3600
		
		for i = 0, 2, 1 do
			if t[i] < 10 then
				t[i] = "0" .. t[i]
			end
		end
		
		self.wndMain:FindChild("TimeWindow"):SetText(t[0] .. ":" .. t[1] .. ":" .. t[2])
	end
end


-----------------------------------------------------------------------------------------------
-- PizzaTimerForm Functions
-----------------------------------------------------------------------------------------------

function PizzaTimer:OnCloseButton( wndHandler, wndControl, eMouseButton )
	self.wndMain:Close() -- hide the window
end

function PizzaTimer:OnOptionButton( wndHandler, wndControl, eMouseButton )
	self.wndOption:Invoke() -- show the window
end

function PizzaTimer:OnStartButton( wndHandler, wndControl, eMouseButton )
	if self.time and self.time > 0 then
		self.run = not self.run
	end
end

function PizzaTimer:OnResetButton( wndHandler, wndControl, eMouseButton )
	self.run = false
	self.time = self.settings.defaultTime
	self:updateTime()
end

function PizzaTimer:OnTimeWindowChanged( wndHandler, wndControl, strAnimDataId )
	local time = tonumber(self.wndMain:FindChild("TimeBox"):GetText())
	if time and time > 0 then
		self.settings.defaultTime = time*60
		if not self.run then
			self.time = self.settings.defaultTime
			self:updateTime()
		end
	else
		self.wndMain:FindChild("TimeBox"):SetText(self.settings.defaultTime/60)
		Print("Your time has to be a number in minutes greater 0.")
	end
end

function PizzaTimer:PizzaTimerFormDragDropEnd( wndHandler, wndControl, strType, iData, bDragDropHasBeenReset )
	local tmpX, tmpY
	self.settings.posX, self.settings.posY, tmpX, tmpY = self.wndMain:GetAnchorOffsets()
	self.settings.sizeX = tmpX - self.settings.posX
	self.settings.sizeY = tmpY - self.settings.posY
end

-----------------------------------------------------------------------------------------------
-- PizzaTimer Save/Restore
-----------------------------------------------------------------------------------------------
function PizzaTimer:OnSave(eLevel)
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character then
        return nil
    end
	return self.settings
end

function PizzaTimer:OnRestore(eLevel, tData)
	if tData then
		self.restoreData = tData
	end
end

-----------------------------------------------------------------------------------------------
-- PizzaTimer Instance
-----------------------------------------------------------------------------------------------
local PizzaTimerInst = PizzaTimer:new()
PizzaTimerInst:Init()
