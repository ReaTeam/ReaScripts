-- @description Floating FX bypass toggle
-- @author 80icio
-- @version 1.0
-- @about
--   This script let you toggle any visible floating FX bypass.
--   track FX, take FX, input FX or fx chain focused FX
--   Please install IMGUI library
--
--   Thanks to BirdBird & Tycho

r = reaper

dofile(r.GetResourcePath() .. '/Scripts/ReaTeam Extensions/API/imgui.lua') ('0.8.1')

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


function exit()
  r.SetExtState(scriptname,'trkFX',tostring(trkFX),true)
  r.SetExtState(scriptname,'TakeFX',tostring(TakeFX),true)
  r.SetExtState(scriptname,'InpFX',tostring(InpFX),true)
  r.SetExtState(scriptname,'ChainFXwndw',tostring(ChainFXwndw),true)
end



ctx = r.ImGui_CreateContext(scriptname)

function TFB_GUI()
  r.ImGui_SetNextWindowSize( ctx, 220, 105)
  local visible, open = r.ImGui_Begin(ctx, scriptname, true, r.ImGui_WindowFlags_NoResize() | r.ImGui_WindowFlags_NoScrollbar())
  if visible then
  r.ImGui_BeginTable(ctx, 'options', 2,  r.ImGui_TableFlags_SizingStretchProp() )
  r.ImGui_TableNextColumn(ctx)
  
  _, trkFX = r.ImGui_Checkbox( ctx, 'Track FX', trkFX )
  _, InpFX = r.ImGui_Checkbox( ctx, 'Input FX', InpFX )
  
  r.ImGui_TableNextColumn(ctx)
  
  _, TakeFX = r.ImGui_Checkbox( ctx, 'Take FX ', TakeFX )
  _, ChainFXwndw = r.ImGui_Checkbox( ctx, 'Chain FX', ChainFXwndw )
  r.ImGui_EndTable(ctx)
  
  toggleBttn = r.ImGui_Button(ctx,'TOGGLE', -1)
  
  
    r.ImGui_End(ctx)
  end
  if open then
    r.defer(TFB_GUI)
  end
---------------------------------------END GUI--------------------------
  if toggleBttn and (trkFX or InpFX or TakeFX or ChainFXwndw) then
reaper.ClearConsole()
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
              r.TrackFX_SetEnabled(track, index, not r.TrackFX_GetEnabled(track, index))
            end
          end
          
          if ChainFXwndw then
            if index == chainfltngfx then
              r.TrackFX_SetEnabled(track, chainfltngfx, not r.TrackFX_GetEnabled(track, chainfltngfx))
            end
          end
        --end
      end
      
      local INchainfltngfx = r.TrackFX_GetRecChainVisible( track )
      
      for index = 0, r.TrackFX_GetRecCount(track) - 1 do
        if InpFX then
          
          if r.TrackFX_GetFloatingWindow(track, index + 0x1000000) then
            r.TrackFX_SetEnabled(track, index + 0x1000000, not r.TrackFX_GetEnabled(track, index + 0x1000000 ))
          end
        end
      
        if ChainFXwndw then
          if index == INchainfltngfx  then
            r.TrackFX_SetEnabled(track, INchainfltngfx + 0x1000000, not r.TrackFX_GetEnabled(track, INchainfltngfx + 0x1000000))
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
            r.TakeFX_SetEnabled(take, j, not r.TakeFX_GetEnabled(take, j))
          end
          
          if ChainFXwndw then
            if j == TKchainfltngfx  then
              r.TakeFX_SetEnabled(take, TKchainfltngfx, not r.TakeFX_GetEnabled(take, TKchainfltngfx))
            end
          end
        
        end
      end
    end
    r.Undo_EndBlock2(0, scriptname, -1)
  end

end

TFB_GUI()

r.atexit(exit)


