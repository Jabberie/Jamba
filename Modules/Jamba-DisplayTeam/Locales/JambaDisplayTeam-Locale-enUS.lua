--[[
Jamba - Jafula's Awesome Multi-Boxer Assistant
Copyright 2008 - 2016 Michael "Jafula" Miller
License: The MIT License
]]--

local L = LibStub("AceLocale-3.0"):NewLocale( "JmbDspTm", "enUS", true )
L["Slash Commands"] = true
L["Team"] = true
L["Display: Team"] = true
L["Push Settings"] = true
L["Push the display team settings to all characters in the team."] = true
L["Settings received from A."] = function( characterName )
	return string.format( "Settings received from %s.", characterName )
end
L[" "] = true
L["("] = true
L[")"] = true
L[" / "] = true
L["%"] = true
L["Blizzard"] = true
L["Blizzard Tooltip"] = true
L["Blizzard Dialog Background"] = true
L["Show"] = true
L["Name"] = true
L["Level"] = true
L["Values"] = true
L["Percentage"] = true
L["Show Team List"] = true
L["Only On Master"] = true
L["Appearance & Layout"] = true
L["Stack Bars Vertically"] = true
L["Status Bar Texture"] = true
L["Border Style"] = true
L["Background"] = true
L["Scale"] = true
L["Show"] = true
L["Width"] = true
L["Height"] = true
L["Portrait"] = true
L["Follow Status Bar"] = true
L["Experience Bar"] = true
L["Health Bar"] = true
L["Power Bar"] = true
L["Alternate PowerBar"] = true
L["Jamba Team"] = true
L["Hide Team Display"] = true
L["Hide the display team panel."] = true
L["Show Team Display"] = true
L["Show the display team panel."] = true
L["Hide Team List In Combat"] = true
L["Enable Clique Support - **reload UI to take effect**"] = true
L["Transparency"] = true
L["Border Colour"] = true
L["Background Colour"] = true
L["Display Team List Horizontally"] = true
L["Show Team List Title"] = true
L["Bag Information"] = true
L["Only Show Free Bag Slots"] = true
L["Reputation Bar"] = true
L["Show Faction Name"] = true
L["No Faction Selected"] = true
L["Show Item Level"] = true
L["Equipped iLvl Only"] = true
L["Stack Text"] = true
L["DEAD"] = true


--new stuff
L["Toon Information"] = true
L["Player Level:"] = true
L["Item Level:"] = true
L["Bag Space:"] = true
L["Durability:"] = true
L["Gold:"] = true
L["Has New Mail From:"] = true
L["Currency:"] = true
L["Unknown Sender"] = true