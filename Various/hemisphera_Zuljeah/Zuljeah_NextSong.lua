-- @noindex

local function collectRegions()
  local regions = {}
  markerCount = reaper.CountProjectMarkers(0)
  for i = 0,markerCount-1 do
    ok, isRegion, posStart, posEnd, name, id = reaper.EnumProjectMarkers2(0, i)
    if (isRegion) then
      local r = {}
      r["id"] = id
      r["name"] = name
      r["sequence"] = 0
      r["start"] = posStart
      r["end"] = posEnd
      regions[i] = r
    end
  end
  return regions
end

local function findSetlistTrack()
  local trackCount = reaper.GetNumTracks()
  for i = 0, trackCount - 1 do
    local track = reaper.GetTrack(0, i)
    local isMuted = reaper.GetMediaTrackInfo_Value(track, 'B_MUTE')
    local ok, trackName = reaper.GetTrackName(track)
    if (isMuted == 0) and (string.find(trackName, "SETLIST")) then
      return track
    end
  end
  return nil
end

local function buildSetlist(track)
  if (track == nil) then
    track = findSetlistTrack()
  end
  if (track == nil) then
    return nil
  end

  local itemCount = reaper.GetTrackNumMediaItems(track)
  local regions = collectRegions()
  sq = {}
  local sortedRegions = {}
  for i = 0, itemCount - 1 do
    local mi = reaper.GetTrackMediaItem(track, i)
    local ok, take = reaper.GetSetMediaItemInfo_String(mi, "P_NOTES", "", false)
    local pos = reaper.GetMediaItemInfo_Value(mi, 'D_POSITION')
    local seq = tonumber(tostring(take))
    for k,v in pairs(regions) do
      if (v["start"] <= pos) and (v["end"] >= pos) then
        v["mediaitem"] = mi
        v["selected"] = reaper.IsMediaItemSelected(mi)
        sortedRegions[seq] = v
      end
    end
  end
  return sortedRegions
end

local function getSelectedIndex(setlist)
  totalItems = 0
  for k,v in pairs(setlist) do
    if (v["selected"]) then
      selectedIndex = k
    end
    totalItems = totalItems + 1
  end
  return selectedIndex, totalItems
end

local function setSelectedIndex(setlist, newIndex)
  selectedIndex, totalItems = getSelectedIndex(setlist)

  if (newIndex < 1) then
    newIndex = totalItems
  end
  if (newIndex > totalItems) then
    newIndex = 1
  end

  if (selectedIndex ~= nil) then
    reaper.SetMediaItemSelected(setlist[selectedIndex]["mediaitem"], false)
  end
  reaper.SetMediaItemSelected(setlist[newIndex]["mediaitem"], true)
  reaper.SetEditCurPos(setlist[newIndex]["start"], true, false)
end

local function modifySelectedIndex(setlist, delta)
  selectedIndex, totalItems = getSelectedIndex(setlist)
  if (selectedIndex == nil) then 
    setSelectedIndex(setlist, 1)
  else
    setSelectedIndex(setlist, selectedIndex + delta)
  end
end

--====--

setlistTrack = findSetlistTrack()
if (setlistTrack == nil) then
  return
end
setlist = buildSetlist(setlistTrack)
modifySelectedIndex(setlist, 1)
reaper.UpdateArrange()
