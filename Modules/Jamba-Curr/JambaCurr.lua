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

-- Currency Identifiers. Old stuff
AJM.CDalaranJewelcraftingToken = 61
AJM.CValor = 1191
AJM.CChampionsSeal = 241
AJM.CIllustriousJewelcraftersToken = 361
AJM.CConquestPoints = 390
AJM.CTolBaradCommendation = 391
AJM.CHonorPoints = 392
AJM.CTypeNine = 402
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
		-- Currency default Shown
		currTypeOne = true,
		currTypeTwo = true,
		currTypeThree = true,
		currTypeFour = true,
		currTypeFive = true,
		currTypeSix = false,
		currTypeSeven = false,
		currTypeEight = false,
		currTypeNine = false,
		currTypeTen = false,
		-- Currency default Id's http://www.wowhead.com/currencies
		--Honor
		CcurrTypeOne = 392,
		CcurrTypeOneName = L["Currency One"],
		--Conquest
		CcurrTypeTwo = 390,
		CcurrTypeTwoName = L["Currency Two"],
		--Valor
		CcurrTypeThree = 1191,
		CcurrTypeThreeName = L["Currency Three"],
		--Time Walker Coins
		CcurrTypeFour = 1129,
		CcurrTypeFourName = L["Currency Four"],
		--Garrison Resources 
		CcurrTypeFive = 824,
		CcurrTypeFiveName = L["Currency Five"],
		-- Apexis Crystal} 
		CcurrTypeSix = 823,
		CcurrTypeSixName = L["Currency Six"],
	--[[	-- [PH]Time Walker Coins 
		CcurrTypeSeven = 1166,
		CcurrTypeSevenName = L["Currency Seven"],
		--[PH]Oil
		CcurrTypeEight = 1101,
		CcurrTypeEightName = L["Currency Eight"],
		--[PH] Honor
		CcurrTypeNine = 392,
		CcurrTypeNineName = L["Currency Nine"],
		--[PH] Honor
		CcurrTypeTen = 392,
		CcurrTypeTenName = L["Currency Ten"],
	]]	
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
		currencyNameWidth = 60,
		currencyPointsWidth = 50,
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
	
	--Currency One
	movingTop = movingTop - checkBoxHeight		
	AJM.settingsControl.checkBoxCurrencyTypeOne = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		halfWidth, 
		left, 
		movingTop, 
		L["Currency One"],
		AJM.SettingsToggleCurrencyTypeOne,
		L["Shows Currency on The Currency display window."]
	)
	AJM.settingsControl.labelBoxCurrencyTypeOneName = JambaHelperSettings:CreateLabel( 
		AJM.settingsControl,
		halfWidth,
		column2left,
		movingTop,
		L["CurrencyName"]
	)	
	AJM.settingsControl.labelBoxCurrencyTypeOneName:SetCallback( "OnEnterPressed", AJM.LabelBoxChangedCurrencyTypeOneName )
	
	movingTop = movingTop - continueLabelHeight
	AJM.settingsControl.editBoxCurrencyTypeOneID = JambaHelperSettings:CreateEditBox( 
		AJM.settingsControl,
		thirdWidth,
		left + indent,
		movingTop,
		L["CurrencyID"],
		L["You can change the Currency ID here.\n\nFor a list of ID's\nhttp://www.wowhead.com/currencies"]
	)	
	AJM.settingsControl.editBoxCurrencyTypeOneID:SetCallback( "OnEnterPressed", AJM.EditBoxChangedCurrencyTypeOneID )
	
	--Currency Two
	movingTop = movingTop - editBoxHeight
	AJM.settingsControl.checkBoxCurrencyTypeTwo = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		halfWidth, 
		left, 
		movingTop, 
		L["Currency Two"],
		AJM.SettingsToggleCurrencyTypeTwo,
		L["Shows Currency on The Currency display window."]
	)

	--movingTop = movingTop - continueLabelHeight
	AJM.settingsControl.labelBoxCurrencyTypeTwoName = JambaHelperSettings:CreateLabel( 
		AJM.settingsControl,
		halfWidth,
		column2left,
		movingTop,
		L["CurrencyName"]
	)	
	AJM.settingsControl.labelBoxCurrencyTypeTwoName:SetCallback( "OnEnterPressed", AJM.LabelBoxChangedCurrencyTypeTwoName )
	movingTop = movingTop - continueLabelHeight
	AJM.settingsControl.editBoxCurrencyTypeTwoID = JambaHelperSettings:CreateEditBox( 
		AJM.settingsControl,
		thirdWidth,
		left + indent,
		movingTop,
		L["CurrencyID"],
		L["You can change the Currency ID here.\n\nFor a list of ID's\nhttp://www.wowhead.com/currencies"]
	)	
	AJM.settingsControl.editBoxCurrencyTypeTwoID:SetCallback( "OnEnterPressed", AJM.EditBoxChangedCurrencyTypeTwoID )	

	--Currency Three
	movingTop = movingTop - editBoxHeight	
	AJM.settingsControl.checkBoxCurrencyTypeThree = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		halfWidth, 
		left, 
		movingTop, 
		L["Currency Three"],
		AJM.SettingsToggleCurrencyTypeThree,
		L["Shows Currency on The Currency display window."]
	)		
	--movingTop = movingTop - continueLabelHeight
	AJM.settingsControl.labelBoxCurrencyTypeThreeName = JambaHelperSettings:CreateLabel( 
		AJM.settingsControl,
		halfWidth,
		column2left,
		movingTop,
		L["CurrencyName"]
	)	
	AJM.settingsControl.labelBoxCurrencyTypeThreeName:SetCallback( "OnEnterPressed", AJM.LabelBoxChangedCurrencyTypeThreeName )
	movingTop = movingTop - continueLabelHeight
	AJM.settingsControl.editBoxCurrencyTypeThreeID = JambaHelperSettings:CreateEditBox( 
		AJM.settingsControl,
		thirdWidth,
		left + indent,
		movingTop,
		L["CurrencyID"],
		L["You can change the Currency ID here.\n\nFor a list of ID's\nhttp://www.wowhead.com/currencies"]
	)	
	AJM.settingsControl.editBoxCurrencyTypeThreeID:SetCallback( "OnEnterPressed", AJM.EditBoxChangedCurrencyTypeThreeID )	
	--Currency Four
	movingTop = movingTop - editBoxHeight
	AJM.settingsControl.checkBoxCurrencyTypeFour = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		halfWidth, 
		left, 
		movingTop, 
		L["Currency Four"],
		AJM.SettingsToggleCurrencyTypeFour,
		L["Shows Currency on The Currency display window."]
	)	
	AJM.settingsControl.labelBoxCurrencyTypeFourName = JambaHelperSettings:CreateLabel( 
		AJM.settingsControl,
		halfWidth,
		column2left,
		movingTop,
		L["CurrencyName"]
	)	
	AJM.settingsControl.labelBoxCurrencyTypeFourName:SetCallback( "OnEnterPressed", AJM.LabelBoxChangedCurrencyTypeFourName )
	movingTop = movingTop - continueLabelHeight
	AJM.settingsControl.editBoxCurrencyTypeFourID = JambaHelperSettings:CreateEditBox( 
		AJM.settingsControl,
		thirdWidth,
		left + indent,
		movingTop,
		L["CurrencyID"],
		L["You can change the Currency ID here.\n\nFor a list of ID's\nhttp://www.wowhead.com/currencies"]
	)	
	AJM.settingsControl.editBoxCurrencyTypeFourID:SetCallback( "OnEnterPressed", AJM.EditBoxChangedCurrencyTypeFourID )	
	--Currency Five
	movingTop = movingTop - editBoxHeight
	AJM.settingsControl.checkBoxCurrencyTypeFive = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		halfWidth, 
		left, 
		movingTop, 
		L["Currency Five"],
		AJM.SettingsToggleCurrencyTypeFive,
		L["Shows Currency on The Currency display window."]
	)	
		AJM.settingsControl.labelBoxCurrencyTypeFiveName = JambaHelperSettings:CreateLabel( 
		AJM.settingsControl,
		halfWidth,
		column2left,
		movingTop,
		L["CurrencyName"]
	)	
	AJM.settingsControl.labelBoxCurrencyTypeFiveName:SetCallback( "OnEnterPressed", AJM.LabelBoxChangedCurrencyTypeFiveName )
	movingTop = movingTop - continueLabelHeight
	AJM.settingsControl.editBoxCurrencyTypeFiveID = JambaHelperSettings:CreateEditBox( 
		AJM.settingsControl,
		thirdWidth,
		left + indent,
		movingTop,
		L["CurrencyID"],
		L["You can change the Currency ID here.\n\nFor a list of ID's\nhttp://www.wowhead.com/currencies"]
	)
	AJM.settingsControl.editBoxCurrencyTypeFiveID:SetCallback( "OnEnterPressed", AJM.EditBoxChangedCurrencyTypeFiveID )	
	--Currency Six
	movingTop = movingTop - editBoxHeight	
	AJM.settingsControl.checkBoxCurrencyTypeSix = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		halfWidth, 
		left, 
		movingTop, 
		L["Currency Six"],
		AJM.SettingsToggleCurrencyTypeSix,
		L["Shows Currency on The Currency display window."]
	)	
	AJM.settingsControl.labelBoxCurrencyTypeSixName = JambaHelperSettings:CreateLabel( 
		AJM.settingsControl,
		halfWidth,
		column2left,
		movingTop,
		L["CurrencyName"]
	)	
	AJM.settingsControl.labelBoxCurrencyTypeSixName:SetCallback( "OnEnterPressed", AJM.LabelBoxChangedCurrencyTypeSixName )
	movingTop = movingTop - continueLabelHeight
	AJM.settingsControl.editBoxCurrencyTypeSixID = JambaHelperSettings:CreateEditBox( 
		AJM.settingsControl,
		thirdWidth,
		left + indent,
		movingTop,
		L["CurrencyID"],
		L["You can change the Currency ID here.\n\nFor a list of ID's\nhttp://www.wowhead.com/currencies"]
	)
	AJM.settingsControl.editBoxCurrencyTypeSixID:SetCallback( "OnEnterPressed", AJM.EditBoxChangedCurrencyTypeSixID )		
--[[ Extra Space if needed some point in time Ebony
	--Currency Seven
	movingTop = movingTop - editBoxHeight
	AJM.settingsControl.checkBoxCurrencyTypeSeven = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		halfWidth, 
		left, 
		movingTop, 
		L["Currency Seven"],
		L["Shows Currency on The Currency display window."],
		AJM.SettingsToggleCurrencyTypeSeven
	)	
	AJM.settingsControl.labelBoxCurrencyTypeSevenName = JambaHelperSettings:CreateLabel( 
		AJM.settingsControl,
		halfWidth,
		column2left,
		movingTop,
		L["CurrencyName"]
	)	
	AJM.settingsControl.labelBoxCurrencyTypeSevenName:SetCallback( "OnEnterPressed", AJM.LabeloxChangedCurrencyTypeSevenName )
	movingTop = movingTop - continueLabelHeight
	AJM.settingsControl.editBoxCurrencyTypeSevenID = JambaHelperSettings:CreateEditBox( 
		AJM.settingsControl,
		thirdWidth,
		left + indent,
		movingTop,
		L["CurrencyID"],
		L["You can change the Currency ID here.\n\nFor a list of ID's\nhttp://www.wowhead.com/currencies"]
	)	
	AJM.settingsControl.editBoxCurrencyTypeSevenID:SetCallback( "OnEnterPressed", AJM.EditBoxChangedCurrencyTypeSevenID )
	--Currency Eight
	movingTop = movingTop - editBoxHeight
	AJM.settingsControl.checkBoxCurrencyTypeEight = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		halfWidth, 
		left, 
		movingTop, 
		L["Currency Eight"],
		AJM.SettingsToggleCurrencyTypeEight,
		L["Shows Currency on The Currency display window."]
	)	
	AJM.settingsControl.labelBoxCurrencyTypeEightName = JambaHelperSettings:CreateLabel( 
		AJM.settingsControl,
		halfWidth,
		column2left,
		movingTop,
		L["CurrencyName"]
	)	
	AJM.settingsControl.labelBoxCurrencyTypeEightName:SetCallback( "OnEnterPressed", AJM.LabelBoxChangedCurrencyTypeEightName )
	movingTop = movingTop - continueLabelHeight
	AJM.settingsControl.editBoxCurrencyTypeEightID = JambaHelperSettings:CreateEditBox( 
		AJM.settingsControl,
		thirdWidth,
		left + indent,
		movingTop,
		L["CurrencyID"],
		L["You can change the Currency ID here.\n\nFor a list of ID's\nhttp://www.wowhead.com/currencies"]
	)	
	AJM.settingsControl.editBoxCurrencyTypeEightID:SetCallback( "OnEnterPressed", AJM.EditBoxChangedCurrencyTypeEightID )
	--Currency Nine
	movingTop = movingTop - editBoxHeight
	AJM.settingsControl.checkBoxCurrencyTypeNine = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		halfWidth, 
		left, 
		movingTop, 
		L["Currency Nine"],
		AJM.SettingsToggleCurrencyTypeNine,
		L["Shows Currency on The Currency display window."]
	)	
	AJM.settingsControl.labelBoxCurrencyTypeNineName = JambaHelperSettings:CreateLabel( 
		AJM.settingsControl,
		halfWidth,
		column2left,
		movingTop,
		L["CurrencyName"]
	)	
	AJM.settingsControl.labelBoxCurrencyTypeNineName:SetCallback( "OnEnterPressed", AJM.LabelBoxChangedCurrencyTypeNineName )
	movingTop = movingTop - continueLabelHeight
	AJM.settingsControl.editBoxCurrencyTypeNineID = JambaHelperSettings:CreateEditBox( 
		AJM.settingsControl,
		thirdWidth,
		left + indent,
		movingTop,
		L["CurrencyID"],
		L["You can change the Currency ID here.\n\nFor a list of ID's\nhttp://www.wowhead.com/currencies"]
	)	
	AJM.settingsControl.editBoxCurrencyTypeNineID:SetCallback( "OnEnterPressed", AJM.EditBoxChangedCurrencyTypeNineID )
	-- Currency Ten
	movingTop = movingTop - editBoxHeight
	AJM.settingsControl.checkBoxCurrencyTypeTen = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		halfWidth, 
		left, 
		movingTop, 
		L["Currency Ten"],
		AJM.SettingsToggleCurrencyTypeTen,
		L["Shows Currency on The Currency display window."]
	)
	AJM.settingsControl.labelBoxCurrencyTypeTenName = JambaHelperSettings:CreateLabel( 
		AJM.settingsControl,
		halfWidth,
		column2left,
		movingTop,
		L["CurrencyName"]
	)	
	AJM.settingsControl.labelBoxCurrencyTypeTenName:SetCallback( "OnEnterPressed", AJM.LabelBoxChangedCurrencyTypeTenName )
	movingTop = movingTop - continueLabelHeight
	AJM.settingsControl.editBoxCurrencyTypeTenID = JambaHelperSettings:CreateEditBox( 
		AJM.settingsControl,
		thirdWidth,
		left + indent,
		movingTop,
		L["CurrencyID"],
		L["You can change the Currency ID here.\n\nFor a list of ID's\nhttp://www.wowhead.com/currencies"]
	)
	AJM.settingsControl.editBoxCurrencyTypeTenID:SetCallback( "OnEnterPressed", AJM.EditBoxChangedCurrencyTypeTenID )	
]]	-- Other Stuff	
	movingTop = movingTop - editBoxHeight
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
	-- 
	AJM.settingsControl.checkBoxCurrencyTypeOne:SetValue( AJM.db.currTypeOne )
	AJM.settingsControl.editBoxCurrencyTypeOneID:SetText ( AJM.db.CcurrTypeOne )
	AJM.settingsControl.labelBoxCurrencyTypeOneName:SetText ( AJM.db.CcurrTypeOneName )
	
	AJM.settingsControl.checkBoxCurrencyTypeTwo:SetValue( AJM.db.currTypeTwo )
	AJM.settingsControl.editBoxCurrencyTypeTwoID:SetText ( AJM.db.CcurrTypeTwo )
	AJM.settingsControl.labelBoxCurrencyTypeTwoName:SetText ( AJM.db.CcurrTypeTwoName )	
	
	AJM.settingsControl.checkBoxCurrencyTypeThree:SetValue( AJM.db.currTypeThree )
	AJM.settingsControl.editBoxCurrencyTypeThreeID:SetText ( AJM.db.CcurrTypeThree )
	AJM.settingsControl.labelBoxCurrencyTypeThreeName:SetText ( AJM.db.CcurrTypeThreeName )	
	
	AJM.settingsControl.checkBoxCurrencyTypeFour:SetValue( AJM.db.currTypeFour )	
	AJM.settingsControl.editBoxCurrencyTypeFourID:SetText ( AJM.db.CcurrTypeFour )
	AJM.settingsControl.labelBoxCurrencyTypeFourName:SetText ( AJM.db.CcurrTypeFourName )
	
	AJM.settingsControl.checkBoxCurrencyTypeFive:SetValue( AJM.db.currTypeFive )
	AJM.settingsControl.editBoxCurrencyTypeFiveID:SetText ( AJM.db.CcurrTypeFive )
	AJM.settingsControl.labelBoxCurrencyTypeFiveName:SetText ( AJM.db.CcurrTypeFiveName )	
		
	AJM.settingsControl.checkBoxCurrencyTypeSix:SetValue( AJM.db.currTypeSix )
	AJM.settingsControl.editBoxCurrencyTypeSixID:SetText ( AJM.db.CcurrTypeSix )
	AJM.settingsControl.labelBoxCurrencyTypeSixName:SetText ( AJM.db.CcurrTypeSixName )	
	
--[[ Extra If needed for Some other Use Ebony	
	AJM.settingsControl.checkBoxCurrencyTypeSeven:SetValue( AJM.db.currTypeSeven )
	AJM.settingsControl.editBoxCurrencyTypeSevenID:SetText ( AJM.db.CcurrTypeSeven )
	AJM.settingsControl.labelBoxCurrencyTypeSevenName:SetText ( AJM.db.CcurrTypeSevenName )	

	AJM.settingsControl.checkBoxCurrencyTypeEight:SetValue( AJM.db.currTypeEight )
	AJM.settingsControl.editBoxCurrencyTypeEightID:SetText ( AJM.db.CcurrTypeEight )
	AJM.settingsControl.labelBoxCurrencyTypeEightName:SetText ( AJM.db.CcurrTypeEightName )		

	AJM.settingsControl.checkBoxCurrencyTypeNine:SetValue( AJM.db.currTypeNine )
	AJM.settingsControl.editBoxCurrencyTypeNineID:SetText ( AJM.db.CcurrTypeNine )
	AJM.settingsControl.labelBoxCurrencyTypeNineName:SetText ( AJM.db.CcurrTypeNineName )	

	AJM.settingsControl.checkBoxCurrencyTypeTen:SetValue( AJM.db.currTypeTen )
	AJM.settingsControl.editBoxCurrencyTypeTenID:SetText ( AJM.db.CcurrTypeTen )
	AJM.settingsControl.labelBoxCurrencyTypeTenName:SetText ( AJM.db.CcurrTypeTenName )	
]]	
	--state
	AJM.settingsControl.editBoxCurrencyTypeOneID:SetDisabled ( not AJM.db.currTypeOne )
	AJM.settingsControl.labelBoxCurrencyTypeOneName:SetDisabled ( not AJM.db.currTypeOne )
	
	AJM.settingsControl.editBoxCurrencyTypeTwoID:SetDisabled ( not AJM.db.currTypeTwo )
	AJM.settingsControl.labelBoxCurrencyTypeTwoName:SetDisabled ( not AJM.db.currTypeTwo )
	
	AJM.settingsControl.editBoxCurrencyTypeThreeID:SetDisabled ( not AJM.db.currTypeThree )
	AJM.settingsControl.labelBoxCurrencyTypeThreeName:SetDisabled ( not AJM.db.currTypeThree )

	AJM.settingsControl.editBoxCurrencyTypeFourID:SetDisabled ( not AJM.db.currTypeFour )
	AJM.settingsControl.labelBoxCurrencyTypeFourName:SetDisabled ( not AJM.db.currTypeFour )

	AJM.settingsControl.editBoxCurrencyTypeFiveID:SetDisabled ( not AJM.db.currTypeFive )
	AJM.settingsControl.labelBoxCurrencyTypeFiveName:SetDisabled ( not AJM.db.currTypeFive )

	AJM.settingsControl.editBoxCurrencyTypeSixID:SetDisabled ( not AJM.db.currTypeSix )
	AJM.settingsControl.labelBoxCurrencyTypeSixName:SetDisabled ( not AJM.db.currTypeSix )

--[[ Extra If needed for Some other Use Ebony	Need to change this [PH] Code EBONY	
	AJM.settingsControl.editBoxCurrencyTypeThreeID:SetDisabled ( not AJM.db.currTypeThree )
	AJM.settingsControl.labelBoxCurrencyTypeThreeName:SetDisabled ( not AJM.db.currTypeThree )

	AJM.settingsControl.editBoxCurrencyTypeFourID:SetDisabled ( not AJM.db.currTypeFour )
	AJM.settingsControl.labelBoxCurrencyTypeFourName:SetDisabled ( not AJM.db.currTypeFour )

	AJM.settingsControl.editBoxCurrencyTypeOneID:SetDisabled ( not AJM.db.currTypeFive )
	AJM.settingsControl.labelBoxCurrencyTypeOneName:SetDisabled ( not AJM.db.currTypeFive )

	AJM.settingsControl.editBoxCurrencyTypeSixID:SetDisabled ( not AJM.db.currTypeSix )
	AJM.settingsControl.labelBoxCurrencyTypeSixName:SetDisabled ( not AJM.db.currTypeSix )
]]	

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
		AJM:SettingsUpdateBorderStyle()
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

function AJM:SettingsToggleCurrencyTypeOne( event, checked )
	AJM.db.currTypeOne = checked
	AJM:SettingsRefresh()
end

function AJM:EditBoxChangedCurrencyTypeOneID( event, text )
	AJM.db.CcurrTypeOne = text
	AJM:JambaToonRequestCurrency()
	AJM:SettingsRefresh()
end

function AJM:LabelBoxChangedCurrencyTypeOneName( event, text )
	AJM.db.CcurrTypeOneName = text
	AJM:SettingsRefresh()
end


function AJM:SettingsToggleCurrencyTypeTwo( event, checked )
	AJM.db.currTypeTwo = checked
	AJM:SettingsRefresh()
end

function AJM:EditBoxChangedCurrencyTypeTwoID( event, text )
	AJM.db.CcurrTypeTwo = text
	AJM:JambaToonRequestCurrency()
	AJM:SettingsRefresh()
end

function AJM:LabelBoxChangedCurrencyTypeTwoName( event, text )
	AJM.db.CcurrTypeTwoName = text
	AJM:SettingsRefresh()
end


function AJM:SettingsToggleCurrencyTypeThree( event, checked )
	AJM.db.currTypeThree = checked
	AJM:SettingsRefresh()
end

function AJM:EditBoxChangedCurrencyTypeThreeID( event, text )
	AJM.db.CcurrTypeThree = text
	AJM:JambaToonRequestCurrency()
	AJM:SettingsRefresh()
end

function AJM:LabelBoxChangedCurrencyTypeThreeName( event, text )
	AJM.db.CcurrTypeThreeName = text
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleCurrencyTypeFour( event, checked )
	AJM.db.currTypeFour = checked
	AJM:SettingsRefresh()
end

function AJM:EditBoxChangedCurrencyTypeFourID( event, text )
	AJM.db.CcurrTypeFour = text
	AJM:JambaToonRequestCurrency()
	AJM:SettingsRefresh()
end

function AJM:LabelBoxChangedCurrencyTypeFourName( event, text )
	AJM.db.CcurrTypeFourName = text
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleCurrencyTypeFive( event, checked )
	AJM.db.currTypeFive = checked
	AJM:SettingsRefresh()
end

function AJM:EditBoxChangedCurrencyTypeFiveID( event, text )
	AJM.db.CcurrTypeFive = text
	AJM:JambaToonRequestCurrency()
	AJM:SettingsRefresh()
end

function AJM:LabelBoxChangedCurrencyTypeFiveName( event, text )
	AJM.db.CcurrTypeFiveName = text
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleCurrencyTypeSix( event, checked )
	AJM.db.currTypeSix = checked
	AJM:SettingsRefresh()
end

function AJM:EditBoxChangedCurrencyTypeSixID( event, text )
	AJM.db.CcurrTypeSix = text
	AJM:JambaToonRequestCurrency()
	AJM:SettingsRefresh()
end

function AJM:LabelBoxChangedCurrencyTypeSixName( event, text )
	AJM.db.CcurrTypeSixName = text
	AJM:SettingsRefresh()
end

--[[ Extra If needed for Some other Use Ebony
function AJM:SettingsToggleCurrencyTypeSeven( event, checked )
	AJM.db.currTypeSeven = checked
	AJM:SettingsRefresh()
end

function AJM:EditBoxChangedCurrencyTypeSevenID( event, text )
	AJM.db.CcurrTypeSeven = text
	AJM:JambaToonRequestCurrency()
	AJM:SettingsRefresh()
end

function AJM:LabelBoxChangedCurrencyTypeSevenName( event, text )
	AJM.db.CcurrTypeSevenName = text
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleCurrencyTypeEight( event, checked )
	AJM.db.currTypeEight = checked
	AJM:SettingsRefresh()
end

function AJM:EditBoxChangedCurrencyTypeEightID( event, text )
	AJM.db.CcurrTypeEight = text
	AJM:JambaToonRequestCurrency()
	AJM:SettingsRefresh()
end

function AJM:LabelBoxChangedCurrencyTypeEightName( event, text )
	AJM.db.CcurrTypeEightName = text
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleCurrencyTypeNine( event, checked )
	AJM.db.currTypeNine = checked
	AJM:SettingsRefresh()
end

function AJM:EditBoxChangedCurrencyTypeNineID( event, text )
	AJM.db.CcurrTypeEight = text
	AJM:JambaToonRequestCurrency()
	AJM:SettingsRefresh()
end

function AJM:LabelBoxChangedCurrencyTypeNineName( event, text )
	AJM.db.CcurrTypeNineName = text
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleCurrencyTypeTen( event, checked )
	AJM.db.currTypeTen = checked
	AJM:SettingsRefresh()
end

function AJM:EditBoxChangedCurrencyTypeTenID( event, text )
	AJM.db.CcurrTypeTen = text
	AJM:JambaToonRequestCurrency()
	AJM:SettingsRefresh()
end

function AJM:LabelBoxChangedCurrencyTypeTenName( event, text )
	AJM.db.CcurrTypeTenName = text
	AJM:SettingsRefresh()
end
]]


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
		--Changed Text
		AJM.db.currTypeOne = settings.currTypeOne
		AJM.db.CcurrTypeOne = settings.CcurrTypeOne
		AJM.db.CcurrTypeOneName = settings.CcurrTypeOneName
		
		AJM.db.currTypeTwo = settings.currTypeTwo
		AJM.db.CcurrTypeTwo = settings.CcurrTypeTwo
		AJM.db.CcurrTypeTwoName = settings.CcurrTypeTwoName
		
		AJM.db.currTypeThree = settings.currTypeThree
		AJM.db.CcurrTypeThree = settings.CcurrTypeThree
		AJM.db.CcurrTypeThreeName = settings.CcurrTypeThreeName
		
		AJM.db.currTypeFour = settings.currTypeFour
		AJM.db.CcurrTypeFour = settings.CcurrTypeFour
		AJM.db.CcurrTypeFourName = settings.CcurrTypeFourName
		
		AJM.db.currTypeFive = settings.currTypeFive
		AJM.db.CcurrTypeFive = settings.CcurrTypeFive
		AJM.db.CcurrTypeFiveName = settings.CcurrTypeFiveName
		
		AJM.db.currTypeSix = settings.currTypeSix
		AJM.db.CcurrTypeSix = settings.CcurrTypeSix
		AJM.db.CcurrTypeSixName = settings.CcurrTypeSixName
		
		--[[ Extra If needed for Some other Use Ebony
		AJM.db.currTypeSeven = settings.currTypeSeven
		AJM.db.CcurrTypeSeven = settings.CcurrTypeSeven
		AJM.db.CcurrTypeSevenName = settings.CcurrTypeSevenName
		
		AJM.db.currTypeEight = settings.currTypeEight
		AJM.db.CcurrTypeEight = settings.CcurrTypeEight
		AJM.db.CcurrTypeEightName = settings.CcurrTypeEightName
		
		AJM.db.currTypeNine = settings.currTypeNine
		AJM.db.CcurrTypeNine = settings.CcurrTypeNine
		AJM.db.CcurrTypeNineName = settings.CcurrTypeNineName
		
		AJM.db.currTypeTen = settings.currTypeTen
		AJM.db.CcurrTypeTen = settings.CcurrTypeTen
		AJM.db.CcurrTypeTenName = settings.CcurrTypeTenName
		]]
		
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
	--[[ Extra If Ever Neeeded for some Reason <Ebony>
	-- Set the TypeSeven font string.
	local frameTypeSeven = AJM.globalCurrencyFramePrefix.."TitleTypeSeven"
	local frameTypeSevenText = parentFrame:CreateFontString( frameTypeSeven.."Text", "OVERLAY", "GameFontNormal" )
	frameTypeSevenText:SetText( L["CurrSeven"] )
	frameTypeSevenText:SetTextColor( r, g, b, a )
	frameTypeSevenText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, top )
	frameTypeSevenText:SetWidth( width )
	frameTypeSevenText:SetJustifyH( "CENTER" )
	frame.TypeSevenText = frameTypeSevenText
	left = left + spacing
	-- Set the Eight font string.
	local frameTypeEight = AJM.globalCurrencyFramePrefix.."TiteTypeEight"
	local frameTypeEightText = parentFrame:CreateFontString( frameTypeEight.."Text", "OVERLAY", "GameFontNormal" )
	frameTypeEightText:SetText( L["CurrEight"] )
	frameTypeEightText:SetTextColor( r, g, b, a )
	frameTypeEightText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, top )
	frameTypeEightText:SetWidth( width )
	frameTypeEightText:SetJustifyH( "CENTER" )
	frame.TypeEightText = frameTypeEightText
	left = left + spacing
	-- Set the Nine font string.
	local frameTypeNine = AJM.globalCurrencyFramePrefix.."TitleTypeEight"
	local frameTypeNineText = parentFrame:CreateFontString( frameTypeEight.."Text", "OVERLAY", "GameFontNormal" )
	frameTypeNineText:SetText( L["CurrNine"] )
	frameTypeNineText:SetTextColor( r, g, b, a )
	frameTypeNineText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, top )
	frameTypeNineText:SetWidth( width )
	frameTypeNineText:SetJustifyH( "CENTER" )
	frame.TypeNineText = frameTypeNineText
	left = left + spacing
	-- Set the Ten font string.
	local frameTypeTen = AJM.globalCurrencyFramePrefix.."TitleTypeTen"
	local frameTypeTenText = parentFrame:CreateFontString( frameTypeTen.."Text", "OVERLAY", "GameFontNormal" )
	frameTypeTenText:SetText( L["CurrTen"] )
	frameTypeTenText:SetTextColor( r, g, b, a )
	frameTypeTenText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, top )
	frameTypeTenText:SetWidth( width )
	frameTypeTenText:SetJustifyH( "CENTER" )
	frame.TypeTenText = frameTypeTenText
	left = left + spacing
	]]
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
	JambaToonCurrencyListFrame:Hide()
	AJM.currencyListFrameCreated = true
	AJM:UpdateHendingText()
	AJM:CurrencyListSetHeight()
end

function AJM:UpdateHendingText()
	local parentFrame = JambaToonCurrencyListFrame
	-- Type One
	local name, amount, icon, earnedThisWeek, weeklyMax, totalMax, isDiscovered = GetCurrencyInfo( AJM.db.CcurrTypeOne )
	if name then
	Name = string.gsub(name, "%l+%s*", "" ) 
		local iconTextureString = strconcat(" |T"..icon..":20|t")
		local iconTextureStringFull = strconcat(" |T"..icon..":20|t", L[" "]..name)
		AJM.db.CcurrTypeOneName = iconTextureStringFull
		parentFrame.TypeOneText:SetText( iconTextureString )
	else 
		return
	end
	-- Type Two
	local name, amount, icon, earnedThisWeek, weeklyMax, totalMax, isDiscovered = GetCurrencyInfo( AJM.db.CcurrTypeTwo )
	Name = string.gsub(name, "%l+%s*", "" ) 
	local iconTextureString = strconcat(" |T"..icon..":20|t")
	local iconTextureStringFull = strconcat(" |T"..icon..":20|t", L[" "]..name)
	AJM.db.CcurrTypeTwoName = iconTextureStringFull
	parentFrame.TypeTwoText:SetText( iconTextureString )
	-- Type Two
	local name, amount, icon, earnedThisWeek, weeklyMax, totalMax, isDiscovered = GetCurrencyInfo( AJM.db.CcurrTypeTwo )
	Name = string.gsub(name, "%l+%s*", "" ) 
	local iconTextureString = strconcat(" |T"..icon..":20|t")
	local iconTextureStringFull = strconcat(" |T"..icon..":20|t", L[" "]..name)
	AJM.db.CcurrTypeTwoName = iconTextureStringFull
	parentFrame.TypeTwoText:SetText( iconTextureString )
	-- Type Three
	local name, amount, icon, earnedThisWeek, weeklyMax, totalMax, isDiscovered = GetCurrencyInfo( AJM.db.CcurrTypeThree )
	Name = string.gsub(name, "%l+%s*", "" ) 
	local iconTextureString = strconcat(" |T"..icon..":20|t")
	local iconTextureStringFull = strconcat(" |T"..icon..":20|t", L[" "]..name)
	AJM.db.CcurrTypeThreeName = iconTextureStringFull
	parentFrame.TypeThreeText:SetText( iconTextureString )	
	-- Type Four
	local name, amount, icon, earnedThisWeek, weeklyMax, totalMax, isDiscovered = GetCurrencyInfo( AJM.db.CcurrTypeFour )
	Name = string.gsub(name, "%l+%s*", "" ) 
	local iconTextureString = strconcat(" |T"..icon..":20|t")
	local iconTextureStringFull = strconcat(" |T"..icon..":20|t", L[" "]..name)
	AJM.db.CcurrTypeFourName = iconTextureStringFull
	parentFrame.TypeFourText:SetText( iconTextureString ) 	
	-- Type Five
	local name, amount, icon, earnedThisWeek, weeklyMax, totalMax, isDiscovered = GetCurrencyInfo( AJM.db.CcurrTypeFive )
	Name = string.gsub(name, "%l+%s*", "" ) 
	local iconTextureString = strconcat(" |T"..icon..":20|t")
	local iconTextureStringFull = strconcat(" |T"..icon..":20|t", L[" "]..name)
	AJM.db.CcurrTypeFiveName = iconTextureStringFull
	parentFrame.TypeFiveText:SetText( iconTextureString )
	-- Type six
	local name, amount, icon, earnedThisWeek, weeklyMax, totalMax, isDiscovered = GetCurrencyInfo( AJM.db.CcurrTypeSix )
	Name = string.gsub(name, "%l+%s*", "" ) 
	local iconTextureString = strconcat(" |T"..icon..":20|t")
	local iconTextureStringFull = strconcat(" |T"..icon..":20|t", L[" "]..name)
	AJM.db.CcurrTypeSixName = iconTextureStringFull
	parentFrame.TypeSixText:SetText( iconTextureString )
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
	if AJM.db.currTypeOne == true then
		parentFrame.TypeOneText:SetWidth( pointsWidth )
		parentFrame.TypeOneText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, headingRowTopPoint )
		left = left + pointsWidth + spacingWidth
		numberOfPointsColumns = numberOfPointsColumns + 1
		parentFrame.TypeOneText:Show()
	else
		parentFrame.TypeOneText:Hide()
	end
	if AJM.db.currTypeTwo == true then
		parentFrame.TypeTwoText:SetWidth( pointsWidth )
		parentFrame.TypeTwoText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, headingRowTopPoint )
		left = left + pointsWidth + spacingWidth
		numberOfPointsColumns = numberOfPointsColumns + 1
		parentFrame.TypeTwoText:Show()
	else
		parentFrame.TypeTwoText:Hide()
	end
	if AJM.db.currTypeThree == true then
		parentFrame.TypeThreeText:SetWidth( pointsWidth )
		parentFrame.TypeThreeText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, headingRowTopPoint )
		left = left + pointsWidth + spacingWidth
		numberOfPointsColumns = numberOfPointsColumns + 1
		parentFrame.TypeThreeText:Show()
	else
		parentFrame.TypeThreeText:Hide()
	end	
	if AJM.db.currTypeFour == true then
		parentFrame.TypeFourText:SetWidth( pointsWidth )
		parentFrame.TypeFourText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, headingRowTopPoint )
		left = left + pointsWidth + spacingWidth
		numberOfPointsColumns = numberOfPointsColumns + 1
		parentFrame.TypeFourText:Show()
	else
		parentFrame.TypeFourText:Hide()
	end
	if AJM.db.currTypeFive == true then
		parentFrame.TypeFiveText:SetWidth( pointsWidth )
		parentFrame.TypeFiveText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, headingRowTopPoint )
		left = left + pointsWidth + spacingWidth
		numberOfPointsColumns = numberOfPointsColumns + 1
		parentFrame.TypeFiveText:Show()
	else
		parentFrame.TypeFiveText:Hide()
	end
		if AJM.db.currTypeSix == true then
		parentFrame.TypeSixText:SetWidth( pointsWidth )
		parentFrame.TypeSixText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, headingRowTopPoint )
		left = left + pointsWidth + spacingWidth
		numberOfPointsColumns = numberOfPointsColumns + 1
		parentFrame.TypeSixText:Show()
	else
		parentFrame.TypeSixText:Hide()
	end
--[[ Extra Space if needed
	if AJM.db.currTypeSeven == true then
		parentFrame.TypeSevenText:SetWidth( pointsWidth )
		parentFrame.TypeSevenText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, headingRowTopPoint )
		left = left + pointsWidth + spacingWidth
		numberOfPointsColumns = numberOfPointsColumns + 1
		parentFrame.TypeSevenText:Show()
	else
		parentFrame.TypeSevenText:Hide()
	end
	if AJM.db.currTypeEight == true then
		parentFrame.TypeEightText:SetWidth( pointsWidth )
		parentFrame.TypeEightText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, headingRowTopPoint )
		left = left + pointsWidth + spacingWidth
		numberOfPointsColumns = numberOfPointsColumns + 1
		parentFrame.TypeEightText:Show()
	else
		parentFrame.TypeEightText:Hide()
	end
	if AJM.db.currTypeNine == true then
		parentFrame.TypeNineText:SetWidth( pointsWidth )
		parentFrame.TypeNineText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, headingRowTopPoint )
		left = left + pointsWidth + spacingWidth
		numberOfPointsColumns = numberOfPointsColumns + 1
		parentFrame.TypeNineText:Show()
	else
		parentFrame.TypeNineText:Hide()
	end
	if AJM.db.currTypeTen == true then
		parentFrame.TypeTenText:SetWidth( pointsWidth )
		parentFrame.TypeTenText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, headingRowTopPoint )
		left = left + pointsWidth + spacingWidth
		numberOfPointsColumns = numberOfPointsColumns + 1
		parentFrame.TypeTenText:Show()
	else
		parentFrame.TypeTenText:Hide()
	end ]]	
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
			if AJM.db.currTypeOne == true then
				currencyFrameCharacterInfo.TypeOneText:SetWidth( pointsWidth )
				currencyFrameCharacterInfo.TypeOneText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, characterRowTopPoint )
				left = left + pointsWidth + spacingWidth
				currencyFrameCharacterInfo.TypeOneText:Show()
			else
				currencyFrameCharacterInfo.TypeOneText:Hide()
			end
			if AJM.db.currTypeTwo == true then
				currencyFrameCharacterInfo.TypeTwoText:SetWidth( pointsWidth )
				currencyFrameCharacterInfo.TypeTwoText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, characterRowTopPoint )
				left = left + pointsWidth + spacingWidth
				currencyFrameCharacterInfo.TypeTwoText:Show()
			else
				currencyFrameCharacterInfo.TypeTwoText:Hide()
			end
			if AJM.db.currTypeThree == true then
				currencyFrameCharacterInfo.TypeThreeText:SetWidth( pointsWidth )
				currencyFrameCharacterInfo.TypeThreeText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, characterRowTopPoint )
				left = left + pointsWidth + spacingWidth
				currencyFrameCharacterInfo.TypeThreeText:Show()
			else
				currencyFrameCharacterInfo.TypeThreeText:Hide()
			end		
			if AJM.db.currTypeFour == true then
				currencyFrameCharacterInfo.TypeFourText:SetWidth( pointsWidth )
				currencyFrameCharacterInfo.TypeFourText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, characterRowTopPoint )
				left = left + pointsWidth + spacingWidth
				currencyFrameCharacterInfo.TypeFourText:Show()
			else
				currencyFrameCharacterInfo.TypeFourText:Hide()
			end
			if AJM.db.currTypeFive == true then
				currencyFrameCharacterInfo.TypeFiveText:SetWidth( pointsWidth )
				currencyFrameCharacterInfo.TypeFiveText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, characterRowTopPoint )
				left = left + pointsWidth + spacingWidth
				currencyFrameCharacterInfo.TypeFiveText:Show()
			else
				currencyFrameCharacterInfo.TypeFiveText:Hide()
			end
			if AJM.db.currTypeSix == true then
				currencyFrameCharacterInfo.TypeSixText:SetWidth( pointsWidth )
				currencyFrameCharacterInfo.TypeSixText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, characterRowTopPoint )
				left = left + pointsWidth + spacingWidth
				currencyFrameCharacterInfo.TypeSixText:Show()
			else
				currencyFrameCharacterInfo.TypeSixText:Hide()
			end		
	--[[	
			if AJM.db.currTypeSeven == true then
				currencyFrameCharacterInfo.TypeSevenText:SetWidth( pointsWidth )
				currencyFrameCharacterInfo.TypeSevenText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, characterRowTopPoint )
				left = left + pointsWidth + spacingWidth
				currencyFrameCharacterInfo.TypeSevenText:Show()
			else
				currencyFrameCharacterInfo.TypeSevenText:Hide()
			end
			if AJM.db.currTypeEight == true then
				currencyFrameCharacterInfo.TypeEightText:SetWidth( pointsWidth )
				currencyFrameCharacterInfo.TypeEightText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, characterRowTopPoint )
				left = left + pointsWidth + spacingWidth
				currencyFrameCharacterInfo.TypeEightText:Show()
			else
				currencyFrameCharacterInfo.TypeEightText:Hide()
			end		
			if AJM.db.currTypeNine == true then
				currencyFrameCharacterInfo.TypeNineText:SetWidth( pointsWidth )
				currencyFrameCharacterInfo.TypeNineText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, characterRowTopPoint )
				left = left + pointsWidth + spacingWidth
				currencyFrameCharacterInfo.TypeNineText:Show()
			else
				currencyFrameCharacterInfo.TypeNineText:Hide()
			end
			if AJM.db.currTypeTen == true then
				currencyFrameCharacterInfo.TypeTenText:SetWidth( pointsWidth )
				currencyFrameCharacterInfo.TypeTenText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, characterRowTopPoint )
				left = left + pointsWidth + spacingWidth
				currencyFrameCharacterInfo.TypeTenText:Show()
			else
				currencyFrameCharacterInfo.TypeTenText:Hide()
			end ]]
		else
			
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
	--if JambaPrivate.Team.GetCharacterOnlineStatus (characterName) == true then
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
--[[ More Space if needed
	-- Set the TypeSeven font string.
	local frameTypeSeven = AJM.globalCurrencyFramePrefix.."TypeSeven"
	local frameTypeSevenText = parentFrame:CreateFontString( frameTypeSeven.."Text", "OVERLAY", "GameFontNormal" )
	frameTypeSevenText:SetText( "0" )
	frameTypeSevenText:SetTextColor( 1.00, 1.00, 1.00, 1.00 )
	frameTypeSevenText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, top )
	frameTypeSevenText:SetWidth( width )
	frameTypeSevenText:SetJustifyH( "CENTER" )
	currencyFrameCharacterInfo.TypeSevenText = frameTypeSevenText
	left = left + spacing
	-- Set the TypeEight font string.
	local frameTypeEight = AJM.globalCurrencyFramePrefix.."TypeEight"
	local frameTypeEightText = parentFrame:CreateFontString( frameTypeEight.."Text", "OVERLAY", "GameFontNormal" )
	frameTypeEightText:SetText( "0" )
	frameTypeEightText:SetTextColor( 1.00, 1.00, 1.00, 1.00 )
	frameTypeEightText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, top )
	frameTypeEightText:SetWidth( width )
	frameTypeEightText:SetJustifyH( "CENTER" )
	currencyFrameCharacterInfo.TypeEightText = frameTypeEightText
	left = left + spacing
	-- Set the TypeNine font string.
	local frameTypeNine = AJM.globalCurrencyFramePrefix.."TypeNine"
	local frameTypeNineText = parentFrame:CreateFontString( frameTypeNine.."Text", "OVERLAY", "GameFontNormal" )
	frameTypeNineText:SetText( "0" )
	frameTypeNineText:SetTextColor( 1.00, 1.00, 1.00, 1.00 )
	frameTypeNineText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, top )
	frameTypeNineText:SetWidth( width )
	frameTypeNineText:SetJustifyH( "CENTER" )
	currencyFrameCharacterInfo.TypeNineText = frameTypeNineText
	left = left + spacing
	-- Set the TypeTen font string.
	local frameTypeTen = AJM.globalCurrencyFramePrefix.."TypeTen"
	local frameTypeTenText = parentFrame:CreateFontString( frameTypeTen.."Text", "OVERLAY", "GameFontNormal" )
	frameTypeTenText:SetText( "0" )
	frameTypeTenText:SetTextColor( 1.00, 1.00, 1.00, 1.00 )
	frameTypeTenText:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", left, top )
	frameTypeTenText:SetWidth( width )
	frameTypeTenText:SetJustifyH( "CENTER" )
	currencyFrameCharacterInfo.TypeTenText = frameTypeTenText
	left = left + spacing
]]


	--end
end

function AJM:JambaToonHideCurrency()
	JambaToonCurrencyListFrame:Hide()
end

function AJM:JambaToonRequestCurrency()
	-- Colour red.
	local r = 1.0
	local g = 0.0
	local b = 0.0
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
			--[[
			currencyFrameCharacterInfo.TypeSevenText:Hide()
			currencyFrameCharacterInfo.TypeEightText:Hide()
			currencyFrameCharacterInfo.TypeNineText:Hide()
			currencyFrameCharacterInfo.TypeTenText:Hide()
			]]
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
			--[[currencyFrameCharacterInfo.TypeSevenText:SetTextColor( r, g, b, a )
			currencyFrameCharacterInfo.TypeEightText:SetTextColor( r, g, b, a )
			currencyFrameCharacterInfo.TypeNineText:SetTextColor( r, g, b, a )
			currencyFrameCharacterInfo.TypeTenText:SetTextColor( r, g, b, a )
			]]
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
--	AJM.currentCurrencyValues.currTypeSeven = select( 2, GetCurrencyInfo( AJM.db.CcurrTypeSeven ) )	
--	AJM.currentCurrencyValues.currTypeEight = select( 2, GetCurrencyInfo( AJM.db.CcurrTypeEight ) )
--	AJM.currentCurrencyValues.currTypeNine = select( 2, GetCurrencyInfo( AJM.db.CcurrTypeNine ) )
--	AJM.currentCurrencyValues.currTypeTen = select( 2, GetCurrencyInfo( AJM.db.CcurrTypeTen ) )
	AJM:JambaSendCommandToToon( characterName, AJM.COMMAND_HERE_IS_CURRENCY, AJM.currentCurrencyValues )
	else
		return
	end
end

function AJM:DoShowToonsCurrency( characterName, currencyValues )
	--AJM.Print("DoShowCurrency", characterName, currencyValues.currTypeOne )
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
	currencyFrameCharacterInfo.GoldText:SetTextColor( r, g, b, a )
	currencyFrameCharacterInfo.characterNameText:SetTextColor( r, g, b, a )
	currencyFrameCharacterInfo.TypeOneText:SetTextColor( r, g, b, a )
	currencyFrameCharacterInfo.TypeTwoText:SetTextColor( r, g, b, a )
	currencyFrameCharacterInfo.TypeThreeText:SetTextColor( r, g, b, a )
	currencyFrameCharacterInfo.TypeFourText:SetTextColor( r, g, b, a )
	currencyFrameCharacterInfo.TypeFiveText:SetTextColor( r, g, b, a )
	currencyFrameCharacterInfo.TypeSixText:SetTextColor( r, g, b, a )
--[[	
	currencyFrameCharacterInfo.TypeSevenText:SetTextColor( r, g, b, a )
	currencyFrameCharacterInfo.TypeEightText:SetTextColor( r, g, b, a )
	currencyFrameCharacterInfo.TypeNineText:SetTextColor( r, g, b, a )
	currencyFrameCharacterInfo.TypeTenText:SetTextColor( r, g, b, a )
]]
	--currencyFrameCharacterInfo.GoldText:SetText( JambaUtilities:FormatMoneyString( currencyValues.currGold ) )
	currencyFrameCharacterInfo.GoldText:SetText( GetCoinTextureString( currencyValues.currGold ) )
	currencyFrameCharacterInfo.TypeOneText:SetText( currencyValues.currTypeOne )
	currencyFrameCharacterInfo.TypeTwoText:SetText( currencyValues.currTypeTwo )
	currencyFrameCharacterInfo.TypeThreeText:SetText( currencyValues.currTypeThree )	
	currencyFrameCharacterInfo.TypeFourText:SetText( currencyValues.currTypeFour )
	currencyFrameCharacterInfo.TypeFiveText:SetText( currencyValues.currTypeFive )
	currencyFrameCharacterInfo.TypeSixText:SetText( currencyValues.currTypeSix )
--[[	
currencyFrameCharacterInfo.TypeSevenText:SetText( currencyValues.currTypeSeven )
	currencyFrameCharacterInfo.TypeEightText:SetText( currencyValues.currTypeEight )
	currencyFrameCharacterInfo.TypeNineText:SetText( currencyValues.currTypeNine )
	currencyFrameCharacterInfo.TypeTenText:SetText( currencyValues.currTypeTen )
]]
	-- Total gold.
	AJM.currencyTotalGold = AJM.currencyTotalGold + currencyValues.currGold
	--parentFrame.TotalGoldText:SetText( JambaUtilities:FormatMoneyString( AJM.currencyTotalGold ) )
	parentFrame.TotalGoldText:SetText( GetCoinTextureString( AJM.currencyTotalGold ) )
	if IsInGuild() then
		--parentFrame.TotalGoldGuildText:SetText( JambaUtilities:FormatMoneyString( GetGuildBankMoney() ) )
		parentFrame.TotalGoldGuildText:SetText( GetCoinTextureString( GetGuildBankMoney() ) )
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