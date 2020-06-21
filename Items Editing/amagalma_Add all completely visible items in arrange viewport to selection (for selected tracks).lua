-- @description Add all completely visible items in arrange viewport to selection (for selected tracks)
-- @author amagalma
-- @version 1.00
-- @link https://forum.cockos.com/showthread.php?p=2307538#post2307538
-- @donation https://www.paypal.me/amagalma
-- @about
--   # Adds all items that are completely visible in the arrange viewport to selection
--
--   - Works for all items on selected tracks that are completely visible
--   - Requires JS_ReaScriptAPI

if not reaper.APIExists( "JS_Window_GetClientSize" ) then
  reaper.MB( "Please, right-click and install 'js_ReaScriptAPI: API functions for ReaScripts'. Then restart Reaper and run the script again. Thanks!", "You need to install the JS_ReaScriptAPI", 0 )
  local ok, err = reaper.ReaPack_AddSetRepository( "ReaTeam Extensions", "https://github.com/ReaTeam/Extensions/raw/master/index.xml", true, 1 )
  if ok then reaper.ReaPack_BrowsePackages( "js_ReaScriptAPI" )
  else reaper.MB( err, "Something went wrong...", 0)
  end
  return reaper.defer(function() end)
end

local tracks_cnt = reaper.CountSelectedTracks( 0 )
if tracks_cnt == 0 then return end
reaper.PreventUIRefresh(1)
local _, _, tcp_height = reaper.JS_Window_GetClientSize( 
      reaper.JS_Window_FindChildByID( reaper.GetMainHwnd(), 0x3E8 ) )
local start_time, end_time = reaper.GetSet_ArrangeView2( 0, false, 0, 0 )
local prev_tr_visible = false
for tr = 0, tracks_cnt-1 do
  local track = reaper.GetSelectedTrack(0, tr)
  local track_pos = reaper.GetMediaTrackInfo_Value( track, "I_TCPY" )
  local track_h = track_pos + reaper.GetMediaTrackInfo_Value( track, "I_TCPH" )
  if reaper.IsTrackVisible( track, false ) and
  track_pos >= 0 and track_h <= tcp_height then
    prev_tr_visible = true
    local item_cnt = reaper.GetTrackNumMediaItems( track )
    local prev_visible = false
    for i = 0, item_cnt-1 do
      local item = reaper.GetTrackMediaItem( track, i )
      local item_start = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
      local item_end = item_start + reaper.GetMediaItemInfo_Value( item, "D_LENGTH" )
      if item_start >= start_time and item_end <= end_time then
        reaper.SetMediaItemSelected( item, true )
        prev_visible = true
      else
        if prev_visible then break end
      end
    end
  else
    if prev_tr_visible then break end
  end
end
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
reaper.Undo_OnStateChange( "Add all items in viewport to selection" )
