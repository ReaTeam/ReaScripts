-- @description Rearpeggiate
-- @author DEFENSE MECHANISM
-- @version 1.0beta1
-- @screenshot Usage https://imgur.com/a/pCoVVvO
-- @about
--   # Rearpeggiate
--
--   NOTE: Requires rtk https://reapertoolkit.dev/
--
--   Thanks to lunker for providing the MIDI Guitar Chord Tool, which this borrows from (heavily).
--
--   Usage: First, create a chord in the MIDI Editor. The arpeggio will last for the duration of the entire chord. Set the MIDI Editor grid size to the length of each note within the arpeggio. Select all notes of the chord and then press one of the buttons to create the arpeggio. Multiple sequential chords may be selected and will follow the same arpeggio pattern. Press Esc to close the window.
--
--   Explanation of the buttons:
--
--   Octave up/down - Each time the arpeggio repeats, it will repeat one octave up or down, respectively. To disable this just click the button that is already highlighted blue and it will be deselected.
--
--   Up - Arpeggiate notes from lowest to highest (e.g. 1 2 3 4 1 2 3 4...)
--
--   Down - Arpeggiate notes from highest to lowest (e.g. 4 3 2 1 4 3 2 1...)
--
--   Up/Down - Arpeggiate notes up, then down (e.g. 1 2 3 4 3 2 1 2...)
--
--   Down/Up - Arpeggiate notes down, then up (e.g. 4 3 2 1 2 3 4 3...)
--
--   UpInv - Arpeggiate up in inversions (e.g. 1 2 3 4 2 3 4 1 3 4 1 2...)
--
--   DownInv - Arpeggiate down in inversions (e.g. 4 3 2 1 3 2 1 4 2 1 4 3...)

local Info       = debug.getinfo (1, 'S');
local ScriptPath = Info.source:match[[^@?(.*[\/])[^\/]-$]];
--local DebugFile  = assert (io.open (ScriptPath .. 'debug.txt', 'w'));
--package.path     = ScriptPath .. './lib/lua/?.lua;' .. package.path;
package.path = reaper.GetResourcePath() .. '/Scripts/rtk/1/?.lua'
--require ('strict');
--require ('DataDumper');
--io.output (DebugFile);

--                   dofile (ScriptPath .. './lib/lua/lunker math.lua');
--
-- lunker reaper.lua
-- Useful Reaper functions (especially MIDI functions)
--

--[[
    Wish List:

        * Add MidiCc and MidiTextSysex classes (similar to the MidiNote class)

--]]

------------------------------------------------------------------------------------------------------------------------

local ReaperFunc = {};

------------------------------------------------------------------------------------------------------------------------

ReaperFunc.RunCommand = function (Command)

    if type (Command) == 'string' then
        reaper.Main_OnCommand (reaper.NamedCommandLookup (Command), 0); -- I'm not sure what the '0' is for ('1' also works ...)
    elseif type (Command) == 'integer' then
        reaper.Main_OnCommand (Command, 0);
    end

end -- function RunCommand

------------------------------------------------------------------------------------------------------------------------

-- This gets the MIDI take from the active MIDI Editor.
-- Call this when you need a MIDI take that must be open in a MIDI Editor.

ReaperFunc.GetMidiEditor = function ()

    local MidiEditor   =                reaper.MIDIEditor_GetActive ();
    local MidiTake     = MidiEditor and reaper.MIDIEditor_GetTake   (MidiEditor);
    local MidiTakeName = MidiTake   and reaper.GetTakeName          (MidiTake);

    return MidiEditor, MidiTake, MidiTakeName;

end -- function GetMidiEditor

------------------------------------------------------------------------------------------------------------------------

-- This gets the current take from the selected MIDI Media Item or active MIDI Editor.
-- Call this then you just need a MIDI take, and it doesn't matter if it is in a MIDI Editor or not.

ReaperFunc.GetMidiTake = function ()

    local MediaItem         =                   reaper.GetSelectedMediaItem (0, 0);
    local MediaItemTake     = MediaItem     and reaper.GetMediaItemTake     (MediaItem, reaper.GetMediaItemInfo_Value (MediaItem, 'I_CURTAKE'));
    local MediaItemTakeName = MediaItemTake and reaper.GetTakeName          (MediaItemTake);
    local MediaItemIsMidi   = MediaItemTake and reaper.TakeIsMIDI           (MediaItemTake);

-- If there is an open MIDI Editor, make sure that it is open to the selected Media Item
-- Note that this isn't strictly necessary, since I could just return the selected Media Item,
-- but this ensures that there is no confusion about which item is actually being returned.

    local MidiEditor   =                reaper.MIDIEditor_GetActive ();
    local MidiTake     = MidiEditor and reaper.MIDIEditor_GetTake   (MidiEditor);
    local MidiTakeName = MidiTake   and reaper.GetTakeName          (MidiTake);

    local MidiEditor, MidiTake, MidiTakeName = ReaperFunc.GetMidiEditorTake ();

    if MediaItemTake == MidiTake then
        return MediaItem, MediaItemTake, MediaItemTakeName;
    elseif MediaItemIsMidi and MidiTake then
        reaper.ShowMessageBox ('The selected Media/MIDI item and the active MIDI Editor refer to different items.\nPlease select the correct Media/MIDI item or close the MIDI Editor, and try again.', 'Invalid Selection', 0);
        return;
    elseif MediaItemIsMidi then
        return MediaItem, MediaItemTake, MediaItemTakeName;
    elseif MidiTake then
        return MidiEditor, MidiTake, MidiTakeName;
    else
        return;
    end

end -- function GetMidiTake

------------------------------------------------------------------------------------------------------------------------

ReaperFunc.GetAllMidiNoteIndexes = function (MidiTake)

-- NOTE -- Sorting helps get the notes in the correct order
--         (in case someone manually messed up the order).

    reaper.MIDI_Sort (MidiTake);

    local NoteIndexes = {};

-- TODO -- Is it better to use MIDI_CountEvts to get the number of notes?
--         I assume the notes indexes would just be 1 .. #NoteEvents ???

    local NoteIndex = 0;

    while NoteIndex >= 0 do

        local IsValidNote = reaper.MIDI_GetNote (MidiTake, NoteIndex);

        if IsValidNote then

            NoteIndexes[#NoteIndexes + 1] = NoteIndex;

            NoteIndex = NoteIndex + 1;

        else

            NoteIndex = -1;

        end

    end

    return NoteIndexes;

end -- function GetAllMidiNoteIndexes

------------------------------------------------------------------------------------------------------------------------

ReaperFunc.GetSelectedMidiNoteIndexes = function (MidiTake)

-- NOTE -- Sorting helps get the notes in the correct order
--         (in case someone manually messed up the order).

    reaper.MIDI_Sort (MidiTake);

    local NoteIndexes = {};

    local NoteIndex = reaper.MIDI_EnumSelNotes (MidiTake, -1);

    while NoteIndex >= 0 do

        NoteIndexes[#NoteIndexes + 1] = NoteIndex;

        NoteIndex = reaper.MIDI_EnumSelNotes (MidiTake, NoteIndex);

    end

    return NoteIndexes;

end -- function GetSelectedMidiNoteIndexes

------------------------------------------------------------------------------------------------------------------------

ReaperFunc.GetAllMidiNotes = function (MidiTake)

    local NoteIndexes = ReaperFunc.GetAllMidiNoteIndexes (MidiTake);

    if #NoteIndexes == 0 then

        reaper.ShowMessageBox ('You must select one or more notes in the MIDI Editor.', 'Error: No Notes Selected', 0);

        return {};

    end

    local MidiNotes = {};

    for iNote = 1, #NoteIndexes do

        MidiNotes[iNote] = ReaperFunc.MidiNote:Get (MidiTake, NoteIndexes[iNote]);

    end

    return MidiNotes;

end -- function GetAllMidiNotes

------------------------------------------------------------------------------------------------------------------------

ReaperFunc.GetSelectedMidiNotes = function (MidiTake)

    local NoteIndexes = ReaperFunc.GetSelectedMidiNoteIndexes (MidiTake);

    if #NoteIndexes == 0 then

        --reaper.ShowMessageBox ('You must select one or more notes in the MIDI Editor.', 'Error: No Notes Selected', 0);

        return {};

    end

    local MidiNotes = {};

    for iNote = 1, #NoteIndexes do

        MidiNotes[iNote] = ReaperFunc.MidiNote:Get (MidiTake, NoteIndexes[iNote]);

    end

    return MidiNotes;

end -- function GetSelectedMidiNotes

------------------------------------------------------------------------------------------------------------------------

ReaperFunc.DeleteAllMidiNotes = function (MidiTake)

    local MidiNotes = ReaperFunc.GetAllMidiNotes (MidiTake);

-- Need to iterate backwards throught the notes to make sure index-reassignment doesn't cause any notes to be skipped.

    for iMidiNote = #MidiNotes, 1, -1 do
        MidiNotes[iMidiNote]:Delete ();
    end

end -- function DeleteAllMidiNotes

------------------------------------------------------------------------------------------------------------------------

ReaperFunc.DeleteSelectedMidiNotes = function (MidiTake)

    local MidiNotes = ReaperFunc.GetSelectedMidiNotes (MidiTake);
    
    if #MidiNotes < 1 then
        return
    end

-- Need to iterate backwards throught the notes to make sure index-reassignment doesn't cause any notes to be skipped.

    for iMidiNote = #MidiNotes, 1, -1 do
        MidiNotes[iMidiNote]:Delete ();
    end

end -- function DeleteSelectedMidiNotes

------------------------------------------------------------------------------------------------------------------------

ReaperFunc.UnselectAllMidiNotes = function (MidiTake)

    local NoteIndexes = ReaperFunc.GetSelectedMidiNoteIndexes (MidiTake);

    for iNote = 1, #NoteIndexes do

        local MidiNote = ReaperFunc.MidiNote:Get (MidiTake, NoteIndexes[iNote]);

        MidiNote:Set ({Selected = false}, true);

    end

end -- function UnselectAllMidiNotes

------------------------------------------------------------------------------------------------------------------------

--[[

    "reaper.MIDI_Sort" doesn't seem to include the note number when resorting the notes (just start time and channel)

    The sorting algorithm is borrowed from this example:

        https://forums.coronalabs.com/topic/46704-how-to-sort-a-table-on-2-values/

        a.Start      < b.Start      : sort earlier notes first
        a.Channel    < b.Channel    : for the same start time, sort lower channels (higher strings) first
        a.NoteNumber > b.NoteNumber : for the same channel, sort higher note numbers first

    I'm not sure if I will ever need to sort CC or TextSysex events, but I'm leaving that option open with "SortMidiTakeCc" and "SortMidiTakeTextSysEx"

]]

ReaperFunc.SortMidiTake = function (MidiTake)

    reaper.MIDI_Sort (MidiTake);    -- use this first, in case it does something that I don't (and that I want it to do)

    ReaperFunc.SortMidiTakeNotes      (MidiTake);
--    ReaperFunc.SortMidiTakeCc         (MidiTake);
--    ReaperFunc.SortMidiTakeTextSysex  (MidiTake);

    reaper.MIDI_Sort (MidiTake);    -- and call it again, in case it does any clean-up after I deleted/re-created events

end -- function SortMidiTake

------------------------------------------------------------------------------------------------------------------------

ReaperFunc.SortMidiTakeNotes = function (MidiTake)

    local function SortNotesByStartThenChannelThenNoteNumber (a, b)
--[[ I sort of see what's wrong with this ...
        return (
            ((a.Start < b.Start)
            or
            (a.Start == b.Start and a.Channel < b.Channel))
            or
            (a.Channel == b.Channel and a.NoteNumber > b.NoteNumber)
        );
]]

        if (a.Start < b.Start) then
            return true;
        elseif (a.Start > b.Start) then
            return false;
        else
            if (a.Channel < b.Channel) then
                return true;
            elseif (a.Channel > b.Channel) then
                return false;
            else
                if (a.NoteNumber > b.NoteNumber) then
                    return true;
                elseif (a.NoteNumber <= b.NoteNumber) then
                    return false;
                end
            end
        end

    end

    local MidiNotes = ReaperFunc.GetAllMidiNotes (MidiTake);

    ReaperFunc.DeleteAllMidiNotes (MidiTake);

    local Notes = {};

    for iNote = 1, #MidiNotes, 1 do

        table.insert (
            Notes,
            {
--                iNote      = iNote,
                Note       = MidiNotes[iNote],
--                NoteIndex  = MidiNotes[iNote].NoteIndex,
                Start      = MidiNotes[iNote].NoteData.Start,
                Channel    = MidiNotes[iNote].NoteData.Channel,
                NoteNumber = MidiNotes[iNote].NoteData.NoteNumber,
            }
        );

    end

    table.sort (Notes, SortNotesByStartThenChannelThenNoteNumber);

    for iNote = 1, #Notes do

-- These next two statements are equivalent.
-- However, if I want to use "DataDumper (Notes)", I have to remove Note from the table,
-- which means I have to use the second form (which I think is not quite as straight-forward to understand)

        Notes[iNote].Note:Copy ({}, true);
--        MidiNotes[Notes[iNote].iNote]:Copy ({}, true);

    end -- for iNote

end -- function SortMidiTakeNotes

------------------------------------------------------------------------------------------------------------------------

ReaperFunc.GroupOverlappingMidiNotes = function (MidiNotes)

--[[
    Important to understand that note indexes will already be ordered by:
        * start time  (earlier items sort first)
        * channel     (lower channel numbers sort first)
        * note number (higher note numbers sort first)
--]]

    local NoteGroups = { { MidiNotes[1] } };

    local GroupStart = MidiNotes[1].NoteData.Start;
    local GroupEnd   = MidiNotes[1].NoteData.End;

    for iNote = 2, #MidiNotes do

        local NoteStart = MidiNotes[iNote].NoteData.Start;
        local NoteEnd   = MidiNotes[iNote].NoteData.End;

        if (NoteStart >= GroupStart) and (NoteStart < GroupEnd) then

            NoteGroups[#NoteGroups][#NoteGroups[#NoteGroups] + 1] = MidiNotes[iNote];

            if NoteEnd > GroupEnd then
                GroupEnd = NoteEnd
            end

        else

            NoteGroups[#NoteGroups + 1] = { MidiNotes[iNote] };

            GroupStart = MidiNotes[iNote].NoteData.Start;
            GroupEnd   = MidiNotes[iNote].NoteData.End;

        end

    end

    return NoteGroups;

end -- end function GroupOverlappingMidiNotes

------------------------------------------------------------------------------------------------------------------------

ReaperFunc.AlignMidiNoteStartTimes = function (MidiNotes)

    local Start = math.huge;

    for iNote = 1, #MidiNotes do

        if MidiNotes[iNote].NoteData.Start < Start then
            Start = MidiNotes[iNote].NoteData.Start;
        end

    end

    for iNote = 1, #MidiNotes do

        MidiNotes[iNote]:Set ({Start = Start}, true);  -- true = DO NOT RE-SORT !!!

    end

    return Start;

end -- AlignMidiNoteStartTimes

------------------------------------------------------------------------------------------------------------------------

ReaperFunc.AlignMidiNoteEndTimes = function (MidiNotes)

    local End = -1;

    for iNote = 1, #MidiNotes do

        if MidiNotes[iNote].NoteData.End > End then
            End = MidiNotes[iNote].NoteData.End;
        end

    end

    for iNote = 1, #MidiNotes do

        MidiNotes[iNote]:Set ({End = End}, true);  -- true = DO NOT RE-SORT !!! (although changing the end time shouldn't change indexes)

    end

    return End;

end -- AlignMidiNoteEndTimes

------------------------------------------------------------------------------------------------------------------------

ReaperFunc.StrumMidiNotes = function (MidiTake, StrumTime, AddRandomness, RandomnessSd)

--[[

    * Delays the start of all but the first note to create a guitar strum or piano roll.
    * Does not change the end point of any notes.


Original Notes:
------------------ : Channel 1
------------------ : Channel 2
------------------ : Channel 3
------------------ : Channel 4
------------------ : Channel 5
------------------ : Channel 6


Down Strum:
     ------------- : Channel 1
    -------------- : Channel 2
   --------------- : Channel 3
  ---------------- : Channel 4
 ----------------- : Channel 5
------------------ : Channel 6


Up Strum:
------------------ : Channel 1
 ----------------- : Channel 2
  ---------------- : Channel 3
   --------------- : Channel 4
    -------------- : Channel 5
     ------------- : Channel 6

--]]

--    reaper.MIDI_Sort (MidiTake);  -- doesn't work as expected !!!
    ReaperFunc.SortMidiTakeNotes (MidiTake);

    local MidiNotes = ReaperFunc.GetSelectedMidiNotes (MidiTake);

    if #MidiNotes == 0 then
        return;
    end

    local NoteGroups = ReaperFunc.GroupOverlappingMidiNotes (MidiNotes)

    local ChordStartPpq = {};
    local   ChordEndPpq = {};

    for iNoteGroup = 1, #NoteGroups do

        ChordStartPpq[iNoteGroup] = ReaperFunc.AlignMidiNoteStartTimes (NoteGroups[iNoteGroup]);
          ChordEndPpq[iNoteGroup] = ReaperFunc.AlignMidiNoteEndTimes   (NoteGroups[iNoteGroup]);

    end

    for iNoteGroup = 1, #NoteGroups do

        local ChordStartQn = reaper.MIDI_GetProjQNFromPPQPos (MidiTake, ChordStartPpq[iNoteGroup]);
        local   ChordEndQn = reaper.MIDI_GetProjQNFromPPQPos (MidiTake,   ChordEndPpq[iNoteGroup]);

        local StrumDelta = StrumTime / #NoteGroups[iNoteGroup];

-- Remember that the notes are added by the chord tool starting with string 1, so the highest string.
-- This next code assumes we want to start with a down strum, which orders the notes from last to first (lowest string to highest string).

        for iNote = #NoteGroups[iNoteGroup] - 1, 1, -1 do   -- don't include the first note (since we don't want to alter it)

            local NoteStartQn = ChordStartQn + StrumDelta * (#NoteGroups[iNoteGroup] - iNote);

            if AddRandomness then
                NoteStartQn = NoteStartQn + StrumDelta * xGauss (0, RandomnessSd);
            end

            if NoteStartQn > ChordStartQn and NoteStartQn < ChordEndQn then

                local NoteStartPpq = reaper.MIDI_GetPPQPosFromProjQN (MidiTake, NoteStartQn);

                NoteGroups[iNoteGroup][iNote]:Set ({Start = NoteStartPpq}, true);

            end

        end

    end

    reaper.MIDI_Sort (MidiTake);

end -- function StrumMidiNotes

------------------------------------------------------------------------------------------------------------------------

ReaperFunc.ArpeggiateMidiNotes = function (MidiTake, AddRandomness, RandomnessSd)

--[[

    * Distributes notes evently across the duration of the initial chord
    * Changes the end points of all but the last note
    * Note that to keep the chords in recognizable groups,
      this function creates a slight overlap of each note.


Original Notes:
------------------ : Channel 1
------------------ : Channel 2
------------------ : Channel 3
------------------ : Channel 4
------------------ : Channel 5
------------------ : Channel 6


Downward Arpeggio:
               --- : Channel 1
            ---    : Channel 2
         ---       : Channel 3
      ---          : Channel 4
   ---             : Channel 5
---                : Channel 6


Upward Arpeggio:
---                : Channel 1
   ---             : Channel 2
      ---          : Channel 3
         ---       : Channel 4
            ---    : Channel 5
               --- : Channel 6

--]]

--    reaper.MIDI_Sort (MidiTake);  -- doesn't work as expected !!!
    ReaperFunc.SortMidiTakeNotes (MidiTake);

    local MidiNotes = ReaperFunc.GetSelectedMidiNotes (MidiTake);

    if #MidiNotes == 0 then
        return;
    end

    local NoteGroups = ReaperFunc.GroupOverlappingMidiNotes (MidiNotes)

    local ChordStartPpq = {};
    local   ChordEndPpq = {};

    for iNoteGroup = 1, #NoteGroups do

        ChordStartPpq[iNoteGroup] = ReaperFunc.AlignMidiNoteStartTimes (NoteGroups[iNoteGroup]);
          ChordEndPpq[iNoteGroup] = ReaperFunc.AlignMidiNoteEndTimes   (NoteGroups[iNoteGroup]);

    end

    for iNoteGroup = 1, #NoteGroups do

        local  ChordStartQn = reaper.MIDI_GetProjQNFromPPQPos (MidiTake, ChordStartPpq[iNoteGroup]);
        local    ChordEndQn = reaper.MIDI_GetProjQNFromPPQPos (MidiTake,   ChordEndPpq[iNoteGroup]);
        local ChordLengthQn = ChordEndQn - ChordStartQn;
        local  NoteLengthQn = ChordLengthQn / #NoteGroups[iNoteGroup]

-- Adjust the end time of all but the last note,
-- Save the new end times, so they can be used when calculating the new start times

        local NoteEndsQn = {};

        for iNote = #NoteGroups[iNoteGroup], 2, -1 do   -- don't alter the end time of the last note

            local NoteEndQn = ChordStartQn + NoteLengthQn * (#NoteGroups[iNoteGroup] - iNote + 1);

            if AddRandomness then
                NoteEndQn = NoteEndQn + NoteLengthQn * xGauss (0, RandomnessSd);
            end

            NoteEndsQn[iNote] = NoteEndQn;

            if NoteEndQn > ChordStartQn and NoteEndQn < ChordEndQn then

                local NoteEndPpq = reaper.MIDI_GetPPQPosFromProjQN (MidiTake, NoteEndQn);

                NoteGroups[iNoteGroup][iNote]:Set ({End = NoteEndPpq + 1}, true);          -- I don't think I need this extra bit of overlap, but I feel safer using it

            end

        end

-- Adjust the start time of all but the first note,
-- using the end times saved above

        for iNote = #NoteGroups[iNoteGroup] - 1, 1, -1 do   -- don't alter the start time of the first note

            local NoteStartQn = NoteEndsQn[iNote + 1];

            if NoteStartQn > ChordStartQn and NoteStartQn < ChordEndQn then

                local NoteStartPpq = reaper.MIDI_GetPPQPosFromProjQN (MidiTake, NoteStartQn);

                NoteGroups[iNoteGroup][iNote]:Set ({Start = NoteStartPpq - 1}, true);      -- subtract 1 PPQ to ensure overlap with the next note

            end

        end

    end

    reaper.MIDI_Sort (MidiTake);

end -- function ArpeggiateMidiNotes

------------------------------------------------------------------------------------------------------------------------

ReaperFunc.ArpeggiateMidiNotesGrid = function (MidiTake, ArpTime, direction, octaves)


    --* Distributes notes according to grid time


--    reaper.MIDI_Sort (MidiTake);  -- doesn't work as expected !!!
    direction = direction or "up";
    octaves   = octaves or 0;

    ReaperFunc.SortMidiTakeNotes (MidiTake);

    local MidiNotes = ReaperFunc.GetSelectedMidiNotes (MidiTake);

    if #MidiNotes == 0 then
        return;
    end
    
    local NoteGroups = ReaperFunc.GroupOverlappingMidiNotes (MidiNotes)

    local ChordStartPpq = {};
    local   ChordEndPpq = {};
    local   ArpTimePpq  = reaper.MIDI_GetPPQPosFromProjQN(MidiTake, ArpTime);

    for iNoteGroup = 1, #NoteGroups do

        ChordStartPpq[iNoteGroup] = ReaperFunc.AlignMidiNoteStartTimes (NoteGroups[iNoteGroup]);
          ChordEndPpq[iNoteGroup] = ReaperFunc.AlignMidiNoteEndTimes   (NoteGroups[iNoteGroup]);

    end

    local AllChordPitches = {};
    local Channel = {};
    local Velocity = {};
    for iNoteGroup = 1, #NoteGroups do

        local  ChordStartQn = reaper.MIDI_GetProjQNFromPPQPos (MidiTake, ChordStartPpq[iNoteGroup]);
        local    ChordEndQn = reaper.MIDI_GetProjQNFromPPQPos (MidiTake,   ChordEndPpq[iNoteGroup]);
        local CurrentChordPitches = {};
        
        for iNote = 1, #NoteGroups[iNoteGroup], 1 do
               
            if iNote == 1 then
                Channel[iNoteGroup] = NoteGroups[iNoteGroup][iNote].NoteData.Channel;
                Velocity[iNoteGroup] = NoteGroups[iNoteGroup][iNote].NoteData.Velocity;
            end
            CurrentChordPitches[iNote] = NoteGroups[iNoteGroup][iNote].NoteData.NoteNumber;

        end

        AllChordPitches[iNoteGroup] = CurrentChordPitches;

    end
    
    ReaperFunc.DeleteSelectedMidiNotes(MidiTake);

    for iNoteGroup = 1, #NoteGroups do


        if direction == "up" or direction == "upinv" then
            table.sort(AllChordPitches[iNoteGroup]);
        elseif direction == "down" or direction == "downinv" then
            table.sort(AllChordPitches[iNoteGroup], function (a, b) return a > b end)
        elseif direction == "updown" then
            table.sort(AllChordPitches[iNoteGroup])
            local len = #AllChordPitches[iNoteGroup]
            for iNewPitch = len - 1, 2, -1 do
                table.insert(AllChordPitches[iNoteGroup], AllChordPitches[iNoteGroup][iNewPitch]);
            end
        elseif direction == "downup" then
            table.sort(AllChordPitches[iNoteGroup], function (a, b) return a > b end)
            local len = #AllChordPitches[iNoteGroup]
            for iNewPitch = len - 1, 2, -1 do
                table.insert(AllChordPitches[iNoteGroup], AllChordPitches[iNoteGroup][iNewPitch]);
            end
        end
        
        local NoteStart = ChordStartPpq[iNoteGroup];
        local NoteEnd = NoteStart + ArpTimePpq;
       
        while (NoteEnd < ChordEndPpq[iNoteGroup])
        do
        
            for iPitch = 1, #AllChordPitches[iNoteGroup], 1 do
            
              if AllChordPitches[iNoteGroup][iPitch] < 128 and AllChordPitches[iNoteGroup][iPitch] > 0 then
                reaper.MIDI_InsertNote(MidiTake, true, false, NoteStart, NoteEnd, Channel[iNoteGroup], AllChordPitches[iNoteGroup][iPitch], Velocity[iNoteGroup], true)
              end
                NoteStart = NoteEnd;
                NoteEnd = NoteEnd + ArpTimePpq;
                if NoteEnd > ChordEndPpq[iNoteGroup] then
                    break;
                end
            end 
            
            if direction == 'upinv' then
                newPitch = AllChordPitches[iNoteGroup][1] + 12;
                for iPitch = 1, #AllChordPitches[iNoteGroup] - 1, 1 do
                    AllChordPitches[iNoteGroup][iPitch] = AllChordPitches[iNoteGroup][iPitch + 1]
                end
                AllChordPitches[iNoteGroup][#AllChordPitches[iNoteGroup]] = newPitch
            elseif direction == 'downinv' then
                newPitch = AllChordPitches[iNoteGroup][1] - 12;
                for iPitch = 1, #AllChordPitches[iNoteGroup] - 1, 1 do
                    AllChordPitches[iNoteGroup][iPitch] = AllChordPitches[iNoteGroup][iPitch + 1]
                end
                AllChordPitches[iNoteGroup][#AllChordPitches[iNoteGroup]] = newPitch            
            end

            if octaves ~= 1 then
                for iPitch = 1, #AllChordPitches[iNoteGroup], 1 do
                  AllChordPitches[iNoteGroup][iPitch] = AllChordPitches[iNoteGroup][iPitch] + (12 * octave)
                end
            end        



        end
      
      end

    reaper.MIDI_Sort (MidiTake);

end -- function ArpeggiateMidiNotesGrid

------------------------------------------------------------------------------------------------------------------------

do

-- TODO -- Can I write it in this form ???
--
--  ReaperFunc.MidiNote = {
--      <put the functions here>
--  };
--
--  ReaperFunc.MidiNote.__index = ReaperFunc.MidiNote;

    ReaperFunc.MidiNote = {};

    ReaperFunc.MidiNote.__index = ReaperFunc.MidiNote;

--Lua: boolean retval, boolean selectedOut, boolean mutedOut, number startppqposOut, number endppqposOut, number chanOut, number pitchOut, number velOut
--     reaper.MIDI_GetNote(MediaItem_Take take, integer noteidx)

    local DataNames = {
--        'ValidNote',  -- I took this out of the hash/list, and store it as MidiNote.ValidNote
        'Selected',
        'Muted',
        'Start',
        'End',
        'Channel',
        'NoteNumber',
        'Velocity',
    };

    local List2Hash = function (List)
        local Hash = {};
        for iList = 1, #List do
            Hash[DataNames[iList]] = List[iList];
        end
        return Hash;
    end

    local Hash2List = function (Hash)
        local List = {};
        for iData = 1, #DataNames do
            List[iData] = Hash[DataNames[iData]];
        end
        return List;
    end

------------------------------------------------------------------------------------------------------------------------

function ReaperFunc.MidiNote:Dump ()

--[[
    TODO

    I edited DataDumper.lua to allow dumping userdata,
    but it still errors out on some other properties.

    I think I need to use 'type()' to see which properties are causing the errors,
    and then decide if I want to edit them in DataDumper.lua.
--]]

    return DataDumper ( {
        MidiTake  = self.MidiTake,
        NoteIndex = self.NoteIndex,
        ValidNote = self.ValidNote,
        NoteData  = self.NoteData,
    } );

end

------------------------------------------------------------------------------------------------------------------------

function ReaperFunc.MidiNote:Get (MidiTake, NoteIndex)

--[[
    This is a little bit hokey/over-complicated/confusing.
    The issue is that I want to use the :Get function for two things:

        * Return the MidiNote object when given a MidiTake and NoteIndex
        * Return the note properties just like reaper.MIDI_GetNote does

    That's easy enough.  The problem is that I don't want to do this:

        local MidiNote = ReaperFunc.MidiNote:Get (MidiTake, NoteIndex);
        local NoteProp = { MidiNote:Get () };

    So instead, it becomes:

        local MidiNote, Selected, Muted, Start, End, Channel, NoteNumber, Velocity = ReaperFunc.MidiNote:Get (MidiTake, NoteIndex);

    or

        local NoteProp = { ReaperFunc.MidiNote:Get (MidiTake, NoteIndex) };
        local MidiNote = table.remove (NoteProp, 1);

    I may ultimately decide to go back to having a separate :Read (or :Load) function
    that returns the MidiNote object, so that :Get can just return the properties.
    But for now, I am leaving it this way.

--]]

-- TODO -- this needs more/better parameter validation and error checking

    if (MidiTake == nil) or (NoteIndex == nil) then
        return self, Hash2List (self.NoteData);
    end

    local tNoteProperties = { reaper.MIDI_GetNote (MidiTake, NoteIndex) };

    local ValidNote = table.remove (tNoteProperties, 1); -- I don't want this in the NoteData, since it almost always needs to be stripped off

    local MidiNote = {
        MidiTake  = MidiTake,
        NoteIndex = NoteIndex,
        ValidNote = ValidNote,
        NoteData  = List2Hash ( tNoteProperties ),
    };

    setmetatable (MidiNote, self);

    return MidiNote, Hash2List (MidiNote.NoteData);

end -- function MidiNote:Get

------------------------------------------------------------------------------------------------------------------------

function ReaperFunc.MidiNote:Set (NewValues, NoSort)

    for Name, Value in pairs (NewValues) do

        self.NoteData[Name] = Value;

    end

--Lua: boolean reaper.MIDI_SetNote(MediaItem_Take take, integer noteidx, optional boolean selectedInOptional, optional boolean mutedInOptional,
--     optional number startppqposInOptional, optional number endppqposInOptional, optional number chanInOptional, optional number pitchInOptional,
--     optional number velInOptional, optional boolean noSortInOptional)

    local Selected, Muted, Start, End, Channel, NoteNumber, Velocity = table.unpack (Hash2List (self.NoteData));

    self.NoteData.ValidNote = reaper.MIDI_SetNote (self.MidiTake, self.NoteIndex, Selected, Muted, Start, End, Channel, NoteNumber, Velocity, NoSort);

    return self, Selected, Muted, Start, End, Channel, NoteNumber, Velocity;

end -- function MidiNote:Set

------------------------------------------------------------------------------------------------------------------------

-- I should have left better notes -- what is the difference between :Insert and :Copy?
-- Could I have done it better without duplicating the code?
-- Maybe make on function just call/alias the other?

function ReaperFunc.MidiNote:Insert (NewValues, NoSort)

    local NewNote = self;

    NewNote.NoteIndex = -1; -- would nil be better???

    for Name, Value in pairs (NewValues) do

        NewNote.NoteData[Name] = Value;

    end

    local Selected, Muted, Start, End, Channel, NoteNumber, Velocity = table.unpack (Hash2List (NewNote.NoteData));

    NewNote.NoteData.ValidNote = reaper.MIDI_InsertNote (NewNote.MidiTake, Selected, Muted, Start, End, Channel, NoteNumber, Velocity, NoSort);

    return NewNote, Selected, Muted, Start, End, Channel, NoteNumber, Velocity;

end -- function MidiNote:Insert

------------------------------------------------------------------------------------------------------------------------

function ReaperFunc.MidiNote:Copy (NewValues, NoSort)

    local NewNote = self;

    NewNote.NoteIndex = -1; -- would nil be better???

    for Name, Value in pairs (NewValues) do

        NewNote.NoteData[Name] = Value;

    end

    local Selected, Muted, Start, End, Channel, NoteNumber, Velocity = table.unpack (Hash2List (NewNote.NoteData));

    NewNote.NoteData.ValidNote = reaper.MIDI_InsertNote (NewNote.MidiTake, Selected, Muted, Start, End, Channel, NoteNumber, Velocity, NoSort);

    return NewNote, Selected, Muted, Start, End, Channel, NoteNumber, Velocity;

end -- function MidiNote:Copy

------------------------------------------------------------------------------------------------------------------------

function ReaperFunc.MidiNote:Delete ()

    reaper.MIDI_DeleteNote (self.MidiTake, self.NoteIndex);

-- TODO -- should this return anything?
        -- perhaps set self to {} and return it ???

end -- function MidiNote:Delete

------------------------------------------------------------------------------------------------------------------------

end -- end DataNames localization

------------------------------------------------------------------------------------------------------------------------

local function Arpeggiate (direction, octaves)

    local MidiEditor, MidiTake, MidiTakeName = ReaperFunc.GetMidiEditor ();
    local ArpTime = reaper.MIDI_GetGrid (MidiTake);
    reaper.Undo_BeginBlock ();
    ReaperFunc.ArpeggiateMidiNotesGrid (MidiTake, ArpTime, direction, octaves)
    
    reaper.UpdateArrange ();    -- Update the arrangement (often needed)

    reaper.Undo_EndBlock ('Arpeggiate MIDI Chord', 0);

end
reaper.ClearConsole();
-- Set package path to find rtk installed via ReaPack
-- Now we can load the rtk library.
local rtk = require('rtk')
local log = rtk.log
-- Set the current log level to INFO
log.level = log.INFO

local window = rtk.Window{borderless=true}

local octaves = 0;
local buttonUp = rtk.Button{'   Up   ', margin=5, minw=40, halign='center', fillw=true, width=40}

buttonUp.onclick = function(self, event)

    Arpeggiate("up", octaves);
end
local buttonDown = rtk.Button{'  Down  ', margin=5, fillw=true, width=40}

buttonDown.onclick = function(self, event)

    Arpeggiate("down", octaves);
end
local buttonUpDown = rtk.Button{' Up/Down ', margin=5, fillw=true, width=40}
-- Add an onclick handler to respond to mouse clicks of the button
buttonUpDown.onclick = function(self, event)

    Arpeggiate("updown", octaves);
end
local buttonDownUp = rtk.Button{' Down/Up ', margin=5, fillw=true, width=40}

buttonDownUp.onclick = function(self, event)

    Arpeggiate("downup", octaves);
end
local buttonUpInv = rtk.Button{' Up Inv ', margin=5, fillw=true, width=40}

buttonUpInv.onclick = function(self, event)

    Arpeggiate("upinv", octaves);
end
local buttonDownInv = rtk.Button{'Down Inv ', margin=5, fillw=true, width=40}

buttonDownInv.onclick = function(self, event)

    Arpeggiate("downinv", octaves);
end
local vbox = rtk.VBox{vspacing=2, hspacing=2, halign='center'}
local vbox_buttons = rtk.VBox{vspacing=2, hspacing=2}

local hbox = rtk.HBox{vspacing = 2, hspacing = 2}
local buttonOctUp    = rtk.Button{'Octave Up', margin=5, color='gray'}
local buttonOctDown  = rtk.Button{'Octave Down', margin=5, color='gray'}
buttonOctUp.onclick = function(self, event)
  if octave ~= 1 then
    octave = 1
    self:attr('color','blue')
    buttonOctDown:attr('color','gray');
    buttonOctDown:attr('disabled',false);
  else
    octave = 0
    self:attr('color','gray')
  end
end
buttonOctDown.onclick = function(self, event)
  if octave ~= -1 then
    octave = -1
    self:attr('color','blue')
    buttonOctUp:attr('color','gray');
    buttonOctUp:attr('disabled',false);
  else
    octave = 0
    self:attr('color','gray')
  end
end

hbox:add(buttonOctUp)
hbox:add(buttonOctDown)

vbox:add(rtk.Heading{'Rearpeggiate', margin=5, halign="center"})
vbox:add(rtk.Spacer(), {expand=1, fillh=true, bg='black'})
vbox:add(hbox)
vbox:add(vbox_buttons)


vbox_buttons:add(buttonUp)
vbox_buttons:add(buttonDown)
vbox_buttons:add(buttonUpDown)
vbox_buttons:add(buttonDownUp)
vbox_buttons:add(buttonUpInv)
vbox_buttons:add(buttonDownInv)
window:add(vbox)

window:open{align='center'}
