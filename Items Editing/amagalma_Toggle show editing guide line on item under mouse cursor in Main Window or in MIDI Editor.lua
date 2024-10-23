-- @description Toggle show editing guide line on item under mouse cursor in Main Window or in MIDI Editor
-- @author amagalma
-- @version 1.87
-- @changelog - Slightly improved performance (about 16-17% less CPU)
-- @link https://forum.cockos.com/showthread.php?t=234369
-- @screenshot Screenshot https://stash.reaper.fm/38839/amagalma_Toggle%20show%20editing%20guide%20line%20on%20item%20under%20mouse%20cursor%20in%20Main%20Window%20or%20in%20MIDI%20Editor.gif
-- @donation https://www.paypal.me/amagalma
-- @about
--   # Displays a guide line on the item under the mouse cursor for easier editing in the Main Window, or a tall line in the focused MIDI Editor
--    - Can be used as a toolbar action or assigned to a key shortcut
--    - Accompanied by helper script to toggle between full height or item height in the arrange view
--    - Ability to have an additional guide line showing on the timeline (set inside the script)
--    - Set line colors inside the script (rgb values 0-255)
--    - Set minimum/maximum additional line height inside the script
--    - When prompted by Reaper, choose to "Terminate instance" and to remember your choice
--    - Requires JS_ReaScriptAPI 1.002 or higher
--    - Many thanks to juliansader :)

-- Many thanks to juliansader :)

-------------------------------------------------------------------

-- SET "SNAP GUIDE LINE TO GRID" SUPPORT HERE -- (1 = enabled, 0 = disabled)
local Arrange_snap_support = 1 -- (for arrange view)
local MidiEditor_snap_support = 1 -- (for active midi editor)

-- SET LINE COLOR HERE -- (0-255)
local red, green, blue = 240, 240, 180

--------

-- ADDITIONAL GUIDE LINE SHOWING ON THE TIMELINE -- (1 = enabled, 0 = disabled)
local timeline_guide = 1

-- MINIMUM HEIGHT OF ADDITIONAL LINE
local timeline_guide_height = 15 -- pixels

-- MAXIMUM HEIGHT OF ADDITIONAL LINE IN RELATION TO TIMELINE HEIGHT
local timeline_guide_height_max = 0.25 -- (timeline height * timeline_guide_height_max)

-- SET ADDITIONAL LINE COLOR HERE -- (0-255)
local red2, green2, blue2 = 165, 165, 135

-------------------------------------------------------------------

-- Check JS_ReaScriptAPI availability
if reaper.APIExists( "JS_ReaScriptAPI_Version") then
  local version = reaper.JS_ReaScriptAPI_Version()
  if version < 1.002 then
    reaper.MB( "Installed JS_ReaScriptAPI version is v" .. version .. "\n\nPlease, update, restart Reaper and run the script again. Thanks!", "Required version: >=1.002", 0 )
    return reaper.defer(function() end)
  end
else
  reaper.MB( "Please, install JS_ReaScriptAPI for this script to function. Thanks!", "JS_ReaScriptAPI is not installed", 0 )
  return reaper.defer(function() end)
end


-------------------------------------------------------------------

local debug = false
Arrange_snap_support = Arrange_snap_support == 1
MidiEditor_snap_support = MidiEditor_snap_support == 1
timeline_guide = timeline_guide == 1
local floor, ceil, abs = math.floor, math.ceil, math.abs
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
local timeline = reaper.JS_Window_FindChildByID(MainHwnd, 0x3ED)
local _, _, timeline_h = reaper.JS_Window_GetClientSize( timeline )
local timeline_max = math.floor(timeline_h*timeline_guide_height_max)
if timeline_max > timeline_guide_height then
  timeline_guide_height = timeline_max
end
local snap = reaper.GetToggleCommandState( 1157 ) == 1
local zoom
local left_button_down, direction_right = false
local midiview_time = 2
local bigLine, prev_x, prev_y, prev_item, prev_track, track_y, item_h
local bm_size = 0
local cur_view = set_window == 0 and midiview or trackview
local _, scrollposv = reaper.JS_Window_GetScrollInfo( cur_view, "v" )
local _, scrollposh = reaper.JS_Window_GetScrollInfo( cur_view, "h" )
local checkscroll = false
local prev_scrollposv, prev_scrollposh = scrollposv, scrollposh
red = red and (red < 0 and 0 or (red > 255 and 255 or red)) or 0
green = green and (green < 0 and 0 or (green > 255 and 255 or green)) or 0
blue = blue and (blue < 0 and 0 or (blue > 255 and 255 or blue)) or 0
red2 = red2 and (red2 < 0 and 0 or (red2 > 255 and 255 or red2)) or 0
green2 = green2 and (green2 < 0 and 0 or (green2 > 255 and 255 or green2)) or 0
blue2 = blue2 and (blue2 < 0 and 0 or (blue2 > 255 and 255 or blue2)) or 0
local RGB = (((blue)&0xFF)|(((green)&0xFF)<<8)|(((red)&0xFF)<<16)|(0xFF<<24))
local RGB2 = (((blue2)&0xFF)|(((green2)&0xFF)<<8)|(((red2)&0xFF)<<16)|(0xFF<<24))
local bm = reaper.JS_LICE_CreateBitmap(true, 1, 1)
reaper.JS_LICE_Clear(bm, RGB)
local bm2
if timeline_guide then
  bm2 = reaper.JS_LICE_CreateBitmap(true, 1, 1)
  reaper.JS_LICE_Clear(bm2, RGB2)
end
local toggleCmd = reaper.NamedCommandLookup('_RS723f1ed6da61cd868278d4d78b1c1531edc946f4') -- Script: Toggle guide line size 
local bigLine = reaper.GetToggleCommandState( toggleCmd ) == 1
local prev_bigLine = reaper.GetToggleCommandState( toggleCmd ) == 1
local start = reaper.time_precise()
local prev_scrollpos_time = start
local continue = true
local change = false
local start_item_pos, start_take_offs, start_x
local moving_item, moving_take
-- Refresh toolbar
local _, _, section, cmdID = reaper.get_action_context()
reaper.SetToggleCommandState( section, cmdID, 1 )
reaper.RefreshToolbar2( section, cmdID )

-------------------------------------------------------------------

local function Msg(string)
  if debug then return reaper.ShowConsoleMsg(string) end
end

local function round(num)
  if num >= 0 then return floor(num + 0.5)
  else return ceil(num - 0.5)
  end
end

local function exit()
  if bm then reaper.JS_LICE_DestroyBitmap(bm) end
  if bm2 then reaper.JS_LICE_DestroyBitmap(bm2) end
  reaper.SetToggleCommandState( section, cmdID, 0 )
  reaper.RefreshToolbar2( section, cmdID )
  reaper.defer(function() end)
end

local function PositionAtMouseCursor(x, y )
  local _, left, _, right = reaper.JS_Window_GetClientRect( trackview ) -- without scrollbars
  return reaper.GetSet_ArrangeView2( 0, false, left, right ) +
                   (x + reaper.JS_Window_ScreenToClient( trackview, 0, 0 )) / reaper.GetHZoomLevel()
end

local function visibletracksheight()
  local tr_cnt = reaper.CountTracks( 0 )
  if tr_cnt < 1 then return 0 end
  local last_track
  for i = tr_cnt-1, 0, -1 do
    local track = reaper.GetTrack( 0, i )
    if reaper.IsTrackVisible(track, false) then
      last_track = track
      break
    end
  end
  return ( last_track and reaper.GetMediaTrackInfo_Value(last_track, "I_WNDH") + reaper.GetMediaTrackInfo_Value(last_track, "I_TCPY") or 0 )
end

local vis_tracks_h = visibletracksheight()
local prev_vis_tracks_h = vis_tracks_h

local function GetMidiViewMousePositionAndHZoom(MidiEditor, width, x)
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


local function in_arrange(x)
  return (0 <= x and x < trackview_w)
end
-------------------------------------------------------------------

local function main()
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
      if timeline_guide then
        _, _, timeline_h = reaper.JS_Window_GetClientSize( timeline )
      end
      if bigLine then
        _, trackview_w, trackview_h = reaper.JS_Window_GetClientSize( trackview )
      end
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
      elseif prev_set_window == 0 then
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
        continue = true
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
        prev_track = nil

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

      local grabbing = reaper.JS_Mouse_GetState( 1 ) & 1 == 1
      if not grabbing then
        moving_item, moving_take = reaper.GetItemFromPoint( x, y, true )
      end
      if moving_item and grabbing then
        if not start_item_pos then
          start_item_pos = reaper.GetMediaItemInfo_Value( moving_item, "D_POSITION")
        end
        if moving_take and not start_take_offs then
          start_take_offs = reaper.GetMediaItemTakeInfo_Value( moving_take, "D_STARTOFFS" )
        end
        if not start_x then
          if snap then
            local mouse_pos = PositionAtMouseCursor( x, y )
            local diff = floor((reaper.SnapToGrid( 0, mouse_pos ) - mouse_pos)*zoom + 0.5)
            start_x = reaper.JS_Window_ScreenToClient(trackview, x, y) + diff
          else
            start_x = reaper.JS_Window_ScreenToClient(trackview, x, y)
          end
        end
      else
        if start_item_pos then start_item_pos,start_x = false,false end
        if start_take_offs then start_take_offs,start_x = false,false end
      end

      if change or (x ~= prev_x or y ~= prev_y) then
        prev_x, prev_y = x, y
        change = false
        zoom = reaper.GetHZoomLevel()
        local x_cl, y_cl = reaper.JS_Window_ScreenToClient(trackview, x, y)


        if in_arrange(x_cl) and 0 <= y_cl and y_cl <= trackview_h then
          if snap then
            local mouse_pos = PositionAtMouseCursor( x, y )
            local diff = floor((reaper.SnapToGrid( 0, mouse_pos ) - mouse_pos)*zoom + 0.5)
            x_cl = x_cl + diff
          end

          local edit, _, flag = reaper.GetItemEditingTime2()
          if edit ~= -666 and start_item_pos then
            if flag == 4 then
              local new_pos = start_x + floor((reaper.GetMediaItemInfo_Value( moving_item, "D_POSITION") -
                     start_item_pos) * zoom + 0.5)
              if in_arrange(new_pos) then
                x_cl = new_pos
              else
                start_item_pos,start_x = false,false
              end
            elseif flag == 8 and moving_take then
              local new_pos = start_x - floor((reaper.GetMediaItemTakeInfo_Value( moving_take, "D_STARTOFFS" ) -
                     start_take_offs) * zoom + 0.5)
              if in_arrange(new_pos) then
                x_cl = new_pos
              else 
                start_take_offs,start_x = false, false
              end
            end
          end

          if bigLine then
            Msg("draw big line at " .. x_cl .. "\n")
            reaper.JS_Composite(trackview, x_cl, 0, 1, (vis_tracks_h < trackview_h and vis_tracks_h or trackview_h), bm, 0, 0, 1, 1, true)
          else
            if moving_item then
              local par_track = reaper.GetMediaItem_Track( moving_item )
              if moving_item ~= prev_item or par_track ~= prev_track then
                prev_item = moving_item
                prev_track = par_track
                track_y = reaper.GetMediaTrackInfo_Value( par_track, "I_TCPY" )
                      + reaper.GetMediaItemInfo_Value( moving_item, "I_LASTY" ) -- client
                item_h = reaper.GetMediaItemInfo_Value( moving_item, "I_LASTH" )
              end
              Msg("draw line at " .. x_cl .. "\n")
              reaper.JS_Composite(trackview, x_cl, track_y, 1, item_h, bm, 0, 0, 1, 1, true)
            else
              Msg("make line disappear\n")
              reaper.JS_Composite(trackview, 0, 0, 0, 0, bm, 0, 0, 1, 1, true)
              bm_size = 0
            end
          end

          if timeline_guide then
            reaper.JS_Composite(timeline, x_cl, timeline_h-timeline_guide_height, 1, timeline_guide_height, bm2, 0, 0, 1, 1, true)
          end

          bm_size = 1

        elseif bm_size == 1 then
          Msg("make line disappear\n")
          reaper.JS_Composite(trackview, 0, 0, 0, 0, bm, 0, 0, 1, 1, true)
          if timeline_guide then
            reaper.JS_Composite(timeline, 0, 0, 0, 0, bm2, 0, 0, 1, 1, true)
          end
          bm_size = 0
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
          local closest_division, diff = 0, 0
          local nosnap, _, activetempo = false
          local zoom, mouse_pos = GetMidiViewMousePositionAndHZoom(MidiWindow, mwidth, xcl)
          local mgrid, swing, notelen = reaper.MIDI_GetGrid( reaper.MIDIEditor_GetTake( MidiWindow ) )
          notelen = notelen == 0 and mgrid or notelen
          _, _, _, _, activetempo = reaper.GetTempoTimeSigMarker( 0, reaper.FindTempoTimeSigMarker( 0, mouse_pos ) )
          activetempo = activetempo == 0 and reaper.GetProjectTimeSignature2( 0 ) or activetempo
          local note_duration = notelen *( 60 / activetempo )

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

          if swing == 0 then

            local _, pgrid = reaper.GetSetProjectGrid( 0, false, 0, 0, 0 )
            mgrid = mgrid/4
            if mgrid ~= pgrid then
              reaper.SetProjectGrid( 0, mgrid )
            end
            closest_division = reaper.BR_GetClosestGridDivision(mouse_pos)
            diff = direction_right and
                                 ( closest_division - mouse_pos + note_duration ) * zoom
                              or ( closest_division - mouse_pos ) * zoom
          else

            local QN = reaper.TimeMap_timeToQN_abs( 0, mouse_pos )
            QN = direction_right and QN + mgrid or QN
            local QN_grid = floor( QN / mgrid )
            if QN_grid % 2 ~= 0 then QN_grid = QN_grid - 1 end
            local swing_pos = QN_grid * mgrid + mgrid * ( 0.5 * swing + 1)
            if abs( round( QN ) - QN ) > abs( QN - swing_pos ) then
              closest_division = reaper.TimeMap_QNToTime_abs(0, swing_pos)
            else
              closest_division = reaper.TimeMap_QNToTime_abs(0, round(QN))
            end
            diff = ( closest_division - mouse_pos ) * zoom
          end

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
