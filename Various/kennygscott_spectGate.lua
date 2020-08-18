-- @description SpectreGate
-- @author Kenny Scott
-- @version 1.0.0
-- @about
--   #SpectreGate
--
--   SpectreGate is simply an action based on the ["Greatest Kick & Snare Gate Trick Ever!"](https://www.youtube.com/watch?v=kVYmNTgMyww) video by Glenn Fricker of SpectreSoundStudios during the Tutorial Tuesday presentation on 08/18/2020.
--
--   **Disclaimer:** I am not affiliated with SpectreSoundStudios or Spectre Media Group. I am just a big fan trying to help make everyone else's life a little easier.

function FkYouGlenn()
  reaper.Main_OnCommand(40062, 0);
  reaper.Main_OnCommand(40289, 0);
  reaper.Main_OnCommand(40287, 0);
  id = reaper.GetSelectedTrack(0, 0);
  reaper.TrackFX_AddByName(id, "ReaComp", false, 1)
  reaper.SetMediaTrackInfo_Value(id, "B_PHASE", 1)
end

FkYouGlenn();
