-- Description: Join selected overlapping and consecutive notes with spacing below threshold - input and no input versions
-- Version: 1.0.1
-- Author: FnA
-- Changelog: Fix syntax error in lines 116 and 133. About section improvements.
-- Link: Forum Thread http://forum.cockos.com/showthread.php?t=143366
-- About:
--   This package script makes two actions in the MIDI Editor Action List.
--   The scripts should join only selected notes. Unselected overlapping notes may be re-sorted 
--   in a fashion similar to what happens when using Undo in the MIDI Editor or changing Active Item via Tracklist. 
--   The scripts should join only unmuted notes to unmuted notes and muted to muted. 
--   Input integer into the input box version to allow that number of ticks at most between notes to be joined.
-- MetaPackage: true
-- Provides:
--   [main=midi_editor] . > FnA_Join selected overlapping and consecutive (adjacent) notes.lua
--   [main=midi_editor] . > FnA_Join selected overlapping and consecutive notes with spacing below threshold (input box).lua

local filename = ({reaper.get_action_context()})[2]:match("([^/\\_]+).lua$")
local isInput = filename:match("input")

---------------------------------------------------
function Fn_Make_T_CPx4()
  local t = {}
  for i=1,16 do
    t[i] = {}
    for j=1,128 do
      t[i][j] = {false, false, false, false} -- 2 for not muted/2 for muted
    end
  end
  return t
end
----------------------------------
function Fn_Join_Selected_Notes(take,MJS)
  local T_CP = Fn_Make_T_CPx4() -- note channel and pitch matrix
  local t1 = {} -- for pre packed variables, because need to "" some out
  local tableEvents = {} -- for packed string
  local gotAllOK, MIDIstring = reaper.MIDI_GetAllEvts(take, "")
  local MIDIlen = MIDIstring:len()  
  local s_on, s_empty = "on",""
  local i, runningppqpos, prevoffset, stringPos = 1, 0, 0, 1
  local offset, flags, msg, c, p
  local doit = true
  -------------------------------------------------------------------------------------
  local function Fn_Do_Note_On(a,b)
    local ok = false
    if T_CP[c][p][a] then -- NOT first note at this channel and pitch.
      if T_CP[c][p][a] == s_on then -- less offs than ons between here and first joinable on.
        T_CP[c][p][b] = T_CP[c][p][b] + 1 -- number of note ons to be joined into one. used in note off section
        prevoffset = offset -- not inserting this event so increase prevoffset for next event if necessary
      else -- note has been shut off
        local space = runningppqpos - T_CP[c][p][a] -- distance to T_CP table value (re)assigned by note off to running ppq position
        if space <= MJS then -- join notes. No new on required.
          t1[T_CP[c][p][b] ] [3] = s_empty -- "" note off msg in other table
          T_CP[c][p][a] = s_on -- note is not off anymore
          T_CP[c][p][b] = 1 -- all note ons but one should have been removed
          prevoffset = offset
        else -- new note on
          ok = true
          T_CP[c][p][a] = s_on
          T_CP[c][p][b] = 1
        end
      end
    else -- first note in item at this channel and pitch. T_CP[c][p][1] = false currently
      ok = true
      T_CP[c][p][a] = s_on -- note is on
      T_CP[c][p][b] = 1 -- count of ons to be joined into one
    end -- end of note on section
    return ok
  end
  
  local function Fn_Do_Note_Off(a,b)
    local ok = false
    if T_CP[c][p][b] == 1 then -- correct number of note ons to allow this insertion
      ok = true
      T_CP[c][p][a] = runningppqpos -- for join/don't join use with next note on at this channel/pitch
      T_CP[c][p][b] = i -- index in other table in case needs to be "" out
    else -- better be another note off after this one...
      prevoffset = offset
      T_CP[c][p][b] = T_CP[c][p][b]-1 -- number of note ons reduced
    end -- end of note off section
    return ok
  end
  ------------------------------------------------------------------------------------
  while stringPos < MIDIlen do
    offset, flags, msg, stringPos = string.unpack("i4Bs4", MIDIstring, stringPos)
    offset = offset + prevoffset
    runningppqpos = runningppqpos + offset
    prevoffset = 0
    doit = true
    if msg:len() == 3 then
      local mb1 = msg:byte(1) --MIDI event type and channel
      local evt = mb1 >> 4 --MIDI event type
      local mb3 = msg:byte(3) -- velocity
      if (evt == 9 and (flags&1) == 1) and (mb3 ~= 0) then -- Note-on MIDI event type and selected and not 0 velocity
        c = (mb1 & 0xf) + 1 -- channel
        p = (msg:byte(2)) + 1 -- pitch
        if (flags&2) == 2 then doit = Fn_Do_Note_On(3,4) else doit = Fn_Do_Note_On(1,2) end -- muted or not
      elseif ( (evt == 8 and (flags&1) == 1) ) or ( (evt == 9) and ((flags&1) == 1) and (mb3 == 0) )then -- Note-off. (or on with Vel 0)
        c = (mb1 & 0xf) + 1 -- channel
        p = (msg:byte(2)) + 1 -- pitch
        if (flags&2) == 2 then doit = Fn_Do_Note_Off(3,4) else doit = Fn_Do_Note_Off(1,2) end
      end -- end of if note ons/offs section
    end -- if msg:len() == 3 then
    if doit == true then 
      t1[i] = {offset, flags, msg}
      i = i+1
    end
  end -- while
  
  for i=1,#t1 do tableEvents[i] = string.pack("i4Bs4", t1[i][1], t1[i][2], t1[i][3]) end
  reaper.MIDI_SetAllEvts(take, table.concat(tableEvents))
end -- function Fn_Join_Selected_Notes(take,MJS)

---------------------------------------------------------------
local MJS -- "Max Join Spacing"
if isInput then
  local retval, input_str = reaper.GetUserInputs("Join Selected Notes", 1, "Max Spacing (Ticks)", "0")
  if retval == true then MJS = tonumber(input_str) else MJS = nil end
else
  MJS = 0
end
if MJS then
  local take = reaper.MIDIEditor_GetTake(reaper.MIDIEditor_GetActive())
  if take then 
    Fn_Join_Selected_Notes(take,MJS)
    reaper.MIDI_Sort(take)
    reaper.Undo_OnStateChange("join selected notes")
  end
else
  function noundo() end
  reaper.defer(noundo)
end
if isInput and reaper.APIExists("SN_FocusMIDIEditor") then
  reaper.SN_FocusMIDIEditor() 
end -- because input box returns focus to Main
