--[[
ReaScript Name: Add markers for lyrics in selected items
About:
  Looks through the lyrics in an item and adds a marker at each lyric.
Instructions:
  - Select items
  - Run the script
Author: beaunus
Licence: GPL v3
REAPER: 5.0
Version: 1.0
]]

--[[
 Changelog:
 * v1.0 (2017-02-20)
    + Initial Release
]]

-- Count the number of selected items.
num_selected_items = reaper.CountSelectedMediaItems()

-- Iterate through all selected items.
for i = 0, num_selected_items - 1 do
  item = reaper.GetSelectedMediaItem(0, i)
  -- Get the active take
  take = reaper.GetActiveTake(item)
  -- Process the take IFF the take contains MIDI
  if reaper.TakeIsMIDI(take) then
    -- Get all the MIDI events for this take
    ok, buf = reaper.MIDI_GetAllEvts(take, "")
    -- Proceed only if there are MIDI events to process
    if ok and buf:len() > 0 then
      --[[
      Since messages offsets are relative to the previous message,
      track the total offset, in order to know the position of the MIDI events
      --]]
      total_offset = 0
      pos = 1
      while pos <= buf:len() do
        offs, flag, msg = string.unpack("IBs4", buf, pos)
        total_offset = total_offset + offs
        adv = 4 + 1 + 4 + msg:len()
        -- Determine if this event is a lyric message
        if msg:byte(1) == 255 and msg:byte(2) == 5 then
          lyric = msg:sub(2)
          position = reaper.MIDI_GetProjTimeFromPPQPos(take, total_offset)
          -- Create the marker
          reaper.AddProjectMarker(0, false, position, 0, lyric, -1)
        end
        pos = pos+adv
      end
    end
  end
end