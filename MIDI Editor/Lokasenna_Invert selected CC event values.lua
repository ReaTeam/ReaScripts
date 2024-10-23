--[[
    Description: Invert selected CC event values
    Version: 1.0.0
    Author: Lokasenna
    Donation: https://paypal.me/Lokasenna
    Changelog:
        Initial Release
    Links:
        Lokasenna's Website http://forum.cockos.com/member.php?u=10417
    About:
        Inverts the values of the selected CC events. That is:
        0 -> 127
        127 -> 0
        n -> 127-n

    Donation: https://www.paypal.me/Lokasenna
]]--

local editor = reaper.MIDIEditor_GetActive()
if not editor then return end

local take = reaper.MIDIEditor_GetTake(editor)
if not take then return end

reaper.Undo_BeginBlock()

local ccIdx = -1
while true do
  ccIdx = reaper.MIDI_EnumSelCC(take, ccIdx)
  if ccIdx == -1 then break end

  -- msg3 is the CC value
  local _, _, _, _, _, _, _, msg3 = reaper.MIDI_GetCC(take, ccIdx)

  reaper.MIDI_SetCC(take, ccIdx, nil, nil, nil, nil, nil, nil, 127 - msg3, true)
end

reaper.MIDI_Sort(take)

-- Hack to make Reaper recognize that the item was altered
local item = reaper.GetMediaItemTake_Item(take)
reaper.SetMediaItemSelected(item, false)
reaper.SetMediaItemSelected(item, true)

reaper.Undo_EndBlock("Invert selected CC event values", 4)
