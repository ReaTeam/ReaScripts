-- @description Turn items into midi
-- @author Webcam
-- @version 1.0
-- @changelog Add metadata
-- @provides
--   [main=main] .
--   [main=main,midi_editor] webcam_Turn items into midi/item2midi.lua
-- @about
--   # About
--
--   Reascript for mmaker's After effect screenfilpping script. (https://youtu.be/w5zKZov4-u0)
--
--   # How to use
--
--   Select the track which contains item and run this script. It'll make midi item based on item's pitch.

--[[
    Script information
    Script name: item2midi.lua
    Developer: Webcam (@webcam_ytp)
    How to use: Select the track which contais item and run this script. It will make midi item based on item's pitch.

    History
    2020.10.20: Initial release.
    2020.10.21: Add error message and minor issues, upload it on Reapack.
]]--

R = reaper

local function main()
    --get the information of the track
    local cur_track = R.GetSelectedTrack(0, 0)
    local track_num =  R.GetMediaTrackInfo_Value(cur_track, "IP_TRACKNUMBER")
    local item_num =  R.CountTrackMediaItems(cur_track)

    --information for media items
    local pitch_arr = {} --pitch
    local start_point = {} --start point
    local end_point = {} --end point
    local start_ppq = {} --start point of pulses per quarter note (for midi)
    local end_ppq = {} --end point of pulses per quarter note (for midi)

    --get the audio file's data from track
    if  R.CountTrackMediaItems(cur_track) == 0 then
        return R.ShowMessageBox("There is no items in track", "Error", 0)
    end

    for i=0, item_num-1 do
        local media_item =  R.GetTrackMediaItem(cur_track, i)
        local item_take =  R.GetMediaItemTake(media_item, 0)
        pitch_arr[i] =  math.floor(R.GetMediaItemTakeInfo_Value(item_take, "D_PITCH"))
        start_point[i] = R.GetMediaItemInfo_Value(media_item, "D_POSITION")
        end_point[i] = start_point[i] + R.GetMediaItemInfo_Value(media_item, "D_LENGTH")
    end

    --set new midi item under the original track
    R.InsertTrackAtIndex(track_num, true)
    local midi_track =  R.GetTrack(0, track_num)
    R.CreateNewMIDIItemInProj(midi_track, start_point[0], end_point[item_num-1], false)
    local folder_depth = R.GetMediaTrackInfo_Value(cur_track, "I_FOLDERDEPTH")
    R.SetMediaTrackInfo_Value(midi_track, "I_FOLDERDEPTH", folder_depth-1)

    --insert midi notes to midi item
    local midi_item =  R.GetTrackMediaItem(midi_track, 0)
    local midi_take =  R.GetMediaItemTake(midi_item, 0)
    for i=0, item_num-1 do
        start_ppq[i] = R.MIDI_GetPPQPosFromProjTime(midi_take, start_point[i])
        end_ppq[i] = R.MIDI_GetPPQPosFromProjTime(midi_take, end_point[i])
        R.MIDI_InsertNote(midi_take, false, false, start_ppq[i], end_ppq[i], 0, 60 + pitch_arr[i], 100, false)
    end
end


if R.CountSelectedTracks(0) == 0 then
    R.ShowMessageBox("Please select the track", "Error", 0)
else
    main()
end

R.UpdateArrange()
