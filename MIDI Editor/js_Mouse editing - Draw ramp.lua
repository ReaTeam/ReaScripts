--[[
ReaScript name: js_Mouse editing - Draw ramp.lua
Version: 4.55
Author: juliansader
Website: http://forum.cockos.com/showthread.php?t=176878
Donation: https://www.paypal.me/juliansader
Provides: [main=midi_editor,midi_inlineeditor,main] .
About:
  # DESCRIPTION
  
  Draw linear, curved or sine ramps of MIDI CCs and automation envelopes events in real time.
  
  Works in automation envelopes as well as inline MIDI editors and full MIDI editors.
        
  This script was conceived before REAPER v6 introduced CC envelopes, and was intended as a workaround to quickly draw smooth ramps.
  Now that REAPER has native CC envelopes, the script is largely deprecated.
  
  * SNAP TO GRID: If snap to grid is enabled in the MIDI editor, the endpoints of the 
      ramp will snap to grid, allowing precise positioning of the ramp 
      (allowing, for example, the insertion of a pitch riser at the
      exact position of a note).  
    Holding down Shift will override snap-to-grid.
  
  * CHASING START VALUES: Right-clicking toggles between chasing existing CC values at the line start position, 
      and starting at the mouse's original vertical position.  Chasing ensures that
      CC values change smoothly. 
    In the USER AREA, the user can customize whether chasing should interpolate envelope segments.
      
  * LINEAR OR SINE SHAPES: Clicking the middle button toggles between a linear shape and a sine shape,
      which can be tweaked into other shapes such as parabolic.
  
  * TWEAK THE CURVE: By using the mousewheel, the shape of the ramp can be tweaked. 
      Linear ramps can be smoothly morphed to parabolic, for example. 
       
  * SKIP REDUNDANT CCs: This script (like all other js_ scripts that insert new CCs) can optionally 
      skip redundant CCs (that is, CCs with the same value as the preceding CC). 
      This is controlled by the script "js_Option - Toggle skip redundant events when inserting CCs".
      
  * ZOOM-DEPENDENT RESOLUTION: CCs and envelope points are inserted at a maximum density set in 
      Preferences -> MIDI editor -> "Events per quarter note when drawing in CC lanes".
    Since REAPER v6 now has CC envelopes, a high CC density is not necessary for smooth ramps any more,
      so in the USER AREA, the user can customize whether the resolution should be zoom dependent.
  
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
      * Any keystroke: Terminates the script.
  
  
  STARTING AT MINIMUM OR MAXIMUM
  
  In order to start a ramp at the minimum or maximum value, the starting position of the mouse can be slightly outside the target lane.
  
  In the case of MIDI, the mouse can be positioned over a CC lane divider.
  
  In the case of automation envelopes, the selected envelope takes precedence (whether take or track): 
      If the mouse starting position is close to the selected envelope, the selected envelope will be edited, even if the starting position was inside another lane.
                    
                    
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
  
     * Keyboard: Pressing any key (except Shift) while the script is running.
     
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
  * v4.20 (2019-04-25)
    + Clicking armed toolbar button disarms script.
    + Improved starting/stopping: 1) Any keystroke terminates script; 2) Alternatively, hold shortcut for second and release to terminate.
  * v4.30 (2019-09-18)
    + Preliminary compatibility with CC envelopes. (Visual appearance still needs to be improved.)
  * v4.50 (2020-05-17)
    + Works in automation envelopes.
    + Better compatibility with CC envelopes.
  * v4.52 (2020-06-30)
    + Fix bug when no automation options.
  * v4.55 (2020-07-05)
    + macOS: Fixed jumping mouse cursor.
    + Automation: Edit nearest envelope instead of waiting for mouse to enter lane.
]]

----------------------------------------
-- USER AREA
-- Settings that the user can customize.
 
    -- If no default shape is set, the script will recall the last-used shape
    --local defaultShape = "sine" -- "sine", "fast start" or "fast end"
    
    -- Should the script follow the MIDI editor's snap-to-grid setting, or should the
    --    script ignore the snap-to-grid setting and never snap to the grid?
    local neverSnapToGrid = false -- true or false
    
    -- Should chased values interpolate the envelope segment between nearest CCs to left and right?
    -- Or should chased values be level with nearest CCs to left or right?
    local chasingInterpolatesEnvelope = true -- true or false: 
    
    -- Should the number of points per ramp be limited to about 16?
    local zoomDependentResolution = true -- true or false
   
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
local tDel = {} -- Envelope points that are visible onscreen, and that may be deleted (in real time) while drawing ramp
local tMIDI = {}

-- As the MIDI events of the ramp are calculated, each event wil be assmebled into a short string and stored in the tLine table.   
--local tLine = {}
--local lastPPQPos -- to calculate offset to next CC
--local lastValue -- To compare against last value, if skipRedundantCCs
 
-- Starting values and position of mouse 
-- mouseOrigCCLane: (CC0-127 = 7-bit CC, 0x100|(0-31) = 14-bit CC, 0x200 = velocity, 0x201 = pitch, 
--    0x202=program, 0x203=channel pressure, 0x204=bank/program select, 
--    0x205=text, 0x206=sysex, 0x207=off velocity)
local laneMinValue, laneMaxValue = nil, nil-- The minimum and maximum values in the target lane
local mouseOrigCCLane, mouseOrigCCValue, mouseOrigPPQPos, mouseOrigPitch, mouseOrigCCLaneID = nil, nil, nil, nil, nil
local snappedOrigPPQPos = nil -- If snap-to-grid is enabled, these will give the closest grid PPQ to the left. (Swing is not implemented.)

-- This script can work in inline MIDI editors as well as the main MIDI editors
-- The two types of editors require some different code, though.  
-- In particular, if in an inline editor, functions from the SWS extension will be used to track mouse position.
-- In the main editor, WIN32/SWELL functions from the js_ReaScriptAPI extension will be used.
local isInline, editor = nil, nil

-- Tracking the new value and position of the mouse while the script is running
local mouseX, mouseY = nil, nil
local mouseNewCCLane, mouseNewCCValue, mouseNewPPQPos, mouseNewPitch, mouseNewCCLaneID = nil, nil, nil, nil, nil
local snappedNewPPQPos = nil

-- The script can be controlled by mousewheel, mouse buttons an mouse modifiers.  These are tracked by the following variables.
local mouseState
local prevMouseTime = 0
local prevDelta
--local mousewheel = 1 -- Will be loaded from extState below

-- The script will intercept keystrokes, to allow control of script via keyboard, 
--    and to prevent inadvertently running other actions such as closing MIDI editor by pressing ESC
local VKLow, VKHi, VKShift = 9, 0xFE, 0x10 --0xA5 -- 0x13, 0xFE -- Range of virtual key codes to check for key presses: Skip mouse modifiers, which will be checked with Mouse_GetState
local VKState0 = string.rep("\0", VKHi-VKLow) --+1
--VKState0 = VKState0:sub(1,VKShift-VKLow-1)..VKState0:sub(VKShift-VKLow+1,nil)
local dragTime = 0.5 -- How long must the shortcut key be held down before left-drag is activated?
local dragTimeStarted = false

-- REAPER preferences and settings that will affect the drawing/selecting of new events in take
local isSnapEnabled = false -- Will be changed to true if snap-to-grid is enabled in the editor
local activeChannel -- In case new MIDI events will be inserted, what is the default channel?
local editAllChannels = nil -- Is the MIDI editor's channel filter enabled?
local CCDensity = nil-- CC resolution as set in Preferences -> MIDI editor -> "Events per quarter note when drawing in CC lanes"
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
local loopStartTick = nil -- Start of loop iteration under mouse 
local sourceLengthTicks = nil -- = reaper.BR_GetMidiSourceLenPPQ(activeTake)
local minimumTick, maximumTick = nil -- The mouse PPO position should not go outside the boundares of either the visible item or the underlying MIDI source

-- Some internal stuff that will be used to set up everything
local  _, activeItem, activeTake = nil, nil, nil
local window, segment, details = nil, nil, nil -- given by the SWS function reaper.BR_GetMouseCursorContext()
local startTime = 0
local sectionID, commandID

-- If the mouse is over a MIDI editor, these variables will store the on-screen layout of the editor.
-- NOTE: Getting the MIDI editor scroll and zoom values is slow, since the item chunk has to be parsed.
--    This script will therefore not update these variables after getting them once.  The user should not scroll and zoom while the script is running.
local activeTakeChunk
local ME_l, ME_t, ME_r, ME_b = nil, nil, nil, nil -- screen coordinates of MIDI editor, with frame
local ME_LeftmostTick, ME_PixelsPerTick, ME_PixelsPerSecond = nil, nil, nil -- horizontal scroll and zoom
local ME_LeftmostTime, ME_RightmostTime, ME_RightmostTick, ME_TargetTopPixel, ME_TargetBottomPixel = nil, nil, nil, nil, nil
local ME_TopPitch, ME_PixelsPerPitch = nil, nil -- vertical scroll and zoom
local ME_CCLaneTopPixel, ME_CCLaneBottomPixel = nil, nil
local ME_midiviewLeftPixel, ME_midiviewTopPixel, ME_midiviewRightPixel, ME_midiviewBottomPixel = nil, nil, nil, nil
local ME_TimeBase =nil
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
local baseShape   = (defaultShape == "sine" and "sine") or (defaultShape == "fast start" and "linear") or (defaultShape == "fast end" and "linear") or baseShape or "linear"
local mustChase   = (mustChase == "true")
local mousewheel  = (defaultShape == "sine" and 1) or (defaultShape == "fast start" and 0.5) or (defaultShape == "fast end" and 2) or math.max(0.025, math.min(40, tonumber(mousewheel) or 1)) -- Track mousewheel movement
local factor = 1.04
local defaultFlagChar = '\1' -- Square shape | selected. Later, toggle states of shape actions will be queried.

 activeEnv, activeAI, activeTrack, arrStartTime, arrEndTime, envTopPixel, envBottomPixel, envHeight, envStartTime, envEndTime, envMinValue, envMaxValue = nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil
local winRectHeight, winRectWidth = nil, nil
local macOS = reaper.GetOS():match("OSX")



-----------------------------
function DEFER_DrawEnvelope()

    local mouseTimePos = arrStartTime + mouseX/pixelsPerSec 
    if isSnapEnabled and mouseState&8 == 0 then mouseTimePos = reaper.SnapToGrid(0, mouseTimePos) end 
    if mouseTimePos < envStartTime then mouseTimePos = envStartTime elseif mouseTimePos >= envEndTime then mouseTimePos = envEndTime-0.00000001 end
    
    local mouseValue = envMinValue+(envMaxValue-envMinValue)*(envBottomPixel-mouseY)/envHeight
    if mouseValue < envMinValue then mouseValue = envMinValue elseif mouseValue > envMaxValue then mouseValue = envMaxValue end
        
    if mouseTimePos < mouseOrigTimePos then
        rampLeftTimePos, rampRightTimePos, rampLeftValue, rampRightValue = mouseTimePos, mouseOrigTimePos, mouseValue, (mustChase and rightChasedValue or mouseOrigValue)
        baseValue, baseTimePos = rampRightValue, rampRightTimePos
    else
        rampLeftTimePos, rampRightTimePos, rampLeftValue, rampRightValue = mouseOrigTimePos, mouseTimePos, (mustChase and leftChasedValue or mouseOrigValue), mouseValue
        baseValue, baseTimePos = rampLeftValue, rampLeftTimePos
    end 
    local valueRange = mouseValue - baseValue
    
    -- Mousewheel values
    local power, mousewheelLargerThanOne = nil, nil
    if mousewheel >= 1 then 
        mousewheelLargerThanOne = true -- I expect that accessing local boolean variables are faster than comparing numbers
        power = mousewheel 
    else 
        power = 1/mousewheel 
    end  
    
    reaper.PreventUIRefresh(1)
    
    -- To ensure that points that were previously deleted are re-inserted if the ramp range contracts, delete/redraw range must include ramp range of previous cycle
    local deleteStartTimePos = ((prevRampLeftTimePos or mouseOrigTimePos) < rampLeftTimePos) and prevRampLeftTimePos or rampLeftTimePos
    local deleteEndTimePos   = ((prevRampRightTimePos or mouseOrigTimePos) > rampRightTimePos) and prevRampRightTimePos or rampRightTimePos
    prevRampLeftTimePos, prevRampRightTimePos = rampLeftTimePos, rampRightTimePos
    reaper.DeleteEnvelopePointRangeEx(activeEnv, activeAI, playrate*(deleteStartTimePos-envOffset)-0.000001, playrate*(deleteEndTimePos-envOffset)+0.000001)
    
    -- Delete or re-insert points to the left of the ramp
    for p = 1, #tDel do
        local tP = tDel[p]
        if tP.time >= rampLeftTimePos then 
            break
        elseif deleteStartTimePos <= tP.time then
            reaper.InsertEnvelopePointEx(activeEnv, activeAI, playrate*(tP.time-envOffset), tP.value, tP.shape, tP.tension, tP.selected, true)
        end
    end 
    reaper.InsertEnvelopePointEx(activeEnv, activeAI, playrate*(rampLeftTimePos-envOffset), rampLeftValue, 5, 0, true, true)
    
    local prevValue = rampLeftValue
    
    -- TIMEBASE = TIME
    if false then -- timebase == 0 then -- Always use timebase = beats
        local timeRange  = rampRightTimePos - rampLeftTimePos
        -- Zoom resolution
        local _, _, bpm = reaper.TimeMap_GetTimeSigAtTime(0, rampLeftTimePos)
        local step = 60 / (CCDensity*bpm)
        if zoomDependentResolution then
            local numPoints16 = (timeRange//step)>>4
            while numPoints16 ~= 0 do
                step = step*2
                numPoints16 = numPoints16>>1
            end
        end
        
        for t = rampLeftTimePos+step, rampRightTimePos-0.000001, step do
            local insertValue
            local distance = baseTimePos-t
            if distance < 0 then distance = -distance end
            if baseShape == "linear" then
                if mousewheelLargerThanOne then
                    insertValue = baseValue + valueRange*((distance/timeRange)^power)
                else
                    insertValue = mouseValue - valueRange*((1 - (distance/timeRange))^power)
                end
            else
                if mousewheelLargerThanOne then
                    insertValue = baseValue + valueRange*(  (0.5*(1 - m_cos(m_pi*(distance/timeRange)))) ^power )
                else
                    insertValue = mouseValue - valueRange*(  (0.5*(1 - m_cos(m_pi*(1 - (distance/timeRange))))) ^power  )
                end
            end
            
            if insertValue ~= insertValue then insertValue = baseValue -- Undefined?
            elseif insertValue < envMinValue then insertValue = envMinValue
            elseif insertValue > envMaxValue then insertValue = envMaxValue
            end
            if insertValue ~= prevValue or not skipRedundantCCs then
                reaper.InsertEnvelopePointEx(activeEnv, activeAI, playrate*(t-envOffset), insertValue, 5, 0, true, true)
                prevValue = insertValue
            end
        end
        
    -- TIMEBASE = BEATS
    else
        local leftQN  = reaper.TimeMap2_timeToQN(0, rampLeftTimePos)
        local rightQN = reaper.TimeMap2_timeToQN(0, rampRightTimePos)
        local baseQN  = (baseTimePos == rampLeftTimePos) and leftQN or rightQN
        local timeRange  = rightQN-leftQN
        -- Zoom resolution
        local step = 1 / CCDensity
        if zoomDependentResolution then
            local numPoints16 = (timeRange//step)>>4
            while numPoints16 ~= 0 do
                step = step*2
                numPoints16 = numPoints16>>1
            end
        end
        
     
        for t = leftQN+step, rightQN-0.001, step do
            local insertValue
            local distance = baseQN-t
            if distance < 0 then distance = -distance end
            if baseShape == "linear" then
                if mousewheelLargerThanOne then
                    insertValue = baseValue + valueRange*((distance/timeRange)^power)
                else
                    insertValue = mouseValue - valueRange*((1 - (distance/timeRange))^power)
                end
            else
                if mousewheelLargerThanOne then
                    insertValue = baseValue + valueRange*(  (0.5*(1 - m_cos(m_pi*(distance/timeRange)))) ^power )
                else
                    insertValue = mouseValue - valueRange*(  (0.5*(1 - m_cos(m_pi*(1 - (distance/timeRange))))) ^power  )
                end
            end
            
            if insertValue ~= insertValue then insertValue = baseValue -- Undefined?
            elseif insertValue < envMinValue then insertValue = envMinValue
            elseif insertValue > envMaxValue then insertValue = envMaxValue
            end
            if insertValue ~= prevValue or not skipRedundantCCs then
                reaper.InsertEnvelopePointEx(activeEnv, activeAI, playrate*(reaper.TimeMap_QNToTime(t)-envOffset), insertValue, 5, 0, true, true)
                prevValue = insertValue
            end
        end
    end
            
    reaper.InsertEnvelopePointEx(activeEnv, activeAI, playrate*(rampRightTimePos-envOffset), rampRightValue, 5, 0, true, true)
    
    -- Delete or re-insert points to the right of the ramp
    for p = #tDel, 1, -1 do 
        local tP = tDel[p]
        if tP.time <= rampRightTimePos then 
            break
        elseif tP.time <= deleteEndTimePos then
            reaper.InsertEnvelopePointEx(activeEnv, activeAI, playrate*(tP.time-envOffset), tP.value, tP.shape, tP.tension, tP.selected, true)
        end
    end
    reaper.Envelope_SortPointsEx(activeEnv, activeAI)
    
    -- This is a "trick" from the LFO Tool: to get REAPER to apply env points to the tempo envelope, set one tempo/timesig marker via the tempo/timesig API:
    if activeEnv == tempoEnv then
        local firstOK, timepos, measurepos, beatpos, bpm, timesig_num, timesig_denom, lineartempo = reaper.GetTempoTimeSigMarker(0, 0)
        if firstOK then
            reaper.SetTempoTimeSigMarker(0, 0, timepos, -1, -1, bpm, timesig_num, timesig_denom, lineartempo)
            --reaper.UpdateTimeline()
        end
    end
    reaper.PreventUIRefresh(-1) 
    
    return true -- Continue drawing
end


--#################################
-----------------------------------
function GetMouseValue(limitInside)
    local mouseNewCCValue
    if not mouseY then 
        local x, y = reaper.GetMousePosition()
        local _, mouseY = reaper.JS_Window_ScreenToClient(windowUnderMouse, x, y)
    end
    mouseNewCCValue = laneMinValue + (laneMaxValue-laneMinValue) * (tME_Lanes[mouseOrigCCLaneID].bottomPixel - mouseY) / (tME_Lanes[mouseOrigCCLaneID].bottomPixel - tME_Lanes[mouseOrigCCLaneID].topPixel)
    if limitInside then
        -- May the mouse CC value go beyond lane limits?
        if mouseNewCCValue > laneMaxValue then mouseNewCCValue = laneMaxValue
        elseif mouseNewCCValue < laneMinValue then mouseNewCCValue = laneMinValue
        else mouseNewCCValue = (mouseNewCCValue+0.5)//1
        end
    end
    return mouseNewCCValue
end


--##################################
------------------------------------
local function GetMouseTick(trySnap)

    local snappedNewTick
    
    -- MOUSE NEW TICK / PPQ VALUE (horizontal position)
    -- Snapping not relevant to this script
    if not mouseX then 
        local x, y = reaper.GetMousePosition()
        mouseX = reaper.JS_Window_ScreenToClient(windowUnderMouse, x, y)
    end
    if ME_TimeBase == "beats" then
        mouseNewPPQPos = ME_LeftmostTick + mouseX/ME_PixelsPerTick
    else -- ME_TimeBase == "time"
        mouseNewPPQPos = reaper.MIDI_GetPPQPosFromProjTime(activeTake, ME_LeftmostTime + mouseX/ME_PixelsPerSecond )
    end
    mouseNewPPQPos = mouseNewPPQPos - loopStartTick -- Adjust mouse PPQ position for looped items
    
    -- Adjust mouse PPQ position for snapping
    if not trySnap or not isSnapEnabled or (mouseState and mouseState&8 == 8) then -- While shift is held down, don't snap
        snappedNewTick = (mouseNewPPQPos+0.5)//1
    elseif isInline then
        local timePos = reaper.MIDI_GetProjTimeFromPPQPos(activeTake, mouseNewPPQPos)
        local snappedTimePos = reaper.SnapToGrid(0, timePos) -- If snap-to-grid is not enabled, will return timePos unchanged
        snappedNewTick = (reaper.MIDI_GetPPQPosFromProjTime(activeTake, snappedTimePos) + 0.5)//1
    else
        local mouseQNpos = reaper.MIDI_GetProjQNFromPPQPos(activeTake, mouseNewPPQPos) -- Mouse position in quarter notes
        local roundedGridQN = math.floor((mouseQNpos/QNperGrid)+0.5)*QNperGrid -- nearest grid to mouse position
        snappedNewTick = (reaper.MIDI_GetPPQPosFromProjQN(activeTake, roundedGridQN) + 0.5)//1
    end
    snappedNewTick = math.max(minimumTick, math.min(maximumTick, snappedNewTick))
    
    return snappedNewTick
end


--#######################
-------------------------
function DEFER_DrawMIDI()
    local lineLeftPPQPos, lineLeftValue, lineRightPPQPos, lineRightValue = nil, nil, nil, nil -- The CCs will be inserted into the MIDI string from left to right

    local mouseNewCCValue = GetMouseValue(true)
    
    local snappedNewPPQPos = GetMouseTick(true)
        
    -- LINE DIRECTION?   
    -- Prefer to draw the line from left to right, so check whether mouse is to left or right of starting point
    -- The line's startpoint event 'chases' existing CC values.
    if snappedNewPPQPos >= snappedOrigPPQPos then
        mouseToRight    = true
        lineLeftPPQPos  = snappedOrigPPQPos
        baseValue       = mustChase and leftChasedValue or mouseOrigCCValue
        lineRightPPQPos = snappedNewPPQPos --isSnapEnabled and (snappedNewPPQPos-1) or snappedNewPPQPos -- -1 because rightmost tick actually falls outside time selection
        basePPQPos      = lineLeftPPQPos
    else 
        mouseToRight    = false
        lineLeftPPQPos  = snappedNewPPQPos
        lineRightPPQPos = snappedOrigPPQPos --isSnapEnabled and (snappedOrigPPQPos-1) or snappedOrigPPQPos -- -1 because rightmost tick actually falls outside time selection
        baseValue       = mustChase and rightChasedValue or mouseOrigCCValue
        basePPQPos      = lineRightPPQPos
    end    
    local PPQrange = lineRightPPQPos - lineLeftPPQPos
    local valueRange = mouseNewCCValue - baseValue
    
    -- Zoom resolution
    local PPerCC = PPerCC
    if zoomDependentResolution then
        local numPoints16 = (PPQrange//PPerCC)>>4
        while numPoints16 ~= 0 do
            PPerCC = PPerCC*2
            numPoints16 = numPoints16>>1
        end
    end
            
    -- Mousewheel values
    local power, mousewheelLargerThanOne = nil, nil
    if mousewheel >= 1 then 
        mousewheelLargerThanOne = true -- I expect that accessing local boolean variables are faster than comparing numbers
        power = mousewheel 
    else 
        power = 1/mousewheel 
    end           
    
    
    -- Delete overlapping events in same channel
    local lineInsertIndex = 0
    local lineInsertTick  = 0
    for _, tD in ipairs(tDel) do
        if tD.ticks < lineLeftPPQPos then --or tD.ticks > lineRightPPQPos then
            tMIDI[tD.index] = tD.event
            lineInsertIndex = tD.index
            lineInsertTick  = tD.ticks
        elseif tD.ticks <= lineRightPPQPos then
            tMIDI[tD.index] = "\0\0\0\0\0"
        elseif tMIDI[tD.index] == "\0\0\0\0\0" then
            tMIDI[tD.index] = tD.event
        else
            break
        end
    end
    
    
    -- Clean previous tLine.  All the new MIDI events will be stored in this table, 
    --    and later concatenated into a single string.
    local tLine = {}
    local c = 0 -- Count index in tLine - This is faster than using table.insert or even #table+1
    local lastPPQPos  = lineInsertTick
    local lastValue = nil
    
                -------
                local function InsertCC(insertPPQPos)
                    local insertValue
                    insertPPQPos = (insertPPQPos+0.5)//1
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
                    else insertValue = (insertValue + 0.5)//1
                    end
                    
                    local offset = insertPPQPos - lastPPQPos
                    if insertValue ~= lastValue or skipRedundantCCs == false then
                        if laneIsCC7BIT then
                            c = c + 1
                            tLine[c] = s_pack("i4BI4BBB", offset, 81, 3, 0xB0 | activeChannel, mouseOrigCCLane, insertValue)
                        elseif laneIsPITCH then
                            c = c + 1
                            tLine[c] = s_pack("i4BI4BBB", offset, 81, 3, 0xE0 | activeChannel, insertValue&127, insertValue>>7)
                        elseif laneIsCHANPRESS then
                            c = c + 1
                            tLine[c] = s_pack("i4BI4BB",  offset, 81, 2, 0xD0 | activeChannel, insertValue)
                        elseif laneIsPROGRAM then
                            c = c + 1
                            tLine[c] = s_pack("i4BI4BB",  insertPPQPos-lastPPQPos, 17, 2, 0xC0 | activeChannel, insertValue)
                        else -- laneIsCC14BIT
                            c = c + 1
                            tLine[c] = s_pack("i4BI4BBB", offset, 81, 3, 0xB0 | activeChannel, mouseOrigCCLane-256, insertValue>>7)
                            c = c + 1
                            tLine[c] = s_pack("i4BI4BBB", 0     ,  1, 3, 0xB0 | activeChannel, mouseOrigCCLane-224, insertValue&127)
                        end
                        lastValue = insertValue
                        lastPPQPos = insertPPQPos
                    end
                end
                -------

    -- Try to always insert one CC, even if range = 0
    if minimumTick <= lineLeftPPQPos and lineLeftPPQPos <= maximumTick then
        InsertCC(lineLeftPPQPos)   
    end  
    
    if lineLeftPPQPos < lineRightPPQPos-1 then
    
        for PPQPos = lineLeftPPQPos+PPerCC, lineRightPPQPos-2, PPerCC do
            if minimumTick <= PPQPos and PPQPos <= maximumTick then
                InsertCC(PPQPos)   
            end  
        end

        -- Insert the rightmost endpoint
        if minimumTick <= lineRightPPQPos-1 and lineRightPPQPos-1 <= maximumTick then 
            InsertCC(lineRightPPQPos)
        end
 
    end -- if lineLeftPPQPos <= lineRightPPQPos
                        
    -- Change shape of last CC to default
    if laneIsCC14BIT then if #tLine>1 then 
        tLine[#tLine-1] = tLine[#tLine-1]:sub(1,4)..defaultFlagChar..tLine[#tLine-1]:sub(6,nil) 
        end
    elseif #tLine>0 then
        tLine[#tLine] = tLine[#tLine]:sub(1,4)..defaultFlagChar..tLine[#tLine]:sub(6,nil) 
    end
    
    -- DRUMROLL... write the edited events into the MIDI string!  
    reaper.MIDI_SetAllEvts(activeTake, table.concat(tMIDI, "", 1, lineInsertIndex) 
                                    .. table.concat(tLine) 
                                    .. string.pack("i4Bs4", lineInsertTick-lastPPQPos, 0, "") 
                                    .. table.concat(tMIDI, "", lineInsertIndex+1, #tMIDI)) -- MIDIStringDeselected)    
    if isInline then reaper.UpdateItemInProject(activeItem) end
    takeIsSorted = false
    
    return true -- Continue drawing
end


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
local function DEFER_GetInputs()
    
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
    
    -- TAKE AND EDITOR STILL VALID?
    if editor and reaper.MIDIEditor_GetMode(editor) ~= 0 then return false end
    if isMIDI and not reaper.ValidatePtr2(0, activeTake, "MediaItem_Take*") then activeTake = nil return false end
    
    -- KEYBOARD: Script can be terminated by pressing key twice to start/stop, or by holding key and releasing after dragTime
    -- Recent versions of js_ReaScriptAPI ignore auto-repeared KEYDOWNs, so checking key presses is much simpler.
    local prevKeyState = keyState
    keyState = reaper.JS_VKeys_GetState(startTime-0.5):sub(VKLow, VKHi)
    keyState = keyState:sub(1,VKShift-VKLow)..keyState:sub(VKShift-VKLow+2,nil)
    if dragTimeStarted and keyState ~= prevKeyState and keyState == VKState0 then -- Only lift after every key has been lifted, to avoid immediately trigger action again. NOTE: modifier keys don't always send repeat KEYDOWN if held together with another key.
        return false
    end
    local keyDown = reaper.JS_VKeys_GetDown(prevCycleTime):sub(VKLow, VKHi)
    keyDown = keyDown:sub(1,VKShift-VKLow)..keyDown:sub(VKShift-VKLow+2,nil)
    if keyDown ~= VKState0 then return false end
    
    -- EXTSTATE: Other scripts can communicate with and control the other js_ scripts via ExtStates
    local extState = reaper.GetExtState("js_Mouse actions", "Status") or ""
    if extState == "" or extState == "Must quit" then return(false) end
    
    -- MOUSE MODIFIERS / LEFT CLICK / LEFT DRAG: Script can be terminated by left-clicking twice to start/stop, or by holding left button and releasing after dragTime
    -- This can detect left clicks even if the mouse is outside the MIDI editor
    local prevMouseState = mouseState or 0xFF
    mouseState = reaper.JS_Mouse_GetState(0xFF)
    if ((mouseState&53) > (prevMouseState&53)) -- 61 = 0b00110101 = Ctrl | Alt | Win | Left button
    or (dragTimeStarted and (mouseState&1) < (prevMouseState&1)) then
        return false
    end
    
    -- MOUSE POSITION: (New versions of the script don't quit if mouse moves out of CC lane, but will still quit if moves too far out of midiview.
    mouseX, mouseY = reaper.JS_Window_ScreenToClient(windowUnderMouse, reaper.GetMousePosition())
    if mouseX < 0 then mouseX = 0 reaper.JS_Mouse_SetPosition(reaper.JS_Window_ClientToScreen(windowUnderMouse, 0, mouseY))
    elseif mouseX >= winRectWidth then mouseX = winRectWidth-1 reaper.JS_Mouse_SetPosition(reaper.JS_Window_ClientToScreen(windowUnderMouse, mouseX, mouseY))
    end
    if mouseY < 0 then mouseY = 0 reaper.JS_Mouse_SetPosition(reaper.JS_Window_ClientToScreen(windowUnderMouse, mouseX, 0))
    elseif mouseY >= winRectHeight then mouseY = winRectHeight-1 reaper.JS_Mouse_SetPosition(reaper.JS_Window_ClientToScreen(windowUnderMouse, mouseX, mouseY))
    end
    --[[
    if macOS then
        if mouseY > winRectTop then mouseY = winRectTop reaper.JS_Mouse_SetPosition(mouseX, mouseY)
        elseif mouseY <= winRectBottom then mouseY = winRectBottom+1 reaper.JS_Mouse_SetPosition(mouseX, mouseY)
        end
        mouseX, mouseY = mouseX-winRectLeft, winRectTop-mouseY --reaper.JS_Window_ScreenToClient(windowUnderMouse, mouseX, mouseY)
    else
        if mouseY < winRectTop then mouseY = winRectTop reaper.JS_Mouse_SetPosition(mouseX, mouseY)
        elseif mouseY >= winRectBottom then mouseY = winRectBottom-1 reaper.JS_Mouse_SetPosition(mouseX, mouseY)
        end
        mouseX, mouseY = mouseX-winRectLeft, mouseY-winRectTop --reaper.JS_Window_ScreenToClient(windowUnderMouse, mouseX, mouseY)
    end]]
    if mouseX ~= prevMouseX or mouseY ~= prevMouseY then
        prevMouseX, prevMouseY = mouseX, mouseY
        mustCalculate = true
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
            --if keys&12 ~= 0 then return end
            if macOS then delta = -delta end -- macOS mousewheel events use opposite sign
            delta = ((delta > 0) and 1) or ((delta < 0) and -1) or 0 -- Standardize delta values so that can compare with previous
            delta = (mouseY >= mouseOrigY) and delta or -delta -- Ensure that moving wheel down/up always moves curve down/up
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
    
    --[[ LEFT DRAG: (If the left button was kept pressed for 1 second or longer, or after moving the mouse 20 pixels, assume left-drag, so quit when lifting.)
    peekOK, pass, time = reaper.JS_WindowMessage_Peek(windowUnderMouse, "WM_LBUTTONUP")
    if peekOK and (time > startTime + 1.5 )
              --or  (time > startTime and (mouseX < mouseOrigX - 20 or mouseX > mouseOrigX + 20 or mouseY < mouseOrigY - 20 or mouseY > mouseOrigY + 20))) 
              then  
        return false
    end]]
    
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
   
    -- TESTS DONE! DRAW RAMP!
    -- Scripts that extract selected MIDI events and re-concatenate them out of order (usually at the beginning of the MIDI string, for easier editing)
    --    cannot be auditioned in real-time while events are out of order, since such events are not played.
    -- If the mouse is held still, no editing is done, and instead the take is sorted, thereby temporarily allowing playback.
    -- NOTE:  Automation Envelope is sorted in every mustCalculate cycle.
    if isMIDI and not mustCalculate and not takeIsSorted then
        reaper.MIDI_Sort(activeTake)
        takeIsSorted = true
    end
    
    
    -- Tell pcall to loop again
    return mustCalculate and "mustCalculate" or true
        
end -- DEFERLOOP_TrackMouseAndUpdateMIDI()


--############################################################################################
----------------------------------------------------------------------------------------------
-- Why is the TrackMouseAndUpdateMIDI function isolated behind a pcall?
--    If the script encounters an error, all intercepts must first be released, before the script quits.
function DEFER_pcall()
    pcallOK, pcallRetval = pcall(DEFER_GetInputs)
    if pcallOK then
        if pcallRetval == "mustCalculate" then
            pcallOK, pcallRetval = pcall(DEFER_DrawFunction)
        end
        if pcallOK and pcallRetval then
            reaper.defer(DEFER_pcall)
        end
    end
end


----------------------------------------------------------------------------
function AtExit()
      
    -- Remove intercepts, restore original intercepts.  Do this first, because these are most important to restore, in case anything else goes wrong during AtExit.
    reaper.TrackCtl_SetToolTip("", 0, 0, false)
    if interceptKeysOK ~= nil then pcall(function() reaper.JS_VKeys_Intercept(-1, -1) end) end
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
        reaper.JS_WindowMessage_ReleaseWindow(windowUnderMouse)
        reaper.MB("The script encountered an error during startup:"
                .."\n\nmainOK: "..tostring(mainOK)
                .."\nmainRetval: "..tostring(mainRetval)
                .."\n\nPlease report these details in the \"MIDI Editor Tools\" thread in the REAPER forums."
                .."\n\nAll script intercepts of window messages have been released, which may affect other background scripts."
                , "ERROR", 0)
    end
    
    -- Save last-used line shape
    reaper.SetExtState("js_Draw ramp", "Last shape", tostring(baseShape) .. "," .. tostring(mousewheel) .. "," .. tostring(mustChase), true)
    
    -- Was an active take found, and does it still exist?  If not, don't need to do anything to the MIDI.
    if isMIDI and reaper.ValidatePtr2(0, activeTake, "MediaItem_Take*") and reaper.TakeIsMIDI(activeTake) then
        -- Before exiting, if DEFERLOOP_pcall was successfully executed, delete existing CCs in the line's range (and channel)
        -- The delete function will also ensure that the MIDI is re-uploaded into the active take.
        --[[if pcallOK == true then
            pcallOK, pcallRetval = pcall(DeleteExistingCCsInRange)
        end]]
        
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
    end

    -- DEFERLOOP_pcall was executed, but exception encountered:
    if pcallOK == false then
        reaper.JS_WindowMessage_ReleaseWindow(windowUnderMouse)
        if MIDIString then reaper.MIDI_SetAllEvts(activeTake, MIDIString) end -- Restore original MIDI
        reaper.MB("The script encountered an error."
                .."\n\n* The detailed error text has been copied to the console -- please report these details in the \"MIDI Editor Tools\" thread in the REAPER forums."
                .."\n\n* The original, unaltered MIDI has been restored to the take."
                .."\n\n* All script intercepts of window messages have been released, which may affect other background scripts."
                , "ERROR", 0)
        reaper.ShowConsoleMsg("\n\n" .. tostring(pcallRetval)) -- If pcall returs an error, the error data is in the second return value, namely deferMustContinue  
    end
    
 
    -- if script reached DEFERLOOP_pcall (or the WindowMessage section), pcallOK ~= nil, and must create undo point:
    --if pcallOK ~= nil then 
                  
        -- Write nice, informative Undo strings
        if isEnvelope then
            local envOK, envName = reaper.GetEnvelopeName(activeEnv)
            undoString = "Draw ramp in " .. (envOK and envName or "") .. " envelope"
        elseif laneIsCC7BIT then 
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

    if tME_Lanes[laneID] then
        ME_TargetTopPixel = tME_Lanes[laneID].topPixel
        ME_TargetBottomPixel = tME_Lanes[laneID].bottomPixel
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


--########################################
------------------------------------------
function GetInlineEditorCoordinates()

    local activeTakeNum = activeTakeNum or reaper.GetMediaItemTakeInfo_Value(activeTake, "IP_TAKENUMBER")
    local activeItem    = activeItem    or reaper.GetMediaItemTake_Item(activeTake)
    local activeTrack   = activeTrack   or reaper.GetMediaItem_Track(activeItem)
    
    local itemTop = reaper.GetMediaTrackInfo_Value(activeTrack, "I_TCPY") + reaper.GetMediaItemInfo_Value(activeItem, "I_LASTY")
    local itemHeight = reaper.GetMediaItemInfo_Value(activeItem, "I_LASTH")
    local itemBottom = itemTop + itemHeight - 1
    
    local showTakesInLanes = (reaper.GetToggleCommandState(40435) == 1)
    if not showTakesInLanes then -- Options: Show all takes in lanes (when room)
        inline_TakeTopPixel, inline_TakeBottomPixel = itemTop, itemBottom
    else
        local tT = {}
        showEmptyTakes = (reaper.GetToggleCommandState(41346) == 1) -- Options: Show empty take lanes (align takes by recording pass)?   Must skip empty take lanes
        if not showEmptyTakes then -- Must skip empty take lanes
            for t = 0, reaper.CountTakes(activeItem)-1 do
                local take = reaper.GetTake(activeItem, t)
                if reaper.ValidatePtr2(0, activeTake, "MediaItem_Take*") then
                    tT[#tT+1] = t
                end
            end
        else 
            for t = 0, reaper.CountTakes(activeItem)-1 do
                tT[#tT+1] = t
            end
        end
        local takeHeight = itemHeight/#tT
        for t = 1, #tT do
            if tT[t] == activeTakeNum then 
                inline_TakeTopPixel    = (itemTop + (t-1)*takeHeight)//1
                inline_TakeBottomPixel = (inline_TakeTopPixel + takeHeight - 0.5)//1
                break 
            end
        end
    end
    return inline_TakeTopPixel, inline_TakeBottomPixel
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
    
    -- MIDI editor and inline editor both need to know then active channel.  Inline is always timebase = time.
    activeChannel, ME_TimeBase = activeTakeChunk:match("\nCFGEDIT %S+ %S+ %S+ %S+ %S+ %S+ %S+ %S+ (%S+) %S+ %S+ %S+ %S+ %S+ %S+ %S+ %S+ %S+ (%S+)")
    activeChannel   = tonumber(activeChannel)
    if not activeChannel then
        reaper.MB("Could not determine the MIDI filter and active MIDI channel.", "ERROR", 0)
        return false
    else
        activeChannel = activeChannel - 1 
    end
    
    -- The MIDI editor scroll and zoom are hidden within the CFGEDITVIEW field 
    -- If the MIDI editor's timebase = project synced or project time, horizontal zoom is given as pixels per second.  If timebase is beats, pixels per tick
    _, ME_Width, ME_Height = reaper.JS_Window_GetClientSize(windowUnderMouse) --takeChunk:match("CFGEDIT %S+ %S+ %S+ %S+ %S+ %S+ %S+ %S+ %S+ %S+ %S+ %S+ (%S+) (%S+) (%S+) (%S+)") 
        if not _ then reaper.MB("Could not determine the MIDI editor's client window pixel coordinates.", "ERROR", 0) return(false) end
        if ME_Width < 100 or ME_Height < 100 then reaper.MB("The MIDI editor is too small for editing with the mouse", "ERROR", 0) return(false) end
    if isInline then
        ME_LeftmostTime, ME_RightmostTime = reaper.GetSet_ArrangeView2(0, false, 0, 0)
        ME_LeftmostTick = reaper.MIDI_GetPPQPosFromProjTime(activeTake, ME_LeftmostTime)
        ME_RightmostTick = reaper.MIDI_GetPPQPosFromProjTime(activeTake, ME_RightmostTime)
        ME_PixelsPerSecond = reaper.GetHZoomLevel() 
        ME_TimeBase = "time"
        inline_TakeTopPixel, inline_TakeBottomPixel = GetInlineEditorCoordinates()
        if not (inline_TakeTopPixel and inline_TakeBottomPixel) then reaper.MB("Could not determine the coordinates of the inline editor.", "ERROR", 0) return false end
    else
        -- The MIDI editor scroll and zoom are hidden within the CFGEDITVIEW field 
        -- If the MIDI editor's timebase = project synced or project time, horizontal zoom is given as pixels per second.  If timebase is beats, pixels per tick
        local ME_HorzZoom
        ME_LeftmostTick, ME_HorzZoom, ME_TopPitch, ME_PixelsPerPitch = activeTakeChunk:match("\nCFGEDITVIEW (%S+) (%S+) (%S+) (%S+)")
        ME_LeftmostTick, ME_HorzZoom, ME_TopPitch, ME_PixelsPerPitch = tonumber(ME_LeftmostTick), tonumber(ME_HorzZoom), 127-tonumber(ME_TopPitch), tonumber(ME_PixelsPerPitch)
            if not (ME_LeftmostTick and ME_HorzZoom and ME_TopPitch and ME_PixelsPerPitch) then 
                reaper.MB("Could not determine the MIDI editor's zoom and scroll positions.", "ERROR", 0) 
                return(false) 
            end
        ME_LeftmostTime = reaper.MIDI_GetProjTimeFromPPQPos(activeTake, ME_LeftmostTick)
        
        ME_TimeBase = (ME_TimeBase == "0" or ME_TimeBase == "4") and "beats" or "time"
        if ME_TimeBase == "beats" then
            ME_PixelsPerTick = ME_HorzZoom
            ME_RightmostTick = ME_LeftmostTick + ME_Width/ME_PixelsPerTick
        else
            ME_PixelsPerSecond = ME_HorzZoom
            ME_RightmostTick   = reaper.MIDI_GetPPQPosFromProjTime(activeTake, ME_LeftmostTime + ME_Width/ME_PixelsPerSecond)
        end
    end

    -- Now get the heights and types of all the CC lanes.
    -- !!!! WARNING: IF THE EDITOR DISPLAYS TWO LANE OF THE SAME TYPE/NUMBER, FOR EXAMPLE TWO MODWHEEL LANES, THE CHUNK WILL ONLY LIST ONE, AND THIS CODE WILL THEREFORE FAIL !!!!
    -- !!!! WARNING: IF THE NOTES AREA IS TOO SMALL, CHUNK VALUES ARE ALSO INACCURATE !!!!
    -- Chunk lists CC lane from top to bottom, so must first get each lane's height, from top to bottom, 
    --    then go in reverse direction, from bottom to top, calculating screen coordinates.
    -- Lane heights include lane divider (9 pixels high in MIDI editor, 8 in inline editor)
    local laneDividerHeight = isInline and 6 or 9
    
    local laneID = -1 -- lane = -1 is the notes area
    tME_Lanes[-1]   = {laneType = -1} --, inlineHeight = 100} -- inlineHeight is not accurate, but will simply be used to indicate that this "lane" is large enough to be visible.
    tME_Lanes[-1.5] = {laneType = "ruler"} --, inlineHeight = 100}
    for vellaneStr in activeTakeChunk:gmatch("\nVELLANE [^\n]+") do 
        local laneType, ME_LaneHeight, inline_LaneHeight = vellaneStr:match("VELLANE (%S+) (%d+) (%d+)")
        -- Lane number as used in the chunk differ from those returned by API functions such as MIDIEditor_GetSetting_int(editor, "last_clicked")
        laneType, ME_LaneHeight, inline_LaneHeight = ConvertCCTypeChunkToAPI(tonumber(laneType)), tonumber(ME_LaneHeight), tonumber(inline_LaneHeight)
        if not (laneType and ME_LaneHeight and inline_LaneHeight) then
            reaper.MB("Could not parse the VELLANE fields in the item state chunk.", "ERROR", 0)
            return(false)
        end    
        laneID = laneID + 1   
        tME_Lanes[laneID] = {VELLANE = vellaneStr, laneType = laneType, height = isInline and inline_LaneHeight or ME_LaneHeight}
        tME_Lanes[laneID-0.5] = {laneType = "divider", height = laneDividerHeight} --, inlineHeight = laneDividerHeight}
    end
    
        
    -- Now that we have the MIDI editor width, can calculate rightmost time for MIDI editor.
    -- Inline editor already got arrange view rightmostTime above
    if not isInline then
        if ME_TimeBase == "beats" then
            ME_RightmostTick = ME_LeftmostTick + (ME_Width-1)/ME_PixelsPerTick
            ME_RightmostTime = reaper.MIDI_GetProjTimeFromPPQPos(activeTake, ME_RightmostTick)
        else
            ME_RightmostTime = ME_LeftmostTime + (ME_Width-1)/ME_PixelsPerSecond
            --ME_RightmostTick = reaper.MIDI_GetPPQPosFromProjTime(activeTake, ME_RightmostTime)
        end
    end
        
    -- And now, calculate top and bottom pixels of each lane -- AND lane divider
    local laneBottomPixel   = isInline and inline_TakeBottomPixel or ME_Height-1
    local rulerHeight       = isInline and 17 or 62
    for i = #tME_Lanes, 0, -1 do
        tME_Lanes[i].bottomPixel = laneBottomPixel 
        tME_Lanes[i].topPixel    = laneBottomPixel - tME_Lanes[i].height + laneDividerHeight + 1
        tME_Lanes[i-0.5].bottomPixel = tME_Lanes[i].topPixel - 1
        tME_Lanes[i-0.5].topPixel    = tME_Lanes[i].topPixel - 9
        laneBottomPixel = laneBottomPixel - tME_Lanes[i].height
    end
        
    -- Notes area height is remainder after deducting 1) total CC lane height and 2) height (62 pixels) of Ruler/Marker/Region area at top of midiview
    tME_Lanes[-1].bottomPixel = laneBottomPixel
    tME_Lanes[-1].topPixel    = isInline and (inline_TakeTopPixel+rulerHeight) or rulerHeight
    tME_Lanes[-1].height      = laneBottomPixel-rulerHeight+1
    --ME_BottomPitch = ME_TopPitch - math.floor(tME_Lanes[-1].height / ME_PixelsPerPitch)
    
    -- Ruler/Marker/Region
    tME_Lanes[-1.5].bottomPixel = tME_Lanes[-1].topPixel - 1
    tME_Lanes[-1.5].topPixel    = isInline and inline_TakeTopPixel or 0
    tME_Lanes[-1.5].height      = rulerHeight
    
    return true
    
end -- function SetupMIDIEditorInfoFromTakeChunk


--#########################################
-------------------------------------------
-- x and y are *client* coordinates
function GetCCLaneIDFromPoint(x, y)
    if 0 <= x and x < ME_Width then
        for i = -1, #tME_Lanes do
            if y < tME_Lanes[i].topPixel then
                return i - 0.5
            elseif y <= tME_Lanes[i].bottomPixel then
                return i
            end
        end
        return #tME_Lanes + 0.5
    end
end


-----------------------------
function SetupEnvelopeContext()
    
    -- Why not use the SWS function to get the envelope context?  Because selected envelope should be targeted, even if mouse is slightly outside the lane.
    
    local activeEnv, activeAI, activeTrack, arrH, arrW, trackY, envHeight, envTop, envBottom, gotEnvelope = nil, nil, nil, nil, nil, nil, nil, nil, nil, nil
    
    tempoEnv = reaper.GetTrackEnvelopeByName(reaper.GetMasterTrack(0), "Tempo map")


    -- First check if the mouse is close enough to the selected envelope
    activeEnv = reaper.GetSelectedEnvelope(0)
    if activeEnv then --and reaper.ValidatePtr2(0, activeEnv, "TrackEnvelope*") then -- Does ValidatePtr work with TAKE envelopes?
        -- Is take envelope?
        -- Even if take env, must get parent track, since env position is given relative to track
        activeTake = reaper.Envelope_GetParentTake(activeEnv)
        if activeTake and reaper.ValidatePtr2(0, activeTake, "MediaItem_Take*") then
            activeItem = reaper.GetMediaItemTake_Item(activeTake)
            local itemStart = reaper.GetMediaItemInfo_Value(activeItem, "D_POSITION")
            local itemEnd = itemStart + reaper.GetMediaItemInfo_Value(activeItem, "D_LENGTH")
            if itemStart <= mouseOrigTimePos and mouseOrigTimePos <= itemEnd then
                activeTrack = reaper.GetMediaItemTake_Track(activeTake)
            else
                activeEnv, activeTake = nil, nil
            end
        -- Track envelope
        else
            activeTrack = reaper.GetEnvelopeInfo_Value(activeEnv, "P_TRACK", activeEnv)
        end 
        if activeTrack and reaper.ValidatePtr2(0, activeTrack, "MediaTrack*") then 
            trackY = reaper.GetMediaTrackInfo_Value(activeTrack, "I_TCPY")
            envTop = trackY + reaper.GetEnvelopeInfo_Value(activeEnv, "I_TCPY_USED")
            envHeight = reaper.GetEnvelopeInfo_Value(activeEnv, "I_TCPH_USED")
            envBottom = envTop + envHeight - 1
            if envHeight > 5 and envTop >= 0 and envBottom <= winRectHeight and envTop-50 < mouseOrigY and mouseOrigY < envBottom+50 then -- Is selected envelope visible onscreen, and is mouse nearby?
                gotEnvelope = true 
            end
        end
    end
  
    -- Check if mouse is OVER a TAKE envelope
    if not gotEnvelope then 
        -- If mouse is over take, first try to find take envelopes, then track ones (which may be displayed "in media lane")
        activeItem, activeTake  = reaper.GetItemFromPoint(mouseOrigScreenX, mouseOrigScreenY, true)
        if activeTake and reaper.ValidatePtr2(0, activeTake, "MediaItem_Take*") then
            activeTrack = reaper.GetMediaItemTake_Track(activeTake)
            if activeTrack and reaper.ValidatePtr2(0, activeTrack, "MediaTrack*") then 
                trackY = reaper.GetMediaTrackInfo_Value(activeTrack, "I_TCPY")
                for e = 0, reaper.CountTakeEnvelopes(activeTake)-1 do
                    local env = reaper.GetTakeEnvelope(activeTake, e)
                    local envTop = trackY + reaper.GetEnvelopeInfo_Value(env, "I_TCPY")
                    local envHeight = reaper.GetEnvelopeInfo_Value(env, "I_TCPH")
                    local envBottom = envTop + envHeight - 1
                    if envTop <= mouseOrigY and mouseOrigY <= envBottom then 
                        gotEnvelope = true 
                        activeEnv = env
                        break
                    end
                end
            end
        end
    end
    
    -- Check if mouse is CLOSE TO a TRACK envelope
    if not gotEnvelope then
        prevEnv, prevTrack, prevDistance = nil, nil, math.huge
        track = reaper.GetTrackFromPoint(reaper.JS_Window_ClientToScreen(trackview, 0, 0))
        while (track and reaper.ValidatePtr2(0, track, "MediaTrack*")) do
            t = t or reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")
            trackY = reaper.GetMediaTrackInfo_Value(track, "I_TCPY")
            for e = 0, reaper.CountTrackEnvelopes(track)-1 do
                local env = reaper.GetTrackEnvelope(track, e)
                local envTop = trackY + reaper.GetEnvelopeInfo_Value(env, "I_TCPY")
                local envHeight = reaper.GetEnvelopeInfo_Value(env, "I_TCPH")
                local envBottom = envTop + envHeight
                distance = ((envTop <= mouseOrigY and mouseOrigY < envBottom) and 0)
                            or ((mouseOrigY < envTop) and (envTop-mouseOrigY)) 
                            or (mouseOrigY-envBottom)
                if distance > prevDistance then
                    goto goneThroughTrackEnvelopes
                else
                    prevEnv = env
                    prevTrack = track
                    prevDistance = distance
                end
            end
            t = t + 1
            track = reaper.GetTrack(0, t)
        end
        ::goneThroughTrackEnvelopes::
        if prevDistance < 50 then
            activeEnv = prevEnv
            activeTrack = prevTrack
            gotEnvelope = true
        end
    end
    
    if not gotEnvelope then
        reaper.MB("No automation lane found near to mouse position."
                  .."\n\nTo edit an unselected take envelope, the mouse cursor must be positioned inside the target envelope lane when the script starts."
                  .."\n\nTo edit an unselected track envelope, the mouse cursor can either be inside or slighty outside the target lane. "
                  .."If outside, it will ensure that the ramp starts at the minimum or maximum."
                  .."\n\nThe selected envelope takes precedence (whether take or track): If the mouse starting position is close to the selected envelope, "
                  .."the selected envelope will be edited, even if the starting position was inside another lane."
                  , "ERROR", 0) 
        return false
    end
        --[==[
        local prevX, prevY = nil, nil
        
        -- If mouse is slightly outside envelope lane, wait for mouse to enter
        do ::tryFindEnv:: 
        
            activeEnv, gotEnvelope = nil, false
            
            -- TERMINATE script if moves out of track area
            local newX, newY = reaper.GetMousePosition()
            local newClientX, newClientY = reaper.JS_Window_ScreenToClient(trackview, newX, newY)
            if newClientX < 0 or newClientX >= winRectWidth or newClientY < 0 or newClientY >= winRectHeight then
                return false
            end
            
            activeTrack = reaper.GetTrackFromPoint(newX, newY) -- This function also return isEnvelope, but doesn't work for take envelopes
            if activeTrack and reaper.ValidatePtr2(0, activeTrack, "MediaTrack*") then

                trackY = reaper.GetMediaTrackInfo_Value(activeTrack, "I_TCPY")
                
                
                -- No take envs found, so try track envs
                if not activeEnv then
                    for e = 0, reaper.CountTrackEnvelopes(activeTrack)-1 do
                        local env = reaper.GetTrackEnvelope(activeTrack, e)
                        local envTop = trackY + reaper.GetEnvelopeInfo_Value(env, "I_TCPY")
                        local envHeight = reaper.GetEnvelopeInfo_Value(env, "I_TCPH")
                        local envBottom = envTop + envHeight
                        if envTop <= newClientY and newClientY < envBottom then 
                            gotEnvelope = true 
                            activeEnv = env
                            break
                        end
                    end
                end
            end
                
            if not (activeEnv and gotEnvelope) then 
            --[[ If no env yet, try again
                if not DEFER_GetInputs() then 
                    return false 
                else]]if newX ~= prevX or newY ~= prevY then
                    prevX, prevY = newX, newY
                    reaper.TrackCtl_SetToolTip("Move mouse into envelope lane", newX+10, newY+(macOS and -10 or 10), true) 
                end
                goto tryFindEnv 
            end
        end
]==]
        --[[
        ]]
  
    
    --reaper.TrackCtl_SetToolTip("", 0, 0, true)
    
    -- To get the env under mouse, entire lane height was used.  To get value at mouse position, only "used" height must be used
    trackY = reaper.GetMediaTrackInfo_Value(activeTrack, "I_TCPY")
    local envTopPixel    = trackY + reaper.GetEnvelopeInfo_Value(activeEnv, "I_TCPY_USED")
    local envHeight      = reaper.GetEnvelopeInfo_Value(activeEnv, "I_TCPH_USED")
    local envBottomPixel = envTopPixel + envHeight - 1
    
    local tAI, activeAI, offset = {}, -1, 0
    if activeTake then
        activeItem = reaper.GetMediaItemTake_Item(activeTake)
        local itemStart = reaper.GetMediaItemInfo_Value(activeItem, "D_POSITION")
        local itemEnd = itemStart + reaper.GetMediaItemInfo_Value(activeItem, "D_LENGTH")
        tAI[-1] = { startTime = itemStart, endTime = itemEnd }
        offset = itemStart -- Take envelopes use time positions relative to item start
    else
        tAI[-1] = { startTime = 0, endTime = math.huge }
        offset = 0
        for ai = 0, reaper.CountAutomationItems(activeEnv)-1 do
            local startTime = reaper.GetSetAutomationItemInfo(activeEnv, ai, "D_POSITION", -1, false)
            local endTime   = startTime + reaper.GetSetAutomationItemInfo(activeEnv, ai, "D_LENGTH", -1, false)
            tAI[ai] = { startTime = startTime, endTime = endTime }
            if startTime <= mouseOrigTimePos and mouseOrigTimePos < endTime then activeAI = ai end
        end
        if activeAI ~= -1 then
            for ai = 0, #tAI do
                if ai ~= activeAI and tAI[ai].endTime > tAI[activeAI].startTime and tAI[ai].startTime < tAI[activeAI].endTime then
                    reaper.MB("This script is not yet compatible with overlapping Automation Items.", "ERROR", 0)
                    return false
                end
            end
        end
    end
    
    local BR_Env = reaper.BR_EnvAlloc(activeEnv, false)
    if not BR_Env then reaper.MB("Failed running the SWS function BR_EnvAlloc.", "ERROR", 0) return false end
    local _, _, _, _, _, defaultShape, minValue, maxValue, _, _, _, automationItemsOptions = reaper.BR_EnvGetProperties(BR_Env)
    reaper.BR_EnvFree(BR_Env, false)
    mode = reaper.GetEnvelopeScalingMode(activeEnv)
    minValue, maxValue = reaper.ScaleFromEnvelopeMode(mode, minValue), reaper.ScaleToEnvelopeMode(mode, maxValue)

    if not activeTake and activeAI == -1 and ( (automationItemsOptions and automationItemsOptions ~= -1 and automationItemsOptions&4 == 4)
                                                or reaper.GetToggleCommandState(42213) == 1)
                                         then return false end -- Underlying track env is bypassed
  
    return gotEnvelope, activeEnv, activeAI, activeTake, activeTrack, tAI[activeAI].startTime, tAI[activeAI].endTime, offset, minValue, maxValue, envTopPixel, envBottomPixel, defaultShape
end                    


--######################
------------------------
function ParseEnvelope()

    tDel = {}
    --[[
    local pAlpha = reaper.GetEnvelopePointByTimeEx(activeEnv, activeAI, arrStartTime-envOffset) or -1
    local pOmega = reaper.GetEnvelopePointByTimeEx(activeEnv, activeAI, arrEndTime-envOffset) or -1
    for p = pAlpha, pOmega+1 do
        local pointOK, time, value, shape, tension, selected = reaper.GetEnvelopePointEx(activeEnv, activeAI, p)
        if pointOK then 
            tDel[#tDel+1] = { p = p, time = time+envOffset, value = value, shape = shape, tension = tension, selected = selected }
            --if time <= mouseOrigTime then chaseLeft = value end
            --if not chaseRight and time >= mouseOrigTime then chaseRight = value end
        end
    end]]
    leftChasedValue, rightChasedValue = nil, nil
    local L, M, R = arrStartTime, mouseOrigTimePos, arrEndTime
    for p = 0, reaper.CountEnvelopePointsEx(activeEnv, activeAI)-1 do
        local pointOK, time, value, shape, tension, selected = reaper.GetEnvelopePointEx(activeEnv, activeAI, p)
        local realTime = envOffset + time / playrate
        if pointOK then
            if realTime < M then
                leftChasedValue = value
            elseif not rightChasedValue then
                rightChasedValue = value
            end
            if L <= realTime and realTime <= R then
                tDel[#tDel+1] = { p = p, time = realTime, value = value, shape = shape, tension = tension, selected = selected }
            end
            --if time <= mouseOrigTime then chaseLeft = value end
            --if not chaseRight and time >= mouseOrigTime then chaseRight = value end
        end
    end
    if chasingInterpolatesEnvelope then
        local chaseOK, chasedValue = reaper.Envelope_Evaluate(activeEnv, playrate*(mouseOrigTimePos-envOffset), 41800, 0)
        leftChasedValue = chasedValue
        rightChasedValue = chasedValue
    end
end


--##########################################################################
----------------------------------------------------------------------------
-- Parse MIDI string and chase starting values.
function ParseMIDIString()

    --[[
    To avoid weird-looking backward envelope segments, CCs must be uploaded in correct order 
        (at least, in each channel separately).

    * The MIDI string of the line of CCs (in the active channel) must therefore be inserted after the last CC preceding the line.
    * All overlapping CCs must be deleted in real-time
    
    These CCs that 1) may either need to be deleted in real-time, or 2) after which the line must be inserted, will be separated into separate entries in tMIDI.
    
    They include all CCs in the active channel that are *onscreen*, as well as the closest offscreen preceding CC.
    ]]
    -- Since the entire MIDI string must in any case be parsed here, in order to 
    --    deselect, lastChasedValue and nextChasedValue will also be calculated.
    -- If mustChase == false, they will eventually be replaced by mouseOrigCCValue.
    
    -- By default (if not mustChase, or if no pre-existing CCs are found),
    --    use mouse starting values.    
    -- 14-bit CC must determine both MSB and LSB.  If no LSB is found, simply use 0 as default.
     leftChasedEvent, rightChasedEvent, leftChasedLSB, rightChasedLSB = nil, nil, nil, nil
    
    -- The script will speed up execution by not inserting each event individually into tEvents as they are parsed.
    --    Instead, only changed (i.e. deselected) events will be re-packed and inserted individually, while unchanged events
    --    will be inserted as bulk blocks of unchanged sub-strings.
    local runningPPQPos = 0 -- The MIDI string only provides the relative offsets of each event, so the actual PPQ positions must be calculated by iterating through all events and adding their offsets
    local prevPos, nextPos, savePos = 1, 1, 1 -- savePos is starting position of block of unchanged MIDI.
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
            
        mustDo = nil  
        -- For backward chase, CC must be *before* snappedOrigPPQPos
        -- For forward chase, CC can be after *or at* snappedOrigPPQPos
        runningPPQPos = runningPPQPos + offset
        if msg:len() >= 2 then
            local msg1 = msg:byte(1)
            local msg2 = msg:byte(2)
            if laneIsCC7BIT then 
                if msg1>>4 == 11 and msg2 == mouseOrigCCLane then 
                    if flags&1 == 1 then mustDo = "deselect" end
                    if msg1&0x0F == activeChannel then
                        if runningPPQPos < snappedOrigPPQPos then 
                            leftChasedEvent = {val = msg:byte(3), ticks = runningPPQPos, flags = flags}
                        elseif not rightChasedEvent then 
                            rightChasedEvent = {val = msg:byte(3), ticks = runningPPQPos}
                        end
                        if runningPPQPos < ME_LeftmostTick then mustDo = "1" -- The CCs in tDel are not only stored there since they may be deleted, but also since the line's MIDI string needs to be inserted directly the closest preceding CC in the active channel.
                        elseif runningPPQPos <= ME_RightmostTick then mustDo = ">1" 
                        end
                    end
                end
            elseif laneIsPITCH then 
                if msg1>>4 == 14 then 
                    if flags&1 == 1 then mustDo = "deselect" end
                    if msg1&0x0F == activeChannel then
                        if runningPPQPos < snappedOrigPPQPos then 
                            leftChasedEvent = {val = (((msg:byte(3))<<7) | msg2), ticks = runningPPQPos, flags = flags}
                        elseif not rightChasedEvent then 
                            rightChasedEvent = {val = (((msg:byte(3))<<7) | msg2), ticks = runningPPQPos}
                        end
                        if runningPPQPos < ME_LeftmostTick then mustDo = "1"
                        elseif runningPPQPos <= ME_RightmostTick then mustDo = ">1" 
                        end
                    end
                end
            elseif laneIsCC14BIT then -- Should the script ignore LSB?
                if msg1>>4 == 11 then
                    if msg2 == mouseOrigCCLane-256 then 
                        if flags&1 == 1 then mustDo = "deselect" end
                        if msg1&0x0F == activeChannel then
                            if runningPPQPos < snappedOrigPPQPos then 
                                leftChasedEvent = {val = msg:byte(3), ticks = runningPPQPos, flags = flags}
                            elseif not rightChasedEvent then 
                                rightChasedEvent = {val = msg:byte(3), ticks = runningPPQPos}
                            end
                            if runningPPQPos < ME_LeftmostTick then mustDo = "1"
                            elseif runningPPQPos <= ME_RightmostTick then mustDo = ">1" 
                            end
                        end
                    elseif msg2 == mouseOrigCCLane-224 then 
                        if flags&1 == 1 then mustDo = "deselect" end
                        if msg1&0x0F == activeChannel then
                            if runningPPQPos < snappedOrigPPQPos then 
                                leftChasedLSB = msg:byte(3)
                            elseif not nextChasedLSB then 
                                rightChasedLSB = msg:byte(3)
                            end
                            if runningPPQPos < ME_LeftmostTick then mustDo = "1"
                            elseif runningPPQPos <= ME_RightmostTick then mustDo = ">1" 
                            end
                        end
                    end
                end
            elseif laneIsCHANPRESS then 
                if msg1>>4 == 13 then 
                    if flags&1 == 1 then mustDo = "deselect" end
                    if msg1&0x0F == activeChannel then
                        if runningPPQPos < snappedOrigPPQPos then 
                            leftChasedEvent = {val = msg2, ticks = runningPPQPos, flags = flags}
                        elseif not rightChasedEvent then 
                            rightChasedEvent = {val = msg2, ticks = runningPPQPos}
                        end
                        if runningPPQPos < ME_LeftmostTick then mustDo = "1"
                        elseif runningPPQPos <= ME_RightmostTick then mustDo = ">1" 
                        end
                    end
                end
            end
        end -- if msg:len() >= 2
        
        if mustDo then
            -- Offset won't change when deleted, so store with preceding stuff
            t = t + 1
            tEvents[t] = MIDIString:sub(savePos, prevPos+3)
            -- Assemble event string
            local ev = s_pack("Bs4", flags&0xFE, msg)
            -- Check if event has meta info
            if mustDo ~= "deselect" then
                if MIDIString:sub(nextPos, nextPos+10):match("^\0\0\0\0.....\255\15") then
                    _, flags, msg, nextPos = s_unpack("i4Bs4", MIDIString, nextPos)
                    ev = ev .. "\0\0\0\0" .. s_pack("Bs4", flags, msg)
                end
                tDel[(mustDo == "1") and 1 or (#tDel+1)] = {ticks = runningPPQPos, stringPos = prevPos+4, stringEnd = nextPos-1, event = ev, deleted = false }
            end
            t = t + 1
            tEvents[t] = ev
            savePos = nextPos
        end 
        
    end -- while nextPos <= MIDILen    
   
    MIDIStringDeselected = table.concat(tEvents) .. MIDIString:sub(savePos, nil)
    
    -- Get chased values
    if laneIsCC14BIT then
        if leftChasedEvent then leftChasedEvent.val = ((leftChasedEvent.val)<<7) | (leftChasedLSB or 0) end
        if rightChasedEvent then rightChasedEvent.val = ((rightChasedEvent.val)<<7) | (rightChasedLSB or 0) end
    end
    if chasingInterpolatesEnvelope then
        local chasedValue
        if not leftChasedEvent and not rightChasedEvent then 
            chasedValue = mouseOrigCCValue 
        elseif not leftChasedEvent then
            chasedValue = rightChasedEvent.val
        elseif not rightChasedEvent then
            chasedValue = leftChasedEvent.val
        else
            local tickRange  = rightChasedEvent.ticks - leftChasedEvent.ticks
            local valueRange = rightChasedEvent.val - leftChasedEvent.val
            -- flag high 4 bits for CC shape: &16=linear, &32=slow start/end, &16|32=fast start, &64=fast end, &64|16=bezier
            if leftChasedEvent.flags&0xF0 == 0 then
                chasedValue = leftChasedEvent.val
            -- I don't know what formula REAPER uses for Bézier curves, so apprimate with linear
            elseif leftChasedEvent.flags&0xF0 == 64 then -- &64=fast end
                chasedValue = leftChasedEvent.val + valueRange*((snappedOrigPPQPos - leftChasedEvent.ticks)/tickRange)^3
            elseif leftChasedEvent.flags&0xF0 == 48 then -- &16|32=fast start
                chasedValue = rightChasedEvent.val - valueRange*((rightChasedEvent.ticks - snappedOrigPPQPos)/tickRange)^3  
            else --if leftChasedEvent.flags&0xF0 == 16 or leftChasedEvent.flags&0xF0 == 80 then -- &16=linear, &64|16=bezier
                chasedValue = leftChasedEvent.val + valueRange*(snappedOrigPPQPos - leftChasedEvent.ticks)/tickRange
            end
        end 
        leftChasedValue = chasedValue
        rightChasedValue = chasedValue
    else
        leftChasedValue = leftChasedEvent and leftChasedEvent.val or mouseOrigCCValue
        rightChasedValue = rightChasedEvent and rightChasedEvent.val or mouseOrigCCValue
    end
    
    -- Use stored tDel info to separate MIDIString into table with events that may need to be deleted as separate entries
    tMIDI = {}
    nextPos = 1
    for _, tD in ipairs(tDel) do
        tMIDI[#tMIDI+1] = MIDIStringDeselected:sub(nextPos, tD.stringPos-1)
        tMIDI[#tMIDI+1] = MIDIStringDeselected:sub(tD.stringPos, tD.stringEnd)
        tD.index = #tMIDI
        nextPos = tD.stringEnd + 1
    end
    tMIDI[#tMIDI+1] = MIDIStringDeselected:sub(nextPos, nil)
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
        Tooltip("Armed: Draw ramp")
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
    mouseOrigScreenX, mouseOrigScreenY = reaper.GetMousePosition()
    
    
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
    if defaultShape and not (defaultShape == "sine" or defaultShape == "fast start" or defaultShape == "fast end") then
        reaper.MB('The parameter "defaultShape" can either be commented out, or may take the values "sine", "fast start" or "fast end".', "ERROR", 0)
        return false 
    elseif not (type(chasingInterpolatesEnvelope) == "boolean") then 
        reaper.MB('The parameter "chasingInterpolatesEnvelope" may only take on the boolean values "true" or "false".', "ERROR", 0)
        return false
    elseif not (type(neverSnapToGrid) == "boolean") then 
        reaper.MB('The parameter "neverSnapToGrid" may only take on the boolean values "true" or "false".', "ERROR", 0)
        return false      
    end                    
    
    
    -- GET MIDI EDITOR UNDER MOUSE:
    -- Unfortunately, REAPER's windows don't have the same titles or classes on all three platforms, so must use roundabout way
    -- If platform is Windows, the piano roll area is title "midiview", but not in Linux, and I'm not sure about MacOS.
    -- SWS uses Z order to find the midiview. In ReaScriptAPI, the equivalent would be JS_Window_GetRelated(parent, "CHILD"), "NEXT").
    -- But this is also not always reliable!  
    -- It seems to me that Window ID seems to me more cross-platform reliable than title or Z order.
    windowUnderMouse = reaper.JS_Window_FromPoint(mouseOrigScreenX, mouseOrigScreenY)
    if windowUnderMouse then
            
        winRectOK, winRectWidth, winRectHeight = reaper.JS_Window_GetClientSize(windowUnderMouse)
        if winRectOK then
        
            parentWindow = reaper.JS_Window_GetParent(windowUnderMouse)
            if parentWindow then
    
                -- Is the mouse over the piano roll of a MIDI editor?
                
                -- MIDI EDITOR:
                if reaper.MIDIEditor_GetMode(parentWindow) == 0 then -- got a window in a MIDI editor
                    isInline = false
                    isMIDI = true
                    editor = parentWindow
                    if windowUnderMouse == reaper.JS_Window_FindChildByID(parentWindow, 1001) then -- The piano roll child window, titled "midiview" in Windows.
                        midiview = windowUnderMouse
                        mouseOrigX, mouseOrigY = reaper.JS_Window_ScreenToClient(midiview, mouseOrigScreenX, mouseOrigScreenY) -- Always use client coordinates in MIDI editor                                    
                        
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
                                                mouseOrigPitch = ME_TopPitch - math.ceil((mouseOrigY - tME_Lanes[-1].topPixel) / ME_PixelsPerPitch)
                                                mouseOrigCCValue = -1
                                            elseif (mouseOrigCCLaneID%1 == 0) and laneMinValue and laneMaxValue then
                                                mouseOrigPitch = -1                                        
                                                mouseOrigCCValue = laneMinValue + (laneMaxValue-laneMinValue) * (mouseOrigY - tME_Lanes[mouseOrigCCLaneID].bottomPixel) / (tME_Lanes[mouseOrigCCLaneID].topPixel - tME_Lanes[mouseOrigCCLaneID].bottomPixel)  
                                            end
                                            
                                            gotEverythingOK  = true
                    end end end end end end
    
                -- ARRANGE WINDOW
                -- Is the mouse over the arrange view?  Envelope or inline editor?
                elseif windowUnderMouse == reaper.JS_Window_FindChildByID(reaper.GetMainHwnd(), 1000) then
                    
                    trackview = windowUnderMouse
                    ruler     = reaper.JS_Window_FindChildByID(reaper.GetMainHwnd(), 1005)
                    activeItem, activeTake  = reaper.GetItemFromPoint(mouseOrigScreenX, mouseOrigScreenY, true)
                    
                    mouseOrigX, mouseOrigY = reaper.JS_Window_ScreenToClient(trackview, mouseOrigScreenX, mouseOrigScreenY)
                    arrStartTime, arrEndTime = reaper.GetSet_ArrangeView2(0, false, 0, 0)
                    pixelsPerSec = reaper.GetHZoomLevel()
                    mouseOrigTimePos = arrStartTime + mouseOrigX/pixelsPerSec
                    
                    
                    
                    
                    -- INLINE MIDI EDITOR
                    -- The inline editor is much faster than the main MIDI editor, so can use the relatively SWS functions in each cycle, without causing noticable delay.
                    --    (Also, it is much more complicated to calculate mouse context for the arrange view and inline editor, so I don't want to do it in this script.)
                    if activeTake and reaper.BR_IsMidiOpenInInlineEditor(activeTake) then
                    
                        ::loopUntilMouseEntersCCLane::
                        window, segment, details = reaper.BR_GetMouseCursorContext()    
                        editor, isInline, mouseOrigPitch, mouseOrigCCLane, mouseOrigCCValue, mouseOrigCCLaneID = reaper.BR_GetMouseCursorContext_MIDI() 
                        if details == "cc_lane" and mouseOrigCCValue == -1 then mouseStartedOnLaneDivider = true; goto loopUntilMouseEntersCCLane end
                        
                        if isInline then
                            
                            editor = nil
                            isMIDI = true
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
                        end end end end end
                      
                    -- ENVELOPE
                    else
                        isEnvelope, activeEnv, activeAI, activeTake, activeTrack, envStartTime, envEndTime, envOffset, envMinValue, envMaxValue, envTopPixel, envBottomPixel, envDefaultShape = SetupEnvelopeContext()
                        
                        if isEnvelope then
                            gotEverythingOK = true
    end end end end end end
   
   
    -- To keep things neater, all these error messages are here together
    if not gotEverythingOK then
        if not windowUnderMouse then
            reaper.MB("Could not determine the window under the mouse.", "ERROR", 0)
        elseif not winRectOK then
            reaper.MB("Could not determine the onscreen coordinate RECT of the window under the mouse.", "ERROR", 0)
        elseif not parentWindow then
            reaper.MB("Could not determine the parent window of the window under the mouse.", "ERROR", 0)
        elseif not (midiview or trackview) then
            ArmToolbarButton()
        elseif isMIDI then 
            if not activeTakeOK then
                reaper.MB("Could not determine a valid MIDI take in the editor under the mouse.", "ERROR", 0)
            elseif not activeItemOK then
                reaper.MB("Could not determine the media item to which the MIDI editor's active take belong.", "ERROR", 0)
            elseif not chunkStuffOK then
                -- The chuck functions give their own detailed error messages if something goes awry.
            elseif not mouseOrigCCLane then
                 reaper.MB("One or more of the CC lanes are of unknown type, and could not be parsed by this script.", "ERROR", 0)
            end
        end 
        return false
    end 
    if isMIDI and not (laneIsCC7BIT or laneIsCC14BIT or laneIsCHANPRESS or laneIsPITCH) then
        reaper.MB("This script will only work in the following MIDI lanes: \n * 7-bit CC, \n * 14-bit CC, \n * Pitch, or\n * Channel Pressure."
                .. "\n\nTo inform the script which lane must be edited, the mouse must be positioned inside that lane when the script starts."
                .. "\n\nTo ensure that the ramp starts at the minimum or maximum value, position the mouse over a lane divider and then move the mouse into the target lane."
                , "ERROR", 0)  
        return false 
    end
    
    -- MIDI and Envelopes use the same CC density setting
    -- Since user may have lowered CC density now that we have CC envelopes, apply a minimum of 16
    CCDensity = (math.max(16, math.min(512, math.abs(reaper.SNM_GetIntConfigVar("midiCCdensity", 32)))))//1 -- If user selected "Zoom dependent", density<0
    
    -- Now that we know whether we are dealing with env, inline or editor, get the rest of the necessary variables
    -- ENVELOPE
    if isEnvelope then 
        DEFER_DrawFunction = DEFER_DrawEnvelope
        
        if reaper.GetToggleCommandStateEx(0, 1157) == 1 and not neverSnapToGrid then
            isSnapEnabled = true
            mouseOrigTimePos = reaper.SnapToGrid(0, mouseOrigTimePos)
        end
        envHeight = envBottomPixel - envTopPixel + 1
        mouseOrigValue = math.min(envMaxValue, math.max(envMinValue, envMinValue + (envMaxValue-envMinValue)*(envBottomPixel-mouseOrigY)/envHeight))

        prevRampLeftTimePos, prevRampRightTimePos = mouseOrigTimePos, mouseOrigTimePos
        prevMouseTimePos, prevMouseValue = nil, nil
        -- Don't try to edit Master track tempo env
        
        
        --[[if activeEnv == tempoEnv then
            local _, gridDividedByFour = reaper.GetSetProjectGrid(0, false) -- Arrange grid and MIDI grid are returned in different units
            CCDensity = 0.25 / gridDividedByFour
        else
            CCDensity = m_floor(math.max(16, math.min(512, math.abs(reaper.SNM_GetIntConfigVar("midiCCdensity", 32))))) -- If user selected "Zoom dependent", density<0
        end]]
        
        -- Get timebase, starting from item -> track -> project
        if activeTake then 
            activeItem = reaper.GetMediaItemTake_Item(activeTake)
            timebase = reaper.GetMediaItemInfo_Value(activeItem, "C_BEATATTACHMODE") -- Item timebase
        end
        if not activeTake or timebase == -1 then timebase = reaper.GetMediaTrackInfo_Value(activeTrack, "C_BEATATTACHMODE") end -- Track timebase
        if timebase == -1 then timebase = 1 - reaper.GetToggleCommandState(reaper.NamedCommandLookup("_SWS_AWTBASETIME")) end -- Project timebase
        
        -- Automation Items also have playrates, but these don't seem to affect the time positions of env points when reading or writing
        playrate = activeTake and reaper.GetMediaItemTakeInfo_Value(activeTake, "D_PLAYRATE") or 1
        
        ParseEnvelope()
        
    -- MIDI
    else
        DEFER_DrawFunction = DEFER_DrawMIDI
        
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
        else mouseOrigCCValue = (mouseOrigCCValue+0.5)//1
        end
    
    
        -- MOUSE STARTING PPQ POSITION:
        -- Get mouse starting PPQ position -- AND ADJUST FOR LOOPING AND SNAP-TO-GRID
        --[[if isInline then
            mouseOrigPPQPos = reaper.MIDI_GetPPQPosFromProjTime(activeTake, reaper.BR_GetMouseCursorContext_Position())
        elseif ME_TimeBase == "beats" then
            mouseOrigPPQPos = ME_LeftmostTick + mouseOrigX/ME_PixelsPerTick
        else -- ME_TimeBase == "time"
            mouseOrigPPQPos  = reaper.MIDI_GetPPQPosFromProjTime(activeTake, ME_LeftmostTime + mouseOrigX/ME_PixelsPerSecond )
        end
        ]]
        loopStartTick, minimumTick, maximumTick = 0, -math.huge, math.huge
        mouseOrigPPQPos = GetMouseTick(false)
        
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
        loopStartTick = (mouseOrigPPQPos // sourceLengthTicks) * sourceLengthTicks
        mouseOrigPPQPos = mouseOrigPPQPos - loopStartTick 
    
        minimumTick = math.max(0, itemFirstVisibleTick)
        maximumTick = (math.min(itemLastVisibleTick, sourceLengthTicks-1))//1 -- I prefer not to draw any event on the same PPQ position as the All-Notes-Off
        
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
            snappedOrigPPQPos = (mouseOrigPPQPos+0.5)//1
        elseif isInline then
            local timePos = reaper.MIDI_GetProjTimeFromPPQPos(activeTake, mouseOrigPPQPos)
            local snappedTimePos = reaper.SnapToGrid(0, timePos) -- If snap-to-grid is not enabled, will return timePos unchanged
            snappedOrigPPQPos = (reaper.MIDI_GetPPQPosFromProjTime(activeTake, snappedTimePos) + 0.5)//1
        else
            local mouseQNpos = reaper.MIDI_GetProjQNFromPPQPos(activeTake, mouseOrigPPQPos) -- Mouse position in quarter notes
            local roundedGridQN = math.floor((mouseQNpos/QNperGrid)+0.5)*QNperGrid -- Grid nearest to mouse position
            snappedOrigPPQPos = (reaper.MIDI_GetPPQPosFromProjQN(activeTake, roundedGridQN) + 0.5)//1
        end 
        snappedOrigPPQPos = math.max(minimumTick, math.min(maximumTick, snappedOrigPPQPos)) 
        
      
        -- CC DRAWING DENSITY:
        -- If the CCs are being drawn in the "Tempo" track, CCs will be inserted at the MIDI editor's grid spacing.
        -- In all other cases, CCs density will follow the setting in Preferences -> MIDI editor -> "Events per quarter note when drawing in CC lanes".
        local track = reaper.GetMediaItemTake_Track(activeTake)
        local trackNameOK, trackName = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)
        
        --[[if trackName == "Tempo" then
            local QNperCC = reaper.MIDI_GetGrid(activeTake)
            CCDensity = math.floor((1/QNperCC) + 0.5)
        else
            CCDensity = reaper.SNM_GetIntConfigVar("midiCCdensity", 32)
            CCDensity = m_floor(math.max(4, math.min(512, math.abs(CCDensity)))) -- If user selected "Zoom dependent", density<0
        end]]
        local startQN = reaper.MIDI_GetProjQNFromPPQPos(activeTake, 0)
        PPQ = reaper.MIDI_GetPPQPosFromProjQN(activeTake, startQN+1)
        PPerCC = PPQ/CCDensity -- Not necessarily an integer! 
        firstCCinTakePPQPos = reaper.MIDI_GetPPQPosFromProjQN(activeTake, math.ceil(startQN*CCDensity)/CCDensity)    
    
    
        -- DEFAULT CC SHAPE:
        local tShapeActions = {[42086] = 16, [42087] = 0, [42088] = 32, [42089] = 16|32, [42090] = 64, [42091] = 64|16}
        for shapeActionID, shapeFlag in pairs(tShapeActions) do
            if reaper.GetToggleCommandStateEx(sectionID, shapeActionID) == 1 then defaultFlagChar = string.char(shapeFlag|1) break end -- 1 for selected
        end 
        
        
        -- GET AND PARSE MIDI:
        -- Time to process the MIDI of the take!
        -- As mentioned in the header, this script does not use the old-fashioned MIDI API functions such as 
        --    MIDI_InsertCC, since these functions are far too slow when dealing with thousands of events.
        getAllOK, MIDIString = reaper.MIDI_GetAllEvts(activeTake, "")
            if not getAllOK then reaper.MB("MIDI_GetAllEvts could not load the raw MIDI data.", "ERROR", 0) return false end
        -- Deselect existing CCs in lane, and find chased values
        ParseMIDIString()
    
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
    
    
    -- KEYBOARD STATE:
    -- DO NOT get keystate immediately.  If startTime = actual start time of script, and if mouse starts outside lane, 
    --    may take more than dragtime to move into lane, so the script can only check whether key has quickly been released 
    --    *after* dragtime has already passed.
    startTime = reaper.time_precise()
    prevMouseTime = startTime + 0.5 -- In case mousewheel sends multiple messages, don't react to messages sent too closely spaced, so wait till little beyond startTime.
    keyState = reaper.JS_VKeys_GetState(-2):sub(VKLow, VKHi)
    keyState = keyState:sub(1,VKShift-VKLow)..keyState:sub(VKShift-VKLow+2,nil)
    
    
    ------------------------------------------------------------
    -- Finally, startup completed OK, so can continue with loop!
    return true 
    
end -- function Main()


--################################################
--------------------------------------------------
mainOK, mainRetval = pcall(MAIN)
if mainOK and mainRetval then DEFER_pcall() end -- START LOOPING!


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
