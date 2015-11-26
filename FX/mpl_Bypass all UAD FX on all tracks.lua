--[[
 * ReaScript Name: Bypass all FX except instruments on all tracks 
 * Description:
 * Instructions: 
 * Author: Michael Pilyavskiy
 * Author URl: http://forum.cockos.com/member.php?u=70694
 * Repository: 
 * Repository URl: 
 * File URl:
 * Licence: GPL v3
 * Forum Thread: 
 * Forum Thread URl: 
 * REAPER: 5.0 
 * Extensions: 
 --]]
 
 --[[
  * Changelog:
  * v1.0 (2015-11-03)
   + Initial Release
  --]]
    
  script_title = "Bypass all UAD FX on all tracks"
  reaper.Undo_BeginBlock()
  
  plug_name = "UAD"
  
  trackcount = reaper.CountTracks(0)
  if trackcount ~= nil then
    for i = 1, trackcount do
      track = reaper.GetTrack(0,i-1)
      fx_count = reaper.TrackFX_GetCount(track)
      if fx_count ~= nil then
        for j = 1, fx_count do
          retval, fx_name = reaper.TrackFX_GetFXName(track, j-1, "")
          if string.find(fx_name, plug_name) ~= nil then
            reaper.TrackFX_SetEnabled(track, j-1, false)
          end
        end
      end  
    end
  end 
  
  track = reaper.GetMasterTrack(0)
    fx_count = reaper.TrackFX_GetCount(track)
    if fx_count ~= nil then
      for j = 1, fx_count do
        retval, fx_name = reaper.TrackFX_GetFXName(track, j-1, "")
        if string.find(fx_name, plug_name) ~= nil then
          reaper.TrackFX_SetEnabled(track, j-1, false)
        end
      end
    end  
  reaper.Undo_EndBlock(script_title, 0)
