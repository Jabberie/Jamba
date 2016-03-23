--[[
Jamba - Jafula's Awesome Multi-Boxer Assistant
Copyright 2008 - 2016 Michael "Jafula" Miller
License: The MIT License
]]--

-- Create the addon using AceAddon-3.0 and embed some libraries.
local AJM = LibStub( "AceAddon-3.0" ):NewAddon( 
	"JambaDisplayTeam",
	"JambaModule-1.0", 
	"AceConsole-3.0", 
	"AceEvent-3.0",
	"AceHook-3.0",
	"AceTimer-3.0"
)

-- Load libraries.
local JambaUtilities = LibStub:GetLibrary( "JambaUtilities-1.0" )
local JambaHelperSettings = LibStub:GetLibrary( "JambaHelperSettings-1.0" )
local LibBagUtils = LibStub:GetLibrary( "LibBagUtils-1.0" )
AJM.SharedMedia = LibStub( "LibSharedMedia-3.0" )

-- Constants required by JambaModule and Locale for this module.
AJM.moduleName = "JmbDspTm"
AJM.settingsDatabaseName = "JambaDisplayTeamProfileDB"
AJM.chatCommand = "jamba-display-team"
local L = LibStub( "AceLocale-3.0" ):GetLocale( AJM.moduleName )
AJM.parentDisplayName = L["Team"]
AJM.moduleDisplayName = L["Display: Team"]

-- Settings - the values to store and their defaults for the settings database.
AJM.settings = {
	profile = {
		showTeamList = true,
		showTeamListOnMasterOnly = true,
		hideTeamListInCombat = false,
		enableClique = false,
		statusBarTexture = L["Blizzard"],
		borderStyle = L["Blizzard Tooltip"],
		backgroundStyle = L["Blizzard Dialog Background"],
		teamListScale = 1,
		teamListTitleHeight = 15,
		teamListVerticalSpacing = 4,
		teamListHorizontalSpacing = 4,
		barVerticalSpacing = 2,
		barHorizontalSpacing = 2,
		barsAreStackedVertically = false,
		teamListHorizontal = false,
		showListTitle = true,
		showCharacterPortrait = true,
		characterPortraitWidth = 20,
		showFollowStatus = true,
		followStatusWidth = 80,
		followStatusHeight = 20,
		followStatusShowName = true,
--		followStatusShowLevel = true,	
		showExperienceStatus = true,
		experienceStatusWidth = 80,
		experienceStatusHeight = 20,
		experienceStatusShowValues = false,
		experienceStatusShowPercentage = true,
		showReputationStatus = true,
		showReputationName = true,
		reputationStatusWidth = 80,
		reputationStatusHeight = 20,
		reputationStatusShowValues = false,
		reputationStatusShowPercentage = true,		
		showHealthStatus = false,
		healthStatusWidth = 80,
		healthStatusHeight = 20,
		healthStatusShowValues = true,
		healthStatusShowPercentage = true,		
		showPowerStatus = false,
		powerStatusWidth = 80,
		powerStatusHeight = 20,
		powerStatusShowValues = true,
		powerStatusShowPercentage = true,
		showComboStatus = false,
		comboStatusWidth = 80,
		comboStatusHeight = 20,
		comboStatusShowValues = true,
		comboStatusShowPercentage = true,		
--		showBagInformation = true,
--		showBagFreeSlotsOnly = true,
--		bagInformationWidth = 80,
--		bagInformationHeight = 25,
		--EbonyTest
--		stackName = false,
--		showIlvlInformation = true,
--		ShowEquippedOnly = false,
		--ilvlInformationWidth = 80,
		--ilvlInformationHeight = 20,
		framePoint = "CENTER",
		frameRelativePoint = "CENTER",
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
		timerCount = 1,
		currGold = true
	},
}

-- Debug message.
function AJM:DebugMessage( ... )
	--AJM:Print( ... )
end

-- Configuration.
function AJM:GetConfiguration()
	local configuration = {
		name = AJM.moduleDisplayName,
		handler = AJM,
		type = "group",
		get = "JambaConfigurationGetSetting",
		set = "JambaConfigurationSetSetting",
		args = {	
			push = {
				type = "input",
				name = L["Push Settings"],
				desc = L["Push the display team settings to all characters in the team."],
				usage = "/jamba-display-team push",
				get = false,
				set = "JambaSendSettings",
			},	
			hide = {
				type = "input",
				name = L["Hide Team Display"],
				desc = L["Hide the display team panel."],
				usage = "/jamba-display-team hide",
				get = false,
				set = "HideTeamListCommand",
			},	
			show = {
				type = "input",
				name = L["Show Team Display"],
				desc = L["Show the display team panel."],
				usage = "/jamba-display-team show",
				get = false,
				set = "ShowTeamListCommand",
			},				
		},
	}
	return configuration
end

-------------------------------------------------------------------------------------------------------------
-- Command this module sends.
-------------------------------------------------------------------------------------------------------------

AJM.COMMAND_FOLLOW_STATUS_UPDATE = "FlwStsUpd"
AJM.COMMAND_EXPERIENCE_STATUS_UPDATE = "ExpStsUpd"
--AJM.COMMAND_BAGINFORMATION_UPDATE = "BagInfoUpd"
AJM.COMMAND_ITEMLEVELINFORMATION_UPDATE = "IlvlInfoUpd"
AJM.COMMAND_REPUTATION_STATUS_UPDATE = "RepStsUpd"
AJM.COMMAND_COMBO_STATUS_UPDATE = "CboStsUpd"
AJM.COMMAND_REQUEST_INFO = "SendInfo"

-------------------------------------------------------------------------------------------------------------
-- Messages module sends.
-------------------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------------------------
-- Constants used by module.
-------------------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------------------------
-- Variables used by module.
-------------------------------------------------------------------------------------------------------------

-- Team display variables.
AJM.globalFramePrefix = "JambaDisplayTeam"
AJM.characterStatusBar = {}
AJM.totalMembersDisplayed = 0
AJM.teamListCreated = false	
AJM.refreshHideTeamListControlsPending = false
AJM.refreshShowTeamListControlsPending = false
AJM.updateSettingsAfterCombat = false

-------------------------------------------------------------------------------------------------------------
-- Team Frame.
-------------------------------------------------------------------------------------------------------------

local function GetCharacterHeight()
	local height = 0
	local heightPortrait = 0
	local heightFollowStatus = 0
	local heightExperienceStatus = 0
	local heightReputationStatus = 0
	local heightHealthStatus = 0
	local heightPowerStatus = 0
	local heightComboStatus = 0	
--	local heightBagInformation = 0	
	--local heightIlvlInformation = 0	
	local heightAllBars = 0
	if AJM.db.showCharacterPortrait == true then
		heightPortrait = AJM.db.characterPortraitWidth + AJM.db.teamListVerticalSpacing
	end
--	if AJM.db.showBagInformation == true then
--		heightBagInformation = AJM.db.bagInformationHeight + AJM.db.teamListVerticalSpacing
--		heightAllBars = heightAllBars + heightBagInformation
--	end	
--	if AJM.db.showIlvlInformation == true then
--		heightIlvlInformation = AJM.db.ilvlInformationHeight + AJM.db.teamListVerticalSpacing
--		heightAllBars = heightAllBars + heightIlvlInformation
--	end
	if AJM.db.showFollowStatus == true then
		heightFollowStatus = AJM.db.followStatusHeight + AJM.db.barVerticalSpacing
		heightAllBars = heightAllBars + heightFollowStatus
	end
	if AJM.db.showExperienceStatus == true then
		heightExperienceStatus = AJM.db.experienceStatusHeight + AJM.db.barVerticalSpacing
		heightAllBars = heightAllBars + heightExperienceStatus
	end
	if AJM.db.showReputationStatus == true then
		heightReputationStatus = AJM.db.reputationStatusHeight + AJM.db.barVerticalSpacing
		heightAllBars = heightAllBars + heightReputationStatus
	end	
	if AJM.db.showHealthStatus == true then
		heightHealthStatus = AJM.db.healthStatusHeight + AJM.db.barVerticalSpacing
		heightAllBars = heightAllBars + heightHealthStatus
	end
	if AJM.db.showPowerStatus == true then
		heightPowerStatus = AJM.db.powerStatusHeight + AJM.db.barVerticalSpacing
		heightAllBars = heightAllBars + heightPowerStatus
	end
	if AJM.db.showComboStatus == true then
		heightComboStatus = AJM.db.comboStatusHeight + AJM.db.barVerticalSpacing
		heightAllBars = heightAllBars + heightComboStatus
	end	
	if AJM.db.barsAreStackedVertically == true then
		height = max( heightPortrait, heightAllBars )
	else
	height = max( heightPortrait, heightFollowStatus, heightExperienceStatus, heightReputationStatus, heightHealthStatus, heightPowerStatus, heightComboStatus )
	--height = max( heightPortrait, heightBagInformation, heightFollowStatus, heightExperienceStatus, heightReputationStatus, heightHealthStatus, heightPowerStatus, heightComboStatus )
	end
	return height
end

local function GetCharacterWidth()
	local width = 0
	local widthPortrait = 0
	local widthFollowStatus = 0
	local widthExperienceStatus = 0
	local widthReputationStatus = 0
	local widthHealthStatus = 0
	local widthPowerStatus = 0
	local widthComboStatus = 0	
--	local widthBagInformation = 0
--	local widthIvlInformation = 0
	local widthAllBars = 0
	if AJM.db.showCharacterPortrait == true then
		widthPortrait = AJM.db.characterPortraitWidth + AJM.db.teamListHorizontalSpacing
	end
--	if AJM.db.showBagInformation == true then
--		widthBagInformation = AJM.db.bagInformationWidth + AJM.db.teamListHorizontalSpacing
--		widthAllBars = widthAllBars + widthBagInformation
--	end		
	--if AJM.db.showIlvlInformation == true then
	--	widthIlvlInformation = AJM.db.ilvlInformationWidth + AJM.db.teamListHorizontalSpacing
	--	widthAllBars = widthAllBars + widthIlvlInformation
	--end
	if AJM.db.showFollowStatus == true then
		widthFollowStatus = AJM.db.followStatusWidth + AJM.db.barHorizontalSpacing
		widthAllBars = widthAllBars + widthFollowStatus
	end
	if AJM.db.showExperienceStatus == true then
		widthExperienceStatus = AJM.db.experienceStatusWidth + AJM.db.barHorizontalSpacing
		widthAllBars = widthAllBars + widthExperienceStatus		
	end
	if AJM.db.showReputationStatus == true then
		widthReputationStatus = AJM.db.reputationStatusWidth + AJM.db.barHorizontalSpacing
		widthAllBars = widthAllBars + widthReputationStatus		
	end	
	if AJM.db.showHealthStatus == true then
		widthHealthStatus = AJM.db.healthStatusWidth + AJM.db.barHorizontalSpacing
		widthAllBars = widthAllBars + widthHealthStatus		
	end	
	if AJM.db.showPowerStatus == true then
		widthPowerStatus = AJM.db.powerStatusWidth + AJM.db.barHorizontalSpacing
		widthAllBars = widthAllBars + widthPowerStatus		
	end
	if AJM.db.showComboStatus == true then
		widthComboStatus = AJM.db.comboStatusWidth + AJM.db.barHorizontalSpacing
		widthAllBars = widthAllBars + widthComboStatus		
	end
	if AJM.db.barsAreStackedVertically == true then
		width = widthPortrait + max( widthFollowStatus, widthExperienceStatus, widthReputationStatus, widthHealthStatus, widthPowerStatus, widthComboStatus )		
		--width = widthPortrait + max( widthBagInformation, widthFollowStatus, widthExperienceStatus, widthReputationStatus, widthHealthStatus, widthPowerStatus, widthComboStatus )
	else
		width = widthPortrait + widthAllBars
	end
	return width
end

local function UpdateJambaTeamListDimensions()
	local frame = JambaDisplayTeamListFrame
	if AJM.db.showListTitle == true then
		AJM.db.teamListTitleHeight = 15
		JambaDisplayTeamListFrame.titleName:SetText( L["Jamba Team"] )
	else
		AJM.db.teamListTitleHeight = 0
		JambaDisplayTeamListFrame.titleName:SetText( "" )
	end
	if AJM.db.teamListHorizontal == true then
		frame:SetWidth( (AJM.db.teamListVerticalSpacing * 3) + (GetCharacterWidth() * AJM.totalMembersDisplayed) )
		frame:SetHeight( AJM.db.teamListTitleHeight + (AJM.db.teamListVerticalSpacing * 3) + GetCharacterHeight() )
	else
		frame:SetWidth( (AJM.db.teamListHorizontalSpacing * 3) + GetCharacterWidth() )
		frame:SetHeight( AJM.db.teamListTitleHeight + (GetCharacterHeight() * AJM.totalMembersDisplayed) + (AJM.db.teamListVerticalSpacing * 3) )
	end
	frame:SetScale( AJM.db.teamListScale )
end

local function CreateJambaTeamInfoFrame()
	local frame = CreateFrame( "Frame", "JambaTeamInfoWindowFrame", UIParent )
		frame.obj = AJM
	frame:SetFrameStrata( "LOW" )
	frame:SetToplevel( true )
	frame:SetClampedToScreen( true )
	frame:EnableMouse( true )
	frame:SetMovable( true )	
	frame:RegisterForDrag( "LeftButton" )
	frame:SetScript( "OnDragStart", 
		function( this ) 
			if IsAltKeyDown() then
				if not UnitAffectingCombat("player") then		
					this:StartMoving()
				end	
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

	
end




local function CreateJambaTeamListFrame()
	-- The frame.
	local frame = CreateFrame( "Frame", "JambaDisplayTeamListWindowFrame", UIParent )
	frame.obj = AJM
	frame:SetFrameStrata( "LOW" )
	frame:SetToplevel( true )
	frame:SetClampedToScreen( true )
	frame:EnableMouse( true )
	frame:SetMovable( true )	
	frame:RegisterForDrag( "LeftButton" )
	frame:SetScript( "OnDragStart", 
		function( this ) 
			if IsAltKeyDown() then
				if not UnitAffectingCombat("player") then		
					this:StartMoving()
				end	
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

	-- Create the title for the team list frame.
	local titleName = frame:CreateFontString( "JambaDisplayTeamListWindowFrameTitleText", "OVERLAY", "GameFontNormal" )
	titleName:SetPoint( "TOP", frame, "TOP", 0, -5 )
	titleName:SetTextColor( 1.00, 1.00, 1.00 )
	titleName:SetText( L["Jamba Team"] )
	frame.titleName = titleName
	
	-- Set transparency of the the frame (and all its children).
	frame:SetAlpha(AJM.db.frameAlpha)
	
	-- Set the global frame reference for this frame.
	JambaDisplayTeamListFrame = frame
	
	AJM:SettingsUpdateBorderStyle()	
	AJM.teamListCreated = true

--[[
	-- Draw the title.
	if AJM.db.teamListStatusWidth >= 90 then
		JambaDisplayTeamListFrame.titleName:SetText( L["Jamba Team"] )
	else
		JambaDisplayTeamListFrame.titleName:SetText( L["Team"] )
	end
]]--	
end

local function CanDisplayTeamList()
	local canShow = false
	if AJM.db.showTeamList == true then
		if AJM.db.showTeamListOnMasterOnly == true then
			if JambaApi.IsCharacterTheMaster( AJM.characterName ) == true then
				canShow = true
			end
		else
			canShow = true
		end
	end
	return canShow
end

function AJM:ShowTeamListCommand()
	AJM.db.showTeamList = true
	AJM:SetTeamListVisibility()
end

function AJM:HideTeamListCommand()
	AJM.db.showTeamList = false
	AJM:SetTeamListVisibility()
end

function AJM:SetTeamListVisibility()
	if CanDisplayTeamList() == true then
		JambaDisplayTeamListFrame:ClearAllPoints()
		JambaDisplayTeamListFrame:SetPoint( AJM.db.framePoint, UIParent, AJM.db.frameRelativePoint, AJM.db.frameXOffset, AJM.db.frameYOffset )
		JambaDisplayTeamListFrame:SetAlpha( AJM.db.frameAlpha )
		JambaDisplayTeamListFrame:Show()
	else
		JambaDisplayTeamListFrame:Hide()
	end	
end

function AJM:RefreshTeamListControlsHide()
	if InCombatLockdown() then
		AJM.refreshHideTeamListControlsPending = true
		return
	end
	for characterName, characterStatusBar in pairs( AJM.characterStatusBar ) do	
		characterName = JambaUtilities:AddRealmToNameIfMissing ( characterName ) 
		-- Hide their status bar.
		AJM:HideJambaTeamStatusBar( characterName )		
	end
	UpdateJambaTeamListDimensions()
end

function AJM:RefreshTeamListControlsShow()
	if InCombatLockdown() then
		AJM.refreshShowTeamListControlsPending = true
		return
	end
	-- Iterate all the team members.
	AJM.totalMembersDisplayed = 0
	for index, characterName in JambaApi.TeamListOrdered() do
		characterName = JambaUtilities:AddRealmToNameIfMissing ( characterName )
		-- Is the team member online?
		if JambaApi.GetCharacterOnlineStatus( characterName ) == true then
			-- Yes, the team member is online, draw their status bars.
			AJM:UpdateJambaTeamStatusBar( characterName, AJM.totalMembersDisplayed )		
			AJM.totalMembersDisplayed = AJM.totalMembersDisplayed + 1
		end
	end
	UpdateJambaTeamListDimensions()	
end
	
function AJM:RefreshTeamListControls()
	AJM:RefreshTeamListControlsHide()
	AJM:RefreshTeamListControlsShow()
end

function AJM:SettingsUpdateStatusBarTexture()
	local statusBarTexture = AJM.SharedMedia:Fetch( "statusbar", AJM.db.statusBarTexture )
	for characterName, characterStatusBar in pairs( AJM.characterStatusBar ) do	
		characterStatusBar["followBar"]:SetStatusBarTexture( statusBarTexture )
		characterStatusBar["followBar"]:GetStatusBarTexture():SetHorizTile( false )
		characterStatusBar["followBar"]:GetStatusBarTexture():SetVertTile( false )		
		characterStatusBar["experienceBar"]:SetStatusBarTexture( statusBarTexture )
		characterStatusBar["experienceBar"]:GetStatusBarTexture():SetHorizTile( false )
		characterStatusBar["experienceBar"]:GetStatusBarTexture():SetVertTile( false )
		characterStatusBar["reputationBar"]:SetStatusBarTexture( statusBarTexture )
		characterStatusBar["reputationBar"]:GetStatusBarTexture():SetHorizTile( false )
		characterStatusBar["reputationBar"]:GetStatusBarTexture():SetVertTile( false )		
		characterStatusBar["healthBar"]:SetStatusBarTexture( statusBarTexture )
		characterStatusBar["healthBar"]:GetStatusBarTexture():SetHorizTile( false )
		characterStatusBar["healthBar"]:GetStatusBarTexture():SetVertTile( false )		
		characterStatusBar["powerBar"]:SetStatusBarTexture( statusBarTexture )
		characterStatusBar["powerBar"]:GetStatusBarTexture():SetHorizTile( false )
		characterStatusBar["powerBar"]:GetStatusBarTexture():SetVertTile( false )
		characterStatusBar["comboBar"]:SetStatusBarTexture( statusBarTexture )
		characterStatusBar["comboBar"]:GetStatusBarTexture():SetHorizTile( false )
		characterStatusBar["comboBar"]:GetStatusBarTexture():SetVertTile( false )
	end
end

function AJM:SettingsUpdateBorderStyle()
	local borderStyle = AJM.SharedMedia:Fetch( "border", AJM.db.borderStyle )
	local backgroundStyle = AJM.SharedMedia:Fetch( "background", AJM.db.backgroundStyle )
	local frame = JambaDisplayTeamListFrame
	frame:SetBackdrop( {
		bgFile = backgroundStyle, 
		edgeFile = borderStyle, 
		tile = true, tileSize = frame:GetWidth(), edgeSize = 10, 
		insets = { left = 3, right = 3, top = 3, bottom = 3 }
	} )
	frame:SetBackdropColor( AJM.db.frameBackgroundColourR, AJM.db.frameBackgroundColourG, AJM.db.frameBackgroundColourB, AJM.db.frameBackgroundColourA )
	frame:SetBackdropBorderColor( AJM.db.frameBorderColourR, AJM.db.frameBorderColourG, AJM.db.frameBorderColourB, AJM.db.frameBorderColourA )	
end

function AJM:CreateJambaTeamStatusBar( characterName, parentFrame )
	local statusBarTexture = AJM.SharedMedia:Fetch( "statusbar", AJM.db.statusBarTexture )
	-- Create the table to hold the status bars for this character.
	AJM.characterStatusBar[characterName] = {}
	-- Get the status bars table.
	local characterStatusBar = AJM.characterStatusBar[characterName]
	-- Set the portrait.
	local portraitName = AJM.globalFramePrefix.."PortraitButton"
	local portraitButton = CreateFrame( "PlayerModel", portraitName, parentFrame )
	--portraitButton.Texture = portraitButton:CreateTexture( portraitName.."NormalTexture", "ARTWORK" )
	--SetPortraitTexture( portraitButton.Texture, characterName )
	--portraitButton.Texture:SetAllPoints()
	portraitButton:ClearModel()
	portraitButton:SetUnit( Ambiguate( characterName, "short" ) )
	portraitButton:SetPortraitZoom( 1 )
    portraitButton:SetCamDistanceScale( 1 )
    portraitButton:SetPosition( 0, 0, 0 )
	local portraitButtonClick = CreateFrame( "CheckButton", portraitName.."Click", parentFrame, "SecureActionButtonTemplate" )
	portraitButtonClick:SetAttribute( "unit", Ambiguate( characterName, "all" ) )
	characterStatusBar["portraitButton"] = portraitButton
	characterStatusBar["portraitButtonClick"] = portraitButtonClick
--[[
	-- Set the bag information.
	local bagInformationFrameName = AJM.globalFramePrefix.."BagInformationFrame"
	local bagInformationFrame = CreateFrame( "Frame", bagInformationFrameName, parentFrame )
	local bagInformationFrameText = bagInformationFrame:CreateFontString( bagInformationFrameName.."Text", "OVERLAY", "GameFontNormal" )
	bagInformationFrameText:SetText( "999/999" )
	bagInformationFrame:SetAlpha( 1 )
	--bagInformationFrameText:SetPoint( "CENTER", bagInformationFrame, "CENTER", 0, 0 )
	bagInformationFrameText:SetAllPoints()
	bagInformationFrameText:SetJustifyH( "CENTER" )
	bagInformationFrameText:SetJustifyV( "MIDDLE" )
	bagInformationFrameText:SetTextColor( 1.00, 1.00, 1.00, 1.00 )
	bagInformationFrame.slotsFree = 999
	bagInformationFrame.totalSlots = 999
	--bagInformationFrame.durability = 100
	characterStatusBar["bagInformationFrame"] = bagInformationFrame
	characterStatusBar["bagInformationFrameText"] = bagInformationFrameText
--]]
	--set the ilevel Information.	
	local ilvlInformationFrameName = AJM.globalFramePrefix.."IlvlInformationFrame"
	local ilvlInformationFrame = CreateFrame( "Frame", ilvlInformationFrameName, parentFrame )
	local ilvlInformationFrameText = ilvlInformationFrame:CreateFontString( ilvlInformationFrameName.."Text", "OVERLAY", "GameFontNormal" )
	ilvlInformationFrameText:SetText( "999/999" )
	ilvlInformationFrameText:SetAllPoints()
	ilvlInformationFrameText:SetJustifyH( "CENTER" )
	ilvlInformationFrameText:SetJustifyV( "MIDDLE" )
	ilvlInformationFrameText:SetTextColor( 1.00, 1.00, 1.00, 1.00 )
	ilvlInformationFrame.overall = 999
	ilvlInformationFrame.equipped = 999
	ilvlInformationFrame.characterLevel = 0
	ilvlInformationFrame.gold = 0
	ilvlInformationFrame.durability = 100
	ilvlInformationFrame.slotsFree = 999
	ilvlInformationFrame.totalSlots = 999
	ilvlInformationFrame.toolText = "nothing"
	ilvlInformationFrame.currText = "nothing"
	characterStatusBar["ilvlInformationFrame"] = ilvlInformationFrame
	characterStatusBar["ilvlInformationFrameText"] = ilvlInformationFrameText	
	characterStatusBar["ilvlInformationFrameText"] = ilvlInformationFrameText
	-- Set the follow bar.
	local followName = AJM.globalFramePrefix.."FollowBar"
	local followBar = CreateFrame( "StatusBar", followName, parentFrame, "TextStatusBar,SecureActionButtonTemplate" )
	followBar.backgroundTexture = followBar:CreateTexture( followName.."BackgroundTexture", "ARTWORK" )
	followBar.backgroundTexture:SetTexture( 0.58, 0.0, 0.55, 0.15 )
	followBar:SetStatusBarTexture( statusBarTexture )
	followBar:GetStatusBarTexture():SetHorizTile( false )
	followBar:GetStatusBarTexture():SetVertTile( false )
	followBar:SetStatusBarColor( 0.55, 0.15, 0.15, 0.25 )
	followBar:SetMinMaxValues( 0, 100 )
	followBar:SetValue( 100 )
	followBar:SetFrameStrata( "LOW" )
	followBar:SetAlpha( 1 )
	local followBarClick = CreateFrame( "CheckButton", followName.."Click", parentFrame, "SecureActionButtonTemplate" )
	followBarClick:SetAttribute( "unit", Ambiguate( characterName, "all" ) )
	followBarClick:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
	--followBarClick:SetAttribute( "macrotext", "/targetexact "..characterName )
	followBarClick:SetFrameStrata( "MEDIUM" )
	characterStatusBar["followBar"] = followBar
	characterStatusBar["followBarClick"] = followBarClick	
	local followBarText = followBar:CreateFontString( followName.."Text", "OVERLAY", "GameFontNormal" )
	followBarText:SetTextColor( 1.00, 1.00, 1.00, 1.00 )
	followBarText:SetAllPoints()
	characterStatusBar["followBarText"] = followBarText
	AJM:SettingsUpdateFollowText( characterName, UnitLevel( Ambiguate( characterName, "none" ) ), nil, nil )
		--Tooltip test work...
		followBarClick:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_TOP")
			AJM:JambaRequestUpdate()
			GameTooltip:AddLine(L["Toon Information"], 1, 0.82, 0, 1)	
		--level of platyer if not max.
		local maxLevel = GetMaxPlayerLevel()
			--AJM:Print(ilvlInformationFrame.characterLevel, maxLevel )
		if ilvlInformationFrame.characterLevel == maxLevel == false then
			GameTooltip:AddLine(L["Player Level:"]..L[" "]..L["("]..tostring (format("%.0f", ilvlInformationFrame.characterLevel ))..L[")"],1,1,1,1)
		end
		-- Item Level of player
			GameTooltip:AddLine(L["Item Level:"]..L[" "]..L["("]..tostring (format("%.0f", ilvlInformationFrame.equipped ))..L[")"],1,1,1,1)
		-- Bag Space
			GameTooltip:AddLine(L["Bag Space:"]..L[" "]..L["("]..tostring(ilvlInformationFrame.slotsFree).."/"..tostring(ilvlInformationFrame.totalSlots)..L[")"],1,1,1,1)
		-- Durability
			GameTooltip:AddLine(L["Durability:"]..L[" "]..L["("]..tostring(gsub(ilvlInformationFrame.durability, "%.[^|]+", "") )..L["%"]..L[")"],1,1,1,1)
		-- Gold
			GameTooltip:AddLine(L["Gold:"]..L[" "]..GetCoinTextureString( ilvlInformationFrame.gold ),1,1,1,1)
		--AJM:Print("mail", ilvlInformationFrame.toolText, "Curr", ilvlInformationFrame.currText)
		-- Shows if has Ingame Mail
			if not (ilvlInformationFrame.toolText == "nothing") then
				GameTooltip:AddLine(" ",1,1,1,1)
				GameTooltip:AddLine(L["Has New Mail From:"], 1, 0.82, 0, 1)
				GameTooltip:AddLine(ilvlInformationFrame.toolText,1,1,1,1)
			end	
		-- Shows if currency is on backback
			if not (ilvlInformationFrame.currText == "nothing") then
				GameTooltip:AddLine(" ",1,1,1,1)
				GameTooltip:AddLine(L["Currency:"], 1, 0.83, 0, 1)
				GameTooltip:AddLine(ilvlInformationFrame.currText,1,1,1,1)
			end
				GameTooltip:Show()
		end)
	-- Set the experience bar.
	local experienceName = AJM.globalFramePrefix.."ExperienceBar"
	local experienceBar = CreateFrame( "StatusBar", experienceName, parentFrame, "TextStatusBar,SecureActionButtonTemplate" )
	experienceBar.backgroundTexture = experienceBar:CreateTexture( experienceName.."BackgroundTexture", "ARTWORK" )
	experienceBar.backgroundTexture:SetTexture( 0.0, 0.39, 0.88, 0.15 )
	experienceBar:SetStatusBarTexture( statusBarTexture )
	experienceBar:GetStatusBarTexture():SetHorizTile( false )
	experienceBar:GetStatusBarTexture():SetVertTile( false )
	experienceBar:SetMinMaxValues( 0, 100 )
	experienceBar:SetValue( 100 )
	experienceBar:SetFrameStrata( "LOW" )
	local experienceBarClick = CreateFrame( "CheckButton", experienceName.."Click", parentFrame, "SecureActionButtonTemplate" )
	experienceBarClick:SetAttribute( "unit", Ambiguate( characterName, "all" ) )
	experienceBarClick:SetFrameStrata( "MEDIUM" )
	characterStatusBar["experienceBar"] = experienceBar
	characterStatusBar["experienceBarClick"] = experienceBarClick
	local experienceBarText = experienceBar:CreateFontString( experienceName.."Text", "OVERLAY", "GameFontNormal" )
	experienceBarText:SetTextColor( 1.00, 1.00, 1.00, 1.00 )
	experienceBarText:SetAllPoints()
	experienceBarText.playerExperience = 100
	experienceBarText.playerMaxExperience = 100
	experienceBarText.exhaustionStateID = 1
	characterStatusBar["experienceBarText"] = experienceBarText
	AJM:UpdateExperienceStatus( characterName, nil, nil, nil )
	-- Set the reputation bar.
	local reputationName = AJM.globalFramePrefix.."ReputationBar"
	local reputationBar = CreateFrame( "StatusBar", reputationName, parentFrame, "TextStatusBar,SecureActionButtonTemplate" )
	reputationBar.backgroundTexture = reputationBar:CreateTexture( reputationName.."BackgroundTexture", "ARTWORK" )
	reputationBar.backgroundTexture:SetTexture( 0.0, 0.39, 0.88, 0.15 )
	reputationBar:SetStatusBarTexture( statusBarTexture )
	reputationBar:GetStatusBarTexture():SetHorizTile( false )
	reputationBar:GetStatusBarTexture():SetVertTile( false )
	reputationBar:SetMinMaxValues( 0, 100 )
	reputationBar:SetValue( 100 )
	reputationBar:SetFrameStrata( "LOW" )
	reputationBar:SetAlpha( 1 )
	local reputationBarClick = CreateFrame( "CheckButton", reputationName.."Click", parentFrame, "SecureActionButtonTemplate" )
	reputationBarClick:SetAttribute( "unit", Ambiguate( characterName, "all" ) )
	reputationBarClick:SetFrameStrata( "MEDIUM" )
	characterStatusBar["reputationBar"] = reputationBar
	characterStatusBar["reputationBarClick"] = reputationBarClick
	local reputationBarText = reputationBar:CreateFontString( reputationName.."Text", "OVERLAY", "GameFontNormal" )
	reputationBarText:SetTextColor( 1.00, 1.00, 1.00, 1.00 )
	reputationBarText:SetAllPoints()
	reputationBarText.reputationName = "Faction"
	reputationBarText.reputationStandingID = 4
	reputationBarText.reputationBarMin = 0
	reputationBarText.reputationBarMax = 100
	reputationBarText.reputationBarValue = 100
	characterStatusBar["reputationBarText"] = reputationBarText
	AJM:UpdateReputationStatus( characterName, nil, nil, nil )
	-- Set the health bar.
	local healthName = AJM.globalFramePrefix.."HealthBar"
	local healthBar = CreateFrame( "StatusBar", healthName, parentFrame, "TextStatusBar,SecureActionButtonTemplate" )
	healthBar.backgroundTexture = healthBar:CreateTexture( healthName.."BackgroundTexture", "ARTWORK" )
	healthBar.backgroundTexture:SetTexture( 0.58, 0.0, 0.55, 0.15 )
	healthBar:SetStatusBarTexture( statusBarTexture )
	healthBar:GetStatusBarTexture():SetHorizTile( false )
	healthBar:GetStatusBarTexture():SetVertTile( false )
	healthBar:SetMinMaxValues( 0, 100 )
	healthBar:SetValue( 100 )
	healthBar:SetFrameStrata( "LOW" )
	healthBar:SetAlpha( 1 )
	local healthBarClick = CreateFrame( "CheckButton", healthName.."Click"..characterName, parentFrame, "SecureActionButtonTemplate" )
	healthBarClick:SetAttribute( "unit", Ambiguate( characterName, "all" ) )
	healthBarClick:SetFrameStrata( "MEDIUM" )
	characterStatusBar["healthBar"] = healthBar
	characterStatusBar["healthBarClick"] = healthBarClick
	local healthBarText = healthBar:CreateFontString( healthName.."Text", "OVERLAY", "GameFontNormal" )
	healthBarText:SetTextColor( 1.00, 1.00, 1.00, 1.00 )
	healthBarText:SetAllPoints()
	healthBarText.playerHealth = 100
	healthBarText.playerMaxHealth = 100
	characterStatusBar["healthBarText"] = healthBarText
	AJM:UpdateHealthStatus( characterName, nil, nil )
	-- Set the power bar.
	local powerName = AJM.globalFramePrefix.."PowerBar"
	local powerBar = CreateFrame( "StatusBar", powerName, parentFrame, "TextStatusBar,SecureActionButtonTemplate" )
	powerBar.backgroundTexture = powerBar:CreateTexture( powerName.."BackgroundTexture", "ARTWORK" )
	powerBar.backgroundTexture:SetTexture( 0.58, 0.0, 0.55, 0.15 )
	powerBar:SetStatusBarTexture( statusBarTexture )
	powerBar:GetStatusBarTexture():SetHorizTile( false )
	powerBar:GetStatusBarTexture():SetVertTile( false )
	powerBar:SetMinMaxValues( 0, 100 )
	powerBar:SetValue( 100 )
	powerBar:SetFrameStrata( "LOW" )
	powerBar:SetAlpha( 1 )
	local powerBarClick = CreateFrame( "CheckButton", powerName.."Click"..characterName, parentFrame, "SecureActionButtonTemplate" )
	powerBarClick:SetAttribute( "unit", Ambiguate( characterName, "all" ) )
	powerBarClick:SetFrameStrata( "MEDIUM" )
	characterStatusBar["powerBar"] = powerBar
	characterStatusBar["powerBarClick"] = powerBarClick
	local powerBarText = powerBar:CreateFontString( powerName.."Text", "OVERLAY", "GameFontNormal" )
	powerBarText:SetTextColor( 1.00, 1.00, 1.00, 1.00 )
	powerBarText:SetAllPoints()
	powerBarText.playerPower = 100
	powerBarText.playerMaxPower = 100
	characterStatusBar["powerBarText"] = powerBarText
	AJM:UpdatePowerStatus( characterName, nil, nil, nil )
	-- Set the Combo Points bar.
	local comboName = AJM.globalFramePrefix.."ComboBar"
	local comboBar = CreateFrame( "StatusBar", comboName, parentFrame, "TextStatusBar,SecureActionButtonTemplate" )
	comboBar.backgroundTexture = comboBar:CreateTexture( comboName.."BackgroundTexture", "ARTWORK" )
	comboBar.backgroundTexture:SetTexture( 0.58, 0.0, 0.55, 0.15 )
	comboBar:SetStatusBarTexture( statusBarTexture )
	comboBar:GetStatusBarTexture():SetHorizTile( false )
	comboBar:GetStatusBarTexture():SetVertTile( false )
	comboBar:SetStatusBarColor( 1.00, 0.0, 0.0, 1.00 )
	comboBar:SetMinMaxValues( 0, 5 )
	comboBar:SetValue( 5 )
	comboBar:SetFrameStrata( "LOW" )
	comboBar:SetAlpha( 1 )
	local comboBarClick = CreateFrame( "CheckButton", comboName.."Click"..characterName, parentFrame, "SecureActionButtonTemplate" )
	comboBarClick:SetAttribute( "unit", characterName )
	comboBarClick:SetFrameStrata( "MEDIUM" )
	characterStatusBar["comboBar"] = comboBar
	characterStatusBar["comboBarClick"] = comboBarClick
	local comboBarText = comboBar:CreateFontString( comboName.."Text", "OVERLAY", "GameFontNormal" )
	comboBarText:SetTextColor( 1.00, 1.00, 0.0, 1.00 )
	comboBarText:SetAllPoints()
	comboBarText.playerCombo = 0
	comboBarText.playerMaxCombo = 5
	characterStatusBar["comboBarText"] = comboBarText
	AJM:UpdateComboStatus( characterName, nil, nil )
	-- Add the health and power click bars to ClickCastFrames for addons like Clique to use.
	--Ebony if Support for Clique if not on then default to target unit
	--TODO there got to be a better way to doing this for sure but right now i can not be assed to do this for now you need to reload the UI when turning off and on clique support. 
	ClickCastFrames = ClickCastFrames or {}
	if AJM.db.enableClique == true then
		ClickCastFrames[portraitButtonClick] = true
		ClickCastFrames[followBarClick] = true
		ClickCastFrames[experienceBarClick] = true
		ClickCastFrames[reputationBarClick] = true
		ClickCastFrames[healthBarClick] = true
		ClickCastFrames[powerBarClick] = true
		ClickCastFrames[comboBarClick] = true
	else
		portraitButtonClick:SetAttribute( "type1", "target")
		followBarClick:SetAttribute( "type1", "target")
		experienceBarClick:SetAttribute( "type1", "target")
		reputationBarClick:SetAttribute( "type1", "target")
		healthBarClick:SetAttribute( "type1", "target")
		powerBarClick:SetAttribute( "type1", "target")
		comboBarClick:SetAttribute( "type1", "target")
	end
end



function AJM:HideJambaTeamStatusBar( characterName )	
	local parentFrame = JambaDisplayTeamListFrame
	-- Get (or create and get) the character status bar information.
	local characterStatusBar = AJM.characterStatusBar[characterName]
	if characterStatusBar == nil then
		AJM:CreateJambaTeamStatusBar( characterName, parentFrame )
		characterStatusBar = AJM.characterStatusBar[characterName]
	end
	-- Hide the bars.
	characterStatusBar["portraitButton"]:Hide()
	characterStatusBar["portraitButtonClick"]:Hide()
--	characterStatusBar["bagInformationFrame"]:Hide()
	characterStatusBar["ilvlInformationFrame"]:Hide()
	characterStatusBar["followBar"]:Hide()
	characterStatusBar["followBarClick"]:Hide()
	characterStatusBar["experienceBar"]:Hide()
	characterStatusBar["experienceBarClick"]:Hide()
	characterStatusBar["reputationBar"]:Hide()
	characterStatusBar["reputationBarClick"]:Hide()	
	characterStatusBar["healthBar"]:Hide()
	characterStatusBar["healthBarClick"]:Hide()
	characterStatusBar["powerBar"]:Hide()
	characterStatusBar["powerBarClick"]:Hide()
	characterStatusBar["comboBar"]:Hide()
	characterStatusBar["comboBarClick"]:Hide()
end


function AJM:UpdateJambaTeamStatusBar( characterName, characterPosition )	
	local parentFrame = JambaDisplayTeamListFrame
	-- Get (or create and get) the character status bar information.
	local characterStatusBar = AJM.characterStatusBar[characterName]
	if characterStatusBar == nil then
		AJM:CreateJambaTeamStatusBar( characterName, parentFrame )
		characterStatusBar = AJM.characterStatusBar[characterName]
	end
	-- Set the positions.
	local characterHeight = GetCharacterHeight()
	local characterWidth = GetCharacterWidth()
	local positionLeft = 0
	local positionTop = -AJM.db.teamListTitleHeight - (AJM.db.teamListVerticalSpacing * 2)
	if AJM.db.teamListHorizontal == true then
		positionLeft = -6 + (characterPosition * characterWidth) + (AJM.db.teamListHorizontalSpacing * 3)
	else
		positionLeft = 6
		positionTop = positionTop - (characterPosition * characterHeight)
	end
	-- Display the portrait.
	local portraitButton = characterStatusBar["portraitButton"]
	local portraitButtonClick = characterStatusBar["portraitButtonClick"]
	if AJM.db.showCharacterPortrait == true then
		portraitButton:ClearModel()
		portraitButton:SetUnit( characterName )
		portraitButton:SetPortraitZoom( 1 )
        portraitButton:SetCamDistanceScale( 1 )
        portraitButton:SetPosition( 0, 0, 0 )
        portraitButton:SetWidth( AJM.db.characterPortraitWidth )
		portraitButton:SetHeight( AJM.db.characterPortraitWidth )
		portraitButton:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", positionLeft, positionTop )
		portraitButtonClick:SetWidth( AJM.db.characterPortraitWidth )
		portraitButtonClick:SetHeight( AJM.db.characterPortraitWidth )
		portraitButtonClick:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", positionLeft, positionTop )
		--SetPortraitTexture( portraitButton.Texture, characterName )
		--portraitButton.Texture:SetAllPoints()	
		portraitButton:Show()
		portraitButtonClick:Show()
		positionLeft = positionLeft + AJM.db.characterPortraitWidth + AJM.db.teamListHorizontalSpacing
	else
		portraitButton:Hide()
		portraitButtonClick:Hide()
	end
	-- Display the follow bar.
	local followBar	= characterStatusBar["followBar"]
	local followBarClick = characterStatusBar["followBarClick"]
	if AJM.db.showFollowStatus == true then
		followBar.backgroundTexture:SetAllPoints()
		followBar:SetWidth( AJM.db.followStatusWidth )
		followBar:SetHeight( AJM.db.followStatusHeight )
		followBar:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", positionLeft, positionTop )
		followBarClick:SetWidth( AJM.db.followStatusWidth )
		followBarClick:SetHeight( AJM.db.followStatusHeight )
		followBarClick:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", positionLeft, positionTop )
		followBar:Show()
		followBarClick:Show()
		if AJM.db.barsAreStackedVertically == true then
			positionTop = positionTop - AJM.db.followStatusHeight - AJM.db.barVerticalSpacing
		else
			positionLeft = positionLeft + AJM.db.followStatusWidth + AJM.db.teamListHorizontalSpacing
		end
	else
		followBar:Hide()
		followBarClick:Hide()
	end
	-- Display the experience bar.
	local experienceBar	= characterStatusBar["experienceBar"]
	local experienceBarClick	= characterStatusBar["experienceBarClick"]
	if AJM.db.showExperienceStatus == true then
		experienceBar.backgroundTexture:SetAllPoints()
		experienceBar:SetWidth( AJM.db.experienceStatusWidth )
		experienceBar:SetHeight( AJM.db.experienceStatusHeight )
		experienceBar:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", positionLeft, positionTop )
		experienceBarClick:SetWidth( AJM.db.experienceStatusWidth )
		experienceBarClick:SetHeight( AJM.db.experienceStatusHeight )
		experienceBarClick:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", positionLeft, positionTop )		
		experienceBar:Show()
		experienceBarClick:Show()
		if AJM.db.barsAreStackedVertically == true then
			positionTop = positionTop - AJM.db.experienceStatusHeight - AJM.db.barVerticalSpacing
		else
			positionLeft = positionLeft + AJM.db.experienceStatusWidth + AJM.db.teamListHorizontalSpacing
		end
	else
		experienceBar:Hide()
		experienceBarClick:Hide()
	end
	-- Display the reputation bar.
	local reputationBar	= characterStatusBar["reputationBar"]
	local reputationBarClick = characterStatusBar["reputationBarClick"]
	if AJM.db.showReputationStatus == true then
		reputationBar.backgroundTexture:SetAllPoints()
		reputationBar:SetWidth( AJM.db.reputationStatusWidth )
		reputationBar:SetHeight( AJM.db.reputationStatusHeight )
		reputationBar:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", positionLeft, positionTop )
		reputationBarClick:SetWidth( AJM.db.reputationStatusWidth )
		reputationBarClick:SetHeight( AJM.db.reputationStatusHeight )
		reputationBarClick:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", positionLeft, positionTop )		
		reputationBar:Show()
		reputationBarClick:Show()
		if AJM.db.barsAreStackedVertically == true then
			positionTop = positionTop - AJM.db.reputationStatusHeight - AJM.db.barVerticalSpacing
		else
			positionLeft = positionLeft + AJM.db.reputationStatusWidth + AJM.db.teamListHorizontalSpacing
		end
	else
		reputationBar:Hide()
		reputationBarClick:Hide()
	end		
	-- Display the health bar.
	local healthBar	= characterStatusBar["healthBar"]
	local healthBarClick = characterStatusBar["healthBarClick"]
	if AJM.db.showHealthStatus == true then
		healthBar.backgroundTexture:SetAllPoints()
		healthBar:SetWidth( AJM.db.healthStatusWidth )
		healthBar:SetHeight( AJM.db.healthStatusHeight )
		healthBar:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", positionLeft, positionTop )
		healthBarClick:SetWidth( AJM.db.healthStatusWidth )
		healthBarClick:SetHeight( AJM.db.healthStatusHeight )
		healthBarClick:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", positionLeft, positionTop )
		healthBar:Show()
		healthBarClick:Show()
		if AJM.db.barsAreStackedVertically == true then
			positionTop = positionTop - AJM.db.healthStatusHeight - AJM.db.barVerticalSpacing
		else
			positionLeft = positionLeft + AJM.db.healthStatusWidth + AJM.db.teamListHorizontalSpacing
		end
	else
		healthBar:Hide()
		healthBarClick:Hide()
	end		
	-- Display the power bar.
	local powerBar = characterStatusBar["powerBar"]
	local powerBarClick = characterStatusBar["powerBarClick"]
	if AJM.db.showPowerStatus == true then
		powerBar.backgroundTexture:SetAllPoints()
		powerBar:SetWidth( AJM.db.powerStatusWidth )
		powerBar:SetHeight( AJM.db.powerStatusHeight )
		powerBar:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", positionLeft, positionTop )
		powerBarClick:SetWidth( AJM.db.powerStatusWidth )
		powerBarClick:SetHeight( AJM.db.powerStatusHeight )
		powerBarClick:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", positionLeft, positionTop )
		powerBar:Show()
		powerBarClick:Show()
		if AJM.db.barsAreStackedVertically == true then
			positionTop = positionTop - AJM.db.powerStatusHeight - AJM.db.barVerticalSpacing
		else
			positionLeft = positionLeft + AJM.db.powerStatusWidth + AJM.db.teamListHorizontalSpacing
		end
	else
		powerBar:Hide()
		powerBarClick:Hide()
	end
	-- Display the Combo Point bar.
	local comboBar = characterStatusBar["comboBar"]
	local comboBarClick = characterStatusBar["comboBarClick"]
	if AJM.db.showComboStatus == true then
		comboBar.backgroundTexture:SetAllPoints()
		comboBar:SetWidth( AJM.db.comboStatusWidth )
		comboBar:SetHeight( AJM.db.comboStatusHeight )
		comboBar:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", positionLeft, positionTop )
		comboBarClick:SetWidth( AJM.db.comboStatusWidth )
		comboBarClick:SetHeight( AJM.db.comboStatusHeight )
		comboBarClick:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", positionLeft, positionTop )
		comboBar:Show()
		comboBarClick:Show()
		if AJM.db.barsAreStackedVertically == true then
			positionTop = positionTop - AJM.db.comboStatusHeight - AJM.db.barVerticalSpacing
		else
			positionLeft = positionLeft + AJM.db.comboStatusWidth + AJM.db.teamListHorizontalSpacing
		end
	else
		comboBar:Hide()
		comboBarClick:Hide()
	end		
--[[
	-- Display the bag information
	local bagInformationFrame = characterStatusBar["bagInformationFrame"]
	local bagInformationFrameText = characterStatusBar["bagInformationFrameText"]
	if AJM.db.showBagInformation == true then		
		bagInformationFrame:SetWidth( AJM.db.bagInformationWidth )
		bagInformationFrame:SetHeight( AJM.db.bagInformationHeight )
		bagInformationFrame:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", positionLeft, positionTop )
		bagInformationFrame:Show()
		if AJM.db.barsAreStackedVertically == true then
			positionTop = positionTop - AJM.db.bagInformationHeight - AJM.db.barVerticalSpacing
		else
			positionLeft = positionLeft + AJM.db.bagInformationWidth + AJM.db.teamListHorizontalSpacing
		end
	else
		bagInformationFrame:Hide()
	end
--]]	
	--[[
	-- Display the ilevel information
	local ilvlInformationFrame = characterStatusBar["ilvlInformationFrame"]
	local ilvlInformationFrameText = characterStatusBar["ilvlInformationFrameText"]
	if AJM.db.showIlvlInformation == true then		
		ilvlInformationFrame:SetWidth( AJM.db.ilvlInformationWidth )
		ilvlInformationFrame:SetHeight( AJM.db.ilvlInformationHeight )
		ilvlInformationFrame:SetPoint( "TOPLEFT", parentFrame, "TOPLEFT", positionLeft, positionTop )
		ilvlInformationFrame:Show()
		if AJM.db.barsAreStackedVertically == true then
			positionTop = positionTop - AJM.db.ilvlInformationHeight - AJM.db.barVerticalSpacing
		else
			positionLeft = positionLeft + AJM.db.ilvlInformationWidth + AJM.db.teamListHorizontalSpacing
		end
	else
		ilvlInformationFrame:Hide()
	end	
	--]]
end

-------------------------------------------------------------------------------------------------------------
-- Settings Dialogs.
-------------------------------------------------------------------------------------------------------------

local function SettingsCreateDisplayOptions( top )
	-- Get positions.
	local checkBoxHeight = JambaHelperSettings:GetCheckBoxHeight()
	local labelContinueHeight = JambaHelperSettings:GetContinueLabelHeight()
	local sliderHeight = JambaHelperSettings:GetSliderHeight()
	local mediaHeight = JambaHelperSettings:GetMediaHeight()
	local left = JambaHelperSettings:LeftOfSettings()
	local headingHeight = JambaHelperSettings:HeadingHeight()
	local headingWidth = JambaHelperSettings:HeadingWidth( true )
	local horizontalSpacing = JambaHelperSettings:GetHorizontalSpacing()
	local verticalSpacing = JambaHelperSettings:GetVerticalSpacing()
	local sectionSpacing = verticalSpacing * 4
	local halfWidthSlider = (headingWidth - horizontalSpacing) / 2
	local thirdWidth = (headingWidth - (horizontalSpacing * 2)) / 3
	local column2left = left + halfWidthSlider
	local left2 = left + thirdWidth
	local left3 = left + (thirdWidth * 2)
	local movingTop = top
	-- Create show.
	JambaHelperSettings:CreateHeading( AJM.settingsControl, L["Show"], movingTop, true )
	movingTop = movingTop - headingHeight
	AJM.settingsControl.displayOptionsCheckBoxShowTeamList = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		left, 
		movingTop, 
		L["Show Team List"],
		AJM.SettingsToggleShowTeamList
	)
	movingTop = movingTop - checkBoxHeight - verticalSpacing
	AJM.settingsControl.displayOptionsCheckBoxShowTeamListOnlyOnMaster = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		left, 
		movingTop, 
		L["Only On Master"],
		AJM.SettingsToggleShowTeamListOnMasterOnly
	)	
	movingTop = movingTop - checkBoxHeight - verticalSpacing
	AJM.settingsControl.displayOptionsCheckBoxHideTeamListInCombat = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		left, 
		movingTop, 
		L["Hide Team List In Combat"],
		AJM.SettingsToggleHideTeamListInCombat
	)
	movingTop = movingTop - checkBoxHeight - verticalSpacing
	AJM.settingsControl.displayOptionsCheckBoxEnableClique = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		left, 
		movingTop, 
		L["Enable Clique Support - **reload UI to take effect**"],
		AJM.SettingsToggleEnableClique
	)	
	movingTop = movingTop - checkBoxHeight - verticalSpacing
	-- Create appearance & layout.
	JambaHelperSettings:CreateHeading( AJM.settingsControl, L["Appearance & Layout"], movingTop, true )
	movingTop = movingTop - headingHeight
	AJM.settingsControl.displayOptionsCheckBoxStackVertically = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		left, 
		movingTop, 
		L["Stack Bars Vertically"],
		AJM.SettingsToggleStackVertically
	)
	movingTop = movingTop - checkBoxHeight - verticalSpacing
	AJM.settingsControl.displayOptionsCheckBoxTeamHorizontal = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		left, 
		movingTop, 
		L["Display Team List Horizontally"],
		AJM.SettingsToggleTeamHorizontal
	)
	movingTop = movingTop - checkBoxHeight - verticalSpacing
	AJM.settingsControl.displayOptionsCheckBoxShowListTitle = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		left, 
		movingTop, 
		L["Show Team List Title"],
		AJM.SettingsToggleShowTeamListTitle
	)
	movingTop = movingTop - checkBoxHeight - verticalSpacing
	AJM.settingsControl.displayOptionsTeamListScaleSlider = JambaHelperSettings:CreateSlider( 
		AJM.settingsControl, 
		headingWidth, 
		left, 
		movingTop, 
		L["Scale"]
	)
	AJM.settingsControl.displayOptionsTeamListScaleSlider:SetSliderValues( 0.5, 2, 0.01 )
	AJM.settingsControl.displayOptionsTeamListScaleSlider:SetCallback( "OnValueChanged", AJM.SettingsChangeScale )
	movingTop = movingTop - sliderHeight - verticalSpacing
	AJM.settingsControl.displayOptionsTeamListTransparencySlider = JambaHelperSettings:CreateSlider( 
		AJM.settingsControl, 
		headingWidth, 
		left, 
		movingTop, 
		L["Transparency"]
	)
	AJM.settingsControl.displayOptionsTeamListTransparencySlider:SetSliderValues( 0, 1, 0.01 )
	AJM.settingsControl.displayOptionsTeamListTransparencySlider:SetCallback( "OnValueChanged", AJM.SettingsChangeTransparency )
	movingTop = movingTop - sliderHeight - verticalSpacing	
	AJM.settingsControl.displayOptionsTeamListMediaStatus = JambaHelperSettings:CreateMediaStatus( 
		AJM.settingsControl, 
		halfWidthSlider, 
		left, 
		movingTop,
		L["Status Bar Texture"]
	)
	AJM.settingsControl.displayOptionsTeamListMediaStatus:SetCallback( "OnValueChanged", AJM.SettingsChangeStatusBarTexture )
	movingTop = movingTop - mediaHeight - verticalSpacing
	AJM.settingsControl.displayOptionsTeamListMediaBorder = JambaHelperSettings:CreateMediaBorder( 
		AJM.settingsControl, 
		halfWidthSlider, 
		left, 
		movingTop,
		L["Border Style"]
	)
	AJM.settingsControl.displayOptionsTeamListMediaBorder:SetCallback( "OnValueChanged", AJM.SettingsChangeBorderStyle )
	AJM.settingsControl.displayOptionsBorderColourPicker = JambaHelperSettings:CreateColourPicker(
		AJM.settingsControl,
		halfWidthSlider,
		column2left + 15,
		movingTop - 15,
		L["Border Colour"]
	)
	AJM.settingsControl.displayOptionsBorderColourPicker:SetHasAlpha( true )
	AJM.settingsControl.displayOptionsBorderColourPicker:SetCallback( "OnValueConfirmed", AJM.SettingsBorderColourPickerChanged )	
	movingTop = movingTop - mediaHeight - verticalSpacing
	AJM.settingsControl.displayOptionsTeamListMediaBackground = JambaHelperSettings:CreateMediaBackground( 
		AJM.settingsControl, 
		halfWidthSlider, 
		left, 
		movingTop,
		L["Background"]
	)
	AJM.settingsControl.displayOptionsTeamListMediaBackground:SetCallback( "OnValueChanged", AJM.SettingsChangeBackgroundStyle )
	AJM.settingsControl.displayOptionsBackgroundColourPicker = JambaHelperSettings:CreateColourPicker(
		AJM.settingsControl,
		halfWidthSlider,
		column2left + 15,
		movingTop - 15,
		L["Background Colour"]
	)
	AJM.settingsControl.displayOptionsBackgroundColourPicker:SetHasAlpha( true )
	AJM.settingsControl.displayOptionsBackgroundColourPicker:SetCallback( "OnValueConfirmed", AJM.SettingsBackgroundColourPickerChanged )
	movingTop = movingTop - mediaHeight - sectionSpacing	
	-- Create portrait.
	JambaHelperSettings:CreateHeading( AJM.settingsControl, L["Portrait"], movingTop, true )
	movingTop = movingTop - headingHeight
	AJM.settingsControl.displayOptionsCheckBoxShowPortrait = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		headingWidth, 
		left, 
		movingTop, 
		L["Show"],
		AJM.SettingsToggleShowPortrait
	)	
	movingTop = movingTop - checkBoxHeight - verticalSpacing
	AJM.settingsControl.displayOptionsPortraitWidthSlider = JambaHelperSettings:CreateSlider( 
		AJM.settingsControl, 
		halfWidthSlider, 
		left, 
		movingTop, 
		L["Width"]
	)
	AJM.settingsControl.displayOptionsPortraitWidthSlider:SetSliderValues( 5, 200, 1 )
	AJM.settingsControl.displayOptionsPortraitWidthSlider:SetCallback( "OnValueChanged", AJM.SettingsChangePortraitWidth )
	movingTop = movingTop - sliderHeight - sectionSpacing
	-- Create follow status.
	JambaHelperSettings:CreateHeading( AJM.settingsControl, L["Follow Status Bar"], movingTop, true )
	movingTop = movingTop - headingHeight
	AJM.settingsControl.displayOptionsCheckBoxShowFollowStatus = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		thirdWidth, 
		left, 
		movingTop, 
		L["Show"],
		AJM.SettingsToggleShowFollowStatus
	)	
	AJM.settingsControl.displayOptionsCheckBoxShowFollowStatusName = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		thirdWidth, 
		left2, 
		movingTop, 
		L["Name"],
		AJM.SettingsToggleShowFollowStatusName
	)
--[[	AJM.settingsControl.displayOptionsCheckBoxstackName = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		thirdWidth, 
		left3, 
		movingTop, 
		L["Stack Text"],
		AJM.SettingsTogglestackName
	)	
	movingTop = movingTop - checkBoxHeight - verticalSpacing
	AJM.settingsControl.displayOptionsCheckBoxShowFollowStatusLevel = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		thirdWidth, 
		left, 
		movingTop, 
		L["Level"],
		AJM.SettingsToggleShowFollowStatusLevel
	)
	AJM.settingsControl.displayOptionsCheckBoxShowIlvlInformation = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		thirdWidth, 
		left2, 
		movingTop, 
		L["Show Item Level"],
		AJM.SettingsToggleShowIlvlInformation
	)
	AJM.settingsControl.displayOptionsCheckBoxShowEquippedOnly = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		thirdWidth + thirdWidth, 
		left3, 
		movingTop, 
		L["Equipped iLvl Only"],
		AJM.SettingsToggleShowEquippedOnly
	)]]
	movingTop = movingTop - checkBoxHeight - verticalSpacing
	AJM.settingsControl.displayOptionsFollowStatusWidthSlider = JambaHelperSettings:CreateSlider( 
		AJM.settingsControl, 
		halfWidthSlider, 
		left, 
		movingTop, 
		L["Width"]
	)
	AJM.settingsControl.displayOptionsFollowStatusWidthSlider:SetSliderValues( 5, 200, 1 )
	AJM.settingsControl.displayOptionsFollowStatusWidthSlider:SetCallback( "OnValueChanged", AJM.SettingsChangeFollowStatusWidth )
	AJM.settingsControl.displayOptionsFollowStatusHeightSlider = JambaHelperSettings:CreateSlider( 
		AJM.settingsControl, 
		halfWidthSlider, 
		column2left, 
		movingTop, 
		L["Height"]
	)
	AJM.settingsControl.displayOptionsFollowStatusHeightSlider:SetSliderValues( 5, 50, 1 )
	AJM.settingsControl.displayOptionsFollowStatusHeightSlider:SetCallback( "OnValueChanged", AJM.SettingsChangeFollowStatusHeight )
	movingTop = movingTop - sliderHeight - sectionSpacing
	-- Create experience status.
	JambaHelperSettings:CreateHeading( AJM.settingsControl, L["Experience Bar"], movingTop, true )
	movingTop = movingTop - headingHeight
	AJM.settingsControl.displayOptionsCheckBoxShowExperienceStatus = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		thirdWidth, 
		left, 
		movingTop, 
		L["Show"],
		AJM.SettingsToggleShowExperienceStatus
	)	
	AJM.settingsControl.displayOptionsCheckBoxShowExperienceStatusValues = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		thirdWidth, 
		left2, 
		movingTop, 
		L["Values"],
		AJM.SettingsToggleShowExperienceStatusValues
	)	
	AJM.settingsControl.displayOptionsCheckBoxShowExperienceStatusPercentage = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		thirdWidth, 
		left3, 
		movingTop, 
		L["Percentage"],
		AJM.SettingsToggleShowExperienceStatusPercentage
	)		
	movingTop = movingTop - checkBoxHeight - verticalSpacing
	AJM.settingsControl.displayOptionsExperienceStatusWidthSlider = JambaHelperSettings:CreateSlider( 
		AJM.settingsControl, 
		halfWidthSlider, 
		left, 
		movingTop, 
		L["Width"]
	)
	AJM.settingsControl.displayOptionsExperienceStatusWidthSlider:SetSliderValues( 5, 200, 1 )
	AJM.settingsControl.displayOptionsExperienceStatusWidthSlider:SetCallback( "OnValueChanged", AJM.SettingsChangeExperienceStatusWidth )
	AJM.settingsControl.displayOptionsExperienceStatusHeightSlider = JambaHelperSettings:CreateSlider( 
		AJM.settingsControl, 
		halfWidthSlider, 
		column2left, 
		movingTop, 
		L["Height"]
	)
	AJM.settingsControl.displayOptionsExperienceStatusHeightSlider:SetSliderValues( 5, 50, 1 )
	AJM.settingsControl.displayOptionsExperienceStatusHeightSlider:SetCallback( "OnValueChanged", AJM.SettingsChangeExperienceStatusHeight )
	movingTop = movingTop - sliderHeight - sectionSpacing
	-- Create reputation status.
	JambaHelperSettings:CreateHeading( AJM.settingsControl, L["Reputation Bar"], movingTop, true )
	movingTop = movingTop - headingHeight
	AJM.settingsControl.displayOptionsCheckBoxShowReputationStatus = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		thirdWidth, 
		left, 
		movingTop, 
		L["Show"],
		AJM.SettingsToggleShowReputationStatus
	)	
	AJM.settingsControl.displayOptionsCheckBoxShowReputationStatusValues = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		thirdWidth, 
		left2, 
		movingTop, 
		L["Values"],
		AJM.SettingsToggleShowReputationStatusValues
	)	
	AJM.settingsControl.displayOptionsCheckBoxShowReputationStatusPercentage = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		thirdWidth, 
		left3, 
		movingTop, 
		L["Percentage"],
		AJM.SettingsToggleShowReputationStatusPercentage
	)		
	movingTop = movingTop - checkBoxHeight - verticalSpacing
	AJM.settingsControl.displayOptionsCheckBoxShowReputationName = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		thirdWidth + thirdWidth, 
		left, 
		movingTop, 
		L["Show Faction Name"],
		AJM.SettingsToggleShowReputationName
	)
	movingTop = movingTop - checkBoxHeight - verticalSpacing
	AJM.settingsControl.displayOptionsReputationStatusWidthSlider = JambaHelperSettings:CreateSlider( 
		AJM.settingsControl, 
		halfWidthSlider, 
		left, 
		movingTop, 
		L["Width"]
	)
	AJM.settingsControl.displayOptionsReputationStatusWidthSlider:SetSliderValues( 5, 400, 1 )
	AJM.settingsControl.displayOptionsReputationStatusWidthSlider:SetCallback( "OnValueChanged", AJM.SettingsChangeReputationStatusWidth )
	AJM.settingsControl.displayOptionsReputationStatusHeightSlider = JambaHelperSettings:CreateSlider( 
		AJM.settingsControl, 
		halfWidthSlider, 
		column2left, 
		movingTop, 
		L["Height"]
	)
	AJM.settingsControl.displayOptionsReputationStatusHeightSlider:SetSliderValues( 5, 50, 1 )
	AJM.settingsControl.displayOptionsReputationStatusHeightSlider:SetCallback( "OnValueChanged", AJM.SettingsChangeReputationStatusHeight )
	movingTop = movingTop - sliderHeight - sectionSpacing	
	-- Create health status.
	JambaHelperSettings:CreateHeading( AJM.settingsControl, L["Health Bar"], movingTop, true )
	movingTop = movingTop - headingHeight
	AJM.settingsControl.displayOptionsCheckBoxShowHealthStatus = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		thirdWidth, 
		left, 
		movingTop, 
		L["Show"],
		AJM.SettingsToggleShowHealthStatus
	)	
	AJM.settingsControl.displayOptionsCheckBoxShowHealthStatusValues = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		thirdWidth, 
		left2, 
		movingTop, 
		L["Values"],
		AJM.SettingsToggleShowHealthStatusValues
	)	
	AJM.settingsControl.displayOptionsCheckBoxShowHealthStatusPercentage = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		thirdWidth, 
		left3, 
		movingTop, 
		L["Percentage"],
		AJM.SettingsToggleShowHealthStatusPercentage
	)		
	movingTop = movingTop - checkBoxHeight - verticalSpacing
	AJM.settingsControl.displayOptionsHealthStatusWidthSlider = JambaHelperSettings:CreateSlider( 
		AJM.settingsControl, 
		halfWidthSlider, 
		left, 
		movingTop, 
		L["Width"]
	)
	AJM.settingsControl.displayOptionsHealthStatusWidthSlider:SetSliderValues( 5, 200, 1 )
	AJM.settingsControl.displayOptionsHealthStatusWidthSlider:SetCallback( "OnValueChanged", AJM.SettingsChangeHealthStatusWidth )
	AJM.settingsControl.displayOptionsHealthStatusHeightSlider = JambaHelperSettings:CreateSlider( 
		AJM.settingsControl, 
		halfWidthSlider, 
		column2left, 
		movingTop, 
		L["Height"]
	)
	AJM.settingsControl.displayOptionsHealthStatusHeightSlider:SetSliderValues( 5, 50, 1 )
	AJM.settingsControl.displayOptionsHealthStatusHeightSlider:SetCallback( "OnValueChanged", AJM.SettingsChangeHealthStatusHeight )
	movingTop = movingTop - sliderHeight - sectionSpacing	
	-- Create power status.
	JambaHelperSettings:CreateHeading( AJM.settingsControl, L["Power Bar"], movingTop, true )
	movingTop = movingTop - headingHeight
	AJM.settingsControl.displayOptionsCheckBoxShowPowerStatus = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		thirdWidth, 
		left, 
		movingTop, 
		L["Show"],
		AJM.SettingsToggleShowPowerStatus
	)	
	AJM.settingsControl.displayOptionsCheckBoxShowPowerStatusValues = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		thirdWidth, 
		left2, 
		movingTop, 
		L["Values"],
		AJM.SettingsToggleShowPowerStatusValues
	)	
	AJM.settingsControl.displayOptionsCheckBoxShowPowerStatusPercentage = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		thirdWidth, 
		left3, 
		movingTop, 
		L["Percentage"],
		AJM.SettingsToggleShowPowerStatusPercentage
	)			
	movingTop = movingTop - checkBoxHeight - verticalSpacing
	AJM.settingsControl.displayOptionsPowerStatusWidthSlider = JambaHelperSettings:CreateSlider( 
		AJM.settingsControl, 
		halfWidthSlider, 
		left, 
		movingTop, 
		L["Width"]
	)
	AJM.settingsControl.displayOptionsPowerStatusWidthSlider:SetSliderValues( 5, 200, 1 )
	AJM.settingsControl.displayOptionsPowerStatusWidthSlider:SetCallback( "OnValueChanged", AJM.SettingsChangePowerStatusWidth )
	AJM.settingsControl.displayOptionsPowerStatusHeightSlider = JambaHelperSettings:CreateSlider( 
		AJM.settingsControl, 
		halfWidthSlider, 
		column2left, 
		movingTop, 
		L["Height"]
	)
	AJM.settingsControl.displayOptionsPowerStatusHeightSlider:SetSliderValues( 5, 50, 1 )
	AJM.settingsControl.displayOptionsPowerStatusHeightSlider:SetCallback( "OnValueChanged", AJM.SettingsChangePowerStatusHeight )
	movingTop = movingTop - sliderHeight - sectionSpacing
	-- Create Combo Point status.
	JambaHelperSettings:CreateHeading( AJM.settingsControl, L["Alternate PowerBar"], movingTop, true )
	movingTop = movingTop - headingHeight
	AJM.settingsControl.displayOptionsCheckBoxShowComboStatus = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		thirdWidth, 
		left, 
		movingTop, 
		L["Show"],
		AJM.SettingsToggleShowComboStatus
	)	
	AJM.settingsControl.displayOptionsCheckBoxShowComboStatusValues = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		thirdWidth, 
		left2, 
		movingTop, 
		L["Values"],
		AJM.SettingsToggleShowComboStatusValues
	)	
	AJM.settingsControl.displayOptionsCheckBoxShowComboStatusPercentage = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		thirdWidth, 
		left3, 
		movingTop, 
		L["Percentage"],
		AJM.SettingsToggleShowComboStatusPercentage
	)			
	movingTop = movingTop - checkBoxHeight - verticalSpacing
	AJM.settingsControl.displayOptionsComboStatusWidthSlider = JambaHelperSettings:CreateSlider( 
		AJM.settingsControl, 
		halfWidthSlider, 
		left, 
		movingTop, 
		L["Width"]
	)	
	AJM.settingsControl.displayOptionsComboStatusWidthSlider:SetSliderValues( 5, 200, 1 )
	AJM.settingsControl.displayOptionsComboStatusWidthSlider:SetCallback( "OnValueChanged", AJM.SettingsChangeComboStatusWidth )
	AJM.settingsControl.displayOptionsComboStatusHeightSlider = JambaHelperSettings:CreateSlider( 
		AJM.settingsControl, 
		halfWidthSlider, 
		column2left, 
		movingTop, 
		L["Height"]
	)
	AJM.settingsControl.displayOptionsComboStatusHeightSlider:SetSliderValues( 5, 50, 1 )
	AJM.settingsControl.displayOptionsComboStatusHeightSlider:SetCallback( "OnValueChanged", AJM.SettingsChangeComboStatusHeight )
	movingTop = movingTop - sliderHeight - sectionSpacing
--[[
	-- Create bag information status.
	JambaHelperSettings:CreateHeading( AJM.settingsControl, L["Bag Information"], movingTop, true )
	movingTop = movingTop - headingHeight
	AJM.settingsControl.displayOptionsCheckBoxShowBagInformation = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		thirdWidth, 
		left, 
		movingTop, 
		L["Show"],
		AJM.SettingsToggleShowBagInformation
	)	
	AJM.settingsControl.displayOptionsCheckBoxShowFreeBagSlotsOnly = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		thirdWidth + thirdWidth, 
		left2, 
		movingTop, 
		L["Only Show Free Bag Slots"],
		AJM.SettingsToggleShowFreeBagSlotsOnly
	)
	movingTop = movingTop - checkBoxHeight - verticalSpacing
	AJM.settingsControl.displayOptionsBagInformationWidthSlider = JambaHelperSettings:CreateSlider( 
		AJM.settingsControl, 
		halfWidthSlider, 
		left, 
		movingTop, 
		L["Width"]
	)
	AJM.settingsControl.displayOptionsBagInformationWidthSlider:SetSliderValues( 5, 200, 1 )
	AJM.settingsControl.displayOptionsBagInformationWidthSlider:SetCallback( "OnValueChanged", AJM.SettingsChangeBagInformationWidth )
	AJM.settingsControl.displayOptionsBagInformationHeightSlider = JambaHelperSettings:CreateSlider( 
		AJM.settingsControl, 
		halfWidthSlider, 
		column2left, 
		movingTop, 
		L["Height"]
	)
	AJM.settingsControl.displayOptionsBagInformationHeightSlider:SetSliderValues( 5, 50, 1 )
	AJM.settingsControl.displayOptionsBagInformationHeightSlider:SetCallback( "OnValueChanged", AJM.SettingsChangeBagInformationHeight )	
	movingTop = movingTop - sliderHeight - verticalSpacing
--]]
--[[
	-- Create Ilvl information status.
	JambaHelperSettings:CreateHeading( AJM.settingsControl, L["Players Item Level Information"], movingTop, true )
	movingTop = movingTop - headingHeight
	AJM.settingsControl.displayOptionsCheckBoxShowIlvlInformation = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		thirdWidth, 
		left, 
		movingTop, 
		L["Show"],
		AJM.SettingsToggleShowIlvlInformation
	)	
	AJM.settingsControl.displayOptionsCheckBoxShowEquippedOnly = JambaHelperSettings:CreateCheckBox( 
		AJM.settingsControl, 
		thirdWidth + thirdWidth, 
		left2, 
		movingTop, 
		L["Only Show Equipped Item Level Only"],
		AJM.SettingsToggleShowEquippedOnly
	)
	movingTop = movingTop - checkBoxHeight - verticalSpacing
	AJM.settingsControl.displayOptionsIlvlInformationWidthSlider = JambaHelperSettings:CreateSlider( 
		AJM.settingsControl, 
		halfWidthSlider, 
		left, 
		movingTop, 
		L["Width"]
	)
	AJM.settingsControl.displayOptionsIlvlInformationWidthSlider:SetSliderValues( 5, 200, 1 )
	AJM.settingsControl.displayOptionsIlvlInformationWidthSlider:SetCallback( "OnValueChanged", AJM.SettingsChangeIlvlInformationWidth )
	AJM.settingsControl.displayOptionsIlvlInformationHeightSlider = JambaHelperSettings:CreateSlider( 
		AJM.settingsControl, 
		halfWidthSlider, 
		column2left, 
		movingTop, 
		L["Height"]
	)
	AJM.settingsControl.displayOptionsIlvlInformationHeightSlider:SetSliderValues( 5, 50, 1 )
	AJM.settingsControl.displayOptionsIlvlInformationHeightSlider:SetCallback( "OnValueChanged", AJM.SettingsChangeIlvlInformationHeight )	
	movingTop = movingTop - sliderHeight - verticalSpacing	
	--]]
	return movingTop
end

local function SettingsCreate()
	AJM.settingsControl = {}
	-- Create the settings panel.
	JambaHelperSettings:CreateSettings( 
		AJM.settingsControl, 
		AJM.moduleDisplayName, 
		AJM.parentDisplayName, 
		AJM.SettingsPushSettingsClick 
	)
	local bottomOfDisplayOptions = SettingsCreateDisplayOptions( JambaHelperSettings:TopOfSettings() )
	AJM.settingsControl.widgetSettings.content:SetHeight( -bottomOfDisplayOptions )
	-- Help
	local helpTable = {}
	JambaHelperSettings:CreateHelp( AJM.settingsControl, helpTable, AJM:GetConfiguration() )		
end

-------------------------------------------------------------------------------------------------------------
-- Settings Populate.
-------------------------------------------------------------------------------------------------------------

function AJM:BeforeJambaProfileChanged()	
	AJM:RefreshTeamListControlsHide()
end

function AJM:OnJambaProfileChanged()	
	AJM:SettingsRefresh()
end

function AJM:SettingsRefresh()
	AJM.settingsControl.displayOptionsCheckBoxShowTeamList:SetValue( AJM.db.showTeamList )
	AJM.settingsControl.displayOptionsCheckBoxShowTeamListOnlyOnMaster:SetValue( AJM.db.showTeamListOnMasterOnly )
	AJM.settingsControl.displayOptionsCheckBoxHideTeamListInCombat:SetValue( AJM.db.hideTeamListInCombat )
	AJM.settingsControl.displayOptionsCheckBoxEnableClique:SetValue( AJM.db.enableClique )
	AJM.settingsControl.displayOptionsCheckBoxStackVertically:SetValue( AJM.db.barsAreStackedVertically )
	AJM.settingsControl.displayOptionsCheckBoxTeamHorizontal:SetValue( AJM.db.teamListHorizontal )
	AJM.settingsControl.displayOptionsCheckBoxShowListTitle:SetValue( AJM.db.showListTitle )
	AJM.settingsControl.displayOptionsTeamListTransparencySlider:SetValue( AJM.db.frameAlpha )
	AJM.settingsControl.displayOptionsTeamListScaleSlider:SetValue( AJM.db.teamListScale )
	AJM.settingsControl.displayOptionsTeamListMediaStatus:SetValue( AJM.db.statusBarTexture )
	AJM.settingsControl.displayOptionsTeamListMediaBorder:SetValue( AJM.db.borderStyle )
	AJM.settingsControl.displayOptionsTeamListMediaBackground:SetValue( AJM.db.backgroundStyle )
	AJM.settingsControl.displayOptionsCheckBoxShowPortrait:SetValue( AJM.db.showCharacterPortrait )
	AJM.settingsControl.displayOptionsPortraitWidthSlider:SetValue( AJM.db.characterPortraitWidth )
	AJM.settingsControl.displayOptionsCheckBoxShowFollowStatus:SetValue( AJM.db.showFollowStatus )
	AJM.settingsControl.displayOptionsCheckBoxShowFollowStatusName:SetValue( AJM.db.followStatusShowName )
--	AJM.settingsControl.displayOptionsCheckBoxShowFollowStatusLevel:SetValue( AJM.db.followStatusShowLevel )
	AJM.settingsControl.displayOptionsFollowStatusWidthSlider:SetValue( AJM.db.followStatusWidth )
	AJM.settingsControl.displayOptionsFollowStatusHeightSlider:SetValue( AJM.db.followStatusHeight )
	AJM.settingsControl.displayOptionsCheckBoxShowExperienceStatus:SetValue( AJM.db.showExperienceStatus )
	AJM.settingsControl.displayOptionsCheckBoxShowExperienceStatusValues:SetValue( AJM.db.experienceStatusShowValues )
	AJM.settingsControl.displayOptionsCheckBoxShowExperienceStatusPercentage:SetValue( AJM.db.experienceStatusShowPercentage )
	AJM.settingsControl.displayOptionsExperienceStatusWidthSlider:SetValue( AJM.db.experienceStatusWidth )
	AJM.settingsControl.displayOptionsExperienceStatusHeightSlider:SetValue( AJM.db.experienceStatusHeight )
	AJM.settingsControl.displayOptionsCheckBoxShowReputationStatus:SetValue( AJM.db.showReputationStatus )
	AJM.settingsControl.displayOptionsCheckBoxShowReputationName:SetValue( AJM.db.showReputationName )
	AJM.settingsControl.displayOptionsCheckBoxShowReputationStatusValues:SetValue( AJM.db.reputationStatusShowValues )
	AJM.settingsControl.displayOptionsCheckBoxShowReputationStatusPercentage:SetValue( AJM.db.reputationStatusShowPercentage )
	AJM.settingsControl.displayOptionsReputationStatusWidthSlider:SetValue( AJM.db.reputationStatusWidth )
	AJM.settingsControl.displayOptionsReputationStatusHeightSlider:SetValue( AJM.db.reputationStatusHeight )		
	AJM.settingsControl.displayOptionsCheckBoxShowHealthStatus:SetValue( AJM.db.showHealthStatus )
	AJM.settingsControl.displayOptionsCheckBoxShowHealthStatusValues:SetValue( AJM.db.healthStatusShowValues )
	AJM.settingsControl.displayOptionsCheckBoxShowHealthStatusPercentage:SetValue( AJM.db.healthStatusShowPercentage )	
	AJM.settingsControl.displayOptionsHealthStatusWidthSlider:SetValue( AJM.db.healthStatusWidth )
	AJM.settingsControl.displayOptionsHealthStatusHeightSlider:SetValue( AJM.db.healthStatusHeight )	
	AJM.settingsControl.displayOptionsCheckBoxShowPowerStatus:SetValue( AJM.db.showPowerStatus )
	AJM.settingsControl.displayOptionsCheckBoxShowPowerStatusValues:SetValue( AJM.db.powerStatusShowValues )
	AJM.settingsControl.displayOptionsCheckBoxShowPowerStatusPercentage:SetValue( AJM.db.powerStatusShowPercentage )
	AJM.settingsControl.displayOptionsPowerStatusWidthSlider:SetValue( AJM.db.powerStatusWidth )
	AJM.settingsControl.displayOptionsPowerStatusHeightSlider:SetValue( AJM.db.powerStatusHeight )
	AJM.settingsControl.displayOptionsCheckBoxShowComboStatus:SetValue( AJM.db.showComboStatus )
	AJM.settingsControl.displayOptionsCheckBoxShowComboStatusValues:SetValue( AJM.db.comboStatusShowValues )
	AJM.settingsControl.displayOptionsCheckBoxShowComboStatusPercentage:SetValue( AJM.db.comboStatusShowPercentage )
	AJM.settingsControl.displayOptionsComboStatusWidthSlider:SetValue( AJM.db.comboStatusWidth )
	AJM.settingsControl.displayOptionsComboStatusHeightSlider:SetValue( AJM.db.comboStatusHeight )	
	AJM.settingsControl.displayOptionsBackgroundColourPicker:SetColor( AJM.db.frameBackgroundColourR, AJM.db.frameBackgroundColourG, AJM.db.frameBackgroundColourB, AJM.db.frameBackgroundColourA )
	AJM.settingsControl.displayOptionsBorderColourPicker:SetColor( AJM.db.frameBorderColourR, AJM.db.frameBorderColourG, AJM.db.frameBorderColourB, AJM.db.frameBorderColourA )
--	AJM.settingsControl.displayOptionsCheckBoxShowBagInformation:SetValue( AJM.db.showBagInformation )
--	AJM.settingsControl.displayOptionsCheckBoxShowFreeBagSlotsOnly:SetValue( AJM.db.showBagFreeSlotsOnly )
--	AJM.settingsControl.displayOptionsBagInformationWidthSlider:SetValue( AJM.db.bagInformationWidth )
--	AJM.settingsControl.displayOptionsBagInformationHeightSlider:SetValue( AJM.db.bagInformationHeight )
	--Ebony
--	AJM.settingsControl.displayOptionsCheckBoxShowIlvlInformation:SetValue( AJM.db.showIlvlInformation )
--	AJM.settingsControl.displayOptionsCheckBoxShowEquippedOnly:SetValue( AJM.db.ShowEquippedOnly )
--	AJM.settingsControl.displayOptionsCheckBoxstackName:SetValue( AJM.db.stackName )
	--AJM.settingsControl.displayOptionsIlvlInformationWidthSlider:SetValue( AJM.db.ilvlInformationWidth )
	--AJM.settingsControl.displayOptionsIlvlInformationHeightSlider:SetValue( AJM.db.ilvlInformationHeight )	
	-- State.
	-- Trying to change state in combat lockdown causes taint. Let's not do that. Eventually it would be nice to have a "proper state driven team display",
	-- but this workaround is enough for now.
	if not InCombatLockdown() then
		AJM.settingsControl.displayOptionsCheckBoxShowTeamListOnlyOnMaster:SetDisabled( not AJM.db.showTeamList )
		AJM.settingsControl.displayOptionsCheckBoxHideTeamListInCombat:SetDisabled( not AJM.db.showTeamList )
		AJM.settingsControl.displayOptionsCheckBoxEnableClique:SetDisabled( not AJM.db.showTeamList )
		AJM.settingsControl.displayOptionsCheckBoxStackVertically:SetDisabled( not AJM.db.showTeamList )
		AJM.settingsControl.displayOptionsCheckBoxTeamHorizontal:SetDisabled( not AJM.db.showTeamList )
		AJM.settingsControl.displayOptionsCheckBoxShowListTitle:SetDisabled( not AJM.db.showTeamList )
		AJM.settingsControl.displayOptionsTeamListScaleSlider:SetDisabled( not AJM.db.showTeamList )
		AJM.settingsControl.displayOptionsTeamListTransparencySlider:SetDisabled( not AJM.db.showTeamList )
		AJM.settingsControl.displayOptionsTeamListMediaStatus:SetDisabled( not AJM.db.showTeamList )
		AJM.settingsControl.displayOptionsTeamListMediaBorder:SetDisabled( not AJM.db.showTeamList )
		AJM.settingsControl.displayOptionsTeamListMediaBackground:SetDisabled( not AJM.db.showTeamList )
		AJM.settingsControl.displayOptionsCheckBoxShowPortrait:SetDisabled( not AJM.db.showTeamList )
		AJM.settingsControl.displayOptionsPortraitWidthSlider:SetDisabled( not AJM.db.showTeamList )
		AJM.settingsControl.displayOptionsCheckBoxShowFollowStatus:SetDisabled( not AJM.db.showTeamList )
		AJM.settingsControl.displayOptionsCheckBoxShowFollowStatusName:SetDisabled( not AJM.db.showTeamList )
--		AJM.settingsControl.displayOptionsCheckBoxShowFollowStatusLevel:SetDisabled( not AJM.db.showTeamList )
		AJM.settingsControl.displayOptionsFollowStatusWidthSlider:SetDisabled( not AJM.db.showTeamList )
		AJM.settingsControl.displayOptionsFollowStatusHeightSlider:SetDisabled( not AJM.db.showTeamList )
		AJM.settingsControl.displayOptionsCheckBoxShowExperienceStatus:SetDisabled( not AJM.db.showTeamList )
		AJM.settingsControl.displayOptionsCheckBoxShowExperienceStatusValues:SetDisabled( not AJM.db.showTeamList )
		AJM.settingsControl.displayOptionsCheckBoxShowExperienceStatusPercentage:SetDisabled( not AJM.db.showTeamList )
		AJM.settingsControl.displayOptionsExperienceStatusWidthSlider:SetDisabled( not AJM.db.showTeamList )
		AJM.settingsControl.displayOptionsExperienceStatusHeightSlider:SetDisabled( not AJM.db.showTeamList )
		AJM.settingsControl.displayOptionsCheckBoxShowReputationStatus:SetDisabled( not AJM.db.showTeamList )
		AJM.settingsControl.displayOptionsCheckBoxShowReputationName:SetDisabled( not AJM.db.showTeamList )
		AJM.settingsControl.displayOptionsCheckBoxShowReputationStatusValues:SetDisabled( not AJM.db.showTeamList )
		AJM.settingsControl.displayOptionsCheckBoxShowReputationStatusPercentage:SetDisabled( not AJM.db.showTeamList )
		AJM.settingsControl.displayOptionsReputationStatusWidthSlider:SetDisabled( not AJM.db.showTeamList )
		AJM.settingsControl.displayOptionsReputationStatusHeightSlider:SetDisabled( not AJM.db.showTeamList )
		AJM.settingsControl.displayOptionsCheckBoxShowHealthStatus:SetDisabled( not AJM.db.showTeamList )
		AJM.settingsControl.displayOptionsCheckBoxShowHealthStatusValues:SetDisabled( not AJM.db.showTeamList )
		AJM.settingsControl.displayOptionsCheckBoxShowHealthStatusPercentage:SetDisabled( not AJM.db.showTeamList )
		AJM.settingsControl.displayOptionsHealthStatusWidthSlider:SetDisabled( not AJM.db.showTeamList )
		AJM.settingsControl.displayOptionsHealthStatusHeightSlider:SetDisabled( not AJM.db.showTeamList )
		AJM.settingsControl.displayOptionsCheckBoxShowPowerStatus:SetDisabled( not AJM.db.showTeamList )
		AJM.settingsControl.displayOptionsCheckBoxShowPowerStatusValues:SetDisabled( not AJM.db.showTeamList )
		AJM.settingsControl.displayOptionsCheckBoxShowPowerStatusPercentage:SetDisabled( not AJM.db.showTeamList )
		AJM.settingsControl.displayOptionsPowerStatusWidthSlider:SetDisabled( not AJM.db.showTeamList )
		AJM.settingsControl.displayOptionsPowerStatusHeightSlider:SetDisabled( not AJM.db.showTeamList )
		AJM.settingsControl.displayOptionsCheckBoxShowComboStatus:SetDisabled( not AJM.db.showTeamList )
		AJM.settingsControl.displayOptionsCheckBoxShowComboStatusValues:SetDisabled( not AJM.db.showTeamList )
		AJM.settingsControl.displayOptionsCheckBoxShowComboStatusPercentage:SetDisabled( not AJM.db.showTeamList )
		AJM.settingsControl.displayOptionsComboStatusWidthSlider:SetDisabled( not AJM.db.showTeamList )
		AJM.settingsControl.displayOptionsComboStatusHeightSlider:SetDisabled( not AJM.db.showTeamList )
		AJM.settingsControl.displayOptionsBackgroundColourPicker:SetDisabled( not AJM.db.showTeamList )
		AJM.settingsControl.displayOptionsBorderColourPicker:SetDisabled( not AJM.db.showTeamList )
--		AJM.settingsControl.displayOptionsCheckBoxShowBagInformation:SetDisabled( not AJM.db.showTeamList )
--		AJM.settingsControl.displayOptionsCheckBoxShowFreeBagSlotsOnly:SetDisabled( not AJM.db.showTeamList )
--		AJM.settingsControl.displayOptionsBagInformationWidthSlider:SetDisabled( not AJM.db.showTeamList )
--		AJM.settingsControl.displayOptionsBagInformationHeightSlider:SetDisabled( not AJM.db.showTeamList )
--		AJM.settingsControl.displayOptionsCheckBoxShowIlvlInformation:SetDisabled( not AJM.db.showTeamList )
--		AJM.settingsControl.displayOptionsCheckBoxShowEquippedOnly:SetDisabled( not AJM.db.showTeamList )
--		AJM.settingsControl.displayOptionsCheckBoxstackName:SetDisabled( not AJM.db.showTeamList )
		--AJM.settingsControl.displayOptionsIlvlInformationWidthSlider:SetDisabled( not AJM.db.showTeamList )
		--AJM.settingsControl.displayOptionsIlvlInformationHeightSlider:SetDisabled( not AJM.db.showTeamList )
		if AJM.teamListCreated == true then
			AJM:RefreshTeamListControls()
			AJM:SettingsUpdateBorderStyle()
			AJM:SettingsUpdateStatusBarTexture()
			AJM:SetTeamListVisibility()	
			AJM:SettingsUpdateFollowTextAll()
			AJM:SettingsUpdateExperienceAll()
			AJM:SettingsUpdateReputationAll()
			AJM:SettingsUpdateHealthAll()
			AJM:SettingsUpdatePowerAll()
			AJM:SettingsUpdateComboAll()
			--AJM:SettingsUpdateBagInformationAll()
			--AJM:SettingsUpdateIlvlInformationAll()
		end
	else
		AJM.updateSettingsAfterCombat = true
	end
end

-- Settings received.
function AJM:JambaOnSettingsReceived( characterName, settings )	
	if characterName ~= AJM.characterName then
		-- Update the settings.
		AJM.db.showTeamList = settings.showTeamList
		AJM.db.showTeamListOnMasterOnly = settings.showTeamListOnMasterOnly
		AJM.db.hideTeamListInCombat = settings.hideTeamListInCombat
		AJM.db.enableClique = settings.enableClique
		AJM.db.barsAreStackedVertically = settings.barsAreStackedVertically
		AJM.db.teamListHorizontal = settings.teamListHorizontal
		AJM.db.showListTitle = settings.showListTitle
		AJM.db.teamListScale = settings.teamListScale
		AJM.db.statusBarTexture = settings.statusBarTexture
		AJM.db.borderStyle = settings.borderStyle
		AJM.db.backgroundStyle = settings.backgroundStyle
		AJM.db.showCharacterPortrait = settings.showCharacterPortrait
		AJM.db.characterPortraitWidth = settings.characterPortraitWidth
		AJM.db.showFollowStatus = settings.showFollowStatus
		AJM.db.followStatusWidth = settings.followStatusWidth
		AJM.db.followStatusHeight = settings.followStatusHeight
		AJM.db.followStatusShowName = settings.followStatusShowName
--		AJM.db.followStatusShowLevel = settings.followStatusShowLevel
		AJM.db.showExperienceStatus = settings.showExperienceStatus
		AJM.db.experienceStatusWidth = settings.experienceStatusWidth
		AJM.db.experienceStatusHeight = settings.experienceStatusHeight
		AJM.db.experienceStatusShowValues = settings.experienceStatusShowValues
		AJM.db.experienceStatusShowPercentage = settings.experienceStatusShowPercentage
		AJM.db.showReputationStatus = settings.showReputationStatus
		AJM.db.showReputationName = settings.showReputationName
		AJM.db.reputationStatusWidth = settings.reputationStatusWidth
		AJM.db.reputationStatusHeight = settings.reputationStatusHeight
		AJM.db.reputationStatusShowValues = settings.reputationStatusShowValues
		AJM.db.reputationStatusShowPercentage = settings.reputationStatusShowPercentage
		AJM.db.showHealthStatus = settings.showHealthStatus
		AJM.db.healthStatusWidth = settings.healthStatusWidth
		AJM.db.healthStatusHeight = settings.healthStatusHeight
		AJM.db.healthStatusShowValues = settings.healthStatusShowValues
		AJM.db.healthStatusShowPercentage = settings.healthStatusShowPercentage
		AJM.db.showPowerStatus = settings.showPowerStatus
		AJM.db.powerStatusWidth = settings.powerStatusWidth
		AJM.db.powerStatusHeight = settings.powerStatusHeight		
		AJM.db.powerStatusShowValues = settings.powerStatusShowValues
		AJM.db.powerStatusShowPercentage = settings.powerStatusShowPercentage
		AJM.db.showComboStatus = settings.showComboStatus
		AJM.db.comboStatusWidth = settings.comboStatusWidth
		AJM.db.comboStatusHeight = settings.comboStatusHeight		
		AJM.db.comboStatusShowValues = settings.comboStatusShowValues
		AJM.db.comboStatusShowPercentage = settings.comboStatusShowPercentage
--		AJM.db.showBagInformation = settings.showBagInformation
--		AJM.db.showBagFreeSlotsOnly = settings.showBagFreeSlotsOnly
--		AJM.db.bagInformationWidth = settings.bagInformationWidth
--		AJM.db.bagInformationHeight = settings.bagInformationHeight
		--EBS
--		AJM.db.showIlvlInformation = settings.showIlvlInformation
--		AJM.db.ShowEquippedOnly = settings.ShowEquippedOnly
--		AJM.db.stackName = settings.stackName
		--AJM.db.ilvlInformationWidth = settings.ilvlInformationWidth
		--AJM.db.ilvlInformationHeight = settings.ilvlInformationHeight		
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

-------------------------------------------------------------------------------------------------------------
-- Settings Callbacks.
-------------------------------------------------------------------------------------------------------------

function AJM:SettingsPushSettingsClick( event )
	AJM:JambaSendSettings()
end

function AJM:SettingsToggleShowTeamList( event, checked )
	AJM.db.showTeamList = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleShowTeamListOnMasterOnly( event, checked )
	AJM.db.showTeamListOnMasterOnly = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleHideTeamListInCombat( event, checked )
	AJM.db.hideTeamListInCombat = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleEnableClique( event, checked )
	AJM.db.enableClique = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleStackVertically( event, checked )
	AJM.db.barsAreStackedVertically = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleTeamHorizontal( event, checked )
	AJM.db.teamListHorizontal = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleShowTeamListTitle( event, checked )
	AJM.db.showListTitle = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsChangeScale( event, value )
	AJM.db.teamListScale = tonumber( value )
	AJM:SettingsRefresh()
end

function AJM:SettingsChangeTransparency( event, value )
	AJM.db.frameAlpha = tonumber( value )
	AJM:SettingsRefresh()
end

function AJM:SettingsChangeStatusBarTexture( event, value )
	AJM.db.statusBarTexture = value
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

function AJM:SettingsToggleShowPortrait( event, checked )
	AJM.db.showCharacterPortrait = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsChangePortraitWidth( event, value )
	AJM.db.characterPortraitWidth = tonumber( value )
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleShowFollowStatus( event, checked )
	AJM.db.showFollowStatus = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleShowFollowStatusName( event, checked )
	AJM.db.followStatusShowName = checked
	AJM:SettingsRefresh()
end

--[[
function AJM:SettingsToggleShowFollowStatusLevel( event, checked )
	AJM.db.followStatusShowLevel = checked
	AJM:SettingsRefresh()
end]]

function AJM:SettingsChangeFollowStatusWidth( event, value )
	AJM.db.followStatusWidth = tonumber( value )
	AJM:SettingsRefresh()
end

function AJM:SettingsChangeFollowStatusHeight( event, value )
	AJM.db.followStatusHeight = tonumber( value )
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleShowExperienceStatus( event, checked )
	AJM.db.showExperienceStatus = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleShowExperienceStatusValues( event, checked )
	AJM.db.experienceStatusShowValues = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleShowExperienceStatusPercentage( event, checked )
	AJM.db.experienceStatusShowPercentage = checked
	AJM.SettingsRefresh()
end

function AJM:SettingsChangeExperienceStatusWidth( event, value )
	AJM.db.experienceStatusWidth = tonumber( value )
	AJM:SettingsRefresh()
end

function AJM:SettingsChangeExperienceStatusHeight( event, value )
	AJM.db.experienceStatusHeight = tonumber( value )
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleShowReputationStatus( event, checked )
	AJM.db.showReputationStatus = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleShowReputationName( event, checked )
	AJM.db.showReputationName = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleShowReputationStatusValues( event, checked )
	AJM.db.reputationStatusShowValues = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleShowReputationStatusPercentage( event, checked )
	AJM.db.reputationStatusShowPercentage = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsChangeReputationStatusWidth( event, value )
	AJM.db.reputationStatusWidth = tonumber( value )
	AJM:SettingsRefresh()
end

function AJM:SettingsChangeReputationStatusHeight( event, value )
	AJM.db.reputationStatusHeight = tonumber( value )
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleShowHealthStatus( event, checked )
	AJM.db.showHealthStatus = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleShowHealthStatusValues( event, checked )
	AJM.db.healthStatusShowValues = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleShowHealthStatusPercentage( event, checked )
	AJM.db.healthStatusShowPercentage = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsChangeHealthStatusWidth( event, value )
	AJM.db.healthStatusWidth = tonumber( value )
	AJM:SettingsRefresh()
end

function AJM:SettingsChangeHealthStatusHeight( event, value )
	AJM.db.healthStatusHeight = tonumber( value )
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleShowPowerStatus( event, checked )
	AJM.db.showPowerStatus = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleShowPowerStatusValues( event, checked )
	AJM.db.powerStatusShowValues = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleShowPowerStatusPercentage( event, checked )
	AJM.db.powerStatusShowPercentage = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsChangePowerStatusWidth( event, value )
	AJM.db.powerStatusWidth = tonumber( value )
	AJM:SettingsRefresh()
end

function AJM:SettingsChangePowerStatusHeight( event, value )
	AJM.db.powerStatusHeight = tonumber( value )
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleShowComboStatus( event, checked )
	AJM.db.showComboStatus = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleShowComboStatusValues( event, checked )
	AJM.db.comboStatusShowValues = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleShowComboStatusPercentage( event, checked )
	AJM.db.comboStatusShowPercentage = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsChangeComboStatusWidth( event, value )
	AJM.db.comboStatusWidth = tonumber( value )
	AJM:SettingsRefresh()
end

function AJM:SettingsChangeComboStatusHeight( event, value )
	AJM.db.comboStatusHeight = tonumber( value )
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

--[[
function AJM:SettingsToggleShowBagInformation( event, checked )
	AJM.db.showBagInformation = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleShowFreeBagSlotsOnly( event, checked )
	AJM.db.showBagFreeSlotsOnly = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsChangeBagInformationWidth( event, value )
	AJM.db.bagInformationWidth = tonumber( value )
	AJM:SettingsRefresh()
end

function AJM:SettingsChangeBagInformationHeight( event, value )
	AJM.db.bagInformationHeight = tonumber( value )
	AJM:SettingsRefresh()
end
--]]
--ilvl
--[[
function AJM:SettingsToggleShowIlvlInformation( event, checked )
	AJM.db.showIlvlInformation = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsToggleShowEquippedOnly( event, checked )
	AJM.db.ShowEquippedOnly = checked
	AJM:SettingsRefresh()
end

function AJM:SettingsTogglestackName( event, checked )
	AJM.db.stackName = checked
	AJM:SettingsRefresh()
end]]

--[[
function AJM:SettingsChangeIlvlInformationWidth( event, value )
	AJM.db.ilvlInformationWidth = tonumber( value )
	AJM:SettingsRefresh()
end

function AJM:SettingsChangeIlvlInformationHeight( event, value )
	AJM.db.ilvlInformationHeight = tonumber( value )
	AJM:SettingsRefresh()
end
--]]

-------------------------------------------------------------------------------------------------------------
-- Commands.
-------------------------------------------------------------------------------------------------------------

-- A Jamba command has been recieved.
function AJM:JambaOnCommandReceived( characterName, commandName, ... )
	AJM:DebugMessage( "JambaOnCommandReceived", characterName )
	if commandName == AJM.COMMAND_FOLLOW_STATUS_UPDATE then
		AJM:ProcessUpdateFollowStatusMessage( characterName, ... )
	end
	if commandName == AJM.COMMAND_EXPERIENCE_STATUS_UPDATE then
		AJM:ProcessUpdateExperienceStatusMessage( characterName, ... )
	end
	if commandName == AJM.COMMAND_REPUTATION_STATUS_UPDATE then
		AJM:ProcessUpdateReputationStatusMessage( characterName, ... )
	end
--	if commandName == AJM.COMMAND_BAGINFORMATION_UPDATE then
--		AJM:ProcessUpdateBagInformationMessage( characterName, ... )
--	end	
	if commandName == AJM.COMMAND_ITEMLEVELINFORMATION_UPDATE then
		AJM:ProcessUpdateIlvlInformationMessage( characterName, ... )
	end
	if commandName == AJM.COMMAND_COMBO_STATUS_UPDATE then
		AJM:ProcessUpdateComboStatusMessage( characterName, ... )
	end	
	if commandName == AJM.COMMAND_REQUEST_INFO then
		AJM.SendIlvlInformationUpdateCommand()
	end		
end	

-------------------------------------------------------------------------------------------------------------
-- Shared Media Callbacks
-------------------------------------------------------------------------------------------------------------

function AJM:LibSharedMedia_Registered()
end

function AJM:LibSharedMedia_SetGlobal()
end

-------------------------------------------------------------------------------------------------------------
-- Status Bar Updates.
-------------------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------------------------
-- Range Status Bar Updates.
-------------------------------------------------------------------------------------------------------------

function AJM:RangeUpdateCommand()
	for characterName, characterStatusBar in pairs( AJM.characterStatusBar ) do			
		--AJM:Print("name", characterName )
		local name = Ambiguate( characterName, "none" )
		local range = UnitInRange( name )
		AJM:UpdateHealthStatus( name, nil, nil, range, nil )
		AJM:UpdatePowerStatus( name, nil, nil, range )
		AJM:UpdateComboStatus( name, nil, nil, range )
		AJM:UpdateReputationStatus( name, nil, nil, nil, nil, nil, range )
		AJM:UpdateExperienceStatus( name, nil, nil, nil, range )
--		AJM:ProcessUpdateBagInformationMessage( name, nil, nil, range )		
	end				
end

--[[
-------------------------------------------------------------------------------------------------------------
-- Bag Information Updates.
-------------------------------------------------------------------------------------------------------------

function AJM:ITEM_PUSH( event, ... )
	AJM:SendBagInformationUpdateCommand()	
end	

function AJM:SendBagInformationUpdateCommand()
	if AJM.db.showTeamList == true and AJM.db.showBagInformation == true then
		if UnitIsGhost( "player" ) then
			return
		end
		if UnitIsDead( "player" ) then
			return
		end		
		local slotsFree, totalSlots = LibBagUtils:CountSlots( "BAGS", 0 )
		local curTotal, maxTotal, broken = 0, 0, 0
		
		--for i = 1, 18 do
		--	local curItemDurability, maxItemDurability = GetInventoryItemDurability(i)
		--	if curItemDurability and maxItemDurability then
		--	curTotal = curTotal + curItemDurability
		--	maxTotal = maxTotal + maxItemDurability
		--		if maxItemDurability > 0 and curItemDurability == 0 then
		--			broken = broken + 1
		--		end
		--	end
		--local percent = curTotal / maxTotal * 100
		--return percent, broken
		--end
		--AJM:Print("Durability", percent, broken)
		--if AJM.previousSlotsFree ~= slotsFree or AJM.previousTotalSlots ~= totalSlots then
		if AJM.db.showTeamListOnMasterOnly == true then
			AJM:JambaSendCommandToMaster( AJM.COMMAND_BAGINFORMATION_UPDATE, slotsFree, totalSlots )
		else
			AJM:JambaSendCommandToTeam( AJM.COMMAND_BAGINFORMATION_UPDATE, slotsFree, totalSlots )
		end
	end
end

function AJM:ProcessUpdateBagInformationMessage( characterName, slotsFree, totalSlots, range )
	AJM:UpdateBagInformation( characterName, slotsFree, totalSlots, range )
end

function AJM:SettingsUpdateBagInformationAll()
	for characterName, characterStatusBar in pairs( AJM.characterStatusBar ) do			
		AJM:UpdateBagInformation( characterName, nil, nil, nil, nil )
	end
end

function AJM:UpdateBagInformation( characterName, slotsFree, totalSlots, range ) --percent, range )
--	AJM:Print("Data", characterName, slotsFree, totalSlots, percent )
	if CanDisplayTeamList() == false then
		return
	end
	if AJM.db.showBagInformation == false then
		return
	end
	characterName = JambaUtilities:AddRealmToNameIfMissing( characterName )
	local characterStatusBar = AJM.characterStatusBar[characterName]
	if characterStatusBar == nil then
		return
	end
	local bagInformationFrame = characterStatusBar["bagInformationFrame"]
	local bagInformationFrameText = characterStatusBar["bagInformationFrameText"]
	if slotsFree == nil then
		slotsFree = bagInformationFrame.slotsFree
	end
	if totalSlots == nil then
		totalSlots = bagInformationFrame.totalSlots
	end
--	if percent == nil or percent == false then
--		percent = bagInformationFrame.durability
--	end	
	bagInformationFrame.slotsFree = slotsFree
	bagInformationFrame.totalSlots = totalSlots
--	bagInformationFrame.durability = percent
	if 	UnitInParty(Ambiguate( characterName, "none" ) ) == true then
		if range == false then
			bagInformationFrame:SetAlpha( 0.5 )
		else
			bagInformationFrame:SetAlpha( 1 )
		end
	else
		bagInformationFrame:SetAlpha( 1 )
	end
	
	--AJM:Print("test", percent)
	--local durability = gsub(percent, "%.[^|]+", "")
	--AJM:Print("hello", durability)
	--text = text..L["Dura"]..L[" "]..tostring(gsub(percent, "%.[^|]+", "") )..L["%"]
	local text = ""
	if AJM.db.showBagFreeSlotsOnly == true then
		--text = text..("\n")..L["BgS"]..L[" "]..tostring(slotsFree)
		text = tostring(slotsFree)
	else
		--text = text..("\n")..L["BgS"]..L[" "]..tostring((totalSlots - slotsFree)).."/"..tostring(totalSlots)
		text = tostring((totalSlots - slotsFree)).."/"..tostring(totalSlots)
	end
	bagInformationFrameText:SetText( text )	
	--AJM:Print("freespace", slotsFree, totalSlots) --Debug
end
--]]
-------------------------------------------------------------------------------------------------------------
-- Ilvl Information Updates.
-------------------------------------------------------------------------------------------------------------
--[[
function AJM:ITEMLVL_PUSH( event, ... )
	AJM:SendIlvlInformationUpdateCommand()	
end

function AJM:PLAYER_EQUIPMENT_CHANGED( event, ... )
	AJM:SendIlvlInformationUpdateCommand()	
end
]]

function AJM:JambaRequestUpdate()		
	AJM:JambaSendCommandToTeam( AJM.COMMAND_REQUEST_INFO )
end

function AJM:SendIlvlInformationUpdateCommand()
	if AJM.db.showTeamList == true then --and AJM.db.showIlvlInformation == true or AJM.db.followStatusShowLevel == true then
		if UnitIsGhost( "player" ) then
			return
		end
		if UnitIsDead( "player" ) then
			return
		end	
		-- Item Level	
		local overall, equipped = GetAverageItemLevel()
		-- characterLevel
		local characterLevel = UnitLevel("player")
		-- gold
		local gold = GetMoney()
		-- Bag information
		local slotsFree, totalSlots = LibBagUtils:CountSlots( "BAGS", 0 )
		-- durability
		local curTotal, maxTotal, broken = 0, 0, 0
		for i = 1, 18 do
			local curItemDurability, maxItemDurability = GetInventoryItemDurability(i)
			if curItemDurability and maxItemDurability then
				curTotal = curTotal + curItemDurability
				maxTotal = maxTotal + maxItemDurability
					if maxItemDurability > 0 and curItemDurability == 0 then
						broken = broken + 1
					end
			end
		end
		local durability = curTotal / maxTotal * 100
		--Mail (blizzard minimap code)
		toolText = "nothing"
		if HasNewMail() == true then
			local sender1,sender2,sender3 = GetLatestThreeSenders()
			if( sender1 or sender2 or sender3 ) then
				if( sender1 ) then
					toolText = sender1
				end
				if( sender2 ) then
					toolText = toolText.."\n"..sender2
				end
				if( sender3 ) then
				toolText = toolText.."\n"..sender3
				end
			else
				toolText = L["Unknown Sender"]
			end
		end
		--  Currency 6.2.x max of 3  Currency on backback so we check 3 times using GetNumWatchedTokens() always returns 1 bugged?
		currText = "nothing"
		--local name, count, icon, currencyID
		local name, count, icon, currencyID = GetBackpackCurrencyInfo(1)
			if ( name ) then
				--AJM:Print("test", name, count)
				currText = name.." ".." |T"..icon..":16|t".." "..count
			end
		local name, count, icon, currencyID = GetBackpackCurrencyInfo(2)
			if ( name ) then
				--AJM:Print("test2", name, count)
				currText = currText.."\n"..name.." ".." |T"..icon..":16|t".." "..count
			end
		local name, count, icon, currencyID = GetBackpackCurrencyInfo(3)
			if ( name ) then
				--AJM:Print("test3", name, count)
				currText = currText.."\n"..name.." ".." |T"..icon..":16|t".." "..count
			end
	
		
		--AJM:Print("CurrTest", currText)
		--AJM:Print("test", slotsFree, totalSlots)
		--if AJM.previousIlvl ~= overall then ---or AJM.previousTotalSlots ~= totalSlots then
			if AJM.db.showTeamListOnMasterOnly == true then
				AJM:JambaSendCommandToMaster( AJM.COMMAND_ITEMLEVELINFORMATION_UPDATE, characterLevel, overall, equipped, gold, durability, slotsFree, totalSlots, currName, currCout, toolText, currText)
			else
				AJM:JambaSendCommandToTeam( AJM.COMMAND_ITEMLEVELINFORMATION_UPDATE, characterLevel, overall, equipped, gold, durability, slotsFree, totalSlots, currName, currCout, toolText, currText)
			end
		end
end

-------------------------------------------------------------------------------------------------------------
-- Follow Status Bar Updates.
-------------------------------------------------------------------------------------------------------------

function AJM:AUTOFOLLOW_BEGIN( event, ... )
	AJM:SendFollowStatusUpdateCommand( true )
end

function AJM:AUTOFOLLOW_END( event, followEndedReason, ... )
	AJM:SendFollowStatusUpdateCommand( false )
end

function AJM:SendFollowStatusUpdateCommand( isFollowing )
	if AJM.db.showTeamList == true and AJM.db.showFollowStatus == true then
		-- Check to see if JambaFollow is enabled and follow strobing is on.  If this is the case then
		-- do not send the follow update.
		local canSend = true
		if JambaApi.Follow ~= nil then
			if JambaApi.Follow.IsFollowingStrobing() == true then
				canSend = false
			end
		end
		if canSend == true then
			if AJM.db.showTeamListOnMasterOnly == true then
				AJM:JambaSendCommandToMaster( AJM.COMMAND_FOLLOW_STATUS_UPDATE, isFollowing )
			else
				AJM:JambaSendCommandToTeam( AJM.COMMAND_FOLLOW_STATUS_UPDATE, isFollowing )
			end
		end
	end
end

function AJM:ProcessUpdateFollowStatusMessage( characterName, isFollowing )
	AJM:UpdateFollowStatus( characterName, isFollowing, false )
end

--TODO: Ebony,-- See if this code could be cleaned up a little as when in combat takes a few mins after to catch up. Sending add-on msg with combat?
function AJM:UpdateFollowStatus( characterName, isFollowing, isFollowLeader )
	if CanDisplayTeamList() == false then
		return
	end
	if AJM.db.showFollowStatus == false then
		return
	end
	characterName = JambaUtilities:AddRealmToNameIfMissing( characterName )
	local characterStatusBar = AJM.characterStatusBar[characterName]
	if characterStatusBar == nil then
		return
	end
	local followBar = characterStatusBar["followBar"]	
	if isFollowing == true then
		-- Following.
		followBar:SetStatusBarColor( 0.05, 0.85, 0.05, 1.00 )
	else
		if isFollowLeader == true then
			-- Follow leader.
			followBar:SetStatusBarColor( 0.55, 0.15, 0.15, 0.25 )
		else
			-- Not following.
			followBar:SetStatusBarColor( 0.85, 0.05, 0.05, 1.00 )
		end
	end		
end

function AJM:ProcessUpdateIlvlInformationMessage( characterName, characterLevel, overall, equipped, gold, durability, slotsFree, totalSlots, toolText, currText )
	AJM:SettingsUpdateFollowText( characterName, characterLevel, overall, equipped, gold, durability, slotsFree, totalSlots, toolText, currText )
end


function AJM:SettingsUpdateFollowTextAll()
	for characterName, characterStatusBar in pairs( AJM.characterStatusBar ) do			
		AJM:SettingsUpdateFollowText( characterName, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil )
	end
end


function AJM:SettingsUpdateFollowText( characterName, characterLevel, overall, equipped, gold, durability, slotsFree, totalSlots, toolText, currText )
	--AJM:Print("Info", characterName, characterLevel, overall, equipped) -- debug
	if CanDisplayTeamList() == false then
		return
	end
	if AJM.db.showFollowStatus == false then
		return
	end
	characterName = JambaUtilities:AddRealmToNameIfMissing( characterName )
	local characterStatusBar = AJM.characterStatusBar[characterName]
	if characterStatusBar == nil then
		return
	end
	local ilvlInformationFrame = characterStatusBar["ilvlInformationFrame"]
	local ilvlInformationFrameText = characterStatusBar["ilvlInformationFrameText"]
	if overall == nil then
		overall = ilvlInformationFrame.overall
	end
	if equipped == nil then
		equipped = ilvlInformationFrame.equipped
	end
	if characterLevel == nil then
		characterLevel = ilvlInformationFrame.characterLevel
	end
	if gold == nil then
		gold = ilvlInformationFrame.gold
	end
	if durability == nil then
		durability = ilvlInformationFrame.durability
	end
	if slotsFree == nil then
		slotsFree = ilvlInformationFrame.slotsFree
	end
	if totalSlots == nil then
		totalSlots = ilvlInformationFrame.totalSlots
	end
	if toolText == nil then
		toolText = ilvlInformationFrame.toolText
	end	
	if currText == nil then
		currText = ilvlInformationFrame.currText
	end	
	ilvlInformationFrame.overall = overall
	ilvlInformationFrame.equipped = equipped
	ilvlInformationFrame.characterLevel = characterLevel
	ilvlInformationFrame.gold = gold
	ilvlInformationFrame.durability = durability
	ilvlInformationFrame.slotsFree = slotsFree
	ilvlInformationFrame.totalSlots = totalSlots
	ilvlInformationFrame.toolText = toolText
	ilvlInformationFrame.currText = currText
	local followBarText = characterStatusBar["followBarText"]
	local text = ""
	if AJM.db.followStatusShowName == true then
		text = text..Ambiguate( characterName, "none" )
	end
	-- code to be removed if using the new tooltip way.
	--[[
	if AJM.db.followStatusShowLevel == true then
		if AJM.db.followStatusShowName == true then
			if AJM.db.stackName == true then
				text = text..L[" "]..("\n")..L["("]..tostring( characterLevel )..L[")"]
			else
				text = text..L[" "]..L["("]..tostring( characterLevel )..L[")"]
			end	
		else
			text = tostring( characterLevel )
		end
	end
	if AJM.db.showIlvlInformation == true then
		if AJM.db.ShowEquippedOnly == true then
			if AJM.db.stackName == true then
				text = text..L[" "]..("\n")..L["("]..tostring (format("%.0f", equipped ))..L[")"]
			else
				text = text..L[" "]..L["("]..tostring (format("%.0f", equipped ))..L[")"]
			end	
		else
			if AJM.db.stackName == true then
				text = text..L[" "]..("\n")..L["("]..tostring(format("%.0f", equipped )).."/"..tostring(format("%.0f", overall ))..L[")"]
			else
				text = text..L[" "]..L["("]..tostring(format("%.0f", equipped )).."/"..tostring(format("%.0f", overall ))..L[")"]
			end
		end	
	end
	--]]
	--AJM:Print(text)
	followBarText:SetText( text )
	--followBarClick.GameTooltip:AddLine( text )
end


-------------------------------------------------------------------------------------------------------------
-- Experience Status Bar Updates.
-------------------------------------------------------------------------------------------------------------

function AJM:PLAYER_XP_UPDATE( event, ... )
	AJM:SendExperienceStatusUpdateCommand()	
end

function AJM:UPDATE_EXHAUSTION( event, ... )
	AJM:SendExperienceStatusUpdateCommand()	
end

function AJM:PLAYER_LEVEL_UP( event, ... )
	AJM:SendExperienceStatusUpdateCommand()	
	--AJM:SettingsUpdateFollowTextAll()
	--AJM:SendIlvlInformationUpdateCommand()
end

function AJM:SendExperienceStatusUpdateCommand()
	if AJM.db.showTeamList == true and AJM.db.showExperienceStatus == true then
		-- Hide the xp bar at max level as its nolonger needed.
		local uLevel = UnitLevel("player")
		local maxLevel = GetMaxPlayerLevel()
		--[[
		if uLevel == maxLevel then
			--AJM:Print("maxLevel", uLevel, maxLevel) --debug
			AJM.db.showExperienceStatus = false
			AJM.SettingsRefresh()
			AJM:JambaSendSettings()
		end
		--]]
		local playerExperience = UnitXP( "player" )
		local playerMaxExperience = UnitXPMax( "player" )
		local playerMaxLevel = GetMaxPlayerLevel()	
		local playerLevel = UnitLevel("player")
		local exhaustionStateID, exhaustionStateName, exhaustionStateMultiplier = GetRestState()
			if AJM.db.showTeamListOnMasterOnly == true then
				AJM:JambaSendCommandToMaster( AJM.COMMAND_EXPERIENCE_STATUS_UPDATE, playerExperience, playerMaxExperience, exhaustionStateID)
			else
				AJM:DebugMessage( "SendExperienceStatusUpdateCommand TO TEAM!" )
				AJM:JambaSendCommandToTeam( AJM.COMMAND_EXPERIENCE_STATUS_UPDATE, playerExperience, playerMaxExperience, exhaustionStateID)
			end
	end
end

function AJM:ProcessUpdateExperienceStatusMessage( characterName, playerExperience, playerMaxExperience, exhaustionStateID, range )
	AJM:UpdateExperienceStatus( characterName, playerExperience, playerMaxExperience, exhaustionStateID, range )
end

function AJM:SettingsUpdateExperienceAll()
	for characterName, characterStatusBar in pairs( AJM.characterStatusBar ) do			
		AJM:UpdateExperienceStatus( characterName, nil, nil, nil, nil )
	end
end

function AJM:UpdateExperienceStatus( characterName, playerExperience, playerMaxExperience, exhaustionStateID, range )
	--AJM:Print( "UpdateExperienceStatus", characterName, playerExperience, playerMaxExperience, exhaustionStateID, range)
	
	if CanDisplayTeamList() == false then
		return
	end
	if AJM.db.showExperienceStatus == false then
		return
	end
	
	characterName = JambaUtilities:AddRealmToNameIfMissing( characterName )
	local characterStatusBar = AJM.characterStatusBar[characterName]
	if characterStatusBar == nil then
		return
	end
	local experienceBarText = characterStatusBar["experienceBarText"]	
	local experienceBar = characterStatusBar["experienceBar"]	
	if playerExperience == nil then
		playerExperience = experienceBarText.playerExperience
	end
	if playerMaxExperience == nil then
		playerMaxExperience = experienceBarText.playerMaxExperience
	end
	if exhaustionStateID == nil then
		exhaustionStateID = experienceBarText.exhaustionStateID
	end
	
	experienceBarText.playerExperience = playerExperience
	experienceBarText.playerMaxExperience = playerMaxExperience
	experienceBarText.exhaustionStateID = exhaustionStateID
	experienceBar:SetMinMaxValues( 0, tonumber( playerMaxExperience ) )
	experienceBar:SetValue( tonumber( playerExperience ) )
	if 	UnitInParty(Ambiguate( characterName, "none" ) ) == true then
		if range == false then
			experienceBar:SetAlpha( 0.5 )
		else
			experienceBar:SetAlpha( 1 )
		end
	else
		experienceBar:SetAlpha( 1 )
	end
	local text = ""
	if AJM.db.experienceStatusShowValues == true then
		text = text..tostring( playerExperience )..L[" / "]..tostring( playerMaxExperience )..L[" "]
	end
	if AJM.db.experienceStatusShowPercentage == true then
		if AJM.db.experienceStatusShowValues == true then
			text = text..L["("]..tostring( floor( (playerExperience/playerMaxExperience)*100) )..L["%"]..L[")"]
		else
			text = tostring( floor( (playerExperience/playerMaxExperience)*100) )..L["%"]
		end
	end
	experienceBarText:SetText( text )		
	if exhaustionStateID == 1 then
		experienceBar:SetStatusBarColor( 0.0, 0.39, 0.88, 1.0 )
		experienceBar.backgroundTexture:SetTexture( 0.0, 0.39, 0.88, 0.15 )
	else
		experienceBar:SetStatusBarColor( 0.58, 0.0, 0.55, 1.0 )
		experienceBar.backgroundTexture:SetTexture( 0.58, 0.0, 0.55, 0.15 )
	end	
end

-------------------------------------------------------------------------------------------------------------
-- Reputation Status Bar Updates.
-------------------------------------------------------------------------------------------------------------

function AJM:CHAT_MSG_COMBAT_FACTION_CHANGE( event, ... )
	AJM:SendReputationStatusUpdateCommand()	
end

function AJM:SetWatchedFactionIndex( index )
	AJM:ScheduleTimer( "SendReputationStatusUpdateCommand", 5 )
end

function AJM:SendReputationStatusUpdateCommand()
	if AJM.db.showTeamList == true and AJM.db.showReputationStatus == true then
		local reputationName, reputationStandingID, reputationBarMin, reputationBarMax, reputationBarValue = GetWatchedFactionInfo()
		if AJM.db.showTeamListOnMasterOnly == true then
			AJM:JambaSendCommandToMaster( AJM.COMMAND_REPUTATION_STATUS_UPDATE, reputationName, reputationStandingID, reputationBarMin, reputationBarMax, reputationBarValue )
		else
			AJM:JambaSendCommandToTeam( AJM.COMMAND_REPUTATION_STATUS_UPDATE, reputationName, reputationStandingID, reputationBarMin, reputationBarMax, reputationBarValue )
		end
	end
end

function AJM:ProcessUpdateReputationStatusMessage( characterName, reputationName, reputationStandingID, reputationBarMin, reputationBarMax, reputationBarValue, range )
	AJM:UpdateReputationStatus( characterName, reputationName, reputationStandingID, reputationBarMin, reputationBarMax, reputationBarValue, range )
end

function AJM:SettingsUpdateReputationAll()
	for characterName, characterStatusBar in pairs( AJM.characterStatusBar ) do			
		AJM:UpdateReputationStatus( characterName, nil, nil, nil, nil, nil, nil )
	end
end

function AJM:UpdateReputationStatus( characterName, reputationName, reputationStandingID, reputationBarMin, reputationBarMax, reputationBarValue, range )
	if CanDisplayTeamList() == false then
		return
	end
	if AJM.db.showReputationStatus == false then
		return
	end
	characterName = JambaUtilities:AddRealmToNameIfMissing( characterName )
	local characterStatusBar = AJM.characterStatusBar[characterName]
	if characterStatusBar == nil then
		return
	end
	local reputationBarText = characterStatusBar["reputationBarText"]	
	local reputationBar = characterStatusBar["reputationBar"]	
	if reputationName == nil then
		reputationName = reputationBarText.reputationName
	end
	if reputationStandingID == nil then
		reputationStandingID = reputationBarText.reputationStandingID
	end
	if reputationBarMin == nil then
		reputationBarMin = reputationBarText.reputationBarMin
	end
	if reputationBarMax == nil then
		reputationBarMax = reputationBarText.reputationBarMax
	end
	if reputationBarValue == nil then
		reputationBarValue = reputationBarText.reputationBarValue
	end
	reputationBarText.reputationName = reputationName
	reputationBarText.reputationStandingID = reputationStandingID
	reputationBarText.reputationBarMin = reputationBarMin
	reputationBarText.reputationBarMax = reputationBarMax
	reputationBarText.reputationBarValue = reputationBarValue
	reputationBar:SetMinMaxValues( tonumber( reputationBarMin ), tonumber( reputationBarMax ) )
	reputationBar:SetValue( tonumber( reputationBarValue ) )
    if reputationName == 0 then
        reputationBarMin = 0
        reputationBarMax = 100
        reputationBarValue = 100
        reputationStandingID = 1
    end
	if 	UnitInParty(Ambiguate( characterName, "none" ) ) == true then
		if range == false then
			reputationBar:SetAlpha( 0.5 )
		else
			reputationBar:SetAlpha( 1 )
		end
	else
		reputationBar:SetAlpha( 1 )
	end
	local text = ""
	if AJM.db.showReputationName == true then
        if reputationName == 0 then
		    text = text..L["No Faction Selected"].." "
        else
            text = text..reputationName.." "
        end
	end
	-- TODO: do we need to hook SetWatchedFactionIndex for when a watched faction changes?
	if AJM.db.reputationStatusShowValues == true then
		text = text..tostring( reputationBarValue-reputationBarMin )..L[" / "]..tostring( reputationBarMax-reputationBarMin )..L[" "]
	end
	if AJM.db.reputationStatusShowPercentage == true then
		local textPercentage = tostring( floor( (reputationBarValue-reputationBarMin)/(reputationBarMax-reputationBarMin)*100 ) )..L["%"]
		if AJM.db.reputationStatusShowValues == true then
			text = text..L["("]..textPercentage..L[")"]
		else
			text = text..textPercentage
		end
	end
	reputationBarText:SetText( text )
	local barColor = _G.FACTION_BAR_COLORS[reputationStandingID]
	if barColor ~= nil then
		reputationBar:SetStatusBarColor( barColor.r, barColor.g, barColor.b, 1.0 )
		reputationBar.backgroundTexture:SetTexture( barColor.r, barColor.g, barColor.b, 0.15 )
	end
end

-------------------------------------------------------------------------------------------------------------
-- Health Status Bar Updates.
-------------------------------------------------------------------------------------------------------------

function AJM:UNIT_HEALTH( event, unit, ... )
	AJM:SendHealthStatusUpdateCommand( unit,nil )
	--AJM:Print("test2", unit)	
end

function AJM:UNIT_MAXHEALTH( event, unit, ... )
	AJM:SendHealthStatusUpdateCommand( unit, nil )	
end


function AJM:SendHealthStatusUpdateCommand( unit, range )
	if AJM.db.showTeamList == true and AJM.db.showHealthStatus == true then
		local playerHealth = UnitHealth( unit )
		local playerMaxHealth = UnitHealthMax( unit )
		local isDead = UnitIsDeadOrGhost( unit )
		local characterName, characterRealm = UnitName( unit )
		local character = JambaUtilities:AddRealmToNameIfNotNil( characterName, characterRealm )
		--AJM:Print("HeathStats", character, playerHealth, playerMaxHealth, range)
		AJM:UpdateHealthStatus( character, playerHealth, playerMaxHealth, range, isDead )
	end
end

function AJM:SettingsUpdateHealthAll()
	for characterName, characterStatusBar in pairs( AJM.characterStatusBar ) do			
		AJM:UpdateHealthStatus( characterName, nil, nil, nil, nil )
	end
end

function AJM:UpdateHealthStatus( characterName, playerHealth, playerMaxHealth, range, isDead )
	if CanDisplayTeamList() == false then
		return
	end
	if AJM.db.showHealthStatus == false then
		return
	end
	characterName = JambaUtilities:AddRealmToNameIfMissing( characterName )
	local characterStatusBar = AJM.characterStatusBar[characterName]
	if characterStatusBar == nil then
		return
	end
	local healthBarText = characterStatusBar["healthBarText"]	
	local healthBar = characterStatusBar["healthBar"]	
	if playerHealth == nil then
		playerHealth = healthBarText.playerHealth
	end
	if playerMaxHealth == nil then
		playerMaxHealth = healthBarText.playerMaxHealth
	end	
	if 	UnitInParty(Ambiguate( characterName, "none" ) ) == true then
		if range == false then
			healthBar:SetAlpha( 0.5 )
		else
			healthBar:SetAlpha( 1 )
		end
	else
		healthBar:SetAlpha( 1 )
	end
	healthBarText.playerHealth = playerHealth
	healthBarText.playerMaxHealth = playerMaxHealth
	healthBar:SetMinMaxValues( 0, tonumber( playerMaxHealth ) )
	healthBar:SetValue( tonumber( playerHealth ) )
	local text = ""
	if UnitIsDeadOrGhost(Ambiguate( characterName, "none" ) ) == true then
	--if isDead == true then
		--AJM:Print("dead", characterName)
		text = text..L["DEAD"]	
	else
		if AJM.db.healthStatusShowValues == true then
			text = text..tostring( playerHealth )..L[" / "]..tostring( playerMaxHealth )..L[" "]
		end
		if AJM.db.healthStatusShowPercentage == true then
			if AJM.db.healthStatusShowValues == true then
				text = text..L["("]..tostring( floor( (playerHealth/playerMaxHealth)*100) )..L["%"]..L[")"]
			else
				text = tostring( floor( (playerHealth/playerMaxHealth)*100) )..L["%"]
			end
		end
	end
	healthBarText:SetText( text )		
	AJM:SetStatusBarColourForHealth( healthBar, floor((playerHealth/playerMaxHealth)*100) )
end

function AJM:SetStatusBarColourForHealth( statusBar, statusValue )
	local r, g, b = 0, 0, 0
	statusValue = statusValue / 100
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

-------------------------------------------------------------------------------------------------------------
-- Power Status Bar Updates.
-------------------------------------------------------------------------------------------------------------

function AJM:UNIT_POWER( event, unit, ... )
	AJM:SendPowerStatusUpdateCommand( unit )
end

function AJM:UNIT_DISPLAYPOWER( event, unit, ... )
	AJM:SendPowerStatusUpdateCommand( unit )
end

function AJM:SendPowerStatusUpdateCommand( unit )
	if AJM.db.showTeamList == true and AJM.db.showPowerStatus == true then
		local playerPower = UnitPower( unit )
		local playerMaxPower = UnitPowerMax( unit )
		local characterName, characterRealm = UnitName( unit )
		local character = JambaUtilities:AddRealmToNameIfNotNil( characterName, characterRealm )
		--AJM:Print("power", character, playerPower, playerMaxPower )
		AJM:UpdatePowerStatus( character, playerPower, playerMaxPower)
	end
end

function AJM:SettingsUpdatePowerAll()
	for characterName, characterStatusBar in pairs( AJM.characterStatusBar ) do			
		AJM:UpdatePowerStatus( characterName, nil, nil, nil )
	end
end

function AJM:UpdatePowerStatus( characterName, playerPower, playerMaxPower, range )
	if CanDisplayTeamList() == false then
		return
	end
	if AJM.db.showPowerStatus == false then
		return
	end
	local originalChatacterName = characterName
	characterName = JambaUtilities:AddRealmToNameIfMissing( characterName )
	local characterStatusBar = AJM.characterStatusBar[characterName]
	if characterStatusBar == nil then
		return
	end
	local powerBarText = characterStatusBar["powerBarText"]	
	local powerBar = characterStatusBar["powerBar"]	
	if playerPower == nil then
		playerPower = powerBarText.playerPower
	end
	if playerMaxPower == nil then
		playerMaxPower = powerBarText.playerMaxPower
	end
	if 	UnitInParty(Ambiguate( characterName, "none" ) ) == true then
		if range == false then
			powerBar:SetAlpha( 0.5 )
		else
			powerBar:SetAlpha( 1 )
		end	
	else
		powerBar:SetAlpha( 1 )
	end
	powerBarText.playerPower = playerPower
	powerBarText.playerMaxPower = playerMaxPower
	powerBar:SetMinMaxValues( 0, tonumber( playerMaxPower ) )
	powerBar:SetValue( tonumber( playerPower ) )
	local text = ""
	if AJM.db.powerStatusShowValues == true then
		text = text..tostring( playerPower )..L[" / "]..tostring( playerMaxPower )..L[" "]
	end
	if AJM.db.powerStatusShowPercentage == true then
		if AJM.db.powerStatusShowValues == true then
			text = text..L["("]..tostring( floor( (playerPower/playerMaxPower)*100) )..L["%"]..L[")"]
		else
			text = tostring( floor( (playerPower/playerMaxPower)*100) )..L["%"]
		end
	end
	powerBarText:SetText( text )		
	AJM:SetStatusBarColourForPower( powerBar, originalChatacterName )
end

function AJM:SetStatusBarColourForPower( statusBar, unit )
	unit =  Ambiguate( unit, "none" )
	local powerIndex, powerString, altR, altG, altB = UnitPowerType( unit )
	if powerString ~= nil and powerString ~= "" then
		local r = PowerBarColor[powerString].r
		local g = PowerBarColor[powerString].g
		local b = PowerBarColor[powerString].b
		statusBar:SetStatusBarColor( r, g, b, 1 )
		statusBar.backgroundTexture:SetTexture( r, g, b, 0.25 )
	end
end		

-------------------------------------------------------------------------------------------------------------
-- Combo Points Status Bar Updates.
-------------------------------------------------------------------------------------------------------------

function AJM:UNIT_COMBO_POINTS( event, ... )
	--AJM:Print("hello")
	--AJM:SendComboStatusUpdateCommand()	
end

function AJM:UNIT_POWER_FREQUENT( event, Unit, powerType, ... )
	--TODO there got to be a better way to clean this code up Checking to see if its the event we need and then send the command to the update if it is.	
	--AJM:Print("EventTest", Unit, powerType) 
	if Unit == "player" then
		--AJM:Print("player", Unit, powerType)
		if( event and powerType == "BURNING_EMBERS" ) then
			AJM:SendComboStatusUpdateCommand()
		elseif( event and powerType == "COMBO_POINTS" ) then
			AJM:SendComboStatusUpdateCommand()
		--TODO Remove in legion.
		elseif( event and powerType == "DEMONIC_FURY" ) then
			AJM:SendComboStatusUpdateCommand()
		elseif( event and powerType == "SOUL_SHARDS" ) then
			AJM:SendComboStatusUpdateCommand()
		elseif( event and powerType == "HOLY_POWER" ) then
			AJM:SendComboStatusUpdateCommand()		
		else
			return
		end
	end	
end

function AJM:PLAYER_TALENT_UPDATE(event, ...)
	AJM:SendComboStatusUpdateCommand()	
end

--function AJM:UNIT_DISPLAYCOMBO( event, unit, ... )
--	AJM:SendComboStatusUpdateCommand( unit )
--end

function AJM:SendComboStatusUpdateCommand()
	--AJM:Print("test")
	if AJM.db.showTeamList == true and AJM.db.showComboStatus == true then
		--if select(2, UnitClass("player")) ~= "DRUID" or and select(2, UnitClass("player")) ~= "WARLOCK" select(2, UnitClass("player")) ~= "ROGUE" == true then
		--	return
		--end	
		-- get powerType from http://wowprogramming.com/docs/api_types#powerType as there no real API to get this infomation as of yet.
		local Class = select(2, UnitClass("player"))
		--AJM:Print("class", Class)
		-- ComboPoints
		if Class == "DRUID" then
			PowerType = 4
		-- Combo Points
		elseif Class == "ROGUE" then
			PowerType = 4
		-- Warlock Destrunction burningEmbers TODO Other Warlock Specs
		elseif Class == "WARLOCK" then
			local Spec = GetSpecialization()
			--Destrunction
			if Spec == 3 then
				PowerType = 14
			--Demo Nolonger in legion so TODO Remove!
			elseif Spec == 2 then
				PowerType = 15
			--SOUL SHARDS default warlock spell
			else 
				PowerType = 7
			end
		-- Paladin Holy Power
		elseif Class == "PALADIN" then
			PowerType = 9
		else 
			return
		end
			
		local playerCombo = UnitPower ( "player", PowerType)
		local playerMaxCombo = UnitPowerMax( "player", PowerType)
		
		--AJM:Print ("PowerType", PowerType, playerCombo, playerMaxCombo)
		--AJM:Print("send")
		if AJM.db.showTeamListOnMasterOnly == true then
			AJM:DebugMessage( "SendComboStatusUpdateCommand TO Master!" )
			AJM:JambaSendCommandToMaster( AJM.COMMAND_COMBO_STATUS_UPDATE, playerCombo, playerMaxCombo )
		else
			AJM:DebugMessage( "SendComboStatusUpdateCommand TO TEAM!" )
			AJM:JambaSendCommandToTeam( AJM.COMMAND_COMBO_STATUS_UPDATE, playerCombo, playerMaxCombo )
		end
	end	
end

function AJM:ProcessUpdateComboStatusMessage( characterName, playerCombo, playerMaxCombo, range )
	AJM:UpdateComboStatus( characterName, playerCombo , playerMaxCombo, range )
end

function AJM:SettingsUpdateComboAll()
	for characterName, characterStatusBar in pairs( AJM.characterStatusBar ) do			
		AJM:UpdateComboStatus( characterName, nil, nil, nil )
	end
end

function AJM:UpdateComboStatus( characterName, playerCombo, playerMaxCombo, range )
	if CanDisplayTeamList() == false then
		return
	end
	
	if AJM.db.showComboStatus == false then
		return
	end
	
	local characterStatusBar = AJM.characterStatusBar[characterName]
	if characterStatusBar == nil then
		return
	end
	
	local comboBarText = characterStatusBar["comboBarText"]	
	local comboBar = characterStatusBar["comboBar"]	
	
	if playerCombo == nil then
		playerCombo = comboBarText.playerCombo
	end
	
	if playerMaxCombo == nil then
		playerMaxCombo = comboBarText.playerMaxCombo
	end
	
	comboBarText.playerCombo = playerCombo
	comboBarText.playerMaxCombo = playerMaxCombo
	comboBar:SetMinMaxValues( 0, tonumber( playerMaxCombo ) )
	comboBar:SetValue( tonumber( playerCombo ) )
	if 	UnitInParty(Ambiguate( characterName, "none" ) ) == true then
		if range == false then
			comboBar:SetAlpha( 0.5 )
		else
			comboBar:SetAlpha( 1 )
		end
	else
		comboBar:SetAlpha( 1 )
	end	
	local text = ""
	
	if AJM.db.comboStatusShowValues == true then
		text = text..tostring( playerCombo )..L[" / "]..tostring( playerMaxCombo )..L[" "]
	end
	
	if AJM.db.ComboStatusShowPercentage == true then
		if AJM.db.comboStatusShowValues == true then
			text = text..L["("]..tostring( floor( (playerCombo/playerMaxCombo)*100) )..L["%"]..L[")"]
		else
			text = tostring( floor( (playerCombo/playerMaxCombo)*100) )..L["%"]
		end
	end
	comboBarText:SetText( text )
	AJM:SetStatusBarColourForCombo( comboBar )	
end


function AJM:SetStatusBarColourForCombo( comboBar )
	local Class = select(2, UnitClass("player"))
	if Class == "WARLOCK" then
		local Spec = GetSpecialization()
			if Spec == 3 then
				--Orange
				comboBar:SetStatusBarColor( 1.00, 0.50, 0.25, 1 )
				comboBar.backgroundTexture:SetTexture ( 1.00, 0.50, 0.25, 0.25 )
			else
				-- Purple
				comboBar:SetStatusBarColor( 0.58, 0.51, 0.79, 1 )
				comboBar.backgroundTexture:SetTexture( 0.58, 0.51, 0.79, 0.25) 	
			end
	elseif  Class == "PALADIN" then
			comboBar:SetStatusBarColor( 0.96, 0.55, 0.73, 1 )
			comboBar.backgroundTexture:SetTexture( 0.96, 0.55, 0.73, 0.25) 	
	else
		return
	end	
end	

		
-------------------------------------------------------------------------------------------------------------
-- Addon initialization, enabling and disabling.
-------------------------------------------------------------------------------------------------------------

-- Initialise the module.
function AJM:OnInitialize()
	AJM.previousSlotsFree = 0
	AJM.previousTotalSlots = 0
	-- Create the settings control.
	SettingsCreate()
	-- Initialise the JambaModule part of this module.
	AJM:JambaModuleInitialize( AJM.settingsControl.widgetSettings.frame )
	-- Populate the settings.
	AJM:SettingsRefresh()
	-- Create the team list frame.
	CreateJambaTeamListFrame()
	AJM:SetTeamListVisibility()	
end

-- Called when the addon is enabled.
function AJM:OnEnable()
	AJM:RegisterEvent( "PLAYER_REGEN_ENABLED" )
	AJM:RegisterEvent( "PLAYER_REGEN_DISABLED" )
	AJM:RegisterEvent( "AUTOFOLLOW_BEGIN" )
	AJM:RegisterEvent( "AUTOFOLLOW_END" )
	AJM:RegisterEvent( "PLAYER_XP_UPDATE" )
	AJM:RegisterEvent( "UPDATE_EXHAUSTION" )
	AJM:RegisterEvent( "PLAYER_LEVEL_UP" )		
	AJM:RegisterEvent( "UNIT_HEALTH" )
	AJM:RegisterEvent( "UNIT_MAXHEALTH" )
	AJM:RegisterEvent( "UNIT_POWER", "UNIT_POWER" )
	AJM:RegisterEvent( "UNIT_MAXPOWER", "UNIT_POWER" )
	--AJM:RegisterEvent( "PLAYER_EQUIPMENT_CHANGED" )
	AJM:RegisterEvent( "PLAYER_ENTERING_WORLD")
	AJM:RegisterEvent( "UNIT_DISPLAYPOWER" )
	--AJM:RegisterEvent( "UNIT_LEVEL" )
	--AJM:RegisterEvent( "ITEMLVL_PUSH" )
--	AJM:RegisterEvent( "GROUP_ROSTER_UPDATE" )
--	AJM:RegisterEvent( "ITEM_PUSH" )
	AJM:RegisterEvent( "CHAT_MSG_COMBAT_FACTION_CHANGE" )
	AJM:RegisterEvent( "UNIT_COMBO_POINTS" )
	AJM:RegisterEvent( "UNIT_POWER_FREQUENT")
	AJM:RegisterEvent( "PLAYER_TALENT_UPDATE")
	--Updating Bag information -- Chaneged again 4.1  this event fires even for bank bags. When moving an item in your inventory, this fires multiple times: once each for the source and destination bag
--	AJM:RegisterEvent( "BAG_UPDATE", "ITEM_PUSH" )
	--Updates everytime jamba Reads the UI_ERROR_MESSAGE Are This is not very good for me using a spambar! Need's a better system.
	--AJM:RegisterEvent( "UI_ERROR_MESSAGE", "ITEM_PUSH" )
    --TODO: Clean up code
	--AJM:RegisterEvent( "UNIT_PORTRAIT_UPDATE" )
	AJM.SharedMedia.RegisterCallback( AJM, "LibSharedMedia_Registered" )
    AJM.SharedMedia.RegisterCallback( AJM, "LibSharedMedia_SetGlobal" )	
	AJM:RegisterMessage( JambaApi.MESSAGE_TEAM_CHARACTER_ADDED, "OnCharactersChanged" )
	AJM:RegisterMessage( JambaApi.MESSAGE_TEAM_CHARACTER_REMOVED, "OnCharactersChanged" )	
	AJM:RegisterMessage( JambaApi.MESSAGE_TEAM_ORDER_CHANGED, "OnCharactersChanged" )
	AJM:RegisterMessage( JambaApi.MESSAGE_TEAM_MASTER_CHANGED, "OnMasterChanged" )
	AJM:RegisterMessage( JambaApi.MESSAGE_CHARACTER_ONLINE, "OnCharactersChanged")
	AJM:RegisterMessage( JambaApi.MESSAGE_CHARACTER_OFFLINE, "OnCharactersChanged")
	AJM:SecureHook( "SetWatchedFactionIndex" )
	AJM:ScheduleTimer( "RefreshTeamListControls", 20 )
	AJM:ScheduleTimer( "SendExperienceStatusUpdateCommand", 5 )
	AJM:ScheduleTimer( "SendReputationStatusUpdateCommand", 5 )
--	AJM:ScheduleTimer( "SendBagInformationUpdateCommand", 5 )
	AJM:ScheduleTimer( "SendIlvlInformationUpdateCommand", 5 )
	--AJM:timerCount = ( 0 )
    --AJM:testTimer = 
	--self.timerCount = 0
	AJM:ScheduleRepeatingTimer("RangeUpdateCommand", 5)
end

-- Called when the addon is disabled.
function AJM:OnDisable()
end

function AJM:PLAYER_ENTERING_WORLD( event, ... )
	AJM:SendComboStatusUpdateCommand()
end

function AJM:OnMasterChanged( message, characterName )
	AJM:SettingsRefresh()
end
--[[
function AJM:UNIT_LEVEL( event, ... )
	--AJM:SettingsUpdateFollowTextAll()
	AJM:SendIlvlInformationUpdateCommand()
end]]


function AJM:PLAYER_REGEN_ENABLED( event, ... )
	if AJM.db.hideTeamListInCombat == true then
		AJM:SetTeamListVisibility()
	end
	if AJM.refreshHideTeamListControlsPending == true then
		AJM:RefreshTeamListControlsHide()
		AJM.refreshHideTeamListControlsPending = false
	end
	if AJM.refreshShowTeamListControlsPending == true then
		AJM:RefreshTeamListControlsShow()
		AJM.refreshShowTeamListControlsPending = false
	end
	if AJM.updateSettingsAfterCombat == true then
		AJM:SettingsRefresh()
		AJM.updateSettingsAfterCombat = false
	end 
end

function AJM:PLAYER_REGEN_DISABLED( event, ... )
	if AJM.db.hideTeamListInCombat == true then
		JambaDisplayTeamListFrame:Hide()
	end
end

function AJM:OnCharactersChanged()
	AJM:RefreshTeamListControls()
	--AJM:SendIlvlInformationUpdateCommand()
end


