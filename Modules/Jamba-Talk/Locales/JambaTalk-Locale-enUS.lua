--[[
Jamba - Jafula's Awesome Multi-Boxer Assistant
Copyright 2008 - 2018 Michael "Jafula" Miller
License: The MIT License
]]--

local L = LibStub("AceLocale-3.0"):NewLocale( "Jamba-Talk", "enUS", true )
L["Slash Commands"] = true
L["Chat"] = true
L["Talk"] = true
L["Push Settings"] = true
L["Push the talk settings to all characters in the team."] = true
L["Settings received from A."] = function( characterName )
	return string.format( "Settings received from %s.", characterName )
end
L["Talk Options"] = true
L["Forward Whispers To Master And Relay Back"] = true
L["Forward Using Normal Whispers"] = true
L["Chat Snippets"] = true
L["Remove"] = true
L["Snippet Text"] = true
L["Add"] = true
L["Enter the shortcut text for this chat snippet:"] = true
L["Are you sure you wish to remove the selected chat snippet?"] = true
L["<GM>"] = true
L["GM"] = true
L[" whispers: "] = true
L["Forward Via Fake Whispers For Clickable Links And Players"] = true
L["Enable Chat Snippets"] = true
L["(RealID)"] = true
L["Add Forwarder To Reply Queue On Master"] = true
L["Only Show Messages With Links"] = true
L["Add Originator To Reply Queue On Master"] = true
L["Send Fake Whispers To"] = true
L[" "] = true
L[" (via "] = true
L[")"] = true
L["Update"] = true
L["whispered you."] = true
L["Do Not Forward RealID Whispers"] = true
