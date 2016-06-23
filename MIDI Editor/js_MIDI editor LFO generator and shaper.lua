--[[
 * ReaScript Name: js_MIDI editor LFO generator and shaper.lua
 * Description: LFO generator and shaper - MIDI editor version
 *              Draw fancy LFO curves in REAPER's piano roll.
 * Instructions:  
 *         DRAWING ENVELOPES
 *         Leftclick in open space in the envelope drawing area to add an envelope node.
 *         Shift + Leftdrag to add multiple envelope nodes.
 *         Alt + Leftclick (or -drag) to delete nodes.
 *         Rightclick on an envelope node to open a dialog box in which a precise custom value can be entered.
 *         Move mousewheel while mouse hovers above node for fine adjustment.
 * 
 *         Use a Ctrl modifier to edit all nodes simultaneously:
 *         Ctrl + Leftclick (or -drag) to set all nodes to the mouse Y position.
 *         Ctrl + Rightclick to enter a precise custom value for all nodes.
 *         Ctrl + Mousewheel for fine adjustment of all nodes simultaneously.
 *
 *         VALUE AND TIME DISPLAY
 *         The precise Rate, Amplitude or Center of the hot node, as well as the precise time position, can be displayed above the node.
 *         Rightclick in open space in the envelope area to open a menu in which the Rate and time display formats can be selected.
 *
 *         LOADING AND SAVING CURVES
 *         Right-click (outside envelope area) to open the Save/Load/Delete curve menu.
 *         One of the saved curves can be loaded automatically at startup. By default, this curve must be named "default".
 *                           
 *         FURTHER CUSTOMIZATION
 *         Further customization is possible - see the instructions in the script's USER AREA.
 *         This include:
 *         - Easily adding custom LFO shapes.
 *         - Specifying the resolution of LFO shapes' phase steps.
 *         - Specifying the resolution of the mousewheel fine adjustment.
 *         - Changing interface colors.
 *         - Changing the default curve name.
 *         etc...      
 * 
 * Screenshot: 
 * Notes: 
 * Category: 
 * Author: Xenakios / juliansader
 * Licence: GPL v3
 * Forum Thread:
 * Forum Thread URL: http://forum.cockos.com/showthread.php?t=153348&page=5
 * Version: 1.04
 * REAPER: 5.20
 * Extensions: SWS/S&M 2.8.3
]]

--[[
 Changelog:
 * v1.04 (2016-06-23)
    + User can specify the number of phase steps in standard LFO shapes, which allows nearly continuous phase changes.
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
    -- "notes" to fill areas underneath selected notes, or "time" for time selection
    --    If "time", script can be linked to a mouse modifier such as double-click.
    -- It may suit workflow to save two versions of the script: one that can be used to 
    --    insert CCs underneath selected notes, and one that inserts an LFO in the time 
    --    selection.
    selectionToUse = "time" 
    
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
    
    -- Should the script show error messages in REAPER's console?  
    --    Set to true or false.
    verbose = true
    
    -- If set to false, CCs in channels other than the LFO's channel will not be deleted.
    -- NOTE: If selectionToUse == "notes", the newly inserted CCs will have the same channel 
    --    as the note under which they are inserted. 
    deleteOnlyDrawChannel = true
    
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

---------------------------------------------
-- Some global constants used in Julian's mod
shapeSelected = 6 -- Starting shape
sliderHeight = 28
borderWidth = 10
envHeight = 190
initXsize = 209 --300 -- Initial sizes for the GUI
initYsize = borderWidth + sliderHeight*11 + envHeight + 45
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
                 
-- laneTypes         
CC7BIT = 0
CHANPRESSURE = 1
PITCH = 2
CC14BIT = 3

-- mouse_cap values
NOTHING = 0
LEFTBUTTON = 1
RIGHTBUTTON = 2
CTRLKEY = 4
SHIFTKEY = 8
ALTKEY = 16
WINKEY = 32
MIDDLEBUTTON = 64

-- For 7-bit lanes, will later be divided by 128
minv = 0
maxv = 16383
---------------------------------------------

------------------------------------------------------------------------
-- Reader beware: there is lots of cruft remaining in this script
--    since it is an unfinished script that was later hacked and modded.

egsliders={}

notevalues={{1,8,"32nd"},
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

---------------------------------------------------------------
-- Julian's mod: these new "make_" functions are basically just 
--    copies of the original "make_slider" function, but with
--    new "type".  Irrelevant stuff such as slider.envelope were left
--    untouched in case there is a reference to these stuff in the
--    rest of the code. 
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
    stepSize = math.floor(0.5 + (maxv-minv)/numsteps)
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

function draw_slider(slid)
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
        if slid.name == egsliders[100].name then
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
                if egsliders[slidNum_timebase].value == 1 then -- Timebase == Beats
                    local timeStartQN = reaper.TimeMap_timeToQN(time_start)
                    local timeEndQN = reaper.TimeMap_timeToQN(time_end)
                    timeAtNode = reaper.TimeMap_QNToTime(timeStartQN + envpoint[1]*(timeEndQN-timeStartQN))
                else
                    timeAtNode = time_start + envpoint[1]*(time_end - time_start)
                end
            else -- Just in case no envelope selected, or update() has not yet been run, or something.
                timeAtNode = 0
            end
            
            -- If Rate envelope, display either period or frequency above hotpoint
            if env.name == "Rate" then
                
                if egsliders[slidNum_timebase].value >= 0.5 and hotpointRateDisplayType == "period note length" then
                    local pointRate = beatBaseMin + (beatBaseMax - beatBaseMin)*(envpoint[2]^2)
                    local pointRateInverse = 1.0/pointRate
                    if pointRateInverse == math.floor(pointRateInverse) then hotString = string.format("%i", tostring(pointRateInverse))
                    elseif pointRate == math.floor(pointRate) then hotString = "1/" .. string.format("%i", tostring(pointRate))
                    elseif pointRate > 1 then hotString = "1/" .. string.format("%.3f", tostring(pointRate))
                    else hotString = string.format("%.3f", tostring(pointRateInverse))
                    end
                elseif egsliders[slidNum_timebase].value >= 0.5 and hotpointRateDisplayType == "frequency" then
                    local bpm = getBPM(timeAtNode)
                    local pointRate = beatBaseMin + (beatBaseMax - beatBaseMin)*(envpoint[2]^2)
                    local pointFreq = (1.0/240) * pointRate * bpm
                    hotString = string.format("%.3f", tostring(pointFreq)) .. "Hz"
                elseif egsliders[slidNum_timebase].value < 0.5 and hotpointRateDisplayType == "period note length" then
                    local bpm = getBPM(timeAtNode)
                    local pointFreq = timeBaseMin + (timeBaseMax-timeBaseMin)*(envpoint[2]^2)
                    local pointRate = (1.0/bpm) * pointFreq * 240 -- oscillations/sec * sec/min * min/beat * beats/wholenote
                    local pointRateInverse = 1.0/pointRate
                    if pointRateInverse == math.floor(pointRateInverse) then hotString = string.format("%i", tostring(pointRateInverse))
                    elseif pointRate == math.floor(pointRate) then hotString = "1/" .. string.format("%i", tostring(pointRate))
                    elseif pointRate > 1 then hotString = "1/" .. string.format("%.3f", tostring(pointRate))
                    else hotString = string.format("%.3f", tostring(pointRateInverse))
                    end
                elseif egsliders[slidNum_timebase].value < 0.5 and hotpointRateDisplayType == "frequency" then -- hotpointRateDisplayType == "frequency"
                    local pointFreq = timeBaseMin+((timeBaseMax-timeBaseMin)*(envpoint[2])^2.0)
                    hotString = string.format("%.3f", tostring(pointFreq)) .. "Hz"
                end
                hotString = "R =" .. hotString
                
            -- If Amplitude or Center, display value scaled to actual envelope range.
            -- (The BRenvMaxValue and BRenvMinValue variables are calculated in the update() function.)
            elseif env.name == "Amplitude" then
                hotString = "A =" .. string.format("%.0f", tostring(envpoint[2]*0.5*(BRenvMaxValue-BRenvMinValue)))
            else -- env.name == "Center"
                hotString = "C =" .. string.format("%.0f", tostring(BRenvMinValue + envpoint[2]*(BRenvMaxValue-BRenvMinValue)))
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
function generate(freq,amp,center,phase,randomness,quansteps,tilt,fadindur,fadoutdur,ratemode,clip)

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

        freq_norm_to_use = get_env_interpolated_value(egsliders[1].envelope,time_to_interp, rateInterpolationType)
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
            amp_to_use = get_env_interpolated_value(egsliders[2].envelope,time_to_interp, "linear")
            --if amp_to_use<0.0 or amp_to_use>1.0 then reaper.ShowConsoleMsg(amp_to_use.." ") end
            val=0.5+(0.5*amp_to_use*fade_gain)*val
            local center_to_use=get_env_interpolated_value(egsliders[3].envelope,time_to_interp, "linear")
            local rangea=maxv-minv
            val=minv+((rangea*center_to_use)+(-rangea/2.0)+(rangea/1.0)*val)
            local z=(2*math.random()-1)*randomness*(maxv-minv)/2
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
            
                      
            val=bound_value(minv,val,maxv)
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
                oppositeVal=minv+((rangea*center_to_use)+(-rangea/2.0)+(rangea/1.0)*oppositeVal)
                oppositeVal=oppositeVal-z
                --[[if quansteps ~= 1 then
                    val=quantize_value(val,3 + math.ceil(quansteps*125))
                end]]
                oppositeVal=bound_value(minv,oppositeVal,maxv)
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
    
    if sectionID ~= nil and cmdID ~= nil and sectionID ~= -1 and cmdID ~= -1 then
        reaper.SetToggleCommandState(sectionID, cmdID, 0)
        reaper.RefreshToolbar2(sectionID, cmdID)
    end
    
    --[[    
    if laneType == CC7BIT then
        reaper.Undo_OnStateChange("LFO tool: 7-bit CC lane ".. clickedLane, -1)
    elseif laneType == CHANPRESSURE then
        reaper.Undo_OnStateChange("LFO tool: channel pressure", -1)
    elseif laneType == CC14BIT then
        reaper.Undo_OnStateChange("LFO tool: 14 bit CC lanes ".. 
                                  tostring(clickedLane-256) .. "/" .. tostring(clickedLane-224))
    elseif laneType == PITCH then
        reaper.Undo_OnStateChange("LFO tool: pitchwheel", -1)
    end
    ]]
    reaper.Undo_OnStateChange("LFO tool: ".. clickedLaneString, -1)
end -- function exit() 

----------------------


-------------------------------
function showErrorMsg(errorMsg)
    if verbose == true and type(errorMsg) == "string" then
        reaper.ShowConsoleMsg("\n\nERROR:\n" 
                              .. errorMsg 
                              .. "\n\n"
                              .. "(To prevent future error messages, set 'verbose' to 'false' in the USER AREA near the beginning of the script.)"
                              .. "\n\n")
    end
end -- showErrorMsg(errorMsg)


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

function update()

    ---------------------------------------------------------------------------
    -- First, go through several tests to detect whether the script should exit
    -- 1) Quit script if GUI has been closed, or Esc has been pressed
    local char = gfx.getchar()
    if char<0 or char==27 then 
        return(0)
    end 
    
    -- 2) The LFO Tool automatically quits if the time selection, the note selection, or the last clicked lane changes, 
    --    which prepares the editor to insert a new LFO.
    --    (Clicking in the piano roll to select new notes changes the "last clicked lane".)
    local newEditor = reaper.MIDIEditor_GetActive()
    if newEditor ~= editor then return(0) end
    local newTake = reaper.MIDIEditor_GetTake(newEditor)
    if newTake ~= take then return(0) end
    
    if laneToUse == "last clicked" then
        newClickedLane = reaper.MIDIEditor_GetSetting_int(newEditor, "last_clicked_cc_lane")   
        if newClickedLane ~= clickedLane then
            return(0)
        end
    end
    --if selectionToUse == "time" then
        time_start_new, time_end_new = reaper.GetSet_LoopTimeRange(false, false, 0.0, 0.0, false)
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
    for key,tempcontrol in pairs(egsliders) do
    
      --if key>=200 and tempcontrol.type=="Button" then reaper.ShowConsoleMsg(tostring(tempcontrol).." ") end
      if is_in_rect(gfx.mouse_x,gfx.mouse_y,tempcontrol.x(),tempcontrol.y(),tempcontrol.w(),tempcontrol.h()) 
      or (key == slidNum_env and is_in_rect(gfx.mouse_x,gfx.mouse_y,0,tempcontrol.y()-15,gfx.w,tempcontrol.h()+22))
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
              egsliders[100].envelope=tempcontrol.envelope
              egsliders[100].name=tempcontrol.name
            end
          end
          ]]
        
            -- Click on Rate/Center/Amplitude buttons to change envelope type
            if gfx.mouse_cap==LEFTBUTTON and (tempcontrol.name=="Rate" or tempcontrol.name=="Amplitude" or tempcontrol.name=="Center") then
                egsliders[100].envelope=tempcontrol.envelope
                egsliders[100].name=tempcontrol.name
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
                    
                  if userNoteFound == true and egsliders[slidNum_timebase].value == 0 
                      and type(time_end) == "number" and type(time_start) == "number" and time_start<=time_end then
                      for i = 1, #tempcontrol.envelope do
                          local bpm = getBPM(time_start + tempcontrol.envelope[i][1]*(time_end-time_start))
                          local userFreq = (1.0/240) * userNote * bpm
                          tempcontrol.envelope[i][2] = math.min(1, math.max(0, ((1.0/(timeBaseMax - timeBaseMin)) * (userFreq-timeBaseMin))^(0.5)))
                      end
                      dogenerate = true
                  elseif userFreqFound == true and egsliders[slidNum_timebase].value == 0 then
                      local normalizedValue = ((1.0/(timeBaseMax - timeBaseMin)) * (userFreq-timeBaseMin))^(0.5)
                      for i = 1, #tempcontrol.envelope do
                          tempcontrol.envelope[i][2] = math.min(1, math.max(0, normalizedValue))
                      end
                      dogenerate = true
                  elseif userNoteFound == true and egsliders[slidNum_timebase].value == 1 then
                      local normalizedValue = ((1.0/(beatBaseMax - beatBaseMin)) * (userNote-beatBaseMin))^(0.5)
                      for i = 1, #tempcontrol.envelope do
                          tempcontrol.envelope[i][2] = math.min(1, math.max(0, normalizedValue))
                      end
                      dogenerate = true
                  elseif userFreqFound == true and egsliders[slidNum_timebase].value == 1 
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
                  
                  if userNoteFound == true and egsliders[slidNum_timebase].value == 0 
                      and type(time_end) == "number" and type(time_start) == "number" and time_start<=time_end then
                      local bpm = getBPM(time_start + tempcontrol.envelope[tempcontrol.hotpoint][1]*(time_end-time_start))
                      local userFreq = (1.0/240.0) * userNote * bpm
                      tempcontrol.envelope[tempcontrol.hotpoint][2] = math.min(1, math.max(0, ((1.0/(timeBaseMax - timeBaseMin)) * (userFreq-timeBaseMin))^(0.5)))
                      dogenerate = true                                            
                  elseif userFreqFound == true and egsliders[slidNum_timebase].value == 0 then
                      tempcontrol.envelope[tempcontrol.hotpoint][2] = math.min(1, math.max(0, ((1.0/(timeBaseMax - timeBaseMin)) * (userFreq-timeBaseMin))^(0.5)))
                      dogenerate = true
                  elseif userNoteFound == true and egsliders[slidNum_timebase].value == 1 then
                      tempcontrol.envelope[tempcontrol.hotpoint][2] = math.min(1, math.max(0, ((1.0/(beatBaseMax - beatBaseMin)) * (userNote-beatBaseMin))^(0.5)))
                      dogenerate = true
                  elseif userFreqFound == true and egsliders[slidNum_timebase].value == 1 
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
              if captured_control.envelope==egsliders[100].envelope then 
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
      
      draw_slider(tempcontrol)
      draw_envelope(tempcontrol,env_enabled)
    end -- for key,tempcontrol in pairs(egsliders)
  
  ---------------------------------------------
  -- If right-click, show save/load/delete menu
  -- (But not if in envelope drawing area)
  if gfx.mouse_cap == RIGHTBUTTON and not is_in_rect(gfx.mouse_x,
                                                     gfx.mouse_y,
                                                     0, --egsliders[100].x(),
                                                     egsliders[100].y(),
                                                     gfx.w, --egsliders[100].w(),
                                                     gfx.h - egsliders[100].y()) --egsliders[100].h()) 
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
            egsliders[slidNum_rate].envelope = {{0,0.5}, {1,0.5}}
            egsliders[slidNum_amp].envelope = {{0,0.5}, {1,0.5}}
            egsliders[slidNum_center].envelope = {{0,0.5}, {1,0.5}}
            dogenerate = true
            
            -------------------------------------------------------
            -- Draw the newly loaded envelope
            if egsliders[100].name == egsliders[1].name then -- "Rate"
                egsliders[100]=make_envelope(borderWidth, envYpos, 0, envHeight, egsliders[1])
            elseif egsliders[100].name == egsliders[2].name then -- "Amplitude"
                egsliders[100]=make_envelope(borderWidth, envYpos, 0, envHeight, egsliders[2])
            else -- "Center"
                egsliders[100]=make_envelope(borderWidth, envYpos, 0, envHeight, egsliders[3])
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
                    if egsliders[i] == nil then -- skip
                    elseif egsliders[i].name == "LFO shape?" then saveString = saveString .. ",LFO shape?," .. tostring(shapeSelected)
                    --elseif egsliders[i].name == "Real-time copy to CC?" then saveString = saveString .. ",Real-time copy to CC?," .. tostring(egsliders[i].enabled) 
                    elseif egsliders[i].name == "Phase step" then saveString = saveString .. ",Phase step," .. tostring(egsliders[i].value)
                    elseif egsliders[i].name == "Randomness" then saveString = saveString .. ",Randomness," .. tostring(egsliders[i].value)
                    elseif egsliders[i].name == "Quant steps" then saveString = saveString .. ",Quant steps," .. tostring(egsliders[i].value)
                    elseif egsliders[i].name == "Bezier shape" then saveString = saveString .. ",Bezier shape," .. tostring(egsliders[i].value)
                    elseif egsliders[i].name == "Fade in duration" then saveString = saveString .. ",Fade in duration," .. tostring(egsliders[i].value)
                    elseif egsliders[i].name == "Fade out duration" then saveString = saveString .. ",Fade out duration," .. tostring(egsliders[i].value)
                    elseif egsliders[i].name == "Timebase?" then saveString = saveString .. ",Timebase?," .. tostring(egsliders[i].value)
                    elseif egsliders[i].name == "Rate" then 
                        saveString = saveString .. ",Rate,"  .. tostring(#egsliders[i].envelope)
                        for p = 1, #egsliders[i].envelope do
                            saveString = saveString .. "," .. tostring(egsliders[i].envelope[p][1]) .. "," 
                                                           .. tostring(egsliders[i].envelope[p][2])
                        end
                    elseif egsliders[i].name == "Center" then 
                        saveString = saveString .. ",Center,"  .. tostring(#egsliders[i].envelope)
                        for p = 1, #egsliders[i].envelope do
                            saveString = saveString .. "," .. tostring(egsliders[i].envelope[p][1]) .. "," 
                                                           .. tostring(egsliders[i].envelope[p][2])
                        end
                    elseif egsliders[i].name == "Amplitude" then 
                        saveString = saveString .. ",Amplitude,"  .. tostring(#egsliders[i].envelope)
                        for p = 1, #egsliders[i].envelope do
                            saveString = saveString .. "," .. tostring(egsliders[i].envelope[p][1]) .. "," 
                                                           .. tostring(egsliders[i].envelope[p][2])
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
        generateAndDisplay()      
    end -- if dogenerate==true
    
    last_mouse_cap=gfx.mouse_cap
    gfx.update()
    reaper.defer(update)
end

--------------------------------

function generateAndDisplay()
      generate(egsliders[1].value, -- freq
             egsliders[2].value, -- amp
             egsliders[3].value, -- center
             egsliders[4].value, -- phase
             egsliders[5].value, -- randomness
             egsliders[6].value, -- quansteps
             egsliders[7].value, -- tilt
             egsliders[8].value, -- fadindur
             egsliders[9].value, -- fadoutdur
             egsliders[10].value, -- timebase (aka ratemode)
             clip) 
      was_changed=true
    
    -- Draw the envelope in CC lane
    drawCCsBetweenNodes()
end

------------------------------
function drawCCsBetweenNodes()
    i = 1
    for n = 1, #tableNodes-1 do
        while i <= #tableCC and tableCC[i].PPQ < tableNodes[n+1].PPQ do
            -- Interpolate value of CC between nodes
            if tableNodes[n].shape == 0 then -- Linear
                CCvalue = tableNodes[n].value + ((tableCC[i].PPQ - tableNodes[n].PPQ)/(tableNodes[n+1].PPQ - tableNodes[n].PPQ))*(tableNodes[n+1].value - tableNodes[n].value)
            elseif tableNodes[n].shape == 1 then -- Square
                CCvalue = tableNodes[n].value
            elseif tableNodes[n].shape >= 2 and tableNodes[n].shape < 3 then -- Sine
                local piMin = (tableNodes[n].shape - 2)*math.pi
                local piRefVal = math.cos(piMin)+1
                local piFrac  = piMin + (tableCC[i].PPQ-tableNodes[n].PPQ)/(tableNodes[n+1].PPQ-tableNodes[n].PPQ)*(math.pi - piMin)
                local cosFrac = 1-(math.cos(piFrac)+1)/piRefVal
                CCvalue = tableNodes[n].value + cosFrac*(tableNodes[n+1].value-tableNodes[n].value)
            elseif tableNodes[n].shape >= 3 and tableNodes[n].shape < 4 then -- Inverse parabolic
                local minVal = 1 - (tableNodes[n].shape - 4)
                local fracVal = minVal*(tableCC[i].PPQ-tableNodes[n+1].PPQ)/(tableNodes[n].PPQ-tableNodes[n+1].PPQ)
                local refVal = minVal^3
                local normFrac = (fracVal^3)/refVal
                CCvalue = tableNodes[n+1].value + normFrac*(tableNodes[n].value - tableNodes[n+1].value)            
            elseif tableNodes[n].shape >= 4 and tableNodes[n].shape < 5 then -- Parabolic
                local minVal = tableNodes[n].shape - 4
                local fracVal = minVal + (tableCC[i].PPQ-tableNodes[n].PPQ)/(tableNodes[n+1].PPQ-tableNodes[n].PPQ)*(1 - minVal)
                local refVal = 1 - minVal^3
                local normFrac = 1 - (1-fracVal^3)/refVal
                CCvalue = tableNodes[n].value + normFrac*(tableNodes[n+1].value - tableNodes[n].value)
            else -- if tableNodes[n].shape == 5 then -- Bézier
                CCvalue = tableNodes[n].value
            end
            
            if egsliders[slidNum_quant].value ~= 1 then
                CCvalue=quantize_value(CCvalue, 3 + math.ceil(125*egsliders[slidNum_quant].value))
            end
            CCvalue = math.max(minv, math.min(maxv, math.floor(CCvalue+0.5)))
            
            -- SetCC to the new value
            if laneType == CC7BIT then
                reaper.MIDI_SetCC(take, tableCC[i].index, nil, nil, nil, nil, nil, nil, CCvalue>>7, true)
            elseif laneType == CC14BIT then
                reaper.MIDI_SetCC(take, tableCC[i].index, nil, nil, nil, nil, nil, nil, CCvalue>>7, true)
                reaper.MIDI_SetCC(take, tableCCLSB[i].index, nil, nil, tableCC[i].PPQ, nil, nil, nil, CCvalue&127, true)
            elseif laneType == PITCH then
                reaper.MIDI_SetCC(take, tableCC[i].index, nil, nil, nil, nil, nil, CCvalue&127, CCvalue>>7, true)
            else -- if laneType == CHANPRESSURE then
                reaper.MIDI_SetCC(take, tableCC[i].index, nil, nil, nil, nil, nil, CCvalue>>7, nil, true)
            end
            
            i = i + 1
            
        end -- while tableCC[i].PPQ < tableNodes[n].PPQ and i <= #tableCC
    
    end -- for n = 1, #tableNodes-1 

end -- function drawCCsBetweenNodes()

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
            reaper.ShowConsoleMsg("\n\nThe saved curves appear to have been corrupted."
                                  .. "\n\nThe saved curves can be edited (and perhaps recovered) manually, or they can all be deleted by running the following command in a script:"
                                  .. "\nreaper.DeleteExtState(\"LFO generator\", \"savedCurves\", true)")
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
        egsliders[slidNum_timebase].value = 0
        
        for i = 0, 11 do
            --reaper.ShowConsoleMsg("\nsliderName = ")
            sliderName = nextStr()
            if sliderName  == "LFO shape?" then shapeSelected = tonumber(nextStr())
            --[[elseif sliderName == "Real-time copy to CC?" then 
                if nextStr() == "true" then
                    egsliders[slidNum_copyCC].enabled = true
                else
                    egsliders[slidNum_copyCC].enabled = false
                end]]
            elseif sliderName == "Phase step" then egsliders[slidNum_phase].value = tonumber(nextStr())
            elseif sliderName == "Randomness" then egsliders[slidNum_random].value = tonumber(nextStr())
            elseif sliderName == "Quant steps" then egsliders[slidNum_quant].value = tonumber(nextStr())
            elseif sliderName == "Bezier shape" then egsliders[slidNum_Bezier].value = tonumber(nextStr())
            elseif sliderName == "Fade in duration" then egsliders[slidNum_fadein].value = tonumber(nextStr())
            elseif sliderName == "Fade out duration" then egsliders[slidNum_fadeout].value = tonumber(nextStr())
            elseif sliderName == "Timebase?" then egsliders[slidNum_timebase].value = tonumber(nextStr())
            elseif sliderName == "Rate" then 
                egsliders[slidNum_rate].envelope = nil
                egsliders[slidNum_rate].envelope = {}
                for p = 1, tonumber(nextStr()) do
                    egsliders[slidNum_rate].envelope[p] = {tonumber(nextStr()), tonumber(nextStr())}
                end
            elseif sliderName == "Center" then 
                egsliders[slidNum_center].envelope = nil
                egsliders[slidNum_center].envelope = {}
                for p = 1, tonumber(nextStr()) do
                    egsliders[slidNum_center].envelope[p] = {tonumber(nextStr()), tonumber(nextStr())}
                end
            elseif sliderName == "Amplitude" then 
                egsliders[slidNum_amp].envelope = nil
                egsliders[slidNum_amp].envelope = {}
                for p = 1, tonumber(nextStr()) do
                    egsliders[slidNum_amp].envelope[p] = {tonumber(nextStr()), tonumber(nextStr())}
                end
            end
        end -- for i = 0, 11 
        
        -------------------------------------------------------
        -- Draw the newly loaded envelope
        if egsliders[100].name == egsliders[1].name then -- "Rate"
            egsliders[100]=make_envelope(borderWidth, envYpos, 0, envHeight, egsliders[1])
        elseif egsliders[100].name == egsliders[2].name then -- "Amplitude"
            egsliders[100]=make_envelope(borderWidth, envYpos, 0, envHeight, egsliders[2])
        else -- "Center"
            egsliders[100]=make_envelope(borderWidth, envYpos, 0, envHeight, egsliders[3])
        end
        
        generate(egsliders[1].value, -- freq
               egsliders[2].value, -- amp
               egsliders[3].value, -- center
               egsliders[4].value, -- phase
               egsliders[5].value, -- randomness
               egsliders[6].value, -- quansteps
               egsliders[7].value, -- tilt
               egsliders[8].value, -- fadindur
               egsliders[9].value, -- fadoutdur
               egsliders[10].value, -- timebase (aka ratemode)
               clip)
               was_changed=true
                              
       -- Draw the envelope in CC lane
       drawCCsBetweenNodes()
        
    end -- savedCurves ~= nil and #savedCurves ~= nil and

end -- loadCurve()

  
---------------------------------------------
function constructNewGUI()

    --[[
    if laneType == CC7BIT then
        titleString = "LFO: CC ".. tostring(clickedLane)
    elseif laneType == CHANPRESSURE then
        titleString = "LFO: Chan pressure"
    elseif laneType == CC14BIT then
        titleString = "LFO: CC ".. tostring(clickedLane-256) .. "/" .. tostring(clickedLane-224)
    elseif laneType == PITCH then
        titleString = "LFO: Pitch"
    end
    ]]
    gfx.quit()
    gfx.init("LFO: ".. clickedLaneString, initXsize, initYsize,0)
    gfx.setfont(1,"Ariel", 15)
    
    egsliders[1]=make_radiobutton(borderWidth,borderWidth,0,0,0.5,"Rate", function(nx) end)
    slidNum_rate = 1
    egsliders[2]=make_radiobutton(borderWidth,borderWidth+sliderHeight*1,0,0,0.5,"Amplitude",function(nx) end)
    slidNum_amp = 2
    egsliders[3]=make_radiobutton(borderWidth,borderWidth+sliderHeight*2,0,0,0.5,"Center",function(nx) end)
    slidNum_center = 3
    egsliders[10]=make_question(borderWidth,borderWidth+sliderHeight*3,0,0,0.0,"Timebase?",function(nx) end, "Beats", "Time")
    slidNum_timebase = 10
    egsliders[0]=make_menubutton(borderWidth,borderWidth+sliderHeight*4,0,0,0.0,"LFO shape?",function(nx) end)
    slidNum_shape = 0
    --egsliders[11]=make_question(borderWidth,borderWidth+sliderHeight*5,0,0,0.0,"Real-time copy to CC?",function(nx) end, "Enabled", "Disabled")
    --slidNum_copyCC = 11
    -- The following slider was originally named "Phase"
    egsliders[4]=make_slider(borderWidth,borderWidth+sliderHeight*5,0,0,0.0,"Phase step",function(nx) end)
    slidNum_phase = 4
    egsliders[5]=make_slider(borderWidth,borderWidth+sliderHeight*6,0,0,0.0,"Randomness",function(nx) end)
    slidNum_random = 5
    egsliders[6]=make_slider(borderWidth,borderWidth+sliderHeight*7,0,0,1.0,"Quant steps",function(nx) end)
    slidNum_quant = 6
    egsliders[7]=make_slider(borderWidth,borderWidth+sliderHeight*8,0,0,0.7,"Bezier shape",function(nx) end)
    slidNum_Bezier = 7
    egsliders[8]=make_slider(borderWidth,borderWidth+sliderHeight*9,0,0,0.0,"Fade in duration",function(nx) end)
    slidNum_fadein = 8
    egsliders[9]=make_slider(borderWidth,borderWidth+sliderHeight*10,0,0,0.0,"Fade out duration",function(nx) end)
    slidNum_fadeout = 9
    egsliders[100]=make_envelope(borderWidth, envYpos, 0, envHeight,egsliders[1]) --315-30
    slidNum_env = 100
      
    --[[for key,tempcontrol in pairs(egsliders) do
      reaper.ShowConsoleMsg(key.." "..tempcontrol.type.." "..tempcontrol.name.."\n")
    end]]
    
end -- constructNewGUI()

------------------------


---------------------------------------

function insertNewCCs(take, insertChannel, PPQstart, PPQend)

 -- Delete all CCs in time selection (in last clicked lane and in channel)
        -- Use binary search to find event close to rightmost edge of ramp
        reaper.MIDI_Sort(take)
        _, _, ccevtcnt, _ = reaper.MIDI_CountEvts(take)        
        rightIndex = ccevtcnt-1
        leftIndex = 0
        while (rightIndex-leftIndex)>1 do
            middleIndex = math.ceil((rightIndex+leftIndex)/2)
            _, _, _, middlePPQpos, _, _, _, _ = reaper.MIDI_GetCC(take, middleIndex)
            if middlePPQpos > PPQend then
                rightIndex = middleIndex
            else -- middlePPQpos <= startingPPQpos
                leftIndex = middleIndex
            end     
        end -- while (rightIndex-leftIndex)>1
        
        -- Now delete events original events between the two endpoints.
        for i = rightIndex, 0, -1 do   
            _, selected, _, ppqpos, chanmsg, chan, msg2, _ = reaper.MIDI_GetCC(take, i)
            if ppqpos < PPQstart then
                break -- Once below range of selected events, no need to search further
            elseif ppqpos < PPQend
            and (deleteOnlyDrawChannel == false or (deleteOnlyDrawChannel == true and chan == insertChannel)) -- same channel
            and (   (laneType == CC7BIT and chanmsg == 176 and msg2 == clickedLane) 
                 or (laneType == PITCH and chanmsg == 224)
                 or (laneType == CHANPRESSURE and chanmsg == 208)
                 or (laneType == CC14BIT and chanmsg == 176 and msg2 == clickedLane-256)
                 or (laneType == CC14BIT and chanmsg == 176 and msg2 == clickedLane-224)
                )
            then
                reaper.MIDI_DeleteCC(take, i)
            end -- elseif
        end -- for i = rightIndex, 0, -1
        
        -----------------------------------------------------------------
        -- Insert new (selected) CCs at CC density grid in time selection
        -- Insert endpoints at time_start and time_end
        
        insertValue = 8000
        
        if laneType == CC7BIT then
            reaper.MIDI_InsertCC(take, true, false, PPQstart, 176, insertChannel, clickedLane, insertValue>>7)
        elseif laneType == PITCH then
            reaper.MIDI_InsertCC(take, true, false, PPQstart, 224, insertChannel, insertValue&127, insertValue>>7)
        elseif laneType == CHANPRESSURE then
            reaper.MIDI_InsertCC(take, true, false, PPQstart, 208, insertChannel, insertValue>>7, 0)
        else -- laneType == CC14BIT
            reaper.MIDI_InsertCC(take, true, false, PPQstart, 176, insertChannel, clickedLane-256, insertValue>>7)
            reaper.MIDI_InsertCC(take, true, false, PPQstart, 176, insertChannel, clickedLane-224, insertValue&127)
        end
        
        --[[ In the new versions of this tool, a CC is not inserted at the very end of the time selection,
        --     since this CC actually falls outside the time selection.
        if laneType == CC7BIT then
            reaper.MIDI_InsertCC(take, true, false, PPQend, 176, insertChannel, clickedLane, insertValue>>7)
        elseif laneType == PITCH then
            reaper.MIDI_InsertCC(take, true, false, PPQend, 224, insertChannel, insertValue&127, insertValue>>7)
        elseif laneType == CHANPRESSURE then
            reaper.MIDI_InsertCC(take, true, false, PPQend, 208, insertChannel, insertValue>>7, 0)
        else -- laneType == CC14BIT
            reaper.MIDI_InsertCC(take, true, false, PPQend, 176, insertChannel, clickedLane-256, insertValue>>7)
            reaper.MIDI_InsertCC(take, true, false, PPQend, 176, insertChannel, clickedLane-224, insertValue&127)
        end          
        ]]
        
        -- Get first insert position at CC density 'grid'
        local QNstart = reaper.MIDI_GetProjQNFromPPQPos(take, PPQstart)
        firstCCinsertPPQpos = reaper.MIDI_GetPPQPosFromProjQN(take, QNperCC*(math.ceil(QNstart/QNperCC)))
        if math.floor(firstCCinsertPPQpos+0.5) <= PPQstart then firstCCinsertPPQpos = firstCCinsertPPQpos + PPperCC end
        
        -- PPQend is actually beyond time selection, so "-1" to prevent insert at PPQend
        for p = firstCCinsertPPQpos, PPQend-1, PPperCC do
            insertPPQpos = math.floor(p + 0.5)      
            --if insertPPQpos ~= PPQstart and insertPPQpos ~= PPQend then
                if laneType == CC7BIT then
                    reaper.MIDI_InsertCC(take, true, false, insertPPQpos, 176, insertChannel, clickedLane, insertValue>>7)
                elseif laneType == PITCH then
                    reaper.MIDI_InsertCC(take, true, false, insertPPQpos, 224, insertChannel, insertValue&127, insertValue>>7)
                elseif laneType == CHANPRESSURE then
                    reaper.MIDI_InsertCC(take, true, false, insertPPQpos, 208, insertChannel, insertValue>>7, 0)
                else -- laneType == CC14BIT
                    reaper.MIDI_InsertCC(take, true, false, insertPPQpos, 176, insertChannel, clickedLane-256, insertValue>>7)
                    reaper.MIDI_InsertCC(take, true, false, insertPPQpos, 176, insertChannel, clickedLane-224, insertValue&127)
                end
            --end
        end
        
end -- insertNewCCs(startPPQ, endPPQ)

-------------------------------------


---------------------------------------------
-- Main 

function newTimeAndCCs()
   
    if type(verbose) ~= "boolean" then 
        reaper.ShowConsoleMsg("\n\nERROR: \nThe setting 'verbose' must be either 'true' of 'false'.\n") return(false) end
    if laneToUse ~= "last clicked" and laneToUse ~= "under mouse" then 
        reaper.ShowConsoleMsg('\n\nERROR: \nThe setting "laneToUse" must be either "last clicked" or "under mouse".\n') return(false) end
    if selectionToUse ~= "time" and selectionToUse ~= "notes" then 
        reaper.ShowConsoleMsg('\n\nERROR: \nThe setting "selectionToUse" must be either "time" or "notes".\n') return(false) end
    if type(defaultCurveName) ~= "string" then
        reaper.ShowConsoleMsg("\n\nERROR: \nThe setting 'defaultCurveName' must be a string.\n") return(false) end
    if type(deleteOnlyDrawChannel) ~= "boolean" then
        reaper.ShowConsoleMsg("\n\nERROR: \nThe setting 'deleteOnlyDrawChannel' must be either 'true' of 'false'.\n") return(false) end
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
        reaper.ShowConsoleMsg("\n\nERROR: \nThe custom interface colors must each be a table of four values between 0 and 1.\n") 
        return(false) 
        end
    if type(shadows) ~= "boolean" then 
        reaper.ShowConsoleMsg("\n\nERROR: \nThe setting 'shadows' must be either 'true' of 'false'.\n") return(false) end
    if type(fineAdjust) ~= "number" or fineAdjust < 0 or fineAdjust > 1 then
        reaper.ShowConsoleMsg("\n\nERROR: \nThe setting 'fineAdjust' must be a number between 0 and 1.\n") return(false) end
    if type(phaseStepsDefault) ~= "number" or phaseStepsDefault % 4 ~= 0 or phaseStepsDefault <= 0 then
        reaper.ShowConsoleMsg("\n\nERROR: \nThe setting 'phaseStepsDefault' must be a positive multiple of 4.\n") return(false) end
        
    
    editor = reaper.MIDIEditor_GetActive()
    if editor == nil then showErrorMsg("No active MIDI editor found.") return(false) end
    take = reaper.MIDIEditor_GetTake(editor)
    if take == nil then showErrorMsg("No active take found in MIDI editor.") return(false) end

    -- LFO Tool can only work in channels that use continuous data.
    -- Since 7bit CC, 14bit CC, channel pressure, and pitch all 
    --     require somewhat different tweaks, these must often be 
    --     distinguished.
    if laneToUse == "under mouse" then
        window, segment, details = reaper.BR_GetMouseCursorContext()
        if details ~= "cc_lane" then showErrorMsg("Since the 'laneToUse' setting is currently set to 'under mouse', the mouse must be positioned over either "
                                                  .. "a 7-bit CC lane, a 14-bit CC lane, pitchwheel or channel pressure."
                                                  .. "\n\nThe 'laneToUse' setting can be changed to 'last clicked' in the script's USER AREA.")
            return(false) 
        end
                       
        -- SWS version 2.8.3 has a bug in the crucial function "BR_GetMouseCursorContext_MIDI()"
        -- https://github.com/Jeff0S/sws/issues/783
        -- For compatibility with 2.8.3 as well as other versions, the following lines test the SWS version for compatibility
        _, testParam1, _, _, _, testParam2 = reaper.BR_GetMouseCursorContext_MIDI()
        if type(testParam1) == "number" and testParam2 == nil then SWS283 = true else SWS283 = false end
        if type(testParam1) == "boolean" and type(testParam2) == "number" then SWS283again = false else SWS283again = true end 
        if SWS283 ~= SWS283again then
            showErrorMsg("Could not determine compatible SWS version")
            return(false)
        end
        
        if SWS283 == true then
            _, _, mouseLane, _, _ = reaper.BR_GetMouseCursorContext_MIDI()
        else 
            _, _, _, mouseLane, _, _ = reaper.BR_GetMouseCursorContext_MIDI()
        end
        
        clickedLane = mouseLane
    else
        clickedLane = reaper.MIDIEditor_GetSetting_int(editor, "last_clicked_cc_lane")   
    end
    
    if type(clickedLane) ~= "number" then
        if laneToUse == "under mouse" then
            showErrorMsg("Since the 'laneToUse' setting is currently set to 'under mouse', the mouse must be positioned over either "
                         .. "a 7-bit CC lane, a 14-bit CC lane, pitchwheel or channel pressure."
                         .. "\n\nThe 'laneToUse' setting can be changed to 'last clicked' in the script's USER AREA.")
                         
            showErrorMsg("Since the 'laneToUse' setting is currently set to 'last clicked', the last clicked lane in the MIDI editor must be either "
                         .. "a 7-bit CC lane, a 14-bit CC lane, pitchwheel or channel pressure."
                         .. "\n\nThe 'laneToUse' setting can be changed to 'under mouse' in the script's USER AREA.")
        end
        return(false)
    elseif 0 <= clickedLane and clickedLane <= 127 then -- CC, 7 bit (single lane)
        laneType = CC7BIT
    elseif clickedLane == 0x203 then -- Channel pressure
        laneType = CHANPRESSURE
    elseif 256 <= clickedLane and clickedLane <= 287 then -- CC, 14 bit (double lane)
        laneType = CC14BIT
    elseif clickedLane == 0x201 then
        laneType = PITCH
    else -- not a lane type in which a ramp can be drawn (sysex, velocity etc).
        if laneToUse == "under mouse" then
            showErrorMsg("Since the 'laneToUse' setting is currently set to 'under mouse', the mouse must be positioned over either "
                         .. "a 7-bit CC lane, a 14-bit CC lane, pitchwheel or channel pressure."
                         .. "\n\nThe 'laneToUse' setting can be changed to 'last clicked' in the script's USER AREA.")
        else                         
            showErrorMsg("Since the 'laneToUse' setting is currently set to 'last clicked', the last clicked lane in the MIDI editor must be either "
                         .. "a 7-bit CC lane, a 14-bit CC lane, pitchwheel or channel pressure."
                         .. "\n\nThe 'laneToUse' setting can be changed to 'under mouse' in the script's USER AREA.")
        end
        return(false)
    end
    
    if laneToUse == "under mouse" then
        if laneType == CC7BIT then clickedLaneString = "CC " .. tostring(clickedLane)
        elseif laneType == CHANPRESSURE then clickedLaneString = "Channel pressure"
        elseif laneType == CC14BIT then clickedLaneString = "CC ".. tostring(clickedLane-256) .. "/" .. tostring(clickedLane-224) .. " 14-bit"
        elseif laneType == PITCH then clickedLaneString = "Pitchwheel"
        end
    else
        _, clickedLaneString = reaper.MIDIEditor_GetSetting_str(editor, "last_clicked_cc_lane", "")    
        if 256 <= clickedLane and clickedLane <= 287 then
            clickedLaneString = "CC ".. tostring(clickedLane-256) .. "/" .. tostring(clickedLane-224) .. " 14-bit"
        elseif type(clickedLaneString) ~= "string" or clickedLaneString == "" then
            clickedLaneString = "CC ".. tostring(clickedLane)
        end
    end
     
    -- Test whether there is actually a time span in which to draw LFO
    timeSelectStart, timeSelectEnd = reaper.GetSet_LoopTimeRange(false, false, 0.0, 0.0, false)  
    if selectionToUse == "time" then
        if type(timeSelectStart) ~= "number"
        or type(timeSelectEnd) ~= "number"
        or timeSelectEnd<=timeSelectStart 
        or reaper.MIDI_GetPPQPosFromProjTime(take, timeSelectStart) < 0
        or reaper.MIDI_GetPPQPosFromProjTime(take, timeSelectEnd) < 0
        then 
            showErrorMsg("A time range must be selected (within the active item's own time range).")
            return(false) 
        end
    else -- selectionToUse == "notes"
        if reaper.MIDI_EnumSelNotes(take, -1) ==  -1 then -- no notes selected
            showErrorMsg("No selected notes found in active take.")
            return(false) 
        end 
    end
            
    -- OK, tests completed and script can start, so activate menu button, if relevant, and define atexit
    _, _, sectionID, cmdID, _, _, _ = reaper.get_action_context()
    if sectionID ~= nil and cmdID ~= nil and sectionID ~= -1 and cmdID ~= -1 then
        reaper.SetToggleCommandState(sectionID, cmdID, 1)
        reaper.RefreshToolbar2(sectionID, cmdID)
    end    
    reaper.atexit(exit)
    
    -- First, Get the default grid resolution as set in Preferences -> 
    --    MIDI editor -> "Events per quarter note when drawing in CC lanes"
    --    and calculate PPQ per CC density
    takeStartQN = reaper.MIDI_GetProjQNFromPPQPos(take, 0)
    PPQ = reaper.MIDI_GetPPQPosFromProjQN(take, takeStartQN+1)
    density = math.floor(reaper.SNM_GetIntConfigVar("midiCCdensity", 32))
    density = math.floor(math.min(128, math.max(4, math.abs(density)))) -- If user selected "Zoom dependent", density < 0
    PPperCC = PPQ/density
    QNperCC = 1/density
    
    -- The Amplitude and Center displays above the hot node will use these variables:
    if laneType == CC7BIT or laneType == CHANPRESSURE then
        BRenvMaxValue = 127 -- The names of these variables will make sense in the envelope version of the script...
        BRenvMinValue = 0
    else
        BRenvMaxValue = 16383
        BRenvMinValue = 0
    end
        
    -------------------------------------------------------------
    -- Now, draw the new CCs in the time/note selection.  
    --    The new CCs will be selected, but all other MIDI data
    --    (except selected notes, if selectionToUse == "notes") 
    --    will be deselected.  This enables further manipulation
    --    of the CCs by other scripts.
    --
    -- There is not a "lane uder mouse" equivalent of the built-in function
    --    "Unselect all CC events in last clicked lane".  Therefore is "lane under mouse"
    --    is used, all MIDI events must be deselected, or a custom deselect function must be coded.
    
    if selectionToUse == "time" then
        if laneToUse == "under mouse" then
            reaper.MIDI_SelectAll(take, false)
        else
            reaper.MIDIEditor_OnCommand(editor, 40669) -- Unselect all CC events in last clicked lane 
        end
        --reaper.MIDIEditor_OnCommand(editor, 40747) -- Select all CC events in time selection (in last clicked CC lane)
        --reaper.MIDIEditor_OnCommand(editor, reaper.NamedCommandLookup("_BR_ME_DEL_SE_EVENTS_LAST_LANE")) -- Delete selected events in last clicked lane        
        time_start = timeSelectStart
        time_end = timeSelectEnd
        insertNewCCs(take, reaper.MIDIEditor_GetSetting_int(editor, "default_note_chan"), 
                           reaper.MIDI_GetPPQPosFromProjTime(take, time_start), 
                           reaper.MIDI_GetPPQPosFromProjTime(take, time_end))
    else -- selectionToUse == "notes"
        -- If "Unselect all CC events in last clicked lane" is used rather than "SelectAll(take, false)"
        --    then it is not really necessary to store the selected notes in a table before unselecting.
        local tableSelectedNotes = {}
        local tempFirstPPQ = math.huge
        local tempLastPPQ = 0
        selectedNoteIndex = reaper.MIDI_EnumSelNotes(take, -1)
        while (selectedNoteIndex ~= -1) do
            _, _, _, notePPQstart, notePPQend, noteChannel, _, _ = reaper.MIDI_GetNote(take, selectedNoteIndex)
            table.insert(tableSelectedNotes, {noteIndex = selectedNoteIndex, 
                                              notePPQstart = notePPQstart, 
                                              notePPQend = notePPQend, 
                                              noteChannel = noteChannel})
            if notePPQstart < tempFirstPPQ then tempFirstPPQ = notePPQstart end
            if notePPQend > tempLastPPQ then tempLastPPQ = notePPQend end
            selectedNoteIndex = reaper.MIDI_EnumSelNotes(take, selectedNoteIndex)
        end
        time_start = reaper.MIDI_GetProjTimeFromPPQPos(take, tempFirstPPQ)
        time_end = reaper.MIDI_GetProjTimeFromPPQPos(take, tempLastPPQ)
        
        -- Make sure the notes are sorted
        function sortPPQstart(a,b)
            if a.notePPQstart < b.notePPQstart then return(true) else return(false) end
        end
        table.sort(tableSelectedNotes,sortPPQstart)
        
        -- Should all MIDI be unselected, or only the CC events in the last clicked lane?
        if laneToUse == "under mouse" then
            reaper.MIDI_SelectAll(take, false)        
        else
            reaper.MIDIEditor_OnCommand(editor, 40669) -- Unselect all CC events in last clicked lane 
        end
        for i = 1, #tableSelectedNotes do
            reaper.MIDI_SetNote(take, tableSelectedNotes[i].noteIndex, true, nil, nil, nil, nil, nil, nil, true)
            insertNewCCs(take, tableSelectedNotes[i].noteChannel, 
                               tableSelectedNotes[i].notePPQstart, 
                               tableSelectedNotes[i].notePPQend)
        end

    end
           
    reaper.MIDI_Sort(take)
    
    -----------------------------------------------------------
    -- Get indices of the newly inserted CCs and store in table
    tableCC = nil
    tableCCLSB = nil
    tableCC = {}
    tableCCLSB = {}
    local ppqpos, chanmsg, msg2
    
    -- If "SelectAll(take, false)" was used, the events in the ramp are the only selected 
    --    ones in take, so no need to check event types.
    -- But if "Unselect all CC events in last clicked lane" was used, the lane must be checked.
    if laneType ~= CC14BIT then
        selCCindex = reaper.MIDI_EnumSelCC(take, -1)
        while (selCCindex ~= -1) do
            _, _, _, ppqpos, chanmsg, _, msg2, _ = reaper.MIDI_GetCC(take, selCCindex)
            if (laneType == CC7BIT and chanmsg == 176 and msg2 == clickedLane)
            or (laneType == PITCH and chanmsg == 224)
            or (laneType == CHANPRESSURE and chanmsg == 208) then
                table.insert(tableCC, {index = selCCindex,
                                      PPQ = ppqpos})
            end
            selCCindex = reaper.MIDI_EnumSelCC(take, selCCindex)
        end
    else -- When 14-bit CC, must distinguish between MSB and LSB events
        selCCindex = reaper.MIDI_EnumSelCC(take, -1)
        while (selCCindex ~= -1) do
            _, _, _, ppqpos, chanmsg, _, msg2, _ = reaper.MIDI_GetCC(take, selCCindex)
            if chanmsg == 176 and msg2 == clickedLane-256 then
                table.insert(tableCC, {index = selCCindex,
                                       PPQ = ppqpos})
            elseif chanmsg == 176 and msg2 == clickedLane-224 then
                table.insert(tableCCLSB, {index = selCCindex,
                                          PPQ = ppqpos})
            end
            selCCindex = reaper.MIDI_EnumSelCC(take, selCCindex)
        end
        if #tableCC ~= #tableCCLSB then
            reaper.ShowConsoleMsg("Something went wrong while writing 14-bit CCs")
            return(false)
        end
    end
    
    ----------------------------------
    -- Make sure the tables are sorted
    function sortPPQ(a,b)
        if a.PPQ < b.PPQ then return(true) else return(false) end
    end
    table.sort(tableCC,sortPPQ)
    if laneType == CC14BIT then
        table.sort(tableCCLSB, sortPPQ)
    end
    
        
end -- newTimeAndCCs()

-------------------------
-- Get the script started

if newTimeAndCCs() == false then return(0) end

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
generateAndDisplay()
update()

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

]]
