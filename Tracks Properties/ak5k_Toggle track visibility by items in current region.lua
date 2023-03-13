-- @description Toggle track visibility by items in current region
-- @author ak5k
-- @version 0.2.1
-- @changelog Zero-length time selection is no longer registered as 'point of interest'.
-- @link Forum thread https://forum.cockos.com/showthread.php?t=262559
-- @screenshot https://i.imgur.com/rvnZAzk.gif
-- @about Toggles track visibility based on existing items within current region.

-------------------------------------------------------------------------------
local next = next
local pairs = pairs
local reaper = reaper
local string = string

local regions = {}
local tracks = {}
local tracks_by_guid = {}

local starts, ends = {}, {}
local function GetRange()
  regions = {}
  tracks = {}
  tracks_by_guid = {}
  starts, ends = {}, {}

  local isPlaying = false
  if reaper.GetPlayState() ~= 0 then 
    isPlaying = true
  end
  local cursor = reaper.GetCursorPosition()
  starts[#starts+1] = cursor
  ends[#ends+1] = cursor
  
  if isPlaying then
    cursor = reaper.GetPlayPosition()
    starts[#starts+1] = cursor
    ends[#ends+1] = cursor
  end
  
  local loop_start, loop_end = 
    reaper.GetSet_LoopTimeRange(false, false, _,_, false)
  if (loop_end - loop_start ~= 0) then
    starts[#starts+1] = loop_start
    ends[#ends+1] = loop_end
  end
  
  for i = 0, reaper.GetNumTracks() - 1, 1 do
    local track = reaper.GetTrack(0, i)
    local track_guid = reaper.GetTrackGUID(track)
    tracks[track] = track_guid
    tracks_by_guid[track_guid] = track
    local retval, razor_edits = 
      reaper.GetSetMediaTrackInfo_String(track, "P_RAZOREDITS", "", false)
    for word in razor_edits:gmatch("%S+") do
      local number = tonumber(word)
      if number then
        starts[#starts+1] = number
        ends[#ends+1] = number
      end
    end
  end
  
  local selection_start, selection_end = nil, nil
  for i = 1, #starts, 1 do
    selection_start = selection_start or starts[i]
    if starts[i] < selection_start then
      selection_start = starts[i]
    end
  end
  for i = 1, #ends, 1 do
    selection_end = selection_end or ends[i]
    if ends[i] > selection_end then
      selection_end = ends[i]
    end
  end
  
  for i = 0, reaper.CountProjectMarkers(0) - 1, 1 do
    local retval, isrgn, pos, rgnend = reaper.EnumProjectMarkers(i)
    if retval and isrgn then
      regions[#regions+1] = {pos, rgnend}
    end
  end
  
  local range_start, range_end = nil, nil
  for i = 1, #regions, 1 do
    local pos = regions[i][1]
    local rgnend = regions[i][2]
    local region_valid = false
    if not ((pos < selection_start and rgnend < selection_start) or
      (pos > selection_end and rgnend > selection_end)) then
      region_valid = true
    end
    if region_valid then
      range_start = range_start or pos
      range_end = range_end or rgnend
      if pos < range_start then
        range_start = pos
      end
      if rgnend > range_end then
        range_end = rgnend
      end
    end
  end
  if (range_start and selection_start < range_start) or
    (range_end and selection_end > range_end) then
    range_start = nil
    range_end = nil
  end
 return range_start, range_end
end

local function GetTracksToHide()
  local res = {}
  local range_start, range_end = GetRange()
  if not range_start then return res end
  for track, _ in pairs(tracks) do
    res[track] = true
    local mediaitem_count = reaper.CountTrackMediaItems(track)
    if mediaitem_count == 0 then
      res[track] = nil
      goto next_track
    end
    
    local track_has_global_item = true
    for j = 0, mediaitem_count - 1, 1 do
      local item_is_global = true
      local mediaitem = reaper.GetTrackMediaItem(track, j)
      local pos = reaper.GetMediaItemInfo_Value(mediaitem, "D_POSITION")
      local endpos = reaper.GetMediaItemInfo_Value(mediaitem, "D_LENGTH") + pos
      
      for i = 1, #regions, 1 do
        local rgnpos = regions[i][1]
        local rgnend = regions[i][2]
        if (pos >= rgnpos and endpos <= rgnend) then
          item_is_global = false
          break
        end
      end
      
      if item_is_global then
        res[track] = nil
        goto next_track
      end
      
      if ((pos <= range_start and endpos <= range_start) or 
        (pos >= range_end and endpos >= range_end)) then
         goto continue
      else
        res[track] = nil
        break
      end
      ::continue::
    end

    ::next_track::
  end
  return res
end

local hasJS = false
if reaper.APIExists("JS_Mouse_GetState") then
  hasJS = true
end

local function GetSetState(state)
  local res = {}
  local extname = "ak5k"
  local key = "toggle_track_visibility_by_items_in_current_region"
  local state = state or nil
  local retval, current_state
  local n = 0

  retval, current_state = reaper.GetProjExtState(0, extname, key)
  
  if not state then
    for value in string.gmatch(current_state, '[^,]+') do
        res[#res + 1] = tracks_by_guid[value]
    end
  end
  
  if state then
    current_state = ""
    for track, _ in pairs(state) do
      current_state = current_state .. tracks[track] .. ","
    end
    retval = reaper.SetProjExtState(0, extname, key, current_state)
  end
  
  return res
end

local function ToggleTrackVisibility(tracks_to_hide)
  
  if hasJS then
    local mouseState = reaper.JS_Mouse_GetState(3)
    if mouseState == 1 or mouseState == 2 then 
      return 
    end
  end
  
  local current_state = GetSetState()
  local tracks_to_hide = tracks_to_hide or GetTracksToHide()
  local tracks_to_show = {}
  
  GetSetState(tracks_to_hide)
  for i = 1, #current_state, 1 do
    local track = current_state[i]
    if tracks_to_hide[track] then
      tracks_to_hide[track] = nil
    else
      tracks_to_show[track] = true
    end
  end
  for track in pairs(tracks_to_show) do
    if reaper.ValidatePtr(track, "MediaTrack*") then
      reaper.SetMediaTrackInfo_Value(track, "B_SHOWINMIXER", 1)
      reaper.SetMediaTrackInfo_Value(track, "B_SHOWINTCP", 1)
    end
  end
  
  for track in pairs(tracks_to_hide) do
    if reaper.ValidatePtr(track, "MediaTrack*") then
      reaper.SetMediaTrackInfo_Value(track, "B_SHOWINMIXER", 0)
      reaper.SetMediaTrackInfo_Value(track, "B_SHOWINTCP", 0)
    end
  end
  
  if next(tracks_to_hide) ~= nil or
    next(tracks_to_show) ~= nil then
    reaper.TrackList_AdjustWindows(false)
  end
  
  return
end

local function main()
  --time0 = reaper.time_precise()
  
  ToggleTrackVisibility()
  
  --[[
  time1 = reaper.time_precise() - time0
  time_max = time_max or 0
  if time1 > time_max then
    time_max = time1
  end
  
  gb = collectgarbage("count")
  ]]--
  
  reaper.defer(main)
end

local function ToggleCommandState(state)
  local _, _, sec, cmd,_, _, _ = reaper.get_action_context()
  reaper.SetToggleCommandState(sec, cmd, state) -- Set ON
  reaper.RefreshToolbar2(sec, cmd)
end

ToggleCommandState(1)

reaper.defer(main)

function exit()
  ToggleTrackVisibility({})
  ToggleCommandState(0)
  return
end

reaper.atexit(exit)
