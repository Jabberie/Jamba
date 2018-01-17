--[[
Jamba - Jafula's Awesome Multi-Boxer Assistant
Copyright 2008 - 2018 Michael "Jafula" Miller
License: The MIT License
]]--

local L = LibStub( "AceLocale-3.0" ):NewLocale( "Jamba-Toon", "enUS", true )
L["I'll be something one day"] = true
L["Slash Commands"] = true
L["Toon: Warnings"] = true
L["Push Settings"] = true
L["Push the toon settings to all characters in the team."] = true
L["Settings received from A."] = function( characterName )
	return string.format( "Settings received from %s.", characterName )
end
L["Toon"] = true
L[": "] = true
L["I'm Attacked!"] = true
L["Not Targeting!"] = true
L["Not Focus!"] = true
L["Low Health!"] = true
L["Low Mana!"] = true
L["Merchant"] = true
L["Auto Repair"] = true
L["Auto Repair With Guild Funds"] = true
L["Send Request Message Area"] = true
L["Requests"] = true
L["Auto Deny Duels"] = true
L["Auto Deny Guild Invites"] = true
L["Auto Accept Resurrect Request"] = true
L["Auto Accept Summon Request"] = true
L["Send Request Message Area"] = true
L["Combat"] = true
L["Health / Mana"] = true
L["Bag Space"] = true
L["Bags Full!"] = true
L["Warn If Bags Are Full"] = true
L["Bags Full Message"] = true	
L["Warn If Hit First Time"] = true
L["Hit First Time Message"] = true
L["Warn If Target Not Master"] = true
L["Warn Target Not Master Message"] = true
L["Warn If Focus Not Master"] = true
L["Warn Focus Not Master Message"] = true
L["Warn If My Health Drops Below"] = true
L["Health Amount - Percentage Allowed Before Warning"] = true
L["Warn Health Drop Message"] = true
L["Warn If My Mana Drops Below"] = true
L["Mana Amount - Percentage Allowed Before Warning"] = true
L["Warn Mana Drop Message"] = true
L["Send Warning Area"]  = true
L["I refused a guild invite to: X from: Y"] = function( guild, inviter )
	return string.format( "I refused a guild invite to: %s from: %s", guild, inviter )
end
L["I refused a duel from: X"] = function( challenger )
	return string.format( "I refused a duel from: %s", challenger )
end
L["I Accepted Summon From: X To: Y"] = function( sender, location )
	return string.format( "I Accepted Summon From: %s To: %s", sender, location )
end

L["I do not have enough money to repair all my items."] = true
L["Repairing cost me: X"] = function( costString )
    return string.format( "Repairing cost me: %s", costString )
end
L["Other"] = true
L["Crowd Control Message"] = true
L["Warn If Toon Gets Crowd Control"] = true
L["I Am"] = true
L[" "] = true
L["Display Team Release Prompts"] = true
L["Release Team?"] = true
L["Release Team"] = true
L["Recover All Team Corpses?"] = true
L["I can not release to my Corpse for:"] = true
L[" Seconds"] = true
L["I Do not have a SoulStone"] = true
L["Raid/Party Tools."] = true
L["Auto Accept Role Checks"] = true
L["Accept Ready Checks With Team"] = true
L["LFG Teleport With Team"] = true
L["Roll Loot With Team"] = true

--Jamba Help Tooltips
L["Display Team Release Popups when the Team Dies"] = true
L["Auto Repairs Toons Items When You Visit a Repair Merchant"] = true
L["Trys to Auto Repair With Guild Bank Funds"] = true
L["Pick a Message Area"] = true
L["Auto Deny All Guild Invites"] = true
L["Automatically Deny Duels From Players"] = true
L["Automatically Accept Resurrect Request"] = true
L["Display Team Release Popup Displays when the Team Dies"] = true
L["Automatically Accept Summon Requests"] = true
L["Warn If Hit First Time In Combat (Minion)"] = true
L["Warn If Target Not Master On Combat (Minion)"] = true
L["Warn If Focus Not Master On Combat (Minion)"] = true
L["Warn If All Minions Health Drops Below"] = true
L["Warn If all Minions Mana Drops Below"] = true
L["Warn If All Regular Bags Are Full"] = true
L["Warn If Toon Goes Inactive mosty for PVP"] = true
L["Warn If any Minion Gets Crowd Control"] = true
L["Automatically Deny All Guild Invites"] = true
L["Automatically Accept Role Checks \n\nIf a role is already set.."] = true
L["Accept Ready Checks With Team \n\nIf Team Member is the one that does the ready check it is Auto."] = true
L["Teleport With Team Members LFG"] = true
L["Roll Loot With the Team"] = true
--PLace Holder.
L["Bags"] = true
L[" "] = true
L["Jamba Bags"] = true
