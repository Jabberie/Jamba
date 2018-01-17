--[[
Jamba - Jafula's Awesome Multi-Boxer Assistant
Copyright 2008 - 2018 Michael "Jafula" Miller
License: The MIT License
]]--

local MAJOR, MINOR = "JambaModule-1.0", 1
local JambaModule, oldMinor = LibStub:NewLibrary( MAJOR, MINOR )

if not JambaModule then 
	return 
end

-- Load libraries.
LibStub( "AceConsole-3.0" ):Embed( JambaModule )

-------------------------------------------------------------------------------------------------------------
-- Jamba Module Mixin Management.
-------------------------------------------------------------------------------------------------------------

-- A list of modules that embed this module.
JambaModule.embeddedModules = JambaModule.embeddedModules or {}

-- These methods are the embbedable methods.
local mixinMethods = {
	"JambaRegisterModule", "JambaModuleInitialize",
	"JambaSendCommandToTeam", "JambaSendCommandToMaster",
	"JambaSendMessageToTeam", "JambaSendCommandToToon",
	"JambaSendSettings", "JambaOnSettingsReceived",
	"JambaChatCommand",
	"JambaConfigurationGetSetting", "JambaConfigurationSetSetting",
} 

-- Embed all the embeddable methods into the target module.
function JambaModule:Embed( targetModule )
	for key, value in pairs( mixinMethods ) do
		targetModule[value] = self[value]
	end
	LibStub( "AceConsole-3.0" ):Embed( targetModule )
	self.embeddedModules[targetModule] = true
	return targetModule
end

-------------------------------------------------------------------------------------------------------------
-- Jamba Module Registration.
-------------------------------------------------------------------------------------------------------------

-- Register a module with Jamba.  Jamba needs modules to be registered in order to faciliate communications.
function JambaModule:JambaRegisterModule( moduleName )
	JambaPrivate.Core.RegisterModule( self, moduleName )
end

-------------------------------------------------------------------------------------------------------------
-- Jamba Communications.
-------------------------------------------------------------------------------------------------------------

-- Send settings to all available Jamba Team characters.
function JambaModule:JambaSendSettings()
	JambaPrivate.Core.SendSettings( self, self.db )
end

-- Send a command to all available Jamba Team characters.
function JambaModule:JambaSendCommandToTeam( commandName, ... )
	JambaPrivate.Core.SendCommandToTeam( self, commandName, ... )
end

-- Send a command to just the master character.
function JambaModule:JambaSendCommandToMaster( commandName, ... )
	JambaPrivate.Core.SendCommandToMaster( self, commandName, ... )
end

function JambaModule:JambaSendCommandToToon( characterName, commandName, ... )
	JambaPrivate.Core.SendCommandToToon( self, characterName, commandName, ... )
end

-- Send a message to the team.
function JambaModule:JambaSendMessageToTeam( areaName, message, suppressSender, ... )
	JambaPrivate.Message.SendMessage( areaName, message, suppressSender, ... )
end

-------------------------------------------------------------------------------------------------------------
-- Jamba Chat Commands.
-------------------------------------------------------------------------------------------------------------

-- Handle the chat command.
function JambaModule:JambaChatCommand( input )
    if not input or input:trim() == "" then
		JambaPrivate.SettingsFrame.Widget:Show()
		JambaPrivate.SettingsFrame.TreeGroupStatus.groups[self.parentDisplayName] = true
		JambaPrivate.SettingsFrame.WidgetTree:SelectByPath( self.parentDisplayName, self.moduleDisplayName )
		JambaPrivate.SettingsFrame.Tree.ButtonClick( nil, nil, self.moduleDisplayName, false)
    else
        LibStub( "AceConfigCmd-3.0" ):HandleCommand( self.chatCommand, self.moduleName, input )
    end    
end

-------------------------------------------------------------------------------------------------------------
-- Module initialization and settings management.
-------------------------------------------------------------------------------------------------------------

-- Initialise the module.
function JambaModule:JambaModuleInitialize( settingsFrame )
    -- Create the settings database supplying the settings values along with defaults.
    self.completeDatabase = LibStub( "AceDB-3.0" ):New( self.settingsDatabaseName, self.settings )
	self.db = self.completeDatabase.profile
	-- Create the settings.
	LibStub( "AceConfig-3.0" ):RegisterOptionsTable( self.moduleName, self:GetConfiguration() )
	self.settingsFrame = settingsFrame
	-- Register the chat command for this module.
	self:RegisterChatCommand( self.chatCommand, "JambaChatCommand" )
	-- Remember the characters name.
	-- If server has a space in realm name GetRealmName() will show space this will not work with blizzard API so we need to hack this to work --ebony
	--local _, k = UnitFullName("player")
	local k = GetRealmName()
	local realm = k:gsub( "%s+", "")
	self.characterRealm = realm
	self.characterNameLessRealm = UnitName( "player" ) 
	--self.characterName = UnitFullName( "player" )
	self.characterName = self.characterNameLessRealm.."-"..self.characterRealm
	--self.characterName = UnitFullName("player")
	self.characterGUID = UnitGUID( "player" )
	-- Register this module with Jamba.
	self:JambaRegisterModule( self.moduleName )
end

-- Get a settings value.
function JambaModule:JambaConfigurationGetSetting( key )
	return self.db[key[#key]]
end

-- Set a settings value.
function JambaModule:JambaConfigurationSetSetting( key, value )
	self.db[key[#key]] = value
end

-------------------------------------------------------------------------------------------------------------
-- Upgrade Library.
-------------------------------------------------------------------------------------------------------------

-- Upgrade all modules that are already using this library to use the newer version.
for targetModule, value in pairs( JambaModule.embeddedModules ) do
	JambaModule:Embed( targetModule )
end
