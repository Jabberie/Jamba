--[[
Jamba - Jafula's Awesome Multi-Boxer Assistant
Copyright 2008 - 2018 Michael "Jafula" Miller
License: The MIT License
]]--

-- Create the addon using AceAddon-3.0 and embed some libraries.
local AJM = LibStub( "AceAddon-3.0" ):NewAddon( 
	"JambaTaxi", 
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
AJM.moduleName = "Jamba-Taxi"
AJM.settingsDatabaseName = "JambaTaxiProfileDB"
AJM.chatCommand = "jamba-taxi"
local L = LibStub( "AceLocale-3.0" ):GetLocale( AJM.moduleName )
AJM.parentDisplayName = L["Toon"]
AJM.moduleDisplayName = L["Taxi"]

-- Settings - the values to store and their defaults for the settings database.
AJM.settings = {
	profile = {
		takeMastersTaxi = true,
		requestTaxiStop = true,
		changeTexiTime = 2,
		messageArea = JambaApi.DefaultMessageArea(),
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
				desc = L["Push the taxi settings to all characters in the team."],
				usage = "/jamba-taxi push",
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

AJM.COMMAND_TAKE_TAXI = "JambaTaxiTakeTaxi"
AJM.COMMAND_EXIT_TAXI = "JambaTaxiExitTaxi"
AJM.COMMAND_CLOSE_TAXI = "JambaCloseTaxi"

-------------------------------------------------------------------------------------------------------------
-- Messages module sends.
-------------------------------------------------------------------------------------------------------------

-- Taxi has been taken, no parameters.
AJM.MESSAGE_TAXI_TAKEN = "JambaTaxiTaxiTaken"

-------------------------------------------------------------------------------------------------------------
-- Addon initialization, enabling and disabling.
-------------------------------------------------------------------------------------------------------------

-- Initialise the module.
function AJM:OnInitialize()
	AJM.jambaTakesTaxi = false
	AJM.jambaLeavsTaxi = false
	-- Create the settings control.
	AJM:SettingsCreate()
	-- Initialse the JambaModule part of this module.
	AJM:JambaModuleInitialize( AJM.settingsControl.widgetSettings.frame )
	-- Populate the settings.
	AJM:SettingsRefresh()	
end

-- Called when the addon is enabled.
function AJM:OnEnable()
	-- Hook the TaketaxiNode function.
	AJM:SecureHook( "TakeTaxiNode" )
	AJM:SecureHook( "TaxiRequestEarlyLanding" )
	-- WoW API Events.
	AJM:RegisterEvent("TAXIMAP_CLOSED")
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
	local bottomOfInfo = AJM:SettingsCreateTaxi( JambaHelperSettings:TopOfSettings() )
	AJM.settingsControl.widgetSettings.content:SetHeight( -bottomOfInfo )
	-- Help
	local helpTable = {}
	JambaHelperSettings:CreateHelp( AJM.settingsControl, helpTable, AJM:GetConfiguration() )		
end

function AJM:SettingsPushSettingsClick( event )
	AJM:JambaSendSettings()
end

function AJM:SettingsCreateTaxi( top )
	local checkBoxHeight = JambaHelperSettings:GetCheckBoxHeight()
	local left = JambaHelperSettings:LeftOfSettings()
	local sliderHeight = JambaHelperSettings:GetSliderHeight()
	local headingHeight = JambaHelperSettings:HeadingHeight()
	local horizontalSpacing = JambaHelperSettings:GetHorizontalSpacing()
	local headingWidth = JambaHelperSettings:HeadingWidth( false )
	local halfWidthSlider = (headingWidth - horizontalSpacing) / 2
	local dropdownHeight = JambaHelperSettings:GetDropdownHeight()
	local verticalSpacing = JambaHelperSettings:GetVerticalSpacing()
	
	
	local movingTop = top
	JambaHelperSettings:CreateHeading( AJM.settingsControl, L["Taxi Options"], movingTop, false )
	movingTop = movingTop - headingHeight
	AJM.settingsControl.checkBoxTakeMastersTaxi = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		left, 
		movingTop,
		L["Take Teams Taxi"],
		AJM.SettingsToggleTakeTaxi,
		L["Take the same flight as the any team member (Other Team Members must have NPC Flight Master window open)."]
	)	
	movingTop = movingTop - headingHeight
	AJM.settingsControl.checkBoxrequestStop = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		left, 
		movingTop,
		L["Request Taxi Stop with Master"],
		AJM.SettingsTogglerequestStop
	)	
	movingTop = movingTop - headingHeight		
	movingTop = movingTop - headingHeight
	AJM.settingsControl.changeTexiTime = JambaHelperSettings:CreateSlider( 
		AJM.settingsControl, 
		halfWidthSlider, 
		left, 
		movingTop,
		L["Clones To Take Taxi After Master"]
	)		
	AJM.settingsControl.changeTexiTime:SetSliderValues( 0, 5, 0.5 )
	AJM.settingsControl.changeTexiTime:SetCallback( "OnValueChanged", AJM.SettingsChangeTaxiTimer )
	
	--movingTop = movingTop - halfWidthSlider
	movingTop = movingTop - sliderHeight - verticalSpacing
	AJM.settingsControl.dropdownMessageArea = JambaHelperSettings:CreateDropdown( 
		AJM.settingsControl, 
		headingWidth, 
		left, 
		movingTop, 
		L["Message Area"] 
	)
	AJM.settingsControl.dropdownMessageArea:SetList( JambaApi.MessageAreaList() )
	AJM.settingsControl.dropdownMessageArea:SetCallback( "OnValueChanged", AJM.SettingsSetMessageArea )
	movingTop = movingTop - dropdownHeight - verticalSpacing
	return movingTop	
end

function AJM:OnMessageAreasChanged( message )
	AJM.settingsControl.dropdownMessageArea:SetList( JambaApi.MessageAreaList() )
end

function AJM:SettingsSetMessageArea( event, value )
	AJM.db.messageArea = value
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleTakeTaxi( event, checked )
	AJM.db.takeMastersTaxi = checked
	AJM:SettingsRefresh()
end

--ebs
function AJM:SettingsTogglerequestStop( event, checked )
	AJM.db.requestTaxiStop = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsChangeTaxiTimer( event, value )
	AJM.db.changeTexiTime = tonumber( value )
	AJM:SettingsRefresh()
end



-- Settings received.
function AJM:JambaOnSettingsReceived( characterName, settings )	
	if characterName ~= AJM.characterName then
		-- Update the settings.
		AJM.db.takeMastersTaxi = settings.takeMastersTaxi
		AJM.db.requestTaxiStop = settings.requestTaxiStop
		AJM.db.changeTexiTime = settings.changeTexiTime
		AJM.db.messageArea = settings.messageArea
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
	AJM.settingsControl.checkBoxTakeMastersTaxi:SetValue( AJM.db.takeMastersTaxi )
	AJM.settingsControl.checkBoxrequestStop:SetValue( AJM.db.requestTaxiStop )
	AJM.settingsControl.dropdownMessageArea:SetValue( AJM.db.messageArea )
	AJM.settingsControl.changeTexiTime:SetValue( AJM.db.changeTexiTime )
end

-------------------------------------------------------------------------------------------------------------
-- JambaTaxi functionality.
-------------------------------------------------------------------------------------------------------------

-- Take a taxi.
local function TakeTaxi( sender, nodeName )
	-- If the take masters taxi option is on.
	if AJM.db.takeMastersTaxi == true then
		-- If the sender was not this character and is the master then...
		if sender ~= AJM.characterName then
			-- Find the index of the taxi node to fly to.
			local nodeIndex = nil
			for iterateNodes = 1, NumTaxiNodes() do
				if TaxiNodeName( iterateNodes ) == nodeName then
					nodeIndex = iterateNodes
					break
				end
			end	
			-- If a node index was found...
			if nodeIndex ~= nil then
				-- Send a message to any listeners that a taxi is being taken.
				AJM:SendMessage( AJM.MESSAGE_TAXI_TAKEN )
				-- Take a taxi.
				AJM.jambaTakesTaxi = true
				AJM:ScheduleTimer( "TakeTimedTaxi", AJM.db.changeTexiTime , nodeIndex )
				--GetNumRoutes( nodeIndex )
				--TakeTaxiNode( nodeIndex )
			else
				-- Tell the master that this character could not take the same flight.
				AJM:JambaSendMessageToTeam( AJM.db.messageArea,  L["I am unable to fly to A."]( nodeName ), false )
			end
		end
	end
end

function AJM.TakeTimedTaxi( event, nodeIndex, ...)
	if nodeIndex ~= nil then
		GetNumRoutes( nodeIndex )
		TakeTaxiNode( nodeIndex )
	end		
end

-- Called after the character has just taken a flight (hooked function).
function AJM:TakeTaxiNode( taxiNodeIndex )
	-- If the take masters taxi option is on.
	if AJM.db.takeMastersTaxi == true then
		-- Get the name of the node flown to.
		local nodeName = TaxiNodeName( taxiNodeIndex )
		if AJM.jambaTakesTaxi == false then
			-- Tell the other characters about the taxi.
			AJM:JambaSendCommandToTeam( AJM.COMMAND_TAKE_TAXI, nodeName )
		end
		AJM.jambaTakesTaxi = false
	end
end

local function LeaveTaxi ( sender )
	if AJM.db.requestTaxiStop == true then
		if sender ~= AJM.characterName then
			AJM.jambaLeavsTaxi = true
			TaxiRequestEarlyLanding()
			AJM:JambaSendMessageToTeam( AJM.db.messageArea,  L["I Have Requested a Stop From X"]( sender ), false )	
		end
	end	
end

function AJM.TaxiRequestEarlyLanding( sender )
	-- If the take masters taxi option is on.
	--AJM:Print("test")
	if AJM.db.requestTaxiStop == true then
		if UnitOnTaxi( "player" ) and CanExitVehicle() == true then
			if AJM.jambaLeavsTaxi == false then
				-- Send a message to any listeners that a taxi is being taken.
				AJM:JambaSendCommandToTeam ( AJM.COMMAND_EXIT_TAXI )
			end
		end
		AJM.jambaLeavsTaxi = false
	end
end

function AJM:TAXIMAP_CLOSED( event, ... )
	--AJM:Print("closeTaxiTwo", AJM.jambaTakesTaxi )
	if TaxiFrame_ShouldShowOldStyle() or FlightMapFrame:IsVisible() then
		AJM:JambaSendCommandToTeam ( AJM.COMMAND_CLOSE_TAXI )
	end	
end


local function CloseTaxiMapFrame()
	if AJM.jambaTakesTaxi == false then
		CloseTaxiMap()
	end
end

-- A Jamba command has been received.
function AJM:JambaOnCommandReceived( characterName, commandName, ... )
	if characterName ~= self.characterName then
		-- If the command was to take a taxi...
		if commandName == AJM.COMMAND_TAKE_TAXI then
			-- If not already on a taxi...
			if not UnitOnTaxi( "player" ) then
				-- And if the taxi frame is open...
				-- 7.0.3 Added support for FlightMapFrame for legion flightMastrers. --ebony 
				if TaxiFrame_ShouldShowOldStyle() == true then
					if TaxiFrame:IsVisible() then
						TakeTaxi( characterName, ... )
					end
				else
					if FlightMapFrame:IsVisible() then
						TakeTaxi( characterName, ... )
					end	
				end
			end
		end
		if commandName == AJM.COMMAND_EXIT_TAXI then
			if UnitOnTaxi ( "player") then
				LeaveTaxi ( characterName, ... )
			end
		end
		if commandName == AJM.COMMAND_CLOSE_TAXI then
			CloseTaxiMapFrame()
		end	
	end
end

JambaApi.Taxi = {}
JambaApi.Taxi.MESSAGE_TAXI_TAKEN = AJM.MESSAGE_TAXI_TAKEN
