--[[
Jamba - Jafula's Awesome Multi-Boxer Assistant
Copyright 2008 - 2016 Michael "Jafula" Miller
License: The MIT License
]]--

local L = LibStub("AceLocale-3.0"):NewLocale( "Jamba-Proc", "enUS", true )
L["Slash Commands"] = true
L["Combat"] = true
L["Proc"] = true
L["Push Settings"] = true
L["Push the proc settings to all characters in the team."] = true
L["Settings received from A."] = function( characterName )
	return string.format( "Settings received from %s.", characterName )
end
L["Proc"] = true
L["Enable Jamba-Proc"] = true
L["Jamba Proc"] = true
L["Tag"] = true
L["Proc List"] = true
L["Proc Configuration"] = true
L["Display Text"] = true
L['Are you sure you wish to remove "%s" from the proc list?'] = true
L["Add"] = true
L["Remove"] = true
L["Save"] = true
L["The Art of War"] = true
L["Hot Streak"] = true
L["Missile Barrage"] = true
L["Fireball!"] = true
L["Clearcasting (Shaman)"] = true
L["Clearcasting (Druid)"] = true
L["Maelstrom Weapon"] = true
L["Elune's Wrath"] = true
L["Shadow Trance"] = true
L["Clearcasting (Mage)"] = true
L["Infusion of Light"] = true
L["Freezing Fog"] = true
L["Lock and Load"] = true
L["Eclipse (Lunar)"] = true
L["Eclipse (Solar)"] = true
L["Appearance & Layout"] = true
L["Proc Bar Texture"] = true
L["Proc Bar Font"] = true
L["Proc Bar Font Size"] = true
L["Proc Bar Width"] = true
L["Proc Bar Height"] = true
L["Proc Bar Spacing"] = true
L["Proc Duration (seconds)"] = true
L["Proc Colour"] = true
L["Proc Sound"] = true
L["Toon-Name-1"] = true
L["Toon-Name-2"] = true
L["Toon-Name-3"] = true
L["Enter the ID of the spell to add:"] = true -- Remove obsolete text around line 25 similar to this one (name instead of ID).
L["Spell ID"] = true -- Remove obsolete text around line 25 similar to this one (name instead of ID).
L["Enable Jamba Proc"] = true
L["Show Test Bars"] = true
L["Show Proc Bars Only On Master"] = true
L["Proc Information Text Displayed Here"] = true
L["Blizzard"] = true -- Default status bar texture, check what LibSharedMedia has for default for each language.
L["Friz Quadrata TT"] = true -- Default status bar font, check what LibSharedMedia has for default for each language.
L["None"] = true -- Default sound, check what LibSharedMedia has for default for each language.
L["Killing Machine"] = true
L["Fulmination!"] = true
L["Sword and Board"] = true
L["Taste for Blood"] = true
L["Power Torrent"] = true