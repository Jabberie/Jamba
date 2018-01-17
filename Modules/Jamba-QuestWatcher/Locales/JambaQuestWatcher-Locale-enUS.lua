--[[
Jamba - Jafula's Awesome Multi-Boxer Assistant
Copyright 2008 - 2018 Michael "Jafula" Miller
License: The MIT License
]]--

local L = LibStub("AceLocale-3.0"):NewLocale( "Jamba-QuestWatcher", "enUS", true )
L["Slash Commands"] = true
L["Quest"] = true
L["Quest: Watcher"] = true
L["Quest: Tracker"] = true
L["Quest Watcher"] = true
L["Push Settings"] = true
L["Push the quest settings to all characters in the team."] = true
L["Settings received from A."] = function( characterName )
	return string.format( "Settings received from %s.", characterName )
end
L["N/A"] = true
L["Update"] = true
L["Border Colour"] = true
L["Background Colour"] = true
L["<Map>"] = true
L["Lines Of Info To Display"] = true
L["Lines Of Info To Display (Reload UI To See Change)"] = true
L["Quest Watcher Width"] = true
L["Lines Of Info To Display (Reload UI To See Change)"] = true
L["DONE"] = true
L["Blizzard Tooltip"] = true
L["Blizzard Dialog Background"] = true
L["Arial Narrow"] = true
L["Font"] = true
L["Font Size"] = true
L["Border Style"] = true
L["Transparency"] = true
L["Scale"] = true
L["Background"] = true
L["Appearance & Layout"] = true
L["Show Quest Watcher"] = true
L["Show the quest watcher window."] = true
L["Hide Quest Watcher"] = true
L["Hide the quest watcher window."] = true
L["Send Message Area"] = true
L["Send Progress Messages To Message Area"] = true

--New Help system and changes.

L["Jamba Objective Tracker"] = true
L["Send Progress Messages To Message Area/Chat"] = true
L["Do Not Hide An Individuals Completed Objectives"] = true
L["Hide Objectives/Quests Completed By Team"] = true
L["Hide objectives Completed By Team"] = true
L["Show Completed objective As 'DONE'"] = true
L["Show Completed Objectives/Quests As 'DONE'"] = true
L["Hide JoT In Combat"] = true
L["Hide Jamba Objective Tracker in Combat"] = true
L["Olny shows Jamba Objective Tracker On Master Character Olny"] = true
L["Show JoT On Master Only"] = true 
L["Hide Blizzard's Objectives Tracker"] = true
L["Hides Defualt Objective Tracker"] = true
L["Unlock JoT"] = true
L["Unlocks Jamba Objective Tracker\n Hold Alt key To Move It\n Lock to Click Through"] = true
L["Enable JoT"] = true
L["Enables Jamba Objective Tracker"] = true
L["Olny show Jamba Objective Tracker On Master Character Olny"] = true
