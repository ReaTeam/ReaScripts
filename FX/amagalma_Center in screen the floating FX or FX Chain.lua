-- @description Center in screen the floating FX or FX Chain
-- @author amagalma
-- @version 1.00
-- @link https://forum.cockos.com/showthread.php?t=238370
-- @donation https://www.paypal.me/amagalma
-- @about Requires JS_ReaScriptAPI


if not reaper.APIExists( "JS_Window_ListFind" ) then
  reaper.MB( "Please, right-click and install 'js_ReaScriptAPI: API functions for ReaScripts'. Then restart Reaper and run the script again. Thanks!", "You need to install the JS_ReaScriptAPI", 0 )
  local ok, err = reaper.ReaPack_AddSetRepository( "ReaTeam Extensions", "https://github.com/ReaTeam/Extensions/raw/master/index.xml", true, 1 )
  if ok then reaper.ReaPack_BrowsePackages( "js_ReaScriptAPI" )
  else reaper.MB( err, "Something went wrong...", 0)
  end
  return reaper.defer(function() end)
end

local exists, tracknumber, itemnumber, fxnumber = reaper.GetFocusedFX()
local FX_win
if exists > 0 then
  local track = reaper.CSurf_TrackFromID( tracknumber, false )
  if exists == 1 then
    FX_win = reaper.TrackFX_GetFloatingWindow( track, fxnumber )
  else
    local item = reaper.GetTrackMediaItem( track, itemnumber )
    local take = reaper.GetMediaItemTake(item, fxnumber >> 16)
    FX_win = reaper.TakeFX_GetFloatingWindow( take, fxnumber )
  end
end
if not FX_win then
  -- Try again
  local number, list = reaper.JS_Window_ListFind("FX: ", false)
  if number > 0 then
    for address in list:gmatch("[^,]+") do
      local hwnd = reaper.JS_Window_HandleFromAddress(address)
      local title = reaper.JS_Window_GetTitle(hwnd)
      if (tracknumber > 0 and (title:match("FX: Track " .. tracknumber) or title:match("FX: Item ") ) ) or
      title:match("FX: Master Track") then
        FX_win = hwnd
        break
      end
    end
  end
end
if FX_win then
  local _, left, top, right, bottom = reaper.JS_Window_GetRect(FX_win)
  local pos_x, pos_y, screen_w, screen_h = reaper.my_getViewport(0, 0, 0, 0, left, top, right, bottom, true)
  local width = right - left
  local height = math.abs(bottom - top)
  left = math.floor((screen_w+pos_x)/2 - width/2)
  top = math.floor((screen_h+pos_y)/2 - height/2)
  reaper.JS_Window_SetPosition( FX_win, left, top, width, height )
end
reaper.defer(function() end)
