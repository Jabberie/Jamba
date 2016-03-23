--[[
Jamba - Jafula's Awesome Multi-Boxer Assistant
Copyright 2008 - 2016 Michael "Jafula" Miller
License: The MIT License
]]--

local L = LibStub("AceLocale-3.0"):NewLocale( "Jamba-Target", "enUS", true )
L["all"] = true
L["Target Messages"] = true
L["Message Area"] = true
L["Slash Commands"] = true
L["Combat"] = true
L["Target"] = true
L["Push Settings"] = true
L["Push the target settings to all characters in the team."] = true
L["Settings received from A."] = function( characterName )
	return string.format( "Settings received from %s.", characterName )
end
L["Target Options"] = true
L["Jamba-Target"] = true
L["Targets To Hold"] = true
L[": "] = true
L["Macros"] = true
L["Target Macros"] = true
L["Mark Targets (Press & Hold)"] = true
L["Clear Target"] = true
L["Target 1 (Star)"] = true
L["Target 2 (Circle)"] = true
L["Target 3 (Diamond)"] = true
L["Target 4 (Triangle)"] = true
L["Target 5 (Moon)"] = true
L["Target 6 (Square)"] = true
L["Target 7 (Cross)"] = true
L["Target 8 (Skull)"] = true
L["Hold 1 (Star)"] = true
L["Hold 2 (Circle)"] = true
L["Hold 3 (Diamond)"] = true
L["Hold 4 (Triangle)"] = true
L["Hold 5 (Moon)"] = true
L["Hold 6 (Square)"] = true
L["Hold 7 (Cross)"] = true
L["Hold 8 (Skull)"] = true
L["Mark Targets With Raid Icons"] = true
L["Show Target List"] = true
L["The macro to use for each target.  Use #MOB# for the actual target."] = true
L["Macro for Target 1 (Star)"] = true
L["Macro for Target 2 (Circle)"] = true
L["Macro for Target 3 (Diamond)"] = true
L["Macro for Target 4 (Triangle)"] = true
L["Macro for Target 5 (Moon)"] = true
L["Macro for Target 6 (Square)"] = true
L["Macro for Target 7 (Cross)"] = true
L["Macro for Target 8 (Skull)"] = true
L["Tag for Target 1 (Star)"] = true
L["Tag for Target 2 (Circle)"] = true
L["Tag for Target 3 (Diamond)"] = true
L["Tag for Target 4 (Triangle)"] = true
L["Tag for Target 5 (Moon)"] = true
L["Tag for Target 6 (Square)"] = true
L["Tag for Target 7 (Cross)"] = true
L["Tag for Target 8 (Skull)"] = true
L["List Health Bars Width"] = true
L["List Health Bars Height"] = true
L["Hold Target Name"] = true
L["Do not track health for a particular unit.  Leave name in list for targeting purposes."] = true
L["Appearance & Layout"] = true
L["Transparency"] = true
L["Border Style"] = true
L["Border Colour"] = true
L["Background"] = true
L["Background Colour"] = true
L["Blizzard Tooltip"] = true
L["Blizzard Dialog Background"] = true
L["Scale"] = true