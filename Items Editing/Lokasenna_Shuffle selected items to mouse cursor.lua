--[[
Description: Shuffle selected items to mouse cursor
Version: 1.01
Author: Lokasenna
Donation: https://paypal.me/Lokasenna
Changelog:
    Bug fix
Links:
	Lokasenna's Website http://forum.cockos.com/member.php?u=10417
About: 
    Emulates the "shuffle edit" mode from Pro Tools - the selected item
    is moved to the mouse cursor and other items are pushed left/right to
    make room.
    
    Adapted from code by spk77. Cheers.
--]]

-- Licensed under the GNU GPL v3


local function Msg(str)
    reaper.ShowConsoleMsg(tostring(str).."\n")
end


if not reaper.BR_PositionAtMouseCursor then
    reaper.MB("This script requires the SWS extension.", "Whoops!", 0)
    return
end

local mouse = reaper.BR_PositionAtMouseCursor( true )
if mouse < 0 then
    reaper.MB("The mouse isn't within the arrange area.", "Whoops!", 0)
    return
end


local function get_pos(item)
    
    local p = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local l = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")

    return p, l, p + l
    
end

local num_items = reaper.CountSelectedMediaItems(0)
if num_items == 0 then return end

-- Need this to see which direction we're shuffling in
local sel_item = reaper.GetSelectedMediaItem(0,0)
local sel_pos, sel_len, sel_end = get_pos(sel_item)

local dir =     (sel_pos > mouse) and -1
            or  (sel_pos < mouse) and 1
if not dir then return end



reaper.Undo_BeginBlock()

local a, b, inc = 0, num_items - 1, 1
for i = a, b, inc do

    sel_item = reaper.GetSelectedMediaItem(0,dir == 1 and 0 or num_items - 1)
    if not sel_item then return end
    local track = reaper.GetMediaItem_Track(sel_item)
    if not track then return end

    --Msg("shuffling item " .. reaper.ULT_GetMediaItemNote( sel_item ) .. ", track " ..
        --math.floor(reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")) .. "\n")

    sel_pos, sel_len, sel_end = get_pos(sel_item)

    while true do
        
        -- Compare mouse with item to see dir and/or break the loop
        if sel_pos <= mouse and mouse <= sel_end then 

            --Msg("\titem at pos " .. 
            --    math.floor(reaper.GetMediaItemInfo_Value(sel_item, "IP_ITEMNUMBER") + 1) ..
            --    "\tbreaking\n")

            break 
        end

        -- Get next item
        local idx = reaper.GetMediaItemInfo_Value(sel_item, "IP_ITEMNUMBER")
        
        --Msg("\titem at pos " .. math.floor(idx + 1) .. "\tmoving")
        
        local next_item = reaper.GetTrackMediaItem(track, idx + dir)
        if not next_item then break end
        local next_pos, next_len, next_end = get_pos(next_item)
        
        -- Shuffle according to dir
        reaper.SetMediaItemInfo_Value(next_item, "D_POSITION", dir == 1 and sel_pos
                                                                        or  sel_end - next_len)
        reaper.SetMediaItemInfo_Value(sel_item, "D_POSITION",  dir == 1 and next_pos
                                                                        or  next_end - sel_len)

        sel_pos, sel_len, sel_end = get_pos(sel_item)

    end

end

reaper.Undo_EndBlock("Lokasenna_Shuffle selected items to mouse cursor", 4)