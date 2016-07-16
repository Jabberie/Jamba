--[[
Jamba Advanced Loot
*******************
Author: Max Schilling
Create Date: 10/16/2012
Version: 5.1.1
Description: Jamba extension that allows choosing which group member is able to loot a certain item. Specifically intended for Motes of Harmony.
Credits: Built on top of the awesome JAMBA addon, most code is copied nearly directly from various Jamba addons. Only the logic for looting is original.
]]--

local L = LibStub("AceLocale-3.0"):NewLocale( "Jamba-AdvancedLoot", "enUS", true )
L["Slash Commands"] = true
L["Merchant"] = true
L["Team"] = true
L["Advanced Loot"] = true
L["Enable Advanced Loot"] = true
L["Auto Close Loot Window On Minions"] = true
L["Manage Auto Loot"] = true
L["Push Settings"] = true
L["Push the advanced loot settings to all characters in the team."] = true
L["Settings received from A."] = function( characterName )
	return string.format( "Settings received from %s.", characterName )
end

L["GOTTA LOOT A FROM B."] = function( itemLink, characterName )
	return string.format( "JAMBA ADVANCED LOOT: %s FOUND. LOOT THIS FROM %s.", itemLink, characterName )
end

L["Epic Quality Target"] = true
L["Rare Quality Target"] = true
L["Uncommon Quality Target"] = true
L["Bind on Pickup"] = true
L["Bind on Equip"] = true
L["Loot all cloth with"] = true
L["Cloth Target"] = true
L["Cloth"] = true
L["Trade Goods"] = true
L["Tradeskill"] = true
L["Advanced Loot Items"] = true
L["Character Name"] = true
L["Remove"] = true
L["Add Item"] = true
L["Item (drag item to box from your bags)"] = true
L["Add"] = true
L["Advanced Loot Messages"] = true
L["Message Area"] = true
L["Are you sure you wish to remove the selected item from the advanced loot items list?"] = true

L["Character name must only be made up of letters and numbers."] = true

L["PopOut"] = true
L["Show the advanced loot settings in their own window."] = true
