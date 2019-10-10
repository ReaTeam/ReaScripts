--[[
ReaScript name: js_Mouse editing - Arch and Tilt.lua
Version: 4.21
Author: juliansader 
Screenshot: http://stash.reaper.fm/28025/Arch%20events.gif
Website: http://forum.cockos.com/showthread.php?t=176878
Donation: https://www.paypal.me/juliansader
Provides: 
  [main=midi_editor,midi_inlineeditor] .
  js_Mouse editing - Arch and Tilt.cur
About:
  # DESCRIPTION
  
  Arch selected CCs or velocities in the lane under mouse towards mouse position, using a linear or power curve.
  
  If the mouse is outside the selected events' PPQ position range, the Arch curve is similar to a Tilt towards the mouse position.
  
  The shape of the curve can be changed with the mousewheel.
  
  * Useful for tweaking an existing, complex CC or velocity curve up or down, without having to re-draw the curve.
  * Useful for quickly applying and auditioning crescendo-decrescendo (fade-in and fade-out) curves.  
  
  
  # MOUSE EDITING SCRIPTS vs REAPER's LEFT-DRAG MOUSE MODIFIER ACTIONS
  
  The "js_Mouse editing" script resemble REAPER's own left-drag mouse modifier actions 
  (such as "Draw CCs", "Arpeggiate", "Paint notes", etc), in that the scripts follow mouse movement 
  and continue to run until the user stops the script.
  
  However, the scripts are more advanced than the native actions, in at least two ways:
  
     * The scripts' functioning (such as the ramp shape or the channel of inserted CCs) can be tweaked while the script is running, 
     using the mousewheel, mouse middle button and right button.
     
     * Whereas native actions can only be started and stopped by left-dragging and lifting the mouse button,
     the scripts be started and stopped in multiple ways, allowing a more customized and streamlined workflow.
     
     
  # INSTRUCTIONS
  
  1) Select events to be arched/tilted. (Note that the scripts obeys the MIDI editor's "Edit only active channel" setting.)
  2) Position mouse inside the lane. (After the script starts, the mouse may move out of the target lane.)
  3) Start script.
  4) Control script with mouse:
      * Mouse position determines position to arch towards.
      * Middle click switches between a linear/power curve and a sine curve.
      * Mousewheel tweaks the curve shape.
      
  
  # STARTING AND STOPPING THE SCRIPT
  
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
  
     * Keyboard: Pressing any key while the script is running.
     
     * Keyboard: Releasing the shortcut key after holding it down for more than one second.
         
  
  RUNNING THE SCRIPT FROM THE TOOLBAR
  
  Since the functioning of the script depends on initial mouse position (similar to some of REAPER's own mouse modifier actions, 
     or actions such as "Insert note at mouse cursor"), the script cannot be run from a toolbar button.  
     This problem is solved by "arming" toolbar buttons for delayed execution after moving the mouse into position:
     
     
     REAPER's NATIVE TOOLBAR ARMING
     
     REAPER natively provides a "toolbar arming" feature: right-click a toolbar button to arm its linked action
     (the button will light up with an alternative color), and then left-click to run the action 
     after moving the mouse into position over the piano roll.
     
     There are two niggles with this feature, though: 
     
     1) Left-drag is very sensitive: If the mouse is even slightly moved while left-clicking,
         the left-drag mouse modifier action will be run instead of the armed toolbar action; 
  
     2) Multiple clicks: The user has to right-click the toolbar (or press Esc) to disarm the toolbar and use left-click normally again,
         then right-click the toolbar again to use the script. 
         
         
     ALTERNATIVE TOOLBAR ARMING
     
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

      
  PERFORMANCE TIPS
  
  * The responsiveness of the MIDI editor is significantly influenced by the total number of events in 
      the visible and editable takes. If the MIDI editor is slow, try reducing the number of editable and visible tracks.
      
  * If the MIDI editor gets slow and jerky when a certain VST plugin is loaded, 
      check for graphics driver incompatibility by disabling graphics acceleration in the plugin.
]] 

--[[
  Changelog:
  * v4.00 (2019-01-19)
    + Updated for js_ReaScriptAPI extension.
  * v4.01 (2019-02-11)
    + Restore focus to original window, if script opened notification window.
  * v4.02 (2019-02-16)
    + Fixed: On Linux, crashing if editor closed while script is running.
    + Arching curve displayed in MIDI editor.
  * v4.03 (2019-03-02)
    + Fixed: If editor is docked, properly restore focus.
  * v4.11 (2019-03-05)
    + Compatible with macOS.
  * v4.20 (2019-04-25)
    + macOS and Linux: Draw guidelines on screen (as on Windows).
    + macOS and Linux: Load custom cursor, as on Windows.
    + Clicking armed toolbar button disarms script.
    + Improved starting/stopping: 1) Any keystroke terminates script; 2) Alternatively, hold shortcut for second and release to terminate.
  * v4.21 (2019-09-05)
    + Download custom cursor on macOS.
]]

-- USER AREA 
-- Settings that the user can customize

Guideline_Color_Top    = 0xFF00FF00 -- Format AARRGGBB
Guideline_Color_Bottom = 0xFF0000FF
    
-- End of USER AREA   


-- ################################################################################################
---------------------------------------------------------------------------------------------------
-- CONSTANTS AND VARIABLES (that modders may find useful)

-- The raw MIDI data string will be divided into substrings in tMIDI, which can be concatenated into a new edited MIDI string.
--    In order to easily edit selected target events' values (tick positions will not be altered by this script), 
--    each target event's value bytes will be a separate table entry.
-- tTargets will store the indices in tMIDI of these target entries, their original values, and their tick positions.
local MIDIString -- The original raw MIDI data returned by GetAllEvts
local tMIDI = {} -- tMIDI[#tMIDI+1] = MIDIString:sub(prevPos, pos-2);  tMIDI[#tMIDI+1] = msg:sub(-1)
local tTargets = {} -- tTargets[i] = {index = #tMIDI, val = msg:byte(3), ticks = ticks}

-- The original value and PPQ ranges of selected events in the target lane will be summarized in:
local origValueMin, origValueMax, origValueRange, origValueLeftmost, origValueRightmost
local origPPQleftmost, origPPQrightmost, origPPQrange
local includeNoteOffsInPPQrange = false -- ***** Should origPPQrange and origPPQrightmost take note-offs into account? Set this flag to true for scripts that stretch or warp note lengths. *****
 
-- Starting values and position of mouse 
-- Not all of these lanes will be used by all scripts.
-- mouseOrigCCLane: (CC0-127 = 7-bit CC, 0x100|(0-31) = 14-bit CC, 0x200 = velocity, 0x201 = pitch, 
--    0x202=program, 0x203=channel pressure, 0x204=bank/program select, 
--    0x205=text, 0x206=sysex, 0x207=off velocity)
local mouseOrigX, mouseOrigY = nil, nil
local laneMinValue, laneMaxValue -- The minimum and maximum values in the target lane
local mouseOrigCCLane, mouseOrigCCValue, mouseOrigPPQPos, mouseOrigPitch, mouseOrigCCLaneID
local snappedOrigPPQPos -- If snap-to-grid is enabled, these will give the closest grid PPQ to the left. (Swing is not implemented.)

-- This script can work in inline MIDI editors as well as the main MIDI editors
-- The two types of editors require some different code, though.  
-- In particular, if in an inline editor, functions from the SWS extension will be used to track mouse position.
-- In the main editor, WIN32/SWELL functions from the js_ReaScriptAPI extension will be used.
local isInline, editor = nil, nil

-- Tracking the new value and position of the mouse while the script is running
local mouseNewCCLane, mouseNewCCValue, mouseNewPPQPos, mouseNewPitch, mouseNewCCLaneID
local prevMouseX, prevMouseY, mouseX, mouseY
local snappedNewPPQPos 

-- The script can be controlled by mousewheel, mouse buttons an mouse modifiers.  These are tracked by the following variables.
local mouseState
local mousewheel = 1 -- Track mousewheel movement.  ***** This default value may change, depending on the script and formulas used. *****
local prevDelta = 0
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
local startTime, prevMousewheelTime = 0, 0
--local lastPPQPos -- to calculate offset to next CC
--local lastValue -- To compare against last value, if skipRedundantCCs

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
local m_cos = math.cos
local m_min = math.min
local m_max = math.max 
local m_pi  = math.pi

-- Window messages that will be intercepted while the script is running
local tWM_Messages = {WM_LBUTTONDOWN = false, WM_LBUTTONDBLCLK = false, WM_LBUTTONUP = false,
                      WM_MBUTTONDOWN = false, WM_MBUTTONDBLCLK = false, WM_MBUTTONUP = false,
                      WM_RBUTTONDOWN = false, WM_RBUTTONDBLCLK = false, WM_RBUTTONUP = false,
                      WM_NCMOUSEMOVE = false, -- I'm not sure... Does this prevent REAPER from changing the mouse cursor when it's over scrollbars?
                      WM_MOUSEWHEEL  = false, WM_MOUSEHWHEEL   = false,
                      WM_SETCURSOR   = false}
  

-- Unique to this script
local apexHeight = 0 -- How much is the CC under the mouse lifted or lowered
local baseShape = "power"
local Guides_LeftPixel, Guides_RightPixel, Guides_XStr, Guides_YStr_Top, Guides_YStr_Bottom = nil, nil, nil, nil, nil, nil, nil, nil
local tGuides_Ticks, tGuides_X = {}, {} -- Guide lines will be drawn between nodes spaced every 10 pixels. What are the tick positions of these pixels?
local Guides_COLOR_TOP    = tonumber(Guideline_Color_Top) or 0xFF00FF00 -- Format AARRGGBB
local Guides_COLOR_BOTTOM = tonumber(Guideline_Color_Bottom) or 0xFF0000FF
local macOS = reaper.GetOS():match("OSX")

  
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
local function DEFERLOOP_TrackMouseAndUpdateMIDI()

    -- Must the script go through the entire function to calculate new MIDI stuff?
    -- MIDI stuff might be changed if the mouse has moved, mousebutton has been clicked, or mousewheel has scrolled, so need to re-calculate.
    -- Otherwise, mustCalculate remains nil, and can skip to end of function.
    local mustCalculate = false
    
    -- Must the script terminate?
    -- There are several ways to terminate the script:  Any mouse button, mousewheel movement or modifier key will terminate the script;
    --   except unmodified middle button and unmodified mousewheel, which toggles or scrolls through options, respectively.
    -- This gives the user flexibility to control the script via keyboard or mouse, as desired.
    local prevCycleTime = thisCycleTime or startTime
    thisCycleTime = reaper.time_precise()
    dragTimeStarted = dragTimeStarted or (thisCycleTime > startTime + dragTime)
    
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
    
    -- MOUSE MODIFIERS / LEFT CLICK / LEFT DRAG: Script can be terminated by left-clicking twice to start/stop, or by holding left button and releasing after dragTime
    -- This can detect left clicks even if the mouse is outside the MIDI editor
    local prevMouseState = mouseState or 0xFF
    mouseState = reaper.JS_Mouse_GetState(0xFF)
    if ((mouseState&61) > (prevMouseState&61)) -- 61 = 0b00111101 = Ctrl | Shift | Alt | Win | Left button
    or (dragTimeStarted and (mouseState&1) < (prevMouseState&1)) then
        return false
    end
    
    -- MOUSE POSITION: (New versions of the script doesn't quit if mouse moves out of CC lane, but will still quit if moves too far out of midiview.
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
    
    -- MOUSEWHEEL
    local peekOK, pass, time, keys, delta = reaper.JS_WindowMessage_Peek(windowUnderMouse, "WM_MOUSEWHEEL")
    if not (peekOK and time > prevMouseTime) then 
        peekOK, pass, time, keys, delta = reaper.JS_WindowMessage_Peek(windowUnderMouse, "WM_MOUSEHWHEEL")
    end 
    if peekOK then
        if time <= prevMouseTime then
            if reaper.time_precise() - time > 0.5 then --<= prevMouseTime then 
                prevDelta = 0
            end
        else --if time > prevMouseTime then
            --if keys&12 ~= 0 then return false end -- Any modifier keys (may be sent from mouse) terminate script.
            -- Standardize delta values so that can compare with previous
            if apexHeight and apexHeight > 0 then delta = -delta end
            if macOS then delta = -delta end -- macOS mousewheel events use opposite sign
            local sameDirection = (delta*prevDelta > 0)
            --delta = ((delta > 0) and 1) or ((delta < 0) and -1) or 0
            -- Meradium's suggestion: If mousewheel is turned rapidly, make larger changes to the curve per defer cycle
            --local factor = ((delta == prevDelta) and (time-prevMouseTime < 1)) and 0.04/((time-prevMouseTime)) or 0.04
            if not (mousewheel == 1 and sameDirection and time < prevMouseTime + 1) then
                factor = sameDirection and factor*1.4 or 1.04
                local prevMousewheel = mousewheel
                mousewheel = ((delta > 0) and mousewheel*factor) or ((delta < 0) and mousewheel/factor) or mousewheel
                if (prevMousewheel < 1 and mousewheel >= 1) or (prevMousewheel > 1 and mousewheel <= 1) then mousewheel = 1; factor = 1.04 -- Prevent scrolling through 1, and round to 1
                elseif mousewheel < 0.025 then mousewheel = 0.025 
                elseif mousewheel > 40 then mousewheel = 40
                --elseif 0.962 < mousewheel and mousewheel < 1.04 then mousewheel = 1 -- Round to 1 if comes close
                end
                prevMouseTime = time 
                mustCalculate = true
            end
            prevDelta = delta
        end
    end
    
    --[[
    -- LEFT DRAG: (If the left button was kept pressed for 1 second or longer, or after moving the mouse 20 pixels, assume left-drag, so quit when lifting.)
    peekOK, pass, time, _, _, upX, upY = reaper.JS_WindowMessage_Peek(windowUnderMouse, "WM_LBUTTONUP")
    if peekOK and (time > startTime + 1.5
              or  (time > startTime and (upX < mouseOrigX-40 or upX > mouseOrigX+40 or upY < mouseOrigY-40 or upY > mouseOrigY+40))) then
        return false
    end
    
    -- LEFT CLICK: (If the left mouse button or any modifier key is pressed, after first releasing them, quit.)
    peekOK, pass, time = reaper.JS_WindowMessage_Peek(windowUnderMouse, "WM_LBUTTONDOWN")
    if peekOK and time > startTime then return false end]]
    
    -- MIDDLE BUTTON:
    peekOK, pass, time = reaper.JS_WindowMessage_Peek(windowUnderMouse, "WM_MBUTTONDOWN")
    if peekOK and time > prevMouseTime then 
        baseShape = (baseShape == "power") and "sine" or "power"
        Tooltip("Curve: "..baseShape)
        prevMouseTime = time
        mustCalculate = true
    end
    
    --[[ RIGHT CLICK: Not implemented in this script
    peekOK, pass, time = reaper.JS_WindowMessage_Peek(windowUnderMouse, "WM_RBUTTONDOWN")
    if peekOK and time > prevMouseTime then
        --
        prevMouseTime = time
        mustCalculate = true
    end]]
 
    -- TAKE STILL VALID:
    if not reaper.ValidatePtr2(0, activeTake, "MediaItem_Take*") then return false end
    
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
        --takeIsSorted = false -- Does the script scramble MIDI order?
        
        -----------------------------------------
        -- Get mouse CC value (vertical position)
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
            mouseNewCCValue = laneMinValue + (laneMaxValue-laneMinValue) * (tME_Lanes[mouseOrigCCLaneID].ME_BottomPixel - mouseY) / (tME_Lanes[mouseOrigCCLaneID].ME_BottomPixel - tME_Lanes[mouseOrigCCLaneID].ME_TopPixel)
        end
        if mouseNewCCValue > laneMaxValue then mouseNewCCValue = laneMaxValue
        elseif mouseNewCCValue < laneMinValue then mouseNewCCValue = laneMinValue
        else mouseNewCCValue = math.floor(mouseNewCCValue+0.5)
        end
    
        ------------------------------------------
        -- Get mouse new PPQ (horizontal) position
        -- (And prevent mouse line from extending beyond item boundaries.)
        if isInline then
            -- A call to BR_GetMouseCursorContext must always precede the other BR_ context calls
            mouseNewPPQPos = reaper.MIDI_GetPPQPosFromProjTime(activeTake, reaper.BR_GetMouseCursorContext_Position())
        elseif ME_TimeBase == "beats" then
            mouseNewPPQPos = ME_LeftmostTick + mouseX/ME_PixelsPerTick
        else -- ME_TimeBase == "time"
            mouseNewPPQPos = reaper.MIDI_GetPPQPosFromProjTime(activeTake, ME_LeftmostTime + mouseX/ME_PixelsPerSecond )
        end
        mouseNewPPQPos = mouseNewPPQPos - loopStartPPQPos -- Adjust mouse PPQ position for looped items
        mouseNewPPQPos = math.max(origPPQleftmost, math.min(origPPQrightmost, mouseNewPPQPos)) -- !!!!!!!!!!!! Unique to this script: limit PPQ pos to CC range, so that curve doesn't change the further mouse goes outside CC range
    
        ---------------------------------------------------------------
        -- Arching: 
        -- If mouse is within selected event' PPQ range, find the event that is nearest to left of mouse
        -- This event will be raised or lowered to the mouse posiion.
        --local origPPQleftmost, origPPQrightmost = tTargets[1].ticks, tTargets[#tTargets].ticks
        local ceilIndex, floorIndex, middleIndex
        if origPPQleftmost < mouseNewPPQPos and mouseNewPPQPos < origPPQrightmost then
            -- Use binary search to find event closest to left of mouse.        
            ceilIndex = #tTargets -- index of event with PPQ to right of mouse
            floorIndex = 1 -- index of event with PPQ to left of mouse
            while (ceilIndex-floorIndex)>1 do
                middleIndex = (ceilIndex+floorIndex)//2 -- middle index
                if tTargets[middleIndex].ticks > mouseNewPPQPos then
                    ceilIndex = middleIndex
                else
                    floorIndex = middleIndex
                end     
            end -- while (ceilIndex-floorIndex)>1        
            apexHeight = mouseNewCCValue - tTargets[floorIndex].val                                         
        elseif mouseNewPPQPos <= origPPQleftmost then
            apexHeight = mouseNewCCValue - tTargets[1].val
            ceilIndex = 1      
        else -- mouseNewPPQPos >= origPPQrightmost
            apexHeight = mouseNewCCValue - tTargets[#tTargets].val
            floorIndex = #tTargets
        end  
        
        -- Declaring these stuff local only speeds things up by less than 1/100th of a second.  And only when thousands of events are selected.
        local newValue    
        local leftPPQrange = mouseNewPPQPos - origPPQleftmost
        local rightPPQrange = origPPQrightmost - mouseNewPPQPos 
        
        -- A power > 1 gives a more musical shape, therefore the cases mouseWheel >= 1 and mouseWheel < 1 will be dealt with separately.
        -- If mouseWheel < 1, its inverse will be used as power.
        if mousewheel >= 1 then 
            if mouseNewPPQPos > origPPQleftmost then      
                for i = 1, floorIndex do
                    local CC = tTargets[i]
                    if baseShape == "power" then
                        newValue = CC.val + apexHeight*(((CC.ticks - origPPQleftmost)/leftPPQrange)^mousewheel)
                    else
                        sineValue = 0.5*(1-m_cos(m_pi*(CC.ticks - origPPQleftmost)/leftPPQrange))
                        newValue = CC.val + apexHeight*(sineValue^mousewheel)
                    end
                    if      newValue > laneMaxValue then newValue = laneMaxValue
                    elseif  newValue < laneMinValue then newValue = laneMinValue
                    else    newValue = math.floor(newValue+0.5)
                    end
                    if      laneIsCC14BIT then tMIDI[CC.indexMSB] = s_pack("B", newValue >> 7); tMIDI[CC.indexLSB] = s_pack("B", newValue & 127)
                    elseif  laneIsPITCH   then tMIDI[CC.index]    = s_pack("BB", newValue&127, newValue>>7)
                    else    tMIDI[CC.index] = s_pack("B", newValue)
                    end
                end
            end
            
            if mouseNewPPQPos < origPPQrightmost then                
                for i = ceilIndex, #tTargets do
                    local CC = tTargets[i]
                    if baseShape == "power" then
                        newValue = CC.val + apexHeight*(((origPPQrightmost - CC.ticks)/rightPPQrange)^mousewheel)
                    else
                        sineValue = 0.5*(1-m_cos(m_pi*(origPPQrightmost - CC.ticks)/rightPPQrange))
                        newValue = CC.val + apexHeight*(sineValue^mousewheel)
                    end
                    if      newValue > laneMaxValue then newValue = laneMaxValue
                    elseif  newValue < laneMinValue then newValue = laneMinValue
                    else    newValue = math.floor(newValue+0.5)
                    end
                    if      laneIsCC14BIT then tMIDI[CC.indexMSB] = s_pack("B", newValue >> 7); tMIDI[CC.indexLSB] = s_pack("B", newValue & 127)
                    elseif  laneIsPITCH   then tMIDI[CC.index]    = s_pack("BB", newValue&127, newValue>>7)
                    else    tMIDI[CC.index] = s_pack("B", newValue)
                    end
                end
            end
            
        else -- mousewheel < 1, so use inverse as power, and also change the sine formula
            local inverseWheel = 1.0/mousewheel
            
            if mouseNewPPQPos > origPPQleftmost then
                for i = 1, floorIndex do
                    local CC = tTargets[i]
                    if baseShape == "power" then
                        newValue = CC.val + apexHeight - apexHeight*(((mouseNewPPQPos - CC.ticks)/leftPPQrange)^inverseWheel)
                    else
                        sineValue = 0.5*(1-m_cos(m_pi*(mouseNewPPQPos - CC.ticks)/leftPPQrange))
                        newValue = CC.val + apexHeight - apexHeight*(sineValue^inverseWheel)
                    end
                    if      newValue > laneMaxValue then newValue = laneMaxValue
                    elseif  newValue < laneMinValue then newValue = laneMinValue
                    else    newValue = math.floor(newValue+0.5)
                    end
                    if      laneIsCC14BIT then tMIDI[CC.indexMSB] = s_pack("B", newValue >> 7); tMIDI[CC.indexLSB] = s_pack("B", newValue & 127)
                    elseif  laneIsPITCH   then tMIDI[CC.index]    = s_pack("BB", newValue&127, newValue>>7)
                    else    tMIDI[CC.index] = s_pack("B", newValue)
                    end          
                end
            end
            
            if mouseNewPPQPos < origPPQrightmost then
                for i = ceilIndex, #tTargets do
                    local CC = tTargets[i]
                    if baseShape == "power" then
                        newValue = CC.val + apexHeight - apexHeight*(((CC.ticks - mouseNewPPQPos)/rightPPQrange)^inverseWheel)
                    else
                        sineValue = 0.5*(1-m_cos(m_pi*(CC.ticks - mouseNewPPQPos)/rightPPQrange))
                        newValue = CC.val + apexHeight - apexHeight*(sineValue^inverseWheel)
                    end
                    if      newValue > laneMaxValue then newValue = laneMaxValue
                    elseif  newValue < laneMinValue then newValue = laneMinValue
                    else    newValue = math.floor(newValue+0.5)
                    end
                    if      laneIsCC14BIT then tMIDI[CC.indexMSB] = s_pack("B", newValue >> 7); tMIDI[CC.indexLSB] = s_pack("B", newValue & 127)
                    elseif  laneIsPITCH   then tMIDI[CC.index]    = s_pack("BB", newValue&127, newValue>>7)
                    else    tMIDI[CC.index] = s_pack("B", newValue)
                    end         
                end
            end -- if mouseNewPPQPos < origPPQrightmost
        end -- if mousewheel >= 1 then  
            
                    
        -----------------------------------------------------------
        -- DRUMROLL... write the edited events into the MIDI chunk!
        reaper.MIDI_SetAllEvts(activeTake, table.concat(tMIDI))
        if isInline then reaper.UpdateItemInProject(activeItem) end

        
        ----------------
        -- Guidelines
        if compositeOK then
            local tTopY = {}
            local tBottomY = {}
            local apexPixels = (apexHeight/laneMaxValue) * (ME_TargetTopPixel - ME_TargetBottomPixel)
            
            if mousewheel >= 1 then 
                if baseShape == "power" then
                    for i, ticks in ipairs(tGuides_Ticks) do
                        if ticks <= mouseNewPPQPos then
                            local s = (leftPPQrange == 0) and apexPixels or (apexPixels*(((ticks - origPPQleftmost)/leftPPQrange)^mousewheel))
                            tTopY[i] = ME_TargetTopPixel + s
                            tBottomY[i] = ME_TargetBottomPixel + 1 + s
                        else
                            local s = (rightPPQrange == 0) and apexPixels or (apexPixels*(((origPPQrightmost - ticks)/rightPPQrange)^mousewheel))
                            tTopY[i] = ME_TargetTopPixel + s
                            tBottomY[i] = ME_TargetBottomPixel + 1 + s
                        end
                    end
                else
                    for i, ticks in ipairs(tGuides_Ticks) do
                        if ticks <= mouseNewPPQPos then
                            local s = (leftPPQrange == 0) and apexPixels or (apexPixels*((0.5*(1-m_cos(m_pi*(ticks - origPPQleftmost)/leftPPQrange)))^mousewheel))
                            tTopY[i] = ME_TargetTopPixel + s
                            tBottomY[i] = ME_TargetBottomPixel + 1 + s
                        else
                            local s = (rightPPQrange == 0) and apexPixels or (apexPixels*((0.5*(1-m_cos(m_pi*(origPPQrightmost - ticks)/rightPPQrange)))^mousewheel))
                            tTopY[i] = ME_TargetTopPixel + s
                            tBottomY[i] = ME_TargetBottomPixel + 1 + s
                        end
                    end
                end
            else
                local inverseWheel = 1.0/mousewheel
                if baseShape == "power" then
                    for i, ticks in ipairs(tGuides_Ticks) do
                        if ticks <= mouseNewPPQPos then
                            local s = (leftPPQrange == 0) and apexPixels or (apexPixels - apexPixels*(((mouseNewPPQPos - ticks)/leftPPQrange)^inverseWheel))
                            tTopY[i] = ME_TargetTopPixel + s
                            tBottomY[i] = ME_TargetBottomPixel + 1 + s
                        else
                            local s = (rightPPQrange == 0) and apexPixels or (apexPixels - apexPixels*(((ticks - mouseNewPPQPos)/rightPPQrange)^inverseWheel))
                            tTopY[i] = ME_TargetTopPixel + s
                            tBottomY[i] = ME_TargetBottomPixel + 1 + s
                        end
                    end
                else
                    for i, ticks in ipairs(tGuides_Ticks) do
                        if ticks <= mouseNewPPQPos then
                            local s = (leftPPQrange == 0) and apexPixels or (apexPixels - apexPixels*((0.5*(1-m_cos(m_pi*(mouseNewPPQPos - ticks)/leftPPQrange)))^inverseWheel))
                            tTopY[i] = ME_TargetTopPixel + s
                            tBottomY[i] = ME_TargetBottomPixel + 1 + s
                        else
                            local s = (rightPPQrange == 0) and apexPixels or (apexPixels - apexPixels*((0.5*(1-m_cos(m_pi*(ticks - mouseNewPPQPos)/rightPPQrange)))^inverseWheel))
                            tTopY[i] = ME_TargetTopPixel + s
                            tBottomY[i] = ME_TargetBottomPixel + 1 + s
                        end
                    end
                end
            end
            
            reaper.JS_LICE_Clear(bitmap, 0)
            local x1, t1, b1 = tGuides_X[1], tTopY[1], tBottomY[1] -- Coordinates of left pixel of each line segment
            for i = 2, #tGuides_X do
                if x1 < mouseX and mouseX < tGuides_X[i] then -- To make sure than pointy curve is correctly drawn, even is point falls between 10-pixel segements, insert extra line
                    reaper.JS_LICE_Line(bitmap, x1, t1, mouseX, ME_TargetTopPixel+apexPixels,      Guides_COLOR_TOP, 1, "COPY", true)
                    reaper.JS_LICE_Line(bitmap, x1, b1, mouseX, ME_TargetBottomPixel+apexPixels+1, Guides_COLOR_BOTTOM, 1, "COPY", true)
                    x1, t1, b1 = mouseX, ME_TargetTopPixel+apexPixels, ME_TargetBottomPixel+apexPixels+1
                end
                x2, t2, b2 = tGuides_X[i], tTopY[i], tBottomY[i]
                reaper.JS_LICE_Line(bitmap, x1, t1, x2, t2, Guides_COLOR_TOP, 1, "COPY", true)
                reaper.JS_LICE_Line(bitmap, x1, b1, x2, b2, Guides_COLOR_BOTTOM, 1, "COPY", true)
                x1, t1, b1 = x2, t2, b2
            end

        end -- if compositeOK
        
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


--############################################################################################
----------------------------------------------------------------------------------------------
function AtExit()
    
    -- Remove intercepts, restore original intercepts.  Do this first, because these are most important to restore, in case anything else goes wrong during AtExit.
    if interceptKeysOK ~= nil then pcall(function() reaper.JS_VKeys_Intercept(-1, -1) end) end
    if bitmap then reaper.JS_LICE_DestroyBitmap(bitmap) end -- The extension will automatically un-composite the bitmap
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
    if origToggleState and sectionID and commandID and not leaveToolbarButtonArmed then
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
    if activeTake and reaper.ValidatePtr2(0, activeTake, "MediaItem_Take*") and reaper.TakeIsMIDI(activeTake) then
        -- DEFERLOOP_pcall was executed, and no exceptions encountered:
        if pcallOK then
            -- MIDI_Sort used to be buggy when dealing with overlapping or unsorted notes,
            --    causing infinitely extended notes or zero-length notes.
            -- Fortunately, these bugs were seemingly all fixed in v5.32.
            -- This script does not change MIDI order, so no need to sort.
            --reaper.MIDI_Sort(activeTake)
             
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
            reaper.MB("The script encountered an error:\n\n"
                    .. tostring(pcallRetval)
                    .."\n\nPlease report these details in the \"MIDI Editor Tools\" thread in the REAPER forums."
                    .."\n\n* The original, unaltered MIDI has been restored to the take."
                    , "ERROR", 0)
        end
    end -- if reaper.ValidatePtr2(0, "MediaItem_Take*", activeTake) and reaper.TakeIsMIDI(activeTake)
    
 
    -- if script reached DEFERLOOP_pcall (or the WindowMessage section), pcallOK ~= nil, and must create undo point:
    --if pcallOK ~= nil then
                  
        -- Write nice, informative Undo strings
        if laneIsCC7BIT then 
            undoString = "Arch 7-bit CCs in lane ".. tostring(mouseOrigCCLane)
        elseif laneIsCHANPRESS then
            undoString = "Arch channel pressure"
        elseif laneIsCC14BIT then
            undoString = "Arch 14-bit CCs in lanes ".. 
                                      tostring(mouseOrigCCLane-256) .. "/" .. tostring(mouseOrigCCLane-224)
        elseif laneIsPITCH then
            undoString = "Arch pitchwheel"
        elseif laneIsVELOCITY then
            undoString = "Arch note velocities"
        elseif laneIsPROGRAM then
            undoString = "Arch program select"
        else
            undoString = "Arch event values"
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
-- Returns true, laneType if CC lane could be parsed.
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

    local laneType = tME_Lanes[laneID] and tME_Lanes[laneID].Type
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


--##########################################################################
----------------------------------------------------------------------------
-- Parse MIDI string; store selected events' values
function GetAndParseMIDIString()

    -- If unsorted MIDI is encountered, this helper function will be called
    local TryToSort = {}
    setmetatable(TryToSort, {__index = function(t, i)
                                 -- The bugs in MIDI_Sort have been fixed in REAPER v5.32, so it should be save to use this function.
                                 if not haveAlreadySorted then
                                     reaper.MIDI_Sort(activeTake)
                                     haveAlreadySorted = true
                                     return true
                                 else -- haveAlreadySorted == true
                                     reaper.ShowMessageBox("Unsorted MIDI data has been detected."
                                                           .. "\n\nThe script has tried to sort the data, but was unsuccessful."
                                                           .. "\n\nSorting of the MIDI can usually be induced by any simple editing action, such as selecting a note."
                                                           , "ERROR", 0)
                                     return false
                                 end
                             end})
    
    ::startAgain::
    
    getAllEvtsOK, MIDIString = reaper.MIDI_GetAllEvts(activeTake, "")
        if not getAllEvtsOK then reaper.MB("MIDI_GetAllEvts could not load the raw MIDI data.", "ERROR", 0) return false end
        
    tTargets = {}
    tMIDI    = {}
    
    local t14 = {} -- Store index in tTargets of 14bit event at chan and tick: t14[chan][tick] = {indexMSB = ..., indexLSB = ..., val = ...}
        for chan = 0, 15 do t14[chan] = {} end
    
    local pos, prevPos = 1, 1 -- Positions inside MIDI string while parsing
    local ticks = 0 -- Running PPQ position of events while parsing
    local offset, flags, msg
    
    local MIDI, MIDILen = MIDIString, #MIDIString
    local targetLane = mouseOrigCCLane
      
    if laneIsCC7BIT then
        while pos < MIDILen do
            offset, flags, msg, pos = string.unpack("i4Bs4", MIDI, pos)
            if offset < 0 then if TryToSort[this] then goto startAgain else return false end end -- Check for unsorted MIDI
            ticks = ticks + offset
            if flags&1==1 and #msg >= 3 and msg:byte(2) == targetLane and (msg:byte(1))>>4 == 11 and (editAllChannels or msg:byte(1)&0x0F == activeChannel)
            then
                tMIDI[#tMIDI+1] = MIDI:sub(prevPos, pos-#msg+1)
                tMIDI[#tMIDI+1] = msg:sub(3, 3)
                prevPos = pos-#msg+3
                tTargets[#tTargets+1] = {index = #tMIDI, val = msg:byte(3), ticks = ticks}
            end
        end
    elseif laneIsCC14BIT then
        local targetLaneMSB, targetLaneLSB = targetLane-256, targetLane-224
        while pos < MIDILen do
            offset, flags, msg, pos = string.unpack("i4Bs4", MIDI, pos)
            if offset < 0 then if TryToSort[this] then goto startAgain else return false end end -- Check for unsorted MIDI
            ticks = ticks + offset
            if flags&1==1 and #msg >= 3 and (msg:byte(1))>>4 == 11 and (editAllChannels or msg:byte(1)&0x0F == activeChannel)
            then
                if msg:byte(2) == targetLaneMSB
                then
                    local chan = msg:byte(1)&0x0F
                    tMIDI[#tMIDI+1] = MIDI:sub(prevPos, pos-#msg+1)
                    tMIDI[#tMIDI+1] = msg:sub(3, 3)
                    prevPos = pos-#msg+3
                    -- Store value so that can later be combined with LSB
                    local i = t14[chan][ticks] -- Previously stored CC in this channnel and tick position
                    if i then
                        if tTargets[i].indexMSB then -- Oops, already got MSB with this tick pos and channel.  So delete this one.
                            tMIDI[#tMIDI] = nil
                            tMIDI[#tMIDI] = s_pack("i4Bs4", offset, 0, "")
                        else
                            tTargets[i].indexMSB = #tMIDI
                            tTargets[i].val = tTargets[i].val | (msg:byte(3)<<7)
                        end
                    else 
                        tTargets[#tTargets+1] = {indexMSB = #tMIDI, val = msg:byte(3)<<7, ticks = ticks}
                        t14[chan][ticks] = #tTargets
                    end
                elseif msg:byte(2) == targetLaneLSB
                then
                    local chan = msg:byte(1)&0x0F
                    tMIDI[#tMIDI+1] = MIDI:sub(prevPos, pos-#msg+1)
                    tMIDI[#tMIDI+1] = msg:sub(3, 3)
                    prevPos = pos-#msg+3
                    -- Store value so that can later be combined with LSB
                    local i = t14[chan][ticks] -- Previously stored CC in this channnel and tick position
                    if i then
                        if tTargets[i].indexLSB then -- Oops, already got LSB with this tick pos and channel.  So delete this one.
                            tMIDI[#tMIDI] = nil
                            tMIDI[#tMIDI] = s_pack("i4Bs4", offset, 0, "")
                        else
                            tTargets[i].indexLSB = #tMIDI
                            tTargets[i].val = tTargets[i].val | msg:byte(3)
                        end
                    else 
                        tTargets[#tTargets+1] = {indexLSB = #tMIDI, val = msg:byte(3), ticks = ticks}
                        t14[chan][ticks] = #tTargets
                    end
                end -- if msg:byte(2) == targetLaneMSB
            end -- if #msg == 3 and (msg:byte(1))>>4 == 11
        end
    elseif laneIsPITCH then
        while pos < MIDILen do
            offset, flags, msg, pos = string.unpack("i4Bs4", MIDI, pos)
            if offset < 0 then if TryToSort[this] then goto startAgain else return false end end -- Check for unsorted MIDI
            ticks = ticks + offset
            if flags&1==1 and #msg >= 3 and (msg:byte(1))>>4 == 14 and (editAllChannels or msg:byte(1)&0x0F == activeChannel)
            then
                tMIDI[#tMIDI+1] = MIDI:sub(prevPos, pos-#msg)
                tMIDI[#tMIDI+1] = msg:sub(2, 3)
                prevPos = pos-#msg+3
                tTargets[#tTargets+1] = {index = #tMIDI, val = (msg:byte(3)<<7) + msg:byte(2), ticks = ticks}
            end
        end   
    elseif laneIsPROGRAM then 
        while pos < MIDILen do
            offset, flags, msg, pos = string.unpack("i4Bs4", MIDI, pos)
            if offset < 0 then if TryToSort[this] then goto startAgain else return false end end -- Check for unsorted MIDI
            ticks = ticks + offset
            if flags&1==1 and #msg >= 2 and (msg:byte(1))>>4 == 12 and (editAllChannels or msg:byte(1)&0x0F == activeChannel)
            then
                tMIDI[#tMIDI+1] = MIDI:sub(prevPos, pos-#msg)
                tMIDI[#tMIDI+1] = msg:sub(2, 2)
                prevPos = pos-#msg+2
                tTargets[#tTargets+1] = {index = #tMIDI, val = msg:byte(2), ticks = ticks}
            end
        end 
    elseif laneIsCHANPRESS then 
        while pos < MIDILen do
            offset, flags, msg, pos = string.unpack("i4Bs4", MIDI, pos)
            if offset < 0 then if TryToSort[this] then goto startAgain else return false end end -- Check for unsorted MIDI
            ticks = ticks + offset
            if flags&1==1 and #msg >= 2 and (msg:byte(1))>>4 == 13 and (editAllChannels or msg:byte(1)&0x0F == activeChannel)
            then
                tMIDI[#tMIDI+1] = MIDI:sub(prevPos, pos-#msg)
                tMIDI[#tMIDI+1] = msg:sub(2, 2)
                prevPos = pos-#msg+2
                tTargets[#tTargets+1] = {index = #tMIDI, val = msg:byte(2), ticks = ticks}
            end
        end 
    elseif laneIsVELOCITY then 
        while pos < MIDILen do
            offset, flags, msg, pos = string.unpack("i4Bs4", MIDI, pos)
            if offset < 0 then if TryToSort[this] then goto startAgain else return false end end -- Check for unsorted MIDI
            ticks = ticks + offset
            if flags&1==1 and #msg >= 3 and (msg:byte(1))>>4 == 9 and msg:byte(3) ~= 0 and (editAllChannels or msg:byte(1)&0x0F == activeChannel)
            then
                tMIDI[#tMIDI+1] = MIDI:sub(prevPos, pos-#msg+1)
                tMIDI[#tMIDI+1] = msg:sub(3, 3)
                prevPos = pos-#msg+3
                tTargets[#tTargets+1] = {index = #tMIDI, val = msg:byte(3), pitch = msg:byte(2), ticks = ticks}
            end
        end 
    elseif laneIsOFFVEL then 
        while pos < MIDILen do
            offset, flags, msg, pos = string.unpack("i4Bs4", MIDI, pos)
            if offset < 0 then if TryToSort[this] then goto startAgain else return false end end -- Check for unsorted MIDI
            ticks = ticks + offset
            if flags&1==1 and #msg >= 3 and ((msg:byte(1)>>4 == 9 and msg:byte(3) == 0) or msg:byte(1)>>4 == 8) and (editAllChannels or msg:byte(1)&0x0F == activeChannel)
            then
                tMIDI[#tMIDI+1] = MIDI:sub(prevPos, pos-#msg+1)
                tMIDI[#tMIDI+1] = msg:sub(3, 3)
                prevPos = pos-#msg+3
                tTargets[#tTargets+1] = {index = #tMIDI, val = msg:byte(3), ticks = ticks}
            end
        end 
    end
    
    -- Insert all unselected events remaining
    tMIDI[#tMIDI+1] = MIDI:sub(prevPos, nil)    
    
    origPPQleftmost, origPPQrightmost = (tTargets[1] and tTargets[1].ticks) or math.huge, (tTargets[#tTargets] and tTargets[#tTargets].ticks) or -math.huge
    
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
        Tooltip("Armed: Arch and Tilt")
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
    
    
    -- ATEXIT CLEAN-UP
    -- so must be defined before any potential errors, and stuff that may cause havoc if not cleaned up, such as intercepts.
    -- Also, if anyting goes wrong during main(), a dialog box will pop up, so AtExit() will try to return focus to original windows.
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
    filename = filename:gsub("\\", "/") -- Change Windows format to cross-platform
    filename = filename:match("^.*/") -- Remove script filename, keeping directory
    filename = filename .. "js_Mouse editing - Arch and Tilt.cur"
    cursor = reaper.JS_Mouse_LoadCursorFromFile(filename) -- The first time that the cursor is loaded in the session will be slow, but afterwards the extension will re-use previously loaded cursor
    if not cursor then cursor = reaper.JS_Mouse_LoadCursor(527) end -- If .cur file unavailable, load one of REAPER's own cursors]]
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
                        
                            -- Get MIDI editor structure from chunk, and store in tME_Lanes table.
                            chunkStuffOK = SetupMIDIEditorInfoFromTakeChunk() 
                            if chunkStuffOK then
                                
                                mouseOrigCCLaneID = GetCCLaneIDFromPoint(mouseOrigX, mouseOrigY) 
                                if mouseOrigCCLaneID then
                                    
                                    targetLaneOK, mouseOrigCCLane = SetupTargetLaneForParsing(mouseOrigCCLaneID) 
                                    if targetLaneOK then
                                                    
                                        -- Calculate these variables here, since the BR_ function will get these for inline editor
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
                if details == "cc_lane" and mouseOrigCCValue == -1 then mouseOrigCCLaneID = mouseOrigCCLaneID - 0.5 end -- Adjust mouseOrigCCLaneID to same values as this script's GetCCLaneIDFromPoint for MIDI editor.
                                
                if isInline then
                    
                    editor = nil
                    activeTake = reaper.BR_GetMouseCursorContext_Take()
                    activeTakeOK = activeTake and reaper.ValidatePtr2(0, activeTake, "MediaItem_Take*") and reaper.TakeIsMIDI(activeTake) 
                    if activeTakeOK then
                    
                        activeItem = reaper.GetMediaItemTake_Item(activeTake)
                        activeItemOK = activeItem and reaper.ValidatePtr(activeItem, "MediaItem*") 
                        if activeItemOK then 
                        
                            -- In the case of the inline editor, BR functions will be used to track the mouse, 
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
    if not (laneIsCC7BIT or laneIsCC14BIT or laneIsCHANPRESS or laneIsPROGRAM or laneIsPITCH or laneIsVELOCITY or laneIsOFFVEL) then
        reaper.MB("The script will only work in the following MIDI lanes: \n * Velocity or Off velocity, \n * 7-bit or 14-bit CC, \n * Pitchwheel, \n * Program select, or\n * Channel Pressure."
                .. "\n\nTo tell the script which lane must be edited, the mouse must be positioned inside that lane when the script starts."
                .. "\n\nEvents that do not have values, such as text or sysex, cannot be arched."
                , "ERROR", 0)
        return false 
    end
    
    
    -- MOUSE STARTING CC VALUE:
    -- As mentioned above, if the mouse starts on the divider between lanes, the lane is undetermined, 
    --    so the script must loop till the user moves the mouse into a lane.
    if mouseOrigCCValue > laneMaxValue then mouseOrigCCValue = laneMaxValue
    elseif mouseOrigCCValue < laneMinValue then mouseOrigCCValue = laneMinValue
    else mouseOrigCCValue = math.floor(mouseOrigCCValue+0.5)
    end 


    -- MOUSE STARTING PPQ POSITION:
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
    local itemLastVisibleTick = math.floor(reaper.MIDI_GetPPQPosFromProjTime(activeTake, itemEndTimePos))
    mouseOrigPPQPos = math.max(itemFirstVisibleTick, math.min(itemLastVisibleTick-1, mouseOrigPPQPos)) 
    -- Now get PPQ position relative to loop iteration under mouse
    -- Source length will be used in other context too: When script terminates, check that no inadvertent shifts in PPQ position occurred.
    if not sourceLengthTicks then sourceLengthTicks = reaper.BR_GetMidiSourceLenPPQ(activeTake) end
    loopStartPPQPos = (mouseOrigPPQPos // sourceLengthTicks) * sourceLengthTicks
    mouseOrigPPQPos = mouseOrigPPQPos - loopStartPPQPos  
    
    minimumTick = math.max(0, itemFirstVisibleTick)
    maximumTick = math.min(itemLastVisibleTick, sourceLengthTicks-1) -- I prefer not to draw any event on the same PPQ position as the All-Notes-Off
    mouseOrigPPQPos = math.max(minimumTick, math.min(maximumTick, mouseOrigPPQPos))


    -- GET AND PARSE MIDI:
    -- Time to process the MIDI of the take!
    -- As mentioned in the header, this script does not use the old-fashioned MIDI API functions such as 
    --    MIDI_InsertCC, since these functions are far too slow when dealing with thousands of events.
    if not GetAndParseMIDIString() then return false end
    if #tTargets < 3 or tTargets[#tTargets].ticks - tTargets[1].ticks == 0 then
        reaper.MB("Could not find a sufficient number of selected events in the target lane."
                .. "\n\nNB: If the MIDI editor's filter is set to \"Edit active channel only\", the script will only edit events in the active channel."
                , "ERROR", 0)
        return false
    end
    

    -- Prepare LICE stuff for compositing
    if midiview then
        bitmap = reaper.JS_LICE_CreateBitmap(true, ME_midiviewWidth, ME_midiviewHeight)
        if bitmap then
            if ME_TimeBase == "beats" then
                Guides_LeftPixel = (tTargets[1].ticks + loopStartPPQPos - ME_LeftmostTick) * ME_PixelsPerTick
                Guides_RightPixel = (tTargets[#tTargets].ticks + loopStartPPQPos - ME_LeftmostTick) * ME_PixelsPerTick
            else -- ME_TimeBase == "time"
                local firstTime = reaper.MIDI_GetProjTimeFromPPQPos(activeTake, tTargets[1].ticks + loopStartPPQPos)
                local lastTime  = reaper.MIDI_GetProjTimeFromPPQPos(activeTake, tTargets[#tTargets].ticks + loopStartPPQPos)
                Guides_LeftPixel  = (firstTime-ME_LeftmostTime)*ME_PixelsPerSecond
                Guides_RightPixel = (lastTime -ME_LeftmostTime)*ME_PixelsPerSecond
            end
            Guides_LeftPixel  = math.ceil(math.max(Guides_LeftPixel, 0)) 
            Guides_RightPixel = math.floor(math.min(Guides_RightPixel, ME_midiviewWidth-1))
            
            -- The line will be calculated at nodes spaced 10 pixels. Get PPQ positions of each node.
            tGuides_Ticks = {} 
            tGuides_X = {} -- Pixel positions relative to midiview client area
            if ME_TimeBase == "beats" then
                for x = Guides_LeftPixel, Guides_RightPixel-1, 5 do
                    tGuides_X[#tGuides_X+1] = x
                    tGuides_Ticks[#tGuides_Ticks+1] = ME_LeftmostTick + x/ME_PixelsPerTick - loopStartPPQPos
                end
                tGuides_X[#tGuides_X+1] = Guides_RightPixel -- Make sure the line goes up to last event
                tGuides_Ticks[#tGuides_Ticks+1] = ME_LeftmostTick + Guides_RightPixel/ME_PixelsPerTick - loopStartPPQPos
            else -- ME_TimeBase == "time"
                for x = Guides_LeftPixel, Guides_RightPixel-1, 5 do
                    tGuides_X[#tGuides_X+1] = x
                    tGuides_Ticks[#tGuides_Ticks+1] = reaper.MIDI_GetPPQPosFromProjTime(activeTake, ME_LeftmostTime + x/ME_PixelsPerSecond )
                                                - loopStartPPQPos
                end
                tGuides_X[#tGuides_X+1] = Guides_RightPixel
                tGuides_Ticks[#tGuides_Ticks+1] = reaper.MIDI_GetPPQPosFromProjTime(activeTake, ME_LeftmostTime + Guides_RightPixel/ME_PixelsPerSecond )
                                            - loopStartPPQPos
            end
            
            if #tGuides_X > 1 then
                compositeOK = reaper.JS_Composite(midiview, 0, 0, ME_midiviewWidth, ME_midiviewHeight, bitmap, 0, 0, ME_midiviewWidth, ME_midiviewHeight)
                if compositeOK ~= 1 then reaper.MB("Cannot draw guidelines.\n\nCompositing error: "..tostring(compositeOK), "ERROR", 0) end
            end
        end
    end    
    
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
     
    

