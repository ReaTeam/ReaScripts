-- @description Search selected notes in chord finder
-- @version 1.1
-- @author Mordi
-- @changelog
--  This script will take any selected notes and generate a URL
--  that will show what chord the notes make, if any.
--  It uses the wonderful site "www.scales-chords.com" to
--  do this.
--
--  Made by Mordi, Jan 2016

-- Function for opening a URL
function OpenURL(url)
  local OS = reaper.GetOS()
  if OS == "OSX32" or OS == "OSX64" then
    os.execute('open "" "' .. url .. '"')
  else
    os.execute('start "" "' .. url .. '"')
  end
end

function Msg(str)
  reaper.ClearConsole();
  reaper.ShowConsoleMsg(tostring(str) .. "\n")
end

-- Init note name-array (for use in URL)
noteNames = {"C", "C%23", "D", "D%23", "E", "F", "F%23", "G", "G%23", "A", "A%23", "B"}

-- Get HWND
hwnd = reaper.MIDIEditor_GetActive()

-- Get current take being edited in MIDI Editor
take = reaper.MIDIEditor_GetTake(hwnd)

-- Check if the take exists
if take == nil then
  Msg("Chord finder: Whoops! No take selected.")
else
  -- Count all notes in take
  retval, notes, ccs, sysex = reaper.MIDI_CountEvts(take)
  
  -- Setup variables for number of selected notes
  -- and an array to hold the pitch of selected notes
  selNum = 0
  selNotePitch = {}
  
  -- Loop through every note in take, and get selected notes
  -- and their pitch
  for i = 0, notes-1 do
    retval, sel, muted, startppqposOut, endppqposOut, chan, pitch, vel = reaper.MIDI_GetNote(take, i)
    
    if sel == true then
      -- Don't add note if it already exists
      note_is_dupe = false
      for n = 0, selNum-1 do
        if (selNotePitch[n] % 12) == (pitch % 12) then
          note_is_dupe = true
        end
      end
      if not note_is_dupe then -- Add note to array
        selNotePitch[selNum] = pitch % 12
        selNum = selNum + 1
      end
    end
  end
  
  -- If more than 6 notes are selected, we can't generate a URL
  if (selNum > 6) then
    Msg("Chord-finder: Whoops! Can't select more than 6 notes.")
  else
    -- If no notes are selected we can't generate a URL
    if (selNum == 0) then
      Msg("Chord-finder: Whoops! No notes selected.")
    else
      -- Generate URL to chord-finder
      url = "http://www.scales-chords.com/findnotes_en.php?"
      for i = 0, selNum-1 do
        url = url .. "n" .. tostring(i + 1) .. "=" .. noteNames[selNotePitch[i] + 1] .. "&"
      end
      
      -- Set "do not allow additional notes"
      url = url .. "strict=1"
      
      -- Open url in browser
      OpenURL(url)
    end
  end
end
