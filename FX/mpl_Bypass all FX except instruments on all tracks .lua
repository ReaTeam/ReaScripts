--[[
 * ReaScript Name: Bypass all FX except instruments on all tracks 
 * Description: Lua version of spk77_Bypass trackFXs (except VSTis)
 * Instructions: 
 * Author: Michael Pilyavskiy, spk77
 * Author URl: http://forum.cockos.com/member.php?u=70694
 * Repository: 
 * Repository URl: 
 * File URl:
 * Licence: GPL v3
 * Forum Thread: 
 * Forum Thread URl: http://forum.cockos.com/showpost.php?p=1475585&postcount=6
 * REAPER: 5.0 
 * Extensions: 
 --]]
 
 --[[
  * Changelog:
  * v1.0 (2015-11-03)
   + Initial Release
  --]]
 
 
  script_title = "Bypass all FX except instruments on all tracks"
  reaper.Undo_BeginBlock()
  
  counttracks = reaper.CountTracks(0)
  if counttracks  ~= nil then
    for i = 1, counttracks do
      tr = reaper.GetTrack(0,i-1)
      if tr ~= nil then
        instr_id = reaper.TrackFX_GetInstrument(tr)-1
        if instr_id == nil then instr_id = -1 end
        fxcount = reaper.TrackFX_GetCount(tr)
        if fxcount ~= nil then
          for j = 1, fxcount do
            if j-1 == instr_id then
              reaper.TrackFX_SetEnabled(tr, j-1, true)
             else
              reaper.TrackFX_SetEnabled(tr, j-1, false)
            end
          end
        end        
      end
    end
  end
  
  tr= reaper.GetMasterTrack(0)
    instr_id = reaper.TrackFX_GetInstrument(tr)-1
    if instr_id == nil then instr_id = -1 end
      fxcount = reaper.TrackFX_GetCount(tr)
      if fxcount ~= nil then
        for j = 1, fxcount do
          if j-1 == instr_id then
            reaper.TrackFX_SetEnabled(tr, j-1, true)
           else
            reaper.TrackFX_SetEnabled(tr, j-1, false)
          end
        end
    end  
    
  reaper.Undo_EndBlock(script_title, 0)
