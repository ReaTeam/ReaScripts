-- 1. make sure that "silently increment filenames" is CHECKED
-- 2. Render settings: 
--    Render Master mix
--    wildcards - $project (to prevent overwriting)
--    Save render settings ("Save changes and close").
-- 3. Run script.
-- 4. Check your render queue.

sel_track_guid_t = {}
reaper.PreventUIRefresh(1)
count_sel_tracks = reaper.CountSelectedTracks(0)
if count_sel_tracks ~= nil then 
  for i = 1, count_sel_tracks do
    sel_track = reaper.GetSelectedTrack(0, i-1)
    sel_track_guid = reaper.BR_GetMediaTrackGUID(sel_track)
    table.insert(sel_track_guid_t, sel_track_guid)
  end
end    

if sel_track_guid_t ~= nil then
  for i = 1, #sel_track_guid_t do
    reaper.Main_OnCommand(40297, 0) -- unselect all tracks
    reaper.Main_OnCommand(40341, 0) -- mute all tracks
    sel_track_guid = sel_track_guid_t[i]
    sel_track = reaper.BR_GetMediaTrackByGUID(0, sel_track_guid)
    reaper.SetMediaTrackInfo_Value(sel_track, "I_SELECTED", 1)
    reaper.SetMediaTrackInfo_Value(sel_track, "B_MUTE", 0)
    reaper.SetMediaTrackInfo_Value(sel_track, "I_SOLO", 0)
    send_track = reaper.GetParentTrack(sel_track)
    reaper.SetMediaTrackInfo_Value(send_track, "I_SELECTED", 1)
    reaper.SetMediaTrackInfo_Value(send_track, "B_MUTE", 0)
    reaper.SetMediaTrackInfo_Value(send_track, "I_SOLO", 0)
    reaper.UpdateArrange()
    reaper.Main_OnCommand(41823, 0) -- add to render queue
  end  
end
 
count_tracks = reaper.CountTracks(0)
if count_tracks ~= nil then
 for i =1, count_tracks do
  track = reaper.GetTrack(0, i-1)
  if track ~= nil then
    reaper.SetMediaTrackInfo_Value(track, "I_SELECTED", 0)
    reaper.SetMediaTrackInfo_Value(track, "B_MUTE", 0)
    reaper.SetMediaTrackInfo_Value(track, "I_SOLO", 0)
  end
 end 
end

reaper.MB(#sel_track_guid_t.." files added to render queue", "", 0)
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
