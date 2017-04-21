--[[
Jamba - Jafula's Awesome Multi-Boxer Assistant
Copyright 2008 - 2017 Michael "Jafula" Miller
License: The MIT License

This is was made by Ebony with the idea from Hydra
]]--

-- Create the addon using AceAddon-3.0 and embed some libraries.
local AJM = LibStub( "AceAddon-3.0" ):NewAddon( 
	"JambaMount", 
	"JambaModule-1.0", 
	"AceConsole-3.0", 
	"AceEvent-3.0",
	"AceHook-3.0",
	"AceTimer-3.0"
)

-- Get the Jamba Utilities Library.
local JambaUtilities = LibStub:GetLibrary( "JambaUtilities-1.0" )
local JambaHelperSettings = LibStub:GetLibrary( "JambaHelperSettings-1.0" )

--  Constants and Locale for this module.
AJM.moduleName = "Jamba-Mount"
AJM.settingsDatabaseName = "JambaMountProfileDB"
AJM.chatCommand = "jamba-mount"
local L = LibStub( "AceLocale-3.0" ):GetLocale( AJM.moduleName )
AJM.parentDisplayName = L["Toon"]
AJM.moduleDisplayName = L["Mount"]

-- Settings - the values to store and their defaults for the settings database.
AJM.settings = {
	profile = {
		mountWithTeam = true,
		dismountWithTeam = true,
		dismountWithMaster = true,
		mountInRange = false,
		--mountName = nil,
		--messageArea = JambaApi.DefaultMessageArea(),
		warningArea = JambaApi.DefaultWarningArea()
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
				desc = L["Push the Mount settings to all characters in the team."],
				usage = "/jamba-mount push",
				get = false,
				set = "JambaSendSettings",
				order = 4,
				guiHidden = true,
			},
		},
	}
	return configuration
end

-------------------------------------------------------------------------------------------------------------
-- Command this module sends.
-------------------------------------------------------------------------------------------------------------

AJM.COMMAND_MOUNT_ME = "JambaMountMe"
AJM.COMMAND_MOUNT_DISMOUNT = "JambaMountDisMount"

-------------------------------------------------------------------------------------------------------------
-- Messages module sends.
-------------------------------------------------------------------------------------------------------------


-------------------------------------------------------------------------------------------------------------
-- Addon initialization, enabling and disabling.
-------------------------------------------------------------------------------------------------------------

-- Initialise the module.
function AJM:OnInitialize()
	-- Create the settings control.
	AJM:SettingsCreate()
	-- Initialse the JambaModule part of this module.
	AJM:JambaModuleInitialize( AJM.settingsControl.widgetSettings.frame )
	-- Populate the settings.
	AJM:SettingsRefresh()
	AJM.MountFromTeamMember	= false
	AJM.castingMount = nil
end

-- Called when the addon is enabled.
function AJM:OnEnable()
--	AJM:RegisterEvent("PLAYER_REGEN_ENABLED")
--	AJM:RegisterEvent("PLAYER_REGEN_DISABLED")	
	AJM:RegisterEvent("UNIT_SPELLCAST_START")
	AJM:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	AJM:RegisterEvent("UNIT_AURA")
	AJM:RegisterMessage( JambaApi.MESSAGE_MESSAGE_AREAS_CHANGED, "OnMessageAreasChanged" )
	
end

-- Called when the addon is disabled.
function AJM:OnDisable()
	-- AceHook-3.0 will tidy up the hooks for us. 
end

function AJM:SettingsCreate()
	AJM.settingsControl = {}
	-- Create the settings panel.
	JambaHelperSettings:CreateSettings( 
		AJM.settingsControl, 
		AJM.moduleDisplayName, 
		AJM.parentDisplayName, 
		AJM.SettingsPushSettingsClick 
	)
	local bottomOfInfo = AJM:SettingsCreateMount( JambaHelperSettings:TopOfSettings() )
	AJM.settingsControl.widgetSettings.content:SetHeight( -bottomOfInfo )
	-- Help
	local helpTable = {}
	JambaHelperSettings:CreateHelp( AJM.settingsControl, helpTable, AJM:GetConfiguration() )		
end

function AJM:SettingsPushSettingsClick( event )
	AJM:JambaSendSettings()
end

function AJM:SettingsCreateMount( top )
	local checkBoxHeight = JambaHelperSettings:GetCheckBoxHeight()
	local left = JambaHelperSettings:LeftOfSettings()
	local headingHeight = JambaHelperSettings:HeadingHeight()
	local headingWidth = JambaHelperSettings:HeadingWidth( false )
	local dropdownHeight = JambaHelperSettings:GetDropdownHeight()
	local verticalSpacing = JambaHelperSettings:GetVerticalSpacing()
	local movingTop = top
	JambaHelperSettings:CreateHeading( AJM.settingsControl, L["Mount Options"], movingTop, false )
	movingTop = movingTop - headingHeight
	AJM.settingsControl.checkBoxMountWithTeam = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		left, 
		movingTop,
		L["Mount with Team"],
		AJM.SettingsToggleMountWithTeam
	)	
	movingTop = movingTop - headingHeight
	AJM.settingsControl.checkBoxDismountWithTeam = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		left, 
		movingTop,
		L["Dismount with Team"],
		AJM.SettingsToggleDisMountWithTeam,
		L["Dismount with Character That Dismount"]
	)	
	movingTop = movingTop - headingHeight
	AJM.settingsControl.checkBoxDismountWithMaster = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		left, 
		movingTop,
		L["Only Dismount's from Master"],
		AJM.SettingsToggleDisMountWithMaster,
		L["Only Dismount's from Master character."]
	)	
	movingTop = movingTop - headingHeight
	AJM.settingsControl.checkBoxMountInRange = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		left, 
		movingTop,
		L["Only Mount when in Range"],
		AJM.SettingsToggleMountInRange,
		L["Only Works In a party!"]
	)
--	movingTop = movingTop - checkBoxHeight
--	AJM.settingsControl.dropdownMessageArea = JambaHelperSettings:CreateDropdown( 
--		AJM.settingsControl, 
--		headingWidth, 
--		left, 
--		movingTop, 
--		L["Message Area"] 
--	)
--	AJM.settingsControl.dropdownMessageArea:SetList( JambaApi.MessageAreaList() )
--	AJM.settingsControl.dropdownMessageArea:SetCallback( "OnValueChanged", AJM.SettingsSetMessageArea )
	movingTop = movingTop - checkBoxHeight
	AJM.settingsControl.dropdownWarningArea = JambaHelperSettings:CreateDropdown( 
		AJM.settingsControl, 
		headingWidth, 
		left, 
		movingTop, 
		L["Send Warning Area"] 
	)
	AJM.settingsControl.dropdownWarningArea:SetList( JambaApi.MessageAreaList() )
	AJM.settingsControl.dropdownWarningArea:SetCallback( "OnValueChanged", AJM.SettingsSetWarningArea )
	
	
	
	movingTop = movingTop - dropdownHeight - verticalSpacing
	return movingTop	
end

function AJM:OnMessageAreasChanged( message )
	--AJM.settingsControl.dropdownMessageArea:SetList( JambaApi.MessageAreaList() )
	AJM.settingsControl.dropdownWarningArea:SetList( JambaApi.MessageAreaList() )
end

function AJM:SettingsSetWarningArea( event, value )
	AJM.db.warningArea = value
	AJM:SettingsRefresh()
end

--function AJM:SettingsSetMessageArea( event, value )
--	AJM.db.messageArea = value
--	AJM:SettingsRefresh()
--end

function AJM:SettingsToggleMountWithTeam( event, checked )
	AJM.db.mountWithTeam = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleDisMountWithTeam( event, checked )
	AJM.db.dismountWithTeam = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleDisMountWithMaster( event, checked )
	AJM.db.dismountWithMaster = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleMountInRange( event, checked )
	AJM.db.mountInRange = checked
	AJM:SettingsRefresh()
end

-- Settings received.
function AJM:JambaOnSettingsReceived( characterName, settings )	
	if characterName ~= AJM.characterName then
		-- Update the settings.
		AJM.db.mountWithTeam = settings.mountWithTeam
		AJM.db.dismountWithTeam = settings.dismountWithTeam
		AJM.db.dismountWithMaster = settings.dismountWithMaster
		AJM.db.mountInRange = settings.mountInRange
		AJM.db.messageArea = settings.messageArea
		AJM.db.warningArea = settings.warningArea
		-- Refresh the settings.
		AJM:SettingsRefresh()
		-- Tell the player.
		AJM:Print( L["Settings received from A."]( characterName ) )
		-- Tell the team?
		--AJM:JambaSendMessageToTeam( AJM.db.messageArea,  L["Settings received from A."]( characterName ), false )
	end
end

function AJM:BeforeJambaProfileChanged()	
end

function AJM:OnJambaProfileChanged()	
	AJM:SettingsRefresh()
end

function AJM:SettingsRefresh()
	AJM.settingsControl.checkBoxMountWithTeam:SetValue( AJM.db.mountWithTeam )
	AJM.settingsControl.checkBoxDismountWithTeam:SetValue( AJM.db.dismountWithTeam )
	AJM.settingsControl.checkBoxDismountWithMaster:SetValue( AJM.db.dismountWithMaster )
	AJM.settingsControl.checkBoxMountInRange:SetValue( AJM.db.mountInRange )
	--AJM.settingsControl.dropdownMessageArea:SetValue( AJM.db.messageArea )
	AJM.settingsControl.dropdownWarningArea:SetValue( AJM.db.warningArea )
	-- Set state.
	--AJM.settingsControl.checkBoxMountWithTeam:SetDisabled( not AJM.db.mountWithTeam )
	AJM.settingsControl.checkBoxDismountWithTeam:SetDisabled( not AJM.db.mountWithTeam )
	AJM.settingsControl.checkBoxDismountWithMaster:SetDisabled( not AJM.db.dismountWithTeam or not AJM.db.mountWithTeam )
	AJM.settingsControl.checkBoxMountInRange:SetDisabled( not AJM.db.mountWithTeam )
end

-------------------------------------------------------------------------------------------------------------
-- JambaMount functionality.
-------------------------------------------------------------------------------------------------------------

function AJM:UNIT_SPELLCAST_START(event, unitID, name, rank, lineID, spellID, ...  )
	--AJM:Print("Looking for Spells.", unitID, spellID, name)
	--AJM.castingMount = nil
	-- No Need to send the casting of mount again to team.
	if AJM.MountFromTeamMember == true then
		return
	end	
	if unitID == "player" and UnitAffectingCombat("player") == false then
		local mountIDs = C_MountJournal.GetMountIDs()	
		for i = 1, #mountIDs do
			--local name , id, icon, active = C_MountJournal.GetMountInfoByID(i)
			local creatureName,mountSpellID,_,_,_,_,_,_,_,hideOnChar,isCollected,mountID = C_MountJournal.GetMountInfoByID(mountIDs[i])
			if (isCollected and hideOnChar ~= true) then
				--AJM:Print("MountName", name, spellID, "Checks", creatureName, mountSpellID)
				if spellID == mountSpellID then
					--AJM:Print("SendtoTeam", "name", creatureName , "id", mountID)
					if IsShiftKeyDown() == false then
						AJM.castingMount = creatureName
						AJM:JambaSendCommandToTeam( AJM.COMMAND_MOUNT_ME, spellID, mountID )
						break	
					end	
				end
			end	
		end	
	end
end

function AJM:UNIT_SPELLCAST_SUCCEEDED(event, unitID, spell, rank, lineID, spellID, ... )
	if unitID ~= "player" then
        return
    end
	--AJM:Print("Looking for Spells Done", spell, AJM.castingMount)
	if spell == AJM.castingMount then
		--AJM:Print("test", spell)
		AJM.isMounted = spell
		--AJM:Print("Mounted!", AJM.isMounted)
	end
	
end

function AJM:UNIT_AURA(event, unitID, ... )
	--AJM:Print("tester", unitID, AJM.isMounted)
	if unitID ~= "player" or AJM.isMounted == nil or AJM.db.dismountWithTeam == false then
        return
    end
	--AJM:Print("tester", unitID, AJM.isMounted)
	if not UnitBuff( unitID, AJM.isMounted) then
		--AJM:Print("I have Dismounted - Send to team!", AJM.isMounted)
		if AJM.db.dismountWithMaster == true then
			if JambaApi.IsCharacterTheMaster( AJM.characterName ) == true then
				if IsShiftKeyDown() == false then	
					--AJM:Print("test")
					AJM:JambaSendCommandToTeam( AJM.COMMAND_MOUNT_DISMOUNT )
					AJM.MountFromTeamMember = false
				end		
			else	
				--AJM:Print("test1")
				return
			end
		else
			AJM:JambaSendCommandToTeam( AJM.COMMAND_MOUNT_DISMOUNT )
		end		
	end
end

function AJM:TeamMountStart(characterName, spellID, mountID)
	--This checks the toon is not moving and if so adds a timmer before it mounts! (ebony magic :D)
	local moving = GetUnitSpeed("Player")
	--AJM:Print("moving", moving, spellID, mountID )
	if moving == 0 then
		--AJM:Print("mount?", spellID, mountID )
		AJM:TeamMount(characterName, spellID, mountID)
	else
		--AJM:Print("player Moving try agian in 1..." )
		AJM:ScheduleTimer( "TeamMountStart", 1, nil, spellID, mountID )	
	end	
end


function AJM:TeamMount(characterName, spellID, mountID)
	--AJM:Print("testTeamMount", characterName, name, mountID )
	--mount with team truned off.
	if UnitAffectingCombat("player") == true then
		AJM:JambaSendMessageToTeam( AJM.db.warningArea, L["I am Unable To Mount In Combat."], false )
		return
	end	
	if AJM.db.mountWithTeam == false then
		return
	end
	-- already mounted.
	if IsMounted() then 
		return
	end
	-- Checks if character is in range.
	if AJM.db.mountInRange == true then
		if UnitIsVisible(Ambiguate(characterName, "none") ) == false then
			--AJM:Print("UnitIsNotVisible", characterName)
			return	
		end
	end
	-- Checks done now the fun stuff!
	--Do i have the same mount as master?
	hasMount = false
	local creatureName, spellID, icon, active, isUsable, sourceType, isFavorite, isFactionSpecific, faction, hideOnChar, isCollected, mountID = C_MountJournal.GetMountInfoByID(mountID)
	if isUsable == true then
		--AJM:Print("i have this Mount", creatureName)
		hasMount = true
		mount = mountID
	else
		--AJM:Print("i Do not have Mount", creatureName)
		for i = 1, C_MountJournal.GetNumMounts() do
		local creatureName, spellID, icon, active, isUsable, sourceType, isFavorite, isFactionSpecific, faction, hideOnChar, isCollected, mountID = C_MountJournal.GetMountInfoByID(i)
			--AJM:Print("looking for a mount i can use", i)
			if isUsable == true then
				mount = mountID
				hasMount = true
				break
			end	
		end
	end		
	
--AJM:Print("test1420", mount, name)
	-- for unsupported mounts.	
	if hasMount == true then
		--AJM:Print("test14550", mount, name )
		if name == "Random" then
			C_MountJournal.SummonByID(0)
		else 
			--AJM:Print("test1054" )
			C_MountJournal.SummonByID( mount )
		end
		if IsMounted() == false then	
			AJM:ScheduleTimer( "AmNotMounted", 2 )
		end		
	end	
end

function AJM:AmNotMounted()
	if IsMounted() == false then
		--AJM:Print("test")
		AJM:JambaSendMessageToTeam( AJM.db.warningArea, L["I am unable to Mount."], false )
	end	
end



-- A Jamba command has been received.
function AJM:JambaOnCommandReceived( characterName, commandName, ... )
	if characterName ~= self.characterName then
		if commandName == AJM.COMMAND_MOUNT_ME then
			--AJM:Print("command")	
			AJM:TeamMountStart( characterName, ... )
			AJM.MountFromTeamMember = true
		end
		-- Dismount if mounted!
		if commandName == AJM.COMMAND_MOUNT_DISMOUNT then
			--AJM:Print("time to Dismount")
			if IsMounted() then
				AJM.MountFromTeamMember = false
				Dismount()
			end	
		end
	end
end
