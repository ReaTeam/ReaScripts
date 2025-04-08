-- @description Toggle fixed item lanes (convert takes to lanes) and keep the same track height
-- @author amagalma
-- @version 1.00
-- @donation https://www.paypal.me/amagalma
-- @about Like the native action, but keeps the same track height. It can be used as an action of a custom tcp button.


local is_new_value,_,_,_,mode,resolution,val = reaper.get_action_context()

if (not is_new_value) and resolution == -1 and mode == -1 and val == -1 then
-- one track version
  local x, y = reaper.GetMousePosition()
  local track = reaper.GetTrackFromPoint( x, y )
  if not track then track = reaper.GetSelectedTrack( 0, 0 ) end
  if track then
    local tracks = {}
    local track_cnt = reaper.CountSelectedTracks( 0 )
    if track_cnt > 1 then
      for i = 1, track_cnt-1 do
        local track = reaper.GetSelectedTrack( 0, i )
        tracks[i] = track
      end
      reaper.SetOnlyTrackSelected( track )
    end
    reaper.Undo_BeginBlock2( 0 )
    reaper.PreventUIRefresh( 1 )
    local height = reaper.GetMediaTrackInfo_Value( track, "I_TCPH" )
    reaper.Main_OnCommand(42660, 0) -- Toggle fixed item lanes (convert takes to lanes)
    local lanes = reaper.GetMediaTrackInfo_Value( track, "I_FREEMODE" ) == 2 and
                  reaper.GetMediaTrackInfo_Value( track, "I_NUMFIXEDLANES" ) or 1
    reaper.SetMediaTrackInfo_Value( track, "I_HEIGHTOVERRIDE", height/lanes )
    reaper.TrackList_AdjustWindows( false )
    if track_cnt > 1 then
      for i = 1, #tracks do
        reaper.SetTrackSelected( tracks[i], true )
      end
    end
    reaper.PreventUIRefresh( -1 )
    reaper.Undo_EndBlock2( 0, "set/unset track fixed lanes" , 1|4 )
    return
  else
    return reaper.defer(function() end)
  end
else
-- one or more tracks version
  local track_cnt = reaper.CountSelectedTracks( 0 )
  if track_cnt ~= 0 then
    local tracks = {}
    for i = 0, track_cnt-1 do
      local track = reaper.GetSelectedTrack( 0, i )
      tracks[track] = reaper.GetMediaTrackInfo_Value( track, "I_TCPH" )
    end
    reaper.Undo_BeginBlock2( 0 )
    reaper.PreventUIRefresh( 1 )
    reaper.Main_OnCommand(42660, 0) -- Toggle fixed item lanes (convert takes to lanes)
    for track, height in pairs(tracks) do
      local lanes = reaper.GetMediaTrackInfo_Value( track, "I_FREEMODE" ) == 2 and
                    reaper.GetMediaTrackInfo_Value( track, "I_NUMFIXEDLANES" ) or 1
      reaper.SetMediaTrackInfo_Value( track, "I_HEIGHTOVERRIDE", height/lanes )
    end
    reaper.TrackList_AdjustWindows( false )
    reaper.PreventUIRefresh( -1 )
    reaper.Undo_EndBlock2( 0, "set/unset track fixed lanes" , 1|4 )
    return
  else
    return reaper.defer(function() end)
  end
end
