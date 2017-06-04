--[[
ReaScript name: js_LFO Tool (MIDI editor version, insert CCs under selected notes in last clicked lane).lua
Version: 2.10
Author: juliansader
Website: http://forum.cockos.com/showthread.php?t=177437
Screenshot: http://stash.reaper.fm/27848/LFO%20Tool%20-%20fill%20note%20positions%20with%20CCs.gif
REAPER version: v5.32 or later
Extensions: None required
Donation: https://www.paypal.me/juliansader
About:
  # Description
  
  LFO generator and shaper - MIDI editor version
  
  Draw fancy LFO curves in REAPER's piano roll.
  
  This version of the script inserts new CCs under selected notes in the last clicked lane, 
  using the same channels as the notes above (after removing any pre-existing CCs in the same time range and channels).
  
  # Instructions
  
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
  
  Right-click (outside envelope area) to open the Save/Load/Delete curve menu.
  
  One of the saved curves can be loaded automatically at startup. By default, this curve must be named "default".
  
                    
  FURTHER CUSTOMIZATION
  
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
  v2.10 (2017-06-03)
    + New Smoothing slider (replecs non-functional Bezier slider) to smoothen curves at nodes.    
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
    
    -- Which area should be filled with CCs?
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


shapeSelected = 6 -- Starting shape
GUIelementHeight = 28 -- Height of the GUI elements
borderWidth = 10
envHeight = 190
initXsize = 209 --300 -- Initial sizes for the GUI
initYsize = borderWidth + GUIelementHeight*11 + envHeight + 45
envYpos = initYsize - envHeight - 30

hotpointRateDisplayType = "period note length" -- "frequency" or "period note length"
hotpointTimeDisplayType = -1
rateInterpolationType = "parabolic" -- "linear" or "parabolic"

-- By default, these curve will align if the tempo is a constant 120bpm
-- The range is between 2 whole notes and 1/32 notes, or 0.25Hz and 16Hz.
timeBaseMax = 16 -- 16 oscillations per second
timeBaseMin = 0.25
beatBaseMax = 32 -- 32 divisions per whole note
beatBaseMin = 0.5

-- The Clip slider and value in the original code
--     do not appear to have any effect, 
--     so the slider was replaced by the "Real-time copy to CC?" 'slider',
--     and the value was replaced by this constant
clip = 1

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
         .."\n\nRight-click (outside envelope area) to open the Save/Load/Delete curve menu."
         .."\n\nOne of the saved curves can be loaded automatically at startup. By default, this curve must be named 'default'."
                 
         .."\n\nCOPYING TO CC:"
         .."\n\n'Real-time copy to CC' does not write directly to the CC lane. Instead, it copies from the active envelope to the last clicked CC lane. An envelope must therefore still be open and active."
        
         .."\n\nFURTHER CUSTOMIZATION:"
         .."\n\nFurther customization is possible - refer to the instructions in the script's USER AREA.\nThis includes:"
         .."\n  * Easily adding custom LFO shapes."
         .."\n  * Specifying the resolution of LFO shapes' phase steps."
         .."\n  * Specifying the resolution of the mousewheel fine adjustment."
         .."\n  * Changing interface colors."
         .."\n  * Changing the default curve name."
         .."\netc..." 
                 

-- mouse_cap values
NOTHING = 0
LEFTBUTTON = 1
RIGHTBUTTON = 2
CTRLKEY = 4
SHIFTKEY = 8
ALTKEY = 16
WINKEY = 32
MIDDLEBUTTON = 64


-- The raw MIDI data will be stored in the string.  While parsing the string, targeted events (the
--    ones that will be edited) will be removed from the string.
-- The offset of the first event will be stored separately - not in remainMIDIstring - since this offset 
--    will need to be updated in each cycle relative to the PPQ positions of the edited events.
local MIDIstring -- The original raw MIDI
local remainMIDIstring -- The MIDI that remained after extracting selected events in the target lane
local remainMIDIstringSub5 -- The MIDI that remained, except the very first offset
local remainOffset -- The very first offset of the remaining events
local newRemainOffset -- At each cycle, the very first offset must be updated relative to the edited MIDI. NOTE: In scripts that do not change the positions of events, this will not actually be necessary.

-- When the info of the targeted events is extracted - or when the new CCs are inserted -- the info will be stored in several tables.
local tableMsg = {}
local tableMsgLSB = {}
local tableMsgNoteOff = {}
local tableValues = {} -- CC values, 14bit CC combined values, note velocities
local tablePPQs = {}
local tableChannels = {}
local tableFlags = {}
local tableFlagsLSB = {} -- In the case of 14bit CCs, mute/select status of the MSB
local tablePitches = {} -- This table will only be filled if laneIsVELOCITY
local tableNoteLengths = {}
local tableNotation = {} -- Will only contain entries at those indices where the notes have notation

-- The original value and PPQ ranges of selected events in the target lane will be summarized in:
local origPPQleftmost, origPPQrightmost, origPPQrange
local includeNoteOffsInPPQrange = false -- ***** Should origPPQrange and origPPQrightmost take note-offs into account? Set this flag to true for scripts that stretch or warp note lengths. *****

-- As the edited MIDI events' new values are calculated, each event wil be assmebled into a short string and stored in the tableEditedMIDI table.
-- When the calculations are done, the entire table will be concatenated into a single string, then inserted 
--    at the beginning of remainMIDIstring (while updating the relative offset of the first event in remainMIDIstring, 
--    and loaded into REAPER as the new state chunk.
local tableEditedMIDI = {}

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
  result.y=function() return y end
  result.w=function() return gfx.w-20 end
  result.h=function() return h+gfx.h-initYsize end
  
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
        if shadows == true then
            setColor({0,0,0,1})
            gfx.rect(slid.x()+1,slid.y()+16,slid.w()*slid.value,7,true)  
        end
        setColor(foregroundColor)
        gfx.rect(slid.x(),slid.y()+15,slid.w()*slid.value,7,true)
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
        if slid.name == tableGUIelements[100].name then
            --local stringw,stringh = gfx.measurestr("Amplitude")
            if shadows == true then
                setColor({0,0,0,1})
                --gfx.rect(gfx.w/2-ampw/2-5, slid.y()-1, ampw+12, stringh+7, true)
                fillRoundRect(gfx.w/2-ampw/2-5, slid.y()-1, ampw+12, stringh+7, 1)
            end
            setColor(foregroundColor)
            gfx.a = gfx.a*0.9
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
    
    -- draw "?"
    if shadows == true then
        gfx.x = gfx.w - 19
        gfx.y = gfx.h - 22
        setColor({0,0,0,1})
        gfx.drawstr("?")
    end
    setColor(foregroundColor)
    gfx.a = 1
    gfx.y = gfx.h - 23
    gfx.x = gfx.w - 20 --gfx.measurestr("?")
    gfx.drawstr("?")
    
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
function generateNodes(freq,amp,center,phase,randomness,quansteps,tilt,fadindur,fadoutdur,ratemode,clip)

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

        freq_norm_to_use = get_env_interpolated_value(tableGUIelements[1].envelope,time_to_interp, rateInterpolationType)
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
            amp_to_use = get_env_interpolated_value(tableGUIelements[2].envelope,time_to_interp, "linear")
            --if amp_to_use<0.0 or amp_to_use>1.0 then reaper.ShowConsoleMsg(amp_to_use.." ") end
            val=0.5+(0.5*amp_to_use*fade_gain)*val
            local center_to_use=get_env_interpolated_value(tableGUIelements[3].envelope,time_to_interp, "linear")
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
    gfx.quit()
    
    -- MIDI_Sort used to be buggy when dealing with overlapping or unsorted notes,
    --    causing infinitely extended notes or zero-length notes.
    -- Fortunately, these bugs were seemingly all fixed in v5.32.
    reaper.MIDI_Sort(take)  
    
    -- Check that there were no inadvertent shifts in the PPQ positions of unedited events.
    if not (sourceLengthTicks == reaper.BR_GetMidiSourceLenPPQ(take)) then
        reaper.MIDI_SetAllEvts(take, origMIDIstring) -- Restore original MIDI
        reaper.ShowMessageBox("The script has detected inadvertent shifts in the PPQ positions of unedited events."
                              .. "\n\nThis may be due to a bug in the script, or in the MIDI API functions."
                              .. "\n\nPlease report the bug in the following forum thread:"
                              .. "\nhttp://forum.cockos.com/showthread.php?t=176878"
                              .. "\n\nThe original MIDI data will be restored to the take.", "ERROR", 0)
    end
        
    if isInline then reaper.UpdateArrange() end  
    
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
    
    
    --if selectionToUse == "time" then
        local time_start_new, time_end_new = reaper.GetSet_LoopTimeRange(false, false, 0.0, 0.0, false)
        if time_start_new ~= timeSelectStart or time_end_new ~= timeSelectEnd then 
            return(0) 
        end
    --end
    
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
    if (gfx.mouse_cap == LEFTBUTTON
    and gfx.mouse_x > gfx.w-22 and gfx.mouse_y > gfx.h-22) 
    and firstClick == true then
        firstClick = false
        reaper.ShowConsoleMsg(helpText)
    end  
    
    -- Iterate through all the buttons and sliders in the GUI  
    local dogenerate=false
    for key,tempcontrol in pairs(tableGUIelements) do
    
      --if key>=200 and tempcontrol.type=="Button" then reaper.ShowConsoleMsg(tostring(tempcontrol).." ") end
      if is_in_rect(gfx.mouse_x,gfx.mouse_y,tempcontrol.x(),tempcontrol.y(),tempcontrol.w(),tempcontrol.h()) 
      or (key == GUIelement_env and is_in_rect(gfx.mouse_x,gfx.mouse_y,0,tempcontrol.y()-15,gfx.w,tempcontrol.h()+22))
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
                tableGUIelements[100].envelope=tableGUIelements[GUIelement_RATE].envelope
                tableGUIelements[100].name=tableGUIelements[GUIelement_RATE].name -- = tempcontrol.name
                firstClick = false
                dogenerate = true
            elseif char == string.byte("c") or (gfx.mouse_cap==LEFTBUTTON and tempcontrol.name=="Center") then
                tableGUIelements[100].envelope=tableGUIelements[GUIelement_CENTER].envelope
                tableGUIelements[100].name=tableGUIelements[GUIelement_CENTER].name -- = tempcontrol.name
                firstClick = false
                dogenerate = true
            elseif char == string.byte("a") or (gfx.mouse_cap==LEFTBUTTON and tempcontrol.name=="Amplitude") then
                tableGUIelements[100].envelope=tableGUIelements[GUIelement_AMPLITUDE].envelope
                tableGUIelements[100].name=tableGUIelements[GUIelement_AMPLITUDE].name -- tempcontrol.name
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
                  tempcontrol.envelope[#tempcontrol.envelope+1]={math.min(1, math.max(0, pt_x)),
                                                                 math.min(1, math.max(0, 1.0-pt_y)) }
                  dogenerate=true
                  already_added_pt=true
                  sort_envelope(tempcontrol.envelope)
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
                  tempcontrol.envelope[#tempcontrol.envelope+1]={math.min(1, math.max(0, pt_x)),
                                                                 math.min(1, math.max(0, 1.0-pt_y)) }
                  dogenerate=true
                  already_added_pt=true
                  sort_envelope(tempcontrol.envelope)
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
                  ept = captured_control.envelope[captured_control.hotpoint]
                  if tempcontrol.hotpoint == 1 then 
                      ept[1]=0
                  elseif tempcontrol.hotpoint == #tempcontrol.envelope then
                      ept[1]=1
                  else
                      ept[1]=math.min(1, math.max(0, pt_x))
                  end
                  ept[2]=math.min(1, math.max(0, 1.0-pt_y))
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
              if captured_control.envelope==tableGUIelements[100].envelope then 
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
  if gfx.mouse_cap == RIGHTBUTTON and not is_in_rect(gfx.mouse_x,
                                                     gfx.mouse_y,
                                                     0, --tableGUIelements[100].x(),
                                                     tableGUIelements[100].y(),
                                                     gfx.w, --tableGUIelements[100].w(),
                                                     gfx.h - tableGUIelements[100].y()) --tableGUIelements[100].h()) 
                                                     then
        
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
            
            loadStr = loadStr .. "|<||>Delete curve"
            for i = 1, #savedNames do
                loadStr = loadStr .. "|" .. savedNames[i] 
            end
            loadStr = loadStr .. "|<||"           
        else
            gotSavedNames = false
            loadStr = "#Load curve||#Delete curve||"
        end
        
        saveLoadString = "Save curve||" .. loadStr .. "Reset curve"      
        
        
        ----------------------------------------
        -- Show save/load/delete menu
        gfx.x = gfx.mouse_x; gfx.y = gfx.mouse_y
        menuSel = gfx.showmenu(saveLoadString)
        
        if menuSel == 0 then  
            -- do nothing
            
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
            if tableGUIelements[100].name == tableGUIelements[1].name then -- "Rate"
                tableGUIelements[100]=make_envelope(borderWidth, envYpos, 0, envHeight, tableGUIelements[1])
            elseif tableGUIelements[100].name == tableGUIelements[2].name then -- "Amplitude"
                tableGUIelements[100]=make_envelope(borderWidth, envYpos, 0, envHeight, tableGUIelements[2])
            else -- "Center"
                tableGUIelements[100]=make_envelope(borderWidth, envYpos, 0, envHeight, tableGUIelements[3])
            end
            
        ------------------------
        -- Save curve
        elseif menuSel == 1 then
            repeat
                retval, curveName = reaper.GetUserInputs("Save curve", 1, "Curve name (no | or ,)", "")
            until retval == false or (curveName:find("|") == nil and curveName:find(",") == nil and curveName:len()>0)
            
            if retval ~= false then
                saveString = curveName
                for i = 0, 10 do
                    if tableGUIelements[i] == nil then -- skip
                    elseif tableGUIelements[i].name == "LFO shape?" then saveString = saveString .. ",LFO shape?," .. tostring(shapeSelected)
                    --elseif tableGUIelements[i].name == "Real-time copy to CC?" then saveString = saveString .. ",Real-time copy to CC?," .. tostring(tableGUIelements[i].enabled) 
                    elseif tableGUIelements[i].name == "Phase step" then saveString = saveString .. ",Phase step," .. tostring(tableGUIelements[i].value)
                    elseif tableGUIelements[i].name == "Randomness" then saveString = saveString .. ",Randomness," .. tostring(tableGUIelements[i].value)
                    elseif tableGUIelements[i].name == "Quant steps" then saveString = saveString .. ",Quant steps," .. tostring(tableGUIelements[i].value)
                    elseif tableGUIelements[i].name == "Bezier shape" then saveString = saveString .. ",Bezier shape," .. tostring(tableGUIelements[i].value)
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
      generateNodes(tableGUIelements[1].value, -- freq
             tableGUIelements[2].value, -- amp
             tableGUIelements[3].value, -- center
             tableGUIelements[4].value, -- phase
             tableGUIelements[5].value, -- randomness
             tableGUIelements[6].value, -- quansteps
             tableGUIelements[7].value, -- tilt
             tableGUIelements[8].value, -- fadindur
             tableGUIelements[9].value, -- fadoutdur
             tableGUIelements[10].value, -- timebase (aka ratemode)
             clip) 
      was_changed=true
    
    -- Draw the envelope in CC lane
    updateEventValuesAndUploadIntoTake()
end


------------------------------------------------------------
-- NOTE: This function requires all the tables to be sorted!
function updateEventValuesAndUploadIntoTake() 

    local tableEditedMIDI = {} -- Clean previous tableEditedMIDI
    local c = 0 -- Count index inside tableEditedMIDI - strangely, this is faster than using table.insert or even #tableEditedMIDI+1
    
    local offset = 0
    local lastPPQpos = 0
    local i = 1 -- index in tablePPQs and other event tables
    
    -- The smoothing function depends on values of nodes before and after the current two, 
    --    so add two artificial 'nodes' to tableNodes:
    local numNodesMinus1 = #tableNodes-1
    tableNodes[0] = {value = tableNodes[1].value, PPQ = tableNodes[1].PPQ-1, shape = 0}
    tableNodes[#tableNodes+1] = {value = tableNodes[#tableNodes].value, PPQ = tableNodes[#tableNodes].PPQ + 1}
    
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
        if tableGUIelements[GUIelement_SMOOTH].value ~= 0 -- Slider value = 0 implies no smoothing
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
                squareSmoothRadiusX = (nextNodePPQ - prevNodePPQ)*0.5*tableGUIelements[GUIelement_SMOOTH].value
                squareSmoothRadiusYleft  = math.abs((prevNodeValue - prevPrevNodeValue)*0.5*tableGUIelements[GUIelement_SMOOTH].value)
                squareSmoothRadiusYright = math.abs((prevNodeValue - nextNodeValue)*0.5*tableGUIelements[GUIelement_SMOOTH].value)
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
        while i <= #tablePPQs and tablePPQs[i] < nextNodePPQ do
            --local newValue
            
            if tablePPQs[i] >= prevNodePPQ and tablePPQs[i] < nextNodePPQ then
            
                -- Determine event values, based on node point shape
                if tableNodes[n].shape == 0 then -- Linear
                    newValue = prevNodeValue + ((tablePPQs[i] - prevNodePPQ)/(nextNodePPQ - prevNodePPQ))*(nextNodeValue - prevNodeValue)
                elseif tableNodes[n].shape == 1 then -- Square
                    newValue = prevNodeValue
                elseif tableNodes[n].shape >= 2 and tableNodes[n].shape < 3 then -- Sine
                    local piMin = (tableNodes[n].shape - 2)*m_pi
                    local piRefVal = m_cos(piMin)+1
                    local piFrac  = piMin + (tablePPQs[i]-prevNodePPQ)/(nextNodePPQ-prevNodePPQ)*(m_pi - piMin)
                    local cosFrac = 1-(m_cos(piFrac)+1)/piRefVal
                    newValue = prevNodeValue + cosFrac*(nextNodeValue-prevNodeValue)
                elseif tableNodes[n].shape >= 3 and tableNodes[n].shape < 4 then -- Inverse parabolic
                    local minVal = 1 - (tableNodes[n].shape - 4)
                    local fracVal = minVal*(tablePPQs[i]-nextNodePPQ)/(prevNodePPQ-nextNodePPQ)
                    local refVal = minVal^3
                    local normFrac = (fracVal^3)/refVal
                    newValue = nextNodeValue + normFrac*(prevNodeValue - nextNodeValue)            
                elseif tableNodes[n].shape >= 4 and tableNodes[n].shape < 5 then -- Parabolic
                    local minVal = tableNodes[n].shape - 4
                    local fracVal = minVal + (tablePPQs[i]-prevNodePPQ)/(nextNodePPQ-prevNodePPQ)*(1 - minVal)
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
                        if tablePPQs[i] < squareSmoothLeftPPQ and tableNodes[n-1].shape == 1 then
                            local radicand = (   1 - ((tablePPQs[i] - squareSmoothLeftPPQ)/squareSmoothRadiusX)^2  ) * (squareSmoothRadiusYleft^2)
                            if radicand < 0 then radicand = 0 end
                            local y = radicand^0.5
                            if prevPrevNodeValue < prevNodeValue then
                                newValue = newValue - squareSmoothRadiusYleft + y
                            else
                                newValue = newValue + squareSmoothRadiusYleft - y
                            end
                        elseif tablePPQs[i] > squareSmoothRightPPQ then
                            local radicand = (   1 - ((tablePPQs[i] - squareSmoothRightPPQ)/squareSmoothRadiusX)^2  ) * (squareSmoothRadiusYright^2)
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
                        if tablePPQs[i] < (prevNodePPQ + nextNodePPQ)/2 then 
                            linearTargetValue = prevNodeValue + slopeAtNodeN * (tablePPQs[i] - prevNodePPQ)
                            -- To get a smooth Bézier-like curve, CCs closer to the nodes must be more strongly affected by the smoothing.
                            -- CCs precisely at the midpoint between nodes will not be affected.
                            -- Possible formulas to use?  Can try quadratic etc.
                            -- distanceWeightedTargetValue = newValue + (1 - (tablePPQs[i] - prevNodePPQ) / ((nextNodePPQ - prevNodePPQ)/2))^2 * (linearTargetValue - newValue)
                            distanceWeightedTargetValue = linearTargetValue + ((tablePPQs[i] - prevNodePPQ) / ((nextNodePPQ - prevNodePPQ)/2)) * (newValue - linearTargetValue)                        
    
                        -- CCs closer to node[n+1]:
                        else
                            linearTargetValue = nextNodeValue + slopeAtNodeNplus1 * (tablePPQs[i] - nextNodePPQ)
                            distanceWeightedTargetValue = linearTargetValue + ((nextNodePPQ - tablePPQs[i]) / ((nextNodePPQ - prevNodePPQ)/2)) * (newValue - linearTargetValue)                        
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
                
                
                -- Ensure that values do not exceed bounds of CC lane
                if newValue < laneMinValue then newValue = laneMinValue
                elseif newValue > laneMaxValue then newValue = laneMaxValue
                else newValue = m_floor(newValue+0.5)
                end
                
                
                -- Insert the MIDI events into REAPER's MIDI stream
                offset = tablePPQs[i]-lastPPQpos
                lastPPQpos = tablePPQs[i]
                
                if laneIsCC7BIT then
                    c = c + 1
                    tableEditedMIDI[c] = s_pack("i4BI4BBB", offset, tableFlags[i], 3, 0xB0 | tableChannels[i], targetLane, newValue)
                elseif laneIsPITCH then
                    c = c + 1
                    tableEditedMIDI[c] = s_pack("i4BI4BBB", offset, tableFlags[i], 3, 0xE0 | tableChannels[i], newValue&127, newValue>>7)
                elseif laneIsCC14BIT then
                    c = c + 1
                    tableEditedMIDI[c] = s_pack("i4BI4BBB", offset, tableFlags[i],    3, 0xB0 | tableChannels[i], targetLane-256, newValue>>7)
                    c = c + 1
                    tableEditedMIDI[c] = s_pack("i4BI4BBB", 0     , tableFlagsLSB[i], 3, 0xB0 | tableChannels[i], targetLane-224, newValue&127)
                elseif laneIsVELOCITY then
                    -- Insert note-on
                    c = c + 1 
                    tableEditedMIDI[c] = s_pack("i4BI4BBB", offset, tableFlags[i], 3, 0x90 | tableChannels[i], tablePitches[i], newValue) 
                    -- Since REAPER v5.32, notation (if it exists) must always be inserted *after* its note-0n
                    if tableNotation[i] then
                        c = c + 1
                        tableEditedMIDI[c] = s_pack("I4Bs4", 0, tableFlags[i]&0xFE, tableNotation[i])
                    end
                    -- Insert note-off
                    c = c + 1
                    tableEditedMIDI[c] = s_pack("i4BI4BBB", tableNoteLengths[i], tableFlags[i], 3, 0x80 | tableChannels[i], tablePitches[i], 0)
                    lastPPQpos = lastPPQpos + tableNoteLengths[i]
                elseif laneIsCHPRESS then
                    c = c + 1
                    tableEditedMIDI[c] = s_pack("i4BI4BB",  offset, tableFlags[i], 2, 0xD0 | tableChannels[i], newValue) -- NB Channel Pressure uses only 2 bytes!
                elseif laneIsPROGRAM then
                    c = c + 1
                    tableEditedMIDI[c] = s_pack("i4BI4BB",  offset, tableFlags[i], 2, 0xC0 | tableChannels[i], newValue) -- NB Channel Pressure uses only 2 bytes!
                end -- if laneIsCC7BIT / laneIsCC14BIT / ...
            i = i + 1
            end -- if tablePPQs[i] >= prevNodePPQ and tablePPQs[i] < nextNodePPQ then
        end -- while i <= #tablePPQs and tablePPQs[i] < nextNodePPQ do
    end -- for n = 1, #tableNodes-1 do
    
    -----------------------------------------------------------
    -- DRUMROLL... write the edited events into the MIDI chunk!
    -- This also updates the offset of the first event in remainMIDIstring relative to the PPQ position of the last event in tableEditedMIDI
    newRemainOffset = remainOffset-lastPPQpos
    reaper.MIDI_SetAllEvts(take, table.concat(tableEditedMIDI)
                                  .. s_pack("i4", newRemainOffset)
                                  .. remainMIDIstringSub5)
    
    if isInline then reaper.UpdateArrange() end

end -- function updateEventValuesAndUploadIntoTake()


-----------------------------------
function parseNotesAndInsertCCs()

    local tableNoteOns = {}
    for flags = 0, 3 do
        tableNoteOns[flags] = {}
        for chan = 0, 15 do
            tableNoteOns[flags][chan] = {}
        end
    end
    local stringPos = 1
    local runningPPQpos = 0
    local MIDIlen = origMIDIstring:len()
    local offset, flags, msg, msg1, eventType, channel, pitch
    while stringPos < MIDIlen do
        offset, flags, msg, stringPos = s_unpack("i4Bs4", origMIDIstring, stringPos)
        runningPPQpos = runningPPQpos + offset
        if flags&1==1 and msg:len() == 3 then
            msg1 = msg:byte(1)
            eventType = msg1>>4
            channel   = msg1&0x0F
            if eventType == 9 and msg:byte(3) ~= 0 then -- Note-ons
                tableNoteOns[flags][channel][msg:byte(2)] = runningPPQpos
            elseif eventType == 8 or (eventType == 9 and msg:byte(3) == 0) then -- Note-offs
                pitch = msg:byte(2)
                if tableNoteOns[flags][channel][pitch] then
                    if tableNoteOns[flags][channel][pitch] < runningPPQpos then
                        deleteCCs(tableNoteOns[flags][channel][pitch], runningPPQpos, channel)
                        insertNewCCs(tableNoteOns[flags][channel][pitch], runningPPQpos, channel)
                    end
                end
            end
        end
    end
    
    -- Sort tablePPQs and tableChannels
    local tableIndices = {}
    for i = 1, #tablePPQs do
        tableIndices[i] = i
    end
    local function sortPPQ(a, b)
        if tablePPQs[a] < tablePPQs[b] then 
            return true 
        elseif tablePPQs[a] == tablePPQs[b] then
            if tableChannels[a] < tableChannels[b] then
                return true
            end
        end
    end
    table.sort(tableIndices, sortPPQ)
    local tempTablePPQs = {}
    local tempTableChannels = {}
    for i = 1, #tablePPQs do
        tempTablePPQs[i] = tablePPQs[tableIndices[i]]
        tempTableChannels[i] = tableChannels[tableIndices[i]]
    end
    local p = 0
    tablePPQs = nil
    tableChannels = nil
    tablePPQs = {}
    tableChannels = {}
    for i = 1, #tempTablePPQs do
        if tempTablePPQs[i] ~= tempTablePPQs[i+1] or tempTableChannels[i] ~= tempTableChannels[i+1] then
            p = p + 1
            tablePPQs[p] = tempTablePPQs[i]
            tableChannels[p] = tempTableChannels[i]
        end
    end        
    
    remainMIDIstringSub5  = remainMIDIstring:sub(5)-- The MIDI that remained, except the very first offset
    remainOffset = s_unpack("i4", remainMIDIstring, 1) -- The very first offset of the remaining events                          
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
            elseif sliderName == "Bezier shape" then tableGUIelements[GUIelement_SMOOTH].value = tonumber(nextStr())
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
            tableGUIelements[100]=make_envelope(borderWidth, envYpos, 0, envHeight, tableGUIelements[1])
        elseif tableGUIelements[100].name == tableGUIelements[2].name then -- "Amplitude"
            tableGUIelements[100]=make_envelope(borderWidth, envYpos, 0, envHeight, tableGUIelements[2])
        else -- "Center"
            tableGUIelements[100]=make_envelope(borderWidth, envYpos, 0, envHeight, tableGUIelements[3])
        end
        
        generateNodes(tableGUIelements[1].value, -- freq
               tableGUIelements[2].value, -- amp
               tableGUIelements[3].value, -- center
               tableGUIelements[4].value, -- phase
               tableGUIelements[5].value, -- randomness
               tableGUIelements[6].value, -- quansteps
               tableGUIelements[7].value, -- tilt
               tableGUIelements[8].value, -- fadindur
               tableGUIelements[9].value, -- fadoutdur
               tableGUIelements[10].value, -- timebase (aka ratemode)
               clip)
               was_changed=true
                              
       -- Draw the envelope in CC lane
       updateEventValuesAndUploadIntoTake()
        
    end -- savedCurves ~= nil and #savedCurves ~= nil and

end -- loadCurve()

  
---------------------------------------------
function constructNewGUI()

    gfx.quit()
    gfx.init("LFO: ".. targetLaneString, initXsize, initYsize,0)
    gfx.setfont(1,"Ariel", 15)
    
    tableGUIelements[1]=make_radiobutton(borderWidth,borderWidth,0,0,0.5,"Rate", function(nx) end)
    GUIelement_RATE = 1
    tableGUIelements[2]=make_radiobutton(borderWidth,borderWidth+GUIelementHeight*1,0,0,0.5,"Amplitude",function(nx) end)
    GUIelement_AMPLITUDE = 2
    tableGUIelements[3]=make_radiobutton(borderWidth,borderWidth+GUIelementHeight*2,0,0,0.5,"Center",function(nx) end)
    GUIelement_CENTER = 3
    tableGUIelements[10]=make_question(borderWidth,borderWidth+GUIelementHeight*3,0,0,0.0,"Timebase?",function(nx) end, "Beats", "Time")
    GUIelement_TIMEBASE = 10
    tableGUIelements[0]=make_menubutton(borderWidth,borderWidth+GUIelementHeight*4,0,0,0.0,"LFO shape?",function(nx) end)
    GUIelement_shape = 0
    --tableGUIelements[11]=make_question(borderWidth,borderWidth+GUIelementHeight*5,0,0,0.0,"Real-time copy to CC?",function(nx) end, "Enabled", "Disabled")
    --GUIelement_copyCC = 11
    -- The following slider was originally named "Phase"
    tableGUIelements[4]=make_slider(borderWidth,borderWidth+GUIelementHeight*5,0,0,0.0,"Phase step",function(nx) end)
    GUIelement_PHASE = 4
    tableGUIelements[5]=make_slider(borderWidth,borderWidth+GUIelementHeight*6,0,0,0.0,"Randomness",function(nx) end)
    GUIelement_RANDOMNESS = 5
    tableGUIelements[6]=make_slider(borderWidth,borderWidth+GUIelementHeight*7,0,0,1.0,"Quantize steps",function(nx) end)
    GUIelement_QUANTSTEPS = 6
    tableGUIelements[7]=make_slider(borderWidth,borderWidth+GUIelementHeight*8,0,0,0.0,"Smoothing",function(nx) end)
    GUIelement_SMOOTH = 7
    tableGUIelements[8]=make_slider(borderWidth,borderWidth+GUIelementHeight*9,0,0,0.0,"Fade in duration",function(nx) end)
    GUIelement_FADEIN = 8
    tableGUIelements[9]=make_slider(borderWidth,borderWidth+GUIelementHeight*10,0,0,0.0,"Fade out duration",function(nx) end)
    GUIelement_FADEOUT = 9
    tableGUIelements[100]=make_envelope(borderWidth, envYpos, 0, envHeight,tableGUIelements[1]) --315-30
    GUIelement_env = 100
      
    --[[for key,tempcontrol in pairs(tableGUIelements) do
      reaper.ShowConsoleMsg(key.." "..tempcontrol.type.." "..tempcontrol.name.."\n")
    end]]
    
end -- constructNewGUI()

------------------------


--####################################################################################
--------------------------------------------------------------------------------------
function parseAndExtractTargetMIDI()
    
    -- If unsorted MIDI is encountered, the function will try to correct it by calling 
    --    "Invert selection" twice, which should invoke the MIDI editor's built-in sorting
    --    algorithm.  This is more reliable than the buggy MIDI_Sort(take) API function.
    -- This will only be tried once, so use flag.
    local haveAlreadyCorrectedOverlaps = false
    
    MIDIstring = origMIDIstring
    
    -- Start again here if sorting was done.
    ::startAgain::
    
    if gotAllOK then
    
        local MIDIlen = MIDIstring:len()
        
        -- These functions are fast, but require complicated parsing of the MIDI string.
        -- The following tables with temporarily store data while parsing:
        local tableNoteOns = {} -- Store note-on position and pitch while waiting for the next note-off, to calculate note length
        local tableTempNotation = {} -- Store notation text while waiting for a note-on with matching position, pitch and channel
        local tableCCMSB = {} -- While waiting for matching LSB of 14-bit CC
        local tableCCLSB = {} -- While waiting for matching MSB of 14-bit CC
        for flags = 0, 3 do
            tableNoteOns[flags] = {}
            for chan = 0, 15 do
                tableNoteOns[flags][chan] = {}
                for pitch = 0, 127 do
                    tableNoteOns[flags][chan][pitch] = {}
                end
            end
        end
        for chan = 0, 15 do
            tableTempNotation[chan] = {}
            tableCCMSB[chan] = {}
            tableCCLSB[chan] = {}
            for pitch = 0, 127 do
                tableTempNotation[chan][pitch] = {}
            end
        end
        
        -- The abstracted info of targeted MIDI events (that will be edited) will be will be stored in
        --    several new tables such as tablePPQs and tableValues.
        -- Clean up these tables in case starting again after sorting.
        --tableMsg = {}
        --tableMsgLSB = {}
        --tableMsgNoteOffs = {}
        --tableValues = {} -- CC values, 14bit CC combined values, note velocities
        tablePPQs = {}
        tableChannels = {}
        tableFlags = {}
        tableFlagsLSB = {} -- In the case of 14bit CCs, mute/select status of the MSB
        tablePitches = {} -- This table will only be filled if laneIsVELOCITY / laneIsPIANOROLL / laneIsOFFVEL / laneIsNOTES
        tableNoteLengths = {}
        tableNotation = {} -- Will only contain entries at those indices where the notes have notation
        
        -- The MIDI strings of non-targeted events will temnporarily be stored in a table, tableRemainingEvents[],
        --    and once all MIDI data have been parsed, this table (which excludes the strings of targeted events)
        --    will be concatenated into remainMIDIstring.
        local tableRemainingEvents = {}    
         
        local runningPPQpos = 0 -- The MIDI string only provides the relative offsets of each event, sp the actual PPQ positions must be calculated by iterating through all events and adding their offsets
        local lastRemainPPQpos = 0 -- PPQ position of last event that was *not* targeted, and therefore stored in tableRemainingEvents.
                
        local prevPos, nextPos, unchangedPos = 1, 1, 1 -- Keep record of position within MIDIstring. unchangedPos is position from which unchanged events van be copied in bulk.
        local c = 0 -- Count index inside tables - strangely, this is faster than using table.insert or even #table+1
        local r = 0 -- Count inside tableRemainingEvents
        local offset, flags, msg -- MIDI data that will be unpacked for each event
        
        ---------------------------------------------------------------
        -- This loop will iterate through the MIDI data, event-by-event
        -- In the case of unselected events, only their offsets are relevant, in order to update runningPPQpos.
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
        --    * First, an upper bound for positions of the targeted events in MIDIstring must be found. 
        --      If such an upper bound can be found, the parser does not need to parse beyond this point,
        --      and the remaining later part of MIDIstring can be stored as is.
        --    * Second, events that are not changed (i.e. not extracted or offset changed) will not be 
        --      inserted individually into tableRemainingEvents, using string.pack.  Instead, they will be 
        --      inserted as blocks of multiple events, copied directly from MIDIstring.  By so doing, the 
        --      number of table writes are lowered, the speed of table.concat is improved, and string.sub
        --      can be used instead of string.pack.
        
        -----------------------------------------------------------------------------------------------------
        -- To get an upper limit for the positions of targeted events in MIDIstring, string.find will be used
        --    to find the posision of the last targeted event in MIDIstring (NB, the *string* posision, not 
        --    the PPQ position.  string.find will search backwards from the end of MIDIstring, using Lua's 
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
        
            local MIDIrev = MIDIstring:reverse()
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
            if laneIsCC7BIT then 
                local msg2string = string.char(targetLane):gsub("[%(%)%.%%%+%-%*%?%[%]%^]", "%%%0") -- Replace magic characters.
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
            elseif laneIsCHPRESS then
                matchStrReversed = table.concat({"[",string.char(0xD0),"-",string.char(0xDF),"]",
                                                           string.pack("I4", 2):reverse(),
                                                       "[",string.char(0x01, 0x03),"]"})                                      
            elseif laneIsCC14BIT then
                local MSBlane = targetLane - 256
                local LSBlane = targetLane - 224
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
        
            firstTargetPosReversed = MIDIstring:reverse():find(matchStrReversed) -- Search backwards by using reversed string. 
        --end
        
        if firstTargetPosReversed then 
            lastTargetStrPos = MIDIlen - firstTargetPosReversed 
        else -- Found no targeted events
            lastTargetStrPos = 0
        end    
        
        ---------------------------------------------------------------------------------------------
        -- OK, got an upper limit.  Not iterate through MIDIstring, until the upper limit is reached.
        while nextPos < lastTargetStrPos do
           
            local mustExtract = false
            local offset, flags, msg
            
            prevPos = nextPos
            offset, flags, msg, nextPos = s_unpack("i4Bs4", MIDIstring, prevPos)
          
            -- Check flag as simple test if parsing is still going OK
            if flags&252 ~= 0 then -- 252 = binary 11111100.
                reaper.ShowMessageBox("The MIDI data uses an unknown format that could not be parsed."
                                      .. "\n\nPlease report the problem in the thread http://forum.cockos.com/showthread.php?t=176878:"
                                      .. "\nFlags = " .. string.format("%02x", flags)
                                      , "ERROR", 0)
                return false
            end
            
            -- Check for unsorted MIDI
            if offset < 0 and prevPos > 1 then   
                -- The bugs in MIDI_Sort have been fixed in REAPER v5.32, so it should be save to use this function.
                if not haveAlreadyCorrectedOverlaps then
                    reaper.MIDI_Sort(take)
                    gotAllOK, MIDIstring = reaper.MIDI_GetAllEvts(take, "")
                    haveAlreadyCorrectedOverlaps = true
                    goto startAgain
                else -- haveAlreadyCorrectedOverlaps == true
                    reaper.ShowMessageBox("Unsorted MIDI data has been detected."
                                          .. "\n\nThe script has tried to sort the data, but was unsuccessful."
                                          .. "\n\nSorting of the MIDI can usually be induced by any simple editing action, such as selecting a note."
                                          , "ERROR", 0)
                    return false
                end
            end         
            
            runningPPQpos = runningPPQpos + offset                 

            -- Only analyze *selected* events - as well as notation text events (which are always unselected)
            if flags&1 == 1 and msg:len() >= 2 then -- bit 1: selected                
                    
                if laneIsCC7BIT then if msg:byte(2) == targetLane and (msg:byte(1))>>4 == 11
                then
                    mustExtract = true
                    c = c + 1 
                    --tableValues[c] = msg:byte(3)
                    tablePPQs[c] = runningPPQpos
                    tableChannels[c] = msg:byte(1)&0x0F
                    tableFlags[c] = flags
                    --tableMsg[c] = msg
                    end 
                                    
                elseif laneIsPITCH then if (msg:byte(1))>>4 == 14
                then
                    mustExtract = true 
                    c = c + 1
                    --tableValues[c] = (msg:byte(3)<<7) + msg:byte(2)
                    tablePPQs[c] = runningPPQpos
                    tableChannels[c] = msg:byte(1)&0x0F
                    tableFlags[c] = flags 
                    --tableMsg[c] = msg        
                    end                           
                                        
                elseif laneIsCC14BIT then 
                    if msg:byte(2) == targetLane-224 and (msg:byte(1))>>4 == 11 -- 14bit CC, only the LSB lane
                    then
                        mustExtract = true
                        local channel = msg:byte(1)&0x0F
                        -- Has a corresponding LSB value already been saved?  If so, combine and save in tableValues.
                        if tableCCMSB[channel][runningPPQpos] then
                            c = c + 1
                            --tableValues[c] = (((tableCCMSB[channel][runningPPQpos].message):byte(3))<<7) + msg:byte(3)
                            tablePPQs[c] = runningPPQpos
                            tableFlags[c] = tableCCMSB[channel][runningPPQpos].flags -- The MSB determines muting
                            tableFlagsLSB[c] = flags
                            tableChannels[c] = channel
                            --tableMsg[c] = tableCCMSB[channel][runningPPQpos].message
                            --tableMsgLSB[c] = msg
                            tableCCMSB[channel][runningPPQpos] = nil -- delete record
                        else
                            tableCCLSB[channel][runningPPQpos] = {message = msg, flags = flags}
                        end
                            
                    elseif msg:byte(2) == targetLane-256 and (msg:byte(1))>>4 == 11 -- 14bit CC, only the MSB lane
                    then
                        mustExtract = true
                        local channel = msg:byte(1)&0x0F
                        -- Has a corresponding LSB value already been saved?  If so, combine and save in tableValues.
                        if tableCCLSB[channel][runningPPQpos] then
                            c = c + 1
                            --tableValues[c] = (msg:byte(3)<<7) + (tableCCLSB[channel][runningPPQpos].message):byte(3)
                            tablePPQs[c] = runningPPQpos
                            tableFlags[c] = flags
                            tableChannels[c] = channel
                            tableFlagsLSB[c] = tableCCLSB[channel][runningPPQpos].flags
                            --tableMsg[c] = msg
                            --tableMsgLSB[c] = tableCCLSB[channel][runningPPQpos].message
                            tableCCLSB[channel][runningPPQpos] = nil -- delete record
                        else
                            tableCCMSB[channel][runningPPQpos] = {message = msg, flags = flags}
                        end
                    end
                  
                -- Note-Offs
                elseif laneIsNOTES then 
                    if ((msg:byte(1))>>4 == 8 or (msg:byte(3) == 0 and (msg:byte(1))>>4 == 9))
                    then
                        local channel = msg:byte(1)&0x0F
                        local msg2 = msg:byte(2)
                        -- Check whether there was a note-on on this channel and pitch.
                        if not tableNoteOns[flags][channel][msg2].index then
                            reaper.ShowMessageBox("There appears to be orphan note-offs (probably caused by overlapping notes or unsorted MIDI data) in the active takes."
                                                  .. "\n\nIn particular, at position " 
                                                  .. reaper.format_timestr_pos(reaper.MIDI_GetProjTimeFromPPQPos(take, runningPPQpos), "", 1)
                                                  .. "\n\nPlease remove these before retrying the script."
                                                  .. "\n\n"
                                                  , "ERROR", 0)
                            return false
                        else
                            mustExtract = true
                            tableNoteLengths[tableNoteOns[flags][channel][msg2].index] = runningPPQpos - tableNoteOns[flags][channel][msg2].PPQ
                            --tableMsgNoteOff[tableNoteOns[flags][channel][msg2].index] = msg
                            tableNoteOns[flags][channel][msg2] = {} -- Reset this channel and pitch
                        end
                                                                    
                    -- Note-Ons
                    elseif (msg:byte(1))>>4 == 9 -- and msg3 > 0
                    then
                        local channel = msg:byte(1)&0x0F
                        local msg2 = msg:byte(2)
                        if tableNoteOns[flags][channel][msg2].index then
                            reaper.ShowMessageBox("There appears to be overlapping notes among the selected notes."
                                                  .. "\n\nIn particular, at position " 
                                                  .. reaper.format_timestr_pos(reaper.MIDI_GetProjTimeFromPPQPos(take, runningPPQpos), "", 1)
                                                  .. "\n\nThe action 'Correct overlapping notes' can be used to correct overlapping notes in the active take."
                                                  , "ERROR", 0)
                            return false
                        else
                            mustExtract = true
                            c = c + 1
                            --tableMsg[c] = msg
                            --tableValues[c] = msg:byte(3)
                            tablePPQs[c] = runningPPQpos
                            tablePitches[c] = msg2
                            tableChannels[c] = channel
                            tableFlags[c] = flags
                            -- Check whether any notation text events have been stored for this unique PPQ, channel and pitch
                            tableNotation[c] = tableTempNotation[channel][msg2][runningPPQpos]
                            -- Store the index and PPQ position of this note-on with a unique key, so that later note-offs can find their matching note-on
                            tableNoteOns[flags][channel][msg2] = {PPQ = runningPPQpos, index = #tablePPQs}
                        end  
                    end
  
                    
                elseif laneIsPROGRAM then if (msg:byte(1))>>4 == 12
                then
                    mustExtract = true
                    c = c + 1
                    --tableValues[c] = msg:byte(2)
                    tablePPQs[c] = runningPPQpos
                    tableChannels[c] = msg:byte(1)&0x0F
                    tableFlags[c] = flags
                    --tableMsg[c] = msg
                    end
                    
                elseif laneIsCHPRESS then if (msg:byte(1))>>4 == 13
                then
                    mustExtract = true
                    c = c + 1
                    --tableValues[c] = msg:byte(2)
                    tablePPQs[c] = runningPPQpos
                    tableChannels[c] = msg:byte(1)&0x0F
                    tableFlags[c] = flags
                    --tableMsg[c] = msg
                    end
                    
                end  
                
            end -- if laneIsCC7BIT / CC14BIT / PITCH etc    
            
            -- Check notation text events
            if laneIsNOTES 
            and msg:byte(1) == 0xFF -- MIDI text event
            and msg:byte(2) == 0x0F -- REAPER's notation event type
            then
                -- REAPER v5.32 changed the order of note-ons and notation events. So must search backwards as well as forward.
                local notationChannel, notationPitch = msg:match("NOTE (%d+) (%d+) ") 
                if notationChannel then
                    notationChannel = tonumber(notationChannel)
                    notationPitch   = tonumber(notationPitch)
                    -- First, backwards through notes that have already been parsed.
                    for i = #tablePPQs, 1, -1 do
                        if tablePPQs[i] ~= runningPPQpos then 
                            break -- Go on to forward search
                        else
                            if tableChannels[i] == notationChannel
                            and tablePitches[i] == notationPitch
                            then
                                tableNotation[i] = msg
                                mustExtract = true
                                goto completedNotationSearch
                            end
                        end
                    end
                    -- Search forward through following events, looking for a selected note that match the channel and pitch
                    local evPos = nextPos -- Start search at position of nmext event in MIDI string
                    local evOffset, evFlags, evMsg
                    repeat -- repeat until an offset is found > 0
                        evOffset, evFlags, evMsg, evPos = s_unpack("i4Bs4", MIDIstring, evPos)
                        if evOffset == 0 then 
                            if evFlags&1 == 1 -- Only match *selected* events
                            and evMsg:byte(1) == 0x90 | notationChannel -- Match note-ons and channel
                            and evMsg:byte(2) == notationPitch -- Match pitch
                            and evMsg:byte(3) ~= 0 -- Note-ons with velocity == 0 are actually note-offs
                            then
                                -- Store this notation text with unique key so that future selected notes can find their matching notation
                                tableTempNotation[notationChannel][notationPitch][runningPPQpos] = msg
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
                    tableRemainingEvents[r] = MIDIstring:sub(unchangedPos, prevPos-1)
                end
                unchangedPos = nextPos
                mustUpdateNextOffset = true
            elseif mustUpdateNextOffset then
                r = r + 1
                tableRemainingEvents[r] = s_pack("i4Bs4", runningPPQpos-lastRemainPPQpos, flags, msg)
                lastRemainPPQpos = runningPPQpos
                unchangedPos = nextPos
                mustUpdateNextOffset = false
            else
                lastRemainPPQpos = runningPPQpos
            end
    
        end -- while    
        
        
        -- Now insert all the events to the right of the targets as one bulk
        if mustUpdateNextOffset then
            offset = s_unpack("i4", MIDIstring, nextPos)
            runningPPQpos = runningPPQpos + offset
            r = r + 1
            tableRemainingEvents[r] = s_pack("i4", runningPPQpos - lastRemainPPQpos) .. MIDIstring:sub(nextPos+4) 
        else
            r = r + 1
            tableRemainingEvents[r] = MIDIstring:sub(unchangedPos) 
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
        
        if #tablePPQs == 0 then -- Nothing to extract, so don't need to concatenate tableRemainingEvents
            remainOffset = s_unpack("i4", MIDIstring, 1)
            remainMIDIstring = MIDIstring
            remainMIDIstringSub5 = MIDIstring:sub(5)
            return true 
        end         

        
        -- Now check that the number of LSB and MSB events were nicely balanced. If they are, these tables should be empty
        if laneIsCC14BIT then
            for chan = 0, 15 do
                for key, value in pairs(tableCCLSB[chan]) do
                    reaper.ShowMessageBox("There appears to be selected CCs in the LSB lane that do not have corresponding CCs in the MSB lane."
                                          .. "\n\nThe script does not know whether these CCs should be included in the edits, so please deselect these before retrying the script.", "ERROR", 0)
                    return false
                end
                for key, value in pairs(tableCCMSB[chan]) do
                    reaper.ShowMessageBox("There appears to be selected CCs in the MSB lane that do not have corresponding CCs in the LSB lane."
                                          .. "\n\nThe script does not know whether these CCs should be included in the edits, so please deselect these before retrying the script.", "ERROR", 0)
                    return false
                end
            end
        end    
            
        -- Check that every note-on had a corresponding note-off
        if (laneIsNOTES) and #tableNoteLengths ~= #tablePPQs then
            reaper.ShowMessageBox("There appears to be an imbalanced number of note-ons and note-offs.", "ERROR", 0)
            return false 
        end
        
        -- Calculate original PPQ ranges and extremes
        -- * THIS ASSUMES THAT THE MIDI DATA IS SORTED *
        if includeNoteOffsInPPQrange and laneIsNOTES then
            origPPQleftmost  = tablePPQs[1]
            origPPQrightmost = tablePPQs[#tablePPQs] -- temporary
            local noteEndPPQ
            for i = 1, #tablePPQs do
                noteEndPPQ = tablePPQs[i] + tableNoteLengths[i]
                if noteEndPPQ > origPPQrightmost then origPPQrightmost = noteEndPPQ end
            end
            origPPQrange = origPPQrightmost - origPPQleftmost
        else
            origPPQleftmost  = tablePPQs[1]
            origPPQrightmost = tablePPQs[#tablePPQs]
            origPPQrange     = origPPQrightmost - origPPQleftmost
        end                    
        
        ------------------------
        -- Fiinally, return true
        -- When concatenating tableRemainingEvents, leave out the first remaining event's offset (first 4 bytes), 
        --    since this offset will be updated relative to the edited events' positions during each cycle.
        -- (The edited events will be inserted in the string before all the remaining events.)
        remainMIDIstring = table.concat(tableRemainingEvents)
        remainMIDIstringSub5 = remainMIDIstring:sub(5)
        remainOffset = s_unpack("i4", remainMIDIstring, 1)
        return true
        
    else -- if not gotAllOK
        reaper.ShowMessageBox("MIDI_GetAllEvts could not load the raw MIDI data.", "ERROR", 0)
        return false 
    end

end



---------------------------------------

function deleteCCs(PPQstart, PPQend, channel) 
    -- The remaining events and the newly assembled events will be stored in these table
    local tableRemainingEvents = {}
    local r = 0
    local stringPos = 1
    local runningPPQpos = 0
    local MIDIlen = remainMIDIstring:len()
    local offset, flags, msg, mustDelete
    while stringPos < MIDIlen do
        mustDelete = false
        offset, flags, msg, stringPos = s_unpack("i4Bs4", remainMIDIstring, stringPos)
        runningPPQpos = runningPPQpos + offset
        if runningPPQpos >= PPQstart and runningPPQpos < PPQend then
            if laneIsCC7BIT       then if msg:byte(1) == (0xB0 | channel) and msg:byte(2) == targetLane then mustDelete = true end
            elseif laneIsPITCH    then if msg:byte(1) == (0xE0 | channel) then mustDelete = true end
            elseif laneIsCC14BIT  then if msg:byte(1) == (0xB0 | channel) and (msg:byte(2) == targetLane-224 or msg:byte(2) == targetLane-256) then mustDelete = true end
            elseif laneIsPROGRAM  then if msg:byte(1) == (0xC0 | channel) then mustDelete = true end
            elseif laneIsCHPRESS  then if msg:byte(1) == (0xD0 | channel) then mustDelete = true end
            end         
        end 
        
        if mustDelete then
            r = r + 1
            tableRemainingEvents[r] = s_pack("i4Bs4", offset, flags, "")
        else
            r = r + 1
            tableRemainingEvents[r] = s_pack("i4Bs4", offset, flags, msg)
        end
    end
    remainMIDIstring = table.concat(tableRemainingEvents)
end


-- This function ADDS items to tablePPQs and other tables.
function insertNewCCs(PPQstart, PPQend, channel)
    
    -- Since v2.01, first CC will be inserted at first tick within time selection, even if it does not fall on a beat, to ensure that the new LFO value is applied before any note is played.

    i = #tablePPQs + 1
    tablePPQs[i] = math.ceil(PPQstart)
    tableChannels[i] = channel
    tableFlags[i] = 1
    tableFlagsLSB[i] = 1
        
    -- Get first insert position at CC density 'grid' beyond PPQstart
    local QNstart = reaper.MIDI_GetProjQNFromPPQPos(take, PPQstart)
    -- For improved accuracy, do not round firstCCinsertPPQpos yet
    local firstCCinsertPPQpos = reaper.MIDI_GetPPQPosFromProjQN(take, QNperCC*(math.ceil(QNstart/QNperCC)))
    if math.floor(firstCCinsertPPQpos+0.5) <= math.ceil(PPQstart) then firstCCinsertPPQpos = firstCCinsertPPQpos + PPperCC end
        
    -- PPQend is actually beyond time selection, so "-1" to prevent insert at PPQend
    --i = #tablePPQs
    for p = firstCCinsertPPQpos, PPQend-1, PPperCC do
        local insertPPQpos = math.floor(p + 0.5)      
        i = i + 1
        tablePPQs[i] = insertPPQpos
        tableChannels[i] = channel
        tableFlags[i] = 1
        tableFlagsLSB[i] = 1
    end
            
end -- insertNewCCs(startPPQ, endPPQ, channel)

-------------------------------------

--############################################################################################
----------------------------------------------------------------------------------------------
-- HERE CODE EXECUTION STARTS

-- function main()
 
   
-- Start with a trick to avoid automatically creating undo states if nothing actually happened
-- Undo_OnStateChange will only be used if reaper.atexit(onexit) has been executed
function avoidUndo()
end
reaper.defer(avoidUndo)

------------------------------------------------
-- Check whether user-defined values are usable.
--[[if type(verbose) ~= "boolean" then 
    reaper.ShowMessageBox("The setting 'verbose' must be either 'true' of 'false'.", "ERROR", 0) return(false) end]]
if laneToUse ~= "last clicked" and laneToUse ~= "under mouse" then 
    reaper.ShowMessageBox('The setting "laneToUse" must be either "last clicked" or "under mouse".', "ERROR", 0) return(false) end
if selectionToUse ~= "time" and selectionToUse ~= "notes" and selectionToUse ~= "existing" then 
    reaper.ShowMessageBox('The setting "selectionToUse" must be either "time", "notes" or "existing".', "ERROR", 0) return(false) end
if type(defaultCurveName) ~= "string" then
    reaper.ShowMessageBox("The setting 'defaultCurveName' must be a string.", "ERROR", 0) return(false) end
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
    reaper.ShowMessageBox("The custom interface colors must each be a table of four values between 0 and 1.", "ERROR", 0) 
    return(false) 
    end
if type(shadows) ~= "boolean" then 
    reaper.ShowMessageBox("The setting 'shadows' must be either 'true' of 'false'.", "ERROR", 0) return(false) end
if type(fineAdjust) ~= "number" or fineAdjust < 0 or fineAdjust > 1 then
    reaper.ShowMessageBox("The setting 'fineAdjust' must be a number between 0 and 1.", "ERROR", 0) return(false) end
if type(phaseStepsDefault) ~= "number" or phaseStepsDefault % 4 ~= 0 or phaseStepsDefault <= 0 then
    reaper.ShowMessageBox("The setting 'phaseStepsDefault' must be a positive multiple of 4.", "ERROR", 0) return(false) 
end
    
    
-------------------------------------------------------------
-- Check whether the required version of REAPER is available.
version = tonumber(reaper.GetAppVersion():match("(%d+%.%d+)"))
if version == nil or version < 5.32 then
    reaper.ShowMessageBox("This version of the script requires REAPER v5.32 or higher."
                          .. "\n\nOlder versions of the script will work in older versions of REAPER, but may be slow in takes with many thousands of events"
                          , "ERROR", 0)
    return(false)
end


------------------------------------------------------
-- If laneToUse == "under mouse" then SWS is required.
if laneToUse == "under mouse" then
    if not reaper.APIExists("BR_GetMouseCursorContext") then
        reaper.ShowMessageBox("This script requires the SWS/S&M extension.\n\nThe SWS/S&M extension can be downloaded from www.sws-extension.org.", "ERROR", 0)
        return(false) 
    end 
    window, segment, details = reaper.BR_GetMouseCursorContext()
    if not (segment == "notes" or segment == "cc_lane") then
        reaper.ShowMessageBox('The mouse is not correctly positioned.'
                              .. '\n\nIf the "lane_to_use" setting is "under mouse", the mouse must be positioned over a CC lane of a MIDI editor when the script starts.', "ERROR", 0)
        return(false)
    end
    -- SWS version 2.8.3 has a bug in the crucial function "BR_GetMouseCursorContext_MIDI"
    -- https://github.com/Jeff0S/sws/issues/783
    -- For compatibility with 2.8.3 as well as other versions, the following lines test the SWS version for compatibility
    _, testParam1, _, _, _, testParam2 = reaper.BR_GetMouseCursorContext_MIDI()
    if type(testParam1) == "number" and testParam2 == nil then SWS283 = true else SWS283 = false end
    if type(testParam1) == "boolean" and type(testParam2) == "number" then SWS283again = false else SWS283again = true end 
    if SWS283 ~= SWS283again then
        reaper.ShowMessageBox("Could not determine compatible SWS version.", "ERROR", 0)
        return(false)
    end
    if SWS283 == true then
        isInline, _, targetLane, _, _ = reaper.BR_GetMouseCursorContext_MIDI()
    else 
        _, isInline, _, targetLane, _, _ = reaper.BR_GetMouseCursorContext_MIDI()
    end 
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
gotAllOK, origMIDIstring = reaper.MIDI_GetAllEvts(take, "")
if not gotAllOK then
    reaper.ShowMessageBox("MIDI_GetAllEvts could not load the raw MIDI data.", "ERROR", 0)
    return false 
end
remainMIDIstring = origMIDIstring -- remainMIDIstring may change after MIDI_Sort, deletion etc, but origMIDIstring will remain. In case of errors, origMIDIstring will return the take to its original state.


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
    time_start = reaper.MIDI_GetProjTimeFromPPQPos(take, timeSelPPQstart)
    time_end = reaper.MIDI_GetProjTimeFromPPQPos(take, timeSelPPQend)
    deleteCCs(timeSelPPQstart, timeSelPPQend, defaultChannel)
    insertNewCCs(timeSelPPQstart, timeSelPPQend, defaultChannel)
    remainMIDIstringSub5  = remainMIDIstring:sub(5)-- The MIDI that remained, except the very first offset
    remainOffset = s_unpack("i4", remainMIDIstring, 1) -- The very first offset of the remaining events

elseif selectionToUse == "notes" then
    parseNotesAndInsertCCs()
    if #tablePPQs < 3 or origPPQrange == 0 then
        reaper.ShowMessageBox("Could not find selected notes of sufficient length.", "ERROR", 0)
        return(false)
    end
    time_start = reaper.MIDI_GetProjTimeFromPPQPos(take, tablePPQs[1])
    time_end = reaper.MIDI_GetProjTimeFromPPQPos(take, tablePPQs[#tablePPQs])    

else -- selectionToUse == "existing"
    if not parseAndExtractTargetMIDI() then
        return(false)
    end        
    if #tablePPQs < 3 or origPPQrange == 0 then
        reaper.ShowMessageBox("Could not find a sufficient number of selected events in the target lane.", "ERROR", 0)
        return(false)
    end
    time_start = reaper.MIDI_GetProjTimeFromPPQPos(take, tablePPQs[1])
    time_end = reaper.MIDI_GetProjTimeFromPPQPos(take, tablePPQs[#tablePPQs])
end        
                

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
