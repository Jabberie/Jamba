--[[
Jamba - Jafula's Awesome Multi-Boxer Assistant
Copyright 2008 - 2018 Michael "Jafula" Miller
License: The MIT License
]]--

-- Create the addon using AceAddon-3.0 and embed some libraries.
local AJM = LibStub( "AceAddon-3.0" ):NewAddon( 
	"JambaTalk", 
	"JambaModule-1.0", 
	"AceConsole-3.0", 
	"AceEvent-3.0",
	"AceHook-3.0"
)

-- Load libraries.
local JambaUtilities = LibStub:GetLibrary( "JambaUtilities-1.0" )
local JambaHelperSettings = LibStub:GetLibrary( "JambaHelperSettings-1.0" )

--  Constants and Locale for this module.
AJM.moduleName = "Jamba-Talk"
AJM.settingsDatabaseName = "JambaTalkProfileDB"
AJM.chatCommand = "jamba-talk"
local L = LibStub( "AceLocale-3.0" ):GetLocale( AJM.moduleName )
AJM.parentDisplayName = L["Chat"]
AJM.moduleDisplayName = L["Talk"]

-- Settings - the values to store and their defaults for the settings database.
AJM.settings = {
	profile = {
		forwardWhispers = true,
		doNotForwardRealIdWhispers = true,
		forwardViaWhisper = false,
		fakeWhisper = true,
		fakeInjectSenderToReplyQueue = true,
		fakeInjectOriginatorToReplyQueue = false,
		fakeWhisperCompact = false,
		whisperMessageArea = "ChatFrame1",
		enableChatSnippets = false,
		chatSnippets = {},
	},
}

-- Configuration.
function AJM:GetConfiguration()
	local configuration = {
		name = AJM.moduleDisplayName,
		handler = AJM,
		type = 'group',
		childGroups  = "tab",
		get = "JambaConfigurationGetSetting",
		set = "JambaConfigurationSetSetting",
		args = {	
			push = {
				type = "input",
				name = L["Push Settings"],
				desc = L["Push the talk settings to all characters in the team."],
				usage = "/jamba-talk push",
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

AJM.COMMAND_MESSAGE = "JambaTalkMessage"

-------------------------------------------------------------------------------------------------------------
-- Messages module sends.
-------------------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------------------------
-- Talk Management.
-------------------------------------------------------------------------------------------------------------

function AJM:UpdateChatFrameList()
	JambaUtilities:ClearTable( AJM.chatFrameList )
	for index = 1, NUM_CHAT_WINDOWS do
		local name, fontSize, r, g, b, alpha, shown, locked, docked, uninteractable = GetChatWindowInfo( index )
		if (shown == 1) or (docked ~= nil) then
			AJM.chatFrameList["ChatFrame"..index] = name
		end
	end
	table.sort( AJM.chatFrameList )
end

function AJM:BeforeJambaProfileChanged()	
end

function AJM:OnJambaProfileChanged()	
	AJM:SettingsRefresh()
end

function AJM:SettingsRefresh()
	-- Set values.
	AJM.settingsControl.checkBoxForwardWhispers:SetValue( AJM.db.forwardWhispers )
	AJM.settingsControl.checkBoxDoNotForwardRealIdWhispers:SetValue( AJM.db.doNotForwardRealIdWhispers )
	AJM.settingsControl.checkBoxForwardViaWhisper:SetValue( AJM.db.forwardViaWhisper )
	AJM.settingsControl.checkBoxFakeWhispers:SetValue( AJM.db.fakeWhisper )
	AJM.settingsControl.checkBoxFakeInjectSenderToReplyQueue:SetValue( AJM.db.fakeInjectSenderToReplyQueue )
	AJM.settingsControl.checkBoxFakeInjectOriginatorToReplyQueue:SetValue( AJM.db.fakeInjectOriginatorToReplyQueue )
	AJM.settingsControl.checkBoxFakeWhisperCompact:SetValue( AJM.db.fakeWhisperCompact )
	AJM.settingsControl.checkBoxEnableChatSnippets:SetValue( AJM.db.enableChatSnippets )
	AJM.settingsControl.dropdownMessageArea:SetValue( AJM.db.whisperMessageArea )
	-- Set state.
	AJM.settingsControl.checkBoxFakeInjectSenderToReplyQueue:SetDisabled( not AJM.db.fakeWhisper )
	AJM.settingsControl.checkBoxFakeInjectOriginatorToReplyQueue:SetDisabled( not AJM.db.fakeWhisper )
	AJM.settingsControl.checkBoxFakeWhisperCompact:SetDisabled( not AJM.db.fakeWhisper )
	AJM.settingsControl.dropdownMessageArea:SetDisabled( not AJM.db.fakeWhisper )
	AJM.settingsControl.buttonRefreshChatList:SetDisabled( not AJM.db.fakeWhisper )
	AJM.settingsControl.buttonRemove:SetDisabled( not AJM.db.enableChatSnippets )
	AJM.settingsControl.buttonAdd:SetDisabled( not AJM.db.enableChatSnippets )
	AJM.settingsControl.multiEditBoxSnippet:SetDisabled( not AJM.db.enableChatSnippets )
	AJM:SettingsScrollRefresh()
end

-- Settings received.
function AJM:JambaOnSettingsReceived( characterName, settings )	
	if characterName ~= AJM.characterName then
		-- Update the settings.
		AJM.db.forwardWhispers = settings.forwardWhispers
		AJM.db.doNotForwardRealIdWhispers = settings.doNotForwardRealIdWhispers
		AJM.db.fakeWhisper = settings.fakeWhisper
		AJM.db.enableChatSnippets = settings.enableChatSnippets
		AJM.db.whisperMessageArea = settings.whisperMessageArea
		AJM.db.forwardViaWhisper = settings.forwardViaWhisper
		AJM.db.fakeWhisperCompact = settings.fakeWhisperCompact
		AJM.db.fakeInjectSenderToReplyQueue = settings.fakeInjectSenderToReplyQueue
		AJM.db.fakeInjectOriginatorToReplyQueue = settings.fakeInjectOriginatorToReplyQueue
		AJM.db.chatSnippets = JambaUtilities:CopyTable( settings.chatSnippets )
		-- Refresh the settings.
		AJM:SettingsRefresh()
		-- Tell the player.
		AJM:Print( L["Settings received from A."]( characterName ) )
		-- Tell the team?
		--AJM:JambaSendMessageToTeam( AJM.db.messageArea,  L["Settings received from A."]( characterName ), false )
	end
end

-------------------------------------------------------------------------------------------------------------
-- Settings Dialogs.
-------------------------------------------------------------------------------------------------------------

local function SettingsCreateOptions( top )
	-- Position and size constants.
	local buttonControlWidth = 105
	local checkBoxHeight = JambaHelperSettings:GetCheckBoxHeight()
	local buttonHeight = JambaHelperSettings:GetButtonHeight()
	local editBoxHeight = JambaHelperSettings:GetEditBoxHeight()
	local dropdownHeight = JambaHelperSettings:GetDropdownHeight()
	local left = JambaHelperSettings:LeftOfSettings()
	local headingHeight = JambaHelperSettings:HeadingHeight()
	local headingWidth = JambaHelperSettings:HeadingWidth( false )
	local horizontalSpacing = JambaHelperSettings:GetHorizontalSpacing()
	local verticalSpacing = JambaHelperSettings:GetVerticalSpacing()
	local halfWidth = (headingWidth - horizontalSpacing) / 2
	local left2 = left + halfWidth + horizontalSpacing
	local indent = horizontalSpacing * 10
	local movingTop = top
	JambaHelperSettings:CreateHeading( AJM.settingsControl, L["Talk Options"], movingTop, false )
	movingTop = movingTop - headingHeight
	AJM.settingsControl.checkBoxForwardWhispers = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		left, 
		movingTop, 
		L["Forward Whispers To Master And Relay Back"],
		AJM.SettingsToggleForwardWhispers
	)	
	movingTop = movingTop - checkBoxHeight	
	AJM.settingsControl.checkBoxDoNotForwardRealIdWhispers = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		left, 
		movingTop, 
		L["Do Not Forward RealID Whispers"],
		AJM.SettingsToggleDoNotForwardRealIdWhispers
	)	
	movingTop = movingTop - checkBoxHeight	
	AJM.settingsControl.checkBoxForwardViaWhisper = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		left, 
		movingTop, 
		L["Forward Using Normal Whispers"],
		AJM.SettingsToggleForwardViaWhisper
	)	
	movingTop = movingTop - checkBoxHeight
	AJM.settingsControl.checkBoxFakeWhispers = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		left, 
		movingTop, 
		L["Forward Via Fake Whispers For Clickable Links And Players"],
		AJM.SettingsToggleFakeWhispers
	)	
	movingTop = movingTop - checkBoxHeight
		AJM.settingsControl.dropdownMessageArea = JambaHelperSettings:CreateDropdown( 
		AJM.settingsControl,
		(headingWidth - indent) / 2, 
		left + indent, 
		movingTop, 
		L["Send Fake Whispers To"] 
	)
	AJM.settingsControl.dropdownMessageArea:SetList( AJM.chatFrameList )
	AJM.settingsControl.dropdownMessageArea:SetCallback( "OnValueChanged", AJM.SettingsSetMessageArea )
	AJM.settingsControl.buttonRefreshChatList = JambaHelperSettings:CreateButton(
		AJM.settingsControl, 
		buttonControlWidth, 
		left + indent + (headingWidth - indent) / 2 + horizontalSpacing, 
		movingTop - buttonHeight + 4,
		L["Update"],
		AJM.SettingsRefreshChatListClick
	)
	movingTop = movingTop - dropdownHeight - verticalSpacing
	AJM.settingsControl.checkBoxFakeInjectSenderToReplyQueue = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth - indent, 
		left + indent, 
		movingTop, 
		L["Add Forwarder To Reply Queue On Master"],
		AJM.SettingsToggleFakeInjectSenderToReplyQueue
	)	
	movingTop = movingTop - checkBoxHeight
	AJM.settingsControl.checkBoxFakeInjectOriginatorToReplyQueue = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth - indent, 
		left + indent, 
		movingTop, 
		L["Add Originator To Reply Queue On Master"],
		AJM.SettingsToggleFakeInjectOriginatorToReplyQueue
	)	
	movingTop = movingTop - checkBoxHeight
	AJM.settingsControl.checkBoxFakeWhisperCompact = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth - indent, 
		left + indent, 
		movingTop, 
		L["Only Show Messages With Links"],
		AJM.SettingsToggleFakeWhisperCompact
	)	
	movingTop = movingTop - checkBoxHeight	
	JambaHelperSettings:CreateHeading( AJM.settingsControl, L["Chat Snippets"], movingTop, false )
	movingTop = movingTop - headingHeight	
	AJM.settingsControl.checkBoxEnableChatSnippets = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		left, 
		movingTop, 
		L["Enable Chat Snippets"],
		AJM.SettingsToggleChatSnippets
	)	
	movingTop = movingTop - checkBoxHeight		
	AJM.settingsControl.highlightRow = 1
	AJM.settingsControl.offset = 1
	local list = {}
	list.listFrameName = "JambaTalkChatSnippetsSettingsFrame"
	list.parentFrame = AJM.settingsControl.widgetSettings.content
	list.listTop = movingTop
	list.listLeft = left
	list.listWidth = headingWidth
	list.rowHeight = 20
	list.rowsToDisplay = 5
	list.columnsToDisplay = 2
	list.columnInformation = {}
	list.columnInformation[1] = {}
	list.columnInformation[1].width = 25
	list.columnInformation[1].alignment = "LEFT"
	list.columnInformation[2] = {}
	list.columnInformation[2].width = 75
	list.columnInformation[2].alignment = "LEFT"	
	list.scrollRefreshCallback = AJM.SettingsScrollRefresh
	list.rowClickCallback = AJM.SettingsRowClick
	AJM.settingsControl.list = list
	JambaHelperSettings:CreateScrollList( AJM.settingsControl.list )
	movingTop = movingTop - list.listHeight - verticalSpacing
	AJM.settingsControl.buttonAdd = JambaHelperSettings:CreateButton(	
		AJM.settingsControl, 
		buttonControlWidth, 
		left, 
		movingTop, 
		L["Add"],
		AJM.SettingsAddClick
	)
	AJM.settingsControl.buttonRemove = JambaHelperSettings:CreateButton(
		AJM.settingsControl, 
		buttonControlWidth, 
		left + buttonControlWidth + horizontalSpacing, 
		movingTop,
		L["Remove"],
		AJM.SettingsRemoveClick
	)
	movingTop = movingTop -	buttonHeight - verticalSpacing
	AJM.settingsControl.multiEditBoxSnippet = JambaHelperSettings:CreateMultiEditBox( 
		AJM.settingsControl,
		headingWidth,
		left,
		movingTop,
		L["Snippet Text"],
		5
	)
	AJM.settingsControl.multiEditBoxSnippet:SetCallback( "OnEnterPressed", AJM.SettingsMultiEditBoxChangedSnippet )
	local multiEditBoxHeightSnippet = 110
	movingTop = movingTop - multiEditBoxHeightSnippet								
	return movingTop
end

local function SettingsCreate()
	AJM.settingsControl = {}
	JambaHelperSettings:CreateSettings( 
		AJM.settingsControl, 
		AJM.moduleDisplayName, 
		AJM.parentDisplayName, 
		AJM.SettingsPushSettingsClick 
	)
	local bottomOfSettings = SettingsCreateOptions( JambaHelperSettings:TopOfSettings() )
	AJM.settingsControl.widgetSettings.content:SetHeight( -bottomOfSettings )
	-- Help
	local helpTable = {}
	JambaHelperSettings:CreateHelp( AJM.settingsControl, helpTable, AJM:GetConfiguration() )		
end

-------------------------------------------------------------------------------------------------------------
-- Settings Callbacks.
-------------------------------------------------------------------------------------------------------------

function AJM:SettingsScrollRefresh()
	FauxScrollFrame_Update(
		AJM.settingsControl.list.listScrollFrame, 
		AJM:GetItemsMaxPosition(),
		AJM.settingsControl.list.rowsToDisplay, 
		AJM.settingsControl.list.rowHeight
	)
	AJM.settingsControl.offset = FauxScrollFrame_GetOffset( AJM.settingsControl.list.listScrollFrame )
	for iterateDisplayRows = 1, AJM.settingsControl.list.rowsToDisplay do
		-- Reset.
		AJM.settingsControl.list.rows[iterateDisplayRows].columns[1].textString:SetText( "" )
		AJM.settingsControl.list.rows[iterateDisplayRows].columns[1].textString:SetTextColor( 1.0, 1.0, 1.0, 1.0 )
		AJM.settingsControl.list.rows[iterateDisplayRows].columns[2].textString:SetText( "" )
		AJM.settingsControl.list.rows[iterateDisplayRows].columns[2].textString:SetTextColor( 1.0, 1.0, 1.0, 1.0 )				
		AJM.settingsControl.list.rows[iterateDisplayRows].highlight:SetColorTexture( 0.0, 0.0, 0.0, 0.0 )
		-- Get data.
		local dataRowNumber = iterateDisplayRows + AJM.settingsControl.offset
		if dataRowNumber <= AJM:GetItemsMaxPosition() then
			-- Put data information into columns.
			local itemInformation = AJM:GetItemAtPosition( dataRowNumber )
			AJM.settingsControl.list.rows[iterateDisplayRows].columns[1].textString:SetText( itemInformation.name )
			AJM.settingsControl.list.rows[iterateDisplayRows].columns[2].textString:SetText( itemInformation.snippet )
			-- Highlight the selected row.
			if dataRowNumber == AJM.settingsControl.highlightRow then
				AJM.settingsControl.list.rows[iterateDisplayRows].highlight:SetColorTexture( 1.0, 1.0, 0.0, 0.5 )
			end
		end
	end
end

function AJM:SettingsRowClick( rowNumber, columnNumber )		
	if AJM.settingsControl.offset + rowNumber <= AJM:GetItemsMaxPosition() then
		AJM.settingsControl.highlightRow = AJM.settingsControl.offset + rowNumber
		local itemInformation = AJM:GetItemAtPosition( AJM.settingsControl.highlightRow )
		if itemInformation ~= nil then
			AJM.settingsControl.multiEditBoxSnippet:SetText( itemInformation.snippet )
		end
		AJM:SettingsScrollRefresh()
	end
end

function AJM:SettingsPushSettingsClick( event )
	AJM:JambaSendSettings()
end

function AJM:SettingsSetMessageArea( event, value )
	AJM.db.whisperMessageArea = value
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleForwardWhispers( event, checked )
	AJM.db.forwardWhispers = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleDoNotForwardRealIdWhispers( event, checked )
	AJM.db.doNotForwardRealIdWhispers = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleFakeWhispers( event, checked )
	AJM.db.fakeWhisper = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleForwardViaWhisper( event, checked )
	AJM.db.forwardViaWhisper = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleFakeInjectSenderToReplyQueue( event, checked )
	AJM.db.fakeInjectSenderToReplyQueue = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleFakeInjectOriginatorToReplyQueue( event, checked )
	AJM.db.fakeInjectOriginatorToReplyQueue = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleFakeWhisperCompact( event, checked )
	AJM.db.fakeWhisperCompact = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleChatSnippets( event, checked )
	AJM.db.enableChatSnippets = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsMultiEditBoxChangedSnippet( event, text )
	local itemInformation = AJM:GetItemAtPosition( AJM.settingsControl.highlightRow )
	if itemInformation ~= nil then
		itemInformation.snippet = text
	end
	AJM:SettingsRefresh()
end

function AJM:SettingsRefreshChatListClick( event )
	AJM:UPDATE_CHAT_WINDOWS()
end

function AJM:SettingsAddClick( event )
	StaticPopup_Show( "JAMBATALK_ASK_SNIPPET" )
end

function AJM:SettingsRemoveClick( event )
	StaticPopup_Show( "JAMBATALK_CONFIRM_REMOVE_CHAT_SNIPPET" )
end

-------------------------------------------------------------------------------------------------------------
-- Popup Dialogs.
-------------------------------------------------------------------------------------------------------------

-- Initialize Popup Dialogs.
local function InitializePopupDialogs()
   StaticPopupDialogs["JAMBATALK_ASK_SNIPPET"] = {
        text = L["Enter the shortcut text for this chat snippet:"],
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
			AJM:AddItem( self.editBox:GetText() )
		end,
		EditBoxOnTextChanged = function( self )
            if not self:GetText() or self:GetText():trim() == "" or self:GetText():find( "%W" ) ~= nil then
				self:GetParent().button1:Disable()
            else
                self:GetParent().button1:Enable()
            end
        end,
		EditBoxOnEnterPressed = function( self )
            if self:GetParent().button1:IsEnabled() then
				AJM:AddItem( self:GetText() )
            end
            self:GetParent():Hide()
        end,				
    }
	StaticPopupDialogs["JAMBATALK_CONFIRM_REMOVE_CHAT_SNIPPET"] = {
        text = L["Are you sure you wish to remove the selected chat snippet?"],
        button1 = YES,
        button2 = NO,
        timeout = 0,
		whileDead = 1,
		hideOnEscape = 1,
        OnAccept = function( self )
			AJM:RemoveItem()
		end,
    } 
end

-------------------------------------------------------------------------------------------------------------
-- Addon initialization, enabling and disabling.
-------------------------------------------------------------------------------------------------------------

-- Initialise the module.
function AJM:OnInitialize()
	AJM.chatFrameList = {}
	AJM:UpdateChatFrameList()
	-- Remember the last sender to whisper this character.
	AJM.lastSender = nil
	AJM.lastSenderIsReal = false
	AJM.lastSenderRealID = nil
	-- Create the settings control.
	SettingsCreate()
	-- Initialise the JambaModule part of this module.
	AJM:JambaModuleInitialize( AJM.settingsControl.widgetSettings.frame )
	-- Hook the SendChatMessage to translate any chat snippets.
	AJM:RawHook( "SendChatMessage", true )	
	-- Initialise the popup dialogs.
	InitializePopupDialogs()
	-- Populate the settings.
	AJM:SettingsRefresh()	
	AJM:SettingsRowClick( 1, 1 )
end

-- Called when the addon is enabled.
function AJM:OnEnable()
	AJM:RegisterEvent( "CHAT_MSG_WHISPER" )
	AJM:RegisterEvent( "CHAT_MSG_BN_WHISPER" )
	AJM:RegisterEvent( "UPDATE_CHAT_WINDOWS" )
	AJM:RegisterEvent( "UPDATE_FLOATING_CHAT_WINDOWS", "UPDATE_CHAT_WINDOWS" )
end

-- Called when the addon is disabled.
function AJM:OnDisable()
end

-------------------------------------------------------------------------------------------------------------
-- JambaTalk functionality.
-------------------------------------------------------------------------------------------------------------

function AJM:UPDATE_CHAT_WINDOWS()
	AJM:UpdateChatFrameList()
	AJM.settingsControl.dropdownMessageArea:SetList( AJM.chatFrameList )
	if AJM.chatFrameList[AJM.db.whisperMessageArea] == nil then
		AJM.db.whisperMessageArea = "ChatFrame1"
	end
	AJM.settingsControl.dropdownMessageArea:SetValue( AJM.db.whisperMessageArea )	
end

function AJM:GetItemsMaxPosition()
	return #AJM.db.chatSnippets
end

function AJM:GetItemAtPosition( position )
	return AJM.db.chatSnippets[position]
end

function AJM:AddItem( name )
	local itemInformation = {}
	itemInformation.name = name
	itemInformation.snippet = ""
	table.insert( AJM.db.chatSnippets, itemInformation )
	AJM:SettingsRefresh()			
	AJM:SettingsRowClick( 1, 1 )
end

function AJM:RemoveItem()
	table.remove( AJM.db.chatSnippets, AJM.settingsControl.highlightRow )
	AJM:SettingsRefresh()
	AJM:SettingsRowClick( 1, 1 )		
end

-- The SendChatMessage hook.
function AJM:SendChatMessage( ... )
	local message, chatType, language, target = ...
	if chatType == "WHISPER" then
		-- Does this character have chat snippets enabled?
		if AJM.db.enableChatSnippets == true then
			local snippetName = select( 3, message:find( "^!(%w+)$" ) )
			-- If a snippet name was found...
			if snippetName then
				-- Then look up the associated text.
				local messageToSend = AJM:GetTextForSnippet( snippetName )
				JambaApi.SendChatMessage( messageToSend, "WHISPER", target, JambaApi.COMMUNICATION_PRIORITY_BULK )
				-- Finish with the chat message, i.e. do not let the original handler run.
				return true
			end
		end
	end
	-- Call the orginal function.
	return AJM.hooks["SendChatMessage"]( ... )
end

function AJM:CHAT_MSG_WHISPER( chatType, message, sender, language, channelName, target, flag, ... )
	-- Does this character forward whispers?
	if AJM.db.forwardWhispers == true then
		-- Set a GM flag if this whisper was from a GM.
		local isGM = false
		if flag == L["GM"] then
			isGM = true
		end
		-- Was the sender the master?
		if JambaApi.IsCharacterTheMaster( sender ) == true then
			-- Yes, relay the masters message to others.
			AJM:ForwardWhisperFromMaster( message )
		else		
			-- Not the master, forward the whisper to the master.
			AJM:ForwardWhisperToMaster( message, sender, isGM, false, nil )
		end
	end
end

function AJM:CHAT_MSG_BN_WHISPER( event, message, sender, a, b, c, d, e, f, g, h, i, j, realFriendID, ... )
	-- Does this character forward whispers?
	if AJM.db.forwardWhispers == true and AJM.db.doNotForwardRealIdWhispers == false then
		-- Is this character NOT the master?
		if JambaApi.IsCharacterTheMaster( self.characterName ) == false then
			-- Yes, not the master, relay the message to the master.
			AJM:ForwardWhisperToMaster( message, sender, false, true, realFriendID )
		end
	end
end

local function ColourCodeLinks( message )
	local realMessage = message
	for link in message:gmatch( "|H.*|h" ) do
		local realLink = ""
		local startFind, endFind = message:find( "|Hitem", 1, true )
		-- Is it an item link?
		if startFind ~= nil then
			-- Yes, is an item link.
			local itemQuality = select( 3, GetItemInfo( link ) )
			-- If the item is not in our cache, we cannot get the correct item quality / colour and the link will not work.
			if itemQuality ~= nil then
				realLink = select( 4, GetItemQualityColor( itemQuality ) )..link..FONT_COLOR_CODE_CLOSE
			else
				realLink = NORMAL_FONT_COLOR_CODE..link..FONT_COLOR_CODE_CLOSE
			end
		else
			-- Not an item link.
			-- GetFixedLink is in Blizzard's FrameXML/ItemRef.lua
			-- It fixes, quest, achievement, talent, trade, enchant and instancelock links.						
			realLink = GetFixedLink( link )
		end
		realMessage = realMessage:replace( link, realLink )
	end
	return realMessage
end

local function DoesMessageHaveLink( message )
	local startFind, endFind = message:find( "|H", 1, true )
	return startFind ~= nil 
end

local function BuildWhisperCharacterString( originalSender, viaCharacter )
	local info = ChatTypeInfo["WHISPER"]
	local colorString = format( "|cff%02x%02x%02x", info.r * 255, info.g * 255, info.b * 255 )
	return format( "%s|Hplayer:%2$s|h[%2$s]|h%4$s|Hplayer:%3$s|h[%3$s]|h%5$s|r", colorString, originalSender, viaCharacter, L[" (via "], L[")"] )
end

function AJM:ForwardWhisperToMaster( message, sender, isGM, isReal, realFriendID )
	-- Don't relay messages to the master or self (causes infinite loop, which causes disconnect).
	if (JambaApi.IsCharacterTheMaster( AJM.characterName )) or (AJM.characterName == sender) then
		return
	end
	-- Don't relay messages from the master either (not that this situation should happen).
	if JambaApi.IsCharacterTheMaster( sender ) == true then
		return
	end
	-- Build from whisper string, this cannot be a link as player links are not sent by whispers.
	local fromCharacterWhisper = sender	
	if isReal == true then
		-- Get the toon name of the character the RealID person is playing, Blizzard will not reveal player real names, so cannot send those.
		fromCharacterWhisper = select( 5, BNGetFriendInfoByID( realFriendID ) )..L["(RealID)"]
		--local presenceID, presenceName, battleTag, isBattleTagPresence, toonName, toonID, client, isOnline, lastOnline, isAFK, isDND, messageText = BNGetFriendInfoByID( realFriendID )
	end
	if isGM == true then
		fromCharacterWhisper = fromCharacterWhisper..L["<GM>"]
	end
	-- Whisper the master.
	if AJM.db.fakeWhisper == true then
		local completeMessage = L[" whispers: "]..message
		-- Send in compact format?
		if AJM.db.fakeWhisperCompact == true then
			-- Does the message contain a link?
			if DoesMessageHaveLink( message ) == false then
				-- No, don't display the message.
				local info = ChatTypeInfo["WHISPER"]
				local colorString = format( "|cff%02x%02x%02x", info.r * 255, info.g * 255, info.b * 255 )
				completeMessage = L[" "]..colorString..L["whispered you."].."|r"
			end
		end
		if isGM == true then
			completeMessage = L[" "]..L["<GM>"]..L[" "]..completeMessage
		end
		local inject1 = nil
		if AJM.db.fakeInjectSenderToReplyQueue == true then
			inject1 = AJM.characterName
		end
		local inject2 = nil
		if AJM.db.fakeInjectOriginatorToReplyQueue == true then
			inject2 = sender
		end
		AJM:JambaSendCommandToMaster( AJM.COMMAND_MESSAGE, AJM.db.whisperMessageArea, sender, AJM.characterName, completeMessage, inject1, inject2 )
	end
	if AJM.db.forwardViaWhisper == true then
		-- RealID messages do not wrap links in colour codes (text is always all blue), so wrap link in colour code
		-- so normal whisper forwarding with link works.
		if (isReal == true) and (DoesMessageHaveLink( message ) == true) then
			message = ColourCodeLinks( message )
		end
		JambaApi.SendChatMessage( fromCharacterWhisper..": "..message, "WHISPER", JambaApi.GetMasterName(), JambaApi.COMMUNICATION_PRIORITY_BULK )
	end
	-- Remember this sender as the most recent sender.
	AJM.lastSender = sender
	AJM.lastSenderIsReal = isReal
	AJM.lastSenderRealID = realFriendID
end

function AJM:ForwardWhisperFromMaster( messageFromMaster )
	-- Who to send to and what to send?
	-- Check the message to see if there is a character to whisper to; character name is preceeded by @.
	-- No match will return nil for the parameters.
	local sendTo, messageToInspect = select( 3, messageFromMaster:find( "^@(%w+)%s*(.*)$" ) )
	-- If no sender found in message...
	if not sendTo then
		-- Then send to last sender.
		sendTo = AJM.lastSender
		-- Send the full message.
		messageToInspect = messageFromMaster
	end
	-- Check to see if there is a snippet name in the message (text with a leading !).
	local messageToSend = messageToInspect
	if AJM.db.enableChatSnippets == true then
		local snippetName = select( 3, messageToInspect:find( "^!(%w+)$" ) )
		-- If a snippet name was found...
		if snippetName then
			-- Then look up the associated text.
			messageToSend = AJM:GetTextForSnippet( snippetName )
		end
	end
	-- If there is a valid character to send to...
	if sendTo then
		if messageToSend:trim() ~= "" then
			-- Send the message.
			if AJM.lastSenderIsReal == true and AJM.lastSenderRealID ~= nil then
				BNSendWhisper( AJM.lastSenderRealID, messageToSend )
			else
				JambaApi.SendChatMessage( messageToSend, "WHISPER", sendTo, JambaApi.COMMUNICATION_PRIORITY_BULK )
			end
		end
		-- Remember this sender as the most recent sender.
		AJM.lastSender = sendTo
	end
end

function AJM:GetTextForSnippet( snippetName )
	local snippet = ""
	for position, itemInformation in pairs( AJM.db.chatSnippets ) do
		if itemInformation.name == snippetName then
			snippet = itemInformation.snippet
			break
		end
	end
	return snippet
end

function AJM:ProcessReceivedMessage( sender, whisperMessageArea, orginator, forwarder, message, inject1, inject2 )
	local chatTimestamp = ""
	local info = ChatTypeInfo["WHISPER"]
	local colorString = format( "|cff%02x%02x%02x", info.r * 255, info.g * 255, info.b * 255 )	
	if (CHAT_TIMESTAMP_FORMAT) then
		chatTimestamp = colorString..BetterDate( CHAT_TIMESTAMP_FORMAT, time() ).."|r"
	end
	local fixedMessage = message
	for embeddedColourString in message:gmatch( "|c.*|r" ) do
		fixedMessage = fixedMessage:replace( embeddedColourString, "|r"..embeddedColourString..colorString )
	end
	fixedMessage = colorString..fixedMessage.."|r"
	if string.sub( whisperMessageArea, 1, 9 ) ~= "ChatFrame" then
		whisperMessageArea = "ChatFrame1"
	end
	_G[whisperMessageArea]:AddMessage( chatTimestamp..BuildWhisperCharacterString( orginator, forwarder )..fixedMessage )
	if inject1 ~= nil then
		ChatEdit_SetLastTellTarget( inject1, "WHISPER" )
	end
	if inject2 ~= nil then
		ChatEdit_SetLastTellTarget( inject2, "WHISPER" )
	end	
end

-- A Jamba command has been recieved.
function AJM:JambaOnCommandReceived( characterName, commandName, ... )
	if commandName == AJM.COMMAND_MESSAGE then		
		AJM:ProcessReceivedMessage( characterName, ... )
	end
end