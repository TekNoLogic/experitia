--[[
	eXPeritia
]]

local eXPeritia = CreateFrame("Frame", "eXPeritia", UIParent)

--[[ Default Configuration (used for first time ingame]]
defaults = {
	['Width'] = 640,			-- Width of bar
	['Height'] = 30,			-- Height of bar
	['Color'] = { r = .9, g = .5, b = 0 },	-- Indicator color
	['ClassColors'] = true		-- Use class colored indicators
}
eXPeritia:SetPoint("TOP", UIParent, "TOP", 0, -100)	-- Position of bar
--[[ Configuration end ]]

local LargeValue = function(value) 
	if(value > 999 or value < -999) then
		return string.format("|cffffffff%.0f|rk", value / 1e3) 
	else
		return "|cffffffff"..value.."|r"
	end 
end 

function eXPeritia:New()
	local bgleft = self:CreateTexture(nil, "BACKGROUND")
	bgleft:SetTexture([[Interface\AddOns\eXPeritia\bg-left]])
	bgleft:SetPoint("TOPLEFT", -4, 0)
	bgleft:SetPoint("BOTTOMRIGHT", self, "BOTTOM", 0, 0)
	self.bgLeft = bgleft
	
	local bgright = self:CreateTexture(nil, "BACKGROUND")
	bgright:SetTexture([[Interface\AddOns\eXPeritia\bg-right]])
	bgright:SetPoint("TOPRIGHT", 4, 0)
	bgright:SetPoint("BOTTOMLEFT", self, "BOTTOM", 0, 0)
	self.bgRight = bgright
	
	self.Indicator = self:NewIndicator(1)
	self.Last = self:NewIndicator(1)
	self.Rest = self:NewIndicator(1)
	
	local textPercent = self:CreateFontString(nil, "OVERLAY")
	textPercent:SetFont("Fonts\\FRIZQT__.TTF", 14)
	textPercent:SetPoint("LEFT", self.Indicator, 10, 0)
	textPercent:SetShadowOffset(1, -1)
	self.textPercent = textPercent
	
	local textAbsolute = self:CreateFontString(nil, "OVERLAY")
	textAbsolute:SetFont("Fonts\\FRIZQT__.TTF", 10)
	textAbsolute:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT", 0, 0)
	textAbsolute:SetShadowOffset(1, -1)
	self.textAbsolute = textAbsolute
	
	local textNeeded = self:CreateFontString(nil, "OVERLAY")
	textNeeded:SetFont("Fonts\\FRIZQT__.TTF", 10)
	textNeeded:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, 0)
	textNeeded:SetShadowOffset(1, -1)
	self.textNeeded = textNeeded
	
	self:SetMovable(true)
	self:SetScript("OnEvent", self.Update)
	self:RegisterEvent("PLAYER_XP_UPDATE")
	self:RegisterEvent("PLAYER_LEVEL_UP")
	self:RegisterEvent("PLAYER_LOGIN")
	
	self:Hide()
end

function eXPeritia:ApplyOptions()
	if(not eXPeritiaDB) then eXPeritiaDB = defaults else defaults = nil end
	if(not self.db) then self.db = eXPeritiaDB end

	local color
	if(self.db.ClassColor) then
		color = RAID_CLASS_COLORS[select(2, UnitClass("player"))]
	else
		color = self.db.Color
	end
	self.Indicator:SetHeight(self.db.Height)
	self.Last:SetHeight(self.db.Height/3)
	self.Rest:SetHeight(self.db.Height/3)

	self.Indicator:SetTexture(color.r, color.g, color.b)
	self.Last:SetTexture(color.r, color.g, color.b)
	self.Rest:SetTexture(color.r, color.g, color.b)
	self.textPercent:SetTextColor(color.r, color.g, color.b)
	self.textAbsolute:SetTextColor(color.r, color.g, color.b)
	self.textNeeded:SetTextColor(color.r, color.g, color.b)
	
	self:SetWidth(self.db.Width)
	self:SetHeight(self.db.Height)

	self:Update("noFade")
end

local min, max, rest, last

local fadeOut = { mode = "OUT", timeToFade = 10, finishedFunc = eXPeritia.Hide, finishedArg1 = eXPeritia }
local StartFadingOut = function()
	fadeOut.fadeTimer = 0
	fadeOut.finishedFunc = eXPeritia.Hide
	UIFrameFade(eXPeritia, fadeOut)
end
local fadeIn = { mode = "IN", timeToFade = 0.2 }

function eXPeritia:Update(event)
	if(event == "PLAYER_LOGIN") then return self:ApplyOptions() end

	min, max, rest = UnitXP("player"), UnitXPMax("player"), GetXPExhaustion()

	self:Move(self.Indicator, min/max)
	if(rest and rest > 0) then
		self.Rest:Show()
		self:Move(self.Rest, (min+rest)/max)
	else
		self.Rest:Hide()
	end
	
	self.textPercent:SetFormattedText("|cffffffff%.1f|r%%", min/max*100)
	self.textAbsolute:SetText(LargeValue(min-max))
	if(last and last ~= min) then
		self:Move(self.Last, last/max)
		self.textNeeded:SetFormattedText("|cffffffff%.0f|rx", (max-min)/(min-last))
	end
	if(last ~= min) then last = min end
	
	if(event~="noFade" and not self:IsShown()) then
		fadeIn.fadeTimer = 0
		fadeIn.finishedFunc = StartFadingOut
		UIFrameFade(self, fadeIn)
		self:Show()
	end
end

function eXPeritia:NewIndicator(width)
	local ind = self:CreateTexture(nil, "OVERLAY")
	ind:SetWidth(width)
	return ind
end

function eXPeritia:Move(ind, percent)
	ind:ClearAllPoints()
	ind:SetPoint("TOPLEFT", self.db.Width*percent, 0)
end

eXPeritia:New()
