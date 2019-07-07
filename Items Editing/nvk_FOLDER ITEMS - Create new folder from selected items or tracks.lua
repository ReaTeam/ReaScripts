-- @description FOLDER ITEMS - Create new folder from selected items or tracks
-- @author nvk
-- @version 0.9beta
-- @changelog beta
-- @about
--   # Game Audio Workflow
--
--   A collection of scripts designed to improve workflow for common game audio tasks such as item editing, renaming, folder creation, and subproject management. Click [here](https://www.youtube.com/c/NickvonKaenel) for more information.

--[[
 * ReaScript Name: nvk_FOLDER ITEMS - Create new folder from selected items or tracks
 * Description: Select items or tracks to move into folder. Folder items will be created for contiguous item sets and children tracks will be hidden. Use Script: nvk_FOLDER ITEMS - Toggle visibility.lua to show items again.
 * Author: Nick von Kaenel
 * Author URI: nickvonkaenel.com
 * Special thanks (for contributing code): X-Raym, ausbaxter, me2beats
 * Repository URI: https://github.com/NickvonKaenel/ReaScripts
 * REAPER: 5.979
 * Extensions needed: SWS/S&M 2.10.0
 * Version: 0.9beta
--]]

----------------------SAVE SELECTED ITEMS--------------------

function SaveSelectedItems (table)
	for i = 0, reaper.CountSelectedMediaItems(0)-1 do
		table[i+1] = reaper.GetSelectedMediaItem(0, i)
	end
end

----------------------UNSELECT ALL TRACKS--------------------

function UnselectAllTracks()
  first_track = reaper.GetTrack(0, 0)
  reaper.SetOnlyTrackSelected(first_track)
  reaper.SetTrackSelected(first_track, false)
end

------------------------SELECT TRACKS------------------------

function SelectTracksFromItems() 
  
  --focus = reaper.GetCursorContext()
  --if focus == 0 then return end
  -- LOOP THROUGH SELECTED ITEMS
  selected_items_count = reaper.CountSelectedMediaItems(0)
  if selected_items_count == 0 then return end

  UnselectAllTracks()
  
  -- INITIALIZE loop through selected items
  -- Select tracks with selected items
  for i = 0, selected_items_count - 1  do
    -- GET ITEMS
    item = reaper.GetSelectedMediaItem(0, i) -- Get selected item i

    -- GET ITEM PARENT TRACK AND SELECT IT
    track = reaper.GetMediaItem_Track(item)
    reaper.SetTrackSelected(track, true)
        
  end -- ENDLOOP through selected tracks

end


-----------------------CREATE FOLDER-----------------------

function last_track_in_folder (folder_track)
  last = nil
  local dep = reaper.GetTrackDepth(folder_track)
  local num = reaper.GetMediaTrackInfo_Value(folder_track, 'IP_TRACKNUMBER')
  local tracks = reaper.CountTracks()
  for i = num+1, tracks do
    if reaper.GetTrackDepth(reaper.GetTrack(0,i-1)) <= dep then last = reaper.GetTrack(0,i-2) break end
  end
  if last == nil then last = reaper.GetTrack(0, tracks-1) end
  return last
end



function CreateFolderFromSelectedTracks()

	sel_tracks = reaper.CountSelectedTracks()
	if sel_tracks == 0 then return end

	first_sel = reaper.GetSelectedTrack(0,0)
	track_num = reaper.GetMediaTrackInfo_Value(first_sel, 'IP_TRACKNUMBER')

	last_sel = reaper.GetSelectedTrack(0,sel_tracks-1)
	last_sel_dep = reaper.GetMediaTrackInfo_Value(last_sel, 'I_FOLDERDEPTH')
	if last_sel_dep == 1 then last_track = last_track_in_folder(last_sel) else last_track = last_sel end
  last_sel_dep = reaper.GetMediaTrackInfo_Value(last_track, 'I_FOLDERDEPTH')

	reaper.InsertTrackAtIndex(track_num-1, 1)
	reaper.TrackList_AdjustWindows(0)
	track = reaper.GetTrack(0, track_num-1)

	reaper.SetMediaTrackInfo_Value(track, 'I_FOLDERDEPTH', 1)
	reaper.SetMediaTrackInfo_Value(last_track, 'I_FOLDERDEPTH', last_sel_dep-1) --make last track close the folder
	reaper.SetOnlyTrackSelected(track)

	reaper.Main_OnCommand(40914,0) -- Track: Set first selected track as last touched track
end




----------------DUPLICATE ITEMS WITH TRACKS-------------------


function Elem_in_tb(elem,tb)
  _found = nil
  for eit = 1, #tb do if tb[eit] == elem then _found = 1 break end end
  if _found then return 1 end
end

sel_tracks1 = {}
sel_tracks2 = {}

function SaveSelTracks(table)
  for i = 0, reaper.CountSelectedTracks(0)-1 do
    table[i+1] = reaper.GetSelectedTrack(0, i)
  end
end

function RestoreSelTracks(table)
  reaper.Main_OnCommand(40297,0) -- unselect all tracks
  for _, track in ipairs(table) do
    reaper.SetTrackSelected(track, true)
  end
end


function SetLastTouchedTrack(tr)

  SaveSelTracks(sel_tracks2)
  reaper.SetOnlyTrackSelected(tr)
  reaper.Main_OnCommand(40914,0) -- Track: Set first selected track as last touched track
  RestoreSelTracks(sel_tracks2)

end


function SaveView() start_time_view, end_time_view = reaper.BR_GetArrangeView(0) end

function RestoreView() reaper.BR_SetArrangeView(0, start_time_view, end_time_view) end




function DuplicateItemsWithTracks()

	local tracks = reaper.CountSelectedTracks()

	local items = reaper.CountSelectedMediaItems()
	if items == 0 then return end

	tracks_tb = {}
	items_tb = {}

	for i = 1, items do
	  local item = reaper.GetSelectedMediaItem(0,i-1)
	  local tr = reaper.GetMediaItem_Track(item)
	  if not Elem_in_tb(tr,tracks_tb) then tracks_tb[#tracks_tb+1] = tr end --create table of tracks with selected items
	  items_tb[i] = {item,tr} --creates array within array
	end

	if #tracks_tb == 1 then ---if only one track (makes things simpler)

	  SaveSelTracks(sel_tracks1)
	  local tr = tracks_tb[1]
	  reaper.SetOnlyTrackSelected(tr)

	  reaper.Main_OnCommand(40062,0) -- Track: Duplicate tracks

	  for i = #items_tb,1,-1 do
	    local it = items_tb[i][1] --multidimensional array (gets first item which is item from items_tb)
	    reaper.DeleteTrackMediaItem(tr, it) --deletes items from original track
	  end

	  local new_tr = reaper.GetSelectedTrack(0,0) 
	  local items = reaper.CountTrackMediaItems(new_tr) --get count of items on new track
	  for i = items-1,0,-1 do --iterating down from item count by -1
	    local item = reaper.GetTrackMediaItem(new_tr, i)
	    if not reaper.IsMediaItemSelected(item) then reaper.DeleteTrackMediaItem(new_tr, item) end --delete unselected items from track leaving only the duplicated selected items
	  end

	  RestoreSelTracks(sel_tracks1)

	  reaper.PreventUIRefresh(-1) reaper.Undo_EndBlock('Move items to new tracks (duplicate tracks)', -1)

	return end

	--if more than one track--

	SaveSelTracks(sel_tracks1)
	SaveView()

	reaper.Main_OnCommand(40297,0) -- unselect all tracks
	for i = 1, #tracks_tb do reaper.SetTrackSelected(tracks_tb[i],1) end --select track with selected items

	local tracks = #tracks_tb

	first_track_idx = reaper.GetMediaTrackInfo_Value( reaper.GetSelectedTrack(0,0) , "IP_TRACKNUMBER" )
	last_sel = reaper.GetTrack(0, first_track_idx-2) --get previous track
	if first_track_idx == 1 then last_sel = reaper.GetSelectedTrack(0, tracks-1) end--set last selected track to the last one (can make change here)

	SetLastTouchedTrack(last_sel) --this tells next function where to paste

	reaper.Main_OnCommand(reaper.NamedCommandLookup('_S&M_COPYSNDRCV1'),0) -- SWS/S&M: Copy selected tracks (with routing)
	reaper.Main_OnCommand(reaper.NamedCommandLookup('_BR_FOCUS_TRACKS'),0) -- SWS/BR: Focus tracks
	reaper.Main_OnCommand(reaper.NamedCommandLookup('_S&M_PASTSNDRCV1'),0) -- SWS/S&M: Paste tracks (with routing) or items

	for i = #items_tb,1,-1 do
	  local it,tr = items_tb[i][1],items_tb[i][2] --read first and second values from table within table and assign them
	  reaper.DeleteTrackMediaItem(tr, it) --delete from old track
	end

	for j = 0, reaper.CountSelectedTracks()-1 do --delete other items from new track
	  local new_tr = reaper.GetSelectedTrack(0,j)
	  local items = reaper.CountTrackMediaItems(new_tr)
	  for i = items-1,0,-1 do
	    local item = reaper.GetTrackMediaItem(new_tr, i)
	    if not reaper.IsMediaItemSelected(item) then reaper.DeleteTrackMediaItem(new_tr, item) end
	  end
	end

	RestoreSelTracks(sel_tracks1)
	RestoreView()
end



-----------------------------CREATE BLANK ITEMS IN PARENT TRACK FROM SELECTED ITEM COLUMNS-------------------------


--------------------------------------Class Definitions-----------------------------------------------------

local Item = {}
Item.__index = Item

setmetatable(Item, {
    __call = function (cls, ...)
      return cls.New(...)
    end,
})

function Item.New(item, i_start, i_end, m_state) --stores reaper item, start and end values
    local self = setmetatable({}, Item)
    self.item = item
    self.s = i_start
    self.e = i_end
    self.m_state = m_state
    return self
end

--------------------------------------------Script---------------------------------------------------------

function Initialize()
    first_item = reaper.GetSelectedMediaItem(0,0)
    first_take = reaper.GetActiveTake(first_item)
    --if first_take ~= nil then retval, first_name = reaper.GetSetMediaItemTakeInfo_String(first_take, "P_NAME", "", 0) end
    first_item_track = reaper.GetMediaItem_Track(first_item)
    parent_track = reaper.GetParentTrack(first_item_track)
    region_track = reaper.GetTrack(0,1)
    media_items = {}                                                                                             --sorted selected media item list
    item_columns = {}
    track_count = reaper.CountTracks(0) - 1
    media_tracks = {}
    parent_tk_check = {}                                                                                   --check for "f" mode
end

function CreateItem(track, position, length)
  local item = reaper.AddMediaItemToTrack(track)
  reaper.SetMediaItemSelected(item, 1)
  reaper.SetMediaItemInfo_Value(item, "D_POSITION", position)
  reaper.SetMediaItemInfo_Value(item, "D_LENGTH", length)
  reaper.AddTakeToMediaItem(item)
  take = reaper.GetActiveTake(item)
  --reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", first_name, 1)
  return item

end

function GetItemPosition(item)

    local s = reaper.GetMediaItemInfo_Value(item, "D_POSITION") 
    local e = s + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    return s, e
  
end

function InsertTrackIntoTable(t, this_track, check)

    local track_found = false
    for i, track in ipairs(t) do                                                                       --check if trying to add repeated track
        if this_track == track[1] then
            track_found = true
            break 
        end
    end
    if track_found == false then
        local track_index = reaper.GetMediaTrackInfo_Value(this_track, "IP_TRACKNUMBER") - 1
        table.insert(t, {this_track, track_index})
    end

end

function InsertIntoTable(t, this_elem)
    local elem_found = false
    for i, elem in ipairs(t) do                                                                       --check if trying to add repeated track
        if this_elem == elem then
            elem_found = true
            break 
        end
    end
    if elem_found == false then
        table.insert(t, this_elem)
    end
end

function GetSelectedMediaItemsAndTracks()
    all_muted = true
    in_place_bad = false
    for i = 0, item_count - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        local s, e = GetItemPosition(item)
        local m = reaper.GetMediaItemInfo_Value(item, "B_MUTE")
        if m == 0 then
            all_muted = false
        end
        table.insert(media_items, Item(item, s, e, m))
        
        local track = reaper.GetMediaItem_Track(item)

        local p_track = tostring(reaper.GetParentTrack(track))
        InsertIntoTable(parent_tk_check, p_track)

        InsertTrackIntoTable(media_tracks, track)
    end
    if #parent_tk_check > 1 then --checks if in-place is possible
        in_place_bad = true
    end 
    table.sort(media_items, function(a,b) return a.s < b.s end)

end

function FindFirstValidItem(idx)
    for i = idx, item_count do                                                                                   --make sure first item in column is unmuted
        local item_check = media_items[idx]
        if item_check.m_state == 1 then
            idx = i+1
            item_check = media_items[idx]
        else
            return item_check , idx
        end
    end
end


function GetLoopTimeSelection(item_columns, column)

    local c_start = -1 --changed from 0.0 because would give false positives from items at 0
    local c_end = 0.0
              
    for i, item in ipairs(item_columns[column]) do
        if c_start == -1 then          --changed from 0.0                                                                      --init with first item's start and end
            c_start = item.s 
            c_end = item.e
        else
            if item.e > c_end then                                                                            --update item end
                c_end = item.e
            end
        end          
    end
    
    return c_start, c_end
                
end

function GetItemColumns()                                                                                        --making into a grammar
  
  local end_compare = 0.0
  local item_index = 1
  local column = {}
  local first_item = true
  while item_index <= item_count do
      local in_column = true
      while in_column and item_index <= item_count do
          
          if first_item then                                                                                     --first item in column
              item, item_index = FindFirstValidItem(item_index)
              table.insert(column,item)
              end_compare = item.e
              first_item = false
          else
              local item = media_items[item_index]
              local start_compare = item.s
              if item.m_state == 1 then
              elseif start_compare < end_compare then --item is within column
                  table.insert(column,item)
                  if item.e > end_compare then
                      end_compare = item.e
                  end           
              else                                                                                               --item is start of next column
                end_compare = item.e         
                in_column = false
                item, item_index = FindFirstValidItem(item_index)
                table.insert(item_columns, column)
                column = {}                                                                                      --new empty column
                table.insert(column,item)
              end
          end            
          item_index = item_index + 1
      end     
  end
  table.insert(item_columns, column)                                                                             --insert final column into table 
end


function ColumnToItem()
    GetItemColumns()
    for i, column in ipairs(item_columns) do
        local c_start, c_end = GetLoopTimeSelection(item_columns, i)
        CreateItem(parent_track, c_start, c_end - c_start)
    end
end       

function CreateBlankItemsInParentTrack()
  item_count = reaper.CountSelectedMediaItems()
  if item_count == 0 then return end
  Initialize()
  GetSelectedMediaItemsAndTracks()
  if all_muted then return end
  if parent_track == nil then return end
  ColumnToItem()
end

---------------------------GROUP CONTIGUOUS ITEMS-------------------------------

function InitializeGroupContiguous()
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

function GroupContiguousItems()
  if reaper.CountSelectedMediaItems() > 0 then
    reaper.PreventUIRefresh(1)
    InitializeGroupContiguous()
    GetSelectedItemsinColumns()
    GroupItemsInColumns()
    RestoreOriginalItemSelection()
  else
    reaper.ReaScriptError("Error: No items selected.")
    reaper.Undo_EndBlock("Group Contiguous Items in Columns Error", 8)
  end
end

-------SET CHILDREN TO SAME COLOR AS DIRECT PARENT TRACK---------
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
      reaper.SetTrackColor(child_track, color)
    end
  end
  if last == nil then last = reaper.GetTrack(0, tracks-1) end
  return last
end


------------------------MAIN----------------------------

focus = reaper.GetCursorContext()
if focus == 0 then
	CreateFolderFromSelectedTracks()
return end

item_count = reaper.CountSelectedMediaItems(0)

if item_count > 0 then

reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()

init_sel_items =  {}
SaveSelectedItems(init_sel_items)

SelectTracksFromItems() 
reaper.Main_OnCommand(40421,0) --select all items on track
if item_count < reaper.CountSelectedMediaItems(0) then --if other items on track besides selected 
	reaper.Main_OnCommand(40289, 0) --unselect all items
	for i, item in ipairs(init_sel_items) do
		reaper.SetMediaItemSelected(item, 1) --select orignal items
	end
	DuplicateItemsWithTracks()
end

SelectTracksFromItems()
CreateFolderFromSelectedTracks()
CreateBlankItemsInParentTrack()
GroupContiguousItems()
track = reaper.GetSelectedTrack(0,0) --parent track is selected at this point
reaper.Main_OnCommand(40360, 0) --set track to random color
set_direct_children_tracks_to_same_color_as_parent(track)
--reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_COLCHILDREN"), 0) --set children to same color as parent
reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_SELCHILDREN"), 0) --only children tracks selected
reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWSTL_HIDE"),0) --hide children tracks
reaper.SetOnlyTrackSelected(track)

reaper.Undo_EndBlock("nvk_FOLDER ITEMS - Create new folder from selected items or tracks",-1)
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)

end
