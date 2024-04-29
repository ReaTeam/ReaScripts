-- @description Normalize project encoding
-- @author cfillion
-- @version 1.0
-- @metapackage
-- @provides [main] . > cfillion_Normalize project encoding to NFC.lua
-- @donate https://reapack.com/donate
-- @link Request thread https://forum.cockos.com/showthread.php?t=290779
-- @about
--   This scripts normalizes the encoding of the current project to Unicode Normalization Form C. The following objects are converted:
--
--   - Project marker names
--   - Project region names
--   - Take marker names
--   - Take names
--   - Track names

local NORMALIZE_MODE = 1 -- NFC
local SCRIPT_NAME = select(2, reaper.get_action_context()):match("([^/\\_]+)%.lua$")

local function normalizeName(thing, getSetInfoString)
  local name = select(2, getSetInfoString(thing, 'P_NAME', '', false))
  name = reaper.CF_NormalizeUTF8(name, NORMALIZE_MODE)
  getSetInfoString(thing, 'P_NAME', name, true)
end

if not reaper.CF_NormalizeUTF8 then
  reaper.MB('Version 2.14 or newer of the SWS extension is required.', SCRIPT_NAME, 0)
  return
end

reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()

for ti = 0, reaper.GetNumTracks() - 1 do
  local track = reaper.GetTrack(nil, ti)
  normalizeName(track, reaper.GetSetMediaTrackInfo_String)
end

for ii = 0, reaper.CountMediaItems(nil) - 1 do
  local item = reaper.GetMediaItem(nil, ii)
  for ti = 0, reaper.CountTakes(item) - 1 do
    local take = reaper.GetMediaItemTake(item, ti)
    normalizeName(take, reaper.GetSetMediaItemTakeInfo_String)

    if reaper.GetNumTakeMarkers then
      for mi = 0, reaper.GetNumTakeMarkers(take) - 1 do
        local name = select(2, reaper.GetTakeMarker(take, mi))
        name = reaper.CF_NormalizeUTF8(name, NORMALIZE_MODE)
        reaper.SetTakeMarker(take, mi, name)
      end
    end
  end
end

for mi = 0, math.huge do
  local retval, isrgn, pos, rgnend, name, index = reaper.EnumProjectMarkers(mi)
  if retval < 1 then break end
  name = reaper.CF_NormalizeUTF8(name, NORMALIZE_MODE)
  reaper.SetProjectMarker(index, isrgn, pos, rgnend, name)
end

reaper.Undo_EndBlock(SCRIPT_NAME, 1|4|8)
reaper.PreventUIRefresh(-1)
