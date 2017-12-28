--[[
ReaScript name: js_MIDI Inspector.lua
Version: 1.21
Author: juliansader
Screenshot: http://stash.reaper.fm/28295/js_MIDI%20Inspector.jpeg
Website: http://forum.cockos.com/showthread.php?t=176878
Donation: https://www.paypal.me/juliansader
REAPER version: 5.32
About:
  # Description
  This script opens a GUI that shows important information about the active MIDI take, 
  selected notes, and selected CCs.
  
  The script improves on REAPER's native Properties windows in several ways:
  
  * The GUI is continuously updated and does not interfere with MIDI editing.  
  
  * If multiple events are selected, value ranges are shown.
  
  * Note, CC and take information are all shown simultaneously.
  
  * Note and CC positions can be displayed in any of REAPER's time formats.  
  
  * In Measure:Beat:Ticks format, script can display fractional tick values.
  
  * The GUI can be docked.
  
  In addition, the script clearly shows the take's default insert channel, and allows 
  the user to change the channel.  (From REAPER v2.54 onward, this crucial setting will
  also be available by default in the MIDI editor itself.)
  
  # Instructions
  Click on any of the highlighted values to open a Properties window or a dropdown menu 
  in which the values can be changed.
  
  The default colors of the GUI, as well as the font size, can be customized in the script's USER AREA.  
  
  When opening, the script will recall its last-used position and size.
  
  If the script GUI is docked, REAPER's own pin-on-top button can be used to keep the docker on top and the script visible at all times.
  If the script GUI is not docked, 3rd party apps that pin windows on top, such as "FileBox eXtender" (on Windows), can be used. 
  
  Updating MIDI information in realtime can take a toll on the responsiveness of the MIDI editor, 
      particularly if the take contains many thousands of MIDI events.  The GUI therefore provides a
      "Pause" checkbox, which will pause the realtime updating.  
]]
 
--[[
  Changelog:
  * v0.90 (2016-08-20)
    + Initial beta release
  * v0.91 (2016-08-20)
    + Improved header info
  * v0.92 (2016-08-20)
    + When default channel is changed, GUI will immediately update
    + WARNING: In REAPER v5.2x, the actions for changing the default channel for new events 
      ("Set channel for new events to 1 [...16]") are buggy and may inappropriately activate 
      the MIDI editor's event filter (as set in the Filter window).  Changing the default 
      channel via this script (or by running the actions directly) may therefore make 
      some notes of CCs invisible.
  * v0.93 (2016-08-25)
    + In REAPER itself, the aforementioned bug (setting channel for new events activates 
      event filter) has been fixed in v2.54.
    + In the MIDI Inspector, the GUI will immediately update if the channel for new events
      is changed via the action list or via the MIDI editor's own new channel features.  
  * v0.94 (2016-09-10)
    + If user clicks in CC area, the script will ask whether all notes, text and sysex events 
      should deselected before opening REAPER's Event Properties, to avoid opening the
      Note Properties or Text/Sysex windows instead.
    + New position formats: Ticks, and Measure:Beat:Ticks 
      (the latter is similar to how the MIDI editor's Event Properties displays position).
  * v0.95 (2016-09-13)
    + In Measure:Beat:Ticks format, script will display fractional tick values if the MIDI item's
      ticks are not precisely aligned with the project beats.  (As discussed in t=181211.)
  * v1.00 (2016-12-15)
    + Improved speed, using new API functions of REAPER v5.30.
    + The script requires REAPER v5.30.
  * v1.01 (2017-02-14)
    + Interpret note-ons with velocity=0 as note-offs.
  * v1.10 (2017-06-19)
    + GUI window will open at last-used screen coordinates.
  * v1.20 (2017-12-28)
    + Use negative time or ticks in M:B:ticks or M:B:time formats, if very slightly before beat.
    + New position display format: ticks. 
    + Display seconds in higher precision.
    + Position display follows Project start time and Project start measure.
    + Display note numbers as well as letters.
    + Note names follow "MIDI octave name display offset" in Preferences/
    + GUI window will recall last-used size.
  * v1.21 (2017-12-28)
    + Display Time (min;sec) format in high precision.
]]

-- USER AREA
-- Settings that the user can customize

defaultTimeFormat = 0 -- Refer to tableTimeFormats below for description of the formats

fontFace = "Ariel"
fontSize = 14
textColor = {1,1,1,0.7}
highlightColor = {1,1,0,1}
backgroundColor = {0.18, 0.18, 0.18, 1}
shadowColor = {0,0,0,1}

-- End of USER AREA

-----------------------------------------------------------------
-----------------------------------------------------------------

local tableTimeFormats = {[-1] = "Project default",
                          [0] = "Measures.Beats.Ticks", -- This is how the MIDI editor's Properties window displays position (except with . instead of :)
                          [1] = "Measures.Beats.Secs",
                          [2] = "Measures.Beats.Cents",
                          [3] = "Time (seconds)",
                          [4] = "Time (min.sec)",
                          [5] = "Samples",
                          [6] = "h ; m ; s ; frames",
                          [7] = "Ticks (from take start)"}
    
local tableCCTypes = {[8] = "Note on",
                      [9] = "Note off",
                      [11] = "CC",
                      [12] = "Program select",
                      [13] = "Channel pressure",
                      [14] = "Pitch wheel"}

local tableCCLanes = {[0] = "Bank Select MSB",
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
                
local notePositionString = ""
local noteChannelString = ""
local notePitchString = ""
local noteVelocityString = ""
local noteLengthString = ""
local ccTypeString = ""
local ccLaneString = ""
local ccPositionString = ""
local ccChannelString = ""
local ccValueString = ""
local countSelCCs = 0
local countSelNotes = 0

local projStartMeasure = 0 --tonumber(reaper.format_timestr_pos(0, "", 2):match("([%d%-]+)"))
local projStartTime    = 0 --reaper.GetProjectTimeOffset(0, false)

-- Preferences -> MIDI settings -> MIDI octave name display offset
local octaveOffset = 0

---------------
function exit()
    -- Find and store the last-used coordinates of the GUI window, so that it can be re-opened at the same position
    local docked, xPos, yPos, xWidth, yHeight = gfx.dock(-1, 0, 0, 0, 0)
    if docked == 0 and type(xPos) == "number" and type(yPos) == "number" then
        -- xPos and yPos should already be integers, but use math.floor just to make absolutely sure
        reaper.SetExtState("MIDI Inspector", "Last coordinates", string.format("%i", math.floor(xPos+0.5)) .. "," 
                                                              .. string.format("%i", math.floor(yPos+0.5)) .. ",", true)
        reaper.SetExtState("MIDI Inspector", "Last dimensions", string.format("%i", math.floor(xWidth+0.5)) .. "," 
                                                              .. string.format("%i", math.floor(yHeight+0.5)) .. ",", true)                                                      
    end    
    gfx.quit()
    
    -- Deactivate toolbar button
    _, _, sectionID, ownCommandID, _, _, _ = reaper.get_action_context()
    if not (sectionID == nil or ownCommandID == nil or sectionID == -1 or ownCommandID == -1) then
        reaper.SetToggleCommandState(sectionID, ownCommandID, 0)
        reaper.RefreshToolbar2(sectionID, ownCommandID)
    end
    
    -- Make sure MIDI editor is focused
    if reaper.APIExists("SN_FocusMIDIEditor") then
        reaper.SN_FocusMIDIEditor()
    end
    
end -- function exit

-----------------------------
local function setColor(colorTable)
    gfx.r = colorTable[1]
    gfx.g = colorTable[2]
    gfx.b = colorTable[3]
    gfx.a = colorTable[4]
end -- function setColor

-------------------------------
local function drawWhiteBlock()
    local r = gfx.r; g = gfx.g; b = gfx.b; a = gfx.a
    setColor(blockColor) --{1,1,1,1})
    --gfx.x = gfx.x - 2
    --gfx.y = gfx.y - 2
    gfx.rect(gfx.x-2, gfx.y-2, blockWidth, strHeight+4, true)
    setColor({r,g,b,a})
end -- function drawWhiteBlock

---------------------------------
local function pitchString(pitch)
    local pitchNames = {"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"}
    return tostring(pitchNames[(pitch%12)+1])..tostring((pitch+(octaveOffset*12))//12 - 1) --.. " (" .. string.format("%i", pitch) .. ")"
end -- function pitchString

-------------------
local function timeStr(take, ppq, format)
    --[[
    These are REAPER's own numbers for format_timestr_pos:
        -1=proj default.
        0=time (min.sec)
        1=measures.beats.time
        2=measures.beats.cents
        3=seconds
        4=samples
        5=h:m:s:f
    ]]
    --[[
    My numbers are:
        [-1] = "Project default",
        [0] = "Measures.Beats.Ticks", -- This is how the MIDI editor's Properties window displays position (except with . instead of :)
        [1] = "Measures.Beats.Secs",
        [2] = "Measures.Beats.Cents",
        [3] = "Time (seconds)",
        [4] = "Time (min.sec)",
        [5] = "Samples",
        [6] = "h ; m ; s ; frames",
        [7] = "Ticks"}
        ]]
    -- Own addition: 6=Ticks
    
    -- format_timestr_pos returns strings that are not in the same format as 
    --    how the MIDI editor's Properties window displays position.
    -- Therefore extra format options were added: 
    -- Also, "M:B:time" format is imprecise since it rounds the time, this will also be changed. 
    
    -- BTW, all this string formatting stuff takes a mere few microseconds, so doesn't affect responsiveness at all.
    if format == -1 then
        return reaper.format_timestr_pos(reaper.MIDI_GetProjTimeFromPPQPos(take, ppq), "", -1):gsub(":", " ; ")
    elseif format == 0 then -- Custom format measure:beat:ticks
        local measureStr, beatStr = reaper.format_timestr_pos(reaper.MIDI_GetProjTimeFromPPQPos(take, ppq), "", 2):match("([%d%-]+)[%.%:](%d+)")
        local measures, beats = tonumber(measureStr)-projStartMeasure, tonumber(beatStr)-1
        local beatTime = reaper.TimeMap2_beatsToTime(0, beats, measures)
        local beatPPQ  = reaper.MIDI_GetPPQPosFromProjTime(take, beatTime)
        local ticks = ppq-beatPPQ
        local ticksStr = string.format("%.8f", ticks):gsub("%.?0+$", "")
        --[[
        if ticks%1 == 0 then -- integer, so can format nicely without decimal point
            ticksStr = string.format("%03d", ticks)
        else -- Not integer, so display exact displacement
            ticksStr = string.format("%03.4f", ticks)
        end]]
        return (measureStr .. " ; " .. beatStr .. " ; " .. ticksStr)
    elseif format == 1 then -- measure:beat:seconds
        local t1 = reaper.time_precise()
        local eventTime = reaper.MIDI_GetProjTimeFromPPQPos(take, ppq)
        -- Why use format_timestr_pos instead of TimeMap2_timeToBeats?  
        --    Because format_timestr_pos returns negative time when event is slightly ahead of beats. This is useful to see how far ahead event is.
        local measureStr, beatStr = reaper.format_timestr_pos(eventTime, "", 2):match("([%d%-]+)[%.%:](%d+)")
        local measures, beats = tonumber(measureStr)-projStartMeasure, tonumber(beatStr)-1
        local beatTime  = reaper.TimeMap2_beatsToTime(0, beats, measures)
        local timeStr = string.format("%.11f", eventTime-beatTime):gsub("%.?0+$", "") -- gsub removes trailing zeroes and decimal point
        if timeStr == "-0" then timeStr = "0" end
        --if (timeStr == "-0.000000000" or timeStr == "0.000000000") then timeStr = "0" end
        timeTaken = reaper.time_precise() - t1
        return (measureStr .. " ; " .. beatStr .. " ; " .. timeStr)
    elseif format == 2 then -- Measures.Beats.Cents
        return reaper.format_timestr_pos(reaper.MIDI_GetProjTimeFromPPQPos(take, ppq), "", 2):gsub("%.", " ; ")
    elseif format == 3 then -- seconds
        --return tostring(reaper.MIDI_GetProjTimeFromPPQPos(take, ppq) + projStartTime)
        return string.format("%.11f", reaper.MIDI_GetProjTimeFromPPQPos(take, ppq) + projStartTime):gsub("%.?0+$", "") -- gsub removes trailing zeroes and decimal point
    elseif format == 4 then -- Time (min ; seconds)
        local timePos = reaper.MIDI_GetProjTimeFromPPQPos(take, ppq) + projStartTime
        if timePos >= 0 then
            local minutes = timePos // 60
            local seconds = timePos - (minutes*60)
            return string.format("%im %.11f", minutes, seconds):gsub("%.?0+$", "") .. "s" -- gsub removes trailing zeroes and decimal point
        else
            local minutes = (-timePos // 60)
            local seconds = (-minutes*60) - timePos
            return string.format("-%im %.11f", minutes, seconds):gsub("%.?0+$", "") .. "s"-- gsub removes trailing zeroes and decimal point
        end
    elseif format == 5 then
        return reaper.format_timestr_pos(reaper.MIDI_GetProjTimeFromPPQPos(take, ppq), "", 4)
    elseif format == 6 then
        return reaper.format_timestr_pos(reaper.MIDI_GetProjTimeFromPPQPos(take, ppq), "", 5):gsub(":", " ; ")
    elseif format == 7 then -- ticks
        return string.format("%.11f", ppq):gsub("%.?0+$", "") --gsub("%.%d+", ""))
    end
end


--------------------
function updateGUI()
    -- Updates the GUI - assuming that all the strings have already been given 
    --    their correct values by loopMIDIInspector
    
    local tabLong = tabLong
    local tabShort = tabShort
    
    lineHeight = math.max(strHeight, gfx.h / 26)
    setColor(backgroundColor)
    gfx.rect(1, 1, gfx.w-2, gfx.h-2, true)
    gfx.r=gfx.r*2; gfx.g=gfx.g*2; gfx.b=gfx.b*2; gfx.a = 1
    gfx.line(0, 0, gfx.w-1, 0)
    gfx.line(0, 1, 0, gfx.h-1)
    setColor(shadowColor)
    gfx.line(gfx.w-1, gfx.h-1, 0, gfx.h-1)
    gfx.line(gfx.w-1, gfx.h-1, gfx.w-1, 0)
    
    local midX = gfx.w/2
    
    ---------------------------------------------------------------
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
    gfx.rect(6, 1+lineHeight*6.85, gfx.w-11, lineHeight*7.5, false)
    setColor(shadowColor)
    gfx.rect(5, lineHeight*6.85, gfx.w-11, lineHeight*7.5, false)
    
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
    gfx.rect(6, 1+lineHeight*15.35, gfx.w-11, lineHeight*7.5, false)
    setColor(shadowColor)
    gfx.rect(5, lineHeight*15.35, gfx.w-11, lineHeight*7.5, false)
    
    setColor(backgroundColor)
    --gfx.rect(9, lineHeight * 13.5, strWidth["Selected CCs"], strHeight, true)
    gfx.rect(9, lineHeight * 15.0, strWidth["SELECTED CCs"], strHeight, true)
    setColor(textColor)
    gfx.x = 13
    gfx.y = lineHeight * 15.0
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
    gfx.y = lineHeight*23.3
    setColor(textColor)
    gfx.drawstr("Time format: ")
    --gfx.x = tabShort
    setColor(highlightColor)
    gfx.drawstr(tableTimeFormats[timeFormat])
    
    
    -- Draw Pause radio button
    local CHECKBOX_Y_POS = lineHeight*24.5
    setColor(backgroundColor)
    gfx.r=gfx.r*2; gfx.g=gfx.g*2; gfx.b=gfx.b*2; gfx.a = 1
    gfx.rect(11, 2+CHECKBOX_Y_POS, strHeight-2, strHeight-2, false)
    setColor(shadowColor)
    gfx.rect(10, 1+CHECKBOX_Y_POS, strHeight-2, strHeight-2, false)
    setColor(textColor) --{0.7,0.7,0.7,1})
    gfx.a = gfx.a*0.5
    gfx.rect(12, 3+CHECKBOX_Y_POS, strHeight-5, strHeight-5, true)
    setColor(textColor)
    gfx.x = 15 + strHeight
    gfx.y = CHECKBOX_Y_POS
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
    gfx.rect(midX+1, 2+CHECKBOX_Y_POS, strHeight-2, strHeight-2, false)
    setColor(shadowColor)
    gfx.rect(midX, 1+CHECKBOX_Y_POS, strHeight-2, strHeight-2, false)
    setColor(textColor) --{0.7,0.7,0.7,1})
    gfx.a = gfx.a*0.5
    gfx.rect(midX+2, 3+CHECKBOX_Y_POS, strHeight-5, strHeight-5, true)
    setColor(textColor)
    gfx.x = midX + 5 + strHeight
    gfx.y = CHECKBOX_Y_POS
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
        
    -- In order to do as little per cycle (so as not to waste REAPER's resources)
    --    this call to gfx.update has been commented out.  Only one call will be done 
    --    per cycle - right at the beginning of the loop.
    --gfx.update()
    
end -- function updateGUI

----------------------------
function loopMIDIInspector()
    
    -- Apparently gfx.update must be called in order to update gfx.w, gfx.mouse_x and other gfx variables
    gfx.update()
    
    -- Quit script if GUI has been closed
    local char = gfx.getchar()
    if char<0 then return(0) end         
    
    -- Or if there is no active MIDI editor
    editor = reaper.MIDIEditor_GetActive()
    if editor == nil then return(0) end
        
    -- If paused, GUI size will update and mouseclicks will be intercepted, but no MIDI updates
    if not paused then    
        
        -- (GetTake is buggy and sometimes returns an invalid, deleted take, so must validate take.)
        local take = reaper.MIDIEditor_GetTake(editor)
        if reaper.ValidatePtr(take, "MediaItem_Take*") and reaper.TakeIsMIDI(take) then
        
            -- Only do all the time-consuming GetNote and GetCC stuff if there were in fact changes in MIDI,
            --    or if active take has switched.
            -- Changes in MIDI can be monitored by getting the take's hash, but not changes in default 
            --    channel or velocity, so these settings are monitored separately.
            defaultVelocity = reaper.MIDIEditor_GetSetting_int(editor, "default_note_vel")
            -- Some of REAPER's MIDI function work with channel range 0-15, others with 1-16
            defaultChannel  = 1 + reaper.MIDIEditor_GetSetting_int(editor, "default_note_chan")  
        
            -- Has the project start positions changed?
            projStartMeasure = tonumber(reaper.format_timestr_pos(0, "", 2):match("([%d%-]+)"))
            projStartTime    = reaper.GetProjectTimeOffset(0, false)
            
            -- If take or hash is changed, then update the info.
            -- If not updated, the info strings simply remain the same.
            hashOK, takeHash = reaper.MIDI_GetHash(take, false, "")
            if take ~= prevTake or (hashOK and takeHash ~= prevHash) or projStartMeasure ~= prevProjStartMeasure or projStartTime ~= prevProjStartTime then
                prevTake = take
                prevHash = takeHash
                prevProjStartMeasure = projStartMeasure
                prevProjStartTime    = projStartTime
                
                -- Initialize temporary values for all the info that will soon be parsed
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
                local foundOverlaps = false
                
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
                
                countSelCCs = 0 -- These are not local, since the draw function must refer to them directly
                countSelNotes = 0

                countOK, numNotes, numCCs, numSysex = reaper.MIDI_CountEvts(take)
                --[[if countOK ~= true then
                    numNotes = "?"
                    numCCs = "?"
                    numSysex = "?"
                end]]
                
                ------------------------------------------------------------
                -- Now get all the info of the selected NOTES in active take
                -- Note: For later versions: use MIDI_GetHash limited to notes to check whether this section can be skipped
                
                local gotAllOK, MIDIstring = reaper.MIDI_GetAllEvts(take, "")
                
                if not gotAllOK then
                
                    countSelCCs = "GetAllEvts error"
                    countSelNotes = "GetAllEvts error"
                
                else
                
                    -- The following tables with temporarily store data while parsing:
                    local tableNoteOns = {} -- Store note-on position and pitch while waiting for the next note-off, to calculate note length
                    local tableCCMSB = {} -- While waiting for matching LSB of 14-bit CC
                    local tableCCLSB = {} -- While waiting for matching MSB of 14-bit CC
                    for chan = 0, 15 do
                        tableNoteOns[chan] = {}
                        tableCCMSB[chan] = {}
                        tableCCLSB[chan] = {}
                    end
                
                    local MIDIlen = MIDIstring:len()
                    local nextPos = 1 -- Position of current event inside MIDIstring
                    local runningPPQpos = 0 -- Parsed PPQ position of current event
                    
                    countSelCCs = 0
                    countSelNotes = 0
                    
                    -----------------------------------------------------
                    -- Start iterating through all the events in the take
                    while nextPos < MIDIlen do
                  
                        local offset, flags, msg
                        offset, flags, msg, nextPos = string.unpack("i4Bs4", MIDIstring, nextPos)
                        runningPPQpos = runningPPQpos + offset
                        
                        if flags&1 == 1 and msg:len() ~= 0 then -- selected, and skip empty events
                            
                            local eventType = msg:byte(1)>>4
                            local channel   = msg:byte(1)&0xF
                            local msg2      = msg:byte(2)
                            local msg3      = msg:byte(3)
                               
                            if eventType == 9 and msg3 ~= 0 then -- note-on
                                -- Check for overlaps
                                if tableNoteOns[channel][msg2] then foundOverlaps = true end        
                                countSelNotes = countSelNotes + 1
                                if runningPPQpos < noteLowPPQ then noteLowPPQ = runningPPQpos end
                                if runningPPQpos > noteHighPPQ then noteHighPPQ = runningPPQpos end
                                if channel < noteLowChannel then noteLowChannel = channel end
                                if channel > noteHighChannel then noteHighChannel = channel end
                                if msg2 < noteLowPitch then noteLowPitch = msg2 end
                                if msg2 > noteHighPitch then noteHighPitch = msg2 end
                                if msg3 < noteLowVelocity then noteLowVelocity = msg3 end
                                if msg3 > noteHighVelocity then noteHighVelocity = msg3 end
                                -- Store the index and PPQ position of this note-on with a unique key, so that later note-offs can find their matching note-on
                                tableNoteOns[channel][msg2] = runningPPQpos
                                  
                            elseif eventType == 8 or eventType == 9 then -- Note-off
                                -- Check whether there was a note-on on this channel and pitch.
                                if tableNoteOns[channel][msg2] then
                                    local noteLength = runningPPQpos - tableNoteOns[channel][msg2]
                                    if noteLength < noteLowLength then noteLowLength = noteLength end
                                    if noteLength > noteHighLength then noteHighLength = noteLength end
                                    tableNoteOns[channel][msg2] = false
                                end
                          
                            elseif eventType >= 11 and eventType <= 14 then 
                                countSelCCs = countSelCCs + 1
                                
                                if eventType < ccLowType then ccLowType = eventType end
                                if eventType > ccHighType then ccHighType = eventType end
                                                            
                                if eventType == 11 then value = msg3 -- standard CCs
                                elseif eventType == 14 then value = (msg3<<7) + msg2 -- pitch
                                else value = msg2 -- eventType == 13 or eventType == 12, channel pressure, program select
                
                                end
                                if value < ccLowValue then ccLowValue = value end
                                if value > ccHighValue then ccHighValue = value end
                            
                                if eventType == 11 then -- CC
                                    if msg2 < ccLowLane then ccLowLane = msg2 end
                                    if msg2 > ccHighLane then ccHighLane = msg2 end
                                end
                                                    
                                if runningPPQpos < ccLowPPQ then ccLowPPQ = runningPPQpos end
                                if runningPPQpos > ccHighPPQ then ccHighPPQ = runningPPQpos end
                                if channel < ccLowChannel then ccLowChannel = channel end
                                if channel > ccHighChannel then ccHighChannel = channel end
                            
                            end -- if eventType...
                            
                        end -- if flags&1 = 1 -- selected
                    
                    end -- while nextPos < MIDIlen
                    
                    
                    -------------------------------------------------
                    -- Got all event info, now translate into strings
                
                    if noteLowPPQ < noteHighPPQ then 
                        notePositionString = timeStr(take, noteLowPPQ, timeFormat) .. "\n" .. timeStr(take, noteHighPPQ, timeFormat)
                    elseif noteLowPPQ == noteHighPPQ then
                        notePositionString = timeStr(take, noteLowPPQ, timeFormat)
                    else 
                        notePositionString = ""
                    end
                    
                    if noteLowChannel < noteHighChannel then
                        noteChannelString = tostring(noteLowChannel+1) .. " - " .. tostring(noteHighChannel+1)
                    elseif noteLowChannel == noteHighChannel then 
                        noteChannelString = tostring(noteLowChannel+1)
                    else 
                        noteChannelString = ""
                    end
                    
                    if noteLowPitch < noteHighPitch then 
                        notePitchString = pitchString(noteLowPitch) .. " - " .. pitchString(noteHighPitch) 
                                        .. "  (" .. string.format("%i", noteLowPitch) .. " - " .. string.format("%i", noteHighPitch) .. ")"
                    elseif noteLowPitch == noteHighPitch then 
                        notePitchString = pitchString(noteLowPitch) .. "  (" .. string.format("%i", noteLowPitch) .. ")"
                    else 
                        notePitchString = ""
                    end
                                
                    if noteLowVelocity < noteHighVelocity then 
                        noteVelocityString = tostring(noteLowVelocity) .. " - " .. tostring(noteHighVelocity)
                    elseif noteLowVelocity == noteHighVelocity then 
                        noteVelocityString = tostring(noteLowVelocity)
                    else 
                        noteVelocityString = ""
                    end
                    
                    if foundOverlaps then noteLengthString = "? (Overlaps found)"
                    elseif noteLowLength < noteHighLength then 
                        noteLengthString = tostring(noteLowLength):match("[%d]+") .. " - " .. tostring(noteHighLength):match("[%d]+") .. " ticks"
                    elseif noteLowLength == noteHighLength then 
                        noteLengthString = tostring(noteLowLength):match("[%d]+") .. " ticks"
                    else 
                        noteLengthString = ""
                    end                    
                    
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
                           ccLaneString = tostring(ccLowLane) .. " - " .. tostring(ccHighLane)
                        end
                    else
                        ccLaneString = ""
                    end
                                
                    if ccLowValue < ccHighValue then 
                        ccValueString = tostring(ccLowValue) .. " - " .. tostring(ccHighValue)
                    elseif ccLowValue == ccHighValue then 
                        ccValueString = tostring(ccLowValue)
                    else 
                        ccValueString = ""
                    end
                    
                    if ccLowPPQ < ccHighPPQ then 
                        ccPositionString = timeStr(take, ccLowPPQ, timeFormat) .. "\n" .. timeStr(take, ccHighPPQ, timeFormat)
                    elseif ccLowPPQ == ccHighPPQ then 
                        ccPositionString = timeStr(take, ccLowPPQ, timeFormat)
                    else 
                        ccPositionString = ""
                    end
                    
                    if ccLowChannel < ccHighChannel then 
                        ccChannelString = tostring(ccLowChannel+1) .. " - " .. tostring(ccHighChannel+1)
                    elseif ccLowChannel == ccHighChannel then 
                        ccChannelString = tostring(ccLowChannel+1)
                    else 
                        ccChannelString = ""
                    end
                                            
                    if ccLowValue < ccHighValue then 
                        ccValueString = tostring(ccLowValue) .. " - " .. tostring(ccHighValue)
                    elseif ccLowValue == ccHighValue then 
                        ccValueString = tostring(ccLowValue)
                    else 
                        ccValueString = ""
                    end
                    
                end -- if gotAllOK
            end -- if takeHash ~= prevHash: get new note and CC info           
        end -- if take ~= nil: get new default channel and velocity
    end -- if paused == false
    
    -------------------------------------
    -- Now check if any mouse interaction
    -- gfx.update()
                
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
                prevHash = nil -- This just to force GUI to update in next loop
            end
        end -- type(defaultChannel) == "number" 
    end -- if gfx.mouse_cap == 1
    
    
    -- Checkboxes
    local CHECKBOX_Y_POS = lineHeight*24.5
    
    if gfx.mouse_cap == 1 and mouseAlreadyClicked == false 
    and gfx.mouse_y > CHECKBOX_Y_POS and gfx.mouse_y < CHECKBOX_Y_POS+lineHeight 
    then
        -- Pause / Unpause
        if gfx.mouse_x > 0 and gfx.mouse_x < gfx.w/2 then
            mouseAlreadyClicked = true
            paused = not paused
        -- Dock / Undock
        elseif gfx.mouse_x > gfx.w/2 and gfx.mouse_x < gfx.w then
            mouseAlreadyClicked = true
            if gfx.dock(-1) ~= 0 then
                gfx.dock(0)
            else
                gfx.dock(1)
            end
        end
    end
    
    -- Select time format
    if (gfx.mouse_cap == 2 or gfx.mouse_cap == 1)
    and mouseAlreadyClicked == false 
    and gfx.mouse_y > lineHeight*23.3 and gfx.mouse_y < lineHeight*24.3 
    --and gfx.mouse_x > gfx.w/2 and gfx.mouse_x < gfx.w
    then
        mouseAlreadyClicked = true
        gfx.x = strWidth["Time format"] --tabShort
        gfx.y = lineHeight*23
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
            prevHash = nil -- This just to force GUI to update in next loop    
        end
    end
    
    -- Click in notes area, open REAPER's Properties window (which defaults to Note Properties if notes as well as CCs are selected)
    if gfx.mouse_cap == 1 and mouseAlreadyClicked == false 
    and (  (gfx.mouse_y > lineHeight*8.5 and gfx.mouse_y < lineHeight*14.5)
        --or (gfx.mouse_y > lineHeight*16.5 and gfx.mouse_y < lineHeight*21.5)
        )
    then
        mouseAlreadyClicked = true
        reaper.MIDIEditor_OnCommand(editor, 40004)
    end
    
    -- Click in CC area, first ask user whether all notes should be deselected, then call Event Properties
    --    If notes are not deselected, REAPER will automatically open the Notes Properties window instead
    if gfx.mouse_cap == 1 and mouseAlreadyClicked == false 
    and (gfx.mouse_y > lineHeight*16.5 and gfx.mouse_y < lineHeight*22.5)
    then
        mouseAlreadyClicked = true
        
        -- Check whether there are any selected notes. If there are, get user input.
        local take = reaper.MIDIEditor_GetTake(editor)
        if reaper.ValidatePtr(take, "MediaItem_Take*")
        and (reaper.MIDI_EnumSelNotes(take, -1) ~= -1 or reaper.MIDI_EnumSelTextSysexEvts(take, -1) ~= -1) then
            local userInput = reaper.ShowMessageBox("If any notes or text/sysex are selected (and visible in the MIDI editor), REAPER will automatically open "
                                                        .. "their Properties window, instead of the CCs' Event Properties. Should all notes and text/sysex be deselected before continuing?", "CC properties", 3)
            if userInput == 2 then -- "Cancel"
                -- Do nothing
            elseif userInput == 6 then -- "Yes"
                local isTarget = {[8] = true, [9] = true, [15] = true} -- Note-offs, note-ons, and text/sysex.  Perhaps also [12] = true for Program Select?
                local gotAllOK, MIDIstring = reaper.MIDI_GetAllEvts(take, "")
                if gotAllOK then
                    local MIDIlen = MIDIstring:len()
                    local tableEvents = {} -- All events will be stored in this table until they are concatened again
                    local t = 0 -- Count index in table.  It is faster to use tableEvents[t] = ... than table.insert(...
                    local s_unpack = string.unpack
                    local s_pack   = string.pack
                    -- The script will speed up execution by not inserting each event individually into tableEvents as they are parsed.
                    --    Instead, only changed (i.e. deselected) events will be re-packed and inserted individually, while unchanged events
                    --    will be inserted as bulk blocks of unchanged sub-strings.
                    local nextPos, prevPos, unchangedPos = 1, 1, 1 -- unchangedPos is starting position of block of unchanged MIDI.
                    while nextPos <= MIDIlen do  
                        local offset, flags, msg
                        prevPos = nextPos
                        offset, flags, msg, nextPos = s_unpack("i4Bs4", MIDIstring, prevPos)
                        if flags&1 == 1 and isTarget[msg:byte(1)>>4] then -- then deselect!
                            -- First write all preceding unchanged events as one bulk block
                            if unchangedPos < prevPos then
                                t = t + 1
                                tableEvents[t] = MIDIstring:sub(unchangedPos, prevPos-1)
                            end
                            -- Now write the changed, deselected event
                            t = t + 1
                            tableEvents[t] = s_pack("i4Bs4", offset, flags&0xFE, msg)
                            unchangedPos = nextPos
                        end
                    end
                    t = t + 1
                    tableEvents[t] = MIDIstring:sub(unchangedPos)
                    reaper.MIDI_SetAllEvts(take, table.concat(tableEvents))
                else -- Not gotAllOK
                    reaper.ShowMessageBox("MIDI_GetAllEvts could not load the raw MIDI data of the active take.", "ERROR", 0)
                end
                reaper.MIDIEditor_OnCommand(editor, 40004) -- Call Event Properties
            elseif userInput == 7 then -- "No", so call properties without deselecting
                reaper.MIDIEditor_OnCommand(editor, 40004) -- Call Event Properties
            end
        else -- no selected notes and/or sysex found
            reaper.MIDIEditor_OnCommand(editor, 40004) -- Call Event Properties
        end
    end -- Of clicked on yellow CC text
    
    updateGUI()
   
    reaper.runloop(loopMIDIInspector)
end -- function loop GetSetChannel

--------------------------------------------------------------------
-- Here the code execution starts
--------------------------------------------------------------------
-- function main()

-- Check whether the required version of REAPER is available
if not reaper.APIExists("MIDI_GetAllEvts") then
    reaper.ShowMessageBox("This script requires REAPER v5.32 or higher.", "ERROR", 0)
    return(false) 
end

reaper.atexit(exit)

_, _, sectionID, ownCommandID, _, _, _ = reaper.get_action_context()
if not (sectionID == nil or ownCommandID == nil or sectionID == -1 or ownCommandID == -1) then
    reaper.SetToggleCommandState(sectionID, ownCommandID, 1)
    reaper.RefreshToolbar2(sectionID, ownCommandID)
end

-- Strangely, MIDI octave offet is stored in ini file with value 1 higher than that shown in Preferences.
octaveOffset = reaper.SNM_GetIntConfigVar("midioctoffs", 0) - 1


-- To measure string widths, must first open a GUI.
-- The GUI window will be opened at the last-used coordinates
local coordinatesExtState = reaper.GetExtState("MIDI Inspector", "Last coordinates") -- Returns an empty string if the ExtState does not exist
local dimensionsExtState  = reaper.GetExtState("MIDI Inspector", "Last dimensions")
local lastX, lastY          = coordinatesExtState:match("(%d+),(%d+)") -- Will be nil if cannot match
local lastWidth, lastHeight = dimensionsExtState:match("(%d+),(%d+)")
if lastHeight then initWidth, initHeight = lastWidth, lastHeight else initWidth, initHeight = 200, 410 end

gfx.init("MIDI Inspector", initWidth, initHeight, 0, lastX, lastY) -- Interesting, this function can accept xPos and yPos strings, without tonumber

    
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

paused = false
timeFormat = defaultTimeFormat

-- If this is the first time that the script is run, adapt GUI size to font size.
-- Apparently, the only way to change the GUI size is to quit and re-initiate.
if not lastHeight then
    initWidth = strWidth["Long time format"]+tabShort+15
    initHeight = (strHeight+3)*26
    gfx.quit()
    gfx.init("MIDI Inspector", initWidth, initHeight, 0, lastX, lastY) -- Interesting, this function can accept xPos and yPos strings, without tonumber
    gfx.setfont(1, fontFace, fontSize, 'b')
end

--gfx.update()

reaper.runloop(loopMIDIInspector)
