-- @description Toggle show editing guide line on item under mouse cursor in Main Window or in MIDI Editor
-- @author amagalma
-- @version 1.40
-- @about
--   # Displays a guide line on the item under the mouse cursor for easier editing in the Main Window, or a tall line in the focused MIDI Editor
--   - Can be used as a toolbar action or assigned to a key shortcut
--   - Accompanied by helper script to toggle between full height or item height
--   - Set line color inside the script (rgb values 0-255)
--   - When prompted by Reaper, choose to "Terminate instance" and to remember your choice
--   - Requires JS_ReaScriptAPI 1.000 and higher
-- @changelog - support snap line to grid in arrange view (support is enabled/disabled inside the script)
-- - experimental support snap line to grid in midi view (support is enabled/disabled inside the script)
-- - code improvements

-- Many thanks to juliansader :)

-------------------------------------------------------------------

-- SET LINE COLOR HERE -- (0-255)
local red, green, blue = 234, 254, 67

-- SET SNAP LINE TO GRID SUPPORT HERE -- (1 = enabled, 0 = disabled)
local snap_support = 1 -- (for arrange view)
local MidiEditor_snap_support = 0 -- (experimental)

-------------------------------------------------------------------

-- Check if JS_ReaScriptAPI >1.000 is installed
if not reaper.APIExists("JS_ReaScriptAPI_Version") then
  local answer = reaper.MB( "You have to install JS_ReaScriptAPI for this script to work. Would you like to open the relative web page in your browser?", "JS_ReaScriptAPI not installed", 4 )
  if answer == 6 then
    local url = "https://forum.cockos.com/showthread.php?t=212174"
     reaper.CF_ShellExecute( url )
  end
  return reaper.defer(function() end)
else
  local version = reaper.JS_ReaScriptAPI_Version()
  if version < 1 then
    reaper.MB( "Your JS_ReaScriptAPI version is " .. version .. "\nPlease update to version 1.000 or higher.", "Older version is installed", 0 )
    return reaper.defer(function() end)
  end
end

local function RGB(r,g,b) 
  return (((b)&0xFF)|(((g)&0xFF)<<8)|(((r)&0xFF)<<16)|(0xFF<<24))
end

-------------------------------------------------------------------

local reaper = reaper
local debug = false
snap_support = snap_support == 1
MidiEditor_snap_support = MidiEditor_snap_support == 1
local floor, huge = math.floor, math.huge
local MainHwnd = reaper.GetMainHwnd()
local Foreground = reaper.JS_Window_GetForeground()
local MidiWindow, midiview
local master = reaper.GetMasterTrack(0)
local trackview = reaper.JS_Window_FindChildByID(MainHwnd, 1000)
local _, trackview_w, trackview_h = reaper.JS_Window_GetClientSize( trackview )
local snap = reaper.GetToggleCommandState( 1157 ) == 1
local zoom, vis_tracks_h
local midiview_time = 2
local bm_size, bigLine, prev_x, prev_y, prev_item, track_y, item_h, set_window
local _, scrollposv = reaper.JS_Window_GetScrollInfo( trackview, "v" )
local _, scrollposh = reaper.JS_Window_GetScrollInfo( trackview, "h" )
local prev_scrollposv, prev_scrollposh = scrollposv, scrollposh
local bm = reaper.JS_LICE_CreateBitmap(true, 1, 1)
red = red and (red < 0 and 0 or (red > 255 and 255 or red)) or 0
green = green and (green < 0 and 0 or (green > 255 and 255 or green)) or 0
blue = blue and (blue < 0 and 0 or (blue > 255 and 255 or blue)) or 0
reaper.JS_LICE_Clear(bm, RGB(red, green, blue))
local toggleCmd = reaper.NamedCommandLookup('_RS723f1ed6da61cd868278d4d78b1c1531edc946f4') -- Script: Toggle guide line size 
local bigLine = reaper.GetToggleCommandState( toggleCmd ) == 1
local prev_bigLine = reaper.GetToggleCommandState( toggleCmd ) == 1
local start = reaper.time_precise()
local prev_scrollpos_time = start
local continue = true
local change = false
-- Refresh toolbar
local _, _, section, cmdID = reaper.get_action_context()
reaper.SetToggleCommandState( section, cmdID, 1 )
reaper.RefreshToolbar2( section, cmdID )

-------------------------------------------------------------------

local function isINF(value)
  return value == huge or value == -huge
end

local function isNAN(value)
  return value ~= value
end

function Msg(string)
  if debug then return reaper.ShowConsoleMsg(string) end
end

function exit()
  if bm then reaper.JS_LICE_DestroyBitmap(bm) end
  reaper.SetToggleCommandState( section, cmdID, 0 )
  reaper.RefreshToolbar2( section, cmdID )
  reaper.defer(function() end)
end

function visibletracksheight()
  local tr_cnt = reaper.CountTracks( 0 )
  if tr_cnt < 1 then return 0 end
  local last_track = 0
  for i = 0, tr_cnt-1 do
    local track = reaper.GetTrack( 0, i )
    if reaper.IsTrackVisible(track, false) then
      last_track = track
    end
  end
  local max = reaper.GetMediaTrackInfo_Value(last_track, "I_WNDH") + reaper.GetMediaTrackInfo_Value(last_track, "I_TCPY")
  return max <= trackview_h and max or trackview_h
end

-------------------------------------------------------------------

function main()
  local now = reaper.time_precise()
  local x, y = reaper.GetMousePosition() -- screen
  
  if now - start >= 0.3 then
    snap = snap_support and reaper.GetToggleCommandState( 1157 ) == 1
    bigLine = reaper.GetToggleCommandState( toggleCmd ) == 1
    Foreground = reaper.JS_Window_GetForeground()
    if bigLine ~= prev_bigLine then
      Msg("Changed guide line size\n")
      prev_bigLine = bigLine
      change = true
    end
    start = now
  end
  
  if Foreground == MainHwnd or Foreground == trackview then
    if set_window ~= 1 then
      if debug then reaper.ClearConsole() end
      Msg("Foreground is Main Window\n")
      set_window = 1 -- 1 is Main
      bm_size = 0
    end
  else
    MidiWindow = reaper.MIDIEditor_GetActive()
    midiview = reaper.JS_Window_FindChildByID(MidiWindow, 1001)
    if MidiWindow and (Foreground == MidiWindow or Foreground == midiview) then
      if set_window ~= 0 then
        if debug then reaper.ClearConsole() end
        Msg("Foreground is MIDI Window\n")
        set_window = 0 -- 0 is MIDI
        bm_size = -1
      end
    end
  end
  
  -- Main Window -----------------------------------------------------------
  if set_window == 1 then
  
    _, scrollposh = reaper.JS_Window_GetScrollInfo( trackview, "h" )
    _, scrollposv = reaper.JS_Window_GetScrollInfo( trackview, "v" )
    if scrollposv ~= prev_scrollposv or scrollposh ~= prev_scrollposh then
      prev_scrollposv = scrollposv
      prev_scrollposh = scrollposh
      prev_scrollpos_time = now
      continue = false
      if bm_size ~= 3 then
        Msg("Changing arrange view...\n")
        reaper.JS_Composite(trackview, 0, 0, 0, 0, bm, 0, 0, 1, 1)
        bm_size = 3
        prev_item = nil
      end
    elseif scrollposv == prev_scrollposv
    and scrollposh == prev_scrollposh
    and now - prev_scrollpos_time >= 0.3
    then
      if bm_size == 3 then
        Msg("Finished changing arrange view\n")
        bm_size = 0
        continue = true
        change = true
      end
    end
    
    if continue then
      if change or (x ~= prev_x or y ~= prev_y) then
        prev_x, prev_y = x, y
        change = false
        zoom = reaper.GetHZoomLevel()
        
        if bigLine then
          _, trackview_w, trackview_h = reaper.JS_Window_GetClientSize( trackview )
          x, y = reaper.JS_Window_ScreenToClient(trackview, x, y)
          if 0 <= x and x <= trackview_w and 0 <= y and y <= trackview_h then
            if snap then
              local mouse_pos = reaper.BR_PositionAtMouseCursor( false )
              local diff = floor((reaper.SnapToGrid( 0, mouse_pos ) - mouse_pos)*zoom + 0.5)
              x = x + diff
            end
            vis_tracks_h = visibletracksheight()
            Msg("draw big line at " .. x .. "\n")
            reaper.JS_Composite(trackview, x, 0, 1, vis_tracks_h, bm, 0, 0, 1, 1)
            bm_size = 1
          elseif bm_size == 1 then
            Msg("make line disappear\n")
            reaper.JS_Composite(trackview, 0, 0, 0, 0, bm, 0, 0, 1, 1)
            bm_size = 0
          end
        
        else
          local item = reaper.GetItemFromPoint( x, y, true )
          if item then
            if item ~= prev_item then
              prev_item = item
              track_y = reaper.GetMediaTrackInfo_Value( reaper.GetMediaItem_Track( item ), "I_TCPY" )
                    + reaper.GetMediaItemInfo_Value( item, "I_LASTY" ) -- client
              item_h = reaper.GetMediaItemInfo_Value( item, "I_LASTH" )
            end
            x, y = reaper.JS_Window_ScreenToClient(trackview, x, y)
            if snap then
              local mouse_pos = reaper.BR_PositionAtMouseCursor( false )
              local diff = floor((reaper.SnapToGrid( 0, mouse_pos ) - mouse_pos)*zoom + 0.5)
              x = x + diff
            end
            Msg("draw line at " .. x .. "\n")
            reaper.JS_Composite(trackview, x, track_y, 1, item_h, bm, 0, 0, 1, 1)
            bm_size = 1
          elseif bm_size == 1 then
            Msg("make line disappear\n")
            reaper.JS_Composite(trackview, 0, 0, 0, 0, bm, 0, 0, 1, 1)
            bm_size = 0
          end
        end
        
      end
    end
    
  -- MIDI Editor -----------------------------------------------------------------
  elseif set_window == 0 and MidiWindow then
  
    _, scrollposh = reaper.JS_Window_GetScrollInfo( midiview, "h" )
    _, scrollposv = reaper.JS_Window_GetScrollInfo( midiview, "v" )
    if scrollposv ~= prev_scrollposv or scrollposh ~= prev_scrollposh then
      prev_scrollposv = scrollposv
      prev_scrollposh = scrollposh
      prev_scrollpos_time = now
      continue = false
      if bm_size ~= 4 then
        Msg("Changing midi view...\n")
        reaper.JS_Composite(midiview, 0, 0, 0, 0, bm, 0, 0, 1, 1)
        bm_size = 4
      end
    elseif scrollposv == prev_scrollposv
    and scrollposh == prev_scrollposh
    and now - prev_scrollpos_time >= 0.3
    then
      if bm_size == 4 then
        Msg("Finished changing midi view\n")
        bm_size = 0
        continue = true
      end
    end
  
    if continue or x ~= prev_x then
      prev_x = x
      local _, mwidth, mheight = reaper.JS_Window_GetClientSize( midiview )
      local xcl, ycl = reaper.JS_Window_ScreenToClient(midiview, x, y)
      if xcl >= 0 and xcl <= mwidth and ycl >= 64 and ycl <= mheight then
        snap = MidiEditor_snap_support and reaper.MIDIEditor_GetSetting_int( MidiWindow, "snap_enabled" ) == 1
        if snap then
          if reaper.JS_Mouse_GetState( 1 ) ~= 1 and reaper.JS_Mouse_GetState( 2 ) ~= 2 then
            local _, left, top, right, bottom = reaper.JS_Window_GetClientRect( midiview )
            local cursor = reaper.JS_Mouse_GetCursor()
            reaper.JS_Mouse_SetCursor( nil )
            reaper.JS_Mouse_SetPosition( left, y )
            reaper.BR_GetMouseCursorContext()
            local start_time = reaper.BR_GetMouseCursorContext_Position()
            reaper.JS_Mouse_SetPosition( right - 1, y )
            reaper.BR_GetMouseCursorContext()
            local end_time = reaper.BR_GetMouseCursorContext_Position()
            reaper.JS_Mouse_SetPosition( x, y )
            reaper.JS_Mouse_SetCursor( cursor )
            midiview_time = end_time - start_time
          end
          reaper.BR_GetMouseCursorContext()
          local mouse_pos = reaper.BR_GetMouseCursorContext_Position()
          zoom = mwidth/(midiview_time)
          local mgrid = reaper.MIDI_GetGrid( reaper.MIDIEditor_GetTake( MidiWindow ) )
          local _, pgrid = reaper.GetSetProjectGrid( 0, false, 0, 0, 0 )
          mgrid = mgrid/4
          if mgrid ~= pgrid then
            reaper.SetProjectGrid( 0, mgrid )
          end
          -- local diff = (reaper.SnapToGrid( 0, mouse_pos ) - mouse_pos)*zoom
          local diff = (reaper.BR_GetClosestGridDivision(mouse_pos) - mouse_pos)*zoom
          x = floor(x + diff)
          x = (isNAN(x) or isINF(x)) and 0 or x
          --y = (isNAN(y) or isINF(y)) and 0 or y
        end
        x, y = reaper.JS_Window_ScreenToClient(midiview, x, 0)
        Msg("draw line in Midi Editor at " ..x .. "\n")
        reaper.JS_Composite(midiview, x, 64, 1, mheight-64, bm, 0, 0, 1, 1)
        bm_size = 1
      else
        if bm_size == 1 then
          Msg("make line in Midi Editor disappear\n")
          reaper.JS_Composite(midiview, 0, 0, 0, 0, bm, 0, 0, 1, 1)
          bm_size = 0
        end
      end
    end
    
  end
  reaper.defer(main)
end

-------------------------------------------------------------------

reaper.atexit(exit) 
main()
