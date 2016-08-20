--[[
ReaScript name:  js_MIDI Inspector.lua
Version: 0.90
Author: juliansader
Link: http://forum.cockos.com/showthread.php?t=176878
Screenshot: http://stash.reaper.fm/v/28295/js_MIDI%20Inspector.jpeg
REAPER version: 5.23
Extensions required: -
About:
  # Description: 
  This script open a GUI that shows important information about the active MIDI take, 
  selected notes, and selected CCs.
  
  The script improves on REAPER's native Properties windows in several ways:
  * The GUI is continuously updated and does not interfere with MIDI editing.  
  * If multiple events are selected, value ranges are shown.
  * Note, CC and take information are all shown simultaneously.
  * Note and CC positions can be displayed in any of REAPER's time formats.
  * The GUI can be docked.
  
  In addition, the script clearly shows the take's default insert channel, and allows 
  the user to change the channel.  This crucial setting is hidden in the default MIDI editor.
  
  # Instructions
  Click on any of the highlighted values to open a Properties window or a dropdown menu 
  in which the values can be changed.
  
  The default colors of the GUI can be customized in the script's USER AREA.
]]
 
--[[
 Changelog:
 * v0.90 (2016-08-18)
    + Initial beta release
]]

-- USER AREA
-- Settings that the user can customize

fontFace = "Ariel"
fontSize = 16
textColor = {1,1,1,0.7}
highlightColor = {1,1,0,1}
backgroundColor = {0.18, 0.18, 0.18, 1}
shadowColor = {0,0,0,1}

-- If the initialization dimensions are not specified, the script
--    will calculate appropriate values based on font size
initWidth = 210
initHeight = 450

-- End of USER AREA

-----------------------------------------------------------------
-----------------------------------------------------------------

--[[tableTimeFormats = {}
tableTimeFormats[-1] = "Project default"
tableTimeFormats[0] = "Time"
tableTimeFormats[1] = "Measrs.beats+time"
tableTimeFormats[2] = "Measures.beats"
tableTimeFormats[3] = "Seconds"
tableTimeFormats[4] = "Samples"
tableTimeFormats[5] = "h:m:s:f"]]

tableTimeFormats = {[-1] = "Project default",
                    [0] = "Time",
                    [1] = "Measrs.beats+time",
                    [2] = "Measures.beats",
                    [3] = "Seconds",
                    [4] = "Samples",
                    [5] = "h:m:s:frames"}
    
tableCCTypes = {[8] = "Note on",
                [9] = "Note off",
                [11] = "CC",
                [12] = "Program select",
                [13] = "Channel pressure",
                [14] = "Pitch wheel"}

tableCCLanes = {[0] = "Bank Select MSB",
                [1] = "Mod Wheel MSB",
                [2] = "Breath MSB",
                [4] = "Foot Pedal MSB",
                [5] = "Portamento MSB",
                [6] = "Data Entry MSB",
                [7] = "Volume MSB",
                [8] = "Balance MSB",
                [10] = "Pan MSB",
                [11] = "Expression MSB",
                [12] = "Control 1 MSB",
                [13] = "Control 2 MSB",
                [32] = "Bank Select LSB",
                [33] = "Mod Wheel LSB",
                [34] = "Breath LSB",
                [36] = "Foot Pedal LSB",
                [37] = "Portamento LSB",
                [38] = "Data Entry LSB",
                [39] = "Volume LSB",
                [40] = "Balance LSB",
                [42] = "Pan LSB",
                [43] = "Expression LSB",
                [64] = "Sustain Pedal (on/off)",
                [65] = "Portamento (on/off)",
                [66] = "Sostenuto (on/off)",
                [67] = "Soft Pedal (on/off)",
                [68] = "Legato Pedal (on/off)",
                [69] = "Hold Pedal 2 (on/off)",
                [70] = "Sound Variation",
                [71] = "Timbre Content",
                [72] = "Release Time",
                [73] = "Attack Time",
                [74] = "Brightness",
                [84] = "Portamento Control",
                [91] = "External FX Depth",
                [92] = "Tremolo Depth",
                [93] = "Chorus Depth",
                [94] = "Detune Depth",
                [95] = "Phaser Depth",
                [96] = "Data Increment",
                [97] = "Data Decrement"}
                
---------------
function exit()
    gfx.quit()
    _, _, sectionID, ownCommandID, _, _, _ = reaper.get_action_context()
    if not (sectionID == nil or ownCommandID == nil or sectionID == -1 or ownCommandID == -1) then
        reaper.SetToggleCommandState(sectionID, ownCommandID, 0)
        reaper.RefreshToolbar2(sectionID, ownCommandID)
    end
end -- function exit

-----------------------------
function setColor(colorTable)
    gfx.r = colorTable[1]
    gfx.g = colorTable[2]
    gfx.b = colorTable[3]
    gfx.a = colorTable[4]
end -- function setColor

-------------------------
function drawWhiteBlock()
    local r = gfx.r; g = gfx.g; b = gfx.b; a = gfx.a
    setColor(blockColor) --{1,1,1,1})
    --gfx.x = gfx.x - 2
    --gfx.y = gfx.y - 2
    gfx.rect(gfx.x-2, gfx.y-2, blockWidth, strHeight+4, true)
    setColor({r,g,b,a})
end -- function drawWhiteBlock

---------------------------
function pitchString(pitch)
    local pitchNames = {"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"}
    return tostring(pitchNames[(pitch%12)+1])..tostring(pitch//12 - 1)
end -- function pitchString

--------------------
function updateGUI()
    
    local tabLong = tabLong
    local tabShort = tabShort
    
    lineHeight = math.max(strHeight, gfx.h / 25)
    setColor(backgroundColor)
    gfx.rect(1, 1, gfx.w-2, gfx.h-2, true)
    gfx.r=gfx.r*2; gfx.g=gfx.g*2; gfx.b=gfx.b*2; gfx.a = 1
    gfx.line(0, 0, gfx.w-1, 0)
    gfx.line(0, 1, 0, gfx.h-1)
    setColor(shadowColor)
    gfx.line(gfx.w-1, gfx.h-1, 0, gfx.h-1)
    gfx.line(gfx.w-1, gfx.h-1, gfx.w-1, 0)
    
    local midX = gfx.w/2
    
    ------------------
    -- Draw take stuff
    setColor(backgroundColor)
    gfx.r=gfx.r*2; gfx.g=gfx.g*2; gfx.b=gfx.b*2; gfx.a = 1
    gfx.rect(6, 1+lineHeight*0.85, gfx.w-11, lineHeight*5, false)
    setColor(shadowColor)
    gfx.rect(5, lineHeight*0.85, gfx.w-11, lineHeight*5, false)
        
    setColor(backgroundColor)
    --gfx.rect(9, lineHeight * 0.5, strWidth["Active take"], strHeight, true)
    gfx.rect(9, lineHeight * 0.5, strWidth["ACTIVE TAKE"], strHeight, true)
    setColor(textColor)
    --gfx.r=gfx.r*1.5; gfx.g=gfx.g*1.5; gfx.b=gfx.b*1.5; gfx.a = gfx.a*1.5
    gfx.x = 13
    gfx.y = lineHeight * 0.5
    --gfx.drawstr("Active take")
    gfx.drawstr("ACTIVE TAKE")
    
    --setColor(textColor)
    gfx.x = tabLong - strWidth["Total notes"]
    gfx.y = lineHeight * 1.5
    gfx.drawstr("Total notes: ")
    gfx.x = tabLong
    gfx.drawstr(numNotes)
    gfx.x = tabLong - strWidth["Total CCs"]
    gfx.y = lineHeight * 2.5
    gfx.drawstr("Total CCs: ")
    gfx.x = tabLong
    gfx.drawstr(numCCs)
    gfx.x = tabLong - strWidth["Default channel"]
    gfx.y = lineHeight * 3.5
    gfx.drawstr("Default channel: ")
    gfx.x = tabLong
    setColor(highlightColor)
    gfx.drawstr(defaultChannel)
    gfx.x = tabLong - strWidth["Default velocity"]
    gfx.y = lineHeight * 4.5
    setColor(textColor)
    gfx.drawstr("Default velocity: ")
    gfx.x = tabLong
    gfx.drawstr(defaultVelocity)
    
    --------------------------------------------------------------
    -- Draw note stuff
    setColor(backgroundColor)
    gfx.r=gfx.r*2; gfx.g=gfx.g*2; gfx.b=gfx.b*2; gfx.a = 1
    gfx.rect(6, 1+lineHeight*6.85, gfx.w-11, lineHeight*7, false)
    setColor(shadowColor)
    gfx.rect(5, lineHeight*6.85, gfx.w-11, lineHeight*7, false)
    
    setColor(backgroundColor)
    --gfx.rect(9, lineHeight * 6.5, strWidth["Selected notes"], strHeight, true)
    gfx.rect(9, lineHeight * 6.5, strWidth["SELECTED NOTES"], strHeight, true)
    setColor(textColor)
    gfx.x = 13
    gfx.y = lineHeight * 6.5
    --gfx.drawstr("Selected notes")
    gfx.drawstr("SELECTED NOTES")
    
    gfx.x = tabShort - strWidth["Count"]
    gfx.y = gfx.y + lineHeight
    setColor(textColor)
    gfx.drawstr("Count: ")
    gfx.x = tabShort
    gfx.drawstr(countSelNotes)        
    
    gfx.x = tabShort - strWidth["Pitch"]
    gfx.y = gfx.y + lineHeight
    setColor(textColor)
    gfx.drawstr("Pitch: ")
    gfx.x = tabShort
    setColor(highlightColor)
    gfx.drawstr(notePitchString)
    
    gfx.x = tabShort - strWidth["Channel"]
    gfx.y = gfx.y + lineHeight
    setColor(textColor)
    gfx.drawstr("Channel: ")
    gfx.x = tabShort
    setColor(highlightColor)
    gfx.drawstr(noteChannelString)
    
    gfx.x = tabShort - strWidth["Velocity"]
    gfx.y = gfx.y + lineHeight
    setColor(textColor)
    gfx.drawstr("Velocity: ")
    gfx.x = tabShort
    setColor(highlightColor)
    gfx.drawstr(noteVelocityString)
    
    gfx.x = tabShort - strWidth["Length"]
    gfx.y = gfx.y + lineHeight
    setColor(textColor)
    gfx.drawstr("Length: ")
    gfx.x = tabShort
    setColor(highlightColor)
    gfx.drawstr(noteLengthString)
    
    gfx.x = tabShort - strWidth["Start pos"]
    gfx.y = gfx.y + lineHeight
    setColor(textColor)
    gfx.drawstr("Start pos: ")
    gfx.x = tabShort
    setColor(highlightColor)
    gfx.drawstr(notePositionString)
    
    ---------------------------------------------------------------
    -- Draw CC stuff
    setColor(backgroundColor)
    gfx.r=gfx.r*2; gfx.g=gfx.g*2; gfx.b=gfx.b*2; gfx.a = 1
    gfx.rect(6, 1+lineHeight*14.85, gfx.w-11, lineHeight*7, false)
    setColor(shadowColor)
    gfx.rect(5, lineHeight*14.85, gfx.w-11, lineHeight*7, false)
    
    setColor(backgroundColor)
    --gfx.rect(9, lineHeight * 13.5, strWidth["Selected CCs"], strHeight, true)
    gfx.rect(9, lineHeight * 14.5, strWidth["SELECTED CCs"], strHeight, true)
    setColor(textColor)
    gfx.x = 13
    gfx.y = lineHeight * 14.5
    --gfx.drawstr("Selected CCs")
    gfx.drawstr("SELECTED CCs")
    
    gfx.x = tabShort - strWidth["Count"]
    gfx.y = gfx.y + lineHeight
    gfx.drawstr("Count: ")
    gfx.x = tabShort
    gfx.drawstr(countSelCCs)
    
    gfx.x = tabShort - strWidth["Type"]
    gfx.y = gfx.y + lineHeight
    setColor(textColor)
    gfx.drawstr("Type: ")
    gfx.x = tabShort
    setColor(highlightColor)
    gfx.drawstr(ccTypeString)    
    
    gfx.x = tabShort - strWidth["CC lane"]
    gfx.y = gfx.y + lineHeight
    setColor(textColor)
    gfx.drawstr("CC lane: ")
    gfx.x = tabShort
    setColor(highlightColor)
    gfx.drawstr(ccLaneString) 
    
    gfx.x = tabShort - strWidth["Channel"]
    gfx.y = gfx.y + lineHeight
    setColor(textColor)
    gfx.drawstr("Channel: ")
    gfx.x = tabShort
    setColor(highlightColor)
    gfx.drawstr(ccChannelString) 
    
    gfx.x = tabShort - strWidth["Value"]
    gfx.y = gfx.y + lineHeight
    setColor(textColor)
    gfx.drawstr("Value: ")
    gfx.x = tabShort
    setColor(highlightColor)
    gfx.drawstr(ccValueString)   
    
    gfx.x = tabShort - strWidth["Position"]
    gfx.y = gfx.y + lineHeight
    setColor(textColor)
    gfx.drawstr("Position: ")
    gfx.x = tabShort
    setColor(highlightColor)
    gfx.drawstr(ccPositionString)
    
    -- Draw position/time format
    gfx.x = 11 --tabShort - strWidth["Format"]
    gfx.y = lineHeight*22.3
    setColor(textColor)
    gfx.drawstr("Time format: ")
    --gfx.x = tabShort
    setColor(highlightColor)
    gfx.drawstr(tableTimeFormats[timeFormat])
    
    
    -- Draw Pause radio button
    setColor(backgroundColor)
    gfx.r=gfx.r*2; gfx.g=gfx.g*2; gfx.b=gfx.b*2; gfx.a = 1
    gfx.rect(11, 2+lineHeight*23.5, strHeight-2, strHeight-2, false)
    setColor(shadowColor)
    gfx.rect(10, 1+lineHeight*23.5, strHeight-2, strHeight-2, false)
    setColor(textColor) --{0.7,0.7,0.7,1})
    gfx.a = gfx.a*0.5
    gfx.rect(12, 3+lineHeight*23.5, strHeight-5, strHeight-5, true)
    setColor(textColor)
    gfx.x = 15 + strHeight
    gfx.y = lineHeight * 23.5
    gfx.drawstr("Pause")
    
    if paused == true then
        setColor(shadowColor)
        gfx.x = 13
        --gfx.y = lineHeight * 19.5
        gfx.drawstr("X")
        gfx.x = 13
        gfx.y = gfx.y + 1
        gfx.drawstr("X")
    end
    
    -- Draw Dock radio button
    setColor(backgroundColor)
    gfx.r=gfx.r*2; gfx.g=gfx.g*2; gfx.b=gfx.b*2; gfx.a = 1
    gfx.rect(midX+1, 2+lineHeight*23.5, strHeight-2, strHeight-2, false)
    setColor(shadowColor)
    gfx.rect(midX, 1+lineHeight*23.5, strHeight-2, strHeight-2, false)
    setColor(textColor) --{0.7,0.7,0.7,1})
    gfx.a = gfx.a*0.5
    gfx.rect(midX+2, 3+lineHeight*23.5, strHeight-5, strHeight-5, true)
    setColor(textColor)
    gfx.x = midX + 5 + strHeight
    gfx.y = lineHeight * 23.5
    gfx.drawstr("Dock")
    
    if gfx.dock(-1) ~= 0 then
        setColor(shadowColor)
        gfx.x = midX + 3
        --gfx.y = lineHeight * 19.5
        gfx.drawstr("X")
        gfx.x = midX + 3
        gfx.y = gfx.y + 1
        gfx.drawstr("X")
    end
        
    --[[setColor(backgroundColor)
    gfx.r=gfx.r*2; gfx.g=gfx.g*2; gfx.b=gfx.b*2; gfx.a = 1
    gfx.rect(gfx.w-8-strHeight, 2+lineHeight*19.5, strHeight-2, strHeight-2, false)
    setColor(shadowColor)
    gfx.rect(gfx.w-9-strHeight, 1+lineHeight*19.5, strHeight-2, strHeight-2, false)
    setColor(textColor) --{0.7,0.7,0.7,1})
    gfx.a = gfx.a*0.5
    gfx.rect(gfx.w-7-strHeight, 3+lineHeight*19.5, strHeight-5, strHeight-5, true)
    setColor(textColor)
    gfx.x = gfx.w-13-strHeight-strWidthDock
    gfx.y = lineHeight * 19.5
    gfx.drawstr("Dock")
    ]]
    gfx.update()
end -- function updateGUI

----------------------------
function loopMIDIInspector()

    gfx.update()
    
    -- Quit script if GUI has been closed
    local char = gfx.getchar()
    if char<0 then return(0) end         
    
    -- Or if there is no active MIDI editor
    editor = reaper.MIDIEditor_GetActive()
    if editor == nil then return(0) end
    
    -- If paused, GUI updates and mouseclicks will be done, but no MIDI updates
    if paused == false then    
           
        local take = reaper.MIDIEditor_GetTake(editor)
        -- The GetTake function is buggy and sometimes returns an invalid, deleted take, so must validate
        if reaper.ValidatePtr(take, "MediaItem_Take*") then
        
            -- Only do all the time-consuming stuff if there were in fact changes in MIDI (or if active take switched)
            hashOK, takeHash = reaper.MIDI_GetHash(take, false, "")
            if take ~= prevTake or (hashOK and takeHash ~= prevHash) then
                prevTake = take
                prevHash = takeHash
                --[[
                countSelNotes = ""
                noteChannelString = ""
                notePitchString = "sdf"
                notePositionString = ""
                noteVelocityString = ""
                
                countSelCCs = ""
                ccChannelString = ""
                ccPositionString = ""
                ccValueString = ""
                ]]
                countOK, numNotes, numCCs, numSysex = reaper.MIDI_CountEvts(take)
                --[[if countOK ~= true then
                    numNotes = "?"
                    numCCs = "?"
                    numSysex = "?"
                end]]
                defaultVelocity = reaper.MIDIEditor_GetSetting_int(editor, "default_note_vel")
                -- Some of REAPER's MIDI function work with channel range 0-15, others with 1-16
                defaultChannel  = 1 + reaper.MIDIEditor_GetSetting_int(editor, "default_note_chan")  
                
                ------------------------------------------------------------
                -- Now get all the info of the selected NOTES in active take
                local noteLowPPQ = math.huge
                local noteHighPPQ = -1
                local noteLowChannel = 17
                local noteHighChannel = -1
                local noteLowPitch = 200
                local noteHighPitch = -1
                local noteLowVelocity = 200
                local noteHighVelocity = -1
                local noteHighLength = -1
                local noteLowLength = math.huge
                --[[
                noteLowPPQ = math.huge
                noteHighPPQ = -1
                noteLowChannel = 17
                noteHighChannel = -1
                noteLowPitch = 200
                noteHighPitch = -1
                noteLowVelocity = 200
                noteHighVelocity = -1
                noteHighLength = -1
                noteLowLength = math.huge
                ]]
                local noteIndex = reaper.MIDI_EnumSelNotes(take, -1)
                countSelNotes = 0
                while noteIndex > -1 do
                    local noteOK, _, _, startPPQ, endPPQ, channel, pitch, velocity = reaper.MIDI_GetNote(take, noteIndex)
                    if noteOK == true then
                        countSelNotes = countSelNotes + 1
                        local length = endPPQ - startPPQ
                        if length < noteLowLength then noteLowLength = length end
                        if length > noteHighLength then noteHighLength = length end
                        if startPPQ < noteLowPPQ then noteLowPPQ = startPPQ end
                        if startPPQ > noteHighPPQ then noteHighPPQ = startPPQ end
                        if channel < noteLowChannel then noteLowChannel = channel end
                        if channel > noteHighChannel then noteHighChannel = channel end
                        if pitch < noteLowPitch then noteLowPitch = pitch end
                        if pitch > noteHighPitch then noteHighPitch = pitch end
                        if velocity < noteLowVelocity then noteLowVelocity = velocity end
                        if velocity > noteHighVelocity then noteHighVelocity = velocity end
                    end
                    noteIndex = reaper.MIDI_EnumSelNotes(take, noteIndex)
                end -- while noteIndex > -1
                
                if noteLowPPQ > noteHighPPQ then notePositionString = ""
                else
                    -- The GetProjTime returns a string that is not in the same format as 
                    --    how the Properties window displays position.
                    -- The 3rd number is returned as 1/100th of a beat, instead of ticks
                    --[[
                    -- This code does not work yet
                    noteLowTime = reaper.format_timestr_pos(reaper.MIDI_GetProjTimeFromPPQPos(take, noteLowPPQ), "", 2)
                    noteLowBeats, noteLowTicks = noteLowTime:match("([%d]+.[%d]+).([%d]+)")
                    noteLowTicks = 9.6 * tonumber(noteLowTicks)
                    
                    noteHighTime = reaper.format_timestr_pos(reaper.MIDI_GetProjTimeFromPPQPos(take, noteHighPPQ), "", 2)
                    noteHighBeats, noteHighTicks = noteHighTime:match("([%d]+.[%d]+).([%d]+)")
                    noteHighTicks = 9.6 * tonumber(noteHighTicks)
                    ]]
                    if noteLowPPQ == noteHighPPQ then 
                        notePositionString = reaper.format_timestr_pos(reaper.MIDI_GetProjTimeFromPPQPos(take, noteLowPPQ), "", timeFormat)
                    else 
                        notePositionString =  reaper.format_timestr_pos(reaper.MIDI_GetProjTimeFromPPQPos(take, noteLowPPQ), "", timeFormat) 
                                         .. " - " 
                                         .. reaper.format_timestr_pos(reaper.MIDI_GetProjTimeFromPPQPos(take, noteHighPPQ), "", timeFormat)
                    end
                end
                
                if noteLowChannel > noteHighChannel then noteChannelString = ""
                elseif noteLowChannel == noteHighChannel then 
                    noteChannelString = tostring(noteLowChannel+1)
                else 
                    noteChannelString = tostring(noteLowChannel+1) 
                                     .. " - " 
                                     .. tostring(noteHighChannel+1)
                end
                
                if noteLowPitch > noteHighPitch then notePitchString = ""
                elseif noteLowPitch == noteHighPitch then 
                    notePitchString = pitchString(noteLowPitch)
                else 
                    notePitchString = pitchString(noteLowPitch) 
                                     .. " - " 
                                     .. pitchString(noteHighPitch)
                end
                            
                if noteLowVelocity > noteHighVelocity then noteVelocityString = ""
                elseif noteLowVelocity == noteHighVelocity then 
                    noteVelocityString = tostring(noteLowVelocity)
                else 
                    noteVelocityString = tostring(noteLowVelocity) 
                                     .. " - " 
                                     .. tostring(noteHighVelocity)
                end
                
                if noteLowLength > noteHighLength then noteLengthString = ""
                elseif noteLowLength == noteHighLength then 
                    noteLengthString = tostring(noteLowLength):match("[%d]+") .. " ticks"
                else 
                    noteLengthString = tostring(noteLowLength):match("[%d]+")
                                     .. " - " 
                                     .. tostring(noteHighLength):match("[%d]+")
                                     .. " ticks"
                end
                            
                --if type(ccPositionString) == "string" then updateGUI() end
                
                ----------------------------------------------------------
                -- Now get all the info of the selected CCs in active take
                local ccLowPPQ = math.huge
                local ccHighPPQ = -1
                local ccLowChannel = 17
                local ccHighChannel = -1
                local ccLowValue = math.huge
                local ccHighValue = -1
                local ccHighLane = -1
                local ccLowLane = math.huge
                local ccHighType = -1 -- Actually, other 'types' are not CCs at all
                local ccLowType = math.huge
                --local value, ccType
                
                local ccIndex = reaper.MIDI_EnumSelCC(take, -1)
                countSelCCs = 0
                while ccIndex > -1 do
                    ccOK, _, _, PPQpos, chanmsg, channel, msg2, msg3 = reaper.MIDI_GetCC(take, ccIndex)
                    --[[            
                    if (0 <= mouseLane and mouseLane <= 127 -- CC, 7 bit (single lane)
                        and msg2 == mouseLane and eventType == 11)
                    or (256 <= mouseLane and mouseLane <= 287 -- CC, 14 bit (double lane)
                        and (msg2 == mouseLane-256 or msg2 == mouseLane-224) and eventType ==11) -- event can be from either MSB or LSB lane
                    or ((mouseLane == 0x200 or mouseLane == 0x207) -- Velocity or off-velocity
                        and (eventType == 9 or eventType == 8)) -- note on or note off
                    or (mouseLane == 0x201 and eventType == 14) -- pitch
                    or (mouseLane == 0x202 and eventType == 12) -- program select
                    or (mouseLane == 0x203 and eventType == 13) -- channel pressure (after-touch)
                    or (mouseLane == 0x204 and eventType == 12) -- Bank/Program select - Program select
                    or (mouseLane == 0x204 and eventType == 11 and msg2 == 0) -- Bank/Program select - Bank select MSB
                    or (mouseLane == 0x204 and eventType == 11 and msg2 == 32) -- Bank/Program select - Bank select LSB
                    ]]
                    
                    if ccOK == true then 
                        countSelCCs = countSelCCs + 1
                        
                        ccType = chanmsg>>4
                        if ccType < ccLowType then ccLowType = ccType end
                        if ccType > ccHighType then ccHighType = ccType end
                                                    
                        if ccType == 14 then value = (msg3<<7) + msg2 -- pitch
                        elseif ccType == 13 then value = msg2 -- channel pressure
                        else value = msg3
                        end
                        if value < ccLowValue then ccLowValue = value end
                        if value > ccHighValue then ccHighValue = value end

                        if ccType == 11 then -- CC
                            if msg2 < ccLowLane then ccLowLane = msg2 end
                            if msg2 > ccHighLane then ccHighLane = msg2 end
                        end
                                            
                        if PPQpos < ccLowPPQ then ccLowPPQ = PPQpos end
                        if PPQpos > ccHighPPQ then ccHighPPQ = PPQpos end
                        if channel < ccLowChannel then ccLowChannel = channel end
                        if channel > ccHighChannel then ccHighChannel = channel end
                    end
                    ccIndex = reaper.MIDI_EnumSelCC(take, ccIndex)
                end -- while ccIndex > -1
                
                if ccHighType == -1 then ccTypeString = "" -- no CCs selected
                elseif ccLowType ~= ccHighType then ccTypeString = "Multiple"
                else ccTypeString = tableCCTypes[ccLowType]
                end
                     
                -- CC lane will be calculated in ccType == 11, actual CC
                if ccLowType == ccHighType and ccLowType == 11 then
                    if ccLowLane > ccHighLane then ccLaneString = ""    
                    elseif ccLowLane == ccHighLane then 
                        ccLaneString = tostring(ccLowLane)
                        if tableCCLanes[ccLowLane] ~= nil then
                            ccLaneString = ccLaneString .. " (" .. tableCCLanes[ccLowLane] .. ")"
                        end
                    else 
                       ccLaneString = tostring(ccLowLane) 
                                              .. " - " 
                                              .. tostring(ccHighLane)
                    end
                else
                    ccLaneString = ""
                end
                            
                if ccLowValue > ccHighValue then ccValueString = ""
                elseif ccLowValue == ccHighValue then 
                    ccValueString = tostring(ccLowValue)
                else 
                    ccValueString = tostring(ccLowValue) 
                                     .. " - " 
                                     .. tostring(ccHighValue)
                end
                
                if ccLowPPQ > ccHighPPQ then ccPositionString = ""
                elseif ccLowPPQ == ccHighPPQ then 
                    ccPositionString = reaper.format_timestr_pos(reaper.MIDI_GetProjTimeFromPPQPos(take, ccLowPPQ), "", timeFormat)
                else 
                    ccPositionString =  reaper.format_timestr_pos(reaper.MIDI_GetProjTimeFromPPQPos(take, ccLowPPQ), "", timeFormat) 
                                     .. " - " 
                                     .. reaper.format_timestr_pos(reaper.MIDI_GetProjTimeFromPPQPos(take, ccHighPPQ), "", timeFormat)
                end
                
                if ccLowChannel > ccHighChannel then ccChannelString = ""
                elseif ccLowChannel == ccHighChannel then 
                    ccChannelString = tostring(ccLowChannel+1)
                else 
                    ccChannelString = tostring(ccLowChannel+1) 
                                     .. " - " 
                                     .. tostring(ccHighChannel+1)
                end
                                        
                if ccLowValue > ccHighValue then ccValueString = ""
                elseif ccLowValue == ccHighValue then 
                    ccValueString = tostring(ccLowValue)
                else 
                    ccValueString = tostring(ccLowValue) 
                                     .. " - " 
                                     .. tostring(ccHighValue)
                end
            end -- if takeHash ~= prevHash
        end -- if take ~= nil
    end -- if paused == false
    
    -------------------------------------
    -- Now check if any mouse interaction
    gfx.update()
                
    if gfx.mouse_cap == 0 then mouseAlreadyClicked = false end
    
    -- Select new default channel for new events
    if gfx.mouse_cap == 1 and mouseAlreadyClicked == false 
    and gfx.mouse_y > lineHeight*3.5 and gfx.mouse_y < lineHeight*4.5 
    then
        mouseAlreadyClicked = true
        
        if type(defaultChannel) == "number" 
        and defaultChannel%1 == 0 
        and defaultChannel <= 16
        and defaultChannel >= 1
        then
            gfx.x = tabLong
            gfx.y = lineHeight * 4.5
            local channelString = "#Channel|1|2|3|4|5|6|7|8|9|10|11|12|13|14|15|16"
            local checkPos = channelString:find(tostring(defaultChannel))
            channelString = channelString:sub(1,checkPos-1) .. "!" .. channelString:sub(checkPos, nil)
            local menuChoice = gfx.showmenu(channelString)
            if menuChoice > 0 then
                reaper.MIDIEditor_OnCommand(editor, 40482+menuChoice-2) -- Set channel for new events to 0+channel
            end
        end -- type(defaultChannel) == "number" 
    end -- if gfx.mouse_cap == 1
    
    
    -- Pause / Unpause
    if gfx.mouse_cap == 1 and mouseAlreadyClicked == false 
    and gfx.mouse_y > lineHeight*23.5 and gfx.mouse_y < lineHeight*24.5 
    and gfx.mouse_x > 0 and gfx.mouse_x < gfx.w/2
    then
        mouseAlreadyClicked = true
        paused = not paused
    end
    
    -- Dock / Undock
    if gfx.mouse_cap == 1 and mouseAlreadyClicked == false 
    and gfx.mouse_y > lineHeight*23.5 and gfx.mouse_y < lineHeight*24.5 
    and gfx.mouse_x > gfx.w/2 and gfx.mouse_x < gfx.w
    then
        mouseAlreadyClicked = true
        if gfx.dock(-1) ~= 0 then
            gfx.dock(0)
        else
            gfx.dock(1)
        end
    end
    
    -- Select time format
    if (gfx.mouse_cap == 2 or gfx.mouse_cap == 1)
    and mouseAlreadyClicked == false 
    and gfx.mouse_y > lineHeight*22.3 and gfx.mouse_y < lineHeight*23.3 
    --and gfx.mouse_x > gfx.w/2 and gfx.mouse_x < gfx.w
    then
        mouseAlreadyClicked = true
        gfx.x = 11+strWidth["Time format"] --tabShort
        gfx.y = lineHeight*23.3 
        local menuString = "#Display position as|"
        -- Time format ranges from -1 (default) to 5
        for i = -1, #tableTimeFormats do
            menuString = menuString .. "|"
            if i == timeFormat then menuString = menuString .. "!" end
            menuString = menuString .. tableTimeFormats[i]
        end
        local menuChoice = gfx.showmenu(menuString)
        if menuChoice > 1 then 
            timeFormat = menuChoice-3 
            prevHash = nil -- This just to force everything to update    
        end
    end
    
    -- Click anywhere else where there are highlighted values, open REAPER's Properties window
    if gfx.mouse_cap == 1 and mouseAlreadyClicked == false 
    and (  (gfx.mouse_y > lineHeight*8.5 and gfx.mouse_y < lineHeight*13.5)
        or (gfx.mouse_y > lineHeight*16.5 and gfx.mouse_y < lineHeight*21.5)
        )
    then
        mouseAlreadyClicked = true
        reaper.MIDIEditor_OnCommand(editor, 40004)
    end
    
    updateGUI()
    
    reaper.runloop(loopMIDIInspector)
end -- function loop GetSetChannel

--------------------------------------------------------------------
-- Here the code execution starts
--------------------------------------------------------------------
-- function main()

reaper.atexit(exit)

_, _, sectionID, ownCommandID, _, _, _ = reaper.get_action_context()
if not (sectionID == nil or ownCommandID == nil or sectionID == -1 or ownCommandID == -1) then
    reaper.SetToggleCommandState(sectionID, ownCommandID, 1)
    reaper.RefreshToolbar2(sectionID, ownCommandID)
end

gfx.init("MIDI Inspector", 200, 400)
gfx.setfont(1, fontFace, fontSize, 'b')
strWidth = {}
strWidth["ACTIVE TAKE"] = gfx.measurestr(" ACTIVE TAKE ")
strWidth["Active take"] = gfx.measurestr(" Active take ")
strWidth["Total notes"] = gfx.measurestr("Total notes:  ")
strWidth["Total CCs"] = gfx.measurestr("Total CCs:  ")
strWidth["Default channel"] = gfx.measurestr("Default channel:  ")
strWidth["Default velocity"] = gfx.measurestr("Default velocity:  ")

strWidth["SELECTED NOTES"] = gfx.measurestr(" SELECTED NOTES ")
strWidth["Selected notes"] = gfx.measurestr(" Selected notes ")
strWidth["Count"] = gfx.measurestr("Count:  ")
strWidth["Start pos"] = gfx.measurestr("Start pos:  ")
strWidth["Position"] = gfx.measurestr("Position:  ")
strWidth["Channel"] = gfx.measurestr("Channel:  ")
strWidth["Pitch"] = gfx.measurestr("Pitch:  ")
strWidth["Velocity"] = gfx.measurestr("Velocity:  ")

strWidth["SELECTED CCs"] = gfx.measurestr(" SELECTED CCs ")
strWidth["Selected CCs"] = gfx.measurestr(" Selected CCs ")
strWidth["CC type"] = gfx.measurestr("CC type:  ")
strWidth["Type"] = gfx.measurestr("Type:  ")
strWidth["Value"] = gfx.measurestr("Value:  ")
strWidth["CC lane"] = gfx.measurestr("CC lane:  ")

strWidth["Time format"] = gfx.measurestr("Time format:  ")
strWidth["Length"] = gfx.measurestr("Length:  ")
strWidth["Long time format"], strHeight = gfx.measurestr("0:00:00:00 - 0:00:00:00")
strWidthDock = gfx.measurestr("Dock")
--[[
strWidthCutoff = 2 * math.max(gfx.measurestr("Channel:  15-16 "), 
                          gfx.measurestr("Pitch:  G#8 - G#8 "),
                          gfx.measurestr("Count:  0000000 "),
                          gfx.measurestr("velocity:  127 - 128 "))
                          ]]

--blockWidth, _ = gfx.measurestr("00000 - 00000") + 4
tabLong  = 20 + math.max(strWidth["Default channel"], 
                         gfx.measurestr("Default velocity:  "))
tabShort = 20 + math.max(gfx.measurestr("Position:  "), 
                         gfx.measurestr("Channel:  "), 
                         gfx.measurestr("Velocity:  "), 
                         gfx.measurestr("Start pos:  "))
lineHeight = math.max(strHeight, gfx.h / 21)
gfx.quit()

paused = false
timeFormat = -1

if type(initWidth) ~= "number" then initWidth = strWidth["Long time format"]+tabShort+15 end
if type(initHeight) ~= "number" then initHeight = (strHeight+3)*20 end
gfx.init("MIDI Inspector", initWidth, initHeight)
gfx.setfont(1, fontFace, fontSize, 'b')
gfx.update()

reaper.runloop(loopMIDIInspector)
