-- @description FOLDER ITEMS - Add new items to existing folder - rename folder items
-- @author nvk
-- @version 0.9beta
-- @changelog beta
-- @about
--   # Game Audio Workflow
--
--   A collection of scripts designed to improve workflow for common game audio tasks such as item editing, renaming, folder creation, and subproject management. Click [here](https://www.youtube.com/c/NickvonKaenel) for more information.

--[[
 * ReaScript Name: nvk_FOLDER ITEMS - Add new items to existing folder - rename folder items
 * Description: Select items in folder and folder items. Script will update folder item lengths and attempt to rename automatically. Select only folder items to rename with new name.
 * Author: Nick von Kaenel
 * Author URI: nickvonkaenel.com
 * Special thanks (for contributing code): X-Raym, ausbaxter, me2beats, knotar
 * Repository URI: https://github.com/NickvonKaenel/ReaScripts
 * REAPER: 5.979
 * Extensions needed: SWS/S&M 2.10.0
 * Version: 0.9beta
--]]



-----------------------Item Selection-----------------------------


function SaveSelectedItems(table)
  for i=0, reaper.CountSelectedMediaItems(0)-1 do
    table[i+1] = reaper.GetSelectedMediaItem(0, i)
  end
end


function SelectOnlyItemsOnFirstTrack()

  init_sel_items = {}
  SaveSelectedItems(init_sel_items)

  first_item = reaper.GetSelectedMediaItem(0,0)
  first_track = reaper.GetMediaItemTrack(first_item)
  item_count = reaper.CountSelectedMediaItems()
  reaper.Main_OnCommand(40289, 0) --unselect all items
  for i, item in ipairs(init_sel_items) do
    track = reaper.GetMediaItemTrack(item)
    if track == first_track then
      reaper.SetMediaItemSelected(item,true)
    end
  end
end

-------------------------------------Rename Items-----------------------------------------

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


---------------------------------------Error Handler--------------------------------------------------------
function ErrorMsg(msg)
    reaper.ShowConsoleMsg(msg)
end


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

local Region = {}
Region.__index = Region

setmetatable(Region, {
    __call = function (cls, ...)
      return cls.New(...)
    end,
})

function Region.New(index, r_start, r_end)
    local self = setmetatable({}, Region)
    self.index = index
    self.r_start = r_start
    self.r_end = r_end
    return self
end


-------------------------------------------Constants-------------------------------------------------------
local mono = 41721
local stereo = 41719
local multi = 41720
local cmd_id                                                                                                       --for render type
local in_place = 1
local folder = 2
local master = 3
local preview_nm = "RIC Preview"
local default_nm = "Column Render"
-----------------------------------------Region Preview----------------------------------------------------
local preview_switch = false
local preview_rgns ={}

--------------------------------------------Script---------------------------------------------------------
function msg(m)
    reaper.ShowConsoleMsg(tostring(m))
end


function Initialize()
    first_item = reaper.GetSelectedMediaItem(0,0)
    local take_count = reaper.CountTakes(first_item)

      if take_count == 0 then
        reaper.AddTakeToMediaItem(first_item)
        local take= reaper.GetActiveTake(first_item)
        local note = reaper.ULT_GetMediaItemNote(first_item)
        local note = note:gsub("\n", " ")
        reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", note, 1)
      end
    first_take = reaper.GetActiveTake(first_item)
    if first_take ~= nil then retval, first_name = reaper.GetSetMediaItemTakeInfo_String(first_take, "P_NAME", "", 0) end
    first_item_track = reaper.GetMediaItem_Track(first_item)
    --parent_track = reaper.GetParentTrack(first_item_track)
    --region_track = reaper.GetTrack(0,1)
    media_items = {}                                                                                             --sorted selected media item list
    item_columns = {}
    track_count = reaper.CountTracks(0) - 1
    media_tracks = {}
    parent_tk_check = {}
    render_track = nil
    dest_track = nil
    folder_is_child = true
    track_folder_state = {}
    R = math.random(255)
    G = math.random(255)
    B = math.random(255)
    color = (R + 256 * G + 65536 * B)|16777216                                                                                      --check for "f" mode
    ts_start, ts_end = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
end

function create_item(track, position, length)
  local item = reaper.AddMediaItemToTrack(track)
  reaper.SetMediaItemSelected(item, 1)
  reaper.SetMediaItemInfo_Value(item, "D_POSITION", position)
  reaper.SetMediaItemInfo_Value(item, "D_LENGTH", length)
  reaper.AddTakeToMediaItem(item)
  take = reaper.GetActiveTake(item)
  reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", first_name, 1)
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
    all_folder = true
    no_folder = true
    first_child_item = true
    for i = 0, item_count - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        local s, e = GetItemPosition(item)
        local m = reaper.GetMediaItemInfo_Value(item, "B_MUTE")
        local track = reaper.GetMediaItem_Track(item)

        if m == 0 then
            all_muted = false
        end
        

        if reaper.GetMediaTrackInfo_Value(track,"I_FOLDERDEPTH") ~= 1 then --if not parent track
          all_folder = false
          
          if first_child_item then
            parent_track = reaper.GetParentTrack(track)
            first_child_item = false
          end
          table.insert(media_items, Item(item, s, e, m))        
          local p_track = tostring(reaper.GetParentTrack(track))
          InsertIntoTable(parent_tk_check, p_track)
          InsertTrackIntoTable(media_tracks, track)

        end

        if reaper.GetMediaTrackInfo_Value(track,"I_FOLDERDEPTH") == 1 then
          no_folder = false
          item_count = item_count-1
        end

        
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

    local c_start = -1.0
    local c_end = 0.0
              
    for i, item in ipairs(item_columns[column]) do
        if c_start == -1.0 then                                                                                --init with first item's start and end
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
    items_to_delete = {}
    for i, column in ipairs(item_columns) do --remove existing folder items
      local c_start, c_end = GetLoopTimeSelection(item_columns, i)
      local track_items_count = reaper.CountTrackMediaItems(parent_track)
      for i=0, track_items_count-1 do
        local item = reaper.GetTrackMediaItem(parent_track,i)
        local take = reaper.GetActiveTake(item)
        local source =  reaper.GetMediaItemTake_Source( take )
        local typebuf = reaper.GetMediaSourceType( source, "" )
        if typebuf == "EMPTY" then
          local item_start = reaper.GetMediaItemInfo_Value(item,"D_POSITION")
          local item_end = item_start + reaper.GetMediaItemInfo_Value(item,"D_LENGTH")
          if item_start >= c_start and item_start <= c_end then
            InsertIntoTable(items_to_delete, item)
          end
          if item_end >= c_start and item_end <= c_end then
            InsertIntoTable(items_to_delete, item)
          end
        end
      end
    end
    if #items_to_delete > 0 then
      for i, item in ipairs(items_to_delete) do
        --local it = items_to_delete[i]
        local track = reaper.GetMediaItem_Track(item)
        reaper.DeleteTrackMediaItem(track, item)
      end
    end
    for i, column in ipairs(item_columns) do --create new folder items
        local c_start, c_end = GetLoopTimeSelection(item_columns, i)
        create_item(parent_track, c_start, c_end - c_start)
    end
end       




---------------MAIN-----------------------

function Main()
    reaper.Undo_BeginBlock()
    item_count = reaper.CountSelectedMediaItems()
    if item_count == 0 then return end
    Initialize()
    GetSelectedMediaItemsAndTracks()
    if all_muted then return end
    if all_folder then 
    --if reaper.GetMediaTrackInfo_Value(first_item_track,"I_FOLDERDEPTH") == 1 then --is track a parent?
    --if first_item_track == region_track then
    --if parent_track == nil then
      --SelectOnlyItemsOnFirstTrack()
      name = first_name
      name = RemoveExtensions(name)
      retval, retvals_csv = reaper.GetUserInputs("Rename", 1, "New Name, extrawidth=333", name) -- Gets values and stores them
      if retval == false then return end
      name = retvals_csv
      RenameItemsWithNumbersAppended()
    else
        reaper.Main_OnCommand(40289,0) --unselect all items
        ColumnToItem()
        name = first_name
        name = RemoveExtensions(name)
        RenameItemsWithNumbersAppended()
    end
end


reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()
Main()
reaper.Undo_EndBlock("nvk_FOLDER ITEMS - Add new items to existing folder - rename folder items", -1)
reaper.PreventUIRefresh(-1)