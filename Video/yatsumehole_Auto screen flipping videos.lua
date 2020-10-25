-- @description Auto screen flipping videos
-- @author yatsumehole
-- @version 1.0
-- @changelog Initial release with fixing some errors and add more feature.
-- @about
--   # Script information
--   This is script for people who making videos called YTPMV.
--   If you run the script and select the mode, it will flip the video automatically.
--   # How to use it
--   I upload tutorial on this [Notion page](https://www.notion.so/How-to-use-auto-flip-Reaper-script-c9181236994b407c8ccdb9ac4a63f454) but I will upload this on these sites too when my script uploaded on ReaPack.
--   - ENG : [My English blog](https://ytpmv-info-en.blogspot.com/)
--   - KOR : [My Korean blog](https://hapsung.tistory.com/)
--   - JPN : [maimai's Japanese blog](https://ytpmv.info/)
--   # Example video
--   [Streamable link](https://streamable.com/aj4bmq)

R = reaper

--split user input based on comma.
function string:split()
    local result = {}
    local from = 1
    local delim_from, delim_to = string.find(self, ',', from)
    while delim_from do
      table.insert(result, string.sub(self, from , delim_from-1))
      from = delim_to + 1
      delim_from, delim_to = string.find(self, ',', from)
    end
    table.insert(result, string.sub(self, from))
    return result
end

--set envelope based on user's sequence input.
local function flip_envelope(user, item_num, env, start_time, length)
    for i=0, item_num-1 do
        if user[2] == "2" or user[2] == "" then
            if i % 2 == 0 then
                R.InsertEnvelopePointEx(env, -1, start_time[i], 1, 1, 0, false)
            else
                R.InsertEnvelopePointEx(env, -1, start_time[i], 2, 1, 0, false)
            end
        elseif user[2] == "4" then
            if i % 4 == 0 then
                R.InsertEnvelopePointEx(env, -1, start_time[i], 1, 1, 0, false)
            elseif i % 4 == 1 then
                R.InsertEnvelopePointEx(env, -1, start_time[i], 4, 1, 0, false)
            elseif i % 4 == 2 then
                R.InsertEnvelopePointEx(env, -1, start_time[i], 3, 1, 0, false)
            elseif i % 4 == 3 then
                R.InsertEnvelopePointEx(env, -1, start_time[i], 2, 1, 0, false)
            end
        end
    end
    R.InsertEnvelopePointEx(env, -1, start_time[item_num-1] + length[item_num-1], 0, 1, 0, false)
end

--set video fx and envelope for new item
local function set_envelope(tr)
    --maek new media item on track
    local item_info = R.AddMediaItemToTrack(tr)
    R.SetMediaItemInfo_Value(item_info, "D_POSITION", 0)
    R.SetMediaItemInfo_Value(item_info, "D_LENGTH", 0.2)
    local take_info = R.AddTakeToMediaItem(item_info)

    --take fx on new media item and move fx to track
    local new_fx = R.TakeFX_AddByName(take_info, "Video processor", -1)
    R.TakeFX_SetPreset(take_info, new_fx, "Screen flip")
    R.TakeFX_CopyToTrack(take_info, new_fx, tr, new_fx, true)
    local flip_env = R.GetFXEnvelope(tr, 0, 0, true) --get envelope info

    --remove item which made before on track.
    R.DeleteTrackMediaItem(tr, item_info)
    return flip_env, new_fx
end

--set new track and item
local function set_items(user, i_start, length, tr, real_num)
    --set new track
    R.InsertTrackAtIndex(tr[2], true)
    local new_track =  R.GetTrack(0, tr[2])
    local folder_depth = R.GetMediaTrackInfo_Value(tr[1], "I_FOLDERDEPTH")
    R.SetMediaTrackInfo_Value(new_track, "I_FOLDERDEPTH", folder_depth-1)

    --set items on new track
    for i=0, tonumber(real_num)-1 do
        local new_item = R.AddMediaItemToTrack(new_track)
        R.SetMediaItemInfo_Value(new_item, "D_POSITION", i_start[i])
        if i ~= real_num-1 and user[1] ~= "1" then
            R.SetMediaItemInfo_Value(new_item, "D_LENGTH", i_start[i+1]-i_start[i])
        elseif i == real_num-1 and user[1] ~= "1" then
            R.SetMediaItemInfo_Value(new_item, "D_LENGTH", length[i])
        elseif user[1] == "1" then
            R.SetMediaItemInfo_Value(new_item, "D_LENGTH", length[i])
        end
        R.AddTakeToMediaItem(new_item)
    end

    return new_track
end

--get track info
local function get_track_info()
    local cur_track = R.GetSelectedTrack(0, 0)
    local track_num =  R.GetMediaTrackInfo_Value(cur_track, "IP_TRACKNUMBER")
    local item_num =  R.CountTrackMediaItems(cur_track)
    local tr_table = {cur_track, track_num, item_num}
    return tr_table
end

--get item info
local function get_item_info(mode, tr)
    local i_start = {}
    local i_length = {}
    local l_short = 0
    local real = 0
    local i_item = {}

    --set item's inital start and end point
    for i=0, tr[3]-1 do
        local media_item =  R.GetTrackMediaItem(tr[1], i)
        local item_mute = R.GetMediaItemInfo_Value(media_item, "B_MUTE")
        --if item is muted, it will not apply on midi note.
        --set item's start point and length.
        if item_mute == 0.0 then
            i_start[real] = R.GetMediaItemInfo_Value(media_item, "D_POSITION")
            i_length[real] = R.GetMediaItemInfo_Value(media_item, "D_LENGTH")

            if real == 0 then --set shortest item's length for mode 1.
                l_short = R.GetMediaItemInfo_Value(media_item, "D_LENGTH")
            else
                local length_temp = R.GetMediaItemInfo_Value(media_item, "D_LENGTH")
                if length_temp < l_short then
                    l_short = length_temp
                end
            end
            i_item[real] = media_item
            real = real + 1
        end
    end

    --change items' length based on mode.
    if mode ~= "1" then
        return i_start, i_length, real, i_item
    elseif mode == "1" then
        R.ClearConsole()
        for i = 0, tr[3]-1 do
            i_length[i] = l_short
        end
        return i_start, i_length, real, i_item
    end
end

--select items based on sequence
local function select_items(user, real_num, i_item)
    for i=0, real_num-1 do
        if user[2] == "2" or user[2] == "" then
            if i % 2 == 0 then
                R.SetMediaItemSelected(i_item[i], true)
            else
                R.SetMediaItemSelected(i_item[i], false)
            end
        elseif user[2] == "4" then
            if i % 4 == 0 then
                R.SetMediaItemSelected(i_item[i], true)
            else
                R.SetMediaItemSelected(i_item[i], false)
            end
        end
    end
end

--main function
local function main(user, tr, new_fx)
    local i_start = {} --start point
    local i_length = {} --end point
    local real_num = 0
    local i_item = {}
    local new_track = nil
    local flip_env = nil
    local new_fx = nil

    i_start, i_length, real_num, i_item = get_item_info(user[1], tr) --get start and end point of items

    if user[1] == "0" or user[1] == "1" or user[1] == "" then --create new track and envelope. But items' length are different.
        new_track = set_items(user, i_start, i_length, tr, real_num)
        if user[2] ~= "0" then
            flip_env, new_fx = set_envelope(new_track)
            flip_envelope(user, real_num, flip_env, i_start, i_length)
            if not R.TrackFX_GetOpen(new_track, new_fx) then --have to open fx's window because of updating UI
                R.TrackFX_SetOpen(new_track, new_fx, true)
            end
        end
        R.SetMediaTrackInfo_Value(new_track, "D_VOL", 0) --set track's volume to -inf for not overlapping sound.
    elseif user[1] == "2" then --create envelope only
        flip_env, new_fx = set_envelope(tr[1])
        flip_envelope(user, real_num, flip_env, i_start, i_length)
        if not R.TrackFX_GetOpen(tr[1], new_fx) then
            R.TrackFX_SetOpen(tr[1], new_fx, true)
        end
    elseif user[1] == "3" then --select items in sequence.
        select_items(user, real_num, i_item)
    end
end

--detect non-proper user inputs
local function detect_error(input1, input2)
    local i_ex1, i_ex2 = {"0", "1", "2", "3", "4", ""}, {"0", "2", "4", ""}
    local i_prop1, i_prop2 = true, true

    for i = 1, 6 do
        if input1 == i_ex1[i] then
            i_prop1 = false
            break
        end
    end

    for i = 1, 4 do
        if input2 == i_ex2[i] then
            i_prop2 = false
            break
        end
    end

    return i_prop1, i_prop2
end

local function set_mode() --sets item's length and envelope based on user input
    --get information about track
    local tr_info = get_track_info() --cur_track, track_num, item_num
    if tr_info[3] == 0 then --if there is no item, it output error.
        return R.ShowMessageBox("There is no items in track", "Error", 0)
    end

    --get user input and split them into i_table
    local input_bool, inputs = R.GetUserInputs("Select mode and sequence", 2, "Mode,Sequence", "")
    local i_table = {}
    if input_bool then
        i_table = string.split(inputs)
    end

    --check user puts proper input
    local i_bool1, i_bool2 = detect_error(i_table[1], i_table[2])
    if i_bool1 or i_bool2 then
        return R.ShowMessageBox("Please put proper input.", "Error", 0)
    end

    local item_info = R.AddMediaItemToTrack(tr_info[1])
    R.SetMediaItemInfo_Value(item_info, "D_POSITION", 0)
    R.SetMediaItemInfo_Value(item_info, "D_LENGTH", 0.2)
    local take_info = R.AddTakeToMediaItem(item_info)

    --take fx on new media item and move fx to track
    local new_fx = R.TakeFX_AddByName(take_info, "Video processor", -1)
    if not R.TakeFX_SetPreset(take_info, new_fx, "Screen flip") and i_table[2] ~= "3" then
        R.DeleteTrackMediaItem(tr_info[1], item_info)
        return R.ShowMessageBox("There isn't preset named \"Screen flip\".\nPlease put proper preset in Video processor effect.", "Error", 0)
    end

    R.DeleteTrackMediaItem(tr_info[1], item_info)
    --Send user's input and track info as argument.
    main(i_table, tr_info)
end

--detect track is selected
if R.CountSelectedTracks(0) == 0 then
    R.ShowMessageBox("Please select the track", "Error", 0)
else
    set_mode()
end

R.UpdateArrange()
