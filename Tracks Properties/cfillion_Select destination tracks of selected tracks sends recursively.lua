-- @description Select destination tracks of selected tracks sends recursively
-- @version 1.1.1
-- @author cfillion
-- @changelog Simpler packaging using new ReaPack features (no other code changes).
-- @link Forum Thread http://forum.cockos.com/showthread.php?t=183638
-- @donation https://www.paypal.me/cfillion
-- @provides
--   [main] .
--   [main] . > cfillion_Select destination tracks of selected tracks sends recursively (background).lua

-- This file is also used by cfillion_Select source tracks of selected tracks sends recursively.lua

local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+).lua$")
local background = script_name:match("background")
local destination = script_name:match("destination")

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
