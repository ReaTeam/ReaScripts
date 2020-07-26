--[[
@description Distribute MIDI notes evenly
@version 1.0.0
@author Talagan
@license MIT
@link Forum Thread https://forum.cockos.com/showthread.php?t=240332
@provides
  [nomain] .
  [main=main,midi_editor] talagan_Distribute MIDI notes evenly (grid size).lua
  [main=main,midi_editor] talagan_Distribute MIDI notes evenly (param).lua
  [main=main,midi_editor] talagan_Distribute MIDI notes evenly (last param).lua
@about
  Redistribute the selected MIDI notes evenly in time, based on notes start, starting from the first note, and given a spacing value. Note lengths are preserved.

  Exists under three versions :
    - Param : use a param for the spacing value. The param should be in the project time format (Time/Beats/etc). Use an empty value to use the MIDI editor grid size.
    - Last Param : Same as above, but skip the param dialog and reuse last entered value
    - Grid size : Same as above,  but skip the param dialog and use the MIDI editor grid size directly. This does not affect the last param, so you can alternate between last param and grid size for a faster workflow.
--]]

DEBUG = false;

function debug(msg)
  if DEBUG then
    reaper.ShowConsoleMsg(msg);
  end
end

function performMidiDistribution(spacing_str)
  
  local hwnd = reaper.MIDIEditor_GetActive()
  local take = reaper.MIDIEditor_GetTake(hwnd)
  
  if not take then
    return
  end

  -- Gather selected notes
  local retval, notes, ccs, sysex = reaper.MIDI_CountEvts(take) -- count all notes(events)
  local i = 0
  local notes_selected={}
  for i=0, notes-1 do
    local retval, sel, muted, startppq, endppq, chan, pitch, vel = reaper.MIDI_GetNote(take, i)
    if sel == true then 
      notes_selected[#notes_selected+1] = { 
        idx = i,
        start_time = startppq, 
        end_time = endppq,
      }
    end
    i=i+1
  end
  
  -- Get start time in various formats
  local global_start_ppq  = notes_selected[1].start_time;
  local global_start_qn   = reaper.MIDI_GetProjQNFromPPQPos(take, notes_selected[1].start_time); 
  local global_start_time = reaper.MIDI_GetProjTimeFromPPQPos(take, notes_selected[1].start_time);
  
  local spacing = nil;
  
  -- Deduce spacing value from the current context (first note position and project time options)
  if spacing_str == nil or spacing_str == '' then
    -- If no spacing param is given, get the midi grid size
    spacing = reaper.MIDI_GetGrid(take);
  else
    -- Else, convert the given param to QNs, using project time format 
    local tspacing = reaper.parse_timestr_len(spacing_str, global_start_time, -1);
    local ppqend   = reaper.MIDI_GetPPQPosFromProjTime(take, global_start_time + tspacing);
    spacing = reaper.MIDI_GetProjQNFromPPQPos(take, ppqend) - reaper.MIDI_GetProjQNFromPPQPos(take, global_start_ppq);
  end
  
  -- loop on selected notes
  for index, note in ipairs(notes_selected) do
   
    -- deduce start and end
    local new_start = reaper.MIDI_GetPPQPosFromProjQN(take, global_start_qn + (index-1) * spacing);
    local new_end   = new_start + (note.end_time - note.start_time);
    
    debug( note.idx .. " : " .. note.start_time .. " > " .. new_start .. "\n");
    
    -- Move the MIDI note
    -- Don't sort during the loop, this will screw up everything
    reaper.MIDI_SetNote(take, note.idx, nil, nil, new_start, new_end, nil, nil,nil, true ); 
  end
  
  -- Now sort
  reaper.MIDI_Sort(take);
  
  -- Save last user input
  if spacing_str ~= nil then
    reaper.SetExtState("talagan_Distribute MIDI notes evenly", "spacing", spacing_str, true);
  end
  
end
