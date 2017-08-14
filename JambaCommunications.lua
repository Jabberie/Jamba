--[[
Jamba - Jafula's Awesome Multi-Boxer Assistant
Copyright 2008 - 2017 Michael "Jafula" Miller


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
local JambaUtilities = LibStub:GetLibrary( "JambaUtilities-1.0" )
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
AJM.COMMUNICATION_GUILD = "GUILD"

-- Communication message prefix.
AJM.MESSAGE_PREFIX = "JmbCmMsg"


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
--		DO NOT Change lines here!
--		teamOnlineChannelName = "JambaTeamIsOnline",
--		teamOnlineChannelPassword = "JambaTeamPassword",
--		showOnlineChannel = false,
		assumeTeamAlwaysOnline = false, -- This is a place holder And is used as backup DO NOT CHANGE assumeTeamAlwaysOnline unless you know what your doing that you probs don't ;)
		autoSetTeamOnlineorOffline = true,
		boostCommunication = true,
		useGuildComms = false,
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
local function IsCharacterOnline( characterName )
	if AJM.db.assumeTeamAlwaysOnline == true then
		return true
	end
	return JambaPrivate.Team.GetCharacterOnlineStatus( characterName )
end

local function AssumeTeamAlwaysOnline()
	return AJM.db.assumeTeamAlwaysOnline
end


-------------------------------------------------------------------------------------------------------------
-- Command management.
-------------------------------------------------------------------------------------------------------------

-- Creates a command to send.
local function CreateCommandToSend( moduleName, commandName, ... )
	--AJM:Print("Create", moduleName, commandName)
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
	--AJM:Print("Create", moduleName, commandName, iterateArguments)
	return message	
end


local function CommandAll( moduleName, commandName, ... )
   -- AJM:DebugMessage( "Command All: ", moduleName, commandName, ... )
	--AJM:Print( "Command All: ", moduleName, commandName, ... )
	-- Get the message to send.
	local message = CreateCommandToSend( moduleName, commandName, ... )
	local channel
	if AJM.db.useGuildComms == true then
			AJM:SendCommMessage(
			AJM.COMMAND_PREFIX,
			message,
			AJM.COMMUNICATION_GUILD,
			nil,
			AJM.COMMUNICATION_PRIORITY_ALERT	
			)
		return
	end	
	-- toon has to be in a group		
	if UnitInBattleground( "player" ) then
		AJM:DebugMessage( "PvP_INSTANCE")
		channel = "INSTANCE_CHAT"
	elseif IsInGroup() then
		AJM:DebugMessage( "Group")
		local isInstance, instanceType = IsInInstance()
		local name, Type, difficulty, difficultyName, maxPlayers, playerDifficulty, isDynamicInstance = GetInstanceInfo()
		if isInstance or instanceType == "raid" or IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
			if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
				channel = "INSTANCE_CHAT"
			else
				if IsInRaid() then	
					channel = "RAID"
				else
					channel = "PARTY"
				end				
			end	
		else
			if IsInRaid() then	
				channel = "RAID"
			else
				channel = "PARTY"
			end
		end	
	end	
	--AJM:Print( "CHANNEL", channel)
	if channel then
	AJM:DebugMessage("Sending command to group.", message, "channel", channel, nil)
		--AJM:Print("Sending command to group.", message, "channel", channel, nil)
			--AJM.COMMUNICATION_GROUP,
			AJM:SendCommMessage(
			AJM.COMMAND_PREFIX,
			message,
			channel,
			nil,
			AJM.COMMUNICATION_PRIORITY_ALERT
			)
			--AJM:Print("testChennel", AJM.COMMAND_PREFIX, channel, AJM.COMMUNICATION_PRIORITY_ALERT)	
			--return
	end
	--if the unit is not in the party then it unlikely did not get the party message,
	for characterName, characterOrder in JambaPrivate.Team.TeamList() do		
		if UnitInParty( Ambiguate( characterName, "none" ) ) == false then				
			AJM:DebugMessage( "Toon not in party:", characterName)
			if IsCharacterOnline( characterName ) == true then
				AJM:DebugMessage("Sending command to others not in party/raid.", message, "WHISPER", characterName)	
				AJM:SendCommMessage(
				AJM.COMMAND_PREFIX,
				message,
				AJM.COMMUNICATION_WHISPER,
				characterName,
				AJM.COMMUNICATION_PRIORITY_ALERT
				)
				--AJM:Print("testWis", AJM.COMMAND_PREFIX, AJM.COMMUNICATION_WHISPER, characterName , AJM.COMMUNICATION_PRIORITY_ALERT)	
			end	
		end
	end	
end



-- Should this get removed at some point and use all comms on one channel???
-- WHISPER's don't work cross-realm but do work connected-realm so sending msg to masters would not send.
-- TODO: Maybe remove masters???, and fall back to everyone being the master?
-- Not really sure what to do so for now will keep with the master, and whisper them, 
-- if was to use party/raid then everyone will get the command and masters would not work. 

-- Send a command to the master.
local function CommandMaster( moduleName, commandName, ... )
    AJM:DebugMessage( "Command Master: ", moduleName, commandName, ... )
	-- Get the message to send.
	local message = CreateCommandToSend( moduleName, commandName, ... )
	-- Send the message to the master.
	local characterName = JambaPrivate.Team.GetMasterName()
		if IsCharacterOnline( characterName ) == true then
			AJM:DebugMessage("Sending command to others not in party/raid.", message, "WHISPER", characterName)	
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
			AJM:DebugMessage("Sending command to others not in party/raid.", message, "WHISPER", characterName)	
				AJM:SendCommMessage( 
				AJM.COMMAND_PREFIX,
				message,
				AJM.COMMUNICATION_WHISPER,
				characterName,
				AJM.COMMUNICATION_PRIORITY_ALERT
				)
		end	
end		

-- EbonyTest
-- hide offline player spam Not really the best way but it works, Maybe adding tick box's to set members offline? This should now work with elvUI?

local function SystemSpamFilter(frame, event, message)
	if( event == "CHAT_MSG_SYSTEM") then	
		if message:match(string.format(ERR_CHAT_PLAYER_NOT_FOUND_S, "(.+)")) then
			local SearchPlayerNotFound = gsub(ERR_CHAT_PLAYER_NOT_FOUND_S, "%%s", "(.+)")  -- Get from "No player named '%s' is currently playing."
			local _, _, characterName = strfind(message, SearchPlayerNotFound)
			if JambaApi.IsCharacterInTeam(characterName) == true then	
				--AJM:Print("player offline in team", characterName )
				if AJM.db.autoSetTeamOnlineorOffline == true then
					if IsCharacterOnline( characterName ) == true then
						JambaApi.setOffline( characterName, false )
						--AJM:Print("player offline in team", characterName )
					end
				end
				return true
			else
				--AJM:Print("player offline Not in team")
				return
			end
		end	
		if message:match(string.format(ERR_NOT_IN_RAID, "(.+)")) then
			return true
		end
	end		
    return false
end
ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", SystemSpamFilter)



-- Receive a command from another character.
function AJM:CommandReceived( prefix, message, distribution, sender )
    local characterName = JambaUtilities:AddRealmToNameIfMissing( sender )
	AJM:DebugMessage( "Command received: ", prefix, message, distribution, sender )
	--AJM:Print( "Command received: ", prefix, message, distribution, sender )
	-- Check if the command is for Jamba Communications.
	if prefix == AJM.COMMAND_PREFIX then
		--checks the char is in the team if not everyone can change settings and we do not want that
		if JambaPrivate.Team.IsCharacterInTeam( sender ) == true then
		    AJM:DebugMessage( "Sender is in team list." )
		   --automaic setting team members online.
			--AJM:Print("toonnonline", sender )
				if JambaPrivate.Team.GetCharacterOnlineStatus( characterName ) == false then
					--AJM:Print("Setting Toon online", distribution, sender, characterName )
					JambaApi.setOnline( characterName, true)
				end
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
			else
				AJM:DebugMessage( "Sender is NOT in team list." )
			end
	end
end

-------------------------------------------------------------------------------------------------------------
-- Jamba Communications API.  These methods should only be called by Jamba Core.
-------------------------------------------------------------------------------------------------------------

-- Send settings to all members of the current team.
local function SendSettings( moduleName, settings )
	-- Send a push settings command to all.
	--AJM:Print("test", moduleName, AJM.COMMAND_INTERNAL_SEND_SETTINGS, settings )
	CommandAll( moduleName, AJM.COMMAND_INTERNAL_SEND_SETTINGS, settings )
end

-- Command all members of the current team.
local function SendCommandAll( moduleName, commandName, ... )
	-- Send the command to all.
	CommandAll( moduleName, commandName, ... )
end

-- TODO: needs to be cleaned up at some point with other communication stuff

-- Command the master.
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
	--AJM.channelPollTimer = nil
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
	--TODO: Is this needed? as its already in a module??
	local k = GetRealmName()
	local realm = k:gsub( "%s+", "" )
	self.characterRealm = realm
	self.characterNameLessRealm = UnitName( "player" )
	self.characterName = self.characterNameLessRealm.."-"..self.characterRealm
	AJM.characterGUID = UnitGUID( "player" )
	-- End of needed:
	-- Register communications as a module.
	JambaPrivate.Core.RegisterModule( AJM, AJM.moduleName )
end
	
function AJM:OnEnable()
	--local hookSecure = true
	--AJM:RawHook( "ChatFrame_MessageEventHandler", true )
	AJM:RegisterEvent("GUILD_ROSTER_UPDATE")
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

function AJM:OnDisable()
	--AJM:CancelAllTimers()
end

function AJM:GUILD_ROSTER_UPDATE(event, ... )
	if AJM.db.useGuildComms == false then
		return
	end
	local numGuildMembers, numOnline, numOnlineAndMobile = GetNumGuildMembers()
	for index = 1, numGuildMembers do
		characterName,_,_,_,class,_,_,_,online,status,classFileName,_, _,isMobile = GetGuildRosterInfo(index)
		--AJM:Print("Name", fullName, "online", online )
		if online == false then 
			if AJM.db.autoSetTeamOnlineorOffline == true then
				if JambaApi.IsCharacterInTeam(characterName) == true and IsCharacterOnline( characterName ) == true then 	
					JambaApi.setOffline( characterName, false )
					--AJM:Print("player offline in team", characterName )
				end
			end	
		end
	end	
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
	JambaHelperSettings:CreateHeading( AJM.settingsControl, L["Team Online Check"], movingTop, false )--
	movingTop = movingTop - headingHeight	
	--[[
	AJM.settingsControl.checkBoxAssumeAlwaysOnline = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		column1Left, 
		movingTop, 
		L["Use Team List Offline Button"],
		AJM.CheckBoxAssumeAlwaysOnline
	)
		movingTop = movingTop - checkBoxHeight
	AJM.settingsControl.labelInformationAlwaysOnline = JambaHelperSettings:CreateContinueLabel( 
		AJM.settingsControl, 
		headingWidth, 
		column1Left, 
		movingTop,
		L["**Untick this to use the WIP Set Offline team List Set offline Button"]
	)
	--]]
	AJM.settingsControl.checkBoxAutoSetTeamOnlineorOffline = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		column1Left, 
		movingTop, 
		L["Auto Set Team Members On and Off Line"],
		AJM.CheckBoxAutoSetTeamOnlineorOffline
	)
	movingTop = movingTop - checkBoxHeight
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
	movingTop = movingTop - buttonHeight		
	AJM.settingsControl.checkBoxUseGuildComms = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		column1Left, 
		movingTop, 
		L["Use Guild Communications***"],
		AJM.CheckBoxUseGuildComms
	)
	movingTop = movingTop - checkBoxHeight
	AJM.settingsControl.labelInformationBNComms = JambaHelperSettings:CreateContinueLabel( 
		AJM.settingsControl, 
		headingWidth, 
		column1Left, 
		movingTop,
		L["*** EveryToon will be classed as online and needs to be in same guild!"]
	)
--[[	AJM.settingsControl.checkBoxShowChannel = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 		
		headingWidth, 		
		column1Left, 
		movingTop, 
		L["Show Online Channel Traffic (For Debugging Purposes)"],
		AJM.CheckBoxShowChannelClick
	)
]]
	movingTop = movingTop - checkBoxHeight		
	return movingTop	
end

function AJM:CheckBoxUseGuildComms( event, value )
	AJM.db.useGuildComms = value
	AJM:SettingsRefresh()
end

function AJM:CheckBoxBoostCommunication( event, value )
	AJM.db.boostCommunication = value
	AJM:SettingsRefresh()
end

function AJM:CheckBoxAssumeAlwaysOnline( event, value )
	AJM.db.assumeTeamAlwaysOnline = value
	AJM:SettingsRefresh()	
end

function AJM:CheckBoxAutoSetTeamOnlineorOffline( event, value )
	AJM.db.autoSetTeamOnlineorOffline = value
	AJM:SettingsRefresh()	
end

function AJM:BeforeJambaProfileChanged()	
end

function AJM:OnJambaProfileChanged()	
	AJM:SettingsRefresh()
end

function AJM:SettingsRefresh()	
--	AJM.settingsControl.checkBoxAssumeAlwaysOnline:SetValue( AJM.db.assumeTeamAlwaysOnline )
	AJM.settingsControl.checkBoxAutoSetTeamOnlineorOffline:SetValue( AJM.db.autoSetTeamOnlineorOffline )
	AJM.settingsControl.checkBoxBoostCommunication:SetValue( AJM.db.boostCommunication )
	AJM.settingsControl.checkBoxUseGuildComms:SetValue( AJM.db.useGuildComms )
end

-- Settings received.
function AJM:JambaSendSettings()
	SendSettings( AJM.moduleName, AJM.db )
end

-- Settings received.
function AJM:JambaOnSettingsReceived( characterName, settings )
	if characterName ~= AJM.characterName then
		-- Update the settings.
		AJM.db.assumeTeamAlwaysOnline = settings.assumeTeamAlwaysOnline
		AJM.db.autoSetTeamOnlineorOffline = settings.autoSetTeamOnlineorOffline
		AJM.db.boostCommunication = settings.boostCommunication
		AJM.db.useGuildComms = settings.useGuildComms
		-- Refresh the settings.
		AJM:SettingsRefresh()
		-- Tell the player.
		AJM:Print( L["Settings received from A."]( characterName ) )
		-- Tell the team?
		--AJM:JambaSendMessageToTeam( AJM.db.messageArea,  L["Settings received from A."]( characterName ), false )
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
JambaPrivate.Communications.SendCommandMaster = SendCommandMaster
JambaPrivate.Communications.SendCommandToon = SendCommandToon
JambaPrivate.Communications.AssumeTeamAlwaysOnline = AssumeTeamAlwaysOnline
