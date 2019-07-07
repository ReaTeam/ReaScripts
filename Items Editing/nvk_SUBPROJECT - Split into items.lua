-- @description SUBPROJECT - Split into items
-- @author nvk
-- @version 0.9beta
-- @changelog beta
-- @about
--   # Game Audio Workflow
--
--   A collection of scripts designed to improve workflow for common game audio tasks such as item editing, renaming, folder creation, and subproject management. Click [here](https://www.youtube.com/c/NickvonKaenel) for more information.

--[[
 * ReaScript Name: nvk_SUBPROJECT - Split into items
 * Description: Splits contiguous items in subproject and renames subproject items with numbers. Can also reposition items in master project based on subproject. Settings explained in USER CONFIG area.
 * Author: Nick von Kaenel
 * Author Website: nickvonkaenel.com
 * Special thanks (for contributing code): ausbaxter, X-Raym, me2beats, JerContact, knotar
 * Repository Website: https://github.com/NickvonKaenel/ReaScripts
 * REAPER: 5.979
 * Extensions: SWS/S&M 2.10.0
 * Version: 0.9beta
--]]

-------USER CONFIG------

popup = true --show popup to change settings when action is run. If false, will use settings below (these are also used for defaults in popup)

item_gap = 0 --how much space to leave between items (in seconds). If -1, items will use subproject positions. If -2, items will use relative subproject positions

item_tail = 0 --how much tail to add to items (in seconds)


---------------GET USER VALUES-------------

function GetUserValues()
  retval, retvals_csv = reaper.GetUserInputs("Subproject split (time is in seconds)", 3, "Name,Item gap (-1 to reset positions),Tail length, extrawidth=150", name..","..item_gap..","..item_tail) -- Gets values and stores them
  if retval == false then return end
  name, item_gap, item_tail = string.match(retvals_csv, "([^,]+),([^,]+),([^,]+)")
  item_gap = tonumber(item_gap)
  item_tail = tonumber(item_tail)
end


-----------------SET FUNCTIONS----------------

function addToSet(set, key)
    set[key] = true
end

function removeFromSet(set, key)
    set[key] = nil
end

function setContains(set, key)
    return set[key] ~= nil
end

----------------------SAVE SELECTED ITEMS--------------------

function SaveSelectedItems (table)
  for i = 0, reaper.CountSelectedMediaItems(0)-1 do
    table[i+1] = reaper.GetSelectedMediaItem(0, i)
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


function ColumnToItemSplit(split_item, split_offset)
  for i, column in ipairs(item_columns) do
    local c_start, c_end = GetLoopTimeSelection(item_columns, i)
    split_item = SplitItemByColumns(split_item, c_start + split_offset, c_end + split_offset)
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

function RemoveExtensions(name)
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
return name 
end



function RenameItemsWithNumbersAppended()
  local items_count = reaper.CountSelectedMediaItems(0)
  if items_count > 0 then 
    
    if name == nil then
      local item = reaper.GetSelectedMediaItem(0,0)
      local track =  reaper.GetMediaItem_Track(item)
      local take = reaper.GetActiveTake(item)
      name = reaper.GetTakeName(take)
      name = RemoveExtensions(name)
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

------------------SELECT ALL ITEMS BESIDES VIDEO IN SUBPROJECT RANGE----------------------

function SelectAllItemsExceptVideoInSubprojectRange()
  reaper.Main_OnCommand(40289, 0) --unselect all items
  start_pos, end_pos = GetSubprojectStartAndEnd()
  tracks = reaper.CountTracks(0)
  for i=0, tracks-1 do
    track = reaper.GetTrack(0, i)
    retval, trackname = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "something", false)
    trackname = string.upper(trackname)
    if trackname ~= "VIDEO" then
      track_items_count = reaper.CountTrackMediaItems(track)
      for i=0, track_items_count-1 do
        item = reaper.GetTrackMediaItem(track,i)
        item_start = reaper.GetMediaItemInfo_Value(item,"D_POSITION")
        item_end = item_start + reaper.GetMediaItemInfo_Value(item,"D_LENGTH")
        if item_start >= start_pos and item_start <= end_pos then
          reaper.SetMediaItemSelected(item,true)
        end
      end
    end
  end
end

-------------------------------MAIN--------------------------------------

reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()

masterproj, projfn = reaper.EnumProjects(-1, "NULL")

item_count = reaper.CountSelectedMediaItems(0)
source_name = ""
last_source_name = ""
init_sel_items =  {}
source_names_set = {}

if item_count > 0 then
  local item = reaper.GetSelectedMediaItem(0,0)
  local take = reaper.GetActiveTake(item)
  name = reaper.GetTakeName(take)
  name = RemoveExtensions(name)

  if popup == true then
    GetUserValues()
  end
  if retval == false then return end
  SaveSelectedItems(init_sel_items)
  for i, item in ipairs(init_sel_items) do
    item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    take = reaper.GetActiveTake(item)
    take_playrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE") --store playrate for later
    source = reaper.GetMediaItemTake_Source(take)
    typebuf = reaper.GetMediaSourceType(source, "")

    if typebuf == "RPP_PROJECT" then
      reaper.SetMediaItemTakeInfo_Value(take,"D_PLAYRATE",1.0) --set playrate to 1 so math works
      source_name = reaper.GetMediaSourceFileName(source, "")

      if setContains(source_names_set, source_name) then
        track = reaper.GetMediaItemTrack(item)
        reaper.DeleteTrackMediaItem(track, item)

      else
        addToSet(source_names_set, source_name)
        last_source_name = source_name
        subproject = item
        reaper.Main_OnCommand(40289, 0) --unselect all items
        reaper.SetMediaItemSelected(subproject,true)
        reaper.Main_OnCommand(41816,0) --open project in new tab
        SelectAllItemsExceptVideoInSubprojectRange()
        Initialize()
        GetSelectedMediaItemsAndTracks()
        GetItemColumns()
        reaper.SelectProjectInstance(masterproj)
        reaper.Main_OnCommand(40289, 0) --unselect all items
        reaper.SetMediaItemSelected(subproject,true)
        reaper.Main_OnCommand(reaper.NamedCommandLookup("_XENAKIOS_RESETITEMLENMEDOFFS"),0)

        if item_gap == -1 then --if use subproject positions
          reaper.SetMediaItemInfo_Value(subproject,"D_POSITION",start_pos)
          split_offset = 0
        else
          split_offset = item_pos - start_pos --if use relative positions
        end
        ColumnToItemSplit(subproject, split_offset)

        item_count = reaper.CountSelectedMediaItems(0)
        item_end = nil

        
        split_sel_items = {}
        SaveSelectedItems(split_sel_items)

        for i, item in ipairs(split_sel_items) do
          take = reaper.GetActiveTake(item)
          item_length = reaper.GetMediaItemInfo_Value(item,"D_LENGTH")
          reaper.SetMediaItemTakeInfo_Value(take,"D_PLAYRATE",take_playrate) --remove empty space between items and reset playrate to user value
          reaper.SetMediaItemInfo_Value(item,"D_LENGTH",item_length/take_playrate + item_tail) --fix length and add tail to end
          item_length = reaper.GetMediaItemInfo_Value(item,"D_LENGTH") --get new length

          if item_gap >= 0 then --if removing space
            if item_end then 
              reaper.SetMediaItemInfo_Value(item,"D_POSITION",item_end + item_gap)
            end
            item_start = reaper.GetMediaItemInfo_Value(item,"D_POSITION")
            item_end = item_start + item_length
          end
        end
        RenameItemsWithNumbersAppended()
        name = nil
      end
    end
  end
end

reaper.Main_OnCommand(40289, 0) --unselect all items



reaper.Undo_EndBlock("nvk_SUBPROJECT - Split into items",-1)
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)





