--[[
@description Scroll TCP to track currently edited in active MIDI editor
@version 0.5.0
@author Ben 'Talagan' Babut
@donation https://www.paypal.com/donate/?business=3YEZMY9D6U8NC&no_recurring=1&currency_code=EUR
@license MIT
@provides
  [main=main,midi_editor] .
@changelog
  Initial release.
@about
  It may happen that you are working in the MIDI editor and want to access the edited track TCP's but unfortunately, it's not on screen, you
  don't want to scroll by yourself, and you don't want to break your track selection.

  This action can be used to scroll the TCP to have the currently edited MIDI take's track at the top, so you can interract with the track
  controls and keep your track selection and the rest of your current screen layout intact.

  There's a good chance that if you need this, you'll use it as a small brick in custom actions in conjunction with other ones
  (scroll, resize, fit, etc).
--]]

local function CheckReapack(func_name, api_name, search_string)
  if not reaper.APIExists(func_name) then
    local answer = reaper.MB( api_name .. " is required and you need to install it.\z
      Right-click the entry in the next window and choose to install.",
      api_name .. " not installed", 0 )
    reaper.ReaPack_BrowsePackages( search_string )
    return false
  end
  return true
end

if not CheckReapack("JS_ReaScriptAPI_Version",   "JS_ReaScriptAPI",  "js_ReaScriptAPI")     then return end


-- Using X-Raym's X-Raym_Scroll vertically to first selected track.lua
-- Thanks Raymond !
function ScrollTrackToTop( track )
  reaper.PreventUIRefresh( 1 )

  local track_tcpy = reaper.GetMediaTrackInfo_Value( track, "I_TCPY" )

  local mainHWND    = reaper.GetMainHwnd()
  local windowHWND  = reaper.JS_Window_FindChildByID(mainHWND, 1000)
  local scroll_retval, scroll_position, scroll_pageSize, scroll_min, scroll_max, scroll_trackPos = reaper.JS_Window_GetScrollInfo( windowHWND, "v" )
  reaper.JS_Window_SetScrollPos( windowHWND, "v", track_tcpy + scroll_position )

  reaper.PreventUIRefresh( -1 )
end

local function proceed()

  local me    = reaper.MIDIEditor_GetActive()
  if not me then return end

  local take  = reaper.MIDIEditor_GetTake(me);
  if not take then return end

  local track = reaper.GetMediaItemTake_Track(take);
  if not track then return end

  ScrollTrackToTop(track);

end

proceed();

