-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of Spectracular

-- Rendering tools on top of Reaper. The aim is to transform a selection (time/tracks) to samples for analysis.

local TRACKS = require "modules/tracks"
local S      = require "modules/settings"
local DSP    = require "modules/dsp"
local LOG    = require "modules/log"
local CSV    = require "modules/csv"

local function ScrollFollowsPlaybackState()
    return (reaper.GetToggleCommandStateEx(32060, 40750) == 1)
end

local function SetScrollFollowPlaybackState(on)
    local curr = ScrollFollowsPlaybackState()
    if not curr == on then
        reaper.MIDIEditor_OnCommand(reaper.MIDIEditor_GetActive(), 40750)
    end
end

local function renderCommandID(channel_mode)

    -- Track: Render selected area of tracks to stereo post-fader stem tracks (and mute originals)
    local render_stereo_post_fader = 41716
    -- Track: Render selected area of tracks to multichannel post-fader stem tracks (and mute originals)
    local render_multi_post_fader = 41717
    -- Track: Render selected area of tracks to mono post-fader stem tracks (and mute originals)
    local render_mono_post_fader = 41718

    -- Track: Render selected area of tracks to stereo stem tracks (and mute originals)
    local render_stereo_pre_fader = 41719
    -- Track: Render selected area of tracks to multichannel stem tracks (and mute originals)
    local render_multi_pre_fader = 41720
    -- Track: Render selected area of tracks to mono stem tracks (and mute originals)
    local render_mono_pre_fader = 41721

    -- SWS/AW: Render tracks to mono stem tracks, obeying time selection
    local render_sws_mono_start    = reaper.NamedCommandLookup("_SWS_AWRENDERMONOSMART")
    -- SWS/AW: Render tracks to stereo stem tracks, obeying time selection
    local render_sws_stereo_start  = reaper.NamedCommandLookup("_SWS_AWRENDERSTEREOSMART")

    if channel_mode == 'stereo' then
        return render_sws_stereo_start
    elseif channel_mode == 'mono' then
        return render_sws_mono_start
    else
        error("Developer error : passing unknown channel_mode")
    end

end

local function getAllSamplesFromTake(take)
    local item          = reaper.GetMediaItemTake_Item(take)
    local aa            = reaper.CreateTakeAudioAccessor(take)
    local tts           = reaper.GetAudioAccessorStartTime(aa)
    local tte           = reaper.GetAudioAccessorEndTime(aa)
    local source        = reaper.GetMediaItemTake_Source(take)
    local chan_count    = reaper.GetMediaSourceNumChannels(source)  -- Should be 1 since we render in mono
    local sample_rate   = reaper.GetMediaSourceSampleRate(source)   -- Should be the SR of the project
    local numframes     = math.floor((tte - tts) * sample_rate)
    local file_name     = reaper.GetMediaSourceFileName(source)
    local arr           = reaper.new_array(numframes * chan_count)
    local ts            = reaper.GetMediaItemInfo_Value(item, "D_POSITION");
    local te            = ts + reaper.GetMediaItemInfo_Value(item, "D_LENGTH");


    local use_split_implementation = true
    if use_split_implementation then
        local frames_per_block  = 65536
        local block_size        = frames_per_block * chan_count
        local block_dur         = frames_per_block * 1.0 / sample_rate
        local tmp               = reaper.new_array(block_size)

        local bls = tts
        local off = 1
        -- TODO : Split into blocks !!
        while bls < tte do
            local ble     = bls + block_dur
            local bdur    = block_dur
            local bframes = frames_per_block
            local bsize   = block_size

            if ble > tte then
                -- Last block may pose problems
                ble     = tte
                bdur    = ble - bls
                bframes = math.floor(bdur * sample_rate)
                bsize   = bframes * chan_count
            end

            reaper.GetAudioAccessorSamples(aa, sample_rate, chan_count, bls, bframes, tmp)
            arr.copy(tmp, 1, bsize, off)

            off = off + bsize
            bls = bls + block_dur
        end
    else
        -- One shot implementation
        reaper.GetAudioAccessorSamples(aa, sample_rate, chan_count, tts, numframes, arr)
    end

    reaper.DestroyAudioAccessor(aa)

    local chan_samples = {}
    for i=1, chan_count do
        chan_samples[#chan_samples+1] = reaper.new_array(numframes)
    end

    DSP.array_deinterleave(arr, table.unpack(chan_samples))

    return {
        samples         = chan_samples,
        sample_rate     = sample_rate,
        chan_count      = chan_count,
        ts              = ts,
        te              = te,
        file_name       = file_name
    }
end

local function getSamplesHelper(new_track)
    local item = reaper.GetTrackMediaItem(new_track, 0)

    local ret = {
        success = false,
        err     = nil,
    }

    if not item then
        ret.err = "No item was created on rendered track !"
    else
        local new_take = reaper.GetMediaItemTake(item, 0)
        if not new_take then
             ret.err = "No take was created on rendered track !"
        else

            local sample_ret = getAllSamplesFromTake(new_take)

            ret.success     = true
            ret.samples     = sample_ret.samples
            ret.sample_rate = sample_ret.sample_rate
            ret.chan_count  = sample_ret.chan_count
            ret.ts          = sample_ret.ts
            ret.te          = sample_ret.te

           -- Remove the rendedred file
            os.remove(sample_ret.file_name)
        end
    end

    return ret
end


local function getSamples(new_track)
    -- Protect the call to get samples helper as it may screw up things in the project
    local succ, sample_res = pcall(getSamplesHelper, new_track)

    if not succ then
        -- Unexpected crash !
        return {
            success = false,
            err     = sample_res
        }
    else
        -- Success or expected crash
        local ret = {
            success      = sample_res.success,
            err          = sample_res.err,
        }

        if sample_res.success then
            ret.samples      = sample_res.samples
            ret.sample_rate  = sample_res.sample_rate
            ret.chan_count   = sample_res.chan_count

            ret.start        = sample_res.ts
            ret.stop         = sample_res.te
            ret.duration     = sample_res.te - sample_res.ts
        end

        return ret
    end
end


local function render(params)

    local cts, cte = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)

    local ts = params.ts
    local te = params.te

    if not te or not ts then
        -- No solid time selection given, use current one.
        te = cte
        ts = cts
        if not (ts < te) then
            return {
                success  = false,
                err      = "No time selection !"
            }
        end

        if te - ts > 20 then
            -- This is due to the fact the EEL functions are limited to 8M slots
            -- And most of them will explode past this limit ...
            return {
                success = false,
                err     = "For technical reasons, Spectracular is currently limited to a selection of 20 seconds."
            }
        end
    end

    -- Backup current tracks
    local selectedTracks            = TRACKS.GetSelectedTracks(0)
    -- Backup this flag
    local scroll_follows_playback   = ScrollFollowsPlaybackState()

    -- Resolve wanted tracks
    local wantedTracks              = params.tracks or selectedTracks

    reaper.PreventUIRefresh(1)
    reaper.Undo_BeginBlock()


    -- Set current time selection
    reaper.GetSet_LoopTimeRange(true, false, ts, te, false)

    -- Disable the scroll follow playback option to avoid glitches
    SetScrollFollowPlaybackState(false)
    -- Create new neutral track
    local rendertrack = TRACKS.CreateTrackAtEnd(0, false)
    reaper.GetSetMediaTrackInfo_String(rendertrack._track, "P_NAME", "Spectracular TMP", true)

    --  Create sends for all tracks
    for _, track in ipairs(wantedTracks) do
        -- Track may not be valid anymore with the "keep track selection" option on
        if track:stillValid() then
            local sendid = reaper.CreateTrackSend(track._track, rendertrack._track)
            -- Set send volume at 0db
            reaper.SetTrackSendInfo_Value(track._track, 0, sendid, 'D_VOL', 1.0)
        end
    end

    -- Select only the render track and render !
    TRACKS.DeselectAllTracks()
    reaper.SetTrackSelected(rendertrack._track, true)

    local  alltracks = TRACKS.GetTracks(0)

    local t1 = reaper.time_precise()
    reaper.Main_OnCommand(renderCommandID(params.channel_mode), 0)
    LOG.info("Rendering : " .. (reaper.time_precise() - t1) .. "\n")

    local newtracks  = TRACKS.GetDiffTracks(0, alltracks)

    local ret = nil
    if #newtracks == 1 then
        local t1 = reaper.time_precise()
        ret = getSamples(newtracks[1]._track)
        LOG.info("Samples extraction : " .. (reaper.time_precise() - t1) .. "\n")
    else
        ret = {
            success = false,
            err     = "Something strange happened, as " .. #newtracks .. " were created during render O_o"
        }
    end

    -- Delete newly created track(s)
    for _, t in pairs(newtracks) do
       reaper.DeleteTrack(t._track)
    end

    -- Delete boundce track
    reaper.DeleteTrack(rendertrack._track)

    -- Restore scroll during playback option
    SetScrollFollowPlaybackState(scroll_follows_playback)

    -- Restore track selection
    TRACKS.RestoreSelectedTracks(0, selectedTracks)

    -- Restore time selection
    reaper.GetSet_LoopTimeRange(true, false, cts, cte, false)

    reaper.Undo_EndBlock(S.AppName, 0)
    reaper.PreventUIRefresh(-1)

    ret.tracks = wantedTracks

    return ret
end


return {
    render=render
}