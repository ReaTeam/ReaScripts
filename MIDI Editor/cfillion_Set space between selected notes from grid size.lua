-- @description Set space between selected notes from grid size
-- @version 1.0.1
-- @changelog Fix behavior when multiple notes are at the same position.
-- @author cfillion
-- @link Forum Thread http://forum.cockos.com/showthread.php?t=187255
-- @donation https://www.paypal.me/cfillion

local editor = reaper.MIDIEditor_GetActive()
local take = reaper.MIDIEditor_GetTake(editor)
if not take or not reaper.ValidatePtr(take, 'MediaItem_Take*') then
  return reaper.defer(function() end)
end

local grid = reaper.MIDI_GetGrid(take)
local ni, last_end, changes = -1, nil, {}

while true do
  ni = reaper.MIDI_EnumSelNotes(take, ni)
  if ni == -1 then break end
  
  local _, _, _, startpos, endpos = reaper.MIDI_GetNote(take, ni)

  if last_end then
    local originalStartPos = reaper.MIDI_GetProjQNFromPPQPos(take, startpos)
    startpos = last_end + grid
    endpos = reaper.MIDI_GetProjQNFromPPQPos(take, endpos)

    if originalStartPos ~= startpos then
      endpos = endpos - (originalStartPos - startpos)
  
      table.insert(changes, {
        ni=ni, oldstart=startpos,
        newstart=reaper.MIDI_GetPPQPosFromProjQN(take, startpos),
        newend=reaper.MIDI_GetPPQPosFromProjQN(take, endpos),
      })
    end
  else
    endpos = reaper.MIDI_GetProjQNFromPPQPos(take, endpos)
  end
  
  last_end = endpos
end

if #changes == 0 then
  return reaper.defer(function() end)
end

reaper.Undo_BeginBlock()

for _,change in ipairs(changes) do
  reaper.MIDI_SetNote(take, change.ni, nil, nil,
    change.newstart, change.newend, nil, nil, nil, true)
end

reaper.MIDI_Sort(take)

local pointName = ({reaper.get_action_context()})[2]:match('([^/\\_]+).lua$')
reaper.Undo_EndBlock(pointName, -1)
