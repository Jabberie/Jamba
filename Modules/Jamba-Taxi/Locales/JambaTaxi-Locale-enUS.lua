--[[
Jamba - Jafula's Awesome Multi-Boxer Assistant
Copyright 2008 - 2018 Michael "Jafula" Miller
License: The MIT License
]]--

local L = LibStub("AceLocale-3.0"):NewLocale( "Jamba-Taxi", "enUS", true )
L["Slash Commands"] = true
L["Toon"] = true
L["Taxi"] = true
L["Taxi Options"] = true
L["Take Teams Taxi"] = true
L["Request Taxi Stop with Master"] = true
L["Clones To Take Taxi After Master"] = true
L["Take the same flight as the any team member (Other Team Members must have NPC Flight Master window open)."] = true
L["Push Settings"] = true
L["Push the taxi settings to all characters in the team."] = true
L["I Have Requested a Stop From X"] = function( sender )
	return string.format( "I Have Requested a Stop From %s", sender )
end
L["Settings received from A."] = function( characterName )
	return "Settings received from "..characterName.."."
end
L["I am unable to fly to A."] = function( nodename )
	return "I am unable to fly to "..nodename.."."
end
L["Message Area"] = true
