--[[
Jamba - Jafula's Awesome Multi-Boxer Assistant
Copyright 2008 - 2018 Michael "Jafula" Miller
License: The MIT License
]]--

-- Create the addon using AceAddon-3.0 and embed some libraries.
local AJM = LibStub( "AceAddon-3.0" ):NewAddon( 
	"JambaTrade", 
	"JambaModule-1.0", 
	"AceConsole-3.0", 
	"AceEvent-3.0",
	"AceHook-3.0",
	"AceTimer-3.0"
)

-- Get the Jamba Utilities Library.
local JambaUtilities = LibStub:GetLibrary( "JambaUtilities-1.0" )
local JambaHelperSettings = LibStub:GetLibrary( "JambaHelperSettings-1.0" )
local LibBagUtils = LibStub:GetLibrary( "LibBagUtils-1.0" )
--local LibGratuity = LibStub( "LibGratuity-3.0" ) --Unlikey to be used bugged!
local AceGUI = LibStub( "AceGUI-3.0" )

--  Constants and Locale for this module.
AJM.moduleName = "Jamba-Trade"
AJM.settingsDatabaseName = "JambaTradeProfileDB"
AJM.chatCommand = "jamba-trade"
local L = LibStub( "AceLocale-3.0" ):GetLocale( AJM.moduleName )
AJM.parentDisplayName = L["Toon"]
AJM.moduleDisplayName = L["Trade"]

AJM.inventorySeperator = "\008"
AJM.inventoryPartSeperator = "\009"

-- Settings - the values to store and their defaults for the settings database.
AJM.settings = {
	profile = {
		messageArea = JambaApi.DefaultMessageArea(),
		showJambaTradeWindow = false,
		tradeBoEItems = false,
		tradeCRItems = false,
		autoTradeItemsList = {},
		adjustMoneyWithGuildBank = false,
		goldAmountToKeepOnToon = 200,
		adjustMoneyWithMasterOnTrade = false,
		goldAmountToKeepOnToonTrade = 200,
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
				desc = L["Push the trade settings to all characters in the team."],
				usage = "/jamba-trade push",
				get = false,
				set = "JambaSendSettings",
				guiHidden = true,
			},
		},
	}
	return configuration
end

-------------------------------------------------------------------------------------------------------------
-- Command this module sends.
-------------------------------------------------------------------------------------------------------------


-------------------------------------------------------------------------------------------------------------
-- Messages module sends.
-------------------------------------------------------------------------------------------------------------


-------------------------------------------------------------------------------------------------------------
-- Popup Dialogs.
-------------------------------------------------------------------------------------------------------------

local function InitializePopupDialogs()
	StaticPopupDialogs["JAMBATRADE_CONFIRM_REMOVE_TRADE_ITEMS"] = {
        text = L["Are you sure you wish to remove the selected item from the trade items list?"],
        button1 = YES,
        button2 = NO,
        timeout = 0,
		whileDead = 1,
		hideOnEscape = 1,
        OnAccept = function()
			AJM:RemoveItem()
		end,
    }
end


-------------------------------------------------------------------------------------------------------------
-- Addon initialization, enabling and disabling.
-------------------------------------------------------------------------------------------------------------

-- Initialise the module.
function AJM:OnInitialize()
	-- Initialise the popup dialogs.
	InitializePopupDialogs()
	AJM.autoTradeItemLink = nil
	AJM.autoTradeItemTag = JambaApi.AllTag()
	-- Create the settings control.
	AJM:SettingsCreate()
	-- Initialse the JambaModule part of this module.
	AJM:JambaModuleInitialize( AJM.settingsControl.widgetSettings.frame )
	-- Populate the settings.
	AJM:SettingsRefresh()	
end

-- Called when the addon is enabled.
function AJM:OnEnable()
	AJM:RegisterEvent( "TRADE_SHOW" )
	AJM:RegisterEvent( "TRADE_CLOSED" ) -- Unsued but we keep it for now!
	AJM:RegisterEvent( "GUILDBANKFRAME_OPENED" ) -- Temp!
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
	local bottomOfInfo = AJM:SettingsCreateTrade( JambaHelperSettings:TopOfSettings() )
	AJM.settingsControl.widgetSettings.content:SetHeight( -bottomOfInfo )
	-- Help
	local helpTable = {}
	JambaHelperSettings:CreateHelp( AJM.settingsControl, helpTable, AJM:GetConfiguration() )		
end

function AJM:SettingsPushSettingsClick( event )
	AJM:JambaSendSettings()
end

function AJM:SettingsCreateTrade( top )
	local buttonControlWidth = 85
	local checkBoxHeight = JambaHelperSettings:GetCheckBoxHeight()
	local editBoxHeight = JambaHelperSettings:GetEditBoxHeight()
	local buttonHeight = JambaHelperSettings:GetButtonHeight()
	local dropdownHeight = JambaHelperSettings:GetDropdownHeight()
	local left = JambaHelperSettings:LeftOfSettings()
	local headingHeight = JambaHelperSettings:HeadingHeight()
	local headingWidth = JambaHelperSettings:HeadingWidth( false )
	local horizontalSpacing = JambaHelperSettings:GetHorizontalSpacing()
	local verticalSpacing = JambaHelperSettings:GetVerticalSpacing()
	local tradeWidth = headingWidth
	local movingTop = top
	JambaHelperSettings:CreateHeading( AJM.settingsControl, L["Trade Item List"], movingTop, false )
	movingTop = movingTop - headingHeight
	AJM.settingsControl.checkBoxShowJambaTradeWindow = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		left, 
		movingTop, 
		L["Trade The List Of Items With Master"],
		AJM.SettingsToggleShowJambaTradeWindow
	)	
	movingTop = movingTop - checkBoxHeight
	AJM.settingsControl.checkBoxTradeBoEItems = JambaHelperSettings:CreateCheckBox( 
	AJM.settingsControl, 
		headingWidth, 
		left, 
		movingTop, 
		L["Trades Binds When Equipped Items With Master"],
		AJM.SettingsToggleTradeBoEItems
	)	
	movingTop = movingTop - checkBoxHeight
	AJM.settingsControl.checkBoxTradeCRItems = JambaHelperSettings:CreateCheckBox( 
	AJM.settingsControl, 
		headingWidth, 
		left, 
		movingTop, 
		L["Trades Crafting Reagents Items With Master"],
		AJM.SettingsToggleTradeCRItems
	)	
	movingTop = movingTop - checkBoxHeight
	AJM.settingsControl.tradeItemsHighlightRow = 1
	AJM.settingsControl.tradeItemsOffset = 1
	local list = {}
	list.listFrameName = "JambaTradeIteamsSettingsFrame"
	list.parentFrame = AJM.settingsControl.widgetSettings.content
	list.listTop = movingTop
	list.listLeft = left
	list.listWidth = tradeWidth
	list.rowHeight = 15
	list.rowsToDisplay = 10
	list.columnsToDisplay = 2
	list.columnInformation = {}
	list.columnInformation[1] = {}
	list.columnInformation[1].width = 70
	list.columnInformation[1].alignment = "LEFT"
	list.columnInformation[2] = {}
	list.columnInformation[2].width = 30
	list.columnInformation[2].alignment = "LEFT"	
	list.scrollRefreshCallback = AJM.SettingsScrollRefresh
	list.rowClickCallback = AJM.SettingsTradeItemsRowClick
	AJM.settingsControl.tradeItems = list
	JambaHelperSettings:CreateScrollList( AJM.settingsControl.tradeItems )
	movingTop = movingTop - list.listHeight - verticalSpacing
	AJM.settingsControl.tradeItemsButtonRemove = JambaHelperSettings:CreateButton(
		AJM.settingsControl, 
		buttonControlWidth, 
		left, 
		movingTop,
		L["Remove"],
		AJM.SettingsTradeItemsRemoveClick
	)
	movingTop = movingTop -	buttonHeight - verticalSpacing
	JambaHelperSettings:CreateHeading( AJM.settingsControl, L["Add Items"], movingTop, false )
	movingTop = movingTop - headingHeight
	AJM.settingsControl.tradeItemsEditBoxTradeItem = JambaHelperSettings:CreateEditBox( 
		AJM.settingsControl,
		headingWidth,
		left,
		movingTop,
		L["Other Item (drag item to box)"]
	)
	AJM.settingsControl.tradeItemsEditBoxTradeItem:SetCallback( "OnEnterPressed", AJM.SettingsEditBoxChangedTradeItem )
	movingTop = movingTop - editBoxHeight	
	AJM.settingsControl.tradeItemsEditBoxTradeTag = JambaHelperSettings:CreateEditBox( 
		AJM.settingsControl,
		headingWidth,
		left,
		movingTop,
		L["Other Tag"]
	)
	
	AJM.settingsControl.tradeItemsEditBoxTradeTag:SetCallback( "OnEnterPressed", AJM.SettingsEditBoxChangedTradeItemTag )
	movingTop = movingTop - editBoxHeight	
	AJM.settingsControl.tradeItemsButtonAdd = JambaHelperSettings:CreateButton(	
		AJM.settingsControl, 
		buttonControlWidth, 
		left, 
		movingTop, 
		L["Add"],
		AJM.SettingsTradeItemsAddClick
	)
	movingTop = movingTop -	buttonHeight		
	JambaHelperSettings:CreateHeading( AJM.settingsControl, L["Trade Options"], movingTop, false )
	movingTop = movingTop - headingHeight
	AJM.settingsControl.checkBoxAdjustMoneyOnToonViaGuildBank = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		left, 
		movingTop, 
		L["Adjust Toon Money While Visiting The Guild Bank"],
		AJM.SettingsToggleAdjustMoneyOnToonViaGuildBank
	)	
	movingTop = movingTop - checkBoxHeight
	AJM.settingsControl.editBoxGoldAmountToLeaveOnToon = JambaHelperSettings:CreateEditBox( AJM.settingsControl,
		headingWidth,
		left,
		movingTop,
		L["Amount of Gold"]
	)	
	AJM.settingsControl.editBoxGoldAmountToLeaveOnToon:SetCallback( "OnEnterPressed", AJM.EditBoxChangedGoldAmountToLeaveOnToon )
	movingTop = movingTop - editBoxHeight
	AJM.settingsControl.checkBoxAdjustMoneyWithMasterOnTrade = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		left, 
		movingTop, 
		L["Trade Excess Gold To Master From Minion"],
		AJM.SettingsToggleAdjustMoneyWithMasterOnTrade
	)	
	movingTop = movingTop - checkBoxHeight
	AJM.settingsControl.editBoxGoldAmountToLeaveOnToonTrade = JambaHelperSettings:CreateEditBox( AJM.settingsControl,
		headingWidth,
		left,
		movingTop,
		L["Amount Of Gold To Keep"]
	)	
	AJM.settingsControl.editBoxGoldAmountToLeaveOnToonTrade:SetCallback( "OnEnterPressed", AJM.EditBoxChangedGoldAmountToLeaveOnToonTrade )
	movingTop = movingTop - editBoxHeight
	
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


-------------------------------------------------------------------------------------------------------------
-- Settings Callbacks.
-------------------------------------------------------------------------------------------------------------


function AJM:SettingsScrollRefresh()
	FauxScrollFrame_Update(
		AJM.settingsControl.tradeItems.listScrollFrame, 
		AJM:GetTradeItemsMaxPosition(),
		AJM.settingsControl.tradeItems.rowsToDisplay, 
		AJM.settingsControl.tradeItems.rowHeight
	)
	AJM.settingsControl.tradeItemsOffset = FauxScrollFrame_GetOffset( AJM.settingsControl.tradeItems.listScrollFrame )
	for iterateDisplayRows = 1, AJM.settingsControl.tradeItems.rowsToDisplay do
		-- Reset.
		AJM.settingsControl.tradeItems.rows[iterateDisplayRows].columns[1].textString:SetText( "" )
		AJM.settingsControl.tradeItems.rows[iterateDisplayRows].columns[1].textString:SetTextColor( 1.0, 1.0, 1.0, 1.0 )
		AJM.settingsControl.tradeItems.rows[iterateDisplayRows].columns[2].textString:SetText( "" )
		AJM.settingsControl.tradeItems.rows[iterateDisplayRows].columns[2].textString:SetTextColor( 1.0, 1.0, 1.0, 1.0 )		
		AJM.settingsControl.tradeItems.rows[iterateDisplayRows].highlight:SetColorTexture( 0.0, 0.0, 0.0, 0.0 )
		-- Get data.
		local dataRowNumber = iterateDisplayRows + AJM.settingsControl.tradeItemsOffset
		if dataRowNumber <= AJM:GetTradeItemsMaxPosition() then
			-- Put data information into columns.
			local tradeItemsInformation = AJM:GetTradeItemsAtPosition( dataRowNumber )
			AJM.settingsControl.tradeItems.rows[iterateDisplayRows].columns[1].textString:SetText( tradeItemsInformation.name )
			AJM.settingsControl.tradeItems.rows[iterateDisplayRows].columns[2].textString:SetText( tradeItemsInformation.tag )
			-- Highlight the selected row.
			if dataRowNumber == AJM.settingsControl.tradeItemsHighlightRow then
				AJM.settingsControl.tradeItems.rows[iterateDisplayRows].highlight:SetColorTexture( 1.0, 1.0, 0.0, 0.5 )
			end
		end
	end
end

function AJM:SettingsTradeItemsRowClick( rowNumber, columnNumber )		
	if AJM.settingsControl.tradeItemsOffset + rowNumber <= AJM:GetTradeItemsMaxPosition() then
		AJM.settingsControl.tradeItemsHighlightRow = AJM.settingsControl.tradeItemsOffset + rowNumber
		AJM:SettingsScrollRefresh()
	end
end

function AJM:SettingsTradeItemsRemoveClick( event )
	StaticPopup_Show( "JAMBATRADE_CONFIRM_REMOVE_TRADE_ITEMS" )
end

function AJM:SettingsEditBoxChangedTradeItem( event, text )
	AJM.autoTradeItemLink = text
	AJM:SettingsRefresh()
end

function AJM:SettingsEditBoxChangedTradeItemTag( event, text )
	if not text or text:trim() == "" or text:find( "%W" ) ~= nil then
		AJM:Print( L["Item tags must only be made up of letters and numbers."] )
		return
	end
	AJM.autoTradeItemTag = text
	AJM:SettingsRefresh()
end

function AJM:SettingsTradeItemsAddClick( event )
	if AJM.autoTradeItemLink ~= nil and AJM.autoTradeItemTag ~= nil then
		AJM:AddItem( AJM.autoTradeItemLink, AJM.autoTradeItemTag )
		AJM.autoTradeItemLink = nil
		AJM.settingsControl.tradeItemsEditBoxTradeItem:SetText( "" )
		AJM:SettingsRefresh()
	end
end

function AJM:OnMessageAreasChanged( message )
	AJM.settingsControl.dropdownMessageArea:SetList( JambaApi.MessageAreaList() )
end

function AJM:SettingsSetMessageArea( event, value )
	AJM.db.messageArea = value
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleShowJambaTradeWindow( event, checked )
	AJM.db.showJambaTradeWindow = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleTradeBoEItems(event, checked )
	AJM.db.tradeBoEItems = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleTradeCRItems(event, checked )
	AJM.db.tradeCRItems = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleAdjustMoneyOnToonViaGuildBank( event, checked )
	AJM.db.adjustMoneyWithGuildBank = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleAdjustMoneyWithMasterOnTrade( event, checked )
	AJM.db.adjustMoneyWithMasterOnTrade = checked
	AJM:SettingsRefresh()
end

function AJM:EditBoxChangedGoldAmountToLeaveOnToon( event, text )
	AJM.db.goldAmountToKeepOnToon = tonumber( text )
	if AJM.db.goldAmountToKeepOnToon == nil then
		AJM.db.goldAmountToKeepOnToon = 0
	end
	AJM:SettingsRefresh()
end

function AJM:EditBoxChangedGoldAmountToLeaveOnToonTrade( event, text )
	AJM.db.goldAmountToKeepOnToonTrade = tonumber( text )
	if AJM.db.goldAmountToKeepOnToonTrade == nil then
		AJM.db.goldAmountToKeepOnToonTrade = 0
	end
	AJM:SettingsRefresh()
end

-- Settings received.
function AJM:JambaOnSettingsReceived( characterName, settings )	
	if characterName ~= AJM.characterName then
		-- Update the settings.
		AJM.db.messageArea = settings.messageArea
		AJM.db.showJambaTradeWindow = settings.showJambaTradeWindow
		AJM.db.tradeBoEItems = settings.tradeBoEItems
		AJM.db.tradeCRItems = settings.tradeCRItems
		AJM.db.autoTradeItemsList = JambaUtilities:CopyTable( settings.autoTradeItemsList )
		AJM.db.adjustMoneyWithGuildBank = settings.adjustMoneyWithGuildBank
		AJM.db.goldAmountToKeepOnToon = settings.goldAmountToKeepOnToon
		AJM.db.adjustMoneyWithMasterOnTrade = settings.adjustMoneyWithMasterOnTrade
		AJM.db.goldAmountToKeepOnToonTrade = settings.goldAmountToKeepOnToonTrade
		-- Refresh the settings.
		AJM:SettingsRefresh()
		-- Tell the player.
		AJM:Print( L["Settings received from A."]( characterName ) )
	end
end

function AJM:BeforeJambaProfileChanged()	
end

function AJM:OnJambaProfileChanged()	
	AJM:SettingsRefresh()
end

function AJM:SettingsRefresh()
	AJM.settingsControl.checkBoxShowJambaTradeWindow:SetValue( AJM.db.showJambaTradeWindow )
	AJM.settingsControl.checkBoxTradeBoEItems:SetValue( AJM.db.tradeBoEItems)
	AJM.settingsControl.checkBoxTradeCRItems:SetValue( AJM.db.tradeCRItems)
	AJM.settingsControl.checkBoxTradeBoEItems:SetDisabled( not AJM.db.showJambaTradeWindow )
	AJM.settingsControl.checkBoxTradeCRItems:SetDisabled( not AJM.db.showJambaTradeWindow )
	AJM.settingsControl.dropdownMessageArea:SetValue( AJM.db.messageArea )
	AJM.settingsControl.checkBoxAdjustMoneyOnToonViaGuildBank:SetValue( AJM.db.adjustMoneyWithGuildBank )
	AJM.settingsControl.editBoxGoldAmountToLeaveOnToon:SetText( tostring( AJM.db.goldAmountToKeepOnToon ) )
	AJM.settingsControl.editBoxGoldAmountToLeaveOnToon:SetDisabled( not AJM.db.adjustMoneyWithGuildBank )
	AJM.settingsControl.checkBoxAdjustMoneyWithMasterOnTrade:SetValue( AJM.db.adjustMoneyWithMasterOnTrade )
	AJM.settingsControl.editBoxGoldAmountToLeaveOnToonTrade:SetText( tostring( AJM.db.goldAmountToKeepOnToonTrade ) )
	AJM.settingsControl.editBoxGoldAmountToLeaveOnToonTrade:SetDisabled( not AJM.db.adjustMoneyWithMasterOnTrade )
	AJM.settingsControl.tradeItemsEditBoxTradeTag:SetText( AJM.autoTradeItemTag )
	AJM.settingsControl.tradeItemsEditBoxTradeItem:SetDisabled( not AJM.db.showJambaTradeWindow )
	AJM.settingsControl.tradeItemsEditBoxTradeTag:SetDisabled( not AJM.db.showJambaTradeWindow )	
	AJM.settingsControl.tradeItemsButtonRemove:SetDisabled( not AJM.db.showJambaTradeWindow )
	AJM.settingsControl.tradeItemsButtonAdd:SetDisabled( not AJM.db.showJambaTradeWindow )
	AJM:SettingsScrollRefresh()

end

--Comms not sure if we going to use comms here.
-- A Jamba command has been received.
function AJM:JambaOnCommandReceived( characterName, commandName, ... )
	if characterName == self.characterName then
		return
	end
end

-------------------------------------------------------------------------------------------------------------
-- Trade functionality.
-------------------------------------------------------------------------------------------------------------

-- New Trade stuff


function AJM:GetTradeItemsMaxPosition()
	return #AJM.db.autoTradeItemsList
end

function AJM:GetTradeItemsAtPosition( position )
	return AJM.db.autoTradeItemsList[position]
end

function AJM:AddItem( itemLink, itemTag )
	-- Get some more information about the item.
	local name, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo( itemLink )
	-- If the item could be found.
	if name ~= nil then
		local itemInformation = {}
		itemInformation.link = link
		itemInformation.name = name
		itemInformation.tag = itemTag
		table.insert( AJM.db.autoTradeItemsList, itemInformation )
		AJM:SettingsRefresh()			
		AJM:SettingsTradeItemsRowClick( 1, 1 )
	end	
end

function AJM:RemoveItem()
	table.remove( AJM.db.autoTradeItemsList, AJM.settingsControl.tradeItemsHighlightRow )
	AJM:SettingsRefresh()
	AJM:SettingsTradeItemsRowClick( 1, 1 )		
end


function AJM:TRADE_SHOW( event, ... )	
	--Keep for tradeing gold!
	if AJM.db.adjustMoneyWithMasterOnTrade == true then
		AJM:ScheduleTimer( "TradeShowAdjustMoneyWithMaster", 1 )
	end	
	-- do trade list with Gold!
	if AJM.db.showJambaTradeWindow == true then
		AJM:ScheduleTimer("TradeItemsFromList", 1 )
	end
	if AJM.db.tradeBoEItems == true and AJM.db.showJambaTradeWindow == true then
		AJM:ScheduleTimer("TradeBoEItems", 1.5 )
	end	
	if AJM.db.tradeCRItems == true and AJM.db.showJambaTradeWindow == true then
		AJM:ScheduleTimer("TradeCRItems", 1.8 )
	end	
end


function AJM:TradeShowAdjustMoneyWithMaster()
	if JambaApi.IsCharacterTheMaster( AJM.characterName ) == true then
		return
	end
	local moneyToKeepOnToon = tonumber( AJM.db.goldAmountToKeepOnToonTrade ) * 10000
	local moneyOnToon = GetMoney()
	local moneyToDepositOrWithdraw = moneyOnToon - moneyToKeepOnToon
	if moneyToDepositOrWithdraw == 0 then
		return
	end
	if moneyToDepositOrWithdraw > 0 then
		for index, character in JambaApi.TeamListOrderedOnline() do
			--AJM:Print("Team", character )
			local teamCharacterName = ( Ambiguate( character, "short" ) )
			local tradePlayersName = GetUnitName("NPC")
			if tradePlayersName == teamCharacterName then
					--AJM:Print("found", tradePlayersName, teamCharacterName, character )
					if JambaApi.IsCharacterTheMaster(character) == true and JambaUtilities:CheckIsFromMyRealm(character) == true then	
						MoneyInputFrame_SetCopper(TradePlayerInputMoneyFrame, moneyToDepositOrWithdraw)
						break
					end	
			else
				--AJM:Print(tradePlayersName, L["Is Not a Member of the team, Will not trade Gold."])
			end
		end
		
	end
end


function AJM:TradeItemsFromList()
	if JambaApi.IsCharacterTheMaster( AJM.characterName ) == true then
		return
	end
	for index, character in JambaApi.TeamListOrderedOnline() do
		--AJM:Print("Team", character )
		local teamCharacterName = ( Ambiguate( character, "short" ) )
		local tradePlayersName = GetUnitName("NPC")
		if tradePlayersName == teamCharacterName then
			--AJM:Print("found", tradePlayersName, teamCharacterName, character )
			if JambaApi.IsCharacterTheMaster(character) == true and JambaUtilities:CheckIsFromMyRealm(character) == true then
				--Checks the D_B for any items in the list.
				for position, itemInformation in pairs( AJM.db.autoTradeItemsList ) do
					--AJM:Print("Items in list", itemInformation.link )
					if JambaApi.DoesCharacterHaveTag( AJM.characterName, itemInformation.tag ) == true then
					--Checks if there is a item in the bag with the name
						--local bag, slot, link = LibBagUtils:Find("BAGS", itemInformation.link ) --did olny the find the 1st stack of a item.
						for bag,slot,link in LibBagUtils:Iterate("BAGS", itemInformation.link ) do
							if bag ~= nil then
								--AJM:Print("found", bag, slot)
								for iterateTradeSlots = 1, (MAX_TRADE_ITEMS - 1) do
									if GetTradePlayerItemLink( iterateTradeSlots ) == nil then
										PickupContainerItem( bag, slot )
										ClickTradeButton( iterateTradeSlots )
									end	
								end		
							end
						end		
					end	
				end				
			end			
		else
			--AJM:Print(tradePlayersName, L["Is Not a Member of the team, Will not trade Items."])
		end	
	end	
end

function AJM:TradeBoEItems()
	if JambaApi.IsCharacterTheMaster( AJM.characterName ) == true then
		return
	end
	for index, character in JambaApi.TeamListOrderedOnline() do
		--AJM:Print("Team", character )
		local teamCharacterName = ( Ambiguate( character, "short" ) )
		local tradePlayersName = GetUnitName("NPC")
		if tradePlayersName == teamCharacterName then
			if JambaApi.IsCharacterTheMaster(character) == true and JambaUtilities:CheckIsFromMyRealm(character) == true then
				for bag,slot,link in LibBagUtils:Iterate("BAGS") do
					if bag ~= nil then			
						local _, _, locked, quality = GetContainerItemInfo(bag, slot)
						-- quality is Uncommon (green) to  Epic (purple) 2 - 3 - 4
						if quality ~= nil and locked == false then
							if quality >= 2 and quality <= 4 then 
								-- tooltips scan is the olny way to find if the item is BoE in bags!
								local isBoe = JambaUtilities:ToolTipBagScaner(link, bag, slot)
								-- if the item is boe then add it to the trade list!
								if isBoe ~= ITEM_SOULBOUND then
									--AJM:Print("test21", link, locked)
									for iterateTradeSlots = 1, (MAX_TRADE_ITEMS - 1) do
										if GetTradePlayerItemLink( iterateTradeSlots ) == nil then
											PickupContainerItem( bag, slot )
											ClickTradeButton( iterateTradeSlots )
										end	
									end
								end	
							end	
						end	
					end	
				end
			end
		end
	end		
end


function AJM:TradeCRItems()
	if JambaApi.IsCharacterTheMaster( AJM.characterName ) == true then
		return
	end
	for index, character in JambaApi.TeamListOrderedOnline() do
		--AJM:Print("Team", character )
		local teamCharacterName = ( Ambiguate( character, "short" ) )
		local tradePlayersName = GetUnitName("NPC")
		if tradePlayersName == teamCharacterName then
			if JambaApi.IsCharacterTheMaster(character) == true and JambaUtilities:CheckIsFromMyRealm(character) == true then
				for bag,slot,itemLink in LibBagUtils:Iterate("BAGS") do
					if itemLink then
						-- using legion CraftingReagent API, as tooltip massess up some "items"
						local _,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,isCraftingReagent = GetItemInfo(itemLink)
						if isCraftingReagent == true then
							--AJM:Print("TradeCraftingGoods", isCraftingReagent, itemLink)
							-- tooltips scan is the olny way to find if the item is BOP in bags!
							local isBop = JambaUtilities:TooltipScaner(itemLink)
							--AJM:Print("testBOP", itemLink, isBop)
							if isBop ~= ITEM_BIND_ON_PICKUP then
							--AJM:Print("AddToTrade", itemLink)
								for iterateTradeSlots = 1, (MAX_TRADE_ITEMS - 1) do
									if GetTradePlayerItemLink( iterateTradeSlots ) == nil then
										PickupContainerItem( bag, slot )
										ClickTradeButton( iterateTradeSlots )
									end	
								end	
							end	
						end	
					end	
				end
			end
		end
	end		
end


function AJM:TRADE_CLOSED()
	
end
-- Guild bank stuff keep TEMP!

function AJM:GUILDBANKFRAME_OPENED()
	--AJM:Print("guildBankOpen")
	if AJM.db.adjustMoneyWithGuildBank == false then
		return
	end
	if not CanWithdrawGuildBankMoney() then
		return
	end
	local moneyToKeepOnToon = tonumber( AJM.db.goldAmountToKeepOnToon ) * 10000
	local moneyOnToon = GetMoney()
	local moneyToDepositOrWithdraw = moneyOnToon - moneyToKeepOnToon
	--AJM:Print(" testa", moneyToDepositOrWithdraw )
	if moneyToDepositOrWithdraw == 0 then
		return
	end
	if moneyToDepositOrWithdraw > 0 then
	--	AJM:Print(" test", moneyToDepositOrWithdraw )
		--DepositGuildBankMoney( moneyToDepositOrWithdraw )
		AJM:ScheduleTimer("SendMoneyToGuild", 0.5, moneyToDepositOrWithdraw)
	else
		local takeoutmoney = -1 * moneyToDepositOrWithdraw
	--	AJM:Print("takeout", takeoutmoney)
		AJM:ScheduleTimer("TakeMoneyOut", 0.5, takeoutmoney )
	end
end

function AJM:SendMoneyToGuild( money )
	DepositGuildBankMoney( money )
end

function AJM:TakeMoneyOut( money )
	WithdrawGuildBankMoney( money )	
end	