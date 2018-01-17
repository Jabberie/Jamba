--[[
Jamba - Jafula's Awesome Multi-Boxer Assistant
Copyright 2008 - 2018 Michael "Jafula" Miller
License: The MIT License
]]--

-- Create the addon using AceAddon-3.0 and embed some libraries.
local AJM = LibStub( "AceAddon-3.0" ):NewAddon( 
	"JambaQuestWatcher", 
	"JambaModule-1.0", 
	"AceConsole-3.0", 
	"AceEvent-3.0",
	"AceHook-3.0",
	"AceTimer-3.0"
)

-- Load libraries.
local JambaUtilities = LibStub:GetLibrary( "JambaUtilities-1.0" )
local JambaHelperSettings = LibStub:GetLibrary( "JambaHelperSettings-1.0" )
AJM.SharedMedia = LibStub( "LibSharedMedia-3.0" )

--  Constants and Locale for this module.
AJM.moduleName = "Jamba-QuestWatcher"
AJM.settingsDatabaseName = "JambaQuestWatcherProfileDB"
AJM.chatCommand = "jamba-quest-watcher"
local L = LibStub( "AceLocale-3.0" ):GetLocale( AJM.moduleName )
AJM.parentDisplayName = L["Quest"]
AJM.moduleDisplayName = L["Quest: Tracker"]

-- Settings - the values to store and their defaults for the settings database.
AJM.settings = {
	profile = {
		enableQuestWatcher = true,
		watcherFramePoint = "RIGHT",
		watcherFrameRelativePoint = "RIGHT",
		watcherFrameXOffset = 0,
		watcherFrameYOffset = 150,
		watcherFrameAlpha = 1.0,
		watcherFrameScale = 1.0,
		borderStyle = L["Blizzard Tooltip"],
		backgroundStyle = L["Blizzard Dialog Background"],
		watchFontStyle = L["Arial Narrow"],
		watchFontSize = 14,
		hideQuestWatcherInCombat = false,
		enableQuestWatcherOnMasterOnly = false,
		watchFrameBackgroundColourR = 0.0,
		watchFrameBackgroundColourG = 0.0,
		watchFrameBackgroundColourB = 0.0,
		watchFrameBackgroundColourA = 0.0,
		watchFrameBorderColourR = 0.0,
		watchFrameBorderColourG = 0.0,
		watchFrameBorderColourB = 0.0,
		watchFrameBorderColourA = 0.0,
		watcherListLines = 20,
		watcherFrameWidth = 340,
		unlockWatcherFrame = true,
		hideBlizzardWatchFrame = true,
		doNotHideCompletedObjectives = true,
		showCompletedObjectivesAsDone = true,
		hideQuestIfAllComplete = false,
		showFrame = true,
		messageArea = JambaApi.DefaultMessageArea(),
		sendProgressChatMessages = false,
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
			show = {
				type = "input",
				name = L["Show Quest Watcher"],
				desc = L["Show the quest watcher window."],
				usage = "/jamba-quest-watcher show",
				get = false,
				set = "ShowFrameCommand",
			},		
			hide = {
				type = "input",
				name = L["Hide Quest Watcher"],
				desc = L["Hide the quest watcher window."],
				usage = "/jamba-quest-watcher hide",
				get = false,
				set = "HideFrameCommand",
			},		
			push = {
				type = "input",
				name = L["Push Settings"],
				desc = L["Push the quest settings to all characters in the team."],
				usage = "/jamba-quest-watcher push",
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

AJM.COMMAND_QUEST_WATCH_OBJECTIVE_UPDATE = "JQWObjUpd"
AJM.COMMAND_UPDATE_QUEST_WATCHER_LIST = "JQWLstUpd"
AJM.COMMAND_QUEST_WATCH_REMOVE_QUEST = "JQWRmveQst"
AJM.COMMAND_AUTO_QUEST_COMPLETE = "JQWAtQstCmplt"
AJM.COMMAND_REMOVE_AUTO_QUEST_COMPLETE = "JQWRmvAtQstCmplt"
AJM.COMMAND_AUTO_QUEST_OFFER = "JQWAqQstOfr"

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
	AJM.currentAutoQuestPopups = {}
	AJM.countAutoQuestPopUpFrames = 0
	AJM.questWatcherFrameCreated = false
	-- Create the settings control.
	AJM:SettingsCreate()
	-- Initialise the JambaModule part of this module.
	AJM:JambaModuleInitialize( AJM.settingsControlWatcher.widgetSettings.frame )
	-- Populate the settings.
	AJM:SettingsRefresh()	
	-- Create the quest watcher frame.
	AJM:CreateQuestWatcherFrame()
	AJM:SetQuestWatcherVisibility()		
	-- Quest watcher.
	AJM.questWatchListOfQuests = {}
	AJM.questWatchCache = {}
	AJM.questWatchObjectivesList = {}
end

-- Called when the addon is enabled.
function AJM:OnEnable()
	-- Register for the Jamba master changed message.
	AJM:RegisterMessage( JambaApi.MESSAGE_TEAM_MASTER_CHANGED, "OnMasterChanged" )
	AJM:RegisterMessage( JambaApi.MESSAGE_MESSAGE_AREAS_CHANGED, "OnMessageAreasChanged" )
    -- Quest events.
	-- Watcher events.
	AJM:RegisterEvent( "PLAYER_REGEN_ENABLED" )
	AJM:RegisterEvent( "PLAYER_REGEN_DISABLED" )
	AJM:RegisterEvent( "QUEST_WATCH_UPDATE" )
	AJM:RegisterEvent( "QUEST_LOG_UPDATE")
	AJM:RegisterEvent( "QUEST_WATCH_LIST_CHANGED", "QUEST_WATCH_UPDATE" )
	-- For in the field auto quests. And Bonus Quests.
	AJM:RegisterEvent("QUEST_ACCEPTED", "QUEST_WATCH_UPDATE")
	AJM:RegisterEvent("QUEST_REMOVED", "RemoveQuestsNotBeingWatched")
	--AJM:RegisterEvent("UNIT_QUEST_LOG_CHANGED", "JambaQuestWatchListUpdateButtonClicked")
	AJM:RegisterEvent( "QUEST_AUTOCOMPLETE" )
	AJM:RegisterEvent( "QUEST_COMPLETE" )
	AJM:RegisterEvent( "QUEST_DETAIL" )
	AJM:RegisterEvent( "SCENARIO_UPDATE" )
	AJM:RegisterEvent( "SCENARIO_CRITERIA_UPDATE" )
	--AJM:RegisterEvent( "SUPER_TRACKED_QUEST_CHANGED", "QUEST_WATCH_UPDATE" )
	AJM:RegisterEvent( "PLAYER_ENTERING_WORLD" )
   -- Quest post hooks.
    AJM:SecureHook( "SelectActiveQuest" )
	AJM:SecureHook( "GetQuestReward" )
	AJM:SecureHook( "AddQuestWatch" )
	AJM:SecureHook( "RemoveQuestWatch" )
	AJM:SecureHook( "AbandonQuest" )
	AJM:SecureHook( "SetAbandonQuest" )
	-- Update the quest watcher for watched quests.
	AJM:ScheduleTimer( "JambaQuestWatcherUpdate", 1, false )
	AJM:ScheduleTimer( "JambaQuestWatcherScenarioUpdate", 1, false )
	AJM:UpdateUnlockWatcherFrame()
	-- To Hide After elv changes. --ebony
	AJM:ScheduleTimer( "UpdateHideBlizzardWatchFrame", 2 )
	-- Remvoed me somtime 7.0.4
	--AJM:UpdateHideBlizzardWatchFrame()
	if AJM.db.enableQuestWatcher == true then
		AJM:QuestWatcherQuestListScrollRefresh()
	end
end

-- Called when the addon is disabled.
function AJM:OnDisable()
	-- AceHook-3.0 will tidy up the hooks for us. 
end

-------------------------------------------------------------------------------------------------------------
-- Messages.
-------------------------------------------------------------------------------------------------------------

function AJM:OnMasterChanged( message, characterName )
	if AJM.db.enableQuestWatcher == false then
		return
	end
	AJM:SetQuestWatcherVisibility()
end

-------------------------------------------------------------------------------------------------------------
-- Settings Dialogs.
-------------------------------------------------------------------------------------------------------------

function AJM:SettingsCreate()
	AJM.settingsControlWatcher = {}
	-- Create the settings panels.
	JambaHelperSettings:CreateSettings( 
		AJM.settingsControlWatcher, 
		AJM.moduleDisplayName, 
		AJM.parentDisplayName, 
		AJM.SettingsPushSettingsClick 
	)	
	-- Create the quest controls.
	local bottomOfQuestWatcherOptions = AJM:SettingsCreateQuestWatcherControl( JambaHelperSettings:TopOfSettings() )
	AJM.settingsControlWatcher.widgetSettings.content:SetHeight( -bottomOfQuestWatcherOptions )
		-- Help
	local helpTable = {}
	JambaHelperSettings:CreateHelp( AJM.settingsControlWatcher, helpTable, AJM:GetConfiguration() )	
end

function AJM:SettingsCreateQuestWatcherControl( top )
	-- Get positions and dimensions.
	local checkBoxHeight = JambaHelperSettings:GetCheckBoxHeight()
	local radioBoxHeight = JambaHelperSettings:GetRadioBoxHeight()
	local mediaHeight = JambaHelperSettings:GetMediaHeight()
	local labelHeight = JambaHelperSettings:GetLabelHeight()
	local sliderHeight = JambaHelperSettings:GetSliderHeight()
	local dropdownHeight = JambaHelperSettings:GetDropdownHeight()
	local labelContinueHeight = JambaHelperSettings:GetContinueLabelHeight()
	local left = JambaHelperSettings:LeftOfSettings()
	local headingHeight = JambaHelperSettings:HeadingHeight()
	local headingWidth = JambaHelperSettings:HeadingWidth( true )
	local horizontalSpacing = JambaHelperSettings:GetHorizontalSpacing()
	local verticalSpacing = JambaHelperSettings:GetVerticalSpacing()
	local halfWidthSlider = (headingWidth - horizontalSpacing) / 2
	local indent = horizontalSpacing * 10
	local indentContinueLabel = horizontalSpacing * 18
	local indentSpecial = indentContinueLabel + 9
	local checkBoxThirdWidth = (headingWidth - indentContinueLabel) / 3
	local column1Left = left
	local column2Left = left + halfWidthSlider
	local column1LeftIndent = left + indentContinueLabel
	local column2LeftIndent = column1LeftIndent + checkBoxThirdWidth + horizontalSpacing
	local column3LeftIndent = column2LeftIndent + checkBoxThirdWidth + horizontalSpacing
	local movingTop = top
	-- Create a heading for quest completion.
	JambaHelperSettings:CreateHeading( AJM.settingsControlWatcher, L["Quest Watcher"], movingTop, true )
	movingTop = movingTop - headingHeight
	-- Check box: Enable auto quest completion.
	AJM.settingsControlWatcher.checkBoxEnableQuestWatcher = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControlWatcher, 
		headingWidth, 
		column1Left, 
		movingTop,
		L["Enable JoT"],
		AJM.SettingsToggleEnableQuestWatcher,
		L["Enables Jamba Objective Tracker"]
	)	
--	movingTop = movingTop - checkBoxHeight
--	AJM.settingsControlWatcher.checkBoxShowFrame = JambaHelperSettings:CreateCheckBox( 
--		AJM.settingsControlWatcher, 
--		headingWidth, 
--		left, 
--		movingTop, 
--		L["Show Quest Watcher"],
--		AJM.SettingsToggleShowFrame,
--		L["Show Quest Watcher"]
--	)
	movingTop = movingTop - checkBoxHeight		
	AJM.settingsControlWatcher.checkBoxUnlockWatcherFrame = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControlWatcher, 
		headingWidth, 
		left, 
		movingTop, 
		L["Unlock JoT"],
		AJM.SettingsToggleUnlockWatcherFrame,
		L["Unlocks Jamba Objective Tracker\n Hold Alt key To Move It\n Lock to Click Through"]
	)
	movingTop = movingTop - checkBoxHeight	
	AJM.settingsControlWatcher.checkBoxHideBlizzardWatchFrame = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControlWatcher, 
		headingWidth, 
		left, 
		movingTop, 
		L["Hide Blizzard's Objectives Tracker"],
		AJM.SettingsToggleHideBlizzardWatchFrame,
		L["Hides Defualt Objective Tracker"]
	)
	movingTop = movingTop - checkBoxHeight	
	AJM.settingsControlWatcher.checkBoxEnableQuestWatcherMasterOnly = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControlWatcher, 
		headingWidth, 
		column1Left, 
		movingTop,
		L["Show JoT On Master Only"],
		AJM.SettingsToggleEnableQuestWatcherMasterOnly,
		L["Olny show Jamba Objective Tracker On Master Character Olny"]
		
	)	
	movingTop = movingTop - checkBoxHeight	
	AJM.settingsControlWatcher.displayOptionsCheckBoxHideQuestWatcherInCombat = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControlWatcher, 
		headingWidth, 
		column1Left, 
		movingTop, 
		L["Hide JoT In Combat"],
		AJM.SettingsToggleHideQuestWatcherInCombat,
		L["Hide Jamba Objective Tracker in Combat"]
	)	
	movingTop = movingTop - checkBoxHeight
	AJM.settingsControlWatcher.checkBoxShowCompletedObjectivesAsDone = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControlWatcher, 
		headingWidth, 
		left, 
		movingTop, 
		L["Show Completed objective As 'DONE'"],
		AJM.SettingsShowCompletedObjectivesAsDone,
		L["Show Completed Objectives/Quests As 'DONE'"]
	)
	movingTop = movingTop - checkBoxHeight
	AJM.settingsControlWatcher.checkBoxHideQuestIfAllComplete = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControlWatcher, 
		headingWidth, 
		left, 
		movingTop, 
		L["Hide objectives Completed By Team"],
		AJM.SettingsHideQuestIfAllComplete,
		L["Hide Objectives/Quests Completed By Team"]
	)
	movingTop = movingTop - checkBoxHeight
	AJM.settingsControlWatcher.checkBoxShowDoNotHideCompletedObjectives = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControlWatcher, 
		headingWidth, 
		left, 
		movingTop, 
		L["Do Not Hide An Individuals Completed Objectives"],
		AJM.SettingsDoNotHideCompletedObjectives,
		L["Do Not Hide An Individuals Completed Objectives"]
	)
	movingTop = movingTop - checkBoxHeight
	AJM.settingsControlWatcher.checkBoxSendProgressChatMessages = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControlWatcher, 
		headingWidth, 
		left, 
		movingTop, 
		L["Send Progress Messages To Message Area"],
		AJM.SettingsToggleSendProgressChatMessages,
		L["Send Progress Messages To Message Area/Chat"]
	)
	movingTop = movingTop - checkBoxHeight			
	-- Message area.
	AJM.settingsControlWatcher.dropdownMessageArea = JambaHelperSettings:CreateDropdown( 
		AJM.settingsControlWatcher, 
		headingWidth, 
		left, 
		movingTop, 
		L["Send Message Area"]	
	)
	AJM.settingsControlWatcher.dropdownMessageArea:SetList( JambaApi.MessageAreaList() )
	AJM.settingsControlWatcher.dropdownMessageArea:SetCallback( "OnValueChanged", AJM.SettingsSetMessageArea )
	movingTop = movingTop - dropdownHeight
	JambaHelperSettings:CreateHeading( AJM.settingsControlWatcher, L["Appearance & Layout"], movingTop, true )
	movingTop = movingTop - headingHeight - verticalSpacing

	AJM.settingsControlWatcher.displayOptionsQuestWatcherLinesSlider = JambaHelperSettings:CreateSlider( 
		AJM.settingsControlWatcher, 
		halfWidthSlider, 
		left, 
		movingTop, 
		L["Lines Of Info To Display"]
	)
	AJM.settingsControlWatcher.displayOptionsQuestWatcherLinesSlider:SetSliderValues( 5, 50, 1 )
	AJM.settingsControlWatcher.displayOptionsQuestWatcherLinesSlider:SetCallback( "OnValueChanged", AJM.SettingsChangeWatchLines )
	AJM.settingsControlWatcher.displayOptionsQuestWatcherFrameWidthSlider = JambaHelperSettings:CreateSlider( 
		AJM.settingsControlWatcher, 
		halfWidthSlider, 
		column2Left, 
		movingTop, 
		L["Quest Watcher Width"]
	)
	AJM.settingsControlWatcher.displayOptionsQuestWatcherFrameWidthSlider:SetSliderValues( 250, 600, 5 )
	AJM.settingsControlWatcher.displayOptionsQuestWatcherFrameWidthSlider:SetCallback( "OnValueChanged", AJM.SettingsChangeWatchFrameWidth )
	movingTop = movingTop - sliderHeight - verticalSpacing	
	AJM.settingsControlWatcher.displayOptionsQuestWatcherMediaBorder = JambaHelperSettings:CreateMediaBorder( 
		AJM.settingsControlWatcher, 
		halfWidthSlider, 
		left, 
		movingTop,
		L["Border Style"]
	)
	AJM.settingsControlWatcher.displayOptionsQuestWatcherMediaBorder:SetCallback( "OnValueChanged", AJM.SettingsChangeBorderStyle )
	AJM.settingsControlWatcher.questWatchBorderColourPicker = JambaHelperSettings:CreateColourPicker(
		AJM.settingsControlWatcher,
		halfWidthSlider,
		column2Left + 15,
		movingTop - 15,
		L["Border Colour"]
	)
	AJM.settingsControlWatcher.questWatchBorderColourPicker:SetHasAlpha( true )
	AJM.settingsControlWatcher.questWatchBorderColourPicker:SetCallback( "OnValueConfirmed", AJM.SettingsQuestWatchBorderColourPickerChanged )
	movingTop = movingTop - mediaHeight - verticalSpacing
	AJM.settingsControlWatcher.displayOptionsQuestWatcherMediaBackground = JambaHelperSettings:CreateMediaBackground( 
		AJM.settingsControlWatcher, 
		halfWidthSlider, 
		column1Left, 
		movingTop,
		L["Background"]
	)
	AJM.settingsControlWatcher.displayOptionsQuestWatcherMediaBackground:SetCallback( "OnValueChanged", AJM.SettingsChangeBackgroundStyle )
	AJM.settingsControlWatcher.questWatchBackgroundColourPicker = JambaHelperSettings:CreateColourPicker(
		AJM.settingsControlWatcher,
		halfWidthSlider,
		column2Left + 15,
		movingTop - 15,
		L["Background Colour"]
	)
	AJM.settingsControlWatcher.questWatchBackgroundColourPicker:SetHasAlpha( true )
	AJM.settingsControlWatcher.questWatchBackgroundColourPicker:SetCallback( "OnValueConfirmed", AJM.SettingsQuestWatchBackgroundColourPickerChanged )
	movingTop = movingTop - mediaHeight - verticalSpacing
	AJM.settingsControlWatcher.questWatchMediaFont = JambaHelperSettings:CreateMediaFont( 
		AJM.settingsControlWatcher, 
		halfWidthSlider, 
		left, 
		movingTop,
		L["Font"]
	)
	AJM.settingsControlWatcher.questWatchMediaFont:SetCallback( "OnValueChanged", AJM.SettingsChangeFontStyle )
	AJM.settingsControlWatcher.questWatchFontSize = JambaHelperSettings:CreateSlider( 
		AJM.settingsControlWatcher, 
		halfWidthSlider, 
		column2Left, 
		movingTop, 
		L["Font Size"]
	)	
	AJM.settingsControlWatcher.questWatchFontSize:SetSliderValues( 8, 20 , 1 )
	AJM.settingsControlWatcher.questWatchFontSize:SetCallback( "OnValueChanged", AJM.SettingsChangeFontSize )	
	movingTop = movingTop - mediaHeight - verticalSpacing
	AJM.settingsControlWatcher.displayOptionsQuestWatcherScaleSlider = JambaHelperSettings:CreateSlider( 
		AJM.settingsControlWatcher, 
		halfWidthSlider, 
		column1Left, 
		movingTop, 
		L["Scale"]
	)
	AJM.settingsControlWatcher.displayOptionsQuestWatcherScaleSlider:SetSliderValues( 0.5, 2, 0.01 )
	AJM.settingsControlWatcher.displayOptionsQuestWatcherScaleSlider:SetCallback( "OnValueChanged", AJM.SettingsChangeScale )
	--movingTop = movingTop - sliderHeight - verticalSpacing	
	AJM.settingsControlWatcher.displayOptionsQuestWatcherTransparencySlider = JambaHelperSettings:CreateSlider( 
		AJM.settingsControlWatcher, 
		halfWidthSlider, 
		column2Left, 
		movingTop, 
		L["Transparency"]
	)
	AJM.settingsControlWatcher.displayOptionsQuestWatcherTransparencySlider:SetSliderValues( 0, 1, 0.01 )
	AJM.settingsControlWatcher.displayOptionsQuestWatcherTransparencySlider:SetCallback( "OnValueChanged", AJM.SettingsChangeTransparency )
	movingTop = movingTop - sliderHeight - verticalSpacing
	return movingTop
end

function AJM:OnMessageAreasChanged( message )
	AJM.settingsControlWatcher.dropdownMessageArea:SetList( JambaApi.MessageAreaList() )
end

-------------------------------------------------------------------------------------------------------------
-- Watcher frame.
-------------------------------------------------------------------------------------------------------------

function AJM:CanDisplayQuestWatcher()
	-- Do not show is quest watcher disabled.
	if AJM.db.enableQuestWatcher == false then
		return false
	end
	-- Do not show if user has hidden frame.
	if AJM.db.showFrame == false then
		return false
	end
	-- Do not show if master only and not the master.
	if AJM.db.enableQuestWatcherOnMasterOnly == true then
		if JambaApi.IsCharacterTheMaster( AJM.characterName ) == false then
			return false
		end
	end
	-- Show if at least one line in the watch list.
	if AJM:CountLinesInQuestWatchList() > 0 then
		return true
	end
	-- Show if at least one auto quest popup.
	if AJM:HasAtLeastOneAutoQuestPopup() == true then
		return true
	end
	-- Nothing to show.
	return false
end

function AJM:CreateQuestWatcherFrame()
	-- The frame.
	local frame = CreateFrame( "Frame", "JambaQuestWatcherWindowFrame", UIParent )
	frame.obj = AJM
	frame:SetFrameStrata( "BACKGROUND" )
	frame:SetClampedToScreen( true )
	frame:EnableMouse( false )
	frame:SetMovable( true )	
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
			AJM.db.watcherFramePoint = point
			AJM.db.watcherFrameRelativePoint = relativePoint
			AJM.db.watcherFrameXOffset = xOffset
			AJM.db.watcherFrameYOffset = yOffset
		end	)	
	frame:ClearAllPoints()
	frame:SetPoint( AJM.db.watcherFramePoint, UIParent, AJM.db.watcherFrameRelativePoint, AJM.db.watcherFrameXOffset, AJM.db.watcherFrameYOffset )
	frame:SetBackdrop( {
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", 
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", 
		tile = true, tileSize = 10, edgeSize = 10, 
		insets = { left = 3, right = 3, top = 3, bottom = 3 }
	} )
	-- Create the title for the team list frame.
	local titleName = frame:CreateFontString( "JambaQuestWatcherWindowFrameTitleText", "OVERLAY", "GameFontNormal" )
    titleName:SetPoint( "TOPLEFT", frame, "TOPLEFT", 7, -7 )
    titleName:SetTextColor( 1.00, 1.00, 1.00 )
    titleName:SetText( L["Jamba Objective Tracker"] )
	frame.titleName = titleName
	-- Update button.
	local updateButton = CreateFrame( "Button", "JambaQuestWatcherWindowFrameButtonUpdate", frame, "UIPanelButtonGrayTemplate" )
	updateButton:SetScript( "OnClick", AJM.JambaQuestWatchListUpdateButtonClicked )
	updateButton:SetPoint( "TOPRIGHT", frame, "TOPRIGHT", -5, -4 )
	updateButton:SetHeight( 20 )
	updateButton:SetWidth( 100 )
	updateButton:SetText( L["Update"] )		
	-- Add an area for the "in the field quest" notifications.
	frame.fieldNotificationsTop = -24
	frame.fieldNotifications = CreateFrame( "Frame", "JambaQuestWatcherFieldQuestFrame", frame )
	frame.fieldNotifications:SetFrameStrata( "BACKGROUND" )
	frame.fieldNotifications:SetClampedToScreen( true )
	frame.fieldNotifications:EnableMouse( false )
	frame.fieldNotifications:ClearAllPoints()
	frame.fieldNotifications:SetPoint( "TOPLEFT", frame, "TOPLEFT", 0, frame.fieldNotificationsTop )
	frame.fieldNotifications:Show()
	-- Set transparency of the the frame (and all its children).
	frame:SetAlpha( AJM.db.watcherFrameAlpha )	
	-- List.
	local topOfList = frame.fieldNotificationsTop
	local list = {}
	list.listFrameName = "JambaQuestWatcherQuestListFrame"
	list.parentFrame = frame
	list.listTop = topOfList
	list.listLeft = 2
	list.listWidth = AJM.db.watcherFrameWidth
	list.rowHeight = 17
	list.rowsToDisplay = AJM.db.watcherListLines
	list.columnsToDisplay = 2
	list.columnInformation = {}	
	list.columnInformation[1] = {}
	list.columnInformation[1].width = 80
	list.columnInformation[1].alignment = "LEFT"
	list.columnInformation[2] = {}
	list.columnInformation[2].width = 20
	list.columnInformation[2].alignment = "CENTER"
	list.scrollRefreshCallback = AJM.QuestWatcherQuestListScrollRefresh
	list.rowClickCallback = AJM.QuestWatcherQuestListRowClick
	frame.questWatchList = list
	JambaHelperSettings:CreateScrollList( frame.questWatchList )
	-- Change appearance from default.
	frame.questWatchList.listFrame:SetBackdropColor( 0.0, 0.0, 0.0, 0.0 )
	frame.questWatchList.listFrame:SetBackdropBorderColor( 0.0, 0.0, 0.0, 0.0 )
	-- Disable mouse on columns so click-through works.
	for iterateDisplayRows = 1, frame.questWatchList.rowsToDisplay do
		for iterateDisplayColumns = 1, frame.questWatchList.columnsToDisplay do
			frame.questWatchList.rows[iterateDisplayRows].columns[iterateDisplayColumns]:EnableMouse( false )
		end
	end
	-- Position and size constants (once list height is known).
	frame.questWatchListBottom = topOfList - list.listHeight
	frame.questWatchListHeight = list.listHeight
	frame.questWatchHighlightRow = 1
	frame.questWatchListOffset = 1
	-- Set the global frame reference for this frame.
	JambaQuestWatcherFrame = frame
	JambaQuestWatcherFrame.autoQuestPopupsHeight = 0
	AJM:SettingsUpdateBorderStyle()	
	AJM:SettingsUpdateFontStyle()
	AJM.questWatcherFrameCreated = true
end


function AJM:SettingsUpdateBorderStyle()
	local borderStyle = AJM.SharedMedia:Fetch( "border", AJM.db.borderStyle )
	local backgroundStyle = AJM.SharedMedia:Fetch( "background", AJM.db.backgroundStyle )
	local frame = JambaQuestWatcherFrame
	frame:SetBackdrop( {
		bgFile = backgroundStyle, 
		edgeFile = borderStyle, 
		tile = true, tileSize = frame:GetWidth(), edgeSize = 10, 
		insets = { left = 3, right = 3, top = 3, bottom = 3 }
	} )
	frame:SetBackdropColor( AJM.db.watchFrameBackgroundColourR, AJM.db.watchFrameBackgroundColourG, AJM.db.watchFrameBackgroundColourB, AJM.db.watchFrameBackgroundColourA )
	frame:SetBackdropBorderColor( AJM.db.watchFrameBorderColourR, AJM.db.watchFrameBorderColourG, AJM.db.watchFrameBorderColourB, AJM.db.watchFrameBorderColourA )	
end

function AJM:SettingsUpdateFontStyle()
	local textFont = AJM.SharedMedia:Fetch( "font", AJM.db.watchFontStyle )
	local textSize = AJM.db.watchFontSize
	local frame = JambaQuestWatcherFrame
		frame.titleName:SetFont( textFont , textSize , "OUTLINE")
end	


function AJM:UpdateQuestWatcherDimensions()
	local frame = JambaQuestWatcherFrame
	frame:SetWidth( frame.questWatchList.listWidth + 4 )
	frame:SetHeight( frame.questWatchListHeight + 40 )
	-- Field notifications.
	frame.fieldNotifications:SetWidth( frame.questWatchList.listWidth + 4 )
	frame.fieldNotifications:SetHeight( JambaQuestWatcherFrame.autoQuestPopupsHeight )
	-- List.
	frame.questWatchList.listTop = frame.fieldNotificationsTop - JambaQuestWatcherFrame.autoQuestPopupsHeight
	frame.questWatchList.listFrame:SetPoint( "TOPLEFT", frame.questWatchList.parentFrame, "TOPLEFT", frame.questWatchList.listLeft, frame.questWatchList.listTop )
	-- Scale.
	frame:SetScale( AJM.db.watcherFrameScale )
end

function AJM:SetQuestWatcherVisibility()
	if AJM:CanDisplayQuestWatcher() == true then
		AJM:UpdateQuestWatcherDimensions()
		JambaQuestWatcherFrame:ClearAllPoints()
		JambaQuestWatcherFrame:SetPoint( AJM.db.watcherFramePoint, UIParent, AJM.db.watcherFrameRelativePoint, AJM.db.watcherFrameXOffset, AJM.db.watcherFrameYOffset )
		JambaQuestWatcherFrame:SetAlpha( AJM.db.watcherFrameAlpha )
		JambaQuestWatcherFrame:Show()
	else
		JambaQuestWatcherFrame:Hide()
	end	
end

-------------------------------------------------------------------------------------------------------------
-- Settings functionality.
-------------------------------------------------------------------------------------------------------------

-- Settings received.
function AJM:JambaOnSettingsReceived( characterName, settings )	
	if characterName ~= AJM.characterName then
		-- Update the settings.
		AJM.db.enableQuestWatcher = settings.enableQuestWatcher
		AJM.db.watcherFrameAlpha = settings.watcherFrameAlpha
		AJM.db.watcherFramePoint = settings.watcherFramePoint
		AJM.db.watcherFrameRelativePoint = settings.watcherFrameRelativePoint
		AJM.db.watcherFrameXOffset = settings.watcherFrameXOffset
		AJM.db.watcherFrameYOffset = settings.watcherFrameYOffset
		AJM.db.borderStyle = settings.borderStyle
		AJM.db.backgroundStyle = settings.backgroundStyle
		
		AJM.db.watchFontStyle = settings.watchFontStyle
		AJM.db.watchFontSize = settings.watchFontSize
		
		AJM.db.hideQuestWatcherInCombat = settings.hideQuestWatcherInCombat
		AJM.db.watcherFrameScale = settings.watcherFrameScale
		AJM.db.enableQuestWatcherOnMasterOnly = settings.enableQuestWatcherOnMasterOnly
		AJM.db.watchFrameBackgroundColourR = settings.watchFrameBackgroundColourR
		AJM.db.watchFrameBackgroundColourG = settings.watchFrameBackgroundColourG
		AJM.db.watchFrameBackgroundColourB = settings.watchFrameBackgroundColourB
		AJM.db.watchFrameBackgroundColourA = settings.watchFrameBackgroundColourA
		AJM.db.watchFrameBorderColourR = settings.watchFrameBorderColourR
		AJM.db.watchFrameBorderColourG = settings.watchFrameBorderColourG
		AJM.db.watchFrameBorderColourB = settings.watchFrameBorderColourB
		AJM.db.watchFrameBorderColourA = settings.watchFrameBorderColourA
		AJM.db.watcherListLines = settings.watcherListLines
		AJM.db.watcherFrameWidth = settings.watcherFrameWidth
		AJM.db.unlockWatcherFrame = settings.unlockWatcherFrame
		AJM.db.hideBlizzardWatchFrame = settings.hideBlizzardWatchFrame
		AJM.db.doNotHideCompletedObjectives = settings.doNotHideCompletedObjectives
		AJM.db.showCompletedObjectivesAsDone = settings.showCompletedObjectivesAsDone
		AJM.db.hideQuestIfAllComplete = settings.hideQuestIfAllComplete
--		AJM.db.showFrame = settings.showFrame
		AJM.db.sendProgressChatMessages = settings.sendProgressChatMessages
		AJM.db.messageArea = settings.messageArea
		-- Refresh the settings.
		AJM:SettingsRefresh()
		AJM:UpdateUnlockWatcherFrame()
		--AJM:UpdateHideBlizzardWatchFrame()
		AJM:ScheduleTimer( "UpdateHideBlizzardWatchFrame", 2 )
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
	-- Quest watcher options.
	AJM.settingsControlWatcher.checkBoxEnableQuestWatcher:SetValue( AJM.db.enableQuestWatcher )
	AJM.settingsControlWatcher.displayOptionsQuestWatcherMediaBorder:SetValue( AJM.db.borderStyle )
	AJM.settingsControlWatcher.displayOptionsQuestWatcherMediaBackground:SetValue( AJM.db.backgroundStyle )
	
	AJM.settingsControlWatcher.questWatchMediaFont:SetValue( AJM.db.watchFontStyle )
	AJM.settingsControlWatcher.questWatchFontSize:SetValue( AJM.db.watchFontSize )

	AJM.settingsControlWatcher.displayOptionsCheckBoxHideQuestWatcherInCombat:SetValue( AJM.db.hideQuestWatcherInCombat )
	AJM.settingsControlWatcher.displayOptionsQuestWatcherTransparencySlider:SetValue( AJM.db.watcherFrameAlpha )
	AJM.settingsControlWatcher.displayOptionsQuestWatcherScaleSlider:SetValue( AJM.db.watcherFrameScale )
	AJM.settingsControlWatcher.checkBoxEnableQuestWatcherMasterOnly:SetValue( AJM.db.enableQuestWatcherOnMasterOnly )
	AJM.settingsControlWatcher.questWatchBackgroundColourPicker:SetColor( AJM.db.watchFrameBackgroundColourR, AJM.db.watchFrameBackgroundColourG, AJM.db.watchFrameBackgroundColourB, AJM.db.watchFrameBackgroundColourA )
	AJM.settingsControlWatcher.questWatchBorderColourPicker:SetColor( AJM.db.watchFrameBorderColourR, AJM.db.watchFrameBorderColourG, AJM.db.watchFrameBorderColourB, AJM.db.watchFrameBorderColourA )
	AJM.settingsControlWatcher.displayOptionsQuestWatcherLinesSlider:SetValue( AJM.db.watcherListLines )
	AJM.settingsControlWatcher.displayOptionsQuestWatcherFrameWidthSlider:SetValue( AJM.db.watcherFrameWidth )
	AJM.settingsControlWatcher.checkBoxUnlockWatcherFrame:SetValue( AJM.db.unlockWatcherFrame )
	AJM.settingsControlWatcher.checkBoxHideBlizzardWatchFrame:SetValue( AJM.db.hideBlizzardWatchFrame )
	AJM.settingsControlWatcher.checkBoxShowCompletedObjectivesAsDone:SetValue( AJM.db.showCompletedObjectivesAsDone  )
	AJM.settingsControlWatcher.checkBoxShowDoNotHideCompletedObjectives:SetValue( AJM.db.doNotHideCompletedObjectives )
	AJM.settingsControlWatcher.checkBoxHideQuestIfAllComplete:SetValue( AJM.db.hideQuestIfAllComplete )
--	AJM.settingsControlWatcher.checkBoxShowFrame:SetValue( AJM.db.showFrame )
	AJM.settingsControlWatcher.dropdownMessageArea:SetValue( AJM.db.messageArea )
	AJM.settingsControlWatcher.checkBoxSendProgressChatMessages:SetValue( AJM.db.sendProgressChatMessages )
	-- Quest watcher state.
	AJM.settingsControlWatcher.displayOptionsQuestWatcherMediaBorder:SetDisabled( not AJM.db.enableQuestWatcher )
	AJM.settingsControlWatcher.displayOptionsQuestWatcherMediaBackground:SetDisabled( not AJM.db.enableQuestWatcher )
	AJM.settingsControlWatcher.questWatchMediaFont:SetDisabled( not AJM.db.enableQuestWatcher )
	AJM.settingsControlWatcher.questWatchFontSize:SetDisabled( not AJM.db.enableQuestWatcher )
	
	AJM.settingsControlWatcher.displayOptionsCheckBoxHideQuestWatcherInCombat:SetDisabled( not AJM.db.enableQuestWatcher )
	AJM.settingsControlWatcher.displayOptionsQuestWatcherTransparencySlider:SetDisabled( not AJM.db.enableQuestWatcher )
	AJM.settingsControlWatcher.displayOptionsQuestWatcherScaleSlider:SetDisabled( not AJM.db.enableQuestWatcher )
	AJM.settingsControlWatcher.checkBoxEnableQuestWatcherMasterOnly:SetDisabled( not AJM.db.enableQuestWatcher )
	AJM.settingsControlWatcher.questWatchBackgroundColourPicker:SetDisabled( not AJM.db.enableQuestWatcher )
	AJM.settingsControlWatcher.questWatchBorderColourPicker:SetDisabled( not AJM.db.enableQuestWatcher )
	AJM.settingsControlWatcher.displayOptionsQuestWatcherLinesSlider:SetDisabled( not AJM.db.enableQuestWatcher )
	AJM.settingsControlWatcher.displayOptionsQuestWatcherFrameWidthSlider:SetDisabled( not AJM.db.enableQuestWatcher )
	AJM.settingsControlWatcher.checkBoxUnlockWatcherFrame:SetDisabled( not AJM.db.enableQuestWatcher )
	AJM.settingsControlWatcher.checkBoxHideBlizzardWatchFrame:SetDisabled( not AJM.db.enableQuestWatcher )
	AJM.settingsControlWatcher.checkBoxShowCompletedObjectivesAsDone:SetDisabled( not AJM.db.enableQuestWatcher )
	AJM.settingsControlWatcher.checkBoxShowDoNotHideCompletedObjectives:SetDisabled( not AJM.db.enableQuestWatcher )
	AJM.settingsControlWatcher.checkBoxHideQuestIfAllComplete:SetDisabled( not AJM.db.enableQuestWatcher )
--	AJM.settingsControlWatcher.checkBoxShowFrame:SetDisabled( not AJM.db.enableQuestWatcher )
	AJM.settingsControlWatcher.dropdownMessageArea:SetDisabled( not AJM.db.enableQuestWatcher )
	AJM.settingsControlWatcher.checkBoxSendProgressChatMessages:SetDisabled( not AJM.db.enableQuestWatcher )
	if AJM.questWatcherFrameCreated == true then
		AJM:SettingsUpdateBorderStyle()
		AJM:SettingsUpdateFontStyle()
		AJM:SetQuestWatcherVisibility()	
	end
end

function AJM:SettingsPushSettingsClick( event )
	AJM:JambaSendSettings()
end

function AJM:SettingsToggleEnableQuestWatcher( event, checked )
	AJM.db.enableQuestWatcher = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsChangeBorderStyle( event, value )
	AJM.db.borderStyle = value
	AJM:SettingsRefresh()
end

function AJM:SettingsChangeBackgroundStyle( event, value )
	AJM.db.backgroundStyle = value
	AJM:SettingsRefresh()
end

function AJM:SettingsChangeFontStyle( event, value )
	AJM.db.watchFontStyle = value
	AJM:SettingsRefresh()
	AJM:JambaQuestWatcherUpdate( false )
end

function AJM:SettingsChangeFontSize( event, value )
	AJM.db.watchFontSize = value
	AJM:SettingsRefresh()
	AJM:JambaQuestWatcherUpdate( false )
end

function AJM:SettingsToggleHideQuestWatcherInCombat( event, checked )
	AJM.db.hideQuestWatcherInCombat = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsChangeTransparency( event, value )
	AJM.db.watcherFrameAlpha = tonumber( value )
	AJM:SettingsRefresh()
end

function AJM:SettingsChangeScale( event, value )
	AJM.db.watcherFrameScale = tonumber( value )
	AJM:SettingsRefresh()
end

function AJM:SettingsChangeWatchLines( event, value )
	AJM.db.watcherListLines = tonumber( value )
	AJM:SettingsRefresh()
end

function AJM:SettingsChangeWatchFrameWidth( event, value )
	AJM.db.watcherFrameWidth = tonumber( value )
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleEnableQuestWatcherMasterOnly( event, checked )
	AJM.db.enableQuestWatcherOnMasterOnly = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsQuestWatchBackgroundColourPickerChanged( event, r, g, b, a )
	AJM.db.watchFrameBackgroundColourR = r
	AJM.db.watchFrameBackgroundColourG = g
	AJM.db.watchFrameBackgroundColourB = b
	AJM.db.watchFrameBackgroundColourA = a
	AJM:SettingsRefresh()
end

function AJM:SettingsQuestWatchBorderColourPickerChanged( event, r, g, b, a )
	AJM.db.watchFrameBorderColourR = r
	AJM.db.watchFrameBorderColourG = g
	AJM.db.watchFrameBorderColourB = b
	AJM.db.watchFrameBorderColourA = a
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleUnlockWatcherFrame( event, checked )
	AJM.db.unlockWatcherFrame = checked
	AJM:UpdateUnlockWatcherFrame()
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleSendProgressChatMessages( event, checked )
	AJM.db.sendProgressChatMessages = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleShowFrame( event, checked )
	AJM.db.showFrame = checked
	AJM:SettingsRefresh()
end

function AJM:ShowFrameCommand( info, parameters )
	AJM.db.showFrame = true
	AJM:SettingsRefresh()
end

function AJM:HideFrameCommand( info, parameters )
	AJM.db.showFrame = false
	AJM:SettingsRefresh()
end

function AJM:SettingsSetMessageArea( event, messageAreaValue )
	AJM.db.messageArea = messageAreaValue
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleHideBlizzardWatchFrame( event, checked )
	AJM.db.hideBlizzardWatchFrame = checked
	--AJM:UpdateHideBlizzardWatchFrame()
	AJM:ScheduleTimer( "UpdateHideBlizzardWatchFrame", 2 )
	AJM:SettingsRefresh()
end

function AJM:SettingsShowCompletedObjectivesAsDone( event, checked )
	AJM.db.showCompletedObjectivesAsDone = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsHideQuestIfAllComplete( event, checked )
	AJM.db.hideQuestIfAllComplete = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsDoNotHideCompletedObjectives( event, checked )
	AJM.db.doNotHideCompletedObjectives = checked
	AJM:SettingsRefresh()
end

function AJM:UpdateUnlockWatcherFrame()
	if AJM.db.enableQuestWatcher == false then
		return
	end
	if AJM.db.unlockWatcherFrame == true then
		JambaQuestWatcherFrame:EnableMouse( true )
	else
		JambaQuestWatcherFrame:EnableMouse( false )
	end
end

function AJM:UpdateHideBlizzardWatchFrame()
	if AJM.db.enableQuestWatcher == false then
		return
	end
	if AJM.db.hideBlizzardWatchFrame == true then
		if ObjectiveTrackerFrame:IsVisible() then
            ObjectiveTrackerFrame:Hide()
		end
	else
        ObjectiveTrackerFrame:Show()
	end
end

-------------------------------------------------------------------------------------------------------------
-- QUEST WATCHING HOOKS
-------------------------------------------------------------------------------------------------------------

function AJM:SelectActiveQuest( questIndex )
    AJM:DebugMessage("select active quest", questIndex)
	if AJM.db.enableQuestWatcher == false then
		return
	end
	AJM:SetActiveQuestForQuestWatcherCache( questIndex )
end

function AJM:GetQuestReward( itemChoice )
	if AJM.db.enableQuestWatcher == false then
		return
    end
	local questJustCompletedName = GetTitleText()
    AJM:DebugMessage( "GetQuestReward: ", questIndex, questJustCompletedName )
    local questIndex = AJM:GetQuestLogIndexByName( questJustCompletedName )
    local title, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID, startEvent, displayQuestID, isOnMap, hasLocalPOI, isTask, isStory = GetQuestLogTitle( questIndex )
    AJM:DebugMessage( "GetQuestReward after GetQuestLogTitle: ", questIndex, questJustCompletedName, questID )
	AJM:RemoveQuestFromWatchList( questID )
end

function AJM:AddQuestWatch( questIndex )
	if AJM.db.enableQuestWatcher == false then
		return
	end
	--AJM:UpdateHideBlizzardWatchFrame()
	AJM:ScheduleTimer( "UpdateHideBlizzardWatchFrame", 2 )
	AJM:JambaQuestWatcherUpdate( true )
	AJM:JambaQuestWatcherScenarioUpdate( true )
end

function AJM:RemoveQuestWatch( questIndex )
	if AJM.db.enableQuestWatcher == false then
		return
    end
    AJM:DebugMessage( "RemoveQuestWatch", questIndex )
	--AJM:UpdateHideBlizzardWatchFrame()
    AJM:ScheduleTimer( "UpdateHideBlizzardWatchFrame", 2 )
	local title, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID, startEvent, displayQuestID, isOnMap, hasLocalPOI, isTask, isStory = GetQuestLogTitle( questIndex )
    AJM:DebugMessage( "About to call RemoveQuestFromWatchList with value:", questID )
	AJM:RemoveQuestFromWatchList( questID )
end

function AJM:SetAbandonQuest()
	if AJM.db.enableQuestWatcher == false then
		return
	end
	local questName = GetAbandonQuestName()
	if questName ~= nil then
		local questIndex = AJM:GetQuestLogIndexByName( questName )
		AJM:SetActiveQuestForQuestWatcherCache( questIndex )
	end
end

function AJM:AbandonQuest()
	if AJM.db.enableQuestWatcher == false then
		return
	end
	-- Wait a bit for the correct information to come through from the server...
	AJM:ScheduleTimer( "AbandonQuestDelayed", 1 )		
end


function AJM:QUEST_WATCH_UPDATE( event, ... )
	--AJM:Print("test4")
	if AJM.db.enableQuestWatcher == true then
		-- Wait a bit for the correct information to come through from the server...
		AJM:ScheduleTimer( "JambaQuestWatcherUpdate", 1, true )		
	end
end


function AJM:QUEST_LOG_UPDATE( event, ... )
	--AJM:Print("test")
	if AJM.db.enableQuestWatcher == true then
		-- Wait a bit for the correct information to come through from the server...
		AJM:ScheduleTimer( "JambaQuestWatcherUpdate", 1, true )		
	end
end


function AJM:SCENARIO_UPDATE( event, ... )
	--AJM:Print("test2")
	if AJM.db.enableQuestWatcher == true then
		--AJM:JambaQuestWatchListUpdateButtonClicked()
		AJM:RemoveQuestsNotBeingWatched()
		AJM:ScheduleTimer( "JambaQuestWatcherScenarioUpdate", 1, true )
	end
end


function AJM:SCENARIO_CRITERIA_UPDATE( event, ... )
	--AJM:Print("test3")
	if AJM.db.enableQuestWatcher == true then
		-- Wait a bit for the correct information to come through from the server...
		--AJM:ScheduleTimer( "JambaQuestWatcherUpdate", 1, false )
		AJM:ScheduleTimer( "JambaQuestWatcherScenarioUpdate", 1, true )	
	end
end

function AJM:PLAYER_ENTERING_WORLD( event, ... )
	--AJM:Print("test4")
	if AJM.db.enableQuestWatcher == true then
		AJM:RemoveQuestsNotBeingWatched()
		AJM:ScheduleTimer( "JambaQuestWatcherScenarioUpdate", 1, false )
		AJM:ScheduleTimer( "JambaQuestWatcherUpdate", 1, false )
		--AJM:JambaQuestWatchListUpdateButtonClicked()
	end
end


function AJM:PLAYER_REGEN_ENABLED( event, ... )
	if AJM.db.enableQuestWatcher == false then
		return
	end
	if AJM.db.hideQuestWatcherInCombat == true then
		AJM:SetQuestWatcherVisibility()
	end
end

function AJM:PLAYER_REGEN_DISABLED( event, ... )
	if AJM.db.enableQuestWatcher == false then
		return
	end
	if AJM.db.hideQuestWatcherInCombat == true then
		JambaQuestWatcherFrame:Hide()
	end
end

-------------------------------------------------------------------------------------------------------------
-- QUEST WATCHING
-------------------------------------------------------------------------------------------------------------

function AJM:AbandonQuestDelayed()
	AJM:RemoveCurrentQuestFromWatcherCache()
	AJM:RemoveQuestsNotBeingWatched()
end

function AJM:JambaQuestWatchListUpdateButtonClicked()
	AJM:RemoveQuestsNotBeingWatched()
	AJM:JambaSendCommandToTeam( AJM.COMMAND_UPDATE_QUEST_WATCHER_LIST )
end

function AJM:DoQuestWatchListUpdate( characterName )
	AJM:JambaQuestWatcherUpdate( false )
	AJM:JambaQuestWatcherScenarioUpdate( false )
end


function AJM:GetQuestObjectiveCompletion( text )
	if text == nil then
		return L["N/A"], L["N/A"]
	end
	local arg1, arg2 = string.match(text, "(.-%S)%s(.*)")
	if arg1 and arg2 then
		return arg1, arg2
	else
		return L["N/A"], text
	end
end

function AJM:QuestWatchGetObjectiveText( questIndex, objectiveIndex )
	local objectiveFullText, objectiveType, objectiveFinished = GetQuestLogLeaderBoard( objectiveIndex, questIndex )
	local amountCompleted, objectiveText = AJM:GetQuestObjectiveCompletion( objectiveFullText )
	return objectiveText 
end




-------------------------------------------------------------------------------------------------------------
-- QUEST WATCH CACHE
-------------------------------------------------------------------------------------------------------------

function AJM:IsQuestObjectiveInCache( questID, objectiveIndex )
	local key = questID..objectiveIndex
	if AJM.questWatchCache[key] == nil then
		return false
	end
	return true
end

function AJM:AddQuestObjectiveToCache( questID, objectiveIndex, amountCompleted, objectiveFinished )
	local key = questID..objectiveIndex
	AJM.questWatchCache[key] = {}
	AJM.questWatchCache[key].questID = questID
	AJM.questWatchCache[key].amountCompleted = amountCompleted
	AJM.questWatchCache[key].objectiveFinished = objectiveFinished
end

function AJM:GetQuestCachedValues( questID, objectiveIndex )
	local key = questID..objectiveIndex
	return AJM.questWatchCache[key].amountCompleted, AJM.questWatchCache[key].objectiveFinished
end

function AJM:UpdateQuestCachedValues( questID, objectiveIndex, amountCompleted, objectiveFinished )
	local key = questID..objectiveIndex
	AJM.questWatchCache[key].amountCompleted = amountCompleted
	AJM.questWatchCache[key].objectiveFinished = objectiveFinished
end

function AJM:QuestCacheUpdate( questID, objectiveIndex, amountCompleted, objectiveFinished )
	if AJM:IsQuestObjectiveInCache( questID, objectiveIndex ) == false then
		AJM:AddQuestObjectiveToCache( questID, objectiveIndex, amountCompleted, objectiveFinished )
		return true
	end
	local cachedAmountCompleted, cachedObjectiveFinished = AJM:GetQuestCachedValues( questID, objectiveIndex )
	if cachedAmountCompleted == amountCompleted and cachedObjectiveFinished == objectiveFinished then
		return false
	end
	AJM:UpdateQuestCachedValues( questID, objectiveIndex, amountCompleted, objectiveFinished )
	return true
end

function AJM:SetActiveQuestForQuestWatcherCache( questIndex )
	if AJM.db.enableQuestWatcher == false then
		return
	end
	if questIndex ~= nil then
        local title, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID, startEvent, displayQuestID, isOnMap, hasLocalPOI, isTask, isStory = GetQuestLogTitle( questIndex )
		AJM.currentQuestForQuestWatcherID = questID
	else
		AJM.currentQuestForQuestWatcherID = nil
	end
end

function AJM:RemoveQuestFromWatcherCache( questID )
    AJM:DebugMessage( "RemoveQuestFromWatcherCache", questID )
	for key, questInfo in pairs( AJM.questWatchCache ) do
		if questInfo.questID == questID then
			AJM.questWatchCache[key].questID = nil
			AJM.questWatchCache[key].amountCompleted = nil
			AJM.questWatchCache[key].objectiveFinished = nil
			AJM.questWatchCache[key] = nil
			AJM:JambaSendCommandToTeam( AJM.COMMAND_QUEST_WATCH_REMOVE_QUEST, questID )
		end
	end
end

function AJM:RemoveCurrentQuestFromWatcherCache()
	if AJM.db.enableQuestWatcher == false then
		return
    end
    AJM:DebugMessage( "RemoveCurrentQuestFromWatcherCache", AJM.currentQuestForQuestWatcherID )
	if AJM.currentQuestForQuestWatcherID == nil then
		return
	end
	AJM:RemoveQuestFromWatcherCache( AJM.currentQuestForQuestWatcherID )
end

-------------------------------------------------------------------------------------------------------------
-- AUTO QUEST COMMUNICATION
-------------------------------------------------------------------------------------------------------------

function AJM:IsCompletedAutoCompleteFieldQuest( questIndex, isComplete )
	-- Send an isComplete true flag if the quest is completed and is an in the field autocomplete quest.
	if isComplete and isComplete > 0 then
		if GetQuestLogIsAutoComplete( questIndex ) then
			isComplete = true
		else
			isComplete = false
		end
	else
		isComplete = false
	end
	return isComplete
end

function AJM:QUEST_AUTOCOMPLETE( event, questID, ... )
	-- In the field autocomplete quest event.
	if AJM.db.enableQuestWatcher == false then
		return
	end
	AJM:JambaSendCommandToTeam( AJM.COMMAND_AUTO_QUEST_COMPLETE, questID )
end

function AJM:DoAutoQuestFieldComplete( characterName, questID )
	AJM:JambaAddAutoQuestPopUp( questID, "COMPLETE", characterName )
end

function AJM:QUEST_COMPLETE()
	if AJM.db.enableQuestWatcher == false then
		return
    end
	AJM:JambaSendCommandToTeam( AJM.COMMAND_REMOVE_AUTO_QUEST_COMPLETE, questID )
end

function AJM:DoRemoveAutoQuestFieldComplete( characterName, questID )
	AJM:JambaRemoveAutoQuestPopUp( questID, characterName )
end

function AJM:QUEST_DETAIL()
	if AJM.db.enableQuestWatcher == false then
		return
	end
	if QuestGetAutoAccept() and QuestIsFromAreaTrigger() then
		AJM:JambaSendCommandToTeam( AJM.COMMAND_AUTO_QUEST_OFFER, GetQuestID() )
	end
end		

function AJM:DoAutoQuestFieldOffer( characterName, questID )
	AJM:JambaAddAutoQuestPopUp( questID, "OFFER", characterName )
end

-------------------------------------------------------------------------------------------------------------
-- QUEST WATCH COMMUNICATION
-------------------------------------------------------------------------------------------------------------
--Ebony test
function AJM:JambaQuestWatcherScenarioUpdate( useCache )
	if AJM.db.enableQuestWatcher == false then
		return
	end
	-- Scenario information
	local isInScenario = C_Scenario.IsInScenario()
	if isInScenario == true then
		--local useCache = false
		local scenarioName, currentStage, numStages, flags, _, _, _, xp, money = C_Scenario.GetInfo()
		--AJM:Print("scenario", scenarioName, currentStage, numStages)
			for StagesIndex = 1, currentStage do
				--AJM:Print("Player is on Stage", currentStage)
				local stageName, stageDescription, numCriteria, _, _, _, numSpells, spellInfo, weightedProgress = C_Scenario.GetStepInfo()
				--AJM:Print("test match", numCriteria)
				if numCriteria == 0 then
					--AJM:Print("test match 0")
					if (weightedProgress) then
						--AJM:Print("Checking Progress", weightedProgress)
						local questID = 1001	
						local criteriaIndex = 0
						local maxProgress = 100
						--Placeholder does not work on borkenshore questlines......
						--local totalQuantity = 100
						local completed = false
						local amountCompleted = tostring(weightedProgress).."/"..(maxProgress)
						local name = "Scenario:"..stageName.." "..currentStage.."/"..numStages
						--AJM:Print("scenarioProgressInfo", questID, name, criteriaIndex, stageDescription , amountCompleted , totalQuantity, completed )
							--if (AJM:QuestCacheUpdate( questID, criteriaIndex, amountCompleted, objectiveFinished ) == true) or (useCache == false) then
								AJM:JambaSendCommandToTeam( AJM.COMMAND_QUEST_WATCH_OBJECTIVE_UPDATE, questID, name, numCriteria, stageDescription , amountCompleted , totalQuantity, completed )
							--end
					else
						--AJM:Print("ScenarioDONE", stageDescription)
						local questID = 1001
						local criteriaIndex = 1
						local completed = false
						local amountCompleted = tostring(0).."/"..(1)
						local name = "Scenario:"..stageName.." "..currentStage.."/"..numStages
						--AJM:Print("scenarioProgressInfo", questID, name, criteriaIndex, stageDescription , amountCompleted , totalQuantity, completed )
						if (AJM:QuestCacheUpdate( questID, criteriaIndex, amountCompleted, objectiveFinished ) == true) or (useCache == false) then
							AJM:JambaSendCommandToTeam( AJM.COMMAND_QUEST_WATCH_OBJECTIVE_UPDATE, questID, name, numCriteria, stageDescription , amountCompleted , totalQuantity, completed )
						end
					end
					
				else
				for criteriaIndex = 1, numCriteria do
		--AJM:Print("Player has", numCriteria, "Criterias", "and is checking", criteriaIndex)
				local criteriaString, criteriaType, completed, quantity, totalQuantity, flags, assetID, quantityString, criteriaID, duration, elapsed = C_Scenario.GetCriteriaInfo(criteriaIndex)
		--AJM:Print("test", criteriaString, criteriaType, completed, quantity, totalQuantity )
				--Ebony to fix a bug with character trial quest (this might be a blizzard bug) TODO relook at somepoint in beta.
					if (criteriaString) then
						local questID = 1001
						local amountCompleted = tostring( quantity ).."/"..( totalQuantity ) 
						--AJM:Print("Stages", numStages)
						local name = nil
							if (numStages) > 1 then
								local textName = "Scenario:"..stageName.." "..currentStage.."/"..numStages
								newName = textName
							else
								local textName = "Scenario:"..stageName
								newName = textName
							end
							local name = newName
							if (AJM:QuestCacheUpdate( questID, criteriaIndex, amountCompleted, objectiveFinished ) == true) or (useCache == false) then
							--AJM:Print("test", questID, name, criteriaIndex, criteriaString , amountCompleted , completed, completed)
							AJM:JambaSendCommandToTeam( AJM.COMMAND_QUEST_WATCH_OBJECTIVE_UPDATE, questID, name, criteriaIndex, criteriaString , amountCompleted , completed, completed )						if AJM.db.sendProgressChatMessages == true then
							--	if AJM.db.sendProgressChatMessages == true then
							--	AJM:JambaSendMessageToTeam( AJM.db.messageArea, objectiveText.." "..amountCompleted, false )
							--	end
							end							
						end
					end	
				end
			end
		end
	-- SCENARIO_BONUS
		local tblBonusSteps = C_Scenario.GetBonusSteps()
		if #tblBonusSteps > 0 then
	--AJM:Print("BonusTest", #tblBonusSteps )
			for i = 1, #tblBonusSteps do
					local bonusStepIndex = tblBonusSteps[i]
	--AJM:Print("bonusIndex", bonusStepIndex)
					local stageName, stageDescription, numCriteria = C_Scenario.GetStepInfo(bonusStepIndex)
	--AJM:Print("bonusInfo", numCriteria, stageName, stageDescription) 
				for criteriaIndex = 1, numCriteria do
					--AJM:Print("Player has", numCriteria, "Criterias", "and is checking", criteriaIndex)
					local criteriaString, criteriaType, completed, quantity, totalQuantity, flags, assetID, quantityString, criteriaID = C_Scenario.GetCriteriaInfoByStep(bonusStepIndex, criteriaIndex)
					local questID = assetID
					local amountCompleted = tostring(quantity).."/"..(totalQuantity)
					local name = "ScenarioBouns:"..stageName --.." "..currentStage.."/"..numStages
	--AJM:Print("scenarioBouns", questID, name, criteriaIndexa, criteriaString , amountCompleted , totalQuantity, completed )
					if (AJM:QuestCacheUpdate( questID, criteriaIndex, amountCompleted, objectiveFinished ) == true) or (useCache == false) then
						AJM:JambaSendCommandToTeam( AJM.COMMAND_QUEST_WATCH_OBJECTIVE_UPDATE, questID, name, criteriaIndex, criteriaString , amountCompleted , completed, completed )
						--if AJM.db.sendProgressChatMessages == true then
						--	AJM:JambaSendMessageToTeam( AJM.db.messageArea, objectiveText.." "..amountCompleted, false )
						--end							
					end
				end
			end
		end
	end
end


function AJM:JambaQuestWatcherUpdate( useCache )
	if AJM.db.enableQuestWatcher == false then
		return
	end
	AJM:DebugMessage( "Sending quest watch information...")
	-- old wow quests system
		for iterateWatchedQuests = 1, GetNumQuestWatches() do
		--for iterateQuests = 1, GetNumQuestLogEntries() do
			local questIndex = GetQuestIndexForWatch( iterateWatchedQuests )
			AJM:DebugMessage( "GetQuestIndexForWatch: questIndex: ", questIndex )
			if questIndex ~= nil then
				local title, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID, startEvent, displayQuestID, isOnMap, hasLocalPOI, isTask, isStory = GetQuestLogTitle( questIndex )			
				isComplete = AJM:IsCompletedAutoCompleteFieldQuest( questIndex, isComplete )
				local numObjectives = GetNumQuestLeaderBoards( questIndex )
				AJM:DebugMessage( "NumObjs:", numObjectives )
				for iterateObjectives = 1, numObjectives do
					local objectiveFullText, objectiveType, objectiveFinished = GetQuestLogLeaderBoard( iterateObjectives, questIndex )
					AJM:DebugMessage( "ObjInfo:", objectiveFullText, objectiveType, objectiveFinished, iterateObjectives, questIndex  )
					local amountCompleted, objectiveText = AJM:GetQuestObjectiveCompletion( objectiveFullText )
					AJM:DebugMessage( "SplitObjInfo",  amountCompleted, objectiveText )
					if (AJM:QuestCacheUpdate( questID, iterateObjectives, amountCompleted, objectiveFinished ) == true) or (useCache == false) then
						--AJM:Print( "UPDATE:", questID, title, iterateObjectives, objectiveText, amountCompleted, objectiveFinished, isComplete )				
						AJM:JambaSendCommandToTeam( AJM.COMMAND_QUEST_WATCH_OBJECTIVE_UPDATE, questID, title, iterateObjectives, objectiveText, amountCompleted, objectiveFinished, isComplete )
						if AJM.db.sendProgressChatMessages == true then
							AJM:JambaSendMessageToTeam( AJM.db.messageArea, objectiveText.." "..amountCompleted, false )
						end					
					end
				end
			end
		end
		-- New Bouns Quests!
	for iterateWatchedQuests = 1, GetNumQuestLogEntries() do
		local title, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID, startEvent, displayQuestID, isOnMap, hasLocalPOI, isTask, isStory = GetQuestLogTitle( iterateWatchedQuests )
		--AJM:DebugMessage( "EbonyTest101:", questID)
		local isInArea, isOnMap, numObjectives = GetTaskInfo(questID);
		if isInArea and isOnMap then
				isComplete = AJM:IsCompletedAutoCompleteFieldQuest( questIndex, isComplete )
				--AJM:Print( "EbonyTestbounsquestID:", questID, numObjectives, isComplete )
			for iterateObjectives = 1, numObjectives do
			local objectiveFullText, objectiveType, finished = GetQuestObjectiveInfo( questID, iterateObjectives, isComplete )
				--AJM:Print("BonuesQuest", objectiveFullText, objectiveType, finished )
				-- if progressbar quest that is not a quest where you kill XYZ and many things can make you do the complete the quest.
				if objectiveType == "progressbar"  then
					--AJM:Print("hello123", )
					local objectiveText = "ProgressBar"
					local progress = GetQuestProgressBarPercent( questID )
					local maxProgress = 100
					local amountCompleted = tostring(progress).."/"..(maxProgress)
					--AJM:Print("BarQuesttext", amountCompleted )
					if (AJM:QuestCacheUpdate( questID, iterateObjectives, amountCompleted, objectiveFinished ) == true) or (useCache == false) then
					--AJM:Print("QuestPercent", title, objectiveText, amountCompleted )
					local name = tostring("Bonus:")..(title)
						--send command to team
						--AJM:Print("BarQuest", questID, title, iterateObjectives, objectiveText, amountCompleted, objectiveFinished, isComplete)						AJM:JambaSendCommandToTeam( AJM.COMMAND_QUEST_WATCH_OBJECTIVE_UPDATE, questID, name, iterateObjectives, objectiveText, amountCompleted, objectiveFinished, isComplete )
						AJM:JambaSendCommandToTeam( AJM.COMMAND_QUEST_WATCH_OBJECTIVE_UPDATE, questID, name, iterateObjectives, objectiveText, amountCompleted, objectiveFinished, isComplete )
						if AJM.db.sendProgressChatMessages == true then
							AJM:JambaSendMessageToTeam( AJM.db.messageArea, objectiveText.." "..amountCompleted, false )
						end
					end					
				-- for other bouns quests EG one time world pop up quests that don't have a npc. 
				else
				local amountCompleted, objectiveText = AJM:GetQuestObjectiveCompletion( objectiveFullText )
					if (AJM:QuestCacheUpdate( questID, iterateObjectives, amountCompleted, objectiveFinished ) == true) or (useCache == false) then
					--AJM:Print("BonusQuest", amountCompleted, objectiveText )
					--AJM:Print( "UPDATE:", "cache:", useCache, "QuestID", questID, "ObjectID", iterateObjectives )
					--AJM:Print("sendingquestdata", objectiveText, amountCompleted, finished )
					local name = gsub(title, "[^|]+:", "Bonus:")
					-- send command to team
					AJM:JambaSendCommandToTeam( AJM.COMMAND_QUEST_WATCH_OBJECTIVE_UPDATE, questID, name, iterateObjectives, objectiveText, amountCompleted, objectiveFinished, isComplete )
						if AJM.db.sendProgressChatMessages == true then
							AJM:JambaSendMessageToTeam( AJM.db.messageArea, objectiveText.." "..amountCompleted, false )
						end	
					end
				end
			end
		end
	end		
end

-- Gathers messages from team.
function AJM:DoQuestWatchObjectiveUpdate( characterName, questID, questName, objectiveIndex, objectiveText, amountCompleted, objectiveFinished, isComplete )
	AJM:UpdateQuestWatchList( questID, questName, objectiveIndex, objectiveText, characterName, amountCompleted, objectiveFinished, isComplete )
end

function AJM:UpdateQuestWatchList( questID, questName, objectiveIndex, objectiveText, characterName, amountCompleted, objectiveFinished, isComplete )
    --local characterName = (( Ambiguate( name, "none" ) ))
	AJM:DebugMessage( "UpdateQuestWatchList", questID, questName, objectiveIndex, objectiveText, characterName, amountCompleted, objectiveFinished, isComplete )
	local questHeaderPosition = AJM:GetQuestHeaderInWatchList( questID, questName, characterName )
	local objectiveHeaderPosition = AJM:GetObjectiveHeaderInWatchList( questID, questName, objectiveIndex, objectiveText, "", questHeaderPosition )
	local characterPosition = AJM:GetCharacterInWatchList( questID, objectiveIndex, characterName, amountCompleted, objectiveHeaderPosition, objectiveFinished )	
	local totalAmountCompleted = AJM:GetTotalCharacterAmountFromWatchList( questID, objectiveIndex )
	--AJM:Print("QuestPosition", objectiveHeaderPosition, questHeaderPosition )
	objectiveHeaderPosition = AJM:GetObjectiveHeaderInWatchList( questID, questName, objectiveIndex, objectiveText, totalAmountCompleted, questHeaderPosition )
	-- isComplete piggybacks on the quest watch update, so we are always displaying a complete quest button (in case the QUEST_AUTOCOMPLETE event does not fire).
	if isComplete == true then
		AJM:DoAutoQuestFieldComplete( characterName, questID )
	end
	if AJM.db.hideQuestIfAllComplete == true then
		AJM:CheckQuestForAllObjectivesCompleteAndHide( questID )
	end	
	AJM:QuestWatcherQuestListScrollRefresh()
	AJM:SetQuestWatcherVisibility()
end

-------------------------------------------------------------------------------------------------------------

function AJM:RemoveQuestFromWatchList( questID )
	AJM:RemoveQuestFromWatcherCache( questID )
	AJM:JambaSendCommandToTeam( AJM.COMMAND_QUEST_WATCH_REMOVE_QUEST, questID )
end

function AJM:DoRemoveQuestFromWatchList( characterName, questID )
	-- Remove character lines for this character.
	for key, questWatchInfoContainer in pairs( AJM.questWatchObjectivesList ) do
		local questWatchInfo = questWatchInfoContainer.info
		if questWatchInfo.questID == questID and questWatchInfo.character == characterName then
			AJM:RemoveQuestWatchInfo( questWatchInfo.key )	
		end
	end
	-- See if any character lines left, if none, then remove quest completely.
	local found = false
	for key, questWatchInfoContainer in pairs( AJM.questWatchObjectivesList ) do
		local questWatchInfo = questWatchInfoContainer.info
		if questWatchInfo.questID == questID and questWatchInfo.type == "CHARACTER_AMOUNT" then
			found = true
		end
	end
	if found == false then
		for key, questWatchInfoContainer in pairs( AJM.questWatchObjectivesList ) do
			local questWatchInfo = questWatchInfoContainer.info
			if questWatchInfo.questID == questID then
				AJM:RemoveQuestWatchInfo( questWatchInfo.key )	
			end
		end
	else
		-- Still some character lines left, update the total amount of objectives to reflect lost team member.
		-- Find any remaining quest objective headers.
		for key, questWatchInfoContainer in pairs( AJM.questWatchObjectivesList ) do
			local questWatchInfo = questWatchInfoContainer.info
			if questWatchInfo.questID == questID and questWatchInfo.type == "OBJECTIVE_HEADER" then
				questWatchInfo.amount = AJM:GetTotalCharacterAmountFromWatchList( questID, questWatchInfo.objectiveIndex )
				-- If all done auto-collapse when complete, collapse objective header.
				if (questWatchInfo.amount == L["DONE"]) and (AJM.db.doNotHideCompletedObjectives == true) then
					questWatchInfo.childrenAreHidden = true
				end
			end
			if questWatchInfo.questID == questID and questWatchInfo.type == "QUEST_HEADER" then
				AJM:UpdateTeamQuestCountRemoveCharacter( questWatchInfo, characterName )
				if AJM.db.hideQuestIfAllComplete == true then
					AJM:CheckQuestForAllObjectivesCompleteAndHide( questID )
				end
			end
		end
	end
	-- Remove any auto quest buttons.
	AJM:DoRemoveAutoQuestFieldComplete( characterName, questID )
	AJM:QuestWatcherQuestListScrollRefresh()
	AJM:SetQuestWatcherVisibility()
end

-------------------------------------------------------------------------------------------------------------
-- QUEST WATCH DISPLAY LIST LOGIC
-------------------------------------------------------------------------------------------------------------

--Ebony working here
function AJM:GetTotalCharacterAmountFromWatchList( questID, objectiveIndex )
	local amount = 0
	local total = 0
	local countCharacters = 0
	local countDones = 0
	for key, questWatchInfoContainer in pairs( AJM.questWatchObjectivesList ) do
		local questWatchInfo = questWatchInfoContainer.info
		local position = questWatchInfoContainer.position
		if questWatchInfo.questID == questID and questWatchInfo.type == "CHARACTER_AMOUNT" and questWatchInfo.objectiveIndex == objectiveIndex then
			countCharacters = countCharacters + 1
			local amountCompletedText = questWatchInfo.amount
			if amountCompletedText == L["DONE"] then
				countDones = countDones + 1
			end
			local arg1, arg2 = string.match(amountCompletedText, "(%d*)/(%d*)")
            AJM:DebugMessage( amountCompletedText, arg1, arg2 )
			if (arg1 ~= nil) and (arg2 ~= nil) then
				if strtrim( arg1 ) ~= "" and strtrim( arg2 ) ~= "" then
					amount = amount + tonumber( arg1 )
					total = total + tonumber( arg2 )
				end
			end
		end
	end
	if countCharacters == 0 then
		return L["DONE"]
	end
	local amountOverTotal = string.format( "%s/%s", amount, total )
    AJM:DebugMessage( "AMTOT:", amountOverTotal )
	if amountOverTotal == "0/0" then
		if countDones == countCharacters then
			amountOverTotal = L["DONE"]
		else
			amountOverTotal = "N/A" 
		end
	end
	return amountOverTotal
end

function AJM:RemoveQuestsNotBeingWatched()
	AJM:UpdateAllQuestsInWatchList()
	for checkQuestID, value in pairs( AJM.questWatchListOfQuests ) do
		local found = false
		for iterateWatchedQuests = 1, GetNumQuestWatches() do
			local questIndex = GetQuestIndexForWatch( iterateWatchedQuests )
			if questIndex ~= nil then
                local title, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID, startEvent, displayQuestID, isOnMap, hasLocalPOI, isTask, isStory = GetQuestLogTitle( questIndex )
				if checkQuestID == questID then
					found = true
				end
			end
		end
		if found == false then
			AJM:RemoveQuestFromWatchList( checkQuestID )
		end
	end
end

function AJM:UpdateAllQuestsInWatchList()
	table.wipe( AJM.questWatchListOfQuests )
	for key, questWatchInfoContainer in pairs( AJM.questWatchObjectivesList ) do
		-- TODO- whats going on here?
		AJM.questWatchListOfQuests[questWatchInfoContainer.info.questID] = true
	end
end

function AJM:GetCharacterInWatchList( questID, objectiveIndex, characterName, amountCompleted, objectiveHeaderPosition, objectiveFinished )
	local characterPosition = -1
	local characterQuestWatchInfo
	if objectiveFinished then
		if AJM.db.showCompletedObjectivesAsDone == true then
			amountCompleted = L["DONE"]
		end
	end
	-- Try and find the character line.	
	for key, questWatchInfoContainer in pairs( AJM.questWatchObjectivesList ) do
		local questWatchInfo = questWatchInfoContainer.info
		local position = questWatchInfoContainer.position
		if questWatchInfo.questID == questID and questWatchInfo.type == "CHARACTER_AMOUNT" and questWatchInfo.objectiveIndex == objectiveIndex and questWatchInfo.character == characterName then
			-- Character line found.  Update information.
			questWatchInfo.amount = amountCompleted
			characterQuestWatchInfo = questWatchInfo
			characterPosition = position
			break
		end
	end
	-- Was not found, add character line.
	if characterPosition == -1 then
		-- Only if not completed or user wants to show completed.
		if ((objectiveFinished == nil) or (objectiveFinished == false)) or (AJM.db.doNotHideCompletedObjectives == true) then	
			local questWatchInfo = AJM:CreateQuestWatchInfo( questID, "CHARACTER_AMOUNT", objectiveIndex, characterName, characterName, amountCompleted )
			AJM:InsertQuestWatchInfoToListAfterPosition( questWatchInfo, objectiveHeaderPosition )
			return objectiveHeaderPosition + 1
		end
		return -1
	else
		-- Character line was found.  Remove it if objective finished?
		if (objectiveFinished) and (AJM.db.doNotHideCompletedObjectives == false) then
			AJM:RemoveQuestWatchInfo( characterQuestWatchInfo.key )
			return -1
		end			
	end
	return -1
end

function AJM:GetObjectiveHeaderInWatchList( questID, questName, objectiveIndex, objectiveText, totalAmountCompleted, questHeaderPosition )
	--AJM:Print("testposition", questName, "oT", objectiveText, questHeaderPosition)
	if strtrim( objectiveText ) == "" then
		objectiveText = questName
	end
	for key, questWatchInfoContainer in pairs( AJM.questWatchObjectivesList ) do
		local questWatchInfo = questWatchInfoContainer.info
		local position = questWatchInfoContainer.position
		if questWatchInfo.questID == questID and questWatchInfo.type == "OBJECTIVE_HEADER" and questWatchInfo.objectiveIndex == objectiveIndex then
			questWatchInfo.information = objectiveText
			questWatchInfo.amount = totalAmountCompleted
			-- If all done auto-collapse when complete, collapse objective header.
			if (questWatchInfo.amount == L["DONE"]) and (AJM.db.doNotHideCompletedObjectives == true) then
				questWatchInfo.childrenAreHidden = true
			end
			return position
		end
	end
	local questWatchInfo = AJM:CreateQuestWatchInfo( questID, "OBJECTIVE_HEADER", objectiveIndex, "", objectiveText, totalAmountCompleted )
	-- Hide the team list by default.
	questWatchInfo.childrenAreHidden = true
	AJM:InsertQuestWatchInfoToListAfterPosition( questWatchInfo, questHeaderPosition )
	return questHeaderPosition + 1	
end

function AJM:GetQuestHeaderInWatchList( questID, questName, characterName )
	for key, questWatchInfoContainer in pairs( AJM.questWatchObjectivesList ) do
		local questWatchInfo = questWatchInfoContainer.info
		local position = questWatchInfoContainer.position
		if questWatchInfo.questID == questID and questWatchInfo.type == "QUEST_HEADER" then
			AJM:UpdateTeamQuestCountAddCharacter( questWatchInfo, characterName )
			
			if AJM.db.hideQuestIfAllComplete == true then
				AJM:CheckQuestForAllObjectivesCompleteAndHide( questID )
			end
			return position
		end
	end
	local iconTexture = ("Interface\\ICONS\\INV_Misc_Map07")
	local icon = strconcat(" |T"..iconTexture..":18|t")
	local questWatchInfo = AJM:CreateQuestWatchInfo( questID, "QUEST_HEADER", -1, "", questName, icon ) --L["<Map>"] )
	AJM:UpdateTeamQuestCountAddCharacter( questWatchInfo, characterName )
	if AJM.db.hideQuestIfAllComplete == true then
		AJM:CheckQuestForAllObjectivesCompleteAndHide( questID )
	end	
	local newPositionAtEnd = AJM:GetQuestWatchMaximumOrder() + 1
	AJM:AddQuestWatchInfoToListAtPosition( questWatchInfo, newPositionAtEnd )
	return newPositionAtEnd
end

function AJM:UpdateTeamQuestCount( questWatchInfo, characterName )
	local count = 0
	for character, dummy in pairs( questWatchInfo.teamCharacters ) do
		count = count + 1
	end
	questWatchInfo.questTeamCount = count
end

function AJM:UpdateTeamQuestCountAddCharacter( questWatchInfo, name )

	questWatchInfo.teamCharacters[name] = true
	AJM:UpdateTeamQuestCount( questWatchInfo, name )
end

function AJM:UpdateTeamQuestCountRemoveCharacter( questWatchInfo, characterName )
	questWatchInfo.teamCharacters[characterName] = nil
	AJM:UpdateTeamQuestCount( questWatchInfo, characterName )
end

function AJM:CheckQuestForAllObjectivesCompleteAndHide( questID )
	if AJM.db.hideQuestIfAllComplete == false then
		return
	end
	-- If all objective headers for quest say "DONE" then hide quest if hideQuestIfAllComplete option set.
	local allDone = true
	for key, questWatchInfoContainer in pairs( AJM.questWatchObjectivesList ) do
		local questWatchInfo = questWatchInfoContainer.info
		if questWatchInfo.questID == questID and questWatchInfo.type == "OBJECTIVE_HEADER" then	
			if questWatchInfo.amount ~= L["DONE"] then
				allDone = false
			end
		end
	end	
	-- Set quest header hidden or not as appropriate.
	for key, questWatchInfoContainer in pairs( AJM.questWatchObjectivesList ) do
		local questWatchInfo = questWatchInfoContainer.info
		if questWatchInfo.questID == questID and questWatchInfo.type == "QUEST_HEADER" then
			questWatchInfo.childrenAreHidden = allDone
		end
	end	
end

-------------------------------------------------------------------------------------------------------------
-- QUEST WATCH INFO FUNCTIONS
-------------------------------------------------------------------------------------------------------------

function AJM:CreateQuestWatchInfo( questID, type, objectiveIndex, character, information, amount )
	local questWatchInfo = {}
	questWatchInfo.key = questID..type..objectiveIndex..character
	questWatchInfo.questID = questID
	questWatchInfo.type = type
	questWatchInfo.objectiveIndex = objectiveIndex
	questWatchInfo.character = character
	questWatchInfo.information = information
	questWatchInfo.amount = amount
	questWatchInfo.childrenAreHidden = false
	questWatchInfo.questTeamCount = 0
	questWatchInfo.teamCharacters = {}
	return questWatchInfo 
end

function AJM:AddQuestWatchInfoToListAtPosition( questWatchInfo, position )
	AJM.questWatchObjectivesList[questWatchInfo.key] = {}
	AJM.questWatchObjectivesList[questWatchInfo.key].position = position
	AJM.questWatchObjectivesList[questWatchInfo.key].info = questWatchInfo
end

function AJM:InsertQuestWatchInfoToListAfterPosition( questWatchInfo, position )
	for key, questWatchInfoContainer in pairs( AJM.questWatchObjectivesList ) do
		local questWatchInfo = questWatchInfoContainer.info
		local checkPosition = questWatchInfoContainer.position
		if checkPosition > position then
			questWatchInfoContainer.position = checkPosition + 1
		end
	end
	AJM:AddQuestWatchInfoToListAtPosition( questWatchInfo, position + 1 )
end

function AJM:RemoveQuestWatchInfo( key )
	local removedPosition = AJM.questWatchObjectivesList[key].position
	for checkKey, questWatchInfoContainer in pairs( AJM.questWatchObjectivesList ) do
		local checkPosition = questWatchInfoContainer.position
		if checkPosition > removedPosition then
			questWatchInfoContainer.position = checkPosition - 1
		end
	end
	AJM.questWatchObjectivesList[key].info.key = nil
	AJM.questWatchObjectivesList[key].info.questID = nil
	AJM.questWatchObjectivesList[key].info.type = nil
	AJM.questWatchObjectivesList[key].info.objectiveIndex = nil
	AJM.questWatchObjectivesList[key].info.character = nil
	AJM.questWatchObjectivesList[key].info.information = nil
	AJM.questWatchObjectivesList[key].info.amount = nil
	AJM.questWatchObjectivesList[key].info.childrenAreHidden = nil
	AJM.questWatchObjectivesList[key].info.questTeamCount = nil
	table.wipe( AJM.questWatchObjectivesList[key].info.teamCharacters )
	table.wipe( AJM.questWatchObjectivesList[key].info )
	AJM.questWatchObjectivesList[key].info = nil
	AJM.questWatchObjectivesList[key].position = nil
	table.wipe( AJM.questWatchObjectivesList[key] )
	AJM.questWatchObjectivesList[key] = nil
end

-- Get the largest order number from the quest watch list.
function AJM:GetQuestWatchMaximumOrder()
	local largestPosition = 0
	for key, questWatchInfoContainer in pairs( AJM.questWatchObjectivesList ) do
		local questWatchInfo = questWatchInfoContainer.info
		local position = questWatchInfoContainer.position	
		if position > largestPosition then
			largestPosition = position
		end
	end
	return largestPosition
end

function AJM:GetQuestWatchInfoFromKey( key )
	local questWatchInfo = AJM.questWatchObjectivesList[key].info
	return questWatchInfo.information, questWatchInfo.amount, questWatchInfo.type, questWatchInfo.questID, questWatchInfo.childrenAreHidden, key			
end

-- Get the quest watch info at a specific position.
function AJM:GetQuestWatchInfoAtOrderPosition( position )
	local information = ""
	local amount = ""
	local type = ""
	local questID = ""
	local childrenAreHidden = ""
	local key = ""
	local questTeamCount = ""
	local objectiveIndex = ""
	for keyStored, questWatchInfoContainer in pairs( AJM.questWatchObjectivesList ) do
		local questWatchInfo = questWatchInfoContainer.info
		local questWatchPosition = questWatchInfoContainer.position		
		if questWatchPosition == position then
			information = questWatchInfo.information
			amount = questWatchInfo.amount
			type = questWatchInfo.type
			questID = questWatchInfo.questID
			childrenAreHidden = questWatchInfo.childrenAreHidden
			key = keyStored
			questTeamCount = questWatchInfo.questTeamCount
			objectiveIndex = questWatchInfo.objectiveIndex
			break
		end
	end
	return information, amount, type, questID, childrenAreHidden, key, questTeamCount, objectiveIndex
end

function AJM:ToggleChildrenAreHiddenQuestWatchInfoByKey( key )
	local questWatchInfo = AJM.questWatchObjectivesList[key].info
	questWatchInfo.childrenAreHidden = not questWatchInfo.childrenAreHidden
end

function AJM:CountLinesInQuestWatchList()
	if AJM.questWatchObjectivesList == nil then
		return 1
	end
	local count = 1
	for key, questWatchInfoContainer in pairs( AJM.questWatchObjectivesList ) do
		count = count + 1
	end
	return count
end

-------------------------------------------------------------------------------------------------------------
-- QUEST WATCH DISPLAY LIST MECHANICS
-------------------------------------------------------------------------------------------------------------

function AJM:QuestWatcherQuestListDrawLine( frame, iterateDisplayRows, type, information, amount, childrenAreHidden, key, questTeamCount )
	local toggleDisplay = ""
	local padding = ""
	local teamCount = ""
	local textFont = AJM.SharedMedia:Fetch( "font", AJM.db.watchFontStyle )
	local textSize = AJM.db.watchFontSize
	if type == "CHARACTER_AMOUNT" then
		padding = "        "
	end
	if type == "OBJECTIVE_HEADER" then
		padding = "    "
		if childrenAreHidden == true then
			toggleDisplay = "+ "
		else
			toggleDisplay = "- "
		end
	end
	if type == "QUEST_HEADER" then
		if questTeamCount ~= 0 then
			--teamCount = " ("..questTeamCount.."/"..JambaApi.GetTeamListMaximumOrder()..") "
			--Ebony Only Show online character info
			teamCount = " ("..questTeamCount.."/"..JambaApi.GetTeamListMaximumOrderOnline()..") "			
		end
	end
	local matchDataScenario = string.find( information, "Scenario:" )
	local matchDataScenarioBouns = string.find( information, "ScenarioBouns:" )
	-- Scenario
	if matchDataScenario then
		local name = gsub(information, "[^|]+:", "")
		frame.questWatchList.rows[iterateDisplayRows].columns[1].textString:SetText( padding..toggleDisplay..name )
		frame.questWatchList.rows[iterateDisplayRows].columns[2].textString:SetText( amount )
		frame.questWatchList.rows[iterateDisplayRows].columns[1].textString:SetFont( textFont , textSize , "OUTLINE")
		frame.questWatchList.rows[iterateDisplayRows].columns[2].textString:SetFont( textFont , textSize , "OUTLINE")
		
		-- Turn off the mouse for these buttons.
		frame.questWatchList.rows[iterateDisplayRows].columns[1]:EnableMouse( false )
		frame.questWatchList.rows[iterateDisplayRows].columns[2]:EnableMouse( false )
	-- Scenario Bouns
	elseif matchDataScenarioBouns then
		local name = gsub(information, "[^|]+:", "")
		frame.questWatchList.rows[iterateDisplayRows].columns[1].textString:SetText( padding..toggleDisplay..name )
		frame.questWatchList.rows[iterateDisplayRows].columns[2].textString:SetText( amount )
		frame.questWatchList.rows[iterateDisplayRows].columns[1].textString:SetFont( textFont , textSize , "OUTLINE")
		frame.questWatchList.rows[iterateDisplayRows].columns[2].textString:SetFont( textFont , textSize , "OUTLINE")
		-- Turn off the mouse for these buttons.
		frame.questWatchList.rows[iterateDisplayRows].columns[1]:EnableMouse( false )
		frame.questWatchList.rows[iterateDisplayRows].columns[2]:EnableMouse( false )
	else
		frame.questWatchList.rows[iterateDisplayRows].columns[1].textString:SetText( padding..toggleDisplay..teamCount..information )
		frame.questWatchList.rows[iterateDisplayRows].columns[2].textString:SetText( amount )
		frame.questWatchList.rows[iterateDisplayRows].columns[1].textString:SetFont( textFont , textSize , "OUTLINE")
		frame.questWatchList.rows[iterateDisplayRows].columns[2].textString:SetFont( textFont , textSize , "OUTLINE")
		-- Turn off the mouse for these buttons.
		frame.questWatchList.rows[iterateDisplayRows].columns[1]:EnableMouse( false )
		frame.questWatchList.rows[iterateDisplayRows].columns[2]:EnableMouse( false )
	end
	--AJM:Print("test2343", type, information )
	if type == "QUEST_HEADER" then
		local matchData = string.find( information, "Bonus:" )
		local matchDataScenario = string.find( information, "Scenario:" )
		local matchDataScenarioBouns = string.find( information, "ScenarioBouns:" )
		if matchData then 
		-- 	Bonus Quests
			--AJM:Print("Match", information)
			frame.questWatchList.rows[iterateDisplayRows].columns[1].textString:SetTextColor( 1.0, 0, 0, 1.0 )
			frame.questWatchList.rows[iterateDisplayRows].columns[2].textString:SetTextColor( 1.0, 0, 0, 1.0 )
			-- Turn on the mouse for these buttons.
			frame.questWatchList.rows[iterateDisplayRows].columns[1]:EnableMouse( true )
			frame.questWatchList.rows[iterateDisplayRows].columns[2]:EnableMouse( true )
		-- Scenario Text
			
			--AJM:Print("Match", information)
			elseif matchDataScenario then
			
			frame.questWatchList.rows[iterateDisplayRows].columns[1].textString:SetTextColor( 1.0, 0, 1.0, 1.0 )
			frame.questWatchList.rows[iterateDisplayRows].columns[2].textString:SetTextColor( 1.0, 0, 1.0, 1.0 )
			-- Turn on the mouse for these buttons.
			frame.questWatchList.rows[iterateDisplayRows].columns[1]:EnableMouse( true )
			frame.questWatchList.rows[iterateDisplayRows].columns[2]:EnableMouse( true )		
			--frame.questWatchList.rowHeight = 60
			
			elseif matchDataScenarioBouns then
			
			frame.questWatchList.rows[iterateDisplayRows].columns[1].textString:SetTextColor( 0, 0.30, 1.0, 1.0 )
			frame.questWatchList.rows[iterateDisplayRows].columns[2].textString:SetTextColor( 0, 0.30, 1.0, 1.0 )
			-- Turn on the mouse for these buttons.
			frame.questWatchList.rows[iterateDisplayRows].columns[1]:EnableMouse( true )
			frame.questWatchList.rows[iterateDisplayRows].columns[2]:EnableMouse( true )
			
			else
			frame.questWatchList.rows[iterateDisplayRows].columns[1].textString:SetTextColor( 1.0, 0.96, 0.41, 1.0 )
			frame.questWatchList.rows[iterateDisplayRows].columns[2].textString:SetTextColor( 1.0, 0.96, 0.41, 1.0 )		
			-- Turn on the mouse for these buttons.
			frame.questWatchList.rows[iterateDisplayRows].columns[1]:EnableMouse( true )
			frame.questWatchList.rows[iterateDisplayRows].columns[2]:EnableMouse( true )
		end
	end
	if type == "OBJECTIVE_HEADER" then
		--AJM:Print("Match", information)
		local matchData = string.find( information, "ProgressBar" )
			if matchData then
			--AJM:Print("Match", information)
			frame.questWatchList.rows[iterateDisplayRows].columns[1].textString:SetTextColor( 1.0, 0.50, 0.50, 1.0 )
			frame.questWatchList.rows[iterateDisplayRows].columns[2].textString:SetTextColor( 1.0, 0.50, 0.50, 1.0 )
			-- Turn on the mouse for these buttons.
			frame.questWatchList.rows[iterateDisplayRows].columns[1]:EnableMouse( true )		
			else
			frame.questWatchList.rows[iterateDisplayRows].columns[1].textString:SetTextColor( NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1.0 )
			frame.questWatchList.rows[iterateDisplayRows].columns[2].textString:SetTextColor( NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1.0 )
			-- Turn on the mouse for these buttons.
			frame.questWatchList.rows[iterateDisplayRows].columns[1]:EnableMouse( true )
		end
	end
	frame.questWatchList.rows[iterateDisplayRows].key = key
end

function AJM:QuestWatcherQuestListScrollRefresh()
	local frame = JambaQuestWatcherFrame
	FauxScrollFrame_Update(
		frame.questWatchList.listScrollFrame, 
		AJM:GetQuestWatchMaximumOrder(),
		frame.questWatchList.rowsToDisplay, 
		frame.questWatchList.rowHeight
	)
	frame.questWatchListOffset = FauxScrollFrame_GetOffset( frame.questWatchList.listScrollFrame )
	frame.dataRowOffset = 0
	local atLeastOneRowShowing = false
	for iterateDisplayRows = 1, frame.questWatchList.rowsToDisplay do
		-- Reset.
		frame.questWatchList.rows[iterateDisplayRows].key = ""
		frame.questWatchList.rows[iterateDisplayRows].columns[1].textString:SetText( "" )
		frame.questWatchList.rows[iterateDisplayRows].columns[2].textString:SetText( "" )
		frame.questWatchList.rows[iterateDisplayRows].columns[1].textString:SetTextColor( 1.0, 1.0, 1.0, 1.0 )
		frame.questWatchList.rows[iterateDisplayRows].columns[2].textString:SetTextColor( 1.0, 1.0, 1.0, 1.0 )
		frame.questWatchList.rows[iterateDisplayRows].highlight:SetTexture( 0.0, 0.0, 0.0, 0.0 )
		-- Get data.
		local dataRowNumber = iterateDisplayRows + frame.questWatchListOffset + frame.dataRowOffset
		local foundDataRow = false
		local finishedRows = false
		while (foundDataRow == false) and (finishedRows == false) do
			dataRowNumber = iterateDisplayRows + frame.questWatchListOffset + frame.dataRowOffset
			if dataRowNumber > AJM:GetQuestWatchMaximumOrder() then
				finishedRows = true
			else		
				local information, amount, type, questID, childrenAreHidden, key, questTeamCount, objectiveIndex = AJM:GetQuestWatchInfoAtOrderPosition( dataRowNumber )
				foundDataRow = true
				if type == "QUEST_HEADER" then
					-- In this case, children are hidden refers to itself as well.
					if childrenAreHidden == true then
						foundDataRow = false
						frame.dataRowOffset = frame.dataRowOffset + 1
					end
				end
				if type == "OBJECTIVE_HEADER" then
					local hideMe = false
					for key, questWatchInfoContainer in pairs( AJM.questWatchObjectivesList ) do
						local questWatchInfo = questWatchInfoContainer.info
						if questWatchInfo.questID == questID and questWatchInfo.type == "QUEST_HEADER" then
							hideMe = questWatchInfo.childrenAreHidden
							break
						end
					end
					if hideMe == true then
						foundDataRow = false
						frame.dataRowOffset = frame.dataRowOffset + 1
					end				
				end
				-- If this is a character_amount type, find its parent objective header and see if its children are hidden.
				if type == "CHARACTER_AMOUNT" then
					local hideMe = false
					for key, questWatchInfoContainer in pairs( AJM.questWatchObjectivesList ) do
						local questWatchInfo = questWatchInfoContainer.info
						if questWatchInfo.questID == questID and questWatchInfo.type == "OBJECTIVE_HEADER" and questWatchInfo.objectiveIndex ==  objectiveIndex then
							hideMe = questWatchInfo.childrenAreHidden
							break
						end
					end
					if hideMe == true then
						foundDataRow = false
						frame.dataRowOffset = frame.dataRowOffset + 1
					end
				end
			end
		end
		if finishedRows == false and foundDataRow == true then
			-- Put information and amount into columns.
			local information, amount, type, questID, childrenAreHidden, key, questTeamCount, objectiveIndex = AJM:GetQuestWatchInfoAtOrderPosition( dataRowNumber )
			AJM:QuestWatcherQuestListDrawLine( frame, iterateDisplayRows, type, information, amount, childrenAreHidden, key, questTeamCount )
			atLeastOneRowShowing = true
		end
	end
	-- Adjust the scroll frame based on hidden rows.
	if atLeastOneRowShowing == true then
		FauxScrollFrame_Update(
			frame.questWatchList.listScrollFrame, 
			AJM:GetQuestWatchMaximumOrder() - frame.dataRowOffset,
			frame.questWatchList.rowsToDisplay, 
			frame.questWatchList.rowHeight
		)
	end
	AJM:DisplayAutoQuestPopUps()
end

function AJM:QuestWatcherQuestListRowClick( rowNumber, columnNumber )
    AJM:DebugMessage( "QuestWatcherQuestListRowClick", rowNumber, columnNumber )
	local frame = JambaQuestWatcherFrame
	local key = frame.questWatchList.rows[rowNumber].key
	if key ~= nil and key ~= "" then
		local information, amount, type, questID, childrenAreHidden, keyStored = AJM:GetQuestWatchInfoFromKey( key )
        AJM:DebugMessage( "GetQuestWatchInfoFromKey", information, amount, type, questID, childrenAreHidden, keyStored, key )
		if type == "QUEST_HEADER" then
            if columnNumber == 2 then
                QuestMapFrame_OpenToQuestDetails( questID )
            end
            if columnNumber == 1 then
			    local questIndex = AJM:GetQuestLogIndexByName( information )
                AJM:DebugMessage( "Open Quest:", questIndex, information )
			    if questIndex ~= 0 then
                    QuestLogPopupDetailFrame_Show( questIndex )
				end
			end
		end
		if type == "OBJECTIVE_HEADER" then
			if columnNumber == 1 then
				AJM:ToggleChildrenAreHiddenQuestWatchInfoByKey( key )
				AJM:QuestWatcherQuestListScrollRefresh()
			end
		end
	end
end

-------------------------------------------------------------------------------------------------------------
-- QUEST WATCH AUTO QUEST DISPLAY - MOSTLY BORROWED FROM BLIZZARD CODE
-------------------------------------------------------------------------------------------------------------

function AJM:HasAtLeastOneAutoQuestPopup()
	if #AJM.currentAutoQuestPopups == 0 then
		return false
	end
	return true
end

function AJM:JambaAddAutoQuestPopUp( questID, popUpType, characterName )
	if AJM.currentAutoQuestPopups[questID] == nil then
		AJM.currentAutoQuestPopups[questID] = {}	
	end
	AJM.currentAutoQuestPopups[questID][characterName] = popUpType
end

function AJM:JambaRemoveAutoQuestPopUp( questID, characterName )
	if AJM.currentAutoQuestPopups[questID] == nil then
		return
	end
	AJM.currentAutoQuestPopups[questID][characterName] = nil
	if #AJM.currentAutoQuestPopups[questID] == 0 then
		table.wipe( AJM.currentAutoQuestPopups[questID] )
		AJM.currentAutoQuestPopups[questID] = nil
	end
end

function AJM:JambaRemoveAllAutoQuestPopUps( questID )
	if AJM.currentAutoQuestPopups[questID] == nil then
		return
	end
	table.wipe( AJM.currentAutoQuestPopups[questID] )
	AJM.currentAutoQuestPopups[questID] = nil
end

function AJM:AutoQuestGetOrCreateFrame( parent, index )
	if _G["JambaWatchFrameAutoQuestPopUp"..index] then
		return _G["JambaWatchFrameAutoQuestPopUp"..index]
	end
	local frame = CreateFrame( "SCROLLFRAME", "JambaWatchFrameAutoQuestPopUp"..index, parent )
	frame.index = index
    frame:EnableMouse( true )
    local QuestName = frame:CreateFontString( "JambaWatchFrameAutoQuestPopUpQuestName"..index, "OVERLAY", "GameFontNormal" )
    QuestName:SetPoint( "TOP", frame, "TOP", 0, -12 )
    QuestName:SetTextColor( 1.00, 1.00, 1.00 )
    QuestName:SetText( "" )
    frame.QuestName = QuestName
    local TopText = frame:CreateFontString( "JambaWatchFrameAutoQuestPopUpTopText"..index, "OVERLAY", "GameFontNormal" )
    TopText:SetPoint( "TOP", frame, "TOP", 0, -24 )
    TopText:SetTextColor( 1.00, 1.00, 1.00 )
    TopText:SetText( "" )
    frame.TopText = TopText
    local BottomText = frame:CreateFontString( "JambaWatchFrameAutoQuestPopUpBottomText"..index, "OVERLAY", "GameFontNormal" )
    BottomText:SetPoint( "TOP", frame, "TOP", 0, -36 )
    BottomText:SetTextColor( 1.00, 1.00, 1.00 )
    BottomText:SetText( "BottomText" )
    frame.BottomText = BottomText
	AJM.countAutoQuestPopUpFrames = AJM.countAutoQuestPopUpFrames + 1
	return frame
end

function AJM:DisplayAutoQuestPopUps()
	local nextAnchor
	local countPopUps = 0
	local iterateQuestPopups = 01
	JambaQuestWatcherFrame.autoQuestPopupsHeight = 0
	local parentFrame = JambaQuestWatcherFrame.fieldNotifications
	for questID, characterInfo in pairs( AJM.currentAutoQuestPopups ) do
		local characterName, characterPopUpType, popUpType
		local characterList = ""
		for characterName, characterPopUpType in pairs( characterInfo ) do
			--characterList = characterList..characterName.." "
			characterList = characterList..( Ambiguate( characterName, "none" ) ).." "
			-- TODO - hack, assuming all characters have the same sort of popup.
			popUpType = characterPopUpType
		end
        local title, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID, startEvent, displayQuestID, isOnMap, hasLocalPOI, isTask, isStory = GetQuestLogTitle( GetQuestLogIndexByID( questID ) )
		if isComplete and isComplete > 0 then
			isComplete = true
		else
			isComplete = false
		end
		-- If the current character does not have the quest, show the character names that do have it.
		local clickToViewText = QUEST_WATCH_POPUP_CLICK_TO_VIEW
		if not (title and title ~= "") then
            title = characterList
			clickToViewText = ""
		end
		local frame = AJM:AutoQuestGetOrCreateFrame( parentFrame, countPopUps + 1 )
		frame:Show()
		frame:ClearAllPoints()
		frame:SetParent( parentFrame )
		if isComplete == true and popUpType == "COMPLETE" then
			frame.TopText:SetText( QUEST_WATCH_POPUP_CLICK_TO_COMPLETE )
			frame.BottomText:Hide()
            frame:SetHeight( 32 )
			frame.type = "COMPLETED"
            frame:HookScript( "OnMouseUp", function()
                ShowQuestComplete( GetQuestLogIndexByID( questID ) )
                AJM:JambaRemoveAllAutoQuestPopUps( questID )
                AJM:DisplayAutoQuestPopUps()
                AJM:SettingsUpdateBorderStyle()
				AJM:SettingsUpdateFontStyle()
            end )
		elseif popUpType == "OFFER" then
			frame.TopText:SetText( QUEST_WATCH_POPUP_QUEST_DISCOVERED )
			frame.BottomText:Show()
			frame.BottomText:SetText( clickToViewText )
            frame:SetHeight( 48 )
			frame.type = "OFFER"
			frame:HookScript( "OnMouseUp", function()
				AJM:JambaRemoveAllAutoQuestPopUps( questID )
				AJM:DisplayAutoQuestPopUps()
				AJM:SettingsUpdateBorderStyle()
				AJM:SettingsUpdateFontStyle()
			end )
		end
		frame:ClearAllPoints()
		if nextAnchor ~= nil then
			if iterateQuestPopups == 1 then
				frame:SetPoint( "TOP", nextAnchor, "BOTTOM", 0, 0 ) -- -WATCHFRAME_TYPE_OFFSET
			else
				frame:SetPoint( "TOP", nextAnchor, "BOTTOM", 0, 0 )
			end
		else
			frame:SetPoint( "TOP", parentFrame, "TOP", 0, 5 ) -- -WATCHFRAME_INITIAL_OFFSET
		end
		frame:SetPoint( "LEFT", parentFrame, "LEFT", -20, 0 )
		frame.QuestName:SetText( title )
		frame.questId = questID
		--frame:UpdateScrollChildRect()
		--frame:SetVerticalScroll( floor( -9 + 0.5 ) )
		nextAnchor = frame
		countPopUps = countPopUps + 1
		JambaQuestWatcherFrame.autoQuestPopupsHeight = JambaQuestWatcherFrame.autoQuestPopupsHeight + frame:GetHeight()
	end
	for iterateQuestPopups = countPopUps + 1, AJM.countAutoQuestPopUpFrames do
		_G["JambaWatchFrameAutoQuestPopUp"..iterateQuestPopups].questId = nil
		_G["JambaWatchFrameAutoQuestPopUp"..iterateQuestPopups]:Hide()
	end
	AJM:UpdateQuestWatcherDimensions()
end

-------------------------------------------------------------------------------------------------------------
-- QUEST WATCH HELPERS
-------------------------------------------------------------------------------------------------------------

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

function AJM:GetQuestLogIndexByID( inQuestID )
	for iterateQuests = 1, GetNumQuestLogEntries() do
        local title, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID, startEvent, displayQuestID, isOnMap, hasLocalPOI, isTask, isStory = GetQuestLogTitle( iterateQuests )
		if not isHeader then
			if questID == inQuestID then
				return iterateQuests
			end
		end
	end
	return 0
end

-------------------------------------------------------------------------------------------------------------
-- COMMAND MANAGEMENT
-------------------------------------------------------------------------------------------------------------

-- A Jamba command has been recieved.
function AJM:JambaOnCommandReceived( characterName, commandName, ... )
	--if characterName ~= AJM.characterName then
		if commandName == AJM.COMMAND_QUEST_WATCH_OBJECTIVE_UPDATE then
			AJM:DoQuestWatchObjectiveUpdate( characterName, ... )
		end
		if commandName == AJM.COMMAND_UPDATE_QUEST_WATCHER_LIST then
			AJM:DoQuestWatchListUpdate( characterName, ... )
		end
		if commandName == AJM.COMMAND_QUEST_WATCH_REMOVE_QUEST then
			AJM:DoRemoveQuestFromWatchList( characterName, ... )
		end
		if commandName == AJM.COMMAND_AUTO_QUEST_COMPLETE then
			AJM:DoAutoQuestFieldComplete( characterName, ... )
		end
		if commandName == AJM.COMMAND_REMOVE_AUTO_QUEST_COMPLETE then
			AJM:DoRemoveAutoQuestFieldComplete( characterName, ... )
		end
		if commandName == AJM.COMMAND_AUTO_QUEST_OFFER then
			AJM:DoAutoQuestFieldOffer( characterName, ... )
		end
	--end	
end


JambaApi.ClearAllQuests = ClearAllQuests