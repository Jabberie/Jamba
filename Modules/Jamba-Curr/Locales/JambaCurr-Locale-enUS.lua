--[[
Jamba - Jafula's Awesome Multi-Boxer Assistant
Copyright 2008 - 2018 Michael "Jafula" Miller
License: The MIT License
]]--

local L = LibStub( "AceLocale-3.0" ):NewLocale( "Jamba-Curr", "enUS", true )
L["Slash Commands"] = true
L["Toon: Warnings"] = true
L["Push Settings"] = true
L["Push the toon settings to all characters in the team."] = true
L["Settings received from A."] = function( characterName )
	return string.format( "Settings received from %s.", characterName )
end
L["Toon"] = true
L[": "] = true
L["Currency"] = true
L["CurrencyName"] = true
L["CurrencyID"] = true
L["Currency One"] = true
L["Currency Two"] = true
L["Currency Three"] = true
L["Currency Four"] = true
L["Currency Five"] = true
L["Currency Six"] = true

L["CurrOne"] = true
L["CurrTwo"] = true
L["CurrThree"] = true
L["CurrFour"] = true
L["CurrFive"] = true
L["CurrSix"] = true
L["Show Currency"] = true
L["Show the current toon the currency values for all members in the team."] = true
L["Blizzard Tooltip"] = true
L["Blizzard Dialog Background"] = true
L["Curr"] = true
L["Jamba Currency"] = true
L["Update"] = true
L["Gold"] = true
L["Include Gold In Guild Bank"] = true
L["Total"] = true
L["Guild"] = true
L[" ("] = true
L[")"] = true
L["Currency Selection"] = true
L["Scale"] = true
L["Transparency"] = true
L["Border Style"] = true
L["Border Colour"] = true
L["Background"] = true
L["Background Colour"] = true
L["Appearance & Layout"] = true
L["Arial Narrow"] = true
L["Font"] = true
L["Font Size"] = true
L["Space For Name"] = true
L["Space For Gold"] = true
L["Space For Points"] = true
L["Space Between Values"] = true
L["Lock Currency List"] = true
L["Open Currency List On Start Up"] = true
L["Hide Currency"] = true
L["Hide the currency values for all members in the team."] = true
L[" "] = true --space character




--Help Tooltips

L["Shows the minions Gold"] = true
L["Show Gold In Guild Bank\n\nThis does not update unless you visit the guildbank."] = true
L["Shows Currency on The Currency display window."] = true
L["You can change the Currency ID here.\n\nFor a list of ID's\nhttp://www.wowhead.com/currencies"] = true
L["Show Currency Window"] = true
L["Open Currency List On Start Up.\n\nThe Master Minion Only)"] = true
L["Lock Currency List\n\n(Enables Mouse Click-Through)"] = true