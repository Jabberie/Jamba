--[[
Jamba - Jafula's Awesome Multi-Boxer Assistant
Copyright 2008 - 2017 Michael "Jafula" Miller


License: The MIT License
]]--

local MAJOR, MINOR = "JambaHelperSettings-1.0", 1
local JambaHelperSettings, oldMinor = LibStub:NewLibrary( MAJOR, MINOR )

if not JambaHelperSettings then 
	return 
end

-- Locale.
local L = LibStub( "AceLocale-3.0" ):GetLocale( "Jamba-Core" )

-- Get the ACE GUI Library.
local AceGUI = LibStub( "AceGUI-3.0" )

-- Register a manual layout function which does nothing, each child manually sets its size and position.
AceGUI:RegisterLayout( "JambaManual", function(content, children) end )

AceGUI:RegisterLayout("JambaFill",
	function(content, children)
		if children[1] then
			local offset = 12
			local height = content:GetHeight() - offset
			local width = content:GetWidth()
			children[1]:SetWidth(width)
			children[1]:SetHeight(height)
			children[1]:ClearAllPoints()
			children[1]:SetPoint( "TOPLEFT", 0, -offset )
			children[1].frame:Show()
		end
	end)
	
	-- A single control fills the whole content area
AceGUI:RegisterLayout("JambaFillAce3Fix",
	function(content, children)
		if children[1] then
			local offset = 0
			local height = content:GetHeight()
			local width = content:GetWidth()
			children[1]:SetWidth(width)
			children[1]:SetHeight(height)
			children[1]:ClearAllPoints()
			children[1]:SetPoint("TOPLEFT", content)
			children[1].frame:Show()
		end
	end)
	
-------------------------------------------------------------------------------------------------------------
-- Spacing.
-------------------------------------------------------------------------------------------------------------

function JambaHelperSettings:GetHorizontalSpacing()
	return 2
end

function JambaHelperSettings:GetVerticalSpacing()
	return 2
end

-------------------------------------------------------------------------------------------------------------
-- Settings Frame.
-------------------------------------------------------------------------------------------------------------

function JambaHelperSettings:CreateSettings( settingsControl, displayName, parentDisplayName, pushSettingsCallback )
	local containerWidgetSettings = AceGUI:Create( "SimpleGroup" )
	containerWidgetSettings:SetLayout( "JambaFill" )
	
	local widgetSettingsHelp = AceGUI:Create( "ScrollFrame" )
	widgetSettingsHelp:SetLayout( "Flow" )
	
	local widgetSettings = AceGUI:Create( "ScrollFrame" )
	widgetSettings:SetLayout( "JambaManual" )
	
	local tabGroupWidgetSettings = AceGUI:Create( "TabGroup" )
	-- Was 'Fill', which causes lockup, started at patch 4.1 (40100).  Similar to http://forums.wowace.com/showthread.php?t=17872
	tabGroupWidgetSettings:SetLayout( "JambaFillAce3Fix" )	
	tabGroupWidgetSettings:SetTabs( { {text=L["Options"], value="options"}, {text=L["Commands"], value="help"} } )
	
	containerWidgetSettings:AddChild( tabGroupWidgetSettings )
	tabGroupWidgetSettings:AddChild( widgetSettings )
	
	-- Jafula loves closures!
	settingsControl.tabGroupSelected = function( container, event, group )
		if group == "options" then
			widgetSettingsHelp.frame:Hide()
			widgetSettings:SetParent( container )
			widgetSettings:SetWidth( container.content:GetWidth() or 0 )
			widgetSettings:SetHeight( container.content:GetHeight() or 0 )
			widgetSettings.frame:SetAllPoints( container.content )
			widgetSettings.frame:Show()	
		elseif group == "help" then
			widgetSettings.frame:Hide()	
			widgetSettingsHelp:SetParent( container )
			widgetSettingsHelp:SetWidth( container.content:GetWidth() or 0 )
			widgetSettingsHelp:SetHeight( container.content:GetHeight() or 0 )
			widgetSettingsHelp.frame:SetAllPoints( container.content )
			widgetSettingsHelp.frame:Show()	
		end
	end

	tabGroupWidgetSettings:SelectTab( "options" )
	tabGroupWidgetSettings:SetCallback( "OnGroupSelected", settingsControl.tabGroupSelected )
	
	local label = containerWidgetSettings.frame:CreateFontString( nil, "OVERLAY", "GameFontNormalLarge" )
	label:SetPoint( "TOPLEFT", 0, 0 )
	label:SetPoint( "BOTTOMRIGHT", containerWidgetSettings.frame, "TOPRIGHT", 0, -30 )
	label:SetJustifyH( "LEFT" )
	label:SetJustifyV( "TOP" )
	label:SetText( displayName )
	
	local button = AceGUI:Create( "Button" )
	button:SetText( L["Push Settings"] )
	containerWidgetSettings:AddChild( button )
	button:SetWidth( 200 )
	button:SetPoint( "TOPLEFT", containerWidgetSettings.frame, "TOPRIGHT", -200, 0 )
	button:SetCallback( "OnClick", pushSettingsCallback )
	settingsControl.widgetPushSettingsButton = button

	settingsControl.widgetSettingsHelp = widgetSettingsHelp
	settingsControl.containerWidgetSettings = containerWidgetSettings
	settingsControl.tabGroupWidgetSettings = tabGroupWidgetSettings
	settingsControl.widgetSettings = widgetSettings
	JambaPrivate.SettingsFrame.Tree.Add( displayName, parentDisplayName, settingsControl.containerWidgetSettings, settingsControl.tabGroupWidgetSettings )
end

function JambaHelperSettings:TopOfSettings()
	return 0
end

function JambaHelperSettings:LeftOfSettings()
	return 0
end

-------------------------------------------------------------------------------------------------------------
-- Help.
-------------------------------------------------------------------------------------------------------------

function JambaHelperSettings:CreateHelp( settingsControl, help, configuration )
	table.insert( help, {"D", ""} )
	table.insert( help, {"H", L["Slash Commands"]} )
	for key, info in pairs( configuration.args ) do
		if info.type == "input" then
			table.insert( help, {"D", ""} )
			table.insert( help, {"S", info.usage} )
			table.insert( help, {"D", info.desc} )
		end
	end	
	for index, info in ipairs( help ) do
		local type = info[1]
		local text = info[2]
		if type == "H" then
			local heading = AceGUI:Create( "Heading" )
			heading:SetText( text )
			heading.width = "fill"
			settingsControl.widgetSettingsHelp:AddChild( heading )
		end		
		if type == "D" then
			local label = AceGUI:Create( "Label" )
			label:SetText( text )
			label.width = "fill"
			settingsControl.widgetSettingsHelp:AddChild( label )
		end
		if type == "S" then
			local label = AceGUI:Create( "Label" )
			label:SetText( text )
			label:SetColor( 1.0, 0.96, 0.41 )
			label.width = "fill"
			settingsControl.widgetSettingsHelp:AddChild( label )
		end		
	end
end
	
-------------------------------------------------------------------------------------------------------------
-- Heading.
-------------------------------------------------------------------------------------------------------------

function JambaHelperSettings:HeadingWidth( hasScrollBar )
	if hasScrollBar == true then
		return 500
	else
		return 520
	end
end

function JambaHelperSettings:HeadingHeight()
	-- Defined as 18 in the AceGUI Heading Widget (added 2 more pixels for spacing purposes).
	return 20
end

function JambaHelperSettings:CreateHeading( settingsControl, text, top, hasScrollBar )
	-- Create a heading
	local heading = AceGUI:Create( "Heading" )
	heading:SetText( text )
	settingsControl.widgetSettings:AddChild( heading )
	heading:SetWidth( self:HeadingWidth( hasScrollBar ) )
	heading:SetPoint( "TOPLEFT", settingsControl.widgetSettings.content, "TOPLEFT", 0, top )
end

-------------------------------------------------------------------------------------------------------------
-- Frame backdrop.
-------------------------------------------------------------------------------------------------------------

function JambaHelperSettings:CreateBackdrop()
	local frameBackdrop  = {
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 16,
		insets = { left = 3, right = 3, top = 5, bottom = 3 }
	}
	return frameBackdrop  
end

-------------------------------------------------------------------------------------------------------------
-- ToolTip.
-------------------------------------------------------------------------------------------------------------


local function onControlEnter(widget, event, value)
	GameTooltip:ClearLines()
	GameTooltip:SetOwner(widget.frame, "ANCHOR_TOP")
	GameTooltip:AddLine(widget.text and widget.text:GetText() or widget.label:GetText())
	GameTooltip:AddLine(widget:GetUserData("tooltip"), 1, 1, 1, 1)
	GameTooltip:Show()
end

local function onControlLeave() GameTooltip:Hide() end

-------------------------------------------------------------------------------------------------------------
-- Button.
-------------------------------------------------------------------------------------------------------------

function JambaHelperSettings:GetButtonHeight()
	-- Defined as 24 in the AceGUI Button Widget .
	return 24
end

function JambaHelperSettings:CreateButton( settingsControl, width, left, top, text, buttonCallback, toolTip )
	local button = AceGUI:Create( "Button" )
	button:SetText( text )
	settingsControl.widgetSettings:AddChild( button )
	button:SetWidth( width )
	button:SetPoint( "TOPLEFT", settingsControl.widgetSettings.content, "TOPLEFT", left, top )
	button:SetCallback( "OnClick", buttonCallback )	
	--button:SetUserData("key", "keyword") -- needed/??
	button:SetUserData("tooltip", toolTip)
	button:SetCallback("OnEnter", onControlEnter)
	button:SetCallback("OnLeave", onControlLeave)		
	return button
end

-------------------------------------------------------------------------------------------------------------
-- CheckBox.
-------------------------------------------------------------------------------------------------------------

function JambaHelperSettings:GetCheckBoxHeight()
	-- Defined as 24 in the AceGUI CheckBox Widget.
	return 24
end

function JambaHelperSettings:GetRadioBoxHeight()
	-- Defined as 16 in the AceGUI CheckBox Widget (added 4 pixels for spacing).
	return 20
end

function JambaHelperSettings:CreateCheckBox( settingsControl, width, left, top, text, checkBoxCallback, toolTip )
	local button = AceGUI:Create( "CheckBox" )
	button:SetLabel( text )
	settingsControl.widgetSettings:AddChild( button )
	button:SetWidth( width )
	button:SetPoint( "TOPLEFT", settingsControl.widgetSettings.content, "TOPLEFT", left, top )
	button:SetCallback( "OnValueChanged", checkBoxCallback )
	button:SetUserData("tooltip", toolTip)
	button:SetCallback("OnEnter", onControlEnter)
	button:SetCallback("OnLeave", onControlLeave)
	return button
end

-------------------------------------------------------------------------------------------------------------
-- EditBox.
-------------------------------------------------------------------------------------------------------------

function JambaHelperSettings:GetEditBoxHeight()
	-- Defined as 44 (with label) in the AceGUI EditBox Widget.
	return 44
end

function JambaHelperSettings:CreateEditBox( settingsControl, width, left, top, text, toolTip )
	local editBox = AceGUI:Create( "EditBox" )
	editBox:SetLabel( text )
	settingsControl.widgetSettings:AddChild( editBox )
	editBox:SetWidth( width )
	editBox:SetPoint( "TOPLEFT", settingsControl.widgetSettings.content, "TOPLEFT", left, top )
	editBox:SetUserData("tooltip", toolTip)
	editBox:SetCallback("OnEnter", onControlEnter)
	editBox:SetCallback("OnLeave", onControlLeave)
	return editBox
end

-------------------------------------------------------------------------------------------------------------
-- Multi EditBox.
-------------------------------------------------------------------------------------------------------------

function JambaHelperSettings:CreateMultiEditBox( settingsControl, width, left, top, text, lines, toolTip )
	local editBox = AceGUI:Create( "MultiLineEditBox" )
	editBox:SetLabel( text )
	settingsControl.widgetSettings:AddChild( editBox )
	editBox:SetWidth( width )
	editBox:SetPoint( "TOPLEFT", settingsControl.widgetSettings.content, "TOPLEFT", left, top )
	editBox:SetNumLines( lines )
	editBox:SetUserData("tooltip", toolTip)
	editBox:SetCallback("OnEnter", onControlEnter)
	editBox:SetCallback("OnLeave", onControlLeave)
	return editBox
end

-------------------------------------------------------------------------------------------------------------
-- Keybinding.
-------------------------------------------------------------------------------------------------------------

function JambaHelperSettings:GetKeyBindingHeight()
	-- Defined as 44 (with label) in the AceGUI Keybinding Widget.
	return 44
end

function JambaHelperSettings:CreateKeyBinding( settingsControl, width, left, top, text )
	local keyBinding = AceGUI:Create( "JambaKeybinding" )
	keyBinding:SetLabel( text )
	settingsControl.widgetSettings:AddChild( keyBinding )
	keyBinding:SetWidth( width )
	keyBinding:SetPoint( "TOPLEFT", settingsControl.widgetSettings.content, "TOPLEFT", left, top )
	return keyBinding
end

-------------------------------------------------------------------------------------------------------------
-- Dropdown.
-------------------------------------------------------------------------------------------------------------

function JambaHelperSettings:GetDropdownHeight()
	-- Defined as 44 (with label) in the AceGUI Dropdown Widget.
	return 44
end

function JambaHelperSettings:CreateDropdown( settingsControl, width, left, top, text, toolTip )
	local dropdown = AceGUI:Create( "Dropdown" )
	--dropdown:ClearAllPoints()
	dropdown:SetLabel( text )
	settingsControl.widgetSettings:AddChild( dropdown )
	dropdown:SetWidth( width )
	dropdown:SetPoint( "TOPLEFT", settingsControl.widgetSettings.content, "TOPLEFT", left, top )
	--dropdown:SetUserData("tooltip", toolTip)
	--dropdown:SetCallback("OnEnter", onControlEnter)
	--dropdown:SetCallback("OnLeave", onControlLeave)
	return dropdown
end

-------------------------------------------------------------------------------------------------------------
-- Label.
-------------------------------------------------------------------------------------------------------------

function JambaHelperSettings:GetLabelHeight()
	-- Defined as 24 in the AceGUI JambaNormalLabel Widget.
	return 24
end

function JambaHelperSettings:CreateLabel( settingsControl, width, left, top, text )
	local label = AceGUI:Create( "JambaNormalLabel" )
	label:SetText( text )
	settingsControl.widgetSettings:AddChild( label )
	label:SetWidth( width )
	label:SetPoint( "TOPLEFT", settingsControl.widgetSettings.content, "TOPLEFT", left, top )
	return label
end

-------------------------------------------------------------------------------------------------------------
-- Label continue.
-------------------------------------------------------------------------------------------------------------

function JambaHelperSettings:GetContinueLabelHeight()
	-- Defined as 14 in the AceGUI JambaContinueLabel Widget.
	return 14
end

function JambaHelperSettings:CreateContinueLabel( settingsControl, width, left, top, text )
	local label = AceGUI:Create( "JambaContinueLabel" )
	label:SetText( text )
	settingsControl.widgetSettings:AddChild( label )
	label:SetWidth( width )
	label:SetPoint( "TOPLEFT", settingsControl.widgetSettings.content, "TOPLEFT", left, top )
	return label
end

-------------------------------------------------------------------------------------------------------------
-- Slider.
-------------------------------------------------------------------------------------------------------------

function JambaHelperSettings:GetSliderHeight()
	return 45
end

function JambaHelperSettings:CreateSlider( settingsControl, width, left, top, text )
	local slider = AceGUI:Create( "Slider" )
	slider:SetLabel( text )
	settingsControl.widgetSettings:AddChild( slider )
	slider:SetWidth( width )
	slider:SetPoint( "TOPLEFT", settingsControl.widgetSettings.content, "TOPLEFT", left, top )
	slider:SetSliderValues( 0, 100, 1 )
	slider:SetValue( 0 )
	return slider
end

-------------------------------------------------------------------------------------------------------------
-- Colour pickers.
-------------------------------------------------------------------------------------------------------------

function JambaHelperSettings:GetColourPickerHeight()
	return 25
end

function JambaHelperSettings:CreateColourPicker( settingsControl, width, left, top, text )
	local picker = AceGUI:Create( "ColorPicker" )
	picker:SetLabel( text )
	settingsControl.widgetSettings:AddChild( picker )
	picker:SetWidth( width )
	picker:SetPoint( "TOPLEFT", settingsControl.widgetSettings.content, "TOPLEFT", left, top )
	return picker
end

-------------------------------------------------------------------------------------------------------------
-- Media.
-------------------------------------------------------------------------------------------------------------

function JambaHelperSettings:GetMediaHeight()
	return 45
end

-------------------------------------------------------------------------------------------------------------
-- Media Status Bar.
-------------------------------------------------------------------------------------------------------------

function JambaHelperSettings:CreateMediaStatus( settingsControl, width, left, top, text )
	local media = AceGUI:Create( "LSM30_Statusbar" )
	media:SetLabel( text )
	media:SetWidth( width )
	media:SetPoint( "TOPLEFT", settingsControl.widgetSettings.content, "TOPLEFT", left, top )
	media:SetList()
	settingsControl.widgetSettings:AddChild( media )
	return media
end

-------------------------------------------------------------------------------------------------------------
-- Media Border.
-------------------------------------------------------------------------------------------------------------

function JambaHelperSettings:CreateMediaBorder( settingsControl, width, left, top, text )
	local media = AceGUI:Create( "LSM30_Border" )
	media:SetLabel( text )
	media:SetWidth( width )
	media:SetPoint( "TOPLEFT", settingsControl.widgetSettings.content, "TOPLEFT", left, top )
	media:SetList()
	settingsControl.widgetSettings:AddChild( media )
	return media
end

-------------------------------------------------------------------------------------------------------------
-- Media Background.
-------------------------------------------------------------------------------------------------------------

function JambaHelperSettings:CreateMediaBackground( settingsControl, width, left, top, text )
	local media = AceGUI:Create( "LSM30_Background" )
	media:SetLabel( text )
	media:SetWidth( width )
	media:SetPoint( "TOPLEFT", settingsControl.widgetSettings.content, "TOPLEFT", left, top )
	media:SetList()
	settingsControl.widgetSettings:AddChild( media )
	return media
end

-------------------------------------------------------------------------------------------------------------
-- Media Font.
-------------------------------------------------------------------------------------------------------------

function JambaHelperSettings:CreateMediaFont( settingsControl, width, left, top, text )
	local media = AceGUI:Create( "LSM30_Font" )
	media:SetLabel( text )
	media:SetWidth( width )
	media:SetPoint( "TOPLEFT", settingsControl.widgetSettings.content, "TOPLEFT", left, top )
	media:SetList()
	settingsControl.widgetSettings:AddChild( media )
	return media
end

-------------------------------------------------------------------------------------------------------------
-- Media Sound.
-------------------------------------------------------------------------------------------------------------

function JambaHelperSettings:CreateMediaSound( settingsControl, width, left, top, text )
	local media = AceGUI:Create( "LSM30_Sound" )
	media:SetLabel( text )
	media:SetWidth( width )
	media:SetPoint( "TOPLEFT", settingsControl.widgetSettings.content , "TOPLEFT", left, top )
	media:SetList()
	settingsControl.widgetSettings:AddChild( media )
	return media
end

-------------------------------------------------------------------------------------------------------------
-- FauxScrollFrame.
-------------------------------------------------------------------------------------------------------------

--
-- List Structure
--
-- Required to be passed into the function.
--
-- list.listFrameName - String (name of list frame)
-- list.parentFrame - Frame (parent frame for the list)
-- list.listTop - Number (top location in parent frame) 
-- list.listLeft - Number (left location in parent frame)
-- list.listWidth - Number (width of list) 
-- list.rowHeight - Number (height of row)
-- list.rowsToDisplay - Number (number of rows to display)
-- list.columnsToDisplay - Number (number of columns to display)
-- list.columnInformation - Table (table of columns information)
-- list.columnInformation[x]- Table (table of column information)
-- list.columnInformation[x].width - Number[0,100] (percentage of width to use for this column)
-- list.columnInformation[x].alignment - String (column text alignment string: "LEFT", "CENTER" or "RIGHT")
-- list.scrollRefreshCallback - Function (called when the list is scrolled, no parameters)
-- list.rowClickCallback - Function (called when a column in a row is clicked, parameters: self, rowNumber, columnNumber)
--
-- Created by the function.
--
-- list.listFrame - Frame (list frame holder)
-- list.listScrollFrame - Frame (list frame holder)
-- list.listHeight - Number (height of list - decided by number of display rows * height of each row)
-- list.rows - Table
-- list.rows[x] - Frame (row frame)
-- list.rows[x].highlight - Texture (row frame texture for highlight)
-- list.rows[x].columns - Table
-- list.rows[x].columns[y] - Frame (column frame)
-- list.rows[x].columns[y].rowNumber - Number (the row number of this row)
-- list.rows[x].columns[y].columnNumber - Number (the column number of this column)
-- list.rows[x].columns[y].textString - FontString (where text for column goes)
--
function JambaHelperSettings:CreateScrollList( list )
	-- Position and size constants.
	local columnSpacing = 6
	local widthOfScrollBar = 16
	local rowVerticalSpacing = 3
	local rowWidth = list.listWidth - ( columnSpacing * 2 ) - widthOfScrollBar
	list.listHeight = list.rowsToDisplay * list.rowHeight + ( rowVerticalSpacing * 2 )
	-- Create the holder frame.
	list.listFrame = CreateFrame( 
		"Frame", 
		list.listFrameName, 
		list.parentFrame 
	)
	list.listFrame:SetBackdrop( self:CreateBackdrop() )
	list.listFrame:SetBackdropColor( 0.1, 0.1, 0.1, 0.5 )
	list.listFrame:SetBackdropBorderColor( 0.4, 0.4, 0.4 )
	list.listFrame:SetPoint( "TOPLEFT", list.parentFrame, "TOPLEFT", list.listLeft, list.listTop )
	list.listFrame:SetWidth( list.listWidth )
	list.listFrame:SetHeight( list.listHeight )
	-- Create the scroll frame.
	list.listScrollFrame = CreateFrame(
		"ScrollFrame", 
		list.listFrame:GetName().."ScrollFrame", 
		list.listFrame, 
		"FauxScrollFrameTemplate"
	)
	list.listScrollFrame:SetPoint( "TOPLEFT", list.listFrame, "TOPLEFT", 0, -4 )
	list.listScrollFrame:SetPoint( "BOTTOMRIGHT", list.listFrame, "BOTTOMRIGHT", -26, 3 )
	list.listScrollFrame:SetScript( "OnVerticalScroll", 
		function( self, offset )
			FauxScrollFrame_OnVerticalScroll( 
				self, 
				offset, 
				list.rowHeight, 
				list.scrollRefreshCallback )			
		end 
	)
	-- Create frames for scroll table rows and columns.
	list.rows = {}
	for iterateDisplayRows = 1, list.rowsToDisplay do 
		local displayRow = CreateFrame( 
			"Frame",
			list.listFrame:GetName().."Row"..iterateDisplayRows, 
			list.listFrame 
		)
		displayRow:SetWidth( rowWidth )
		displayRow:SetHeight( list.rowHeight )
		displayRow:SetPoint( 
			"TOPLEFT", 
			list.listFrame, 
			"TOPLEFT", 
			columnSpacing, 
			( -1 * rowVerticalSpacing ) - ( list.rowHeight * ( iterateDisplayRows - 1 ) )
		)
		displayRow.highlight = displayRow:CreateTexture( nil, "OVERLAY" )
		displayRow.highlight:SetAllPoints( displayRow )
		list.rows[iterateDisplayRows] = displayRow		
		displayRow.columns = {}
		local columnPosition = 0
		for iterateDisplayColumns = 1, list.columnsToDisplay do
			local displayColumn = CreateFrame(
				"Button",
				displayRow:GetName().."Column"..iterateDisplayColumns, 
				displayRow
			)
			displayColumn.rowNumber = iterateDisplayRows
			displayColumn.columnNumber = iterateDisplayColumns
			displayColumn.textString = displayRow:CreateFontString( 
				displayColumn:GetName().."Text", 
				"OVERLAY", 
				"GameFontHighlight" 
			)
			local columnWidth = ( list.columnInformation[iterateDisplayColumns].width / 100 ) * 
				( rowWidth - ( columnSpacing * ( list.columnsToDisplay - 1 ) ) )
			displayColumn:SetPoint( "TOPLEFT", displayRow, "TOPLEFT", columnPosition, 0 )
			displayColumn:SetWidth( columnWidth )
			displayColumn:SetHeight( list.rowHeight )				
			displayColumn:EnableMouse( true )
			displayColumn:RegisterForClicks( "AnyUp" )	
			displayColumn:SetScript( "OnClick", 
				function( self )
					list.rowClickCallback( self, displayColumn.rowNumber, displayColumn.columnNumber )
				end 
			)	
			displayColumn.textString:SetJustifyH( list.columnInformation[iterateDisplayColumns].alignment )
			displayColumn.textString:SetAllPoints( displayColumn )		
			displayRow.columns[iterateDisplayColumns] = displayColumn
			columnPosition = columnPosition + columnWidth + columnSpacing
		end
	end
end
	
function JambaHelperSettings:SetFauxScrollFramePosition( scrollFrame, position, maxPosition, rowHeight )
	FauxScrollFrame_SetOffset( scrollFrame, position )
	local scrollBar = getglobal( scrollFrame:GetName().."ScrollBar" )
	if scrollBar ~= nil then
		local minScroll, maxScroll = scrollBar:GetMinMaxValues()
		scrollBar:SetValue( minScroll + ( ( maxScroll - minScroll + (2 * rowHeight) ) * position / maxPosition ) )
	end
end
