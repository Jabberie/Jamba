--[[
Jamba - Jafula's Awesome Multi-Boxer Assistant
Copyright 2008 - 2014 Michael "Jafula" Miller
License: All Rights Reserved
http://jafula.com/jamba/
]]--

local L = LibStub("AceLocale-3.0"):NewLocale( "Jamba-Taxi", "enUS", true )
L["Slash Commands"] = true
L["Toon"] = true
L["Taxi"] = true
L["Taxi Options"] = true
L["Take Master's Taxi"] = true
L["Take the same flight as the master did (minions's must have NPC Flight Master window open)."] = true
L["Push Settings"] = true
L["Push the taxi settings to all characters in the team."] = true
L["Settings received from A."] = function( characterName )
	return "Settings received from "..characterName.."."
end
L["I am unable to fly to A."] = function( nodename )
	return "I am unable to fly to "..nodename.."."
end
L["Message Area"] = true