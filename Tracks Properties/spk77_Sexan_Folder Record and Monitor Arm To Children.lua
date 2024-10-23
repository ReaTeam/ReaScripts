--[[
 * ReaScript Name: Folder Record/Monitor Arming Childs
 * Author: SPK77, SeXan
 * Licence: GPL v3
 * REAPER: 5.0
 * Extensions: None
 * Version: 1.0.1
--]]


-- USER CONFIG AREA ---------------------------------------------------------

local last_proj_change_count = reaper.GetProjectStateChangeCount(0)
-- Returns a track's folder depth
function get_track_folder_depth(track_index)
  local folder_depth = 0
  for i=0, track_index do -- loop from start of tracks to "track_index"... 
    local track = reaper.GetTrack(0, i)
    local folder_depth = folder_depth + reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH") -- ...to get the actual folder depth
  end
  return folder_depth
end


-----------------------
-- on_rec_arm_change --
-----------------------
t = {} -- table for saving inputs
--  this function is called when rec arm button is pressed on some track
function on_rec_arm_change(track_pointer, track_index)
  -- t = {} -- table for saving folders input
  -- If this function is called, we know that:
  --   last touched track is a folder track (parent)
  --   rec-arm button was clicked on that track
  
 
  -- call "get_track_folder_depth" to get the actual folder depth
  local parent_folder_depth = get_track_folder_depth(track_index)
  local total_folder_depth = parent_folder_depth
  
  local parent_rec_arm = reaper.GetMediaTrackInfo_Value(track_pointer, "I_RECARM") -- get (parent) track's rec arm state
  local parent_mon_arm = reaper.GetMediaTrackInfo_Value(track_pointer, "I_RECMON") -- get (parent) track's monitor state
  
  -- loop from" parent track index" to end of tracks (break when last child is found)
  for i = track_index + 1, reaper.CountTracks(0) do
    local child_track = reaper.GetTrack(0, i-1)
    
    if last_a ==  "toggle track record arming" then
       reaper.SetMediaTrackInfo_Value(child_track, "I_RECARM", parent_rec_arm) -- set track armed as folder
       local ret, child_state = reaper.GetTrackState(child_track) 
	   local child_input = reaper.GetMediaTrackInfo_Value(child_track,"I_RECINPUT")
       
        if child_state&1 == 1 then -- if track is a folder
         if child_state&64 == 64 then -- if folder is rec-armed
			if child_input >= 0 then
				t[i]=reaper.GetMediaTrackInfo_Value(child_track,"I_RECINPUT") -- add folder input to table
				reaper.SetMediaTrackInfo_Value(child_track, "I_RECINPUT", -1) -- disable folder input (avoid double monitoring issue)
			end
		 else      
           for k,v in pairs(t) do
            local track_from_key = reaper.CSurf_TrackFromID(k, false) -- convert track number to track code
            local ret, k_state = reaper.GetTrackState(track_from_key)
              if k_state&64 ~= 64 then
                 reaper.SetMediaTrackInfo_Value(track_from_key, "I_RECINPUT", v) -- restore inputs from table
              end
           end
           t[i] = nil -- empty the table when inputs are restored          
         end     
        end       
 
    elseif last_a == "toggle track recording monitor" then
           reaper.SetMediaTrackInfo_Value(child_track, "I_RECMON", parent_mon_arm) -- set monitor arm
    end   
    
    total_folder_depth = total_folder_depth + reaper.GetMediaTrackInfo_Value(child_track, "I_FOLDERDEPTH")
        if total_folder_depth <= parent_folder_depth then
          break -- break when last child is found
        end
  end 

  reaper.UpdateArrange()                -- update arrange view
  reaper.TrackList_AdjustWindows(false) -- update tracklist
end



-----------------------------
-- on_project_state_change --
-----------------------------
--  this function is called when project state changes

function on_project_state_change(last_action)
  last_a = last_action
  -- if last action (that changed the project state) was "Toggle Track Record Arming"...
  if last_action == "toggle track record arming" or last_action == "toggle track recording monitor" then
    local last_touched_track = reaper.GetLastTouchedTrack() -- get last touched track's "track pointer"
    local last_touched_track_name, flags = reaper.GetTrackState(last_touched_track)
    local last_touched_track_index = reaper.CSurf_TrackToID(last_touched_track, false) - 1 -- get track index from "last touched track"
   
    -- Check if last_touched_track was a folder track
    if flags&1 ~= 1 then -- if last_touched track was not a folder (parent)...
      return -- ...return to main function...
    end
            
    on_rec_arm_change(last_touched_track, last_touched_track_index) -- ...(else) call "on_rec_arm_change"
  end
end  
----------

function main() 
 lt=reaper.GetLastTouchedTrack()
 lt_par= reaper.GetMediaTrackInfo_Value(lt, "I_FOLDERDEPTH")
  local proj_change_count = reaper.GetProjectStateChangeCount(0)
  if proj_change_count > last_proj_change_count then -- to make it work across project tabs change > with ~= as suggested by HurdyGuigui at https://forum.cockos.com/showpost.php?p=2344506&postcount=17
    local last_action = reaper.Undo_CanUndo2(0):lower() -- get last action
    if last_action ~= nil then      
      on_project_state_change(last_action) -- call "on_project_state_change" to update something if needed
    end
    last_proj_change_count = proj_change_count -- store "Project State Change Count" for the next pass
  end
  reaper.defer(main)    
end

main()
