--[[
ReaScript name: js_Mouse editing - Slice notes.lua
Version: 4.10
Author: juliansader
Screenshot: http://stash.reaper.fm/27951/Split%20notes%20by%20drawing%20line%20with%20mouse.gif
Website: http://forum.cockos.com/showthread.php?t=176878
Donation: https://www.paypal.me/juliansader
Provides: 
  [main=midi_editor,midi_inlineeditor] .
  js_Mouse editing - Slice notes.cur

About:
  # DESCRIPTION
  
  Split or trim multiple notes by drawing a "cutting line" with the mouse in the MIDI editor or inline piano roll.
  
  Notes that intersect the cutting line will be sliced at the position of intersection.               
  
  If snap-to-grid is enabled, the notes will be sliced at the grid.
  
  After drawing the line, the script will pop up a menu at the mouse position, with which the user can select between:
  * Split selected notes (split only *selected* notes that intersect the line)
  * Split notes (split any note that intersects the line)
  * Trim selected notes
  * Trim notes


  # INSTRUCTIONS
  
  To use, position mouse in the 'notes' area of the piano roll, press the shortcut key once, and then move the mouse to draw the cutting line.
    
  To end the script, left-click the mouse, press any mouse modifier key, or press the shortcut key again.
  
  
  PERFORMANCE TIP: The responsiveness of the MIDI editor is significantly influenced by the total number of events in 
      the visible and editable takes.  If the MIDI editor is slow, try reducing the number of editable and visible tracks.
      
  PERFORMANCE TIP 2: If the MIDI editor gets slow and jerky when a certain VST plugin is loaded, 
      check for graphics driver incompatibility by disabling graphics acceleration in the plugin.
]] 

--[[
  Changelog:
  * v4.00 (2019-01-19)
    + Updated for ReaScriptAPI extension.
  * v4.01 (2019-02-10)
    + Correct ReaPack header.
  * v4.02 (2019-02-11)
    + Restore focus to original window, if script opened notification window.
  * v4.03 (2019-02-16)
    + Fixed: On Linux, crashing if editor closed while script is running.
  * v4.04 (2019-03-02)
    + Fixed: If editor is docked, properly restore focus.
  * v4.10 (2019-03-05)
    + Compatible with macOS.
]] 


-- ################################################################################################
---------------------------------------------------------------------------------------------------
-- CONSTANTS AND VARIABLES (that modders may find useful)

local MIDIString -- The original raw MIDI data returned by GetAllEvts

-- The original value and PPQ ranges of selected events in the target lane will be summarized in:
local origValueMin, origValueMax, origValueRange, origValueLeftmost, origValueRightmost = nil, nil, nil, nil, nil
local origPPQleftmost, origPPQrightmost, origPPQRange = nil, nil, nil
--local includeNoteOffsInPPQRange = true
--local includeNoteOffsInPPQRange = false -- ***** Should origPPQRange and origPPQrightmost take note-offs into account? Set this flag to true for scripts that stretch or warp note lengths. *****
 
-- Starting values and position of mouse 
-- Not all of these lanes will be used by all scripts.
-- mouseOrigCCLane: (CC0-127 = 7-bit CC, 0x100|(0-31) = 14-bit CC, 0x200 = velocity, 0x201 = pitch, 
--    0x202=program, 0x203=channel pressure, 0x204=bank/program select, 
--    0x205=text, 0x206=sysex, 0x207=off velocity)
local laneMinValue, laneMaxValue = nil, nil -- The minimum and maximum values in the target lane
local mouseOrigCCLane, mouseOrigCCValue, mouseOrigPPQPos, mouseOrigPitch, mouseOrigCCLaneID = nil, nil, nil, nil, nil
--local snappedOrigPPQPos = nil -- If snap-to-grid is enabled, these will give the closest grid PPQ to the left. (Swing is not implemented.)

-- This script can work in inline MIDI editors as well as the main MIDI editors
-- The two types of editors require some different code, though.  
-- In particular, if in an inline editor, functions from the SWS extension will be used to track mouse position.
-- In the main editor, WIN32/SWELL functions from the js_ReaScriptAPI extension will be used.
local isInline, editor = nil, nil

-- Tracking the new value and position of the mouse while the script is running
local mouseX, mouseY
local mouseNewCCLane, mouseNewCCValue, mouseNewPPQPos, mouseNewPitch, mouseNewCCLaneID = nil, nil, nil, nil, nil
--local snappedNewPPQPos = nil

-- The script can be controlled by mousewheel, mouse buttons an mouse modifiers.  These are tracked by the following variables.
local mouseState
--local mousewheel = 1 -- Track mousewheel movement.  ***** This default value may change, depending on the script and formulae used. *****

-- REAPER preferences and settings that will affect the drawing/selecting of new events in take
local isSnapEnabled = false -- Will be changed to true if snap-to-grid is enabled in the editor
local activeChannel -- In case new MIDI events will be inserted, what is the default channel?
local editAllChannels = nil -- Is the MIDI editor's channel filter enabled?
local CCDensity -- CC resolution as set in Preferences -> MIDI editor -> "Events per quarter note when drawing in CC lanes"
local skipRedundantCCs
local PPQ -- ticks per quarter note

-- Variables that will be used to calculate the CC spacing
local PPerCC -- ticks per CC ** not necessarily an integer **
local QNperGrid
--local firstCCinTakePPQPos -- CC spacing should not be calculated from PPQPos = 0, since take may not start on grid.
--slocal firstGridInsideTakePPQPos -- If snap to grid, don't snap to left of this edge

-- Not only must the mouse cursor's PPQ position be snapped to the grid (except in some scripts such as Arch), 
--    but if the item is looped, must also be translated to its relative position in the first loop iteration
-- Also, the source length when the script begins will be checked against the source length when the script ends,
--    to ensure that the script did not inadvertently shift the positions of non-target events.
local loopStartPPQPos -- Start of loop iteration under mouse
local sourceLengthTicks -- = reaper.BR_GetMidiSourceLenPPQ(activeTake)
local minimumTick, maximumTick -- The mouse PPO position should not go outside the boundares of either the visible item or the underlying MIDI source

-- Some internal stuff that will be used to set up everything
local  _, activeItem, activeTake
local window, segment, details = nil, nil, nil -- given by the SWS function reaper.BR_GetMouseCursorContext()
local startTime, prevMouseTime = 0, 0
--local lastPPQPos -- to calculate offset to next CC
--local lastValue -- To compare against last value, if skipRedundantCCs

-- If the mouse is over a MIDI editor, these variables will store the on-screen layout of the editor.
-- NOTE: Getting the MIDI editor scroll and zoom values is slow, since the item chunk has to be parsed.
--    This script will therefore not update these variables after getting them once.  The user should not scroll and zoom while the script is running.
local activeTakeChunk
local ME_LeftmostTick, ME_PixelsPerTick, ME_PixelsPerSecond = nil, nil, nil -- horizontal scroll and zoom
local ME_TopPitch, ME_PixelsPerPitch, ME_BottomPitch = nil, nil, nil -- vertical scroll and zoom
local ME_CCLaneTopPixel, ME_CCLaneBottomPixel = nil, nil
local ME_midiviewWidth, ME_midiviewHeight = nil, nil -- Mouse screen coordinates will be converted to client, so leftmost and topmost pixels are always 0.
local ME_TargetTopPixel, ME_TargetBottomPixel
local ME_TimeBase
local tME_Lanes = {} -- store the layout of each MIDI editor lane
--local tVisibleCC7Bit = {} -- CC lanes to use.  (In case of a 14bit CC lane or Bank/Program, this table will contain two entries. If all visible lanes are used, may contain even more entries.)

-- I am not sure that declaring functions local really helps to speed things up...
local s_unpack = string.unpack
local s_pack   = string.pack
local m_floor  = math.floor

-- Window messages that will be intercepted while the script is running
local tWM_Messages = {WM_LBUTTONDOWN = false, WM_LBUTTONDBLCLK = false, WM_LBUTTONUP = false,
                      WM_MBUTTONDOWN = false, WM_MBUTTONDBLCLK = false, WM_MBUTTONUP = false,
                      WM_RBUTTONDOWN = false, WM_RBUTTONDBLCLK = false, WM_RBUTTONUP = false,
                      WM_NCMOUSEMOVE = false, -- I'm not sure... Does this prevent REAPER from changing the mouse cursor when it's over scrollbars?
                      WM_MOUSEWHEEL  = false, WM_MOUSEHWHEEL   = false,
                      WM_SETCURSOR   = false}                 
  
-- Unique to this script:
  
-- The PPQ position at which cuts should be made, using [pitch] as key
local tableCutPPQPos = {} -- tableCutPPQs[pitch]
local thicknessTicks = 6 -- How thick should the line be, in ticks? 2 seem sto work well at all zoom levels.

  
--#############################################################################################
-----------------------------------------------------------------------------------------------
-- The function that will be 'deferred' to run continuously
-- There are three bottlenecks that impede the speed of this function:
--    Minor: reaper.BR_GetMouseCursorContext(), which must unfortunately unavoidably be called before 
--           reaper.BR_GetMouseCursorContext_MIDI(), and which (surprisingly) gets much slower as the 
--           number of MIDI events in the take increases.
--           ** This script will therefore apply a nifty trick to speed up this function:  using
--           MIDI_SetAllEvts, the take will be cleared of all MIDI before running BR_...! **
--    Minor: MIDI_SetAllEvts (when filled with hundreds of thousands of events) is not fast - but is 
--           infinitely better than the standard API functions such as MIDI_SetCC.
--    Major: Updating the MIDI editor between defer cycles is by far the slowest part of the whole process.
--           The more events in visible and editable takes, the slower the updating.  MIDI_SetAllEvts
--           seems to get slowed down more than REAPER's native Actions such as Invert Selection.
--           If, in the future, the REAPER API provides a way to toggle take visibility in the editor,
--           it may be helpful to temporarily make all non-active takes invisible. 
-- The Lua script parts of this function - even if it calculates thousands of events per cycle,
--    make up only a small fraction of the execution time.
function DEFERLOOP_TrackMouseAndUpdateMIDI()
    
    -- Must the script terminate?
    -- There are several ways to terminate the script:  Left-click, left-drag, or modifier keys.
    -- This gives the user flexibility to control the script via keyboard or mouse, as desired.
    
    -- Must the script go through the entire function to calculate new MIDI stuff?
    -- MIDI stuff might be changed if the mouse has moved, mousebutton has been clicked, or mousewheel has scrolled, so need to re-calculate.
    -- Otherwise, mustCalculate remains nil, and can skip to end of function.
    local mustCalculate    
    
    -- TAKE VALID? or perhaps been deleted? 
    if not reaper.ValidatePtr2(0, activeTake, "MediaItem_Take*") then return false end  
    
    -- EXTSTATE: Other scripts can communicate with and control the other js_ scripts via ExtStates
    local extState = reaper.GetExtState("js_Mouse actions", "Status") or ""
    if extState == "" or extState == "Must quit" then return(false) end    
    
    -- MOUSE MODIFIERS / LEFT CLICK: (If the left mouse button or any modifier key is pressed, after first releasing them, quit.)
    -- This can detect left clicks even if the mouse is outside the MIDI editor
    local prevMouseState = mouseState or 0xFF
    mouseState = reaper.JS_Mouse_GetState(0xFF)
    if (mouseState&61) > (prevMouseState&61) then -- 61 = 0b00111101 = Ctrl | Shift | Alt | Win | Left button
        return false
    end
    
    -- MOUSE POSITION: (New versions of the script don't quit if mouse moves out of CC lane, but will still quit if moves too far out of midiview.
    mouseX, mouseY = reaper.GetMousePosition()
    if mouseX ~= prevMouseX or mouseY ~= prevMouseY then
        prevMouseX, prevMouseY = mouseX, mouseY
        mustCalculate = true
    end
    if isInline then
        window = reaper.BR_GetMouseCursorContext()
        if not (window == "midi_editor" or window == "arrange") then
            return false 
        end
    else 
        -- MIDI editor closed or changed mode?  Also, quit if moved too far outside piano roll.
        if reaper.MIDIEditor_GetMode(editor) ~= 0 then return false end 
        -- Mouse can't go outside MIDI editor, unless left-dragging (to ensure that user remembers that script is running)
        mouseX, mouseY = reaper.JS_Window_ScreenToClient(midiview, mouseX, mouseY)
        if mouseX < 0 or mouseY < 0 or ME_midiviewWidth <= mouseX or ME_midiviewHeight <= mouseY then 
            if mouseState&1 == 0 and (mouseX < -150 or mouseY < -150 or ME_midiviewWidth+150 < mouseX or ME_midiviewHeight+150 < mouseY) then
                return false
            elseif cursor then
                reaper.JS_Mouse_SetCursor(cursor)
            end
        end
    end
    
    -- LEFT DRAG: (If the left button was kept pressed for 1.5 second or longer, or after moving the mouse 20 pixels, assume left-drag, so quit when lifting.)
    local peekOK, pass, time = reaper.JS_WindowMessage_Peek(windowUnderMouse, "WM_LBUTTONUP")
    if peekOK and (time > startTime + 1.5) then
              --or  (time > startTime and (mouseX < mouseOrigX - 20 or mouseX > mouseOrigX + 20 or mouseY < mouseOrigY - 20 or mouseY > mouseOrigY + 20))) then
        return false
    end
    
    -- LEFT CLICK: (If the left mouse button or any modifier key is pressed, after first releasing them, quit.)
    peekOK, pass, time = reaper.JS_WindowMessage_Peek(windowUnderMouse, "WM_LBUTTONDOWN")
    if peekOK and time > startTime then 
        return false 
    end
 
    -- MOUSEWHEEL: (Script isn't controlled by mousewheel, but will quit if wheel+modifier is sent by mouse.)
    local peekOK, pass, time, keys, delta = reaper.JS_WindowMessage_Peek(windowUnderMouse, "WM_MOUSEWHEEL")
    if not (peekOK and time > prevMouseTime) then 
        peekOK, pass, time, keys, delta = reaper.JS_WindowMessage_Peek(windowUnderMouse, "WM_MOUSEHWHEEL")
    end 
    if peekOK and time > prevMouseTime+0.25 and keys&12 ~= 0 then
        return false
    end
        
        
    ---------------------
    -- DO THE MIDI STUFF!
    
    -- Scripts that extract selected MIDI events and re-concatenate them out of order (usually at the beginning of the MIDI string, for easier editing)
    --    cannot be auditioned in real-time while events are out of order, since such events are not played.
    -- If the mouse is held still, no editing is done, and instead the take is sorted, thereby temporarily allowing playback.
    -- NO NEED TO CALCULATE:
    if not mustCalculate then --and not takeIsSorted then
        --[[if not takeIsSorted then
            reaper.MIDI_Sort(activeTake)
            takeIsSorted = true
        end]]
        
    -- MUST CALCULATE:
    else        
        --takeIsSorted = false
      
        -- MOUSE NEW CC/PITCH VALUE (vertical position)
        if isInline then
            -- reaper.BR_GetMouseCursorContext was already called above
            _, _, mouseNewPitch = reaper.BR_GetMouseCursorContext_MIDI()
            if mouseNewPitch == -1 then mouseNewPitch = (mousePrevPitch or mouseOrigPitch) else mousePrevPitch = mouseNewPitch end
        else
            mouseNewPitch = ME_TopPitch - ((mouseY - tME_Lanes[-1].ME_TopPixel) / ME_PixelsPerPitch)
            if mouseNewPitch > ME_TopPitch then mouseNewPitch = ME_TopPitch
            elseif mouseNewPitch < ME_BottomPitch then mouseNewPitch = ME_BottomPitch
            else mouseNewPitch = math.floor(mouseNewPitch + 0.5)
            end
        end
            
        -- MOUSE NEW TICK / PPQ VALUE (horizontal position)
        -- Snapping not relevant to this script
        if isInline then
            -- A call to BR_GetMouseCursorContext must always precede the other BR_ context calls
            mouseNewPPQPos = reaper.MIDI_GetPPQPosFromProjTime(activeTake, reaper.BR_GetMouseCursorContext_Position())
        elseif ME_TimeBase == "beats" then
            mouseNewPPQPos = ME_LeftmostTick + mouseX/ME_PixelsPerTick
        else -- ME_TimeBase == "time"
            mouseNewPPQPos = reaper.MIDI_GetPPQPosFromProjTime(activeTake, ME_LeftmostTime + mouseX/ME_PixelsPerSecond )
        end
        mouseNewPPQPos = mouseNewPPQPos - loopStartPPQPos -- Adjust mouse PPQ position for looped items
        mouseNewPPQPos = math.max(minimumTick, math.min(maximumTick, mouseNewPPQPos))
        
        --[[ LINE THICKNESS
        -- If inline or timebase == "time", pixels/ticks may vary over item.  Therefore try to find the average pixels/ticks over used area.
        if isInline or ME_TimeBase == "time" then
            if mouseNewPPQPos < mouseLeftmostPPQPos then mouseLeftmostPPQPos = mouseNewPPQPos
            elseif mouseNewPPQPos > mouseRightmostPPQPos then mouseRightmostPPQPos = mouseOrigPPQPos
            end
            if mouseX < mouseLeftmostPixel then mouseLeftmostPixel = mouseX
            elseif mouseX > mouseRightmostPixel then mouseRightmostPixel = mouseX
            end
            if mouseRightmostPixel > mouseLeftmostPixel then
                thicknessTicks = math.max(4, 4*math.ceil((mouseRightmostPPQPos-mouseLeftmostPPQPos)/(mouseRightmostPixel-mouseLeftmostPixel)))
            end
        end]]
        
        -- Clear the table of line MIDI event
        local tableLineMIDI = {}
        local t = 0 -- -- Count index in tableLine - This is faster than using table.insert or even #table+1
        lastPPQPos = 0
        tableCutPPQPos = {} -- The PPQ position at which cuts should be made, using [pitch] as key (NOT local)
        
        if mouseNewPitch == mouseOrigPitch then -- Separate code for this case since denominator=0, and should not insert second note at mouse position.
            local ppq = mouseOrigPPQPos
            if isInline then
                local timePos = reaper.MIDI_GetProjTimeFromPPQPos(activeTake, ppq)
                local snappedTimePos = reaper.SnapToGrid(0, timePos) -- If snap-to-grid is not enabled, will return timePos unchanged
                ppq = reaper.MIDI_GetPPQPosFromProjTime(activeTake, snappedTimePos)
            elseif isSnapEnabled then --and pitch ~= mouseOrigPitch and pitch ~= mouseNewPitch then
                -- Note that the line snaps to closest grid, not the floor grid
                local QNpos = reaper.MIDI_GetProjQNFromPPQPos(activeTake, ppq)
                local roundGridQN = math.floor(QNpos/QNperGrid + 0.5)*QNperGrid
                ppq = reaper.MIDI_GetPPQPosFromProjQN(activeTake, roundGridQN) 
            end
            ppq = math.floor(ppq + 0.5)
            tableCutPPQPos[mouseOrigPitch] = ppq 
            t = t + 1
            tableLineMIDI[t] = s_pack("i4Bi4BBB", (ppq-thicknessTicks/2)-lastPPQPos, 3, 3, 0x90|activeChannel, mouseOrigPitch, 1)
            t = t + 1
            tableLineMIDI[t] = s_pack("i4Bi4BBB", thicknessTicks, 3, 3, 0x80|activeChannel, mouseOrigPitch, 0)
            lastPPQPos = ppq + thicknessTicks/2
        else
            if mouseOrigPitch <= mouseNewPitch then step = 1 else step = -1 end
            for pitch = mouseOrigPitch, mouseNewPitch, step do
                local tick = mouseOrigPPQPos + (mouseNewPPQPos-mouseOrigPPQPos)*(pitch-mouseOrigPitch)/(mouseNewPitch-mouseOrigPitch)
                if isInline then
                    local timePos = reaper.MIDI_GetProjTimeFromPPQPos(activeTake, tick)
                    local snappedTimePos = reaper.SnapToGrid(0, timePos) -- If snap-to-grid is not enabled, will return timePos unchanged
                    tick = reaper.MIDI_GetPPQPosFromProjTime(activeTake, snappedTimePos)
                elseif isSnapEnabled then --and pitch ~= mouseOrigPitch and pitch ~= mouseNewPitch then             
                    -- Note that the line snaps to closest grid, not the floor grid
                    local QNpos = reaper.MIDI_GetProjQNFromPPQPos(activeTake, tick)
                    local roundGridQN = math.floor(QNpos/QNperGrid + 0.5)*QNperGrid
                    tick = reaper.MIDI_GetPPQPosFromProjQN(activeTake, roundGridQN) 
                end
                tick = math.floor(tick + 0.5)
                tableCutPPQPos[pitch] = tick
                t = t + 1
                tableLineMIDI[t] = s_pack("i4Bi4BBB", (tick-thicknessTicks/2)-lastPPQPos, 3, 3, 0x90|activeChannel, pitch, 1)
                t = t + 1
                tableLineMIDI[t] = s_pack("i4Bi4BBB", thicknessTicks, 3, 3, 0x80|activeChannel, pitch, 0)
                lastPPQPos = tick + thicknessTicks/2
            end
        end   
          
        -----------------------------------------------------------
        -- Write the edited events into the MIDI chunk!
        reaper.MIDI_SetAllEvts(activeTake, table.concat(tableLineMIDI) .. string.pack("i4Bs4", -lastPPQPos, 0, "") .. MIDIString)

        if isInline then reaper.UpdateItemInProject(activeItem) end
        
    end -- mustCalculate stuff

    
    ---------------------------
    -- Tell pcall to loop again
    return true
    
end -- DEFERLOOP_TrackMouseAndUpdateMIDI()


--############################################################################################
----------------------------------------------------------------------------------------------
-- Why is the TrackMouseAndUpdateMIDI function isolated behind a pcall?
--    If the script encounters an error, all intercepts must first be released, before the script quits.
function DEFERLOOP_pcall()
    pcallOK, pcallRetval = pcall(DEFERLOOP_TrackMouseAndUpdateMIDI)
    if pcallOK and pcallRetval then
        reaper.defer(DEFERLOOP_pcall)
    end
end


--##########################################################################
----------------------------------------------------------------------------
function SliceNotes()
    
    local tableEvents = {} -- Individual events in MIDIString will be stored in this table while parsing, and re-concatenated at the end
    
    -- First, show menu and get user inputs
    local menuStr = "|Split notes|Split selected notes||Trim notes|Trim selected notes||"
    local x, y = reaper.GetMousePosition()
    gfx.init("_Split_or_Trim______", 0, 0, 0, x, y)
    local hwnd = reaper.JS_Window_Find("_Split_or_Trim______", true)
    if hwnd then reaper.JS_Window_SetOpacity(hwnd, "ALPHA", 0) end
    if reaper.GetOS():match("OSX") then
        gfx.x, gfx.y = gfx.screentoclient(x-5, y+40)
    else
        gfx.x, gfx.y = gfx.screentoclient(x-5, y-40)
    end
    local mode = gfx.showmenu(menuStr)
    gfx.quit()
    
    if mode == 0 then
    
        dontSlice = true
    
    else
    
        local notOnlySelected = (mode == 1 or mode == 3)
        splitOrTrim = (mode == 3 or mode == 4) and "trim" or "split"
        
        -- To find each note-ons matching note-off, the info of note-ons will temporarily be stored in tableNoteOns.
        local tableNoteOns = {} 
        for flags = 0, 3 do
            tableNoteOns[flags] = {}
            for chan = 0, 15 do
                tableNoteOns[flags][chan] = {} -- tableNoteOns[flags][channel][pitch] = {PPQPos, msg}
            end
        end
        
        -- All the parsed and cut MIDI events will be stored in tableEvents
        local t = 0
        
        local stringPos = 1 -- Position in MIDIString while parsing
        local runningPPQPos = 0 -- PPQ position of event parsed
        local MIDIlen = MIDIString:len()
        while stringPos < MIDIlen do
            local hasAlreadyInsertedEvent = false
            local offset, flags, msg
            offset, flags, msg, stringPos = s_unpack("i4Bs4", MIDIString, stringPos)
            runningPPQPos = runningPPQPos + offset
            if flags&1 == 1 or notOnlySelected then
                if msg:len() == 3 and (editAllChannels or msg:byte(1)&0x0F == activeChannel) then
                    local eventType = msg:byte(1)>>4
                    if eventType == 9 and not (msg:byte(3) == 0) then
                        local channel = msg:byte(1)&0x0F
                        local pitch   = msg:byte(2)
                        if tableNoteOns[flags][channel][pitch] then
                            reaper.MIDI_SetAllEvts(activeTake, MIDIString) -- Restore original MIDI                    
                            reaper.MB("The script has encountered overlapping notes."
                                    .. "\n\nSuch notes are not legal MIDI data, and their lengths can not be parsed.", "ERROR", 0)
                            dontSlice = true
                            break
                        else
                            tableNoteOns[flags][channel][pitch] = {notePPQ = runningPPQPos, noteMsg = msg}
                        end
                    elseif eventType == 8 or (eventType == 9 and msg:byte(3) == 0) then
                        local channel = msg:byte(1)&0x0F
                        local pitch   = msg:byte(2)
                        if tableNoteOns[flags][channel][pitch] then -- Is there a matching note-on waiting?
                            if tableCutPPQPos[pitch] then -- Does this pitch fall within the cutting line's pitch range?
                                if tableCutPPQPos[pitch] > tableNoteOns[flags][channel][pitch].notePPQ and tableCutPPQPos[pitch] < runningPPQPos then
                                    t = t + 1
                                    tableEvents[t] = s_pack("i4Bs4", offset - runningPPQPos + tableCutPPQPos[pitch], flags, msg)
                                    t = t + 1
                                    if splitOrTrim == "trim" then
                                        -- The only difference between trimming and splitting is that the former does not insert a new note.
                                        -- Instead, it simply inserts an empty event as 'spacer' to update the running PPQ position:
                                        tableEvents[t] = s_pack("i4Bs4", runningPPQPos - tableCutPPQPos[pitch], flags, "")  
                                    else -- mode == "split"
                                        tableEvents[t] = s_pack("i4Bs4", 0, flags, tableNoteOns[flags][channel][pitch].noteMsg)
                                        t = t + 1
                                        tableEvents[t] = s_pack("i4Bs4", runningPPQPos - tableCutPPQPos[pitch], flags, msg)  
                                    end                             
                                    hasAlreadyInsertedEvent = true
                                end
                            end
                        end
                        tableNoteOns[flags][channel][pitch] = nil
                    end
                end -- if msg:len() == 3 
            end -- if flags&1 == 1 or not onlySliceSelectedNotes
            if not hasAlreadyInsertedEvent then
                t = t + 1
                tableEvents[t] = s_pack("i4Bs4", offset, flags, msg)
            end                  
        end -- while stringPos < MIDIlen
        
        if not (type(tableEvents[#tableEvents]) == "string" and tableEvents[#tableEvents]:sub(-8) == MIDIString:sub(-8)) then
            dontSlice = true
        end        
    
    end -- if mode ~= 0
    
    if dontSlice then
        reaper.MIDI_SetAllEvts(activeTake, MIDIString)
        return false
    else
        reaper.MIDI_SetAllEvts(activeTake, table.concat(tableEvents))
        return true
    end
end


--##########################################################################
----------------------------------------------------------------------------
function AtExit()    
    
    -- Remove intercepts, restore original intercepts
    -- WARNING! v0.963 of ReaScriptAPI may crash on Linux if all intercepts are released from a window that doesn't exist any more.
    if pcallInterceptOK and pcallInterceptRetval and (isInline or (editor and reaper.MIDIEditor_GetMode(editor) ~= -1)) then
        for message, passthrough in pairs(tWM_Messages) do
            if passthrough then 
                reaper.JS_WindowMessage_PassThrough(windowUnderMouse, message, true)
            else
                reaper.JS_WindowMessage_Release(windowUnderMouse, message)    
    end end end
    
    -- As when starting the script, restore cursor and toolbar button as soon as possible, in order to seem more responsive.
    -- Was a custom cursur loaded? Restore plain cursor.
    if cursor then 
        cursor = reaper.JS_Mouse_LoadCursor(32512) -- IDC_ARROW standard arrow
        if cursor then reaper.JS_Mouse_SetCursor(cursor) end
    end 
    
    -- Deactivate toolbar button (if it has been toggled)
    if origToggleState and sectionID and commandID and not leaveToolbarButtonArmed then
        reaper.SetToggleCommandState(sectionID, commandID, origToggleState)
        reaper.RefreshToolbar2(sectionID, commandID)
    end  
    
    -- Communicate with the js_Run.. script that this script is exiting
    reaper.DeleteExtState("js_Mouse actions", "Status", true)
    
    
    -- Was an active take found, and does it still exist?  If not, don't need to do anything to the MIDI.
    if reaper.ValidatePtr2(0, activeTake, "MediaItem_Take*") and reaper.TakeIsMIDI(activeTake) then
        -- Before exiting, if DEFERLOOP_pcall was successfully executed, do the slicing.
        -- The slice function will also ensure that the MIDI is re-uploaded into the active take.
        if pcallOK == true then 
            pcallOK, pcallRetval = pcall(SliceNotes)
        end
        
        -- DEFERLOOP_pcall and DeleteExistingCCsInRange were executed, and no exceptions encountered:
        if pcallOK then
            -- MIDI_Sort used to be buggy when dealing with overlapping or unsorted notes,
            --    causing infinitely extended notes or zero-length notes.
            -- Fortunately, these bugs were seemingly all fixed in v5.32.
            reaper.MIDI_Sort(activeTake)
             
            -- Check that there were no inadvertent shifts in the PPQ positions of unedited events.
            if sourceLengthTicks and not (sourceLengthTicks == reaper.BR_GetMidiSourceLenPPQ(activeTake)) then
                if MIDIString then reaper.MIDI_SetAllEvts(activeTake, MIDIString) end -- Restore original MIDI
                reaper.MB("The script has detected inadvertent shifts in the PPQ positions of unedited events."
                .. "\n\nThis may be due to a bug in the script, or in the MIDI API functions."
                .. "\n\nPlease report the bug in the following forum thread:"
                .. "\nhttp://forum.cockos.com/showthread.php?t=176878"
                .. "\n\nThe original MIDI data will be restored to the take."
                , "ERROR", 0)
            end
        end
        
        -- DEFERLOOP_pcall was executed, but exception encountered:
        if pcallOK == false then
        
            if MIDIString then reaper.MIDI_SetAllEvts(activeTake, MIDIString) end -- Restore original MIDI
            reaper.MB("The script encountered an error."
                    .."\n\n* The detailed error text has been copied to the console -- please report these details in the \"MIDI Editor Tools\" thread in the REAPER forums."
                    .."\n\n* The original, unaltered MIDI has been restored to the take."
                    , "ERROR", 0)
            reaper.ShowConsoleMsg("\n\n" .. tostring(pcallRetval)) -- If pcall returs an error, the error data is in the second return value, namely deferMustContinue  
        end
    end -- if reaper.ValidatePtr2(0, "MediaItem_Take*", activeTake) and reaper.TakeIsMIDI(activeTake)
    
 
    -- if script reached DEFERLOOP_pcall (or the WindowMessage section), pcallOK ~= nil, and must create undo point:
    if pcallOK ~= nil then        
                  
        -- Write nice, informative Undo stringsW
        if splitOrTrim == "trim" then
            undoString = "Trim notes"
        elseif splitOrTrim == "split" then
            undoString = "Split notes"
        else
            undoString = "Slice notes"
        end
        
        -- Undo_OnStateChange_Item is expected to be the fastest undo function, since it limits the info stored 
        --    in the undo point to changes in this specific item.
        if reaper.ValidatePtr2(0, activeItem, "MediaItem*") then    
            if isInline then reaper.UpdateItemInProject(activeItem) end
            reaper.Undo_OnStateChange_Item(0, undoString, activeItem)
        else
            reaper.Undo_OnStateChange2(0, undoString)
        end      
            
    end

    
    -- At the very end, no more notification windows will be opened, 
    --    so restore original focus - except if "Terminate script" dialog box is waiting for user
    -- Also, restore "Display note names" state
    if editor and reaper.MIDIEditor_GetMode(editor) ~= -1 then
        if displayNoteNames == 1 then reaper.MIDIEditor_OnCommand(editor, 40045) end
        if midiview then
            curForegroundWindow = reaper.JS_Window_GetForeground()
            if not (curForegroundWindow and reaper.JS_Window_GetTitle(curForegroundWindow) == reaper.JS_Localize("ReaScript task control", "common")) then
                reaper.JS_Window_SetForeground(editor)
                reaper.JS_Window_SetFocus(editor)
    end end end
    
end -- function AtExit   


--###############################################################################################
-------------------------------------------------------------------------------------------------
-- Returns true, laneType if CC lane could be parsed, 
--    true, nil if multiple visible lanes were enabled, and 
--    false if target lane is unusable or could not be parsed.
function SetupTargetLaneForParsing(laneID, target)
    -- Since 7bit CC, 14bit CC, channel pressure, and pitch all require somewhat different tweaks,
    --    these must often be distinguished. 
    local SetupIndividualLane = {} -- Why not make setupIndividualLane a standard function?  Because I don't want this helper function to be listed in the right-click list
    setmetatable(SetupIndividualLane, {__index = function(t, laneType)
                                          laneType = tonumber(laneType) or 0xFFFF
                                          if laneType == -1 then
                                              laneIsPIANOROLL, laneIsNOTES, laneMinValue, laneMaxValue = true, true, 0, 127
                                          elseif (0 <= laneType and laneType <= 127) then -- CC, 7 bit (single lane)
                                              laneIsCC7BIT, laneMinValue, laneMaxValue = true, 0, 127
                                              --tVisibleCC7Bit[laneType] = true
                                          elseif (laneType == 0x200) then
                                              laneIsVELOCITY, laneIsNOTES, laneMinValue, laneMaxValue = true, true, 1, 127
                                          elseif (laneType == 0x201) then
                                              laneIsPITCH, laneMinValue, laneMaxValue = true, 0, 16383
                                          elseif (laneType == 0x202) then
                                              laneIsPROGRAM, laneMinValue, laneMaxValue = true, 0, 127
                                          elseif (laneType == 0x203) then
                                              laneIsCHANPRESS, laneMinValue, laneMaxValue = true, 0, 127
                                          elseif (laneType == 0x204) then
                                              laneIsBANKPROG, laneIsPROGRAM, laneMinValue, laneMaxValue = true, true, 0, 127
                                              --tVisibleCC7Bit[0]  = true
                                              --tVisibleCC7Bit[32] = true
                                          elseif (laneType == 0x205) then
                                              laneIsTEXT = true
                                          elseif (laneType == 0x206) then
                                              laneIsSYSEX = true
                                          elseif (laneType == 0x207) then
                                              laneIsOFFVEL, laneIsNOTES, laneMinValue, laneMaxValue = true, true, 0, 127
                                          elseif (laneType == 0x208) then
                                              laneIsNOTATION = true
                                          elseif (laneType == 0x210) then
                                              laneIsMEDIAITEM = true
                                          elseif (256 <= laneType and laneType <= 287) then -- CC, 14 bit (double lane)
                                              laneIsCC14BIT, laneMinValue, laneMaxValue = true, 0, 16383 
                                              --tVisibleCC7Bit[laneType-256] = true
                                              --tVisibleCC7Bit[laneType-224] = true
                                          else -- not a lane type in which script can be used.
                                             --reaper.MB("One or more of the CC lanes are of unknown type, and could not be parsed by this script.", "ERROR", 0)
                                             return false
                                          end
                                          
                                          return true
                                      end
                                      })

    laneType = tonumber(tME_Lanes[laneID] and tME_Lanes[laneID].Type)
    if laneType then
        if SetupIndividualLane[laneType] then
            ME_TargetTopPixel = tME_Lanes[laneID].ME_TopPixel
            ME_TargetBottomPixel = tME_Lanes[laneID].ME_BottomPixel
            return true, laneType
        else
            return false, nil
        end
    else
        laneIsALL = true
        return true, nil
    end
end


--##############################################################################################
------------------------------------------------------------------------------------------------
-- Lane numbers as used in the chunk's VELLANE field differ from those returned by API functions 
--    such as MIDIEditor_GetSetting_int(editor, "last_clicked").
--[[   last_clicked_cc_lane: returns 0-127=CC, 0x100|(0-31)=14-bit CC, 
       0x200=velocity, 0x201=pitch, 0x202=program, 0x203=channel pressure, 
       0x204=bank/program select, 0x205=text, 0x206=sysex, 0x207=off velocity]]
function ConvertCCTypeChunkToAPI(lane)
    local tLanes = {[ -1] = 0x200, -- Velocity
                    [128] = 0x201, -- Pitch
                    [129] = 0x202, -- Program select
                    [130] = 0x203, -- Channel pressure
                    [131] = 0x204, -- Bank/program
                    [132] = 0x205, -- Text
                    [133] = 0x206, -- Sysex
                    [167] = 0x207, -- Off velocity
                    [166] = 0x208, -- Notation
                    [ -2] = 0x210, -- Media Item lane
                   }    
    if type(lane) == "number" and 134 <= lane and lane <= 165 then 
        return (lane + 122) -- 14 bit CC range from 256-287 in API
    else 
        return (tLanes[lane] or lane) -- If 7bit CC, number remains the same
    end
end


--#############################################################################################
-----------------------------------------------------------------------------------------------
function SetupMIDIEditorInfoFromTakeChunk()
    -- This function assumes that activeTake and activeItem have already been determined and validated
    
    -- First, get the active take's part of the item's chunk.
    -- In the item chunk, each take's data is separate, and in the same order as the take numbers.
    local takeNum = reaper.GetMediaItemTakeInfo_Value(activeTake, "IP_TAKENUMBER")
    local chunkOK, chunk = reaper.GetItemStateChunk(activeItem, "", false)
        if not chunkOK then 
            reaper.MB("Could not get the state chunk of the active item.", "ERROR", 0) 
            return false
        end
    local takeChunkStartPos = 1
    for t = 1, takeNum do
        takeChunkStartPos = chunk:find("\nTAKE[^\n]-\nNAME", takeChunkStartPos+1)
        if not takeChunkStartPos then 
            reaper.MB("Could not find the active take's part of the item state chunk.", "ERROR", 0) 
            return false
        end
    end
    local takeChunkEndPos = chunk:find("\nTAKE[^\n]-\nNAME", takeChunkStartPos+1)
    activeTakeChunk = chunk:sub(takeChunkStartPos, takeChunkEndPos)
    
    -- The MIDI editor scroll and zoom are hidden within the CFGEDITVIEW field 
    -- If the MIDI editor's timebase = project synced or project time, horizontal zoom is given as pixels per second.  If timebase is beats, pixels per tick
    local ME_HorzZoom
    ME_LeftmostTick, ME_HorzZoom, ME_TopPitch, ME_PixelsPerPitch = activeTakeChunk:match("\nCFGEDITVIEW (%S+) (%S+) (%S+) (%S+)")
    ME_LeftmostTick, ME_HorzZoom, ME_TopPitch, ME_PixelsPerPitch = tonumber(ME_LeftmostTick), tonumber(ME_HorzZoom), 127-tonumber(ME_TopPitch), tonumber(ME_PixelsPerPitch)
        if not (ME_LeftmostTick and ME_HorzZoom and ME_TopPitch and ME_PixelsPerPitch) then 
            reaper.MB("Could not determine the MIDI editor's zoom and scroll positions.", "ERROR", 0) 
            return(false) 
        end
    activeChannel, ME_TimeBase = activeTakeChunk:match("\nCFGEDIT %S+ %S+ %S+ %S+ %S+ %S+ %S+ %S+ (%S+) %S+ %S+ %S+ %S+ %S+ %S+ %S+ %S+ %S+ (%S+)")
    ME_TimeBase = (ME_TimeBase == "0" or ME_TimeBase == "4") and "beats" or "time"
    if ME_TimeBase == "beats" then
        ME_PixelsPerTick = ME_HorzZoom
    else
        ME_PixelsPerSecond = ME_HorzZoom
        ME_LeftmostTime    = reaper.MIDI_GetProjTimeFromPPQPos(activeTake, ME_LeftmostTick)
    end

    -- Now get the heights and types of all the CC lanes.
    -- !!!! WARNING: IF THE EDITOR DISPLAYS TWO LANE OF THE SAME TYPE/NUMBER, FOR EXAMPLE TWO MODWHEEL LANES, THE CHUNK WILL ONLY LIST ONE, AND THIS CODE WILL THEREFORE FAIL !!!!
    -- Chunk lists CC lane from top to bottom, so must first get each lane's height, from top to bottom, 
    --    then go in reverse direction, from bottom to top, calculating screen coordinates.
    -- Lane heights include lane divider (9 pixels high in MIDI editor, 8 in inline editor)
    local laneID = -1 -- lane = -1 is the notes area
    tME_Lanes[-1] = {Type = -1, inlineHeight = 100} -- inlineHeight is not accurate, but will simply be used to indicate that this "lane" is large enough to be visible.
    for vellaneStr in activeTakeChunk:gmatch("\nVELLANE [^\n]+") do 
        local laneType, ME_Height, inlineHeight = vellaneStr:match("VELLANE (%S+) (%d+) (%d+)")
        -- Lane number as used in the chunk differ from those returned by API functions such as MIDIEditor_GetSetting_int(editor, "last_clicked")
        laneType, ME_Height, inlineHeight = ConvertCCTypeChunkToAPI(tonumber(laneType)), tonumber(ME_Height), tonumber(inlineHeight)
        if not (laneType and ME_Height and inlineHeight) then
            reaper.MB("Could not parse the VELLANE fields in the item state chunk.", "ERROR", 0)
            return(false)
        end    
        laneID = laneID + 1   
        tME_Lanes[laneID] = {VELLANE = vellaneStr, Type = laneType, ME_Height = ME_Height, inlineHeight = inlineHeight}
    end
    
    -- If main editor (not inline) get pixel coordinates of editor structure
    if midiview then
        -- ClientRect places Y pixel 0 at *top*, and right/bottom are *outside* actual area.
        -- Also, exclude the ruler area on top (which is always 62 pixels high).
        -- Note that on MacOS and Linux, a window may be "flipped". I'm not sure what that means, so always check that width and height are non-negative.
        local clientOK, rectLeft, rectTop, rectRight, rectBottom = reaper.JS_Window_GetClientRect(midiview) --takeChunk:match("CFGEDIT %S+ %S+ %S+ %S+ %S+ %S+ %S+ %S+ %S+ %S+ %S+ %S+ (%S+) (%S+) (%S+) (%S+)") 
            if not clientOK then 
                reaper.MB("Could not determine the MIDI editor's client window pixel coordinates.", "ERROR", 0) 
                return(false) 
            end
        ME_midiviewWidth  = ((rectRight-rectLeft) >= 0) and (rectRight-rectLeft) or (rectLeft-rectRight)--ME_midiviewRightPixel - ME_midiviewLeftPixel + 1
        ME_midiviewHeight = ((rectTop-rectBottom) >= 0) and (rectTop-rectBottom) or (rectBottom-rectTop)--ME_midiviewBottomPixel - ME_midiviewTopPixel + 1
        
        local laneBottomPixel = ME_midiviewHeight-1
        for i = #tME_Lanes, 0, -1 do
            tME_Lanes[i].ME_BottomPixel = laneBottomPixel
            tME_Lanes[i].ME_TopPixel    = laneBottomPixel - tME_Lanes[i].ME_Height + 10
            
            laneBottomPixel = laneBottomPixel - tME_Lanes[i].ME_Height
        end
        
        -- Notes area height is remainder after deducting 1) total CC lane height and 2) height (62 pixels) of Ruler/Marker/Region area at top of midiview
        tME_Lanes[-1].ME_BottomPixel = laneBottomPixel
        tME_Lanes[-1].ME_TopPixel    = 62
        tME_Lanes[-1].ME_Height      = laneBottomPixel-61
        ME_BottomPitch = ME_TopPitch - math.floor(tME_Lanes[-1].ME_Height / ME_PixelsPerPitch)
    end
 
    -- Finally, get active channel info
    editAllChannels = activeTakeChunk:match("\nEVTFILTER (%S+) %S+ %S+ %S+ %S+ %S+ %S+ ")
    activeChannel   = tonumber(activeChannel)
    if not (activeChannel and editAllChannels) then
        reaper.MB("Could not determine the MIDI filter and active MIDI channel.", "ERROR", 0)
        return false
    else
        editAllChannels = (editAllChannels == "0")
        activeChannel = activeChannel - 1 
    end
    
    return true
    
end -- function SetupMIDIEditorInfoFromTakeChunk


--#########################################
-------------------------------------------
-- x and y are *client* coordinates
function GetCCLaneIDFromPoint(x, y)
    if isInline then
        -- return nil -- Not yet implemented in this version
    elseif midiview then
        if 0 <= x and x < ME_midiviewWidth then
            for i = -1, #tME_Lanes do
                if y < tME_Lanes[i].ME_TopPixel then
                    return i - 0.5
                elseif y <= tME_Lanes[i].ME_BottomPixel then
                    return i
                end
            end
            return #tME_Lanes + 0.5
        end
    end
end


--###################################################################
---------------------------------------------------------------------
-- Set this script as the armed command that will be called by the 
--    "js_Mouse editing - Run script that is armed in toolbar" script
function ArmToolbarButton()
    
    -- In this version of the Mouse editing scripts, the toolbar button is activated in the MAIN function,
    --    so no need to do it here too.
    -- Must notify the AtExit function that button should not be deactivated when exiting.
    --[[if not (sectionID and commandID) then
        _, _, sectionID, commandID = reaper.get_action_context()
        if sectionID == nil or commandID == nil or sectionID == -1 or commandID == -1 then
            return(false)
        end  
    end]]
    
    prevCommandIDs = reaper.GetExtState("js_Mouse actions", "Previous commandIDs") or ""
    
    for prevCommandID in prevCommandIDs:gmatch("%d+") do
        prevCommandID = tonumber(prevCommandID)
        if prevCommandID == commandID then
            alreadyGotOwnCommand = true
        else
            reaper.SetToggleCommandState(sectionID, prevCommandID, 0)
            reaper.RefreshToolbar2(sectionID, prevCommandID)
        end
    end
    if not alreadyGotOwnCommand then
        prevCommandIDs = prevCommandIDs .. tostring(commandID) .. "|"
        reaper.SetExtState("js_Mouse actions", "Previous commandIDs", prevCommandIDs, false)
    end
    
    reaper.SetExtState("js_Mouse actions", "Armed commandID", tostring(commandID), false)
    --reaper.SetToggleCommandState(sectionID, commandID, 1)
    --reaper.RefreshToolbar2(sectionID, commandID)
    
    Tooltip("Armed: Slice notes")

    leaveToolbarButtonArmed = true
    
end -- ArmToolbarButton()


--######################
------------------------
local tooltipTime = 0
local tooltipText = ""
function Tooltip(text)
    if text then -- New tooltip text
        tooltipTime = reaper.time_precise()
        tooltipText = text
        local x, y = reaper.GetMousePosition()
        reaper.TrackCtl_SetToolTip(tooltipText, x+10, y+10, true)
        reaper.defer(Tooltip)
    elseif reaper.time_precise() < tooltipTime+0.5 then
        local x, y = reaper.GetMousePosition()
        reaper.TrackCtl_SetToolTip(tooltipText, x+10, y+10, true)
        reaper.defer(Tooltip)
    else
        reaper.TrackCtl_SetToolTip("", 0, 0, false)
        return
    end
end


--#####################################################################################################
-------------------------------------------------------------------------------------------------------
-- Here execution starts!
function MAIN()

    startTime = reaper.time_precise()
    
    -- Before doing anything that may terminate the script, use this trick to avoid automatically 
    --    creating undo states if nothing actually happened.
    -- Undo_OnStateChange will only be used if reaper.atexit(exit) has been executed
    reaper.defer(function() end)  
    

    -- Check whether SWS and my own extension are available, as well as the required version of REAPER
    if not reaper.JS_Window_FindEx then -- FindEx was added in v0.963
        reaper.MB("This script requires an up-to-date version of the js_ReaScriptAPI extension."
               .. "\n\nThe js_ReaScripAPI extension can be installed via ReaPack, or can be downloaded manually."
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
    -- The js_ReaScriptAPI extension already requires REAPER v5.95 or higher, so don't need to check.
    -- Older versions of SWS had bugs in BR_GetMouseCursorContext
    elseif not reaper.SN_FocusMIDIEditor then 
        reaper.MB("This script requires an up-to-date versions of the SWS/S&M extension."
               .. "\n\nThe SWS/S&M extension can be downloaded from www.sws-extension.org."
                , "ERROR", 0)
        return(false) 
    end 
    

    -- ATEXIT BECOMES RELEVANT
    -- If anyting goes wrong during main(), a dialog box will pop up, so Exit() will try to return focus to original windows,
    -- This can only be done if the ReaScriptAPI extension is installed.
    reaper.atexit(AtExit)
    
    
    -- GET MOUSE STARTING STATE:
    -- as soon as possible.  Hopefully, if script is started with mouse click, mouse button will still be down.
    mouseOrigX, mouseOrigY = reaper.GetMousePosition()
    prevMouseTime = startTime + 0.5 -- In case mousewheel sends multiple messages, don't react to messages sent too closely spaced, so wait till little beyond startTime.
    mouseState = reaper.JS_Mouse_GetState(0xFF)    
    
    
    -- CONFLICTING SCRIPTS:
    -- Check whether other js_Mouse editing scripts are running
    if reaper.HasExtState("js_Mouse actions", "Status") then
        return false
    else
        reaper.SetExtState("js_Mouse actions", "Status", "Running", false)
    end 
    
    
    -- MOUSE CURSOR AND TOOLBAR BUTTON:
    -- To give an impression of quick responsiveness, the script must change the cursor and toolbar button as soon as possible.
    -- (Later, the script will block "WM_SETCURSOR" to prevent REAPER from changing the cursor back after each defer cycle.)
    _, filename, sectionID, commandID = reaper.get_action_context()
    filename = filename:gsub("\\", "/") -- Change Windows format to cross-platform
    filename = filename:match("^.*/") or "" -- Remove script filename, keeping directory
    filename = filename .. "js_Mouse editing - Slice notes.cur"
    cursor = reaper.JS_Mouse_LoadCursorFromFile(filename) -- The first time that the cursor is loaded in the session will be slow, but afterwards the extension will re-use previously loaded cursor
    if not cursor then cursor = reaper.JS_Mouse_LoadCursor(433) end -- If .cur file unavailable, load one of REAPER's own cursors]]
    if cursor then reaper.JS_Mouse_SetCursor(cursor) end    
    
    if sectionID ~= nil and commandID ~= nil and sectionID ~= -1 and commandID ~= -1 then
        origToggleState = reaper.GetToggleCommandStateEx(sectionID, commandID)
        reaper.SetToggleCommandState(sectionID, commandID, 1)
        reaper.RefreshToolbar2(sectionID, commandID)
    end                 
    
    
    -- GET MIDI EDITOR UNDER MOUSE:
    -- Unfortunately, REAPER's windows don't have the same titles or classes on all three platforms, so must use roundabout way
    -- If platform is Windows, the piano roll area is title "midiview", but not in Linux, and I'm not sure about MacOS.
    -- SWS uses Z order to find the midiview. In ReaScriptAPI, the equivalent would be JS_Window_GetRelated(parent, "CHILD"), "NEXT").
    -- But this is also not always reliable!  
    -- It seems to me that Window ID seems to me more cross-platform reliable than title or Z order.
    windowUnderMouse = reaper.JS_Window_FromPoint(mouseOrigX, mouseOrigY)
    if windowUnderMouse then
 
        parentWindow = reaper.JS_Window_GetParent(windowUnderMouse)
        if parentWindow then

            -- Is the mouse over the piano roll of a MIDI editor?
            
            -- MIDI EDITOR:
            if reaper.MIDIEditor_GetMode(parentWindow) == 0 then -- got a window in a MIDI editor
                isInline = false
                editor = parentWindow
                if windowUnderMouse == reaper.JS_Window_FindChildByID(parentWindow, 1001) then -- The piano roll child window, titled "midiview" in Windows.
                    midiview = windowUnderMouse
                    mouseOrigX, mouseOrigY = reaper.JS_Window_ScreenToClient(midiview, mouseOrigX, mouseOrigY) -- Always use client coordinates in MIDI editor                                    
                    
                    activeTake = reaper.MIDIEditor_GetTake(editor)
                    activeTakeOK = activeTake and reaper.ValidatePtr2(0, activeTake, "MediaItem_Take*") and reaper.TakeIsMIDI(activeTake)
                    if activeTakeOK then
                    
                        activeItem = reaper.GetMediaItemTake_Item(activeTake)
                        activeItemOK = activeItem and reaper.ValidatePtr(activeItem, "MediaItem*") 
                        if activeItemOK then 
                        
                            chunkStuffOK = SetupMIDIEditorInfoFromTakeChunk() -- Get MIDI editor structure from chunk, and store in tME_Lanes table.
                            if chunkStuffOK then
                                
                                mouseOrigCCLaneID = GetCCLaneIDFromPoint(mouseOrigX, mouseOrigY)                                 
                                if mouseOrigCCLaneID then
                                    
                                    targetLaneOK, mouseOrigCCLane = SetupTargetLaneForParsing(mouseOrigCCLaneID) 
                                    if targetLaneOK then
                                    
                                        -- Calculate these variables here, since the BR_ function will get this for inline editor
                                        if (mouseOrigCCLaneID == -1) and laneIsPIANOROLL and ME_TopPitch and ME_PixelsPerPitch then
                                            mouseOrigPitch = ME_TopPitch - math.ceil((mouseOrigY - tME_Lanes[-1].ME_TopPixel) / ME_PixelsPerPitch)
                                            mouseOrigCCValue = -1
                                        elseif (mouseOrigCCLaneID%1 == 0) and laneMinValue and laneMaxValue then
                                            mouseOrigPitch = -1                                        
                                            mouseOrigCCValue = laneMinValue + (laneMaxValue-laneMinValue) * (mouseOrigY - tME_Lanes[mouseOrigCCLaneID].ME_BottomPixel) / (tME_Lanes[mouseOrigCCLaneID].ME_TopPixel - tME_Lanes[mouseOrigCCLaneID].ME_BottomPixel)
                                        end
                                        
                                        gotEverythingOK  = true
                end end end end end end

            -- INLINE EDITOR:
            -- Is the mouse over the arrange view?  And over an inline editor?
            -- The inline editor is much faster than the main MIDI editor, so can use the relatively SWS functions in each cycle, without causing noticable delay.
            --    (Also, it is much more complicated to calculate mouse context for the arrange view and inline editor, so I don't want to do it in this script.)
            elseif parentWindow == reaper.GetMainHwnd() then
            
                -- Get MIDI editor and CC lane.  This script works in a single lane, so if on divider, must wait until mouse enters a CC lane
                --::loopUntilMouseEntersCCLane::
                window, segment, details = reaper.BR_GetMouseCursorContext()  
                editor, isInline, mouseOrigPitch, mouseOrigCCLane, mouseOrigCCValue, mouseOrigCCLaneID = reaper.BR_GetMouseCursorContext_MIDI() 
                --if details == "cc_lane" and mouseOrigCCValue == -1 then mouseStartedOnLaneDivider = true; goto loopUntilMouseEntersCCLane end
                
                if isInline and segment == "notes" then
                    
                    editor = nil
                    activeTake = reaper.BR_GetMouseCursorContext_Take()
                    activeTakeOK = activeTake and reaper.ValidatePtr2(0, activeTake, "MediaItem_Take*") and reaper.TakeIsMIDI(activeTake) 
                    if activeTakeOK then
                    
                        activeItem = reaper.GetMediaItemTake_Item(activeTake)
                        activeItemOK = activeItem and reaper.ValidatePtr(activeItem, "MediaItem*") 
                        if activeItemOK then 
                        
                            -- In the case of the inline editor, BR functions will be use dto track the mouse, 
                            --    but the take chunk info is still necessary to get all visible lanes, and the active MIDI channel
                            chunkStuffOK = SetupMIDIEditorInfoFromTakeChunk() 
                            if chunkStuffOK then
                                
                                targetLaneOK, mouseOrigCCLane = SetupTargetLaneForParsing(mouseOrigCCLaneID)
                                if targetLaneOK then
                                    
                                    gotEverythingOK = true
    end end end end end end end end
   
    -- To keep things neater, all these error messages are here together
    if not gotEverythingOK then
        if not windowUnderMouse then
            reaper.MB("Could not determine the window under the mouse.", "ERROR", 0)
        elseif not parentWindow then
            reaper.MB("Could not determine the parent window of the window under the mouse.", "ERROR", 0)
        elseif (not isInline and not midiview) then
            ArmToolbarButton()
        elseif (isInline and not (segment == "notes")) or (midiview and not (mouseOrigCCLaneID == -1)) then
            reaper.MB("The mouse should be positioned over the notes area of the piano roll", "ERROR", 0)
        elseif not activeTakeOK then
            reaper.MB("Could not determine a valid MIDI take in the editor under the mouse.", "ERROR", 0)
        elseif not activeItemOK then
            reaper.MB("Could not determine the media item to which the MIDI editor's active take belong.", "ERROR", 0)
        elseif not chunkStuffOK then
            -- The chuck functions give their own detailed error messages if something goes awry.
        elseif not targetLaneOK then
            --reaper.MB("One or more of the CC lanes are of unknown type, and could not be parsed by this script.", "ERROR", 0)
        end
        return false
    end   
    if not laneIsPIANOROLL then
        reaper.MB("The mouse should be positioned over the notes area of the piano roll", "ERROR", 0)
        return false
    end
    
    
    -- UNIQUE TO THIS SCRIPT:
    if midiview then
        -- MIDI note names are unattractive when drawing line, so disable temporarily
        displayNoteNames = reaper.GetToggleCommandStateEx(sectionID, 40045)
        if displayNoteNames == 1 then reaper.MIDIEditor_OnCommand(editor, 40045) end
        -- In case of beats, constant ratio pixels:ticks, so can calculate nice ticknessTicks here. Otherwise, will try to find average pixels:ticks each cycle.
        if ME_TimeBase == "beats" and ME_PixelsPerTick then
            thicknessTicks = 2*math.ceil(2/ME_PixelsPerTick)
        end
    end
    --[[if isInline or ME_TimeBase == "time" then
        mousePrevPitch = mouseOrigPitch
        mouseLeftmostPPQPos = mouseOrigPPQPos
        mouseRightmostPPQPos = mouseOrigPPQPos
        mouseLeftmostPixel = mouseOrigX
        mouseRightmostPixel = mouseOrigX
    end]]
    
    
    -- MOUSE STARTING PPQ VALUES:
    -- Get mouse starting PPQ position -- AND ADJUST FOR LOOPING AND SNAPPING
    if isInline then
        mouseOrigTime   = reaper.BR_GetMouseCursorContext_Position()
        mouseOrigPPQPos = reaper.MIDI_GetPPQPosFromProjTime(activeTake, mouseOrigTime)
    elseif ME_TimeBase == "beats" then
        mouseOrigPPQPos = ME_LeftmostTick + mouseOrigX/ME_PixelsPerTick
    else -- ME_TimeBase == "time"
        mouseOrigTime   = ME_LeftmostTime + mouseOrigX/ME_PixelsPerSecond
        mouseOrigPPQPos = reaper.MIDI_GetPPQPosFromProjTime(activeTake, mouseOrigTime)
    end
    
    -- In case the item is looped, adjust the mouse PPQ position to equivalent position in first iteration.
    --    * mouseOrigPPQPos will be contracted to (possibly looped) item visible boundaries
    --    * Then get tick position relative to start of loop iteration under mouse
    local itemStartTimePos = reaper.GetMediaItemInfo_Value(activeItem, "D_POSITION")
    local itemEndTimePos = itemStartTimePos + reaper.GetMediaItemInfo_Value(activeItem, "D_LENGTH")
    local itemFirstVisibleTick = math.ceil(reaper.MIDI_GetPPQPosFromProjTime(activeTake, itemStartTimePos)) 
    local itemLastVisibleTick = math.floor(reaper.MIDI_GetPPQPosFromProjTime(activeTake, itemEndTimePos))
    mouseOrigPPQPos = math.max(itemFirstVisibleTick, math.min(itemLastVisibleTick-1, mouseOrigPPQPos)) 
    -- Now get PPQ position relative to loop iteration under mouse
    -- Source length will be used in other context too: When script terminates, check that no inadvertent shifts in PPQ position occurred.
    if not sourceLengthTicks then sourceLengthTicks = reaper.BR_GetMidiSourceLenPPQ(activeTake) end
    loopStartPPQPos = (mouseOrigPPQPos // sourceLengthTicks) * sourceLengthTicks
    mouseOrigPPQPos = mouseOrigPPQPos - loopStartPPQPos      

    -- If snapping is enabled, the PPQ position must be adjusted to nearest grid.
    -- If snapping is not enabled, snappedOrigPPQPos = mouseOrigPPQPos, snapped to nearest tick
    -- NB: The rest of the function will work with snappedOrigPPQPos.
    if isInline then
        isSnapEnabled = (reaper.GetToggleCommandStateEx(0, 1157) == 1)
        -- Even is snapping is disabled, need PPperGrid and QNperGrid for LFO length
        local _, gridDividedByFour = reaper.GetSetProjectGrid(0, false) -- Arrange grid and MIDI grid are returned in different units
        QNperGrid = gridDividedByFour*4
    else
        isSnapEnabled = (reaper.MIDIEditor_GetSetting_int(editor, "snap_enabled") == 1)
        QNperGrid, _, _ = reaper.MIDI_GetGrid(activeTake) -- Quarter notes per grid
    end
    --PPQ = reaper.MIDI_GetPPQPosFromProjQN(activeTake, 1 + reaper.MIDI_GetProjQNFromPPQPos(activeTake, 0))
    --PPerGrid = PPQ*QNperGrid
    
    minimumTick = math.max(0, itemFirstVisibleTick) + thicknessTicks
    maximumTick = math.min(itemLastVisibleTick, sourceLengthTicks-1) - thicknessTicks -- I prefer not to draw any event on the same PPQ position as the All-Notes-Off
    mouseOrigPPQPos = math.max(minimumTick, math.min(maximumTick, mouseOrigPPQPos))
    
    --[[
    if isSnapEnabled == false then
        snappedOrigPPQPos = math.floor(mouseOrigPPQPos+0.5)
    elseif isInline then
        local timePos = reaper.MIDI_GetProjTimeFromPPQPos(activeTake, mouseOrigPPQPos)
        local snappedTimePos = reaper.SnapToGrid(0, timePos) -- If snap-to-grid is not enabled, will return timePos unchanged
        snappedOrigPPQPos = math.floor(reaper.MIDI_GetPPQPosFromProjTime(activeTake, snappedTimePos) + 0.5)
    else
        local mouseQNpos = reaper.MIDI_GetProjQNFromPPQPos(activeTake, mouseOrigPPQPos) -- Mouse position in quarter notes
        local roundedGridQN = math.floor((mouseQNpos/QNperGrid)+0.5)*QNperGrid -- Grid nearest to mouse position
        snappedOrigPPQPos = math.floor(reaper.MIDI_GetPPQPosFromProjQN(activeTake, roundedGridQN) + 0.5)
    end ]]
    

    -- GET AND PARSE MIDI:
    -- Time to process the MIDI of the take!
    -- As mentioned in the header, this script does not use the old-fashioned MIDI API functions such as 
    --    MIDI_InsertCC, since these functions are far too slow when dealing with thousands of events.
    getAllEvtsOK, MIDIString = reaper.MIDI_GetAllEvts(activeTake, "")
        if not getAllEvtsOK then reaper.MB("MIDI_GetAllEvts could not load the raw MIDI data.", "ERROR", 0) return false end
    -- This script does not require parsing before looping
        
    
    -- INTERCEPT WINDOW MESSAGES:
    -- Do the magic that will allow the script to track mouse button and mousewheel events!
    -- The code assumes that all the message types will be blocked.  (Scripts that pass some messages through, must use other code.)
    -- tWM_Messages entries that are currently being intercepted but passed through, will temporarily be blocked and then restored when the script terminates.
    -- tWM_Messages entries that are already being intercepted and blocked, do not need to be changed or restored, so will be deleted from the table.
    pcallInterceptOK, pcallInterceptRetval = pcall( 
        function()
            for message in pairs(tWM_Messages) do            
                local interceptOK = reaper.JS_WindowMessage_Intercept(windowUnderMouse, message, false)
                -- Is message type already being intercepted by another script?
                if interceptOK == 0 then 
                    local prevIntercepted, prevPassthrough = reaper.JS_WindowMessage_Peek(windowUnderMouse, message)
                    if prevIntercepted then
                        if prevPassthrough == false then
                            interceptOK = 1 
                            tWM_Messages[message] = nil -- No need to change or restore this message type
                        else
                            interceptOK = reaper.JS_WindowMessage_PassThrough(windowUnderMouse, message, false)
                            tWM_Messages[message] = true
                        end
                    end
                end
                -- Intercept OK?
                if interceptOK ~= 1 then 
                    return false
                end
            end
            return true
        end)
    if not (pcallInterceptOK and pcallInterceptRetval) then 
        reaper.JS_WindowMessage_ReleaseWindow(windowUnderMouse) 
        tWM_Messages = {}
        reaper.MB("Intercepting window messages failed.\n\nAll intercepts for the window under the mouse will be released. (This may affect other scripts that are currently monitoring this window.)", "ERROR", 0) 
        return false 
    end      
    
    
    -- Start the loop!
    DEFERLOOP_pcall()
    
end -- function MAIN()


--################################################
--------------------------------------------------
MAIN()


