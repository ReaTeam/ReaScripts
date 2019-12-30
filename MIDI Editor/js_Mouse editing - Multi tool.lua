--[[
ReaScript name: js_Mouse editing - Multi Tool.lua
Version: 5.12
Author: juliansader
Website: http://forum.cockos.com/showthread.php?t=176878
Donation: https://www.paypal.me/juliansader
Provides: 
  [main=midi_editor] .
  js_Mouse editing - Scale bottom.cur
  js_Mouse editing - Scale top.cur
  js_Mouse editing - Multi compress.cur
  js_Mouse editing - Undo.cur
  js_Mouse editing - Redo.cur
About:
  # DESCRIPTION
  
  A multifunctional script for stretching, scaling, tilting and warping MIDI events.
  
  
  # INSTRUCTIONS
  
  The script is intended to work similar to REAPER's native left-drag mouse modifier functions -- but with more advanced functionality:
  
  First, recall how to run REAPER's native mouse modifier functions: 
  
      * You press the modifiers key(s) and then hold them down while left-clicking or left-dragging the mouse.
      
      * The effect of a mouse modifier function often depends on the starting position of the mouse:
          For example, Alt+left-dragging from the right edge of a note stretches the note, 
          whereas Alt+left-dragging from the inside of a note changes velocity.)
  
  Similarly, to run this script, you press the shortcut key (instead of the modifier key), then click or drag the mouse from specific starting positions.
  
  Beyond these basic similarities, however, this script offers several advanced features:
  
      * The various positions from which the mouse can be clicked or dragged are displayed onscreen as colored zones.
      
      * The scripts' functioning (such as the ramp shape or the channel of inserted CCs) can be tweaked while the script is running, 
        using the mousewheel, mouse middle button and right button.
     
      * Whereas native actions can only be started and stopped by left-dragging and lifting the mouse button,
        the scripts be started and stopped in multiple ways, allowing a more customized and streamlined workflow.
        
      * Multiple editing steps can be performed before terminating the script, and the precise (floating point) positions and values of the events
          are remembered between steps, to avoid rounding errors when rounding to the nearest tick positions or 128-step values ranges. 
          
      * And, of course, the script offers a variety of editing tools such as warping, compressing, stretching and tilting that are not found among REAPER's native actions.
  
  
  LANE UNDER MOUSE:
  
  The script can either affect 1) all selected MIDI events in the MIDI editor's active take, or 2) only the selected MIDI events in lane under the mouse.
  
      * To edit only the selected events in a single lane, the mouse must be positioned inside that lane when the script starts.  
          (After the script has started, the mouse may move out of the starting lane.)
      
      * To edit all selected events together, the mouse must be positioned over a lane divider, or over the ruler -- i.e., outside any lane.
  
  When editing all selected events, only their tick positions can be edited, using the warp, stretch or reverse functions.  
  When editing a single lane, positions as well as values can be edited.  
  
  
  STARTING THE SCRIPT:
  
      * Similar to any action in the Actions list, the script can be assigned a keyboard or mousewheel shortcut.
        (NOTE: To run the script, the shortcut key can either be held down for as long as the script must run, similar to REAPER's native mouse modifier functions,
                or the shortcut key can be clicked once to start the scripts and then once again the terminate the script.) 
        
      * Similar to mouse modifier actions, assign the script to a left-click or double-click mouse modifier in Preferences -> Mouse modifiers.  
               
      * Arming a toolbar button, as described below.
      
  
  ZONES AND FUNCTIONS:
  
  As soon as the shortcut key is pressed, colored zones will light up on screens, indicating the available functions.
  
  Each zone may either be left-click/dragged, mousewheel-triggered, or right-clicked.  The zones and their associated 
      left-button / mousewheel functions are:
  
      * Compress lane from top / Flip values absolute
      * Compress lane from bottom / Flip values absolute
      * Scale values from top / Flip values relative
      * Scale value from bottom / Flip values relative
      * Warp left/right or up/down (depending on initial mouse movement)
      * Stretch from left / Reverse positions
      * Stretch from right / Reverse positions
      * Tilt left side / Snap to chased values on left
      * Tilt right side / Snap to chased values on right
      * Undo
      * Redo
      
  Right-clicking pops up a context menu (which currently only includes color selection).
  
  Note that left-clicking and left-dragging can both be used to run the same functions.
 
  To proceed to next step:  
      * If the mouse was dragged, proceed by lifting the mouse button.  
      * If the mouse button was clicked, proceed by clicking a second time.
      
      
  TWEAKING WHILE RUNNING:
  
  The scripts' functioning can be tweaked while the script is running:
  
      * Middle-clicking switches the curve shape:  
            In the case of compression and tilting, it switches between sine (aka slow start/end) and power (aka linear, slow start, and slow end) curves.
            In the case of warping, it switches between slow start and slow end warp shapes.
    
      * Mousewheel tweaks the steepness of the curves.
    
      * Right-clicking switches between one-sided mode and symmetrical mode in the case of compression and scaling.
      
      * If the Shift key is held down while stretcing, snapping is ignored.  
  
  
  TERMINATE THE SCRIPT: 
  
  To terminate the script:  
      * If the shortcut key was held down, terminate by lifting the key.  
      * If the shortcut key was clicked and released, terminate by pressing any key (excluding some special keys such as Shift).
      * Clicking or mousewheel outside any zone (when the mouse cursor is a cross).
  
        
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
  * v5.01 (2019-12-03)
    + BETA version.
  * v5.05 (2019-12-19)
    + Fixed: Load custom colors.
    + Fixed: Display Undo/Redo boxes on macOS.
    + Fixed: Canceled color selection dialog doesn't change color.
  * v5.10 (2019-12-28)
    + Scale top/bottom zones drawn at level of CC max/min values.
    + Compress bottom zone active behind bottom scroll bar.
  * v5.11 (2019-12-29)
    + A few tweaks.
  * v5.12 (2019-12-30)
    + Fixed: Bug when holding keyboard shortcut.
]]

-- USER AREA 
-- Settings that the user can customize
    
    Guideline_Color_Top    = 0xFF00FF00 -- Format AARRGGBB
    Guideline_Color_Bottom = 0xFF0000FF
    
    
-- End of USER AREA   


-- ################################################################################################
---------------------------------------------------------------------------------------------------
-- CONSTANTS AND VARIABLES (that modders may find useful)

-- The raw MIDI data string will be divided into substrings in tMIDI, which can be concatenated into a new edited MIDI string in each cycle.
local MIDIString -- The original raw MIDI data returned by GetAllEvts
local tMIDI = {}

--[[ CCs in different lanes and different channels must be handled separately.  
    For example, when deleting overlapping CCs, only CCs in the same lane and channel as the selected CCs must be deleted.
        Also, when tilting/snapping to chased values, each channel must be chased individually.
    The CCs events in different lanes and different channels will therefore be separated into distinct tables, which will be stored in tGroups.
        Notes, sysex and text also get separate groups.
    Each group will itself consist of multiple tables, which store the info if the events: tick positions, flags, values, pitch etc:
        tGroups[group] = {tT = {}, tA = {}, tI = {}, tM = {}, tM2 = {}, tV = {}, tT = {}, tC = {}, tF = {}, tF2 = {}, tP = {}, tOff = {}, tQ = {}, tD = {}}
    These are shorthand for these names: 
        tTicks = {}
        tPrevTicks = {}
        tIndices = {}
        tMsg = {} 
        tMsg2 = {} -- Msf of secondary events such as note-offs
        tValues = {} -- CC values, 14bit CC combined values, note velocities
        tTicks = {} 
        tChannels = {} 
        tFlags = {} 
        tFlags2 = {} -- Flags of secondary events such as note-offs in the case of notes, or LSB in the case of 14bit CCs
        tPitches = {} -- This table will only be filled if laneIsNOTES (laneIsVELOCITY, laneIsOFFVEL, or laneIsPIANOROLL)
        tLengths = {} 
        tMeta = {} -- Extra REAPER-specific non-MIDI metadata such as notation or Bezier tension.
]]
local tGroups = {}

-- At each step, tGroups and the global values will be updated into a new entry in tSteps:
-- NOTE:  Not all tables will be copied entry-by-entry at each step.  Tables that remain unchanged will simply be aliases for the corresponding tables in the previous step.
local tSteps = {} -- At each step, tSteps will store a new tValues, tTicks 
  
-- If the curve is being auditioned in real time, must be sorted, since unsorted events with negative offset may not play back properly.
local isRealtimeAudition = ((reaper.GetPlayStateEx(0)&5) ~= 0)

-- The original value and PPQ ranges of selected events in the target lane will be summarized in:
local origValueMin, origValueMax, origValueRange, origValueLeftmost, origValueRightmost = nil, nil, nil, nil, nil
local origTickLeftmost, origTickRightmost, origNoteOffTick, origTickRange = nil, nil, nil, nil
local includeNoteOffsInPPQRange = true
 
-- Starting values and position of mouse 
-- Not all of these lanes will be used by all scripts.
-- mouseOrigCCLane: (CC0-127 = 7-bit CC, 0x100|(0-31) = 14-bit CC, 0x200 = velocity, 0x201 = pitch, 
--    0x202=program, 0x203=channel pressure, 0x204=bank/program select, 
--    0x205=text, 0x206=sysex, 0x207=off velocity)
local mouseOrigX, mouseOrigY = nil, nil
local laneMinValue, laneMaxValue = nil, nil -- The minimum and maximum values in the target lane
local mouseOrigCCLane, mouseOrigCCValue, mouseOrigPPQPos, mouseOrigPitch, mouseOrigCCLaneID = nil, nil, nil, nil, nil

-- Some day, this script is intended to work in inline MIDI editors as well as the main MIDI editors
-- The two types of editors require some different code, though.  
-- In particular, if in an inline editor, functions from the SWS extension will be used to track mouse position.
-- In the main editor, WIN32/SWELL functions from the js_ReaScriptAPI extension will be used.
local isInline, editor = nil, nil

-- Tracking the new value and position of the mouse while the script is running
local mouseNewCCLane, mouseNewCCValue, mouseNewPPQPos, mouseNewPitch, mouseNewCCLaneID = nil, nil, nil, nil, nil
local prevMouseX, prevMouseY, mouseX, mouseY
local prevMouseTick, mouseTick

-- The script can be controlled by mousewheel, mouse buttons an mouse modifiers.  These are tracked by the following variables.
local mouseState
local mousewheel = 1 -- Track mousewheel movement.  ***** This default value may change, depending on the script and formulae used. *****
local prevDelta = 0
local prevMouseTime = 0

-- The script will intercept keystrokes, to allow control of script via keyboard, 
--    and to prevent inadvertently running other actions such as closing MIDI editor by pressing ESC
local VKLow, VKHi = 0x13, 0xFE --9, 0xA5 -- Range of virtual key codes to check for key presses: Skip mouse modifiers
local keyState0 = string.rep("\0", VKHi-VKLow+1) -- String representing no keys held, for easy comparison with running keyState
local dragTime = 0.35 -- To distinguish clicks and drags, how long must mouse or shortcut key be held down before drag is activated?

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
local ME_TargetTopPixel, ME_TargetBottomPixel = nil, nil
local ME_TimeBase = nil
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
local tp = reaper.time_precise

-- Window messages that will be intercepted while the script is running
local tWM_Messages = {WM_LBUTTONDOWN = false, WM_LBUTTONDBLCLK = false, WM_LBUTTONUP = false,
                      WM_MBUTTONDOWN = false, WM_MBUTTONDBLCLK = false, WM_MBUTTONUP = false,
                      WM_RBUTTONDOWN = false, WM_RBUTTONDBLCLK = false, WM_RBUTTONUP = false,
                      WM_NCMOUSEMOVE = false, -- This intercept allows the mouse to go into the bottom scroll area (i.e. outside midiview's client area) without REAPER noticing it and changing the mouse cursor.
                      WM_NCLBUTTONDOWN = false, WM_NCLBUTTONDBLCLK = false, -- Prevent clicking on scrollbar
                      WM_MOUSEWHEEL  = false, WM_MOUSEHWHEEL   = false,
                      WM_SETCURSOR   = false}                 
  

-- Guideline GUI stuff:
local leftPPQrange, rightPPQrange
local Guides_LeftPixel, Guides_RightPixel, Guides_XStr, Guides_YStr_Top, Guides_YStr_Bottom = nil, nil, nil, nil, nil, nil, nil, nil
local tGuides_Ticks, tGuides_X = {}, {} -- Guide lines will be drawn between nodes spaced every 10 pixels. What are the tick positions of these pixels?
local Guides_COLOR_TOP    = tonumber(Guideline_Color_Top) or 0xFF00FF00 -- Format AARRGGBB
local Guides_COLOR_BOTTOM = tonumber(Guideline_Color_Bottom) or 0xFF0000FF

-- Zone GUI stuff
local tZones = {}
local zone = nil
local prevZone = nil
local tColors = nil
local zoneWidth = (gfx.ext_retina == 2) and 40 or 20 -- I'm nont sure if gfx.ext_retina actually works if no script GUI is created

local OS, macOS, winOS        

--##################################
------------------------------------
local function GetMouseTick(trySnap)
    local snappedNewTick
    
    -- MOUSE NEW TICK / PPQ VALUE (horizontal position)
    -- Snapping not relevant to this script
    if isInline then
        -- A call to BR_GetMouseCursorContext must always precede the other BR_ context calls
        mouseNewPPQPos = reaper.MIDI_GetPPQPosFromProjTime(activeTake, reaper.BR_GetMouseCursorContext_Position())
    else
        if not mouseX then 
            local x, y = reaper.GetMousePosition()
            local mouseX = reaper.JS_Window_ScreenToClient(midiview, x, y)
        end
        if ME_TimeBase == "beats" then
            mouseNewPPQPos = ME_LeftmostTick + mouseX/ME_PixelsPerTick
        else -- ME_TimeBase == "time"
            mouseNewPPQPos = reaper.MIDI_GetPPQPosFromProjTime(activeTake, ME_LeftmostTime + mouseX/ME_PixelsPerSecond )
        end
    end
    mouseNewPPQPos = mouseNewPPQPos - loopStartPPQPos -- Adjust mouse PPQ position for looped items
    
    -- Adjust mouse PPQ position for snapping
    if not trySnap or not isSnapEnabled or (mouseState and mouseState&8 == 8) then -- While shift is held down, don't snap
        snappedNewTick = m_floor(mouseNewPPQPos+0.5) 
    elseif isInline then
        local timePos = reaper.MIDI_GetProjTimeFromPPQPos(activeTake, mouseNewPPQPos)
        local snappedTimePos = reaper.SnapToGrid(0, timePos) -- If snap-to-grid is not enabled, will return timePos unchanged
        snappedNewTick = m_floor(reaper.MIDI_GetPPQPosFromProjTime(activeTake, snappedTimePos) + 0.5)
    else
        local mouseQNpos = reaper.MIDI_GetProjQNFromPPQPos(activeTake, mouseNewPPQPos) -- Mouse position in quarter notes
        local roundedGridQN = math.floor((mouseQNpos/QNperGrid)+0.5)*QNperGrid -- nearest grid to mouse position
        snappedNewTick = m_floor(reaper.MIDI_GetPPQPosFromProjQN(activeTake, roundedGridQN) + 0.5)
    end
    snappedNewTick = math.max(minimumTick, math.min(maximumTick, snappedNewTick))
    
    return snappedNewTick
end


--#################################
-----------------------------------
function GetMouseValue(limitInside)
    local mouseNewCCValue
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
        if not mouseY then 
            local x, y = reaper.GetMousePosition()
            local _, mouseY = reaper.JS_Window_ScreenToClient(midiview, x, y)
        end
        mouseNewCCValue = laneMinValue + (laneMaxValue-laneMinValue) * (tME_Lanes[mouseOrigCCLaneID].ME_BottomPixel - mouseY) / (tME_Lanes[mouseOrigCCLaneID].ME_BottomPixel - tME_Lanes[mouseOrigCCLaneID].ME_TopPixel)
        if limitInside then
            -- May the mouse CC value go beyond lane limits?
            if mouseNewCCValue > laneMaxValue then mouseNewCCValue = laneMaxValue
            elseif mouseNewCCValue < laneMinValue then mouseNewCCValue = laneMinValue
            else mouseNewCCValue = (mouseNewCCValue+0.5)//1
            end
        end
    end
    return mouseNewCCValue
end


--#########################
---------------------------
function GetMinMaxValues(tableGroups)
    local min, max = math.huge, -math.huge
    local tMin, tMax
    for group, tables in pairs(tableGroups) do
        local tV = tables.tV
        for i = 1, #tV do
            if tV[i] > max then max = tV[i] tMax = {id = group, i = i} end
            if tV[i] < min then min = tV[i] tMin = {id = group, i = i} end
        end
    end
    return min, max, tMin, tMax
end


local stepDragTimeStarted = nil
--######################################
----------------------------------------
function Check_MouseLeftButtonSinceLastDefer()
    if continueStep ~= "CONTINUE" then
        mouseStateAtStepDragTime = nil
    elseif not mouseStateAtStepDragTime then
        mouseStateAtStepDragTime = (thisDeferTime > stepStartTime + dragTime) and mouseState
    elseif (mouseState&1) < (mouseStateAtStepDragTime&1) then
        return true
    end

        --[[
                if (mouseState&1) < (mouseStateAtStepDragTime&1) then
                    return true
                end
            end
        -- LEFT MOUSE BUTTON: 
        -- Terminate this step (but not entire script) if left button is released after dragTime has passed
        if mouseStateAtStepDragTime then
            if (thisDeferTime > stepStartTime + dragTime) then 
                if (mouseState&1) < (mouseStateAtStepDragTime&1) then
                    return true
                end
            else
                mouseStateAtStepDragTime = mouseStateAtStepDragTime & mouseState
            end
        end
        if (mouseState&1) > (mouseStateAtStepDragTime&1) then return true end
        ]]
        -- Terminate if left button is clicked
    local peekOK, pass, time = reaper.JS_WindowMessage_Peek(windowUnderMouse, "WM_LBUTTONDOWN")
    if peekOK and time > stepStartTime + 0.1 then 
        return true 
    end
    peekOK, pass, time = reaper.JS_WindowMessage_Peek(windowUnderMouse, "WM_NCLBUTTONDOWN")
    if peekOK and time > stepStartTime + 0.1 then 
        return true 
    end
end
    
   
local stretchFactor = 1
--###########################
-----------------------------
function Defer_Stretch_Left()
  
    -- Setup stuff when this function 
    if not (continueStep == "CONTINUE") then
        stepStartTime = thisDeferTime
        mouseStateAtStepDragTime = mouseState
        stretchFactor = 1
        -- Construct new tStep by copying previous - except those tables/values that will be newly contructed
        local old = tSteps[#tSteps]
        local new = {tGroups = {}, isChangingPositions = true}
        tSteps[#tSteps+1] = new
        for k, e in pairs(old) do
            if not new[k] then new[k] = e end
        end
        for id, t in pairs(old.tGroups) do
            new.tGroups[id] = (id == "notes") and {tT = {}, tOff = {}} or {tT = {}}
            for a, b in pairs(t) do
                if not new.tGroups[id][a] then new.tGroups[id][a] = b end
            end
        end
        mustCalculate = true -- Always start step with re-calculation        
    end
    
    local prevMouseTick = mouseTick 
    mouseTick = GetMouseTick("SNAPPED") -- Don't snap if shift is pressed
    if mouseTick ~= prevMouseTick then
        mustCalculate = true
    end
    
    if mustCalculate then
        local new, old = tSteps[#tSteps], tSteps[#tSteps-1]
        local oldNoteOffTick = old.globalNoteOffTick
        local prevStretchFactor = stretchFactor
        stretchFactor = (oldNoteOffTick - mouseTick) / (oldNoteOffTick - old.globalLeftTick)
        if stretchFactor == 0 then stretchFactor = prevStretchFactor or 1 end -- Avoid zero-length notes or CCs on top of each other in same channel
        local noteFactor = (stretchFactor > 0) and stretchFactor or -stretchFactor        
        
        for id, t in pairs(new.tGroups) do
            local nT, oT = t.tT, old.tGroups[id].tT
            for i = 1, #oT do
                nT[i] = oldNoteOffTick - stretchFactor*(oldNoteOffTick - oT[i])
            end
            if id == "notes" then
                local nO, oO = t.tOff, old.tGroups[id].tOff
                for i = 1, #oO do
                    nO[i] = oldNoteOffTick - stretchFactor*(oldNoteOffTick - oO[i])
                end
                if stretchFactor < 0 then t.tT, t.tOff = t.tOff, t.tT end
            end
        end
        
        CONSTRUCT_MIDI_STRING()
    end
   
    -- GO TO NEXT STEP?
    if Check_MouseLeftButtonSinceLastDefer() then 
        if stretchFactor < 0 then
            GetAllEdgeValues(tSteps[#tSteps])
        else
            local new, old = tSteps[#tSteps], tSteps[#tSteps-1]
            new.globalLeftTick = old.globalNoteOffTick - stretchFactor*(old.globalNoteOffTick - old.globalLeftTick)
        end
        return "NEXT"
    else
        return "CONTINUE"
    end
end


--############################
------------------------------
function Defer_Stretch_Right()
  
    -- Setup stuff when this function 
    if not (continueStep == "CONTINUE") then
        stepStartTime = thisDeferTime
        mouseStateAtStepDragTime = mouseState
        stretchFactor = 1
        -- Construct new tStep by copying previous - except those tables/values that will be newly contructed
        local old = tSteps[#tSteps]
        local new = {tGroups = {}, isChangingPositions = true}
        tSteps[#tSteps+1] = new
        for k, e in pairs(old) do
            if not new[k] then new[k] = e end
        end
        for id, t in pairs(old.tGroups) do
            new.tGroups[id] = (id == "notes") and {tT = {}, tOff = {}} or {tT = {}}
            for a, b in pairs(t) do
                if not new.tGroups[id][a] then new.tGroups[id][a] = b end
            end
        end
        mustCalculate = true -- Always start step with re-calculation        
    end
    
    local prevMouseTick = mouseTick 
    mouseTick = GetMouseTick("SNAPPED")
    if mouseTick ~= prevMouseTick then
        mustCalculate = true
    end
    
    if mustCalculate then
        local new, old    = tSteps[#tSteps], tSteps[#tSteps-1]
        local oldLeftTick = old.globalLeftTick
        local prevStretchFactor = stretchFactor
        stretchFactor = (mouseTick - oldLeftTick) / (old.globalNoteOffTick - oldLeftTick)
        if stretchFactor == 0 then stretchFactor = prevStretchFactor or 1 end -- Avoid zero-length notes or CCs on top of each other in same channel
        local noteFactor = (stretchFactor > 0) and stretchFactor or -stretchFactor        
        
        for id, t in pairs(new.tGroups) do
            local nT, nL, oT, oL = t.tT, t.tOff, old.tGroups[id].tT, old.tGroups[id].tOff
            for i = 1, #oT do
                nT[i] = oldLeftTick + stretchFactor*(oT[i]-oldLeftTick)
            end
            if id == "notes" then
                local nO, oO = t.tOff, old.tGroups[id].tOff
                for i = 1, #oO do
                    nO[i] = oldLeftTick + stretchFactor*(oO[i]-oldLeftTick)
                end
                if stretchFactor < 0 then t.tT, t.tOff = t.tOff, t.tT end
            end
        end
        
        CONSTRUCT_MIDI_STRING()
    end
    
    -- GO TO NEXT STEP?
    if Check_MouseLeftButtonSinceLastDefer() then 
        if stretchFactor < 0 then
            GetAllEdgeValues(tSteps[#tSteps])
        else
            local new, old = tSteps[#tSteps], tSteps[#tSteps-1]
            new.globalLeftTick    = old.globalLeftTick
            new.globalRightTick   = old.globalLeftTick + stretchFactor*(old.globalRightTick - old.globalLeftTick)
            new.globalNoteOffTick = old.globalLeftTick + stretchFactor*(old.globalNoteOffTick - old.globalLeftTick)
        end
        return "NEXT"
    else
        return "CONTINUE"
    end
end


 warpLEFTRIGHT, warpUPDOWN, canWarpBothDirections, mouseStartTick = false, false, nil, nil
local mouseMovementResolution, warpCurve = 5, 1
local hasConstructedNewWarpStep = false
--#################################
-----------------------------------
function Defer_Warp()

    -- First time this function runs in this step:
    if not (continueStep == "CONTINUE") then
        reaper.JS_LICE_Clear(bitmap, 0)
        stepStartTime = thisDeferTime
        mouseStateAtStepDragTime = mouseState
        hasConstructedNewWarpStep = false
        mouseStartTick = GetMouseTick()

        -- DIRECTION: Determine the direction of warping.
        -- Notes, sysex and text can only be warped left/right
        -- (To warp note pitches, use the built-in Arpeggiate mouse modifiers)
        -- For other lanes, warp direction depends on mouse movement, similar
        --    to the "move in one direction only" mouse modifiers.
        if laneIsALL or laneIsPIANOROLL or laneIsSYSEX or laneIsTEXT or laneIsBANKPROG 
        or (tSteps[#tSteps].globalMaxValue == tSteps[#tSteps].globalMinValue)
        then
            warpLEFTRIGHT, warpUPDOWN = true, false
            canWarpBothDirections = false
        else 
            canWarpBothDirections = true
            warpLEFTRIGHT, warpUPDOWN = false, false
            reaper.JS_Window_InvalidateRect(midiview, 0, 0, 1, 1, false)
            if Check_MouseLeftButtonSinceLastDefer() then return "NEXT" else return "CONTINUE" end
            return "CONTINUE"
        end
    end
    
    -- Second time this function runs in current step:
    if not (warpLEFTRIGHT or warpUPDOWN) then

        local mouseXmove, mouseYmove, timeWaited = 0, 0, 0
        repeat
            local x, y = reaper.GetMousePosition()
            x, y = reaper.JS_Window_ScreenToClient(midiview, x, y)
            mouseXmove = math.abs(x - mouseX)
            mouseYmove = math.abs(y - mouseY)
            timeWaited = reaper.time_precise() - stepStartTime 
        until timeWaited > 3 or ((mouseXmove > mouseMovementResolution or mouseYmove > mouseMovementResolution) and mouseXmove ~= mouseYmove)
        if timeWaited > 3 then
            return "NEXT"
        elseif mouseXmove > mouseYmove then 
            warpLEFTRIGHT, warpUPDOWN = true, false 
        else 
            warpLEFTRIGHT, warpUPDOWN = false, true
        end
    end
    
    if not hasConstructedNewWarpStep then
        -- If warpLEFTRIGHT, the event under the mouse should follow mouse X position exactly, so get relative position.
        if warpLEFTRIGHT then
            mouseStartFraction = (mouseStartTick-tSteps[#tSteps].globalLeftTick) / (tSteps[#tSteps].globalNoteOffTick - tSteps[#tSteps].globalLeftTick)   
        else -- warpUPDOWN
            mouseStartCCValue = GetMouseValue()
            mouseStartY = mouseY
            -- CURSOR: Defer_Zones has already set the cursor to left/right 
            cursor = reaper.JS_Mouse_LoadCursor(503) -- REAPER's own arpeggiate up/down cursor
            if cursor then reaper.JS_Mouse_SetCursor(cursor) end
        end
        
        -- CONSTRUCT NEW STEP: by copying previous - except those tables/values that will be newly contructed
        local old = tSteps[#tSteps]
        local new = {tGroups = {}, isChangingPositions = warpLEFTRIGHT}
        tSteps[#tSteps+1] = new
        for k, e in pairs(old) do
            if not new[k] then new[k] = e end
        end
        for id, t in pairs(old.tGroups) do
            if warpUPDOWN then new.tGroups[id] = {tV = {}}
            else               new.tGroups[id] = {tT = {}, tOff = {}}
            end
            for a, b in pairs(t) do
                if not new.tGroups[id][a] then new.tGroups[id][a] = b end
            end
        end
        
        hasConstructedNewWarpStep = true
        mustCalculate = true -- Always start step with re-calculation 
    end -- if not (continueStep == "CONTINUE") ... elseif not (warpLEFTRIGHT or warpUPDOWN)
    
    -- MIDDLE BUTTON: (Middle button changes curve shape.)
    peekOK, pass, time = reaper.JS_WindowMessage_Peek(windowUnderMouse, "WM_MBUTTONDOWN")
    if peekOK and time > prevMouseTime then 
        warpCurve = (warpCurve == 1) and 0 or 1
        prevMouseTime = time
        mustCalculate = true
    end
 
    -- MOUSE MOVEMENT:
    if warpLEFTRIGHT then
        prevMouseTick = mouseTick
        mouseTick = GetMouseTick()
        if mouseTick ~= prevMouseTick then mustCalculate = true end
    else
        if mouseY ~= prevMouseY then mustCalculate = true end
    end
    
    
    -- CALCULATE MIDI STUFF!
    
    -- Scripts that extract selected MIDI events and re-concatenate them out of order (usually at the beginning of the MIDI string, for easier editing)
    --    cannot be auditioned in real-time while events are out of order, since such events are not played.
    -- If the mouse is held still, no editing is done, and instead the take is sorted, thereby temporarily allowing playback.
    -- NO NEED TO CALCULATE:
    if mustCalculate then 

        -- CALCULATE NEW MIDI DATA! and write the tWarpMIDI!
        -- The warping uses a power function, and the power variable is determined
        --     by calculating to what power 0.5 must be raised to reach the 
        --     mouse's deviation to the left or right from its starting PPQ position. 
        -- The reason why 0.5 was chosen, was so that the CC in the middle of the range
        --     would follow the mouse position.
        -- The PPQ range of the selected events is used as reference to calculate
        --     magnitude of mouse movement.
        
        local newValue, power, mouseRelativeMovement
        if warpUPDOWN or warpBOTH then
        
            local mouseRelativeMovement = (mouseStartY-mouseY) / (ME_TargetBottomPixel-ME_TargetTopPixel) --ME_TargetGetMouseValue()-mouseStartCCValue)/(laneMaxValue-laneMinValue) -- Positive if moved to right, negative if moved to left
            -- Prevent warping too much, so that all CCs don't end up in a solid block
            if mouseRelativeMovement > 0.99 then mouseRelativeMovement = 0.99 elseif mouseRelativeMovement < -0.99 then mouseRelativeMovement = -0.99 end
            if warpCurve == 1 then
                power = math.log(0.5 + mouseRelativeMovement/2, 0.5)
            else
                power = math.log(0.5 - mouseRelativeMovement/2, 0.5)
            end
            
            local min, max = tSteps[#tSteps-1].globalMinValue, tSteps[#tSteps-1].globalMaxValue
            local range = max-min
            if range == 0 or mouseMovement == 0 then
                for grp, t in pairs(tSteps[#tSteps-1].tGroups) do  
                    local tV, tOldV = tSteps[#tSteps].tGroups[grp].tV, t.tV
                    for i = 1, #tOldV do  
                        tV[i] = tOldV[i]
                    end
                end
            else
                local newValue
                for grp, t in pairs(tSteps[#tSteps-1].tGroups) do  
                    local tV, tOldV = tSteps[#tSteps].tGroups[grp].tV, t.tV
                    for i = 1, #tOldV do                             
                        if warpCurve == 1 then 
                            newValue = min + (((tOldV[i] - min)/range)^power)*range          
                        else -- mouseMovement > 0
                            newValue = max - (((max - tOldV[i])/range)^power)*range           
                        end
                        if     newValue > laneMaxValue then tV[i] = laneMaxValue
                        elseif newValue < laneMinValue then tV[i] = laneMinValue
                        else tV[i] = newValue
                        end       
                    end
                end
            end
            
        else -- warpLEFTRIGHT or warpBOTH then  
        
            local left, right = tSteps[#tSteps].globalLeftTick, tSteps[#tSteps].globalNoteOffTick
            local range = right - left
            local mouseFraction = (mouseTick-left)/range
            if mouseFraction > 0.95 then mouseFraction = 0.95 elseif mouseFraction < 0.05 then mouseFraction = 0.05 end
            local power = (warpCurve == 1) and (math.log(mouseFraction, mouseStartFraction)) or (math.log(1-mouseFraction, 1-mouseStartFraction))
            if range == 0 or power == 1 then -- just copy, if no warp
                for grp, t in pairs(tSteps[#tSteps-1].tGroups) do  
                    local tT, tOldT, tOff, tOldL = tSteps[#tSteps].tGroups[grp].tT, t.tT, tSteps[#tSteps].tGroups[grp].tOff, t.tOff
                    for i = 1, #tOldT do  
                        tT[i] = tOldT[i]
                        tOff[i] = tOldL[i]
                    end
                end
            else
                for grp, t in pairs(tSteps[#tSteps-1].tGroups) do  
                    local tT, tOldT = tSteps[#tSteps].tGroups[grp].tT, t.tT
                    for i = 1, #tOldT do                             
                        if warpCurve == 1 then
                            tT[i] = left + (((tOldT[i] - left)/range)^power)*range
                        else
                            tT[i] = right - (((right - tOldT[i])/range)^power)*range
                        end    
                    end
                    if grp == "notes" then
                        local tOff, tOldO = tSteps[#tSteps].tGroups[grp].tOff, t.tOff
                        for i = 1, #tOldO do                             
                            if warpCurve == 1 then
                                tOff[i] = left + (((tOldO[i] - left)/range)^power)*range
                            else
                                tOff[i] = right - (((right - tOldO[i])/range)^power)*range
                            end    
                        end
                    end
                end
            end
        end
      
        CONSTRUCT_MIDI_STRING()
        
    end -- mustCalculate stuff


    -- GO TO NEXT STEP?
    if Check_MouseLeftButtonSinceLastDefer() then
        if warpUPDOWN then
            GetAllEdgeValues(tSteps[#tSteps])
        end
        return "NEXT"
    else
        return "CONTINUE"
    end
    
end -- Defer_Warp


local scaleTOP, scaleBOTTOM, scaleSYMMETRIC = nil, nil, false
--####################
----------------------
function Defer_Scale()

    -- Setup stuff when this function 
    if not (continueStep == "CONTINUE") then
        stepStartTime = thisDeferTime
        mouseStateAtStepDragTime = mouseState
        
        -- If mouse is close to CC height, move mouse to precisely CC height
        local pixelY
        if zone.cursor == cursorHandTop then
            scaleTOP, scaleBOTTOM = true, false
            pixelY = (ME_TargetBottomPixel - (ME_TargetBottomPixel-ME_TargetTopPixel)*(tSteps[#tSteps].globalMaxValue-laneMinValue)/(laneMaxValue-laneMinValue))//1      
        else
            scaleTOP, scaleBOTTOM = false, true
            pixelY = (ME_TargetBottomPixel - (ME_TargetBottomPixel-ME_TargetTopPixel)*(tSteps[#tSteps].globalMinValue-laneMinValue)/(laneMaxValue-laneMinValue))//1
        end
        if -zoneWidth < (pixelY-mouseY) and (pixelY-mouseY) < zoneWidth then
            mouseY = pixelY
            reaper.JS_Mouse_SetPosition(reaper.JS_Window_ClientToScreen(midiview, mouseX, mouseY))
        end

        -- Construct new tStep by copying previous - except those tables/values that will be newly contructed
        local old = tSteps[#tSteps]
        local new = {tGroups = {}, isChangingPositions = false}
        tSteps[#tSteps+1] = new
        for k, e in pairs(old) do
            if not new[k] then new[k] = e end
        end
        for id, t in pairs(old.tGroups) do
            new.tGroups[id] = {tV = {}}
            for a, b in pairs(t) do
                if not new.tGroups[id][a] then new.tGroups[id][a] = b end
            end
        end
        SetupGuidelineTables() -- Can only get left/right pixels and set up tables *after* constructing new step's table
        mustCalculate = true -- Always start step with re-calculation 
    end        
    
    -- RIGHT CLICK: Right click changes script mode
    --    * If script is terminated by right button, disarm toolbar.
    --    * REAPER shows context menu when right button is *lifted*, so must continue intercepting mouse messages until right button is lifted.
    local peekOK, pass, time = reaper.JS_WindowMessage_Peek(windowUnderMouse, "WM_RBUTTONDOWN")
    if peekOK and time > prevDeferTime then
        scaleSYMMETRIC = not scaleSYMMETRIC
        prevMouseTime = time
        mustCalculate = true
    end
    
    -- MOUSE MOVEMENT:
    if mouseY ~= prevMouseY then mustCalculate = true end
    
    ---------------------
    if mustCalculate then
    
        local newRangeMin, newRangeMax
        local new, old = tSteps[#tSteps], tSteps[#tSteps-1]
        local oldMinValue, oldMaxValue = old.globalMinValue, old.globalMaxValue
        if oldMinValue == oldMaxValue then
            newRangeMax = GetMouseValue("LIMIT")
            newRangeMin = newRangeMax
            for id, t in pairs(new.tGroups) do
                local tV, tOldV = t.tV, old.tGroups[id].tV
                for i = 1, #tOldV do
                    tV[i] = newRangeMax
                end
            end
        else
            if scaleTOP then
                newRangeMax = GetMouseValue("LIMIT")
                if scaleSYMMETRIC then
                    newRangeMin = old.globalMinValue-(newRangeMax-oldMaxValue)
                    if newRangeMin < laneMinValue then
                        newRangeMax = newRangeMax - (laneMinValue-newRangeMin)
                        newRangeMin = laneMinValue
                    elseif newRangeMin > laneMaxValue then
                        newRangeMax = newRangeMax + (newRangeMin-laneMaxValue)
                        newRangeMin = laneMaxValue
                    end
                else
                    newRangeMin = oldMinValue
                end
            else -- scaleBOTTOM
                newRangeMin = GetMouseValue("LIMIT")
                if scaleSYMMETRIC then
                    newRangeMax = old.globalMaxValue-(newRangeMin-oldMinValue)
                    if newRangeMax < laneMinValue then
                        newRangeMin = newRangeMin - (laneMinValue-newRangeMax)
                        newRangeMax = laneMinValue
                    elseif newRangeMax > laneMaxValue then
                        newRangeMin = newRangeMin + (newRangeMax-laneMaxValue)
                        newRangeMax = laneMaxValue
                    end
                else
                    newRangeMax = oldMaxValue
                end
            end
        
            local stretchFactor = (newRangeMax - newRangeMin)/(oldMaxValue-oldMinValue)
                
            for id, t in pairs(new.tGroups) do
                local tV, tOldV = t.tV, old.tGroups[id].tV
                for i = 1, #tOldV do
                    tV[i] = newRangeMin + stretchFactor*(tOldV[i] - oldMinValue)
                end
            end
        end
        
        -- Draw LICE line
        local bottomLineY = ME_TargetBottomPixel - (ME_TargetBottomPixel-ME_TargetTopPixel)*(newRangeMin-laneMinValue)/(laneMaxValue-laneMinValue)
        local topLineY = ME_TargetBottomPixel - (ME_TargetBottomPixel-ME_TargetTopPixel)*(newRangeMax-laneMinValue)/(laneMaxValue-laneMinValue)
        reaper.JS_LICE_Clear(bitmap, 0)
        reaper.JS_LICE_Line(bitmap, Guides_LeftPixel, topLineY, Guides_RightPixel, topLineY, Guideline_Color_Top, 1, "COPY", true)
        reaper.JS_LICE_Line(bitmap, Guides_LeftPixel, bottomLineY, Guides_RightPixel, bottomLineY, Guideline_Color_Bottom, 1, "COPY", true)
    
        CONSTRUCT_MIDI_STRING()
    end

    -- GO TO NEXT STEP?
    if Check_MouseLeftButtonSinceLastDefer() then
        GetAllEdgeValues(tSteps[#tSteps])
        return "NEXT"
    else
        return "CONTINUE"
    end
    
end -- Defer_Scale


--#######################
-------------------------
-- Default colors:
local DARKRED, RED, GREEN, BLUE, PURPLE, TURQOISE, YELLOW, ORANGE, BLACK = 0xFFAA2200, 0xFFFF0000, 0xFF00BB00, 0xFF0000FF, 0xFFFF00FF, 0xFF00FFFF, 0xFFFFFF00, 0xFFFF8800, 0xFF000000
function LoadZoneColors()
    
    local extState = reaper.GetExtState("js_Multi Tool", "Settings") or ""
    local colorCompress, colorScale, colorStretch, colorTilt, colorWarp, colorUndo, colorRedo = extState:match("compress.-(%d+) scale.-(%d+) stretch.-(%d+) tilt.-(%d+) warp.-(%d+) undo.-(%d+) redo.-(%d+)")
    tColors = {compress = (colorCompress  and tonumber(colorCompress) or YELLOW),
               scale    = (colorScale     and tonumber(colorScale)    or ORANGE),
               stretch  = (colorStretch   and tonumber(colorStretch)  or DARKRED),
               tilt     = (colorTilt      and tonumber(colorTilt)     or PURPLE),
               warp     = (colorWarp      and tonumber(colorWarp)     or GREEN),
               undo     = (colorUndo      and tonumber(colorUndo)     or RED),
               redo     = (colorRedo      and tonumber(colorRedo)     or GREEN),
               black    = BLACK
              }
    --[[
    for k, e in pairs(tColors) do
        reaper.ShowConsoleMsg("\n"..k..": "..string.format("0x%x", e))
    end
    ]]
end


--########################
--------------------------
function ChooseZoneColor()
    if zone and zone.color then
        local x, y = reaper.GetMousePosition()
        ok, c = reaper.GR_SelectColor(windowUnderMouse)
        reaper.JS_Mouse_SetPosition(x, y)
        if editor and reaper.MIDIEditor_GetMode(editor) ~= -1 then reaper.JS_Window_SetForeground(editor) end
        if midiview and reaper.ValidatePtr(midiview, "HWND") then reaper.JS_Window_SetFocus(midiview) end
        
        --reaper.ShowConsoleMsg(tostring(ok) .. " " .. string.format("%x", c))
        if ok == 1 and type(c) == "number" then 
            if winOS then c = 0xFF000000 | ((c&0xff)<<16) | (c&0xff00) | ((c&0xff0000)>>16)
            else c = (c | 0xFF000000) & 0xFFFFFFFF -- Make sure that basic color is completely opaque
            end
            tColors[zone.color] = c
            local extState = "compress="..string.format("%i", tColors.compress)
                            .." scale="..string.format("%i", tColors.scale)
                            .." stretch="..string.format("%i", tColors.stretch)
                            .." tilt="..string.format("%i", tColors.tilt)
                            .." warp="..string.format("%i", tColors.warp)
                            .." undo="..string.format("%i", tColors.undo)
                            .." redo="..string.format("%i", tColors.redo)
            reaper.SetExtState("js_Multi Tool", "Settings", extState, true)
            SetupDisplayZones()
        end
    else
        reaper.MB("No zone found under mouse", "ERROR", 0)
    end
end

    
--####################
----------------------
-- Eventually, this function can include all kinds of settings. But for now, only color.
function ContextMenu()
    ChooseZoneColor()
    return "NEXT"
end


local tRedo = {}
--###################
---------------------
function Defer_Redo()
    if #tRedo > 0 then 
        tSteps[#tSteps+1] = tRedo[#tRedo]
        tRedo[#tRedo] = nil
    end
    CONSTRUCT_MIDI_STRING()
    return "NEXT"
end


--###################
---------------------
function Defer_Undo()
    if #tSteps > 0 then 
        -- If the last step has changed positions (thereby deleting all overlapped CCs), but none 
        --    of the steps before that have changed positions, all deleted CCs must be reset.
        if tSteps[#tSteps].isChangingPositions and not tSteps[#tSteps-1].isChangingPositions then
            for i = 1, #tSteps-2 do
                if tSteps[i].isChangingPositions then tSteps[#tSteps-1].isChangingPositions = true break end
            end
            if not tSteps[#tSteps-1].isChangingPositions then
                for id, t in pairs(tSteps[#tSteps-1].tGroups) do
                    for i = 1, #t.tD do
                        tMIDI[t.tD[i].index] = t.tD[i].flagsMsg
                    end
                end
            end
        end
        
        tRedo[#tRedo+1] = tSteps[#tSteps]
        tSteps[#tSteps] = nil
        --if tSteps[#tSteps].isChangingPositions then tSteps[#tSteps-1].isChangingPositions = true end
    end
    CONSTRUCT_MIDI_STRING()
    return "NEXT"
end


--###########################
-----------------------------
function Edit_ChaseRight()
    local old = tSteps[#tSteps]
    local new = {tGroups = {}, isChangingPositions = false}
    tSteps[#tSteps+1] = new
    for k, e in pairs(old) do
        if not new[k] then new[k] = e end
    end
    
    for id, t in pairs(old.tGroups) do
    
        -- Get edge ticks and values
        local prevLeft, prevRight, prevLeftVal, prevRightVal = t.tT[1], t.tT[#t.tT], t.tV[1], t.tV[#t.tV]
        local origLeft, origRight = tSteps[0].tGroups[id].tT[1], tSteps[0].tGroups[id].tT[#t.tT] -- step 0 was sorted
        if prevLeft > prevRight then prevLeft, prevRight, prevLeftVal, prevRightVal = prevRight, prevLeft, prevRightVal, prevLeftVal end
        local left  = (origLeft < prevLeft)   and origLeft or prevLeft
        local right = (origRight > prevRight) and origRight or prevRight
        
        local tC = t.tChase
        -- If there is nothing to chase, simpy copy previous step's values
        if not tC or #tC == 0 or tC[#tC].ticks <= right or prevLeft == prevRight then
            new.tGroups[id] = {tV = t.tV}
        -- Otherwise, do binary search to quickly find closest event
        else
            new.tGroups[id] = {tV = {}}
            local targetValue
            if tC[1].ticks > right then
                targetValue = tC[1].value
            else
                local hi, lo = #tC, 1
                while hi-lo > 1 do 
                    local mid = (lo+hi)//2
                    if tC[mid].ticks <= right then
                        lo = mid
                    else 
                        hi = mid
                    end
                end
                targetValue = tC[hi].value
            end
            
            -- Tilt values
            local valueDelta = targetValue - prevRightVal
            local tickRange = prevRight-prevLeft
            local pT, pV, nV = t.tT, t.tV, new.tGroups[id].tV
            for i = 1, #pV do
                nV[i] = pV[i] + valueDelta*(pT[i]-prevLeft)/tickRange
            end
        end
    
        -- Copy remaining tables to new step    
        for a, b in pairs(t) do
            if not new.tGroups[id][a] then new.tGroups[id][a] = b end
        end
    end
    
    GetAllEdgeValues()
    CONSTRUCT_MIDI_STRING()
    return "NEXT"
end


--###########################
-----------------------------
function Edit_ChaseLeft()
    local old = tSteps[#tSteps]
    local new = {tGroups = {}, isChangingPositions = false}
    tSteps[#tSteps+1] = new
    for k, e in pairs(old) do
        if not new[k] then new[k] = e end
    end
    
    for id, t in pairs(old.tGroups) do
    
        -- Get edge ticks and values
        local prevLeft, prevRight, prevLeftVal, prevRightVal = t.tT[1], t.tT[#t.tT], t.tV[1], t.tV[#t.tV]
        local origLeft, origRight = tSteps[0].tGroups[id].tT[1], tSteps[0].tGroups[id].tT[#t.tT] -- step 0 was sorted
        if prevLeft > prevRight then prevLeft, prevRight, prevLeftVal, prevRightVal = prevRight, prevLeft, prevRightVal, prevLeftVal end
        local left  = (origLeft < prevLeft)   and origLeft or prevLeft
        local right = (origRight > prevRight) and origRight or prevRight
        
        local tC = t.tChase
        -- If there is nothing to chase, simpy copy previous step's values
        if not tC or #tC == 0 or tC[1].ticks >= left or prevLeft == prevRight then
            new.tGroups[id] = {tV = t.tV}
        -- Otherwise, do binary search to quickly find closest event
        else
            new.tGroups[id] = {tV = {}}
            local targetValue
            if tC[#tC].ticks < left then
                targetValue = tC[#tC].value
            else
                local hi, lo = #tC, 1
                while hi-lo > 1 do 
                    local mid = (lo+hi)//2
                    if tC[mid].ticks < left then
                        lo = mid
                    else 
                        hi = mid
                    end
                end
                targetValue = tC[lo].value
            end
            
            -- Tilt values
            local valueDelta = targetValue - prevLeftVal
            local tickRange = prevRight-prevLeft
            local pT, pV, nV = t.tT, t.tV, new.tGroups[id].tV
            for i = 1, #pV do
                nV[i] = pV[i] + valueDelta*(prevRight-pT[i])/tickRange
            end
        end
    
        -- Copy remaining tables to new step    
        for a, b in pairs(t) do
            if not new.tGroups[id][a] then new.tGroups[id][a] = b end
        end
    end
    
    GetAllEdgeValues()
    CONSTRUCT_MIDI_STRING()
    return "NEXT"
end


--######################
------------------------
function Edit_Reverse()
    local old = tSteps[#tSteps]
    local new = {tGroups = {}, globalLeftValue = old.globalRightValue, globalRightValue = old.globalLeftValue, isChangingPositions = true}
    tSteps[#tSteps+1] = new
    for k, e in pairs(old) do
        if not new[k] then new[k] = e end
    end
    for id, t in pairs(old.tGroups) do
        new.tGroups[id] = {tT = {}}
        for a, b in pairs(t) do
            if not new.tGroups[id][a] then new.tGroups[id][a] = b end
        end
    end

    local left, right = new.globalLeftTick, new.globalNoteOffTick
    for id, t in pairs(new.tGroups) do
        local nT, oT = t.tT, old.tGroups[id].tT
        for i = 1, #oT do
            nT[i] = right - (oT[i] - left)
        end
        if id == "notes" then
            local nO, oO = t.tOff, old.tGroups[id].tOff
            for i = 1, #oO do
                nO[i] = right - (oO[i] - left)
            end
            t.tT, t.tOff = t.tOff, t.tT
        end
    end
    
    CONSTRUCT_MIDI_STRING()
    return "NEXT"
end


--###########################
-----------------------------
function Edit_FlipValuesAbsolute()
    local old = tSteps[#tSteps]
    local new = {tGroups = {}, isChangingPositions = false}
    tSteps[#tSteps+1] = new
    for k, e in pairs(old) do
        if not new[k] then new[k] = e end
    end
    for id, t in pairs(old.tGroups) do
        new.tGroups[id] = {tV = {}}
        for a, b in pairs(t) do
            if not new.tGroups[id][a] then new.tGroups[id][a] = b end
        end
    end
    new.globalLeftValue   = laneMaxValue - (old.globalLeftValue - laneMinValue)
    new.globalRightValue  = laneMaxValue - (old.globalRightValue - laneMinValue)
    new.globalMinValue    = laneMaxValue - (old.globalMaxValue - laneMinValue)
    new.globalMaxValue    = laneMaxValue - (old.globalMinValue - laneMinValue)
    
    for id, t in pairs(new.tGroups) do
        local nV, oV = t.tV, old.tGroups[id].tV
        for i = 1, #oV do
            nV[i] = laneMaxValue - (oV[i] - laneMinValue)
        end
    end

    CONSTRUCT_MIDI_STRING()
    return "NEXT"
end


--###########################
-----------------------------
function Edit_FlipValuesRelative()
    local old = tSteps[#tSteps]
    local new = {tGroups = {}, isChangingPositions = false}
    tSteps[#tSteps+1] = new
    for k, e in pairs(old) do
        if not new[k] then new[k] = e end
    end
    for id, t in pairs(old.tGroups) do
        new.tGroups[id] = {tV = {}}
        for a, b in pairs(t) do
            if not new.tGroups[id][a] then new.tGroups[id][a] = b end
        end
    end
    new.globalLeftValue   = old.globalMaxValue - (old.globalLeftValue - old.globalMinValue)
    new.globalRightValue  = old.globalMaxValue - (old.globalRightValue - old.globalMinValue)
    
    for id, t in pairs(new.tGroups) do
        local nV, oV = t.tV, old.tGroups[id].tV
        for i = 1, #oV do
            nV[i] = old.globalMaxValue - (oV[i] - old.globalMinValue)
        end
    end

    CONSTRUCT_MIDI_STRING()
    return "NEXT"
end


local tiltWheel, tiltShape, tiltHeight, tiltRIGHT, tiltLEFT
--#####################################
---------------------------------------
function Defer_Tilt()

    -- Setup stuff at first defer cycle for this step
    if not (continueStep == "CONTINUE") then
        stepStartTime = thisDeferTime
        mouseStateAtStepDragTime = mouseState -- Temporarily - will be adjusted at each cycle
        -- Construct new tStep by copying previous - except those tables/values that will be newly contructed
        tSteps[#tSteps+1] = {tGroups = {}, isChangingPositions = false}
        local old = tSteps[#tSteps-1]
        local new = tSteps[#tSteps]
        for k, e in pairs(old) do
            if not new[k] then new[k] = e end
        end
        for id, t in pairs(old.tGroups) do
            new.tGroups[id] = {tV = {}}
            for a, b in pairs(t) do
                if not new.tGroups[id][a] then new.tGroups[id][a] = b end
            end
        end
        SetupGuidelineTables() -- Can only get left/right pixels and set up tables *after* constructing new step's table
        tiltWheel = tiltWheel or 1 -- If not first time tilting, remember previous wheel and shape
        tiltShape = tiltShape or "linear"
        if mouseX < (Guides_LeftPixel+Guides_RightPixel)/2 then tiltLEFT, tiltRIGHT = true, false else tiltLEFT, tiltRIGHT = false, true end
        mustCalculate = true
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
            if tiltHeight and tiltHeight > 0 then delta = -delta end
            if macOS then delta = -delta end -- macOS mousewheel events use opposite sign
            local sameDirection = (delta*prevDelta > 0)
            --delta = ((delta > 0) and 1) or ((delta < 0) and -1) or 0
            -- Meradium's suggestion: If mousewheel is turned rapidly, make larger changes to the curve per defer cycle
            --local factor = ((delta == prevDelta) and (time-prevMouseTime < 1)) and 0.04/((time-prevMouseTime)) or 0.04
            if not (tiltWheel == 1 and sameDirection and time < prevMouseTime + 1) then
                factor = sameDirection and factor*1.4 or 1.04
                local prevTiltWheel = tiltWheel
                tiltWheel = ((delta > 0) and tiltWheel*factor) or ((delta < 0) and tiltWheel/factor) or tiltWheel
                if (prevTiltWheel < 1 and tiltWheel >= 1) or (prevTiltWheel > 1 and tiltWheel <= 1) then tiltWheel = 1; factor = 1.04 -- Prevent scrolling through 1, and round to 1
                elseif tiltWheel < 0.025 then tiltWheel = 0.025 
                elseif tiltWheel > 40 then tiltWheel = 40
                --elseif 0.962 < tiltWheel and tiltWheel < 1.04 then tiltWheel = 1 -- Round to 1 if comes close
                end
                prevMouseTime = time 
                mustCalculate = true
            end
            prevDelta = delta
        end
    end
    
    -- MIDDLE BUTTON:
    peekOK, pass, time = reaper.JS_WindowMessage_Peek(windowUnderMouse, "WM_MBUTTONDOWN")
    if peekOK and time > prevMouseTime then 
        tiltShape = (tiltShape == "linear") and "sine" or "linear"
        Tooltip("Curve: "..tiltShape)
        prevMouseTime = time
        mustCalculate = true
    end
    
    -- MOUSE MOVEMENT:
    if mouseY ~= prevMouseY then mustCalculate = true end
    
    -- Scripts that extract selected MIDI events and re-concatenate them out of order (usually at the beginning of the MIDI string, for easier editing)
    --    cannot be auditioned in real-time while events are out of order, since such events are not played.
    -- If the mouse is held still, no editing is done, and instead the take is sorted, thereby temporarily allowing playback.
    if mustCalculate then
        
        local new = tSteps[#tSteps]
        local old = tSteps[#tSteps-1]
        local leftTick, rightTick = old.globalLeftTick, old.globalRightTick
        local range           = rightTick - leftTick
        local mouseNewCCValue = GetMouseValue("LIMIT")
        tiltHeight      = tiltLEFT and (mouseNewCCValue - old.globalLeftValue) or (mouseNewCCValue - old.globalRightValue)
        
        -- A power > 1 gives a more musical shape, therefore the cases tiltWheel >= 1 and tiltWheel < 1 will be dealt with separately.
        -- If tiltWheel < 1, its inverse will be used as power.
        if tiltLEFT then
            if tiltShape == "sine" then
                if tiltWheel >= 1 then 
                    for id, t in pairs(new.tGroups) do
                        local tT, tV, tOldV = t.tT, t.tV, old.tGroups[id].tV
                        for i = 1, #tT do
                            local v = 0.5*(1-m_cos(m_pi*(rightTick - tT[i])/range))
                            v = tOldV[i] + tiltHeight*(v^tiltWheel)
                            if v > laneMaxValue then v = laneMaxValue elseif v < laneMinValue then v = laneMinValue end  
                            tV[i] = v
                        end
                    end
                else -- tiltWheel < 1, so use inverse as power, and also change the sine formula
                    local inverseWheel = 1.0/tiltWheel
                    for id, t in pairs(new.tGroups) do
                        local tT, tV, tOldV = t.tT, t.tV, old.tGroups[id].tV
                        for i = 1, #tT do
                            local v = 0.5*(1-m_cos(m_pi*(tT[i] - leftTick)/range))
                            v = tOldV[i] + tiltHeight - tiltHeight*(v^inverseWheel)
                            if v > laneMaxValue then v = laneMaxValue elseif v < laneMinValue then v = laneMinValue end  
                            tV[i] = v
                        end
                    end
                end
            else -- tiltShape == "linear"
                if tiltWheel >= 1 then 
                    for id, t in pairs(new.tGroups) do
                        local tT, tV, tOldV = t.tT, t.tV, old.tGroups[id].tV
                        for i = 1, #tT do
                            local v = tOldV[i] + tiltHeight*(((rightTick - tT[i])/range)^tiltWheel)
                            if v > laneMaxValue then v = laneMaxValue elseif v < laneMinValue then v = laneMinValue end  
                            tV[i] = v
                        end
                    end
                else -- tiltWheel < 1
                    local inverseWheel = 1.0/tiltWheel
                    for id, t in pairs(new.tGroups) do
                        local tT, tV, tOldV = t.tT, t.tV, old.tGroups[id].tV
                        for i = 1, #tT do
                            local v = tOldV[i] + tiltHeight - tiltHeight*(((tT[i] - leftTick)/range)^inverseWheel)
                            if v > laneMaxValue then v = laneMaxValue elseif v < laneMinValue then v = laneMinValue end  
                            tV[i] = v
                        end
                    end
                end
            end
        else -- tiltRIGHT
            if tiltShape == "sine" then
                if tiltWheel >= 1 then 
                    for id, t in pairs(new.tGroups) do
                        local tT, tV, tOldV = t.tT, t.tV, old.tGroups[id].tV
                        for i = 1, #tT do
                            local v = 0.5*(1-m_cos(m_pi*(tT[i] - leftTick)/range))
                            v = tOldV[i] + tiltHeight*(v^tiltWheel)
                            if v > laneMaxValue then v = laneMaxValue elseif v < laneMinValue then v = laneMinValue end  
                            tV[i] = v
                        end
                    end
                else -- tiltWheel < 1
                    local inverseWheel = 1.0/tiltWheel
                    for id, t in pairs(new.tGroups) do
                        local tT, tV, tOldV = t.tT, t.tV, old.tGroups[id].tV
                        for i = 1, #tT do
                            local v = 0.5*(1-m_cos(m_pi*(rightTick - tT[i])/range))
                            v = tOldV[i] + tiltHeight - tiltHeight*(v^inverseWheel)
                            if v > laneMaxValue then v = laneMaxValue elseif v < laneMinValue then v = laneMinValue end  
                            tV[i] = v
                        end
                    end
                end
            else -- tiltShape == "linear"
                if tiltWheel >= 1 then 
                    for id, t in pairs(new.tGroups) do
                        local tT, tV, tOldV = t.tT, t.tV, old.tGroups[id].tV
                        for i = 1, #tT do 
                            local v = tOldV[i] + tiltHeight*(((tT[i] - leftTick)/range)^tiltWheel)
                            if v > laneMaxValue then v = laneMaxValue elseif v < laneMinValue then v = laneMinValue end  
                            tV[i] = v
                        end
                    end
                else -- tiltWheel < 1
                    local inverseWheel = 1.0/tiltWheel
                    for id, t in pairs(new.tGroups) do
                        local tT, tV, tOldV = t.tT, t.tV, old.tGroups[id].tV
                        for i = 1, #tT do
                            local v = 0.5*(1-m_cos(m_pi*(rightTick - tT[i])/range))
                            v = tOldV[i] + tiltHeight - tiltHeight*(v^inverseWheel)
                            if v > laneMaxValue then v = laneMaxValue elseif v < laneMinValue then v = laneMinValue end  
                            tV[i] = v
                        end
                    end
                end
            end
        end
        
        local tTopY = {}
        local tBottomY = {}
        local apexPixels = (tiltHeight/laneMaxValue) * (ME_TargetTopPixel - ME_TargetBottomPixel)
        
        if tiltWheel >= 1 then 
            if tiltShape == "sine" then
                for i, ticks in ipairs(tGuides_Ticks) do
                    if tiltRIGHT then --ticks <= mouseNewPPQPos then
                        local s = apexPixels*((0.5*(1-m_cos(m_pi*(ticks - leftTick)/range)))^tiltWheel)
                        tTopY[i] = ME_TargetTopPixel + s
                        tBottomY[i] = ME_TargetBottomPixel + 1 + s
                    else
                        local s = apexPixels*((0.5*(1-m_cos(m_pi*(rightTick - ticks)/range)))^tiltWheel)
                        tTopY[i] = ME_TargetTopPixel + s
                        tBottomY[i] = ME_TargetBottomPixel + 1 + s
                    end
                end
            else
                for i, ticks in ipairs(tGuides_Ticks) do
                    if tiltRIGHT then --ticks <= mouseNewPPQPos then
                        local s = apexPixels*(((ticks - leftTick)/range)^tiltWheel)
                        tTopY[i] = ME_TargetTopPixel + s
                        tBottomY[i] = ME_TargetBottomPixel + 1 + s
                    else -- tiltLEFT
                        local s = apexPixels*(((rightTick - ticks)/range)^tiltWheel)
                        tTopY[i] = ME_TargetTopPixel + s
                        tBottomY[i] = ME_TargetBottomPixel + 1 + s
                    end
                end
            end
        else
            local inverseWheel = 1.0/tiltWheel
            if tiltShape == "sine" then
                for i, ticks in ipairs(tGuides_Ticks) do
                    if tiltRIGHT then --ticks <= mouseNewPPQPos then
                        local s = apexPixels - apexPixels*((0.5*(1-m_cos(m_pi*(rightTick - ticks)/range)))^inverseWheel)
                        tTopY[i] = ME_TargetTopPixel + s
                        tBottomY[i] = ME_TargetBottomPixel + 1 + s
                    else
                        local s = apexPixels - apexPixels*((0.5*(1-m_cos(m_pi*(ticks - leftTick)/range)))^inverseWheel)
                        tTopY[i] = ME_TargetTopPixel + s
                        tBottomY[i] = ME_TargetBottomPixel + 1 + s
                    end
                end
            else
                for i, ticks in ipairs(tGuides_Ticks) do
                    if tiltRIGHT then --ticks <= mouseNewPPQPos then
                        local s = apexPixels - apexPixels*(((rightTick - ticks)/range)^inverseWheel)
                        tTopY[i] = ME_TargetTopPixel + s
                        tBottomY[i] = ME_TargetBottomPixel + 1 + s
                    else
                        local s = apexPixels - apexPixels*(((ticks - leftTick)/range)^inverseWheel)
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
        
        CONSTRUCT_MIDI_STRING()
        
    end -- mustCalculate stuff
    
    
    -- GO TO NEXT STEP?
    if Check_MouseLeftButtonSinceLastDefer() then
        GetAllEdgeValues(tSteps[#tSteps])
        return "NEXT"
    else
        return "CONTINUE"
    end
    
end -- Defer_Tilt()


local tRel = {} -- Compress formula uses relative values, not absolute
local compressWheel, compressTOP, compressBOTTOM, compressSYMMETRIC, compressShape = 1, nil, nil, false, "linear"
--#######################
-------------------------
function Defer_Compress()

    --local tRel = tRel or {}
    -- Setup stuff at first defer cycle for this step
    if not (continueStep == "CONTINUE") then
        stepStartTime = thisDeferTime
        mouseStateAtStepDragTime = mouseState
        compressTOP = mouseY and (mouseY < (ME_TargetBottomPixel+ME_TargetTopPixel)/2)
        compressBOTTOM = not compressTOP

        tRel = {}
        -- Construct new tStep by copying previous - except those tables/values that will be newly contructed
        local old = tSteps[#tSteps]
        local new = {tGroups = {}, isChangingPositions = false}
        tSteps[#tSteps+1] = new
        for k, e in pairs(old) do
            if not new[k] then new[k] = e end
        end
        for id, t in pairs(old.tGroups) do
            new.tGroups[id] = {tV = {}}
            for a, b in pairs(t) do
                if not new.tGroups[id][a] then new.tGroups[id][a] = b end
            end
            tRel[id] = {}
            local r = tRel[id]
            local laneHeight = laneMaxValue-laneMinValue
            for i, v in ipairs(t.tV) do
                r[i] = (v-laneMinValue)/laneHeight
            end
        end
        SetupGuidelineTables() -- Can only get left/right pixels and set up tables *after* constructing new step's table
        mustCalculate = true -- Always calculate when script starts
    end
  
    local s = tSteps[#tSteps]
    
    --[==[ MOUSEWHEEL
    local peekOK, pass, time, keys, delta = reaper.JS_WindowMessage_Peek(windowUnderMouse, "WM_MOUSEWHEEL")
    if not (peekOK and time > prevMouseTime) then 
        peekOK, pass, time, keys, delta = reaper.JS_WindowMessage_Peek(windowUnderMouse, "WM_MOUSEHWHEEL")
    end 
    if peekOK and time > prevMouseTime + 0.1 then 
        prevMouseTime = time
        mustCalculate = true
        --if keys&12 ~= 0 then return false end
        -- Standardize delta values
        delta = ((delta > 0) and 1) or ((delta < 0) and -1) or 0
        if macOS then delta = -delta end -- macOS scrolls up/down with opposite mousewheel than Windows/Linux
        if (compressTOP and mouseY < ME_TargetTopPixel) or (compressBOTTOM and mouseY < ME_TargetBottomPixel) then delta = -delta end
        --[[ Pause a little if flat line has been reached
        if mousewheel <= 0 then
            if delta ~= prevDelta then
                mousewheel = (delta == 1) and 0.025 or 40
            end
        else]]
            
        -- Meradium's suggestion: If mousewheel is turned rapidly, make larger changes to the curve per defer cycle
        if compressWheel == 0 then if delta == 1 then compressWheel = 0.025 else compressWheel = 40 end end
        --else
            local factor = (delta == prevDelta and time-prevMouseTime < 1) and 0.04/((time-prevMouseTime)^2) or 0.04
            compressWheel = (delta == 1) and (compressWheel*(1+factor)) or (compressWheel/(1+factor))
            --if mousewheel <= 0 then mousewheel = (delta == 1) and 0.025 or 40 end
            -- Snap to flat line (standard compression shape) if either direction goes extreme
            if compressWheel < 0.025 or 40 < compressWheel then 
                compressWheel = 0
                --prevMouseTime = prevMouseTime + 1
            -- Round to 1 if comes close
            elseif 0.962 < compressWheel and compressWheel < 1.04 then
                compressWheel = 1
                --prevMouseTime = prevMouseTime + 1
            end
        --end]]
        if compressWheel == 0 or compressWheel == 1 then prevMouseTime = prevMouseTime + 1 end
        prevDelta = delta
    end]==]
    
    -- MOUSEWHEEL
    local peekOK, pass, time, keys, delta = reaper.JS_WindowMessage_Peek(windowUnderMouse, "WM_MOUSEWHEEL")
    if not (peekOK and time > prevMouseTime) then 
        peekOK, pass, time, keys, delta = reaper.JS_WindowMessage_Peek(windowUnderMouse, "WM_MOUSEHWHEEL")
    end 
    if peekOK and time > prevMouseTime + 0.1 then 
        --if keys&12 ~= 0 then return false end
        -- Standardize delta values
        delta = ((delta > 0) and 1) or ((delta < 0) and -1) or 0
        if macOS then delta = -delta end -- macOS scrolls up/down with opposite mousewheel than Windows/Linux
        if (compressTOP and mouseY < ME_TargetTopPixel) or (compressBOTTOM and mouseY < ME_TargetBottomPixel) then delta = -delta end
        -- Pause a little if flat line has been reached
        if compressWheel == 0 then
            if time > prevMouseTime+1 or (delta ~= prevDelta and delta ~= 0 and prevDelta ~= 0) then --or delta ~= prevDelta then
                compressWheel = (delta == 1) and 0.025 or 40
                prevMouseTime = time
                mustCalculate = true
            end
        elseif compressWheel == 1 then
            if time > prevMouseTime+1 or (delta ~= prevDelta and delta ~= 0 and prevDelta ~= 0) then
                compressWheel = (delta == 1) and 1.04 or 0.962
                prevMouseTime = time
                mustCalculate = true
            end
        else
            -- Meradium's suggestion: If mousewheel is turned rapidly, make larger changes to the curve per defer cycle
            local factor = (delta == prevDelta and time-prevMouseTime < 1) and 0.04/((time-prevMouseTime)^2) or 0.04
            local prevCompressWheel = compressWheel or 1
            compressWheel = (delta == 1) and (compressWheel*(1+factor)) or (compressWheel/(1+factor))
            -- Snap to flat line (standard compression shape) if either direction goes extreme
            if compressWheel < 0.025 or 40 < compressWheel then 
                compressWheel = 0
            -- Round to 1 if comes close
            elseif (compressWheel < 1 and 1 < prevCompressWheel) or (prevCompressWheel < 1 and 1 < compressWheel) then
                compressWheel = 1
            end
            prevMouseTime = time
            mustCalculate = true
        end
        prevDelta = delta
    end
    mouseGreaterThanOne = (compressWheel >= 1)
    inversewheel = 1/compressWheel -- Can be infinity
        
    -- MIDDLE BUTTON: Middle button changes curve shape
    peekOK, pass, time = reaper.JS_WindowMessage_Peek(windowUnderMouse, "WM_MBUTTONDOWN")
    if peekOK and time > prevDeferTime then 
        compressShape = (compressShape == "linear") and "sine" or "linear"
        Tooltip("Curve: "..compressShape)
        prevMouseTime = time
        mustCalculate = true
    end
    
    -- RIGHT CLICK: Right click changes script mode
    --    * If script is terminated by right button, disarm toolbar.
    --    * REAPER shows context menu when right button is *lifted*, so must continue intercepting mouse messages until right button is lifted.
    peekOK, pass, time = reaper.JS_WindowMessage_Peek(windowUnderMouse, "WM_RBUTTONDOWN")
    if peekOK and time > prevDeferTime then
        compressSYMMETRIC = not compressSYMMETRIC
        prevMouseTime = time
        mustCalculate = true
    end
  
    -- MOUSE MOVEMENT:
    if mouseX ~= prevMouseX or mouseY ~= prevMouseY then mustCalculate = true end
    
    ---------------------
    
    if mustCalculate then
         
        local globalLeftTick = s.globalLeftTick
        local globalRightTick = s.globalRightTick
        -- MOUSE NEW CC VALUE (vertical position)
        mouseNewCCValue = GetMouseValue()        
        mouseNewPPQPos = GetMouseTick() -- Adjust mouse PPQ position for looped items
        mouseNewPPQPos = math.max(globalLeftTick, math.min(globalRightTick, mouseNewPPQPos)) -- !!!!!!!!!!!! Unique to this script: limit PPQ pos to CC range, so that curve doesn't change the further mouse goes outside CC range
        
        leftPPQrange = mouseNewPPQPos - globalLeftTick
        rightPPQrange = globalRightTick - mouseNewPPQPos
                
                
        -- CALCULATE NEW CC VALUES!
        local newValue, fraction 

        for id, t in pairs(s.tGroups) do
            local tOldV = tSteps[#tSteps-1].tGroups[id].tV
            local tR    = tRel[id]
            local tV    = t.tV
            for i = 1, #tOldV do
                local ticks = t.tT[i]
                if ticks == mouseNewPPQPos or compressWheel == 0 then
                    fraction = 1
                else
                    if mouseGreaterThanOne then
                        if ticks < mouseNewPPQPos then
                            fraction = ((ticks - globalLeftTick)/leftPPQrange)^compressWheel
                        else
                            fraction = ((globalRightTick - ticks)/rightPPQrange)^compressWheel
                        end
                    else
                        if ticks < mouseNewPPQPos then
                            fraction = 1 - ((mouseNewPPQPos - ticks)/leftPPQrange)^inversewheel
                        else
                            fraction = 1 - ((ticks - mouseNewPPQPos)/rightPPQrange)^inversewheel
                        end
                    end
                end
                if compressShape == "sine" then fraction = 0.5*(1-m_cos(m_pi*fraction)) end
                    
                local tempLaneMin, tempLaneMax
                if compressTOP then
                    tempLaneMax = laneMaxValue + fraction*(mouseNewCCValue-laneMaxValue)
                    if compressSYMMETRIC then
                        tempLaneMin = laneMinValue + fraction*(laneMaxValue-mouseNewCCValue)
                    else
                        tempLaneMin = laneMinValue
                    end
                else -- compressBOTTON
                    tempLaneMin = laneMinValue + fraction*(mouseNewCCValue-laneMinValue)
                    if compressSYMMETRIC then
                        tempLaneMax = laneMaxValue + fraction*(laneMinValue-mouseNewCCValue)
                    else
                        tempLaneMax = laneMaxValue
                    end
                end
                local newValue = tempLaneMin + tR[i] * (tempLaneMax - tempLaneMin) -- Replace with tRel
                if      newValue > laneMaxValue then tV[i] = laneMaxValue
                elseif  newValue < laneMinValue then tV[i] = laneMinValue
                else tV[i] = newValue
                end
            end
        end
        
        -------------------------------------------------------
        -- Guidelines
              
        local tTopY = {}
        local tBottomY = {}
        local y
        
        for i, ticks in ipairs(tGuides_Ticks) do
            if compressWheel == 0 then --or (mouseNewPPQPos-5 < ticks and ticks < mouseNewPPQPos+5) then 
                fraction = 1
            else
                if mouseGreaterThanOne then
                    if ticks < mouseNewPPQPos then
                        fraction = ((ticks - globalLeftTick)/leftPPQrange)^compressWheel
                    else
                        fraction = ((globalRightTick - ticks)/rightPPQrange)^compressWheel
                    end
                else
                    if ticks < mouseNewPPQPos then
                        fraction = 1 - ((mouseNewPPQPos - ticks)/leftPPQrange)^inversewheel
                    else
                        fraction = 1 - ((ticks - mouseNewPPQPos)/rightPPQrange)^inversewheel
                    end
                end
            end
            if compressShape == "sine" then fraction = 0.5*(1-m_cos(m_pi*fraction)) end
        
            if compressTOP then
                y = fraction*(mouseY-ME_TargetTopPixel)
                tTopY[i] = ME_TargetTopPixel + y
                if compressSYMMETRIC then tBottomY[i] = ME_TargetBottomPixel + 1 - y end
            else
                y = fraction*(ME_TargetBottomPixel-mouseY)
                tBottomY[i] = ME_TargetBottomPixel + 1 - y
                if compressSYMMETRIC then tTopY[i] = ME_TargetTopPixel + y end
            end
        end
        
        reaper.JS_LICE_Clear(bitmap, 0)
        
        local x1, t1, b1 = tGuides_X[1], tTopY[1], tBottomY[1] -- Coordinates of left pixel of each line segment
        for i = 2, #tGuides_X do
            -- To make sure than pointy curve is correctly drawn, even is point falls between 10-pixel segements, insert extra line to precise position of mouse
            if x1 < mouseX and mouseX < tGuides_X[i] then 
                if compressTOP then
                    reaper.JS_LICE_Line(bitmap, x1, t1, mouseX, mouseY, Guides_COLOR_TOP, 1, "COPY", true)
                    t1 = mouseY
                    if compressSYMMETRIC then
                        reaper.JS_LICE_Line(bitmap, x1, b1, mouseX, (ME_TargetBottomPixel+1) - (mouseY-ME_TargetTopPixel), Guides_COLOR_BOTTOM, 1, "COPY", true)
                        b1 = (ME_TargetBottomPixel+1) - (mouseY-ME_TargetTopPixel)
                    end
                else -- compressSYMMETRIC then
                    reaper.JS_LICE_Line(bitmap, x1, b1, mouseX, mouseY, Guides_COLOR_BOTTOM, 1, "COPY", true)
                    b1 = mouseY
                    if compressSYMMETRIC then
                        reaper.JS_LICE_Line(bitmap, x1, t1, mouseX, ME_TargetTopPixel - (mouseY-ME_TargetBottomPixel), Guides_COLOR_TOP, 1, "COPY", true)
                        t1 = ME_TargetTopPixel - (mouseY-ME_TargetBottomPixel)
                    end
                end
            end
            x2, t2, b2 = tGuides_X[i], tTopY[i], tBottomY[i]
            if compressTOP or compressSYMMETRIC then reaper.JS_LICE_Line(bitmap, x1, t1, x2, t2, Guides_COLOR_TOP, 1, "COPY", true) end
            if compressBOTTOM or compressSYMMETRIC then reaper.JS_LICE_Line(bitmap, x1, b1, x2, b2, Guides_COLOR_BOTTOM, 1, "COPY", true) end
            x1, t1, b1 = x2, t2, b2
        end
        
        if compressTOP and not compressSYMMETRIC then reaper.JS_LICE_Line(bitmap, tGuides_X[1], ME_TargetBottomPixel+1, tGuides_X[#tGuides_X], ME_TargetBottomPixel+1, Guides_COLOR_BOTTOM, 1, "COPY", true) end
        if compressBOTTOM and not compressSYMMETRIC then reaper.JS_LICE_Line(bitmap, tGuides_X[1], ME_TargetTopPixel, tGuides_X[#tGuides_X], ME_TargetTopPixel, Guides_COLOR_TOP, 1, "COPY", true) end
        
        --reaper.JS_Window_InvalidateRect(midiview, Guides_LeftPixel-20, ME_TargetTopPixel-20, Guides_RightPixel+20, ME_TargetBottomPixel+20, false)
        
        CONSTRUCT_MIDI_STRING()
        
    end -- mustCalculate stuff
    
    -- GO TO NEXT STEP?
    if Check_MouseLeftButtonSinceLastDefer() then
        GetAllEdgeValues(tSteps[#tSteps])
        return "NEXT"
    else
        return "CONTINUE"
    end
    
end -- Defer_Compress()


local dragTimeStarted, keysDownAtDragTime = nil, nil
--##################################
------------------------------------
function Check_CommonQuitConditionsAndGetInputs()
    
    -- Must the script terminate?
    -- Must the script go through the entire deferred function to calculate new MIDI stuff?
    --
    -- Both of these questions will be checked by getting mouse and keyboard input.
    -- Each defer edit function may also check further input such as 
    -- MIDI stuff might be changed if the mouse has moved, mousebutton has been clicked, or mousewheel has scrolled, so need to re-calculate.
    -- Otherwise, mustCalculate remains nil, and can skip to end of function.
    
    mustCalculate = false
    prevDeferTime = thisDeferTime or startTime
    thisDeferTime = reaper.time_precise()
    --dragTimeStarted = dragTimeStarted or (thisDeferTime > startTime + dragTime)  -- No need to call time_precise if dragTimeStarted already true   
    
    -- KEYBOARD: Script can be terminated by pressing key twice to start/stop, or by holding key and releasing after dragTime
    -- Recent versions of js_ReaScriptAPI ignore auto-repeared KEYDOWNs, so checking key presses is much simpler.
    -- BEWARE: REAPER only passes info to the VKey functions *between* defer cycles.  So if the MIDI take is very large and parsing takes longer than dragtime,
    --          Vkey_GetState will not be updated before getting keysDownAtDragTime.  The following code therefore waits at least three cycles:
    if not dragTimeStarted then -- First cycle
        dragTimeStarted = (thisDeferTime > startTime + dragTime)
    elseif not keysDownAtDragTime then -- Second cycle
        keysDownAtDragTime = reaper.JS_VKeys_GetState(startTime-0.5):sub(VKLow, VKHi) -- Only get keyState once, when dragtime has started
    elseif keysDownAtDragTime ~= keyState0 then -- Third cycle
        if reaper.JS_VKeys_GetState(startTime-0.5):sub(VKLow, VKHi) == keyState0 then return false end -- If keys are still held after dragtime, quit when they are released
    end 
    if reaper.JS_VKeys_GetDown(prevDeferTime):sub(VKLow, VKHi) ~= keyState0 then return false end
    
    -- EXTSTATE: Other scripts can communicate with and control the other js_ scripts via ExtStates
    local extState = reaper.GetExtState("js_Mouse actions", "Status") or ""
    if extState == "" or extState == "Must quit" then return(false) end
    
    -- MOUSE MODIFIERS: If any modifier key is pressed, after first releasing them, quit.
    -- This can detect left clicks even if the mouse is outside the MIDI editor
    prevMouseState = mouseState or 0xFF
    mouseState = reaper.JS_Mouse_GetState(0xFF)
    if (mouseState&52) > (prevMouseState&52) then -- 60 = 0b00111100 = Win | Alt | Shift | Ctrl
        return false
    end
    
    -- MOUSE POSITION: (New versions of the script don't quit if mouse moves out of CC lane, but will still quit if moves too far out of midiview.
    prevMouseX, prevMouseY = mouseX, mouseY
    mouseX, mouseY = reaper.GetMousePosition()
    --[[if mouseX ~= prevMouseX or mouseY ~= prevMouseY then
        prevMouseX, prevMouseY = mouseX, mouseY
        mustCalculate = true
    end]]
    if isInline then
        window = reaper.BR_GetMouseCursorContext()
        if not (window == "midi_editor" or window == "arrange") then
            return false 
        end
    else 
        -- MIDI editor closed or changed mode? 
        if reaper.MIDIEditor_GetMode(editor) ~= 0 then return false end 
        mouseX, mouseY = reaper.JS_Window_ScreenToClient(midiview, mouseX, mouseY)
        -- When move out of midiview, WM_SETCURSOR is no longer blocked, so must continually force cursor back to script cursor
        if mouseX < 0 or mouseY < 0 or ME_midiviewWidth <= mouseX or ME_midiviewHeight <= mouseY then 
            if cursor then 
                reaper.JS_Mouse_SetCursor(cursor) 
            end
            -- Quit if clicking outside midiview -- unless click on bottom scrollbar, which may be hiding the bottom Compress zone
            if mouseState > prevMouseState then 
                if mouseX < 0 or mouseY < 0 or ME_midiviewWidth <= mouseX or ME_midiviewHeight+50 <= mouseY then
                    return false 
                end
            end
            --[[
            if cursor then reaper.JS_Mouse_SetCursor(cursor) end
            if mouseState&1 == 0 and (mouseX < -150 or mouseY < -150 or ME_midiviewWidth+150 < mouseX or ME_midiviewHeight+150 < mouseY) then
                return false
            elseif cursor then
                reaper.JS_Mouse_SetCursor(cursor)
            end]]
        end
    end  
    
    -- TAKE STILL VALID?
    if not reaper.ValidatePtr2(0, activeTake, "MediaItem_Take*") then return false end
    
    -- EVERYTHING CHECKS OUT
    return true
end


--#######################
-------------------------
function GetMinMaxTicks()
    if tSteps[#tSteps].tTicks[1] < tSteps[#tSteps].tTicks[#tTicks] then
        return tSteps[#tSteps].tTicks[1], tSteps[#tSteps].tTicks[#tTicks] + (tSteps[#tSteps].tLengths[#tTicks] or 0)
    else
        return tSteps[#tSteps].tTicks[#tTicks], tSteps[#tSteps].tTicks[1] + (tSteps[#tSteps].tLengths[1] or 0)
    end
end


--#################################
-----------------------------------
--[[
--function GetAllEdgeValues(tGroups, preferredGroup)
    local leftTick, leftValue, rightTick, rightValue, minValue, maxValue = math.huge, nil, -math.huge, nil, math.huge, -math.huge
    local tP = tGroups[preferredGroup]
    if tP then
        leftTick, leftValue, rightTick, rightValue = tP.tT[1], tP.tV[1], tP.tT[#tP.tT], tP.tV[#tP.tV]
        if leftTick > rightTick then leftTick, leftValue, rightTick, rightValue = rightTick, rightValue, leftTick, leftValue end
    end
    for id, t in pairs(tGroups) do
        local tV, tT = t.tV, t.tT
        if id ~= preferredGroup then
            if tT[1] < leftTick then leftTick, leftValue = tT[1], tV[1] end
            if tT[#tT] < leftTick then leftTick, leftValue = tT[#tT], tV[#tV] end
            if tT[1] > rightTick then rightTick, rightValue = tT[1], tV[1] end
            if tT[#tT] >rightTick then rightTick, rightValue = tT[#tT], tV[#tV] end
        end
        for i = 1, #tV do
            if tV[i] < minValue then minValue = tV[i] end -- !!!! Can speed this up with elseif
            if tV[i] > maxValue then maxValue = tV[i] end
        end
    end
    return leftTick, leftValue, rightTick, rightValue, minValue, maxValue
end]]
function GetAllEdgeValues(step)
    local leftTick, leftValue, rightTick, rightValue, minValue, maxValue, noteOffTick = math.huge, nil, -math.huge, nil, math.huge, -math.huge, -math.huge
    step = step or tSteps[#tSteps]
    -- The active channel takes precedence when finding edge values, if multiple CCs at same tick positions, so that Tilt zones correspond to active channel
    local tP = step.tGroups[activeChannel]
    if tP then
        leftTick, leftValue, rightTick, rightValue = tP.tT[1], tP.tV[1], tP.tT[#tP.tT], tP.tV[#tP.tV]
        if leftTick > rightTick then leftTick, leftValue, rightTick, rightValue = rightTick, rightValue, leftTick, leftValue end
    end
    for id, t in pairs(step.tGroups) do
        local tV, tT, tOff = t.tV, t.tT, t.tOff
        if id == "notes" and t.noteWithLastNoteOff then
            local n = t.noteWithLastNoteOff
            local t1 = tOff[1]
            local tn = tOff[n]
            if t1 < tn then 
                noteOffTick, rightValue = tn, tV[n] 
            else 
                noteOffTick, rightValue = t1, tV[1]
            end
            if tT[1] < leftTick then leftTick, leftValue = tT[1], tV[1] end
            if tT[n] < leftTick then leftTick, leftValue = tT[n], tV[n] end
            if tT[1] > rightTick then rightTick = tT[1] end
            if tT[#tT] > rightTick then rightTick = tT[#tT] end
        elseif id ~= activeChannel then
            if tT[1] < leftTick then leftTick, leftValue = tT[1], tV[1] end
            if tT[#tT] < leftTick then leftTick, leftValue = tT[#tT], tV[#tV] end
            if tT[1] > rightTick then rightTick, rightValue = tT[1], tV[1] end
            if tT[#tT] > rightTick then rightTick, rightValue = tT[#tT], tV[#tV] end
        end
        if id ~= "text" then
            for i = 1, #tV do
                if tV[i] < minValue then minValue = tV[i] end -- !!!! Can speed this up with elseif, and one comparison when all done
                if tV[i] > maxValue then maxValue = tV[i] end
            end
        end
    end
    if noteOffTick < rightTick then noteOffTick = rightTick end
    step.globalLeftTick   = leftTick
    step.globalLeftValue  = leftValue
    step.globalRightTick  = rightTick
    step.globalRightValue = rightValue
    step.globalMinValue   = minValue
    step.globalMaxValue   = maxValue
    step.globalNoteOffTick = noteOffTick         
end


--############################################
----------------------------------------------
function GetLeftRightPixels(step, withNoteOff)
    
    if not (type(step) == "table") then step = tSteps[step] end
    local leftTick  = step.globalLeftTick
    local rightTick = withNoteOff and step.globalNoteOffTick or step.globalRightTick
    --local leftPixel, rightPixel
    if ME_TimeBase == "beats" then
        leftPixel = (leftTick + loopStartPPQPos - ME_LeftmostTick) * ME_PixelsPerTick
        rightPixel = (rightTick + loopStartPPQPos - ME_LeftmostTick)*ME_PixelsPerTick
    else -- ME_TimeBase == "time"
        local firstTime = reaper.MIDI_GetProjTimeFromPPQPos(activeTake, leftTick + loopStartPPQPos)
        local lastTime  = reaper.MIDI_GetProjTimeFromPPQPos(activeTake, rightTick + loopStartPPQPos)
        leftPixel  = (firstTime-ME_LeftmostTime)*ME_PixelsPerSecond
        rightPixel = (lastTime -ME_LeftmostTime)*ME_PixelsPerSecond
    end
    leftPixel  = leftPixel//1 --math.ceil(math.max(left, 0)) 
    rightPixel = rightPixel//1 --math.floor(math.min(right, ME_midiviewWidth-1))
    return leftPixel, rightPixel
end


--#############################
-------------------------------
function SetupGuidelineTables()
 
    Guides_LeftPixel, Guides_RightPixel = GetLeftRightPixels(tSteps[#tSteps], false)
    if Guides_LeftPixel and Guides_RightPixel 
    and (Guides_LeftPixel ~= prevGuides_LeftPixel) or (Guides_RightPixel ~= prevGuides_RightPixel) 
    then
        prevGuides_LeftPixel = Guides_LeftPixel
        prevGuides_RightPixel = Guides_RightPixel
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
                tGuides_X[#tGuides_X+1] = x
                tGuides_Ticks[#tGuides_Ticks+1] = reaper.MIDI_GetPPQPosFromProjTime(activeTake, ME_LeftmostTime + x/ME_PixelsPerSecond )
                                            - loopStartPPQPos
            end
            tGuides_X[#tGuides_X+1] = Guides_RightPixel
            tGuides_Ticks[#tGuides_Ticks+1] = reaper.MIDI_GetPPQPosFromProjTime(activeTake, ME_LeftmostTime + Guides_RightPixel/ME_PixelsPerSecond )
                                        - loopStartPPQPos
        end
    end
end


--##########################
----------------------------
function SetupDisplayZones()    
    
    if not tColors then
        LoadZoneColors()
    end
    
    tZones = {}
    local t = tSteps[#tSteps]
    
    local GUI_LeftPixel, GUI_RightPixel = GetLeftRightPixels(tSteps[#tSteps], "NOTEOFF")
    GUI_LeftPixel, GUI_RightPixel = (GUI_LeftPixel-zoneWidth*1.5)//1, (GUI_RightPixel+zoneWidth*1.5)//1
    -- Always show stretch zones, even if MIDI is offscreen, so that stretchig can still be performed
    if GUI_LeftPixel > ME_midiviewWidth then GUI_LeftPixel = ME_midiviewWidth-zoneWidth*2 end
    if GUI_RightPixel < 0 then GUI_RightPixel = zoneWidth*2 end
    local GUI_MidPixel = (GUI_LeftPixel+GUI_RightPixel)//2
    if (GUI_RightPixel - GUI_LeftPixel) < zoneWidth*4 then GUI_LeftPixel, GUI_RightPixel = GUI_MidPixel - 2*zoneWidth, GUI_MidPixel + 2*zoneWidth end
    
    local undoLeft = math.max(0, GUI_LeftPixel-2*zoneWidth)
     
    tZones = {}
    if (laneIsCC7BIT or laneIsCC14BIT or laneIsPITCH or laneIsCHANPRESS or laneIsPROGRAM or laneIsVELOCITY or laneIsOFFVEL) 
    and (ME_TargetBottomPixel-ME_TargetTopPixel) > 3*zoneWidth
    then
        -- Tilt
        local leftValue, rightValue = t.globalLeftValue, t.globalRightValue
        if leftValue then
            --if t.tTicks[1] > t.tTicks[#t.tTicks] then leftValue, rightValue = rightValue, leftValue end
            local leftTiltPixel = ME_TargetTopPixel+(1-leftValue/laneMaxValue)*(ME_TargetBottomPixel-ME_TargetTopPixel)
            tZones[#tZones+1] = {func = Defer_Tilt,         wheel = Edit_ChaseLeft,         tooltip = "Tilt / Arch",   cursor = cursorTilt,         color = "tilt", 
                                  left = GUI_LeftPixel,  right = GUI_LeftPixel+zoneWidth-1,  top = leftTiltPixel-zoneWidth/2,    bottom = leftTiltPixel+zoneWidth/2}   
        end
        if rightValue then
            local rightTiltPixel = ME_TargetTopPixel+(1-rightValue/laneMaxValue)*(ME_TargetBottomPixel-ME_TargetTopPixel)
            tZones[#tZones+1] = {func = Defer_Tilt,           wheel = Edit_ChaseRight,          tooltip = "Tilt / Arch",  cursor = cursorTilt,      color = "tilt", 
                                  left = GUI_RightPixel-zoneWidth+1,   right = GUI_RightPixel,  top = rightTiltPixel-zoneWidth/2,  bottom = rightTiltPixel+zoneWidth/2}
        end
        
        -- Undo/Redo        
        tZones[#tZones+1] = {func = Defer_Undo,     wheel = Defer_Undo,     tooltip = "Undo",                       cursor = cursorUndo,    color = (#tSteps > 0) and "undo" or "black", 
                             left = undoLeft,       right = undoLeft+zoneWidth-1,      top = ME_TargetTopPixel-2*zoneWidth-2,  bottom = ME_TargetTopPixel-zoneWidth-2}                  
        tZones[#tZones+1] = {func = Defer_Redo,     wheel = Defer_Redo,     tooltip = "Redo",                       cursor = cursorRedo,    color = (#tRedo > 0) and "redo" or "black", 
                             left = undoLeft+zoneWidth,      right = undoLeft+2*zoneWidth-1,  top = ME_TargetTopPixel-2*zoneWidth-2,  bottom = ME_TargetTopPixel-zoneWidth-2}                  
        
        -- Scale
        local left, right = GUI_LeftPixel+2*zoneWidth, GUI_RightPixel-2*zoneWidth
        if right-left < 2*zoneWidth then left, right = GUI_MidPixel-zoneWidth, GUI_MidPixel+zoneWidth end
        
        local minValuePixel, maxValuePixel = ME_TargetBottomPixel, ME_TargetTopPixel
        if t.globalMaxValue and t.globalMinValue then 
            maxValuePixel = ME_TargetBottomPixel - (ME_TargetBottomPixel-ME_TargetTopPixel)*(t.globalMaxValue-laneMinValue)/(laneMaxValue-laneMinValue) - zoneWidth/2
            minValuePixel = ME_TargetBottomPixel - (ME_TargetBottomPixel-ME_TargetTopPixel)*(t.globalMinValue-laneMinValue)/(laneMaxValue-laneMinValue) + zoneWidth/2
            if minValuePixel - maxValuePixel < zoneWidth*3 then maxValuePixel = (minValuePixel+maxValuePixel)/2 - zoneWidth*1.5 end
            if maxValuePixel <= ME_TargetTopPixel    then maxValuePixel = ME_TargetTopPixel end
            if minValuePixel - maxValuePixel <= zoneWidth*3 then minValuePixel = maxValuePixel + zoneWidth*3 end
            if minValuePixel >= ME_TargetBottomPixel then minValuePixel = ME_TargetBottomPixel end
            if minValuePixel - maxValuePixel <= zoneWidth*3 then maxValuePixel = minValuePixel - zoneWidth*3 end
            minValuePixel, maxValuePixel = minValuePixel//1, maxValuePixel//1
        end
        tZones[#tZones+1] = {func = Defer_Scale,          wheel = Edit_FlipValuesRelative,     tooltip = "Scale top",      cursor = cursorHandTop,     color = "scale", 
                             left = left,     right = right, top = maxValuePixel,    bottom = maxValuePixel+zoneWidth-1,
                             activeTop = ME_TargetTopPixel} --activeLeft = -1/0, activeRight = 1/0}
        tZones[#tZones+1] = {func = Defer_Scale,          wheel = Edit_FlipValuesRelative,     tooltip = "Scale bottom",   cursor = cursorHandBottom,  color = "scale", 
                              left = left,    right = right, top = minValuePixel-zoneWidth+1, bottom = minValuePixel,
                              activeBottom = ME_TargetBottomPixel} --activeLeft = -1/0, activeRight = 1/0}    
        
        -- Stretch
        -- Make sure that the Stretch zones are always visible and separate, even if the pixel range of the selected events is tiny.
        --local leftStretchPixel, rightStretchPixel = GUI_LeftPixel+zoneWidth*2-1, GUI_RightPixel-zoneWidth*2
        --if rightStretchPixel - leftStretchPixel < 0 then leftStretchPixel, rightStretchPixel = (leftStretchPixel+rightStretchPixel)//2, (leftStretchPixel+rightStretchPixel)//2+1 end
        local stretchTopPixel     = maxValuePixel+zoneWidth --(maxValuePixel > ME_TargetTopPixel+zoneWidth+1) and maxValuePixel or (maxValuePixel+zoneWidth+1)
        local stretchBottomPixel  = minValuePixel-zoneWidth --(minValuePixel < ME_TargetBottomPixel-zoneWidth-1) and minValuePixel or (minValuePixel-zoneWidth-1)
        tZones[#tZones+1] = {func = Defer_Stretch_Left,   wheel = Edit_Reverse,               tooltip = "Stretch left",   cursor = cursorHandLeft,    color = "stretch", 
                             left = GUI_LeftPixel+zoneWidth,       right = GUI_LeftPixel+zoneWidth*2-1, 
                             top  = stretchTopPixel, bottom = stretchBottomPixel,
                             activeTop = ME_TargetTopPixel, activeBottom = ME_TargetBottomPixel, activeLeft = -1/0}
        tZones[#tZones+1] = {func = Defer_Stretch_Right,  wheel = Edit_Reverse,               tooltip = "Stretch right",  cursor = cursorHandRight,   color = "stretch", 
                             left = GUI_RightPixel-zoneWidth*2+1,    right = GUI_RightPixel-zoneWidth,                        
                             top  = stretchTopPixel, bottom = stretchBottomPixel,
                             activeTop = ME_TargetTopPixel, activeBottom = ME_TargetBottomPixel, activeRight = 1/0}         
        
        -- Warp
        if (GUI_RightPixel - GUI_LeftPixel) > zoneWidth*4 then
            tZones[#tZones+1] = {func = Defer_Warp,           wheel = Edit_Reverse,   tooltip = "Warp",           cursor = cursorArpeggiateLR,color = "warp", 
                                 left = GUI_LeftPixel+zoneWidth*2, right = GUI_RightPixel-zoneWidth*2, top = stretchTopPixel, bottom = stretchBottomPixel}
        end  
        
        -- Compress top/bottom
        left, right = GUI_LeftPixel+3*zoneWidth, GUI_RightPixel-3*zoneWidth
        if right-left < 2*zoneWidth then left, right = GUI_MidPixel-zoneWidth, GUI_MidPixel+zoneWidth end
        tZones[#tZones+1] = {func = Defer_Compress,   wheel = Edit_FlipValuesAbsolute,   tooltip = "Scale top",      cursor = cursorCompress,    color = "compress", 
                              left = left,  right = right,  top = ME_TargetTopPixel-zoneWidth-1, bottom = ME_TargetTopPixel-1,
                              activeLeft = -1/0, activeRight = 1/0}
        tZones[#tZones+1] = {func = Defer_Compress,   wheel = Edit_FlipValuesAbsolute,   tooltip = "Scale bottom",   cursor = cursorCompress,    color = "compress", 
                              left = left,  right = right,  top = ME_TargetBottomPixel+1, bottom = ME_TargetBottomPixel+zoneWidth+1,
                              activeLeft = -1/0, activeRight = 1/0}  
                  
    else
        local bottom, top = ME_TargetBottomPixel, ME_TargetTopPixel
        if bottom - top < 2*zoneWidth then
            local midPixel = (bottom + top)//2
            bottom, top = midPixel+40, midPixel-40
        end
        
        -- Undo/Redo     
        local undoTop, undoBottom = top-zoneWidth-1, top-1
        if undoTop < 0 then
            undoTop, undoBottom = bottom+1, bottom+zoneWidth+1
        end   
        tZones[#tZones+1] = {func = Defer_Undo,         wheel = Defer_Undo,       tooltip = "Undo",   cursor = cursorUndo,    color = (#tSteps > 0) and "undo" or "black", 
                              left = undoLeft,  right = undoLeft+zoneWidth,  top = undoTop, bottom = undoBottom}                  
        tZones[#tZones+1] = {func = Defer_Redo,         wheel = Defer_Redo,       tooltip = "Redo",   cursor = cursorRedo,    color = (#tRedo > 0) and "redo" or "black", 
                              left = undoLeft+zoneWidth+1, right = undoLeft+2*zoneWidth+1,  top = undoTop, bottom = undoBottom}                  
        -- Stretch
        tZones[#tZones+1] = {func = Defer_Stretch_Left,   wheel = Edit_Reverse,   tooltip = "Stretch left",   cursor = cursorHandLeft,    color = "stretch", 
                              left = GUI_LeftPixel+zoneWidth, right = GUI_LeftPixel+zoneWidth*2-1,   top = top, bottom = bottom,
                              activeLeft = -1/0}
        tZones[#tZones+1] = {func = Defer_Stretch_Right,  wheel = Edit_Reverse,   tooltip = "Stretch right",  cursor = cursorHandRight,   color = "stretch", 
                              left = GUI_RightPixel-zoneWidth*2+1,    right = GUI_RightPixel-zoneWidth,   top = top, bottom = bottom,
                              activeRight = 1/0}
        -- Warp
        tZones[#tZones+1] = {func = Defer_Warp,           wheel = Edit_Reverse,   tooltip = "Warp",           cursor = cursorArpeggiateLR,color = "warp", 
                              left = GUI_LeftPixel+zoneWidth*2, right = GUI_RightPixel-zoneWidth*2, top = top, bottom = bottom}
    end    
    reaper.JS_LICE_Clear(bitmap, 0)
    for _, z in ipairs(tZones) do
        local color = tColors[z.color]
        reaper.JS_LICE_FillRect(bitmap, z.left//1, z.top//1, (z.right-z.left)//1, (z.bottom-z.top)//1, color, 1, "COPY")
        color = winOS and ((color>>3)&0x1F1F1F1F) or (color&0x1FFFFFFF)
        reaper.JS_LICE_FillRect(bitmap, (z.left+1)//1, (z.top+1)//1, (z.right-z.left-2)//1, (z.bottom-z.top-2)//1, color, 1, "COPY")
    end
    
    reaper.JS_Window_InvalidateRect(midiview, 0, 0, ME_midiviewWidth, ME_midiviewHeight, false) --GUI_LeftPixel-zoneWidth, ME_TargetTopPixel-zoneWidth, GUI_RightPixel+zoneWidth, ME_TargetBottomPixel+zoneWidth, false)

end


--local zone, prevZone
--####################
----------------------
function Defer_Zones()

    -- continueStep = true means that a deferred function is already running, so no need for GUI setup
    if not (continueStep == "CONTINUE") then
        SetupDisplayZones()
        stepStartTime = thisDeferTime
    end
    
    -- FIND ZONE
    prevZone = zone or false
    zone = nil
    if 0 <= mouseX and mouseX < ME_midiviewWidth and 0 <= mouseY and mouseY < ME_midiviewHeight+zoneWidth then -- Add a little leeway at bottom, in case a compress zone is hidden behind scrollbar
        for _, z in ipairs(tZones) do
            if (z.activeLeft or z.left) <= mouseX and mouseX <= (z.activeRight or z.right) and (z.activeTop or z.top) <= mouseY and mouseY <= (z.activeBottom or z.bottom) then
                zone = z
                break
            end
        end
    end
    -- MOUSE CURSOR
    if zone ~= prevZone then
        if zone and zone.cursor then
            --Tooltip(zone.tooltip) -- tooltips seem to flicker when compositing is used
            cursor = zone.cursor
        else
            cursor = cursorNo
        end
        if cursor then reaper.JS_Mouse_SetCursor(cursor) end
    end
    -- MOUSEWHEEL
    local peekOK, pass, time, keys, delta = reaper.JS_WindowMessage_Peek(windowUnderMouse, "WM_MOUSEWHEEL")
    if not (peekOK and time > prevMouseTime) then 
        peekOK, pass, time, keys, delta = reaper.JS_WindowMessage_Peek(windowUnderMouse, "WM_MOUSEHWHEEL")
    end 
    if peekOK and time > prevMouseTime + 0.2 then 
        prevMouseTime = time
        if zone and zone.wheel then 
            selectedEditFunction = zone.wheel
            --reaper.JS_LICE_Clear(bitmap, 0)
            --reaper.JS_Window_InvalidateRect(midiview, 0, 0, ME_midiviewWidth, ME_midiviewHeight, false)
            return "NEXT", zone.wheel
        else
            return "QUIT"
        end
    end
    -- LEFT CLICK: Run the function linked to zone under mouse
    peekOK, pass, time = reaper.JS_WindowMessage_Peek(windowUnderMouse, "WM_LBUTTONDOWN")
    if not (peekOK and time > stepStartTime) then
        peekOK, pass, time = reaper.JS_WindowMessage_Peek(windowUnderMouse, "WM_NCLBUTTONDOWN")
    end
    if peekOK and time > stepStartTime then --prevMouseTime then
        if zone then 
            selectedEditFunction = zone.func
            reaper.JS_LICE_Clear(bitmap, 0)
            --reaper.JS_Window_InvalidateRect(midiview, 0, 0, ME_midiviewWidth, ME_midiviewHeight, false)
            return "NEXT", zone.func
        else
            return "QUIT"
        end
    end
    -- RIGHT CLICK: Context menu
    if (mouseState&2) > (prevMouseState&2) then
        if zone then 
            selectedEditFunction = ContextMenu
            return "NEXT", ContextMenu
        end
    end

    return "CONTINUE"
end


local selectedEditFunction = nil  
--############################################################################################
----------------------------------------------------------------------------------------------
-- Why are the deferred editing functions isolated behind a pcall?
--    If the script encounters an error, all intercepts must first be released, before the script quits.
-- Deferred and other Edit script can return three values: 
--    "CONTINUE" to continue with same function in the next defer cycle,
--    "NEXT" to proceed to show zones and select a new edit function, and
--    "QUIT" to terminate the script.
function DEFER_pcall()  

    local nextFunction
    pcallOK, continueScript = pcall(Check_CommonQuitConditionsAndGetInputs)
    if pcallOK and continueScript then
        pcallOK, continueStep, nextFunction = pcall(selectedEditFunction or Defer_Zones)
        if pcallOK and not (continueStep == "QUIT") then
            selectedEditFunction = (continueStep == "CONTINUE") and selectedEditFunction or nextFunction or Defer_Zones
            reaper.defer(DEFER_pcall)
        end
    end
end


--##########################################################################
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
    cursor = reaper.JS_Mouse_LoadCursor(32512) -- IDC_ARROW standard arrow
    if cursor then reaper.JS_Mouse_SetCursor(cursor) end
    
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
        -- DEFER_pcall was executed, but exception encountered:
        if pcallOK == false then
            if MIDIString then reaper.MIDI_SetAllEvts(activeTake, MIDIString) end -- Restore original MIDI
            reaper.MB("The script encountered an error:\n\n"
                    .. tostring(continueStep or continue or pcallRetval)
                    --.."\n\nPlease report these details in the \"MIDI Editor Tools\" thread in the REAPER forums."
                    .."\n\n* The original, unaltered MIDI has been restored to the take."
                    , "ERROR", 0)
        -- DEFER_pcall and DeleteExistingCCsInRange were executed, and no exceptions encountered:
        elseif pcallOK == true then  
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
    end -- if reaper.ValidatePtr2(0, "MediaItem_Take*", activeTake) and reaper.TakeIsMIDI(activeTake)    
                  
                  
    -- Write nice, informative Undo strings
    if laneIsCC7BIT then
        undoString = "Multi tool: 7-bit CC lane ".. tostring(mouseOrigCCLane)
    elseif laneIsCHANPRESS then
        undoString = "Multi tool: channel pressure"
    elseif laneIsCC14BIT then
        undoString = "Multi tool: 14 bit-CC lanes ".. 
                                  tostring(mouseOrigCCLane-256) .. "/" .. tostring(mouseOrigCCLane-224)
    elseif laneIsPITCH then
        undoString = "Multi tool: pitchwheel events"
    elseif laneIsNOTES then
        undoString = "Multi tool: notes"
    elseif laneIsTEXT then
        undoString = "Multi tool: text events"
    elseif laneIsSYSEX then
        undoString = "Multi tool: sysex events"
    elseif laneIsPROGRAM then
        undoString = "Multi tool: program select events"
    elseif laneIsBANKPROG then
        undoString = "Multi tool: bank/program select events"
    elseif laneIsBANKPROG then
        undoString = "Multi tool: all lanes"
    else
        undoString = "Multi tool"
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
    if editor and reaper.MIDIEditor_GetMode(editor) ~= -1 then
        curForegroundWindow = reaper.JS_Window_GetForeground()
        if not (curForegroundWindow and reaper.JS_Window_GetTitle(curForegroundWindow) == reaper.JS_Localize("ReaScript task control", "common")) then
            reaper.JS_Window_SetForeground(editor)
            if midiview and reaper.ValidatePtr(midiview, "HWND") then reaper.JS_Window_SetFocus(midiview) end
    end end           
    
end -- function AtExit   



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
                                          if type(laneType) ~= "number" or laneType == 0xFFFF then
                                              laneIsALL = true
                                          elseif laneType == -1 then
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
                                              laneIsBANKPROG, laneMinValue, laneMaxValue = true, 0, 127
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

    if tME_Lanes[laneID] then
        ME_TargetTopPixel = tME_Lanes[laneID].ME_TopPixel
        ME_TargetBottomPixel = tME_Lanes[laneID].ME_BottomPixel
        --if not (ME_TargetTopPixel and ME_TargetBottomPixel) or (ME_TargetBottomPixel - ME_TargetTopPixel < 
        local laneType = tME_Lanes[laneID].laneType
        
        local ok = SetupIndividualLane[laneType]
        
        return ok, laneType
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
    tME_Lanes[-1]   = {laneType = -1, inlineHeight = 100} -- inlineHeight is not accurate, but will simply be used to indicate that this "lane" is large enough to be visible.
    tME_Lanes[-1.5] = {laneType = "ruler", inlineHeight = 100}
    for vellaneStr in activeTakeChunk:gmatch("\nVELLANE [^\n]+") do 
        local laneType, ME_Height, inlineHeight = vellaneStr:match("VELLANE (%S+) (%d+) (%d+)")
        -- Lane number as used in the chunk differ from those returned by API functions such as MIDIEditor_GetSetting_int(editor, "last_clicked")
        laneType, ME_Height, inlineHeight = ConvertCCTypeChunkToAPI(tonumber(laneType)), tonumber(ME_Height), tonumber(inlineHeight)
        if not (laneType and ME_Height and inlineHeight) then
            reaper.MB("Could not parse the VELLANE fields in the item state chunk.", "ERROR", 0)
            return(false)
        end    
        laneID = laneID + 1   
        tME_Lanes[laneID] = {VELLANE = vellaneStr, laneType = laneType, ME_Height = ME_Height, inlineHeight = inlineHeight}
        tME_Lanes[laneID-0.5] = {laneType = "divider", ME_Height = 9, inlineHeight = 8}
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
            if ME_midiviewWidth < 100 or ME_midiviewHeight < 100 then reaper.MB("The MIDI editor is too small for editing with the mouse", "ERROR", 0) return false end
        
        -- Now that we have the MIDI editor width, can calculate rightmost tick
        if ME_TimeBase == "beats" then
            ME_RightmostTick = ME_LeftmostTick + (ME_midiviewWidth-1)/ME_PixelsPerTick
        else
            ME_RightmostTick = reaper.MIDI_GetPPQPosFromProjTime(activeTake, ME_LeftmostTime + (ME_midiviewWidth-1)/ME_PixelsPerSecond)
        end
        
        -- And now, calculate top and bottom pixels of each lane -- AND lane divider
        local laneBottomPixel = ME_midiviewHeight-1
        for i = #tME_Lanes, 0, -1 do
            tME_Lanes[i].ME_BottomPixel = laneBottomPixel
            tME_Lanes[i].ME_TopPixel    = laneBottomPixel - tME_Lanes[i].ME_Height + 10
            tME_Lanes[i-0.5].ME_BottomPixel = tME_Lanes[i].ME_TopPixel - 1
            tME_Lanes[i-0.5].ME_TopPixel    = tME_Lanes[i].ME_TopPixel - 9
            laneBottomPixel = laneBottomPixel - tME_Lanes[i].ME_Height
        end
        
        -- Notes area height is remainder after deducting 1) total CC lane height and 2) height (62 pixels) of Ruler/Marker/Region area at top of midiview
        tME_Lanes[-1].ME_BottomPixel = laneBottomPixel
        tME_Lanes[-1].ME_TopPixel    = 62
        tME_Lanes[-1].ME_Height      = laneBottomPixel-61
        ME_BottomPitch = ME_TopPitch - math.floor(tME_Lanes[-1].ME_Height / ME_PixelsPerPitch)
        
        -- Ruler/Marker/Region
        tME_Lanes[-1.5].ME_BottomPixel = 61
        tME_Lanes[-1.5].ME_TopPixel    = 0
        tME_Lanes[-1.5].ME_Height      = 62
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


--[[ Why parse using two passes?  
        1) In order to improve responsiveness, the script must display zones as quickly as possible. Zones require only global left/right positions and values.
        2) If every individual event is separated into a separate table entry in tMIDI, concatenation will be much slower.  
            Therefore, only events that may be altered by the script will be separated.  This include unselected CCs that fall in the same channel 
            as selected CCs, and that may therefore be deleted while stretching, if they overlap with the stretched selected CCs. 
            In order to know which channels contain selected CCs, the selected CCs must first be parsed, *after* which the unselected ones can be parsed in a second pass.
]]
--############################
------------------------------
function ParseMidi_FirstPass()
    local i = -1 
    local tGroups = tGroups
    origValueMin, origValueMax = math.huge, -math.huge
    
    if laneIsALL then
    
        do ::getNextEvt::
            i = reaper.MIDI_EnumSelEvts(activeTake, i)
            if i == -1 then 
                goto gotAllEvts 
            else
                local ok, selected, muted, ppqpos, msg = reaper.MIDI_GetEvt(activeTake, i, true, false, 0, "")
                local status = msg:byte(1)&0xF0
                if msg:byte(1) == 0xFF then
                    if not tGroups.text then tGroups.text = {tT = {}, tA = {}, tI = {}, tM = {}, tM2 = {}, tV = {}, tT = {}, tC = {}, tF = {}, tF2 = {}, tP = {}, tOff = {}, tQ = {}, tD = {}} end
                elseif status == 0xF0 then
                    if not tGroups.sysex then tGroups.sysex = {tT = {}, tA = {}, tI = {}, tM = {}, tM2 = {}, tV = {}, tT = {}, tC = {}, tF = {}, tF2 = {}, tP = {}, tOff = {}, tQ = {}, tD = {}} end
                elseif status == 0x90 then
                    if not tGroups.notes then tGroups.notes = {tT = {}, tA = {}, tI = {}, tM = {}, tM2 = {}, tV = {}, tT = {}, tC = {}, tF = {}, tF2 = {}, tP = {}, tOff = {}, tQ = {}, tD = {}} end
                elseif status == 0xB0 then
                    if not tGroups[msg:sub(1,2)] then tGroups[msg:sub(1,2)] = {tT = {}, tA = {}, tI = {}, tM = {}, tM2 = {}, tV = {}, tT = {}, tC = {}, tF = {}, tF2 = {}, tP = {}, tOff = {}, tQ = {}, tD = {}} end
                elseif status > 0xB0 then
                    if not tGroups[msg:byte(1)] then tGroups[msg:byte(1)] = {tT = {}, tA = {}, tI = {}, tM = {}, tM2 = {}, tV = {}, tT = {}, tC = {}, tF = {}, tF2 = {}, tP = {}, tOff = {}, tQ = {}, tD = {}} end                           
                end
                origTickLeftmost    = origTickLeftmost or ppqpos
                origTickRightmost   = ppqpos
                goto getNextEvt
            end
        ::gotAllEvts:: end
        
        --[[ Quickly check if there are any selected notes and text/sysex
        if reaper.MIDI_EnumSelNotes(activeTake, -1) ~= -1 then tGroups.notes = {tT = {}, tA = {}, tI = {}, tM = {}, tM2 = {}, tV = {}, tT = {}, tC = {}, tF = {}, tF2 = {}, tP = {}, tOff = {}, tQ = {}, tD = {}} end
        if reaper.MIDI_EnumSelTextSysexEvts(activeTake, -1) ~= -1 then tGroups.text = {tT = {}, tA = {}, tI = {}, tM = {}, tM2 = {}, tV = {}, tT = {}, tC = {}, tF = {}, tF2 = {}, tP = {}, tOff = {}, tQ = {}, tD = {}} end
        
        -- Must iterate through all selected CCs, since they are separated into groups
        do ::getNextCC::
            i = reaper.MIDI_EnumSelCC(activeTake, i)
            if i == -1 then 
                goto gotAllCCs
            else
                local OK, selected, muted, ppqpos, chanmsg, chan, msg2, msg3 = reaper.MIDI_GetCC(activeTake, i)
                local group = (chanmsg == 0xB0) and string.char(chanmsg|chan, msg2) or (chanmsg|chan)
                if not tGroups[group] then tGroups[group] = {tT = {}, tA = {}, tI = {}, tM = {}, tM2 = {}, tV = {}, tT = {}, tC = {}, tF = {}, tF2 = {}, tP = {}, tOff = {}, tQ = {}, tD = {}} end
                goto getNextCC
            end
        ::gotAllCCs:: end
        
        -- Get first and last selected event (which may, for example, be a note's note-off)
        local firstEvt = reaper.MIDI_EnumSelEvts(activeTake, -1)
        local lastEvt  = firstEvt
        do ::getNextEvt::
            local i = reaper.MIDI_EnumSelEvts(activeTake, lastEvt)
            if i ~= -1 then 
                lastEvt = i 
                goto getNextEvt
            else
                goto gotAllEvts
            end
        ::gotAllEvts:: end
        
        -- laneIsALL only needs global left and right positions, not any global values
        local ok, selected, muted, ppqpos, msg = reaper.MIDI_GetEvt(activeTake, firstEvt, true, false, 0, "")
        if ok then origTickLeftmost = ppqpos end
        local ok, selected, muted, ppqpos, msg = reaper.MIDI_GetEvt(activeTake, lastEvt, true, false, 0, "")
        if ok then origTickRightmost = ppqpos end
        ]]

    elseif laneIsNOTES then
    
        origTickLeftmost, origNoteOffTick = nil, -math.huge
        tGroups.notes = {tT = {}, tA = {}, tI = {}, tM = {}, tM2 = {}, tV = {}, tT = {}, tC = {}, tF = {}, tF2 = {}, tP = {}, tOff = {}, tQ = {}, tD = {}}
        do ::getNextNote:: 
            i = reaper.MIDI_EnumSelNotes(activeTake, i)
            if i == -1 then 
                goto gotAllNotes
            else
                local retval, selected, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote(activeTake, i)
                origTickLeftmost    = origTickLeftmost or startppqpos
                origValueLeftmost   = origValueLeftmost or vel
                origTickRightmost   = ppqpos
                if endppqpos > origNoteOffTick then 
                    origNoteOffTick   = endppqpos 
                    origValueRightmost  = vel
                end 
                if vel > origValueMax then origValueMax = vel end
                if vel < origValueMin then origValueMin = vel end
                goto getNextNote
            end
        ::gotAllNotes:: end
        
    elseif laneIsCC7BIT or laneIsCC14BIT then
    
        local ccType = laneIsCC14BIT and (mouseOrigCCLane-256) or mouseOrigCCLane -- Since we are only interested in finding ticks positions and used channels, no need to get LSB for 14 bit CCs
        do ::getNextCC::
            i = reaper.MIDI_EnumSelCC(activeTake, i)
            if i == -1 then 
                goto gotAllCCs
            else
                local OK, selected, muted, ppqpos, chanmsg, chan, msg2, msg3 = reaper.MIDI_GetCC(activeTake, i)
                if msg2 == ccType and chanmsg == 0xB0 then --and (editAllChannels or chan == activeChannel) then 
                    if not tGroups[chan] then tGroups[chan] = {tT = {}, tA = {}, tI = {}, tM = {}, tM2 = {}, tV = {}, tT = {}, tC = {}, tF = {}, tF2 = {}, tP = {}, tOff = {}, tQ = {}, tD = {}, tChase = {}} end
                    origValueLeftmost   = origValueLeftmost or msg3
                    origValueRightmost  = msg3
                    origTickLeftmost    = origTickLeftmost or ppqpos
                    origTickRightmost   = ppqpos
                    if msg3 > origValueMax then origValueMax = msg3 end
                    if msg3 < origValueMin then origValueMin = msg3 end
                    
                    --[[if not origValueLeftmost or (ppqpos == origTickLeftmost and chan == activeChan) then
                        origValueLeftmost   = msg3
                        origTickLeftmost    = ppqpos
                    end
                    if (chan == activeChan or ppqpos ~= origTickRightmost) then
                        origValueRightmost  = msg3
                        origTickRightmost   = ppqpos
                    end
                    ]]
                    --[[if tGroups[chan] then 
                        tGroups[chan].right = ppqpos 
                    else 
                        --tGroups[chan] = {left = ppqpos, right = ppqpos, tTicks = {}, tPrevTicks = {}, tIndices = {}, tMsg = {}, tMsg2 = {}, tValues = {}, tTicks = {}, tChannels = {}, tFlags = {}, tFlags2 = {}, tPitches = {}, tLengths = {}, tMeta = {}, tDelete = {}} 
                        tGroups[chan] = {left = ppqpos, right = ppqpos, tT = {}, tA = {}, tI = {}, tM = {}, tM2 = {}, tV = {}, tT = {}, tC = {}, tF = {}, tF2 = {}, tP = {}, tOff = {}, tQ = {}, tD = {}} 
                        
                    end]]
                end
                goto getNextCC
            end
        ::gotAllCCs:: end
        if laneIsCC14BIT and origValueLeftmost then origValueLeftmost, origValueRightmost, origValueMin, origValueMax = origValueLeftmost<<7, origValueRightmost<<7, origValueMin<<7, origValueMax<<7 end
        
    elseif laneIsPROGRAM then
    
        do ::getNextCC::
            i = reaper.MIDI_EnumSelCC(activeTake, i)
            if i == -1 then 
                goto gotAllCCs
            else
                local OK, selected, muted, ppqpos, chanmsg, chan, msg2 = reaper.MIDI_GetCC(activeTake, i)
                if chanmsg == 0xC0 then 
                    if not tGroups[chan] then tGroups[chan] = {tT = {}, tA = {}, tI = {}, tM = {}, tM2 = {}, tV = {}, tT = {}, tC = {}, tF = {}, tF2 = {}, tP = {}, tOff = {}, tQ = {}, tD = {}, tChase = {}} end
                    origValueLeftmost   = origValueLeftmost or msg2
                    origValueRightmost  = msg2
                    origTickLeftmost    = origTickLeftmost or ppqpos
                    origTickRightmost   = ppqpos
                    if msg2 > origValueMax then origValueMax = msg2 end
                    if msg2 < origValueMin then origValueMin = msg2 end
                end
                goto getNextCC
            end
        ::gotAllCCs:: end
        
    elseif laneIsCHANPRESS then
    
        do ::getNextCC::
            i = reaper.MIDI_EnumSelCC(activeTake, i)
            if i == -1 then 
                goto gotAllCCs
            else
                local OK, selected, muted, ppqpos, chanmsg, chan, msg2 = reaper.MIDI_GetCC(activeTake, i)
                if chanmsg == 0xD0 then 
                    if not tGroups[chan] then tGroups[chan] = {tT = {}, tA = {}, tI = {}, tM = {}, tM2 = {}, tV = {}, tT = {}, tC = {}, tF = {}, tF2 = {}, tP = {}, tOff = {}, tQ = {}, tD = {}, tChase = {}} end
                    origValueLeftmost   = origValueLeftmost or msg2
                    origValueRightmost  = msg2
                    origTickLeftmost    = origTickLeftmost or ppqpos
                    origTickRightmost   = ppqpos
                    if msg2 > origValueMax then origValueMax = msg2 end
                    if msg2 < origValueMin then origValueMin = msg2 end
                end
                goto getNextCC
            end
        ::gotAllCCs:: end
        
    elseif laneIsPITCH then
    
        do ::getNextCC::
            i = reaper.MIDI_EnumSelCC(activeTake, i)
            if i == -1 then 
                goto gotAllCCs
            else
                local OK, selected, muted, ppqpos, chanmsg, chan, msg2, msg3 = reaper.MIDI_GetCC(activeTake, i)
                if chanmsg == 0xE0 then --and (editAllChannels or chan == activeChannel) then 
                    local value = ((msg3<<7) | msg2)
                    if not tGroups[chan] then tGroups[chan] = {tT = {}, tA = {}, tI = {}, tM = {}, tM2 = {}, tV = {}, tT = {}, tC = {}, tF = {}, tF2 = {}, tP = {}, tOff = {}, tQ = {}, tD = {}, tChase = {}} end
                    origValueLeftmost   = origValueLeftmost or value
                    origValueRightmost  = value
                    origTickLeftmost    = origTickLeftmost or ppqpos
                    origTickRightmost   = ppqpos
                    if value > origValueMax then origValueMax = value end
                    if value < origValueMin then origValueMin = value end
                end
                goto getNextCC
            end
        ::gotAllCCs:: end
        
    elseif laneIsTEXT then
        
        do ::getNextEvt::
            i = reaper.MIDI_EnumSelEvts(activeTake, i)
            if i == -1 then 
                goto gotAllEvts 
            else
                local ok, selected, muted, ppqpos, msg = reaper.MIDI_GetEvt(activeTake, i, true, false, 0, "")
                if msg:byte(1) == 0xFF and msg:byte(2) ~= 0xF then
                    if not tGroups.text then tGroups.text = {tT = {}, tA = {}, tI = {}, tM = {}, tM2 = {}, tV = {}, tT = {}, tC = {}, tF = {}, tF2 = {}, tP = {}, tOff = {}, tQ = {}, tD = {}} end
                    origTickLeftmost    = origTickLeftmost or ppqpos
                    origTickRightmost   = ppqpos
                end
                goto getNextEvt
            end
        ::gotAllEvts:: end

    elseif laneIsSYSEX then
        
        do ::getNextEvt::
            i = reaper.MIDI_EnumSelEvts(activeTake, i)
            if i == -1 then 
                goto gotAllEvts 
            else
                local ok, selected, muted, ppqpos, msg = reaper.MIDI_GetEvt(activeTake, i, true, false, 0, "")
                if msg:byte(1)&0xF0 == 0xF0 and msg:byte(1) ~= 0xFF then
                    if not tGroups.sysex then tGroups.sysex = {tT = {}, tA = {}, tI = {}, tM = {}, tM2 = {}, tV = {}, tT = {}, tC = {}, tF = {}, tF2 = {}, tP = {}, tOff = {}, tQ = {}, tD = {}} end
                    origTickLeftmost    = origTickLeftmost or ppqpos
                    origTickRightmost   = ppqpos
                end
                goto getNextEvt
            end
        ::gotAllEvts:: end
        
    elseif laneIsBANKPROG then
    
        do ::getNextCC::
            i = reaper.MIDI_EnumSelCC(activeTake, i)
            if i == -1 then 
                goto gotAllCCs
            else
                local OK, selected, muted, ppqpos, chanmsg, chan, msg2, msg3 = reaper.MIDI_GetCC(activeTake, i)
                local id
                if chanmsg == 0xC0 then -- Program
                    id = chanmsg|chan
                elseif chanmsg == 0xB0 and msg2 == 0 then -- Bank select
                    id = string.char(chanmsg|chan, msg2)
                end
                if id then
                    if not tGroups[id] then tGroups[id] = {tT = {}, tA = {}, tI = {}, tM = {}, tM2 = {}, tV = {}, tT = {}, tC = {}, tF = {}, tF2 = {}, tP = {}, tOff = {}, tQ = {}, tD = {}} end
                    origTickLeftmost    = origTickLeftmost or ppqpos
                    origTickRightmost   = ppqpos
                end
                goto getNextCC
            end
        ::gotAllCCs:: end
    
    end
    
    origTickRightmost = origTickRightmost or origNoteOffTick
    origNoteOffTick   = origNoteOffTick or origTickRightmost
    if origValueMin > origValueMax then
        origValueMin, origValueMax = laneMinValue, laneMaxValue
    end 
    tSteps[0] = { globalMinValue    = origValueMin,       globalMaxValue    = origValueMax,
                  globalLeftTick    = origTickLeftmost,   globalRightTick   = origTickRightmost, 
                  globalLeftValue   = origValueLeftmost,  globalRightValue  = origValueRightmost,
                  globalNoteOffTick = origNoteOffTick}
end


--##########################################################################
----------------------------------------------------------------------------
--[[ Why parse using two passes?  
        1) In order to improve responsiveness, the script must display zones as quickly as possible. Zones require only global left/right positions and values.
        2) If every individual event is separated into a separate table entry in tMIDI, concatenation will be much slower.  
            Therefore, only events that may be altered by the script will be separated.  This include unselected CCs that fall in the same channel 
            as selected CCs, and that may therefore be deleted while stretching, if they overlap with the stretched selected CCs. 
            In order to know which channels contain selected CCs, the selected CCs must first be parsed, *after* which the unselected ones can be parsed in a second pass.
]]
function ParseMidi_SecondPass()

    getAllEvtsOK, MIDIString = reaper.MIDI_GetAllEvts(activeTake, "")
        if not getAllEvtsOK then reaper.MB("MIDI_GetAllEvts could not load the raw MIDI data.", "ERROR", 0) return "QUIT" end
      
    local tMIDI = tMIDI
    -- The abstracted info of targeted MIDI events (that will be edited) will be will be stored in
    --    several new tables such as tTicks and tValues.
    --[[ Clean up these tables in case starting again after sorting.
    local tI  = tIndices -- Indices of target events inside tMIDI -- will not change during editing
    local tO  = tPrevTicks -- Original offsets to events -- will not change during editing
    local tT  = tTicks -- Tick position of edited events -- tSteps[0] contain the original tick positions
    local tM  = tMsg
    local tM2 = tMsg2
    local tV  = tValues -- CC values, 14bit CC combined values, note velocities
    local tC  = tChannels
    local tF  = tFlags
    local tF2 = tFlags2 -- Flags of second event of multi-part events: 14bit CC LSB, or note note-offs.
    local tP  = tPitches -- This table will only be filled if laneIsVELOCITY / laneIsPIANOROLL / laneIsOFFVEL / laneIsNOTES
    local tOff  = tLengths -- Not lengths.  When editing all, lanes, will only be filled at indices that refer to notes.
    local tQ  = tMeta -- Meta events such as notation or Bézier tension.  Will only be filled at indices where notes have notation or CCs have tension.
    local e = 0]]
    
    -- This script does not scroll the MIDI editor if the mouse moves out of the client area, so the only CCs that
    --    may need to be deleted, are those visible in the editor. Only those will be separated into entries in tMIDI.
    local leftTickLimit = math.min(origTickLeftmost, ME_LeftmostTick)
    local rightTickLimit = math.max(origTickRightmost, ME_RightmostTick) -- !!!!!!!!!!!!!!!!! length 
    
    -- Store LSB and MSB info in this table, so that can be combined with next matching CC while parsing.
    local t14 = {}
    local tNotes = {}
    for chan = 0, 15 do 
        t14[chan], tNotes[chan] = {}, nil --{} 
    end        
  
    -- The entire MIDI string does not need to be parsed.  
    -- Instead, go on till ticks reached beyond rightTickLimit, *and* got at least one further event that can be chased in each group.
    local tBeyond = {}
    for grp, t in pairs(tGroups) do
        if not (grp == "sysex" or grp == "text") then
            tBeyond[grp] = true
        end
    end
    --[[ Store note-on info
    local tNotes = {}
    if laneIsVELOCITY or laneIsPIANOROLL or laneIsOFFVEL then   
        for chan = 0, 15 do 
            tNotes[chan] = {} 
            for pitch = 0, 127 do
                tNotes[chan][pitch] = {}
            end
        end
    end]]
    
    local prevPos, savePos = 1, 1 -- Position inside MIDI string while parsing / Last position not yet stored in tMIDI
    local ticks = 0 -- Running PPQ position of events while parsing
    --local offset, flags, msg
    
    local MIDI, MIDILen = MIDIString, #MIDIString
    local targetLane = mouseOrigCCLane
    local s_unpack, s_pack = string.unpack, string.pack

    if laneIsALL or laneIsPIANOROLL or laneIsBANKPROG then
        local tGrpN, tGrpT, tGrpS = tGroups.notes, tGroups.text, tGroups.sysex
        while prevPos < MIDILen do
            local offset, flags, msg, pos = s_unpack("i4Bs4", MIDI, prevPos)
            ticks = ticks + offset
            if ticks > rightTickLimit then break end
            if #msg >= 2 then
                local status = msg:byte(1)&0xF0
                local tGrpCC = tGroups[  (status == 0xB0) and msg:sub(1,2) or msg:byte(1)  ] -- CCs require two byte to distinguish their group: channel + lane
                -- Text and notation
                if msg:byte(1) == 0xFF then
                    -- Notation meta
                    -- Unlike Bezier meta events, notation events don't immediately follow their correspnding notes (prior to v5.9??)
                    --    but this code assumes that notation follows *before* the note-off.
                    if offset == 0 and msg:sub(2,6) == "\15NOTE" then
                        if tGrpN then
                            local notationChannel, notationPitch = msg:match("NOTE (%d+) (%d+) ")
                            if notationChannel and notationPitch then
                                notationChannel = tonumber(notationChannel)
                                notationPitch   = tonumber(notationPitch)
                                local saved = tNotes[(notationPitch<<4) | notationChannel]
                                if saved then
                                    if savePos < prevPos then tMIDI[#tMIDI+1] = MIDI:sub(savePos, prevPos-1) end
                                    tMIDI[#tMIDI+1] = s_pack("i4Bs4", offset, 0, 0) -- Delete form tMIDI, since will be combined with note-on and note-off at note-on's entry
                                    tGrpN.tQ[saved] = MIDI:sub(prevPos, pos-1)
                                    savePos = pos
                                end
                            end
                        end
                    elseif flags&1 == 1 then 
                        if tGrpT then
                            if prevPos > savePos then tMIDI[#tMIDI+1] = MIDI:sub(savePos, prevPos-1) end
                            tMIDI[#tMIDI+1] = MIDI:sub(prevPos, pos-1) --(pos-#msg-5, pos-1)
                            savePos = pos
                            local i = #tGrpT.tT + 1
                            tGrpT.tI[i], tGrpT.tA[i] = #tMIDI, ticks-offset
                            tGrpT.tT[i], tGrpT.tM[i] = ticks, MIDI:sub(prevPos+4, pos-1)
                        end
                    end
                elseif status == 0xF0 then
                    if tGrpS and flags&1 == 1 then
                        if prevPos > savePos then tMIDI[#tMIDI+1] = MIDI:sub(savePos, prevPos-1) end
                        tMIDI[#tMIDI+1] = MIDI:sub(prevPos, pos-1)
                        savePos = pos
                        local i = #tGrpS.tT + 1
                        tGrpS.tI[i], tGrpS.tA[i] = #tMIDI, ticks-offset
                        tGrpS.tT[i], tGrpS.tM[i] = ticks, MIDI:sub(prevPos+4, pos-1)
                    end
                -- Notes
                -- Note-on
                elseif status == 0x90 and msg:byte(3) ~= 0 then
                    if tGrpN and flags&1 == 1 then
                        if savePos < prevPos then tMIDI[#tMIDI+1] = MIDI:sub(savePos, prevPos-1) end
                        tMIDI[#tMIDI+1] = ""
                        savePos = pos
                        local i = #tGrpN.tT+1
                        tGrpN.tI[i], tGrpN.tA[i] = #tMIDI, ticks-offset
                        tGrpN.tT[i], tGrpN.tM[i] = ticks, MIDI:sub(prevPos+4, pos-1)
                        local id = (msg:byte(2)<<4) | (msg:byte(1)&0x0F)
                        if tNotes[id] then 
                            reaper.MB("The script encountered overlapping notes, which cannot be parsed.\n\nOverlapping notes can be removed using the \"Correct overlapping notes\" action", "ERROR", 0)
                            return "QUIT"
                        else 
                            tNotes[id] = i 
                        end
                    end
                -- Note-off
                elseif status == 0x80 or (status == 0x90 and msg:byte(3) == 0) then
                    if tGrpN and flags&1 == 1 then
                        if savePos < prevPos then tMIDI[#tMIDI+1] = MIDI:sub(savePos, prevPos-1) end
                        tMIDI[#tMIDI+1] = s_pack("i4", offset) .. "\0\0\0\0\0" -- Delete note-off from this position. If note-off has no note-on partner, will remain deleted.
                        savePos = pos
                        local id = (msg:byte(2)<<4) | (msg:byte(1)&0x0F)
                        local saved = tNotes[id]
                        if saved then
                            tGrpN.tOff[saved] = ticks
                            --t.tF2[saved]  = flags
                            tGrpN.tM2[saved]  = MIDI:sub(prevPos+4, pos-1) --msg
                        end
                        if ticks >= origNoteOffTick then tGrpN.noteWithLastNoteOff = saved end
                        tNotes[id] = nil
                    end
                -- CCs
                elseif tGrpCC then    
                    if flags&1 == 1 then 
                        if prevPos > savePos then tMIDI[#tMIDI+1] = MIDI:sub(savePos, prevPos-1) end
                        tMIDI[#tMIDI+1] = MIDI:sub(prevPos, pos-1)
                        --local t = tGroups[msg:byte(1)]
                        local i = #tGrpCC.tT + 1
                        tGrpCC.tI[i], tGrpCC.tA[i], tGrpCC.tT[i] = #tMIDI, ticks-offset, ticks
                        if MIDI:sub(pos, pos+15) == "\0\0\0\0\0\12\0\0\0\255\15CCBZ " then 
                            tGrpCC.tM[i] = MIDI:sub(prevPos+4, pos+20) 
                            pos = pos + 21
                        else
                            tGrpCC.tM[i] = MIDI:sub(prevPos+4, pos-1)
                        end
                        savePos = pos
                    elseif leftTickLimit < ticks and ticks < rightTickLimit then
                        tMIDI[#tMIDI+1] = MIDI:sub(savePos, prevPos+3) --pos-#msg-6) -- Exclude offset, which won't change when deleting with empty event
                        tMIDI[#tMIDI+1] = MIDI:sub(prevPos+4, pos-1) --(pos-#msg-5, pos-1)
                        savePos = pos
                        tGrpCC.tD[#tGrpCC.tD+1] = {index = #tMIDI, id = msg:byte(1)&0x0F, ticks = ticks, flagsMsg = tMIDI[#tMIDI]}
                    end
                end
            end
            prevPos = pos
        end
    elseif laneIsCC7BIT then
        while prevPos < MIDILen do -- and next(tBeyond) do
            local offset, flags, msg, pos = s_unpack("i4Bs4", MIDI, prevPos)
            ticks = ticks + offset
            if #msg ~= 0 and msg:byte(2) == targetLane and (msg:byte(1))>>4 == 11 then
                local grp = msg:byte(1)&0x0F
                local t = tGroups[grp]
                if t then
                    if flags&1==1 then
                        if savePos < prevPos then tMIDI[#tMIDI+1] = MIDI:sub(savePos, prevPos-1) end --pos-#msg-10)
                        tMIDI[#tMIDI+1] = "" --if tMIDI[#tMIDI] ~= "" then tMIDI[#tMIDI+1] = "" end
                        local i = #t.tT + 1
                        if MIDI:sub(pos, pos+15) == "\0\0\0\0\0\12\0\0\0\255\15CCBZ " then t.tQ[i] = MIDI:sub(pos, pos+20) pos = pos + 21 end
                        savePos = pos
                        t.tI[i], t.tA[i] = #tMIDI, ticks-offset
                        t.tT[i], t.tF[i], t.tC[i], t.tV[i] = ticks, flags, msg:byte(1)&0x0F, msg:byte(3) -- tC not actually necessary, since ID = chan
                    else
                        if ticks < leftTickLimit then
                            t.tChase[1] = {ticks = ticks, value = msg:byte(3)} --chaseIndex = 1 --local tChase = tGroups[msg:byte(1)&0x0F].tChase[1] = {ticks = ticks, value = msg:byte(3)}
                        elseif ticks <= rightTickLimit then
                            t.tChase[#t.tChase+1] = {ticks = ticks, value = msg:byte(3)}

                            tMIDI[#tMIDI+1] = MIDI:sub(savePos, prevPos+3) --pos-#msg-6) -- Exclude offset, which won't change when deleting with empty event
                            tMIDI[#tMIDI+1] = MIDI:sub(prevPos+4, pos-1) --(pos-#msg-5, pos-1)
                            savePos = pos
                            local tD = t.tD
                            tD[#tD+1] = {index = #tMIDI, id = msg:byte(1)&0x0F, ticks = ticks, flagsMsg = tMIDI[#tMIDI]}
                        elseif tBeyond[grp] then
                            t.tChase[#t.tChase+1] = {ticks = ticks, value = msg:byte(3)}
                            tBeyond[grp] = nil
                            if not next(tBeyond) then break end
                        end
                    end
                end
            end
            prevPos = pos
        end
    elseif laneIsCC14BIT then
        local targetLaneMSB, targetLaneLSB = targetLane-256, targetLane-224
        local tRunning = {} -- Running 14-bit value.  Its MSB and LSB will be updated whenever a MSB or LSB is parsed.
        for grp in pairs(tGroups) do tRunning[grp] = 0 end
        while prevPos < MIDILen do
            local offset, flags, msg, pos = s_unpack("i4Bs4", MIDI, prevPos)
            ticks = ticks + offset
            if #msg ~= 0 and (msg:byte(1))>>4 == 11 then
                local grp = msg:byte(1)&0x0F
                local t = tGroups[grp]
                if t then
                    local lane
                    if msg:byte(2) == targetLaneMSB and "MSB" then
                        lane = "MSB"
                        tRunning[grp] = (msg:byte(3)<<7)|(tRunning[grp]&0x7F)
                    elseif msg:byte(2) == targetLaneLSB then
                        lane = "LSB"
                        tRunning[grp] = (tRunning[grp]&0xFF80)|msg:byte(3)
                    end
                    if lane then
                        if flags&1==1 then           
                            if lane == "MSB" then --msg:byte(2) == targetLaneMSB then
                                tMIDI[#tMIDI+1] = MIDI:sub(savePos, prevPos-1)
                                tMIDI[#tMIDI+1] = s_pack("i4Bs4", offset, 0, "")
                                local meta = (MIDI:sub(pos, pos+15) == "\0\0\0\0\0\12\0\0\0\255\15CCBZ ") and MIDI:sub(pos, pos+20) or nil
                                if meta then pos = pos + 21 end
                                savePos = pos                               
                                local saved = t14[grp][ticks]
                                if saved and saved.valueLSB then -- combine with saved values, store in tGroups, delete record
                                    local i = #t.tT + 1
                                    t.tI[i], t.tA[i], t.tQ[i]   = #tMIDI, ticks-offset, meta
                                    t.tT[i], t.tF[i], t.tF2[i]  = ticks, flags, saved.flagsLSB
                                    t.tC[i], t.tV[i]            = grp, (msg:byte(3)<<7)|(saved.valueLSB) -- tC not actually necessary, since ID = chan
                                    t14[grp][ticks] = nil
                                else -- save info, delete from midi string
                                    t14[grp][ticks] = {valueMSB = msg:byte(3), flagsMSB = flags, meta = meta}
                                end
                            else --if msg:byte(2) == targetLaneLSB then
                                tMIDI[#tMIDI+1] = MIDI:sub(savePos, prevPos-1)
                                tMIDI[#tMIDI+1] = s_pack("i4Bs4", offset, 0, "") -- LSB does not have envelope meta data
                                savePos = pos
                                local saved = t14[grp][ticks]
                                if saved and saved.valueMSB then -- combine with saved values, store in tGroups, delete record
                                    local i = #t.tT + 1
                                    t.tI[i], t.tA[i], t.tQ[i]   = #tMIDI, ticks-offset, saved.meta
                                    t.tT[i], t.tF[i], t.tF2[i]  = ticks, saved.flagsMSB, flags
                                    t.tC[i], t.tV[i]            = grp, ((saved.valueMSB)<<7)|msg:byte(3) -- tC not actually necessary, since ID = chan
                                    t14[grp][ticks] = nil
                                else -- save info, delete from midi string
                                    t14[grp][ticks] = {valueLSB = msg:byte(3), flagsLSB = flags}
                                end
                            end -- if msg:byte(2) == targetLaneMSB then
                        else -- Unselected
                            if ticks < leftTickLimit then
                                t.tChase[1] = {ticks = ticks, value = tRunning[grp]}
                            elseif ticks <= rightTickLimit then
                                if #t.tChase ~= 0 and ticks == t.tChase[#t.tChase].ticks then
                                    t.tChase[#t.tChase].value = tRunning[grp]
                                else
                                    t.tChase[#t.tChase+1] = {ticks = ticks, value = tRunning[grp]}
                                end
                                tMIDI[#tMIDI+1] = MIDI:sub(savePos, prevPos+3) --pos-#msg-6) -- Exclude offset, which won't change when deleting with empty event
                                tMIDI[#tMIDI+1] = MIDI:sub(prevPos+4, pos-1) --(pos-#msg-5, pos-1)
                                savePos = pos
                                local tD = t.tD
                                tD[#tD+1] = {index = #tMIDI, id = msg:byte(1)&0x0F, ticks = ticks, flagsMsg = tMIDI[#tMIDI]}
                            elseif tBeyond[grp] then
                                if #t.tChase ~= 0 and ticks == t.tChase[#t.tChase].ticks then
                                    t.tChase[#t.tChase].value = tRunning[grp]
                                    tBeyond[grp] = nil
                                    if not next(tBeyond) then break end
                                else
                                    t.tChase[#t.tChase+1] = {ticks = ticks, value = tRunning[grp]}
                                end                  
                            end
                            
                            --if chaseIndex then t.tChase[chaseIndex] = {ticks = ticks, value = tRunning[grp]} end
                            --if not next(tBeyond) then break end
                            
                            --[[local chaseIndex = (ticks < leftTickLimit and 1) or 
                                local oldValue = 0
                                if t.tChase[#t.tChase] and t.tChase[#t.tChase].ticks == ticks then
                                    local oldValue = t.tChase[#t.tChase].value
                                    tChase[#t.tChase] = {ticks = ticks, value = (oldValue&0xFF80)|(msg:byte(3))}
                                end
                                    
                                    
                            --local lane = (msg:byte(2) == targetLaneMSB and "MSB") or (msg:byte(2) == targetLaneLSB and "LSB") or nil
                            --if lane then
                                if lane == "MSB" then --msg:byte(2) == targetLaneMSB then
                                    
                                    tChase[1] = {ticks = ticks, value = (msg:byte(3)<<7)|(oldValue&0x007F)}
                                else --if msg:byte(2) == targetLaneLSB then
                                    local tChase1 = tGroups[msg:byte(1)&0x0F].tChase
                                    local 
                                end
                            elseif ticks <= rightTickLimit then
                                tMIDI[#tMIDI+1] = MIDI:sub(savePos, prevPos+3) -- Exclude offset, which won't change when deleting with empty event
                                tMIDI[#tMIDI+1] = MIDI:sub(prevPos+4, pos-1)
                                savePos = pos
                                local tD = tGroups[msg:byte(1)&0x0F].tD
                                tD[#tD+1] = {index = #tMIDI, id = msg:byte(1)&0x0F, ticks = ticks, flagsMsg = tMIDI[#tMIDI]}
                            end]]
                        end
                    end
                end -- if t
            end -- if #msg ~= 0 and (msg:byte(1))>>4 == 11 then
            prevPos = pos
        end -- while prevPos < MIDILen do
    elseif laneIsPITCH then
        while prevPos < MIDILen do
            local offset, flags, msg, pos = s_unpack("i4Bs4", MIDI, prevPos)
            ticks = ticks + offset
            if #msg ~= 0 and (msg:byte(1)&0xF0) == 0xE0 then
                local grp = msg:byte(1)&0x0F
                local t = tGroups[grp]
                if t then
                    if flags&1==1 then
                        if savePos < prevPos then tMIDI[#tMIDI+1] = MIDI:sub(savePos, prevPos-1) end
                        tMIDI[#tMIDI+1] = ""
                        local e = #t.tT + 1
                        if MIDI:sub(pos, pos+15) == "\0\0\0\0\0\12\0\0\0\255\15CCBZ " then t.tQ[e] = MIDI:sub(pos, pos+20) pos = pos + 21 end
                        savePos = pos
                        t.tI[e], t.tA[e] = #tMIDI, ticks-offset
                        t.tT[e], t.tF[e], t.tC[e], t.tV[e] = ticks, flags, msg:byte(1)&0x0F, (msg:byte(3)<<7)|msg:byte(2) -- tC not actually necessary, since ID = chan
                    else
                        if ticks < leftTickLimit then
                            t.tChase[1] = {ticks = ticks, value = (msg:byte(3)<<7)|msg:byte(2)} --chaseIndex = 1 --local tChase = tGroups[msg:byte(1)&0x0F].tChase[1] = {ticks = ticks, value = msg:byte(3)}
                        elseif ticks <= rightTickLimit then
                            t.tChase[#t.tChase+1] = {ticks = ticks, value = (msg:byte(3)<<7)|msg:byte(2)}

                            tMIDI[#tMIDI+1] = MIDI:sub(savePos, prevPos+3) --pos-#msg-6) -- Exclude offset, which won't change when deleting with empty event
                            tMIDI[#tMIDI+1] = MIDI:sub(prevPos+4, pos-1) --(pos-#msg-5, pos-1)
                            savePos = pos
                            local tD = t.tD
                            tD[#tD+1] = {index = #tMIDI, id = msg:byte(1)&0x0F, ticks = ticks, flagsMsg = tMIDI[#tMIDI]}
                        elseif tBeyond[grp] then
                            t.tChase[#t.tChase+1] = {ticks = ticks, value = (msg:byte(3)<<7)|msg:byte(2)}
                            tBeyond[grp] = nil
                            if not next(tBeyond) then break end
                        end
                    end
                end
            end
            prevPos = pos
        end
    elseif laneIsPROGRAM then 
        while prevPos < MIDILen do
            local offset, flags, msg, pos = s_unpack("i4Bs4", MIDI, prevPos)
            ticks = ticks + offset
            if #msg ~= 0 and (msg:byte(1)&0xF0) == 0xC0 then
                local grp = msg:byte(1)&0x0F
                local t = tGroups[grp]
                if t then
                    if flags&1==1 then
                        if savePos < prevPos then tMIDI[#tMIDI+1] = MIDI:sub(savePos, prevPos-1) end
                        tMIDI[#tMIDI+1] = ""
                        local t = tGroups[msg:byte(1)&0x0F]
                        local e = #t.tT + 1
                        if MIDI:sub(pos, pos+15) == "\0\0\0\0\0\12\0\0\0\255\15CCBZ " then t.tQ[e] = MIDI:sub(pos, pos+20) pos = pos + 21 end
                        savePos = pos
                        t.tI[e], t.tA[e] = #tMIDI, ticks-offset
                        t.tT[e], t.tF[e], t.tC[e], t.tV[e] = ticks, flags, msg:byte(1)&0x0F, msg:byte(2) -- tC not actually necessary, since ID = chan
                    else
                        if ticks < leftTickLimit then
                            t.tChase[1] = {ticks = ticks, value = msg:byte(2)} --chaseIndex = 1 --local tChase = tGroups[msg:byte(1)&0x0F].tChase[1] = {ticks = ticks, value = msg:byte(3)}
                        elseif ticks <= rightTickLimit then
                            t.tChase[#t.tChase+1] = {ticks = ticks, value = msg:byte(2)}
                        
                            tMIDI[#tMIDI+1] = MIDI:sub(savePos, prevPos+3) --pos-#msg-6) -- Exclude offset, which won't change when deleting with empty event
                            tMIDI[#tMIDI+1] = MIDI:sub(prevPos+4, pos-1) --(pos-#msg-5, pos-1)
                            savePos = pos
                            local tD = t.tD
                            tD[#tD+1] = {index = #tMIDI, id = msg:byte(1)&0x0F, ticks = ticks, flagsMsg = tMIDI[#tMIDI]}
                        elseif tBeyond[grp] then
                            t.tChase[#t.tChase+1] = {ticks = ticks, value = msg:byte(2)}
                            tBeyond[grp] = nil
                            if not next(tBeyond) then break end
                        end
                    end
                end
            end
            prevPos = pos
        end
    elseif laneIsCHANPRESS then 
        while prevPos < MIDILen do
            local offset, flags, msg, pos = s_unpack("i4Bs4", MIDI, prevPos)
            ticks = ticks + offset
            if #msg ~= 0 and (msg:byte(1)&0xF0) == 0xD0 then
                local grp = msg:byte(1)&0x0F
                local t = tGroups[grp]
                if t then
                    if flags&1==1 then
                        if savePos < prevPos then tMIDI[#tMIDI+1] = MIDI:sub(savePos, prevPos-1) end
                        tMIDI[#tMIDI+1] = ""
                        local t = tGroups[msg:byte(1)&0x0F]
                        local e = #t.tT + 1
                        if MIDI:sub(pos, pos+15) == "\0\0\0\0\0\12\0\0\0\255\15CCBZ " then t.tQ[e] = MIDI:sub(pos, pos+20) pos = pos + 21 end
                        savePos = pos
                        t.tI[e], t.tA[e] = #tMIDI, ticks-offset
                        t.tT[e], t.tF[e], t.tC[e], t.tV[e] = ticks, flags, msg:byte(1)&0x0F, msg:byte(2) -- tC not actually necessary, since ID = chan
                    else                        
                        if ticks < leftTickLimit then
                            t.tChase[1] = {ticks = ticks, value = msg:byte(2)} --chaseIndex = 1 --local tChase = tGroups[msg:byte(1)&0x0F].tChase[1] = {ticks = ticks, value = msg:byte(3)}
                        elseif ticks <= rightTickLimit then
                            t.tChase[#t.tChase+1] = {ticks = ticks, value = msg:byte(2)}
                        
                            tMIDI[#tMIDI+1] = MIDI:sub(savePos, prevPos+3) --pos-#msg-6) -- Exclude offset, which won't change when deleting with empty event
                            tMIDI[#tMIDI+1] = MIDI:sub(prevPos+4, pos-1) --(pos-#msg-5, pos-1)
                            savePos = pos
                            local tD = t.tD
                            tD[#tD+1] = {index = #tMIDI, id = msg:byte(1)&0x0F, ticks = ticks, flagsMsg = tMIDI[#tMIDI]}
                        elseif tBeyond[grp] then
                            t.tChase[#t.tChase+1] = {ticks = ticks, value = msg:byte(2)}
                            tBeyond[grp] = nil
                            if not next(tBeyond) then break end
                        end
                    end
                end
            end
            prevPos = pos
        end
    --[[elseif laneIsVELOCITY or laneIsOFFVEL then 
        local t = tGroups.notes
        while prevPos < MIDILen do
            local offset, flags, msg, pos = s_unpack("i4Bs4", MIDI, prevPos)
            ticks = ticks + offset
            if flags&1==1 and #msg == 3 then 
                -- Note-on
                if msg:byte(1)>>4 == 9 and msg:byte(3) ~= 0 then
                    if savePos < prevPos then tMIDI[#tMIDI+1] = MIDI:sub(savePos, prevPos-1) end
                    tMIDI[#tMIDI+1] = ""
                    savePos = pos
                    local i = #t.tT+1
                    t.tI[i], t.tA[i] = #tMIDI, ticks-offset
                    t.tT[i], t.tM[i] = ticks, MIDI:sub(prevPos+4, pos-1)
                    tNotes[msg:byte(1)&0x0F][msg:byte(2)] = i 
                -- Note-off
                elseif msg:byte(1)>>4 == 8 or (msg:byte(1)>>4 == 9 and msg:byte(3) == 0) then
                    if savePos < prevPos then tMIDI[#tMIDI+1] = MIDI:sub(savePos, prevPos-1) end
                    tMIDI[#tMIDI+1] = s_pack("i4", offset) .. "\0\0\0\0\0" -- Delete note-off from this position. If note-off has no note-on partner, will remain deleted.
                    savePos = pos
                    local saved = tNotes[msg:byte(1)&0x0F][msg:byte(2)]
                    if saved then
                        t.tOff[saved] = ticks
                        --t.tF2[saved]  = flags
                        t.tM2[saved]  = MIDI:sub(prevPos+4, pos-1)
                    end
                    if ticks >= origNoteOffTick then t.noteWithLastNoteOff = saved end
                    tNotes[msg:byte(1)&0x0F][msg:byte(2)] = nil
                end
            -- Notation meta
            -- Unlike Bezier meta events, notation events don't immediately follow their correspnding notes (prior to v5.9??)
            --    but this code assumes that notation follows *before* the note-off.
            elseif offset == 0 and msg:sub(1,6) == "\255\15NOTE" then
                local notationChannel, notationPitch = msg:match("NOTE (%d+) (%d+) ")
                if notationChannel and notationPitch then
                    notationChannel = tonumber(notationChannel)
                    notationPitch   = tonumber(notationPitch)
                    local saved = tNotes[notationChannel] and tNotes[notationChannel][notationPitch]
                    if saved then
                        if savePos < prevPos then tMIDI[#tMIDI+1] = MIDI:sub(savePos, prevPos-1) end
                        tMIDI[#tMIDI+1] = s_pack("i4Bs4", offset, 0, 0) -- Delete form tMIDI, since will be combined with note-on and note-off at note-on's entry
                        t.tQ[saved] = MIDI:sub(prevPos, pos-1)
                        savePos = pos
                    end
                end
            end            
            prevPos = pos
        end]]
    -- The data that is stored for Velocity and off-velocity only differ in tV.
    elseif laneIsVELOCITY or laneIsOFFVEL then 
        local t = tGroups.notes
        while prevPos < MIDILen do
            local offset, flags, msg, pos = s_unpack("i4Bs4", MIDI, prevPos)
            ticks = ticks + offset
            if flags&1==1 and #msg == 3 then 
                -- Note-on
                if msg:byte(1)>>4 == 9 and msg:byte(3) ~= 0 then
                    if savePos < prevPos then tMIDI[#tMIDI+1] = MIDI:sub(savePos, prevPos-1) end
                    tMIDI[#tMIDI+1] = ""
                    savePos = pos
                    local i = #t.tT+1
                    t.tI[i], t.tA[i] = #tMIDI, ticks-offset
                    t.tT[i], t.tF[i], t.tC[i], t.tP[i], t.tM[i] = ticks, flags, msg:byte(1)&0x0F, msg:byte(2), msg
                    local id = (msg:byte(2)<<4) | msg:byte(1)&0x0F
                    if tNotes[id] then 
                        reaper.MB("The script encountered overlapping notes, which cannot be parsed.\n\nOverlapping notes can be removed using the \"Correct overlapping notes\" action", "ERROR", 0)
                        return "QUIT"
                    else
                        tNotes[id] = i 
                    end
                -- Note-off
                elseif msg:byte(1)>>4 == 8 or (msg:byte(1)>>4 == 9 and msg:byte(3) == 0) then
                    if savePos < prevPos then tMIDI[#tMIDI+1] = MIDI:sub(savePos, prevPos-1) end
                    tMIDI[#tMIDI+1] = s_pack("i4", offset) .. "\0\0\0\0\0" -- Delete note-off from this position. If note-off has no note-on partner, will remain deleted.
                    savePos = pos
                    local id = (msg:byte(2)<<4) | msg:byte(1)&0x0F
                    local saved = tNotes[id]
                    if saved then
                        t.tOff[saved] = ticks -- - t.tT[saved]
                        t.tF2[saved]  = flags
                        t.tM2[saved]  = msg
                    end
                    if ticks >= origNoteOffTick then t.noteWithLastNoteOff = saved end
                    tNotes[id] = nil
                end
            -- Notation meta
            -- Unlike Bezier meta events, notation events don't immediately follow their correspnding notes (prior to v5.9??)
            --    but this code assumes that notation follows *before* the note-off.
            elseif offset == 0 and msg:sub(1,6) == "\255\15NOTE" then
                local notationChannel, notationPitch = msg:match("NOTE (%d+) (%d+) ")
                if notationChannel and notationPitch then
                    notationChannel = tonumber(notationChannel)
                    notationPitch   = tonumber(notationPitch)
                    local saved = tNotes[(notationPitch<<4) | notationChannel]
                    if saved then
                        if savePos < prevPos then tMIDI[#tMIDI+1] = MIDI:sub(savePos, prevPos-1) end
                        tMIDI[#tMIDI+1] = s_pack("i4Bs4", offset, 0, 0) -- Delete form tMIDI, since will be combined with note-on and note-off at note-on's entry
                        t.tQ[saved] = MIDI:sub(prevPos, pos-1)
                        savePos = pos
                    end
                end
            end            
            prevPos = pos
        end
        -- The data that is stored for Velocity and off-velocity only differ in tV.
        local tM = laneIsVELOCITY and t.tM or t.tM2
        local tV = t.tV
        for i = 1, #tM do
            tV[i] = tM[i]:byte(3)
        end
    elseif laneIsTEXT then
        local tGrpT = tGroups.text
        while prevPos < MIDILen and ticks <= rightTickLimit do
            local offset, flags, msg, pos = s_unpack("i4Bs4", MIDI, prevPos)
            ticks = ticks + offset
            if flags&1 == 1 and msg ~= 0 and msg:byte(1) == 0xFF and msg:byte(2) ~= 0x0F then
                if prevPos > savePos then tMIDI[#tMIDI+1] = MIDI:sub(savePos, prevPos-1) end
                tMIDI[#tMIDI+1] = MIDI:sub(prevPos, pos-1)
                savePos = pos
                local i = #tGrpT.tT + 1
                tGrpT.tI[i], tGrpT.tA[i] = #tMIDI, ticks-offset
                tGrpT.tT[i], tGrpT.tM[i] = ticks, MIDI:sub(prevPos+4, pos-1)
            end
            prevPos = pos
        end
    elseif laneIsSYSEX then
        local tGrpT = tGroups.text
        while prevPos < MIDILen and ticks <= rightTickLimit do
            local offset, flags, msg, pos = s_unpack("i4Bs4", MIDI, prevPos)
            ticks = ticks + offset
            if flags&1 == 1 and msg ~= 0 and msg:byte(1)&0xF0 == 0xF0 and msg:byte(1) ~= 0xFF then
                if prevPos > savePos then tMIDI[#tMIDI+1] = MIDI:sub(savePos, prevPos-1) end
                tMIDI[#tMIDI+1] = MIDI:sub(prevPos, pos-1)
                savePos = pos
                local i = #tGrpT.tT + 1
                tGrpT.tI[i], tGrpT.tA[i] = #tMIDI, ticks-offset
                tGrpT.tT[i], tGrpT.tM[i] = ticks, MIDI:sub(prevPos+4, pos-1)
            end
            prevPos = pos
        end
    end
    
    -- Insert all unselected events remaining
    tMIDI[#tMIDI+1] = MIDI:sub(savePos, nil)    
    
    --origValueMax, origValueMin = GetMinMaxValues(tGroups)
    --origTickLeftmost, origValueLeftmost, origTickRightmost, origValueRightmost, origValueMin, origValueMax = GetAllEdgeValues(tGroups, activeChannel)
    
    --origPPQleftmost, origPPQrightmost = (tTargets[1] and tTargets[1].ticks) or math.huge, (tTargets[#tTargets] and tTargets[#tTargets].ticks) or -math.huge
    tSteps[0] =  --[[{globalLeftValue = origValueLeftmost,  globalRightValue  = origValueRightmost, 
                  globalMinValue  = origValueMin,       globalMaxValue    = origValueMax, 
                  globalLeftTick  = origTickLeftmost,   globalRightTick   = origTickRightmost,]]
                  {tGroups = tGroups}
    GetAllEdgeValues(tSteps[#tSteps])
    return "NEXT"
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
        Tooltip("Armed: Multi tool")
    end

    -- Must notify the AtExit function that button should not be deactivated when exiting.
    leaveToolbarButtonArmed = true
    
end -- ArmToolbarButton()


--######################
------------------------
-- This function displays a tooltip next to the mouse cursor, and moves the tooltip with the cursor for 0.5 seconds
local tooltipTime = 0
local tooltipText = ""
function Tooltip(text)
    if text then -- New tooltip text, so new tooltip
        tooltipTime = reaper.time_precise()
        tooltipText = text
        local x, y = reaper.GetMousePosition()
        reaper.TrackCtl_SetToolTip(tooltipText, x+10, y+10, true)
        reaper.defer(Tooltip)
    elseif pcallOK and continue and reaper.time_precise() < tooltipTime+0.5 then -- if not (pcallOK and pcallRetval), then script is quitting, so don't defer
        local x, y = reaper.GetMousePosition()
        reaper.TrackCtl_SetToolTip(tooltipText, x+10, y+10, true)
        reaper.defer(Tooltip)
    else
        reaper.TrackCtl_SetToolTip("", 0, 0, false)
    end
end


--############################
------------------------------
function CONSTRUCT_MIDI_STRING()

    local s_pack = string.pack   
    local tMIDI = tMIDI    
    local spacer = "\0\0\0\0\0"

    for id, t in pairs(tSteps[#tSteps].tGroups) do
        local tI  = t.tI
        local tA  = t.tA
        local tT  = t.tT
        local tO  = tSteps[0].tGroups[id].tT -- Original tick positions
        local tV  = t.tV
        local tOff  = t.tOff
        local tM  = t.tM
        local tM2 = t.tM2
        local tC  = t.tC 
        local tF  = t.tF
        local tF2 = t.tF2
        local tP  = t.tP
        local tMeta = t.tQ -- Extra REAPER-specific non-MIDI metadata such as notation or Bezier tension.
        --local tR  = tRanges
        
        local step = (tT[1] <= tT[#tT]) and 1 or -1
        local e    = (tT[1] <= tT[#tT]) and 0 or #tT+1
       
        for i = 1, #tI do          
            e = e + step
            
            local ticks = tT[e]
            if   ticks ~= ticks then error("inf e="..tostring(e).." i="..tostring(i))
            elseif  ticks < 0 then ticks = 0
            elseif  ticks > sourceLengthTicks then ticks = sourceLengthTicks
            else    ticks = (ticks+0.5)//1
            end

            local offTicks = tOff[e]
            if offTicks then
                if      offTicks < 0 then offTicks = 0
                elseif  offTicks > sourceLengthTicks then offTicks = sourceLengthTicks
                else    offTicks = (offTicks+0.5)//1
                end
            end
            
            local value = tV[e]
            if value then
                if      value < laneMinValue then value = laneMinValue
                elseif  value > laneMaxValue then value = laneMaxValue
                else    value = (value+0.5)//1
                end
            end
                            
                
            if laneIsCC7BIT then
                tMIDI[tI[i]] = s_pack("i4BI4BBB", ticks-tA[i], tF[e], 3, 0xB0 | tC[e], mouseOrigCCLane, value) 
                            .. (tMeta[e] or "") 
                            .. ((ticks ~= tO[i]) and (s_pack("i4", tO[i]-ticks) .. spacer) or "")
            elseif laneIsPITCH then
                tMIDI[tI[i]] = s_pack("i4BI4BBB", ticks-tA[i], tF[e], 3, 0xE0 | tC[e], value&127, value>>7) 
                            .. (tMeta[e] or "") 
                            .. ((ticks ~= tO[i]) and (s_pack("i4", tO[i]-ticks) .. spacer) or "")
            elseif laneIsCHANPRESS then
                tMIDI[tI[i]] = s_pack("i4BI4BB", ticks-tA[i], tF[e], 2, 0xD0 | tC[e], value) 
                            .. (tMeta[e] or "") 
                            .. ((ticks ~= tO[i]) and (s_pack("i4", tO[i]-ticks) .. spacer) or "")
            elseif laneIsCC14BIT then
                tMIDI[tI[i]] = s_pack("i4BI4BBB", ticks-tA[i], tF[e], 3, 0xB0 | tC[e], mouseOrigCCLane-256, value>>7) 
                            .. (tMeta[e] or "")
                            .. s_pack("i4BI4BBB", 0, tF2[e], 3, 0xB0 | tC[e], mouseOrigCCLane-224, value&127)
                            .. ((ticks ~= tO[i]) and (s_pack("i4", tO[i]-ticks) .. spacer) or "")
            elseif laneIsVELOCITY then
                tMIDI[tI[i]] = s_pack("i4BI4BBB", ticks-tA[i], tF[e], 3, 0x90 | tC[e], tP[e], value) 
                            .. (tMeta[e] or "")
                            .. s_pack("i4Bs4", offTicks-ticks, tF2[e], tM2[e])
                            .. s_pack("i4", tO[i]-offTicks) .. spacer
            elseif laneIsOFFVEL then
                tMIDI[tI[i]] = s_pack("i4Bs4", ticks-tA[i], tF[e], tM[e]) 
                            .. (tMeta[e] or "")
                            .. s_pack("i4BI4BBB", offTicks-ticks, tF2[e], 3, 0x80 | tC[e], tP[e], value)
                            .. s_pack("i4", tO[i]-offTicks) .. spacer
            elseif laneIsPROGRAM then
                tMIDI[tI[i]] = s_pack("i4Bi4BB", ticks-tA[i], tF[e], 2, 0xC0 | tC[e], value) 
                            .. (tMeta[e] or "") 
                            .. ((ticks ~= tO[i]) and (s_pack("i4", tO[i]-ticks) .. spacer) or "")
            else -- all lanes that only move horizontally: if laneIsALL or laneIsTEXT or laneIsSYSEX or or laneIsBANKPROG or laneIsONLYHORZ then
                if id == "notes" then
                    tMIDI[tI[i]] = s_pack("i4", ticks-tA[i]) .. tM[e] 
                            .. (tMeta[e] or "")
                            .. s_pack("i4", offTicks-ticks) .. tM2[e]
                            .. s_pack("i4", tO[i]-offTicks) .. "\0\0\0\0\0"
                else
                    tMIDI[tI[i]] = s_pack("i4", ticks-tA[i]) .. tM[e]
                            .. (tMeta[e] or "") 
                            .. ((ticks ~= tO[i]) and (s_pack("i4", tO[i]-ticks) .. spacer) or "")
                end
            end
        end
        
        -- If changing positions, delete overlapped CCs.  All CCs between original and new boundaries will be deleted -- not only those between new boundaries.
        if tSteps[#tSteps].isChangingPositions then
            local tD  = t.tD
            if tD and #tD > 0 then
                local left, right         = tT[1], tT[#tT]
                local origLeft, origRight = tSteps[0].tGroups[id].tT[1], tSteps[0].tGroups[id].tT[#tT] -- step 0 was sorted
                if left > right then left, right = right, left end
                if origLeft < left then left = origLeft end
                if origRight > right then right = origRight end
                
                -- Binary search
                local hi, lo = #tD, 1
                while hi-lo > 1 do 
                    local mid = (lo+hi)//2
                    if tD[mid].ticks < left then
                        lo = mid
                    else 
                        hi = mid
                    end
                end

                -- Check each target event until one is reached that is beyond left/right bounds, and also not deleted.
                --    Since overlapped events are always deleted in a contiguous block, the first non-deleted one is 
                for i = hi, 1, -1 do
                    local d = tD[i]
                    if     right < d.ticks  then tMIDI[d.index] = d.flagsMsg
                    elseif left <= d.ticks  then tMIDI[d.index] = spacer
                    elseif tMIDI[d.index] == spacer then tMIDI[d.index] = d.flagsMsg
                    elseif d.ticks < left   then break
                    end
                end
                
                for i = hi+1, #tD do
                    local d = tD[i]
                    if     d.ticks < left   then tMIDI[d.index] = d.flagsMsg
                    elseif d.ticks <= right then tMIDI[d.index] = spacer
                    elseif tMIDI[d.index] == spacer then tMIDI[d.index] = d.flagsMsg
                    elseif right < d.ticks  then break
                    end
                end
                --[[
                for i = hi+1, #tD do
                    local d = tD[i]
                    if left <= d.ticks and d.ticks <= right then
                        if not d.deleted then
                            tMIDI[d.index] = spacer
                            d.deleted = true
                        end
                    elseif d.deleted then
                        tMIDI[d.index] = d.flagsMsg
                        d.deleted = false
                    elseif right < d.ticks then
                        break
                    end
                end]]
            end
          
            --[[for i, d in ipairs(tD) do
                if left <= d.ticks and d.ticks <= right then
                    tMIDI[d.index] = "\0\0\0\0\0"
                else
                    tMIDI[d.index] = d.flagsMsg
                end 
            end]]
        end
    end        
    
    -----------------------------------------------------------
    -- DRUMROLL... write the edited events into the MIDI chunk!
    --[[stretchMIDIString = table.concat(tMIDI)
    reaper.MIDI_SetAllEvts(activeTake, remainMIDILeft 
                                    .. string.pack("i4Bs4", -remainTicksLeft, 0, "")
                                    .. stretchMIDIString 
                                    .. string.pack("i4Bs4", remainTicksLeft-lastPPQPos, 0, "") 
                                    .. remainMIDIRight)]]
    reaper.MIDI_SetAllEvts(activeTake, table.concat(tMIDI))
                                    
    if isInline then reaper.UpdateItemInProject(activeItem) end
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
    elseif not reaper.JS_LICE_WritePNG then
        reaper.ShowConsoleMsg("\n\nURL to add ReaPack repository:\nhttps://github.com/ReaTeam/Extensions/raw/master/index.xml")
        reaper.ShowConsoleMsg("\n\nURL for direct download:\nhttps://github.com/juliansader/ReaExtensions")
        reaper.MB("This script requires an up-to-date version of the js_ReaScriptAPI extension."
               .. "\n\nThe js_ReaScripAPI extension can be installed via ReaPack, or can be downloaded manually."
               .. "\n\nTo install via ReaPack, ensure that the ReaTeam/Extensions repository is enabled. "
               .. "This repository should be enabled by default in recent versions of ReaPack, but if not, "
               .. "the repository can be added using the URL that should now be displayed in REAPER's Console."
               .. "\n\n(In REAPER's menu, go to Extensions -> ReaPack -> Import a repository.)"
               .. "\n\nTo install the extension manually, download the most recent version from Github, "
               .. "using the second URL displayed in the console, and copy it to REAPER's UserPlugins directory."
                , "ERROR", 0)
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
    
    
    -- GET MOUSE AND KEYBOARD STARTING STATE
    -- as soon as possible.  Hopefully, if script is started with mouse click, mouse button will still be down.
    -- VKeys_Intercept is also urgent, because must prevent multiple WM_KEYDOWN message from being sent, which may trigger script termination.
    interceptKeysOK = (reaper.JS_VKeys_Intercept(-1, 1) > 0)
        if not interceptKeysOK then reaper.MB("Could not intercept keyboard input.", "ERROR", 0) return false end
    mouseState = reaper.JS_Mouse_GetState(0xFF)    
    mouseOrigX, mouseOrigY = reaper.GetMousePosition()
    startTime = reaper.time_precise()
    prevMouseTime = startTime + 0.5 -- In case mousewheel sends multiple messages, don't react to messages sent too closely spaced, so wait till little beyond startTime.
    keyState = reaper.JS_VKeys_GetState(-2):sub(VKLow, VKHi)
 
    
    -- CONFLICTING SCRIPTS
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
    if sectionID ~= nil and commandID ~= nil and sectionID ~= -1 and commandID ~= -1 then
        origToggleState = reaper.GetToggleCommandStateEx(sectionID, commandID)
        reaper.SetToggleCommandState(sectionID, commandID, 1)
        reaper.RefreshToolbar2(sectionID, commandID)
    end                  

    
    -- GET MIDI EDITOR UNDER MOUSE
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
                                
                                -- Get the part of the MIDI editor that is under the mouse. The lane IDs are slightly different (and more informative) 
                                --    then those returned by SWS's BR_ functions: -1.5 = ruler, -1 = piano roll, fractions are lane dividers
                                mouseOrigCCLaneID = GetCCLaneIDFromPoint(mouseOrigX, mouseOrigY)
                                if mouseOrigCCLaneID then
                                    
                                    -- Convert lane ID to the codes returned by reaper.MIDIEditor_GetSetting_int(editor, "last_clicked_lane")
                                    --    Also set laneMinValue and laneMaxValue, and set the appropriate laneIsXXX to true.
                                    targetLaneOK, mouseOrigCCLane = SetupTargetLaneForParsing(mouseOrigCCLaneID) 
                                    if targetLaneOK then                                    
                                        
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
                    
                    editor, midiview = nil, nil
                    modeIsSTRETCH = true -- inline editor doesn't have COMPRESS mode
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
    if laneIsNOTATION or laneIsMEDIAITEM then
        reaper.MB("This script cannot edit events in the notation or media item lanes.", "ERROR: Multi Tool", 0)
        return false
    end
    
    
    -- MOUSE VALUE / PITCH
    -- The BR_ functions have already retrieved these for the inline editor
    if midiview then
        if (mouseOrigCCLaneID == -1) and ME_TopPitch and ME_PixelsPerPitch then
            mouseOrigPitch = ME_TopPitch - math.ceil((mouseOrigY - tME_Lanes[-1].ME_TopPixel) / ME_PixelsPerPitch)
            mouseOrigCCValue = -1
        elseif (mouseOrigCCLaneID%1 == 0) and laneMinValue and laneMaxValue then
            mouseOrigPitch = -1                                        
            mouseOrigCCValue = laneMinValue + (laneMaxValue-laneMinValue) * (mouseOrigY - tME_Lanes[mouseOrigCCLaneID].ME_BottomPixel) / (tME_Lanes[mouseOrigCCLaneID].ME_TopPixel - tME_Lanes[mouseOrigCCLaneID].ME_BottomPixel)
        end
    end
    
    
    -- ITEM TICK POSITIONS
    -- In case the item is looped, mouse PPQ position will be adjusted to equivalent position in first iteration.
    --    * mouseOrigPPQPos will be contracted to (possibly looped) item visible boundaries
    --    * Then get tick position relative to start of loop iteration under mouse
    local mouseOrigPPQPos = nil
    if isInline then
        mouseOrigPPQPos = reaper.MIDI_GetPPQPosFromProjTime(activeTake, reaper.BR_GetMouseCursorContext_Position())
    elseif ME_TimeBase == "beats" then
        mouseOrigPPQPos = ME_LeftmostTick + mouseOrigX/ME_PixelsPerTick
    else -- ME_TimeBase == "time"
        mouseOrigPPQPos  = reaper.MIDI_GetPPQPosFromProjTime(activeTake, ME_LeftmostTime + mouseOrigX/ME_PixelsPerSecond )
    end
    local itemStartTimePos = reaper.GetMediaItemInfo_Value(activeItem, "D_POSITION")
    local itemEndTimePos = itemStartTimePos + reaper.GetMediaItemInfo_Value(activeItem, "D_LENGTH")
    local itemFirstVisibleTick = math.ceil(reaper.MIDI_GetPPQPosFromProjTime(activeTake, itemStartTimePos)) 
    local itemLastVisibleTick = math.ceil(reaper.MIDI_GetPPQPosFromProjTime(activeTake, itemEndTimePos)) - 1 -- -1 is important, since this function returns tick that immediately *follows* the time position.
    if mouseOrigPPQPos > itemLastVisibleTick then mouseOrigPPQPos = itemLastVisibleTick
    elseif mouseOrigPPQPos < itemFirstVisibleTick then mouseOrigPPQPos = itemFirstVisibleTick 
    end
    -- Source length will be used in other context too: When script terminates, check that no inadvertent shifts in PPQ position occurred.
    if not sourceLengthTicks then sourceLengthTicks = reaper.BR_GetMidiSourceLenPPQ(activeTake) end
    loopStartPPQPos = (mouseOrigPPQPos // sourceLengthTicks) * sourceLengthTicks
    minimumTick = math.max(0, itemFirstVisibleTick)
    maximumTick = math.min(itemLastVisibleTick, sourceLengthTicks-1) -- I prefer not to draw any event on the same PPQ position as the All-Notes-Off


    -- IS SNAPPING ENABLED?
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
    
    
    -- GET AND PARSE MIDI
    -- Time to process the MIDI of the take!
    -- As mentioned in the header, this script does not use the old-fashioned MIDI API functions such as 
    --    MIDI_InsertCC, since these functions are far too slow when dealing with thousands of events.
    --if not GetAndParseMIDIString() then return false end
    ParseMidi_FirstPass()
    if not (origTickLeftmost and origTickRightmost) or origTickLeftmost >= origTickRightmost then
        reaper.MB("Could not find a sufficient number of selected events in the target lane(s)."
                .. "\n\nNB: If the MIDI editor's filter is set to \"Edit active channel only\", the script will only edit events in the active channel."
                , "ERROR", 0)
        return false
    end
    selectedEditFunction = ParseMidi_SecondPass
    
        
    -- 
    bitmap = reaper.JS_LICE_CreateBitmap(true, ME_midiviewWidth, ME_midiviewHeight)
        if not bitmap then reaper.MB("Could not create LICE bitmap", "ERROR", 0) return false end 
    compositeOK = reaper.JS_Composite(midiview, 0, 0, ME_midiviewWidth, ME_midiviewHeight, bitmap, 0, 0, ME_midiviewWidth, ME_midiviewHeight)
        if compositeOK ~= 1 then reaper.MB("Cannot draw guidelines.\n\nCompositing error: "..tostring(compositeOK), "ERROR", 0) return false end


    OS = reaper.GetOS()
    macOS = OS:match("OSX") -- On macOS, mouse events use opposite sign
    winOS = OS:match("Win")
    filename = filename:gsub("\\", "/") -- Change Windows format to cross-platform
    filename = filename:match("^.*/") or "" -- Remove script filename, keeping directory
    cursorHandTop       = reaper.JS_Mouse_LoadCursorFromFile(filename.."js_Mouse editing - Scale top.cur") -- The first time that the cursor is loaded in the session will be slow, but afterwards the extension will re-use previously loaded cursor
    if not cursorHandTop then reaper.MB("Could not load the cursorHandTop cursor", "ERROR", 0) return false end
    cursorHandBottom    = reaper.JS_Mouse_LoadCursorFromFile(filename.."js_Mouse editing - Scale bottom.cur")
    if not cursorHandBottom then reaper.MB("Could not load the cursorHandBottom cursor", "ERROR", 0) return false end
    cursorHandRight     = reaper.JS_Mouse_LoadCursor(431)
    if not cursorHandRight then reaper.MB("Could not load the cursorHandRight cursor", "ERROR", 0) return false end
    cursorHandLeft      = reaper.JS_Mouse_LoadCursor(430)
    if not cursorHandLeft then reaper.MB("Could not load the cursorHandLeft cursor", "ERROR", 0) return false end
    cursorCompress      = reaper.JS_Mouse_LoadCursorFromFile(filename.."js_Mouse editing - Multi compress.cur") --reaper.JS_Mouse_LoadCursor(533)
    if not cursorCompress then reaper.MB("Could not load the cursorCompress cursor", "ERROR", 0) return false end
    cursorArpeggiateLR  = reaper.JS_Mouse_LoadCursor(502)
    if not cursorArpeggiateLR then reaper.MB("Could not load the cursorArpeggiateLR cursor", "ERROR", 0) return false end
    cursorArpeggiateUD  = reaper.JS_Mouse_LoadCursor(503) -- REAPER's own arpeggiate up/down cursor
    if not cursorArpeggiateUD then reaper.MB("Could not load the cursorArpeggiateUD cursor", "ERROR", 0) return false end
    cursorTilt          = reaper.JS_Mouse_LoadCursor(189) --reaper.JS_Mouse_LoadCursorFromFile(filename.."js_Mouse editing - Arch and Tilt.cur")
    if not cursorTilt then reaper.MB("Could not load the cursorTilt cursor", "ERROR", 0) return false end
    cursorNo            = reaper.JS_Mouse_LoadCursor(464) -- Arrow with cross
    if not cursorNo then reaper.MB("Could not load the cursorNo cursor", "ERROR", 0) return false end
    cursorArrow         = reaper.JS_Mouse_LoadCursor(32512) -- Standard IDC_ARROW
    if not cursorArrow then reaper.MB("Could not load the cursorArrow cursor", "ERROR", 0) return false end
    cursorUndo          = reaper.JS_Mouse_LoadCursorFromFile(filename.."js_Mouse editing - Undo.cur", true)
    if not cursorUndo then reaper.MB("Could not load the cursorUndo cursor", "ERROR", 0) return false end
    cursorRedo          = reaper.JS_Mouse_LoadCursorFromFile(filename.."js_Mouse editing - Redo.cur", true)
    if not cursorRedo then reaper.MB("Could not load the cursorRedo cursor", "ERROR", 0) return false end 
    
    -- Display something onscreen as quickly as possible, for better user responsiveness
    SetupDisplayZones()
    
    
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
if mainOK and mainRetval then DEFER_pcall() end -- START LOOPING!


