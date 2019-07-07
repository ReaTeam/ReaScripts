-- @description SUBPROJECT - Create from selected items or tracks
-- @author nvk
-- @version 0.9beta
-- @changelog beta
-- @about
--   # Game Audio Workflow
--
--   A collection of scripts designed to improve workflow for common game audio tasks such as item editing, renaming, folder creation, and subproject management. Click [here](https://www.youtube.com/c/NickvonKaenel) for more information.

--[[
 * ReaScript Name: nvk_SUBPROJECT - Create from selected items or tracks
 * Description: Select items or tracks that you want to move to subproject. If you have a video track make sure it is named "VIDEO". Enter name for subproject and script will handle the rest.
 * Author: Nick von Kaenel
 * Author URI: nickvonkaenel.com
 * Special thanks (for contributing code): X-Raym, ausbaxter, me2beats, JerContact, knotar
 * Repository URI: https://github.com/NickvonKaenel/ReaScripts
 * REAPER: 5.979
 * Extensions needed: SWS/S&M 2.10.0
 * Version: 0.9beta
--]]

-------------------USER CONFIG--------------------

FolderFXName = "VST3:Fabfilter Pro-L 2" --This fx will be added to the top level folder track of the subproject (recommend adding a limiter of some sort)

TrackTemplateSlot = 1 --add sws track template slot (1-4) at end of tracks (0 does nothing, "p" opens prompt)


----------------------SAVE SELECTED ITEMS/TRACKS--------------------

function SaveSelectedItems(table)
  for i=0, reaper.CountSelectedMediaItems(0)-1 do
    table[i+1] = reaper.GetSelectedMediaItem(0, i)
  end
end

function RestoreSelectedItems(table)
  reaper.Main_OnCommand(40289, 0) --unselect all items
  for i, item in ipairs(table) do
    reaper.SetMediaItemSelected(item,1)
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


------------------SELECT ALL ITEMS ESCEPT VIDEO----------------------

function SelectAllItemsExceptVideo()
  reaper.Main_OnCommand(40289, 0) --unselect all items
  tracks = reaper.CountTracks(0)
  for i=0, tracks-1 do
    track = reaper.GetTrack(0, i)
    retval, trackname = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "something", false)
    trackname = string.upper(trackname)
    if trackname ~= "VIDEO" then
      track_items_count = reaper.CountTrackMediaItems(track)
      for i=0, track_items_count-1 do
        item = reaper.GetTrackMediaItem(track,i)
        reaper.SetMediaItemSelected(item,true)
      end
    end
  end
end

--------------SELECT ALL ITEMS IN GROUP WITH ITEM-----------------

function SelectAllItemsInGroup(source_item)
  source_group = reaper.GetMediaItemInfo_Value(source_item, "I_GROUPID")
  for i=0, reaper.CountMediaItems(0)-1 do
    local item = reaper.GetMediaItem(0, i)
    local group = reaper.GetMediaItemInfo_Value(item, "I_GROUPID")
    if item ~= source_item and group > 0 and group == source_group then
      reaper.SetMediaItemSelected(item,true)
    end
  end
end

------------SELECT ALL ITEMS IN GROUP WITH SELECTED ITEMS--------------------

function SelectAllItemsInGroupsWithSelectedItems()
  for i=0, reaper.CountSelectedMediaItems(0)-1 do
    local item = reaper.GetSelectedMediaItem(0,i)
    SelectAllItemsInGroup(item)
  end
end


---------------------SHOW HIDDEN TCP TRACKS AND SAVE--------------------------------------

function ShowHiddenTracksAndSave()
  hidden_tracks = {}
  b=0
  for i=0, reaper.CountTracks(0)-1 do
    track = reaper.GetTrack(0,i)
    if reaper.GetMediaTrackInfo_Value(track,"B_SHOWINTCP") == 0 then
      reaper.SetMediaTrackInfo_Value(track,"B_SHOWINTCP",1)
      b=b+1
      hidden_tracks[b] = track
    end
  end
end


function RestoreHiddenTracks()
  for i, track in ipairs(hidden_tracks) do
    reaper.SetMediaTrackInfo_Value(track,"B_SHOWINTCP",0)
  end
end



function RestoreHiddenTracks2()
  UnselectAllTracks()
  for i, track in ipairs(hidden_tracks) do
    reaper.SetTrackSelected(track, true)
  end
  for i=0, reaper.CountSelectedTracks(0)-1 do
    track = reaper.GetSelectedTrack(0,i)
    reaper.SetMediaTrackInfo_Value(track,"B_SHOWINTCP",0)
  end
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

  reaper.InsertTrackAtIndex(track_num-1, 1)
  reaper.TrackList_AdjustWindows(0)
  track = reaper.GetTrack(0, track_num-1)

  reaper.SetMediaTrackInfo_Value(track, 'I_FOLDERDEPTH', 1)
  reaper.SetMediaTrackInfo_Value(last_track, 'I_FOLDERDEPTH', last_sel_dep-1)
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

------------------------ADD ITEMS TO FOLDER----------------------------

function SelectedTracksContainFolder()
  for i = 0, reaper.CountSelectedTracks(0)-1 do
    local track = reaper.GetSelectedTrack(0,i)
    local depth = reaper.GetMediaTrackInfo_Value(track, 'I_FOLDERDEPTH')
    if depth == 1 then
      return true 
    end
  end
end

function AddItemsToFolder()
  item_count = reaper.CountSelectedMediaItems(0)
  if item_count > 0 then
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
    reaper.Main_OnCommand(40359, 0) --track to default color
    if SelectedTracksContainFolder() == nil then
      CreateFolderFromSelectedTracks()
    end
  end
end
---------SUBPROJECT CREATION---------------------

function CreateSubproject()

  masterproj, projfn = reaper.EnumProjects(-1, "NULL")
  reaper.Main_OnCommand(41997, 0) --subproject
  reaper.Main_OnCommand(40769, 0) --unselect all
  i=0
  subproj, projfn = reaper.EnumProjects(i, "NULL")
  while subproj do
    i=i+1
    subproj, projfn = reaper.EnumProjects(i, "NULL")  
  end
  subproj, projfn = reaper.EnumProjects(i-1, "NULL")

  isrgnOut = {}
  posOut = {}
  rgnendOut = {}
  nameOut = {}
  idexnum = {}

  tracks = reaper.CountTracks(0)
  i=0
  while i<tracks do
    tr = reaper.GetTrack(0, i)
    retval, trackname = reaper.GetSetMediaTrackInfo_String(tr, "P_NAME", "something", false)
    trackname = string.upper(trackname)
    if trackname == "VIDEO" then
      track = reaper.GetTrack(0, i)
      reaper.SetTrackSelected(track, true)
      reaper.Main_OnCommand(40210, 0) --copy tracks

      reaper.SelectProjectInstance(subproj)

      SelectAllItemsExceptVideo()
      subproject_items =  {}
      SaveSelectedItems(subproject_items)

      local last_track = reaper.GetTrack(0,reaper.CountTracks(0)-1)
      if last_track then reaper.SetOnlyTrackSelected(last_track) end

      if TrackTemplateSlot ~= 0 then
        TrackTemplateSlot = "_S&M_ADD_TRTEMPLATE"..TrackTemplateSlot
        reaper.Main_OnCommand(reaper.NamedCommandLookup(TrackTemplateSlot), 0) -- add track template slot 1 track (set it to default template)
      end

      commandID = reaper.NamedCommandLookup("_SWS_SELMASTER")

      reaper.Main_OnCommand(commandID, 0) --select master

      reaper.Main_OnCommand(40058, 0) --paste track  

      reaper.Main_OnCommand(40769, 0) --unselect all
      break
    end
    i=i+1
  end
  for i, item in ipairs(subproject_items) do
    reaper.SetMediaItemSelected(item, 1) --select original items
  end
  --reaper.Main_OnCommand(40031, 0) --reposition zoom
end

---------------------MOVE SUBPROJECT MARKERS------------------------

function MoveSubprojectMarkersToSelectedItems()
  reaper.Main_OnCommand(40290, 0) --set time selection to items
  startOut, endOut = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
  pos =  reaper.GetCursorPosition()
  y=0
  while y==0 do

    retval, num_markersOut, num_regionsOut = reaper.CountProjectMarkers(0)
    a=0
    i=0
    while i<num_markersOut+num_regionsOut do
          retval2, isrgnOut, posOut, rgnendOut, nameOut, idexnum = reaper.EnumProjectMarkers(i)
      if isrgnOut==false then      
          if nameOut=="=START" then
            reaper.DeleteProjectMarker(0, idexnum, false)
          a=1
          end
          if nameOut=="=END" then
            reaper.DeleteProjectMarker(0, idexnum, false)
          a=1
          end
      end
      i=i+1
    end
    if a==0 then
      y=1
    end 
  end
  if startOut==endOut then
    reaper.AddProjectMarker(0, false, pos, 0, "=START", 1)
    reaper.AddProjectMarker(0, false, pos+1, 0, "=END", 2)   
  else
    reaper.AddProjectMarker(0, false, startOut, 0, "=START", 1)
    reaper.AddProjectMarker(0, false, endOut, 0, "=END", 2)
  end

  reaper.Main_OnCommand(40020, 0)  --remove time selection
  reaper.Main_OnCommand(40289, 0)  --deselect all items
end



--------------------------------------GET CONTIGUOUS ITEMS-----------------------------------------------------

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

function Initialize()
    item_count = reaper.CountSelectedMediaItems(0)
    if item_count > 0 then
      first_item = reaper.GetSelectedMediaItem(0,0)
      first_take = reaper.GetActiveTake(first_item)
    --if first_take ~= nil then retval, first_name = reaper.GetSetMediaItemTakeInfo_String(first_take, "P_NAME", "", 0) end
      first_item_track = reaper.GetMediaItem_Track(first_item)
      parent_track = reaper.GetParentTrack(first_item_track)
    end
    region_track = reaper.GetTrack(0,1)
    media_items = {}                                                                                             --sorted selected media item list
    item_columns = {}
    track_count = reaper.CountTracks(0) - 1
    media_tracks = {}
    parent_tk_check = {}                                                                                   --check for "f" mode
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

    local c_start = -1
    local c_end = 0.0
              
    for i, item in ipairs(item_columns[column]) do
        if c_start == -1 then                                                                                --init with first item's start and end
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

function SplitItemByColumns(split_item, start_pos, end_pos)
  track = reaper.GetMediaItemTrack(split_item)
  right_item = reaper.SplitMediaItem(split_item, start_pos)
  if right_item ~= nil then
    reaper.DeleteTrackMediaItem(track, split_item)
    split_item = reaper.SplitMediaItem(right_item, end_pos)
  else
    split_item = reaper.SplitMediaItem(split_item, end_pos)
  end
  return split_item
end


function ColumnToItemSplit(split_item)
  for i, column in ipairs(item_columns) do
    local c_start, c_end = GetLoopTimeSelection(item_columns, i)
    split_item = SplitItemByColumns(split_item, c_start, c_end)
  end
end       

------------------------------RENAME------------------------------------
remove = {".wav" , ".aif", ".mp3", ".mid", ".mov", ".mp4", ".rex", ".bwf", ".rpp", "-glued", " glued", " render", "reversed", "_0", "_1", "_2", "_3", "_4", "_5", "_6", "_7", "_8", "_9", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9"}


function rev(string)
  return string.reverse(string)
end

function nospace(string)
  return string.gsub(string,"%s*$","")
end

function RenameItemsWithNumbersAppended()
  local items_count = reaper.CountSelectedMediaItems(0)
  if items_count > 0 then
    local item = reaper.GetSelectedMediaItem(0,0)
    local track =  reaper.GetMediaItem_Track(item)
    local take = reaper.GetActiveTake(item)
    local name = reaper.GetTakeName(take)

    o = 1
    while o <= #remove do -- checks all items defined at top

      flag = 0
      while flag ==0 do
        if string.find(rev(name),rev(remove[o])) == 1 then   
          name = nospace(string.sub(name,1,string.len(name)-string.len(remove[o])))
          o = 1
        else
          if string.match(name,"%-%d%d$") ~= nil then 
            name = nospace(string.sub(name,1,string.len(name)-string.len(string.match(name,"%-%d%d$"))))
            o = 1
          else
            if string.match(name,"%s%d%d%d$") ~= nil then 
              name = nospace(string.sub(name,1,string.len(name)-string.len(string.match(name,"%d%d%d$"))))
              o = 1
            else
              flag = 1
            end
          end
        end
      end
    o = o+1
    end

    for i = 0, items_count - 1 do

      local item = reaper.GetSelectedMediaItem(0, i)

      local take_count = reaper.CountTakes(item)

      if take_count == 0 then
        reaper.AddTakeToMediaItem(item)
        take= reaper.GetActiveTake(item)
        note = reaper.ULT_GetMediaItemNote(item)
        note = note:gsub("\n", " ")
        reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", note, 1)
      end

      local take= reaper.GetActiveTake(item)
      local enumerator = 1 + i
      local number_value = tostring(enumerator)
      if enumerator < 10 then
          reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", name.."_".."0"..number_value, true)
      else
          reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", name.."_"..number_value, true)
      end
    end
  end
end

function DeleteEmptyTakesFromSelection()
  if reaper.GetToggleCommandState(1156) == 1 then --turn grouping off
    reaper.Main_OnCommand(1156, 0)
    grouping_on = true
  end
  guids_it = {}
  guids_tk = {}
  count_sel_items = reaper.CountSelectedMediaItems(0)
  if count_sel_items ~= nil then
    for i=0, count_sel_items-1 do
      item = reaper.GetSelectedMediaItem(0, i)
      item_guid = reaper.BR_GetMediaItemGUID(item)
      table.insert(guids_it, item_guid)
    end
  end
  for i=1, #guids_it do
    guid_temp = guids_it[i]
    item = reaper.BR_GetMediaItemByGUID(0,guid_temp)
    takes_count = reaper.CountTakes(item)
    if takes_count ~= nil then
      for i=1, takes_count do
        take = reaper.GetTake(item,i-1)
        take_guid = reaper.BR_GetMediaItemTakeGUID(take)
        table.insert(guids_tk, take_guid)
      end
    end
  end
  if guids_tk ~= nil then
    for i=1, #guids_tk do
      guid_temp = guids_tk[i]
      reaper.Main_OnCommand(40289,0) -- unselect all items
      take = reaper.SNM_GetMediaItemTakeByGUID(0,guid_temp)
      if take then 
        item = reaper.GetMediaItemTake_Item(take)
        active_take = reaper.GetActiveTake(item)
        reaper.SetMediaItemSelected(item,true)
        reaper.SetActiveTake(take)
        local source =  reaper.GetMediaItemTake_Source(take)
        local typebuf = reaper.GetMediaSourceType( source, "" )
        if typebuf == "EMPTY" then
          reaper.Main_OnCommand(40129,0) --delete active take
          if take == active_take then
            active_take = nil
          end
        end
      --else
      --  reaper.Main_OnCommand(40129,0) --delete active take
      --  active_take = nil
      end
    end
    if active_take then
      reaper.SetActiveTake(active_take)
    end
  end
  if grouping_on then
    reaper.Main_OnCommand(1156, 0)
  end
end




-------------------------------MAIN--------------------------------------
retval, retvals_csv = reaper.GetUserInputs("Create Subproject", 1, "Name, extrawidth=100", "") -- Gets values and stores them
if retval == false then return end
subproject_name = retvals_csv


reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()
ShowHiddenTracksAndSave() --have to do this because hidden tracks break some things

focus = reaper.GetCursorContext()
if focus == 0 then
  track = reaper.GetSelectedTrack(0,0)
else
  SelectAllItemsInGroupsWithSelectedItems()
  reaper.Main_OnCommand(40033, 0) --remove from group
  AddItemsToFolder()
  track = reaper.GetSelectedTrack(0,0)
  reaper.TrackFX_AddByName(track,FolderFXName,0,1) --add folder fx to folder track
end

trackidx = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER") --save track number for renaming later
reaper.GetSetMediaTrackInfo_String(track,"P_NAME",subproject_name,true)
CreateSubproject()
DeleteEmptyTakesFromSelection()
SelectAllItemsExceptVideo()

if reaper.CountSelectedMediaItems(0) > 0 then
  Initialize()
  GetSelectedMediaItemsAndTracks()
  GetItemColumns()
  MoveSubprojectMarkersToSelectedItems()
  reaper.Main_OnCommand(42332,0) --save and render project
end

reaper.SelectProjectInstance(masterproj)
track = reaper.GetTrack( 0, trackidx-1 )
reaper.GetSetMediaTrackInfo_String(track,"P_NAME","",true)
subproject = reaper.GetTrackMediaItem(track, 0)
reaper.SetMediaItemSelected(subproject,true)
if startOut ~= nil then
  reaper.SetMediaItemInfo_Value(subproject,"D_POSITION",startOut)
  reaper.Main_OnCommand(reaper.NamedCommandLookup("_XENAKIOS_RESETITEMLENMEDOFFS"),0)
  ColumnToItemSplit(subproject)
end
RenameItemsWithNumbersAppended()
RestoreHiddenTracks2()

reaper.Undo_EndBlock("nvk_SUBPROJECT - Create from selected items or tracks",-1)
reaper.TrackList_AdjustWindows(0)
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()




