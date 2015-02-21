--[[
Jamba - Jafula's Awesome Multi-Boxer Assistant
Copyright 2008 - 2015 Michael "Jafula" Miller
License: The MIT License
]]--

-- Create the addon using AceAddon-3.0 and embed some libraries.
local AJM = LibStub( "AceAddon-3.0" ):NewAddon(
	"JambaTeam",
	"JambaModule-1.0", 
	"AceConsole-3.0", 
	"AceEvent-3.0",
	"AceHook-3.0",
	"AceTimer-3.0"
)

-- Load libraries.
local JambaUtilities = LibStub:GetLibrary( "JambaUtilities-1.0" )
local JambaHelperSettings = LibStub:GetLibrary( "JambaHelperSettings-1.0" )

-- Constants required by JambaModule and Locale for this module.
AJM.moduleName = "Jamba-Team"
AJM.settingsDatabaseName = "JambaTeamProfileDB"
AJM.chatCommand = "jamba-team"
local L = LibStub( "AceLocale-3.0" ):GetLocale( AJM.moduleName )
AJM.parentDisplayName = L["Team"]
AJM.moduleDisplayName = L["Core: Team"]

-- Jamba key bindings.
BINDING_HEADER_JAMBATEAM = L["Jamba-Team"]
BINDING_NAME_JAMBATEAMINVITE = L["Invite Team To Group"]
BINDING_NAME_JAMBATEAMDISBAND = L["Disband Group"]

-- Settings - the values to store and their defaults for the settings database.
AJM.settings = {
	profile = {
		master = "",
        teamList = {},
		focusChangeSetMaster = false,
		masterChangePromoteLeader = false,
		inviteAcceptTeam = true,
		inviteAcceptFriends = false,
		inviteAcceptBNFriends = false,
		inviteAcceptGuild = false,
		inviteDeclineStrangers = false,
		lootSetAutomatically = false,
		lootSetFreeForAll = true,
		lootSetMasterLooter = false,
		lootSlavesOptOutOfLoot = false,
		lootToGroupIfStrangerPresent = true,
		lootToGroupFriendsAreNotStrangers = false,
		masterChangeClickToMove = false,
	},
}

-- Configuration.
function AJM:GetConfiguration()
	local configuration = {
		name = AJM.moduleDisplayName,
		handler = AJM,
		type = "group",
		get = "JambaConfigurationGetSetting",
		set = "JambaConfigurationSetSetting",
		args = {	
			add = {
				type = "input",
				name = L["Add"],
				desc = L["Add a member to the team list."],
				usage = "/jamba-team add <name>",
				get = false,
				set = "AddMemberCommand",
			},					
			remove = {
				type = "input",
				name = L["Remove"],
				desc = L["Remove a member from the team list."],
				usage = "/jamba-team remove <name>",
				get = false,
				set = "RemoveMemberCommand",
			},						
			master = {
				type = "input",
				name = L["Master"],
				desc = L["Set the master character."],
				usage = "/jamba-team master <name> <tag>",
				get = false,
				set = "CommandSetMaster",
			},						
			iammaster = {
				type = "input",
				name = L["I Am Master"],
				desc = L["Set this character to be the master character."],
				usage = "/jamba-team iammaster <tag>",
				get = false,
				set = "CommandIAmMaster",
			},	
			invite = {
				type = "input",
				name = L["Invite"],
				desc = L["Invite team members to a party."],
				usage = "/jamba-team invite",
				get = false,
				set = "InviteTeamToParty",
			},	
			disband = {
				type = "input",
				name = L["Disband"],
				desc = L["Disband all team members from their parties."],
				usage = "/jamba-team disband",
				get = false,
				set = "DisbandTeamFromParty",
			},
			addparty = {
				type = "input",
				name = L["Add Party Members"],
				desc = L["Add members in the current party to the team."],
				usage = "/jamba-team addparty",
				get = false,
				set = "AddPartyMembers",
			},
			removeall = {
				type = "input",
				name = L["Remove All Members"],
				desc = L["Remove all members from the team."],
				usage = "/jamba-team removeall",
				get = false,
				set = "RemoveAllMembersFromTeam",
			},
			push = {
				type = "input",
				name = L["Push Settings"],
				desc = L["Push the team settings to all characters in the team."],
				usage = "/jamba-team push",
				get = false,
				set = "JambaSendSettings",
			},	
		},
	}
	return configuration
end

-- Create the character online table and ordered characters tables.
AJM.characterOnline = {}
AJM.orderedCharacters = {}

-------------------------------------------------------------------------------------------------------------
-- Command this module sends.
-------------------------------------------------------------------------------------------------------------

-- Leave party command.
AJM.COMMAND_LEAVE_PARTY = "JambaTeamLeaveGroup"
-- Set master command.
AJM.COMMAND_SET_MASTER = "JambaTeamSetMaster"

-------------------------------------------------------------------------------------------------------------
-- Messages module sends.
-------------------------------------------------------------------------------------------------------------

-- Master changed, parameter: new master name.
AJM.MESSAGE_TEAM_MASTER_CHANGED = "JambaTeamMasterChanged"
-- Team order changed, no parameters.
AJM.MESSAGE_TEAM_ORDER_CHANGED = "JambaTeamOrderChanged"
-- Character has been added, parameter: characterName.
AJM.MESSAGE_TEAM_CHARACTER_ADDED = "JambaTeamCharacterAdded"
-- Character has been removed, parameter: characterName.
AJM.MESSAGE_TEAM_CHARACTER_REMOVED = "JambaTeamCharacterRemoved"
-- Character has been added, parameter: characterName.

-------------------------------------------------------------------------------------------------------------
-- Constants used by module.
-------------------------------------------------------------------------------------------------------------

AJM.PARTY_LOOT_FREEFORALL = "freeforall"
AJM.PARTY_LOOT_GROUP = "group"
AJM.PARTY_LOOT_MASTER = "master"
AJM.PARTY_LOOT_NEEDBEFOREGREED = "needbeforegreed"
AJM.PARTY_LOOT_ROUNDROBIN = "roundrobin"

-------------------------------------------------------------------------------------------------------------
-- Settings Dialogs.
-------------------------------------------------------------------------------------------------------------

local function SettingsCreateTeamList()
	-- Position and size constants.
	local teamListButtonControlWidth = 95
	local inviteDisbandButtonWidth = 105
	local setMasterButtonWidth = 120
	local buttonHeight = JambaHelperSettings:GetButtonHeight()
	local top = JambaHelperSettings:TopOfSettings()
	local left = JambaHelperSettings:LeftOfSettings()
	local headingHeight = JambaHelperSettings:HeadingHeight()
	local headingWidth = JambaHelperSettings:HeadingWidth( false )
	local horizontalSpacing = JambaHelperSettings:GetHorizontalSpacing()
	local verticalSpacing = JambaHelperSettings:GetVerticalSpacing()
	local teamListWidth = headingWidth - teamListButtonControlWidth - horizontalSpacing
	local rightOfList = left + teamListWidth + horizontalSpacing
	local topOfList = top - headingHeight
	-- Team list internal variables (do not change).
	AJM.settingsControl.teamListHighlightRow = 1
	AJM.settingsControl.teamListOffset = 1
	-- Create a heading.
	JambaHelperSettings:CreateHeading( AJM.settingsControl, L["Team List"], top, false )
	-- Create a team list frame.
	local list = {}
	list.listFrameName = "JambaTeamSettingsTeamListFrame"
	list.parentFrame = AJM.settingsControl.widgetSettings.content
	list.listTop = topOfList
	list.listLeft = left
	list.listWidth = teamListWidth
	list.rowHeight = 25
	list.rowsToDisplay = 5
	list.columnsToDisplay = 2
	list.columnInformation = {}
	list.columnInformation[1] = {}
	list.columnInformation[1].width = 70
	list.columnInformation[1].alignment = "LEFT"
	list.columnInformation[2] = {}
	list.columnInformation[2].width = 30
	list.columnInformation[2].alignment = "LEFT"
	list.scrollRefreshCallback = AJM.SettingsTeamListScrollRefresh
	list.rowClickCallback = AJM.SettingsTeamListRowClick
	AJM.settingsControl.teamList = list
	JambaHelperSettings:CreateScrollList( AJM.settingsControl.teamList )
	-- Position and size constants (once list height is known).
	local bottomOfList = topOfList - list.listHeight - verticalSpacing
	local bottomOfSection = bottomOfList -  buttonHeight - verticalSpacing		
	-- Create buttons.
	AJM.settingsControl.teamListButtonMoveUp = JambaHelperSettings:CreateButton( 
		AJM.settingsControl, 
		teamListButtonControlWidth, 
		rightOfList, 
		topOfList, 
		L["Up"], 
		AJM.SettingsMoveUpClick 
	)
	AJM.settingsControl.teamListButtonMoveDown = JambaHelperSettings:CreateButton(
		AJM.settingsControl, 
		teamListButtonControlWidth, 
		rightOfList, 
		topOfList - verticalSpacing - buttonHeight, 
		L["Down"],
		AJM.SettingsMoveDownClick 
	)
	AJM.settingsControl.teamListButtonAdd = JambaHelperSettings:CreateButton(	
		AJM.settingsControl, 
		teamListButtonControlWidth, 
		rightOfList, 
		topOfList - verticalSpacing - buttonHeight - verticalSpacing - buttonHeight, 
		L["Add"],
		AJM.SettingsAddClick
	)
	--ebony
	AJM.settingsControl.teamListButtonParty = JambaHelperSettings:CreateButton(
		AJM.settingsControl, 
		teamListButtonControlWidth, 
		rightOfList, 
		topOfList - verticalSpacing - buttonHeight - verticalSpacing - buttonHeight - verticalSpacing - buttonHeight,
		L["Add Party"],
		AJM.SettingsAddPartyClick
	)
	AJM.settingsControl.teamListButtonRemove = JambaHelperSettings:CreateButton(
		AJM.settingsControl, 
		teamListButtonControlWidth, 
		rightOfList, 
		topOfList - verticalSpacing - buttonHeight - verticalSpacing - buttonHeight - verticalSpacing - buttonHeight - verticalSpacing - buttonHeight, 
		L["Remove"],
		AJM.SettingsRemoveClick
	)
	AJM.settingsControl.teamListButtonSetMaster = JambaHelperSettings:CreateButton(
		AJM.settingsControl,  
		setMasterButtonWidth, 
		left + inviteDisbandButtonWidth + horizontalSpacing + inviteDisbandButtonWidth + horizontalSpacing, 
		bottomOfList, 
		L["Set Master"],
		AJM.SettingsSetMasterClick
	)
	AJM.settingsControl.teamListButtonInvite = JambaHelperSettings:CreateButton(
		AJM.settingsControl, 
		inviteDisbandButtonWidth, 
		left, 
		bottomOfList, 
		L["Invite"],
		AJM.SettingsInviteClick
	)
	AJM.settingsControl.teamListButtonDisband = JambaHelperSettings:CreateButton( 
		AJM.settingsControl, 
		inviteDisbandButtonWidth,
		left + inviteDisbandButtonWidth + horizontalSpacing, 
		bottomOfList, 
		L["Disband"],
		AJM.SettingsDisbandClick
	)	
	return bottomOfSection
end

local function SettingsCreateMasterControl( top )
	-- Get positions.
	local checkBoxHeight = JambaHelperSettings:GetCheckBoxHeight()
	local labelContinueHeight = JambaHelperSettings:GetContinueLabelHeight()
	local left = JambaHelperSettings:LeftOfSettings()
	local headingHeight = JambaHelperSettings:HeadingHeight()
	local headingWidth = JambaHelperSettings:HeadingWidth( false )
	local horizontalSpacing = JambaHelperSettings:GetHorizontalSpacing()
	local verticalSpacing = JambaHelperSettings:GetVerticalSpacing()
	local indentContinueLabel = horizontalSpacing * 13
	local bottomOfSection = top - headingHeight - (checkBoxHeight * 3) - (verticalSpacing * 2)
	-- Create a heading.
	JambaHelperSettings:CreateHeading( AJM.settingsControl, L["Master Control"], top, false )
	-- Create checkboxes.
	AJM.settingsControl.masterControlCheckBoxFocusChange = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		left, 
		top - headingHeight, 
		L["When Focus changes, set the Master to the Focus."],
		AJM.SettingsFocusChangeToggle
	)	
	AJM.settingsControl.masterControlCheckBoxMasterChange = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		left, 
		top - headingHeight - checkBoxHeight, 
		L["When Master changes, promote Master to party leader."],
		AJM.SettingsMasterChangeToggle
	)
	AJM.settingsControl.masterControlCheckBoxMasterChangeClickToMove = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		left, 
		top - headingHeight - checkBoxHeight - checkBoxHeight, 
		L["Auto activate click-to-move on Slaves and deactivate on Master."],
		AJM.SettingsMasterChangeClickToMoveToggle
	)	
	return bottomOfSection	
end

local function SettingsCreatePartyInvitationsControl( top )
	-- Get positions.
	local checkBoxHeight = JambaHelperSettings:GetCheckBoxHeight()
	local left = JambaHelperSettings:LeftOfSettings()
	local headingHeight = JambaHelperSettings:HeadingHeight()
	local headingWidth = JambaHelperSettings:HeadingWidth( false )
	local horizontalSpacing = JambaHelperSettings:GetHorizontalSpacing()
	local verticalSpacing = JambaHelperSettings:GetVerticalSpacing()
	local checkBoxWidth = (headingWidth - horizontalSpacing) / 2
	local column1Left = left
	local column2Left = left + checkBoxWidth + horizontalSpacing
	local bottomOfSection = top - headingHeight - (checkBoxHeight * 3) - verticalSpacing
	-- Create a heading.
	JambaHelperSettings:CreateHeading( AJM.settingsControl, L["Party Invitations Control"], top, false )
	-- Create checkboxes.
	AJM.settingsControl.partyInviteControlCheckBoxAcceptMembers = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		checkBoxWidth, 
		column1Left, 
		top - headingHeight, 
		L["Accept from team."],
		AJM.SettingsAcceptInviteMembersToggle
	)	
	AJM.settingsControl.partyInviteControlCheckBoxAcceptFriends = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		checkBoxWidth, 
		column2Left, 
		top - headingHeight, 
		L["Accept from friends."],
		AJM.SettingsAcceptInviteFriendsToggle
	)
	AJM.settingsControl.partyInviteControlCheckBoxAcceptBNFriends = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		checkBoxWidth, 
		column2Left, 
		top - headingHeight - checkBoxHeight, 
		L["Accept from BattleNet/RealD friends."],
		AJM.SettingsAcceptInviteBNFriendsToggle
	)		
	AJM.settingsControl.partyInviteControlCheckBoxAcceptGuild = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		checkBoxWidth, 
		column1Left, 
		top - headingHeight - checkBoxHeight,
		L["Accept from guild."],
		AJM.SettingsAcceptInviteGuildToggle
	)	
	AJM.settingsControl.partyInviteControlCheckBoxDeclineStrangers = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		checkBoxWidth, 
		column1Left, 
		top - headingHeight  - checkBoxHeight - checkBoxHeight,
		L["Decline from strangers."],
		AJM.SettingsDeclineInviteStrangersToggle
	)	
	return bottomOfSection	
end

local function SettingsCreatePartyLootControl( top )
	-- Get positions.
	local checkBoxHeight = JambaHelperSettings:GetCheckBoxHeight()
	local radioBoxHeight = JambaHelperSettings:GetRadioBoxHeight()
	local labelContinueHeight = JambaHelperSettings:GetContinueLabelHeight()
	local left = JambaHelperSettings:LeftOfSettings()
	local headingHeight = JambaHelperSettings:HeadingHeight()
	local headingWidth = JambaHelperSettings:HeadingWidth( false )
	local horizontalSpacing = JambaHelperSettings:GetHorizontalSpacing()
	local verticalSpacing = JambaHelperSettings:GetVerticalSpacing()
	local checkBoxWidth = (headingWidth - horizontalSpacing) / 2
	local indentContinueLabel = horizontalSpacing * 13
	local column1Left = left
	local column2Left = left + checkBoxWidth + horizontalSpacing
	local bottomOfSection = top - headingHeight - checkBoxHeight - radioBoxHeight - verticalSpacing - checkBoxHeight - checkBoxHeight - (verticalSpacing * 4) - labelContinueHeight - checkBoxHeight 
	-- Create a heading.
	JambaHelperSettings:CreateHeading( AJM.settingsControl, L["Party Loot Control"], top, false )
	-- Create checkboxes.
	AJM.settingsControl.partyLootControlCheckBoxSetLootMethod = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		column1Left, 
		top - headingHeight,
		L["Automatically set the Loot Method to..."],
		AJM.SettingsSetLootMethodToggle
	)
	AJM.settingsControl.partyLootControlCheckBoxSetFFA = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		checkBoxWidth, 
		column1Left, 
		top - headingHeight - checkBoxHeight - verticalSpacing, 
		L["Free For All"],
		AJM.SettingsSetFFALootToggle
	)
	AJM.settingsControl.partyLootControlCheckBoxSetFFA:SetType( "radio" )
	AJM.settingsControl.partyLootControlCheckBoxSetMasterLooter = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		checkBoxWidth, 
		column2Left, 
		top - headingHeight - checkBoxHeight - verticalSpacing, 
		L["Master Looter"],
		AJM.SettingsSetMasterLooterToggle
	)	
	AJM.settingsControl.partyLootControlCheckBoxSetMasterLooter:SetType( "radio" )
	AJM.settingsControl.partyLootControlCheckBoxStrangerToGroup = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		column1Left, 
		top - headingHeight - checkBoxHeight - radioBoxHeight,
		L["Override: Set loot to Group Loot if stranger in group."],
		AJM.SettingsSetStrangerToGroup
	)
	AJM.settingsControl.partyLootControlCheckBoxFriendsNotStrangers = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		column1Left + indentContinueLabel, 
		top - headingHeight - checkBoxHeight - radioBoxHeight - checkBoxHeight,
		L["Friends Are Not Strangers"],
		AJM.SettingsSetFriendsNotStrangers
	)
	AJM.settingsControl.partyLootControlCheckBoxSetOptOutOfLoot = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		column1Left,
		top - headingHeight - checkBoxHeight - radioBoxHeight - checkBoxHeight - checkBoxHeight ,
		L["Slaves Opt Out of Loot"],
		AJM.SettingsSetSlavesOptOutToggle
	)		
	return bottomOfSection	
end

local function SettingsCreate()
	AJM.settingsControl = {}
	-- Create the settings panel.
	JambaHelperSettings:CreateSettings( 
		AJM.settingsControl, 
		AJM.moduleDisplayName, 
		AJM.parentDisplayName, 
		AJM.SettingsPushSettingsClick 
	)
	-- Create the team list controls.
	local bottomOfTeamList = SettingsCreateTeamList()
	-- Create the master control controls.
	local bottomOfMasterControl = SettingsCreateMasterControl( bottomOfTeamList )
	-- Create the party invitation controls.
	local bottomOfPartyInvitationControl = SettingsCreatePartyInvitationsControl( bottomOfMasterControl )
	-- Create the party loot control controls.
	local bottomOfPartyLootControl = SettingsCreatePartyLootControl( bottomOfPartyInvitationControl )
	AJM.settingsControl.widgetSettings.content:SetHeight( -bottomOfPartyLootControl )
	-- Help
	local helpTable = {}
	JambaHelperSettings:CreateHelp( AJM.settingsControl, helpTable, AJM:GetConfiguration() )	
end

-------------------------------------------------------------------------------------------------------------
-- Popup Dialogs.
-------------------------------------------------------------------------------------------------------------

-- Initialize Popup Dialogs.
local function InitializePopupDialogs()
   -- Ask the name of the character to add as a new member.
   StaticPopupDialogs["JAMBATEAM_ASK_CHARACTER_NAME"] = {
        text = L["Enter name of character to add:"],
        button1 = ACCEPT,
        button2 = CANCEL,
        hasEditBox = 1,
        timeout = 0,
		whileDead = 1,
		hideOnEscape = 1,
		OnShow = function( self )
			self.editBox:SetText("")
            self.button1:Disable()
            self.editBox:SetFocus()
        end,
		OnAccept = function( self )
			AJM:AddMemberGUI( self.editBox:GetText() )
		end,
		EditBoxOnTextChanged = function( self )
            if not self:GetText() or self:GetText():trim() == "" then
				self:GetParent().button1:Disable()
            else
                self:GetParent().button1:Enable()
            end
        end,
		EditBoxOnEnterPressed = function( self )
            if self:GetParent().button1:IsEnabled() then
				AJM:AddMemberGUI( self:GetText() )
            end
            self:GetParent():Hide()
        end,			
    }
   -- Confirm removing characters from member list.
   StaticPopupDialogs["JAMBATEAM_CONFIRM_REMOVE_CHARACTER"] = {
        text = L["Are you sure you wish to remove %s from the team list?"],
        button1 = ACCEPT,
        button2 = CANCEL,
        timeout = 0,
		whileDead = 1,
		hideOnEscape = 1,
        OnAccept = function( self )
			AJM:RemoveMemberGUI()
		end,
    }        
end

-------------------------------------------------------------------------------------------------------------
-- Team management.
-------------------------------------------------------------------------------------------------------------

local function TeamList()
	return pairs( AJM.db.teamList )
end

-- Get the largest order number from the team list.
local function GetTeamListMaximumOrder()
	local largestPosition = 0
	for characterName, position in pairs( AJM.db.teamList ) do
		if position > largestPosition then
			largestPosition = position
		end
	end
	return largestPosition
end

-- Return true if the character specified is in the team.
local function IsCharacterInTeam( characterName )
	local isMember = false
	if AJM.db.teamList[characterName] then
		isMember = true
	end
	return isMember
end

-- Get the master for this character.
local function GetMasterName()
	return AJM.db.master	
end

-- Return true if the character specified is in the master.
local function IsCharacterTheMaster( characterName )
	local isTheMaster = false
	if characterName == GetMasterName() then
		isTheMaster = true
	end
	return isTheMaster
end

-- Set the master for AJM character; the master character must be online.
local function SetMaster( value )
	-- Make sure a valid string value is supplied.
	if (value ~= nil) and (value:trim() ~= "") then
		-- The name must be capitalised.
		-- TODO: is it necessary to capitalise?
		local master = JambaUtilities:Capitalise( value )
		-- Only allow characters in the team list to be the master.
		if IsCharacterInTeam( master ) == true then
			-- Set the master.
			AJM.db.master = master
			-- Refresh the settings.
			AJM:SettingsRefresh()			
			-- Send a message to any listeners that the master has changed.
			AJM:SendMessage( AJM.MESSAGE_TEAM_MASTER_CHANGED, master )				
		else
			-- Character not in team.  Tell the team.
			AJM:JambaSendMessageToTeam( 
				AJM.characterName, 
				L["A is not in my team list.  I can not set them to be my master."]( master ),
				false
			)
		end
	end
end

-- Add a member to the member list.
local function AddMember( value )
	-- Wow names are at least two characters.
	if value ~= nil and value:trim() ~= "" and value:len() > 1 then	
		-- Capitalise the name.
		local characterName = JambaUtilities:Capitalise( value )
		-- Checks for realm and removes -realm if added
		local characterName = JambaUtilities:RemoveRealmToNameIfAdded( characterName )
		-- If the character is not already on the list...
		if AJM.db.teamList[characterName] == nil then
			-- Get the maximum order number.
			local maxOrder = GetTeamListMaximumOrder()
			-- Yes, add to the member list.
			AJM.db.teamList[characterName] = maxOrder + 1
			-- Send a message to any listeners that AJM character has been added.
			AJM:SendMessage( AJM.MESSAGE_TEAM_CHARACTER_ADDED, characterName )						
			-- Refresh the settings.
			AJM:SettingsRefresh()			
		end
	end
end

-- Add member from the command line.
function AJM:AddMemberCommand( info, parameters )
	local characterName = parameters
	-- Add the character.
	AddMember( characterName )
end

-- Add all party members to the member list.
function AJM:AddPartyMembers()
	local numberPartyMembers = GetNumSubgroupMembers()
	for iteratePartyMembers = numberPartyMembers, 1, -1 do
		local partyMemberName = UnitName( "party"..iteratePartyMembers )
		if IsCharacterInTeam( partyMemberName ) == false then
			AddMember( partyMemberName )
		end
	end
end

-- Add a member to the member list.
function AJM:AddMemberGUI( value )
	AddMember( value )
	--FauxScrollFrame_Update(
		--AJM.settingsControl.teamList.listScrollFrame, 
		--GetTeamListMaximumOrder(),
		--AJM.settingsControl.teamList.rowsToDisplay, 
		--AJM.settingsControl.teamList.rowHeight
	--)	
	--AJM.settingsControl.teamListHighlightRow = GetTeamListMaximumOrder()
	--if ( AJM.settingsControl.teamListHighlightRow - AJM.settingsControl.teamList.rowsToDisplay ) > AJM.settingsControl.teamListOffset then	
		--JambaHelperSettings:SetFauxScrollFramePosition( 
			--AJM.settingsControl.teamList.listScrollFrame, 
			--( AJM.settingsControl.teamListHighlightRow - AJM.settingsControl.teamList.rowsToDisplay ), 
			--GetTeamListMaximumOrder(), 
			--AJM.settingsControl.teamList.rowHeight 
		--)
		--AJM:Print( AJM.settingsControl.teamListHighlightRow, AJM.settingsControl.teamList.rowsToDisplay, FauxScrollFrame_GetOffset( AJM.settingsControl.teamList.listScrollFrame ) )
	--end
	AJM:SettingsTeamListScrollRefresh()
end

-- Get the character name at a specific position.
local function GetCharacterNameAtOrderPosition( position )
	local characterNameAtPosition = ""
	for characterName, characterPosition in pairs( AJM.db.teamList ) do
		if characterPosition == position then
			characterNameAtPosition = characterName
			break
		end
	end
	return characterNameAtPosition
end

-- Get the position for a specific character.
local function GetPositionForCharacterName( findCharacterName )
	local positionForCharacterName = 0
	for characterName, characterPosition in pairs( AJM.db.teamList ) do
		if characterName == findCharacterName then
			positionForCharacterName = characterPosition
			break
		end
	end
	return positionForCharacterName
end

-- Swap character positions.
local function TeamListSwapCharacterPositions( position1, position2 )
	-- Get characters at positions.
	local character1 = GetCharacterNameAtOrderPosition( position1 )
	local character2 = GetCharacterNameAtOrderPosition( position2 )
	-- Swap the positions.
	AJM.db.teamList[character1] = position2
	AJM.db.teamList[character2] = position1
end

-- Makes sure that AJM character is a team member.  Enables if previously not a member.
local function ConfirmCharacterIsInTeam()
	if not IsCharacterInTeam( AJM.characterName ) then
		-- Then add as a member.
		AddMember( AJM.characterName )
	end
end

-- Make sure there is a master, if none, set this character.
local function ConfirmThereIsAMaster()
	-- Read the db option for master.  Is it set?
	if AJM.db.master:trim() == "" then
		-- No, set it to self.
		SetMaster( AJM.characterName )
	end
	-- Is the master in the member list?
	if not IsCharacterInTeam( AJM.db.master ) then
		-- No, set self as master.
		SetMaster( AJM.characterName )
	end	 
end

-- Remove a member from the member list.
local function RemoveMember( value )
	-- Wow names are at least two characters.
	if value ~= nil and value:trim() ~= "" and value:len() > 1 then
		-- Capitalise the name.
		local characterName = JambaUtilities:Capitalise( value )
		-- Is character in team?
		if IsCharacterInTeam( characterName ) == true then
			-- Remove character from list.
			local characterPosition = AJM.db.teamList[characterName]
			AJM.db.teamList[characterName] = nil
			-- If any character had an order greater than this character's order, then shift their order down by one.
			for checkCharacterName, checkCharacterPosition in pairs( AJM.db.teamList ) do	
				if checkCharacterPosition > characterPosition then
					AJM.db.teamList[checkCharacterName] = checkCharacterPosition - 1
				end
			end
			-- Send a message to any listeners that this character has been removed.
			AJM:SendMessage( AJM.MESSAGE_TEAM_CHARACTER_REMOVED, characterName )	
			-- Make sure AJM character is a member.  
			ConfirmCharacterIsInTeam()
			-- Make sure there is a master, if none, set this character.
			ConfirmThereIsAMaster()
			-- Refresh the settings.
			AJM:SettingsRefresh()				
		end
	end
end

-- Provides a GUI for a user to confirm removing selected members from the member list.
function AJM:RemoveMemberGUI()
	local characterName = GetCharacterNameAtOrderPosition( AJM.settingsControl.teamListHighlightRow )
	RemoveMember( characterName )
	AJM.settingsControl.teamListHighlightRow = 1	
	AJM:SettingsTeamListScrollRefresh()
end

-- Remove member from the command line.
function AJM:RemoveMemberCommand( info, parameters )
	local characterName = parameters
	-- Remove the character.
	RemoveMember( characterName )
end

-- Remove all members from the team list via command line.
function AJM:RemoveAllMembersFromTeam( info, parameters )
	for characterName, characterPosition in pairs( AJM.db.teamList ) do
		RemoveMember( characterName )
	end
end

function AJM:CommandIAmMaster( info, parameters )
	local tag = parameters
	local target = AJM.characterName
	if tag ~= nil and tag:trim() ~= "" then 
		AJM:JambaSendCommandToTeam( AJM.COMMAND_SET_MASTER, target, tag )
	else
		SetMaster( target )
	end
end

function AJM:CommandSetMaster( info, parameters )
	local target, tag = strsplit( " ", parameters )
	target = JambaUtilities:Capitalise( target )
	if tag ~= nil and tag:trim() ~= "" then 
		AJM:JambaSendCommandToTeam( AJM.COMMAND_SET_MASTER, target, tag )
	else
		SetMaster( target )
	end
end

function AJM:ReceiveCommandSetMaster( target, tag )
	if JambaPrivate.Tag.DoesCharacterHaveTag( AJM.characterName, tag ) then
		SetMaster( target )
	end
end

-------------------------------------------------------------------------------------------------------------
-- Character online status.
-------------------------------------------------------------------------------------------------------------

-- Get a character's online status.
local function GetCharacterOnlineStatus( characterName )
	if JambaPrivate.Communications.AssumeTeamAlwaysOnline() == true then
		return true
	end
	return AJM.characterOnline[characterName]
end

-- Set a character's online status.
local function SetCharacterOnlineStatus( characterName, isOnline )
	if JambaPrivate.Communications.AssumeTeamAlwaysOnline() == true then
		isOnline = true
	end
	AJM.characterOnline[characterName] = isOnline
	AJM:SettingsTeamListScrollRefresh()
end

local function SetTeamStatusToOffline()
	if JambaPrivate.Communications.AssumeTeamAlwaysOnline() == true then
		return
	end
	-- Set all characters online status to false.
	for characterName, characterPosition in pairs( AJM.db.teamList ) do
		SetCharacterOnlineStatus( characterName, false )
	end
end

local function SortTeamListOrdered( characterA, characterB )
	local positionA = GetPositionForCharacterName( characterA )
	local positionB = GetPositionForCharacterName( characterB )
	return positionA < positionB
end

-- Return all characters ordered.
local function TeamListOrdered()	
	JambaUtilities:ClearTable( AJM.orderedCharacters )
	for characterName, characterPosition in pairs( AJM.db.teamList ) do
		table.insert( AJM.orderedCharacters, characterName )
	end
	table.sort( AJM.orderedCharacters, SortTeamListOrdered )
	return ipairs( AJM.orderedCharacters )
end

-------------------------------------------------------------------------------------------------------------
-- Party.
-------------------------------------------------------------------------------------------------------------

-- Invite team to party.
function AJM:InviteTeamToParty()
	-- Iterate each enabled member and invite them to a group.
	AJM.inviteList = {}
	AJM.inviteCount = 0
	for index, characterName in TeamListOrdered() do
		if GetCharacterOnlineStatus( characterName ) == true then
			-- As long as they are not the player doing the inviting.
			if characterName ~= AJM.characterName then
				AJM.inviteList[AJM.inviteCount] = characterName
				AJM.inviteCount = AJM.inviteCount + 1
			end
		end
	end
	AJM.currentInviteCount = 0
	AJM:ScheduleTimer( "DoTeamPartyInvite", 0.5 )
end

function AJM.DoTeamPartyInvite()
	InviteUnit( AJM.inviteList[AJM.currentInviteCount] )
	AJM.currentInviteCount = AJM.currentInviteCount + 1
	if AJM.currentInviteCount < AJM.inviteCount then
		AJM:ScheduleTimer( "DoTeamPartyInvite", 0.5 )
		if AJM.currentInviteCount > 5 then
			ConvertToRaid()
		end	
	else
		-- Process group checks.
		AJM:PARTY_LEADER_CHANGED( "PARTY_LEADER_CHANGED" )
		AJM:GROUP_ROSTER_UPDATE( "GROUP_ROSTER_UPDATE" )	
	end
end

local function SetPartyLoot( desiredLootOption )
	-- Is this character in a party and the party leader?
	if IsInGroup( "player" ) and UnitIsGroupLeader( "player" ) == true then
		-- What is the current loot method?
		local lootMethod, partyMaster, raidMaster = GetLootMethod()
		-- Can the loot method be changed?
		local canChangeLootMethod = false
		-- Different loot methods?
		if lootMethod ~= desiredLootOption then
			-- Yes, can change loot method.
			canChangeLootMethod = true
		else
			-- Same, loot methods, but master looter...		
			if desiredLootOption == AJM.PARTY_LOOT_MASTER and partyMaster ~= nil then
				-- And is a different master looter...
				-- If partyMaster is 0, then this player is the master looter.
				if partyMaster == 0 and IsCharacterTheMaster( AJM.characterName ) == false then
					-- Then, yes, can change loot method.
					canChangeLootMethod = true
				end
				-- If partyMaster between 1 and 4 then that player (party1 .. party4) is the master looter.
				if partyMaster > 0 then
					if UnitName( "party"..partyMaster ) ~= GetMasterName() then
						-- Then, yes, can change loot method.
						canChangeLootMethod = true
					end
				end
			end
		end
		-- SetLootMethod fires the PartyLeaderChanged event (need to check that loot is not being set to 
		-- the same loot method; otherwise an infinite loop occurs).
		if canChangeLootMethod == true then	
			if desiredLootOption == AJM.PARTY_LOOT_MASTER then
				SetLootMethod( desiredLootOption, GetMasterName(), 1 )
			else
				SetLootMethod( desiredLootOption )
			end
		end
	end
end

function AJM:PLAYER_FOCUS_CHANGED()
	-- Change master on focus change option enabled?
	if AJM.db.focusChangeSetMaster == true then
		-- Get the name of the focused unit.
		local targetName, targetRealm = UnitName( "focus" )
		-- Attempt to set this target as the master if the target is in the team.
		if IsCharacterInTeam( targetName ) == true then
			if (targetName ~= nil) and (targetName:trim() ~= "") then
				SetMaster( targetName )
			end
		end
	end
end

function AJM:PARTY_LEADER_CHANGED( event, ... )
	if AJM.db.lootSetAutomatically == true then
		if UnitIsGroupLeader( "player" ) == true then
			-- Is there a stranger in the group?
			local haveStranger = false
			if AJM.db.lootToGroupIfStrangerPresent == true then
				local numberPartyMembers = GetNumSubgroupMembers()
				for iteratePartyMembers = numberPartyMembers, 1, -1 do
					local partyMemberName = UnitName( "party"..iteratePartyMembers )
					if IsCharacterInTeam( partyMemberName ) == false then
						if AJM.db.lootToGroupFriendsAreNotStrangers == true then
							local isAFriend = false
							for friendIndex = 1, GetNumFriends() do
								local friendName = GetFriendInfo( friendIndex )
								if partyMemberName == friendName then
									isAFriend = true
								end
							end
							-- For BattleNet/RealD Friends
							for bnIndex = 1, BNGetNumFriends() do
							local _, _, _, _, name, toonid = BNGetFriendInfo( bnIndex )
								for toonIndex = 1, BNGetNumFriendToons( bnIndex ) do
								local _, friendName = BNGetFriendToonInfo( bnIndex, toonIndex );
									friendName = friendName:match("(.+)%-.+") or friendName
									if partyMemberName == friendName then
										isAFriend = true
									end
								end
							end
							if isAFriend == false then
								haveStranger = true
							end
						else
							haveStranger = true
						end
					end
				end
				if haveStranger == true then
					SetPartyLoot( AJM.PARTY_LOOT_GROUP )
				end
			end
			if haveStranger == false then
				-- Automatically set the loot to free for all?
				if AJM.db.lootSetFreeForAll == true then
					SetPartyLoot( AJM.PARTY_LOOT_FREEFORALL )
				end
				-- Automatically set the loot to master loot?
				if AJM.db.lootSetMasterLooter == true then
					SetPartyLoot( AJM.PARTY_LOOT_MASTER )
				end
			end
		end
	end
	AJM:CheckSlavesOptOutOfLoot()
end

function AJM:GROUP_ROSTER_UPDATE( event, ... )
	AJM:CheckSlavesOptOutOfLoot()
end

function AJM:CheckSlavesOptOutOfLoot()
	-- Set opt out of loot rolls?
	if AJM.db.lootSlavesOptOutOfLoot == true then
		-- Only if not the master.
		if IsCharacterTheMaster( AJM.characterName ) == false then
			if not GetOptOutOfLoot() then
				SetOptOutOfLoot( true )
			end
		else
			if GetOptOutOfLoot() then
				SetOptOutOfLoot( false )
			end
		end
	else
		if GetOptOutOfLoot() then
			SetOptOutOfLoot( false )
		end	
	end
end

function AJM:PARTY_INVITE_REQUEST( event, inviter, ... )
	-- Accept this invite, initially no.
	local acceptInvite = false
	-- Is character not in a group?
	if not IsInGroup( "player" ) then	
		-- Accept an invite from members?
		if AJM.db.inviteAcceptTeam == true then
			-- If inviter found in team list, allow the invite to be accepted.
			if IsCharacterInTeam( inviter ) then
				acceptInvite = true
			end
		end			
		-- Accept an invite from friends?
		if AJM.db.inviteAcceptFriends == true then
			-- Iterate each friend; searching for the inviter in the friends list.
			for friendIndex = 1, GetNumFriends() do
				local friendName = GetFriendInfo( friendIndex )
				-- Inviter found in friends list, allow the invite to be accepted.
				if inviter == friendName then
					acceptInvite = true
					break
				end
			end	
		end
		-- Accept an invite from BNET/RealD?
		if AJM.db.inviteAcceptBNFriends and BNFeaturesEnabledAndConnected() == true then
			-- Iterate each friend; searching for the inviter in the friends list.
			for bnIndex = 1, BNGetNumFriends() do
			local _, _, _, _, name, toonid = BNGetFriendInfo( bnIndex )
				for toonIndex = 1, BNGetNumFriendToons( bnIndex ) do
					local _, toonName = BNGetFriendToonInfo( bnIndex, toonIndex );
					inviter = inviter:match("(.+)%-.+") or inviter
					if toonName == inviter then
						acceptInvite = true
						break
					end
				end
			end	
		end
		-- Accept an invite from guild members?
		if AJM.db.inviteAcceptGuild == true then
			if UnitIsInMyGuild( inviter ) then
				acceptInvite = true
			end
		end	
	end	
	-- Hide the party invite popup?
	local hidePopup = false
	-- Accept the group invite if allowed.
	if acceptInvite == true then
		AcceptGroup()
		hidePopup = true
	else
		-- Otherwise decline the invite if permitted.
		if AJM.db.inviteDeclineStrangers == true then
			DeclineGroup()
			hidePopup = true
		end
	end		
	-- Hide the popup group invitation request if accepted or declined the invite.
	if hidePopup == true then
		-- Make sure the invite dialog does not decline the invitation when hidden.
		for iteratePopups = 1, STATICPOPUP_NUMDIALOGS do
			local dialog = _G["StaticPopup"..iteratePopups]
			if dialog.which == "PARTY_INVITE" then
				-- Set the inviteAccepted flag to true (even if the invite was declined, as the
				-- flag is only set to stop the dialog from declining in its OnHide event).
				dialog.inviteAccepted = 1
				break
			end
			-- Ebony Sometimes invite is from XREALM even though Your on the same realm and have joined the party. This should hide the Popup.
			if dialog.which == "PARTY_INVITE_XREALM" then
				-- Set the inviteAccepted flag to true (even if the invite was declined, as the
				-- flag is only set to stop the dialog from declining in its OnHide event).
				dialog.inviteAccepted = 1
				break
			end	
		end
		StaticPopup_Hide( "PARTY_INVITE" )
		--Ebony Sometimes invite is from XREALM even though Your on the same realm and have joined the party. This should hide the Popup.
		StaticPopup_Hide( "PARTY_INVITE_XREALM" )
	end	
end

function AJM:DisbandTeamFromParty()
	AJM:JambaSendCommandToTeam( AJM.COMMAND_LEAVE_PARTY )
end

local function LeaveTheParty()
	if IsInGroup( "player" ) then
		LeaveParty()
	end
end

function AJM:OnMasterChange( message, characterName )
	local playerName = UnitName( "player" )
	if AJM.db.masterChangePromoteLeader == true then
		if IsInGroup( "player" ) and UnitIsGroupLeader( "player" ) == true and GetMasterName() ~= playerName then
			PromoteToLeader( GetMasterName() )
		end
	end
	if AJM.db.masterChangeClickToMove == true then
		if IsCharacterTheMaster( self.characterName ) == true then
			ConsoleExec("Autointeract 0")
		else
			ConsoleExec("Autointeract 1")
		end
	end
end

-------------------------------------------------------------------------------------------------------------
-- NPCS.
-------------------------------------------------------------------------------------------------------------

local function IsCharacterTargetAnNpc()	
--AJM:Print( "UnitIsPlayer (NPC): ", UnitIsPlayer("npc") )
	-- Is the character targeting something?  Try and get the target's GUID.
	local guid = UnitGUID( "npc" )
	if guid == nil then
		-- No target, so target is not an npc.
--AJM:Print( "Target (NPC): None" )		
		return false
	else
		-- Yes, targeting a valid character, what is it?
		local guidRepresents = JambaUtilities:ParseGUID( guid )
		-- Is this character an NPC?
		if guidRepresents == JambaUtilities.GUID_REPRESENTS_NPC then
--AJM:Print( "Target (NPC): NPC" )			
			return true
		else
			-- Yes, a player, return false.
--AJM:Print( "Target (NPC): Player" )			
			return false
		end
	end
end

-------------------------------------------------------------------------------------------------------------
-- Addon initialization, enabling and disabling.
-------------------------------------------------------------------------------------------------------------

-- Initialise the module.
function AJM:OnInitialize()
	-- Create the settings control.
	SettingsCreate()
	-- Initialise the JambaModule part of this module.
	AJM:JambaModuleInitialize( AJM.settingsControl.widgetSettings.frame )
	-- Populate the settings.
	AJM:SettingsRefresh()	
	-- Initialise the popup dialogs.
	InitializePopupDialogs()
	-- Make sure this character is a member, add and enable if not on the list.
	ConfirmCharacterIsInTeam()
	-- Make sure there is a master, if none, set this character.
	ConfirmThereIsAMaster()
	-- Set team members online status to not connected.
	SetTeamStatusToOffline()	
	-- Key bindings.
	JambaTeamSecureButtonInvite = CreateFrame( "CheckButton", "JambaTeamSecureButtonInvite", nil, "SecureActionButtonTemplate" )
	JambaTeamSecureButtonInvite:SetAttribute( "type", "macro" )
	JambaTeamSecureButtonInvite:SetAttribute( "macrotext", "/jamba-team invite" )
	JambaTeamSecureButtonInvite:Hide()	
	JambaTeamSecureButtonDisband = CreateFrame( "CheckButton", "JambaTeamSecureButtonDisband", nil, "SecureActionButtonTemplate" )
	JambaTeamSecureButtonDisband:SetAttribute( "type", "macro" )
	JambaTeamSecureButtonDisband:SetAttribute( "macrotext", "/jamba-team disband" )
	JambaTeamSecureButtonDisband:Hide()
	
end

-- Called when the addon is enabled.
function AJM:OnEnable()
	AJM:RegisterEvent( "PARTY_INVITE_REQUEST" )
	AJM:RegisterEvent( "PARTY_LEADER_CHANGED" )
	AJM:RegisterEvent( "GROUP_ROSTER_UPDATE" )
	AJM:RegisterEvent( "GROUP_JOINED", "GROUP_ROSTER_UPDATE" )
	AJM:RegisterMessage( AJM.MESSAGE_TEAM_MASTER_CHANGED, "OnMasterChange" )
	-- Kickstart the settings team list scroll frame.
	AJM:SettingsTeamListScrollRefresh()
	AJM:RegisterEvent( "PLAYER_FOCUS_CHANGED" )
	-- Initialise key bindings.
	AJM.keyBindingFrame = CreateFrame( "Frame", nil, UIParent )
	AJM:RegisterEvent( "UPDATE_BINDINGS" )		
	AJM:UPDATE_BINDINGS()
end

-- Called when the addon is disabled.
function AJM:OnDisable()
end

-------------------------------------------------------------------------------------------------------------
-- Settings Populate.
-------------------------------------------------------------------------------------------------------------

function AJM:BeforeJambaProfileChanged()	
end

function AJM:OnJambaProfileChanged()	
	-- Refresh the settings.
	AJM:SettingsRefresh()
	-- Make sure this character is a member, add and enable if not on the list.
	ConfirmCharacterIsInTeam()
	-- Make sure there is a master, if none, set this character.
	ConfirmThereIsAMaster()	
	-- Update the settings team list.
	AJM:SettingsTeamListScrollRefresh()	
	-- Send team order changed and team master changed messages.
	AJM:SendMessage( AJM.MESSAGE_TEAM_ORDER_CHANGED )	
	AJM:SendMessage( AJM.MESSAGE_TEAM_MASTER_CHANGED )
end

function AJM:SettingsRefresh()
	-- Master Control.
	AJM.settingsControl.masterControlCheckBoxFocusChange:SetValue( AJM.db.focusChangeSetMaster )
	AJM.settingsControl.masterControlCheckBoxMasterChange:SetValue( AJM.db.masterChangePromoteLeader )
	AJM.settingsControl.masterControlCheckBoxMasterChangeClickToMove:SetValue( AJM.db.masterChangeClickToMove )
	-- Party Invitiation Control.
	AJM.settingsControl.partyInviteControlCheckBoxAcceptMembers:SetValue( AJM.db.inviteAcceptTeam )
	AJM.settingsControl.partyInviteControlCheckBoxAcceptFriends:SetValue( AJM.db.inviteAcceptFriends )
	AJM.settingsControl.partyInviteControlCheckBoxAcceptBNFriends:SetValue( AJM.db.inviteAcceptBNFriends )
	AJM.settingsControl.partyInviteControlCheckBoxAcceptGuild:SetValue( AJM.db.inviteAcceptGuild )
	AJM.settingsControl.partyInviteControlCheckBoxDeclineStrangers:SetValue( AJM.db.inviteDeclineStrangers )
	-- Party Loot Control.
	AJM.settingsControl.partyLootControlCheckBoxSetLootMethod:SetValue( AJM.db.lootSetAutomatically )
	AJM.settingsControl.partyLootControlCheckBoxSetFFA:SetValue( AJM.db.lootSetFreeForAll )
	AJM.settingsControl.partyLootControlCheckBoxSetMasterLooter:SetValue( AJM.db.lootSetMasterLooter )
	AJM.settingsControl.partyLootControlCheckBoxStrangerToGroup:SetValue( AJM.db.lootToGroupIfStrangerPresent )
	AJM.settingsControl.partyLootControlCheckBoxFriendsNotStrangers:SetValue( AJM.db.lootToGroupFriendsAreNotStrangers )
	AJM.settingsControl.partyLootControlCheckBoxSetOptOutOfLoot:SetValue( AJM.db.lootSlavesOptOutOfLoot )		
	-- Ensure correct state.
	AJM.settingsControl.partyLootControlCheckBoxSetFFA:SetDisabled( not AJM.db.lootSetAutomatically )
	AJM.settingsControl.partyLootControlCheckBoxSetMasterLooter:SetDisabled( not AJM.db.lootSetAutomatically )
	AJM.settingsControl.partyLootControlCheckBoxStrangerToGroup:SetDisabled( not AJM.db.lootSetAutomatically )
	AJM.settingsControl.partyLootControlCheckBoxFriendsNotStrangers:SetDisabled( not AJM.db.lootSetAutomatically )
	-- Update the settings team list.
	AJM:SettingsTeamListScrollRefresh()
	-- Check the opt out of loot settings.
	AJM:CheckSlavesOptOutOfLoot()
end

-- Settings received.
function AJM:JambaOnSettingsReceived( characterName, settings )	
	if characterName ~= AJM.characterName then
		-- Update the settings.
		AJM.db.teamList = JambaUtilities:CopyTable( settings.teamList )
		AJM.db.focusChangeSetMaster = settings.focusChangeSetMaster 
		AJM.db.masterChangePromoteLeader = settings.masterChangePromoteLeader 
		AJM.db.inviteAcceptTeam = settings.inviteAcceptTeam 
		AJM.db.inviteAcceptFriends = settings.inviteAcceptFriends 
		AJM.db.inviteAcceptBNFriends = settings.inviteBNAcceptFriends 
		AJM.db.inviteAcceptGuild = settings.inviteAcceptGuild 
		AJM.db.inviteDeclineStrangers = settings.inviteDeclineStrangers 
		AJM.db.lootSetAutomatically = settings.lootSetAutomatically 
		AJM.db.lootSetFreeForAll = settings.lootSetFreeForAll 
		AJM.db.lootSetMasterLooter = settings.lootSetMasterLooter 
		AJM.db.lootSlavesOptOutOfLoot = settings.lootSlavesOptOutOfLoot
		AJM.db.masterChangeClickToMove = settings.masterChangeClickToMove
		AJM.db.master = settings.master
		SetMaster( settings.master )
		-- Refresh the settings.
		AJM:SettingsRefresh()
		-- Tell the player.
		AJM:Print( L["Settings received from A."]( characterName ) )
	end
end

-------------------------------------------------------------------------------------------------------------
-- Settings Callbacks.
-------------------------------------------------------------------------------------------------------------

function AJM:SettingsTeamListScrollRefresh()
	FauxScrollFrame_Update(
		AJM.settingsControl.teamList.listScrollFrame, 
		GetTeamListMaximumOrder(),
		AJM.settingsControl.teamList.rowsToDisplay, 
		AJM.settingsControl.teamList.rowHeight
	)
	AJM.settingsControl.teamListOffset = FauxScrollFrame_GetOffset( AJM.settingsControl.teamList.listScrollFrame )
	for iterateDisplayRows = 1, AJM.settingsControl.teamList.rowsToDisplay do
		-- Reset.
		AJM.settingsControl.teamList.rows[iterateDisplayRows].columns[1].textString:SetText( "" )
		AJM.settingsControl.teamList.rows[iterateDisplayRows].columns[2].textString:SetText( "" )
		AJM.settingsControl.teamList.rows[iterateDisplayRows].columns[1].textString:SetTextColor( 1.0, 1.0, 1.0, 1.0 )
		AJM.settingsControl.teamList.rows[iterateDisplayRows].columns[2].textString:SetTextColor( 1.0, 1.0, 1.0, 1.0 )
		AJM.settingsControl.teamList.rows[iterateDisplayRows].highlight:SetTexture( 0.0, 0.0, 0.0, 0.0 )
		-- Get data.
		local dataRowNumber = iterateDisplayRows + AJM.settingsControl.teamListOffset
		if dataRowNumber <= GetTeamListMaximumOrder() then
			-- Put character name and type into columns.
			local characterName = GetCharacterNameAtOrderPosition( dataRowNumber )
			local displayCharacterName = characterName
			local isOnline = GetCharacterOnlineStatus( characterName )
			if isOnline == false then
				displayCharacterName = characterName.." "..L["(Offline)"]
			end
			local isMaster = false
			local characterType = L["Slave"]
			if IsCharacterTheMaster( characterName ) == true then
				characterType = L["Master"]
				isMaster = true
			end
			AJM.settingsControl.teamList.rows[iterateDisplayRows].columns[1].textString:SetText( displayCharacterName )
			AJM.settingsControl.teamList.rows[iterateDisplayRows].columns[2].textString:SetText( characterType )
			-- Master is a yellow colour.
			if isMaster == true then
				AJM.settingsControl.teamList.rows[iterateDisplayRows].columns[1].textString:SetTextColor( 1.0, 0.96, 0.41, 1.0 )
				AJM.settingsControl.teamList.rows[iterateDisplayRows].columns[2].textString:SetTextColor( 1.0, 0.96, 0.41, 1.0 )
			end
			-- Offline is a grey colour.
			if isOnline == false then
				AJM.settingsControl.teamList.rows[iterateDisplayRows].columns[1].textString:SetTextColor( 1.0, 1.0, 1.0, 0.6 )
				AJM.settingsControl.teamList.rows[iterateDisplayRows].columns[2].textString:SetTextColor( 1.0, 1.0, 1.0, 0.6 )
			end
			-- Highlight the selected row.
			if dataRowNumber == AJM.settingsControl.teamListHighlightRow then
				AJM.settingsControl.teamList.rows[iterateDisplayRows].highlight:SetTexture( 1.0, 1.0, 0.0, 0.5 )
			end
		end
	end
end

function AJM:SettingsTeamListRowClick( rowNumber, columnNumber )		
	if AJM.settingsControl.teamListOffset + rowNumber <= GetTeamListMaximumOrder() then
		AJM.settingsControl.teamListHighlightRow = AJM.settingsControl.teamListOffset + rowNumber
		AJM:SettingsTeamListScrollRefresh()
	end
end

function AJM:SettingsPushSettingsClick( event )
	AJM:JambaSendSettings()
end

function AJM:SettingsMoveUpClick( event )
	if AJM.settingsControl.teamListHighlightRow > 1 then
		TeamListSwapCharacterPositions( AJM.settingsControl.teamListHighlightRow, AJM.settingsControl.teamListHighlightRow - 1 )
		AJM.settingsControl.teamListHighlightRow = AJM.settingsControl.teamListHighlightRow - 1
		if AJM.settingsControl.teamListHighlightRow <= AJM.settingsControl.teamListOffset then
			JambaHelperSettings:SetFauxScrollFramePosition( 
				AJM.settingsControl.teamList.listScrollFrame, 
				AJM.settingsControl.teamListHighlightRow - 1, 
				GetTeamListMaximumOrder(), 
				AJM.settingsControl.teamList.rowHeight 
			)
		end
		AJM:SettingsTeamListScrollRefresh()
		AJM:SendMessage( AJM.MESSAGE_TEAM_ORDER_CHANGED )
	end
end

function AJM:SettingsMoveDownClick( event )
	if AJM.settingsControl.teamListHighlightRow < GetTeamListMaximumOrder() then
		TeamListSwapCharacterPositions( AJM.settingsControl.teamListHighlightRow, AJM.settingsControl.teamListHighlightRow + 1 )
		AJM.settingsControl.teamListHighlightRow = AJM.settingsControl.teamListHighlightRow + 1
		if AJM.settingsControl.teamListHighlightRow > ( AJM.settingsControl.teamListOffset + AJM.settingsControl.teamList.rowsToDisplay ) then
			JambaHelperSettings:SetFauxScrollFramePosition( 
				AJM.settingsControl.teamList.listScrollFrame, 
				AJM.settingsControl.teamListHighlightRow + 1, 
				GetTeamListMaximumOrder(), 
				AJM.settingsControl.teamList.rowHeight 
			)
		end
		AJM:SettingsTeamListScrollRefresh()
		AJM:SendMessage( AJM.MESSAGE_TEAM_ORDER_CHANGED )
	end
end

function AJM:SettingsAddClick( event )
	StaticPopup_Show( "JAMBATEAM_ASK_CHARACTER_NAME" )
end

function AJM:SettingsRemoveClick( event )
	local characterName = GetCharacterNameAtOrderPosition( AJM.settingsControl.teamListHighlightRow )
	StaticPopup_Show( "JAMBATEAM_CONFIRM_REMOVE_CHARACTER", characterName )
end

-- ebony
function AJM.SettingsAddPartyClick( event )
	AJM:AddPartyMembers()
end

function AJM:SettingsInviteClick( event )
	AJM:InviteTeamToParty()
end

function AJM:SettingsDisbandClick( event )
	AJM:DisbandTeamFromParty()
end

function AJM:SettingsSetMasterClick( event )
	local characterName = GetCharacterNameAtOrderPosition( AJM.settingsControl.teamListHighlightRow )
	SetMaster( characterName )
	AJM:SettingsTeamListScrollRefresh()
end

function AJM:SettingsFocusChangeToggle( event, checked )
	AJM.db.focusChangeSetMaster = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsMasterChangeToggle( event, checked )
	AJM.db.masterChangePromoteLeader = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsMasterChangeClickToMoveToggle( event, checked )
	AJM.db.masterChangeClickToMove = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsAcceptInviteMembersToggle( event, checked )
	AJM.db.inviteAcceptTeam = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsAcceptInviteFriendsToggle( event, checked )
	AJM.db.inviteAcceptFriends = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsAcceptInviteBNFriendsToggle( event, checked )
	AJM.db.inviteAcceptBNFriends = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsAcceptInviteGuildToggle( event, checked )
	AJM.db.inviteAcceptGuild = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsDeclineInviteStrangersToggle( event, checked )
	AJM.db.inviteDeclineStrangers = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsSetLootMethodToggle( event, checked )
	AJM.db.lootSetAutomatically = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsSetFFALootToggle( event, checked )
	AJM.db.lootSetFreeForAll = checked
	AJM.db.lootSetMasterLooter = not checked
	AJM:SettingsRefresh()
end

function AJM:SettingsSetMasterLooterToggle( event, checked )
	AJM.db.lootSetMasterLooter = checked
	AJM.db.lootSetFreeForAll = not checked
	AJM:SettingsRefresh()
end

function AJM:SettingsSetStrangerToGroup( event, checked )
	AJM.db.lootToGroupIfStrangerPresent = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsSetFriendsNotStrangers( event, checked )
	AJM.db.lootToGroupFriendsAreNotStrangers = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsSetSlavesOptOutToggle( event, checked )
	AJM.db.lootSlavesOptOutOfLoot = checked
	AJM:SettingsRefresh()
end

-------------------------------------------------------------------------------------------------------------
-- Key bindings.
-------------------------------------------------------------------------------------------------------------

function AJM:UPDATE_BINDINGS()
	if InCombatLockdown() then
		return
	end
	ClearOverrideBindings( AJM.keyBindingFrame )
	local key1, key2 = GetBindingKey( "JAMBATEAMINVITE" )		
	if key1 then 
		SetOverrideBindingClick( AJM.keyBindingFrame, false, key1, "JambaTeamSecureButtonInvite" ) 
	end
	if key2 then 
		SetOverrideBindingClick( AJM.keyBindingFrame, false, key2, "JambaTeamSecureButtonInvite" ) 
	end	
	key1, key2 = GetBindingKey( "JAMBATEAMDISBAND" )		
	if key1 then 
		SetOverrideBindingClick( AJM.keyBindingFrame, false, key1, "JambaTeamSecureButtonDisband" ) 
	end
	if key2 then 
		SetOverrideBindingClick( AJM.keyBindingFrame, false, key2, "JambaTeamSecureButtonDisband" ) 
	end
end

-------------------------------------------------------------------------------------------------------------
-- Commands.
-------------------------------------------------------------------------------------------------------------

function AJM:JambaOnCommandReceived( sender, commandName, ... )
	if commandName == AJM.COMMAND_LEAVE_PARTY then
		if IsCharacterInTeam( sender ) == true then
			LeaveTheParty()
		end
	end
	if commandName == AJM.COMMAND_SET_MASTER then
		if IsCharacterInTeam( sender ) == true then
			AJM:ReceiveCommandSetMaster( ... )
		end	
	end
end

-- Functions available from Jamba Team for other Jamba internal objects.
JambaPrivate.Team.MESSAGE_TEAM_MASTER_CHANGED = AJM.MESSAGE_TEAM_MASTER_CHANGED
JambaPrivate.Team.MESSAGE_TEAM_ORDER_CHANGED = AJM.MESSAGE_TEAM_ORDER_CHANGED
JambaPrivate.Team.MESSAGE_TEAM_CHARACTER_ADDED = AJM.MESSAGE_TEAM_CHARACTER_ADDED
JambaPrivate.Team.MESSAGE_TEAM_CHARACTER_REMOVED = AJM.MESSAGE_TEAM_CHARACTER_REMOVED
JambaPrivate.Team.TeamList = TeamList
JambaPrivate.Team.IsCharacterInTeam = IsCharacterInTeam
JambaPrivate.Team.IsCharacterTheMaster = IsCharacterTheMaster
JambaPrivate.Team.GetMasterName = GetMasterName
JambaPrivate.Team.SetTeamStatusToOffline = SetTeamStatusToOffline
JambaPrivate.Team.GetCharacterOnlineStatus = GetCharacterOnlineStatus
JambaPrivate.Team.SetCharacterOnlineStatus = SetCharacterOnlineStatus
JambaPrivate.Team.GetCharacterNameAtOrderPosition = GetCharacterNameAtOrderPosition
JambaPrivate.Team.GetTeamListMaximumOrder = GetTeamListMaximumOrder
JambaPrivate.Team.IsCharacterTargetAnNpc = IsCharacterTargetAnNpc
JambaPrivate.Team.RemoveAllMembersFromTeam = RemoveAllMembersFromTeam

-- Functions available for other addons.
JambaApi.MESSAGE_TEAM_MASTER_CHANGED = AJM.MESSAGE_TEAM_MASTER_CHANGED
JambaApi.MESSAGE_TEAM_ORDER_CHANGED = AJM.MESSAGE_TEAM_ORDER_CHANGED
JambaApi.MESSAGE_TEAM_CHARACTER_ADDED = AJM.MESSAGE_TEAM_CHARACTER_ADDED
JambaApi.MESSAGE_TEAM_CHARACTER_REMOVED = AJM.MESSAGE_TEAM_CHARACTER_REMOVED
JambaApi.IsCharacterInTeam = IsCharacterInTeam
JambaApi.IsCharacterTargetAnNpc = IsCharacterTargetAnNpc
JambaApi.IsCharacterTheMaster = IsCharacterTheMaster
JambaApi.GetMasterName = GetMasterName
JambaApi.TeamList = TeamList
JambaApi.TeamListOrdered = TeamListOrdered
JambaApi.GetCharacterNameAtOrderPosition = GetCharacterNameAtOrderPosition
JambaApi.GetPositionForCharacterName = GetPositionForCharacterName 
JambaApi.GetTeamListMaximumOrder = GetTeamListMaximumOrder
JambaApi.GetCharacterOnlineStatus = GetCharacterOnlineStatus
JambaApi.RemoveAllMembersFromTeam = RemoveAllMembersFromTeam