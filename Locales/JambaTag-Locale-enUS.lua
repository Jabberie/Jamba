--[[
Jamba - Jafula's Awesome Multi-Boxer Assistant
Copyright 2008 - 2018 Michael "Jafula" Miller
License: The MIT License
]]--

local L = LibStub("AceLocale-3.0"):NewLocale( "Jamba-Tag", "enUS", true )
L["Slash Commands"] = true
L["Team"] = true
L["Core: Tags"] = true
L["Add"] = true
L["Add a tag to the this character."] = true
L["Remove"] = true				
L["Remove a tag from this character."] = true
L["Push Settings"] = true
L["Push the tag settings to all characters in the team."] = true
L["Team List"] = true
L["Tag List"] = true
L["Enter a tag to add:"] = true
L["Are you sure you wish to remove %s from the tag list for %s?"] = true
L["Settings received from A."] = function( characterName )
	return "Settings received from "..characterName.."."
end
L["master"] = true
L["minion"] = true
L["all"] = true
L["justme"] = true
