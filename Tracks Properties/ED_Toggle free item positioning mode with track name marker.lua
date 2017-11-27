--[[
 * @description Toggle free item positioning mode with track name marker
 * @about This script will enable FIPM for selected track(s) and add a [F] prefix to the track names to show they are in that mode
 * @author EvilDragon
 * @donate [link](https://www.paypal.me/EvilDragon)
 * @version 1.0
 * Licence: GPL v3
 * REAPER: 5.0+
 * Extensions: none
--]]

num_sel_tracks = reaper.CountSelectedTracks(0)

reaper.Undo_BeginBlock()

if num_sel_tracks > 0 then
  reaper.Main_OnCommand(40641, 0)  -- toggle FIPM

  i = 0
  while i < num_sel_tracks do
    track_idx = reaper.GetSelectedTrack(0, i)
    retval, track_name = reaper.GetSetMediaTrackInfo_String(track_idx, "P_NAME", "", false)

    FIPM_label = string.sub(track_name, 1, 4)
    str_remainder = string.sub(track_name, 5)

    FIPM_mode = reaper.GetMediaTrackInfo_Value(track_idx, "B_FREEMODE")

    if FIPM_mode == 1 and FIPM_label ~= "[F] " then
      reaper.GetSetMediaTrackInfo_String(track_idx, "P_NAME", "[F] " .. track_name, true)
    elseif FIPM_mode == 0 and FIPM_label == "[F] " then
      reaper.GetSetMediaTrackInfo_String(track_idx, "P_NAME", str_remainder, true)
    end

    i = i + 1
  end
end

reaper.Undo_EndBlock("Toggle free item positioning mode with track name marker", -1)
