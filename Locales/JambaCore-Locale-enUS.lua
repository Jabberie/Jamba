--[[
Jamba - Jafula's Awesome Multi-Boxer Assistant
Copyright 2008 - 2015 Michael "Jafula" Miller
License: The MIT License
]]--

local L = LibStub("AceLocale-3.0"):NewLocale( "Jamba-Core", "enUS", true )
L["Slash Commands"] = true
L["Team"] = true
L["Quest"] = true
L["Merchant"] = true
L["Interaction"] = true
L["Combat"] = true
L["Toon"] = true
L["Chat"] = true
L["Macro"] = true
L["Advanced"] = true
L["Core"] = true
L["Profiles"] = true
L[": Profiles"] = true
L["Core: Communications"] = true
L["Push Settings"] = true
L["Push settings to all characters in the team list."] = true
L["Push Settings For All The Modules"] = true
L["Push all module settings to all characters in the team list."] = true
L["A: Failed to deserialize command arguments for B from C."] = function( libraryName, moduleName, sender )
	return libraryName..": Failed to deserialize command arguments for "..moduleName.." from "..sender.."."
end
L["Settings received from A."] = function( characterName )
	return "Settings received from "..characterName.."."
end
L["Team Online Channel"] = true
L["Channel Name"] = true
L["Channel Password"] = true
L["Change Channel (Debug)"] = true
L["After you change the channel name or password, push the"] = true
L["new settings to all your other characters and then log off"] = true
L["all your characters and log them on again."] = true
L["Show Online Channel Traffic (For Debugging Purposes)"] = true
L["Change Channel"] = true
L["Change the communications channel."] = true
L["Jamba4"] = true
L["Jamba"] = true
L["A Awesome Multi-Boxer Assistant"] = true
L["Jafula's Awesome Multi-Boxer Assistant"] = true
L["Copyright 2008-2016 Michael 'Jafula' Miller, Now managed By Ebony"] = true
L["Special thanks to Michael 'Jafula' Miller who made Jamba"] = true
L["Made For MultiBoxing"] = true
L["Help & Documentation"] = true
L["For user manuals and documentation please visit:"] = true
L["Other useful websites:"] = true
L["http://dual-boxing.com/"] = true
L["Special thanks to olipcs on dual-boxing.com for writing the FTL Helper module."] = true
L["Advanced Loot by schilm (Max Schilling) - modified by Tehtsuo and Jafula."] = true
L["Attempting to reset the Jamba Settings Frame."] = true
L["Reset Settings Frame"] = true
L["Settings"] = true
L["Options"] = true
L["Help"] = true
L["Team Online Check"] = true
L["Assume All Team Members Always Online*"] = true
L["Boost Jamba to Jamba Communications**"] = true
L["**reload UI to take effect, may cause disconnections"] = true
L["*reload UI to take effect"] = true
L["Release Notes / News"] = true
L["Close and Do Not Show Again"] = true
L["Close"] = true
-- test stuff
L["**Untick this to use the WIP Set Offline team List Set offline Button"] =true
L["Use Team List Offline Button"] = true
L["Auto Set Team Members On and Off Line"] = true