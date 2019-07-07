-- @description FOLDER ITEMS - Toggle visibility
-- @author nvk
-- @version 0.9beta
-- @changelog beta
-- @about
--   # Game Audio Workflow
--
--   A collection of scripts designed to improve workflow for common game audio tasks such as item editing, renaming, folder creation, and subproject management. Click [here](https://www.youtube.com/c/NickvonKaenel) for more information.

--[[
 * ReaScript Name: Script: nvk_FOLDER ITEMS - Toggle visibility
 * Description: Toggles visibility of hidden items in folder and groups contigious folder items, if item not in folder track, will do slightly improved default double click action, going to exact location in subproject and maximizing view.
 * Instructions: Instead of assigning this to a hotkey, assign it to mouse modifier "Media item/double click/Default action" and "Track control panel/double click/Default action"
 * Author: Nick von Kaenel
 * Author URI: nickvonkaenel.com
 * Special thanks (for contributing code): X-Raym , ausbaxter, me2beats
 * Repository URI: https://github.com/NickvonKaenel/ReaScripts
 * REAPER: 5.979
 * Extensions: SWS/S&M 2.10.0
 * Version: 0.9beta
--]]

select_children = reaper.NamedCommandLookup("_SWS_SELCHILDREN2")  --select children of selected tracks
unselect_children = reaper.NamedCommandLookup("_SWS_UNSELCHILDREN")
hide_selected_tracks = reaper.NamedCommandLookup("_SWSTL_HIDE")
show_selected_tracks = reaper.NamedCommandLookup("_SWSTL_BOTH")


----------------------SAVE SELECTED ITEMS/TRACKS--------------------

function SaveSelectedItems(table)
  for i=0, reaper.CountSelectedMediaItems(0)-1 do
    table[i+1] = reaper.GetSelectedMediaItem(0, i)
  end
end


function SaveSelectedTracks(table)
  for i = 0, reaper.CountSelectedTracks(0)-1 do
    table[i+1] = reaper.GetSelectedTrack(0, i)
  end
end

----------------------UNSELECT ALL TRACKS--------------------

function UnselectAllTracks()
  local first_track = reaper.GetTrack(0, 0)
  reaper.SetOnlyTrackSelected(first_track)
  reaper.SetTrackSelected(first_track, false)
end





-------------------------GROUP ITEMS----------------------------------

function Initialize()

  selectedMediaItems = {} --for sorting media items in order
  mediaItemColumns = {} --columns are stored as nested arrays
  selItemCount = reaper.CountSelectedMediaItems()
end

function GetSelectedItemsinColumns()
  
  --insert media items, start pos and end pos into a table  
  for i = 0, selItemCount - 1 do
    local mediaItem = reaper.GetSelectedMediaItem(0, i)
    local itemStart, itemEnd = GetMediaItemPosition(mediaItem)
    local itemTrack = reaper.GetMediaItem_Track(mediaItem)
    local trackFound = false
    table.insert(selectedMediaItems, {mediaItem, itemStart, itemEnd})
  end
  
  --Sort table into chronological order
  table.sort(selectedMediaItems, function(a,b) return a[2] < b[2] end)
  SortItemsIntoColumns(selectedMediaItems)
end

function GetMediaItemPosition(mediaItem)
  local itemStart = reaper.GetMediaItemInfo_Value(mediaItem, "D_POSITION")
  local itemEnd = itemStart + reaper.GetMediaItemInfo_Value(mediaItem, "D_LENGTH")
  return itemStart, itemEnd
end

function SortItemsIntoColumns(mediaItems)
  local itemEnd = 0.0
  local columnNum = 1
  local loopItemCount = 1
  local columnItemNum = 1
  local newColumn = false
  numColumns = 0
  --Handles dynamic table creation
  while loopItemCount <= selItemCount do
    newColumn = false
    --Creates nested table containing items in the same column
    while newColumn == false and loopItemCount <= selItemCount do
      local mediaItem = mediaItems[loopItemCount]
      if loopItemCount == 1 then
        mediaItemColumns[columnNum] = {}
        mediaItemColumns[columnNum][columnItemNum] = mediaItem
        itemEnd = mediaItem[3]     
      else
        local itemStart = mediaItem[2]              
        if itemStart < itemEnd then
          mediaItemColumns[columnNum][columnItemNum] = mediaItem
          if mediaItem[3] > itemEnd then
            itemEnd = mediaItem[3]
          end
        else
          itemEnd = mediaItem[3]        
          columnItemNum = 1
          columnNum = columnNum + 1
          mediaItemColumns[columnNum] = {}
          newColumn = true
          mediaItemColumns[columnNum][columnItemNum] = mediaItem
        end
      end
      columnItemNum = columnItemNum + 1
      loopItemCount = loopItemCount + 1
    end    
    numColumns = numColumns + 1
  end
end

function GroupItemsInColumns()
  for i, column in ipairs(mediaItemColumns) do
    reaper.Main_OnCommand(40289, 0)
    for j, item in ipairs(column) do
        reaper.SetMediaItemInfo_Value(item[1], "B_UISEL", 1)
    end
    reaper.Main_OnCommand(40032, 0)
   -- reaper.Main_OnCommand(40706, 0) --set item to one random color
  end
end

function RestoreOriginalItemSelection()
  for i, item in ipairs(selectedMediaItems) do
    reaper.SetMediaItemInfo_Value(item[1], "B_UISEL", 1)
  end
end

function GroupItems()
  if reaper.CountSelectedMediaItems() > 0 then
    Initialize()
    GetSelectedItemsinColumns()
    GroupItemsInColumns()
    RestoreOriginalItemSelection()
  else
    --reaper.ReaScriptError("Error: No items selected.")
  end
end


-------------------GET SUBPROJECT START AND END-----------------------

function GetSubprojectStartAndEnd()
  y=0
  i=0
  while y==0 do
    retval, num_markersOut, num_regionsOut = reaper.CountProjectMarkers(0)
    a=0
    while i<num_markersOut do
      retval2, isrgnOut, posOut, rgnendOut, nameOut, idexnum = reaper.EnumProjectMarkers(i)
      if isrgnOut==false then      
        if nameOut=="=START" then
          start_pos = posOut
          a=1
        end
        if nameOut=="=END" then
          end_pos = posOut
          a=1
        end
        i=i+1
      end
    end
    if a==0 then
      y=1
    end 
  end
  return start_pos, end_pos
end
----------------LAST TRACK IN FOLDER-----------------

function set_direct_children_tracks_to_same_color_as_parent (folder_track)
  last = nil
  local dep = reaper.GetTrackDepth(folder_track)
  local color = reaper.GetTrackColor(folder_track)
  local num = reaper.GetMediaTrackInfo_Value(folder_track, 'IP_TRACKNUMBER')
  local tracks = reaper.CountTracks()
  for i = num+1, tracks do
    local child_track = reaper.GetTrack(0,i-1)
    if reaper.GetTrackDepth(child_track) <= dep then last = reaper.GetTrack(0,i-2) break end
    if color ~= 0 and reaper.GetMediaTrackInfo_Value(child_track, 'I_FOLDERDEPTH') ~= 1 then
      local parent_track = reaper.GetParentTrack(child_track)
      local color = reaper.GetTrackColor(parent_track)
      if color ~= 0 then
        reaper.SetTrackColor(child_track, color)
      end
    end
  end
  if last == nil then last = reaper.GetTrack(0, tracks-1) end
  return last
end


----------------------TOGGLE MAIN (Recursive)----------------

function ToggleMain(track, repeat_bool)
  if track ~= nil and reaper.GetMediaTrackInfo_Value(track, 'I_FOLDERDEPTH') == 1 then -- if selected track is folder and not nil
    reaper.SetOnlyTrackSelected(track)
    local depth = reaper.GetTrackDepth(track)
    reaper.Main_OnCommand(select_children, 0)
    reaper.Main_OnCommand(40421, 0) --select all items in track
    reaper.SetTrackSelected(track,false)
    local child_track = reaper.GetSelectedTrack(0,0)
    if reaper.IsTrackVisible(child_track, 0) == true then 
      GroupItems()
      reaper.Main_OnCommand(hide_selected_tracks,0)
    else
      reaper.Main_OnCommand(show_selected_tracks,0)
      reaper.Main_OnCommand(40033, 0) --remove from group
      local sel_tracks = {}
      SaveSelectedTracks(sel_tracks)
      for i, track in ipairs(sel_tracks) do
        local child_depth = reaper.GetTrackDepth(track)
        if reaper.GetMediaTrackInfo_Value(track, 'I_FOLDERDEPTH') == 1 and child_depth == depth+1 then
          if repeat_bool then
            ToggleMain(track, false)
          end--hides folders inside folder
        end
      end
    end
  end
end

-------------------------------MAIN---------------------------------------------


track = reaper.GetSelectedTrack(0,0) -- save actual track to "track"
focus = reaper.GetCursorContext()

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

if focus ~= 0 then
  items_count = reaper.CountSelectedMediaItems(0)
  if items_count > 0 then
      item = reaper.GetSelectedMediaItem(0,0)

      take_count = reaper.CountTakes(item)
      if take_count == 0 then
        reaper.AddTakeToMediaItem(item)
        take= reaper.GetActiveTake(item)
        note = reaper.ULT_GetMediaItemNote(item)
        note = note:gsub("\n", " ")
        reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", note, 1)
      end

      take = reaper.GetActiveTake(item)
    source = reaper.GetMediaItemTake_Source( take )
    typebuf = reaper.GetMediaSourceType( source, "" ) 
    if typebuf == "MIDI" then
      reaper.Main_OnCommand(40153,0) --open in midi editor
      track = nil
      return
    end 
    if typebuf == "RPP_PROJECT" then
      local item_length = reaper.GetMediaItemInfo_Value(item,"D_LENGTH")
      offset = reaper.GetMediaItemTakeInfo_Value(take,"D_STARTOFFS")
      reaper.Main_OnCommand(41816,0) --open project in new tab
      start_pos, end_pos = GetSubprojectStartAndEnd()
      loop_start = start_pos + offset
      loop_end = loop_start + item_length
      reaper.SetEditCurPos(loop_start,true,false)
      reaper.MoveEditCursor(0, false ) --have to add this since edit cursor is bugged
      reaper.GetSet_LoopTimeRange(true, true, loop_start, loop_end, false)
      --for i=0, reaper.CountTracks(0)-1 do
      --  reaper.SetTrackSelected(reaper.GetTrack(0,i),true)
      --end
      reaper.Main_OnCommand(40296,0) -- select all tracks
      --reaper.Main_OnCommand(40111,0) --zoom out vertical (hack)
      reaper.Main_OnCommand(40031,0) -- zoom to time selection
      reaper.PreventUIRefresh(-1)
      reaper.Main_OnCommand(reaper.NamedCommandLookup('_SWS_VZOOMFIT'),0)
      reaper.PreventUIRefresh(1)
      reaper.Main_OnCommand(40297,0) --unselect all tracks
      track = nil
      return
    end
    track =  reaper.GetMediaItem_Track(item)
    if track ~= nil and reaper.GetMediaTrackInfo_Value(track, 'I_FOLDERDEPTH') ~= 1 then -- if selected track is not folder and not nil
      reaper.Main_OnCommand(40009,0) return --show media item/take properties
      --track = reaper.GetParentTrack(track)
    end
  end
end



ToggleMain(track, true)

reaper.SetOnlyTrackSelected(track)
set_direct_children_tracks_to_same_color_as_parent(track)
--reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_COLCHILDREN"), 0) --set children to same color as parent
reaper.Main_OnCommand(40289, 0) --unselect all items
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)

reaper.Undo_EndBlock("nvk_FOLDER ITEMS - Toggle visibility", -1)

