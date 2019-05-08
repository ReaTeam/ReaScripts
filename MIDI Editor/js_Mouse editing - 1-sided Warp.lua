--[[
ReaScript name: js_Mouse editing - 1-sided Warp.lua
Version: 4.20
Author: juliansader
Website: http://forum.cockos.com/showthread.php?t=176878
Donation: https://www.paypal.me/juliansader
Provides: [main=midi_editor,midi_inlineeditor] .
About:
  # DESCRIPTION
  
  A Lua script for warping the positions or values of MIDI CCs and velocities.
  
  Warp axis:
  * Events positions can be warped horizontally (to the left or right), and event values can be warp vertically (up or down).
  * When warping events in multiple lanes together, or events that do not have values, such as text or sysex, warping can only be horizontal.
  * Warp direction is determined by initial mouse movement: To warp event positions horizontally, move the mouse left/right when the script starts; 
      to warp event values vertically, move the mouse up/down. (This is similar to how REAPER's own "move in one direction only" mouse modifiers work.)
  
  Applications:
  * Changing a linear ramp into a parabolic (or other power) curve.
  * Accelerating a series of evenly spaced notes.
  * Changing the curve shape of LFOs.
  
  Single lane vs all lanes:
  * If the mouse is positioned inside a CC lane (or inside the notes area) when the script starts, the script will only warp selected events in that single lane.
  * If the mouse is positioned over a lane divider (or in the ruler area) when the script starts, the script will warp all selected events in all lanes together.
  * If the mouse is positioned over a toolbar or the Actions list (or, actually anywhere outside the MIDI piano roll and CC lanes), the script will arm itself 
      and can then be run by the "js_Run the mouse editing script that is armed in toolbar" script.

  The script can apply two different acceleration curves: smooth or steep:
  * The mouse middle button can be used to switch between the curves.
  * Both of the curves are invertible, so events that were warped can later be re-selected and re-warped back to their original positions.


  # INSTRUCTIONS
   
  js_Mouse editing scripts can be controlled by the mouse and keyboard while the script is running:
      * Mouse movement: Changes the extent of warping
      * Mouse left click: Terminates the script.
      * Mouse middle click: Toggle the warp curve shape.
      * Mouse right click: While right button is down, temporarily warp in both directions.
      * Mousewheel: -- (not used by this script)
      * Any keystroke:  Terminates the script.
  
  
  MOUSE EDITING SCRIPTS vs REAPER's LEFT-DRAG MOUSE MODIFIER ACTIONS
  
  The "js_Mouse editing" script resemble REAPER's own left-drag mouse modifier actions 
  (such as "Draw CCs", "Arpeggiate", "Paint notes", etc), in that the scripts follow mouse movement 
  and continue to run until the user stops the script.
  
  However, the scripts are more advanced than the native actions:
  
     * The scripts' functioning (such as the ramp shape or the channel of inserted CCs) can be tweaked while the script is running, 
     using the mousewheel, mouse middle button and right button.
     
     * Whereas native actions can only be started and stopped by left-dragging and lifting the mouse button,
     the scripts be started and stopped in multiple ways, allowing a more customized and streamlined workflow.
  
  Starting a script:
  
      * Similar to any action in the Actions list, the script can be assigned a keyboard or mousewheel shortcut.
        To start and stop the script using a shortcut, you have two options: 
            1) Two keystrokes: To start, press the shortcut key once *without holding the key down* and then press the same or any other key to stop;
            2) Press and hold: Press the shortcut key and hold it down for as long as the script should run. If the key is held down for more than one second, the script will terminate when the key is released.
        
      * Similar to mouse modifier actions, assign the script to a left-click or double-click mouse modifier in Preferences -> Mouse modifiers.  
        (NOTE: In current versions of REAPER, actions can not be assigned to left-drag mouse modifiers, 
               but the script will automatically detect a left-drag movement. To use left-drag, assign the script to a *double*-click mouse modifier.)
               
      * Arming a toolbar button, as described below.
  
  Stopping a script:
  
     * Mouse: Left clicking while the script is running.
  
     * Mouse: Left-dragging and lifting the left button after holding the button down for more than one second.
  
     * Keyboard: Pressing any key (Ctrl/Cmnd, Alt, Shift or Win) while theh script is running.
     
     * Keyboard: Releasing the shortcut key after holding it down for more than one second.
         
  
  RUNNING THE SCRIPT FROM THE TOOLBAR:
  
  Since the functioning of the script depends on initial mouse position (similar to some of REAPER's own mouse modifier actions, 
     or actions such as "Insert note at mouse cursor"), the script cannot be run from a toolbar button.  
     This problem is solved by "arming" toolbar buttons for delayed execution after moving the mouse into position:
     
     
     REAPER's NATIVE TOOLBAR ARMING:
     
     REAPER natively provides a "toolbar arming" feature: right-click a toolbar button to arm its linked action
     (the button will light up with an alternative color), and then left-click to run the action 
     after moving the mouse into position over the piano roll.
     
     There are two niggles with this feature, though: 
     
     1) Left-drag is very sensitive: If the mouse is even slightly moved while left-clicking,
         the left-drag mouse modifier action will be run instead of the armed toolbar action; 
  
     2) Multiple clicks: The user has to right-click the toolbar (or press Esc) to disarm the toolbar and use left-click normally again,
         then right-click the toolbar again to use the script. 
         
         
     ALTERNATIVE TOOLBAR ARMING:
     
     The "js_Mouse editing" scripts therefore offer an alternative "toolbar arming" solution:  
     
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
      the visible and editable takes.  If the MIDI editor is slow, try reducing the number of editable and visible tracks.
      
  PERFORMANCE TIP 2: If the MIDI editor gets slow and jerky when a certain VST plugin is loaded, 
      check for graphics driver incompatibility by disabling graphics acceleration in the plugin.
]] 

--[[
  Changelog:
  * v4.00 (2019-01-19)
    + Updated for ReaScriptAPI extension.
  * v4.01 (2019-02-11)
    + Restore focus to original window, if script opened notification window.
  * v4.02 (2019-02-16)
    + Fixed: On Linux, crashing if editor closed while script is running.
  * v4.03 (2019-03-02)
    + Fixed: If editor is docked, properly restore focus.
  * v4.10 (2019-03-05)
    + Compatible with macOS.
  * v4.20 (2019-04-25)
    + Clicking armed toolbar button disarms script.
    + Improved starting/stopping: 1) Any keystroke terminates script; 2) Alternatively, hold shortcut for second and release to terminate.
]]

-- USER AREA 
-- Settings that the user can customize
    
    -- How far must the mouse move before the scripts decides between warping up/down or left/right?  
    -- May need to be changed if Hi-res screen or jerky mouse.
    local mouseMovementResolution = 5
    
-- End of USER AREA   


-- ################################################################################################
---------------------------------------------------------------------------------------------------
-- CONSTANTS AND VARIABLES (that modders may find useful)

local MIDIString -- The original raw MIDI data returned by GetAllEvts
local remainMIDIString -- The MIDI that remained after extracting selected events in the target lane
local tableEditedMIDI = {} -- Each edited event will be stored in this table, ready to be concatenated

-- When the info of the targeted events is extracted, the info will be stored in several tables.
-- The order of events in the tables will reflect the order of events in the original MIDI, except note-offs, 
--    which will be replaced by note lengths, and notation text events, which will also be stored in a separate table
--    at the same indices as the corresponding notes.
local tMsg = {}
local tMsgLSB = {}
local tMsgNoteOffs = {}
local tValues = {} -- CC values, 14bit CC combined values, note velocities
local tTicks = {}
local tChannels = {}
local tFlags = {}
local tFlagsLSB = {} -- In the case of 14bit CCs, mute/select status of the MSB
local tPitches = {} -- This table will only be filled if laneIsVELOCITY or laneIsPIANOROLL
local tNoteLengths = {}
local tNotation = {} -- Will only contain entries at those indices where the notes have notation
local tV, tP = {}, {} -- When warping in both directions, store values and positions temporarily for next step.

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

-- The script will intercept keystrokes, to allow control of script via keyboard, 
--    and to prevent inadvertently running other actions such as closing MIDI editor by pressing ESC
local VKLow, VKHi = 8, 0xFE --0xA5 -- Range of virtual key codes to check for key presses
local VKState0 = string.rep("\0", VKHi-VKLow+1)
local dragTime = 0.5 -- How long must the shortcut key be held down before left-drag is activated?
local dragTimeStarted = false

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
local ME_LeftmostTick, ME_PixelsPerTick, ME_PixelsPerSecond = nil, nil, nil -- horizontal scroll and zoom
local ME_TopPitch, ME_PixelsPerPitch = nil, nil -- vertical scroll and zoom
local ME_midiviewWidth, ME_midiviewHeight = nil, nil -- Mouse screen coordinates will be converted to client, so leftmost and topmost pixels are always 0.
local ME_TargetTopPixel, ME_TargetBottomPixel
local ME_TimeBase
local tME_Lanes = {} -- store the layout of each MIDI editor lane
--local tVisibleCC7Bit = {} -- CC lanes to use.  (In case of a 14bit CC lane or Bank/Program, this table will contain two entries. If all visible lanes are used, may contain even more entries.)

-- I am not sure that declaring functions local really helps to speed things up...
local s_unpack = string.unpack
local s_pack   = string.pack
local m_floor  = math.floor
local m_min = math.min
local m_max = math.max 

-- User preferences that can be customized via toggle scripts
--local clearNonActiveTakes  = true

-- Window messages that will be intercepted while the script is running
local tWM_Messages = {WM_LBUTTONDOWN = false, WM_LBUTTONDBLCLK = false, WM_LBUTTONUP = false,
                      WM_MBUTTONDOWN = false, WM_MBUTTONDBLCLK = false, WM_MBUTTONUP = false,
                      WM_RBUTTONDOWN = false, WM_RBUTTONDBLCLK = false, WM_RBUTTONUP = false,
                      WM_NCMOUSEMOVE = false, -- I'm not sure... Does this prevent REAPER from changing the mouse cursor when it's over scrollbars?
                      WM_MOUSEWHEEL  = false, WM_MOUSEHWHEEL   = false,
                      WM_SETCURSOR   = false,
                      WM_KEYDOWN     = false}                 
  
-- Unique to this script:
-- Warp direction, based on initial mouse movement
local warpLEFTRIGHT = false
local warpUPDOWN = false
local curveType = true -- the script can switch between two curve types using the mousewheel. This variable toggles between true and false.
local canWarpBothDirections = false

  
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
--           The more events in visible and editable takes, the slower the updating.  MIDI_SetAllEvts
--           seems to get slowed down more than REAPER's native Actions such as Invert Selection.
--           If, in the future, the REAPER API provides a way to toggle take visibility in the editor,
--           it may be helpful to temporarily make all non-active takes invisible. 
-- The Lua script parts of this function - even if it calculates thousands of events per cycle,
--    make up only a small fraction of the execution time.
local function DEFERLOOP_TrackMouseAndUpdateMIDI()
    
    -- TERMINATE OR CALCULATE?
    -- Must the script terminate?
    -- There are several ways to terminate the script:  Any mouse button, mousewheel movement or modifier key will terminate the script;
    --   except unmodified middle button and unmodified mousewheel, which toggles or scrolls through options, respectively.
    -- This gives the user flexibility to control the script via keyboard or mouse, as desired.
    
    -- Must the script go through the entire function to calculate new MIDI stuff?
    -- MIDI stuff might be changed if the mouse has moved, mousebutton has been clicked, or mousewheel has scrolled, so need to re-calculate.
    -- Otherwise, mustCalculate remains nil, and can skip to end of function.
    local mustCalculate = false
    local prevCycleTime = thisCycleTime or startTime
    thisCycleTime = reaper.time_precise()
    dragTimeStarted = dragTimeStarted or (reaper.time_precise() > startTime + dragTime)  -- No need to call time_precise if dragTimeStarted already true

    -- KEYBOARD: Script can be terminated by pressing key twice to start/stop, or by holding key and releasing after dragTime
    local prevKeyState = keyState
    keyState = reaper.JS_VKeys_GetState(startTime-0.5):sub(VKLow, VKHi)
    if dragTimeStarted and keyState ~= prevKeyState and keyState == VKState0 then -- Only lift after every key has been lifted, to avoid immediately trigger action again. NOTE: modifier keys don't always send repeat KEYDOWN if held together with another key.
        return false
    end
    local keyDown = reaper.JS_VKeys_GetDown(prevCycleTime):sub(VKLow, VKHi)
    if keyDown ~= prevKeyState and keyDown ~= VKState0 then
        local p = 0
        ::checkNextKeyDown:: do
            p = keyDown:find("\1", p+1)
            if p then 
                if prevKeyState:byte(p) == 0 then 
                    return false 
                else 
                    goto checkNextKeyDown 
                end
            end
        end
    end
    
    -- EXTSTATE: Other scripts can communicate with and control the other js_ scripts via ExtStates
    local extState = reaper.GetExtState("js_Mouse actions", "Status") or ""
    if extState == "" or extState == "Must quit" then return(false) end
    
    -- MOUSE MODIFIERS / LEFT CLICK: (If the left mouse button or any modifier key is pressed, after first releasing them, quit.)
    -- This can detect left clicks even if the mouse is outside the MIDI editor
    local prevMouseState = mouseState or 0xFF
    mouseState = reaper.JS_Mouse_GetState(0xFF)
    if (mouseState&61) > (prevMouseState&61) -- 61 = 0b00111101 = Ctrl | Shift | Alt | Win | Left button
    or (dragTimeStarted and (mouseState&1) < (prevMouseState&1)) then
        return false
    end
    
    -- MOUSE POSITION: (New versions of the script doesn't quit if mouse moves out of CC lane, but will still quit if moves out of original window.)
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

    --[[ MOUSEWHEEL: This script is not controlled by the mousewheel, but mousewheel+modifier should still terminate
    local peekOK, pass, time, keys, delta = reaper.JS_WindowMessage_Peek(windowUnderMouse, "WM_MOUSEWHEEL")
    if not (peekOK and time > prevMouseTime) then 
        peekOK, pass, time, keys, delta = reaper.JS_WindowMessage_Peek(windowUnderMouse, "WM_MOUSEHWHEEL")
    end 
    if peekOK and time > prevMouseTime + 0.25 and keys&12 ~= 0 then -- Quit if wheel + modifier key
        return false
    end]]
    
    -- LEFT CLICK: (If the left mouse button or any modifier key is pressed, after first releasing them, quit.)
    peekOK, pass, time = reaper.JS_WindowMessage_Peek(windowUnderMouse, "WM_LBUTTONDOWN")
    if peekOK and time > startTime then return false end
    
    -- MIDDLE BUTTON: (Middle button changes curve shape.)
    peekOK, pass, time = reaper.JS_WindowMessage_Peek(windowUnderMouse, "WM_MBUTTONDOWN")
    if peekOK and time > prevMouseTime then 
        curveType = not curveType
        prevMouseTime = time
        mustCalculate = true
    end
 
    -- RIGHT CLICK: Toggle warp both directions -- while right button is held down
    if mouseState&2 == 2 then
        if warpUPDOWN or canWarpBothDirections then warpBOTH = true end
    else
        warpBOTH = false
    end
    
    -- TAKE STILL VALID:
    if not reaper.ValidatePtr2(0, activeTake, "MediaItem_Take*") then return false end
    
    
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
        if warpUPDOWN or warpBOTH then -- needs CC value
            if isInline then
                -- reaper.BR_GetMouseCursorContext was already called above
                _, _, mouseNewPitch, mouseNewCCLane, mouseNewCCValue, mouseNewCCLaneID = reaper.BR_GetMouseCursorContext_MIDI()
                -- Convert BR function's laneID return value to same as this script's GetCCLaneIDFromPoint
                if details == "cc_lane" and mouseNewCCValue == -1 then mouseNewCCLaneID = mouseNewCCLaneID - 0.5 end  
                if mouseNewCCLaneID     > mouseOrigCCLaneID 
                    then mouseNewCCValue = laneMinValue
                elseif mouseNewCCLaneID < mouseOrigCCLaneID or mouseNewCCValue == -1 
                    then mouseNewCCValue = laneMaxValue
                end
            else
                if mouseOrigPitch and mouseOrigPitch ~= -1 then
                    mouseNewPitch = ME_TopPitch -(mouseY - tME_Lanes[-1].ME_TopPixel) / ME_PixelsPerPitch
                    if mouseNewPitch > ME_TopPitch then mouseNewPitch = ME_TopPitch
                    elseif mouseNewPitch < ME_BottomPitch then mouseNewPitch = ME_BottomPitch
                    else mouseNewPitch = m_floor(mouseNewPitch + 0.5)
                    end
                    mouseNewPitch = -1
                elseif mouseOrigCCValue and mouseOrigCCValue ~= -1 then      
                    mouseNewPitch = -1                               
                    mouseNewCCValue = laneMinValue + (laneMaxValue-laneMinValue) * (mouseY - tME_Lanes[mouseOrigCCLaneID].ME_BottomPixel) / (tME_Lanes[mouseOrigCCLaneID].ME_TopPixel - tME_Lanes[mouseOrigCCLaneID].ME_BottomPixel)
                    -- In some scripts, the mouse CC value may go beyond lane limits
                    if mouseNewCCValue      > laneMaxValue  then mouseNewCCValue = laneMaxValue
                    elseif mouseNewCCValue  < laneMinValue  then mouseNewCCValue = laneMinValue
                    else mouseNewCCValue = m_floor(mouseNewCCValue+0.5)
                    end
                end
            end
        end   
        
        -- MOUSE NEW TICK / PPQ VALUE (horizontal position)
        if warpLEFTRIGHT or warpBOTH then-- warpLEFTRIGHT, needs PPQ pos
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
            mouseOrigPPQPos = m_max(minimumTick, m_min(maximumTick, mouseOrigPPQPos))
        end
                

        -- CALCULATE NEW MIDI DATA! and write the tableEditedMIDI!
        -- The warping uses a power function, and the power variable is determined
        --     by calculating to what power 0.5 must be raised to reach the 
        --     mouse's deviation to the left or right from its starting PPQ position. 
        -- The reason why 0.5 was chosen, was so that the CC in the middle of the range
        --     would follow the mouse position.
        -- The PPQ range of the selected events is used as reference to calculate
        --     magnitude of mouse movement.
        
        local newValue, power, mouseRelativeMovement
        if warpUPDOWN or warpBOTH then
            tV = {}
            local mouseRelativeMovement = (mouseNewCCValue-mouseOrigCCValue)/(laneMaxValue-laneMinValue) -- Positive if moved to right, negative if moved to left
            -- Prevent warping too much, so that all CCs don't end up in a solid block
            if mouseRelativeMovement > 0.49 then mouseRelativeMovement = 0.49 elseif mouseRelativeMovement < -0.49 then mouseRelativeMovement = -0.49 end
            if curveType then
                power = math.log(0.5 + mouseRelativeMovement, 0.5)
            else
                power = math.log(0.5 - mouseRelativeMovement, 0.5)
            end
                        
            for i = 1, #tValues do                             
                if mouseMovement == 0 then
                    newValue = tValues[i]
                elseif curveType then 
                    newValue = origValueMin + (((tValues[i] - origValueMin)/origValueRange)^power)*origValueRange          
                else -- mouseMovement > 0
                    newValue = origValueMax - (((origValueMax - tValues[i])/origValueRange)^power)*origValueRange           
                end
                if newValue > laneMaxValue then newValue = laneMaxValue
                elseif newValue < laneMinValue then newValue = laneMinValue
                else newValue = m_floor(newValue + 0.5)
                end       
                tV[i] = newValue
            end
        end
        
        if warpLEFTRIGHT or warpBOTH then  
            tP = {}
            mouseRelativeMovement = (mouseNewPPQPos-mouseOrigPPQPos)/origPPQRange
            -- Prevent warping too much, so that all CCs don't end up in a solid block
            if mouseRelativeMovement > 0.49 then mouseRelativeMovement = 0.49 elseif mouseRelativeMovement < -0.49 then mouseRelativeMovement = -0.49 end
            if curveType then
                power = math.log(0.5 + mouseRelativeMovement, 0.5)
            else
                power = math.log(0.5 - mouseRelativeMovement, 0.5)
            end
    
            for i = 1, #tTicks do
                if mouseMovement == 0 then
                    tP[i] = tTicks[i]
                elseif curveType then --mouseMovement < 0 then
                    tP[i] = m_floor(origPPQLeftmost + (((tTicks[i] - origPPQLeftmost)/origPPQRange)^power)*origPPQRange + 0.5)
                else -- mouseMovement > 0
                    tP[i] = m_floor(origPPQRightmost - (((origPPQRightmost - tTicks[i])/origPPQRange)^power)*origPPQRange + 0.5)
                end 
            end
        end
                

        tableEditedMIDI = {} -- Clean previous tableEditedMIDI
        local c = 0 -- Count index inside tableEditedMIDI - strangely, this is faster than using table.insert or even #tableEditedMIDI+1
        local offset, newPPQPos, noteOffPPQPos, newNoteOffPPQPos
        lastPPQPos = 0
        
        for i = 1, #tTicks do

            offset = tP[i] - lastPPQPos
            lastPPQPos = tP[i] 
                
            if not canWarpBothDirections then
            
                if tNoteLengths[i] then -- note event (if laneIsALL, not all i's may refer to note events)
                
                    noteOffPPQPos = tTicks[i] + tNoteLengths[i]
                    
                    if mouseMovement == 0 then
                        newNoteOffPPQPos = noteOffPPQPos
                    elseif curveType then --mouseMovement < 0 then
                        newNoteOffPPQPos = m_floor(origPPQLeftmost + (((noteOffPPQPos - origPPQLeftmost)/origPPQRange)^power)*origPPQRange + 0.5)
                    else -- mouseMovement > 0
                        newNoteOffPPQPos = m_floor(origPPQRightmost - (((origPPQRightmost - noteOffPPQPos)/origPPQRange)^power)*origPPQRange + 0.5)
                    end
                    lastPPQPos = newNoteOffPPQPos
                    
                    -- Insert note-on 
                    c = c + 1 
                    tableEditedMIDI[c] = s_pack("i4Bs4", offset, tFlags[i], tMsg[i])    
                    -- Since REAPER v5.32, notation (if it exists) must always be inserted *after* its note-0n
                    if tNotation[i] then
                        c = c + 1
                        tableEditedMIDI[c] = s_pack("I4Bs4", 0, tFlags[i]&0xFE, tNotation[i])
                    end    
                    -- Insert note-off
                    c = c + 1
                    tableEditedMIDI[c] = s_pack("i4Bs4", newNoteOffPPQPos - tP[i], tFlags[i], tMsgNoteOffs[i]) --tableEditedMIDI[c] = s_pack("i4BI4BBB", newNoteOffPPQPos - newPPQPos, tFlags[i], 3, 0x80 | (tMsg[i]:byte(1) & 0x0F), tMsg[i]:byte(2), 0)           
                     
                else -- All other lane types
                
                    c = c + 1
                    tableEditedMIDI[c] = s_pack("i4Bs4", offset, tFlags[i], tMsg[i])
                    
                    if tMsgLSB[i] then -- Only if laneIs14BIT then tMsgLSB will contain entries 
                        c = c + 1
                        tableEditedMIDI[c] = s_pack("i4Bs4", 0, tFlagsLSB[i], tMsgLSB[i])
                    end
                end

            -- Stuff that can be warped in both directions: use tV[i] instead of original msg
            else
            
                if laneIsCC7BIT then
                    c = c + 1
                    tableEditedMIDI[c] = s_pack("i4BI4BBB", offset, tFlags[i], 3, 0xB0 | tChannels[i], mouseOrigCCLane, tV[i]) .. tMsg[i]:sub(4, nil)
                elseif laneIsPITCH then
                    c = c + 1
                    tableEditedMIDI[c] = s_pack("i4BI4BBB", offset, tFlags[i], 3, 0xE0 | tChannels[i], tV[i]&127, tV[i]>>7) .. tMsg[i]:sub(4, nil)
                elseif laneIsCC14BIT then
                    c = c + 1
                    tableEditedMIDI[c] = s_pack("i4BI4BBB", offset, tFlags[i], 3, 0xB0 | tChannels[i], mouseOrigCCLane-256, tV[i]>>7) .. tMsg[i]:sub(4, nil)
                    c = c + 1
                    tableEditedMIDI[c] = s_pack("i4BI4BBB", 0  , tFlagsLSB[i], 3, 0xB0 | tChannels[i], mouseOrigCCLane-224, tV[i]&127) .. tMsgLSB[i]:sub(4, nil)
                elseif laneIsVELOCITY then
                    -- Insert note-on
                    c = c + 1 
                    tableEditedMIDI[c] = s_pack("i4BI4BBB", offset, tFlags[i], 3, 0x90 | tChannels[i], tPitches[i], tV[i]) .. tMsg[i]:sub(4, nil)
                    -- Since REAPER v5.32, notation (if it exists) must always be inserted *after* its note-0n
                    if tNotation[i] then
                        c = c + 1
                        tableEditedMIDI[c] = s_pack("I4Bs4", 0, tFlags[i]&0xFE, tNotation[i])
                    end
                    -- Insert note-off
                    c = c + 1
                    tableEditedMIDI[c] = s_pack("i4Bs4", tNoteLengths[i], tFlags[i], tMsgNoteOffs[i])
                    lastPPQPos = lastPPQPos + tNoteLengths[i]
                elseif laneIsOFFVEL then
                    -- Insert note-on
                    c = c + 1 
                    tableEditedMIDI[c] = s_pack("i4Bs4", offset, tFlags[i], tMsg[i]) 
                    -- Since REAPER v5.32, notation (if it exists) must always be inserted *after* its note-0n
                    if tNotation[i] then
                        c = c + 1
                        tableEditedMIDI[c] = s_pack("I4Bs4", 0, tFlags[i]&0xFE, tNotation[i])
                    end
                    -- Insert note-off
                    c = c + 1
                    tableEditedMIDI[c] = s_pack("i4Bi4BBB", tNoteLengths[i], tFlags[i], 3, 0x80 | tChannels[i], tPitches[i], tV[i]) .. tMsgNoteOffs[i]:sub(4, nil)
                    lastPPQPos = lastPPQPos + tNoteLengths[i]
                elseif laneIsCHANPRESS then
                    c = c + 1
                    tableEditedMIDI[c] = s_pack("i4BI4BB",  offset, tFlags[i], 2, 0xD0 | tChannels[i], tV[i]) .. tMsg[i]:sub(3, nil) -- NB Channel Pressure uses only 2 bytes!
                elseif laneIsPROGRAM then
                    c = c + 1
                    tableEditedMIDI[c] = s_pack("i4BI4BB",  offset, tFlags[i], 2, 0xC0 | tChannels[i], tV[i]) .. tMsg[i]:sub(3, nil) -- NB Channel Pressure uses only 2 bytes!
                end 
            end 
            
        end -- for i = 1, #tValues
                     
    
        -- DRUMROLL... write the edited events into the MIDI chunk!
        reaper.MIDI_SetAllEvts(activeTake, table.concat(tableEditedMIDI) .. s_pack("i4Bs4", -lastPPQPos, 0, "") .. remainMIDIString)

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


--##########################################################################
----------------------------------------------------------------------------
function AtExit()    

    -- Remove intercepts, restore original intercepts.  Do this first, because these are most important to restore, in case anything else goes wrong during AtExit.
    if interceptKeysOK ~= nil then pcall(function() reaper.JS_VKeys_Intercept(-1, -1) end) end
    if bitmap then reaper.JS_LICE_DestroyBitmap(bitmap) end -- The ReaScriptAPI extension will automatically un-composite the bitmap
    if pcallInterceptWM_OK ~= nil then -- If these are nil, that part of MAIN wasn't reached
        if not (pcallInterceptWM_OK and pcallInterceptWM_Retval) then -- Either an exception or some other error
            reaper.JS_WindowMessage_ReleaseWindow(windowUnderMouse) 
            reaper.MB("Intercepting window messages failed.\n\nAll intercepts for the window under the mouse will be released. (This may affect other scripts that are currently monitoring this window.)", "ERROR", 0) 
        elseif windowUnderMouse and reaper.ValidatePtr(windowUnderMouse, "HWND") then --(isInline or (editor and reaper.MIDIEditor_GetMode(editor) ~= -1)) then
            for message, passthrough in pairs(tWM_Messages) do
                if passthrough then 
                    reaper.JS_WindowMessage_PassThrough(windowUnderMouse, message, true)
                else
                    reaper.JS_WindowMessage_Release(windowUnderMouse, message)    
                end
            end
        end
    end
    
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
    
    -- Communicate with the js_Run.. script that this script is exiting
    reaper.DeleteExtState("js_Mouse actions", "Status", true)    
    
    -- Before getting to errors in MAIN, clean up stuff that could have been changed in MAIN
    if not mainOK then
        reaper.MB("The script encountered an error during startup:\n\n"
                .. tostring(mainRetval)
                .."\n\nPlease report these details in the \"MIDI Editor Tools\" thread in the REAPER forums."
                , "ERROR", 0)
    end
    
    -- Was an active take found, and does it still exist?  If not, don't need to do anything to the MIDI.
    if reaper.ValidatePtr2(0, activeTake, "MediaItem_Take*") and reaper.TakeIsMIDI(activeTake) then
        -- DEFERLOOP_pcall was executed, and no exceptions encountered:
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
    --if pcallOK ~= nil then        
                  
        -- Write nice, informative Undo strings
        if warpLEFTRIGHT then 
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
        else -- warpUPDOWN
            if laneIsCC7BIT then
                undoString = "Warp values of 7-bit CC events in lane ".. tostring(mouseOrigCCLane)
            elseif laneIsCHANPRESS then
                undoString = "Warp values of channel pressure events"
            elseif laneIsCC14BIT then
                undoString = "Warp values of 14 bit-CC events in lanes ".. 
                                          tostring(mouseOrigCCLane-256) .. "/" .. tostring(mouseOrigCCLane-224)
            elseif laneIsPITCH then
                undoString = "Warp values of pitchwheel events"
            elseif laneIsVELOCITY then
                undoString = "Warp velocities of notes"
            elseif laneIsOFFVEL then
                undoString = "Warp off-velocities of notes"
            elseif laneIsPROGRAM then
                undoString = "Warp values of program select events"
            else
                undoString = "Warp event values"
            end   
        end   
        
        -- Undo_OnStateChange_Item is expected to be the fastest undo function, since it limits the info stored 
        --    in the undo point to changes in this specific item.
        if activeItem and reaper.ValidatePtr2(0, activeItem, "MediaItem*") then    
            if isInline then reaper.UpdateItemInProject(activeItem) end
            reaper.Undo_OnStateChange_Item(0, undoString, activeItem)
        else
            reaper.Undo_OnStateChange2(0, undoString)
        end
    --end    
    
    
    -- At the very end, no more notification windows will be opened, 
    --    so restore original focus - except if "Terminate script" dialog box is waiting for user
    if editor and reaper.MIDIEditor_GetMode(editor) == 0 then
        curForegroundWindow = reaper.JS_Window_GetForeground()
        if not (curForegroundWindow and reaper.JS_Window_GetTitle(curForegroundWindow) == reaper.JS_Localize("ReaScript task control", "common")) then
            reaper.JS_Window_SetForeground(editor)
            if midiview and reaper.ValidatePtr(midiview, "HWND") then reaper.JS_Window_SetFocus(midiview) end
    end end 
  
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
    --    then go in reverse direction, from bottom to top, calculating client coordinates.
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
        -- Note that on MacOS and Linux, a window may be flipped, so rectLeft may be larger than rectRight, for example.
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
        ME_BottomPitch = ME_TopPitch - m_floor(tME_Lanes[-1].ME_Height / ME_PixelsPerPitch)
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
    
    -- These functions are fast, but require complicated parsing of the MIDI string.
    -- The following tables with temporarily store data while parsing:
    local tableNoteOns = {} -- Store note-on position and pitch while waiting for the next note-off, to calculate note length
    local tableTempNotation = {} -- Store notation text while waiting for a note-on with matching position, pitch and channel
     tableCCMSB = {} -- While waiting for matching LSB of 14-bit CC: tableCCMSB[channel][PPQPos] = value
     tableCCLSB = {} -- While waiting for matching MSB of 14-bit CC: tableCCLSB[channel][PPQPos] = value
    if laneIsNOTES or laneIsALL then
        for chan = 0, 15 do
            tableNoteOns[chan] = {}
            tableTempNotation[chan] = {}
            for pitch = 0, 127 do
                tableNoteOns[chan][pitch] = {}
                tableTempNotation[chan][pitch] = {} -- tableTempNotation[channel][pitch][PPQPos] = notation text message
                for flags = 0, 32 do
                    tableNoteOns[chan][pitch][flags] = {} -- = {PPQPos, velocity} (note-off must match channel, pitch and flags)
                end
            end
        end
    elseif laneIsCC14BIT then
        for chan = 0, 15 do
            tableCCMSB[chan] = {} 
            tableCCLSB[chan] = {} 
            for flags = 1, 32 do
                tableCCMSB[chan][flags] = {} -- tableCCMSB[channel][flags][PPQPos] = MSBvalue
                tableCCLSB[chan][flags] = {} -- tableCCLSB[channel][flags][PPQPos] = LSBvalue
            end
        end
    end
    
    -- The abstracted info of targeted MIDI events (that will be edited) will be will be stored in
    --    several new tables such as tTicks and tValues.
    -- Clean up these tables in case starting again after sorting.
    tMsg = {}
    tMsgLSB = {}
    tMsgNoteOffs = {}
    tValues = {} -- CC values, 14bit CC combined values, note velocities
    tTicks = {}
    tChannels = {}
    tFlags = {}
    tFlagsLSB = {} -- In the case of 14bit CCs, mute/select status of the MSB
    tPitches = {} -- This table will only be filled if laneIsVELOCITY / laneIsPIANOROLL / laneIsOFFVEL / laneIsNOTES
    tNoteLengths = {}
    tNotation = {} -- Will only contain entries at those indices where the notes have notation
    
    -- The MIDI strings of non-targeted events will temnporarily be stored in a table, tableRemainingEvents[],
    --    and once all MIDI data have been parsed, this table (which excludes the strings of targeted events)
    --    will be concatenated into remainMIDIString.
    local tableRemainingEvents = {}    
     
    local runningPPQPos = 0 -- The MIDI string only provides the relative offsets of each event, sp the actual PPQ positions must be calculated by iterating through all events and adding their offsets
    local lastRemainPPQPos = 0 -- PPQ position of last event that was *not* targeted, and therefore stored in tableRemainingEvents.
    local mustUpdateNextOffset        
    local prevPos, nextPos, unchangedPos = 1, 1, 1 -- Keep record of position within MIDIString. unchangedPos is position from which unchanged events van be copied in bulk.
    local c = 0 -- Count index inside tables - strangely, this is faster than using table.insert or even #table+1
    local r = 0 -- Count inside tableRemainingEvents
    local offset, flags, msg -- MIDI data that will be unpacked for each event
    
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
    --      inserted individually into tableRemainingEvents, using s_pack.  Instead, they will be 
    --      inserted as blocks of multiple events, copied directly from MIDIString.  By so doing, the 
    --      number of table writes are lowered, the speed of table.concat is improved, and string.sub
    --      can be used instead of s_pack.
    
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
    --[[if laneIsBANKPROG then
    
        local MIDIrev = MIDIString:reverse()
        local matchProgStrRev = table.concat({"[",string.char(0xC0),"-",string.char(0xCF),"]",
                                                  s_pack("I4", 2):reverse(),
                                              "[",string.char(0x01, 0x03),"]"})
        local msg2string = string.char(0, 32):gsub("[%(%)%.%%%+%-%*%?%[%]%^]", "%%%0")
        local matchBankStrRev = table.concat({"[",msg2string,"]",
                                              "[",string.char(0xB0),"-",string.char(0xBF),"]", 
                                                  s_pack("I4", 3):reverse(),
                                              "[",string.char(0x01, 0x03),"]"})
        firstTargetPosReversedProg = MIDIrev:find(matchProgStrRev)
        firstTargetPosReversedBank = MIDIrev:find(matchBankStrRev)
        if firstTargetPosReversedProg and firstTargetPosReversedBank then 
            firstTargetPosReversed = m_min(MIDIlen-firstTargetPosReversedProg, MIDIlen-firstTargetPosReversedBank)
        elseif firstTargetPosReversedProg then firstTargetPosReversed = firstTargetPosReversedProg
        elseif firstTargetPosReversedBank then firstTargetPosReversed = firstTargetPosReversedBank
        end
              
    else ]]
    lastTargetStrPos = MIDIlen-12
    --[[if laneIsALL then
        lastTargetStrPos = MIDIlen-12
    else
        if laneIsCC7BIT then
            local msg2string = string.char(mouseOrigCCLane):gsub("[%(%)%.%%%+%-%*%?%[%]%^]", "%%%0") -- Replace magic characters.
            matchStrReversed = table.concat({"[",msg2string,"]",
                                                   "[",string.char(0xB0),"-",string.char(0xBF),"]", 
                                                       s_pack("I4", 3):reverse(),
                                                   "[",string.char(0x01, 0x03),"]"})    
        elseif laneIsPITCH then
            matchStrReversed = table.concat({"[",string.char(0xE0),"-",string.char(0xEF),"]",
                                                       s_pack("I4", 3):reverse(),
                                                   "[",string.char(0x01, 0x03),"]"})
        elseif laneIsNOTES then
            matchStrReversed = table.concat({"[",string.char(0x80),"-",string.char(0x9F),"]", -- Note-offs and note-ons in all channels.
                                                       s_pack("I4", 3):reverse(),
                                                   "[",string.char(0x01, 0x03),"]"})
        elseif laneIsCHANPRESS then
            matchStrReversed = table.concat({"[",string.char(0xD0),"-",string.char(0xDF),"]",
                                                       s_pack("I4", 2):reverse(),
                                                   "[",string.char(0x01, 0x03),"]"})                                      
        elseif laneIsCC14BIT then
            local MSBlane = mouseOrigCCLane - 256
            local LSBlane = mouseOrigCCLane - 224
            local msg2string = string.char(MSBlane, LSBlane):gsub("[%(%)%.%%%+%-%*%?%[%]%^]", "%%%0")
            matchStrReversed = table.concat({"[",msg2string,"]",
                                                   "[",string.char(0xB0),"-",string.char(0xBF),"]", 
                                                       s_pack("I4", 3):reverse(),
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
                                                       s_pack("I4", 2):reverse(),
                                                   "[",string.char(0x01, 0x03),"]"})                      
        end
    
        firstTargetPosReversed = MIDIString:reverse():find(matchStrReversed) -- Search backwards by using reversed string. 
        
        if firstTargetPosReversed then 
            lastTargetStrPos = MIDIlen - firstTargetPosReversed 
        else -- Found no targeted events
            lastTargetStrPos = 0
        end   
    end ]]
    
    ---------------------------------------------------------------------------------------------
    -- OK, got an upper limit.  Not iterate through MIDIString, until the upper limit is reached.
    while nextPos < lastTargetStrPos do
       
        local mustExtract = false
        local offset, flags, msg, channel
        
        prevPos = nextPos
        offset, flags, msg, nextPos = s_unpack("i4Bs4", MIDIString, prevPos)
        
        -- Check for unsorted MIDI
        if offset < 0 and prevPos > 1 then   
            -- The bugs in MIDI_Sort have been fixed in REAPER v5.32, so it should be save to use this function.
            if not haveAlreadyCorrectedOverlaps then
                reaper.MIDI_Sort(activeTake)
                haveAlreadyCorrectedOverlaps = true
                goto startAgain
            else -- haveAlreadyCorrectedOverlaps == true
                reaper.MB("Unsorted MIDI data has been detected."
                        .. "\n\nThe script has tried to sort the data, but was unsuccessful."
                        .. "\n\nSorting of the MIDI can usually be induced by any simple editing action, such as selecting a note."
                        , "ERROR", 0)
                return false
            end
        end         
        
        runningPPQPos = runningPPQPos + offset              

        -- Only analyze *selected* events - as well as notation text events (which are always unselected)
        if flags&1 == 1 and msg:len() ~= 0 and (editAllChannels or msg:byte(1)&0x0F == activeChannel or msg:byte(1)>>4 == 0x0F) then -- bit 1: selected
            --[[local eventType = (msg:byte(1))>>4
            local channel   = (msg:byte(1))&0xF
            local msg2      = msg:byte(2)
            local msg3      = msg:byte(3)
                ]]

            -- When stretching ALL events, note events (note-ons, note-offs and notation) must be separated from CCs,
            --    since these may have to be reversed.
            -- Note that notes and CCs will use the same tTicks, tMsg and tFlags, but only notes will use tableNotesLengths, tNotations etc.
            -- The note tables will therefore only contain entries at certain keys, not every key from 1 to #tTicks
            if laneIsALL 
            then
                -- Note-offs
                if ((msg:byte(1))>>4 == 8 or (msg:byte(3) == 0 and (msg:byte(1))>>4 == 9))
                then
                    local channel = msg:byte(1)&0x0F
                    local msg2 = msg:byte(2)
                    -- Check whether there was a note-on on this channel and pitch.
                    if not tableNoteOns[channel][msg2][flags].index then
                        reaper.MB("There appears to be orphan note-offs (probably caused by overlapping notes or unsorted MIDI data) in the active takes."
                                .. "\n\nIn particular, at position " 
                                .. reaper.format_timestr_pos(reaper.MIDI_GetProjTimeFromPPQPos(activeTake, runningPPQPos), "", 1)
                                .. "\n\nPlease remove these before retrying the script."
                                .. "\n\n"
                                , "ERROR", 0)
                        return false
                    else
                        mustExtract = true
                        tNoteLengths[tableNoteOns[channel][msg2][flags].index] = runningPPQPos - tableNoteOns[channel][msg2][flags].PPQ
                        tMsgNoteOffs[tableNoteOns[channel][msg2][flags].index] = msg
                        tableNoteOns[channel][msg2][flags] = {} -- Reset this channel and pitch
                    end
                                                                
                -- Note-Ons
                elseif (msg:byte(1))>>4 == 9 -- and msg3 > 0
                then
                    local channel = msg:byte(1)&0x0F
                    local msg2 = msg:byte(2)
                    if tableNoteOns[channel][msg2][flags].index then
                        reaper.MB("There appears to be overlapping notes among the selected notes."
                                .. "\n\nIn particular, at position " 
                                .. reaper.format_timestr_pos(reaper.MIDI_GetProjTimeFromPPQPos(activeTake, runningPPQPos), "", 1)
                                .. "\n\nThe action 'Correct overlapping notes' can be used to correct overlapping notes in the active take."
                                , "ERROR", 0)
                        return false
                    else
                        mustExtract = true
                        c = c + 1
                        tMsg[c] = msg
                        tTicks[c] = runningPPQPos
                        tFlags[c] = flags
                        -- Check whether any notation text events have been stored for this unique PPQ, channel and pitch
                        tNotation[c] = tableTempNotation[channel][msg2][runningPPQPos]
                        -- Store the index and PPQ position of this note-on with a unique key, so that later note-offs can find their matching note-on
                        tableNoteOns[channel][msg2][flags] = {PPQ = runningPPQPos, index = c}
                    end  
                    
                -- Other CCs  
                else
                    mustExtract = true
                    c = c + 1
                    tMsg[c] = msg
                    tTicks[c] = runningPPQPos
                    tFlags[c] = flags
                end
                                      
            elseif laneIsCC7BIT then if msg:byte(2) == mouseOrigCCLane and (msg:byte(1))>>4 == 11
            then
                mustExtract = true
                c = c + 1 
                tValues[c] = msg:byte(3)
                tTicks[c] = runningPPQPos
                tChannels[c] = msg:byte(1)&0x0F
                tFlags[c] = flags
                tMsg[c] = msg
                end 
                                
            elseif laneIsPITCH then if (msg:byte(1))>>4 == 14
            then
                mustExtract = true 
                c = c + 1
                tValues[c] = (msg:byte(3)<<7) + msg:byte(2)
                tTicks[c] = runningPPQPos
                tChannels[c] = msg:byte(1)&0x0F
                tFlags[c] = flags 
                tMsg[c] = msg        
                end                           
                                    
            elseif laneIsCC14BIT then 
                if msg:byte(2) == mouseOrigCCLane-224 and (msg:byte(1))>>4 == 11 -- 14bit CC, only the LSB lane
                then
                    mustExtract = true
                    local channel = msg:byte(1)&0x0F
                    -- Has a corresponding MSB value already been saved?  If so, combine and save in tValues.
                    --[[ Has another LSB already been found at this
                    local p = tableCCLSB[channel][flags][runningPPQPos] 
                    if p then
                        local i = p.index
                        if i then 
                            tValues[i] = (tValues[i]&0x80) | msg:byte(3)
                            tMsgLSB[i] = msg
                            tableCCLSB[channel][flags][runningPPQPos] = {message = msg, flags = flags, index = i}
                        else
                            tableCCLSB[channel][flags][runningPPQPos] = {message = msg, flags = flags}
                        end
                    end
                    if tableCCLSB[channel][runningPPQPos] then -- Whoops, more than one CC at the same tick position.  Simply delete the first one
                    ]]
                    local e = tableCCMSB[channel][flags][runningPPQPos]
                    if e then
                        c = c + 1
                        tValues[c] = ((e.message):byte(3)<<7) + msg:byte(3)
                        tTicks[c] = runningPPQPos
                        tFlags[c] = e.flags -- The MSB determines muting
                        tFlagsLSB[c] = flags
                        tChannels[c] = channel
                        tMsg[c] = e.message
                        tMsgLSB[c] = msg
                        tableCCMSB[channel][flags][runningPPQPos] = nil
                        tableCCLSB[channel][flags][runningPPQPos] = nil
                    else
                        tableCCLSB[channel][flags][runningPPQPos] = {message = msg, flags = flags}
                    end
                        
                elseif msg:byte(2) == mouseOrigCCLane-256 and (msg:byte(1))>>4 == 11 -- 14bit CC, only the MSB lane
                then
                    mustExtract = true
                    local channel = msg:byte(1)&0x0F
                    -- Has a corresponding LSB value already been saved?  If so, combine and save in tValues.
                    local e = tableCCLSB[channel][flags][runningPPQPos]
                    if e then
                        c = c + 1
                        tValues[c] = (msg:byte(3)<<7) + (e.message):byte(3)
                        tTicks[c] = runningPPQPos
                        tFlags[c] = flags
                        tChannels[c] = channel
                        tFlagsLSB[c] = e.flags
                        tMsg[c] = msg
                        tMsgLSB[c] = e.message
                        tableCCLSB[channel][flags][runningPPQPos] = nil -- delete record
                        tableCCMSB[channel][flags][runningPPQPos] = nil
                    else
                        tableCCMSB[channel][flags][runningPPQPos] = {message = msg, flags = flags}
                    end
                end
              
            -- Note-Offs
            elseif laneIsNOTES then 
                if ((msg:byte(1))>>4 == 8 or (msg:byte(3) == 0 and (msg:byte(1))>>4 == 9))
                then
                    local channel = msg:byte(1)&0x0F
                    local pitch = msg:byte(2)
                    -- Check whether there was a note-on on this channel and pitch.
                    if not tableNoteOns[channel][pitch][flags].index then
                        reaper.ShowMessageBox("There appears to be orphan note-offs (probably caused by overlapping notes or unsorted MIDI data) in the active takes."
                                              .. "\n\nIn particular, at position " 
                                              .. reaper.format_timestr_pos(reaper.MIDI_GetProjTimeFromPPQPos(activeTake, runningPPQPos), "", 1)
                                              .. "\n\nPlease remove these before retrying the script."
                                              .. "\n\n"
                                              , "ERROR", 0)
                        return false
                    else
                        mustExtract = true
                        local n = tableNoteOns[channel][pitch][flags]
                        tNoteLengths[n.index] = runningPPQPos - n.PPQ
                        tMsgNoteOffs[n.index] = s_pack("BBB", 0x80 | channel, pitch, msg:byte(3)) -- Replace possible note-on with vel=0 msg with proper note-off
                        if laneIsOFFVEL then tValues[n.index] = msg:byte(3) end
                        tableNoteOns[channel][pitch][flags] = {} -- Reset this channel and pitch
                    end
                                                                
                -- Note-Ons
                elseif (msg:byte(1))>>4 == 9 -- and msg3 > 0
                then
                    local channel = msg:byte(1)&0x0F
                    local pitch = msg:byte(2)
                    if tableNoteOns[channel][pitch][flags].index then
                        reaper.ShowMessageBox("There appears to be overlapping notes among the selected notes."
                                              .. "\n\nIn particular, at position " 
                                              .. reaper.format_timestr_pos(reaper.MIDI_GetProjTimeFromPPQPos(activeTake, runningPPQPos), "", 1)
                                              .. "\n\nThe action 'Correct overlapping notes' can be used to correct overlapping notes in the active take."
                                              , "ERROR", 0)
                        return false
                    else
                        mustExtract = true
                        c = c + 1
                        tMsg[c] = msg
                        tValues[c] = msg:byte(3)
                        tTicks[c] = runningPPQPos
                        tPitches[c] = pitch
                        tChannels[c] = channel
                        tFlags[c] = flags
                        -- Check whether any notation text events have been stored for this unique PPQ, channel and pitch
                        tNotation[c] = tableTempNotation[channel][pitch][runningPPQPos]
                        -- Store the index and PPQ position of this note-on with a unique key, so that later note-offs can find their matching note-on
                        tableNoteOns[channel][pitch][flags] = {PPQ = runningPPQPos, index = c}
                    end  
                end

                
            elseif laneIsPROGRAM then if (msg:byte(1))>>4 == 12
            then
                mustExtract = true
                c = c + 1
                tValues[c] = msg:byte(2)
                tTicks[c] = runningPPQPos
                tChannels[c] = msg:byte(1)&0x0F
                tFlags[c] = flags
                tMsg[c] = msg
                end
                
            elseif laneIsCHANPRESS then if (msg:byte(1))>>4 == 13
            then
                mustExtract = true
                c = c + 1
                tValues[c] = msg:byte(2)
                tTicks[c] = runningPPQPos
                tChannels[c] = msg:byte(1)&0x0F
                tFlags[c] = flags
                tMsg[c] = msg
                end
                
            elseif laneIsBANKPROG then if ((msg:byte(1))>>4 == 12 or ((msg:byte(1))>>4 == 11 and (msg:byte(2) == 0 or msg:byte(2) == 32)))
            then
                mustExtract = true
                c = c + 1
                tTicks[c] = runningPPQPos
                tChannels[c] = msg:byte(1)&0x0F
                tFlags[c] = flags
                tMsg[c] = msg
                end
                         
            elseif laneIsTEXT then if msg:byte(1) == 0xFF --and not (msg2 == 0x0F) -- text event (0xFF), excluding notation type (0x0F)
            then
                mustExtract = true
                c = c + 1
                tTicks[c] = runningPPQPos
                tFlags[c] = flags
                tMsg[c] = msg
                end
                                    
            elseif laneIsSYSEX then if (msg:byte(1))>>4 == 0xF and not (msg:byte(1) == 0xFF) then -- Selected sysex event (text events with 0xFF as first byte have already been excluded)
                mustExtract = true
                c = c + 1
                tTicks[c] = runningPPQPos
                tFlags[c] = flags
                tMsg[c] = msg
                end
            end  
            
        end -- if laneIsCC7BIT / CC14BIT / PITCH etc    
        
        -- Check notation text events
        if (laneIsNOTES or laneIsALL)
        and msg:byte(1) == 0xFF -- MIDI text event
        and msg:byte(2) == 0x0F -- REAPER's MIDI text event type
        then
            -- REAPER v5.32 changed the order of note-ons and notation events. So must search backwards as well as forward.
            local notationChannel, notationPitch = msg:match("NOTE (%d+) (%d+) ") 
            if notationChannel and (editAllChannels or notationChannel == activeChannel) then
                notationChannel = tonumber(notationChannel)
                notationPitch   = tonumber(notationPitch)
                -- First, backwards through notes that have already been parsed.
                for i = #tTicks, 1, -1 do
                    if tTicks[i] ~= runningPPQPos then 
                        break -- Go on to forward search
                    else
                        if tMsg[i]:byte(1) == 0x90 | notationChannel
                        and tMsg[i]:byte(2) == notationPitch
                        then
                            tNotation[i] = msg
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
                        and evMsg:byte(3) ~= 0 -- Note-ons with velocity == 0 are actually note-offs
                        then
                            -- Store this notation text with unique key so that future selected notes can find their matching notation
                            tableTempNotation[notationChannel][notationPitch][runningPPQPos] = msg
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
        --    in tableRemainingEvents?  Or update offset?
        if mustExtract then
            -- The chain of unchanged events is broken, so write to tableRemainingEvents
            if unchangedPos < prevPos then
                r = r + 1
                tableRemainingEvents[r] = MIDIString:sub(unchangedPos, prevPos-1)
            end
            unchangedPos = nextPos
            mustUpdateNextOffset = true
        elseif mustUpdateNextOffset then
            r = r + 1
            tableRemainingEvents[r] = s_pack("i4Bs4", runningPPQPos-lastRemainPPQPos, flags, msg)
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
        tableRemainingEvents[r] = s_pack("i4", runningPPQPos - lastRemainPPQPos) .. MIDIString:sub(nextPos+4) 
    else
        r = r + 1
        tableRemainingEvents[r] = MIDIString:sub(unchangedPos) 
    end
        
    ----------------------------------------------------------------------------
    -- The entire MIDI string has been parsed.  Now check that everything is OK. 
    --[[local lastEvent = tableRemainingEvents[#tableRemainingEvents]:sub(-12)
    if tableRemainingEvents[#tableRemainingEvents]:byte(-2) ~= 0x7B
    or (tableRemainingEvents[#tableRemainingEvents]:byte(-3))&0xF0 ~= 0xB0
    then
        reaper.ShowMessageBox("No All-Notes-Off MIDI message was found at the end of the take."
                              .. "\n\nThis may indicate a parsing error in script, or an error in the take."
                              , "ERROR", 0)
        return false
    end ]]          
    
    if #tTicks == 0 then -- Nothing to extract, so don't need to concatenate tableRemainingEvents
        remainOffset = s_unpack("i4", MIDIString, 1)
        remainMIDIString = MIDIString
        return true 
    end         

    
    -- Now check that the number of LSB and MSB events were nicely balanced. If they are, these tables should be empty
    if laneIsCC14BIT then
        for chan = 0, 15 do
            for flags = 1, 3, 2 do
                if next(tableCCLSB[chan][flags]) then
                    reaper.MB("There appears to be selected CCs in the LSB lane that do not have corresponding CCs in the MSB lane."
                            .. "\n\nThe script does not know whether these CCs should be included in the edits, so please deselect these before retrying the script.", "ERROR", 0)
                    return false
                end
                if next(tableCCMSB[chan][flags]) then
                    reaper.MB("There appears to be selected CCs in the MSB lane that do not have corresponding CCs in the LSB lane."
                            .. "\n\nThe script does not know whether these CCs should be included in the edits, so please deselect these before retrying the script.", "ERROR", 0)
                    return false
                end
            end
        end
    end    
        
    -- Check that every note-on had a corresponding note-off
    if (laneIsNOTES) and #tNoteLengths ~= #tValues then
        reaper.ShowMessageBox("There appears to be an imbalanced number of note-ons and note-offs.", "ERROR", 0)
        return false 
    end
    
    -- Calculate original PPQ ranges and extremes
    -- * THIS ASSUMES THAT THE MIDI DATA IS SORTED *
    if includeNoteOffsInPPQrange and (laneIsNOTES or laneIsALL) then
        origPPQLeftmost  = tTicks[1]
        origPPQRightmost = tTicks[#tTicks] -- temporary
        local noteEndPPQ
        for i = 1, #tTicks do
            if tNoteLengths[i] then -- laneIsALL event is a note
                noteEndPPQ = tTicks[i] + tNoteLengths[i]
                if noteEndPPQ > origPPQRightmost then origPPQRightmost = noteEndPPQ end
            end
        end
        origPPQRange = origPPQRightmost - origPPQLeftmost
    else
        origPPQLeftmost  = tTicks[1]
        origPPQRightmost = tTicks[#tTicks]
        origPPQRange     = origPPQRightmost - origPPQLeftmost
    end
    
    -- Calculate original event value ranges and extremes
    if laneIsTEXT or laneIsSYSEX or laneIsBANKPROG or laneIsALL then
        origValueRange = -1
    else
        origValueMin = math.huge
        origValueMax = -math.huge
        for i = 1, #tValues do
            if tValues[i] < origValueMin then origValueMin = tValues[i] end
            if tValues[i] > origValueMax then origValueMax = tValues[i] end
        end
        origValueRange     = origValueMax - origValueMin
        origValueLeftmost  = tValues[1]
        origValueRightmost = tValues[#tValues]
    end
                
    
    ------------------------
    -- Fiinally, return true
    -- When concatenating tableRemainingEvents, leave out the first remaining event's offset (first 4 bytes), 
    --    since this offset will be updated relative to the edited events' positions during each cycle.
    -- (The edited events will be inserted in the string before all the remaining events.)
    remainMIDIString = table.concat(tableRemainingEvents) 
    
    return true
end


--###################################################################
---------------------------------------------------------------------
-- Set this script as the armed command that will be called by the 
--    "js_Mouse editing - Run script that is armed in toolbar" script
function ArmToolbarButton()
    
    if not (sectionID and commandID) then
        _, _, sectionID, commandID = reaper.get_action_context()
        if sectionID == nil or commandID == nil or sectionID == -1 or commandID == -1 then
            reaper.MB("Could not determine the action context of the script.", "ERROR", 0)
            return false
        end  
    end

    -- Make doubly sure all previous scripts were properly deactivated (set to NO state, not merely OFF, otherwise right-click arming won't work)
    prevCommandIDs = reaper.GetExtState("js_Mouse actions", "Previous commandIDs") or ""
    for prevCommandID in prevCommandIDs:gmatch("%d+") do
        prevCommandID = tonumber(prevCommandID)
        if prevCommandID == commandID then
            alreadyGotOwnCommand = true
        else
            reaper.SetToggleCommandState(sectionID, prevCommandID, -1)
            reaper.RefreshToolbar2(sectionID, prevCommandID)
        end
    end
    if not alreadyGotOwnCommand then
        prevCommandIDs = prevCommandIDs .. tostring(commandID) .. "|"
        reaper.SetExtState("js_Mouse actions", "Previous commandIDs", prevCommandIDs, false)
    end
    
    -- Toggle arming
    armedCommand = tonumber(reaper.GetExtState("js_Mouse actions", "Armed commandID") or "")
    if armedCommand == commandID then -- already armed, so disarm
        reaper.DeleteExtState("js_Mouse actions", "Armed commandID", true)
        reaper.SetToggleCommandState(sectionID, commandID, -1)
        reaper.RefreshToolbar2(sectionID, commandID)
        Tooltip("All scripts disarmed")
    else
        -- In this version of the Mouse editing scripts, the toolbar button is activated in the MAIN function, so no need to do it here too.
        reaper.SetExtState("js_Mouse actions", "Armed commandID", tostring(commandID), false)
        --reaper.SetToggleCommandState(sectionID, commandID, 1)
        --reaper.RefreshToolbar2(sectionID, commandID)
        Tooltip("Armed:1-sided Warp")
    end

    -- Must notify the AtExit function that button should not be deactivated when exiting.
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
 
    -- Before doing anything that may terminate the script, use this trick to avoid automatically 
    --    creating undo states if nothing actually happened.
    -- Undo_OnStateChange will only be used if reaper.atexit(exit) has been executed
    --reaper.defer(function() end)     
    
    
    -- Check whether SWS and my own extension are available, as well as the required version of REAPER
    if not reaper.MIDI_DisableSort then
        reaper.MB("This script requires REAPER v5.974 or higher.", "ERROR", 0)
        return(false) 
    elseif not reaper.JS_VKeys_GetDown then
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
    
    
    -- GET MOUSE AND KEYBOARD STARTING STATE:
    -- as soon as possible.  Hopefully, if script is started with mouse click, mouse button will still be down.
    -- VKeys_Intercept is also urgent, because must prevent multiple WM_KEYDOWN message from being sent, which may trigger script termination.
    interceptKeysOK = (reaper.JS_VKeys_Intercept(-1, 1) > 0)
        if not interceptKeysOK then reaper.MB("Could not intercept keyboard input.", "ERROR", 0) return false end
    mouseState = reaper.JS_Mouse_GetState(0xFF)    
    mouseOrigX, mouseOrigY = reaper.GetMousePosition()
    startTime = reaper.time_precise()
    prevMouseTime = startTime + 0.5 -- In case mousewheel sends multiple messages, don't react to messages sent too closely spaced, so wait till little beyond startTime.
    keyState = reaper.JS_VKeys_GetState(-2):sub(VKLow, VKHi)
 
    
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
    --[[filename = filename:gsub("\\", "/") -- Change Windows format to cross-platform
    filename = filename:match("^.*/") -- Remove script filename, keeping directory
    filename = filename .. "js_Mouse editing - Warp left right - Orange.cur"
    cursor = reaper.JS_Mouse_LoadCursorFromFile(filename) -- The first time that the cursor is loaded in the session will be slow, but afterwards the extension will re-use previously loaded cursor
    if not cursor then cursor = reaper.JS_Mouse_LoadCursor(32646) end]] -- If .cur file unavailable, load Windows/swell 4-pointed arrow cursor, to indicate that mouse can move in any direction.
    cursor = reaper.JS_Mouse_LoadCursor(32646) -- Load Windows/swell 4-pointed arrow cursor, to indicate that mouse can move in any direction.
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
            if reaper.MIDIEditor_GetMode(parentWindow) == 0 then -- Got a window in a MIDI editor, piano roll mode
                isInline = false
                editor = parentWindow
                if windowUnderMouse == reaper.JS_Window_FindChildByID(parentWindow, 1001) then -- The piano roll child window, titled "midiview" in Windows.
                    midiview = windowUnderMouse
                    -- Always use client coordinates in MIDI editor
                    mouseOrigX, mouseOrigY = reaper.JS_Window_ScreenToClient(midiview, mouseOrigX, mouseOrigY)
                    
                    activeTake = reaper.MIDIEditor_GetTake(editor)
                    activeTakeOK = activeTake and reaper.ValidatePtr2(0, activeTake, "MediaItem_Take*") and reaper.TakeIsMIDI(activeTake)
                    if activeTakeOK then
                    
                        activeItem = reaper.GetMediaItemTake_Item(activeTake)
                        activeItemOK = activeItem and reaper.ValidatePtr(activeItem, "MediaItem*") 
                        if activeItemOK then 
                        
                            -- Get MIDI editor structure from chunk, and store in tME_Lanes table.
                            chunkStuffOK = SetupMIDIEditorInfoFromTakeChunk() 
                            if chunkStuffOK then
                                
                                mouseOrigCCLaneID = GetCCLaneIDFromPoint(mouseOrigX, mouseOrigY)                                
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
            
                window, segment, details = reaper.BR_GetMouseCursorContext()    
                editor, isInline, mouseOrigPitch, mouseOrigCCLane, mouseOrigCCValue, mouseOrigCCLaneID = reaper.BR_GetMouseCursorContext_MIDI() 
                -- Adjust mouseOrigCCLaneID to same values as returned by GetCCLaneIDFromPoint for MIDI editor.
                if details == "cc_lane" and mouseOrigCCValue == -1 then mouseOrigCCLaneID = mouseOrigCCLaneID - 0.5 end
                
                if isInline then
                    
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
    if laneIsNOTATION or laneIsMEDIAITEM then
        reaper.MB("This script cannot warp events in the notation or media item lanes."
                .. "\n\nTIPS:"
                .. "\n\nIf the mouse is positioned inside a CC lane when the script starts, only selected events in that single lane will be warped."
                .. "\n\nIf the mouse is positioned over the ruler or a lane divider when the script starts, all selected events in all lanes will be warped left/right together."
                .. "\n\nWhen warping single lanes, warp direction is determined by initial mouse movement -- either left/right or up/down."
                .. "\n\nEvents that do not have values, such as text or sysex, can only be warped left/right -- not up/down."
                , "ERROR", 0)
        return false
    end
    
    
    -- MOUSE STARTING PPQ VALUES
    -- Get mouse starting PPQ position -- AND ADJUST FOR LOOPING -- NB: This script does not require snap to grid
    if isInline then
        mouseOrigPPQPos = reaper.MIDI_GetPPQPosFromProjTime(activeTake, reaper.BR_GetMouseCursorContext_Position())
    elseif ME_TimeBase == "beats" then
        mouseOrigPPQPos = ME_LeftmostTick + mouseOrigX/ME_PixelsPerTick
    else -- ME_TimeBase == "time"
        mouseOrigPPQPos  = reaper.MIDI_GetPPQPosFromProjTime(activeTake, ME_LeftmostTime + mouseOrigX/ME_PixelsPerSecond )
    end
    -- In case the item is looped, adjust the mouse PPQ position to equivalent position in first iteration.
    --    * mouseOrigPPQPos will be contracted to (possibly looped) item visible boundaries
    --    * Then get tick position relative to start of loop iteration under mouse
    local itemStartTimePos = reaper.GetMediaItemInfo_Value(activeItem, "D_POSITION")
    local itemEndTimePos = itemStartTimePos + reaper.GetMediaItemInfo_Value(activeItem, "D_LENGTH")
    local itemFirstVisibleTick = math.ceil(reaper.MIDI_GetPPQPosFromProjTime(activeTake, itemStartTimePos)) 
    local itemLastVisibleTick = m_floor(reaper.MIDI_GetPPQPosFromProjTime(activeTake, itemEndTimePos))
    mouseOrigPPQPos = m_max(itemFirstVisibleTick, m_min(itemLastVisibleTick-1, mouseOrigPPQPos)) 
    -- Now get PPQ position relative to loop iteration under mouse
    -- Source length will be used in other context too: When script terminates, check that no inadvertent shifts in PPQ position occurred.
    if not sourceLengthTicks then sourceLengthTicks = reaper.BR_GetMidiSourceLenPPQ(activeTake) end
    loopStartPPQPos = (mouseOrigPPQPos // sourceLengthTicks) * sourceLengthTicks
    mouseOrigPPQPos = mouseOrigPPQPos - loopStartPPQPos  
    
    minimumTick = m_max(0, itemFirstVisibleTick)
    maximumTick = m_floor(m_min(itemLastVisibleTick, sourceLengthTicks-1)) -- I prefer not to draw any event on the same PPQ position as the All-Notes-Off
    mouseOrigPPQPos = m_max(minimumTick, m_min(maximumTick, mouseOrigPPQPos))


    -- GET AND PARSE MIDI:
    -- Time to process the MIDI of the take!
    -- As mentioned in the header, this script does not use the old-fashioned MIDI API functions such as 
    --    MIDI_InsertCC, since these functions are far too slow when dealing with thousands of events.
    if not GetAndParseMIDIString() then return false end
    -- !!!!!!!!!! Uniue to this script:
    if #tTicks < 2 or (#tTicks < 3 and not laneIsNOTES) then -- Two notes can be warped, but not two CCs
        reaper.MB("Could not find a sufficient number of selected events in the target lane(s)."
                .. "\n\nTIPS:"
                .. "\n\nIf the MIDI editor's filter is set to \"Edit only the active channel\", the script will only detect and edit events in the active MIDI channel."
                .. "\n\nIf the mouse is positioned inside a CC lane when the script starts, only selected events in that single lane will be warped."
                .. "\n\nIf the mouse is positioned over the ruler or a lane divider when the script starts, all selected events in all lanes will be warped left/right together."
                .. "\n\nWhen warping single lanes, warp direction is determined by initial mouse movement -- either left/right or up/down."
                .. "\n\nEvents that do not have values, such as text or sysex, can only be warped left/right -- not up/down."
                , "ERROR", 0)
        return(false)
    end
        
    
    -- UNIQUE TO THIS SCRIPT:
    
    -- Determine the direction of warping.
    -- Notes, sysex and text can only be warped left/right
    -- (To warp note pitches, use the built-in Arpeggiate mouse modifiers)
    -- For other lanes, warp direction depends on mouse movement, similar
    --    to the "move in one direction only" mouse modifiers.
    -- This part has been postponed till last, to give the user more time
    --    to move the mouse.
    if laneIsPIANOROLL or laneIsSYSEX or laneIsTEXT or laneIsBANKPROG or laneIsALL then
        warpLEFTRIGHT = true
        canWarpBothDirections = false
    else 
        canWarpBothDirections = true
        -- mouseXorig, mouseYorig = reaper.GetMousePosition() -- The starting pixel coordinates was already stored at the beginning of the script
        local mouseXmove, mouseYmove
        repeat
            local mouseX, mouseY = reaper.GetMousePosition()
            if midiview then mouseX, mouseY = reaper.JS_Window_ScreenToClient(midiview, mouseX, mouseY) end
            mouseXmove = math.abs(mouseX - mouseOrigX)
            mouseYmove = math.abs(mouseY - mouseOrigY)
        until (mouseXmove > mouseMovementResolution or mouseYmove > mouseMovementResolution) and mouseXmove ~= mouseYmove
        if mouseXmove > mouseYmove then warpLEFTRIGHT = true else warpUPDOWN = true end
    end   
    if warpUPDOWN then
        cursor = reaper.JS_Mouse_LoadCursor(503) -- REAPER's own arpeggiate up/down cursor
        if cursor then reaper.JS_Mouse_SetCursor(cursor) end
    else
        cursor = reaper.JS_Mouse_LoadCursor(502) -- REAPER's own arpeggiate left/right cursor
        if cursor then reaper.JS_Mouse_SetCursor(cursor) end
    end
    tV = tValues -- temporary values
    tP = tTicks -- temporary PPQ positions
      
    
    -- INTERCEPT WINDOW MESSAGES:
    -- Do the magic that will allow the script to track mouse button and mousewheel events!
    -- The code assumes that all the message types will be blocked.  (Scripts that pass some messages through, must use other code.)
    -- tWM_Messages entries that are currently being intercepted but passed through, will temporarily be blocked and then restored when the script terminates.
    -- tWM_Messages entries that are already being intercepted and blocked, do not need to be changed or restored, so will be deleted from the table.
    pcallInterceptWM_OK, pcallInterceptWM_Retval = pcall(function()
        for message in pairs(tWM_Messages) do 
            local interceptWM_OK = -1  
            interceptWM_OK = reaper.JS_WindowMessage_Intercept(windowUnderMouse, message, false)
            -- Is message type already being intercepted by another script?
            if interceptWM_OK == 0 then 
                local prevIntercepted, prevPassthrough = reaper.JS_WindowMessage_Peek(windowUnderMouse, message)
                if prevIntercepted then
                    if prevPassthrough == false then
                        interceptWM_OK = 1 
                        tWM_Messages[message] = nil -- No need to change or restore this message type
                    else
                        interceptWM_OK = reaper.JS_WindowMessage_PassThrough(windowUnderMouse, message, false)
                        tWM_Messages[message] = true
                    end
                end
            end
            -- Intercept OK?
            if interceptWM_OK ~= 1 then 
                return false
            end
        end
        return true
    end)
    if not (pcallInterceptWM_OK and pcallInterceptWM_Retval) then return false end
    
       
    ------------------------------------------------------------
    -- Finally, startup completed OK, so can continue with loop!
    return true 
    
end -- function Main()


--################################################
--------------------------------------------------
mainOK, mainRetval = pcall(MAIN)
if mainOK and mainRetval then DEFERLOOP_pcall() end -- START LOOPING!


