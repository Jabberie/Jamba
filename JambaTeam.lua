--[[
Jamba - Jafula's Awesome Multi-Boxer Assistant
Copyright 2008 - 2018 Michael "Jafula" Miller


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
		characterOnline = {},
		characterClass = {},
		focusChangeSetMaster = false,
		masterChangePromoteLeader = false,
		inviteAcceptTeam = true,
		inviteAcceptFriends = false,
		inviteAcceptBNFriends = false,
		inviteAcceptGuild = false,
		inviteDeclineStrangers = false,
		inviteConvertToRaid = true,
		inviteSetAllAssistant = false,
		lootSetAutomatically = false,
		lootSetFreeForAll = true,
		lootSetGroupLoot = false,
		lootSetPersLooter = false,
	--	lootSlavesOptOutOfLoot = false,
	--	lootToGroupIfStrangerPresent = true,
	--	lootToGroupFriendsAreNotStrangers = false,
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
				desc = L["Invite team members to a party with or without a <tag>."],
				usage = "/jamba-team invite",
				get = false,
				set = "InviteTeamToParty",
			},
			inviteTag = {
				type = "input",
				name = L["Invites"],
				desc = L["Invite team members to a <tag> party."],
				usage = "/jamba-team inviteTag <tag>",
				get = false,
				set = "InviteTeamToPartys",
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
				set = "DoRemoveAllMembersFromTeam",
			},
			setalloffline = {
				type = "input",
				name = L["Set Team OffLine"],
				desc = L["Set All Team Members OffLine"],
				usage = "/jamba-team setalloffline",
				get = false,
				set = "setAllMembersOffline",
			},
			setallonline = {
				type = "input",
				name = L["Set Team OnLine"],
				desc = L["Set All Team Members OnLine"],
				usage = "/jamba-team setallonline",
				get = false,
				set = "setAllMembersOnline",
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
AJM.orderedCharacters = {}
AJM.orderedCharactersOnline = {}

-------------------------------------------------------------------------------------------------------------
-- Command this module sends.
-------------------------------------------------------------------------------------------------------------

AJM.COMMAND_TAG_PARTY = "JambaTeamTagGroup"
-- Leave party command.
AJM.COMMAND_LEAVE_PARTY = "JambaTeamLeaveGroup"
-- Set master command.
AJM.COMMAND_SET_MASTER = "JambaTeamSetMaster"
-- Set Minion OffLine
AJM.COMMAND_SET_OFFLINE = "JambaTeamSetOffline"
AJM.COMMAND_SET_ONLINE = "JambaTeamSetOnline"


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
-- character online
AJM.MESSAGE_CHARACTER_ONLINE = "JmbTmChrOn"
-- character offline
AJM.MESSAGE_CHARACTER_OFFLINE = "JmbTmChrOf"


-------------------------------------------------------------------------------------------------------------
-- Constants used by module.
-------------------------------------------------------------------------------------------------------------

AJM.PARTY_LOOT_FREEFORALL = "freeforall"
AJM.PARTY_LOOT_GROUP = "group"
AJM.PARTY_LOOT_PERSONAL = "personalloot"

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
		AJM.SettingsMoveUpClick,
		L["Move the character up a place in the team list"]
	)	
	AJM.settingsControl.teamListButtonMoveDown = JambaHelperSettings:CreateButton(
		AJM.settingsControl, 
		teamListButtonControlWidth, 
		rightOfList, 
		topOfList - verticalSpacing - buttonHeight, 
		L["Down"],
		AJM.SettingsMoveDownClick,
		L["Move the character down a place in the team list"]		
	)
	AJM.settingsControl.teamListButtonAdd = JambaHelperSettings:CreateButton(	
		AJM.settingsControl, 
		teamListButtonControlWidth, 
		rightOfList, 
		topOfList - verticalSpacing - buttonHeight - verticalSpacing - buttonHeight, 
		L["Add"],
		AJM.SettingsAddClick,
		L["Adds a member to the team list\nYou can Use:\nCharacterName\nCharacterName-realm\n@Target\n@Mouseover"]
	)
	AJM.settingsControl.teamListButtonParty = JambaHelperSettings:CreateButton(
		AJM.settingsControl, 
		teamListButtonControlWidth, 
		rightOfList, 
		topOfList - verticalSpacing - buttonHeight - verticalSpacing - buttonHeight - verticalSpacing - buttonHeight,
		L["Add Party"],
		AJM.SettingsAddPartyClick,
		L["Adds all Party/Raid members to the team list"]
	)
	AJM.settingsControl.teamListButtonRemove = JambaHelperSettings:CreateButton(
		AJM.settingsControl, 
		teamListButtonControlWidth, 
		rightOfList, 
		topOfList - verticalSpacing - buttonHeight - verticalSpacing - buttonHeight - verticalSpacing - buttonHeight - verticalSpacing - buttonHeight, 
		L["Remove"],
		AJM.SettingsRemoveClick,
		L["Removes Members from the team list"]
	)
	AJM.settingsControl.teamListButtonSetMaster = JambaHelperSettings:CreateButton(
		AJM.settingsControl,  
		setMasterButtonWidth, 
		left + inviteDisbandButtonWidth + horizontalSpacing + inviteDisbandButtonWidth + horizontalSpacing, 
		bottomOfList, 
		L["Set Master"],
		AJM.SettingsSetMasterClick,
		L["Set the selected member to be the master of the group"]
	)
	AJM.settingsControl.teamListButtonInvite = JambaHelperSettings:CreateButton(
		AJM.settingsControl, 
		inviteDisbandButtonWidth, 
		left, 
		bottomOfList, 
		L["Invite"],
		AJM.SettingsInviteClick,
		L["Invites all Team members online to a party or raid.\nThis can be set as a keyBinding"]
	)
	AJM.settingsControl.teamListButtonDisband = JambaHelperSettings:CreateButton( 
		AJM.settingsControl, 
		inviteDisbandButtonWidth,
		left + inviteDisbandButtonWidth + horizontalSpacing,
		bottomOfList, 
		L["Disband"],
		AJM.SettingsDisbandClick,
		L["Asks all Team members to leave a party or raid.\nThis can be set as a keyBinding"]
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
	local checkBoxWidth = (headingWidth - horizontalSpacing) / 2
	local column1Left = left
	local column2Left = left + checkBoxWidth + horizontalSpacing
	local bottomOfSection = top - headingHeight - (checkBoxHeight * 2) - (verticalSpacing * 2)
	-- Create a heading.
	JambaHelperSettings:CreateHeading( AJM.settingsControl, L["Master Control"], top, false )
	-- Create checkboxes.
	AJM.settingsControl.masterControlCheckBoxFocusChange = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		checkBoxWidth, 
		column1Left, 
		top - headingHeight, 
		L["Focus will set master toon."],
		AJM.SettingsFocusChangeToggle,
		L["The master will be the set from the focus target if a team member \n\nNote: All team members must be setting the focus."]
	)	
	AJM.settingsControl.masterControlCheckBoxMasterChange = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		checkBoxWidth, 
		column2Left, 
		top - headingHeight,
		L["Promote Master to party leader."],
		AJM.SettingsMasterChangeToggle,
		L["Master will always be the party leader."]
	)
	AJM.settingsControl.masterControlCheckBoxMasterChangeClickToMove = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		checkBoxWidth, 
		column1Left, 
		top - headingHeight - checkBoxHeight, 
		L["Sets click-to-move on Minions"],
		AJM.SettingsMasterChangeClickToMoveToggle,
		L["Auto activate click-to-move on Minions and deactivate on Master."]
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
	local bottomOfSection = top - headingHeight - (checkBoxHeight * 4) - (verticalSpacing * 2)
	-- Create a heading.
	JambaHelperSettings:CreateHeading( AJM.settingsControl, L["Party Invitations Control"], top, false )
	-- Create checkboxes.
	AJM.settingsControl.partyInviteControlCheckBoxConvertToRaid = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		checkBoxWidth, 
		column1Left, 
		top - headingHeight,
		L["Auto Convert To Raid"],
		AJM.SettingsinviteConvertToRaidToggle,
		L["Auto Convert To Raid if team is over five character's"]
	)
	AJM.settingsControl.partyInviteControlCheckBoxSetAllAssist = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		checkBoxWidth, 
		column2Left, 
		top - headingHeight,
		L["Auto Set All Assistant"],
		AJM.SettingsinviteSetAllAssistToggle,
		L["Auto Set all raid Member's to Assistant"]
	)
	AJM.settingsControl.partyInviteControlCheckBoxAcceptMembers = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		checkBoxWidth, 
		column1Left, 
		top - headingHeight - checkBoxHeight, 
		L["Accept from team."],
		AJM.SettingsAcceptInviteMembersToggle,
		L["Auto Accept invites from the team."]
	)
	AJM.settingsControl.partyInviteControlCheckBoxAcceptFriends = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		checkBoxWidth, 
		column2Left, 
		top - headingHeight - checkBoxHeight, 
		L["Accept from friends."],
		AJM.SettingsAcceptInviteFriendsToggle,
		L["Auto Accept invites from your friends list."]
	)
	AJM.settingsControl.partyInviteControlCheckBoxAcceptBNFriends = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		checkBoxWidth, 
		column1Left, 
		top - headingHeight - checkBoxHeight - checkBoxHeight, 
		L["Accept From BattleTag Friends."],
		AJM.SettingsAcceptInviteBNFriendsToggle,
		L["Auto Accept invites from your BatteTag or RealID Friends list."]
	)	
	AJM.settingsControl.partyInviteControlCheckBoxAcceptGuild = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		checkBoxWidth, 
		column2Left, 
		top - headingHeight - checkBoxHeight - checkBoxHeight,
		L["Accept from guild."],
		AJM.SettingsAcceptInviteGuildToggle,
		L["Auto Accept invites from your Guild."]
	)	
	AJM.settingsControl.partyInviteControlCheckBoxDeclineStrangers = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		checkBoxWidth, 
		column1Left, 
		top - headingHeight  - checkBoxHeight - checkBoxHeight - checkBoxHeight,
		L["Decline from strangers."],
		AJM.SettingsDeclineInviteStrangersToggle,
		L["Decline invites from anyone else."]
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
	local bottomOfSection = top - headingHeight - checkBoxHeight - radioBoxHeight - verticalSpacing - checkBoxHeight - checkBoxHeight -  checkBoxHeight - (verticalSpacing * 4) - labelContinueHeight - checkBoxHeight 
	-- Create a heading.
	JambaHelperSettings:CreateHeading( AJM.settingsControl, L["Party Loot Control (Instances)"], top, false )
	-- Create checkboxes.
	AJM.settingsControl.partyLootControlCheckBoxSetLootMethod = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		column1Left, 
		top - headingHeight,
		L["Set the Loot Method to..."],
		AJM.SettingsSetLootMethodToggle,
		L["Automatically set the Loot Method to\nFree For All\nPrsonal Loot\nGroup Loot"]
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
	AJM.settingsControl.partyLootControlCheckBoxSetPersLooter = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		checkBoxWidth, 
		column2Left, 
		top - headingHeight - checkBoxHeight, 
		L["Personal Loot"],
		AJM.SettingsSetPersLooterToggle
	)	
	AJM.settingsControl.partyLootControlCheckBoxSetPersLooter:SetType( "radio" )
	AJM.settingsControl.partyLootControlCheckBoxSetGroupLoot = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		column1Left, 
		top - headingHeight - checkBoxHeight - radioBoxHeight,
		L["Set to Group Loot "],
		AJM.SettingsSetGroupLootTogggle,
		L["Set loot to Group Loot."]
	)
	AJM.settingsControl.partyLootControlCheckBoxSetGroupLoot:SetType( "radio" )
--[[
	AJM.settingsControl.partyLootControlCheckBoxSetOptOutOfLoot = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		column1Left,
		top - headingHeight - checkBoxHeight - radioBoxHeight - checkBoxHeight - checkBoxHeight - checkBoxHeight,
		L["Minions Opt Out of Loot"],
		AJM.SettingsSetMinionsOptOutToggle,
		L["Minions Don't need loot."]
	)		
--]]
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
	AJM.settingsControl.widgetSettings.content:SetHeight( - bottomOfPartyInvitationControl )
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
        text = L["Enter character to add in name-server format:"],
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
	-- Master can not be set offline PopUp Box.
	   StaticPopupDialogs["MasterCanNotBeSetOffline"] = {
        text = L["Master Can not be Set OffLine"],
        button1 = OKAY,
		timeout = 0,
		whileDead = 1,
		hideOnEscape = 1,
    }
	-- OFFLINE TEST STUFF.
	   StaticPopupDialogs["SET_OFFLINE_WIP"] = {
        text = L["WIP: This Button Does absolutely nothing at all, Unless you untick Use team List Offline Button in Core:communications Under Advanced. Report bugs to to me -EBONY"],
		button1 = OKAY,
        --button2 = CANCEL,
        timeout = 0,
		whileDead = 1,
		hideOnEscape = 1,
        OnAccept = function( self )
			--AJM:RemoveMemberGUI() stuff goes here.
		end,
    }
end

-------------------------------------------------------------------------------------------------------------
-- Team management.
-------------------------------------------------------------------------------------------------------------

local function TeamList()
	return pairs( AJM.db.teamList )
end

local function Offline()
	return pairs( AJM.db.characterOnline )
end

local function characterClass()
	return pairs( AJM.db.characterClass )
end

local function setClass()
	for characterName, position in pairs( AJM.db.teamList ) do
	local class, classFileName, classIndex = UnitClass( Ambiguate(characterName, "none") )
		--AJM:Print("new", class, CharacterName )
		if class ~= nil then
			AJM.db.characterClass[characterName] = classFileName
		end
	end	
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

local function GetTeamListMaximumOrderOnline()
	local totalMembersDisplayed = 0
		for index, characterName in JambaApi.TeamListOrderedOnline() do
			--if JambaApi.GetCharacterOnlineStatus( characterName ) == true then
				totalMembersDisplayed = totalMembersDisplayed + 1
			--end
		end	
	return totalMembersDisplayed
end		
		
local function IsCharacterInTeam( characterName )
	local isMember = false
	if AJM.db.teamList[characterName] then
		isMember = true
	end
	if not isMember then
		for fullCharacterName, position in pairs( AJM.db.teamList ) do
			local matchDash = fullCharacterName:find( "-" )
			if matchDash then
				fullName = gsub(fullCharacterName, "%-[^|]+", "")
			end
			--AJM:Print('checking', checkCharacterName, 'vs', characterName)
			if fullName == characterName then
				--AJM:Print('match found')
				isMember = true
				break
			end
		end
	end
	--AJM:Print('returning', isMember)
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
local function SetMaster( master )
	-- Make sure a valid string value is supplied.
	if (master ~= nil) and (master:trim() ~= "") then
		-- The name must be capitalised i still like this or though its not needed.
		--local character = JambaUtilities:Capitalise( master )
		local character = JambaUtilities:AddRealmToNameIfMissing( master )
		-- Only allow characters in the team list to be the master.
		if IsCharacterInTeam( character ) == true then
			-- Set the master.
			AJM.db.master = character
			-- Refresh the settings.
			AJM:SettingsRefresh()			
			-- Send a message to any listeners that the master has changed.
			AJM:SendMessage( AJM.MESSAGE_TEAM_MASTER_CHANGED, character )
		else
			-- Character not in team.  Tell the team.
			AJM:JambaSendMessageToTeam( AJM.characterName, L["A is not in my team list.  I can not set them to be my master."]( character ), false )
		end
	end
end

-- Add a member to the member list.
local function AddMember( characterName )
	local name
	if characterName == "@Target" or characterName == "@target" or characterName == "@TARGET" then
		local UnitIsPlayer = UnitIsPlayer("target")
		if UnitIsPlayer == true then
			local unitName = GetUnitName("target", true)
			--AJM:Print("Target", unitName)
			name = unitName
		else
			AJM:Print(L["No Target Or Target is not a Player"])
			return
		end	
	elseif characterName == "@Mouseover" or characterName == "@mouseover" or characterName == "@MOUSEOVER" then
		local UnitIsPlayer = UnitIsPlayer("mouseover")
		if UnitIsPlayer == true then
			local unitName = GetUnitName("mouseover", true)
			--AJM:Print("mouseover", unitName)
			name = unitName
		else
			AJM:Print(L["No Target Or Target is not a Player"])
			return
		end
	end
	if name then
		--AJM:Print ( "New", name )
		local character = JambaUtilities:AddRealmToNameIfMissing( name )
		if AJM.db.teamList[character] == nil then
		-- Get the maximum order number.
		local maxOrder = GetTeamListMaximumOrder()
		-- Yes, add to the member list.
		AJM.db.teamList[character] = maxOrder + 1
		JambaPrivate.Team.SetTeamOnline()
		--AJM.Print("teamList", character)
		-- Send a message to any listeners that AJM character has been added.
		AJM:SendMessage( AJM.MESSAGE_TEAM_CHARACTER_ADDED, character )
		-- Refresh the settings.
		AJM:SettingsRefresh()	
		end	
	else
	-- Wow names are at least two characters.
	if characterName ~= nil and characterName:trim() ~= "" and characterName:len() > 1 then
		-- If the character is not already in the list...
		local character = JambaUtilities:AddRealmToNameIfMissing( characterName )
		if AJM.db.teamList[character] == nil then
			-- Get the maximum order number.
			local maxOrder = GetTeamListMaximumOrder()
			-- Yes, add to the member list.
			AJM.db.teamList[character] = maxOrder + 1
			
			local class, classFileName, classIndex = UnitClass( characterName )
			if class ~= nil then	
				--AJM:Print( classFileName )
				AJM.db.characterClass[character] = classFileName
			else
				AJM.db.characterClass[character] = nil
			end
			JambaPrivate.Team.SetTeamOnline()
			--AJM.Print("teamList", character)
			-- Send a message to any listeners that AJM character has been added.
			AJM:SendMessage( AJM.MESSAGE_TEAM_CHARACTER_ADDED, character )
			-- Refresh the settings.
			AJM:SettingsRefresh()			
			end
		end
	end
end

-- Add member from the command line.
function AJM:AddMemberCommand( info, parameters )
	local characterName = parameters
	-- Add the character.
	AddMember( characterName )
end

-- Add all party members to the member list. does not worl cross rwalm todo
function AJM:AddPartyMembers()
	--local numberPartyMembers = GetNumSubgroupMembers()
	local numberPartyMembers = GetNumGroupMembers()
	for iteratePartyMembers = numberPartyMembers, 1, -1 do
		--AJM:Print("party/raid", numberPartyMembers, iteratePartyMembers)
		local inRaid = IsInRaid()
		if inRaid == true then
			local partyMemberName, partyMemberRealm = UnitName( "raid"..iteratePartyMembers )
			local character = JambaUtilities:AddRealmToNameIfNotNil( partyMemberName, partyMemberRealm )
			if IsCharacterInTeam( character ) == false then
				AddMember( character )
			end	
		else
			local partyMemberName, partyMemberRealm = UnitName( "party"..iteratePartyMembers )
			local character = JambaUtilities:AddRealmToNameIfNotNil( partyMemberName, partyMemberRealm )
			if IsCharacterInTeam( character ) == false then
				AddMember( character )
			end
		end
	end
end

-- Add a member to the member list.
function AJM:AddMemberGUI( value )
	AddMember( value )
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

local function GetPositionForCharacterNameOnline( findCharacterName )
	local positionForCharacterName = 0
		for index, characterName in JambaApi.TeamListOrderedOnline() do
			if characterName == findCharacterName then
				--AJM:Print("found", characterName, index)
				positionForCharacterName = index
				--break
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
local function RemoveMember( characterName )
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
	-- Wow names are at least two characters.
	if characterName ~= nil and characterName:trim() ~= "" and characterName:len() > 1 then
		-- Remove the character.
		RemoveMember( characterName )
	end
end

local function RemoveAllMembersFromTeam()
	for characterName, characterPosition in pairs( AJM.db.teamList ) do
		RemoveMember( characterName )
	end
end

-- Remove all members from the team list via command line.
function AJM:DoRemoveAllMembersFromTeam( info, parameters )
	RemoveAllMembersFromTeam()
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
	return AJM.db.characterOnline[characterName]
end

-- Set a character's online status.
local function SetCharacterOnlineStatus( characterName, isOnline )
	--AJM:Print('setting', character, 'to be online')
	AJM.db.characterOnline[characterName] = isOnline
end

local function SetTeamStatusToOffline()
	for characterName, characterPosition in pairs( AJM.db.teamList ) do
		SetCharacterOnlineStatus( characterName, false )
		AJM:SendMessage( AJM.MESSAGE_CHARACTER_OFFLINE )
		AJM:SettingsTeamListScrollRefresh()
	end
end

local function SetTeamOnline()
	-- Set all characters online status to false.
	for characterName, characterPosition in pairs( AJM.db.teamList ) do
		SetCharacterOnlineStatus( characterName, true )
		AJM:SendMessage( AJM.MESSAGE_CHARACTER_ONLINE )
		AJM:SettingsTeamListScrollRefresh()
	end
end
	
--Set character Offline. 
local function setOffline( characterName )
	local character = JambaUtilities:AddRealmToNameIfMissing( characterName )
	SetCharacterOnlineStatus( character, false )
	AJM:SendMessage( AJM.MESSAGE_CHARACTER_OFFLINE )
	AJM:SettingsTeamListScrollRefresh()
end

--Set character OnLine. 
local function setOnline( characterName )
	local character = JambaUtilities:AddRealmToNameIfMissing( characterName )
	SetCharacterOnlineStatus( character, true )
	AJM:SendMessage( AJM.MESSAGE_CHARACTER_ONLINE )
	AJM:SettingsTeamListScrollRefresh()
end

function AJM.ReceivesetOffline( characterName )
	--AJM:Print("command", characterName )
	setOffline( characterName, false )
	AJM:SettingsRefresh()
end

function AJM.ReceivesetOnline( characterName )
	--AJM:Print("command", characterName )
	setOnline( characterName, false )
	AJM:SettingsRefresh()
end

function AJM:setAllMembersOffline()
	SetTeamStatusToOffline()
end	

function AJM:setAllMembersOnline()
	SetTeamOnline()
end

-------------------------------------------------------------------------------------------------------------
-- Character team list ordering.
-------------------------------------------------------------------------------------------------------------

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

-- Return all characters ordered online.
local function TeamListOrderedOnline()	
	JambaUtilities:ClearTable( AJM.orderedCharactersOnline )
	for characterName, characterPosition in pairs( AJM.db.teamList ) do
		if JambaApi.GetCharacterOnlineStatus( characterName ) == true then	
			table.insert( AJM.orderedCharactersOnline, characterName )
		end	
	end
	table.sort( AJM.orderedCharactersOnline, SortTeamListOrdered )
	return ipairs( AJM.orderedCharactersOnline )
end
-------------------------------------------------------------------------------------------------------------
-- Party.
-------------------------------------------------------------------------------------------------------------

-- Invite team to party.

function AJM:InviteTeamToPartys()
	--Clean up in next xpac!
	AJM:Print("This Command Has Been Removed and is now used as \"/Jamba-Team Invite <TagName>/")
end


function AJM.DoTeamPartyInvite()
	InviteUnit( AJM.inviteList[AJM.currentInviteCount] )
	AJM.currentInviteCount = AJM.currentInviteCount + 1
	if AJM.currentInviteCount < AJM.inviteCount then
		--if GetTeamListMaximumOrderOnline() > 5 and AJM.db.inviteConvertToRaid == true then
		if AJM.inviteCount > 5 and AJM.db.inviteConvertToRaid == true then
			if AJM.db.inviteSetAllAssistant == true then	
				ConvertToRaid()
				SetEveryoneIsAssistant(true)
			else				
				ConvertToRaid()
			end
		end
		AJM:ScheduleTimer( "DoTeamPartyInvite", 0.5 )
	else
		-- Process group checks.
		--AJM:PARTY_LEADER_CHANGED( "PARTY_LEADER_CHANGED" )
	--	AJM:GROUP_ROSTER_UPDATE( "GROUP_ROSTER_UPDATE" )	
	end
end


function AJM:InviteTeamToParty( info, tag )
	-- Iterate each enabled member and invite them to a group.
	if tag == nil or tag == "" then
		tag = "all"
	end
	if JambaUtilities:InTagList(tag) == true then
		if JambaPrivate.Tag.DoesCharacterHaveTag( AJM.characterName, tag ) == false then
			--AJM:Print("IDONOTHAVETAG", tag)
			for index, characterName in TeamListOrderedOnline() do
				--AJM:Print("NextChartohavetag", tag, characterName )
				if JambaPrivate.Tag.DoesCharacterHaveTag( characterName, tag ) then
					--AJM:Print("i have tag", tag, characterName )
					AJM:JambaSendCommandToTeam( AJM.COMMAND_TAG_PARTY, characterName, tag )
					break
				end
			end
			return
		else
			AJM.inviteList = {}
			AJM.inviteCount = 0
			for index, characterName in TeamListOrderedOnline() do
				if JambaPrivate.Tag.DoesCharacterHaveTag( characterName, tag ) then
					--AJM:Print("HasTag", characterName, tag )
					-- As long as they are not the player doing the inviting.
					if characterName ~= AJM.characterName then
						AJM.inviteList[AJM.inviteCount] = characterName
						AJM.inviteCount = AJM.inviteCount + 1
					end
				end
			end
		end
		AJM.currentInviteCount = 0
		AJM:ScheduleTimer( "DoTeamPartyInvite", 0.5 )
	else
	AJM:Print (L["Unknown Tag "]..tag )
	end	
end

function AJM:TagParty(event, characterName, tag, ...)
	--AJM:Print("test", characterName, tag )
	if AJM.characterName == characterName then
	 --AJM:Print("this msg is for me", characterName )
		if JambaPrivate.Tag.DoesCharacterHaveTag( AJM.characterName, tag ) then
			AJM:InviteTeamToParty( nil, tag)
		else 
			return
		end
	 end
end

function AJM:PLAYER_FOCUS_CHANGED()
	-- Change master on focus change option enabled?
	if AJM.db.focusChangeSetMaster == true then
		-- Get the name of the focused unit.
		local targetName, targetRealm = UnitName( "focus" )
		local name = JambaUtilities:AddRealmToNameIfNotNil( targetName, targetRealm )
		--AJM:Print("test", name)
		-- Attempt to set this target as the master if the target is in the team.
		if IsCharacterInTeam( name ) == true then
			if (name ~= nil) and (name:trim() ~= "") then
				SetMaster( name )
			end
		end
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
					local checkName, checkRealm = UnitName( "party"..partyMaster )
					local character = JambaUtilities:AddRealmToNameIfNotNil( checkName, checkName )
					if character ~= GetMasterName() then
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
				--SetLootMethod( desiredLootOption, GetMasterName(), 1 )
				SetLootMethod( desiredLootOption, ( Ambiguate( GetMasterName(), "none" ) ), 1 )
				--AJM.Print("setloot", name , desiredLootOption)
			else
				SetLootMethod( desiredLootOption )
			end
		end
	end
end

function AJM:PARTY_LEADER_CHANGED( event, ... )
	if AJM.db.lootSetAutomatically == true then
		inInstance, instanceType = IsInInstance()
		--if inInstance then
			-- Automatically set the loot to free for all?
			if AJM.db.lootSetFreeForAll == true then
				SetPartyLoot( AJM.PARTY_LOOT_FREEFORALL )
			end
				-- Automatically set the loot to Group loot?
			if AJM.db.lootSetGroupLoot == true then
				SetPartyLoot( AJM.PARTY_LOOT_GROUP )
			end
			-- Automatically set the loot to Personal Loot
			if AJM.db.lootSetPersLooter == true then
				SetPartyLoot( AJM.PARTY_LOOT_PERSONAL )
			end	
		--end
	end
end



function AJM:PARTY_INVITE_REQUEST( event, inviter, ... )
	--AJM:Print("Inviter", inviter)
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
			local _, numFriends = BNGetNumFriends()
			for bnIndex = 1, numFriends do
				for toonIndex = 1, BNGetNumFriendGameAccounts( bnIndex ) do
					local _, toonName, client, realmName = BNGetFriendGameAccountInfo( bnIndex, toonIndex )
					--AJM:Print("BNFrindsTest", toonName, client, realmName, "inviter", inviter)
					if client == "WoW" then
						if toonName == inviter or toonName.."-"..realmName == inviter then
							acceptInvite = true
							break
						end	
					end
				end
			end	
		end					
		-- Accept and invite from guild members?
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
	local playerName = AJM.characterName
	if AJM.db.masterChangePromoteLeader == true then
		if IsInGroup( "player" ) and UnitIsGroupLeader( "player" ) == true and GetMasterName() ~= playerName then
			PromoteToLeader( Ambiguate( GetMasterName(), "all" ) )
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
	-- Set team members online status to not connected. we do not want to do this on start-up!
	--SetTeamStatusToOffline()
	SetTeamOnline()
	-- Key bindings.
	JambaTeamSecureButtonInvite = CreateFrame( "CheckButton", "JambaTeamSecureButtonInvite", nil, "SecureActionButtonTemplate" )
	JambaTeamSecureButtonInvite:SetAttribute( "type", "macro" )
	JambaTeamSecureButtonInvite:SetAttribute( "macrotext", "/jamba-team invite" )
	JambaTeamSecureButtonInvite:Hide()	
	JambaTeamSecureButtonDisband = CreateFrame( "CheckButton", "JambaTeamSecureButtonDisband", nil, "SecureActionButtonTemplate" )
	JambaTeamSecureButtonDisband:SetAttribute( "type", "macro" )
	JambaTeamSecureButtonDisband:SetAttribute( "macrotext", "/jamba-team disband" )
	JambaTeamSecureButtonDisband:Hide()
	-- Update teamList if necessary to include realm names. Only used from upgrading form 3.x to 4.0
	local updatedTeamList = {}
	--Ebony Using GetRealmName() shows realm name with a space the api does not like spaces. So we have to remove it
	local k = GetRealmName()
	-- remove space for server name if there is one.
	local realmName = k:gsub( "%s+", "")
	for characterName, position in pairs( AJM.db.teamList ) do
		--AJM:Print( 'Iterating:', characterName, position )
		local updateMatchStart = characterName:find( "-" )
		if not updateMatchStart then
			updatedTeamList[characterName.."-"..realmName] = position
			AJM.db.teamList = JambaUtilities:CopyTable( updatedTeamList )
		end
	end
	--Sets The class of the char.
	setClass()
	
--todo look at this ebony
--	local updateMatchStart = AJM.db.master:find( "-" )
--	if not updateMatchStart then
--		AJM.db.master = AJM.db.master.."-"..realmName
--	end
end

-- Called when the addon is enabled.
function AJM:OnEnable()
	AJM:RegisterEvent( "PARTY_INVITE_REQUEST" )
	AJM:RegisterEvent( "PARTY_LEADER_CHANGED" )
--	AJM:RegisterEvent( "GROUP_ROSTER_UPDATE" )
--	AJM:RegisterEvent( "GROUP_JOINED", "GROUP_ROSTER_UPDATE" )
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
	AJM.settingsControl.partyInviteControlCheckBoxConvertToRaid:SetValue( AJM.db.inviteConvertToRaid )
	AJM.settingsControl.partyInviteControlCheckBoxSetAllAssist:SetValue( AJM.db.inviteSetAllAssistant )
	-- Party Loot Control.
	AJM.settingsControl.partyLootControlCheckBoxSetLootMethod:SetValue( AJM.db.lootSetAutomatically )
	AJM.settingsControl.partyLootControlCheckBoxSetFFA:SetValue( AJM.db.lootSetFreeForAll )
	AJM.settingsControl.partyLootControlCheckBoxSetGroupLoot:SetValue( AJM.db.lootSetGroupLoot )
	AJM.settingsControl.partyLootControlCheckBoxSetPersLooter:SetValue( AJM.db.lootSetPersLooter )
	--AJM.settingsControl.partyLootControlCheckBoxStrangerToGroup:SetValue( AJM.db.lootToGroupIfStrangerPresent )
	--AJM.settingsControl.partyLootControlCheckBoxFriendsNotStrangers:SetValue( AJM.db.lootToGroupFriendsAreNotStrangers )
	--AJM.settingsControl.partyLootControlCheckBoxSetOptOutOfLoot:SetValue( AJM.db.lootSlavesOptOutOfLoot )
	-- Ensure correct state.
	AJM.settingsControl.partyInviteControlCheckBoxSetAllAssist:SetDisabled (not AJM.db.inviteConvertToRaid )
	AJM.settingsControl.partyLootControlCheckBoxSetFFA:SetDisabled( not AJM.db.lootSetAutomatically )
	AJM.settingsControl.partyLootControlCheckBoxSetGroupLoot:SetDisabled( not AJM.db.lootSetAutomatically )
	AJM.settingsControl.partyLootControlCheckBoxSetPersLooter:SetDisabled( not AJM.db.lootSetAutomatically )
	--AJM.settingsControl.partyLootControlCheckBoxStrangerToGroup:SetDisabled( not AJM.db.lootSetAutomatically )
	--AJM.settingsControl.partyLootControlCheckBoxFriendsNotStrangers:SetDisabled( not AJM.db.lootSetAutomatically or not AJM.db.lootToGroupIfStrangerPresent)
	-- Update the settings team list.
	AJM:SettingsTeamListScrollRefresh()
	-- Check the opt out of loot settings.
	--AJM:CheckMinionsOptOutOfLoot()
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
		AJM.db.inviteConvertToRaid = settings.inviteConvertToRaid
		AJM.db.inviteSetAllAssistant = settings.inviteSetAllAssistant
		AJM.db.lootSetAutomatically = settings.lootSetAutomatically 
		AJM.db.lootSetFreeForAll = settings.lootSetFreeForAll 
		AJM.db.lootSetGroupLoot = settings.lootSetGroupLoot 
		AJM.db.lootSetPersLooter = settings.lootSetPersLooter 
--		AJM.db.lootSlavesOptOutOfLoot = settings.lootSlavesOptOutOfLoot
--		AJM.db.lootToGroupIfStrangerPresent = settings.lootToGroupIfStrangerPresent
--		AJM.db.lootToGroupFriendsAreNotStrangers = settings.lootToGroupFriendsAreNotStrangers
		AJM.db.masterChangeClickToMove = settings.masterChangeClickToMove
		AJM.db.master = settings.master
		--Copy the Offline team members.
		AJM.db.characterOnline = JambaUtilities:CopyTable( settings.characterOnline )
		SetMaster( settings.master )
		-- Refresh the settings.
		--AJM:SettingsRefresh()
		-- Tell the player.
		AJM:Print( L["Settings received from A."]( characterName ) )
		-- Tell the team?
		--AJM:JambaSendMessageToTeam( AJM.db.messageArea,  L["Settings received from A."]( characterName ), false )
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
		--AJM.settingsControl.teamList.rows[iterateDisplayRows].highlight:SetTexture( 0.0, 0.0, 0.0, 0.0 )
		AJM.settingsControl.teamList.rows[iterateDisplayRows].highlight:SetColorTexture( 0.0, 0.0, 0.0, 0.0 )
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
			local class = AJM.db.characterClass[characterName]
			--AJM:Print("Test", class)
			-- Set Class Color
			if class ~= nil then
				local color = RAID_CLASS_COLORS[class]
	--Debug	--	AJM:Print("Name", characterName, class)
				AJM.settingsControl.teamList.rows[iterateDisplayRows].columns[1].textString:SetTextColor( color.r, color.g, color.b, 1.0 )
				if isOnline == false then
				AJM.settingsControl.teamList.rows[iterateDisplayRows].columns[1].textString:SetTextColor( color.r, color.g, color.b, 0.4 )
				end
			end
			local isMaster = false
			local characterType = L["Minion"]
			if IsCharacterTheMaster( characterName ) == true then
				characterType = L["Master"]
				isMaster = true
			end
			AJM.settingsControl.teamList.rows[iterateDisplayRows].columns[1].textString:SetText( displayCharacterName )
			AJM.settingsControl.teamList.rows[iterateDisplayRows].columns[2].textString:SetText( characterType )
			-- Master is a yellow colour.
			if isMaster == true then
				--AJM.settingsControl.teamList.rows[iterateDisplayRows].columns[1].textString:SetTextColor( 1.0, 0.96, 0.41, 1.0 )
				AJM.settingsControl.teamList.rows[iterateDisplayRows].columns[2].textString:SetTextColor( 1.0, 0.96, 0.41, 1.0 )
			end
		--	-- Offline is a grey colour.
		--	
		--		AJM.settingsControl.teamList.rows[iterateDisplayRows].columns[2].textString:SetTextColor( 1.0, 1.0, 1.0, 0.6 )
		--	end
			-- Highlight the selected row.
			if dataRowNumber == AJM.settingsControl.teamListHighlightRow then
				--AJM.settingsControl.teamList.rows[iterateDisplayRows].highlight:SetTexture( 1.0, 1.0, 0.0, 0.5 )
				AJM.settingsControl.teamList.rows[iterateDisplayRows].highlight:SetColorTexture( 1.0, 1.0, 0.0, 0.5 )
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

function AJM.SettingsAddPartyClick( event )
	AJM:AddPartyMembers()
end
function AJM:SettingsInviteClick( event )
	AJM:InviteTeamToParty(nil)
end

function AJM:SettingsDisbandClick( event )
	AJM:DisbandTeamFromParty()
end

--TODO CLEAN UP if remove the button. Ebony

function AJM:SettingsOfflineClick( event )
	local characterName = GetCharacterNameAtOrderPosition( AJM.settingsControl.teamListHighlightRow )
	setOfflineClick ( characterName )
	AJM:SettingsTeamListScrollRefresh()
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

function AJM:SettingsinviteConvertToRaidToggle( event, checked )
	AJM.db.inviteConvertToRaid = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsinviteSetAllAssistToggle( event, checked )
	AJM.db.inviteSetAllAssistant = checked
end

function AJM:SettingsSetLootMethodToggle( event, checked )
	AJM.db.lootSetAutomatically = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsSetFFALootToggle( event, checked )
	AJM.db.lootSetFreeForAll = checked
	AJM.db.lootSetGroupLoot = not checked
	AJM.db.lootSetPersLooter = not checked
	AJM:SettingsRefresh()
end

function AJM:SettingsSetGroupLootTogggle( event, checked )
	AJM.db.lootSetGroupLoot = checked
	AJM.db.lootSetFreeForAll = not checked
	AJM.db.lootSetPersLooter = not checked
	AJM:SettingsRefresh()
end

function AJM:SettingsSetPersLooterToggle( event, checked )
	AJM.db.lootSetPersLooter = checked
	AJM.db.lootSetFreeForAll = not checked
	AJM.db.lootSetGroupLoot = not checked
	AJM:SettingsRefresh()
end

--[[
function AJM:SettingsSetStrangerToGroup( event, checked )
	AJM.db.lootToGroupIfStrangerPresent = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsSetFriendsNotStrangers( event, checked )
	AJM.db.lootToGroupFriendsAreNotStrangers = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsSetMinionsOptOutToggle( event, checked )
	AJM.db.lootSlavesOptOutOfLoot = checked
	AJM:SettingsRefresh()
end
]]
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
	--Ebony8
	if commandName == AJM.COMMAND_SET_OFFLINE then
		if IsCharacterInTeam( sender ) == true then
			AJM.ReceivesetOffline( ... )
		end
	end
	if commandName == AJM.COMMAND_SET_ONLINE then
		if IsCharacterInTeam( sender ) == true then
			AJM.ReceivesetOnline( ... )
		end
	end
	if commandName == AJM.COMMAND_TAG_PARTY then
		if IsCharacterInTeam( sender ) == true then
			AJM.TagParty( characterName, tag, ... )
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
JambaPrivate.Team.SetTeamOnline = SetTeamOnline
JambaPrivate.Team.GetCharacterNameAtOrderPosition = GetCharacterNameAtOrderPosition
JambaPrivate.Team.GetTeamListMaximumOrder = GetTeamListMaximumOrder
JambaPrivate.Team.RemoveAllMembersFromTeam = RemoveAllMembersFromTeam
JambaPrivate.Team.setOffline = setOffline
JambaPrivate.Team.setOnline = setOline

-- Functions available for other addons.
JambaApi.MESSAGE_TEAM_MASTER_CHANGED = AJM.MESSAGE_TEAM_MASTER_CHANGED
JambaApi.MESSAGE_TEAM_ORDER_CHANGED = AJM.MESSAGE_TEAM_ORDER_CHANGED
JambaApi.MESSAGE_TEAM_CHARACTER_ADDED = AJM.MESSAGE_TEAM_CHARACTER_ADDED
JambaApi.MESSAGE_TEAM_CHARACTER_REMOVED = AJM.MESSAGE_TEAM_CHARACTER_REMOVED
JambaApi.IsCharacterInTeam = IsCharacterInTeam
JambaApi.IsCharacterTheMaster = IsCharacterTheMaster
JambaApi.GetMasterName = GetMasterName
JambaApi.TeamList = TeamList
JambaApi.Offline = Offline
JambaApi.TeamListOrdered = TeamListOrdered
JambaApi.GetCharacterNameAtOrderPosition = GetCharacterNameAtOrderPosition
JambaApi.GetPositionForCharacterName = GetPositionForCharacterName 
JambaApi.GetTeamListMaximumOrder = GetTeamListMaximumOrder
JambaApi.GetCharacterOnlineStatus = GetCharacterOnlineStatus
JambaApi.RemoveAllMembersFromTeam = RemoveAllMembersFromTeam
JambaApi.MESSAGE_CHARACTER_ONLINE = AJM.MESSAGE_CHARACTER_ONLINE
JambaApi.MESSAGE_CHARACTER_OFFLINE = AJM.MESSAGE_CHARACTER_OFFLINE
JambaApi.setOffline = setOffline
JambaApi.setOnline = setOnline
JambaApi.GetTeamListMaximumOrderOnline = GetTeamListMaximumOrderOnline
JambaApi.TeamListOrderedOnline = TeamListOrderedOnline
JambaApi.GetPositionForCharacterNameOnline = GetPositionForCharacterNameOnline
JambaApi.GetClass = characterClass
JambaApi.SetClass = setClass
