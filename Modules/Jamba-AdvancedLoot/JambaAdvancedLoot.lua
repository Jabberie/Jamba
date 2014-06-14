--[[
Jamba Advanced Loot
*******************
Author: Max Schilling
Create Date: 10/16/2012
Version: 5.1.1
Description: Jamba extension that allows choosing which group member is able to loot a certain item. Specifically intended for Motes of Harmony.
Credits: Built on top of the awesome JAMBA addon, most code is copied nearly directly from various Jamba addons. Only the logic for looting is original.
]]--


-- Create the addon using AceAddon-3.0 and embed some libraries.
local AJM = LibStub( "AceAddon-3.0" ):NewAddon( 
	"JambaAdvancedLoot", 
	"JambaModule-1.0", 
	"AceConsole-3.0", 
	"AceEvent-3.0"
)

 AJM.simpleTeamList = {}

-- Load libraries.
local JambaUtilities = LibStub:GetLibrary( "JambaUtilities-1.0" )
local JambaHelperSettings = LibStub:GetLibrary( "JambaHelperSettings-1.0" )
local AceGUI = LibStub:GetLibrary( "AceGUI-3.0" )

--  Constants and Locale for this module.
AJM.moduleName = "Jamba-AdvancedLoot"
AJM.settingsDatabaseName = "JambaAdvancedLootProfileDB"
AJM.chatCommand = "jamba-advancedloot"
local L = LibStub( "AceLocale-3.0" ):GetLocale( AJM.moduleName )
AJM.parentDisplayName = L["Team"]
AJM.moduleDisplayName = L["Advanced Loot"]

-- Settings - the values to store and their defaults for the settings database.
AJM.settings = {
	profile = {
		advancedLoot = false,
		manageAutoLoot = false,
		autoCloseLootWindowOnSlaves = false,
		messageArea = JambaApi.DefaultWarningArea(),
		advancedLootItems = {}
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
			--[[
			popout = {
				type = "input",
				name = L["PopOut"],
				desc = L["Show the advancedloot settings in their own window."],
				usage = "/jamba-advancedloot popout",
				get = false,
				set = "ShowPopOutWindow",
			},
			]]--
			push = {
				type = "input",
				name = L["Push Settings"],
				desc = L["Push the advanced loot settings to all characters in the team."],
				usage = "/jamba-advancedloot push",
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

-------------------------------------------------------------------------------------------------------------
-- Messages module sends.
-------------------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------------------------
-- Advanced Loot Management.
-------------------------------------------------------------------------------------------------------------

function AJM:BeforeJambaProfileChanged()	
end

function AJM:OnJambaProfileChanged()	
	AJM:SettingsRefresh()
end

function AJM:SettingsRefresh()

	if AJM.advancedLootItemCharacterName == nil then
		AJM.advancedLootItemCharacterName = AJM.characterName
	end

	AJM.settingsControl.checkBoxAdvancedLoot:SetValue( AJM.db.advancedLoot )
	AJM.settingsControl.checkBoxManageAutoLoot:SetValue( AJM.db.manageAutoLoot )
	AJM.settingsControl.checkBoxAutoCloseLootWindowOnSlaves:SetValue( AJM.db.autoCloseLootWindowOnSlaves )	
	AJM.settingsControl.dropdownCharacterName:SetValue( AJM.advancedLootItemCharacterName )
	AJM.settingsControl.dropdownMessageArea:SetValue( AJM.db.messageArea )	
	AJM.settingsControl.checkBoxManageAutoLoot:SetDisabled( not AJM.db.advancedLoot )
	AJM.settingsControl.editBoxItem:SetDisabled( not AJM.db.advancedLoot )
	AJM.settingsControl.dropdownCharacterName:SetDisabled( not AJM.db.advancedLoot )
	AJM.settingsControl.buttonRemove:SetDisabled( not AJM.db.advancedLoot )
	AJM.settingsControl.buttonAdd:SetDisabled( not AJM.db.advancedLoot )
	AJM:SettingsScrollRefresh()
end

-- Settings received.
function AJM:JambaOnSettingsReceived( characterName, settings )	
	if characterName ~= AJM.characterName then
		-- Update the settings.
		AJM.db.advancedLoot = settings.advancedLoot
		AJM.db.manageAutoLoot = settings.manageAutoLoot
		AJM.db.messageArea = settings.messageArea
		AJM.db.autoCloseLootWindowOnSlaves = settings.autoCloseLootWindowOnSlaves
		AJM.db.advancedLootItems = JambaUtilities:CopyTable( settings.advancedLootItems )
		
		AJM:SetAutoLoot()
		
		-- Refresh the settings.
		AJM:SettingsRefresh()
		-- Tell the player.
		AJM:Print( L["Settings received from A."]( characterName ) )
	end
end

-------------------------------------------------------------------------------------------------------------
-- Settings Dialogs.
-------------------------------------------------------------------------------------------------------------

local function SettingsCreateOptions( top )
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
	local left2 = left + halfWidth + horizontalSpacing
	local movingTop = top
	JambaHelperSettings:CreateHeading( AJM.settingsControl, L["Advanced Loot Items"], movingTop, false )
	movingTop = movingTop - headingHeight
	AJM.settingsControl.checkBoxAdvancedLoot = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		halfWidth, 
		left, 
		movingTop, 
		L["Enable Advanced Loot"],
		AJM.SettingsToggleAdvancedLootItems
	)	
	AJM.settingsControl.checkBoxManageAutoLoot = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		halfWidth, 
		left2, 
		movingTop, 
		L["Manage Auto Loot"],
		AJM.SettingsToggleAdvancedLootManageAutoLoot
	)	
	movingTop = movingTop - checkBoxHeight		
	AJM.settingsControl.checkBoxAutoCloseLootWindowOnSlaves = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		halfWidth, 
		left, 
		movingTop, 
		L["Auto Close Loot Window On Slaves"],
		AJM.SettingsToggleAutoCloseLootWindowOnSlaves
	)	
	movingTop = movingTop - checkBoxHeight	
	AJM.settingsControl.advancedLootHighlightRow = 1
	AJM.settingsControl.advancedLootOffset = 1
	local list = {}
	list.listFrameName = "JambaAdvancedLootSettingsFrame"
	list.parentFrame = AJM.settingsControl.widgetSettings.content
	list.listTop = movingTop
	list.listLeft = left
	list.listWidth = headingWidth
	list.rowHeight = 20
	list.rowsToDisplay = 8
	list.columnsToDisplay = 2
	list.columnInformation = {}
	list.columnInformation[1] = {}
	list.columnInformation[1].width = 60
	list.columnInformation[1].alignment = "LEFT"
	list.columnInformation[2] = {}
	list.columnInformation[2].width = 30
	list.columnInformation[2].alignment = "LEFT"		
	list.scrollRefreshCallback = AJM.SettingsScrollRefresh
	list.rowClickCallback = AJM.SettingsRowClick
	AJM.settingsControl.list = list
	JambaHelperSettings:CreateScrollList( AJM.settingsControl.list )
	movingTop = movingTop - list.listHeight - verticalSpacing
	AJM.settingsControl.buttonRemove = JambaHelperSettings:CreateButton(
		AJM.settingsControl, 
		buttonControlWidth, 
		left, 
		movingTop,
		L["Remove"],
		AJM.SettingsRemoveClick
	)
	movingTop = movingTop -	buttonHeight - verticalSpacing
	JambaHelperSettings:CreateHeading( AJM.settingsControl, L["Add Item"], movingTop, false )
	movingTop = movingTop - headingHeight
	AJM.settingsControl.editBoxItem = JambaHelperSettings:CreateEditBox( 
		AJM.settingsControl,
		headingWidth,
		left,
		movingTop,
		L["Item (drag item to box from your bags)"]
	)
	AJM.settingsControl.editBoxItem:SetCallback( "OnEnterPressed", AJM.SettingsEditBoxChangedItem )
	movingTop = movingTop - editBoxHeight
	AJM.settingsControl.dropdownCharacterName = JambaHelperSettings:CreateDropdown( 
		AJM.settingsControl, 
		halfWidth, 
		left, 
		movingTop, 
		L["Character Name"] 
	)
	AJM.settingsControl.dropdownCharacterName:SetList( AJM:GetTeamList() )
	AJM.settingsControl.dropdownCharacterName:SetCallback( "OnValueChanged", AJM.SettingsSetCharacterName )
	movingTop = movingTop - dropdownHeight - verticalSpacing	
	AJM.settingsControl.buttonAdd = JambaHelperSettings:CreateButton(	
		AJM.settingsControl, 
		buttonControlWidth, 
		left, 
		movingTop, 
		L["Add"],
		AJM.SettingsAddClick
	)
	movingTop = movingTop -	buttonHeight	
	JambaHelperSettings:CreateHeading( AJM.settingsControl, L["Advanced Loot Messages"], movingTop, false )
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

local function SettingsCreate()
	AJM.settingsControl = {}
	JambaHelperSettings:CreateSettings( 
		AJM.settingsControl, 
		AJM.moduleDisplayName, 
		AJM.parentDisplayName, 
		AJM.SettingsPushSettingsClick 
	)
	local bottomOfSettings = SettingsCreateOptions( JambaHelperSettings:TopOfSettings() )
	AJM.settingsControl.widgetSettings.content:SetHeight( -bottomOfSettings )
	-- Help
	local helpTable = {}
	JambaHelperSettings:CreateHelp( AJM.settingsControl, helpTable, AJM:GetConfiguration() )		
end

-------------------------------------------------------------------------------------------------------------
-- Settings Callbacks.
-------------------------------------------------------------------------------------------------------------

function AJM:SettingsScrollRefresh()
	FauxScrollFrame_Update(
		AJM.settingsControl.list.listScrollFrame, 
		AJM:GetItemsMaxPosition(),
		AJM.settingsControl.list.rowsToDisplay, 
		AJM.settingsControl.list.rowHeight
	)
	AJM.settingsControl.advancedLootOffset = FauxScrollFrame_GetOffset( AJM.settingsControl.list.listScrollFrame )
	for iterateDisplayRows = 1, AJM.settingsControl.list.rowsToDisplay do
		-- Reset.
		AJM.settingsControl.list.rows[iterateDisplayRows].columns[1].textString:SetText( "" )
		AJM.settingsControl.list.rows[iterateDisplayRows].columns[1].textString:SetTextColor( 1.0, 1.0, 1.0, 1.0 )
		AJM.settingsControl.list.rows[iterateDisplayRows].columns[2].textString:SetText( "" )
		AJM.settingsControl.list.rows[iterateDisplayRows].columns[2].textString:SetTextColor( 1.0, 1.0, 1.0, 1.0 )			
		AJM.settingsControl.list.rows[iterateDisplayRows].highlight:SetTexture( 0.0, 0.0, 0.0, 0.0 )
		-- Get data.
		local dataRowNumber = iterateDisplayRows + AJM.settingsControl.advancedLootOffset
		if dataRowNumber <= AJM:GetItemsMaxPosition() then
			-- Put data information into columns.
			local itemInformation = AJM:GetItemAtPosition( dataRowNumber )
			AJM.settingsControl.list.rows[iterateDisplayRows].columns[1].textString:SetText( itemInformation.name )
			AJM.settingsControl.list.rows[iterateDisplayRows].columns[2].textString:SetText( itemInformation.characterName )
			-- Highlight the selected row.
			if dataRowNumber == AJM.settingsControl.advancedLootHighlightRow then
				AJM.settingsControl.list.rows[iterateDisplayRows].highlight:SetTexture( 1.0, 1.0, 0.0, 0.5 )
			end
		end
	end
end

function AJM:SettingsRowClick( rowNumber, columnNumber )		
	if AJM.settingsControl.advancedLootOffset + rowNumber <= AJM:GetItemsMaxPosition() then
		AJM.settingsControl.advancedLootHighlightRow = AJM.settingsControl.advancedLootOffset + rowNumber
		AJM:SettingsScrollRefresh()
	end
end

function AJM:SettingsPushSettingsClick( event )
	AJM:JambaSendSettings()
end

function AJM:SettingsSetMessageArea( event, value )
	AJM.db.messageArea = value
	AJM:SettingsRefresh()
end

function AJM:SettingsSetCharacterName( event, value )
	AJM.advancedLootItemCharacterName = value
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleAdvancedLootItems( event, checked )
	AJM.db.advancedLoot = checked
	
	AJM:SetAutoLoot()
	
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleAdvancedLootManageAutoLoot( event, checked )
	AJM.db.manageAutoLoot = checked
	
	AJM:SetAutoLoot()
	
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleAutoCloseLootWindowOnSlaves( event, checked )
	AJM.db.autoCloseLootWindowOnSlaves = checked
	
	AJM:SettingsRefresh()
end

function AJM:SettingsRemoveClick( event )
	StaticPopup_Show( "JAMBAADVANCEDLOOT_CONFIRM_REMOVE_ADVANCEDLOOT_ITEM" )
end

function AJM:SettingsEditBoxChangedItem( event, text )
	AJM.advancedLootItemLink = text
	AJM:SettingsRefresh()
end

function AJM:SettingsAddClick( event )
	if AJM.advancedLootItemLink ~= nil and AJM.advancedLootItemCharacterName ~= nil then
		if AJM:GetAdvancedLootCharacterName(AJM.advancedLootItemLink) == nil then
			AJM:AddItem( AJM.advancedLootItemLink, AJM.advancedLootItemCharacterName )
			AJM.advancedLootItemLink = nil
			AJM.settingsControl.editBoxItem:SetText( "" )
			AJM:SettingsRefresh()
		end
	end
end

-------------------------------------------------------------------------------------------------------------
-- Popup Dialogs.
-------------------------------------------------------------------------------------------------------------

-- Initialize Popup Dialogs.
local function InitializePopupDialogs()
	StaticPopupDialogs["JAMBAADVANCEDLOOT_CONFIRM_REMOVE_ADVANCEDLOOT_ITEM"] = {
        text = L["Are you sure you wish to remove the selected item from the advanced loot items list?"],
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
	--AJM.advancedLootItemCharacter = JambaApi.AllTag()
	AJM.advancedLootItemLink = nil
	-- Create the settings control.
	SettingsCreate()
	-- Initialise the JambaModule part of this module.
	AJM:JambaModuleInitialize( AJM.settingsControl.widgetSettings.frame )
	-- Initialise the popup dialogs.
	InitializePopupDialogs()		
	-- Populate the settings.
	AJM:SettingsRefresh()
	-- Create a standalone window for the Advanced Loot.
	--[[
	AJM.standaloneWindow = AceGUI:Create( "Window" )
	AJM.standaloneWindow:Hide()
	AJM.standaloneWindow:SetTitle( "Jamba-AdvancedLoot" )
	AJM.standaloneWindow:SetLayout( "Fill" )
	AJM.standaloneWindow:AddChild( AJM.settingsControl.widgetSettings )
	AJM.standaloneWindow:SetHeight( 410 )
	AJM.standaloneWindow:SetWidth( 410 )
	AJM.standaloneWindow.frame:SetFrameStrata( "HIGH" )
	]]--
end

-- Called when the addon is enabled.
function AJM:OnEnable()
	AJM:SetAutoLoot()
	AJM:RegisterEvent( "LOOT_OPENED" )
	AJM:RegisterEvent( "GROUP_ROSTER_UPDATE" )
	AJM:RegisterMessage( JambaApi.MESSAGE_MESSAGE_AREAS_CHANGED, "OnMessageAreasChanged" )
end

-- Called when the addon is disabled.
function AJM:OnDisable()
	AJM:DisableAutoLoot()
end

-------------------------------------------------------------------------------------------------------------
-- JambaAdvancedLoot functionality.
-------------------------------------------------------------------------------------------------------------

function AJM:OnMessageAreasChanged( message )
	AJM.settingsControl.dropdownMessageArea:SetList( JambaApi.MessageAreaList() )
end

function AJM:GetTeamList()
	JambaUtilities:ClearTable( AJM.simpleTeamList )
	for characterName, characterPosition in JambaApi.TeamList() do
		AJM.simpleTeamList[characterName] = characterName
	end
	table.sort( AJM.simpleTeamList )
	return AJM.simpleTeamList
end

function AJM:ShowPopOutWindow()
	--AJM.standaloneWindow:Show()
end

function AJM:GetItemsMaxPosition()
	return #AJM.db.advancedLootItems
end

function AJM:GetItemAtPosition( position )
	return AJM.db.advancedLootItems[position]
end

function AJM:AddItem( itemLink, characterName )
	-- Get some more information about the item.
	local name, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo( itemLink )
	-- If the item could be found.
	if name ~= nil then
		local itemInformation = {}
		itemInformation.link = itemLink
		itemInformation.name = name
		itemInformation.characterName = characterName
		table.insert( AJM.db.advancedLootItems, itemInformation )
		AJM:SettingsRefresh()			
		AJM:SettingsRowClick( 1, 1 )
	end	
end

function AJM:RemoveItem()
	table.remove( AJM.db.advancedLootItems, AJM.settingsControl.advancedLootHighlightRow )
	AJM:SettingsRefresh()
	AJM:SettingsRowClick( 1, 1 )		
end

function AJM:SetAutoLoot()
	if (AJM.db.advancedLoot) then
		if GetNumGroupMembers() == 0 then
			AJM:EnableAutoLoot()
		else
			AJM:DisableAutoLoot()
		end
	else
		AJM:EnableAutoLoot()
	end
end

function AJM:EnableAutoLoot()
	if (AJM.db.manageAutoLoot) then
		SetCVar( "autoLootDefault", 1 );
	end
end

function AJM:DisableAutoLoot()
	if (AJM.db.manageAutoLoot) then
		SetCVar( "autoLootDefault", 0 );
	end
end

function AJM:GROUP_ROSTER_UPDATE( event, ... )
	AJM:SetAutoLoot()
end

function AJM:LOOT_OPENED()
	if AJM.db.advancedLoot == true then
		AJM:DoAdvancedLoot()
	end
end

-- A Jamba command has been recieved.
function AJM:JambaOnCommandReceived( characterName, commandName, ... )
end

function AJM:GetAdvancedLootCharacterName(iteminfo)

	local returnCharacterName = nil

	local itemNameToFind = GetItemInfo( iteminfo )
	
	for position, itemInfoTable in pairs( AJM.db.advancedLootItems ) do	
		local characterName = itemInfoTable.characterName
		local advancedLootItemLink = itemInfoTable.link
		
		local itemNameAdvancedLoot = GetItemInfo( advancedLootItemLink )
			if itemNameAdvancedLoot == itemNameToFind then
				returnCharacterName = characterName;
				break
			end
	end
	
	return returnCharacterName;
end

function AJM:DoAdvancedLoot()

	if IsInGroup() then

		local numloot = GetNumLootItems()
		if numloot == 0 then 
		pcall(CloseLoot)
			return nil 
		end

		local itemsAlerted = {}
		local itemsAlertedCount = 1
		
		local tries = 0

		-- seems to get itself stuck when it only runs once... this is intended to allow a few times
		-- through while the others are looting just in case.
		while tries < 20 and numloot > 0 do
		  
			for slot = 1, numloot do
			
				lootme = false

				local _, icon, name, quantity, quality, locked, isQuestItem, questId, isActive = pcall(GetLootSlotInfo, slot)
			
				if icon then

					if GetLootSlotType(slot) == LOOT_SLOT_MONEY then
						lootme = true
					end
							
					if not lootme and isQuestItem then
						lootme = true;
					end
				
					local is_item, link2 = (GetLootSlotType(slot) == LOOT_SLOT_ITEM)
					if not lootme and is_item then
							
						link = GetLootSlotLink(slot)
					
						local advancedLootCharacterName = AJM:GetAdvancedLootCharacterName(link);
						
						if advancedLootCharacterName ~= nil then
							if advancedLootCharacterName == AJM.characterName then
								lootme = true
							else
							
								local sName, sLink, iRarity, iLevel, iMinLevel, sType, sSubType, iStackCount = GetItemInfo(link);
								local alreadyAlerted = false;
							
								for i = 1, itemsAlertedCount do
									if itemsAlerted[i] == sName then
										alreadyAlerted = true
									end
								end
								
								if (not alreadyAlerted) then
								
									AJM:JambaSendMessageToTeam( AJM.db.messageArea, L["GOTTA LOOT A FROM B."]( sName, advancedLootCharacterName ), false )
									
									itemsAlerted[itemsAlertedCount] = sName
									itemsAlertedCount = itemsAlertedCount + 1
								end
							end								
						else
							lootme = true
						end					
					end
						
					if lootme then
						LootSlot(slot)
					end
				end
			end
			numloot = GetNumLootItems()
			tries = tries + 1
		end

		if AJM.db.autoCloseLootWindowOnSlaves == true then
			if JambaApi.IsCharacterTheMaster( AJM.characterName ) ~= true then
				pcall(CloseLoot)
			end
		end
		
	end
end


