-- @description Prevent item extend on record
-- @author Tagirijus
-- @version 1.0
-- @link Website https://www.tagirijus.de
-- @about
--   # Description
--
--   This is a Reaper script which prevents the item extending on record.
--
--
--   # Problem
--
--   In my workflow I like to place the play cursor one measure in front of the passage I want to record to have a pre-count. The Reaper pre-count is not able to record an upbeat, AFAIK. And when the cursors is on an media item an record starts (MIDI overdub + Tape Mode active), the media item will be extended. I want to have a new media item after such a recording situation, though.
--
--
--   # Solution
--
--   This script looks which tracks are selected (I am using "Auto arm on select") and looks which media items are underneath the play cursors. Then the script shortens these media items to the cursor. Recording will start. After recording the script restores the lengths of the media items. Now there are the "old" media items basically untouched and the new recorded ones separately.

--[[
 * ReaScript Name: tagirijus_Prevent item extend on record.lua
 * Author: Manuel Senfft (Tagirijus)
 * Licence: MIT
 * REAPER: 6.05
 * Extensions: None
 * Version: 1.0
--]]


local scriptTitle = 'Tagirijus: Prevent item extend on record'
local itemHeal = {}


function main()

    -- check for selected tracks
	local selectedTrackCount = reaper.CountSelectedTracks(0)
	if selectedTrackCount == 0 then
        reaper.ShowMessageBox('No tracks selected', scriptTitle, 0)
		return
    end

    -- record!
    reaper.PreventUIRefresh(1)
    reaper.Undo_BeginBlock()

    shortenItemsUnderCursor(selectedTrackCount, reaper.GetCursorPosition())

    reaper.CSurf_OnRecord()

    healItemsLengths()

    reaper.Undo_EndBlock(scriptTitle, -1)
    reaper.PreventUIRefresh(-1)

end


function shortenItemsUnderCursor(selectedTrackCount, playCursorPosition)

    -- iter through the selected tracks to find their items under the play cursor
    for i = 0, selectedTrackCount - 1 do

        local track = reaper.GetSelectedTrack(0, i)


        -- iter through all items in the track to find the correct item/s under the play cursor
        local itemCount = reaper.CountTrackMediaItems(track)

        for ii = 0, itemCount - 1 do

            local item = reaper.GetTrackMediaItem(track, ii)
            local itemPosition = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
            local itemLength = reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')

            local itemStartsBeforeCursor = itemPosition <= playCursorPosition
            local itemReachesIntoCursor = itemPosition + itemLength > playCursorPosition

            if itemStartsBeforeCursor and itemReachesIntoCursor then

                -- store the original length for later "healing"
                itemHeal[reaper.BR_GetMediaItemGUID(item)] = itemLength

                -- shorten the item here
                local newLength = playCursorPosition - itemPosition
                reaper.SetMediaItemInfo_Value(item, 'D_LENGTH', newLength)

            end

        end

    end

end


function healItemsLengths()
    for itemGUID, itemLength in pairs(itemHeal) do
        local item = reaper.BR_GetMediaItemByGUID(0, itemGUID)
        reaper.SetMediaItemInfo_Value(item, 'D_LENGTH', itemLength)
    end
end


main()
