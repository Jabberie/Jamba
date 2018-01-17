--[[
Jamba - Jafula's Awesome Multi-Boxer Assistant
Copyright 2008 - 2018 Michael "Jafula" Miller
License: The MIT License
]]--

local L = LibStub("AceLocale-3.0"):NewLocale( "Jamba-Sell", "enUS", true )
L["Slash Commands"] = true
L["Merchant"] = true
L["Sell: Greys"] = true
L["Push Settings"] = true
L["Push the sell settings to all characters in the team."] = true
L["Settings received from A."] = function( characterName )
	return string.format( "Settings received from %s.", characterName )
end
L["Are you sure you wish to remove the selected item from the auto sell poor items exception list?"] = true
L["Are you sure you wish to remove the selected item from the auto sell other items list?"] = true
L["I have sold: X"] = function( itemLink )
	return string.format( "I have sold: %s", itemLink )
end
L["I have deleted: X"] = function( itemLink )
	return string.format( "I have DELETED: %s", itemLink )
end
L["DID NOT SELL: X"] = function( itemLink )
	return string.format( "DID NOT SELL: %s", itemLink )
end
L["I have sold: X Items And Made:"] = function( count )
	return string.format( "I have sold: %s Items And Made: ", count )
end

L["Items"] = true
L["Sell: Others"] = true
--L["Sell Greys"] = true
L["Sell Others"] = true
--L["Auto Sell Poor Quality Items"] = true
--L["Except For These Poor Quality Items"] = true
--L["Add Exception"] = true
--L["Exception Item (drag item to box)"] = true
--L["Exception Tag"] = true
L["Remove"] = true
L["Add"] = true
L["Sell Others"] = true
L["Auto Sell Items"] = true
L["Other Item (drag item to box)"] = true
L["Other Tag"] = true
L["Message Area"] = true
L["Item tags must only be made up of letters and numbers."] = true
L["Add Other"] = true
L["Sell Messages"] = true
L["Sell Item On All Toons"] = true
L["Hold Alt While Selling An Item To Sell On All Toons"] = true
--L["PopOut"] = true
--L["Show the sell other settings in their own window."] = true
--L["Sell Unusable Soulbound Items"] = true
--L["Automatically Sell Unusable Soulbound Items"] = true
--L["On Characters With This Tag"] = true
L["Sell"] = true
--L["And Unusable Lower Tier Armour Soulbound Items"] = true

--New Stuff

L["Automatically Sell Items"] = true
L["Sell Items"] = true
L["Only SoulBound"] = true
L["Item Level"] = true
L["Sell Gray Items"] = true
L["Sell Green Items"] = true
L["Sell Rare Items"] = true
L["Sell Epic Items"] = true
