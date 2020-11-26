-- @description Select all MIDI notes that share MIDI channel with selection
-- @author Erik Landskov
-- @version 1.0
-- @about Simple script that selects all notes that share a MIDI channel with your selection. For example, if you have a note on MIDI channel 4 selected, then it will select all other notes on MIDI channel 4. This is handy if you like to use MIDI channels to organize groups of notes. With multiple notes selected, it will use the first note's channel.

-- used this thread for lots of help: https://forum.cockos.com/showthread.php?t=171015

take = reaper.MIDIEditor_GetTake(reaper.MIDIEditor_GetActive())

retval, notes, ccs, sysex = reaper.MIDI_CountEvts(take) -- count notes

i = 0
channel = 0

-- get the selected channel (will use first note of selection)
for i=0, notes-1 do
  --loop through every note to find the selected one, idk any other way to do it
  retval, sel, muted, startppq, endppq, chan, pitch, vel = reaper.MIDI_GetNote(take, i)
    if sel == true then -- find which notes are selected
      channel = chan -- set channel to the selected note's channel (channel 1 = 0 here)
      break
    end
  i=i+1
end

for i=0, notes-1 do
  retval, sel, muted, startppq, endppq, chan, pitch, vel = reaper.MIDI_GetNote(take, i)
    if chan == channel then -- find which notes match the channel
      reaper.MIDI_SetNote(take, i, true) -- select them
    end
  i=i+1
end

