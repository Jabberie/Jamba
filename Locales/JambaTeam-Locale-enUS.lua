--[[
Jamba - Jafula's Awesome Multi-Boxer Assistant
Copyright 2008 - 2018 Michael "Jafula" Miller
License: The MIT License
]]--

local L = LibStub("AceLocale-3.0"):NewLocale( "Jamba-Team", "enUS", true )
L["Slash Commands"] = true
L["Team"] = true
L["Core: Team"] = true
L["Add"] = true
L["Add Party"] = true
L["Add a member to the team list."] = true
L["Remove"] = true
L["Remove a member from the team list."] = true
L["Master"] = true
L["Party Loot Control"] = true
L["Set OffLine"] = true
L["Set On-Line"] = true
L["Master Can not be Set OffLine"] = true
--wip
L["WIP: This Button Does absolutely nothing at all, Unless you untick Use team List Offline Button in Core:communications Under Advanced. Report bugs to to me -EBONY"] = true
L["Set the master character."] = true
L["I Am Master"] = true
L["Set this character to be the master character."] = true
L["Invite"] = true
L["Invites"] = true
L["Invite team members to a party with or without a <tag>."] = true
L["Invite team members to a <tag> party."] = true
L["Disband"] = true
L["Disband all team members from their parties."] = true
L["Push Settings"] = true
L["Push the team settings to all characters in the team."] = true
L["Team List"] = true
L["Up"] = true
L["Down"] = true
L["Set Master"] = true
L["Master Control"] = true
L["When Focus changes, set the Master to the Focus."] = true
L["When Master changes, promote Master to party leader."] = true
L["Party Invitations Control"] = true
L["Accept from team."] = true
L["Auto Convert Team Over Five To Raid"] = true
L["Auto Set All Assistant"] = true
L["Accept from friends."] = true
L["Accept from BattleNet/RealD friends."] = true
L["Accept from guild."] = true
L["Decline from strangers."] = true

L["Party Loot Control"] = true
L["Automatically set the Loot Method to..."] = true
L["Free For All"] = true
L["Master Guild Looter"] = true
L["Personal Loot"] = true
L["Free For All"] = true
L["Group Loot"] = true
L["Minions Opt Out of Loot"] = true
L["Minion"] = true
L["(Offline)"] = true
L["Enter character to add in name-server format:"] = true
L["Are you sure you wish to remove %s from the team list?"] = true
L["A is not in my team list.  I can not set them to be my master."] = function( characterName )
	return characterName.." is not in my team list.  I can not set them to be my master."
end
L["A is not in my team list.  I can not set them Offline."] = function( characterName )
	return characterName.." is not in my team list.  I can not set them Offline."
end
L["Settings received from A."] = function( characterName )
	return "Settings received from "..characterName.."."
end
L["Jamba-Team"] = true
L["Invite Team To Group"] = true
L["Disband Group"] = true
L["Override: Set loot to Group Loot if stranger in group."] = true
L["Add Party Members"] = true
L["Add members in the current party to the team."] = true
L["Friends Are Not Strangers"] = true
L["Remove All Members"] = true
L["Remove all members from the team."] = true
L["Auto activate click-to-move on Minions and deactivate on Master."] = true
L["Set All Team Members OffLine"] = true
L["Set Team OffLine"] = true
L["Set All Team Members OnLine"] = true
L["Set Team OnLine"] = true
L["Set Offline"] = true
L["Sets a member offline"] = true
L["Unknown Tag "] = true

-- ebony tooltip work and Gui Changes.

L["Move the character up a place in the team list"] = true
L["Move the character down a place in the team list"] = true
L["Adds a member to the team list\nYou can Use:\nCharacterName\nCharacterName-realm\n@Target\n@Mouseover"] = true
L["Adds all Party/Raid members to the team list"] = true
L["Removes Members from the team list"] = true
L["Set the selected member to be the master of the group"] = true
L["Invites all Team members online to a party or raid.\nThis can be set as a keyBinding"] = true
L["Asks all Team members to leave a party or raid.\nThis can be set as a keyBinding"] = true
L["The master will be the set to the focus if a team member"] = true
L["Master will always be the party leader."] = true
L["Sets click-to-move on Minions"] = true
L["Auto Accept invites from the team."] = true
L["Auto Accept invites from your friends list."] = true
L["Auto Accept invites from your Battlenet list."] = true
L["Auto Accept invites from your Guild."] = true
L["Set loot to Group Loot."] = true
L["Automatically set the Loot Method to\nFree For All\nPrsonal Loot\nGroup Loot"] = true
L["Decline invites from anyone else."] = true
L["Friends Use the same loot as if they was a team member."] = true
L["Minions Don't need loot."] = true
L["Set to Group Loot "] = true
L["Override: Set loot to Group Loot if stranger is in group."] = true
L["Set the Loot Method to..."] = true

L["Accept From BattleTag Friends."] = true 

L["Auto Accept invites from your BatteTag or RealID Friends list."] = true
L["Auto Convert To Raid if team is over five character's"] = true
L["Auto Convert To Raid"] = true
L["Auto Set all raid Member's to Assistant"] = true
L["Promote Master to party leader."] = true
L["Set the Master to the Focus."] = true
L["Focus will set master toon."] = true
L["The master will be the set from the focus target if a team member \n\nNote: All team members must be setting the focus."] = true
L["Party Loot Control (Instances)"] = true
