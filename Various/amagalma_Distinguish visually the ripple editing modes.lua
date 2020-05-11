-- @description Distinguish visually the ripple editing modes
-- @author amagalma
-- @version 1.10
-- @changelog
--   - Changed behavior: In both ripple modes affected items are colored. No change of timeline color
-- @about
--   # Colors the the affected items in ripple editing modes
--   - Color can be set inside the script
--   - Script reports on/off state so that it can be set to a toolbar button
--   - Requires JS_ReaScriptAPI extension >v1.002
--   - Inspired by nikolalkc Colored Rippling extension


------------------------------------------------------


-- SET COLOR HERE -- (0-255)
local red, green, blue, alpha = 0, 255, 0, 13


------------------------------------------------------

local reaper, floor = reaper, math.floor
local debug = false

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

local function Msg(str)
  if debug then
    reaper.ShowConsoleMsg(str)
  end
end

------------------------------------------------------

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

local ripple
if reaper.GetToggleCommandState( 41991 ) == 1 then ripple = 2 -- ripple editing all tracks
elseif reaper.GetToggleCommandState( 41990 ) == 1 then ripple = 1 -- ripple editing per-track
else ripple = 0
end

local trackview = reaper.JS_Window_FindChildByID(MainHwnd, 0x3E8)
local _, width_trackview, height_trackview = reaper.JS_Window_GetClientSize( trackview )
width_trackview = width_trackview + 17
local _, left_trackview, top_trackview, right_trackview, bottom_trackview = reaper.JS_Window_GetRect( trackview )

---------------------------------------------------------------

local start = reaper.time_precise()
local checksizetime = start
local checkrippletime = start
local p_item, p_item_cnt = 0, -1
local first_pos

function main()
  local give_space = false
  local now = reaper.time_precise()

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
        reaper.JS_LICE_DestroyBitmap( bmps[k])
      end
      for k in pairs(tracks) do
        tracks[k] = nil
      end
    end
  end
  
  if r_state == 1 then

    local st, en = reaper.GetSet_ArrangeView2( 0, false, 0, 0 )
    local arr_duration = en - st
    local track_cnt = reaper.CountTracks( 0 )
    for i = 0, track_cnt-1 do
      local track = reaper.GetTrack( 0, i )
      local y_pos = reaper.GetMediaTrackInfo_Value( track, "I_TCPY" )
                                                                     
      if reaper.IsTrackVisible( track, false ) and y_pos < height_trackview then
        local item_cnt = reaper.CountTrackMediaItems( track )
        if item_cnt > 0 then
          local id = reaper.GetMediaTrackInfo_Value( track, "IP_TRACKNUMBER" )
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
              reaper.JS_LICE_Clear( bmps[id], color_trackview) -- 0x012F2F2F )
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
              reaper.JS_Window_InvalidateRect( trackview, tracks[id], y_pos, width_trackview, y_pos + track_h, false )
              tracks[id] = nil
            end
          end
        
        end
      else    
        break
      end
    end  
    
  elseif r_state == 2 then
     
    local st, en = reaper.GetSet_ArrangeView2( 0, false, 0, 0 )
    local arr_duration = en - st
    local item_cnt = reaper.CountSelectedMediaItems( 0 )
    local first_item = reaper.GetSelectedMediaItem( 0, 0 )
    if item_cnt ~= p_item_cnt or first_item ~= p_item then
      first_pos = math.huge
    end
    for i = 0, item_cnt-1 do
      local item = reaper.GetSelectedMediaItem( 0, i )
      local item_pos = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
      if item_pos < first_pos then first_pos = item_pos end
    end

    local track_cnt = reaper.CountTracks( 0 )
    for i = 0, track_cnt-1 do
      local track = reaper.GetTrack( 0, i )
      local y_pos = reaper.GetMediaTrackInfo_Value( track, "I_TCPY" )
                                                                     
      if reaper.IsTrackVisible( track, false ) and y_pos < height_trackview then
        local item_cnt = reaper.CountTrackMediaItems( track )
        if item_cnt > 0 then
          local id = reaper.GetMediaTrackInfo_Value( track, "IP_TRACKNUMBER" )
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
              reaper.JS_LICE_Clear( bmps[id], color_trackview) -- 0x012F2F2F )
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
              reaper.JS_Window_InvalidateRect( trackview, tracks[id], y_pos, width_trackview, y_pos + track_h, false )
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
    reaper.JS_LICE_DestroyBitmap( bmps[k])
  end
  reaper.UpdateArrange()
  reaper.SetToggleCommandState( section, cmdID, 0 )
  reaper.RefreshToolbar2( section, cmdID )
  Msg("\n== script end ==\n\n")
  return reaper.defer(function() end)
end

reaper.atexit(Exit)
main()
