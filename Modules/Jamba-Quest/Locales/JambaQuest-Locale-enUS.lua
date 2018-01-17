--[[
Jamba -- Jafula's Awesome Multi-Boxer Assistant
Copyright 2008 - 2018 Michael "Jafula" Miller
License: The MIT License
]]--

local L = LibStub("AceLocale-3.0"):NewLocale( "Jamba-Quest", "enUS", true )
L["Slash Commands"] = true
L["Quest"] = true
L["Push Settings"] = true
L["Push the quest settings to all characters in the team."] = true
L["Settings received from A."] = function( characterName )
	return string.format( "Settings received from %s.", characterName )
end
L[": "] = true
L["Completion"] = true
L[" "] = true
L["Information"] = true
L["Jamba-Quest treats any team member as the Master."] = true
L["Quest actions by one character will be actioned by the other"] = true
L["characters regardless of who the Master is."] = true
L["Quest Selection & Acceptance"] = true
L["Toon Select & Decline Quest With Team"] = true
L["All Auto Select Quests"] = true
L["Accept Quests"] = true
L["Toon Accept Quest From Team"] = true
L["Do Not Auto Accept Quests"] = true
L["All Auto Accept ANY Quest"] = true
L["Only Auto Accept Quests From:"] = true
L["Team"] = true
L["NPC"] = true
L["Friends"] = true
L["Party"] = true
L["Raid"] = true
L["Guild"] = true
L["Master Auto Share Quests When Accepted"] = true
L["Toon Auto Accept Escort Quest From Team"] = true
L["Other Options"] = true
L["Show Jamba-Quest Log With WoW Quest Log"] = true
L["Quest Completion"] = true
L["Enable Auto Quest Completion"] = true
L["Quest Has No Rewards Or One Reward:"] = true
L["Toon Do Nothing"] = true
L["Toon Complete Quest With Team"] = true
L["All Automatically Complete Quest"] = true
L["Quest Has More Than One Reward:"] = true
L["Toon Choose Same Reward As Team"] = true
L["Toon Must Choose Own Reward"] = true
L["If Modifier Keys Pressed, Toon Choose Same Reward"] = true
L["As Team Otherwise Toon Must Choose Own Reward"] = true
L["Ctrl"] = true
L["Shift"] = true
L["Alt"] = true
L["Override: If Toon Already Has Reward Selected,"] = true
L["Choose That Reward"] = true
L["Accepted Quest: A"] = function( questName )
	return string.format( "Accepted Quest: %s", questName )
end
L["Automatically Accepted Quest: A"] = function( questName )
	return string.format( "Automatically Accepted Quest: %s", questName )
end
L["Automatically Accepted Quest: A"] = function( questName )
	return string.format( "Automatically Accepted Quest: %s", questName )
end
L["Automatically Accepted AutoPickupQuest: A"] = function( questName )
	return string.format( "Automatically Accepted AutoPickupQuest: %s", questName )
end
L["Quest has X reward choices."] = function( choices )
	return string.format( "Quest has %s reward choices.", choices )
end
L["Completed Quest: A"] = function( questName )
	return string.format( "Completed Quest: %s", questName )
end
L["Automatically Accepted Escort Quest: A"] = function( questName )
	return string.format( "Automatically Accepted Escort Quest: %s", questName )
end

L["Jamba-Quest"] = true

L["Send Message Area"] = true
L["Send Warning Area"] = true
L["Set The Auto Select Functionality"] = true
L["Set the auto select functionality."] = true
L["toggle"] = true
L["off"] = true
L["on"] = true
L["Hold Shift To Override Auto Select/Auto Complete"] = true
L["Toon Auto Selects Best Reward"] = true
L["And Claims It As Well"] = true
L["The reward information was not loaded from the server.  Close the quest window and open it again."] = true

--[[
L["JAMBA_QUESTLOG_CONTEXT_DROPDOWNTEXT_AbandonAllToons"] = "Jamba Abandon On All Toons"
L["JAMBA_QUESTLOG_CONTEXT_DROPDOWNTEXT_TrackAllToons"] = "Jamba Track On All Toons"
L["JAMBA_QUESTLOG_CONTEXT_DROPDOWNTEXT_UnTrackAllToons"] = "Jamba UnTrack On All Toons"

L["JAMBA_QUESTLOG_CONTEXT_ALERT_AbandonAllToons"] = "Abandon \"%s\" on all toons?"

L["JAMBA_QUESTLOG_ALL_MOUSEOVER_AbandonAllButton"] = "Jamba Abandon All Quests"
L["JAMBA_QUESTLOG_ALL_MOUSEOVER_ShareAllButton"] = "Jamba Share All Quests"
L["JAMBA_QUESTLOG_ALL_MOUSEOVER_TrackAllButton"] = "Jamba Track All Quests"
L["JAMBA_QUESTLOG_ALL_MOUSEOVER_UnTrackAllButton"] = "Jamba UnTrack All Quests"

L["JAMBA_QUESTLOG_ALL_ALERT_AbandonAllButton"] = "This will abandon ALL quests ON every toon!  Yes, this means you will end up with ZERO quests in your quest log!  Are you sure?"
L["JAMBA_QUESTLOG_ALL_ALERT_ShareAllButton"] = "Are you sure you want to share all quests on all toon?"
L["JAMBA_QUESTLOG_ALL_ALERT_TrackAllButton"] = "Are you sure you want to track all quests on all toons?"
L["JAMBA_QUESTLOG_ALL_ALERT_UnTrackAllButton"] = "Are you sure you want to untrack all quests on all toons?"

L["JAMBA_QUESTLOG_HaveAbandonedQuest"] = function( questName )
	return string.format( "I have abandoned the quest: %s", questName )
end

L["JAMBA_QUESTLOG_DoNotHaveQuest"] = function( questName )
	return string.format( "I do not have the quest: %s", questName )
end

L["JAMBA_QUESTLOG_ALL_MESSAGE_CannotAbandonQuest"] = function( questName )
	return string.format( "Cannot abandon quest: %s", questName )
end

L["JAMBA_QUESTLOG_ALL_MESSAGE_UnTrackAllButton"] = function( questName )
	return string.format( "Untracking quest on all toons: %s", questName )
end

L["JAMBA_QUESTLOG_ALL_MESSAGE_TrackAllButton"] = function( questName )
	return string.format( "Tracking quest on all toons: %s", questName )
end

L["JAMBA_QUESTLOG_ALL_MESSAGE_AbandonAllButton"] = function( questName )
	return string.format( "Abandoning quest on all toons: %s", questName )
end

L["JAMBA_QUESTLOG_ALL_MESSAGE_ShareAllButton"] = function( questName )
	return string.format( "Sharing quest to all toons: %s", questName )

L["JAMBA_QUESTLOG_ALL_MESSAGE_AbandonAllButton"] = function( questName )
	return string.format( "Abandoning quest on all toons: %s", questName )
end


]]
L["JAMBA_QUESTLOG_HaveAbandonedQuest"] = function( questName )
	return string.format( "I have abandoned the quest: %s", questName )
end

L["JAMBA_QUESTLOG_DoNotHaveQuest"] = function( questName )
	return string.format( "I do not have the quest: %s", questName )
end


--JAMBA QUEST 3.0
L["Would you like to Abandon \"%s\" On All Toons?"] = true
L["Would you like to Track \"%s\" On All Toons?"] = true
L["Would you like to UnTrack \"%s\" On All Toons?"] = true
L["Just Me"] = true
L["All Team"] = true
L["This will abandon ALL quests ON every toon!  Yes, this means you will end up with ZERO quests in your quest log!  Are you sure?"] = true
L["Untracking Quest's to All Minions"] = true
L["Tracking Quest's to All Minions"] = true
L["Sharing Quest's to All Minions"] = true
L["Abandoning quest's to all toons"] = true
L["Abandon All\nQuests"] = true
L["Aabandon All Quests on all Minions"] = true
L["Untrack All"] = true
L["Untrack All Quests on all Minions"] = true
L["Track All"] = true
L["Track All Quests on all Minions"] = true
L["Share All"] = true 
L["share All Quests to all Minions"] = true



