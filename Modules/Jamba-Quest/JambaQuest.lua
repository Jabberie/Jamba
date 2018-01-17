--[[
Jamba -- Jafula's Awesome Multi-Boxer Assistant
Copyright 2008 - 2018 Michael "Jafula" Miller
License: The MIT License
--]]

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


local JambaQuestMapQuestOptionsDropDown = CreateFrame("Frame", "JambaQuestMapQuestOptionsDropDown", QuestMapFrame, "UIDropDownMenuTemplate");

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
		hideStaticPopup = false,
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

AJM.COMMAND_SELECT_GOSSIP_OPTION = "JambaSelectGossipOption"
AJM.COMMAND_SELECT_GOSSIP_ACTIVE_QUEST = "JambaSelectGossipActiveQuest"
AJM.COMMAND_SELECT_GOSSIP_AVAILABLE_QUEST = "JambaSelectGossipAvailableQuest"
AJM.COMMAND_SELECT_ACTIVE_QUEST = "JambaSelectActiveQuest"
AJM.COMMAND_SELECT_AVAILABLE_QUEST = "JambaSelectAvailableQuest"
AJM.COMMAND_ACCEPT_QUEST = "JambaAcceptQuest"
AJM.COMMAND_COMPLETE_QUEST = "JambaCompleteQuest"
AJM.COMMAND_CHOOSE_QUEST_REWARD = "JambaChooseQuestReward"
AJM.COMMAND_DECLINE_QUEST = "JambaDeclineQuest"
AJM.COMMAND_SELECT_QUEST_LOG_ENTRY = "JambaSelectQuestLogEntry"
AJM.COMMAND_QUEST_TRACK = "JambaQuestTrack"
AJM.COMMAND_ABANDON_QUEST = "JambaAbandonQuest"
AJM.COMMAND_ABANDON_ALL_QUESTS = "JambaAbandonAllQuests"
AJM.COMMAND_TRACK_ALL_QUESTS = "JambaTrackAllQuests"
AJM.COMMAND_UNTRACK_ALL_QUESTS = "JambaUnTrackAllQuests"
AJM.COMMAND_SHARE_ALL_QUESTS = "JambaShareAllQuests"
AJM.COMMAND_TOGGLE_AUTO_SELECT = "JambaToggleAutoSelect"
AJM.COMMAND_LOG_COMPLETE_QUEST = "JambaLogCompleteQuest"
AJM.COMMAND_ACCEPT_QUEST_FAKE = "JambaAcceptQuestFake"

-------------------------------------------------------------------------------------------------------------
-- Messages module sends.
-------------------------------------------------------------------------------------------------------------


-------------------------------------------------------------------------------------------------------------
-- Popup Dialogs.
-------------------------------------------------------------------------------------------------------------

-- Initialize Popup Dialogs.
local function InitializePopupDialogs()
   -- Asks If you like to Abandon on all toons
   StaticPopupDialogs["JAMBAQUEST_ABANDON_ALL_TOONS"] = {
        text = L["Would you like to Abandon \"%s\" On All Toons?"],
        button1 = L["Just Me"],
        button2 = L["All Team"],
        button3 = NO,
        timeout = 0,
		whileDead = 1,
		hideOnEscape = 1,
        OnAccept = function( self )
			--AJM:Print("Button1")
			AbandonQuest()
		end,
		OnAlt = function ( self )
			--AJM:Print("Button3")
			
		end,
		OnCancel = function( self, data )
			--AJM:Print("Button2")
			AJM:JambaSendCommandToTeam( AJM.COMMAND_ABANDON_QUEST, data.questID, data.title)
		end,		
    }
   -- Asks If you like to Track on all toons
   StaticPopupDialogs["JAMBAQUEST_TRACK_ALL_TOONS"] = {
        text = L["Would you like to Track \"%s\" On All Toons?"],
        button1 = YES,
        button2 = NO,
        timeout = 0,
		whileDead = 1,
		hideOnEscape = 1,
        OnAccept = function( self, data )
			AJM:JambaSendCommandToTeam( AJM.COMMAND_QUEST_TRACK, data.questID, data.title, true )
		end,
		OnCancel = function( self )
		end,		
    }
	StaticPopupDialogs["JAMBAQUEST_UNTRACK_ALL_TOONS"] = {
        text = L["Would you like to UnTrack \"%s\" On All Toons?"],
        button1 = YES,
        button2 = NO,
        timeout = 0,
		whileDead = 1,
		hideOnEscape = 1,
        OnAccept = function( self, data )
			AJM:JambaSendCommandToTeam( AJM.COMMAND_QUEST_TRACK, data.questID, data.title, false )
		end,
		OnCancel = function( self )
		end,		
    }
	StaticPopupDialogs["AbandonALLToonsQuest"] = {
        text = L["This will abandon ALL quests ON every toon!  Yes, this means you will end up with ZERO quests in your quest log!  Are you sure?"],
        button1 = YES,
        button2 = NO,
        timeout = 0,
		whileDead = true,
		hideOnEscape = true,
       OnAccept = function()
			AJM:DoAbandonAllQuestsFromAllToons()
		end,
    }    


end

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
	-- Initialise the popup dialogs.
	InitializePopupDialogs()
	-- Create the Jamba Quest Log frame.
	AJM:CreateJambaMiniQuestLogFrame()
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
	AJM:SecureHook( "AcknowledgeAutoAcceptQuest" )
    AJM:SecureHook( "CompleteQuest" )
	AJM:SecureHook( "GetQuestReward" )
	AJM:SecureHook( "ToggleFrame" )
	AJM:SecureHook( "ToggleQuestLog" )
	AJM:SecureHook( WorldMapFrame, "Hide", "QuestLogFrameHide" )
	AJM:SecureHook( "ShowQuestComplete" )
	AJM:SecureHook( "QuestMapQuestOptions_AbandonQuest" )
	AJM:SecureHook( "QuestMapQuestOptions_TrackQuest" )
--	AJM:SecureHook( QuestFrame, "Hide", "DeclineQuest" )	
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
	-- Radio box: Minion select, accept and decline quest with master.
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
	-- Radio box: Minion accept quest with master.
	AJM.settingsControl.checkBoxMinionMirrorMasterAccept = JambaHelperSettings:CreateCheckBox(
		AJM.settingsControl, 
		headingWidth, 
		column1Left + indent, 
		movingTop,
		L["Toon Accept Quest From Team"],
		AJM.SettingsToggleMinionMirrorMasterAccept
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
	-- Check box: Minion auto accept escort quest from master.
	AJM.settingsControl.checkBoxMinionAutoAcceptEscortQuest = JambaHelperSettings:CreateCheckBox(
		AJM.settingsControl, 
		headingWidth, 
		column1Left, 
		movingTop,
		L["Toon Auto Accept Escort Quest From Team"],
		AJM.SettingsToggleMinionAutoAcceptEscortQuest
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
	-- Radio box: No choice, minion do nothing.
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
	-- Radio box: No choice, minion complete quest with master.
	AJM.settingsControlCompletion.checkBoxNoChoiceMinionCompleteQuestWithMaster = JambaHelperSettings:CreateCheckBox(
		AJM.settingsControlCompletion, 
		headingWidth, 
		column1Left, 
		movingTop,
		L["Toon Complete Quest With Team"],
		AJM.SettingsToggleNoChoiceMinionCompleteQuestWithMaster
	)
	AJM.settingsControlCompletion.checkBoxNoChoiceMinionCompleteQuestWithMaster:SetType( "radio" )
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
	-- Radio box: Has choice, minion do nothing.
	AJM.settingsControlCompletion.checkBoxHasChoiceMinionDoNothing = JambaHelperSettings:CreateCheckBox(
		AJM.settingsControlCompletion, 
		headingWidth, 
		column1Left, 
		movingTop,
		L["Toon Do Nothing"],
		AJM.SettingsToggleHasChoiceMinionDoNothing
	)	
	AJM.settingsControlCompletion.checkBoxHasChoiceMinionDoNothing:SetType( "radio" )
	movingTop = movingTop - radioBoxHeight
	-- Radio box: Has choice, minion complete quest with master.
	AJM.settingsControlCompletion.checkBoxHasChoiceMinionCompleteQuestWithMaster = JambaHelperSettings:CreateCheckBox(
		AJM.settingsControlCompletion, 
		headingWidth, 
		column1Left, 
		movingTop,
		L["Toon Complete Quest With Team"],
		AJM.SettingsToggleHasChoiceMinionCompleteQuestWithMaster
	)	
	AJM.settingsControlCompletion.checkBoxHasChoiceMinionCompleteQuestWithMaster:SetType( "radio" )
	movingTop = movingTop - radioBoxHeight
	-- Radio box: Has choice, minion must choose own reward.
	AJM.settingsControlCompletion.checkBoxHasChoiceMinionMustChooseOwnReward = JambaHelperSettings:CreateCheckBox(
		AJM.settingsControlCompletion, 
		headingWidth, 
		column1Left + indent, 
		movingTop,
		L["Toon Must Choose Own Reward"],
		AJM.SettingsToggleHasChoiceMinionMustChooseOwnReward
	)	
	AJM.settingsControlCompletion.checkBoxHasChoiceMinionMustChooseOwnReward:SetType( "radio" )
	movingTop = movingTop - radioBoxHeight	
	-- Radio box: Has choice, minion choose same reward as master.
	AJM.settingsControlCompletion.checkBoxHasChoiceMinionChooseSameRewardAsMaster = JambaHelperSettings:CreateCheckBox(
		AJM.settingsControlCompletion, 
		headingWidth, 
		column1Left + indent, 
		movingTop,
		L["Toon Choose Same Reward As Team"],
		AJM.SettingsToggleHasChoiceMinionChooseSameRewardAsMaster
	)	
	AJM.settingsControlCompletion.checkBoxHasChoiceMinionChooseSameRewardAsMaster:SetType( "radio" )
	movingTop = movingTop - radioBoxHeight
	-- Radio box: Has choice, minion reward choice depends on modifier key pressed down.
	AJM.settingsControlCompletion.checkBoxHasChoiceMinionRewardChoiceModifierConditional = JambaHelperSettings:CreateCheckBox(
		AJM.settingsControlCompletion, 
		headingWidth, 
		column1Left + indent, 
		movingTop,
		L["If Modifier Keys Pressed, Toon Choose Same Reward"],
		AJM.SettingsToggleHasChoiceMinionRewardChoiceModifierConditional
	)	
	AJM.settingsControlCompletion.checkBoxHasChoiceMinionRewardChoiceModifierConditional:SetType( "radio" )
	movingTop = movingTop - radioBoxHeight
	-- Label continuing radio box above.
	AJM.settingsControlCompletion.labelHasChoiceMinionRewardChoiceModifierConditional = JambaHelperSettings:CreateContinueLabel(
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
	-- Check box: Has choice, override, if minion already has reward selected, choose that reward.
	AJM.settingsControlCompletion.checkBoxHasChoiceOverrideUseMinionRewardSelected = JambaHelperSettings:CreateCheckBox(
		AJM.settingsControlCompletion, 
		headingWidth, 
		column1Left + indent, 
		movingTop,
		L["Override: If Toon Already Has Reward Selected,"],
		AJM.SettingsToggleHasChoiceOverrideUseMinionRewardSelected
	)	
	movingTop = movingTop - checkBoxHeight
	-- Label continuing check box above.
	AJM.settingsControlCompletion.labelHasChoiceOverrideUseMinionRewardSelected = JambaHelperSettings:CreateContinueLabel(
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
		AJM.db.messageArea = settings.messageArea
		AJM.db.warningArea = settings.warningArea
		AJM.db.overrideQuestAutoSelectAndComplete = settings.overrideQuestAutoSelectAndComplete
		-- Refresh the settings.
		AJM:SettingsRefresh()
		-- Tell the player.
		AJM:Print( L["Settings received from A."]( characterName ) )
		-- Tell the team?
		--AJM:JambaSendMessageToTeam( AJM.db.messageArea,  L["Settings received from A."]( characterName ), false )
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
	AJM.settingsControl.checkBoxMinionMirrorMasterAccept:SetValue( AJM.db.slaveMirrorMasterAccept )
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
	AJM.settingsControl.checkBoxMinionAutoAcceptEscortQuest:SetValue( AJM.db.slaveAutoAcceptEscortQuest )
	AJM.settingsControl.checkBoxShowJambaQuestLogWithWoWQuestLog:SetValue( AJM.db.showJambaQuestLogWithWoWQuestLog )
	AJM.settingsControl.checkBoxOverrideQuestAutoSelectAndComplete:SetValue( AJM.db.overrideQuestAutoSelectAndComplete )
	AJM.settingsControl.dropdownMessageArea:SetValue( AJM.db.messageArea )
	AJM.settingsControl.dropdownWarningArea:SetValue( AJM.db.warningArea )
	-- Quest completion options.
	AJM.settingsControlCompletion.checkBoxEnableAutoQuestCompletion:SetValue( AJM.db.enableAutoQuestCompletion )
	AJM.settingsControlCompletion.checkBoxNoChoiceAllDoNothing:SetValue( AJM.db.noChoiceAllDoNothing )
	AJM.settingsControlCompletion.checkBoxNoChoiceMinionCompleteQuestWithMaster:SetValue( AJM.db.noChoiceSlaveCompleteQuestWithMaster )
	AJM.settingsControlCompletion.checkBoxNoChoiceAllAutoCompleteQuest:SetValue( AJM.db.noChoiceAllAutoCompleteQuest )
	AJM.settingsControlCompletion.checkBoxHasChoiceMinionDoNothing:SetValue( AJM.db.hasChoiceSlaveDoNothing )
	AJM.settingsControlCompletion.checkBoxHasChoiceMinionCompleteQuestWithMaster:SetValue( AJM.db.hasChoiceSlaveCompleteQuestWithMaster )
	AJM.settingsControlCompletion.checkBoxHasChoiceMinionChooseSameRewardAsMaster:SetValue( AJM.db.hasChoiceSlaveChooseSameRewardAsMaster )
	AJM.settingsControlCompletion.checkBoxHasChoiceMinionMustChooseOwnReward:SetValue( AJM.db.hasChoiceSlaveMustChooseOwnReward )
	AJM.settingsControlCompletion.checkBoxHasChoiceMinionRewardChoiceModifierConditional:SetValue( AJM.db.hasChoiceSlaveRewardChoiceModifierConditional )
	AJM.settingsControlCompletion.checkBoxHasChoiceCtrlKeyModifier:SetValue( AJM.db.hasChoiceCtrlKeyModifier )
	AJM.settingsControlCompletion.checkBoxHasChoiceShiftKeyModifier:SetValue( AJM.db.hasChoiceShiftKeyModifier )
	AJM.settingsControlCompletion.checkBoxHasChoiceAltKeyModifier:SetValue( AJM.db.hasChoiceAltKeyModifier )
	AJM.settingsControlCompletion.checkBoxHasChoiceOverrideUseMinionRewardSelected:SetValue( AJM.db.hasChoiceOverrideUseSlaveRewardSelected )
	-- Ensure correct state (general and acceptance options).
	AJM.settingsControl.checkBoxMinionMirrorMasterAccept:SetDisabled( not AJM.db.acceptQuests )
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
	AJM.settingsControlCompletion.checkBoxNoChoiceMinionCompleteQuestWithMaster:SetDisabled( not AJM.db.enableAutoQuestCompletion )
	AJM.settingsControlCompletion.checkBoxNoChoiceAllAutoCompleteQuest:SetDisabled( not AJM.db.enableAutoQuestCompletion )
	AJM.settingsControlCompletion.checkBoxHasChoiceMinionDoNothing:SetDisabled( not AJM.db.enableAutoQuestCompletion )
	AJM.settingsControlCompletion.checkBoxHasChoiceMinionCompleteQuestWithMaster:SetDisabled( not AJM.db.enableAutoQuestCompletion )
	AJM.settingsControlCompletion.checkBoxHasChoiceMinionChooseSameRewardAsMaster:SetDisabled( not AJM.db.enableAutoQuestCompletion or not AJM.db.hasChoiceSlaveCompleteQuestWithMaster )
	AJM.settingsControlCompletion.checkBoxHasChoiceMinionMustChooseOwnReward:SetDisabled( not AJM.db.enableAutoQuestCompletion or not AJM.db.hasChoiceSlaveCompleteQuestWithMaster )
	AJM.settingsControlCompletion.checkBoxHasChoiceMinionRewardChoiceModifierConditional:SetDisabled( not AJM.db.enableAutoQuestCompletion or not AJM.db.hasChoiceSlaveCompleteQuestWithMaster )
	AJM.settingsControlCompletion.labelHasChoiceMinionRewardChoiceModifierConditional:SetDisabled( not AJM.db.enableAutoQuestCompletion or not AJM.db.hasChoiceSlaveCompleteQuestWithMaster )
	AJM.settingsControlCompletion.checkBoxHasChoiceCtrlKeyModifier:SetDisabled( not AJM.db.enableAutoQuestCompletion or not AJM.db.hasChoiceSlaveCompleteQuestWithMaster or not AJM.db.hasChoiceSlaveRewardChoiceModifierConditional )
	AJM.settingsControlCompletion.checkBoxHasChoiceShiftKeyModifier:SetDisabled( not AJM.db.enableAutoQuestCompletion or not AJM.db.hasChoiceSlaveCompleteQuestWithMaster or not AJM.db.hasChoiceSlaveRewardChoiceModifierConditional )
	AJM.settingsControlCompletion.checkBoxHasChoiceAltKeyModifier:SetDisabled( not AJM.db.enableAutoQuestCompletion or not AJM.db.hasChoiceSlaveCompleteQuestWithMaster or not AJM.db.hasChoiceSlaveRewardChoiceModifierConditional )
	AJM.settingsControlCompletion.checkBoxHasChoiceOverrideUseMinionRewardSelected:SetDisabled( not AJM.db.enableAutoQuestCompletion or not AJM.db.hasChoiceSlaveCompleteQuestWithMaster )
	AJM.settingsControlCompletion.labelHasChoiceOverrideUseMinionRewardSelected:SetDisabled( not AJM.db.enableAutoQuestCompletion or not AJM.db.hasChoiceSlaveCompleteQuestWithMaster )
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

function AJM:SettingsToggleMinionMirrorMasterAccept( event, checked )
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

function AJM:SettingsToggleMinionAutoAcceptEscortQuest( event, checked )
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

function AJM:SettingsToggleNoChoiceMinionCompleteQuestWithMaster( event, checked )
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

function AJM:SettingsToggleHasChoiceMinionDoNothing( event, checked )
	AJM.db.hasChoiceSlaveDoNothing = checked
	AJM.db.hasChoiceAquireBestQuestRewardForCharacter = not checked
	AJM.db.hasChoiceSlaveCompleteQuestWithMaster = not checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleHasChoiceMinionCompleteQuestWithMaster( event, checked )
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

function AJM:SettingsToggleHasChoiceMinionChooseSameRewardAsMaster( event, checked )
	AJM.db.hasChoiceSlaveChooseSameRewardAsMaster = checked
	AJM.db.hasChoiceSlaveMustChooseOwnReward = not checked
	AJM.db.hasChoiceSlaveRewardChoiceModifierConditional = not checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleHasChoiceMinionMustChooseOwnReward( event, checked )
	AJM.db.hasChoiceSlaveMustChooseOwnReward = checked
	AJM.db.hasChoiceSlaveChooseSameRewardAsMaster = not checked
	AJM.db.hasChoiceSlaveRewardChoiceModifierConditional = not checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleHasChoiceMinionRewardChoiceModifierConditional( event, checked )
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

function AJM:SettingsToggleHasChoiceOverrideUseMinionRewardSelected( event, checked )
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
			AJM:ScheduleTimer("JambaSendCommandToTeam", 0.5, AJM.COMMAND_DECLINE_QUEST )
		end
	end		
end

function AJM:DoDeclineQuest( sender )
	if AJM.db.mirrorMasterQuestSelectionAndDeclining == true then
		AJM.isInternalCommand = true
        AJM:DebugMessage( "DoDeclineQuest" )
		HideUIPanel(QuestFrame)
		--DeclineQuest()
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
			local bestQuestItemIndex =  nil --AJM:GetBestRewardIndexForCharacter()			Max Fix 4/1/2016... this method is commented, yields error.
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
	end
	AJM.isInternalCommand = false	
end

-------------------------------------------------------------------------------------------------------------
-- NPC QUEST PROCESSING - REWARDS
-------------------------------------------------------------------------------------------------------------

function AJM:CheckForOverrideAndChooseQuestReward( questIndex )
	-- Yes, override if minion has reward selected?
	if (AJM.db.hasChoiceOverrideUseSlaveRewardSelected == true) and (QuestInfoFrame.itemChoice > 0) then
		-- Yes, choose minions reward.
		GetQuestReward( QuestInfoFrame.itemChoice )
	else
		-- No, choose masters reward.
		GetQuestReward( questIndex )
	end
end

function AJM:CheckForOverrideAndDoNotChooseQuestReward( questIndex )
	-- Yes, override if minion has reward selected?
	if QuestInfoFrame.itemChoice ~= nil then
		if (AJM.db.hasChoiceOverrideUseSlaveRewardSelected == true) and (QuestInfoFrame.itemChoice > 0) then
			-- Yes, choose minions reward.
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
						-- Yes, choose minions reward.
						GetQuestReward( QuestInfoFrame.itemChoice )
					end
				end
			end
			AJM.isInternalCommand = false
		end
	end
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
					SelectQuestLogEntry( questIndex )
						if GetQuestLogPushable() and GetNumSubgroupMembers() > 0 then
							AJM:JambaSendMessageToTeam( AJM.db.messageArea, "Pushing newly accepted quest.", false )
							QuestLogPushQuest()
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

function AJM:DoAcceptQuest( sender )
	if AJM.db.acceptQuests == true and AJM.db.slaveMirrorMasterAccept == true then
	local questIndex = AJM:GetQuestLogIndexByName( questName )
		--Only works if the quest frame is open. Stops sending a blank quest. Tell the team a char not got the quest window open???? <<<<<< TODO
		if QuestFrame:IsShown() == true then
			AJM.isInternalCommand = true
			AJM:DebugMessage( "DoAcceptQuest" )
			AJM:JambaSendMessageToTeam( AJM.db.messageArea, L["Accepted Quest: A"]( GetTitleText() ), false )
			AcceptQuest()
			HideUIPanel( QuestFrame )
			AJM.isInternalCommand = false
		end		
	end
end

-- Auto quest magic!
function AJM:AcknowledgeAutoAcceptQuest()
	if AJM.db.acceptQuests == true then
		if AJM.db.slaveMirrorMasterAccept == true then
			if AJM.isInternalCommand == false then
                AJM:DebugMessage( "MagicAutoAcceptQuestGrrrr", QuestGetAutoAccept() )
					AJM:JambaSendCommandToTeam( AJM.COMMAND_ACCEPT_QUEST_FAKE )
			end	
		end
	end
end

function AJM:DoMagicAutoAcceptQuestGrrrr()
	if AJM.db.acceptQuests == true and AJM.db.slaveMirrorMasterAccept == true and QuestFrame:IsVisible() then
	local questIndex = AJM:GetQuestLogIndexByName( questName )
		AJM.isInternalCommand = true
		AJM:DebugMessage( "DoMagicAutoAcceptQuestGrrrr" )
		AJM:JambaSendMessageToTeam( AJM.db.messageArea, L["Automatically Accepted AutoPickupQuest: A"]( GetTitleText() ), false )
		AcknowledgeAutoAcceptQuest()
		HideUIPanel( QuestFrame )
		AJM.isInternalCommand = false
	end
end

-------------------------------------------------------------------------------------------------------------
-- QUEST PROCESSING - AUTO ACCEPTING
-------------------------------------------------------------------------------------------------------------

--TODO: this could do with some work with Friends.
function AJM:CanAutoAcceptSharedQuestFromPlayer()
	local canAccept = false
	if AJM.db.allAcceptAnyQuest == true then
		canAccept = true
	elseif AJM.db.onlyAcceptQuestsFrom == true then
		local questSourceName, questSourceRealm = UnitName( "npc" )
		local character = JambaUtilities:AddRealmToNameIfNotNil( questSourceName, questSourceRealm )
		if AJM.db.acceptFromTeam == true then	
			if JambaApi.IsCharacterInTeam( character ) == true then
				canAccept = true
			end
		end
		if AJM.db.acceptFromFriends == true then	
			for friendIndex = 1, GetNumFriends() do
				local friendName = GetFriendInfo( friendIndex )
				if questSourceName == friendName then
					canAccept = true
					break
				end
			end	
		end
		if AJM.db.acceptFromParty == true then	
			if UnitInParty( "npc" ) then
				AJM:DebugMessage( "test" )
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

function AJM:QUEST_DETAIL()
    AJM:DebugMessage( "QUEST_DETAIL" )
	if AJM.db.acceptQuests == true then
		-- Who is this quest from.
		if UnitIsPlayer( "npc" ) then
			-- Quest is shared from a player.
			if AJM:CanAutoAcceptSharedQuestFromPlayer() == true then		
				--TODO: is this even needed??? Can auto quests be shared from other players?? unsure so we add it in anyway.
				if ( QuestFrame.autoQuest ) then
					AcknowledgeAutoAcceptQuest()
				else
					AJM.isInternalCommand = true
					AJM:JambaSendMessageToTeam( AJM.db.messageArea, L["Automatically Accepted Quest: A"]( GetTitleText() ), false )
					AcceptQuest()
					AJM.isInternalCommand = false
				end	
			end			
		else
			-- Quest is from an NPC.
			if (AJM.db.allAcceptAnyQuest == true) or ((AJM.db.onlyAcceptQuestsFrom == true) and (AJM.db.acceptFromNpc == true)) then		
				--AutoQuest is Accepted no need to accept it again.
				if ( QuestFrame.autoQuest ) then
					AcknowledgeAutoAcceptQuest()
				else 	
					AJM.isInternalCommand = true
					--AJM:DebugMessage( "QUEST_DETAIL - auto accept is: ", QuestGetAutoAccept() )
					AJM:JambaSendMessageToTeam( AJM.db.messageArea, L["Automatically Accepted Quest: A"]( GetTitleText() ), false )
					AcceptQuest()
					HideUIPanel( QuestFrame )
					AJM.isInternalCommand = false
				end
			end
		end
	end	
end

-------------------------------------------------------------------------------------------------------------
-- JAMBA QUEST CONTEXT MENU
-------------------------------------------------------------------------------------------------------------



function AJM:QuestMapQuestOptions_AbandonQuest(questID)                       
	if JambaApi.GetTeamListMaximumOrderOnline() > 1 then	
		local lastQuestIndex = GetQuestLogSelection()
		--AJM:Print("SetAbandonQuest", lastQuestIndex, questID)
		title = GetAbandonQuestName()
		local data = {}
		data.questID = questID
		data.title = title
		StaticPopup_Hide( "ABANDON_QUEST" )
		StaticPopup_Hide( "ABANDON_QUEST_WITH_ITEMS" )	
		StaticPopup_Show( "JAMBAQUEST_ABANDON_ALL_TOONS", title, nil, data )
	end	
end

function AJM:QuestMapQuestOptions_TrackQuest(questID)
	if JambaApi.GetTeamListMaximumOrderOnline() > 1 then
		--AJM:Print("test", questID)
		local questLogIndex = GetQuestLogIndexByID(questID)
		local title = GetQuestLogTitle( questLogIndex )
		local data = {}
		data.questID = questID
		data.title = title
		if ( IsQuestWatched(questLogIndex) ) then
			--AJM:Print("TrackingQuest")
			StaticPopup_Show( "JAMBAQUEST_TRACK_ALL_TOONS", title, nil, data )
		else
			--AJM:Print("UnTrackQuest")
			StaticPopup_Show( "JAMBAQUEST_UNTRACK_ALL_TOONS", title, nil, data )	
		end
	end			
end


--Max's Menu System that was tainting like hell do like it trying quest3.0 Ebony's way.

--[[
function JambaQuestMapQuestOptionsDropDown_Initialize(self)
	local questLogIndex = GetQuestLogIndexByID(self.questID);
	local info = UIDropDownMenu_CreateInfo();
	info.isNotRadio = true;
	info.notCheckable = true;
	table.insert( UISpecialFrames, "JambaQuestMapQuestOptionsDropDown" )
	
	info.text = TRACK_QUEST;
	if ( IsQuestWatched(questLogIndex) ) then
		info.text = UNTRACK_QUEST;
	end
	info.func =function(_, questID) AJM:QuestMapQuestOptions_ToggleTrackQuest(questID) end;
	info.arg1 = self.questID;
	UIDropDownMenu_AddButton(info)
	
	info.text = SHARE_QUEST;
	info.func = function(_, questID) AJM:QuestMapQuestOptions_ShareQuest(questID) end;
	info.arg1 = self.questID;
	if ( not GetQuestLogPushable(questLogIndex) or not IsInGroup() ) then
		info.disabled = 1;
	end
	UIDropDownMenu_AddButton(info)
	
	info.text = ABANDON_QUEST;
	info.func = function(_, questID) AJM:QuestMapQuestOptions_AbandonQuest(questID) end;
	info.arg1 = self.questID;
	info.disabled = nil;
	UIDropDownMenu_AddButton(info)
	
	info.text = L["JAMBA_QUESTLOG_CONTEXT_DROPDOWNTEXT_TrackAllToons"];
	if ( IsQuestWatched(questLogIndex) ) then
		info.text = L["JAMBA_QUESTLOG_CONTEXT_DROPDOWNTEXT_UnTrackAllToons"];
	end
	info.func =function(_, questID) AJM:QuestMapQuestOptions_ToggleTrackQuestAllToons(questID) end;
	info.arg1 = self.questID;
	UIDropDownMenu_AddButton(info)
	
	info.text = L["JAMBA_QUESTLOG_CONTEXT_DROPDOWNTEXT_AbandonAllToons"];
	info.func =function(_, questID) AJM:QuestMapQuestOptions_AbandonQuestAllToons(questID) end;
	info.arg1 = self.questID;
	UIDropDownMenu_AddButton(info)
	
	StaticPopupDialogs["JAMBAQUEST_CONFIRM_ABANDON_QUEST_NEW"] = {
        text = L["JAMBA_QUESTLOG_CONTEXT_ALERT_AbandonAllToons"],
        button1 = YES,
        button2 = NO,
       	  timeout = 0,
			whileDead = true,
		hideOnEscape = true,
       OnAccept = function(self, data)
			AJM:JambaSendCommandToTeam( AJM.COMMAND_ABANDON_QUEST, data.questID, data.title)
		end,
    }
end

function AJM:QuestMapQuestOptions_ToggleTrackQuest(questID)
	local questLogIndex = GetQuestLogIndexByID(questID);
	
	if ( IsQuestWatched(questLogIndex) ) then
		QuestObjectiveTracker_UntrackQuest(nil, questID);
	else
		AddQuestWatch(questLogIndex, true);
		QuestSuperTracking_OnQuestTracked(questID);
	end
end

function AJM:QuestMapQuestOptions_ShareQuest(questID)

	local questLogIndex = GetQuestLogIndexByID(questID);
	QuestLogPushQuest(questLogIndex);
	PlaySound("igQuestLogOpen");
end

 function AJM:QuestMapQuestOptions_AbandonQuest(questID)
	local lastQuestIndex = GetQuestLogSelection();
	SelectQuestLogEntry(GetQuestLogIndexByID(questID));
	SetAbandonQuest();
	local items = GetAbandonQuestItems();
	if ( items ) then
		StaticPopup_Hide("ABANDON_QUEST");
		StaticPopup_Show("ABANDON_QUEST_WITH_ITEMS", GetAbandonQuestName(), items);
	else
		StaticPopup_Hide("ABANDON_QUEST_WITH_ITEMS");
		StaticPopup_Show("ABANDON_QUEST", GetAbandonQuestName());
	end
	SelectQuestLogEntry(lastQuestIndex);
end

function AJM:QuestMapQuestOptions_ToggleTrackQuestAllToons(questID)

	local questLogIndex = GetQuestLogIndexByID(questID);
	local title = GetQuestLogTitle( questLogIndex )
	
	if ( IsQuestWatched(questLogIndex) ) then
		AJM:JambaSendCommandToTeam( AJM.COMMAND_QUEST_TRACK, questID, title, false )
	else
		AJM:JambaSendCommandToTeam( AJM.COMMAND_QUEST_TRACK, questID, title, true )
	end
end

function AJM:QuestMapQuestOptions_AbandonQuestAllToons(questID)

	local questLogIndex = GetQuestLogIndexByID(questID);
	local title = GetQuestLogTitle( questLogIndex )
	
	local data = {}
	data.questID = questID
	data.title = title

	StaticPopup_Show("JAMBAQUEST_CONFIRM_ABANDON_QUEST_NEW", title, nil, data)
	
end


]]

function AJM:QuestMapQuestOptions_Jamba_DoQuestTrack( sender, questID, title, track )
	local questLogIndex = GetQuestLogIndexByID( questID )
	if questLogIndex ~= 0 then
		if track then
			AJM:JambaDoQuest_TrackQuest( questID, questLogIndex )
		else
			AJM:JambaDoQuest_UnTrackQuest( questID, questLogIndex )
		end
	else
		AJM:JambaSendMessageToTeam( AJM.db.messageArea, L["JAMBA_QUESTLOG_DoNotHaveQuest"]( title ), false )
	end		
end

function AJM:JambaDoQuest_TrackQuest(questID, questLogIndex)
	--AJM:Print("test", questID, questLogIndex )
	if ( not IsQuestWatched(questID) ) then
		AddQuestWatch(questLogIndex, true)
		QuestSuperTracking_OnQuestTracked(questID)
	end
end


function AJM:JambaDoQuest_UnTrackQuest(questID, questLogIndex)
	--AJM:Print("test", questID, questLogIndex )
	if ( IsQuestWatched(questLogIndex) ) then
		QuestObjectiveTracker_UntrackQuest(nil, questID)
	end
end



function AJM:QuestMapQuestOptions_Jamba_DoAbandonQuest( sender, questID, title )
	local questLogIndex = GetQuestLogIndexByID( questID )
	if questLogIndex ~= 0 then
		local lastQuestIndex = GetQuestLogSelection();
		SelectQuestLogEntry(GetQuestLogIndexByID(questID));
		SetAbandonQuest();
		AbandonQuest();
		SelectQuestLogEntry(lastQuestIndex);	
		AJM:JambaSendMessageToTeam( AJM.db.messageArea, L["JAMBA_QUESTLOG_HaveAbandonedQuest"]( title ), false )
	end		
end



-- Jamba ALL menu at the bottom of quest WorldMap Quest Log


function AJM:CreateJambaMiniQuestLogFrame()

    JambaMiniQuestLogFrame = CreateFrame( "Frame", "JambaMiniQuestLogFrame", QuestMapFrame )
    local frame = JambaMiniQuestLogFrame
	frame:SetWidth( 295 )
	frame:SetHeight( 50 )
	frame:SetFrameStrata( "HIGH" )
	frame:SetToplevel( true )
	frame:SetClampedToScreen( true )
	frame:EnableMouse( true )
	frame:SetMovable( true )	
	frame:ClearAllPoints()
	frame:SetPoint("BOTTOMRIGHT", QuestMapFrame, "BOTTOMRIGHT", 5,-50)
		frame:SetBackdrop( {
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", 
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", 
		tile = true, tileSize = 15, edgeSize = 15, 
		insets = { left = 5, right = 5, top = 5, bottom = 5 }
	} )
	table.insert( UISpecialFrames, "JambaQuestLogWindowFrame" )

	-- abandon ALL button
	local abandonButton = CreateFrame( "Button", "abandonButton", frame, "UIPanelButtonTemplate" )
	abandonButton:SetScript( "OnClick", function()  StaticPopup_Show("AbandonALLToonsQuest") end )
	abandonButton:SetPoint( "TOPLEFT", frame, "TOPLEFT", 0 , -5)
	abandonButton:SetHeight( 35 )
	abandonButton:SetWidth( 100 )
	abandonButton:SetText( L["Abandon All\nQuests"] )	
	abandonButton:SetScript("OnEnter", function(self) AJM:ShowTooltip(trackButton, true, L["Aabandon All Quests on all Minions"]) end)
	abandonButton:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
	abandonQuestLogWindowAbandonFrameButton = abandonButton

	-- Share All Button
	local shareButton = CreateFrame( "Button", "shareButton", frame, "UIPanelButtonTemplate" )
	shareButton:SetScript( "OnClick", function()  AJM:DoShareAllQuestsFromAllToons() end )
	shareButton:SetPoint( "TOPLEFT", frame, "TOPLEFT", 100, -5)
	shareButton:SetHeight( 21 )
	shareButton:SetWidth( 100 )
	shareButton:SetText( L["Share All"] )	
	shareButton:SetScript("OnEnter", function(self) AJM:ShowTooltip(shareButton, true, L["share All Quests to all Minions"]) end)
	shareButton:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
	shareQuestLogWindowFrameShareButton = shareButton

	--Track All Button
	local trackButton = CreateFrame( "Button", "trackButton", frame, "UIPanelButtonTemplate" )
	trackButton:SetScript( "OnClick", function()  AJM:DoTrackAllQuestsFromAllToons() end )
	trackButton:SetPoint( "TOPRIGHT", frame, "TOPRIGHT", 0, -5)
	trackButton:SetHeight( 21 )
	trackButton:SetWidth( 100 )
	trackButton:SetText( L["Track All"] )	
	trackButton:SetScript("OnEnter", function(self) AJM:ShowTooltip(trackButton, true, L["Track All Quests on all Minions"]) end)
	trackButton:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
	JambaQuestLogWindowFrameTrackButton = trackButton

	-- Untrack All
	local unTrackButton = CreateFrame( "Button", "unTrackButton", frame, "UIPanelButtonTemplate" )
	unTrackButton:SetScript( "OnClick", function()  AJM:DoUnTrackAllQuestsFromAllToons() end )
	unTrackButton:SetPoint( "TOPRIGHT", frame, "TOPRIGHT", 0, -25)
	unTrackButton:SetHeight( 21 )
	unTrackButton:SetWidth( 100 )
	unTrackButton:SetText( L["Untrack All"] )	
	unTrackButton:SetScript("OnEnter", function(self) AJM:ShowTooltip(trackButton, true, L["Untrack All Quests on all Minions"]) end)
	unTrackButton:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
	JambaQuestLogWindowFrameUnTrackButton = unTrackButton
end


function AJM:ShowTooltip(frame, show, text)
	if show then
		GameTooltip:SetOwner(frame, "ANCHOR_TOP")
		GameTooltip:SetPoint("TOPLEFT", frame, "TOPRIGHT", 16, 0)
		GameTooltip:ClearLines()
		GameTooltip:AddLine( text , 1, 0.82, 0, 1)
		GameTooltip:Show()
	else
	GameTooltip:Hide()
	end
end

function AJM:DoAbandonAllQuestsFromAllToons()
	AJM:JambaSendMessageToTeam( AJM.db.messageArea, L["Abandoning quest's to all toons"], false )
	AJM:DoAbandonAllQuestsFromThisToon()	
	AJM:ScheduleTimer("JambaSendCommandToTeam" , 2, AJM.COMMAND_ABANDON_ALL_QUESTS)
end

function AJM:DoAbandonAllQuestsFromThisToon()
	AJM.iterateQuests = 0
	AJM:IterateQuests("AbandonNextQuest", 0.5)
end

function AJM.AbandonNextQuest()
	local title, isHeader, questID = AJM:GetRelevantQuestInfo(AJM.iterateQuests)
	if isHeader == false and questID ~= 0 then
		local canAbandon = CanAbandonQuest(questID)
		if canAbandon then
			AJM:JambaSendCommandToTeam( AJM.COMMAND_ABANDON_QUEST, questID, title)
			if (AJM.iterateQuests ~= GetNumQuestLogEntries()) then
				-- decrement quest count as we have removed one if not last quest
				AJM.iterateQuests = AJM.iterateQuests - 1
			end
		end
	end
	AJM:IterateQuests("AbandonNextQuest", 0.5)
end

function AJM.DoShareAllQuestsFromAllToons()
	AJM:JambaSendMessageToTeam( AJM.db.messageArea, L["Sharing Quest's to All Minions"], false )
	AJM:DoShareAllQuestsFromThisToon()	
	AJM:ScheduleTimer("JambaSendCommandToTeam" , 2,  AJM.COMMAND_SHARE_ALL_QUESTS)
end

function AJM.DoShareAllQuestsFromThisToon()
	AJM.iterateQuests = 0
	AJM:IterateQuests("ShareNextQuest", 1)
end

function AJM.ShareNextQuest()
	local title, isHeader, questID = AJM:GetRelevantQuestInfo(AJM.iterateQuests)
	if GetQuestLogPushable() then
		if isHeader == false and questID ~= 0 then
			QuestMapQuestOptions_ShareQuest(questID)
		end
	end	
	AJM:IterateQuests("ShareNextQuest", 1)
end


function AJM:DoTrackAllQuestsFromAllToons()
	AJM:JambaSendMessageToTeam( AJM.db.messageArea, L["Tracking Quest's to All Minions"], false )
	AJM:DoTrackAllQuestsFromThisToon()
	AJM:ScheduleTimer("JambaSendCommandToTeam", 1, AJM.COMMAND_TRACK_ALL_QUESTS)
end

function AJM:DoTrackAllQuestsFromThisToon()
	AJM.iterateQuests = 0
	AJM:IterateQuests("TrackNextQuest", 0.5)
end

function AJM.TrackNextQuest()

	local title, isHeader, questID = AJM:GetRelevantQuestInfo(AJM.iterateQuests)

	if isHeader == false and questID ~= 0 then
		AJM:JambaSendCommandToTeam( AJM.COMMAND_QUEST_TRACK, questID, title, true )
	end

	AJM:IterateQuests("TrackNextQuest", 0.5)
end

function AJM:DoUnTrackAllQuestsFromAllToons()
	AJM:JambaSendMessageToTeam( AJM.db.messageArea, L["Untracking Quest's to All Minions"], false )
	AJM:DoUnTrackAllQuestsFromThisToon()
	AJM:ScheduleTimer("JambaSendCommandToTeam", 1, AJM.COMMAND_UNTRACK_ALL_QUESTS)
end

function AJM:DoUnTrackAllQuestsFromThisToon()
	AJM.iterateQuests = 0
	AJM:IterateQuests("UnTrackNextQuest", 0.5)
end


function AJM.UnTrackNextQuest()
	local title, isHeader, questID = AJM:GetRelevantQuestInfo(AJM.iterateQuests)
		if isHeader == false and questID ~= 0 then
			AJM:JambaSendCommandToTeam( AJM.COMMAND_QUEST_TRACK, questID, title, false )
		end
	AJM:IterateQuests("UnTrackNextQuest", 0.5)
end

function AJM:IterateQuests(methodToCall, timer)
	AJM.iterateQuests = AJM.iterateQuests + 1
		if AJM.iterateQuests <= GetNumQuestLogEntries() then
			AJM:ScheduleTimer( methodToCall, timer )
		end
end

function AJM:GetRelevantQuestInfo(questLogIndex)
    local title, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID, startEvent, displayQuestID, isOnMap, hasLocalPOI, isTask, isStory = GetQuestLogTitle( questLogIndex )
	return title, isHeader, questID
end

function AJM:ToggleFrame( frame )
	if frame == WorldMapFrame then
		AJM:ToggleQuestLog()
	end
end

function AJM:ToggleQuestLog()
	-- This sorts out hooking on L or marcioMenu button
	if AJM.db.showJambaQuestLogWithWoWQuestLog == true then
		if WorldMapFrame:IsVisible() and QuestMapFrame:IsVisible() then
			AJM:ToggleShowQuestCommandWindow( true )
		else
			AJM:ToggleShowQuestCommandWindow( false )
		end
	end
end

function AJM:QuestLogFrameHide()
	if AJM.db.showJambaQuestLogWithWoWQuestLog == true then
		AJM:ToggleShowQuestCommandWindow( false )
	end
end

function AJM:ToggleShowQuestCommandWindow( show )
    if show == true then
		JambaMiniQuestLogFrame:Show()
    else
		JambaMiniQuestLogFrame:Hide()
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

function AJM:AutoSelectToggleCommand( info, parameters )
	local toggle, tag = strsplit( " ", parameters )
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
-- Want to action track and abandon command on the same character tat sent the command.
	if commandName == AJM.COMMAND_QUEST_TRACK then
		AJM:QuestMapQuestOptions_Jamba_DoQuestTrack( characterName, ... )
	end
	if commandName == AJM.COMMAND_ABANDON_QUEST then		
		AJM:QuestMapQuestOptions_Jamba_DoAbandonQuest( characterName, ... )
	end
	 
	 -- If this character sent this command, don't action it.
	if characterName == AJM.characterName then
		return
	end

	if commandName == AJM.COMMAND_ABANDON_ALL_QUESTS then		
		AJM:DoAbandonAllQuestsFromThisToon()
	end
	if commandName == AJM.COMMAND_TRACK_ALL_QUESTS then		
		AJM:DoTrackAllQuestsFromThisToon()
	end
	if commandName == AJM.COMMAND_UNTRACK_ALL_QUESTS then		
		AJM:DoUnTrackAllQuestsFromThisToon()
	end
	if commandName == AJM.COMMAND_SHARE_ALL_QUESTS then		
		AJM:DoShareAllQuestsFromThisToon()
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
	if commandName == AJM.COMMAND_LOG_COMPLETE_QUEST then
		AJM:DoShowQuestComplete( characterName, ... )
	end
	if commandName == AJM.COMMAND_ACCEPT_QUEST_FAKE then
		AJM:DoMagicAutoAcceptQuestGrrrr( characterName, ... )
	end
end
