-- @description Toggle show editing guide line on item under mouse cursor in Main Window or in MIDI Editor
-- @author amagalma
-- @version 1.57
-- @changelog
--   - Help to install JS_ReaScriptAPI for those who don't have it or have older version than required
--   - Fix bug when changing zoom with only a few tracks visible
-- @about
--   # Displays a guide line on the item under the mouse cursor for easier editing in the Main Window, or a tall line in the focused MIDI Editor
--   - Can be used as a toolbar action or assigned to a key shortcut
--   - Accompanied by helper script to toggle between full height or item height in the arrange view
--   - Set line color inside the script (rgb values 0-255)
--   - When prompted by Reaper, choose to "Terminate instance" and to remember your choice
--   - Requires JS_ReaScriptAPI 1.002 or higher

-- Many thanks to juliansader :)

-------------------------------------------------------------------

-- SET LINE COLOR HERE -- (0-255)
local red, green, blue = 239, 255, 72

-- SET "SNAP GUIDE LINE TO GRID" SUPPORT HERE -- (1 = enabled, 0 = disabled)
local Arrange_snap_support = 1 -- (for arrange view)
local MidiEditor_snap_support = 1 -- (for active midi editor)

-------------------------------------------------------------------

-- Check if JS_ReaScriptAPI >1.002 is installed
if not reaper.APIExists("JS_ReaScriptAPI_Version") then
  noAPI = true
elseif reaper.JS_ReaScriptAPI_Version() < 1.002 then
  oldVersion = true
end
if noAPI or oldVersion then
  if noAPI then
    reaper.MB( "Please, right-click and install 'js_ReaScriptAPI: API functions for ReaScripts'. Then restart Reaper and run the script again. Thanks!", "You need to install the JS_ReaScriptAPI", 0 )
  else
    reaper.MB( "Please, right-click and install the latest version of 'js_ReaScriptAPI: API functions for ReaScripts'. Then restart Reaper and run the script again. Thanks!", "Older JS_ReaScriptAPI version is installed", 0 )
  end
  local ok, err = reaper.ReaPack_AddSetRepository( "ReaTeam Extensions", "https://github.com/ReaTeam/Extensions/raw/master/index.xml", true, 1 )
  if ok then
    reaper.ReaPack_BrowsePackages( "js_ReaScriptAPI" )
  else
    reaper.MB( err, "Something went wrong...", 0)
  end
  return reaper.defer(function() end)
end

local function RGB(r,g,b) 
  return (((b)&0xFF)|(((g)&0xFF)<<8)|(((r)&0xFF)<<16)|(0xFF<<24))
end

-------------------------------------------------------------------

local reaper = reaper
local debug = false
Arrange_snap_support = Arrange_snap_support == 1
MidiEditor_snap_support = MidiEditor_snap_support == 1
local floor = math.floor
local MainHwnd = reaper.GetMainHwnd()
local CurrentWindow
local set_window
local MidiWindow = reaper.MIDIEditor_GetActive()
local midiview = MidiWindow and reaper.JS_Window_FindChildByID(MidiWindow, 0x3E9)
local Foreground = reaper.JS_Window_GetForeground()
if Foreground == MainHwnd then
  set_window = 1
elseif Foreground == MidiWindow then
  set_window = 0
end
local prev_set_window = set_window
local master = reaper.GetMasterTrack(0)
local trackview = reaper.JS_Window_FindChildByID(MainHwnd, 0x3E8)
local _, trackview_w, trackview_h = reaper.JS_Window_GetClientSize( trackview )
local snap = reaper.GetToggleCommandState( 1157 ) == 1
local zoom
local left_button_down, direction_right = false
local midiview_time = 2
local bigLine, prev_x, prev_y, prev_item, track_y, item_h
local bm_size = 0
local cur_view = set_window == 0 and midiview or trackview
local _, scrollposv = reaper.JS_Window_GetScrollInfo( cur_view, "v" )
local _, scrollposh = reaper.JS_Window_GetScrollInfo( cur_view, "h" )
local checkscroll = false
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
  for i = tr_cnt-1, 0, -1 do
    local track = reaper.GetTrack( 0, i )
    if reaper.IsTrackVisible(track, false) then
      last_track = track
      break
    end
  end
  return reaper.GetMediaTrackInfo_Value(last_track, "I_WNDH") + reaper.GetMediaTrackInfo_Value(last_track, "I_TCPY")
end

local vis_tracks_h = visibletracksheight()
local prev_vis_tracks_h = vis_tracks_h

function GetMidiViewMousePositionAndHZoom(MidiEditor, width, x)
  -- x, y must be to client
  local midiview = reaper.JS_Window_FindChildByID( MidiEditor, 0x3E9 )
  local take = reaper.MIDIEditor_GetTake( MidiEditor )
  local guid = reaper.BR_GetMediaItemTakeGUID( take )
  local item = reaper.GetMediaItemTake_Item( take )
  local _, chunk = reaper.GetItemStateChunk( item, "", false )
  local guidfound, editviewfound = false, false
  local leftmost_tick, hzoom, timebase
  local function setvalue(a)
    a = tonumber(a)
    if not leftmost_tick then leftmost_tick = a
    elseif not hzoom then hzoom = a
    else timebase = a
    end
  end
  for line in chunk:gmatch("[^\n]+") do
    if line == "GUID " .. guid then
      guidfound = true
    end
    if (not editviewfound) and guidfound then
      if line:find("CFGEDITVIEW ") then
        line:gsub("([%-%d%.]+)", setvalue, 2)
        editviewfound = true
      end
    end
    if editviewfound then
      if line:find("CFGEDIT ") then
        line:gsub("([%-%d%.]+)", setvalue, 19)
        break
      end
    end
  end
  local start_time, end_time, HZoom = reaper.MIDI_GetProjTimeFromPPQPos( take, leftmost_tick )
  if timebase == 0 or timebase == 4 then
    end_time = reaper.MIDI_GetProjTimeFromPPQPos( take, leftmost_tick + (width - 1 ) / hzoom )
    x = reaper.MIDI_GetProjTimeFromPPQPos( take, leftmost_tick + (x / hzoom) )
  else
    end_time = start_time + (width-1)/hzoom
    x = start_time + (x / hzoom)
  end
  HZoom = (width)/(end_time - start_time)
  return HZoom, x
end

-------------------------------------------------------------------

function main()
  local now = reaper.time_precise()
  local x, y = reaper.GetMousePosition() -- screen

  CurrentWindow = reaper.JS_Window_FromPoint( x, y )
  MidiWindow = reaper.MIDIEditor_GetActive()
  midiview = MidiWindow and reaper.JS_Window_FindChildByID(MidiWindow, 0x3E9)
  if CurrentWindow == trackview then
    
    if now - start >= 0.3 then
      snap = Arrange_snap_support and reaper.GetToggleCommandState( 1157 ) == 1
      bigLine = reaper.GetToggleCommandState( toggleCmd ) == 1
      if bigLine ~= prev_bigLine then
        Msg("Changed guide line size\n")
        prev_bigLine = bigLine
        change = true
      end
      start = now
    end
    
    if set_window ~= 1 then
      checkscroll = false
      if debug then reaper.ClearConsole() end
      Msg("Current window is Main Window\n")
      prev_set_window = set_window
      set_window = 1 -- 1 is Main
      bm_size = 0
      if midiview and prev_set_window == 0 then
        reaper.JS_Composite(midiview, 0, 0, 0, 0, bm, 0, 0, 1, 1, true)
        continue = true
      end
    else  
      checkscroll = true
    end
  
  elseif CurrentWindow == midiview then
    
    if now - start >= 0.3 then
      snap = MidiEditor_snap_support and reaper.MIDIEditor_GetSetting_int( MidiWindow, "snap_enabled" ) == 1
      start = now
    end
  
    if set_window ~= 0 then
      checkscroll = false
      if debug then reaper.ClearConsole() end
      Msg("Current window is MIDI Window\n")
      prev_set_window = set_window
      set_window = 0 -- 0 is MIDI
      bm_size = 0
      if prev_set_window == 1 then 
        reaper.JS_Composite(trackview, 0, 0, 0, 0, bm, 0, 0, 1, 1, true)
      end
    else
      checkscroll = true
    end
  
  end
  
  -- Main Window -----------------------------------------------------------
  if set_window == 1 then
    
    _, scrollposh = reaper.JS_Window_GetScrollInfo( trackview, "h" )
    _, scrollposv = reaper.JS_Window_GetScrollInfo( trackview, "v" )
    vis_tracks_h = visibletracksheight()
    if checkscroll then
      if scrollposv ~= prev_scrollposv or scrollposh ~= prev_scrollposh 
      or vis_tracks_h ~= prev_vis_tracks_h
      then
        prev_vis_tracks_h = vis_tracks_h
        prev_scrollposv = scrollposv
        prev_scrollposh = scrollposh
        prev_scrollpos_time = now
        continue = false
        Msg("Changing arrange view...\n")
        reaper.JS_Composite(trackview, 0, 0, 0, 0, bm, 0, 0, 1, 1, true)
        bm_size = -1
        prev_item = nil
  
      elseif scrollposv == prev_scrollposv
      and scrollposh == prev_scrollposh
      and now - prev_scrollpos_time >= 0.5
      then
        if bm_size == -1 then
          Msg("Finished changing arrange view\n")
          bm_size = 0
          continue = true
          change = true
        end
      end
    else
      prev_scrollposv = scrollposv
      prev_scrollposh = scrollposh
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
            Msg("draw big line at " .. x .. "\n")
            reaper.JS_Composite(trackview, x, 0, 1, (vis_tracks_h < trackview_h and vis_tracks_h or trackview_h), bm, 0, 0, 1, 1, true)
            bm_size = 1
          elseif bm_size == 1 then
            Msg("make line disappear\n")
            reaper.JS_Composite(trackview, 0, 0, 0, 0, bm, 0, 0, 1, 1, true)
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
            reaper.JS_Composite(trackview, x, track_y, 1, item_h, bm, 0, 0, 1, 1, true)
            bm_size = 1
          elseif bm_size == 1 then
            Msg("make line disappear\n")
            reaper.JS_Composite(trackview, 0, 0, 0, 0, bm, 0, 0, 1, 1, true)
            bm_size = 0
          end
        end
        
      end
    end
    
  -- MIDI Editor -----------------------------------------------------------------
  elseif set_window == 0 then

    _, scrollposh = reaper.JS_Window_GetScrollInfo( midiview, "h" )
    if snap and checkscroll then
      if prev_scrollposh and scrollposh ~= prev_scrollposh then
        prev_scrollposh = scrollposh
        prev_scrollpos_time = now
        continue = false
        Msg("Changing midi view...\n")
        reaper.JS_Composite(midiview, 0, 0, 0, 0, bm, 0, 0, 1, 1, true)
        bm_size = -1
      elseif scrollposh == prev_scrollposh
      and now - prev_scrollpos_time >= 0.35
      then
        if bm_size == -1 then
          Msg("Finished changing midi view\n")
          bm_size = 0
          continue = true
        end
      end
    else
      prev_scrollposv = scrollposv
      prev_scrollposh = scrollposh
    end
    
    local _, mwidth, mheight = reaper.JS_Window_GetClientSize( midiview )
    local xcl, ycl = reaper.JS_Window_ScreenToClient(midiview, x, y)
    if ycl >= 64 and ycl <= mheight then --and xcl >= 0 and xcl < mwidth then
      if x ~= prev_x or continue then
        
        continue = false
        local prev_mouse_pos = prev_x
        local current_mouse_pos = x
        prev_x = x
        
        if snap then
          local nosnap, _, activetempo = false
          local zoom, mouse_pos = GetMidiViewMousePositionAndHZoom(MidiWindow, mwidth, xcl)
          local mgrid, swing, notelen = reaper.MIDI_GetGrid( reaper.MIDIEditor_GetTake( MidiWindow ) )
          notelen = notelen == 0 and mgrid or notelen
          _, _, _, _, activetempo = reaper.GetTempoTimeSigMarker( 0, reaper.FindTempoTimeSigMarker( 0, mouse_pos ) )
          activetempo = activetempo == 0 and reaper.GetProjectTimeSignature2( 0 ) or activetempo
          local note_duration = notelen *( 60 / activetempo )
          local _, pgrid = reaper.GetSetProjectGrid( 0, false, 0, 0, 0 )
          mgrid = mgrid/4
          if mgrid ~= pgrid then
            reaper.SetProjectGrid( 0, mgrid )
          end
          local mouse_state = reaper.JS_Mouse_GetState( 255 )
          if mouse_state == 9 then
            nosnap = true
          elseif mouse_state == 1 then -- only left-click is held down
            if prev_mouse_pos and prev_mouse_pos < current_mouse_pos and (not left_button_down) then
              Msg("drawing towards the right\n")
              left_button_down = true
              direction_right = true
            elseif prev_mouse_pos and prev_mouse_pos > current_mouse_pos and (not left_button_down) then
              Msg("drawing towards the left\n")
              left_button_down = true
            end
          else
            left_button_down = false
            direction_right = nil
          end 
          local closest_division = reaper.BR_GetClosestGridDivision(mouse_pos)
          local diff = direction_right and
                     ( closest_division - mouse_pos + note_duration ) * zoom
                  or ( closest_division - mouse_pos ) * zoom
          x = nosnap and x or floor(x + diff + 0.5)
        end
        
        x, y = reaper.JS_Window_ScreenToClient(midiview, x, 0)
        Msg("draw line in Midi Editor at " ..x .. "\n")
        reaper.JS_Composite(midiview, x, 64, 1, mheight-64, bm, 0, 0, 1, 1, true)
        bm_size = 1      
      end
      
    else
      if bm_size == 1 then
        Msg("make line in Midi Editor disappear\n")
        reaper.JS_Composite(midiview, 0, 0, 0, 0, bm, 0, 0, 1, 1, true)
        bm_size = 0
      end
        
    end
  end
  reaper.defer(main)
end

-------------------------------------------------------------------

reaper.atexit(exit) 
main()
