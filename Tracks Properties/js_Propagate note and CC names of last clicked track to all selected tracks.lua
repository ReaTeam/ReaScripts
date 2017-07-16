--[[
ReaScript name: js_Propagate note and CC names of last clicked track to all selected tracks.lua
Version: 1.10
Author: juliansader
Website: http://forum.cockos.com/showthread.php?t=181276
Donation: https://www.paypal.me/juliansader
About:
  # Description

  Propagates the note and CC names of last clicked track to all selected tracks.
  
  The script will open a dialog box in which the user can:
  * confirm or change the source track, and
  * select whether all existing note names in the selected tracks should be removed.
]]

--[[
Changelog:
  * v1.00 (2016-09-13)
    + Initial release
  * v1.10 (2017-07-16)
    + Updated to propagate CC names as well as note names.
]]

--------------------------------------------------------------------
-- Find last-clicked track, which will serve as default source track
sourceTrack = reaper.GetLastTouchedTrack()
if reaper.ValidatePtr2(0, sourceTrack, "MediaTrack*") then
    sourceString = tostring(reaper.GetMediaTrackInfo_Value(sourceTrack, "IP_TRACKNUMBER"))
    sourceString = sourceString:gsub("%.%d+", "")
else
    sourceString = ""
end

--[[
editor = reaper.MIDIEditor_GetActive()
if editor ~= nil then
    activeTake = reaper.MIDIEditor_GetTake(editor)
    if reaper.ValidatePtr2(0, activeTake, "MediaItem_Take*") then
        sourceTrack = reaper.GetMediaItemTake_Track(activeTake)
        if reaper.ValidatePtr2(0, sourceTrack, "MediaTrack*") then
            sourceString = tostring(reaper.GetMediaTrackInfo_Value(sourceTrack, "IP_TRACKNUMBER"))
            sourceString = sourceString:gsub("%.%d+", "")
end end end
if not (type(tonumber(sourceString)) == "number") then sourceString = "" end
]]            

-------------------------------------------------
-- Get user inputs (user may change source track)
repeat
    inputOK, input = reaper.GetUserInputs("Propagate note names", 2, "Source track number,Clear existing note/CC names?", sourceString .. ",y")
    if not inputOK then return end
    
    sourceIndex, mustClear = input:match("(%d+),([yYnN])")
    sourceIndex = tonumber(sourceIndex)
until (type(sourceIndex) == "number" and sourceIndex <= reaper.CountTracks(0))

if mustClear == "y" or mustClear == "Y" then mustClear = true else mustClear = false end

---------------------------------------
-- Find all named notes in source track
tableNotes = {}
for pitch_CC = 0, 500 do -- Pitch range from 0 to 127, CCs from 128 onwards.  (Highest CC is probably 415.)
    for channel = 0, 15 do
        -- NB: GetTrackMIDINoteName is zero-based, whereas GetMediaTrackInfo is 1-based
        --    therefore substract 1 from index.
        name = reaper.GetTrackMIDINoteName(sourceIndex-1, pitch_CC, channel)
        if type(name) == "string" and name ~= "" then
            table.insert(tableNotes, {channel=channel, pitch_CC=pitch_CC, name=name})
        end
    end
end

----------------------------------------------
-- Propagate note names to all selected tracks
numSelTracks = reaper.CountSelectedTracks(0)
for t = 0, numSelTracks-1 do
    destTrack = reaper.GetSelectedTrack(0, t)
    destIndex = reaper.GetMediaTrackInfo_Value(destTrack, "IP_TRACKNUMBER")
    if destIndex ~= sourceIndex then
    
        -- First clear existing note names
        if mustClear then
            for pitch_CC = 0, 500 do
                for channel = 0, 15 do
                    reaper.SetTrackMIDINoteName(destIndex-1, pitch_CC, channel, "")
                end
            end
        end
        
        -- Now write new note names
        for n = 1, #tableNotes do
            reaper.SetTrackMIDINoteName(destIndex-1, tableNotes[n].pitch_CC, tableNotes[n].channel, tableNotes[n].name)
        end
    end
end

reaper.Undo_OnStateChange("Propagate note names from track " .. tostring(sourceIndex))
