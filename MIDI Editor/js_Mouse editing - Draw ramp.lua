--[[
ReaScript name: js_Mouse editing - Draw ramp.lua
Version: 4.10
Author: juliansader
Screenshot: http://stash.reaper.fm/27627/Draw%20linear%20or%20curved%20ramps%20in%20real%20time%2C%20chasing%20start%20values%20-%20Copy.gif
Website: http://forum.cockos.com/showthread.php?t=176878
Donation: https://www.paypal.me/juliansader
Provides: [main=midi_editor,midi_inlineeditor] .
About:
  # DESCRIPTION
  
  Draw linear or curved ramps of CC and pitchwheel events in real time.
  
  Works in inline MIDI editors as well as full MIDI editors.
               
  An improvement over REAPER's built-in "Linear ramp CC events" mouse action:
  
  * SNAP TO GRID: If snap to grid is enabled in the MIDI editor, the endpoints of the 
     ramp will snap to grid, allowing precise positioning of the ramp 
     (allowing, for example, the insertion of a pitch riser at the
     exact position of a note).
  
  * CHASING START VALUES: Right-clicking toggles between chasing existing CC values at the line start position, 
      and starting at the mouse's original vertical position.  Chasing ensures that
      CC values change smoothly. 
      
  * LINEAR OR SINE SHAPES: Clicking the middle button toggles between a linear shape and a sine shape,
      which can be tweaked into other shapes such as parabolic.
  
  * TWEAK THE CURVE: By using the mousewheel, the shape of the ramp can be tweaked. 
      Linear ramps can be smoothly morphed to parabolic, for example. 
       
  * SKIP REDUNDANT CCs: This script (like all other js_ scripts that insert new CCs) can optionally 
      skip redundant CCs (that is, CCs with the same value as the preceding CC). 
      This is controlled by the script "js_Option - Toggle skip redundant events when inserting CCs".
      
  * The script inserts new CCs, instead of only editing existing CCs.  (CCs
      are inserted at the density set in Preferences -> MIDI editor -> "Events 
      per quarter note when drawing in CC lanes".)
  
  * The script does not change or delete existing events until execution 
      ends, so there are no 'overshoot remnants' if the mouse movement overshoots 
      the target endpoint.
  
  * The events in the newly inserted ramp are automatically selected and other
      events in the same lane are deselected, which allows immediate further shaping
      of the ramp (using, for example, the warping or arching scripts).     


  # INSTRUCTIONS
  
  As already mentioned above, the script can be controlled by the mouse while the script is running:
      * Left click: Terminates the script.
      * Middle click: Toggles the ramp shape between 1) linear/power curve and 2) sine ("slow start / slow end") curve.
      * Right click: Toggles between 1) chasing start values and 2) no chasing, use original mouse position.
      * Mousewheel: Tweaks the ramp curve. 
        (NB: The longer the mousewheel is kept moving, the faster the curve will change. 
             The curve will also momentarily pause when it reaches the default, middle value.)
 
      
  The keyboard can also terminate the script:
      * Any mouse modifier key: Terminates the script.
      * Pressing the keyboard shortcut again: Terminates the script.
  
  
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

  
  PERFORMANCE TIPS
  
  * The responsiveness of the MIDI editor is significantly influenced by the total number of events in 
      the visible and edit takes. If the MIDI editor is slow, try reducing the number of edit and visible tracks.
      
  * If the MIDI editor gets slow and jerky when a certain VST plugin is loaded, 
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
    + Redraw immediately if "Skip redundant CCs" is toggled while script is running.
]]

----------------------------------------
-- USER AREA
-- Settings that the user can customize.
 
    -- Should the script follow the MIDI editor's snap-to-grid setting, or should the
    --    script ignore the snap-to-grid setting and never snap to the grid?
    local neverSnapToGrid = false -- true or false
      
    local deleteOnlyDrawChannel = true -- true or false: Delete all CCs in range of new ramp, or only CCs in same channel as ramp.
    
    local deselectEverythingInLane = false -- true or false: Deselect all CCs in the same lane as the new ramp (and in active take). 
    
-- End of USER AREA


-- ################################################################################################
---------------------------------------------------------------------------------------------------
-- CONSTANTS AND VARIABLES (that modders may find useful)

-- General note:
-- REAPER's MIDI API functions such as InsertCC and SetCC are very slow if the active take contains 
--    hundreds of thousands of MIDI events.  
-- Therefore, this script will not use these functions, and will instead directly access the item's 
--    raw MIDI stream via new functions that were introduced in v5.30: GetAllEvts and SetAllEvts.

-- The MIDI data will be stored in the string MIDIString.  While drawing, in each cycle a string with 
--    new events will be concatenated *in front* of the original MIDI data, and loaded into REAPER 
--    as the new MIDI data.
-- In v3.11, the new MIDI was concatenated at the *end*, to ensure that the line's events are drawn 
--    in front of the take's original MIDI events.  However, this failed due to the bug described in
--    http://forum.cockos.com/showthread.php?t=189343.
-- This script will therefore 1) concatenated the new MIDI in front, to ensure that the CCs don't
--    disappear, and 2) all CCs in the target lane will *temporarily* be deselected while drawing.

local MIDIString -- The original raw MIDI data returned by GetAllEvts
local MIDIStringDeselected -- MIDIString with all CCs in target lane deselected.

-- As the MIDI events of the ramp are calculated, each event wil be assmebled into a short string and stored in the tLine table.   
local tLine = {}
local lastPPQPos -- to calculate offset to next CC
local lastValue -- To compare against last value, if skipRedundantCCs
 
-- Starting values and position of mouse 
-- mouseOrigCCLane: (CC0-127 = 7-bit CC, 0x100|(0-31) = 14-bit CC, 0x200 = velocity, 0x201 = pitch, 
--    0x202=program, 0x203=channel pressure, 0x204=bank/program select, 
--    0x205=text, 0x206=sysex, 0x207=off velocity)
local laneMinValue, laneMaxValue -- The minimum and maximum values in the target lane
local mouseOrigCCLane, mouseOrigCCValue, mouseOrigPPQPos, mouseOrigPitch, mouseOrigCCLaneID = nil, nil, nil, nil, nil
local snappedOrigPPQPos -- If snap-to-grid is enabled, these will give the closest grid PPQ to the left. (Swing is not implemented.)

-- This script can work in inline MIDI editors as well as the main MIDI editors
-- The two types of editors require some different code, though.  
-- In particular, if in an inline editor, functions from the SWS extension will be used to track mouse position.
-- In the main editor, WIN32/SWELL functions from the js_ReaScriptAPI extension will be used.
local isInline, editor = nil, nil

-- Tracking the new value and position of the mouse while the script is running
local mouseX, mouseY
local mouseNewCCLane, mouseNewCCValue, mouseNewPPQPos, mouseNewPitch, mouseNewCCLaneID = nil, nil, nil, nil, nil
local snappedNewPPQPos = nil

-- The script can be controlled by mousewheel, mouse buttons an mouse modifiers.  These are tracked by the following variables.
local mouseState
local prevMouseTime = 0
local prevDelta
--local mousewheel = 1 -- Will be loaded from extState below

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
local sectionID, commandID

-- If the mouse is over a MIDI editor, these variables will store the on-screen layout of the editor.
-- NOTE: Getting the MIDI editor scroll and zoom values is slow, since the item chunk has to be parsed.
--    This script will therefore not update these variables after getting them once.  The user should not scroll and zoom while the script is running.
local activeTakeChunk
local ME_l, ME_t, ME_r, ME_b -- screen coordinates of MIDI editor, with frame
local ME_LeftmostTick, ME_PixelsPerTick, ME_PixelsPerSecond = nil, nil, nil -- horizontal scroll and zoom
local ME_TopPitch, ME_PixelsPerPitch = nil, nil -- vertical scroll and zoom
local ME_UsableAreaLeftPixel, ME_UsableAreaRightPixel, ME_UsableAreaTopPixel, ME_UsableAreaBottomPixel = nil, nil, nil, nil
local ME_CCLaneTopPixel, ME_CCLaneBottomPixel = nil, nil
local ME_midiviewLeftPixel, ME_midiviewTopPixel, ME_midiviewRightPixel, ME_midiviewBottomPixel = nil, nil, nil, nil
local ME_TimeBase
local tME_Lanes = {} -- store the layout of each MIDI editor lane
--local tVisibleCC7Bit = {} -- CC lanes to use.  (In case of a 14bit CC lane or Bank/Program, this table will contain two entries. If all visible lanes are used, may contain even more entries.)

-- I am not sure that defining these functions as local really helps to spred up the script...
local s_unpack = string.unpack
local s_pack   = string.pack
local m_floor  = math.floor
local m_cos = math.cos
local m_pi  = math.pi

-- Window messages that will be intercepted while the script is running
local tWM_Messages = {WM_LBUTTONDOWN = false, WM_LBUTTONDBLCLK = false, WM_LBUTTONUP = false,
                      WM_MBUTTONDOWN = false, WM_MBUTTONDBLCLK = false, WM_MBUTTONUP = false,
                      WM_RBUTTONDOWN = false, WM_RBUTTONDBLCLK = false, WM_RBUTTONUP = false,
                      WM_NCMOUSEMOVE = false, -- I'm not sure... Does this prevent REAPER from changing the mouse cursor when it's over scrollbars?
                      WM_MOUSEWHEEL  = false, WM_MOUSEHWHEEL   = false,
                      WM_SETCURSOR   = false}

-- Variables unique to this script:
-- If mustChase is false, or if no pre-existing CCs are found, these will be the same as mouseOrigCCValue
local lastChasedValue = nil -- value of closest CC to the left
local nextChasedValue = nil -- value of closest CC to the right
local baseShape, mousewheel, mustChase = reaper.GetExtState("js_Draw ramp", "Last shape"):match("([^,]+),([^,]+),([^,]+)") -- Saved shape
baseShape   = baseShape  or "linear"
mustChase   = (mustChase == "true")
mousewheel  = math.max(0.025, math.min(40, tonumber(mousewheel) or 1)) -- Track mousewheel movement
local lineLeftPPQPos, lineLeftValue, lineRightPPQPos, lineRightValue = nil, nil, nil, nil -- The CCs will be inserted into the MIDI string from left to right
local factor = 1.04



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
    
    -- TAKE STILL VALID:
    if not reaper.ValidatePtr2(0, activeTake, "MediaItem_Take*") then activeTake = nil return false end
    
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
    
    -- MOUSEWHEEL:
    local peekOK, pass, time, keys, delta = reaper.JS_WindowMessage_Peek(windowUnderMouse, "WM_MOUSEWHEEL")
    if not (peekOK and time > prevMouseTime) then 
        peekOK, pass, time, keys, delta = reaper.JS_WindowMessage_Peek(windowUnderMouse, "WM_MOUSEHWHEEL")
    end 
    if peekOK then
        if time <= prevMouseTime then 
            prevDelta = 0
        else --if time > prevMouseTime+0.25 then
            if keys&12 ~= 0 then return end
            delta = ((delta > 0) and 1) or ((delta < 0) and -1) or 0 -- Standardize delta values so that can compare with previous
            delta = (mouseNewCCValue <= mouseOrigCCValue) and delta or -delta -- Ensure that moving wheel down/up always moves curve down/up
            --[[
            local factor = (time - prevMouseTime < 0.6) and 3 or 1.1
            if delta > 0 then mousewheel = mousewheel * factor
            elseif delta < 0 then mousewheel = mousewheel / factor
            end
            if mousewheel < 1.01 and mousewheel > 0.99 then mousewheel = 1 end -- Prevent rounding error accumulation
            ]]
            -- Meradium's suggestion: If mousewheel is turned rapidly, make larger changes to the curve per defer cycle
            --local factor = ((delta == prevDelta) and (time-prevMouseTime < 1)) and 0.04/((time-prevMouseTime)) or 0.04
            -- The script tries to make it easy to bring curve back to the default mousewheel == 1:
            --    * When mousewheel is scrolled through 1, pause for a moment.
            --    * When mousewheel is near 1, round to 1.
            if not (mousewheel == 1 and time < prevMouseTime + 1) then -- Pause for 1 sec when reach default value of 1
                factor = (factor and delta == prevDelta) and factor*1.2 or 1.04
                local prevMousewheel = mousewheel
                mousewheel = ((delta == 1) and mousewheel*factor) or ((delta == -1) and mousewheel/factor)
                if (prevMousewheel < 1 and mousewheel >= 1) or (prevMousewheel > 1 and mousewheel <= 1) then mousewheel = 1; factor = 1.04 -- Prevent scrolling through 1, and round to 1
                --elseif 0.962 < mousewheel and mousewheel < 1.04 then mousewheel = 1 -- Round to 1 if comes close
                -- Snap to flat line (standard compression shape) if either direction goes extreme
                elseif mousewheel < 0.025 then mousewheel = 0.025 
                elseif mousewheel > 40 then mousewheel = 40
                end
                prevMouseTime = time 
                mustCalculate = true
            end
            prevDelta = delta
        end
    end
    
    -- LEFT DRAG: (If the left button was kept pressed for 1 second or longer, or after moving the mouse 20 pixels, assume left-drag, so quit when lifting.)
    peekOK, pass, time = reaper.JS_WindowMessage_Peek(windowUnderMouse, "WM_LBUTTONUP")
    if peekOK and (time > startTime + 1.5 )
              --or  (time > startTime and (mouseX < mouseOrigX - 20 or mouseX > mouseOrigX + 20 or mouseY < mouseOrigY - 20 or mouseY > mouseOrigY + 20))) 
              then  
        return false
    end
    
    -- LEFT CLICK: (If the left mouse button or any modifier key is pressed, after first releasing them, quit.)
    peekOK, pass, time = reaper.JS_WindowMessage_Peek(windowUnderMouse, "WM_LBUTTONDOWN")
    if peekOK and time > startTime then return false end
    
    -- MIDDLE BUTTON:
    peekOK, pass, time = reaper.JS_WindowMessage_Peek(windowUnderMouse, "WM_MBUTTONDOWN")
    if peekOK and time > prevMouseTime then 
        baseShape = (baseShape == "linear") and "sine" or "linear"
        prevMouseTime = time
        mustCalculate = true
    end
    
    -- RIGHT CLICK: (Toggle chase.)
    peekOK, pass, time = reaper.JS_WindowMessage_Peek(windowUnderMouse, "WM_RBUTTONDOWN")
    if peekOK and time > prevMouseTime then
        mustChase = not mustChase
        prevMouseTime = time
        mustCalculate = true
    end
    
    -- SKIP REDUNDANT CCS?
    -- In every cycle, check whether redundant events must be skipped, 
    --    so that can be changed in real time.
    local prevSkip = skipRedundantCCs
    skipRedundantCCs = (reaper.GetExtState("js_Mouse actions", "skipRedundantCCs") == "true") -- false by default, so that new users aren't surprised by missing CCs
    if skipRedundantCCs ~= prevSkip then
        mustCalculate = true
    end
        
    
    ---------------------
    -- DO THE MIDI STUFF!
    
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
        
        -- MOUSE PPQ (HORIZONTAL) POSITION
        -- (And prevent mouse line from extending beyond item boundaries.)
        if isInline then
            -- A call to BR_GetMouseCursorContext must always precede the other BR_ context calls
            mouseNewPPQPos = reaper.MIDI_GetPPQPosFromProjTime(activeTake, reaper.BR_GetMouseCursorContext_Position())
        elseif ME_TimeBase == "beats" then
            mouseNewPPQPos = ME_LeftmostTick + mouseX/ME_PixelsPerTick
        else -- ME_TimeBase == "time"
            mouseNewPPQPos = reaper.MIDI_GetPPQPosFromProjTime(activeTake, ME_LeftmostTime + mouseX/ME_PixelsPerSecond )
        end
        -- Adjust mouse PPQ position for looped items
        mouseNewPPQPos = mouseNewPPQPos - loopStartPPQPos
        -- Adjust mouse PPQ position for snapping
        if not isSnapEnabled then
            snappedNewPPQPos = m_floor(mouseNewPPQPos+0.5)
        elseif isInline then
            local timePos = reaper.MIDI_GetProjTimeFromPPQPos(activeTake, mouseNewPPQPos)
            local snappedTimePos = reaper.SnapToGrid(0, timePos) -- If snap-to-grid is not enabled, will return timePos unchanged
            snappedNewPPQPos = m_floor(reaper.MIDI_GetPPQPosFromProjTime(activeTake, snappedTimePos) + 0.5)
        else
            local mouseQNpos = reaper.MIDI_GetProjQNFromPPQPos(activeTake, mouseNewPPQPos) -- Mouse position in quarter notes
            local roundedGridQN = math.floor((mouseQNpos/QNperGrid)+0.5)*QNperGrid -- nearest grid to mouse position
            snappedNewPPQPos = m_floor(reaper.MIDI_GetPPQPosFromProjQN(activeTake, roundedGridQN) + 0.5)
        end
        -- Don't draw outside item or source boundaries
        snappedNewPPQPos = math.max(minimumTick, math.min(maximumTick, snappedNewPPQPos)) 
            
            
        -- LINE DIRECTION?   
        -- Prefer to draw the line from left to right, so check whether mouse is to left or right of starting point
        -- The line's startpoint event 'chases' existing CC values.
        if snappedNewPPQPos >= snappedOrigPPQPos then
            mouseToRight    = true
            lineLeftPPQPos  = snappedOrigPPQPos
            baseValue       = mustChase and lastChasedValue or mouseOrigCCValue
            lineRightPPQPos = isSnapEnabled and (snappedNewPPQPos-1) or snappedNewPPQPos -- -1 because rightmost tick actually falls outside time selection
            basePPQPos      = lineLeftPPQPos
            --lineRightValue  = mouseNewCCValue
        else 
            mouseToRight    = false
            lineLeftPPQPos  = snappedNewPPQPos
            --lineLeftValue  = mouseNewCCValue
            lineRightPPQPos = isSnapEnabled and (snappedOrigPPQPos-1) or snappedOrigPPQPos -- -1 because rightmost tick actually falls outside time selection
            baseValue       = mustChase and nextChasedValue or mouseOrigCCValue
            basePPQPos      = lineRightPPQPos
        end    
        local PPQrange = lineRightPPQPos - lineLeftPPQPos
        local valueRange = mouseNewCCValue - baseValue
                
        -- Mousewheel values
        local power, mousewheelLargerThanOne = nil, nil
        if mousewheel >= 1 then 
            mousewheelLargerThanOne = true -- I expect that accessing local boolean variables are faster than comparing numbers
            power = mousewheel 
        else 
            power = 1/mousewheel 
        end           
        

        -- Clean previous tLine.  All the new MIDI events will be stored in this table, 
        --    and later concatenated into a single string.
        tLine = {}
        local c = 0 -- Count index in tLine - This is faster than using table.insert or even #table+1
        
        lastPPQPos = 0
        lastValue = nil
        
                    -------
                    local function InsertCC(insertPPQPos)
                        local insertValue
                        local distance = insertPPQPos-basePPQPos
                        if distance < 0 then distance = -distance end
                        if distance == 0 or PPQrange <= 0 then -- Avoid of divide by zero!
                            insertValue = baseValue
                        elseif baseShape == "linear" then
                            if mousewheelLargerThanOne then
                                insertValue = baseValue + valueRange*((distance/PPQrange)^power)
                            else
                                insertValue = mouseNewCCValue - valueRange*((1 - (distance/PPQrange))^power)
                            end
                        else
                            if mousewheelLargerThanOne then
                                insertValue = baseValue + valueRange*(  (0.5*(1 - m_cos(m_pi*(distance/PPQrange)))) ^power )
                            else
                                insertValue = mouseNewCCValue - valueRange*(  (0.5*(1 - m_cos(m_pi*(1 - (distance/PPQrange))))) ^power  )
                            end
                        end
                        
                        if insertValue ~= insertValue then insertValue = baseValue -- Undefined?
                        elseif insertValue < laneMinValue then insertValue = laneMinValue
                        elseif insertValue > laneMaxValue then insertValue = laneMaxValue
                        else insertValue = math.floor(insertValue + 0.5)
                        end
                        
                        local offset = insertPPQPos - lastPPQPos
                        if insertValue ~= lastValue or skipRedundantCCs == false then
                            if laneIsCC7BIT then
                                c = c + 1
                                tLine[c] = s_pack("i4BI4BBB", offset, 1, 3, 0xB0 | activeChannel, mouseOrigCCLane, insertValue)
                            elseif laneIsPITCH then
                                c = c + 1
                                tLine[c] = s_pack("i4BI4BBB", offset, 1, 3, 0xE0 | activeChannel, insertValue&127, insertValue>>7)
                            elseif laneIsCHANPRESS then
                                c = c + 1
                                tLine[c] = s_pack("i4BI4BB",  offset, 1, 2, 0xD0 | activeChannel, insertValue)
                            else -- laneIsCC14BIT
                                c = c + 1
                                tLine[c] = s_pack("i4BI4BBB", offset, 1, 3, 0xB0 | activeChannel, mouseOrigCCLane-256, insertValue>>7)
                                c = c + 1
                                tLine[c] = s_pack("i4BI4BBB", 0     , 1, 3, 0xB0 | activeChannel, mouseOrigCCLane-224, insertValue&127)
                            end
                            lastValue = insertValue
                            lastPPQPos = insertPPQPos
                        end
                    end
                    -------
    
        if lineLeftPPQPos <= lineRightPPQPos then
        
            local roundedPPQPos
            for PPQPos = lineLeftPPQPos, lineRightPPQPos, PPerCC do
                roundedPPQPos = m_floor(PPQPos + 0.5) -- PPerCC is not necessarily an integer
                if minimumTick <= roundedPPQPos and roundedPPQPos <= maximumTick then
                    InsertCC(roundedPPQPos)   
                end       
            end
            --[[ Insert the leftmost endpoint (which is not necessarily a grid position)
            if 0 <= lineLeftPPQPos and lineLeftPPQPos < sourceLengthTicks then
                InsertCC(lineLeftPPQPos)
            end
            
            -- Now insert all the CCs in-between the endpoints.  These positions will follow the "midiCCDensity" setting (which 
            --    is usually much finer than the editor's "grid" setting.
            -- First, find next PPQ position at which CCs will be inserted.  
            local nextCCDensityPPQPos = firstCCinTakePPQPos + PPerCC * math.ceil((lineLeftPPQPos+1-firstCCinTakePPQPos)/PPerCC)            
            for PPQPos = nextCCDensityPPQPos, lineRightPPQPos-1, PPerCC do -- -1 so that falls within time selection
                insertPPQPos = m_floor(PPQPos + 0.5)
                
                if 0 <= insertPPQPos and insertPPQPos < sourceLengthTicks then
                    InsertCC(insertPPQPos)
                end
            end
            ]]
            -- Insert the rightmost endpoint
            if lastPPQPos < lineRightPPQPos then -- If CC is inserted precisely at grid, will not be selected with note that ends on that grid
                if minimumTick <= lineRightPPQPos and lineRightPPQPos <= maximumTick then 
                    InsertCC(lineRightPPQPos)
                end
            end
            
        
        end -- if lineLeftPPQPos <= lineRightPPQPos
                                    
        
        -- DRUMROLL... write the edited events into the MIDI string!  
        reaper.MIDI_SetAllEvts(activeTake, table.concat(tLine) .. string.pack("i4Bs4", -lastPPQPos, 0, "") .. MIDIStringDeselected)    
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
    
    -- Save last-used line shape
    reaper.SetExtState("js_Draw ramp", "Last shape", tostring(baseShape) .. "," .. tostring(mousewheel) .. "," .. tostring(mustChase), true)
    
    -- Was an active take found, and does it still exist?  If not, don't need to do anything to the MIDI.
    if reaper.ValidatePtr2(0, activeTake, "MediaItem_Take*") and reaper.TakeIsMIDI(activeTake) then
        -- Before exiting, if DEFERLOOP_pcall was successfully executed, delete existing CCs in the line's range (and channel)
        -- The delete function will also ensure that the MIDI is re-uploaded into the active take.
        if pcallOK == true then
            pcallOK, pcallRetval = pcall(DeleteExistingCCsInRange)
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
                  
        -- Write nice, informative Undo strings
        if laneIsCC7BIT then 
            undoString = "Draw ramp in 7-bit CC lane ".. mouseOrigCCLane
        elseif laneIsCHANPRESS then
            undoString = "Draw ramp in channel pressure lane"
        elseif laneIsCC14BIT then
            undoString = "Draw ramp in 14 bit CC lanes ".. 
                                      tostring(mouseOrigCCLane-256) .. "/" .. tostring(mouseOrigCCLane-224)
        elseif laneIsPITCH then
            undoString = "Draw ramp in pitchwheel lane"
        else
            undoString = "Draw ramp: ERROR"
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
    if editor and midiview and reaper.MIDIEditor_GetMode(editor) ~= -1 then
        curForegroundWindow = reaper.JS_Window_GetForeground()
        if not (curForegroundWindow and reaper.JS_Window_GetTitle(curForegroundWindow) == reaper.JS_Localize("ReaScript task control", "common")) then
            reaper.JS_Window_SetForeground(midiview)
            reaper.JS_Window_SetFocus(midiview)
    end end    
    
end -- function AtExit


--###############################################################################################
-------------------------------------------------------------------------------------------------
function SetupTargetLaneForParsing(laneID, target)
    -- Since 7bit CC, 14bit CC, channel pressure, and pitch all require somewhat different tweaks,
    --    these must often be distinguished. 
    -- Unlike some other scripts, the Draw ramp script only targets a single lane, not all visible ones.
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
            return true, laneType
        end
    else
        --reaper.MB("The target lane CC lanes are of unknown type, and could not be parsed by this script.", "ERROR", 0)
        return false
    end
    return false, nil
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
        ME_BottomPitch = ME_TopPitch - m_floor(tME_Lanes[-1].ME_Height / ME_PixelsPerPitch)
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
-- Parse MIDI string and chase starting values.
function ParseMIDIString_DeselectAndFindChasedValues()

    -- Unfortunately, there are two problems that this script has to circumvent:
    -- 1) If the new MIDI is concatenated to the front of MIDIString, selected events
    --    that are later in the string, will overwrite the line's CC bars.
    -- 2) If the new MIDI is concatenated to the end of MIDIString, the MIDI editor
    --    may forget to the draw these CCs, if earlier CCs that are earlier in the
    --    stream go offscreen.  http://forum.cockos.com/showthread.php?t=189343
    -- This script will therefore do the following:
    --    The new MIDI will be concatenated in front, but all CCs in the target lane
    --    will temporarily be deselected.
    
    -- Since the entire MIDI string must in any case be parsed here, in order to 
    --    deselect, lastChasedValue and nextChasedValue will also be calculated.
    -- If mustChase == false, they will eventually be replaced by mouseOrigCCValue.
    
    -- By default (if not mustChase, or if no pre-existing CCs are found),
    --    use mouse starting values.    
    -- 14-bit CC must determine both MSB and LSB.  If no LSB is found, simply use 0 as default.
    local lastChasedMSB, nextChasedMSB = 1, 1
    local lastChasedLSB, nextChasedLSB = 1, 1
    
    -- The script will speed up execution by not inserting each event individually into tEvents as they are parsed.
    --    Instead, only changed (i.e. deselected) events will be re-packed and inserted individually, while unchanged events
    --    will be inserted as bulk blocks of unchanged sub-strings.
    local runningPPQPos = 0 -- The MIDI string only provides the relative offsets of each event, so the actual PPQ positions must be calculated by iterating through all events and adding their offsets
    local prevPos, nextPos, unchangedPos = 1, 1, 1 -- unchangedPos is starting position of block of unchanged MIDI.
    local offset, flags, msg
    local mustDeselect
    local tEvents = {} -- All events will be stored in this table until they are concatened again
    local t = 0 -- Count index in table.  It is faster to use tEvents[t] = ... than table.insert(...
        
    -- Iterate through all the (original) MIDI in the take, searching for events closest to snappedOrigPPQPos
    -- MOTE: This function assumes that the MIDI is sorted.  This should almost always be true, unless there 
    --    is a bug, or a previous script has neglected to re-sort the data.
    -- Even a tiny edit in the MIDI editor induced the editor to sort the MIDI.
    -- By assuming that the MIDI is sorted, the script avoids having to call the slow MIDI_sort function, 
    --    and also avoids making any edits to the take at this point.
    local MIDILen = #MIDIString
    while nextPos <= MIDILen do
    
        prevPos = nextPos    
        offset, flags, msg, nextPos = s_unpack("i4Bs4", MIDIString, nextPos)
            
        mustDeselect = false
        -- For backward chase, CC must be *before* snappedOrigPPQPos
        -- For forward chase, CC can be after *or at* snappedOrigPPQPos
        runningPPQPos = runningPPQPos + offset
        if msg:len() >= 2 then
            local msg1 = msg:byte(1)
            local msg2 = msg:byte(2)
            if laneIsCC7BIT then 
                if msg1>>4 == 11 and msg2 == mouseOrigCCLane then 
                    if flags&1 == 1 then mustDeselect = true end
                    if msg1&0x0F  == activeChannel then
                        if runningPPQPos < snappedOrigPPQPos then lastChasedValue = msg:byte(3) 
                        elseif not nextChasedValue then nextChasedValue = msg:byte(3)
                        end
                    end
                end
            elseif laneIsPITCH then 
                if msg1>>4 == 14 then 
                    if flags&1 == 1 then mustDeselect = true end
                    if msg1&0x0F == activeChannel then
                        if runningPPQPos < snappedOrigPPQPos then lastChasedValue = ((msg:byte(3))<<7) | msg2 
                        elseif not nextChasedValue then nextChasedValue = ((msg:byte(3))<<7) | msg2 
                        end
                    end
                end
            elseif laneIsCC14BIT then -- Should the script ignore LSB?
                if msg1>>4 == 11 then
                    if msg2 == mouseOrigCCLane-256 then 
                        if flags&1 == 1 then mustDeselect = true end
                        if msg1&0x0F == activeChannel then
                            if runningPPQPos < snappedOrigPPQPos then lastChasedMSB = msg:byte(3)
                            elseif not nextChasedMSB then nextChasedMSB = msg:byte(3)
                            end
                        end
                    elseif msg2 == mouseOrigCCLane-224 then 
                        if flags&1 == 1 then mustDeselect = true end
                        if msg1&0x0F == activeChannel then
                            if runningPPQPos < snappedOrigPPQPos then lastChasedLSB = msg:byte(3)
                            elseif not nextChasedLSB then nextChasedLSB = msg:byte(3)
                            end
                        end
                    end
                end
            elseif laneIsCHANPRESS then 
                if msg1>>4 == 13 then 
                    if flags&1 == 1 then mustDeselect = true end
                    if msg1&0x0F == activeChannel then
                        if runningPPQPos < snappedOrigPPQPos then lastChasedValue = msg2 
                        elseif not nextChasedValue then nextChasedValue = msg2 
                        end
                    end
                end
            end
        end -- if msg:len() >= 2
        
        if mustDeselect then
            if unchangedPos < prevPos then
                t = t + 1
                tEvents[t] = MIDIString:sub(unchangedPos, prevPos-1)
            end
            t = t + 1
            tEvents[t] = s_pack("i4Bs4", offset, flags&0xFE, msg)
            unchangedPos = nextPos
        end 
        
    end -- while nextPos <= MIDILen    
    
    MIDIStringDeselected = table.concat(tEvents) .. MIDIString:sub(unchangedPos, nil)
    -- Finalize chased values, and combine 14-bit CC chased values, if necessary
    if laneIsCC14BIT then
        if not lastChasedLSB then lastChasedLSB = 0 end
        if not nextChasedLSB then nextChasedLSB = 0 end
        if lastChasedMSB then lastChasedValue = (lastChasedMSB<<7) + lastChasedLSB end
        if nextChasedMSB then nextChasedValue = (nextChasedMSB<<7) + nextChasedLSB end
    end
    if not lastChasedValue then lastChasedValue = mouseOrigCCValue end
    if not nextChasedValue then nextChasedValue = mouseOrigCCValue end      
    
end


--##############################################################################
--------------------------------------------------------------------------------
function DeleteExistingCCsInRange()  
            
    -- The MIDI strings of non-deleted events will temnporarily be stored in a table, tRemainingEvents[],
    --    and once all MIDI data have been parsed, this table (which excludes the strings of targeted events)
    --    will be concatenated to replace the original MIDIString.
    -- The targeted events will therefore have been extracted from the MIDI string.
    local tRemainingEvents = {}     
    local r = 0 -- Count index in tRemainingEvents - This is faster than using table.insert or even #table+1 

    local newOffset = 0
    local runningPPQPos = 0 -- The MIDI string only provides the relative offsets of each event, so the actual PPQ positions must be calculated by iterating through all events and adding their offsets
    local lastRemainPPQPos = 0 -- PPQ position of last event that was *not* targeted, and therefore stored in tRemainingEvents.
    local prevPos, nextPos, unchangedPos = 1, 1, 1 -- Keep record of position within MIDIString. unchangedPos is position from which unchanged events van be copied in bulk.
    local mustUpdateNextOffset -- If an event has bee deleted from the MIDI stream, the offset of the next remaining event must be updated.
    
    -- Give default values to variables, in case the deferred drawing function has quit before completing a single loop and assigning values to tehse variables
    snappedNewPPQPos = snappedNewPPQPos or snappedOrigPPQPos
    lineLeftPPQPos   = lineLeftPPQPos   or snappedOrigPPQPos 
    lineRightPPQPos  = lineRightPPQPos  or snappedOrigPPQPos
    lastPPQPos = lastPPQPos or 0
    
    --------------------------------------------------------------------------------------------------
    -- Iterate through all the (original) MIDI in the take, searching for events to delete or deselect
    local MIDILen = #MIDIString
    while nextPos <= MIDILen do
       
        local offset, flags, msg
        local mustDelete  = false
        local mustDeselect = false
        
        prevPos = nextPos
        offset, flags, msg, nextPos = s_unpack("i4Bs4", MIDIString, prevPos)
        
        -- A little check if parsing is still OK
        if flags&252 ~= 0 then -- 252 = binary 11111100.
            reaper.ShowMessageBox("The MIDI data uses an unknown format that could not be parsed.  No events will be deleted."
                                  .. "\n\nPlease report the problem in the thread http://forum.cockos.com/showthread.php?t=176878:"
                                  .. "\nFlags = " .. string.char(flags)
                                  .. "\nMessage = " .. msg
                                  , "ERROR", 0)
            return false
        end
        
        -- runningPPQPos must be updated for all events, even if not selected etc
        runningPPQPos = runningPPQPos + offset
                                            
        -- If event within line PPQ range, check whether must delete
        if runningPPQPos >= lineLeftPPQPos and runningPPQPos <= lineRightPPQPos then
            if msg:byte(1) & 0x0F == activeChannel or deleteOnlyDrawChannel == false then
                local eventType = msg:byte(1)>>4
                local msg2      = msg:byte(2)
                if laneIsCC7BIT then if eventType == 11 and msg2 == mouseOrigCCLane then mustDelete = true end
                elseif laneIsPITCH then if eventType == 14 then mustDelete = true end
                elseif laneIsCC14BIT then if eventType == 11 and (msg2 == mouseOrigCCLane-224 or msg2 == mouseOrigCCLane-256) then mustDelete = true end
                elseif laneIsCHANPRESS then if eventType == 13 then mustDelete = true end
                end
            end
        end
        
        -- Even if outside PPQ range, must still deselect if in lane
        if deselectEverythingInLane == true and flags&1 == 1 and not mustDelete then -- Only necessary to deselect if not already mustDelete
            local eventType = msg:byte(1)>>4
            local msg2      = msg:byte(2)
            if laneIsCC7BIT then if eventType == 11 and msg2 == mouseOrigCCLane then mustDeselect = true end
            elseif laneIsPITCH then if eventType == 14 then mustDeselect = true end
            elseif laneIsCC14BIT then if eventType == 11 and (msg2 == mouseOrigCCLane-224 or msg2 == mouseOrigCCLane-256) then mustDeselect = true end
            elseif laneIsCHANPRESS then if eventType == 13 then mustDeselect = true end
            end
        end
        
        -------------------------------------------------------------------------------------
        -- This section will try to speed up parsing by not inserting each event individually
        --    into the table.  Unchanged events will be copied as larger blocks.
        -- This does make things a bit complicated, unfortunately...
        if mustDelete then
            -- The chain of unchanged events is broken, so write to tRemainingEvents, if necessary
            if unchangedPos < prevPos then
                r = r + 1
                tRemainingEvents[r] = MIDIString:sub(unchangedPos, prevPos-1)
            end
            unchangedPos = nextPos
            mustUpdateNextOffset = true
        elseif mustDeselect then
            -- The chain of unchanged events is broken, so write to tRemainingEvents, if necessary
            if unchangedPos < prevPos then
                r = r + 1
                tRemainingEvents[r] = MIDIString:sub(unchangedPos, prevPos-1)
            end
            r = r + 1
            tRemainingEvents[r] = s_pack("i4Bs4", runningPPQPos - lastRemainPPQPos, flags&0xFE, msg)
            lastRemainPPQPos = runningPPQPos
            unchangedPos = nextPos
            mustUpdateNextOffset = false
        elseif mustUpdateNextOffset then
            r = r + 1
            tRemainingEvents[r] = s_pack("i4Bs4", runningPPQPos-lastRemainPPQPos, flags, msg)
            lastRemainPPQPos = runningPPQPos
            unchangedPos = nextPos
            mustUpdateNextOffset = false
        else
            lastRemainPPQPos = runningPPQPos
        end
        
    end -- while nextPos <= MIDILen   
    
    -- Insert all remaining unchanged events
    r = r + 1
    tRemainingEvents[r] = MIDIString:sub(unchangedPos) 

    ------------------------
    -- Upload into the take!
    reaper.MIDI_SetAllEvts(activeTake, table.concat(tLine) .. string.pack("i4Bs4", -lastPPQPos, 0, "") .. table.concat(tRemainingEvents))                                                                    
               
end -- function deleteExistingCCsInRange


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
    
    Tooltip("Armed: Draw ramp")

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

    local startTime = reaper.time_precise()

    -- Before doing anything that may terminate the script, use this trick to avoid automatically 
    --    creating undo states if nothing actually happened.
    -- Undo_OnStateChange will only be used if reaper.atexit(exit) has been executed
    reaper.defer(function() end)  
       

    -- Check whether SWS and my own extension are available, as well as the required version of REAPER
    if not reaper.JS_Window_FindEx then
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
    --[[filename = filename:gsub("\\", "/") -- Change Windows format to cross-platform
    filename = filename:match("^.*/") -- Remove script filename, keeping directory
    filename = filename .. "js_Mouse editing - Draw LFO.cur"
    cursor = reaper.JS_Mouse_LoadCursorFromFile(filename) -- The first time that the cursor is loaded in the session will be slow, but afterwards the extension will re-use previously loaded cursor
    if not cursor then cursor = reaper.JS_Mouse_LoadCursor(527) end -- If .cur file unavailable, load one of REAPER's own cursors]]
    cursor = reaper.JS_Mouse_LoadCursor(185)
    if cursor then reaper.JS_Mouse_SetCursor(cursor) end
    
    if sectionID ~= nil and commandID ~= nil and sectionID ~= -1 and commandID ~= -1 then
        origToggleState = reaper.GetToggleCommandStateEx(sectionID, commandID)
        reaper.SetToggleCommandState(sectionID, commandID, 1)
        reaper.RefreshToolbar2(sectionID, commandID)
    end
    
    
    -- CHECK USER VALUES:
    -- Check whether the user-customizable values are usable.
    if not (type(neverSnapToGrid) == "boolean") then 
        reaper.MB('The parameter "neverSnapToGrid" may only take on the boolean values "true" or "false".', "ERROR", 0)
        return false 
    elseif not (type(deleteOnlyDrawChannel) == "boolean") then 
        reaper.MB('The parameter "deleteOnlyDrawChannel" may only take on the boolean values "true" or "false".', "ERROR", 0)
        return false
    elseif not (type(deselectEverythingInLane) == "boolean") then 
        reaper.MB('The parameter "deselectEverythingInLane" may only take on the boolean values "true" or "false".', "ERROR", 0)
        return false      
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
                                
                                ::loopUntilMouseEntersCCLane::
                                mouseOrigCCLaneID = GetCCLaneIDFromPoint(mouseOrigX, mouseOrigY) 
                                if mouseOrigCCLaneID and mouseOrigCCLaneID%1 ~= 0 then 
                                    mouseStartedOnLaneDivider = true; 
                                    _, mouseOrigY = reaper.GetMousePosition(); 
                                    _, mouseOrigY = reaper.JS_Window_ScreenToClient(midiview, mouseOrigX, mouseOrigY)
                                    goto loopUntilMouseEntersCCLane 
                                end
                                
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
            
                ::loopUntilMouseEntersCCLane::
                window, segment, details = reaper.BR_GetMouseCursorContext()    
                editor, isInline, mouseOrigPitch, mouseOrigCCLane, mouseOrigCCValue, mouseOrigCCLaneID = reaper.BR_GetMouseCursorContext_MIDI() 
                if details == "cc_lane" and mouseOrigCCValue == -1 then mouseStartedOnLaneDivider = true; goto loopUntilMouseEntersCCLane end
                
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
        elseif not mouseOrigCCLane then
             reaper.MB("One or more of the CC lanes are of unknown type, and could not be parsed by this script.", "ERROR", 0)
        end
        return false
    end
    if not (laneIsCC7BIT or laneIsCC14BIT or laneIsCHANPRESS or laneIsPITCH) then
        reaper.MB("This script will only work in the following MIDI lanes: \n * 7-bit CC, \n * 14-bit CC, \n * Pitch, or\n * Channel Pressure."
                .. "\n\nTo inform the script which lane must be edited, the mouse must be positioned inside that lane when the script starts."
                .. "\n\nTo ensure that the ramp starts at the minimum or maximum value, position the mouse over a lane divider and then move the mouse into the target lane."
                , "ERROR", 0)  
        return false 
    end
    
    
    -- MOUSE STARTING CC VALUE:
    -- As mentioned above, if the mouse starts on the divider between lanes, the lane is undetermined, 
    --    so the script must loop till the user moves the mouse into a lane.
    -- To optimize responsiveness, the script has done some other stuff before re-visiting the mouse position.
    if mouseStartedOnLaneDivider then
        if mouseOrigCCValue > (laneMaxValue + laneMinValue)/2 then
            mouseOrigCCValue = laneMaxValue
        else 
            mouseOrigCCValue = laneMinValue
        end
    elseif mouseOrigCCValue > laneMaxValue then mouseOrigCCValue = laneMaxValue
    elseif mouseOrigCCValue < laneMinValue then mouseOrigCCValue = laneMinValue
    else mouseOrigCCValue = math.floor(mouseOrigCCValue+0.5)
    end


    -- MOUSE STARTING PPQ POSITION:
    -- Get mouse starting PPQ position -- AND ADJUST FOR LOOPING AND SNAP-TO-GRID
    if isInline then
        mouseOrigPPQPos = reaper.MIDI_GetPPQPosFromProjTime(activeTake, reaper.BR_GetMouseCursorContext_Position())
    elseif ME_TimeBase == "beats" then
        mouseOrigPPQPos = ME_LeftmostTick + mouseOrigX/ME_PixelsPerTick
    else -- ME_TimeBase == "time"
        mouseOrigPPQPos  = reaper.MIDI_GetPPQPosFromProjTime(activeTake, ME_LeftmostTime + mouseOrigX/ME_PixelsPerSecond )
    end
    
    
    -- If snapping is enabled, the PPQ position must be adjusted to nearest grid.
    -- If snapping is not enabled, snappedOrigPPQPos = mouseOrigPPQPos, snapped to nearest tick
    
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
    maximumTick = math.floor(math.min(itemLastVisibleTick, sourceLengthTicks-1)) -- I prefer not to draw any event on the same PPQ position as the All-Notes-Off
    
    -- The rest of the function will work with snappedOrigPPQPos.
    if isInline then
        isSnapEnabled = (reaper.GetToggleCommandStateEx(0, 1157) == 1)
        -- Even is snapping is disabled, need PPperGrid and QNperGrid for LFO length
        local _, gridDividedByFour = reaper.GetSetProjectGrid(0, false) -- Arrange grid and MIDI grid are returned in different units
        QNperGrid = gridDividedByFour*4
    else
        isSnapEnabled = (reaper.MIDIEditor_GetSetting_int(editor, "snap_enabled") == 1)
        QNperGrid, _, _ = reaper.MIDI_GetGrid(activeTake) -- Quarter notes per grid
    end
    -- Unique to the Draw ramp scripts: the neverSnapToGrid option
    if neverSnapToGrid then isSnapEnabled = false end -- !!!!!!!!!!!!!!1
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
    end 
    snappedOrigPPQPos = math.max(minimumTick, math.min(maximumTick, snappedOrigPPQPos)) 
    
  
    -- CC DRAWING DENSITY:
    -- If the CCs are being drawn in the "Tempo" track, CCs will be inserted at the MIDI editor's grid spacing.
    -- In all other cases, CCs density will follow the setting in Preferences -> MIDI editor -> "Events per quarter note when drawing in CC lanes".
    local track = reaper.GetMediaItemTake_Track(activeTake)
    local trackNameOK, trackName = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)
    
    if trackName == "Tempo" then
        local QNperCC = reaper.MIDI_GetGrid(activeTake)
        CCDensity = math.floor((1/QNperCC) + 0.5)
    else
        CCDensity = reaper.SNM_GetIntConfigVar("midiCCdensity", 32)
        CCDensity = m_floor(math.max(4, math.min(512, math.abs(CCDensity)))) -- If user selected "Zoom dependent", density<0
    end
    local startQN = reaper.MIDI_GetProjQNFromPPQPos(activeTake, 0)
    PPQ = reaper.MIDI_GetPPQPosFromProjQN(activeTake, startQN+1)
    PPerCC = PPQ/CCDensity -- Not necessarily an integer! 
    firstCCinTakePPQPos = reaper.MIDI_GetPPQPosFromProjQN(activeTake, math.ceil(startQN*CCDensity)/CCDensity)    


    -- GET AND PARSE MIDI:
    -- Time to process the MIDI of the take!
    -- As mentioned in the header, this script does not use the old-fashioned MIDI API functions such as 
    --    MIDI_InsertCC, since these functions are far too slow when dealing with thousands of events.
    getAllOK, MIDIString = reaper.MIDI_GetAllEvts(activeTake, "")
        if not getAllOK then reaper.MB("MIDI_GetAllEvts could not load the raw MIDI data.", "ERROR", 0) return false end
    -- Deselect existing CCs in lane, and find chased values
    ParseMIDIString_DeselectAndFindChasedValues()
    
 
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
    

    -- START LOOPING!
    DEFERLOOP_pcall()
    
end -- function Main()


--################################################
--------------------------------------------------
MAIN()


--[[
  Changelog:
  * v1.0 (2016-05-05)
    + Initial Release
  * v1.1 (2016-05-18)
    + Added compatibility with SWS versions other than 2.8.3 (still compatible with v2.8.3)
    + Improved speed and responsiveness
  * v1.11 (2016-05-29)
    + Script does not fail when "Zoom dependent" CC density is selected in Preferences
    + If linked to a menu button, script will toggle button state to indicate activation/termination
  * v1.12 (2016-06-02)
    + Few tweaks to improve appearance of real-time ramp when using very low CC density
  * v2.0 (2016-07-04)
    + All the "lane under mouse" js_ scripts can now be linked to toolbar buttons and run using a single shortcut.
    + Description and instructions are included inside script - please read with REAPER's built-in script editor.
  * v2.10 (2016-10-23)
    + Header updated to ReaPack v1.1 format.
    + Chasing will only match CCs in active channel.
  * v3.00 (2016-11-18)
    + Option to skip redundant events.
    + IMPROVED, NEAR-NATIVE SPEED!  (Especially in items with >100000 MIDI events.)
  * v3.01 (2016-11-19)
    + Script works with takes in which first MIDI message is sysex.
  * v3.10 (2016-12-10)
    + Improved speed, using new API functions of REAPER v5.30. 
  * v3.11 (2017-01-09)
    + Updated for REAPER v.5.32.
    + Ramps are drawn in front of other selected events in lane.
    + Script works in looped takes.
    + Script works in inline editor, but can only draw in channel 1.
  * v3.20 (2017-01-21)
    + Allow drawing of ramp from a starting position on lane divider.
    + New option "neverSnapToGrid".
    + New option "defaultShapePower".
  * v3.21 (2017-01-30)
    + Improved reset of toolbar button.
  * v3.22 (2017-03-13)
    + Temporary workaround for 'disappearing CCs' bug in MIDI editor.
    + In Tempo track, insert CCs (tempos) at MIDI editor grid spacing.    
  * v3.23 (2017-03-14)
    + Fix chasing bug that was introduced yesterday.
  * v3.24 (2017-03-18)
    + More extensive instructions in header.
  * v3.30 (2017-07-23)
    + Mouse cursor changes to indicate that script is running.  
  * v3.31 (2017-12-14)
    + Tweak mouse cursor icon.
  * v3.32 (2018-04-15)
    + Automatically install script in MIDI Inline Editor section.
  * v3.33 (2018-04-21)
    + Skipping redundant events can be toggled by separate script.
  * v3.34 (2018-05-29)
    + Return focus to MIDI editor after arming button in floating toolbar.
    + Script will recall last-used curve shape.
  * v3.51 (2018-09-09)
    + Snap to closest grid, instead of preceding grid.
]]
