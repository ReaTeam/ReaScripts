--[[
ReaScript name: js_Navigate - Select next note in same channel.lua
Version: 0.90
Author: juliansader
Website: http://forum.cockos.com/showthread.php?t=191780
REAPER: v5.32 or later
Extensions: None required
Donation: https://www.paypal.me/juliansader
About:
  # Description
  Similar to REAPER's native action "Navigate: Select next note", but only selects notes within same channel as currently selected note. 
]] 

--[[
  Changelog:
  * v0.90 (2017-05-29)
    + Initial beta release    
]]

-- This script uses the fast MIDI API functions that were introduced in REAPER v5.32
if not reaper.APIExists("MIDI_GetAllEvts") then
    reaper.ShowMessageBox("This version of the script requires REAPER v5.32 or higher.", "ERROR", 0)
    return(false) 
end   

local editor = reaper.MIDIEditor_GetActive()
if editor == nil then 
    reaper.ShowMessageBox("No active MIDI editor found.", "ERROR", 0)
    return(false)
end

local take = reaper.MIDIEditor_GetTake(editor)
if not reaper.ValidatePtr(take, "MediaItem_Take*") then 
    reaper.ShowMessageBox("Could not find an active take in the MIDI editor.", "ERROR", 0)
    return(false)
end

-- The script will now parse all the MIDI in the take.  The parsing is similar to how REAPER natively allows events, CCs/notes/textsysex and selected CCs/notes/textsysex to be enumerate separately.
-- The information will be organized into several tables.
-- Only the tEvents tahle will contain actual MIDI data and PPQ positions.
-- All the other tables will only contain indices to entries in other tables.
-- Each entry in tCCs will be the index of a CC event in tEvents.  Similarly for tTextSysex.
-- Each entry in tNotes will contain two or three indices: to the note-on, note-off and (where relevant) notation text events for each note.
-- The tSel tables contain indices of selected CCs, notes or text/sysex.  The tSel entries refer to tNotes, tCCs and tSelTextSysex - not directly to tEvents.
-- Thus, tSelNotes contain indices of entries in tNotes, and tNotes contains indices of entries in tEvents.
-- tNotesWithNotation is an improvement over REAPER's native parsing, since it allows enumeration of notes with notation.
local tEvents = {} 
local tNotes = {}
--local tCCs = {}
local tTextSysex = {}
local tSelEvents = {}
local tSelNotes = {}
--local tSelCCs = {}
local tSelTextSysex = {}
local tNotesWithNotation = {}
local tNotationWithoutNotes = {}
local e, c, n, t, se, sn, sc, st, nn = 0, 0, 0, 0, 0, 0, 0, 0, 0 -- Indices in tables. (Zero means no entries yet.) My indices start at 1, not 0 like REAPER's

-- Since the notes will be navigated in sequence, the MIDI data must of course be sorted first.
reaper.MIDI_Sort(take)

-- While parsing the MIDI string, the indices of the last note-ons for each channel/pitch/flag must be temporarily stored until a matching mote-off is encountered. 
local runningNotes = {}
for channel = 0, 15 do
    runningNotes[channel] = {}
    for pitch = 0, 127 do
        runningNotes[channel][pitch] = {}
    end
end

-- Get all MIDI data and then parse through it    
local gotAllOK, MIDIstring = reaper.MIDI_GetAllEvts(take, "")
local stringPos = 1 -- Position inside MIDIstring while parsing
local runningPPQpos = 0
local MIDIlen = MIDIstring:len() - 12 -- Don't parse the final 12 bytes, which provides the All-Notes-Off message
local offset, flags, msg, selected

while stringPos < MIDIlen do
    offset, flags, msg, stringPos = string.unpack("i4Bs4", MIDIstring, stringPos)
    runningPPQpos = runningPPQpos + offset  
    selected = (flags&1 == 1)      
    
    -- All events are stored in tEvents
    e = e + 1
    tEvents[e] = {ppqpos   = runningPPQpos,
                  flags    = flags,
                  msg      = msg
                 }
    -- The indices to selected events within tEvents are stored in tSelEvents
    if selected then 
        se = se + 1
        tSelEvents[se] = e
    end     
        
    if msg ~= "" then -- Don't need to analyze empty events that simply change PPQ position
        local eventType = msg:byte(1)>>4
        
        if eventType == 9 and msg:byte(3) ~= 0 then -- Note-ons
            local channel = msg:byte(1)&0x0F
            local pitch   = msg:byte(2)
            if runningNotes[channel][pitch][flags] then
                reaper.ShowMessageBox("The script encountered overlapping notes.\n\nSuch notes are not valid MIDI, and can not be parsed.", "ERROR", 0)
                return false
            else
                n = n + 1
                tNotes[n] = {noteOnIndex = e}
                if selected then
                    sn = sn + 1 
                    tSelNotes[sn] = n
                end
                runningNotes[channel][pitch][flags] = n
            end
        
        elseif eventType == 8 or (eventType == 9 and msg:byte(3) == 0) then
            local channel = msg:byte(1)&0x0F
            local pitch   = msg:byte(2)
            local lastNoteOnIndex = runningNotes[channel][pitch][flags]
            if lastNoteOnIndex then
                tNotes[lastNoteOnIndex].noteOffIndex = e
                runningNotes[channel][pitch][flags] = nil
            end
        --[[
        elseif eventType > 9 and eventType < 0xF then
            c = c + 1 
            tCCs[c] = e
            if flags&1 == 1 then
                sc = sc + 1
                tSelCCs[sc] = c
            end
        ]]
        elseif eventType == 15 then
            t = t + 1
            tTextSysex[t] = e
            if selected then
                st = st + 1
                tSelTextSysex[st] = t
            end
        
            if msg:byte(1) == 0xFF then
                local channel, pitch = msg:match("NOTE (%d+) (%d+)")
                if channel then
                    channel, pitch = tonumber(channel), tonumber(pitch)
                    for i = #tNotes, 0, -1 do 
                        local noteOn = tEvents[ tNotes[i].noteOnIndex]
                        if noteOn.ppqpos == runningPPQpos and noteOn.msg:byte(1)&0x0F == channel and noteOn.msg:byte(2) == pitch then
                            tNotes[i].notationIndex = e
                            nn = nn + 1
                            tNotesWithNotation[nn] = i
                            goto gotNotationNote
                        end
                    end
                    tNotationWithoutNotes[#tNotationWithoutNotes+1] = e
                end
                ::gotNotationNote::
            end
        end   
    end
end

-- Get PPQ position of final All-Notes-Off
offset, _, _, _ = string.unpack("i4Bs4", MIDIstring, stringPos)
local AllNotesOffPPQpos = runningPPQpos + offset


------------------------------------------------
-- Parsing done!  Now start searching for notes.

if #tSelNotes == 0 then -- If no selected notes, simply quit.
    return 
else

    -- Get channel of rightmost selected note
    local lastSelNoteIndex  = tSelNotes[#tSelNotes] -- Index inside notes table of last selected note
    local channel = (tEvents[ tNotes[ lastSelNoteIndex].noteOnIndex].msg:byte(1)) & 0x0F
        
    -- Now search ahead for note with matching channel    
    for i = lastSelNoteIndex + 1, #tNotes do
        if channel == (tEvents[ tNotes[i].noteOnIndex].msg:byte(1)) & 0x0F then
            indexOfNoteToSelect = i
            break
        end
    end
    
    -- If no matching note is found, indexOfNoteToSelect will be undefined/nil
    if not indexOfNoteToSelect then
    
        -- Simply exit without changing enything
        return
        
    else
        -- Select the matching note (by changing flags of note-on and note-off events)
        tEvents[ tNotes[indexOfNoteToSelect].noteOnIndex].flags = tEvents[ tNotes[indexOfNoteToSelect].noteOnIndex].flags | 1
        tEvents[ tNotes[indexOfNoteToSelect].noteOffIndex].flags = tEvents[ tNotes[indexOfNoteToSelect].noteOffIndex].flags | 1
        
        -- DEselect all previously selected notes
        for s = 1, #tSelNotes do
            local noteIndex = tSelNotes[s]
            tEvents[ tNotes[noteIndex].noteOnIndex].flags = tEvents[ tNotes[noteIndex].noteOnIndex].flags & 0xFE
            tEvents[ tNotes[noteIndex].noteOffIndex].flags = tEvents[ tNotes[noteIndex].noteOffIndex].flags & 0xFE
        end
    end

    -- Now upload the altered MIDI into the take
    -- Pack all events into correct format, place in table, and concatenate into long string
    local tableEvents = {}
    local t = 0
    local prevPPQpos, offset = 0, 0
    for i = 1, #tEvents do
        offset = tEvents[i].ppqpos - prevPPQpos
        t = t + 1
        tableEvents[t] = string.pack("i4Bs4", offset, tEvents[i].flags, tEvents[i].msg)
        prevPPQpos = tEvents[i].ppqpos
    end
    -- Add the All-Notes-Off that must end all of REAPER's MIDI takes
    t = t + 1
    tableEvents[t] = string.pack("i4Bi4BBB", AllNotesOffPPQpos - prevPPQpos, 0, 3, 0xB0, 0x7B, 0x00)
    
    reaper.MIDI_SetAllEvts(take, table.concat(tableEvents))
    
    reaper.Undo_OnStateChange_Item(0, "Select next note in same channel", reaper.GetMediaItemTake_Item(take))

end


