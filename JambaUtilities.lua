--[[
Jamba - Jafula's Awesome Multi-Boxer Assistant
Copyright 2008 - 2016 Michael "Jafula" Miller
License: The MIT License
]]--

-- Localization debugging.
--GAME_LOCALE = "frFR"

local MAJOR, MINOR = "JambaUtilities-1.0", 1
local JambaUtilities, oldMinor = LibStub:NewLibrary( MAJOR, MINOR )

if not JambaUtilities then 
	return 
end

-- Code modified from http://lua-users.org/wiki/CopyTable
function JambaUtilities:CopyTable(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for index, value in pairs(object) do
            new_table[_copy(index)] = _copy(value)
        end
        return setmetatable(new_table, getmetatable(object))
    end
    return _copy(object)
end

function JambaUtilities:ClearTable( object )
	for key in next, object do
		if type( object[key] ) == "table" then
			JambaUtilities:ClearTable( object[key] )
		end
		object[key] = nil
	end
end

function JambaUtilities:Lowercase( name )
	return string.utf8lower( name )
end
--[[
function JambaUtilities:AddRealmToNameIfMissing( name )
	--local fullName = name
	Fullname = name:gsub("^%l", string.upper)
	local matchDash = Fullname:find( "-" )
	if not matchDash then
		local realmName = GetRealmName()
		Fullname = Fullname.."-"..realmName
		end
	return Fullname
end
--]]

--AddRealmToNameIfMissing Blizzard Code does not like spaces in the realm name GetRealmName() pulls back the name with a Space Unwanted for most of the stuff we need to do.
function JambaUtilities:AddRealmToNameIfMissing( name )
	Name = name:gsub("^%l", string.upper )
	fullName = Name:gsub( "%s+", "")
	local matchDash = fullName:find( "-" )
	if not matchDash then
		local k = GetRealmName()
		local realm = k:gsub( "%s+", "")
		fullName = fullName.."-"..realm
		end
	return fullName
end



--if not string.find(name, "-") then
--	local _, realm = UnitFullName("player")
--	name = name.."-"..realm
--end

-- Capitalise the name.	
function JambaUtilities:Capitalise( name )
    return string.utf8upper( string.utf8sub( name, 1, 1 ) )..string.utf8lower( string.utf8sub( name, 2 ) )
end

function JambaUtilities:AddRealmToNameIfNotNil( name, realm )
	local fullName = name
	if realm ~= nil and realm:trim() ~= "" then
		fullName = name.."-"..realm
	end
	return fullName
end

-- Money constants.
JambaUtilities.COLOUR_COPPER = "eda55f"
JambaUtilities.COLOUR_SILVER = "c7c7cf"
JambaUtilities.COLOUR_GOLD = "ffd700"
JambaUtilities.COPPER_PER_SILVER = 100;
JambaUtilities.SILVER_PER_GOLD = 100;
JambaUtilities.COPPER_PER_GOLD = JambaUtilities.COPPER_PER_SILVER * JambaUtilities.SILVER_PER_GOLD;

-- value - the amount of money to display formatted.
-- Creates a money string from the value passed; don't pass negative values!
function JambaUtilities:FormatMoneyString( value )
	local gold = floor( value / ( JambaUtilities.COPPER_PER_SILVER * JambaUtilities.SILVER_PER_GOLD ) );
	local silver = floor( ( value - ( gold * JambaUtilities.COPPER_PER_SILVER * JambaUtilities.SILVER_PER_GOLD ) ) / JambaUtilities.COPPER_PER_SILVER );
	local copper = mod( value, JambaUtilities.COPPER_PER_SILVER );
	local goldFormat = format( "|cff%s%d|r", JambaUtilities.COLOUR_GOLD, gold )	
	local silverFormat = format( "|cff%s%02d|r", JambaUtilities.COLOUR_SILVER, silver )
	local copperFormat = format( "|cff%s%02d|r", JambaUtilities.COLOUR_COPPER, copper )
	if gold <=0 then
		goldFormat = ""
		if silver <= 0 then
			silverFormat = ""
		end
	end
	return strtrim(goldFormat.." "..silverFormat.." "..copperFormat)	
end

-- itemLink - the item link to extract an item id from.
-- Gets an item id from an item link.  Returns nil, if an item id could not be found.
function JambaUtilities:GetItemIdFromItemLink( itemLink )
	local itemIdFound = nil 
	local itemStringStart, itemStringEnd, itemString = itemLink:find( "^|c%x+|H(.+)|h%[.*%]" )
	if itemStringStart then
		local matchStart, matchEnd, itemId = itemString:find( "(item:%d+)" )
		if matchStart then
			itemIdFound = itemId	
		end
	end
	return itemIdFound	
end

-- itemLink1 - the first item link to compare.
-- itemLink2 - the second item link to compare.
-- Compares two itemlinks to see if they both refer to the same item.  Return true if they do, false if they don't.
function JambaUtilities:DoItemLinksContainTheSameItem( itemLink1, itemLink2 )
	local theSame = false
	local itemId1 = JambaUtilities:GetItemIdFromItemLink( itemLink1 )
	local itemId2 = JambaUtilities:GetItemIdFromItemLink( itemLink2 )
	if itemId1 ~= nil and itemId2 ~= nil then
		if itemId1 == itemId2 then
			theSame = true
		end
	end
	return theSame	
end

-- state - string value containing "on" or "off".
-- onCommand - string that is equivalent to true, like "on".
-- offCommand - string that is equivalent to false, like "off".
-- Returns true for "on"; false for "off"; nil for invalid.
function JambaUtilities:GetOnOrOffFromCommand( state, onCommand, offCommand )
	local setToOn = nil
	state = state:lower():trim()
	if state == onCommand then
		setToOn = true
	end
	if state == offCommand then
		setToOn = false
	end
	return setToOn
end

-- Check for a buff.
function JambaUtilities:DoesThisCharacterHaveBuff( buffName )
	local hasBuff = false
	local iterateBuffs = 1
	local buff = UnitBuff( "player", iterateBuffs )
	while buff ~= nil do
		if buff == buffName then
			hasBuff = true
			break
		end
		iterateBuffs = iterateBuffs + 1
		buff = UnitBuff( "player", iterateBuffs )
	end
	return hasBuff
end

function JambaUtilities:FixValueToRange( value, minValue, maxValue )
	if value < minValue then
		value = minValue
	end		
	if value > maxValue then
		value = maxValue
	end	
	return value
end


		
	
	
	
	
	
	
	
	
	
	
	
	