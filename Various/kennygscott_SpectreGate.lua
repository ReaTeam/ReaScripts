-- @description SpectreGate
-- @author Kenny G Scott
-- @version 1.0.0
-- @about
--   #Spectre gate
--
--   SpectreGate is an action based on the ["Greatest Kick & Snare Gate Trick Ever!"](https://www.youtube.com/watch?v=kVYmNTgMyww) Tutorial Tuesday by SpectreSoundStudios.
--
--   **DISCLAIMER:** I am not affiliated with SpectreSoundStudios or Spectre Media Group nor do I claim to be!

function F_ckYouGlenn()
  local track_selected = reaper.GetSelectedTrack(0, 0)
  if not track_selected then
    reaper.ShowMessageBox("Error: You must select a track before running this script!", "SpectreGate", 0)
  else
    reaper.Main_OnCommand(40062, 0);
    reaper.Main_OnCommand(40289, 0);
    reaper.Main_OnCommand(40287, 0);
    local id = reaper.GetSelectedTrack(0, 0);
    reaper.TrackFX_AddByName(id, "ReaComp", false, 1)
    reaper.SetMediaTrackInfo_Value(id, "B_PHASE", 1)
  end
end

F_ckYouGlenn();
