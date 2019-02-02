-- @description Group selected items vertically
-- @author amagalma
-- @version 1.0
-- @about
--   # Groups selected items in different tracks vertically if they are aligned
--
--   - You can specify in the script if you want each group to be randomly colored



--------------------- USER SETTINGS ----------------------
--                                                      --
-- Set to 1 if you want random colors or 0 if you don't --
--                                                      --
-------------------                                     --
RandomColors = 1 --                                     --
-------------------                                     --
----------------------------------------------------------


----------------------------------------------------------------------------------

local reaper = reaper
local init_sel_items = {}
local init_sel_tracks = {}
local floor = math.floor
local random = math.random
local randomseed = math.randomseed

----------------------------------------------------------------------------------

local function SaveSelectedItems()
  for i = 0, reaper.CountSelectedMediaItems(0)-1 do
    init_sel_items[i+1] = reaper.GetSelectedMediaItem(0, i)
  end
end

local function RestoreSelectedItems()
  reaper.Main_OnCommand(40289, 0) -- Unselect all items
  for _, item in ipairs(init_sel_items) do
    reaper.SetMediaItemSelected(item, true)
  end
end

local function SaveSelectedTracks()
  for i = 0, reaper.CountSelectedTracks(0)-1 do
    init_sel_tracks[i+1] = reaper.GetSelectedTrack(0, i)
  end
end

local function RestoreSelectedTracks()
  reaper.Main_OnCommand(40297, 0) -- Unselect all tracks
  for _, track in ipairs(init_sel_tracks) do
    reaper.SetTrackSelected(track, true)
  end
end

local function SelectOnlyTracksOfSelectedItems()
  reaper.Main_OnCommand(40297, 0) -- Unselect all tracks
  local selected_items_count = reaper.CountSelectedMediaItems(0)
  for i = 0, selected_items_count - 1  do
    local item = reaper.GetSelectedMediaItem(0, i)
    local track = reaper.GetMediaItem_Track(item)
    reaper.SetTrackSelected(track, true)   
  end
end

local function MaxProjectGroupID()
  local all_item_count = reaper.CountMediaItems(0)
  local MaxGroupID = 0
  for i = 0, all_item_count - 1 do
    local item = reaper.GetMediaItem(0, i)
    local item_group_id = floor(reaper.GetMediaItemInfo_Value(item, "I_GROUPID"))
    if item_group_id > MaxGroupID then
      MaxGroupID = item_group_id
    end
  end
  return MaxGroupID
end

----------------------------------------------------------------------------------

if reaper.CountSelectedMediaItems(0) > 1 then
  reaper.PreventUIRefresh(1)
  reaper.Undo_BeginBlock()
  local MaxGroupID = MaxProjectGroupID()
  SaveSelectedItems()
  SaveSelectedTracks()
  SelectOnlyTracksOfSelectedItems()
  local selected_tracks_count = reaper.CountSelectedTracks(0)
  local first_track = reaper.GetSelectedTrack(0, 0)
  local count_items_on_track = reaper.CountTrackMediaItems(first_track)
  for i = 0, count_items_on_track - 1  do
    MaxGroupID = MaxGroupID +1
    local r = random(0, 255)
    local g = random(0, 255)
    local b = random(0, 255)
    local color = reaper.ColorToNative(r, g, b)
    local item_on_first_track = reaper.GetTrackMediaItem(first_track, i)
    if reaper.IsMediaItemSelected(item_on_first_track) == true then
      local firstposition = reaper.GetMediaItemInfo_Value(item_on_first_track, "D_POSITION")
      local firstlength = reaper.GetMediaItemInfo_Value(item_on_first_track, "D_LENGTH")
      for j = 1, selected_tracks_count - 1 do
        local track = reaper.GetSelectedTrack(0, j)
        local count_items_on_track2 = reaper.CountTrackMediaItems(track)
        for k = 0, count_items_on_track2 - 1  do
          local item_on_track = reaper.GetTrackMediaItem(track, k)
          local position = reaper.GetMediaItemInfo_Value(item_on_track, "D_POSITION")
          local length = reaper.GetMediaItemInfo_Value(item_on_track, "D_LENGTH")
          if position == firstposition and length == firstlength then
            reaper.SetMediaItemInfo_Value(item_on_first_track, "I_GROUPID", MaxGroupID)
            reaper.SetMediaItemInfo_Value(item_on_track, "I_GROUPID", MaxGroupID)
            if RandomColors == 1 then 
              reaper.SetMediaItemInfo_Value(item_on_first_track, "I_CUSTOMCOLOR", color|0x1000000)
              reaper.SetMediaItemInfo_Value(item_on_track, "I_CUSTOMCOLOR", color|0x1000000)
            end
          break
          end
        end
      end
    end     
  end
  RestoreSelectedItems()
  RestoreSelectedTracks()
  reaper.Undo_EndBlock("Group selected items vertically", -1)
  reaper.PreventUIRefresh(-1)
  reaper.UpdateArrange()
end
