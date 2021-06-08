-- @description Prevent item extend on record
-- @author Tagirijus
-- @version 1.4
-- @changelog I added a compensation for the playback time offset. So now e.g. for a string library it is possible to have some negative time offset so that for quantized notes the strings will be in time, even if they have a slightly slower attack or so. My recording script now understand this playback time offset and compensates recorded MIDI data (which probably will be in sync with the beat during record but not after that anymore, if the time offset exists for the track!).
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
 * REAPER: 6.20
 * Extensions: None
 * Version: 1.4
--]]


local scriptTitle = 'Tagirijus: Prevent item extend on record'
local selectedTrackCount = reaper.CountSelectedTracks(0)
local itemHealLength = {}
local itemHealMute = {}
local itemHealPosition = {}
local existingItems = {}



--===== SOME FUNCTIONS =====--

function debugMsg(msg)
    reaper.ShowMessageBox(tostring(msg), 'DEBUG MSG', 0)
end

function keyExists(array, key)
    return array[key] ~= nil
end

function GetExistingItems()
    for i = 0, reaper.CountMediaItems(0) - 1 do
        item = reaper.GetMediaItem(0, i)
        existingItems[reaper.BR_GetMediaItemGUID(item)] = item
    end
end

function ShortenAndMuteItemsUnderCursor(playCursorPosition)

    -- iter through the selected tracks to find their items under the play cursor
    for i = 0, selectedTrackCount - 1 do

        local track = reaper.GetSelectedTrack(0, i)


        -- iter through all items in the track to find the correct item/s under the play cursor
        local itemCount = reaper.CountTrackMediaItems(track)

        for ii = 0, itemCount - 1 do

            local item = reaper.GetTrackMediaItem(track, ii)
            local itemPosition = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
            local itemLength = reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')
            local itemMute = reaper.GetMediaItemInfo_Value(item, 'B_MUTE')

            local itemStartsBeforeCursor = itemPosition <= playCursorPosition
            local itemStartsOnCursor = itemPosition == playCursorPosition
            local itemReachesIntoCursor = itemPosition + itemLength > playCursorPosition

            local itemSelected = reaper.IsMediaItemSelected(item)

            if itemStartsBeforeCursor and itemReachesIntoCursor and not itemSelected then

                -- store the original length, mute state and position for later "healing"
                itemHealLength[reaper.BR_GetMediaItemGUID(item)] = itemLength
                itemHealMute[reaper.BR_GetMediaItemGUID(item)] = itemMute
                itemHealPosition[reaper.BR_GetMediaItemGUID(item)] = itemPosition

                -- if the cursor is exactly on the start of the item,
                -- it has to be slightly repositioned so that the
                -- script will work correctly
                if itemStartsOnCursor then
                    reaper.SetMediaItemInfo_Value(item, 'D_POSITION', itemPosition - 0.1)
                    newLength = 0.1
                else
                    -- I once had a weird bug that the item changes in length while recording,
                    -- but not at the playcursor. With substracting 0.01 it's some monkey patch
                    -- I did not faced this bug again, thus using the line without - 0.01
                    -- OLD LINE:
                    -- newLength = playCursorPosition - itemPosition - 0.01
                    -- NEW LINE:
                    -- newLength = playCursorPosition - itemPosition
                    -- And suddenly (maybe due to a Reaper update?) I have a very weird problem
                    -- again that in certain situations, where ... I am not sure ... there is
                    -- an odd BPM, maybe combined with signature changes and looped items
                    -- some items cannot be recorded new, since they would be recorded into
                    -- the looped item, while this item cannot be extended or so and thus
                    -- in the end nothing will be recorded ...
                    -- long text, short solution: I randomly tried my other monkey patch again
                    -- and it somehow fixes this issue ...
                    -- I have ABSOLUTELY no idea why this is happening, but it SEEMS (for now)
                    -- that this -0.01 seem to fix an issue I cannot understand :D
                    -- NEW LINE 2:
                    newLength = playCursorPosition - itemPosition - 0.01
                end

                -- shorten and mute the item here
                reaper.SetMediaItemInfo_Value(item, 'D_LENGTH', newLength)
                reaper.SetMediaItemInfo_Value(item, 'B_MUTE', 1)

            end

        end

    end

end

function HealItemsLengthsAndMuteState()
    for itemGUID, itemLength in pairs(itemHealLength) do
        local item = reaper.BR_GetMediaItemByGUID(0, itemGUID)
        reaper.SetMediaItemInfo_Value(item, 'D_LENGTH', itemHealLength[itemGUID])
        reaper.SetMediaItemInfo_Value(item, 'B_MUTE', itemHealMute[itemGUID])
        reaper.SetMediaItemInfo_Value(item, 'D_POSITION', itemHealPosition[itemGUID])
    end
end

function SelectNewestMediaItems()
    for i = 0, reaper.CountMediaItems(0) - 1 do
        item = reaper.GetMediaItem(0, i)
        uid = reaper.BR_GetMediaItemGUID(item)

        if not keyExists(existingItems, uid) then
            reaper.SetMediaItemSelected(item, 1)
            CompensatePlaybackTimeOffset(item)
        end
    end
    reaper.UpdateArrange()
end

function CompensatePlaybackTimeOffset(item)
    local itemsTrack = reaper.GetMediaItemInfo_Value(item, 'P_TRACK')
    local itemPosition = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')

    if reaper.GetMediaTrackInfo_Value(itemsTrack, 'I_PLAY_OFFSET_FLAG') == 0.0 then
        newPosition = itemPosition - reaper.GetMediaTrackInfo_Value(itemsTrack, 'D_PLAY_OFFSET')
    else
        newPosition = itemPosition
    end

    reaper.SetMediaItemInfo_Value(item, 'D_POSITION', newPosition)
end

function TrimTheNewItems()
    commandID = reaper.NamedCommandLookup('_BR_TRIM_MIDI_ITEM_ACT_CONTENT')
    reaper.Main_OnCommand(commandID, -1)
end




--===== RECORDING STATES =====--

function OnStartRecording()
    -- apparently the undo block will not work in defer scripts
    -- reaper.Undo_BeginBlock()
    GetExistingItems()
    ShortenAndMuteItemsUnderCursor(reaper.GetCursorPosition())
end

function OnRecord()
    -- for future features
end

function OnStopRecording()

    HealItemsLengthsAndMuteState()
    SelectNewestMediaItems()
    TrimTheNewItems()
    -- apparently the undo block will not work in defer scripts
    -- reaper.Undo_EndBlock(scriptTitle, -1)
    return
end




--===== MAIN =====--
local lastPlayState = -1
function main()
    local playState = reaper.GetPlayState()
    if lastPlayState == 5 and playState ~= lastPlayState then
        return OnStopRecording()
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
