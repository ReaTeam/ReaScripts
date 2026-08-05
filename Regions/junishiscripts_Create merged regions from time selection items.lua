-- @description Create merged regions from time selection items
-- @author Junishi Scripts
-- @version 1.0.0
-- @link X https://x.com/1496jun
-- @about
--   - Purpose
--   Creates merged regions from media items within the current time selection in REAPER.
--
--   - Key Features
--   Time Selection Based: Only items inside the current time selection are considered.
--   Strict Item Range: Ignores fades—uses pure item start/end points.
--   Auto Expansion: Regions expand to include overlapping items.
--   Region Merging: Overlapping areas are merged into one.
--
--
--   - Usage
--   Set a time selection.
--   Run the script.
--   Regions will be created and labeled based on overlapping items.

reaper.Undo_BeginBlock()

-- Time Selection 範囲取得
local time_start, time_end = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
if time_end <= time_start then
  reaper.MB("Please set a valid time selection.", "Error", 0)
  return
end

-- フェードを考慮せず、純粋なアイテム範囲のみを対象にする（安定性重視）
local function get_strict_item_range(item)
  local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
  local len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
  return pos, pos + len
end

-- 指定された範囲に含まれるアイテムを使って拡張
local function expand_region(start_pos, end_pos)
  local changed = true
  local iteration = 0
  while changed and iteration < 10 do
    changed = false
    local new_start = start_pos
    local new_end = end_pos

    for t = 0, reaper.CountTracks(0) - 1 do
      local track = reaper.GetTrack(0, t)
      for i = 0, reaper.CountTrackMediaItems(track) - 1 do
        local item = reaper.GetTrackMediaItem(track, i)
        local istart, iend = get_strict_item_range(item)

        if iend > start_pos and istart < end_pos then
          if istart < new_start then
            new_start = istart
            changed = true
          end
          if iend > new_end then
            new_end = iend
            changed = true
          end
        end
      end
    end

    start_pos = new_start
    end_pos = new_end
    iteration = iteration + 1
  end

  return start_pos, end_pos
end

-- Region候補収集
local raw_regions = {}

for t = 0, reaper.CountTracks(0) - 1 do
  local track = reaper.GetTrack(0, t)
  for i = 0, reaper.CountTrackMediaItems(track) - 1 do
    local item = reaper.GetTrackMediaItem(track, i)
    local istart, iend = get_strict_item_range(item)

    if iend > time_start and istart < time_end then
      local r_start, r_end = expand_region(istart, iend)
      table.insert(raw_regions, {start = r_start, endp = r_end})
    end
  end
end

-- Region統合
table.sort(raw_regions, function(a, b) return a.start < b.start end)

local merged = {}
for _, r in ipairs(raw_regions) do
  if #merged == 0 then
    table.insert(merged, r)
  else
    local last = merged[#merged]
    if r.start <= last.endp then
      last.endp = math.max(last.endp, r.endp)
    else
      table.insert(merged, r)
    end
  end
end

-- Region作成
for i, r in ipairs(merged) do
  reaper.AddProjectMarker2(0, true, r.start, r.endp, "TSRegion_" .. i, -1, 0)
end

reaper.Undo_EndBlock("Create stable merged regions from time selection", -1)

