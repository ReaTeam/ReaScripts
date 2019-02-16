-- @description Select destination tracks of selected tracks sends recursively
-- @version 1.2
-- @author cfillion
-- @changelog
--   Fix a bug causing some tracks to not be selected in a single shot
--   Ignore muted sends
--   Select tracks up the folder hierarchy (obeying parent send)
-- @link Forum thread https://forum.cockos.com/showthread.php?t=183638
-- @donation https://www.paypal.me/cfillion
-- @provides
--   [main] .
--   [main] . > cfillion_Select destination tracks of selected tracks sends recursively (background).lua

-- This file is also used by cfillion_Select source tracks of selected tracks sends recursively.lua

local scriptName = ({reaper.get_action_context()})[2]:match("([^/\\_]+).lua$")
local background = scriptName:match("background")
local destination = scriptName:match("destination")

local selected = {}

local function wasSelected(match)
  for i,track in ipairs(selected) do
    if track == match then
      return true
    end
  end

  return false
end

local function enumSendTracks(track)
  local sendReceive = destination and 0 or -1
  local trackType = destination and 1 or 0
  local i, max = -1, reaper.GetTrackNumSends(track, sendReceive) - 1

  return function()
    while i < max do
      i = i + 1

      local muted = reaper.GetTrackSendInfo_Value(track, sendReceive, i, 'B_MUTE') == 1

      if not muted then
        return reaper.BR_GetMediaTrackSendInfo_Track(
          track, sendReceive, i, trackType)
      end
    end
  end
end

local function enumDirectChildTracks(track)
  local index = reaper.GetMediaTrackInfo_Value(track, 'IP_TRACKNUMBER')
  local depth = reaper.GetMediaTrackInfo_Value(track, 'I_FOLDERDEPTH')
  local count = reaper.CountTracks(0)

  return function()
    while depth > 0 and index < count do
      track = reaper.GetTrack(0, index)

      local direct = depth == 1
      local parentSend = reaper.GetMediaTrackInfo_Value(track, 'B_MAINSEND') == 1

      index = index + 1
      depth = depth + reaper.GetMediaTrackInfo_Value(track, 'I_FOLDERDEPTH')

      if direct and parentSend then
        return track
      end
    end
  end
end

local function highlight(track, select)
  for target in enumSendTracks(track) do
    reaper.SetTrackSelected(target, select)

    if select then
      highlight(target, select)
    end
  end

  if destination then
    local parentSend = reaper.GetMediaTrackInfo_Value(track, 'B_MAINSEND') == 1
    local parent = parentSend and reaper.GetParentTrack(track)
    if parent then
      reaper.SetTrackSelected(parent, select)
      highlight(parent, select)
    end
  else
    for child in enumDirectChildTracks(track) do
      reaper.SetTrackSelected(child, select)
      highlight(child, select)
    end
  end
end

local function main()
  for i=0,reaper.CountSelectedTracks(0)-1 do
    local track = reaper.GetSelectedTrack(0, i)

    if not wasSelected(track) then
      table.insert(selected, track)
    end
  end

  for i,track in ipairs(selected) do
    local valid = reaper.ValidatePtr(track, 'MediaTrack*')
    local isSelected = valid and reaper.IsTrackSelected(track)

    if isSelected then
      highlight(track, true)
    else
      -- background mode: unselect destination of unselected tracks
      table.remove(selected, i)

      if valid then
        highlight(track, false)
      end
    end
  end

  reaper.defer(background and main or function() end)
end

main()
