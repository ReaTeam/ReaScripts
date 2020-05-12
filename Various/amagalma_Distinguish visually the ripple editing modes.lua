-- @description Distinguish visually the ripple editing modes
-- @author amagalma
-- @version 1.20
-- @changelog
--   -   fixed bug: original tracks staying highlighted when dragging items across tracks
-- @link https://forum.cockos.com/showthread.php?t=236201
-- @about
--   # Colors the items that will move in ripple editing modes
--   - Color can be set inside the script
--   - Script reports on/off state so that it can be set to a toolbar button
--   - If prompted by Reaper, choose "Terminate instances" and "Remember"
--   - Requires JS_ReaScriptAPI extension >= v1.002
--   - Inspired by nikolalkc Colored Rippling extension


------------------------------------------------------


-- SET COLOR HERE -- (0-255)
local red, green, blue, alpha = 0, 255, 0, 13


------------------------------------------------------

local reaper, floor = reaper, math.floor
local debug = false

-- Check JS_ReaScriptAPI availability
local required_version, ok  = "1.002", false
local js_api = { "reaper_js_ReaScriptAPI32.dll", "reaper_js_ReaScriptAPI32.dylib", "reaper_js_ReaScriptAPI64.dll", "reaper_js_ReaScriptAPI64.dylib", "reaper_js_ReaScriptAPI64.so" }
local sep = reaper.GetOS():find("Win") and "\\" or "/"
local ext_path = reaper.GetResourcePath() .. sep .. "UserPlugins" .. sep
for i = 1, 5 do
  if reaper.file_exists( ext_path .. js_api[i] ) then
    js_api = ext_path .. js_api[i]
    break
  end
end
if type(js_api) ~= "table" then
  local entry = reaper.ReaPack_GetOwner( js_api )
  js_api = ({reaper.ReaPack_GetEntryInfo( entry )})[7]
  reaper.ReaPack_FreeEntry( entry )
  ok = reaper.ReaPack_CompareVersions( js_api, required_version ) >= 0
  if not ok then
    reaper.MB( "Your installed version is v" .. js_api .. ".\n\nPlease, right-click and install the latest version of 'js_ReaScriptAPI: API functions for ReaScripts'. Then restart Reaper and run the script again. Thanks!", "JS_ReaScriptAPI v" .. required_version .. " is required", 0 )
  end
else
  reaper.MB( "Please, right-click and install 'js_ReaScriptAPI: API functions for ReaScripts'. Then restart Reaper and run the script again. Thanks!", "You need to install the JS_ReaScriptAPI", 0 )
end
if not ok then
  local ok, err = reaper.ReaPack_AddSetRepository( "ReaTeam Extensions", "https://github.com/ReaTeam/Extensions/raw/master/index.xml", true, 1 )
  if ok then reaper.ReaPack_BrowsePackages( "js_ReaScriptAPI" )
  else reaper.MB( err, "Something went wrong...", 0) end
  return reaper.defer(function() end)
else
  required_version, ok, js_api, sep, ext_path, entry = nil, nil, nil, nil, nil, nil
end

local function Msg(str)
  if debug then
    reaper.ShowConsoleMsg(str)
  end
end

------------------------------------------------------

-- Sanitize values
red = red and (red < 0 and 0 or (red > 255 and 255 or red)) or 0
green = green and (green < 0 and 0 or (green > 255 and 255 or green)) or 255
blue = blue and (blue < 0 and 0 or (blue > 255 and 255 or blue)) or 0
alpha = alpha and (alpha < 0 and 0 or (alpha > 255 and 1 or alpha/255)) or 0.051
local color = (((blue)&0xFF)|(((green)&0xFF)<<8)|(((red)&0xFF)<<16)|(0xFF<<24))
local color_trackview = (((blue*alpha)&0xFF)|(((green*alpha)&0xFF)<<8)|(((red*alpha)&0xFF)<<16)|(0x01<<24))

-- Refresh toolbar
local _, _, section, cmdID = reaper.get_action_context()
reaper.SetToggleCommandState( section, cmdID, 1 )
reaper.RefreshToolbar2( section, cmdID )

local MainHwnd = reaper.GetMainHwnd()
local tracks = {}
local bmps = {}
local p_trackitems_cnt = {}

local ripple
if reaper.GetToggleCommandState( 41991 ) == 1 then ripple = 2 -- ripple editing all tracks
elseif reaper.GetToggleCommandState( 41990 ) == 1 then ripple = 1 -- ripple editing per-track
else ripple = 0
end

local trackview = reaper.JS_Window_FindChildByID(MainHwnd, 0x3E8)
local _, width_trackview, height_trackview = reaper.JS_Window_GetClientSize( trackview )
width_trackview = width_trackview + 17

local start = reaper.time_precise()
local checksizetime = start
local checkrippletime = start
local p_item, p_item_cnt = 0, -1
local huge = math.huge
local first_pos
local st, en, arr_duration, track_cnt
local setDelay, prevMinTime, prevMaxTime, prevBitmaps = reaper.JS_Composite_Delay( trackview, 0.0035, 0.105, 30 )

---------------------------------------------------------------

function main()
  local give_space = false
  local now = reaper.time_precise()

  -- Check ripple mode state
  local r_state
  if now - checkrippletime >= 0.35 then
    if reaper.GetToggleCommandState( 41991 ) == 1 then r_state = 2
    elseif reaper.GetToggleCommandState( 41990 ) == 1 then r_state = 1
    else r_state = 0
    end
    if ripple ~= r_state then
      local msg = r_state == 0 and "Ripple disabled" or ( r_state == 1 and 
      "Ripple per track\n\n" or "Ripple all tracks\n\n" )
      Msg(msg)
      ripple = r_state
      for k in pairs(bmps) do
        reaper.JS_LICE_DestroyBitmap( bmps[k] )
        bmps[k] = nil
      end
      for k in pairs(tracks) do
        tracks[k] = nil
      end
    end
  end
  
  -- If in any ripple mode, get common values
  if r_state ~= 0 then
    st, en = reaper.GetSet_ArrangeView2( 0, false, 0, 0 )
    arr_duration = en - st
    track_cnt = reaper.CountTracks( 0 )
    
    -- Check every now and then if arrange size changed and update values
    if now - checksizetime >= 1 then
      _, width_trackview, height_trackview = reaper.JS_Window_GetClientSize( trackview )
      width_trackview = width_trackview + 17
      checksizetime = now
    end
  end
  
  -- Ripple per-track
  if r_state == 1 then

    for i = 0, track_cnt-1 do
      local track = reaper.GetTrack( 0, i )
      local id = reaper.GetMediaTrackInfo_Value( track, "IP_TRACKNUMBER" )
      local y_pos = reaper.GetMediaTrackInfo_Value( track, "I_TCPY" )
                                                                     
      if reaper.IsTrackVisible( track, false ) and y_pos < height_trackview then
        local item_cnt = reaper.CountTrackMediaItems( track )
        if p_trackitems_cnt[id] ~= item_cnt then
          if bmps[id] then
            reaper.JS_LICE_DestroyBitmap( bmps[id] ) 
            bmps[id] = nil
          end
          tracks[id] = nil
          p_trackitems_cnt[id] = item_cnt
        end
        if item_cnt > 0 then
          local paint = false
          local x_pos
          for j = 0, item_cnt-1 do
            local item = reaper.GetTrackMediaItem( track, j )
            if reaper.IsMediaItemSelected( item ) then
              x_pos = floor( ( ( reaper.GetMediaItemInfo_Value( item, "D_POSITION" ) - st ) / arr_duration ) * width_trackview )
              x_pos = x_pos > 0 and ( x_pos < width_trackview and x_pos or width_trackview ) or 0
              paint = true
              break
            end
          end
          local track_h = reaper.GetMediaTrackInfo_Value( track, "I_WNDH" )
          
          if paint then
            if ( not tracks[id] ) then
              Msg( string.format("paint track %i : %i, %i", id, x_pos, y_pos) .. "\n")
              give_space = true
              bmps[id] = reaper.JS_LICE_CreateBitmap( true, 1, 1 )
              reaper.JS_LICE_Clear( bmps[id], color_trackview )
              reaper.JS_Composite( trackview, x_pos, y_pos, width_trackview-x_pos, track_h, bmps[id], 0, 0, 1, 1, true )
              tracks[id] = x_pos
            elseif x_pos ~= tracks[id] then
              Msg( string.format("re-paint track %i : %i, %i", id, x_pos, y_pos) .. "\n")
              give_space = true
              reaper.JS_Window_InvalidateRect( trackview, tracks[id], y_pos, width_trackview, y_pos + track_h, false )
              reaper.JS_Composite( trackview, x_pos, y_pos, width_trackview-x_pos, track_h, bmps[id], 0, 0, 1, 1, true )
              tracks[id] = x_pos
            end
          else
            if tracks[id] then
              Msg( string.format("erase track %i", id) .. "\n" )
              give_space = true
              if bmps[id] then
                reaper.JS_LICE_DestroyBitmap( bmps[id] ) 
                bmps[id] = nil
              end
              --reaper.JS_Window_InvalidateRect( trackview, tracks[id], y_pos, width_trackview, y_pos + track_h, false )
              tracks[id] = nil
            end
          end
        
        end
      else    
        break
      end
    end  
    
  -- Ripple all-tracks
  elseif r_state == 2 then

    local item_cnt = reaper.CountSelectedMediaItems( 0 )
    local first_item = reaper.GetSelectedMediaItem( 0, 0 )
    if item_cnt ~= p_item_cnt or first_item ~= p_item then
      first_pos = huge
    end
    for i = 0, item_cnt-1 do
      local item = reaper.GetSelectedMediaItem( 0, i )
      local item_pos = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
      if item_pos < first_pos then first_pos = item_pos end
    end

    for i = 0, track_cnt-1 do
      local track = reaper.GetTrack( 0, i )
      local y_pos = reaper.GetMediaTrackInfo_Value( track, "I_TCPY" )
      local id = reaper.GetMediaTrackInfo_Value( track, "IP_TRACKNUMBER" )
                                                                     
      if reaper.IsTrackVisible( track, false ) and y_pos < height_trackview then
        local item_cnt = reaper.CountTrackMediaItems( track )
        if p_trackitems_cnt[id] ~= item_cnt then
          if bmps[id] then
            reaper.JS_LICE_DestroyBitmap( bmps[id] ) 
            bmps[id] = nil
          end
          tracks[id] = nil
          p_trackitems_cnt[id] = item_cnt
        end
        if item_cnt > 0 then
          local paint = false
          local x_pos
          for j = 0, item_cnt-1 do
            local item = reaper.GetTrackMediaItem( track, j )
            local item_pos = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
            if item_pos >= first_pos then
              x_pos = floor( ( ( reaper.GetMediaItemInfo_Value( item, "D_POSITION" ) - st ) / arr_duration ) * width_trackview )
              x_pos = x_pos > 0 and ( x_pos < width_trackview and x_pos or width_trackview ) or 0
              paint = true
              break
            end
          end
          local track_h = reaper.GetMediaTrackInfo_Value( track, "I_WNDH" )
          
          if paint then
            if ( not tracks[id] ) then
              bmps[id] = reaper.JS_LICE_CreateBitmap( true, 1, 1 )
              reaper.JS_LICE_Clear( bmps[id], color_trackview )
              reaper.JS_Composite( trackview, x_pos, y_pos, width_trackview-x_pos, track_h, bmps[id], 0, 0, 1, 1, true )
              tracks[id] = x_pos
            elseif x_pos ~= tracks[id] then
              reaper.JS_Window_InvalidateRect( trackview, tracks[id], y_pos, width_trackview, y_pos + track_h, false )
              reaper.JS_Composite( trackview, x_pos, y_pos, width_trackview-x_pos, track_h, bmps[id], 0, 0, 1, 1, true )
              tracks[id] = x_pos
            end
          else
            if tracks[id] then
              if bmps[id] then
                reaper.JS_LICE_DestroyBitmap( bmps[id] ) 
                bmps[id] = nil
              end
              --reaper.JS_Window_InvalidateRect( trackview, tracks[id], y_pos, width_trackview, y_pos + track_h, false )
              tracks[id] = nil
            end
          end
        
        end
      else    
        break   
      end
    end

  end

  reaper.defer(main)
  
  if give_space then
    Msg("\n\n")
  end
  
end

function Exit()
  for k in pairs(bmps) do
    reaper.JS_LICE_DestroyBitmap( bmps[k] )
  end
  reaper.UpdateArrange()
  reaper.SetToggleCommandState( section, cmdID, 0 )
  reaper.RefreshToolbar2( section, cmdID )
  if setDelay then
    if prevMinTime == -1 or prevMaxTime == -1 then
      prevMinTime, prevMaxTime, prevBitmaps = 0, 0, 2
    end
    local ok, newMinTime, newMaxTime, newBitmaps = reaper.JS_Composite_Delay( trackview, prevMinTime, prevMaxTime, prevBitmaps )
    if ok then
      Msg(string.format("\nRestored JS_Composite_Delay values to:\nMinTime %s -> %s\nMaxTime %s -> %s" ..
      "\nBitmaps %s -> %s", newMinTime, prevMinTime, newMaxTime, prevMaxTime, newBitmaps, prevBitmaps))
    else
      Msg("\nCould not restore the JS_Composite_Delay values\n")
    end
  end
  Msg("\n\n== script end ==\n\n")
  return reaper.defer(function() end)
end

reaper.atexit(Exit)
main()
