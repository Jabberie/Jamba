--[[
Jamba - Jafula's Awesome Multi-Boxer Assistant
Copyright 2008 - 2015 Michael "Jafula" Miller
License: The MIT License
]]--

local AJM = LibStub( "AceAddon-3.0" ):NewAddon( 
	"JambaCommunications", 
	"AceComm-3.0", 
	"AceEvent-3.0",
	"AceConsole-3.0",
	"AceTimer-3.0",
	"AceHook-3.0"
)

-- Get the locale for JambaCommunications.
local L = LibStub( "AceLocale-3.0" ):GetLocale( "Jamba-Core" )

-- Get libraries.
local AceSerializer = LibStub:GetLibrary( "AceSerializer-3.0" )
local JambaHelperSettings = LibStub:GetLibrary( "JambaHelperSettings-1.0" )

-- JambaCommunications is not a module, but the same naming convention for these values is convenient.
AJM.moduleName = "Jamba-Communications"
AJM.moduleDisplayName = L["Core: Communications"]
AJM.settingsDatabaseName = "JambaCommunicationsProfileDB"
AJM.parentDisplayName = L["Advanced"]
AJM.chatCommand = "jamba-comm"

-------------------------------------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------------------------------------

-- Communication methods.
AJM.COMMUNICATION_WHISPER = "WHISPER"
AJM.COMMUNICATION_GROUP = "RAID"

-- Communication message prefix.
AJM.MESSAGE_PREFIX = "JmbCmMsg"

-- Communication over channel for online status.
AJM.COMMUNICATION_TEAM_ONLINE_PREFIX = "JmbCmTmOn"
AJM.COMMUNICATION_MESSAGE_ONLINE = "JmbCmTmOnTe"
AJM.COMMUNICATION_MESSAGE_OFFLINE = "JmbCmTmOnFe"

-- Communication priorities.
AJM.COMMUNICATION_PRIORITY_BULK = "BULK"
AJM.COMMUNICATION_PRIORITY_NORMAL = "NORMAL"
AJM.COMMUNICATION_PRIORITY_ALERT = "ALERT"

-- Communication command.
AJM.COMMAND_PREFIX = "JmbCmCmd"
AJM.COMMAND_SEPERATOR = "\004"
AJM.COMMAND_ARGUMENT_SEPERATOR = "\005"

-- Internal commands sent by Jamba Communications.
AJM.COMMAND_INTERNAL_SEND_SETTINGS = "JmbCmSdSet"

-------------------------------------------------------------------------------------------------------------
-- Messages module sends.
-------------------------------------------------------------------------------------------------------------

AJM.MESSAGE_CHARACTER_ONLINE = "JmbTmChrOn"
AJM.MESSAGE_CHARACTER_OFFLINE = "JmbTmChrOf"

-- Get a settings value.
function AJM:ConfigurationGetSetting( key )
	return AJM.db[key[#key]]
end

-- Set a settings value.
function AJM:ConfigurationSetSetting( key, value )
	AJM.db[key[#key]] = value
end

-- Settings - the values to store and their defaults for the settings database.
AJM.settings = {
	profile = {
		teamOnlineChannelName = "JambaTeamIsOnline",
		teamOnlineChannelPassword = "JambaTeamPassword",
		showOnlineChannel = false,
		assumeTeamAlwaysOnline = true,
		boostCommunication = true,
	},
}

-- Configuration.
local function GetConfiguration()
	local configuration = {
		name = AJM.moduleDisplayName,
		handler = AJM,
		type = 'group',
		get = "ConfigurationGetSetting",
		set = "ConfigurationSetSetting",
		args = {			 				
			push = {
				type = "input",
				name = L["Push Settings"],
				desc = L["Push settings to all characters in the team list."],
				usage = "/jamba-comm push",
				get = false,
				set = "JambaSendSettings",
			},	
			channel = {
				type = "input",
				name = L["Change Channel"],
				desc = L["Change the communications channel."],
				usage = "/jamba-comm channel <channel name> <channel password>",
				get = false,
				set = "ChangeChannelCommand",
			},				
		},
	}
	return configuration
end


-- Debug message.
function AJM:DebugMessage( ... )
    --AJM:Print( ... )
end

-------------------------------------------------------------------------------------------------------------
-- Character online management.
-------------------------------------------------------------------------------------------------------------

local function AssumeTeamAlwaysOnline()
	return AJM.db.assumeTeamAlwaysOnline
end

-- Join the team online status channel.
local function JoinTeamOnlineStatusChannel()
	local channelType, channelName = JoinTemporaryChannel( AJM.db.teamOnlineChannelName, AJM.db.teamOnlineChannelPassword )
	AJM.lastChannel = AJM.db.teamOnlineChannelName
end

-- Leave the team online status channel.
local function LeaveTeamOnlineStatusChannel()
	LeaveChannelByName( AJM.channelJustMovedFrom )
	AJM.channelJustMovedFrom = AJM.lastChannel
end

function AJM:SettingsChangeChannelClick( event )
	AJM:StopChannelPollTimer()
	AJM:Print( "Changing Channel from [", AJM.lastChannel, "] to [", AJM.db.teamOnlineChannelName, "]." )
	AJM.channelJustMovedFrom = AJM.lastChannel
	JoinTeamOnlineStatusChannel()
	LeaveTeamOnlineStatusChannel()
	AJM:StartChannelPollTimer()
end

-- Is a character online?
local function IsCharacterOnline( characterName )
	if AJM.db.assumeTeamAlwaysOnline == true then
		return true
	end
	return JambaPrivate.Team.GetCharacterOnlineStatus( characterName )
end

-- Test to see if the channel name provided is the name of the team online channel.
local function IsChannelTeamOnlineChannel( channelName )
	local isTeamOnlineChannel = false
	if channelName ~= nil then
		if AJM.db.showOnlineChannel == true then
			AJM:Print( "Team Channel: match? this:", string.utf8lower( channelName ), "team:", string.utf8lower( AJM.lastChannel ), "or:", string.utf8lower( AJM.channelJustMovedFrom ) )
		end
		if string.utf8lower( channelName ) == string.utf8lower( AJM.lastChannel ) then
			isTeamOnlineChannel = true
		end
		if string.utf8lower( channelName) == string.utf8lower( AJM.channelJustMovedFrom ) then
			isTeamOnlineChannel = true
		end		
	end
	return isTeamOnlineChannel 
end

function AJM:CHAT_MSG_CHANNEL_LIST( event, ... )
	if AJM.db.showOnlineChannel == true then
		AJM:Print( "CHAT_MSG_CHANNEL_LIST" )
	end
	local message, arg2, arg3, arg4, arg5, arg6, arg7, arg8, channelName, arg10, arg11, arg12 = ... 	
	-- Is this the team online channel?
	if IsChannelTeamOnlineChannel( channelName ) == true then
		-- Yes, set all characters to be offline.
		JambaPrivate.Team.SetTeamStatusToOffline()
		-- Parse the message for characters.
		local characters = {}
		for character in message:gmatch( "[^,]+" ) do
			table.insert( characters, character )
		end
		for index, character in pairs( characters ) do 
			local characterName = character:gsub( "%s*%@*%**([^%s]+)", "%1" )	
			-- Is this character in our team?		
			if JambaPrivate.Team.IsCharacterInTeam( characterName ) == true then
				-- Set the character status to online.
				JambaPrivate.Team.SetCharacterOnlineStatus( characterName, true )
			end
		end
	end
end

function AJM:CHAT_MSG_CHANNEL_JOIN( event, ... )
	if AJM.db.showOnlineChannel == true then
		AJM:Print( "CHAT_MSG_CHANNEL_JOIN" )
	end
	local arg1, sender, arg3, arg4, arg5, arg6, arg7, arg8, channelName, arg10, arg11, arg12 = ... 
	-- Is this the team online channel?
	if IsChannelTeamOnlineChannel( channelName ) == true then
		-- Is this character in our team?		
		if JambaPrivate.Team.IsCharacterInTeam( sender ) == true then
			-- Set the character status to online.
			JambaPrivate.Team.SetCharacterOnlineStatus( sender, true )
			AJM:SendMessage( AJM.MESSAGE_CHARACTER_ONLINE )
		end
	end
end

function AJM:CHAT_MSG_CHANNEL_LEAVE( event, ... )
	if AJM.db.showOnlineChannel == true then
		AJM:Print( "CHAT_MSG_CHANNEL_LEAVE" )
	end
	local arg1, sender, arg3, arg4, arg5, arg6, arg7, arg8, channelName, arg10, arg11, arg12 = ... 
	-- Is this the team online channel?
	if IsChannelTeamOnlineChannel( channelName ) == true then
		-- Is this character in our team?		
		if JambaPrivate.Team.IsCharacterInTeam( sender ) == true then
			-- Set the character status to offline.
			JambaPrivate.Team.SetCharacterOnlineStatus( sender, false )
			AJM:SendMessage( AJM.MESSAGE_CHARACTER_OFFLINE )
		end
	end
end

-- TODO: Investigate ChatFrame_AddMessageEventFilter (hooks may be the wrong thing to do here)
-- TODO: See http://www.wowwiki.com/API_ChatFrame_AddMessageEventFilter
-- The ChatFrame_MessageEventHandler hook.
function AJM:ChatFrame_MessageEventHandler( self, event, ... )
	if AJM.db.showOnlineChannel == true then
		AJM:Print( "ChatFrame_MessageEventHandler" )
	end
	local arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, channelName, arg10, arg11, arg12 = ... 	
	-- Is this the team online channel?
	if IsChannelTeamOnlineChannel( channelName ) == true then
		-- Yes, the chat frames don't need to know about this channel.
		if AJM.db.showOnlineChannel == false then
			return true
		end
	end
	-- Call the orginal function.
	return AJM.hooks["ChatFrame_MessageEventHandler"]( self, event, ... )
end

-------------------------------------------------------------------------------------------------------------
-- Command management.
-------------------------------------------------------------------------------------------------------------

-- Creates a command to send.
local function CreateCommandToSend( moduleName, commandName, ... )
	-- Start the message with the module name and a seperator.
	local message = moduleName..AJM.COMMAND_SEPERATOR
	-- Add the command  name and a seperator.
	message = message..commandName..AJM.COMMAND_SEPERATOR
	-- Add any arguments to the message (serialized and seperated).
	local numberArguments = select( "#", ... )
	for iterateArguments = 1, numberArguments do
		local argument = select( iterateArguments, ... )
		message = message..AceSerializer:Serialize( argument )
		if iterateArguments < numberArguments then
			message = message..AJM.COMMAND_ARGUMENT_SEPERATOR
		end
	end
	-- Return the command to send.
	return message	
end

-- Send a command to all members of the current team.
local function CommandAll( moduleName, commandName, ... )
    AJM:DebugMessage( "Command All: ", moduleName, commandName, ... )
	-- Get the message to send.
	local message = CreateCommandToSend( moduleName, commandName, ... )
	-- Send command to all in group/raid.
	--if not UnitInBattleground( "player" ) then
	if UnitInParty( "player" ) == true then --or UnitInRaid( "player" ) then 
		if not UnitInBattleground( "player" ) then
		AJM:DebugMessage( "Sending command to group." )
			AJM:SendCommMessage( 
			AJM.COMMAND_PREFIX,
			message,
			AJM.COMMUNICATION_GROUP,
			nil,
			AJM.COMMUNICATION_PRIORITY_ALERT
			)
		end	
	end
	-- If player not in a party or raid, then send to player. Pointless as does it under anyway, x2 everything!
--	if GetNumSubgroupMembers() == 0 and GetNumGroupMembers() == 0 then
--	AJM:DebugMessage( "Sending command just to single player." )
--		AJM:SendCommMessage( 
--			AJM.COMMAND_PREFIX,
--			message,
--			AJM.COMMUNICATION_WHISPER,
--			UnitName( "player" ),
--			AJM.COMMUNICATION_PRIORITY_ALERT
--		)		
--	end
	-- Send the message to all members of the current team that are not in a party / raid.	
	for characterName, characterOrder in JambaPrivate.Team.TeamList() do
		if IsCharacterOnline( characterName ) == true then
			local canSend = false
			-- Team member not in party then send command.
			if not UnitInParty( characterName ) then
				canSend = true
			end
			--If in a battleground then send a whisper as the party/raid would have not been sent.
			if UnitInBattleground( characterName ) then
				canSend = true
			end
			if canSend == true then
                AJM:DebugMessage( "Sending command to others not in party/raid." )
				AJM:SendCommMessage( 
					AJM.COMMAND_PREFIX,
					message,
					AJM.COMMUNICATION_WHISPER,
					characterName,
					AJM.COMMUNICATION_PRIORITY_ALERT
				)
			end
		end
	end
end

-- Send a command to the master.
local function CommandMaster( moduleName, commandName, ... )
--	AJM:DebugMessage( "Command Master: ", moduleName, commandName, ... )
	-- Get the message to send.
	local message = CreateCommandToSend( moduleName, commandName, ... )
	-- Send the message to the master.
	local characterName = JambaPrivate.Team.GetMasterName()
	if IsCharacterOnline( characterName ) == true then
		AJM:SendCommMessage( 
			AJM.COMMAND_PREFIX,
			message,
			AJM.COMMUNICATION_WHISPER,
			characterName,
			AJM.COMMUNICATION_PRIORITY_ALERT
		)
	end
end

-- Send a command to the master.
local function CommandToon( moduleName, characterName, commandName, ... )
	-- Get the message to send.
	local message = CreateCommandToSend( moduleName, commandName, ... )
	if IsCharacterOnline( characterName ) == true then
		AJM:SendCommMessage( 
			AJM.COMMAND_PREFIX,
			message,			AJM.COMMUNICATION_WHISPER,
			characterName,
			AJM.COMMUNICATION_PRIORITY_ALERT
		)
	end
end

-- Send a command to all slave characters of the current team.
local function CommandSlaves( moduleName, commandName, ... )
	-- Get the message to send.
	local message = CreateCommandToSend( moduleName, commandName, ... )
	-- Send the message to all members of the current team.
	for characterName, characterOrder in JambaPrivate.Team.TeamList() do
		if IsCharacterOnline( characterName ) == true then
			if JambaPrivate.Team.IsCharacterTheMaster( characterName ) == false then
				AJM:SendCommMessage( 
					AJM.COMMAND_PREFIX,
					message,
					AJM.COMMUNICATION_WHISPER,
					characterName,
					AJM.COMMUNICATION_PRIORITY_ALERT
				)
			end
		end
	end
end

-- Receive a command from another character.
function AJM:CommandReceived( prefix, message, distribution, sender )
    AJM:DebugMessage( "Command received: ", prefix, message, distribution, sender )
	-- Check if the command is for Jamba Communications.
	if prefix == AJM.COMMAND_PREFIX then
		-- Check if the sender is trusted.
        sender = Ambiguate(sender, "none")
        AJM:DebugMessage( "Sender after ambiguate: ", sender )
		if JambaPrivate.Team.IsCharacterInTeam( sender ) == true then
            AJM:DebugMessage( "Sender is in team list." )
			-- Split the command into its components.
			local moduleName, commandName, argumentsStringSerialized = strsplit( AJM.COMMAND_SEPERATOR, message )
			local argumentsTable  = {}
			-- Are there any arguments?
			if (argumentsStringSerialized ~= nil) and (argumentsStringSerialized:trim() == "") then 
				-- No.
			else
				-- Deserialize the arguments.
				local argumentsTableSerialized = { strsplit( AJM.COMMAND_ARGUMENT_SEPERATOR, argumentsStringSerialized ) }
				for index, argumentSerialized in ipairs( argumentsTableSerialized ) do
					local success, argument = AceSerializer:Deserialize( argumentSerialized )
					if success == true then
						table.insert( argumentsTable, argument )
					else
						error( L["A: Failed to deserialize command arguments for B from C."]( "AJM", moduleName, sender ) )
					end
				end			
			end
			-- Look for internal Jamba Communication commands.
			if commandName == AJM.COMMAND_INTERNAL_SEND_SETTINGS then				
				-- Tell JambaCore to handle the settings received.
				JambaPrivate.Core.OnSettingsReceived( sender, moduleName, unpack( argumentsTable ) )
			else
				-- Any other command can go directly to the module that sent it.
                AJM:DebugMessage( "Sending command on to module: ", sender, moduleName, commandName, unpack( argumentsTable ) )
				JambaPrivate.Core.OnCommandReceived( sender, moduleName, commandName, unpack( argumentsTable ) )
			end			
		end
	end
end

-------------------------------------------------------------------------------------------------------------
-- Jamba Communications API.  These methods should only be called by Jamba Core.
-------------------------------------------------------------------------------------------------------------

-- Send settings to all members of the current team.
local function SendSettings( moduleName, settings )
	-- Send a push settings command to all.
	CommandAll( moduleName, AJM.COMMAND_INTERNAL_SEND_SETTINGS, settings )
end

-- Command all members of the current team.
local function SendCommandAll( moduleName, commandName, ... )
	-- Send the command to all.
	CommandAll( moduleName, commandName, ... )
end

-- 	Command the master.
local function SendCommandMaster( moduleName, commandName, ... )
	-- Send the command to the master character.
	CommandMaster( moduleName, commandName, ... )
end

-- Command the master.
local function SendCommandToon( moduleName, characterName, commandName, ... )
	-- Send the command to the master character.
	CommandToon( moduleName, characterName, commandName, ... )
end

-------------------------------------------------------------------------------------------------------------
-- Jamba Communications Initialization.
-------------------------------------------------------------------------------------------------------------

-- Initialize the addon.
function AJM:OnInitialize()
	AJM.channelPollTimer = nil
	-- Register commands with AceComms - tell AceComms to call the CommandReceived function when a command is received.
	AJM:RegisterComm( AJM.COMMAND_PREFIX, "CommandReceived" )
	-- Create the settings database supplying the settings values along with defaults.
    AJM.completeDatabase = LibStub( "AceDB-3.0" ):New( AJM.settingsDatabaseName, AJM.settings )
	AJM.db = AJM.completeDatabase.profile
	-- Create the settings.
	LibStub( "AceConfig-3.0" ):RegisterOptionsTable( 
		AJM.moduleName, 
		GetConfiguration() 
	)	
	AJM:SettingsCreate()
	AJM.settingsFrame = AJM.settingsControl.widgetSettings.frame
	AJM:SettingsRefresh()	
	if AJM.db.assumeTeamAlwaysOnline == false then
		-- Hook the ChatFrame_MessageEventHandler to hide any messages that are for the team online channel.
		AJM:RawHook( "ChatFrame_MessageEventHandler", true )
	end
	AJM.characterName = UnitName( "player" )
	AJM.characterGUID = UnitGUID( "player" )
	AJM:RegisterChatCommand( AJM.chatCommand, "JambaChatCommand" )
	-- Register communications as a module.
	JambaPrivate.Core.RegisterModule( AJM, AJM.moduleName )
	-- The last channel joined.
	AJM.lastChannel = AJM.db.teamOnlineChannelName
	AJM.channelJustMovedFrom = AJM.lastChannel
end

function AJM:OnEnable()
	if AJM.db.assumeTeamAlwaysOnline == false then
		-- Wait for some seconds before initialising the team online channel.
		-- This lets the defaults channels get the usual channel numbers (i.e. Trade is /2).
		AJM:ScheduleTimer( "InitialiseTeamOnlineChannel", 10 )
	end
	if AJM.db.boostCommunication == true then
		AJM:BoostCommunication()
		-- Repeat every 5 minutes.
		AJM:ScheduleRepeatingTimer( "BoostCommunication", 300 )
	end
end

function AJM:BoostCommunication()
	if AJM.db.boostCommunication == true then
		-- 2000 seems to be safe if NOTHING ELSE is happening. let's call it 800.
		ChatThrottleLib.MAX_CPS = 1200 --800
		-- Guesstimate overhead for sending a message; source+dest+chattype+protocolstuff
		ChatThrottleLib.MSG_OVERHEAD = 40
		-- WoW's server buffer seems to be about 32KB. 8KB should be safe, but seen disconnects on _some_ servers. Using 4KB now.
		ChatThrottleLib.BURST = 6000 --4000
		-- Reduce output CPS to half (and don't burst) if FPS drops below this value
		ChatThrottleLib.MIN_FPS = 10 --20
	end
end

-- Handle the chat command.
function AJM:JambaChatCommand( input )
    if not input or input:trim() == "" then
        InterfaceOptionsFrame_OpenToCategory( AJM.moduleDisplayName )
    else
        LibStub( "AceConfigCmd-3.0" ):HandleCommand( AJM.chatCommand, AJM.moduleName, input )
    end    
end

function AJM:InitialiseTeamOnlineChannel()
	-- Register for the list of members in a channel event.
	AJM:RegisterEvent( "CHAT_MSG_CHANNEL_LIST" )
	-- And for joiners and leavers.
	AJM:RegisterEvent( "CHAT_MSG_CHANNEL_JOIN" )
	AJM:RegisterEvent( "CHAT_MSG_CHANNEL_LEAVE" )
	-- Join the team online channel.
	JoinTeamOnlineStatusChannel()
	-- Ask for a list of characters in the team online channel.
	ListChannelByName( AJM.lastChannel )
	AJM:StartChannelPollTimer()
end

function AJM:StopChannelPollTimer()
	if AJM.channelPollTimer ~= nil then
		AJM:CancelTimer( AJM.channelPollTimer )
	end
end

function AJM:StartChannelPollTimer()
	-- Poll for characters every 5 seconds.
	AJM.channelPollTimer = AJM:ScheduleRepeatingTimer( ListChannelByName, 5, AJM.lastChannel )
end

function AJM:OnDisable()
	AJM:CancelAllTimers()
end

-------------------------------------------------------------------------------------------------------------
-- Settings Dialogs.
-------------------------------------------------------------------------------------------------------------

function AJM:SettingsCreate()
	AJM.settingsControl = {}
	JambaHelperSettings:CreateSettings( 
		AJM.settingsControl, 
		AJM.moduleDisplayName, 
		AJM.parentDisplayName, 
		AJM.JambaSendSettings 
	)
	local bottomOfOptions = AJM:SettingsCreateOptions( JambaHelperSettings:TopOfSettings() )
	AJM.settingsControl.widgetSettings.content:SetHeight( -bottomOfOptions )
	-- Help
	local helpTable = {}
	JambaHelperSettings:CreateHelp( AJM.settingsControl, helpTable, GetConfiguration() )	
end

function AJM:SettingsCreateOptions( top )
	-- Get positions and dimensions.
	local checkBoxHeight = JambaHelperSettings:GetCheckBoxHeight()
	local labelContinueHeight = JambaHelperSettings:GetContinueLabelHeight()
	local editBoxHeight = JambaHelperSettings:GetEditBoxHeight()
	local buttonHeight = JambaHelperSettings:GetButtonHeight()
	local left = JambaHelperSettings:LeftOfSettings()
	local headingHeight = JambaHelperSettings:HeadingHeight()
	local headingWidth = JambaHelperSettings:HeadingWidth( false )
	local horizontalSpacing = JambaHelperSettings:GetHorizontalSpacing()
	local verticalSpacing = JambaHelperSettings:GetVerticalSpacing()
	local halfWidth = (headingWidth - horizontalSpacing) / 2
	local column1Left = left
	local movingTop = top
	-- Create a heading for information.
	JambaHelperSettings:CreateHeading( AJM.settingsControl, L["Team Online Check"], movingTop, false )
	movingTop = movingTop - headingHeight
	AJM.settingsControl.checkBoxAssumeAlwaysOnline = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		column1Left, 
		movingTop, 
		L["Assume All Team Members Always Online*"],
		AJM.CheckBoxAssumeAlwaysOnline
	)
	movingTop = movingTop - checkBoxHeight	
	AJM.settingsControl.labelInformationAlwaysOnline = JambaHelperSettings:CreateContinueLabel( 
		AJM.settingsControl, 
		headingWidth, 
		column1Left, 
		movingTop,
		L["*reload UI to take effect"]
	)	
	movingTop = movingTop - labelContinueHeight	
	AJM.settingsControl.checkBoxBoostCommunication = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		column1Left, 
		movingTop, 
		L["Boost Jamba to Jamba Communications**"],
		AJM.CheckBoxBoostCommunication
	)
	movingTop = movingTop - checkBoxHeight
	AJM.settingsControl.labelInformationBoost = JambaHelperSettings:CreateContinueLabel( 
		AJM.settingsControl, 
		headingWidth, 
		column1Left, 
		movingTop,
		L["**reload UI to take effect, may cause disconnections"]
	)	
	movingTop = movingTop - labelContinueHeight			
	-- Create a heading for information.
	JambaHelperSettings:CreateHeading( AJM.settingsControl, L["Team Online Channel"], movingTop, false )
	movingTop = movingTop - headingHeight
	-- Information line 1.
	AJM.settingsControl.labelInformation1 = JambaHelperSettings:CreateContinueLabel( 
		AJM.settingsControl, 
		headingWidth, 
		column1Left, 
		movingTop,
		L["After you change the channel name or password, push the"]
	)	
	movingTop = movingTop - labelContinueHeight		
	-- Information line 2.
	AJM.settingsControl.labelInformation2 = JambaHelperSettings:CreateContinueLabel( 
		AJM.settingsControl, 
		headingWidth, 
		column1Left, 
		movingTop,
		L["new settings to all your other characters and then log off"]
	)	
	movingTop = movingTop - labelContinueHeight		
	-- Information line 3.
	AJM.settingsControl.labelInformation3 = JambaHelperSettings:CreateContinueLabel( 
		AJM.settingsControl, 
		headingWidth, 
		column1Left, 
		movingTop,
		L["all your characters and log them on again."]
	)	
	movingTop = movingTop - labelContinueHeight				
	-- Channel name.
	AJM.settingsControl.editBoxChannelName = JambaHelperSettings:CreateEditBox( AJM.settingsControl,
		headingWidth,
		column1Left,
		movingTop,
		L["Channel Name"]
	)	
	AJM.settingsControl.editBoxChannelName:SetCallback( "OnEnterPressed", AJM.EditBoxChannelNameChanged )
	movingTop = movingTop - editBoxHeight
	-- Channel password.
	AJM.settingsControl.editBoxChannelPassword = JambaHelperSettings:CreateEditBox( AJM.settingsControl,
		headingWidth,
		column1Left,
		movingTop,
		L["Channel Password"]
	)	
	AJM.settingsControl.editBoxChannelPassword:SetCallback( "OnEnterPressed", AJM.EditBoxChannelPasswordChanged )
	movingTop = movingTop - editBoxHeight
	-- Change channel button.
	AJM.settingsControl.buttonChangeChannel = JambaHelperSettings:CreateButton(
		AJM.settingsControl, 
		headingWidth, 
		column1Left, 
		movingTop, 
		L["Change Channel (Debug)"],
		AJM.SettingsChangeChannelClick
	)	
	movingTop = movingTop - buttonHeight		
	AJM.settingsControl.checkBoxShowChannel = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		column1Left, 
		movingTop, 
		L["Show Online Channel Traffic (For Debugging Purposes)"],
		AJM.CheckBoxShowChannelClick
	)
	movingTop = movingTop - checkBoxHeight		
	return movingTop	
end

function AJM:EditBoxChannelNameChanged( event, text )
	AJM.db.teamOnlineChannelName = text
end

function AJM:EditBoxChannelPasswordChanged( event, text )
	AJM.db.teamOnlineChannelPassword = text
end

function AJM:CheckBoxShowChannelClick( event, value )
	AJM.db.showOnlineChannel = value
	AJM:SettingsRefresh()	
end

function AJM:CheckBoxAssumeAlwaysOnline( event, value )
	AJM.db.assumeTeamAlwaysOnline = value
	AJM:SettingsRefresh()	
end

function AJM:CheckBoxBoostCommunication( event, value )
	AJM.db.boostCommunication = value
	AJM:SettingsRefresh()	
end

function AJM:BeforeJambaProfileChanged()	
end

function AJM:OnJambaProfileChanged()	
	AJM:SettingsRefresh()
end

function AJM:SettingsRefresh()	
	AJM.settingsControl.editBoxChannelName:SetText( AJM.db.teamOnlineChannelName )
	AJM.settingsControl.editBoxChannelPassword:SetText( AJM.db.teamOnlineChannelPassword )
	AJM.settingsControl.checkBoxShowChannel:SetValue( AJM.db.showOnlineChannel )
	AJM.settingsControl.checkBoxAssumeAlwaysOnline:SetValue( AJM.db.assumeTeamAlwaysOnline )
	AJM.settingsControl.checkBoxBoostCommunication:SetValue( AJM.db.boostCommunication )
end

-- Settings received.
function AJM:JambaSendSettings()
	SendSettings( AJM.moduleName, AJM.db )
end

-- Settings received.
function AJM:JambaOnSettingsReceived( characterName, settings )
	if characterName ~= AJM.characterName then
		-- Update the settings.
		AJM.db.teamOnlineChannelName = settings.teamOnlineChannelName
		AJM.db.teamOnlineChannelPassword = settings.teamOnlineChannelPassword
		AJM.db.showOnlineChannel = settings.showOnlineChannel
		AJM.db.assumeTeamAlwaysOnline = settings.assumeTeamAlwaysOnline
		AJM.db.boostCommunication = settings.boostCommunication
		-- Refresh the settings.
		AJM:SettingsRefresh()
		-- Tell the player.
		AJM:Print( L["Settings received from A."]( characterName ) )
	end
end

function AJM:ChangeChannelCommand( info, parameters )
	local name, password = strsplit( " ", parameters )
	AJM:ChangeChannelCommandAction( name, password )
end

function AJM:ChangeChannelCommandAction( name, password )
	AJM.db.teamOnlineChannelName = name
	AJM.db.teamOnlineChannelPassword = password
	AJM:SettingsRefresh()
	AJM:SettingsChangeChannelClick( nil )
end

-- text = message to send
-- chatDestination = "PARTY, WHISPER, RAID, CHANNEL, etc"
-- characterOrChannelName = character name if WHISPER or channel name if CHANNEL or nil otherwise
-- priority = one of 
--   AJM.COMMUNICATION_PRIORITY_BULK,
--   AJM.COMMUNICATION_PRIORITY_NORMAL
--   AJM.COMMUNICATION_PRIORITY_ALERT
local function SendChatMessage( text, chatDestination, characterOrChannelName, priority )
	-- Message small enough to send?
	if text:len() <= 255 then
		ChatThrottleLib:SendChatMessage( priority, AJM.MESSAGE_PREFIX, text, chatDestination, nil, characterOrChannelName, nil )
	else
		-- No, message is too big, split into smaller messages, taking UTF8 characters into account.	
		local bytesAvailable = string.utf8len(text1)
		local currentPosition = 1
		local countBytes = 1
		local startPosition = currentPosition
		local splitText = ""
		-- Iterate all the utf8 characters, character by character until we reach 255 characters, then send
		-- those off and start counting over.
		while currentPosition <= bytesAvailable do
			-- Count the number of bytes the character at this position takes up.
			countBytes = countBytes + jambautf8charbytes( text, currentPosition )
			-- More than 255 bytes yet?
			if countBytes <= 255 then
				-- No, increment the position and keep counting.
				currentPosition = currentPosition + jambautf8charbytes( text, currentPosition )
			else
				-- Yes, more than 255.  Send this amount off.
				splitText = text:sub( startPosition, currentPosition )
				ChatThrottleLib:SendChatMessage( priority, AJM.MESSAGE_PREFIX, splitText, chatDestination, nil, characterOrChannelName, nil )
				-- New start position and count.
				startPosition = currentPosition + 1
				countBytes = 1
			end
		end
		-- Any more bytes left to send?
		if startPosition < currentPosition then
			-- Yes, send them.
			splitText = text:sub( startPosition, currentPosition )
			ChatThrottleLib:SendChatMessage( priority, AJM.MESSAGE_PREFIX, splitText, chatDestination, nil, characterOrChannelName, nil )
		end
	end
end

-- Functions available from Jamba Communications for other Jamba internal objects.
JambaPrivate.Communications.COMMUNICATION_PRIORITY_BULK = AJM.COMMUNICATION_PRIORITY_BULK
JambaPrivate.Communications.COMMUNICATION_PRIORITY_NORMAL = AJM.COMMUNICATION_PRIORITY_NORMAL
JambaPrivate.Communications.COMMUNICATION_PRIORITY_ALERT = AJM.COMMUNICATION_PRIORITY_ALERT
JambaPrivate.Communications.SendChatMessage = SendChatMessage
JambaPrivate.Communications.SendSettings = SendSettings
JambaPrivate.Communications.SendCommandAll = SendCommandAll
JambaPrivate.Communications.SendCommandMaster = SendCommandMaster
JambaPrivate.Communications.SendCommandToon = SendCommandToon
JambaPrivate.Communications.AssumeTeamAlwaysOnline = AssumeTeamAlwaysOnline
JambaPrivate.Communications.MESSAGE_CHARACTER_ONLINE = AJM.MESSAGE_CHARACTER_ONLINE
JambaPrivate.Communications.MESSAGE_CHARACTER_OFFLINE = AJM.MESSAGE_CHARACTER_OFFLINE

JambaApi.SendChatMessage = SendChatMessage
JambaApi.COMMUNICATION_PRIORITY_BULK = AJM.COMMUNICATION_PRIORITY_BULK
JambaApi.COMMUNICATION_PRIORITY_NORMAL = AJM.COMMUNICATION_PRIORITY_NORMAL
JambaApi.COMMUNICATION_PRIORITY_ALERT = AJM.COMMUNICATION_PRIORITY_ALERT
JambaApi.MESSAGE_CHARACTER_ONLINE = AJM.MESSAGE_CHARACTER_ONLINE
JambaApi.MESSAGE_CHARACTER_OFFLINE = AJM.MESSAGE_CHARACTER_OFFLINE
