-- @description Turn item pitch in the selected track into MIDI notes
-- @author yatsumehole
-- @version 1.2
-- @changelog Made script work on multiple tracks. Added explanation of the script.
-- @about
--   # Introduce
--   As it's name, it turns items' pitch in the selected track into MIDI notes.
--
--   # How to use
--   Select the track, and run the **Turn item pitch in the selected track into MIDI notes.lua**.  
--   It will generate the midi notes from items.
--   - If you mute the item, script will not recognize the item.
--   - It works on the multiple selected tracks.
--
--   # My blog
--   Tutorial with picture will upload on these blogs.
--   - [My blog(ENG)](https://ytpmv-info-en.blogspot.com/)
--   - [My blog(KOR)](https://hapsung.tistory.com/)

R = reaper

local function main()
    --get the information of the track
    for track_idx=0, R.CountSelectedTracks(0)-1 do
        local cur_track = R.GetSelectedTrack(0, track_idx)
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

        local real = 0 --actual item number

        for i=0, item_num-1 do
            local media_item =  R.GetTrackMediaItem(cur_track, i)
            local item_take =  R.GetMediaItemTake(media_item, 0)
            local item_mute = R.GetMediaItemInfo_Value(media_item, "B_MUTE")
            --if item is muted, it will not apply on midi note.
            if item_mute == 0.0 then
                pitch_arr[real] =  math.floor(R.GetMediaItemTakeInfo_Value(item_take, "D_PITCH"))
                start_point[real] = R.GetMediaItemInfo_Value(media_item, "D_POSITION")
                if real == 0 then --If item is overlapped with previous item, it will modify midi note.
                    end_point[real] = start_point[real] + R.GetMediaItemInfo_Value(media_item, "D_LENGTH")
                elseif real ~= 0 and end_point[real-1] < start_point[real] then
                    end_point[real] = start_point[real] + R.GetMediaItemInfo_Value(media_item, "D_LENGTH")
                elseif real ~= 0 and end_point[real-1] >= start_point[real] then
                    end_point[real-1] = start_point[real]
                    end_point[real] = start_point[real] + R.GetMediaItemInfo_Value(media_item, "D_LENGTH")
                end
                real = real + 1
            end
        end

        --set new midi item under the original track
        R.InsertTrackAtIndex(track_num, true)
        local midi_track =  R.GetTrack(0, track_num)
        R.CreateNewMIDIItemInProj(midi_track, start_point[0], end_point[real-1], false)
        local folder_depth = R.GetMediaTrackInfo_Value(cur_track, "I_FOLDERDEPTH")
        R.SetMediaTrackInfo_Value(midi_track, "I_FOLDERDEPTH", folder_depth-1)

        --insert midi notes to midi item
        local midi_item =  R.GetTrackMediaItem(midi_track, 0)
        local midi_take =  R.GetMediaItemTake(midi_item, 0)
        for i=0, real-1 do
            start_ppq[i] = R.MIDI_GetPPQPosFromProjTime(midi_take, start_point[i])
            end_ppq[i] = R.MIDI_GetPPQPosFromProjTime(midi_take, end_point[i])
            R.MIDI_InsertNote(midi_take, false, false, start_ppq[i], end_ppq[i], 0, 60 + pitch_arr[i], 100, false)
        end
    end
end


if R.CountSelectedTracks(0) == 0 then
    R.ShowMessageBox("Please select the track", "Error", 0)
else
    main()
end

R.UpdateArrange()
