--[[
Jamba - Jafula's Awesome Multi-Boxer Assistant
Copyright 2008 - 2018 Michael "Jafula" Miller
License: The MIT License
]]--

-- Create the addon using AceAddon-3.0 and embed some libraries.
local AJM = LibStub( "AceAddon-3.0" ):NewAddon( 
	"JambaItemUse", 
	"JambaModule-1.0", 
	"AceConsole-3.0", 
	"AceEvent-3.0",
	"AceTimer-3.0"
)

-- Get the Jamba Utilities Library.
local JambaUtilities = LibStub:GetLibrary( "JambaUtilities-1.0" )
local JambaHelperSettings = LibStub:GetLibrary( "JambaHelperSettings-1.0" )
--local LibBagUtils = LibStub:GetLibrary( "LibBagUtils-1.0" )
--local LibGratuity = LibStub( "LibGratuity-3.0" )
local LibActionButton = LibStub( "LibActionButtonJamba-1.0" )
local tooltipName = "AJMScanner"
local tooltipScanner = CreateFrame("GameTooltip", tooltipName, nil, "GameTooltipTemplate")
AJM.SharedMedia = LibStub( "LibSharedMedia-3.0" )

--  Constants and Locale for this module.
AJM.moduleName = "Jamba-ItemUse"
AJM.settingsDatabaseName = "JambaItemUseProfileDB"
AJM.chatCommand = "jamba-item-use"
local L = LibStub( "AceLocale-3.0" ):GetLocale( AJM.moduleName )
AJM.parentDisplayName = L["Interaction"]
AJM.moduleDisplayName = L["Item Use"]

-- Jamba key bindings.
BINDING_HEADER_JAMBAITEMUSE = L["Jamba-Item-Use"]
BINDING_NAME_JAMBAITEMUSE1 = L["Item 1"]
BINDING_NAME_JAMBAITEMUSE2 = L["Item 2"]
BINDING_NAME_JAMBAITEMUSE3 = L["Item 3"]
BINDING_NAME_JAMBAITEMUSE4 = L["Item 4"]
BINDING_NAME_JAMBAITEMUSE5 = L["Item 5"]
BINDING_NAME_JAMBAITEMUSE6 = L["Item 6"]
BINDING_NAME_JAMBAITEMUSE7 = L["Item 7"]
BINDING_NAME_JAMBAITEMUSE8 = L["Item 8"]
BINDING_NAME_JAMBAITEMUSE9 = L["Item 9"]
BINDING_NAME_JAMBAITEMUSE10 = L["Item 10"]
BINDING_NAME_JAMBAITEMUSE11 = L["Item 11"]
BINDING_NAME_JAMBAITEMUSE12 = L["Item 12"]
BINDING_NAME_JAMBAITEMUSE13 = L["Item 13"]
BINDING_NAME_JAMBAITEMUSE14 = L["Item 14"]
BINDING_NAME_JAMBAITEMUSE15 = L["Item 15"]
BINDING_NAME_JAMBAITEMUSE16 = L["Item 16"]
BINDING_NAME_JAMBAITEMUSE17 = L["Item 17"]
BINDING_NAME_JAMBAITEMUSE18 = L["Item 18"]
BINDING_NAME_JAMBAITEMUSE19 = L["Item 19"]
BINDING_NAME_JAMBAITEMUSE20 = L["Item 20"]

-- Settings - the values to store and their defaults for the settings database.
AJM.settings = {
	profile = {
		showItemUse = true,
		showItemUseOnMasterOnly = true,
		hideItemUseInCombat = false,
		borderStyle = L["Blizzard Tooltip"],
		backgroundStyle = L["Blizzard Dialog Background"],
		itemUseScale = 1,
		itemUseTitleHeight = 3,
		itemUseVerticalSpacing = 3,
		itemUseHorizontalSpacing = 2,
		autoAddQuestItemsToBar = true,
		autoAddArtifactItemsToBar = true,
		autoAddSatchelsItemsToBar = true,
		hideClearButton = false,
		itemBarsSynchronized = true,
		numberOfItems = 10,
		numberOfRows = 2,
		messageArea = JambaApi.DefaultWarningArea(),
		itemsAdvanced = {},
		framePoint = "BOTTOMRIGHT",
		frameRelativePoint = "BOTTOMRIGHT",
		frameXOffset = 0,
		frameYOffset = 0,
		frameAlpha = 1.0,
		frameBackgroundColourR = 1.0,
		frameBackgroundColourG = 1.0,
		frameBackgroundColourB = 1.0,
		frameBackgroundColourA = 1.0,
		frameBorderColourR = 1.0,
		frameBorderColourG = 1.0,
		frameBorderColourB = 1.0,
		frameBorderColourA = 1.0,		
	},
}

-- Configuration.
function AJM:GetConfiguration()
	local configuration = {
		name = AJM.moduleDisplayName,
		handler = AJM,
		type = 'group',
		args = {	
			push = {
				type = "input",
				name = L["Push Settings"],
				desc = L["Push the item use settings to all characters in the team."],
				usage = "/jamba-item-use push",
				get = false,
				set = "JambaSendSettings",
			},											
			hide = {
				type = "input",
				name = L["Hide Item Bar"],
				desc = L["Hide the item bar panel."],
				usage = "/jamba-item-use hide",
				get = false,
				set = "HideItemUseCommand",
			},	
			show = {
				type = "input",
				name = L["Show Item Bar"],
				desc = L["Show the item bar panel."],
				usage = "/jamba-item-use show",
				get = false,
				set = "ShowItemUseCommand",
			},
			clear = {
				type = "input",
				name = L["Clear Item Bar"],
				desc = L["Clear the item bar (remove all items)."],
				usage = "/jamba-item-use clear",
				get = false,
				set = "ClearItemUseCommand",
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

AJM.COMMAND_ITEMBAR_BUTTON = "JambaCommandItemBarButton"
AJM.COMMAND_ITEMUSE_SYNC = "JambaCommandItemBarSync"

-------------------------------------------------------------------------------------------------------------
-- Messages module sends.
-------------------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------------------------
-- Variables used by module.
-------------------------------------------------------------------------------------------------------------

AJM.globalFramePrefix = "JambaItemUse"
AJM.itemContainer = {}
AJM.itemUseCreated = false	
AJM.itemSize = 40
AJM.refreshItemUseControlsPending = false
AJM.refreshUpdateItemsInBarPending = false
AJM.refreshUpdateBindingsPending = false
AJM.updateSettingsAfterCombat = false
AJM.maximumNumberOfItems = 20
AJM.maximumNumberOfRows = 20

-------------------------------------------------------------------------------------------------------------
-- Item Bar.
-------------------------------------------------------------------------------------------------------------

local function CanDisplayItemUse()
	local canShow = false
	if AJM.db.showItemUse == true then
		if AJM.db.showItemUseOnMasterOnly == true then
			if JambaApi.IsCharacterTheMaster( AJM.characterName ) == true then
				canShow = true
			end
		else
			canShow = true
		end
	end
	return canShow
end

local function CreateJambaItemUseFrame()
	-- The frame.	
	local frame = CreateFrame( "Frame", "JambaItemUseWindowFrame", UIParent, "SecureHandlerStateTemplate" )
	RegisterStateDriver(JambaItemUseWindowFrame, "page", "[mod:alt]0;0")
	JambaItemUseWindowFrame:SetAttribute("_onstate-page", [[
		self:SetAttribute("state", newstate)
		control:ChildUpdate("state", newstate)
	]])
	frame.parentObject = AJM
	frame:SetFrameStrata( "LOW" )
	frame:SetToplevel( true )
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
			AJM.db.framePoint = point
			AJM.db.frameRelativePoint = relativePoint
			AJM.db.frameXOffset = xOffset
			AJM.db.frameYOffset = yOffset
		end	)	
	-- Artifact Remove Buttion
		local updateButton = CreateFrame( "Button", "ButtonUpdate", frame, "UIPanelButtonTemplate" )
		updateButton:SetScript( "OnClick", function() AJM:ClearButton() end )
		updateButton:SetPoint( "TOPRIGHT", frame, "TOPRIGHT", -4, -3 )
		updateButton:SetHeight( 20 )
		updateButton:SetWidth( 65 )
		updateButton:SetText( L["Clear"] )	
		updateButton:SetScript("OnEnter", function(self) AJM:ShowTooltip(updateButton, "clear", true) end)
		updateButton:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
		ClearUpdateButton = updateButton
	-- Sync Button	
		local syncButton = CreateFrame( "Button", "ButtonSync", frame, "UIPanelButtonTemplate" )
		syncButton:SetScript( "OnClick", function() AJM:SyncButton() end )
		syncButton:SetPoint( "TOPRIGHT", frame, "TOPRIGHT", -71, -3 )
		syncButton:SetHeight( 20 )
		syncButton:SetWidth( 65 )
		syncButton:SetText( L["Sync"] )	
		syncButton:SetScript("OnEnter", function(self) AJM:ShowTooltip(updateButton, "sync", true) end)
		syncButton:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
		SyncUpdateButton = syncButton
	frame:ClearAllPoints()
	frame:SetPoint( AJM.db.framePoint, UIParent, AJM.db.frameRelativePoint, AJM.db.frameXOffset, AJM.db.frameYOffset )
	frame:SetBackdrop( {
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", 
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", 
		tile = true, tileSize = 10, edgeSize = 10, 
		insets = { left = 3, right = 3, top = 3, bottom = 3 }
	} )
	-- Set transparency of the the frame (and all its children).
	frame:SetAlpha(AJM.db.frameAlpha)
	-- Set the global frame reference for this frame.
	JambaItemUseFrame = frame
	-- Remove unsued items --test
	AJM:SettingsUpdateBorderStyle()	
	AJM.itemUseCreated = true
	AJM.UpdateHeight()
end

function AJM:ShowTooltip(frame, info, show)
	if show then
		GameTooltip:SetOwner(frame, "ANCHOR_TOP")
		GameTooltip:SetPoint("TOPLEFT", frame, "TOPRIGHT", 16, 0)
		GameTooltip:ClearLines()
		if info == "clear" then
		GameTooltip:AddLine(L["Clears items no longer in your bags"], 1, 0.82, 0, 1)
		elseif info == "sync" then
		GameTooltip:AddLine(L["Synchronise Item-Use Buttons"], 1, 0.82, 0, 1)
		end
		GameTooltip:Show()
	else
	GameTooltip:Hide()
	end
end


function AJM:UpdateHeight()											  
	if AJM.db.hideClearButton == false then
		AJM.db.itemUseTitleHeight = 2
		local newHeight = AJM.db.itemUseTitleHeight + 20
		ClearUpdateButton:Show()
		SyncUpdateButton:Show()
		return newHeight	
	else
		AJM.db.itemUseTitleHeight = 2
		oldHeight = AJM.db.itemUseTitleHeight
		ClearUpdateButton:Hide()
		SyncUpdateButton:Hide()
		return oldHeight
	end	
end


function AJM:ShowItemUseCommand()
	AJM.db.showItemUse = true
	AJM:SetItemUseVisibility()
	AJM:SettingsRefresh()
end

function AJM:HideItemUseCommand()
	AJM.db.showItemUse = false
	AJM:SetItemUseVisibility()
	AJM:SettingsRefresh()
end

function AJM:ClearItemUseCommand()
	JambaUtilities:ClearTable(AJM.db.itemsAdvanced)
	AJM:SettingsRefresh()
	AJM:Print(L["Item Bar Cleared"])
end

function AJM:SetItemUseVisibility()
	if CanDisplayItemUse() == true then
		JambaItemUseFrame:ClearAllPoints()
		JambaItemUseFrame:SetPoint( AJM.db.framePoint, UIParent, AJM.db.frameRelativePoint, AJM.db.frameXOffset, AJM.db.frameYOffset )
		JambaItemUseFrame:SetAlpha( AJM.db.frameAlpha )
		JambaItemUseFrame:Show()
	else
		JambaItemUseFrame:Hide()
	end	
end

function AJM:SettingsUpdateBorderStyle()
	local borderStyle = AJM.SharedMedia:Fetch( "border", AJM.db.borderStyle )
	local backgroundStyle = AJM.SharedMedia:Fetch( "background", AJM.db.backgroundStyle )
	local frame = JambaItemUseFrame
	frame:SetBackdrop( {
		bgFile = backgroundStyle, 
		edgeFile = borderStyle, 
		tile = true, tileSize = frame:GetWidth(), edgeSize = 10, 
		insets = { left = 3, right = 3, top = 3, bottom = 3 }
	} )
	frame:SetBackdropColor( AJM.db.frameBackgroundColourR, AJM.db.frameBackgroundColourG, AJM.db.frameBackgroundColourB, AJM.db.frameBackgroundColourA )
	frame:SetBackdropBorderColor( AJM.db.frameBorderColourR, AJM.db.frameBorderColourG, AJM.db.frameBorderColourB, AJM.db.frameBorderColourA )		
end

-- updates after the quest has been handed in,
function AJM:UpdateQuestItemsInBar()
	local state = "0"
	for iterateItems = 1, AJM.maximumNumberOfItems, 1 do
		local itemContainer = AJM.itemContainer[iterateItems]
		if itemContainer == nil then
			AJM:CreateJambaItemUseItemContainer( iterateItems, parentFrame )
			itemContainer = AJM.itemContainer[iterateItems]
		end
		local containerButton = itemContainer["container"]
		local itemInfo = AJM:GetItemFromItemDatabase( iterateItems )
		local kind = itemInfo.kind
		local action = itemInfo.action
		if kind == "item" then
			local itemLink,_,_,_,_,questItem = GetItemInfo( action )
			--AJM:Print("Checking Item...", itemLink, action)
			if questItem == "Quest" then
				if JambaApi.IsCharacterTheMaster( AJM.characterName ) == true then
					if AJM:IsInInventory( itemLink ) == false then
					--AJM:Print("NOT IN BAGS", itemLink)
						AJM.db.itemsAdvanced[iterateItems] = nil	
						AJM:JambaSendUpdate( iterateItems, "empty", nil )
						--AJM:JambaSendSettings()						
					end
				end	
			end
		end
	end	
end	

function AJM:UpdateItemsInBar()
	local state = "0"
    local parentFrame = JambaItemUseFrame
	for iterateItems = 1, AJM.maximumNumberOfItems, 1 do
		local itemContainer = AJM.itemContainer[iterateItems]
		if itemContainer == nil then
			AJM:CreateJambaItemUseItemContainer( iterateItems, parentFrame )
			itemContainer = AJM.itemContainer[iterateItems]
		end
		local containerButton = itemContainer["container"]
		local itemInfo = AJM:GetItemFromItemDatabase( iterateItems )
		local kind = itemInfo.kind
		local action = itemInfo.action
		if kind == "item" and not tonumber( action ) then
			action = action:sub(6)
		end
        --AJM:Print(state, kind, action)
		if kind == "mount" or kind == "battlepet" then
            containerButton:ClearStates()
		else
		containerButton:SetState(state, kind, action)
        end
	end
end

function AJM:AddItemToItemDatabase( itemNumber, kind, action )
    if kind == "mount" or kind == "battlepet" then
        return
    end
	if AJM.db.itemsAdvanced[itemNumber] == nil then
		AJM.db.itemsAdvanced[itemNumber] = {}
	end
	AJM.db.itemsAdvanced[itemNumber].kind = kind
	AJM.db.itemsAdvanced[itemNumber].action = action
end

function AJM:GetItemFromItemDatabase( itemNumber )
	if AJM.db.itemsAdvanced[itemNumber] == nil then
		AJM.db.itemsAdvanced[itemNumber] = {}
		AJM.db.itemsAdvanced[itemNumber].kind = "empty"
		AJM.db.itemsAdvanced[itemNumber].action = "empty"
	end
	return AJM.db.itemsAdvanced[itemNumber]
end

function AJM:OnButtonContentsChanged( event, button, state, type, value, ... )
    if type == "mount" or type == "battlepet" then
		return
    end
    AJM:AddItemToItemDatabase( button.itemNumber, type, value )
    AJM:JambaSendUpdate(button.itemNumber, type, value )
	--AJM:JambaSendSettings()
	AJM:SettingsRefresh()
end

function AJM:OnButtonUpdate( event, button, ... )
	--AJM:Print( event, button, ...)
end

function AJM:OnButtonState( event, button, ... )
	--AJM:Print( event, button, ...)
end

function AJM:OnButtonUsable( event, button, ... )
	--AJM:Print( event, button, ...)
end

function AJM:CreateJambaItemUseItemContainer( itemNumber, parentFrame )
	AJM.itemContainer[itemNumber] = {}
	local itemContainer = AJM.itemContainer[itemNumber]
	local containerButtonName = AJM.globalFramePrefix.."ContainerButton"..itemNumber
    local buttonConfig = {
        outOfRangeColoring = "button",
        tooltip = "enabled",
        showGrid = true,
        colors = {
            range = { 0.8, 0.1, 0.1 },
            mana = { 0.5, 0.5, 1.0 }
        },
        hideElements = {
            macro = false,
            hotkey = false,
            equipped = false,
        },
        keyBoundTarget = false,
        clickOnDown = false,
        flyoutDirection = "UP",
    }
	local containerButton = LibActionButton:CreateButton( itemNumber, containerButtonName, JambaItemUseWindowFrame, buttonConfig )
	containerButton:SetState( "0", "empty", nil)
	containerButton.itemNumber = itemNumber
	itemContainer["container"] = containerButton	
end

--ebony test Using the wowapi and not the scanning of tooltips
function AJM:CheckForQuestItemAndAddToBar()
	--[[
	for bag = 0,4,1 do 
		for slot = 1,GetContainerNumSlots(bag),1 do 
			local IsQuestItem,StartsQuest,_ = GetContainerItemQuestInfo(bag,slot)
			local _,_,_,_,readable,_,itemLink = GetContainerItemInfo(bag,slot) -- readable???
				-- Quests now auto get started since 7.1 kinda making this usless.
				--if not IsQuestItem and StartsQuest then
					--local itemString = GetItemInfo(itemLink)
					--AJM:AddAnItemToTheBarIfNotExists( itemLink, true)
				--end
			end
		end
	]]		
	for iterateQuests=1,GetNumQuestLogEntries() do
	local questLogTitleText,_,_,_,isHeader = GetQuestLogTitle(iterateQuests)
		if not isHeader then
			local questItemLink, questItemIcon, questItemCharges = GetQuestLogSpecialItemInfo( iterateQuests )
			if questItemLink  then
				local itemName = GetItemInfo(questItemLink)
				local questname,rank = GetItemSpell(questItemLink) -- Only means to detect if the item is usable
				if questname then
					if JambaUtilities:DoItemLinksContainTheSameItem( questItemLink, questItemLink ) == true then
						--AJM:Print("addItem", questItemLink )
						AJM:AddAnItemToTheBarIfNotExists( questItemLink, false)				
					end				
				end
			end
		end
	end
end

-- Add satchels to item bar.
function AJM:CheckForSatchelsItemAndAddToBar()
	for bag = 0, NUM_BAG_SLOTS do
		for slot = 1, GetContainerNumSlots(bag) do
			local texture, count, locked, quality, readable, lootable, link, isFiltered, hasNoValue, itemID = GetContainerItemInfo(bag, slot)
			if link and lootable then
				--AJM:Print("test", link)	
				tooltipScanner:SetOwner(UIParent, "ANCHOR_NONE")
				tooltipScanner:SetHyperlink(link)
				--AJM:Print("scanTooltip", link) -- Debug
				local tooltipText = _G[tooltipName.."TextLeft2"]:GetText()
				--AJM:Print("tooltiptest", link, tooltipText) -- Debug
				if tooltipText ~= "Locked" then
					--AJM:Print("Not Locked", link)
					--AJM:Print("satchelsFound", link)
					AJM:AddAnItemToTheBarIfNotExists( link, false )
				end
			end
		end
	end
end	

-- Removes unused items.

function AJM:ClearButton()
	local state = "0"
	for iterateItems = 1, AJM.db.numberOfItems, 1 do
		local itemContainer = AJM.itemContainer[iterateItems]
		if itemContainer == nil then
			AJM:CreateJambaItemUseItemContainer( iterateItems, parentFrame )
			itemContainer = AJM.itemContainer[iterateItems]
		end
		local containerButton = itemContainer["container"]
		local itemInfo = AJM:GetItemFromItemDatabase( iterateItems )
		local kind = itemInfo.kind
		local action = itemInfo.action
		if kind == "item" then
			local name, itemLink,_,_,_,itemType,questItem = GetItemInfo( action )
			if itemLink and itemLink:match("item:%d") then
				tooltipScanner:SetOwner(UIParent, "ANCHOR_NONE")
				tooltipScanner:SetHyperlink(itemLink)
				--AJM:Print("scanTooltip", itemLink)
				local tooltipText = _G[tooltipName.."TextLeft3"]:GetText()
				--AJM:Print("tooltiptest", tooltipText, tooltipTextTwo)
				if tooltipText == nil or tooltipText ~= "Unique" then
					--AJM:Print("testWorks!", itemLink)
					if AJM:IsInInventory( name ) == false then
						--AJM:Print("NOT IN BAGS", itemLink)
						AJM.db.itemsAdvanced[iterateItems] = nil
						AJM:JambaSendUpdate( iterateItems, "empty", nil	)
						AJM:SettingsRefresh()
					end		
				end
			end					
		end
	end	
end

-- Sync Buttion
function AJM:SyncButton()
	local dataTable = {}
	for iterateItems = 1, AJM.db.numberOfItems, 1 do
	local itemContainer = AJM.itemContainer[iterateItems]
		if itemContainer == nil then
			AJM:CreateJambaItemUseItemContainer( iterateItems, parentFrame )
			itemContainer = AJM.itemContainer[iterateItems]
		end
			local containerButton = itemContainer["container"]
			local itemInfo = AJM:GetItemFromItemDatabase( iterateItems )
			local kind = itemInfo.kind
			local action = itemInfo.action
			data = {}
			data.button = iterateItems
			data.type = kind
			data.action = action
			table.insert( dataTable, data )
	end
	AJM:JambaSendCommandToTeam( AJM.COMMAND_ITEMUSE_SYNC, dataTable)
end


-- Adds artifact power items to item bar.
function AJM:CheckForArtifactItemAndAddToBar()
	for bag = 0, NUM_BAG_SLOTS do
		for slot = 1, GetContainerNumSlots(bag) do
			local itemLink = GetContainerItemLink(bag, slot)
			--AJM:Print("bagcheck", itemLink)
			if itemLink and itemLink:match("item:%d") then
				tooltipScanner:SetOwner(UIParent, "ANCHOR_NONE")
				tooltipScanner:SetHyperlink(itemLink)
				--AJM:Print("scanTooltip", itemLink)
				local tooltipText = _G[tooltipName.."TextLeft2"]:GetText()
				if tooltipText and tooltipText:match(ARTIFACT_POWER) then
					--AJM:Print("artifactPowerFound", itemLink)
					AJM:AddAnItemToTheBarIfNotExists( itemLink, false )
				end
			end
		end
	end
end		
	
--Checks the item is in the Toon players bag
function AJM:IsInInventory(itemLink)
	for bag = 0,4,1 do 
		for slot = 1,GetContainerNumSlots(bag),1 do 
			--AJM:Debug( "Bags OK. checking", itemLink )
			local _,_,_,_,_,_,_,_,_,Link = GetContainerItemInfo(bag,slot)
			if Link then
				--AJM:Debug( "Bags OK. checking", itemLink, Link )
				local itemString = GetItemInfo( Link )
				--AJM:Debug( "Bags OK. checking", itemLink, itemString )
				if itemLink == itemString then
					--AJM:Print( "True" )
					return true
				end
			end
		end 
	end
	return false
end


function AJM:AddAnItemToTheBarIfNotExists( itemLink, startsQuest)
	local itemInfo
	local barItemId
	local iterateItems
	local alreadyExists = false
	local itemId = JambaUtilities:GetItemIdFromItemLink( itemLink )
	for iterateItems = 1, AJM.db.numberOfItems, 1 do
		itemInfo = AJM:GetItemFromItemDatabase( iterateItems )
			--AJM:Print("check", itemLink, itemInfo.action)
		if itemInfo.kind == "item" and itemInfo.action == itemId then
			alreadyExists = true
		--	AJM:Print("test", itemLink )
			return
		end
	end
	if alreadyExists == false then
		--AJM:Print("test2", itemLink )
		for iterateItems = 1, AJM.db.numberOfItems, 1 do
			itemInfo = AJM:GetItemFromItemDatabase( iterateItems )
			--Checks the items we talking about is in the bags of the player.
			if itemInfo.kind == "empty" then
				AJM:AddItemToItemDatabase( iterateItems, "item", itemId )
				AJM:JambaSendUpdate( iterateItems, "item", itemId )
				AJM:SettingsRefresh()	
					if startsQuest then
						AJM:JambaSendMessageToTeam( AJM.db.messageArea, L["New item that starts a quest found!"], false )
					end
				return
			end
		end
	end
end

function AJM:RefreshItemUseControls()
	if InCombatLockdown() then
		AJM.refreshItemUseControlsPending = true
		return
	end
	local parentFrame = JambaItemUseFrame
	local positionLeft
	local positionTop
	local itemsPerRow = AJM.db.numberOfItems / AJM.db.numberOfRows
	local row
	local rowLeftModifier
	for iterateItems = 1, AJM.maximumNumberOfItems, 1 do
		local itemContainer = AJM.itemContainer[iterateItems]
		if itemContainer ~= nil then
			local containerButton = itemContainer["container"]
			containerButton:Hide()
		end
	end
	for iterateItems = 1, AJM.db.numberOfItems, 1 do
		local itemContainer = AJM.itemContainer[iterateItems]
		if itemContainer == nil then
			AJM:CreateJambaItemUseItemContainer( iterateItems, parentFrame )
			itemContainer = AJM.itemContainer[iterateItems]
		end
		local containerButton = itemContainer["container"]
		row = math.floor((iterateItems - 1) / itemsPerRow)
		rowLeftModifier = math.floor((iterateItems-1) % itemsPerRow)
		positionLeft = 6 + (AJM.itemSize * rowLeftModifier) + (AJM.db.itemUseHorizontalSpacing * rowLeftModifier)
		local getHeight = AJM.UpdateHeight()
		positionTop = -getHeight - (AJM.db.itemUseVerticalSpacing * 2) - (row * AJM.itemSize) - (row * AJM.db.itemUseVerticalSpacing)
		containerButton:SetWidth( AJM.itemSize )
		containerButton:SetHeight( AJM.itemSize )
		containerButton:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", positionLeft, positionTop )
		containerButton:Show()
	end	
	AJM:UpdateJambaItemUseDimensions()
end

function AJM:UpdateJambaItemUseDimensions()
	local frame = JambaItemUseFrame
	local itemsPerRow = AJM.db.numberOfItems / AJM.db.numberOfRows
	frame:SetWidth( 5 + (AJM.db.itemUseHorizontalSpacing * (3 + itemsPerRow-1)) + (AJM.itemSize * itemsPerRow) )
	local getHeight = AJM.UpdateHeight()
	frame:SetHeight( getHeight + (AJM.itemSize * AJM.db.numberOfRows) + (AJM.db.itemUseVerticalSpacing * AJM.db.numberOfRows) + (AJM.db.itemUseVerticalSpacing * 3))
	frame:SetScale( AJM.db.itemUseScale )
end

-------------------------------------------------------------------------------------------------------------
-- Communications
-------------------------------------------------------------------------------------------------------------

function AJM:JambaSendUpdate( button, type, action )
	--AJM:Print("testDataDebug", button, type, action )
	AJM:JambaSendCommandToTeam( AJM.COMMAND_ITEMBAR_BUTTON, button, type, action )
end

function AJM:ReceiveButtonData(characterName, button, type, action)
	--AJM:Print("ReceiveButtonDataDebug", button, type, action )
	AJM:AddItemToItemDatabase( button, type, action )
	AJM:SettingsRefresh()
end

function AJM:ReceiveSync(characterName, data)
	--AJM:Print("ReceiveSync", data)
	for id, data in pairs( data ) do 
		--AJM:Print("ID", id, data.button, data.type, data.action )
		AJM:AddItemToItemDatabase( data.button, data.type, data.action )
		AJM:SettingsRefresh()
	end		
end	


-------------------------------------------------------------------------------------------------------------
-- Settings Dialogs.
-------------------------------------------------------------------------------------------------------------

local function SettingsCreateOptions( top )
	-- Get positions.
    local buttonHeight = JambaHelperSettings:GetButtonHeight()
	local checkBoxHeight = JambaHelperSettings:GetCheckBoxHeight()
	local editBoxHeight = JambaHelperSettings:GetEditBoxHeight()
	local dropdownHeight = JambaHelperSettings:GetDropdownHeight()
	local labelHeight = JambaHelperSettings:GetLabelHeight()
	local mediaHeight = JambaHelperSettings:GetMediaHeight()
	local sliderHeight = JambaHelperSettings:GetSliderHeight()
	local left = JambaHelperSettings:LeftOfSettings()
	local headingHeight = JambaHelperSettings:HeadingHeight()
	local headingWidth = JambaHelperSettings:HeadingWidth( false )
	local horizontalSpacing = JambaHelperSettings:GetHorizontalSpacing()
	local verticalSpacing = JambaHelperSettings:GetVerticalSpacing()
	local halfWidth = (headingWidth - horizontalSpacing) / 2
	local thirdWidth = (headingWidth - (horizontalSpacing * 2)) / 3
	local column2left = left + halfWidth
	local left2 = left + thirdWidth
	local left3 = left + (thirdWidth * 2)
	local movingTop = top
	JambaHelperSettings:CreateHeading( AJM.settingsControl, L["Item Use Options"], movingTop, false )
	movingTop = movingTop - headingHeight
	AJM.settingsControl.displayOptionsCheckBoxShowItemUse = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		left, 
		movingTop, 
		L["Show Item Bar"],
		AJM.SettingsToggleShowItemUse
	)
	movingTop = movingTop - checkBoxHeight - verticalSpacing
	AJM.settingsControl.displayOptionsCheckBoxShowItemUseOnlyOnMaster = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		left, 
		movingTop, 
		L["Only On Master"],
		AJM.SettingsToggleShowItemUseOnlyOnMaster
	)
	movingTop = movingTop - checkBoxHeight - verticalSpacing
	AJM.settingsControl.displayOptionsCheckBoxItemBarsSynchronized = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		left, 
		movingTop, 
		L["Keep Item Bars On Minions Synchronized"],
		AJM.SettingsToggleItemBarsSynchronized
	)	
	movingTop = movingTop - checkBoxHeight - verticalSpacing
	AJM.settingsControl.displayOptionsCheckBoxAutoAddQuestItem = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		left, 
		movingTop, 
		L["Automatically Add Quest Items To Bar"],
		AJM.SettingsToggleAutoAddQuestItem
	)
	movingTop = movingTop - checkBoxHeight - verticalSpacing
	AJM.settingsControl.displayOptionsCheckBoxAutoAddArtifactItem = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		left, 
		movingTop, 
		L["Automatically Add Artifact Power Items To Bar"],
		AJM.SettingsToggleAutoAddArtifactItem
	)	
	movingTop = movingTop - checkBoxHeight - verticalSpacing
	AJM.settingsControl.displayOptionsCheckBoxAutoAddSatchelsItem = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		left, 
		movingTop, 
		L["Automatically Add Satchel Items To Bar"],
		AJM.SettingsToggleAutoAddSatchelsItem
	)
	movingTop = movingTop - checkBoxHeight - verticalSpacing
	AJM.settingsControl.displayOptionsCheckBoxHideClearButton = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		left, 
		movingTop, 
		L["Hide Buttons"],
		AJM.SettingsToggleHideClearButton
	)	
	movingTop = movingTop - checkBoxHeight - verticalSpacing	
	AJM.settingsControl.displayOptionsCheckBoxHideItemUseInCombat = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		left, 
		movingTop, 
		L["Hide Item Bar In Combat"],
		AJM.SettingsToggleHideItemUseInCombat
	)	
	movingTop = movingTop - checkBoxHeight - verticalSpacing	
	AJM.settingsControl.displayOptionsItemUseNumberOfItems = JambaHelperSettings:CreateSlider( 
		AJM.settingsControl, 
		headingWidth, 
		left, 
		movingTop, 
		L["Number Of Items"]
	)
	AJM.settingsControl.displayOptionsItemUseNumberOfItems:SetSliderValues( 1, AJM.maximumNumberOfItems, 1 )
	AJM.settingsControl.displayOptionsItemUseNumberOfItems:SetCallback( "OnValueChanged", AJM.SettingsChangeNumberOfItems )
	movingTop = movingTop - sliderHeight - verticalSpacing
	AJM.settingsControl.displayOptionsItemUseNumberOfRows = JambaHelperSettings:CreateSlider( 
		AJM.settingsControl, 
		headingWidth, 
		left, 
		movingTop, 
		L["Number Of Rows"]
	)
	AJM.settingsControl.displayOptionsItemUseNumberOfRows:SetSliderValues( 1, AJM.maximumNumberOfRows, 1 )
	AJM.settingsControl.displayOptionsItemUseNumberOfRows:SetCallback( "OnValueChanged", AJM.SettingsChangeNumberOfRows )
	movingTop = movingTop - sliderHeight - verticalSpacing
	JambaHelperSettings:CreateHeading( AJM.settingsControl, L["Appearance & Layout"], movingTop, false )
	movingTop = movingTop - headingHeight	
	AJM.settingsControl.displayOptionsItemUseScaleSlider = JambaHelperSettings:CreateSlider( 
		AJM.settingsControl, 
		headingWidth, 
		left, 
		movingTop, 
		L["Scale"]
	)
	AJM.settingsControl.displayOptionsItemUseScaleSlider:SetSliderValues( 0.5, 2, 0.01 )
	AJM.settingsControl.displayOptionsItemUseScaleSlider:SetCallback( "OnValueChanged", AJM.SettingsChangeScale )
	movingTop = movingTop - sliderHeight - verticalSpacing
	AJM.settingsControl.displayOptionsItemUseTransparencySlider = JambaHelperSettings:CreateSlider( 
		AJM.settingsControl, 
		headingWidth, 
		left, 
		movingTop, 
		L["Transparency"]
	)
	AJM.settingsControl.displayOptionsItemUseTransparencySlider:SetSliderValues( 0, 1, 0.01 )
	AJM.settingsControl.displayOptionsItemUseTransparencySlider:SetCallback( "OnValueChanged", AJM.SettingsChangeTransparency )
	movingTop = movingTop - sliderHeight - verticalSpacing
	AJM.settingsControl.displayOptionsItemUseMediaBorder = JambaHelperSettings:CreateMediaBorder( 
		AJM.settingsControl, 
		halfWidth, 
		left, 
		movingTop,
		L["Border Style"]
	)
	AJM.settingsControl.displayOptionsItemUseMediaBorder:SetCallback( "OnValueChanged", AJM.SettingsChangeBorderStyle )
	AJM.settingsControl.displayOptionsBorderColourPicker = JambaHelperSettings:CreateColourPicker(
		AJM.settingsControl,
		halfWidth,
		column2left + 15,
		movingTop - 15,
		L["Border Colour"]
	)
	AJM.settingsControl.displayOptionsBorderColourPicker:SetHasAlpha( true )
	AJM.settingsControl.displayOptionsBorderColourPicker:SetCallback( "OnValueConfirmed", AJM.SettingsBorderColourPickerChanged )
	movingTop = movingTop - mediaHeight - verticalSpacing
	AJM.settingsControl.displayOptionsItemUseMediaBackground = JambaHelperSettings:CreateMediaBackground( 
		AJM.settingsControl, 
		halfWidth, 
		left, 
		movingTop,
		L["Background"]
	)
	AJM.settingsControl.displayOptionsItemUseMediaBackground:SetCallback( "OnValueChanged", AJM.SettingsChangeBackgroundStyle )
	AJM.settingsControl.displayOptionsBackgroundColourPicker = JambaHelperSettings:CreateColourPicker(
		AJM.settingsControl,
		halfWidth,
		column2left + 15,
		movingTop - 15,
		L["Background Colour"]
	)
	AJM.settingsControl.displayOptionsBackgroundColourPicker:SetHasAlpha( true )
	AJM.settingsControl.displayOptionsBackgroundColourPicker:SetCallback( "OnValueConfirmed", AJM.SettingsBackgroundColourPickerChanged )	
	movingTop = movingTop - mediaHeight - verticalSpacing
	JambaHelperSettings:CreateHeading( AJM.settingsControl, L["Messages"], movingTop, false )
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
    JambaHelperSettings:CreateHeading( AJM.settingsControl, L["Clear Item Bar"], movingTop, false )
    movingTop = movingTop - headingHeight
    AJM.settingsControl.buttonClearItemBar = JambaHelperSettings:CreateButton(
        AJM.settingsControl,
        headingWidth,
        left,
        movingTop,
        L["Clear Item Bar"],
        AJM.ClearItemUseCommand
    )
    movingTop = movingTop - buttonHeight - verticalSpacing
	return movingTop
end

function AJM:OnMessageAreasChanged( message )
	AJM.settingsControl.dropdownMessageArea:SetList( JambaApi.MessageAreaList() )
end

local function SettingsCreate()
	AJM.settingsControl = {}
	JambaHelperSettings:CreateSettings( 
		AJM.settingsControl, 
		AJM.moduleDisplayName, 
		AJM.parentDisplayName, 
		AJM.SettingsPushSettingsClick 
	)
	local bottomOfOptions = SettingsCreateOptions( JambaHelperSettings:TopOfSettings() )
	AJM.settingsControl.widgetSettings.content:SetHeight( -bottomOfOptions )
	-- Help
	local helpTable = {}
	JambaHelperSettings:CreateHelp( AJM.settingsControl, helpTable, AJM:GetConfiguration() )		
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
	-- Values.
	AJM.settingsControl.displayOptionsCheckBoxShowItemUse:SetValue( AJM.db.showItemUse )
	AJM.settingsControl.displayOptionsCheckBoxShowItemUseOnlyOnMaster:SetValue( AJM.db.showItemUseOnMasterOnly )
	AJM.settingsControl.displayOptionsCheckBoxHideItemUseInCombat:SetValue( AJM.db.hideItemUseInCombat )
	AJM.settingsControl.displayOptionsItemUseNumberOfItems:SetValue( AJM.db.numberOfItems )
	AJM.settingsControl.displayOptionsItemUseNumberOfRows:SetValue( AJM.db.numberOfRows )
	AJM.settingsControl.displayOptionsCheckBoxAutoAddQuestItem:SetValue( AJM.db.autoAddQuestItemsToBar )
	AJM.settingsControl.displayOptionsCheckBoxAutoAddArtifactItem:SetValue( AJM.db.autoAddArtifactItemsToBar )
	AJM.settingsControl.displayOptionsCheckBoxAutoAddSatchelsItem:SetValue( AJM.db.autoAddSatchelsItemsToBar )
	AJM.settingsControl.displayOptionsCheckBoxHideClearButton:SetValue( AJM.db.hideClearButton )
	AJM.settingsControl.displayOptionsCheckBoxItemBarsSynchronized:SetValue( AJM.db.itemBarsSynchronized )
	AJM.settingsControl.displayOptionsItemUseScaleSlider:SetValue( AJM.db.itemUseScale )
	AJM.settingsControl.displayOptionsItemUseTransparencySlider:SetValue( AJM.db.frameAlpha )
	AJM.settingsControl.displayOptionsItemUseMediaBorder:SetValue( AJM.db.borderStyle )
	AJM.settingsControl.displayOptionsItemUseMediaBackground:SetValue( AJM.db.backgroundStyle )
	AJM.settingsControl.dropdownMessageArea:SetValue( AJM.db.messageArea )
	AJM.settingsControl.displayOptionsBackgroundColourPicker:SetColor( AJM.db.frameBackgroundColourR, AJM.db.frameBackgroundColourG, AJM.db.frameBackgroundColourB, AJM.db.frameBackgroundColourA )
	AJM.settingsControl.displayOptionsBorderColourPicker:SetColor( AJM.db.frameBorderColourR, AJM.db.frameBorderColourG, AJM.db.frameBorderColourB, AJM.db.frameBorderColourA )
	-- State.
	-- Trying to change state in combat lockdown causes taint. Let's not do that. Eventually it would be nice to have a "proper state driven item list",
	-- but this workaround is enough for now.
	if not InCombatLockdown() then
		AJM.settingsControl.displayOptionsCheckBoxShowItemUseOnlyOnMaster:SetDisabled( not AJM.db.showItemUse )
		AJM.settingsControl.displayOptionsCheckBoxHideItemUseInCombat:SetDisabled( not AJM.db.showItemUse )
		AJM.settingsControl.displayOptionsItemUseNumberOfItems:SetDisabled( not AJM.db.showItemUse )
		AJM.settingsControl.displayOptionsItemUseNumberOfRows:SetDisabled( not AJM.db.showItemUse )
		AJM.settingsControl.displayOptionsCheckBoxAutoAddQuestItem:SetDisabled( not AJM.db.showItemUse )
		AJM.settingsControl.displayOptionsCheckBoxAutoAddArtifactItem:SetDisabled( not AJM.db.showItemUse )
		AJM.settingsControl.displayOptionsCheckBoxAutoAddSatchelsItem:SetDisabled( not AJM.db.showItemUse )
		AJM.settingsControl.displayOptionsCheckBoxHideClearButton:SetDisabled( not AJM.db.showItemUse )
		AJM.settingsControl.displayOptionsCheckBoxItemBarsSynchronized:SetDisabled( not AJM.db.showItemUse )
		AJM.settingsControl.displayOptionsItemUseScaleSlider:SetDisabled( not AJM.db.showItemUse )
		AJM.settingsControl.displayOptionsItemUseTransparencySlider:SetDisabled( not AJM.db.showItemUse )
		AJM.settingsControl.displayOptionsItemUseMediaBorder:SetDisabled( not AJM.db.showItemUse )
		AJM.settingsControl.displayOptionsItemUseMediaBackground:SetDisabled( not AJM.db.showItemUse )
		AJM.settingsControl.dropdownMessageArea:SetDisabled( not AJM.db.showItemUse )
		AJM.settingsControl.displayOptionsBackgroundColourPicker:SetDisabled( not AJM.db.showItemUse )
		AJM.settingsControl.displayOptionsBorderColourPicker:SetDisabled( not AJM.db.showItemUse )		
		if AJM.itemUseCreated == true then
			AJM:RefreshItemUseControls()
			AJM:SettingsUpdateBorderStyle()
			AJM:SetItemUseVisibility()
			AJM:UpdateItemsInBar()
			AJM:UpdateHeight()
		end
	else
		AJM.updateSettingsAfterCombat = true
	end
end

function AJM:SettingsPushSettingsClick( event )
	AJM:JambaSendSettings()
end

function AJM:SettingsToggleShowItemUse( event, checked )
	AJM.db.showItemUse = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleHideItemUseInCombat( event, checked )
	AJM.db.hideItemUseInCombat = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleShowItemUseOnlyOnMaster( event, checked )
	AJM.db.showItemUseOnMasterOnly = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleAutoAddQuestItem( event, checked )
	AJM.db.autoAddQuestItemsToBar = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleAutoAddArtifactItem( event, checked )
	AJM.db.autoAddArtifactItemsToBar = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleAutoAddSatchelsItem( event, checked )
	AJM.db.autoAddSatchelsItemsToBar = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleHideClearButton(event, checked )
	AJM.db.hideClearButton = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleItemBarsSynchronized( event, checked )
	AJM.db.itemBarsSynchronized = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsChangeNumberOfItems( event, value )
	AJM.db.numberOfItems = tonumber( value )
	AJM:SettingsRefresh()
end

function AJM:SettingsChangeNumberOfRows( event, value )
	AJM.db.numberOfRows= tonumber( value )
	AJM:SettingsRefresh()
end

function AJM:SettingsChangeScale( event, value )
	AJM.db.itemUseScale = tonumber( value )
	AJM:SettingsRefresh()
end

function AJM:SettingsChangeTransparency( event, value )
	AJM.db.frameAlpha = tonumber( value )
	AJM:SettingsRefresh()
end

function AJM:SettingsChangeBorderStyle( event, value )
	AJM.db.borderStyle = value
	AJM:SettingsRefresh()
end

function AJM:SettingsChangeBackgroundStyle( event, value )
	AJM.db.backgroundStyle = value
	AJM:SettingsRefresh()
end

function AJM:SettingsSetMessageArea( event, value )
	AJM.db.messageArea = value
	AJM:SettingsRefresh()
end

function AJM:OnMasterChanged( message, characterName )
	AJM:SettingsRefresh()
end

function AJM:SettingsBackgroundColourPickerChanged( event, r, g, b, a )
	AJM.db.frameBackgroundColourR = r
	AJM.db.frameBackgroundColourG = g
	AJM.db.frameBackgroundColourB = b
	AJM.db.frameBackgroundColourA = a
	AJM:SettingsRefresh()
end

function AJM:SettingsBorderColourPickerChanged( event, r, g, b, a )
	AJM.db.frameBorderColourR = r
	AJM.db.frameBorderColourG = g
	AJM.db.frameBorderColourB = b
	AJM.db.frameBorderColourA = a
	AJM:SettingsRefresh()
end

-------------------------------------------------------------------------------------------------------------
-- Addon initialization, enabling and disabling.
-------------------------------------------------------------------------------------------------------------

-- Initialise the module.
function AJM:OnInitialize()
	-- Create the settings control.
	SettingsCreate()
	-- Initialise the JambaModule part of this module.
	AJM:JambaModuleInitialize( AJM.settingsControl.widgetSettings.frame )
	-- Populate the settings.
	AJM:SettingsRefresh()	
	-- Create the item use frame.
	CreateJambaItemUseFrame()
	AJM:RefreshItemUseControls()
	AJM:SettingsUpdateBorderStyle()
	AJM:SetItemUseVisibility()
	AJM:UpdateItemsInBar()
end

-- Called when the addon is enabled.
function AJM:OnEnable()
	AJM:RegisterEvent( "PLAYER_REGEN_ENABLED" )
	AJM:RegisterEvent( "PLAYER_REGEN_DISABLED" )
	AJM:RegisterEvent( "BAG_UPDATE" )
	AJM:RegisterEvent( "ITEM_PUSH" )
	AJM:RegisterEvent( "UNIT_QUEST_LOG_CHANGED", "QUEST_UPDATE" )
	AJM.SharedMedia.RegisterCallback( AJM, "LibSharedMedia_Registered" )
    AJM.SharedMedia.RegisterCallback( AJM, "LibSharedMedia_SetGlobal" )	
	AJM:RegisterMessage( JambaApi.MESSAGE_TEAM_MASTER_CHANGED, "OnMasterChanged" )
	AJM:RegisterMessage( JambaApi.MESSAGE_MESSAGE_AREAS_CHANGED, "OnMessageAreasChanged" )
	AJM:RefreshItemUseControls()
	AJM:UpdateItemsInBar()
	AJM.keyBindingFrame = CreateFrame( "Frame", nil, UIParent )
	AJM:RegisterEvent( "UPDATE_BINDINGS" )		
	AJM:UPDATE_BINDINGS()
	LibActionButton.RegisterCallback( AJM, "OnButtonContentsChanged", "OnButtonContentsChanged" )
	LibActionButton.RegisterCallback( AJM, "OnButtonUpdate", "OnButtonUpdate" )
	LibActionButton.RegisterCallback( AJM, "OnButtonState", "OnButtonState" )
	LibActionButton.RegisterCallback( AJM, "OnButtonUsable", "OnButtonUsable" )
end

-- Called when the addon is disabled.
function AJM:OnDisable()
end

-- Settings received.
function AJM:JambaOnSettingsReceived( characterName, settings )	
	if characterName ~= AJM.characterName then
		-- Update the settings.
		AJM.db.showItemUse = settings.showItemUse
		AJM.db.showItemUseOnMasterOnly = settings.showItemUseOnMasterOnly
		AJM.db.hideItemUseInCombat = settings.hideItemUseInCombat
		AJM.db.borderStyle = settings.borderStyle
		AJM.db.backgroundStyle = settings.backgroundStyle
		AJM.db.itemUseScale = settings.itemUseScale
		AJM.db.itemUseTitleHeight = settings.itemUseTitleHeight
		AJM.db.itemUseVerticalSpacing = settings.itemUseVerticalSpacing
		AJM.db.itemUseHorizontalSpacing = settings.itemUseHorizontalSpacing
		AJM.db.autoAddQuestItemsToBar = settings.autoAddQuestItemsToBar
		AJM.db.autoAddArtifactItemsToBar = settings.autoAddArtifactItemsToBar
		AJM.db.autoAddSatchelsItemsToBar = settings.autoAddSatchelsItemsToBar
		AJM.db.hideClearButton = settings.hideClearButton
		AJM.db.itemBarsSynchronized = settings.itemBarsSynchronized
		AJM.db.numberOfItems = settings.numberOfItems
		AJM.db.numberOfRows = settings.numberOfRows
		AJM.db.messageArea = settings.messageArea
		if AJM.db.itemBarsSynchronized == true then
		 AJM.db.itemsAdvanced = JambaUtilities:CopyTable( settings.itemsAdvanced )
		end
		AJM.db.frameAlpha = settings.frameAlpha
		AJM.db.framePoint = settings.framePoint
		AJM.db.frameRelativePoint = settings.frameRelativePoint
		AJM.db.frameXOffset = settings.frameXOffset
		AJM.db.frameYOffset = settings.frameYOffset
		AJM.db.frameBackgroundColourR = settings.frameBackgroundColourR
		AJM.db.frameBackgroundColourG = settings.frameBackgroundColourG
		AJM.db.frameBackgroundColourB = settings.frameBackgroundColourB
		AJM.db.frameBackgroundColourA = settings.frameBackgroundColourA
		AJM.db.frameBorderColourR = settings.frameBorderColourR
		AJM.db.frameBorderColourG = settings.frameBorderColourG
		AJM.db.frameBorderColourB = settings.frameBorderColourB
		AJM.db.frameBorderColourA = settings.frameBorderColourA				
		-- Refresh the settings.
		AJM:SettingsRefresh()
		-- Tell the player.
		AJM:Print( L["Settings received from A."]( characterName ) )
		-- Tell the team?
		--AJM:JambaSendMessageToTeam( AJM.db.messageArea,  L["Settings received from A."]( characterName ), false )
	end
end

function AJM:PLAYER_REGEN_ENABLED()
	if AJM.db.hideItemUseInCombat == true then
		AJM:SetItemUseVisibility()
	end
	if AJM.refreshItemUseControlsPending == true then
		AJM:RefreshItemUseControls()
		AJM.refreshItemUseControlsPending = false
	end
	if AJM.refreshUpdateItemsInBarPending == true then
		AJM:UpdateItemsInBar()
		AJM.refreshUpdateItemsInBarPending = false
	end
	if AJM.refreshUpdateBindingsPending == true then
		AJM:UPDATE_BINDINGS()
		AJM.refreshUpdateBindingsPending = false
	end
	if AJM.updateSettingsAfterCombat == true then
		AJM:SettingsRefresh()
		AJM.updateSettingsAfterCombat = false
	end 	
end

function AJM:PLAYER_REGEN_DISABLED()
	if AJM.db.hideItemUseInCombat == true then
		JambaItemUseFrame:Hide()
	end
end

function AJM:BAG_UPDATE()
	if not InCombatLockdown() then
		AJM:UpdateItemsInBar()
		AJM:UpdateQuestItemsInBar()
		--AJM:ScheduleTimer( "UpdateArtifactItemsInBar", 1 )
	end
end

function AJM:QUEST_UPDATE()
	if not InCombatLockdown() then
		AJM:UpdateQuestItemsInBar()	
	end
end


function AJM:ITEM_PUSH()
	if AJM.db.showItemUse == false then
		return
	end
	if AJM.db.autoAddQuestItemsToBar == true then
		AJM:ScheduleTimer( "CheckForQuestItemAndAddToBar", 1 )
	end
	if AJM.db.autoAddArtifactItemsToBar == true then
		AJM:ScheduleTimer( "CheckForArtifactItemAndAddToBar", 1 )
	end
	if AJM.db.autoAddSatchelsItemsToBar == true then
		AJM:ScheduleTimer( "CheckForSatchelsItemAndAddToBar", 1 )
	end	
end

function AJM:UPDATE_BINDINGS()
	if InCombatLockdown() then
		AJM.refreshUpdateBindingsPending = true
		return
    end
	ClearOverrideBindings( AJM.keyBindingFrame )
	for iterateItems = 1, AJM.maximumNumberOfItems, 1 do
		local containerButtonName = AJM.globalFramePrefix.."ContainerButton"..iterateItems
		local key1, key2 = GetBindingKey( "JAMBAITEMUSE"..iterateItems )
		if key1 then
			SetOverrideBindingClick( AJM.keyBindingFrame, false, key1, containerButtonName ) 
		end
		if key2 then 
			SetOverrideBindingClick( AJM.keyBindingFrame, false, key2, containerButtonName ) 
		end	
	end
end

function AJM:LibSharedMedia_Registered()
end

function AJM:LibSharedMedia_SetGlobal()
end

-- A Jamba command has been recieved.
function AJM:JambaOnCommandReceived( characterName, commandName, ... )
	if characterName ~= self.characterName then
		if commandName == AJM.COMMAND_ITEMBAR_BUTTON then
			AJM:ReceiveButtonData( characterName, ... )
		end
		if commandName == AJM.COMMAND_ITEMUSE_SYNC then
			AJM:ReceiveSync( characterName, ... )
		end
	end
end	
