--[[
Reascript name: js_Notation - Select notes by user-supplied notation text.lua
Version: 2.0
Author: juliansader
Donation: https://www.paypal.me/juliansader
]]

--[[
Changelog:
  * v1.0 (2019-11-17)
    + Initial beta release
  * v2.0 (2021-09-11)
    + Apply (only) to all editable takes.
]]

-- Get edtor so that can return focus after opening and closing dialog window
editor = reaper.MIDIEditor_GetActive()
if not (editor and reaper.MIDIEditor_GetMode(editor) ~= -1) then
    reaper.MB("Could not detect an active MIDI editor.", "ERROR", 0)
    return
end

-- Get user inputs
ok, inputs = reaper.GetUserInputs("Select notes by notation", 1, "Keywords (\"\" for phrases)", "")
reaper.JS_Window_SetFocus(editor)
if not ok then return end

-- Parse input to separate into individual keywords and phrases
tWords = {}
inputs = inputs:gsub("\"(.-)\"", function(word) tWords[#tWords+1] = word return "" end) -- Get phrases
inputs = inputs:gsub("(%S+)", function(word) tWords[#tWords+1] = word return "" end) -- Get remaining isolated words
if #tWords == 0 then return end


-----------------------------------------------
-- Find all editable takes (that contain notes)
reaper.Undo_BeginBlock2(0)

tT = {}
timeLeft, timeRight = reaper.GetSet_LoopTimeRange2(0, false, false, 0, 0, false)
reaper.GetSet_LoopTimeRange2(0, true, false, 0, 1000000, false) -- Is 1000000s enough?
reaper.MIDIEditor_LastFocused_OnCommand(40877, false) -- Select all notes in time selection

for i = 0, reaper.CountMediaItems(0)-1 do
    local item = reaper.GetMediaItem(0, i)
    local take = reaper.GetActiveTake(item)
    if reaper.ValidatePtr2(0, take, "MediaItem_Take*") and reaper.TakeIsMIDI(take) and reaper.MIDI_EnumSelNotes(take, -1) == 0 then -- Get potential takes that contain notes. NB == 0 
        tT[take] = true
    end
end

reaper.MIDIEditor_LastFocused_OnCommand(40214, false) -- Deselect all

for take in next, tT do
    if reaper.MIDI_EnumSelNotes(take, -1) ~= -1 then tT[take] = nil end -- Remoce takes that were not affected by deselection
end

reaper.GetSet_LoopTimeRange2(0, true, false, timeLeft, timeRight, false)

--reaper.Undo_EndBlock2(0, "qwerty", 0) -- Other scripts that use this hack must undo.  However, since this script will in any case deselect and re-select, no need to undo
--if reaper.Undo_CanUndo2(0) == "qwerty" then reaper.Undo_DoUndo2(0) end


----------------------------------------------------------------------
-- First, iterate through all items and takes in the entire project
--    and deselect all MIDI events in all take *except* the active take    
countNotes = 0 -- Count how many notes selected

for take in next, tT do

    local ok, midi = reaper.MIDI_GetAllEvts(take, "")
    if not ok then
        reaper.MB("Could not load the MIDI string.", "ERROR", 0)
        return
    end
    
    -- Find notation that match input, store in tNotation
    local ticks, prevPos, pos, savePos = 0, 1, 1, 1
    local tNotation = {}
    local countNotation = 0
    while pos < #midi do
        offset, flags, msg, pos = string.unpack("i4Bs4", midi, pos)
        ticks = ticks + offset
        if offset == 0 and msg:sub(1,7) == "\255\15NOTE " then
            local match = true
            for _, word in ipairs(tWords) do
                if not msg:match(word) then
                    match = false break
                end
            end
            if match then
                countNotation = countNotation + 1
                local chan, pitch = msg:match("NOTE (%d+) (%d+) ")
                if chan and pitch then
                    chan  = (tonumber(chan)//1)%16
                    pitch = (tonumber(pitch)//1)%256
                    tNotation[(ticks<<12) | (pitch<<4) | chan] = true
                end
            end
        end
    end
    
    -- Find notes that match notation
    if countNotation > 0 then
        ticks, prevPos, pos, savePos = 0, 1, 1, 1
        local tNoteOns = {}
        local tMidi = {}
        while prevPos < #midi do
            local offset, flags, msg, pos = string.unpack("i4Bs4", midi, prevPos)
            ticks = ticks + offset
            if flags&1==0 and #msg==3 then 
                local select = false
                local chan = msg:byte(1)&0x0F
                local pitch = msg:byte(2)
                -- Note-on: check if matching NOTATION
                if msg:byte(1)>>4 == 9 and msg:byte(3) ~= 0 then
                    if tNotation[(ticks<<12) | (pitch<<4) | chan] then
                        select = true
                        tNoteOns[(pitch<<4) | chan] = true -- Remember that note on this channel and pitch is still being played
                    end
                -- Note-off: check if matching NOTE-ON
                elseif msg:byte(1)>>4 == 8 or (msg:byte(1)>>4 == 9 and msg:byte(3) == 0) then
                    if tNoteOns[(pitch<<4) | chan] then -- Is this note still being played?
                        select = true
                        countNotes = countNotes + 1
                        tNoteOns[(pitch<<4) | chan] = nil
                    end
                end
                if select then
                    flags = flags|1
                    if savePos < prevPos then tMidi[#tMidi+1] = midi:sub(savePos, prevPos-1) end
                    tMidi[#tMidi+1] = string.pack("i4Bs4", offset, flags, msg)
                    savePos = pos
                end
            end
            prevPos = pos
        end
        if savePos < #midi then tMidi[#tMidi+1] = midi:sub(savePos, nil) end
    
        if next(tNoteOns) then
            reaper.MB("Some note-ons did not have matching note-offs.\n\nNo changes were made to the MIDI.", "ERROR", 0)
            return
        end
    
        reaper.MIDI_SetAllEvts(take, table.concat(tMidi))
    end
    
    reaper.MarkTrackItemsDirty(reaper.GetMediaItemTake_Track(take), reaper.GetMediaItemTake_Item(take))
end

reaper.Undo_EndBlock2(0, "Select ".. tostring(countNotes) .." notes by notation", -1)
