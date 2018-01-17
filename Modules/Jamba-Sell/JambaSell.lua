--[[
Jamba - Jafula's Awesome Multi-Boxer Assistant
Copyright 2008 - 2018 Michael "Jafula" Miller
License: The MIT License
]]--

-- Create the addon using AceAddon-3.0 and embed some libraries.
local AJM = LibStub( "AceAddon-3.0" ):NewAddon( 
	"JambaSell", 
	"JambaModule-1.0", 
	"AceConsole-3.0", 
	"AceEvent-3.0",
	"AceHook-3.0",
	"AceTimer-3.0"
)

-- Load libraries.
local JambaUtilities = LibStub:GetLibrary( "JambaUtilities-1.0" )
local JambaHelperSettings = LibStub:GetLibrary( "JambaHelperSettings-1.0" )
local AceGUI = LibStub:GetLibrary( "AceGUI-3.0" )
local LibBagUtils = LibStub:GetLibrary( "LibBagUtils-1.0" )
local LibItemUtilsJamba = LibStub:GetLibrary( "LibItemUtilsJamba-1.0" )
local ItemUpgradeInfo = LibStub("LibItemUpgradeInfo-1.0")

--  Constants and Locale for this module.
AJM.moduleName = "Jamba-Sell"
AJM.settingsDatabaseName = "JambaSellProfileDB"
AJM.chatCommand = "jamba-sell"
local L = LibStub( "AceLocale-3.0" ):GetLocale( AJM.moduleName )
AJM.parentDisplayName = L["Merchant"]
AJM.moduleDisplayName = L["Sell"]


-- Settings - the values to store and their defaults for the settings database.
AJM.settings = {
	profile = {
		sellItemOnAllWithAltKey = false,
	
		--TODO REMOVE
	--	autoSellPoorItems = false,
	--	autoSellPoorItemsHaveExceptions = false,
	--	autoSellPoorItemsExceptionList = {},
		
		-- Other Items
		autoSellOtherItems = false,
		autoSellOtherItemsList = {},
		messageArea = JambaApi.DefaultMessageArea(),
		autoSellItem = false,
		-- Gray
		autoSellPoor = false,
		autoSellBoEPoor	=  false,
		-- Green	
		autoSellUncommon = false,
		autoSellIlvlUncommon = 0,
		autoSellBoEUncommon	= false,
		-- Rare
		autoSellRare = false,
		autoSellIlvlRare = 0,
		autoSellBoERare	=  false,
		-- Epic
		autoSellEpic = false,
		autoSellIlvlEpic = 0,
		autoSellBoEEpic	=  false,		
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
				desc = L["Push the sell settings to all characters in the team."],
				usage = "/jamba-sell push",
				get = false,
				set = "JambaSendSettings",
			},
		},
	}
	return configuration
end

-------------------------------------------------------------------------------------------------------------
-- Command this module sends.
-------------------------------------------------------------------------------------------------------------

AJM.COMMAND_SELL_ITEM = "SellItem"

-------------------------------------------------------------------------------------------------------------
-- Messages module sends.
-------------------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------------------------
-- Sell Management.
-------------------------------------------------------------------------------------------------------------

AJM.BAG_PLAYER_BACKPACK = 0
-- NUM_BAG_SLOTS is defined as 4 in Blizzard's FrameXML\BankFrame.lua.
AJM.BAG_PLAYER_MAXIMUM = NUM_BAG_SLOTS
-- Store ItemQuality https://wow.gamepedia.com/API_TYPE_Quality
AJM.ITEM_QUALITY_POOR = 0
AJM.ITEM_QUALITY_COMMON = 1
AJM.ITEM_QUALITY_UNCOMMON = 2
AJM.ITEM_QUALITY_RARE = 3
AJM.ITEM_QUALITY_EPIC = 4
AJM.ITEM_QUALITY_LEGENDARY = 5
AJM.ITEM_QUALITY_ARTIFACT = 6
AJM.ITEM_QUALITY_HEIRLOOM = 7
AJM.MIN_ITEM_LEVEL = 10

function AJM:BeforeJambaProfileChanged()	
end

function AJM:OnJambaProfileChanged()	
	AJM:SettingsRefresh()
end

function AJM:SettingsRefresh()
	-- Sell on all with alt key.
	AJM.settingsControl.checkBoxSellItemOnAllWithAltKey:SetValue( AJM.db.sellItemOnAllWithAltKey )
	-- Auto sell Quality and Ilvl items.
	AJM.settingsControl.checkBoxAutoSellItems:SetValue( AJM.db.autoSellItem )
	-- Poor
	AJM.settingsControl.checkBoxAutoSellPoor:SetValue ( AJM.db.autoSellPoor )
	AJM.settingsControl.checkBoxAutoSellBoEPoor:SetValue ( AJM.db.autoSellBoEPoor )
	AJM.settingsControl.checkBoxAutoSellPoor:SetDisabled ( not AJM.db.autoSellItem )
	AJM.settingsControl.checkBoxAutoSellBoEPoor:SetDisabled ( not AJM.db.autoSellPoor )
	-- Uncommon
	AJM.settingsControl.checkBoxAutoSellUncommon:SetValue (AJM.db.autoSellUncommon )
	AJM.settingsControl.editBoxAutoSellIlvlUncommon:SetText (AJM.db.autoSellIlvlUncommon )
	AJM.settingsControl.checkBoxAutoSellBoEUncommon:SetValue (AJM.db.autoSellBoEUncommon )
	AJM.settingsControl.checkBoxAutoSellUncommon:SetDisabled ( not AJM.db.autoSellItem )
	AJM.settingsControl.editBoxAutoSellIlvlUncommon:SetDisabled ( not AJM.db.autoSellUncommon )
	AJM.settingsControl.checkBoxAutoSellBoEUncommon:SetDisabled ( not AJM.db.autoSellUncommon )	
	-- Rare
	AJM.settingsControl.checkBoxAutoSellRare:SetValue (AJM.db.autoSellRare )
	AJM.settingsControl.editBoxAutoSellIlvlRare:SetText (AJM.db.autoSellIlvlRare )
	AJM.settingsControl.checkBoxAutoSellBoERare:SetValue (AJM.db.autoSellBoERare )
	AJM.settingsControl.checkBoxAutoSellRare:SetDisabled ( not AJM.db.autoSellItem )
	AJM.settingsControl.editBoxAutoSellIlvlRare:SetDisabled ( not AJM.db.autoSellRare )
	AJM.settingsControl.checkBoxAutoSellBoERare:SetDisabled ( not AJM.db.autoSellRare )	
	-- Epic
	AJM.settingsControl.checkBoxAutoSellEpic:SetValue ( AJM.db.autoSellEpic )
	AJM.settingsControl.editBoxAutoSellIlvlEpic:SetText ( AJM.db.autoSellIlvlEpic)
	AJM.settingsControl.checkBoxAutoSellBoEEpic:SetValue ( AJM.db.autoSellBoEEpic )
	AJM.settingsControl.checkBoxAutoSellEpic:SetDisabled ( not AJM.db.autoSellItem )
	AJM.settingsControl.editBoxAutoSellIlvlEpic:SetDisabled ( not AJM.db.autoSellEpic )
	AJM.settingsControl.checkBoxAutoSellBoEEpic:SetDisabled ( not AJM.db.autoSellEpic )		
	-- Messages.
	AJM.settingsControl.dropdownMessageArea:SetValue( AJM.db.messageArea )
	-- Greys.

--[[
	AJM.settingsControlGreys.checkBoxAutoSellPoorItems:SetValue( AJM.db.autoSellPoorItems )
	AJM.settingsControlGreys.checkBoxAutoSellPoorItemsHaveExceptions:SetValue( AJM.db.autoSellPoorItemsHaveExceptions )
	AJM.settingsControlGreys.greysEditBoxExceptionTag:SetText( AJM.autoSellPoorItemExceptionTag )
	AJM.settingsControlGreys.checkBoxAutoSellPoorItemsHaveExceptions:SetDisabled( not AJM.db.autoSellPoorItems )
	AJM.settingsControlGreys.greysEditBoxExceptionItem:SetDisabled( not AJM.db.autoSellPoorItems or not AJM.db.autoSellPoorItemsHaveExceptions )
	AJM.settingsControlGreys.greysEditBoxExceptionTag:SetDisabled( not AJM.db.autoSellPoorItems or not AJM.db.autoSellPoorItemsHaveExceptions )
	AJM.settingsControlGreys.greysButtonRemove:SetDisabled( not AJM.db.autoSellPoorItems or not AJM.db.autoSellPoorItemsHaveExceptions )
	AJM.settingsControlGreys.greysButtonAdd:SetDisabled( not AJM.db.autoSellPoorItems or not AJM.db.autoSellPoorItemsHaveExceptions )
]]
	-- Others. 
	AJM.settingsControlOthers.checkBoxAutoSellOtherItems:SetValue( AJM.db.autoSellOtherItems )
	AJM.settingsControlOthers.othersEditBoxOtherTag:SetText( AJM.autoSellOtherItemTag )
	AJM.settingsControlOthers.othersEditBoxOtherItem:SetDisabled( not AJM.db.autoSellOtherItems )
	AJM.settingsControlOthers.othersEditBoxOtherTag:SetDisabled( not AJM.db.autoSellOtherItems )
	AJM.settingsControlOthers.othersButtonRemove:SetDisabled( not AJM.db.autoSellOtherItems )
	AJM.settingsControlOthers.othersButtonAdd:SetDisabled( not AJM.db.autoSellOtherItems )
--	AJM:SettingsGreysScrollRefresh()
	AJM:SettingsOthersScrollRefresh()
end

-- Settings received.
function AJM:JambaOnSettingsReceived( characterName, settings )	
	if characterName ~= AJM.characterName then
		-- Update the settings.
		AJM.db.sellItemOnAllWithAltKey = settings.sellItemOnAllWithAltKey
		AJM.db.autoSellItem = settings.autoSellItem
		AJM.db.autoSellPoor = settings.autoSellPoor
		AJM.db.autoSellBoEPoor = settings.autoSellBoEPoor
		AJM.db.autoSellUncommon = settings.autoSellUncommon
		AJM.db.autoSellIlvlUncommon = settings.autoSellIlvlUncommon
		AJM.db.autoSellBoEUncommon = settings.autoSellBoEUncommon
		AJM.db.autoSellRare = settings.autoSellRare
		AJM.db.autoSellIlvlRare = settings.autoSellIlvlRare
		AJM.db.autoSellBoERare = settings.autoSellBoERare
		AJM.db.autoSellEpic = settings.autoSellEpic
		AJM.db.autoSellIlvlEpic = settings.autoSellIlvlEpic
		AJM.db.autoSellBoEEpic = settings.autoSellBoEEpic
	--	AJM.db.autoSellPoorItems = settings.autoSellPoorItems
	--	AJM.db.autoSellPoorItemsHaveExceptions = settings.autoSellPoorItemsHaveExceptions 
		AJM.db.autoSellOtherItems = settings.autoSellOtherItems
		AJM.db.messageArea = settings.messageArea
--		AJM.db.autoSellPoorItemsExceptionList = JambaUtilities:CopyTable( settings.autoSellPoorItemsExceptionList )
		AJM.db.autoSellOtherItemsList = JambaUtilities:CopyTable( settings.autoSellOtherItemsList )
		-- Refresh the settings.
		AJM:SettingsRefresh()
		-- Tell the player.
		AJM:Print( L["Settings received from A."]( characterName ) )
		-- Tell the team?
		--AJM:JambaSendMessageToTeam( AJM.db.messageArea,  L["Settings received from A."]( characterName ), false )
	end
end


-------------------------------------------------------------------------------------------------------------
-- Settings Dialogs.
-------------------------------------------------------------------------------------------------------------

local function SettingsCreateMain( top )
	-- Position and size constants.
	local buttonControlWidth = 105
	local checkBoxHeight = JambaHelperSettings:GetCheckBoxHeight()
	local buttonHeight = JambaHelperSettings:GetButtonHeight()
	local editBoxHeight = JambaHelperSettings:GetEditBoxHeight()
	local dropdownHeight = JambaHelperSettings:GetDropdownHeight()
	local left = JambaHelperSettings:LeftOfSettings()
	local headingHeight = JambaHelperSettings:HeadingHeight()
	local headingWidth = JambaHelperSettings:HeadingWidth( false )
	local horizontalSpacing = JambaHelperSettings:GetHorizontalSpacing()
	local indent = horizontalSpacing * 12
	local verticalSpacing = JambaHelperSettings:GetVerticalSpacing()
	local halfWidth = (headingWidth - horizontalSpacing) / 2
	local thirdWidth = (headingWidth - (horizontalSpacing * 5)) / 5
	local left2 = left + thirdWidth
	local left3 = left + halfWidth
	local movingTop = top
	JambaHelperSettings:CreateHeading( AJM.settingsControl, L["Sell Item On All Toons"], movingTop, false )
	movingTop = movingTop - headingHeight	
	AJM.settingsControl.checkBoxSellItemOnAllWithAltKey = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		left, 
		movingTop, 
		L["Hold Alt While Selling An Item To Sell On All Toons"],
		AJM.SettingsToggleSellItemOnAllWithAltKey
	)	
	movingTop = movingTop - checkBoxHeight	
	JambaHelperSettings:CreateHeading( AJM.settingsControl, L["Sell Items"], movingTop, false )
	
	movingTop = movingTop - headingHeight	
	AJM.settingsControl.checkBoxAutoSellItems = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		left, 
		movingTop, 
		L["Automatically Sell Items"],
		AJM.SettingsToggleAutoSellItems
	)	
-- Gray
	movingTop = movingTop - checkBoxHeight - 3
	AJM.settingsControl.checkBoxAutoSellPoor = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		halfWidth, 
		left,
		movingTop,
		L["Sell Gray Items"],
		AJM.SettingsToggleAutoSellPoor
	)
	AJM.settingsControl.checkBoxAutoSellBoEPoor = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		halfWidth, 
		left3,
		movingTop,
		L["Only SoulBound"],
		AJM.SettingsToggleAutoSellBoEPoor
	)
-- Green	
	movingTop = movingTop - checkBoxHeight - 3
	AJM.settingsControl.checkBoxAutoSellUncommon = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		halfWidth, 
		left,
		movingTop,
		L["Sell Green Items"],
		AJM.SettingsToggleAutoSellUncommon
	)
	AJM.settingsControl.checkBoxAutoSellBoEUncommon = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		halfWidth, 
		left3,
		movingTop,
		L["Only SoulBound"],
		AJM.SettingsToggleAutoSellBoEUncommon
	)
	movingTop = movingTop - checkBoxHeight
	AJM.settingsControl.editBoxAutoSellIlvlUncommon = JambaHelperSettings:CreateEditBox( 
		AJM.settingsControl, 
		thirdWidth, 
		left,
		movingTop,
		L["Item Level"]
	)	
	AJM.settingsControl.editBoxAutoSellIlvlUncommon:SetCallback( "OnEnterPressed", AJM.SettingsEditBoxChangedIlvlUncommon )	
-- Rare
	movingTop = movingTop - editBoxHeight - 3	
	AJM.settingsControl.checkBoxAutoSellRare = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		halfWidth, 
		left,
		movingTop,
		L["Sell Rare Items"],
		AJM.SettingsToggleAutoSellRare
	)
	AJM.settingsControl.checkBoxAutoSellBoERare = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		halfWidth, 
		left3,
		movingTop,
		L["Only SoulBound"],
		AJM.SettingsToggleAutoSellBoERare
	)
	movingTop = movingTop - checkBoxHeight
	AJM.settingsControl.editBoxAutoSellIlvlRare = JambaHelperSettings:CreateEditBox( 
		AJM.settingsControl, 
		thirdWidth, 
		left,
		movingTop,
		L["Item Level"]
	)	
	AJM.settingsControl.editBoxAutoSellIlvlRare:SetCallback( "OnEnterPressed", AJM.SettingsEditBoxChangedIlvlRare )		
-- Epic
	movingTop = movingTop - editBoxHeight - 3
	AJM.settingsControl.checkBoxAutoSellEpic = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		halfWidth, 
		left,
		movingTop,
		L["Sell Epic Items"],
		AJM.SettingsToggleAutoSellEpic
	)
	AJM.settingsControl.checkBoxAutoSellBoEEpic = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		halfWidth, 
		left3,
		movingTop,
		L["Only SoulBound"],
		AJM.SettingsToggleAutoSellBoEEpic
	)
	movingTop = movingTop - checkBoxHeight
	AJM.settingsControl.editBoxAutoSellIlvlEpic = JambaHelperSettings:CreateEditBox( 
		AJM.settingsControl, 
		thirdWidth, 
		left,
		movingTop,
		L["Item Level"]
	)	
	AJM.settingsControl.editBoxAutoSellIlvlEpic:SetCallback( "OnEnterPressed", AJM.SettingsEditBoxChangedIlvlEpic )		
	movingTop = movingTop - editBoxHeight	
	JambaHelperSettings:CreateHeading( AJM.settingsControl, L["Sell Messages"], movingTop, false )
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

--[[
local function SettingsCreateGreys( top )
	-- Position and size constants.
	local buttonControlWidth = 105
	local checkBoxHeight = JambaHelperSettings:GetCheckBoxHeight()
	local buttonHeight = JambaHelperSettings:GetButtonHeight()
	local editBoxHeight = JambaHelperSettings:GetEditBoxHeight()
	local dropdownHeight = JambaHelperSettings:GetDropdownHeight()
	local left = JambaHelperSettings:LeftOfSettings()
	local headingHeight = JambaHelperSettings:HeadingHeight()
	local headingWidth = JambaHelperSettings:HeadingWidth( false )
	local horizontalSpacing = JambaHelperSettings:GetHorizontalSpacing()
	local verticalSpacing = JambaHelperSettings:GetVerticalSpacing()
	local halfWidth = (headingWidth - horizontalSpacing) / 2
	local greysWidth = headingWidth
	local movingTop = top
	JambaHelperSettings:CreateHeading( AJM.settingsControlGreys, L["Sell Greys"], movingTop, false )
	movingTop = movingTop - headingHeight
	AJM.settingsControlGreys.checkBoxAutoSellPoorItems = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControlGreys, 
		headingWidth, 
		left, 
		movingTop, 
		L["Auto Sell Poor Quality Items"],
		AJM.SettingsToggleAutoSellPoorItems
	)	
	movingTop = movingTop - checkBoxHeight
	AJM.settingsControlGreys.checkBoxAutoSellPoorItemsHaveExceptions = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControlGreys, 
		headingWidth, 
		left, 
		movingTop, 
		L["Except For These Poor Quality Items"],
		AJM.SettingsToggleAutoSellPoorItemsHaveExceptions
	)	
	movingTop = movingTop - checkBoxHeight
	AJM.settingsControlGreys.greysHighlightRow = 1
	AJM.settingsControlGreys.greysOffset = 1
	local list = {}
	list.listFrameName = "JambaSellSettingsGreysFrame"
	list.parentFrame = AJM.settingsControlGreys.widgetSettings.content
	list.listTop = movingTop
	list.listLeft = left
	list.listWidth = greysWidth
	list.rowHeight = 20
	list.rowsToDisplay = 2
	list.columnsToDisplay = 2
	list.columnInformation = {}
	list.columnInformation[1] = {}
	list.columnInformation[1].width = 70
	list.columnInformation[1].alignment = "LEFT"
	list.columnInformation[2] = {}
	list.columnInformation[2].width = 30
	list.columnInformation[2].alignment = "LEFT"	
	list.scrollRefreshCallback = AJM.SettingsGreysScrollRefresh
	list.rowClickCallback = AJM.SettingsGreysRowClick
	AJM.settingsControlGreys.greys = list
	JambaHelperSettings:CreateScrollList( AJM.settingsControlGreys.greys )
	movingTop = movingTop - list.listHeight - verticalSpacing
	AJM.settingsControlGreys.greysButtonRemove = JambaHelperSettings:CreateButton(
		AJM.settingsControlGreys, 
		buttonControlWidth, 
		left, 
		movingTop,
		L["Remove"],
		AJM.SettingsGreysRemoveClick
	)
	movingTop = movingTop -	buttonHeight - verticalSpacing
	JambaHelperSettings:CreateHeading( AJM.settingsControlGreys, L["Add Exception"], movingTop, false )
	movingTop = movingTop - headingHeight
	AJM.settingsControlGreys.greysEditBoxExceptionItem = JambaHelperSettings:CreateEditBox( 
		AJM.settingsControlGreys,
		headingWidth,
		left,
		movingTop,
		L["Exception Item (drag item to box)"]
	)
	AJM.settingsControlGreys.greysEditBoxExceptionItem:SetCallback( "OnEnterPressed", AJM.SettingsEditBoxChangedGreyExceptionItem )
	movingTop = movingTop - editBoxHeight	
	AJM.settingsControlGreys.greysEditBoxExceptionTag = JambaHelperSettings:CreateEditBox( 
		AJM.settingsControlGreys,
		headingWidth,
		left,
		movingTop,
		L["Exception Tag"]
	)
	AJM.settingsControlGreys.greysEditBoxExceptionTag:SetCallback( "OnEnterPressed", AJM.SettingsEditBoxChangedGreyExceptionTag )
	movingTop = movingTop - editBoxHeight	
	AJM.settingsControlGreys.greysButtonAdd = JambaHelperSettings:CreateButton(	
		AJM.settingsControlGreys, 
		buttonControlWidth, 
		left, 
		movingTop, 
		L["Add"],
		AJM.SettingsGreysAddClick
	)
	movingTop = movingTop -	buttonHeight	
	return movingTop
end
]]

local function SettingsCreateOthers( top )
	-- Position and size constants.
	local buttonControlWidth = 85
	local checkBoxHeight = JambaHelperSettings:GetCheckBoxHeight()
	local buttonHeight = JambaHelperSettings:GetButtonHeight()
	local editBoxHeight = JambaHelperSettings:GetEditBoxHeight()
	local dropdownHeight = JambaHelperSettings:GetDropdownHeight()
	local left = JambaHelperSettings:LeftOfSettings()
	local headingHeight = JambaHelperSettings:HeadingHeight()
	local headingWidth = JambaHelperSettings:HeadingWidth( false )
	local horizontalSpacing = JambaHelperSettings:GetHorizontalSpacing()
	local verticalSpacing = JambaHelperSettings:GetVerticalSpacing()
	local othersWidth = headingWidth
	local movingTop = top
	JambaHelperSettings:CreateHeading( AJM.settingsControlOthers, L["Sell Others"], movingTop, false )
	movingTop = movingTop - headingHeight
	AJM.settingsControlOthers.checkBoxAutoSellOtherItems = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControlOthers, 
		headingWidth, 
		left, 
		movingTop, 
		L["Auto Sell Items"],
		AJM.SettingsToggleAutoSellOtherItems
	)	
	movingTop = movingTop - checkBoxHeight
	AJM.settingsControlOthers.othersHighlightRow = 1
	AJM.settingsControlOthers.othersOffset = 1
	local list = {}
	list.listFrameName = "JambaSellSettingsOthersFrame"
	list.parentFrame = AJM.settingsControlOthers.widgetSettings.content
	list.listTop = movingTop
	list.listLeft = left
	list.listWidth = othersWidth
	list.rowHeight = 20
	list.rowsToDisplay = 15
	list.columnsToDisplay = 2
	list.columnInformation = {}
	list.columnInformation[1] = {}
	list.columnInformation[1].width = 70
	list.columnInformation[1].alignment = "LEFT"
	list.columnInformation[2] = {}
	list.columnInformation[2].width = 30
	list.columnInformation[2].alignment = "LEFT"	
	list.scrollRefreshCallback = AJM.SettingsOthersScrollRefresh
	list.rowClickCallback = AJM.SettingsOthersRowClick
	AJM.settingsControlOthers.others = list
	JambaHelperSettings:CreateScrollList( AJM.settingsControlOthers.others )
	movingTop = movingTop - list.listHeight - verticalSpacing
	AJM.settingsControlOthers.othersButtonRemove = JambaHelperSettings:CreateButton(
		AJM.settingsControlOthers, 
		buttonControlWidth, 
		left, 
		movingTop,
		L["Remove"],
		AJM.SettingsOthersRemoveClick
	)
	movingTop = movingTop -	buttonHeight - verticalSpacing
	JambaHelperSettings:CreateHeading( AJM.settingsControlOthers, L["Add Other"], movingTop, false )
	movingTop = movingTop - headingHeight
	AJM.settingsControlOthers.othersEditBoxOtherItem = JambaHelperSettings:CreateEditBox( 
		AJM.settingsControlOthers,
		headingWidth,
		left,
		movingTop,
		L["Other Item (drag item to box)"]
	)
	AJM.settingsControlOthers.othersEditBoxOtherItem:SetCallback( "OnEnterPressed", AJM.SettingsEditBoxChangedOtherItem )
	movingTop = movingTop - editBoxHeight	
	AJM.settingsControlOthers.othersEditBoxOtherTag = JambaHelperSettings:CreateEditBox( 
		AJM.settingsControlOthers,
		headingWidth,
		left,
		movingTop,
		L["Other Tag"]
	)
	AJM.settingsControlOthers.othersEditBoxOtherTag:SetCallback( "OnEnterPressed", AJM.SettingsEditBoxChangedOtherTag )
	movingTop = movingTop - editBoxHeight	
	AJM.settingsControlOthers.othersButtonAdd = JambaHelperSettings:CreateButton(	
		AJM.settingsControlOthers, 
		buttonControlWidth, 
		left, 
		movingTop, 
		L["Add"],
		AJM.SettingsOthersAddClick
	)
	movingTop = movingTop -	buttonHeight	
	return movingTop
end

local function SettingsCreate()
	AJM.settingsControl = {}
	--AJM.settingsControlGreys = {}
	AJM.settingsControlOthers = {}
	JambaHelperSettings:CreateSettings( 
		AJM.settingsControl, 
		AJM.moduleDisplayName, 
		AJM.parentDisplayName, 
		AJM.SettingsPushSettingsClick 
	)	
--	JambaHelperSettings:CreateSettings( 
--		AJM.settingsControlGreys, 
--		L["Sell: Greys"], 
--		AJM.parentDisplayName, 
--		AJM.SettingsPushSettingsClick 
--	)
	JambaHelperSettings:CreateSettings( 
		AJM.settingsControlOthers, 
		L["Sell: Others"], 
		AJM.parentDisplayName, 
		AJM.SettingsPushSettingsClick 
	)	
	local bottomOfSell = SettingsCreateMain( JambaHelperSettings:TopOfSettings() )
	AJM.settingsControl.widgetSettings.content:SetHeight( -bottomOfSell )
--	local bottomOfGreys = SettingsCreateGreys( JambaHelperSettings:TopOfSettings() )
--	AJM.settingsControlGreys.widgetSettings.content:SetHeight( -bottomOfGreys )
	local bottomOfOthers = SettingsCreateOthers( JambaHelperSettings:TopOfSettings() )
	AJM.settingsControlOthers.widgetSettings.content:SetHeight( -bottomOfOthers )
	-- Help
	local helpTable = {}
	JambaHelperSettings:CreateHelp( AJM.settingsControl, helpTable, AJM:GetConfiguration() )		
end

-------------------------------------------------------------------------------------------------------------
-- Settings Callbacks.
-------------------------------------------------------------------------------------------------------------

--[[
function AJM:SettingsGreysScrollRefresh()
	FauxScrollFrame_Update(
		AJM.settingsControlGreys.greys.listScrollFrame, 
		AJM:GetGreysMaxPosition(),
		AJM.settingsControlGreys.greys.rowsToDisplay, 
		AJM.settingsControlGreys.greys.rowHeight
	)
	AJM.settingsControlGreys.greysOffset = FauxScrollFrame_GetOffset( AJM.settingsControlGreys.greys.listScrollFrame )
	for iterateDisplayRows = 1, AJM.settingsControlGreys.greys.rowsToDisplay do
		-- Reset.
		AJM.settingsControlGreys.greys.rows[iterateDisplayRows].columns[1].textString:SetText( "" )
		AJM.settingsControlGreys.greys.rows[iterateDisplayRows].columns[1].textString:SetTextColor( 1.0, 1.0, 1.0, 1.0 )
		AJM.settingsControlGreys.greys.rows[iterateDisplayRows].columns[2].textString:SetText( "" )
		AJM.settingsControlGreys.greys.rows[iterateDisplayRows].columns[2].textString:SetTextColor( 1.0, 1.0, 1.0, 1.0 )
		AJM.settingsControlGreys.greys.rows[iterateDisplayRows].highlight:SetColorTexture( 0.0, 0.0, 0.0, 0.0 )
		-- Get data.
		local dataRowNumber = iterateDisplayRows + AJM.settingsControlGreys.greysOffset
		if dataRowNumber <= AJM:GetGreysMaxPosition() then
			-- Put data information into columns.
			local greysInformation = AJM:GetGreyAtPosition( dataRowNumber )
			AJM.settingsControlGreys.greys.rows[iterateDisplayRows].columns[1].textString:SetText( greysInformation.name )
			AJM.settingsControlGreys.greys.rows[iterateDisplayRows].columns[2].textString:SetText( greysInformation.tag )
			-- Highlight the selected row.
			if dataRowNumber == AJM.settingsControlGreys.greysHighlightRow then
				AJM.settingsControlGreys.greys.rows[iterateDisplayRows].highlight:SetColorTexture( 1.0, 1.0, 0.0, 0.5 )
			end
		end
	end
end

function AJM:SettingsGreysRowClick( rowNumber, columnNumber )		
	if AJM.settingsControlGreys.greysOffset + rowNumber <= AJM:GetGreysMaxPosition() then
		AJM.settingsControlGreys.greysHighlightRow = AJM.settingsControlGreys.greysOffset + rowNumber
		AJM:SettingsGreysScrollRefresh()
	end
end
]]


function AJM:SettingsOthersScrollRefresh()
	FauxScrollFrame_Update(
		AJM.settingsControlOthers.others.listScrollFrame, 
		AJM:GetOthersMaxPosition(),
		AJM.settingsControlOthers.others.rowsToDisplay, 
		AJM.settingsControlOthers.others.rowHeight
	)
	AJM.settingsControlOthers.othersOffset = FauxScrollFrame_GetOffset( AJM.settingsControlOthers.others.listScrollFrame )
	for iterateDisplayRows = 1, AJM.settingsControlOthers.others.rowsToDisplay do
		-- Reset.
		AJM.settingsControlOthers.others.rows[iterateDisplayRows].columns[1].textString:SetText( "" )
		AJM.settingsControlOthers.others.rows[iterateDisplayRows].columns[1].textString:SetTextColor( 1.0, 1.0, 1.0, 1.0 )
		AJM.settingsControlOthers.others.rows[iterateDisplayRows].columns[2].textString:SetText( "" )
		AJM.settingsControlOthers.others.rows[iterateDisplayRows].columns[2].textString:SetTextColor( 1.0, 1.0, 1.0, 1.0 )		
		AJM.settingsControlOthers.others.rows[iterateDisplayRows].highlight:SetColorTexture( 0.0, 0.0, 0.0, 0.0 )
		-- Get data.
		local dataRowNumber = iterateDisplayRows + AJM.settingsControlOthers.othersOffset
		if dataRowNumber <= AJM:GetOthersMaxPosition() then
			-- Put data information into columns.
			local othersInformation = AJM:GetOtherAtPosition( dataRowNumber )
			AJM.settingsControlOthers.others.rows[iterateDisplayRows].columns[1].textString:SetText( othersInformation.name )
			AJM.settingsControlOthers.others.rows[iterateDisplayRows].columns[2].textString:SetText( othersInformation.tag )
			-- Highlight the selected row.
			if dataRowNumber == AJM.settingsControlOthers.othersHighlightRow then
				AJM.settingsControlOthers.others.rows[iterateDisplayRows].highlight:SetColorTexture( 1.0, 1.0, 0.0, 0.5 )
			end
		end
	end
end

function AJM:SettingsOthersRowClick( rowNumber, columnNumber )		
	if AJM.settingsControlOthers.othersOffset + rowNumber <= AJM:GetOthersMaxPosition() then
		AJM.settingsControlOthers.othersHighlightRow = AJM.settingsControlOthers.othersOffset + rowNumber
		AJM:SettingsOthersScrollRefresh()
	end
end

function AJM:SettingsPushSettingsClick( event )
	AJM:JambaSendSettings()
end

function AJM:SettingsToggleSellItemOnAllWithAltKey( event, checked )
	AJM.db.sellItemOnAllWithAltKey = checked
	AJM:SettingsRefresh()
end

--Here

function AJM:SettingsToggleAutoSellItems( event, checked )
	AJM.db.autoSellItem = checked
	AJM:SettingsRefresh()
end	

--  Poor
function AJM:SettingsToggleAutoSellPoor( event, checked )
	AJM.db.autoSellPoor = checked
	AJM:SettingsRefresh()
end	


function AJM:SettingsToggleAutoSellBoEPoor( event, checked )
	AJM.db.autoSellBoEPoor = checked
	AJM:SettingsRefresh()
end	

-- Uncommon

function AJM:SettingsToggleAutoSellUncommon( event, checked )
	AJM.db.autoSellUncommon = checked
	AJM:SettingsRefresh()
end	

function AJM:SettingsEditBoxChangedIlvlUncommon( event, text )
	AJM.db.autoSellIlvlUncommon = text
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleAutoSellBoEUncommon( event, checked )
	AJM.db.autoSellBoEUncommon = checked
	AJM:SettingsRefresh()
end

-- Rare

function AJM:SettingsToggleAutoSellRare( event, checked )
	AJM.db.autoSellRare = checked
	AJM:SettingsRefresh()
end	

function AJM:SettingsEditBoxChangedIlvlRare( event, text )
	AJM.db.autoSellIlvlRare = text
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleAutoSellBoERare( event, checked )
	AJM.db.autoSellBoERare = checked
	AJM:SettingsRefresh()
end

-- Epic

function AJM:SettingsToggleAutoSellEpic( event, checked )
	AJM.db.autoSellEpic = checked
	AJM:SettingsRefresh()
end	

function AJM:SettingsEditBoxChangedIlvlEpic( event, text )
	AJM.db.autoSellIlvlEpic = text
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleAutoSellBoEEpic( event, checked )
	AJM.db.autoSellBoEEpic = checked
	AJM:SettingsRefresh()
end


function AJM:SettingsSetMessageArea( event, value )
	AJM.db.messageArea = value
	AJM:SettingsRefresh()
end


--TPDO Remove!
--[[ 
function AJM:SettingsToggleAutoSellPoorItems( event, checked )
	AJM.db.autoSellPoorItems = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleAutoSellPoorItemsHaveExceptions( event, checked )
	AJM.db.autoSellPoorItemsHaveExceptions = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsGreysRemoveClick( event )
	StaticPopup_Show( "JAMBASELL_CONFIRM_REMOVE_AUTO_SELL_POOR_ITEMS_EXCEPTION" )
end

function AJM:SettingsEditBoxChangedGreyExceptionItem( event, text )
	AJM.autoSellPoorItemExceptionLink = text
	AJM:SettingsRefresh()
end

function AJM:SettingsEditBoxChangedGreyExceptionTag( event, text )
	if not text or text:trim() == "" or text:find( "%W" ) ~= nil then
		AJM:Print( L["Item tags must only be made up of letters and numbers."] )
		return
	end
	AJM.autoSellPoorItemExceptionTag = text
	AJM:SettingsRefresh()
end

function AJM:SettingsGreysAddClick( event )
	if AJM.autoSellPoorItemExceptionLink ~= nil and AJM.autoSellPoorItemExceptionTag ~= nil then
		AJM:AddGrey( AJM.autoSellPoorItemExceptionLink, AJM.autoSellPoorItemExceptionTag )
		AJM.autoSellPoorItemExceptionLink = nil
		AJM.settingsControlGreys.greysEditBoxExceptionItem:SetText( "" )
		AJM:SettingsRefresh()
	end
end
]]

function AJM:SettingsToggleAutoSellOtherItems( event, checked )
	AJM.db.autoSellOtherItems = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsOthersRemoveClick( event )
	StaticPopup_Show( "JAMBASELL_CONFIRM_REMOVE_AUTO_SELL_OTHER_ITEMS" )
end

function AJM:SettingsEditBoxChangedOtherItem( event, text )
	AJM.autoSellOtherItemLink = text
	AJM:SettingsRefresh()
end

function AJM:SettingsEditBoxChangedOtherTag( event, text )
	if not text or text:trim() == "" or text:find( "%W" ) ~= nil then
		AJM:Print( L["Item tags must only be made up of letters and numbers."] )
		return
	end
	AJM.autoSellOtherItemTag = text
	AJM:SettingsRefresh()
end

function AJM:SettingsEditBoxChangedUnusableSoulboundTag( event, text )
	if not text or text:trim() == "" or text:find( "%W" ) ~= nil then
		AJM:Print( L["Item tags must only be made up of letters and numbers."] )
		return
	end
	AJM.db.autoSellUnusableSoulboundTag = text
	AJM:SettingsRefresh()
end

function AJM:SettingsOthersAddClick( event )
	if AJM.autoSellOtherItemLink ~= nil and AJM.autoSellOtherItemTag ~= nil then
		AJM:AddOther( AJM.autoSellOtherItemLink, AJM.autoSellOtherItemTag )
		AJM.autoSellOtherItemLink = nil
		AJM.settingsControlOthers.othersEditBoxOtherItem:SetText( "" )
		AJM:SettingsRefresh()
	end
end

-------------------------------------------------------------------------------------------------------------
-- Popup Dialogs.
-------------------------------------------------------------------------------------------------------------

-- Initialize Popup Dialogs.
local function InitializePopupDialogs()
--	StaticPopupDialogs["JAMBASELL_CONFIRM_REMOVE_AUTO_SELL_POOR_ITEMS_EXCEPTION"] = {
--       text = L["Are you sure you wish to remove the selected item from the auto sell poor items exception list?"],
--       button1 = YES,
--       button2 = NO,
--       timeout = 0,
--		 whileDead = 1,
--		 hideOnEscape = 1,
--       OnAccept = function()
--		 AJM:RemoveGrey()
--		 end,
--   } 
	StaticPopupDialogs["JAMBASELL_CONFIRM_REMOVE_AUTO_SELL_OTHER_ITEMS"] = {
        text = L["Are you sure you wish to remove the selected item from the auto sell other items list?"],
        button1 = YES,
        button2 = NO,
        timeout = 0,
		whileDead = 1,
		hideOnEscape = 1,
        OnAccept = function()
			AJM:RemoveOther()
		end,
    }
end

-------------------------------------------------------------------------------------------------------------
-- Addon initialization, enabling and disabling.
-------------------------------------------------------------------------------------------------------------

-- Initialise the module.
function AJM:OnInitialize()
	-- Item link of item to add to auto sell item other / poor exception list.
--	AJM.autoSellPoorItemExceptionLink = nil
	AJM.autoSellOtherItemLink = nil
	-- The tag to add to the other / poor exception item.
--	AJM.autoSellPoorItemExceptionTag = JambaApi.AllTag()
	AJM.autoSellOtherItemTag = JambaApi.AllTag()

	-- Create the settings control.
	SettingsCreate()
	-- Initialise the JambaModule part of this module.
--	AJM:JambaModuleInitialize( AJM.settingsControlGreys.widgetSettings.frame )
	AJM:JambaModuleInitialize( AJM.settingsControl.widgetSettings.frame )
	-- Populate the settings.
	AJM:SettingsRefresh()	
	-- Initialise the popup dialogs.
	InitializePopupDialogs()	
	-- Hook the item click event.
	AJM:RawHook( "ContainerFrameItemButton_OnModifiedClick", true )
end

-- Called when the addon is enabled.
function AJM:OnEnable()
	AJM:RegisterEvent( "MERCHANT_SHOW" )
	AJM:RegisterMessage( JambaApi.MESSAGE_MESSAGE_AREAS_CHANGED, "OnMessageAreasChanged" )
end

-- Called when the addon is disabled.
function AJM:OnDisable()
end

-------------------------------------------------------------------------------------------------------------
-- JambaSell functionality.
-------------------------------------------------------------------------------------------------------------

--function AJM:ShowPopOutWindow()
	--AJM.standaloneWindow:Show()
--end

-- The ContainerFrameItemButton_OnModifiedClick hook.
function AJM:ContainerFrameItemButton_OnModifiedClick( self, event, ... )
	if AJM.db.sellItemOnAllWithAltKey == true and IsAltKeyDown() and MerchantFrame:IsVisible() then
		local bag, slot = self:GetParent():GetID(), self:GetID()
		local texture, count, locked, quality, readable, lootable, link = GetContainerItemInfo( bag, slot )
		AJM:JambaSendCommandToTeam( AJM.COMMAND_SELL_ITEM, link )
	end
	return AJM.hooks["ContainerFrameItemButton_OnModifiedClick"]( self, event, ... )
end

function AJM:DoSellItem( itemlink )
	-- Iterate each bag the player has.		
	for bag = AJM.BAG_PLAYER_BACKPACK, AJM.BAG_PLAYER_MAXIMUM do 
		-- Iterate each slot in the bag.
		numSlots = GetContainerNumSlots( bag )
		for slot = 1, numSlots do 
			-- Get the item link for the item in this slot.
		--	local bagItemLink = GetContainerItemLink( bag, slot )
			local _, _, locked, _, _, _, bagItemLink, _, hasNoValue = GetContainerItemInfo(bag, slot)
			-- If there is an item...
			if bagItemLink ~= nil then
				-- Does it match the item to sell?					
				if JambaUtilities:DoItemLinksContainTheSameItem( bagItemLink, itemlink ) then
					-- Yes, sell this item.
					if 	hasNoValue == false then	
						if MerchantFrame:IsVisible() == true then	
							UseContainerItem( bag, slot ) 
							-- Tell the boss.
							AJM:JambaSendMessageToTeam( AJM.db.messageArea, L["I have sold: X"]( bagItemLink ), false )
						end
					else
						if 	locked == false then
							PickupContainerItem(bag,slot)
							DeleteCursorItem()
							AJM:JambaSendMessageToTeam( AJM.db.messageArea, L["I have deleted: X"]( bagItemLink ), false )
						end	
					end							
				end
			end
		end
	end
end

--[[
function AJM:GetGreysMaxPosition()
	return #AJM.db.autoSellPoorItemsExceptionList
end

function AJM:GetGreyAtPosition( position )
	return AJM.db.autoSellPoorItemsExceptionList[position]
end

function AJM:GetGreyByName( name )
	for position, items in pairs( AJM.db.autoSellPoorItemsExceptionList ) do
		if items.name == name then
			return items
		end
	end
	return nil
end

function AJM:AddGrey( itemLink, itemTag )
	-- Get some more information about the item.
	local name, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo( itemLink )
	-- If the item could be found.
	if name ~= nil then
		local itemInformation = {}
		itemInformation.link = itemLink
		itemInformation.name = name
		itemInformation.tag = itemTag
		table.insert( AJM.db.autoSellPoorItemsExceptionList, itemInformation )
		AJM:SettingsRefresh()			
		AJM:SettingsGreysRowClick( 1, 1 )
	end	
end

function AJM:RemoveGrey()
	table.remove( AJM.db.autoSellPoorItemsExceptionList, AJM.settingsControlGreys.greysHighlightRow )
	AJM:SettingsRefresh()
	AJM:SettingsGreysRowClick( 1, 1 )		
end
]]

function AJM:GetOthersMaxPosition()
	return #AJM.db.autoSellOtherItemsList
end

function AJM:GetOtherAtPosition( position )
	return AJM.db.autoSellOtherItemsList[position]
end

function AJM:AddOther( itemLink, itemTag )
	-- Get some more information about the item.
	local name, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo( itemLink )
	-- If the item could be found.
	if name ~= nil then
		local itemInformation = {}
		itemInformation.link = itemLink
		itemInformation.name = name
		itemInformation.tag = itemTag
		table.insert( AJM.db.autoSellOtherItemsList, itemInformation )
		AJM:SettingsRefresh()			
		AJM:SettingsOthersRowClick( 1, 1 )
	end	
end

function AJM:RemoveOther()
	table.remove( AJM.db.autoSellOtherItemsList, AJM.settingsControlOthers.othersHighlightRow )
	AJM:SettingsRefresh()
	AJM:SettingsOthersRowClick( 1, 1 )		
end

function AJM:MERCHANT_SHOW()
	-- Sell Items
	if AJM.db.autoSellItem == true then
		AJM:DoMerchantSellItems()
	
	end
	-- Sell Other Items
	if AJM.db.autoSellOtherItems == true then
		AJM:ScheduleTimer( "DoMerchantSellOtherItems", 2 )
	end
	
	-- Does the user want to auto sell poor items?
	--if AJM.db.autoSellPoorItems == true then
	--	AJM:DoMerchantSellPoorItems()
	--end

	-- Does the user want to auto sell other items?
	-- Does the user want to auto sell unusable soulbound items?
--	if AJM.db.autoSellUnusableSoulbound == true then
--		if JambaApi.DoesCharacterHaveTag( AJM.characterName, AJM.db.autoSellUnusableSoulboundTag ) == true then
--			AJM:DoMerchantSellUnusableSoulbound()
--		end
--	end
end


function AJM:DoMerchantSellItems()
	local count = 0
	local gold = 0
	for bag,slot,link in LibBagUtils:Iterate("BAGS") do
		if bag ~= nil then
			if link ~= nil then	
			local canSell = false
			local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, iconFileDataID, itemSellPrice = GetItemInfo( link )	
			local _, itemCount = GetContainerItemInfo( bag, slot )
			--AJM:Print("Test", itemLink, itemRarity )
				if AJM.db.autoSellPoor == true then
					if itemRarity == AJM.ITEM_QUALITY_POOR then
						canSell = true
						if AJM.db.autoSellBoEPoor == true then 
							local isBop = JambaUtilities:ToolTipBagScaner(link, bag, slot)
							if isBop ~= ITEM_SOULBOUND then
							 --AJM:Print("BoE", link )
							 canSell = false
							end
						end	
					end
				end	
				-- Green
				if AJM.db.autoSellUncommon == true then
					if itemRarity == AJM.ITEM_QUALITY_UNCOMMON then
						if itemType == WEAPON or itemType == ARMOR or itemSubType == EJ_LOOT_SLOT_FILTER_ARTIFACT_RELIC then
							--AJM:Print("testGreen", link, itemRarity, "a", AJM.ITEM_QUALITY_UNCOMMON )
							local num = tonumber( AJM.db.autoSellIlvlUncommon )
							local iLvl = ItemUpgradeInfo:GetUpgradedItemLevel(link)
							--AJM:Print("test", num , "vs", iLvl, "item", link )
							if num ~= nil and iLvl ~= nil and ( itemLevel > AJM.MIN_ITEM_LEVEL ) then
								--if iLvl >= num then
								if num >= iLvl then	
									--AJM:Print("ture", link )
									canSell = true
								end
							end	
							if AJM.db.autoSellBoEUncommon == true then 
								local isBop = JambaUtilities:ToolTipBagScaner( link,bag,slot )
								--AJM:Print("IsBoP", isBop)									
								if isBop ~= ITEM_SOULBOUND then
									canSell = false
								end
							end
						end
					end
				end	
					--Blue
					if AJM.db.autoSellRare == true then
						if itemRarity == AJM.ITEM_QUALITY_RARE then
							if itemType == WEAPON or itemType == ARMOR or itemSubType == EJ_LOOT_SLOT_FILTER_ARTIFACT_RELIC then
								local num = tonumber( AJM.db.autoSellIlvlRare )
								local iLvl = ItemUpgradeInfo:GetUpgradedItemLevel(link)
								--AJM:Print("test", iLvl, "vs", num )
								if num ~= nil and iLvl ~= nil and (itemLevel > AJM.MIN_ITEM_LEVEL ) then
									if num >= iLvl then
										canSell = true
									end
								end	
								if AJM.db.autoSellBoERare == true then 
									local isBop = JambaUtilities:ToolTipBagScaner( link,bag,slot )
									--AJM:Print("IsBoP", isBop)
									if isBop ~= ITEM_SOULBOUND then
										canSell = false									
									end
								end
							end	
						end	
					end		
					-- Epic
					if AJM.db.autoSellEpic == true then
						if itemRarity == AJM.ITEM_QUALITY_EPIC then
							if itemType == WEAPON or itemType == ARMOR or itemSubType == EJ_LOOT_SLOT_FILTER_ARTIFACT_RELIC then
								local num = tonumber( AJM.db.autoSellIlvlEpic )
								local iLvl = ItemUpgradeInfo:GetUpgradedItemLevel(link)
								--AJM:Print("test", iLvl, "vs", num )
								if num ~= nil and iLvl ~= nil and (itemLevel > AJM.MIN_ITEM_LEVEL ) then
									if num >= iLvl then	
										canSell = true
									end
								end	
								if AJM.db.autoSellBoEEpic == true then 
									local isBop = JambaUtilities:ToolTipBagScaner( link,bag,slot )
									--AJM:Print("IsBoP", isBop)
									if isBop ~= ITEM_SOULBOUND then
										canSell = false
									end
								end
							end
						end	
					end
					if canSell == true then 
						if itemSellPrice ~= nil and itemSellPrice > 0 then
							if MerchantFrame:IsVisible() == true then
								if itemCount > 1 then
									count = count + itemCount
									gold = gold + itemSellPrice * itemCount
								else	
									count = count + 1
									gold = gold + itemSellPrice
								end
								UseContainerItem( bag, slot )	
							end
						end	
					end
				end	
			end
		end
	if count > 0 then	
		local formattedGoldAmount = GetCoinTextureString(gold)
		AJM:JambaSendMessageToTeam( AJM.db.messageArea, L["I have sold: X Items And Made:"]( count )..formattedGoldAmount, false )
	end
end



--[[
function AJM:DoMerchantSellUnusableSoulbound()
	-- Iterate each bag the player has.
	local localizedClass, fileClass = UnitClass( "player" )
	local compare = function(val, t)
		for _,v in ipairs(t) do
			if val == v then
				return true
			end
		end
		return false
	end
	local canWear = {
		ALL = {"Plate", "Mail", "Leather", "Cloth"},
		DEATHKNIGHT = {"Plate"},
		DRUID = {"Leather"},
		HUNTER = {"Mail"},
		MAGE = {"Cloth"},
		PALADIN = {"Plate"},
		PRIEST = {"Cloth"},
		ROGUE = {"Leather"},
		SHAMAN = {"Mail"}, 
		WARLOCK = {"Cloth"},
		WARRIOR = {"Plate"}
	}	
	for bag = AJM.BAG_PLAYER_BACKPACK, AJM.BAG_PLAYER_MAXIMUM do 
		-- Iterate each slot in the bag.
		for slot = 1, GetContainerNumSlots( bag ) do 
			-- Get the item link for the item in this slot.
			local itemLink = GetContainerItemLink( bag, slot )
			-- If there is an item...
			if itemLink ~= nil then
				-- Is the item soulbound?
				LibGratuity:SetBagItem( bag, slot )
				if LibGratuity:Find( ITEM_SOULBOUND, 1, 3 ) then
					-- Can this character's class use this item?
					if LibItemUtilsJamba:ClassCanUse( fileClass, itemLink ) == false then
						-- Sell.
						UseContainerItem( bag, slot ) 
						AJM:JambaSendMessageToTeam( AJM.db.messageArea, L["I have sold: X"]( itemLink ), false )
					end
					if AJM.db.autoSellUnusableSoulboundLowerTier == true then
						-- Is this a lower tier item?
						local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo( itemLink )
						-- If the item subtype is an armor, plate, mail, leather, cloth; and it is not the one the class can wear then sell it.
						if compare( itemSubType, canWear["ALL"] ) then
							if not compare( itemSubType, canWear[fileClass] ) then
								-- Sell.
								if MerchantFrame:IsVisible() == true then
									UseContainerItem( bag, slot ) 
									AJM:JambaSendMessageToTeam( AJM.db.messageArea, L["I have sold: X"]( itemLink ), false )
								end
							end
						end
					end
				end
			end
		end
	end
end


function AJM:DoMerchantSellPoorItems()
	-- Iterate each bag the player has.		
	for bag = AJM.BAG_PLAYER_BACKPACK, AJM.BAG_PLAYER_MAXIMUM do 
		-- Iterate each slot in the bag.
		local numSlots = GetContainerNumSlots( bag )
		for slot = 1, numSlots do 
			-- Get the item link for the item in this slot.
			local itemLink = GetContainerItemLink( bag, slot )
			-- If there is an item...
			if itemLink ~= nil then
				-- Get the item's quality.
				local name, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo( itemLink )				
				-- If the item is of a poor quality...
				if quality == AJM.ITEM_QUALITY_POOR then 
					-- Attempt to sell the item.
					AJM:SellPoorItemIfNotAnException( name, itemLink, bag, slot )				
				end
			end
		end
	end
end

function AJM:SellPoorItemIfNotAnException( itemName, itemLink, bag, slot )
	local canSell = true
	-- Are selling poor items exceptions on?
	if AJM.db.autoSellPoorItemsHaveExceptions == true then
		-- Yes, is this item in the list?
		local itemInformation = AJM:GetGreyByName( itemName )
		if itemInformation ~= nil then
			-- Does the character have this tag?
			if JambaApi.DoesCharacterHaveTag( AJM.characterName, itemInformation.tag ) == true then
				-- Yes, has the tag, do not sell the item.
				canSell = false
			end
		end
	end
	-- Can sell the item?
	if canSell == true then
		-- Then use it (effectively selling it as the character is talking to a merchant).
		if MerchantFrame:IsVisible() == true then
			UseContainerItem( bag, slot ) 
			AJM:JambaSendMessageToTeam( AJM.db.messageArea, L["I have sold: X"]( itemLink ), false )
		end	
	else
		AJM:JambaSendMessageToTeam( AJM.db.messageArea, L["DID NOT SELL: X"]( itemLink ), false )
	end						
end
]]
-- Sell Other Items! 

function AJM:DoMerchantSellOtherItems()
	-- Iterate all the wanted items...
	for position, itemInformation in pairs( AJM.db.autoSellOtherItemsList ) do
		-- Does this character have the item tag?  No, don't sell.
		if JambaApi.DoesCharacterHaveTag( AJM.characterName, itemInformation.tag ) == true then
			-- Attempt to sell any items in the players bags.
			-- Iterate each bag the player has.		
			for bag = AJM.BAG_PLAYER_BACKPACK, AJM.BAG_PLAYER_MAXIMUM do 
				-- Iterate each slot in the bag.
				for slot = 1, GetContainerNumSlots( bag ) do 
					-- Get the item link for the item in this slot.
					local bagItemLink = GetContainerItemLink( bag, slot )
					local _, _, locked, _, _, _, bagItemLink, _, hasNoValue = GetContainerItemInfo(bag, slot)
					-- If there is an item...
					if bagItemLink ~= nil then
						-- Does it match the item to sell?					
						if JambaUtilities:DoItemLinksContainTheSameItem( bagItemLink, itemInformation.link ) then
							-- Yes, sell this item.
							if 	hasNoValue == false then	
								if MerchantFrame:IsVisible() == true then	
									UseContainerItem( bag, slot ) 
									-- Tell the boss.
									--AJM:JambaSendMessageToTeam( AJM.db.messageArea, L["I have sold: X"]( bagItemLink ), false )
								end
							else
								if 	locked == false then
									PickupContainerItem(bag,slot)
									DeleteCursorItem()
								end	
							end							
						end
					end
				end
			end
		end
	end
end

-- A Jamba command has been recieved.
function AJM:JambaOnCommandReceived( characterName, commandName, ... )
	if commandName == AJM.COMMAND_SELL_ITEM then
		AJM:DoSellItem( ... )
	end
end
