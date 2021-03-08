-- @description Bounce selection (like in Studio One)
-- @author Yaunick
-- @version 1.0
-- @about
--   How it works - download my guide
--   https://drive.google.com/file/d/1BA8blNRakAmM7F5wc3EN_5RpHv-yQPx1/view?usp=sharing

  -------------------------------------------------------------

    render_overlaid_items_into_one_item = true
    render_every_selected_item_to_new_track = false
    mute_original_items = true
    mute_original_tracks = false
    tail_for_every_item = 0
    user_input_for_entering_tail = true
    
    render_in = 2   --- 1 = mono
                    --- 2 = stereo
                    --- 3 = multichannel
                    
  -------------------------------------------------------------
    
  function bla() end
  function nothing()
    reaper.defer(bla)
  end
  
  if (render_overlaid_items_into_one_item ~= true and render_overlaid_items_into_one_item ~= false)
  or (render_every_selected_item_to_new_track ~= true and render_every_selected_item_to_new_track ~= false)
  or (mute_original_items ~= true and mute_original_items ~= false)
  or (mute_original_tracks ~= true and mute_original_tracks ~= false)
  or (not tonumber(tail_for_every_item) or tail_for_every_item < 0)
  or (user_input_for_entering_tail ~= true and user_input_for_entering_tail ~= false)
  or (not tonumber(render_in) or (render_in ~= 1 and render_in ~= 2 and render_in ~= 3))
  then
    reaper.MB('Incorrect values for some line in user settings. Look at the beginning of the script', 'Error',0)
    nothing() return
  end
  
  if reaper.CountSelectedMediaItems(0) == 0 then
    reaper.MB('No items. Please select an item', 'Error',0)
    nothing() return
  end
  
  if user_input_for_entering_tail == true then
    ::START_INPUT::
    retval, retvals_csv = reaper.GetUserInputs
    (
    'Bounce selection (like in Studio One)', 
    1, 
    'Set tail for item(s):', 
    tail_for_every_item
    )
    if not retval then
      nothing() return
    end
    local t_values = {}
    for s in string.gmatch(retvals_csv, "[^,]+") do
      table.insert(t_values,s)
    end
    if #t_values ~= 1 or not tonumber(t_values[1]) or tonumber(t_values[1]) < 0 then
      reaper.MB('Incorrect value. Please enter a valid value', 'Error',0)
      goto START_INPUT
    end
    tail_for_every_item = tonumber(t_values[1])
  end
  
  reaper.Undo_BeginBlock()
  
  local t = {}
  for i=1, reaper.CountSelectedMediaItems(0) do
    t[i] = reaper.GetSelectedMediaItem(0,i-1)
  end
  
  local t_save_tracks = {}
  local save_cur_pos = reaper.GetCursorPosition()
  local strt, nd = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
  
  count = 1
  bool = false
  bool_two = false
  all_done = false
  bool_end = false
 
  ::START::
  
  reaper.Main_OnCommand(40289,0)
 
  reaper.PreventUIRefresh(1)
  
  count_blocks = 0
  
  repeat
    if t[count] then
      item_ome_track = reaper.GetMediaItemTrack(t[count])
      if count_blocks == 0 then
        reaper.SetOnlyTrackSelected(item_ome_track, true)
      end
      reaper.SetMediaItemSelected(t[count], true)
      reaper.UpdateItemInProject(t[count])
      if t[count+1] then
        local item_one_end = 
        reaper.GetMediaItemInfo_Value(t[count],'D_POSITION') +
        reaper.GetMediaItemInfo_Value(t[count],'D_LENGTH')
        item_two_track = reaper.GetMediaItemTrack(t[count+1])
        local item_two_start = 
        reaper.GetMediaItemInfo_Value(t[count+1],'D_POSITION')
        if item_two_start >= item_one_end 
        or item_ome_track ~= item_two_track
        or render_overlaid_items_into_one_item == false
        then
          bool = true
        end
      end
    else
      bool = true
    end
    count = count + 1
    count_blocks = count_blocks + 1
  until bool == true
  
  bool = false

  reaper.Main_OnCommand(40290,0)
  local crnt_start, crnt_end = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
  reaper.GetSet_LoopTimeRange(true, false, crnt_start, crnt_end + tail_for_every_item, false)
  
  local count_mute = {}
  for i=0, reaper.CountSelectedMediaItems(0)-1 do
    count_mute[i+1] = reaper.GetMediaItemInfo_Value
    (reaper.GetSelectedMediaItem(0,i), 'B_MUTE')
  end
 
  reaper.Main_OnCommand(41559,0) -- solo items
 
  for i=0, reaper.CountSelectedMediaItems(0)-1 do
    reaper.SetMediaItemInfo_Value
    (reaper.GetSelectedMediaItem(0,i), 'B_MUTE', count_mute[i+1])
  end
  
  local count_tracks_one = reaper.CountTracks(0)
  
  if render_in == 1 then
    reaper.Main_OnCommand(41721,0) -- render mono
  elseif render_in == 2 then
    reaper.Main_OnCommand(41719,0) -- render stereo
  elseif render_in == 3 then
    reaper.Main_OnCommand(41720,0) -- render multichannel
  end
  
  local count_tracks_two = reaper.CountTracks(0)

  reaper.Main_OnCommand(41560,0) -- unsolo items
  
  if count_tracks_one == count_tracks_two then
    bool_end = true
    goto END
  end
  
  if render_every_selected_item_to_new_track == false then
    if bool_two == false then
      get_new_track = reaper.GetTrack
      (
      0, reaper.GetMediaTrackInfo_Value(item_ome_track, 'IP_TRACKNUMBER') - 2
      )
      bool_two = true
      t_save_tracks[#t_save_tracks+1] = get_new_track
    else
      local get_track_item = reaper.GetTrack
      (
      0, reaper.GetMediaTrackInfo_Value(item_ome_track, 'IP_TRACKNUMBER') - 2
      )
      local item_in_track = reaper.GetTrackMediaItem(get_track_item,0)
      reaper.MoveMediaItemToTrack(item_in_track, get_new_track)
      reaper.DeleteTrack(get_track_item)
    end
  end

  if mute_original_tracks == false then
    if item_ome_track ~= item_two_track 
    or count > #t then
      reaper.SetMediaTrackInfo_Value(item_ome_track,'B_MUTE', 0)
    end
  end
  
  if render_every_selected_item_to_new_track == false then
    if item_ome_track ~= item_two_track then
      bool_two = false
    end
  end
  
  reaper.PreventUIRefresh(-1)
  
  if count <= #t then
    goto START
  end
  
  reaper.PreventUIRefresh(1)
  
  if #t_save_tracks > 0 then
    for i=1, #t_save_tracks do
       reaper.SetTrackSelected(t_save_tracks[i], true)
    end
  end
  
  ::END::
  
  result = #t
  if bool_end == true then
    result = count - count_blocks - 1
    if mute_original_tracks == false then
      reaper.SetMediaTrackInfo_Value(item_ome_track,'B_MUTE', 0)
    end
  end

  if mute_original_items == true then
    for i=1, result do
      reaper.SetMediaItemInfo_Value(t[i], 'B_MUTE', 1)
    end
  end
  
  if bool_end == false then
    reaper.Main_OnCommand(40421,0)
  end
  
  reaper.SetEditCurPos(save_cur_pos,false,false)
  reaper.GetSet_LoopTimeRange(true, false, strt, nd, false)
  
  reaper.PreventUIRefresh(-1)
  
  reaper.Undo_EndBlock('Bounce selection (like in Studio One)', -1)
