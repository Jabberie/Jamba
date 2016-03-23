--[[
Jamba - Jafula's Awesome Multi-Boxer Assistant
Copyright 2008 - 2016 Michael "Jafula" Miller
License: The MIT License
]]--

-- Create the addon using AceAddon-3.0 and embed some libraries.
local AJM = LibStub( "AceAddon-3.0" ):NewAddon( 
	"JambaTarget", 
	"JambaModule-1.0", 
	"AceConsole-3.0", 
	"AceEvent-3.0",
	"AceTimer-3.0"
)

-- Get the Jamba Utilities Library.
local JambaUtilities = LibStub:GetLibrary( "JambaUtilities-1.0" )
local JambaHelperSettings = LibStub:GetLibrary( "JambaHelperSettings-1.0" )
AJM.SharedMedia = LibStub( "LibSharedMedia-3.0" )

--  Constants and Locale for this module.
AJM.moduleName = "Jamba-Target"
AJM.settingsDatabaseName = "JambaTargetProfileDB"
AJM.chatCommand = "jamba-target"
local L = LibStub( "AceLocale-3.0" ):GetLocale( AJM.moduleName )
AJM.parentDisplayName = L["Combat"]
AJM.moduleDisplayName = L["Target"]

-- Jamba key bindings.
BINDING_HEADER_JAMBA_TARGET = L["Jamba-Target"]
BINDING_NAME_JAMBATARGETMARK = L["Mark Targets (Press & Hold)"]
BINDING_NAME_JAMBACLEARTARGET = L["Clear Target"]
BINDING_NAME_JAMBATARGET1 = L["Target 1 (Star)"]
BINDING_NAME_JAMBATARGET2 = L["Target 2 (Circle)"]
BINDING_NAME_JAMBATARGET3 = L["Target 3 (Diamond)"]
BINDING_NAME_JAMBATARGET4 = L["Target 4 (Triangle)"]
BINDING_NAME_JAMBATARGET5 = L["Target 5 (Moon)"]
BINDING_NAME_JAMBATARGET6 = L["Target 6 (Square)"]
BINDING_NAME_JAMBATARGET7 = L["Target 7 (Cross)"]
BINDING_NAME_JAMBATARGET8 = L["Target 8 (Skull)"]

-- Settings - the values to store and their defaults for the settings database.
AJM.settings = {
	profile = {
		framePoint = "CENTER",
		frameRelativePoint = "CENTER",
		frameXOffset = 0,
		frameYOffset = 0,
		frameAlpha = 1.0,
		borderStyle = L["Blizzard Tooltip"],
		backgroundStyle = L["Blizzard Dialog Background"],
		frameBackgroundColourR = 1.0,
		frameBackgroundColourG = 1.0,
		frameBackgroundColourB = 1.0,
		frameBackgroundColourA = 1.0,
		frameBorderColourR = 1.0,
		frameBorderColourG = 1.0,
		frameBorderColourB = 1.0,
		frameBorderColourA = 1.0,
		frameScale = 1,
		markTargetsWithRaidIcons = true,
		showTargetList = true,
		targetListHealthHeight = 15,
		targetListHealthWidth = 180,
		holdTargets = {
			["1"] = false,
			["2"] = false,
			["3"] = false,
			["4"] = false,
			["5"] = false,
			["6"] = false,
			["7"] = false,
			["8"] = false,
		},
		targetTag = {
			["1"] = L["all"],
			["2"] = L["all"],
			["3"] = L["all"],
			["4"] = L["all"],
			["5"] = L["all"],
			["6"] = L["all"],
			["7"] = L["all"],
			["8"] = L["all"],
		},				
		targetMacro = {
			["1"] = "/targetexact #MOB#",
			["2"] = "/targetexact #MOB#",
			["3"] = "/targetexact #MOB#",
			["4"] = "/targetexact #MOB#",
			["5"] = "/targetexact #MOB#",
			["6"] = "/targetexact #MOB#",
			["7"] = "/targetexact #MOB#",
			["8"] = "/targetexact #MOB#",
		},							
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
				desc = L["Push the target settings to all characters in the team."],
				usage = "/jamba-target push",
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

AJM.COMMAND_SET_MOB_TARGET = "SetTargetToMob"
AJM.COMMAND_CLEAR_MOB_TARGET = "SetTargetToMobClear"

-------------------------------------------------------------------------------------------------------------
-- Messages module sends.
-------------------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------------------------
-- Addon initialization, enabling and disabling.
-------------------------------------------------------------------------------------------------------------

function AJM:CreateJambaTargetListFrame()
	-- The frame.
	local frame = CreateFrame( "Frame", "JambaTargetListWindowFrame", UIParent )
	frame.obj = self
	frame:SetWidth( AJM.db.targetListHealthWidth )
	frame:SetHeight( AJM.listTargetsTitleHeight + (AJM.db.targetListHealthHeight * 8) + (AJM.listTargetsVerticalSpacing * (8 + 3)) )
	frame:SetFrameStrata( "MEDIUM" )
	frame:SetToplevel( true )
	frame:SetClampedToScreen( true )
	frame:EnableMouse( true )
	frame:SetMovable( true )	
	frame:SetUserPlaced( true )
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
			AJM.db.framePoint = point
			AJM.db.frameRelativePoint = relativePoint
			AJM.db.frameXOffset = xOffset
			AJM.db.frameYOffset = yOffset
		end	)	
	frame:ClearAllPoints()
	frame:SetPoint( AJM.db.framePoint, UIParent, AJM.db.frameRelativePoint, AJM.db.frameXOffset, AJM.db.frameYOffset )
	frame:SetBackdrop( {
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", 
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", 
		tile = true, tileSize = 10, edgeSize = 10, 
		insets = { left = 3, right = 3, top = 3, bottom = 3 }
	} )
	JambaTargetListFrame = frame
	-- Create the title for the target list frame.
	local titleName = frame:CreateFontString( "JambaTargetListWindowFrameTitleText", "OVERLAY", "GameFontNormal" )
	titleName:SetPoint( "TOP", frame, "TOP", 0, -5 )
	titleName:SetTextColor( 1.00, 1.00, 1.00 )
	titleName:SetText( L["Jamba-Target"] )
	-- Secure action button targets 1-8.
	local heightAddition = AJM.db.targetListHealthHeight + AJM.listTargetsVerticalSpacing
	local topPosition = -AJM.listTargetsTitleHeight + -AJM.listTargetsVerticalSpacing * 2
	local leftPosition = 6
	for target = 1, 8, 1 do
		AJM:CreateJambaTargetTargetButton( 
			target, 
			"JambaTargetSecureButtonTarget"..tostring( target ), 
			frame, 
			leftPosition, 
			topPosition + ((target - 1) * -heightAddition) 
		)
	end
	frame:SetAlpha( AJM.db.frameAlpha )
	frame:SetScale( AJM.db.frameScale )
	AJM:SettingsUpdateBorderStyle()	
	frame:Hide()
end

function AJM:SettingsUpdateBorderStyle()
	local borderStyle = AJM.SharedMedia:Fetch( "border", AJM.db.borderStyle )
	local backgroundStyle = AJM.SharedMedia:Fetch( "background", AJM.db.backgroundStyle )
	local frame = JambaTargetListFrame
	frame:SetBackdrop( {
		bgFile = backgroundStyle, 
		edgeFile = borderStyle, 
		tile = true, tileSize = frame:GetWidth(), edgeSize = 10, 
		insets = { left = 3, right = 3, top = 3, bottom = 3 }
	} )
	frame:SetBackdropColor( AJM.db.frameBackgroundColourR, AJM.db.frameBackgroundColourG, AJM.db.frameBackgroundColourB, AJM.db.frameBackgroundColourA )
	frame:SetBackdropBorderColor( AJM.db.frameBorderColourR, AJM.db.frameBorderColourG, AJM.db.frameBorderColourB, AJM.db.frameBorderColourA )	
end

function AJM:CreateJambaTargetTargetButton( targetNumber, buttonName, parentFrame, positionLeft, positionTop )
	-- Create the target button that holds the macro (and the corresponding raid icon).
	local targetButton = CreateFrame( "CheckButton", buttonName, parentFrame, "SecureActionButtonTemplate" )
	targetButton:SetWidth( AJM.db.targetListHealthHeight )
	targetButton:SetHeight( AJM.db.targetListHealthHeight )
	targetButton:SetID( targetNumber )
	targetButton.Texture = targetButton:CreateTexture( targetButton:GetName().."NormalTexture", "ARTWORK" )
	targetButton.Texture:SetTexture( "Interface\\TargetingFrame\\UI-RaidTargetingIcons" )
	targetButton.Texture:SetAllPoints()
	SetRaidTargetIconTexture( targetButton.Texture, targetNumber )	
	targetButton:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", positionLeft, positionTop )
	targetButton:SetAttribute( "type", "macro" )
	targetButton:SetAttribute( "macrotext", "" )
	-- Create a status bar for the targets health.
	local targetStatusHealth = CreateFrame( "StatusBar", buttonName.."StatusHealth", parentFrame, "TextStatusBar" )
	targetStatusHealth:SetWidth( AJM.db.targetListHealthWidth - (AJM.db.targetListHealthHeight * 2) )
	targetStatusHealth:SetHeight( AJM.db.targetListHealthHeight )
	targetStatusHealth:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", positionLeft + AJM.db.targetListHealthHeight + 4, positionTop )
	targetStatusHealth:SetStatusBarTexture( "Interface\\TargetingFrame\\UI-StatusBar" )
	targetStatusHealth:SetMinMaxValues( 0, 100 )
	AJM:UpdateHealthStatusBar( targetStatusHealth, 100, 100 )
	-- Create a text string for the targets name.
	local targetName = targetStatusHealth:CreateFontString( buttonName.."NameText", "OVERLAY", "GameFontNormal" )
	targetName:SetWidth( (AJM.db.targetListHealthWidth - (AJM.db.targetListHealthHeight * 2)) - 4 )
	targetName:SetHeight( AJM.db.targetListHealthHeight )
	targetName:SetPoint( "TOPLEFT", targetStatusHealth, "TOPLEFT", 2, 0 )
	targetName:SetTextColor( 1.00, 1.00, 1.00, 1.00 )
	targetName:SetText( "" )
	targetButton:Hide()
	targetStatusHealth:Hide()		
end

function AJM:UpdateHealthStatusBar( statusBar, statusValue, statusMaxValue )
	statusBar:SetMinMaxValues( 0, statusMaxValue )
	statusBar:SetValue( statusValue )
	local r, g, b = 0, 0, 0
	statusValue = statusValue / statusMaxValue
	if( statusValue > 0.5 ) then
		r = (1.0 - statusValue) * 2
		g = 1.0
	else
		r = 1.0
		g = statusValue * 2
	end
	b = 0.0
	statusBar:SetStatusBarColor( r, g, b )
end

function AJM:CreateJambaTargetMarkFrame()
	-- The frame.
	local frame = CreateFrame( "Frame", "JambaTargetMarkWindowFrame", UIParent )
	frame.obj = self
	frame:SetWidth( 100 )
	frame:SetHeight( 100 )
	frame:SetFrameStrata( "DIALOG" )
	frame:SetToplevel( true )
	frame:SetClampedToScreen( true )
	frame:EnableMouse( true )
	frame:ClearAllPoints()
	frame:SetPoint( "CENTER", UIParent )
	JambaTargetMarkFrame = frame
	-- The 8 raid icons to use as targets.
	for raidIcon = 1, 8, 1 do
		-- Create the button.
		local targetButton = CreateFrame( "Button", "JambaTargetMarkRaidIconButton"..tostring( raidIcon ), frame )
		targetButton:SetWidth( 30 )
		targetButton:SetHeight( 30 )
		targetButton:SetID( raidIcon )
		targetButton.Texture = targetButton:CreateTexture( targetButton:GetName().."NormalTexture", "ARTWORK" )
		targetButton.Texture:SetTexture( "Interface\\TargetingFrame\\UI-RaidTargetingIcons" )
		targetButton.Texture:SetAllPoints()
		SetRaidTargetIconTexture( targetButton.Texture, raidIcon )
		local relocateIcon = raidIcon - 1
		if relocateIcon == 0 then
			relocateIcon = 8
		end
		targetButton:SetPoint( "CENTER", sin( 360 / 8 * relocateIcon ) * 50, cos( 360 / 8 * relocateIcon ) * 50)
		-- Events.
		targetButton:RegisterForClicks( "LeftButtonUp", "RightButtonUp" )
		targetButton:SetScript( "OnClick", AJM.JambaTargetMarkTargetClick )
		targetButton:SetScript( "OnEnter", 
			function( this ) 				
				this.Texture:ClearAllPoints();
				this.Texture:SetPoint( "TOPLEFT", -5, 5 )
				this.Texture:SetPoint( "BOTTOMRIGHT", 5, -5 )
			end )
		targetButton:SetScript( "OnLeave", 
			function( this ) 
				this.Texture:SetAllPoints()
			end )
	end
	frame:Hide()
end

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
	-- Variables.
	AJM.refreshUpdateBindingsPending = false
	-- Size of items on target list frame.
	AJM.listTargetsVerticalSpacing = 4
	AJM.listTargetsTitleHeight = 15	
	-- Timer handle for refreshing the targets list.
	AJM.updateTargetListTimer = nil	
	-- Create a target list.
	AJM.targetList = {}
	for targetNumber = 1, 8 do
		local targetInformation = {}
		targetInformation["set"] = false
		targetInformation["name"] = ""
		targetInformation["guid"] = ""
		AJM.targetList[targetNumber] = targetInformation
	end
	-- A secure action button for clear target.
	JambaTargetSecureButtonClearTarget = CreateFrame( "CheckButton", "JambaTargetSecureButtonClearTarget", nil, "SecureActionButtonTemplate" ); 
	JambaTargetSecureButtonClearTarget:SetAttribute( "type", "macro" )
	JambaTargetSecureButtonClearTarget:SetAttribute( "macrotext", "/cleartarget" )
	JambaTargetSecureButtonClearTarget:Hide()
	-- Create the jamba target list frame.
	AJM:CreateJambaTargetListFrame()
	-- Create the jamba mark target frame.
	AJM:CreateJambaTargetMarkFrame()	
end

-- Called when the addon is enabled.
function AJM:OnEnable()
	AJM.keyBindingFrame = CreateFrame( "Frame", nil, UIParent )
	AJM:RegisterEvent( "UPDATE_BINDINGS" )		
	AJM:UPDATE_BINDINGS()
	AJM:RegisterEvent( "PLAYER_REGEN_ENABLED" )
	AJM:RegisterEvent( "PLAYER_REGEN_DISABLED" )
	AJM:RegisterEvent( "COMBAT_LOG_EVENT_UNFILTERED" )
	AJM:RegisterEvent( "UNIT_COMBAT" )
	AJM.updateTargetListTimer = AJM:ScheduleRepeatingTimer( "RefreshTargetList", 3 )
	AJM:RegisterMessage( JambaApi.MESSAGE_MESSAGE_AREAS_CHANGED, "OnMessageAreasChanged" )
end

-- Called when the addon is disabled.
function AJM:OnDisable()
	AJM:CancelTimer( AJM.updateTargetListTimer )
end

function AJM:SettingsCreate()
	AJM.settingsControl = {}
	AJM.settingsControlMacros = {}
	-- Create the settings panel.
	JambaHelperSettings:CreateSettings( 
		AJM.settingsControl, 
		AJM.moduleDisplayName, 
		AJM.parentDisplayName, 
		AJM.SettingsPushSettingsClick 
	)
	JambaHelperSettings:CreateSettings( 
		AJM.settingsControlMacros, 
		AJM.moduleDisplayName..L[": "]..L["Macros"], 
		AJM.parentDisplayName, 
		AJM.SettingsPushSettingsClick 
	)	
	local bottomOfInfo = AJM:SettingsCreateTarget( JambaHelperSettings:TopOfSettings() )
	AJM.settingsControl.widgetSettings.content:SetHeight( -bottomOfInfo )
	local bottomOfMacros = AJM:SettingsCreateMacros( JambaHelperSettings:TopOfSettings() )
	AJM.settingsControlMacros.widgetSettings.content:SetHeight( -bottomOfMacros )	
	-- Help
	local helpTable = {}
	JambaHelperSettings:CreateHelp( AJM.settingsControl, helpTable, AJM:GetConfiguration() )		
end

function AJM:SettingsPushSettingsClick( event )
	AJM:JambaSendSettings()
end

function AJM:SettingsCreateMacros( top )
	local checkBoxHeight = JambaHelperSettings:GetCheckBoxHeight()
	local left = JambaHelperSettings:LeftOfSettings()
	local headingHeight = JambaHelperSettings:HeadingHeight()
	local headingWidth = JambaHelperSettings:HeadingWidth( true )
	local dropdownHeight = JambaHelperSettings:GetDropdownHeight()
	local verticalSpacing = JambaHelperSettings:GetVerticalSpacing()
	local horizontalSpacing = JambaHelperSettings:GetHorizontalSpacing()
	local labelContinueHeight = JambaHelperSettings:GetContinueLabelHeight()
	local editBoxHeight = JambaHelperSettings:GetEditBoxHeight()
	local multiEditBoxHeightMacroText = 100
	local halfWidth = (headingWidth - horizontalSpacing) / 2
	local column2left = left + halfWidth
	local movingTop = top
	JambaHelperSettings:CreateHeading( AJM.settingsControlMacros, L["Target Macros"], movingTop, true )
	movingTop = movingTop - headingHeight
	AJM.settingsControlMacros.labelHoldInformation = JambaHelperSettings:CreateContinueLabel( 
		AJM.settingsControlMacros, 
		headingWidth, 
		left, 
		movingTop,
		L["The macro to use for each target.  Use #MOB# for the actual target."] 
	)	
	movingTop = movingTop - (labelContinueHeight * 1.5)		
	JambaHelperSettings:CreateHeading( AJM.settingsControlMacros, L["Target 1 (Star)"], movingTop, true )
	movingTop = movingTop - headingHeight
	AJM.settingsControlMacros.editMacro1Star = JambaHelperSettings:CreateMultiEditBox( 
		AJM.settingsControlMacros,
		headingWidth,
		left,
		movingTop,
		L["Macro for Target 1 (Star)"],
		4
	)
	AJM.settingsControlMacros.editMacro1Star:SetCallback( "OnEnterPressed", AJM.SettingsEditMacro1Star )
	movingTop = movingTop - multiEditBoxHeightMacroText	
	AJM.settingsControlMacros.editTag1Star = JambaHelperSettings:CreateEditBox( 
		AJM.settingsControlMacros,
		headingWidth,
		left,
		movingTop,
		L["Tag for Target 1 (Star)"]
	)
	AJM.settingsControlMacros.editTag1Star:SetCallback( "OnEnterPressed", AJM.SettingsEditTag1Star )	
	movingTop = movingTop - editBoxHeight		
	JambaHelperSettings:CreateHeading( AJM.settingsControlMacros, L["Target 2 (Circle)"], movingTop, true )
	movingTop = movingTop - headingHeight
	AJM.settingsControlMacros.editMacro2Circle = JambaHelperSettings:CreateMultiEditBox( 
		AJM.settingsControlMacros,
		headingWidth,
		left,
		movingTop,
		L["Macro for Target 2 (Circle)"],
		4
	)
	AJM.settingsControlMacros.editMacro2Circle:SetCallback( "OnEnterPressed", AJM.SettingsEditMacro2Circle )
	movingTop = movingTop - multiEditBoxHeightMacroText	
	AJM.settingsControlMacros.editTag2Circle = JambaHelperSettings:CreateEditBox( 
		AJM.settingsControlMacros,
		headingWidth,
		left,
		movingTop,
		L["Tag for Target 2 (Circle)"]
	)
	AJM.settingsControlMacros.editTag2Circle:SetCallback( "OnEnterPressed", AJM.SettingsEditTag2Circle )	
	movingTop = movingTop - editBoxHeight		
	JambaHelperSettings:CreateHeading( AJM.settingsControlMacros, L["Target 3 (Diamond)"], movingTop, true )
	movingTop = movingTop - headingHeight
	AJM.settingsControlMacros.editMacro3Diamond = JambaHelperSettings:CreateMultiEditBox( 
		AJM.settingsControlMacros,
		headingWidth,
		left,
		movingTop,
		L["Macro for Target 3 (Diamond)"],
		4
	)
	AJM.settingsControlMacros.editMacro3Diamond:SetCallback( "OnEnterPressed", AJM.SettingsEditMacro3Diamond )
	movingTop = movingTop - multiEditBoxHeightMacroText	
	AJM.settingsControlMacros.editTag3Diamond = JambaHelperSettings:CreateEditBox( 
		AJM.settingsControlMacros,
		headingWidth,
		left,
		movingTop,
		L["Tag for Target 3 (Diamond)"]
	)
	AJM.settingsControlMacros.editTag3Diamond:SetCallback( "OnEnterPressed", AJM.SettingsEditTag3Diamond )	
	movingTop = movingTop - editBoxHeight		
	JambaHelperSettings:CreateHeading( AJM.settingsControlMacros, L["Target 4 (Triangle)"], movingTop, true )
	movingTop = movingTop - headingHeight
	AJM.settingsControlMacros.editMacro4Triangle = JambaHelperSettings:CreateMultiEditBox( 
		AJM.settingsControlMacros,
		headingWidth,
		left,
		movingTop,
		L["Macro for Target 4 (Triangle)"],
		4
	)
	AJM.settingsControlMacros.editMacro4Triangle:SetCallback( "OnEnterPressed", AJM.SettingsEditMacro4Triangle )
	movingTop = movingTop - multiEditBoxHeightMacroText	
	AJM.settingsControlMacros.editTag4Triangle = JambaHelperSettings:CreateEditBox( 
		AJM.settingsControlMacros,
		headingWidth,
		left,
		movingTop,
		L["Tag for Target 4 (Triangle)"]
	)
	AJM.settingsControlMacros.editTag4Triangle:SetCallback( "OnEnterPressed", AJM.SettingsEditTag4Triangle )	
	movingTop = movingTop - editBoxHeight		
	JambaHelperSettings:CreateHeading( AJM.settingsControlMacros, L["Target 5 (Moon)"], movingTop, true )
	movingTop = movingTop - headingHeight
	AJM.settingsControlMacros.editMacro5Moon = JambaHelperSettings:CreateMultiEditBox( 
		AJM.settingsControlMacros,
		headingWidth,
		left,
		movingTop,
		L["Macro for Target 5 (Moon)"],
		4
	)
	AJM.settingsControlMacros.editMacro5Moon:SetCallback( "OnEnterPressed", AJM.SettingsEditMacro5Moon )
	movingTop = movingTop - multiEditBoxHeightMacroText	
	AJM.settingsControlMacros.editTag5Moon = JambaHelperSettings:CreateEditBox( 
		AJM.settingsControlMacros,
		headingWidth,
		left,
		movingTop,
		L["Tag for Target 5 (Moon)"]
	)
	AJM.settingsControlMacros.editTag5Moon:SetCallback( "OnEnterPressed", AJM.SettingsEditTag5Moon )	
	movingTop = movingTop - editBoxHeight		
	JambaHelperSettings:CreateHeading( AJM.settingsControlMacros, L["Target 6 (Square)"], movingTop, true )
	movingTop = movingTop - headingHeight
	AJM.settingsControlMacros.editMacro6Square = JambaHelperSettings:CreateMultiEditBox( 
		AJM.settingsControlMacros,
		headingWidth,
		left,
		movingTop,
		L["Macro for Target 6 (Square)"],
		4
	)
	AJM.settingsControlMacros.editMacro6Square:SetCallback( "OnEnterPressed", AJM.SettingsEditMacro6Square )
	movingTop = movingTop - multiEditBoxHeightMacroText	
	AJM.settingsControlMacros.editTag6Square = JambaHelperSettings:CreateEditBox( 
		AJM.settingsControlMacros,
		headingWidth,
		left,
		movingTop,
		L["Tag for Target 6 (Square)"]
	)
	AJM.settingsControlMacros.editTag6Square:SetCallback( "OnEnterPressed", AJM.SettingsEditTag6Square )	
	movingTop = movingTop - editBoxHeight
	JambaHelperSettings:CreateHeading( AJM.settingsControlMacros, L["Target 7 (Cross)"], movingTop, true )
	movingTop = movingTop - headingHeight	
	AJM.settingsControlMacros.editMacro7Cross = JambaHelperSettings:CreateMultiEditBox( 
		AJM.settingsControlMacros,
		headingWidth,
		left,
		movingTop,
		L["Macro for Target 7 (Cross)"],
		4
	)
	AJM.settingsControlMacros.editMacro7Cross:SetCallback( "OnEnterPressed", AJM.SettingsEditMacro7Cross )
	movingTop = movingTop - multiEditBoxHeightMacroText	
	AJM.settingsControlMacros.editTag7Cross = JambaHelperSettings:CreateEditBox( 
		AJM.settingsControlMacros,
		headingWidth,
		left,
		movingTop,
		L["Tag for Target 7 (Cross)"]
	)
	AJM.settingsControlMacros.editTag7Cross:SetCallback( "OnEnterPressed", AJM.SettingsEditTag7Cross )	
	movingTop = movingTop - editBoxHeight		
	JambaHelperSettings:CreateHeading( AJM.settingsControlMacros, L["Target 8 (Skull)"], movingTop, true )
	movingTop = movingTop - headingHeight
	AJM.settingsControlMacros.editMacro8Skull = JambaHelperSettings:CreateMultiEditBox( 
		AJM.settingsControlMacros,
		headingWidth,
		left,
		movingTop,
		L["Macro for Target 8 (Skull)"],
		4
	)
	AJM.settingsControlMacros.editMacro8Skull:SetCallback( "OnEnterPressed", AJM.SettingsEditMacro8Skull )
	movingTop = movingTop - multiEditBoxHeightMacroText	
	AJM.settingsControlMacros.editTag8Skull = JambaHelperSettings:CreateEditBox( 
		AJM.settingsControlMacros,
		headingWidth,
		left,
		movingTop,
		L["Tag for Target 8 (Skull)"]
	)
	AJM.settingsControlMacros.editTag8Skull:SetCallback( "OnEnterPressed", AJM.SettingsEditTag8Skull )	
	movingTop = movingTop - editBoxHeight		
	return movingTop	
end

function AJM:SettingsCreateTarget( top )
	local checkBoxHeight = JambaHelperSettings:GetCheckBoxHeight()
	local left = JambaHelperSettings:LeftOfSettings()
	local headingHeight = JambaHelperSettings:HeadingHeight()
	local headingWidth = JambaHelperSettings:HeadingWidth( true )
	local dropdownHeight = JambaHelperSettings:GetDropdownHeight()
	local mediaHeight = JambaHelperSettings:GetMediaHeight()
	local verticalSpacing = JambaHelperSettings:GetVerticalSpacing()
	local sliderHeight = JambaHelperSettings:GetSliderHeight()
	local horizontalSpacing = JambaHelperSettings:GetHorizontalSpacing()
	local labelContinueHeight = JambaHelperSettings:GetContinueLabelHeight()
	local halfWidth = (headingWidth - horizontalSpacing) / 2
	local column2left = left + halfWidth
	local movingTop = top
	JambaHelperSettings:CreateHeading( AJM.settingsControl, L["Target Options"], movingTop, true )
	movingTop = movingTop - headingHeight
	AJM.settingsControl.targetCheckBoxMarkTargetsWithRaidIcons = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		left, 
		movingTop, 
		L["Mark Targets With Raid Icons"],
		AJM.SettingsToggleMarkTargetsWithRaidIcons
	)
	movingTop = movingTop - checkBoxHeight - verticalSpacing
	AJM.settingsControl.targetCheckBoxShowTargetList = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		left, 
		movingTop, 
		L["Show Target List"],
		AJM.SettingsToggleShowTargetList
	)
	movingTop = movingTop - checkBoxHeight - verticalSpacing
	JambaHelperSettings:CreateHeading( AJM.settingsControl, L["Targets To Hold"], movingTop, true )
	movingTop = movingTop - headingHeight
	AJM.settingsControl.labelHoldInformation = JambaHelperSettings:CreateContinueLabel( 
		AJM.settingsControl, 
		headingWidth, 
		left, 
		movingTop,
		L["Do not track health for a particular unit.  Leave name in list for targeting purposes."] 
	)	
	movingTop = movingTop - (labelContinueHeight * 1.5)		
	AJM.settingsControl.targetCheckBoxHold1Star = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		halfWidth, 
		left, 
		movingTop, 
		L["Hold 1 (Star)"],
		AJM.SettingsToggleHold1Star
	)
	AJM.settingsControl.targetCheckBoxHold5Moon = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		halfWidth, 
		column2left, 
		movingTop, 
		L["Hold 5 (Moon)"],
		AJM.SettingsToggleHold5Moon
	)
	movingTop = movingTop - checkBoxHeight - verticalSpacing
	AJM.settingsControl.targetCheckBoxHold2Circle = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		halfWidth, 
		left, 
		movingTop, 
		L["Hold 2 (Circle)"],
		AJM.SettingsToggleHold2Circle
	)		
	AJM.settingsControl.targetCheckBoxHold6Square = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		halfWidth, 
		column2left, 
		movingTop, 
		L["Hold 6 (Square)"],
		AJM.SettingsToggleHold6Square
	)
	movingTop = movingTop - checkBoxHeight - verticalSpacing
	AJM.settingsControl.targetCheckBoxHold3Diamond = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		halfWidth, 
		left, 
		movingTop, 
		L["Hold 3 (Diamond)"],
		AJM.SettingsToggleHold3Diamond
	)
	AJM.settingsControl.targetCheckBoxHold7Cross = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		halfWidth, 
		column2left, 
		movingTop, 
		L["Hold 7 (Cross)"],
		AJM.SettingsToggleHold7Cross
	)	
	movingTop = movingTop - checkBoxHeight - verticalSpacing
	AJM.settingsControl.targetCheckBoxHold4Triangle = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		halfWidth, 
		left, 
		movingTop, 
		L["Hold 4 (Triangle)"],
		AJM.SettingsToggleHold4Triangle
	)
	AJM.settingsControl.targetCheckBoxHold8Skull = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		halfWidth, 
		column2left, 
		movingTop, 
		L["Hold 8 (Skull)"],
		AJM.SettingsToggleHold8Skull
	)
	movingTop = movingTop - checkBoxHeight - verticalSpacing
	JambaHelperSettings:CreateHeading( AJM.settingsControl, L["Appearance & Layout"], movingTop, true )
	movingTop = movingTop - headingHeight	
	AJM.settingsControl.targetListHealthWidth = JambaHelperSettings:CreateSlider( 
		AJM.settingsControl, 
		headingWidth, 
		left, 
		movingTop, 
		L["List Health Bars Width"]
	)
	AJM.settingsControl.targetListHealthWidth:SetSliderValues( 80, 400, 5 )
	AJM.settingsControl.targetListHealthWidth:SetCallback( "OnValueChanged", AJM.SettingsChangeTargetListHealthWidth )
	movingTop = movingTop - sliderHeight - verticalSpacing
	AJM.settingsControl.targetListHealthHeight = JambaHelperSettings:CreateSlider( 
		AJM.settingsControl, 
		headingWidth, 
		left, 
		movingTop, 
		L["List Health Bars Height"]
	)
	AJM.settingsControl.targetListHealthHeight:SetSliderValues( 10, 100, 1 )
	AJM.settingsControl.targetListHealthHeight:SetCallback( "OnValueChanged", AJM.SettingsChangeTargetListHealthHeight )
	movingTop = movingTop - sliderHeight - verticalSpacing
	AJM.settingsControl.targetListTransparencySlider = JambaHelperSettings:CreateSlider( 
		AJM.settingsControl, 
		headingWidth, 
		left, 
		movingTop, 
		L["Transparency"]
	)
	AJM.settingsControl.targetListTransparencySlider:SetSliderValues( 0, 1, 0.01 )
	AJM.settingsControl.targetListTransparencySlider:SetCallback( "OnValueChanged", AJM.SettingsChangeTransparency )
	movingTop = movingTop - sliderHeight - verticalSpacing
	AJM.settingsControl.targetListMediaBorder = JambaHelperSettings:CreateMediaBorder( 
		AJM.settingsControl, 
		halfWidth, 
		left, 
		movingTop,
		L["Border Style"]
	)
	AJM.settingsControl.targetListMediaBorder:SetCallback( "OnValueChanged", AJM.SettingsChangeBorderStyle )
	AJM.settingsControl.targetListBorderColourPicker = JambaHelperSettings:CreateColourPicker(
		AJM.settingsControl,
		halfWidth,
		column2left + 15,
		movingTop - 15,
		L["Border Colour"]
	)
	AJM.settingsControl.targetListBorderColourPicker:SetHasAlpha( true )
	AJM.settingsControl.targetListBorderColourPicker:SetCallback( "OnValueConfirmed", AJM.SettingsBorderColourPickerChanged )	
	movingTop = movingTop - mediaHeight - verticalSpacing
	AJM.settingsControl.targetListMediaBackground = JambaHelperSettings:CreateMediaBackground( 
		AJM.settingsControl, 
		halfWidth, 
		left, 
		movingTop,
		L["Background"]
	)
	AJM.settingsControl.targetListMediaBackground:SetCallback( "OnValueChanged", AJM.SettingsChangeBackgroundStyle )
	AJM.settingsControl.targetListBackgroundColourPicker = JambaHelperSettings:CreateColourPicker(
		AJM.settingsControl,
		halfWidth,
		column2left + 15,
		movingTop - 15,
		L["Background Colour"]
	)
	AJM.settingsControl.targetListBackgroundColourPicker:SetHasAlpha( true )
	AJM.settingsControl.targetListBackgroundColourPicker:SetCallback( "OnValueConfirmed", AJM.SettingsBackgroundColourPickerChanged )
	movingTop = movingTop - mediaHeight - verticalSpacing
	AJM.settingsControl.targetListScaleSlider = JambaHelperSettings:CreateSlider( 
		AJM.settingsControl, 
		headingWidth, 
		left, 
		movingTop, 
		L["Scale"]
	)
	AJM.settingsControl.targetListScaleSlider:SetSliderValues( 0.5, 2, 0.01 )
	AJM.settingsControl.targetListScaleSlider:SetCallback( "OnValueChanged", AJM.SettingsChangeScale )
	movingTop = movingTop - sliderHeight - verticalSpacing	
	JambaHelperSettings:CreateHeading( AJM.settingsControl, L["Target Messages"], movingTop, true )
	movingTop = movingTop - headingHeight	
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

function AJM:SettingsChangeTransparency( event, value )
	AJM.db.frameAlpha = tonumber( value )
	AJM:SettingsRefresh()
	AJM:RefreshTargetList()
end

function AJM:SettingsChangeBorderStyle( event, value )
	AJM.db.borderStyle = value
	AJM:SettingsRefresh()
	AJM:RefreshTargetList()
end

function AJM:SettingsChangeBackgroundStyle( event, value )
	AJM.db.backgroundStyle = value
	AJM:SettingsRefresh()
	AJM:RefreshTargetList()
end

function AJM:SettingsBackgroundColourPickerChanged( event, r, g, b, a )
	AJM.db.frameBackgroundColourR = r
	AJM.db.frameBackgroundColourG = g
	AJM.db.frameBackgroundColourB = b
	AJM.db.frameBackgroundColourA = a
	AJM:SettingsRefresh()
	AJM:RefreshTargetList()
end

function AJM:SettingsBorderColourPickerChanged( event, r, g, b, a )
	AJM.db.frameBorderColourR = r
	AJM.db.frameBorderColourG = g
	AJM.db.frameBorderColourB = b
	AJM.db.frameBorderColourA = a
	AJM:SettingsRefresh()
	AJM:RefreshTargetList()
end

function AJM:SettingsChangeScale( event, value )
	AJM.db.frameScale = tonumber( value )
	AJM:SettingsRefresh()
	AJM:RefreshTargetList()
end

function AJM:SettingsChangeTargetListHealthWidth( event, value )
	AJM.db.targetListHealthWidth = tonumber( value )
	AJM:SettingsRefresh()
	AJM:RefreshTargetList()
end

function AJM:SettingsChangeTargetListHealthHeight( event, value )
	AJM.db.targetListHealthHeight = tonumber( value )
	AJM:SettingsRefresh()
	AJM:RefreshTargetList()
end

function AJM:SettingsToggleMarkTargetsWithRaidIcons( event, checked )
	AJM.db.markTargetsWithRaidIcons = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleShowTargetList( event, checked )
	AJM.db.showTargetList = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleHold1Star( event, checked )
	AJM.db.holdTargets["1"] = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleHold2Circle( event, checked )
	AJM.db.holdTargets["2"] = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleHold3Diamond( event, checked )
	AJM.db.holdTargets["3"] = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleHold4Triangle( event, checked )
	AJM.db.holdTargets["4"] = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleHold5Moon( event, checked )
	AJM.db.holdTargets["5"] = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleHold6Square( event, checked )
	AJM.db.holdTargets["6"] = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleHold7Cross( event, checked )
	AJM.db.holdTargets["7"] = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleHold8Skull( event, checked )
	AJM.db.holdTargets["8"] = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsSetMessageArea( event, value )
	AJM.db.messageArea = value
	AJM:SettingsRefresh()
end

function AJM:SettingsEditMacro1Star( event, text )
	AJM.db.targetMacro["1"] = text
	AJM:SettingsRefresh()
end

function AJM:SettingsEditTag1Star( event, text )
	AJM.db.targetTag["1"] = text
	AJM:SettingsRefresh()
end

function AJM:SettingsEditMacro2Circle( event, text )
	AJM.db.targetMacro["2"] = text
	AJM:SettingsRefresh()
end

function AJM:SettingsEditTag2Circle( event, text )
	AJM.db.targetTag["2"] = text
	AJM:SettingsRefresh()
end

function AJM:SettingsEditMacro3Diamond( event, text )
	AJM.db.targetMacro["3"] = text
	AJM:SettingsRefresh()
end

function AJM:SettingsEditTag3Diamond( event, text )
	AJM.db.targetTag["3"] = text
	AJM:SettingsRefresh()
end

function AJM:SettingsEditMacro4Triangle( event, text )
	AJM.db.targetMacro["4"] = text
	AJM:SettingsRefresh()
end

function AJM:SettingsEditTag4Triangle( event, text )
	AJM.db.targetTag["4"] = text
	AJM:SettingsRefresh()
end

function AJM:SettingsEditMacro5Moon( event, text )
	AJM.db.targetMacro["5"] = text
	AJM:SettingsRefresh()
end

function AJM:SettingsEditTag5Moon( event, text )
	AJM.db.targetTag["5"] = text
	AJM:SettingsRefresh()
end

function AJM:SettingsEditMacro6Square( event, text )
	AJM.db.targetMacro["6"] = text
	AJM:SettingsRefresh()
end

function AJM:SettingsEditTag6Square( event, text )
	AJM.db.targetTag["6"] = text
	AJM:SettingsRefresh()
end

function AJM:SettingsEditMacro7Cross( event, text )
	AJM.db.targetMacro["7"] = text
	AJM:SettingsRefresh()
end

function AJM:SettingsEditTag7Cross( event, text )
	AJM.db.targetTag["7"] = text
	AJM:SettingsRefresh()
end

function AJM:SettingsEditMacro8Skull( event, text )
	AJM.db.targetMacro["8"] = text
	AJM:SettingsRefresh()
end

function AJM:SettingsEditTag8Skull( event, text )
	AJM.db.targetTag["8"] = text
	AJM:SettingsRefresh()
end

-- Settings received.
function AJM:JambaOnSettingsReceived( characterName, settings )	
	if characterName ~= AJM.characterName then
		-- Update the settings.
		AJM.db.framePoint = settings.framePoint
		AJM.db.frameRelativePoint = settings.frameRelativePoint
		AJM.db.frameXOffset = settings.frameXOffset
		AJM.db.frameYOffset = settings.frameYOffset		
		AJM.db.messageArea = settings.messageArea
		AJM.db.markTargetsWithRaidIcons = settings.markTargetsWithRaidIcons
		AJM.db.showTargetList = settings.showTargetList
		AJM.db.targetListHealthHeight = settings.targetListHealthHeight
		AJM.db.targetListHealthWidth = settings.targetListHealthWidth
		AJM.db.frameAlpha = settings.frameAlpha
		AJM.db.frameScale = settings.frameScale
		AJM.db.borderStyle = settings.borderStyle
		AJM.db.backgroundStyle = settings.backgroundStyle
		AJM.db.frameBackgroundColourR = settings.frameBackgroundColourR
		AJM.db.frameBackgroundColourG = settings.frameBackgroundColourG
		AJM.db.frameBackgroundColourB = settings.frameBackgroundColourB
		AJM.db.frameBackgroundColourA = settings.frameBackgroundColourA
		AJM.db.frameBorderColourR = settings.frameBorderColourR
		AJM.db.frameBorderColourG = settings.frameBorderColourG
		AJM.db.frameBorderColourB = settings.frameBorderColourB
		AJM.db.frameBorderColourA = settings.frameBorderColourA			
		AJM.db.holdTargets["1"] = settings.holdTargets["1"]
		AJM.db.holdTargets["2"] = settings.holdTargets["2"]
		AJM.db.holdTargets["3"] = settings.holdTargets["3"]
		AJM.db.holdTargets["4"] = settings.holdTargets["4"]
		AJM.db.holdTargets["5"] = settings.holdTargets["5"]
		AJM.db.holdTargets["6"] = settings.holdTargets["6"]
		AJM.db.holdTargets["7"] = settings.holdTargets["7"]
		AJM.db.holdTargets["8"] = settings.holdTargets["8"]
		AJM.db.targetTag["1"] = settings.targetTag["1"]
		AJM.db.targetTag["2"] = settings.targetTag["2"]
		AJM.db.targetTag["3"] = settings.targetTag["3"]
		AJM.db.targetTag["4"] = settings.targetTag["4"]
		AJM.db.targetTag["5"] = settings.targetTag["5"]
		AJM.db.targetTag["6"] = settings.targetTag["6"]
		AJM.db.targetTag["7"] = settings.targetTag["7"]
		AJM.db.targetTag["8"] = settings.targetTag["8"]
		AJM.db.targetMacro["1"] = settings.targetMacro["1"]
		AJM.db.targetMacro["2"] = settings.targetMacro["2"]
		AJM.db.targetMacro["3"] = settings.targetMacro["3"]
		AJM.db.targetMacro["4"] = settings.targetMacro["4"]
		AJM.db.targetMacro["5"] = settings.targetMacro["5"]
		AJM.db.targetMacro["6"] = settings.targetMacro["6"]
		AJM.db.targetMacro["7"] = settings.targetMacro["7"]
		AJM.db.targetMacro["8"] = settings.targetMacro["8"]				
		-- Refresh the settings.
		AJM:SettingsRefresh()
		AJM:RefreshTargetList()
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
	AJM.settingsControl.targetCheckBoxMarkTargetsWithRaidIcons:SetValue( AJM.db.markTargetsWithRaidIcons )
	AJM.settingsControl.targetCheckBoxShowTargetList:SetValue( AJM.db.showTargetList )
	AJM.settingsControl.targetCheckBoxHold1Star:SetValue( AJM.db.holdTargets["1"] )
	AJM.settingsControl.targetCheckBoxHold2Circle:SetValue( AJM.db.holdTargets["2"] )
	AJM.settingsControl.targetCheckBoxHold3Diamond:SetValue( AJM.db.holdTargets["3"] )
	AJM.settingsControl.targetCheckBoxHold4Triangle:SetValue( AJM.db.holdTargets["4"] )
	AJM.settingsControl.targetCheckBoxHold5Moon:SetValue( AJM.db.holdTargets["5"] )
	AJM.settingsControl.targetCheckBoxHold6Square:SetValue( AJM.db.holdTargets["6"] )
	AJM.settingsControl.targetCheckBoxHold7Cross:SetValue( AJM.db.holdTargets["7"] )
	AJM.settingsControl.targetCheckBoxHold8Skull:SetValue( AJM.db.holdTargets["8"] )
	AJM.settingsControl.targetListHealthWidth:SetValue( AJM.db.targetListHealthWidth )
	AJM.settingsControl.targetListHealthHeight:SetValue( AJM.db.targetListHealthHeight )
	AJM.settingsControl.targetListTransparencySlider:SetValue( AJM.db.frameAlpha )
	AJM.settingsControl.targetListScaleSlider:SetValue( AJM.db.frameScale )
	AJM.settingsControl.targetListMediaBorder:SetValue( AJM.db.borderStyle )
	AJM.settingsControl.targetListMediaBackground:SetValue( AJM.db.backgroundStyle )
	AJM.settingsControl.targetListBackgroundColourPicker:SetColor( AJM.db.frameBackgroundColourR, AJM.db.frameBackgroundColourG, AJM.db.frameBackgroundColourB, AJM.db.frameBackgroundColourA )
	AJM.settingsControl.targetListBorderColourPicker:SetColor( AJM.db.frameBorderColourR, AJM.db.frameBorderColourG, AJM.db.frameBorderColourB, AJM.db.frameBorderColourA )	
	AJM.settingsControlMacros.editMacro1Star:SetText( AJM.db.targetMacro["1"] )
	AJM.settingsControlMacros.editMacro2Circle:SetText( AJM.db.targetMacro["2"] )
	AJM.settingsControlMacros.editMacro3Diamond:SetText( AJM.db.targetMacro["3"] )
	AJM.settingsControlMacros.editMacro4Triangle:SetText( AJM.db.targetMacro["4"] )
	AJM.settingsControlMacros.editMacro5Moon:SetText( AJM.db.targetMacro["5"] )
	AJM.settingsControlMacros.editMacro6Square:SetText( AJM.db.targetMacro["6"] )
	AJM.settingsControlMacros.editMacro7Cross:SetText( AJM.db.targetMacro["7"] )
	AJM.settingsControlMacros.editMacro8Skull:SetText( AJM.db.targetMacro["8"] )	
	AJM.settingsControlMacros.editTag1Star:SetText( AJM.db.targetTag["1"] )
	AJM.settingsControlMacros.editTag2Circle:SetText( AJM.db.targetTag["2"] )
	AJM.settingsControlMacros.editTag3Diamond:SetText( AJM.db.targetTag["3"] )
	AJM.settingsControlMacros.editTag4Triangle:SetText( AJM.db.targetTag["4"] )
	AJM.settingsControlMacros.editTag5Moon:SetText( AJM.db.targetTag["5"] )
	AJM.settingsControlMacros.editTag6Square:SetText( AJM.db.targetTag["6"] )
	AJM.settingsControlMacros.editTag7Cross:SetText( AJM.db.targetTag["7"] )
	AJM.settingsControlMacros.editTag8Skull:SetText( AJM.db.targetTag["8"] )
	AJM.settingsControl.dropdownMessageArea:SetText( AJM.db.messageArea )
end

function AJM:UPDATE_BINDINGS()
	if InCombatLockdown() then
		AJM.refreshUpdateBindingsPending = true
		return
	end
	local containerButtonName, key1, key2
	ClearOverrideBindings( AJM.keyBindingFrame )
	-- Targets 1 to 8.
	for iterateItems = 1, 8, 1 do
		containerButtonName = "JambaTargetSecureButtonTarget"..iterateItems
		key1, key2 = GetBindingKey( "JAMBATARGET"..iterateItems )		
		if key1 then 
			SetOverrideBindingClick( AJM.keyBindingFrame, false, key1, containerButtonName ) 
		end
		if key2 then 
			SetOverrideBindingClick( AJM.keyBindingFrame, false, key2, containerButtonName ) 
		end	
	end
	-- Clear target button.
	containerButtonName = "JambaTargetSecureButtonClearTarget"
	key1, key2 = GetBindingKey( "JAMBACLEARTARGET" )
	if key1 then 
		SetOverrideBindingClick( AJM.keyBindingFrame, false, key1, containerButtonName ) 
	end
	if key2 then 
		SetOverrideBindingClick( AJM.keyBindingFrame, false, key2, containerButtonName ) 
	end	
end

function AJM:PLAYER_REGEN_ENABLED()
	if AJM.refreshUpdateBindingsPending == true then
		AJM:UPDATE_BINDINGS()
		AJM.refreshUpdateBindingsPending = false
	end
	AJM:RefreshTargetList()
end

function AJM:PLAYER_REGEN_DISABLED()
end

function AJM:COMBAT_LOG_EVENT_UNFILTERED( ... )
	if AJM.db.showTargetList == false then
		return
	end
	-- Get the combat log information.
	local wowEvent, timestamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, param1, param2, param3, param4, param5, param6, param7, param8, param9 = ...
	if event == "UNIT_DIED" or event == "UNIT_DESTROYED" then
		-- Iterate all our targets looking for a match.
		for iterateTarget = 1, 8, 1 do
			-- Get this target information.
			local targetInformation = AJM.targetList[iterateTarget]
			local isActive = targetInformation["set"]
			local targetGuid = targetInformation["guid"]
			local targetName = targetInformation["name"]
			-- Did one of our targets die?
			if isActive == true and targetGuid == destGUID then				
				-- Yes, set the active flag to false.
				targetInformation["set"] = false
				targetInformation["guid"] = ""
				targetInformation["name"] = ""
				-- Update their health bar to 0.
				local targetStatusHealth = _G["JambaTargetSecureButtonTarget"..iterateTarget.."StatusHealth"]
				AJM:UpdateHealthStatusBar( targetStatusHealth, 0, 100 )
			end
		end
	end
end

function AJM:UNIT_COMBAT( ... )
	if AJM.db.showTargetList == false then
		return
	end
	local event, unitAffected, action, descriptor, damage, damageType = ...
	local currentTargetGuid = UnitGUID( unitAffected )
	for iterateTarget = 1, 8, 1 do	
		local targetInformation = AJM.targetList[iterateTarget]
		local isActive = targetInformation["set"]
		local targetGuid = targetInformation["guid"]
		local targetName = targetInformation["name"]
		if isActive == true and currentTargetGuid == targetGuid then
			local targetStatusHealth = _G["JambaTargetSecureButtonTarget"..iterateTarget.."StatusHealth"]
			AJM:UpdateHealthStatusBar( targetStatusHealth, UnitHealth( unitAffected ), UnitHealthMax( unitAffected ) )
		end
	end
end

-------------------------------------------------------------------------------------------------------------
-- JambaTarget functionality.
-------------------------------------------------------------------------------------------------------------

function AJM.JambaTargetMarkTargetClick( button, ... )
	-- Cannot mark if in combat.
	if not InCombatLockdown() then
		-- What mouse button was clicked.
		local mouseButton = ...
		-- Was this a clear target action.
		local clearTarget = false
		if mouseButton == "RightButton" then
			clearTarget = true
		end
		-- Get the target number.
		local targetNumber = button:GetID()
		-- Get the target.
		if UnitExists( "target" ) then
			-- Update the list targets and tell the all about this target.
			AJM:TargetListSetActiveTarget( targetNumber, not clearTarget )
		end
	end				
end

-- Global
function JambaTargetMarkTargetKeyPress( keyState )
	-- Cannot mark if in combat.
	if not InCombatLockdown() then
		-- Only show the mark target frame if this player is the master.
		if JambaApi.IsCharacterTheMaster( AJM.characterName ) then
			if keyState == "down" then
				local cursorX, cursorY = GetCursorPosition()
				local uiScale = UIParent:GetEffectiveScale()
				JambaTargetMarkFrame:SetPoint( "CENTER", UIParent, "BOTTOMLEFT", cursorX / uiScale, cursorY / uiScale )
				JambaTargetMarkFrame:Show()
			else
				JambaTargetMarkFrame:Hide() 
			end
		end
	end			
end

function AJM:TargetListSetActiveTarget( targetNumber, isActive )
	-- Update this target information.
	local targetName = UnitName( "target" )
	local targetGuid = UnitGUID( "target" ) 
	-- Set or clear?
	if isActive then
		-- If there is a player target...
		if targetName:trim() ~= "" then
			-- Tell everyone to set this target.
			AJM:TargetUpdateSetCommand( tostring( targetNumber ), targetGuid, targetName, AJM.db.targetTag[tostring( targetNumber )] )
			-- Set a raid icon?
			if AJM.db.markTargetsWithRaidIcons == true then	
				SetRaidTarget( "target", targetNumber )
			end			
		end
	else
		-- Tell everyone to clear this target.
		AJM:TargetUpdateClearCommand( nil, tostring( targetNumber ).." "..AJM.db.targetTag[tostring( targetNumber )] )
		-- Clear a raid icon?
		if AJM.db.markTargetsWithRaidIcons == true then	
			SetRaidTarget( "target", 0 )
		end
	end			
end

function AJM:RefreshTargetList()
	if AJM.db.showTargetList == true then
		if not InCombatLockdown() then
			AJM:DoRefreshTargetList()
		end
	end
end

function AJM:DoRefreshTargetList()
	local topPosition = -AJM.listTargetsTitleHeight + -AJM.listTargetsVerticalSpacing * 2
	local leftPosition = 5
	local heightAddition = AJM.db.targetListHealthHeight + AJM.listTargetsVerticalSpacing
	-- Count the active targets.
	local activeTargetCount = 0
	-- Iterate each target and if active, draw it, one under the other.
	for iterateTarget = 1, 8, 1 do
		local targetInformation = AJM.targetList[iterateTarget]
		local targetIsActive = targetInformation["set"]
		-- Count the number of actice targets.
		if targetIsActive == true then
			activeTargetCount = activeTargetCount + 1
		end
		-- Position and draw the targets.
		local positionTop = topPosition + ((activeTargetCount - 1) * -heightAddition)
		local positionLeft = leftPosition
		local targetButton = _G["JambaTargetSecureButtonTarget"..iterateTarget]
		local targetStatusHealth = _G["JambaTargetSecureButtonTarget"..iterateTarget.."StatusHealth"]
		local targetName = _G["JambaTargetSecureButtonTarget"..iterateTarget.."NameText"]
		-- Make sure the width and heights are correct based on the user settings.
		targetButton:SetWidth( AJM.db.targetListHealthHeight )
		targetButton:SetHeight( AJM.db.targetListHealthHeight )
		targetStatusHealth:SetWidth( AJM.db.targetListHealthWidth - (AJM.db.targetListHealthHeight + 16) )
		targetStatusHealth:SetHeight( AJM.db.targetListHealthHeight )
		targetName:SetWidth( (AJM.db.targetListHealthWidth - (AJM.db.targetListHealthHeight * 2)) - 4 )
		targetName:SetHeight( AJM.db.targetListHealthHeight )			
		-- Show or hide the particular target based on whether or not it is active.
		if targetIsActive == true then
			targetButton:SetPoint( "TOPLEFT", JambaTargetListFrame, "TOPLEFT", positionLeft, positionTop )
			targetButton:Show()
			targetStatusHealth:SetPoint( "TOPLEFT", JambaTargetListFrame, "TOPLEFT", positionLeft + AJM.db.targetListHealthHeight + 4, positionTop )
			targetStatusHealth:Show()
		else
			targetStatusHealth:SetMinMaxValues( 0, 100 )
			targetStatusHealth:SetValue( 0 )
			targetButton:Hide()
			targetStatusHealth:Hide()
		end
	end
	-- If no active targets...
	if activeTargetCount == 0 then
		-- Hide the frame.
		JambaTargetListFrame:Hide()
	else
		-- Show the frame with the correct width and height.
		JambaTargetListFrame:ClearAllPoints()
		JambaTargetListFrame:SetPoint( AJM.db.framePoint, UIParent, AJM.db.frameRelativePoint, AJM.db.frameXOffset, AJM.db.frameYOffset )		
		JambaTargetListFrame:SetWidth( AJM.db.targetListHealthWidth )
		JambaTargetListFrame:SetHeight( AJM.listTargetsTitleHeight + (AJM.db.targetListHealthHeight * activeTargetCount) + (AJM.listTargetsVerticalSpacing * (activeTargetCount + 3)) )
		JambaTargetListFrame:SetAlpha( AJM.db.frameAlpha )
		JambaTargetListFrame:SetScale( AJM.db.frameScale )
		AJM:SettingsUpdateBorderStyle()
		JambaTargetListFrame:Show()
	end
end

function AJM:TargetUpdateSetCommand( targetNumber, targetGuid, targetName, tag )
	if tag ~= nil and tag:trim() ~= "" then 
		self:TargetUpdateSendCommand( targetNumber, targetGuid, targetName, tag )
	else
		self:TargetUpdateMacroText( targetNumber, targetGuid, targetName )
	end
end

function AJM:TargetUpdateSendCommand( targetNumber, targetGuid, targetName, tag )
	AJM:JambaSendCommandToTeam( AJM.COMMAND_SET_MOB_TARGET, targetNumber, targetGuid, targetName, tag )
end

function AJM:TargetUpdateReceiveCommand( targetNumber, targetGuid, targetName, tag )
	-- If this character responds to this tag...
	if JambaApi.DoesCharacterHaveTag( AJM.characterName, tag ) == true then
		-- Then update the macro text for the target specified.
		AJM:TargetUpdateMacroText( targetNumber, targetGuid, targetName )
	end
end

function AJM:TargetUpdateMacroText( targetNumber, targetGuid, targetName )
	-- Was a target provided?
	if targetName then
		-- If not in combat then...
		if not InCombatLockdown() then
			-- Clearing or setting the target?
			local clearTarget = true
			if targetName:trim() ~= "" then
				clearTarget = false
			end
			-- Change the macro text on the secure button to set target.  Set the name of the target 
			-- into the target list.  Update the target information as well.
			local secureButton = _G["JambaTargetSecureButtonTarget"..targetNumber]
			local targetNameText = _G["JambaTargetSecureButtonTarget"..targetNumber.."NameText"]
			local targetStatusHealth = _G["JambaTargetSecureButtonTarget"..targetNumber.."StatusHealth"]
			local targetInformation = AJM.targetList[tonumber( targetNumber )]
			local targetHealthMax = 100
			if not clearTarget then
				-- Get the macro to use.
				local macroToUse = AJM.db.targetMacro[targetNumber]
				-- Substitue the #MOB# for the mobname.
				macroToUse = macroToUse:gsub( "#MOB#", targetName )
AJM:Print( macroToUse )
				secureButton:SetAttribute( "macrotext", macroToUse ) --"/targetexact "..targetName 
				targetNameText:SetText( targetName )
				targetStatusHealth:SetMinMaxValues( 0, targetHealthMax )
				AJM:UpdateHealthStatusBar( targetStatusHealth, targetHealthMax, targetHealthMax )
				targetInformation["set"] = true
				targetInformation["name"] = targetName
				-- If this target is not held...
				if AJM.db.holdTargets[targetNumber] == false then
					-- Then set the unit guid.
					targetInformation["guid"] = targetGuid 	
				else
					-- Otherwise display the held colour.
					targetInformation["guid"] = ""
					targetStatusHealth:SetStatusBarColor( 0.2, 0.2, 1.0, 0.75 )
				end				
			else
				secureButton:SetAttribute( "macrotext", "" )
				targetNameText:SetText( "" )
				targetInformation["set"] = false
				targetInformation["name"] = ""
				targetInformation["guid"] = "" 
			end
			-- Refresh all the targets.
			AJM:RefreshTargetList()
		end
	end
end

function AJM:TargetUpdateClearCommand( info, parameters )
	local targetNumber, tag = strsplit( " ", parameters )
	if tag ~= nil and tag:trim() ~= "" then 
		AJM:TargetUpdateClearSendCommand( targetNumber, tag )
	else
		AJM:TargetUpdateMacroText( targetNumber, "", "" )
	end
end

function AJM:TargetUpdateClearSendCommand( targetNumber, tag )
	AJM:JambaSendCommandToTeam( AJM.COMMAND_CLEAR_MOB_TARGET, targetNumber, tag )
end

function AJM:TargetUpdateClearReceiveCommand( targetNumber, tag )
	-- If this character responds to this tag...
	if JambaApi.DoesCharacterHaveTag( AJM.characterName, tag ) == true then
		-- Then update the macro text for the target specified.
		AJM:TargetUpdateMacroText( targetNumber, "", "" )
	end
end

-- A Jamba command has been received.
function AJM:JambaOnCommandReceived( characterName, commandName, ... )	
	if commandName == AJM.COMMAND_SET_MOB_TARGET then
		AJM:TargetUpdateReceiveCommand( ... )
	end
	if commandName == AJM.COMMAND_CLEAR_MOB_TARGET then		
		AJM:TargetUpdateClearReceiveCommand( ... )
	end
end

JambaApi.Target = {}
