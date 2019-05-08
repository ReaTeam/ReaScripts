--[[
ReaScript name: js_MIDI Inspector.lua
Version: 1.50
Author: juliansader
Screenshot: http://stash.reaper.fm/28295/js_MIDI%20Inspector.jpeg
Website: http://forum.cockos.com/showthread.php?t=176878
Donation: https://www.paypal.me/juliansader
About:
  # DESCRIPTION
  
  This script shows important information about the active MIDI take, selected notes, and selected CCs.
  
  The script can open a separate GUI window, or can be docked in the marker/region lanes of the MIDI editor.
  
  
  The script improves on REAPER's native Properties windows in several ways:
  
  * The GUI is continuously updated and does not interfere with MIDI editing.  
  
  * If multiple events are selected, value ranges are shown.
  
  * Note, CC and take information are all shown simultaneously.
  
  * Note and CC positions can be displayed in any of REAPER's time formats.  
  
  * In Measure:Beat:Ticks format, script can display fractional tick values.
  
  * When working with multiple MIDI editors, the script will automatically switch to the active editor.
  
  
  # GUI FONTS AND COLORS
  
  In the script's USER AREA the user can change fonts and colors.  

  (On Windows, the script uses blurring to "fake" antialiasing. This can also be switched on or off in the USER AREA.)
  
  
  # TERMINATION
  
  If all MIDI editors are closed, the script will continue running in the background (with negligible CPU usage),
      and will automatiically reappear when a new editor is opened.
      
  To terminate the script, the user must explicitly close the GUI window, or click the toolbar button again 
      (or equivalently, run the script action again).  The first time that the script is closed by clicking
      the toolbar button, REAPER will ask whether to terminate the script.
      
  
  # INSTRUCTIONS
  
  If the GUI window is open:
  
    * Click on any of the highlighted values to open a Properties window or a dropdown menu in which the values can be changed.
  
    * The default colors of the GUI, as well as the font size, can be customized in the script's USER AREA.  
  
    * When opening, the script will recall its last-used position and size.
    
  If the Inspector is docked in the marker/region lanes:
  
    * Right-click on the Inspector to open a context menu.
  
  
  WARNING: 
  
  Updating MIDI information in realtime can take a toll on the responsiveness of the MIDI editor, 
      particularly if the take contains many thousands of MIDI events.  The GUI therefore provides a
      "Pause" option, which will pause the realtime updating.     
      
  Also, the user can set the minimum wait time between updating the inspector.  
      To do so, edit the "updateTime" parameter in the script's USER AREA.
   
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
  * v1.22 (2017-12-29)
    + Time format: Samples respects project start time and measure.
  * v1.23 (2018-05-01)
    + Automatically pause while playing or recording.
  * v1.30 (2019-01-19)
    + If the js_ReaScriptAPI extension is installed, automatically add pin-on-top button to GUI.
  * v1.40 (2019-02-17)
    + Inspector can be docked in MIDI editor marker/region lane.
    + Requires the js_ReaScriptAPI extension.
  * v1.45 (2019-02-19)
    + Recall docked state.
    + If Inspector is active, "js_Option - Selecting single note or CC in active take sets channel for new events" can also be enabled with no performance costs.
  * v1.46 (2019-02-27)
    + Properly release GDI device and objects.
    + Do not terminate when editor is closed; reappear when new editor is opened.
  * v1.48 (2019-03-03)
    + Linux and macOS: Don't dock in piano roll.
  * v1.49 (2019-03-15)
    + Fixed: Only capture right-click where docked inspector is visible.
  * v1.50 (2019-04-08)
    + Linux, macOS: Enable docking in piano roll.
    + WindowsOS: Less flickering and "fake" antialiasing when docked in piano roll.
]]

-- USER AREA
-- Settings that the user can customize:

-- How often should the inspector update?  Longer updateTime can help with (slightly) less CPU usage. (Time in seconds.)
local updateTime = 0.25 

-- Parameters for GUI window:
fontFace = "Arial"
textHeight = 14
textColor = {1,1,1,0.7}
highlightColor = {1,1,0,1}
backgroundColor = {0.18, 0.18, 0.18, 1}
shadowColor = {0,0,0,1}

-- Parameters for docked in MIDI editor ruler:
ME_TextHeight = 13 
ME_TextWeight = 100 -- Integer between 0 and 1000
ME_TextColor = nil -- 0xFF0000 -- Color in RRGGBB format. If nil, script will try to find theme color.
ME_TryAntiAlias = false -- On Windows, small LICE text is not properly antialiased.  This setting tries to achieve a similar effect by slightly blurring the text.
local s1, s2, s4, s6, s9, s12, s15 = 46, 110, 220, 330, 450, 600, 750 -- Spacing (tabs, in pixels) when drawing info in MIDI editor

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
    
local tableTimeFormatsShort = {[-1] = "",
                                [0] = "(M;B;Ticks)", -- This is how the MIDI editor's Properties window displays position (except with . instead of :)
                                [1] = "(M;B;Secs)",
                                [2] = "(M;B;Cents)",
                                [3] = "(Time)",
                                [4] = "(Time)",
                                [5] = "(Samples)",
                                [6] = "(h;m;s;f)",
                                [7] = "(Ticks)"}
                          
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

-- For communicating with "js_Option - Selecting single note or CC in active take sets channel for new events.lua"
-- Can't use ccChannelString or noteChannelString, becuase these use human-readable channels from 1-16 instead of 0-15
local noteChannel = nil  
local ccChannel = nil    

local projStartMeasure = 0 --tonumber(reaper.format_timestr_pos(0, "", 2):match("([%d%-]+)"))
local projStartTime    = 0 --reaper.GetProjectTimeOffset(0, false)

-- Preferences -> MIDI settings -> MIDI octave name display offset
local octaveOffset = 0

local paused = false
local playState = 0
local prevTime = 0
local prevExtStateSetChannel

local lastX, lastY, lastWidth, lastHeight, lastFormat, dockedInDocker, dockedMidiview = 0, 0, 211, 450, nil, 0, nil
local editor, prevEditor, midiview = nil, nil, nil
local mustUpdateGUI, prevGfxW, preGfxH = true, nil, nil


-------------------------
function measureStrings()
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
    strWidth["CC #"] = gfx.measurestr("CC #:  ")
    
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
end


------------------------
function initializeGUI()
    gfx.quit()
    
    -- The GUI window will be opened at the last-used coordinates
    local mouseX, mouseY = reaper.GetMousePosition()
    lastExtState = reaper.GetExtState("MIDI Inspector", "Last state") or ""
    lastX, lastY, lastWidth, lastHeight, lastFormat, dockedInDocker, lastdockedMidiview = lastExtState:match("([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+)")
    if not (lastX and lastY) then
        local coordinatesExtState = reaper.GetExtState("MIDI Inspector", "Last coordinates") or ""
        lastX, lastY = coordinatesExtState:match("([^,]+),([^,]+)")
    end
    lastX = lastX and tonumber(lastX) or mouseX
    lastY = lastY and tonumber(lastY) or mouseX
    if not (lastWidth and lastHeight) then
        local dimensionsExtState  = reaper.GetExtState("MIDI Inspector", "Last dimensions") or ""
        lastWidth, lastHeight = dimensionsExtState:match("([^,]+),([^,]+)")
    end
    lastWidth = lastWidth and tonumber(lastWidth) or 211
    lastHeight = lastHeight and tonumber(lastHeight) or 450
    timeFormat = timeFormat or (lastFormat and tonumber(lastFormat)) or 0 -- Only load timeFormat if script has just started, so timeFormat = nil
    dockedInDocker = dockedInDocker and tonumber(dockedInDocker) or 0
    if dockedMidiview == nil then dockedMidiview = (lastdockedMidiview == "true") else dockedMidiview = (dockedMidiview == true) end -- If dockedMidiview not yet initialized, use previous state, else keep state
    
    if not dockedMidiview then
        gfx.init("MIDI Inspector", lastWidth, lastHeight, dockedInDocker, lastX, lastY)
        gfx.setfont(1, fontFace, textHeight, 'b')
        measureStrings()
        
        -- Attach a "pin-on-top" button
        local num, list = reaper.JS_Window_ListFind("MIDI Inspector", true)
        for address in list:gmatch("[^,]+") do
            local hwnd = reaper.JS_Window_HandleFromAddress(address)
            if hwnd then reaper.JS_Window_AttachTopmostPin(hwnd) end
        end
    end
end


---------------------------
function saveCurrentState()
    -- Find and store the last-used coordinates of the GUI window, so that it can be re-opened at the same position
    if not dockedMidiview then
        dockedInDocker, xPos, yPos, xWidth, yHeight = gfx.dock(-1, 0, 0, 0, 0)
        if dockedInDocker == 0 then 
            -- xPos and yPos should already be integers, but use math.floor just to make absolutely sure
            lastX, lastY, lastWidth, lastHeight = math.floor(xPos+0.5), math.floor(yPos+0.5), math.floor(xWidth+0.5), math.floor(yHeight+0.5) 
    end end
    if lastX and lastY and lastWidth and lastHeight and timeFormat and dockedInDocker then
        saveState  = string.format("%i", lastX) .. "," 
                  .. string.format("%i", lastY) .. ","
                  .. string.format("%i", lastWidth) .. "," 
                  .. string.format("%i", lastHeight) .. ","
                  .. string.format("%i", timeFormat) .. ","
                  .. string.format("%i", dockedInDocker) .. ","
                  .. tostring(dockedMidiview)
        reaper.SetExtState("MIDI Inspector", "Last state", saveState, true)
    end
end


---------------
function exit()

    saveCurrentState()
    gfx.quit()
    reaper.DeleteExtState("MIDI Inspector", "Last coordinates", true)
    reaper.DeleteExtState("MIDI Inspector", "Last dimensions", true)
    reaper.DeleteExtState("MIDI Inspector", "Set channel", true)
    
    --if editor and reaper.MIDIEditor_GetMode(editor) ~= -1 and midiview and midiviewDC then reaper.JS_GDI_ReleaseDC(midiview, midiviewDC) end
    if GDI_Font then reaper.JS_GDI_DeleteObject(GDI_Font) end
    --[[for _, midiview in pairs(tEditorMidiview) do
        reaper.JS_Composite_Unlink(midiview, LICE_Bitmap)
    end]]
    
    if LICE_Bitmap then 
        if midiview then reaper.JS_Composite_Unlink(midiview, LICE_Bitmap) reaper.JS_Window_InvalidateRect(midiview, 0, 0, 1200, 26, false) end
        reaper.JS_LICE_DestroyBitmap(LICE_Bitmap)
    end
    
    -- Deactivate toolbar button
    _, _, sectionID, ownCommandID, _, _, _ = reaper.get_action_context()
    if not (sectionID == nil or ownCommandID == nil or sectionID == -1 or ownCommandID == -1) then
        reaper.SetToggleCommandState(sectionID, ownCommandID, 0)
        reaper.RefreshToolbar2(sectionID, ownCommandID)
    end
    
    -- Make sure MIDI editor is focused
    if reaper.SN_FocusMIDIEditor then
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
        [7] = "Ticks (from take start)"}
        ]]
    
    -- format_timestr_pos returns strings that are not in the same format as 
    --    how the MIDI editor's Properties window displays position.
    -- Therefore extra format options were added: 
    
    -- Also, "M:B:time" format is imprecise since it rounds the time, this will also be changed. 
    
    -- NB! format_timestr_pos does not take into account Project settings -> "Project start time" and "Project start measure"!
    
    -- BTW, all this string formatting stuff takes a mere few microseconds, so doesn't affect responsiveness at all.
    if format == -1 then
        return reaper.format_timestr_pos(reaper.MIDI_GetProjTimeFromPPQPos(take, ppq), "", -1):gsub(":", " ; ")
    -- Custom format measure:beat:ticks
    elseif format == 0 then 
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
    -- Measure:beat:seconds
    elseif format == 1 then 
        local t1 = reaper.time_precise()
        local eventTime = reaper.MIDI_GetProjTimeFromPPQPos(take, ppq)
        -- Why use format_timestr_pos instead of TimeMap2_timeToBeats?  
        --    Because format_timestr_pos returns negative time when event is slightly ahead of beats. This is useful to see how far ahead event is.
        local measureStr, beatStr = reaper.format_timestr_pos(eventTime, "", 2):match("([%d%-]+)[%.%:](%d+)")
        local measures, beats = tonumber(measureStr)-projStartMeasure, tonumber(beatStr)-1
        local beatTime  = reaper.TimeMap2_beatsToTime(0, beats, measures)
        local timeStr = string.format("%.10f", eventTime-beatTime):gsub("%.?0+$", "") -- gsub removes trailing zeroes and decimal point (use slightly lower precision so that string fits into GUI)
        if timeStr == "-0" then timeStr = "0" end
        --if (timeStr == "-0.000000000" or timeStr == "0.000000000") then timeStr = "0" end
        timeTaken = reaper.time_precise() - t1
        return (measureStr .. " ; " .. beatStr .. " ; " .. timeStr)
    -- Measures.Beats.Cents
    elseif format == 2 then -- Measures.Beats.Cents
        return reaper.format_timestr_pos(reaper.MIDI_GetProjTimeFromPPQPos(take, ppq), "", 2):gsub("%.", " ; ")
    -- Seconds (full floating point precision)
    elseif format == 3 then 
        --return tostring(reaper.MIDI_GetProjTimeFromPPQPos(take, ppq) + projStartTime)
        return string.format("%.11f", reaper.MIDI_GetProjTimeFromPPQPos(take, ppq) + projStartTime):gsub("%.?0+$", "") .. " s" -- gsub removes trailing zeroes and decimal point
    -- Time (min ; seconds)
    elseif format == 4 then 
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
    -- Samples
    --    Something very weird is going on with format_timestr_pos: 
    --    after experimentation I discovered that projStartTime be SUBTRACTED instead of added?
    elseif format == 5 then 
        return reaper.format_timestr_pos(reaper.MIDI_GetProjTimeFromPPQPos(take, ppq) - projStartTime, "", 4)
    -- h:m:s:f
    elseif format == 6 then 
        return reaper.format_timestr_pos(reaper.MIDI_GetProjTimeFromPPQPos(take, ppq), "", 5):gsub(":", " ; ")
    -- Ticks (from take start)
    elseif format == 7 then 
        return string.format("%.11f", ppq):gsub("%.?0+$", "") -- ppq should always be integer, but format just in case...
    end
end


-- local tTabs = {}
--------------------
function updateLICE()
    
    --[[if midiview then
        local rectOK, l, t, r, b = reaper.JS_Window_GetClientRect(midiview)
        if rectOK then
            local s = math.min(1200, math.max(600, (r-l)))
            if not tTabs[s] then
                local tab = math.max(30, math.min(90, s//21))
                tTabs[s] = {math.floor(46*ME_TextHeight/12), tab<<1, tab<<2, tab*6, tab*9, tab*12, tab*15}
            end
            local s1, s2, s4, s6, s9, s12, s15 = tTabs[s][1], tTabs[s][2], tTabs[s][3], tTabs[s][4], tTabs[s][5], tTabs[s][6], tTabs[s][7]
            ]]
            
            local numNotes = tostring(numNotes)
            local numCCs   = tostring(numCCs)
            local countSelCCs = tostring(countSelCCs)
            local countSelNotes = tostring(countSelNotes)
            local notePositionString = notePositionString:gsub("\n", "  --  ")
            local ccPositionString = ccPositionString:gsub("\n", "  --  ")
            local positionString = "Position " .. tableTimeFormatsShort[timeFormat] .. ": "
            
            reaper.JS_LICE_Clear(LICE_Bitmap, 0)
            reaper.JS_LICE_DrawText(LICE_Bitmap, LICE_Font, "NOTES:", 6, 2, 0, s1, 40)
            reaper.JS_LICE_DrawText(LICE_Bitmap, LICE_Font, numNotes, #numNotes, s1, 0, s2-4, 40)
            reaper.JS_LICE_DrawText(LICE_Bitmap, LICE_Font, "Selected: "..countSelNotes, 10+#countSelNotes, s2, 0, s4-4, 40)
            reaper.JS_LICE_DrawText(LICE_Bitmap, LICE_Font, "Channel: "..noteChannelString, 9+#noteChannelString, s4, 0, s6-4, 40)
            reaper.JS_LICE_DrawText(LICE_Bitmap, LICE_Font, "Pitch: "..notePitchString, 7+#notePitchString, s6, 0, s9-4, 40)
            reaper.JS_LICE_DrawText(LICE_Bitmap, LICE_Font, "Length: "..noteLengthString, 9+#noteLengthString, s9, 0, s12-4, 40)
            reaper.JS_LICE_DrawText(LICE_Bitmap, LICE_Font, "Velocity: "..noteVelocityString, 10+#noteVelocityString, s12, 0, s15-4, 40)
            reaper.JS_LICE_DrawText(LICE_Bitmap, LICE_Font, string.rep(" ", #positionString+#notePositionString), #positionString+#notePositionString, s15, 0, 2000, 40)
            reaper.JS_LICE_DrawText(LICE_Bitmap, LICE_Font, positionString..notePositionString, #positionString+#notePositionString, s15, 0, 2000, 40)
            
            reaper.JS_LICE_DrawText(LICE_Bitmap, LICE_Font, "CCs:", 4, 2, 11, s1, 40)
            reaper.JS_LICE_DrawText(LICE_Bitmap, LICE_Font, numCCs, #numCCs, s1, 11, s2-4, 40)
            reaper.JS_LICE_DrawText(LICE_Bitmap, LICE_Font, "Selected: "..countSelCCs, 10+#countSelCCs, s2, 11, s4-4, 40)
            reaper.JS_LICE_DrawText(LICE_Bitmap, LICE_Font, "Channel: "..ccChannelString, 9+#ccChannelString, s4, 11, s6-4, 40)
            reaper.JS_LICE_DrawText(LICE_Bitmap, LICE_Font, "Type:  "..ccTypeString, 7+#ccTypeString, s6, 11, s9-4, 40)
            reaper.JS_LICE_DrawText(LICE_Bitmap, LICE_Font, "CC #:    "..ccLaneString, 9+#ccLaneString, s9, 11, s12-4, 40)
            reaper.JS_LICE_DrawText(LICE_Bitmap, LICE_Font, "Value:     "..ccValueString, 11+#ccValueString, s12, 11, s15-4, 40)
            reaper.JS_LICE_DrawText(LICE_Bitmap, LICE_Font, positionString..ccPositionString, #positionString+#ccPositionString, s15, 11, 2000, 40)
            reaper.JS_Window_InvalidateRect(midiview, 0, 0, 1200, 26, false)
        --end
    --end
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
    
    gfx.x = tabShort - strWidth["CC #"]
    gfx.y = gfx.y + lineHeight
    setColor(textColor)
    gfx.drawstr("CC #: ")
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
    
    if paused == true or playState&5 ~= 0 then
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
    
    --[[if gfx.dock(-1) ~= 0 then
        setColor(shadowColor)
        gfx.x = midX + 3
        --gfx.y = lineHeight * 19.5
        gfx.drawstr("X")
        gfx.x = midX + 3
        gfx.y = gfx.y + 1
        gfx.drawstr("X")
    end]]
        
    -- In order to do as little per cycle (so as not to waste REAPER's resources)
    --    this call to gfx.update has been commented out.  Only one call will be done 
    --    per cycle - right at the beginning of the loop.
    --gfx.update()
    
end -- function updateGUI

tMidiview = {}
local prevTime = 0

----------------------------
function loopMIDIInspector() 
        
    -- CHECK MIDI EDITOR 
    -- Skip everything if no MIDI editor
            
    prevEditor = editor
    editor = reaper.MIDIEditor_GetActive()
    if editor == nil then 
        if prevEditor then -- Previously one or more editors were open, so this is first cycle after all editors have been closed.
            if midiview then 
                reaper.JS_Composite_Unlink(midiview, LICE_Bitmap) 
                if reaper.ValidatePtr(midiview, "HWND") then reaper.JS_Window_InvalidateRect(midiview, 0, 0, 1200, 26, false) end
            end
            midiview = nil
            saveCurrentState()
            gfx.quit()
        end
    
    -- MIDI editor exists
    else
        mustUpdateGUI = false
    
        if not prevEditor then 
            initializeGUI() 
        end -- Previously no editors were open, so this is first cycle after editor has been opened. 
        
        if editor ~= prevEditor then
            mustUpdateGUI = true
            -- Unlink previous editor's midiview
            if midiview then                 
                reaper.JS_Composite_Unlink(midiview, LICE_Bitmap) 
                if reaper.ValidatePtr(midiview, "HWND") then reaper.JS_Window_InvalidateRect(midiview, 0, 0, 1200, 26, false) end
            end
            -- Composite new editor's midiview
            midiview = reaper.JS_Window_FindChildByID(editor, 1001)
            if midiview and reaper.ValidatePtr(midiview, "HWND") then 
                if dockedMidiview then
                    reaper.JS_Composite(midiview, 0, 0, 1200, 26, LICE_Bitmap, 0, 0, 1200, 26)
                end
            else
                reaper.MB("Could not determine the midiview child window of the active MIDI editor.", "ERROR", 0)
                return false
            end
        end                
        
        -- CHECK MOUSE INTERACTION (before updating GUIs)
        -- This is done continuously and in each cycle, even if paused.
        
        if dockedMidiview then 
        
            -- Intercept right-click on docked inspector, and give own context menu.
            local prevMouseState = mouseState or 0
            mouseState = reaper.JS_Mouse_GetState(2)
            if mouseState > prevMouseState then
                local x, y = reaper.GetMousePosition()
                if reaper.JS_Window_FromPoint(x, y) == midiview then
                    local cx, cy = reaper.JS_Window_ScreenToClient(midiview, x, y)
                    if 0 <= cy and cy < 25 then
                        local menuString = paused and "!Pause|Undock||#Display position as:|" or "Pause|Undock||#Display position as:|"
                        -- Time format ranges from -1 (default) to 5
                        for i = -1, #tableTimeFormats do
                            if i == timeFormat then menuString = menuString .. "!" end
                            menuString = menuString .. tableTimeFormats[i] .. "|"
                        end
                        gfx.init("", 0, 0, 0, x+20, y+30)
                        gfx.x = -20
                        gfx.y = -50
                        local menuChoice = gfx.showmenu(menuString)
                        gfx.quit()
                        if menuChoice == 1 then
                            paused = not paused
                        elseif menuChoice == 2 then
                            dockedMidiview = false
                            if midiview and reaper.ValidatePtr(midiview, "HWND") then reaper.JS_Composite_Unlink(midiview, LICE_Bitmap) reaper.JS_Window_InvalidateRect(midiview, 0, 0, 1200, 26, false) end
                            mustUpdateGUI = true
                            initializeGUI()
                        elseif menuChoice > 3 then 
                            timeFormat = menuChoice-5
                            mustUpdateGUI = true
                            prevHash = nil -- This just to force GUI to update in next loop    
                        end
                    end -- if 0 <= cy and cy < 24
                end -- if reaper.JS_Window_FromPoint(x, y) == midiview
            end -- if mouseState > prevMouseState
            
        -- not dockedMidiview: Quit script if GUI has been closed
        else
            -- Apparently gfx.update must be called in order to update gfx.w, gfx.mouse_x and other gfx variables
            gfx.update()  
            if gfx.getchar() < 0 then 
                return(0)
            end
                      
            -- If the GUI size is being changed, update while changing
            if gfx.w ~= prevGfxW or gfx.h ~= prevGfxH then
                mustUpdateGUI = true
                prevGfxW, prevGfxH = gfx.w, gfx.h
            end
            
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
                        mustUpdateGUI = true -- This just to force GUI to update in next loop
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
                    mustUpdateGUI = true
                -- Dock / Undock
                elseif gfx.mouse_x > gfx.w/2 and gfx.mouse_x < gfx.w then
                    saveCurrentState()
                    gfx.quit()
                    mouseAlreadyClicked = true
                    mustUpdateGUI = true
                    dockedMidiview = true
                    if midiview and reaper.ValidatePtr(midiview, "HWND") then reaper.JS_Composite(midiview, 0, 0, 1200, 26, LICE_Bitmap, 0, 0, 1200, 26) reaper.JS_Window_InvalidateRect(midiview, 0, 0, 1200, 26, false) end
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
                    mustUpdateGUI = true   
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
            end -- If clicked on yellow CC text
        end
        
        
        -- PARSE MIDI, CONSTRUCT STRINGS
        
        -- If paused, GUI size will update and mouseclicks will be intercepted, but no MIDI updates.
        -- Also automatically pause while playing or recording, or if a js_Mouse editing script is running.
        
        if reaper.time_precise() > prevTime + updateTime then
            -- prevTime will be update *after* all the analyses
    
            local curPaused = paused or reaper.GetPlayState()&5 ~= 0 or reaper.GetExtState("js_Mouse actions", "Status") == "Running" -- playState: &1=playing,&2=pause,&=4 is recording
            if not curPaused then     
                
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
                        mustUpdateGUI = true
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
                                noteChannel = noteLowChannel
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
                                ccChannel = ccLowChannel
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
            end -- if curPaused == false       
            
            prevTime = reaper.time_precise()
            
        end -- if reaper.time_precise() > prevTime + updateTime 
            
            
        -- UPDATE GUI
        if mustUpdateGUI then
            if dockedMidiview then
                updateLICE()
            else
                updateGUI()
            end
        end
         
        
        -- COMMUNICATE with the script "js_Option - Selecting single note or CC in active take sets channel for new events.lua"
        local extStateSetChannel = ""
        if curPaused then
            extStateSetChannel = "Paused"
        elseif countSelNotes == 1 then
            extStateSetChannel = noteChannel
        elseif countSelNotes == 0 and countSelCCs == 1 then
            extStateSetChannel = ccChannel
        else
            extStateSetChannel = "Multi"
        end
        if extStateSetChannel ~= prevExtStateSetChannel then
            reaper.SetExtState("MIDI Inspector", "Set channel", extStateSetChannel, false)
            prevExtStateSetChannel = extStateSetChannel
        end
    
    end -- if editor ~= nil
       
    reaper.runloop(loopMIDIInspector)
    
end -- function loop GetSetChannel

---------------------------------------------------------------------
-- Here the code execution starts
---------------------------------------------------------------------
function main()
    
    -- Check whether ReaScriptAPI extension is available
    if not reaper.MIDI_DisableSort then
        reaper.MB("This script requires an up-to-date version of REAPER.", "ERROR", 0)
        return(false)
    elseif not reaper.JS_LICE_WritePNG then
        reaper.MB("This script requires an up-to-date version of the js_ReaScriptAPI extension."
               .. "\n\nThe js_ReaScriptAPI extension can be installed via ReaPack, or can be downloaded manually."
               .. "\n\nTo install via ReaPack, ensure that the ReaTeam/Extensions repository is enabled. "
               .. "This repository should be enabled by default in recent versions of ReaPack, but if not, "
               .. "the repository can be added using the URL that the script will copy to REAPER's Console."
               .. "\n\n(In REAPER's menu, go to Extensions -> ReaPack -> Import a repository.)"
               .. "\n\nTo install the extension manually, download the most recent version from Github, "
               .. "using the second URL copied to the console, and copy it to REAPER's UserPlugins directory."
                , "ERROR", 0)
        reaper.ShowConsoleMsg("\n\nURL to add ReaPack repository:\nhttps://github.com/ReaTeam/Extensions/raw/master/index.xml")
        reaper.ShowConsoleMsg("\n\nURL for direct download:\nhttps://github.com/juliansader/ReaExtensions")
        return(false)
    elseif not reaper.SNM_GetIntConfigVar then reaper.MB("This script required the SWS/S&M extension, which can be downloaded from\n\nwww.sws-extension.com.", "ERROR", 0) 
        return(false)
    end
    
    reaper.atexit(exit)
    
    _, _, sectionID, ownCommandID, _, _, _ = reaper.get_action_context()
    if not (sectionID == nil or ownCommandID == nil or sectionID == -1 or ownCommandID == -1) then
        reaper.SetToggleCommandState(sectionID, ownCommandID, 1)
        reaper.RefreshToolbar2(sectionID, ownCommandID)
    end
    
    windowsOS = reaper.GetOS():match("Win")
    if not windowsOS then 
        textHeight = textHeight - 2 -- gfx fonts look much larger on macOS and Linux than on Windows, for some reason.
        ME_TextHeight = ME_TextHeight - 2
    end
    
    -- SETUP LICE STUFF
    LICE_Bitmap = reaper.JS_LICE_CreateBitmap(true, 1200, 26)
    if not LICE_Bitmap then reaper.MB("Could not create a LICE bitmap.", "ERROR", 0) return(false) end
    
    -- To make script GUI feel more 'native', try to use theme colors.
    -- Strangely, SNM_GetIntConfigVar does not appear to work for theme colors.
    ME_TextColor = tonumber(ME_TextColor)
    if not ME_TextColor then
        local f = reaper.get_ini_file()
        if f then
            local f = io.open(f, "r")
            if f then
                local fs = f:read("*all")
                if fs then
                    ME_TextColor = tonumber(fs:match("midi_rulerfg=(%d+)")) or 0x0000FF -- REAPER's ini file uses BBGGRR format
                    ME_TextColor = 0xFF000000 | ((ME_TextColor&0xFF0000)>>16) | (ME_TextColor&0x00FF00) | ((ME_TextColor&0x0000FF)<<16) -- LICE uses AARRGGBB
                    f:close()
    end end end end
    LICE_Font = reaper.JS_LICE_CreateFont()
    if not LICE_Font then reaper.MB("Could not create a LICE font.", "ERROR", 0) return(false) end
    ::setFontSize:: do
        GDI_Font  = reaper.JS_GDI_CreateFont(ME_TextHeight, ME_TextWeight, 0, false, false, false, fontFace)
        if not GDI_Font then reaper.MB("Could not create a GDI font.", "ERROR", 0) return(false) end
        local options = (windowsOS and ME_TryAntiAlias) and "BLUR" or ""
        reaper.JS_LICE_SetFontFromGDI(LICE_Font, GDI_Font, options)
        --[[if reaper.JS_LICE_MeasureText() > 13 then
            reaper.JS_GDI_DeleteObject(GDI_Font)
            ME_TextHeight = ME_TextHeight - 1
            goto setFontSize
        end]]
    end
    reaper.JS_LICE_SetFontBkColor(LICE_Font, 0) -- Transparent
    reaper.JS_LICE_SetFontColor(LICE_Font, ME_TextColor)
    
    -- Strangely, MIDI octave offet is stored in ini file with value 1 higher than that shown in Preferences.
    octaveOffset = reaper.SNM_GetIntConfigVar("midioctoffs", 0) - 1    
    
    loopMIDIInspector()
end

main()
