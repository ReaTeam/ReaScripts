-- @description Mixdown selection (like in Studio One)
-- @author Yaunick
-- @version 1.0
-- @about
--   How it works - download my guide
--   https://drive.google.com/file/d/1BA8blNRakAmM7F5wc3EN_5RpHv-yQPx1/view?usp=sharing

  ----Set some parameters-------------------------------------------------------
    Tail_for_new_track = 4  --Sec
    Solo_for_new_track = false
    Insert_new_track_at_end_of_all_tracks = false
    Auto_unsolo_all_tracks_before_render = false
    Auto_unmute_all_tracks_before_render = false
  ------------------------------------------------------------------------------
  
  ----Color for new send track, if no existed-----------------------------------
    ---enter 0 for R and G and B to disable coloring---
    R = 0
    G = 0
    B = 0
  ------------------------------------------------------------------------------
  
  function bla() end
  function nothing()
    reaper.defer(bla)
  end
  
  if (Solo_for_new_track ~= false and Solo_for_new_track ~= true)
  or (Insert_new_track_at_end_of_all_tracks ~= false and Insert_new_track_at_end_of_all_tracks ~= true)
  or (Auto_unsolo_all_tracks_before_render ~= false and Auto_unsolo_all_tracks_before_render ~= true)
  or (Auto_unmute_all_tracks_before_render ~= false and Auto_unmute_all_tracks_before_render ~= true)
  or Tail_for_new_track ~= tonumber(Tail_for_new_track) 
  or (not tonumber(R) or not tonumber(G) or not tonumber(B))
  or (R < 0 or G < 0 or B < 0)
  then
    reaper.MB('Incorrect value for "Tail_for_new_track "' .. 
    'or "Solo_for_new_track" or "Insert_new_track_at_end_of_all_tracks" ' ..
    'or "Auto_unsolo_all_tracks_before_render" or "Auto_unmute_all_tracks_before_render" or "RGB" parameters. ' ..
    'Look at the beginning of the script', 'Error',0) 
    nothing() return 
  end
  
  local test_SWS = reaper.CF_EnumerateActions
  if not test_SWS then
    reaper.MB('Please install or update SWS extension', 'Error', 0) nothing() return
  end

  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(1)
    
    if reaper.CountSelectedMediaItems(0) == 0 then reaper.MB('No items. Please select an item', 'Error', 0) nothing() return end
  
    ---Save selected items and unselect muted selected items-------
    local t = {}
    local cnt_t_save = 1
    for i=reaper.CountSelectedMediaItems(0)-1,0,-1 do
      local item = reaper.GetSelectedMediaItem(0,i)
      if item then
        t[cnt_t_save] = reaper.GetSelectedMediaItem(0,i)
        cnt_t_save = cnt_t_save + 1
        if reaper.GetMediaItemInfo_Value(item,'B_MUTE') == 1 then
          reaper.SetMediaItemSelected(item,false)
        end
      end     
    end
    ---------------------------------------------------------------
    
    ---Check unmuted items----------------------------------------------------------------------
    if reaper.CountSelectedMediaItems(0) == 0 then
      reaper.MB('No unmuted items. Please select an unmuted item', 'Error', 0) nothing() return 
    end
    --------------------------------------------------------------------------------------------
    
    ---Save track selecton-----------------------------
    local tr_tab = {}
    if reaper.CountSelectedTracks(0) > 0 then
      for i=0, reaper.CountSelectedTracks(0)-1 do
        tr_tab[i+1] = reaper.GetSelectedTrack(0,i)
      end
    end
    ---------------------------------------------------
  
    ----Save TS and cursor positions---------------------------------------------------
    local cur_pos = reaper.GetCursorPosition()
    local save_start, save_end = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
    -----------------------------------------------------------------------------------
    
    reaper.Main_OnCommand(40290,0) --set TS to items
    ----Set TS to items + Tail--------------------------------------------------------
    local new_start, new_end = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
    reaper.GetSet_LoopTimeRange(true, false, new_start, new_end+Tail_for_new_track, false)
    ----------------------------------------------------------------------------------
  
    reaper.Main_OnCommand(41559,0) --solo items
    
    reaper.InsertTrackAtIndex(0, false) --insert track for render
    reaper.SetMediaTrackInfo_Value(reaper.GetTrack(0,0), 'I_FOLDERDEPTH', 1) --set folder state for track for render
    reaper.SetOnlyTrackSelected(reaper.GetTrack(0,0), true) --select global folder track only
    
    local unsolo_bool = false
    if Auto_unsolo_all_tracks_before_render == true then
      reaper.Main_OnCommand(40340,0) --unsolo all tracks
      unsolo_bool = true
    end
    if Auto_unmute_all_tracks_before_render == true then
      reaper.Main_OnCommand(40339,0) --unmute all tracks
    end
      
    local count_tr_br = reaper.CountTracks(0) --count tracks before render
    
    ----Render----------------------------------------------------
    reaper.Main_OnCommand(41719,0) --render stereo (selected area)
    --------------------------------------------------------------
    
    local count_tr_ar = reaper.CountTracks(0) --count tracks after render
    
    
    if count_tr_br < count_tr_ar then --if render is not canceled
      reaper.DeleteTrack(reaper.GetTrack(0,1)) --delete folder track
      local sel_tr = reaper.GetSelectedTrack(0,0)
      reaper.GetSetMediaTrackInfo_String(sel_tr, 'P_NAME', 'Mixdown', true) --named new track as 'Mixdown'
      if R == 0 and G == 0 and B == 0 then
        nothing()
      else
        color = reaper.ColorToNative(R,G,B)|0x1000000
        reaper.SetTrackColor(sel_tr,color)
      end
      if Solo_for_new_track == true then
        if unsolo_bool == false then
          reaper.Main_OnCommand(40340,0)
        end
        reaper.SetMediaTrackInfo_Value(sel_tr, 'I_SOLO', 2)
      end
      if Insert_new_track_at_end_of_all_tracks == true then
        reaper.ReorderSelectedTracks(count_tr_ar,0)
        reaper.Main_OnCommand(reaper.NamedCommandLookup("_XENAKIOS_TVPAGEEND"),0)
      else
        reaper.Main_OnCommand(reaper.NamedCommandLookup("_XENAKIOS_TVPAGEHOME"),0)
      end
    elseif count_tr_br == count_tr_ar then --if render is canceled
      reaper.DeleteTrack(reaper.GetTrack(0,0)) --delete folder track
      ---Restore selection of tracks------------
      if tr_tab ~= {} then 
        for i=1, #tr_tab do
          reaper.SetTrackSelected(tr_tab[i], true)
        end
      end
    ------------------------------------------
    end
      
    ---Restore TS and cursor positions-----------------------------------
    reaper.GetSet_LoopTimeRange(true, false, save_start, save_end, false)
    reaper.SetEditCurPos(cur_pos, false, false)
    ---------------------------------------------------------------------
  
    ---Restore selection of items------------
    for i=1, #t do
      reaper.SetMediaItemSelected(t[i], true)
    end
    -----------------------------------------
    
    reaper.Main_OnCommand(41560,0) --unsolo items
    
  reaper.UpdateArrange()
  reaper.Undo_EndBlock('Mixdown items selection', -1)
  reaper.PreventUIRefresh(-1)
