--[[
Jamba - Jafula's Awesome Multi-Boxer Assistant
Copyright 2008 - 2015 Michael "Jafula" Miller
License: The MIT License
]]--

-- Create the addon using AceAddon-3.0 and embed some libraries.
local AJM = LibStub( "AceAddon-3.0" ):NewAddon( 
	"JambaQuest", 
	"JambaModule-1.0", 
	"AceConsole-3.0", 
	"AceEvent-3.0",
	"AceHook-3.0",
	"AceTimer-3.0"
)

-- Load libraries.
local JambaUtilities = LibStub:GetLibrary( "JambaUtilities-1.0" )
local JambaHelperSettings = LibStub:GetLibrary( "JambaHelperSettings-1.0" )
local AceGUI = LibStub( "AceGUI-3.0" )
AJM.SharedMedia = LibStub( "LibSharedMedia-3.0" )

--  Constants and Locale for this module.
AJM.moduleName = "Jamba-Quest"
AJM.settingsDatabaseName = "JambaQuestProfileDB"
AJM.chatCommand = "jamba-quest"
local L = LibStub( "AceLocale-3.0" ):GetLocale( AJM.moduleName )
AJM.parentDisplayName = L["Quest"]
AJM.moduleDisplayName = L["Quest"]

-- Settings - the values to store and their defaults for the settings database.
AJM.settings = {
	profile = {
		mirrorMasterQuestSelectionAndDeclining = true,
		acceptQuests = true,
		slaveMirrorMasterAccept = true,
		allAutoSelectQuests = false,
		doNotAutoAccept = true,
		allAcceptAnyQuest = false,
		onlyAcceptQuestsFrom = false,
		acceptFromTeam = false,
		acceptFromNpc = false,
		acceptFromFriends = false,
		acceptFromParty = false,
		acceptFromRaid = false,
		acceptFromGuild = false,
		masterAutoShareQuestOnAccept = false,
		slaveAutoAcceptEscortQuest = true,
		showJambaQuestLogWithWoWQuestLog = true,
		enableAutoQuestCompletion = true,
		noChoiceAllDoNothing = false,
		noChoiceSlaveCompleteQuestWithMaster = true,
		noChoiceAllAutoCompleteQuest = false,
		hasChoiceSlaveDoNothing = false,
		hasChoiceSlaveCompleteQuestWithMaster = true,
		hasChoiceSlaveChooseSameRewardAsMaster = false,
		hasChoiceSlaveMustChooseOwnReward = true,
		hasChoiceSlaveRewardChoiceModifierConditional = false,
--		hasChoiceAquireBestQuestRewardForCharacter = false,
		hasChoiceCtrlKeyModifier = false,
		hasChoiceShiftKeyModifier = false,
		hasChoiceAltKeyModifier = false,
		hasChoiceOverrideUseSlaveRewardSelected = true,
		messageArea = JambaApi.DefaultMessageArea(),
		warningArea = JambaApi.DefaultWarningArea(),
		framePoint = "CENTER",
		frameRelativePoint = "CENTER",
		frameXOffset = 0,
		frameYOffset = 0,
		overrideQuestAutoSelectAndComplete = false,
--		hasChoiceAquireBestQuestRewardForCharacterAndGet = false,
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
			autoselect = {
				type = "input",
				name = L["Set The Auto Select Functionality"],
				desc = L["Set the auto select functionality."],
				usage = "/jamba-quest autoselect <on | off | toggle> <tag>",
				get = false,
				set = "AutoSelectToggleCommand",
			},
			push = {
				type = "input",
				name = L["Push Settings"],
				desc = L["Push the quest settings to all characters in the team."],
				usage = "/jamba-quest push",
				get = false,
				set = "JambaSendSettings",
			},	
		},
	}
	return configuration
end

-------------------------------------------------------------------------------------------------------------
-- Command this module sends.
-------------------------------------------------------------------------------------------------------------

AJM.COMMAND_SELECT_GOSSIP_OPTION = "SelectGossipOption"
AJM.COMMAND_SELECT_GOSSIP_ACTIVE_QUEST = "SelectGossipActiveQuest"
AJM.COMMAND_SELECT_GOSSIP_AVAILABLE_QUEST = "SelectGossipAvailableQuest"
AJM.COMMAND_SELECT_ACTIVE_QUEST = "SelectActiveQuest"
AJM.COMMAND_SELECT_AVAILABLE_QUEST = "SelectAvailableQuest"
AJM.COMMAND_ACCEPT_QUEST = "AcceptQuest"
AJM.COMMAND_COMPLETE_QUEST = "CompleteQuest"
AJM.COMMAND_CHOOSE_QUEST_REWARD = "ChooseQuestReward"
AJM.COMMAND_DECLINE_QUEST = "DeclineQuest"
AJM.COMMAND_SELECT_QUEST_LOG_ENTRY = "SelectQuestLogEntry"
AJM.COMMAND_QUEST_TRACK = "QuestTrack"
AJM.COMMAND_ABANDON_QUEST = "AbandonQuest"
AJM.COMMAND_ABANDON_ALL_QUESTS = "AbandonAllQuests"
AJM.COMMAND_TOGGLE_AUTO_SELECT = "ToggleAutoSelect"
AJM.COMMAND_LOG_COMPLETE_QUEST = "LogCompleteQuest"
AJM.COMMAND_ACCEPT_QUEST_FAKE = "AcceptQuestFake"

-------------------------------------------------------------------------------------------------------------
-- Messages module sends.
-------------------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------------------------
-- Addon initialization, enabling and disabling.
-------------------------------------------------------------------------------------------------------------

function AJM:DebugMessage( ... )
	--AJM:Print( ... )
end

-- Initialise the module.
function AJM:OnInitialize()
	-- Create the settings control.
	AJM:SettingsCreate()
	-- Initialise the JambaModule part of this module.
	AJM:JambaModuleInitialize( AJM.settingsControl.widgetSettings.frame )
	-- Populate the settings.
	AJM:SettingsRefresh()	
	-- Create the Jamba Quest Log frame.
	AJM.currentlySelectedQuest =  L["(No Quest Selected)"]
	AJM:CreateJambaQuestLogFrame()
	-- An empty table to hold the available and active quests at an npc.
	AJM.gossipQuests = {}
end

-- Called when the addon is enabled.
function AJM:OnEnable()
	-- No internal commands active.
	AJM.isInternalCommand = false
	AJM:RegisterMessage( JambaApi.MESSAGE_MESSAGE_AREAS_CHANGED, "OnMessageAreasChanged" )
    -- Quest events.
	AJM:RegisterEvent( "QUEST_ACCEPTED" )
    AJM:RegisterEvent( "QUEST_DETAIL" )
    AJM:RegisterEvent( "QUEST_COMPLETE" )
    AJM:RegisterEvent( "QUEST_ACCEPT_CONFIRM" )
	AJM:RegisterEvent( "GOSSIP_SHOW" )
	AJM:RegisterEvent( "QUEST_GREETING" )
	AJM:RegisterEvent( "QUEST_PROGRESS" )
    -- Quest post hooks.
    AJM:SecureHook( "SelectGossipOption" )
    AJM:SecureHook( "SelectGossipActiveQuest" )
    AJM:SecureHook( "SelectGossipAvailableQuest" )
    AJM:SecureHook( "SelectActiveQuest" )
    AJM:SecureHook( "SelectAvailableQuest" )
    AJM:SecureHook( "AcceptQuest" )
    AJM:SecureHook( "CompleteQuest" )
    AJM:SecureHook( "DeclineQuest" )
	AJM:SecureHook( "GetQuestReward" )
	AJM:SecureHook( "ToggleFrame" )
	AJM:SecureHook( WorldMapFrame, "Hide", "QuestLogFrameHide" )
	--AJM:SecureHook( QuestLogFrame, "Hide", "QuestLogFrameHide" )
	AJM:SecureHook( "SelectQuestLogEntry" )
	AJM:SecureHook( "ShowQuestComplete" )
--	QuestDetailAcceptButton_OnClick:HookScript( "OnClick", function() AJM:MagicAutoAcceptQuestGrrrr() end )
end

-- Called when the addon is disabled.
function AJM:OnDisable()
	-- AceHook-3.0 will tidy up the hooks for us. 
end

-------------------------------------------------------------------------------------------------------------
-- Settings Dialogs.
-------------------------------------------------------------------------------------------------------------

function AJM:SettingsCreate()
	AJM.settingsControl = {}
	AJM.settingsControlCompletion = {}
	-- Create the settings panels.
	JambaHelperSettings:CreateSettings( 
		AJM.settingsControl, 
		AJM.moduleDisplayName, 
		AJM.parentDisplayName, 
		AJM.SettingsPushSettingsClick 
	)
	JambaHelperSettings:CreateSettings( 
		AJM.settingsControlCompletion, 
		AJM.moduleDisplayName..L[": "]..L["Completion"], 
		AJM.parentDisplayName, 
		AJM.SettingsPushSettingsClick 
	)
	-- Create the quest controls.
	local bottomOfQuestOptions = AJM:SettingsCreateQuestControl( JambaHelperSettings:TopOfSettings() )
	AJM.settingsControl.widgetSettings.content:SetHeight( -bottomOfQuestOptions )
	local bottomOfQuestCompletionOptions = AJM:SettingsCreateQuestCompletionControl( JambaHelperSettings:TopOfSettings() )
	AJM.settingsControlCompletion.widgetSettings.content:SetHeight( -bottomOfQuestCompletionOptions )
	-- Help
	local helpTable = {}
	JambaHelperSettings:CreateHelp( AJM.settingsControl, helpTable, AJM:GetConfiguration() )		
end

function AJM:SettingsCreateQuestControl( top )
	-- Get positions and dimensions.
	local checkBoxHeight = JambaHelperSettings:GetCheckBoxHeight()
	local radioBoxHeight = JambaHelperSettings:GetRadioBoxHeight()
	local labelHeight = JambaHelperSettings:GetLabelHeight()
	local labelContinueHeight = JambaHelperSettings:GetContinueLabelHeight()
	local dropdownHeight = JambaHelperSettings:GetDropdownHeight()
	local left = JambaHelperSettings:LeftOfSettings()
	local headingHeight = JambaHelperSettings:HeadingHeight()
	local headingWidth = JambaHelperSettings:HeadingWidth( false )
	local horizontalSpacing = JambaHelperSettings:GetHorizontalSpacing()
	local verticalSpacing = JambaHelperSettings:GetVerticalSpacing()
	local indent = horizontalSpacing * 10
	local indentContinueLabel = horizontalSpacing * 22
	local checkBoxThirdWidth = (headingWidth - indentContinueLabel) / 3
	local halfWidth = (headingWidth - horizontalSpacing) / 2
	local middle = left + halfWidth
	local column1Left = left
	local column1LeftIndent = left + indentContinueLabel
	local column2LeftIndent = column1LeftIndent + checkBoxThirdWidth + horizontalSpacing
	local column3LeftIndent = column2LeftIndent + checkBoxThirdWidth + horizontalSpacing
	local movingTop = top
	-- Create a heading for information.
	JambaHelperSettings:CreateHeading( AJM.settingsControl, AJM.moduleDisplayName..L[" "]..L["Information"], movingTop, false )
	movingTop = movingTop - headingHeight
	-- Information line 1.
	AJM.settingsControl.labelQuestInformation1 = JambaHelperSettings:CreateContinueLabel( 
		AJM.settingsControl, 
		headingWidth, 
		column1Left, 
		movingTop,
		L["Jamba-Quest treats any team member as the Master."] 
	)	
	movingTop = movingTop - labelContinueHeight		
	-- Information line 2.
	AJM.settingsControl.labelQuestInformation2 = JambaHelperSettings:CreateContinueLabel( 
		AJM.settingsControl, 
		headingWidth, 
		column1Left, 
		movingTop,
		L["Quest actions by one character will be actioned by the other"] 
	)	
	movingTop = movingTop - labelContinueHeight		
	-- Information line 3.
	AJM.settingsControl.labelQuestInformation3 = JambaHelperSettings:CreateContinueLabel( 
		AJM.settingsControl, 
		headingWidth, 
		column1Left, 
		movingTop,
		L["characters regardless of who the Master is."] 
	)	
	movingTop = movingTop - labelContinueHeight				
	-- Create a heading for quest selection.
	JambaHelperSettings:CreateHeading( AJM.settingsControl, L["Quest Selection & Acceptance"], movingTop, false )
	movingTop = movingTop - headingHeight
	-- Radio box: Slave select, accept and decline quest with master.
	AJM.settingsControl.checkBoxMirrorMasterQuestSelectionAndDeclining = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		column1Left, 
		movingTop,
		L["Toon Select & Decline Quest With Team"],
		AJM.SettingsToggleMirrorMasterQuestSelectionAndDeclining
	)	
	AJM.settingsControl.checkBoxMirrorMasterQuestSelectionAndDeclining:SetType( "radio" )
	movingTop = movingTop - radioBoxHeight
	-- Radio box: All auto select quests.
	AJM.settingsControl.checkBoxAllAutoSelectQuests = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		column1Left, 
		movingTop,
		L["All Auto Select Quests"],
		AJM.SettingsToggleAllAutoSelectQuests
	)	
	AJM.settingsControl.checkBoxAllAutoSelectQuests:SetType( "radio" )
	movingTop = movingTop - radioBoxHeight
	-- Check box: Accept quests.
	AJM.settingsControl.checkBoxAcceptQuests = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		column1Left, 
		movingTop,
		L["Accept Quests"],
		AJM.SettingsToggleAcceptQuests
	)	
	movingTop = movingTop - checkBoxHeight		
	-- Radio box: Slave accept quest with master.
	AJM.settingsControl.checkBoxSlaveMirrorMasterAccept = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		column1Left + indent, 
		movingTop,
		L["Toon Accept Quest From Team"],
		AJM.SettingsToggleSlaveMirrorMasterAccept
	)	
	movingTop = movingTop - checkBoxHeight		
	-- Radio box: All auto accept any quest.
	AJM.settingsControl.checkBoxDoNotAutoAccept = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		column1Left + indent, 
		movingTop,
		L["Do Not Auto Accept Quests"],
		AJM.SettingsToggleDoNotAutoAccept
	)	
	AJM.settingsControl.checkBoxDoNotAutoAccept:SetType( "radio" )
	movingTop = movingTop - radioBoxHeight		
	-- Radio box: All auto accept any quest.
	AJM.settingsControl.checkBoxAllAcceptAnyQuest = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		column1Left + indent, 
		movingTop,
		L["All Auto Accept ANY Quest"],
		AJM.SettingsToggleAllAcceptAnyQuest
	)	
	AJM.settingsControl.checkBoxAllAcceptAnyQuest:SetType( "radio" )
	movingTop = movingTop - radioBoxHeight		
	-- Radio box: Choose who to auto accept quests from.
	AJM.settingsControl.checkBoxOnlyAcceptQuestsFrom = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		column1Left + indent, 
		movingTop,
		L["Only Auto Accept Quests From:"],
		AJM.SettingsToggleOnlyAcceptQuestsFrom
	)	
	AJM.settingsControl.checkBoxOnlyAcceptQuestsFrom:SetType( "radio" )
	movingTop = movingTop - radioBoxHeight
	-- Check box: Team.
	AJM.settingsControl.checkBoxAcceptFromTeam = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		checkBoxThirdWidth, 
		column1LeftIndent, 
		movingTop,
		L["Team"],
		AJM.SettingsToggleAcceptFromTeam
	)	
	-- Check box: NPC.
	AJM.settingsControl.checkBoxAcceptFromNpc = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		checkBoxThirdWidth, 
		column2LeftIndent, 
		movingTop,
		L["NPC"],
		AJM.SettingsToggleAcceptFromNpc
	)	
	-- Check box: Friends.
	AJM.settingsControl.checkBoxAcceptFromFriends = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		checkBoxThirdWidth, 
		column3LeftIndent, 
		movingTop,
		L["Friends"],
		AJM.SettingsToggleAcceptFromFriends
	)	
	movingTop = movingTop - checkBoxHeight
	-- Check box: Party.
	AJM.settingsControl.checkBoxAcceptFromParty = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		checkBoxThirdWidth, 
		column1LeftIndent, 
		movingTop,
		L["Party"],
		AJM.SettingsToggleAcceptFromParty
	)	
	-- Check box: Raid.
	AJM.settingsControl.checkBoxAcceptFromRaid = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		checkBoxThirdWidth, 
		column2LeftIndent, 
		movingTop,
		L["Raid"],
		AJM.SettingsToggleAcceptFromRaid
	)	
	-- Check box: Guild.
	AJM.settingsControl.checkBoxAcceptFromGuild = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		checkBoxThirdWidth, 
		column3LeftIndent, 
		movingTop,
		L["Guild"],
		AJM.SettingsToggleAcceptFromGuild
	)	
	movingTop = movingTop - checkBoxHeight
	-- Check box: Master auto share quest on accept.
	AJM.settingsControl.checkBoxMasterAutoShareQuestOnAccept = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		column1Left, 
		movingTop,
		L["Master Auto Share Quests When Accepted"],
		AJM.SettingsToggleMasterAutoShareQuestOnAccept
	)	
	movingTop = movingTop - checkBoxHeight			
	-- Check box: Slave auto accept escort quest from master.
	AJM.settingsControl.checkBoxSlaveAutoAcceptEscortQuest = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		column1Left, 
		movingTop,
		L["Toon Auto Accept Escort Quest From Team"],
		AJM.SettingsToggleSlaveAutoAcceptEscortQuest
	)	
	movingTop = movingTop - checkBoxHeight
	-- Create a heading for other options.
	JambaHelperSettings:CreateHeading( AJM.settingsControl, L["Other Options"], movingTop, false )
	movingTop = movingTop - headingHeight
	-- Check box: Override quest auto select and auto complete.
	AJM.settingsControl.checkBoxOverrideQuestAutoSelectAndComplete = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		column1Left, 
		movingTop,
		L["Hold Shift To Override Auto Select/Auto Complete"],
		AJM.SettingsToggleOverrideQuestAutoSelectAndComplete
	)	
	movingTop = movingTop - checkBoxHeight
	-- Check box: Show Jamba quest log with WoW quest log.
	AJM.settingsControl.checkBoxShowJambaQuestLogWithWoWQuestLog = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		column1Left, 
		movingTop,
		L["Show Jamba-Quest Log With WoW Quest Log"],
		AJM.SettingsToggleShowJambaQuestLogWithWoWQuestLog
	)	
	movingTop = movingTop - checkBoxHeight
	-- Message area.
	AJM.settingsControl.dropdownMessageArea = JambaHelperSettings:CreateDropdown( 
		AJM.settingsControl, 
		headingWidth, 
		column1Left, 
		movingTop, 
		L["Send Message Area"] 
	)
	AJM.settingsControl.dropdownMessageArea:SetList( JambaApi.MessageAreaList() )
	AJM.settingsControl.dropdownMessageArea:SetCallback( "OnValueChanged", AJM.SettingsSetMessageArea )
	movingTop = movingTop - dropdownHeight
	-- Warning area.
	AJM.settingsControl.dropdownWarningArea = JambaHelperSettings:CreateDropdown( 
		AJM.settingsControl, 
		headingWidth, 
		column1Left, 
		movingTop, 
		L["Send Warning Area"] 
	)
	AJM.settingsControl.dropdownWarningArea:SetList( JambaApi.MessageAreaList() )
	AJM.settingsControl.dropdownWarningArea:SetCallback( "OnValueChanged", AJM.SettingsSetWarningArea )
	movingTop = movingTop - dropdownHeight
	return movingTop	
end

function AJM:OnMessageAreasChanged( message )
	AJM.settingsControl.dropdownMessageArea:SetList( JambaApi.MessageAreaList() )
	AJM.settingsControl.dropdownWarningArea:SetList( JambaApi.MessageAreaList() )
end

function AJM:SettingsCreateQuestCompletionControl( top )
	-- Get positions and dimensions.
	local checkBoxHeight = JambaHelperSettings:GetCheckBoxHeight()
	local radioBoxHeight = JambaHelperSettings:GetRadioBoxHeight()
	local labelHeight = JambaHelperSettings:GetLabelHeight()
	local labelContinueHeight = JambaHelperSettings:GetContinueLabelHeight()
	local left = JambaHelperSettings:LeftOfSettings()
	local headingHeight = JambaHelperSettings:HeadingHeight()
	local headingWidth = JambaHelperSettings:HeadingWidth( false )
	local horizontalSpacing = JambaHelperSettings:GetHorizontalSpacing()
	local verticalSpacing = JambaHelperSettings:GetVerticalSpacing()
	local indent = horizontalSpacing * 10
	local indentContinueLabel = horizontalSpacing * 18
	local indentSpecial = indentContinueLabel + 9
	local checkBoxThirdWidth = (headingWidth - indentContinueLabel) / 3
	local column1Left = left
	local column1LeftIndent = left + indentContinueLabel
	local column2LeftIndent = column1LeftIndent + checkBoxThirdWidth + horizontalSpacing
	local column3LeftIndent = column2LeftIndent + checkBoxThirdWidth + horizontalSpacing
	local movingTop = top
	-- Create a heading for quest completion.
	JambaHelperSettings:CreateHeading( AJM.settingsControlCompletion, L["Quest Completion"], movingTop, false )
	movingTop = movingTop - headingHeight
	-- Check box: Enable auto quest completion.
	AJM.settingsControlCompletion.checkBoxEnableAutoQuestCompletion = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControlCompletion, 
		headingWidth, 
		column1Left, 
		movingTop,
		L["Enable Auto Quest Completion"],
		AJM.SettingsToggleEnableAutoQuestCompletion
	)	
	movingTop = movingTop - checkBoxHeight
	-- Label: Quest has no rewards or one reward.	
	AJM.settingsControlCompletion.labelQuestNoRewardsOrOneReward = JambaHelperSettings:CreateLabel( 
		AJM.settingsControlCompletion, 
		headingWidth, 
		column1Left, 
		movingTop,
		L["Quest Has No Rewards Or One Reward:"]
	)	
	movingTop = movingTop - labelHeight
	-- Radio box: No choice, slave do nothing.
	AJM.settingsControlCompletion.checkBoxNoChoiceAllDoNothing = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControlCompletion, 
		headingWidth, 
		column1Left, 
		movingTop,
		L["Toon Do Nothing"],
		AJM.SettingsToggleNoChoiceAllDoNothing
	)	
	AJM.settingsControlCompletion.checkBoxNoChoiceAllDoNothing:SetType( "radio" )
	movingTop = movingTop - radioBoxHeight	
	-- Radio box: No choice, slave complete quest with master.
	AJM.settingsControlCompletion.checkBoxNoChoiceSlaveCompleteQuestWithMaster = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControlCompletion, 
		headingWidth, 
		column1Left, 
		movingTop,
		L["Toon Complete Quest With Team"],
		AJM.SettingsToggleNoChoiceSlaveCompleteQuestWithMaster
	)
	AJM.settingsControlCompletion.checkBoxNoChoiceSlaveCompleteQuestWithMaster:SetType( "radio" )
	movingTop = movingTop - radioBoxHeight
	-- Radio box: No Choice, all automatically complete quest.
	AJM.settingsControlCompletion.checkBoxNoChoiceAllAutoCompleteQuest = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControlCompletion, 
		headingWidth, 
		column1Left, 
		movingTop,
		L["All Automatically Complete Quest"],
		AJM.SettingsToggleNoChoiceAllAutoCompleteQuest
	)	
	AJM.settingsControlCompletion.checkBoxNoChoiceAllAutoCompleteQuest:SetType( "radio" )
	movingTop = movingTop - radioBoxHeight
	-- Label: Quest has more than one reward.
	AJM.settingsControlCompletion.labelQuestHasMoreThanOneReward = JambaHelperSettings:CreateLabel( 
		AJM.settingsControlCompletion, 
		headingWidth, 
		column1Left, 
		movingTop,
		L["Quest Has More Than One Reward:"]
	)	
	movingTop = movingTop - labelHeight
	-- Radio box: Has choice, slave do nothing.
	AJM.settingsControlCompletion.checkBoxHasChoiceSlaveDoNothing = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControlCompletion, 
		headingWidth, 
		column1Left, 
		movingTop,
		L["Toon Do Nothing"],
		AJM.SettingsToggleHasChoiceSlaveDoNothing
	)	
	AJM.settingsControlCompletion.checkBoxHasChoiceSlaveDoNothing:SetType( "radio" )
--	movingTop = movingTop - radioBoxHeight
	-- TODO: Fix or remove.
	-- Radio box: Has choice, choose best reward.
--		AJM.settingsControlCompletion.checkBoxHasChoiceAquireBestQuestRewardForCharacter = JambaHelperSettings:CreateCheckBox( 
--		AJM.settingsControlCompletion, 
--		headingWidth, 
--		column1Left, 
--		movingTop,
--		L["Toon Auto Selects Best Reward"],
--		AJM.SettingsToggleHasChoiceAquireBestQuestRewardForCharacter
--	)	
--	AJM.settingsControlCompletion.checkBoxHasChoiceAquireBestQuestRewardForCharacter:SetType( "radio" )
--	movingTop = movingTop - radioBoxHeight
	-- Radio box: Has choice, choose best reward - actually get it.
--	AJM.settingsControlCompletion.checkBoxActuallyGetTheBestReward = JambaHelperSettings:CreateCheckBox( 
--		AJM.settingsControlCompletion, 
--		headingWidth, 
--		column1Left + indent, 
--		movingTop,
--		L["And Claims It As Well"],
--		AJM.SettingsToggleActuallyGetTheBestReward
--	)	
	movingTop = movingTop - checkBoxHeight	
	-- Radio box: Has choice, slave complete quest with master.
	AJM.settingsControlCompletion.checkBoxHasChoiceSlaveCompleteQuestWithMaster = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControlCompletion, 
		headingWidth, 
		column1Left, 
		movingTop,
		L["Toon Complete Quest With Team"],
		AJM.SettingsToggleHasChoiceSlaveCompleteQuestWithMaster
	)	
	AJM.settingsControlCompletion.checkBoxHasChoiceSlaveCompleteQuestWithMaster:SetType( "radio" )
	movingTop = movingTop - radioBoxHeight
	-- Radio box: Has choice, slave must choose own reward.
	AJM.settingsControlCompletion.checkBoxHasChoiceSlaveMustChooseOwnReward = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControlCompletion, 
		headingWidth, 
		column1Left + indent, 
		movingTop,
		L["Toon Must Choose Own Reward"],
		AJM.SettingsToggleHasChoiceSlaveMustChooseOwnReward
	)	
	AJM.settingsControlCompletion.checkBoxHasChoiceSlaveMustChooseOwnReward:SetType( "radio" )
	movingTop = movingTop - radioBoxHeight	
	-- Radio box: Has choice, slave choose same reward as master.
	AJM.settingsControlCompletion.checkBoxHasChoiceSlaveChooseSameRewardAsMaster = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControlCompletion, 
		headingWidth, 
		column1Left + indent, 
		movingTop,
		L["Toon Choose Same Reward As Team"],
		AJM.SettingsToggleHasChoiceSlaveChooseSameRewardAsMaster
	)	
	AJM.settingsControlCompletion.checkBoxHasChoiceSlaveChooseSameRewardAsMaster:SetType( "radio" )
	movingTop = movingTop - radioBoxHeight
	-- Radio box: Has choice, slave reward choice depends on modifier key pressed down.
	AJM.settingsControlCompletion.checkBoxHasChoiceSlaveRewardChoiceModifierConditional = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControlCompletion, 
		headingWidth, 
		column1Left + indent, 
		movingTop,
		L["If Modifier Keys Pressed, Toon Choose Same Reward"],
		AJM.SettingsToggleHasChoiceSlaveRewardChoiceModifierConditional
	)	
	AJM.settingsControlCompletion.checkBoxHasChoiceSlaveRewardChoiceModifierConditional:SetType( "radio" )
	movingTop = movingTop - radioBoxHeight
	-- Label continuing radio box above.
	AJM.settingsControlCompletion.labelHasChoiceSlaveRewardChoiceModifierConditional = JambaHelperSettings:CreateContinueLabel( 
		AJM.settingsControlCompletion, 
		headingWidth, 
		column1Left + indentContinueLabel, 
		movingTop,
		L["As Team Otherwise Toon Must Choose Own Reward"]
	)	
	movingTop = movingTop - labelContinueHeight	
	-- Check box: Ctrl modifier key.
	AJM.settingsControlCompletion.checkBoxHasChoiceCtrlKeyModifier = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControlCompletion, 
		checkBoxThirdWidth, 
		column1LeftIndent, 
		movingTop,
		L["Ctrl"],
		AJM.SettingsToggleHasChoiceCtrlKeyModifier
	)	
	-- Check box: Shift modifier key.
	AJM.settingsControlCompletion.checkBoxHasChoiceShiftKeyModifier = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControlCompletion, 
		checkBoxThirdWidth, 
		column2LeftIndent, 
		movingTop,
		L["Shift"],
		AJM.SettingsToggleHasChoiceShiftKeyModifier
	)	
	-- Check box: Alt modifier key.
	AJM.settingsControlCompletion.checkBoxHasChoiceAltKeyModifier = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControlCompletion, 
		checkBoxThirdWidth, 
		column3LeftIndent, 
		movingTop,
		L["Alt"],
		AJM.SettingsToggleHasChoiceAltKeyModifier
	)	
	movingTop = movingTop - checkBoxHeight
	-- Check box: Has choice, override, if slave already has reward selected, choose that reward.
	AJM.settingsControlCompletion.checkBoxHasChoiceOverrideUseSlaveRewardSelected = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControlCompletion, 
		headingWidth, 
		column1Left + indent, 
		movingTop,
		L["Override: If Toon Already Has Reward Selected,"],
		AJM.SettingsToggleHasChoiceOverrideUseSlaveRewardSelected
	)	
	movingTop = movingTop - checkBoxHeight
	-- Label continuing check box above.
	AJM.settingsControlCompletion.labelHasChoiceOverrideUseSlaveRewardSelected = JambaHelperSettings:CreateContinueLabel( 
		AJM.settingsControlCompletion, 
		headingWidth, 
		column1Left + indentSpecial, 
		movingTop,
		L["Choose That Reward"]
	)	
	movingTop = movingTop - labelContinueHeight	
	return movingTop	
end

-------------------------------------------------------------------------------------------------------------
-- Settings functionality.
-------------------------------------------------------------------------------------------------------------

-- Settings received.
function AJM:JambaOnSettingsReceived( characterName, settings )	
	if characterName ~= AJM.characterName then
		-- Update the settings.
		AJM.db.mirrorMasterQuestSelectionAndDeclining = settings.mirrorMasterQuestSelectionAndDeclining
		AJM.db.allAutoSelectQuests = settings.allAutoSelectQuests
		AJM.db.acceptQuests = settings.acceptQuests
		AJM.db.slaveMirrorMasterAccept = settings.slaveMirrorMasterAccept
		AJM.db.doNotAutoAccept = settings.doNotAutoAccept 
		AJM.db.allAcceptAnyQuest = settings.allAcceptAnyQuest
		AJM.db.onlyAcceptQuestsFrom = settings.onlyAcceptQuestsFrom
		AJM.db.acceptFromTeam = settings.acceptFromTeam
		AJM.db.acceptFromNpc = settings.acceptFromNpc
		AJM.db.acceptFromFriends = settings.acceptFromFriends
		AJM.db.acceptFromParty = settings.acceptFromParty
		AJM.db.acceptFromRaid = settings.acceptFromRaid
		AJM.db.acceptFromGuild = settings.acceptFromGuild
		AJM.db.masterAutoShareQuestOnAccept = settings.masterAutoShareQuestOnAccept
		AJM.db.slaveAutoAcceptEscortQuest = settings.slaveAutoAcceptEscortQuest
		AJM.db.showJambaQuestLogWithWoWQuestLog = settings.showJambaQuestLogWithWoWQuestLog
		AJM.db.enableAutoQuestCompletion = settings.enableAutoQuestCompletion
		AJM.db.noChoiceAllDoNothing = settings.noChoiceAllDoNothing
		AJM.db.noChoiceSlaveCompleteQuestWithMaster = settings.noChoiceSlaveCompleteQuestWithMaster
		AJM.db.noChoiceAllAutoCompleteQuest = settings.noChoiceAllAutoCompleteQuest
		AJM.db.hasChoiceSlaveDoNothing = settings.hasChoiceSlaveDoNothing
		AJM.db.hasChoiceSlaveCompleteQuestWithMaster = settings.hasChoiceSlaveCompleteQuestWithMaster
		AJM.db.hasChoiceSlaveChooseSameRewardAsMaster = settings.hasChoiceSlaveChooseSameRewardAsMaster
		AJM.db.hasChoiceSlaveMustChooseOwnReward = settings.hasChoiceSlaveMustChooseOwnReward
		AJM.db.hasChoiceSlaveRewardChoiceModifierConditional = settings.hasChoiceSlaveRewardChoiceModifierConditional
		AJM.db.hasChoiceCtrlKeyModifier = settings.hasChoiceCtrlKeyModifier
		AJM.db.hasChoiceShiftKeyModifier = settings.hasChoiceShiftKeyModifier
		AJM.db.hasChoiceAltKeyModifier = settings.hasChoiceAltKeyModifier
		AJM.db.hasChoiceOverrideUseSlaveRewardSelected = settings.hasChoiceOverrideUseSlaveRewardSelected
--		AJM.db.hasChoiceAquireBestQuestRewardForCharacter = settings.hasChoiceAquireBestQuestRewardForCharacter
--		AJM.db.hasChoiceAquireBestQuestRewardForCharacterAndGet = settings.hasChoiceAquireBestQuestRewardForCharacterAndGet
		AJM.db.messageArea = settings.messageArea
		AJM.db.warningArea = settings.warningArea
		AJM.db.overrideQuestAutoSelectAndComplete = settings.overrideQuestAutoSelectAndComplete
		-- Refresh the settings.
		AJM:SettingsRefresh()
		-- Tell the player.
		AJM:Print( L["Settings received from A."]( characterName ) )
	end
end

-------------------------------------------------------------------------------------------------------------
-- Settings Populate.
-------------------------------------------------------------------------------------------------------------

function AJM:BeforeJambaProfileChanged()	
end

function AJM:OnJambaProfileChanged()	
	AJM:SettingsRefresh()
end

function AJM:SettingsRefresh()
	-- Quest general and acceptance options.
	AJM.settingsControl.checkBoxMirrorMasterQuestSelectionAndDeclining:SetValue( AJM.db.mirrorMasterQuestSelectionAndDeclining )
	AJM.settingsControl.checkBoxAllAutoSelectQuests:SetValue( AJM.db.allAutoSelectQuests )
	AJM.settingsControl.checkBoxAcceptQuests:SetValue( AJM.db.acceptQuests )
	AJM.settingsControl.checkBoxSlaveMirrorMasterAccept:SetValue( AJM.db.slaveMirrorMasterAccept )
	AJM.settingsControl.checkBoxDoNotAutoAccept:SetValue( AJM.db.doNotAutoAccept )
	AJM.settingsControl.checkBoxAllAcceptAnyQuest:SetValue( AJM.db.allAcceptAnyQuest )
	AJM.settingsControl.checkBoxOnlyAcceptQuestsFrom:SetValue( AJM.db.onlyAcceptQuestsFrom )
	AJM.settingsControl.checkBoxAcceptFromTeam:SetValue( AJM.db.acceptFromTeam )
	AJM.settingsControl.checkBoxAcceptFromNpc:SetValue( AJM.db.acceptFromNpc )
	AJM.settingsControl.checkBoxAcceptFromFriends:SetValue( AJM.db.acceptFromFriends )
	AJM.settingsControl.checkBoxAcceptFromParty:SetValue( AJM.db.acceptFromParty )
	AJM.settingsControl.checkBoxAcceptFromRaid:SetValue( AJM.db.acceptFromRaid )
	AJM.settingsControl.checkBoxAcceptFromGuild:SetValue( AJM.db.acceptFromGuild )
	AJM.settingsControl.checkBoxMasterAutoShareQuestOnAccept:SetValue( AJM.db.masterAutoShareQuestOnAccept )
	AJM.settingsControl.checkBoxSlaveAutoAcceptEscortQuest:SetValue( AJM.db.slaveAutoAcceptEscortQuest )
	AJM.settingsControl.checkBoxShowJambaQuestLogWithWoWQuestLog:SetValue( AJM.db.showJambaQuestLogWithWoWQuestLog )
	AJM.settingsControl.checkBoxOverrideQuestAutoSelectAndComplete:SetValue( AJM.db.overrideQuestAutoSelectAndComplete )
	AJM.settingsControl.dropdownMessageArea:SetValue( AJM.db.messageArea )
	AJM.settingsControl.dropdownWarningArea:SetValue( AJM.db.warningArea )
	-- Quest completion options.
	AJM.settingsControlCompletion.checkBoxEnableAutoQuestCompletion:SetValue( AJM.db.enableAutoQuestCompletion )
	AJM.settingsControlCompletion.checkBoxNoChoiceAllDoNothing:SetValue( AJM.db.noChoiceAllDoNothing )
	AJM.settingsControlCompletion.checkBoxNoChoiceSlaveCompleteQuestWithMaster:SetValue( AJM.db.noChoiceSlaveCompleteQuestWithMaster )
	AJM.settingsControlCompletion.checkBoxNoChoiceAllAutoCompleteQuest:SetValue( AJM.db.noChoiceAllAutoCompleteQuest )
	AJM.settingsControlCompletion.checkBoxHasChoiceSlaveDoNothing:SetValue( AJM.db.hasChoiceSlaveDoNothing )
	AJM.settingsControlCompletion.checkBoxHasChoiceSlaveCompleteQuestWithMaster:SetValue( AJM.db.hasChoiceSlaveCompleteQuestWithMaster )
	AJM.settingsControlCompletion.checkBoxHasChoiceSlaveChooseSameRewardAsMaster:SetValue( AJM.db.hasChoiceSlaveChooseSameRewardAsMaster )
	AJM.settingsControlCompletion.checkBoxHasChoiceSlaveMustChooseOwnReward:SetValue( AJM.db.hasChoiceSlaveMustChooseOwnReward )
--	Ebony Fix or remove,
--	AJM.settingsControlCompletion.checkBoxHasChoiceAquireBestQuestRewardForCharacter:SetValue( AJM.db.hasChoiceAquireBestQuestRewardForCharacter )
--	AJM.settingsControlCompletion.checkBoxActuallyGetTheBestReward:SetValue( AJM.db.hasChoiceAquireBestQuestRewardForCharacterAndGet )
	AJM.settingsControlCompletion.checkBoxHasChoiceSlaveRewardChoiceModifierConditional:SetValue( AJM.db.hasChoiceSlaveRewardChoiceModifierConditional )
	AJM.settingsControlCompletion.checkBoxHasChoiceCtrlKeyModifier:SetValue( AJM.db.hasChoiceCtrlKeyModifier )
	AJM.settingsControlCompletion.checkBoxHasChoiceShiftKeyModifier:SetValue( AJM.db.hasChoiceShiftKeyModifier )
	AJM.settingsControlCompletion.checkBoxHasChoiceAltKeyModifier:SetValue( AJM.db.hasChoiceAltKeyModifier )
	AJM.settingsControlCompletion.checkBoxHasChoiceOverrideUseSlaveRewardSelected:SetValue( AJM.db.hasChoiceOverrideUseSlaveRewardSelected )
	-- Ensure correct state (general and acceptance options).
	AJM.settingsControl.checkBoxSlaveMirrorMasterAccept:SetDisabled( not AJM.db.acceptQuests )
	AJM.settingsControl.checkBoxDoNotAutoAccept:SetDisabled( not AJM.db.acceptQuests )
	AJM.settingsControl.checkBoxAllAcceptAnyQuest:SetDisabled( not AJM.db.acceptQuests )
	AJM.settingsControl.checkBoxOnlyAcceptQuestsFrom:SetDisabled( not AJM.db.acceptQuests )
	AJM.settingsControl.checkBoxAcceptFromTeam:SetDisabled( not AJM.db.acceptQuests or not AJM.db.onlyAcceptQuestsFrom )
	AJM.settingsControl.checkBoxAcceptFromNpc:SetDisabled( not AJM.db.acceptQuests or not AJM.db.onlyAcceptQuestsFrom )
	AJM.settingsControl.checkBoxAcceptFromFriends:SetDisabled( not AJM.db.acceptQuests or not AJM.db.onlyAcceptQuestsFrom )
	AJM.settingsControl.checkBoxAcceptFromParty:SetDisabled( not AJM.db.acceptQuests or not AJM.db.onlyAcceptQuestsFrom )
	AJM.settingsControl.checkBoxAcceptFromRaid:SetDisabled( not AJM.db.acceptQuests or not AJM.db.onlyAcceptQuestsFrom )
	AJM.settingsControl.checkBoxAcceptFromGuild:SetDisabled( not AJM.db.acceptQuests or not AJM.db.onlyAcceptQuestsFrom )
	-- Ensure correct state (completion options). 
	AJM.settingsControlCompletion.labelQuestNoRewardsOrOneReward:SetDisabled( not AJM.db.enableAutoQuestCompletion )
	AJM.settingsControlCompletion.labelQuestHasMoreThanOneReward:SetDisabled( not AJM.db.enableAutoQuestCompletion )
	AJM.settingsControlCompletion.checkBoxNoChoiceAllDoNothing:SetDisabled( not AJM.db.enableAutoQuestCompletion )
	AJM.settingsControlCompletion.checkBoxNoChoiceSlaveCompleteQuestWithMaster:SetDisabled( not AJM.db.enableAutoQuestCompletion )
	AJM.settingsControlCompletion.checkBoxNoChoiceAllAutoCompleteQuest:SetDisabled( not AJM.db.enableAutoQuestCompletion )
	AJM.settingsControlCompletion.checkBoxHasChoiceSlaveDoNothing:SetDisabled( not AJM.db.enableAutoQuestCompletion )
--	AJM.settingsControlCompletion.checkBoxHasChoiceAquireBestQuestRewardForCharacter:SetDisabled( not AJM.db.enableAutoQuestCompletion )
--	AJM.settingsControlCompletion.checkBoxActuallyGetTheBestReward:SetDisabled( not AJM.db.enableAutoQuestCompletion or not AJM.db.hasChoiceAquireBestQuestRewardForCharacter )
	AJM.settingsControlCompletion.checkBoxHasChoiceSlaveCompleteQuestWithMaster:SetDisabled( not AJM.db.enableAutoQuestCompletion )
	AJM.settingsControlCompletion.checkBoxHasChoiceSlaveChooseSameRewardAsMaster:SetDisabled( not AJM.db.enableAutoQuestCompletion or not AJM.db.hasChoiceSlaveCompleteQuestWithMaster )
	AJM.settingsControlCompletion.checkBoxHasChoiceSlaveMustChooseOwnReward:SetDisabled( not AJM.db.enableAutoQuestCompletion or not AJM.db.hasChoiceSlaveCompleteQuestWithMaster )
	AJM.settingsControlCompletion.checkBoxHasChoiceSlaveRewardChoiceModifierConditional:SetDisabled( not AJM.db.enableAutoQuestCompletion or not AJM.db.hasChoiceSlaveCompleteQuestWithMaster )
	AJM.settingsControlCompletion.labelHasChoiceSlaveRewardChoiceModifierConditional:SetDisabled( not AJM.db.enableAutoQuestCompletion or not AJM.db.hasChoiceSlaveCompleteQuestWithMaster )
	AJM.settingsControlCompletion.checkBoxHasChoiceCtrlKeyModifier:SetDisabled( not AJM.db.enableAutoQuestCompletion or not AJM.db.hasChoiceSlaveCompleteQuestWithMaster or not AJM.db.hasChoiceSlaveRewardChoiceModifierConditional )
	AJM.settingsControlCompletion.checkBoxHasChoiceShiftKeyModifier:SetDisabled( not AJM.db.enableAutoQuestCompletion or not AJM.db.hasChoiceSlaveCompleteQuestWithMaster or not AJM.db.hasChoiceSlaveRewardChoiceModifierConditional )
	AJM.settingsControlCompletion.checkBoxHasChoiceAltKeyModifier:SetDisabled( not AJM.db.enableAutoQuestCompletion or not AJM.db.hasChoiceSlaveCompleteQuestWithMaster or not AJM.db.hasChoiceSlaveRewardChoiceModifierConditional )
	AJM.settingsControlCompletion.checkBoxHasChoiceOverrideUseSlaveRewardSelected:SetDisabled( not AJM.db.enableAutoQuestCompletion or not AJM.db.hasChoiceSlaveCompleteQuestWithMaster )
	AJM.settingsControlCompletion.labelHasChoiceOverrideUseSlaveRewardSelected:SetDisabled( not AJM.db.enableAutoQuestCompletion or not AJM.db.hasChoiceSlaveCompleteQuestWithMaster )
end

function AJM:SettingsPushSettingsClick( event )
	AJM:JambaSendSettings()
end

function AJM:SettingsToggleMirrorMasterQuestSelectionAndDeclining( event, checked )
	AJM.db.mirrorMasterQuestSelectionAndDeclining = checked
	AJM.db.allAutoSelectQuests = not checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleAllAutoSelectQuests( event, checked )
	AJM.db.allAutoSelectQuests = checked
	AJM.db.mirrorMasterQuestSelectionAndDeclining = not checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleAcceptQuests( event, checked )
	AJM.db.acceptQuests = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleSlaveMirrorMasterAccept( event, checked )
	AJM.db.slaveMirrorMasterAccept = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleOverrideQuestAutoSelectAndComplete( event, checked )
	AJM.db.overrideQuestAutoSelectAndComplete = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleDoNotAutoAccept( event, checked )
	AJM.db.doNotAutoAccept = checked
	AJM.db.allAcceptAnyQuest = not checked
	AJM.db.onlyAcceptQuestsFrom = not checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleAllAcceptAnyQuest( event, checked )
	AJM.db.allAcceptAnyQuest = checked
	AJM.db.onlyAcceptQuestsFrom = not checked
	AJM.db.doNotAutoAccept = not checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleOnlyAcceptQuestsFrom( event, checked )
	AJM.db.onlyAcceptQuestsFrom = checked
	AJM.db.allAcceptAnyQuest = not checked
	AJM.db.doNotAutoAccept = not checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleAcceptFromTeam( event, checked )
	AJM.db.acceptFromTeam = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleAcceptFromNpc( event, checked )
	AJM.db.acceptFromNpc = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleAcceptFromFriends( event, checked )
	AJM.db.acceptFromFriends = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleAcceptFromParty( event, checked )
	AJM.db.acceptFromParty = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleAcceptFromRaid( event, checked )
	AJM.db.acceptFromRaid = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleAcceptFromGuild( event, checked )
	AJM.db.acceptFromGuild = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleMasterAutoShareQuestOnAccept( event, checked )
	AJM.db.masterAutoShareQuestOnAccept = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleSlaveAutoAcceptEscortQuest( event, checked )
	AJM.db.slaveAutoAcceptEscortQuest = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleShowJambaQuestLogWithWoWQuestLog( event, checked )
	AJM.db.showJambaQuestLogWithWoWQuestLog = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleEnableAutoQuestCompletion( event, checked )
	AJM.db.enableAutoQuestCompletion = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleNoChoiceAllDoNothing( event, checked )
	AJM.db.noChoiceAllDoNothing = checked
	AJM.db.noChoiceSlaveCompleteQuestWithMaster = not checked
	AJM.db.noChoiceAllAutoCompleteQuest = not checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleNoChoiceSlaveCompleteQuestWithMaster( event, checked )
	AJM.db.noChoiceSlaveCompleteQuestWithMaster = checked
	AJM.db.noChoiceAllDoNothing = not checked
	AJM.db.noChoiceAllAutoCompleteQuest = not checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleNoChoiceAllAutoCompleteQuest( event, checked )
	AJM.db.noChoiceAllAutoCompleteQuest = checked
	AJM.db.noChoiceAllDoNothing = not checked
	AJM.db.noChoiceSlaveCompleteQuestWithMaster = not checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleHasChoiceSlaveDoNothing( event, checked )
	AJM.db.hasChoiceSlaveDoNothing = checked
	AJM.db.hasChoiceAquireBestQuestRewardForCharacter = not checked
	AJM.db.hasChoiceSlaveCompleteQuestWithMaster = not checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleHasChoiceSlaveCompleteQuestWithMaster( event, checked )
	AJM.db.hasChoiceSlaveCompleteQuestWithMaster = checked
	AJM.db.hasChoiceAquireBestQuestRewardForCharacter = not checked
	AJM.db.hasChoiceSlaveDoNothing = not checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleHasChoiceAquireBestQuestRewardForCharacter( event, checked )
	AJM.db.hasChoiceAquireBestQuestRewardForCharacter = checked
	AJM.db.hasChoiceSlaveCompleteQuestWithMaster = not checked
	AJM.db.hasChoiceSlaveDoNothing = not checked
	AJM:SettingsRefresh()
end

--function AJM:SettingsToggleActuallyGetTheBestReward( event, checked )
--	AJM.db.hasChoiceAquireBestQuestRewardForCharacterAndGet = checked
--	AJM:SettingsRefresh()
--end

function AJM:SettingsToggleHasChoiceSlaveChooseSameRewardAsMaster( event, checked )
	AJM.db.hasChoiceSlaveChooseSameRewardAsMaster = checked
	AJM.db.hasChoiceSlaveMustChooseOwnReward = not checked
	AJM.db.hasChoiceSlaveRewardChoiceModifierConditional = not checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleHasChoiceSlaveMustChooseOwnReward( event, checked )
	AJM.db.hasChoiceSlaveMustChooseOwnReward = checked
	AJM.db.hasChoiceSlaveChooseSameRewardAsMaster = not checked
	AJM.db.hasChoiceSlaveRewardChoiceModifierConditional = not checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleHasChoiceSlaveRewardChoiceModifierConditional( event, checked )
	AJM.db.hasChoiceSlaveRewardChoiceModifierConditional = checked
	AJM.db.hasChoiceSlaveChooseSameRewardAsMaster = not checked
	AJM.db.hasChoiceSlaveMustChooseOwnReward = not checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleHasChoiceCtrlKeyModifier( event, checked )
	AJM.db.hasChoiceCtrlKeyModifier = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleHasChoiceShiftKeyModifier( event, checked )
	AJM.db.hasChoiceShiftKeyModifier = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleHasChoiceAltKeyModifier( event, checked )
	AJM.db.hasChoiceAltKeyModifier = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleHasChoiceOverrideUseSlaveRewardSelected( event, checked )
	AJM.db.hasChoiceOverrideUseSlaveRewardSelected = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsSetMessageArea( event, messageAreaValue )
	AJM:DebugMessage( event, messageAreaValue )
	AJM.db.messageArea = messageAreaValue
	AJM:SettingsRefresh()
end

function AJM:SettingsSetWarningArea( event, messageAreaValue )
	AJM.db.warningArea = messageAreaValue
	AJM:SettingsRefresh()
end

-------------------------------------------------------------------------------------------------------------
-- NPC QUEST PROCESSING - SELECTING AND DECLINING
-------------------------------------------------------------------------------------------------------------

function AJM:ChurnNpcGossip()
    AJM:DebugMessage( "ChurnNpcGossip" )
	-- GetGossipAvailableQuests and GetGossipActiveQuests are returning nil in some cases, so do this as well.
	-- GetGossipAvailableQuests() now returns 6 elements per quest and GetGossipActiveQuests() returns 4. title, level, isTrivial, isDaily, ...
	-- Patch 5.0.4 added isLegendary.
	-- title1, level1, isLowLevel1, isDaily1, isRepeatable1, isLegendary1, title2, level2, isLowLevel2, isDaily2, isRepeatable2, isLegendary2 = GetGossipAvailableQuests()
	-- title1, level1, isLowLevel1, isComplete1, isLegendary1, title2, level2, isLowLevel2, isComplete2, isLegendary2 = GetGossipActiveQuests()
	local numberAvailableQuestInfo = 6
	local numberActiveQuestInfo = 5
    local index
    AJM:DebugMessage( "GetNumAvailableQuests", GetNumAvailableQuests() )
    AJM:DebugMessage( "GetNumActiveQuests", GetNumActiveQuests() )
    AJM:DebugMessage( "GetGossipAvailableQuests", GetGossipAvailableQuests() )
    AJM:DebugMessage( "GetGossipActiveQuests", GetGossipActiveQuests() )
    for index = 0, GetNumAvailableQuests() do
		SelectAvailableQuest( index )
	end
    for index = 0, GetNumActiveQuests() do
		SelectActiveQuest( index )
	end
	JambaUtilities:ClearTable( AJM.gossipQuests )
	local availableQuestsData = { GetGossipAvailableQuests() }
	local iterateQuests = 1
	local questIndex = 1
	while( availableQuestsData[iterateQuests] ) do
		local questInformation = {}
		questInformation.type = "available"
		questInformation.index = questIndex
		questInformation.name = availableQuestsData[iterateQuests]
		questInformation.level = availableQuestsData[iterateQuests + 1]
		table.insert( AJM.gossipQuests, questInformation )
		iterateQuests = iterateQuests + numberAvailableQuestInfo
		questIndex = questIndex + 1
	end
	local activeQuestsData = { GetGossipActiveQuests() }
	iterateQuests = 1
	while( activeQuestsData[iterateQuests] ) do
		local questInformation = {}
		questInformation.type = "active"
		questInformation.index = questIndex
		questInformation.name = activeQuestsData[iterateQuests]
		questInformation.level = activeQuestsData[iterateQuests + 1]
		questInformation.isComplete = activeQuestsData[iterateQuests + 3]
		table.insert( AJM.gossipQuests, questInformation )
		iterateQuests = iterateQuests + numberActiveQuestInfo
		questIndex = questIndex + 1
	end
	for index, questInformation in ipairs( AJM.gossipQuests ) do
		if questInformation.type == "available" then
			SelectGossipAvailableQuest( questInformation.index )
		end
		-- If this is an active quest...
		if questInformation.type == "active" then
			-- If this quest has been completed...
			if questInformation.isComplete then
				-- Complete it.
				SelectGossipActiveQuest( questInformation.index )
			end
		end			
	end

end

function AJM:CanAutomateAutoSelectAndComplete()
	if AJM.db.overrideQuestAutoSelectAndComplete == true then
		if IsShiftKeyDown() then
		   return false
		else
		   return true
		end
	end
	return true
 end

function AJM:GOSSIP_SHOW()
	if AJM.db.allAutoSelectQuests == true and AJM:CanAutomateAutoSelectAndComplete() == true then
        AJM:ChurnNpcGossip()
	end
end

function AJM:QUEST_GREETING()
	if AJM.db.allAutoSelectQuests == true and AJM:CanAutomateAutoSelectAndComplete() == true then
		AJM:ChurnNpcGossip()
	end
end

function AJM:QUEST_PROGRESS()
	if AJM.db.allAutoSelectQuests == true and AJM:CanAutomateAutoSelectAndComplete() == true then
		if IsQuestCompletable() then
			CompleteQuest()
		end
	end
end

function AJM:SelectGossipOption( gossipIndex )
	if AJM.db.mirrorMasterQuestSelectionAndDeclining == true then
		if AJM.isInternalCommand == false then
            AJM:DebugMessage( "SelectGossipOption" )
			AJM:JambaSendCommandToTeam( AJM.COMMAND_SELECT_GOSSIP_OPTION, gossipIndex )
		end
	end		
end

function AJM:DoSelectGossipOption( sender, gossipIndex )
	if AJM.db.mirrorMasterQuestSelectionAndDeclining == true then
		AJM.isInternalCommand = true
        AJM:DebugMessage( "DoSelectGossipOption" )
		SelectGossipOption( gossipIndex )
		AJM.isInternalCommand = false
	end		
end

function AJM:SelectGossipActiveQuest( gossipIndex )
	if AJM.db.mirrorMasterQuestSelectionAndDeclining == true then
		if AJM.isInternalCommand == false then
            AJM:DebugMessage( "SelectGossipActiveQuest" )
			AJM:JambaSendCommandToTeam( AJM.COMMAND_SELECT_GOSSIP_ACTIVE_QUEST, gossipIndex )		
		end
	end		
end

function AJM:DoSelectGossipActiveQuest( sender, gossipIndex )
	if AJM.db.mirrorMasterQuestSelectionAndDeclining == true then
		AJM.isInternalCommand = true
        AJM:DebugMessage( "DoSelectGossipActiveQuest" )
		SelectGossipActiveQuest( gossipIndex )
		AJM.isInternalCommand = false
	end
end

function AJM:SelectGossipAvailableQuest( gossipIndex )
	if AJM.db.mirrorMasterQuestSelectionAndDeclining == true then
		if AJM.isInternalCommand == false then
            AJM:DebugMessage( "SelectGossipAvailableQuest" )
			AJM:JambaSendCommandToTeam( AJM.COMMAND_SELECT_GOSSIP_AVAILABLE_QUEST, gossipIndex )
		end
	end
end

function AJM:DoSelectGossipAvailableQuest( sender, gossipIndex )
	if AJM.db.mirrorMasterQuestSelectionAndDeclining == true then
		AJM.isInternalCommand = true
        AJM:DebugMessage( "DoSelectGossipAvailableQuest" )
		SelectGossipAvailableQuest( gossipIndex )
		AJM.isInternalCommand = false
	end
end

function AJM:SelectActiveQuest( questIndex )
	if AJM.db.mirrorMasterQuestSelectionAndDeclining == true then
		if AJM.isInternalCommand == false then
            AJM:DebugMessage( "SelectActiveQuest" )
			AJM:JambaSendCommandToTeam( AJM.COMMAND_SELECT_ACTIVE_QUEST, questIndex )
		end
	end		
end

function AJM:DoSelectActiveQuest( sender, questIndex )
	if AJM.db.mirrorMasterQuestSelectionAndDeclining == true then
		AJM.isInternalCommand = true
        AJM:DebugMessage( "DoSelectActiveQuest" )
		SelectActiveQuest( questIndex )
		AJM.isInternalCommand = false
	end
end

function AJM:SelectAvailableQuest( questIndex )
	if AJM.db.mirrorMasterQuestSelectionAndDeclining == true then	
		if AJM.isInternalCommand == false then
            AJM:DebugMessage( "SelectAvailableQuest" )
			AJM:JambaSendCommandToTeam( AJM.COMMAND_SELECT_AVAILABLE_QUEST, questIndex )
		end
	end		
end

function AJM:DoSelectAvailableQuest( sender, questIndex )
	if AJM.db.mirrorMasterQuestSelectionAndDeclining == true then
		AJM.isInternalCommand = true
        AJM:DebugMessage( "DoSelectAvailableQuest" )
		SelectAvailableQuest( questIndex )
		AJM.isInternalCommand = false
	end
end

function AJM:DeclineQuest()
	if AJM.db.mirrorMasterQuestSelectionAndDeclining == true then
		if AJM.isInternalCommand == false then
            AJM:DebugMessage( "DeclineQuest" )
			AJM:JambaSendCommandToTeam( AJM.COMMAND_DECLINE_QUEST )
		end
	end		
end

function AJM:DoDeclineQuest( sender )
	if AJM.db.mirrorMasterQuestSelectionAndDeclining == true then
		AJM.isInternalCommand = true
        AJM:DebugMessage( "DoDeclineQuest" )
		DeclineQuest()
		AJM.isInternalCommand = false
	end
end

-------------------------------------------------------------------------------------------------------------
-- NPC QUEST PROCESSING - COMPLETING
-------------------------------------------------------------------------------------------------------------

function AJM:CompleteQuest()  
	if AJM.db.enableAutoQuestCompletion == true then
		if AJM.isInternalCommand == false then
            AJM:DebugMessage( "CompleteQuest" )
			AJM:JambaSendCommandToTeam( AJM.COMMAND_COMPLETE_QUEST )
		end
	end
end

function AJM:DoCompleteQuest( sender )
	if AJM.db.enableAutoQuestCompletion == true then
		AJM.isInternalCommand = true
        AJM:DebugMessage( "DoCompleteQuest" )
		CompleteQuest()
		AJM.isInternalCommand = false
	end	
end

function AJM:QUEST_COMPLETE()
    AJM:DebugMessage( "QUEST_COMPLETE" )
	if AJM.db.enableAutoQuestCompletion == true then
		if (AJM.db.hasChoiceAquireBestQuestRewardForCharacter == true) and (GetNumQuestChoices() > 1) then
			local bestQuestItemIndex = AJM:GetBestRewardIndexForCharacter()			
			if bestQuestItemIndex ~= nil and bestQuestItemIndex > 0 then
				local questItemChoice = _G["QuestInfoItem"..bestQuestItemIndex]
				QuestInfoItem_OnClick( questItemChoice )
				QuestInfoFrame.itemChoice = bestQuestItemIndex
				if AJM.db.hasChoiceAquireBestQuestRewardForCharacterAndGet == true then
					GetQuestReward( bestQuestItemIndex )
				end
			end
		elseif (AJM.db.noChoiceAllAutoCompleteQuest == true) and (GetNumQuestChoices() <= 1) then
			--AJM:JambaSendMessageToTeam( AJM.db.messageArea, L["Completed Quest: A"]( GetTitleText() ), false )
			GetQuestReward( GetNumQuestChoices() )
		end		
	end
end

-------------------------------------------------------------------------------------------------------------
-- IN THE FIELD QUEST PROCESSING - COMPLETING
-------------------------------------------------------------------------------------------------------------

function AJM:ShowQuestComplete( questIndex )
    AJM:DebugMessage( "ShowQuestComplete" )
	if AJM.db.enableAutoQuestCompletion == false then
		return
	end
	if AJM.isInternalCommand == true then
		return
	end
	local questName = select( 1, GetQuestLogTitle( questIndex ) )
	AJM:JambaSendCommandToTeam( AJM.COMMAND_LOG_COMPLETE_QUEST, questName )
end

function AJM:DoShowQuestComplete( sender, questName )
    AJM:DebugMessage( "DoShowQuestComplete" )
	if AJM.db.enableAutoQuestCompletion == false then
		return
	end
	AJM.isInternalCommand = true
	local questIndex = AJM:GetQuestLogIndexByName( questName )
	if questIndex ~= 0 then
		ShowQuestComplete( questIndex )
		--TODO fix this or remove still wip (this seems to be new code)
	-- WatchFrameAutoQuest_ClearPopUpByLogIndex( questIndex )
		AutoQuestPopupTracker_RemovePopUp ( questIndex )
	end
	AJM.isInternalCommand = false	
end

-------------------------------------------------------------------------------------------------------------
-- NPC QUEST PROCESSING - REWARDS
-------------------------------------------------------------------------------------------------------------

function AJM:CheckForOverrideAndChooseQuestReward( questIndex )
	-- Yes, override if slave has reward selected?
	if (AJM.db.hasChoiceOverrideUseSlaveRewardSelected == true) and (QuestInfoFrame.itemChoice > 0) then
		-- Yes, choose slaves reward.
		GetQuestReward( QuestInfoFrame.itemChoice )
	else
		-- No, choose masters reward.
		GetQuestReward( questIndex )
	end
end

function AJM:CheckForOverrideAndDoNotChooseQuestReward( questIndex )
	-- Yes, override if slave has reward selected?
	if QuestInfoFrame.itemChoice ~= nil then
		if (AJM.db.hasChoiceOverrideUseSlaveRewardSelected == true) and (QuestInfoFrame.itemChoice > 0) then
			-- Yes, choose slaves reward.
			GetQuestReward( QuestInfoFrame.itemChoice )
		end
	end
end

function AJM:AreCorrectConditionalKeysPressed()	
	local failTest = false
	if AJM.db.hasChoiceCtrlKeyModifier == true and not IsControlKeyDown() then
		failTest = true
	end
	if AJM.db.hasChoiceShiftKeyModifier == true and not IsShiftKeyDown() then
		failTest = true
	end
	if AJM.db.hasChoiceAltKeyModifier == true and not IsAltKeyDown() then
		failTest = true
	end
	return not failTest
end

function AJM:GetQuestReward( questIndex )
	if AJM.db.enableAutoQuestCompletion == true then
		if (AJM.db.noChoiceSlaveCompleteQuestWithMaster == true) or (AJM.db.hasChoiceSlaveCompleteQuestWithMaster == true) or (AJM.db.hasChoiceAquireBestQuestRewardForCharacter == true) then
			if AJM.isInternalCommand == false then
                AJM:DebugMessage( "GetQuestReward" )
				AJM:JambaSendCommandToTeam( AJM.COMMAND_CHOOSE_QUEST_REWARD, questIndex, AJM:AreCorrectConditionalKeysPressed(), AJM.db.hasChoiceAquireBestQuestRewardForCharacter )
			end
		end
	end		
end

function AJM:DoChooseQuestReward( sender, questIndex, modifierKeysPressed, rewardPickedAlready )
	local numberOfQuestRewards = GetNumQuestChoices()
	if AJM.db.enableAutoQuestCompletion == true then
		if (AJM.db.noChoiceSlaveCompleteQuestWithMaster == true) or (AJM.db.hasChoiceSlaveCompleteQuestWithMaster == true) or (AJM.db.hasChoiceAquireBestQuestRewardForCharacter == true) then
			AJM.isInternalCommand = true
            AJM:DebugMessage( "DoChooseQuestReward" )
            AJM:DebugMessage( "Quest has ", numberOfQuestRewards, " reward choices." )
			-- How many reward choices does this quest have?
			if numberOfQuestRewards <= 1 then
				-- One or less.
				if AJM.db.noChoiceSlaveCompleteQuestWithMaster == true then
					GetQuestReward( questIndex )
				end
			else
				-- More than one.
				if AJM.db.hasChoiceSlaveCompleteQuestWithMaster == true then
					-- Choose same as master?
					if AJM.db.hasChoiceSlaveChooseSameRewardAsMaster == true then
						AJM:CheckForOverrideAndChooseQuestReward( questIndex )
					-- Choose same as master, conditional keys?
					elseif AJM.db.hasChoiceSlaveRewardChoiceModifierConditional == true then
						if modifierKeysPressed == true then
							AJM:CheckForOverrideAndChooseQuestReward( questIndex )
						else
							AJM:CheckForOverrideAndDoNotChooseQuestReward( questIndex )
						end
					end
				end
				if (AJM.db.hasChoiceAquireBestQuestRewardForCharacter == true) and (rewardPickedAlready == true) then
					if QuestInfoFrame.itemChoice > 0 then
						-- Yes, choose slaves reward.
						GetQuestReward( QuestInfoFrame.itemChoice )
					end
				end
			end
			AJM.isInternalCommand = false
		end
	end
end

--TODO FIX or Remove!
function AJM:GetBestRewardIndexForCharacter()
	-- Originally provided by loop: http://www.dual-boxing.com/showpost.php?p=257610&postcount=1505
	-- New version provided by Mischanix via jamba.uservoice.com.
	-- Modified by Jafula.
	local numberOfQuestRewards = GetNumQuestChoices()
	local bestQuestItemIndex = 1
	local bestSellPrice = 0
	-- Yanked this from LibItemUtils; sucks that we need this lookup table, but GetItemInfo only 
	-- returns an equipment location, which must first be converted to a slot value that GetInventoryItemLink understands:
	local equipmentSlotLookup = {
		INVTYPE_HEAD = {"HeadSlot", nil},
		INVTYPE_NECK = {"NeckSlot", nil},
		INVTYPE_SHOULDER = {"ShoulderSlot", nil},
		INVTYPE_CLOAK = {"BackSlot", nil},
		INVTYPE_CHEST = {"ChestSlot", nil},
		INVTYPE_WRIST = {"WristSlot", nil},
		INVTYPE_HAND = {"HandsSlot", nil},
		INVTYPE_WAIST = {"WaistSlot", nil},
		INVTYPE_LEGS = {"LegsSlot", nil},
		INVTYPE_FEET = {"FeetSlot", nil},
		INVTYPE_SHIELD = {"SecondaryHandSlot", nil},
		INVTYPE_ROBE = {"ChestSlot", nil},
		INVTYPE_2HWEAPON = {"MainHandSlot", "SecondaryHandSlot"},
		INVTYPE_WEAPONMAINHAND = {"MainHandSlot", nil},
		INVTYPE_WEAPONOFFHAND = {"SecondaryHandSlot", "MainHandSlot"},
		INVTYPE_WEAPON = {"MainHandSlot","SecondaryHandSlot"},
		INVTYPE_THROWN = {"RangedSlot", nil},
		INVTYPE_RANGED = {"RangedSlot", nil},
		INVTYPE_RANGEDRIGHT = {"RangedSlot", nil},
		INVTYPE_FINGER = {"Finger0Slot", "Finger1Slot"},
		INVTYPE_HOLDABLE = {"SecondaryHandSlot", "MainHandSlot"},
		INVTYPE_TRINKET = {"Trinket0Slot", "Trinket1Slot"}
	} 
	local statWeights = {
		ITEM_MOD_STRENGTH_SHORT = 0x0C,
		ITEM_MOD_AGILITY_SHORT = 0x02,
		ITEM_MOD_INTELLECT_SHORT = 0x11,
		ITEM_MOD_SPELL_POWER_SHORT = 0x11,
		ITEM_MOD_SPIRIT_SHORT = 0x10,
		ITEM_MOD_HIT_RATING_SHORT = 0x07,
	}
	local classSpec = {
		DEATHKNIGHT1 = 0x08,
		DEATHKNIGHT2 = 0x04,
		DEATHKNIGHT3 = 0x04,
		DRUID1 = 0x01,
		DRUID2 = 0x02, -- Feral bears get agi itemization as well
		DRUID3 = 0x10,
		HUNTER1 = 0x02,
		HUNTER2 = 0x02,
		HUNTER3 = 0x02,
		MAGE1 = 0x01,
		MAGE2 = 0x01,
		MAGE3 = 0x01,
		PALADIN1 = 0x10,
		PALADIN2 = 0x08,
		PALADIN3 = 0x04,
		PRIEST1 = 0x10,
		PRIEST2 = 0x10,
		PRIEST3 = 0x01,
		ROGUE1 = 0x02,
		ROGUE2 = 0x02,
		ROGUE3 = 0x02,
		SHAMAN1 = 0x01,
		SHAMAN2 = 0x02,
		SHAMAN3 = 0x10,
		WARLOCK1 = 0x01,
		WARLOCK2 = 0x01,
		WARLOCK3 = 0x01,
		WARRIOR1 = 0x04,
		WARRIOR2 = 0x04,
		WARRIOR3 = 0x08,
	}
	local _, class = UnitClass("player")
	-- Original canWear - here for documentation purposes - Jafula.
	--[[
	local canWear = {
		DEATHKNIGHT = {"Cloth", "Leather", "Mail", "Plate", "Axe", "Mace", "Polearm", "Sword"},
		DRUID = {"Cloth", "Leather", "Dagger", "Fist Weapon", "Mace", "Polearm", "Staff"},
		HUNTER = {"Cloth", "Leather", "Mail", "Axe", "Dagger", "Fist Weapon", "Polearm", "Staff", "Sword", "Bow", "Crossbow", "Gun"},
		MAGE = {"Cloth", "Dagger", "Staff", "Sword", "Wand"},
		PALADIN = {"Cloth", "Leather", "Mail", "Plate", "Axe", "Mace", "Polearm", "Sword"},
		PRIEST = {"Cloth", "Dagger", "Mace", "Staff", "Wand"},
		ROGUE = {"Cloth", "Leather", "Dagger", "Fist Weapon", "Axe", "Mace", "Sword"},
		SHAMAN = {"Cloth", "Leather", "Mail", "Axe", "Dagger", "Fist Weapon", "Mace", "Staff"},
		WARLOCK = {"Cloth", "Dagger", "Staff", "Sword", "Wand"},
		WARRIOR = {"Cloth", "Leather", "Mail", "Plate", "Axe", "Dagger", "Fist Weapon", "Mace", "Polearm", "Staff", "Sword", "Bow", "Crossbow", "Gun", "Thrown"}
	}
	]]--
	-- Removed lower tier armour from canWear table (i.e. DKs, Paladins, Warriers can only wear Plate).
	-- I personally would not pick up a lower tiered piece for my toons.  Jafula.
	local canWear = {
		DEATHKNIGHT = {"Plate", "Guns", "One-Handed Axes", "One-Handed Maces", "One-Handed Swords", "Two-Handed Axes", "Two-Handed Maces", "Two-Handed Swords", "Sigils", "Miscellaneous"},
		DRUID = {"Leather", "Daggers", "Fist Weapons", "One-Handed Maces", "Polearms", "Staves", "Two-Handed Maces", "Idols", "Miscellaneous"},
		HUNTER = {"Mail", "Bows", "Crossbows", "Daggers", "Fist Weapons", "Guns", "One-Handed Axes", "One-Handed Swords", "Polearms", "Staves", "Two-Handed Axes", "Two-Handed Swords", "Thrown", "Miscellaneous"},
		MAGE = {"Cloth", "Daggers", "One-Handed Swords", "Staves", "Wands", "Miscellaneous"},
		PALADIN = {"Plate", "Shields", "Daggers", "One-Handed Axes", "One-Handed Maces", "One-Handed Swords", "Polearms", "Two-Handed Axes", "Two-Handed Maces", "Two-Handed Swords", "Librams", "Miscellaneous"},
		PRIEST = {"Cloth", "Daggers", "One-Handed Maces", "One-Handed Swords", "Staves", "Wands", "Miscellaneous"},
		ROGUE = {"Leather", "Bows", "Crossbows", "Daggers", "Fist Weapons", "Guns", "One-Handed Axes", "One-Handed Maces", "One-Handed Swords", "Thrown", "Miscellaneous"},
		SHAMAN = {"Mail", "Shields", "Daggers", "Fist Weapons", "One-Handed Axes", "One-Handed Maces", "Staves", "Two-Handed Axes", "Two-Handed Maces", "Totems", "Miscellaneous"}, 
		WARLOCK = {"Cloth", "Daggers", "One-Handed Swords", "Staves", "Wands", "Miscellaneous"},
		WARRIOR = {"Plate", "Shields", "Bows", "Crossbows", "Daggers", "Fist Weapons", "Guns", "One-Handed Axes", "One-Handed Maces", "One-Handed Swords", "Polearms","Staves", "Two-Handed Axes","Two-Handed Maces", "Two-Handed Swords", "Thrown", "Miscellaneous"}
	}
	local canWearLowbies = {
		DEATHKNIGHT = {"Plate", "Guns", "One-Handed Axes", "One-Handed Maces", "One-Handed Swords", "Two-Handed Axes", "Two-Handed Maces", "Two-Handed Swords", "Sigils", "Miscellaneous"},
		DRUID = {"Leather", "Daggers", "Fist Weapons", "One-Handed Maces", "Polearms", "Staves", "Two-Handed Maces", "Idols", "Miscellaneous"},
		HUNTER = {"Leather", "Bows", "Crossbows", "Daggers", "Fist Weapons", "Guns", "One-Handed Axes", "One-Handed Swords", "Polearms", "Staves", "Two-Handed Axes", "Two-Handed Swords", "Thrown", "Miscellaneous"},
		MAGE = {"Cloth", "Daggers", "One-Handed Swords", "Staves", "Wands", "Miscellaneous"},
		PALADIN = {"Mail", "Shields", "Daggers", "One-Handed Axes", "One-Handed Maces", "One-Handed Swords", "Polearms", "Two-Handed Axes", "Two-Handed Maces", "Two-Handed Swords", "Librams", "Miscellaneous"},
		PRIEST = {"Cloth", "Daggers", "One-Handed Maces", "One-Handed Swords", "Staves", "Wands", "Miscellaneous"},
		ROGUE = {"Leather", "Bows", "Crossbows", "Daggers", "Fist Weapons", "Guns", "One-Handed Axes", "One-Handed Maces", "One-Handed Swords", "Thrown", "Miscellaneous"},
		SHAMAN = {"Leather", "Shields", "Daggers", "Fist Weapons", "One-Handed Axes", "One-Handed Maces", "Staves", "Two-Handed Axes", "Two-Handed Maces", "Totems", "Miscellaneous"}, 
		WARLOCK = {"Cloth", "Daggers", "One-Handed Swords", "Staves", "Wands", "Miscellaneous"},
		WARRIOR = {"Mail", "Shields", "Bows", "Crossbows", "Daggers", "Fist Weapons", "Guns", "One-Handed Axes", "One-Handed Maces", "One-Handed Swords", "Polearms","Staves", "Two-Handed Axes","Two-Handed Maces", "Two-Handed Swords", "Thrown", "Miscellaneous"}
	}
	local compare = function(val, t)
		for _,v in ipairs(t) do if val == v then return true end end return false
	end
	local scaleRare = {
		1,
		1,
		1,
		1.11,
		1.67,
		2,
		2.2,
		1
	}
	if UnitLevel("player")<=58 then
		scaleRare[7] = UnitLevel("player")+15
	elseif UnitLevel("player")<=68 then
		scaleRare[7] = (UnitLevel("player")-60)*3 + 85
	elseif UnitLevel("player")<=79 then
		scaleRare[7] = (UnitLevel("player")-70)*4 + 134
	elseif UnitLevel("player")<=85 then
		scaleRare[7] = (UnitLevel("player")-80)*8 + 292
	end
	local ourItemization = classSpec[class..(GetSpecialization() or 1)]
	local statTable = {}
	local rewardTable = {}
	local countRewardNotLoaded = 0
	for questItemIndex = 1, numberOfQuestRewards do
		local rewardItemLink = GetQuestItemLink("choice", questItemIndex)
-- TODO: Remove
--AJM:Print( questItemIndex, " of ", numberOfQuestRewards, " is ", rewardItemLink )
		if rewardItemLink ~= nil then
			local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo( rewardItemLink )
			if itemSellPrice > bestSellPrice then
				bestSellPrice = itemSellPrice
				bestQuestItemIndex = questItemIndex
			end
			local relevance = 0
			local itemLevelD = 0
			GetItemStats(itemLink, statTable)
			for modifier, value in pairs(statTable) do
				if statWeights[modifier] and bit.band(ourItemization, statWeights[modifier]) ~= 0 then
					relevance = relevance + 1
				end
			end
			local lowLevel = 400
			local lowRare = 7
			if equipmentSlotLookup[itemEquipLoc] ~= nil then
				for _, a in ipairs( equipmentSlotLookup[itemEquipLoc] ) do
					local itemLink = GetInventoryItemLink( "player", GetInventorySlotInfo( a ) )
					if itemLink then
						local _, _, ourRare, ourLevel = GetItemInfo( itemLink )
						if ourLevel < lowLevel then
							lowLevel = ourLevel
							lowRare = ourRare
						end
					end
				end
				itemLevel = itemLevel * scaleRare[itemRarity]
				lowLevel = lowLevel * scaleRare[lowRare]
				itemLevelD = lowLevel - itemLevel			
				--AJM:Print( itemLevelD, relevance, compare( itemSubType, canWear[class] ), compare( itemSubType, canWearLowbies[class] ), itemSubType)
				local toonCanWearPiece = false
				if UnitLevel("player") <= 39 then
					toonCanWearPiece = compare( itemSubType, canWearLowbies[class] )
				else
					toonCanWearPiece = compare( itemSubType, canWear[class] )
				end
				if itemLevelD <= 0 and relevance > 0 and toonCanWearPiece == true then
				--AJM:Print( "added: ", questItemIndex)
					rewardTable[questItemIndex] = relevance
				end
				--AJM:Print(itemLink..": r="..relevance..", delta="..itemLevelD, "itemIndex="..questItemIndex)
				wipe(statTable)
			end
		else
			countRewardNotLoaded = countRewardNotLoaded + 1
		end
	end
	if countRewardNotLoaded > 0 then
		AJM:JambaSendMessageToTeam( AJM.db.messageArea, L["The reward information was not loaded from the server.  Close the quest window and open it again."], false )
	end
	bestR = -1
--AJM:Print( "dotable!" )
	for i, r in pairs( rewardTable ) do
		--AJM:Print( i, r )
		if r > bestR then
			bestQuestItemIndex = i
			bestR = r
		end
	end
	return bestQuestItemIndex
end

-------------------------------------------------------------------------------------------------------------
-- NPC QUEST PROCESSING - ACCEPTING
-------------------------------------------------------------------------------------------------------------

function AJM:QUEST_ACCEPTED( ... )
	local event, questIndex =  ...
	if AJM.db.acceptQuests == true then
		if AJM.db.masterAutoShareQuestOnAccept == true then	
			if JambaApi.IsCharacterTheMaster( AJM.characterName ) == true then
				if AJM.isInternalCommand == false then
					AJM:JambaSendMessageToTeam( AJM.db.messageArea, "Attempting to auto share newly accepted quest.", false )
					SelectQuestLogEntry( questIndex )
					if AJM:IsCurrentlySelectedQuestValid() == true then
						if GetQuestLogPushable() and GetNumSubgroupMembers() > 0 then
							AJM:JambaSendMessageToTeam( AJM.db.messageArea, "Pushing newly accepted quest.", false )
							QuestLogPushQuest()
						end
					end
				end	
			end
		end
	end
end

function AJM:AcceptQuest()
	if AJM.db.acceptQuests == true then
		if AJM.db.slaveMirrorMasterAccept == true then	
			if AJM.isInternalCommand == false then
				AJM:DebugMessage( "AcceptQuest" )
				AJM:JambaSendCommandToTeam( AJM.COMMAND_ACCEPT_QUEST )
			end		
		end
	end	
end

--ebony
function AJM:DoAcceptQuest( sender )
	if AJM.db.acceptQuests == true and AJM.db.slaveMirrorMasterAccept == true then
	local questIndex = AJM:GetQuestLogIndexByName( questName )
		AJM.isInternalCommand = true
		AJM:DebugMessage( "DoAcceptQuest" )
		AJM:JambaSendMessageToTeam( AJM.db.messageArea, L["Accepted Quest: A"]( GetTitleText() ), false )
		AcceptQuest()
		HideUIPanel( QuestFrame )
		--ebony
		--AJM:JambaSendMessageToTeam( AJM.db.messageArea, L["Accepted Quest: A"]( GetTitleText() ), false )
		AJM.isInternalCommand = false	
	end
end


--function AJM:MagicAutoAcceptQuestGrrrr()
--	if AJM.db.acceptQuests == true then
--		if AJM.db.slaveMirrorMasterAccept == true then	
--			if AJM.isInternalCommand == false then
--				-- AJM:DebugMessage( "MagicAutoAcceptQuestGrrrr", QuestGetAutoAccept() )
--				if QuestGetAutoAccept() == true then
--					AJM:JambaSendCommandToTeam( AJM.COMMAND_ACCEPT_QUEST_FAKE )
--				end
--			end		
--		end
--	end
--end

--function AJM:DoMagicAutoAcceptQuestGrrrr()
--	AJM:DebugMessage( "Start of DoMagicAutoAcceptQuestGrrrr" )
--	local questIndex = AJM:GetQuestLogIndexByName( questName )
--	if AJM.db.acceptQuests == true and AJM.db.slaveMirrorMasterAccept == true then
--		if QuestFrame:IsVisible() == true then
--		--AJM.isInternalCommand = true
--			 AJM:DebugMessage( "DoMagicAutoAcceptQuestGrrrr", QuestGetAutoAccept() )
--				if QuestGetAutoAccept() == true then
--				AJM:JambaSendMessageToTeam( AJM.db.messageArea, L["Accepted Quest: A"]( GetTitleText() ), false )
--				--AcceptQuest()
--				AcknowledgeAutoAcceptQuest()
--				HideUIPanel( QuestFrame )
--				--ebony-
--			end
--		end
--		AJM.isInternalCommand = false
--	end
--end

-------------------------------------------------------------------------------------------------------------
-- QUEST PROCESSING - AUTO ACCEPTING
-------------------------------------------------------------------------------------------------------------

function AJM:CanAutoAcceptSharedQuestFromPlayer()
	local canAccept = false
	if AJM.db.allAcceptAnyQuest == true then
		canAccept = true
	elseif AJM.db.onlyAcceptQuestsFrom == true then
		local questSourceName, questSourceRealm = UnitName( "npc" )
		
		if AJM.db.acceptFromTeam == true then	
			if JambaApi.IsCharacterInTeam( character ) == true then
				canAccept = true
			end
		end
		if AJM.db.acceptFromFriends == true then	
			for friendIndex = 1, GetNumFriends() do
				local friendName = GetFriendInfo( friendIndex )
				if character == friendName then
					canAccept = true
					break
				end
			end	
		end
		if AJM.db.acceptFromParty == true then	
			if UnitInParty( "npc" ) then
				canAccept = true
			end
		end
		if AJM.db.acceptFromRaid == true then	
			if UnitInRaid( "npc" ) then
				canAccept = true
			end
		end
		if AJM.db.acceptFromGuild == true then
			if UnitIsInMyGuild( "npc" ) then
				canAccept = true
			end
		end			
	end
	return canAccept
end

--ebony wip
function AJM:QUEST_DETAIL()
    AJM:DebugMessage( "QUEST_DETAIL" )
	-- if auto quest then auto close window.
	if QuestGetAutoAccept() then
		AJM:JambaSendMessageToTeam( AJM.db.messageArea, L["Automatically Accepted AutoPickupQuest: A"]( GetTitleText() ), false )
		AcknowledgeAutoAcceptQuest()
	elseif AJM.db.acceptQuests == true then
		-- Who is this quest from.
		--Getting AutoPickupquest to work and hiding the UI.		
		if UnitIsPlayer( "npc" ) then
			-- Quest is shared from a player.
			if AJM:CanAutoAcceptSharedQuestFromPlayer() == true then		
				AJM.isInternalCommand = true
				AJM:JambaSendMessageToTeam( AJM.db.messageArea, L["Automatically Accepted Quest: A"]( GetTitleText() ), false )
				AcceptQuest()
				HideUIPanel( QuestFrame )
				--ebony see under.
				AJM.isInternalCommand = false
			end			
		else
			-- Quest is from an NPC.
			if (AJM.db.allAcceptAnyQuest == true) or ((AJM.db.onlyAcceptQuestsFrom == true) and (AJM.db.acceptFromNpc == true)) then		
				AJM.isInternalCommand = true
				AJM:JambaSendMessageToTeam( AJM.db.messageArea, L["Automatically Accepted Quest: A"]( GetTitleText() ), false )
				AcceptQuest()
				HideUIPanel( QuestFrame )
               -- AJM:DebugMessage( "QUEST_DETAIL - auto accept is: ", QuestGetAutoAccept() )
				--ebony questNameGetTitleText
				--AJM:JambaSendMessageToTeam( AJM.db.messageArea, L["Automatically Accepted Quest: A"]( GetTitleText() ), false )
				AJM.isInternalCommand = false
			end
		end
	end	
end

-------------------------------------------------------------------------------------------------------------
-- ESCORT QUEST
-------------------------------------------------------------------------------------------------------------

function AJM:QUEST_ACCEPT_CONFIRM( event, senderName, questName )
    AJM:DebugMessage( "QUEST_ACCEPT_CONFIRM" )
	if AJM.db.acceptQuests == true then
		if AJM.db.slaveAutoAcceptEscortQuest == true then
			AJM:JambaSendMessageToTeam( AJM.db.messageArea, L["Automatically Accepted Escort Quest: A"]( questName ), false )
			AJM.isInternalCommand = true
			ConfirmAcceptQuest()
			AJM.isInternalCommand = false
			StaticPopup_Hide( "QUEST_ACCEPT" )
		end
	end	
end

-------------------------------------------------------------------------------------------------------------
-- JAMBA QUEST LOG WINDOW
-------------------------------------------------------------------------------------------------------------

function AJM.JambaQuestSelectButtonClicked()
	if AJM:IsCurrentlySelectedQuestValid() == true then
		AJM:JambaSendCommandToTeam( AJM.COMMAND_SELECT_QUEST_LOG_ENTRY, AJM.CurrentlySelectedQuest, AJM.selectedTag )
	else
		AJM:JambaSendMessageToTeam( AJM.db.messageArea, L["You must select a quest from the quest log in order to action it on your other characters."], false )
	end
end

function AJM.JambaQuestShareButtonClicked()
	if AJM:IsCurrentlySelectedQuestValid() == true then
		if GetQuestLogPushable() and GetNumSubgroupMembers() > 0 then
			QuestLogPushQuest()
		end
	else
		AJM:JambaSendMessageToTeam( AJM.db.messageArea, L["You must select a quest from the quest log in order to action it on your other characters."], false )
	end
end

function AJM.JambaQuestTrackAllButtonClicked()
	AJM.iterateQuests = 1
	if AJM.iterateQuests <= GetNumQuestLogEntries() then
		AJM:ScheduleTimer( "TrackAllNextQuest", 0.5 )
	end
end

function AJM.TrackAllNextQuest()
    local title, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID, startEvent, displayQuestID, isOnMap, hasLocalPOI, isTask, isStory = GetQuestLogTitle( AJM.iterateQuests )
	if isHeader == nil then
		if title ~= nil then
			SelectQuestLogEntry( AJM.iterateQuests )	
			if AJM:IsCurrentlySelectedQuestValid() == true then
				local watch = 0
				local questIndex = AJM:GetQuestLogIndexByName( AJM.CurrentlySelectedQuest )
				if questIndex ~= 0 then
					AddQuestWatch( questIndex )
					watch = 1
				end	
				AJM:JambaSendCommandToTeam( AJM.COMMAND_QUEST_TRACK, AJM.CurrentlySelectedQuest, watch, AJM.selectedTag )
			end	
		end
	end
	AJM.iterateQuests = AJM.iterateQuests + 1
	if AJM.iterateQuests <= GetNumQuestLogEntries() then
		AJM:ScheduleTimer( "TrackAllNextQuest", 0.5 )
	end
end

function AJM.JambaQuestTrackNoneButtonClicked()
	AJM.iterateQuests = 1
	if AJM.iterateQuests <= GetNumQuestLogEntries() then
		AJM:ScheduleTimer( "TrackNoneNextQuest", 0.5 )
	end
end

function AJM.TrackNoneNextQuest()
    local title, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID, startEvent, displayQuestID, isOnMap, hasLocalPOI, isTask, isStory = GetQuestLogTitle( AJM.iterateQuests )
	if isHeader == nil then
		if title ~= nil then
			SelectQuestLogEntry( AJM.iterateQuests )	
			if AJM:IsCurrentlySelectedQuestValid() == true then
				local watch = 0
				local questIndex = AJM:GetQuestLogIndexByName( AJM.CurrentlySelectedQuest )
				if questIndex ~= 0 then
					RemoveQuestWatch( questIndex )
					watch = 0
				end	
				AJM:JambaSendCommandToTeam( AJM.COMMAND_QUEST_TRACK, AJM.CurrentlySelectedQuest, watch, AJM.selectedTag )
			end	
		end
	end
	AJM.iterateQuests = AJM.iterateQuests + 1
	if AJM.iterateQuests <= GetNumQuestLogEntries() then
		AJM:ScheduleTimer( "TrackNoneNextQuest", 0.5 )
	end
end

function AJM.JambaQuestTrackToggleButtonClicked()
	if AJM:IsCurrentlySelectedQuestValid() == true then
		local watch = 0
		local questIndex = AJM:GetQuestLogIndexByName( AJM.CurrentlySelectedQuest )
		if questIndex ~= 0 then
			if IsQuestWatched( questIndex ) then
				RemoveQuestWatch( questIndex )
				watch = 0
			else
				AddQuestWatch( questIndex )
				watch = 1
			end
		end	
		AJM:JambaSendCommandToTeam( AJM.COMMAND_QUEST_TRACK, AJM.CurrentlySelectedQuest, watch, AJM.selectedTag )
	else
		AJM:JambaSendMessageToTeam( AJM.db.messageArea, L["You must select a quest from the quest log in order to action it on your other characters."], false )
	end
end

function AJM.JambaQuestTrackToggleAllButtonClicked()
	AJM.iterateQuests = 1
	if AJM.iterateQuests <= GetNumQuestLogEntries() then
		AJM:ScheduleTimer( "TrackToggleNextQuest", 0.5 )
	end
end

function AJM.TrackToggleNextQuest()
    local title, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID, startEvent, displayQuestID, isOnMap, hasLocalPOI, isTask, isStory = GetQuestLogTitle( AJM.iterateQuests )
	if isHeader == nil then
		if title ~= nil then
			SelectQuestLogEntry( AJM.iterateQuests )	
			if AJM:IsCurrentlySelectedQuestValid() == true then
				local watch = 0
				local questIndex = AJM:GetQuestLogIndexByName( AJM.CurrentlySelectedQuest )
				if questIndex ~= 0 then
					if IsQuestWatched( questIndex ) then
						RemoveQuestWatch( questIndex )
						watch = 0
					else
						AddQuestWatch( questIndex )
						watch = 1
					end
				end	
				AJM:JambaSendCommandToTeam( AJM.COMMAND_QUEST_TRACK, AJM.CurrentlySelectedQuest, watch, AJM.selectedTag )
			end	
		end
	end
	AJM.iterateQuests = AJM.iterateQuests + 1
	if AJM.iterateQuests <= GetNumQuestLogEntries() then
		AJM:ScheduleTimer( "TrackToggleNextQuest", 0.5 )
	end
end

function AJM:JambaQuestAbandonQuest()
	if AJM:IsCurrentlySelectedQuestValid() == true then
		AJM:JambaSendCommandToTeam( AJM.COMMAND_ABANDON_QUEST, AJM.currentlySelectedQuest, AJM.selectedTag )
	else
		AJM:JambaSendMessageToTeam( AJM.db.messageArea, L["You must select a quest from the quest log in order to action it on your other characters."], false )
	end
end

function AJM.JambaQuestAbandonButtonClicked()
	if AJM:IsCurrentlySelectedQuestValid() == true then
		StaticPopup_Show( "JAMBAQUEST_CONFIRM_ABANDON_QUEST", AJM.currentlySelectedQuest )
	else
		AJM:JambaSendMessageToTeam( AJM.db.messageArea, L["You must select a quest from the quest log in order to action it on your other characters."], false )
	end
end

function AJM:JambaQuestAbandonAllQuests()
	AJM:JambaSendCommandToTeam( AJM.COMMAND_ABANDON_ALL_QUESTS, AJM.selectedTag )
end

function AJM.AbandonNextQuest()
    local title, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID, startEvent, displayQuestID, isOnMap, hasLocalPOI, isTask, isStory = GetQuestLogTitle( AJM.iterateQuests )
	if isHeader == nil then
		if title ~= nil then
			SelectQuestLogEntry( AJM.iterateQuests )
			SetAbandonQuest()
			AbandonQuest()
			AJM:UpdateQuestLog( nil )
			-- Start again at the top, as to not miss any quests.
			AJM.iterateQuests = 1
		end
	end
	AJM.iterateQuests = AJM.iterateQuests + 1
	if AJM.iterateQuests <= GetNumQuestLogEntries() then
		AJM:ScheduleTimer( "AbandonNextQuest", 0.5 )
	end
end

function AJM.JambaQuestAbandonAllButtonClicked()
	StaticPopup_Show( "JAMBAQUEST_CONFIRM_ABANDON_ALL_QUESTS" )
end

function AJM.JambaQuestShareAllButtonClicked()
	AJM.iterateQuests = 1
	if AJM.iterateQuests <= GetNumQuestLogEntries() then
		AJM:ScheduleTimer( "PushNextQuest", 1 )
	end
end

--ebony
function AJM.PushNextQuest()
    local title, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID, startEvent, displayQuestID, isOnMap, hasLocalPOI, isTask, isStory = GetQuestLogTitle( AJM.iterateQuests )
	if isHeader == nil then
		if title ~= nil then
			SelectQuestLogEntry( AJM.iterateQuests )
			if GetQuestLogPushable() and GetNumSubgroupMembers() > 0 then
				AJM:JambaSendMessageToTeam( AJM.db.messageArea, L["Sharing Quest: A"]( title ), false )
				QuestLogPushQuest()
			end			
		end
	end
	AJM.iterateQuests = AJM.iterateQuests + 1
	if AJM.iterateQuests <= GetNumQuestLogEntries() then
		AJM:ScheduleTimer( "PushNextQuest", 1 )
	end
end

function AJM.JambaQuestCloseButtonClicked()
	JambaQuestLogWindowFrame:Hide()
end

function AJM.JambaQuestTagDropDownOnClick( event, value )
	AJM.selectedTag = value
end

function AJM:CreateJambaQuestLogFrame()
	local frameName = "JambaQuestLogWindowFrame"
    JambaQuestLogWindowFrame = CreateFrame( "Frame", "JambaQuestLogWindowFrame", UIParent )
    local frame = JambaQuestLogWindowFrame
	frame:SetWidth( 670 )
	frame:SetHeight( 50 )
	frame:SetFrameStrata( "HIGH" )
	frame:SetToplevel( true )
	frame:SetClampedToScreen( true )
	frame:EnableMouse( true )
	frame:SetMovable( true )	
	frame:ClearAllPoints()
	frame:SetPoint( AJM.db.framePoint, UIParent, AJM.db.frameRelativePoint, AJM.db.frameXOffset, AJM.db.frameYOffset )
	frame:RegisterForDrag( "LeftButton" )
	frame:SetScript( "OnDragStart", 
		function( this ) 
			if IsAltKeyDown() then
				this:StartMoving() 
			end
		end )
	frame:SetScript( "OnDragStop", 
		function( this ) 
			this:StopMovingOrSizing() 
			local point, relativeTo, relativePoint, xOffset, yOffset = this:GetPoint()
			AJM.db.framePoint = point
			AJM.db.frameRelativePoint = relativePoint
			AJM.db.frameXOffset = xOffset
			AJM.db.frameYOffset = yOffset
		end	)
	frame:SetBackdrop( {
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", 
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", 
		tile = true, tileSize = 15, edgeSize = 15, 
		insets = { left = 5, right = 5, top = 5, bottom = 5 }
	} )
	local buttonHeight = 22
	local buttonWidth = 100
	local buttonWidthTag = 120
	local buttonWidthToggle = 140
	local buttonTop = -10
	--local buttonTopSecondRow = buttonTop - buttonHeight - 2
	local left = 8
	local spacing = 1
	-- Tags should this get removed at some point? 
	local dropDownTag = AceGUI:Create( "Dropdown" )
	dropDownTag.frame:SetParent( frame )
	dropDownTag:SetLabel( "" )
	dropDownTag:SetPoint( "TOPLEFT", frame, "TOPLEFT", left, -10 )
	dropDownTag:SetWidth( buttonWidthTag )
	dropDownTag:SetList( JambaApi.AllTagsList() )
	dropDownTag:SetCallback( "OnValueChanged", AJM.JambaQuestTagDropDownOnClick )
	-- Hack - 1 is "all" in the list - this might change on day, but will do for now!
	dropDownTag:SetValue( 1 )
	AJM.selectedTag = JambaApi.AllTag()	
	AJM.jambaQuestLogFrameDropDownTag = dropDownTag
	-- Select.
	left = left + buttonWidth + spacing
	left = left + 30
	local selectButton = CreateFrame( "Button", frameName.."ButtonSelect", frame, "UIPanelButtonTemplate" )
	selectButton:SetScript( "OnClick", AJM.JambaQuestSelectButtonClicked )
	selectButton:SetPoint( "TOPLEFT", frame, "TOPLEFT", left, buttonTop )
	selectButton:SetHeight( buttonHeight )
	selectButton:SetWidth( buttonWidth )
	selectButton:SetText( L["Select"] )		
	left = left + buttonWidth + spacing
	--left = left + 70
	-- Share / Share All.
	local shareButton = CreateFrame( "Button", frameName.."ButtonShare", frame, "UIPanelButtonTemplate" )
	shareButton:SetScript( "OnClick", AJM.JambaQuestShareButtonClicked )
	shareButton:SetPoint( "TOPLEFT", frame, "TOPLEFT", left, buttonTop )
	shareButton:SetHeight( buttonHeight )
	shareButton:SetWidth( buttonWidth )
	shareButton:SetText( L["Share"] )		
	AJM.jambaQuestLogFrameShareButton = shareButton
	left = left + buttonWidth + spacing
	local shareAllButton = CreateFrame( "Button", frameName.."ButtonShareAll", frame, "UIPanelButtonTemplate" )
	shareAllButton:SetScript( "OnClick", AJM.JambaQuestShareAllButtonClicked )
	shareAllButton:SetPoint( "TOPLEFT", frame, "TOPLEFT", left, buttonTop )
	shareAllButton:SetHeight( buttonHeight )
	shareAllButton:SetWidth( buttonWidth )
	shareAllButton:SetText( L["Share All"] )		
	left = left + buttonWidth + spacing
	-- Track / Track All.
	--local trackButtonToggle = CreateFrame( "Button", frameName.."ButtonToggleTrack", frame, "UIPanelButtonTemplate" )
	--trackButtonToggle:SetScript( "OnClick", AJM.JambaQuestTrackToggleButtonClicked )
	--trackButtonToggle:SetPoint( "TOPLEFT", frame, "TOPLEFT", left, buttonTop )
	--trackButtonToggle:SetHeight( buttonHeight )
	--trackButtonToggle:SetWidth( buttonWidthToggle )
	--trackButtonToggle:SetText( L["Toggle Track"] )
	--local trackAllButtonToggle = CreateFrame( "Button", frameName.."ButtonToggleTrackAll", frame, "UIPanelButtonTemplate" )
	--trackAllButtonToggle:SetScript( "OnClick", AJM.JambaQuestTrackToggleAllButtonClicked )
	--trackAllButtonToggle:SetPoint( "TOPLEFT", frame, "TOPLEFT", left, buttonTopSecondRow )
	--trackAllButtonToggle:SetHeight( buttonHeight )
	--trackAllButtonToggle:SetWidth( buttonWidthToggle )
	--trackAllButtonToggle:SetText( L["Toggle Track All"] )	
	--left = left + buttonWidthToggle + spacing
	--local trackButton = CreateFrame( "Button", frameName.."ButtonTrackAll", frame, "UIPanelButtonTemplate" )
	--trackButton:SetScript( "OnClick", AJM.JambaQuestTrackAllButtonClicked )
	--trackButton:SetPoint( "TOPLEFT", frame, "TOPLEFT", left, buttonTop )
	--trackButton:SetHeight( buttonHeight )
	--trackButton:SetWidth( buttonWidth )
	--trackButton:SetText( L["Track All"] )
	--local trackNoneButton = CreateFrame( "Button", frameName.."ButtonTrackNone", frame, "UIPanelButtonTemplate" )
	--trackNoneButton:SetScript( "OnClick", AJM.JambaQuestTrackNoneButtonClicked )
	--trackNoneButton:SetPoint( "TOPLEFT", frame, "TOPLEFT", left, buttonTopSecondRow )
	--trackNoneButton:SetHeight( buttonHeight )
	--trackNoneButton:SetWidth( buttonWidth )
	--trackNoneButton:SetText( L["Track None"] )	
	--left = left + buttonWidth + spacing
	--left = left + 70
	-- Abandon / Abandon All.
	local abandonButton = CreateFrame( "Button", frameName.."ButtonAbandon", frame, "UIPanelButtonTemplate" )
	abandonButton:SetScript( "OnClick", AJM.JambaQuestAbandonButtonClicked )
	abandonButton:SetPoint( "TOPLEFT", frame, "TOPLEFT", left, buttonTop )
	abandonButton:SetHeight( buttonHeight )
	abandonButton:SetWidth( buttonWidth )
	abandonButton:SetText( L["Abandon"] )
	left = left + buttonWidth + spacing	
	local abandonAllButton = CreateFrame( "Button", frameName.."ButtonAbandonAll", frame, "UIPanelButtonTemplate" )
	abandonAllButton:SetScript( "OnClick", AJM.JambaQuestAbandonAllButtonClicked )
	abandonAllButton:SetPoint( "TOPLEFT", frame, "TOPLEFT", left, buttonTop )
	abandonAllButton:SetHeight( buttonHeight )
	abandonAllButton:SetWidth( buttonWidth )
	abandonAllButton:SetText( L["Abandon All"] )		
	left = left + buttonWidth + spacing
	-- Close.
	local closeButton = CreateFrame( "Button", frameName.."ButtonClose", frame, "UIPanelCloseButton" )
	closeButton:SetScript( "OnClick", AJM.JambaQuestCloseButtonClicked )
	closeButton:SetPoint( "TOPRIGHT", frame, "TOPRIGHT", -1, -2 )
	table.insert( UISpecialFrames, "JambaQuestLogWindowFrame" )
	-- Popups.
	StaticPopupDialogs["JAMBAQUEST_CONFIRM_ABANDON_QUEST"] = {
        text = L['Abandon "%s"?'],
        button1 = YES,
        button2 = NO,
        timeout = 0,
		whileDead = 1,
		hideOnEscape = 1,
        OnAccept = function()
			AJM:JambaQuestAbandonQuest()
		end,
    }        
	StaticPopupDialogs["JAMBAQUEST_CONFIRM_ABANDON_ALL_QUESTS"] = {
        text = L["This will abandon ALL quests ON every toon!  Yes, this means you will end up with ZERO quests in your quest log!  Are you sure?"],
        button1 = YES,
        button2 = NO,
        timeout = 0,
		whileDead = 1,
		hideOnEscape = 1,
        OnAccept = function()
			AJM:JambaQuestAbandonAllQuests()
		end,
    }        
end

--ebony wip
function AJM:ToggleFrame ( frame )
    --AJM:Print( "in toggle frame", frame )
	if frame == WorldMapFrame then
		if AJM.db.showJambaQuestLogWithWoWQuestLog == true then
          --AJM:Print("check qmfiv:", WorldMapFrame:IsVisible() )
			--if WorldMapFrame:IsVisible() then -ebs and QuestLogDetailScrollFrame:IsVisible
			if WorldMapFrame:IsVisible() and QuestMapFrame:IsVisible() then
				AJM:ToggleShowQuestCommandWindow( true )				
			else
				AJM:ToggleShowQuestCommandWindow( false )
			end
		end
	end
end
--ebony

--function AJM:ToggleQuestLog ( frame )
--    AJM:Print( "in toggle frame", frame )
--	if frame == ToggleQuestLog then
--		if AJM.db.showJambaQuestLogWithWoWQuestLog == true then
--          --AJM:Print("check qmfiv:", WorldMapFrame:IsVisible() )
--			--if WorldMapFrame:IsVisible() then -ebs and QuestLogDetailScrollFrame:IsVisible
--			if WorldMapFrame:IsVisible() and QuestMapFrame:IsVisible() then
--				AJM:ToggleShowQuestCommandWindow( true )				
--			else
--				AJM:ToggleShowQuestCommandWindow( false )
--			end
--		end
--	end
--end

function AJM:QuestLogFrameHide()
	if AJM.db.showJambaQuestLogWithWoWQuestLog == true then
		AJM:ToggleShowQuestCommandWindow( false )
	end
end

function AJM:ToggleShowQuestCommandWindow( show )
    if show == true then
		JambaQuestLogWindowFrame:Show()
    else
		JambaQuestLogWindowFrame:Hide()
    end
end
--ebony-wip
function AJM:UpdateQuestLog( questIndex )		
	if WorldMapFrame:IsVisible() and QuestMapFrame:IsVisible() then
		if questIndex then
		SelectQuestLogEntry( questIndex )
		--	QuestLog_SetSelection( questIndex ) -- Removed by blizzard in 6.0.2 changed to SelectQuestLogEntry
		end
	end	
--	What does this do???????-ebony Junk????
--	if WorldMapFrame:IsVisible() then
--		QuestLog_Update()
--	end
	-- ebony not sure,
	--if QuestScrollFrameScrollBar:IsVisible() then	-- ebony was QuestLogDetailScrollFrame turned back nothing.
	if QuestScrollFrameScrollBar:IsVisible() then	
		QuestMap_UpdateQuestDetails( false )
	end
	-- is this needed ebony???? truns back nothing? Don't think was needed?? was renamed in 6.0 to ObjectiveTrackerFrame
	if ObjectiveTrackerFrame:IsVisible() then		
		ObjectiveTrackerFrame_Update()
 	end
end

function AJM:GetQuestLogIndexByName( questName )
	for iterateQuests = 1, GetNumQuestLogEntries() do
        local title, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID, startEvent, displayQuestID, isOnMap, hasLocalPOI, isTask, isStory = GetQuestLogTitle( iterateQuests )
		if not isHeader then
			if title == questName then
				return iterateQuests
			end
		end
	end
	return 0
end

function AJM:SelectQuestLogEntry( questIndex )
	AJM.currentlySelectedQuest =  L["(No Quest Selected)"]
	--AJM.SelectQuestLogEntry =  L["(No Quest Selected)"]
	--if questIndex ~= nil then
	if questIndex ~= nil then
        local title, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID, startEvent, displayQuestID, isOnMap, hasLocalPOI, isTask, isStory = GetQuestLogTitle( questIndex )
		if not isHeader then
			if title then
				AJM.currentlySelectedQuest = title
				-- SelectQuestLogEntry = title
				if JambaQuestLogWindowFrame:IsVisible() then
					if GetQuestLogPushable() and GetNumSubgroupMembers() > 0 then
						AJM.jambaQuestLogFrameShareButton:Enable()
						--AJM.jambaQuestLogFrameShareButton:Enable()
					else
						AJM.jambaQuestLogFrameShareButton:Disable()
						--AJM.jambaQuestLogFrameShareButton:Disable()
					end
				end
			end
		end
	end	
end

--ebonytest SelectQuestLogEntry

function AJM:IsCurrentlySelectedQuestValid()
	if AJM.currentlySelectedQuest:trim() ~= "" and AJM.currentlySelectedQuest ~= L["(No Quest Selected)"] then
		return true
	end
	return false	
end

function AJM:DoSelectQuestLogEntry( sender, questName, tag )
	if JambaApi.DoesCharacterHaveTag( AJM.characterName, tag ) == true then
		local questIndex = AJM:GetQuestLogIndexByName( questName )
		if questIndex ~= 0 then
			SelectQuestLogEntry( questIndex )
			AJM:UpdateQuestLog( questIndex )
		else
			AJM:JambaSendMessageToTeam( AJM.db.warningArea, L["I do not have the quest: A"]( questName ), false )
		end		
	end
end

function AJM:DoQuestTrack( sender, questName, watch, tag )
	if JambaApi.DoesCharacterHaveTag( AJM.characterName, tag ) == true then
		local questIndex = AJM:GetQuestLogIndexByName( questName )
		if questIndex ~= 0 then
			if watch then
				AddQuestWatch( questIndex )
			else
				RemoveQuestWatch( questIndex )
			end
			AJM:UpdateQuestLog( questIndex )
		else
			AJM:JambaSendMessageToTeam( AJM.db.warningArea, L["I do not have the quest: A"]( questName ), false )
		end		
	end
end

function AJM:DoAbandonQuest( sender, questName, tag )
	if JambaApi.DoesCharacterHaveTag( AJM.characterName, tag ) == true then
		local questIndex = AJM:GetQuestLogIndexByName( questName )
		if questIndex ~= 0 then
			SelectQuestLogEntry( questIndex )
			SetAbandonQuest()
			AbandonQuest()
			AJM:UpdateQuestLog( questIndex )
			AJM:JambaSendMessageToTeam( AJM.db.messageArea, L["I have abandoned the quest: A"]( questName ), false )
		else
			AJM:JambaSendMessageToTeam( AJM.db.warningArea, L["I do not have the quest: A"]( questName ), false )
		end		
	end
end

function AJM:DoAbandonAllQuests( sender, tag )
	if JambaApi.DoesCharacterHaveTag( AJM.characterName, tag ) == true then
		AJM.iterateQuests = 1
		if AJM.iterateQuests <= GetNumQuestLogEntries() then
			AJM:ScheduleTimer( "AbandonNextQuest", 1 )
		end
	end
end

function AJM:AutoSelectToggleCommand( info, parameters )
	--xx
	local toggle, tag = strsplit ( " ", parameters )
	if tag ~= nil and tag:trim() ~= "" then
		AJM:JambaSendCommandToTeam( AJM.COMMAND_TOGGLE_AUTO_SELECT, toggle, tag )
	else
		AJM:AutoSelectToggle( toggle )
	end	
end

function AJM:DoAutoSelectToggle( sender, toggle, tag )
	if JambaApi.DoesCharacterHaveTag( AJM.characterName, tag ) == true then
		AJM:AutoSelectToggle( toggle )
	end
end

function AJM:AutoSelectToggle( toggle )
	if toggle == L["toggle"] then
		if AJM.db.allAutoSelectQuests == true then
			toggle = L["off"]
		else
			toggle = L["on"]
		end
	end
	if toggle == L["on"] then
		AJM.db.mirrorMasterQuestSelectionAndDeclining = false
		AJM.db.allAutoSelectQuests = true
	elseif toggle == L["off"] then
		AJM.db.mirrorMasterQuestSelectionAndDeclining = true
		AJM.db.allAutoSelectQuests = false
	end
	AJM:SettingsRefresh()
end

-------------------------------------------------------------------------------------------------------------
-- COMMAND MANAGEMENT
-------------------------------------------------------------------------------------------------------------

-- A Jamba command has been recieved.
function AJM:JambaOnCommandReceived( characterName, commandName, ... )
    AJM:DebugMessage( 'got a command', characterName, commandName, ... )
	if commandName == AJM.COMMAND_TOGGLE_AUTO_SELECT then
		AJM:DoAutoSelectToggle( characterName, ... )
	end
	-- Want to action track and abandon command on the same character that sent the command.
	if commandName == AJM.COMMAND_QUEST_TRACK then
		AJM:DoQuestTrack( characterName, ... )
	end
	if commandName == AJM.COMMAND_ABANDON_QUEST then		
		AJM:DoAbandonQuest( characterName, ... )
	end
	if commandName == AJM.COMMAND_ABANDON_ALL_QUESTS then		
		AJM:DoAbandonAllQuests( characterName, ... )
	end
	-- If this character sent this command, don't action it.
	if characterName == AJM.characterName then
		return
	end
	if commandName == AJM.COMMAND_ACCEPT_QUEST then		
		AJM:DoAcceptQuest( characterName, ...  )
	end			
	if commandName == AJM.COMMAND_SELECT_GOSSIP_OPTION then		
		AJM:DoSelectGossipOption( characterName, ... )
	end
	if commandName == AJM.COMMAND_SELECT_GOSSIP_ACTIVE_QUEST then		
		AJM:DoSelectGossipActiveQuest( characterName, ... )
	end
	if commandName == AJM.COMMAND_SELECT_GOSSIP_AVAILABLE_QUEST then		
		AJM:DoSelectGossipAvailableQuest( characterName, ... )
	end
	if commandName == AJM.COMMAND_SELECT_ACTIVE_QUEST then		
		AJM:DoSelectActiveQuest( characterName, ... )
	end
	if commandName == AJM.COMMAND_SELECT_AVAILABLE_QUEST then		
		AJM:DoSelectAvailableQuest( characterName, ... )
	end
	if commandName == AJM.COMMAND_DECLINE_QUEST then		
		AJM:DoDeclineQuest( characterName, ...  )
	end
	if commandName == AJM.COMMAND_COMPLETE_QUEST then		
		AJM:DoCompleteQuest( characterName, ... )
	end
	if commandName == AJM.COMMAND_CHOOSE_QUEST_REWARD then		
		AJM:DoChooseQuestReward( characterName, ... )
	end
	if commandName == AJM.COMMAND_SELECT_QUEST_LOG_ENTRY then
		AJM:DoSelectQuestLogEntry( characterName, ... )
	end
	if commandName == AJM.COMMAND_LOG_COMPLETE_QUEST then
		AJM:DoShowQuestComplete( characterName, ... )
	end
	if commandName == AJM.COMMAND_ACCEPT_QUEST_FAKE then
		AJM:DoMagicAutoAcceptQuestGrrrr( characterName, ... )
	end
end
