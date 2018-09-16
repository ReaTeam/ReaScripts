--[[
ReaScript name: js_LFO Tool (MIDI editor version, insert CCs under selected notes in last clicked lane).lua
Version: 2.60
Author: juliansader
Website: http://forum.cockos.com/showthread.php?t=177437
Screenshot: http://stash.reaper.fm/29477/LFO%20Tool%20%28MIDI%20editor%20version%2C%20apply%20to%20existing%20CCs%20or%20velocities%29.gif
Donation: https://www.paypal.me/juliansader
About:
  # DESCRIPTION
  
  LFO generator and shaper - MIDI editor version
  
  Draw fancy LFO curves in REAPER's piano roll.
  
  This version of the script inserts new CCs under selected notes in the last clicked lane, 
  using the same channels as the notes above (after removing any pre-existing CCs in the same time range and channels).
 
 
  # INSTRUCTIONS
  
  DRAWING ENVELOPES
  
  Leftclick in open space in the envelope drawing area to add an envelope node.
  
  Shift + Leftdrag to add multiple envelope nodes.
  
  Alt + Leftclick (or -drag) to delete nodes.
  
  Rightclick on an envelope node to open a dialog box in which a precise custom value can be entered.
  
  Move mousewheel while mouse hovers above node for fine adjustment.
  
  
  Use a Ctrl modifier to edit all nodes simultaneously:
  
  Ctrl + Leftclick (or -drag) to set all nodes to the mouse Y position.
  
  Ctrl + Rightclick to enter a precise custom value for all nodes.
  
  Ctrl + Mousewheel for fine adjustment of all nodes simultaneously.
  
  
  The keyboard shortcuts "a", "c" and "r" can be used to switch the envelope view between Amplitude, Center and Rate.
  

  VALUE AND TIME DISPLAY
  
  The precise Rate, Amplitude or Center of the hot node, as well as the precise time position, can be displayed above the node.
  
  Rightclick in open space in the envelope area to open a menu in which the Rate and time display formats can be selected.
  

  LOADING AND SAVING CURVES
  
  Click on the menu button at bottom left (or right-click anywhere outside envelope area) to open the Save/Load/Delete curve menu.
  
  One of the saved curves can be loaded automatically at startup. By default, this curve must be named "default".
  
                    
  FURTHER CUSTOMIZATION
  
  The menu also includes an option to skip redundant CCs while drawing the LFO.
  
  Further customization is possible - see the instructions in the script's USER AREA.
  
  This include:
  - Easily adding custom LFO shapes.
  - Specifying the resolution of LFO shapes' phase steps.
  - Specifying the resolution of the mousewheel fine adjustment.
  - Changing interface colors.
  - Changing the default curve name.
  - etc...      
]]

--[[
  Changelog:
  v2.00 (2017-01-15)
    + Much faster execution in large takes with hundreds of thousands of events.
    + Keyboard shortcuts "a", "c" and "r" to switch GUI views.
    + LFO can be applied to existing events - including velocities - instead of inserting new CCs.
    + Requires REAPER v5.32 or later.  
  v2.02 (2017-02-28)
    + First CC will be inserted at first tick within time selection, even if it does not fall on a beat, to ensure that the new LFO value is applied before any note is played.
  v2.11 (2017-06-04)
    + New Smoothing slider (replecs non-functional Bezier slider) to smoothen curves at nodes.
  v2.21 (2017-06-19)
    + Option to skip redundant CCs.
    + GUI window will open at last-used screen position.
  v2.30 (2017-10-03)
    + Keep nodes in order while moving hot node.
  v2.31 (2017-10-03)
    + Keep edge nodes in order when inserting new nodes.
  v2.32 (2017-12-13)
    + Refocus MIDI editor after closing script GUI (if SWS v2.9.5 or higher is installed).
  v2.50 (2018-09-15)
    + Fixed: Enable MIDI playback while script is running.
  v2.60 (2018-09-17)
    + "Morph" slider when applied to existing events.
]]
-- The archive of the full changelog is at the end of the script.

--  USER AREA:
    --[[ 
    Colors are defined as {red, green, blue, alpha}
    (Values are between 0 and 1)
    
    Default colors are:
    backgroundColor = {0.15, 0.15, 0.15, 1}
    foregroundColor = {0.75, 0.29, 0, 0.8}
    textColor       = {1, 1, 1, 0.7}  
    buttonColor     = {1, 0, 0, 1} 
    hotbuttonColor  = {0, 1, 0, 1}
    shadows         = true
    ]]
    backgroundColor = {0.15, 0.15, 0.15, 1}
    foregroundColor = {0.3, 0.8, 0.3, 0.7}
    textColor       = {1, 1, 1, 0.7} 
    buttonColor     = {1, 0, 1, 1} 
    hotbuttonColor  = {0, 1, 0, 1}
    shadows         = true  
    
    -- Which area should be filled with CCs?  Either "notes", "time" or "existing".
    -- "notes" to fill areas underneath selected notes, "time" for time selection,
    --    or "existing" to apply the LFO to existing selected events (which may be velocities).
    --    If "time", script can be linked to a mouse modifier such as double-click.
    -- It may suit workflow to save three versions of the script: one for each of the versions. 
    --    selection.
    selectionToUse = "notes" 
    
    -- Lane in which to insert LFO: either "under mouse" or "last clicked"
    -- "last clicked" has the advantage that the script can be run from a toolbar button, 
    --    since the mouse does not need to be positioned over a CC lane.  
    --    "under mouse" needs to be linked to a shortcut key.
    -- "last clicked" also enables automatic closing of the GUI as soon as a new lane
    --    or note is clicked.
    laneToUse = "last clicked" 
    
    -- Name of curve to load as default.
    --    By changing this name and saving as new script, different default curves can be 
    --    linked to different shortcut keys.
    defaultCurveName = "default" 
            
    -- How fine should the mousewheel adjustment be? (Between 0 and 1.)
    -- 0 would result in no fine adjustment, while 1 would result in immediate jumps to
    --    minimum or maximum values.
    fineAdjust = 0.0003
    
    -- Number of phase steps in standard LFO shapes.  (Must be a positive multiple of 4.)
    -- The higher the number, the more nearly continuous the phase steps will be.  However, it may also
    --    slow the responsiveness of the scripts down.
    phaseStepsDefault = 100
    
    --[[
    The user can easily add new shapes:
    Simply add the new items to 1) shapeMenu, 2) shapeTable, 4) the list of values
        and 3) the shape_function table, and give the new shape the next number in the 'List of shapes'.
    The functions in the table specify the shapes in terms of a sequence of node points:
        totalSteps = total number of steps in the shape
        amplitude  = Relative amplitude of point (min=-1, max=1).  "false" means that the point 
                     will be skipped (thereby expanding the shape).
        shape      = 0=Linear, 1=Square, 2=Slow start/end (aka sine), 3=Fast start, 4=Fast end (aka parabolic), 5=Bézier
        tension    = Tension of Bézier curve (only relevant if shape == 5.
        linearJump = specifies whether the shape has a discontinuous jump to the other side of the 'center'.
    ]]
                                
shapeMenu = "#Bézier (N/A)|Saw down|Saw up|Square|Triangle|Sine|Fast end triangle|Fast start triangle|MwMwMw"
shapeTable = {"Bezier (N/A)", "Saw down", "Saw up", "Square", "Triangle", "Sine", "Fast end triangle", "Fast start triangle", "MwMwMw"}
-- List of shapes:
Bezier = 1
SawDown = 2
SawUp = 3
Square = 4
Triangle = 5
Sine = 6
FastEndTri = 7
FastStartTri = 8
MwMwMw = 9

shape_function = {}

shape_function[Bezier] = function(cnt)
  -- returns totalSteps, amplitude, shape, tension, linearJump
  if cnt % phaseStepsDefault == 0 then return phaseStepsDefault, 1, 5, 1, false end
  if cnt % phaseStepsDefault == phaseStepsDefault/4 then return phaseStepsDefault, 0, 5, -1, false end
  if cnt % phaseStepsDefault == phaseStepsDefault/2 then return phaseStepsDefault, -1, 5, 1, false end
  if cnt % phaseStepsDefault == phaseStepsDefault*3/4 then return phaseStepsDefault, 0, 5, -1, false end
  return phaseStepsDefault, false, 5, -1, false
end

shape_function[SawUp] = function(cnt)
  -- returns totalSteps, amplitude, shape, tension, linearJump 
  if cnt % phaseStepsDefault == 0 then return phaseStepsDefault, 1, 0, 1, true end
  return phaseStepsDefault, false, 0, 1, false
end

shape_function[SawDown] = function(cnt)
  -- returns totalSteps, amplitude, shape, tension, linearJump
  if cnt % phaseStepsDefault == 0 then return phaseStepsDefault, -1, 0, 1, true end
  return phaseStepsDefault, false, 0, 1, false
end

shape_function[Square] = function(cnt)
  -- returns totalSteps, amplitude, shape, tension, linearJump
  if cnt % phaseStepsDefault == phaseStepsDefault/4 then return phaseStepsDefault, -1, 1, 1, false end  
  if cnt % phaseStepsDefault == phaseStepsDefault*3/4 then return phaseStepsDefault, 1, 1, 1, false end
  return phaseStepsDefault, false, 1, 1, false
end

shape_function[Triangle] = function(cnt)
  -- returns totalSteps, amplitude, shape, tension, linearJump
  if cnt % phaseStepsDefault == 0 then return phaseStepsDefault, 1, 0, 1, false end
  if cnt % phaseStepsDefault == phaseStepsDefault/2 then return phaseStepsDefault, -1, 0, 1, false end
  return phaseStepsDefault, false, 0, 1, false
end

shape_function[Sine] = function(cnt)
  -- returns totalSteps, amplitude, shape, tension, linearJump
  if cnt % phaseStepsDefault == 0 then return phaseStepsDefault, 1, 2, 1, false end
  if cnt % phaseStepsDefault == phaseStepsDefault/2 then return phaseStepsDefault, -1, 2, 1, false end
  return phaseStepsDefault, false, 2, 1, false
end

shape_function[FastEndTri] = function(cnt)
  -- returns totalSteps, amplitude, shape, tension, linearJump
  if cnt % phaseStepsDefault == 0 then return phaseStepsDefault, 1, 4, 1, false end
  if cnt % phaseStepsDefault == phaseStepsDefault/2 then return phaseStepsDefault, -1, 4, 1, false end
  return phaseStepsDefault, false, 4, 1, false
end

shape_function[FastStartTri] = function(cnt)
  -- returns totalSteps, amplitude, shape, tension, linearJump
  if cnt % phaseStepsDefault == 0 then return phaseStepsDefault, 1, 3, 1, false end
  if cnt % phaseStepsDefault == phaseStepsDefault/2 then return phaseStepsDefault, -1, 3, 1, false end
  return phaseStepsDefault, false, 3, 1, false
end

shape_function[MwMwMw] = function(cnt)
  -- returns totalSteps, amplitude, shape, tension, linearJump
  if cnt % 8 == 0 then return 8, 0.5, 0, 1, false end
  if cnt % 8 == 1 then return 8, false, 0, 1, false end
  if cnt % 8 == 2 then return 8, 1, 0, 1, true end
  if cnt % 8 == 3 then return 8, false, 0, 1, false end
  if cnt % 8 == 4 then return 8, -0.5, 0, 1, false end
  if cnt % 8 == 5 then return 8, false, 0, 1, false end
  if cnt % 8 == 6 then return 8, -1, 0, 1, true end
  if cnt % 8 == 7 then return 8, false, 0, 1, false end
end



--#######################################################################################
-----------------------------------------------------------------------------------------

--[[ General notes:

Readability of script:
Reader beware! There is lots of cruft remaining in this script since it is an unfinished 
    script that was later hacked and modded.

Speed:
REAPER's MIDI API functions such as InsertCC and SetCC are very slow if the active take contains 
    hundreds of thousands of MIDI events.  
Therefore, this script will not use these functions, and will instead directly access the item's 
    raw MIDI stream via new functions that were introduced in v5.30: GetAllEvts and SetAllEvts.
Parsing of the MIDI stream can be relatively straightforward, but to improve speed even
    further, this script will use several 'tricks', which will unfortunately also make the 
    parsing function, parseAndExtractTargetMIDI, quite complicated.
    
Sorting:
Prior to v5.32, sorting of MIDI events, either by MIDI_Sort or by other functions such as MIDI_SetNote
    (with sort=true) was endlessly buggy (http://forum.cockos.com/showthread.php?t=184459
    is one of many threads).  In particular, it often mutated overlapping notes or unsorted notes into
    infinitely extende notes.
Finally, in v5.32, these bugs were (seemingly) all fixed.  This new version of the script will therefore
    use the MIDI_Sort function (instead of calling a MIDI editor action via OnCommand to induce sorting).
]]


local shapeSelected = 6 -- Starting shape
local GUIelementHeight = 28 -- Height of the GUI elements
local borderWidth = 10
local envHeight = 190
local initXsize = 209 --300 -- Initial sizes for the GUI
local initYsize = borderWidth + GUIelementHeight*11 + envHeight + 45
local envYpos = initYsize - envHeight - 30

local hotpointRateDisplayType = "period note length" -- "frequency" or "period note length"
local hotpointTimeDisplayType = -1
local rateInterpolationType = "parabolic" -- "linear" or "parabolic"

-- By default, these curve will align if the tempo is a constant 120bpm
-- The range is between 2 whole notes and 1/32 notes, or 0.25Hz and 16Hz.
local timeBaseMax = 16 -- 16 oscillations per second
local timeBaseMin = 0.25
local beatBaseMax = 32 -- 32 divisions per whole note
local beatBaseMin = 0.5

local skipRedundantCCs = true -- This can be changed in GUI menu

-- The Clip slider and value in the original code
--     do not appear to have any effect, 
--     so the slider was replaced by the "Real-time copy to CC?" 'slider',
--     and the value was replaced by this constant
local clip = 1

helpText = "\n\nDRAWING ENVELOPES:"
         .."\n\n  * Leftclick in open space in the envelope drawing area to add an envelope node."
         .."\n\n  * Shift + Leftdrag to add multiple envelope nodes."
         .."\n\n  * Alt + Leftclick (or -drag) to delete nodes."
         .."\n\n  * Rightclick on an envelope node to open a dialog box in which a precise custom value can be entered."
         .."\n\n  * Move mousewheel while mouse hovers above node for fine adjustment."

         .."\n\nUse a Ctrl modifier to edit all nodes simultaneously:"
         .."\n\n  * Ctrl + Leftclick (or -drag) to set all nodes to the mouse Y position."
         .."\n\n  * Ctrl + Rightclick to enter a precise custom value for all nodes."
         .."\n\n  * Ctrl + Mousewheel for fine adjustment of all nodes simultaneously."
         
         .."\n\nThe keyboard shortcuts 'a', 'c' and 'r' can be used to switch the envelope view between Amplitude, Center and Rate."
         
         .."\n\nVALUE AND TIME DISPLAY:"
         .."\n\nThe precise Rate, Amplitude or Center of the hot node, as well as the precise time position, can be displayed above the node." 
         .."\n\nRightclick in open space in the envelope area to open a menu in which the Rate and time display formats can be selected."
                 
         .."\n\nLOADING AND SAVING CURVES:"
         .."\n\nClick on the menu button at bottom left (or right-click anywhere outside envelope area) to open the Save/Load/Delete curve menu."
         .."\n\nOne of the saved curves can be loaded automatically at startup. By default, this curve must be named 'default'."
                         
         .."\n\nFURTHER CUSTOMIZATION:"
         .."\n\nThe menu also includes an option to skip redundant CCs while drawing the LFO."
         .."\n\nFurther customization is possible - refer to the instructions in the script's USER AREA.\nThis includes:"
         .."\n  * Easily adding custom LFO shapes."
         .."\n  * Specifying the resolution of LFO shapes' phase steps."
         .."\n  * Specifying the resolution of the mousewheel fine adjustment."
         .."\n  * Changing interface colors."
         .."\n  * Changing the default curve name."
         .."\netc..." 
                 

-- mouse_cap values
local NOTHING = 0
local LEFTBUTTON = 1
local RIGHTBUTTON = 2
local CTRLKEY = 4
local SHIFTKEY = 8
local ALTKEY = 16
local WINKEY = 32
local MIDDLEBUTTON = 64


-- The offset of the first event will be stored separately - not in editMIDI - since this offset 
--    will need to be updated in each cycle relative to the PPQ positions of the edited events.
local origMIDI -- The original raw MIDI will be stored, in case an error is encountered and the original MIDI must be restored.
local editMIDI -- The MIDI that remained after deselcting, deleting and inserting CCs in the target lane.
local tMIDI = {} -- The MIDI string will be disassembled into tMIDI, to be re-concatenated at each cycle. 
local tSel = {} -- tSel stores the indices of selected events' entries in tMIDI, so that these can be edited in each cycle.

-- In case new CCs must be inserted and existing CCs deleted, the channels and tick ranges will be stored in this table.
local tRanges = {}

EMPTY_EVENT_MSG = string.pack("s4", "")

-- The original value and PPQ ranges of selected events in the target lane will be summarized in:
local origPPQleftmost, origPPQrightmost, origPPQrange

-- Is the editor inline?  Only applicable if laneToUse == "under mouse"
local isInline
 
-- Starting values and position of mouse 
-- targetLane: (CC0-127 = 7-bit CC, 0x100|(0-31) = 14-bit CC, 0x200 = velocity, 0x201 = pitch, 
--    0x202=program, 0x203=channel pressure, 0x204=bank/program select, 
--    0x205=text, 0x206=sysex, 0x207=off velocity)
local window, segment, details -- given by the SWS function reaper.BR_GetMouseCursorContext()
local targetLane
local laneIsCC7BIT    = false
local laneIsCC14BIT   = false
local laneIsPITCH     = false
local laneIsPROGRAM   = false
local laneIsBANKPROG  = false
local laneIsCHPRESS   = false
local laneIsVELOCITY  = false
local laneIsOFFVEL    = false
local laneIsPIANOROLL = false
local laneIsNOTES     = false -- Includes laneIsPIANOROLL, laneIsVELOCITY and laneIsOFFVEL
local laneIsSYSEX     = false
local laneIsTEXT      = false
local laneMinValue, laneMaxValue -- The minimum and maximum values in the target lane

-- Time selection into which the LFO nodes will be placed
local timeSelectStart, timeSelectEnd -- The actual project time selection
local time_start, time_end -- The start and end times of the target events (which is not the same as the time selection, unless selectionToUse = "time")

-- REAPER preferences and settings that will affect the drawing of new events in take
local defaultChannel -- In case new MIDI events will be inserted, what is the default channel?
local CCperQN -- CC density resolution as set in Preferences -> MIDI editor -> "Events per quarter note when drawing in CC lanes"

-- CCs will be inserted at the grid resolution as set in Preferences -> MIDI editor -> "Events per quarter note when drawing in CC lanes"
-- These variables will be useful to calculate each event's PPQ position.
local takeStartQN -- = reaper.MIDI_GetProjQNFromPPQPos(take, 0)
local PPperCC -- ticks per CC ** not necessarily an integer **
local PPQ -- ticks per quarter note
local QNperCC -- = 1/CCperQN

-- The source length when the script begins will be checked against the source length when the script ends,
--    to ensure that the script did not inadvertently shift the positions of non-target events.
local AllNotesOffString -- = string.pack("i4Bi4BBB", sourceLengthTicks, 0, 3, 0xB0, 0x7B, 0x00)
local sourceLengthTicks -- = reaper.BR_GetMidiSourceLenPPQ(take)
local loopStartPPQpos -- Start of loop iteration under mouse

-- Some internal stuff that will be used to set up everything
local _, item, take, editor

-- I am not sure that declaring functions local really helps to speed things up...
local s_unpack = string.unpack
local s_pack   = string.pack
local t_insert = table.insert -- myTable[i] = X is actually much faster than t_insert(myTable, X)
local m_floor  = math.floor
local m_cos    = math.cos
local m_pi     = math.pi

-- The table of GUI objects, including buttons and sliders
local tableGUIelements={}

local tableNodes = {}

local notevalues={{1,8,"32nd"},
                  {1,5,"16th quintuplet"},
                  {1,4,"16th"},
                  {1,3,"8th triplet"},
                  {1,2,"8th"},
                  {6,8,"8th dotted"},
                  {4,5,"4th quintuplet"},
                  {1,1,"4th"},
                  {6,4,"4th dotted"},
                  {4,2,"Half"},
                  {4,1,"Whole"}}
            
use_note_rates=false         
   

local GUIelement_RATE, GUIelement_AMPLITUDE, GUIelement_CENTER, GUIelement_TIMEBASE, GUIelement_SHAPE, GUIelement_PHASE
local GUIelement_RANDOMNESS, GUIelement_QUANTSTEPS, GUIelement_SMOOTH, GUIelement_FADEIN, GUIelement_FADEOUT, GUIelement_MORPH, GUIelement_ENV

---------------------------------------------------------------
-- Julian's mod: these new "make_" functions are basically just 
--    copies of the original "make_slider" function, but with
--    new "type".  Irrelevant stuff such as slider.envelope were left
--    untouched in case there is a reference to these stuff in the
--    rest of the code. 
function make_slider(x,y,w,h,val,name,valcb)
  slider={}
  slider.x=function() return x end
  slider.y=function() return y end
  -- gfx.w-60 was replaced by gfx.w-20 since the column of buttons was removed
  slider.w=function() return gfx.w-20 end
  slider.h=function() return 20 end
  slider.value=val
  slider.valcb=valcb
  slider.name=name
  slider.type="Slider"
  slider.env_enabled=false
  slider.envelope= {{ 0.0, val }, 
                    --{ 0.25, val } , -- Two of the starting nodes were
                    --{ 0.75 ,val } , --   removed to simple ramp simpler.
                    { 1.0,val }}
  slider.OnMouse=function(theslider, whichevent, x, y, extra) 
      --reaper.ShowConsoleMsg(tostring(theslider).." "..x.." "..y.."\n") 
  end
  return slider
end

function make_radiobutton(x,y,w,h,val,name,valcb)
  slider={}
  slider.x=function() return x end
  slider.y=function() return y end
  slider.w=function() return gfx.w-20 end
  slider.h=function() return 20 end
  slider.value=val
  slider.valcb=valcb
  slider.name=name
  slider.type="Button"
  slider.env_enabled=false
  slider.envelope= {{ 0.0, val },
                    --{ 0.25, val } , 
                    --{ 0.75 ,val } , 
                    { 1.0,val }}
  slider.OnMouse=function(theslider, whichevent, x, y, extra) 
      --reaper.ShowConsoleMsg(tostring(theslider).." "..x.." "..y.."\n") 
    end
  return slider
end -- function make_radiobutton

function make_menubutton(x,y,w,h,val,name,valcb)
  slider={}
  slider.x=function() return x end
  slider.y=function() return y end
  slider.w=function() return gfx.w-20 end
  slider.h=function() return 20 end
  slider.value=val
  slider.valcb=valcb
  slider.name=name
  slider.type="Menu"
  slider.env_enabled=false
  slider.envelope= {{ 0.0, val }, 
                    --{ 0.25, val } , 
                    --{ 0.75 ,val } , 
                    { 1.0,val }}
  slider.OnMouse=function(theslider, whichevent, x, y, extra) 
      --reaper.ShowConsoleMsg(tostring(theslider).." "..x.." "..y.."\n") 
    end
  return slider
end -- function make_menubutton

function make_question(x,y,w,h,val,name,valcb, trueanswer, falseanswer)
  slider={}
  slider.x=function() return x end
  slider.y=function() return y end
  slider.w=function() return gfx.w-20 end
  slider.h=function() return 20 end
  slider.value=val
  slider.valcb=valcb
  slider.name=name
  slider.enabled = false
  slider.trueanswer = trueanswer
  slider.falseanswer = falseanswer
  slider.type="Question"
  slider.env_enabled=false
  slider.envelope= {{ 0.0, val }, 
                    --{ 0.25, val } , 
                    --{ 0.75 ,val } , 
                    { 1.0,val }}
  slider.OnMouse=function(theslider, whichevent, x, y, extra) 
      --reaper.ShowConsoleMsg(tostring(theslider).." "..x.." "..y.."\n") 
    end
  return slider
end -- function make_question
-- End new functions -------------------------------------
----------------------------------------------------------

function make_envelope(x,y,w,h,assocslider)
  result={}
  result.x=function() return x end
  result.y=function() return borderWidth + GUIelementHeight*(#tableGUIelements+0.5) end
  result.w=function() return gfx.w-20 end
  result.h=function() return (gfx.h - 34 -  borderWidth - GUIelementHeight*(#tableGUIelements+0.5)) end
  
  result.type="Envelope"
  result.hotpoint=0
  result.envelope=assocslider.envelope
  result.name=assocslider.name
  return result
end

-- The column of buttons in original release was removed,
--     so this function is not necessary any more
--[[
function make_button(x,y,w,h,click_cb)
  result={}
  result.x=function() return x end
  result.y=function() return y end
  result.w=function() return w end
  result.h=function() return h end
  result.type="Button"
  result.name="MyButton"
  result.OnClick=click_cb
  result.checked=true
  return result
end
]]
function bound_value(minval, val, maxval)
    if val<minval then return minval end
    if val>maxval then return maxval end
    return val
end

function quantize_value(val, numsteps)
    stepSize = math.floor(0.5 + (laneMaxValue-laneMinValue)/numsteps)
    return(stepSize * math.floor(0.5 + val/stepSize))
    --return 1.0/numsteps*math.floor(val*numsteps)
end

-- This function has been removed since BR_EnvGetProperties is more accurate
--[[
envelope_ranges={["Volume"] = {0.0,2.0}, ["Volume (Pre-FX)"] = {0.0,2.0},
                 ["Pan"] = {-1.0,1.0}, ["Pan (Pre-FX)"] = {-1.0,1.0}, ["Playrate"]={0.1,4.0} }

function get_envelope_range(env)
  rv, name=reaper.GetEnvelopeName(env, "")
  if rv==true then
    if envelope_ranges[name]~=nil then 
      return envelope_ranges[name][1],envelope_ranges[name][2] end
    --if name=="Volume" or name=="Volume (Pre-FX)" then return 0.0,2.0 end
    --if name=="Pan" or name=="Pan (Pre-FX)" then return -1.0,1.0 end
  end
  return 0.0,1.0
end
]]


function setColor(colorTable)
    gfx.r = colorTable[1]
    gfx.g = colorTable[2]
    gfx.b = colorTable[3]
    gfx.a = colorTable[4]
end


function getBPM(projtime)
    return(reaper.TimeMap_GetDividedBpmAtTime(projtime))
    --[[
    local currentQN = reaper.TimeMap2_timeToQN(0, projtime)
    local nextQNtime = reaper.TimeMap2_QNToTime(0, currentQN + 1)
    return(60/(nextQNtime-projtime))
    ]]
end


function is_in_rect(xcora,ycora,xa,ya,wa,ha)
if (xcora>=xa and xcora<xa+wa and ycora>=ya and ycora<ya+ha) then
  return true
end
return false
end

function slider_to_value(slid)
  
end

function slider_to_string(slid)
    if slid.name=="Quant steps" then 
        if slid.value == 1 then return("None")
        else return(math.ceil(3+slid.value*125))
        end
    elseif slid.name=="Phase step" then 
        local totalSteps, _, _, _, _ = shape_function[shapeSelected](0)
        local phaseStep = math.floor(slid.value * totalSteps)
        return tostring(phaseStep) .."/".. tostring(totalSteps)
    elseif slid.name=="Morph" then
        return tostring((math.floor(0.5 + (slid.value-0.5)*200))/100)
    else
       return tostring((math.floor(0.5 + slid.value*100))/100)
    end
end

function drawGUIobject(slid) 
    if slid.type == "Slider" then
        local imgw = 32
        local imgh = 25
        setColor(textColor)
        gfx.x=slid.x()+3
        gfx.y=slid.y() --+2
        gfx.drawstr(slid.name .. ": " .. slider_to_string(slid))
        gfx.a=gfx.a - 0.6;
        --gfx.rect(slid.x(),slid.y()+15,slid.w(),2,true)
        local thumbx=slid.x()+(slid.w()-(imgw/1))*slid.value
        local slidWVal = slid.w() * slid.value
        if shadows == true then
            setColor({0,0,0,1})
            gfx.rect(slid.x()+1,slid.y()+16,slidWVal,7,true)  
        end
        setColor(foregroundColor)
        gfx.gradrect(slid.x(), slid.y()+15, slidWVal,7, gfx.r*0.15, gfx.g*0.15, gfx.b*0.15, 0.5, gfx.r/slidWVal, gfx.g/slidWVal, gfx.b/slidWVal)
        --gfx.rect(thumbx,slid.y(),imgw,imgh,true)  
    
    elseif slid.type == "Button" then
        function fillRoundRect(x,y,w,h,r)
            if r>w/2 or r>h/2 then r=math.floor(min(w/2, h/2)) end
            for i = 0, r-1 do
                gfx.line(x+r-i, y+i, x+w-1-r+i, y+i, 0)
                gfx.line(x+r-i, y+h-1-i, x+w-1-r+i, y+h-1-i, 0)
            end
            for i = y+r, y+h-1-r do
                gfx.line(x, i, x+w-1, i, 0)
            end
        end
        stringw,stringh = gfx.measurestr(slid.name)
        ampw,amph = gfx.measurestr("Amplitude")
        if slid.name == tableGUIelements[GUIelement_ENV].name then
            --local stringw,stringh = gfx.measurestr("Amplitude")
            if shadows == true then
                setColor({0,0,0,1})
                --gfx.rect(gfx.w/2-ampw/2-5, slid.y()-1, ampw+12, stringh+7, true)
                fillRoundRect(gfx.w/2-ampw/2-5, slid.y()-1, ampw+12, stringh+7, 1)
            end
            setColor(foregroundColor)
            gfx.a = gfx.a*0.7
            --gfx.a = gfx.a+0.1
            --gfx.rect(gfx.w/2-ampw/2-6, slid.y()-2, ampw+12, stringh+7, true) --(slid.x(),slid.y()-2,stringw+6,stringh+8,true)
            fillRoundRect(gfx.w/2-ampw/2-6, slid.y()-2, ampw+12, stringh+7, 1)
            setColor(textColor)
            gfx.x=gfx.w/2-stringw/2 --slid.x()+3
            gfx.y=slid.y()+2
            gfx.drawstr(slid.name)
        else
            setColor(textColor)
            gfx.x=gfx.w/2-stringw/2 --slid.x()+3
            gfx.y=slid.y()+2
            gfx.drawstr(slid.name)
        end
    
    elseif slid.type == "Menu" then
        setColor(textColor)
        gfx.x=slid.x()+3
        gfx.y=slid.y()+2
        gfx.drawstr(slid.name)
        if shadows == true then
            setColor({0,0,0,1})
            gfx.x=slid.x()+4+gfx.measurestr(slid.name)+gfx.measurestr("w")
            gfx.y=slid.y()+3
            gfx.drawstr(shapeTable[shapeSelected])
        end
        setColor(foregroundColor)
        gfx.x=slid.x()+3+gfx.measurestr(slid.name)+gfx.measurestr("w")
        gfx.y=slid.y()+2
        gfx.a = gfx.a + 0.3
        gfx.drawstr(shapeTable[shapeSelected])
    
    elseif slid.type == "Question" then
        setColor(textColor)
        gfx.x=slid.x()+3
        gfx.y=slid.y()+2
        gfx.drawstr(slid.name)
        if shadows == true then
            gfx.x=slid.x()+4+gfx.measurestr(slid.name)+gfx.measurestr("w")
            gfx.y=slid.y()+3
            setColor({0,0,0,1})
            if slid.value == 1 then
                gfx.drawstr(slid.trueanswer)
            else
                gfx.drawstr(slid.falseanswer)      
            end
        end
        gfx.x=slid.x()+3+gfx.measurestr(slid.name)+gfx.measurestr("w")
        gfx.y=slid.y()+2
        setColor(foregroundColor)
        gfx.a = gfx.a + 0.3  
        if slid.value == 1 then
            gfx.drawstr(slid.trueanswer)
        else
            gfx.drawstr(slid.falseanswer)      
        end    
    end    
        
end

-- The column of buttons in original release was removed,
--     so this function is not necessary any more
--[[
function draw_button(but)
  if but.type~="Button" then return end
  gfx.r=1.0; gfx.g=1.0; gfx.b=1.0; gfx.a=1.0;
  gfx.rect(but.x(),but.y(),but.w(),but.h(),false)
  if but.checked==true then
    gfx.line(but.x(),but.y(),but.x()+but.w(), but.y()+but.h())
    gfx.line(but.x(),but.y()+but.h(),but.x()+but.w(),but.y())
  end
end
]]

function draw_envelope(env,enabled)

    -- Draw Envelope title
    if env.type~="Envelope" then return end
    local title=env.name
    setColor(textColor)
    title = "Envelope: " .. title
    gfx.x = gfx.w/2 - gfx.measurestr(title)/2
    gfx.y = gfx.h - 23
    gfx.drawstr(title)
    
    -- draw "?" and "≡" buttons --!!!!!!!!New in 2.20
    local charWidth = gfx.measurestr("≡")
    if shadows == true then
        gfx.x = gfx.w - 19
        gfx.y = gfx.h - 22
        setColor({0,0,0,1})
        gfx.drawstr("?")
        gfx.x = 19 - charWidth
        gfx.drawstr("≡")
    end
    setColor(foregroundColor)
    gfx.a = 1
    gfx.y = gfx.h - 23
    gfx.x = gfx.w - 20 --gfx.measurestr("?")
    gfx.drawstr("?")
    gfx.x = 20 - charWidth --gfx.measurestr("?")
    gfx.drawstr("≡")
        
    setColor(backgroundColor)
    gfx.r = gfx.r/3; gfx.g = gfx.g/3; gfx.b = gfx.b/3
    gfx.rect(env.x(), env.y(), env.w(), env.h())

        
    --env.h = function() return(envHeight+gfx.h-initYsize) end
    
    local xcor0=0.0
    local ycor0=0.0
    local i=1
    for key,envpoint in pairs(env.envelope) do
        local xcor = env.x()+envpoint[1]*env.w()
        local ycor = env.y()+(1.0-envpoint[2])*env.h()
        
        if i>1 then
            --reaper.ShowConsoleMsg(i.." ")
            setColor(textColor)
            gfx.a = gfx.a * 0.8
            gfx.line(xcor0,ycor0,xcor,ycor,true)
        end
        xcor0=xcor
        ycor0=ycor
        
        if env.hotpoint==i then
            setColor(hotbuttonColor)            
            
            -- Must calculate the hotpoint time and rate displays
            local timeAtNode
            if type(time_end) == "number" and type(time_start) == "number" and time_start<=time_end then
                if tableGUIelements[GUIelement_TIMEBASE].value == 1 then -- Timebase == Beats
                    local timeStartQN = reaper.TimeMap_timeToQN(time_start)
                    local timeEndQN = reaper.TimeMap_timeToQN(time_end)
                    timeAtNode = reaper.TimeMap_QNToTime(timeStartQN + envpoint[1]*(timeEndQN-timeStartQN))
                else
                    timeAtNode = time_start + envpoint[1]*(time_end - time_start)
                end
            else -- Just in case no envelope selected, or loop_GetInputsAndUpdate() has not yet been run, or something.
                timeAtNode = 0
            end
            
            -- If Rate envelope, display either period or frequency above hotpoint
            if env.name == "Rate" then
                
                if tableGUIelements[GUIelement_TIMEBASE].value >= 0.5 and hotpointRateDisplayType == "period note length" then
                    local pointRate = beatBaseMin + (beatBaseMax - beatBaseMin)*(envpoint[2]^2)
                    local pointRateInverse = 1.0/pointRate
                    if pointRateInverse == math.floor(pointRateInverse) then hotString = string.format("%i", tostring(pointRateInverse))
                    elseif pointRate == math.floor(pointRate) then hotString = "1/" .. string.format("%i", tostring(pointRate))
                    elseif pointRate > 1 then hotString = "1/" .. string.format("%.3f", tostring(pointRate))
                    else hotString = string.format("%.3f", tostring(pointRateInverse))
                    end
                elseif tableGUIelements[GUIelement_TIMEBASE].value >= 0.5 and hotpointRateDisplayType == "frequency" then
                    local bpm = getBPM(timeAtNode)
                    local pointRate = beatBaseMin + (beatBaseMax - beatBaseMin)*(envpoint[2]^2)
                    local pointFreq = (1.0/240) * pointRate * bpm
                    hotString = string.format("%.3f", tostring(pointFreq)) .. "Hz"
                elseif tableGUIelements[GUIelement_TIMEBASE].value < 0.5 and hotpointRateDisplayType == "period note length" then
                    local bpm = getBPM(timeAtNode)
                    local pointFreq = timeBaseMin + (timeBaseMax-timeBaseMin)*(envpoint[2]^2)
                    local pointRate = (1.0/bpm) * pointFreq * 240 -- oscillations/sec * sec/min * min/beat * beats/wholenote
                    local pointRateInverse = 1.0/pointRate
                    if pointRateInverse == math.floor(pointRateInverse) then hotString = string.format("%i", tostring(pointRateInverse))
                    elseif pointRate == math.floor(pointRate) then hotString = "1/" .. string.format("%i", tostring(pointRate))
                    elseif pointRate > 1 then hotString = "1/" .. string.format("%.3f", tostring(pointRate))
                    else hotString = string.format("%.3f", tostring(pointRateInverse))
                    end
                elseif tableGUIelements[GUIelement_TIMEBASE].value < 0.5 and hotpointRateDisplayType == "frequency" then -- hotpointRateDisplayType == "frequency"
                    local pointFreq = timeBaseMin+((timeBaseMax-timeBaseMin)*(envpoint[2])^2.0)
                    hotString = string.format("%.3f", tostring(pointFreq)) .. "Hz"
                end
                hotString = "R =" .. hotString
                
            -- If Amplitude or Center, display value scaled to actual envelope range.
            -- (The laneMaxValue and laneMinValue variables are calculated in the loop_GetInputsAndUpdate() function.)
            elseif env.name == "Amplitude" then
                hotString = "A =" .. string.format("%.0f", tostring(envpoint[2]*0.5*(laneMaxValue-laneMinValue)))
            else -- env.name == "Center"
                hotString = "C =" .. string.format("%.0f", tostring(laneMinValue + envpoint[2]*(laneMaxValue-laneMinValue)))
            end
            
            if hotpointTimeDisplayType >= -1 and hotpointTimeDisplayType <=5 then
                hotString = hotString .. ", " .. "t =" .. reaper.format_timestr_pos(timeAtNode, "", hotpointTimeDisplayType)
            elseif hotpointTimeDisplayType == 6 then
                hotString = hotString .. ", " .. "t =" .. string.format("%.3f", tostring(envpoint[1]))
            -- if hotpointTimeDisplayType == 7 then do nothing
            end
            
            -- The following lines shift the x-position of the string            
            stringWidth, stringHeight = gfx.measurestr(hotString)
            gfx.x = (xcor+3) - (stringWidth+5)*(xcor-env.x())/env.w()
            gfx.y = ycor - 5 - stringHeight
            gfx.drawstr(hotString)
        else
            setColor(buttonColor)
        end
        
        i=i+1
        gfx.circle(xcor,ycor,5.0,true,true)
    end
end

function get_hot_env_point(env,mx,my)
  for key,envpoint in pairs(env.envelope) do
    local xcor = env.x()+envpoint[1]*env.w()
    local ycor = env.y()+(1.0-envpoint[2])*env.h()
    if is_in_rect(mx,my,xcor-5,ycor-5,10,10) then return key end
  end
 
  return 0
end

function get_env_interpolated_value(env,x,curveType)
  if #env==0 then return 0.0 end
  if x<=env[1][1] then return env[1][2] end
  if x>=env[#env][1] then return env[#env][2] end
  local i=1
  for key,envpoint in pairs(env) do
      if x>=envpoint[1] then
          nextpt=env[key+1]
          if nextpt==nil then nextpt=envpoint end
          if x<nextpt[1] then
              local timedelta=nextpt[1]-envpoint[1]
              if timedelta<0.0001 then timedelta=0.0001 end
              -- Remember that the envelope area is mapping to freqhz using a power curve:
              -- freqhz = 0.2+(15.8*freq_norm_to_use^2.0)
              -- Therefore this function was changed from a linear interpolation to a similar power curve.
              if curveType == "parabolic" then
                  local valuedelta=nextpt[2]^2 - envpoint[2]^2
                  local interpos=(x-envpoint[1])
                  return ((envpoint[2]^2 + valuedelta*(interpos/timedelta))^0.5)
              else
                  local valuedelta=nextpt[2] - envpoint[2]
                  local interpos=(x-envpoint[1])
                  return (envpoint[2] + valuedelta*(interpos/timedelta))
              end
          end
      end
      i=i+1
  end
  return 0.0
end


function sort_envelope(env)
  table.sort(env,function(a,b) return a[1]<b[1] end)
end


---------------------------------------------------------------------------------------------------
-- The important function that generates the nodes
function generateNodes()

    local freq = GUIelement_RATE and tableGUIelements[GUIelement_RATE].value or 0.5
    local amp  = GUIelement_AMPLITUDE and tableGUIelements[GUIelement_AMPLITUDE].value or 0.5
    local center = GUIelement_CENTER and tableGUIelements[GUIelement_CENTER].value or 0.5
    local phase = GUIelement_PHASE and tableGUIelements[GUIelement_PHASE].value or 0
    local randomness = GUIelement_RANDOMNESS and tableGUIelements[GUIelement_RANDOMNESS].value or 0
    local quansteps = GUIelement_QUANTSTEPS and tableGUIelements[GUIelement_QUANTSTEPS].value or 0
    local tilt = 0
    local fadindur = GUIelement_FADEIN and tableGUIelements[GUIelement_FADEIN].value or 0
    local fadoutdur = GUIelement_FADEOUT and tableGUIelements[GUIelement_FADEOUT].value or 0
    local ratemode = GUIelement_TIMEBASE and tableGUIelements[GUIelement_TIMEBASE].value or 0
             
    math.randomseed(1)
       
    tableVals = nil
    tableVals = {}        
  
    time=time_start
  
    --local freqhz=1.0+7.0*freq^2.0
    --[[local nvindex=math.floor(1+(#notevalues-1)*freq)
    local dividend=notevalues[nvindex][1]
    local divisor=notevalues[nvindex][2]
    ]]
    --reaper.ShowConsoleMsg(dividend .. " " .. divisor .. "\n")
    --[[!!!!freqhz=1.0
    if ratemode>0.5 then
        freqhz=(reaper.Master_GetTempo()/60.0)*1.0/(dividend/divisor)
    else
        freqhz=0.1+(31.9*freq^2.0)
    end ]]   
    
    --!! -- Keep time_start and time_end in timebase, gen_time_start and gen_time_end is in time or beats.
    if ratemode>0.5 then
      time=reaper.TimeMap_timeToQN(time_start)
      gen_time_start = time --!!
      gen_time_end=reaper.TimeMap_timeToQN(time_end)
    else
      time=time_start
      gen_time_start = time
      gen_time_end=time_end
    end
    
    local timeseldur = gen_time_end - gen_time_start --!!time_end-time_start
  
    -- local fadoutstart_time = time_end-time_start-timeseldur*fadoutdur
    
    local totalSteps, _, _, _, _ = shape_function[shapeSelected](0)
    local phaseStep = math.floor(phase * totalSteps)
  
    local segshape=-1.0+2.0*tilt
    local ptcount=0
        
    tableNodes = nil
    tableNodes = {}
    ---------------------------------------------------------------------------------------------------
    -- The main loop that inserts points.
    -- In order to interpolate the closing envelope point that will be inserted at end_time,
    --    this loop must actually progress one step beyond the end time.  The point beyond end_time 
    --    of course not be inserted, but will only be used to calculate the interpolated closing point.
    -- while isBeyondEnd == false do
    repeat
        time_to_interp = (1.0/timeseldur)*(time-gen_time_start) --!!time_start

        freq_norm_to_use = get_env_interpolated_value(tableGUIelements[GUIelement_RATE].envelope,time_to_interp, rateInterpolationType)
        if ratemode < 0.5 then
            -- Timebase is time, so step size in seconds
            nextNodeStepSize = (1.0/(timeBaseMin + (timeBaseMax-timeBaseMin)*(freq_norm_to_use^2.0))) / totalSteps
        else
            -- Timebase == beats, so step size in Quarter Notes
            nextNodeStepSize = (4.0/(beatBaseMin + (beatBaseMax-beatBaseMin)*(freq_norm_to_use^2.0))) / totalSteps
        end                
              
        ---------------------     
        -- Get info for point
        totalSteps, val, pointShape, pointTension, linearJump = shape_function[shapeSelected](ptcount-phaseStep)
        
        -- Bézier curves are not yet implemented, so replace Bézier with Linear
        if pointShape == 5 then pointShape = 0 end
        
        -- Usually "false" values are skipped, but not if it is the very first point
        --   Try to interpolate
        if ptcount == 0 and val == false then
            for i = 1, totalSteps-1 do
                _, nextVal, nextShape, nextTension, nextJump = shape_function[shapeSelected](ptcount-phaseStep+i)
                if nextVal ~= false then n=i break end
            end
            for i = 1, totalSteps-1 do
                _, prevVal, prevShape, prevTension, prevJump = shape_function[shapeSelected](ptcount-phaseStep-i)
                if prevVal ~= false then p=i break end
            end
            if nextVal ~= false and prevVal ~= false then -- if entire shape is "false", then don't bother
                if prevJump then prevVal=-prevVal end
                linearJump = false
                if prevShape == 1 then -- square
                    val = prevVal
                elseif prevShape == 2 then -- sine
                    val = prevVal + (nextVal-prevVal)*(1-math.cos(math.pi * p/(p+n)))/2
                    pointShape = 2 + p/(p+n)
                elseif prevShape == 3 then -- Fast start (aka inverse parabolic)
                    val = nextVal + (prevVal-nextVal)*((n/(p+n))^3)
                    pointShape = 3 + p/(p+n)
                elseif prevShape == 4 then -- Fast end (aka parabolic)
                    val = prevVal + (nextVal-prevVal)*((p/(p+n))^3)
                    pointShape = 4 + p/(p+n)                
                else -- Linear or Bézier: This interpolation will only be accurate for linear shapes
                    val = prevVal + (nextVal-prevVal) * p / (p+n)
                end
            else
                return(0) -- entire shape is false
            end
        
        end  
               
        if val == false then -- Skip point
            time=time+nextNodeStepSize
            ptcount=ptcount+1   
        else -- Point will be inserted. Must first calculate value
            -- If linearJump, then oppositeVal must also be calculated               
            if linearJump == true then oppositeVal = -val end
          
            -- fade goes to infinity when trying to calculate point beyond end_time, 
            --    so use fadeHackTime when calculating the point efter end_time.
            fade_gain = 1.0
            timeFadeHack = math.min(time, gen_time_end) 
            if timeFadeHack - gen_time_start < timeseldur*fadindur then
               fade_gain = 1.0/(timeseldur*fadindur)*(timeFadeHack - gen_time_start)
            end
            if timeFadeHack - gen_time_start > timeseldur - timeseldur*fadoutdur then
               --!!fade_gain = 1.0-(1.0/(timeseldur*fadoutdur)*(timeFadeHack - fadoutstart_time - gen_time_start))
               fade_gain = fade_gain * (1.0/(timeseldur*fadoutdur))*(gen_time_end - timeFadeHack)
            end
                      
            
            --if time_to_interp<0.0 or time_to_interp>1.0 then
            --  reaper.ShowConsoleMsg(time_to_interp.." ") end
            amp_to_use = get_env_interpolated_value(tableGUIelements[GUIelement_AMPLITUDE].envelope,time_to_interp, "linear")
            --if amp_to_use<0.0 or amp_to_use>1.0 then reaper.ShowConsoleMsg(amp_to_use.." ") end
            val=0.5+(0.5*amp_to_use*fade_gain)*val
            local center_to_use=get_env_interpolated_value(tableGUIelements[GUIelement_CENTER].envelope,time_to_interp, "linear")
            local rangea=laneMaxValue-laneMinValue
            val=laneMinValue+((rangea*center_to_use)+(-rangea/2.0)+(rangea/1.0)*val)
            local z=(2*math.random()-1)*randomness*(laneMaxValue-laneMinValue)/2
            val=val+z
            local tilt_ramp = (time - gen_time_start) / (timeseldur) --!!1.0/(gen_time_end-time_start) * (time-time_start)
            local tilt_amount = -1.0+2.0*tilt
            local tilt_delta = -tilt_amount+(2.0*tilt_amount)*time_to_interp --!!tilt_ramp
                --[[val=val+tilt_delta
            local num_quansteps=3+quansteps*61
            if num_quansteps<64 then
                val=quantize_value(val,num_quansteps)
            end]]
            --[[if quansteps ~= 1 then
                val=quantize_value(val,3 + math.ceil(quansteps*125))
            end]]
            
                      
            val=bound_value(laneMinValue,val,laneMaxValue)
            --val = reaper.ScaleToEnvelopeMode(envscalingmode, val)
            local tension = segshape*pointTension  
            
            --[[ To insert envelope nodes, timebase==beat must be mapped back to timebase==time
            --!!local instime=time
            if ratemode>0.5 then
                instime=reaper.TimeMap2_QNToTime(0, time)
            else
                instime = time
            end
            ]]
            
            if ratemode == 1 then
                insPPQ = reaper.MIDI_GetPPQPosFromProjQN(take, time)
            else
                insPPQ = reaper.MIDI_GetPPQPosFromProjTime(take, time)
            end
            
            if linearJump == true then
                oppositeVal=0.5+(0.5*amp_to_use*fade_gain)*oppositeVal
                oppositeVal=laneMinValue+((rangea*center_to_use)+(-rangea/2.0)+(rangea/1.0)*oppositeVal)
                oppositeVal=oppositeVal-z
                --[[if quansteps ~= 1 then
                    val=quantize_value(val,3 + math.ceil(quansteps*125))
                end]]
                oppositeVal=bound_value(laneMinValue,oppositeVal,laneMaxValue)
                local tension = segshape*pointTension
                table.insert(tableNodes, {PPQ = insPPQ, 
                                          value = val, 
                                          shape = 0, 
                                          tension = 0})
                table.insert(tableNodes, {PPQ = insPPQ,
                                          value = oppositeVal, 
                                          shape = pointShape, 
                                          tension = tension})
            else
                table.insert(tableNodes, {PPQ = insPPQ, 
                                          value = val, 
                                          shape = pointShape, 
                                          tension = tension})       
            end

            time=time+nextNodeStepSize
            ptcount=ptcount+1
        end -- if val ~= false
       
        instime = reaper.MIDI_GetProjTimeFromPPQPos(take, insPPQ)
    until instime >= time_end -- while time < gen_end_time
    --end -- while time<=gen_end_time
    
    --if last_used_parms==nil then last_used_params={"}
    --last_used_params[env]={freq,amp,center,phase,randomness,quansteps,tilt,fadindur,fadoutdur,ratemode,clip}
    
    --reaper.Envelope_SortPoints(env)
    --tableNodes:sort(sortPPQ)
end

function exit()

    -- Find and store the last-used coordinates of the GUI window, so that it can be re-opened at the same position
    local docked, xPos, yPos, xWidth, yHeight = gfx.dock(-1, 0, 0, 0, 0)
    if docked == 0 and type(xPos) == "number" and type(yPos) == "number" then
        -- xPos and yPos should already be integers, but use math.floor just to make absolutely sure
        reaper.SetExtState("LFO generator", "Last coordinates", string.format("%i", math.floor(xPos+0.5)) .. "," .. string.format("%i", math.floor(yPos+0.5)), true)
    end
    gfx.quit()
  
    -- New versions of the SWS extension provide a function to focus the MIDI editor!
    --    This will prevent shortcuts from accidentally being sent to the Main window. 
    if reaper.APIExists("SN_FocusMIDIEditor") then
        reaper.SN_FocusMIDIEditor()
    end
    
    -- MIDI_Sort used to be buggy when dealing with overlapping or unsorted notes,
    --    causing infinitely extended notes or zero-length notes.
    -- Fortunately, these bugs were seemingly all fixed in v5.32.
    reaper.MIDI_Sort(take)  
    
    -- Check that there were no inadvertent shifts in the PPQ positions of unedited events.
    if not (sourceLengthTicks == reaper.BR_GetMidiSourceLenPPQ(take)) then
        reaper.MIDI_SetAllEvts(take, origMIDI) -- Restore original MIDI
        reaper.ShowMessageBox("The script has detected inadvertent shifts in the PPQ positions of unedited events."
                              .. "\n\nThis may be due to a bug in the script, or in the MIDI API functions."
                              .. "\n\nPlease report the bug in the following forum thread:"
                              .. "\nhttp://forum.cockos.com/showthread.php?t=176878"
                              .. "\n\nThe original MIDI data will be restored to the take.", "ERROR", 0)
    end
        
    if isInline then reaper.UpdateArrange() end  
    
    -- Deactivate toolbar button, if any
    if sectionID ~= nil and cmdID ~= nil and sectionID ~= -1 and cmdID ~= -1 then
        reaper.SetToggleCommandState(sectionID, cmdID, 0)
        reaper.RefreshToolbar2(sectionID, cmdID)
    end
    
    reaper.Undo_OnStateChange_Item(0, "LFO tool: ".. targetLaneString, item)
end -- function exit() 

----------------------


function getBPM(projtime)
    return(reaper.TimeMap_GetDividedBpmAtTime(projtime))
    --[[
    local currentQN = reaper.TimeMap2_timeToQN(0, projtime)
    local nextQNtime = reaper.TimeMap2_QNToTime(0, currentQN + 1)
    return(60/(nextQNtime-projtime))
    ]]
end


-------------------------------------------------------------------------
-- The function that gets user inputs from the GUI and then draws the CCs
captured_control=nil
was_changed=false
already_added_pt=false
already_removed_pt=false
last_mouse_cap=0

function loop_GetInputsAndUpdate()

    ---------------------------------------------------------------------------
    -- First, go through several tests to detect whether the script should exit
    -- 1) Quit script if GUI has been closed, or Esc has been pressed
    local char = gfx.getchar()
    if char<0 or char==27 then 
        return(0)
    end 
    
    -- 2) The LFO Tool automatically quits if either of the following changes:
    --    * editor, 
    --    * active take, 
    --    * time selection, 
    --    * last clicked lane.
    --    This prepares the editor to insert a new LFO.
    --    (Clicking in the piano roll to select new notes changes the "last clicked lane".)
    if not isInline then
        local newEditor = reaper.MIDIEditor_GetActive()
        if newEditor ~= editor then return(0) end
        
        local newTake = reaper.MIDIEditor_GetTake(newEditor)
        if newTake ~= take then return(0) end
        
        if laneToUse == "last clicked" then
            local newtargetLane = reaper.MIDIEditor_GetSetting_int(newEditor, "last_clicked_cc_lane")   
            if newtargetLane == -1 then newtargetLane = 0x200 end
            if newtargetLane ~= targetLane then
                return(0)
            end
        end
    end
    
    
    if selectionToUse == "time" then
        local time_start_new, time_end_new = reaper.GetSet_LoopTimeRange(false, false, 0.0, 0.0, false)
        if time_start_new ~= timeSelectStart or time_end_new ~= timeSelectEnd then 
            return(0) 
        end
    end
    
    setColor(backgroundColor)
    gfx.rect(0,0,gfx.w,gfx.h,true)
    
    ------------------------------------------------------------------------
    -- Reset several parameters
    -- Including firstClick to prevent long mousebutton press from activating buttons multiple times
    if gfx.mouse_cap==0 then 
        captured_control=nil
        already_added_pt=false 
        already_removed_pt=false
        firstClick = true
        was_changed=false
    end
    
    -----------------------------------------------------------------------
    -- Now, check all the possible combinations of mousebuttons, mousewheel
    --    and mouse position to see what to do
    
    -- Show help menu
    if gfx.mouse_cap == LEFTBUTTON
    and gfx.mouse_x > gfx.w-22 and gfx.mouse_y > gfx.h-22
    and firstClick == true then
        firstClick = false
        reaper.ShowConsoleMsg(helpText)       
    end  
    
    -- Iterate through all the buttons and sliders in the GUI  
    local dogenerate=false
    for key, tempcontrol in pairs(tableGUIelements) do
    
      if is_in_rect(gfx.mouse_x,gfx.mouse_y,tempcontrol.x(),tempcontrol.y(),tempcontrol.w(),tempcontrol.h()) 
      or (key == GUIelement_ENV and is_in_rect(gfx.mouse_x,gfx.mouse_y,0,tempcontrol.y()-15,gfx.w,tempcontrol.h()+22))
      --get_hot_env_point(tempcontrol,gfx.mouse_x,gfx.mouse_y)>0) -- Envelope gets captured if on hotbutton, even if outside rectangle
      then
          if gfx.mouse_cap==LEFTBUTTON and captured_control==nil then
              captured_control=tempcontrol
          end
          --[[
          if tempcontrol.type=="Slider" and gfx.mouse_cap==2 
            and (tempcontrol.name=="Rate" or tempcontrol.name=="Amplitude") then
            gfx.x=gfx.mouse_x
            gfx.y=gfx.mouse_y
            local menuresult=gfx.showmenu("Toggle envelope active|Show envelope")
            if menuresult==1 then
              if tempcontrol.env_enabled==false then
                tempcontrol.env_enabled=true else
                tempcontrol.env_enabled=false
              end
            end
            if menuresult==2 then
              tableGUIelements[100].envelope=tempcontrol.envelope
              tableGUIelements[100].name=tempcontrol.name
            end
          end
          ]]
        
          -- Click on Rate/Center/Amplitude buttons to change envelope type
          --[[if char == string.byte("a") or (gfx.mouse_cap==LEFTBUTTON and (tempcontrol.name=="Rate" or tempcontrol.name=="Amplitude" or tempcontrol.name=="Center") then
              tableGUIelements[100].envelope=tempcontrol.envelope
              tableGUIelements[100].name=tempcontrol.name
              firstClick = false
              dogenerate = true
          end ]]
          if char == string.byte("r") or (gfx.mouse_cap==LEFTBUTTON and tempcontrol.name=="Rate") then
              tableGUIelements[GUIelement_ENV].envelope=tableGUIelements[GUIelement_RATE].envelope
              tableGUIelements[GUIelement_ENV].name=tableGUIelements[GUIelement_RATE].name -- = tempcontrol.name
              firstClick = false
              dogenerate = true
          elseif char == string.byte("c") or (gfx.mouse_cap==LEFTBUTTON and tempcontrol.name=="Center") then
              tableGUIelements[GUIelement_ENV].envelope=tableGUIelements[GUIelement_CENTER].envelope
              tableGUIelements[GUIelement_ENV].name=tableGUIelements[GUIelement_CENTER].name -- = tempcontrol.name
              firstClick = false
              dogenerate = true
          elseif char == string.byte("a") or (gfx.mouse_cap==LEFTBUTTON and tempcontrol.name=="Amplitude") then
              tableGUIelements[GUIelement_ENV].envelope=tableGUIelements[GUIelement_AMPLITUDE].envelope
              tableGUIelements[GUIelement_ENV].name=tableGUIelements[GUIelement_AMPLITUDE].name -- tempcontrol.name
              firstClick = false
              dogenerate = true
          end
          
          -- Enable or disable Real-time copy-to-CC
          if gfx.mouse_cap==LEFTBUTTON and tempcontrol.type == "Question" --name=="Real-time copy to CC?") 
          and firstClick == true
          then
            if tempcontrol.value == 0 then
                tempcontrol.value = 1
            else
                tempcontrol.value = 0
            end
            firstClick = false
            dogenerate = true
          end 
      
          -- Choose envelope shape
          if gfx.mouse_cap == LEFTBUTTON and tempcontrol.name == "LFO shape?" then
              gfx.x = gfx.mouse_x
              gfx.y = gfx.mouse_y
              retval = gfx.showmenu(shapeMenu)
              if retval ~= 0 then shapeSelected = retval end
              dogenerate = true
              firstClick = false
          end       
      
          --------------------------------------------------------------------------------------------------
          -- Several options when drawing in envelope
          if tempcontrol.type=="Envelope" then
            
              -- Detect hotpoint if hovering over or drag-deleting
              -- The value of the tempcontrol.hotpoint variable is the number of the 'hot'
              --       node of the envelope.  0 if no hotpoint.
              if gfx.mouse_cap==NOTHING or gfx.mouse_cap==(LEFTBUTTON+ALTKEY) then
                tempcontrol.hotpoint=get_hot_env_point(tempcontrol,gfx.mouse_x,gfx.mouse_y)
              end
              
              -- Ctrl+left click in envelope area to set all nodes to same value
              if gfx.mouse_cap == (LEFTBUTTON + CTRLKEY) then
                  pt_y = 1.0/tempcontrol.h()*(gfx.mouse_y-tempcontrol.y())
                  for i = 1, #tempcontrol.envelope do
                      tempcontrol.envelope[i][2] = math.min(1, math.max(0, 1 - pt_y))
                  end
                  dogenerate = true
                  firstClick = false
              end 
              
      
              -- Leftclick to add an envelope node at mouse position
              -- Since the 'capture' area of the envelope area has been expanded, must make sure here that mouse is really inside area
              if tempcontrol.hotpoint==0 and gfx.mouse_cap==LEFTBUTTON and already_added_pt==false 
              and is_in_rect(gfx.mouse_x,gfx.mouse_y,tempcontrol.x(),tempcontrol.y(),tempcontrol.w(),tempcontrol.h()) 
              and tempcontrol == captured_control -- To prevent adding nodes while moving Fade out slider
              then
                  --reaper.ShowConsoleMsg("gonna add point ")
                  local pt_x = 1.0/tempcontrol.w()*(gfx.mouse_x-tempcontrol.x())
                  local pt_y = 1.0/tempcontrol.h()*(gfx.mouse_y-tempcontrol.y())
                  pt_x = math.min(1, math.max(0, pt_x))
                  pt_y = math.min(1, math.max(0, 1.0-pt_y))
                  -- Insert new points *before* last node, so that sorting isn't necessary.
                  for p = 1, #tempcontrol.envelope-1 do
                      if tempcontrol.envelope[p][1] <= pt_x and pt_x <= tempcontrol.envelope[p+1][1] then
                          table.insert(tempcontrol.envelope, p+1, {pt_x, pt_y})
                          break
                      end
                  end
                  dogenerate=true
                  already_added_pt=true
                  --sort_envelope(tempcontrol.envelope)
                  firstClick = false
              end
              
              -- Shift+left-drag to add multiple envelope nodes
              -- Ignore already_added_pt to allow left-drag
              -- Since the 'capture' area of the envelope area has been expanded, must make sure here that mouse is really inside area
              if tempcontrol.hotpoint==0 and gfx.mouse_cap==(LEFTBUTTON+SHIFTKEY) 
              and is_in_rect(gfx.mouse_x,gfx.mouse_y,tempcontrol.x(),tempcontrol.y(),tempcontrol.w(),tempcontrol.h()) 
              then --and already_added_pt==false then
                  --reaper.ShowConsoleMsg("gonna add point ")
                  local pt_x = 1.0/tempcontrol.w()*(gfx.mouse_x-tempcontrol.x())
                  local pt_y = 1.0/tempcontrol.h()*(gfx.mouse_y-tempcontrol.y())
                  pt_x = math.min(1, math.max(0, pt_x))
                  pt_y = math.min(1, math.max(0, 1.0-pt_y))
                  -- Insert new points *before* last node, so that sorting isn't necessary.
                  for p = 1, #tempcontrol.envelope-1 do
                      if tempcontrol.envelope[p][1] <= pt_x and pt_x <= tempcontrol.envelope[p+1][1] then
                          table.insert(tempcontrol.envelope, p+1, {pt_x, pt_y})
                          break
                      end
                  end
                  dogenerate=true
                  already_added_pt=true
                  --sort_envelope(tempcontrol.envelope)
                  firstClick = false
              end
              
              --Remove envelope point under mouse
              --Prevent removal of endpoint nodes
              --if already_removed_pt==false and tempcontrol.hotpoint>0 and gfx.mouse_cap == 17  then
              if tempcontrol.hotpoint > 0 and gfx.mouse_cap == (LEFTBUTTON+ALTKEY)
                  and not (tempcontrol.hotpoint == 1 or tempcontrol.hotpoint == #tempcontrol.envelope)
                  then
                  table.remove(tempcontrol.envelope,tempcontrol.hotpoint)
                  dogenerate=true
                  firstClick = false
                  --already_removed_pt=true
                  --reaper.ShowConsoleMsg("remove pt "..tempcontrol.hotpoint)
              end  
                           
              -- Move existing envelope node
              if tempcontrol==captured_control and tempcontrol.hotpoint>0 and gfx.mouse_cap==LEFTBUTTON then
                  local pt_x = (1.0/captured_control.w())*(gfx.mouse_x-captured_control.x())
                  local pt_y = (1.0/captured_control.h())*(gfx.mouse_y-captured_control.y())
                  local ept = tempcontrol.envelope[tempcontrol.hotpoint]
                  ept[2]=math.min(1, math.max(0, 1.0-pt_y))
                  if tempcontrol.hotpoint == 1 then 
                      ept[1]=0
                  elseif tempcontrol.hotpoint == #tempcontrol.envelope then
                      ept[1]=1
                  else
                      ept[1]=math.min(1, math.max(0, pt_x))
                      -- Did the hotpoint pass beyond another point?  If so, re-sort the envelope
                      -- (These explicit tests are faster than calling sort_envelope for the entire envelope.)
                      ::checkPointsForSorting::
                          if ept[1] < tempcontrol.envelope[tempcontrol.hotpoint-1][1] then
                              tempcontrol.envelope[tempcontrol.hotpoint] = tempcontrol.envelope[tempcontrol.hotpoint-1]
                              tempcontrol.envelope[tempcontrol.hotpoint-1] = ept
                              tempcontrol.hotpoint = tempcontrol.hotpoint - 1
                              goto checkPointsForSorting
                          elseif ept[1] > tempcontrol.envelope[tempcontrol.hotpoint+1][1] then
                              tempcontrol.envelope[tempcontrol.hotpoint] = tempcontrol.envelope[tempcontrol.hotpoint+1]
                              tempcontrol.envelope[tempcontrol.hotpoint+1] = ept
                              tempcontrol.hotpoint = tempcontrol.hotpoint + 1
                              goto checkPointsForSorting
                          end
                  end
                  dogenerate=true
                  firstClick = false
                  --reaper.ShowConsoleMsg("would drag pt "..tempcontrol.hotpoint.."\n")
              end
      
              -- Fine adjust hotpoint using mousewheel
              if tempcontrol.hotpoint>0 and gfx.mouse_cap==NOTHING and gfx.mouse_wheel ~= 0 then
                  if gfx.mouse_wheel < 0 then fineAdjust = -math.abs(fineAdjust) else fineAdjust = math.abs(fineAdjust) end
                  gfx.mouse_wheel = 0
                  tempcontrol.envelope[tempcontrol.hotpoint][2] = math.min(1, math.max(0, tempcontrol.envelope[tempcontrol.hotpoint][2] + fineAdjust))
                  dogenerate=true
                  --reaper.ShowConsoleMsg("would drag pt "..tempcontrol.hotpoint.."\n")
              end
              
                              
              -- Ctrl+mousewheel for fine adjustment of all points simultaneously
              if gfx.mouse_cap == CTRLKEY and gfx.mouse_wheel ~= 0 then
                  if gfx.mouse_wheel < 0 then fineAdjust = -math.abs(fineAdjust) else fineAdjust = math.abs(fineAdjust) end
                  gfx.mouse_wheel = 0
                  for i = 1, #tempcontrol.envelope do
                      tempcontrol.envelope[i][2] = math.min(1, math.max(0, tempcontrol.envelope[i][2] + fineAdjust))
                  end
                  dogenerate = true
              end 
        
              -- Rightclick away from nodes: select rate and time display
              if type(tempcontrol.hotpoint)=="number" and tempcontrol.hotpoint<=0
                  and gfx.mouse_cap==RIGHTBUTTON 
                  then
                  gfx.x = gfx.mouse_x; gfx.y = gfx.mouse_y
                  if hotpointRateDisplayType == "frequency" then
                      rateMenuString = "#Display hotpoint rate as|!Time (Frequency)|Beats (Period note length)"
                  else
                      rateMenuString = "#Display hotpoint rate as|Time (Frequency)|!Beats (Period note length)"
                  end 
                  
                  if hotpointTimeDisplayType == -1 then
                      rateMenuString = rateMenuString .. 
                      "||#Display hotpoint position as|!Project default|Time|Measures.beats+time|Measures.beats|Seconds|Samples|h:m:s:f|Normalized|Do not display time"
                  elseif hotpointTimeDisplayType == 0 then
                      rateMenuString = rateMenuString .. 
                      "||#Display hotpoint position as|Project default|!Time|Measures.beats+time|Measures.beats|Seconds|Samples|h:m:s:f|Normalized|Do not display time"
                  elseif hotpointTimeDisplayType == 1 then
                      rateMenuString = rateMenuString .. 
                      "||#Display hotpoint position as|Project default|Time|!Measures.beats+time|Measures.beats|Seconds|Samples|h:m:s:f|Normalized|Do not display time"
                  elseif hotpointTimeDisplayType == 2 then
                      rateMenuString = rateMenuString .. 
                      "||#Display hotpoint position as|Project default|Time|Measures.beats+time|!Measures.beats|Seconds|Samples|h:m:s:f|Normalized|Do not display time"
                  elseif hotpointTimeDisplayType == 3 then
                      rateMenuString = rateMenuString .. 
                      "||#Display hotpoint position as|Project default|Time|Measures.beats+time|Measures.beats|!Seconds|Samples|h:m:s:f|Normalized|Do not display time"
                  elseif hotpointTimeDisplayType == 4 then
                      rateMenuString = rateMenuString .. 
                      "||#Display hotpoint position as|Project default|Time|Measures.beats+time|Measures.beats|Seconds|!Samples|h:m:s:f|Normalized|Do not display time"
                  elseif hotpointTimeDisplayType == 5 then
                      rateMenuString = rateMenuString .. 
                      "||#Display hotpoint position as|Project default|Time|Measures.beats+time|Measures.beats|Seconds|Samples|!h:m:s:f|Normalized|Do not display time"
                  elseif hotpointTimeDisplayType == 6 then
                      rateMenuString = rateMenuString .. 
                      "||#Display hotpoint position as|Project default|Time|Measures.beats+time|Measures.beats|Seconds|Samples|h:m:s:f|!Normalized|Do not display time"
                  else --if hotpointTimeDisplayType == false then
                      rateMenuString = rateMenuString .. 
                      "||#Display hotpoint position as|Project default|Time|Measures.beats+time|Measures.beats|Seconds|Samples|h:m:s:f|Normalized|!Do not display time"
                  end
                  
                  retval = gfx.showmenu(rateMenuString)
                  if retval == 2 then hotpointRateDisplayType = "frequency" 
                  elseif retval == 3 then hotpointRateDisplayType = "period note length" 
                  elseif type(retval) == "number" and retval > 3 then hotpointTimeDisplayType = retval-6
                  end
                  
                  dogenerate = true       
              end
        
              -- If Rate: Ctrl-RightClick to quantize period of ALL nodes
              if tempcontrol.name == "Rate" and gfx.mouse_cap==CTRLKEY+RIGHTBUTTON then
                  gfx.x = gfx.mouse_x; gfx.y = gfx.mouse_y
                  local tableNoteRates = {nil, 32.0, 16.0*3.0/2.0, 16.0, 8.0*3.0/2.0, 8.0, 4.0*3.0/2.0, 4.0, 2.0*3.0/2.0, 2.0, 1.0, 0.5}                                            
                  quantmenuSel = gfx.showmenu("#Set rate at ALL nodes to:|1/32|1/16 triplet|1/16|1/8 triplet|1/8|1/4 triplet|1/4|1/2 triplet|1/2|Whole note|Two whole notes||Custom note length (beats)||Custom frequency (time)")
                  userNoteFound = false
                  userFreqFound = false
                  if quantmenuSel >= 2 and quantmenuSel <= #tableNoteRates then 
                      --local tableNoteRates = {nil, (1/64)*(2/3), (1/64), (1/32)*(2/3), (1/32), (1/16)*(2/3), (1/16), (1/8)*(2/3), (1/8), (1/4)*(2/3), (1/4), (1/2)*(2/3), (1/2), 1}
                      userNote = tableNoteRates[quantmenuSel]
                      userNoteFound = true
                  elseif quantmenuSel == #tableNoteRates + 1 then
                      repeat
                          retval, userNote = reaper.GetUserInputs("Set rate at all nodes", 1, "Periods per whole note", "")
                          userNote = tonumber(userNote)
                          if type(userNote) == "number" and userNote > 0 then -- >= beatBaseMin and userNote <= beatBaseMax  then 
                              userNoteFound = true 
                          end
                      until retval == false or userNoteFound == true
                  elseif quantmenuSel == #tableNoteRates + 2 then
                      repeat
                          retval, userFreq = reaper.GetUserInputs("Set rate at all nodes", 1, "Frequency in Hz"
                                                                                             --[[
                                                                                             .. " ("
                                                                                             .. tostring(timeBaseMin) 
                                                                                             .. "-" 
                                                                                             .. tostring(timeBaseMax)
                                                                                             .. ")"
                                                                                             ]]
                                                                                             , "")
                          userFreq = tonumber(userFreq)
                          if type(userFreq) == "number" and userFreq > 0 then -- >= timeBaseMin and userFreq <= timeBaseMax then 
                              userFreqFound = true 
                          end
                      until retval == false or userFreqFound == true
                  end
                    
                  if userNoteFound == true and tableGUIelements[GUIelement_TIMEBASE].value == 0 
                      and type(time_end) == "number" and type(time_start) == "number" and time_start<=time_end then
                      for i = 1, #tempcontrol.envelope do
                          local bpm = getBPM(time_start + tempcontrol.envelope[i][1]*(time_end-time_start))
                          local userFreq = (1.0/240) * userNote * bpm
                          tempcontrol.envelope[i][2] = math.min(1, math.max(0, ((1.0/(timeBaseMax - timeBaseMin)) * (userFreq-timeBaseMin))^(0.5)))
                      end
                      dogenerate = true
                  elseif userFreqFound == true and tableGUIelements[GUIelement_TIMEBASE].value == 0 then
                      local normalizedValue = ((1.0/(timeBaseMax - timeBaseMin)) * (userFreq-timeBaseMin))^(0.5)
                      for i = 1, #tempcontrol.envelope do
                          tempcontrol.envelope[i][2] = math.min(1, math.max(0, normalizedValue))
                      end
                      dogenerate = true
                  elseif userNoteFound == true and tableGUIelements[GUIelement_TIMEBASE].value == 1 then
                      local normalizedValue = ((1.0/(beatBaseMax - beatBaseMin)) * (userNote-beatBaseMin))^(0.5)
                      for i = 1, #tempcontrol.envelope do
                          tempcontrol.envelope[i][2] = math.min(1, math.max(0, normalizedValue))
                      end
                      dogenerate = true
                  elseif userFreqFound == true and tableGUIelements[GUIelement_TIMEBASE].value == 1 
                      and type(time_end) == "number" and type(time_start) == "number" and time_start<=time_end then
                      for i = 1, #tempcontrol.envelope do
                          local timeStartQN = reaper.TimeMap_timeToQN(time_start)
                          local timeEndQN = reaper.TimeMap_timeToQN(time_end)
                          local timeAtNode = reaper.TimeMap_QNToTime(timeStartQN + tempcontrol.envelope[i][1]*(timeEndQN-timeStartQN))
                          local bpm = getBPM(timeAtNode)
                          local userNote = (1.0/bpm) * 240.0 * userFreq
                          tempcontrol.envelope[i][2] = math.min(1, math.max(0, ((1.0/(beatBaseMax - beatBaseMin)) * (userNote-beatBaseMin))^(0.5)))
                      end
                      dogenerate = true
                  end 
                                          
              end -- if tempcontrol.name == "Rate" and gfx.mouse_cap==CTRLKEY+RIGHTBUTTON
              
              
              -- If Rate and right-click on hotpoint: Quantize period of hotpoint
              if tempcontrol.name == "Rate" and tempcontrol.hotpoint>0 and gfx.mouse_cap==RIGHTBUTTON then
                  gfx.x = gfx.mouse_x; gfx.y = gfx.mouse_y
                  local tableNoteRates = {nil, 32.0, 16.0*3.0/2.0, 16.0, 8.0*3.0/2.0, 8.0, 4.0*3.0/2.0, 4.0, 2.0*3.0/2.0, 2.0, 1.0, 0.5}                                            
                  quantmenuSel = gfx.showmenu("#Set rate at node to:|1/32|1/16 triplet|1/16|1/8 triplet|1/8|1/4 triplet|1/4|1/2 triplet|1/2|Whole note|Two whole notes||Custom note length (beats)||Custom frequency (time)")
                  userNoteFound = false
                  userFreqFound = false
                  if quantmenuSel >= 2 and quantmenuSel <= #tableNoteRates then 
                      --local tableNoteRates = {nil, (1/64)*(2/3), (1/64), (1/32)*(2/3), (1/32), (1/16)*(2/3), (1/16), (1/8)*(2/3), (1/8), (1/4)*(2/3), (1/4), (1/2)*(2/3), (1/2), 1}
                      userNote = tableNoteRates[quantmenuSel]
                      userNoteFound = true
                  elseif quantmenuSel == #tableNoteRates + 1 then
                      repeat
                          retval, userNote = reaper.GetUserInputs("Set rate at node", 1, "Periods per whole note", "")
                          userNote = tonumber(userNote)
                          if type(userNote) == "number" and userNote > 0 then -- >= beatBaseMin and userNote <= beatBaseMax  then 
                              userNoteFound = true 
                          end
                      until retval == false or userNoteFound == true
                  elseif quantmenuSel == #tableNoteRates + 2 then
                      repeat
                          retval, userFreq = reaper.GetUserInputs("Set rate at node", 1, "Frequency in Hz"
                                                                                      --[[
                                                                                      .. " ("
                                                                                      .. tostring(timeBaseMin) 
                                                                                      .. "-" 
                                                                                      .. tostring(timeBaseMax)
                                                                                      .. ")"
                                                                                      ]]
                                                                                      , "")
                          userFreq = tonumber(userFreq)
                          if type(userFreq) == "number" and userFreq > 0 then -- >= timeBaseMin and userFreq <= timeBaseMax then 
                              userFreqFound = true 
                          end
                      until retval == false or userFreqFound == true
                  end
                  
                  if userNoteFound == true and tableGUIelements[GUIelement_TIMEBASE].value == 0 
                      and type(time_end) == "number" and type(time_start) == "number" and time_start<=time_end then
                      local bpm = getBPM(time_start + tempcontrol.envelope[tempcontrol.hotpoint][1]*(time_end-time_start))
                      local userFreq = (1.0/240.0) * userNote * bpm
                      tempcontrol.envelope[tempcontrol.hotpoint][2] = math.min(1, math.max(0, ((1.0/(timeBaseMax - timeBaseMin)) * (userFreq-timeBaseMin))^(0.5)))
                      dogenerate = true                                            
                  elseif userFreqFound == true and tableGUIelements[GUIelement_TIMEBASE].value == 0 then
                      tempcontrol.envelope[tempcontrol.hotpoint][2] = math.min(1, math.max(0, ((1.0/(timeBaseMax - timeBaseMin)) * (userFreq-timeBaseMin))^(0.5)))
                      dogenerate = true
                  elseif userNoteFound == true and tableGUIelements[GUIelement_TIMEBASE].value == 1 then
                      tempcontrol.envelope[tempcontrol.hotpoint][2] = math.min(1, math.max(0, ((1.0/(beatBaseMax - beatBaseMin)) * (userNote-beatBaseMin))^(0.5)))
                      dogenerate = true
                  elseif userFreqFound == true and tableGUIelements[GUIelement_TIMEBASE].value == 1 
                      and type(time_end) == "number" and type(time_start) == "number" and time_start<=time_end then
                      local timeStartQN = reaper.TimeMap_timeToQN(time_start)
                      local timeEndQN = reaper.TimeMap_timeToQN(time_end)
                      local timeAtNode = reaper.TimeMap_QNToTime(timeStartQN + tempcontrol.envelope[tempcontrol.hotpoint][1]*(timeEndQN-timeStartQN))
                      local bpm = getBPM(timeAtNode)
                      local userNote = (1.0/bpm) * 240.0 * userFreq
                      tempcontrol.envelope[tempcontrol.hotpoint][2] = math.min(1, math.max(0, ((1.0/(beatBaseMax - beatBaseMin)) * (userNote-beatBaseMin))^(0.5)))
                      dogenerate = true
                  end              
              end -- if tempcontrol.name == "Rate" and tempcontrol.hotpoint>0 and gfx.mouse_cap==RIGHTBUTTON
              
              
              -- If Amplitude or Center and rightclick on hotpoint: Set to precise custom value
              if (tempcontrol.name == "Amplitude" or tempcontrol.name == "Center") 
                  and tempcontrol.hotpoint>0 
                  and gfx.mouse_cap==RIGHTBUTTON 
                  then
                  repeat
                          retval, userVal = reaper.GetUserInputs("Set node value", 1, "Node value (normalized)", "")
                          userVal = tonumber(userVal)
                  until retval == false or (retval == true and type(userVal)=="number" and userVal >= 0 and userVal <= 1)
                  
                  if retval == true then
                      tempcontrol.envelope[tempcontrol.hotpoint][2] = userVal
                      dogenerate = true
                  end 
              end
              
              
              -- If Amplitude or Center and Ctrl-rightclick: Set ALL nodes to precise custom value
              if (tempcontrol.name == "Amplitude" or tempcontrol.name == "Center") 
                  and gfx.mouse_cap==CTRLKEY+RIGHTBUTTON 
                  then
                  repeat
                          retval, userVal = reaper.GetUserInputs("Set value of all nodes", 1, "Node value (normalized)", "")
                          userVal = tonumber(userVal)
                  until retval == false or (retval == true and type(userVal)=="number" and userVal >= 0 and userVal <= 1)
                  
                  if retval == true then                  
                      for i = 1, #tempcontrol.envelope do
                          tempcontrol.envelope[i][2] = math.min(1, math.max(0, userVal))
                      end                 
                      dogenerate = true        
                  end
              end              
                            
          end -- if tempcontrol.type=="Envelope"
                  
      end -- if is_in_rect
      
      local env_enabled=false
      if captured_control~=nil then
          if captured_control.OnMouse~=nil then 
              --captured_control.OnMouse(captured_control, "drag", gfx.mouse_x,gfx.mouse_y, nil)
          end
          if captured_control.type=="Slider" then
              if captured_control.envelope==tableGUIelements[GUIelement_ENV].envelope then 
                   env_enabled=captured_control.env_enabled
              end
              local new_value=1.0/captured_control.w()*(gfx.mouse_x-captured_control.x())
              new_value=bound_value(0.0,new_value,1.0)
              --reaper.ShowConsoleMsg(captured_control.type .. " ")
              if captured_control.value~=new_value then
                  dogenerate=true
                  captured_control.value=new_value
              end
          end
      end -- if captured_control~=nil
      
      drawGUIobject(tempcontrol)
      draw_envelope(tempcontrol,env_enabled)
    end -- for key,tempcontrol in pairs(tableGUIelements)
  
    ---------------------------------------------
    -- If right-click, show save/load/delete menu
    -- (But not if in envelope drawing area)
    if (gfx.mouse_cap == RIGHTBUTTON 
        and not is_in_rect(gfx.mouse_x,
                           gfx.mouse_y,
                           0, --tableGUIelements[100].x(),
                           tableGUIelements[GUIelement_ENV].y(),
                           gfx.w, --tableGUIelements[100].w(),
                           gfx.h - tableGUIelements[GUIelement_ENV].y()) --tableGUIelements[100].h()) 
       )
    -- Left-click on menu button bottom left !!!!!New in 2.20
    or (gfx.mouse_cap == LEFTBUTTON
        and gfx.mouse_x < 22 
        and gfx.mouse_y > gfx.h-22
        and firstClick == true
       ) 
        
        then
        firstClick = false
        
        --reaper.DeleteExtState("LFO generator", "savedCurves", true) -- delete the ExtState

        -------------------------------
        -- First, try to load all saved curves
        getSavedCurvesAndNames()
        
        local gotSavedNames
        loadStr = ""
        if savedNames ~= nil and type(savedNames) == "table" and #savedNames > 0 then
  
            gotSavedNames = true
            loadStr = ">Load curve"
            for i = 1, #savedNames do
                loadStr = loadStr .. "|" .. savedNames[i]
            end
            
            loadStr = loadStr .. "|<|>Delete curve"
            for i = 1, #savedNames do
                loadStr = loadStr .. "|" .. savedNames[i] 
            end
            loadStr = loadStr .. "|<|"           
        else
            gotSavedNames = false
            loadStr = "#Load curve|#Delete curve|"
        end
        
        saveLoadString = "Save curve|" .. loadStr .. "Reset curve"
        
        --!!!!!!!New in 2.20
        if skipRedundantCCs then
            saveLoadString = saveLoadString .. "||!Skip redundant CCs"
        else
            saveLoadString = saveLoadString .. "||Skip redundant CCs"
        end
        
        
        ----------------------------------------
        -- Show save/load/delete menu
        gfx.x = gfx.mouse_x; gfx.y = gfx.mouse_y
        menuSel = gfx.showmenu(saveLoadString)
        
        if menuSel == 0 then  
            -- do nothing
            
        --!!!!!!!!!!New in 2.20
        -- Toggle skipRedundantCCs
        elseif (gotSavedNames == true and menuSel == 3 + 2*#savedNames)
            or (gotSavedNames == false and menuSel == 5)
            then
            skipRedundantCCs = not skipRedundantCCs
            reaper.SetExtState("LFO generator", "skipRedundantCCs", tostring(skipRedundantCCs), true)
            updateEventValuesAndUploadIntoTake()
            
        --------------   
        -- Reset curve
        elseif (gotSavedNames == true and menuSel == 2 + 2*#savedNames)
            or (gotSavedNames == false and menuSel == 4)
            then
            tableGUIelements[GUIelement_RATE].envelope = {{0,0.5}, {1,0.5}}
            tableGUIelements[GUIelement_AMPLITUDE].envelope = {{0,0.5}, {1,0.5}}
            tableGUIelements[GUIelement_CENTER].envelope = {{0,0.5}, {1,0.5}}
            dogenerate = true
            
            -------------------------------------------------------
            -- Draw the newly loaded envelope
            if tableGUIelements[GUIelement_ENV].name == tableGUIelements[1].name then -- "Rate"
                tableGUIelements[GUIelement_ENV]=make_envelope(borderWidth, envYpos, 0, envHeight, tableGUIelements[GUIelement_RATE])
            elseif tableGUIelements[GUIelement_ENV].name == tableGUIelements[2].name then -- "Amplitude"
                tableGUIelements[GUIelement_ENV]=make_envelope(borderWidth, envYpos, 0, envHeight, tableGUIelements[GUIelement_AMPLITUDE])
            else -- "Center"
                tableGUIelements[GUIelement_ENV]=make_envelope(borderWidth, envYpos, 0, envHeight, tableGUIelements[GUIelement_CENTER])
            end
            
        ------------------------
        -- Save curve
        elseif menuSel == 1 then
            repeat
                retval, curveName = reaper.GetUserInputs("Save curve", 1, "Curve name (no | or ,)", "")
            until retval == false or (curveName:find("|") == nil and curveName:find(",") == nil and curveName:len()>0)
            
            if retval ~= false then
                saveString = curveName
                for i = 0, #tableGUIelements do
                    if tableGUIelements[i] == nil then -- skip
                    elseif tableGUIelements[i].name == "LFO shape?" then saveString = saveString .. ",LFO shape?," .. tostring(shapeSelected)
                    --elseif tableGUIelements[i].name == "Real-time copy to CC?" then saveString = saveString .. ",Real-time copy to CC?," .. tostring(tableGUIelements[i].enabled) 
                    elseif tableGUIelements[i].name == "Phase step" then saveString = saveString .. ",Phase step," .. tostring(tableGUIelements[i].value)
                    elseif tableGUIelements[i].name == "Randomness" then saveString = saveString .. ",Randomness," .. tostring(tableGUIelements[i].value)
                    elseif tableGUIelements[i].name == "Quant steps" then saveString = saveString .. ",Quant steps," .. tostring(tableGUIelements[i].value)
                    elseif tableGUIelements[i].name == "Bezier shape" or tableGUIelements[i].name == "Smoothing" then saveString = saveString .. ",Bezier shape," .. tostring(tableGUIelements[i].value)
                    elseif tableGUIelements[i].name == "Fade in duration" then saveString = saveString .. ",Fade in duration," .. tostring(tableGUIelements[i].value)
                    elseif tableGUIelements[i].name == "Fade out duration" then saveString = saveString .. ",Fade out duration," .. tostring(tableGUIelements[i].value)
                    elseif tableGUIelements[i].name == "Timebase?" then saveString = saveString .. ",Timebase?," .. tostring(tableGUIelements[i].value)
                    elseif tableGUIelements[i].name == "Rate" then 
                        saveString = saveString .. ",Rate,"  .. tostring(#tableGUIelements[i].envelope)
                        for p = 1, #tableGUIelements[i].envelope do
                            saveString = saveString .. "," .. tostring(tableGUIelements[i].envelope[p][1]) .. "," 
                                                           .. tostring(tableGUIelements[i].envelope[p][2])
                        end
                    elseif tableGUIelements[i].name == "Center" then 
                        saveString = saveString .. ",Center,"  .. tostring(#tableGUIelements[i].envelope)
                        for p = 1, #tableGUIelements[i].envelope do
                            saveString = saveString .. "," .. tostring(tableGUIelements[i].envelope[p][1]) .. "," 
                                                           .. tostring(tableGUIelements[i].envelope[p][2])
                        end
                    elseif tableGUIelements[i].name == "Amplitude" then 
                        saveString = saveString .. ",Amplitude,"  .. tostring(#tableGUIelements[i].envelope)
                        for p = 1, #tableGUIelements[i].envelope do
                            saveString = saveString .. "," .. tostring(tableGUIelements[i].envelope[p][1]) .. "," 
                                                           .. tostring(tableGUIelements[i].envelope[p][2])
                        end
                    end
                end -- for i = 0, 11
                
                if reaper.HasExtState("LFO generator", "savedCurves") then
                    reaper.SetExtState("LFO generator", "savedCurves", saveString .. "|" .. reaper.GetExtState("LFO generator", "savedCurves"), true)
                else
                    reaper.SetExtState("LFO generator", "savedCurves", saveString .. "|", true)
                end
                
                
            end -- if retval ~= false
    
        elseif savedNames ~= nil and type(savedNames) == "table" and #savedNames > 0 then
            -----------------------------------
            -- delete curve
            if 1+#savedNames < menuSel then 
            
                --retval, curveName = reaper.GetUserInputs("Delete curve", 1, "Curve name", "")
                extStateString = ""
                for i = 1, #savedCurves do
                    if i ~= menuSel - (#savedNames+1) then
                        extStateString = savedCurves[i] .. "|" .. extStateString
                    end
                end
                if extStateString == "" then 
                    reaper.DeleteExtState("LFO generator", "savedCurves", true)
                else
                    reaper.SetExtState("LFO generator", "savedCurves", extStateString, true)
                end
                
            ---------------------------------------------------
            -- load curve 
            elseif 1 < menuSel and menuSel <= 1+#savedNames then 
            
                if savedNames ~= nil and type(savedNames) == "table" and #savedNames > 0 then
                    loadCurve(menuSel-1)
                    dogenerate = true
                end
            end    
            
        end -- if menuSel == ...  
    
    end -- if gfx.mouse_cap == 2
    
    
    if dogenerate==true then
        callGenerateNodesThenUpdateEvents()      
    end -- if dogenerate==true
    
    last_mouse_cap=gfx.mouse_cap
    gfx.update()
    reaper.defer(loop_GetInputsAndUpdate)
end 


--------------------------------

function callGenerateNodesThenUpdateEvents()
     generateNodes() 
     was_changed=true
    
     -- Draw the envelope in CC lane
     updateEventValuesAndUploadIntoTake()
end


------------------------------------------------------------
-- NOTE: This function requires all the tables to be sorted!
function updateEventValuesAndUploadIntoTake() 

    local i = 1 -- index in tSel
    local prevValues = {} -- store previous values for each channel, for skipRedundantCCs
    
    -- The smoothing function depends on values of nodes before and after the current two, 
    --    so add two artificial 'nodes' to tableNodes:
    local numNodesMinus1 = #tableNodes-1
    tableNodes[0] = {value = tableNodes[1].value, PPQ = tableNodes[1].PPQ-1, shape = 0}
    tableNodes[#tableNodes+1] = {value = tableNodes[#tableNodes].value, PPQ = tableNodes[#tableNodes].PPQ + 1}
    
    -- Morphing can only be done when Morph slider is available 
    local morph = GUIelement_MORPH and tableGUIelements[GUIelement_MORPH].value or 1
    local laneAvgValue = (laneMaxValue+laneMinValue)/2
    
    local smooth = GUIelement_SMOOTH and tableGUIelements[GUIelement_SMOOTH].value or 0
    
    -- Iterate through all the nodes
    for n = 1, numNodesMinus1 do
    
        local prevNodeValue = tableNodes[n].value
        local nextNodeValue = tableNodes[n+1].value
        local prevPrevNodeValue = tableNodes[n-1].value
        local nextNextNodeValue = tableNodes[n+2].value        
        local maxNodeValue, minNodeValue
        
        local prevNodePPQ = tableNodes[n].PPQ
        local nextNodePPQ = tableNodes[n+1].PPQ
        local prevPrevNodePPQ = tableNodes[n-1].PPQ
        local nextNextNodePPQ = tableNodes[n+2].PPQ

        -- These values will be used if smoothing needs to be done
        -- For smoothing sqaure nodes, the corners will be converted to ovals with radii
        --    determined by the Smoothing slider.  
        -- The X radius (i.e. PPQ) will range between 0 and half the distance between the nodes PPQ positions.
        -- Similarly, the Y radii (i.e. CC values) will range between 0 and half the difference in values of the nodes.
        -- (The Y radii at prevNode and nextNode may therefore differ.)
        --    squareSmoothLeftPPQ = prevNodePPQ + squareSmoothRadiusX and
        --    squareSmoothRightPPQ = nextNodePPQ - squareSmoothRadiusX are simply the cutoff PPQ positions between which event values will not be affected.
        local midPointPPQ, squareSmoothLeftPPQ, squareSmoothRightPPQ, squareSmoothRadiusX, squareSmoothRadiusYleft, squareSmoothRadiusYright
        local slopeBetweenNodesCurrent, slopeBetweenNodesPrev, slopeBetweenNodesNext 
            
        -- In case smoothing is applied, do some pre-calculations of slopes
        -- (Do this for each node, not each CC, to save time)
        --
        -- How does the smoothing work?  At each node, if the preceding and next inter-node slopes have different signs, 
        --    it tries to approximate a slope of 0 at that node.
        -- If the preceding and next inter-node slopes have the same sign, it tries to approximate the slope with the lowest absolute value.
        -- Square shapes have idiosyncratic issues.
        local mustSmooth = false -- Only do smoothing if necessary
        if smooth ~= 0 -- Slider value = 0 implies no smoothing
        and nextNodePPQ - prevNodePPQ > 2 -- If nodes are too close, too few CCs in-between to smooth, and avoid divide-by-zero
        and prevNodeValue ~= nextNodeValue -- Unlike REAPER's Bézier curves, the LFO Tool will not shift CC values beyond node boundaries, so not smoothing will be applied if node values are equal.
        then
        
            mustSmooth = true
            
            -- min and max node values will be used to prevent inadvertent (aka buggy) changes in CC values beyond node boundaries.
            if prevNodeValue > nextNodeValue then maxNodeValue, minNodeValue = prevNodeValue, nextNodeValue
            else maxNodeValue, minNodeValue = nextNodeValue, prevNodeValue 
            end
                        
            -- Square shapes have idiosyncratic issues.
            if tableNodes[n].shape == 1 then -- square
                slopeBetweenNodesCurrent = 0
                squareSmoothRadiusX = (nextNodePPQ - prevNodePPQ)*0.5*smooth
                squareSmoothRadiusYleft  = math.abs((prevNodeValue - prevPrevNodeValue)*0.5*smooth)
                squareSmoothRadiusYright = math.abs((prevNodeValue - nextNodeValue)*0.5*smooth)
                squareSmoothLeftPPQ  = prevNodePPQ + squareSmoothRadiusX
                squareSmoothRightPPQ = nextNodePPQ - squareSmoothRadiusX
            else
                slopeBetweenNodesCurrent = (nextNodeValue - prevNodeValue) / math.max(1, (nextNodePPQ - prevNodePPQ))
                midPointPPQ = (nextNodePPQ + prevNodePPQ)*0.5
            end
            
            if tableNodes[n-1].shape == 1 then -- square
                slopeBetweenNodesPrev = (prevNodeValue - prevPrevNodeValue) -- Simulate steep slope, but with correct sign
            else
                slopeBetweenNodesPrev = (prevNodeValue - prevPrevNodeValue) / math.max(1, (prevNodePPQ - prevPrevNodePPQ))
            end
            
            if tableNodes[n+1].shape == 1 then -- square
                slopeBetweenNodesNext = 0
            else
                slopeBetweenNodesNext = (nextNextNodeValue - nextNodeValue) / math.max(1, (nextNextNodePPQ - nextNodePPQ))
            end
            
            -- If the preceding and next inter-node slopes have the same sign, it tries to approximate the slope with the lowest absolute value.
            if (slopeBetweenNodesPrev >= 0 and slopeBetweenNodesCurrent <= 0) 
            or (slopeBetweenNodesPrev <= 0 and slopeBetweenNodesCurrent >= 0) 
            then
                slopeAtNodeN = 0
            elseif math.abs(slopeBetweenNodesPrev) < math.abs(slopeBetweenNodesCurrent) then
                slopeAtNodeN = slopeBetweenNodesPrev
            else
                slopeAtNodeN = slopeBetweenNodesCurrent
            end
            
            if (slopeBetweenNodesNext >= 0 and slopeBetweenNodesCurrent <= 0) 
            or (slopeBetweenNodesNext <= 0 and slopeBetweenNodesCurrent >= 0) 
            then
                slopeAtNodeNplus1 = 0
            elseif math.abs(slopeBetweenNodesNext) < math.abs(slopeBetweenNodesCurrent) then
                slopeAtNodeNplus1 = slopeBetweenNodesNext
            else
                slopeAtNodeNplus1 = slopeBetweenNodesCurrent
            end
        end -- if tableGUIelements[GUIelement_SMOOTH].value ~= 0     
        
        
        -- Now start iterating through the CCs
        while i <= #tSel and tSel[i].ticks < nextNodePPQ do
            --local newValue
            local evTicks = tSel[i].ticks
            if evTicks >= prevNodePPQ then -- and evTicks < nextNodePPQ then
            
                -- Determine event values, based on node point shape
                if tableNodes[n].shape == 0 then -- Linear
                    newValue = prevNodeValue + ((evTicks - prevNodePPQ)/(nextNodePPQ - prevNodePPQ))*(nextNodeValue - prevNodeValue)
                elseif tableNodes[n].shape == 1 then -- Square
                    newValue = prevNodeValue
                elseif tableNodes[n].shape >= 2 and tableNodes[n].shape < 3 then -- Sine
                    local piMin = (tableNodes[n].shape - 2)*m_pi
                    local piRefVal = m_cos(piMin)+1
                    local piFrac  = piMin + (evTicks-prevNodePPQ)/(nextNodePPQ-prevNodePPQ)*(m_pi - piMin)
                    local cosFrac = 1-(m_cos(piFrac)+1)/piRefVal
                    newValue = prevNodeValue + cosFrac*(nextNodeValue-prevNodeValue)
                elseif tableNodes[n].shape >= 3 and tableNodes[n].shape < 4 then -- Inverse parabolic
                    local minVal = 1 - (tableNodes[n].shape - 4)
                    local fracVal = minVal*(evTicks-nextNodePPQ)/(prevNodePPQ-nextNodePPQ)
                    local refVal = minVal^3
                    local normFrac = (fracVal^3)/refVal
                    newValue = nextNodeValue + normFrac*(prevNodeValue - nextNodeValue)            
                elseif tableNodes[n].shape >= 4 and tableNodes[n].shape < 5 then -- Parabolic
                    local minVal = tableNodes[n].shape - 4
                    local fracVal = minVal + (evTicks-prevNodePPQ)/(nextNodePPQ-prevNodePPQ)*(1 - minVal)
                    local refVal = 1 - minVal^3
                    local normFrac = 1 - (1-fracVal^3)/refVal
                    newValue = prevNodeValue + normFrac*(nextNodeValue - prevNodeValue)
                else -- if tableNodes[n].shape == 5 then -- Bézier
                    newValue = prevNodeValue
                end                
                
                
                -- Apply slider: Bézier-like smoothing
                if mustSmooth then          
                    
                    -- For smoothing sqaure nodes, the corners will be converted to ovals with radii
                    --    determined by the Smoothing slider.
                    if tableNodes[n].shape == 1 then
                        -- Smoothing only needs to be applied at left node if previous node shape is NOT square
                        if evTicks < squareSmoothLeftPPQ and tableNodes[n-1].shape == 1 then
                            local radicand = (   1 - ((evTicks - squareSmoothLeftPPQ)/squareSmoothRadiusX)^2  ) * (squareSmoothRadiusYleft^2)
                            if radicand < 0 then radicand = 0 end
                            local y = radicand^0.5
                            if prevPrevNodeValue < prevNodeValue then
                                newValue = newValue - squareSmoothRadiusYleft + y
                            else
                                newValue = newValue + squareSmoothRadiusYleft - y
                            end
                        elseif evTicks > squareSmoothRightPPQ then
                            local radicand = (   1 - ((evTicks - squareSmoothRightPPQ)/squareSmoothRadiusX)^2  ) * (squareSmoothRadiusYright^2)
                            if radicand < 0 then radicand = 0 end
                            local y = radicand^0.5
                            if nextNodeValue < prevNodeValue then
                                newValue = newValue - squareSmoothRadiusYright + y
                            else
                                newValue = newValue + squareSmoothRadiusYright - y
                            end
                        end
                        
                    -- For other node shapes, smoothing involves calculating a linear 'target' slope at the node,
                    --    and shifting event values on both sides of the node towards this slope, until
                    --    events on both sides of the node have the same slope.
                    else
                        local linearTargetValue, distanceWeightedTargetValue
                        -- CCs closer to node[n] are adjusted by preceding node[n-1], whereas CCs closer to node[n+1] are adjusted by node[n+2]
                        -- CCs closer to node[n]:
                        if evTicks < (prevNodePPQ + nextNodePPQ)/2 then 
                            linearTargetValue = prevNodeValue + slopeAtNodeN * (evTicks - prevNodePPQ)
                            -- To get a smooth Bézier-like curve, CCs closer to the nodes must be more strongly affected by the smoothing.
                            -- CCs precisely at the midpoint between nodes will not be affected.
                            -- Possible formulas to use?  Can try quadratic etc.
                            -- distanceWeightedTargetValue = newValue + (1 - (tablePPQs[i] - prevNodePPQ) / ((nextNodePPQ - prevNodePPQ)/2))^2 * (linearTargetValue - newValue)
                            distanceWeightedTargetValue = linearTargetValue + ((evTicks - prevNodePPQ) / ((nextNodePPQ - prevNodePPQ)/2)) * (newValue - linearTargetValue)                        
    
                        -- CCs closer to node[n+1]:
                        else
                            linearTargetValue = nextNodeValue + slopeAtNodeNplus1 * (evTicks - nextNodePPQ)
                            distanceWeightedTargetValue = linearTargetValue + ((nextNodePPQ - evTicks) / ((nextNodePPQ - prevNodePPQ)/2)) * (newValue - linearTargetValue)                        
                        end
                        
                        newValue = newValue + tableGUIelements[GUIelement_SMOOTH].value * (distanceWeightedTargetValue - newValue)
                    end -- if tableNodes[n].shape == 1
                    
                    if newValue > maxNodeValue then newValue = maxNodeValue
                    elseif newValue < minNodeValue then newValue = minNodeValue 
                    end
                end -- if mustSmooth
                
                
                -- Apply slider: quantization
                if tableGUIelements[GUIelement_QUANTSTEPS].value ~= 1 then
                    local numQuantSteps = 3 + math.ceil(125*tableGUIelements[GUIelement_QUANTSTEPS].value)
                    local quantStepSize = m_floor(0.5 + (laneMaxValue-laneMinValue)/numQuantSteps)
                    newValue = quantStepSize * m_floor(0.5 + newValue/quantStepSize)
                end
                
                
                -- Morph
                if morph ~= 1 then
                    --[[if morph < 0.5 then
                        newValue = (2*morph*(newValue-laneAvgValue)) + tSel[i].val
                    else
                        newValue = 2*(1-morph)*((newValue-laneAvgValue) + tSel[i].val) + 2*(morph-0.5)*newValue
                    end]]
                    if morph < 0.5 then
                        newValue = (1 - 2*morph) * (newValue-laneAvgValue) + tSel[i].val
                    else
                        newValue = (1 - 2*(morph-0.5))*tSel[i].val + 2*(morph-0.5)*newValue
                    end
                    
                end
                
                
                -- Ensure that values do not exceed bounds of CC lane
                if newValue < laneMinValue then newValue = laneMinValue
                elseif newValue > laneMaxValue then newValue = laneMaxValue
                else newValue = m_floor(newValue+0.5)
                end
                
                
                -- Insert the MIDI events into REAPER's MIDI stream
                --!!!!!!!!New in 2.20: skipRedundantCCs
                local channel = tSel[i].chan 
                
                if laneIsVELOCITY then --skipRedundantCCs is only applied to CCs, not note velocities
                    tMIDI[tSel[i].index] = s_pack("I4BBB", 3, 0x90 | channel, tSel[i].pitch, newValue)                  
                elseif skipRedundantCCs and newValue == prevValues[channel] then
                    if laneIsCC14BIT then
                        tMIDI[tSel[i].indexMSB] = EMPTY_EVENT_MSG
                        tMIDI[tSel[i].indexLSB] = EMPTY_EVENT_MSG
                    else
                        tMIDI[tSel[i].index] = EMPTY_EVENT_MSG
                    end
                elseif laneIsCC7BIT then
                    tMIDI[tSel[i].index] = s_pack("I4BBB", 3, 0xB0 | channel, targetLane, newValue)
                elseif laneIsPITCH then
                    tMIDI[tSel[i].index] = s_pack("I4BBB", 3, 0xE0 | channel, newValue&127, newValue>>7)
                elseif laneIsCC14BIT then
                    tMIDI[tSel[i].indexMSB] = s_pack("I4BBB", 3, 0xB0 | channel, targetLane-256, newValue>>7)
                    tMIDI[tSel[i].indexLSB] = s_pack("I4BBB", 3, 0xB0 | channel, targetLane-224, newValue&127)
                elseif laneIsCHPRESS then
                    tMIDI[tSel[i].index] = s_pack("I4BB", 2, 0xD0 | channel, newValue) -- NB Channel Pressure uses only 2 bytes!
                elseif laneIsPROGRAM then
                    tMIDI[tSel[i].index] = s_pack("I4BB", 2, 0xC0 | channel, newValue) -- NB Channel Pressure uses only 2 bytes!
                end -- if laneIsCC7BIT / laneIsCC14BIT / ...
                    
                prevValues[channel] = newValue
        
                i = i + 1
            end -- if tablePPQs[i] >= prevNodePPQ and tablePPQs[i] < nextNodePPQ then
        end -- while i <= #tablePPQs and tablePPQs[i] < nextNodePPQ do       
    end -- for n = 1, #tableNodes-1 do
    
    -----------------------------------------------------------
    -- DRUMROLL... write the edited events into the MIDI chunk!
    -- This also updates the offset of the first event in editMIDI relative to the PPQ position of the last event in tableEditedMIDI
    reaper.MIDI_SetAllEvts(take, table.concat(tMIDI))
    
    if isInline then reaper.UpdateArrange() end

end -- function updateEventValuesAndUploadIntoTake()


-----------------------------------
function setup_parseNotesToRanges()

    local tableNoteOns = {}
    for flags = 0, 3 do
        tableNoteOns[flags] = {}
        for chan = 0, 15 do
            tableNoteOns[flags][chan] = {}
        end
    end
    local stringPos = 1
    local runningPPQpos = 0
    local offset, flags, msg, msg1, eventType, channel, pitch, startTick
    while stringPos < #origMIDI do
        offset, flags, msg, stringPos = s_unpack("i4Bs4", origMIDI, stringPos)
        runningPPQpos = runningPPQpos + offset
        if flags&1==1 and msg:len() == 3 then
            eventType = msg:byte(1)>>4
            channel   = msg:byte(1)&0x0F
            if eventType == 9 and msg:byte(3) ~= 0 then -- Note-ons
                tableNoteOns[flags][channel][msg:byte(2)] = runningPPQpos
            elseif eventType == 8 or eventType == 9 then -- Note-offs
                pitch = msg:byte(2)
                startTick = tableNoteOns[flags][channel][pitch]
                if startTick and startTick < runningPPQpos then
                    --deleteCCs(tableNoteOns[flags][channel][pitch], runningPPQpos, channel)
                    --insertNewCCs(tableNoteOns[flags][channel][pitch], runningPPQpos, channel)
                    tRanges[#tRanges+1] = {channel = channel, startTick = startTick, endTick = runningPPQpos}
                    tableNoteOns[flags][channel][pitch] = nil
                end
            end
        end
    end                     
end


--------------------------
function getSavedCurvesAndNames()
    savedCurves = nil
    savedCurves = {}
    savedNames = nil
    savedNames = {}
        
    if reaper.HasExtState("LFO generator", "savedCurves") then
        extStateString = reaper.GetExtState("LFO generator", "savedCurves")
        savedCurves = nil
        savedCurves = {}
        prevSeparator = 0
        repeat
            nextSeparator = extStateString:find("|", prevSeparator+1)
            if nextSeparator ~= nil then
                table.insert(savedCurves, extStateString:sub(prevSeparator+1, nextSeparator-1))
                --reaper.ShowConsoleMsg(savedCurves[#savedCurves] .. "\n\n")
            end
            prevSeparator = nextSeparator
        until nextSeparator == nil
        
        for i = 1, #savedCurves do
            firstComma = savedCurves[i]:find(",")
            if firstComma ~= nil then
                table.insert(savedNames, savedCurves[i]:sub(1, firstComma-1))
            end
        end
        
        if #savedNames == 0 or #savedNames ~= #savedCurves then
            reaper.ShowMessageBox("\n\nThe saved curves appear to have been corrupted."
                                  .. "\n\nThe saved curves can be edited (and perhaps recovered) manually, or they can all be deleted by running the following command in a script:"
                                  .. "\nreaper.DeleteExtState(\"LFO generator\", \"savedCurves\", true)"
                                  , "ERROR", 0)
            savedCurves = nil
            savedNames = nil
            return(false)
        end
    else
        return(false)
    end
                
end -- function getSavedCurvesAndNames()

-----------------------------------

function loadCurve(curveNum)

    if savedCurves ~= nil and #savedCurves ~= nil and #savedCurves >= curveNum and curveNum >= 0 then
    
        savedString = savedCurves[curveNum]
                
        prevComma = 0
        function nextStr()
            nextComma = savedString:find(",", prevComma+1)
            if nextComma == nil then substring = savedString:sub(prevComma+1)
            else substring = savedString:sub(prevComma+1,nextComma-1)
                prevComma = nextComma
            end
            --reaper.ShowConsoleMsg(substring .. "\n")
            return(substring)
        end
        
        curveName = nextStr()
        -- For compatibility with previous version that only has timebase=time, timebase is set to 0 by default
        tableGUIelements[GUIelement_TIMEBASE].value = 0
        
        for i = 0, 11 do
            --reaper.ShowConsoleMsg("\nsliderName = ")
            sliderName = nextStr()
            if sliderName  == "LFO shape?" then shapeSelected = tonumber(nextStr())
            --[[elseif sliderName == "Real-time copy to CC?" then 
                if nextStr() == "true" then
                    tableGUIelements[GUIelement_copyCC].enabled = true
                else
                    tableGUIelements[GUIelement_copyCC].enabled = false
                end]]
            elseif sliderName == "Phase step" then tableGUIelements[GUIelement_PHASE].value = tonumber(nextStr())
            elseif sliderName == "Randomness" then tableGUIelements[GUIelement_RANDOMNESS].value = tonumber(nextStr())
            elseif sliderName == "Quant steps" then tableGUIelements[GUIelement_QUANTSTEPS].value = tonumber(nextStr())
            elseif sliderName == "Bezier shape" or sliderName == "Smoothing" then tableGUIelements[GUIelement_SMOOTH].value = tonumber(nextStr()) -- include shape for compatibility with previous versions
            elseif sliderName == "Fade in duration" then tableGUIelements[GUIelement_FADEIN].value = tonumber(nextStr())
            elseif sliderName == "Fade out duration" then tableGUIelements[GUIelement_FADEOUT].value = tonumber(nextStr())
            elseif sliderName == "Timebase?" then tableGUIelements[GUIelement_TIMEBASE].value = tonumber(nextStr())
            elseif sliderName == "Rate" then 
                tableGUIelements[GUIelement_RATE].envelope = nil
                tableGUIelements[GUIelement_RATE].envelope = {}
                for p = 1, tonumber(nextStr()) do
                    tableGUIelements[GUIelement_RATE].envelope[p] = {tonumber(nextStr()), tonumber(nextStr())}
                end
            elseif sliderName == "Center" then 
                tableGUIelements[GUIelement_CENTER].envelope = nil
                tableGUIelements[GUIelement_CENTER].envelope = {}
                for p = 1, tonumber(nextStr()) do
                    tableGUIelements[GUIelement_CENTER].envelope[p] = {tonumber(nextStr()), tonumber(nextStr())}
                end
            elseif sliderName == "Amplitude" then 
                tableGUIelements[GUIelement_AMPLITUDE].envelope = nil
                tableGUIelements[GUIelement_AMPLITUDE].envelope = {}
                for p = 1, tonumber(nextStr()) do
                    tableGUIelements[GUIelement_AMPLITUDE].envelope[p] = {tonumber(nextStr()), tonumber(nextStr())}
                end
            end
        end -- for i = 0, 11 
        
        -------------------------------------------------------
        -- Draw the newly loaded envelope
        if tableGUIelements[100].name == tableGUIelements[1].name then -- "Rate"
            tableGUIelements[100]=make_envelope(borderWidth, envYpos, 0, envHeight, tableGUIelements[GUIelement_RATE])
        elseif tableGUIelements[100].name == tableGUIelements[2].name then -- "Amplitude"
            tableGUIelements[100]=make_envelope(borderWidth, envYpos, 0, envHeight, tableGUIelements[GUIelement_AMPLITUDE])
        else -- "Center"
            tableGUIelements[100]=make_envelope(borderWidth, envYpos, 0, envHeight, tableGUIelements[GUIelement_CENTER])
        end
        
        generateNodes()
        was_changed=true
                              
        -- Draw the envelope in CC lane
        updateEventValuesAndUploadIntoTake()
        
    end -- savedCurves ~= nil and #savedCurves ~= nil and

end -- loadCurve()

  
---------------------------------------------
function constructNewGUI()

    gfx.quit()
    -- The GUI window will be opened at the last-used coordinates
    local coordinatesExtState = reaper.GetExtState("LFO generator", "Last coordinates") -- Returns an empty string if the ExtState does not exist
    xPos, yPos = coordinatesExtState:match("(%d+),(%d+)") -- Will be nil if cannot match
    if xPos and yPos then
        gfx.init("LFO: ".. targetLaneString, initXsize, initYsize, 0, tonumber(xPos), tonumber(yPos)) -- Interesting, this function can accept xPos and yPos strings, without tonumber
    else
        gfx.init("LFO: ".. targetLaneString, initXsize, initYsize, 0)
    end
    gfx.setfont(1,"Ariel", 15)
    
    tableGUIelements[1]=make_radiobutton(borderWidth,borderWidth,0,0,0.5,"Rate", function(nx) end)
    GUIelement_RATE = 1
    tableGUIelements[2]=make_radiobutton(borderWidth,borderWidth+GUIelementHeight*#tableGUIelements,0,0,0.5,"Amplitude",function(nx) end)
    GUIelement_AMPLITUDE = 2
    tableGUIelements[3]=make_radiobutton(borderWidth,borderWidth+GUIelementHeight*#tableGUIelements,0,0,0.5,"Center",function(nx) end)
    GUIelement_CENTER = 3
    tableGUIelements[4]=make_question(borderWidth,borderWidth+GUIelementHeight*#tableGUIelements,0,0,0.0,"Timebase?",function(nx) end, "Beats", "Time")
    GUIelement_TIMEBASE = 4
    tableGUIelements[5]=make_menubutton(borderWidth,borderWidth+GUIelementHeight*#tableGUIelements,0,0,0.0,"LFO shape?",function(nx) end)
    GUIelement_SHAPE = 5
    --tableGUIelements[11]=make_question(borderWidth,borderWidth+GUIelementHeight*5,0,0,0.0,"Real-time copy to CC?",function(nx) end, "Enabled", "Disabled")
    --GUIelement_copyCC = 11
    -- The following slider was originally named "Phase"
    tableGUIelements[6]=make_slider(borderWidth,borderWidth+GUIelementHeight*#tableGUIelements,0,0,0.0,"Phase step",function(nx) end)
    GUIelement_PHASE = 6
    tableGUIelements[7]=make_slider(borderWidth,borderWidth+GUIelementHeight*#tableGUIelements,0,0,0.0,"Randomness",function(nx) end)
    GUIelement_RANDOMNESS = 7
    tableGUIelements[8]=make_slider(borderWidth,borderWidth+GUIelementHeight*#tableGUIelements,0,0,1.0,"Quant steps",function(nx) end)
    GUIelement_QUANTSTEPS = 8
    tableGUIelements[9]=make_slider(borderWidth,borderWidth+GUIelementHeight*#tableGUIelements,0,0,0.0,"Smoothing",function(nx) end)
    GUIelement_SMOOTH = 9 
    tableGUIelements[10]=make_slider(borderWidth,borderWidth+GUIelementHeight*#tableGUIelements,0,0,0.0,"Fade in duration",function(nx) end)
    GUIelement_FADEIN = 10
    -- make_slider(x,y,w,h,val,name,valcb)
    tableGUIelements[11]=make_slider(borderWidth,borderWidth+GUIelementHeight*#tableGUIelements,0,0,0.0,"Fade out duration",function(nx) end)
    GUIelement_FADEOUT = 11
    if selectionToUse == "existing" then
        tableGUIelements[12]=make_slider(borderWidth,borderWidth+GUIelementHeight*#tableGUIelements,0,0,1,"Morph",function(nx) end)
        GUIelement_MORPH = 12
    end
    -- make_envelope(x,y,w,h,assocslider)
    tableGUIelements[100]=make_envelope(borderWidth, borderWidth+GUIelementHeight*#tableGUIelements, 0, 0, tableGUIelements[1])
    --tableGUIelements[100]=make_envelope(borderWidth, borderWidth+GUIelementHeight*12, 0, envHeight,tableGUIelements[1]) --315-30
    GUIelement_ENV = 100
      
    --[[for key,tempcontrol in pairs(tableGUIelements) do
      reaper.ShowConsoleMsg(key.." "..tempcontrol.type.." "..tempcontrol.name.."\n")
    end]]
    
end -- constructNewGUI()

------------------------


--#####################################################################################
---------------------------------------------------------------------------------------
-- Parses editMIDI and separates selected target events into separate entries in tMIDI.
-- Indices of these target events (as well as other info) are stored in tSel.
function setup_findTargetEvents()
   
    local MIDI = editMIDI
    
    local t14 = {} -- Store index in tSel of 14bit event at chan and tick: t14[chan][tick]
        for chan = 0, 15 do t14[chan] = {} end
    
    local pos, prevPos = 1, 1 -- Positions inside MIDI string
    local ticks = 0 -- Running PPQ position of events while parsing
    local offset, flags, msg
     
    if laneIsCC7BIT then
        while pos < #MIDI do
            offset, flags, msg, pos = string.unpack("i4Bs4", MIDI, pos)
            ticks = ticks + offset
            if flags&1==1 and #msg == 3 and msg:byte(2) == targetLane and (msg:byte(1))>>4 == 11 
            then
                tMIDI[#tMIDI+1] = MIDI:sub(prevPos, pos-8)
                tMIDI[#tMIDI+1] = MIDI:sub(pos-7, pos-1) --string.pack("s4", msg)
                prevPos = pos
                tSel[#tSel+1] = {index = #tMIDI, chan = msg:byte(1)&0x0F, val = msg:byte(3), ticks = ticks}
            end
        end
    elseif laneIsCC14BIT then
        while pos < #MIDI do
            offset, flags, msg, pos = string.unpack("i4Bs4", MIDI, pos)
            ticks = ticks + offset
            if flags&1==1 and #msg == 3 and (msg:byte(1))>>4 == 11 
            then
                if msg:byte(2) == targetLane-256
                then
                    local chan = msg:byte(1)&0x0F
                    tMIDI[#tMIDI+1] = MIDI:sub(prevPos, pos-8)
                    tMIDI[#tMIDI+1] = MIDI:sub(pos-7, pos-1)
                    prevPos = pos
                    -- Store value so that can later be combined with LSB
                    local t14Index = t14[chan][ticks]
                    if t14Index then
                        if tSel[t14Index].indexMSB then -- Oops, already got MSB with this tick pos and channel.  So delete this one.
                            tMIDI[#tMIDI] = EMPTY_EVENT_MSG
                        else
                            tSel[t14Index].indexMSB = #tMIDI
                            tSel[t14Index].val = tSel[t14Index].val | (msg:byte(3)<<7)
                        end
                    else 
                        tSel[#tSel+1] = {indexMSB = #tMIDI, chan = chan, val = msg:byte(3)<<7, ticks = ticks}
                        t14[chan][ticks] = #tSel
                    end
                elseif msg:byte(2) == targetLane-224
                then
                    local chan = msg:byte(1)&0x0F
                    tMIDI[#tMIDI+1] = MIDI:sub(prevPos, pos-8)
                    tMIDI[#tMIDI+1] = MIDI:sub(pos-7, pos-1)
                    prevPos = pos
                    -- Store value so that can later be combined with LSB
                    local t14Index = t14[chan][ticks]
                    if t14Index then
                        if tSel[t14Index].indexLSB then -- Oops, already got MSB with this tick pos and channel.  So delete this one.
                            tMIDI[#tMIDI] = EMPTY_EVENT_MSG
                        else
                            tSel[t14Index].indexLSB = #tMIDI
                            tSel[t14Index].val = tSel[t14Index].val | msg:byte(3)
                        end
                    else 
                        tSel[#tSel+1] = {indexLSB = #tMIDI, chan = chan, val = msg:byte(3), ticks = ticks}
                        t14[chan][ticks] = #tSel
                    end
                end -- if msg:byte(2) == targetLane-256
            end -- if #msg == 3 and (msg:byte(1))>>4 == 11
        end
    elseif laneIsPITCH then
        while pos < #MIDI do
            offset, flags, msg, pos = string.unpack("i4Bs4", MIDI, pos)
            ticks = ticks + offset
            if flags&1==1 and #msg == 3 and (msg:byte(1))>>4 == 14 
            then
                tMIDI[#tMIDI+1] = MIDI:sub(prevPos, pos-8)
                tMIDI[#tMIDI+1] = MIDI:sub(pos-7, pos-1)
                prevPos = pos
                tSel[#tSel+1] = {index = #tMIDI, chan = msg:byte(1)&0x0F, val = (msg:byte(3)<<7) + msg:byte(2), ticks = ticks}
            end
        end   
    elseif laneIsPROGRAM then 
        while pos < #MIDI do
            offset, flags, msg, pos = string.unpack("i4Bs4", MIDI, pos)
            ticks = ticks + offset
            if flags&1==1 and #msg == 2 and (msg:byte(1))>>4 == 12 
            then
                tMIDI[#tMIDI+1] = MIDI:sub(prevPos, pos-7)
                tMIDI[#tMIDI+1] = MIDI:sub(pos-6, pos-1)
                prevPos = pos
                tSel[#tSel+1] = {index = #tMIDI, chan = msg:byte(1)&0x0F, val = msg:byte(2), ticks = ticks}
            end
        end 
    elseif laneIsCHPRESS then 
        while pos < #MIDI do
            offset, flags, msg, pos = string.unpack("i4Bs4", MIDI, pos)
            ticks = ticks + offset
            if flags&1==1 and #msg == 2 and (msg:byte(1))>>4 == 13
            then
                tMIDI[#tMIDI+1] = MIDI:sub(prevPos, pos-7)
                tMIDI[#tMIDI+1] = MIDI:sub(pos-6, pos-1)
                prevPos = pos
                tSel[#tSel+1] = {index = #tMIDI, chan = msg:byte(1)&0x0F, val = msg:byte(2), ticks = ticks}
            end
        end 
    elseif laneIsVELOCITY then 
        while pos < #MIDI do
            offset, flags, msg, pos = string.unpack("i4Bs4", MIDI, pos)
            ticks = ticks + offset
            if flags&1==1 and #msg == 3 and (msg:byte(1))>>4 == 9 and msg:byte(3) ~= 0
            then
                tMIDI[#tMIDI+1] = MIDI:sub(prevPos, pos-8)
                tMIDI[#tMIDI+1] = MIDI:sub(pos-7, pos-1) --string.pack("s4", msg)
                prevPos = pos
                tSel[#tSel+1] = {index = #tMIDI, chan = msg:byte(1)&0x0F, val = msg:byte(3), pitch = msg:byte(2), ticks = ticks}
            end
        end 
    elseif laneIsOFFVEL then 
        while pos < #MIDI do
            offset, flags, msg, pos = string.unpack("i4Bs4", MIDI, pos)
            ticks = ticks + offset
            if flags&1==1 and #msg == 3 and ((msg:byte(1)>>4 == 9 and msg:byte(3) == 0) or msg:byte(1)>>4 == 8) then
                tMIDI[#tMIDI+1] = MIDI:sub(prevPos, pos-8)
                tMIDI[#tMIDI+1] = MIDI:sub(pos-7, pos-1) --string.pack("s4", msg)
                prevPos = pos
                tSel[#tSel+1] = {index = #tMIDI, chan = msg:byte(1)&0x0F, val = msg:byte(3), ticks = ticks}
            end
        end 
    end
    
    -- Insert all unselected events remaining
    tMIDI[#tMIDI+1] = MIDI:sub(prevPos, nil)                

end


---------------------------------------------
function setup_deselectAndDeleteCCs() 
    -- The remaining events and the newly assembled events will be stored in these table
    local tMIDI = {}
    local r = 0
    local pos = 1
    local prevPos = 1
    local runningPPQpos = 0
    local offset, flags, msg, mustDelete
    while pos < #editMIDI do
        mustDelete, mustDeselect = nil, nil
        offset, flags, msg, pos = s_unpack("i4Bs4", editMIDI, pos)
        runningPPQpos = runningPPQpos + offset
        
        if laneIsCC7BIT then 
            if msg:byte(1)>>4 == 0xB and msg:byte(2) == targetLane then 
                mustDeselect = 13
                local channel = msg:byte(1)&0x0F
                for i = 1, #tRanges do    
                    if channel == tRanges[i].channel and runningPPQpos >= tRanges[i].startTick and runningPPQpos < tRanges[i].endTick then
                        mustDelete = 13
                        break
                    end
                end
            end

        elseif laneIsPITCH    
            then if msg:byte(1)>>4 == 0xE then 
                mustDeselect = 13
                local channel = msg:byte(1)&0x0F
                for i = 1, #tRanges do    
                    if channel == tRanges[i].channel and runningPPQpos >= tRanges[i].startTick and runningPPQpos < tRanges[i].endTick then
                        mustDelete = 13
                        break
                    end
                end
            end
            
        elseif laneIsCC14BIT  
            then if msg:byte(1)>>4 == 0xB and (msg:byte(2) == targetLane-224 or msg:byte(2) == targetLane-256) then 
                mustDeselect = 13
                local channel = msg:byte(1)&0x0F
                for i = 1, #tRanges do    
                    if channel == tRanges[i].channel and runningPPQpos >= tRanges[i].startTick and runningPPQpos < tRanges[i].endTick then
                        mustDelete = 13
                        break
                    end
                end
            end
            
        elseif laneIsPROGRAM  
            then if msg:byte(1)>>4 == 0xC then 
                mustDeselect = 12
                local channel = msg:byte(1)&0x0F
                for i = 1, #tRanges do    
                    if channel == tRanges[i].channel and runningPPQpos >= tRanges[i].startTick and runningPPQpos < tRanges[i].endTick then
                        mustDelete = 12
                        break
                    end
                end
            end
            
        elseif laneIsCHPRESS  
            then if msg:byte(1)>>4 == 0xD then 
                mustDeselect = 12
                local channel = msg:byte(1)&0x0F
                for i = 1, #tRanges do    
                    if channel == tRanges[i].channel and runningPPQpos >= tRanges[i].startTick and runningPPQpos < tRanges[i].endTick then
                        mustDelete = 12
                        break
                    end
                end
            end
        end         

        
        if mustDelete then
            tMIDI[#tMIDI+1] = editMIDI:sub(prevPos, pos-mustDelete)
            tMIDI[#tMIDI+1] = s_pack("i4Bs4", offset, 0, "")
            prevPos = pos
        elseif mustDeselect then
            tMIDI[#tMIDI+1] = editMIDI:sub(prevPos, pos-mustDeselect)
            tMIDI[#tMIDI+1] = s_pack("i4Bs4", offset, flags&0xE, msg)
            prevPos = pos
        end
    end -- while pos < #editMIDI do
    
    tMIDI[#tMIDI+1] = editMIDI:sub(prevPos, nil)
    editMIDI = table.concat(tMIDI)
end


----------------------------------------------------------
-- This function ADDS items to tablePPQs and other tables.
function setup_insertNewCCs()
    
    local tMIDI = {}
    local lastPPQpos = 0
    
    -- Since v2.01, first CC will be inserted at first tick within time selection, even if it does not fall on a beat, to ensure that the new LFO value is applied before any note is played.
    for i = 1, #tRanges do
        local startTick = tRanges[i].startTick
        local channel   = tRanges[i].channel
        -- Get first insert position at CC density 'grid' beyond PPQstart
        local QNstart = reaper.MIDI_GetProjQNFromPPQPos(take, startTick)
        -- For improved accuracy, do not round firstCCinsertPPQpos yet
        local firstCCinsertPPQpos = reaper.MIDI_GetPPQPosFromProjQN(take, QNperCC*(math.ceil(QNstart/QNperCC)))
        if math.floor(firstCCinsertPPQpos+0.5) <= math.ceil(startTick) then firstCCinsertPPQpos = firstCCinsertPPQpos + PPperCC end
            
        -- endTick is actually beyond time selection, so "-1" to prevent insert at PPQend
        for p = firstCCinsertPPQpos, tRanges[i].endTick-1, PPperCC do
            local insertPPQpos = math.floor(p + 0.5)
            
            if     laneIsCC7BIT  then tMIDI[#tMIDI+1] = s_pack("i4Bi4BBB", insertPPQpos-lastPPQpos, 1, 3, 0xB0|channel, targetLane, 0)
            elseif laneIsCC14BIT then tMIDI[#tMIDI+1] = s_pack("i4Bi4BBB", insertPPQpos-lastPPQpos, 1, 3, 0xB0|channel, targetLane-256, 0)
                                      tMIDI[#tMIDI+1] = s_pack("i4Bi4BBB", 0, 1, 3, 0xB0|channel, targetLane-224, 0)
            elseif laneIsPROGRAM then tMIDI[#tMIDI+1] = s_pack("i4Bi4BB", insertPPQpos-lastPPQpos, 1, 2, 0xC0|channel, 0)
            elseif laneIsCHPRESS then tMIDI[#tMIDI+1] = s_pack("i4Bi4BB", insertPPQpos-lastPPQpos, 1, 2, 0xD0|channel, 0)
            elseif laneIsPITCH   then tMIDI[#tMIDI+1] = s_pack("i4Bi4BBB", insertPPQpos-lastPPQpos, 1, 3, 0xE0|channel, 0, 0)
            end
            lastPPQpos = insertPPQpos
        end
    end
    tMIDI[#tMIDI+1] = s_pack("i4Bs4", -lastPPQpos, 0, "")
    
    editMIDI = table.concat(tMIDI) .. editMIDI
end -- insertNewCCs(startPPQ, endPPQ, channel)

-------------------------------------

--############################################################################################
----------------------------------------------------------------------------------------------
-- HERE CODE EXECUTION STARTS

-- function main()
 
   
-- Start with a trick to avoid automatically creating undo states if nothing actually happened
-- Undo_OnStateChange will only be used if reaper.atexit(onexit) has been executed
reaper.defer(function() end)

------------------------------------------------
-- Check whether user-defined values are usable.
--[[if type(verbose) ~= "boolean" then 
    reaper.ShowMessageBox("The setting 'verbose' must be either 'true' of 'false'.", "ERROR", 0) return(false) end]]
if laneToUse ~= "last clicked" and laneToUse ~= "under mouse" then 
    reaper.MB('The setting "laneToUse" must be either "last clicked" or "under mouse".', "ERROR", 0) return(false) end
if selectionToUse ~= "time" and selectionToUse ~= "notes" and selectionToUse ~= "existing" then 
    reaper.MB('The setting "selectionToUse" must be either "time", "notes" or "existing".', "ERROR", 0) return(false) end
if type(defaultCurveName) ~= "string" then
    reaper.MB("The setting 'defaultCurveName' must be a string.", "ERROR", 0) return(false) end
--[[if type(deleteOnlyDrawChannel) ~= "boolean" then
    reaper.ShowMessageBox("The setting 'deleteOnlyDrawChannel' must be either 'true' of 'false'.", "ERROR", 0) return(false) end]]
if type(backgroundColor) ~= "table" 
    or type(foregroundColor) ~= "table" 
    or type(textColor) ~= "table" 
    or type(buttonColor) ~= "table" 
    or type(hotbuttonColor) ~= "table"
    or #backgroundColor ~= 4 
    or #foregroundColor ~= 4 
    or #textColor ~= 4 
    or #buttonColor ~= 4 
    or #hotbuttonColor ~= 4 
    then
    reaper.MB("The custom interface colors must each be a table of four values between 0 and 1.", "ERROR", 0) 
    return(false) 
    end
if type(shadows) ~= "boolean" then 
    reaper.MB("The setting 'shadows' must be either 'true' of 'false'.", "ERROR", 0) return(false) end
if type(fineAdjust) ~= "number" or fineAdjust < 0 or fineAdjust > 1 then
    reaper.MB("The setting 'fineAdjust' must be a number between 0 and 1.", "ERROR", 0) return(false) end
if type(phaseStepsDefault) ~= "number" or phaseStepsDefault % 4 ~= 0 or phaseStepsDefault <= 0 then
    reaper.MB("The setting 'phaseStepsDefault' must be a positive multiple of 4.", "ERROR", 0) return(false) 
end
    
    
-------------------------------------------------------------
-- Check whether the required version of REAPER is available.
if not reaper.APIExists("GetArmedCommand") then
    reaper.MB("This script requires an up-to-date version of REAPER.", "ERROR", 0)
    return(false)
end


------------------------------------------------------
-- If laneToUse == "under mouse" then SWS is required.
if laneToUse == "under mouse" then
    if not reaper.APIExists("SN_FocusMIDIEditor") then
        reaper.MB("This script requires an up-to-date version of the SWS/S&M extension.\n\nThe SWS/S&M extension can be downloaded from www.sws-extension.org.", "ERROR", 0)
        return(false) 
    end 
    window, segment, details = reaper.BR_GetMouseCursorContext()
    if not (segment == "notes" or segment == "cc_lane") then
        reaper.ShowMessageBox('The mouse is not correctly positioned.'
                              .. '\n\nIf the "lane_to_use" setting is "under mouse", the mouse must be positioned over a CC lane of a MIDI editor when the script starts.', "ERROR", 0)
        return(false)
    end
    _, isInline, _, targetLane, _, _ = reaper.BR_GetMouseCursorContext_MIDI()
end


---------------------
-- Get take and item.
if laneToUse == "under mouse" and isInline then
    take = reaper.BR_GetMouseCursorContext_Take()
else
    editor = reaper.MIDIEditor_GetActive()
    if editor == nil then 
        reaper.ShowMessageBox("No active MIDI editor found.", "ERROR", 0)
        return(false)
    end
    take = reaper.MIDIEditor_GetTake(editor)
end
if not reaper.ValidatePtr(take, "MediaItem_Take*") then 
    reaper.ShowMessageBox("Could not find an active take in the MIDI editor.", "ERROR", 0)
    return(false)
end
item = reaper.GetMediaItemTake_Item(take)  
if not reaper.ValidatePtr(item, "MediaItem*") then 
    reaper.ShowMessageBox("Could not determine the item to which the active take belongs.", "ERROR", 0)
    return(false)
end


----------------------------------------------------------------------
-- If new CCs have to be inserted, they wil be inserted at the default
--    grid resolution as set in Preferences -> MIDI editor 
--    -> "Events per quarter note when drawing in CC lanes".
-- Don't go above 128/QN or below 4/QN.
-- Calculate the ticks per CC density.
takeStartQN = reaper.MIDI_GetProjQNFromPPQPos(take, 0)
PPQ = reaper.MIDI_GetPPQPosFromProjQN(take, takeStartQN+1)
CCperQN = math.floor(reaper.SNM_GetIntConfigVar("midiCCdensity", 32) + 0.5)
CCperQN = math.min(128, math.max(4, math.abs(CCperQN))) -- If user selected "Zoom dependent", CCperQN < 0
PPperCC = PPQ/CCperQN
QNperCC = 1/CCperQN


------------------------------------------------------------------------------
-- The source length will be saved and checked again at the end of the script, 
--    to check that no inadvertent shifts in PPQ position happened.
sourceLengthTicks = reaper.BR_GetMidiSourceLenPPQ(take)


-------------------------------------------------------------------
-- Events will be inserted in the active channel of the active take
if isInline then
    defaultChannel = 0
else
    defaultChannel = reaper.MIDIEditor_GetSetting_int(editor, "default_note_chan")
end


-------------------------------------------------------------------
-- The LFO Tool can only work in channels that use continuous data.
-- Since 7bit CC, 14bit CC, channel pressure, and pitch all 
--     require somewhat different tweaks, these must often be 
--     distinguished.
if laneToUse == "under mouse" then
    -- targetLane has already been retrieved above...        
else
    targetLane = reaper.MIDIEditor_GetSetting_int(editor, "last_clicked_cc_lane")
    -- MIDIEditor_GetSetting_int(editor, "last_clicked_cc_lane") only works on CC lanes,
    --    so if no CC lane, assume that user last clicked in notea area.
    if targetLane == -1 then targetLane = 0x200 end  
end

if segment == "notes" and selectionToUse == "existing" then
    laneIsVELOCITY, laneIsNOTES = true, true
    laneMaxValue = 127
    laneMinValue = 1     
elseif type(targetLane) ~= "number" then
    couldNotParseLane = true
elseif 0 <= targetLane and targetLane <= 127 then -- CC, 7 bit (single lane)
    laneIsCC7BIT = true
    laneMaxValue = 127
    laneMinValue = 0
elseif targetLane == 0x203 then -- Channel pressure
    laneIsCHPRESS = true
    laneMaxValue = 127
    laneMinValue = 0
elseif 256 <= targetLane and targetLane <= 287 then -- CC, 14 bit (double lane)
    laneIsCC14BIT = true
    laneMaxValue = 16383
    laneMinValue = 0
elseif targetLane == 0x201 then
    laneIsPITCH = true
    laneMaxValue = 16383
    laneMinValue = 0
elseif targetLane == 0x200 and selectionToUse == "existing" then
    laneIsVELOCITY, laneIsNOTES = true, true
    laneMaxValue = 127
    laneMinValue = 1 
else 
    couldNotParseLane = true -- not a lane type in which a ramp can be drawn (sysex, velocity etc).
end

-- If laneToUse == "existing", then velocity lane can be used.
-- So the error messages must be slightly different.
if couldNotParseLane then
    if selectionToUse == "existing" then
        if laneToUse == "under mouse" then
            reaper.ShowMessageBox("The lane under mouse is not usable."
                         .. "\n\nThe LFO Tool can only work in lanes that accept events with continuous values (unlike sysex or text, for example)."
                         .. "\n\nSince the 'laneToUse' setting is currently set to 'under mouse', the mouse must be positioned over one of the following lanes when the script starts:"
                         .. "\n * 7-bit CC,\n * 14-bit CC,\n * pitchwheel,\n * channel pressure, or\n * velocity."                        
                         .. "\n\nThe velocity lane can only be used when applying the LFO to existing events, not when inserting new events.  (That is, when the setting 'selectionToUse' is set to 'existing' in the script's user area.)"
                         , "ERROR", 0)
        else
            reaper.ShowMessageBox("The last clicked lane is not usable."
                         .. "\n\nThe LFO Tool can only work in lanes that accept events with continuous values (unlike sysex or text, for example)."           
                         .. "\n\nSince the 'laneToUse' setting is currently set to 'last clicked', the last clicked lane in the MIDI editor must be one of the following lanes:"
                         .. "\n * 7-bit CC,\n * 14-bit CC,\n * pitchwheel,\n * channel pressure, or\n * velocity."                        
                         .. "\n\nThe velocity lane can only be used when applying the LFO to existing events, not when inserting new events.  (That is, when the setting 'selectionToUse' is set to 'existing' in the script's user area.)"
                         , "ERROR", 0)    
        end
    else
        if laneToUse == "under mouse" then
            reaper.ShowMessageBox("The lane under mouse is not usable."
                         .. "\n\nThe LFO Tool can only work in lanes that accept events with continuous values (unlike sysex or text, for example)."     
                         .. "\n\nSince the 'laneToUse' setting is currently set to 'under mouse', the mouse must be positioned over one of the following lanes when the script starts:"
                         .. "\n * 7-bit CC,\n * 14-bit CC,\n * pitchwheel, or\n * channel pressure."                        
                         .. "\n\nThe velocity lane can only be used when applying the LFO to existing events, not when inserting new events.  (That is, when the setting 'selectionToUse' is set to 'existing' in the script's user area.)"
                         , "ERROR", 0)        
        else
            reaper.ShowMessageBox("The last clicked lane is not useable."
                         .. "\n\nThe LFO Tool can only work in lanes that accept events with continuous values (unlike sysex or text, for example)."
                         .. "\n\nSince the 'laneToUse' setting is currently set to 'last clicked', the last clicked lane in the MIDI editor must be one of the following lanes:"
                         .. "\n * 7-bit CC,\n * 14-bit CC,\n * pitchwheel, or\n * channel pressure."                            
                         .. "\n\nThe velocity lane can only be used when applying the LFO to existing events, not when inserting new events.  (That is, when the setting 'selectionToUse' is set to 'existing' in the script's user area.)"
                         , "ERROR", 0)     
        end  
    end          
    return(false)
end


----------------------------------------------------------
-- Get a nice lane description to use use as window title.
if laneIsCC7BIT        then targetLaneString = "CC " .. tostring(targetLane)
elseif laneIsCHPRESS   then targetLaneString = "Channel pressure"
elseif laneIsCC14BIT   then targetLaneString = "CC ".. tostring(targetLane-256) .. "/" .. tostring(targetLane-224) .. " 14-bit"
elseif laneIsPITCH     then targetLaneString = "Pitchwheel"
elseif laneIsVELOCITY  then targetLaneString = "Velocity"
end
 

--------------------------------------------------------------------------
-- REAPER v5.30 introduced new API functions for fast, mass edits of MIDI:
--    MIDI_GetAllEvts and MIDI_SetAllEvts.
gotAllOK, origMIDI = reaper.MIDI_GetAllEvts(take, "")
if not gotAllOK then
    reaper.ShowMessageBox("MIDI_GetAllEvts could not load the raw MIDI data.", "ERROR", 0)
    return false 
end
editMIDI = origMIDI -- editMIDI may change after MIDI_Sort, deletion etc, but origMIDI will remain. In case of errors, origMIDI will return the take to its original state.


-----------------------------------------------------------------------------------
-- OK, most of the tests are completed and script can start making changes to take, 
--    so activate menu button, if relevant, and define atexit
_, _, sectionID, cmdID, _, _, _ = reaper.get_action_context()
if sectionID ~= nil and cmdID ~= nil and sectionID ~= -1 and cmdID ~= -1 then
    reaper.SetToggleCommandState(sectionID, cmdID, 1)
    reaper.RefreshToolbar2(sectionID, cmdID)
end    
reaper.atexit(exit)


-------------------------------------------------------------------
-- Test whether there is actually a time span in which to draw LFO.
-- (Remember to later correct PPQ positions for looped takes.)
timeSelectStart, timeSelectEnd = reaper.GetSet_LoopTimeRange(false, false, 0.0, 0.0, false)    
if selectionToUse == "time" then
    if type(timeSelectStart) ~= "number"
        or type(timeSelectEnd) ~= "number"
        or timeSelectEnd<=timeSelectStart 
        then 
        reaper.ShowMessageBox("A time range must be selected (within the active item's own time range).", "ERROR", 0)
        return(false) 
    end
    -- Find PPQ positions of time selection and calculate corrected values (relative to first iteration) if take is looped
    local timeSelPPQstart = reaper.MIDI_GetPPQPosFromProjTime(take, timeSelectStart)
    local timeSelPPQend = reaper.MIDI_GetPPQPosFromProjTime(take, timeSelectEnd) -- May be changed later if rightmost event is not a note
    PPQofLoopStart = (timeSelPPQstart//sourceLengthTicks)*sourceLengthTicks
    if not (PPQofLoopStart == ((timeSelPPQend-1)//sourceLengthTicks)*sourceLengthTicks) then
        reaper.ShowMessageBox("The selected time range should fall within a single loop iteration.", "ERROR", 0)
        return(false) 
    end
    timeSelPPQstart = timeSelPPQstart - PPQofLoopStart
    timeSelPPQend   = timeSelPPQend - PPQofLoopStart
    
    tRanges[1] = {channel = defaultChannel, startTick = timeSelPPQstart, endTick = timeSelPPQend}
    setup_deselectAndDeleteCCs()
    setup_insertNewCCs()    

elseif selectionToUse == "notes" then
   setup_parseNotesToRanges()
    if #tRanges == 0 then
    --if #tablePPQs < 3 or origPPQrange == 0 then
        reaper.MB("Could not find selected notes of sufficient length.", "ERROR", 0)
        return(false)
    end
    setup_deselectAndDeleteCCs()
    setup_insertNewCCs()  

else -- selectionToUse == "existing"
    -- Nothing
end        
            
            
--------------------------------------------------------            
-- Now that CCs have been deselected, deleted and added, 
--    use REAPER's own API to sort the events.
reaper.MIDI_SetAllEvts(take, editMIDI)
reaper.MIDI_Sort(take)
MIDIOK, editMIDI = reaper.MIDI_GetAllEvts(take, "")
-- Find selected events in target lane
setup_findTargetEvents()
if #tSel < 4 then
    reaper.MB("The selected range does not contain a sufficient number of events.", "ERROR", 0)
    reaper.MIDI_SetAllEvts(take, origMIDI)
    return(false)
end
time_start = reaper.MIDI_GetProjTimeFromPPQPos(take, tSel[1].ticks)
time_end = reaper.MIDI_GetProjTimeFromPPQPos(take, tSel[#tSel].ticks) 
    

------------------------
-- Done with MIDI setup!
--    Start GUI!
constructNewGUI()
-- Load default curve, if any
if getSavedCurvesAndNames() ~= false then
    if savedNames ~= nil and type(savedNames) == "table" and #savedNames > 0 then
        for i = 1, #savedNames do
            if savedNames[i] == defaultCurveName then
                loadCurve(i)
            end
        end
    end
end

--!!!!!!!New in 2.20
-- Check whether skipRedundantCCs setting has been saved
if reaper.GetExtState("LFO generator", "skipRedundantCCs") == "true" then
    skipRedundantCCs = true
else
    skipRedundantCCs = false
end

-- Generate the first version of the envelope nodes and draw the CCs between
callGenerateNodesThenUpdateEvents()
loop_GetInputsAndUpdate()

--[[ Archive of changelog
 * v0.1
    + Xenakios' Initial Release
 * v0.2
    + Julian's mod
 * v0.3 (2016-05-20)
    + Time selection now works properly with take envelopes when take position is not at start of project.
    + LFO now uses full range of envelopes with different min and max values (such as pitch).
 * v0.4 (2016-05-20)
    + Cntl-click (or -drag) in envelope now sets all points to the same value.
    + Added help text and "?" button.
 * v0.5 (2016-05-21)
    + Prevent slow mouse clicks from activating buttons multiple times.
    + Interface colors now easily customizable.
    + Replaced 'Delay' with 'Phase step', which steps through nodes in shape definition.
    + The LFO generator now inserts an interpolated envelope point at end of time selection.
 * v0.9 (2016-05-22)
    + Saving and loading of curves.
    + New interface look.
 * v0.91 (2016-05-25)
    + Fixed "attempt to get length of a nil value (global 'savedNames')" bug
 * v0.99 (2016-05-27)
    + The MIDI editor version!  
    + Bézier curves are not yet implemented in this v0.99. All REAPER envelope shapes are implemented.
    + Envelope area now resizeable (allowing finer resolution).
    + Alt-drag for quick delete of multiple nodes.
    + Slow start/end shape replaced by Sine in MIDI editor version.
    + Accurate interpolation of Fast start, Fast end and Sine shapes.
    + Curve named "default" will be loaded on startup.
 * v0.991 (2016-05-29)
    + Bug fix: Script does not fail when "Zoom dependent" CC density is selected in Preferences.
 * v0.995 (2016-06-06)
    + New option to draw LFO underneath selected notes, instead of in time selection.
    + New option to draw LFO in CC lane under mouse, instead of last clicked CC lane.
    + Esc closes GUI. 
 * v0.997 (2016-06-13)
    + Mousewheel can be used for super fine adjustment of node values.
    + Rightclick in envelope area to set the LFO period to precise note lengths.
    + Envelope value displayed above hotpoint.
 * v0.999 (2016-06-13)
    + Changed Rate interpolation between nodes from linear to parabolic.
 * v1.03 (2016-06-18)
    + Timebase: Beats option.
    + Fixed regression in fade out.
    + Added "Reset curve" option in Save/Load menu.
    + Added optional display of hotpoint time position (in any of REAPER's time formats).
    + Improved sensitivity of nodes at edges of envelope drawing area.
 * v1.04 (2016-06-23)
    + User can specify the number of phase steps in standard LFO shapes, which allows nearly continuous phase changes.
]]
