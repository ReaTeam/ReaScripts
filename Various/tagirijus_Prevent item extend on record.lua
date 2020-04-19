-- @description Prevent item extend on record
-- @author Tagirijus
-- @version 1.1
-- @changelog Selected items won't be shortened now.
-- @about
--   # Description
--
--   This is a Reaper script which prevents the item extending on record, when it's not selected.
--
--
--   # Problem
--
--   In my workflow I like to place the play cursor one measure in front of the passage I want to record to have a pre-count. The Reaper pre-count is not able to record an upbeat, AFAIK. And when the cursors is on an media item an record starts ("MIDI overdub" + "Tape Mode" active), the media item will be extended. I want to have a new media item after such a recording situation, though.
--
--
--   # Solution
--
--   This script looks which tracks are selected (I am using "Auto arm on select") and looks which media items are underneath the play cursors. Then the script shortens these media items to the cursor, if these items are not selected. Recording will start. After recording the script restores the lengths of the media items. Now there are the "old" media items basically untouched and the new recorded ones separately.

--[[
 * ReaScript Name: tagirijus_Prevent item extend on record.lua
 * Author: Manuel Senfft (Tagirijus)
 * Licence: MIT
 * REAPER: 6.08
 * Extensions: None
 * Version: 1.1
--]]


local scriptTitle = 'Tagirijus: Prevent item extend on record'
local selectedTrackCount = reaper.CountSelectedTracks(0)
local firstStart = false
local itemHeal = {}



--===== SOME FUNCTIONS =====--

function ShortenItemsUnderCursor(playCursorPosition)

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

            local itemSelected = reaper.IsMediaItemSelected(item)

            if itemStartsBeforeCursor and itemReachesIntoCursor and not itemSelected then

                -- store the original length for later "healing"
                itemHeal[reaper.BR_GetMediaItemGUID(item)] = itemLength

                -- shorten the item here
                local newLength = playCursorPosition - itemPosition
                reaper.SetMediaItemInfo_Value(item, 'D_LENGTH', newLength)

            end

        end

    end

end

function HealItemsLengths()
    for itemGUID, itemLength in pairs(itemHeal) do
        local item = reaper.BR_GetMediaItemByGUID(0, itemGUID)
        reaper.SetMediaItemInfo_Value(item, 'D_LENGTH', itemLength)
    end
end




--===== RECORDING STATES =====--

function OnStartRecording()
    -- apparently the undo block will not work in defer scripts
    -- reaper.Undo_BeginBlock()
    ShortenItemsUnderCursor(reaper.GetCursorPosition())
end

function OnRecord()
    -- for future features
end

function OnStopRecording()
    HealItemsLengths()
    -- apparently the undo block will not work in defer scripts
    -- reaper.Undo_EndBlock(scriptTitle, -1)
end




--===== MAIN =====--
local lastPlayState = -1
function main()
    local playState =   reaper.GetPlayStateEx(0)
    if lastPlayState == 5 and playState ~= lastPlayState then
        OnStopRecording()
    else
        lastPlayState = playState
        OnRecord()
        reaper.defer(main)
    end
end

---------
OnStartRecording()
reaper.Main_OnCommand(1013, -1) --start recording
main()
