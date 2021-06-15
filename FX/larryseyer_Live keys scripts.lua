-- @description Live keys scripts
-- @author Larry Seyer
-- @version 1.0.0-1
-- @changelog Fix broken include path due to packaging changes
-- @provides
--   [nomain] .
--   [main] larryseyer_Live keys scripts/action.lua > larryseyer_Live keys scripts - Track 1.lua
--   [main] larryseyer_Live keys scripts/action.lua > larryseyer_Live keys scripts - Track 2.lua
--   [main] larryseyer_Live keys scripts/action.lua > larryseyer_Live keys scripts - Track 3.lua
--   [main] larryseyer_Live keys scripts/action.lua > larryseyer_Live keys scripts - Track 4.lua
--   [main] larryseyer_Live keys scripts/action.lua > larryseyer_Live keys scripts - Track 5.lua
--   [main] larryseyer_Live keys scripts/action.lua > larryseyer_Live keys scripts - Track 6.lua
--   [main] larryseyer_Live keys scripts/action.lua > larryseyer_Live keys scripts - Track 7.lua
--   [main] larryseyer_Live keys scripts/action.lua > larryseyer_Live keys scripts - Track 8.lua
--   [main] larryseyer_Live keys scripts/action.lua > larryseyer_Live keys scripts - Track 9.lua
--   [main] larryseyer_Live keys scripts/action.lua > larryseyer_Live keys scripts - Track 10.lua
--   [main] larryseyer_Live keys scripts/action.lua > larryseyer_Live keys scripts - Track 11.lua
--   [main] larryseyer_Live keys scripts/action.lua > larryseyer_Live keys scripts - Track 12.lua
--   [main] larryseyer_Live keys scripts/action.lua > larryseyer_Live keys scripts - Track 13.lua
--   [main] larryseyer_Live keys scripts/action.lua > larryseyer_Live keys scripts - Track 14.lua
--   [main] larryseyer_Live keys scripts/action.lua > larryseyer_Live keys scripts - Track 15.lua
--   [main] larryseyer_Live keys scripts/action.lua > larryseyer_Live keys scripts - Track 16.lua
--   [main] larryseyer_Live keys scripts/action.lua > larryseyer_Live keys scripts - Reset.lua
-- @link
--   How-To Install Video https://www.youtube.com/watch?v=g506QrJ19-4
--   Author Website https://larryseyer.com/
--   Donation Page https://larryseyer.com/donate/
-- @about
--   Live Keys Scripts (NOW WORKS WITH MAC AND WINDOWS)
--
--   These scripts are designed for those who want to use Reaper for live performance such as a replacement for MainStage.
--
--   Using these scripts saves computing power by turning off ALL tracks and FX (up to 16 tracks) except the desired track allowing for more stable operation for a live performance using Reaper. Tracks that are disabled take no processing power.
--
--   This script differs from other scripts in that it allows for instantaneous switching from one track to another without cutting notes or effects off. In other words, delays, reverbs, and long string patches continue to sound when selecting new tracks.
--
--   In addition, bypassed tracks and FX are hidden out of view and only the selected track is visible (up to 16 tracks). This is done in order to allow for the automatic large track size increase when a track is selected this script performs.

--
-- Live_Inst (c) 2021 Larry Seyer All rights reserved
-- http://LarrySeyer.com
--

-- function msg(value)
--      reaper.ShowConsoleMsg(tostring(value) .. "\n")
-- end

max_live_tracks = 16 -- one based
current_track_height_override = 765

-- SAVE/RESTORE DATA
function setValue(key, value)
  reaper.SetProjExtState(0, "Live_Inst_", key, value)
end

function getValue(key)
  local valueExists, value = reaper.GetProjExtState(0, "Live_Inst_", key)
  if valueExists == 0 then
    return nil
  end
  return value
end

function save_last_selected_track(this_track)
    setValue("last_selected_track", this_track)
end

function recall_last_selected_track()
    return tonumber(getValue("last_selected_track"))
end

function reset_tracks(tracks_count)
    for i = 0, tracks_count - 1  do
        local track = reaper.GetTrack(0, i)
        reaper.SetMediaTrackInfo_Value(track, "B_SHOWINMIXER", 1)
        reaper.SetMediaTrackInfo_Value(track, "B_SHOWINTCP", 1)
        reaper.SetMediaTrackInfo_Value(track, "I_FXEN", 1)
        reaper.SetMediaTrackInfo_Value(track, "I_HEIGHTOVERRIDE", 0)
        reaper.SetMediaTrackInfo_Value(track, "I_RECARM", 0)
        reaper.SetMediaTrackInfo_Value(track, "I_RECMON", 1)
        reaper.SetMediaTrackInfo_Value(track, "I_SELECTED", 0)
    end
end

function set_all_track_fx_state_off(tracks_count, last_selected_track)
    for i = 0, tracks_count - 1  do
        local track = reaper.GetTrack(0, i)
        if not (i == tonumber(last_selected_track-1)) then
            reaper.SetMediaTrackInfo_Value(track, "I_FXEN", 0)
        end
        reaper.SetMediaTrackInfo_Value(track, "B_SHOWINMIXER", 0)
        reaper.SetMediaTrackInfo_Value(track, "B_SHOWINTCP", 0)
        reaper.SetMediaTrackInfo_Value(track, "I_HEIGHTOVERRIDE", 0)
        reaper.SetMediaTrackInfo_Value(track, "I_SELECTED", 0)
    end
end

function set_one_track_fx_state_on(track_number)
    local track = reaper.GetTrack(0, track_number-1)
    reaper.SetMediaTrackInfo_Value(track, "I_FXEN", 1)
end

function set_track_to_rec_arm(track_number)
    local track = reaper.GetTrack(0, track_number-1)
    reaper.SetMediaTrackInfo_Value(track, "I_SELECTED", 1)
    reaper.SetMediaTrackInfo_Value(track, "B_SHOWINMIXER", 1)
    reaper.SetMediaTrackInfo_Value(track, "B_SHOWINTCP", 1)
    reaper.SetMediaTrackInfo_Value(track, "I_HEIGHTOVERRIDE", current_track_height_override)
    reaper.SetMediaTrackInfo_Value(track, "I_RECARM", 1)
    reaper.SetMediaTrackInfo_Value(track, "I_RECMON", 1)
end

function Live_Inst_Main_Logic(this_live_track)
    reaper.PreventUIRefresh(1)

    tracks_count = reaper.CountTracks(0)
    if tracks_count > 0 then

        if tracks_count > max_live_tracks then
            tracks_count = max_live_tracks
        end

        if this_live_track == -1 then
            reset_tracks(tracks_count)
        else
            local last_selected_track = 0
            last_selected_track = recall_last_selected_track()
        	local this_track = tonumber(this_live_track)
            if this_track <= tracks_count then
                if not last_selected_track then
                    last_selected_track = this_track
                end
                save_last_selected_track(this_live_track)
                reaper.ClearAllRecArmed()
                set_all_track_fx_state_off(tracks_count, last_selected_track)
                set_one_track_fx_state_on(this_track)
            	set_track_to_rec_arm(this_track)
            end
        end

    end
    reaper.TrackList_AdjustWindows(true) -- Update the arrangement (often needed)
    reaper.UpdateArrange()
    reaper.PreventUIRefresh(-1)
end
