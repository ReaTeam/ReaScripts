-- @description Auto Change Video
-- @author Grayson Solis
-- @version 1.0
-- @about
--   - Auto selects nearest video track
--
--   - If selected track has video, unmute track’s video items and mute all others
--   - If selected track has no video, finds nearest track above it with video and unmutes that video item instead
--   - Ignores muted or collapsed tracks

--[[
@name Auto Change Video
@version 1.0
@author Grayson Solis
@description 

- Auto selects nearest video track

- If selected track has video, unmute track’s video items and mute all others
- If selected track has no video, finds nearest track above it with video and unmutes that video item instead
- Ignores muted or collapsed tracks

@website https://graysonsolis.com
@donations https://paypal.me/GrayTunes?country.x=US&locale.x=en_US
]]

-- Caching for performance

local GetTrack              = reaper.GetTrack
local GetParentTrack        = reaper.GetParentTrack
local GetMediaTrackInfo     = reaper.GetMediaTrackInfo_Value
local CountTracks           = reaper.CountTracks
local CountMediaItems       = reaper.CountTrackMediaItems
local GetMediaItem          = reaper.GetTrackMediaItem
local GetTake               = reaper.GetActiveTake
local GetSource             = reaper.GetMediaItemTake_Source
local GetSourceType         = reaper.GetMediaSourceType
local SetItemMute           = reaper.SetMediaItemInfo_Value
local PreventUIRefresh      = reaper.PreventUIRefresh
local defer                 = reaper.defer
local time_precise          = reaper.time_precise
local GetSelectedTrack      = reaper.GetSelectedTrack
local CountSelectedTracks   = reaper.CountSelectedTracks

local function isVisible(tr)
  while tr do
    tr = GetParentTrack(tr)
    if tr and GetMediaTrackInfo(tr, "I_FOLDERCOMPACT") == 1 then 
      return false 
    end
  end
  return true
end

local function isMuted(tr)
  while tr do
    if GetMediaTrackInfo(tr, "B_MUTE") == 1 then
      return true
    end
    tr = GetParentTrack(tr)
  end
  return false
end

local function collectVideoTracks(tbl)
  for i = 0, CountTracks(0) - 1 do
    local tr = GetTrack(0, i)
    if isVisible(tr) and not isMuted(tr) then
      for j = 0, CountMediaItems(tr) - 1 do
        local take = GetTake(GetMediaItem(tr, j))
        if take and GetSourceType(GetSource(take), "") == "VIDEO" then
          tbl[#tbl + 1] = { track = tr, idx = i }
          break  -- one video item per track is enough
        end
      end
    end
  end
end

local function processTrack(tr, mute)
  for j = 0, CountMediaItems(tr) - 1 do
    local item = GetMediaItem(tr, j)
    local take = GetTake(item)
    if take and GetSourceType(GetSource(take), "") == "VIDEO" then
      SetItemMute(item, "B_MUTE", mute and 1 or 0)
    end
  end
end

local last_idx = -1
local last_run = 0
local interval = 0.1  -- throttle interval in seconds (100 ms)
local vids     = {}

local function main()
  local sel = GetSelectedTrack(0, 0)
  local sel_idx = sel and GetMediaTrackInfo(sel, "IP_TRACKNUMBER") - 1 or -1

  if sel and CountSelectedTracks(0) == 1 and sel_idx ~= last_idx then
    last_idx = sel_idx

    local now = time_precise()
    if now - last_run >= interval then
      last_run = now

      vids = {}
      collectVideoTracks(vids)

      local target_idx
      for _, v in ipairs(vids) do
        if v.idx == sel_idx then
          target_idx = sel_idx
          break
        end
      end
      if not target_idx then
        for i = #vids, 1, -1 do
          if vids[i].idx < sel_idx then
            target_idx = vids[i].idx
            break
          end
        end
      end

      if target_idx then
        PreventUIRefresh(1)
        for _, v in ipairs(vids) do
          processTrack(v.track, v.idx ~= target_idx)
        end
        PreventUIRefresh(-1)
      end
    end
  end

  defer(main)
end

defer(main)
