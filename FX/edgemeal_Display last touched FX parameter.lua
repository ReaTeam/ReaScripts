-- @description Display last touched FX parameter
-- @author Edgemeal
-- @version 1.0
-- @donation Donate https://www.paypal.me/Edgemeal

function Loop()
  local txt = " "
  local retval, tracknumber, fxnumber, paramnumber = reaper.GetLastTouchedFX()
  if retval then
    if (tracknumber >> 16) == 0 then -- Track FX or Input FX
      local track = reaper.CSurf_TrackFromID(tracknumber, false)
      local retval, track_name = reaper.GetTrackName(track)
      if tracknumber == 0 then track_name = 'Master Track' else track_name = 'Track '..tostring(tracknumber)..' - '..track_name end
      local retval, fx_name = reaper.TrackFX_GetFXName(track, fxnumber, "")
      local retval, param_name = reaper.TrackFX_GetParamName(track, fxnumber, paramnumber, "")
      local fx_id = "FX: " if (fxnumber >> 24) == 1 then fx_id = "Input FX: " end
      txt = track_name..'\n'..fx_id..fx_name..'\n'..'Param: '..param_name..'\n'
    else -- ITEM FX >>>>>
      local track = reaper.CSurf_TrackFromID((tracknumber & 0xFFFF), false)
      local retval, track_name = reaper.GetTrackName(track)
      track_name = 'Track '..tostring(tracknumber & 0xFFFF) ..' - ' ..track_name
      local takenumber  = (fxnumber >> 16)
      fxnumber = (fxnumber & 0xFFFF)
      local item_index = (tracknumber >> 16)-1
      local item = reaper.GetTrackMediaItem(track, item_index)
      local take = reaper.GetTake(item, takenumber)
      local retval, fx_name = reaper.TakeFX_GetFXName(take, fxnumber, "")
      local retval, take_param_name = reaper.TakeFX_GetParamName(take, fxnumber, paramnumber, "")
      txt = track_name..'\n'.."Item "..tostring(item_index+1).."  Take "..tostring(takenumber+1)..'\n'.."FX: "..fx_name..'\n'..'Param: '..take_param_name..'\n'
    end
  end
  local str_w, str_h = gfx.measurestr(txt)
  gfx.x, gfx.y = (gfx.w - str_w) / 2, (gfx.h - str_h) / 2
  gfx.drawstr(txt)
  gfx.update()
  if gfx.getchar() >= 0 then reaper.defer(Loop) end
end

local title = 'Last Touched Param'
local wnd_w, wnd_h = 400,100
local __, __, scr_w, scr_h = reaper.my_getViewport(0, 0, 0, 0, 0, 0, 0, 0, 1)
gfx.init(title, wnd_w, wnd_h, 0, (scr_w - wnd_w) / 2, (scr_h - wnd_h) / 2)
gfx.setfont(1,"Arial", 16)

-- Optional: set window topmost
if reaper.APIExists('JS_Window_FindTop') then
  local hwnd = reaper.JS_Window_FindTop(title, true)
  if hwnd then reaper.JS_Window_SetZOrder(hwnd, "TOPMOST", hwnd) end
end

Loop()
