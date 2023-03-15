--[[
ReaScript name: Insert take marker with current timestamp at edit;mouse cursor in selected items;takes
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058
Version: 1.0
Changelog: Initial release
About:
Licence: WTFPL
REAPER: at least v5.962
]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------
-- Timestamp formats:
-- 1 = dd.mm.yyyy - hh:mm:ss
-- 2 = dd.mm.yy - hh:mm:ss
-- 3 = dd.mm.yyyy - H:mm:ss AM/PM
-- 4 = dd.mm.yy - H:mm:ss AM/PM
-- 5 = mm.dd.yyyy - hh:mm:ss
-- 6 = mm.dd.yy - hh:mm:ss
-- 7 = mm.dd.yyyy - H:mm:ss
-- 8 = mm.dd.yy - H:mm:ss AM/PM
-- 9 = current system locale

local TIME_FORMAT = 1		-- number of timestamp format from the above list
local HEX_COLOR = "#000"	-- in HEX format, 6 or 3 digits, defaults to black if format is incorrect
local POS_POINTER = 1 		-- 1 - Edit cursor, any other number - Mouse cursor

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------

function Msg(param)
reaper.ShowConsoleMsg(tostring(param)..'\n')
end

local r = reaper

local sel_item_cnt = r.CountSelectedMediaItems(0)

	if sel_item_cnt == 0 then r.MB('No selected items/takes.','ERROR',0) r.defer(function() end) return end

local err1 = (not TIME_FORMAT or type(TIME_FORMAT) ~= 'number' or TIME_FORMAT < 1 or TIME_FORMAT > 9) and '       Incorrect timestamp format.\n\nMust be a number between 1 and 9.'
local err2 = not POS_POINTER or type(POS_POINTER) ~= 'number' and 'Incorrect position pointer format.\n\n\tMust be a number.'
local err = err1 or err2

	if err then r.MB(err,'USER SETTINGS error',0) r.defer(function() end) return end

local t = {
'%d.%m.%Y - %H:%M:%S', -- 1
'%d.%m.%y - %H:%M:%S', -- 2
'%d.%m.%Y - %I:%M:%S', -- 3
'%d.%m.%y - %I:%M:%S', -- 4
'%m.%d.%Y - %H:%M:%S', -- 5
'%m.%d.%y - %H:%M:%S', -- 6
'%m.%d.%Y - %I:%M:%S', -- 7
'%m.%d.%y - %I:%M:%S', -- 8
'%x - %X'	       -- 9
}

os.setlocale('', 'time')

local store_curs_pos = r.GetCursorPosition() -- if mouse cursor is enabled as pointer

r.PreventUIRefresh(1)

local move_curs = POS_POINTER ~= 1 and r.Main_OnCommand(40514,0) -- View: Move edit cursor to mouse cursor (no snapping)
local cur_pos = r.GetCursorPosition()

local daytime = tonumber(os.date('%H')) < 12 and ' AM' or ' PM' -- for 3,4,7,8 using 12 hour cycle
local daytime = (TIME_FORMAT == 3 or TIME_FORMAT == 4 or TIME_FORMAT == 7 or TIME_FORMAT == 8) and daytime or ''
local timestamp = os.date(t[TIME_FORMAT])..daytime

function hex2rgb(HEX_COLOR)
-- https://gist.github.com/jasonbradley/4357406
    hex = HEX_COLOR:sub(2)
    return tonumber('0x'..hex:sub(1,2)), tonumber('0x'..hex:sub(3,4)), tonumber('0x'..hex:sub(5,6))
end

local HEX_COLOR = type(HEX_COLOR) == 'string' and HEX_COLOR:gsub('%s','') -- remove empty spaces just in case
-- default to black if color is improperly formatted
local HEX_COLOR = (not HEX_COLOR or type(HEX_COLOR) ~= 'string' or HEX_COLOR == '' or #HEX_COLOR < 4 or #HEX_COLOR > 7) and '#000' or HEX_COLOR
-- extend shortened (3 digit) hex color code, duplicate each digit
local HEX_COLOR = #HEX_COLOR == 4 and HEX_COLOR:gsub('%w','%0%0') or HEX_COLOR
local R,G,B = hex2rgb(HEX_COLOR) -- R because r is already taken by reaper, the rest is for consistency

r.Undo_BeginBlock()

	for i = 0, sel_item_cnt-1 do
	local item = r.GetSelectedMediaItem(0,i)
	local take = r.GetActiveTake(item)
		if take then
		local item_pos = r.GetMediaItemInfo_Value(item, 'D_POSITION')
		local offset = r.GetMediaItemTakeInfo_Value(take, 'D_STARTOFFS')
		local playrate = r.GetMediaItemTakeInfo_Value(take, 'D_PLAYRATE')
		local mark_pos = (cur_pos - item_pos + offset)*playrate
		r.SetTakeMarker(take, -1, timestamp, mark_pos, r.ColorToNative(R,G,B)|0x1000000)
		end
	end

r.Undo_EndBlock('Insert take marker(s) time stamped to '..timestamp,-1)

local restore_edit_curs_pos = POS_POINTER ~= 1 and r.SetEditCurPos(store_curs_pos, false, false) -- if mouse cursor is enabled as pointer

r.PreventUIRefresh(-1)



