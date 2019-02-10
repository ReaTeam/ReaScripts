--[[
ReaScript name: js_Mouse editing - 2-sided Warp.lua
Version: 4.00
Author: juliansader
Website: http://forum.cockos.com/showthread.php?t=176878
Donation: https://www.paypal.me/juliansader
Provides: [main=midi_editor,midi_inlineeditor] .
About:
  # DESCRIPTION
  
  A Lua script for warping and stretching the positions of MIDI CCs and notes.
  
  The script only affects events in the MIDI editor lane under the mouse cursor.
  
  * Useful for changing a linear CC ramp into more complex logistic-type curves.
  * Useful for accelerating and decelerating a series of evenly spaced notes, as is typical in a trill.


  # INSTRUCTIONS
  
  1) Select MIDI events to be warped (the script works on any CCs, notes, text or sysex events).
  2) Position mouse in lane, *within* the time range of the selected events. (Events to left and right of mouse position will be stretch separately.)
  3) Press the shortcut key. (Do not press any mouse button.)
  4) Move mouse left or right to stretch the corresponding side, or move mouse up or down to warp towards or away from mouse.
  5) To stop the script, move the mouse out of the CC lane, or press the shortcut key again.   


  MOUSEWHEEL AND KEYBAORD CONTROL
   
  The "js_Mouse editing" scripts can be controlled by the mouse and keyboard while the script is running:
      * Mouse movement:     Changes the extent of warping
      * Mouse left click:   Terminates the script.
      * Mouse middle click: -- (not used by this script)
      * Mouse right click:  -- (not used by this script)
      * Mousewheel:         -- (not used by this script)
      * Keyboard shortcut (assigned in Actions list):  Starts/Terminates the script.
      * Any keyboard modifier key:  Terminates the script.
  
  
  MOUSE EDITING SCRIPTS vs REAPER's LEFT-DRAG MOUSE MODIFIER ACTIONS
  
  The "js_Mouse editing" scripts resemble REAPER's own left-drag mouse modifier actions 
  (such as "Draw CCs", "Arpeggiate", "Paint notes", etc), in that the scripts follow mouse movement 
  and continue to run until the user stops the script.
  
  However, the scripts are more advanced than the native actions:
      
      * The scripts' functioning (such as the ramp shape or the channel of inserted CCs) can be tweaked while the script is running, 
      using the mousewheel, mouse middle button and right button.
      
      * Whereas native actions can only be started and stopped by left-dragging and lifting the mouse button,
      the scripts be started and stopped in multiple ways, allowing a more customized and streamlined workflow.
  
  Starting a script:
  
      * Similar to any action in the Actions list, the script can be assigned a keyboard or mousewheel shortcut.
        (NOTE: To run the script, press the shortcut key *once* and do not hold the key.) 
        
      * Similar to mouse modifier actions, assign the script to a left-click or double-click mouse modifier in Preferences -> Mouse modifiers.  
        (NOTE: In current versions of REAPER, actions can not be assigned to left-drag mouse modifiers, 
               but the script will automatically detect a left-drag movement. To use left-drag, assign the script to a *double*-click mouse modifier.)
               
      * Arming a toolbar button, as described below.
  
  Stopping a script:
  
      * Mouse: Left clicking
  
      * Mouse: Left-dragging and lifting the left button.
  
      * Keyboard: Pressing any mouse modifier key (Ctrl/Cmnd, Alt, Shift or Win).
  
      * Keyboard: If a shortcut has been assigned to the script, that same shortcut will toggle the script on/off.
        (NOTE: The first time that the script is stopped by its shortcut, REAPER will pop up a dialog box 
               asking whether to terminate or restart the script.  Select "Terminate" and "Remember my answer for this script".)  
          
  
  RUNNING THE SCRIPT FROM THE TOOLBAR:
  
  Since the functioning of the script depends on initial mouse position (similar to some of REAPER's own mouse modifier actions, 
     or actions such as "Insert note at mouse cursor"), the script cannot be run from a toolbar button.  
     This problem is solved by "arming" toolbar buttons for delayed execution after moving the mouse into position:
     
     
     REAPER's NATIVE TOOLBAR ARMING:
     
     REAPER natively provides a toolbar arming feature: right-click a toolbar button to arm its linked action
     (the button will light up with an alternative color), and then left-click to run the action 
     after moving the mouse into position over the piano roll.
     
     There are two niggles with this feature, though: 
     
     1) Left-drag is very sensitive: If the mouse is even slightly moved while left-clicking,
         the left-drag mouse modifier action will be run instead of the armed toolbar action; 
  
     2) Multiple clicks: The user has to right-click the toolbar (or press Esc) to disarm the toolbar and use left-click normally again,
         then right-click the toolbar again to use the script. 
         
         
     ALTERNATIVE TOOLBAR ARMING:
     
     The mouse editing scripts therefore offer an alternative "toolbar arming" solution:  
     
     1) Link the "js_Mouse editing - Run script that is armed in toolbar" script to a keyboard or mousewheel shortcut.
     
     2) Link the individual Mouse editing scripts (such as "Draw ramp", "Warp", etc) to toolbar buttons. (No need to link them each to a shortcut.)
         
       (I.e. the Run script is linked to a shortcut, while the individual Mouse editing scripts are linked to toolbar buttons.)
     
     3) If the mouse is positioned over a toolbar or over the Actions list when the Mouse editing script starts 
         (or, actually, anywhere else outside the MIDI piano roll and CC lanes), the script will arm itself 
         and its button will light up with the normal "activated" color.
     
     4) When the "Run" script is executed with its shortcut, it will run the armed Mouse editing script.
     
     By using this feature, each "Mouse editing" script does need not be linked to its own shortcut key.  Instead, only the 
       accompanying "Run" script needs to be linked to a shortcut.
    
    
  PERFORMANCE TIP 1: The responsiveness of the MIDI editor is significantly influenced by the total number of events in 
      the visible and edit takes.  If the MIDI editor is slow, try reducing the number of edit and visible tracks.
      
  PERFORMANCE TIP 2: If the MIDI editor gets slow and jerky when a certain VST plugin is loaded, 
      check for graphics driver incompatibility by disabling graphics acceleration in the plugin.
]] 

--[[
  Changelog:
  * v4.00 (2019-01-19)
    + Updated for ReaScriptAPI extension.
]] 


-- ################################################################################################
---------------------------------------------------------------------------------------------------
-- CONSTANTS AND VARIABLES (that modders may find useful)

local MIDIString -- The original raw MIDI data returned by GetAllEvts
local remainMIDIString -- The MIDI that remained after extracting selected events in the target lane
local tEditedMIDI = {} -- Each edited event will be stored in this table, ready to be concatenated

-- When the info of the targeted events is extracted, the info will be stored in several tables.
-- The order of events in the tables will reflect the order of events in the original MIDI, except note-offs, 
--    which will be replaced by note lengths, and notation text events, which will also be stored in a separate table
--    at the same indices as the corresponding notes.
local tMsg = {}
--local tMsgLSB = {}
--local tMsgNoteOffs = {}
--local tValues = {} -- CC values, 14bit CC combined values, note velocities
local tPPQs = {}
--local tChannels = {}
local tFlags = {}
--local tFlagsLSB = {} -- In the case of 14bit CCs, mute/select status of the MSB
--local tPitches = {} -- This table will only be filled if laneIsVELOCITY or laneIsPIANOROLL
--local tNoteLengths = {}
--local tNotation = {} -- Will only contain entries at those indices where the notes have notation

-- Starting values and position of mouse 
-- Not all of these lanes will be used by all scripts.
-- mouseOrigCCLane: (CC0-127 = 7-bit CC, 0x100|(0-31) = 14-bit CC, 0x200 = velocity, 0x201 = pitch, 
--    0x202=program, 0x203=channel pressure, 0x204=bank/program select, 
--    0x205=text, 0x206=sysex, 0x207=off velocity)
local laneMinValue, laneMaxValue = nil, nil -- The minimum and maximum values in the target lane
local mouseOrigCCLane, mouseOrigCCValue, mouseOrigPPQPos, mouseOrigPitch, mouseOrigCCLaneID = nil, nil, nil, nil, nil
local snappedOrigPPQPos = nil -- If snap-to-grid is enabled, these will give the closest grid PPQ to the left. (Swing is not implemented.)

-- The original value and PPQ ranges of selected events in the target lane will be summarized in:
local origValueMin, origValueMax, origValueRange, origValueLeftmost, origValueRightmost = nil, nil, nil, nil, nil
local origPPQLeftmost, origPPQRightmost, origPPQRange = nil, nil, nil
local includeNoteOffsInPPQrange = true
--local includeNoteOffsInPPQrange = false -- ***** Should origPPQRange and origPPQRightmost take note-offs into account? Set this flag to true for scripts that stretch or warp note lengths. *****
 
-- This script can work in inline MIDI editors as well as the main MIDI editors
-- The two types of editors require some different code, though.  
-- In particular, if in an inline editor, functions from the SWS extension will be used to track mouse position.
-- In the main editor, WIN32/SWELL functions from the js_ReaScriptAPI extension will be used.
local isInline, editor = nil, nil

-- Tracking the new value and position of the mouse while the script is running
local mouseX, mouseY
local mouseNewCCLane, mouseNewCCValue, mouseNewPPQPos, mouseNewPitch, mouseNewCCLaneID = nil, nil, nil, nil, nil
local snappedNewPPQPos 

-- The script can be controlled by mousewheel, mouse buttons an mouse modifiers.  These are tracked by the following variables.
local mouseState
local mousewheel = 1 -- Track mousewheel movement.  ***** This default value may change, depending on the script and formulae used. *****
local prevMouseTime = 0

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
local firstCCinTakePPQPos -- CC spacing should not be calculated from PPQPos = 0, since take may not start on grid.
local firstGridInsideTakePPQPos -- If snap to grid, don't snap to left of this edge

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
local startTime = 0
local lastPPQPos -- to calculate offset to next CC
local lastValue -- To compare against last value, if skipRedundantCCs

-- If the mouse is over a MIDI editor, these variables will store the on-screen layout of the editor.
-- NOTE: Getting the MIDI editor scroll and zoom values is slow, since the item chunk has to be parsed.
--    This script will therefore not update these variables after getting them once.  The user should not scroll and zoom while the script is running.
local activeTakeChunk
local ME_l, ME_t, ME_r, ME_b -- screen coordinates of MIDI editor, with frame
local ME_LeftmostTick, ME_PixelsPerTick, ME_PixelsPerSecond = nil, nil, nil -- horizontal scroll and zoom
local ME_TopPitch, ME_PixelsPerPitch = nil, nil -- vertical scroll and zoom
local ME_CCLaneTopPixel, ME_CCLaneBottomPixel = nil, nil
local ME_midiviewLeftPixel, ME_midiviewTopPixel, ME_midiviewRightPixel, ME_midiviewBottomPixel = nil, nil, nil, nil
local ME_TargetTopPixel, ME_TargetBottomPixel
local ME_TimeBase
local tME_Lanes = {} -- store the layout of each MIDI editor lane
--local tVisibleCC7Bit = {} -- CC lanes to use.  (In case of a 14bit CC lane or Bank/Program, this table will contain two entries. If all visible lanes are used, may contain even more entries.)

-- I am not sure that declaring functions local really helps to speed things up...
local s_unpack = string.unpack
local s_pack   = string.pack
local t_insert = table.insert -- myTable[i] = X is actually much faster than t_insert(myTable, X)
local m_floor  = math.floor
local m_cos = math.cos
local m_min = math.min
local m_max = math.max 
local m_pi  = math.pi
local m_log = math.log

-- User preferences that can be customized via toggle scripts
--local clearNonActiveTakes  = true

-- Window messages that will be intercepted while the script is running
local tWM_Messages = {WM_LBUTTONDOWN = false, WM_LBUTTONDBLCLK = false, WM_LBUTTONUP = false,
                      WM_MBUTTONDOWN = false, WM_MBUTTONDBLCLK = false, WM_MBUTTONUP = false,
                      WM_RBUTTONDOWN = false, WM_RBUTTONDBLCLK = false, WM_RBUTTONUP = false,
                      WM_NCMOUSEMOVE = false, -- I'm not sure... Does this prevent REAPER from changing the mouse cursor when it's over scrollbars?
                      WM_MOUSEWHEEL  = false, WM_MOUSEHWHEEL   = false,
                      WM_SETCURSOR   = false}                 
  
-- Unique to this script:
-- This script warps the left and right parts of the targeted events separately
local PPQrangeL, PPQrangeR -- relative to original mouse position

  
--#############################################################################################
-----------------------------------------------------------------------------------------------
-- The function that will be 'deferred' to run continuously
-- There are three bottlenecks that impede the speed of this function:
--    Minor: reaper.BR_GetMouseCursorContext(), which must unfortunately unavoidably be called before 
--           reaper.BR_GetMouseCursorContext_MIDI(), and which (surprisingly) gets much slower as the 
--           number of MIDI events in the take increases.
--           ** This script will therefore try to avoid the BR_ functions and determine MIDI editor structure itself **
--    Minor: MIDI_SetAllEvts (when filled with hundreds of thousands of events) is not fast - but is 
--           infinitely better than the standard API functions such as MIDI_SetCC.
--    Major: Updating the MIDI editor between defer cycles is by far the slowest part of the whole process.
--           The more events in visible and edit takes, the slower the updating.  MIDI_SetAllEvts
--           seems to get slowed down more than REAPER's native Actions such as Invert Selection.
--           If, in the future, the REAPER API provides a way to toggle take visibility in the editor,
--           it may be helpful to temporarily make all non-active takes invisible. 
-- The Lua script parts of this function - even if it calculates thousands of events per cycle,
--    make up only a small fraction of the execution time.
local function DEFERLOOP_TrackMouseAndUpdateMIDI()
    
    -- Must the script terminate?
    -- There are several ways to terminate the script:  Any mouse button, mousewheel movement or modifier key will terminate the script;
    --   except unmodified middle button and unmodified mousewheel, which toggles or scrolls through options, respectively.
    -- This gives the user flexibility to control the script via keyboard or mouse, as desired.
    
    -- Must the script go through the entire function to calculate new MIDI stuff?
    -- MIDI stuff might be changed if the mouse has moved, mousebutton has been clicked, or mousewheel has scrolled, so need to re-calculate.
    -- Otherwise, mustCalculate remains nil, and can skip to end of function.
    local mustCalculate = false
    
    -- EXTSTATE: Other scripts can communicate with and control the other js_ scripts via ExtStates
    local extState = reaper.GetExtState("js_Mouse actions", "Status") or ""
    if extState == "" or extState == "Must quit" then return(false) end
    
    -- MOUSE MOVEMENT:
    mouseX, mouseY = reaper.GetMousePosition()
    if mouseX ~= prevMouseX or mouseY ~= prevMouseY then
        prevMouseX, prevMouseY = mouseX, mouseY
        mustCalculate = true
    end
    
    -- MOUSE POSITION: (New versions of the script doesn't quit if mouse moves out of CC lane, but will still quit if moves out of original window.)
    if isInline then
        window = reaper.BR_GetMouseCursorContext()
        if not (window == "midi_editor" or window == "arrange") then --reaper.JS_Window_FromPoint(mouseX, mouseY) ~= windowUnderMouse then -- BR_ functions can calculate PPQ even if mouse is outside inline editor
            return false 
        end
    else 
        -- MIDI editor closed or moved?
        local rOK, l, t, r, b = reaper.JS_Window_GetRect(editor) -- Faster than Window_From Point. Use Rect instead of ClientRect so that mouse can go onto scrollbar
        if not (rOK and l==ME_l and t==ME_t and r==ME_r and b==ME_b) then
            return false
        end
        -- Mouse can't go outside MIDI editor, unless left-dragging (to ensure that user remembers that script is running)
        if mouseState&1 == 0 and (mouseX < l or mouseY < t or mouseX >= r or mouseY >= b) then
            return false
        end
        if (mouseX < ME_midiviewLeftPixel or mouseY > ME_midiviewTopPixel or mouseX > ME_midiviewRightPixel or mouseY > ME_midiviewBottomPixel) and cursor then
            reaper.JS_Mouse_SetCursor(cursor)
        end
    end  
    
    -- MOUSE MODIFIERS / LEFT CLICK: (If the left mouse button or any modifier key is pressed, after first releasing them, quit.)
    -- This can detect left clicks even if the mouse is outside the MIDI editor
    local prevMouseState = mouseState or 0xFF
    mouseState = reaper.JS_Mouse_GetState(0xFF)
    if (mouseState&61) > (prevMouseState&61) then -- 61 = 0b00111101 = Ctrl | Shift | Alt | Win | Left button
        return false
    end
 
    -- LEFT DRAG: (If the left button was kept pressed for 1 second or longer, or after moving the mouse 20 pixels, assume left-drag, so quit when lifting.)
    local peekOK, pass, time = reaper.JS_WindowMessage_Peek(windowUnderMouse, "WM_LBUTTONUP")
    if peekOK and (time > startTime + 1.5) 
              --or  (time > startTime and (mouseX < mouseOrigX - 20 or mouseX > mouseOrigX + 20 or mouseY < mouseOrigY - 20 or mouseY > mouseOrigY + 20))) 
              then
        return false
    end
    
    -- LEFT CLICK: (If the left mouse button or any modifier key is pressed, after first releasing them, quit.)
    peekOK, pass, time = reaper.JS_WindowMessage_Peek(windowUnderMouse, "WM_LBUTTONDOWN")
    if peekOK and time > startTime then return false end
            
    
    -- CALCULATE MIDI STUFF!
    
    -- Scripts that extract selected MIDI events and re-concatenate them out of order (usually at the beginning of the MIDI string, for easier editing)
    --    cannot be auditioned in real-time while events are out of order, since such events are not played.
    -- If the mouse is held still, no editing is done, and instead the take is sorted, thereby temporarily allowing playback.
    -- NO NEED TO CALCULATE:
    if not mustCalculate then --and not takeIsSorted then
        if not takeIsSorted then
            reaper.MIDI_Sort(activeTake)
            takeIsSorted = true
        end
          
    -- MUST CALCULATE:
    else        
        takeIsSorted = false
        
        -- MOUSE NEW CC VALUE (vertical position)
        if isInline then
            -- reaper.BR_GetMouseCursorContext was already called above
            _, _, mouseNewPitch, mouseNewCCLane, mouseNewCCValue, mouseNewCCLaneID = reaper.BR_GetMouseCursorContext_MIDI()
            -- Convert BR function's laneID return value to same as this script's GetCCLaneIDFromPoint
            if details == "cc_lane" and mouseNewCCValue == -1 then mouseNewCCLaneID = mouseNewCCLaneID - 0.5 end  
            if mouseNewCCLaneID > mouseOrigCCLaneID then
                mouseNewCCValue = laneMinValue
            elseif mouseNewCCLaneID < mouseOrigCCLaneID or mouseNewCCValue == -1 then
                mouseNewCCValue = laneMaxValue
            end
        else
            if mouseOrigPitch and mouseOrigPitch ~= -1 then
                mouseNewPitch = ME_TopPitch - (mouseY - tME_Lanes[-1].ME_TopPixel) / ME_PixelsPerPitch
                if mouseNewPitch      > ME_TopPitch then mouseNewPitch = ME_TopPitch
                elseif mouseNewPitch  < ME_BottomPitch then mouseNewPitch = ME_BottomPitch
                else mouseNewPitch    = math.floor(mouseNewPitch + 0.5)
                end
                mouseNewCCValue = -1
            elseif mouseOrigCCValue and mouseOrigCCValue ~= -1 then      
                mouseNewPitch = -1                               
                mouseNewCCValue = laneMinValue + (laneMaxValue-laneMinValue) * (mouseY - tME_Lanes[mouseOrigCCLaneID].ME_BottomPixel) / (tME_Lanes[mouseOrigCCLaneID].ME_TopPixel - tME_Lanes[mouseOrigCCLaneID].ME_BottomPixel)
                -- In some scripts, the mouse CC value may go beyond lane limits
                if mouseNewCCValue      > laneMaxValue  then mouseNewCCValue = laneMaxValue
                elseif mouseNewCCValue  < laneMinValue  then mouseNewCCValue = laneMinValue
                else mouseNewCCValue    = math.floor(mouseNewCCValue+0.5)
                end  
            end
        end
        
        -- MOUSE NEW TICK / PPQ VALUE (horizontal position)
        -- Snapping not relevant to this script
        if isInline then
            -- A call to BR_GetMouseCursorContext must always precede the other BR_ context calls
            mouseNewPPQPos = reaper.MIDI_GetPPQPosFromProjTime(activeTake, reaper.BR_GetMouseCursorContext_Position())
        elseif ME_TimeBase == "beats" then
            mouseNewPPQPos = ME_LeftmostTick + (mouseX-ME_midiviewLeftPixel)/ME_PixelsPerTick
        else -- ME_TimeBase == "time"
            mouseNewPPQPos = reaper.MIDI_GetPPQPosFromProjTime(activeTake, ME_LeftmostTime + (mouseX-ME_midiviewLeftPixel)/ME_PixelsPerSecond )
        end
        mouseNewPPQPos = mouseNewPPQPos - loopStartPPQPos -- Adjust mouse PPQ position for looped items
        mouseNewPPQPos = math.max(minimumTick, math.min(maximumTick, mouseNewPPQPos))
                

        -- CALCULATE NEW MIDI DATA! and write the tEditedMIDI!
        local stretchedPPQrangeL, stretchFactorL, stretchedPPQrangeR, stretchFactorR
        if PPQrangeL > 0 then
            stretchedPPQrangeL = mouseNewPPQPos - origPPQLeftmost
            stretchFactorL = stretchedPPQrangeL/PPQrangeL
        end
        if PPQrangeR > 0 then
            stretchedPPQrangeR = origPPQRightmost - mouseNewPPQPos
            stretchFactorR = stretchedPPQrangeR/PPQrangeR
        end
        
        -- The warping uses a power function, and the power variable is determined
        --     by calculating to what power 0.5 must be raised to reach the 
        --     mouse's deviation  mouse's deviation above or below the middle of the CC lane.
        -- Why use absolute value?  Since power>1 gives a nicer, more 'musical looking'
        --     shape than power<1.     
        -- Remember to check whether lane is 7 bit, or 14 bit or pitchbend.
        if laneIsPIANOROLL then mouseNewCCValue = mouseNewPitch end
        local mouseUpDownMove = mouseNewCCValue - (laneMaxValue/2)
        local mouseWarp =  0.5 + math.abs(mouseUpDownMove)/laneMaxValue
        -- Prevent warping too much, so that all CCs don't end up in a solid block
        if mouseWarp > 0.99 then mouseWarp = 0.99
        --elseif mouseWarp < 0.01 then mouseWarp = 0.01
        end
        power = m_log(mouseWarp, 0.5)
            
        ------------------------------------------------------------------
        -- Calculate the new raw MIDI data, and write the tEditedMIDI!
        ---------------------------------------------------------------- THIS IS THE PART THAT CAN EASILY BE MODDED !! ------------------------
        tEditedMIDI = {} -- Clean previous tEditedMIDI
        local c = 0 -- Count index inside tEditedMIDI - strangely, this is faster than using table.insert or even #tEditedMIDI+1
                  
        -- In order to czlculaate offsets, the PPQ position of the last inserted event is stored in this variable.
        -- The MIDI string starts counting offsets relative to position.
        local lastPPQPos = 0 
       
        for i = 1, #tPPQs do
            local newPPQPos
            -- Warp the events in the lefthand part
            if tPPQs[i] <= mouseOrigPPQPos then
                -- First, stretch linearly:
                newPPQPos = origPPQLeftmost + (tPPQs[i] - origPPQLeftmost)*stretchFactorL
                -- Then, warp using power function:
                if stretchedPPQrangeL ~= 0 then
                    if mouseUpDownMove > 0 then
                        newPPQPos = origPPQLeftmost + (((newPPQPos - origPPQLeftmost)/stretchedPPQrangeL)^power)*stretchedPPQrangeL
                    elseif mouseUpDownMove < 0 then
                        newPPQPos = mouseNewPPQPos - (((mouseNewPPQPos - newPPQPos)/stretchedPPQrangeL)^power)*stretchedPPQrangeL
                    end
                end
            -- Warp the events in the righthand part
            else -- if tPPQs[i] > mouseOrigPPQPos
                -- First, stretch linearly:
                newPPQPos = origPPQRightmost - (origPPQRightmost - tPPQs[i])*stretchFactorR
                -- Then, warp using power function:
                if stretchedPPQrangeR ~= 0 then
                    if mouseUpDownMove > 0 then
                        newPPQPos = origPPQRightmost - (((origPPQRightmost - newPPQPos)/stretchedPPQrangeR)^power)*stretchedPPQrangeR
                    elseif mouseUpDownMove < 0 then
                        newPPQPos = mouseNewPPQPos + (((newPPQPos - mouseNewPPQPos)/stretchedPPQrangeR)^power)*stretchedPPQrangeR
                    end
                end
            end
            newPPQPos = m_floor(newPPQPos + 0.5)
            
            c = c + 1
            tEditedMIDI[c] = s_pack("i4Bs4", newPPQPos - lastPPQPos, tFlags[i], tMsg[i])
            lastPPQPos = newPPQPos
        end
                            
        -- DRUMROLL... write the edited events into the MIDI chunk!
        reaper.MIDI_SetAllEvts(activeTake, table.concat(tEditedMIDI) .. string.pack("i4Bs4", -lastPPQPos, 0, "") .. remainMIDIString)
    
        if isInline then reaper.UpdateItemInProject(activeItem) end
        
    end -- mustCalculate stuff

    
    -- Tell pcall to loop again
    return true
    
end -- DEFERLOOP_TrackMouseAndUpdateMIDI()


--############################################################################################
----------------------------------------------------------------------------------------------
-- Why is the TrackMouseAndUpdateMIDI function isolated behind a pcall?
--    If the script encounters an error, all intercepts must first be released, before the script quits.
function DEFERLOOP_pcall()
    pcallOK, pcallMustContinue = pcall(DEFERLOOP_TrackMouseAndUpdateMIDI)
    if pcallOK and pcallMustContinue then
        reaper.defer(DEFERLOOP_pcall)
    end
end


--############################################################################################
----------------------------------------------------------------------------
function AtExit()    
    
    -- As when starting the script, restore cursor and toolbar button as soon as possible, in order to seem more responsive.
    -- Was a custom cursur loaded? Restore plain cursor.
    if cursor then 
        cursor = reaper.JS_Mouse_LoadCursor(32512) -- IDC_ARROW standard arrow
        if cursor then reaper.JS_Mouse_SetCursor(cursor) end
    end 
    -- Deactivate toolbar button (if it has been toggled)
    if not leaveToolbarButtonArmed and origToggleState and sectionID and commandID then
        reaper.SetToggleCommandState(sectionID, commandID, origToggleState)
        reaper.RefreshToolbar2(sectionID, commandID)
    end  
        
    -- Restore original focus - except of "Terminate script" dialog box is waiting for user
    if reaper.JS_Localize then
        curForegroundWindow = reaper.JS_Window_GetForeground()
        if curForegroundWindow then 
            if reaper.JS_Window_GetTitle(curForegroundWindow) == reaper.JS_Localize("ReaScript task control", "common") then
                dontReturnFocus = true
    end end end
    if not dontReturnFocus then
        if origForegroundWindow then reaper.JS_Window_SetForeground(origForegroundWindow) end
        if origFocusWindow then reaper.JS_Window_SetFocus(origFocusWindow) end
    end 
        
    -- Communicate with the js_Run.. script that this script is exiting
    reaper.DeleteExtState("js_Mouse actions", "Status", true)
    
    
    -- DEFERLOOP_pcall was executed, and no exceptions encountered:
    if pcallOK == true then        
     
        -- Remove remaining intercepts, restore original intercepts
        if windowUnderMouse then
            for message, passthrough in pairs(tWM_Messages) do
                if passthrough then 
                    reaper.JS_WindowMessage_PassThrough(windowUnderMouse, message, true)
                else
                    reaper.JS_WindowMessage_Release(windowUnderMouse, message)
                end
            end
        end
        
        -- MIDI_Sort used to be buggy when dealing with overlapping or unsorted notes,
        --    causing infinitely extended notes or zero-length notes.
        -- Fortunately, these bugs were seemingly all fixed in v5.32.
        if activeTake then reaper.MIDI_Sort(activeTake) end
        
        -- Check that there were no inadvertent shifts in the PPQ positions of unedited events.
        if not (sourceLengthTicks == reaper.BR_GetMidiSourceLenPPQ(activeTake)) then
            reaper.MIDI_SetAllEvts(activeTake, MIDIString) -- Restore original MIDI
            reaper.MB("The script has detected inadvertent shifts in the PPQ positions of unedited events."
                      .. "\n\nThis may be due to a bug in the script, or in the MIDI API functions."
                      .. "\n\nPlease report the bug in the following forum thread:"
                      .. "\nhttp://forum.cockos.com/showthread.php?t=176878"
                      --.. "\n\nThe original MIDI data will be restored to the take."
                      , "ERROR", 0)
        end
        
    -- DEFERLOOP_pcall was executed, but exception encountered:
    elseif pcallOK == false then
    
        if activeTake and MIDIString then reaper.MIDI_SetAllEvts(activeTake, MIDIString) end -- Restore original MIDI
        if windowUnderMouse then reaper.JS_WindowMessage_ReleaseWindow(windowUnderMouse) end -- Release all intercepts
        reaper.MB("The script encountered an error."
                .."\n\n* The error text has been copied to the console -- please report this error in the \"MIDI Editor Tools\" thread in the REAPER forums."
                .."\n\n* The original, unaltered MIDI has been restored to the take."
                .."\n\n* All intercepts of window messages to the MIDI editor under the mouse (whether by this script or by another script running in the background) have been cancelled."
                , "ERROR", 0)
        reaper.ShowConsoleMsg("\n\n" .. tostring(pcallMustContinue)) -- If pcall returs an error, the error data is in the second return value, namely deferMustContinue
        
    end
 
    -- if script reached DEFERLOOP_pcall (or the WindowMessage section), pcallOK ~= nil, and must create undo point:
    if pcallOK ~= nil then
    
        if activeItem and isInline then reaper.UpdateItemInProject(activeItem) end 
                  
        -- Write nice, informative Undo strings
        if laneIsCC7BIT then
            undoString = "Warp positions of 7-bit CC events in lane ".. tostring(mouseOrigCCLane)
        elseif laneIsCHANPRESS then
            undoString = "Warp positions of channel pressure events"
        elseif laneIsCC14BIT then
            undoString = "Warp positions of 14 bit-CC events in lanes ".. 
                                      tostring(mouseOrigCCLane-256) .. "/" .. tostring(mouseOrigCCLane-224)
        elseif laneIsPITCH then
            undoString = "Warp positions of pitchwheel events"
        elseif laneIsNOTES then
            undoString = "Warp positions and lengths of notes"
        elseif laneIsTEXT then
            undoString = "Warp positions of text events"
        elseif laneIsSYSEX then
            undoString = "Warp positions of sysex events"
        elseif laneIsPROGRAM then
            undoString = "Warp positions of program select events"
        elseif laneIsBANKPROG then
            undoString = "Warp positions of bank/program select events"
        else
            undoString = "Warp event positions"
        end 
        
        -- Undo_OnStateChange_Item is expected to be the fastest undo function, since it limits the info stored 
        --    in the undo point to changes in this specific item.
        if activeItem then    
            reaper.Undo_OnStateChange_Item(0, undoString, activeItem)
        else
            reaper.Undo_OnStateChange2(0, undoString)
        end
    end   

end -- function AtExit   


--###############################################################################################
-------------------------------------------------------------------------------------------------
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
                                              laneIsTEXT, laneMinValue, laneMaxValue = true, 0, 127
                                          elseif (laneType == 0x206) then
                                              laneIsSYSEX, laneMinValue, laneMaxValue = true, 0, 127
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

    local laneType = (tME_Lanes[laneID] and tME_Lanes[laneID].Type)
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
        ME_rectOK, ME_l, ME_t, ME_r, ME_b = reaper.JS_Window_GetRect(editor)
        if not ME_rectOK then 
            reaper.MB("Could not determine the MIDI editor's pixel coordinates.", "ERROR", 0) 
            return(false) 
        end
        -- ClientRect places Y pixel 0 at *top*, and right/bottom are *outside* actual area.
        -- Also, exclude the ruler area on top (which is always 62 pixels high).
        -- Note that on MacOS and Linux, a window may be flipped, so rectLeft may be larger than rectRight, for example.
        local clientOK, rectLeft, rectTop, rectRight, rectBottom = reaper.JS_Window_GetClientRect(midiview) --takeChunk:match("CFGEDIT %S+ %S+ %S+ %S+ %S+ %S+ %S+ %S+ %S+ %S+ %S+ %S+ (%S+) (%S+) (%S+) (%S+)") 
            if not clientOK then 
                reaper.MB("Could not determine the MIDI editor's client window pixel coordinates.", "ERROR", 0) 
                return(false) 
            end
        ME_midiviewLeftPixel, ME_midiviewTopPixel, ME_midiviewRightPixel, ME_midiviewBottomPixel = math.min(rectLeft, rectRight), math.min(rectTop, rectBottom), math.max(rectLeft, rectRight)-1, math.max(rectTop, rectBottom)-1
        
        local laneBottomPixel = ME_midiviewBottomPixel
        for i = #tME_Lanes, 0, -1 do
            tME_Lanes[i].ME_BottomPixel = laneBottomPixel
            tME_Lanes[i].ME_TopPixel    = laneBottomPixel - tME_Lanes[i].ME_Height + 9
            
            laneBottomPixel = laneBottomPixel - tME_Lanes[i].ME_Height
        end
        
        -- Notes area height is remainder after deducting 1) total CC lane height and 2) height (62 pixels) of Ruler/Marker/Region area at top of midiview
        tME_Lanes[-1].ME_BottomPixel = laneBottomPixel
        tME_Lanes[-1].ME_TopPixel    = ME_midiviewTopPixel + 62
        tME_Lanes[-1].ME_Height      = laneBottomPixel - (ME_midiviewTopPixel + 62)
        ME_BottomPitch = ME_TopPitch - math.floor(tME_Lanes[-1].ME_Height / ME_PixelsPerPitch)
    end
 
    -- Finally, get active channel info
    editAllChannels = activeTakeChunk:match("\nEVTFILTER (%S+) %S+ %S+ %S+ %S+ %S+ %S+ ")
    -- activeChannel = tonumber(activeTakeChunk:match("\nCFGEDIT %S+ %S+ %S+ %S+ %S+ %S+ %S+ %S+ (%S+) ")) -- Alreay got this above
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
function GetCCLaneIDFromPoint(x, y)
    if isInline then
        -- return nil -- Not yet implemented in this version
    elseif midiview then
        if x >= ME_midiviewLeftPixel and x <= ME_midiviewRightPixel then
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


--####################################################################################
--------------------------------------------------------------------------------------
function GetAndParseMIDIString()  
    
    -- Start again here if sorting was done.
    ::startAgain::
    
    gotAllEvtsOK, MIDIString = reaper.MIDI_GetAllEvts(activeTake, "")
        if not gotAllEvtsOK then
            reaper.MB("MIDI_GetAllEvts could not load the raw MIDI data.", "ERROR", 0)
            return false 
        end
    
    local MIDIlen = MIDIString:len()
            
    -- The abstracted info of targeted MIDI events (that will be edited) will be will be stored in
    --    several new tables such as tPPQs and tValues.
    -- Clean up these tables in case starting again after sorting.
    tMsg = {}
    tPPQs = {}
    tFlags = {}
    
    -- The MIDI strings of non-targeted events will temnporarily be stored in a table, tRemainingEvents[],
    --    and once all MIDI data have been parsed, this table (which excludes the strings of targeted events)
    --    will be concatenated into remainMIDIString.
    local tRemainingEvents = {}    
     
    local runningPPQPos = 0 -- The MIDI string only provides the relative offsets of each event, sp the actual PPQ positions must be calculated by iterating through all events and adding their offsets
    local lastRemainPPQPos = 0 -- PPQ position of last event that was *not* targeted, and therefore stored in tRemainingEvents.
    local mustUpdateNextOffset                  
    local prevPos, nextPos, unchangedPos = 1, 1, 1 -- Keep record of position within MIDIString. unchangedPos is position from which unchanged events van be copied in bulk.
    local c = 0 -- Count index inside tables - strangely, this is faster than using table.insert or even #table+1
    local r = 0 -- Count inside tRemainingEvents
    local offset, flags, msg, mustUpdateNextOffset -- MIDI data that will be unpacked for each event
    
    ---------------------------------------------------------------
    -- This loop will iterate through the MIDI data, event-by-event
    -- In the case of unselected events, only their offsets are relevant, in order to update runningPPQPos.
    -- Selected events will be checked in more detail, to find those in the target lane.
    --
    -- The exception is notation events: Notation 'text events' for selected noted are unfortunately not also selected. 
    --    So relevant notation text events can only be found by checking each and every notation event.
    -- If note positions are not changed, then do not need to extract notation, since MIDI_Sort will eventually put notes and notation together again.
    --
    -- Should this parser check for unsorted MIDI?  This would depend on the function of the script. 
    -- Scripts such as "Remove redundant CCs" will only work on sorted MIDI.  For others, sorting is not relevant.
    -- Note that even in sorted MIDI, the first event can have an negative offset if its position is to the left of the item start.
    -- As discussed in the introduction, MIDI sorting entails several problems.  This script will therefore avoid sorting until it exits, and
    --    will instead notify the user, in the rare case that unsorted MIDI is deteced.  (Checking for negative offsets is also faster than unneccesary sorting.)
    
       
        
    -- This function will try two main things to make execution faster:
    --    * First, an upper bound for positions of the targeted events in MIDIString must be found. 
    --      If such an upper bound can be found, the parser does not need to parse beyond this point,
    --      and the remaining later part of MIDIString can be stored as is.
    --    * Second, events that are not changed (i.e. not extracted or offset changed) will not be 
    --      inserted individually into tRemainingEvents, using string.pack.  Instead, they will be 
    --      inserted as blocks of multiple events, copied directly from MIDIString.  By so doing, the 
    --      number of table writes are lowered, the speed of table.concat is improved, and string.sub
    --      can be used instead of string.pack.
    
    -----------------------------------------------------------------------------------------------------
    -- To get an upper limit for the positions of targeted events in MIDIString, string.find will be used
    --    to find the posision of the last targeted event in MIDIString (NB, the *string* posision, not 
    --    the PPQ position.  string.find will search backwards from the end of MIDIString, using Lua's 
    --    string patterns to ensure that all possible targeted events would be matched.  
    --    (It is possible, though unlikely, that a non-targeted events might also be matched, but this is 
    --    not a problem, since it would simply raise the upper limit.  Parsing would be a bit slower, 
    --    but since all targeted events would still be included in below the upper limit, parsing will 
    --    still be accurate.
    
    -- But what happens if one of the characters in the MIDI string is a "magic character"
    --    of Lua's string patterns?  The magic characters are: ^$()%.[]*+-?)
    -- The byte values for these characters are:
    -- % = 0x25
    -- . = 0x2e
    -- ^ = 0x5e
    -- ? = 0x3f
    -- [ = 0x5b 
    -- ] = 0x5d
    -- + = 0x2b
    -- - = 0x2d
    -- ) = 0x29
    -- ( = 0x28
    -- Fortunately, these byte values fall outside the range of (most of the) values in the match string:
    --    * MIDI status bytes > 0x80
    --    * Message lengths <= 3
    -- The only problem is msg2 (MIDI byte 2), which can range from 0 to 0xEF.
    -- These bytes must therefore be compared to the above list, and prefixed with a "%" where necessary. gsub will be used.
    -- (It is probably only strictly necessary to prefix % to "%" and ".", but won't hurt to prefix to all of the above.)
    local matchStrReversed, firstTargetPosReversed = "", 0

        if laneIsCC7BIT then
            local msg2string = string.char(mouseOrigCCLane):gsub("[%(%)%.%%%+%-%*%?%[%]%^]", "%%%0") -- Replace magic characters.
            matchStrReversed = table.concat({"[",msg2string,"]",
                                                   "[",string.char(0xB0),"-",string.char(0xBF),"]", 
                                                       string.pack("I4", 3):reverse(),
                                                   "[",string.char(0x01, 0x03),"]"})    
        elseif laneIsPITCH then
            matchStrReversed = table.concat({"[",string.char(0xE0),"-",string.char(0xEF),"]",
                                                       string.pack("I4", 3):reverse(),
                                                   "[",string.char(0x01, 0x03),"]"})
        elseif laneIsNOTES then
            matchStrReversed = table.concat({"[",string.char(0x80),"-",string.char(0x9F),"]", -- Note-offs and note-ons in all channels.
                                                       string.pack("I4", 3):reverse(),
                                                   "[",string.char(0x01, 0x03),"]"})
        elseif laneIsCHANPRESS then
            matchStrReversed = table.concat({"[",string.char(0xD0),"-",string.char(0xDF),"]",
                                                       string.pack("I4", 2):reverse(),
                                                   "[",string.char(0x01, 0x03),"]"})                                      
        elseif laneIsCC14BIT then
            local MSBlane = mouseOrigCCLane - 256
            local LSBlane = mouseOrigCCLane - 224
            local msg2string = string.char(MSBlane, LSBlane):gsub("[%(%)%.%%%+%-%*%?%[%]%^]", "%%%0")
            matchStrReversed = table.concat({"[",msg2string,"]",
                                                   "[",string.char(0xB0),"-",string.char(0xBF),"]", 
                                                       string.pack("I4", 3):reverse(),
                                                   "[",string.char(0x01, 0x03),"]"})  
        elseif laneIsSYSEX then
            matchStrReversed = table.concat({string.char(0xF0), 
                                                   "....",
                                                   "[",string.char(0x01, 0x03),"]"})
        elseif laneIsTEXT then
            matchStrReversed = table.concat({"[",string.char(0x01),"-",string.char(0x09),"]",
                                                        string.char(0xFF), 
                                                        "....",
                                                   "[", string.char(0x01, 0x03),"]"})                                                
        elseif laneIsPROGRAM then
            matchStrReversed = table.concat({"[",string.char(0xC0),"-",string.char(0xCF),"]",
                                                       string.pack("I4", 2):reverse(),
                                                   "[",string.char(0x01, 0x03),"]"})                      
        end
    
        firstTargetPosReversed = MIDIString:reverse():find(matchStrReversed) -- Search backwards by using reversed string. 
    --end
    
    if firstTargetPosReversed then 
        lastTargetStrPos = MIDIlen - firstTargetPosReversed 
    else -- Found no targeted events
        lastTargetStrPos = 0
    end    
    
    ---------------------------------------------------------------------------------------------
    -- OK, got an upper limit.  Not iterate through MIDIString, until the upper limit is reached.
    while nextPos < lastTargetStrPos do
       
        local mustExtract = false
        local offset, flags, msg
        
        prevPos = nextPos
        offset, flags, msg, nextPos = s_unpack("i4Bs4", MIDIString, prevPos)
      
        -- Check flag as simple test if parsing is still going OK
        if flags&252 ~= 0 then -- 252 = binary 11111100.
            reaper.MB("The MIDI data uses an unknown format that could not be parsed."
                    .. "\n\nPlease report the problem in the MIDI Tools thread:"
                    .. "\nFlags = " .. string.format("%02x", flags)
                    , "ERROR", 0)
            return false
        end
        
        -- Check for unsorted MIDI
        if offset < 0 and prevPos > 1 then   
            -- The bugs in MIDI_Sort have been fixed in REAPER v5.32, so it should be save to use this function.
            if not haveAlreadySorted then
                reaper.MIDI_Sort(activeTake)
                haveAlreadySorted = true
                goto startAgain
            else -- haveAlreadySorted == true
                reaper.MB("Unsorted MIDI data has been detected."
                        .. "\n\nThe script has tried to sort the data, but was unsuccessful."
                        .. "\n\nSorting of the MIDI can usually be induced by any simple editing action, such as selecting a note."
                        , "ERROR", 0)
                return false
            end
        end         
        
        runningPPQPos = runningPPQPos + offset                 

        -- Only analyze *selected* events - as well as notation text events (which are always unselected)
        if flags&1 == 1 and msg:len() ~= 0 then -- bit 1: selected, skip empty spacer events
                
            if laneIsCC7BIT then if msg:byte(2) == mouseOrigCCLane and (msg:byte(1))>>4 == 11 and (editAllChannels or msg:byte(1)&0x0F == activeChannel)
            then
                mustExtract = true
                end 
                                
            elseif laneIsPITCH then if (msg:byte(1))>>4 == 14 and (editAllChannels or msg:byte(1)&0x0F == activeChannel)
            then
                mustExtract = true        
                end                           
                                    
            elseif laneIsCC14BIT then if msg:byte(1)>>4 == 11 and (msg:byte(2) == mouseOrigCCLane-224 or msg:byte(2) == mouseOrigCCLane-256) 
                                                              and (editAllChannels or msg:byte(1)&0x0F == activeChannel)
            then
                mustExtract = true
                end 
              
            elseif laneIsNOTES then if (msg:byte(1)>>4 == 8 or msg:byte(1)>>4 == 9) and (editAllChannels or msg:byte(1)&0x0F == activeChannel)
            then
                mustExtract = true
                end 
                
            elseif laneIsPROGRAM then if (msg:byte(1))>>4 == 12 and (editAllChannels or msg:byte(1)&0x0F == activeChannel)
            then
                mustExtract = true
                end
                
            elseif laneIsCHANPRESS then if (msg:byte(1))>>4 == 13 and (editAllChannels or msg:byte(1)&0x0F == activeChannel)
            then
                mustExtract = true
                end
                
            elseif laneIsBANKPROG then if ((msg:byte(1))>>4 == 12 or ((msg:byte(1))>>4 == 11 and (msg:byte(2) == 0 or msg:byte(2) == 32))) and (editAllChannels or msg:byte(1)&0x0F == activeChannel)
            then
                mustExtract = true
                end
                         
            elseif laneIsTEXT then if msg:byte(1) == 0xFF --and not (msg2 == 0x0F) -- text event (0xFF), excluding notation type (0x0F)
            then
                mustExtract = true
                end
                                    
            elseif laneIsSYSEX then if (msg:byte(1))>>4 == 0xF and not (msg:byte(1) == 0xFF) then -- Selected sysex event (text events with 0xFF as first byte have already been excluded)
                mustExtract = true
                end
                
            end  
            
        end -- if laneIsCC7BIT / CC14BIT / PITCH etc    
        
        -- Check notation text events (check whether or not is selected)
        if laneIsNOTES 
        and msg:byte(1) == 0xFF -- MIDI text event
        and msg:byte(2) == 0x0F -- REAPER's MIDI text event type
        then
            -- REAPER v5.32 changed the order of note-ons and notation events. So must search backwards as well as forward.
            local notationChannel, notationPitch = msg:match("NOTE (%d+) (%d+) ") 
            if notationChannel then
                notationChannel = tonumber(notationChannel)
                notationPitch   = tonumber(notationPitch)
                -- First, backwards through notes that have already been parsed.
                for i = #tPPQs, 1, -1 do
                    if tPPQs[i] ~= runningPPQPos then 
                        break -- Go on to forward search
                    else
                        if tMsg[i]:byte(1) == 0x90 | notationChannel
                        and tMsg[i]:byte(2) == notationPitch
                        then
                            mustExtract = true
                            goto completedNotationSearch
                        end
                    end
                end
                -- Search forward through following events, looking for a selected note that match the channel and pitch
                local evPos = nextPos -- Start search at position of nmext event in MIDI string
                local evOffset, evFlags, evMsg
                repeat -- repeat until an offset is found > 0
                    evOffset, evFlags, evMsg, evPos = s_unpack("i4Bs4", MIDIString, evPos)
                    if evOffset == 0 then 
                        if evFlags&1 == 1 -- Only match *selected* events
                        and evMsg:byte(1) == 0x90 | notationChannel -- Match note-ons and channel
                        and evMsg:byte(2) == notationPitch -- Match pitch
                        and not (evMsg:byte(3) == 0) -- Note-ons with velocity == 0 are actually note-offs
                        then
                            mustExtract = true
                            goto completedNotationSearch
                        end
                    end
                until evOffset ~= 0
                ::completedNotationSearch::
            end   
        end    
                
                        
        --------------------------------------------------------------------------
        -- So what must be done with the MIDI event?  Stored as non-targeted event 
        --    in tRemainingEvents?  Or update offset?
        -- Scripts that only change event position, does not need to extract event values, for example.
        if mustExtract then
            c = c + 1 
            tPPQs[c] = runningPPQPos
            tFlags[c] = flags
            tMsg[c] = msg
            -- The chain of unchanged events is broken, so write to tRemainingEvents
            if unchangedPos < prevPos then
                r = r + 1
                tRemainingEvents[r] = MIDIString:sub(unchangedPos, prevPos-1)
            end
            unchangedPos = nextPos
            mustUpdateNextOffset = true
        elseif mustUpdateNextOffset then
            r = r + 1
            tRemainingEvents[r] = s_pack("i4Bs4", runningPPQPos-lastRemainPPQPos, flags, msg)
            lastRemainPPQPos = runningPPQPos
            unchangedPos = nextPos
            mustUpdateNextOffset = false
        else
            lastRemainPPQPos = runningPPQPos
        end 

    end -- while    
    
    
    -- Now insert all the events to the right of the targets as one bulk
    if mustUpdateNextOffset then
        offset = s_unpack("i4", MIDIString, nextPos)
        runningPPQPos = runningPPQPos + offset
        r = r + 1
        tRemainingEvents[r] = s_pack("i4", runningPPQPos - lastRemainPPQPos) .. MIDIString:sub(nextPos+4) 
    else
        r = r + 1
        tRemainingEvents[r] = MIDIString:sub(unchangedPos) 
    end               
                
    remainMIDIString = table.concat(tRemainingEvents)
    
    -- Calculate original PPQ ranges and extremes
    -- * THIS ASSUMES THAT THE MIDI DATA IS SORTED *
    origPPQLeftmost  = tPPQs[1]
    origPPQRightmost = tPPQs[#tPPQs]
    origPPQRange     = (origPPQRightmost and origPPQLeftmost) and (origPPQRightmost - origPPQLeftmost) or -1                 
    
    -- Fiinally, return true
    return true
    
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
    reaper.SetToggleCommandState(sectionID, commandID, 1)
    reaper.RefreshToolbar2(sectionID, commandID)
    
    Tooltip("Armed: 2-sided Warp")
    
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
        if not (mouseX and mouseY) then mouseX, mouseY = reaper.GetMousePosition() end
        reaper.TrackCtl_SetToolTip(tooltipText, mouseX+10, mouseY+10, true)
        reaper.defer(Tooltip)
    elseif reaper.time_precise() < tooltipTime+0.5 then
        if not (mouseX and mouseY) then mouseX, mouseY = reaper.GetMousePosition() end
        reaper.TrackCtl_SetToolTip(tooltipText, mouseX+10, mouseY+10, true)
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
    
    
    -- If anyting goes wrong during main(), a dialog box will pop up, so Exit() will try to return focus to original windows.
    reaper.atexit(AtExit)
        

    -- Check whether other js_Mouse editing scripts are running
    if reaper.HasExtState("js_Mouse actions", "Status") then
        return false
    else
        reaper.SetExtState("js_Mouse actions", "Status", "Running", false)
    end
    
    
    -- Check whether SWS and my own extension are available, as well as the required version of REAPER
    if not (reaper.JS_Window_Find) then -- FindEx was added in v0.963
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
    -- The js_ReaScriptAPI extension already requires REAPER v5.95 or higher, so don't need to check.
    -- Older versions of SWS had bugs in BR_GetMouseCursorContext
    elseif not reaper.SN_FocusMIDIEditor then 
        reaper.MB("This script requires an up-to-date versions of the SWS/S&M extension."
               .. "\n\nThe SWS/S&M extension can be downloaded from www.sws-extension.org."
                , "ERROR", 0)
        return(false) 
    end 
    
    
    -- GET MOUSE STARTING STATE:
    -- as soon as possible.  Hopefully, if script is started with mouse click, mouse button will still be down.
    mouseOrigX, mouseOrigY = reaper.GetMousePosition()
    prevMouseTime = startTime + 0.5 -- In case mousewheel sends multiple messages, don't react to messages sent too closely spaced, so wait till little beyond startTime.
    mouseState = reaper.JS_Mouse_GetState(0xFF)
 
    
    -- MOUSE CURSOR AND TOOLBAR BUTTON:
    -- To give an impression of quick responsiveness, the script must change the cursor and toolbar button as soon as possible.
    -- (Later, the script will block "WM_SETCURSOR" to prevent REAPER from changing the cursor back after each defer cycle.)
    _, filename, sectionID, commandID = reaper.get_action_context()
    --[[filename = filename:gsub("\\", "/") -- Change Windows format to cross-platform
    filename = filename:match("^.*/") -- Remove script filename, keeping directory
    filename = filename .. "js_Mouse editing - Warp left right - Orange.cur"
    cursor = reaper.JS_Mouse_LoadCursorFromFile(filename) -- The first time that the cursor is loaded in the session will be slow, but afterwards the extension will re-use previously loaded cursor
    if not cursor then cursor = reaper.JS_Mouse_LoadCursor(32646) end]] -- If .cur file unavailable, load Windows/swell 4-pointed arrow cursor, to indicate that mouse can move in any direction.
    cursor = reaper.JS_Mouse_LoadCursor(453)
    if cursor then reaper.JS_Mouse_SetCursor(cursor) end    
    
    if sectionID ~= nil and commandID ~= nil and sectionID ~= -1 and commandID ~= -1 then
        origToggleState = reaper.GetToggleCommandStateEx(sectionID, commandID)
        reaper.SetToggleCommandState(sectionID, commandID, 1)
        reaper.RefreshToolbar2(sectionID, commandID)
    end
    
    
    -- WINDOW FOCUS:
    -- As a courtesy to the user, the script will return focus to the original window, if an error message popped up
    -- REAPER tends to return focus to the main window instead of the last focused MIDI editor.
    origFocusWindow = reaper.JS_Window_GetFocus()
    origForegroundWindow = reaper.JS_Window_GetForeground()                   
    
    
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
            if reaper.MIDIEditor_GetMode(parentWindow) ~= -1 then -- got a window in a MIDI editor
                isInline = false
                editor = parentWindow
                if windowUnderMouse == reaper.JS_Window_FindChildByID(parentWindow, 1001) then -- The piano roll child window, titled "midiview" in Windows.
                    midiview = windowUnderMouse
                    
                    activeTake = reaper.MIDIEditor_GetTake(editor)
                    activeTakeOK = activeTake and reaper.ValidatePtr2(0, activeTake, "MediaItem_Take*") and reaper.TakeIsMIDI(activeTake)
                    if activeTakeOK then
                    
                        activeItem = reaper.GetMediaItemTake_Item(activeTake)
                        activeItemOK = activeItem and reaper.ValidatePtr(activeItem, "MediaItem*") 
                        if activeItemOK then 
                        
                            -- Get MIDI editor structure from chunk, and store in tME_Lanes table.
                            chunkStuffOK = SetupMIDIEditorInfoFromTakeChunk() 
                            if chunkStuffOK then
                                
                                -- Get CC lane.  This script works in a single lane, so if on divider, must wait until mouse enters a CC lane
                                --::loopUntilMouseEntersCCLane::
                                mouseOrigCCLaneID = GetCCLaneIDFromPoint(mouseOrigX, mouseOrigY) 
                                --if mouseOrigCCLaneID and mouseOrigCCLaneID%1 ~= 0 then mouseStartedOnLaneDivider = true; _, mouseOrigY = reaper.GetMousePosition(); goto loopUntilMouseEntersCCLane end
                                
                                if mouseOrigCCLaneID then
                                    
                                    targetLaneOK, mouseOrigCCLane = SetupTargetLaneForParsing(mouseOrigCCLaneID) 
                                    if targetLaneOK then
                                    
                                        -- Calculate these variables here, since the BR_ function will get this for inline editor
                                        if (mouseOrigCCLaneID == -1) and ME_TopPitch and ME_PixelsPerPitch then
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
                
                if isInline then
                    
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
        elseif not activeTakeOK then
            reaper.MB("Could not determine a valid MIDI take in the editor under the mouse.", "ERROR", 0)
        elseif not activeItemOK then
            reaper.MB("Could not determine the media item to which the MIDI editor's active take belong.", "ERROR", 0)
        elseif not chunkStuffOK then
            -- The chuck functions give their own detailed error messages if something goes awry.
        elseif not targetLaneOK then
            reaper.MB("One or more of the CC lanes are of unknown type, and could not be parsed by this script.", "ERROR", 0)
        end
        return false
    end   
    if laneIsNOTATION or laneIsMEDIAITEM or laneIsALL then --not (laneIsCC7BIT or laneIsCC14BIT or laneIsCHANPRESS or laneIsVELOCITY or laneIsPITCH or laneIsPROGRAM or laneIs then
        reaper.MB("This script will only work in the following MIDI lanes: \n* 7-bit CC, \n* 14-bit CC, \n* Velocity, \n* Channel Pressure, \n* Pitch, \n* Program select,\n* Bank/Program,\n* Text or Sysex,\nor in the 'notes area' of the piano roll.", "ERROR", 0)
        return false
    end
    
    
    -- GET AND PARSE MIDI:
    -- Time to process the MIDI of the take!
    -- As mentioned in the header, this script does not use the old-fashioned MIDI API functions such as 
    --    MIDI_InsertCC, since these functions are far too slow when dealing with thousands of events.
    if not GetAndParseMIDIString() then return false end      
    if #tPPQs < 2 or (#tPPQs < 3 and not laneIsNOTES) then -- Two notes can be warped, but not two CCs
        reaper.MB("Could not find a sufficient number of selected events in the target lane(s).", "ERROR", 0)
        return false
    end
    
    
    -- MOUSE STARTING PPQ VALUES
    -- Get mouse starting PPQ position -- AND ADJUST FOR LOOPING -- NB: This script does not require snap to grid
    if isInline then
        mouseOrigPPQPos = reaper.MIDI_GetPPQPosFromProjTime(activeTake, reaper.BR_GetMouseCursorContext_Position())
    elseif ME_TimeBase == "beats" then
        mouseOrigPPQPos = ME_LeftmostTick + (mouseOrigX - ME_midiviewLeftPixel)/ME_PixelsPerTick
    else -- ME_TimeBase == "time"
        mouseOrigPPQPos  = reaper.MIDI_GetPPQPosFromProjTime(activeTake, ME_LeftmostTime + (mouseOrigX-ME_midiviewLeftPixel)/ME_PixelsPerSecond )
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
    -- If notes, prevent warping and stretching out of original PPQ range of events
    if laneIsNOTES then -- !!!!!!!!!!! UNIQUE 
        minimumTick = math.max(itemFirstVisibleTick, origPPQLeftmost + #tPPQs)
        maximumTick = math.min(itemLastVisibleTick, origPPQRightmost - #tPPQs)
    else
        minimumTick = math.max(itemFirstVisibleTick, 0)
        maximumTick = math.min(itemLastVisibleTick, sourceLengthTicks-1) -- I prefer not to draw any event on the same PPQ position as the All-Notes-Off
    end
    mouseOrigPPQPos = math.max(minimumTick, math.min(maximumTick, mouseOrigPPQPos))

        
    
    -- UNIQUE TO THIS SCRIPT:
    PPQrangeL = mouseOrigPPQPos - origPPQLeftmost
    PPQrangeR = origPPQRightmost - mouseOrigPPQPos 

      
    
    -- INTERCEPT WINDOW MESSAGES:
    -- Do the magic that will allow the script to track mouse button and mousewheel events!
    -- Do this only at the very end of the MAIN function, to avoid problems with intercepts remaining blocked.
    -- The code assumes that all the message types will be blocked.  (Scripts that pass some messages through, must use other code.)
    -- tWM_Messages entries that are currently being intercepted but passed through, will temporarily be blocked wnd then restored wen the script terminates.
    -- tWM_Messages entries that are already being intercepted and blocked, do not need to be changed or restored, so will be deleted from the table.   
    local pcallInterceptOK, interceptOK = pcall( 
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
                reaper.MB("Intercepting window messages failed. All intercept for the window under the mouse will be released", "ERROR", 0) 
                return false
            end
        end
        return true
    end)
    if not pcallInterceptOK and interceptOK then reaper.JS_WindowMessage_ReleaseWindow(windowUnderMouse) return false end
       
       
    -- Start the loop!
    DEFERLOOP_pcall()
    
end -- function Main()


--################################################
--------------------------------------------------
MAIN()

