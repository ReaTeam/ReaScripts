script_title = "Implode mono tracks session to stereo items"
 reaper.Undo_BeginBlock()

function main(x) reaper.Main_OnCommand(x,0) end

if reaper.CountTracks(0) ~= nil then
  tracks_t = {}
  for i = 1, reaper.CountTracks(0) do
    tr = reaper.GetTrack(0,i-1)
    table.insert(tracks_t, reaper.BR_GetMediaTrackGUID(tr))    
  end  
end

if tracks_t ~= nil then
  for i = 1, #tracks_t do
    guid = tracks_t[i]
    tr = reaper.BR_GetMediaTrackByGUID(0, guid)
    if tr ~= nil then
      _, tr_name = reaper.GetSetMediaTrackInfo_String(tr, 'P_NAME', '', false)
      tr_name_last_sym = string.upper(string.sub(tr_name,-1))
      if tr_name_last_sym == 'L' or tr_name_last_sym == 'R' then 
      -- if there is L or R check for name matching
        for j = 1, #tracks_t do
          guid1 = tracks_t[j]
          tr2 = reaper.BR_GetMediaTrackByGUID(0, guid1)
          if tr2 ~= nil then
            _, tr_name2 = reaper.GetSetMediaTrackInfo_String(tr2, 'P_NAME', '', false)
            if tr2~= tr and 
              string.sub(tr_name,0,string.len(tr_name)-1) == string.sub(tr_name2,0,string.len(tr_name2)-1) then      
              main(40289) -- unselect all items
              main(40297) -- unselect all tracks
              reaper.SetTrackSelected(tr, true)
              reaper.SetTrackSelected(tr2, true)
              main(40421) -- select all items in sel tracks
              main(40438) -- implode selected items into takes
              if reaper.CountTrackMediaItems(tr) ~= nil then
                for k = 1, reaper.CountTrackMediaItems(tr) do
                  item = reaper.GetTrackMediaItem(tr, k-1)
                  reaper.SetMediaItemInfo_Value(item, 'B_ALLTAKESPLAY', 1)
                end
              end              
              main(reaper.NamedCommandLookup('_XENAKIOS_PANTAKESOFITEMSYM')) -- pan takes symmetrically
              
              -- delete second track
              main(40297) -- unselect all tracks
              reaper.SetTrackSelected(tr2, true)
              main(40337) -- cut track
            end
          end  
        end  
      end  
    end  
  end 
end
reaper.TrackList_AdjustWindows(false)

reaper.Undo_EndBlock(script_title,0)
