--[[
@noindex
@author Talagan
@license MIT
@about
  This is the lib file for the Distribute MIDI notes evenly feature.
  See the companion action file for details.
--]]


DEBUG = false;

function debug(msg)
  if DEBUG then
    reaper.ShowConsoleMsg(msg);
  end
end

function performMidiDistribution(spacing_str, should_modify_last_param)
  
  local hwnd = reaper.MIDIEditor_GetActive()
  local take = reaper.MIDIEditor_GetTake(hwnd)
  
  if not take then
    return
  end
  
  -- Sanitize the spacing string to 'grid size' mode
  if spacing_str == nil then
    spacing_str = ''
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
  if spacing_str == '' then
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
  if should_modify_last_param == true then
    reaper.SetExtState("talagan_Distribute MIDI notes evenly", "spacing", spacing_str, true);
  end
  
end

-- Extract the (parameter value) from the lua action script name
function extractActionParamFromFileName()
  local _, sfname = reaper.get_action_context()
  -- Get the file name
  sfname = string.match(sfname,"/([^/]+)$")
  -- Get the param inside parenthesis
  local pname  = sfname.match(sfname,"%((.*)%)")
  return pname
end

-- Interprete the lua action parameter
function translateActionParam(action_param)
  
  local param, mplus                    = string.match(action_param,"(.-)(%+?)$");
  local should_modify_last_saved_param  = (#mplus == 1);
  local param_is_valid                  = true;
  
  -- TODO : potentially do some other conversions (n beats -> 0.n.0, 1/2 bar -> 0.0.5 etc)
  if param == "grid size" then
    param = '' -- convention
  elseif param == "last param" then
    param = reaper.GetExtState("talagan_Distribute MIDI notes evenly", "spacing");
  elseif param == "dialog" then
    param_is_valid, param = reaper.GetUserInputs("Enter a spacing value (No value = grid size)",
      1,
      "Spacing (use project time format), extrawidth=100",
      reaper.GetExtState("talagan_Distribute MIDI notes evenly", 
      "spacing"
      ));
  end  
  
  return param_is_valid, param, should_modify_last_saved_param;
end

function performMidiDistributionDependingOnActionFileName()
  -- Get action param from the script name
  local action_param = extractActionParamFromFileName();
  -- Convert it if possible (some param names may be aliases)
  local param_is_valid, action_param, should_modify_last_param = translateActionParam(action_param);
  
  if not param_is_valid then
    return
  end
  
  performMidiDistribution(action_param, should_modify_last_param)
end

