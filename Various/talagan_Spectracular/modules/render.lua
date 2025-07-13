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

-- Returns a context with full info on the source so that we can parse it
local function getTrackSourceContext(new_track)

    local item = reaper.GetTrackMediaItem(new_track, 0)

    local ret = {
        success = false,
        err     = nil,
    }

    if not item then
        ret.err = "No item was created on rendered track !"
    else
        local take = reaper.GetMediaItemTake(item, 0)
        if not take then
             ret.err = "No take was created on rendered track !"
        else
            local ts            = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
            local te            = ts + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
            local tlen          = te - ts
            local source        = reaper.GetMediaItemTake_Source(take)
            local chan_count    = reaper.GetMediaSourceNumChannels(source)  -- Should be 1 since we render in mono
            local sample_rate   = reaper.GetMediaSourceSampleRate(source)   -- Should be the SR of the project
            local numframes     = math.floor(tlen * sample_rate)
            local file_name     = reaper.GetMediaSourceFileName(source)

            ret.success         = true
            ret.sample_rate     = sample_rate
            ret.chan_count      = chan_count
            ret.start           = ts
            ret.ts              = ts
            ret.stop            = te
            ret.te              = te
            ret.duration        = tlen
            ret.frame_count     = numframes
            ret.sample_count    = numframes * chan_count
            ret.file_name       = file_name
            -- Create an audio accessor for the take's source. We'll destroy it at the end of the analysis
            ret.audio_accessor  = reaper.CreateTakeAudioAccessor(take)
        end
    end
    return ret
end

-- Renders the selection (track + time selection) and returns a source context
-- So that it can be read and processed
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
        local limit         = 8182 -- ImGUI texture size limit
        local max_seconds   = math.floor(limit * params.time_resolution_ms/1000.0)
        local seconds       = math.ceil(te - ts)

--[[
        if seconds > max_seconds then
            -- This is due to the fact the EEL functions are limited to 8M slots
            -- And most of them will explode past this limit ...
            return {
                success = false,
                err     = "At the current resolution, the time selection is technically limited to :\n\n" .. max_seconds .. " seconds.\n\nThe current one is :\n\n" .. " " .. seconds .. " seconds.\n\nPlease adjust your time selection."
            }
        end
        ]]
    end

    -- Backup current tracks
    local selectedTracks            = TRACKS.GetSelectedTracks(0)

    if #selectedTracks == 0 then
        return {
            success = false,
            err     = "Please select one or more tracks !"
        }
    end

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
        --local t1 = reaper.time_precise()
        --ret = getSamples(newtracks[1]._track)
        --LOG.info("Samples extraction : " .. (reaper.time_precise() - t1) .. "\n")
        ret = getTrackSourceContext(newtracks[1]._track)
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
