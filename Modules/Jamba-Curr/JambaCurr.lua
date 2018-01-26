--[[
Jamba - Jafula's Awesome Multi-Boxer Assistant
Copyright 2008 - 2018 Michael "Jafula" Miller
License: The MIT License
]]--

-- Create the addon using AceAddon-3.0 and embed some libraries.
local AJM = LibStub( "AceAddon-3.0" ):NewAddon( 
	"JambaCurr", 
	"JambaModule-1.0", 
	"AceConsole-3.0", 
	"AceEvent-3.0",
	"AceTimer-3.0"
)

-- Get the Jamba Utilities Library.
local JambaUtilities = LibStub:GetLibrary( "JambaUtilities-1.0" )
local JambaHelperSettings = LibStub:GetLibrary( "JambaHelperSettings-1.0" )
local LibBagUtils = LibStub:GetLibrary( "LibBagUtils-1.0" )
AJM.SharedMedia = LibStub( "LibSharedMedia-3.0" )

--  Constants and Locale for this module.
AJM.moduleName = "Jamba-Curr"
AJM.settingsDatabaseName = "JambaCurrProfileDB"
AJM.chatCommand = "jamba-curr"
local L = LibStub( "AceLocale-3.0" ):GetLocale( AJM.moduleName )
AJM.parentDisplayName = L["Toon"]
AJM.moduleDisplayName = L["Currency"]
AJM.globalCurrencyFramePrefix = "JambaToonCurrencyListFrame"
AJM.currTypes = {}
AJM.simpleCurrList = {}

-- Currency Identifiers. To add you own just add a new line at the bottom of this part
-- http://www.wowhead.com/currencies
-- Old Stuff
--AJM.currTypes.DalaranJewelcraftingToken = 61
AJM.currTypes.ChampionsSeal = 241
--AJM.currTypes.IllustriousJewelcraftersToken = 361
AJM.currTypes.TolBaradCommendation = 391
AJM.currTypes.LesserCharmOfGoodFortune = 738
AJM.currTypes.ElderCharmOfGoodFortune = 697
AJM.currTypes.MoguRuneOfFate = 752
AJM.currTypes.WarforgedSeal = 776
AJM.currTypes.BloodyCoin = 789
AJM.currTypes.TimelessCoin = 777
--WoD Currency
AJM.currTypes.GarrisonResources = 824
AJM.currTypes.TemperedFate = 994
AJM.currTypes.ApexisCrystal = 823
AJM.currTypes.Darkmoon = 515
AJM.currTypes.Oil = 1101
AJM.currTypes.InevitableFate = 1129
AJM.currTypes.TimeWalker = 1166
AJM.currTypes.Valor = 1191
--Legion Currency
AJM.currTypes.OrderResources = 1220
AJM.currTypes.AncientMana = 1155
AJM.currTypes.NetherShard = 1226
AJM.currTypes.SealofBrokenFate = 1273
AJM.currTypes.ShadowyCoins = 1154
AJM.currTypes.SightlessEye = 1149
AJM.currTypes.TimeWornArtifact = 1268
AJM.currTypes.CuriousCoin = 1275
--7.2
AJM.currTypes.LegionfallWarSupplies = 1342
--7.2.5
AJM.currTypes.CoinsOfAir = 1416
--7.3
AJM.currTypes.WakeningEssence = 1533
AJM.currTypes.VeiledArgunite = 1508

-------------------------------------- End of edit --------------------------------------------------------------

function AJM:CurrencyIconAndName( id )
	local fullName, amount, icon, earnedThisWeek, weeklyMax, totalMax, isDiscovered, quality = GetCurrencyInfo(id)
	local currName = strconcat(" |T"..icon..":20|t", L[" "]..fullName)
	return currName
end	
	
	
-- Settings - the values to store and their defaults for the settings database.
AJM.settings = {
	profile = {
		currGold = true,
		currGoldInGuildBank = false,
		-- Currency default's
		CcurrTypeOne = AJM.currTypes.OrderResources,
		CcurrTypeOneName = AJM:CurrencyIconAndName(AJM.currTypes.OrderResources),
		CcurrTypeTwo = AJM.currTypes.AncientMana,
		CcurrTypeTwoName = AJM:CurrencyIconAndName(AJM.currTypes.AncientMana),
		CcurrTypeThree = AJM.currTypes.TimeWalker,
		CcurrTypeThreeName = AJM:CurrencyIconAndName(AJM.currTypes.TimeWalker),
		CcurrTypeFour = AJM.currTypes.SightlessEye,
		CcurrTypeFourName = AJM:CurrencyIconAndName(AJM.currTypes.SightlessEye),
		CcurrTypeFive = 1,
		CcurrTypeFiveName = "",
		CcurrTypeSix = 1,
		CcurrTypeSixName = "",	
		currencyFrameAlpha = 1.0,
		currencyFramePoint = "CENTER",
		currencyFrameRelativePoint = "CENTER",
		currencyFrameXOffset = 0,
		currencyFrameYOffset = 0,
		currencyFrameBackgroundColourR = 1.0,
		currencyFrameBackgroundColourG = 1.0,
		currencyFrameBackgroundColourB = 1.0,
		currencyFrameBackgroundColourA = 1.0,
		currencyFrameBorderColourR = 1.0,
		currencyFrameBorderColourG = 1.0,
		currencyFrameBorderColourB = 1.0,
		currencyFrameBorderColourA = 1.0,		
		currencyBorderStyle = L["Blizzard Tooltip"],
		currencyBackgroundStyle = L["Blizzard Dialog Background"],
		currencyFontStyle = L["Arial Narrow"],
		currencyFontSize = 12,		
		currencyScale = 1,
		currencyNameWidth = 60,
		currencyPointsWidth = 50,
		currencyGoldWidth = 140,
		currencySpacingWidth = 3,
		currencyLockWindow = false,
		currOpenStartUpMaster = false,
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
			show = {
				type = "input",
				name = L["Show Currency"],
				desc = L["Show the current toon the currency values for all members in the team."],
				usage = "/jamba-curr show",
				get = false,
				set = "JambaToonRequestCurrency",
			},
			hide = {
				type = "input",
				name = L["Hide Currency"],
				desc = L["Hide the currency values for all members in the team."],
				usage = "/jamba-curr hide",
				get = false,
				set = "JambaToonHideCurrency",
			},			
			push = {
				type = "input",
				name = L["Push Settings"],
				desc = L["Push the toon settings to all characters in the team."],
				usage = "/jamba-curr push",
				get = false,
				set = "JambaSendSettings",
			},											
		},
	}
	return configuration
end

local function DebugMessage( ... )
	--AJM:Print( ... )
end

-------------------------------------------------------------------------------------------------------------
-- Command this module sends.
-------------------------------------------------------------------------------------------------------------

AJM.COMMAND_REQUEST_CURRENCY = "SendCurrency"
AJM.COMMAND_HERE_IS_CURRENCY = "HereIsCurrency"

-------------------------------------------------------------------------------------------------------------
-- Messages module sends.
-------------------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------------------------
-- Variables used by module.
-------------------------------------------------------------------------------------------------------------


-------------------------------------------------------------------------------------------------------------
-- Settings Dialogs.
-------------------------------------------------------------------------------------------------------------

local function SettingsCreate()
	AJM.settingsControl = {}
	-- Create the settings panel.
	JambaHelperSettings:CreateSettings(  
		AJM.settingsControl, 
		AJM.moduleDisplayName, 
		AJM.parentDisplayName, 
		AJM.SettingsPushSettingsClick 
	)
	local bottomOfInfo = AJM:SettingsCreateCurrency( JambaHelperSettings:TopOfSettings() )
	AJM.settingsControl.widgetSettings.content:SetHeight( -bottomOfInfo )	
	-- Help
	local helpTable = {}
	JambaHelperSettings:CreateHelp( AJM.settingsControl, helpTable, AJM:GetConfiguration() )		
end




function AJM:SettingsCreateCurrency( top )
	-- Get positions.
	local checkBoxHeight = JambaHelperSettings:GetCheckBoxHeight()
	local sliderHeight = JambaHelperSettings:GetSliderHeight()
	local mediaHeight = JambaHelperSettings:GetMediaHeight()	
	local editBoxHeight = JambaHelperSettings:GetEditBoxHeight()
	local buttonHeight = JambaHelperSettings:GetButtonHeight()
	local dropdownHeight = JambaHelperSettings:GetDropdownHeight() + 10
	local labelHeight = JambaHelperSettings:GetLabelHeight()
	local continueLabelHeight = 18
	local left = JambaHelperSettings:LeftOfSettings()
	local headingHeight = JambaHelperSettings:HeadingHeight()
	local headingWidth = JambaHelperSettings:HeadingWidth( true )
	local horizontalSpacing = JambaHelperSettings:GetHorizontalSpacing()
	local indent = horizontalSpacing * 12
	local verticalSpacing = JambaHelperSettings:GetVerticalSpacing()
	local halfWidth = (headingWidth - horizontalSpacing) / 2
	local thirdWidth = (headingWidth - (horizontalSpacing * 5)) / 5
	local halfWidthSlider = (headingWidth - horizontalSpacing) / 2
	local column2left = left + halfWidthSlider
	local left2 = left + thirdWidth
	local left3 = left + (thirdWidth * 1)
	local right = left + halfWidth + horizontalSpacing
	local movingTop = top
	JambaHelperSettings:CreateHeading( AJM.settingsControl, L["Currency Selection"], movingTop, false )
	movingTop = movingTop - headingHeight
	AJM.settingsControl.checkBoxCurrencyGold = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		left, 
		movingTop, 
		L["Gold"],
		AJM.SettingsToggleCurrencyGold,
		L["Shows the minions Gold"]
	)	
	movingTop = movingTop - checkBoxHeight
	AJM.settingsControl.checkBoxCurrencyGoldInGuildBank = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		left, 
		movingTop, 
		L["Include Gold In Guild Bank"],
		AJM.SettingsToggleCurrencyGoldInGuildBank,
		L["Show Gold In Guild Bank\n\nThis does not update unless you visit the guildbank."]
	)
	--Currency One & Two	
	movingTop = movingTop - checkBoxHeight
	AJM.settingsControl.editBoxCurrencyTypeOneID = JambaHelperSettings:CreateDropdown( 
		AJM.settingsControl,
		halfWidth,
		left + indent,
		movingTop,
		L["Currency One"]
	)	
	AJM.settingsControl.editBoxCurrencyTypeOneID:SetList( AJM.CurrDropDownBox() )
	AJM.settingsControl.editBoxCurrencyTypeOneID:SetCallback( "OnValueChanged",  AJM.EditBoxChangedCurrencyTypeOneID)
	AJM.settingsControl.editBoxCurrencyTypeTwoID = JambaHelperSettings:CreateDropdown( 
		AJM.settingsControl,
		halfWidth,
		right + indent,
		movingTop,
		L["Currency Two"]
	)	
	AJM.settingsControl.editBoxCurrencyTypeTwoID:SetList( AJM.CurrDropDownBox() )
	AJM.settingsControl.editBoxCurrencyTypeTwoID:SetCallback( "OnValueChanged",  AJM.EditBoxChangedCurrencyTypeTwoID)	
	--Currency Three & Four
	movingTop = movingTop - dropdownHeight	
	AJM.settingsControl.editBoxCurrencyTypeThreeID = JambaHelperSettings:CreateDropdown( 
		AJM.settingsControl,
		halfWidth,
		left + indent,
		movingTop,
		L["Currency Three"]
	)	
	AJM.settingsControl.editBoxCurrencyTypeThreeID:SetList( AJM.CurrDropDownBox() )
	AJM.settingsControl.editBoxCurrencyTypeThreeID:SetCallback( "OnValueChanged",  AJM.EditBoxChangedCurrencyTypeThreeID)	
	AJM.settingsControl.editBoxCurrencyTypeFourID = JambaHelperSettings:CreateDropdown( 
		AJM.settingsControl,
		halfWidth,
		right + indent,
		movingTop,
		L["Currency Four"]
	)	
	AJM.settingsControl.editBoxCurrencyTypeFourID:SetList( AJM.CurrDropDownBox() )
	AJM.settingsControl.editBoxCurrencyTypeFourID:SetCallback( "OnValueChanged",  AJM.EditBoxChangedCurrencyTypeFourID)
	--Currency Five & Six
	movingTop = movingTop - dropdownHeight 
	AJM.settingsControl.editBoxCurrencyTypeFiveID = JambaHelperSettings:CreateDropdown( 
		AJM.settingsControl,
		halfWidth,
		left + indent,
		movingTop,
		L["Currency Five"]
	)	
	AJM.settingsControl.editBoxCurrencyTypeFiveID:SetList( AJM.CurrDropDownBox() )
	AJM.settingsControl.editBoxCurrencyTypeFiveID:SetCallback( "OnValueChanged",  AJM.EditBoxChangedCurrencyTypeFiveID)	
	AJM.settingsControl.editBoxCurrencyTypeSixID = JambaHelperSettings:CreateDropdown( 
		AJM.settingsControl,
		halfWidth,
		right + indent,
		movingTop,
		L["Currency Six"]
	)	
	AJM.settingsControl.editBoxCurrencyTypeSixID:SetList( AJM.CurrDropDownBox() )
	AJM.settingsControl.editBoxCurrencyTypeSixID:SetCallback( "OnValueChanged",  AJM.EditBoxChangedCurrencyTypeSixID)
	-- Other Stuff	
	movingTop = movingTop - dropdownHeight
	AJM.settingsControl.currencyButtonShowList = JambaHelperSettings:CreateButton( 
		AJM.settingsControl, 
		headingWidth, 
		left, 
		movingTop, 
		L["Show Currency"], 
		AJM.JambaToonRequestCurrency,
		L["Show Currency Window"]
	)
	movingTop = movingTop - buttonHeight
	AJM.settingsControl.checkBoxCurrencyOpenStartUpMaster = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		left, 
		movingTop, 
		L["Open Currency List On Start Up"],
		AJM.SettingsToggleCurrencyOpenStartUpMaster,
		L["Open Currency List On Start Up.\n\nThe Master Minion Only)"]
	)	
	movingTop = movingTop - checkBoxHeight
	-- Create appearance & layout.
	JambaHelperSettings:CreateHeading( AJM.settingsControl, L["Appearance & Layout"], movingTop, true )
	movingTop = movingTop - headingHeight
	AJM.settingsControl.checkBoxCurrencyLockWindow = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		left, 
		movingTop, 
		L["Lock Currency List"],
		AJM.SettingsToggleCurrencyLockWindow,
		L["Lock Currency List\n\n(Enables Mouse Click-Through)"]
	)	
	movingTop = movingTop - checkBoxHeight		
	AJM.settingsControl.currencyScaleSlider = JambaHelperSettings:CreateSlider( 
		AJM.settingsControl, 
		headingWidth, 
		left, 
		movingTop, 
		L["Scale"]
	)
	AJM.settingsControl.currencyScaleSlider:SetSliderValues( 0.5, 2, 0.01 )
	AJM.settingsControl.currencyScaleSlider:SetCallback( "OnValueChanged", AJM.SettingsChangeScale )
	movingTop = movingTop - sliderHeight - verticalSpacing
	AJM.settingsControl.currencyTransparencySlider = JambaHelperSettings:CreateSlider( 
		AJM.settingsControl, 
		headingWidth, 
		left, 
		movingTop, 
		L["Transparency"]
	)
	AJM.settingsControl.currencyTransparencySlider:SetSliderValues( 0, 1, 0.01 )
	AJM.settingsControl.currencyTransparencySlider:SetCallback( "OnValueChanged", AJM.SettingsChangeTransparency )
	movingTop = movingTop - sliderHeight - verticalSpacing	
	AJM.settingsControl.currencyMediaBorder = JambaHelperSettings:CreateMediaBorder( 
		AJM.settingsControl, 
		halfWidthSlider, 
		left, 
		movingTop,
		L["Border Style"]
	)
	AJM.settingsControl.currencyMediaBorder:SetCallback( "OnValueChanged", AJM.SettingsChangeBorderStyle )

	AJM.settingsControl.currencyBorderColourPicker = JambaHelperSettings:CreateColourPicker(
		AJM.settingsControl,
		halfWidthSlider,
		column2left + 15,
		movingTop - 15,
		L["Border Colour"]
	)
	AJM.settingsControl.currencyBorderColourPicker:SetHasAlpha( true )
	AJM.settingsControl.currencyBorderColourPicker:SetCallback( "OnValueConfirmed", AJM.SettingsBorderColourPickerChanged )	
	movingTop = movingTop - mediaHeight - verticalSpacing
	AJM.settingsControl.currencyMediaBackground = JambaHelperSettings:CreateMediaBackground( 
		AJM.settingsControl, 
		halfWidthSlider, 
		left, 
		movingTop,
		L["Background"]
	)
	AJM.settingsControl.currencyMediaBackground:SetCallback( "OnValueChanged", AJM.SettingsChangeBackgroundStyle )
	AJM.settingsControl.currencyBackgroundColourPicker = JambaHelperSettings:CreateColourPicker(
		AJM.settingsControl,
		halfWidthSlider,
		column2left + 15,
		movingTop - 15,
		L["Background Colour"]
	)
	AJM.settingsControl.currencyBackgroundColourPicker:SetHasAlpha( true )
	AJM.settingsControl.currencyBackgroundColourPicker:SetCallback( "OnValueConfirmed", AJM.SettingsBackgroundColourPickerChanged )
	movingTop = movingTop - mediaHeight - verticalSpacing
	--Font
	AJM.settingsControl.currencyMediaFont = JambaHelperSettings:CreateMediaFont( 
		AJM.settingsControl, 
		halfWidthSlider, 
		left, 
		movingTop,
		L["Font"]
	)
	AJM.settingsControl.currencyMediaFont:SetCallback( "OnValueChanged", AJM.SettingsChangeFontStyle )
	AJM.settingsControl.currencyFontSize = JambaHelperSettings:CreateSlider( 
		AJM.settingsControl, 
		halfWidthSlider, 
		column2left, 
		movingTop, 
		L["Font Size"]
	)	
	AJM.settingsControl.currencyFontSize:SetSliderValues( 8, 20 , 1 )
	AJM.settingsControl.currencyFontSize:SetCallback( "OnValueChanged", AJM.SettingsChangeFontSize )
	movingTop = movingTop - mediaHeight - verticalSpacing
	AJM.settingsControl.currencySliderSpaceForName = JambaHelperSettings:CreateSlider( 
		AJM.settingsControl, 
		headingWidth, 
		left, 
		movingTop, 
		L["Space For Name"]
	)
	AJM.settingsControl.currencySliderSpaceForName:SetSliderValues( 20, 200, 1 )
	AJM.settingsControl.currencySliderSpaceForName:SetCallback( "OnValueChanged", AJM.SettingsChangeSliderSpaceForName )
	movingTop = movingTop - sliderHeight - verticalSpacing
	AJM.settingsControl.currencySliderSpaceForGold = JambaHelperSettings:CreateSlider( 
		AJM.settingsControl, 
		headingWidth, 
		left, 
		movingTop, 
		L["Space For Gold"]
	)
	AJM.settingsControl.currencySliderSpaceForGold:SetSliderValues( 20, 200, 1 )
	AJM.settingsControl.currencySliderSpaceForGold:SetCallback( "OnValueChanged", AJM.SettingsChangeSliderSpaceForGold )
	movingTop = movingTop - sliderHeight - verticalSpacing
	AJM.settingsControl.currencySliderSpaceForPoints = JambaHelperSettings:CreateSlider( 
		AJM.settingsControl, 
		headingWidth, 
		left, 
		movingTop, 
		L["Space For Points"]
	)
	AJM.settingsControl.currencySliderSpaceForPoints:SetSliderValues( 20, 200, 1 )
	AJM.settingsControl.currencySliderSpaceForPoints:SetCallback( "OnValueChanged", AJM.SettingsChangeSliderSpaceForPoints )
	movingTop = movingTop - sliderHeight - verticalSpacing	
	AJM.settingsControl.currencySliderSpaceBetweenValues = JambaHelperSettings:CreateSlider( 
		AJM.settingsControl, 
		headingWidth, 
		left, 
		movingTop, 
		L["Space Between Values"]
	)
	AJM.settingsControl.currencySliderSpaceBetweenValues:SetSliderValues( 0, 20, 1 )
	AJM.settingsControl.currencySliderSpaceBetweenValues:SetCallback( "OnValueChanged", AJM.SettingsChangeSliderSpaceBetweenValues )
	movingTop = movingTop - sliderHeight - verticalSpacing	
	return movingTop	
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
	AJM.settingsControl.checkBoxCurrencyGold:SetValue( AJM.db.currGold )
	AJM.settingsControl.checkBoxCurrencyGoldInGuildBank:SetValue( AJM.db.currGoldInGuildBank )
	AJM.settingsControl.checkBoxCurrencyGoldInGuildBank:SetDisabled( not AJM.db.currGold )

	AJM.settingsControl.editBoxCurrencyTypeOneID:SetValue( AJM.db.CcurrTypeOneName )

	AJM.settingsControl.editBoxCurrencyTypeTwoID:SetValue ( AJM.db.CcurrTypeTwoName )	

	AJM.settingsControl.editBoxCurrencyTypeThreeID:SetValue ( AJM.db.CcurrTypeThreeName )
	
	AJM.settingsControl.editBoxCurrencyTypeFourID:SetValue ( AJM.db.CcurrTypeFourName )

	AJM.settingsControl.editBoxCurrencyTypeFiveID:SetValue ( AJM.db.CcurrTypeFiveName )	

	AJM.settingsControl.editBoxCurrencyTypeSixID:SetValue ( AJM.db.CcurrTypeSixName )
	--state
	AJM.settingsControl.checkBoxCurrencyOpenStartUpMaster:SetValue( AJM.db.currOpenStartUpMaster )
	AJM.settingsControl.currencyTransparencySlider:SetValue( AJM.db.currencyFrameAlpha )
	AJM.settingsControl.currencyScaleSlider:SetValue( AJM.db.currencyScale )
	AJM.settingsControl.currencyMediaBorder:SetValue( AJM.db.currencyBorderStyle )
	AJM.settingsControl.currencyMediaBackground:SetValue( AJM.db.currencyBackgroundStyle )
	AJM.settingsControl.currencyBackgroundColourPicker:SetColor( AJM.db.currencyFrameBackgroundColourR, AJM.db.currencyFrameBackgroundColourG, AJM.db.currencyFrameBackgroundColourB, AJM.db.currencyFrameBackgroundColourA )
	AJM.settingsControl.currencyBorderColourPicker:SetColor( AJM.db.currencyFrameBorderColourR, AJM.db.currencyFrameBorderColourG, AJM.db.currencyFrameBorderColourB, AJM.db.currencyFrameBorderColourA )
	AJM.settingsControl.currencyMediaFont:SetValue( AJM.db.currencyFontStyle )
	AJM.settingsControl.currencyFontSize:SetValue( AJM.db.currencyFontSize )
	AJM.settingsControl.currencySliderSpaceForName:SetValue( AJM.db.currencyNameWidth )
	AJM.settingsControl.currencySliderSpaceForGold:SetValue( AJM.db.currencyGoldWidth )
	AJM.settingsControl.currencySliderSpaceForPoints:SetValue( AJM.db.currencyPointsWidth )
	AJM.settingsControl.currencySliderSpaceBetweenValues:SetValue( AJM.db.currencySpacingWidth )
	AJM.settingsControl.checkBoxCurrencyLockWindow:SetValue( AJM.db.currencyLockWindow )
	if AJM.currencyListFrameCreated == true then
		AJM:CurrencyListSetColumnWidth()
		AJM:SettingsUpdateBorderStyle()
		AJM:SettingsUpdateFontStyle()
		AJM:CurrencyUpdateWindowLock()
		JambaToonCurrencyListFrame:SetScale( AJM.db.currencyScale )
		AJM:UpdateHendingText()
		AJM:CurrencyListSetHeight()
	end
end

function AJM:SettingsPushSettingsClick( event )
	AJM:JambaSendSettings()
end

function AJM:SettingsToggleCurrencyGold( event, checked )
	AJM.db.currGold = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleCurrencyGoldInGuildBank( event, checked )
	AJM.db.currGoldInGuildBank = checked
	AJM:SettingsRefresh()
end


function AJM:EditBoxChangedCurrencyTypeOneID( event, value )
	local currName, id = AJM:MatchCurrValue(value)
		AJM.db.CcurrTypeOne = id
		AJM.db.CcurrTypeOneName = currName
		AJM:JambaToonRequestCurrency()
		AJM:SettingsRefresh()
end


function AJM:EditBoxChangedCurrencyTypeTwoID( event, value )
	local currName, id = AJM:MatchCurrValue(value)
		AJM.db.CcurrTypeTwo = id
		AJM.db.CcurrTypeTwoName = currName
		AJM:JambaToonRequestCurrency()
		AJM:SettingsRefresh()
end


function AJM:EditBoxChangedCurrencyTypeThreeID( event, value )
	local currName, id = AJM:MatchCurrValue(value)
		AJM.db.CcurrTypeThree = id
		AJM.db.CcurrTypeThreeName = currName
		AJM:JambaToonRequestCurrency()
		AJM:SettingsRefresh()
end


function AJM:EditBoxChangedCurrencyTypeFourID( event, value )
	local currName, id = AJM:MatchCurrValue(value)
		AJM.db.CcurrTypeFour = id
		AJM.db.CcurrTypeFourName = currName
		AJM:JambaToonRequestCurrency()
		AJM:SettingsRefresh()
end


function AJM:EditBoxChangedCurrencyTypeFiveID( event, value )
	local currName, id = AJM:MatchCurrValue(value)
		AJM.db.CcurrTypeFive = id
		AJM.db.CcurrTypeFiveName = currName
		AJM:JambaToonRequestCurrency()
		AJM:SettingsRefresh()
end


function AJM:EditBoxChangedCurrencyTypeSixID( event, value )
	--AJM:Print("test", value)
	local currName, id = AJM:MatchCurrValue(value)
		AJM.db.CcurrTypeSix = id
		AJM.db.CcurrTypeSixName = currName
		AJM:JambaToonRequestCurrency()
		AJM:SettingsRefresh()
end

function AJM:SettingsToggleCurrencyOpenStartUpMaster( event, checked )
	AJM.db.currOpenStartUpMaster = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsChangeScale( event, value )
	AJM.db.currencyScale = tonumber( value )
	AJM:SettingsRefresh()
end

function AJM:SettingsChangeTransparency( event, value )
	AJM.db.currencyFrameAlpha = tonumber( value )
	AJM:SettingsRefresh()
end

function AJM:SettingsChangeBorderStyle( event, value )
	AJM.db.currencyBorderStyle = value
	AJM:SettingsRefresh()
end

function AJM:SettingsChangeBackgroundStyle( event, value )
	AJM.db.currencyBackgroundStyle = value
	AJM:SettingsRefresh()
end

function AJM:SettingsBackgroundColourPickerChanged( event, r, g, b, a )
	AJM.db.currencyFrameBackgroundColourR = r
	AJM.db.currencyFrameBackgroundColourG = g
	AJM.db.currencyFrameBackgroundColourB = b
	AJM.db.currencyFrameBackgroundColourA = a
	AJM:SettingsRefresh()
end

function AJM:SettingsBorderColourPickerChanged( event, r, g, b, a )
	AJM.db.currencyFrameBorderColourR = r
	AJM.db.currencyFrameBorderColourG = g
	AJM.db.currencyFrameBorderColourB = b
	AJM.db.currencyFrameBorderColourA = a
	AJM:SettingsRefresh()
end

function AJM:SettingsChangeFontStyle( event, value )
	AJM.db.currencyFontStyle = value
	AJM:SettingsRefresh()
end

function AJM:SettingsChangeFontSize( event, value )
	AJM.db.currencyFontSize = value
	AJM:SettingsRefresh()
end

function AJM:SettingsChangeSliderSpaceForName( event, value )
	AJM.db.currencyNameWidth = tonumber( value )
	AJM:SettingsRefresh()
end

function AJM:SettingsChangeSliderSpaceForGold( event, value )
	AJM.db.currencyGoldWidth = tonumber( value )
	AJM:SettingsRefresh()
end

function AJM:SettingsChangeSliderSpaceForPoints( event, value )
	AJM.db.currencyPointsWidth = tonumber( value )
	AJM:SettingsRefresh()
end

function AJM:SettingsChangeSliderSpaceBetweenValues( event, value )
	AJM.db.currencySpacingWidth = tonumber( value )
	AJM:SettingsRefresh()
end
		
function AJM:SettingsToggleCurrencyLockWindow( event, checked )
	AJM.db.currencyLockWindow = checked
	AJM:CurrencyUpdateWindowLock()
	AJM:SettingsRefresh()
end

-------------------------------------------------------------------------------------------------------------
-- Addon initialization, enabling and disabling.
-------------------------------------------------------------------------------------------------------------

-- Initialise the module.
function AJM:OnInitialize()
	AJM.currencyTotalGold = 0
	AJM.currencyListFrameCreated = false
	AJM.currencyFrameCharacterInfo = {}
	AJM.currentCurrencyValues = {}
	-- Create the settings control.
	SettingsCreate()
	-- Initialise the JambaModule part of this module.
	AJM:JambaModuleInitialize( AJM.settingsControl.widgetSettings.frame )
	-- Populate the settings.
	AJM:SettingsRefresh()
	-- Create the currency list frame.
	AJM:CreateJambaToonCurrencyListFrame()
end

-- Called when the addon is enabled.
function AJM:OnEnable()
	-- WoW events.
	--AJM:RegisterMessage( JambaApi.MESSAGE_MESSAGE_AREAS_CHANGED, "OnMessageAreasChanged" )
	if AJM.db.currOpenStartUpMaster == true then
		if JambaApi.IsCharacterTheMaster( self.characterName ) == true then
			AJM:ScheduleTimer( "JambaToonRequestCurrency", 20 )
		end
	end
end

-- Called when the addon is disabled.
function AJM:OnDisable()
end

-- Settings received.
function AJM:JambaOnSettingsReceived( characterName, settings )	
	if characterName ~= AJM.characterName then
		-- Update the settings.
		AJM.db.currGold = settings.currGold
		AJM.db.currGoldInGuildBank = settings.currGoldInGuildBank
		AJM.db.CcurrTypeOne = settings.CcurrTypeOne
		AJM.db.CcurrTypeOneName = settings.CcurrTypeOneName
		AJM.db.CcurrTypeTwo = settings.CcurrTypeTwo
		AJM.db.CcurrTypeTwoName = settings.CcurrTypeTwoName
		AJM.db.CcurrTypeThree = settings.CcurrTypeThree
		AJM.db.CcurrTypeThreeName = settings.CcurrTypeThreeName
		AJM.db.CcurrTypeFour = settings.CcurrTypeFour
		AJM.db.CcurrTypeFourName = settings.CcurrTypeFourName
		AJM.db.CcurrTypeFive = settings.CcurrTypeFive
		AJM.db.CcurrTypeFiveName = settings.CcurrTypeFiveName
		AJM.db.CcurrTypeSix = settings.CcurrTypeSix
		AJM.db.CcurrTypeSixName = settings.CcurrTypeSixName
		AJM.db.currOpenStartUpMaster = settings.currOpenStartUpMaster
		AJM.db.currencyScale = settings.currencyScale
		AJM.db.currencyFrameAlpha = settings.currencyFrameAlpha
		AJM.db.currencyFramePoint = settings.currencyFramePoint
		AJM.db.currencyFrameRelativePoint = settings.currencyFrameRelativePoint
		AJM.db.currencyFrameXOffset = settings.currencyFrameXOffset
		AJM.db.currencyFrameYOffset = settings.currencyFrameYOffset
		AJM.db.currencyFrameBackgroundColourR = settings.currencyFrameBackgroundColourR
		AJM.db.currencyFrameBackgroundColourG = settings.currencyFrameBackgroundColourG
		AJM.db.currencyFrameBackgroundColourB = settings.currencyFrameBackgroundColourB
		AJM.db.currencyFrameBackgroundColourA = settings.currencyFrameBackgroundColourA
		AJM.db.currencyFrameBorderColourR = settings.currencyFrameBorderColourR
		AJM.db.currencyFrameBorderColourG = settings.currencyFrameBorderColourG
		AJM.db.currencyFrameBorderColourB = settings.currencyFrameBorderColourB
		AJM.db.currencyFrameBorderColourA = settings.currencyFrameBorderColourA	
		AJM.db.currencyBorderStyle = settings.currencyBorderStyle
		AJM.db.currencyBackgroundStyle = settings.currencyBackgroundStyle
		AJM.db.currencyFontSize = settings.currencyFontSize
		AJM.db.currencyFontStyle = settings.currencyFontStyle
		AJM.db.currencyNameWidth = settings.currencyNameWidth
		AJM.db.currencyPointsWidth = settings.currencyPointsWidth
		AJM.db.currencyGoldWidth = settings.currencyGoldWidth
		AJM.db.currencySpacingWidth = settings.currencySpacingWidth
		AJM.db.currencyLockWindow = settings.currencyLockWindow
		-- Refresh the settings.
		AJM:SettingsRefresh()
		-- Tell the player.
		AJM:Print( L["Settings received from A."]( characterName ) )
		-- Tell the team?
		--AJM:JambaSendMessageToTeam( AJM.db.messageArea,  L["Settings received from A."]( characterName ), false )
	end
end

function AJM:CurrDropDownBox()
	for name, id in pairs( AJM.currTypes ) do
		local currName = AJM:CurrencyIconAndName( id )
		AJM.simpleCurrList[currName] = currName		
	end
	AJM.simpleCurrList[""] = ""
	table.sort( AJM.simpleCurrList )
	return AJM.simpleCurrList
end	


function AJM:MatchCurrValue(value)
	if value == "" then	
		return "", 0
	end
	for name, id in pairs( AJM.currTypes ) do
		local currName = AJM:CurrencyIconAndName( id )
		if value == currName then
			return currName, id
		end	
	end
end 

function AJM:CreateJambaToonCurrencyListFrame()
	-- The frame.
	local frame = CreateFrame( "Frame", "JambaToonCurrencyListWindowFrame", UIParent )
	frame.obj = AJM
	frame:SetFrameStrata( "LOW" )
	frame:SetToplevel( false )
	frame:SetClampedToScreen( true )
	frame:EnableMouse( true )
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
			AJM.db.currencyFramePoint = point
			AJM.db.currencyFrameRelativePoint = relativePoint
			AJM.db.currencyFrameXOffset = xOffset
			AJM.db.currencyFrameYOffset = yOffset
		end	)
	frame:SetWidth( 500 )
	frame:SetHeight( 200 )
	frame:ClearAllPoints()
	frame:SetPoint( AJM.db.currencyFramePoint, UIParent, AJM.db.currencyFrameRelativePoint, AJM.db.currencyFrameXOffset, AJM.db.currencyFrameYOffset )
	frame:SetBackdrop( {
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", 
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", 
		tile = true, tileSize = 10, edgeSize = 10, 
		insets = { left = 3, right = 3, top = 3, bottom = 3 }
	} )

	-- Create the title for the frame.
	local titleName = frame:CreateFontString( "JambaToonCurrencyListWindowFrameTitleText", "OVERLAY", "GameFontNormal" )
	titleName:SetPoint( "TOPLEFT", frame, "TOPLEFT", 3, -8 )
	titleName:SetTextColor( NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1.0 )
	titleName:SetText( L["Currency"] )
	titleName:SetWidth( 200 )
	titleName:SetJustifyH( "LEFT" )
	titleName:SetWordWrap( false )
	frame.titleName = titleName
	
	-- Create the headings.
	local left = 10
	local spacing = 50
	local width = 50
	local top = -30
	local parentFrame = frame
	local r = 1.0
	local g = 0.96
	local b = 0.41
	local a = 1.0
	-- Set the characters name font string.
	local frameCharacterName = AJM.globalCurrencyFramePrefix.."TitleCharacterName"
	local frameCharacterNameText = parentFrame:CreateFontString( frameCharacterName.."Text", "OVERLAY", "GameFontNormal" )
	frameCharacterNameText:SetText( L["Toon"] )
	frameCharacterNameText:SetTextColor( r, g, b, a )
	frameCharacterNameText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, top )
	frameCharacterNameText:SetWidth( width * 2.5 )
	frameCharacterNameText:SetJustifyH( "LEFT" )
	frame.characterNameText = frameCharacterNameText
	left = left + (spacing * 2)
	-- Set the Gold font string.
	local frameGold = AJM.globalCurrencyFramePrefix.."TitleGold"
	local frameGoldText = parentFrame:CreateFontString( frameGold.."Text", "OVERLAY", "GameFontNormal" )
	frameGoldText:SetText( L["Gold"] )
	frameGoldText:SetTextColor( r, g, b, a )
	frameGoldText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, top )
	frameGoldText:SetWidth( width )
	frameGoldText:SetJustifyH( "CENTER" )
	frame.GoldText = frameGoldText
	left = left + spacing	
	-- Set the TypeOne font string.
	local frameTypeOne = AJM.globalCurrencyFramePrefix.."TitleTypeOne"
	local frameTypeOneText = parentFrame:CreateFontString( frameTypeOne.."Text", "OVERLAY", "GameFontNormal" )
	frameTypeOneText:SetText( L["CurrOne"] )
	frameTypeOneText:SetTextColor( r, g, b, a )
	frameTypeOneText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, top )
	frameTypeOneText:SetWidth( width )
	frameTypeOneText:SetJustifyH( "CENTER" )
	frame.TypeOneText = frameTypeOneText
	left = left + spacing
	-- Set the TypeTwo font string.
	local frameTypeTwo = AJM.globalCurrencyFramePrefix.."TitleTypeTwo"
	local frameTypeTwoText = parentFrame:CreateFontString( frameTypeTwo.."Text", "OVERLAY", "GameFontNormal" )
	frameTypeTwoText:SetText( L["CurrTwo"] )
	frameTypeTwoText:SetTextColor( r, g, b, a )
	frameTypeTwoText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, top )
	frameTypeTwoText:SetWidth( width )
	frameTypeTwoText:SetJustifyH( "CENTER" )
	frame.TypeTwoText = frameTypeTwoText
	left = left + spacing
	-- Set the TypeThree font string.
	local frameTypeThree = AJM.globalCurrencyFramePrefix.."TitleTypeThree"
	local frameTypeThreeText = parentFrame:CreateFontString( frameTypeThree.."Text", "OVERLAY", "GameFontNormal" )
	frameTypeThreeText:SetText( L["CurrThree"] )
	frameTypeThreeText:SetTextColor( r, g, b, a )
	frameTypeThreeText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, top )
	frameTypeThreeText:SetWidth( width )
	frameTypeThreeText:SetJustifyH( "CENTER" )
	frame.TypeThreeText = frameTypeThreeText
	left = left + spacing	
	-- Set the TypeFour font string.
	local frameTypeFour = AJM.globalCurrencyFramePrefix.."TitleTypeFour"
	local frameTypeFourText = parentFrame:CreateFontString( frameTypeFour.."Text", "OVERLAY", "GameFontNormal" )
	frameTypeFourText:SetText( L["CurrFour"] )
	frameTypeFourText:SetTextColor( r, g, b, a )
	frameTypeFourText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, top )
	frameTypeFourText:SetWidth( width )
	frameTypeFourText:SetJustifyH( "CENTER" )
	frame.TypeFourText = frameTypeFourText
	left = left + spacing
	-- Set the TypeFive font string.
	local frameTypeFive = AJM.globalCurrencyFramePrefix.."TitleTypeFive"
	local frameTypeFiveText = parentFrame:CreateFontString( frameTypeFive.."Text", "OVERLAY", "GameFontNormal" )
	frameTypeFiveText:SetText( L["CurrFive"] )
	frameTypeFiveText:SetTextColor( r, g, b, a )
	frameTypeFiveText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, top )
	frameTypeFiveText:SetWidth( width )
	frameTypeFiveText:SetJustifyH( "CENTER" )
	frame.TypeFiveText = frameTypeFiveText
	left = left + spacing
	-- Set the TypeSix font string.
	local frameTypeSix = AJM.globalCurrencyFramePrefix.."TitleTypeSix"
	local frameTypeSixText = parentFrame:CreateFontString( frameTypeSix.."Text", "OVERLAY", "GameFontNormal" )
	frameTypeSixText:SetText( L["CurrSix"] )
	frameTypeSixText:SetTextColor( r, g, b, a )
	frameTypeSixText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, top )
	frameTypeSixText:SetWidth( width )
	frameTypeSixText:SetJustifyH( "CENTER" )
	frame.TypeSixText = frameTypeSixText
	left = left + spacing
	-- Set the Total Gold font string.
	left = 10
	top = -50
	local frameTotalGoldTitle = AJM.globalCurrencyFramePrefix.."TitleTotalGold"
	local frameTotalGoldTitleText = parentFrame:CreateFontString( frameTotalGoldTitle.."Text", "OVERLAY", "GameFontNormal" )
	frameTotalGoldTitleText:SetText( L["Total"] )
	frameTotalGoldTitleText:SetTextColor( r, g, b, a )
	frameTotalGoldTitleText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, top )
	frameTotalGoldTitleText:SetWidth( width )
	frameTotalGoldTitleText:SetJustifyH( "LEFT" )
	frame.TotalGoldTitleText = frameTotalGoldTitleText

	local frameTotalGoldGuildTitle = AJM.globalCurrencyFramePrefix.."TitleTotalGoldGuild"
	local frameTotalGoldGuildTitleText = parentFrame:CreateFontString( frameTotalGoldGuildTitle.."Text", "OVERLAY", "GameFontNormal" )
	frameTotalGoldGuildTitleText:SetText( L["Guild"] )
	frameTotalGoldGuildTitleText:SetTextColor( r, g, b, a )
	frameTotalGoldGuildTitleText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, top )
	frameTotalGoldGuildTitleText:SetWidth( width )
	frameTotalGoldGuildTitleText:SetJustifyH( "LEFT" )
	frame.TotalGoldGuildTitleText = frameTotalGoldGuildTitleText
	
	local frameTotalGold = AJM.globalCurrencyFramePrefix.."TotalGold"
	local frameTotalGoldText = parentFrame:CreateFontString( frameTotalGold.."Text", "OVERLAY", "GameFontNormal" )
	frameTotalGoldText:SetText( "0" )
	frameTotalGoldText:SetTextColor( r, g, b, a )
	frameTotalGoldText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, top )
	frameTotalGoldText:SetWidth( width )
	frameTotalGoldText:SetJustifyH( "RIGHT" )
	frame.TotalGoldText = frameTotalGoldText

	local frameTotalGoldGuild = AJM.globalCurrencyFramePrefix.."TotalGoldGuild"
	local frameTotalGoldGuildText = parentFrame:CreateFontString( frameTotalGoldGuild.."Text", "OVERLAY", "GameFontNormal" )
	frameTotalGoldGuildText:SetText( "0" )
	frameTotalGoldGuildText:SetTextColor( r, g, b, a )
	frameTotalGoldGuildText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, top )
	frameTotalGoldGuildText:SetWidth( width )
	frameTotalGoldGuildText:SetJustifyH( "RIGHT" )
	frame.TotalGoldGuildText = frameTotalGoldGuildText
	
	-- Set frame width.
	frame:SetWidth( left + 10 )
	
	-- Set transparency of the the frame (and all its children).
	frame:SetAlpha( AJM.db.currencyFrameAlpha )
	
	-- Set scale.
	frame:SetScale( AJM.db.currencyScale )
	
	-- Set the global frame reference for this frame.
	JambaToonCurrencyListFrame = frame
	
	-- Close.
	local closeButton = CreateFrame( "Button", AJM.globalCurrencyFramePrefix.."ButtonClose", frame, "UIPanelCloseButton" )
	closeButton:SetScript( "OnClick", function() JambaToonCurrencyListFrame:Hide() end )
	closeButton:SetPoint( "TOPRIGHT", frame, "TOPRIGHT", 0, 0 )	
	frame.closeButton = closeButton
	
	-- Update.
	local updateButton = CreateFrame( "Button", AJM.globalCurrencyFramePrefix.."ButtonUpdate", frame, "UIPanelButtonTemplate" )
	updateButton:SetScript( "OnClick", function() AJM:JambaToonRequestCurrency() end )
	updateButton:SetPoint( "TOPRIGHT", frame, "TOPRIGHT", -30, -4 )
	updateButton:SetHeight( 22 )
	updateButton:SetWidth( 55 )
	updateButton:SetText( L["Update"] )		
	
	frame.updateButton = updateButton
	
	AJM:SettingsUpdateBorderStyle()
	AJM:CurrencyUpdateWindowLock()
	AJM:SettingsUpdateFontStyle()
	JambaToonCurrencyListFrame:Hide()
	AJM.currencyListFrameCreated = true
	AJM:UpdateHendingText()
	AJM:CurrencyListSetHeight()
end

function AJM:UpdateHendingText()
	local parentFrame = JambaToonCurrencyListFrame
	-- Type One
	local name, amount, icon, earnedThisWeek, weeklyMax, totalMax, isDiscovered = GetCurrencyInfo( AJM.db.CcurrTypeOne )
	if icon ~= nil then
		local iconTextureString = strconcat(" |T"..icon..":20|t")
			parentFrame.TypeOneText:SetText( iconTextureString )
	end		
	-- Type Two
	local name, amount, icon, earnedThisWeek, weeklyMax, totalMax, isDiscovered = GetCurrencyInfo( AJM.db.CcurrTypeTwo )
	if icon ~= nil then	
		local iconTextureString = strconcat(" |T"..icon..":20|t")
			parentFrame.TypeTwoText:SetText( iconTextureString )
	end
	-- Type Three
	local name, amount, icon, earnedThisWeek, weeklyMax, totalMax, isDiscovered = GetCurrencyInfo( AJM.db.CcurrTypeThree )
	if icon ~= nil then
		local iconTextureString = strconcat(" |T"..icon..":20|t")
			parentFrame.TypeThreeText:SetText( iconTextureString )	
	end
	-- Type Four
	local name, amount, icon, earnedThisWeek, weeklyMax, totalMax, isDiscovered = GetCurrencyInfo( AJM.db.CcurrTypeFour )
	if icon ~= nil then	
		local iconTextureString = strconcat(" |T"..icon..":20|t")
			parentFrame.TypeFourText:SetText( iconTextureString )
	end
	-- Type Five
	local name, amount, icon, earnedThisWeek, weeklyMax, totalMax, isDiscovered = GetCurrencyInfo( AJM.db.CcurrTypeFive )
	if icon ~= nil then	
		local iconTextureString = strconcat(" |T"..icon..":20|t")
			parentFrame.TypeFiveText:SetText( iconTextureString )
	end
	-- Type six
	local name, amount, icon, earnedThisWeek, weeklyMax, totalMax, isDiscovered = GetCurrencyInfo( AJM.db.CcurrTypeSix )
	if icon ~= nil then	
		local iconTextureString = strconcat(" |T"..icon..":20|t")
			parentFrame.TypeSixText:SetText( iconTextureString )
	end
end

function AJM:CurrencyUpdateWindowLock()
	if AJM.db.currencyLockWindow == false then
		JambaToonCurrencyListFrame:EnableMouse( true )
	else
		JambaToonCurrencyListFrame:EnableMouse( false )
	end
end

function AJM:SettingsUpdateBorderStyle()
	local borderStyle = AJM.SharedMedia:Fetch( "border", AJM.db.currencyBorderStyle )
	local backgroundStyle = AJM.SharedMedia:Fetch( "background", AJM.db.currencyBackgroundStyle )
	local frame = JambaToonCurrencyListFrame
	frame:SetBackdrop( {
		bgFile = backgroundStyle, 
		edgeFile = borderStyle, 
		tile = true, tileSize = frame:GetWidth(), edgeSize = 10, 
		insets = { left = 3, right = 3, top = 3, bottom = 3 }
	} )
	frame:SetBackdropColor( AJM.db.currencyFrameBackgroundColourR, AJM.db.currencyFrameBackgroundColourG, AJM.db.currencyFrameBackgroundColourB, AJM.db.currencyFrameBackgroundColourA )
	frame:SetBackdropBorderColor( AJM.db.currencyFrameBorderColourR, AJM.db.currencyFrameBorderColourG, AJM.db.currencyFrameBorderColourB, AJM.db.currencyFrameBorderColourA )
	frame:ClearAllPoints()
	frame:SetAlpha( AJM.db.currencyFrameAlpha )
	frame:SetPoint( AJM.db.currencyFramePoint, UIParent, AJM.db.currencyFrameRelativePoint, AJM.db.currencyFrameXOffset, AJM.db.currencyFrameYOffset )
end

function AJM:SettingsUpdateFontStyle()
	local textFont = AJM.SharedMedia:Fetch( "font", AJM.db.currencyFontStyle )
	local textSize = AJM.db.currencyFontSize
	local frame = JambaToonCurrencyListFrame
	frame.titleName:SetFont( textFont , textSize , "OUTLINE")
	frame.characterNameText:SetFont( textFont , textSize , "OUTLINE")
	frame.GoldText:SetFont( textFont , textSize , "OUTLINE")
	frame.TotalGoldGuildTitleText:SetFont( textFont , textSize , "OUTLINE")
	frame.TotalGoldGuildText:SetFont( textFont , textSize , "OUTLINE")
	frame.TotalGoldText:SetFont( textFont , textSize , "OUTLINE")
	frame.TotalGoldTitleText:SetFont( textFont , textSize , "OUTLINE")
	for characterName, currencyFrameCharacterInfo in pairs( AJM.currencyFrameCharacterInfo ) do
		--AJM:Print("test", characterName)
		--currencyFrameCharacterInfo.characterNameText:SetFont( textFont , textSize , "OUTLINE")
		currencyFrameCharacterInfo.characterNameText:SetFont( textFont , textSize , "OUTLINE")
		currencyFrameCharacterInfo.GoldText:SetFont( textFont , textSize , "OUTLINE")
		currencyFrameCharacterInfo.TypeOneText:SetFont( textFont , textSize , "OUTLINE")
		currencyFrameCharacterInfo.TypeTwoText:SetFont( textFont , textSize , "OUTLINE")
		currencyFrameCharacterInfo.TypeThreeText:SetFont( textFont , textSize , "OUTLINE")
		currencyFrameCharacterInfo.TypeFourText:SetFont( textFont , textSize , "OUTLINE")
		currencyFrameCharacterInfo.TypeFiveText:SetFont( textFont , textSize , "OUTLINE")
		currencyFrameCharacterInfo.TypeSixText:SetFont( textFont , textSize , "OUTLINE")
	end
end


function AJM:CurrencyListSetHeight()
	local additionalLines = 0
	local addHeight = 0
	if AJM.db.currGold == true then
		if AJM.db.currGoldInGuildBank == true then
			additionalLines = 2
			addHeight = 7
		else
			additionalLines = 1
			addHeight = 5
		end
	end
	JambaToonCurrencyListFrame:SetHeight( 56 + (( JambaApi.GetTeamListMaximumOrderOnline() + additionalLines) * 15) + addHeight )
end

function AJM:CurrencyListSetColumnWidth()
	local nameWidth = AJM.db.currencyNameWidth
	local pointsWidth = AJM.db.currencyPointsWidth
	local goldWidth = AJM.db.currencyGoldWidth
	local spacingWidth = AJM.db.currencySpacingWidth
	local frameHorizontalSpacing = 10
	local numberOfPointsColumns = 0
	local parentFrame = JambaToonCurrencyListFrame
	local headingRowTopPoint = -30
	local left = frameHorizontalSpacing
	local haveGold = 0
	-- Heading rows.
	parentFrame.characterNameText:SetWidth( nameWidth )
	parentFrame.characterNameText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, headingRowTopPoint )
	left = left + nameWidth + spacingWidth
 	if AJM.db.currGold == true then
		parentFrame.GoldText:SetWidth( goldWidth )
		parentFrame.GoldText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, headingRowTopPoint )
		left = left + goldWidth + (spacingWidth * 3)
		parentFrame.GoldText:Show()
		haveGold = 1
	else
		parentFrame.GoldText:Hide()
		haveGold = 0
	end
	if AJM.db.CcurrTypeOneName == "" then
		parentFrame.TypeOneText:Hide()
	else	
		parentFrame.TypeOneText:SetWidth( pointsWidth )
		parentFrame.TypeOneText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, headingRowTopPoint )
		left = left + pointsWidth + spacingWidth
		numberOfPointsColumns = numberOfPointsColumns + 1
		parentFrame.TypeOneText:Show()
	end
	if AJM.db.CcurrTypeTwoName == "" then
		parentFrame.TypeTwoText:Hide()
	else	
		parentFrame.TypeTwoText:SetWidth( pointsWidth )
		parentFrame.TypeTwoText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, headingRowTopPoint )
		left = left + pointsWidth + spacingWidth
		numberOfPointsColumns = numberOfPointsColumns + 1
		parentFrame.TypeTwoText:Show()
	end
	if AJM.db.CcurrTypeThreeName == "" then
		parentFrame.TypeThreeText:Hide()
	else	
		parentFrame.TypeThreeText:SetWidth( pointsWidth )
		parentFrame.TypeThreeText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, headingRowTopPoint )
		left = left + pointsWidth + spacingWidth
		numberOfPointsColumns = numberOfPointsColumns + 1
		parentFrame.TypeThreeText:Show()
	end	
	if AJM.db.CcurrTypeFourName == "" then
		parentFrame.TypeFourText:Hide()
	else	
		parentFrame.TypeFourText:SetWidth( pointsWidth )
		parentFrame.TypeFourText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, headingRowTopPoint )
		left = left + pointsWidth + spacingWidth
		numberOfPointsColumns = numberOfPointsColumns + 1
		parentFrame.TypeFourText:Show()
	end
	if AJM.db.CcurrTypeFiveName == "" then
		parentFrame.TypeFiveText:Hide()
	else	
		parentFrame.TypeFiveText:SetWidth( pointsWidth )
		parentFrame.TypeFiveText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, headingRowTopPoint )
		left = left + pointsWidth + spacingWidth
		numberOfPointsColumns = numberOfPointsColumns + 1
		parentFrame.TypeFiveText:Show()
	end
	if AJM.db.CcurrTypeSixName == "" then
		parentFrame.TypeSixText:Hide()
	else
		parentFrame.TypeSixText:SetWidth( pointsWidth )
		parentFrame.TypeSixText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, headingRowTopPoint )
		left = left + pointsWidth + spacingWidth
		numberOfPointsColumns = numberOfPointsColumns + 1
		parentFrame.TypeSixText:Show()
	end
	-- Character rows.
	for characterName, currencyFrameCharacterInfo in pairs( AJM.currencyFrameCharacterInfo ) do
		if JambaPrivate.Team.GetCharacterOnlineStatus (characterName) == true then
			local left = frameHorizontalSpacing
			local characterRowTopPoint = currencyFrameCharacterInfo.characterRowTopPoint
				currencyFrameCharacterInfo.characterNameText:SetWidth( nameWidth )
				currencyFrameCharacterInfo.characterNameText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, characterRowTopPoint )
				left = left + nameWidth + spacingWidth
			if AJM.db.currGold == true then
				currencyFrameCharacterInfo.GoldText:SetWidth( goldWidth )
				currencyFrameCharacterInfo.GoldText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, characterRowTopPoint )
				left = left + goldWidth + (spacingWidth * 3)
				currencyFrameCharacterInfo.GoldText:Show()
			else
				currencyFrameCharacterInfo.GoldText:Hide()
			end
			if AJM.db.CcurrTypeOneName == "" then
				currencyFrameCharacterInfo.TypeOneText:Hide()
			else
				currencyFrameCharacterInfo.TypeOneText:SetWidth( pointsWidth )
				currencyFrameCharacterInfo.TypeOneText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, characterRowTopPoint )
				left = left + pointsWidth + spacingWidth
				currencyFrameCharacterInfo.TypeOneText:Show()
			end
			if AJM.db.CcurrTypeTwoName == "" then
				currencyFrameCharacterInfo.TypeTwoText:Hide()
			else
				currencyFrameCharacterInfo.TypeTwoText:SetWidth( pointsWidth )
				currencyFrameCharacterInfo.TypeTwoText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, characterRowTopPoint )
				left = left + pointsWidth + spacingWidth
				currencyFrameCharacterInfo.TypeTwoText:Show()
			end
			if AJM.db.CcurrTypeThreeName == "" then
				currencyFrameCharacterInfo.TypeThreeText:Hide()
			else	
				currencyFrameCharacterInfo.TypeThreeText:SetWidth( pointsWidth )
				currencyFrameCharacterInfo.TypeThreeText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, characterRowTopPoint )
				left = left + pointsWidth + spacingWidth
				currencyFrameCharacterInfo.TypeThreeText:Show()
			end		
			if AJM.db.CcurrTypeFourName == "" then
				currencyFrameCharacterInfo.TypeFourText:Hide()
			else
				currencyFrameCharacterInfo.TypeFourText:SetWidth( pointsWidth )
				currencyFrameCharacterInfo.TypeFourText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, characterRowTopPoint )
				left = left + pointsWidth + spacingWidth
				currencyFrameCharacterInfo.TypeFourText:Show()
			end
			if AJM.db.CcurrTypeFiveName == "" then
				currencyFrameCharacterInfo.TypeFiveText:Hide()
			else	
				currencyFrameCharacterInfo.TypeFiveText:SetWidth( pointsWidth )
				currencyFrameCharacterInfo.TypeFiveText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, characterRowTopPoint )
				left = left + pointsWidth + spacingWidth
				currencyFrameCharacterInfo.TypeFiveText:Show()
	
			end
			if AJM.db.CcurrTypeSixName == "" then
				currencyFrameCharacterInfo.TypeSixText:Hide()
			else
				currencyFrameCharacterInfo.TypeSixText:SetWidth( pointsWidth )
				currencyFrameCharacterInfo.TypeSixText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, characterRowTopPoint )
				left = left + pointsWidth + spacingWidth
				currencyFrameCharacterInfo.TypeSixText:Show()
			end		
		end
	end	
	-- Parent frame width and title.
	local finalParentWidth = frameHorizontalSpacing + nameWidth + spacingWidth + (haveGold * (goldWidth + (spacingWidth * 3))) + (numberOfPointsColumns * (pointsWidth + spacingWidth)) + frameHorizontalSpacing
	if finalParentWidth < 95 then
		finalParentWidth = 95
	end
	local widthOfCloseAndUpdateButtons = 70
	parentFrame.titleName:SetWidth( finalParentWidth - widthOfCloseAndUpdateButtons - frameHorizontalSpacing - frameHorizontalSpacing )
	parentFrame.titleName:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", frameHorizontalSpacing, -9 )
	if AJM.db.currGold == true then
		if numberOfPointsColumns > 1 then
			parentFrame.titleName:SetText( L["Jamba Currency"] )
		else
			parentFrame.titleName:SetText( L["Currency"] )
		end
	else
		if numberOfPointsColumns < 2 then
			parentFrame.titleName:SetText( "" )
		end
		if numberOfPointsColumns == 2 then
			parentFrame.titleName:SetText( L["Curr"] )
		end
		if (numberOfPointsColumns >= 3) and (numberOfPointsColumns <= 4) then
			parentFrame.titleName:SetText( L["Currency"] )
		end
		if numberOfPointsColumns > 4 then
			parentFrame.titleName:SetText( L["Jamba Currency"] )
		end
	end
	parentFrame:SetWidth( finalParentWidth )
	-- Total Gold.
	local nameLeft = frameHorizontalSpacing
	local goldLeft = frameHorizontalSpacing + nameWidth + spacingWidth
	--local guildTop = -35 - ((JambaApi.GetTeamListMaximumOrder() + 1) * 15) - 5
	--local goldTop = -35 - ((JambaApi.GetTeamListMaximumOrder() + 1) * 15) - 7	
	local guildTop = -35 - ((JambaApi.GetTeamListMaximumOrderOnline() + 1) * 15) - 5
	local goldTop = -35 - ((JambaApi.GetTeamListMaximumOrderOnline() + 1) * 15) - 7	
	if AJM.db.currGold == true then
		if AJM.db.currGoldInGuildBank == true then
			parentFrame.TotalGoldGuildTitleText:SetWidth( nameWidth )
			parentFrame.TotalGoldGuildTitleText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", nameLeft, guildTop )
			parentFrame.TotalGoldGuildTitleText:Show()
			parentFrame.TotalGoldGuildText:SetWidth( goldWidth )
			parentFrame.TotalGoldGuildText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", goldLeft, guildTop )
			parentFrame.TotalGoldGuildText:Show()
			--goldTop = -35 - ((JambaApi.GetTeamListMaximumOrder() + 2) * 15) - 5
			goldTop = -35 - ((JambaApi.GetTeamListMaximumOrderOnline() + 2) * 15) - 5
		else
			parentFrame.TotalGoldGuildTitleText:Hide()
			parentFrame.TotalGoldGuildText:Hide()			
		end
		parentFrame.TotalGoldTitleText:SetWidth( nameWidth )
		parentFrame.TotalGoldTitleText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", nameLeft, goldTop )
		parentFrame.TotalGoldTitleText:Show()
		parentFrame.TotalGoldText:SetWidth( goldWidth )
		parentFrame.TotalGoldText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", goldLeft, goldTop )
		parentFrame.TotalGoldText:Show()
	else
		parentFrame.TotalGoldTitleText:Hide()
		parentFrame.TotalGoldText:Hide()
		parentFrame.TotalGoldGuildTitleText:Hide()
		parentFrame.TotalGoldGuildText:Hide()	
	end
end

	


function AJM:CreateJambaCurrencyFrameInfo( characterName, parentFrame )
	--AJM.Print("makelist", characterName)
	--if JambaPrivate.Team.GetCharacterOnlineStatus (characterName) == true then
	local left = 10
	local spacing = 50
	local width = 50
	local top = 0
	--local top = -35 + (-15 * JambaApi.GetPositionForCharacterName( characterName ))
	-- WHAT THE HELL IS GOING ON HERE! Ebony!
		local height1 = -35 + ( -15 * JambaApi.GetPositionForCharacterName( characterName) )
		local height2 = -35 + ( -15 * JambaApi.GetPositionForCharacterNameOnline( characterName) )
		if height1 < height2 then
			--AJM:Print("greater than ", characterName )
			top = height2
		elseif height1 > height2 then
			top = height2
		else
			top = height2
		end	
	--AJM:Print("Top", top)
	-- Create the table to hold the status bars for this character.	
	AJM.currencyFrameCharacterInfo[characterName] = {}
	-- Get the character info table.
	local currencyFrameCharacterInfo = AJM.currencyFrameCharacterInfo[characterName]
	currencyFrameCharacterInfo.characterRowTopPoint = top
	-- Set the characters name font string.
	local frameCharacterName = AJM.globalCurrencyFramePrefix.."CharacterName"
	local frameCharacterNameText = parentFrame:CreateFontString( frameCharacterName.."Text", "OVERLAY", "GameFontNormal" )
	frameCharacterNameText:SetText( Ambiguate( characterName , "none" ) )
	frameCharacterNameText:SetTextColor( 1.00, 1.00, 1.00, 1.00 )
	frameCharacterNameText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, top )
	frameCharacterNameText:SetWidth( width * 2.5 )
	frameCharacterNameText:SetJustifyH( "LEFT" )
	currencyFrameCharacterInfo.characterNameText = frameCharacterNameText
	left = left + (spacing * 2)
	-- Set the Gold font string.
	local frameGold = AJM.globalCurrencyFramePrefix.."Gold"
	local frameGoldText = parentFrame:CreateFontString( frameGold.."Text", "OVERLAY", "GameFontNormal" )
	frameGoldText:SetText( "0" )
	frameGoldText:SetTextColor( 1.00, 1.00, 1.00, 1.00 )
	frameGoldText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, top )
	frameGoldText:SetWidth( width )
	frameGoldText:SetJustifyH( "RIGHT" )
	currencyFrameCharacterInfo.GoldText = frameGoldText
	left = left + spacing	
	-- Set the TypeOne font string.
	local frameTypeOne = AJM.globalCurrencyFramePrefix.."TypeOne"
	local frameTypeOneText = parentFrame:CreateFontString( frameTypeOne.."Text", "OVERLAY", "GameFontNormal" )
	frameTypeOneText:SetText( "0" )
	frameTypeOneText:SetTextColor( 1.00, 1.00, 1.00, 1.00 )
	frameTypeOneText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, top )
	frameTypeOneText:SetWidth( width )
	frameTypeOneText:SetJustifyH( "CENTER" )
	currencyFrameCharacterInfo.TypeOneText = frameTypeOneText
	left = left + spacing
	-- Set the TypeTwo font string.
	local frameTypeTwo = AJM.globalCurrencyFramePrefix.."TypeTwo"
	local frameTypeTwoText = parentFrame:CreateFontString( frameTypeTwo.."Text", "OVERLAY", "GameFontNormal" )
	frameTypeTwoText:SetText( "0" )
	frameTypeTwoText:SetTextColor( 1.00, 1.00, 1.00, 1.00 )
	frameTypeTwoText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, top )
	frameTypeTwoText:SetWidth( width )
	frameTypeTwoText:SetJustifyH( "CENTER" )
	currencyFrameCharacterInfo.TypeTwoText = frameTypeTwoText
	left = left + spacing
		-- Set the TypeThree font string.
	local frameTypeThree = AJM.globalCurrencyFramePrefix.."TypeThree"
	local frameTypeThreeText = parentFrame:CreateFontString( frameTypeThree.."Text", "OVERLAY", "GameFontNormal" )
	frameTypeThreeText:SetText( "0" )
	frameTypeThreeText:SetTextColor( 1.00, 1.00, 1.00, 1.00 )
	frameTypeThreeText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, top )
	frameTypeThreeText:SetWidth( width )
	frameTypeThreeText:SetJustifyH( "CENTER" )
	currencyFrameCharacterInfo.TypeThreeText = frameTypeThreeText
	left = left + spacing
	-- Set the TypeFour font string.
	local frameTypeFour = AJM.globalCurrencyFramePrefix.."TypeFour"
	local frameTypeFourText = parentFrame:CreateFontString( frameTypeFour.."Text", "OVERLAY", "GameFontNormal" )
	frameTypeFourText:SetText( "0" )
	frameTypeFourText:SetTextColor( 1.00, 1.00, 1.00, 1.00 )
	frameTypeFourText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, top )
	frameTypeFourText:SetWidth( width )
	frameTypeFourText:SetJustifyH( "CENTER" )
	currencyFrameCharacterInfo.TypeFourText = frameTypeFourText
	left = left + spacing
	-- Set the TypeFive font string.
	local frameTypeFive = AJM.globalCurrencyFramePrefix.."TypeFive"
	local frameTypeFiveText = parentFrame:CreateFontString( frameTypeFive.."Text", "OVERLAY", "GameFontNormal" )
	frameTypeFiveText:SetText( "0" )
	frameTypeFiveText:SetTextColor( 1.00, 1.00, 1.00, 1.00 )
	frameTypeFiveText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, top )
	frameTypeFiveText:SetWidth( width )
	frameTypeFiveText:SetJustifyH( "CENTER" )
	currencyFrameCharacterInfo.TypeFiveText = frameTypeFiveText
	left = left + spacing
	-- Set the TypeSix font string.
	local frameTypeSix = AJM.globalCurrencyFramePrefix.."TypeSix"
	local frameTypeSixText = parentFrame:CreateFontString( frameTypeSix.."Text", "OVERLAY", "GameFontNormal" )
	frameTypeSixText:SetText( "0" )
	frameTypeSixText:SetTextColor( 1.00, 1.00, 1.00, 1.00 )
	frameTypeSixText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, top )
	frameTypeSixText:SetWidth( width )
	frameTypeSixText:SetJustifyH( "CENTER" )
	currencyFrameCharacterInfo.TypeSixText = frameTypeSixText
	left = left + spacing
	
	AJM:SettingsUpdateFontStyle()
end

function AJM:JambaToonHideCurrency()
	JambaToonCurrencyListFrame:Hide()
end

function AJM:JambaToonRequestCurrency()
	-- Colour Light Red.
	local r = 1.0
	local g = 0.42
	local b = 0.42
	local a = 0.6
	for characterName, currencyFrameCharacterInfo in pairs( AJM.currencyFrameCharacterInfo ) do
		--AJM.Print("DoRequestCurrency", characterName)
		-- Change Hight if a new member joins the team or leaves the team.
		local height1 = currencyFrameCharacterInfo.characterRowTopPoint
		local height2 = -35 + ( -15 * JambaApi.GetPositionForCharacterNameOnline( characterName) )
			if height1 < height2 then
				currencyFrameCharacterInfo.characterRowTopPoint = height2
			elseif height1 > height2 then
				currencyFrameCharacterInfo.characterRowTopPoint = height2
			end	
		if JambaApi.GetCharacterOnlineStatus ( characterName ) == false then
			-- Hides currency for offline members.
			--AJM.Print("offlineRemove", characterName )
			currencyFrameCharacterInfo.characterNameText:Hide()
			currencyFrameCharacterInfo.GoldText:Hide()
			currencyFrameCharacterInfo.TypeOneText:Hide()
			currencyFrameCharacterInfo.TypeTwoText:Hide()
			currencyFrameCharacterInfo.TypeThreeText:Hide()
			currencyFrameCharacterInfo.TypeFourText:Hide()
			currencyFrameCharacterInfo.TypeFiveText:Hide()
			currencyFrameCharacterInfo.TypeSixText:Hide()
		else
			currencyFrameCharacterInfo.characterNameText:Show()
			currencyFrameCharacterInfo.GoldText:SetTextColor( r, g, b, a )
			currencyFrameCharacterInfo.characterNameText:SetTextColor( r, g, b, a )
			currencyFrameCharacterInfo.TypeOneText:SetTextColor( r, g, b, a )
			currencyFrameCharacterInfo.TypeTwoText:SetTextColor( r, g, b, a )
			currencyFrameCharacterInfo.TypeThreeText:SetTextColor( r, g, b, a )
			currencyFrameCharacterInfo.TypeFourText:SetTextColor( r, g, b, a )
			currencyFrameCharacterInfo.TypeFiveText:SetTextColor( r, g, b, a )
			currencyFrameCharacterInfo.TypeSixText:SetTextColor( r, g, b, a )
		end
	end
	AJM.currencyTotalGold = 0
	if AJM.db.currGoldInGuildBank == true then
		if IsInGuild() then
			AJM.currencyTotalGold = GetGuildBankMoney()
		end
	end
	AJM:JambaSendCommandToTeam( AJM.COMMAND_REQUEST_CURRENCY, "" )
	AJM.SettingsRefresh()
	
end

function AJM:DoSendCurrency( characterName, dummyValue )
	--AJM:Print("Test2")
	if JambaApi.GetCharacterOnlineStatus ( characterName ) == true then
	table.wipe( AJM.currentCurrencyValues )
	AJM.currentCurrencyValues.currGold = GetMoney()
	-- CurrencyValues
	AJM.currentCurrencyValues.currTypeOne = select( 2, GetCurrencyInfo( AJM.db.CcurrTypeOne ) )
	AJM.currentCurrencyValues.currTypeTwo = select( 2, GetCurrencyInfo( AJM.db.CcurrTypeTwo ) )
	AJM.currentCurrencyValues.currTypeThree = select( 2, GetCurrencyInfo( AJM.db.CcurrTypeThree ) )	
	AJM.currentCurrencyValues.currTypeFour	= select( 2, GetCurrencyInfo( AJM.db.CcurrTypeFour ) )
	AJM.currentCurrencyValues.currTypeFive = select( 2, GetCurrencyInfo( AJM.db.CcurrTypeFive ) )
	AJM.currentCurrencyValues.currTypeSix = select( 2, GetCurrencyInfo( AJM.db.CcurrTypeSix ) )
	-- Max CurrencyValues
	AJM.currentCurrencyValues.currMaxTypeOne = select( 6, GetCurrencyInfo( AJM.db.CcurrTypeOne ) )
	AJM.currentCurrencyValues.currMaxTypeTwo = select( 6, GetCurrencyInfo( AJM.db.CcurrTypeTwo ) )
	AJM.currentCurrencyValues.currMaxTypeThree = select( 6, GetCurrencyInfo( AJM.db.CcurrTypeThree ) )	
	AJM.currentCurrencyValues.currMaxTypeFour	= select( 6, GetCurrencyInfo( AJM.db.CcurrTypeFour ) )
	AJM.currentCurrencyValues.currMaxTypeFive = select( 6, GetCurrencyInfo( AJM.db.CcurrTypeFive ) )
	AJM.currentCurrencyValues.currMaxTypeSix = select( 6, GetCurrencyInfo( AJM.db.CcurrTypeSix ) )
	AJM:JambaSendCommandToToon( characterName, AJM.COMMAND_HERE_IS_CURRENCY, AJM.currentCurrencyValues )
	else
		return
	end
end

function AJM:DoShowToonsCurrency( characterName, currencyValues )
	--AJM.Print("DoShowCurrency", characterName, currencyValues.currTypeOne, currencyValues.currMaxTypeOne )
	local parentFrame = JambaToonCurrencyListFrame
	-- Get (or create and get) the character information.
	local currencyFrameCharacterInfo = AJM.currencyFrameCharacterInfo[characterName]
		--AJM.Print("Frame", characterName)
	if currencyFrameCharacterInfo == nil then
		AJM:CreateJambaCurrencyFrameInfo( characterName, parentFrame )
		currencyFrameCharacterInfo = AJM.currencyFrameCharacterInfo[characterName]
	end
	-- Colour white.
	local r = 1.0
	local g = 1.0
	local b = 1.0
	local a = 1.0
	local v = 0
	
	currencyFrameCharacterInfo.GoldText:SetTextColor( r, g, b, a )
	currencyFrameCharacterInfo.characterNameText:SetTextColor( r, g, b, a )
	currencyFrameCharacterInfo.GoldText:SetTextColor( r, g, b, a )
	if currencyValues.currTypeOne == currencyValues.currMaxTypeOne and currencyValues.currTypeOne > 0 then 
		--AJM:Print("SetRed")
		currencyFrameCharacterInfo.TypeOneText:SetTextColor( r, v, v, a )
	else
		--AJM:Print("SetWhite")
		currencyFrameCharacterInfo.TypeOneText:SetTextColor( r, g, b, a )
	end	
	
	if currencyValues.currTypeTwo == currencyValues.currMaxTypeTwo and currencyValues.currTypeTwo > 0 then 
		currencyFrameCharacterInfo.TypeTwoText:SetTextColor( r, v, v, a )
	else
		currencyFrameCharacterInfo.TypeTwoText:SetTextColor( r, g, b, a )
	end
	if currencyValues.currTypeThree == currencyValues.currMaxTypeThree and currencyValues.currTypeThree > 0 then 
		currencyFrameCharacterInfo.TypeThreeText:SetTextColor( r, v, v, a )
	else
		currencyFrameCharacterInfo.TypeThreeText:SetTextColor( r, g, b, a )
	end
	
	if currencyValues.currTypeFour == currencyValues.currMaxTypeFour and currencyValues.currTypeFour > 0 then 
		currencyFrameCharacterInfo.TypeFourText:SetTextColor( r, v, v, a )
	else
		currencyFrameCharacterInfo.TypeFourText:SetTextColor( r, g, b, a )
	end
	
	if currencyValues.currTypeFive == currencyValues.currMaxTypeFive and currencyValues.currTypeFive > 0 then 
		currencyFrameCharacterInfo.TypeFiveText:SetTextColor( r, v, v, a )
	else
		currencyFrameCharacterInfo.TypeFiveText:SetTextColor( r, g, b, a )
	end
	
	if currencyValues.currTypeSix == currencyValues.currMaxTypeSix and currencyValues.currTypeSix > 0 then 
		currencyFrameCharacterInfo.TypeSixText:SetTextColor( r, v, v, a )
	else
		currencyFrameCharacterInfo.TypeSixText:SetTextColor( r, g, b, a )
	end
	currencyFrameCharacterInfo.GoldText:SetText( JambaUtilities:FormatMoneyString( currencyValues.currGold ) )
	--currencyFrameCharacterInfo.GoldText:SetText( GetCoinTextureString( currencyValues.currGold ) )
	currencyFrameCharacterInfo.TypeOneText:SetText( currencyValues.currTypeOne )
	currencyFrameCharacterInfo.TypeTwoText:SetText( currencyValues.currTypeTwo )
	currencyFrameCharacterInfo.TypeThreeText:SetText( currencyValues.currTypeThree )	
	currencyFrameCharacterInfo.TypeFourText:SetText( currencyValues.currTypeFour )
	currencyFrameCharacterInfo.TypeFiveText:SetText( currencyValues.currTypeFive )
	currencyFrameCharacterInfo.TypeSixText:SetText( currencyValues.currTypeSix )
	-- Total gold.
	AJM.currencyTotalGold = AJM.currencyTotalGold + currencyValues.currGold
	parentFrame.TotalGoldText:SetText( JambaUtilities:FormatMoneyString( AJM.currencyTotalGold ) )
	--parentFrame.TotalGoldText:SetText( GetCoinTextureString( AJM.currencyTotalGold ) )
	if IsInGuild() then
		parentFrame.TotalGoldGuildText:SetText( JambaUtilities:FormatMoneyString( GetGuildBankMoney() ) )
		--parentFrame.TotalGoldGuildText:SetText( GetCoinTextureString( GetGuildBankMoney() ) )
	end
	-- Update width of currency list.
	AJM:CurrencyListSetColumnWidth()
	JambaToonCurrencyListFrame:Show()
end

-- A Jamba command has been received.
function AJM:JambaOnCommandReceived( characterName, commandName, ... )
	if commandName == AJM.COMMAND_REQUEST_CURRENCY then
		AJM:DoSendCurrency( characterName, ... )
	end
	if commandName == AJM.COMMAND_HERE_IS_CURRENCY then
		AJM:DoShowToonsCurrency( characterName, ... )
	end
end
