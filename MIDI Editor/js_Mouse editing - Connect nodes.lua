--[[
ReaScript name: js_Mouse editing - Connect nodes.lua
Version: 4.02
Author: juliansader
Screenshot: http://stash.reaper.fm/27617/Insert%20linear%20or%20shaped%20ramps%20between%20selected%20CCs%20or%20pitches%20in%20lane%20under%20mouse%20-%20Copy.gif
Website: http://forum.cockos.com/showthread.php?t=176878
Donation: https://www.paypal.me/juliansader
Provides: [main=midi_editor,midi_inlineeditor] .
About:
  # DESCRIPTION:

  Inserts CCs between selected "nodes" in the CC lane under the mouse.  

  * Useful for smoothing transitions between CCs that were drawn at low resolution.
  
  * Useful for converting a set of nodes into an LFO with any desired curve shape.


  MODES: WARP and BËZIER:
  
  The script offers two modes (selected by right-clicking the mouse):

  * Warp: The user can the shape of the connecting ramps by moving the mouse.
  
  * Bézier: The script tries to find the smoothest curve to connect all selected nodes. Moving the mouse does not affect the curve.


  MOUSE MOVEMENT AND WARPING:
  
  The Warp mode resembles the "js_Mouse editing - Warp" script, except that the Warp script would warp all ramps and all selected events together,
      whereas this script warps each ramp individually, without changing the position of values of the nodes.
  Moving the mouse left and right warps each individual ramp horizontally, and moving up and down warps each ramp vertically.
  All kinds of shapes can be created, from straight lines to "fast start", "fast end", and sine (aka "slow start / slow end".
  
  
  MOUSE BUTTONS:
    
  Left button: Terminates the script.
  Middle button: In Warp mode, switches between linear/power curves and sine-based curves.
  Right button: Switches between modes.
  
  
  MOUSEWHEEL AND MIDI CHANNELS:
  
  * The mousewheel changes the channel of the inserted MIDI events.
  * If the MIDI editor is set to "Edit only the active MIDI channel", the script will only select nodes that are in the active channel.
  These channel features are very useful for keeping the ramps and the nodes in separate channels, so that the nodes can easily be re-selected and edited.
  
  
  OTHER NOTES:
  
  * The "Connect nodes" script is often used directly after the "Extract nodes" script, and these can usefully be combined in a single custom action, 
      so that both can be run with a single shortcut.
      
  * The scripts works in inline MIDI editors as well as main MIDI editors.
  
  * New CCs will be inserted at the MIDI editor's default density that is set in Preferences -> CC density.

  * Any extraneous CCs between selected events will deleted.
  
  * The script can optionally skip redundant CCs (that is, CCs with the same value as the preceding CC), 
      if the control script "js_Option - Toggle skip redundant events when inserting CCs" is toggled on.
  
  
  
  # INSTRUCTIONS

  1) Select the "node" CCs between which ramps will be inserted.
  
  2) Position mouse over the target CC lane.
  
  3) Press the shortcut key. (Do not press any mouse button.)
  
  4) Move the mouse or mousewheel to shape the ramps.
  
  5) To stop the script, move the mouse out of the CC lane, or press the shortcut key again. 
  
  
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
    
    
  PERFORMANCE TIP: The responsiveness of the MIDI editor is significantly influenced by the total number of events in 
      the visible and edit takes.  If the MIDI editor is slow, try reducing the number of edit and visible tracks.
      
  PERFORMANCE TIP 2: If the MIDI editor gets slow and jerky when a certain VST plugin is loaded, 
      check for graphics driver incompatibility by disabling graphics acceleration in the plugin.
]] 

--[[
  Changelog:
  * v4.00 (2019-01-19)
    + Updated for js_ReaScriptAPI extension.
    + Script can be controlled by mousewheel and mouse buttons.
    + New mode: Bézier smoothing.
    + Ramps can be inserted in different channel than nodes.
  * v4.01 (2019-02-11)
    + Restore focus to original window, if script opened notification window.
  * v4.02 (2019-02-16)
    + Fixed: On Linux, crashing if editor closed while script is running.
]]
 

-- ################################################################################################
---------------------------------------------------------------------------------------------------
-- CONSTANTS AND VARIABLES (that modders may find useful)

local MIDIString -- The original raw MIDI data returned by GetAllEvts
local remainMIDIString -- The MIDI that remained after extracting selected events in the target lane
local tEditedMIDI = {} -- The edited MIDI events will be stored in this table, ready to be concatenated to remainMIDIString.

-- When the info of the targeted events is extracted, the info will be stored in several tables.
-- The order of events in the tables will reflect the order of events in the original MIDI, except note-offs, 
--    which will be replaced by note lengths, and notation text events, which will also be stored in a separate table
--    at the same indices as the corresponding notes.
-- (Not all scripts use all of these tables - depends on which lanes are usable.)
local tMsg = {}
local tMsgLSB = {}
--local tMsgNoteOffs = {}
local tValues = {} -- CC values, 14bit CC combined values, note velocities
local tPPQs = {}
local tChannels = {}
local tFlags = {}
local tFlagsLSB = {} -- In the case of 14bit CCs, mute/select status of the MSB
--local tPitches = {} -- This table will only be filled if laneIsVELOCITY or laneIsPIANOROLL
--local tNoteLengths = {}
--local tNotation = {} -- Will only contain entries at those indices where the notes have notation


-- The original value and PPQ ranges of selected events in the target lane will be summarized in:
local origValueMin, origValueMax, origValueRange, origValueLeftmost, origValueRightmost = nil, nil, nil, nil, nil
local origPPQleftmost, origPPQrightmost, origPPQRange = nil, nil, nil
--local includeNoteOffsInPPQRange = true -- ***** Should origPPQRange and origPPQrightmost take note-offs into account? Set this flag to true for scripts that stretch or warp note lengths. *****
 
-- Starting values and position of mouse 
-- Not all of these lanes will be used by all scripts.
-- mouseOrigCCLane: (CC0-127 = 7-bit CC, 0x100|(0-31) = 14-bit CC, 0x200 = velocity, 0x201 = pitch, 
--    0x202=program, 0x203=channel pressure, 0x204=bank/program select, 
--    0x205=text, 0x206=sysex, 0x207=off velocity)
local mouseOrigX, mouseOrigY
local laneMinValue, laneMaxValue = nil, nil -- The minimum and maximum values in the target lane
local mouseOrigCCLane, mouseOrigCCValue, mouseOrigPPQPos, mouseOrigPitch, mouseOrigCCLaneID = nil, nil, nil, nil, nil
local snappedOrigPPQPos = nil -- If snap-to-grid is enabled, these will give the closest grid PPQ to the left. (Swing is not implemented.)

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

-- REAPER preferences and settings that will affect the drawing/selecting of new events in take
local isSnapEnabled = false -- Will be changed to true if snap-to-grid is enabled in the editor
local activeChannel -- In case new MIDI events will be inserted, what is the default channel?
local editAllChannels = nil -- Is the MIDI editor's channel filter enabled?
local CCDensity -- CC resolution as set in Preferences -> MIDI editor -> "Events per quarter note when drawing in CC lanes"
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
local minimumTick, maximumTick -- The mouse PPO position should not go outside the boundaries of either the visible item or the underlying MIDI source

-- Some internal stuff that will be used to set up everything
local  _, activeItem, activeTake
local window, segment, details = nil, nil, nil -- given by the SWS function reaper.BR_GetMouseCursorContext()
local startTime, prevMousewheelTime = 0, 0 -- To ensure that a single mouse click or mousewheel movement doesn't trigger multiple actions, new events must be little later than last one.
local lastPPQPos = 0 -- To calculate offset to next CC
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

-- User preferences that can be customized via toggle scripts
local skipRedundantCCs  = (reaper.GetExtState("js_Mouse actions", "skipRedundantCCs") == "true") -- false by default, so that new users aren't surprised by missing CCs
local newCCsAreSelected = (reaper.GetExtState("js_Mouse actions", "newCCsAreSelected") ~= "false") -- true by default

-- User preferences that can be customized via toggle scripts
-- skipRedundantCCs -- Will be checked in each defer cycle, since ay be changed while script is running.

-- Window messages that will be intercepted while the script is running
local tWM_Messages = {WM_LBUTTONDOWN = false, WM_LBUTTONDBLCLK = false, WM_LBUTTONUP = false,
                      WM_MBUTTONDOWN = false, WM_MBUTTONDBLCLK = false, WM_MBUTTONUP = false,
                      WM_RBUTTONDOWN = false, WM_RBUTTONDBLCLK = false, WM_RBUTTONUP = false,
                      WM_NCMOUSEMOVE = false, -- I'm not sure... Does this prevent REAPER from changing the mouse cursor when it's over scrollbars?
                      WM_MOUSEWHEEL  = false, WM_MOUSEHWHEEL   = false,
                      WM_SETCURSOR   = false}                 
  
-- Unique to this script:
local lastState = (reaper.GetExtState("js_Insert ramps", "Last state") or "")
local newEventsAddChannel, mode, curve = lastState:match("([^,]+),([^,]+),([^,]+)")
newEventsAddChannel = math.floor(tonumber(newEventsAddChannel) or 0)
mode = "BÉZIER" -- (mode == "WARP") and "WARP" or "BÉZIER" -- default is Bézier
curve = "LINEAR" -- (curve == "LINEAR") and "LINEAR" or "SINE" -- default is linear

local tSortedIndices = {} -- Instead of calling MIDI_Sort at the beginning of the script, the entries in this table will be the sorted indices.
local tSlopes = {} -- For Bézier or Hermite curves, the optimal slope at each node must be calcaulated.
local tNextInChannel, tPrevInChannel = {}, {} -- In case nodes are multiple channel, where are the next/previous node in same channel?
local tBezier = {}

  
--#############################################################################################
-----------------------------------------------------------------------------------------------
-- The function that will be 'deferred' to run continuously
-- There are three bottlenecks that impede the speed of this function:
--    Minor: reaper.BR_GetMouseCursorContext(), which must unfortunately unavoidably be called before 
--           reaper.BR_GetMouseCursorContext_MIDI(), and which (surprisingly) gets much slower as the 
--           number of MIDI events in the take increases.
--           ** This script will therefore determine the MIDI editor on-screen layout itself **
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

    -- TAKE STILL VALID?
    if not reaper.ValidatePtr2(0, activeTake, "MediaItem_Take*") then return false end
    
    -- EXTSTATE: Other scripts can communicate with and control the other js_ scripts via ExtStates
    local extState = reaper.GetExtState("js_Mouse actions", "Status") or ""
    if extState == "" or extState == "Must quit" then return(false) end
    
    -- TAKE VALID? or perhaps been deleted? 
    if not reaper.ValidatePtr2(0, activeTake, "MediaItem_Take*") then return false end 

    -- MOUSE MODIFIERS / LEFT CLICK: (If the left mouse button or any modifier key is pressed, after first releasing them, quit.)
    -- This can detect left clicks even if the mouse is outside the MIDI editor
    local prevMouseState = mouseState or 0xFF
    mouseState = reaper.JS_Mouse_GetState(0xFF)
    if (mouseState&61) > (prevMouseState&61) then -- 61 = 0b00111101 = Ctrl | Shift | Alt | Win | Left button
        return false
    end

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
        if reaper.MIDIEditor_GetMode(editor) ~= 0 then return false end
        local rOK, l, t, r, b = reaper.JS_Window_GetRect(editor) -- Faster than Window_From Point. Use Rect instead of ClientRect so that mouse can go onto scrollbar
        if not (rOK and l==ME_l and t==ME_t and r==ME_r and b==ME_b) then
            return false
        end
        -- Mouse can't go outside MIDI editor, unless left-dragging (to ensure that user remembers that script is running)
        if mouseState&1 == 0 and (mouseX < l or mouseY < t or mouseX >= r or mouseY >= b) then
           return false
        end
        -- If mouse is outside midiview, WM_SETCURSOR isn't blocked
        if (mouseX < ME_midiviewLeftPixel or mouseY > ME_midiviewTopPixel or mouseX > ME_midiviewRightPixel or mouseY > ME_midiviewBottomPixel) and cursor then
            reaper.JS_Mouse_SetCursor(cursor)
        end
    end    
    
    -- MOUSEWHEEL:
    local peekOK, pass, time, keys, delta = reaper.JS_WindowMessage_Peek(windowUnderMouse, "WM_MOUSEWHEEL")
    if not (peekOK and time > prevMouseTime) then 
        peekOK, pass, time, keys, delta = reaper.JS_WindowMessage_Peek(windowUnderMouse, "WM_MOUSEHWHEEL")
    end 
    if peekOK and time > prevMouseTime + 0.2 then 
        if keys&12 ~= 0 then -- Ctrl or shift keys
            return false
        elseif delta > 0 then
            newEventsAddChannel = (newEventsAddChannel + 17)%32 - 16
        else
            newEventsAddChannel = (newEventsAddChannel + 15)%32 - 16
        end
        prevMouseTime = time
        mustCalculate = true
    end
    if newEventsAddChannel ~= prevEventsAddChannel then
        local sign = (newEventsAddChannel >= 0) and "+" or ""
        Tooltip("Channel"..sign..tostring(newEventsAddChannel))
        prevEventsAddChannel = newEventsAddChannel
    end

    -- LEFT DRAG: (If the left button was kept pressed for 1 second or longer, or after moving the mouse 20 pixels, assume left-drag, so quit when lifting.)
    peekOK, pass, time = reaper.JS_WindowMessage_Peek(windowUnderMouse, "WM_LBUTTONUP")
    if peekOK and (time > startTime + 1)
              --or  (time > startTime and (mouseX < mouseOrigX - 20 or mouseX > mouseOrigX + 20 or mouseY < mouseOrigY - 20 or mouseY > mouseOrigY + 20))) 
              then
        return false
    end
    
    -- LEFT CLICK: (If the left mouse button or any modifier key is pressed, after first releasing them, quit.)
    peekOK, pass, time = reaper.JS_WindowMessage_Peek(windowUnderMouse, "WM_LBUTTONDOWN")
    if peekOK and time > startTime then 
        return false 
    end
    
    -- MIDDLE BUTTON: Middle button changes curve shape
    peekOK, pass, time = reaper.JS_WindowMessage_Peek(windowUnderMouse, "WM_MBUTTONDOWN")
    if peekOK and time > prevMouseTime then 
        if mode == "WARP" then
            curve = (curve == "LINEAR") and "SINE" or "LINEAR"
        else
            mode = "WARP"
        end
        Tooltip("Curve: "..curve)
        prevMouseTime = time
        mustCalculate = true
    end
    
    -- RIGHT CLICK: Right click changes script mode
    --    * If script is terminated by right button, disarm toolbar.
    --    * REAPER shows context menu when right button is *lifted*, so must continue intercepting mouse messages until right button is lifted.
    peekOK, pass, time = reaper.JS_WindowMessage_Peek(windowUnderMouse, "WM_RBUTTONDOWN")
    if peekOK and time > prevMouseTime then
        mode = (mode == "WARP") and "BÉZIER" or "WARP"
        Tooltip("Mode: "..mode)
        prevMouseTime = time
        mustCalculate = true
    end
 
        
    ---------------------------------------------
    -- MUST CALCULATE?
    -- Scripts that extract selected MIDI events and re-concatenate them out of order (usually at the beginning of the MIDI string, for easier editing)
    --    cannot be auditioned in real-time while events are out of order, since such events are not played.
    -- If the mouse is held still, no editing is done, and instead the take is sorted, thereby temporarily allowing playback.
    -- NO NEED TO CALCULATE:
    if not mustCalculate then --and not takeIsSorted then
        if not takeIsSorted then
            reaper.MIDI_Sort(activeTake)
            takeIsSorted = true
        end        
        
    else        
        takeIsSorted = false
      
        -- MOUSE NEW CC VALUE (vertical position)
        if isInline then
            -- reaper.BR_GetMouseCursorContext was already called above
            _, _, mouseNewPitch, mouseNewCCLane, mouseNewCCValue, mouseNewCCLaneID = reaper.BR_GetMouseCursorContext_MIDI()
            -- Convert BR function's laneID return value to same as this script's GetCCLaneIDFromPoint
            if details == "cc_lane" and mouseOrigCCValue == -1 then mouseOrigCCLaneID = mouseOrigCCLaneID - 0.5 end  
            if mouseNewCCLaneID     > mouseOrigCCLaneID 
                then mouseNewCCValue = laneMinValue
            elseif mouseNewCCLaneID < mouseOrigCCLaneID or mouseNewCCValue == -1 
                then mouseNewCCValue = laneMaxValue
            end
        else
            if mouseOrigPitch and mouseOrigPitch ~= -1 then
                mouseNewPitch = ME_TopPitch - math.ceil((mouseY - tME_Lanes[-1].ME_TopPixel) / ME_PixelsPerPitch)
                mouseNewPitch = -1
            elseif mouseOrigCCValue and mouseOrigCCValue ~= -1 then      
                mouseNewPitch = -1                               
                mouseNewCCValue = laneMinValue + (laneMaxValue-laneMinValue) * (mouseY - tME_Lanes[mouseOrigCCLaneID].ME_BottomPixel) / (tME_Lanes[mouseOrigCCLaneID].ME_TopPixel - tME_Lanes[mouseOrigCCLaneID].ME_BottomPixel)
            end
        end
        -- In some scripts, the mouse CC value may go beyond lane limits
        if mouseNewCCValue ~= mouseNewCCValue then mouseNewCCValue = laneMaxValue
        elseif mouseNewCCValue > laneMaxValue  then mouseNewCCValue = laneMaxValue
        elseif mouseNewCCValue < laneMinValue  then mouseNewCCValue = laneMinValue
        else mouseNewCCValue = math.floor(mouseNewCCValue+0.5)
        end
    
        -- MOUSE NEW TICK / PPQ VALUE (horizontal position)
        -- Snapping not relevant to this script
        --[[if isInline then
            -- A call to BR_GetMouseCursorContext must always precede the other BR_ context calls
            mouseNewPPQPos = reaper.MIDI_GetPPQPosFromProjTime(activeTake, reaper.BR_GetMouseCursorContext_Position())
        elseif ME_TimeBase == "beats" then
            mouseNewPPQPos = ME_LeftmostTick + (mouseX-ME_midiviewLeftPixel)/ME_PixelsPerTick
        else -- ME_TimeBase == "time"
            mouseNewPPQPos = reaper.MIDI_GetPPQPosFromProjTime(activeTake, ME_LeftmostTime + (mouseX-ME_midiviewLeftPixel)/ME_PixelsPerSecond )
        end
        mouseNewPPQPos = mouseNewPPQPos - loopStartPPQPos -- Adjust mouse PPQ position for looped items
        mouseNewPPQPos = math.max(minimumTick, math.min(maximumTick, mouseNewPPQPos))
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
        end]]
        
        ----------------------------------------------------------
        -- CALCULATE THE NEW MIDI EVENTS! - Unique to each script.
        local warpRight, warpUp
        
        -- left-right warping
        local mouseRelativeMovement = isInline and ((mouseX - mouseOrigX)/400) or (1.5*(mouseX-mouseOrigX)/ME_midiviewWidth)
        if mouseRelativeMovement > 0.4999999999999 then mouseRelativeMovement = 0.499999999999 elseif mouseRelativeMovement < -0.499999999999 then mouseRelativeMovement = -0.499999999999 end
        if mouseRelativeMovement >= 0 then warpRight = true end
        local powerLeftRight = math.log(0.5 - math.abs(mouseRelativeMovement), 0.5)
        
        -- up-down warping
        local mouseRelativeMovement = (mouseNewCCValue-laneAvg)/(laneHeight)
        -- Prevent warping too much, so that all CCs don't end up in a solid block
        if mouseRelativeMovement > 0.5 then mouseRelativeMovement = 0.5 elseif mouseRelativeMovement < -0.5 then mouseRelativeMovement = -0.5 end
        if mouseRelativeMovement >= 0 then warpUp = true end
        local powerUpDown = math.log(0.5 - math.abs(mouseRelativeMovement), 0.5)
    
        tEditedMIDI = {} -- Not local, since other functions need to access this
        lastPPQPos = 0
        local c = 0 -- Count index inside tEditedMIDI - strangely, this is faster than using table.insert or even #tEditedMIDI+1
        local offset, PPQPos, PPQRound     
        local flag = newCCsAreSelected and 1 or 0
        
        -----------------------------------
        -- First insert the original event, and then check whether any new events must be inserted between this and the next event in the same channel.
        for s, i in ipairs(tSortedIndices) do 
        
            -- Insert node as *selected* CC (this duplicates the existing node in MIDIString, but the latter will be deleted wen the script terminates)
            if laneIsCC7BIT then
                c = c + 1
                tEditedMIDI[c] = s_pack("i4BI4BBB", tPPQs[i]-lastPPQPos, tFlags[i], 3, 0xB0 | tChannels[i], mouseOrigCCLane, tValues[i])
            elseif laneIsPITCH then
                c = c + 1
                tEditedMIDI[c] = s_pack("i4BI4BBB", tPPQs[i]-lastPPQPos, tFlags[i], 3, 0xE0 | tChannels[i], tValues[i]&127, tValues[i]>>7)
            elseif laneIsCHANPRESS then
                c = c + 1
                tEditedMIDI[c] = s_pack("i4BI4BB",  tPPQs[i]-lastPPQPos, tFlags[i], 2, 0xD0 | tChannels[i], tValues[i])
            elseif laneIsCC14BIT then
                c = c + 1
                tEditedMIDI[c] = s_pack("i4BI4BBB", tPPQs[i]-lastPPQPos, tFlags[i], 3, 0xB0 | tChannels[i], mouseOrigCCLane-256, tValues[i]>>7)
                c = c + 1
                tEditedMIDI[c] = s_pack("i4BI4BBB", 0, tFlagsLSB[i], 3, 0xB0 | tChannels[i], mouseOrigCCLane-224, tValues[i]&127)
            elseif laneIsPROGRAM then
                c = c + 1
                tEditedMIDI[c] = s_pack("i4BI4BB",  tPPQs[i]-lastPPQPos, tFlags[i], 2, 0xC0 | tChannels[i], tValues[i])
            end
            
            lastPPQPos = tPPQs[i]
            -- Each node starts the "skip redundant CCs" anew
            -- If curve is in different channel, no need to set lastValue because node is in different channel
            local lastValue = (newEventsAddChannel ~= 0) and tValues[i] or nil  
            
                
            -- Only need to draw if there is a next node in same channel
            -- Also, if warping left/right is extreme (powerLeftRight is #IND), don't need to insert anything between nodes
            if tNextInChannel[i] and (powerLeftRight == powerLeftRight) then
                local curVal  = tValues[i]
                local curPPQ  = (newEventsAddChannel == 0) and (tPPQs[i] + PPerCC) or tPPQs[i] 
                local nextVal = tValues[tNextInChannel[i]]
                local nextPPQ = tPPQs[tNextInChannel[i]]

                local insertChannel = (tChannels[i]+newEventsAddChannel) % 16
                
                for PPQPos = curPPQ, nextPPQ-1, PPerCC do --nextCCdensityPPQPos, nextPPQ-1, PPerCC do
                    PPQRound = m_floor(PPQPos + 0.5)
                    local insertValue
                  
                    -- mode == "BÉZIER"
                    if mode == "BÉZIER" then
                        insertValue = (tBezier[i] and tBezier[i][PPQRound]) or curVal -- Must be very careful that PPQ position is same as in CalculateBezierCurve function!
                                               
                    -- mode == "WARP"
                    else
                        if curVal == nextVal or powerUpDown ~= powerUpDown then 
                            insertValue = curVal
                        elseif curve == "LINEAR" then 
                            if warpRight then
                                local weight = ((PPQRound - curPPQ) / (nextPPQ - curPPQ))^powerLeftRight
                                insertValue = curVal + (nextVal - curVal)*weight
                            else
                                local weight = ((PPQRound - nextPPQ) / (curPPQ - nextPPQ))^powerLeftRight
                                insertValue = nextVal + (curVal - nextVal)*weight
                            end
                        else -- curve = "SINE"
                            if warpRight then
                                local weight = ((1 - m_cos(m_pi*(PPQRound - curPPQ) / (nextPPQ - curPPQ)))/2)^powerLeftRight
                                insertValue = curVal + (nextVal - curVal)*weight
                            else
                                local weight = ((1 - m_cos(m_pi*(PPQRound - nextPPQ) / (curPPQ - nextPPQ)))/2)^powerLeftRight
                                insertValue = nextVal + (curVal - nextVal)*weight
                            end   
                        end
                         
                        if (warpUp and curVal > nextVal) or (not warpUp and curVal < nextVal) then
                            insertValue = curVal + (nextVal-curVal)*((insertValue - curVal)/(nextVal - curVal))^powerUpDown
                        else
                            insertValue = nextVal + (curVal-nextVal)*((insertValue - nextVal)/(curVal - nextVal))^powerUpDown
                        end
                    end
                    
                    -- Make sure that CC falls within CC range
                    if insertValue ~= insertValue then insertValue = curVal
                    elseif insertValue > laneMaxValue then insertValue = laneMaxValue
                    elseif insertValue < laneMinValue then insertValue = laneMinValue
                    else insertValue = m_floor(insertValue + 0.5)
                    end
 
                    -- If redundant, skip insertion
                    if insertValue ~= lastValue or skipRedundantCCs == false then
                        if laneIsCC7BIT then
                            c = c + 1
                            tEditedMIDI[c] = s_pack("i4BI4BBB", PPQRound-lastPPQPos, flag, 3, 0xB0 | insertChannel, mouseOrigCCLane, insertValue)
                        elseif laneIsPITCH then
                            c = c + 1
                            tEditedMIDI[c] = s_pack("i4BI4BBB", PPQRound-lastPPQPos, flag, 3, 0xE0 | insertChannel, insertValue&127, insertValue>>7)
                        elseif laneIsCHANPRESS then
                            c = c + 1
                            tEditedMIDI[c] = s_pack("i4BI4BB",  PPQRound-lastPPQPos, flag, 2, 0xD0 | insertChannel, insertValue)
                        elseif laneIsCC14BIT then
                            c = c + 1
                            tEditedMIDI[c] = s_pack("i4BI4BBB", PPQRound-lastPPQPos, flag, 3, 0xB0 | insertChannel, mouseOrigCCLane-256, insertValue>>7)
                            c = c + 1
                            tEditedMIDI[c] = s_pack("i4BI4BBB", 0, flag, 3, 0xB0 | insertChannel, mouseOrigCCLane-224, insertValue&127)
                        elseif laneIsPROGRAM then
                            c = c + 1
                            tEditedMIDI[c] = s_pack("i4BI4BB",  PPQRound-lastPPQPos, flag, 2, 0xC0 | insertChannel, insertValue)    
                        end
                        lastValue = insertValue
                        lastPPQPos = PPQRound
                    end -- if not (skipRedundantCCs == true and insertValue == prevCCValue)
                end -- for PPQPos = curPPQ, nextPPQ-1, PPerCC
            end -- if tNextInChannel[i]
        end -- for i, s in tSortedIndices
    
                    
        -----------------------------------------------------------
        -- DRUMROLL... write the edited events into the MIDI chunk!
        reaper.MIDI_SetAllEvts(activeTake, table.concat(tEditedMIDI) .. string.pack("i4Bs4", -lastPPQPos, 0, "") .. MIDIString)

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


--############################################################################################
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
        -- Before exiting, if DEFERLOOP_pcall was successfully executed, delete existing CCs in the line's range (and channel)
        -- The delete function will also ensure that the MIDI is re-uploaded into the active take.
        if pcallOK == true then
            pcallOK, pcallRetval = pcall(DeleteExistingCCsInRange)
        end
        
        -- DEFERLOOP_pcall and DeleteExistingCCsInRange were executed, and no exceptions encountered:
        if pcallOK then
            if newEventsAddChannel and mode and curve then reaper.SetExtState("js_Insert ramps", "Last state", tostring(newEventsAddChannel)..","..mode..","..curve, true) end

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
            undoString = "Connect nodes in CC lane ".. tostring(mouseOrigCCLane)
        elseif laneIsCHANPRESS then
            undoString = "Connect nodes in channel pressure lane"
        elseif laneIsCC14BIT then
            undoString = "Connect nodes in 14 bit-CC lane ".. 
                                      tostring(mouseOrigCCLane-256) .. "/" .. tostring(mouseOrigCCLane-224)
        elseif laneIsPITCH then
            undoString = "Connect nodes in pitch lane"
        elseif laneIsPROGRAM then
            undoString = "Connect nodes in program select lane"
        else
            undoString = "Connect nodes"
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
    if editor and reaper.MIDIEditor_GetMode(editor) ~= -1 then
        curForegroundWindow = reaper.JS_Window_GetForeground()
        if not (curForegroundWindow and reaper.JS_Window_GetTitle(curForegroundWindow) == reaper.JS_Localize("ReaScript task control", "common")) then
            reaper.JS_Window_SetForeground(editor)
            reaper.JS_Window_SetFocus(editor)
    end end   
    
end -- function AtExit   


--##########################################################################################
--------------------------------------------------------------------------------------------
function DeleteExistingCCsInRange()
    -- This function updates remainMIDIstring to delete all CCs within range of selected CCs
    local tRemainingEvents = {}
    
    -- In order to delete existing CCs in range, must get min and max PPQs for each channel
    local temp = {}
    local tChannelMinMaxPPQs = {} 
    for chan = 0, 15 do
        temp[chan] = {min = math.huge, max = -math.huge}
        tChannelMinMaxPPQs[chan] = {}
    end
    for i = 1, #tPPQs do
        if tPPQs[i] < temp[tChannels[i]].min then temp[tChannels[i]].min = tPPQs[i] end
        if tPPQs[i] > temp[tChannels[i]].max then temp[tChannels[i]].max = tPPQs[i] end
    end
    for chan = 0, 15 do
        tChannelMinMaxPPQs[(chan+newEventsAddChannel)%16].min = math.min(temp[(chan+newEventsAddChannel)%16].min, temp[chan].min)
        tChannelMinMaxPPQs[(chan+newEventsAddChannel)%16].max = math.max(temp[(chan+newEventsAddChannel)%16].max, temp[chan].max)
    end
     
    -- Parse MIDIstring, removing CCs within range, handling each chaannel
    
    local t = 0 -- index in table
    local stringPos, prevPos, unchangedPos = 1, 1, 1 -- Position in MIDIstring while parsing
    local runningPPQPos = 0 -- PPQ position of event parsed
    local MIDIlen = MIDIString:len()
    local offset, flags, msg, mustDelete
    
    while stringPos < MIDIlen do 
        prevPos = stringPos
        mustDelete = false
        offset, flags, msg, stringPos = s_unpack("i4Bs4", MIDIString, stringPos)
        runningPPQPos = runningPPQPos + offset
        if msg:len() > 1 then
            local channel = (msg:byte(1)&0x0F)
            if runningPPQPos >= tChannelMinMaxPPQs[channel].min and runningPPQPos <= tChannelMinMaxPPQs[channel].max then
                if laneIsCC7BIT       then if msg:byte(1)>>4 == 11 and msg:byte(2) == mouseOrigCCLane then mustDelete = true end
                elseif laneIsPITCH    then if msg:byte(1)>>4 == 14 then mustDelete = true end
                elseif laneIsCC14BIT  then if msg:byte(1)>>4 == 11 and (msg:byte(2) == mouseOrigCCLane-224 or msg:byte(2) == mouseOrigCCLane-256) then mustDelete = true end
                --elseif laneIsNOTES    then if msg:byte(1)>>4 == 8 or msg:byte(1)>>4 == 9 then mustDelete = true end
                elseif laneIsPROGRAM  then if msg:byte(1)>>4 == 12 then mustDelete = true end
                elseif laneIsCHANPRESS  then if msg:byte(1)>>4 == 13 then mustDelete = true end
                end
            end
        end   
        if mustDelete then
            t = t + 1
            tRemainingEvents[t] = MIDIString:sub(unchangedPos, prevPos-1)
            t = t + 1
            tRemainingEvents[t] = s_pack("i4Bs4", offset, 0, "")
            unchangedPos = stringPos
        end
    end
        
    tRemainingEvents[t+1] = MIDIString:sub(unchangedPos)
    lastPPQPos = lastPPQPos or 0
    reaper.MIDI_SetAllEvts(activeTake, table.concat(tEditedMIDI) .. string.pack("i4Bs4", -lastPPQPos, 0, "") .. table.concat(tRemainingEvents))
end


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

    laneType = tonumber(tME_Lanes[laneID] and tME_Lanes[laneID].Type)
    if laneType then
        if SetupIndividualLane[laneType] then
            ME_TargetTopPixel = tME_Lanes[laneID].ME_TopPixel
            ME_TargetBottomPixel = tME_Lanes[laneID].ME_BottomPixel
            return true, laneType
       --[[ else
            return false, nil
        end
    else
        laneIsALL = true
        return true, nil]]
        end
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
        ME_midiviewWidth  = ME_midiviewRightPixel - ME_midiviewLeftPixel + 1
        ME_midiviewHeight = ME_midiviewBottomPixel - ME_midiviewTopPixel + 1
        
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
    
    -- REAPER v5.30 introduced new API functions for fast, mass edits of MIDI:
    --    MIDI_GetAllEvts and MIDI_SetAllEvts.
    -- These functions are fast, but require complicated parsing of the MIDI string.
    -- The following ts with temporarily store data while parsing:
    local tCCMSB = {} -- While waiting for matching LSB of 14-bit CC
    local tCCLSB = {} -- While waiting for matching MSB of 14-bit CC
    for chan = 0, 15 do   -- Each channel will be handled separately
        tCCMSB[chan] = {} 
        tCCLSB[chan] = {}
    end
                   
    local runningPPQPos = 0 -- The MIDI string only provides the relative offsets of each event, sp the actual PPQ positions must be calculated by iterating through all events and adding their offsets
            
    local stringPos = 1 -- Keep record of position within MIDIstring. unchangedPos is position from which unchanged events van be copied in bulk.
    local c = 0 -- index in table / number if selected CCs
    
    getAllEvtsOK, MIDIString = reaper.MIDI_GetAllEvts(activeTake, "")
        if not getAllEvtsOK then reaper.MB("MIDI_GetAllEvts could not load the raw MIDI data.", "ERROR", 0) return false end
    MIDIlen = #MIDIString
    
    ----------------------------------------------------------------
    -- Iterate through MIDIstring, until the upper limit is reached.
    while stringPos < MIDIlen do
       
        local offset, flags, msg
        
        offset, flags, msg, stringPos = s_unpack("i4Bs4", MIDIString, stringPos)
        runningPPQPos = runningPPQPos + offset                 

        -- Only analyze *selected* events - as well as notation text events (which are always unselected)
        if flags&1 == 1 and msg:len() ~= 0 then -- bit 1: selected
                          
            local channel = msg:byte(1)&0x0F
            if editAllChannels or channel == activeChannel then
            
                if laneIsCC7BIT then if msg:byte(2) == mouseOrigCCLane and (msg:byte(1))>>4 == 11
                then
                    c = c + 1 
                    tValues[c] = msg:byte(3)
                    tPPQs[c] = runningPPQPos
                    tChannels[c] = channel
                    tFlags[c] = flags
                    end 
                                    
                elseif laneIsPITCH then if (msg:byte(1))>>4 == 14
                then
                    c = c + 1
                    tValues[c] = (msg:byte(3)<<7) + msg:byte(2)
                    tPPQs[c] = runningPPQPos
                    tChannels[c] = channel
                    tFlags[c] = flags 
                    end                           
                                        
                elseif laneIsCC14BIT then 
                    if msg:byte(2) == mouseOrigCCLane-224 and (msg:byte(1))>>4 == 11 -- 14bit CC, only the LSB lane
                    then
                        -- Has a corresponding MSB value already been saved?  If so, combine and save in tValues.
                        if tCCMSB[channel][runningPPQPos] then
                            c = c + 1
                            tValues[c] = (((tCCMSB[channel][runningPPQPos].message):byte(3))<<7) + msg:byte(3)
                            tPPQs[c] = runningPPQPos
                            tFlags[c] = tCCMSB[channel][runningPPQPos].flags -- The MSB determines muting
                            tFlagsLSB[c] = flags
                            tChannels[c] = channel
                            tCCMSB[channel][runningPPQPos] = nil -- delete record
                        else
                            tCCLSB[channel][runningPPQPos] = {message = msg, flags = flags}
                        end
                            
                    elseif msg:byte(2) == mouseOrigCCLane-256 and (msg:byte(1))>>4 == 11 -- 14bit CC, only the MSB lane
                    then
                        -- Has a corresponding LSB value already been saved?  If so, combine and save in tValues.
                        if tCCLSB[channel][runningPPQPos] then
                            c = c + 1
                            tValues[c] = (msg:byte(3)<<7) + (tCCLSB[channel][runningPPQPos].message):byte(3)
                            tPPQs[c] = runningPPQPos
                            tFlags[c] = flags
                            tChannels[c] = channel
                            tFlagsLSB[c] = tCCLSB[channel][runningPPQPos].flags
                            tCCLSB[channel][runningPPQPos] = nil -- delete record
                        else
                            tCCMSB[channel][runningPPQPos] = {message = msg, flags = flags}
                        end
                    end
                    
                elseif laneIsPROGRAM then if (msg:byte(1))>>4 == 12
                then
                    c = c + 1
                    tValues[c] = msg:byte(2)
                    tPPQs[c] = runningPPQPos
                    tChannels[c] = channel
                    tFlags[c] = flags
                    end
                    
                elseif laneIsCHANPRESS then if (msg:byte(1))>>4 == 13
                then
                    c = c + 1
                    tValues[c] = msg:byte(2)
                    tPPQs[c] = runningPPQPos
                    tChannels[c] = channel
                    tFlags[c] = flags
                    end
                end 
            end
        end 
                            
    end -- while              
    
    -- Instead of calling the slow MIDI_Sort, the script will simply find the correct order of selected events itself
    -- The entries in this table will be the sorted indices in tPPQs.
    for i = 1, #tPPQs do
        tSortedIndices[i] = i
    end
    local function sortPPQs(a, b)
        if tPPQs[a] < tPPQs[b] then return true end
    end
    table.sort(tSortedIndices, sortPPQs)
    
    -- Calculate tNextInChannel and tPrevInChannel
    for s, i in ipairs(tSortedIndices) do 
        -- Find next event in same channel
        for a = s+1, #tSortedIndices do 
            if tChannels[tSortedIndices[a]] == tChannels[i] then
                if tPPQs[tSortedIndices[a]] > tPPQs[i] then
                    tNextInChannel[i] = tSortedIndices[a]
                    tPrevInChannel[tSortedIndices[a]] = i
                end
                break
            end
        end
    end            
    
    return true
end


--#############################
-------------------------------
function CalculateBezierCurve()
    -- Calculate tSlopes for SMOOTH mode
    -- A commonly used slope is the Catmull-Ron one, which is equal to the slope between the previous and next nodes.
    -- This script will make three adjustments to make a better-looking slope (IMO):
    --  1) CC curves should preferably not cross the min and max values, so slopes will be limited to fit within the lane's value range.
    --  2) More weight to whichever of the prev and next nodes is nearer. 
    --  3) To ensure that LFO apex and nadir nodes don't shift, apex or nadir nodes will be given slopes of 0, which (usually) prevents the curve from going past the node.
    for i = 1, #tPPQs do
        local curVal = tValues[i]
        local curPPQ = tPPQs[i]
        local n = tNextInChannel[i]
        local p = tPrevInChannel[i]
        local nextVal = tValues[n]
        local nextPPQ = tPPQs[n]  
        local prevVal = tValues[p]
        local prevPPQ = tPPQs[p] 
        if n and not p then
            prevVal = curVal + (curVal-nextVal)
            prevPPQ = curPPQ + (curPPQ-nextPPQ)
        elseif p and not n then
            nextVal = curVal + (curVal-prevVal)
            nextPPQ = curPPQ + (curPPQ-prevPPQ)
        end
        -- If not n and not p, then the node stands alone and will not be ramped to another node.
        if prevVal and nextVal then
            -- Apex or nadir node?
            if (prevVal < curVal and nextVal < curVal) or (prevVal > curVal and nextVal > curVal) then
                tSlopes[i] = 0
            else
                local minSlope = math.max(3*(laneMinValue-curVal)/(nextPPQ-curPPQ), 3*(curVal-laneMaxValue)/(curPPQ-prevPPQ))
                local maxSlope = math.min(3*(laneMaxValue-curVal)/(nextPPQ-curPPQ), 3*(curVal-laneMinValue)/(curPPQ-prevPPQ))
                local weightedAvgSlope = (0.75 - 0.5*(curPPQ-prevPPQ)/(nextPPQ-prevPPQ)) * (curVal-prevVal)/(curPPQ-prevPPQ) 
                               + (0.25 + 0.5*(curPPQ-prevPPQ)/(nextPPQ-prevPPQ)) * (nextVal-curVal)/(nextPPQ-curPPQ)
                --C_RSlope = (nextVal-prevVal)/(nextPPQ-prevPPQ) -- Catmull-Rom spline
                tSlopes[i] = math.min(maxSlope, math.max(minSlope, weightedAvgSlope)) 
            end
        end
    end
    
    tBezier = {}
    for s, i in ipairs(tSortedIndices) do 
        
        -- Only need to draw if there is a next node in same channel
        -- Also, if warping left/right is extreme (powerLeftRight is #IND), don't need to insert anything between nodes
        if tNextInChannel[i] then
            tBezier[i] = {}
            local curVal  = tValues[i]
            local curPPQ  = tPPQs[i] 
            local nextVal = tValues[tNextInChannel[i]]
            local nextPPQ = tPPQs[tNextInChannel[i]]
               
            local curSlope  = tSlopes[i]
            local nextSlope = tSlopes[tNextInChannel[i]]
            -- Cubic spline formulas use slopes, but Bézier curve formulas use two control points: 
            local PPQ1 = (curSlope == 0) and (curPPQ + (nextPPQ-curPPQ)*0.45) or (curPPQ + (nextPPQ-curPPQ)*0.3)
            local PPQ2 = (nextSlope == 0) and (curPPQ + (nextPPQ-curPPQ)*0.55) or (curPPQ + (nextPPQ-curPPQ)*0.7)
            local Val1 = curVal + curSlope*(PPQ1-curPPQ)
            local Val2 = nextVal + nextSlope*(PPQ2-nextPPQ)
            --[[ Do some linear algebra to fit cubic curve
            local m = { {ppPPQ^3,   ppPPQ^2,   ppPPQ,   1, ppValue},
                        {curPPQ^3, curPPQ^2, curPPQ, 1, curVal},
                        {nextPPQ^3, nextPPQ^2, nextPPQ, 1, nextVal},
                        {nnPPQ^3,   nnPPQ^2,   nnPPQ,   1, nnValue} }       
            for h = 1, 4 do
                for r = h, 4 do
                    if m[r][h] ~= 0 then m[h], m[r] = m[r], m[h] break end
                end
                if m[h][h] == 0 then mode = "WARP"; curve = "SINE" break end
              
                d = m[h][h]
                m[h][h] = 1
                for c = h+1, 5 do
                    m[h][c] = m[h][c]/d
                end
               
                for r = 1, 4 do
                    if r ~= h then
                        f = m[r][h]
                        for c = 1, 5 do
                            m[r][c] = m[r][c] - f*m[h][c]
                        end
                    end
                end
            end
            cubicA, cubicB, cubicC, cubicD = m[1][5], m[2][5], m[3][5], m[4][5]
            ]]
            local t = 0
            for PPQPos = curPPQ, nextPPQ-1, PPerCC do --nextCCdensityPPQPos, nextPPQ-1, PPerCC do
                local PPQRound = m_floor(PPQPos + 0.5)
                
                -- This binary search assumes that curve is function (i.e. every PPQ maps onto only one CC value)
                local high, low = 1, t
                for c = 1, 100 do -- In case something goes wrong, prevent endless loop
                    t = (high+low)/2
                    -- Bézier:
                    x = ((1-t)^3)*curPPQ + 3*((1-t)^2)*t*PPQ1 + 3*(1-t)*(t^2)*PPQ2 + (t^3)*nextPPQ
                    -- Cubic Hermite:
                    --x = (2*t^3 - 3*t^2 + 1)*curPPQ + (t^3 - 2*t^2 + t)*(nextPPQ-curPPQ) + (-2*t^3 + 3*t^2)*nextPPQ + (t^3 - t^2)*(nextPPQ-curPPQ)
                    if x > PPQRound+0.5 then
                        high = t
                    elseif x < PPQRound-0.5 then
                        low = t
                    else
                        break
                    end
                end
                -- Bézier:
                tBezier[i][PPQRound] = ((1-t)^3)*curVal + 3*((1-t)^2)*t*Val1 + 3*(1-t)*(t^2)*Val2 + (t^3)*nextVal
                -- Cubic Hermite:
                --insertValue = (2*t^3 - 3*t^2 + 1)*curVal + (t^3 - 2*t^2 + t)*curSlope*(nextPPQ-curPPQ) + (-2*t^3 + 3*t^2)*nextVal + (t^3 - t^2)*nextSlope*(nextPPQ-curPPQ)
                
                --[[ Make sure thdat CC falls within CC range
                if insertValue ~= insertValue then insertValue = curVal
                elseif insertValue > laneMaxValue then insertValue = laneMaxValue
                elseif insertValue < laneMinValue then insertValue = laneMinValue
                else insertValue = m_floor(insertValue + 0.5)
                end]]
                
                
            end -- for PPQPos = curPPQ, nextPPQ-1, PPerCC
            
        end -- if tNextInChannel[i]
    end -- for s, i in ipairs(tSortedIndices)
end -- function CalculateBezierCurve


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
    
    Tooltip("Armed: Connect nodes")

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
        reaper.TrackCtl_SetToolTip(tooltipText, mouseX+10, mouseY+10, false)
        reaper.defer(Tooltip)
    elseif reaper.time_precise() < tooltipTime+0.5 then
        if not (mouseX and mouseY) then mouseX, mouseY = reaper.GetMousePosition() end
        reaper.TrackCtl_SetToolTip(tooltipText, mouseX+10, mouseY+10, false)
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
    prevMouseTime = startTime + 0.2 -- In case mousewheel sends multiple messages, don't react to messages sent too closely spaced, so wait till little beyond startTime.
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
    filename = filename .. "js_Mouse editing - Connect nodes.cur"
    cursor = reaper.JS_Mouse_LoadCursorFromFile(filename) -- The first time that the cursor is loaded in the session will be slow, but afterwards the extension will re-use previously loaded cursor
    if not cursor then cursor = reaper.JS_Mouse_LoadCursor(433) end -- If .cur file unavailable, load one of REAPER's own cursors]]
    cursor = reaper.JS_Mouse_LoadCursor(528)
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
            
                -- Get MIDI editor and CC lane.  This script works in a single lane, so if on divider, must wait until mouse enters a CC lane
                --::loopUntilMouseEntersCCLane::
                window, segment, details = reaper.BR_GetMouseCursorContext()    
                editor, isInline, mouseOrigPitch, mouseOrigCCLane, mouseOrigCCValue, mouseOrigCCLaneID = reaper.BR_GetMouseCursorContext_MIDI() 
                --if details == "cc_lane" and mouseOrigCCValue == -1 then mouseStartedOnLaneDivider = true; goto loopUntilMouseEntersCCLane end
                
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
            reaper.MB("To indicate which CC lane should be edited, the initial position of the mouse should be within that lane.", "ERROR", 0)
        end
        return false
    end   
    if not (laneIsCC7BIT or laneIsCC14BIT or laneIsPITCH or laneIsCHANPRESS or laneIsPROGRAM) then
        reaper.MB("This script will only work in the following MIDI lanes: \n* 7-bit CC, \n* 14-bit CC, \n* Pitch, \n* Channel Pressure, or\n* Program select.", "ERROR", 0)
        return false
    end
    
    
    -- MOUSE STARTING PPQ VALUES
    -- Get mouse starting PPQ position -- AND ADJUST FOR LOOPING AND SNAPPING
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
    
    minimumTick = math.max(0, itemFirstVisibleTick)
    maximumTick = math.min(itemLastVisibleTick, sourceLengthTicks-1) -- I prefer not to draw any event on the same PPQ position as the All-Notes-Off
    mouseOrigPPQPos = math.max(minimumTick, math.min(maximumTick, mouseOrigPPQPos))

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
    

    -- CC INSERT DENSITY:
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
    if not GetAndParseMIDIString() then return false end
    -- !!!!!!!!!! Uniue to this script:
    if #tPPQs < 2 then -- Two notes can be warped, but not two CCs
        reaper.ShowMessageBox("Could not find a sufficient number of selected events in the target lane(s).", "ERROR", 0)
        return(false)
    end
    
    
    -- UNIQUE TO THIS SCRIPT:
    CalculateBezierCurve()
    laneHeight = (laneMaxValue - laneMinValue)
    laneAvg    = (laneMinValue + laneMaxValue)/2
    
    
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
    
end -- function Main()


--################################################
--------------------------------------------------
MAIN()

