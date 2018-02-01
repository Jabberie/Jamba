--[[
Jamba - Jafula's Awesome Multi-Boxer Assistant
Copyright 2008 - 2018 Michael "Jafula" Miller
License: The MIT License
]]--

local L = LibStub("AceLocale-3.0"):NewLocale( "Jamba-Core", "enUS", true )
--Change ME when update version
L["Version"] = "5.4.1"
--End of Changeme
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
L["The Awesome Multi-Boxer Assistant"] = true
L["Use Guild Communications***"] = true
L["*** EveryToon will be classed as online and needs to be in same guild!"] = true



L["Jafula's Awesome Multi-Boxer Assistant"] = true

L["Copyright 2008-2016 Michael 'Jafula' Miller, Now managed By Ebony"] = true

L["Copyright 2008-2016 Michael 'Jafula' Miller, Released Under The MIT License"] = true
L["Current Project Manager - Jennifer 'Ebony'"] = true
L["Special thanks:"] = true
L["To Schilm (Max Schilling) for building Advanced Loot"] = true
L["To Schilm (Max Schilling) for Advanced Loot"] = true 
L["To Olipcs on dual-boxing.com for writing the FTL Helper module."] = true
L["To Michael 'Jafula' Miller who made Jamba"] = true
L["Made For MultiBoxing"] = true
L["Help & Documentation"] = true
L["For user manuals and documentation please visit:"] = true
L["Useful websites:"] = true
L["www.dual-boxing.com"] = true
L["www.isboxer.com"] = true
L["www.twitter.com/jenn_ebony"] = true
L["Special thanks to olipcs on dual-boxing.com for writing the FTL Helper module."] = true
L["Advanced Loot by schilm (Max Schilling) - modified by Tehtsuo and Jafula and Ebony."] = true
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
L["Use BatteTag Communications***"] = true
L["*** Can not work if the team are on the same Blizzard Account"] = true

L["Release Notes / News: "] = true
L["Close and Do Not Show Again"] = true
L["Close"] = true
L["Commands"] = true
L["Module Not Loaded:"] = true
-- test stuff
L["**Untick this to use the WIP Set Offline team List Set offline Button"] =true
L["Use Team List Offline Button"] = true
L["Auto Set Team Members On and Off Line"] = true
L[""] = true
L["Full Change Log"] = true
--Change Log Infomation
L["Full ChangeLog"] = true
L["ChangeLog"] = true
L["Shows the Full changelog\nOpens a new Frame."] = true
L["Text1"] = "Welcome to Legion Patch7.2.0!" 
L["Text2"] = "Jamba-Trade 2.0 Now is a list to trade items with Master" 
L["Text3"] = ""
L["Text4"] = "Jamba-Quest 3.0 No more Taint menu"
L["Text5"] = ""
L["Text6"] = "Tons of bug fix's"
L["Text7"] = ""
L["Text8"] = "See ChangeLog"
L["Text9"] = ""
L["Text10"] = ""






