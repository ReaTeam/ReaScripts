-- @description Floating FX bypass toggle (toggle action using last saved parameters)
-- @author 80icio
-- @version 1.1
-- @about Action to run 80icio_Floating FX bypass toggle script with last saved parameters

--   This script let you toggle any visible floating FX bypass.
--   track FX, take FX, input FX or fx chain focused FX
--
--   Thanks to BirdBird & Tycho

r = reaper


scriptname = 'Floating FX Bypass Toggle'

function str_to_bool(str)
    if str == nil then
        return false
    end
    return string.lower(str) == 'true'
end

trkFX = str_to_bool(r.GetExtState(scriptname,'trkFX')) or false

InpFX = str_to_bool(r.GetExtState(scriptname,'InpFX') ) or false

TakeFX = str_to_bool(r.GetExtState(scriptname,'TakeFX') ) or false

ChainFXwndw = str_to_bool(r.GetExtState(scriptname,'ChainFXwndw') ) or false

WetToggle = str_to_bool(r.GetExtState(scriptname,'WetToggle') ) or false


    r.Undo_BeginBlock2(0)
    for i = -1, r.CountTracks(0) - 1 do
    
      local track
      if i == -1 then track = r.GetMasterTrack() else
        track = r.GetTrack(0, i)
      end
      
      for index = 0, r.TrackFX_GetCount(track) - 1 do
          
          local chainfltngfx = r.TrackFX_GetChainVisible( track )
          
        
          if trkFX then

            if r.TrackFX_GetFloatingWindow( track, index ) then
              if WetToggle then
                local wetparam = r.TrackFX_GetParamFromIdent( track, index, ":wet" )
                local wetparam_value = r.TrackFX_GetParam(track, index, wetparam)
                local wetparam_value = math.floor(wetparam_value + 0.5)
                r.TrackFX_SetParam(track, index, wetparam,  math.abs(wetparam_value -1) )
              else
                r.TrackFX_SetEnabled(track, index, not r.TrackFX_GetEnabled(track, index))
              end
            end
          end
          
          if ChainFXwndw then
            if index == chainfltngfx then
              
              if WetToggle then
                local wetparam = r.TrackFX_GetParamFromIdent( track, chainfltngfx, ":wet" )
                local wetparam_value = r.TrackFX_GetParam(track, chainfltngfx, wetparam)
                local wetparam_value = math.floor(wetparam_value + 0.5)
                r.TrackFX_SetParam(track, chainfltngfx, wetparam,  math.abs(wetparam_value -1) )
              else
                r.TrackFX_SetEnabled(track, chainfltngfx, not r.TrackFX_GetEnabled(track, chainfltngfx))
              end
            
            end
          end
        --end
      end
      
      local INchainfltngfx = r.TrackFX_GetRecChainVisible( track )
      
      for index = 0, r.TrackFX_GetRecCount(track) - 1 do
        if InpFX then
          
          if r.TrackFX_GetFloatingWindow(track, index + 0x1000000) then
            if WetToggle then
              local wetparam = r.TrackFX_GetParamFromIdent( track, index + 0x1000000, ":wet" )
              local wetparam_value = r.TrackFX_GetParam(track, index + 0x1000000, wetparam)
              local wetparam_value = math.floor(wetparam_value + 0.5)
              r.TrackFX_SetParam(track, index + 0x1000000, wetparam,  math.abs(wetparam_value -1) )
            else
              r.TrackFX_SetEnabled(track, index + 0x1000000, not r.TrackFX_GetEnabled(track, index + 0x1000000 ))
            end
          end
        end
      
        if ChainFXwndw then
          if index == INchainfltngfx  then
            if WetToggle then
              local wetparam = r.TrackFX_GetParamFromIdent( track, INchainfltngfx + 0x1000000, ":wet" )
              local wetparam_value = r.TrackFX_GetParam(track, INchainfltngfx + 0x1000000, wetparam)
              local wetparam_value = math.floor(wetparam_value + 0.5)
              r.TrackFX_SetParam(track, INchainfltngfx + 0x1000000, wetparam,  math.abs(wetparam_value -1) )
            else
              r.TrackFX_SetEnabled(track, INchainfltngfx + 0x1000000, not r.TrackFX_GetEnabled(track, INchainfltngfx + 0x1000000))
            end
          end
        end
      end
    end

    
    if TakeFX then
      for i = 0, r.CountMediaItems(0) - 1 do
        local take =  r.GetActiveTake(r.GetMediaItem(0, i))
        local TKchainfltngfx = r.TakeFX_GetChainVisible( take )
        for j = 0, r.TakeFX_GetCount(take) - 1 do
        
          if  r.TakeFX_GetFloatingWindow(take, j) then
            if WetToggle then
              local wetparam = r.TakeFX_GetParamFromIdent( take, j, ":wet" )
              local wetparam_value = r.TakeFX_GetParam(take, j, wetparam)
              local wetparam_value = math.floor(wetparam_value + 0.5)
              r.TakeFX_SetParam(take, j, wetparam,  math.abs(wetparam_value -1) )
            else
              r.TakeFX_SetEnabled(take, j, not r.TakeFX_GetEnabled(take, j))
            end
          end
          
          if ChainFXwndw then
            if j == TKchainfltngfx  then
              if WetToggle then
                local wetparam = r.TakeFX_GetParamFromIdent( take, TKchainfltngfx, ":wet" )
                local wetparam_value = r.TakeFX_GetParam(take, TKchainfltngfx, wetparam)
                local wetparam_value = math.floor(wetparam_value + 0.5)
                r.TakeFX_SetParam(take, TKchainfltngfx, wetparam,  math.abs(wetparam_value -1) )
              else
                r.TakeFX_SetEnabled(take, TKchainfltngfx, not r.TakeFX_GetEnabled(take, TKchainfltngfx))
              end
            end
          end
        
        end
      end
    end
    r.Undo_EndBlock2(0, scriptname, -1)




