--[[
ReaScript name: js_Mouse editing - Stretch and Compress.lua
Version: 4.21
Author: juliansader
Website: http://forum.cockos.com/showthread.php?t=176878
Donation: https://www.paypal.me/juliansader
Provides: 
  [main=midi_editor,midi_inlineeditor] .
  js_Mouse editing - Stretch bottom.cur
  js_Mouse editing - Stretch top.cur
About:
  # DESCRIPTION
  
  A multifunctional script for stretching and compressing MIDI events.
  
  Depending on mouse position when the script starts, the script can:
      * stretch event positions (horizontally) to the mouse position, or
      * stretch event values (vertically) to the mouse position, or
      * compress/expand the lane boundaries with various types of curves.
  
  
  STRETCH EVENTS: 
  
  If the mouse is positioned *inside* a CC lane or the notes area when the script starts, it will only affect events in that individual lane.
      (After the script starts, the mouse may move out of the lane.)
  
  If the mouse is positioned *outside* a CC lane when the script starts, i.e. over a lane divider or over the ruler area, 
      and the mouse is moved left or right, the script will stretch selected events on *all* lanes together.
        
  If the mouse is positioned to the *right* of the selected events, it will stretch the right edge of event positions to the mouse position.
      
  Similarly, if the mouse is positioned to the *left* of the selected events, it will stretch the left edge of event positions to the mouse position.
      
  If the mouse is positioned closer to the middle of the time range, and to the top [or bottom] of the CC's value range, 
      it will stretch the top [or bottom] values up or down to the mouse position.  
      (MIDI notes, as well as events that do not have CC values, such as Text or Sysex, can only be stretched left/right, not up/down.)

      
  COMPRESS LANE:
  
  If the mouse is positioned over a lane divider when the script starts, and then moved up or down into the CC lane,
      the script will compress or expand the lane range.  (Think of the movement as "dragging" the lane boudary up or down.)
      
  The script will draw the compression curve on the screen.
  
  Compress mode is not yet available for the inline MIDI editor.
      
      
  MOUSE CONTROL:
  
  Left-clicking terminates the script. 
  
  While stretching, 
      * flipping the mouse wheel will flip the selected CCs around. (If stretching horizontally, flips event positions; if vertically, flips values.)
  
  While compressing, 
      * the middle button toggles between a linear/power curve and a sine curve,
      * mouse wheel further tweaks the curve, and
      * the right button toggles the mode between 1-sided compression (from either the top or bottom) or symmetrical compression.
      
      
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
      the visible and editable takes.  If the MIDI editor is slow, try reducing the number of editable and visible tracks.
      
  PERFORMANCE TIP 2: If the MIDI editor gets slow and jerky when a certain VST plugin is loaded, 
      check for graphics driver incompatibility by disabling graphics acceleration in the plugin.
]] 

--[[
  Changelog:
  * v4.00 (2019-01-19)
    + Updated for js_ReaScriptAPI extension.
    + Combines previous Stretch and Compress scripts.
    + Compression curve can be controlled by mousewheel.
  * v4.01 (2019-02-11)
    + Restore focus to original window, if script opened notification window.
  * v4.02 (2019-02-16)
    + Fixed: On Linux, crashing if editor closed while script is running.
  * v4.03 (2019-03-02)
    + Fixed: If editor is docked, properly restore focus.
  * v4.11 (2019-03-05)
    + Compatible with macOS.
  * v4.20 (2019-04-25)
    + macOS and Linux: In Compress mode, draw guidelines on screen (as on WindowsOS)
    + Clicking armed toolbar button disarms script.
    + Improved starting/stopping: 1) Any keystroke terminates script; 2) Alternatively, hold shortcut for second and release to terminate.
  * v4.21 (2019-05-11)
    + Fix spike in bottom guideline.
]]

-- USER AREA 
-- Settings that the user can customize
    
    -- If the starting position of the mouse is within this distance (as a fraction of total time range of selected events) 
    --    of the right or left edge of the time range, the script will will stretch left/right, otherwise top/bottom
    -- Useful values are between 0 and 0.5.
    edgeSize = 0.05
    
    -- If CC events are stretched left or right until they overlap other CCs in the same lane (and same channel), 
    --    should the pre-existing CCs be deleted?
    mustDeleteOverlappingCCs = true
    
    Guideline_Color_Top    = 0xFF00FF00 -- Format AARRGGBB
    Guideline_Color_Bottom = 0xFF0000FF
    
-- End of USER AREA   


-- ################################################################################################
---------------------------------------------------------------------------------------------------
-- CONSTANTS AND VARIABLES (that modders may find useful)

--[[ General notes:

Speed:
REAPER's MIDI API functions such as InsertCC and SetCC are very slow if the active take contains 
    hundreds of thousands of MIDI events.  
Therefore, this script will not use these functions, and will instead directly access the item's 
    raw MIDI stream via new functions that were introduced in v5.30: GetAllEvts and SetAllEvts.
Parsing of the MIDI stream can be relatively straightforward, but to improve speed even
    further, this script will use several 'tricks', which will unfortunately also make the 
    parsing function quite complicated.

Sorting:
Prior to v5.32, sorting of MIDI events, either by MIDI_Sort or by other functions such as MIDI_SetNote
    (with sort=true) was endlessly buggy (http://forum.cockos.com/showthread.php?t=184459
    is one of many threads).  In particular, it often mutated overlapping notes or unsorted notes into
    infinitely extende notes.
Finally, in v5.32, these bugs were (seemingly) all fixed.  This new version of the script will therefore
    use the MIDI_Sort function (instead of calling a MIDI editor action via OnCommand to induce sorting).

However, sorting is still relatively slow, so since MIDI will under normal circumstances already be 
    sorted when the script is run (the MIDI editor automatically sorts the data whenever any small edit
    is made), MIDI_Sort will not automatically be called when the script starts.  Instead, offsets will 
    be checked during parsing, and if any negative offsets are detected, MIDI_Sort will be called.
    It is actually faster to check for unsorted data during parsing.
]]

-- The raw MIDI data string will be divided into substrings in tMIDI, which can be concatenated into a new edited MIDI string.
local MIDIString -- The original raw MIDI data returned by GetAllEvts
-- For STRETCH:
-- Target events will be eremoved from MIDIString, which will be re-concatenated into remainMIDIString.
-- When the info of the targeted events is extracted, the info will be stored in several tables.
-- The order of events in the tables will reflect the order of events in the original MIDI, except note-offs, 
--    which will be replaced by note lengths, and notation text events, which will also be stored in a separate table
--    at the same indices as the corresponding notes.
local remainMIDIString -- The MIDI that remained after extracting selected events in the target lane
local editedMIDIString -- The events that were extracted from MIDIString and then edited
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

-- For COMPRESS:
-- The raw MIDI data string will be divided into substrings in tMIDI, which can be concatenated into a new edited MIDI string.
--    In order to easily edit selected target events' values (tick positions will not be altered by this script), 
--    each target event's value bytes will be a separate table entry.
-- tTargets will store the indices in tMIDI of these target entries, their original values, and their tick positions.
local tMIDI = {} -- tMIDI[#tMIDI+1] = MIDIString:sub(prevPos, pos-2);  tMIDI[#tMIDI+1] = msg:sub(-1)
local tTargets = {} -- tTargets[i] = {index = #tMIDI, val = msg:byte(3), ticks = ticks}
  
-- The original value and PPQ ranges of selected events in the target lane will be summarized in:
local origValueMin, origValueMax, origValueRange, origValueLeftmost, origValueRightmost = nil, nil, nil, nil, nil
local origPPQleftmost, origPPQrightmost, origPPQRange = nil, nil, nil
local includeNoteOffsInPPQRange = true
--local includeNoteOffsInPPQRange = false -- ***** Should origPPQRange and origPPQrightmost take note-offs into account? Set this flag to true for scripts that stretch or warp note lengths. *****
 
-- Starting values and position of mouse 
-- Not all of these lanes will be used by all scripts.
-- mouseOrigCCLane: (CC0-127 = 7-bit CC, 0x100|(0-31) = 14-bit CC, 0x200 = velocity, 0x201 = pitch, 
--    0x202=program, 0x203=channel pressure, 0x204=bank/program select, 
--    0x205=text, 0x206=sysex, 0x207=off velocity)
local mouseOrigX, mouseOrigY = nil, nil
local laneMinValue, laneMaxValue = nil, nil -- The minimum and maximum values in the target lane
local mouseOrigCCLane, mouseOrigCCValue, mouseOrigPPQPos, mouseOrigPitch, mouseOrigCCLaneID = nil, nil, nil, nil, nil
local snappedOrigPPQPos = nil -- If snap-to-grid is enabled, these will give the closest grid PPQ to the left. (Swing is not implemented.)

-- This script can work in inline MIDI editors as well as the main MIDI editors
-- The two types of editors require some different code, though.  
-- In particular, if in an inline editor, functions from the SWS extension will be used to track mouse position.
-- In the main editor, WIN32/SWELL functions from the js_ReaScriptAPI extension will be used.
local isInline, editor = nil, nil

-- Tracking the new value and position of the mouse while the script is running
local mouseNewCCLane, mouseNewCCValue, mouseNewPPQPos, mouseNewPitch, mouseNewCCLaneID = nil, nil, nil, nil, nil
local prevMouseX, prevMouseY, mouseX, mouseY
local snappedNewPPQPos 

-- The script can be controlled by mousewheel, mouse buttons an mouse modifiers.  These are tracked by the following variables.
local mouseState
local mousewheel = 1 -- Track mousewheel movement.  ***** This default value may change, depending on the script and formulae used. *****
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
local lastPPQPos -- to calculate offset to next CC
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
local t_insert = table.insert -- myTable[i] = X is actually much faster than t_insert(myTable, X)
local m_floor  = math.floor
local m_cos = math.cos
local m_min = math.min
local m_max = math.max 
local m_pi  = math.pi

-- User preferences that can be customized via toggle scripts
local mouseMovementResolution = 4

-- Window messages that will be intercepted while the script is running
local tWM_Messages = {WM_LBUTTONDOWN = false, WM_LBUTTONDBLCLK = false, WM_LBUTTONUP = false,
                      WM_MBUTTONDOWN = false, WM_MBUTTONDBLCLK = false, WM_MBUTTONUP = false,
                      WM_RBUTTONDOWN = false, WM_RBUTTONDBLCLK = false, WM_RBUTTONUP = false,
                      WM_NCMOUSEMOVE   = false, -- This intercept allows the mouse to go into the bottom scroll area (i.e. outside midiview's client area) without REAPER noticing it and changing the mouse cursor.
                      WM_MOUSEWHEEL  = false, WM_MOUSEHWHEEL   = false,
                      WM_SETCURSOR   = false}                 
  
-- Unique to STRETCH script:
local flipped = false

-- Unique to COMPRESS script:
local leftPPQrange, rightPPQrange
local baseShape = "sine"
local compressSYMMETRIC, compressBOTTOM, compressTOP = true
local Guides_LeftPixel, Guides_RightPixel, Guides_XStr, Guides_YStr_Top, Guides_YStr_Bottom = nil, nil, nil, nil, nil, nil, nil, nil
local tGuides_Ticks, tGuides_X = {}, {} -- Guide lines will be drawn between nodes spaced every 10 pixels. What are the tick positions of these pixels?
local Guides_COLOR_TOP    = tonumber(Guideline_Color_Top) or 0xFF00FF00 -- Format AARRGGBB
local Guides_COLOR_BOTTOM = tonumber(Guideline_Color_Bottom) or 0xFF0000FF
local macOS = reaper.GetOS():match("OSX") -- On macOS, mouse events use opposite sign


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
function DEFERLOOP_TrackMouseAndUpdateMIDI_STRETCH()
    
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
    dragTimeStarted = dragTimeStarted or (thisCycleTime > startTime + dragTime)  -- No need to call time_precise if dragTimeStarted already true    
    
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
    
    -- MOUSE MODIFIERS / LEFT CLICK / LEFT DRAG: (If the left mouse button or any modifier key is pressed, after first releasing them, quit.)
    -- This can detect left clicks even if the mouse is outside the MIDI editor
    local prevMouseState = mouseState or 0xFF
    mouseState = reaper.JS_Mouse_GetState(0xFF)
    if (mouseState&61) > (prevMouseState&61) -- 61 = 0b00111101 = Ctrl | Shift | Alt | Win | Left button
    or (dragTimeStarted and (mouseState&1) < (prevMouseState&1)) then
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
    
    -- MOUSEWHEEL
    local peekOK, pass, time, keys, delta = reaper.JS_WindowMessage_Peek(windowUnderMouse, "WM_MOUSEWHEEL")
    if not (peekOK and time > prevMouseTime) then 
        peekOK, pass, time, keys, delta = reaper.JS_WindowMessage_Peek(windowUnderMouse, "WM_MOUSEHWHEEL")
    end 
    if peekOK and time > prevMouseTime + 0.4 then 
        --if keys&12 ~= 0 then return false end
        flipped = not flipped
        prevMouseTime = time
        mustCalculate = true
    end
    
    --[[ LEFT CLICK: (If the left mouse button or any modifier key is pressed, after first releasing them, quit.)
    peekOK, pass, time = reaper.JS_WindowMessage_Peek(windowUnderMouse, "WM_LBUTTONDOWN")
    if peekOK and time > startTime then 
        return false 
    end]]
    
    -- TAKE STILL VALID?
    if not reaper.ValidatePtr2(0, activeTake, "MediaItem_Take*") then return false end
 
        
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
        
        if stretchTOP or stretchBOTTOM then
        
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
                    mouseNewCCValue = -1
                elseif mouseOrigCCValue and mouseOrigCCValue ~= -1 then      
                    mouseNewPitch = -1                               
                    mouseNewCCValue = laneMinValue + (laneMaxValue-laneMinValue) * (mouseY - tME_Lanes[mouseOrigCCLaneID].ME_BottomPixel) / (tME_Lanes[mouseOrigCCLaneID].ME_TopPixel - tME_Lanes[mouseOrigCCLaneID].ME_BottomPixel)
                end
            end
            -- In some scripts, the mouse CC value may go beyond lane limits
            if mouseNewCCValue      > laneMaxValue  then mouseNewCCValue = laneMaxValue
            elseif mouseNewCCValue  < laneMinValue  then mouseNewCCValue = laneMinValue
            else mouseNewCCValue = math.floor(mouseNewCCValue+0.5)
            end
            
        else -- stretchLEFT or stretchRIGHT
        
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
            snappedNewPPQPos = math.max(minimumTick, math.min(maximumTick, snappedNewPPQPos))
        end
                
        ---------------------------------------------------------------
        -- Calculate the new raw MIDI data, and write the tableEditedMIDI!
        ---------------------------------------------------------------- THIS IS THE PART THAT CAN EASILY BE MODDED !! ------------------------
        tableEditedMIDI = {} -- Clean previous tableEditedMIDI 
        local c = 0 -- Count index inside tableEditedMIDI - strangely, this is faster than using table.insert or even #tableEditedMIDI+1
        
        lastPPQPos = 0 -- Don't make local, since AtExit and DeleteExistinCCs must also reference lastPPQPos
            
        if stretchRIGHT then
            
            local stretchFactor = (snappedNewPPQPos-origPPQleftmost)/origPPQRange
                            
            -- Safer to keep offsets positive, so check whether events are being reversed
            -- In addtion, avoid drawing multiple events on the same PPQ position
            local startIndex, endIndex, step, newPPQPos, newNoteOffPPQPos, newNoteLength
        
            if (stretchFactor >= 0 and not flipped) or (stretchFactor < 0 and flipped) then startIndex, endIndex, step = 1, #tTicks, 1 -- Step forward
            else startIndex, endIndex, step = #tTicks, 1, -1 -- Step backward (forward in PPQ)
            end
                
            for i = startIndex, endIndex, step do
            
                local flippedPPQPos = flipped and (origPPQleftmost + origPPQrightmost - tTicks[i]) or tTicks[i]
                newPPQPos = m_floor(origPPQleftmost + stretchFactor*(flippedPPQPos - origPPQleftmost) + 0.5)                    
                offset = newPPQPos - lastPPQPos                   
                lastPPQPos = newPPQPos 
                
                -- Remember that notes and 14bit CCs contain more than one event per tTicks entry
                
                if tNoteLengths[i] then -- note event
                
                    local flippedNoteOffPPQPos = flipped and (origPPQleftmost + origPPQrightmost - (tTicks[i]+tNoteLengths[i])) 
                                                         or (tTicks[i]+tNoteLengths[i])
                    newNoteOffPPQPos = m_floor(origPPQleftmost + stretchFactor*(flippedNoteOffPPQPos - origPPQleftmost) + 0.5)
                    -- If reversing notes, make sure that note-on is positioned before note-off
                    if newNoteOffPPQPos < newPPQPos then 
                        newPPQPos, newNoteOffPPQPos = newNoteOffPPQPos, newPPQPos
                        newNoteLength = newNoteOffPPQPos - newPPQPos
                        offset = offset - newNoteLength -- (newNoteOffPPQPos - newPPQPos)
                    else
                        newNoteLength = newNoteOffPPQPos - newPPQPos
                        lastPPQPos = lastPPQPos + newNoteLength
                    end                
                    -- Insert note-on
                    c = c + 1 
                    tableEditedMIDI[c] = s_pack("i4Bs4", offset, tFlags[i], tMsg[i])    
                    -- Since REAPER v5.32, notation (if it exists) must always be inserted *after* its note
                    if tNotation[i] then
                        c = c + 1
                        tableEditedMIDI[c] = s_pack("i4Bs4", 0, tFlags[i]&0xFE, tNotation[i])
                    end  
                    -- Insert note-off
                    c = c + 1
                    tableEditedMIDI[c] = s_pack("i4Bs4", newNoteLength, tFlags[i], tMsgNoteOffs[i])
                                        
                else           
                    c = c + 1
                    tableEditedMIDI[c] = s_pack("i4Bs4", offset, tFlags[i], tMsg[i])
                    
                    if tMsgLSB[i] then -- Only if laneIs14BIT then tMsgLSB will contain entries 
                        c = c + 1
                        tableEditedMIDI[c] = s_pack("i4Bs4", 0, tFlagsLSB[i], tMsgLSB[i])
                    end
                end
            end  
                        
        elseif stretchLEFT then
        
            local stretchFactor = (origPPQrightmost - snappedNewPPQPos)/origPPQRange
                            
            -- Safer to keep offsets positive, so check whether events are being reversed
            -- In addtion, avoid drawing multiple events on the same PPQ position
            local startIndex, endIndex, step, newPPQPos, newNoteOffPPQPos, newNoteLength
            
            if (stretchFactor >= 0 and not flipped) or (stretchFactor < 0 and flipped) then startIndex, endIndex, step = 1, #tTicks, 1 
            else startIndex, endIndex, step = #tTicks, 1, -1
            end
                        
            for i = startIndex, endIndex, step do        
            
                local flippedPPQPos = flipped and (origPPQleftmost + origPPQrightmost - tTicks[i]) or tTicks[i]
                newPPQPos = m_floor(origPPQrightmost - stretchFactor*(origPPQrightmost - flippedPPQPos) + 0.5)
                offset = newPPQPos - lastPPQPos
                lastPPQPos = newPPQPos
                
                -- Remember that notes and 14bit CCs contain more than one event per tTicks entry
                
                if tNoteLengths[i] then -- note event
                
                    local flippedNoteOffPPQPos = flipped and (origPPQleftmost + origPPQrightmost - (tTicks[i]+tNoteLengths[i])) 
                                                         or (tTicks[i]+tNoteLengths[i])
                    newNoteOffPPQPos = m_floor(origPPQrightmost - stretchFactor*(origPPQrightmost - flippedNoteOffPPQPos) + 0.5)
                    -- If reversing notes, make sure that note-on is positioned before note-off
                    if newNoteOffPPQPos < newPPQPos then 
                        newPPQPos, newNoteOffPPQPos = newNoteOffPPQPos, newPPQPos
                        newNoteLength = newNoteOffPPQPos - newPPQPos
                        offset = offset - newNoteLength -- (newNoteOffPPQPos - newPPQPos)
                    else
                        newNoteLength = newNoteOffPPQPos - newPPQPos
                        lastPPQPos = lastPPQPos + newNoteLength
                    end
                    -- Insert note-on
                    c = c + 1 
                    tableEditedMIDI[c] = s_pack("i4Bs4", offset, tFlags[i], tMsg[i])    
                    -- Since REAPER v5.32, notation (if it exists) must always be inserted *after* its note
                    if tNotation[i] then
                        c = c + 1
                        tableEditedMIDI[c] = s_pack("i4Bs4", 0, tFlags[i]&0xFE, tNotation[i])
                    end     
                    -- Insert note-off
                    c = c + 1
                    tableEditedMIDI[c] = s_pack("i4Bs4", newNoteLength, tFlags[i], tMsgNoteOffs[i])
                    
                else
                    c = c + 1
                    tableEditedMIDI[c] = s_pack("i4Bs4", offset, tFlags[i], tMsg[i])
                    
                    if tMsgLSB[i] then -- Only if laneIs14BIT then tMsgLSB will contain entries 
                        c = c + 1
                        tableEditedMIDI[c] = s_pack("i4Bs4", 0, tFlagsLSB[i], tMsgLSB[i])
                    end
                end 
            end
        
        elseif stretchTOP then
        
            local stretchFactor = (mouseNewCCValue - origValueMin)/origValueRange
            local newValue
                
            for i = 1, #tTicks do
            
                local flippedValue = flipped and (origValueMin + origValueMax - tValues[i]) or tValues[i]
                newValue = m_floor(origValueMin + stretchFactor*(flippedValue - origValueMin) + 0.5)
                if newValue > laneMaxValue then newValue = laneMaxValue elseif newValue < laneMinValue then laneValue = laneMinValue end
                
                offset = tTicks[i] - lastPPQPos
                
                lastPPQPos = tTicks[i]
                
                if laneIsCC7BIT then
                    c = c + 1
                    tableEditedMIDI[c] = s_pack("i4BI4BBB", offset, tFlags[i], #tMsg[i], 0xB0 | tChannels[i], mouseOrigCCLane, newValue) .. tMsg[i]:sub(4,nil)
                elseif laneIsPITCH then
                    c = c + 1
                    tableEditedMIDI[c] = s_pack("i4BI4BBB", offset, tFlags[i], #tMsg[i], 0xE0 | tChannels[i], newValue&127, newValue>>7) .. tMsg[i]:sub(4,nil)
                elseif laneIsCHANPRESS then
                    c = c + 1
                    tableEditedMIDI[c] = s_pack("i4BI4BB",  offset, tFlags[i], #tMsg[i], 0xD0 | tChannels[i], newValue) .. tMsg[i]:sub(3,nil) -- NB Channel Pressure uses only 2 bytes!
                elseif laneIsCC14BIT then
                    c = c + 1
                    tableEditedMIDI[c] = s_pack("i4BI4BBB", offset, tFlags[i], #tMsg[i], 0xB0 | tChannels[i], mouseOrigCCLane-256, newValue>>7) .. tMsg[i]:sub(4,nil)
                    c = c + 1
                    tableEditedMIDI[c] = s_pack("i4BI4BBB", 0, tFlagsLSB[i], #tMsgLSB[i], 0xB0 | tChannels[i], mouseOrigCCLane-224, newValue&127) .. tMsgLSB[i]:sub(4,nil)
                elseif laneIsVELOCITY then
                    -- Insert note-on
                    c = c + 1 
                    tableEditedMIDI[c] = s_pack("i4BI4BBB", offset, tFlags[i], #tMsg[i], 0x90 | tChannels[i], tPitches[i], newValue) .. tMsg[i]:sub(4,nil)
                    -- Since REAPER v5.32, notation (if it exists) must always be inserted *after* its note
                    if tNotation[i] then
                        c = c + 1
                        tableEditedMIDI[c] = s_pack("i4Bs4", 0, tFlags[i]&0xFE, tNotation[i])
                    end
                    -- Insert note-off
                    c = c + 1 
                    tableEditedMIDI[c] = s_pack("i4Bs4", tNoteLengths[i], tFlags[i], tMsgNoteOffs[i])
                    lastPPQPos = lastPPQPos + tNoteLengths[i]
                elseif laneIsOFFVEL then
                    -- Insert note-on
                    c = c + 1 
                    tableEditedMIDI[c] = s_pack("i4Bs4", offset, tFlags[i], tMsg[i])          
                    -- Since REAPER v5.32, notation (if it exists) must always be inserted *after* its note
                    if tNotation[i] then
                        c = c + 1
                        tableEditedMIDI[c] = s_pack("i4Bs4", 0, tFlags[i]&0xFE, tNotation[i])
                    end
                    -- Insert note-off
                    c = c + 1 
                    tableEditedMIDI[c] = s_pack("i4Bi4BBB", tNoteLengths[i], tFlags[i], #tMsgNoteOffs[i], 0x80 | tChannels[i], tPitches[i], newValue) .. tMsgNoteOffs[i]:sub(4,nil)
                    lastPPQPos = lastPPQPos + tNoteLengths[i]
                elseif laneIsPROGRAM then
                    c = c + 1
                    tableEditedMIDI[c] = s_pack("i4BI4BB",  offset, tFlags[i], #tMsg[i], 0xC0 | tChannels[i], newValue) .. tMsg[i]:sub(3,nil) -- NB Program Select uses only 2 bytes!
                end 
            end
        
        elseif stretchBOTTOM then
        
            local stretchFactor = (origValueMax - mouseNewCCValue)/origValueRange
            local newValue
                
            for i = 1, #tTicks do
                
                local flippedValue = flipped and (origValueMin + origValueMax - tValues[i]) or tValues[i]
                newValue = m_floor(origValueMax - stretchFactor*(origValueMax - flippedValue) + 0.5)
                if newValue > laneMaxValue then newValue = laneMaxValue elseif newValue < laneMinValue then laneValue = laneMinValue end
                
                offset = tTicks[i] - lastPPQPos
                
                lastPPQPos = tTicks[i]
                
                if laneIsCC7BIT then
                    c = c + 1
                    tableEditedMIDI[c] = s_pack("i4BI4BBB", offset, tFlags[i], #tMsg[i], 0xB0 | tChannels[i], mouseOrigCCLane, newValue) .. tMsg[i]:sub(4,nil)
                elseif laneIsPITCH then
                    c = c + 1
                    tableEditedMIDI[c] = s_pack("i4BI4BBB", offset, tFlags[i], #tMsg[i], 0xE0 | tChannels[i], newValue&127, newValue>>7) .. tMsg[i]:sub(4,nil)
                elseif laneIsCHANPRESS then
                    c = c + 1
                    tableEditedMIDI[c] = s_pack("i4BI4BB",  offset, tFlags[i], #tMsg[i], 0xD0 | tChannels[i], newValue) .. tMsg[i]:sub(3,nil) -- NB Channel Pressure uses only 2 bytes!
                elseif laneIsCC14BIT then
                    c = c + 1
                    tableEditedMIDI[c] = s_pack("i4BI4BBB", offset, tFlags[i], #tMsg[i], 0xB0 | tChannels[i], mouseOrigCCLane-256, newValue>>7) .. tMsg[i]:sub(4,nil)
                    c = c + 1
                    tableEditedMIDI[c] = s_pack("i4BI4BBB", 0, tFlagsLSB[i], #tMsgLSB[i], 0xB0 | tChannels[i], mouseOrigCCLane-224, newValue&127) .. tMsgLSB[i]:sub(4,nil)
                elseif laneIsVELOCITY then
                    -- Insert note-on
                    c = c + 1 
                    tableEditedMIDI[c] = s_pack("i4BI4BBB", offset, tFlags[i], #tMsg[i], 0x90 | tChannels[i], tPitches[i], newValue) .. tMsg[i]:sub(4,nil)   
                    -- Since REAPER v5.32, notation (if it exists) must always be inserted *after* its note
                    if tNotation[i] then
                        c = c + 1
                        tableEditedMIDI[c] = s_pack("i4Bs4", 0, tFlags[i]&0xFE, tNotation[i])
                    end
                    -- Insert note-off
                    c = c + 1 
                    tableEditedMIDI[c] = s_pack("i4Bs4", tNoteLengths[i], tFlags[i], tMsgNoteOffs[i])
                    lastPPQPos = lastPPQPos + tNoteLengths[i]
                elseif laneIsOFFVEL then
                    -- Insert note-on
                    c = c + 1 
                    tableEditedMIDI[c] = s_pack("i4Bs4", offset, tFlags[i], tMsg[i])          
                    -- Since REAPER v5.32, notation (if it exists) must always be inserted *after* its note
                    if tNotation[i] then
                        c = c + 1
                        tableEditedMIDI[c] = s_pack("i4Bs4", 0, tFlags[i]&0xFE, tNotation[i])
                    end
                    -- Insert note-off
                    c = c + 1 
                    tableEditedMIDI[c] = s_pack("i4Bi4BBB", tNoteLengths[i], tFlags[i], #tMsgNoteOffs[i], 0x80 | tChannels[i], tPitches[i], newValue) .. tMsgNoteOffs[i]:sub(4,nil)
                    lastPPQPos = lastPPQPos + tNoteLengths[i]
                elseif laneIsPROGRAM then
                    c = c + 1
                    tableEditedMIDI[c] = s_pack("i4BI4BB",  offset, tFlags[i], 2, 0xC0 | tChannels[i], newValue) .. tMsg[i]:sub(3,nil) -- NB Program Select uses only 2 bytes!
                end 
            end
        end
    
                    
        -----------------------------------------------------------
        -- DRUMROLL... write the edited events into the MIDI chunk!
        editedMIDIString = table.concat(tableEditedMIDI)
        reaper.MIDI_SetAllEvts(activeTake, editedMIDIString .. string.pack("i4Bs4", -lastPPQPos, 0, "") .. remainMIDIString)

        if isInline then reaper.UpdateItemInProject(activeItem) end
        
    end -- mustCalculate stuff

    
    ---------------------------
    -- Tell pcall to loop again
    return true
    
end -- DEFERLOOP_TrackMouseAndUpdateMIDI()


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
function DEFERLOOP_TrackMouseAndUpdateMIDI_COMPRESS()

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
    dragTimeStarted = dragTimeStarted or (thisCycleTime > startTime + dragTime)  -- No need to call time_precise if dragTimeStarted already true    
   
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
    
    -- MOUSEWHEEL
    local peekOK, pass, time, keys, delta = reaper.JS_WindowMessage_Peek(windowUnderMouse, "WM_MOUSEWHEEL")
    if not (peekOK and time > prevMouseTime) then 
        peekOK, pass, time, keys, delta = reaper.JS_WindowMessage_Peek(windowUnderMouse, "WM_MOUSEHWHEEL")
    end 
    if peekOK and time > prevMouseTime + 0.1 then 
        --if keys&12 ~= 0 then return false end
        -- Standardize delta values
        delta = ((delta > 0) and 1) or ((delta < 0) and -1) or 0
        if macOS then delta = -delta end
        if mouseY < mouseOrigY then delta = -delta end
        -- Pause a little if flat line has been reached
        if mousewheel == 0 then
            if time > prevMouseTime+1 or delta ~= prevDelta then
                mousewheel = (delta == 1) and 0.025 or 40
                prevMouseTime = time
                mustCalculate = true
            end
        else
            -- Meradium's suggestion: If mousewheel is turned rapidly, make larger changes to the curve per defer cycle
            local factor = (delta == prevDelta and time-prevMouseTime < 1) and 0.04/((time-prevMouseTime)^2) or 0.04
            mousewheel = (delta == 1) and (mousewheel*(1+factor)) or (mousewheel/(1+factor))
            -- Snap to flat line (standard compression shape) if either direction goes extreme
            if mousewheel < 0.025 or 40 < mousewheel then 
                mousewheel = 0
            -- Round to 1 if comes close
            elseif 0.962 < mousewheel and mousewheel < 1.04 then
                mousewheel = 1
            end
            prevMouseTime = time
            mustCalculate = true
        end
        prevDelta = delta
    end
    mouseGreaterThanOne = (mousewheel >= 1)
    inversewheel = 1/mousewheel -- Can be infinity
    
    --[[ LEFT CLICK: (If the left mouse button or any modifier key is pressed, after first releasing them, quit.)
    peekOK, pass, time = reaper.JS_WindowMessage_Peek(windowUnderMouse, "WM_LBUTTONDOWN")
    if peekOK and time > startTime then 
        return false 
    end]]
    
    -- MIDDLE BUTTON: Middle button changes curve shape
    peekOK, pass, time = reaper.JS_WindowMessage_Peek(windowUnderMouse, "WM_MBUTTONDOWN")
    if peekOK and time > prevMouseTime then 
        baseShape = (baseShape == "linear") and "sine" or "linear"
        prevMouseTime = time
        mustCalculate = true
    end
    
    -- RIGHT CLICK: Right click changes script mode
    --    * If script is terminated by right button, disarm toolbar.
    --    * REAPER shows context menu when right button is *lifted*, so must continue intercepting mouse messages until right button is lifted.
    peekOK, pass, time = reaper.JS_WindowMessage_Peek(windowUnderMouse, "WM_RBUTTONDOWN")
    if peekOK and time > prevMouseTime then
        compressSYMMETRIC = not compressSYMMETRIC
        prevMouseTime = time
        mustCalculate = true
    end
 
    -- TAKE STILL VALID?
    if not reaper.ValidatePtr2(0, activeTake, "MediaItem_Take*") then return false end

        
    ---------------------
    -- DO THE MIDI STUFF!
    
    -- Scripts that extract selected MIDI events and re-concatenate them out of order (usually at the beginning of the MIDI string, for easier editing)
    --    cannot be auditioned in real-time while events are out of order, since such events are not played.
    -- If the mouse is held still, no editing is done, and instead the take is sorted, thereby temporarily allowing playback.
    
    -- NO NEED TO CALCULATE: -- This mode does not change MIDI order, so no need to sort
    if not mustCalculate then --and not takeIsSorted then
        --[[if not takeIsSorted then
            reaper.MIDI_Sort(activeTake)
            takeIsSorted = true
        end]]
        

    -- MUST CALCULATE:
    else        
        -- MOUSE NEW CC VALUE (vertical position)
        if isInline then
            -- reaper.BR_GetMouseCursorContext was already called above
            _, _, mouseNewPitch, mouseNewCCLane, mouseNewCCValue, mouseNewCCLaneID = reaper.BR_GetMouseCursorContext_MIDI()
            -- Convert BR function's laneID return value to same as this script's GetCCLaneIDFromPoint
            if details == "cc_lane" and mouseOrigCCValue == -1 then mouseOrigCCLaneID = mouseOrigCCLaneID - 0.5 end  
            if mouseNewCCLaneID > mouseOrigCCLaneID then
                 mouseNewCCValue = laneMinValue
            elseif mouseNewCCLaneID < mouseOrigCCLaneID or mouseNewCCValue == -1 then
                mouseNewCCValue = laneMaxValue
            end
        else
            mouseNewCCValue = laneMinValue + (laneMaxValue-laneMinValue) * (tME_Lanes[mouseOrigCCLaneID].ME_BottomPixel - mouseY) / (tME_Lanes[mouseOrigCCLaneID].ME_BottomPixel - tME_Lanes[mouseOrigCCLaneID].ME_TopPixel)
        end
        --[[
        -- May the mouse CC value go beyond lane limits?
        if mouseNewCCValue > laneMaxValue then mouseNewCCValue = laneMaxValue
        elseif mouseNewCCValue < laneMinValue then mouseNewCCValue = laneMinValue
        else mouseNewCCValue = math.floor(mouseNewCCValue+0.5)
        end]]
    
      
        -- MOUSE NEW TICK / PPQ VALUE (horizontal position)
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
        leftPPQrange = mouseNewPPQPos - origPPQleftmost
        rightPPQrange = origPPQrightmost - mouseNewPPQPos
                
                
        -- CALCULATE NEW CCA VALUES!
        -- Declaring these stuff local only speeds things up by less than 1/100th of a second.  And only when thousands of events are selected.
        local newValue, fraction 
        
        for i = 1, #tTargets do
            local CC = tTargets[i]
            if CC.ticks == mouseNewPPQPos or mousewheel == 0 then
                fraction = 1
            else
                if mouseGreaterThanOne then
                    if CC.ticks < mouseNewPPQPos then
                        fraction = ((CC.ticks - origPPQleftmost)/leftPPQrange)^mousewheel
                    else
                        fraction = ((origPPQrightmost - CC.ticks)/rightPPQrange)^mousewheel
                    end
                else
                    if CC.ticks < mouseNewPPQPos then
                        fraction = 1 - ((mouseNewPPQPos - CC.ticks)/leftPPQrange)^inversewheel
                    else
                        fraction = 1 - ((CC.ticks - mouseNewPPQPos)/rightPPQrange)^inversewheel
                    end
                end
            end
            if baseShape == "sine" then fraction = 0.5*(1-m_cos(m_pi*fraction)) end
                
            local tempLaneMin, tempLaneMax
            if compressTOP then
                tempLaneMax = laneMaxValue + fraction*(mouseNewCCValue-laneMaxValue)
                if compressSYMMETRIC then
                    tempLaneMin = laneMinValue + fraction*(laneMaxValue-mouseNewCCValue)
                else
                    tempLaneMin = laneMinValue
                end
            else
                tempLaneMin = laneMinValue + fraction*(mouseNewCCValue-laneMinValue)
                if compressSYMMETRIC then
                    tempLaneMax = laneMaxValue + fraction*(laneMinValue-mouseNewCCValue)
                else
                    tempLaneMax = laneMaxValue
                end
            end
            newValue = tempLaneMin + CC.rel * (tempLaneMax - tempLaneMin)
            
            if      newValue > laneMaxValue then newValue = laneMaxValue
            elseif  newValue < laneMinValue then newValue = laneMinValue
            else    newValue = math.floor(newValue+0.5)
            end
            
            if      laneIsCC14BIT then tMIDI[CC.indexMSB] = s_pack("B", newValue >> 7); tMIDI[CC.indexLSB] = s_pack("B", newValue & 127)
            elseif  laneIsPITCH   then tMIDI[CC.index]    = s_pack("BB", newValue&127, newValue>>7)
            else    tMIDI[CC.index] = s_pack("B", newValue)
            end
        end
                 
        -----------------------------------------------------------
        -- DRUMROLL... write the edited events into the MIDI chunk!
        reaper.MIDI_SetAllEvts(activeTake, table.concat(tMIDI))
        if isInline then reaper.UpdateItemInProject(activeItem) end


        -------------------------------------------------------
        -- Guidelines
        if compositeOK then
            local tTopY = {}
            local tBottomY = {}
            
            for i, ticks in ipairs(tGuides_Ticks) do
                if mousewheel == 0 then --or (mouseNewPPQPos-5 < ticks and ticks < mouseNewPPQPos+5) then 
                    fraction = 1
                else
                    if mouseGreaterThanOne then
                        if ticks < mouseNewPPQPos then
                            fraction = ((ticks - origPPQleftmost)/leftPPQrange)^mousewheel
                        else
                            fraction = ((origPPQrightmost - ticks)/rightPPQrange)^mousewheel
                        end
                    else
                        if ticks < mouseNewPPQPos then
                            fraction = 1 - ((mouseNewPPQPos - ticks)/leftPPQrange)^inversewheel
                        else
                            fraction = 1 - ((ticks - mouseNewPPQPos)/rightPPQrange)^inversewheel
                        end
                    end
                end
                if baseShape == "sine" then fraction = 0.5*(1-m_cos(m_pi*fraction)) end
            
                if compressTOP then
                    tTopY[i] = ME_TargetTopPixel + fraction*(mouseY-ME_TargetTopPixel)
                    if compressSYMMETRIC then
                        tBottomY[i] = ME_TargetBottomPixel + 1 - fraction*(mouseY-ME_TargetTopPixel)
                    else
                        tBottomY[i] = ME_TargetBottomPixel + 1
                    end
                else
                    tBottomY[i] = ME_TargetBottomPixel + 1 - fraction*(ME_TargetBottomPixel-mouseY)
                    if compressSYMMETRIC then
                        tTopY[i] = ME_TargetTopPixel + fraction*(ME_TargetBottomPixel-mouseY)
                    else
                        tTopY[i] = ME_TargetTopPixel
                    end
                end
            end
            
            reaper.JS_LICE_Clear(bitmap, 0)
            local x1, t1, b1 = tGuides_X[1], tTopY[1], tBottomY[1] -- Coordinates of left pixel of each line segment
            for i = 2, #tGuides_X do
                if x1 < mouseX and mouseX < tGuides_X[i] then -- To make sure than pointy curve is correctly drawn, even is point falls between 10-pixel segements, insert extra line
                    if compressTOP then
                        reaper.JS_LICE_Line(bitmap, x1, t1, mouseX, mouseY, Guides_COLOR_TOP, 1, "COPY", true)
                        t1 = mouseY
                        if compressSYMMETRIC then
                            reaper.JS_LICE_Line(bitmap, x1, b1, mouseX, (ME_TargetBottomPixel+1) - (mouseY-ME_TargetTopPixel), Guides_COLOR_BOTTOM, 1, "COPY", true)
                            b1 = (ME_TargetBottomPixel+1) - (mouseY-ME_TargetTopPixel)
                        else
                            reaper.JS_LICE_Line(bitmap, x1, b1, mouseX, ME_TargetBottomPixel+1, Guides_COLOR_BOTTOM, 1, "COPY", true)
                            b1 = ME_TargetBottomPixel+1
                        end
                    else
                        reaper.JS_LICE_Line(bitmap, x1, b1, mouseX, mouseY, Guides_COLOR_BOTTOM, 1, "COPY", true)
                        b1 = mouseY
                        if compressSYMMETRIC then
                            reaper.JS_LICE_Line(bitmap, x1, t1, mouseX, ME_TargetTopPixel - (mouseY-ME_TargetBottomPixel), Guides_COLOR_TOP, 1, "COPY", true)
                            t1 = ME_TargetTopPixel - (mouseY-ME_TargetBottomPixel)
                        else
                            reaper.JS_LICE_Line(bitmap, x1, t1, mouseX, ME_TargetTopPixel, Guides_COLOR_TOP, 1, "COPY", true)
                            t1 = ME_TargetTopPixel
                        end
                    end
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
    if modeIsSTRETCH then
        pcallOK, pcallMustContinue = pcall(DEFERLOOP_TrackMouseAndUpdateMIDI_STRETCH)
    else
        pcallOK, pcallMustContinue = pcall(DEFERLOOP_TrackMouseAndUpdateMIDI_COMPRESS)
    end
    if pcallOK and pcallMustContinue then
        reaper.defer(DEFERLOOP_pcall)
    end
end


--############################################################################################
----------------------------------------------------------------------------
function AtExit()    
    
    -- Remove intercepts, restore original intercepts.  Do this first, because these are most important to restore, in case anything else goes wrong during AtExit.
    if interceptKeysOK ~= nil then pcall(function() reaper.JS_VKeys_Intercept(-1, -1) end) end
    if compositeOK and midiview and bitmap then pcall(function() reaper.JS_Composite_Unlink(midiview, bitmap) end) end
    if bitmap then reaper.JS_LICE_DestroyBitmap(bitmap) end
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
        -- Before exiting, if DEFERLOOP_pcall was successfully executed, delete existing CCs in the stretch's range (and channel)
        -- The delete function will also ensure that the MIDI is re-uploaded into the active take.
        if pcallOK == true and modeIsSTRETCH and (stretchRIGHT or stretchLEFT) and mustDeleteOverlappingCCs and not laneIsNOTES then 
            pcallOK, pcallRetval = pcall(DeleteOverlappingCCs) -- This function does not return any value, but retval will carry exception info, if any
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
        if (stretchLEFT or stretchRIGHT) then
            if laneIsCC7BIT then
                undoString = "Stretch positions of 7-bit CC events in lane ".. tostring(mouseOrigCCLane)
            elseif laneIsCHANPRESS then
                undoString = "Stretch positions of channel pressure events"
            elseif laneIsCC14BIT then
                undoString = "Stretch positions of 14 bit-CC events in lanes ".. 
                                          tostring(mouseOrigCCLane-256) .. "/" .. tostring(mouseOrigCCLane-224)
            elseif laneIsPITCH then
                undoString = "Stretch positions of pitchwheel events"
            elseif laneIsNOTES then
                undoString = "Stretch positions and lengths of notes"
            elseif laneIsTEXT then
                undoString = "Stretch positions of text events"
            elseif laneIsSYSEX then
                undoString = "Stretch positions of sysex events"
            elseif laneIsPROGRAM then
                undoString = "Stretch positions of program select events"
            elseif laneIsBANKPROG then
                undoString = "Stretch positions of bank/program select events"
            else
                undoString = "Stretch event positions"
            end 
        elseif stretchTOP or stretchBOTTOM then
            if laneIsCC7BIT then
                undoString = "Stretch values of 7-bit CC events in lane ".. tostring(mouseOrigCCLane)
            elseif laneIsCHANPRESS then
                undoString = "Stretch values of channel pressure events"
            elseif laneIsCC14BIT then
                undoString = "Stretch values of 14 bit-CC events in lanes "
                              .. tostring(mouseOrigCCLane-256) .. "/" .. tostring(mouseOrigCCLane-224)
            elseif laneIsPITCH then
                undoString = "Stretch values of pitchwheel events"
            elseif laneIsVELOCITY then
                undoString = "Stretch velocities of notes"
            elseif laneIsPROGRAM then
                undoString = "Stretch values of program select events"
            else
                undoString = "Stretch event values"
            end   
        else -- modeIsCOMPRESS
            if laneIsCC7BIT then 
                undoString = "Compress CC lane ".. tostring(mouseOrigCCLane)
            elseif laneIsCHANPRESS then
                undoString = "Compress channel pressure lane"
            elseif laneIsCC14BIT then
                undoString = "Compress 14-bit CC lane ".. 
                                          tostring(mouseOrigCCLane-256) .. "/" .. tostring(mouseOrigCCLane-224)
            elseif laneIsPITCH then
                undoString = "Compress pitchwheel lane"
            elseif laneIsVELOCITY then
                undoString = "Compress velocity lane"
            elseif laneIsPROGRAM then
                undoString = "Compress program select lane"
            else
                undoString = "Compress CC lane"
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


--####################################################################################
--------------------------------------------------------------------------------------
function DeleteOverlappingCCs()
    
    if laneIsNOTES then --not (laneIsPITCH or laneIsCC7BIT or laneIsCC14BIT or laneIsCHANPRESS or laneIsPROGRAM or laneIsTEXT or laneIsSYSEX or laneIsALL) then
        return
    end
    
    -- Construct table with min and max PPQ positions for each event type.
    -- Deletion will be type-channel-, and lane-specific.
    -- Get final positions of edited events by parsing tableEditedMIDI.
    local tableMinMax = {}
    local runningPPQPos = 0 -- position while parsing edited events
    local eventIsOtherCC = {[0xC] = true, [0xD] = true, [0xE] = true}
    for i = 1, #tableEditedMIDI do
        runningPPQPos = runningPPQPos + s_unpack("i4", tableEditedMIDI[i], 1)
        local msg = tableEditedMIDI[i]:sub(10,11)
        local statusByte = msg:byte(1)
        local eventType = statusByte and statusByte>>4
        local eventID -- Will get value if event is type that ust be deleted if overlapped, such as CC or pitch.  NOT notes or text/sysex.
        if eventType == 0xB then -- Standard CC
            eventID = msg -- contains type, channel and CC lane
        elseif eventIsOtherCC[eventType] then -- Other CC types (pitch etc)
            eventID = msg:byte(1) -- contains type and channel 
        elseif statusByte == 0xFF then -- text events
            if msg:byte(2) ~= 0x0F then -- excluding REAPER's notation events
                eventID = msg
            end
        elseif eventType == 0xF then -- sysex (excluding 0xFF text events)
            eventID = msg:byte(1)
        end
        if eventID then
            if tableMinMax[eventID] then
                if runningPPQPos < tableMinMax[eventID].min then tableMinMax[eventID].min = runningPPQPos end
                if runningPPQPos > tableMinMax[eventID].max then tableMinMax[eventID].max = runningPPQPos end
            else
                tableMinMax[eventID] = {min = runningPPQPos, max = runningPPQPos}
            end
        end
    end
    
    local lastStretchedPPQPos = runningPPQPos -- Rest of unedited events must be offset relative to last PPQ position in edited events.
    
    -- Now search through the remainMIDIString.
    local tableRemainingEvents = {}
    local r = 0
    local runningPPQPos = 0
    local lastRemainPPQPos = 0 -- Will be used to update offset of event directly after deleted event.
    local prevPos, nextPos, unchangedPos = 1, 1, 1
    local offset, flags, msg
    
    local MIDIlen = remainMIDIString:len()
    while nextPos < MIDIlen do
    
        prevPos = nextPos
        offset, flags, msg, nextPos = s_unpack("i4Bs4", remainMIDIString, nextPos)
        runningPPQPos = runningPPQPos + offset
        
        local mustDelete = false
        
        local statusByte = msg:byte(1)
        local eventType = statusByte and statusByte>>4
        local eventID -- Will get value if event is type that ust be deleted if overlapped, such as CC or pitch.  NOT notes or text/sysex.
        if eventType == 0xB then -- Standard CC
            eventID = msg:sub(1,2) -- contains type, channel and CC lane
        elseif eventIsOtherCC[eventType] then -- Other CC types (pitch etc)
            eventID = msg:byte(1) -- contains type and channel 
        elseif eventType == 0xF and not (statusByte == 0xFF) then -- sysex
            eventID = msg:byte(1)
        elseif statusByte == 0xFF and not (msg:byte(2) == 0x0F) then -- text events, excluding notation
            eventID = msg:sub(1,2)
        end
        if eventID and tableMinMax[eventID] then -- does this event type occur in selected events?
            if (runningPPQPos >= tableMinMax[eventID].min and runningPPQPos <= tableMinMax[eventID].max) then 
                mustDelete = true
            end
        end
        
        -- Remove to-be-deleted events and update remaining events' offsets
        if mustDelete then
            -- The chain of unchanged events is broken, so write to tableRemainingEvents
            if unchangedPos < prevPos then
                r = r + 1
                tableRemainingEvents[r] = remainMIDIString:sub(unchangedPos, prevPos-1)
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
    if unchangedPos < MIDIlen then
        r = r + 1
        tableRemainingEvents[r] = remainMIDIString:sub(unchangedPos)
    end
      
    reaper.MIDI_SetAllEvts(activeTake, editedMIDIString .. string.pack("i4Bs4", -lastPPQPos, 0, "") .. table.concat(tableRemainingEvents))

end


--###############################################################################################
-------------------------------------------------------------------------------------------------
-- Returns true, laneType if CC lane could be parsed, 
--    true, nil if multiple visible lanes were enabled, and 
--    false if target lane is unusable or could not be parsed.
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


--##########################################################################
----------------------------------------------------------------------------
-- Parse MIDI string; store selected events' values
function GetAndParseMIDIString_COMPRESS()

    -- If unsorted MIDI is encountered, this helper function will be called
    local function helper_TryToSort()
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
    end
    
    ::startAgain::
    
    getAllEvtsOK, MIDIString = reaper.MIDI_GetAllEvts(activeTake, "")
        if not getAllEvtsOK then reaper.MB("MIDI_GetAllEvts could not load the raw MIDI data.", "ERROR", 0) return false end
    
    tTargets = {}
    tMIDI    = {}
    
    local t14 = {} -- Store index in tTargets of 14bit event at chan and tick: t14[chan][tick] = {indexMSB = ..., indexLSB = ..., val = ...}
        for chan = 0, 15 do t14[chan] = {} end
    
    local pos, savePos = 1, 1 -- Positions inside MIDI string while parsing; position from which to save next part of string, in-between target values that will be changed.
    local ticks = 0 -- Running PPQ position of events while parsing
    local offset, flags, msg
    
    local MIDI, MIDILen = MIDIString, #MIDIString
    local targetLane = mouseOrigCCLane
      
    if laneIsCC7BIT then
        while pos < MIDILen do
            offset, flags, msg, pos = string.unpack("i4Bs4", MIDI, pos)
            if offset < 0 then if helper_tryToSort() then goto startAgain else return false end end -- Check for unsorted MIDI
            ticks = ticks + offset
            if flags&1==1 and #msg >= 3 and msg:byte(2) == targetLane and (msg:byte(1))>>4 == 11 and (editAllChannels or msg:byte(1)&0x0F == activeChannel) then
                tMIDI[#tMIDI+1] = MIDI:sub(savePos, pos-#msg+1)
                tMIDI[#tMIDI+1] = msg:sub(3, 3)
                savePos = pos-#msg+3
                tTargets[#tTargets+1] = {index = #tMIDI, val = msg:byte(3), ticks = ticks}
            end
        end
    elseif laneIsCC14BIT then
        local targetLaneMSB, targetLaneLSB = targetLane-256, targetLane-224
        while pos < MIDILen do
            offset, flags, msg, pos = string.unpack("i4Bs4", MIDI, pos)
            if offset < 0 then if helper_tryToSort() then goto startAgain else return false end end -- Check for unsorted MIDI
            ticks = ticks + offset
            if flags&1==1 and #msg >= 3 and (msg:byte(1))>>4 == 11 and (editAllChannels or msg:byte(1)&0x0F == activeChannel) then
                if msg:byte(2) == targetLaneMSB then
                    -- Store value so that can later be combined with LSB
                    local chan = msg:byte(1)&0x0F
                    local i = t14[chan][ticks]
                    if not i then -- Previously stored CC in this channnel and tick position? If not, create new one.
                        tTargets[#tTargets+1] = {ticks = ticks}
                        t14[chan][ticks] = #tTargets
                        i = #tTargets
                    end
                    if tTargets[i].indexMSB then -- Oops, already got MSB with this tick pos and channel.  So delete this MSB (replace with blank spacer.)
                        tMIDI[#tMIDI+1] = MIDI:sub(savePos, pos-#msg-6) .. "\0\0\0\0\0"
                        savePos = pos
                    else
                        tMIDI[#tMIDI+1] = MIDI:sub(savePos, pos-#msg+1)
                        tMIDI[#tMIDI+1] = msg:sub(3, 3)
                        savePos = pos-#msg+3
                        tTargets[i].indexMSB = #tMIDI
                        tTargets[i].val = (tTargets[i].val or 0) | (msg:byte(3)<<7)
                    end
                elseif msg:byte(2) == targetLaneLSB then
                    local chan = msg:byte(1)&0x0F
                    local i = t14[chan][ticks]
                    if not i then -- Previously stored CC in this channnel and tick position? If not, create new one.
                        tTargets[#tTargets+1] = {ticks = ticks}
                        t14[chan][ticks] = #tTargets
                        i = #tTargets
                    end
                    if tTargets[i].indexLSB then -- Oops, already got MSB with this tick pos and channel.  So delete this MSB (replace with blank spacer.)
                        tMIDI[#tMIDI+1] = MIDI:sub(savePos, pos-#msg-6) .. "\0\0\0\0\0"
                        savePos = pos
                    else
                        tMIDI[#tMIDI+1] = MIDI:sub(savePos, pos-#msg+1)
                        tMIDI[#tMIDI+1] = msg:sub(3, 3)
                        savePos = pos-#msg+3
                        tTargets[i].indexLSB = #tMIDI
                        tTargets[i].val = (tTargets[i].val or 0) | (msg:byte(3))
                    end
                end -- if msg:byte(2) == targetLaneMSB
            end -- if #msg == 3 and (msg:byte(1))>>4 == 11
        end
    elseif laneIsPITCH then
        while pos < MIDILen do
            offset, flags, msg, pos = string.unpack("i4Bs4", MIDI, pos)
            if offset < 0 then if helper_tryToSort() then goto startAgain else return false end end -- Check for unsorted MIDI
            ticks = ticks + offset
            if flags&1==1 and #msg >= 3 and (msg:byte(1))>>4 == 14 and (editAllChannels or msg:byte(1)&0x0F == activeChannel) then
                tMIDI[#tMIDI+1] = MIDI:sub(savePos, pos-#msg)
                tMIDI[#tMIDI+1] = msg:sub(2, 3)
                savePos = pos-#msg+3
                tTargets[#tTargets+1] = {index = #tMIDI, val = (msg:byte(3)<<7) + msg:byte(2), ticks = ticks}
            end
        end   
    elseif laneIsPROGRAM then 
        while pos < MIDILen do
            offset, flags, msg, pos = string.unpack("i4Bs4", MIDI, pos)
            if offset < 0 then if helper_tryToSort() then goto startAgain else return false end end -- Check for unsorted MIDI
            ticks = ticks + offset
            if flags&1==1 and #msg >= 2 and (msg:byte(1))>>4 == 12 and (editAllChannels or msg:byte(1)&0x0F == activeChannel) then
                tMIDI[#tMIDI+1] = MIDI:sub(savePos, pos-#msg)
                tMIDI[#tMIDI+1] = msg:sub(2, 2)
                savePos = pos-#msg+2
                tTargets[#tTargets+1] = {index = #tMIDI, val = msg:byte(2), ticks = ticks}
            end
        end 
    elseif laneIsCHANPRESS then 
        while pos < MIDILen do
            offset, flags, msg, pos = string.unpack("i4Bs4", MIDI, pos)
            if offset < 0 then if helper_tryToSort() then goto startAgain else return false end end -- Check for unsorted MIDI
            ticks = ticks + offset
            if flags&1==1 and #msg >= 2 and (msg:byte(1))>>4 == 13 and (editAllChannels or msg:byte(1)&0x0F == activeChannel) then
                tMIDI[#tMIDI+1] = MIDI:sub(savePos, pos-#msg)
                tMIDI[#tMIDI+1] = msg:sub(2, 2)
                savePos = pos-#msg+2
                tTargets[#tTargets+1] = {index = #tMIDI, val = msg:byte(2), ticks = ticks}
            end
        end 
    elseif laneIsVELOCITY then 
        while pos < MIDILen do
            offset, flags, msg, pos = string.unpack("i4Bs4", MIDI, pos)
            if offset < 0 then if helper_tryToSort() then goto startAgain else return false end end -- Check for unsorted MIDI
            ticks = ticks + offset
            if flags&1==1 and #msg >= 3 and (msg:byte(1))>>4 == 9 and msg:byte(3) ~= 0 and (editAllChannels or msg:byte(1)&0x0F == activeChannel) then
                tMIDI[#tMIDI+1] = MIDI:sub(savePos, pos-#msg+1)
                tMIDI[#tMIDI+1] = msg:sub(3, 3)
                savePos = pos-#msg+3
                tTargets[#tTargets+1] = {index = #tMIDI, val = msg:byte(3), pitch = msg:byte(2), ticks = ticks}
            end
        end 
    elseif laneIsOFFVEL then 
        while pos < MIDILen do
            offset, flags, msg, pos = string.unpack("i4Bs4", MIDI, pos)
            if offset < 0 then if helper_tryToSort() then goto startAgain else return false end end -- Check for unsorted MIDI
            ticks = ticks + offset
            if flags&1==1 and #msg >= 3 and ((msg:byte(1)>>4 == 9 and msg:byte(3) == 0) or msg:byte(1)>>4 == 8) and (editAllChannels or msg:byte(1)&0x0F == activeChannel) then
                tMIDI[#tMIDI+1] = MIDI:sub(savePos, pos-#msg+1)
                tMIDI[#tMIDI+1] = msg:sub(3, 3)
                savePos = pos-#msg+3
                tTargets[#tTargets+1] = {index = #tMIDI, val = msg:byte(3), ticks = ticks}
            end
        end 
    end
    
    -- Insert all unselected events remaining
    tMIDI[#tMIDI+1] = MIDI:sub(savePos, nil)   
    
    -- Check that all 14bit CCs have partnerse 
    if laneIsCC14BIT then
        for _, i in ipairs(tTargets) do
            if not (i.indexMSB and i.indexLSB) then
                reaper.MB("The target CC lane is 14bit CC, but some of the selected MSB [or LSB] CCs do not have selected LSB [or MSB] partners", "ERROR", 0)
                return false
            end
        end
    end 
    
    if #tTargets > 0 then origPPQleftmost, origPPQrightmost = tTargets[1].ticks, tTargets[#tTargets].ticks end    
    
    return true
end


--####################################################################################
--------------------------------------------------------------------------------------
function GetAndParseMIDIString_STRETCH()  
    
    -- Start again here if sorting was done.
    ::startAgain::

    -- REAPER v5.30 introduced new API functions for fast, mass edits of MIDI:
    --    MIDI_GetAllEvts and MIDI_SetAllEvts.
    gotAllOK, MIDIString = reaper.MIDI_GetAllEvts(activeTake, "")
        if not gotAllOK then reaper.MB("MIDI_GetAllEvts could not load the raw MIDI data.", "ERROR", 0) return false end
    
    local MIDIlen = #MIDIString
    
    -- These functions are fast, but require complicated parsing of the MIDI string.
    -- The following tables with temporarily store data while parsing:
    local tableNoteOns = {} -- Store note-on position and pitch while waiting for the next note-off, to calculate note length
    local tableTempNotation = {} -- Store notation text while waiting for a note-on with matching position, pitch and channel
    local tableCCMSB = {} -- While waiting for matching LSB of 14-bit CC: tableCCMSB[channel][PPQPos] = value
    local tableCCLSB = {} -- While waiting for matching MSB of 14-bit CC: tableCCLSB[channel][PPQPos] = value
    if laneIsNOTES or laneIsALL then
        for chan = 0, 15 do
            tableNoteOns[chan] = {}
            tableTempNotation[chan] = {}
            for pitch = 0, 127 do
                tableNoteOns[chan][pitch] = {}
                tableTempNotation[chan][pitch] = {} -- tableTempNotation[channel][pitch][PPQPos] = notation text message
                for flags = 0, 3 do
                    tableNoteOns[chan][pitch][flags] = {} -- = {PPQPos, velocity} (note-off must match channel, pitch and flags)
                end
            end
        end
    elseif laneIsCC14BIT then
        for chan = 0, 15 do
            tableCCMSB[chan] = {} 
            tableCCLSB[chan] = {} 
            for flags = 1, 3, 2 do
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
    --      inserted individually into tableRemainingEvents, using string.pack.  Instead, they will be 
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
    --[[if laneIsBANKPROG then
    
        local MIDIrev = MIDIString:reverse()
        local matchProgStrRev = table.concat({"[",string.char(0xC0),"-",string.char(0xCF),"]",
                                                  string.pack("I4", 2):reverse(),
                                              "[",string.char(0x01, 0x03),"]"})
        local msg2string = string.char(0, 32):gsub("[%(%)%.%%%+%-%*%?%[%]%^]", "%%%0")
        local matchBankStrRev = table.concat({"[",msg2string,"]",
                                              "[",string.char(0xB0),"-",string.char(0xBF),"]", 
                                                  string.pack("I4", 3):reverse(),
                                              "[",string.char(0x01, 0x03),"]"})
        firstTargetPosReversedProg = MIDIrev:find(matchProgStrRev)
        firstTargetPosReversedBank = MIDIrev:find(matchBankStrRev)
        if firstTargetPosReversedProg and firstTargetPosReversedBank then 
            firstTargetPosReversed = math.min(MIDIlen-firstTargetPosReversedProg, MIDIlen-firstTargetPosReversedBank)
        elseif firstTargetPosReversedProg then firstTargetPosReversed = firstTargetPosReversedProg
        elseif firstTargetPosReversedBank then firstTargetPosReversed = firstTargetPosReversedBank
        end
              
    else ]]
    if laneIsALL then
        lastTargetStrPos = MIDIlen-12
    else
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
        
        if firstTargetPosReversed then 
            lastTargetStrPos = MIDIlen - firstTargetPosReversed 
        else -- Found no targeted events
            lastTargetStrPos = 0
        end   
    end 
    
    ---------------------------------------------------------------------------------------------
    -- OK, got an upper limit.  Not iterate through MIDIString, until the upper limit is reached.
    while nextPos < lastTargetStrPos do
       
        local mustExtract = false
        local offset, flags, msg
        
        prevPos = nextPos
        offset, flags, msg, nextPos = s_unpack("i4Bs4", MIDIString, prevPos)

        -- Check for unsorted MIDI
        if offset < 0 then   
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
        if flags&1 == 1 -- bit 1: selected
        and msg:len() ~= 0 -- Skip empty space events
        and (editAllChannels or msg:byte(1)&0x0F == activeChannel or msg:byte(1)>>4 == 0x0F) -- Events with 0xF0 types, i.e. text, sysex and notation, do not have channels nibbles
        then 
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
                        reaper.ShowMessageBox("There appears to be orphan note-offs (probably caused by overlapping notes or unsorted MIDI data) in the active takes."
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
                    -- Has a corresponding LSB value already been saved?  If so, combine and save in tValues.
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
                        tMsgNoteOffs[n.index] = string.pack("BBB", 0x80 | channel, pitch, msg:byte(3)) -- Replace possible note-on with vel=0 msg with proper note-off
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
    if includeNoteOffsInPPQRange and (laneIsNOTES or laneIsALL) then
        origPPQleftmost  = tTicks[1]
        origPPQrightmost = tTicks[#tTicks] -- temporary
        local noteEndPPQ
        for i = 1, #tTicks do
            if tNoteLengths[i] then -- laneIsALL event is a note
                noteEndPPQ = tTicks[i] + tNoteLengths[i]
                if noteEndPPQ > origPPQrightmost then origPPQrightmost = noteEndPPQ end
            end
        end
        origPPQRange = origPPQrightmost - origPPQleftmost
    else
        origPPQleftmost  = tTicks[1]
        origPPQrightmost = tTicks[#tTicks]
        origPPQRange     = origPPQrightmost - origPPQleftmost
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
        Tooltip("Armed: Stretch and Compress")
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
    
    
    -- MOUSE CURSOR AND TOOLBAR BUTTON
    -- To give an impression of quick responsiveness, the script must change the cursor and toolbar button as soon as possible.
    -- (Later, the script will block "WM_SETCURSOR" to prevent REAPER from changing the cursor back after each defer cycle.)
    _, filename, sectionID, commandID = reaper.get_action_context()
    filename = filename:gsub("\\", "/") -- Change Windows format to cross-platform
    filename = filename:match("^.*/") or "" -- Remove script filename, keeping directory
    --filename = filename .. "..."
    --cursor = reaper.JS_Mouse_LoadCursorFromFile(filename) -- The first time that the cursor is loaded in the session will be slow, but afterwards the extension will re-use previously loaded cursor
    --if not cursor then cursor = reaper.JS_Mouse_LoadCursor(433) end -- If .cur file unavailable, load one of REAPER's own cursors]]
    cursor = reaper.JS_Mouse_LoadCursor(429) -- Open hand cursor
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
                                
                                -- Get CC lane.  The mode of this script depends on mouse starting position and movement: 
                                mouseOrigCCLaneID = GetCCLaneIDFromPoint(mouseOrigX, mouseOrigY)
                                if mouseOrigCCLaneID and (mouseOrigCCLaneID == -1.5 or mouseOrigCCLaneID%1 == 0) then
                                    modeIsSTRETCH = true
                                else
                                    while mouseOrigCCLaneID and mouseOrigCCLaneID%1 ~= 0 do
                                        local x, y = reaper.GetMousePosition()
                                        x, y = reaper.JS_Window_ScreenToClient(midiview, x, y)
                                        local dX, dY = math.abs(x-mouseOrigX), math.abs(y-mouseOrigY)
                                        mouseOrigCCLaneID = GetCCLaneIDFromPoint(x, y)
                                        if not mouseOrigCCLaneID then -- Moved out of midiview
                                            break
                                        elseif mouseOrigCCLaneID%1 == 0 then -- Move into lane
                                            modeIsCOMPRESS = true
                                            if y > mouseOrigY then compressTOP = true else compressBOTTOM = true end
                                            break
                                        elseif dX > dY and dX > mouseMovementResolution then -- Moved laterally
                                            modeIsSTRETCH = true 
                                            laneIsALL = true
                                            break 
                                        end
                                    end
                                end
                                
                                if mouseOrigCCLaneID and (modeIsCOMPRESS or modeIsSTRETCH) then
                                    
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
                if details == "cc_lane" and mouseOrigCCValue == -1 then mouseOrigCCLaneID = mouseOrigCCLaneID - 0.5 end -- Convert SWS lane divider ID's to this script's.
                
                if isInline then
                    
                    editor = nil
                    modeIsSTRETCH = true -- inline editor doesn't have COMPRESS mode
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
    if modeIsSTRETCH then
        if laneIsNOTATION or laneIsMEDIAITEM then
            reaper.MB("This script cannot stretch events in the notation or media item lanes.", "ERROR: Stretch", 0)
            return false
        end
    else -- modeIsCOMPRESS
        if not (laneMinValue and laneMaxValue and (laneIsCC7BIT or laneIsCC14BIT or laneIsCHANPRESS or laneIsPITCH or laneIsVELOCITY or laneIsOFFVEL or laneIsPROGRAM)) then
            reaper.MB("The script can only compress events in the following MIDI lanes: \n * Velocity or Off velocity, \n * 7-bit or 14-bit CC, \n * Pitchwheel, or\n * Channel Pressure."
                  .. "\n\nTo tell the script which lane must be compressed, the mouse must be positioned on a lane divider when the script starts, and then move into the target lane (as if the mouse is dragging the border of the target lane)."
                  , "ERROR: Compress", 0)
            return false 
        end
    end
    
    
    -- MOUSE PPQ VALUES
    -- Get mouse starting PPQ position -- AND ADJUST FOR LOOPING AND SNAPPING
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
    snappedOrigPPQPos = math.max(minimumTick, math.min(maximumTick, snappedOrigPPQPos))

    
    -- GET AND PARSE MIDI:
    -- Time to process the MIDI of the take!
    -- As mentioned in the header, this script does not use the old-fashioned MIDI API functions such as 
    --    MIDI_InsertCC, since these functions are far too slow when dealing with thousands of events.
    if modeIsSTRETCH then
        if not GetAndParseMIDIString_STRETCH() then return false end
        if #tTicks < 2 or (#tTicks < 3 and not laneIsNOTES) then -- Two notes can be stretched, but not two CCs
            reaper.MB("Could not find a sufficient number of selected events in the target lane(s)."
                    .. "\n\nNB: If the MIDI editor's filter is set to \"Edit active channel only\", the script will only edit events in the active channel."
                    , "ERROR", 0)
            return false
        end
    else -- modeIsCOMPRESS
        if not GetAndParseMIDIString_COMPRESS() then return false end
        if #tMIDI <= 2 then
            reaper.MB("Could not find a sufficient number of selected events in the target lane(s)."
                    .. "\n\nNB: If the MIDI editor's filter is set to \"Edit active channel only\", the script will only edit events in the active channel."
                    , "ERROR", 0)
            return false
        end
        for i = 1, #tTargets do
            tTargets[i].rel = (tTargets[i].val - laneMinValue) / laneMaxValue
        end
    end    
        
    
    -- UNIQUE TO THIS SCRIPT:
    if modeIsSTRETCH then
    
        -- Determine in which direction events will be stretched
        edgeSize = math.max(0, math.min(0.5, edgeSize))
        -- these can only be stretch horizontally    
        if origPPQRange > 0 and (origValueRange == 0 or (laneIsALL or laneIsSYSEX or laneIsTEXT or laneIsPIANOROLL or laneIsBANKPROG)) then
            if mouseOrigPPQPos > origPPQleftmost + 0.5*origPPQRange then stretchRIGHT = true
            else stretchLEFT = true
            end
        -- only stretch vertically (origPPQRange == 0 may happen if several notes in a chord are selected)
        elseif not (laneIsSYSEX or laneIsTEXT or laneIsPIANOROLL or laneIsBANKPROG) and origValueRange > 0 and origPPQRange == 0 then  
            if mouseOrigCCValue > origValueMin + 0.5*origValueRange then stretchTOP = true
            else stretchBOTTOM = true
            end
        elseif origValueRange > 0 and origPPQRange > 0 then
            if mouseOrigPPQPos > origPPQrightmost - edgeSize*origPPQRange then stretchRIGHT = true
            elseif mouseOrigPPQPos < origPPQleftmost + edgeSize*origPPQRange then stretchLEFT = true
            elseif mouseOrigCCValue > origValueMin + 0.5*origValueRange then stretchTOP = true
            else stretchBOTTOM = true
            end
        else
            reaper.MB("Could not find a sufficient number of selected events with different values and/or PPQ positions in the target lane."
                    .. "\n\nNB: If the MIDI editor's filter is set to \"Edit active channel only\", the script will only edit events in the active channel."
                    , "ERROR", 0)
            return(false)
        end
        
        if stretchLEFT then
            cursor = reaper.JS_Mouse_LoadCursor(430) or cursor
            if cursor then reaper.JS_Mouse_SetCursor(cursor) end
        elseif stretchRIGHT then
            cursor = reaper.JS_Mouse_LoadCursor(431) or cursor
            if cursor then reaper.JS_Mouse_SetCursor(cursor) end  
        elseif stretchTOP then
            filename = filename .. "js_Mouse editing - Stretch top.cur"
            cursor = reaper.JS_Mouse_LoadCursorFromFile(filename) or cursor -- The first time that the cursor is loaded in the session will be slow, but afterwards the extension will re-use previously loaded cursor
            if cursor then reaper.JS_Mouse_SetCursor(cursor) end
        else
            filename = filename .. "js_Mouse editing - Stretch bottom.cur"
            cursor = reaper.JS_Mouse_LoadCursorFromFile(filename) or cursor -- The first time that the cursor is loaded in the session will be slow, but afterwards the extension will re-use previously loaded cursor
            if cursor then reaper.JS_Mouse_SetCursor(cursor) end
        end 
    
    else -- modeIsCOMPRESS
    
        --filename = filename .. "js_Mouse editing - Compress.cur"
        --cursor = reaper.JS_Mouse_LoadCursorFromFile(filename) -- The first time that the cursor is loaded in the session will be slow, but afterwards the extension will re-use previously loaded cursor
        --if not cursor then cursor = reaper.JS_Mouse_LoadCursor(533) or cursor end -- If .cur file unavailable, load one of REAPER's own cursors]]
        cursor = reaper.JS_Mouse_LoadCursor(533) or cursor
        if cursor then reaper.JS_Mouse_SetCursor(cursor) end
        
        -- Prepare GDI stuff
        if midiview then
            bitmap = reaper.JS_LICE_CreateBitmap(true, ME_midiviewWidth, ME_midiviewHeight)
            if bitmap then
               if ME_TimeBase == "beats" then
                    Guides_LeftPixel = (tTargets[1].ticks + loopStartPPQPos - ME_LeftmostTick) * ME_PixelsPerTick
                    Guides_RightPixel = (tTargets[#tTargets].ticks + loopStartPPQPos - ME_LeftmostTick)*ME_PixelsPerTick
                else -- ME_TimeBase == "time"
                    local firstTime = reaper.MIDI_GetProjTimeFromPPQPos(activeTake, tTargets[1].ticks + loopStartPPQPos)
                    local lastTime  = reaper.MIDI_GetProjTimeFromPPQPos(activeTake, tTargets[#tTargets].ticks + loopStartPPQPos)
                    Guides_LeftPixel  = (firstTime-ME_LeftmostTime)*ME_PixelsPerSecond
                    Guides_RightPixel = (lastTime -ME_LeftmostTime)*ME_PixelsPerSecond
                end
                Guides_LeftPixel  = math.ceil(math.max(Guides_LeftPixel, 0)) 
                Guides_RightPixel = math.floor(math.min(Guides_RightPixel, ME_midiviewWidth-1)) -- Plus 5 because CC bars are approx 5v pixels wide
                
                -- The line will be calculated at nodes spaced 10 pixels. Get PPQ positions of each node.
                tGuides_Ticks = {}
                tGuides_X = {} -- Pixel positions relative to midiview client area
                if ME_TimeBase == "beats" then
                    for x = Guides_LeftPixel, Guides_RightPixel-1, 2 do
                        tGuides_X[#tGuides_X+1] = x
                        tGuides_Ticks[#tGuides_Ticks+1] = ME_LeftmostTick + x/ME_PixelsPerTick - loopStartPPQPos
                    end
                    tGuides_X[#tGuides_X+1] = Guides_RightPixel -- Make sure the line goes up to last event
                    tGuides_Ticks[#tGuides_Ticks+1] = ME_LeftmostTick + Guides_RightPixel/ME_PixelsPerTick - loopStartPPQPos
                else -- ME_TimeBase == "time"
                    for x = Guides_LeftPixel, Guides_RightPixel-1, 2 do
                        tGuides_X[#tGuides_X+1] =x
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


