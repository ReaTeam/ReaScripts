-- This script is part of:
-- * cfillion_Select destination tracks of selected tracks sends recursively.lua
-- * cfillion_Select source tracks of selected tracks receives recursively.lua
--
-- @noindex
--
-- Global settings (must be set before including this file):
-- background  [boolean] this script is a one-shot (without undo point) by default
-- destination [boolean] whether to work on sends (select destinations) or receives (select sources)

local selected = {}

local function wasSelected(match)
  for i,track in ipairs(selected) do
    if track == match then
      return true
    end
  end

  return false
end

local function highlight(track, select)
  local send_receive = destination and 0 or -1

  for i=0, reaper.GetTrackNumSends(track, send_receive)-1 do
    local target = reaper.BR_GetMediaTrackSendInfo_Track(
      track, send_receive, i, destination and 1 or 0)

    reaper.SetTrackSelected(target, select)

    if select then
      highlight(target, select)
    end
  end
end

local function main()
  for i,track in ipairs(selected) do
    local valid = reaper.ValidatePtr(track, 'MediaTrack*')
    local isSelected = valid and reaper.IsTrackSelected(track)

    if not isSelected then
      table.remove(selected, i)

      if valid then
        highlight(track, false)
      end
    end
  end

  for i=0,reaper.CountSelectedTracks(0)-1 do
    local track = reaper.GetSelectedTrack(0, i)

    if not wasSelected(track) then
      selected[#selected + 1] = track
    end

    highlight(track, true)
  end

  reaper.defer(background and main or function() end)
end

main()
