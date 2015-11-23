 script_title = "Sort all tracks by color"
 
  reaper.Undo_BeginBlock()
  
function check(tr_col)
  local col_exist = false
  if #tr_colors_t > 0 then
    for j = 1, #tr_colors_t do
      col = tr_colors_t[j]
      if tr_col == col then col_exist = true end
    end
  end  
  return col_exist
end    
  
reaper.PreventUIRefresh(1)
    
if reaper.CountTracks(0) ~= nil then
  tracks_t = {}
  tr_colors_t = {}
  for i = 1,  reaper.CountTracks(0) do
    tr = reaper.GetTrack(0,i-1)
    reaper.SetMediaTrackInfo_Value(tr,'I_FOLDERDEPTH', 0) 
    tr_guid = reaper.GetTrackGUID(tr)
    table.insert(tracks_t,tr_guid )    
    tr_col0 = reaper.GetMediaTrackInfo_Value(tr, 'I_CUSTOMCOLOR')
    if not check(tr_col0) then table.insert(tr_colors_t, tr_col0) end   
  end
  for i = 1, #tr_colors_t do
    reaper.Main_OnCommandEx(40297, 0,0) -- unselect tracks
    tr_color = tr_colors_t[i]
    for j = 1, #tracks_t do
      guid = tracks_t[j]
      tr = reaper.BR_GetMediaTrackByGUID(0,guid)
      if tr ~= nil then
        tr_col0 = reaper.GetMediaTrackInfo_Value(tr, 'I_CUSTOMCOLOR')
        if tr_col0 == tr_color then 
          reaper.SetMediaTrackInfo_Value(tr,'I_SELECTED', 1) 
        end   
      end       
    end
    reaper.Main_OnCommandEx(40337, 0,0) -- cut tracks 
    tr = reaper.GetTrack(0,reaper.CountTracks(0)-1)
    reaper.SetMediaTrackInfo_Value(tr,'I_SELECTED', 1) 
    reaper.Main_OnCommandEx(40058, 0,0) -- paste tracks    
  end
end
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(script_title,0)
