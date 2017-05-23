--[[
Jamba - Jafula's Awesome Multi-Boxer Assistant
Copyright 2008 - 2017 Michael "Jafula" Miller
License: The MIT License


]]--

-- The global private table for Jamba.
JambaPrivate = {}
JambaPrivate.Core = {}
JambaPrivate.Communications = {}
JambaPrivate.Message = {}
JambaPrivate.Team = {}
JambaPrivate.Tag = {}

-- The global public API table for Jamba.
JambaApi = {}EMA

local EMA = LibStub( "AceAddon-3.0" ):NewAddon( 
	"JambaCore", 
	"AceConsole-3.0" 
)

-- JambaCore is not a module, but the same naming convention for these values is convenient.
EMA.moduleName = "Jamba-Core"
local L = LibStub( "AceLocale-3.0" ):GetLocale( EMA.moduleName )
EMA.moduleDisplayName = L["Jamba"]
EMA.settingsDatabaseName = "JambaCoreProfileDB"
EMA.parentDisplayName = "Jamba"
EMA.chatCommand = "jamba"
EMA.teamModuleName = "Jamba-Team"

-- Load libraries.
local JambaUtilities = LibStub:GetLibrary( "JambaUtilities-1.0" )
local JambaHelperSettings = LibStub:GetLibrary( "JambaHelperSettings-1.0" )
local AceGUI = LibStub("AceGUI-3.0")

-- Create frame for Jamba Settings.
JambaPrivate.SettingsFrame = {}
JambaPrivate.SettingsFrame.Widget = AceGUI:Create( "JambaWindow" )
--JambaPrivate.SettingsFrame.Widget = AceGUI:Create( "Frame" )
JambaPrivate.SettingsFrame.Widget:SetTitle( L["Jamba"].." "..L["Version"] )
JambaPrivate.SettingsFrame.Widget:SetStatusText(L["The Awesome Multi-Boxer Assistant"])
JambaPrivate.SettingsFrame.Widget:SetWidth(800)
JambaPrivate.SettingsFrame.Widget:SetHeight(650)
JambaPrivate.SettingsFrame.Widget:SetLayout( "Fill" )
JambaPrivate.SettingsFrame.WidgetTree = AceGUI:Create( "TreeGroup" )
JambaPrivate.SettingsFrame.TreeGroupStatus = { treesizable = false, groups = {} }
JambaPrivate.SettingsFrame.WidgetTree:SetStatusTable( JambaPrivate.SettingsFrame.TreeGroupStatus )
JambaPrivate.SettingsFrame.WidgetTree:EnableButtonTooltips( false )
JambaPrivate.SettingsFrame.Widget:AddChild( JambaPrivate.SettingsFrame.WidgetTree )
JambaPrivate.SettingsFrame.WidgetTree:SetLayout( "Fill" )

function EMA:OnEnable()
	if EMA.db.showStartupMessage4000 then
		JambaStartupMessageFrameTitle:SetText( L["Jamba"].." "..GetAddOnMetadata("Jamba", "version").." - "..L["Full Change Log"] )
		--JambaStartupMessageFrame:Show()
		EMA.db.showStartupMessage4000 = false
	end
end

function EMA:OnDisable()
end

function EMA:ShowChangeLog()
	JambaStartupMessageFrameTitle:SetText( L["Jamba"].." "..GetAddOnMetadata("Jamba", "version").." - "..L["Full Change Log"] )
	JambaStartupMessageFrame:Show()
end	

local function JambaSettingsTreeSort( a, b )
	local aText = ""
	local bText = ""
	local aJambaOrder = 0
	local bJambaOrder = 0
	if a ~= nil then
		aText = a.text
		aJambaOrder = a.jambaOrder
	end	
	if b ~= nil then
		bText = b.text
		bJambaOrder = b.jambaOrder
	end
	if aText == L["Jamba"] or bText == L["Jamba"] then
		if aText == L["Jamba"] then
			return true
		end
		if bText == L["Jamba"] then
			return false
		end
	end
	if aJambaOrder == bJambaOrder then
		return aText < bText
	end
	return aJambaOrder < bJambaOrder
end

local function JambaTreeGroupTreeGetParent( parentName )
	local parent
	for index, tableInfo in ipairs( JambaPrivate.SettingsFrame.Tree.Data ) do
		if tableInfo.value == parentName then
			parent = tableInfo			
		end
	end
	return parent
end

local function GetTreeGroupParentJambaOrder( parentName )
	local order = 1000
	if parentName == L["Team"] then
		order = 10
	end
	if parentName == L["Quest"] then
		order = 20
	end
	if parentName == L["Merchant"] then
		order = 30
	end
	if parentName == L["Interaction"] then
		order = 40
	end
	if parentName == L["Combat"] then
		order = 50
	end
	if parentName == L["Toon"] then
		order = 60
	end
	if parentName == L["Chat"] then
		order = 70
	end
	if parentName == L["Macro"] then
		order = 80
	end
	if parentName == L["Profiles"] then
		order = 90
	end
	if parentName == L["Advanced"] then
		order = 100
	end
	return order
end

local function GetTreeGroupParentIcon( parentName )
	local icon = "Interface\\Icons\\Temp"
	if parentName == L["Team"] then
		icon = "Interface\\Icons\\INV_Misc_FireDancer_01"
	end
	if parentName == L["Quest"] then
		icon = "Interface\\Icons\\Achievement_Quests_Completed_08"
	end
	if parentName == L["Merchant"] then
		icon = "Interface\\Icons\\INV_Drink_05"
	end
	if parentName == L["Interaction"] then
		icon = "Interface\\Icons\\Achievement_Reputation_01"
	end
	if parentName == L["Combat"] then
		icon = "Interface\\Icons\\INV_Sword_11"
	end
	if parentName == L["Toon"] then
		icon = "Interface\\Icons\\Achievement_Character_Bloodelf_Female"
	end
	if parentName == L["Chat"] then
		icon = "Interface\\Icons\\Ability_Warrior_RallyingCry"
	end
	if parentName == L["Macro"] then
		icon = "Interface\\Icons\\Spell_Holy_Dizzy"
	end
	if parentName == L["Profiles"] then
		icon = "Interface\\Icons\\INV_Misc_Dice_01"
	end
	if parentName == L["Advanced"] then
		icon = "Interface\\Icons\\Trade_Engineering"
	end
	return icon
end

local function JambaAddModuleToSettings( childName, parentName, moduleFrame, tabGroup )
	local parent = JambaTreeGroupTreeGetParent( parentName )
	if parent == nil then
		local order = GetTreeGroupParentJambaOrder( parentName )
		table.insert( JambaPrivate.SettingsFrame.Tree.Data, { value = parentName, text = parentName, jambaOrder = order, icon = GetTreeGroupParentIcon( parentName ) } )
		parent = JambaTreeGroupTreeGetParent( parentName )
	end
	if parent.children == nil then
		parent.children = {}
	end	
	table.insert( parent.children, { value = childName, text = childName } )
	table.sort( JambaPrivate.SettingsFrame.Tree.Data, JambaSettingsTreeSort )
	JambaPrivate.SettingsFrame.Tree.ModuleFrames[childName] = moduleFrame
	JambaPrivate.SettingsFrame.Tree.ModuleFramesTabGroup[childName] = tabGroup
end

local function JambaModuleSelected( tree, event, treeValue, selected )
	local parentValue, value = strsplit( "\001", treeValue )
	if tree == nil and event == nil then
		-- Came from chat command.
		value = treeValue
	end
	JambaPrivate.SettingsFrame.Widget:Show()
	if JambaPrivate.SettingsFrame.Tree.CurrentChild ~= nil then
		JambaPrivate.SettingsFrame.Tree.CurrentChild.frame:Hide()
		JambaPrivate.SettingsFrame.Tree.CurrentChild = nil
	end
	for moduleValue, moduleFrame in pairs( JambaPrivate.SettingsFrame.Tree.ModuleFrames ) do	
		if moduleValue == value then
			moduleFrame:SetParent( JambaPrivate.SettingsFrame.WidgetTree )
			moduleFrame:SetWidth( JambaPrivate.SettingsFrame.WidgetTree.content:GetWidth() or 0 )
			moduleFrame:SetHeight( JambaPrivate.SettingsFrame.WidgetTree.content:GetHeight() or 0 )
			moduleFrame.frame:SetAllPoints() -- JambaPrivate.SettingsFrame.WidgetTree.content 
			moduleFrame.frame:Show()	
			JambaPrivate.SettingsFrame.Tree.CurrentChild = moduleFrame
			-- Hacky hack hack.
			if JambaPrivate.SettingsFrame.Tree.ModuleFramesTabGroup[value] ~= nil then
				JambaPrivate.SettingsFrame.Tree.ModuleFramesTabGroup[value]:SelectTab( "options" )
			else
				-- Hacky hack hack.
				LibStub( "AceConfigDialog-3.0" ):Open( EMA.moduleName.."-Profiles", moduleFrame )
			end			
			return
		end
	end
end

JambaPrivate.SettingsFrame.Tree = {}
JambaPrivate.SettingsFrame.Tree.Data = {}
JambaPrivate.SettingsFrame.Tree.ModuleFrames = {}
JambaPrivate.SettingsFrame.Tree.ModuleFramesTabGroup = {}
JambaPrivate.SettingsFrame.Tree.CurrentChild = nil
JambaPrivate.SettingsFrame.Tree.Add = JambaAddModuleToSettings
JambaPrivate.SettingsFrame.Tree.ButtonClick = JambaModuleSelected
JambaPrivate.SettingsFrame.WidgetTree:SetTree( JambaPrivate.SettingsFrame.Tree.Data )
JambaPrivate.SettingsFrame.WidgetTree:SetCallback( "OnClick", JambaPrivate.SettingsFrame.Tree.ButtonClick )
JambaPrivate.SettingsFrame.Widget:Hide()
table.insert( UISpecialFrames, "JambaSettingsWindowsFrame" )

-- Settings - the values to store and their defaults for the settings database.
EMA.settings = {
	profile = {
		showMinimapIcon = true,
		showStartupMessage4000 = true,
	},
}

-- Configuration.
local function GetConfiguration()
	local configuration = {
		name = "Jamba",
		handler = EMA,
		type = 'group',
		childGroups  = "tab",
		get = "ConfigurationGetSetting",
		set = "ConfigurationSetSetting",
		args = {	
			push = {
				type = "input",
				name = L["Push Settings"],
				desc = L["Push Settings"],
				usage = "/jamba push",
				get = false,
				set = "SendSettingsAllModules",
				order = 4,
				guiHidden = true,
			},
			resetsettingsframe = {
				type = "input",
				name = L["Reset Settings Frame"],
				desc = L["Reset Settings Frame"],
				usage = "/jamba resetsettingsframe",
				get = false,
				set = "ResetSettingsFrame",
				order = 5,
				guiHidden = true,				
			},
		},
	}
	return configuration
end

-- Get a settings value.
function EMA:ConfigurationGetSetting( key )
	return EMA.db[key[#key]]
end

-- Set a settings value.
function EMA:ConfigurationSetSetting( key, value )
	EMA.db[key[#key]] = value
end

local function DebugMessage( ... )
	EMA:Print( ... )
end

-------------------------------------------------------------------------------------------------------------
-- Module management.
-------------------------------------------------------------------------------------------------------------

-- Register a Jamba module.
local function RegisterModule( moduleAddress, moduleName )
	if EMA.registeredModulesByName == nil then
		EMA.registeredModulesByName = {}
	end
	if EMA.registeredModulesByAddress == nil then
		EMA.registeredModulesByAddress = {}
	end
	EMA.registeredModulesByName[moduleName] = moduleAddress
	EMA.registeredModulesByAddress[moduleAddress] = moduleName
end

-------------------------------------------------------------------------------------------------------------
-- Settings sending and receiving.
-------------------------------------------------------------------------------------------------------------

-- Send the settings for the module specified (using its address) to other Jamba Team characters.
local function SendSettings( moduleAddress, settings )
	-- Get the name of the module.
	local moduleName = EMA.registeredModulesByAddress[moduleAddress]
	-- Send the settings identified by the module name.
	JambaPrivate.Communications.SendSettings( moduleName, settings )
end

-- Settings are received, pass them to the relevant module.
local function OnSettingsReceived( sender, moduleName, settings )
	sender = JambaUtilities:AddRealmToNameIfMissing( sender )
	--EMA:Print("onsettings", sender, moduleName )
	-- Get the address of the module.
	local moduleAddress = EMA.registeredModulesByName[moduleName]	
	-- can not receive a message from a Module not Loaded so ignore it. Better tell them its not loaded --ebony.
	if moduleAddress == nil then 
		EMA:Print(L["Module Not Loaded:"], moduleName)
		return
	else
	-- loaded? Pass the module its settings.
		moduleAddress:JambaOnSettingsReceived( sender, settings )
	end	
end

function EMA:SendSettingsAllModules()
	EMA:Print( "Sending settings for all modules." )
	for moduleName, moduleAddress in pairs( EMA.registeredModulesByName ) do
		EMA:Print( "Sending settings for: ", moduleName )
		moduleAddress:JambaSendSettings()
	end
end


-------------------------------------------------------------------------------------------------------------
-- Commands sending and receiving.
-------------------------------------------------------------------------------------------------------------

-- Send a command for the module specified (using its address) to other Jamba Team characters.
local function SendCommandToTeam( moduleAddress, commandName, ... )
	-- Get the name of the module.
	local moduleName = EMA.registeredModulesByAddress[moduleAddress]
	-- Send the command identified by the module name.
	JambaPrivate.Communications.SendCommandAll( moduleName, commandName, ... )
end

-- Send a command for the module specified (using its address) to the master character.
local function SendCommandToMaster( moduleAddress, commandName, ... )
	-- Get the name of the module.
	local moduleName = EMA.registeredModulesByAddress[moduleAddress]
	-- Send the command identified by the module name.
	JambaPrivate.Communications.SendCommandMaster( moduleName, commandName, ... )
end

local function SendCommandToToon( moduleAddress, characterName, commandName, ... )
	-- Get the name of the module.
	local moduleName = EMA.registeredModulesByAddress[moduleAddress]
	-- Send the command identified by the module name.
	JambaPrivate.Communications.SendCommandToon( moduleName, characterName, commandName, ... )
end

-- A command is received, pass it to the relevant module.
local function OnCommandReceived( sender, moduleName, commandName, ... )
	sender = JambaUtilities:AddRealmToNameIfMissing( sender )
	-- Get the address of the module.
	local moduleAddress = EMA.registeredModulesByName[moduleName]
	-- Pass the module its settings.
	moduleAddress:JambaOnCommandReceived( sender, commandName, ... )
end

-------------------------------------------------------------------------------------------------------------
-- Jamba Core Profile Support.
-------------------------------------------------------------------------------------------------------------

function EMA:FireBeforeProfileChangedEvent()
	for moduleName, moduleAddress in pairs( EMA.registeredModulesByName ) do
		if moduleName ~= EMA.moduleName then		
			moduleAddress:BeforeJambaProfileChanged()
		end
	end
end

function EMA:CanChangeProfileForModule( moduleName )
	if (moduleName ~= EMA.moduleName) and (moduleName ~= EMA.teamModuleName) then		
		return true
	end
	return false
end

function EMA:FireOnProfileChangedEvent( moduleAddress )
	moduleAddress.db = moduleAddress.completeDatabase.profile
	moduleAddress:OnJambaProfileChanged()
end

function EMA:OnProfileChanged( event, database, newProfileKey, ... )
	EMA:Print( "Profile changed - iterating all modules." )
	EMA:FireBeforeProfileChangedEvent()
	-- Do the team module before all the others.
	local teamModuleAddress = EMA.registeredModulesByName[EMA.teamModuleName]
	EMA:Print( "Changing profile: ", EMA.teamModuleName )
	teamModuleAddress.completeDatabase:SetProfile( newProfileKey )
	EMA:FireOnProfileChangedEvent( teamModuleAddress )
	-- Do the other modules.
	for moduleName, moduleAddress in pairs( EMA.registeredModulesByName ) do
		if EMA:CanChangeProfileForModule( moduleName ) == true then		
			EMA:Print( "Changing profile: ", moduleName )
			moduleAddress.completeDatabase:SetProfile( newProfileKey )
			EMA:FireOnProfileChangedEvent( moduleAddress )
		end
	end
end

function EMA:OnProfileCopied( event, database, sourceProfileKey )
	EMA:Print( "Profile copied - iterating all modules." )
	EMA:FireBeforeProfileChangedEvent()
	-- Do the team module before all the others.
	local teamModuleAddress = EMA.registeredModulesByName[EMA.teamModuleName]
	EMA:Print( "Copying profile: ", EMA.teamModuleName )
	teamModuleAddress.completeDatabase:CopyProfile( sourceProfileKey, true )
	EMA:FireOnProfileChangedEvent( teamModuleAddress )	
	-- Do the other modules.
	for moduleName, moduleAddress in pairs( EMA.registeredModulesByName ) do
		if EMA:CanChangeProfileForModule( moduleName ) == true then		
			EMA:Print( "Copying profile: ", moduleName )
			moduleAddress.completeDatabase:CopyProfile( sourceProfileKey, true )
			EMA:FireOnProfileChangedEvent( moduleAddress )
		end
	end
end

function EMA:OnProfileReset( event, database )
	EMA:Print( "Profile reset - iterating all modules." )
	EMA:FireBeforeProfileChangedEvent()
	-- Do the team module before all the others.
	local teamModuleAddress = EMA.registeredModulesByName[EMA.teamModuleName]
	EMA:Print( "Resetting profile: ", EMA.teamModuleName )
	teamModuleAddress.completeDatabase:ResetProfile()
	EMA:FireOnProfileChangedEvent( teamModuleAddress )	
	-- Do the other modules.	
	for moduleName, moduleAddress in pairs( EMA.registeredModulesByName ) do
		if EMA:CanChangeProfileForModule( moduleName ) == true then		
			EMA:Print( "Resetting profile: ", moduleName )
			moduleAddress.completeDatabase:ResetProfile()
			EMA:FireOnProfileChangedEvent( moduleAddress )
		end
	end
end

function EMA:OnProfileDeleted( event, database, profileKey )
	EMA:Print( "Profile deleted - iterating all modules." )
	EMA:FireBeforeProfileChangedEvent()
	-- Do the team module before all the others.
	local teamModuleAddress = EMA.registeredModulesByName[EMA.teamModuleName]
	EMA:Print( "Deleting profile: ", EMA.teamModuleName )
	teamModuleAddress.completeDatabase:DeleteProfile( profileKey, true )
	EMA:FireOnProfileChangedEvent( teamModuleAddress )	
	-- Do the other modules.		
	for moduleName, moduleAddress in pairs( EMA.registeredModulesByName ) do
		if EMA:CanChangeProfileForModule( moduleName ) == true then		
			EMA:Print( "Deleting profile: ", moduleName )
			moduleAddress.completeDatabase:DeleteProfile( profileKey, true )
			EMA:FireOnProfileChangedEvent( moduleAddress )
		end
	end
end

-------------------------------------------------------------------------------------------------------------
-- Jamba Core Initialization.
-------------------------------------------------------------------------------------------------------------

-- Initialize the addon.
function EMA:OnInitialize()
	-- Tables to hold registered modules - lookups by name and by address.  
	-- By name is used for communication between clients and by address for communication between addons on the same client.
	EMA.registeredModulesByName = {}
	EMA.registeredModulesByAddress = {}
	-- Create the settings database supplying the settings values along with defaults.
    EMA.completeDatabase = LibStub( "AceDB-3.0" ):New( EMA.settingsDatabaseName, EMA.settings )
	EMA.completeDatabase.RegisterCallback( EMA, "OnProfileChanged", "OnProfileChanged" )
	EMA.completeDatabase.RegisterCallback( EMA, "OnProfileCopied", "OnProfileCopied" )
	EMA.completeDatabase.RegisterCallback( EMA, "OnProfileReset", "OnProfileReset" )	
	EMA.completeDatabase.RegisterCallback( EMA, "OnProfileDeleted", "OnProfileDeleted" )	
	EMA.db = EMA.completeDatabase.profile
	-- Create the settings.
	LibStub( "AceConfig-3.0" ):RegisterOptionsTable( 
		EMA.moduleName, 
		GetConfiguration() 
	)
	-- Create the settings frame.
	EMA:CoreSettingsCreate()
	EMA.settingsFrame = EMA.settingsControl.widgetSettings.frame
	-- Blizzard options frame.
	local frame = CreateFrame( "Frame" )
	frame.name = L["Jamba"]
	local button = CreateFrame( "Button", nil, frame, "OptionsButtonTemplate" )
	button:SetPoint( "CENTER" )
	button:SetText( "/jamba" )
	button:SetScript( "OnClick", EMA.LoadJambaSettings )
	InterfaceOptions_AddCategory( frame )
	-- Create the settings profile support.
	LibStub( "AceConfig-3.0" ):RegisterOptionsTable( 
		EMA.moduleName.."-Profiles",
		LibStub( "AceDBOptions-3.0" ):GetOptionsTable( EMA.completeDatabase ) 
	)
	local profileContainerWidget = AceGUI:Create( "SimpleGroup" )
	profileContainerWidget:SetLayout( "Fill" )
	JambaPrivate.SettingsFrame.Tree.Add( L["Core"]..L[": Profiles"], L["Profiles"], profileContainerWidget, nil )
	-- Register the core as a module.
	RegisterModule( EMA, EMA.moduleName )
	-- Register the chat command.
	EMA:RegisterChatCommand( EMA.chatCommand, "JambaChatCommand" )
	-- Attempt to load modules, if they are disabled, they won't be loaded.
	-- TODO: This kinda defeats the purpose of the module system if we have to update core each time a module is added.
    EMA:LoadJambaModule( "Jamba-AdvancedLoot" )
	EMA:LoadJambaModule( "Jamba-DisplayTeam" )
	EMA:LoadJambaModule( "Jamba-Follow" )
	EMA:LoadJambaModule( "Jamba-FTL" )
	EMA:LoadJambaModule( "Jamba-ItemUse" )
	EMA:LoadJambaModule( "Jamba-Macro" )
	EMA:LoadJambaModule( "Jamba-Proc" )
	EMA:LoadJambaModule( "Jamba-Purchase" )
	EMA:LoadJambaModule( "Jamba-Quest" )
	EMA:LoadJambaModule( "Jamba-QuestWatcher" )
	EMA:LoadJambaModule( "Jamba-Sell" )
	EMA:LoadJambaModule( "Jamba-Talk" )
	EMA:LoadJambaModule( "Jamba-Target" )
	EMA:LoadJambaModule( "Jamba-Taxi" )
	EMA:LoadJambaModule( "Jamba-Toon" )
	EMA:LoadJambaModule( "Jamba-Trade" )
	EMA:LoadJambaModule( "Jamba-Video" )
	EMA:LoadJambaModule( "Jamba-Curr" )
	EMA:LoadJambaModule( "Jamba-Mount" )
end

function EMA:LoadJambaModule( moduleName )
	local loaded, reason = LoadAddOn( moduleName )
	if not loaded then
		if reason ~= "DISABLED" and reason ~= "MISSING" then
			EMA:Print("Failed to load Jamba Module '"..moduleName.."' ["..reason.."]." )
		end
	end
end

function EMA:CoreSettingsCreateInfo( top )
	-- Get positions and dimensions.
	local buttonPushAllSettingsWidth = 200
	local buttonHeight = JambaHelperSettings:GetButtonHeight()
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
	local column2Left = column1Left + checkBoxThirdWidth + horizontalSpacing
	local column1LeftIndent = left + indentContinueLabel
	local column2LeftIndent = column1LeftIndent + checkBoxThirdWidth + horizontalSpacing
	local column3LeftIndent = column2LeftIndent + checkBoxThirdWidth + horizontalSpacing
	local movingTop = top
	--Main Heading
	JambaHelperSettings:CreateHeading( EMA.settingsControl, L["The Awesome Multi-Boxer Assistant"], movingTop, false )
	movingTop = movingTop - headingHeight
	EMA.settingsControl.labelInformation1 = JambaHelperSettings:CreateContinueLabel( 
		EMA.settingsControl, 
		headingWidth, 
		column1Left, 
		movingTop,
		L["Current Project Manager - Jennifer 'Ebony'"]
	)	
	movingTop = movingTop + movingTop * 2
	JambaHelperSettings:CreateHeading( EMA.settingsControl, L["Release Notes / News: "]..GetAddOnMetadata("jamba", "version") , movingTop, false )
	movingTop = movingTop - headingHeight
	EMA.settingsControl.labelInformation10 = JambaHelperSettings:CreateContinueLabel( 
		EMA.settingsControl, 
		headingWidth, 
		column1Left, 
		movingTop,
		L["Text1"]
	)
	movingTop = movingTop - labelContinueHeight
	EMA.settingsControl.labelInformation11 = JambaHelperSettings:CreateContinueLabel( 
		EMA.settingsControl, 
		headingWidth, 
		column1Left, 
		movingTop,
		L["Text2"]
	)	
	movingTop = movingTop - labelContinueHeight
	EMA.settingsControl.labelInformation12 = JambaHelperSettings:CreateContinueLabel( 
		EMA.settingsControl, 
		headingWidth, 
		column1Left, 
		movingTop,
		L["Text3"]
	)	
	movingTop = movingTop - labelContinueHeight
	EMA.settingsControl.labelInformation13	= JambaHelperSettings:CreateContinueLabel( 
		EMA.settingsControl, 
		headingWidth, 
		column1Left, 
		movingTop,
		L["Text4"]
	)	
	movingTop = movingTop - labelContinueHeight
	EMA.settingsControl.labelInformation14 = JambaHelperSettings:CreateContinueLabel( 
		EMA.settingsControl, 
		headingWidth, 
		column1Left, 
		movingTop,
		L["Text5"]
	)	
	movingTop = movingTop - labelContinueHeight
	EMA.settingsControl.labelInformation15 = JambaHelperSettings:CreateContinueLabel( 
		EMA.settingsControl, 
		headingWidth, 
		column1Left, 
		movingTop,
		L["Text6"]
	)	
	movingTop = movingTop - labelContinueHeight
	EMA.settingsControl.labelInformation16 = JambaHelperSettings:CreateContinueLabel( 
		EMA.settingsControl, 
		headingWidth, 
		column1Left, 
		movingTop,
		L["Text7"]
	)	
	movingTop = movingTop - labelContinueHeight
	EMA.settingsControl.labelInformation17 = JambaHelperSettings:CreateContinueLabel( 
		EMA.settingsControl, 
		headingWidth, 
		column1Left, 
		movingTop,
		L["Text8"]
	)	
	movingTop = movingTop - labelContinueHeight
	EMA.settingsControl.labelInformation18 = JambaHelperSettings:CreateContinueLabel( 
		EMA.settingsControl, 
		headingWidth, 
		column1Left, 
		movingTop,
		L["Text9"]
	)	
	movingTop = movingTop - labelContinueHeight
	EMA.settingsControl.labelInformation19 = JambaHelperSettings:CreateContinueLabel( 
		EMA.settingsControl, 
		headingWidth, 
		column1Left, 
		movingTop,
		L["Text10"]
	)	
	--movingTop = movingTop - labelContinueHeight
--[[	movingTop = movingTop - buttonHeight * 3
	EMA.settingsControl.buttonPushSettingsForAllModules = JambaHelperSettings:CreateButton(	
		EMA.settingsControl, 
		buttonPushAllSettingsWidth, 
		column2Left, 
		movingTop, 
		L["Full ChangeLog"],
		EMA.ShowChangeLog,
		L["Shows the Full changelog\nOpens a new Frame."]
	)
--]]
	-- Special thanks Heading
	
	movingTop = movingTop - buttonHeight 
	JambaHelperSettings:CreateHeading( EMA.settingsControl, L["Special thanks:"], movingTop, false )	
	movingTop = movingTop - headingHeight
	EMA.settingsControl.labelInformation20 = JambaHelperSettings:CreateContinueLabel( 
		EMA.settingsControl, 
		headingWidth, 
		column1Left, 
		movingTop,
		L["To Michael 'Jafula' Miller who made Jamba"]
	)	
	movingTop = movingTop - labelContinueHeight
	EMA.settingsControl.labelInformation21 = JambaHelperSettings:CreateContinueLabel( 
		EMA.settingsControl, 
		headingWidth, 
		column1Left, 
		movingTop,
		L["To Olipcs on dual-boxing.com for writing the FTL Helper module."]
		
	)	
	movingTop = movingTop - labelContinueHeight
	EMA.settingsControl.labelInformation22 = JambaHelperSettings:CreateContinueLabel( 
		EMA.settingsControl, 
		headingWidth, 
		column1Left, 
		movingTop,
		L["To Schilm (Max Schilling) for Advanced Loot"]
	)
	-- Useful websites Heading
	movingTop = movingTop - labelContinueHeight * 2
	JambaHelperSettings:CreateHeading( EMA.settingsControl, L["Useful websites:"], movingTop, false )	
	movingTop = movingTop - headingHeight
	EMA.settingsControl.labelInformation30 = JambaHelperSettings:CreateContinueLabel( 
		EMA.settingsControl, 
		headingWidth, 
		column2Left, 
		movingTop,
		L["www.twitter.com/jenn_ebony"]
		
	)		
	movingTop = movingTop - labelContinueHeight
	EMA.settingsControl.labelInformation21 = JambaHelperSettings:CreateContinueLabel( 
		EMA.settingsControl, 
		headingWidth, 
		column2Left, 
		movingTop,
		L["www.dual-boxing.com"]
	)
	movingTop = movingTop - labelContinueHeight
	EMA.settingsControl.labelInformation22 = JambaHelperSettings:CreateContinueLabel( 
		EMA.settingsControl, 
		headingWidth, 
		column2Left, 
		movingTop,
		L["www.isboxer.com"]
	)	
	--CopyRight heading
	movingTop = movingTop - labelContinueHeight * 4
	EMA.settingsControl.labelInformation30 = JambaHelperSettings:CreateContinueLabel( 
		EMA.settingsControl, 
		headingWidth, 
		column1Left, 
		movingTop,
		L["Copyright 2008-2016 Michael 'Jafula' Miller, Released Under The MIT License"]
	)
	return movingTop	
end

function EMA:CoreSettingsCreate()
	EMA.settingsControl = {}
	-- Create the settings panel.
	JambaHelperSettings:CreateSettings( 
		EMA.settingsControl, 
		EMA.moduleDisplayName, 
		EMA.parentDisplayName, 
		EMA.SendSettingsAllModules 
	)
	local bottomOfInfo = EMA:CoreSettingsCreateInfo( JambaHelperSettings:TopOfSettings() )
	EMA.settingsControl.widgetSettings.content:SetHeight( -bottomOfInfo )
end

-- Send core settings.
function EMA:JambaSendSettings()
	JambaPrivate.Communications.SendSettings( EMA.moduleName, EMA.db )
end

function EMA:OnJambaProfileChanged()	
	EMA:SettingsRefresh()
end

function EMA:SettingsRefresh()
end

-- Core settings received.
function EMA:JambaOnSettingsReceived( characterName, settings )
	--Checks character is not the the character that send the settings. Now checks the character has a realm on there name to match Jamba team list.
	--characterName = JambaUtilities:AddRealmToNameIfMissing( characterName )
	if characterName ~= EMA.characterName then
		-- Update the settings.
        -- TODO: What is this minimap icon?
		EMA.db.showMinimapIcon = settings.showMinimapIcon
		-- Refresh the settings.
		EMA:SettingsRefresh()
		-- Tell the player.
		EMA:Print( L["Settings received from A."]( characterName ) )
		-- Tell the team?
		--EMA:JambaSendMessageToTeam( EMA.db.messageArea,  L["Settings received from A."]( characterName ), false )
	end
end

function EMA:LoadJambaSettings()
	InterfaceOptionsFrameCancel_OnClick()
	HideUIPanel( GameMenuFrame )
	EMA:JambaChatCommand( "" )
end

-- Handle the chat command.
function EMA:JambaChatCommand( input )
    if not input or input:trim() == "" then
		JambaPrivate.SettingsFrame.Widget:Show()
		JambaPrivate.SettingsFrame.WidgetTree:SelectByValue( EMA.moduleDisplayName )
		JambaPrivate.SettingsFrame.Tree.ButtonClick( nil, nil, EMA.moduleDisplayName, false)
    else
        LibStub( "AceConfigCmd-3.0" ):HandleCommand( EMA.chatCommand, EMA.moduleName, input )
    end
end

function EMA:ResetSettingsFrame()
	EMA:Print( L["Attempting to reset the Jamba Settings Frame."] )
	JambaPrivate.SettingsFrame.Widget:SetPoint("TOPLEFT", 0, 0)
	JambaPrivate.SettingsFrame.Widget:SetWidth(770)
	JambaPrivate.SettingsFrame.Widget:SetHeight(650)
	JambaPrivate.SettingsFrame.Widget:Show()
end

-- Functions available from Jamba Core for other Jamba internal objects.
JambaPrivate.Core.RegisterModule = RegisterModule
JambaPrivate.Core.SendSettings = SendSettings
JambaPrivate.Core.OnSettingsReceived = OnSettingsReceived
JambaPrivate.Core.SendCommandToTeam = SendCommandToTeam
JambaPrivate.Core.SendCommandToMaster = SendCommandToMaster
JambaPrivate.Core.SendCommandToToon = SendCommandToToon
-- TODO: Remove send command to minions?
--JambaPrivate.Core.SendCommandToMinions = SendCommandToMinions
JambaPrivate.Core.OnCommandReceived = OnCommandReceived