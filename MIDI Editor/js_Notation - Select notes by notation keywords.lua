--[[
Reascript name: js_Notation - Select notes by notation keywords.lua
Version: 1.03
Author: juliansader
Donation: https://www.paypal.me/juliansader
About:
    If a note has notation information, REAPER stores this information as easily readable text inside a MIDI text event.
    For example, a note in channel 1 and pitch 64 that is notated in the high voice in the top staff 
        will carry notation text "NOTE 0 64 staff 1 voice 1".
    (To figure out the code that REAPER uses, open the "Raw MIDI data" window, which will display all notation text.) 
    
    This script allows the user select notes based on notation text.  
    It opens a dialog window in which the user can enter any text, such as "staff 1" "voice beam", 
        and the script will select all notes with notation that matches the input.  
    (To search for strings containing spaces, such as "voice 1", surround the string with quotation marks.)
]]

--[[
Changelog:
  * v1.00 (2019-11-17)
    + Initial beta release
  * v1.01 (2019-11-18)
    + Some About info.
  * v1.02 (2019-11-18)
    + Fix: Allow multiple phrases, each surrounded by quotation marks.
  * v1.03 (2019-11-18)
    + Change name.
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

take = reaper.MIDIEditor_GetTake(editor)
if not (take and reaper.ValidatePtr2(0, take, "MediaItem_Take*")) then
    reaper.MB("Could not find the active take of the MIDI editor.", "ERROR", 0)
    return
end
local ok, midi = reaper.MIDI_GetAllEvts(take, "")
if not ok then
    reaper.MB("Could not load the MIDI string.", "ERROR", 0)
    return
end

-- Find notation that match input, store in tNotation
local ticks, prevPos, pos, savePos = 0, 1, 1, 1
tNotation = {}
count = 0
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
            count = count + 1
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
if count > 0 then
    ticks, prevPos, pos, savePos = 0, 1, 1, 1
    local tNoteOns = {}
    local tMidi = {}
    count = 0
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
                    count = count + 1
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

item = reaper.GetMediaItemTake_Item(take)
if item then 
    track = reaper.GetMediaItem_Track(item)
    if track then 
        reaper.MarkTrackItemsDirty(track, item)
        reaper.Undo_OnStateChange_Item(0, "Select ".. tostring(count) .. " notes by notation", item)
end end
