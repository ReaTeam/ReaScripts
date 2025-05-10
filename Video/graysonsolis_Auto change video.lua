-- @description Auto change video
-- @author Grayson Solis
-- @version 1.0
-- @about
--   This script automatically “visually solos” the nearest video track (the selected track 
--   or the closest one above) by muting all other visible video tracks in the project.
--
--   ----------------------------------------------------------------------------------------
--   USE CASE
--   ----------------------------------------------------------------------------------------
--   Place reference videos on parent tracks and audio on children. As you select audio tracks, 
--   the script keeps only the relevant video unmuted—ideal for syncing sound layers to video 
--   without distraction from other clips.
--
--   Note: Throw this in a global startup action so you have it ready to go every time!
--
--   ----------------------------------------------------------------------------------------
--   BEHAVIOR
--   ----------------------------------------------------------------------------------------
--   • If no track or multiple tracks are selected → does nothing  
--   • If one track is selected →  
--       1. Builds a list of all visible video tracks  
--       2. Finds the video track at or above the selected track  
--       3. Mutes every other video track, leaving only the target unmuted  
--       4. Repeats continuously as you change selection


----------------------------------------------------------------------------------------
-- API CACHING FOR PERFORMANCE
----------------------------------------------------------------------------------------
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

----------------------------------------------------------------------------------------
-- HELPER: IS TRACK VISIBLE? (NOT IN A COLLAPSED FOLDER)
----------------------------------------------------------------------------------------
local function isVisible(tr)
  while tr do
    tr = GetParentTrack(tr)
    if tr and GetMediaTrackInfo(tr, "I_FOLDERCOMPACT") == 1 then 
      return false 
    end
  end
  return true
end

----------------------------------------------------------------------------------------
-- HELPER: COLLECT VISIBLE VIDEO TRACKS
----------------------------------------------------------------------------------------
local function collectVideoTracks(tbl)
  for i = 0, CountTracks(0) - 1 do
    local tr = GetTrack(0, i)
    if isVisible(tr) then
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

----------------------------------------------------------------------------------------
-- HELPER: MUTE/UNMUTE ALL VIDEO ITEMS ON A TRACK
----------------------------------------------------------------------------------------
local function processTrack(tr, mute)
  for j = 0, CountMediaItems(tr) - 1 do
    local item = GetMediaItem(tr, j)
    local take = GetTake(item)
    if take and GetSourceType(GetSource(take), "") == "VIDEO" then
      SetItemMute(item, "B_MUTE", mute and 1 or 0)
    end
  end
end

----------------------------------------------------------------------------------------
-- STATE & CACHE
----------------------------------------------------------------------------------------
local last_idx = -1  -- previous selection index
local vids     = {}  -- cache of video track entries

----------------------------------------------------------------------------------------
-- MAIN LOOP FUNCTION
----------------------------------------------------------------------------------------
local function main()
  -- 1. Only proceed with exactly one selected track
  local sel = reaper.GetSelectedTrack(0, 0)
  if not sel or reaper.CountSelectedTracks(0) > 1 then
    defer(main)
    return
  end

  -- 2. Get zero-based index of selected track
  local sel_idx = GetMediaTrackInfo(sel, "IP_TRACKNUMBER") - 1

  -- 3. If selection changed, rebuild and apply mutes
  if sel_idx ~= last_idx then
    last_idx = sel_idx
    vids = {}
    collectVideoTracks(vids)

    -- 4. Find target (equal or next highest)
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

    -- 5. Mute/unmute all video tracks
    if target_idx then
      PreventUIRefresh(1)
      for _, v in ipairs(vids) do
        processTrack(v.track, v.idx ~= target_idx)
      end
      PreventUIRefresh(-1)
    end
  end

  -- 6. Loop
  defer(main)
end

----------------------------------------------------------------------------------------
-- START SCRIPT
----------------------------------------------------------------------------------------
defer(main)
