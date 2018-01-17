--[[
Jamba - Jafula's Awesome Multi-Boxer Assistant
Copyright 2008 - 2018 Michael "Jafula" Miller
License: The MIT License
]]--

local L = LibStub("AceLocale-3.0"):NewLocale( "Jamba-ItemUse", "enUS", true )
L["Slash Commands"] = true
L["Interaction"] = true
L["Item Use"] = true
L["Push Settings"] = true
L["Push the item use settings to all characters in the team."] = true
L["Settings received from A."] = function( characterName )
	return string.format( "Settings received from %s.", characterName )
end
L["Blizzard Tooltip"] = true
L["Blizzard Dialog Background"] = true
L["Item Use Options"] = true
L["Show Item Bar"] = true
L["Only On Master"] = true
L["Message Area"] = true
L["Items"] = true
L["Scale"] = true
L["Border Style"] = true
L["Background"] = true
L["Number Of Items"] = true
L["Appearance & Layout"] = true
L["Item Size"] = true
L["Messages"] = true
L["Hide Item Bar In Combat"] = true
L["Hide Item Bar"] = true
L["Hide the item bar panel."] = true
L["Show Item Bar"] = true
L["Show the item bar panel."] = true
L["Jamba-Item-Use"] = true
L["Item 1"] = true
L["Item 2"] = true
L["Item 3"] = true
L["Item 4"] = true
L["Item 5"] = true
L["Item 6"] = true
L["Item 7"] = true
L["Item 8"] = true
L["Item 9"] = true
L["Item 10"] = true
L["I do not have X."] = function( name )
	return string.format( "I do not have %s.", name )
end
L["Transparency"] = true
L["Border Colour"] = true
L["Background Colour"] = true
L["Item 11"] = true
L["Item 12"] = true
L["Item 13"] = true
L["Item 14"] = true
L["Item 15"] = true
L["Item 16"] = true
L["Item 17"] = true
L["Item 18"] = true
L["Item 19"] = true
L["Item 20"] = true
L["Automatically Add Quest Items To Bar"] = true
L["Keep Item Bars On Minions Synchronized"] = true
L["Number Of Rows"] = true
L["New item that starts a quest found!"] = true
L["Clear Item Bar"] = true
L["Clear the item bar (remove all items)."] = true
L["Hide Buttons"] = true
L["Item Bar Cleared"] = true
L["Automatically Add Artifact Power Items To Bar"] = true
L["Automatically Add Satchel Items To Bar"] = true
L["New Artifact Power Item found!"] = true

L["Clear"] = true
L["Clears items no longer in your bags"] = true
L["Sync"] = true
L["Synchronise Item-Use Buttons"] = true