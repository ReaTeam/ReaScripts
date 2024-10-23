-- @description Toggle loop source on item under cursor in selected track
-- @author Tagirijus
-- @version 1.0
-- @about
--   # Description
--
--   This is a Reaper script which toggles "loop source" for the item in the selected track and under the edit cursor uniformly. It also will de-select the items, which have loop source enabled and enable selection on items which will have it disabled.

--[[
 * ReaScript Name: tagirijus_Toggle loop source on item under cursor in selected track.lua
 * Author: Manuel Senfft (Tagirijus)
 * Licence: MIT
 * REAPER: 6.08
 * Extensions: None
 * Version: 1.0
--]]


local scriptTitle = 'Tagirijus: Toggle loop source on item under cursor in selected track'
local selectedTrackCount = reaper.CountSelectedTracks(0)

-- This variable is for making all selected items equally have "loop source" enabled or disabled.
-- The reason: maybe multiple tracks are selected with multiple items. In that case some items may
-- have "loop source" enabled or not. For my workflow, I like to have the tracks (with their items)
-- equally set up before recording. Means: either I want multiple tracks at once and their items
-- to be extended ("loop source" disabled) or a new item created after the item, on which the cursor
-- is on record start ("loop source" enabled).
-- With this variable the first loop of iter through the items will define (depending on the FIRST item)
-- wether the script should disabled or enabled "loop source" for all items. If the first item has it
-- enabled, it will be disabled an also be disabled for all other items, regardless of their actual
-- state. That's why I have it set to "2", means "first loop". After that it will be set to "0", if
-- "loop source" should be disabled or "1" if enabled.
local toggleIt = 2



--===== SOME FUNCTIONS =====--

function ToggleLoopSourceForItemsUnderCursor(playCursorPosition)

    -- due to the "loop source" indication by selecting or deselecting items, first all
    -- items have to be deselected.
    reaper.SelectAllMediaItems(-1, 0)

    -- iter through the selected tracks to find their items under the play cursor
    for i = 0, selectedTrackCount - 1 do

        local track = reaper.GetSelectedTrack(0, i)


        -- iter through all items in the track to find the correct item/s under the play cursor
        local itemCount = reaper.CountTrackMediaItems(track)

        for ii = 0, itemCount - 1 do

            -- get the item first
            local item = reaper.GetTrackMediaItem(track, ii)

            -- now get the items position and length
            local itemPosition = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
            local itemLength = reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')

            -- and check if it's under the cursor
            local itemStartsBeforeCursor = itemPosition <= playCursorPosition
            local itemReachesIntoCursor = itemPosition + itemLength > playCursorPosition
            if itemStartsBeforeCursor and itemReachesIntoCursor then

                -- if it's the first loop, check the first items state and alter the "toggleIt" variable
                if toggleIt == 2 then
                    -- this is basically a ternary operator like    toggleIt = if CONDITION then VALUE ON TRUE else VALUE ON FALSE end
                    --                              but like so:    toggleIt = CONDITION (true) and TRUE or FALSE
                    toggleIt = reaper.GetMediaItemInfo_Value(item, 'B_LOOPSRC') == 1 and 0 or 1
                end

                -- loop source the item
                reaper.SetMediaItemInfo_Value(item, 'B_LOOPSRC', toggleIt)

                -- select it, if "loop source" is disabled now
                reaper.SetMediaItemSelected(item, 1 - toggleIt)
                reaper.UpdateArrange()

            end

        end

    end

end




--===== MAIN =====--
function main()
    reaper.Undo_BeginBlock()
    ToggleLoopSourceForItemsUnderCursor(reaper.GetCursorPosition())
    reaper.Undo_EndBlock(scriptTitle, -1)
end

---------
main()
