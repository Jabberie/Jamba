--[[
Jamba - Jafula's Awesome Multi-Boxer Assistant
Copyright 2008 - 2018 Michael "Jafula" Miller
License: The MIT License



]]--

-- Create the addon using AceAddon-3.0 and embed some libraries.
local AJM = LibStub( "AceAddon-3.0" ):NewAddon( 
	"JambaTag",
	"JambaModule-1.0", 
	"AceConsole-3.0", 
	"AceEvent-3.0",
	"AceHook-3.0"
)

-- Load libraries.
local JambaUtilities = LibStub:GetLibrary( "JambaUtilities-1.0" )
local JambaHelperSettings = LibStub:GetLibrary( "JambaHelperSettings-1.0" )
local AceGUI = LibStub( "AceGUI-3.0" )

-- Constants required by JambaModule and Locale for this module.
AJM.moduleName = "Jamba-Tag"
AJM.settingsDatabaseName = "JambaTagProfileDB"
AJM.chatCommand = "jamba-tag"
local L = LibStub( "AceLocale-3.0" ):GetLocale( AJM.moduleName )
AJM.parentDisplayName = L["Team"]
AJM.moduleDisplayName = L["Core: Tags"]

-- Settings - the values to store and their defaults for the settings database.
AJM.settings = {
	profile = {
        tagList = {},
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
				desc = L["Add a tag to the this character."],
				usage = "/jamba-tag add <name|existing-tag> <tag>",
				get = false,
				set = "AddTagCommand",
			},					
			remove = {
				type = "input",
				name = L["Remove"],
				desc = L["Remove a tag from this character."],
				usage = "/jamba-tag remove <name|existing-tag> <tag>",
				get = false,
				set = "RemoveTagCommand",
			},						
			push = {
				type = "input",
				name = L["Push Settings"],
				desc = L["Push the tag settings to all characters in the team."],
				usage = "/jamba-tag push",
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

-------------------------------------------------------------------------------------------------------------
-- Messages module sends.
-------------------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------------------------
-- Constants used by module.
-------------------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------------------------
-- Settings Dialogs.
-------------------------------------------------------------------------------------------------------------

local function SettingsCreateTeamList()
	-- Position and size constants.
	local top = JambaHelperSettings:TopOfSettings()
	local left = JambaHelperSettings:LeftOfSettings()
	local headingHeight = JambaHelperSettings:HeadingHeight()
	local headingWidth = JambaHelperSettings:HeadingWidth( false )
	local horizontalSpacing = JambaHelperSettings:GetHorizontalSpacing()
	local verticalSpacing = JambaHelperSettings:GetVerticalSpacing()
	local teamListWidth = headingWidth
	local topOfList = top - headingHeight
	-- Team list internal variables (do not change).
	AJM.settingsControl.teamListHighlightRow = 1
	AJM.settingsControl.teamListOffset = 1
	-- Create a heading.
	JambaHelperSettings:CreateHeading( AJM.settingsControl, L["Team List"], top, false )
	-- Create a team list frame.
	local list = {}
	list.listFrameName = "JambaTagSettingsTeamListFrame"
	list.parentFrame = AJM.settingsControl.widgetSettings.content
	list.listTop = topOfList
	list.listLeft = left
	list.listWidth = teamListWidth
	list.rowHeight = 20
	list.rowsToDisplay = 5
	list.columnsToDisplay = 1
	list.columnInformation = {}
	list.columnInformation[1] = {}
	list.columnInformation[1].width = 100
	list.columnInformation[1].alignment = "LEFT"
	list.scrollRefreshCallback = AJM.SettingsTeamListScrollRefresh
	list.rowClickCallback = AJM.SettingsTeamListRowClick
	AJM.settingsControl.teamList = list
	JambaHelperSettings:CreateScrollList( AJM.settingsControl.teamList )
	local bottomOfList = topOfList - list.listHeight - verticalSpacing	
	return bottomOfList
end

local function SettingsCreateTagList( top )
	-- Position and size constants.
	local tagListButtonControlWidth = 105
	local buttonHeight = JambaHelperSettings:GetButtonHeight()
	local left = JambaHelperSettings:LeftOfSettings()
	local headingHeight = JambaHelperSettings:HeadingHeight()
	local headingWidth = JambaHelperSettings:HeadingWidth( false )
	local horizontalSpacing = JambaHelperSettings:GetHorizontalSpacing()
	local verticalSpacing = JambaHelperSettings:GetVerticalSpacing()
	local tagListWidth = headingWidth
	local topOfList = top - headingHeight
	-- Tag list internal variables (do not change).
	AJM.settingsControl.tagListHighlightRow = 1
	AJM.settingsControl.tagListOffset = 1
	-- Create a heading.
	JambaHelperSettings:CreateHeading( AJM.settingsControl, L["Tag List"], top, false )
	-- Create a tag list frame.
	local list = {}
	list.listFrameName = "JambaTagSettingsTagListFrame"
	list.parentFrame = AJM.settingsControl.widgetSettings.content
	list.listTop = topOfList
	list.listLeft = left
	list.listWidth = tagListWidth
	list.rowHeight = 20
	list.rowsToDisplay = 10
	list.columnsToDisplay = 1
	list.columnInformation = {}
	list.columnInformation[1] = {}
	list.columnInformation[1].width = 100
	list.columnInformation[1].alignment = "LEFT"
	list.scrollRefreshCallback = AJM.SettingsTagListScrollRefresh
	list.rowClickCallback = AJM.SettingsTagListRowClick
	AJM.settingsControl.tagList = list
	JambaHelperSettings:CreateScrollList( AJM.settingsControl.tagList )
	-- Position and size constants (once list height is known).
	local bottomOfList = topOfList - list.listHeight - verticalSpacing
	AJM.settingsControl.tagListButtonAdd = JambaHelperSettings:CreateButton(
		AJM.settingsControl,
		tagListButtonControlWidth,
		left,
		bottomOfList,
		L["Add"],
		AJM.SettingsAddClick
	)
	AJM.settingsControl.teamListButtonRemove = JambaHelperSettings:CreateButton(
		AJM.settingsControl,
		tagListButtonControlWidth,
		left + tagListButtonControlWidth + horizontalSpacing,
		bottomOfList,
		L["Remove"],
		AJM.SettingsRemoveClick
	)
	local bottomOfSection = bottomOfList -  buttonHeight - verticalSpacing
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
	-- Create the tag list controls.
	local bottomOfTagList = SettingsCreateTagList( bottomOfTeamList )
	AJM.settingsControl.widgetSettings.content:SetHeight( -bottomOfTagList )
	-- Help
	local helpTable = {}
	JambaHelperSettings:CreateHelp( AJM.settingsControl, helpTable, AJM:GetConfiguration() )		
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
	-- Update the settings team list.
	AJM:SettingsTeamListScrollRefresh()
	AJM:SettingsTagListScrollRefresh()
end

-- Settings received.
function AJM:JambaOnSettingsReceived( characterName, settings )	
	characterName = JambaUtilities:AddRealmToNameIfMissing( characterName )
	if characterName ~= AJM.characterName then
		-- Update the settings.
		AJM.db.tagList = JambaUtilities:CopyTable( settings.tagList )
		AJM:InitializeAllTagsList()
		-- New team and tag lists coming up, highlight first item in each list.
		AJM.settingsControl.teamListHighlightRow = 1
		AJM.settingsControl.tagListHighlightRow = 1
		-- Refresh the settings.
		AJM:SettingsRefresh()
		AJM:SettingsTeamListRowClick( 1, 1 )
		-- Tell the player.
		AJM:Print( L["Settings received from A."]( characterName ) )
		-- Tell the team?
		--AJM:JambaSendMessageToTeam( AJM.db.messageArea,  L["Settings received from A."]( characterName ), false )
	end
end

-------------------------------------------------------------------------------------------------------------
-- Popup Dialogs.
-------------------------------------------------------------------------------------------------------------

-- Initialize Popup Dialogs.
local function InitializePopupDialogs()
   -- Ask the name of the tag to add as to the character.
   StaticPopupDialogs["JAMBATAG_ASK_TAG_NAME"] = {
        text = L["Enter a tag to add:"],
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
			AJM:AddTagGUI( self.editBox:GetText() )
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
				AJM:AddTagGUI( self:GetText() )
            end
            self:GetParent():Hide()
        end,				
    }
   -- Confirm removing characters from member list.
   StaticPopupDialogs["JAMBATAG_CONFIRM_REMOVE_TAG"] = {
        text = L["Are you sure you wish to remove %s from the tag list for %s?"],
        button1 = ACCEPT,
        button2 = CANCEL,
        timeout = 0,
		whileDead = 1,
		hideOnEscape = 1,
        OnAccept = function( self )
			AJM:RemoveTagGUI()
		end,
    }        
end

-------------------------------------------------------------------------------------------------------------
-- Tag management.
-------------------------------------------------------------------------------------------------------------

local function AllTag()
	return L["all"]
end

local function MasterTag()
	return L["master"]
end

local function MinionTag()
	return L["minion"]
end

local function JustMeTag()
	return L["justme"]
end

-- Does this tag list have this tag?
local function DoesTagListHaveTag( tagList, tag )
	local haveTag = false
	for index, findTag in ipairs( tagList ) do
		if findTag == tag then
			haveTag = true
			break
		end
	end
	return haveTag
end

local function GetTagAtPosition( position )
	return AJM.characterTagList[position]
end

local function IsTagASystemTag( tag )
	if tag == MasterTag() or tag == MinionTag() or tag == AllTag() or tag == JustMeTag() then
		return true
	end
	for token, localizedName in pairs( AJM.tagClassesFemale ) do
		if tag == JambaUtilities:Lowercase( localizedName ) then
			return true
		end
	end	
	for token, localizedName in pairs( AJM.tagClassesMale ) do
		if tag == JambaUtilities:Lowercase( localizedName ) then
			return true
		end	
	end	
	return false
end

local function GetTagListForCharacter( characterName )
	characterName = JambaUtilities:AddRealmToNameIfMissing( characterName )
	if AJM.db.tagList[characterName] == nil then
		AJM.db.tagList[characterName] = {}
	end
	return AJM.db.tagList[characterName]
end

-- Add a tag to the all tags list.
local function AddTagToAllTagsList( tag )
	if DoesTagListHaveTag( AJM.allTagsList, tag ) == false then
		table.insert( AJM.allTagsList, tag )
		table.sort( AJM.allTagsList )
	end
end

-- Initialise the all tags list.
function AJM:InitializeAllTagsList()
	-- Clear the tag list table.
	JambaUtilities:ClearTable( AJM.allTagsList )
	-- Add system tags to the list.
	AddTagToAllTagsList( AllTag() )
	AddTagToAllTagsList( MasterTag() )
	AddTagToAllTagsList( MinionTag() )
	AddTagToAllTagsList( JustMeTag() )
	-- Add class tags to the list.
	AJM.tagClassesFemale = {}
	FillLocalizedClassList( AJM.tagClassesFemale, true )
	for token, localizedName in pairs( AJM.tagClassesFemale ) do
		AddTagToAllTagsList( JambaUtilities:Lowercase( localizedName ) )
	end	
	AJM.tagClassesMale = {}
	FillLocalizedClassList( AJM.tagClassesMale, false )
	for token, localizedName in pairs( AJM.tagClassesMale ) do
		AddTagToAllTagsList( JambaUtilities:Lowercase( localizedName ) )
	end	
	-- Add the tags the characters have to the list.
	for characterName, tagList in pairs( AJM.db.tagList ) do
		for index, tag in ipairs( tagList ) do
			AddTagToAllTagsList( tag )
		end
	end
end

-- Return an iterator for the all tags list.
local function AllTagsList()
	return AJM.allTagsList
end

-- Return an iterator for the all tags list.
local function AllTagsListIterator()
	return pairs( AJM.allTagsList )
end

local function IsAValidTag( tag )
	return DoesTagListHaveTag( AJM.allTagsList, tag )
end

local function GetCharacterWithTag( tagToGet )
	if IsAValidTag( tagToGet ) == false then
		return ""
	end
	for characterName, tagList in pairs( AJM.db.tagList ) do
		for index, tag in ipairs( tagList ) do
			if tag == tagToGet then
				return characterName
			end
		end
	end
	return ""
end

local function AddTag( tagList, tag )
	table.insert( tagList, tag )	
	AddTagToAllTagsList( tag )
end

local function RemoveTag( tagList, tag )
	local removeIndex = 0
	for index, findTag in ipairs( tagList ) do
		if tag == findTag then
			removeIndex = index
		end
	end
	if removeIndex ~= 0 then
		table.remove( tagList, removeIndex )
	end
end

local function InternalAddTagToCharacter( characterName, tag )
	local characterTagList = GetTagListForCharacter( characterName )
	-- Cannot add a tag that already exists.
	if DoesTagListHaveTag( characterTagList, tag ) == false then
		-- Add tag.
		AddTag( characterTagList, tag )
		table.sort( characterTagList )
		AJM:SettingsTagListScrollRefresh()	
	end
end

local function AddTagToCharacter( characterNameOrExistingTag, tag )
	if IsTagASystemTag( tag ) == true then
		return
	end
	if JambaPrivate.Team.IsCharacterInTeam( characterNameOrExistingTag ) == true then
		-- Is a character, add the tag to that character.
		InternalAddTagToCharacter( characterNameOrExistingTag, tag )
	else
		-- Assume characterNameOrTag is a tag.  Add the tag to all characters with this existing tag.		
		-- Find all characters with this tag (characterNameOrExistingTag)
		for characterName, tagList in pairs( AJM.db.tagList ) do
			for index, tagIterated in ipairs( tagList ) do
				if tagIterated == characterNameOrExistingTag then
					-- Add tag: tag to character: characterName
					InternalAddTagToCharacter( characterName, tag )
				end
			end
		end
	end
end

local function InternalRemoveTagFromCharacter( characterName, tag )
	local characterTagList = GetTagListForCharacter( characterName )
	RemoveTag( characterTagList, tag )
	table.sort( characterTagList )
	AJM:SettingsTagListScrollRefresh()
end

local function RemoveTagFromCharacter( characterNameOrExistingTag, tag )
	if IsTagASystemTag( tag ) == true then
		return
	end
	if JambaPrivate.Team.IsCharacterInTeam( characterNameOrExistingTag ) == true then
		-- Is a character, remove the tag from that character.	
		InternalRemoveTagFromCharacter( characterNameOrExistingTag, tag )
	else
		-- Assume characterNameOrTag is a tag.  Remove the tag from all characters with this existing tag.
		-- Find all characters with this tag (characterNameOrExistingTag)
		for characterName, tagList in pairs( AJM.db.tagList ) do
			for index, tagIterated in ipairs( tagList ) do
				if tagIterated == characterNameOrExistingTag then
					-- Remove tag: tag from character: characterName
					InternalRemoveTagFromCharacter( characterName, tag )
				end
			end
		end		
	end
end

-- Add tag to character from the command line.
function AJM:AddTagCommand( info, parameters )
	local characterNameOrExistingTag, tag = strsplit( " ", parameters )
	local characterName = characterNameOrExistingTag
	local finalCharacterNameOrExistingTag = characterNameOrExistingTag
	if JambaPrivate.Team.IsCharacterInTeam( characterName ) == true then
		finalCharacterNameOrExistingTag = characterName
	end
	AddTagToCharacter( finalCharacterNameOrExistingTag, tag )
end

-- Remove tag from character from the command line.
function AJM:RemoveTagCommand( info, parameters )
	local characterNameOrExistingTag, tag = strsplit( " ", parameters )
	local characterName = characterNameOrExistingTag
	local finalCharacterNameOrExistingTag = characterNameOrExistingTag
	if JambaPrivate.Team.IsCharacterInTeam( characterName ) == true then
		finalCharacterNameOrExistingTag = characterName
	end	
	RemoveTagFromCharacter( finalCharacterNameOrExistingTag, tag )
end

function AJM:AddTagGUI( tag )
	-- Cannot add a system tag.
	if IsTagASystemTag( tag ) == false then
		-- Cannot add a tag that already exists.
		if DoesTagListHaveTag( AJM.characterTagList, tag ) == false then
			-- Add tag, resort and display.
			AddTag( AJM.characterTagList, tag )
			table.sort( AJM.characterTagList )
			AJM:SettingsTagListScrollRefresh()	
		end
	end
end

function AJM:RemoveTagGUI()
	local tag = GetTagAtPosition( AJM.settingsControl.tagListHighlightRow )
	-- Cannot remove a system tag.
	if IsTagASystemTag( tag ) == false then
		RemoveTag( AJM.characterTagList, tag )
		table.sort( AJM.characterTagList )
		AJM:SettingsTagListScrollRefresh()	
	end
end

local function GetTagListMaxPosition()
	return #AJM.characterTagList
end

local function DisplayTagsForCharacterInTagList( characterName )
	AJM.characterTagList = GetTagListForCharacter( characterName )
	table.sort( AJM.characterTagList )
	AJM:SettingsTagListScrollRefresh()
end

local function CheckSystemTagsAreCorrect()
	for characterName, characterPosition in JambaPrivate.Team.TeamList() do
		local characterTagList = GetTagListForCharacter( characterName )
		-- Make sure all characters have the "all" tag.
		if DoesTagListHaveTag( characterTagList, AllTag() ) == false then
			AddTag( characterTagList, AllTag() )
		end
		-- Make sure all characters have the "justme" tag.
		if DoesTagListHaveTag( characterTagList, JustMeTag() ) == false then
			AddTag( characterTagList, JustMeTag() )
		end
		local localizedName, token = UnitClass( characterName )
		if localizedName ~= nil then
			InternalAddTagToCharacter( characterName, JambaUtilities:Lowercase( localizedName ))
		end	
		-- Master or minion?
		if JambaPrivate.Team.IsCharacterTheMaster( characterName ) == true then
			-- Make sure the master has the master tag and not a minion tag.
			if DoesTagListHaveTag( characterTagList, MasterTag() ) == false then
				AddTag( characterTagList, MasterTag() )
			end
			if DoesTagListHaveTag( characterTagList, MinionTag() ) == true then
				RemoveTag( characterTagList, MinionTag() )
			end
		else
			-- Make sure minions have the minion tag and not the master tag.
			if DoesTagListHaveTag( characterTagList, MasterTag() ) == true then
				RemoveTag( characterTagList, MasterTag() )
			end
			if DoesTagListHaveTag( characterTagList, MinionTag() ) == false then
				AddTag( characterTagList, MinionTag() )
			end
		end
	end
end

local function DoesCharacterHaveTag( characterName, tag )
	--characterName = JambaUtilities:AddRealmToNameIfMissing( characterName )
	local characterTagList = GetTagListForCharacter( characterName )
	return DoesTagListHaveTag( characterTagList, tag )
end

function AJM:OnMasterChanged( message, characterName )
	CheckSystemTagsAreCorrect()
	AJM:SettingsRefresh()
end

function AJM:OnCharacterAdded( message, characterName )
	CheckSystemTagsAreCorrect()
	AJM:SettingsRefresh()
end

function AJM:OnCharacterRemoved( message, characterName )
	AJM.db.tagList[characterName] = nil
	AJM:SettingsRefresh()
end

-------------------------------------------------------------------------------------------------------------
-- Settings Callbacks.
-------------------------------------------------------------------------------------------------------------

function AJM:SettingsTeamListScrollRefresh()
	FauxScrollFrame_Update(
		AJM.settingsControl.teamList.listScrollFrame, 
		JambaPrivate.Team.GetTeamListMaximumOrder(),
		AJM.settingsControl.teamList.rowsToDisplay, 
		AJM.settingsControl.teamList.rowHeight
	)
	AJM.settingsControl.teamListOffset = FauxScrollFrame_GetOffset( AJM.settingsControl.teamList.listScrollFrame )
	for iterateDisplayRows = 1, AJM.settingsControl.teamList.rowsToDisplay do
		-- Reset.
		AJM.settingsControl.teamList.rows[iterateDisplayRows].columns[1].textString:SetText( "" )
		AJM.settingsControl.teamList.rows[iterateDisplayRows].columns[1].textString:SetTextColor( 1.0, 1.0, 1.0, 1.0 )
		AJM.settingsControl.teamList.rows[iterateDisplayRows].highlight:SetColorTexture( 0.0, 0.0, 0.0, 0.0 )
		-- Get data.
		local dataRowNumber = iterateDisplayRows + AJM.settingsControl.teamListOffset
		if dataRowNumber <= JambaPrivate.Team.GetTeamListMaximumOrder() then
			-- Put character name into columns.
			local characterName = JambaPrivate.Team.GetCharacterNameAtOrderPosition( dataRowNumber )
			AJM.settingsControl.teamList.rows[iterateDisplayRows].columns[1].textString:SetText( characterName )
			-- Highlight the selected row.
			if dataRowNumber == AJM.settingsControl.teamListHighlightRow then
				AJM.settingsControl.teamList.rows[iterateDisplayRows].highlight:SetColorTexture( 1.0, 1.0, 0.0, 0.5 )
			end
		end
	end
end

function AJM:SettingsTeamListRowClick( rowNumber, columnNumber )		
	if AJM.settingsControl.teamListOffset + rowNumber <= JambaPrivate.Team.GetTeamListMaximumOrder() then
		AJM.settingsControl.teamListHighlightRow = AJM.settingsControl.teamListOffset + rowNumber
		AJM:SettingsTeamListScrollRefresh()
		-- New tag list coming up, highlight first item in list.
		AJM.settingsControl.tagListHighlightRow = 1
		local characterName = JambaPrivate.Team.GetCharacterNameAtOrderPosition( AJM.settingsControl.teamListHighlightRow )
		DisplayTagsForCharacterInTagList( characterName )
	end
end

function AJM:SettingsTagListScrollRefresh()
	FauxScrollFrame_Update(
		AJM.settingsControl.tagList.listScrollFrame, 
		GetTagListMaxPosition(),
		AJM.settingsControl.tagList.rowsToDisplay, 
		AJM.settingsControl.tagList.rowHeight
	)
	AJM.settingsControl.tagListOffset = FauxScrollFrame_GetOffset( AJM.settingsControl.tagList.listScrollFrame )
	for iterateDisplayRows = 1, AJM.settingsControl.tagList.rowsToDisplay do
		-- Reset.
		AJM.settingsControl.tagList.rows[iterateDisplayRows].columns[1].textString:SetText( "" )
		AJM.settingsControl.tagList.rows[iterateDisplayRows].columns[1].textString:SetTextColor( 1.0, 1.0, 1.0, 1.0 )
		AJM.settingsControl.tagList.rows[iterateDisplayRows].highlight:SetColorTexture( 0.0, 0.0, 0.0, 0.0 )
		-- Get data.
		local dataRowNumber = iterateDisplayRows + AJM.settingsControl.tagListOffset
		if dataRowNumber <= GetTagListMaxPosition() then
			-- Put tag into column.
			local tag = GetTagAtPosition( dataRowNumber )
			AJM.settingsControl.tagList.rows[iterateDisplayRows].columns[1].textString:SetText( tag )
			-- System tags are yellow.
			if IsTagASystemTag( tag ) == true then
				AJM.settingsControl.tagList.rows[iterateDisplayRows].columns[1].textString:SetTextColor( 1.0, 0.96, 0.41, 1.0 )
			end
			-- Highlight the selected row.
			if dataRowNumber == AJM.settingsControl.tagListHighlightRow then
				AJM.settingsControl.tagList.rows[iterateDisplayRows].highlight:SetColorTexture( 1.0, 1.0, 0.0, 0.5 )
			end
		end
	end
end

function AJM:SettingsTagListRowClick( rowNumber, columnNumber )		
	if AJM.settingsControl.tagListOffset + rowNumber <= GetTagListMaxPosition() then
		AJM.settingsControl.tagListHighlightRow = AJM.settingsControl.tagListOffset + rowNumber
		AJM:SettingsTagListScrollRefresh()
	end
end

function AJM:SettingsPushSettingsClick( event )
	AJM:JambaSendSettings()
end

function AJM:SettingsAddClick( event )
	StaticPopup_Show( "JAMBATAG_ASK_TAG_NAME" )
end

function AJM:SettingsRemoveClick( event )
	local tag = GetTagAtPosition( AJM.settingsControl.tagListHighlightRow )
	local characterName = JambaPrivate.Team.GetCharacterNameAtOrderPosition( AJM.settingsControl.teamListHighlightRow )
	StaticPopup_Show( "JAMBATAG_CONFIRM_REMOVE_TAG", tag, characterName )
end

-------------------------------------------------------------------------------------------------------------
-- Addon initialization, enabling and disabling.
-------------------------------------------------------------------------------------------------------------

-- Initialise the module.
function AJM:OnInitialize()
	-- Current character tag list. 
	AJM.characterTagList = {}
	-- Unique list of all tags.
	AJM.allTagsList = {}
	-- Create the settings control.
	SettingsCreate()
	-- Initialise the JambaModule part of this module.
	AJM:JambaModuleInitialize( AJM.settingsControl.widgetSettings.frame )
	-- Populate the settings.
	AJM:SettingsRefresh()	
	-- Initialise the popup dialogs.
	InitializePopupDialogs()
	-- Initialise the all tags list.
	AJM:InitializeAllTagsList()
end

-- Called when the addon is enabled.
function AJM:OnEnable()
	-- Make sure all the system tags are correct.
	CheckSystemTagsAreCorrect()
	AJM:RegisterMessage( JambaPrivate.Team.MESSAGE_TEAM_MASTER_CHANGED, "OnMasterChanged" )
	AJM:RegisterMessage( JambaPrivate.Team.MESSAGE_TEAM_CHARACTER_ADDED, "OnCharacterAdded" )
	AJM:RegisterMessage( JambaPrivate.Team.MESSAGE_TEAM_CHARACTER_REMOVED, "OnCharacterRemoved" )
	-- Kickstart the settings team and tag list scroll frame.
	AJM:SettingsTeamListScrollRefresh()
	AJM:SettingsTagListScrollRefresh()
	-- Click the first row in the team list table to populate the tag list table.
	AJM:SettingsTeamListRowClick( 1, 1 )
end

-- Called when the addon is disabled.
function AJM:OnDisable()
end
	
-------------------------------------------------------------------------------------------------------------
-- Commands.
-------------------------------------------------------------------------------------------------------------

function AJM:JambaOnCommandReceived( sender, commandName, ... )
end

-- Functions available from Jamba Tag for other Jamba internal objects.
JambaPrivate.Tag.AllTag = AllTag
JambaPrivate.Tag.MasterTag = MasterTag
JambaPrivate.Tag.MinionTag = MinionTag
JambaPrivate.Tag.JustMeTag = JustMeTag
JambaPrivate.Tag.AllTagsList = AllTagsList
JambaPrivate.Tag.AllTagsListIterator = AllTagsListIterator
JambaPrivate.Tag.DoesCharacterHaveTag = DoesCharacterHaveTag
JambaPrivate.Tag.IsAValidTag = IsAValidTag
JambaPrivate.Tag.GetCharacterWithTag = GetCharacterWithTag

-- Functions available for other addons.
JambaApi.AllTag = AllTag
JambaApi.MasterTag = MasterTag
JambaApi.MinionTag = MinionTag
JambaApi.JustMeTag = JustMeTag
JambaApi.AllTagsList = AllTagsList
JambaApi.AllTagsListIterator = AllTagsListIterator
JambaApi.DoesCharacterHaveTag = DoesCharacterHaveTag
JambaApi.IsAValidTag = IsAValidTag
JambaApi.GetCharacterWithTag = GetCharacterWithTag