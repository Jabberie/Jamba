--[[
Jamba - Jafula's Awesome Multi-Boxer Assistant
Copyright 2008 - 2016 Michael "Jafula" Miller
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

-- Currency Identifiers.
AJM.CDalaranJewelcraftingToken = 61
AJM.CValor = 1191
AJM.CChampionsSeal = 241
AJM.CIllustriousJewelcraftersToken = 361
AJM.CConquestPoints = 390
AJM.CTolBaradCommendation = 391
AJM.CHonorPoints = 392
AJM.CIronpawToken = 402
AJM.CLesserCharmOfGoodFortune = 738
AJM.CElderCharmOfGoodFortune = 697
AJM.CMoguRuneOfFate = 752
AJM.CWarforgedSeal = 776
AJM.CBloodyCoin = 789
AJM.CTimelessCoin = 777
--ebony New WoD Currency
AJM.CGarrisonResources = 824
AJM.CTemperedFate = 994
AJM.CApexisCrystal = 823
AJM.CDarkmoon = 515
AJM.C = 824
AJM.COil = 1101
AJM.CInevitableFate = 1129
AJM.CTimeWalker = 1166
AJM.globalCurrencyFramePrefix = "JambaToonCurrencyListFrame"

-- Settings - the values to store and their defaults for the settings database.
AJM.settings = {
	profile = {
		currGold = true,
		currGoldInGuildBank = false,
		currHonorPoints = true,
		currConquestPoints = true,
		--as there not used much now changed to false ebony
		currTolBaradCommendation = false,
		currChampionsSeal = false,
		currIllustriousJewelcraftersToken = false,
		currDalaranJewelcraftingToken = false,
		currIronpawToken = false,
		currValor = false,
		currLesserCharmOfGoodFortune = false,
		currElderCharmOfGoodFortune = false,
		currMoguRuneOfFate = false,
        currWarforgedSeal = false,
        currBloodyCoin = false,
        currTimelessCoin = false,
		--ebony New WoD Currency
		currGarrisonResources  = true,
		currTemperedFate  = false,
		currApexisCrystal  = false,
		currDarkmoon = false,
		currInevitableFate  = false,
		currOil = false,		
		currTimeWalker = false,
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
		currencyScale = 1,
		currencyNameWidth = 50,
		currencyPointsWidth = 40,
		currencyGoldWidth = 90,
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
			currency = {
				type = "input",
				name = L["Show Currency"],
				desc = L["Show the current toon the currency values for all members in the team."],
				usage = "/jamba-curr currency",
				get = false,
				set = "JambaToonRequestCurrency",
			},
			currencyhide = {
				type = "input",
				name = L["Hide Currency"],
				desc = L["Hide the currency values for all members in the team."],
				usage = "/jamba-curr currencyhide",
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
	local dropdownHeight = JambaHelperSettings:GetDropdownHeight()
	local labelHeight = JambaHelperSettings:GetLabelHeight()
	local left = JambaHelperSettings:LeftOfSettings()
	local headingHeight = JambaHelperSettings:HeadingHeight()
	local headingWidth = JambaHelperSettings:HeadingWidth( true )
	local horizontalSpacing = JambaHelperSettings:GetHorizontalSpacing()
	local verticalSpacing = JambaHelperSettings:GetVerticalSpacing()
	local halfWidth = (headingWidth - horizontalSpacing) / 2
	local thirdWidth = (headingWidth - (horizontalSpacing * 2)) / 3
	local halfWidthSlider = (headingWidth - horizontalSpacing) / 2
	local column2left = left + halfWidthSlider
	local left2 = left + thirdWidth
	local left3 = left + (thirdWidth * 2)
	local movingTop = top
	JambaHelperSettings:CreateHeading( AJM.settingsControl, L["Currency Selection"], movingTop, false )
	movingTop = movingTop - headingHeight
	AJM.settingsControl.checkBoxCurrencyGold = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		left, 
		movingTop, 
		L["Gold"],
		AJM.SettingsToggleCurrencyGold
	)	
	movingTop = movingTop - checkBoxHeight
	AJM.settingsControl.checkBoxCurrencyGoldInGuildBank = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		left, 
		movingTop, 
		L["Include Gold In Guild Bank"],
		AJM.SettingsToggleCurrencyGoldInGuildBank
	)	
	movingTop = movingTop - checkBoxHeight		
	AJM.settingsControl.checkBoxCurrencyHonorPoints = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		left, 
		movingTop, 
		L["Honor Points"]..L[" ("]..L["HP"]..L[")"],
		AJM.SettingsToggleCurrencyHonorPoints
	)	
	movingTop = movingTop - checkBoxHeight
	AJM.settingsControl.checkBoxCurrencyConquestPoints = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		left, 
		movingTop, 
		L["Conquest Points"]..L[" ("]..L["CP"]..L[")"],
		AJM.SettingsToggleCurrencyConquestPoints
	)
	movingTop = movingTop - checkBoxHeight	
	AJM.settingsControl.checkBoxCurrencyValor = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		left, 
		movingTop, 
		L["Valor Points"]..L[" ("]..L["VP"]..L[")"],
		AJM.SettingsToggleCurrencyValor
	)		
	movingTop = movingTop - checkBoxHeight
	AJM.settingsControl.checkBoxCurrencyTolBaradCommendation = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		left, 
		movingTop, 
		L["Tol Barad Commendation"]..L[" ("]..L["TBC"]..L[")"],
		AJM.SettingsToggleCurrencyTolBaradCommendation
	)	
	movingTop = movingTop - checkBoxHeight
	AJM.settingsControl.checkBoxCurrencyChampionsSeal = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		left, 
		movingTop, 
		L["Champion's Seal"]..L[" ("]..L["CS"]..L[")"],
		AJM.SettingsToggleCurrencyChampionsSeal
	)	
	movingTop = movingTop - checkBoxHeight
	AJM.settingsControl.checkBoxCurrencyIllustriousJewelcraftersToken = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		left, 
		movingTop, 
		L["Illustrious Jewelcrafter's Token"]..L[" ("]..L["IJT"]..L[")"],
		AJM.SettingsToggleCurrencyIllustriousJewelcraftersToken
	)	
	movingTop = movingTop - checkBoxHeight
	AJM.settingsControl.checkBoxCurrencyDalaranJewelcraftingToken = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		left, 
		movingTop, 
		L["Dalaran Jewelcrafting Token"]..L[" ("]..L["DJT"]..L[")"],
		AJM.SettingsToggleCurrencyDalaranJewelcraftingToken
	)	
	movingTop = movingTop - checkBoxHeight
	AJM.settingsControl.checkBoxCurrencyIronpawToken = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		left, 
		movingTop, 
		L["Ironpaw Token"]..L[" ("]..L["IT"]..L[")"],
		AJM.SettingsToggleCurrencyIronpawToken
	)	
	movingTop = movingTop - checkBoxHeight
	AJM.settingsControl.checkBoxCurrencyLesserCharmOfGoodFortune = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		left, 
		movingTop, 
		L["Lesser Charm of Good Fortune"]..L[" ("]..L["LCGF"]..L[")"],
		AJM.SettingsToggleCurrencyLesserCharmOfGoodFortune
	)	
	movingTop = movingTop - checkBoxHeight
	AJM.settingsControl.checkBoxCurrencyElderCharmOfGoodFortune = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		left, 
		movingTop, 
		L["Elder Charm of Good Fortune"]..L[" ("]..L["ECGF"]..L[")"],
		AJM.SettingsToggleCurrencyElderCharmOfGoodFortune
	)	
	movingTop = movingTop - checkBoxHeight
	AJM.settingsControl.checkBoxCurrencyMoguRuneOfFate = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		left, 
		movingTop, 
		L["Mogu Rune Of Fate"]..L[" ("]..L["MROF"]..L[")"],
		AJM.SettingsToggleCurrencyMoguRuneOfFate
	)	
	movingTop = movingTop - checkBoxHeight
    AJM.settingsControl.checkBoxCurrencyWarforgedSeal = JambaHelperSettings:CreateCheckBox(
		AJM.settingsControl,
		headingWidth,
		left,
		movingTop,
		L["Warforged Seal"]..L[" ("]..L["WS"]..L[")"],
		AJM.SettingsToggleCurrencyWarforgedSeal
	)
	movingTop = movingTop - checkBoxHeight
	AJM.settingsControl.checkBoxCurrencyBloodyCoin = JambaHelperSettings:CreateCheckBox(
		AJM.settingsControl,
		headingWidth,
		left,
		movingTop,
		L["Bloody Coin"]..L[" ("]..L["BC"]..L[")"],
		AJM.SettingsToggleCurrencyBloodyCoin
	)
	movingTop = movingTop - checkBoxHeight
	AJM.settingsControl.checkBoxCurrencyTimelessCoin = JambaHelperSettings:CreateCheckBox(
		AJM.settingsControl,
		headingWidth,
		left,
		movingTop,
		L["Timeless Coin"]..L[" ("]..L["TC"]..L[")"],
		AJM.SettingsToggleCurrencyTimelessCoin
	)
	--ebony New WoD Currency
		movingTop = movingTop - checkBoxHeight
	AJM.settingsControl.checkBoxCurrencyGarrisonResources = JambaHelperSettings:CreateCheckBox(
		AJM.settingsControl,
		headingWidth,
		left,
		movingTop,
		L["Garrison Resources"]..L[" ("]..L["GR"]..L[")"],
		AJM.SettingsToggleGarrisonResources
	)
		movingTop = movingTop - checkBoxHeight
		AJM.settingsControl.checkBoxCurrencyTemperedFate = JambaHelperSettings:CreateCheckBox(
		AJM.settingsControl,
		headingWidth,
		left,
		movingTop,
		L["Seal of Tempered Fate"]..L[" ("]..L["SoT"]..L[")"],
		AJM.SettingsToggleTemperedFate
	)
		movingTop = movingTop - checkBoxHeight	
		AJM.settingsControl.checkBoxCurrencyApexisCrystal = JambaHelperSettings:CreateCheckBox(
		AJM.settingsControl,
		headingWidth,
		left,
		movingTop,
		L["Apexis Crystal"]..L[" ("]..L["AC"]..L[")"],
		AJM.SettingsToggleCurrencyApexisCrystal
	)
		movingTop = movingTop - checkBoxHeight	
		AJM.settingsControl.checkBoxCurrencyDarkmoon = JambaHelperSettings:CreateCheckBox(
		AJM.settingsControl,
		headingWidth,
		left,
		movingTop,
		L["Darkmoon Prize Ticket"]..L[" ("]..L["DPT"]..L[")"],
		AJM.SettingsToggleCurrencyDarkmoon
	)
		movingTop = movingTop - checkBoxHeight	
		AJM.settingsControl.checkBoxCurrencyInevitableFate = JambaHelperSettings:CreateCheckBox(
		AJM.settingsControl,
		headingWidth,
		left,
		movingTop,
		L["Seal of Inevitable Fate"]..L[" ("]..L["SoI"]..L[")"],
		AJM.SettingsToggleCurrencyInevitableFate
	)
		movingTop = movingTop - checkBoxHeight	
		AJM.settingsControl.checkBoxCurrencyOil = JambaHelperSettings:CreateCheckBox(
		AJM.settingsControl,
		headingWidth,
		left,
		movingTop,
		L["OIL"]..L[" ("]..L["OIL"]..L[")"],
		AJM.SettingsToggleCurrencyOil
	)
		movingTop = movingTop - checkBoxHeight	
		AJM.settingsControl.checkBoxCurrencyTimeWalker = JambaHelperSettings:CreateCheckBox(
		AJM.settingsControl,
		headingWidth,
		left,
		movingTop,
		L["Timewarped Badge"]..L[" ("]..L["TwB"]..L[")"],
		AJM.SettingsToggleCurrencyTimeWalker
	)	
	movingTop = movingTop - checkBoxHeight
	AJM.settingsControl.currencyButtonShowList = JambaHelperSettings:CreateButton( 
		AJM.settingsControl, 
		headingWidth, 
		left, 
		movingTop, 
		L["Show Currency"], 
		AJM.JambaToonRequestCurrency
	)
	movingTop = movingTop - buttonHeight
	AJM.settingsControl.checkBoxCurrencyOpenStartUpMaster = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		left, 
		movingTop, 
		L["Open Currency List On Start Up (Master Only)"],
		AJM.SettingsToggleCurrencyOpenStartUpMaster
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
		L["Lock Currency List (enables mouse click-through)"],
		AJM.SettingsToggleCurrencyLockWindow
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
	AJM.settingsControl.checkBoxCurrencyHonorPoints:SetValue( AJM.db.currHonorPoints )
	AJM.settingsControl.checkBoxCurrencyConquestPoints:SetValue( AJM.db.currConquestPoints )
	AJM.settingsControl.checkBoxCurrencyValor:SetValue( AJM.db.currValor )	
	AJM.settingsControl.checkBoxCurrencyTolBaradCommendation:SetValue( AJM.db.currTolBaradCommendation )
	AJM.settingsControl.checkBoxCurrencyChampionsSeal:SetValue( AJM.db.currChampionsSeal )
	AJM.settingsControl.checkBoxCurrencyIllustriousJewelcraftersToken:SetValue( AJM.db.currIllustriousJewelcraftersToken )
	AJM.settingsControl.checkBoxCurrencyDalaranJewelcraftingToken:SetValue( AJM.db.currDalaranJewelcraftingToken )
	AJM.settingsControl.checkBoxCurrencyIronpawToken:SetValue( AJM.db.currIronpawToken )
	AJM.settingsControl.checkBoxCurrencyLesserCharmOfGoodFortune:SetValue( AJM.db.currLesserCharmOfGoodFortune )
	AJM.settingsControl.checkBoxCurrencyElderCharmOfGoodFortune:SetValue( AJM.db.currElderCharmOfGoodFortune )
	AJM.settingsControl.checkBoxCurrencyMoguRuneOfFate:SetValue( AJM.db.currMoguRuneOfFate )
    AJM.settingsControl.checkBoxCurrencyWarforgedSeal:SetValue( AJM.db.currWarforgedSeal )
    AJM.settingsControl.checkBoxCurrencyBloodyCoin:SetValue( AJM.db.currBloodyCoin )
    AJM.settingsControl.checkBoxCurrencyTimelessCoin:SetValue( AJM.db.currTimelessCoin )
	--ebony New WoD Currency
	AJM.settingsControl.checkBoxCurrencyGarrisonResources:SetValue( AJM.db.currGarrisonResources )
	AJM.settingsControl.checkBoxCurrencyTemperedFate:SetValue( AJM.db.currTemperedFate )
	AJM.settingsControl.checkBoxCurrencyApexisCrystal:SetValue( AJM.db.currApexisCrystal )
	AJM.settingsControl.checkBoxCurrencyDarkmoon:SetValue( AJM.db.currDarkmoon )
	AJM.settingsControl.checkBoxCurrencyInevitableFate:SetValue( AJM.db.currInevitableFate )
	AJM.settingsControl.checkBoxCurrencyOil:SetValue( AJM.db.currOil )
	AJM.settingsControl.checkBoxCurrencyTimeWalker:SetValue( AJM.db.currTimeWalker )
	--end
	AJM.settingsControl.checkBoxCurrencyOpenStartUpMaster:SetValue( AJM.db.currOpenStartUpMaster )
	AJM.settingsControl.currencyTransparencySlider:SetValue( AJM.db.currencyFrameAlpha )
	AJM.settingsControl.currencyScaleSlider:SetValue( AJM.db.currencyScale )
	AJM.settingsControl.currencyMediaBorder:SetValue( AJM.db.currencyBorderStyle )
	AJM.settingsControl.currencyMediaBackground:SetValue( AJM.db.currencyBackgroundStyle )
	AJM.settingsControl.currencyBackgroundColourPicker:SetColor( AJM.db.currencyFrameBackgroundColourR, AJM.db.currencyFrameBackgroundColourG, AJM.db.currencyFrameBackgroundColourB, AJM.db.currencyFrameBackgroundColourA )
	AJM.settingsControl.currencyBorderColourPicker:SetColor( AJM.db.currencyFrameBorderColourR, AJM.db.currencyFrameBorderColourG, AJM.db.currencyFrameBorderColourB, AJM.db.currencyFrameBorderColourA )
	AJM.settingsControl.currencySliderSpaceForName:SetValue( AJM.db.currencyNameWidth )
	AJM.settingsControl.currencySliderSpaceForGold:SetValue( AJM.db.currencyGoldWidth )
	AJM.settingsControl.currencySliderSpaceForPoints:SetValue( AJM.db.currencyPointsWidth )
	AJM.settingsControl.currencySliderSpaceBetweenValues:SetValue( AJM.db.currencySpacingWidth )
	AJM.settingsControl.checkBoxCurrencyLockWindow:SetValue( AJM.db.currencyLockWindow )
	if AJM.currencyListFrameCreated == true then
		AJM:CurrencyListSetColumnWidth()
		AJM:CurrencyListSetHeight()
		AJM:SettingsUpdateBorderStyle()
		AJM:CurrencyUpdateWindowLock()
		JambaToonCurrencyListFrame:SetScale( AJM.db.currencyScale )
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

function AJM:SettingsToggleCurrencyHonorPoints( event, checked )
	AJM.db.currHonorPoints = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleCurrencyConquestPoints( event, checked )
	AJM.db.currConquestPoints = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleCurrencyValor( event, checked )
	AJM.db.currValor = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleCurrencyTolBaradCommendation( event, checked )
	AJM.db.currTolBaradCommendation = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleCurrencyChampionsSeal( event, checked )
	AJM.db.currChampionsSeal = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleCurrencyIllustriousJewelcraftersToken( event, checked )
	AJM.db.currIllustriousJewelcraftersToken = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleCurrencyDalaranJewelcraftingToken( event, checked )
	AJM.db.currDalaranJewelcraftingToken = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleCurrencyIronpawToken( event, checked )
	AJM.db.currIronpawToken = checked
	AJM:SettingsRefresh()
end


function AJM:SettingsToggleCurrencyLesserCharmOfGoodFortune( event, checked )
	AJM.db.currLesserCharmOfGoodFortune = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleCurrencyElderCharmOfGoodFortune( event, checked )
	AJM.db.currElderCharmOfGoodFortune = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleCurrencyMoguRuneOfFate( event, checked )
	AJM.db.currMoguRuneOfFate = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleCurrencyWarforgedSeal( event, checked )
	AJM.db.currWarforgedSeal = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleCurrencyBloodyCoin( event, checked )
	AJM.db.currBloodyCoin = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleCurrencyTimelessCoin( event, checked )
	AJM.db.currTimelessCoin = checked
	AJM:SettingsRefresh()
end

--ebony New WoD Currency 
function AJM:SettingsToggleCurrencyGarrisonResources ( event, checked )
	AJM.db.currGarrisonResources = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleCurrencyTemperedFate ( event, checked )
	AJM.db.currTemperedFate = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleCurrencyApexisCrystal ( event, checked )
	AJM.db.currApexisCrystal = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleCurrencyInevitableFate ( event, checked )
	AJM.db.currInevitableFate = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleCurrencyOil ( event, checked )
	AJM.db.currOil = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleCurrencyTimeWalker ( event, checked )
	AJM.db.currTimeWalker = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleCurrencyDarkmoon ( event, checked )
	AJM.db.currDarkmoon = checked
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
--[[	if AJM.db.currOpenStartUpMaster == true then
		if JambaApi.IsCharacterTheMaster( self.characterName ) == true then
			AJM:ScheduleTimer( "JambaToonRequestCurrency", 2 )
		end
	end]]
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
		AJM.db.currHonorPoints = settings.currHonorPoints
		AJM.db.currConquestPoints = settings.currConquestPoints
		AJM.db.currValor = settings.currValor	
		AJM.db.currTolBaradCommendation = settings.currTolBaradCommendation
		AJM.db.currChampionsSeal = settings.currChampionsSeal
		AJM.db.currIllustriousJewelcraftersToken = settings.currIllustriousJewelcraftersToken
		AJM.db.currDalaranJewelcraftingToken = settings.currDalaranJewelcraftingToken
		AJM.db.currIronpawToken = settings.currIronpawToken
		AJM.db.currLesserCharmOfGoodFortune = settings.currLesserCharmOfGoodFortune
		AJM.db.currElderCharmOfGoodFortune = settings.currElderCharmOfGoodFortune
		AJM.db.currMoguRuneOfFate = settings.currMoguRuneOfFate
        AJM.db.currWarforgedSeal = settings.currWarforgedSeal
        AJM.db.currBloodyCoin = settings.currBloodyCoin
        AJM.db.currTimelessCoin = settings.currTimelessCoin
		--ebony New WoD Currency
		AJM.db.currGarrisonResources = settings.currGarrisonResources
		AJM.db.currTemperedFate = settings.currTemperedFate
		AJM.db.currApexisCrystal = settings.currApexisCrystal
		AJM.db.currDarkmoon = settings.currDarkmoon
		AJM.db.currInevitableFate = settings.currInevitableFate
		AJM.db.currOil = settings.currOil
		AJM.db.currTimeWalker = settings.currTimeWalker
--		END		
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

function AJM:CreateJambaToonCurrencyListFrame()
	-- The frame.
	local frame = CreateFrame( "Frame", "JambaToonCurrencyListWindowFrame", UIParent )
	frame.obj = AJM
	frame:SetFrameStrata( "BACKGROUND" )
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
	-- Set the HonorPoints font string.
	local frameHonorPoints = AJM.globalCurrencyFramePrefix.."TitleHonorPoints"
	local frameHonorPointsText = parentFrame:CreateFontString( frameHonorPoints.."Text", "OVERLAY", "GameFontNormal" )
	frameHonorPointsText:SetText( L["HP"] )
	frameHonorPointsText:SetTextColor( r, g, b, a )
	frameHonorPointsText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, top )
	frameHonorPointsText:SetWidth( width )
	frameHonorPointsText:SetJustifyH( "CENTER" )
	frame.HonorPointsText = frameHonorPointsText
	left = left + spacing
	-- Set the ConquestPoints font string.
	local frameConquestPoints = AJM.globalCurrencyFramePrefix.."TitleConquestPoints"
	local frameConquestPointsText = parentFrame:CreateFontString( frameConquestPoints.."Text", "OVERLAY", "GameFontNormal" )
	frameConquestPointsText:SetText( L["CP"] )
	frameConquestPointsText:SetTextColor( r, g, b, a )
	frameConquestPointsText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, top )
	frameConquestPointsText:SetWidth( width )
	frameConquestPointsText:SetJustifyH( "CENTER" )
	frame.ConquestPointsText = frameConquestPointsText
	left = left + spacing
	-- Set the Valor font string.
	local frameValor = AJM.globalCurrencyFramePrefix.."Valor"
	local frameValorText = parentFrame:CreateFontString( frameValor.."Text", "OVERLAY", "GameFontNormal" )
	frameValorText:SetText( L["VP"] )
	frameValorText:SetTextColor( r, g, b, a )
	frameValorText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, top )
	frameValorText:SetWidth( width )
	frameValorText:SetJustifyH( "CENTER" )
	frame.ValorText = frameValorText
	left = left + spacing	
	-- Set the TolBaradCommendation font string.
	local frameTolBaradCommendation = AJM.globalCurrencyFramePrefix.."TitleTolBaradCommendation"
	local frameTolBaradCommendationText = parentFrame:CreateFontString( frameTolBaradCommendation.."Text", "OVERLAY", "GameFontNormal" )
	frameTolBaradCommendationText:SetText( L["TBC"] )
	frameTolBaradCommendationText:SetTextColor( r, g, b, a )
	frameTolBaradCommendationText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, top )
	frameTolBaradCommendationText:SetWidth( width )
	frameTolBaradCommendationText:SetJustifyH( "CENTER" )
	frame.TolBaradCommendationText = frameTolBaradCommendationText
	left = left + spacing
	-- Set the ChampionsSeal font string.
	local frameChampionsSeal = AJM.globalCurrencyFramePrefix.."TitleChampionsSeal"
	local frameChampionsSealText = parentFrame:CreateFontString( frameChampionsSeal.."Text", "OVERLAY", "GameFontNormal" )
	frameChampionsSealText:SetText( L["CS"] )
	frameChampionsSealText:SetTextColor( r, g, b, a )
	frameChampionsSealText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, top )
	frameChampionsSealText:SetWidth( width )
	frameChampionsSealText:SetJustifyH( "CENTER" )
	frame.ChampionsSealText = frameChampionsSealText
	left = left + spacing
	-- Set the IllustriousJewelcraftersToken font string.
	local frameIllustriousJewelcraftersToken = AJM.globalCurrencyFramePrefix.."TitleIllustriousJewelcraftersToken"
	local frameIllustriousJewelcraftersTokenText = parentFrame:CreateFontString( frameIllustriousJewelcraftersToken.."Text", "OVERLAY", "GameFontNormal" )
	frameIllustriousJewelcraftersTokenText:SetText( L["IJT"] )
	frameIllustriousJewelcraftersTokenText:SetTextColor( r, g, b, a )
	frameIllustriousJewelcraftersTokenText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, top )
	frameIllustriousJewelcraftersTokenText:SetWidth( width )
	frameIllustriousJewelcraftersTokenText:SetJustifyH( "CENTER" )
	frame.IllustriousJewelcraftersTokenText = frameIllustriousJewelcraftersTokenText
	left = left + spacing
	-- Set the DalaranJewelcraftingToken font string.
	local frameDalaranJewelcraftingToken = AJM.globalCurrencyFramePrefix.."TitleDalaranJewelcraftingToken"
	local frameDalaranJewelcraftingTokenText = parentFrame:CreateFontString( frameDalaranJewelcraftingToken.."Text", "OVERLAY", "GameFontNormal" )
	frameDalaranJewelcraftingTokenText:SetText( L["DJT"] )
	frameDalaranJewelcraftingTokenText:SetTextColor( r, g, b, a )
	frameDalaranJewelcraftingTokenText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, top )
	frameDalaranJewelcraftingTokenText:SetWidth( width )
	frameDalaranJewelcraftingTokenText:SetJustifyH( "CENTER" )
	frame.DalaranJewelcraftingTokenText = frameDalaranJewelcraftingTokenText
	left = left + spacing
	-- Set the IronpawToken font string.
	local frameIronpawToken = AJM.globalCurrencyFramePrefix.."TitleIronpawToken"
	local frameIronpawTokenText = parentFrame:CreateFontString( frameIronpawToken.."Text", "OVERLAY", "GameFontNormal" )
	frameIronpawTokenText:SetText( L["IT"] )
	frameIronpawTokenText:SetTextColor( r, g, b, a )
	frameIronpawTokenText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, top )
	frameIronpawTokenText:SetWidth( width )
	frameIronpawTokenText:SetJustifyH( "CENTER" )
	frame.IronpawTokenText = frameIronpawTokenText
	left = left + spacing
	-- Set the LesserCharmOfGoodFortune font string.
	local frameLesserCharmOfGoodFortune = AJM.globalCurrencyFramePrefix.."TitleLesserCharmOfGoodFortune"
	local frameLesserCharmOfGoodFortuneText = parentFrame:CreateFontString( frameLesserCharmOfGoodFortune.."Text", "OVERLAY", "GameFontNormal" )
	frameLesserCharmOfGoodFortuneText:SetText( L["LCGF"] )
	frameLesserCharmOfGoodFortuneText:SetTextColor( r, g, b, a )
	frameLesserCharmOfGoodFortuneText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, top )
	frameLesserCharmOfGoodFortuneText:SetWidth( width )
	frameLesserCharmOfGoodFortuneText:SetJustifyH( "CENTER" )
	frame.LesserCharmOfGoodFortuneText = frameLesserCharmOfGoodFortuneText
	left = left + spacing
	-- Set the ElderCharmOfGoodFortune font string.
	local frameElderCharmOfGoodFortune = AJM.globalCurrencyFramePrefix.."TitleElderCharmOfGoodFortune"
	local frameElderCharmOfGoodFortuneText = parentFrame:CreateFontString( frameElderCharmOfGoodFortune.."Text", "OVERLAY", "GameFontNormal" )
	frameElderCharmOfGoodFortuneText:SetText( L["ECGF"] )
	frameElderCharmOfGoodFortuneText:SetTextColor( r, g, b, a )
	frameElderCharmOfGoodFortuneText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, top )
	frameElderCharmOfGoodFortuneText:SetWidth( width )
	frameElderCharmOfGoodFortuneText:SetJustifyH( "CENTER" )
	frame.ElderCharmOfGoodFortuneText = frameElderCharmOfGoodFortuneText
	left = left + spacing
	-- Set the MoguRuneOfFate font string.
	local frameMoguRuneOfFate = AJM.globalCurrencyFramePrefix.."TitleMoguRuneOfFate"
	local frameMoguRuneOfFateText = parentFrame:CreateFontString( frameMoguRuneOfFate.."Text", "OVERLAY", "GameFontNormal" )
	frameMoguRuneOfFateText:SetText( L["MROF"] )
	frameMoguRuneOfFateText:SetTextColor( r, g, b, a )
	frameMoguRuneOfFateText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, top )
	frameMoguRuneOfFateText:SetWidth( width )
	frameMoguRuneOfFateText:SetJustifyH( "CENTER" )
	frame.MoguRuneOfFateText = frameMoguRuneOfFateText
	left = left + spacing
    -- Set the WarforgedSeal font string.
	local frameWarforgedSeal = AJM.globalCurrencyFramePrefix.."TitleWarforgedSeal"
	local frameWarforgedSealText = parentFrame:CreateFontString( frameWarforgedSeal.."Text", "OVERLAY", "GameFontNormal" )
	frameWarforgedSealText:SetText( L["WS"] )
	frameWarforgedSealText:SetTextColor( r, g, b, a )
	frameWarforgedSealText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, top )
	frameWarforgedSealText:SetWidth( width )
	frameWarforgedSealText:SetJustifyH( "CENTER" )
	frame.WarforgedSealText = frameWarforgedSealText
	left = left + spacing
    -- Set the BloodyCoin font string.
	local frameBloodyCoin = AJM.globalCurrencyFramePrefix.."TitleBloodyCoin"
	local frameBloodyCoinText = parentFrame:CreateFontString( frameBloodyCoin.."Text", "OVERLAY", "GameFontNormal" )
	frameBloodyCoinText:SetText( L["BC"] )
	frameBloodyCoinText:SetTextColor( r, g, b, a )
	frameBloodyCoinText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, top )
	frameBloodyCoinText:SetWidth( width )
	frameBloodyCoinText:SetJustifyH( "CENTER" )
	frame.BloodyCoinText = frameBloodyCoinText
	left = left + spacing
	-- Set the TimelessCoin font string.
	local frameTimelessCoin = AJM.globalCurrencyFramePrefix.."TitleTimelessCoin"
	local frameTimelessCoinText = parentFrame:CreateFontString( frameTimelessCoin.."Text", "OVERLAY", "GameFontNormal" )
	frameTimelessCoinText:SetText( L["TC"] )
	frameTimelessCoinText:SetTextColor( r, g, b, a )
	frameTimelessCoinText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, top )
	frameTimelessCoinText:SetWidth( width )
	frameTimelessCoinText:SetJustifyH( "CENTER" )
	frame.TimelessCoinText = frameTimelessCoinText
	left = left + spacing
	--ebony New WoD Currency
	-- Set the GarrisonResources font string.
	local frameGarrisonResources = AJM.globalCurrencyFramePrefix.."TitleGarrisonResources"
	local frameGarrisonResourcesText = parentFrame:CreateFontString( frameGarrisonResources .."Text", "OVERLAY", "GameFontNormal" )
	frameGarrisonResourcesText:SetText( L["GR"] )
	frameGarrisonResourcesText:SetTextColor( r, g, b, a )
	frameGarrisonResourcesText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, top )
	frameGarrisonResourcesText:SetWidth( width )
	frameGarrisonResourcesText:SetJustifyH( "CENTER" )
	frame.GarrisonResourcesText = frameGarrisonResourcesText
	left = left + spacing
		-- Set the Tempered Fate font string.
	local frameTemperedFate = AJM.globalCurrencyFramePrefix.."TitleTemperedFate"
	local frameTemperedFateText = parentFrame:CreateFontString( frameTemperedFate .."Text", "OVERLAY", "GameFontNormal" )
	frameTemperedFateText:SetText( L["SoT"] )
	frameTemperedFateText:SetTextColor( r, g, b, a )
	frameTemperedFateText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, top )
	frameTemperedFateText:SetWidth( width )
	frameTemperedFateText:SetJustifyH( "CENTER" )
	frame.TemperedFateText = frameTemperedFateText
	left = left + spacing
		-- Set the Apexis Crystal font string.
	local frameApexisCrystal = AJM.globalCurrencyFramePrefix.."TitleApexisCrystal"
	local frameApexisCrystalText = parentFrame:CreateFontString( frameApexisCrystal .."Text", "OVERLAY", "GameFontNormal" )
	frameApexisCrystalText:SetText( L["AC"] )
	frameApexisCrystalText:SetTextColor( r, g, b, a )
	frameApexisCrystalText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, top )
	frameApexisCrystalText:SetWidth( width )
	frameApexisCrystalText:SetJustifyH( "CENTER" )
	frame.ApexisCrystalText = frameApexisCrystalText
	left = left + spacing
	-- Set the Darkmoon Prize font string.
	local frameDarkmoon = AJM.globalCurrencyFramePrefix.."TitleDarkmoon"
	local frameDarkmoonText = parentFrame:CreateFontString( frameDarkmoon .."Text", "OVERLAY", "GameFontNormal" )
	frameDarkmoonText:SetText( L["DPT"] )
	frameDarkmoonText:SetTextColor( r, g, b, a )
	frameDarkmoonText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, top )
	frameDarkmoonText:SetWidth( width )
	frameDarkmoonText:SetJustifyH( "CENTER" )
	frame.DarkmoonText = frameDarkmoonText
	left = left + spacing
	-- Set the Oil font string.
	local frameOil = AJM.globalCurrencyFramePrefix.."TitleOil"
	local frameOilText = parentFrame:CreateFontString( frameOil .."Text", "OVERLAY", "GameFontNormal" )
	frameOilText:SetText( L["OIL"] )
	frameOilText:SetTextColor( r, g, b, a )
	frameOilText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, top )
	frameOilText:SetWidth( width )
	frameOilText:SetJustifyH( "CENTER" )
	frame.OilText = frameOilText
	left = left + spacing
	-- Set the InevitableFate Prize font string.
	local frameInevitableFate = AJM.globalCurrencyFramePrefix.."TitleInevitableFate"
	local frameInevitableFateText = parentFrame:CreateFontString( frameInevitableFate .."Text", "OVERLAY", "GameFontNormal" )
	frameInevitableFateText:SetText( L["SoI"] )
	frameInevitableFateText:SetTextColor( r, g, b, a )
	frameInevitableFateText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, top )
	frameInevitableFateText:SetWidth( width )
	frameInevitableFateText:SetJustifyH( "CENTER" )
	frame.InevitableFateText = frameInevitableFateText
	left = left + spacing
	-- Set the Time Walker font string.
	local frameTimeWalker = AJM.globalCurrencyFramePrefix.."TitleTimewalker"
	local frameTimeWalkerText = parentFrame:CreateFontString( frameTimeWalker .."Text", "OVERLAY", "GameFontNormal" )
	frameTimeWalkerText:SetText( L["SoI"] )
	frameTimeWalkerText:SetTextColor( r, g, b, a )
	frameTimeWalkerText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, top )
	frameTimeWalkerText:SetWidth( width )
	frameTimeWalkerText:SetJustifyH( "CENTER" )
	frame.TimeWalkerText = frameTimeWalkerText
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
	
	AJM:CurrencyListSetHeight()
	AJM:SettingsUpdateBorderStyle()
	AJM:CurrencyUpdateWindowLock()
	JambaToonCurrencyListFrame:Hide()
	AJM.currencyListFrameCreated = true
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
	frame:SetAlpha( AJM.db.currencyFrameAlpha )
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
	if AJM.db.currHonorPoints == true then
		parentFrame.HonorPointsText:SetWidth( pointsWidth )
		parentFrame.HonorPointsText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, headingRowTopPoint )
		left = left + pointsWidth + spacingWidth
		numberOfPointsColumns = numberOfPointsColumns + 1
		parentFrame.HonorPointsText:Show()
	else
		parentFrame.HonorPointsText:Hide()
	end
	if AJM.db.currConquestPoints == true then
		parentFrame.ConquestPointsText:SetWidth( pointsWidth )
		parentFrame.ConquestPointsText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, headingRowTopPoint )
		left = left + pointsWidth + spacingWidth
		numberOfPointsColumns = numberOfPointsColumns + 1
		parentFrame.ConquestPointsText:Show()
	else
		parentFrame.ConquestPointsText:Hide()
	end
	if AJM.db.currValor == true then
		parentFrame.ValorText:SetWidth( pointsWidth )
		parentFrame.ValorText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, headingRowTopPoint )
		left = left + pointsWidth + spacingWidth
		numberOfPointsColumns = numberOfPointsColumns + 1
		parentFrame.ValorText:Show()
	else
		parentFrame.ValorText:Hide()
	end	
	if AJM.db.currTolBaradCommendation == true then
		parentFrame.TolBaradCommendationText:SetWidth( pointsWidth )
		parentFrame.TolBaradCommendationText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, headingRowTopPoint )
		left = left + pointsWidth + spacingWidth
		numberOfPointsColumns = numberOfPointsColumns + 1
		parentFrame.TolBaradCommendationText:Show()
	else
		parentFrame.TolBaradCommendationText:Hide()
	end
	if AJM.db.currChampionsSeal == true then
		parentFrame.ChampionsSealText:SetWidth( pointsWidth )
		parentFrame.ChampionsSealText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, headingRowTopPoint )
		left = left + pointsWidth + spacingWidth
		numberOfPointsColumns = numberOfPointsColumns + 1
		parentFrame.ChampionsSealText:Show()
	else
		parentFrame.ChampionsSealText:Hide()
	end
	if AJM.db.currIllustriousJewelcraftersToken == true then
		parentFrame.IllustriousJewelcraftersTokenText:SetWidth( pointsWidth )
		parentFrame.IllustriousJewelcraftersTokenText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, headingRowTopPoint )
		left = left + pointsWidth + spacingWidth
		numberOfPointsColumns = numberOfPointsColumns + 1
		parentFrame.IllustriousJewelcraftersTokenText:Show()
	else
		parentFrame.IllustriousJewelcraftersTokenText:Hide()
	end
	if AJM.db.currDalaranJewelcraftingToken == true then
		parentFrame.DalaranJewelcraftingTokenText:SetWidth( pointsWidth )
		parentFrame.DalaranJewelcraftingTokenText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, headingRowTopPoint )
		left = left + pointsWidth + spacingWidth
		numberOfPointsColumns = numberOfPointsColumns + 1
		parentFrame.DalaranJewelcraftingTokenText:Show()
	else
		parentFrame.DalaranJewelcraftingTokenText:Hide()
	end
	if AJM.db.currIronpawToken == true then
		parentFrame.IronpawTokenText:SetWidth( pointsWidth )
		parentFrame.IronpawTokenText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, headingRowTopPoint )
		left = left + pointsWidth + spacingWidth
		numberOfPointsColumns = numberOfPointsColumns + 1
		parentFrame.IronpawTokenText:Show()
	else
		parentFrame.IronpawTokenText:Hide()
	end
	if AJM.db.currLesserCharmOfGoodFortune == true then
		parentFrame.LesserCharmOfGoodFortuneText:SetWidth( pointsWidth )
		parentFrame.LesserCharmOfGoodFortuneText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, headingRowTopPoint )
		left = left + pointsWidth + spacingWidth
		numberOfPointsColumns = numberOfPointsColumns + 1
		parentFrame.LesserCharmOfGoodFortuneText:Show()
	else
		parentFrame.LesserCharmOfGoodFortuneText:Hide()
	end
	if AJM.db.currElderCharmOfGoodFortune == true then
		parentFrame.ElderCharmOfGoodFortuneText:SetWidth( pointsWidth )
		parentFrame.ElderCharmOfGoodFortuneText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, headingRowTopPoint )
		left = left + pointsWidth + spacingWidth
		numberOfPointsColumns = numberOfPointsColumns + 1
		parentFrame.ElderCharmOfGoodFortuneText:Show()
	else
		parentFrame.ElderCharmOfGoodFortuneText:Hide()
	end
	if AJM.db.currMoguRuneOfFate == true then
		parentFrame.MoguRuneOfFateText:SetWidth( pointsWidth )
		parentFrame.MoguRuneOfFateText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, headingRowTopPoint )
		left = left + pointsWidth + spacingWidth
		numberOfPointsColumns = numberOfPointsColumns + 1
		parentFrame.MoguRuneOfFateText:Show()
	else
		parentFrame.MoguRuneOfFateText:Hide()
    end
    if AJM.db.currWarforgedSeal == true then
		parentFrame.WarforgedSealText:SetWidth( pointsWidth )
		parentFrame.WarforgedSealText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, headingRowTopPoint )
		left = left + pointsWidth + spacingWidth
		numberOfPointsColumns = numberOfPointsColumns + 1
		parentFrame.WarforgedSealText:Show()
	else
		parentFrame.WarforgedSealText:Hide()
    end
	if AJM.db.currBloodyCoin == true then
		parentFrame.BloodyCoinText:SetWidth( pointsWidth )
		parentFrame.BloodyCoinText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, headingRowTopPoint )
		left = left + pointsWidth + spacingWidth
		numberOfPointsColumns = numberOfPointsColumns + 1
		parentFrame.BloodyCoinText:Show()
	else
		parentFrame.BloodyCoinText:Hide()
    end
	if AJM.db.currTimelessCoin == true then
		parentFrame.TimelessCoinText:SetWidth( pointsWidth )
		parentFrame.TimelessCoinText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, headingRowTopPoint )
		left = left + pointsWidth + spacingWidth
		numberOfPointsColumns = numberOfPointsColumns + 1
		parentFrame.TimelessCoinText:Show()
	else
		parentFrame.TimelessCoinText:Hide()
	end
	--ebony New WoD Currency
	if AJM.db.currGarrisonResources == true then
		parentFrame.GarrisonResourcesText:SetWidth( pointsWidth )
		parentFrame.GarrisonResourcesText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, headingRowTopPoint )
		left = left + pointsWidth + spacingWidth
		numberOfPointsColumns = numberOfPointsColumns + 1
		parentFrame.GarrisonResourcesText:Show()
	else
		parentFrame.GarrisonResourcesText:Hide()
	end
		if AJM.db.currTemperedFate == true then
		parentFrame.TemperedFateText:SetWidth( pointsWidth )
		parentFrame.TemperedFateText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, headingRowTopPoint )
		left = left + pointsWidth + spacingWidth
		numberOfPointsColumns = numberOfPointsColumns + 1
		parentFrame.TemperedFateText:Show()
	else
		parentFrame.TemperedFateText:Hide()
	end
		if AJM.db.currApexisCrystal == true then
		parentFrame.ApexisCrystalText:SetWidth( pointsWidth )
		parentFrame.ApexisCrystalText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, headingRowTopPoint )
		left = left + pointsWidth + spacingWidth
		numberOfPointsColumns = numberOfPointsColumns + 1
		parentFrame.ApexisCrystalText:Show()
	else
		parentFrame.ApexisCrystalText:Hide()
	end
		if AJM.db.currDarkmoon == true then
		parentFrame.DarkmoonText:SetWidth( pointsWidth )
		parentFrame.DarkmoonText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, headingRowTopPoint )
		left = left + pointsWidth + spacingWidth
		numberOfPointsColumns = numberOfPointsColumns + 1
		parentFrame.DarkmoonText:Show()
	else
		parentFrame.DarkmoonText:Hide()
	end
		if AJM.db.currInevitableFate == true then
		parentFrame.InevitableFateText:SetWidth( pointsWidth )
		parentFrame.InevitableFateText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, headingRowTopPoint )
		left = left + pointsWidth + spacingWidth
		numberOfPointsColumns = numberOfPointsColumns + 1
		parentFrame.InevitableFateText:Show()
	else
		parentFrame.InevitableFateText:Hide()
	end
		if AJM.db.currOil == true then
		parentFrame.OilText:SetWidth( pointsWidth )
		parentFrame.OilText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, headingRowTopPoint )
		left = left + pointsWidth + spacingWidth
		numberOfPointsColumns = numberOfPointsColumns + 1
		parentFrame.OilText:Show()
	else
		parentFrame.OilText:Hide()
	end	
		if AJM.db.currTimeWalker == true then
		parentFrame.TimeWalkerText:SetWidth( pointsWidth )
		parentFrame.TimeWalkerText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, headingRowTopPoint )
		left = left + pointsWidth + spacingWidth
		numberOfPointsColumns = numberOfPointsColumns + 1
		parentFrame.TimeWalkerText:Show()
	else
		parentFrame.TimeWalkerText:Hide()
	end		
	
	-- Character rows.
	for characterName, currencyFrameCharacterInfo in pairs( AJM.currencyFrameCharacterInfo ) do
		--if JambaPrivate.Team.GetCharacterOnlineStatus (characterName) == false then
		--AJM.Print("offline", characterName)
		--	currencyFrameCharacterInfo.characterNameText:hide()
		--end
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
		if AJM.db.currHonorPoints == true then
			currencyFrameCharacterInfo.HonorPointsText:SetWidth( pointsWidth )
			currencyFrameCharacterInfo.HonorPointsText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, characterRowTopPoint )
			left = left + pointsWidth + spacingWidth
			currencyFrameCharacterInfo.HonorPointsText:Show()
		else
			currencyFrameCharacterInfo.HonorPointsText:Hide()
		end
		if AJM.db.currConquestPoints == true then
			currencyFrameCharacterInfo.ConquestPointsText:SetWidth( pointsWidth )
			currencyFrameCharacterInfo.ConquestPointsText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, characterRowTopPoint )
			left = left + pointsWidth + spacingWidth
			currencyFrameCharacterInfo.ConquestPointsText:Show()
		else
			currencyFrameCharacterInfo.ConquestPointsText:Hide()
		end
		if AJM.db.currValor == true then
			currencyFrameCharacterInfo.ValorText:SetWidth( pointsWidth )
			currencyFrameCharacterInfo.ValorText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, characterRowTopPoint )
			left = left + pointsWidth + spacingWidth
			currencyFrameCharacterInfo.ValorText:Show()
		else
			currencyFrameCharacterInfo.ValorText:Hide()
		end		
		if AJM.db.currTolBaradCommendation == true then
			currencyFrameCharacterInfo.TolBaradCommendationText:SetWidth( pointsWidth )
			currencyFrameCharacterInfo.TolBaradCommendationText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, characterRowTopPoint )
			left = left + pointsWidth + spacingWidth
			currencyFrameCharacterInfo.TolBaradCommendationText:Show()
		else
			currencyFrameCharacterInfo.TolBaradCommendationText:Hide()
		end
		if AJM.db.currChampionsSeal == true then
			currencyFrameCharacterInfo.ChampionsSealText:SetWidth( pointsWidth )
			currencyFrameCharacterInfo.ChampionsSealText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, characterRowTopPoint )
			left = left + pointsWidth + spacingWidth
			currencyFrameCharacterInfo.ChampionsSealText:Show()
		else
			currencyFrameCharacterInfo.ChampionsSealText:Hide()
		end
		if AJM.db.currIllustriousJewelcraftersToken == true then
			currencyFrameCharacterInfo.IllustriousJewelcraftersTokenText:SetWidth( pointsWidth )
			currencyFrameCharacterInfo.IllustriousJewelcraftersTokenText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, characterRowTopPoint )
			left = left + pointsWidth + spacingWidth
			currencyFrameCharacterInfo.IllustriousJewelcraftersTokenText:Show()
		else
			currencyFrameCharacterInfo.IllustriousJewelcraftersTokenText:Hide()
		end
		if AJM.db.currDalaranJewelcraftingToken == true then
			currencyFrameCharacterInfo.DalaranJewelcraftingTokenText:SetWidth( pointsWidth )
			currencyFrameCharacterInfo.DalaranJewelcraftingTokenText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, characterRowTopPoint )
			left = left + pointsWidth + spacingWidth
			currencyFrameCharacterInfo.DalaranJewelcraftingTokenText:Show()
		else
			currencyFrameCharacterInfo.DalaranJewelcraftingTokenText:Hide()
		end
		if AJM.db.currIronpawToken == true then
			currencyFrameCharacterInfo.IronpawTokenText:SetWidth( pointsWidth )
			currencyFrameCharacterInfo.IronpawTokenText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, characterRowTopPoint )
			left = left + pointsWidth + spacingWidth
			currencyFrameCharacterInfo.IronpawTokenText:Show()
		else
			currencyFrameCharacterInfo.IronpawTokenText:Hide()
		end
		if AJM.db.currLesserCharmOfGoodFortune == true then
			currencyFrameCharacterInfo.LesserCharmOfGoodFortuneText:SetWidth( pointsWidth )
			currencyFrameCharacterInfo.LesserCharmOfGoodFortuneText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, characterRowTopPoint )
			left = left + pointsWidth + spacingWidth
			currencyFrameCharacterInfo.LesserCharmOfGoodFortuneText:Show()
		else
			currencyFrameCharacterInfo.LesserCharmOfGoodFortuneText:Hide()
		end
		if AJM.db.currElderCharmOfGoodFortune == true then
			currencyFrameCharacterInfo.ElderCharmOfGoodFortuneText:SetWidth( pointsWidth )
			currencyFrameCharacterInfo.ElderCharmOfGoodFortuneText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, characterRowTopPoint )
			left = left + pointsWidth + spacingWidth
			currencyFrameCharacterInfo.ElderCharmOfGoodFortuneText:Show()
		else
			currencyFrameCharacterInfo.ElderCharmOfGoodFortuneText:Hide()
		end
		if AJM.db.currMoguRuneOfFate == true then
			currencyFrameCharacterInfo.MoguRuneOfFateText:SetWidth( pointsWidth )
			currencyFrameCharacterInfo.MoguRuneOfFateText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, characterRowTopPoint )
			left = left + pointsWidth + spacingWidth
			currencyFrameCharacterInfo.MoguRuneOfFateText:Show()
		else
			currencyFrameCharacterInfo.MoguRuneOfFateText:Hide()
        end
		if AJM.db.currWarforgedSeal == true then
			currencyFrameCharacterInfo.WarforgedSealText:SetWidth( pointsWidth )
			currencyFrameCharacterInfo.WarforgedSealText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, characterRowTopPoint )
			left = left + pointsWidth + spacingWidth
			currencyFrameCharacterInfo.WarforgedSealText:Show()
		else
			currencyFrameCharacterInfo.WarforgedSealText:Hide()
        end
		if AJM.db.currBloodyCoin == true then
			currencyFrameCharacterInfo.BloodyCoinText:SetWidth( pointsWidth )
			currencyFrameCharacterInfo.BloodyCoinText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, characterRowTopPoint )
			left = left + pointsWidth + spacingWidth
			currencyFrameCharacterInfo.BloodyCoinText:Show()
		else
			currencyFrameCharacterInfo.BloodyCoinText:Hide()
        end
		if AJM.db.currTimelessCoin == true then
			currencyFrameCharacterInfo.TimelessCoinText:SetWidth( pointsWidth )
			currencyFrameCharacterInfo.TimelessCoinText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, characterRowTopPoint )
			left = left + pointsWidth + spacingWidth
			currencyFrameCharacterInfo.TimelessCoinText:Show()
		else
			currencyFrameCharacterInfo.TimelessCoinText:Hide()
		end
--ebony New WoD Currency
		if AJM.db.currGarrisonResources == true then
			currencyFrameCharacterInfo.GarrisonResourcesText:SetWidth( pointsWidth )
			currencyFrameCharacterInfo.GarrisonResourcesText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, characterRowTopPoint )
			left = left + pointsWidth + spacingWidth
			currencyFrameCharacterInfo.GarrisonResourcesText:Show()
		else
			currencyFrameCharacterInfo.GarrisonResourcesText:Hide()
		end
		if AJM.db.currTemperedFate == true then
			currencyFrameCharacterInfo.TemperedFateText:SetWidth( pointsWidth )
			currencyFrameCharacterInfo.TemperedFateText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, characterRowTopPoint )
			left = left + pointsWidth + spacingWidth
			currencyFrameCharacterInfo.TemperedFateText:Show()
		else
			currencyFrameCharacterInfo.TemperedFateText:Hide()
		end
		if AJM.db.currApexisCrystal == true then
			currencyFrameCharacterInfo.ApexisCrystalText:SetWidth( pointsWidth )
			currencyFrameCharacterInfo.ApexisCrystalText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, characterRowTopPoint )
			left = left + pointsWidth + spacingWidth
			currencyFrameCharacterInfo.ApexisCrystalText:Show()
		else
			currencyFrameCharacterInfo.ApexisCrystalText:Hide()
		end	
		if AJM.db.currDarkmoon == true then
			currencyFrameCharacterInfo.DarkmoonText:SetWidth( pointsWidth )
			currencyFrameCharacterInfo.DarkmoonText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, characterRowTopPoint )
			left = left + pointsWidth + spacingWidth
			currencyFrameCharacterInfo.DarkmoonText:Show()
		else
			currencyFrameCharacterInfo.DarkmoonText:Hide()
		end
		if AJM.db.currInevitableFate == true then
			currencyFrameCharacterInfo.InevitableFateText:SetWidth( pointsWidth )
			currencyFrameCharacterInfo.InevitableFateText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, characterRowTopPoint )
			left = left + pointsWidth + spacingWidth
			currencyFrameCharacterInfo.InevitableFateText:Show()
		else
			currencyFrameCharacterInfo.InevitableFateText:Hide()
		end
		if AJM.db.currOil == true then
			currencyFrameCharacterInfo.OilText:SetWidth( pointsWidth )
			currencyFrameCharacterInfo.OilText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, characterRowTopPoint )
			left = left + pointsWidth + spacingWidth
			currencyFrameCharacterInfo.OilText:Show()
		else
			currencyFrameCharacterInfo.OilText:Hide()
		end
		if AJM.db.currTimeWalker == true then
			currencyFrameCharacterInfo.TimeWalkerText:SetWidth( pointsWidth )
			currencyFrameCharacterInfo.TimeWalkerText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, characterRowTopPoint )
			left = left + pointsWidth + spacingWidth
			currencyFrameCharacterInfo.TimeWalkerText:Show()
		else
			currencyFrameCharacterInfo.TimeWalkerText:Hide()
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
	local left = 10
	local spacing = 50
	local width = 50
	--local top = -35 + (-15 * JambaApi.GetPositionForCharacterName( characterName ))
	local top = -35 + (-15 * JambaApi.GetPositionForCharacterNameOnline( characterName) )
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
	-- Set the HonorPoints font string.
	local frameHonorPoints = AJM.globalCurrencyFramePrefix.."HonorPoints"
	local frameHonorPointsText = parentFrame:CreateFontString( frameHonorPoints.."Text", "OVERLAY", "GameFontNormal" )
	frameHonorPointsText:SetText( "0" )
	frameHonorPointsText:SetTextColor( 1.00, 1.00, 1.00, 1.00 )
	frameHonorPointsText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, top )
	frameHonorPointsText:SetWidth( width )
	frameHonorPointsText:SetJustifyH( "CENTER" )
	currencyFrameCharacterInfo.HonorPointsText = frameHonorPointsText
	left = left + spacing
	-- Set the ConquestPoints font string.
	local frameConquestPoints = AJM.globalCurrencyFramePrefix.."ConquestPoints"
	local frameConquestPointsText = parentFrame:CreateFontString( frameConquestPoints.."Text", "OVERLAY", "GameFontNormal" )
	frameConquestPointsText:SetText( "0" )
	frameConquestPointsText:SetTextColor( 1.00, 1.00, 1.00, 1.00 )
	frameConquestPointsText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, top )
	frameConquestPointsText:SetWidth( width )
	frameConquestPointsText:SetJustifyH( "CENTER" )
	currencyFrameCharacterInfo.ConquestPointsText = frameConquestPointsText
	left = left + spacing
		-- Set the Valor font string.
	local frameValor = AJM.globalCurrencyFramePrefix.."Valor"
	local frameValorText = parentFrame:CreateFontString( frameValor.."Text", "OVERLAY", "GameFontNormal" )
	frameValorText:SetText( "0" )
	frameValorText:SetTextColor( 1.00, 1.00, 1.00, 1.00 )
	frameValorText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, top )
	frameValorText:SetWidth( width )
	frameValorText:SetJustifyH( "CENTER" )
	currencyFrameCharacterInfo.ValorText = frameValorText
	left = left + spacing
	-- Set the TolBaradCommendation font string.
	local frameTolBaradCommendation = AJM.globalCurrencyFramePrefix.."TolBaradCommendation"
	local frameTolBaradCommendationText = parentFrame:CreateFontString( frameTolBaradCommendation.."Text", "OVERLAY", "GameFontNormal" )
	frameTolBaradCommendationText:SetText( "0" )
	frameTolBaradCommendationText:SetTextColor( 1.00, 1.00, 1.00, 1.00 )
	frameTolBaradCommendationText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, top )
	frameTolBaradCommendationText:SetWidth( width )
	frameTolBaradCommendationText:SetJustifyH( "CENTER" )
	currencyFrameCharacterInfo.TolBaradCommendationText = frameTolBaradCommendationText
	left = left + spacing
	-- Set the ChampionsSeal font string.
	local frameChampionsSeal = AJM.globalCurrencyFramePrefix.."ChampionsSeal"
	local frameChampionsSealText = parentFrame:CreateFontString( frameChampionsSeal.."Text", "OVERLAY", "GameFontNormal" )
	frameChampionsSealText:SetText( "0" )
	frameChampionsSealText:SetTextColor( 1.00, 1.00, 1.00, 1.00 )
	frameChampionsSealText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, top )
	frameChampionsSealText:SetWidth( width )
	frameChampionsSealText:SetJustifyH( "CENTER" )
	currencyFrameCharacterInfo.ChampionsSealText = frameChampionsSealText
	left = left + spacing
	-- Set the IllustriousJewelcraftersToken font string.
	local frameIllustriousJewelcraftersToken = AJM.globalCurrencyFramePrefix.."IllustriousJewelcraftersToken"
	local frameIllustriousJewelcraftersTokenText = parentFrame:CreateFontString( frameIllustriousJewelcraftersToken.."Text", "OVERLAY", "GameFontNormal" )
	frameIllustriousJewelcraftersTokenText:SetText( "0" )
	frameIllustriousJewelcraftersTokenText:SetTextColor( 1.00, 1.00, 1.00, 1.00 )
	frameIllustriousJewelcraftersTokenText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, top )
	frameIllustriousJewelcraftersTokenText:SetWidth( width )
	frameIllustriousJewelcraftersTokenText:SetJustifyH( "CENTER" )
	currencyFrameCharacterInfo.IllustriousJewelcraftersTokenText = frameIllustriousJewelcraftersTokenText
	left = left + spacing
	-- Set the DalaranJewelcraftingToken font string.
	local frameDalaranJewelcraftingToken = AJM.globalCurrencyFramePrefix.."DalaranJewelcraftingToken"
	local frameDalaranJewelcraftingTokenText = parentFrame:CreateFontString( frameDalaranJewelcraftingToken.."Text", "OVERLAY", "GameFontNormal" )
	frameDalaranJewelcraftingTokenText:SetText( "0" )
	frameDalaranJewelcraftingTokenText:SetTextColor( 1.00, 1.00, 1.00, 1.00 )
	frameDalaranJewelcraftingTokenText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, top )
	frameDalaranJewelcraftingTokenText:SetWidth( width )
	frameDalaranJewelcraftingTokenText:SetJustifyH( "CENTER" )
	currencyFrameCharacterInfo.DalaranJewelcraftingTokenText = frameDalaranJewelcraftingTokenText
	left = left + spacing
	-- Set the IronpawToken font string.
	local frameIronpawToken = AJM.globalCurrencyFramePrefix.."IronpawToken"
	local frameIronpawTokenText = parentFrame:CreateFontString( frameIronpawToken.."Text", "OVERLAY", "GameFontNormal" )
	frameIronpawTokenText:SetText( "0" )
	frameIronpawTokenText:SetTextColor( 1.00, 1.00, 1.00, 1.00 )
	frameIronpawTokenText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, top )
	frameIronpawTokenText:SetWidth( width )
	frameIronpawTokenText:SetJustifyH( "CENTER" )
	currencyFrameCharacterInfo.IronpawTokenText = frameIronpawTokenText
	left = left + spacing
	-- Set the LesserCharmOfGoodFortune font string.
	local frameLesserCharmOfGoodFortune = AJM.globalCurrencyFramePrefix.."LesserCharmOfGoodFortune"
	local frameLesserCharmOfGoodFortuneText = parentFrame:CreateFontString( frameLesserCharmOfGoodFortune.."Text", "OVERLAY", "GameFontNormal" )
	frameLesserCharmOfGoodFortuneText:SetText( "0" )
	frameLesserCharmOfGoodFortuneText:SetTextColor( 1.00, 1.00, 1.00, 1.00 )
	frameLesserCharmOfGoodFortuneText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, top )
	frameLesserCharmOfGoodFortuneText:SetWidth( width )
	frameLesserCharmOfGoodFortuneText:SetJustifyH( "CENTER" )
	currencyFrameCharacterInfo.LesserCharmOfGoodFortuneText = frameLesserCharmOfGoodFortuneText
	left = left + spacing
	-- Set the ElderCharmOfGoodFortune font string.
	local frameElderCharmOfGoodFortune = AJM.globalCurrencyFramePrefix.."ElderCharmOfGoodFortune"
	local frameElderCharmOfGoodFortuneText = parentFrame:CreateFontString( frameElderCharmOfGoodFortune.."Text", "OVERLAY", "GameFontNormal" )
	frameElderCharmOfGoodFortuneText:SetText( "0" )
	frameElderCharmOfGoodFortuneText:SetTextColor( 1.00, 1.00, 1.00, 1.00 )
	frameElderCharmOfGoodFortuneText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, top )
	frameElderCharmOfGoodFortuneText:SetWidth( width )
	frameElderCharmOfGoodFortuneText:SetJustifyH( "CENTER" )
	currencyFrameCharacterInfo.ElderCharmOfGoodFortuneText = frameElderCharmOfGoodFortuneText
	left = left + spacing
	-- Set the MoguRuneOfFate font string.
	local frameMoguRuneOfFate = AJM.globalCurrencyFramePrefix.."MoguRuneOfFate"
	local frameMoguRuneOfFateText = parentFrame:CreateFontString( frameMoguRuneOfFate.."Text", "OVERLAY", "GameFontNormal" )
	frameMoguRuneOfFateText:SetText( "0" )
	frameMoguRuneOfFateText:SetTextColor( 1.00, 1.00, 1.00, 1.00 )
	frameMoguRuneOfFateText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, top )
	frameMoguRuneOfFateText:SetWidth( width )
	frameMoguRuneOfFateText:SetJustifyH( "CENTER" )
	currencyFrameCharacterInfo.MoguRuneOfFateText = frameMoguRuneOfFateText
	left = left + spacing
    -- Set the WarforgedSeal font string.
	local frameWarforgedSeal = AJM.globalCurrencyFramePrefix.."WarforgedSeal"
	local frameWarforgedSealText = parentFrame:CreateFontString( frameWarforgedSeal.."Text", "OVERLAY", "GameFontNormal" )
	frameWarforgedSealText:SetText( "0" )
	frameWarforgedSealText:SetTextColor( 1.00, 1.00, 1.00, 1.00 )
	frameWarforgedSealText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, top )
	frameWarforgedSealText:SetWidth( width )
	frameWarforgedSealText:SetJustifyH( "CENTER" )
	currencyFrameCharacterInfo.WarforgedSealText = frameWarforgedSealText
	left = left + spacing
    -- Set the BloodyCoin font string.
	local frameBloodyCoin = AJM.globalCurrencyFramePrefix.."BloodyCoin"
	local frameBloodyCoinText = parentFrame:CreateFontString( frameBloodyCoin.."Text", "OVERLAY", "GameFontNormal" )
	frameBloodyCoinText:SetText( "0" )
	frameBloodyCoinText:SetTextColor( 1.00, 1.00, 1.00, 1.00 )
	frameBloodyCoinText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, top )
	frameBloodyCoinText:SetWidth( width )
	frameBloodyCoinText:SetJustifyH( "CENTER" )
	currencyFrameCharacterInfo.BloodyCoinText = frameBloodyCoinText
	left = left + spacing
	-- Set the TimelessCoin font string.
	local frameTimelessCoin = AJM.globalCurrencyFramePrefix.."TimelessCoin"
	local frameTimelessCoinText = parentFrame:CreateFontString( frameTimelessCoin.."Text", "OVERLAY", "GameFontNormal" )
	frameTimelessCoinText:SetText( "0" )
	frameTimelessCoinText:SetTextColor( 1.00, 1.00, 1.00, 1.00 )
	frameTimelessCoinText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, top )
	frameTimelessCoinText:SetWidth( width )
	frameTimelessCoinText:SetJustifyH( "CENTER" )
	currencyFrameCharacterInfo.TimelessCoinText = frameTimelessCoinText
	left = left + spacing
	--ebony New WoD Currency
	-- Set the GarrisonResources font string.
	local frameGarrisonResources = AJM.globalCurrencyFramePrefix.."GarrisonResources"
	local frameGarrisonResourcesText = parentFrame:CreateFontString( frameGarrisonResources .."Text", "OVERLAY", "GameFontNormal" )
	frameGarrisonResourcesText:SetText( "0" )
	frameGarrisonResourcesText:SetTextColor( 1.00, 1.00, 1.00, 1.00 )
	frameGarrisonResourcesText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, top )
	frameGarrisonResourcesText:SetWidth( width )
	frameGarrisonResourcesText:SetJustifyH( "CENTER" )
	currencyFrameCharacterInfo.GarrisonResourcesText = frameGarrisonResourcesText
	left = left + spacing
	-- Set the TemperedFate font string.
	local frameTemperedFate = AJM.globalCurrencyFramePrefix.."TemperedFate"
	local frameTemperedFateText = parentFrame:CreateFontString( frameTemperedFate .."Text", "OVERLAY", "GameFontNormal" )
	frameTemperedFateText:SetText( "0" )
	frameTemperedFateText:SetTextColor( 1.00, 1.00, 1.00, 1.00 )
	frameTemperedFateText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, top )
	frameTemperedFateText:SetWidth( width )
	frameTemperedFateText:SetJustifyH( "CENTER" )
	currencyFrameCharacterInfo.TemperedFateText = frameTemperedFateText
	left = left + spacing
	-- Set the ApexisCrystal font string.
	local frameApexisCrystal = AJM.globalCurrencyFramePrefix.."ApexisCrystal"
	local frameApexisCrystalText = parentFrame:CreateFontString( frameApexisCrystal .."Text", "OVERLAY", "GameFontNormal" )
	frameApexisCrystalText:SetText( "0" )
	frameApexisCrystalText:SetTextColor( 1.00, 1.00, 1.00, 1.00 )
	frameApexisCrystalText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, top )
	frameApexisCrystalText:SetWidth( width )
	frameApexisCrystalText:SetJustifyH( "CENTER" )
	currencyFrameCharacterInfo.ApexisCrystalText = frameApexisCrystalText
	left = left + spacing
	-- Set the Darkmoon font string.
	local frameDarkmoon = AJM.globalCurrencyFramePrefix.."Darkmoon"
	local frameDarkmoonText = parentFrame:CreateFontString( frameDarkmoon .."Text", "OVERLAY", "GameFontNormal" )
	frameDarkmoonText:SetText( "0" )
	frameDarkmoonText:SetTextColor( 1.00, 1.00, 1.00, 1.00 )
	frameDarkmoonText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, top )
	frameDarkmoonText:SetWidth( width )
	frameDarkmoonText:SetJustifyH( "CENTER" )
	currencyFrameCharacterInfo.DarkmoonText = frameDarkmoonText
	left = left + spacing
		-- Set the InevitableFate font string.
	local frameInevitableFate = AJM.globalCurrencyFramePrefix.."InevitableFate"
	local frameInevitableFateText = parentFrame:CreateFontString( frameInevitableFate .."Text", "OVERLAY", "GameFontNormal" )
	frameInevitableFateText:SetText( "0" )
	frameInevitableFateText:SetTextColor( 1.00, 1.00, 1.00, 1.00 )
	frameInevitableFateText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, top )
	frameInevitableFateText:SetWidth( width )
	frameInevitableFateText:SetJustifyH( "CENTER" )
	currencyFrameCharacterInfo.InevitableFateText = frameInevitableFateText
	left = left + spacing
		-- Set the Oil font string.
	local frameOil = AJM.globalCurrencyFramePrefix.."Oil"
	local frameOilText = parentFrame:CreateFontString( frameOil .."Text", "OVERLAY", "GameFontNormal" )
	frameOilText:SetText( "0" )
	frameOilText:SetTextColor( 1.00, 1.00, 1.00, 1.00 )
	frameOilText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, top )
	frameOilText:SetWidth( width )
	frameOilText:SetJustifyH( "CENTER" )
	currencyFrameCharacterInfo.OilText = frameOilText
	left = left + spacing
		-- Set the TimeWalker font string.
	local frameTimeWalker = AJM.globalCurrencyFramePrefix.."TimeWalker"
	local frameTimeWalkerText = parentFrame:CreateFontString( frameTimeWalker .."Text", "OVERLAY", "GameFontNormal" )
	frameTimeWalkerText:SetText( "0" )
	frameTimeWalkerText:SetTextColor( 1.00, 1.00, 1.00, 1.00 )
	frameTimeWalkerText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, top )
	frameTimeWalkerText:SetWidth( width )
	frameTimeWalkerText:SetJustifyH( "CENTER" )
	currencyFrameCharacterInfo.TimeWalkerText = frameTimeWalkerText
	left = left + spacing	
end

function AJM:JambaToonHideCurrency()
	JambaToonCurrencyListFrame:Hide()
end

function AJM:JambaToonRequestCurrency()
	--AJM.Print("DoRequestCurrency", characterName)
	-- Colour red.
	local r = 1.0
	local g = 0.0
	local b = 0.0
	local a = 0.6
	for characterName, currencyFrameCharacterInfo in pairs( AJM.currencyFrameCharacterInfo ) do
		if JambaApi.GetCharacterOnlineStatus ( characterName ) == true then
		--	AJM.Print("offlineRemove")
		--	AJM.currencyFrameCharacterInfo[characterName] = nil
		--	return
		--else
		currencyFrameCharacterInfo.GoldText:SetTextColor( r, g, b, a )
		currencyFrameCharacterInfo.characterNameText:SetTextColor( r, g, b, a )
		currencyFrameCharacterInfo.HonorPointsText:SetTextColor( r, g, b, a )
		currencyFrameCharacterInfo.ConquestPointsText:SetTextColor( r, g, b, a )
		currencyFrameCharacterInfo.ValorText:SetTextColor( r, g, b, a )
		currencyFrameCharacterInfo.TolBaradCommendationText:SetTextColor( r, g, b, a )
		currencyFrameCharacterInfo.ChampionsSealText:SetTextColor( r, g, b, a )
		currencyFrameCharacterInfo.IllustriousJewelcraftersTokenText:SetTextColor( r, g, b, a )
		currencyFrameCharacterInfo.DalaranJewelcraftingTokenText:SetTextColor( r, g, b, a )
		currencyFrameCharacterInfo.IronpawTokenText:SetTextColor( r, g, b, a )
		currencyFrameCharacterInfo.LesserCharmOfGoodFortuneText:SetTextColor( r, g, b, a )
		currencyFrameCharacterInfo.ElderCharmOfGoodFortuneText:SetTextColor( r, g, b, a )
		currencyFrameCharacterInfo.MoguRuneOfFateText:SetTextColor( r, g, b, a )
        currencyFrameCharacterInfo.WarforgedSealText:SetTextColor( r, g, b, a )
        currencyFrameCharacterInfo.BloodyCoinText:SetTextColor( r, g, b, a )
        currencyFrameCharacterInfo.TimelessCoinText:SetTextColor( r, g, b, a )
		--ebony New WoD Currency
		currencyFrameCharacterInfo.GarrisonResourcesText:SetTextColor( r, g, b, a )
		currencyFrameCharacterInfo.TemperedFateText:SetTextColor( r, g, b, a )
		currencyFrameCharacterInfo.ApexisCrystalText:SetTextColor( r, g, b, a )
		currencyFrameCharacterInfo.DarkmoonText:SetTextColor( r, g, b, a )
		currencyFrameCharacterInfo.InevitableFateText:SetTextColor( r, g, b, a )
		currencyFrameCharacterInfo.OilText:SetTextColor( r, g, b, a )
		else
			--AJM.currencyFrameCharacterInfo[characterName] = nil
			--table.wipe( AJM.currentCurrencyValues )
			--AJM.currencyFrameCharacterInfo = {}
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
	table.wipe( AJM.currentCurrencyValues )
	AJM.currentCurrencyValues.currGold = GetMoney()
	AJM.currentCurrencyValues.currHonorPoints = select( 2, GetCurrencyInfo( AJM.CHonorPoints ) )
	AJM.currentCurrencyValues.currConquestPoints = select( 2, GetCurrencyInfo( AJM.CConquestPoints ) )
	AJM.currentCurrencyValues.currValor = select( 2, GetCurrencyInfo( AJM.CValor ) )	
	AJM.currentCurrencyValues.currTolBaradCommendation = select( 2, GetCurrencyInfo( AJM.CTolBaradCommendation ) )
	AJM.currentCurrencyValues.currChampionsSeal = select( 2, GetCurrencyInfo(AJM.CChampionsSeal ) )
	AJM.currentCurrencyValues.currIllustriousJewelcraftersToken = select( 2, GetCurrencyInfo( AJM.CIllustriousJewelcraftersToken ) )
	AJM.currentCurrencyValues.currDalaranJewelcraftingToken = select( 2, GetCurrencyInfo( AJM.CDalaranJewelcraftingToken ) )
	AJM.currentCurrencyValues.currIronpawToken = select( 2, GetCurrencyInfo( AJM.CIronpawToken ) )
	AJM.currentCurrencyValues.currLesserCharmOfGoodFortune = select( 2, GetCurrencyInfo( AJM.CLesserCharmOfGoodFortune ) )
	AJM.currentCurrencyValues.currElderCharmOfGoodFortune = select( 2, GetCurrencyInfo( AJM.CElderCharmOfGoodFortune ) )
	AJM.currentCurrencyValues.currMoguRuneOfFate = select( 2, GetCurrencyInfo( AJM.CMoguRuneOfFate ) )
    AJM.currentCurrencyValues.currWarforgedSeal = select( 2, GetCurrencyInfo( AJM.CWarforgedSeal ) )
    AJM.currentCurrencyValues.currBloodyCoin = select( 2, GetCurrencyInfo( AJM.CBloodyCoin ) )
    AJM.currentCurrencyValues.currTimelessCoin = select( 2, GetCurrencyInfo( AJM.CTimelessCoin ) )
	--ebony New WoD Currency
	AJM.currentCurrencyValues.currGarrisonResources = select( 2, GetCurrencyInfo( AJM.CGarrisonResources ) )
	AJM.currentCurrencyValues.currTemperedFate = select( 2, GetCurrencyInfo( AJM.CTemperedFate ) )
	AJM.currentCurrencyValues.currApexisCrystal = select( 2, GetCurrencyInfo( AJM.CApexisCrystal ) )
	AJM.currentCurrencyValues.currDarkmoon = select( 2, GetCurrencyInfo( AJM.CDarkmoon ) )
	AJM.currentCurrencyValues.currInevitableFate = select( 2, GetCurrencyInfo( AJM.CInevitableFate ) )
	AJM.currentCurrencyValues.currOil = select( 2, GetCurrencyInfo( AJM.COil ) )	
	AJM.currentCurrencyValues.currTimeWalker = select( 2, GetCurrencyInfo( AJM.CTimeWalker ) )
	AJM:JambaSendCommandToToon( characterName, AJM.COMMAND_HERE_IS_CURRENCY, AJM.currentCurrencyValues )
end

function AJM:DoShowToonsCurrency( characterName, currencyValues )
	--AJM.Print("DoShowCurrency", characterName)
	--if JambaPrivate.Team.GetCharacterOnlineStatus( characterName ) == true then
	local parentFrame = JambaToonCurrencyListFrame
	-- Get (or create and get) the character information.
	local currencyFrameCharacterInfo = AJM.currencyFrameCharacterInfo[characterName]
	if currencyFrameCharacterInfo == nil then
		AJM:CreateJambaCurrencyFrameInfo( characterName, parentFrame )
		currencyFrameCharacterInfo = AJM.currencyFrameCharacterInfo[characterName]
	end
	-- Colour white.
	local r = 1.0
	local g = 1.0
	local b = 1.0
	local a = 1.0
	currencyFrameCharacterInfo.GoldText:SetTextColor( r, g, b, a )
	currencyFrameCharacterInfo.characterNameText:SetTextColor( r, g, b, a )
	currencyFrameCharacterInfo.HonorPointsText:SetTextColor( r, g, b, a )
	currencyFrameCharacterInfo.ConquestPointsText:SetTextColor( r, g, b, a )
	currencyFrameCharacterInfo.ValorText:SetTextColor( r, g, b, a )
	currencyFrameCharacterInfo.TolBaradCommendationText:SetTextColor( r, g, b, a )
	currencyFrameCharacterInfo.ChampionsSealText:SetTextColor( r, g, b, a )
	currencyFrameCharacterInfo.IllustriousJewelcraftersTokenText:SetTextColor( r, g, b, a )
	currencyFrameCharacterInfo.DalaranJewelcraftingTokenText:SetTextColor( r, g, b, a )
	currencyFrameCharacterInfo.IronpawTokenText:SetTextColor( r, g, b, a )
	currencyFrameCharacterInfo.LesserCharmOfGoodFortuneText:SetTextColor( r, g, b, a )
	currencyFrameCharacterInfo.ElderCharmOfGoodFortuneText:SetTextColor( r, g, b, a )
	currencyFrameCharacterInfo.MoguRuneOfFateText:SetTextColor( r, g, b, a )
    currencyFrameCharacterInfo.WarforgedSealText:SetTextColor( r, g, b, a )
    currencyFrameCharacterInfo.BloodyCoinText:SetTextColor( r, g, b, a )
    currencyFrameCharacterInfo.TimelessCoinText:SetTextColor( r, g, b, a )
	--ebony New WoD Currency
	currencyFrameCharacterInfo.GarrisonResourcesText:SetTextColor( r, g, b, a )
	currencyFrameCharacterInfo.TemperedFateText:SetTextColor( r, g, b, a )
	currencyFrameCharacterInfo.ApexisCrystalText:SetTextColor( r, g, b, a )
	currencyFrameCharacterInfo.DarkmoonText:SetTextColor( r, g, b, a )
	currencyFrameCharacterInfo.InevitableFateText:SetTextColor( r, g, b, a )
	currencyFrameCharacterInfo.OilText:SetTextColor( r, g, b, a )	
	-- Information.
	currencyFrameCharacterInfo.GoldText:SetText( JambaUtilities:FormatMoneyString( currencyValues.currGold ) )
	currencyFrameCharacterInfo.HonorPointsText:SetText( currencyValues.currHonorPoints )
	currencyFrameCharacterInfo.ConquestPointsText:SetText( currencyValues.currConquestPoints )
	currencyFrameCharacterInfo.ValorText:SetText( currencyValues.currValor )	
	currencyFrameCharacterInfo.TolBaradCommendationText:SetText( currencyValues.currTolBaradCommendation )
	currencyFrameCharacterInfo.ChampionsSealText:SetText( currencyValues.currChampionsSeal )
	currencyFrameCharacterInfo.IllustriousJewelcraftersTokenText:SetText( currencyValues.currIllustriousJewelcraftersToken )
	currencyFrameCharacterInfo.DalaranJewelcraftingTokenText:SetText( currencyValues.currDalaranJewelcraftingToken )
	currencyFrameCharacterInfo.IronpawTokenText:SetText( currencyValues.currIronpawToken )
	currencyFrameCharacterInfo.LesserCharmOfGoodFortuneText:SetText( currencyValues.currLesserCharmOfGoodFortune )
	currencyFrameCharacterInfo.ElderCharmOfGoodFortuneText:SetText( currencyValues.currElderCharmOfGoodFortune )
	currencyFrameCharacterInfo.MoguRuneOfFateText:SetText( currencyValues.currMoguRuneOfFate )
    currencyFrameCharacterInfo.WarforgedSealText:SetText( currencyValues.currWarforgedSeal )
    currencyFrameCharacterInfo.BloodyCoinText:SetText( currencyValues.currBloodyCoin )
    currencyFrameCharacterInfo.TimelessCoinText:SetText( currencyValues.currTimelessCoin )
	--ebony New WoD Currency
	currencyFrameCharacterInfo.GarrisonResourcesText:SetText( currencyValues.currGarrisonResources )
	currencyFrameCharacterInfo.TemperedFateText:SetText( currencyValues.currTemperedFate )
	currencyFrameCharacterInfo.ApexisCrystalText:SetText( currencyValues.currApexisCrystal )
	currencyFrameCharacterInfo.DarkmoonText:SetText( currencyValues.currDarkmoon )
	currencyFrameCharacterInfo.InevitableFateText:SetText( currencyValues.currInevitableFate )
	currencyFrameCharacterInfo.OilText:SetText( currencyValues.currOil )
	currencyFrameCharacterInfo.TimeWalkerText:SetText( currencyValues.currTimeWalker )
	-- Total gold.
	AJM.currencyTotalGold = AJM.currencyTotalGold + currencyValues.currGold
	parentFrame.TotalGoldText:SetText( JambaUtilities:FormatMoneyString( AJM.currencyTotalGold ) )
	if IsInGuild() then
		parentFrame.TotalGoldGuildText:SetText( JambaUtilities:FormatMoneyString( GetGuildBankMoney() ) )
	end
	-- Update width of currency list.
	AJM:CurrencyListSetColumnWidth()
	JambaToonCurrencyListFrame:Show()
	--end
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