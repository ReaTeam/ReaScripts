-- Dynamic Mixer --
-- see http://forum.cockos.com/showthread.php?t=166554
--[[ 
 * @version 1.0
 * @changelog September 16 2015
 *  initial Lua release by spk77
 *
 * @version 1.01
 * @changelog September 29 2015
 *   nofish:
 *   + muted tracks and muted items detection
 *   + record armed tracks detection
 *   + make track always visible (even if muted) and show parents if trackname has #AV suffix
 *   + automatically show receiving tracks and their parents
 *
 * @version 1.02
 * @changelog September 30 2015
 *   nofish:
 *   + script can be assigned to a toolbar button (lights when active), press again to exit
 *   + MCP track view is restored on exit (thanks spk77)
--]]



function msg(m)
  reaper.ShowConsoleMsg(tostring(m) .. "\n")
end


-- save initially hidden tracks (for restoring at script exit)
local hidden_tracks_table = {} -- init table
local function Save_hidden_tracks (hidden_track_table)
  for i = 1, reaper.CountTracks(0) do
    track_id = reaper.GetTrack(0, i-1) -- track_id from track index
    if not reaper.IsTrackVisible(track_id, true) then -- if track is not visible in MCP...
      hidden_tracks_table[#hidden_tracks_table + 1] = track_id -- ...store this track to end of table
    end
  end
end

-- show all tracks in MCP and hide the initially hidden ones again
local function Restore_hidden_tracks (hidden_track_table)
  SWS_show_all_tracks_MCP_ID = reaper.NamedCommandLookup("_SWSTL_SHOWALLMCP") -- get Show all tracks in MCP cmd ID
  reaper.Main_OnCommand (SWS_show_all_tracks_MCP_ID,0) -- show all tracks in MCP
  -- msg(#hidden_tracks_table)
  for i=1, #hidden_tracks_table do -- run through stored table ("#hidden_tracks_table" means "length of hidden_tracks_table")
    -- reaper.ShowConsoleMsg("Stored track pointer " .. i .. " :")
    -- msg(hidden_tracks_table[i])
    reaper.SetMediaTrackInfo_Value(hidden_tracks_table[i], "B_SHOWINMIXER", 0) -- ...hide the track
    reaper.TrackList_AdjustWindows(false)
  end
end

function do_at_exit()
-- set toolbar button to off
reaper.SetToggleCommandState(section_ID, cmd_ID, 0);
reaper.RefreshToolbar2(section_ID, cmd_ID);
-- restore initially hidden tracks
Restore_hidden_tracks (hidden_track_table)
end

----------
-- Init --
----------

Save_hidden_tracks (hidden_track_table)

local item_found = false -- (Just an example how to create a local variable outside of a function.)
                         -- These are called upvalues. A function that uses upvalues is called a closure.
                         -- http://lua-users.org/wiki/ScopeTutorial

local last_proj_change_count = reaper.GetProjectStateChangeCount(0)
local last_edit_cursor_pos = reaper.GetCursorPosition()

-- set toolbar button to on
is_new_value,filename,section_ID,cmd_ID,mode,resolution,val = reaper.get_action_context()
-- state = reaper.GetToggleCommandStateEx(section_ID, cmd_ID); 
reaper.SetToggleCommandState(section_ID, cmd_ID, 1);
reaper.RefreshToolbar2(section_ID, cmd_ID);

-- 


-----------------------------
-- on_project_state_change --
-----------------------------
--  this is called when the project state changes

function on_project_state_change(edit_cursor_pos, last_action)
  local last_a = last_action
  
  -- Check if we need to continue or return back to the main function...
  if last_a == nil then -- no new action
    return
  end
  
  if  edit_cursor_pos == last_edit_cursor_pos and -- no edit cursor pos change
      last_a ~= "Move media items" and 
      last_a ~= "Resize Media Items" then
    return
  end

  -- ...if we didn't return back to the main function -> execute the code below
  
  for i = 1, reaper.CountTracks(0) do -- loop through tracks...
    item_found = false -- (this is a local variable, created outside of this function)
    local track_muted = false -- track muted flag
    local track_always_visible = false -- trackname has suffix "#AV" (for #Always Visible) flag
    local track_is_receiving = false -- flag for showing receiving tracks of current track
    local track_is_rec_armed = false
    local track_id = reaper.GetTrack(0, i-1) -- track_id from track index
    
     -- check if track is always visible (trackname has #AV suffix)
     retval, track_name = reaper.GetSetMediaTrackInfo_String(track_id, "P_NAME", "", false)
     if retval then
       -- check track_name for suffix "#AV" (#ALWAYS VISIBLE)
       track_name_length = string.len(track_name)
       track_name_suffix = string.sub(track_name, track_name_length-2, -1) -- get last three chars of trackname
       if track_name_suffix == "#AV" then
         track_always_visible = true
         -- msg(track_always_visible)
         if not reaper.IsTrackVisible(track_id, true) then
           reaper.SetMediaTrackInfo_Value(track_id, "B_SHOWINMIXER", 1) -- show this track in mixer
         end
         -- if child has #AV suffix show all parent tracks
         local p_track_id = track_id -- a copy of current track pointer
         while true do -- loop through all parent tracks
           p_track_id = reaper.GetParentTrack(p_track_id)
           if p_track_id ~= nil then
             if not reaper.IsTrackVisible(p_track_id, true) then
               if reaper.GetMediaTrackInfo_Value(p_track_id, "B_MUTE") ~= 1.0 then -- if parent is not muted
                 reaper.SetMediaTrackInfo_Value(p_track_id, "B_SHOWINMIXER", 1) -- show parent track
               -- else 
                 -- break -- if direct parent is muted show no parents at all, does this make sense ?
               end
             end
           else
             break -- no parent track -> exit loop through parent tracks
           end 
         end -- end of check for parent tracks
       end
     end -- end of check for always visible 
     
     -- check if current track has receives, if true and a receiving track struddles edit cursor...
     -- ...set current track to visible (set track_is_receiving flag)
     nr_of_receives = reaper.GetTrackNumSends(track_id, -1) -- check for nr. of receives
     if nr_of_receives ~= 0 then
       -- msg (nr_of_receives)
       for i=1, nr_of_receives do -- loop through tracks that send to this one
         receive_track_id = reaper.BR_GetMediaTrackSendInfo_Track(track_id, -1, i-1, 0)
         -- msg(track_id)
         -- msg(receive_track_id)
         -- reaper.SetTrackColor(receive_track_id, 400)
         for i = 1, reaper.CountTrackMediaItems(receive_track_id) do 
           local item_id = reaper.GetTrackMediaItem(receive_track_id, i-1) -- get item id        
           local item_start = reaper.GetMediaItemInfo_Value(item_id, "D_POSITION") -- get item start in seconds
           local item_end = item_start + reaper.GetMediaItemInfo_Value(item_id, "D_LENGTH") -- get item end in seconds
           if item_start <= edit_cursor_pos and item_end >= edit_cursor_pos then -- item on receiving track found
             track_is_receiving = true
             if not reaper.IsTrackVisible(track_id, true) then
               reaper.SetMediaTrackInfo_Value(track_id, "B_SHOWINMIXER", 1) -- show this track in mixer
             end
             -- show all parent tracks for item under edit cursor
             local p_track_id = track_id -- a copy of current track pointer
             while true do -- loop through all parent tracks
               p_track_id = reaper.GetParentTrack(p_track_id)
               if p_track_id ~= nil then
                 if not reaper.IsTrackVisible(p_track_id, true) then
                   reaper.SetMediaTrackInfo_Value(p_track_id, "B_SHOWINMIXER", 1) -- show parent track
                 end
               else
                 break -- no parent track -> exit loop through parent tracks
               end 
             end -- end of check for parent tracks
           end -- end of loop through sending tracks
         end -- end of loop through media items
       end -- end of loop through sending tracks
     end -- end of if nr_of_receives
     
     -- check if track is record armed
     rec_armed_state = reaper.GetMediaTrackInfo_Value(track_id, "I_RECARM")
     if rec_armed_state == 1.0 then
      if not reaper.IsTrackVisible(track_id, true) then
        reaper.SetMediaTrackInfo_Value(track_id, "B_SHOWINMIXER", 1) -- show this track in mixer
      end
      track_is_rec_armed = true
      -- msg(track_is_rec_armed)
     end 
     
    --- loop through items --- 
    for i = 1, reaper.CountTrackMediaItems(track_id) do -- loop through items (note: we can use Lua's "break" function to exit the loop)
      -- check if track is muted
      if reaper.GetMediaTrackInfo_Value(track_id, "B_MUTE") == 1.0 and not track_always_visible then
        track_muted = true 
        break -- exit loop through items
      end
      local item_id = reaper.GetTrackMediaItem(track_id, i-1) -- get item id
      local item_start = reaper.GetMediaItemInfo_Value(item_id, "D_POSITION") -- get item start in seconds
      local item_end = item_start + reaper.GetMediaItemInfo_Value(item_id, "D_LENGTH") -- get item end in seconds
  
      if item_start <= edit_cursor_pos and item_end >= edit_cursor_pos then  -- check if item straddles cursor
        -- check if item is muted
        if reaper.GetMediaItemInfo_Value(item_id, "B_MUTE") == 1.0 then break -- exit loop through items
        end
        if not reaper.IsTrackVisible(track_id, true) then
          reaper.SetMediaTrackInfo_Value(track_id, "B_SHOWINMIXER", 1) -- show this track in mixer
        end
        item_found = true -- set "item_found" flag
        
        -- show all parent tracks for item under edit cursor
        local p_track_id = track_id -- a copy of current track pointer
        while true do -- loop through all parent tracks
          p_track_id = reaper.GetParentTrack(p_track_id)
          if p_track_id ~= nil then
            if not reaper.IsTrackVisible(p_track_id, true) then
              reaper.SetMediaTrackInfo_Value(p_track_id, "B_SHOWINMIXER", 1) -- show parent track
            end
          else
            break -- no parent track -> exit loop through parent tracks
          end 
        end -- end of check for parent tracks
      end -- end of check if item straddles edit cursor
      
      -- if at least one item under edit cursor on this track -> exit loop -> go to next track
      if item_found then
        break -- exit loop through items
      end
    end -- end of loop through items 
    
    if not item_found and not track_always_visible and not track_is_receiving and not track_is_rec_armed or track_muted then -- if no item under edit cursor on this track... 
    -- ...or item is muted (item_found not set) or track is muted and not always visible...
      if reaper.IsTrackVisible(track_id, true) then -- if track is visible...
        reaper.SetMediaTrackInfo_Value(track_id, "B_SHOWINMIXER", 0) -- ...hide the track
      end
    end -- end of hide this track
  end -- end of loop through tracks
  
  reaper.UpdateArrange()                -- update arrange view
  reaper.TrackList_AdjustWindows(false) -- update tracklist
end -- end of function on_project_state_change(edit_cursor_pos, last_action)


----------
-- Main --
----------

function main()
  local edit_cursor_pos = reaper.GetCursorPosition()
  local proj_change_count = reaper.GetProjectStateChangeCount(0)
  
  if proj_change_count > last_proj_change_count or edit_cursor_pos ~= last_edit_cursor_pos then
    local last_action = reaper.Undo_CanUndo2(0) -- get last action
    on_project_state_change(edit_cursor_pos, last_action) -- call "on_project_state_change" to update something if needed

    last_proj_change_count = proj_change_count -- store "Project State Change Count" for the next pass
    last_edit_cursor_pos = edit_cursor_pos     -- store "Edit cursor position" for the next pass
  end
  
 
  reaper.defer(main)
end

main()
reaper.atexit(do_at_exit)
